# Phase 58: Rôles de poste — installeur, profils solo / product / dev - Context

**Gathered:** 2026-10-16
**Status:** Ready for planning

Cadrage porté par `vf-dev-manager` (mission-flow §Pattern F) : faits établis d'abord par un éclaireur en lecture seule
sur `a2ed5094`, puis 14 questions groupées en quatre zones, escaladées à la session principale par `SendMessage(main)`.
**P58-D-01 à P58-D-14 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-16**. L'option recommandée a
été retenue à chaque fois. P58-D-15 à P58-D-20 sont laissées à la discrétion du planificateur : ce sont des
conséquences des décisions arbitrées, aucune n'ouvre un choix neuf.

**Exigences :** famille `RLPO` (réservée le 2026-10-08, libre au 2026-10-16 : `RLPO-[0-9]` absent de main et de
toutes les branches `origin/*`). Elles sont posées à l'ouverture de la planification et reformulent P58-D-01 à
P58-D-20 sans rien y ajouter.

<domain>
## Phase Boundary

`/vibeflow-install` demande le **poste** de l'humain sur ce projet, pré-coché « solo », avec un mode non interactif
par `VF_ROLE`. `module.json` porte une clé `roles` optionnelle (absente = tous les postes), et
`build-module-catalog.sh` filtre le catalogue quand un poste est donné. Le poste vit dans un fichier local non
versionné. Le projet ne porte que la liste des postes autorisés, vérifiée par `check-role-consistency.sh`. Trois
profils seulement : `solo` (défaut, identique à aujourd'hui), `product`, `dev` (A-02).

**Un poste est une vue, pas un droit.** Git ne tient aucun cloisonnement humain, et la doc le dit dès sa première
ligne (spec §5.1).

Hors de cette phase :
- les postes architecte, QA et scrum master (A-02) ;
- tout contrôle d'accès ;
- la front door `vibeflow-product`, le bundle produit et la redirection du head selon le poste (Phase 59) ;
- la validation des phases proposées (Phase 60) ;
- le champ `role:` des registres (Phase 61).

La 58 fige seulement l'**interface de lecture** du poste dont ces phases auront besoin (P58-D-15).

</domain>

<decisions>
## Implementation Decisions

### Modèle du poste
- **P58-D-01 (fichier de poste)** : `.claude/vibeflow-role`, une seule ligne de texte, la valeur du poste.
  - Un seul usage, lisible en bash sur tous les runtimes.
  - Aucune collision avec les écritures JSON de `merge-hooks.sh` et de Claude Code dans `settings.local.json`.
  - Contrepartie assumée, qui est un **comportement neuf** : l'engine pose la règle d'ignorance de ce fichier
    dans **tous les scopes**, alors qu'aujourd'hui seul le scope `local` touche `.gitignore`
    (`vibeflow-update.sh:1159`). Il ajoute aussi une entrée `.worktreeinclude` (P58-D-16).
- **P58-D-02 (postes autorisés du projet)** : clé `vf_roles` (liste) dans le `.planning/config.json` **racine**, sur
  le précédent de `vf_runtimes` (`plugin/conductor/scripts/runtime-registry.sh:6`, propriété VibeFlow, jamais lue
  par gsd-core).
  - Liste absente : le gate se tait (issue 3), et un lab sans liste reste identique à l'octet près.
  - Un lab partitionné la lit à la même racine : les workstreams découpent par périmètre, jamais par poste (spec
    §5.3).
  - Un lab sans `.planning/` n'a pas de liste, donc silence.
- **P58-D-03 (sémantique)** :
  - `solo` est un **sur-ensemble implicite** : il voit tout, et il n'apparaît jamais dans une liste `roles` de
    `module.json`.
  - Valeurs admises dans `roles` : `product`, `dev`. `roles: []` et toute valeur inconnue sont refusés
    **bruyamment** par un validateur neuf (aucun validateur de schéma de `module.json` n'existe aujourd'hui).
  - « Absent = tous » est fixé par la spec §5.4.
- **P58-D-04 (scope user)** : en scope `user`, l'installeur ne pose aucune question et le poste vaut `solo`. La spec
  dit « rôle **sur ce projet** ».

### Ce que filtre le poste
- **P58-D-05 (scope project partagé)** :
  - Le filtre ne joue **qu'à la pose**, par l'humain qui installe.
  - En scope `project`, les modules sont versionnés et partagés par git : un filtre d'installation ne peut pas
    donner deux vues à deux humains sur un même dépôt.
  - Pour l'autre humain, le masquage passe par les front doors et par le contexte SessionStart (P58-D-10). La phrase
    « un poste est une vue, pas un droit » est écrite partout où le poste est présenté.
  - Le critère 1 du jalon (« une install `VF_ROLE=product` n'expose aucune commande dev ») se mesure sur un **lab
    neuf**.
  - Options écartées : forcer le scope `local` pour les modules filtrés (contredit la spec §5.4), et interdire les
    Skill par des réglages propres à chaque utilisateur (capacité non vérifiée).
- **P58-D-06 (table `roles`)** : table minimale, `roles: ["dev"]` sur **dev-orchestrator, mobile-test et
  mobile-test-team** seulement ; la clé reste absente partout ailleurs.
  - Une « commande dev » est un skill ou un agent de ces trois modules, plus gsd-* et superpowers, qui ne sont pas
    amorcés : `ensure-deps.sh` n'est lancé que si dev-orchestrator est posé.
  - Aucune fuite de fermeture mesurée : aucun module non dev ne requiert un module dev (`resolve-deps.sh` reste
    inchangé, spec §5.4).
  - design-orchestrator reste ouvert à product, qui écrit l'UI-SPEC en binôme (spec §5.1).
  - **Limite actée** : un GSD déjà installé au scope user de la machine reste visible, et le poste n'y peut rien.
- **P58-D-07 (changement de poste sur un lab installé)** : réécrire le fichier de poste, puis afficher un **avis**
  listant les modules installés hors du nouveau poste. Aucune désinstallation : ADR-031, et en scope project elle
  retirerait aussi les modules de l'autre humain.
- **P58-D-08 (`--all`)** :
  - `install --all` ne filtre que si `VF_ROLE` est posé **explicitement**.
  - `update --all` ne change pas : il suit le registre `.vibeflow-installed`.
  - Le poste n'entre **jamais** dans ce registre (`mod=version` strict, l.62-120 ; une ligne `role=…` serait lue
    comme un module par `update --all`, l.3264-3266).

### Gate, contexte, doctrine
- **P58-D-09 (`check-role-consistency.sh`)** : nouveau gate, en forme exec (ADR-071), consultatif (ADR-031/074).
  - **Issues** :
    - `0` : poste présent dans la liste ;
    - `1` : poste hors liste ou valeur invalide ;
    - `3` : silence (pas de liste, ou pas de fichier de poste) ;
    - erreur d'analyse **bruyante** : liste illisible, lien symbolique, plusieurs lignes, sur un code non nul
      distinct (2 reste réservé au blocage).
  - **Câblage** : un hook SessionStart dans `conductor`, plus un refus à la pose par l'installeur.
  - **QUAL-01** : chaque issue est prouvée par une mutation qui rend rouge. En CI, seule la suite tourne, puisque ce
    dépôt n'a pas de fichier de poste.
- **P58-D-10 (contexte SessionStart, A-04)** : porté **en 58**, par le stdout du même hook.
  - Une ligne « Poste : X » quand le poste n'est pas solo, rien en solo. Aucun hook neuf.
  - Le stdout d'un hook SessionStart qui sort en 0 est injecté comme contexte (`docs/HOOKS-CONTRAT-SORTIE.md` §3).
  - Le critère 2 tient : sans poste, rien ne change.
- **P58-D-11 (doctrine)** : **ADR-077** est rédigé en 58 (numéro libre ; dernier ADR = 076 sur main et sur les
  branches de Willy). Il porte deux énoncés :
  - « agentique first, ouvert à la collaboration humaine » (promis au cadrage du jalon par
    `.planning/notes/2026-09-16-doctrine-agentique-ouverte-collaboration-humaine.md`, jamais écrit) ;
  - « un poste est une vue, pas un droit ».
  - `docs/ADR.md` est un fichier de dépôt : on l'écrit sous verrou `--depot` court (P57-D-02).
- **P58-D-12 (vocabulaire)** :
  - La 3e colonne du catalogue (`mandatory`/`optional`) est renommée « statut » **dans la doc seulement**. La sortie
    machine ne change pas : la CI la consomme (`ci.yml:1947`, `awk '$3 == "mandatory"'`).
  - Une entrée de glossaire distingue trois sens : le **poste** d'un humain, le **rôle d'agent** (Phase 45 de Willy,
    `register-codex-agent.sh`) et le **statut** de module.
  - Dans la doc de cette phase, « poste » désigne le rôle humain. Les identifiants techniques restent ceux de la spec
    (`VF_ROLE`, `roles`, `vf_roles`, `vibeflow-role`).

### Collision avec Willy et branche
- **P58-D-13 (`gitignore_add_paths()`)** : ses PR #136, #146 et #147, non mergées, modifient cette fonction
  (`vibeflow-update.sh:1159-1240`, commits `3027b186` et `2f3e5b3c`).
  - La règle d'ignorance du fichier de poste est posée dans un **bloc ou une fonction séparés**, appelés à côté, pour
    éviter le conflit textuel.
  - Rebase sur main avant le merge.
  - Aucune de ses branches ne touche `plugin/installer/**`, `build-module-catalog.sh`, `presets.json`,
    `resolve-*.sh`, ni les trois `module.json` visés.
  - `plugin/planning-core/module.json`, que ses branches modifient, n'est **pas** touché (P58-D-06).
- **P58-D-14 (branche)** : `feat/phase-58-roles-de-poste`, empilée sur `docs/cloture-phase-57` (clôture de la 57 et
  tri du BACKLOG, non poussée), rebasée sur main dès que la clôture est mergée.

### Claude's Discretion (conséquences, aucun choix neuf)
- **P58-D-15 (lecteur unique)** : un seul lecteur installé dans le lab, sous `conductor/scripts/` (conductor est
  mandatory, donc présent pour tous les postes et copié dans `.claude/scripts/`, qui est dans `.worktreeinclude`).
  - Contrat : stdout = exactement une valeur parmi `solo|product|dev`. Priorité : `VF_ROLE` de l'environnement, puis
    le fichier. Fichier absent = `solo` (H-03). Valeur invalide ou fichier illisible = erreur bruyante, jamais un
    repli silencieux.
  - Le nom (proposé : `vf-role.sh get|set`) est laissé au planificateur.
  - Ce contrat est l'interface que liront les Phases 59 à 61.
- **P58-D-16 (worktrees)** : `.claude/vibeflow-role` est ajouté à la liste de `ensure_worktreeinclude_entries`
  (`vibeflow-update.sh:1815-1853`). Sans cela, un worker isolé lirait le poste absent, donc « solo », en silence.
- **P58-D-17 (catalogue)** :
  - Filtre par `--role <poste>` ou par `VF_ROLE` (le drapeau l'emporte).
  - Sortie à 3 colonnes **inchangée** ; sans poste, sortie identique **à l'octet** (preuve `cmp`).
  - Les 14 cas de `test-build-module-catalog.sh` restent verts sans modification.
  - Un invariant testé : la fermeture des modules autorisés à `product` ne contient aucun module `["dev"]`.
- **P58-D-18 (étape de l'installeur)** :
  - La question du poste s'insère entre le choix du scope (étape 2) et le type de lab (étape 4) de
    `plugin/installer/SKILL.md`, et seulement en scope `project` ou `local` (P58-D-04).
  - `VF_ROLE` suit la forme des autres `VF_*` : la variable d'environnement, le drapeau l'emporte.
  - La phrase périmée « les bundles métier sont `proposable:false` » (SKILL l.112-114 ; les trois sont `true` depuis
    le 2026-07-25) est corrigée au passage, puisque la même section est réécrite.
- **P58-D-19 (preuves)** :
  - critère 1 : de bout en bout sur un lab neuf (HOME et dossier temporaires), `VF_ROLE=product` ;
  - critère 2 : non-régression d'une install sans poste, sortie et arbre posés comparés à une install de
    référence ;
  - critère 5 : `check-agents.sh --strict`, et aucun agent > 250 lignes ;
  - critère 6 : aucun nom de client.
- **P58-D-20 (versions)** : bumps de module sans release dans la phase : conductor, dev-orchestrator, mobile-test,
  mobile-test-team, plus installer s'il porte une VERSION, avec CHANGELOG et README touchés. La release reste un
  geste humain hors phase.

### Arbitrages de reprise (2026-10-20)
- **P58-D-21 (filtrage des presets)** : arbitrage Samuel, AskUserQuestion session principale, 2026-10-20 (Q16 corrigée).
  - En 58, un poste `product` ne se voit plus proposer un preset dont la **fermeture de dépendances** contient un module
    `roles: ["dev"]` ; le preset reste proposé en `solo` et en `dev`. Il s'agit d'un retrait du CHOIX, jamais d'un droit
    (ADR-077) : la résolution nommée d'un preset ne change pas, l'engine refuse déjà à la pose.
  - Emplacement : `resolve-preset.sh list --role <poste>` (`plugin/_internal/resolve-preset.sh`, branche `list`),
    délégation à `resolve-deps.sh` (fermeture) et `module-roles.sh` (prédicat) ; sortie sans poste identique à l'octet
    (critère 2). Plan 58-12, exigence RLPO-06 (l'installeur propose à chaque poste ce qui lui est proposable).
  - Annule le report de P58-PL-04 (le filtre des presets était renvoyé à Samuel).
- **Q15 / Q17 (2026-10-16)** : liste des clients lue par `VF_CLIENT_NAMES_FILE`, défaut `~/.config/vibeflow/clients.txt`,
  absence = code 2 et critère 6 « en attente de la liste », jamais un échec de phase ; sous-section « Poste » du manuel
  FR+EN. Réalisés par 58-11 (arbitrage Samuel, AskUserQuestion session principale, 2026-10-16).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Doctrine et cahier des charges
- `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md` §5.1 (l.141-163), §5.3, §5.4 (l.199-209), §9
  (critères du jalon).
- `.planning/seeds/SEED-001-equipe-produit-v1.md` : A-02, A-04, A-11.
- `.planning/notes/2026-09-16-doctrine-agentique-ouverte-collaboration-humaine.md` (contenu d'ADR-077).
- `.planning/workstreams/fiabilite/ROADMAP.md` §Milestone equipe-produit-v1.0 et §Phase 58.
- `docs/HOOKS-CONTRAT-SORTIE.md` §3 (stdout SessionStart) ; ADR-071 (forme exec) ; ADR-031 et ADR-074
  (consultatif).

### Code
- `plugin/installer/SKILL.md` (189 lignes, étapes 0-6) ; `plugin/installer/scripts/build-module-catalog.sh` (57
  lignes) et sa suite `tests/test-build-module-catalog.sh` (14 cas).
- `plugin/_internal/vibeflow-update.sh` :
  - scopes : l.330-331 ;
  - registre : l.62-120 et l.3264-3266 ;
  - `.gitignore` en scope local : l.1159-1240 ;
  - `settings.local.json` : l.1955-1962 ;
  - `.worktreeinclude` : l.1815-1853.
- Suites voisines : `plugin/_internal/tests/test-vibeflow-update.sh`, `test-resolve-deps.sh`,
  `test-resolve-preset.sh`, `test-manifest.sh`.
- `plugin/conductor/scripts/runtime-registry.sh:6` (précédent `vf_runtimes`) ; `plugin/*/module.json` (17 modules,
  clés communes : name, version, type, description, requires).
- `plugin/conductor/hooks/hooks.json` (fragment fusionné par `merge-hooks.sh` : effet global, zone de risque de
  `MISSION-INVARIANTS.md`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Le moule des variables `VF_*` (`VF_SCOPE`, `VF_DRY_RUN`, `VF_MODULES_ROOT`) et des lectures « variable
  d'environnement, sinon clé de `config.json` » (`VF_LAB_PROFILE`/`profile`).
- Les fermetures de dépendances, déjà calculables par `resolve-deps.sh` :
  - baseline = audit-architecture, conductor, consolidator, infrastructure-audit, planning-core, skill-creator,
    validator ;
  - preset `dev` = baseline + design-orchestrator + dev-orchestrator.

### Established Patterns
- Gate à trois issues plus erreur d'analyse bruyante, mutations rouges (QUAL-01), forme exec des hooks (ADR-071).
- Hooks posés par fragments `hooks.json` fusionnés : en scope project ou local, un hook qui porte le chemin bash de
  la machine est routé vers `settings.local.json`.

### Integration Points
- L'installeur (skill + engine) pose le fichier de poste et la règle d'ignorance.
- Le hook SessionStart de conductor lit le poste et en injecte le contexte.
- Le catalogue filtre.
- Phases 59 à 61 : elles lisent le poste par le lecteur unique (P58-D-15).

</code_context>

<specifics>
## Specific Ideas

- Le mot « rôle » a trois sens dans le dépôt (P58-D-12). Les noms techniques gardent `role`, la prose dit « poste ».
- La Phase 48 du compartiment `gouvernance`, planifiée, livrera un module neuf : il lui faudra une décision `roles`.
  On le signale à Willy, sans rien écrire dans son compartiment.

</specifics>

<deferred>
## Deferred Ideas

- Masquage des Skill par des réglages Claude Code propres à chaque utilisateur (capacité non vérifiée, option écartée
  en P58-D-05) : spike possible si le besoin d'une vraie seconde vue sur un même clone est prouvé en Phase 61.
- Poste par compte (scope user) ou surcharge par projet (écartés en P58-D-04).

</deferred>
