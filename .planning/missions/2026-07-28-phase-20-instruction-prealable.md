# Mission — Phase 20 : instruction préalable des zones grises

**Date** : 2026-07-28
**Manager** : `vf-dev-manager`
**Branche** : `feat/phase-20-fluidite-flux` (ADR-059, créée avant le premier commit)
**Périmètre** : Phase 20 « Fluidité du flux de dev sans perte de qualité », 4 changements, 7 critères
**Issue** : **GELÉE au checkpoint de doctrine** — 4 décisions attendent Samuel. Aucune ligne de
doctrine, d'agent ou de script n'a été modifiée.

---

## 1. Pourquoi la mission s'arrête là

Le brief impose des checkpoints humains aux points de décision de doctrine (changements 1, 2, 3).
Le contrat de `vf-dev-manager` déclare `AskUserQuestion` dans ses `tools:` — **le runtime ne la
fournit pas** dans ce contexte d'exécution (« AskUserQuestion is not available inside subagents »).

C'est une **instance supplémentaire du problème que la Phase 20 traite** : un `tools:` déclaré qui ne
correspond pas au toolset runtime. Le changement 1 constate l'écart dans le sens de l'**ouverture**
(`memory:` ajoute `Write`/`Edit`) ; ici l'écart joue dans le sens de la **fermeture** (un outil
déclaré est retiré). À verser au cadrage : le critère de succès n°2 devrait couvrir les deux sens.

Protocole appliqué : nœud `checkpoint-doctrine` gelé, aucun nœud aval dispatché (tous en dépendent),
verrou de driver relâché, rapport rendu.

## 2. Plan de bataille (DAG)

```
probe-mcp ─┐
research-runtime ─┤
panel-c2 ─┼─→ checkpoint-doctrine ✗ → discuss-20 → plan-20 → checkpoint-plan
probe-hooks ─┘                          (gelé)      → execute-20 → {review-20, audit-20} → gates-release
```

4 nœuds d'instruction dispatchés en parallèle, tous `done`. 8 nœuds restent `blocked`.

**Erreur de dispatch à consigner** : les périmètres d'**écriture** de `probe-mcp` et `probe-hooks`
étaient disjoints, mais pas leurs périmètres de **mesure** — `probe-mcp` créait des agents-sondes
dans `~/.claude/agents` pendant que `probe-hooks` y comptait les warnings. Chiffres corrigés à la
main (29 lignes / 27 warnings / 0 erreur au lieu de 30 / 26 / 2). Leçon consignée en mémoire d'agent.

## 3. Faits établis, chacun vérifié par le manager après retour du worker

### 3.1 Changement 1 — la granularité est tranchée par le test

**L'allowlist fine `mcp__<serveur>__<outil>` fonctionne ET restreint réellement.** Cobaye :
`plugin:context7:context7` (XcodeBuildMCP ne se connecte pas dans cet environnement — `✘ Failed to
connect`, comme `AppleXcodeMCP` et `mobile-mcp`).

| Sonde | `tools:` | outil listé | outil voisin, même serveur, non listé |
|---|---|---|---|
| A — fine | `…__resolve-library-id` | SUCCÈS | **ÉCHEC** — `Error: No such tool available` |
| B — wildcard | `…__*` | SUCCÈS | SUCCÈS |
| C — contrôle | aucune entrée MCP | ÉCHEC | ÉCHEC |

La sonde B élimine l'explication alternative : l'outil voisin existe et répond, donc son invisibilité
pour A vient bien de l'allowlist. **Non contournable par `ToolSearch`** : interrogé explicitement sur
les deux noms, `ToolSearch` n'en retourne qu'un pour la sonde A.

**Méthode réutilisable** : les agents créés en cours de session sont invisibles (`Agent type not
found`), mais un process `claude -p` **frais** les charge. Aucun redémarrage manuel nécessaire pour
les futurs nœuds de preuve sur les agents.

**Non prouvé** : que `test_sim`/`build_sim` portent bien ces noms exacts chez XcodeBuildMCP. La
transposition repose sur le caractère générique du mécanisme. Recette humaine à prévoir sur un lab
iOS avec le serveur vivant.

### 3.2 Découverte incidente — deux gates du repo se contredisent

`check-agents.sh:355` teste `re.fullmatch(r"[A-Za-z0-9_-]+", tok)` : **le `*` n'est pas dans le
charset**. Or `inject-mcp-tools.sh` injecte la forme `mcp__<serveur>__*` (son en-tête, ligne 10).

**Sur tout lab avec un `.mcp.json`, l'installeur pose un agent que le SessionStart déclare ensuite
non conforme**, et `guard-agent-write.sh` refuserait de le réécrire. Latent dans ce repo (pas de
`.mcp.json`). La forme fine, elle, passe le lint — les deux arguments convergent vers elle.

Corollaire : `check-agents.sh` ne valide **pas** la forme des tokens MCP. Un `mcp__typo__foo` passe
en silence.

### 3.3 Changement 2 — `memory:` rouvre `Write`/`Edit`, et `disallowedTools` referme

Confirmé sur **source primaire** — doc Claude Code, subagents, mémoire persistante : « Read, Write,
and Edit tools are automatically enabled so the subagent can manage its memory files. » Ce n'est ni
un bug ni un comportement empirique : c'est le contrat publié.

Confirmé **expérimentalement**, trois sondes à une seule variable, avec tentative réelle d'écriture :

| Sonde | frontmatter | outils runtime | écriture réellement tentée |
|---|---|---|---|
| `nomem` | `tools: Read, Grep`, pas de `memory:` | `Read, Grep` | fichier **non créé** |
| `mem` | + `memory: project` | `Read, **Write**, **Edit**, Grep` | **fichier créé (2 B)** |
| `deny` | + `disallowedTools: Write, Edit` | `Read, Grep` | fichier **non créé** |

`disallowedTools` gagne contre l'auto-enable. C'est la barrière réelle, elle coûte une ligne, et
`check-agents.sh` parse déjà le champ (`KNOWN` l.154, boucle l.547).

Options écartées : les hooks en frontmatter sont **ignorés pour les agents de plugin** (et VibeFlow
est un plugin) ; `permissions.deny` s'applique à la session entière, pas au sous-agent.

**Portée réelle — 4 juges, pas 1** : `vf-design-judge`, `quality-gate-client`,
`content-clarity-judge`, `growth-quality-judge` (4 modules à bumper). Plus la doctrine :
`team-kernel.md:23` et `:36`, `conductor/README.md:44` affirment « juges sans Write/Edit ». Plus
6 managers qui justifient le dispatch parallèle des juges par ce read-only inexistant.

**Angle mort** : même avec `disallowedTools`, `vf-design-judge`, `vf-reviewer` et `vf-auditer`
gardent `Bash` → `echo > fichier` reste ouvert. « read-only » resterait faux pour eux. Les trois
juges de bundle n'ont pas `Bash` : pour eux la barrière est complète.

**Effet de bord à assumer** : un juge sous `disallowedTools` ne pourra plus **écrire** son
`MEMORY.md` (il continue de le lire). Cohérent avec l'intention de regard frais, mais ADR-044 impose
`memory:` — à documenter comme un choix.

**Affirmation fausse repérée** : `team-kernel.md:23` dit « anti-triche vérifié par les suites de test
de chaque module ». Aucun test de `plugin/*/tests/` n'assure cette propriété.

### 3.4 Changement 2 — deux faits qui changent sa nature

**F1 — la doctrine se contredit déjà.** `mission-cross-team.md:44` contient littéralement
`dag.sh add --id=revue-N --step="revue code étape N" --deps=exec-N`, et `:74` pose « vert complet =
critique-rendu ≥ seuil ET revue PASS ». Donc dès qu'un étage design croise une mission dev, le
manager pose **déjà** un nœud de revue de premier rang — ce que `vf-dev-manager.md:108` lui interdit.
La question n'est pas « faut-il sortir la revue ? » mais « **généraliser un cas déjà écrit, ou le
supprimer ?** ». Le risque de l'option « nœud de DAG » chute d'autant.

**F2 — le périmètre de fichiers par nœud n'existe pas.** `dag.sh` n'a aucun flag `--scope`/`--files`
(vérifié : `grep -n "scope\|files" dag.sh` → 0). Or `vf-dev-manager.md:75-77` impose de déclarer le
périmètre de chaque nœud **au moment du `dag.sh add`** : instruction que l'outil ne sait pas
exécuter. **Conséquence : le critère (b) du succès n°4 est structurellement indécidable aujourd'hui**,
et la table des fichiers gelés du changement 3 n'a aucun support. Dépendance non écrite 2 ↔ 3.

**Recommandations du panel** : nœud `revue-N` piloté par le manager (seule option où le régime de
revue devient une donnée sur disque, donc rejouable par un gate) ; convertir « jugement de risque par
lot » en « zones de risque déclarées une fois » (modèle CODEOWNERS) car l'agent qui classe est celui
qui paie le coût de la revue pleine ; déclencher la revue de jointure sur la **topologie du DAG**
(toute paire de nœuds `exec` incomparables partage un descendant `join`) et non sur l'intersection
des périmètres — celle-ci est **vide par construction** dans le cas nominal, puisqu'on parallélise
justement quand les périmètres sont disjoints ; faire que `dag.sh reopen` **force le régime plein**
(meilleur rapport garantie/coût, enforcé machine et non par prompt).

**Deux avertissements repris à mon compte** :
- Le critère n°4 est **partiellement invérifiable tel qu'écrit** : VibeFlow ne peut pas savoir ce
  qu'est un « adaptateur d'infra » ou un « geste utilisateur » dans une stack qu'il ne connaît pas.
  Atteignable : livrer le **mécanisme**, le **contenu** étant per-projet.
- **Le changement 2 ne rend pas le flux plus rapide, il le rend plus sûr.** L'allègement n'est
  éligible qu'au Domain pur à mutation verte, quasi inexistant en pratique, pendant que le nœud
  `join` ajoute un nœud par frontière parallèle. Le Goal de la phase est servi par les changements 1
  et 4. À écrire au cadrage plutôt qu'à découvrir en rétro.

### 3.5 Changement 4 — le fix est petit, mais insuffisant seul

Reproduction confirmée, scripts installés identiques au repo (`diff -q` OK), install en scope user :
`check-agents.sh --hook` et `check-debug-research.sh --hook` sortent **0 ligne, exit 0**.

**Le mécanisme de substitution existant suffit** : `merge-hooks.sh:167` fait un `.replace` **global**
de `{{VF_SCRIPTS}}` sur toute la ligne de commande. Vérifié par exécution :

```bash
bash "$HOME"/.claude/scripts/check-agents.sh --hook \
  --agents-dir="$HOME"/.claude/scripts/../agents \
  --skills-dir="$HOME"/.claude/scripts/../skills
```

**4 lignes dans `hooks.json`, zéro code**, exact dans les trois scopes d'install, portable
macOS/Linux. Options écartées : l'union projet+user entre en conflit frontal avec
`guard-agent-write.sh:62-72` (CND-05/T20, qui autorise explicitement d'écrire un agent personnel hors
du lab courant) ; le défaut conditionnel rend le même appel non déterministe selon la machine.

**Trois pièges** :
1. Corriger `agents` sans `skills` perd 6 findings — le défaut de chemin relatif touche les deux.
2. **Le contrat anti-vert-à-vide exempte explicitement le mode hook** : `check-agents.sh:568`
   (`if strict and not allow_empty and not hook:`) et `:571` (`if not hook:`). Le mode `--hook` est
   muet qu'il ait lu 58 agents ou zéro. **Corriger le scope sans lever cette exemption remplace un
   garde-fou aveugle par un garde-fou aveugle bien pointé.**
3. **Le critère n°6 se contredit** : `--hook` n'imprime jamais les warnings (`check-agents.sh:64`).
   Après le fix, sur parc propre, le hook sortira **0 ligne** malgré 27 warnings réels. On obtient
   « silencieux en nominal » ✓ mais **pas** « utile sur les dérives ». Décision séparée requise.

**Piège de scope sur l'autre script** : `check-debug-research.sh` n'a **aucun**
`--third-party-prefix`. Corriger son chemin sans le lui donner injecte **5 faux positifs tierces sur
5** (`gsd-debug`, `gsd-ns-review`, `gsd-debug-session-manager`, `seo-audit`, `diagnose`) dans le
contexte à chaque session. Porter le mécanisme existant n'est **pas** l'option redondante que le
critère n°6 interdit : il interdit d'en inventer un second, pas de réutiliser celui-là.

**Le piège de mesure** : aucun des **58 + 14** cas de `test-check-agents.sh` et
`test-check-debug-research.sh` n'exerce le chemin par défaut — `run_check()` passe toujours
`--agents-dir` explicite. C'est pour ça que le bug a survécu à une Phase 16 entière dédiée au script.

**Sur le `|| true`** : aucun code de sortie d'un hook `SessionStart` ne bloque la session (doc
officielle). Le `|| true` n'est donc pas nécessaire, et il rend un crash du script indistinguable
d'un garde-fou vert. Contrat de sortie à copier : `update-banner.sh` (silence total en nominal,
`systemMessage` JSON quand il parle).

## 4. Findings corrigés par le manager

- Le panel signalait des `.bak` « versionnés dans `agents/` ». `git ls-files | grep '\.bak$'` → **0**.
  Ils existent sur disque, ne sont pas suivis. Finding retiré.
- `probe-hooks` rapportait 5 fichiers `zz-probe-*` comme « artefacts d'une sonde antérieure ».
  C'étaient les sondes de `probe-mcp`, concurrent. Toutes supprimées (`0` restante), `git status`
  propre. Chiffres du parc corrigés en conséquence.

## 5. Les 4 décisions qui attendent Samuel

| # | Décision | Ce que la machine a déjà tranché | Ce qui reste humain |
|---|---|---|---|
| D1 | Granularité MCP de `vf-reviewer` | La forme fine marche, restreint, et est la seule à passer le lint | Quels outils exactement (le piège du build en cache plaide pour inclure `clean`), vs wildcard + correction du charset |
| D2 | Périmètre de l'écart `tools:`/runtime | `disallowedTools` est la barrière réelle | 1 juge (texte ROADMAP) ou 4 juges + kernel + règle de lint (4 modules à bumper) |
| D3 | Placement de la revue | La forme « nœud de DAG » existe déjà (F1) | Généraliser ou supprimer ; et si `dag.sh --scope` entre dans la phase (débloque le critère (b) et le changement 3) |
| D4 | `MISSION-INVARIANTS.md` | Les globs de zones sont falsifiables (« zone morte ») ; le seuil de tests ne l'est pas | Créer avec quel contenu, ou ne pas créer |

Décision annexe, technique : politique de remontée des warnings en mode `--hook` (cf. §3.5 piège 3).

## 6. État du dépôt

Branche `feat/phase-20-fluidite-flux` créée depuis `main` (arbre propre). **Seul ce rapport y est
commité** — aucune modification de doctrine, d'agent, de script ou de `.planning/ROADMAP.md`.
`STATE.md` **non touché** : la phase n'a pas avancé, et une entrée `stopped_at` sur une branche non
mergée serait trompeuse. Branche non poussée, pas de PR : prématuré pour une mission gelée sans
changement substantiel.

## 7. Next step

Trancher D1→D4, puis relancer la mission au nœud `discuss-20` — les 4 nœuds d'instruction n'ont pas
à être rejoués, leurs résultats sont dans ce fichier.
