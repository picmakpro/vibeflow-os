# Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate - Context

**Gathered:** 2026-10-27
**Status:** Ready for planning

Cadrage porté par `vf-dev-manager` (mission-flow §Pattern F).
- Les faits viennent d'abord de trois éclaireurs en lecture seule sur `cbe97fb1` : dépôt, spec/SEED, noms BMAD courants.
- Onze questions ont suivi, groupées en quatre zones et escaladées à la session principale par `SendMessage(main)` le 2026-10-26.
- **P59-D-01 à P59-D-12 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-27.** Les questions Q1 à Q4 ont été posées le 2026-10-26 ; la réponse est arrivée à la reprise de session, le 2026-10-27. L'option recommandée a été retenue à chaque fois.
- P59-D-13 est un fait établi (A-10 soldée), pas un arbitrage.
- **P59-D-23 : précision de Samuel, message en session principale, 2026-10-27**, relayée au manager pendant la planification.
- P59-D-14 à P59-D-22 sont laissées à la discrétion du planificateur. Ce sont des conséquences des décisions arbitrées, aucune n'ouvre un choix neuf.

**Exigences :** famille `PRDT`.
- Réservée le 2026-10-08 (`REQUIREMENTS.md`, ligne de réservation des préfixes).
- Vérifiée libre le 2026-10-26 : `PRDT-[0-9]+` donne 0 occurrence dans `.planning`, `docs` et `plugin`.
- Le planificateur la revérifie sur les branches `origin/*` avant de la poser.
- Elle est posée à l'ouverture de la planification et reformule P59-D-01 à P59-D-22 sans rien y ajouter.

<domain>
## Phase Boundary

Un module `product-team-bundle`, sur le moule de `business-pilot-bundle` (manager, workers cloisonnés, juge frais), avec une front door `vibeflow-product` sur le moule de `vibeflow-design` (AGENT.md incarné par un skill, jamais en Task).

Le rôle Product produit deux choses :
- `BRIEF.md`, le seul fichier nouveau (A-06) ;
- le PRD, c'est-à-dire `PROJECT.md` + `REQUIREMENTS.md` instanciés depuis un gabarit `product` de `planning-core`.

Le juge frais `prd-gate` (lecture seule, rubric /100) note le BRIEF et le PRD. Il s'adosse à un script déterministe pour l'éliminatoire « exigence sans critère d'acceptation ».

`vibeflow-head` lit le poste par `vf-role.sh get` (P58-D-15). Au poste `product`, il redirige vers `/vf-product` au lieu de dispatcher `vf-coder` (A-05).

**Un poste est une vue, pas un droit** (spec §5.1, ADR-077). La doc du bundle le dit dès sa première ligne.

Hors de cette phase :
- un fichier `PRD.md` séparé (A-06) ;
- les termes « epic » et « story » (Q-11, fermée par doctrine) ;
- le worker architecte, `ARCHITECTURE.md` et le gate architecture, ainsi que le refus de découpage par le head (Phase 60, A-08) ;
- le marqueur de phase proposée et `check-phase-validation.sh` (Phase 60, A-07) ;
- le champ `role:` des registres et la preuve à deux humains (Phase 61) ;
- l'`UI-SPEC` écrite en binôme avec le design (spec §5.1 ; pas dans la fiche 59) ;
- un preset produit (P59-D-12) ;
- la release racine (P59-D-12 ; levée par l'arbitrage Samuel, AskUserQuestion session principale, 2026-10-29, voir l'amendement de P59-D-12).

</domain>

<decisions>
## Implementation Decisions

### Composition et noms

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

### BRIEF, PRD, juge

- **P59-D-03 (gabarit `product`, Q3) :** le gabarit vit dans `planning-core`, comme une dimension « poste » orthogonale à la rigueur. Il ne devient pas un 4ᵉ niveau à côté de Léger, Standard et Complet : RQ-EP-03 est tranchée en faveur d'une dimension.
  - Contenu : nouveaux fichiers PROJECT et REQUIREMENTS produit.
  - Le gabarit REQUIREMENTS produit ajoute un **critère d'acceptation** et une **priorité** à chaque exigence.
  - Il garde la forme de ligne que GSD sait lire (`- [ ] **ID**: …`), pour que le dev reprenne la main sans conversion.
  - **Phase 45 de Willy :** elle touche aussi `planning-core` (`module.json`, `VERSION`, `CHANGELOG`, hook). Ce n'est PAS un préalable : voir P59-D-23, qui remplace la consigne de rebase initiale.
    - La 59 n'ajoute que des fichiers neufs dans `planning-core`, plus le bump et le changelog.
- **P59-D-04 (BRIEF, Q4) :** `.planning/BRIEF.md`, à côté de `PROJECT.md`. Il est de niveau produit, y compris dans un lab partitionné.
  - Cinq rubriques (spec §5.2) : problème, utilisateurs, valeur, contraintes, hors périmètre.
  - Le BRIEF est court et lisible sans être dev.
- **P59-D-05 (seuil, Q5) :** `prd-gate` passe à 80/100 **et** aucun éliminatoire déclenché, comme les juges des bundles (`quality-gate-client`, « 79 n'est pas 80 »). Deux éliminatoires :
  1. une exigence sans critère d'acceptation ;
  2. un BRIEF auquel il manque l'une de ses cinq rubriques.
- **P59-D-06 (vérification, Q6) :** juge LLM **et** script déterministe `check-prd.sh`, que le juge appelle.
  - Le script rougit sur l'éliminatoire 1, et sur l'éliminatoire 2 s'il est mesurable mécaniquement.
  - Il naît avec ses trois issues et sa mutation rouge prouvée, en forme exec (QUAL-01, ADR-071).
  - Motif : sans lui, l'éliminatoire serait un vert auto-déclaré.
- **P59-D-07 (PRD sous le seuil, Q7) :** halte remontée à l'humain (ADR-031).
  - La main ne repasse au head qu'au-dessus du seuil, ou sur un override humain explicite que le rapport trace.
  - Aucun refus mécanique côté head : le refus de découpage est en Phase 60.

### Head et visibilité

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

### Exposition et sobriété

- **P59-D-11 (Q-09, Q11) :** `proposable:false` jusqu'à un run réel complet (BRIEF → PRD → `prd-gate` ≥ seuil) sur un lab que Samuel désigne.
  - La bascule à `true` se fait dans une PR tracée, hors de cette phase.
  - Trailer `Ajout-Retrait` du nouveau `SKILL.md` (et du `check-prd.sh`) : « aucun : capacité de jalon inscrite (SEED-001, ROADMAP 59) ».
  - Fait à documenter : l'engine ignore `proposable`. `install --all` et une install nominale posent quand même le module ; seuls le catalogue et les presets l'excluent.
- **P59-D-12 (hypothèses par défaut, validées « Je valide ») :**
  - au plus **250 lignes** par agent neuf (critère 5 du jalon, plus strict que les 300 de l'ADR-029) ;
  - bump des modules touchés dans la PR, sans `VERSION` racine ni release (v2.72.0 décidée à part) ; **amendé :** la release v2.72.0 est autorisée (arbitrage Samuel, AskUserQuestion session principale, 2026-10-29 : merger #172 avec --admin si les juges ne rendent aucun majeur et que la CI est verte, puis tag et release v2.72.0) ;
  - pas de preset produit (`resolve-preset.sh` refuse un module `proposable:false`) ;
  - `PROJECT.md` racine périmé et table Coverage de `REQUIREMENTS.md` sans DLWS ni RLPO : en dette, hors 59.

- **P59-D-23 (Phase 45 non bloquante ; précision de Samuel, message en session principale, 2026-10-27 : « pas besoin de prévenir Willy + on attend pas sa phase pour merge et release ») :**
  - aucune coordination avec Willy n'est requise ;
  - la Phase 45 du compartiment `gouvernance` n'est pas un préalable : pas de rebase sur elle, et elle n'est citée nulle part comme bloquante ;
  - la PR 59 se merge et se releasera sur `main` telle quelle.
  - Cette décision précise P59-D-03 sans en changer le fond : le gabarit reste dans `planning-core`.

### Fait établi (pas un arbitrage)

- **P59-D-13 (A-10 soldée) :** noms BMAD courants lus sur `bmad-code-org/BMAD-METHOD` v6.12.4 (2026-10-14) : `bmad-agent-analyst` (brief produit), `bmad-agent-pm` (PRD), `bmad-agent-architect`, `bmad-agent-ux-designer` (`ux-expert` est un nom de la v4). `vf-product-analyst` et `vf-product-pm` restent alignés, sans renommage.

### Claude's Discretion (conséquences, aucun choix neuf)

- **P59-D-14 (rubric) :** le planificateur répartit les 100 points.
  - Pistes : BRIEF complet et lisible, exigences vérifiables, critères d'acceptation testables, priorités posées, traçabilité BRIEF → exigences.
  - Format de verdict aligné sur les juges des bundles : JSON `score`, `eliminatoire`, `detail{}`, et bloc typé du team-kernel.
  - `prd-gate` reprend le frontmatter des juges : outils Read, Glob, Grep, Bash (pour `check-prd.sh`) ; `disallowedTools: Write, Edit` ; `omitClaudeMd: true` (invariant I5) ; `vf-internal: true`, avec le marqueur « Worker interne » dans la description (I1).
- **P59-D-15 (`check-prd.sh`) :** il vit dans `plugin/product-team-bundle/scripts/`.
  - Il lit `.planning/REQUIREMENTS.md` (et `.planning/BRIEF.md`) du lab.
  - Bash portable (ADR-054). Codes de sortie documentés : vert, rouge, indéterminé ou illisible.
  - Le planificateur vérifie s'il tombe sous `check-planning-consumers-registered.sh` (un `.sh` qui cite `.planning/` suivi de REQUIREMENTS). Si oui, il l'enregistre.
- **P59-D-16 (lien gabarit ↔ poste) :** le planificateur décide comment `vf-planning` choisit le gabarit `product` (poste lu par `vf-role.sh`, ou choix explicite du bundle).
  - Les gabarits existants restent intacts à l'octet pour les postes `solo` et `dev`.
- **P59-D-17 (passage de main) :** au-dessus du seuil, le rapport de `vf-product-manager` propose le next step au head (découpage par le dev), sans le lancer.
- **P59-D-18 (suite de tests) :** `test-product-team-bundle.sh` dans le bundle, sur le modèle de `test-business-pilot-bundle.sh`. Elle est découverte automatiquement.
  - Elle couvre : `proposable:false`, `roles`, `requires`, frontmatters, lignes ≤ 250, `check-prd.sh` (vert, rouge, mutation).
  - Le test de `test-build-module-catalog.sh` qui boucle en dur sur les trois bundles `true` est adapté pour exclure `product-team-bundle`, avec `Gate-Touche` si c'est une suite surveillée.
- **P59-D-19 (registres) :**
  - une ligne par agent neuf dans `.planning/instruction-budget-baselines.tsv` (sinon rc 2, SANS-BASELINE) ;
  - rafraîchissement de `check-agents-manifest.json` si `--manifest-freshness=strict` l'exige ;
  - triade `VERSION` ↔ `module.json` ;
  - compteur de modules 17 → 18 dans les badges et la phrase « N modules » de `README.md` et `README.fr.md` ;
  - pages du manuel FR et EN qui listent les bundles, les skills et les agents.
- **P59-D-20 (head) :** la redirection s'insère dans la carte d'intention et le garde-fou de premier usage de `dev-orchestrator/AGENT.md`, ou dans une référence chargée à la demande, selon P59-D-09.
  - `test-dev-orchestrator.sh` T37 (aucun `gsd-*` dans la colonne équipe) et T3/T5 (≤ 300 lignes) restent verts.
- **P59-D-21 (versions) :**
  - `product-team-bundle` naît en `v1.0.0` ;
  - bump minor de `planning-core` (nouveau gabarit) et de `dev-orchestrator` (nouvelle capacité du head) ;
  - lire le `VERSION` réel au moment du bump, jamais une valeur écrite dans un plan.
- **P59-D-22 (doc) :** le README du bundle, FR d'abord, ouvre sur « Un poste est une vue, pas un droit ».
  - Il dit `proposable:false` et le déclencheur de bascule.
  - Il dit que l'engine pose quand même le module sur `install --all`.

</decisions>

<canonical_refs>
## Canonical References

### Doctrine et cahier des charges
- `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md` : §4A (l.101-109), §5.1 (l.148-156), §5.2 (l.165-179), §5.4 (l.207-209), §5.5, §6, §9 critères 3 et 5.
- `.planning/seeds/SEED-001-equipe-produit-v1.md` : A-02, A-04, A-05, A-06, A-07, A-08, A-10 (l.40-57), recherche BMAD (l.63-82).
- `.planning/workstreams/fiabilite/ROADMAP.md` : § Phase 59, contraintes du jalon (collision `planning-core`, QUAL-01, critère 1 amendé).
- Phase 58 : `.planning/workstreams/fiabilite/phases/VFDO-58-*/58-CONTEXT.md`, en particulier P58-D-03, D-05, D-06, D-10, D-15, D-17, D-18, D-21.
- `docs/ADR.md` : ADR-029, ADR-031, ADR-044, ADR-053, ADR-071, ADR-072, ADR-077.

### Code
- Moule bundle : `plugin/business-pilot-bundle/`, dont `module.json`, `agents/quality-gate-client.md` (juge 80/100 et éliminatoires) et `scripts/tests/test-business-pilot-bundle.sh`.
- Moule front door : `plugin/design-orchestrator/` : `AGENT.md` (193 l.), `skills/vf-design/SKILL.md`, `agents/vf-design-manager.md`, `agents/vf-design-judge.md`.
- Poste : `plugin/conductor/scripts/vf-role.sh`, `plugin/_internal/module-roles.sh`, `plugin/_internal/resolve-preset.sh`.
- Visibilité : `plugin/installer/scripts/build-module-catalog.sh:82-90`, `plugin/installer/SKILL.md:125,198`.
- Pose : `plugin/_internal/vibeflow-update.sh` (AGENT.md vers `.claude/agents/<module>.md` l.2534-2536, commande générée l.2707-2708, `content/` vers `docs/<mod>/`).
- Gabarits : `plugin/planning-core/references/templates/`, `PROFILES.md`, `skills/.../SKILL.md` Séquence A.
- Head : `plugin/dev-orchestrator/AGENT.md`, carte d'intention l.46-77 et garde-fou de premier usage l.31-44.
- Gates : `.github/workflows/ci.yml` (jobs `gates` et `tests`), `check-agents.sh` (I1, I2, I5, I6, monde fermé), `check-skills.sh`, `check-instruction-budget.sh` et `.planning/instruction-budget-baselines.tsv`, `scripts/check-version-sync.sh`, `check-ajout-retrait.sh`, `check-gate-touche.sh`, `check-baseline-arbitrage.sh`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Le team-kernel (`conductor-references/team-kernel.md`) fournit le contrat de bloc typé, le DAG, le verrou et le digest : le manager produit les reprend sans les réimplémenter.
- `vf-role.sh get` : contrat stable (0, 1, 5, 64).
- `quality-gate-client` : modèle de juge 80/100 avec éliminatoires.

### Established Patterns
- Front door = AGENT.md + skill qui l'incarne en session principale. Elle propose le manager, jamais d'office.
- Juge = sonnet, effort high, Write et Edit interdits, `omitClaudeMd: true`, `vf-internal: true`.
- Bundle = suffixe `-bundle` + `proposable` explicite + `content/` (BUNDLE.md, blueprints) + suite propre.

### Integration Points
- La CI joue `check-agents` sur `plugin/*/agents` (monde fermé) et sur chaque `plugin/*/AGENT.md`.
- Le catalogue et les presets filtrent `proposable` et `roles`.
- Le hook SessionStart injecte déjà « Poste : X » (P58-D-10) : aucun hook neuf.

</code_context>

<specifics>
## Specific Ideas

- `install --all` pose un module `proposable:false` : c'est un fait à écrire dans le README, pas un défaut à corriger dans la 59.
- Le manifeste `check-agents-manifest.json` périme le 2026-11-21 : le rafraîchir dans la phase s'il est touché.

</specifics>

<deferred>
## Deferred Ideas

- Worker architecte, `ARCHITECTURE.md` et gate architecture : Phase 60.
- `UI-SPEC` en binôme avec le design : à réinscrire si besoin après la 60.
- Preset produit : après la bascule `proposable:true`.
- Mise à jour de `PROJECT.md` racine et de la table Coverage (DLWS, RLPO) : dette d'hygiène hors 59.

</deferred>
