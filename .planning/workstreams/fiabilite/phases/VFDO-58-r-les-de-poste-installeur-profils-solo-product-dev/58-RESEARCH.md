# Phase 58: Rôles de poste — installeur, profils solo / product / dev - Research

**Researched:** 2026-10-16
**Domain:** installeur bash (engine `vibeflow-update.sh`, catalogue, skill `vibeflow-install`), manifestes de module, gate consultatif + hook SessionStart (forme exec), doctrine (ADR) — aucun package externe
**Confidence:** HIGH sur tout ce qui est mesuré dans le dépôt ; MEDIUM sur le comportement du harnais Claude Code hors documentation citée (voir Assumptions Log)

> Mesures faites sur `feat/phase-58-roles-de-poste` (HEAD `c8a38435`), arbre `plugin/` identique à `a2ed5094` (= `main` = `origin/main`)
> [VERIFIED: `git diff --stat a2ed5094 HEAD -- plugin scripts .github` rend zéro ligne ; `git rev-parse main origin/main a2ed5094` rend trois fois `a2ed509495e108985344e3db45d35a5d5c928c46`].
> Aucun fichier du dépôt n'a été modifié ; seuls des labs jetables (scratchpad) ont servi aux mesures.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Cadrage porté par `vf-dev-manager` (mission-flow §Pattern F) : faits établis d'abord par un éclaireur en lecture seule
sur `a2ed5094`, puis 14 questions groupées en quatre zones, escaladées à la session principale par `SendMessage(main)`.
**P58-D-01 à P58-D-14 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-16**. L'option recommandée a
été retenue à chaque fois. P58-D-15 à P58-D-20 sont laissées à la discrétion du planificateur : ce sont des
conséquences des décisions arbitrées, aucune n'ouvre un choix neuf.

**Phase Boundary.** `/vibeflow-install` demande le **poste** de l'humain sur ce projet, pré-coché « solo », avec un mode non interactif
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

#### Modèle du poste
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

#### Ce que filtre le poste
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

#### Gate, contexte, doctrine
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

#### Collision avec Willy et branche
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

### Deferred Ideas (OUT OF SCOPE)
- Masquage des Skill par des réglages Claude Code propres à chaque utilisateur (capacité non vérifiée, option écartée
  en P58-D-05) : spike possible si le besoin d'une vraie seconde vue sur un même clone est prouvé en Phase 61.
- Poste par compte (scope user) ou surcharge par projet (écartés en P58-D-04).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RLPO-01 | Fichier de poste local `.claude/vibeflow-role`, règle d'ignorance tous scopes par bloc séparé de `gitignore_add_paths()`, entrée `.worktreeinclude` | §Engine : `gitignore_add_one` réutilisable tel quel (l.1123-1135) ; `ensure_worktreeinclude_entries` (l.1829-1853) ; **piège** : ajout inconditionnel casse T57c/T57h et le critère 2 (voir Pitfall 1) ; liste close du manifeste (l.456-471) |
| RLPO-02 | Lecteur unique sous `conductor/scripts/`, `VF_ROLE` puis fichier, absent = `solo`, invalide = erreur bruyante | §Lecteur : contrat, résolution de racine (jamais par comptage de `../`), CRLF/BOM/symlink/multi-ligne |
| RLPO-03 | `vf_roles` dans `.planning/config.json` racine, jamais lue par gsd-core | §Config : précédent `runtime-registry.sh`, mais gsd-core 1.16.0 **avertit** sur clé inconnue (config-loader.cjs:807-813) ; aucun écrivain en 58 |
| RLPO-04 | Clé `roles` + validateur neuf + table minimale (3 modules) | §Validateur : emplacement `plugin/_internal/module-roles.sh`, prototype jq vérifié, fermeture `product` mesurée sans fuite |
| RLPO-05 | Catalogue filtré, 3 colonnes inchangées, 14 cas verts, invariant de fermeture | §Catalogue : insertion, collision de nom `role`, recette de preuve `cmp` |
| RLPO-06 | Installeur : question du poste, `VF_ROLE`, `--all`, registre intact, phrase périmée | §Engine + §SKILL.md : points d'insertion ; **trou** : repli « presets vides → dev-orchestrator » (SKILL l.106-107) fuit du dev vers `product` |
| RLPO-07 | Changement de poste : réécriture + avis, aucune désinstallation | §Engine : verbe `role` proposé, avis data-driven |
| RLPO-08 | Gate `check-role-consistency.sh` 0/1/3 + erreur d'analyse bruyante, QUAL-01 | §Gate : modèle `check-workstream-pointer.sh` + sa suite à mutations ; codes ; G-2/Ajout-Retrait |
| RLPO-09 | Stdout du même hook SessionStart : « Poste : X » hors solo | §Hook : flux, forme exec, groupe, injection d'une valeur validée seulement |
| RLPO-10 | ADR-077 sous verrou `--depot`, colonne « statut » en doc, glossaire | §Registres : format ADR, index, glossaire `REFERENCE.md`, lock |
| RLPO-11 | Preuves du jalon (critères 1, 2, 5, 6) | §Validation Architecture : recettes mesurées (normalisation du critère 2) |
| RLPO-12 | Livraison : branche, fichiers non touchés, bumps | §Registres de cohérence : `check-version-sync`, « N suites », collision Willy |
</phase_requirements>

## Summary

La phase tient en quatre pièces de code petites et un lot de preuves. (1) Un validateur/prédicat `roles` jq-based, unique, appelé par le catalogue et par l'engine. (2) Un lecteur de poste pur bash dans `conductor/scripts/` (interface lue par les Phases 59-61). (3) Un gate consultatif `check-role-consistency.sh` qui emprunte la structure de `check-workstream-pointer.sh` (trois issues + erreur d'analyse bruyante + mutants awk), câblé par une entrée `SessionStart` en forme exec dans `conductor/hooks/hooks.json`. (4) Dans l'engine, une lecture de `--role`/`VF_ROLE` sur le moule exact de `--scope`/`VF_SCOPE`, une pose du fichier de poste par fonctions séparées (`gitignore_add_one` est réutilisable sans toucher `gitignore_add_paths`), un filtre de `install --all`, et un verbe de changement de poste avec avis.

Trois faits mesurés changent le plan par rapport à une lecture littérale du CONTEXT. **(a)** Ajouter `.claude/vibeflow-role` *inconditionnellement* à `ensure_worktreeinclude_entries` (ou une règle d'ignorance inconditionnelle) casse les suites existantes T57c (« exactement 4 lignes ») et T57h (`cmp` CRLF) *et* le critère 2 ; la pose du fichier de poste, de la règle d'ignorance et de l'entrée `.worktreeinclude` doit donc être **conditionnelle à l'existence d'un poste posé**, avec un drapeau de run (pas un test disque) pour que `--dry-run` reste égal à la pose réelle. **(b)** Le critère 2 « arbre identique à une install de référence » est faux par construction si la référence est l'ancien dépôt entier (nouveaux scripts conductor, nouvelle entrée de hook, versions) et faux à cause de 4 sources non déterministes mesurées (backups horodatés, `archive.log`, `.vibeflow-target`, horodatage de `gsd-skills-index.md`) ; la preuve correcte compare **ancien engine vs nouvel engine sur le même cache**, sous normalisation mesurée, avec un témoin qui doit rougir (`VF_ROLE=product`). **(c)** Le skill installeur a un repli (« liste des presets vide → dev-orchestrator ») qui installerait du dev pour un poste `product` : les trois presets existants contiennent tous `dev-orchestrator`, donc la liste de presets d'un poste `product` est vide.

**Primary recommendation:** 8 plans en 4 vagues (§Découpage) ; ne toucher ni `ci.yml`, ni `.github/`, ni la baseline du budget d'instructions, ni le frontmatter du SKILL.md installeur (zone du ratchet `@bootstrap:socle` à 2610), ni `gitignore_add_paths()`, ni `plugin/planning-core/module.json` ; nouvelles suites en fichiers neufs (jamais appendues à `test-vibeflow-update.sh`, que la PR #136 de Willy modifie aussi).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Déclarer quels modules un poste voit (`roles`) | Données de module (`module.json`) | Validateur `_internal/module-roles.sh` | Source unique ; « absent = tous » (spec §5.4) ; aucun nom de module en dur (doctrine du catalogue) |
| Filtrer le catalogue / `install --all` | Installeur (`build-module-catalog.sh`, engine) | `module-roles.sh` (prédicat) | Le filtre ne joue qu'à la pose (P58-D-05) |
| Stocker le poste de l'humain | Fichier local non versionné `.claude/vibeflow-role` | Engine (pose + ignore + worktreeinclude) | Deux humains, deux postes sur un même projet (spec §5.1) |
| Lire le poste (interface 59-61) | Lecteur unique `conductor/scripts/vf-role.sh` | Variable `VF_ROLE` (priorité) | Un seul lecteur, contrat stdout à une valeur (P58-D-15) |
| Lister les postes autorisés du projet | `.planning/config.json` racine (`vf_roles`) | Gate (lecture seule) | Le projet ne porte que la liste (spec §5.1) ; propriété VibeFlow |
| Constater l'incohérence poste / liste | Gate `check-role-consistency.sh` (consultatif) | Hook SessionStart + refus à la pose | ADR-031/074 : constater, jamais bloquer |
| Informer la session du poste | Hook SessionStart (stdout) | — | Plain-text stdout ajouté au contexte [CITED: code.claude.com/docs/en/hooks] |
| Masquer pour « l'autre humain » en scope project | Front doors + contexte (Phase 59) | — | Hors 58 ; un poste est une vue, pas un droit |
| Doctrine | `docs/ADR.md` (ADR-077) | `docs/_transverse/REFERENCE.md` (glossaire) | Fichiers de dépôt ; écriture sous verrou `--depot` |

## Standard Stack

### Core

Aucun package externe n'est installé par cette phase. Les outils sont ceux déjà exigés par l'installeur.

| Outil | Version mesurée | Rôle | Pourquoi |
|-------|-----------------|------|----------|
| bash | 3.2.57 (macOS) [VERIFIED: `bash --version`] ; bash 5 en CI | scripts, hooks, suites | Contrainte portabilité : tout script de hook doit tourner en bash 3.2 (pas de tableau associatif, `mapfile`, `${x,,}`) |
| jq | 1.7.1-apple [VERIFIED: `jq --version`] | prédicat/validateur `roles`, catalogue | Déjà prérequis dur du préflight (`preflight.sh`: « jq (DUR …) ») ; wrapper `jqx` obligatoire (ADR-054, retire `\r`) |
| python3 via `vf_python` | 3.14.6 [VERIFIED: `python3 --version`] | lecture de `vf_roles` dans le gate | Python est un prérequis dur d'`merge-hooks.sh` ; la lib `vf-portable.sh` centralise la résolution (cascade python3→python→py -3) |
| awk / cmp / comm | système | assertions de suites, mutants | Les suites existantes ne se fient ni à `grep` pipé ni à `diff` (voir Pitfall 9) |
| perl | /usr/bin/perl [VERIFIED: `command -v perl`] | `perl -e 'alarm N; exec @ARGV'` à la place de `timeout` | `timeout` et `gtimeout` absents de ce poste [VERIFIED: `command -v timeout gtimeout` ne rend rien] |

### Supporting

| Brique du dépôt | Usage |
|-----------------|-------|
| `plugin/_internal/lib/vf-portable.sh` (`vf_resolve_python`, `vf_python`, `jqx`, `vf_guard_unavailable`, `VF_GUARD_UNAVAILABLE_EXIT_CODE=17`) | gate (lecture JSON), erreur « interpréteur indisponible » bruyante |
| `gitignore_add_one` (vibeflow-update.sh:1123) | règle d'ignorance du fichier de poste, déjà idempotente et déclarée au plan |
| `vf_declare_write` (l.827) | déclaration `--dry-run` de chaque écriture neuve |
| `find_*` en cascade `$TARGET_ROOT/scripts` puis `$CACHE_DIR/conductor/scripts` (l.1495-1500, 1640-1646) | l'engine trouve le gate / le lecteur dès la première install de conductor |
| `.planning/milestones/fiabilite-v1.0-phases/VFDO-40.1-…/tools/replay-ci-jobs.sh` | rejeu local des jobs `tests` et `gates` de `ci.yml` (rejoue 1 étape « suites » + 21 étapes `gates` ; saute l'installation de GSD) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Validateur dans `plugin/_internal/` | `plugin/installer/scripts/` | `_internal/` est déjà dans le cache du plugin et trouvé par l'engine (`find_resolver`, `find_hooks_merger`) ; `installer/scripts/` ne l'est pas pour l'engine. Le catalogue (installer) peut atteindre `../../_internal/` par chemin relatif à son propre emplacement, indépendamment de `VF_MODULES_ROOT` |
| `vf_python` pour lire `vf_roles` | `jqx` | jq est aussi un prérequis dur ; mais la lib centralise Python (ADR-054) et le gate est un consommateur de plus du bloc canonique |
| Lecteur `get|set` | `get` seul + écriture par l'engine | Deux écrivains du même fichier divergent (ignore, worktreeinclude, plan `--dry-run`) ; l'engine possède déjà ces trois gestes. **Recommandé : lecteur `get` seul, écrivain unique dans l'engine** (le nom `get|set` du CONTEXT est « proposé », laissé au planificateur) |

**Installation :** aucune.

**Version verification :** sans objet (aucun package). Versions d'outils ci-dessus mesurées sur ce poste le 2026-10-16.

## Package Legitimacy Audit

Aucun package externe n'est recommandé ni installé par cette phase (bash, jq, python3, awk, perl, git : déjà prérequis de l'installeur). Audit non applicable.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                       ┌────────────────────── pose (humain qui installe) ──────────────────────┐
 VF_ROLE / --role ───► │ vibeflow-update.sh  (pré-parse --role comme --scope ; validation case)   │
 (scope project|local) │   │                                                                      │
                       │   ├─ refus à la pose ──► check-role-consistency.sh --role <poste>        │──► exit 1, rien d'écrit
                       │   │      (liste vf_roles présente et poste absent)                        │     si hors liste
                       │   ├─ filtre `install --all` ──► module-roles.sh visible <mod> <poste>     │
                       │   ├─ pose du poste (fonctions SÉPARÉES, run-scoped, dry-run déclaré)      │
                       │   │      .claude/vibeflow-role  ─ gitignore_add_one ─ .worktreeinclude    │
                       │   └─ `role <poste>` (changement) ──► avis : modules installés hors poste  │
                       └────────────────────────────────────────────────────────────────────────┘
                                  │ jamais dans .vibeflow-installed (mod=version strict)
                                  ▼
   build-module-catalog.sh [--role P | VF_ROLE] ──► name<TAB>description<TAB>statut (3 col., inchangé)
        │  prédicat roles (module-roles.sh) ; `solo` = aucun filtre ; roles invalide = erreur bruyante
        ▼
   SKILL.md : étape poste (après scope, avant type de lab) → catalogue filtré → fermeture → engine

                       ┌───────────────────────── chaque session ─────────────────────────┐
   SessionStart ─────► │ check-role-consistency.sh --hook  (exec : {{VF_BASH}} + args)     │
   (conductor)         │   ├─ vf-role.sh get ──► solo|product|dev  (env > fichier > solo)   │
                       │   ├─ fichier absent / pas de liste ─► silence (stdout 0 octet)     │
                       │   ├─ poste ≠ solo ─► stdout « Poste : X » (valeur VALIDÉE seule)   │
                       │   ├─ poste hors liste ─► une ligne de constat, exit 0 (advisory)   │
                       │   └─ liste/fichier illisible, symlink, multi-ligne ─► stderr, exit 4 (bruyant)
                       └────────────────────────────────────────────────────────────────────┘
   Phases 59-61 ─────► vf-role.sh get   (seule interface de lecture)
```

### Recommended Project Structure

```
plugin/
├── _internal/
│   ├── module-roles.sh                    # NEUF : validate | visible <mod> <poste> | list <poste>
│   ├── vibeflow-update.sh                 # MODIFIÉ : --role/VF_ROLE, pose du poste, filtre --all, verbe role
│   └── tests/
│       ├── test-module-roles.sh           # NEUF
│       ├── test-vibeflow-update-role.sh   # NEUF (jamais appendu à test-vibeflow-update.sh)
│       └── test-roles-e2e.sh              # NEUF : critères 1, 2, 5, 6
├── conductor/
│   ├── hooks/hooks.json                   # MODIFIÉ : +1 entrée SessionStart (exec)
│   └── scripts/
│       ├── vf-role.sh                     # NEUF : lecteur unique (get)
│       ├── check-role-consistency.sh      # NEUF : gate consultatif
│       └── tests/test-vf-role.sh, test-check-role-consistency.sh   # NEUFS
├── installer/
│   ├── SKILL.md                           # MODIFIÉ (corps seulement, JAMAIS le frontmatter)
│   └── scripts/build-module-catalog.sh    # MODIFIÉ : --role / VF_ROLE
│       └── tests/test-build-module-catalog-role.sh   # NEUF (les 14 cas existants intacts)
├── dev-orchestrator|mobile-test|mobile-test-team/module.json   # +"roles": ["dev"]
docs/ADR.md (ADR-077 + ligne d'index), docs/HOOKS-CONTRAT-SORTIE.md (inventaire), docs/_transverse/REFERENCE.md (glossaire)
```

### Pattern 1 : Pré-parse `--role` / `VF_ROLE` sur le moule de `--scope`

**What:** `VF_ROLE="${VF_ROLE:-}"` posé à côté de `VF_SCOPE`, boucle de pré-parse qui accepte `--role <val>` et `--role=<val>` (le drapeau l'emporte), puis validation fermée.
**When to use:** engine et catalogue. Moule vérifié :
```bash
# Source: plugin/_internal/vibeflow-update.sh:138 et 159-166 (pré-parse --scope)
VF_SCOPE="${VF_SCOPE:-project}"
...
    --scope)
      [ "$#" -ge 2 ] || err "--scope nécessite une valeur (user|project|local)"
      VF_SCOPE="$2"
      shift 2
      ;;
    --scope=*)
      VF_SCOPE="${1#--scope=}"
```
Validation fermée sur le même modèle que `case "$VF_SCOPE" in user|project|local) : ;; *) err … esac` [VERIFIED: vibeflow-update.sh:208, texte `*) err "scope invalide : $VF_SCOPE (attendu user|project|local)" ;;`]. Proposition (non exécutée) : `case "$VF_ROLE" in ""|solo|product|dev) : ;; *) err "poste invalide : $VF_ROLE (attendu solo|product|dev)" ;; esac`. La valeur ne doit jamais atteindre `eval`, une position de commande ni un chemin avant cette validation.

### Pattern 2 : Pose conditionnelle, déclarée au plan, sans lire le disque en `--dry-run`

**What:** le fichier de poste, sa règle d'ignorance et son entrée `.worktreeinclude` n'existent que si un poste est posé. Garde par drapeau de run (miroir de `VF_SETTINGS_JSON_WILL_EXIST`, vibeflow-update.sh:365 et sa justification F-01), pas par `[ -f … ]` : en dry-run le disque ne bouge pas, donc la garde disque est fausse sur un lab neuf et le plan ≠ la pose réelle (suites TD1 / T57i comparent ces deux ensembles).
**When to use:** `role_apply` (fonction séparée de `gitignore_add_paths`), appelée avant la boucle de modules de `install` pour que la fin d'`install_module` voie l'entrée.
```bash
# Source: plugin/_internal/vibeflow-update.sh:1836 (boucle actuelle de ensure_worktreeinclude_entries)
  for line in ".claude/hooks/" ".claude/scripts/"; do
```
Proposition : ajouter `.claude/vibeflow-role` à cette liste **seulement si** le drapeau de run « poste posé » est à 1 **ou** si `./.claude/vibeflow-role` existe sur disque (cas `update` d'un lab déjà doté : auto-réparation). Les appels `ensure_worktreeinclude_entries` (lignes exactes `  ensure_worktreeinclude_entries` et `    ensure_worktreeinclude_entries`) sont les cibles des mutants T57j : ne pas les renommer ni les déplacer.

### Pattern 3 : Gate à trois issues + erreur d'analyse bruyante, mutants par copie de script

**What:** modèle `check-workstream-pointer.sh` (en-tête = table d'états, `hook_exit` qui ne traduit que sous `--hook`, `diag`/`signal`), et sa suite `test-check-workstream-pointer.sh` : un cas par état sur fixture `mktemp -d`, ensemble des codes observés comparé à l'ensemble attendu par `comm`, MUT sur FIXTURE (preuve d'effectivité par `cmp -s` avant/après) et MUT sur SCRIPT (awk sur une copie, `cmp -s` ≠ script, `bash -n` OK, rouge sur le mutant, vert sur l'original).
**When to use:** `check-role-consistency.sh` et `vf-role.sh`.
```bash
# Source: plugin/conductor/scripts/tests/test-check-workstream-pointer.sh:314-331 (verbatim, extraits)
MUTANT="$MUTD/check-workstream-pointer.mut.sh"
awk -f "$MUTD/neutralise-dossier-absent.awk" "$SCRIPT" > "$MUTANT"
...
if cmp -s "$MUTANT" "$SCRIPT"; then
  ko "MUT-2 …" "la mutation n'a RIEN change (motif introuvable) — mutant NON OPPOSABLE, pas mutant satisfait"
elif ! bash -n "$MUTANT" 2>/dev/null; then
  ko "MUT-2 …" "le mutant n'est pas un script valide : il rougirait pour la mauvaise raison"
```
Chaque `ko` affiche attendu/obtenu (`rc_mutant=… (devait différer de 1) rc_restaure=… (attendu 1)`) : c'est la « trace attendu/obtenu » demandée.

### Anti-Patterns to Avoid
- **Écrire `role=…` dans `.vibeflow-installed`** : `update --all` lirait la ligne comme un module [VERIFIED: vibeflow-update.sh:3265-3266 `while IFS='=' read -r mod ver; do [ -n "$mod" ] && update_module "$mod"`], et `vf_registry_state` classerait le registre invalide.
- **Résoudre la racine du lab par comptage de `../`** depuis `$0` : un script source (`plugin/conductor/scripts/`) et sa copie installée (`.claude/scripts/`) n'ont pas la même profondeur (mémoire « Racine jamais par comptage de ../ » : gate passé NON-VÉRIFIABLE en silence après la partition). Prendre `--path`, sinon `CLAUDE_PROJECT_DIR`, sinon `git rev-parse --show-toplevel`, sinon `.` [ASSUMED: ordre de précédence recommandé].
- **Modifier la signature de `gitignore_add_paths()`** ou son corps (PR #136/#146/#147 de Willy). Preuve à produire : extraire la fonction par awk à `a2ed5094` et à HEAD, `cmp -s`.
- **Éditer `ci.yml`** : toute modification de `.github/` exige la revue `@picmakpro` [VERIFIED: `.github/CODEOWNERS` : `/.github/ @picmakpro`] et un trailer G-2. Les suites neuves sont découvertes sans toucher `ci.yml` [VERIFIED: ci.yml:218 `suites=$(find plugin scripts -type f -path '*/tests/test-*.sh' | sort)`].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lire `roles` / `vf_roles` | `grep`/`sed` sur du JSON | `jqx` (module-roles.sh) ; `vf_python` + `json.load` (gate) | JSON valide mais formaté autrement ; « liste illisible » doit être détectable ; `module_is_mandatory` (grep, l.2182-2187) est tolérable pour un booléen, pas pour un tableau validé |
| Ajouter une ligne à `.gitignore` | `echo >>` | `gitignore_add_one` | idempotent, crée le fichier, déclare au plan |
| Annoncer une écriture au plan | `printf '[plan]…'` | `vf_declare_write` | TD1/T57i comparent plan et pose réelle |
| Écriture atomique du fichier de poste | `>` direct | tmp + `mv -f` (patron `write_target_marker`, l.1456-1475) | pas de fichier à moitié écrit lu par un hook concurrent |
| Résolution Python | `python3` nu | `vf_resolve_python`/`vf_python` + `vf_guard_unavailable` | piège Windows (stub WindowsApps), contrat ADR-054 |
| Exclusion du manifeste | filtre privé | `vf_manifest_excluded` (point UNIQUE, l.456-471) | le fichier de poste est engine-owned comme `scripts/.vibeflow-target` |
| Harnais de mutation | autre style | patron `MUT-n` de `test-check-workstream-pointer.sh` | `cmp -s`, `bash -n`, attendu/obtenu, restauration |
| Découpe de l'entrée de hook | commande shell (`bash … \|\| true`) | forme exec `{{VF_BASH}}` + `args` (ADR-071) | zéro expansion shell ; `\|\| true` n'existe plus en exec |

**Key insight:** presque tout le dispositif est déjà dans le dépôt sous forme de précédents *testés* ; le risque de la phase n'est pas d'inventer, c'est de **casser un invariant d'une suite existante** (T57, TD1, T12 de `test-check-hook-paths.sh`, point 9 de `check-version-sync`) en ajoutant un geste inconditionnel.

## Runtime State Inventory

Non applicable : la phase n'est pas un renommage/refactor/migration d'une chaîne existante. Elle introduit un état neuf. Pour mémoire, l'état neuf et son sort :

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `.claude/vibeflow-role` (nouveau, local, non versionné) ; `vf_roles` dans `.planning/config.json` (optionnel, écrit à la main) | Aucun écrivain de `vf_roles` en 58 (silence si absent) ; documenter l'édition manuelle |
| Live service config | Aucun | — |
| OS-registered state | Aucun | — |
| Secrets/env vars | `VF_ROLE` (variable d'environnement, valeur fermée) | Hermétisme des suites : `env -u VF_ROLE` partout où l'on teste « sans poste » |
| Build artifacts | Labs déjà installés : le prochain `update --all` leur pose le nouveau hook (silencieux sans fichier de poste) et les nouveaux scripts conductor | Bump conductor (le hook n'arrive que par `install_module`/`sync_module_governance`) |

## Common Pitfalls

### Pitfall 1 : l'ajout inconditionnel à `.worktreeinclude` ou `.gitignore` casse les suites et le critère 2
**What goes wrong:** `ensure_worktreeinclude_entries` est appelé à la fin de **chaque** `install_module` et `update_module` ; une ligne ajoutée à sa liste apparaît dans tous les labs, poste ou non.
**Why it happens:** T57c exige un fichier de **exactement 4 lignes** [VERIFIED: test-vibeflow-update.sh:2507 `[ "$(awk 'END { print NR }' "$LAB/.worktreeinclude")" -eq 4 ] || { ko "T57c : le fichier n'a pas exactement 4 lignes`], T57h compare le fichier CRLF octet pour octet [VERIFIED: l.2546 `printf '%s\r\n%s\r\n' ".claude/hooks/" ".claude/scripts/" | cmp -s - "$LAB/.worktreeinclude"`]. Idem pour une règle `.gitignore` en scope `project` : aujourd'hui aucun `.gitignore` n'est créé (mesuré : un lab project fraîchement installé ne contient que `.claude/ .git/ docs/ .worktreeinclude`).
**How to avoid:** conditionner les trois gestes (fichier, ignore, worktreeinclude) à « un poste est posé » (drapeau de run ∨ fichier existant). C'est compatible avec la lettre du CONTEXT (« l'engine pose la règle … dans tous les scopes » = tous les scopes *où un poste est posé*). Voir « Défauts du CONTEXT » n°2.
**Warning signs:** T57a-T57j rougissent ; `.gitignore` apparaît dans une install sans `VF_ROLE`.

### Pitfall 2 : une garde qui lit le disque est fausse en `--dry-run`
**What goes wrong:** `[ -f ./.claude/vibeflow-role ]` est faux en dry-run sur lab neuf ; le plan omet la ligne `.worktreeinclude`, la pose réelle l'ajoute ; TD1/T57i rougissent.
**How to avoid:** drapeau de run (`VF_ROLE_WILL_EXIST`) mis à 1 par la fonction de pose, réel ou dry-run, comme `VF_SETTINGS_JSON_WILL_EXIST` (l.365, F-01).

### Pitfall 3 : critère 2 comparé à la mauvaise référence
**What goes wrong:** « arbre posé identique à une install de référence » rougit pour de bonnes raisons si la référence est l'ancien dépôt entier, et pour de mauvaises si on ne normalise pas.
**Mesuré** (deux installs `install --all` identiques, labs distincts, même HOME-modèle) : listes de fichiers identiques (470 hors `.backups`), mais 3 fichiers diffèrent — `.claude/agents/dev-orchestrator-references/gsd-skills-index.md` (ligne 2 : horodatage « Généré le … »), `.claude/logs/archive.log` (horodatages), `.claude/scripts/.vibeflow-target` (chemin absolu du lab) — et `.claude/.backups/settings-<AAAAMMJJ-HHMMSS>.json` existe en 5 exemplaires dans l'un, 4 dans l'autre (collisions à la seconde). Côté `--dry-run install --all`, la sortie stdout (541 lignes) est identique **sauf** les lignes `[plan] + ./.claude/.backups/settings-…` (10 lignes d'écart).
**How to avoid:** comparer **ancien engine ↔ nouvel engine sur le même cache** (isole le changement d'engine), après exclusion de ces quatre sources et filtrage des lignes `.backups/settings-` ; en sus, un **témoin** (`VF_ROLE=product`) qui doit être jugé différent (une preuve doit pouvoir rendre rouge). La différence modules anciens/nouveaux (nouveaux scripts conductor, entrée de hook, versions) se prouve séparément, par liste attendue (`comm`).

### Pitfall 4 : le repli du skill « presets vides → dev-orchestrator » fuit du dev vers `product`
**What goes wrong:** SKILL.md l.106-107 : « Sans réponse exploitable, ou si la liste des presets est vide, retomber sur le seul module `dev-orchestrator` (entrée `optional` du catalogue) + amorcer ses dépendances de dev ». Les trois presets (`dev`, `dev-mobile`, `dev-audite`) ont tous `dev-orchestrator` pour racine [VERIFIED: presets.json `"modules": ["dev-orchestrator"]`, `["dev-orchestrator", "mobile-test-team"]`, `["dev-orchestrator", "software-architecture", "validator"]`] : pour un poste `product` la liste utile est vide, et le repli installerait du dev.
**How to avoid:** réécrire ce paragraphe avec l'étape poste : le repli ne vaut que si `dev-orchestrator` figure au catalogue **filtré**, et `ensure-deps.sh` (SKILL l.132-133, « ou sur demande ») n'est jamais lancé pour `product`. Recommandation de code (hors CONTEXT, voir Open Question 1) : rendre `resolve-preset.sh list` sensible au poste.

### Pitfall 5 : le frontmatter du SKILL.md installeur est dans le ratchet de bootstrap
**What goes wrong:** `plugin.json` déclare `"skills": "./installer"` [VERIFIED: plugin/.claude-plugin/plugin.json:20] ; le socle mesuré par `check-instruction-budget.sh` (BOOTSTRAP) inclut les lignes `name`/`description`/`when_to_use` de ce SKILL.md ; la baseline est `@bootstrap:socle	0	2610` [VERIFIED: .planning/instruction-budget-baselines.tsv:28] et la mesure du jour est `BOOTSTRAP : 2610 tokens estimés … verdict AU-DESSUS-PLAFOND-ADR029` (hausse = DEPASSEMENT-BOOTSTRAP, et G-1 exige une citation d'arbitrage).
**How to avoid:** ne modifier que le **corps** du SKILL.md (189 lignes, plafond 500 [VERIFIED: sortie du gate `plugin/installer/SKILL.md | 189 | 500 | OK`]). Aucun agent n'est touché : pas de ratchet d'instructions.

### Pitfall 6 : trois sources de non-déterminisme et un piège de timing dans les suites
`test-vibeflow-update.sh` dure **271 s** [VERIFIED: mesure locale, 93 OK / 0 KO] ; ne jamais le mettre en `<verify>` rapide (alarme ≥ 540 s, de préférence en tâche de fond). Les nouvelles suites doivent être rapides (install baseline = 3 s, `install --all` = 15 s, mesurés) et hermétiques (`env -u VF_ROLE`, `HOME` jetable, `VF_GUARD_HEALTH_DIR` jetable pour ne pas polluer `~/.cache/vibeflow/guard-health`).

### Pitfall 7 : le fichier de poste est une entrée non fiable injectée dans le contexte du modèle
Le stdout d'un hook SessionStart est ajouté au contexte du modèle [CITED: code.claude.com/docs/en/hooks]. Imprimer `Poste : $(cat fichier)` ferait entrer du texte arbitraire (injection d'instructions) dans la session. **Imprimer uniquement la valeur validée** parmi `solo|product|dev`, jamais le contenu brut ; en erreur d'analyse, un message fixe sur stderr (le contenu fautif tronqué et assaini si on le cite).

### Pitfall 8 : conflits textuels avec les PR de Willy plus larges que le CONTEXT ne l'indique
La PR #136 modifie aussi `plugin/_internal/tests/test-vibeflow-update.sh` (suite T3d, en-tête), `docs/HOOKS-CONTRAT-SORTIE.md` (inventaire 33→37, numéros n°32-37 pris par `planning-core`), `README.md`/`README.fr.md` (ligne « 109 suites » sur sa branche, 102 sur main) [VERIFIED: `gh pr diff 136` + `gh pr view 136 --json files`]. La PR #146 touche `.planning/…/gouvernance/**` seulement ; la #147 aussi. Les branches `gouvernance/phase-46*` portent les commits `3027b186` et `2f3e5b3c` [VERIFIED: `git branch -r --contains`].
**How to avoid:** nouvelles suites en fichiers neufs ; numéro de l'entrée d'inventaire du hook attribué **au moment du rebase** (le recompte `assert n==NN` se refait sur la base mergée) ; « N suites » des READMEs recalculé par `find plugin scripts -path '*/tests/test-*.sh'` après rebase.

### Pitfall 9 : contraintes d'exécution de ce poste (item 7 du brief)
Confirmées ou mesurées : pas de `timeout`/`gtimeout` (utiliser `perl -e 'alarm N; exec @ARGV'`, vérifié) ; `grep` est réécrit par le hook rtk en `rtk grep` (mesuré : `grep -c` et `grep -h` échouent avec l'aide de `rtk grep`, et les sorties de `grep -n` sont tronquées en « N matches in 1F ») → `awk`, `command grep` dans une suite lancée par `bash`, ou `rtk proxy grep` ; `diff` proxifié → `cmp -s`/`comm` ; zsh : pas de découpage de mots sur `$var` (`for x in $var` itère une fois) → `while IFS= read -r` ou tableaux ; pas de `case` inline dans les commandes de `<verify>`. Lab neuf : `HOME=$(mktemp -d)` avec `PYTHONUSERBASE` sauvegardé *avant* de changer `HOME` (`python3 -m site --user-base` rend `/Users/<user>/Library/Python/3.14` ici). `VF_RUNTIME=claude` explicite (les suites existantes le posent). Un lab doit être `git init -q`, sinon l'engine écrit `.planning/config.json` (`workflow.use_worktrees=false`) et l'arbre diffère.

### Pitfall 10 : numéros de ligne du CONTEXT
Ils sont exacts à ±2 (ex. `gitignore_add_paths` : corps à 1157-1240 ; `ensure_worktreeinclude_entries` : fonction à 1829, commentaire d'en-tête dès 1815). Citer par **nom de fonction** dans les plans.

## Code Examples

### 1. Prédicat/validateur `roles` (prototype exécuté sur jq 1.7.1)
```bash
# Source: prototype de cette recherche, vérifié sur 8 manifestes × 3 postes (aucune sortie inattendue)
# def roles_verdict($r) :
#   absent                      -> "yes"        (absent = tous)
#   non-tableau | [] | valeur ∉ {product,dev} | null | "solo" dans la liste -> "invalid"
#   $r == "solo"                -> "yes"        (sur-ensemble implicite)
#   $r ∈ liste                  -> "yes" sinon "no"
jq -r --arg r "$POSTE" 'def roles_verdict($r):
  if has("roles")|not then "yes"
  elif (.roles|type)!="array" or (.roles|length)==0 or (.roles|any(.[]; (.=="product" or .=="dev")|not)) then "invalid"
  elif $r=="solo" then "yes"
  elif (.roles|any(.[]; .==$r)) then "yes" else "no" end;
roles_verdict($r)' module.json
# Résultats mesurés : {"roles":["dev"]} product -> no ; dev -> yes ; solo -> yes ;
#   {"roles":[]} / ["qa"] / "dev" / ["solo"] / null -> invalid pour les trois postes
```
Piège de forme à éviter : `contains([$r])` (sous-chaîne sur des chaînes), `.proposable // true` (l'opérateur `//` traite `false` comme vide — même piège que documenté dans `build-module-catalog.sh`).

### 2. Entrée de hook SessionStart en forme exec
```json
// Source: plugin/conductor/hooks/hooks.json:27 (entrée voisine, verbatim) — l'entrée neuve en suit la forme
{ "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/check-guard-health.sh", "--hook"] }
// Proposition : { "type": "command", "command": "{{VF_BASH}}", "args": ["{{VF_SCRIPTS}}/check-role-consistency.sh", "--hook"] }
```
Placement : un groupe **propre** (un seul script par groupe, comme `guard-fin-de-geste.sh`, hooks.json:30-34), pas dans le groupe `"matcher": "startup"` (l.20). Raison : SessionStart se déclenche pour `startup`, `resume`, `clear`, `compact` (et `fork`) [CITED: code.claude.com/docs/en/hooks] ; un groupe sans matcher réinjecte la ligne « Poste : X » après un `/clear` ou un compactage [ASSUMED: « sans matcher = toutes les sources »]. À trancher (Open Question 4). `merge-hooks.sh` purge toute entrée référençant le même script dans tous les groupes de l'événement : un script unique par entrée évite la collision.

### 3. Comparateur du critère 2 (recette mesurée)
```bash
# Proposition, composants vérifiés isolément (voir Pitfall 3)
# A = ancien engine (git archive a2ed5094 plugin/_internal -> $REF/_internal), B = nouvel engine ; même cache de modules
norm_tree() { ( cd "$1" && find . -path ./.git -prune -o -type f -print \
  | awk '$0 !~ /^\.\/\.claude\/\.backups\// && $0 != "./.claude/logs/archive.log" && $0 != "./.claude/scripts/.vibeflow-target"' \
  | LC_ALL=C sort ); }
# contenus : cmp -s fichier par fichier ; pour gsd-skills-index.md, comparer sans la ligne « Généré le »
# plan : sortie de `--dry-run install --all` filtrée avec awk '$0 !~ /\.backups\/settings-/' puis cmp -s
# témoin : VF_ROLE=product doit rendre la comparaison NON identique (sinon le comparateur est aveugle)
```

### 4. Mutant du gate (patron de la suite voisine)
```bash
# Source: patron plugin/conductor/scripts/tests/test-check-workstream-pointer.sh:305-332 ; cible proposée
# MUT-liste-hors : neutraliser la branche « poste hors liste » du gate -> le cas 1 doit rougir (rc != 1), l'original reste vert
# MUT-silence    : faire sortir 0 au lieu de 3 quand le fichier de poste est absent -> le cas 3 doit rougir
# MUT-analyse    : replier l'erreur d'analyse (liste illisible) sur le silence 3 -> le cas « bruyant » doit rougir
# MUT-hook       : retirer la traduction 3->0 sous --hook -> la suite --hook doit rougir
# chaque mutant : awk sur copie, cmp -s != original, bash -n OK, attendu/obtenu imprimés, restauration revérifiée verte
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hooks en forme shell `bash … \|\| true` | Forme exec `{{VF_BASH}}` + `args`, traduction des codes dans le script sous `--hook` | ADR-071 (Phase 30) | Le gate neuf naît en forme exec ; `--hook` traduit le silence (3→0), jamais l'erreur d'analyse |
| `.gitignore` seulement en scope `local` | Idem pour les modules ; **neuf** : fichier de poste ignoré dans tous les scopes où il est posé | Phase 58 (P58-D-01) | Premier cas où l'engine écrit `.gitignore` en scope `project` |
| `D-NN` nus | Identifiants préfixés `P58-D-NN` | ADR-075 (2026-09-24) | Citer les décisions de cette phase avec le préfixe |

**Deprecated/outdated:** la phrase « les bundles métier sont `proposable:false` » (SKILL l.112-114) ; le catalogue contient bien les trois bundles, `proposable:true` [VERIFIED: module.json des trois bundles `"proposable":true`, et test-build-module-catalog.sh l.113-121 les exige présents].

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | tout | ✓ | 3.2.57 (macOS) | — (cible de portabilité) |
| zsh | shell du poste | ✓ | 5.9 | — |
| jq | module-roles.sh, catalogue | ✓ | 1.7.1-apple | — (prérequis dur du préflight) |
| python3 | gate (`vf_python`) | ✓ | 3.14.6 | `vf_guard_unavailable` (exit 17, bruyant) |
| node | `ensure-deps.sh` seulement | ✓ | v26.5.0 | **non requis** : le moteur d'install n'appelle jamais `ensure-deps.sh` [VERIFIED: aucune occurrence exécutable dans vibeflow-update.sh, seules des mentions de commentaire l.135, 137, 1419] ; le skill ne le lance que si `dev-orchestrator` est posé (SKILL l.132-133) |
| gsd-core | dev-orchestrator (`build-gsd-index.sh`, best-effort) | ✓ 1.16.0 [VERIFIED: `~/.claude/gsd-core/VERSION`] | — | en lab `product`, dev-orchestrator absent : rien à indexer ; en HOME jetable l'index dit « (version inconnue) » sans échec (mesuré, install rc=0) |
| perl | garde de temps | ✓ | /usr/bin/perl | — |
| `timeout` | — | ✗ | — | `perl -e 'alarm N; exec @ARGV'` |
| gh | lecture des PR de Willy | ✓ | — | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `timeout` (perl).

## Validation Architecture

`workflow.nyquist_validation` est `true` dans `.planning/config.json` [VERIFIED: ligne `"nyquist_validation": true`] → section requise.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash maison (`ok()`/`ko()`, compteurs, `exit` ≠ 0 si un KO), mutants par awk sur copie de script |
| Config file | aucun ; découverte CI : `find plugin scripts -type f -path '*/tests/test-*.sh'` (ci.yml:218) |
| Quick run command | `bash <suite neuve du plan>` (chacune < 30 s ; install baseline 3 s, `install --all` 15 s mesurés) |
| Full suite command | `bash .planning/milestones/fiabilite-v1.0-phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job tests` puis `--job gates` |

Baselines mesurées avant toute modification (toutes vertes) : `test-build-module-catalog.sh` 14 OK ; `test-resolve-deps.sh` 5 OK ; `test-resolve-preset.sh` 15 OK ; `test-manifest.sh` 62 OK (18 s) ; `test-check-hook-paths.sh` 17 OK (1 s) ; `test-check-instruction-budget.sh` 69 OK (5 s) ; `test-vibeflow-update.sh` 93 OK / 0 KO (271 s) ; `check-version-sync.sh` ✓ (v2.70.0, 17 modules, 102 suites).

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | Échec attendu (mutant/témoin) | File Exists? |
|--------|----------|-----------|-------------------|-------------------------------|-------------|
| RLPO-01 | `VF_ROLE=product` en scope project et local pose `.claude/vibeflow-role` (`product\n`), `.gitignore` +1 ligne exacte, `.worktreeinclude` +1 ligne ; sans `VF_ROLE` : aucun des trois, `.worktreeinclude` identique (`cmp`) à l'ancien engine ; `--dry-run` plan == pose | integration | `bash plugin/_internal/tests/test-vibeflow-update-role.sh` | mutant : appel de la règle d'ignorance neutralisé → `grep -cxF` = 0 ; mutant : conditionnel retiré → T57c-like rouge ; témoin | ❌ Wave 0 |
| RLPO-01 (non touché) | `gitignore_add_paths()` inchangée | static | extraction awk de la fonction à `a2ed5094` (`git show`) et à HEAD, `cmp -s` (dans `test-roles-e2e.sh`) | une modification d'une ligne de la fonction → rouge | ❌ Wave 0 |
| RLPO-02 | `vf-role.sh get` : env > fichier > `solo` ; valeur hors `solo|product|dev`, symlink, multi-ligne, illisible → code d'erreur ≠ 0 distinct, stderr, **stdout vide** ; CRLF/BOM tolérés ; stdout = exactement 1 ligne | unit | `bash plugin/conductor/scripts/tests/test-vf-role.sh` | mutants : priorité env/fichier inversée ; invalide → repli `solo` ; absent → sortie vide | ❌ Wave 0 |
| RLPO-03 | liste absente → gate 3 (silence) ; liste présente ; `config.json` octet-identique après toute install (aucun écrivain) ; clé inconnue de gsd-core tolérée (avertissement stderr documenté) | unit + integration | `bash plugin/conductor/scripts/tests/test-check-role-consistency.sh` ; `cmp -s` config avant/après dans `test-vibeflow-update-role.sh` | mutant : lecture de la mauvaise clé (`vf_role`) → cas « dans la liste » rouge | ❌ Wave 0 |
| RLPO-04 | validateur : absent OK ; `[]`, `["qa"]`, `"dev"`, `null`, `["solo"]` refusés **bruyamment** (rc ≠ 0, nom du module cité) ; réel : exactement 3 modules `["dev"]` (dev-orchestrator, mobile-test, mobile-test-team), aucune autre clé `roles` | unit | `bash plugin/_internal/tests/test-module-roles.sh` | mutant : `length==0` retiré → `[]` accepté → rouge ; mutant : `any(...)` retiré → `["qa"]` accepté | ❌ Wave 0 |
| RLPO-05 | `build-module-catalog.sh` sans poste : sortie `cmp`-identique à l'ancien script (fixture ET repo réel) ; `--role solo` == sans poste ; `--role product` == sans poste moins les 3 lignes dev (`comm`) ; `--role` l'emporte sur `VF_ROLE` ; `roles` invalide + `--role` → erreur ; invariant : fermeture de chaque module `product` sans module `["dev"]` | integration | `bash plugin/installer/scripts/tests/test-build-module-catalog-role.sh` **et** `bash plugin/installer/scripts/tests/test-build-module-catalog.sh` (14 OK inchangés) | témoin : fixture module `product` qui `requires` un module `["dev"]` → l'invariant doit rougir ; mutant : filtre inversé | ❌ Wave 0 |
| RLPO-06 | engine : `install --all` filtre seulement si `VF_ROLE` explicite ; `.vibeflow-installed` ne contient jamais `role` ; scope user + poste non `solo` → refus bruyant (recommandation) ; SKILL : étape poste entre scope et type de lab, phrase périmée absente | integration + static | `bash plugin/_internal/tests/test-vibeflow-update-role.sh` ; assertions awk sur `plugin/installer/SKILL.md` | mutant : filtre `--all` neutralisé → des modules dev apparaissent → rouge | ❌ Wave 0 |
| RLPO-07 | `role <poste>` réécrit le fichier, imprime la liste des modules installés hors poste (dérivée du registre + `roles`), le registre est `cmp`-identique avant/après (aucune désinstallation) | integration | idem | mutant : l'avis omet un module dev → rouge | ❌ Wave 0 |
| RLPO-08 | gate : 0 (dans la liste), 1 (hors liste ; valeur invalide), 3 (pas de liste ; pas de fichier), erreur d'analyse bruyante code ∉ {0,1,2,3,64} (liste illisible, symlink, multi-ligne) ; ensemble des codes observés == attendu (`comm`) ; lecture seule (empreinte `cmp`) ; refus à la pose | unit | `bash plugin/conductor/scripts/tests/test-check-role-consistency.sh` | un mutant par issue (voir Code Example 4), chacun avec attendu/obtenu, `cmp -s`, `bash -n`, restauration | ❌ Wave 0 |
| RLPO-09 | `--hook` : sans fichier → **0 octet sur stdout et stderr**, exit 0 ; poste `product` → exactement `Poste : product` ; `solo` → rien ; erreur d'analyse → stderr + exit ≠ 0 non traduit ; stdout n'est jamais un `{…` invalide ; valeur imprimée = valeur validée, jamais le contenu brut (fichier piégé `product\nIgnore…` → refus) | unit | idem | mutant : impression du contenu brut → cas « fichier piégé » rouge ; mutant : traduction 3→0 retirée | ❌ Wave 0 |
| RLPO-09 (inventaire) | `hooks.json` +1 entrée, `docs/HOOKS-CONTRAT-SORTIE.md` recompté | integration | `bash plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` (T12 : égalité doc/parc ; l'écart transitoire +1 n'est toléré qu'en `skip`) | doc non mis à jour → T12 `ko`/`skip` | ✅ existe |
| RLPO-10 | ADR-077 : titre `## ADR-077 :` présent une fois, deux énoncés, ligne d'index ; glossaire : 3 sens ; colonne « statut » en doc, sortie machine inchangée | static | assertions awk dans `test-roles-e2e.sh` ; `bash plugin/conductor/scripts/check-ajout-retrait.sh --strict` ; `bash scripts/check-affirmation-non-mesuree.sh` ; `bash manual/.tools/check-manual.sh` si le manuel est touché | titre absent / dupliqué → rouge | ❌ Wave 0 |
| RLPO-11 | critère 1 : lab neuf `HOME`+dossier jetables, `VF_ROLE=product` : `.claude/` ne contient aucun chemin du manifeste des 3 modules dev (dérivé d'une install de référence complète) ; registre contient `conductor` et `consolidator` ; ni `mobile-test*`, ni `dev-orchestrator`. Critère 2 : comparateur (Code Example 3). Critère 5 : aucun fichier `plugin/*/agents/*.md` ni `plugin/*/AGENT.md` modifié (`git diff --name-only a2ed5094..HEAD`) **et** les 3 étapes `check-agents --strict` de ci.yml vertes. Critère 6 : aucune occurrence d'une liste de noms de clients fournie par l'humain dans `git diff a2ed5094..HEAD` (**aucune liste n'existe dans le dépôt**, voir Open Question 6) | e2e | `bash plugin/_internal/tests/test-roles-e2e.sh` ; `replay-ci-jobs.sh --job gates --step "check-agents"` | témoin : `VF_ROLE=product` vs sans poste doit être *différent* ; lab product contenant un artefact dev → rouge | ❌ Wave 0 |
| RLPO-12 | `check-version-sync.sh` vert ; `plugin/planning-core/module.json` non modifié ; chaque module bumpé : `VERSION` = `module.json` = en-tête `**Version**` du README + entrée CHANGELOG | static | `bash scripts/check-version-sync.sh` ; `git diff --name-only a2ed5094..HEAD` ne contient pas `plugin/planning-core/module.json` | VERSION ≠ module.json → point 6 rouge ; « N suites » faux → point 9 rouge | ✅ existe (gate) |

### Sampling Rate
- **Per task commit:** la suite neuve du plan (`bash <suite>`), < 30 s.
- **Per wave merge:** toutes les suites neuves + `test-build-module-catalog.sh` (14), `test-resolve-deps.sh` (5), `test-resolve-preset.sh` (15), `test-manifest.sh` (62, 18 s), `test-check-hook-paths.sh` (17, T12), `test-vf-portable.sh`, `scripts/check-version-sync.sh`, `plugin/conductor/scripts/check-instruction-budget.sh` (doit rester à 2610).
- **Phase gate:** `replay-ci-jobs.sh --job tests`, `--job gates`, plus `test-vibeflow-update.sh` en tâche de fond (271 s), plus les deux jobs de lab frais rejoués à la main (`lab-frais` : baseline `mandatory` ; ils ne sont **pas** couverts par l'outil de rejeu) avant `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `plugin/_internal/tests/test-module-roles.sh` — RLPO-04 (+ invariant de fermeture RLPO-05)
- [ ] `plugin/conductor/scripts/tests/test-vf-role.sh` — RLPO-02
- [ ] `plugin/conductor/scripts/tests/test-check-role-consistency.sh` — RLPO-03, 08, 09
- [ ] `plugin/installer/scripts/tests/test-build-module-catalog-role.sh` — RLPO-05
- [ ] `plugin/_internal/tests/test-vibeflow-update-role.sh` — RLPO-01, 06, 07
- [ ] `plugin/_internal/tests/test-roles-e2e.sh` — RLPO-10, 11, 12
- [ ] Framework install : aucun.
- Conséquence mécanique : **+6 suites** → « 102 suites » des deux READMEs racine à recalculer (point 9 de `check-version-sync.sh`, ligne 134 : `suites_real="$(find "$ROOT/plugin" "$ROOT/scripts" -path '*/tests/test-*.sh' …`).

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1`, `security_block_on: "high"` [VERIFIED: `.planning/config.json`].

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non | — |
| V3 Session Management | non | — |
| V4 Access Control | **explicitement non** | « un poste est une vue, pas un droit » : aucune promesse de cloisonnement ; à écrire dans ADR-077, l'avis de changement de poste, le SKILL et le glossaire |
| V5 Input Validation | oui | valeur de poste = ensemble fermé `solo|product|dev` (`case`), `roles` validé par jq (ensemble fermé, tableau non vide), `vf_roles` validé ; jamais `eval`, jamais dans un chemin/une commande avant validation |
| V6 Cryptography | non | — |
| V7 Error Handling & Logging | oui | erreur d'analyse bruyante sur code distinct, jamais un repli silencieux ; marqueur de santé via `vf_guard_unavailable` si Python manque |
| V12 Files & Resources | oui | fichier de poste : régulier, pas un lien symbolique, taille bornée, une seule ligne ; écriture atomique tmp+`mv` ; entrée `.worktreeinclude` seulement sur un chemin ignoré |
| V14 Configuration | oui | fichier de poste non versionné (règle d'ignorance posée *avant* toute chance de `git add`) ; `vf_roles` seule clé ajoutée à `config.json` (lecture seule) |

### Known Threat Patterns for bash installer + hook

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Injection d'instructions dans le contexte du modèle via le contenu du fichier de poste | Tampering / Elevation | imprimer la valeur validée uniquement (Pitfall 7) |
| Lien symbolique `.claude/vibeflow-role` → fichier sensible lu par le hook | Information disclosure | refus du lien symbolique (précédent : lecture « SANS RISQUE » de `check-workstream-pointer.sh`), borne d'octets |
| `VF_ROLE` hostile (`; rm -rf`, `../x`) | Tampering | validation par `case` fermé avant tout usage, message fixe |
| Fixation de `VF_ROLE` dans l'environnement du shell qui contamine des flux sans rapport (`vf-calibrate`/`verify-runtime-reversibility.sh` appellent `install --all --target …`) | Tampering (non intentionnel) | comportement explicite sous `--target` et en scope user (Open Question 3) ; suites hermétiques `env -u VF_ROLE` |
| Poste non versionné interprété comme droit d'accès | Spoofing (faux sentiment de sécurité) | formulation « vue, pas un droit » partout ; aucune décision de sécurité ne lit le poste |
| Course sur le fichier lu par un hook pendant la réécriture | Tampering | écriture tmp+`mv -f` |

## Project Constraints (from CLAUDE.md)

Extraites de `CLAUDE.md (racine du dépôt)` (lu cette session) et de la mémoire projet ; même autorité que les décisions verrouillées.
- **Commits en français**, cohérents avec l'historique ; un commit qui invoque une décision nomme **canal et date** (« arbitrage Samuel, AskUserQuestion session principale, 2026-10-16 ») ; identifiants **préfixés** (`P58-D-NN`, ADR-075).
- **Trailer `Gate-Touche: <chemin-ou-motif> — <raison ≥ 10 car.>`** sur tout commit de la branche qui touche un gate, sa suite, une fixture surveillée, `ci.yml` ou un hook. Surface exacte (G-2) : `plugin/conductor/scripts/check-*.sh`, `plugin/conductor/scripts/tests/test-*.sh`, `scripts/check-*.sh`, `scripts/tests/test-*.sh`, `.github/workflows/ci.yml`, `scripts/hooks/**`, fixtures de ces suites [VERIFIED: scripts/check-gate-touche.sh, six classes]. Donc : `check-role-consistency.sh`, `test-check-role-consistency.sh`, `test-vf-role.sh` (même dossier de suites) → un trailer chacun ; `hooks.json` de plugin n'est **pas** dans la surface G-2. Le motif ne contient jamais de virgule.
- **Trailer `Ajout-Retrait: <chemin|ADR-NNN> — <retrait | aucun : justification ≥ 10 car.> — défaillance : <date ISO ou SHA>`** pour tout ajout surveillé : `plugin/conductor/scripts/check-role-consistency.sh` (fichier `check-*.sh`, statut A) et `ADR-077` (titre ajouté dans `docs/ADR.md`) [VERIFIED: en-tête de check-ajout-retrait.sh]. Consultatif.
- **ADR-029** : agents ≤ 250 lignes (alerte dès 251, blocage > 300) ; skills ≤ 500 ; bootstrap ≤ 2000 tokens (ratchet à 2610). Aucun agent n'est créé ni modifié en 58.
- **Jamais de fix sans validation humaine (ADR-031)** : les gardes de poste constatent, ne corrigent ni ne bloquent.
- **Forme exec des hooks (ADR-071)** ; agents natifs machine-enforced (ADR-044) sans objet ici.
- **Discipline de release** : aucune release dans la phase (bump de `VERSION` racine, tag, release GitHub = geste humain hors phase) ; ne pas toucher `VERSION`, `plugin.json`, `marketplace.json` racine. ADR-073 : une PR purement doc ne se release pas ; celle-ci est fonctionnelle, la release reste hors phase.
- **Verrou de dépôt court** (`driver-lock.sh acquire --depot --owner=<id> --step=<étape>` / `release`) pour écrire `docs/ADR.md` ; tenu par le **manager**, relâché dès le geste fait (TTL 1 800 s) ; jamais par un worker. Vérifier `driver-lock.sh status` avant tout geste d'arbre principal.
- **Gardes in-repo** : G-1 (hausse de baseline sans citation → rouge), G-2, G-3, G-4 (ne pas affirmer au présent une protection serveur non mesurée dans `CLAUDE.md`/`docs/ADR.md`/README/manual).
- **Public** : aucun nom de client dans fixtures, exemples ou commits (spec §6) ; `check-machine-paths.sh` bloque tout chemin absolu de machine dans les fichiers versionnés (échappatoire `vf-allow-machine-path`).
- **Mémoire** : ne pas utiliser `gsd-tools state …` (`record-session` et `planned-phase` sont destructifs : ledger à la main) ; `AskUserQuestion` est absent des sous-agents (escalade `SendMessage(main)`) ; « aucun vert auto-déclaré ne tient » (une preuve doit pouvoir rendre rouge) ; ship toujours gaté humain.
- **Interdits de cette tâche de recherche** : pas de commit, `git stash/checkout/switch/reset`, `git add -A`, `gsd-tools state`. Respectés.

## Défauts du CONTEXT

Signalés, **non corrigés**. Chacun est une lecture littérale qui échoue ou une ambiguïté à trancher par le planificateur ou l'humain.

1. **D-09 issue 3 « silence » ↔ D-10 « Poste : X hors solo ».** Avec un fichier `product` et *sans* liste `vf_roles`, D-09 dit silence (3), D-10 dit injecter « Poste : product ». Les deux ne tiennent que si la ligne de contexte est émise *indépendamment du verdict de cohérence*, sous `--hook` seulement, et que « silence » désigne l'absence de constat (le code CLI reste 3). **Recommandation :** sous `--hook`, imprimer la ligne dès que le lecteur rend un poste ≠ `solo` (hors erreur d'analyse) ; le code 3 reste le code CLI de « aucune liste ou aucun fichier ». Le critère 2 tient (aucun fichier de poste → 0 octet).
2. **D-01 « règle d'ignorance dans tous les scopes » et D-16 « ajouté à la liste de `ensure_worktreeinclude_entries` », lus inconditionnellement,** cassent T57c, T57h et le critère 2 (Pitfall 1). Lecture compatible : conditionnel à un poste posé (drapeau de run ∨ fichier présent).
3. **D-12 « colonne renommée statut dans la doc seulement »** : le nom `role` désigne cette colonne dans le **code** du catalogue (variable `role="optional"`, commentaires l.5-8 et 42), dans SKILL.md (l.89-90, 178) et dans un commentaire de `ci.yml` (l.1941, à ne PAS modifier : G-2 + revue @picmakpro). L'ajout de `--role` impose de renommer la variable interne (aucun effet sur la sortie). Le mot « rôle » a en plus un 4ᵉ sens : `driver-lock.sh register --role=<role>` (rôle d'un agent dispatché). Le glossaire doit en citer au moins trois (poste, rôle d'agent, statut) et peut mentionner le registre du verrou.
4. **D-02 « jamais lue par gsd-core »** : exact en lecture, mais gsd-core 1.16.0 écrit sur stderr `gsd-tools: warning: unknown config key(s) in .planning/config.json: … — these will be ignored` à chaque processus pour toute clé racine inconnue [VERIFIED: `~/.claude/gsd-core/bin/lib/config-loader.cjs:807-813`, l'ensemble connu étant construit l.780-785]. Précédent identique : `vf_runtimes`. Coût à documenter (bruit sur les labs qui posent `vf_roles`), pas un blocage.
5. **D-13 « aucune de ses branches ne touche … »** liste des fichiers que la 58 modifie *et* que la PR #136 modifie (`vibeflow-update.sh` — fonction `gitignore_add_paths` seulement —, `test-vibeflow-update.sh`, `docs/HOOKS-CONTRAT-SORTIE.md`, `README.md`, `README.fr.md`) : surface de conflit plus large que celle énumérée (Pitfall 8). Pas de contradiction avec la décision ; à connaître du planificateur.
6. **D-18 / SKILL.md l.106-107 et l.132-133** : le repli « presets vides → dev-orchestrator » et « ensure-deps … ou sur demande » contredisent le critère 1 pour `product` ; le CONTEXT réécrit la section mais ne mentionne pas ce repli (Pitfall 4).
7. **D-19 critère 2 « arbre posé comparé à une install de référence »** : faux tel quel (Pitfall 3) ; formulation exécutable proposée en Validation Architecture.
8. **D-20 « installer s'il porte une VERSION »** : il n'en porte pas [VERIFIED: `ls plugin/installer` rend `SKILL.md scripts` ; ni `VERSION` ni `module.json`] → rien à bumper pour l'installeur.
9. **D-03 / D-09 `solo` dans `vf_roles`** non tranché : `solo` est interdit dans `roles` de `module.json`, mais rien ne dit si une liste `vf_roles` peut ou doit contenir `solo`, ni si `solo` est implicitement autorisé. Lecture littérale de D-09 : `solo` doit figurer dans la liste pour être « présent ». Voir Open Question 5.
10. **Bruit préexistant (pas un défaut de la 58)** : l'index de `docs/ADR.md` n'a pas de ligne pour ADR-075 (lignes 072, 073, 074, 076 présentes) [VERIFIED: grep des lignes `| ADR-07x` du tableau d'index]. L'ajout de la ligne ADR-077 ne doit pas « réparer » 075 sans décision (SOBR : ajout/retrait).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Un groupe `SessionStart` sans `matcher` se déclenche pour toutes les sources (`startup`, `resume`, `clear`, `compact`, `fork`) ; les valeurs de matcher sont [CITED], « sans matcher = toutes » est [ASSUMED] (le dépôt l'utilise : hooks.json entrée #30) | Code Example 2 | La ligne « Poste : X » ne serait pas réinjectée après `/clear` ; remonter la ligne dans le groupe `startup` |
| A2 | Un hook qui sort avec un code non nul différent de 2 est un échec non bloquant visible (stderr montré) | Gate / Pitfall 7 | L'erreur d'analyse serait silencieuse côté UI ; HOOKS-CONTRAT §1 dit « non nul = n'a pas pu faire son travail », l'affichage exact n'a pas été vérifié |
| A3 | Code d'erreur d'analyse = 4 (valeur libre ∉ {0,1,2,3,64}) | Gate | 4 est « INDÉTERMINÉ, traduit vers 0 sous `--hook` » dans `check-branch-claim.sh`/`check-mission-exit.sh` ; confusion de lecture. Alternative : 5. Le gate neuf ne le traduit jamais |
| A4 | Comportements d'arête de l'engine : scope user + poste ≠ solo → refus bruyant ; `--target` + `VF_ROLE` → filtre appliqué, fichier/ignore non écrits et journalisé ; `VF_ROLE=solo` sans fichier → no-op, avec fichier → réécrit `solo` | Engine | Choix de conception hors CONTEXT (aucun n'ouvre un arbitrage selon P58-D-15..20) ; Samuel peut préférer un silence |
| A5 | Niveaux de bump : conductor **minor** (comportement neuf), dev-orchestrator/mobile-test/mobile-test-team **patch** (clé de métadonnée seule) | Registres | Convention CLAUDE.md « nouvelle capacité → minor ; correctif → patch » ; un `roles` change pourtant l'installabilité par poste (minor défendable) |
| A6 | `ubuntu-latest` fournit un jq ≥ 1.5 (`any(generator; cond)`, `has`) | Validateur | Le prédicat échouerait en CI ; mesuré seulement sur jq 1.7.1 local |
| A7 | Les modules `reference`, `kpi-analyst`, bundles, etc. sont tous « product-compatibles » sans autre tri | Catalogue | D-06 fige déjà la table minimale ; la question « un product veut-il `software-architecture` ? » est Phase 59 |
| A8 | La ligne de contexte est plain-text (`Poste : X`), pas JSON `additionalContext` | Hook | Le texte brut est accepté [CITED: code.claude.com/docs/en/hooks] ; il ne doit pas commencer par `{` |
| A9 | Ordre de résolution de racine du lecteur : `--path` > `CLAUDE_PROJECT_DIR` > `git rev-parse --show-toplevel` > `.` | Lecteur | En lab racine non-git (Scroll-Off) ou worktree d'agent, une autre racine lirait un poste absent = `solo` en silence (précisément le défaut que D-16 veut éviter) |
| A10 | Un BOM UTF-8 en tête du fichier (PowerShell 5 `Set-Content`) doit être toléré | Lecteur | `test-check-hook-paths.sh` T13 traite le BOM comme cas légitime sous Windows ; sinon « valeur invalide » bruyant (acceptable) |

## Open Questions (RESOLVED)

> Résolutions du planificateur, 2026-10-16 (conséquences de P58-D-15..20, aucune n'ouvre un arbitrage neuf ; registre P58-PL-01..14 dans `58-01-PLAN.md`) :
> Q1 (presets) → **DÉFÉRÉE hors périmètre**, P58-PL-04 : le repli du SKILL est réécrit, `resolve-preset.sh` n'est pas touché ; la question du filtre de presets par poste est remontée au manager (finding). Q2 → P58-PL-06 (l'engine seul écrit le fichier). Q3 → P58-PL-07 (arêtes `--target` et scope `user`). Q4 → P58-PL-08 (groupe propre sans matcher). Q5 → P58-PL-09 (`solo` doit figurer dans `vf_roles`). Q6 → P58-PL-11 (liste fournie à l'exécution, NON-VÉRIFIABLE sans elle). Q7 (manuel FR+EN) → **DÉFÉRÉE hors périmètre**, P58-PL-12 : remontée au manager (finding). Q8 → P58-PL-13 (étape « 2 bis »).

1. **Presets sensibles au poste ?** (hors CONTEXT)
   - Know: les trois presets contiennent `dev-orchestrator` ; pour `product` la liste est vide et SKILL.md retombe sur `dev-orchestrator`.
   - Unclear: faut-il un filtre de poste dans `resolve-preset.sh list` (change `resolve-*.sh`, cité en P58-D-13 comme non touché par Willy, donc sans conflit) ou une simple réécriture de prose ?
   - Recommendation: filtrer `resolve-preset.sh list` par le même prédicat (`module-roles.sh visible` sur la fermeture) — data-driven, testable, ferme le trou par le code et pas seulement par la prose ; sinon, au minimum, réécrire le repli du SKILL et ajouter une assertion de test sur la phrase.
2. **Qui écrit le fichier de poste : engine seul, ou aussi `vf-role.sh set` ?**
   - Recommendation: engine seul (ignore, worktreeinclude, plan dry-run, manifeste déjà là) ; `vf-role.sh` expose `get` ; le nom `vf-role.sh get|set` du CONTEXT reste libre.
3. **Arêtes de l'engine (A4).** `VF_ROLE` exporté dans le shell d'un humain `product` atteint aussi `vf-calibrate` (`install --all --target`) et `verify-runtime-reversibility.sh`. À trancher : refus bruyant en scope user ; sous `--target`, filtre sans pose du fichier.
4. **Groupe du hook.** Groupe propre sans matcher (recommandé, réinjection après `/clear`) ou groupe `startup` (cohérent avec les six gates voisins) ?
5. **`solo` dans `vf_roles` ?** Si le projet liste `["product","dev"]`, un fichier `solo` est « hors liste » (lecture littérale). Un humain seul sur un projet à plusieurs postes déclarés est-il en infraction ? Recommandation : `solo` doit figurer dans la liste pour être accepté (lecture littérale, ADR-031 : le gate constate), valeurs admises de `vf_roles` = `solo|product|dev`, une valeur inconnue = « liste illisible ».
6. **Critère 6 (aucun nom de client).** Aucun gate ni liste de noms n'existe dans le dépôt [VERIFIED: aucun script de `scripts/`, `plugin/conductor/scripts/` ni `.github` ne porte cette liste ; la règle n'est écrite que dans la spec §6]. La preuve exige que l'humain fournisse la liste ; sans elle, la mesure reste un balayage du diff par mots-clés fournis à l'exécution. À signaler au manager avant la vague 4.
7. **Manuel FR+EN.** La phase 57 a mis à jour le manuel (`check-manual`, C1-C6 : isomorphisme FR/EN, pas de `vX.Y.Z` hors bloc de code, ≤ 300 lignes, ≤ 3 H2). Pages candidates : `01-demarrer/choisir-son-scope.md`, `07-sous-le-capot/l-engine-d-install.md`, `07-sous-le-capot/anatomie-d-un-lab-installe.md`, `02-concepts/glossaire.md`. D-05 demande la phrase « un poste est une vue, pas un droit » « partout où le poste est présenté » : à décider si le manuel entre dans la phase (recommandé, un plan court).
8. **Étape poste : « 2bis » ou renumérotation ?** SKILL.md cite ses étapes par numéro (« étapes 0, 1, 3, 4, 5 », table « Chemins réels »). Recommandation : insérer une étape « 2 bis » sans renuméroter.

## Découpage indicatif en plans et vagues (8 plans, 4 vagues)

Aucun fichier n'est commun à deux plans d'une même vague.

| Plan | Vague | Contenu | Fichiers | Dépend de | RLPO |
|------|-------|---------|----------|-----------|------|
| 58-01 | 1 | Validateur/prédicat `roles` + clé `["dev"]` sur 3 modules + invariant de fermeture `product` | `plugin/_internal/module-roles.sh` (neuf), `plugin/_internal/tests/test-module-roles.sh` (neuf), `plugin/dev-orchestrator/module.json`, `plugin/mobile-test/module.json`, `plugin/mobile-test-team/module.json` | — | 04, (05) |
| 58-02 | 1 | Lecteur unique `vf-role.sh get` + suite (priorité, CRLF/BOM, symlink, multi-ligne, mutants) | `plugin/conductor/scripts/vf-role.sh`, `plugin/conductor/scripts/tests/test-vf-role.sh` (neufs) | — | 02 |
| 58-03 | 1 | **ADR-077 sous verrou `--depot` (tâche du manager, jamais d'un worker)** : `acquire --depot --owner=<id> --step=adr-077` → écrire le titre `## ADR-077 : …`, ses deux énoncés, la ligne d'index → `release`. Trailer `Ajout-Retrait: ADR-077 — …`. Format d'ADR : en-tête **Date** · **Statut** · **Décideur** · **Voisines** · arbitrage (canal+date), puis Contexte / Décision / Alternative écartée / Conséquence [VERIFIED: ADR-075/076, docs/ADR.md:3028-3140]. Source de contenu : `.planning/notes/2026-09-16-doctrine-agentique-ouverte-collaboration-humaine.md`. Ne pas affirmer de protection serveur (G-4) | `docs/ADR.md` | — | 10 |
| 58-04 | 2 | Gate `check-role-consistency.sh` (0/1/3 + erreur d'analyse, `--role` candidat, `--hook`) + suite à mutants + entrée de hook exec + inventaire des hooks | `plugin/conductor/scripts/check-role-consistency.sh`, `plugin/conductor/scripts/tests/test-check-role-consistency.sh` (neufs), `plugin/conductor/hooks/hooks.json`, `docs/HOOKS-CONTRAT-SORTIE.md` ; trailers `Gate-Touche:` ×2 et `Ajout-Retrait:` | 58-02 (lecteur) | 03, 08, 09 |
| 58-05 | 2 | Catalogue `--role`/`VF_ROLE` (+ renommage interne de `$role`) ; éventuel filtre de presets (Open Question 1) | `plugin/installer/scripts/build-module-catalog.sh`, `plugin/installer/scripts/tests/test-build-module-catalog-role.sh` (neuf) [+ `plugin/_internal/resolve-preset.sh` et sa suite neuve si retenu] | 58-01 | 05 |
| 58-06 | 3 | Engine : `--role`/`VF_ROLE`, pose du poste (fichier atomique, ignore via `gitignore_add_one`, `.worktreeinclude` conditionnel, exclusion de manifeste, drapeau de run, dry-run déclaré), filtre `install --all`, refus à la pose (appelle le gate), verbe de changement de poste + avis, `config.json` jamais écrit | `plugin/_internal/vibeflow-update.sh`, `plugin/_internal/tests/test-vibeflow-update-role.sh` (neuf) ; **ne pas toucher** `gitignore_add_paths()` | 58-01, 58-02, 58-04 | 01, 03, 06, 07 |
| 58-07 | 4 | Prose installeur (étape 2 bis, repli corrigé, phrase périmée, « statut », `VF_ROLE` dans la table), glossaire `REFERENCE.md`, doc conductor (README : scripts, hook, `vf_roles` à la main), manuel FR+EN si retenu | `plugin/installer/SKILL.md` (corps seul), `docs/_transverse/REFERENCE.md`, `plugin/conductor/README.md`, `manual/**` (option) | 58-05, 58-06 | 06, 10 |
| 58-08 | 4 | Preuves du jalon + livraison : e2e (critères 1, 2, 5, 6), non-modification (`gitignore_add_paths`, `planning-core/module.json`, agents), bumps (conductor minor ; 3 modules dev patch) avec VERSION / module.json / CHANGELOG / en-tête README, « N suites » des deux READMEs, ledger à la main (STATE/ROADMAP/REQUIREMENTS, sans `gsd-tools state`) | `plugin/_internal/tests/test-roles-e2e.sh` (neuf), `plugin/{conductor,dev-orchestrator,mobile-test,mobile-test-team}/{VERSION,module.json,CHANGELOG.md,README.md}`, `README.md`, `README.fr.md`, `.planning/workstreams/fiabilite/{STATE,ROADMAP,REQUIREMENTS}.md` | 58-01…06 | 11, 12 |

Parallélisme : 58-07 et 58-08 sont sur des fichiers disjoints ; 58-08 ne dépend pas de la prose du SKILL (ses assertions statiques sur le SKILL vivent dans la suite de 58-07 ou de 58-06). Si le manuel entre dans le périmètre, il se range dans 58-07.

## Zones de risque (MISSION-INVARIANTS.md)

Les globs gelés qui couvrent cette phase [VERIFIED: `.planning/MISSION-INVARIANTS.md`, § Zones de risque] : `plugin/conductor/scripts/check-*.sh` (le gate neuf), `plugin/*/hooks/hooks.json` (conductor : effet global sur chaque lab), `plugin/_internal/vibeflow-update.sh` (« le layout qu'il pose est sondé par PRÉSENCE DE FICHIER par d'autres modules »), `plugin/_internal/merge-hooks.sh` (non modifié ; défaut d'idempotence cross-matcher **ouvert** : une seule entrée par script). Le manager doit déclarer ces périmètres (`dag.sh add --scope=…`) et lancer `check-mission-invariants.sh` au démarrage.

## Sources

### Primary (HIGH confidence)
- Fichiers du dépôt lus cette session : `58-CONTEXT.md`, `REQUIREMENTS.md` (RLPO-01..12, QUAL-01), `STATE.md`, `ROADMAP.md` §Phase 58, `CLAUDE.md`, spec `2026-09-16-equipe-produit-bmad-design.md` §5.1-5.4, §6, §9, `plugin/_internal/vibeflow-update.sh` (l.1-420, 456-471, 727-855, 1090-1240, 1456-1475, 1478-1512, 1640-1660, 1829-1856, 1880-2260, 2258-2540, 3150-3322), `plugin/installer/SKILL.md`, `build-module-catalog.sh` + sa suite, `resolve-deps.sh`, `resolve-preset.sh`, `presets.json`, les 17 `module.json`, `plugin/conductor/hooks/hooks.json`, `runtime-registry.sh`, `check-workstream-pointer.sh` + suite, `check-gate-touche.sh`, `check-ajout-retrait.sh`, `check-instruction-budget.sh`, `check-planning-consumers-registered.sh`, `vf-portable.sh`, `docs/HOOKS-CONTRAT-SORTIE.md`, `docs/ADR.md` (ADR-075/076), `docs/_transverse/REFERENCE.md`, `.github/workflows/ci.yml` (l.205-333, 1925-2221), `.github/CODEOWNERS`, `.planning/MISSION-INVARIANTS.md`, `scripts/check-version-sync.sh`, `plugin/_internal/tests/test-vibeflow-update.sh` (T1, T10, T57), `test-manifest.sh`, `test-vf-portable.sh` (T12), `test-check-hook-paths.sh` (T12).
- Mesures exécutées (labs jetables sous le scratchpad, `HOME` temporaire) : installs `--all` ×4, `--dry-run install --all` ×2, fermetures `resolve-deps`/`resolve-preset`, baselines de 8 suites, prototype jq sur 8 manifestes × 3 postes.
- `~/.claude/gsd-core/bin/lib/config-loader.cjs:780-815` (gsd-core 1.16.0) — avertissement « unknown config key(s) ».
- [Claude Code — Hooks reference](https://code.claude.com/docs/en/hooks) — valeurs de matcher SessionStart ; stdout plain-text ajouté au contexte ; forme JSON `additionalContext` (page lue sur ses 100 000 premiers caractères).
- `gh pr view/diff 136, 146, 147` (lecture seule).

### Secondary (MEDIUM confidence)
- Mémoire projet (`MEMORY.md`) : racine par comptage de `../`, preuve incapable de rendre rouge, rtk fausse les vérifications, sessions concurrentes / driver-lock.

### Tertiary (LOW confidence)
- Aucune source web hors documentation officielle citée.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — aucun package ; outils vérifiés sur le poste.
- Architecture: HIGH — chaque point d'insertion lu et, pour l'engine, exercé par installs mesurées ; les comportements d'arête (A4) sont des recommandations.
- Pitfalls: HIGH pour 1-6, 8-10 (mesurés ou cités avec citation verbatim) ; MEDIUM pour 7 (comportement du harnais).

**Research date:** 2026-10-16
**Valid until:** 2026-10-23 (dépôt actif : la PR #136 de Willy, ou toute release/rebase, change HOOKS-CONTRAT, les READMEs et `vibeflow-update.sh`) — revalider `git log a2ed5094..origin/main` avant d'écrire les plans.
