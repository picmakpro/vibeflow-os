# Requirements: VibeFlow Dev Orchestrator (VFDO)

**Defined:** 2026-06-04

> **Clôture agentique-v1.0 (2026-08-15).** Snapshot archivé :
> `.planning/milestones/agentique-v1.0-REQUIREMENTS.md`. **Déviation assumée vs le workflow
> `complete-milestone`** (qui prescrit de supprimer ce fichier après archivage) : le ledger
> complet est **conservé** — c'est l'objet même de la Phase 18 (« survie du ledger d'exigences à
> la clôture de jalon », reportée au prochain milestone) ; on ne supprime pas la chose qu'une
> phase inscrite existe pour protéger. Le prochain milestone ajoutera ses familles à la suite.
**Core Value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.

## v1 Requirements

### Routing & Agent

- [x] **ROUT-01**: L'agent `vibeflow-dev` route ≥11 intentions en langage naturel vers le bon skill GSD/superpowers (table de routage).
- [x] **ROUT-02**: L'agent embarque l'ordre canonique du pipeline GSD + bonnes pratiques (détail dans `references/GSD-PIPELINE.md`, chargé on-demand).
- [x] **ROUT-03**: L'agent ne nomme jamais « GSD » à l'utilisateur et reframe les sorties en vocabulaire VibeFlow.
- [x] **ROUT-04**: L'agent est distribué via `AGENT.md` et installé en `.claude/agents/dev-orchestrator.md` par `vibeflow-update.sh`.

### Index GSD

- [x] **IDX-01**: `build-gsd-index.sh` parse les `SKILL.md` des skills `gsd-*` installés → `references/gsd-skills-index.md` (factuel uniquement, aucun nom inventé).
- [x] **IDX-02**: L'index se régénère à l'install/update du module et lors d'un drift GSD détecté.

### Abstraction

- [x] **ABS-01**: Un set complet de commandes `/vf-*` mappe vers GSD/superpowers/bootstrap, invocables par l'utilisateur ET par l'agent en autonomie.
- [x] **ABS-02**: Une traduction de vocabulaire masque les termes GSD (ex. « SUMMARY » → « rapport de sprint »).

### Bootstrap auto-install

- [x] **BOOT-01**: `ensure-deps.sh` installe GSD en non-interactif si absent (`npx -y get-shit-done-cc@latest --claude --global`).
- [x] **BOOT-02**: `ensure-deps.sh` installe Superpowers en non-interactif si absent (`claude plugin install superpowers@claude-plugins-official --scope user`).
- [x] **BOOT-03**: `ensure-deps.sh` est idempotent, vérifie les exit codes, et affiche les étapes manuelles uniquement si un prérequis (Node/npm ou CLI `claude`) manque.
- [x] **BOOT-04**: `gsd-new-project` (interactif) ne se lance jamais seul ; l'agent propose l'init sur confirmation ; `map-codebase` peut tourner auto si du code existe.

### Vérification

- [x] **VERIF-01**: `tests/test-dev-orchestrator.sh` couvre génération d'index, idempotence de `ensure-deps`, couverture du routage, mapping `/vf-*` non orphelin.
- [x] **VERIF-02**: Gates de densité respectés (agent ≤250L, skills ≤500L), vérifiés par `wc -l` dans le test du module (`check-file-size.sh` n'audite pas les `.md` : regex code sans `.md`).

## Milestone 2 — Install UX (shipped `v2.4.0`, 2026-06-05)

> Spec : `docs/superpowers/specs/2026-06-04-install-ux-design.md`

### Manifeste & résolveur (Phase 2)

- [x] **MANIF-01**: Chaque module a un `module.json` (name, version, type, description, `requires[]`) — source machine-lisible.
- [x] **MANIF-02**: Un résolveur calcule la fermeture transitive des `requires` (ex. validator → consolidator + infrastructure-audit).

### Engine scope-aware (Phase 3)

- [x] **SCOPE-01**: `vibeflow-update.sh` accepte `--scope user|project|local` → résout `TARGET_ROOT` (`~/.claude` vs `./.claude`).
- [x] **SCOPE-02**: Source des modules = cache du plugin (plus de `git clone .vibeflow-cache`).
- [x] **SCOPE-03**: `ensure-deps.sh` scopé : GSD `--global`/`--local`, Superpowers `--scope user|project|local`.
- [x] **SCOPE-04**: Scope `local` → ajout des chemins installés au `.gitignore`.

### Skill /vibeflow-install + auto-lancement (Phase 4)

- [x] **INST-01**: Toggle scope (single-select user/project/local).
- [x] **INST-02**: Toggle modules (multi-select) avec description issue des `module.json`.
- [x] **INST-03**: Récap des dépendances auto-résolues avant install.
- [x] **INST-04**: Orchestration de l'install au scope choisi (modules + GSD + Superpowers).
- [x] **INST-05**: Hook `SessionStart` + marqueur de 1er lancement → ouvre l'UX automatiquement (ID8).

### Packaging plugin (Phase 5)

- [x] **PLUG-01**: `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` valides.
- [x] **PLUG-02**: Le plugin bundle modules + skill + engine + manifeste.
- [x] **PLUG-03**: Repo `vibeflow-os` rendu public (étape délibérée confirmée).
- [x] **PLUG-04**: `claude plugin marketplace add` + `install` fonctionnent en zéro-auth (validé).

### dev-orchestrator first-use (Phase 6)

- [x] **FIRST-01**: L'agent détecte l'absence de `.planning/` (projet non GSD-initialisé) au 1er usage.
- [x] **FIRST-02**: Il propose map-codebase puis new-project sur confirmation (jamais `gsd-new-project` seul).

## Milestone 3 — Doctrine dev & consolidation (shipped `v2.20.0`, 2026-07-07)

> Spec : `docs/superpowers/specs/2026-07-07-dev-doctrine-consolidation-design.md`
> Origine : audit du parc de modules vs `dev-orchestrator`.

### Philosophies de dev (Phase 7)

- [x] **PHIL-01**: `software-architecture/references/principles.md` existe et porte **DRY** comme contrat vérifiable (test → signal → remède), distinct de « dry-run ».
- [x] **PHIL-02**: `principles.md` porte **KISS** et **YAGNI** (frères de DRY, même format).
- [x] **PHIL-03**: **Clean Architecture** est nommée en place dans `solid-soc.md` (section couches = Dependency Rule).
- [x] **PHIL-04**: **Clean Code** est nommée en place dans `solid-soc.md` (petites unités, `Result<T>`, contrats typés).
- [x] **PHIL-05**: Une **carte TDD** (Red-Green-Refactor + quand l'appliquer) renvoie au skill canonique `superpowers:test-driven-development` / `tdd` et s'articule au Gate Nyquist — sans dupliquer la mécanique (DD3).
- [x] **PHIL-06**: `SKILL.md` câble DRY/KISS-YAGNI/Clean Code en **Tier 2** (audit de sprint), ajoute une ligne TDD en Tier 1, référence `principles.md`, et étend le frontmatter `description`. Aucun faux gate machine (DD4).
- [x] **PHIL-07**: `universal-vs-dev.md` étend la table universelle avec DRY/KISS/YAGNI (transposition non-dev).
- [x] **PHIL-08**: `software-architecture` : `module.json` (description + bump v1.2.0) + CHANGELOG + README mis à jour ; densité `.md` sous seuils ADR-029.

### Consolidation des doublons (Phase 8)

- [x] **CONS-01**: Un seul foyer de rule de gates de code — `feature-dev-gates` fusionné dans `software-architecture` (ou déprécié avec plan de migration), plus de doublon de globs.
- [x] **CONS-02**: `audit-architecture` renvoie aux modules au lieu de dupliquer (Instance C `examples-cross-domain.md:44-61`) ; sa `module.json` legacy corrigée.
- [x] **CONS-03**: Les 3 axiomes (enforcement>prose, filet fonctionnel, preuve avant done) ont une source unique + renvois.
- [x] **CONS-04**: Invariant vérifié — `dev-orchestrator` reste un pur routeur, aucune doctrine injectée (DD1).

### R&D mémoire & swarm (Phase 9)

> Spike **R&D hors chaîne de release** — décision go/no-go, aucun changement du format mémoire officiel ni du
> socle `conductor` sans ADR. Source : `.planning/research/jcode-memory-swarm-transposition-NOTE.md` (§0–5).

- [x] **RND-01**: Le frontmatter mémoire enrichi (3 gestes — `trust` high/medium/low, `confidence` 0–1 +
  règle de **décroissance par catégorie**, `superseded_by` non destructif) est prototypé sur ≥1 lab témoin et
  le `consolidator` sait le tenir à jour **automatiquement** : round-trip lit→recalcule→réécrit sans édition
  humaine, ET une entrée `superseded_by` archivée (statut basculé, contenu conservé — pas supprimée). Sinon →
  no-go documenté avec la raison.
- [x] **RND-02**: Une **note go/no-go écrite** tranche (a) écrire un ADR + toucher le format officiel, ou (b)
  archiver — avec les demi-vies de décroissance **re-calibrées** pour l'usage VibeFlow multi-métiers (pas les
  valeurs jcode brutes), ET un **mini-cadrage écrit du volet swarm** (lock de driver unique RAII + DAG
  ready/blocked), **non implémenté** tant que des collisions ne sont pas observées (ADR-048/049).

## Milestone gsd-migration — Migration package GSD (VOC-02)

### Phase 10 — Étude & faisabilité

- [x] **GSDM-01** *(2026-07-26 — `10-ETUDE.md` §1)*: La surface d'usage GSD dans VibeFlow est inventoriée exhaustivement — chaque point de
  contact (`ensure-deps.sh`, `build-gsd-index.sh`, binaire `gsd-sdk`, chemins `~/.claude/get-shit-done/`,
  pins `PROJECT.md`, hooks, références docs) listé avec le changement attendu.
- [x] **GSDM-02** *(2026-07-26 — `10-ETUDE.md` §2, sourcé npm/GitHub/tarball)*: Le package cible `@opengsd/gsd-core` est caractérisé — existence/stabilité npm, commande
  d'install non-interactive équivalente, nom du binaire, structure de dossier, parité fonctionnelle des
  skills/SDK consommés ; écarts documentés.
- [x] **GSDM-03** *(GO validé par Samuel le 2026-07-26 — `10-APPROFONDISSEMENT.md`)*: Une note go/no-go écrite tranche — (a) migrer maintenant (stratégie + fenêtre de compat),
  (b) attendre (déclencheur de resurgence explicite), ou (c) archiver.

### Phase 11 — Intégration (conditionnée au GO de la Phase 10)

- [x] **GSDM-04** *(Phase 11, 2026-07-26 — plafond `@^1`)*: `ensure-deps.sh` et les pins (`PROJECT.md`) installent `@opengsd/gsd-core` en
  non-interactif, idempotent, avec fallback manuel ; `get-shit-done-cc` n'est plus référencé.
- [x] **GSDM-05** *(Phase 11 — index 71 entrées diffé nom à nom contre le payload réel)*: L'index factuel (`build-gsd-index.sh`) est régénéré depuis le nouveau package/binaire
  (zéro hallucination) et les références docs pointent la nouvelle source.
- [x] **GSDM-06** *(Phase 11 + release `v2.39.0` taggée)*: Non-régression prouvée en isolé (dry-run 3 scopes + idempotence, vrai `~/.claude` intact) ;
  CHANGELOG/README à jour ; release bumpée + tag annoté poussé (`check-release-tag.sh --remote` → ✓).

## Milestone vf-routing — Routage fin & couverture des verbes

Spec : `docs/superpowers/specs/2026-07-25-routage-fin-verbes-vf-design.md`.

### Phase 12 — Routage fin & couverture complète des verbes `/vf-*`

> ⚠️ *Post-scriptum 2026-07-26* : ces exigences décrivent l'état **livré en v2.31.0**. La façade `/vf-*`
> (verbes + rule de préséance + table de routage vers les verbes) a été **supprimée en v2.33.0**
> (bascule agentique, spec `2026-07-25-suppression-facade-vf-design.md`) : VERB-01 est inversé (carte
> d'intention unique, l'agent invoque les briques directement), les verbes de VERB-02 et l'artefact de
> VERB-04 n'existent plus sur disque, la suite de tests a été refondue (26 OK). Les cases restent
> cochées au titre de l'historique de livraison.

- [x] **VERB-01**: La table de routage de `AGENT.md` mappe chaque intention vers un **verbe `/vf-*`**
  (plus aucune cible `gsd-*` en entrée de chaîne) ; `AGENT.md` reste ≤ 250 L.
- [~] **VERB-02** *(partiel — 17/18, `vf-ingest` soldé en Phase 13)*: 18 nouveaux verbes `/vf-*` sont livrés dans `dev-orchestrator` (`vf-secure`, `vf-testgen`,
  `vf-gaps`, `vf-forensics`, `vf-inbox`, `vf-milestone`, `vf-phase`, `vf-undo`, `vf-backlog`, `vf-cleanup`,
  `vf-resume`, `vf-pause`, `vf-docs`, `vf-learn`, `vf-explore`, `vf-spike`, `vf-spec`, `vf-ingest`) + `vf-sketch`
  dans `design-orchestrator` ; chacun délègue à une cible GSD existante, aucun ne réimplémente sa logique.
- [x] **VERB-03**: Les 32 descriptions de skills (14 réécrites + 18 nouvelles) suivent le gabarit déclencheur —
  formulations FR réelles + contre-exemples nommant les verbes voisins ; les 5 groupes de collision identifiés
  sont démarqués.
- [x] **VERB-04**: Une rule de préséance globale (`rules/vf-verb-precedence.md`, ≤ 40 L, sans `paths:`) est
  livrée et installée en `.claude/rules/` : aucun skill `gsd-*` ni `superpowers:*` n'est invoqué en entrée de
  chaîne ni nommé à l'utilisateur.
- [x] **VERB-05**: `references/intent-routing.md` couvre **100 %** des skills listés dans
  `gsd-skills-index.md` (chargé on-demand) ; les tests du module passent, fixture T4 étendue aux nouvelles
  cibles + T12 (anti-collision), T13 (préséance), T14 (exhaustivité) — numérotation tranchée en
  12-CONTEXT D-03 (`T11` déjà pris par l'axe de généricité).

### Phase 13 — Pont spec → feuille de route

> Redéfinie le 2026-07-26 : la façade `/vf-*` ayant été supprimée (v2.33.0, bascule agentique), la
> capacité d'ingestion est portée par l'agent `vibeflow-dev` — pas de verbe `/vf-ingest`.

- [x] **BRDG-01**: L'agent `vibeflow-dev` intègre une spec `docs/superpowers/specs/*.md` à la feuille de
  route via `gsd-ingest-docs --mode merge` (étapes + exigences), et un plan `docs/superpowers/plans/*.md`
  via `gsd-import --from` — sans réimplémenter ni contourner les moteurs.
- [x] **BRDG-02**: La découverte des specs/plans **non encore intégrés** est outillée
  (`discover-unintegrated-docs.sh` : chemin non cité dans les 6 registres — ROADMAP, REQUIREMENTS,
  MILESTONES, PROJECT, `milestones/*.md`, `docs/ADR.md` —, détection du grain spec vs plan) ; l'agent
  construit le manifest YAML attendu par le moteur — l'utilisateur n'écrit aucun manifest à la main.
- [x] **BRDG-03**: Les garde-fous sont préservés et vérifiés : gate BLOCKER jamais contourné, confirmation
  humaine avant toute écriture dans `.planning/` (ADR-031), `--mode merge` par défaut sur projet existant,
  cap 50 documents signalé ; en fin de cadrage, l'agent propose l'ingestion comme next step.
  *Réserve (2026-07-26)* : les 4 garde-fous sont **doctrinaux** — leur présence textuelle est prouvée
  (axe T16), leur respect à l'exécution ne l'est pas et ne peut pas l'être par grep. L'audit a relevé
  que la confirmation humaine est ancrée à `vibeflow-dev` seul : `vf-dev-manager` (chemin équipe) n'a
  pas de ligne nominative sur l'ingestion, contrairement au patron appliqué aux skills de clôture de
  milestone. **Arbitrage doctrinal remonté à l'humain**, non tranché en mission.

### Phase 14 — Frontière d'altitude `planning-core` / moteur GSD

Spec : `docs/superpowers/specs/2026-07-25-rescope-vf-planning-gsd-design.md`. ADR-055.

- [x] **ALTI-01**: `scripts/detect-gsd-engine.sh` répond au **fait** « un moteur de planning GSD est-il en
  place ? » via 4 exits évalués par ordre de priorité (1 chaîne absente, 0 moteur actif, 2 migration à
  examiner, 3 terrain libre). Il **n'infère aucun métier** — les signaux de code déclenchent un examen, jamais
  un verdict ; 10 cas de test passent, dont la primauté du marqueur GSD sur les signaux de code.
- [x] **ALTI-02**: La description de `vf-planning` ne revendique plus aucune intention de projet dev
  (« feuille de route », « où en est-on ») et nomme ses voisins en contre-exemples (`/vf-init`,
  `/vf-progress`, `/vf-plan`, `/vf-map`) ; le SKILL porte une étape 0 de branchement (fait + jugement) et deux
  séquences — A (socle universel non-dev) et B (couche lab). Sur un lab dev, **aucun** artefact de projet
  (`PROJECT`, `ROADMAP`, `REQUIREMENTS`, `STATE`, `phases/`) n'est généré.
- [x] **ALTI-03**: La double injection `SessionStart` est terminée : le flag `--defer-to-gsd` (opt-in, câblé
  dans `hooks/hooks.json` uniquement) fait taire `check-planning-state.sh` et `planning-context.sh` sous
  moteur GSD. Le comportement **par défaut** de ces scripts est inchangé (usage manuel et `/checkpoint`
  intacts) et l'`INDEX.md` du lab reste injecté — c'est de l'altitude lab, GSD ne le produit pas.
- [x] **ALTI-04**: La doctrine est tracée et outillée : `references/gsd-handoff.md` (test unique, table
  intention → verbe, périmètre résiduel, protocole de migration), `domain-detection.md` amendé (le métier
  reste du jugement), commande `/vf-planning` alignée, ADR-055 au registre. `guard-planning-updated.sh` reste
  **bloquant** (exception motivée) et aucun `.planning/` existant n'est jamais réécrit (ADR-031).
- [x] **ALTI-05**: Non-régression prouvée : les 4 bundles non-dev (`content`, `business-pilot`, `growth`,
  `kpi-analyst`) passent par la séquence A sans changement, la suite de tests du module est verte,
  `check-agents.sh` OK, JSON valides ; release bumpée (module v2.4.0, racine v2.30.0) + **tag annoté poussé**
  (`scripts/check-release-tag.sh --remote` → ✓).

## Hors-milestone — Phase 22 : hygiène documentaire (doctrine de sortie et captation d'intention)

> **IDs proposés au plan du 2026-07-31**, préfixe `DOCF` (doctrine documentaire de sortie) — aucun
> préfixe existant du ledger ne couvrait ce périmètre. La ROADMAP portait `TBD (à mapper au ledger
> pendant le plan)`.
>
> *Note de continuité* : les Phases 15 à 21 ont été livrées **sans requirements GSD**, comme les
> releases `v2.32.0 → v2.36.1` — tracées dans `MILESTONES.md` et `docs/ADR.md`. La Phase 22 rouvre
> le ledger sans rétro-documenter ces phases.
>
> Source : `.planning/phases/VFDO-22-hygi-ne-documentaire-doctrine-de-sortie-et-captation-d-inten/22-CONTEXT.md`
> (D-01 → D-14, tranchés par Samuel en conversation).

- [x] **DOCF-01**: `plugin/dev-orchestrator/references/docs-flow.md` existe, symétrique
  d'`ingestion-flow.md` (même module, même chargement on-demand, même chemin d'install D7). Il
  traite **en propre** les familles produit / code / savoir et **RENVOIE** vers `ingestion-flow.md`
  pour l'entrée — jamais de duplication (ADR-057). Il écrit noir sur blanc la frontière
  `vibeflow-os` : ce dépôt maintient une triade par module sous gates machine, `gsd-docs-update` ne
  doit jamais y être lancé. *(D-01, D-02)*
- [x] **DOCF-02**: Le régime de confirmation est **gradué par le risque réel, pas par le volume** :
  `--verify-only` est libre (read-only, n'écrit rien, ne commite rien) ; la génération standard
  exige une confirmation humaine explicite avant l'appel (ADR-031) ; en mission autonome, l'agent
  **constate et consigne, jamais n'écrit**. *(D-03, D-04)*
- [x] **DOCF-03**: `--force` est **autorisé sur intention explicite de l'utilisateur** (arbitrage de
  Samuel contre la recommandation) et borné par un garde-fou en trois temps : reformulation du
  nombre **et** de la liste des docs manuscrites qui seront écrasées (dérivée d'`existing_docs`,
  `has_gsd_marker` faux = travail humain à risque), attente d'un oui explicite, et interdiction en
  mission d'équipe **et** en mode autonome. *(D-05, D-06)*
- [x] **DOCF-04**: La captation d'intention couvre les quatre familles avec les formulations réelles
  de l'utilisateur ; `--verify-only` et `--force` ont **chacun** leur formulation déclencheuse dans
  `intent-routing.md` — auditer et régénérer ne sont plus indiscernables. La désambiguïsation se
  fait par ancrage contextuel, et par une **question courte** quand aucun ancrage ne tombe, jamais
  par une devinette. *(D-10, D-12)*
- [x] **DOCF-05**: `vf-dev-manager` et `vf-design-manager` posent **UN** nœud `docs` agrégé en fin
  de mission (`deps` = tous les nœuds d'exécution), dès qu'au moins un des quatre déclencheurs
  constatables tombe — surface publique touchée · `[doc-drift]` actif · fin de milestone · nouveau
  module ou capacité. Aucun déclencheur ne tombe → pas de nœud, état normal. Aucun format de
  rapport nouveau n'est introduit. Le gate `DESIGN.md` du manager design reste distinct. *(D-07,
  D-08, D-09, D-11)*
- [x] **DOCF-06**: La doctrine est non-régressable : `test-dev-orchestrator.sh` est **étendu** (blocs
  T22 et T23, plus `docs-flow.md` dans la boucle d'install T6), jamais dupliqué en suite séparée ;
  le test d'exhaustivité de routage T14 reste vert ; `check-doc-drift.sh` reste **bit-à-bit
  inchangé** — il constate le seul fait qu'il sait produire, c'est la doctrine qui gradue la
  réponse (ADR-055 §3). *(D-13, D-14)*
- [x] **DOCF-07**: Les deux modules touchés sont bumpés en **minor** (nouvelle capacité) avec leur
  triade complète (`VERSION` ↔ `module.json` ↔ en-tête README) et leur CHANGELOG ;
  `check-version-sync.sh` sort ✓. La **release racine** (`VERSION`, `plugin.json`,
  `marketplace.json`, les deux README, tag annoté, release GitHub) reste **hors périmètre**,
  réservée à validation humaine — patron des Phases 13, 17 et 19.

## Hors-milestone — Phase 23 : couplage explicite au moteur GSD (capabilities, flags, voie unique)

> **IDs proposés au plan du 2026-08-01**, préfixe `GSDC` (« GSD Coupling ») — aucun préfixe existant
> du ledger ne couvrait ce périmètre. La ROADMAP portait `TBD (à mapper au ledger pendant le plan)`,
> comme la Phase 22 avant elle.
>
> Source : `.planning/phases/VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-/23-CONTEXT.md`
> (D-00 → D-31, tranchés par Samuel en conversation, `23-DISCUSSION-LOG.md`), recoupés sur pièce par
> `23-RESEARCH.md` contre `@opengsd/gsd-core@1.9.0` **installé**.
>
> **Ordre imposé** (ROADMAP + D-31) : la Lacune 6 (sûreté du contrat de checkpoint) passe avant la
> Lacune 3 (doctrine de flags), qui passe avant la Lacune 2 (voie unique). Le découpage se fait en
> **plans**, pas en phases.

- [x] **GSDC-01**: Le contrat de checkpoint amont est relayé, jamais recalculé : le bloc typé porte
  un champ `gate` optionnel (présent dès qu'un checkpoint est survenu, recopié verbatim) et **une
  seule règle** de mapping — `gate="blocking-human"` **OU** précondition amont non satisfaite ⇒
  statut `human_needed`. Le bloc porte aussi le **minimum de reprise** (`plan_id`, type de
  checkpoint, `gate`, attendu) et **rien de plus** : le contrat de retour interne de l'exécuteur
  n'est jamais dupliqué côté VibeFlow (ADR-030). En mission autonome le gate bloquant fige le
  **nœud**, pas la mission ; c'est `vf-dev-manager` (porteur d'`AskUserQuestion`) qui répond aux
  attentes humaines, jamais `vf-coder`. *(D-01, D-03, D-04, D-04bis, D-10, D-29)*
- [x] **GSDC-02**: `workflow._auto_chain_active` est remis à `false` en geste de démarrage de
  mission, et `test-dev-orchestrator.sh` échoue si un fichier d'agent ou de référence du module
  prescrit le mode d'enchaînement autonome sur la brique de plan ou d'exécution — il reste licite
  sur la brique de cadrage. Discriminance prouvée par mutation, balayage excluant `scripts/tests/`.
  *(D-02)*
- [x] **GSDC-03**: `GSD-PIPELINE.md` porte une **doctrine de flags de cycle en allowlist stricte** :
  seuls les flags nommés sont utilisables, tout le reste est fermé par défaut **y compris les flags
  futurs de `gsd-core`** ; la recherche est graduée sur un critère **factuel** (ADR-055 §3) ; la
  distinction toggle de capability / flag de ligne de commande est écrite ; un renvoi croisé pointe
  `docs-flow.md` pour la famille documentaire, sans jamais la dupliquer (ADR-057). Le cycle
  canonique dit **pourquoi** `gsd-ship` n'est pas emprunté ici (ADR-059/ADR-064). *(D-05, D-06,
  D-08, D-21)*
- [x] **GSDC-04**: La table capabilities/hooks est **GÉNÉRÉE** depuis le moteur installé
  (`build-gsd-capabilities-index.sh` → `references/gsd-capabilities-index.md`, patron
  `build-gsd-index.sh`), couvre les **12** points de hook — liste **découverte** depuis le registre
  amont, jamais écrite en dur —, ne recopie aucun champ de prose destiné au modèle, ne fige aucune
  version, et se régénère à l'install/update (patron IDX-02). *(D-07)*
- [x] **GSDC-05**: **Voie unique** d'invocation des briques de cycle : les mentions de dispatch
  direct d'agent nu disparaissent du corps de prompt de `vf-coder`, et `gsd-planner`/`gsd-executor`
  sortent de sa ligne `tools:` **ainsi que** de celle de `vf-dev-manager` (arbitrage du planner sur
  le Finding 1 du RESEARCH, lecture littérale de D-09 ; l'audit complet des 20+ entrées reste
  différé). Aucune trace textuelle des noms retirés ne subsiste dans les fichiers d'agents. Gate
  machine à discriminance prouvée par mutation, `check-agents.sh --strict` vert (ADR-044).
  *(D-09, D-11, D-12, Finding 1)*
- [x] **GSDC-06**: L'arbitrage des doublons d'étage est écrit **en extension d'ADR-061** (troisième
  objet revu, mêmes 3 axes) : hook de revue de code *vs* nœud `revue-N`, et hook `secure-phase` *vs*
  `vf-auditer` dont le delta factuel est le recoupement avec `CONCERNS.md` — que le hook **ne peut
  pas** produire. Le bloc typé porte les **verdicts déjà rendus** par les hooks
  (`pass|fail|absent`), et le fait dimensionnant est écrit : un seul appel du skill d'exécution
  déclenche revue + nyquist + sécurité. Le critère ne vit qu'à un endroit (assertion négative).
  *(D-13, D-14, D-15, D-16)*
- [x] **GSDC-07**: `check-gsd-config.sh` (module `dev-orchestrator`) signale, sur **n'importe quel
  lab**, les clés inconnues du moteur installé et les toggles de cycle laissés au défaut implicite ;
  il lit ses clés connues **depuis `gsd-core`** (union `VALID_CONFIG_KEYS` ∪ `configKeys`) donc ne
  périme pas ; contrat **advisory** exit 0/3/64, patron `check-doc-drift.sh`, câblé `SessionStart`
  avec `|| true`, jamais bloquant en CI. Les blocs `gates`/`safety` sont **supprimés** du
  `.planning/config.json` de ce lab et les 5 toggles arbitrés y sont écrits à une valeur décidée,
  `ui_review` traité comme **absent en amont** et jamais comme faux. *(D-17, D-18, D-19, D-20,
  Finding 2)*
- [~] **GSDC-08** *(partiel — volet dispatch couvert, volet allowlist ouvert sur `D-22`)*: Quatre briques dormantes reçoivent un **moment déclencheur** écrit dans
  `mission-flow.md`, au gabarit `Déclencheur | Constat` de la Phase 22, chaque ligne un FAIT
  constatable (`gsd-extract-learnings`, `gsd-add-tests`, `gsd-spec-phase`,
  `gsd-undo`/`gsd-forensics`). Le manager **ne debug pas** : il redispatche `vf-coder` en mandat de
  debug, qui invoque le **skill** `gsd-debug` — aucun agent nu de debug en allowlist, aucune
  exception à la voie unique. *(D-22, D-23, D-24)*
- [x] **GSDC-09**: Le budget de tours devient **UN** budget par **ÉTAPE**, partagé entre la boucle de
  revue et la boucle de comblement (fermeture du contournement par renommage du problème) ; sa
  **valeur ne change pas** (D-25). Budget épuisé ⇒ statut `blocked` **+ décompte complet** (tours
  par boucle, findings non résolus), sans proposition de next step jointe. L'invisibilité du coût
  `node_repair` consommé à l'intérieur d'un plan est **écrite comme un fait sourcé**, jamais
  compensée par un total agrégé inventé (D-26, verdict du RESEARCH : le journal amont est de la
  prose libre, aucun champ structuré). *(D-25, D-26, D-27, D-28)*
- [x] **GSDC-10**: Le module `dev-orchestrator` est bumpé en **minor** (nouvelle capacité) avec sa
  triade complète (`VERSION` ↔ `module.json` ↔ en-tête README) et son CHANGELOG écrit depuis les
  SUMMARY ; le compteur « N suites » des deux README racine est remis d'équerre (46 → 47, précédent
  21-05) et `check-version-sync.sh` sort ✓ ; les gates de sortie sont **rejoués** et consignés. La
  **release racine** (`VERSION`, `plugin.json`, `marketplace.json`, badges, historiques, tag annoté,
  release GitHub) reste **hors périmètre**, réservée à validation humaine — patron des Phases 13,
  17, 19 et 22.

## Hors-milestone — Phase 24 : activation et mesure du moteur GSD (capacités dormantes, faits de runtime)

> **IDs proposés au plan du 2026-08-04**, préfixe `GSDA` (« GSD Activation ») — **distinct de
> `GSDC`** (Phase 23, couplage) : la 23 rend le couplage explicite, la 24 décide quoi activer
> dedans. La ROADMAP portait `TBD (à mapper au ledger pendant le plan)`.
>
> Source : `24-CONTEXT.md` (fiches de fait F-01 → F-38) et **`24-ARBITRAGES.md` arbitré par Samuel le
> 2026-08-04** — les **verdicts** priment sur les recommandations du cadrage, une seule inversion
> (zone 5 : adoption des workstreams, contre la recommandation D). Faits web refermés dans
> `.planning/missions/2026-08-04-phase-24-activation-moteur-gsd.md`.
>
> **Ordre imposé** : `GSDA-01` (montée de `@opengsd/gsd-core`) était un **prérequis dur** de
> `GSDA-04`/`GSDA-05` — le bug amont #2893 détruit la prose sous le ledger de `WINDOWS.md` et
> rapporte `ok: true`. Le lot MESURE (zone 6) et le lot workstreams (zone 5) n'en dépendent pas.
>
> **Gate relâché le 2026-08-04 (ADR-066)** : aucune version npm > 1.9.1 n'existe (le correctif de
> #2893 est postérieur à la dernière publication), et `WINDOWS.md` ne porte aucune prose sous son
> ledger — le risque protégé est absent de ce dépôt. Le `waive` a été répété sur une copie jetable
> avant d'être appliqué, fichier committé avant, intégrité vérifiée après : 87 lignes et miroir JSON
> intacts. `GSDA-04`/`GSDA-05` sont donc **activés**, pas différés.

- [x] **GSDA-01**: La version de `@opengsd/gsd-core` sous laquelle la zone 2 s'active est
  **déterminée contre le registre npm** et porte le correctif de l'issue amont **#2893** (`windows
  append` détruit la prose sous le ledger JSON et rapporte `ok: true` ; PR #2975 mergée le
  2026-08-01, **après** la publication de 1.9.1 le 2026-07-31). Si aucune version publiée ne porte
  le correctif, la zone 2 est **explicitement différée** avec un **déclencheur de reprise objectif**
  (publication d'une version portant le correctif), **jamais** activée sur une version vulnérable —
  et jamais silencieusement abandonnée. *(prérequis dur, verdict zone 2)*
- [x] **GSDA-02**: Le slot `AGENT_SKILLS_PLANNER` est peuplé dans `.planning/config.json` : la
  doctrine de dev du lab atteint `gsd-planner`. La portée réelle est **écrite telle quelle** — la
  doctrine atteint le **plan**, **pas l'exécution** ; A2 n'est **plus jamais** présenté comme résolu
  côté exécuteur (le slot `EXECUTOR` n'est pas atteignable : `gsd-executor` est hors de l'allowlist
  de `vf-coder` depuis la Phase 23, et le repli inline n'injecte rien). *(A2, verdict zone 1)*
- [x] **GSDA-03**: `workflow.tdd_mode` reste `false`, **refus écrit** avec son motif mesuré :
  `references/tdd.md` (330 l.) est **déjà injecté sans condition** (`execute-phase.md:693`) et le
  toggle n'ajoute qu'un tag `type: tdd` plus un gate `execute:post` **non bloquant**
  (`onError: skip`) ; l'heuristique amont, calibrée pour des dépôts applicatifs, classerait presque
  tout ce dépôt (bash + markdown) en `execute`. *(A3, verdict zone 1)*
- [x] **GSDA-04**: `workflow.windows_enforce` est activé **et** la fenêtre #3 (recette humaine
  XcodeBuildMCP, **structurellement infermable dans ce dépôt** — aucun `.mcp.json`, aucun projet
  iOS) est **dérogée par une trace auditable** `gsd-tools windows waive 3 "<raison>"`, l'entrée
  passant `open` → `waived` et restant visible dans `/gsd-progress`. **Gaté sur `GSDA-01`.**
  *(A1, verdict zone 2)*
- [x] **GSDA-05**: `hooks.workflow_guard` est activé (garde d'enchaînement de workflow) — une clé,
  **aucune édition de `~/.claude/settings.json`** : le hook est déjà posé en `PreToolUse` et
  s'auto-gate sur le config. **Gaté sur `GSDA-01`.** *(A5, verdict zone 2)*
- [x] **GSDA-06**: `hooks.community` (Conventional Commits bloquants) est **refusé par ADR**, avec
  sa mesure : sur **109 commits locaux**, **23 échouent sur le type** (six types maison — `release:`,
  `planning:`, `doctrine:`, `bump`, `spec`, `plan` — absents de la liste amont) et **76/109 = 69 %**
  des sujets dépassent 72 caractères. L'ADR acte aussi qu'il n'existe **aucun gate machine de message
  de commit** dans ce dépôt : c'est une **consigne** du `CLAUDE.md`, jamais une garantie machine.
  *(A5, verdict zone 2)*
- [x] **GSDA-07**: `intel.enabled` est activé — la promesse de notre propre `docs-flow.md:43-44`
  (le mode `--query` publié comme l'un des **deux modes normaux** de `gsd-map-codebase`) **tient**
  au lieu de router vers un geste inerte. La frontière `codebase/` (jugement humain daté, lecteurs
  prescrits) ↔ `intel/` (fait dérivé rafraîchissable, « HINT ONLY … MAY BE INCOMPLETE ») est
  **écrite**. *(A7 + la troisième route, verdict zone 3)*
- [x] **GSDA-08**: `graphify` et `profile-pipeline` sont **refusés** (aucun consommateur prescrit
  dans le module), leurs entrées de `intent-routing.md` (`:104`, `:147`) marquées **conditionnelles**,
  et **portées dans `gsd-capabilities-index.md` avec leur état** — sans quoi le gate d'activation
  n'a rien à lire. *(A8, verdict zone 3)*
- [x] **GSDA-09**: Un **gate d'activation doc ↔ capability** existe et le gate **T14** de
  `test-dev-orchestrator.sh` est étendu : une entrée de doc ou de routage qui pointe une capability
  **inactive** fait **échouer** la suite. C'est le **vrai livrable de la zone 3** — sans lui le trou
  se rouvre au prochain skill ajouté, exactement ce que le ROADMAP relevait en A8 (« une couverture
  verte peut masquer un geste mort »). Discriminance prouvée par mutation. *(A8, verdict zone 3)*
- [x] **GSDA-10**: Les profils de contexte sont **refusés par ADR**, et l'ADR est **factuellement
  exact** : la clé porteuse de la sémantique est **`context_profile`** (et non `context:`, que les
  trois fichiers livrés nomment à tort en en-tête) ; son état est **documentée, livrée, jamais
  câblée, abandonnée de fait depuis avril 2026** — le mot « **dépréciée** » n'apparaît **nulle
  part**, l'amont ne l'a jamais dit. Motif du refus : **il n'y a rien à activer** (6 occurrences
  amont, **toutes dans `docs/`**), et notre contrat typé est **per-rôle et plus strict**. Le refus
  porte un **déclencheur de réexamen objectif, pas une date** : rouvrir **ssi** `context_profile`
  apparaît hors de `docs/` dans une release amont, **ou** qu'une issue amont le mentionne.
  *(A4, verdict zone 4)*
- [x] **GSDA-11**: `workflow.inline_plan_threshold` reste **inchangé à 2**, et **la mesure est le
  livrable** : sur les `*-PLAN.md` des phases 20-26, regex exacte du moteur, **4 plans sur 28
  (14 %)** passent sous le seuil et le **mode est à 3 tâches** — juste au-dessus. Le seuil ne
  contredit pas la délégation systématique (la doctrine vise l'**acteur**, le seuil est lu **dans**
  la brique). A6 n'est plus présentable comme un « levier de coût inconnu ». *(A6, verdict zone 4)*
- [x] **GSDA-12**: L'**Iron Law 2** (`plugin/conductor/AGENT.md:114`) est traitée **explicitement**
  — soit **révisée**, soit accompagnée de l'écrit qui dit **pourquoi elle ne s'applique pas** à
  l'adoption des workstreams. Le contournement silencieux est **interdit** : c'est une tâche du
  plan, pas un sous-entendu. *(A9, verdict zone 5, point 1)*
- [x] **GSDA-13**: `check-dev-bootstrap.sh` (`:111`) et `check-state-integrity.sh` (`:53`) sont
  **workstream-aware** : les chemins `.planning/ROADMAP.md` / `.planning/STATE.md` codés en dur
  résolvent le workstream actif. Les deux gates restent **verts** dans l'arbre non partitionné
  (non-régression) **et** deviennent verts dans un arbre partitionné. *(A9, verdict zone 5, point 2)*
- [x] **GSDA-14**: `planning-context.sh` est **workstream-aware**, au même contrat de
  non-régression que `GSDA-13`. *(A9, verdict zone 5, point 2)*
- [x] **GSDA-15**: Le flag `--ws` est **câblé dans les agents `vf-*`** — aujourd'hui **aucun** ne
  sait le passer, et exactement **3 fichiers** de tout `plugin/` mentionnent « workstream », tous
  des tables de routage. *(A9, verdict zone 5, point 2)*
- [x] **GSDA-16**: Un **gate sur le pointeur de session de workstream** existe : il détecte que le
  pointeur vit dans `os.tmpdir()/gsd-workstream-sessions/<sha1(realpath du .planning) tronqué
  16>/<clé>` — **effacé au reboot, indexé sur le chemin absolu, donc distinct par worktree et jamais
  hérité** — et **échoue bruyamment** plutôt que de laisser une session ouvrir sans workstream
  résolu. C'est la **non-composabilité avec ADR-064** (« un écrivain = un worktree ») rendue visible
  au lieu d'être subie. *(A9, verdict zone 5, points 2 et 3)*
- [x] **GSDA-17**: La **CI est étendue** aux chemins workstream (les gates de `GSDA-13`/`GSDA-14`
  sont exercés sur un arbre partitionné, pas seulement sur l'arbre racine). *(A9, verdict zone 5,
  point 2)*
- [x] **GSDA-18**: L'**ADR d'adoption** des workstreams est écrit — il dit « **adoption** », avec
  ses **limites connues DATÉES**, et porte les **quatre risques mesurés** sans les dissoudre dans la
  décision : (a) couverture amont **7/91 = 7,7 %** (45 workflows à chemins en dur, dont **42 sans
  aucune conscience** des workstreams) ; (b) `pr-branch.md:235-236`, dont les regex ancrées
  reclassent `.planning/workstreams/dev/STATE.md` de `STRUCTURAL` en **transient → EXCLUDED**, si
  bien que **les commits de feuille de route disparaissent silencieusement des branches de PR** ;
  (c) la **non-composabilité du pointeur avec ADR-064** ; (d) la **divergence invisible** —
  `git merge-tree` sort **exit 0** sur une branche post-partition avec un dossier de phase orphelin,
  **Git ne signale rien**. L'ADR porte la **condition dure conservée : aucune partition tant qu'une
  phase est en vol**. *(A9, verdict zone 5, points 3 et 5)*
- [x] **GSDA-19**: La **remontée amont** des **42 workflows aveugles** est rédigée et prête à
  poster, au **gabarit de forme déjà accepté en amont** (issue **#2598** : « descripteur non
  descriptif du runtime », jamais « bug de comportement »), avec la méthode de mesure reproductible
  (`awk` + `comm` sur les 91 workflows racine, **jamais** `grep` piped qui tronque). Elle est
  **compatible avec l'adoption** — les deux ne s'excluent pas. *(A9, verdict zone 5, point 4)*
- [x] **GSDA-20**: La **marge de profondeur de dispatch** est écrite en doctrine : le descripteur
  du runtime `claude` porte `maxDepth: 5`, la chaîne `vf-dev-manager → vf-coder → agent gsd-*` en
  consomme **3**, il reste **deux niveaux de marge** — et ce que cette marge **autorise** est dit
  (un worker peut légitimement dispatcher un sous-worker). Ce fait **clôt** la question du nesting
  ouverte à l'audit ; ne pas l'écrire garantit qu'elle se repose. *(M1, verdict zone 6)*
- [x] **GSDA-21**: `effort:` est **propagé par rôle** sur les **25 agents livrés**
  (`plugin/*/agents/*.md`, aujourd'hui **0 sur 25**) — **pilotage et jugement haut, exécution
  mécanique bas, jamais uniformément**. Le barème n'est **pas inventé** : il est **repris** des
  3 agents-templates qui en portent déjà un (`business-agent-template.md: medium`,
  `clarity-feature-template.md: high`, `orchestrator-template.md: high`). *(M3, verdict zone 6)*
- [x] **GSDA-22**: `check-agents.sh:514-516` est **durci** de « valide si présent » à « **exige** » :
  un agent posé sans `effort:` fait **échouer** le gate. Les **25** agents passent, **aucun laissé de
  côté**. Discriminance prouvée par mutation. *(M3, verdict zone 6)*

## Hors-milestone — Phase 27 : parallélisation d'exécution (granulaire, simple, sans collision d'écriture)

> **IDs proposés au plan du 2026-08-05**, préfixe `PAEX` (« PArallélisation d'EXécution ). La
> ROADMAP portait `TBD (run /gsd-plan-phase 27 to break down)`.
>
> Source : `27-CONTEXT.md` (13 décisions D-01 → D-13, toutes sourcées fichier + ligne) et les 6
> plans `27-01` → `27-06`. **Aucun `27-ARBITRAGES.md`** : le cadrage a vérifié les 5 candidats à
> l'arbitrage un par un et conclu qu'aucun ne résistait aux sources — deux étaient déjà tranchés
> par Samuel (**A** : repli « un étage = un workflow » ; **B** : `worktree.baseRef: "head"`).
>
> **Phase INCOMPLÈTE et gelée** — mission `.planning/missions/2026-08-05-phase-27-parallelisation-execution.md`,
> branche `feat/phase-27-parallelisation-execution` **non mergée**. Les cases ci-dessous ne sont
> cochées que pour ce qui est livré ET vérifié.
>
> **Ordre non négociable, câblé deux fois** (`depends_on` + précondition machine) : la baseline
> d'horloge de `PAEX-09` se capture **AVANT** toute activation de `PAEX-08`. Un plan qui active
> d'abord a détruit sa propre référence, et c'est irrattrapable.

- [x] **PAEX-01**: La doctrine de `plugin/conductor/references/team-kernel.md:64-65` cesse d'affirmer
  que le parallélisme intra-étape est « **perdu** » et dit « **éteint par défaut** » — un drapeau
  default-off, restaurable. *(livrable 1, plan 27-02)*
- [x] **PAEX-02**: La même doctrine nomme le **vrai chemin** : gate n° 4 de `claude_orchestration`
  lisant `dispatch.nested && dispatch.background`, **jamais** `backgroundDispatch` ; et
  `shouldFlattenDispatch()` n'est plus cité comme la cause. *(livrable 1)*
- [x] **PAEX-03**: La même doctrine nomme le **verrou pratique** — gate n° 5
  (`agent_sdk_version_unknown`), le SDK étant embarqué dans un binaire au lieu d'un paquet npm — et
  `GSD_AGENT_SDK_VERSION` comme contournement amont. *(livrable 1, ajouté sur finding M3 de revue)*
- [x] **PAEX-04**: `dag.sh ready` porte un champ **additif** `stages` calculant la disjonction des
  périmètres entre nœuds. Rétro-compatible : `ready`/`count` inchangés, consommateur hors diff
  re-testé au vert. *(livrable 3, plan 27-01)*
- [x] **PAEX-05**: `stages` est **câblé** sur `partitionStages()` amont via un sous-processus
  `gsd-tools claude-orchestration emit-workflow` — **jamais réimplémenté localement** (ADR-069,
  Iron Law 2 révisée). Manifeste par `mkstemp` 0600 exclusif, suppression en `finally`. *(livrable 3)*
- [x] **PAEX-06**: Le repli de `stages` est prouvé **fail-closed sur toutes ses branches**.
  Le trou est **fermé** : `T31` couvre « CLI **résolue** mais qui échoue » (le mutant `stages: null`
  → `stages: []` rougit désormais), `T32` couvre « `node` absent, `gsd-tools` présent », et `T29`
  neutralise enfin `HOME`/`CLAUDE_CONFIG_DIR` pour épuiser réellement la cascade. Les trois sont
  **prouvés discriminants par mutation**, vérifiés indépendamment par la revue et par l'audit.
  Suite : **99 PASS / 0 FAIL** (87 avant). *(différé à dessein jusqu'à l'arbitrage de `PAEX-11` —
  écrire ces tests plus tôt aurait gravé comme attendu la branche qui a été retirée)*
- [x] **PAEX-07**: `.worktreeinclude` et l'entrée `.gitignore` couvrant `.claude/worktrees/` sont
  posés, et la portée de l'isolation est écrite (`27-ISOLATION-PORTEE.md`, 13 agents écrivains
  re-dérivés : 19 porteurs de `Write`/`Edit` moins 6 managers). *(livrable 2, plan 27-03)*
- [x] **PAEX-08**: `isolation: worktree` est **armé** sur les 13 agents écrivains — **fait**, après
  **ratification explicite de Samuel** de `worktree.baseRef: "head"` et vérification de sa condition
  suspensive (fix `PAEX-11` livré, suite verte). Mesuré après coup : **13** agents portent la clé,
  **0 manager** (traitement distinct tenu). Lint re-passé **par répertoire de module** — 6
  répertoires, **25 fichiers réellement lintés**, non-vacuité assertée.
  **Trou de procédure consigné, pas tu** : `worktree.baseRef` avait été mis à `"head"` **hors
  checkpoint** par un effet de bord de worker (`.claude/settings.local.json`, gitignoré) — le gate
  machine était donc vert **avant** toute ratification. Le worker s'est arrêté quand même : un gate
  vert n'est pas un feu vert. **Piège du gate lui-même** : `check-agents.sh` **nu** sort `exit 0`
  sur « aucun agent dans `.claude/agents` » — il ne scanne qu'un répertoire, sans récursion. Validé
  ainsi, l'armement de 13 frontmatters aurait été confirmé par un gate ne regardant **rien** :
  l'anti-pattern d'ADR-070 retourné contre son propre auteur.
- [x] **PAEX-09**: `claude_orchestration` est instruit par un spike puis une **décision écrite**
  (activation ou refus motivé). **CLOS 2026-08-06 — REFUS MOTIVÉ** (`27-DECISION-claude-orchestration.md`,
  plan 27-05) : l'échelle des 7 gates est franchie sans drapeau manuel — `GSD_AGENT_SDK_VERSION`
  **persistée** par installation réelle (`npm --prefix ~/.claude`, SDK 0.3.223, option 3 tranchée par
  Samuel au checkpoint) — mais le run réel diverge du chemin inline (critère FAIL n°2 : aucun commit
  de worker, aucun SUMMARY, aucun merge, worktrees résiduels). `enabled: false`, jamais à demi activé ;
  déclencheur objectif de reprise consigné dans la décision.
- [x] **PAEX-10**: Le gain réel est **mesuré** — baseline d'horloge avant, mesure après, méthode
  écrite. **CLOS 2026-08-06 par la branche prévue « refus »** : baseline capturée AVANT toute
  activation (blocs 1-2, plan 27-04, précondition D-10 vérifiée), moitié « après » **non-mesurable
  motivée** — `STATUT-BLOC-3: NON-MESURABLE` (plan 27-06), motif et déclencheur de reprise recopiés
  de la décision, protocole A/B conservé intact pour la reprise. Le plafond d'étages **3,00×** reste
  une compression d'étages, **jamais** un gain d'horloge ; le **1,8-2,5×** reste une **estimation**,
  dite comme telle.
- [x] **PAEX-11**: Aucune régression de sécurité de la Phase 24 — **le vecteur trouvé est fermé**,
  et sa fermeture est **vérifiée en exécution**, pas annoncée.
  **Le défaut** : `dag.sh:124` résolvait un `gsd-tools.cjs` **relatif au CWD** et l'exécutait via
  `node` sans ancrage — **RCE reproduite par PoC**, sans symlink ni PATH compromis, dans le socle
  que les 5 managers invoquent en routine. **5ᵉ passage** du motif de confinement de chemin,
  littéralement prédit par `CONCERNS.md`.
  **L'arbitrage** : Samuel a tranché le **RETRAIT** — pas d'ancrage, pas de repli déguisé.
  **La fermeture** : retrait exécuté dans `dag.sh` (`4a532ec`) **et**, après balayage, dans
  `mission-contracts.md` (`08ad030`) où la variante `toplevel` portait le même vecteur —
  `git rev-parse --show-toplevel` n'est pas une frontière de confiance (un dépôt hostile a sa
  propre racine), et son repli `|| pwd` ramenait au CWD qu'on venait d'interdire.
  **La preuve** : PoC rejoué dans deux configurations, le fichier planté n'est plus jamais exécuté ;
  et `T33` rougit sur la **réintroduction du comportement** (vérifié en réintroduisant réellement le
  candidat), pas sur une chaîne de source qu'un renommage contournerait.
  **La cause racine, gravée** : `T-27-01-04` acceptait « le spoofing de résolution » **en bloc** au
  motif qu'un `PATH` compromis compromet déjà la session — raisonnement juste pour `PATH`, faux pour
  le CWD, qui n'exige aucune compromission préalable. D'où **ADR-070** : une disposition `accept`
  **borne le vecteur qu'elle couvre**, jamais le risque en bloc. `T-27-01-04` est réécrite selon
  cette forme. **Balayage repo-wide** : une seule autre occurrence exécutante, `scripts/hooks/pre-push`
  — qualifiée **subsumée** (si `core.hooksPath` pointe dans le dépôt, le hook est lui-même du contenu
  versionné : qui peut détourner `$root` peut déjà réécrire le hook), et **déjà sur `main`** bien
  avant cette phase.

## Hors-milestone — Phase 28 : preuve que ce qui est armé dans le plugin est armé chez l'utilisateur

> **IDs créés au plan du 2026-08-10**, préfixe `ARMD` (« ARMement ↔ Distribution »). La ROADMAP
> portait `Requirements: TBD` (`.planning/ROADMAP.md:2017`) et `28-RESEARCH.md` §Phase Requirements
> constatait qu'aucune correspondance REQ→test ne pouvait être produite sans en inventer.
>
> Sources : `28-CONTEXT.md` (décisions D-01 → D-06, arbitrées humainement), `28-ARBITRAGES.md`
> (arbitrages A-1 → A-9, qui priment sur les recommandations de `28-RESEARCH.md` là où les deux
> divergent), `28-RESEARCH.md` (mécanique fine mesurée, `fichier:ligne`).
>
> **Hors périmètre, verrouillé** : ré-armer `isolation: worktree` sur un artefact distribué,
> distribuer `worktree.baseRef`, ouvrir un véhicule de distribution de settings dans l'engine,
> solder l'ensemble des findings du gate sur l'existant.

- [x] **ARMD-01**: La liaison artefact ↔ preuve se fait par **identifiant de précondition** —
  `vf-requires: <id>` dans le frontmatter de l'artefact armé, `# vf-provides: <id>` en en-tête du
  script de preuve, plus un registre **vocabulaire seul** (liste close des armements + table des
  `<id>` légaux). **Jamais** par nom de fichier, chemin, ni proximité de nom. *(D-02b, A-1)*
- [x] **ARMD-02**: La liste close des armements est **énumérée à la main** dans le gate — plancher
  `isolation:` + outils `mcp__*` — chaque ligne portant son motif sur place. Jamais d'heuristique.
  *(D-01 point 2)*
- [x] **ARMD-03**: Un armement de la liste close sans précondition distribuée rend **ROUGE** : exit
  non nul, message nommant l'artefact, l'armement, la précondition manquante **et** `fichier:ligne`.
  Le rouge ne dépend d'**aucune** déclaration — `vf-requires` ne fait que le lever. *(D-02, A-3)*
- [x] **ARMD-04**: Un `vf-requires: <id>` levé par un `# vf-provides: <id>` porté par un script
  réellement distribué rend **VERT**. La jointure est **statique** : le gate n'exécute aucun
  `ensure-*.sh`. *(D-02, A-4 i)*
- [x] **ARMD-05**: Un `ensure-*` incapable de rendre **non-zéro** quand sa précondition manque ne peut
  pas déclarer `# vf-provides:`. La discriminance est **prouvée dans la suite de tests**, jamais
  déclarée. Fait fondateur : `ensure-design-deps.sh:59-60` sort **toujours 0**, et son seul câblage
  machine (`vibeflow-update.sh:581-586`) le traite en best-effort. *(A-4 ii)*
- [x] **ARMD-06**: Chaque règle neuve porte son **plancher anti-vert-à-vide** (patron
  `check-capability-activation.sh:376-388`) : registre illisible, table vide, zéro artefact balayé ou
  zéro `# vf-provides:` ⇒ « NON VÉRIFIABLE » (exit 2), **jamais** un repli vert. Le 3ᵉ discriminant
  `FILENAME` est explicite (`:318` / `:355`) et la garde `jq` (`:204-207`) ne bloque plus les règles
  qui n'en ont pas besoin.
- [x] **ARMD-07**: Le cas de preuve rejoue **#38 lui-même** sur fixture synthétique : armement remis
  ⇒ ROUGE, désarmé (ou précondition prouvée) ⇒ VERT. Discriminance **bidirectionnelle**, mutation
  vérifiée par `cmp` et jamais par `diff`. Le test établit que le **nouveau** gate rougit **de son
  propre chef**, distinctement de `check-agents.sh:528-549`. *(D-05, D-06)*
- [x] **ARMD-08**: Le gate s'exécute **tel qu'installé** (*as-installed testing*) sur un univers
  **non vide**, avec plancher anti-vert-à-vide et le cas `.planning/config.json` absent réglé.
  Mesuré : la fermeture de `conductor` vaut **7 modules** sans `dev-orchestrator`, **0 armement**
  posé — un branchement naïf rendrait vert à vide. Le vert actuel de Gate C n'est pas troublé.
  *(D-04, A-7, A-8)*
- [x] **ARMD-09**: Le gate **écrit ses propres bornes** dans son en-tête : ce que la liste close
  couvre et ne couvre pas, le nom du pattern *as-installed testing*, la hiérarchie avec
  `check-agents.sh` (interdiction dure vs relation conditionnelle), le sort des `SKILL.md` (aucun
  linter de frontmatter n'existe pour eux), et la limite « couverture **déclarée** ≠ couverture
  **effective** ». *(D-01b, D-06 § recouvrement)*
- [x] **ARMD-10**: Le verdict tranche explicitement **précondition dure vs tuning à défaut sûr** et
  l'écrit. Si `worktree.baseRef` bascule côté « défaut sûr », la ligne `isolation: worktree` n'est
  **pas** évacuée en silence de la liste close : soit gardée avec motif réécrit, soit le cas de preuve
  se fonde sur un armement à précondition réellement dure — dit comme tel. Jamais un cas de preuve
  creux. *(A-9 ii)*

## Hors-milestone — Phase 29 : distiller les gains de la deep-search (G1/G2/G3/G5) — investigation `dag.sh --scope` d'abord

> **IDs créés au plan du 2026-08-15**, préfixe `ICMD` — un acronyme interne de traçabilité (« ICM
> Distillation »), cohérent avec les préfixes précédents du dépôt qui nomment déjà leurs
> identifiants d'après l'objet externe déclencheur (ex. `ARMD` pour la Phase 28). Ce préfixe **ne
> constitue pas** une adoption de la méthodologie externe comme label ou vocabulaire dans un
> artefact distribué — c'est l'interdiction explicite reprise ci-dessous en prohibition de phase.
> La ROADMAP portait `Requirements: TBD` (`.planning/ROADMAP.md:2103`, désormais résolue par ces
> 12 IDs).
>
> Sources : `29-CONTEXT.md` (décisions D-01 → D-03), `29-RESEARCH.md`, `29-PATTERNS.md`.
>
> **Hors périmètre, verrouillé** : **G4** (lab-starters clonables à placeholders pour
> `vf-new-lab`), découpé en phase dédiée par **D-01** ; les gains secondaires du rapport source —
> budgets de tokens par couche, colonne `Section/Scope` dans les mandats, cadrage « compilateur »,
> pipelines mono-agent pour labs non-dev — hors périmètre par **D-02** ; toute modification de
> `plugin/conductor/scripts/dag.sh` (**D-03**, zéro régression autorisée) ; toute restructuration
> de `.planning/` (ADR-055, GSD propriétaire).

- [x] **ICMD-01**: L'investigation du mécanisme de périmètre est livrée comme rapport écrit
  autonome et sourcé (historique en deux phases par commit, inventaire des consommateurs,
  couverture de la suite de tests, verdict intouchable/extensible, voie retenue pour G1), avec la
  forme de citation historique corrigée. *(D-03)*
- [x] **ICMD-02**: Zéro régression sur le mécanisme de périmètre : `plugin/conductor/scripts/dag.sh`
  n'apparaît dans le `files_modified` d'**aucun** plan de la phase, et la suite `test-dag.sh` est
  verte avant et après chaque geste. Toute exigence d'y toucher HALTE sur un `checkpoint:decision`
  explicite, jamais un contournement silencieux. *(D-03)*
- [x] **ICMD-03**: G3 : un gate `check-map-drift.sh` en **lint seul**, en-tête « répond au FAIT,
  jamais au métier », grammaire d'exit `0/1/3/64` du dépôt, wrapper git durci repris verbatim,
  **aucun** mode correctif automatique (ADR-031).
- [x] **ICMD-04**: G3 : deux paires carte↔disque en v1, chacune **bidirectionnelle** (entrée
  déclarée absente du disque ; élément du disque absent de la carte), discriminance de chaque
  paire prouvée par mutation dans la suite, jamais déclarée.
- [x] **ICMD-05**: G3 : plancher anti-vert-à-vide — cible absente, cible vide ou hors dépôt git
  rendent « rien à constater » (exit 3), **jamais** un exit 0 déguisé.
- [x] **ICMD-06**: G3 : le gate **écrit ses propres bornes** en en-tête — ce qu'il ne couvre pas
  (les `skills:` de frontmatter, déjà couverts par `check-agents.sh` ; les DAG de mission, hors
  domaine ; `.planning/` en lecture seule) et pourquoi.
- [x] **ICMD-07**: G1 : le gabarit de digest de mission porte une bullet « NE charge PAS »,
  composée du croisement de deux champs **déjà émis** par le socle, avec **zéro** ligne modifiée
  dans `dag.sh`. *(D-03)*
- [x] **ICMD-08**: G1 : la doctrine des agents porte une table `| Tâche | Charge | NE charge PAS |`
  — l'anti-chargement devient déclaré, pas seulement le chargement.
- [x] **ICMD-09**: G5 : le principe d'édition-à-la-source (une correction récurrente amende la
  source, jamais un redispatch du même correctif) est écrit dans la doctrine des managers, en
  `references/` chargée on-demand — **jamais** inline dans un agent au plafond de densité ADR-029.
- [x] **ICMD-10**: G2 : `scaffold-docs.sh` pose un `CONTEXT.md` de routage ≤ 80 lignes par
  compartiment qualifié, via le garde-fou d'idempotence existant, sur le compartiment de
  **documentation de sous-projet** (ADR-042) — jamais le compartiment de planning homonyme.
- [x] **ICMD-11**: G2 : le pattern `_index.md` (dossier de références > 10 fichiers, table
  `| Fichier | Résumé |`) existe, est distinct en nom **et** en sémantique de l'`INDEX.md` déjà
  posé, et est appliqué à un dossier réel du dépôt qui franchit le seuil.
- [x] **ICMD-12**: Clôture de distribution : le gate G3 est câblé chez son consommateur à **coût
  de densité nul**, les triades de module touchées sont bumpées, les compteurs « N suites » des
  deux README racine sont **re-dérivés** (jamais recopiés) et `check-version-sync.sh` est vert.

## v2 Requirements

### Vocabulaire & UX

- **VOC-01**: Traduction exhaustive de tous les artefacts GSD en vocabulaire VibeFlow.
- **VOC-02**: Migration automatique `get-shit-done-cc` → `@opengsd/gsd-core` quand la bascule npm est stable.
  → **Promu en milestone `gsd-migration`** (Phases 10-11, requirements GSDM-01..06).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Fork/réécriture des skills GSD | On délègue ; absorber casserait les mises à jour gratuites de GSD |
| Support multi-runtime custom (Copilot/Gemini) | Déjà géré par GSD ; hors périmètre VibeFlow |
| UI/dashboard | CLI-first, cohérent avec l'écosystème |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ROUT-01 | Phase 1 | Complete |
| ROUT-02 | Phase 1 | Complete |
| ROUT-03 | Phase 1 | Complete |
| ROUT-04 | Phase 1 | Complete |
| IDX-01 | Phase 1 | Complete |
| IDX-02 | Phase 1 | Complete |
| ABS-01 | Phase 1 | Complete |
| ABS-02 | Phase 1 | Complete |
| BOOT-01 | Phase 1 | Complete |
| BOOT-02 | Phase 1 | Complete |
| BOOT-03 | Phase 1 | Complete |
| BOOT-04 | Phase 1 | Complete |
| VERIF-01 | Phase 1 | Complete |
| VERIF-02 | Phase 1 | Complete |
| MANIF-01 | Phase 2 | Complete |
| MANIF-02 | Phase 2 | Complete |
| SCOPE-01 | Phase 3 | Complete |
| SCOPE-02 | Phase 3 | Complete |
| SCOPE-03 | Phase 3 | Complete |
| SCOPE-04 | Phase 3 | Complete |
| INST-01 | Phase 4 | Complete |
| INST-02 | Phase 4 | Complete |
| INST-03 | Phase 4 | Complete |
| INST-04 | Phase 4 | Complete |
| INST-05 | Phase 4 | Complete |
| PLUG-01 | Phase 5 | Complete |
| PLUG-02 | Phase 5 | Complete |
| PLUG-03 | Phase 5 | Complete |
| PLUG-04 | Phase 5 | Complete |
| FIRST-01 | Phase 6 | Complete |
| FIRST-02 | Phase 6 | Complete |
| PHIL-01 | Phase 7 | Complete |
| PHIL-02 | Phase 7 | Complete |
| PHIL-03 | Phase 7 | Complete |
| PHIL-04 | Phase 7 | Complete |
| PHIL-05 | Phase 7 | Complete |
| PHIL-06 | Phase 7 | Complete |
| PHIL-07 | Phase 7 | Complete |
| PHIL-08 | Phase 7 | Complete |
| CONS-01 | Phase 8 | Complete |
| CONS-02 | Phase 8 | Complete |
| CONS-03 | Phase 8 | Complete |
| CONS-04 | Phase 8 | Complete |
| RND-01 | Phase 9 | Spike done — GO (round-trip + archivage vérifiés) |
| RND-02 | Phase 9 | Done — note go/no-go + demi-vies recalibrées + cadrage swarm |
| GSDM-01 | Phase 10 | Done — inventaire 5 familles de points de contact (10-ETUDE.md §1) |
| GSDM-02 | Phase 10 | Done — cible caractérisée : successeur communautaire dominant, parité totale, chemins/bins changés (10-ETUDE.md §2) |
| GSDM-03 | Phase 10 | Done — GO validé par Samuel (2026-07-26) |
| GSDM-04 | Phase 11 | Done — @opengsd/gsd-core@^1, piège detect_gsd neutralisé, legacy affiché jamais exécuté |
| GSDM-05 | Phase 11 | Done — index 71 entrées, gsd-tools, routage onboard + canal une-seule-voix |
| GSDM-06 | Phase 11 | Done — 39 suites + test-gsd-cohabitation, dry-run 3 scopes, release v2.39.0 |
| VERB-01 | Phase 12 | Done |
| VERB-02 | Phase 12 | Livré v2.31.0 (17/18 verbes) — **caduc depuis v2.33.0** (façade supprimée) |
| VERB-03 | Phase 12 | Done — 33 descriptions, 11 groupes à réciprocité stricte |
| VERB-04 | Phase 12 | Livré v2.31.0 (rule 40 L) — **artefact supprimé en v2.33.0** |
| VERB-05 | Phase 12 | Done — 65/65 skills routés (suite refondue v2.33.0 : 26 OK) |
| BRDG-01 | Phase 13 | Done — doctrine `ingestion-flow.md` + câblage `AGENT.md` (module v2.2.0) |
| BRDG-02 | Phase 13 | Done — `discover-unintegrated-docs.sh`, 16 cas (bornage bilatéral + ERE durcis après revue) |
| BRDG-03 | Phase 13 | Done (doctrinal) — 4 garde-fous écrits, T16 les vérifie ; portée `vf-dev-manager` en arbitrage |
| ALTI-01 | Phase 14 | Complete |
| ALTI-02 | Phase 14 | Complete |
| ALTI-03 | Phase 14 | Complete |
| ALTI-04 | Phase 14 | Complete |
| ALTI-05 | Phase 14 | Complete |
| DOCF-01 | Phase 22 | Planned — plan 22-01 |
| DOCF-02 | Phase 22 | Planned — plan 22-01 |
| DOCF-03 | Phase 22 | Planned — plan 22-01 |
| DOCF-04 | Phase 22 | Planned — plan 22-01 |
| DOCF-05 | Phase 22 | Planned — plan 22-02 |
| DOCF-06 | Phase 22 | Planned — plans 22-01 et 22-02 |
| DOCF-07 | Phase 22 | Planned — plan 22-03 |
| GSDC-01 | Phase 23 | Done — plan 23-01 (exécuté + revue en régime plein) |
| GSDC-02 | Phase 23 | Done — plan 23-01 (exécuté + revue en régime plein) |
| GSDC-03 | Phase 23 | Done — plan 23-03 (exécuté + revue en régime plein) |
| GSDC-04 | Phase 23 | Done — plan 23-04 (exécuté + revue en régime plein) |
| GSDC-05 | Phase 23 | Done — plan 23-05 (exécuté + revue en régime plein) |
| GSDC-06 | Phase 23 | Done — plan 23-06 (exécuté + revue en régime plein + comblement re-revu) |
| GSDC-07 | Phase 23 | Done — plan 23-02 (exécuté + revue en régime plein) |
| GSDC-08 | Phase 23 | Partiel — plan 23-07 (volet dispatch couvert, volet allowlist ouvert sur `D-22`, non tranché) |
| GSDC-09 | Phase 23 | Done — plan 23-07 (exécuté + revue en régime plein) |
| GSDC-10 | Phase 23 | Done — plan 23-08 (exécuté) |
| GSDA-01 | Phase 24 | Done — plan 24-02 (différé écrit : aucune version npm > 1.9.1 au 2026-08-04) |
| GSDA-02 | Phase 24 | Done — plans 24-03 et 24-11 |
| GSDA-03 | Phase 24 | Done — plan 24-03 |
| GSDA-04 | Phase 24 | Done — plan 24-02 (`windows_enforce: true`, fenêtre #3 dérogée — gate GSDA-01 relâché, voir ADR-066) |
| GSDA-05 | Phase 24 | Done — plan 24-02 (`workflow_guard: true` — gate GSDA-01 relâché, voir ADR-066) |
| GSDA-06 | Phase 24 | Done — plan 24-02 (ADR-067, non gaté) |
| GSDA-07 | Phase 24 | Done — plan 24-06 |
| GSDA-08 | Phase 24 | Done — plans 24-06 et 24-11 |
| GSDA-09 | Phase 24 | Done — plans 24-11 et 24-12 |
| GSDA-10 | Phase 24 | Done — plan 24-07 (ADR-068) |
| GSDA-11 | Phase 24 | Done — plan 24-07 |
| GSDA-12 | Phase 24 | Done — plan 24-10, tâche 1 (révision de l'Iron Law 2) |
| GSDA-13 | Phase 24 | Done — plans 24-04 et 24-12 |
| GSDA-14 | Phase 24 | Done — plans 24-04 et 24-12 (module `planning-core`, cf. 24-RESEARCH.md R-2d) |
| GSDA-15 | Phase 24 | Done — plans 24-08, 24-11 et 24-12 |
| GSDA-16 | Phase 24 | Done — plans 24-05 et 24-12 |
| GSDA-17 | Phase 24 | Done — plan 24-09 |
| GSDA-18 | Phase 24 | Done — plan 24-10 (ADR-069) |
| GSDA-19 | Phase 24 | Done — plan 24-10 |
| GSDA-20 | Phase 24 | Done — plans 24-01 et 24-12 |
| GSDA-21 | Phase 24 | Done — plans 24-01 et 24-12 |
| GSDA-22 | Phase 24 | Done — plans 24-01 et 24-12 |
| ICMD-01 | Phase 29 | Planned — plan 29-01 |
| ICMD-02 | Phase 29 | Planned — plan 29-01 |
| ICMD-03 | Phase 29 | Planned — plan 29-02 |
| ICMD-04 | Phase 29 | Planned — plan 29-02 |
| ICMD-05 | Phase 29 | Planned — plan 29-02 |
| ICMD-06 | Phase 29 | Planned — plan 29-02 |
| ICMD-07 | Phase 29 | Planned — plan 29-03 |
| ICMD-08 | Phase 29 | Planned — plan 29-03 |
| ICMD-09 | Phase 29 | Planned — plan 29-03 |
| ICMD-10 | Phase 29 | Planned — plan 29-04 |
| ICMD-11 | Phase 29 | Planned — plan 29-04 |
| ICMD-12 | Phase 29 | Planned — plan 29-05 |
| PORT-01 | Phase 30 | Pending |
| PORT-02 | Phase 30 | Pending |
| PORT-03 | Phase 30 | Pending |
| PORT-04 | Phase 30 | Tranché 2026-08-15 (Samuel, sans Willy — tracer 01-01 jamais livré) : la Phase 30 porte tout le volet merge-hooks.sh et écrit vf-portable.sh — plan dégaté, spec §3.2 amendée |
| PORT-05 | Phase 30 | Pending |
| MANI-01 | Phase 31 | Done — plans 31-01, 31-03 (socle manifeste + migration des ~35 sites d'écriture) |
| MANI-02 | Phase 31 | Done — plans 31-02, 31-04, 31-06 (mode `plan` de `merge-hooks.sh`, `--dry-run`, câblage skills) |
| MANI-03 | Phase 31 | Done — plan 31-05 (convergence à l'update, backup avant suppression) |
| MANI-04 | Phase 31 | Superseded par `31-CONTEXT.md` §4 point 8 — brouillon `31-ISSUE-20-REPLY.md` écrit (plan 31-08), **jamais posté, issue jamais close** (geste humain, ADR-031) |
| LOCK-01 | Phase 32 | Done — plan 32-01, vérifié goal-backward, 2 mutations rouges restaurées |
| LOCK-02 | Phase 32 | Done — plan 32-03 (+32-07 pour la resynchro doctrinale), armement prouvé en lab jetable, contournement réel rejoué en cas de test |
| LOCK-03 | Phase 32 | Done — amendé (D-32-A) : porté par le même guard `PreToolUse(Bash)` que LOCK-02, `reference-transaction` écarté (spike PAS SÛR) |
| LOCK-04 | Phase 32 | Done — plans 32-02 et 32-07 (verbes `takeover`/`reclaim` + fermeture du trou de la voie legacy, 4A) |
| LOCK-05 | Phase 32 | Livré en tant que **convention**, pas encore observée — jeton (`generation`) exposé, convention `Fence:` écrite et exécutable (`mission-flow.md`, `team-kernel.md`), recette d'audit existe ; **aucun commit, y compris ceux de cette phase, ne porte encore le trailer** — entre en vigueur au prochain mandat |
| WTCH-01 | Phase 33 | Done — plans 33-01/33-02, vérifié goal-backward (`33-VERIFICATION.md`, ATTEINT), suite `test-driver-lock.sh` 183 PASS / 0 FAIL |
| WTCH-02 | Phase 33 | Done — détection par `check-guard-health.sh` ATTEINTE (78 PASS/0 FAIL, mutation rouge prouvée). Le gap relevé par `33-VERIFICATION.md` (le relais au geste `dag.sh mark` ne pouvait structurellement jamais remonter un STALL, `record_progress()` avançant `progress_epoch` avant que `check_stall_signal()` ne relise le statut) est **fermé par D-33-G** (commit `88975dc`) : l'ordre est inversé, la lecture précède le rafraîchissement, les deux restent après `save(dag)`. Couvert par le cas de discriminance **T49** (`test-dag.sh` 161 PASS) — mutation prouvée : sous l'ordre fautif T49.2 rougit tandis que T41 et T48 restent verts, donc seul T49 mord. Mesure A/B re-jouée par le manager : les deux chemins convergent sur le même signal, `rc=0` |
| WTCH-03 | Phase 33 | Done (limite assumée) — plans 33-04/33-05, `notify.sh` posé, jalons `done`/`failed` notifiés, `running` jamais ; canal Windows prouvé par shims CI seulement — validation réelle Win10/11 en recette de clôture (`33-CLOTURE-WINDOWS.md`, jamais exécutée, aucune machine disponible). **Amendé par D-33-H (2026-08-17, annexe notifications)** : l'émission devient **opt-in, défaut OFF**, pilotée par un toggle `/vf-notify` (fichier-sentinelle, scope machine) ; les jalons GSD (fin de phase, fin de milestone) sont relayés vers l'**app Claude** (`SendMessage(main)` → `PushNotification` côté session principale, l'outil n'existant pas en sous-agent), les fins de nœud de DAG restant sur le toast OS de `notify.sh` sous opt-in actif. Le signal de stall (D-33-F) n'est **jamais** gaté. Correction pré-distribution sans migration de parc : v2.56.0 a été retirée (revert `07ff554`), aucun lab n'a reçu le défaut d'émission |
| WTCH-04 | Phase 33 | Done — plan 33-05, armement vérifié par le gate PORT-05 (aucune entrée `hooks.json` neuve, aucun settings local, `check-capability-activation.sh` intact — `33-VERIFICATION.md`, ATTEINT) |
| LEDG-01 | Phase 18 | Pending |
| LEDG-02 | Phase 18 | Pending |
| LEDG-03 | Phase 30 | Ouverte le 2026-08-15 — https://github.com/open-gsd/gsd-core/issues/3556 — deadline amont 2026-10-26 |
| BUDG-01 | Phase 25 | Pending |
| BUDG-02 | Phase 25 | Pending |
| WKTR-01 | Phase 35 | Pending — conditionnelle (gsd-core > 1.10.0 releasé ET installé) |
| WKTR-02 | Phase 35 | Pending — conditionnelle |
| WKTR-03 | Phase 30 | Pending — geste jour 1 (veille `npm view`, jamais le dist-tag `next`) |
| SKIL-01 | Phase 34 | Pending — cadrage go/no-go, aucun code avant le go |
| AGTS-01 | Phase 34 | Pending |
| AGTS-02 | Phase 34 | Pending — conditionnée à la sortie d'expérimental de mobile-test |
| QUAL-01 | Transverse — Phases 30, 31, 32, 33, 18, 25, 35 | Pending — satisfait sur les phases 30, 31 et 32 livrées (30/31 : 3 issues + mutation rouge prouvée ; 32 : amendé à **4** issues par D-32-QUAL — PASS/DENY/imparsable-silencieux/indisponible-BRUYANT — les 4 couvertes, cf. `32-RELIQUATS.md` §5) ; reste à tenir sur 33, 18, 25, 35 |

**Coverage:**
- Milestone 1 (v1) : 14 requirements — Complete ✓
- Milestone 2 (Install UX) : 17 requirements — mappés aux phases 2-6, 0 non-mappé ✓
- Milestone 3 (Doctrine dev & consolidation) : 12 requirements — mappés aux phases 7-8, 0 non-mappé ✓
- Milestone 4 (memory-swarm-rnd / R&D) : 2 requirements — mappés à la phase 9, 0 non-mappé ✓
- Milestone 5 (gsd-migration) : 6 requirements — mappés aux phases 10-11, 0 non-mappé ✓
- Milestone 6 (vf-routing) : 13 requirements — mappés aux phases 12-14, 0 non-mappé ✓
- Hors-milestone : les releases `v2.32.0 → v2.36.1` (audit croisé, bascule agentique, bundles métier,
  recettes UAT, refonte README) ont été livrées **sans requirements GSD** — tracées dans
  `MILESTONES.md` (entrée « hors-milestone ») et `docs/ADR.md` (ADR-056/057).
- Phase 22 (hygiène documentaire) : 7 requirements `DOCF-01..07` **créés au plan du 2026-07-31** —
  mappés aux 3 plans de la phase, 0 non-mappé. Les Phases 15 à 21 restent sans requirements au
  ledger (livrées hors registre, comme les releases hors-milestone ci-dessus).
- Phase 23 (couplage explicite au moteur GSD) : 10 requirements `GSDC-01..10` **créés au plan du
  2026-08-01** — mappés aux 8 plans de la phase, 0 non-mappé. Couverture des 7 zones de décision de
  `23-CONTEXT.md` : zone 1 → GSDC-01/02 · zone 2 → GSDC-03/04 · zone 3 → GSDC-05 · zone 4 →
  GSDC-06 · zone 5 → GSDC-07 · zone 6 → GSDC-03 (tension `gsd-ship`) et GSDC-08 · zone 7 →
  GSDC-09 · gouvernance → GSDC-10. Les décisions factuelles D-00, D-29, D-30 et D-31 sont
  **informatives** (vérifications de cadrage et périmètre) : elles fondent les exigences ci-dessus
  sans en constituer une — D-30 (`dag.sh` non touché) et le périmètre différé de D-31 sont des
  **non-livrables explicites**, vérifiables par l'absence de `plugin/conductor/scripts/dag.sh` du
  périmètre de fichiers des 8 plans.
- Phase 24 (activation et mesure du moteur GSD) : 22 requirements `GSDA-01..22` **créés au plan du
  2026-08-04** — mappés aux **12 plans** de la phase (`24-01` → `24-12`, 4 vagues), **0 non-mappé**,
  **0 inventé** (union des champs `requirements:` des 12 plans comparée au ledger par `comm`).
  Couverture des 6 zones d'arbitrage de `24-ARBITRAGES.md` : zone 1 → GSDA-02/03 · zone 2 →
  GSDA-01/04/05/06 · zone 3 → GSDA-07/08/09 · zone 4 → GSDA-10/11 · zone 5 → GSDA-12→19 · zone 6 →
  GSDA-20/21/22. **`GSDA-04` et `GSDA-05` sont planifiés en DIFFÉRÉ ÉCRIT, pas en activation** : la
  recherche du 2026-08-04 (`24-RESEARCH.md` R-1) établit qu'**aucune version de
  `@opengsd/gsd-core` au-delà de `1.9.1` n'est publiée sur npm**, si bien que le prérequis dur du
  verdict de la zone 2 ne peut pas être satisfait et que la clause de repli de `GSDA-01`
  s'applique — déclencheur de reprise objectif gravé, jamais un abandon silencieux.
- Phase 29 (distiller les gains ICM G1/G2/G3/G5) : 12 requirements `ICMD-01..12` **créées au plan
  du 2026-08-15** — mappées aux **5 plans** de la phase (`29-01` → `29-05`), **0 non-mappé**,
  **0 inventé**. D-01 et D-02 sont des **non-livrables** vérifiables par l'absence de G4 et des
  gains secondaires du `files_modified` des 5 plans ; D-03 est vérifiable par l'absence de
  `plugin/conductor/scripts/dag.sh` de ce même ensemble.

- Milestone fiabilite-v1.0 : **30 IDs au ledger** (9 familles + QUAL-01 transverse ; le « 26 » de
  l'arbitrage compte les features avant frappe des IDs transverses et jour 1) — mappés le
  2026-08-15 aux **8 phases** du milestone (30-35 + 18 et 25 héritées), **0 non-mappé**, **0
  doublon** ✓. Gestes jour 1 portés par la Phase 30 : LEDG-03 (RFC upstream) et WKTR-03 (veille
  gsd-core). QUAL-01 est **transverse** : reporté en critère de succès sur chaque phase qui livre
  un gate (30, 31, 32, 33, 18, 25, 35), vérifié à chaque livraison de gate plutôt qu'en une phase
  propre. La Phase 34 (AGTS-01/02 + SKIL-01) n'attend aucun gate neuf — QUAL-01 s'y appliquerait de
  plein droit si un gate y naissait.

## Milestone fiabilite-v1.0 — « ce qui survit » (démarré 2026-08-15)

> Périmètre arbitré par Samuel le 2026-08-15 après audit d'utilité réelle et de faisabilité
> (31 → 26 exigences ; chaque famille adossée à une preuve : incident documenté, demande externe,
> ou bug récurrent par construction). Recherche : `.planning/research/SUMMARY.md` (commit
> `5916899`). Coupes : BUDG-03 différé, SKIL réduit à un cadrage go/no-go, AGTS réduit,
> MANI sans hash conffile, LOCK-03 en détection d'abord.

### Portabilité Windows II (prioritaire — demande client)
- [ ] **PORT-01**: Les 3 fichiers du lot PYBIN passent par la lib partagée `vf-portable.sh` (contrat PR #29 consommé, jamais réinventé)
- [ ] **PORT-02**: `merge-hooks.sh` apprend la forme exec (`args`) AVANT toute migration de fragments — ordre (a) moteur → (b) codes de sortie → (c) hooks.json encodé en vagues dépendantes du plan (spec §1.3)
- [ ] **PORT-03**: Contrat de codes de sortie normalisé pour les scripts de hooks, inventaire des 19 entrées réalisé
- [ ] **PORT-04**: L'affectation §3.2 (résolution du chemin absolu de bash à l'install) est tranchée avec Willy et documentée avant le plan de la phase
- [ ] **PORT-05**: La portabilité est prouvée en CI sur lab frais (suites windows-crlf + windows-guards + gates verts)

### Manifeste d'install + dry-run (issue #20)
- [x] **MANI-01**: Chaque module posé écrit son manifeste de chemins (`$TARGET_ROOT/scripts/.vibeflow-manifest-<module>`, LF trié, un chemin par ligne)
- [x] **MANI-02**: `--dry-run` montre le plan de pose fichier-par-fichier sans rien écrire — même chemin de code que la pose (install + calibrate)
- [x] **MANI-03**: L'update supprime les chemins de l'ancien manifeste absents du nouveau, avec backup systématique et liste signalée à l'utilisateur
- [ ] **MANI-04**: L'issue GitHub #20 est close par livraison, réponse postée sur l'issue — **superseded par `31-CONTEXT.md` §4 point 8** : brouillon écrit (`31-ISSUE-20-REPLY.md`), poster et clore sont des gestes humains (ADR-031), non faits en mission

### Durcissement du driver-lock (Phase 32 livrée le 2026-08-17 — 64 suites / 0 échec)
- [x] **LOCK-01**: Le heartbeat est séparé de la lease — un manager vivant renouvelle son battement, le TTL ne monte pas
- [x] **LOCK-02**: Un commit sous le lock d'autrui est bloqué à la source (guard `PreToolUse` distribué via merge-hooks ; armement prouvé par le gate règle 4)
- [x] **LOCK-03**: Un checkout de branche sous le lock d'autrui est détecté et signalé bruyamment — amendé (D-32-A) : porté par le même guard `PreToolUse(Bash)` que LOCK-02, pas par `reference-transaction` (spike PAS SÛR : wedge rebase, casse worktree add, contournable)
- [x] **LOCK-04**: Le takeover d'un lock périmé est explicite et tracé — jamais d'auto-steal
- [~] **LOCK-05** *(livré en tant que convention, pas encore observée)*: Jeton de fence en trailer des commits de mission — le jeton (`generation`) est exposé, la convention `Fence:` est écrite et exécutable dans `mission-flow.md`/`team-kernel.md`, une recette d'audit existe ; **aucun commit ne porte encore le trailer à ce jour**, y compris ceux de cette phase — entre en vigueur au prochain mandat qui commite sous cette doctrine

### Watchdog & notifications des missions (Phase 33 vérifiée `gaps_found` le 2026-08-17 — 3 critères atteints, 1 partiel, `33-VERIFICATION.md`)
- [x] **WTCH-01**: Chaque nœud du DAG de mission écrit un battement de progression (même battement que LOCK-01, deux consommateurs)
- [x] **WTCH-02**: Un stall est détecté par ABSENCE de battement au-delà du seuil — jamais par auto-déclaration ; le watchdog signale et suggère, ne tue jamais (ADR-031). Gap du relais au geste `mark` fermé par D-33-G (`88975dc`), cas de discriminance T49, mesure A/B re-jouée par le manager.
- [x] **WTCH-03** *(limite assumée : preuve Windows réelle non exécutée)* *(amendé D-33-H, 2026-08-17 — annexe notifications)*: Notification aux jalons de mission (fin de nœud, halt condition) — jamais à chaque tour, et désormais **opt-in : défaut OFF**, activable par le toggle `/vf-notify`. Deux canaux : jalons GSD (fin de phase, fin de milestone) → **push app Claude** relayé par la session principale ; fins de nœud de DAG (`done`/`failed`) → toast OS `notify.sh`, sous opt-in actif. Le signal de stall (D-33-F) n'est jamais gaté par le toggle.
- [x] **WTCH-04**: L'armement (hooks, notify) passe par le gate armement↔précondition — jamais un settings local (leçon #38)

### Survie du ledger d'exigences (Phase 18 héritée)
- [x] **LEDG-01**: La clôture de jalon fait un roll-over outillé du ledger — les exigences non livrées voyagent avec trace `carried-from:`
- [x] **LEDG-02**: Un gate rend rouge si une exigence disparaît du ledger sans issue tracée (livrée / reportée / abandonnée)
- [x] **LEDG-03**: La RFC upstream est ouverte dès le jour 1 du milestone (deadline amont
  2026-10-26) — https://github.com/open-gsd/gsd-core/issues/3556, ouverte le 2026-08-15.

### Budget d'instructions (Phase 25 héritée, réduite)
- [ ] **BUDG-01**: Le budget d'instructions par fichier d'agent distribué est mesuré et publié (métrique tranchée au cadrage de la phase)
- [ ] **BUDG-02**: Le gate est en ratchet — avertit d'abord, bloque au merge, jamais rouge des semaines

### Ré-armement worktree (phase conditionnelle — jamais bloquante)
- [ ] **WKTR-01**: La précondition est machine-vérifiée : gsd-core > 1.10.0 RELEASÉ (sonde `npm view`, jamais le dist-tag `next`) ET installé, prouvée as-installed (`vf-requires`/`# vf-provides` porté par `ensure-deps.sh` + `lab-frais-arme`)
- [ ] **WKTR-02**: Le ré-armement des 13 agents n'a lieu qu'après preuve du retour des commits sur un cas réel rejoué (scénario #3302)
- [ ] **WKTR-03**: La veille de release gsd-core est active dès le jour 1

### Skill-installer global (réduit à un cadrage)
- [ ] **SKIL-01**: Un cadrage go/no-go répond à « que fait-il de plus que le natif `/plugin` ? » — abandon documenté si la réponse est creuse ; aucun code avant le go

### Gaps agency-agents (réduit)
- [ ] **AGTS-01**: Les gaps sont arbitrés en distillant la taxonomie du catalogue — jamais d'import des personas
- [ ] **AGTS-02**: `web-test-team` est construite SI mobile-test sort du statut expérimental pendant le milestone (seule piste alignée fiabilité) ; sinon l'exigence est reportée avec trace

### Transverse
- [ ] **QUAL-01**: Tout nouveau gate du milestone naît avec ses trois issues (PASS / FAIL / imparsable BRUYANT) et sa mutation rouge prouvée

### Out of Scope (audité le 2026-08-15 — chaque exclusion a son alternative dans le périmètre)
- **Auto-steal du lock au TTL** — lock périmé ≠ mission morte (constaté 2026-08-02) → LOCK-01 + LOCK-04. *Réévaluable post-LOCK-01 : auto-takeover sur battement mort (pas sur TTL).*
- **Notification à chaque tour / auto-kill sur stall** — spam couvert par `stop-notify`, auto-kill viole ADR-031 → WTCH-02/03
- **Dry-run en chemin de code séparé** — dérive plan/pose garantie → contrainte encodée dans MANI-02
- **Suppression silencieuse de fichiers modifiés** — perte de travail → MANI-03 backup + signalement
- **Hash conffile-style par fichier** — raffinement sans besoin prouvé, le backup couvre → différé
- **Armement via settings local** — régression #38 rejouée → gate règle 4 (WTCH-04, LOCK-02)
- **Ré-armement worktree sur issue-close** — close ≠ releasé ≠ installé → WKTR-01
- **Marketplace de skills maison / mirroring tiers** — duplique `/plugin` natif → input du cadrage SKIL-01
- **Import des 230 personas agency-agents** — ADR-029 incompatible, zéro gouvernance → AGTS-01
- **Migration des hooks.json avant merge-hooks.sh** — parc cassé sans erreur (§1.3) → ordre PORT-02
- **Blocage CI dur immédiat du budget** — accoutumance au rouge → BUDG-02 ratchet
- **BUDG-03 étage d'alignement court (G2)** — différé : mécanique de workflow neuve, utilité non démontrée, aucun incident lié

---
*Requirements defined: 2026-06-04*
*Last updated: 2026-08-15 — roadmap fiabilite-v1.0 posée : traçabilité mappée aux phases 30-35 + 18/25 héritées (30 IDs, 0 orphelin) ; précédent : ajout milestone fiabilite-v1.0 (26 exigences en 9 familles, audit d utilite prealable, Out of Scope motive) ; precedent : ajout Phase 29 (ICMD-01..12, distillation des gains ICM G1/G2/G3/G5) ; précédent : 2026-07-26 — remise à l'heure post-audit (Phase 12 annotée post-bascule v2.33.0, Phase 13 redéfinie sans verbe, Phase 14 = v2.30.0, milestones 2-3 shipped) ; précédent : 2026-07-25 — ajout Phase 14 au Milestone 6 (ALTI-01→05 : frontière d'altitude planning-core / moteur GSD, ADR-055)*
