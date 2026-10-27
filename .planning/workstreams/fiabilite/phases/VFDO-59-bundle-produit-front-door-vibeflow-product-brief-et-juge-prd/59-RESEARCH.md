# Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate - Research

**Researched:** 2026-10-27
**Domain:** module de plugin Claude Code en markdown + bash (bundle d'agents sur le team-kernel, gabarits de planning, gate déterministe, redirection du head, registres et gates de CI). Aucun code applicatif.
**Confidence:** HIGH sur le dépôt (tout est lu ou mesuré dans ce worktree), MEDIUM sur deux points d'interprétation signalés (`forme exec` de `check-prd.sh`, rubrique de points).

Conventions de preuve de ce document : `[VERIFIED: chemin:lignes]` = fichier ouvert dans cette session, valeur citée verbatim à côté ; `[MEASURED]` = commande jouée dans cette session sur ce worktree (ou sur une copie jetable du scratchpad, jamais sous `plugin/`) ; `[CITED: …]` = lu dans une source ; `[ASSUMED]` = non prouvé, à confirmer. Aucun chemin absolu de machine n'est écrit ici (`check-machine-paths.sh` balaie les fichiers suivis, `.planning/` compris).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **P59-D-01 (composition, Q1 « Bundle complet ») :** module `product-team-bundle`.
  - **Front door.** `vibeflow-product`, en `AGENT.md` à la racine du module. Elle est posée `.claude/agents/<module>.md` et dotée d'une commande générée.
    - Le skill d'entrée `/vf-product` l'incarne en session principale, jamais en Task : la profondeur 1 est réservée au manager qu'elle lance.
    - Elle propose `Task(vf-product-manager)` sur signal de mission, comme `vibeflow-design` le fait avec `vf-design-manager`.
  - **Manager.** `vf-product-manager`, dans `agents/`, NON interne puisque la front door le dispatche.
    - Son allowlist est `Agent(vf-product-analyst, vf-product-pm, prd-gate)`. Elle porte aussi `SendMessage`, exigé par l'invariant I6 de `check-agents.sh`.
    - Il tient DAG, verrou de driver, digest par mandat et rapports typés (team-kernel).
  - **Workers.** Deux workers internes cloisonnés : `vf-product-analyst` produit le BRIEF, `vf-product-pm` produit le PRD.
  - **Juge.** `prd-gate`, interne et en lecture seule. Ce choix satisfait l'invariant I2 (monde fermé) sans toucher à aucun gate : le juge et les workers sont dispatchés par une allowlist de `plugin/*/agents`.
  - **Hors bundle.** Le worker `vf-product-architect` part en Phase 60.
- **P59-D-02 (noms, Q2) :** module `product-team-bundle` (nom de la spec §4A), skill d'entrée `/vf-product` (miroir de `/vf-design`). Aucun nom ne contient « BMAD » (marque protégée, SEED-001 §Recherche).
- **P59-D-03 (gabarit `product`, Q3) :** le gabarit vit dans `planning-core`, comme une dimension « poste » orthogonale à la rigueur. Il ne devient pas un 4ᵉ niveau à côté de Léger, Standard et Complet : RQ-EP-03 est tranchée en faveur d'une dimension.
  - Contenu : nouveaux fichiers PROJECT et REQUIREMENTS produit.
  - Le gabarit REQUIREMENTS produit ajoute un **critère d'acceptation** et une **priorité** à chaque exigence.
  - Il garde la forme de ligne que GSD sait lire (`- [ ] **ID**: …`), pour que le dev reprenne la main sans conversion.
  - **Phase 45 de Willy :** elle touche aussi `planning-core` (`module.json`, `VERSION`, `CHANGELOG`, hook). Ce n'est PAS un préalable : voir P59-D-23, qui remplace la consigne de rebase initiale.
    - La 59 n'ajoute que des fichiers neufs dans `planning-core`, plus le bump et le changelog.
- **P59-D-04 (BRIEF, Q4) :** `.planning/BRIEF.md`, à côté de `PROJECT.md`. Il est de niveau produit, y compris dans un lab partitionné.
  - Cinq rubriques (spec §5.2) : problème, utilisateurs, valeur, contraintes, hors périmètre.
  - Le BRIEF est court et lisible sans être dev.
- **P59-D-05 (seuil, Q5) :** `prd-gate` passe à 80/100 **et** aucun éliminatoire déclenché, comme les juges des bundles (`quality-gate-client`, « 79 n'est pas 80 »). Deux éliminatoires : 1. une exigence sans critère d'acceptation ; 2. un BRIEF auquel il manque l'une de ses cinq rubriques.
- **P59-D-06 (vérification, Q6) :** juge LLM **et** script déterministe `check-prd.sh`, que le juge appelle.
  - Le script rougit sur l'éliminatoire 1, et sur l'éliminatoire 2 s'il est mesurable mécaniquement.
  - Il naît avec ses trois issues et sa mutation rouge prouvée, en forme exec (QUAL-01, ADR-071).
  - Motif : sans lui, l'éliminatoire serait un vert auto-déclaré.
- **P59-D-07 (PRD sous le seuil, Q7) :** halte remontée à l'humain (ADR-031).
  - La main ne repasse au head qu'au-dessus du seuil, ou sur un override humain explicite que le rapport trace.
  - Aucun refus mécanique côté head : le refus de découpage est en Phase 60.
- **P59-D-08 (head, Q8) :** au poste `product`, le head ne dispatche pas `vf-coder` sur une intention de dev. Il redirige vers `/vf-product` et dit pourquoi en une phrase.
  - Il exécute quand même sur une demande explicite réitérée : un poste est une vue, pas un droit.
  - Aux postes `solo` et `dev`, rien ne change, sauf qu'une intention produit explicite (brief, PRD) fait proposer `/vf-product`.
  - Lecture du poste par `vf-role.sh get` (P58-D-15), jamais une relecture maison du fichier.
- **P59-D-09 (baseline d'instructions, Q9) :** la baseline de `dev-orchestrator/AGENT.md` peut monter de 3 au plus (33 → 36). L'objectif reste 0 : la redirection vit d'abord dans une référence chargée à la demande.
  - Le commit qui relève la baseline porte la citation « arbitrage Samuel, AskUserQuestion session principale, 2026-10-27 » (garde G-1).
  - Les baselines des agents neufs sont des lignes ajoutées, que G-1 ne juge pas.
- **P59-D-10 (visibilité, Q10) :** `roles:["product"]`. Le poste `solo` voit le bundle, le poste `dev` ne le voit pas.
  - `requires` = `conductor`, `planning-core`, `consolidator`, `audit-architecture`, `software-architecture` (spec §5.4), sans `design-orchestrator`.
  - L'invariant RLPO-05 (aucun module `["dev"]` dans la fermeture de `product`) reste vert.
- **P59-D-11 (Q-09, Q11) :** `proposable:false` jusqu'à un run réel complet (BRIEF → PRD → `prd-gate` ≥ seuil) sur un lab que Samuel désigne.
  - La bascule à `true` se fait dans une PR tracée, hors de cette phase.
  - Trailer `Ajout-Retrait` du nouveau `SKILL.md` (et du `check-prd.sh`) : « aucun : capacité de jalon inscrite (SEED-001, ROADMAP 59) ».
  - Fait à documenter : l'engine ignore `proposable`. `install --all` et une install nominale posent quand même le module ; seuls le catalogue et les presets l'excluent.
- **P59-D-12 (hypothèses par défaut, validées « Je valide ») :** au plus **250 lignes** par agent neuf (critère 5 du jalon, plus strict que les 300 de l'ADR-029) ; bump des modules touchés dans la PR, sans `VERSION` racine ni release (v2.72.0 décidée à part) ; pas de preset produit (`resolve-preset.sh` refuse un module `proposable:false`) ; `PROJECT.md` racine périmé et table Coverage de `REQUIREMENTS.md` sans DLWS ni RLPO : en dette, hors 59.
- **P59-D-23 (Phase 45 non bloquante ; précision de Samuel, message en session principale, 2026-10-27 : « pas besoin de prévenir Willy + on attend pas sa phase pour merge et release ») :** aucune coordination avec Willy n'est requise ; la Phase 45 du compartiment `gouvernance` n'est pas un préalable : pas de rebase sur elle, et elle n'est citée nulle part comme bloquante ; la PR 59 se merge et se releasera sur `main` telle quelle. Cette décision précise P59-D-03 sans en changer le fond : le gabarit reste dans `planning-core`.
- **P59-D-13 (fait établi, A-10 soldée) :** noms BMAD courants lus sur `bmad-code-org/BMAD-METHOD` v6.12.4 (2026-10-14) : `bmad-agent-analyst` (brief produit), `bmad-agent-pm` (PRD), `bmad-agent-architect`, `bmad-agent-ux-designer` (`ux-expert` est un nom de la v4). `vf-product-analyst` et `vf-product-pm` restent alignés, sans renommage.

### Claude's Discretion

- **P59-D-14 (rubric) :** le planificateur répartit les 100 points. Pistes : BRIEF complet et lisible, exigences vérifiables, critères d'acceptation testables, priorités posées, traçabilité BRIEF → exigences. Format de verdict aligné sur les juges des bundles : JSON `score`, `eliminatoire`, `detail{}`, et bloc typé du team-kernel. `prd-gate` reprend le frontmatter des juges : outils Read, Glob, Grep, Bash (pour `check-prd.sh`) ; `disallowedTools: Write, Edit` ; `omitClaudeMd: true` (invariant I5) ; `vf-internal: true`, avec le marqueur « Worker interne » dans la description (I1).
- **P59-D-15 (`check-prd.sh`) :** il vit dans `plugin/product-team-bundle/scripts/`. Il lit `.planning/REQUIREMENTS.md` (et `.planning/BRIEF.md`) du lab. Bash portable (ADR-054). Codes de sortie documentés : vert, rouge, indéterminé ou illisible. Le planificateur vérifie s'il tombe sous `check-planning-consumers-registered.sh` (un `.sh` qui cite `.planning/` suivi de REQUIREMENTS). Si oui, il l'enregistre.
- **P59-D-16 (lien gabarit ↔ poste) :** le planificateur décide comment `vf-planning` choisit le gabarit `product` (poste lu par `vf-role.sh`, ou choix explicite du bundle). Les gabarits existants restent intacts à l'octet pour les postes `solo` et `dev`.
- **P59-D-17 (passage de main) :** au-dessus du seuil, le rapport de `vf-product-manager` propose le next step au head (découpage par le dev), sans le lancer.
- **P59-D-18 (suite de tests) :** `test-product-team-bundle.sh` dans le bundle, sur le modèle de `test-business-pilot-bundle.sh`. Elle est découverte automatiquement. Elle couvre : `proposable:false`, `roles`, `requires`, frontmatters, lignes ≤ 250, `check-prd.sh` (vert, rouge, mutation). Le test de `test-build-module-catalog.sh` qui boucle en dur sur les trois bundles `true` est adapté pour exclure `product-team-bundle`, avec `Gate-Touche` si c'est une suite surveillée.
- **P59-D-19 (registres) :** une ligne par agent neuf dans `.planning/instruction-budget-baselines.tsv` (sinon rc 2, SANS-BASELINE) ; rafraîchissement de `check-agents-manifest.json` si `--manifest-freshness=strict` l'exige ; triade `VERSION` ↔ `module.json` ; compteur de modules 17 → 18 dans les badges et la phrase « N modules » de `README.md` et `README.fr.md` ; pages du manuel FR et EN qui listent les bundles, les skills et les agents.
- **P59-D-20 (head) :** la redirection s'insère dans la carte d'intention et le garde-fou de premier usage de `dev-orchestrator/AGENT.md`, ou dans une référence chargée à la demande, selon P59-D-09. `test-dev-orchestrator.sh` T37 (aucun `gsd-*` dans la colonne équipe) et T3/T5 (≤ 300 lignes) restent verts.
- **P59-D-21 (versions) :** `product-team-bundle` naît en `v1.0.0` ; bump minor de `planning-core` (nouveau gabarit) et de `dev-orchestrator` (nouvelle capacité du head) ; lire le `VERSION` réel au moment du bump, jamais une valeur écrite dans un plan.
- **P59-D-22 (doc) :** le README du bundle, FR d'abord, ouvre sur « Un poste est une vue, pas un droit ». Il dit `proposable:false` et le déclencheur de bascule. Il dit que l'engine pose quand même le module sur `install --all`.

### Deferred Ideas (OUT OF SCOPE)

- Worker architecte, `ARCHITECTURE.md` et gate architecture : Phase 60.
- `UI-SPEC` en binôme avec le design : à réinscrire si besoin après la 60.
- Preset produit : après la bascule `proposable:true`.
- Mise à jour de `PROJECT.md` racine et de la table Coverage (DLWS, RLPO) : dette d'hygiène hors 59.
- Hors phase (domain) : fichier `PRD.md` séparé (A-06) ; termes « epic » et « story » (Q-11) ; marqueur de phase proposée et `check-phase-validation.sh` (Phase 60) ; champ `role:` des registres et preuve à deux humains (Phase 61) ; release racine (P59-D-12).
</user_constraints>

<phase_requirements>
## Phase Requirements

Les 12 exigences existent déjà dans `.planning/workstreams/fiabilite/REQUIREMENTS.md` (lignes 1371-1382 de ce worktree, `- [ ] **PRDT-01**: …` à `**PRDT-12**`). Famille `PRDT` libre sur toutes les branches `origin/*` [MEASURED : `git grep -E "PRDT-[0-9]+"` sur les 55 branches distantes, 0 occurrence ; seules REQUIREMENTS.md et ROADMAP.md du worktree la portent].

| ID | Description (résumé) | Appui de la recherche |
|----|----------------------|------------------------|
| PRDT-01 | Composition et noms du bundle | § Frontmatters vérifiés, § Moule `business-pilot-bundle` / `design-orchestrator` |
| PRDT-02 | Gabarit `product` dans planning-core | § Gabarit produit, § Compatibilité GSD mesurée, § Recommandation P59-D-16 |
| PRDT-03 | BRIEF `.planning/BRIEF.md`, 5 rubriques | § check-prd.sh (détection des rubriques), gabarit BRIEF dans le bundle |
| PRDT-04 | Juge `prd-gate` | § Rubric proposée, § Frontmatters vérifiés |
| PRDT-05 | `check-prd.sh`, QUAL-01 | § check-prd.sh, prototype mesuré, § Consommateurs de planning |
| PRDT-06 | PRD sous le seuil : halte humaine | § Manager (contrat de rapport), ADR-031 |
| PRDT-07 | Redirection du head | § Head : 0 instruction ajoutée (mesuré) |
| PRDT-08 | `roles`, `requires`, `proposable:false` | § Rôles et fermeture (mesuré), § Engine |
| PRDT-09 | Sobriété, trailers | § Gates, § Trailers |
| PRDT-10 | Suite du bundle | § Validation Architecture, § Suites impactées |
| PRDT-11 | Registres et documentation | § Sites de comptage, § Manuel |
| PRDT-12 | Livraison | § Versions, § Collision planning-core (faits seuls) |
</phase_requirements>

## Summary

Le bundle est un assemblage de moules existants : tout ce qu'il faut a un précédent lisible dans le dépôt (`business-pilot-bundle` pour manager + workers + juge + suite de tests, `design-orchestrator` pour la front door incarnée par un skill). La difficulté n'est pas la forme, mais les **neuf pièges de câblage** que les gates du dépôt posent à un module neuf, tous mesurés ici : (1) une ligne de baseline par fichier d'agent du corpus `plugin/*/agents/*.md` + `plugin/*/AGENT.md`, sinon `check-instruction-budget.sh` rend rc 2 ; (2) `test-module-roles.sh` casse sur deux cas (`MR-LIST`, `MR-REAL`) dès qu'un module porte `roles:["product"]` ; (3) `check-version-sync.sh` exige de recompter les modules (17 → 18) **et les suites** (111 → 111 + nombre de suites neuves) dans les deux README ; (4) les `*.sh` qui citent `.planning/` suivi de `REQUIREMENTS.md` sur une même ligne doivent être recensés (ou ne pas porter ce littéral) ; (5) le trailer `Ajout-Retrait` exige un troisième segment `— défaillance : …` que la formule de P59-D-11 n'a pas ; (6) le gabarit REQUIREMENTS produit doit suivre la forme anglaise de GSD (`## Traceability`, colonne `Status`) pour que `requirements mark-complete` et le contrôle de traçabilité du moteur fonctionnent, ce que le gabarit français actuel de planning-core ne fait pas ; (7) le garde de premier usage du head propose `new-project` : au poste `product` il faut qu'il propose `/vf-product` d'abord ; (8) `planning-core/SKILL.md` Séquence B interdit de générer des exigences sur un lab à moteur GSD actif, donc un choix de gabarit **par le skill** ne fonctionnerait pas là où le poste product opère ; (9) l'engine ignore `proposable`.

La redirection du head se fait à **zéro instruction ajoutée** (mesuré par simulation : deux lignes ajoutées à `AGENT.md`, 212 → 214 lignes, instructions 33 → 33). La baseline `dev-orchestrator/AGENT.md` n'a donc pas à monter et la citation G-1 n'est pas nécessaire ; elle ne devient utile que si l'implémentation dépasse 33.

**Primary recommendation :** Construire en 4 vagues (gabarits + `check-prd.sh` + redirection du head en parallèle ; puis agents et front door ; puis suites/registres et documentation ; puis porte de phase), avec le choix du gabarit **explicite par le bundle** (le worker `vf-product-pm` instancie les fichiers `planning-core/references/templates/product/`), `vf-role.sh get` n'étant consulté que par le head et la front door comme avis, jamais comme sélecteur de gabarit.

## Architectural Responsibility Map

| Capacité | Tier principal | Tier secondaire | Rationale |
|----------|----------------|-----------------|-----------|
| Détecter l'intention produit, proposer `/vf-product` | `vibeflow-head` (dev-orchestrator, référence à la demande) | skill `vf-dev` | Le head détecte et route ; la redirection ne réimplémente rien (A1) |
| Lire le poste | `conductor/scripts/vf-role.sh get` (lecteur unique) | hook SessionStart (ligne « Poste : X ») | Contrat 0/1/5/64 déjà lu par les Phases 59-61 |
| Incarner la front door | skill `vf-product` en session principale | `AGENT.md` du bundle | Profondeur 1 réservée au manager (team-kernel) |
| Orchestrer une mission produit | `vf-product-manager` (DAG, verrou, digest, rapports typés) | team-kernel du conductor | Le manager ne produit jamais |
| Produire BRIEF / PRD | workers `vf-product-analyst` / `vf-product-pm` | gabarits `planning-core` | Cloisonnement Pattern 12 |
| Juger et décider vert/rouge | `prd-gate` (frais, lecture seule) + `check-prd.sh` (déterministe) | humain (ADR-031) sous le seuil | Un vert ne vient jamais du producteur |
| Porter les gabarits `product` | `planning-core/references/templates/product/` | — | P59-D-03 : dimension poste, fichiers neufs |
| Visibilité selon le poste | `module.json` `roles` + `module-roles.sh` + `build-module-catalog.sh` | engine (`vibeflow-update.sh`) | Source unique du prédicat |
| Garde de conformité du dépôt | `scripts/` + `plugin/conductor/scripts` + CI `gates` | suites `*/tests/test-*.sh` | Découverte automatique des suites |

## Standard Stack

Pas de bibliothèque externe : la phase n'installe aucun paquet npm, pip ni cargo (voir § Package Legitimacy Audit).

### Core (outils du dépôt réutilisés, tous lus cette session)
| Brique | Version / état | Rôle | Pourquoi |
|--------|----------------|------|----------|
| team-kernel (`conductor-references/team-kernel.md`) | conductor v1.50.2 | contrat DAG, verrou, digest, rapport typé | repris par `vf-business-manager` (`agents/vf-business-manager.md:53-76`), pas réimplémenté |
| `vf-role.sh get` | `plugin/conductor/scripts/vf-role.sh` | poste unique | `# Codes de sortie ... 0 / 1 / 5 / 64` [VERIFIED: vf-role.sh:9-13] |
| `check-agents.sh` | `--strict --resolve-agents=strict --manifest-freshness=strict` | I1, I2, I5, I6, monde fermé | commandes CI exactes ci-dessous |
| `check-instruction-budget.sh` | baseline TSV `chemin<TAB>lignes<TAB>instructions` | ratchet | une ligne par agent neuf |
| `gsd-tools` (gsd-core 1.18.0 local) | `requirements mark-complete` | lecture des exigences par le dev | mesuré sur le gabarit proposé |

### Alternatives Considered
| Au lieu de | Alternative | Compromis |
|------------|-------------|-----------|
| choix de gabarit par le skill `vf-planning` (poste lu par `vf-role.sh`) | choix explicite du bundle (recommandé) | voir § P59-D-16 : le skill est routé hors-service sur un lab GSD actif |
| Gabarit PRD en 4ᵉ profil de `PROFILES.md` | dimension orthogonale (déjà tranché P59-D-03) | `PROFILES.md` et `SKILL.md` restent identiques à l'octet |
| `check-prd.sh` avec chemin par défaut `.planning/REQUIREMENTS.md` | chemins passés en arguments (recommandé) | évite le recensement (voir § Consommateurs de planning) et sert aussi un lab partitionné |

**Installation :** aucune dépendance à installer.
**Version verification :** non applicable (aucun paquet externe).

## Package Legitimacy Audit

Aucun paquet externe n'est installé par cette phase (markdown, bash, awk, jq déjà prérequis de l'engine [VERIFIED: `plugin/_internal/module-roles.sh:21`]). Rien à auditer.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 humain (poste product ou solo)
   |  "écris le brief / le PRD", "cadre ce produit"
   v
 vibeflow-head (/vf-dev)  --lit le poste--> vf-role.sh get  (0=solo|product|dev, 1/5/64=erreur bruyante)
   |   poste product : redirection en une phrase vers /vf-product (reference product-routing.md)
   |   poste solo/dev : intention produit explicite -> PROPOSE /vf-product
   v
 /vf-product (skill, vf-invocation: model) --incarne--> vibeflow-product (AGENT.md, session principale, jamais en Task)
   |  geste simple (un fichier)            \  signal de mission (BRIEF + PRD + gate)
   |  = production directe cadrée          \--propose--> Task(vf-product-manager)   [profondeur 1]
   v                                                       |
 BRIEF / PRD                                               |  driver-lock acquire ; DAG ; digest <=30L / mandat
                                                           v
                              +---------------- vf-product-manager (opus) ----------------+
                              |                                                           |
                  Task(vf-product-analyst)  --> .planning/BRIEF.md   (gabarit du bundle)  |
                  Task(vf-product-pm)       --> PROJECT.md + REQUIREMENTS.md              |
                                               (gabarit planning-core/templates/product)  |
                              |                         |                                 |
                              +--> Task(prd-gate, frais, lecture seule)                   |
                                      |  Bash: check-prd.sh --requirements <f> --brief <f> (0/1/3/5/64)
                                      |  verdict JSON {statut, score, eliminatoire, detail{}, findings[]}
                                      v
                    score>=80 ET eliminatoire:false ?
                       oui -> rapport de mission : PROPOSE le next step au head (decoupage par le dev), ne le lance pas
                       non -> statut human_needed / gaps_found : HALTE remontee a l'humain (ADR-031)
                              (override humain explicite = trace au rapport)
```

### Recommended Project Structure
```
plugin/product-team-bundle/
├── module.json                  # roles ["product"], proposable false, requires x5
├── VERSION  CHANGELOG.md  README.md   # README FR d'abord, ouvre sur « Un poste est une vue, pas un droit »
├── AGENT.md                     # vibeflow-product (front door), <= 250 lignes
├── agents/
│   ├── vf-product-manager.md    # non interne, opus
│   ├── vf-product-analyst.md    # interne, sonnet -> BRIEF
│   ├── vf-product-pm.md         # interne, sonnet -> PRD
│   └── prd-gate.md              # interne, juge, sonnet, Bash pour check-prd.sh
├── skills/vf-product/SKILL.md   # vf-invocation: model
├── references/BRIEF.template.md # posé par l'engine sous agents/product-team-bundle-references/
└── scripts/
    ├── check-prd.sh             # posé aplati sous .claude/scripts/ (copy_module_scripts)
    └── tests/ test-product-team-bundle.sh, test-check-prd.sh, fixtures/
plugin/planning-core/references/templates/product/{PROJECT,REQUIREMENTS}.template.md   # fichiers NEUFS
```
Faits d'installation [VERIFIED: `plugin/_internal/vibeflow-update.sh`] :
- `:2532-2537` Type 3 : `if [ -f "$module_dir/AGENT.md" ]; then vf_place_file "$module_dir/AGENT.md" "$TARGET_ROOT/agents/${mod}.md"` → la front door devient `.claude/agents/product-team-bundle.md` (name frontmatter `vibeflow-product`, d'où le warning « name différent du nom de fichier », identique à `design-orchestrator`) ;
- `:2706-2709` : `if [ -f "$module_dir/AGENT.md" ]; then generate_agent_command_for "$mod"` → commande `commands/product-team-bundle.md` (`/product-team-bundle`), pas `/vibeflow-product` ; `/vf-product` est le **skill** ;
- `:2586-2596` : `references/` va sous `skills/<mod>/references` si le module a un `SKILL.md` **à la racine**, sinon sous `agents/<mod>-references/` (cas du bundle : skill imbriqué `skills/vf-product/`) ;
- `:2550-2560` Type 4 : `content/` → `docs/<mod>/` (le bundle n'en a pas besoin) ;
- `copy_module_scripts` : `scripts/*.sh` aplatis sous `.claude/scripts/<basename>`, `scripts/tests/*.sh` sous `.claude/scripts/tests/` (nom `check-prd.sh` sans homonyme dans le dépôt [MEASURED]).

### Pattern 1 : frontmatters vérifiés `check-agents.sh --strict` (prototype mesuré)
Un jeu de quatre fichiers d'agents de prototype (hors dépôt, scratchpad) passe la commande CI complète en monde fermé, rc 0, 4 warnings « aucun skill câblé » (identiques aux 5 agents business [MEASURED]) ; retirer `SendMessage` du manager rougit I6 avec `✗ vf-product-manager.md : invariant I6 — manager (allowlist Agent(...) non vide, non vf-internal) sans SendMessage dans tools: (D-07)` [MEASURED].

```yaml
# vf-product-manager.md
name: vf-product-manager
description: "Manager de mission produit — ... Dispatché par l'agent vibeflow-product ..."   # PAS de « Worker interne »
tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, SendMessage, Agent(vf-product-analyst, vf-product-pm, prd-gate)
model: opus
effort: high
memory: project
# vf-product-analyst.md / vf-product-pm.md
tools: Read, Write, Glob, Grep
model: sonnet
effort: medium
memory: project
vf-internal: true          # + « Worker interne » dans description (I1, sens double)
# prd-gate.md   (mêmes clés que vf-design-judge.md)
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
model: sonnet
effort: high
memory: project
omitClaudeMd: true         # I5 : Write ET Edit retirés + allowlist vide => juge
vf-internal: true          # + « Worker interne » dans description
```
Sources : `plugin/business-pilot-bundle/agents/vf-business-commercial.md` (workers : `tools: Read, Write, Glob, Grep`, `model: sonnet`, `effort: medium`, `vf-internal: true`), `plugin/design-orchestrator/agents/vf-design-judge.md` (`tools: Read, Bash, Glob, Grep`, `disallowedTools: Write, Edit`, `effort: high`, `omitClaudeMd: true`), `vf-business-manager.md` (`tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, SendMessage, Agent(...)`, `model: opus`) [VERIFIED par `grep` des clés, cette session].
Règles de rédaction : description en **scalaire guillemeté mono-ligne** (le `description: >` replié casse les convertisseurs kimi/codex, mémoire `project_description-repliee-casse-les-convertisseurs`), sans `"` interne ; ne jamais lister `vf-product-manager` dans une allowlist `Agent(...)` d'un autre agent (I3 : un agent non interne dispatché par une allowlist résolue est « worker exposé par erreur »).

### Pattern 2 : front door sur le moule `design-orchestrator`
- `AGENT.md` : frontmatter `name: vibeflow-product`, `description`, `model: opus`, `effort: high`, `memory: project`, **sans `tools:`** comme `vibeflow-design` (3 warnings connus rc 0 [MEASURED sur `design-orchestrator/AGENT.md`]). Ne pas lui donner d'allowlist `Agent(...)` (elle déclencherait I6 : il faudrait alors `SendMessage`).
- `skills/vf-product/SKILL.md` : `vf-invocation: model` (le gate `check-skills.sh --strict` exige un classement ; `vf-design` et `vf-business` sont `model` [VERIFIED]), 27 lignes pour `vf-design` (corps = « incarne l'agent … jamais dispatché en Task »), 100 pour `vf-business` (aiguillage geste simple vs mission, `SEUIL_EQUIPE_BUSINESS`). Plafond 500 lignes [VERIFIED: check-instruction-budget.sh:125 `VF_SKILL_LINE_CAP=500`].
- Le skill est le seul nouvel `SKILL.md` du bundle : un trailer `Ajout-Retrait` (§ Trailers).

### Pattern 3 : manager (contrat repris du kernel, ne rien réimplémenter)
Sections de `vf-business-manager.md` à décalquer (en-têtes lus : Iron Laws, Entrée, Sources à lire, Discipline kernel, Dispatch parallèle, Périmètres d'écriture, Digest de mission, Définition du « vert », Validation humaine, Contrôle de flux, Halt conditions (5 codes), Capitalisation, Rapport de mission). Pour le produit : un seul nœud en chaîne (analyste → PM → gate → humain), pas de parallélisme de dossiers ; verrou `"$S"/driver-lock.sh acquire --owner=<id> --step=<mission> [--ws=<sujet>]` avant tout dispatch (`vf-business-manager.md:53-76`). Cascade `$S` : `./.claude/scripts` d'abord, puis `$HOME/.claude/scripts`, puis `${CLAUDE_PLUGIN_ROOT}/…` [VERIFIED: `dev-orchestrator/references/mission-flow.md:10-22`] ; `check-prd.sh` doit être cherché dans la même cascade, avec `${CLAUDE_PLUGIN_ROOT}/product-team-bundle/scripts` en dernier repli.
Contrat d'issue (P59-D-07, D-17) : `prd-gate` rend `passed` (>= 80 et `eliminatoire:false`) ou `gaps_found` / `human_needed` ; sous le seuil, le manager rend `human_needed` (jamais de relance silencieuse, jamais de passage au head) ; au-dessus, son rapport **propose** le next step « découpage par le dev » sans le lancer.

### Anti-Patterns to Avoid
- **Choisir le gabarit dans `planning-core/SKILL.md` ou `PROFILES.md`** : modifie l'octet des gabarits « existants » et le `@bootstrap:socle` (voir pitfall 6).
- **Glob ou liste d'agents en dur dans une suite** : le dépôt a déjà payé ce défaut (MR-LIST, MR-REAL).
- **Preuve par `grep` de présence seule** : les suites existantes (`test-business-pilot-bundle.sh` T4-T12) vérifient la présence de chaînes ; le mémo `preuve-incapable-de-rendre-rouge` en fait le mode de défaut dominant. La suite du bundle doit exécuter les gates sur des copies mutées.
- **Un `PRD.md` séparé, « epic », « story », « BMAD » dans un nom** : hors phase / interdits.

## Don't Hand-Roll

| Problème | Ne pas construire | Utiliser | Pourquoi |
|----------|-------------------|----------|----------|
| Lecture du poste | relecture de `.claude/vibeflow-role` | `vf-role.sh get` (cascade `$S`) | valide, borne à 64 octets, refuse liens/BOM, codes stables |
| Verrou, DAG, digest, rapport typé | protocole propre au produit | team-kernel + `driver-lock.sh`, `dag.sh` | `team-kernel.md` ; le manager business le fait déjà |
| Fermeture de dépendances | calcul maison des `requires` | `resolve-deps.sh <module>` | source unique ; MR-CLOS le rejoue |
| Prédicat « visible à un poste » | liste de modules par poste | `module-roles.sh` (`validate/visible/list`) | `# Le prédicat n'existe qu'ici` [VERIFIED: module-roles.sh:14] |
| Lecture des exigences par GSD | parseur propre | forme `- [ ] **ID**: …` + `## Traceability` | `gap-checker.cjs`, `milestone.cjs`, `phase.cjs` (voir § compat) |
| Mutation de gate | harnais neuf | patron `mutant()` de `test-check-role-consistency.sh:404-421` (awk, `cmp -s`, `bash -n`, sonde rouge, original revérifié) | déjà éprouvé en Phase 58 |

**Key insight :** chaque brique de « vert » a déjà un précédent prouvé rouge ; la phase en livre trois neuves (`check-prd.sh`, la suite du bundle, la redirection du head) et doit chacune les armer d'une mutation rouge.

## Runtime State Inventory

Phase de création, pas de renommage/refactor/migration : section omise. Une seule remarque d'état : l'engine pose le module sur `install --all` malgré `proposable:false` (voir § Engine), donc `test-roles-e2e.sh` (qui joue deux `install --all`) l'installera.

## Common Pitfalls

### Pitfall 1 : SANS-BASELINE (rc 2)
**What goes wrong :** `check-instruction-budget.sh` sort rc 2 si un fichier du corpus n'a pas de ligne de baseline [VERIFIED: check-instruction-budget.sh:640-651 : `[ "$SANS_BASELINE_COUNT" -gt 0 ] || [ "$ORPHAN_COUNT" -gt 0 ]` → `BASELINE_CONTRACT_BAD=1` → `RC=2`]. Orphelin = ligne sans fichier.
**How to avoid :** 5 lignes neuves, valeurs lues dans la sortie du script (colonnes `LIGNES`, `INSTR`), jamais calculées à la main : `plugin/product-team-bundle/AGENT.md`, `…/agents/prd-gate.md`, `…/vf-product-analyst.md`, `…/vf-product-manager.md`, `…/vf-product-pm.md`. Format `chemin<TAB>lignes<TAB>instructions`, trié `LC_ALL=C` (insérer entre `plugin/mobile-test-team/…` et `plugin/skill-creator/…`). G-1 ne juge pas une ligne absente à la base [VERIFIED: check-baseline-arbitrage.sh : la jointure ne compare que les chemins `PRESENT` des deux côtés].
**Warning signs :** `SANS-BASELINE` dans la colonne VERDICT ; `BILAN … code=2`.

### Pitfall 2 : `test-module-roles.sh` rougit (MR-LIST, MR-REAL)
**What goes wrong :** [MEASURED sur une copie jetable de `plugin/` avec un `product-team-bundle/module.json` `roles:["product"]`, `proposable:false`] : `✗ MR-LIST product attendu [...]` et `✗ MR-REAL attendu [dev-orchestrator ...]`. `MR-CLOS` (fermeture) reste vert, `test-build-module-catalog.sh` 14 OK / 0 KO, `test-build-module-catalog-role.sh` 25 OK / 1 SKIP, `test-resolve-preset-role.sh` 21 OK / 0 KO.
**Cause :** `plugin/_internal/tests/test-module-roles.sh:81` `DEVS="$(printf 'dev-orchestrator\nmobile-test\nmobile-test-team\n')"`, `:86` `if [ "$LP" = "$exp" ] && [ "$LD" = "$ALL" ] && [ "$LS" = "$ALL" ]` (le poste `dev` voit tout, faux maintenant), `:89-90` `REALANY=…select(has("roles"))` doit égaler `DEVS`.
**Changement minimal :** `ALL_DEV = ALL moins product-team-bundle` pour la comparaison `LD` ; `REALANY` attendu = `DEVS` + `product-team-bundle` ; `REAL` (roles == ["dev"]) inchangé ; ajouter un cas témoin « product-team-bundle visible à product et solo, invisible à dev ». Cette suite n'est **pas** dans la surface de G-2 (voir pitfall 8) : pas de `Gate-Touche`.

### Pitfall 3 : `test-build-module-catalog.sh` n'a PAS besoin d'être adapté
**What goes wrong :** CONTEXT P59-D-18 prévoit d'exclure le bundle de la boucle `for bundle in content-bundle growth-bundle business-pilot-bundle` [VERIFIED: test-build-module-catalog.sh:115]. Cette boucle affirme seulement la **présence** de ces trois-là ; elle ne peut pas voir un quatrième. Le cas « repo réel » compte `ndisk − nhidden` avec `jq -r '.proposable == false'` [VERIFIED: :73-75]. [MEASURED] 14 OK / 0 KO avec le module de prototype.
**Recommandation :** ne pas modifier la boucle ; ajouter si on veut une preuve positive : `product-team-bundle` **absent** du catalogue (témoin que `proposable:false` filtre). Aucun `Gate-Touche` (suite hors surface).

### Pitfall 4 : compteurs de `check-version-sync.sh`
`check-version-sync.sh` (gate CI, étape « check-version-sync ») recompte : badge `modules-N` et phrase `N modules, each versioned` / `N modules, chacun versionné` des deux README ; triade `VERSION` ↔ `module.json` par module ; et **« N suites »** des deux README contre `find plugin scripts -path '*/tests/test-*.sh'` [VERIFIED: check-version-sync.sh:123-137]. État mesuré : 17 modules, 111 suites. Sites : `README.md:20` (badge), `README.md:65` (« 111 suites run »), `README.md:114` (« 17 modules, each versioned »), `README.fr.md:20`, `:67`, `:116`. Chaque suite neuve (`test-product-team-bundle.sh`, `test-check-prd.sh`, toute autre) ajoute 1 : **recompter par `find` à la fin**, ne pas figer 113 dans un plan. Le gate impose aussi `**Version**` des README de module seulement s'il y est déclaré (un bundle n'en déclare pas).

### Pitfall 5 : trailer `Ajout-Retrait` incomplet dans CONTEXT
CONTEXT P59-D-11 cite : « aucun : capacité de jalon inscrite (SEED-001, ROADMAP 59) ». La forme exigée est `Ajout-Retrait: <chemin|motif> — <retrait | aucun : justification ≥ 10 car.> — défaillance : <≥ 10 car. non blancs + date ISO ou SHA>` [VERIFIED: check-ajout-retrait.sh en-tête, lignes « COUVERTURE »] ; sans le troisième segment le trailer est `MARQUEUR-MAL-FORME` et ne couvre rien. Précédent réel :
`Ajout-Retrait: plugin/conductor/scripts/check-role-consistency.sh — aucun : premier gate du poste, aucun contrôle existant ne lit le poste ni vf_roles — défaillance : poste absent du lab et de la session, constaté au cadrage de la Phase 58 le 2026-10-16` [MEASURED : `git log`].
Ajouts surveillés ici [VERIFIED: awk du script] : `plugin/product-team-bundle/scripts/check-prd.sh` (motif `plugin/[^/]+/scripts/(check|guard)-…\.sh`) et `plugin/product-team-bundle/skills/vf-product/SKILL.md` (tout `SKILL.md` sous `plugin/`). Un trailer = un chemin (pas de virgule, glob admis seulement dans le dernier segment et ≥ 6 caractères littéraux). L'étape CI est **consultative** (`::warning::`, rc 0) [VERIFIED: ci.yml:1681-1699].

### Pitfall 6 : le gabarit REQUIREMENTS de planning-core n'est pas lisible par le moteur
Le gabarit actuel `REQUIREMENTS.template.md` écrit `- [ ] **REQ-01** : …` (espace avant `:`), `## Traçabilité` et `| Exigence | Étape | Statut |` [VERIFIED: contenu lu]. Le moteur lit `## Traceability` (regex `^#{1,6}\s+Traceability\b`) et une colonne nommée `Status` [VERIFIED: gsd-core `phase.cjs:3938` et `milestone.cjs:170-180`]. Conséquence : un REQUIREMENTS produit au gabarit français déclencherait « REQ-ID(s) found in body but missing from Traceability table » pour toutes les lignes. Le gabarit **produit** doit donc reprendre la structure du gabarit GSD livré (`templates/requirements.md` : `## v1 Requirements`, `### <catégorie>`, `- [ ] **ID**: …`, `## v2 Requirements` (listes sans case), `## Out of Scope`, `## Traceability` + `| Requirement | Phase | Status |`) tout en gardant le contenu en français. Le gabarit existant reste intact (dimension orthogonale).

### Pitfall 7 : garde de premier usage du head
`dev-orchestrator/AGENT.md:31-42` : si `.planning/PROJECT.md` est absent, le head propose `gsd-onboard`/`new-project` « jamais ce geste seul ni en autonomie ». Au poste `product` sur un lab neuf, c'est le mauvais geste : la référence `product-routing.md` doit dire que `/vf-product` passe d'abord. Le pointeur doit se trouver **dans** la section du garde-fou (ou avant), sinon il est lu après la proposition d'init.

### Pitfall 8 : surface de G-2 (`Gate-Touche`)
Surface = `plugin/conductor/scripts/check-*.sh`, `scripts/check-*.sh`, leurs suites `plugin/conductor/scripts/tests/test-*.sh` et `scripts/tests/test-*.sh`, `.github/workflows/ci.yml`, `scripts/hooks/**`, les fixtures de ces suites [VERIFIED: check-gate-touche.sh en-tête, six classes]. Aucun fichier prévu par ce plan n'y entre (`check-prd.sh` vit sous `plugin/product-team-bundle/`, `test-module-roles.sh` sous `plugin/_internal/`, `test-build-module-catalog.sh` sous `plugin/installer/`). Donc **aucun trailer `Gate-Touche`** attendu ; `check-gate-touche.sh` doit rendre rc 3 (`RIEN-A-JUGER`) — un rc 1 signalerait un fichier touché par erreur. Enregistrer `check-prd.sh` au recensement toucherait `plugin/conductor/references/workstream-planning-consumers.md` (hors surface, mais bump conductor à envisager) : voir § Consommateurs.

### Pitfall 9 : `check-planning-consumers-registered.sh` et le littéral REQUIREMENTS
[VERIFIED: check-planning-consumers-registered.sh volet 1] tout `*.sh` suivi hors segment `tests`, dont **une ligne** porte `.planning/workstreams` ou `.planning/` suivi de `STATE.md`, `ROADMAP.md` ou `REQUIREMENTS.md`, doit figurer au recensement (`plugin/conductor/references/workstream-planning-consumers.md`, première colonne = chemin ou basename). Les lignes de commentaire comptent. `.planning/BRIEF.md` ne déclenche pas. Deux voies :
- (recommandée) `check-prd.sh --requirements <chemin> [--brief <chemin>]` sans chemin par défaut : jamais le littéral sur une ligne ; le manager passe les chemins du compartiment actif (lab partitionné : le BRIEF est à la racine, PROJECT/REQUIREMENTS dans le compartiment). La CI le prouve (le lint est dans `gates`) ;
- sinon recenser en `a2 | exempté — résout le compartiment ACTIF` (précédent : `check-requirements-survival.sh`) et poser le bump conductor.
Les suites (`tests/`) ne sont pas balayées.

### Pitfall 10 : agents, manifeste et fidélité
- Le manifeste `check-agents-manifest.json` : listes vérifiées le 2026-10-22, `valide_jours: 30` → échéance 2026-11-21 [VERIFIED: manifeste ; CONTEXT « périme le 2026-11-21 »]. Pas à rafraîchir tant que la CI passe avant ; sinon relire chaque source avant de re-dater (jamais une date seule).
- Hors ci.yml mais posés à l'install : `check-description-fidelity.sh` (kimi) exige des descriptions YAML valides ; scalaire guillemeté mono-ligne sans `"` interne (mémoire `project_description-frontmatter-contrainte-en-ciseaux`).
- Prose de skill : `check-skills.sh` émet des warnings de dérive (ex. « motif de vf-gate-bloquant en prose ») sans bloquer ; 32 warnings déjà présents au dépôt [MEASURED]. Rester à 0 warning neuf si possible.

### Pitfall 11 : outils de mesure proxifiés
Utiliser `rtk proxy …` pour tout `grep`/`find`/`ls`/`git log`/`git diff` de mesure (sortie tronquée sinon, mémoires `grep-proxifie-tronque`, `ls-proxifie-rend-vide`, `diff-proxifie-faux-identique`). Dans les scripts livrés : `awk`, jamais `grep | wc -l` pour compter ; `LC_ALL=C` pour un balayage bytewise.

### Pitfall 12 : zsh et bash 3.2
La machine locale exécute `bash` 3.2.57 et `awk` 20200816 (BWK) [MEASURED] ; la CI `ubuntu-latest` bash 5 + mawk [CITED: manual/.tools/check-manual.sh:24 « Portable bash 3.2 (macOS) et bash 5 + mawk (ubuntu-latest) »]. Règles pour `check-prd.sh` et ses suites : pas de `mapfile`/`readarray`, pas de tableaux associatifs, pas de `${var,,}`, pas de `sed -i` (BSD ≠ GNU), pas de `grep -P`, pas d'intervalles `{n,m}` en awk (mawk), pas de `match(s, re, arr)` (gawk), retirer `\r` et le BOM, `LC_ALL=C` + ancres ASCII (voir § check-prd.sh). Les commandes de vérification d'un plan se jouent sous zsh côté exécutant : toujours `bash <script>` ou `bash -c '…'`, jamais de glob non guillemeté (zsh : `no matches found`, mesuré pendant cette recherche), `command grep` si un grep est inévitable.

## Code Examples

### Détection « exigence sans critère d'acceptation » (prototype mesuré, NON livré)
Source : prototype jeté du scratchpad ; mesuré sous bash 3.2 et zsh 5.9 (`bash prototype.sh`), awk BWK.
```bash
# Ouvreur d'exigence = forme lue par GSD (gap-checker.cjs boldIdRe, milestone.cjs checkboxPattern)
#   ^[ \t]*- \[[ xX]\] \*\*[A-Z][A-Z0-9]*-[A-Za-z0-9_-]+\*\*
# Bloc = ligne ouvrante + lignes de continuation indentées non-puces, jusqu'a ligne blanche, titre ou puce suivante
# Critère = ancre ASCII  [Aa]cceptation[ \t]*:  puis >= 10 car. non blancs, hors gabarit ( [..] / TBD / TODO / "a definir" / "..." )
LC_ALL=C awk '
  /^[ \t]*(```|~~~)/ { flush(); fence = !fence; next }   # exemples dans un bloc de code : ignorés
  fence { next }
  /^#+[ \t]/ || /^[ \t]*$/ { flush(); next }
  /^[ \t]*- \[[ xX]\] \*\*[A-Z][A-Z0-9]*-[A-Za-z0-9_-]+\*\*/ { flush(); open(); next }
  /^[ \t]*- / && id != "" { flush(); next }
  id != "" && /^[ \t]+/ { block = block "\n" $0; next }
  ...'
```
Résultats mesurés du prototype : fixture conforme (forme A mono-ligne et forme B continuation) → rc 0 ; exigence sans critère → rc 1 (`PRD-01 (aucun critere)`) ; critère `[… à compléter]` → rc 1 ; fichier sans aucune exigence (ou exemple en bloc de code) → rc 3 ; fichier absent → rc 3 ; CRLF → rc 0 ; mutant (branche « aucun critère » neutralisée) → rc 0 sur la fixture rouge, donc tué par la sonde.

### Forme de ligne des exigences produit (mesurée avec le moteur)
```markdown
- [ ] **PRD-01**: L'utilisateur exporte son rapport en PDF.
  Acceptation : un clic sur « Exporter » télécharge un PDF de moins de 5 Mo en moins de 3 s.
  Priorité : must
```
[MEASURED, gsd-core 1.18.0] `gsd-tools requirements mark-complete PRD-01` bascule la case, met la ligne de traçabilité à `Complete`, laisse les deux lignes de continuation intactes ; la forme mono-ligne (`… Acceptation : … Priorité : …` sur la ligne) est lue pareillement. Règles de compatibilité tirées du code du moteur [VERIFIED: `markdown-sectionizer.cjs iterateBullets`] : une ligne blanche ferme l'item (le critère reste **dans** le bloc) ; une sous-puce `  - …` est un item distinct (non lu comme exigence, mais ne pas y mettre de `**ID-NN**` gras) ; `phase.cjs:3928` collecte tout `**[A-Z][A-Z0-9]*-\d+**` en gras de la section active : ne jamais mettre en gras un motif de type identifiant dans un critère ; le gras multi-ligne n'est pas un ID.

## State of the Art

| Ancienne approche | Approche actuelle | Changement | Impact |
|-------------------|-------------------|------------|--------|
| Profils de rigueur seuls (Léger/Standard/Complet) | + dimension « poste » (gabarit `product`) | Phase 59 | fichiers neufs, `PROFILES.md` intact |
| Poste implicite | `vf-role.sh get` + `roles` du `module.json` | Phase 58 (v2.71.0) | contrat 0/1/5/64 |
| Gate qui ne mord pas sans preuve | trois issues + mutation rouge (QUAL-01) | jalon fiabilite-v1.0 | `check-prd.sh` en hérite |

**Deprecated/outdated :** la phrase de CONTEXT qui demande d'adapter `test-build-module-catalog.sh` (non nécessaire, § pitfall 3) ; la consigne de rebase sur la Phase 45 (remplacée par P59-D-23).

## Gates, commandes CI exactes et effet d'un module neuf

Jobs `tests` (découverte de **toutes** les suites) et `gates`. Commandes lues dans `.github/workflows/ci.yml` [VERIFIED] :

| Gate | Commande exacte (ci.yml) | Ce qu'un module neuf déclenche |
|------|---------------------------|--------------------------------|
| suites (`tests`) | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` puis `bash "$t"` chacune (l.217-237) | `plugin/product-team-bundle/scripts/tests/test-*.sh` est découverte seule ; tout rc ≠ 0 échoue |
| agents par dossier | `for d in plugin/*/agents; … bash plugin/conductor/scripts/check-agents.sh --strict --manifest-freshness=strict --agents-dir="$d"` (l.252-273) | nouveau dossier `plugin/product-team-bundle/agents` balayé |
| agents mono-fichier | `for f in plugin/*/AGENT.md; … check-agents.sh --strict --manifest-freshness=strict --file "$f"` (l.276-304) | `plugin/product-team-bundle/AGENT.md` (3 warnings attendus, rc 0) |
| monde fermé | `check-agents.sh --strict --resolve-agents=strict --manifest-freshness=strict --agents-dir="$d" "${registry_args[@]}"` avec `--agent-registry-dir=` de **chaque** `plugin/*/agents` (l.306-332) | I2 (workers/juge orphelins) satisfait par l'allowlist du manager ; I3 (manager non dispatché) ; I5 ; I6 ; I1 |
| skills | `bash plugin/conductor/scripts/check-skills.sh --strict --skills-dir=plugin --callers-root=plugin` + 4 bascules fixtures (l.334-410) | `vf-invocation:` obligatoire, arêtes `model` ; avis « sans appelant machine » non bloquant |
| blueprints | `bash plugin/conductor/scripts/check-blueprints.sh` (l.421) | sans objet (pas de `content/agents/*.blueprint.md`) |
| version-sync | `bash scripts/check-version-sync.sh` (l.424) | modules 17 → 18, suites, triade, README modules/suites |
| capability-activation | `bash plugin/dev-orchestrator/scripts/check-capability-activation.sh` (l.598) | corpus = `intent-routing.md` + `docs-flow.md` : non touchés |
| machine-paths | `bash scripts/check-machine-paths.sh` (l.615) | aucun `/Users/<nom>` ni `/home/<nom>` dans les fichiers suivis (ce document compris) |
| python-isolation | `bash scripts/check-python-isolation.sh --min-sites 40` (l.624) | ne pas écrire de `python -c` ; `check-prd.sh` est sans python |
| instruction-budget | 7 bascules fixtures puis `bash plugin/conductor/scripts/check-instruction-budget.sh` sur le dépôt (l.627-808) | 5 lignes de baseline (pitfall 1) ; plafond fichier 300 (avertissement dès 251) ; SKILL.md 500 |
| planning-consumers | `check-planning-consumers-registered.sh` + sa suite (l.1308-1390) | pitfall 9 |
| baseline-arbitrage (G-1) | `scripts/check-baseline-arbitrage.sh` (l.1391-1562) | rc 3 si plage vide ; lignes neuves non jugées ; citation seulement si une valeur **monte** |
| gate-touche (G-2) | `scripts/check-gate-touche.sh` (l.1563-1680) | rc 3 `RIEN-A-JUGER` attendu |
| ajout-retrait | `bash plugin/conductor/scripts/check-ajout-retrait.sh --ci` (l.1699) | 2 trailers (pitfall 5), consultatif |
| manuel | `bash manual/.tools/check-manual.sh` (l.1820) | pages ≤ 300 lignes, ≤ 3 H2, isomorphisme fr/en via `toc.yml`, **aucun `vX.Y.Z` hors bloc de code** (C5), liens relatifs vivants |
| affirmation non mesurée (G-4) | `scripts/check-affirmation-non-mesuree.sh` (l.1701-1811) | consultatif ; ne pas écrire au présent une protection serveur |
| release-tag | `scripts/check-release-tag.sh --remote` (main seulement, l.1919) | non concerné (pas de `VERSION` racine) |

Autres gates qui lisent le corpus d'agents sans être dans ci.yml : `check-description-fidelity.sh` (posé à l'install, kimi/codex).

## Rôles, fermeture et engine

- `module-roles.sh` : `roles` absente = visible à tous ; liste non vide parmi `product`/`dev` ; `solo` voit tout ; interdit sur `mandatory:true` [VERIFIED: module-roles.sh:5-14]. Donc `roles:["product"]` → visible à `product` et `solo`, invisible à `dev`.
- Fermeture de `product-team-bundle` (requires conductor, planning-core, consolidator, audit-architecture, software-architecture) : `conductor → planning-core, validator, skill-creator` ; `validator → consolidator, infrastructure-audit, audit-architecture`. Aucun n'a `roles` [MEASURED : `jq -c '[.version,.requires,.roles]'` sur les 9 modules]. `MR-CLOS` reste vert sur la copie jetable [MEASURED]. `mandatory` : conductor et consolidator (inchangé).
- `build-module-catalog.sh` filtre `proposable == false` puis `--role` par `module-roles.sh list` [VERIFIED: build-module-catalog.sh:82-120].
- Engine : `grep -c proposable plugin/_internal/vibeflow-update.sh` = 0 [MEASURED] → il ignore `proposable` ; `resolve-preset.sh:134-142` refuse un preset qui référence un module `proposable:false` (`err "preset '$name' : le module '$mod' est marqué proposable:false (WIP) — preset refusé"`). Filtre de poste dans l'engine : `[poste] <module> hors de la vue du poste <p> : non posé` (`vibeflow-update.sh:3477`, `:1287-1295`). `test-roles-e2e.sh` joue deux `install --all` sous HOME jetable, 35 s [MEASURED] : il installera le bundle (poste product : visible) ; il doit rester vert, à rejouer.

## Head : redirection à zéro instruction ajoutée (mesuré)

- `dev-orchestrator/AGENT.md` : 212 lignes, 33 instructions, baseline `212 / 33` [MEASURED + `instruction-budget-baselines.tsv:44` `plugin/dev-orchestrator/AGENT.md	209	33`]. Garde-fou premier usage l.31-42, carte d'intention l.46-75 (tableau l.56-72), `## Garde-fous` l.174, `## Références` l.204.
- Définition d'une instruction [VERIFIED: check-instruction-budget.sh:307-345] : ligne de corps (hors frontmatter, titres, blocs ```) qui contient (insensible à la casse) `jamais|toujours|ne .* pas|doit|must|never|always|interdit|obligatoire`, OU une puce sous un titre dont le libellé contient `règles|garde-fous|iron law|anti-pattern|lignes rouges|discipline`. Les lignes de tableau comptent comme les autres. Donc : un pointeur et une ligne de tableau **sans ces mots** coûtent 0 ; une puce neuve sous `## Garde-fous` coûte 1.
- [MEASURED] simulation sur copie jetable (fixture `--path`) : ajout de (a) une ligne `> Poste product (… « Poste : product » …) : lire d'abord …/product-routing.md, il prime sur ce qui suit.` après le titre du garde-fou premier usage et (b) une ligne de tableau `| brief produit / PRD / exigences / critères d'acceptation | skill vf-product (module product-team-bundle, quand il est posé) |` → 214 lignes, **33 instructions (inchangé)**, verdict `OK+LIGNES-EN-HAUSSE` (informatif, jamais comparé).
- Plan : nouveau fichier `plugin/dev-orchestrator/references/product-routing.md` (chargé à la demande ; installé sous `.claude/agents/dev-orchestrator-references/`) portant : lecture du poste (`"$S"/vf-role.sh get`, cascade `$S` de `mission-flow.md` ; codes 1/5/64 = erreur bruyante, pas de repli sur `solo`), règle poste `product` (redirection d'une phrase, exécution sur demande réitérée), règle `solo`/`dev` (proposition), exception du garde-fou premier usage. Ajouter une ligne à `references/_index.md` (l'index liste chaque fichier du dossier) et au bloc `## Références` d'AGENT.md.
- Contraintes de tests mesurées sur `test-dev-orchestrator.sh` (rc 0, 42 s [MEASURED]) : T3 (`wc -l` ≤ 300, ≥ 11 lignes d'intention), T5 (≤ 300), T13 (toute `references/*.md` balayée : aucun verbe supprimé `vf-plan`, `vf-review`, `vf-progress`… ni `vocabulary-map` ; `vf-product` n'en fait pas partie), T20 (exactement 3 warnings sur `AGENT.md` : ne pas toucher au frontmatter), T30-F (aucune référence ne reformule les 3 axes numérotés d'ADR-061), T37 (aucun `gsd-` dans la Carte d'intention ni dans la colonne Mind de `head-governance.md` §1) ; T11 (aucun chemin `.planning/research/` ni `docs/_mission`). T21/T21b ne portent que sur trois scripts du module (pas le bundle).
- Bump : `dev-orchestrator` v2.28.4 → minor (`VERSION` relue au bump ; `module.json` + `CHANGELOG.md`).
- **Garder le frontmatter du head intact** (description citant `Task(vf-design-manager)` etc.) : T20 et les baselines en dépendent.

## Gabarit produit, BRIEF et recommandation P59-D-16

**État de planning-core** [VERIFIED/MEASURED] : v2.8.3 ; `SKILL.md` Séquence A l.106-136 (choix du profil l.113-115, instanciation l.117-120) ; `PROFILES.md` : tableau Léger/Standard/Complet ; `references/templates/` : 10 gabarits + `cycles/` ; la routage du skill (l.91-96) envoie un lab à moteur GSD actif (`detect-gsd-engine.sh` exit 0) en Séquence B : « Ne pas générer la charte, la trajectoire, les exigences, l'état ni les étapes d'un projet de code ». Aucune suite n'énumère les gabarits (`test-recalc-planning.sh:838` ne résout que `templates/cycles`).
**Recommandation P59-D-16 (choix explicite du bundle, preuve) :**
1. Le poste product opère précisément sur les labs à moteur GSD (le PRD précède le découpage par le dev) ; le choix par `vf-planning` y est routé en Séquence B et refuserait de générer des exigences. Un sélecteur « poste » dans le skill serait donc mort là où il sert.
2. Toucher `SKILL.md` ou `PROFILES.md` change leurs octets (promesse « identiques à l'octet » à prouver au lieu d'être vraie par construction) et la description de `SKILL.md` entre dans `@bootstrap:socle` (2610 tokens, DEPASSEMENT-BOOTSTRAP si elle monte) [VERIFIED: check-instruction-budget.sh en-tête « Clé @bootstrap:socle »].
3. Le bundle `requires: planning-core` : le worker `vf-product-pm` peut lire les gabarits à `skills/planning-core/references/templates/product/` (disposition installée de planning-core [VERIFIED: vibeflow-update.sh:2586-2588 et `test-recalc-planning.sh:838` `skills/planning-core/references/templates/cycles`]), cascade `./.claude/skills/…`, `$HOME/.claude/skills/…`, `${CLAUDE_PLUGIN_ROOT}/planning-core/references/templates/product/`.
4. `vf-role.sh get` sert d'**avis** : si le poste lu est `dev` et que la front door est invoquée, elle l'annonce en une phrase puis exécute (un poste est une vue, pas un droit) ; il ne sélectionne rien.
Preuve d'octet : les fichiers existants de `planning-core` restent identiques ; test = comparaison `cmp` des fichiers existants contre `git show cbe97fb1:<chemin>` (SKIP nommé si l'objet est absent, patron `a2ed5094` des suites de la Phase 58), et `git diff --name-status cbe97fb1 HEAD -- plugin/planning-core` ne liste que des `A` plus `module.json`, `VERSION`, `CHANGELOG.md` (et `README.md` si touché).
**Contenu** : `templates/product/PROJECT.template.md` (charte produit : problème en une phrase renvoyant au BRIEF, valeur cœur, utilisateurs, contraintes, hors périmètre) et `templates/product/REQUIREMENTS.template.md` (structure GSD ci-dessus, lignes d'exemple conformes, `Acceptation :` et `Priorité :` à chaque exigence, `## Traceability`). Le `BRIEF.template.md` (5 rubriques) vit dans le bundle `references/` (lecture par l'analyste), pas dans planning-core (CONTEXT ne liste que PROJECT et REQUIREMENTS).

## check-prd.sh : conception recommandée

- **Interface** : `check-prd.sh --requirements <fichier> [--brief <fichier>] [-h]` ; au moins un des deux. Pas de chemin par défaut contenant `.planning/` + `REQUIREMENTS.md` sur une même ligne (pitfall 9). Installé aplati : `.claude/scripts/check-prd.sh`.
- **Codes de sortie** (convention de `check-role-consistency.sh`, Phase 58 [VERIFIED: l.5-60 : 0 conforme, 1 non conforme, 3 silence/indéterminé, 5 erreur d'analyse bruyante, 64 usage, « Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness »]) : `0` conforme ; `1` éliminatoire détecté (liste `exigence … (aucun critère)` / `rubrique … manquante`) ; `3` INDÉTERMINÉ (cible absente, **zéro exigence détectée** : jamais un vert à vide, F13) ; `5` illisible (lien symbolique, non régulier, illisible, awk en échec, fichier trop gros) ; `64` usage. Le code `2` n'est pas émis. (`check-instruction-budget.sh` suit une autre convention, 2 = non vérifiable ; la phase 58 est la plus récente et la plus proche.)
- **Avertissements non éliminatoires** : `priorité manquante ou hors de l'ensemble {must, should, could}` en sortie, sans effet sur le code ; le juge les lit pour le critère « priorités ».
- **Éliminatoire 2 (BRIEF)** mesurable mécaniquement : cinq titres Markdown reconnus par préfixes ASCII insensibles à la casse sous `LC_ALL=C` (`probl`, `utilisateur`, `valeur`, `contrainte`, `hors p`), chacun avec au moins une ligne de corps non vide, non commentaire HTML, non gabarit (`[…]`, `TBD`, `à compléter`) avant le titre suivant. Ancres sans accent : les octets UTF-8 ne sont pas des classes de caractères portables en awk BWK/mawk.
- **Ancre critère** : `[Aa]cceptation[ \t]*:` (ASCII) ; accepte « Acceptation : », « Critère d'acceptation : », « Critère d’acceptation : » (apostrophe typographique incluse) sans traiter `è`.
- **« Forme exec »** (QUAL-01 + ADR-071) : ADR-071 grave la forme exec pour les **entrées de hook** (`command` + `args`, chemin absolu de bash figé à l'install, pas de `|| true`, sortie normalisée **dans le script** sous `--hook`, aucun lanceur) [VERIFIED: docs/ADR.md:2488-2530]. `check-prd.sh` n'est pas un hook : lecture retenue [ASSUMED, à confirmer par le planificateur/Samuel] = (i) appelé par `bash <chemin résolu> <args>` en éléments séparés par le juge, **sans** `|| true` ni pipe qui masquerait le rc ; (ii) le script porte lui-même sa sémantique de rc (pas de traduction par l'appelant) ; (iii) trois issues PASS / FAIL / imparsable-BRUYANT chacune avec mutation rouge. Aucun câblage de hook, donc aucun `--hook`.
- **QUAL-01** [VERIFIED: REQUIREMENTS.md:1305] : « Tout nouveau gate du milestone naît avec ses trois issues (PASS / FAIL / imparsable BRUYANT) et sa mutation rouge prouvée ». Mutants minimaux à prouver tués (patron `mutant()` de `test-check-role-consistency.sh:404-421`, avec trace du rouge attendu/obtenu — mémoire `mutation-qui-echoue-pour-la-mauvaise-raison`) : M1 branche « aucun critère » neutralisée ; M2 filtre de gabarit/placeholder retiré ; M3 `zéro exigence` → 0 ; M4 `rc 5` replié sur 0/3 ; M5 rubrique du BRIEF non exigée ; M6 déduplication des fences retirée (un exemple en bloc de code compté). Original revérifié vert après chaque mutant.
- **Pas de jq, pas de python** : awk seul (ADR-054, check-python-isolation).

## Rubric proposée pour `prd-gate` (P59-D-14, répartition au choix du planificateur)

| # | Critère | Pts | Éliminatoire |
|---|---------|-----|--------------|
| 1 | BRIEF complet et lisible sans être dev (5 rubriques, court, sans jargon) | 20 | une rubrique manquante (`check-prd.sh --brief`) |
| 2 | Exigences vérifiables (atomiques, formulées en résultat observable) | 20 | — |
| 3 | Critères d'acceptation testables (mesurables, pas « fonctionne bien ») | 25 | une exigence sans critère (`check-prd.sh --requirements`) |
| 4 | Priorités posées et cohérentes (ensemble fermé, pas tout en `must`) | 15 | — |
| 5 | Traçabilité BRIEF → exigences (chaque besoin/valeur couvert, hors périmètre respecté) | 20 | — |

Seuil `score >= 80` ET `eliminatoire:false` (« 79 n'est pas 80 »). Verdict calqué sur `quality-gate-client` : `{"statut":"passed|gaps_found|human_needed","score":0-100,"eliminatoire":bool,"detail":{"brief":..,"exigences":..,"criteres":..,"priorites":..,"tracabilite":..},"findings":[{"severity","action","ref"}]}`. Le juge exécute `check-prd.sh` **et** cite son rc/sortie dans les findings ; un rc 1 force `eliminatoire:true` quel que soit le score ; un rc 3/5 force `human_needed`. Le juge lit explicitement le `CLAUDE.md` du lab (`omitClaudeMd: true` l'a coupé) comme `quality-gate-client`. Limite connue : `Bash` donne au juge une capacité d'écriture que `disallowedTools: Write, Edit` ne couvre pas (I4 interdit les spécificateurs `Bash(...)` dans `disallowedTools`) ; précédent `vf-design-judge` ; consigne écrite « Bash sert uniquement à `check-prd.sh` » [ASSUMED : l'effet d'une restriction `Bash(...)` dans `tools:` sur un sous-agent n'a pas été mesuré].

## Sites de comptage, documentation et versions

- Versions actuelles [MEASURED] : `planning-core` v2.8.3, `dev-orchestrator` v2.28.4, `conductor` v1.50.2, `VERSION` racine v2.71.2 (non touchée). Triade `VERSION` ↔ `module.json` ↔ `CHANGELOG.md` (en-tête `## [vX.Y.Z] — date (objet)`, format lu dans `business-pilot-bundle/CHANGELOG.md`). `product-team-bundle` naît en v1.0.0.
- READMEs racine : voir pitfall 4.
- Manuel [VERIFIED/MEASURED] : pages à mettre à jour FR+EN (toutes ≤ 134 lignes, ≤ 3 H2 : place pour de courts ajouts, **pas de nouvelle page** sauf entrée `toc.yml` + bandeau) : `06-reference/agents.md` (titre « Les 31 agents » FR l.40, « The 31 agents » EN l.37 + 5 lignes de tableau ; table triée par nom), `06-reference/skills.md` (nouvelle section `### product-team-bundle`), `03-modules/catalogue.md`/`catalog.md` (mention « posé par `install --all`, non proposé au catalogue »), `03-modules/bundles-metier.md`/`business-bundles.md` et `05-equipe-agents/equipes-specialisees.md`/`specialized-teams.md` (disent « trois bundles » : ajouter une note, ne pas changer le compte des bundles métier), `06-reference/couts-et-modeles.md`/`cost-and-models.md` (31 agents ; opus 10 → 12 ; sonnet 21 → 24 ; « les cinq autres managers »), `05-equipe-agents/les-agents-livres.md`/`the-agents-that-ship.md`. Les compter par commande, pas de mémoire (mémoire `ecart-de-chiffre-comparer-les-ensembles`). Contrainte C5 : aucun `v1.0.0` hors bloc de code.
- Conductor : le chiffre « 31 noms d'agents » de `team-kernel.md:230` est une prose historique mesurée, non gatée.

## Collision planning-core (faits mesurés, sans recommandation — P59-D-23)

[MEASURED : `git diff --name-only origin/main...origin/gouvernance/phase-47-cadrage -- plugin/planning-core`, refs locales non rafraîchies cette session ; PR ouvertes lues par `gh pr list`]. `main` : planning-core v2.8.3. PR #124 (base `main`, tête `gouvernance/phase-45-execution`) porte v2.9.0 ; la pile #133 → #136 → #146/#147 porte v2.10.0. Fichiers hors `tests/` touchés par ces branches : `CHANGELOG.md`, `README.md`, `VERSION`, `hooks/hooks.json`, `module.json`, `references/{example-lab-contenu,gsd-handoff,modele-cycles}.md`, `references/templates/cycles/{CYCLE,SORTIE-PIEGEE,VERDICT}.template.md`, `scripts/{check-gates-alive,deroger-gate,planning-hook,poser-verdict,recalc-planning,rejeu-gates,rejeu-reel}.sh`. `SKILL.md`, `references/PROFILES.md` et les gabarits à la racine de `references/templates/` n'y figurent pas. Les fichiers neufs de la Phase 59 (`references/templates/product/*`) ne recoupent aucun de ces chemins ; `VERSION`, `module.json`, `CHANGELOG.md` sont des fichiers que les deux séries touchent. Un minor depuis v2.8.3 vaut la chaîne `v2.9.0` aujourd'hui sur `main` (même chaîne que celle de la PR #124).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | « forme exec » de `check-prd.sh` = appel `bash <chemin> <args>` sans `|| true`, rc porté par le script, trois issues + mutation (ADR-071 vise les hooks) | check-prd.sh | le planificateur câble un hook inutile ou, à l'inverse, omet une exigence attendue par Samuel |
| A2 | `Bash` du juge reste utilisé pour `check-prd.sh` seul ; aucune restriction runtime n'est mesurée | Rubric | un juge pourrait écrire via Bash (même défaut que `vf-design-judge`) |
| A3 | répartition des points 20/20/25/15/20 | Rubric | à ajuster, sans conséquence de gate (P59-D-14 : discrétion) |
| A4 | ensemble de priorités `must/should/could` | check-prd.sh | à changer librement ; seul le critère d'acceptation est éliminatoire |
| A5 | mawk (ubuntu-latest) n'accepte pas les intervalles `{n,m}` | Pitfall 12 | contrainte plus stricte que nécessaire, sans coût |
| A6 | le bump de planning-core suit « minor » et s'écrit `v2.9.0` si la ligne `main` n'a pas bougé | Collision | le numéro final se lit au moment du bump (P59-D-21) |

## Open Questions

1. **Résolution des chemins en lab partitionné**
   - Connu : BRIEF à la racine (P59-D-04), PROJECT/REQUIREMENTS dans le compartiment actif ; `check-prd.sh` prend des chemins explicites.
   - Flou : qui calcule le chemin du compartiment (le manager via l'engine GSD, ou le skill) — non tranché par CONTEXT.
   - Recommandation : le manager le résout une fois au démarrage (même cascade que `$S`) et le passe dans le digest ; `check-prd.sh` ne devine jamais.
2. **Faut-il une suite séparée `test-check-prd.sh` ?**
   - Recommandation : oui (mutants dans une suite dédiée, la suite de bundle ne garde que la composition et une preuve croisée « gabarit instancié rempli → rc 0 ; non rempli → rc 1 »). Compte de suites +2.
3. **Pointer ADR** : aucune ADR neuve n'est exigée par CONTEXT ; ADR-077 couvre la doctrine du poste. Ne rien ajouter (SOBR : un ajout = un retrait).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| bash | toutes suites | oui | 3.2.57 (macOS) | — |
| awk | `check-prd.sh`, gates | oui | BWK 20200816 | — |
| jq | catalogue, `module-roles.sh`, suites | oui | présent (suites passent) | — |
| git | gates G-1/G-2, tests | oui | — | — |
| node + gsd-core | preuve de compatibilité GSD (mark-complete) | oui | gsd-core 1.18.0 | SKIP nommé de la preuve si absent |
| python3 | `test-vibeflow-update.sh` (hors périmètre de code neuf) | oui | — | — |
| perl | bornes de temps des suites existantes | oui | — | — |

Aucune dépendance bloquante manquante.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash `*/tests/test-*.sh` (`ok()/ko()/skip()`, exit 0 si tout passe) — pas de framework externe |
| Config file | aucune — découverte `find plugin scripts -type f -path '*/tests/test-*.sh'` (ci.yml:217) |
| Quick run command | `bash plugin/product-team-bundle/scripts/tests/test-check-prd.sh` |
| Full suite command | les suites touchées une à une (ci-dessous), jamais la découverte complète en parallèle |

Durées mesurées (rc 0 sur le dépôt actuel, séquentielles) : business-bundle 0 s ; module-roles 2 s ; build-module-catalog 1 s ; build-module-catalog-role 6 s ; resolve-preset-role 6 s ; roles-e2e 35 s ; planning-consumers 2 s ; instruction-budget (suite) 7 s ; planning-core 0 s ; check-agents (suite) 14 s ; check-skills (suite) 15 s ; dev-orchestrator 42 s ; vibeflow-update 152 s. Toutes < 10 min.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PRDT-01 | 5 agents, allowlist exacte, I1/I2/I5/I6, pas de « BMAD » | suite + gate | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` ; `bash plugin/conductor/scripts/check-agents.sh --strict --resolve-agents=strict --manifest-freshness=strict --agents-dir=plugin/product-team-bundle/agents --agent-registry-dir=plugin/product-team-bundle/agents` | ❌ Wave 0 |
| PRDT-02 | fichiers existants de planning-core identiques à l'octet ; gabarit lu par GSD | suite | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` (cas `cmp` contre `cbe97fb1`, cas `mark-complete`) | ❌ Wave 0 |
| PRDT-03 | BRIEF 5 rubriques détectées / manquante rougit | suite | `bash plugin/product-team-bundle/scripts/tests/test-check-prd.sh` | ❌ Wave 0 |
| PRDT-04 | frontmatter juge, rubric /100, seuil 80, éliminatoires, rc de `check-prd.sh` cités | suite | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` | ❌ Wave 0 |
| PRDT-05 | 3 issues + 6 mutants tués, original revérifié | suite | `bash plugin/product-team-bundle/scripts/tests/test-check-prd.sh` | ❌ Wave 0 |
| PRDT-06 | sous le seuil → `human_needed`, jamais de passage au head ; au-dessus → proposition | suite (texte du manager, mutation de clause) | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` | ❌ Wave 0 |
| PRDT-07 | pointeur et ligne de carte présents, instructions == 33, T3/T5/T13/T20/T30/T37 verts | gate + suite | `bash plugin/conductor/scripts/check-instruction-budget.sh` ; `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | ✅ (étendre) |
| PRDT-08 | `roles`, `requires`, `proposable:false`, fermeture, filtres, catalogue | suites | `bash plugin/_internal/tests/test-module-roles.sh` ; `bash plugin/installer/scripts/tests/test-build-module-catalog.sh` ; `bash plugin/installer/scripts/tests/test-build-module-catalog-role.sh` ; `bash plugin/_internal/tests/test-resolve-preset-role.sh` ; `bash plugin/_internal/tests/test-roles-e2e.sh` | ✅ (adapter `test-module-roles.sh`) |
| PRDT-09 | lignes ≤ 250, frontmatters, trailers, G-2 rc 3 | suite + gates | `bash plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` ; `bash plugin/conductor/scripts/check-ajout-retrait.sh --root . --strict` ; `bash scripts/check-gate-touche.sh` | ❌ Wave 0 |
| PRDT-10 | la suite existe, découverte, tue ses mutants | découverte | `find plugin scripts -type f -path '*/tests/test-*.sh' \| grep -c product-team` (via `rtk proxy` si mesuré en session) puis la suite elle-même | ❌ Wave 0 |
| PRDT-11 | baselines, version-sync, manuel | gates | `bash plugin/conductor/scripts/check-instruction-budget.sh` ; `bash scripts/check-version-sync.sh` ; `bash manual/.tools/check-manual.sh` | ✅ |
| PRDT-12 | bumps, `VERSION` racine intacte, pas de release | gate + diff | `bash scripts/check-version-sync.sh` ; `git diff --quiet cbe97fb1 HEAD -- VERSION plugin/.claude-plugin .claude-plugin` | ✅ |

Chaque commande tourne à l'identique sous bash et sous zsh car elle commence par `bash` et ne contient ni glob ni expansion non guillemetée. Pour qu'une preuve **puisse rougir** : toute assertion de la suite du bundle opère sur une **copie mutée** (agents dont on retire `SendMessage`, `vf-internal`, `omitClaudeMd`, le marqueur « Worker interne », une entrée d'allowlist ; `module.json` sans `roles` ou avec `proposable:true`) et exige le **motif de rouge attendu** (message de `check-agents.sh`, `invariant I6`…), jamais seulement un rc ≠ 0 (mémoire `mutation-qui-echoue-pour-la-mauvaise-raison`). Témoin positif d'abord pour chaque gate (la copie non mutée rend 0).

### Sampling Rate
- **Par commit de tâche :** la suite du fichier touché (`test-check-prd.sh` ou `test-product-team-bundle.sh`) + `bash plugin/conductor/scripts/check-instruction-budget.sh` si un agent ou `AGENT.md` a bougé.
- **Par vague :** ajouter `check-agents` (3 commandes CI ci-dessus), `check-skills`, `check-version-sync`, `check-planning-consumers-registered`.
- **Porte de phase :** voir § plan 59-08.

### Wave 0 Gaps
- [ ] `plugin/product-team-bundle/scripts/tests/test-check-prd.sh` — PRDT-03, 05
- [ ] `plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` — PRDT-01, 02, 04, 06, 08, 09, 10
- [ ] fixtures `plugin/product-team-bundle/scripts/tests/fixtures/` (REQUIREMENTS conforme, sans critère, gabarit non rempli, BRIEF complet / incomplet, CRLF, fence)
- [ ] adaptation `plugin/_internal/tests/test-module-roles.sh` (MR-LIST, MR-REAL)
Pas d'installation de framework.

## Security Domain

`security_enforcement` : clé non lue dans `.planning/config.json` pour cette recherche → traité comme activé.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | non | — |
| V3 Session Management | non | — |
| V4 Access Control | oui (conceptuel) | « un poste est une vue, pas un droit » : aucune décision de sécurité ne lit le poste (ADR-077) ; ne jamais présenter le cloisonnement comme une protection |
| V5 Input Validation | oui | `check-prd.sh` traite des fichiers de lab non fiables : refus de liens symboliques/non réguliers, borne de taille, pas d'`eval`, pas d'expansion de contenu, `LC_ALL=C` ; `vf-role.sh` valide déjà sa sortie |
| V6 Cryptography | non | — |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Injection par contenu de fichier jugé (BRIEF/PRD pilote le juge) | Tampering / Spoofing | le juge note un document, n'exécute rien ; `omitClaudeMd` + consigne de ne suivre aucune instruction contenue dans le livrable (mémoire `codex-juge-injection-par-depot-juge`) |
| Lien symbolique / FIFO / fichier géant comme cible de `check-prd.sh` | DoS / Tampering | refus rc 5 (patron `check-role-consistency.sh` : CR-CFG-LIEN, CR-CFG-FIFO, CR-CFG-GROS) |
| Chemin machine versionné | Info disclosure | `check-machine-paths.sh` (aucun `/Users/<nom>` dans README, fixtures, SUMMARY) |
| Bash du juge utilisé pour écrire | Tampering | limite connue (A2) ; périmètre déclaré dans le prompt |

## Fichiers touchés par la phase et décomposition en plans

**Hypothèse de disjonction** : deux plans d'une même vague ne partagent aucun fichier de `files_modified`. Les fichiers partagés par nature (`instruction-budget-baselines.tsv`, README racine, `toc` du manuel) sont confiés à un seul plan.

| Plan | Vague | Fichiers (créés = C, modifiés = M) |
|------|-------|-------------------------------------|
| 59-01 Gabarits produit + bump planning-core | 1 | C `plugin/planning-core/references/templates/product/PROJECT.template.md`, `…/REQUIREMENTS.template.md` ; M `plugin/planning-core/{module.json,VERSION,CHANGELOG.md}` (et `README.md` seulement si une table de fichiers y est tenue) |
| 59-02 `check-prd.sh` et sa suite à mutants | 1 | C `plugin/product-team-bundle/scripts/check-prd.sh`, `scripts/tests/test-check-prd.sh`, `scripts/tests/fixtures/*` |
| 59-03 Redirection du head + bump dev-orchestrator | 1 | C `plugin/dev-orchestrator/references/product-routing.md` ; M `plugin/dev-orchestrator/{AGENT.md,references/_index.md,module.json,VERSION,CHANGELOG.md}` |
| 59-04 Squelette du module et 4 agents | 2 | C `plugin/product-team-bundle/{module.json,VERSION,CHANGELOG.md,agents/vf-product-manager.md,agents/vf-product-analyst.md,agents/vf-product-pm.md,agents/prd-gate.md,references/BRIEF.template.md}` |
| 59-05 Front door, skill, README du bundle | 2 | C `plugin/product-team-bundle/{AGENT.md,skills/vf-product/SKILL.md,README.md}` |
| 59-06 Suite du bundle, baselines, adaptation de `test-module-roles.sh` | 3 | C `plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` ; M `.planning/instruction-budget-baselines.tsv`, `plugin/_internal/tests/test-module-roles.sh` (et, optionnel, une assertion d'absence dans `plugin/installer/scripts/tests/test-build-module-catalog.sh`) |
| 59-07 README racine et manuel FR+EN | 3 | M `README.md`, `README.fr.md`, `manual/fr/06-reference/{agents,skills,couts-et-modeles}.md`, `manual/en/06-reference/{agents,skills,cost-and-models}.md`, `manual/{fr,en}/03-modules/*` et `manual/{fr,en}/05-*/*` ciblés |
| 59-08 Porte de phase | 4 | aucun fichier de code ; cases PRDT cochées dans `REQUIREMENTS.md` du compartiment, `59-VERIFICATION`/ledger |

Notes de disjonction : 59-04 et 59-05 écrivent dans le même dossier mais sur des fichiers distincts (`module.json`/`agents/` contre `AGENT.md`/`skills/`/`README.md`) ; 59-06 dépend de 59-04/05 (comptage des baselines, preuve croisée) ; 59-07 dépend du nombre final de suites (recompté par `find`, jamais écrit en dur). 59-01 ne partage aucun fichier avec les plans du bundle ; la preuve croisée « gabarit rempli → `check-prd.sh` rc 0 » vit dans 59-06 (vague 3) pour ne pas coupler 59-01 et 59-02.

**Contenu des tâches (≤ 5 par plan)** :
- 59-01 : (1) gabarit REQUIREMENTS produit (structure GSD, Acceptation/Priorité, Traceability) ; (2) gabarit PROJECT produit ; (3) preuve de lecture par le moteur sur une instance (mark-complete) en suite jetable ; (4) bump minor + CHANGELOG (lire `VERSION` au moment du bump).
- 59-02 : (1) fixtures ; (2) `check-prd.sh` rc 0/1/3/5/64 ; (3) suite à trois issues ; (4) six mutants tués avec trace ; (5) trailer `Ajout-Retrait` du script (commit).
- 59-03 : (1) `product-routing.md` ; (2) pointeur + ligne de carte dans `AGENT.md` ; (3) `_index.md` + `## Références` ; (4) mesure `check-instruction-budget.sh` (33 attendu) + `test-dev-orchestrator.sh` ; (5) bump minor + CHANGELOG.
- 59-04 : (1) `module.json` (`roles`, `proposable:false`, `requires`) + `VERSION` + `CHANGELOG` ; (2) manager ; (3) analyste + PM ; (4) `prd-gate` ; (5) `BRIEF.template.md` ; chaque agent ≤ 250 lignes, vérifié par `check-agents.sh` (3 commandes CI) au fil de l'eau.
- 59-05 : (1) `AGENT.md` ; (2) `SKILL.md` + trailer ; (3) README FR puis EN court (ouvre sur « Un poste est une vue, pas un droit », `proposable:false` et déclencheur, pose par `install --all`) ; (4) `check-agents --file` et `check-skills`.
- 59-06 : (1) suite du bundle (composition, mutations de frontmatter, `roles`/`requires`/`proposable`, 250 lignes, preuve croisée gabarit ↔ `check-prd.sh`, `cmp` des fichiers planning-core) ; (2) adapter MR-LIST/MR-REAL ; (3) 5 lignes de baseline lues de la sortie du script ; (4) témoin d'absence du catalogue (optionnel).
- 59-07 : (1) compteurs README (badge, phrase, suites par `find`) ; (2) manuel FR ; (3) manuel EN ; (4) `check-manual.sh` + `check-version-sync.sh`.
- 59-08 (dernier plan, porte de phase) : (1) lire `ci.yml` job `gates` et **rejouer ses commandes lues dans le fichier**, jamais une liste de rapport (mémoire `liste-de-gates-jamais-la-reference` : `check-machine-paths` oublié a rougi la PR #62) ; (2) `bash plugin/conductor/scripts/check-instruction-budget.sh` (rc 0, 31 + 5 = 36 fichiers, `dev-orchestrator/AGENT.md` à 33) ; (3) rejouer **une à une** les suites touchées : `test-check-prd.sh`, `test-product-team-bundle.sh`, `test-module-roles.sh`, `test-build-module-catalog.sh`, `test-build-module-catalog-role.sh`, `test-resolve-preset-role.sh`, `test-roles-e2e.sh`, `test-dev-orchestrator.sh`, `test-check-planning-consumers-registered.sh`, `test-check-instruction-budget.sh`, `test-check-agents.sh`, `test-check-skills.sh`, `test-vibeflow-update.sh` (152 s) ; (4) `git diff --name-status` base..HEAD : seuls les chemins prévus, `VERSION` racine intacte ; (5) cocher PRDT-01..12 et s'arrêter avant merge/tag/release (PRDT-12).

## Sources

### Primary (HIGH confidence)
- Fichiers du dépôt lus cette session : `59-CONTEXT.md`, `REQUIREMENTS.md` (PRDT-01..12, QUAL-01), `ROADMAP.md` § Phase 59, `STATE.md`, `CLAUDE.md`, `.github/workflows/ci.yml`, `plugin/business-pilot-bundle/**` (module.json, agents, skill, suite), `plugin/design-orchestrator/**`, `plugin/dev-orchestrator/AGENT.md` et suite, `plugin/planning-core/**`, `plugin/conductor/scripts/{check-agents,check-skills,check-instruction-budget,check-role-consistency,vf-role,check-ajout-retrait,check-planning-consumers-registered}.sh`, `scripts/{check-version-sync,check-baseline-arbitrage,check-gate-touche,check-machine-paths}.sh`, `plugin/_internal/{module-roles,resolve-deps,vibeflow-update}.sh`, `plugin/installer/scripts/build-module-catalog.sh`, `docs/ADR.md` (ADR-054, ADR-071), spec `2026-09-16-equipe-produit-bmad-design.md` §4A, §5.1, §5.2, §5.4, `manual/.tools/check-manual.sh`.
- gsd-core 1.18.0 local : `bin/lib/{gap-checker,milestone,phase,markdown-sectionizer}.cjs`, `templates/requirements.md`.
- Mesures : exécutions de `check-instruction-budget.sh`, `check-version-sync.sh`, `check-skills.sh`, `check-agents.sh`, des suites listées, d'une copie jetable de `plugin/` avec un module d'essai, d'un prototype de `check-prd.sh`, de `gsd-tools requirements mark-complete`.

### Secondary (MEDIUM confidence)
- Références croisées aux mémoires du projet (mutation, grep proxifié, description repliée) : lues dans l'index de mémoire de la session, non rouvertes fichier par fichier.

### Tertiary (LOW confidence)
- Comportement de mawk 1.3.4 sur `ubuntu-latest` (non reproduit localement) : traité en contrainte conservatrice (A5).

## Metadata

**Confidence breakdown:**
- Standard stack : HIGH — aucune dépendance externe, précédents lus.
- Architecture : HIGH — moules et chemins d'installation vérifiés dans l'engine.
- Pitfalls : HIGH — quatre mesurés par exécution (SANS-BASELINE, MR-LIST/MR-REAL, 0 instruction, mark-complete) ; deux d'interprétation (A1, A2).

**Research date:** 2026-10-27
**Valid until:** 2026-11-21 (échéance du manifeste de `check-agents`) ou jusqu'à la prochaine release de gsd-core `^1`, selon le premier terme.
