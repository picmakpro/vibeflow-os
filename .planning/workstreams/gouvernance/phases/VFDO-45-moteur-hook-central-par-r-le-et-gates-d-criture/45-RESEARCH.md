# Phase 45: Moteur — hook central par rôle et gates d'écriture - Research

**Researched:** 2026-09-29
**Domain:** hooks Claude Code 2.1.284 (PreToolUse fail-closed), shell POSIX portable, pose des hooks par `merge-hooks.sh`, gates d'écriture sur `.planning/`, hook par rôle
**Confidence:** HIGH sur le contrat du harnais, la technique d'extraction shell et le chemin d'install (tout mesuré sur ce poste) ; MEDIUM sur le comportement Linux/CI (non sondable ici : pas de daemon Docker, ni gawk, ni mawk) ; MEDIUM sur la sémantique de G1/G7 face aux labs réels (mesurée, mais arbitrages ouverts)
**Compartiment :** `gouvernance` (`--ws gouvernance`). Ce fichier est en lecture par le planificateur ; il ne modifie aucune décision de `45-CONTEXT.md`.

Convention de provenance : `[VERIFIED: sonde]` = mesuré cette session sur ce poste (macOS, bash 3.2.57, dash, zsh 5.9, ksh, grep/awk/sed BSD, Python 3.14.5, Claude Code 2.1.284) ; `[VERIFIED: chemin:lignes]` = fichier ouvert cette session, valeur citée verbatim ; `[CITED: url]` = doc officielle ; `[ASSUMED]` = non vérifié (listé en Assumptions Log). Les sondes vivaient dans le scratchpad de session (non versionné, éphémère) : tout ce qui doit survivre est **reporté ici** (code, corpus, résultats).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Drapeaux `phases_trace` / `gates` (Q1)

- **P45-D-01 :** `phases_trace` et `options.gates` du `config.json` restent **sans effet** sur le
  moteur. Aucun code de la 45 ne les lit. Les gates **s'arment avec l'adhésion `cycles-v1`**. Un
  gate ne se désarme **que par une dérogation nominative** (P45-D-13), jamais par un drapeau
  qu'un agent peut écrire (spec §5.2, règle 1). Cela ferme l'arbitrage renvoyé par la 44
  (P44-D-05). — **Reversibility:** costly. C'est le contrat d'armement des labs.
- **P45-D-01a (manager, dérivé de Q1) :** **périmètre de tous les gates et du hook par rôle = les
  labs adhérents.** Le lab d'une écriture est trouvé en remontant depuis le chemin écrit
  (P45-D-12). Il est adhérent si son `.planning/config.json` déclare `"planning_version":
  "cycles-v1"`, égalité stricte, même lecture que `verifier_adhesion` de la 44. Hors d'un lab
  adhérent, le hook **ne sort rien et rend 0** : allow implicite, aucun message.

### Lab métier qui contient du code (Q2)

- **P45-D-02 :** l'adhésion explicite `cycles-v1` **l'emporte sur le signal de code**. Quand le
  détecteur rend 2 (migration : STATE.md du socle v2 avec `planning_version` + fichier de code à
  la racine), `recalc-planning.sh` **écrit** si le lab a adhéré. Seul un **moteur GSD actif**
  (détecteur 0) continue de refuser (exit 3). Les autres verdicts « non concluant » de la 44
  (garde de lecture, énumération des compartiments) **restent des refus**. Seul le code 2 est
  levé, et seulement sous adhésion.
- **P45-D-02a (précision de Willy, même canal) :** **test de régression obligatoire**, qui prouve
  trois choses :
  - sans adhésion, le refus de la 44 est **inchangé** : même code de sortie (2), aucun fichier
    touché, cache compris ;
  - avec adhésion et détecteur 0, le refus reste (exit 3) ;
  - seule la combinaison adhésion + détecteur 2 écrit.

  Chaque branche a son jumeau négatif et sa mutation rouge tracée.
- **P45-D-02b (contrainte) :** `detect-gsd-engine.sh` et `workstream-policy.sh` restent **octet
  pour octet inchangés** (P44-D-01b, altitude lab des labs dev). La levée vit dans
  `recalc-planning.sh` seul.

### Ordre d'armement (Q3)

- **P45-D-03 :** **armement par étapes, dans un ordre fixe** :
  1. G6 et G5 ;
  2. G1 ;
  3. G7 ;
  4. le hook par rôle.

  **G2 avertit dès le départ.** Il ne refuse jamais dans cette phase. Chaque étape n'est armée
  (refus réel) qu'après deux preuves :
  - son **canary** passe (P45-D-20) ;
  - sa **mesure de faux refus dans les deux sens** est faite, d'abord **en CI** sur le banc
    synthétique, puis par un **rejeu en lecture seule sur Keystone et BusinessFlow** (P45-D-21).

  L'ordre des étapes est l'ordre des vagues du plan. Une étape suivante n'est jamais armée avant
  la précédente.
- **P45-D-03a (manager) :** l'état « armé / en observation » d'un gate vit **dans le code livré**
  du plugin (constante ou table du script). Il ne vit **jamais** dans un fichier du lab (spec
  §5.2, règle 1). Un gate en observation journalise ce qu'il aurait refusé, sans refuser.
- **P45-D-03b (manager, seuil) :** armer une étape exige **0 faux refus** sur le banc synthétique
  **et** sur le rejeu des deux labs réels, et **0 faux accept** sur le corpus « doit refuser ». Un
  compte non nul n'arme pas l'étape : il remonte à Willy avec le relevé (chemins, gate, raison).
  Aucun seuil de tolérance n'est décidé en mission.

### Portée du hook par rôle (Q4)

- **P45-D-04 :** le hook par rôle ne s'applique qu'aux **labs métier adhérents à `cycles-v1`**.
  Les labs dev, **ce dépôt compris**, restent inchangés. Motif : la ligne « Worker : tout dispatch
  refusé », appliquée à un lab dev, casse la chaîne `vf-coder` → briques GSD (B1). — **Zéro
  régression dev, prouvée par une mesure qui peut rougir** : sur un lab dev fixture et sur ce
  dépôt, le hook ne sort rien (octet vide) et rend 0, quel que soit l'appel. La mutation « ignorer
  l'adhésion » rend la preuve rouge.

### Source du rôle (Q5)

- **P45-D-05 :** le rôle est **dérivé du frontmatter** de la définition d'agent par les prédicats
  existants de `check-agents.sh` :
  - **juge** = I5 : `disallowedTools` retire Write **et** Edit, aucune allowlist `Agent(...)` non
    vide ;
  - **manager** = I6 : allowlist `Agent(...)` non vide, pas `vf-internal` ;
  - **worker** = `vf-internal: true` et pas juge ;
  - **producteur** = tout autre agent résolu.

  Aucun champ `vf-role:` et aucune table centrale.
- **P45-D-05a (manager, contrainte) :** la dérivation du hook et la classification de
  `check-agents.sh` ne doivent pas diverger. Un **contrôle croisé** sur tout le corpus d'agents du
  dépôt et sur les fixtures le prouve, à la manière du contrôle référence ↔ moteur de la 44. Deux
  implémentations sont acceptées : appeler la logique de `check-agents.sh` (dépendance
  planning-core → conductor, à motiver) ou la réimplémenter. En cas de réimplémentation, le
  contrôle croisé est obligatoire et doit pouvoir rougir. Le planificateur choisit et motive.
- **P45-D-05b (manager) :** la **résolution** `agent_type` → fichier de définition suit un ordre
  écrit dans la référence du modèle : agents du lab, puis agents du compte, puis agents de plugin
  (`plugin:nom`). Un nom ambigu (deux définitions contradictoires) vaut **inconnu**.
- **Ligne « producteur »** (écrire un verdict) : elle est couverte par G5, qui refuse toute
  écriture de `VERDICT.md` par outil, quel que soit le rôle (P45-D-07). La table du §5 reste
  exacte, sans règle en double dans le code.

### Hook ou dépendance absent (Q6)

- **P45-D-06 :** **fail-closed**. La **commande enregistrée** dans les réglages teste elle-même
  la présence du script et de `python3`. Si l'un manque, elle émet le **refus JSON** avec un
  **message de réparation** : ce qui manque, et comment le poser. Coût assumé : dans un worktree
  non préparé, les écritures d'un lab adhérent sont refusées jusqu'à réparation. Le **timeout**
  reste un fail-open du harnais, sans réglage possible (`45-SCOUTING.md` A.2e) : le canary est
  obligatoire de toute façon.
- **P45-D-06a (manager, contrainte de cohérence avec P45-D-04) :** le fail-closed ne vaut **que
  pour un lab adhérent**. La commande enregistrée doit donc décider « adhérent ou non »
  **sans python3** : extraire le chemin écrit ou le `cwd` du payload, remonter jusqu'au
  `config.json`, y chercher la déclaration d'adhésion. Un lab dev sans `python3`, ou avec un
  script absent, **n'est jamais refusé**. **C'est le point technique le plus risqué de la
  phase.** La recherche du plan doit montrer que l'extraction du payload sans python est sûre
  (JSON échappé, chemins avec espaces ou guillemets) et, en cas de doute, **fermer** dans le
  doute pour un chemin sous un `.planning/` adhérent.

### Décisions déléguées, validées par Willy (même canal, reconfirmation après /clear)

- **P45-D-07 :** la phase livre la **commande qui pose `VERDICT.md`**. Elle écrit le hash sha256
  de l'artefact jugé et le numéro de tentative, au format de la 44 (`modele-cycles.md`). **G5
  refuse toute écriture de `VERDICT.md` par outil** (`Write`, `Edit`, `NotebookEdit`), quel que
  soit le rôle. Un juge pose son verdict par cette commande : c'est l'exception « sauf son verdict
  posé par commande » de la table du §5. La **vérification** du hash à la clôture reste en 46.
- **P45-D-08 :** le refus passe **toujours** par `hookSpecificOutput.permissionDecision: "deny"`
  avec exit 0, **jamais** par exit 2 (DIV-2, spec §5.1). Toute erreur interne du script est
  piégée et rendue en deny, dans le périmètre adhérent.
- **P45-D-09 :** le matcher de dispatch est **`Agent|Task`**, et les deux `tool_name` sont
  testés (la doc et les issues se contredisent, `45-SCOUTING.md` A.3b). `tool_input.subagent_type`
  est normalisé : casse et séparateurs, comme le harnais depuis v2.1.140.
- **P45-D-10 :** les écritures par **Bash** ne sont **pas couvertes** par les refus : c'est une
  limite déclarée (spec §5, « du théâtre »). G2 avertit aussi sur `PreToolUse(Bash)` quand la
  commande nomme un chemin hors `ecrit:`. C'est une détection, jamais une promesse. La limite est
  écrite dans la référence du modèle et dans le message d'avertissement.
- **P45-D-11 :** un **fil principal** (`agent_id` absent) ou un `agent_type` **inconnu** ne reçoit
  que la ligne « Tous » et les gates G1, G5, G6 et G7. C'est une limite déclarée : un juge dont la
  définition n'est pas trouvée n'est pas traité en juge. Le canary compte ces cas.
- **P45-D-12 :** la **racine du lab** se dérive du **chemin écrit** (`tool_input.file_path`,
  toujours absolu), ou du `cwd` du payload pour un dispatch, **jamais** de `$CLAUDE_PROJECT_DIR`.
  Ce dernier ne suit pas `EnterWorktree` (`45-SCOUTING.md` A.5a).
- **P45-D-13 :** la **dérogation** est nominative : qui, canal, date, gate, chemin(s), avec une
  **raison qui n'est pas un placeholder** (vide, `TODO`, `xxx`, `…`, `<…>` sont refusés). Elle est
  inscrite par une commande dans un **journal append-only protégé par G6**. Elle n'est **jamais
  conditionnée à l'urgence** (spec §5.2). Le planificateur fixe sa durée de vie (usage unique ou
  borné) et la motive. Une dérogation active est **visible** : le hook la cite dans le message de
  sortie de l'action qu'elle laisse passer.
- **P45-D-14 :** **G7 est fail-closed.** Créer un `.planning/` sous un lab adhérent exige, dans
  le dossier parent, un **`.claude/` habité** (au moins un agent et une mémoire) ou un **marqueur
  de projet de code** (même liste que `detect-gsd-engine.sh`). Le prédicat littéral de « habité »
  est écrit dans la référence du modèle. Cas visé : les quatre plannings orphelins de
  BusinessFlow (spec D-05).
- **P45-D-15 :** **un seul script**, dans `plugin/planning-core/`, en Python embarqué dans un
  `.sh` (voie a de P44-D-14 : l'installeur ne pose pas de `.py`), posé par `hooks.json`. La
  commande enregistrée de P45-D-06 est sa seule porte d'entrée.
- **P45-D-16 :** les **suites tournent en CI Linux**, sans dépendance GNU/BSD : pas de `stat -f`,
  pas de `sed -i`, pas de `timeout` (absent du poste). Les commandes de boucle des plans se
  rejouent sous zsh **et** bash avec au moins deux éléments.
- **P45-D-17 :** exigences sous le préfixe **`GATE`**. Vérifié libre le 2026-09-29 par deux
  commandes : `git grep -lE 'GATE-[0-9]'` et `grep -rliE 'GATE-[0-9]' .planning docs plugin
  scripts` rendent 0 fichier. Témoin : `MOTR-[0-9]` rend 25 fichiers. Les exigences sont posées
  au `REQUIREMENTS.md` du compartiment avant le plan.
- **P45-D-18 :** **bump mineur** de `planning-core` (v2.8.0 → v2.9.0, nouvelle capacité),
  CHANGELOG et README du module. **Aucune release** : pas de `VERSION` racine, pas de tag, avant
  la clôture de `fiabilite-v1.0`. Si une PR de `fiabilite` bumpe aussi `planning-core`, la 45 se
  renumérote après son merge.
- **P45-D-19 :** `guard-planning-updated.sh` **n'est pas retiré** (ADR-031 : suppression de code
  sous validation humaine). Il reste l'exception exit 2 déjà connue, hors du nouveau hook.

### Canary et mesure (délégué pour le mécanisme, contraint par la spec §5.1)

- **P45-D-20 :** un **canary par gate armé** rejoue la **commande enregistrée telle quelle**
  (celle des réglages, pas un appel direct au script) sur un payload qui doit être refusé, et
  vérifie qu'il obtient un `deny`. Il tourne à deux endroits :
  - **en CI**, où son échec est bloquant ;
  - **au démarrage de session** d'un lab adhérent, où il signale sans bloquer, dans la famille de
    `check-guard-health.sh`.

  Il couvre au minimum :
  - le script absent ;
  - `python3` absent ;
  - un payload `Task` et un payload `Agent` ;
  - un fil principal ;
  - un `agent_type` préfixé `plugin:`.
- **P45-D-21 :** les faux refus se mesurent **dans les deux sens**, par gate :
  - un corpus « doit passer » : écritures légitimes d'un lab adhérent ;
  - un corpus « doit refuser ».

  Le **rejeu sur les labs réels** (`~/jarvis-keystone`, `~/BusinessFlow-Lab`) suit ces règles :
  - il tourne **hors CI** et en **lecture seule** ;
  - il travaille sur une **copie** dans un dossier temporaire, où l'adhésion est simulée, ou par un
    mode d'évaluation qui n'écrit rien ;
  - les payloads sont construits à partir des fichiers réels ;
  - aucune écriture n'est faite dans les labs, ce qui est prouvé par une empreinte sha256 de
    l'arbre avant et après, comparée par `cmp` (motif P44-D-06b) ;
  - aucune commande `git` n'est lancée dans ces labs ;
  - les chemins machine-locaux restent dans les artefacts de phase, sous la forme `~/…`, jamais
    dans le code livré ni dans une suite de CI.

### Claude's Discretion

Laissés au planificateur :
- nom du script et des commandes (verdict, dérogation) ;
- format du journal de dérogation ;
- structure interne du Python ;
- ordre de résolution fin des définitions d'agent (sous P45-D-05b) ;
- durée de vie d'une dérogation (sous P45-D-13) ;
- découpage en plans, dans l'ordre des vagues imposé par P45-D-03.

### Deferred Ideas (OUT OF SCOPE)

- G2′, G3, G4, G4′, D1 : Phases 46 et 47. Vérification du hash de `VERDICT.md` : Phase 46.
- Retrait de `guard-planning-updated.sh` et du socle v2 : sous validation humaine, hors 45.
- Tolérance de faux refus non nulle : n'est pas décidée en mission ; elle remonte à Willy si le
  rejeu la rend nécessaire (P45-D-03b).
- Hook managed (seul à résister à `disableAllHooks`) : hors périmètre. Le gate détecte et trace,
  il ne verrouille pas.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-01 | script central unique, adhérents seuls, racine dérivée du chemin/`cwd`, silence hors lab adhérent | R1 (technique, précédence chemin > cwd), R2 (une seule entrée `hooks.json`), Pitfalls 1, 6 |
| GATE-02 | refus = `deny` JSON + exit 0 ; erreur interne piégée en deny | Architecture (deux couches, code de retour ≠ 0 avant adhésion connue → couche shell décide), Patterns 2-3 |
| GATE-03 | la commande enregistrée émet elle-même le deny ; adhésion décidée sans python3 | **R1 (sondé : 39 cas × 6 shells, 936 appels E2E, 0 échec)**, code de la commande, F2, F3 |
| GATE-04 | G6 : STATE/INDEX/cloture.log/journal | Patterns G6, Pitfalls 4-5, F6, F7 (`.recalc-cache.json`, `config.json`), mesure réelle 13 STATE.md + 3 INDEX.md |
| GATE-05 | commande de verdict + G5 | Pattern verdict, F8 (3 juges sur 4 sans Bash), hash de `PLAN.md` (A3) |
| GATE-06 | G1 | Pattern G1 (états dérivés `à cadrer`/`en cadrage`), F5 (405/405 sur Keystone), sémantique `registre-invalide` |
| GATE-07 | G7 | Pattern G7, F4 (prédicat « habité » vs mesure des deux labs), liste de marqueurs de code verbatim |
| GATE-08 | G2 avertit | Canal `additionalContext` **vérifié** (F11), pas de deny |
| GATE-09 | hook par rôle + contrôle croisé | Oracle différentiel **sondé** (4 juges, 5 managers), F9 (workers dispatcheurs), résolution `agent_type` |
| GATE-10 | zéro régression dev | Corpus dev + ce dépôt, mutation « ignorer l'adhésion » (M5/MI6 rouges) |
| GATE-11 | dérogation nominative | Pattern dérogation, fichier racine à déclarer (`NOMS_MODELE_RACINE_FICHIERS`), échappement injectif du journal |
| GATE-12 | canary | R3 (suite d'install as-installed sans toucher `ci.yml`), canary de session, table pilotée par l'état d'armement |
| GATE-13 | mesure deux sens, ordre des vagues | R3 (banc texte, rapport, seuil 0), F4-F5-F7 : rejeu réel **non nul par construction**, checkpoints |
| GATE-14 | levée du code 2 sous adhésion | R3 points d'insertion (l.680-684, l.1851-1852) + liste des tests à réécrire, F10 |
| GATE-15 | suites CI Linux, mutations, bump, pas de release | R4, chores (README suites, HOOKS-CONTRAT, consommateurs), Validation Architecture |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Directives applicables à cette phase (`CLAUDE.md` racine et `CLAUDE.local.md`, traitées comme des décisions verrouillées) :

- **Aucune release** avant la clôture de `fiabilite-v1.0` (CLAUDE.local.md) ; le bump de `planning-core` (v2.9.0) ne touche ni `VERSION` racine ni tag (CLAUDE.md « Quand publier », ADR-073).
- **Commits en français**, avec **traçabilité des arbitrages** (canal + date, jamais un « arbitrage Samuel » nu) ; identifiants de décision **préfixés** (`P45-D-NN`), convention prospective.
- **Trailer `Gate-Touche:`** sur tout commit qui touche un gate, sa suite, `.github/workflows/ci.yml` ou un hook. Mesuré : la **surface machine** de G-2 est plus étroite que la prose (voir R3) ; poser le trailer sur tout commit qui touche `hooks.json` ou le script de hook reste la lecture conservatrice.
- **Jamais de fix sans validation humaine (ADR-031)** : le retrait de `guard-planning-updated.sh` reste hors phase ; les findings F4-F10 sont **à arbitrer**, pas à corriger en mission.
- **Densité ADR-029** : aucun agent touché ici (le planificateur ne doit pas en créer).
- **`STATE.md` du compartiment se met à jour à la main** (jamais `state.begin-phase` / `state.record-session`), frontmatter fermé avant la ligne 60 ; **toute commande GSD passe `--ws gouvernance`** ; un worktree = une session ; jamais de `cd` nu vers un autre worktree.
- **CI = `fiabilite` seul** : les gates du compartiment `gouvernance` se rejouent à la main (`--file .planning/workstreams/gouvernance/STATE.md`).
- **`main` protégée côté serveur** : `.github/` et `scripts/hooks/` exigent la revue code owner (`@picmakpro`) ; une PR qui touche `ci.yml` ne peut pas être auto-relue. Conséquence de conception (R3) : porter le canary de CI **en suite** (`*/tests/test-*.sh`, découverte automatique) évite d'éditer `ci.yml`.
- **Chemins machine** : `scripts/check-machine-paths.sh` (gate CI) rejette tout `/Users/<compte>/…` ou `/home/<login>/…` dans un fichier suivi. Les fixtures et suites de la phase ne doivent en porter aucun ; `~/…` n'est admis que dans les artefacts de phase (P45-D-21).

## Summary

La phase est à 80 % de l'ingénierie du contrat du harnais. **Tout ce qui pouvait être mesuré l'a été sur Claude Code 2.1.284** (payloads réels capturés par un hook de capture injecté via `--settings`, trois sessions `claude -p` minimales) : le payload est du JSON **compact** dont l'ordre des clés est `session_id, transcript_path, cwd, prompt_id, permission_mode, [agent_id, agent_type], hook_event_name, tool_name, tool_input, tool_use_id` ; le dispatch a pour `tool_name` **`Agent`**, et les matchers `Agent`, `Task` et `Agent|Task` **se déclenchent tous trois** ; un dispatch **imbriqué** porte l'`agent_type` de l'appelant ; la forme shell d'une entrée est exécutée par **`/bin/sh -c`** (bash 3.2 en mode posix sur macOS) ; le `cwd` du payload est le chemin **physique** alors que `$PWD` hérité est logique ; un `deny` JSON + exit 0 émis par une commande de forme shell **bloque réellement un `Write`** et son motif arrive verbatim au modèle, tandis qu'un hook au script absent (127) laisse passer ; `hookSpecificOutput.additionalContext` sur un `allow` **atteint le modèle** (canal du G2 et de la citation d'une dérogation).

Le risque n°1 (P45-D-06a) est **résolu par une technique concrète et prouvée** : la commande enregistrée est une **couche shell POSIX** (`grep`, `head` et builtins seulement) qui décide « lab adhérent ou non » sans python, fait passer la charge utile au script Python quand il est là, et retombe sur un **deny statique** quand le script, python3 ou le script lui-même échouent (tout code ≠ 0 est traité comme une défaillance). Sur 39 cas adverses × 6 shells (bash 3.2.57, dash, sh, ksh, zsh en émulation sh et natif) : 39/39 ; 936 appels de bout en bout (4 shells × 6 modes de défaillance × 39 cas) : 0 échec, appel le plus lent 68 à 97 ms selon la passe ; 8 mutations rouges sur la couche d'extraction et 7 sur la commande enregistrée, chacune avec sa trace. **Un piège mortel a été mesuré** : `${var#*motif}` est **quadratique sous bash 3.2** (95 s sur 200 Ko quand la clé est en fin de charge utile), donc fail-open par timeout ; la technique retenue ne s'en sert jamais sur la charge utile.

Les mesures sur les **labs réels** (lecture seule) changent le plan de charge : le rejeu de P45-D-21 rendra un **compte non nul par construction** sur Keystone (G1 : 405 `PLAN.md` de forme modèle, dont 197 sans `CADRAGE.md` et 208 à `CADRAGE.md` de format hérité, **0** conforme ; G7 : le prédicat littéral classe `00-doctrine` en orphelin, contre la table D-05 de la spec ; G6 : 13 `STATE.md` et 3 `INDEX.md` écrits à la main aujourd'hui) — donc, selon P45-D-03b, **aucune de ces étapes ne s'armera sans arbitrage de Willy**. Le plan doit livrer chaque gate **en observation**, avec le rapport (chemin, gate, raison) et un point de décision, plutôt que supposer un rejeu à zéro.

**Primary recommendation :** (1) enregistrer **une seule entrée `PreToolUse`** de **forme shell** dans `settings.json` (matcher `Write|Edit|NotebookEdit|Bash|Agent|Task`, `timeout` explicite) dont le `command` est la couche shell décrite en R1 ; (2) faire du `.sh` un **lanceur Python** (charge utile transportée par fichier temporaire, programme en heredoc sur stdin) qui décide exactement ; (3) tout livrer **en observation** dans une table d'armement du code livré, armer vague par vague après canary + rapport de rejeu, avec un point de décision humain à chaque étape dont le rejeu est non nul.

## FINDINGS (à arbitrer — aucune décision de CONTEXT n'est réécrite)

| # | Constat | Preuve | Effet sur le plan | Sévérité |
|---|---|---|---|---|
| F1 | **Pas de contradiction Task/Agent sur 2.1.284** : `tool_name` = `Agent` ; les matchers `Agent`, `Task`, `Agent\|Task` se déclenchent tous ; un dispatch imbriqué déclenche PreToolUse avec l'`agent_type` de l'appelant. | `[VERIFIED: sonde 2]` 4 étiquettes M-Agent/M-Task/M-AgentOrTask/M-star sur le même appel | P45-D-09 tient ; garder les deux `tool_name` dans les tests (coût nul, protège d'une régression amont #95769) | info |
| F2 | **La forme exec `{{VF_BASH}}` part dans `settings.local.json`** (non committé, machine-spécifique). Un worktree ou clone neuf n'a alors **aucune entrée enregistrée** : le fail-closed de P45-D-06 ne peut pas s'exprimer, faute de commande. En forme exec il n'y a **pas de shell** : le test de présence ne peut pas vivre dans `command`. | `[VERIFIED: sonde merge-hooks]` ; `[VERIFIED: merge-hooks.sh:27-31]` « (jamais committé) » ; `[CITED: code.claude.com/docs/en/hooks]` « no shell involved » | **Recommandation : forme shell** (`bash {{VF_SCRIPTS}}/…`-like, jeton `{{VF_SCRIPTS}}` seul) → `settings.json`, committable, présente dans un worktree neuf. Le « Integration Point » de CONTEXT (forme exec) est une option, pas une exigence | HIGH (conception) |
| F3 | **`${v#*motif}` est quadratique sous bash 3.2** : 95,3 s pour extraire une clé située à la fin d'une charge utile de 254 Ko ; le timeout du harnais est un fail-open. | `[VERIFIED: sonde]` `real 95.28` ; la même charge en `case` glob : 0,02 s | Toute extraction « à la main » par expansion de paramètres sur la charge utile est **interdite** ; R1 utilise un seul `grep -o` (linéaire : 111 ms à 5 Mo) puis ne décode que la valeur | HIGH |
| F4 | **Prédicat « habité » de P45-D-14 vs table D-05** : `~/jarvis-keystone/00-doctrine/.claude/` et `~/BusinessFlow-Lab/projects/formation/.claude/` ont exactement la même signature (un seul dossier `agent-memory/`), or la spec les classe l'un « lab » (zéro orphelin), l'autre « orphelin ». Avec « ≥ 1 agent ET ≥ 1 fichier de mémoire » : `00-doctrine` = orphelin (faux) ; `FROZEN-A1` = orphelin (5e, hors des quatre) ; quatre labs `projetflow-staging` = habités. | `[VERIFIED: sonde lecture seule]` tableau en R3 ; `[VERIFIED: docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md:156-165]` | G7 ne pourra pas s'armer à zéro faux refus sans arbitrage du prédicat (P45-D-03b) ; prévoir le point de décision | HIGH |
| F5 | **G1 sur Keystone : 405/405 refus par construction.** 405 `PLAN.md` de forme modèle (`cycles/*/phases/*[/plans/*]`) : 197 sans `CADRAGE.md` dans la phase, 208 avec un `CADRAGE.md` sans clé `inconnues:` (format hérité → `registre-invalide`), **0** au format de la 44. | `[VERIFIED: sonde lecture seule]` | Décider la sémantique de G1 face à `registre-invalide`/`indéterminé` (refuser ou laisser passer + avertir). Recommandation : refuser **seulement** `à cadrer` et `en cadrage` (états dérivés), jamais l'`indéterminé` | HIGH |
| F6 | **L'adhésion est un drapeau que l'agent peut écrire** (`config.json` : `"planning_version"`), et G6 ne le protège pas : `Edit` de `.planning/config.json` (`cycles-v1` → `2.0`) **désarme tous les gates**, contre la règle 1 du §5.2 que P45-D-01 invoque. La spec §10 range aussi « le seuil de juge (`config.json`) » en refus de classe G5. GATE-04/05 ne les listent pas. | `[VERIFIED: spec §5.2 règle 1, §10 ; recalc-planning.sh:274-301]` | Étendre G6/G5 à `.planning/config.json` (changement ou retrait de `planning_version`, seuil de juge) avec dérogation — **hors des listes de GATE-04/05 : arbitrage requis** | HIGH |
| F7 | **`.recalc-cache.json`** : `modele-cycles.md:585` confie sa protection à G6 ; GATE-04 ne le liste pas. **Nouveau fichier racine** (journal de dérogation) : tout nom inconnu à la racine de `.planning/` sort en « Hors modèle » dans `INDEX.md` tant qu'il n'est pas déclaré dans `NOMS_MODELE_RACINE_FICHIERS`. | `[VERIFIED: modele-cycles.md:585 ; recalc-planning.sh:751-754]` | Ajouter `.recalc-cache.json` au périmètre G6 ; déclarer le journal dans `NOMS_MODELE_RACINE_FICHIERS` (même fichier que GATE-14 : sérialiser les tâches) | MEDIUM |
| F8 | **Trois des quatre juges livrés n'ont pas Bash** : `quality-gate-client`, `content-clarity-judge`, `growth-quality-judge` déclarent `tools: Read, Glob, Grep` ; seul `vf-design-judge` a `Bash`. « Un juge pose son verdict par cette commande » (P45-D-07) n'est exécutable que par ce dernier. Les cinq managers (`Read, Write, Bash, …`) le peuvent. | `[VERIFIED: sonde awk sur les frontmatters]` | La commande de verdict sera lancée par le **manager** (rapport du juge → commande) ou les juges doivent recevoir `Bash` (changement d'agents, hors phase). À trancher ; le hash et la tentative viennent de la commande, pas du juge | HIGH |
| F9 | **Quatre workers dispatcheurs livrés** (`vf-auditer`, `vf-coder`, `vf-reviewer`, `vf-test-orchestrator` : `vf-internal: true` **et** allowlist `Agent(...)` non vide). P45-D-05 les classe « worker » → « tout dispatch refusé » : c'est exactement la rupture B1, **dans un lab métier adhérent** qui installe `design-orchestrator` (`vf-design-manager` dispatche `vf-coder`/`vf-reviewer`). | `[VERIFIED: sonde awk]` ; `vf-design-manager` : `Agent(vf-crafter, vf-design-judge, vf-coder, vf-reviewer, …)` | Lecture cohérente proposée : « le worker ne dispatche que ce que **sa propre allowlist** autorise (allowlist vide = tout refusé) » — le hook applique enfin une allowlist que le runtime n'applique pas. Change la ligne du §5 : **arbitrage requis** | HIGH |
| F10 | **GATE-14 casse des tests existants et écrase du contenu à la main.** (a) `test-recalc-planning.sh` assert `3` pour `socle-signal` à 6 endroits (voir R3). (b) Sous adhésion + détecteur 2, la première écriture **remplace** le `STATE.md` (et `INDEX.md`) du socle v2 rédigés à la main, sans sauvegarde ; le message du détecteur dit lui-même « ne rien réécrire ». Mesuré : 13 `STATE.md` et 3 `INDEX.md` existent dans les deux labs réels. | `[VERIFIED: detect-gsd-engine.sh:185-187 ; test-recalc-planning.sh:2683,2719,2809,2942-2965 ; sonde g6]` | La levée est décidée (Q2) ; **la perte du contenu hérité est une conséquence à faire arbitrer** (sauvegarde `.bak` ? note de migration ?). ADR-031 | MEDIUM |
| F11 | **Canal d'avertissement mesuré** : `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"…"}}` + exit 0 (sans `permissionDecision`) **arrive au modèle** (observé dans cette session : les avertissements du hook GSD `gsd-workflow-guard.js` apparaissent en contexte, source lue). | `[VERIFIED: sonde + source du hook]` | G2 et « dérogation active visible » (P45-D-13) empruntent ce canal ; ne pas utiliser `systemMessage` (DIV-3 : n'atteint pas le modèle) | info |
| F12 | **P45-D-01a « en remontant depuis le chemin »** ne dit pas quoi faire des labs **emboîtés** (Keystone : 6 `.planning/` dont 5 sous une racine ; BusinessFlow : 10). | `[VERIFIED: sonde]` | Recommandation : le lab = **le plus proche ancêtre qui contient un `.planning/`** (le plus proche gagne) ; pour G7 (création), l'ancêtre existant le plus proche | MEDIUM |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Enregistrement et fail-closed du hook | Réglages du harnais (`settings.json`, forme shell) | Installeur (`merge-hooks.sh`) | Seule la commande enregistrée survit à un script/interpréteur absent (P45-D-06) |
| Décision « lab adhérent ? » sans python | Couche shell (commande enregistrée) | — | Doit exister quand le script ou python manquent ; POSIX sh + `grep`/`head` |
| Décision exacte, gates G1/G5/G6/G7, rôle | Script Python embarqué (`planning-core`) | Modèle de données 44 (parser de frontmatter, états) | Logique riche, JSON, hash, résolution d'agents : hors de portée du shell |
| État d'armement des gates | **Code livré** (table du script) | — | Jamais dans un fichier du lab (§5.2 règle 1, P45-D-03a) |
| Dérogation et journal | Commande Bash (Python) + fichier append-only sous `.planning/` | G6 (protection du journal) | Le journal est un écrit de commande, refusé par outil |
| Commande de verdict (hash + tentative) | Commande Bash (Python) | G5 (refus des écritures par outil) | Le juge/manager ne fabrique jamais le hash |
| Levée du code 2 sous adhésion | `recalc-planning.sh` seul | Détecteur inchangé (P45-D-02b) | Frontière posée par la 44 |
| Canary (CI) | Suite `*/tests/test-*.sh` (découverte CI) | Étape `lab-frais-arme` (option) | Échec bloquant sans éditer `ci.yml` |
| Canary (session) | Hook `SessionStart` de `planning-core` (signale, ne bloque pas) | `check-guard-health.sh` (famille) | P45-D-20 |
| Mesure des faux refus | Banc texte versionné + outil de rejeu lecture seule (hors CI) | Rapport à Willy | P45-D-21, seuil 0 |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| POSIX `sh` (dash, bash 3.2 en mode posix, busybox ash) | — | couche shell de la commande enregistrée | `[VERIFIED: sonde]` la forme shell tourne sous `/bin/sh -c` ; `[CITED]` doc : `sh -c` sur macOS/Linux |
| `grep` (`-a -o -E`, `LC_ALL=C`) et `head -n 1` | BSD grep 2.6.0 / GNU | localiser les clés JSON, parité des `\` par regex | `[VERIFIED: sonde]` linéaire, 111 ms à 5 Mo ; seuls outils externes de la couche shell |
| Python 3 (stdlib : `json`, `os`, `re`, `stat`, `hashlib`) | 3.14.5 sur ce poste ; ≥ 3 requis | moteur exact des gates, hash sha256, parse de la charge utile | Précédent 44 (`recalc-planning.sh`), `dag.sh` ; `json` = parseur de **document** (piège jq, HOOKS-CONTRAT §3 bis) |
| `bash` | 3.2.57 (macOS) / 5.x (CI) | lanceur du script (`bash "$S"`), suites de tests | `[VERIFIED: ci.yml:218]` suites lancées par `bash "$t"` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `merge-hooks.sh` / `vibeflow-update.sh` | dépôt | pose/retrait/idempotence | déclarer l'entrée dans `plugin/planning-core/hooks/hooks.json` |
| `check-agents.sh` (oracle) | dépôt | contrôle croisé du rôle | test croisé **dans `scripts/tests/`** (multi-modules), pas dans les tests installés de `planning-core` |
| `python3 -I -S` | — | interpréteur du hook | `-I` (= `-E -s`, ignore `PYTHON*` et `cwd` dans `sys.path`) et `-S` (pas de `site`) : 26 ms au lieu de 38 ms `[VERIFIED: sonde]` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `grep -o` pour borner la valeur | `awk` (`index`/`substr`) | 343 ms à 5 Mo contre 111 ; **mais** les gates de dépôt (`check-machine-paths.sh`, consommateurs) bannissent `grep` par prudence (« le `grep` de certains runtimes de dev est proxifié et TRONQUE ») — ce risque vise les commandes tapées dans l'outil Bash d'un poste, pas la commande d'un hook (`/usr/bin/grep`, mesuré). À garder en tête pour les **commandes de vérification** des plans : utiliser `awk` |
| Transport de la charge utile par fichier temporaire | `python3 -I -S /dev/fd/3 3<<'PY'` (payload sur stdin) | `[VERIFIED: sonde]` marche sous bash 3.2, dash, zsh, sh sur macOS, sans résidu disque ; **Linux non sondé** `[ASSUMED]`. Le fichier temporaire est le patron du dépôt (merge-hooks.sh « transport par fichier ») : **le retenir par défaut**, l'autre en optimisation après preuve en CI |
| Programme Python via `python3 -c "$PROG"` | — | **Interdit** : un argv unique est plafonné (~128 Ko sous Linux `[ASSUMED]`, noyau `MAX_ARG_STRLEN`) — le programme grossira ; et le heredoc dans `$(...)` **casse bash 3.2** (voir R1) |
| Forme exec `{{VF_BASH}}` + `args:["-c", …]` | forme shell | voir F2 : la forme exec atterrit en `settings.local.json` |

**Installation :** aucune dépendance à installer. `python3` et `bash` sont des prérequis déjà déclarés du dépôt.

**Version verification :** pas de paquet externe ; versions d'outils mesurées ci-dessus (`gsd_run query package-legitimacy` non applicable : aucune installation de paquet).

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | — | Aucun paquet externe : stdlib Python + outils POSIX déjà requis |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 harnais Claude Code 2.1.284
   PreToolUse(Write|Edit|NotebookEdit|Bash|Agent|Task)   payload JSON compact sur stdin
        │
        ▼
 ┌──────────────────────────────────────────────────────────────────────────────┐
 │ COMMANDE ENREGISTRÉE  (settings.json, forme shell, `/bin/sh -c`, timeout 20)  │
 │  I=$(cat)                                                                     │
 │  script présent ? ── oui ──► O=$(printf %s "$I" | bash "$S") ; R=$?           │
 │        │ non                     │ R=0 : rejouer $O tel quel (silence ou 1 JSON)│
 │        ▼                         │ R≠0 : ▼                                     │
 │  CHEMIN DÉGRADÉ (shell pur : grep+head) ◄──────────────────────────────────── │
 │   tool_name ∈ {Write,Edit,NotebookEdit} ? non → exit 0 (Bash/Agent jamais)    │
 │   file_path|notebook_path (décodé) → cd -P → plus proche .planning/           │
 │      → config.json contient "planning_version":"cycles-v1" ? (TIGHT)          │
 │   sinon cwd du payload, sinon $(pwd -P)                                       │
 │   adhérent → deny JSON statique (message de réparation), exit 0               │
 │   sinon    → silence, exit 0                                                  │
 └───────────────┬──────────────────────────────────────────────────────────────┘
                 ▼  (script présent)
 ┌──────────────────────────────────────────────────────────────────────────────┐
 │ planning-hook.sh  (bash) : mktemp 0600 ← stdin ; python3|python -I -S - "$T"  │
 │   Python : json.loads → lab = plus proche .planning/ (realpath) → adhérent ?  │
 │      non → rien, exit 0                      (GATE-10 : octet vide)           │
 │      oui → table d'armement (code livré) : G6 G5 G1 G7 rôle = observe|armed   │
 │            G2 = avertit (additionalContext)  dérogation active → citée        │
 │      erreur AVANT adhésion connue → exit ≠ 0  (le shell décide)               │
 │      erreur APRÈS adhésion connue → deny JSON, exit 0   (P45-D-08)            │
 └──────────────────────────────────────────────────────────────────────────────┘
   canary CI (suite)  : rejoue la commande enregistrée telle quelle sous 6 modes
   canary de session  : SessionStart, même rejeu sur lab synthétique, signale seulement
```

### Recommended Project Structure
```
plugin/planning-core/
├── hooks/hooks.json                       # +1 entrée PreToolUse (forme shell), +1 SessionStart (canary de session)
├── scripts/
│   ├── planning-hook.sh                   # lanceur bash + Python embarqué (nom : discrétion du planificateur)
│   ├── check-gates-alive.sh               # canary de session (--hook, hook_exit 3/4 → 0)
│   ├── recalc-planning.sh                 # GATE-14 : l.680-684 et l.1851-1852 ; + NOMS_MODELE_RACINE_FICHIERS
│   └── tests/
│       ├── test-planning-hook-registered.sh   # commande enregistrée : extraction, arbre, modes, mutations
│       ├── test-planning-gates.sh             # sémantique des gates, rôle, dérogation, verdict, dev-lab
│       ├── test-recalc-planning.sh            # GATE-14 (tests réécrits + jumeaux)
│       └── fixtures/gates-banc.txt            # banc TEXTE (format du banc 44) : corpus « doit passer / doit refuser »
plugin/_internal/tests/test-planning-hook-installed.sh   # as-installed : install réelle → rejeu de la commande posée
scripts/tests/test-role-hook-vs-check-agents.sh          # contrôle croisé rôle ↔ check-agents.sh (multi-modules)
plugin/planning-core/references/modele-cycles.md         # tables d'armement, prédicat « habité », limite Bash, ordre de résolution
docs/HOOKS-CONTRAT-SORTIE.md                             # inventaire 29 → 31 (test-check-hook-paths.sh T12)
plugin/conductor/references/workstream-planning-consumers.md   # recensement si le script porte `.planning/…STATE.md` sur une ligne
```

### Pattern 1 : couche shell = décideur fail-closed, script = décideur exact
**What:** la commande enregistrée ne fait confiance à rien de ce qui peut manquer. Elle lit la charge utile, lance le script **en fils** (pas `exec`), rejoue sa sortie si `R=0`, et **traite tout code ≠ 0** (script absent, `bash` absent, python absent, plantage, syntaxe) comme une défaillance qu'elle tranche elle-même.
**When to use:** toujours (GATE-01/02/03).
**Code:** voir « Code Examples » (commande complète, testée).

### Pattern 2 : le refus des gates est un objet JSON unique, encodé par `json.dumps`
`{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"…"}}` + exit 0 `[VERIFIED: sonde 3 ; CITED hooks]`. Un seul objet par exécution (`docs/HOOKS-CONTRAT-SORTIE.md` §3 bis) ; vérifier avec `json.loads` (jamais `jq` : il accepte `{}{}`). Le message de repli du shell est **statique** (aucune valeur dynamique interpolée : l'encodage JSON en shell est un trou d'injection).

### Pattern 3 : erreur avant/après adhésion
Python range son `main()` en deux temps : (1) résoudre lab + adhésion dans un bloc minimal ; en cas d'exception, `sys.exit(3)` **sans rien imprimer** (la couche shell, indépendante, tranche) ; (2) une fois le lab adhérent établi, tout le reste est sous `try/except BaseException` → `deny` explicite exit 0 (P45-D-08). Un plantage avant l'adhésion connue ne peut donc ni refuser un lab dev ni laisser passer un lab adhérent.

### Pattern 4 : table d'armement dans le code livré
`GATES = {"G6": "observe", "G5": "observe", "G1": "observe", "G7": "observe", "ROLE": "observe", "G2": "warn"}` (constante du script). En `observe`, le gate calcule son verdict, l'**écrit dans un journal utilisateur** (hors lab, sur le modèle du dossier `${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}` de `vf-portable.sh` : chemin, gate, raison — **jamais** le contenu écrit, qui peut porter des secrets) et laisse passer. Passer une vague à `armed` = **un commit d'une constante**, conditionné à un point de décision humain quand le rejeu est non nul. Le canary itère la table : un gate passé à `armed` sans cas de canary rougit la suite.

### Pattern 5 : G6 compare des identités, pas des chaînes
Sur APFS (insensible à la casse) `.planning/state.md` et `.PLANNING/STATE.md` **sont** `STATE.md`, un lien dur `hard.md` aussi, et `os.path.realpath` **ne normalise pas la casse** `[VERIFIED: sonde]`. Règle : pour une cible existante, `os.path.samefile(cible, protégé)` ; pour une création, comparer `casefold()` du nom relatif à la racine `realpath` du `.planning/`. Le refus par excès de casse sur Linux est un faux refus théorique à zéro cas réel (corpus « doit passer »).

### Pattern 6 : G1 lit l'état dérivé du modèle 44, il ne le réimplémente pas seul
G1 refuse l'écriture (`Write` **et** `Edit` : le prédicat porte sur le `CADRAGE.md` de la phase, pas sur le contenu du `PLAN.md`) d'un `PLAN.md` dont la phase est `à cadrer` (pas de `CADRAGE.md`) ou `en cadrage` (au moins une ligne `structurante: oui` à `statut` vide). **Restreindre G1 à `<lab>/.planning/cycles/*/phases/<unité>/PLAN.md` et `…/plans/<unité>/PLAN.md`** : un `PLAN.md` hors modèle (socle v2 : `.planning/phases/…`) ne doit jamais être refusé. La phase est `<unité>` = le dossier parent, ou grand-parent quand `plans/` est traversé. Le parser de frontmatter de la 44 (`parse_frontmatter`, grammaire de `modele-cycles.md` § « Grammaire du frontmatter ») est en Python **dans un heredoc** de `recalc-planning.sh` : non importable. Réimplémenter (≈ 60 lignes) **et** prouver l'accord par un contrôle croisé : sur chaque phase d'un banc, `G1 refuse ⇔ état dérivé de `recalc-planning.sh --read-only` ∈ {`à cadrer`, `en cadrage`}`.

### Pattern 7 : G7 — création d'un `.planning/`
Détection : le chemin écrit a un composant `.planning`, dont le parent `X` n'a **pas** de dossier `X/.planning` existant. Périmètre : l'ancêtre existant le plus proche de `X` qui contient un `.planning/` est adhérent. Refus sauf `X/.claude/` habité ou marqueur de code dans `X`. **Marqueurs de code (verbatim, `detect-gsd-engine.sh:175-181`)** `[VERIFIED]` :

```
  for f in package.json go.mod Cargo.toml pyproject.toml pom.xml build.gradle \
           build.gradle.kts composer.json Gemfile tsconfig.json Package.swift; do
    [ -f "./$f" ] && return 0
  done
  # Projet Xcode : dossier *.xcodeproj à la racine.
  for f in ./*.xcodeproj; do [ -d "$f" ] && return 0; done
```
La liste est **dupliquée** dans le Python : un test extrait la liste du détecteur (texte) et la compare à celle du script (rouge si écart).

### Pattern 8 : commande de verdict et de dérogation (Bash, Python)
Ce sont des **commandes**, donc hors du périmètre des gates (D-10) : ce qu'elles écrivent n'est jamais refusé par G5/G6, qui ne voient que les outils `Write`/`Edit`/`NotebookEdit`.
- **Verdict** : arguments = phase/plan, juge, tentative, score, constats. La commande calcule **elle-même** le sha256 (`hashlib`) de l'artefact jugé et l'écrit avec `tentative`. Artefact haché : `[ASSUMED]` le `PLAN.md` de l'unité (`modele-cycles.md:338` : « son hash reste **stable** … ce que consommeront les verdicts hachés de la Phase 46 ») — à confirmer (A3). Écriture atomique (`tmp` + `os.replace`), refus si le fichier existe déjà sans `--tentative` incrémentée.
- **Dérogation** : journal **append-only** (`O_APPEND`), champs encodés par le même **encodage pourcent injectif** que `_jeton_journal` de la 44 (jamais d'injection de ligne par une raison contenant un saut de ligne). Refus des raisons placeholder (vide, `TODO`, `xxx`, `…`, `<…>`) **après** normalisation Unicode. Nom du fichier : **ne pas** réutiliser `DEROGATION.md` (déjà pris par la dérogation de phase/plan, P44-D-07) ; ex. `derogations-gates.log`, à déclarer dans `NOMS_MODELE_RACINE_FICHIERS` (F7). Durée de vie recommandée : **usage unique par (gate, chemin)** — la consommation s'enregistre par une ligne ajoutée (le journal est append-only), aucune horloge donc rien qui ressemble à une clé ouverte par l'urgence (§5.2 règle 2).

### Anti-Patterns to Avoid
- **`exec bash "$S"`** dans la commande : un plantage de python rend alors un code ≠ 0 au harnais = fail-open. Lancer en fils et rendre la main à la couche shell.
- **Lire une variable d'environnement qui change le comportement** (`VF_GATES_OFF`, « mode d'évaluation » qui simule l'adhésion) : c'est un contournement que l'agent peut poser (les quatre tours de la course aux armements, spec §5.2). Le rejeu travaille sur **une copie** (P45-D-21, première option), jamais par un interrupteur du script livré.
- **Un `Stop`/`exit 2` de plus** : `guard-planning-updated.sh` reste l'unique exception connue (P45-D-19).
- **Deux entrées `hooks.json` référençant le même script sous deux matchers** : la purge d'idempotence de `merge-hooks.sh` retire l'une des deux (`guard-driver-lock.sh` l'a mesuré, en-tête du script, l.8-14) → une seule entrée, matcher combiné.
- **Nommer une suite avec `G1…G10`** : `test-planning-hooks.sh` porte déjà des cas `G1`…`G10` (garde Stop). Préfixer `GATE-…` / `R-…`.

## Research Answers

### R1 — Décider « lab adhérent ou non » sans python3 (risque n°1) : technique recommandée et preuves

**Technique retenue (une seule, concrète)** `[VERIFIED: sonde — 39 cas × 6 shells, 936 appels E2E, 15 mutations rouges]`

1. Lire stdin **une fois** : `I=$(cat)`.
2. Filtrer l'outil par **`case` glob compact** : `*'"tool_name":"Write"'*|*'"tool_name":"Edit"'*|*'"tool_name":"NotebookEdit"'*|*'"tool_name":"Agent"'*|*'"tool_name":"Task"'*` (P45-D-06b, 2026-09-29 : cinq outils, dispatch compris ; linéaire : 0,15 s au pire à 1,2 Mo sur bash 3.2). Hors de ces cinq outils (Bash, lectures) — **Bash reste ouvert par décision (P45-D-06b), limite déclarée** — : **exit 0 silencieux** en mode dégradé — sinon l'agent ne pourrait même plus lancer la réparation. Un guillemet dans une valeur JSON est toujours échappé (`\"`) : la sous-chaîne `"tool_name":"Write"` ne peut donc pas être fabriquée par un contenu.
3. **Une seule passe** `LC_ALL=C grep -a -o -E '"(file_path|notebook_path|cwd)"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"'` : l'alternative `([^"\\]|\\.)*` fait porter à `grep` la **parité des backslashes** (fin réelle de la chaîne) ; on garde la **première** occurrence de chaque clé (`head -n 1` par clé). `-a` (texte) et `LC_ALL=C` neutralisent les octets invalides et les locales.
4. **Décoder** la seule valeur, en shell pur, par segments `${v%%[\"\\]*}` : `\"`, `\\`, `\/`, `\n`, `\t` sont décodés ; **tout autre échappement (`\uXXXX`, `\r`, `\b`, `\f`) arrête le décodage** et la valeur devient un **préfixe fidèle** (`X=0`). (Claude Code n'émet pas `\uXXXX` pour le non-ASCII : `Créer`, `é` sortent bruts `[VERIFIED: sonde 1]` ; seul un caractère de contrôle en produirait.)
5. **Remonter** avec `cd -P` / `pwd -P` (résolution physique : alias et liens symboliques vers un lab adhérent sont vus) jusqu'au **plus proche** dossier contenant `.planning/` (le plus proche gagne).
6. **Adhésion « TIGHT »** : `grep -a -q -E '"planning_version"[[:space:]]*:[[:space:]]*"cycles-v1"' <lab>/.planning/config.json` (même ligne). Seul niveau qui autorise un deny dégradé : un lab dev dont le `config.json` *mentionne* `cycles-v1` (cas `dev-note`) n'est **jamais** refusé.
7. **Précédence** : un chemin exactement décodé décide **seul** (une session ouverte dans un lab adhérent peut écrire dans un lab dev voisin : cas `n04`, `n06`) ; chemin **relatif** → joint au `cwd` du payload (ou à `$(pwd -P)` sans `cwd`), comme le fait la couche Python (`cible_de`), pour que les deux couches décident pareil (révision du 2026-09-29) ; chemin absent (Agent/Task, et Bash qui n'est de toute façon pas filtré) → `cwd` du payload ; à défaut → `$(pwd -P)`. Chemin seulement **préfixe** (échappement non décodé) → refuser si le lab du préfixe **ou** celui du `cwd` est adhérent (le doute tombe du côté du refus, mais seulement sous un lab adhérent).
8. Adhérent → **un** `printf` d'un objet `deny` **statique**, exit 0. Sinon silence, exit 0.

**Ce qu'il ne faut PAS faire (chaque point est mesuré)** :

| Piège | Mesure |
|---|---|
| `${INPUT#*"clé"}` (expansion de paramètres) sur la charge utile | **95,28 s** sous bash 3.2 à 254 Ko (clé en fin) ; dash/zsh non chronométrés jusqu'au bout (interrompu) — quadratique, donc fail-open par timeout |
| Heredoc dans `$(...)` avec un `'` ou `)` déséquilibré dans le corps | **bash 3.2 : « unexpected EOF while looking for matching `'' »** ; dash et zsh passent — ne **jamais** mettre le programme Python dans un `$(...)` |
| `sed 's/.*"clé":"\(...\)".*/\1/p'` | glouton : rend la **dernière** occurrence (motif déjà présent dans `guard-planning-updated.sh` pour `session_id`) `[ASSUMED]` (non exécuté) ; `n14` (clé en double) le fait rougir pour `grep` glouton (mutation M8) |
| `awk` (`index`+`substr`) | correct mais 343 ms à 5 Mo contre 111 ms `grep` |
| `python3 -c "$PROG"` | plafond d'un argv (~128 Ko Linux `[ASSUMED]`) ; macOS a accepté 500 Ko |
| `$PWD` seul | logique (`…/cwd-link`) alors que le payload porte le chemin physique (`…/cwd-probe`) `[VERIFIED: sonde 2]` |
| `$CLAUDE_PROJECT_DIR` | = dossier de démarrage de la session, ne suit pas `EnterWorktree` (P45-D-12) ; sondé : identique au `cwd` physique de départ seulement |

**Corpus de sondes (à reprendre dans le banc de la suite ; révision du 2026-09-29 : + dispatch `Agent` et `Task` sous lab adhérent et sous lab dev, prompt d'Agent qui cite un faux `"cwd"` échappé, chemins relatifs avec `cwd` adhérent, dev, voisin par `../`, sans `cwd`)** — payloads compacts fabriqués avec `json.dumps` : chemin simple, espace, guillemet, backslash, chemin finissant par `\` ou `\"`, `$HOME`/backtick/glob/`'`/`%s`, Unicode brut et échappé (`ensure_ascii=True`), caractère de contrôle, clé en double (la 1re gagne), contenu piégé contenant `"file_path":"…"` **avant et après** la vraie clé (échappé, donc inoffensif), `Bash` dont la commande cite `{"file_path":…}`, gros contenu 200 Ko/1 Mo/5 Mo avant/après la clé, JSON pretty-printed et clés espacées, JSON tronqué en pleine chaîne, vide, garbage, octets invalides (`\xff\xfe\xc3`) dans le contenu. Arbre de labs : adhérent, adhérent pretty/espacé/valeur sur la ligne suivante, `cycles-v1` échappé, dev, dev qui *mentionne* `cycles-v1`, dev sans `config.json`, chemin à espace/guillemet/backslash, imbriqués dans les deux sens, alias de lab, alias de `.planning`, lien d'un lab adhérent vers un dev, lien d'un dev **vers** un lab adhérent, `..` traversant un dossier inexistant, `config.json` en lien symbolique, session dans un lab adhérent écrivant dans un lab dev.

**Résultats** `[VERIFIED: sonde]` : 39/39 sous bash 3.2.57, dash, `/bin/sh` (bash posix), ksh, zsh (émulation sh) et zsh natif. E2E de la commande complète sous `sh`, dash, bash, zsh × modes {A script OK silence, B script rend un deny (passe-plat), C script absent, D `python3` absent du `PATH` (le lanceur résout `python3 || python` et rend 72), E script plante `exit 1`, F script plante `exit 2`} × 39 cas : **936 appels, 0 échec**, un objet JSON `deny` unique parsé par `json.loads`, exit 0, stderr vide (hors modes plantés). **Mutations rouges** (assertion / attendu / obtenu) : couche d'extraction 8/8 — cd -P retiré (`t18` : attendu tight, obtenu none), parité des backslashes ignorée (`t03` : attendu tight, obtenu none), le plus proche ne gagne plus (`n05` : attendu none, obtenu tight), décodage de `\"` retiré (`t03`), le `cwd` prime (`n04`/`n05`, 11 cas), 1re occurrence → dernière (`n14`), TIGHT → LOOSE (`l01`, `l02`), repli `$PWD` retiré (`n11`) ; commande enregistrée 7/7 — filtre d'outil retiré (12 cas : `n11` deny attendu silence), code de sortie ignoré (`l04`, 34 cas), test de présence du script retiré (39 cas), objet JSON de refus tronqué (51 cas : document invalide), `exit 2` (DIV-2, 51 cas), le plus proche ne gagne plus (`n05`), décodage de `\"` retiré (`t03`).

**Coûts** `[VERIFIED: sonde, macOS Apple silicon]` : commande enregistrée ≈ 20-35 ms par appel dégradé (dominée par les spawns : ≈ 3,5 ms l'un ; équivalent à un spawn `python3 -S -E` = 26 ms) ; charge utile de 5 Mo : 0,4 s (dash) à 0,7 s (bash 3.2). `python3 -I -S` seul : ≈ 26 ms ; `json.loads` d'un fichier de 5 Mo : 65 ms. Le chemin normal (script + python) coûte donc une commande shell + un spawn python (≈ 45-60 ms) ; le chemin dégradé n'est pris que sur défaillance.

**Limites déclarées (à écrire dans `modele-cycles.md` et le message)** : (a) l'entrée doit être du JSON **compact** (vérifié sur 2.1.284) : un `"tool_name" : "Write"` espacé échappe au filtre dégradé (les clés de chemin, elles, tolèrent les blancs) ; (b) `cycles-v1` (valeur échappée) et `"planning_version":` / valeur sur deux lignes ne sont pas reconnus en TIGHT — le script Python, lui, décide exactement quand il tourne ; (c) un `config.json` en lien symbolique est TIGHT-adhérent côté shell, non adhérent côté Python (`O_NOFOLLOW`, `recalc-planning.sh:283`) ; (d) un chemin à `\u` dans le lab lui-même retombe sur le `cwd` ; (e) une charge utile non-JSON n'est jamais refusée en mode dégradé (outil inconnu) ; (f) `bash` absent (Alpine) → code 127 → chemin dégradé (deny sous lab adhérent), même politique fail-closed que `recalc-planning.sh` sans bash. (g) **Bash reste ouvert en mode dégradé** (P45-D-06b) : un lab adhérent dont le script ou `python3` manque refuse Write, Edit, NotebookEdit, Agent et Task, mais laisse passer Bash pour que la réparation (poser le script, installer `python3`) reste possible ; c'est une limite déclarée, cohérente avec P45-D-10, écrite dans la référence du modèle et dans le relevé du canary. (h) un chemin écrit relatif est joint au `cwd` du payload par les deux couches (le harnais l'émet toujours absolu, P45-D-12) ; `..` n'est normalisé que par la résolution physique du plus proche ancêtre existant.

### R2 — Chemin d'install : `hooks.json` → `merge-hooks.sh`

- **Jetons** `[VERIFIED: merge-hooks.sh:322,362-367 ; vibeflow-update.sh:1831-1833,1915]`. `SCRIPT_RE = re.compile(r"([A-Za-z0-9._-]+\.(?:sh|py))")` (dédup, retrait) ; `is_local_entry` : `return bool(settings_local_path) and VF_BASH_TOKEN in h.get("command", "")` (le jeton `{{VF_BASH}}` dans `command` route l'entrée vers `settings.local.json`) ; préfixe `{{VF_SCRIPTS}}` : scope user `'"$HOME"/.claude/scripts'`, sinon `'"$CLAUDE_PROJECT_DIR"/.claude/scripts'` ; `project|local) settings_local_args=(--settings-local "$TARGET_ROOT/settings.local.json")`.
- **Sondé sur le vrai `merge-hooks.sh`** `[VERIFIED: sonde]` (fragment candidat = le `hooks.json` réel de `planning-core` + une entrée `PreToolUse` inline de forme shell) : (1) `plan` annonce les entrées ; (2) `merge` conductor puis `planning-core` : l'entrée **shell** va dans **`settings.json`** (avec `"timeout": 20` **préservé**), le groupe est **séparé** du hook tiers `node …gsd-guard.js` de même matcher (un groupe non entièrement possédé n'est jamais réutilisé) ; (3) **idempotent** (2e merge : `cmp` identique, les deux fichiers) ; (4) `remove` retire seulement les entrées référençant les basenames du fragment, préserve `permissions` et les entrées conductor ; (5) la forme **exec** (`{{VF_BASH}}` + `args`) va dans **`settings.local.json`** en scope project, avec `${CLAUDE_PROJECT_DIR}/…` dans `args` ; en scope user (pas de `--settings-local`) le chemin `$HOME` est **résolu** à l'install.
- **Matcher** : `Write|Edit|NotebookEdit|Bash|Agent|Task` — lettres et `|` seulement = liste de noms exacts, pas une regex `[CITED: code.claude.com/docs/en/hooks]` (Hyphens : v2.1.195+). **Timeout** : clé `"timeout"` en secondes (défaut 600) ; il est fail-open (P45-D-06) : viser court (20 s), largement au-dessus des 45-60 ms nominales.
- **Modules qui livrent un `hooks.json`** (6) : conductor (`bash {{VF_SCRIPTS}}/guard-agent-write.sh` sur `Write` ; exec `{{VF_BASH}}` `guard-driver-lock.sh` sur `Bash|Write|Edit`), software-architecture (exec, `Edit|Write`), consolidator (shell, `Read`/`Bash`), planning-core (SessionStart/UserPromptSubmit/Stop, tous en `bash {{VF_SCRIPTS}}/x.sh || true` sauf le Stop). **Aucun ne porte encore une commande inline multi-instructions** : la nôtre crée le précédent — l'idempotence et le retrait ont été **sondés** avec elle (le script nommé dans l'inline suffit à la dédup). Éviter que l'inline cite d'autres `*.sh`/`*.py` (ils entreraient dans la dédup et le retrait).
- **Pose des scripts** `[VERIFIED: vibeflow-update.sh:1987-2054]` : `scripts/*.sh|*.mjs|*.js` en exécutable ; `*.txt` et `*.json` en données ; `scripts/tests/*.sh` et `scripts/tests/fixtures/*` (**fichiers à plat**, pas de sous-dossier) ; **pas de `.py`**. D'où le banc **texte** (comme `recalc-planning-banc.txt`) et non une arborescence de fixtures ; aucun dossier `.planning/` ne doit être versionné.
- **Scope** : scope **user** (`~/.claude/settings.json`) = un script à `"$HOME"/.claude/scripts` stable pour tous les projets ; scope **project** = `"$CLAUDE_PROJECT_DIR"/.claude/scripts` (copie périmée d'un autre worktree : issue amont #97349 ; `.claude/scripts` en lien symbolique dans les worktrees de ce dépôt, `BACKLOG.md:1130-1144`).
- **Désinstallation** : `merge-hooks.sh remove` (par basenames du fragment), best-effort dans `vibeflow-update.sh` (« retrait hooks échoué … nettoyer settings.json à la main »).
- **Chores induits** `[VERIFIED]` : `docs/HOOKS-CONTRAT-SORTIE.md` §4 « 29 entrées » et §5 (planning-core : 6, total 29) **doivent suivre** (le test `plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` T12 compare l'inventaire au parc réel) : +2 entrées (PreToolUse, SessionStart canary) → 31 ; `scripts/check-version-sync.sh` : le nombre « N suites » des deux README racine (`find plugin scripts -path '*/tests/test-*.sh'`, l.131-139) ; le bump v2.9.0 = `plugin/planning-core/VERSION` + `module.json` + ligne `**Version**` du README du module + CHANGELOG (triade et en-tête, l.99-130) ; **jamais** `VERSION` racine.

### R3 — Gardes et tests à imiter, CI, points d'insertion, ordre des vagues, mesure

**Gardes/tests à imiter**
- Suite `test-recalc-planning.sh` : `ok`/`ko` avec **assertion / attendu / obtenu**, mutants `make_recalc_mutant <NOM> '<motif unique>' '<remplacement>'` + `_verifier_plantage` + `okmut`/`komut`, **banc texte** `fixtures/recalc-planning-banc.txt` (directives `@@ lab`, `@@ fichier`, `@@ attendu`), `mode_octal()` par `os.stat` (pas de `stat -f`), empreinte d'arbre comparée par `cmp`. Le banc 44 est le modèle de « banc synthétique » de P45-D-21 : étendre la grammaire par des directives `@@ ecriture <outil> <chemin> :: doit-passer|doit-refuser [gate]`.
- Suite de **parc** `scripts/tests/test-hook-exit-parc.sh` : « Outillage du DÉPÔT (scripts/tests/, pas un module) : c'est ce qui l'autorise à asserter sur des scripts de PLUSIEURS modules » ; discrimination par **`cmp`, jamais `diff`** ; mutants sous `mktemp -d`. → le contrôle croisé rôle ↔ `check-agents.sh` (planning-core ↔ conductor) va **dans `scripts/tests/`**.
- **Canary de CI existant** (`ci.yml:119-213`) : discriminants qui ne peuvent pas être verts à vide (cas positif, négatif, plancher de compte), `set -eu`, bilan `fail`/`note`. À reproduire dans la suite du canary.
- **As-installed** : `lab-frais-arme` (`ci.yml:2083-2300`) installe via `VIBEFLOW_CACHE=… VF_SCOPE=project bash plugin/_internal/vibeflow-update.sh install <mod>` dans un `mktemp -d` et lit `settings*.json` **posés** ; la suite locale `plugin/_internal/tests/test-vibeflow-update.sh` (T10) fait pareil. → suite `plugin/_internal/tests/test-planning-hook-installed.sh` : installer `planning-core` dans un lab jetable, **extraire la commande posée** de `settings.json`, la rejouer (`CLAUDE_PROJECT_DIR` posé) sous les six modes. **Bloquant en CI par découverte automatique, sans toucher `ci.yml`** (`ci.yml:218` : `suites=$(find plugin scripts -type f -path '*/tests/test-*.sh' | sort)`, échec si 0 suite). Sous `bash -e {0}` prendre garde à `grep -q X && {…}` (piège, `ci.yml:552`).
- **G-2** (`scripts/check-gate-touche.sh:24-37`, cinq classes) : `plugin/conductor/scripts/check-*.sh`, `scripts/check-*.sh`, leurs suites (`plugin/conductor/scripts/tests/test-*.sh` **et** `scripts/tests/test-*.sh`), `.github/workflows/ci.yml`, `scripts/hooks/**`. **`plugin/planning-core/**` est hors surface machine** ; `scripts/tests/test-role-hook-vs-check-agents.sh` et toute édition de `ci.yml` y entrent → trailer `Gate-Touche: <chemin> — <raison de ≥ 10 caractères>`.
- **Exclusions D-31-03** `[VERIFIED: vibeflow-update.sh:456-471]` (`vf_manifest_excluded`) : `scripts/vf-portable.sh`, `scripts/runtime-cli-dispatch.sh`, `scripts/.vibeflow-target`, `memory/*`, `scripts/.vibeflow-installed`, `scripts/.vibeflow-manifest-*`, `.backups/*`, `settings.json`, `settings.local.json`. Le nouveau script et sa suite **entrent** au manifeste (rien à exclure) ; **ne rien ajouter** à cette liste.
- **Lint de consommateurs** `[VERIFIED: check-planning-consumers-registered.sh:162-166]` : tout `*.sh` suivi hors `tests/` dont une ligne porte `.planning/workstreams`, ou `.planning/` suivi sur la **même ligne** de `STATE.md`, `ROADMAP.md` ou `REQUIREMENTS.md`, doit figurer au recensement `plugin/conductor/references/workstream-planning-consumers.md` (sinon l'étape `gates` rougit). Le script de hook nommera `STATE.md`/`INDEX.md` : soit composer les chemins à l'exécution (jamais `.planning/…STATE.md` sur une ligne), soit recenser (catégorie `c`/`a2`).

**Points d'insertion GATE-14** `[VERIFIED: recalc-planning.sh]`
- `680-684` : `if code == 2:` … `return "non-concluante"  # motif-code-2-migration` → rendre un verdict distinct (ex. `"migration"`), le reste de la fonction inchangé (garde de lecture l.635-651, environnement maîtrisé, codes 0/1/3, repli générique).
- `1851-1852` : `verdict_gsd = detection_gsd(detect_sh, planning_abs, racine_lab)` / `if verdict_gsd != "non-gsd":` → laisser passer `"migration"`. **L'adhésion est déjà testée avant** (l.1842-1849 : `if not adhesion["adherente"]: … sys.exit(2)`), donc « sans adhésion : exit 2 inchangé » et « adhésion + détecteur 0 : exit 3 » sont structurellement préservés ; la mutation utile est celle de la branche `migration` (renvoyer `non-concluante` ou `non-gsd`).
- Docstring l.587-604, table des codes de `modele-cycles.md:54-66` (ligne « **2** … `non-concluante` … **refusée** »), prose l.64-71, et `README`/`CHANGELOG`.
- **Tests existants à réécrire** (assertent aujourd'hui « socle+signal → 3 » sur un lab **adhérent**, `traceur`) : `oracle_differentiel socle-signal` (l.2683, 2719 ; la table `0|2) code_attendu=3` se scinde), `matrice_env socle-signal … 3` (l.2809 → 0), `R-LABS-ADVERSES` (l.2866+, trois divergences `package.json`/`*.xcodeproj` en lien et `STATE.md` UTF-8 invalide : **le détecteur voit un signal → 2 → écriture** ; re-poser les attendus et l'invariant « STATE.md intact »), `R-CODE2-MIGRATION` et `MUT-CODE2-MIGRATION` (l.2942-2965, 2982-2992), `R-GSD-HOME-SIGNAL (a)/(b)` (l.3900-3935). Chacun garde son jumeau négatif (sans adhésion → 2 ; détecteur 0 → 3) et sa mutation rouge tracée (P45-D-02a).

**Ordre des vagues (P45-D-03) — proposition de découpage**
| Vague | Contenu | Armement |
|---|---|---|
| W0 | fondations : `hooks.json`, commande enregistrée, lanceur, table d'armement (tout `observe`, G2 `warn`), banc + rejeu (outil lecture seule, chemins en argument), canary (suites), chores R2 ; **GATE-14 en parallèle** (fichiers disjoints : `recalc-planning.sh` + sa suite) | aucun refus |
| W1 | G6 + G5 + commande de verdict + dérogation/journal + G2 | G6+G5 : après canary + rapport → **point de décision** |
| W2 | G1 | idem, après W1 |
| W3 | G7 | idem, après W2 |
| W4 | hook par rôle + contrôle croisé | idem, après W3 |
| W5 | docs, `modele-cycles.md`, README/CHANGELOG/VERSION module, compteurs, canary de session | — |
Un point de décision (`checkpoint:decision`) suit chaque rapport de rejeu non nul (F4, F5, F7, F9), car P45-D-03b interdit de fixer une tolérance en mission.

**Mesure « deux sens » et seuil 0** (P45-D-03b) : par gate, un corpus `doit passer` (écritures légitimes **d'un lab adhérent conforme au modèle** : `cycles/**/{CADRAGE,PLAN,CLOTURE,SUMMARY,CYCLE}.md`, `PROJECT.md`, `REQUIREMENTS.md`, `config.json` hors `planning_version`, `missions/**`, livrables hors `.planning/`) et un corpus `doit refuser` (fichiers générés, `VERDICT.md`, création sous adhérent sans `.claude/` habité, juge qui écrit, worker qui dispatche). Rapport machine-lisible `gate | chemin | attendu | obtenu | raison`. Distinguer **faux refus de conception** (un fichier hérité qui viole le modèle : F5) des faux refus de bug. **Rejeu réel — mesures** `[VERIFIED: sonde lecture seule, aucun fichier écrit, aucun git]` :

| Lab | `.planning/` | G7 « habité » littéral (≥ 1 `.claude/agents/*.md` **et** ≥ 1 fichier `.claude/memory/`) | Constat |
|---|---|---|---|
| `~/jarvis-keystone` | 6 | racine, `10-pilotage`, `20-ateliers/01-marche-offre`, `_gabarit`, `30-captation` : habités ; **`00-doctrine` : non** (`.claude/agent-memory/` seul) | faux orphelin vs spec D-05 « zéro orphelin » |
| `~/BusinessFlow-Lab` | 10 | racine : habité (17 agents, 18 fichiers mémoire, `package.json`) ; `avma`, `dmflow`, `lead-recovery` : **sans `.claude/`** ; `formation` : `agent-memory/` seul ; `ProjetFlow-A2-POLLUE/-A2-PROPRE/-FROZEN-A3/-LAB-GENERE-A3` : habités ; **`ProjetFlow-FROZEN-A1` : non** (mémoire sans agent) | 4 orphelins attendus retrouvés + `FROZEN-A1` en plus |

G6 sur les deux labs : `STATE.md` à la racine d'un `.planning/` : 5 + 8 ; `INDEX.md` : 2 + 1 ; ni `cloture.log` ni `.recalc-cache.json`. G1 sur Keystone : voir F5 (405 PLAN.md de forme modèle ; 0 en a un sur BusinessFlow). Neither lab a adhéré : les deux portent `"planning_version": "2.0"` (l'adhésion se **simule sur une copie**). Copier **seulement** `.planning/`, `.claude/` et les marqueurs de code (BusinessFlow porte `node_modules/` : ne pas le copier).

### R4 — Pièges de portabilité à intégrer aux commandes de vérification

- **zsh (l'outil Bash du poste) vs bash 3.2 (CI/macOS) vs dash (Linux `/bin/sh`)** : `for x in $liste` ne découpe pas sous zsh → listes littérales ou `while IFS= read -r` ; un glob sans correspondance **échoue** sous zsh (« no matches found », rencontré cette session) → gardes `[ -e ]` ou `find` ; tableaux 1-indexés (zsh) vs 0 (bash) → éviter ; `echo` interprète `\n` sous zsh → `printf` ; **boucles à ≥ 2 éléments** (un seul ne révèle ni le découpage ni l'ordre).
- **bash 3.2** : ni `mapfile`, ni tableaux associatifs, ni `${v,,}` ; `local -a` vide sous `set -u` ; **heredoc dans `$()` fragile** ; `read -d ''` OK (bash seul) ; `printf '%s'` sûr partout.
- **dash** : pas de `[[ ]]`, `${v//x/y}`, `${v:o:n}`, `$'…'`, `pipefail`, `local` (existe mais non POSIX) → la couche shell n'en utilise aucun (newline littéral, `$(printf '\t')`).
- **BSD vs GNU** : pas de `stat -f`/`stat -c` (→ `os.stat` via Python), pas de `sed -i` (fichier temporaire + `mv`), pas de `timeout` (absent du poste), pas de `readlink -f` (→ `cd -P && pwd -P`, sondé), pas de `grep -P`, pas de `sed '\x01'`, pas de `xargs -r`, pas de `find -printf`, pas de `date -d`. `mktemp` : `mktemp -d` et `mktemp "${TMPDIR:-/tmp}/x.XXXXXX"` valent partout.
- **`diff`, `grep` peuvent être « proxifiés »** dans l'outil Bash du poste (sortie tronquée/altérée, mesuré par le dépôt) : `cmp -s`, `comm`, et `awk 'index($0,"x"){f=1} END{exit !f}'` pour les vérifications ; la commande enregistrée (exécutée par le harnais, `/usr/bin/grep`) n'est pas concernée.
- **Mutation rouge avec trace** : chaque garde a un mutant à motif unique dont la sortie est comparée à l'original (`assertion`, `attendu`, `obtenu`) ; jumeau négatif obligatoire ; `okmut`/`komut` du dépôt.
- **CI** : `bash -e {0}` (piège `cmd && {…}`), 4 jobs `ubuntu-latest` seulement ; les suites se lancent par `bash "$t"` (pas `-e`).
- **APFS** : insensible à la casse et conserve les liens durs : tout test de chemin protégé doit couvrir `state.md`, `.PLANNING`, lien dur, alias (Pattern 5) ; sous Linux le test de casse est un jumeau « ne doit pas refuser à tort ».

### R5 — Décisions qui paraissent impossibles ou contradictoires une fois sondées

Voir la table FINDINGS (F2, F4, F5, F6, F8, F9, F10, F12). Aucune n'est réécrite ici. En résumé : rien n'est **techniquement impossible** ; en revanche F4/F5 rendent probable un rejeu non nul (donc l'arrêt de l'armement à Willy), F6 ouvre une porte de désarmement que P45-D-01 déclare fermée, F8/F9 opposent la table du §5 aux agents livrés, F10 documente une perte de contenu.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Encoder le refus JSON | concaténation de chaînes en shell/Python | `json.dumps` (Python) ; texte **statique** en shell | guillemet/backslash/newline dans une valeur cassent le document (HOOKS-CONTRAT §3 bis) |
| Valider la sortie d'un hook | `jq` | `json.loads` (parseur de document) | `jq` accepte `{}{}` que le harnais rejette |
| Hash du verdict | `sha256sum` / `shasum` (GNU/BSD divergent) | `hashlib.sha256` | portable, déjà dans la stack |
| Permissions/statut de fichier | `stat -f`/`-c` | `os.stat` / `os.lstat` | GNU/BSD divergent (`mode_octal`, R14 de la 44) |
| Identité d'un fichier protégé | comparaison de chaînes de chemin | `os.path.samefile` + `casefold` | APFS, liens durs, alias (Pattern 5) |
| Frontmatter des `PLAN/CADRAGE/VERDICT` | second parseur YAML | la grammaire minimale de la 44 (`modele-cycles.md` § Grammaire), **avec contrôle croisé** | divergence mesurée trois fois au lot 3 de la 44 |
| Détection GSD / migration | réimplémenter les priorités du détecteur | le vrai `detect-gsd-engine.sh` (déjà appelé par `detection_gsd`) | source unique ; P45-D-02b |
| Classification I5/I6 | table `vf-role:` | prédicats de `check-agents.sh` réimplémentés + **oracle différentiel** | P45-D-05/05a |
| Journal de dérogation injectif | assainissement par remplacement (`_`) | encodage pourcent injectif de `_jeton_journal` | le remplacement par `_` n'est pas injectif (mesuré en 44) |
| Fichier temporaire de transport | `/tmp/x.$$` prévisible | `mktemp` (0600) + `trap 'rm -f'` | course de liens symboliques, fuite de contenu |

**Key insight :** la difficulté n'est pas de refuser, c'est de **ne jamais refuser à tort** (97 % de faux refus mesuré en amont) et de **ne jamais se croire vivant sans preuve**. Tout ce qui multiplie les implémentations (shell/Python, hook/`check-agents`, hook/`recalc`) exige un contrôle croisé qui **peut rougir**.

## Common Pitfalls

### Pitfall 1 : timeout = fail-open déguisé en lenteur
**What goes wrong:** `${v#*motif}` sous bash 3.2 met 95 s → le harnais annule le hook, l'action passe (F3).
**How to avoid:** un seul `grep -o` (linéaire), `case` glob pour le filtre ; test de charge 200 Ko/1 Mo/5 Mo avec une **borne de temps** (suite : la commande doit finir sous 5 s sur 5 Mo ; sans `timeout` du poste : chronométrer avec `date +%s` avant/après ou Python `perf_counter`).
**Warning signs:** hook lent sur de gros `Write` ; « hook error » dans le transcript.

### Pitfall 2 : exit ≠ 0 du script = fail-open
**What goes wrong:** `bash` rend 2 sur une erreur de syntaxe du `.sh` (= **blocage** de tout `Write` de tous les labs, même dev) ; python rend 1 sur une erreur de syntaxe embarquée (= laisse passer).
**How to avoid:** lancer le script en fils depuis la commande enregistrée et traiter tout `R≠0` (mutations `MI2`, `MI5`) ; suite qui exécute `bash -n` sur le script **et** compile le Python extrait du heredoc (`compile(source, …, "exec")`) ; canary sous « script plante ».

### Pitfall 3 : refuser un lab dev
**What goes wrong:** un `config.json` de lab dev qui **mentionne** `cycles-v1` ; une session dans un lab adhérent qui écrit dans un lab dev voisin ; un lab adhérent qui contient un lien vers un dev.
**How to avoid:** TIGHT pour tout deny dégradé, précédence « chemin > cwd », résolution physique ; corpus `n04`, `n06`, `l01`.

### Pitfall 4 : contournement de G6 par identité
**What goes wrong:** `.planning/state.md`, `.PLANNING/STATE.md`, lien dur, alias de `.planning` écrivent le vrai `STATE.md` (APFS).
**How to avoid:** Pattern 5 ; corpus `doit refuser` de la vague W1 avec ces quatre variantes.

### Pitfall 5 : désarmement par l'adhésion (F6)
**What goes wrong:** `Edit .planning/config.json` retire `cycles-v1` ; tous les gates sortent silencieux. **How to avoid:** arbitrer F6 avant W1 ; sinon l'écrire comme limite déclarée.

### Pitfall 6 : `agent_type` n'est pas le nom de fichier
**What goes wrong:** le hook cherche `<agent_type>.md` ; or c'est le `name:` du frontmatter (valeur `general-purpose` pour l'agent intégré, `[VERIFIED: sonde 1]` ; préfixe `plugin:` pour un agent de plugin). **How to avoid:** indexer les définitions par `name:` (repli sur le nom de fichier, comme `agent_display_name`, `check-agents.sh:755`), `agent_type` **normalisé** (casse, séparateurs) ; inconnu → ligne « Tous » seulement (P45-D-11).

### Pitfall 7 : le journal d'observation fuit du contenu
**What goes wrong:** journaliser `tool_input` (contenu d'un `Write`, commande Bash) enregistre des secrets. **How to avoid:** ne journaliser que gate, chemin relatif, raison, horodatage.

### Pitfall 8 : nom collision `DEROGATION.md`
Le modèle 44 a déjà `DEROGATION.md` (phase/plan, `abandonné|remplacé|gelé`). Le journal de gate porte un autre nom (Pattern 8).

### Pitfall 9 : le Stop v2 et G6 se marchent dessus
`guard-planning-updated.sh` (message : « Mets à jour le STATE.md du compartiment concerné ») reste actif (P45-D-19) alors que G6 refuse `STATE.md` à la racine du `.planning/` d'un lab adhérent. Ce n'est **pas** un blocage dur (le Stop s'apaise sur tout fichier `.planning/**` touché, dont ce que `recalc-planning.sh` écrit), mais le **message peut être trompeur** : le refus G6 doit dire « poser par `recalc-planning.sh` ». G6 ne couvre que les fichiers **directs** de la racine du `.planning/` (pas `compartments/x/STATE.md`, pas `workstreams/…/STATE.md`).

## Code Examples

### La commande enregistrée (source de vérité testée — jetons `{{VF_SCRIPTS}}` substitués par l'installeur)

Forme **shell**, une entrée, `timeout` explicite. Texte du champ `command` (dans `hooks.json` il est JSON-échappé par un `json.dumps` ; **générer** l'entrée, ne pas l'éditer à la main) :

```sh
S={{VF_SCRIPTS}}/planning-hook.sh
I=$(cat); R=1; O=
if [ -f "$S" ]; then O=$(printf '%s' "$I" | bash "$S"); R=$?; fi
if [ "$R" -eq 0 ]; then [ -z "$O" ] || printf '%s\n' "$O"; exit 0; fi
case $I in *'"tool_name":"Write"'*|*'"tool_name":"Edit"'*|*'"tool_name":"NotebookEdit"'*|*'"tool_name":"Agent"'*|*'"tool_name":"Task"'*) ;; *) exit 0 ;; esac
NL='
'; TB=$(printf '\t')
vf_get() { _m=$(printf '%s' "$I" | LC_ALL=C grep -a -o -E '"'"$1"'"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -n 1); [ -n "$_m" ] || return 1; _m=${_m#*:}; while :; do case $_m in ' '*|"$TB"*) _m=${_m#?} ;; *) break ;; esac; done; _m=${_m#\"}; V=""; X=1; while :; do _s=${_m%%[\"\\]*}; V=$V$_s; _m=${_m#"$_s"}; case $_m in '') X=0; return 0 ;; \"*) return 0 ;; \\\"*) V=$V\" ;; \\\\*) V=$V\\ ;; \\/*) V=$V/ ;; \\n*) V=$V$NL ;; \\t*) V=$V$TB ;; *) X=0; return 0 ;; esac; _m=${_m#??}; done; }
vf_tight() { _d=$1; case $_d in /*) ;; *) return 1 ;; esac; while :; do if [ -d "$_d" ]; then _p=$(cd -P -- "$_d" 2>/dev/null && pwd -P) && [ -n "$_p" ] && { _d=$_p; break; }; fi; [ "$_d" = / ] && return 1; _q=${_d%/*}; [ -z "$_q" ] && _q=/; [ "$_q" = "$_d" ] && return 1; _d=$_q; done; while :; do if [ -d "$_d/.planning" ]; then [ -f "$_d/.planning/config.json" ] && LC_ALL=C grep -a -q -E '"planning_version"[[:space:]]*:[[:space:]]*"cycles-v1"' "$_d/.planning/config.json" 2>/dev/null; return $?; fi; [ "$_d" = / ] && return 1; _q=${_d%/*}; [ -z "$_q" ] && _q=/; [ "$_q" = "$_d" ] && return 1; _d=$_q; done; }
D=1; for K in file_path notebook_path; do if vf_get "$K"; then P=$V; PX=$X; case $P in /*) ;; *) if vf_get cwd; then P=$V/$P; else P=$(pwd -P)/$P; fi ;; esac; if vf_tight "$P"; then D=0; elif [ "$PX" = 0 ] && { vf_get cwd && vf_tight "$V"; }; then D=0; fi; K=done; break; fi; done
if [ "$K" != done ]; then if vf_get cwd; then vf_tight "$V" && D=0; else vf_tight "$(pwd -P)" && D=0; fi; fi
[ "$D" -eq 0 ] || exit 0
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"[planning-core] hook central indisponible (script ou python3 absent, ou en erreur) dans un lab adherent cycles-v1 : ecritures par outil refusees. Reparer : mettre a jour VibeFlow (/vf-update) ou installer python3, puis relancer la session."}}'
exit 0
```

Notes : (i) le test `command -v python3` **n'est volontairement pas dans la commande** : c'est le lanceur qui résout `python3 || python` (cascade ADR-054, Windows sans `python3`) et rend ≠ 0 s'il n'y en a aucun — observationnellement identique à GATE-03 (deny si python3 manque), à trancher si l'on préfère le test littéral ; (ii) message statique ASCII (aucune valeur dynamique) ; (iii) `vf_get` est appelée sans sous-shell pour conserver `V`/`X` ; (iv) tout est POSIX (aucun `[[ ]]`, `local`, `${//}`, `$'…'`) ; (v) sous zsh les tests passent avec `emulate sh`. (vi) révision du 2026-09-29 (P45-D-06b, contrôle plan-check) : le filtre couvre Write, Edit, NotebookEdit, Agent et Task — Bash n'y est PAS (réparation possible) ; un chemin relatif est joint au `cwd` avant `vf_tight` (`P`, `PX` remplacent `V`, `X` pour ne pas les écraser). Sondée le 2026-09-29 sous sh, dash, bash, ksh et zsh émulé sh sur dix-sept cas (Write/Agent/Task/NotebookEdit/Bash/Read × lab adhérent, dev, voisin, chemin relatif, `..`, sans `cwd`) : 0 échec ; la commande d'avant, rejouée sur les mêmes cas, en échoue six (Agent, Task, chemins relatifs sous lab adhérent).

### Lanceur `planning-hook.sh` (squelette — patron du dépôt : programme en heredoc, transport par fichier)
```bash
#!/usr/bin/env bash
# Le lanceur ne décide de RIEN : tout code de sortie ≠ 0 est repris par la commande enregistrée (fail-closed).
set -u
T="$(mktemp "${TMPDIR:-/tmp}/vf-planning-hook.XXXXXX")" || exit 70
trap 'rm -f "$T"' EXIT
cat > "$T" || exit 71
PYBIN="$(command -v python3 || command -v python)" || exit 72
"$PYBIN" -I -S - "$T" <<'PY_PLANNING_HOOK_EOF'
# ... Python : main() en deux temps (Pattern 3), sortie = rien | un objet JSON, exit 0
PY_PLANNING_HOOK_EOF
```
`[VERIFIED: sonde]` la variante `python3 -I -S /dev/fd/3 3<<'PY'` (charge utile sur stdin) fonctionne sous quatre shells sur macOS ; le squelette ci-dessus (transport par fichier) est le choix conservateur, calqué sur `merge-hooks.sh`.

### Rejeu du canary (esquisse — la commande **posée**, telle quelle)
```bash
# CMD lue dans settings.json posé par vibeflow-update.sh ; CLAUDE_PROJECT_DIR = lab jetable
printf '%s' "$PAYLOAD_DENY" | env CLAUDE_PROJECT_DIR="$LAB" PATH="$PATH_SANS_PYTHON" /bin/sh -c "$CMD"
# attendu : rc 0, stdout = UN objet JSON, .hookSpecificOutput.permissionDecision == "deny" (json.loads)
```
Modes : script présent · **script absent** (`CLAUDE_PROJECT_DIR` vide) · **python3 absent** (`PATH` = liens vers `bash grep head cat sh` seulement) · script qui plante (`exit 1`, `exit 2`) · payloads `Agent` **et** `Task` · fil principal (aucune clé `agent_id`/`agent_type`) · `agent_type:"plugin:nom"` · un lab **dev** dans les mêmes modes (attendu : silence). Le canary itère la **table d'armement** et exige un cas par gate `armed`.

### Payload réel capturé (Claude Code 2.1.284, sous-agent ; valeurs raccourcies)
```json
{"session_id":"…","transcript_path":"…","cwd":"<chemin physique>","prompt_id":"…","permission_mode":"default","agent_id":"…","agent_type":"general-purpose","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"…/a\"q.txt","content":"hi"},"tool_use_id":"toolu_…"}
```
Un `Write` du fil principal n'a **ni** `agent_id` **ni** `agent_type`. Le dispatch : `"tool_name":"Agent"`, `tool_input` = `{"description":…,"prompt":…,"subagent_type":"general-purpose"}`.

### Avertissement (G2) et citation de dérogation — `allow` + `additionalContext`
```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"[planning-core] G2 : … Bash n'est pas couvert par les refus (limite déclarée)."}}
```
Exit 0, aucun `permissionDecision`. `[VERIFIED: F11]`

### Oracle différentiel du rôle (recette, sondée)
Pour chaque définition d'agent (31 fichiers : `plugin/*/agents/*.md` + `plugin/*/AGENT.md`), écrire deux variantes jetables : (a) sans la ligne `omitClaudeMd:` ; (b) sans `SendMessage` dans `tools:` ; lancer `check-agents.sh --file <variante>` (deux arguments) ; **`invariant I5` apparaît en (a) ⇔ juge** ; **`invariant I6` apparaît en (b) ⇔ manager**. Résultat mesuré : juges = `quality-gate-client`, `content-clarity-judge`, `vf-design-judge`, `growth-quality-judge` ; managers = `vf-business-manager`, `vf-content-manager`, `vf-design-manager`, `vf-dev-manager`, `vf-growth-manager` ; 0 code de sortie non nul sur les originaux. La suite compare, pour chaque agent et chaque fixture, `rôle(hook)` à cet oracle **et** exige qu'une mutation du prédicat du hook (par ex. « juge = Write seul retiré ») rende le contrôle rouge. Prédicats à reproduire `[VERIFIED: check-agents.sh:908-921 et 893-906]` : I5 « `disallowed = bare_tokens(fmlines, "disallowedTools")` ; `if not ("Write" in disallowed and "Edit" in disallowed): return []` ; `if dispatch: return []` » ; I6 « `if not dispatch: return []` ; `if str(fm.get("vf-internal", "")) == "true": return []` ». Le tokenizer (`extract_raw_field`, `tokenize_field`, `parse_token`) gère les allowlists `Agent(a, b)` à parenthèses imbriquées : ne pas le simplifier en `split(",")`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Task` = outil de dispatch | `Agent` (alias `Task` conservé) ; matchers `Agent`, `Task`, `Agent\|Task` tous actifs | v2.1.63 ; mesuré 2.1.284 | tester les deux `tool_name` (P45-D-09) |
| `agent_type`/`agent_id` absents des payloads | présents en sous-agent (absents au fil principal) | v2.1.69 | rôle par `agent_type` ; fil principal = absence de clé |
| Un `exit 2` bloque | `permissionDecision: deny` + exit 0 (DIV-2 : `exit 2` fuit le chemin du script) | doctrine du dépôt | gates en deny JSON |
| Hook « supposé vivant » | canary rejouant la **commande posée** | spec §5.1 | GATE-12 |

**Deprecated/outdated :** champs `decision`/`reason` racine pour PreToolUse (dépréciés) ; `MultiEdit` n'est plus listé ; `systemMessage` sur `allow` n'atteint pas le modèle (DIV-3) — utiliser `additionalContext`.

## Runtime State Inventory

Non applicable (phase de construction, pas de renommage). **Une exception** : GATE-14 change ce que `recalc-planning.sh` écrit sur un lab adhérent + code + `STATE.md` v2 — voir F10 ; aucune donnée existante n'est migrée par la phase (Stored data : **aucune** — vérifié : les deux labs réels sont en `2.0`).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Sous Linux/CI, `/bin/sh` = dash, `grep` = GNU, `awk` = mawk, et la couche shell y donne les mêmes verdicts | R1, Standard Stack | la suite de CI rougit ; corriger avant tout armement (c'est le but de W0) |
| A2 | Le plafond d'un argv unique est ~128 Ko sous Linux (`MAX_ARG_STRLEN`) | Alternatives | mineur : le programme ne passe **pas** par `-c` de toute façon |
| A3 | L'artefact haché par la commande de verdict est le `PLAN.md` de l'unité | Pattern 8 | à confirmer (Phase 46 vérifie « le hash contre l'artefact effectivement produit ») |
| A4 | `python3 /dev/fd/3 3<<'PY'` fonctionne sous Linux et Git Bash | Alternatives | si faux, seul le transport par fichier reste (déjà recommandé) |
| A5 | Les sorties `sed` gloutonnes rendent la dernière occurrence (non exécuté ici) | R1 pièges | aucun : `sed` n'est pas retenu |
| A6 | Un agent de plugin (`plugin:nom`) n'est résolu qu'en dernier recours ; sinon « inconnu » | Pitfall 6 | limite déclarée P45-D-11, canary compte le cas |
| A7 | La sémantique recommandée de G1 (refuser `à cadrer`/`en cadrage`, jamais l'`indéterminé`) est acceptable | F5 | arbitrage Willy |
| A8 | Un journal d'observation sous `${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/…` est acceptable pour P45-D-03a | Pattern 4 | choix de conception : à confirmer |

## Open Questions

1. **G7 : quel prédicat « habité » ?** — Connu : mesures ci-dessus. Flou : `00-doctrine` (lab) et `formation` (orphelin) sont indiscernables par `.claude/`. Recommandation : livrer G7 en observation avec le prédicat littéral, remonter le rapport (F4) et faire trancher Willy (agents seuls ? mémoire seule ? liste blanche de labs déclarée par le lab lui-même, donc écrivable → à éviter).
2. **G1 face au format hérité (F5)** et **face à `registre-invalide`/`frontmatter-invalide`** — refuser ou avertir ?
3. **F6 : protéger `config.json` (adhésion, seuil de juge) par G6/G5 ?** Sans cela P45-D-01 (« jamais par un drapeau qu'un agent peut écrire ») est fausse pour l'adhésion elle-même.
4. **F8/F9 : qui pose le verdict, et quelle ligne pour les workers dispatcheurs ?**
5. **F10 : sauvegarde du `STATE.md`/`INDEX.md` v2 avant la première écriture sous adhésion ?**
6. **Où loge le journal d'observation** (A8) et sa rétention.
7. **Faut-il aussi couvrir `Edit` pour G5/G6/G7 sur `NotebookEdit`** — oui par la commande (`NotebookEdit` a `notebook_path`) ; à tester (sondé : extraction du chemin, pas le refus réel).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | suites, lanceur | ✓ | 3.2.57 (macOS) | — |
| dash | preuve de la couche shell (Linux `/bin/sh`) | ✓ | (macOS `/bin/dash`) | — |
| zsh | replay des commandes de vérification | ✓ | 5.9 | — |
| ksh | contrôle POSIX | ✓ | (macOS `/bin/ksh`) | — |
| python3 | moteur, suites | ✓ | 3.14.5 | — |
| grep / awk / sed | couche shell, vérifications | ✓ | BSD 2.6.0 / 20200816 / BSD | — |
| jq | non requis (piège) | ✓ | — | ne pas dépendre |
| gawk, mawk, busybox, GNU grep | comportement Linux | ✗ | — | **prouvé par la CI** (W0), pas ici |
| Docker daemon | sonde Linux locale | ✗ | client 29.1.3, daemon arrêté | CI ubuntu-latest |
| `claude` CLI | capture de payloads réels | ✓ | 2.1.284 | — (les sondes 1-3 ont tourné) |
| `timeout` | — | ✗ (absent) | — | chronométrer par `perf_counter` |

**Missing dependencies with no fallback:** aucune.
**Missing dependencies with fallback:** tout ce qui est propre à Linux se prouve en CI.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash `*/tests/test-*.sh` du dépôt (`ok`/`ko` avec assertion/attendu/obtenu, mutants à motif unique) — aucun framework externe |
| Config file | aucun ; découverte par le `find` de `ci.yml:218` (`find plugin scripts -type f -path '*/tests/test-*.sh'`, trié), 0 suite = échec |
| Quick run command | `bash plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` |
| Full suite command | boucle CI (`ci.yml:215-242`) ou, pour la phase, le bloc ci-dessous (liste littérale ≥ 2 éléments : rejouable sous zsh **et** bash) |

```sh
for t in plugin/planning-core/scripts/tests/test-planning-hook-registered.sh plugin/planning-core/scripts/tests/test-planning-gates.sh plugin/planning-core/scripts/tests/test-recalc-planning.sh plugin/_internal/tests/test-planning-hook-installed.sh scripts/tests/test-role-hook-vs-check-agents.sh; do
  bash "$t" || echo "FAIL $t"
done
```


### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GATE-01 | hors lab adhérent : octet vide + exit 0 ; racine dérivée du chemin/`cwd`, jamais de `$CLAUDE_PROJECT_DIR` | intégration | `bash …/test-planning-hook-registered.sh` | ❌ W0 |
| GATE-02 | deny JSON exit 0 (jamais 2), un objet, `json.loads` ; erreur interne → deny sous adhérent | intégration + mutation (MI5) | `bash …/test-planning-gates.sh` | ❌ W0 |
| GATE-03 | script absent / python3 absent / plantage → deny sous adhérent ; dev jamais refusé ; 39 cas × dash, bash, sh, zsh | intégration | `bash …/test-planning-hook-registered.sh` | ❌ W0 |
| GATE-04 | G6 : `STATE/INDEX/cloture.log/.recalc-cache.json/journal` par `Write`/`Edit`/`NotebookEdit` ; casse, lien dur, alias | unitaire+banc | `bash …/test-planning-gates.sh` | ❌ W0 |
| GATE-05 | commande de verdict (hash, tentative, atomique) ; G5 refuse tout écrit de `VERDICT.md` par outil | unitaire | idem | ❌ W0 |
| GATE-06 | G1 : `à cadrer`/`en cadrage` refusés, hors-modèle et `indéterminé` non ; accord avec `recalc --read-only` | banc + croisé | idem | ❌ W0 |
| GATE-07 | G7 : création sous adhérent ; prédicat « habité » ; liste de marqueurs = celle du détecteur (extraction texte) | banc | idem | ❌ W0 |
| GATE-08 | G2 : `additionalContext`, jamais de deny, limite Bash dite | unitaire | idem | ❌ W0 |
| GATE-09 | rôles ; `Agent` **et** `Task` ; `subagent_type` normalisé ; fil principal/inconnu/`plugin:` | unitaire + croisé | `bash scripts/tests/test-role-hook-vs-check-agents.sh` | ❌ W0 |
| GATE-10 | dev fixture **et ce dépôt** : octet vide + 0 pour Write/Edit/NotebookEdit/Bash/Agent/Task ; mutation « ignorer l'adhésion » rouge | intégration | `bash …/test-planning-hook-registered.sh` | ❌ W0 |
| GATE-11 | dérogation : champs nominatifs, placeholder refusé, journal append-only injectif, usage unique, citation dans la sortie | unitaire | `bash …/test-planning-gates.sh` | ❌ W0 |
| GATE-12 | rejeu de la commande **posée** sous 6 modes ; table d'armement ⇒ un cas par gate armé | as-installed | `bash plugin/_internal/tests/test-planning-hook-installed.sh` | ❌ W0 |
| GATE-13 | banc deux sens en CI ; outil de rejeu lecture seule : empreinte avant/après par `cmp`, zéro `git`, chemins en argument | banc + garde | `bash …/test-planning-gates.sh` (banc) ; rejeu réel **manuel** hors CI | ❌ W0 |
| GATE-14 | 3 branches + jumeaux + mutations ; tests `socle-signal` réécrits | régression | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | ✅ à modifier |
| GATE-15 | suites en CI Linux, pas de `stat -f`/`sed -i`/`timeout`/`diff` ; bump v2.9.0 ; `guard-planning-updated.sh` présent | gates | `bash scripts/check-version-sync.sh` ; `bash plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` ; `bash scripts/check-machine-paths.sh` | ✅ |

### Sampling Rate
- **Per task commit :** la suite du plan concerné (< 30 s : garder les mutants sous `E2E_QUICK`-like : un shell, un mode par mutation).
- **Per wave merge :** liste littérale ci-dessus + `bash scripts/check-version-sync.sh` + `bash scripts/check-machine-paths.sh` + `bash plugin/conductor/scripts/check-planning-consumers-registered.sh`.
- **Phase gate :** toutes les suites de `plugin/planning-core/scripts/tests/` + `plugin/_internal/tests/test-merge-hooks.sh` + `test-manifest.sh` + `test-vibeflow-update.sh` + `scripts/tests/` vertes, gates de planning du compartiment rejoués à la main (`--file .planning/workstreams/gouvernance/STATE.md`).

### Wave 0 Gaps
- [ ] `plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` — extraction (39 cas), arbre de labs, 6 modes de défaillance, 4 shells, mutations M1-M8 / MI1-MI7, chrono 5 Mo
- [ ] `plugin/planning-core/scripts/tests/fixtures/gates-banc.txt` — banc texte + matérialiseur (étendre le `aides.py` du banc 44 ou le partager)
- [ ] `plugin/planning-core/scripts/tests/test-planning-gates.sh` — sémantique gate par gate, jumeaux négatifs, mutations
- [ ] `plugin/_internal/tests/test-planning-hook-installed.sh` — install réelle → commande posée → rejeu
- [ ] `scripts/tests/test-role-hook-vs-check-agents.sh` — oracle différentiel
- [ ] réécriture des tests `socle-signal` de `test-recalc-planning.sh` (GATE-14)
- [ ] outil de rejeu lecture seule (chemins en argument, jamais `~/…` dans le code) + sa suite (fingerprint `cmp`, mutation « écrit dans le lab » rouge)
- [ ] recensement `workstream-planning-consumers.md` si nécessaire ; inventaire `HOOKS-CONTRAT-SORTIE.md` ; compteurs README racine ; bump module

## Security Domain

`security_enforcement` actif (ASVS niveau 1, `security_block_on: high`).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | — |
| V3 Session Management | non (rien ne se fonde sur `session_id`, #76726) | — |
| V4 Access Control | **oui** — le hook est un contrôle d'accès par rôle et par chemin | fail-closed sous adhérent, précédence chemin > `cwd`, allowlists appliquées (F9) |
| V5 Input Validation | **oui** — payload JSON, chemins | `grep` borne les chaînes, décodage borné, résolution physique, `json.loads` côté Python ; jamais d'interpolation dans du JSON produit en shell |
| V6 Cryptography | oui (hash de verdict) | `hashlib.sha256` — jamais maison |
| V7 Error Handling & Logging | **oui** | deny sur erreur sous adhérent ; journal d'observation sans contenu ; journal de dérogation append-only injectif |
| V12 Files & Resources | **oui** | `mktemp` 0600 + `trap`, `O_NOFOLLOW`/`lstat` sur `config.json` (précédent 44), `os.replace` atomique |
| V14 Configuration | **oui** | état d'armement dans le code livré ; `python3 -I -S` (env `PYTHON*` ignoré) ; aucune variable d'environnement de contournement |

### Known Threat Patterns for {hook PreToolUse fail-closed sur `.planning/`}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Désarmer les gates en éditant `config.json` (F6) | Tampering | protéger `planning_version` (G6/G5) ou l'écrire comme limite déclarée |
| Contournement par identité de fichier (casse APFS, lien dur, alias, `..`) | Tampering | `samefile` + `casefold` + `realpath` (Pattern 5) ; corpus `doit refuser` |
| Contenu fabriqué qui imite une clé (`"file_path":"…"` dans `content`) | Spoofing | un `"` de valeur est toujours échappé : la sous-chaîne `"clé":` n'apparaît que pour une vraie clé ; corpus `n15`, `n16` |
| Faux refus massif (97 % en amont) | Denial of Service (de l'usage) | seuil 0 des deux côtés, mode observation, rapport nominatif, canary de vie |
| Timeout du hook (fail-open) | Elevation | pas d'expansion quadratique ; `timeout` explicite court ; canary |
| Détournement du `PATH` (`python3`, `bash`, `grep` factices) | Tampering | l'environnement du harnais est de confiance ; **aucune** variable de comportement lue ; noter le précédent 44 (lot 5) : le vecteur existait sur le **sous-processus** de `recalc`, pas sur un hook du harnais |
| Injection de ligne dans le journal par une « raison » multi-lignes | Tampering | encodage pourcent injectif (`_jeton_journal`) |
| Fuite de contenu via journal d'observation ou fichier temporaire | Information disclosure | ne journaliser ni `content` ni `command` ; `mktemp` 0600 + suppression |
| `disableAllHooks`, `--bare`, hook managed absent | Repudiation | hors périmètre (limite déclarée, deferred) : le gate rend visible et trace |

## Sources

### Primary (HIGH confidence)
- Claude Code 2.1.284 — **captures réelles** de payloads PreToolUse (3 sessions `claude -p` avec hooks injectés par `--settings`) : compacité, ordre des clés, `agent_id`/`agent_type`, `Agent`/`Task`, shell `/bin/sh -c`, `cwd` physique, deny bloquant, script absent non bloquant, `additionalContext` `[VERIFIED: sonde]`
- `https://code.claude.com/docs/en/hooks` — champs `command`/`args`/`timeout`, substitution des placeholders (forme exec sans shell), règles de matcher, `cwd` suit Claude, codes de sortie `[CITED]`
- Fichiers ouverts cette session : `45-CONTEXT.md`, `45-SCOUTING.md`, `45-DISCUSSION-LOG.md`, `REQUIREMENTS.md`, `STATE.md`, `plugin/_internal/merge-hooks.sh`, `plugin/_internal/vibeflow-update.sh` (l.1815-1838, 1895-1934, 1987-2054, 456-471), `plugin/planning-core/{hooks/hooks.json,module.json,VERSION,scripts/recalc-planning.sh,scripts/detect-gsd-engine.sh,scripts/guard-planning-updated.sh,scripts/tests/*,references/modele-cycles.md}`, `plugin/conductor/scripts/{check-agents.sh,guard-driver-lock.sh,check-guard-health.sh,check-planning-consumers-registered.sh}`, `plugin/software-architecture/scripts/guard-file-size.sh`, `plugin/_internal/lib/vf-portable.sh`, `scripts/{check-gate-touche.sh,check-version-sync.sh,check-machine-paths.sh}`, `scripts/tests/test-hook-exit-parc.sh`, `.github/workflows/ci.yml`, `docs/HOOKS-CONTRAT-SORTIE.md`, `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` (§5, 5.1, 5.2, 10, 11), `…fabrique-agents-skills-design.md` (§4, §5), `32-TERRAIN.md` (payload réel de 2.1.233 : compact, `cwd` avant `tool_name`)

### Secondary (MEDIUM confidence)
- Mesures en lecture seule de `~/jarvis-keystone` et `~/BusinessFlow-Lab` (comptes uniquement ; aucun fichier écrit, aucune commande git)

### Tertiary (LOW confidence)
- Comportement Linux (dash/GNU/mawk) — déduit, à prouver en CI (A1, A4)

## Metadata

**Confidence breakdown:**
- Standard stack : HIGH — aucune dépendance nouvelle ; outils mesurés
- Architecture : HIGH — contrat du harnais et couche shell prouvés de bout en bout ; MEDIUM pour la partie Python (non écrite) et la sémantique de G1/G7/rôle (F4-F9)
- Pitfalls : HIGH — chacun a une mesure ou une citation de fichier

**Research date :** 2026-09-29
**Valid until :** 2026-10-13 (14 jours : Claude Code sort une version par semaine ; **re-mesurer** le contrat du harnais — `Agent`/`Task`, ordre des clés, `additionalContext` — si `claude --version` dépasse 2.1.284 avant l'exécution)
