# Contrat de sortie des hooks VibeFlow — et inventaire recompté du parc

**Document DURABLE** (pas un artefact de phase) : la polarité gouvernance (Willy) en hérite pour sa
propre migration en forme exec des 20 entrées qui lui restent (§7 du contrat PR #29). Produit par
le plan `VFDO-30-04` (Portabilité Windows II, PORT-03), le 2026-08-15 ; l'inventaire est mis à jour
par le plan `VFDO-30-09` (ajout de la 26e entrée, `check-hook-paths.sh`), le même jour.

---

## 1. Le contrat de sortie

À la frontière du **harness** Claude Code (pas à l'intérieur d'un script), trois codes et rien
d'autre :

- **0** = rien à signaler, OU un signal a été émis normalement (le cas nominal du hook).
- **non nul** = le script n'a pas pu faire son travail — une vraie erreur, jamais un signal
  déguisé.
- **2** — réservé au blocage explicite par le harness (`PreToolUse`/`Stop`/`UserPromptSubmit`
  peuvent bloquer l'appel d'outil ou l'arrêt de session sur ce code précis) — n'est **jamais**
  émis involontairement par un script qui ne veut pas bloquer.

Le contrat de signaux **interne** posé par la Phase 17 (exit 3 = silence volontaire, exit 0 =
signal émis, exit 64 = erreur d'argument) **reste valide À L'INTÉRIEUR des scripts** — ce plan ne
le touche pas. Ce qui change, c'est sa **traduction vers le harness** : `|| true` en forme shell
absorbait tout aveuglément ; en forme exec, cet opérateur n'existe plus, donc chaque script doit
porter lui-même sa traduction.

## 2. La règle de traduction — conditionnée, jamais globale

La traduction du code de silence interne (3) vers 0 est **conditionnée au drapeau de mode hook
(`--hook`)**, jamais un renommage global. Sans le drapeau (CLI, suites de tests), **tous les codes
restent inchangés**.

**Pourquoi** : la CLI (un appelant manuel, `gsd-progress`, un script tiers) et les suites de tests
existantes testent ces codes directement — `rc=3` explicitement asserté. Un renommage global
`exit 3` → `exit 0` casserait ces deux usages. Le point de traduction doit vivre en un seul endroit
nommé (`hook_exit`, voir la tâche 2 de ce plan), déclenché uniquement quand `--hook` est posé.

Aucun lanceur intermédiaire (`run-hook.sh <script>`) n'est introduit : il réintroduirait une
indirection shell qui contredirait l'objectif même de la forme exec sous Windows (D-06).

## 3. Le silence est un contrat de FLUX, pas seulement de code

Sur `SessionStart`, la documentation officielle Claude Code confirme que le **stdout d'un hook
qui sort en 0 est injecté comme contexte de session** — pas seulement journalisé en debug. Un
chemin nominal silencieux doit donc avoir un **stdout strictement vide** (zéro octet), pas
seulement un code de sortie 0 : une ligne vide accidentelle, un warning non redirigé, romprait le
silence promis même à code de sortie correct.

Les diagnostics humains (`say()` et équivalents) vont systématiquement sur **stderr**, jamais sur
stdout — c'est déjà la convention en place dans les 4 scripts du périmètre dev (task 2 de ce plan
le vérifie et le corrige si besoin).

### 3 bis. Quand le stdout n'est PAS vide : un seul objet, encodé

Le silence est le chemin nominal, mais un hook qui a quelque chose à dire est soumis à une
seconde règle, tout aussi contraignante :

- **UN SEUL** objet JSON par exécution. Le harness parse en strict : deux objets concaténés sur
  stdout, même individuellement valides, forment un document invalide et lèvent « Hook output
  looks like a JSON object but is not valid JSON ». Un script dont plusieurs fonctions émettent
  chacune leur objet doit donc les agréger avant de rendre.
- **Encodé par un encodeur**, jamais par concaténation de chaînes (`json.dumps`, `ConvertTo-Json`,
  `jq -n`, `JSON.stringify`) — sans quoi un guillemet, un backslash ou un retour à la ligne dans
  une valeur casse le document. Un encodeur écrit dans le script lui-même (awk, échappement des
  guillemets, backslashs et contrôles, octets UTF-8 rendus tels quels) en est un : `guard-fin-de-geste.sh`
  n'a ni `jq` ni `python3` à son PATH dans le hook, et sa suite prouve l'encodage avec un PATH réduit.

⚠ **Piège de vérification** : `jq` ne suffit PAS à valider un stdout de hook. `jq` lit un *flux*
d'objets et accepte donc sans broncher `{...}{...}`, que le harness rejette. Vérifier avec un
parseur de **document** (`json.loads`, `JSON.parse`) :

```bash
bash <hook> | python3 -c 'import json,sys; json.loads(sys.stdin.read() or "{}")'
```

C'est exactement ce trou de vérification qui a laissé passer le défaut de l'entrée #18 : le §3
ci-dessus n'avait été appliqué à cette entrée que sur son *code de sortie*, jamais sur son flux.

## 4. L'inventaire — 37 entrées, recompte machine

Commande de recomptage (fait foi, D-08) :

```bash
python3 -c "import json,glob; n=sum(len(h.get('hooks',[])) for f in sorted(glob.glob('plugin/*/hooks/hooks.json')) for gs in json.load(open(f))['hooks'].values() for h in gs); print(n); assert n==37, n"
```

Rendue le 2026-08-17 : `28` (27 recomptées plus tôt le même jour par le plan `32-03`, plus 1 :
l'entrée n°28, `check-guard-health.sh`, `SessionStart · startup`, posée par le plan `32-05`
(QUAL-01, le « hook doctor » spécifié depuis le 2026-08-02 et jamais écrit). Née en forme exec
(D-32-C), **une seule entrée** (pas de piège d'idempotence cross-matcher ici : `SessionStart` du
module `conductor` n'a qu'un seul groupe `startup`, cette entrée s'y ajoute simplement). L'entrée
n°27 (`guard-driver-lock.sh`, matcher `Bash|Write|Edit`, plan `32-03`) est inchangée : **une seule
entrée, pas deux** — D-32-05 envisageait deux entrées séparées (matcher `Bash`, matcher
`Write|Edit`) mais cette forme s'est avérée EMPIRIQUEMENT incompatible avec la purge d'idempotence
cross-matcher de `merge-hooks.sh` (elle retire toute entrée référençant les mêmes scripts dans
TOUS les groupes de l'événement de la cible — la seconde entrée installée supprimait
systématiquement la première). Voir `32-03-SUMMARY.md` pour la reproduction complète. Rendue le
2026-08-18 : `29` — l'entrée n°29, `check-requirements-survival.sh`, `SessionStart · startup`,
posée par le plan `18-01` (LEDG-02, survie du ledger d'exigences à la clôture d'un jalon), ajoutée
au même groupe `startup` UNIQUE de `dev-orchestrator` (même contournement de la dette
d'idempotence cross-matcher que les entrées précédentes de ce module, jamais corrigée ici). Rendue le
2026-09-30 : `31` — les entrées n°30 et n°31, `guard-fin-de-geste.sh` (`SessionStart` sans matcher avec
`--snapshot`, puis `Stop`), posées par le plan `41.3-04` (SOBR-07, ADR-076), chacune dans son propre
groupe du module `conductor` (un seul script par groupe : aucune collision d'idempotence cross-matcher).
Rendue le 2026-10-02 : `33` — les entrées n°32 et n°33 de `planning-core`, nées sur la Phase 45 sous
les numéros 30 et 31 puis renumérotées à l'intégration de `main` (les numéros 30 et 31 y étaient déjà
pris par `guard-fin-de-geste.sh`) : l'entrée n°32, `planning-hook.sh`,
`PreToolUse · Write|Edit|NotebookEdit|Bash|Agent|Task`, Phase 45 (45-01) : le hook central du
moteur de planning, en forme shell (commande inline), **une seule entrée** au matcher combiné
(deux entrées sous deux matchers se purgeraient, comme pour l'entrée n°27). L'entrée n°24
(`Stop`, exit 2 voulu) reste inchangée (P45-D-19). L'entrée n°33, `check-gates-alive.sh`,
`SessionStart · startup`, Phase 45 (45-03) : le canary de session du hook central, advisory, en
forme shell `|| true`, ajouté au groupe `startup` UNIQUE de `planning-core`.
Rendue le 2026-10-03 : `37` — les entrées n°34 à n°37 de `planning-core`, nées sur la Phase 46 (46-04, P46-D-09,
P46-D-10) : le hook central reçoit désormais **cinq événements par UNE commande enregistrée, au texte identique
sous chacun** ; l'entrée n°32 reste celle de `PreToolUse`, dont le matcher unique est élargi à `SubagentHandback`
(jamais un second groupe : la purge de `merge-hooks.sh` l'écraserait), et la même commande est posée sous
`SessionStart` (n°34, dans le groupe sans matcher existant, à côté du cliché de session), `SubagentStop` (n°35),
`CwdChanged` (n°36) et `FileChanged` (n°37), chacune dans son propre groupe sans matcher. Seule la n°35 peut bloquer
(décision JSON `decision: "block"`, code 0, jamais le code 2) ; les n°34, n°36 et n°37 ne refusent jamais.
L'événement de mise à jour de tâche n'est pas câblé (P46-D-01).
Toute dérive future (une 38e entrée apparue, une entrée disparue) fait échouer cette assertion —
bruyamment, jamais en silence — et impose de mettre à jour l'inventaire et l'assertion
**ensemble**, jamais l'un sans l'autre.

**Colonnes** : module · événement · matcher · script · arguments d'invocation (au-delà du chemin du
script lui-même) · `--hook` accepté (oui/non — et s'il change le CODE de sortie ou seulement le
rendu, quand c'est pertinent) · codes de sortie atteignables **aujourd'hui**, avec cette invocation
exacte · classement **advisory** ou **bloquante**, avec le mécanisme · forme actuelle
(shell/exec) · action requise par la Phase 30 (normalisation, migration, ou rien).

### conductor — 10 entrées

| # | Événement · matcher | Script | Invocation (hors chemin script) | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 1 | PreToolUse · Write | `guard-agent-write.sh` | (aucun) | non | 0 (toujours, fail-open) | **bloquante** — décision JSON `permissionDecision: deny` sur écriture d'agent non conforme (ADR-044), jamais via le code de sortie | shell | rien (déjà 0 systématique, pas de `\|\| true` dans le fragment) |
| 2 | SessionStart · startup | `check-agents.sh` | `--hook --agents-dir=… --skills-dir=…` | oui — n'altère AUJOURD'HUI que le rendu (compact) ; le script documente lui-même « exit 0 toujours » en mode `--hook` | 0 (déjà systématique sous `--hook`) | advisory (SessionStart, ADR-031) | shell + `\|\| true` | rien (déjà conforme au contrat cible) |
| 3 | SessionStart · startup | `check-debug-research.sh` | `--hook --agents-dir=… --skills-dir=…` | oui — même profil que #2 (« exit 0 toujours » sous `--hook`) | 0 (déjà systématique) | advisory (ADR-031) | shell + `\|\| true` | rien |
| 4 | SessionStart · startup | `update-banner.sh` | (aucun — pas de flag `--hook` dans ce script) | n/a | 0 (systématique, « Toujours exit 0 » documenté) | advisory (ADR-031) | shell + `\|\| true` | rien |
| 5 | SessionStart · startup | `check-branch-claim.sh` | `--hook` | oui — **ne change QUE le rendu**, jamais le code de sortie (documenté explicitement dans le script) | 0 (signal), 3 (SAIN/silence), 4 (INDÉTERMINÉ — 3e état hors du contrat 0/3/64, cf. contrat amont §4 « n'a pas pu tourner »), 64 (usage, jamais atteint via ce fragment) | advisory — « ne bloque rien, ne relâche aucun lock » (en-tête explicite, ADR-031) | shell + `\|\| true` | normalisation (30-06) — silence porté par 3/4, pas par 0 ; sans `\|\| true` ces deux codes fuiraient comme erreur harness |
| 6 | SessionStart · startup | `check-workstream-pointer.sh` | `--hook` | oui — documenté explicitement : « ne change AUCUN code de sortie », rendu seul | 0 (conforme), 1 (échec constaté, advisory), 2 (NON VÉRIFIABLE), 3 (silence, non partitionné), 64 (usage) | advisory — « il ne corrige rien, ne bloque rien » (en-tête explicite) | shell + `\|\| true` | normalisation (30-06) |
| 27 | PreToolUse · Bash\|Write\|Edit | `guard-driver-lock.sh` | `args: ["{{VF_SCRIPTS}}/guard-driver-lock.sh"]`, `command: {{VF_BASH}}` | n/a (pas de flag) | 0 (toujours, fail-open à quatre issues — QUAL-01) ; **17** atteignable si aucun interprète n'est joignable (fail-open BRUYANT, `vf_guard_unavailable`) | **bloquante** — décision JSON `permissionDecision: deny` (LOCK-02/03 : commit/checkout/switch/merge/rebase/… Bash, ou écriture Write/Edit sous `.planning/`, D-32-B, d'une session tierce sous lock vivant), jamais par le code de sortie | **exec** (né conforme, D-32-C, contrat PR #29 §5) | née à l'état cible (plan 32-03) — **une SEULE entrée à matcher combiné, pas deux** : voir la note du §4 (purge d'idempotence cross-matcher de `merge-hooks.sh`, découverte empirique du plan 32-03) |
| 28 | SessionStart · startup | `check-guard-health.sh` | `args: ["{{VF_SCRIPTS}}/check-guard-health.sh", "--hook"]`, `command: {{VF_BASH}}` | oui — `--hook` traduit SAIN (3) et INDÉTERMINÉ (4) vers 0 ; le signal (déjà 0) et l'usage (64) ne sont jamais traduits | 0 (silence STRICT si aucun marqueur récent, OU signal — une seule ligne — si au moins un garde du parc a écrit un marqueur récent), 64 (usage, jamais atteint via ce fragment) | **advisory** — le « hook doctor » de QUAL-01 : constate, ne corrige rien, ne bloque rien (ADR-031) ; lecture seule STRICTE du répertoire de santé | **exec** (né conforme, D-32-C, contrat PR #29 §5) | née à l'état cible (plan 32-05) — GÉNÉRIQUE : agrège les marqueurs de TOUS les gardes du parc écrits par `vf_guard_unavailable`, pas seulement ceux de `conductor` |
| 30 | SessionStart (sans matcher) | `guard-fin-de-geste.sh` | `args: ["{{VF_SCRIPTS}}/guard-fin-de-geste.sh", "--snapshot"]`, `command: {{VF_BASH}}` | `--snapshot` (mode, pas `--hook`) | 0 (toujours ; hors dépôt armé par `.planning/.fin-de-geste-armed` : muet, aucun effet ; silence STRICT sur le chemin nominal, sinon UN document JSON `{"systemMessage": …}` pour un `NON VÉRIFIABLE` — fail-open bruyant) | **advisory** — photographie en lecture seule ce qui est déjà rangeable, ne bloque jamais le démarrage | **exec** (né conforme, contrat PR #29 §5) | née à l'état cible (plan 41.3-04) |
| 31 | Stop | `guard-fin-de-geste.sh` | `args: ["{{VF_SCRIPTS}}/guard-fin-de-geste.sh"]`, `command: {{VF_BASH}}` | n/a | 0 (autorise ; hors dépôt armé par `.planning/.fin-de-geste-armed` : muet, aucun effet ; silence ou UN document JSON `systemMessage` pour ce qui doit être vu de l'utilisateur), 2 (bloque : du rangement attribué à la session reste ; au plus 3 blocages de suite sans progrès — progrès = plus petit que le plus bas atteint —, puis sortie visible ; toute écriture d'état ratée : sortie visible, exit 0) | **bloquante — par le code de sortie** (2, `Stop`), seule autre que #24 ; coupe-circuit à 3 blocages sans progrès (arbitrage Samuel, AskUserQuestion session principale, 2026-09-30) | **exec** (né conforme, contrat PR #29 §5) | née à l'état cible (plan 41.3-04) |

### consolidator — 7 entrées

| # | Événement · matcher | Script | Invocation | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 7 | PreToolUse · Read | `guard-read-registres.sh` | (aucun) | non | 0 (toujours, fail-open) | **bloquante** — décision JSON `permissionDecision: deny` (lecture hors index-first) | shell | rien |
| 8 | PreToolUse · Bash | `guard-bash-registres.sh` | (aucun) | non | 0 (toujours, fail-open) | **bloquante** — décision JSON `permissionDecision: deny` | shell | rien |
| 9 | PostToolUse · Edit\|Write\|Bash | `post-edit-reindex.sh` | (aucun) | non | 0 (toujours, fail-open : « un hook de maintenance ne casse jamais le flux ») | advisory | shell + `\|\| true` | rien |
| 10 | SessionStart · startup | `seed-registres.sh` | `--project --quiet` | non (pas de flag `--hook` dans ce script) | 0, 1 (gabarits introuvables — module mal installé) | advisory (instanciation mémoire, ADR-032 ; ne bloque rien mais le 1 est aujourd'hui masqué) | shell + `\|\| true` | normalisation (30-06) |
| 11 | SessionStart · startup | `check-registres.sh` | `--hook` | oui — « exit 0 toujours » documenté sous `--hook` | 0 (systématique) | advisory | shell + `\|\| true` | rien |
| 12 | SessionStart · startup | `probe-memory-guards.sh` | (aucun — `--strict` existe mais n'est pas passé par ce fragment) | non | 0 (systématique sans `--strict` : « Silence = tout va bien. Advisory : exit 0 ») | advisory | shell + `\|\| true` | rien |
| 13 | SessionEnd · (aucun matcher) | `archive.sh` | `--async --apply` | non | 0 (mode async : retour immédiat, la tâche réelle se relance en arrière-plan) | advisory | shell + `\|\| true` | rien |

### dev-orchestrator — 6 entrées (périmètre code des plans 30-04/30-07/30-09, 18-01)

| # | Événement · matcher | Script | Invocation | `--hook` | Codes AVANT normalisation (30-04) | Codes APRÈS normalisation (30-04) | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 14 | SessionStart · startup | `check-dev-bootstrap.sh` | `--hook` | oui — avant cette phase, parité d'interface SEULE (n'altérait rien) | 0 (signal onboard/bootstrap), 3 (silence, OU orientation `[gsd-engine]` — sortie non vide, D-14), 64 (usage) | 0 (silence traduit + tous les signaux), 64 | advisory (les 4 SessionStart de dev-orchestrator sont advisory par ADR-031) | shell (migration forme exec : plan 30-07) | **normalisation livrée ici (tâche 2)** ; migration forme exec restant à 30-07 |
| 15 | SessionStart · startup | `discover-unintegrated-docs.sh` | `--hook` | oui — même profil | 0 (au moins un doc non intégré), 3 (rien à intégrer), 64 (usage) | 0 (silence traduit + signaux), 64 | advisory | shell (30-07) | normalisation livrée ici ; migration à 30-07 |
| 16 | SessionStart · startup | `check-doc-drift.sh` | `--hook` | oui — même profil | 0 (seuil atteint), 3 (rien à signaler), 64 (usage) | 0 (silence traduit + signaux), 64 | advisory | shell (30-07) | normalisation livrée ici ; migration à 30-07 |
| 17 | SessionStart · startup | `check-gsd-config.sh` | `--hook` | oui — même profil | 0 (au moins un signal `[gsd-config]`), 3 (aligné/illisible), 64 (usage) | 0 (silence traduit + signaux), 64 | advisory | shell (30-07) | normalisation livrée ici ; migration à 30-07 |
| 26 | SessionStart · startup | `check-hook-paths.sh` | `--hook` | oui — traduit le silence interne (3→0), ne change pas le rendu | sans objet — entrée **née conforme** (plan 30-09) | 0 (silence traduit, et signal `[hook-paths]` sur constat), 1 (« verdict non rendu » — réglages illisibles ou interpréteur Python absent, bruyant sur stderr, stdout vide), 64 (usage) | **advisory** (ADR-031 — constate, ne répare rien, ne bloque jamais le démarrage) | **exec à `command` littéral** (nom nu `bash`, seule entrée du parc dans ce cas) | née à l'état cible (plan 30-09) |
| 29 | SessionStart · startup | `check-requirements-survival.sh` | `--hook` | oui — traduit le silence interne (3→0), ne change pas le rendu | sans objet — entrée **née conforme** (plan 18-01) | 0 (silence traduit, et signal `[ledger-absent]` / `[ledger-illisible]` / `[ledger-outil-absent]` / `[ledger-exigences-disparues]` selon le cas — issue 2bis JAMAIS traduite vers le silence, A-18-08), 3→0 (silence, cran avertissement A-18-02), 64 (usage) | **advisory** (ADR-031 — constate, ne corrige rien, ne bloque jamais le démarrage ; lecteur d'absence, jamais juge de contenu, D-18-10) | **exec** (né conforme, D-01, contrat PR #29 §5) | née à l'état cible (plan 18-01) |

**Dérogation de l'entrée n°26 à ADR-071 §Décision 2** — cette entrée est la SEULE du parc dont le
`command` est un nom nu (`bash`), là où ADR-071 §Décision 2 exige, pour toutes les autres, un chemin
absolu d'interpréteur résolu et vérifié à l'install, **sans clause d'exception**. La raison est le
paradoxe d'amorçage : ce script diagnostique la péremption d'un chemin d'interpréteur figé à
l'install (angle mort assumé de D-01, one-way) — s'il dépendait lui-même de ce chemin figé, il
mourrait exactement dans le cas qu'il sert à détecter. Cette dérogation est autorisée par
l'**approbation humaine de l'addendum du 2026-08-15**, **PAS par ADR-071 elle-même** — ni sa
Décision 2, ni sa section « Ce que cette ADR ne tranche pas » (qui vise la polarité gouvernance), ni
son « Déclencheur de réexamen » (dont la portée est cette même migration à venir, pas ce cas-ci) ne
documentent ce cas. Elle est gardée à la machine par le cas T9 de
`plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` (discriminance prouvée par
mutation). **Reliquat** : un amendement d'ADR-071 — ou une ADR dédiée — est dû pour fermer cet écart
entre la doctrine écrite et le parc réel ; `docs/ADR.md` est hors périmètre du plan `30-09` (geste
humain).

### infrastructure-audit — 1 entrée

| # | Événement · matcher | Script | Invocation | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 18 | SessionStart · startup | `audit-infra.sh` | `--quick --if-older-than=14d --hook` | **oui** — porte à la fois la traduction du silence (3→0, `hook_exit`) **et le rendu du FLUX** (`hook_render`) | 0 (advisory systématique sans `--strict` ; le mode `--strict`, qui rendrait 1/3, n'est jamais atteint ici) | advisory (ADR-031) | shell + `\|\| true` | **stdout corrigé** — les axes écrivent un objet JSON CHACUN, donc `--quick` en émettait DEUX collés : document invalide au parsing strict du harness (`jq` l'acceptait — il lit un flux —, d'où la non-détection). Sous `--hook`, le flux est capturé et rendu en UN SEUL objet encodé (`json.dumps`), émis seulement s'il y a des findings ; stdout strictement vide sinon (§3) |

### planning-core — 12 entrées

| # | Événement · matcher | Script | Invocation | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 19 | SessionStart · startup | `check-planning-state.sh` | `--defer-to-gsd` | non | 0 (frais, ou moteur GSD actif → retrait en silence), 1 (STATE périmé, advisory), 2 (STATE absent, advisory), 3 (`.planning/` absent) | advisory — en-tête explicite : « de façon advisory, jamais bloquant » | shell + `\|\| true` | normalisation (30-06) — le silence n'est pas porté par 0 seul ici, redesign nécessaire |
| 20 | SessionStart · startup | `planning-context.sh` | `--defer-to-gsd` | non | 0 (systématique avec ces arguments — fail-open partout : « toute erreur → exit 0 silencieux ») | advisory | shell + `\|\| true` | rien |
| 21 | SessionStart · startup | `detect-planning-debt.sh` | (aucun) | non | 0 (aucune dette), 1 (au moins un compartiment en dette, **advisory** — documenté explicitement), 3 (racine des compartiments absente) | advisory (en-tête explicite : « advisory, jamais bloquant ») | shell + `\|\| true` | normalisation (30-06) |
| 22 | SessionStart · (aucun matcher, second bloc) | `planning-session-snapshot.sh` | (aucun) | non | 0 (systématique — toutes les branches observées sortent 0) | advisory (baseline d'attribution de session, ne bloque rien) | shell + `\|\| true` | rien |
| 23 | UserPromptSubmit · (aucun matcher) | `planning-task-context.sh` | (aucun) | non | 0 (systématique — fail-open sur toutes les branches observées) | advisory | shell + `\|\| true` | rien |
| 24 | Stop · (aucun matcher) | `guard-planning-updated.sh` | (aucun — **pas de `\|\| true`**) | non | 0 (fail-open, autorise l'arrêt), **2** (bloque l'arrêt — garde-fou de fin de session) | **bloquante** — bloque l'arrêt de session PAR CODE DE SORTIE (exit 2), et **c'est VOULU** : garde-fou machine-enforced « planning à jour avant de s'arrêter » (ADR-040/043/050/055) | shell, sans `\|\| true` | **rien — ne JAMAIS normaliser cette entrée** (la bloquer par exit 2 est le but du script, pas un défaut à corriger) |
| 32 | PreToolUse · Write\|Edit\|NotebookEdit\|Bash\|Agent\|Task\|SubagentHandback | `planning-hook.sh` | commande inline (commande enregistrée, `timeout: 20`) : lance `bash {{VF_SCRIPTS}}/planning-hook.sh` en fils et reprend tout code non nul | n/a (pas de flag) | 0 (toujours côté commande enregistrée — la décision est portée par le JSON) ; le lanceur interne `planning-hook.sh` rend, lui, 0, 3 (erreur Python avant l'adhésion), 70 à 72 et **73** (échéance interne de 8 s du cœur dépassée, ou lanceur disparu : stdout vide), que la commande reprend comme tout code non nul — fail-closed sous adhésion, silence ailleurs | **bloquante par décision JSON** (deny + code 0), jamais par exit 2 ; **fail-closed dans un lab adhérent seulement** (P45-D-06a), sur Write, Edit, NotebookEdit, Agent et Task, et depuis la Phase 46 sur SubagentHandback (le rapport d'un sous-agent, refusé sans dériver le rôle), Bash ouvert (P45-D-06b) — premier garde fail-closed du dépôt ; hors lab adhérent (labs dev, ce dépôt compris) : stdout vide, code 0 (P45-D-04) — **sauf cœur tombé** : un chemin portant un échappement JSON non géré (`\b`, `\f`, `\r`, `\uXXXX`) est refusé même hors de tout lab adhérent, le doute tombant du côté du refus (limite F4 de la référence du modèle, `PX=0` ferme sans condition ; décision du manager vf-dev-manager, 2026-10-01) ; de même, toujours cœur tombé et quel que soit le cwd, un champ `file_path`, `notebook_path` ou `cwd` dont l'extrait brut dépasse 4096 caractères et nomme `.planning` ou `.claude` (casse ignorée) est refusé avec le motif « chemin trop long pour etre analyse, il nomme .planning ou .claude » (`vf_get`, variable `G`) ; un chemin `~` ou `~/…` est développé en `$HOME`, par le cœur comme par la couche de repli, jamais lu comme relatif au cwd (si `HOME` n'est pas absolu, ou pour `~utilisateur/…`, le chemin est tenu pour non analysable) ; **court-circuit hors adhésion** (revue de Samuel sur la PR #124, arbitrage de Willy, AskUserQuestion session principale, 2026-10-02 : le pré-filtre seul, `Bash` reste dans le matcher) : la commande commence par `vf_pre && exit 0` — stdout vide, code 0, sans lancer ni le script, ni `mktemp`, ni `python3` — quand le lab est certainement non adhérent (aucun ancêtre du chemin écrit, du `cwd` du payload, de `$PWD` ni du cwd physique, sous forme lexicale ET physique, ne porte un `.planning` dont le `config.json` contient `cycles-v1` ou un antislash, est illisible ou n'est pas régulier) ; valeur longue (plus de 1024 caractères ou de 64 composants, correspondance brute de plus de 2048, plus de 16 valeurs ; config de plus de 64 Kio, ou plus de 64 lectures de config par exécution : coût borné par construction et indépendant du contenu du système de fichiers, re-audit du 2026-10-02, F-P1 à F-P4), antislash, `~`, relatif, `//`, `.`, `..`, `/.vol`, JSON non compact, clé échappée, lien pendant ou en boucle : jamais de court-circuit, le chemin d'avant reste identique octet pour octet ; ne peut que taire un « non adhérent », jamais créer un passage dans un lab adhérent (garde : `test-planning-prefilter.sh`) | **shell** (commande inline, jamais `{{VF_BASH}}` : la forme exec part dans `settings.local.json` et n'a pas de shell pour porter le test de présence) | rien (née conforme, Phase 45) |
| 33 | SessionStart · startup | `check-gates-alive.sh` | `--hook` | oui — traduit SAIN (3) et INDÉTERMINÉ (4) vers 0 ; le signal (déjà 0) et l'usage (64) ne sont jamais traduits | 0 (signal — UNE seule ligne, préfixe `[planning-core] canary :` : hook central non enregistré, **commande enregistrée non reconnue** (un réglage cite `planning-hook.sh` avec une commande qui n'est pas celle de référence : rien n'est exécuté), mode dégradé, **constantes d'armement absentes ou illisibles** (une table d'armement absente est désormais un SIGNAL en code 0, plus un code 4 traduit en silence sous `--hook`), gate armé sans canary, couverture minimale incomplète, cas en échec), 3 (SAIN : session hors lab adhérent, ou canary passé), 4 (INDÉTERMINÉ : réglages illisibles, aucun interpréteur Python — jamais un vert de complaisance), 64 (usage, jamais atteint via ce fragment) | **advisory** — rejoue la commande enregistrée sur un lab adhérent synthétique et signale, ne bloque jamais (P45-D-20) ; stdout strictement vide hors signal (§3) | shell + `\|\| true` | rien (née conforme, Phase 45) |
| 34 | SessionStart · (aucun matcher, second bloc) | `planning-hook.sh` | commande inline (la MÊME commande enregistrée que la n°32, `timeout: 20`) : lance `bash {{VF_SCRIPTS}}/planning-hook.sh` en fils et reprend tout code non nul | n/a (pas de flag) | 0 (toujours côté commande enregistrée) ; le lanceur interne rend, lui, 0, 3, 70 à 72 et 73, que la commande reprend : hors adhésion, stdout vide, code 0 par le pré-filtre `vf_pre` AVANT le script et AVANT tout `python3` (P46-D-16) ; mode dégradé (script ou `python3` absent) : stdout vide, code 0 (fail-open, limite (ap)) | **advisory** — ne refuse JAMAIS (livré en 46-07 : `watchPaths` et réconciliation de D1 ; objet `hookSpecificOutput`, jamais `decision` ni `permissionDecision`) ; toute erreur : silence, code 0 (fail-open déclaré, P46-D-10) | shell (commande inline, jamais `{{VF_BASH}}`) | rien (née conforme, Phase 46, 46-04) |
| 35 | SubagentStop · (aucun matcher) | `planning-hook.sh` | commande inline (la MÊME commande enregistrée que la n°32, `timeout: 20`) : lance `bash {{VF_SCRIPTS}}/planning-hook.sh` en fils et reprend tout code non nul | n/a (pas de flag) | 0 (toujours côté commande enregistrée) ; le lanceur interne rend, lui, 0, 3, 70 à 72 et 73, que la commande reprend : hors adhésion, stdout vide, code 0 par le pré-filtre `vf_pre` AVANT le script et AVANT tout `python3` (P46-D-16) ; mode dégradé (script ou `python3` absent) : stdout vide, code 0 (fail-open, limite (ap)) | **bloquante par décision JSON** (`decision: "block"` avec `reason`, code 0, JAMAIS le code 2 — #60490) quand G4′ sera armé (repli de G4′ hors mode auto, sans évaluation dans la 46-04) ; toute erreur : silence, code 0 (fail-open) | shell (commande inline) | rien (née conforme, Phase 46, 46-04) |
| 36 | CwdChanged · (aucun matcher) | `planning-hook.sh` | commande inline (la MÊME commande enregistrée que la n°32, `timeout: 20`) : lance `bash {{VF_SCRIPTS}}/planning-hook.sh` en fils et reprend tout code non nul | n/a (pas de flag) | 0 (toujours côté commande enregistrée) ; le lanceur interne rend, lui, 0, 3, 70 à 72 et 73, que la commande reprend : hors adhésion, stdout vide, code 0 par le pré-filtre `vf_pre` AVANT le script et AVANT tout `python3` (P46-D-16) ; mode dégradé (script ou `python3` absent) : stdout vide, code 0 (fail-open, limite (ap)) | **advisory** — ne refuse JAMAIS (livré en 46-07 : `watchPaths` de D1, sous la clé de premier niveau et sous `hookSpecificOutput`, jamais `decision` ni `permissionDecision`) ; racine lue dans `cwd` (limite (ao)) ; toute erreur : silence, code 0 | shell (commande inline) | rien (née conforme, Phase 46, 46-04) |
| 37 | FileChanged · (aucun matcher) | `planning-hook.sh` | commande inline (la MÊME commande enregistrée que la n°32, `timeout: 20`) : lance `bash {{VF_SCRIPTS}}/planning-hook.sh` en fils et reprend tout code non nul | n/a (pas de flag) | 0 (toujours côté commande enregistrée) ; le lanceur interne rend, lui, 0, 3, 70 à 72 et 73, que la commande reprend : hors adhésion, stdout vide, code 0 par le pré-filtre `vf_pre` AVANT le script et AVANT tout `python3` (P46-D-16) ; mode dégradé (script ou `python3` absent) : stdout vide, code 0 (fail-open, limite (ap)) | **advisory** — ne refuse JAMAIS (trace de D1, à venir) ; racine lue dans le `file_path` de premier niveau ; toute erreur : silence, code 0 | shell (commande inline) | rien (née conforme, Phase 46, 46-04) |

### software-architecture — 1 entrée

| # | Événement · matcher | Script | Invocation | `--hook` | Codes atteignables aujourd'hui | Classement | Forme | Action (Phase 30) |
|---|---|---|---|---|---|---|---|---|
| 25 | PreToolUse · Edit\|Write | `guard-file-size.sh` | `args: ["{{VF_SCRIPTS}}/guard-file-size.sh"]`, `command: {{VF_BASH}}` | n/a (pas de flag) | 0 (toujours, fail-open) | **bloquante** — décision JSON `permissionDecision: deny` (Iron Law 300L), et non par son code de sortie qui reste 0 même sur refus | **exec** (déjà migré, contrat PR #29 §5, D-01) | rien (déjà conforme au contrat cible ; PYBIN → `vf_python` reste hors périmètre de PORT-03) |

## 5. Le décompte

| Module | Total | Reproduit par |
|---|---|---|
| conductor | 10 | `python3 -c "import json; d=json.load(open('plugin/conductor/hooks/hooks.json')); print(sum(len(h.get('hooks',[])) for gs in d['hooks'].values() for h in gs))"` |
| consolidator | 7 | idem, `plugin/consolidator/hooks/hooks.json` |
| dev-orchestrator | 6 | idem, `plugin/dev-orchestrator/hooks/hooks.json` |
| infrastructure-audit | 1 | idem, `plugin/infrastructure-audit/hooks/hooks.json` |
| planning-core | 12 | idem, `plugin/planning-core/hooks/hooks.json` |
| software-architecture | 1 | idem, `plugin/software-architecture/hooks/hooks.json` |
| **Total** | **37** | commande de recomptage globale, §4 ci-dessus |

**Les deux entrées bloquantes mises en avant par le plan comme points de vigilance** (le
classement n'est PAS déductible mécaniquement du type d'événement, RESEARCH.md Pitfall 4) :

- **`guard-file-size.sh`** (#25, PreToolUse) — bloque en sortant **0**, via sa décision JSON. Une
  lecture qui ne regarderait que le code de sortie la classerait à tort advisory.
- **`guard-planning-updated.sh`** (#24, Stop) — bloque au contraire **par son code de sortie** (2),
  et c'est le comportement voulu : la seule entrée de tout le parc où « bloquante par code de
  sortie » est une garantie à préserver, jamais un défaut de normalisation à corriger.

**L'inventaire machine complet fait apparaître quatre bloquantes supplémentaires**, du même
mécanisme JSON que #25 : `guard-agent-write.sh` (#1), `guard-read-registres.sh` (#7),
`guard-bash-registres.sh` (#8) et **`guard-driver-lock.sh` (#27 PreToolUse·Bash\|Write\|Edit,
plan `32-03`, LOCK-02/03/05)** — chacune sort toujours 0 et bloque via `permissionDecision: deny`.
Soit **9 entrées bloquantes au total sur les 37** (7 via décision JSON + 2 via code de sortie : #24 et
#31, `guard-fin-de-geste.sh` au Stop, plan `41.3-04` ; la 6e via décision JSON est l'entrée #32,
`planning-hook.sh`, Phase 45, fail-closed dans un lab adhérent, et la 7e l'entrée #35, `planning-hook.sh`
sous `SubagentStop`, Phase 46 : blocage par `decision: "block"` en code 0), et **28 entrées advisory** (dont #30,
le snapshot de début de session ; +1 : l'entrée #28, `check-guard-health.sh`, plan `32-05`, +1 :
l'entrée #29, `check-requirements-survival.sh`, plan `18-01`, +1 : l'entrée #33,
`check-gates-alive.sh`, plan `45-03`, +3 : les entrées #34, #36 et #37, `planning-hook.sh` sous `SessionStart`,
`CwdChanged` et `FileChanged`, Phase 46 — toutes advisory, elles ne bloquent rien ou ne refusent jamais, ADR-031).

## 6. Ce qui reste à la polarité gouvernance

Les **26 entrées gouvernance** (conductor 6 — les entrées n°1 à n°6 —, consolidator 7,
infrastructure-audit 1, planning-core 12) restent à Willy. Le module `conductor` compte bien 10
entrées (§5), mais quatre d'entre elles relèvent de la polarité dev : `guard-driver-lock.sh` (#27,
plan `32-03`), `check-guard-health.sh` (#28, plan `32-05`) et les deux entrées de
`guard-fin-de-geste.sh` (#30 et #31, plan `41.3-04`), nées en forme exec. Les 11 entrées de
la polarité dev sont donc conductor 4, dev-orchestrator 6 et software-architecture 1 ; 26 + 11 = 37,
le total de la commande du §4. Les 26 entrées gouvernance restent à Willy pour :

- **La migration effective en forme exec** de leurs `hooks.json` — hors périmètre de cette phase
  (§7 du contrat PR #29).
- **L'ajout du drapeau de mode hook** (`--hook`) à leur ligne d'invocation, quand le script ne le
  porte pas encore (`update-banner.sh`, `guard-*-registres.sh`, `post-edit-reindex.sh`,
  `seed-registres.sh`, `probe-memory-guards.sh`, `archive.sh`, `planning-context.sh`,
  `detect-planning-debt.sh`, `planning-session-snapshot.sh`, `planning-task-context.sh`,
  `guard-agent-write.sh`) — c'est cette migration-là, pas cette phase, qui leur donne un point
  d'ancrage pour la traduction.

`planning-hook.sh` (#32, et ses entrées sœurs #34 à #37 sous quatre autres événements) est hors de ces deux listes. Sa forme est une commande shell inline,
sans drapeau, et elle le reste : la forme exec part dans `settings.local.json` et n'a pas de shell
pour porter le test de présence du script (ligne n°32 du §4). Elle n'a pas non plus besoin de
`--hook` : la commande enregistrée sort déjà toujours en 0 et porte sa décision dans le JSON.

**Leurs scripts sont normalisés côté script par le plan `30-06`**, sans que leurs fragments
`hooks.json` ne soient touchés par ce plan-là (D-07 : la normalisation de code de sortie couvre
tout le parc, la migration de forme exec reste, elle, bornée au périmètre dev cette phase).
`guard-planning-updated.sh` (#24) est **explicitement exclue** de cette normalisation à venir — son
blocage par code de sortie est voulu et ne doit jamais être traduit.

---

*Produit par le plan VFDO-30-04 (Portabilité Windows II — codes de sortie), 2026-08-15. Inventaire
mis à jour par le plan VFDO-30-09 (26e entrée, `check-hook-paths.sh`), le 2026-08-15, puis par le
plan VFDO-32-03 (27e entrée, `guard-driver-lock.sh`, matcher combiné, LOCK-02/03/05), puis par le
plan VFDO-32-05 (28e entrée, `check-guard-health.sh`, le « hook doctor » générique du parc,
QUAL-01), le 2026-08-17, puis par le plan VFDO-18-01 (29e entrée, `check-requirements-survival.sh`,
survie du ledger d'exigences à la clôture d'un jalon, LEDG-02), le 2026-08-18, puis par le plan
VFDO-45-01 (entrée `planning-hook.sh`, hook central fail-closed du moteur de planning, GATE-01 à
GATE-03, née n°30), le 2026-09-29, puis par le plan VFDO-45-03 (entrée `check-gates-alive.sh`, canary
de session du hook central, GATE-12, née n°31), le 2026-09-30, puis par le plan VFDO-41.3-04 (30e et
31e entrées, `guard-fin-de-geste.sh`, SOBR-07), le 2026-09-30, puis par le plan VFDO-45-10 (lignes
`planning-hook.sh` et `check-gates-alive.sh` mises à jour sur les corrections ciblées des lots A et C :
signaux du canary, code 73 du lanceur, refus `PX=0` hors lab), le 2026-10-01, puis à l'intégration de
`main` dans la branche de la Phase 45 (renumérotation des deux entrées de `planning-core` en n°32 et
n°33, les numéros 30 et 31 étant déjà pris sur `main` ; décompte recompté à 33 par la commande machine
du §4), le 2026-10-02, puis par le plan VFDO-46-04 (entrées n°34 à n°37 : la commande enregistrée de
`planning-hook.sh` sous `SessionStart`, `SubagentStop`, `CwdChanged` et `FileChanged`, matcher de l'entrée
n°32 élargi à `SubagentHandback` ; décompte recompté à 37 par la commande machine du §4), le 2026-10-03.*
