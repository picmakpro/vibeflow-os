# Phase 45: Moteur — hook central par rôle et gates d'écriture - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning
**Compartiment :** `gouvernance` — toute commande GSD de cette phase passe `--ws gouvernance`.
**Décisions humaines :** Q1 à Q6 tranchées par Willy, AskUserQuestion session principale,
2026-09-29, relayées par la session principale au manager de mission. Après un `/clear` qui a
coupé la mission, Willy les a **reconfirmées telles quelles**, avec les 13 décisions marquées
« délégué » : « Willy, AskUserQuestion session principale, 2026-09-29 (reconfirmation après
/clear) ». Les décisions marquées « manager » ont été prises après cette reconfirmation. Willy ne
les a pas relues ; il peut les renverser.
**Faits de départ :** `45-SCOUTING.md` (recherche doc des hooks Claude Code 2.1.284 et
cartographie du dépôt, 2026-09-29). Le planificateur le lit avant tout.

<domain>
## Phase Boundary

La phase livre **un script de hook central**, dans `plugin/planning-core/`, et rien de plus. Il
porte deux familles de refus :

1. **Les gates d'écriture du moteur**. G1, G5, G6 et G7 refusent par `permissionDecision: deny`.
   G2 avertit sans refuser (spec moteur §5).
2. **Le cloisonnement par rôle** (spec fabrique §5, B-02). Le hook lit `agent_type`, en dérive un
   rôle (juge, worker, producteur, tous) et applique la table du §5. « Une mécanique, deux
   chantiers » : c'est le même script que G5.

S'y ajoutent ce que ces refus exigent pour être crus :
- un comportement fail-closed déclaré, gate par gate ;
- un **canary** par gate, qui prouve qu'il refuse encore ;
- une **mesure des faux refus dans les deux sens** avant armement ;
- une **dérogation nominative et journalisée** ;
- la **commande qui pose `VERDICT.md`**, seul chemin légitime une fois G5 armé.

La phase livre aussi la levée du refus de la 44 pour un lab métier qui contient du code et qui a
adhéré (Q2).

**Hors de cette phase :**
- G2′, G3, G4, G4′ et D1 (`TaskCompleted`, `SubagentStop`, `FileChanged`) : Phases 46 et 47.
- La vérification du hash de `VERDICT.md` à la clôture : Phase 46.
- Les baux et le jeton monotone : Phase 47.
- L'injection de l'index et les agents génériques de cycle : Phase 48.
- Le retrait du socle v2 (`guard-planning-updated.sh`) : non retiré, P45-D-19.

</domain>

<decisions>
## Implementation Decisions

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

- **P45-D-06b (manager, 2026-09-29, après le plan-check frais) :** quand le script ou `python3`
  manque dans un lab adhérent, la commande enregistrée refuse `Write`, `Edit` et `NotebookEdit`,
  et **aussi `Agent` et `Task`**, conformément à la lettre de Q6 (a). **`Bash` reste ouvert**,
  pour que la réparation (poser le script, installer `python3`) reste possible. C'est une limite
  déclarée, cohérente avec P45-D-10. Elle est écrite dans la référence du modèle et dans le relevé
  du canary.

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
- **P45-D-12a (manager, 2026-09-29, après le plan-check frais) :** aucune variable
  d'environnement ne change **l'armement** ni **l'adhésion**. **`HOME` est une entrée déclarée**
  de la résolution des définitions d'agent (P45-D-05b), et elle seule. Un cas de test fixe ce
  périmètre : un `HOME` différent change la résolution d'un agent du compte, mais jamais
  l'adhésion ni l'état d'armement.
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

- **P45-D-21a (Willy, AskUserQuestion session principale, 2026-09-29) :** pour le rejeu sur un lab
  réel **non migré**, **le modèle fait référence**.
  - **Faux refus :** une écriture que le modèle autorise et que le gate refuse.
  - **Pas un faux refus :** une écriture que le modèle interdit. Exemple : réécrire un `PLAN.md`
    dans une phase sans `CADRAGE.md`, comme les 197 phases de Keystone. Ces cas sont comptés à
    part, sous le libellé **« refus conforme au modèle, lab non migré »**, et le relevé en donne le
    nombre.

  Conséquences :
  - les gates peuvent s'armer pendant la mission, dans l'ordre de P45-D-03 et au seuil de
    P45-D-03b, appliqué aux seuls faux refus ainsi définis ;
  - le **coût de migration** d'un lab (cadrages à écrire, ou dérogations) est documenté dans la
    référence du modèle pour le jour de l'adhésion ;
  - aucune règle de gate ne change, et le goal de la ROADMAP reste tel quel.
- **P45-D-14a (Willy, AskUserQuestion session principale, 2026-09-29) :** la **table D-05 de la
  spec est corrigée**, pas le prédicat. Un dossier dont le `.claude/` n'a ni agent ni mémoire non
  vide **n'est pas un lab**, même si la table le comptait comme tel. G7 garde le **prédicat
  littéral** de P45-D-14 : au moins un agent **et** au moins une mémoire.
  - `~/jarvis-keystone/00-doctrine` a un `.claude/` réduit à un `agent-memory/` vide (mesuré le
    2026-09-29). Il devient un **« refus conforme au modèle »**.
  - Lecture du manager, par la même règle : tout dossier que le prédicat littéral refuse est un
    refus conforme au modèle. C'est le cas de `ProjetFlow-FROZEN-A1`, absent de la table (mémoire
    sans agent, `45-RESEARCH.md` l.520).
  - La table D-05 de `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` est
    **amendée dans la phase**, avec la mesure et la citation. Les attendus du rejeu de G7 en
    dérivent. G7, puis le hook par rôle, peuvent s'armer en mission.
- **P45-D-21c (manager, 2026-09-29, après le plan-check du tour 3) :** la classification « du
  modèle » d'une écriture rejouée est **totale**.
  - **Quand le recalcul donne un état de phase** (`recalc-planning.sh --read-only`), c'est lui
    qui fait référence.
  - **Quand il n'en donne pas** (cycle sans `CYCLE.md`, qui rend `phases: []` ; courts-circuits
    Φ0/Φ1 de `indéterminé`), l'outil de rejeu applique la **règle écrite du modèle**
    (`modele-cycles.md` et spec §5 : un `PLAN.md` exige un `CADRAGE.md` à registre clos). Il le
    fait **avec son propre code**, sans jamais appeler l'évaluation du hook. Ces cas sont
    comptés dans un sous-compte distinct du relevé, « classé par la règle écrite, état dérivé
    absent ». Une fixture et un mutant rouge tracé couvrent ce chemin. Mesure : 8 `PLAN.md` sans
    `CADRAGE.md` sur Keystone sont dans un cycle sans `CYCLE.md`.
- **P45-D-21b (manager, 2026-09-29, après le plan-check du tour 2) :** en scope projet,
  `$CLAUDE_PROJECT_DIR` choisit **quelle copie** de `planning-hook.sh` s'exécute, et donc quelle
  table d'armement. Une copie périmée d'un autre worktree peut s'exécuter à la place de la bonne
  (`45-SCOUTING.md` A.5, C.3). Cette dépendance n'est pas testable depuis le hook : elle est
  déclarée comme **limite (i)** de P45-D-12a. C'est le canary de session (P45-D-20), en rejouant
  la commande enregistrée telle qu'elle est posée, qui la rend visible.

### Claude's Discretion

Laissés au planificateur :
- nom du script et des commandes (verdict, dérogation) ;
- format du journal de dérogation ;
- structure interne du Python ;
- ordre de résolution fin des définitions d'agent (sous P45-D-05b) ;
- durée de vie d'une dérogation (sous P45-D-13) ;
- découpage en plans, dans l'ordre des vagues imposé par P45-D-03.

</decisions>

<requirements_proposed>
## Exigences proposées (famille GATE)

Chaque exigence dérive d'une décision ci-dessus et n'en pose aucune nouvelle.

- **GATE-01** : un script de hook central unique dans `plugin/planning-core/` (Python embarqué dans
  un `.sh`), déclaré par `hooks.json`, n'agit que dans un lab adhérent `cycles-v1`, dont la racine
  est dérivée du chemin écrit ou du `cwd` du payload, jamais de `$CLAUDE_PROJECT_DIR`. Hors lab
  adhérent, il ne sort rien et rend 0 (P45-D-01, P45-D-01a, P45-D-12, P45-D-15).
- **GATE-02** : tout refus est un `permissionDecision: "deny"` JSON avec exit 0, jamais exit 2.
  Toute erreur interne est piégée en deny dans le périmètre adhérent (P45-D-08).
- **GATE-03** : la commande enregistrée émet elle-même un deny, avec un message de réparation, si
  le script ou `python3` manquent dans un lab adhérent. Elle décide de l'adhésion sans `python3`.
  Un lab non adhérent n'est jamais refusé, même sans `python3` ni script (P45-D-06, P45-D-06a).
- **GATE-04** : G6 refuse toute écriture par outil de `STATE.md`, `INDEX.md`, `cloture.log` et du
  journal de dérogation d'un lab adhérent (P45-D-13, spec §5).
- **GATE-05** : une commande pose `VERDICT.md` avec le hash sha256 de l'artefact jugé et le numéro
  de tentative, au format de la 44. G5 refuse toute écriture par outil de `VERDICT.md`, quel que
  soit le rôle (P45-D-07).
- **GATE-06** : G1 refuse l'écriture d'un `PLAN.md` sans `CADRAGE.md`, ou avec une ligne
  structurante sans statut (spec §5).
- **GATE-07** : G7 refuse la création d'un `.planning/` sous un lab adhérent quand le dossier
  parent n'a ni `.claude/` habité (prédicat littéral écrit dans la référence) ni marqueur de code
  (P45-D-14).
- **GATE-08** : G2 avertit, sans jamais refuser, sur une écriture `Write`/`Edit`/`Bash` hors
  `ecrit:`. La limite « Bash non couvert par les refus » est écrite dans la référence et dans le
  message (P45-D-10).
- **GATE-09** : le hook par rôle dérive le rôle du frontmatter par les prédicats I5/I6 et
  `vf-internal`. Il refuse au juge toute écriture par outil et au worker tout dispatch
  `Agent|Task` (les deux `tool_name`, `subagent_type` normalisé). Un fil principal ou un agent
  inconnu n'a que la ligne « Tous ». Un contrôle croisé prouve l'accord avec `check-agents.sh` sur
  tout le corpus (P45-D-04, P45-D-05, P45-D-05a, P45-D-05b, P45-D-09, P45-D-11).
- **GATE-10** : zéro régression sur les labs dev. Sur un lab dev fixture et sur ce dépôt, le hook
  rend un octet vide et 0 pour chaque type d'appel, et la mutation « ignorer l'adhésion » rend la
  preuve rouge (P45-D-04).
- **GATE-11** : une dérogation nominative (qui, canal, date, gate, chemin(s), raison qui n'est pas
  un placeholder) est posée par une commande dans un journal append-only protégé par G6. Elle
  n'est jamais conditionnée à l'urgence, et elle est citée dans la sortie de l'action qu'elle
  laisse passer (P45-D-01, P45-D-13).
- **GATE-12** : un canary par gate armé rejoue la commande enregistrée telle quelle et exige un
  deny. Il est bloquant en CI et signale au démarrage de session d'un lab adhérent. Il couvre au
  minimum : script absent, `python3` absent, `Task` et `Agent`, fil principal, agent `plugin:`
  (P45-D-20).
- **GATE-13** : les faux refus sont mesurés dans les deux sens pour chaque gate, sur le banc en CI
  puis sur le rejeu en lecture seule de deux labs réels, sans écriture prouvée par une empreinte.
  L'armement suit l'ordre G6+G5 → G1 → G7 → rôle, et chaque étape exige 0 faux refus et 0 faux
  accept (P45-D-03, P45-D-03a, P45-D-03b, P45-D-21).
- **GATE-14** : `recalc-planning.sh` écrit sur un lab adhérent quand le détecteur rend 2. Sans
  adhésion, son refus est inchangé (exit 2, rien touché) ; avec le détecteur à 0, le refus reste
  (exit 3). Les trois branches ont leur jumeau négatif et leur mutation rouge ;
  `detect-gsd-engine.sh` et `workstream-policy.sh` restent inchangés (P45-D-02, P45-D-02a,
  P45-D-02b).
- **GATE-15** : les suites sous `plugin/planning-core/scripts/tests/` tournent en CI Linux, sans
  dépendance GNU/BSD, et chaque garde est prouvée par une mutation rouge tracée. `planning-core`
  reçoit un bump mineur, sans release, et `guard-planning-updated.sh` n'est pas retiré (P45-D-16,
  P45-D-18, P45-D-19).

</requirements_proposed>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Faits de départ
- `45-SCOUTING.md` (ce dossier). Il donne :
  - le contrat du harnais : forme du refus, échecs qui laissent passer, `Agent|Task`,
    `$CLAUDE_PROJECT_DIR` ;
  - les gardes existants ;
  - les prédicats I5/I6 ;
  - les codes du détecteur et du recalcul ;
  - la CI.

### Spec source
- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` :
  - §5, table des gates : G1, G2, G5, G6, G7 ;
  - §5.1, trois contraintes : deny, fail-closed déclaré, faux refus ;
  - §5.2, dérogation : ses trois règles ;
  - D-05 (§2), lab = `.claude/`, labs emboîtés, orphelins de BusinessFlow ;
  - §10, compteur de tentatives.
- `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` :
  - §4, invariants I5/I6 ;
  - §5, table des rôles ;
  - B-02 (§2).

### Planning du compartiment
- `.planning/workstreams/gouvernance/ROADMAP.md` § Phase 45, et l'en-tête du jalon : pas de
  release, gates rejoués à la main.
- `.planning/workstreams/gouvernance/REQUIREMENTS.md`, famille `GATE` (P45-D-17).
- `.planning/workstreams/gouvernance/STATE.md` : tenu à la main, jamais par `state.*`, frontmatter
  fermé avant la ligne 60.
- Phase 44 : `44-CONTEXT.md` (P44-D-02, D-02a, D-05, D-06b, D-14, D-15) et
  `plugin/planning-core/references/modele-cycles.md` (format de `VERDICT.md`, `CLOTURE.md`,
  fichiers générés, « hors de cette phase »).

### Module cible et voisins
- `plugin/planning-core/` : `hooks/hooks.json`, `scripts/recalc-planning.sh` (refus l.1841-1858),
  `scripts/detect-gsd-engine.sh` (inchangé), `scripts/tests/`, `references/modele-cycles.md`,
  `VERSION`, `CHANGELOG.md`, `README.md`.
- `plugin/conductor/scripts/check-agents.sh` : prédicats I5 (l.135-142, 908-922) et I6
  (l.128-134, 893-906).
- `plugin/conductor/scripts/check-guard-health.sh` et `vf-portable.sh` (code 17, marqueurs) :
  famille du canary de session.
- `plugin/_internal/merge-hooks.sh` et `plugin/_internal/vibeflow-update.sh` (l.1828-1834,
  1906-1922, 1984-2054) : pose des hooks, jetons `{{VF_SCRIPTS}}` / `{{VF_BASH}}`, fichiers de
  réglages.
- `docs/HOOKS-CONTRAT-SORTIE.md` : contrat de sortie des hooks du dépôt, à mettre à jour.
- `.planning/BACKLOG.md` l.1116-1144 : hooks absents dans les worktrees.
- `CLAUDE.md` racine :
  - densité ADR-029 ;
  - trailers `Gate-Touche:` sur tout commit qui touche un hook ou sa suite (G-2) ;
  - traçabilité des arbitrages ;
  - préfixage `P45-D-NN`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `plugin/conductor/scripts/dag.sh`, `plugin/planning-core/scripts/recalc-planning.sh` : Python
  embarqué dans un `.sh`.
- `recalc-planning.sh` porte déjà `verifier_adhesion`, le parser de frontmatter minimal, la
  lecture de `VERDICT.md`, et le motif d'environnement construit de zéro pour un sous-processus
  (lot 5 de la 44).
- Les gardes PreToolUse existants (`guard-agent-write.sh`, `guard-driver-lock.sh`) montrent la
  forme du JSON deny. Ils sont fail-open : **ne pas copier leur gestion d'erreur**.

### Established Patterns
- Suites `test-*.sh` découvertes par la CI. Jumeaux négatifs et mutations rouges avec leur trace
  (assertion, attendu, obtenu).
- Le Bash tool du poste tourne sous `/bin/zsh`, la CI sous `bash -e {0}`, sur ubuntu-latest
  uniquement.
- Les commits qui touchent un hook ou sa suite portent `Gate-Touche:`.

### Integration Points
- `hooks.json` de planning-core, entrée `PreToolUse`. La forme exec `{{VF_BASH}}` part dans
  `settings.local.json` en scope projet. Le planificateur vérifie que la commande enregistrée
  garde son test de présence (P45-D-06) sous les deux formes.
- Les compteurs des README racine changent si une suite est ajoutée
  (`scripts/check-version-sync.sh`).

</code_context>

<specifics>
## Specific Ideas

- Le prior de la spec §5.1 : un gate mal calibré a refusé 200 entrées sur 206, soit 97 % de faux
  refus, pendant cinq jours. C'est pour cela que le seuil P45-D-03b vaut zéro, et que le relevé
  nomme chaque refus.
- Les issues amont à surveiller dans les messages et la référence : #82323 (pas de réglage
  fail-closed), #95769 (matcher `Agent`), #76726 (`session_id` du parent).

</specifics>

<deferred>
## Deferred Ideas

- G2′, G3, G4, G4′, D1 : Phases 46 et 47. Vérification du hash de `VERDICT.md` : Phase 46.
- Retrait de `guard-planning-updated.sh` et du socle v2 : sous validation humaine, hors 45.
- Tolérance de faux refus non nulle : n'est pas décidée en mission ; elle remonte à Willy si le
  rejeu la rend nécessaire (P45-D-03b).
- Hook managed (seul à résister à `disableAllHooks`) : hors périmètre. Le gate détecte et trace,
  il ne verrouille pas.

</deferred>

---

*Phase: 45-moteur-hook-central-par-role-et-gates-d-ecriture*
*Context gathered: 2026-09-29*
