# État des lieux — Phase 32, durcissement du driver-lock

> Consigné le 2026-08-16. Deux reconnaissances : anatomie de l'existant (§1-§6) et contrat
> mesuré des hooks `PreToolUse` (§7-§11). Ce qui est **MESURÉ** est signalé comme tel ; le reste
> est lu dans le dépôt, avec chemins et lignes pour re-vérification.

**Avertissement de périmètre** : la Phase 32 « ne touche que `conductor` ». C'est vrai pour le
lock et ses tests. Mais **la découverte CI vit dans `.github/workflows/ci.yml`, `merge-hooks.sh`
dans `plugin/_internal/`, et le gate d'armement dans `plugin/dev-orchestrator/`.** Le périmètre
d'écriture réel devra être arbitré au plan, pas supposé.

---

## 1. `plugin/conductor/scripts/driver-lock.sh` — anatomie (286 lignes)

**Cinq verbes** (parsing positionnel-libre, L44) : `acquire` (L171-230), `heartbeat` (L232-244),
`release` (L246-255), `status` (L257-260), `recover` (L262-280).
`require_owner()` (L166-168) impose `--owner` pour `acquire`/`heartbeat`/`release` — **pas** pour
`status` ni `recover`.

**Acquisition symlink-génération** (mesurée, non rouverte) : `$LOCK_DIR` est un **lien symbolique**
vers `$LOCK_PARENT/${LOCK_BASE}.gen.<epoch>.<pid>`. `new_generation()` (L109-125) écrit le `meta`
**complet** avant de publier le nom → un lock publié est toujours complet. Le primitif qui
départage est `ln_atomic()` (L73-75, `ln -sh` BSD / `ln -sn` GNU ; sans l'option, `ln -s A B` où B
pointe un dossier crée `B/A` et rend 0 — bug mesuré « 8 gagnants sur 8 »). Motivation historique
en L8-20 : la forme antérieure laissait le chemin *absent* pendant la récupération, jusqu'à
5 gagnants simultanés sur 24 acquisitions.

**Le `meta`** (fichier plat `key=value`, `META="$LOCK_DIR/meta"` L38, lu par `meta_get()` L55) :

| clé | écriture | note |
|---|---|---|
| `owner` | L116 / L134 | chaîne **libre**, jamais validée ni générée par le script |
| `step` | L117 / L135 | |
| `branch` | L118 / L136 | capturé à l'acquisition, **préservé** au heartbeat (ADR-064, motif L98-104) |
| `worktree` | L119 / L137 | `git rev-parse --show-toplevel` |
| `acquired_epoch` | L120 / L138 | préservé par `rewrite_meta` ; **jamais utilisé dans un calcul de péremption** |
| `acquired_iso` | L121 / L139 | |
| `heartbeat_epoch` | L122 / L140 | **seul champ que le heartbeat fait bouger** |

La **génération** n'est pas dans le `meta` : c'est le nom de la cible du lien
(`lock_gen()` L96 → `readlink`), ou la chaîne `legacy` si le lock est un dossier réel (L93).

**TTL** : `VF_DRIVER_TTL:-1800` (L37), garde anti-injection L39.
`lock_age()` (L80-88) : `heartbeat_epoch` s'il est numérique, **sinon** mtime de la cible (fix H2)
— un `meta` partiel devient récupérable au lieu de rester « frais éternel ».

### Les deux écarts que la phase doit fermer

**LOCK-01 — le heartbeat prolonge la lease.** Il n'existe **aucune** séparation : `lock_age()` se
calcule sur `heartbeat_epoch`, donc chaque battement remet l'âge à zéro et **la lease est
indéfiniment renouvelable**. Aucune borne de durée totale (`acquired_epoch` n'est lu que pour être
préservé, L131). Second chemin de prolongation : `acquire` du **même** owner sur un lock frais
rafraîchit aussi le heartbeat (L186-191).

**LOCK-04 — l'auto-steal existe, implicite et non tracé.** Dès que `age > TTL`, un `acquire`
**ordinaire d'un autre owner** vole le lock (L196-229), sans flag, sans confirmation. Sérialisé
par mutex nommé d'après la génération observée (L200-201), avec double re-vérification sur
génération **et** âge après le mutex (L210). La **seule** trace est la sortie stdout
`{"acquired":true,…,"recovered":true,"previous_owner":"…"}` (L224) — éphémère, dans le process qui
vole ; l'ancienne génération est `rm -rf` (L223). Et `recover` (L262-280) fonctionne **sans
`--owner`** : n'importe qui, sans identité déclarée, peut élaguer un lock périmé.

**Sorties JSON** — une ligne, exit 0 = succès / 1 = refus. Deux exceptions notables :
`release` sans lock (L248) et `recover` sans lock (L263) sortent **0**.

Consommateur externe du `meta` : `plugin/conductor/scripts/check-branch-claim.sh:98-112`.

---

## 2. Tests du lock — `plugin/conductor/scripts/tests/test-driver-lock.sh` (144 l., 14 cas)

`T1` acquisition · **`T2` double-acquisition d'un autre owner refusée (L46-50)** · `T3` réentrance
même owner · `T4` heartbeat préserve le step · `T5`/`T6` release · `T7` récupération de claim
périmé · `T8` `recover` sur lock frais → `still-fresh` · `T9`/`T10` absences · `T11` 8 acquires
concurrents = 1 gagnant · `T12` lock sans meta récupérable par mtime · `T13` **24 concurrents ×
5 rounds**, égalité stricte à 1 gagnant · `T14` TTL non numérique → défaut.

**T2 est ce que `.planning/STATE.md:664` cite** comme garantie machine de dernier ressort de
l'invariant « un seul manager actif » (aussi
`plugin/dev-orchestrator/references/mission-cross-team.md:19,101`). Il n'asserte **que** le refus
d'une seconde `acquire` — jamais un geste git. C'est toute la dette.

**Convention d'une suite dans ce dossier** — patron **copié**, aucun harness partagé (vérifié :
aucun `source` d'une lib dans `tests/*.sh`) :
shebang + bloc d'en-tête listant les cas · `set -uo pipefail` (**jamais `-e`** : les assertions
doivent pouvoir capturer un exit non nul) · auto-localisation relative `cd "$(dirname "$0")/../.."`
· isolation `mktemp -d` + `trap … EXIT`, système sous test redirigé par variable `VF_*`
(`export VF_DRIVER_LOCK="$WORK_DIR/DRIVER.lock"`) · compteurs `PASS`/`FAIL` + helpers déclarés
dans la suite (`assert`, `assert_exit`, `num_eq`) · groupement `echo "=== Tn — … ==="` ·
épilogue `[ "$FAIL" -eq 0 ] && exit 0 || exit 1`.
Helpers **agnostiques du protocole interne** — cf. `age_stale()` L27-39 et son commentaire L23-26 :
« un test qui édite le meta à la main est un test qui casse au premier changement de protocole ».

---

## 3. Découverte des suites par la CI

`.github/workflows/ci.yml`, step « Découvrir et lancer toutes les suites », **L210-236**.
Pattern exact, **L213** :

```
suites=$(find plugin scripts -type f -path '*/tests/test-*.sh' | sort)
```

Racines `plugin` et `scripts` — **c'est cela, et rien d'autre, qui exclut `.claude/worktrees/`** :
aucune clause `-not -path`, l'exclusion est structurelle. Garde anti-vert-à-vide L216-219
(`count == 0` → `::error::` + `exit 1`).

**Comptes mesurés** : commande CI conforme → **62** ; `find . -type f -path '*/tests/test-*.sh'`
→ **122** (les 60 de surplus viennent de `.claude/worktrees/`). Recoupe `7e97267` et `8867f70`.
*Pièges documentaires* : le commentaire CI L911 dit « 61 suites », le commit `45ff4d7` dit « 76 » —
les deux sont périmés ou hors-pattern.

---

## 4. `merge-hooks` — `plugin/_internal/merge-hooks.sh` (494 l.)

Modes `merge` / `remove` / `plan` (L6-12). `plan` n'écrit rien et réutilise la **même** fonction de
répartition que `merge` (`split_fragment_hooks` L244-272) pour ne pas diverger.

**Déclaration côté plugin** : `plugin/<module>/hooks/hooks.json`. Deux jetons substitués —
`{{VF_SCRIPTS}}` (L137, résolu par `--scripts-prefix`) et `{{VF_BASH}}` (L138, chemin absolu de
bash résolu **à l'install** par `resolve_bash_abs()` L107-123). Tout `{{` résiduel est fatal
(L345, L359).

**Forme exec** (Phase 30, L20-25 / L348-364) : `{"type":"command","command":"{{VF_BASH}}",
"args":["{{VF_SCRIPTS}}/x.sh","--flag"]}` — **aucun shell n'intervient**, donc aucune expansion :
d'où `exec_safe_prefix()` (L141-160) et la garde dure L362-364 qui `die` sur un littéral
shell-quoté dans `args` (c'est le bug v2.53.0, « 6 hooks exec morts en scope user »).

**`--settings-local <chemin>`** (parsé L65-66, documenté L27-35). Règle de routage **bornée**,
`is_local_entry()` L237-242 :

```python
return bool(settings_local_path) and VF_BASH_TOKEN in h.get("command", "")
```

Seules les entrées dont le `command` **brut** porte `{{VF_BASH}}` partent vers le settings local.
Flag absent → comportement identique à avant. En `remove`, les deux cibles sont balayées.
**Limite déjà consignée dans le code (L331-343)** : la substitution de `{{VF_BASH}}` est
inconditionnelle — un fragment exec mergé *sans* `--settings-local` écrirait un chemin machine dans
un settings potentiellement commité. **À relire au moment de câbler le guard.**

Autres contrats à ne pas casser : réutilisation de groupe **conditionnelle** (L299-317 — un groupe
de même `matcher` n'est réutilisé que s'il est entièrement possédé par VF) ; idempotence par
basename avec frontière de mot (L197, L228) ; purge croisée projet ↔ local (L384-387) ; écriture
atomique (L470-483).

**Entrées `PreToolUse` existantes** :

| fichier | matcher | entrée | forme |
|---|---|---|---|
| `plugin/conductor/hooks/hooks.json:6-8` | `Write` | `guard-agent-write.sh` | shell |
| `plugin/consolidator/hooks/hooks.json:6-8` | `Read` | `guard-read-registres.sh` | shell |
| **`plugin/consolidator/hooks/hooks.json:12-14`** | **`Bash`** | `guard-bash-registres.sh` | shell |
| `plugin/software-architecture/hooks/hooks.json:6-8` | `Edit\|Write` | `{{VF_BASH}}` + `args:[guard-file-size.sh]` | **exec, bloquante** |

Le guard de la Phase 32 sera **le premier `PreToolUse(Bash)` en forme exec**, et cohabitera avec
`guard-bash-registres.sh` sur un matcher possiblement identique → attention à la logique de
réutilisation de groupe (L299-317), qui refusera un groupe mixte.

---

## 5. Le gate d'armement ↔ précondition (« règle 4 »)

**Ce n'est pas un script de `conductor`** : `plugin/dev-orchestrator/scripts/check-capability-activation.sh`
(suite : `tests/test-check-capability-activation.sh`, règle 4 dès L619, mutation `MUT-R4 (#38 rejoué)`
L781-806 ; CHANGELOG v2.15.0 L112-148).

Deux tables **littérales, non surchargeables** (L482-508) :
`ARM["isolation"]="worktree-baseref"`, `ARM["vf-mcp-consumer"]="mcp-servers"`,
`ARM["vf-mcp-tools"]="mcp-servers"` ; `OKID["worktree-baseref"]`, `OKID["mcp-servers"]`.
La boucle porte sur les **paires (fichier, armement)**, jamais sur les fichiers seuls (L727-731).
Trois sous-cas rouges (L732-755) : `vf-requires:` absent · citant un autre id · id légal sans
`# vf-provides: <id>` dans le corpus de scripts. Le rouge naît de l'**armement seul**.
Codes : `0` conforme · `1` écart · `2` **NON VÉRIFIABLE** (planchers anti-vert-à-vide L657-675) ·
`64` usage. Sortie sur **stderr**, lecture seule stricte.

**Point où la reconnaissance ne peut pas conclure sans hypothèse** : **la règle 4 ne connaît pas
les hooks.** Son corpus d'armement est fait de frontmatters d'agents/skills ; sa liste close ne
contient aucune clé de hook. Faire rougir la règle 4 sur une entrée de `hooks.json` supposerait
d'**ajouter une ligne à `ARM[]` et un id à `OKID[]`** — élargissement manuel que le code décrit
lui-même (borne 1, L86-90).

**En revanche il existe un autre gate CI qui rougit sur les entrées de hook**, et c'est
vraisemblablement celui que vise le critère n°2 : `.github/workflows/ci.yml`, step « Forme exec
telle qu'installée (PORT-05) », **L800-901**. Il dérive l'attendu du nombre d'entrées portant
`args` dans les `hooks.json` de la fermeture résolue (L812-822), constate ce que l'install a
**réellement posé** dans `settings.json` **et** `settings.local.json` (L861-869), et rougit sur :
0 entrée (L871-873), écart de compte (L875-877), `{{` résiduel (L852-853), `command` non absolu ou
non exécutable (L887-888), métacaractère shell dans `command`/`args` (L889-891). Une seule
dérogation nommée : `check-hook-paths.sh` (L843, L884-886).
→ **Ajouter un `PreToolUse(Bash)` en forme exec fera bouger `expect_total` automatiquement des
deux côtés.** C'est le comportement voulu, à condition que le guard soit absolu, exécutable et
sans métacaractère shell.

*Décision à prendre au plan : « armement prouvé par le gate règle 4 » désigne-t-il ce gate CI
(PORT-05), ou faut-il élargir `check-capability-activation.sh` aux hooks ?*

---

## 6. Trailers de commit et jeton de fence (LOCK-05)

**Trailers déjà en usage, par convention d'agent uniquement.** Sur les 300 derniers commits :
`Co-Authored-By:` 371 (+32 en casse basse), `Claude-Session:` 297, `Requirements:` 10 (ex.
`Requirements: PORT-03` sur `5bdb5a4`, `236e29e`, `2cd7dae`, `1a1d106`).

**Aucun outillage ne pose ni ne vérifie de trailer.** Vérifié : `.git/hooks/` ne contient que des
`.sample` ; `scripts/hooks/` ne contient qu'un `pre-push` (opt-in, ne regarde pas les messages, ne
fait qu'appeler `check-release-tag.sh` sur un push vers `main`) ; aucun `commit-msg` /
`prepare-commit-msg` ; une seule occurrence rédactionnelle du mot trailer dans `plugin/`
(`mobile-test-team/agents/vf-app-fixer.md:37`). **Espace vierge côté machine.**

**« Jeton de fence » n'est implémenté nulle part** — la notion n'existe qu'à l'état d'exigence
(`REQUIREMENTS.md:923`, `ROADMAP.md:690-691`, `research/FEATURES.md:112,275` où elle est classée
différenciateur). Candidats existants, par ordre de proximité :

1. **`owner` du lock** — seule identité de mandat persistée, mais **forme conventionnelle, jamais
   validée ni générée** par le script.
2. **La génération du lock** — `${LOCK_BASE}.gen.<epoch>.<pid>` (L112), déjà unique et monotone
   par acquisition, déjà relue par `lock_gen()` (L96). **C'est le candidat naturel d'un fence au
   sens strict** (numéro qui invalide l'ancien tenant après takeover) — mais elle n'est exposée
   par **aucune** sortie JSON aujourd'hui : il faudrait l'ajouter à `acquire`/`status`.
3. Les ids de nœuds du DAG (`dag.sh`) — portée nœud, pas mission.
4. `Claude-Session:` — identifiant de session, pas de mandat.

---

## 7. Contrat de sortie d'un hook `PreToolUse` — ce que le dépôt impose

`docs/HOOKS-CONTRAT-SORTIE.md` : `0` = rien à signaler **ou** signal émis normalement · non nul =
le script n'a pas pu faire son travail · **`2` réservé au blocage par le harness**, « jamais émis
involontairement » (L12-20). Le silence est un contrat de **flux** : stdout strictement vide,
diagnostics sur stderr (L42-48).

**Classement du parc (L156-169)** : 5 entrées bloquantes sur 26, dont **4 par décision JSON** et
une seule par code de sortie. Phrase clé L159-161 : « bloque en sortant **0**, via sa décision
JSON. Une lecture qui ne regarderait que le code de sortie la classerait à tort advisory. »

**La voie du dépôt est donc `permissionDecision: "deny"` + `exit 0`, jamais `exit 2`.** Trois
justifications écrites convergentes : le `2` réservé (ci-dessus) ; `plugin/_internal/lib/vf-portable.sh`
L126-130 — « non nul, **ET DIFFÉRENT DE 2** — sur un hook PreToolUse, exit 2 bloquerait l'édition
tant que Python manque, alors que la doctrine du dépôt est "dégradé mais utilisable" (ADR-031) »,
d'où `VF_GUARD_UNAVAILABLE_EXIT_CODE=17` ; et le fait que la décision JSON porte un **motif
structuré et long** qu'un `exit 2` ne peut pas porter.

`guard-agent-write.sh` : préfiltre pur-bash L38-42 → résolution `PYBIN` L44-50 → un seul spawn
python L52 → `json.dumps({"hookSpecificOutput":{…,"permissionDecision":"deny",
"permissionDecisionReason":reason}})` + `sys.exit(0)` L115-131 → **le script sort toujours 0**
(L132-133). Fail-open justifié en en-tête L22-23.

---

## 8. MESURÉ — ce que voit réellement l'agent appelant (divergences avec la doc officielle)

La doc officielle (https://code.claude.com/docs/en/hooks) affirme, pour `deny` comme pour `exit 2` :
« User sees the reason… **Claude does NOT see it** », et recommande `systemMessage`.
**Trois mesures contredisent cela** (Claude Code 2.1.233, macOS, sessions `claude -p`) :

| Cas mesuré | Outil exécuté ? | Ce que le modèle a rapporté |
|---|---|---|
| `exit 0` + JSON `deny`, motif `MOTIF_SENTINELLE_XYZ123` | **non** | le motif **restitué exactement**, en clair, sans préfixe |
| `exit 2` + stderr `STDERR_SENTINELLE_ABC789` | **non** | vu, mais **préfixé du chemin absolu du script** |
| `exit 0` + `systemMessage` + `permissionDecision: allow` | oui | **la sentinelle n'est jamais apparue** |

- **DIV-1** : `permissionDecisionReason` **est rendu au modèle** → le motif de refus est un canal
  d'instruction, pas seulement une trace pour l'humain. Bonne nouvelle pour la Phase 32.
- **DIV-2** : `exit 2` fuit le chemin absolu du script — argument de plus pour la voie JSON.
- **DIV-3** : `systemMessage` sur `allow` **n'atteint pas le modèle** (non mesuré en TUI).

---

## 9. MESURÉ — payload d'entrée, et identité de session

Payload réel d'un `PreToolUse(Bash)` :

```json
{"session_id":"d21cb3f3-…","transcript_path":"…/d21cb3f3-….jsonl","cwd":"…",
 "prompt_id":"…","permission_mode":"…","hook_event_name":"PreToolUse",
 "tool_name":"Bash","tool_input":{"command":"echo HELLO","description":"…"},
 "tool_use_id":"toolu_…"}
```

Depuis un **sous-agent**, deux clés en plus : `"agent_id"`, `"agent_type"`.
Pour `Bash`, **seul `tool_input.command` est fiable** — `description` est du texte libre du modèle,
**jamais un discriminant**. Conforme à la doc officielle sur l'entrée (aucune divergence).

**Parsing dans ce dépôt : python3, jamais jq, jamais awk** — les trois guards `PreToolUse` font le
même geste (préfiltre pur-bash puis un seul spawn python). `jq` existe dans la lib (`jqx`,
`vf-portable.sh` L121-124) mais **n'est utilisé par aucun guard `PreToolUse`**.

Le précédent le plus proche pour analyser une commande Bash est
`plugin/consolidator/scripts/guard-bash-registres.sh` : `tool_input.command` + `payload.cwd`
(L64-68) · **troncature au premier `<<`** — le contenu d'un heredoc est du texte, pas des commandes
(L73, CSL-05 ; directement applicable : une doc qui *cite* `git commit` ne doit pas être bloquée) ·
`command_positions()` L106-133 — seuls les tokens **en position de commande** comptent, en sautant
les wrappers (`sudo`, `env`, `nohup`, `xargs`, `nice`, `time`) et les affectations (CSL-04 ; sans
lui, `grep -n "git commit" fichier` déclencherait le deny) · segmentation
`re.split(r"\|\||&&|;|\|", cmd)` L178 · **limite assumée écrite** L26-27 : « garde-fou déterministe
contre le chemin de moindre résistance, **pas une sandbox** — un interpréteur inline (`python -c`,
`node -e`) peut toujours passer ». **La Phase 32 doit écrire la même clause.**

### Le point critique : un sous-agent partage-t-il l'identité de sa session ? — **OUI**

Trois observations concordantes :

1. **Mesure directe** : les deux payloads de la même session portent le **même** `session_id` ;
   celui du sous-agent y ajoute `agent_id`/`agent_type`.
   `CLAUDE_CODE_SESSION_ID` valait la même chose dans les deux.
2. **Traces locales** : le fil principal écrit `<session-uuid>.jsonl` ; les sous-agents écrivent
   `<session-uuid>/subagents/agent-<id>.jsonl` — **chaque ligne porte `sessionId` = l'UUID de la
   session parente**, avec `isSidechain:true` et un `agentId` propre.
3. **Doc officielle** : les hooks tirent aussi dans les sous-agents, l'entrée portant `agent_id` /
   `agent_type`.

**Conséquence** : un guard qui compare `payload.session_id` au `session_id` enregistré dans le lock
**ne bloquera pas les workers de la mission détentrice**. Le risque du « guard naïf qui tue ses
propres workers » **n'existe pas** avec `session_id` — il existerait avec `agent_id`.

### Canaux d'identité — ce qui est fiable et ce qui est un piège

| Canal | Fiable ? | Note |
|---|---|---|
| `payload.session_id` | **oui** | MESURÉ, stable, partagé par les sous-agents |
| `CLAUDE_CODE_SESSION_ID` (env) | **oui** | MESURÉ = `payload.session_id`, **écrasé par session**, pas hérité |
| `CLAUDE_PROJECT_DIR` | oui | racine du projet de la session |
| **`CLAUDE_CODE_CHILD_SESSION`** | **NON — PIÈGE** | MESURÉ hérité du process parent : valait `1` dans le hook d'une session **principale**, seulement parce qu'elle avait été lancée depuis un Bash de sous-agent. **Ne jamais s'en servir.** |
| `payload.agent_id` / `agent_type` | oui, mais | présents **uniquement** en sous-agent ; leur **absence** est le seul marqueur fiable de « fil principal » |
| `CLAUDE_PLUGIN_ROOT` | non | MESURÉ **absent** pour un hook déclaré en `settings.json` |
| `$PPID` | non | = `CLAUDE_PID`, un seul process pour toute la session — redondant, sans granularité |

**Aucune des 12 variables `CLAUDE*` visibles par un hook ne porte l'`agent_id`.**

### Ce qui est IMPOSSIBLE par construction — à assumer par écrit

Une liaison `owner` ↔ appelant à la **granularité de la mission** est hors d'atteinte : le seul
identifiant plus fin que la session est `agent_id`, et il n'existe **que dans le payload du hook**.
Donc **un manager ne peut pas connaître son propre `agent_id`** au moment où il exécute
`driver-lock.sh acquire` — il ne peut pas l'écrire dans le `meta`.

> Le guard pourra garantir « **aucune autre session** ne commite sous mon lock ».
> Il ne pourra **pas** garantir « aucun autre acteur **de ma session** ne commite sous mon lock ».

À écrire noir sur blanc plutôt qu'à laisser croire. Bonne nouvelle : **les incidents documentés
sont tous inter-sessions** (I2, I3) — la granularité session les couvre.

### Mécanisme de liaison recommandé

`driver-lock.sh` ajoute un champ **additif** au `meta` — même patron que `branch`/`worktree`
(ADR-064, L98-104, L118-119) :

```
session_id=<$CLAUDE_CODE_SESSION_ID à l'acquire, vide si absent>
```

Écriture dans `new_generation()` (L109-125) **et** préservation dans `rewrite_meta()` (L129-142),
exactement comme `acquired_epoch`/`branch`/`worktree` (L131-132) — sinon un heartbeat émis depuis
un autre contexte réécrirait le propriétaire.

Décision du guard, dans l'ordre :
1. **Non-applicabilité → allow silencieux** : pas de `.planning/DRIVER.lock`, lock **périmé**,
   commande non concernée.
2. `meta.session_id` **vide** (lock d'une version antérieure, ou acquis en CLI hors session) →
   **allow**, repli sur la comparaison `worktree`. *Rétrocompatibilité obligatoire : sinon la mise
   à jour du script gèle les sessions en cours.*
3. `payload.session_id == meta.session_id` → **allow** (couvre le manager **et** ses workers).
4. Sinon → **deny**, motif portant `owner`, `step`, `branch`, l'âge du lock **et la marche à suivre
   pour reprendre**.
5. Même arbre, session différente : `check-branch-claim.sh:16-20` tranche déjà doctrinalement
   (« deux sessions du même worktree partagent de fait leur arbre »).

**Échappatoire explicite obligatoire** (variable d'env ou préfixe reconnu, patron
`vibeflow:allow-large-file`) : sans elle, un lock zombie non périmé rend le dépôt non-commitable
et **le modèle apprend à contourner par un autre outil** — régression vécue et racontée par
`guard-file-size.sh:9-12` (« boucle deny/retry qui enseignait le contournement par Bash/sed »).

**Modes de défaillance** : F1 manager sous-agent → granularité session (structurel, §ci-dessus) ·
**F2 `claude --resume` / `/clear` changent-ils le `session_id` ? — NON MESURÉ, potentiellement
bloquant** (un resume qui mint un nouvel UUID verrouillerait le détenteur hors de son propre lock ;
le repli `worktree` l'absorbe partiellement) — **à mesurer avant de coder** · F3 lock acquis en CLI
pure → champ vide, prévu par la règle 2 · F4 worktree partagé volontairement · F5 `meta` corrompu →
fail-open · F6 `python -c` / alias → non couvert, clause de limite.

**Options écartées** : *fichier de mandat* (second état à synchroniser, sans identité plus fine) ·
*variable d'env posée par le manager* — **techniquement impossible** : les hooks sont lancés par le
process du harness, pas par le shell du manager (MESURÉ : `PPID` du hook = `CLAUDE_PID`), et l'état
shell ne persiste pas entre appels · *hook compagnon stampant l'`agent_id` à l'acquisition* —
faisable mais crée une dépendance à l'ordre des hooks et un état hors du lock.

---

## 10. Le patron de guard bloquant — `guard-file-size.sh` (169 l.)

Seule entrée `PreToolUse` en **forme exec** du parc, avec mention explicite en `description` :
« entrée **BLOQUANTE** : c'est sa décision JSON `permissionDecision: deny` qui bloque l'appel
d'outil, pas son code de sortie ». **C'est la forme que doit prendre l'entrée de la Phase 32.**

Architecture : préfiltre pur-bash L31-35 (zéro spawn si non concerné) · bloc canonique
`vf-portable:locator` L37-73 (copié verbatim, identité vérifiée par somme de contrôle dans
`test-vf-portable.sh`) · profil **rapide** `vf_resolve_python --fast` L75-84 (« ce guard tourne à
CHAQUE Edit/Write, un spawn `timeout` supplémentaire serait une régression de latence
perceptible ») · un seul spawn python L88-167 · échappatoire `vibeflow:allow-large-file` L91-94.

**Le cas « je ne peux pas savoir » est traité de DEUX façons distinctes — point le plus important
à reprendre** :
- **Erreur interne** (JSON invalide, fichier illisible) → **fail-open SILENCIEUX**
  (`except Exception: sys.exit(0)` L165-166, `2>/dev/null || exit 0` L167). En-tête L22-24.
- **Le guard ne peut pas TOURNER** (aucun interpréteur) → **fail-open BRUYANT** :
  `vf_guard_unavailable …` puis `exit $?` (L81-84). Commentaire L78-80 : « **Renversement du
  silence (D-02)** ». `vf_guard_unavailable` (`vf-portable.sh` L145-158) fait **trois choses
  ensemble** : marqueur horodaté dans `$VF_GUARD_HEALTH_DIR`, ligne préfixée sur stderr, et
  **retour** (jamais `exit`) du code **17**.

Suite : `plugin/software-architecture/scripts/tests/test-guard-file-size.sh`, 15 assertions /
14 cas. DENY : T1, T10 (299 L → franchit le seuil), T11, T12a, T14 (pas de newline finale) ·
allow : T2-T5, T7-T9 (anti-deny-loop), T12b · **T6 stdin imparsable → allow silencieux, `rc=0` ET
sortie vide tous deux assertés** · **T13 fichier `chmod 000` → allow, « jamais deny sur erreur
interne »**. Payloads construits par python (`mk_edit`/`mk_write`), guard exécuté avec
`${BASH:-bash}` (validation bash 3.2 réelle).

> **QUAL-01 demande trois issues ; il en faut QUATRE** :
> PASS · DENY · **imparsable → fail-open silencieux** · **indisponible → fail-open bruyant**.
> Les deux derniers sont distincts, et la suite de `guard-file-size.sh` ne couvre que le premier
> (le chemin `vf_guard_unavailable` est couvert ailleurs, dans `test-vf-portable.sh`).

---

## 11. MESURÉ — coût, et le trou franc de QUAL-01

**Coût** (bancs jetables macOS, 200 puis 100 itérations, warmup inclus, majorants) :

| Forme | Coût / appel |
|---|---|
| Guard **pur bash** (préfiltre `case` + `[ -L ]` + `grep ^owner=` + `cut`) | **6,70 ms** |
| Guard **bash + un spawn `python3`** | **24,40 ms** |

Le spawn python coûte ~3,6× — soit ~18 ms sur **chaque** appel Bash de **chaque** session. Le
travail du lock (`readlink` + `grep` sur 7 lignes) n'a **aucun besoin** de python. Un préfiltre
pur-bash sur le payload brut (sous-chaîne littérale `commit` / `checkout`, surensemble strict du
domaine de deny) ramène le cas nominal — 99 % des appels — à ~1-2 ms, et ne paie le spawn que sur
les commandes réellement suspectes. C'est déjà l'architecture des trois guards existants.

**Modes de défaillance catastrophiques — MESURÉS** :

| Scénario | Comportement observé |
|---|---|
| **Script du hook absent** (exit 127 + stderr) | l'outil **s'exécute**, le modèle rapporte « No error received » |
| **exit 17 + stderr** (code `vf_guard_unavailable`) | l'outil **s'exécute**, le modèle ne voit **rien** |
| `exit 2` + stderr | bloque, message vu (préfixé du chemin) |
| `exit 0` + JSON `deny` | bloque, motif vu **propre** |

**Le harness est structurellement fail-open sur un `PreToolUse` qui plante.** Un guard cassé,
absent ou non exécutable **ne peut pas bloquer le dépôt** — rassurant pour le risque de blocage
global, et c'est exactement le problème ci-dessous.

**Prémunitions des guards existants, à reprendre** : `set -uo pipefail` **sans `-e`**
(`guard-file-size.sh:26`, `guard-agent-write.sh:32`, `guard-bash-registres.sh:31`,
`driver-lock.sh:34`) · sortie précoce de non-applicabilité à zéro spawn · **variantes antislash
Windows** (`guard-bash-registres.sh:40-42` — sans elles « la garde était inerte sous Windows, en
paraissant installée ») · partition à quatre codes de `check-branch-claim.sh` : pas de lock =
« personne ne pilote », état **VÉRIFIÉ donc SAIN** → `hook_exit 3` (L100-104), et `meta` illisible
→ **code 4 indéterminé, jamais un SAIN de complaisance** (L104, contrat L30-38) · **lock périmé
traité comme absent** (L118-126 + L43-45 : « sinon un manager mort gèlerait le signal pour tout le
monde ») — **indispensable ici**, sans quoi un lock zombie bloquerait tous les commits de la
machine · `grep` toujours amorti (`… | head -1 | cut -d= -f2- || true`).

### Le trou franc de QUAL-01 — à trancher, pas à supposer

Le ROADMAP exige « fail-open **BRUYANT** si le lock est illisible — jamais un vert ».
**Ce « bruyant » n'est réalisable par aucun mécanisme en place** :

1. **exit 17 + stderr n'atteint personne** — MESURÉ : ni le modèle, ni l'humain en non-interactif.
2. **`systemMessage` sur `allow` n'atteint pas le modèle** — MESURÉ (non testé en TUI).
3. **Le marqueur de santé n'est lu par personne.** `grep -rn "VF_GUARD_HEALTH_DIR|guard-health"`
   sur `plugin/` ne rend **aucun consommateur** — seul `vf-portable.sh:147-155` écrit. Le « hook
   doctor » censé les agréger est décrit dans
   `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md:205-207`, et ce même
   document constate « hook doctor → **0** occurrence ». **Il n'existe pas.**

Les seuls canaux qui rendent un signal visible sont donc **bloquants** : `deny` (motif vu par le
modèle, mesuré) ou `ask`. Trois issues honnêtes :

- **(A)** lock illisible → `permissionDecision: "ask"` : bruyant *et* non silencieusement
  permissif, mais interrompt le flux et **peut ne pas être disponible à un sous-agent
  backgroundé** (à rapprocher de `AskUserQuestion` absent en subagent — **non mesuré pour `ask`**).
- **(B)** fail-open silencieux + marqueur de santé, **et livrer dans la même phase le hook doctor
  `SessionStart` qui le lit**. Seule voie qui respecte ADR-031 sans mentir sur le mot « bruyant » —
  mais **ajoute un livrable non prévu au périmètre**.
- **(C)** assumer par écrit que « BRUYANT » = « tracé sur disque + stderr », en sachant que
  personne ne le lit. **C'est un vert de complaisance — déconseillé.**

---

## Reliquats de mesure — à lever avant de coder

- `claude --resume` / `/clear` conservent-ils le `session_id` ? *(F2, bloquant pour §9)*
- `permissionDecision: "ask"` est-il honoré quand l'appelant est un sous-agent backgroundé ?
- `systemMessage` est-il visible dans l'UI interactive ? *(mesures faites en `-p` uniquement)*
- Coût du guard sous Windows / Git Bash *(mesures macOS uniquement)*.
