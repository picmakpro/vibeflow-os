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
  **compatible avec l'adoption** — les deux ne s'excluent pas. **— superseded par `PART-06`
  (Phase 39, 2026-09-09)** : l'angle « descripteur non descriptif » (#2598) est abandonné (D-04) ;
  le nouvel angle bug de comportement vit désormais sous `PART-06`, pas ici — ce bullet reste
  l'historique exact de ce que le plan 24-10 a réellement produit. *(A9, verdict zone 5, point 4)*
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
| GSDA-19 | Phase 24 | Done — plan 24-10 — superseded par `PART-06` (Phase 39, 2026-09-09) |
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
| PORT-01 | Phase 30 | Complete — 2026-08-16, PR #43, release `v2.53.0` (case cochée ; réserves de l'audit du 2026-09-24 portées par la case) |
| PORT-02 | Phase 30 | Complete — 2026-08-16, PR #43, release `v2.53.0` (case cochée ; réserves de l'audit du 2026-09-24 portées par la case) |
| PORT-03 | Phase 30 | Complete — 2026-08-16, PR #43, release `v2.53.0` (case cochée ; réserves de l'audit du 2026-09-24 portées par la case) |
| PORT-04 | Phase 30 | Tranché 2026-08-15 (Samuel, sans Willy — tracer 01-01 jamais livré) : la Phase 30 porte tout le volet merge-hooks.sh et écrit vf-portable.sh — plan dégaté, spec §3.2 amendée |
| PORT-05 | Phase 30 | Complete — 2026-08-16, PR #43, release `v2.53.0` (case cochée ; réserves de l'audit du 2026-09-24 portées par la case) |
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
| LEDG-01 | Phase 18 | Done — plans 18-01/18-02/18-03 |
| LEDG-02 | Phase 18 | Done — plans 18-01/18-02/18-03 |
| LEDG-03 | Phase 30 | Ouverte le 2026-08-15 — https://github.com/open-gsd/gsd-core/issues/3556 — deadline amont 2026-10-26 |
| BUDG-01 | Phase 25 | Complete — 2026-09-16, plan 25-04 : 31 fichiers mesurés et publiés (`.planning/instruction-budget-baselines.tsv`, conductor v1.37.1) |
| BUDG-02 | Phase 25 | Complete — 2026-09-16, plan 25-04 : ratchet armé (sentinelle `.planning/.instruction-budget-armed`), gate rend 0 armé |
| BUDG-04 | Phase 40.1 | Complete — 2026-09-17, plan 40.1-14 : recensement versionné final rc 0 (0 ligne), contrôles négatifs verts (fixtures 11/11, clone réel 7/7), rejeu CI gates+tests vert, dix bumps dérivés vérifiés |
| BUDG-05 | Phase 40.1 | Complete — 2026-09-17, plan 40.1-14 : bascules CI prouvées par mutants (plan 40.1-03), invariants de phase (M, I1-I4) verts, rejeu gates (10 étapes) et tests (79 suites/0 échec) verts |
| WKTR-01 | Phase 35 | Requalifié 2026-08-26 — énoncé non satisfiable honnêtement : `ensure-deps.sh` ne peut pas attester une clé de settings (`worktree.baseRef`) qu'il ne doit pas écrire ; l'attester quand même serait une couverture déclarée sans couverture effective (Borne 4 de `check-capability-activation.sh`). Close sans être livré — pas une dette |
| WKTR-02 | Phase 35 | Done (option A, 2026-08-26) — leg A **prouvé** (`2026-08-23-...md`, retour en fast-forward, dont un rejeu sur branche réellement divergente le 2026-08-26) ; leg B **mesuré** (`2026-08-26-wktr-02-leg-b-base-de-fork.md` : moteur 1.11.0, HEAD divergent sans réglage → `shouldDegrade=true`, dégradation séquentielle sûre) ; **ré-armement NON effectué, par décision humaine** (sûr mais inerte en conditions de mission — ADR-059 impose une branche dédiée, donc HEAD diverge toujours) |
| WKTR-03 | Phase 30 | Complete — veille armée en Phase 30 (2026-08-16), désarmée le 2026-09-07 une fois son signal consommé par la Phase 35 |
| SKIL-01 | Phase 34 | Done — cadrage rendu, verdict NO-GO, 2026-09-15 — `34-SPIKE-SKIL.md` |
| AGTS-01 | Phase 34 | Done — verdict par gap rendu, 2026-09-15 — `34-AUDIT-AGTS.md` |
| AGTS-02 | Phase 34 | Reportée avec trace — run réel ROUGE, 2026-09-15 — `34-RUN-MOBILE.md`, déclencheur de reprise au ledger (entrée BACKLOG sortie le 2026-11-05, archivée : `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`) |
| QUAL-01 | Transverse — Phases 30, 31, 32, 33, 18, 25, 35, 40.1, 41 | Complete à la clôture du 2026-10-08 (case cochée, re-satisfaite le 2026-09-24 : 32 mutants tués sur cinq suites ; 33 et 18 non re-mesurées à la clôture) — historique : satisfait sur les phases 30, 31 et 32 livrées (30/31 : 3 issues + mutation rouge prouvée ; 32 : amendé à **4** issues par D-32-QUAL — PASS/DENY/imparsable-silencieux/indisponible-BRUYANT — les 4 couvertes, cf. `32-RELIQUATS.md` §5) ; **non déclenché sur la Phase 35** (2026-08-26, option A) — aucun gate ni comparateur neuf n'y naît, donc rien à satisfaire ; **satisfait sur la Phase 25 le 2026-09-16** (`check-instruction-budget.sh` : trois issues exercées sur fixtures, quatre mutants vérifiés par `cmp` dont un par métrique, mutation rouge sur le dépôt armé) ; **satisfait sur la Phase 40.1 le 2026-09-17** (sept mutants du gate tués, dont MUT-2 remplacé ; contrôles négatifs du recensement ; frontière de l'auditeur) ; **satisfait sur la Phase 41 le 2026-09-18** (trois gates neufs — `check-baseline-arbitrage.sh` neuf mutants tués, `check-gate-touche.sh` six mutants tués, `check-push-sans-pr.sh` cinq mutants tués, chacun avec ses trois issues PASS/FAIL/imparsable-BRUYANT — vingt mutants tués mesurés sur les trois gardes CI ; plus les deux outils de la phase — recensement trois mutants tués, contrôle de trace six mutants tués — total mesuré vingt-neuf mutants tués, ligne canonique `✓ MUT-<n> TUE`, rc=0 sur les cinq suites) ; reste à tenir sur 33, 18 |
| PART-01 | Phase 39 | Done — plan 39-02 — shipped v2.60.0 (PR #62, 2026-09-14) |
| PART-02 | Phase 39 | Done — plan 39-02 — shipped v2.60.0 (PR #62, 2026-09-14) |
| PART-03 | Phase 39 | Done — plan 39-03 — shipped v2.60.0 (PR #62, 2026-09-14) |
| PART-04 | Phase 39 | Done — plan 39-01 — shipped v2.60.0 (PR #62, 2026-09-14) |
| PART-05 | Phase 39 | Done — plan 39-02 — shipped v2.60.0 (PR #62, 2026-09-14) |
| PART-06 | Phase 39 | Done — plan 39-02 — shipped v2.60.0 (PR #62, 2026-09-14) |
| PART-07 | Phase 39 | Done — plan 39-03 — shipped v2.60.0 (PR #62, 2026-09-14) |
| PART-08 | Phase 39 | Done — plan 39-03 — shipped v2.60.0 (PR #62, 2026-09-14) ; déclencheur de reprise exécuté le 2026-09-23 (arbitrage Samuel, AskUserQuestion session principale, 2026-09-23) — voir `.planning/missions/2026-09-23-partition-planning-d02.md` |
| PART-09 | Phase 39 | Done — plan 39-03 — shipped v2.60.0 (PR #62, 2026-09-14) |
| PROT-01 | Phase 41 | Complete — 2026-09-24, mandat direct (hors plan 41-13 jamais exécuté) : rulesets posés par Willy (`picmakpro`) le 2026-09-23 19h56, re-mesurés `gh api` le 2026-09-24 (2 rulesets `enforcement: active`, bypass `always` Samuel + Willy) — voir `41-PREUVES.md` § « Clôture PROT-01 » |
| PROT-02 | Phase 41 | Complete — 2026-09-18, plan 41-17/41-19 : ordre des étapes avant `check-release-tag`, absence d'entrée `tags:` dans le déclencheur, voie `merge-commit-sha` pour les merges par rebase, hook `pre-push` conservé |
| PROT-03 | Phase 41 | Complete — 2026-09-18, plan 41-18 : ADR-072 (doctrine des trois gardes et de leur limite de fond) et son résumé dans `CLAUDE.md` |
| PROT-04 | Phase 41 | Complete — 2026-09-18, plan 41-14 : `check-baseline-arbitrage.sh`, neuf mutants tués, observation O-3 du `25-SECURITY.md` signalée et tracée |
| PROT-05 | Phase 41 | Complete — 2026-09-18, plans 41-16/41-17 : exigence née du recadrage sans admin (décision du manager, 2026-09-17), `check-gate-touche.sh` (six mutants tués) et `check-push-sans-pr.sh` (cinq mutants tués) |
| WSAW-01 | Phase 41.1 | Complete — 2026-09-23, plans 41.1-01/02 : `vf_ws_enumerate` (codes 0/2/3, cinq cas de contrat + deux mutants tués) et `check-divergence.sh` qui la consomme, les deux boucles inline dédupliquées, le repli `CHECKED=0` qui sortait en 0 fermé (rc=2 mesuré) |
| WSAW-02 | Phase 41.1 | Complete — 2026-09-23/24, plans 41.1-03/04/05/06 : les consommateurs (b) et (c) passent par la primitive ou déclarent leur motif ; recensement versionné de 21 consommateurs, re-mesuré à l'exécution et rejoué par la CI |
| WSAW-03 | Phase 41.1 | Complete — 2026-09-24, plan 41.1-06 : fixture jetable à trois compartiments (`alpha`/`beta`/`gamma`), bascule exécutée dans l'étape CI elle-même — rouge avec le cassé (« S2 : compartiment « gamma » »), vert sans |
| WSAW-04 | Phase 41.1 | Complete — 2026-09-24, plans 41.1-05/06 : fan-out par compartiment sans câblage supplémentaire (sonde `cablage_dur_restant=0`), et lint anti-oubli qui rougit sur un consommateur non recensé — jamais vert à vide (assertion d'univers non vide sur les deux volets) |
| WSAW-05 | Phase 41.1 | Complete — 2026-09-24, plans 41.1-06/07 : trichotomie appliquée par le fan-out (`gouvernance` → notice non-initialisé + `AMBIGUITE-D02`, jamais un écart ; corrompu → rc=2 compté), définition unique portée par `workstreams.md` §6, identité à D-02 prouvée par `cmp` et `comm` |
| WSAW-06 | Phase 41.1 | Complete — 2026-09-24, plan 41.1-07 : amendement daté d'ADR-069, frontière formulée par le rôle, ancrage ADR-063 erroné nommé (zéro occurrence de « workstream » mesurée sur la section, témoin de plage prouvé par mutation) |
| WSAW-07 | Phase 41.1 | Complete — 2026-09-24, plan 41.1-07 : `workstreams.md` — procédure de bascule et sa précondition, choix au démarrage et non-choix par défaut, affirmation de §3 devenue fausse depuis la PR #94 corrigée |
| WSCH-01 | Phase 41.2 | Complete avec réserve — 2026-10-02, PR #130 : contrat écrit prouvé (23 cas, 4/4 discriminations), comportement en session non exercé, recette au BACKLOG |
| WSCH-02 | Phase 41.2 | Complete — 2026-10-02, PR #130 : création par le moteur, fixture indépendante `e2e.sh` |
| WSCH-03 | Phase 41.2 | Complete — 2026-10-02, PR #130 : `check-planning-not-inflight.sh`, 32 cas, 8/8 mutants tués |
| WSCH-04 | Phase 41.2 | Complete (réserve fixture-only) — 2026-10-02, PR #130 : lab neuf partitionné en CI, gates verts par sujet |
| WSCH-05 | Phase 41.2 | Complete — 2026-10-02, PR #130 : doctrine remise au manager, `workstreams.md` et `docs/ADR.md` non modifiés |
| SOBR-01 | Phase 41.3 | Complete — 2026-09-30, plans 41.3-01, 41.3-02 : rangement constaté par check-method-budget (branches, stash, mémoires) ; dépôt rangé |
| SOBR-02 | Phase 41.3 | Complete — 2026-09-30, plans 41.3-01 : STATE fiabilite 146 Ko → 3 Ko, historique archivé sous archives/state/ |
| SOBR-03 | Phase 41.3 | Complete — 2026-09-30, plans 41.3-02, 41.3-03 : check-blueprints ignore .claude/worktrees ; .worktreeinclude et installeur |
| SOBR-04 | Phase 41.3 | Complete — 2026-09-30, plans 41.3-04 : relecture adverse du diff fonctionnel avant le tag, dans CLAUDE.md |
| SOBR-05 | Phase 41.3 | Complete — 2026-09-30, plans 41.3-04 : ADR-076 et check-ajout-retrait (visible par machine) |
| SOBR-06 | Phase 41.3 | Complete — 2026-09-30, plans 41.3-03 : budgets BACKLOG, index mémoire, ROADMAP ; archivage seul (--archive, --auto) |
| SOBR-07 | Phase 41.3 | Complete — 2026-09-30, plans 41.3-04 : garde de fin de geste (Stop) et contrôle E7 de check-mission-exit |
| SOBR-08 | Phase 41.3 | Complete — 2026-09-30, plans 41.3-03 : prose plafonnée, sujets clos archivés hors du fichier courant |
| POCK-01 | Phase 41.4 | Complete — 2026-10-06, plans 41.4-04, 41.4-10 : frontière de questions au §Pattern F de `mission-flow.md` (une voix, renvois resserrés), épinglée par T39 avec mutations |
| POCK-02 | Phase 41.4 | Complete — 2026-10-06, plans 41.4-05, 41.4-10 : glossaire de domaine `docs/_transverse/` (10 termes sourcés) et son régime dans `docs-flow.md`, épinglé par T42 |
| POCK-03 | Phase 41.4 | Complete — 2026-10-06, plans 41.4-04, 41.4-10 : frontière de phase (continuer, clear, handoff, sous-agent, compact) et ligne « moins cher la prochaine fois » au §3 de `head-governance.md`, ordre prouvé par mutation (T40) |
| POCK-04 | Phase 41.4 | Complete — 2026-10-06, plans 41.4-07, 41.4-10 + corrections ciblées A et C : contrat à deux axes en conjonction (seuil P414-D-20, Spec `skipped` sans PLAN P414-D-22), sonde réelle dans les deux sens (`41.4-SONDE-POCK04.md`, P414-D-07 étendue par P414-D-21) |
| POCK-05 | Phase 41.4 | Complete — 2026-10-06, plan 41.4-03 (correctifs de revue 2026-10-06) : `detect-promotions.sh` pose `nature` et `proposition` et un tableau `findings` ; grille de tri et findings dans `promotion.md`, 90 cas verts, mutants M07-M10 tués |
| POCK-06 | Phase 41.4 | Complete — 2026-10-06, plans 41.4-06, 41.4-10 (correctifs de revue 2026-10-06) : section `## Merge-danger call` au contrat de PR de mission, lue par E3 de `check-mission-exit.sh` (SAIN, MANQUE nommé, INDÉTERMINÉ), 135 assertions dont 35 lignes « TUE » (mutants E3a-E3z, E3x, E3x2, E15, E18), tour 4 du 2026-10-06 |
| POCK-07 | Phase 41.4 | Complete — 2026-10-06, plans 41.4-01, 41.4-08, 41.4-09 (correctifs de revue 2026-10-06) : `check-skills.sh --callers-root`, 26 skills classés `vf-invocation: model` (aucun user-invoked, arbitrage Samuel, AskUserQuestion session principale, 2026-10-06, P414-D-17), étape CI propre avec quatre bascules |
| POCK-08 | Phase 41.4 | Complete — 2026-10-06, plans 41.4-02, 41.4-09 (correctifs de revue 2026-10-06) : segment `défaillance :` obligatoire (contenu jugé : date calendaire ou SHA) et `SKILL.md` surveillés dans `check-ajout-retrait.sh`, 83 cas dont 29 lignes « TUE », consultatif en CI |
| DLWS-01 | Phase 57 | Complete — 2026-10-12, plans 57-01, 57-03, 57-04 : `test-driver-lock-ws.sh` 528/0, un verrou par compartiment, refus sur le même compartiment, concurrence 24×5 (porte de phase `57-16-SUMMARY.md`) |
| DLWS-02 | Phase 57 | Complete — 2026-10-12, plans 57-01, 57-02, 57-04, 57-08, 57-12, 57-13 : verrou de dépôt distinct, release et partition en gestes de dépôt courts (porte de phase `57-16-SUMMARY.md`) |
| DLWS-03 | Phase 57 | Complete — 2026-10-12, plans 57-01, 57-04, 57-05, 57-11 : `test-driver-lock.sh` 243/0 et `test-guard-driver-lock.sh` 103/0 au diff vide contre la base, A/B `WS-AB-INTEGRITE` et `GW-AB-INTEGRITE` IDENTIQUES sans SKIP (porte de phase `57-16-SUMMARY.md`) |
| DLWS-04 | Phase 57 | Complete — 2026-10-12, plans 57-01, 57-02 + P57-D-39 : `--ws` explicite seul, repli `scope: depot` dit au JSON, refus `not-at-lab-root` (porte de phase `57-16-SUMMARY.md`) |
| DLWS-05 | Phase 57 | Complete — 2026-10-12, plans 57-02, 57-04, 57-05, 57-15 : verrous sous `git-common-dir`, partage entre worktrees, repli hors git (porte de phase `57-16-SUMMARY.md`) |
| DLWS-06 | Phase 57 | Complete — 2026-10-12, plans 57-05, 57-08, 57-11 + P57-D-38 : `test-guard-driver-lock-ws.sh` 240/0, commits jugés sur l'index, `checkout`/`switch` refusés (porte de phase `57-16-SUMMARY.md`) |
| DLWS-07 | Phase 57 | Complete — 2026-10-12, plans 57-03, 57-06, 57-07, 57-09, 57-10, 57-12 à 57-15 : consommateurs, doctrine, amendement daté d'ADR-053 (porte de phase `57-16-SUMMARY.md`) |
| DLWS-08 | Phase 57 | Complete — 2026-10-12, plans 57-04 à 57-07, 57-09, 57-11 : mutants DL-M-*, GW-M-*, consommateurs, A/B ; usage concurrent réel reste à la Phase 61 (porte de phase `57-16-SUMMARY.md`) |
| RLPO-01 | Phase 58 | Complete — 2026-10-20, plans 58-06 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-02 | Phase 58 | Complete — 2026-10-20, plans 58-02 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-03 | Phase 58 | Complete — 2026-10-20, plans 58-04, 58-06 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-04 | Phase 58 | Complete — 2026-10-20, plans 58-01 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-05 | Phase 58 | Complete — 2026-10-20, plans 58-01, 58-05 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-06 | Phase 58 | Complete — 2026-10-20, plans 58-06 à 58-08, 58-12 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-07 | Phase 58 | Complete — 2026-10-20, plans 58-08 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-08 | Phase 58 | Complete — 2026-10-20, plans 58-04 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-09 | Phase 58 | Complete — 2026-10-20, plans 58-04 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-10 | Phase 58 | Complete — 2026-10-20, plans 58-03, 58-07, 58-11 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| RLPO-11 | Phase 58 | Complete (override) — critère 6 accepté sans mesure par Samuel, session principale, 2026-10-22, dette : rejouer `check-livraison-58.sh clients` ; critères 1, 2 et 5 verts (58-09, porte de phase 58-11 ; critère 1 re-prouvé le 2026-10-20 par `E2E-C1-DEPS-DECISION`, deux mutants rouges, après la vérification de phase) ; critère 6 en attente de la liste de clients de Samuel (code 2, jamais coché) |
| RLPO-12 | Phase 58 | Complete — 2026-10-20, plans 58-09, 58-10, 58-11 (preuves : SUMMARY des plans et porte de phase `58-11-SUMMARY.md`) |
| PRDT-01 | Phase 59 | Complete — 2026-10-27, plans 59-04, 59-05, 59-06 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-02 | Phase 59 | Complete — 2026-10-27, plans 59-01, 59-06 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-03 | Phase 59 | Complete — 2026-10-27, plans 59-02, 59-04, 59-05 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-04 | Phase 59 | Complete — 2026-10-27, plans 59-04, 59-06 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-05 | Phase 59 | Complete — 2026-10-27, plans 59-02 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). Lecture : `check-prd.sh` lit les fichiers que le manager lui passe en arguments (compartiment résolu, P59-PL-04, P59-PL-08), ce qui le laisse hors du périmètre du recensement de `check-planning-consumers-registered.sh` (7 OK / 0 KO). |
| PRDT-06 | Phase 59 | Complete — 2026-10-27, plans 59-04, 59-06 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-07 | Phase 59 | Complete — 2026-10-27, plans 59-03 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-08 | Phase 59 | Complete — 2026-10-27, plans 59-04, 59-05, 59-06 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-09 | Phase 59 | Complete — 2026-10-27, plans 59-02, 59-04, 59-05, 59-06 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-10 | Phase 59 | Complete — 2026-10-27, plans 59-06 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). Lecture : la boucle de `test-build-module-catalog.sh` n'a pas été modifiée parce qu'elle exclut déjà le bundle par construction (elle nomme trois bundles ; 14 OK / 0 KO), la preuve positive du filtre étant `PTB-CATALOG` de `test-product-team-bundle.sh` (P59-PL-03). |
| PRDT-11 | Phase 59 | Complete — 2026-10-27, plans 59-05, 59-06, 59-07 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| PRDT-12 | Phase 59 | Complete — 2026-10-27, plans 59-01, 59-03, 59-04, 59-08 (preuves : SUMMARY des plans et porte de phase `59-08-SUMMARY.md`). |
| ARCG-01 | Phase 60 | Partial — 2026-10-29 : forme du marqueur, marqueur absent = validée, preuve moteur (60-03, 60-04), verbe de validation (60-04) prouvés (suites `test-check-phase-validation.sh` 46 ok, `test-vf-validation.sh` 35 ok, rejouées à la porte ; reprise du 2026-10-29 : 104 ok et 63 ok après la correction des cas où une phase proposée passait, voir `60-VERIFICATION.md` § Reprise) ; volet « une phase ajoutée par l'équipe aux postes product et dev naît proposée » prouvé seulement par le texte et le lien manager → contrat (T45, 60-06), jamais par une exécution de mission — dette ouverte, BLOQUÉE sur un run réel de mission (geste humain P59-D-11), à prouver ou à accepter par Samuel. |
| ARCG-02 | Phase 60 | Complete — 2026-10-29, plans 60-01, 60-07 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`). |
| ARCG-03 | Phase 60 | Complete — 2026-10-29, plans 60-06 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`). Lecture : refus prouvé par texte ancré (T45, mutants discriminants) ; reprise du 2026-10-29 : seul « phase introuvable » (`marqueur=introuvable`) laisse continuer, tout autre indéterminé arrête (P60-D-15) et par l'exécution de la commande citée sur fixture (1 proposée, 0 sans marqueur) ; aucun run réel de `vf-coder`. |
| ARCG-04 | Phase 60 | Complete — 2026-10-29, plans 60-06 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`). Lecture : même nature de preuve que ARCG-03 (texte ancré et commande citée exécutée), même conduite sur indéterminé (P60-D-15) ; aucun run réel de `vf-auto`. |
| ARCG-05 | Phase 60 | Complete — 2026-10-29, plans 60-06 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`). Lecture : preuve par texte ancré et liens vérifiés (T45 d, e, f), aucun run réel du head ; les hypothèses P60-H-01 à P60-H-04 restent à confirmer par Samuel. |
| ARCG-06 | Phase 60 | Complete — 2026-10-29, plans 60-02, 60-04 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`). |
| ARCG-07 | Phase 60 | Complete — 2026-10-29, plans 60-02 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`) (34 cas, 9 mutants tués ; résolvable depuis le head : T45 f, 60-06). |
| ARCG-08 | Phase 60 | Complete — 2026-10-29, plans 60-05 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`). Lecture : aucun run réel du worker — le bundle reste `proposable:false` (P59-D-11) ; preuve par `check-agents --strict` (trois formes CI), monde fermé et suite `test-product-team-bundle.sh` 104 ok. |
| ARCG-09 | Phase 60 | Partial — 2026-10-29, plans 60-05, 60-06 : registre d'instructions +1 ligne et 0 retrait, aucune valeur existante relevée, `check-instruction-budget.sh` rc 0 (BOOTSTRAP `ligne 2610` inchangée), aucun skill neuf, `check-ajout-retrait --strict` COUVERT pour les deux gates, mutations rouges prouvées ; critère 6 (`clients`, zéro nom de client) NON VÉRIFIABLE : code 2, en attente de la liste (hors dépôt), comme en Phase 58 — jamais compté vert, exigence laissée décochée, BLOQUÉE sur la liste de noms de clients (donnée humaine hors dépôt). |
| ARCG-10 | Phase 60 | Complete — 2026-10-29, plans 60-08 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`) (`check-manual.sh` rc 0, 16 pages FR+EN). |
| ARCG-11 | Phase 60 | Complete — 2026-10-29, plans 60-07, 60-09 (preuves : SUMMARY des plans et porte de phase `60-09-SUMMARY.md`). Porte rejouée depuis `ci.yml` (20 étapes vertes, 3 sautées nommées), suites une à une, ledger à la main ; arrêt avant PR, merge, tag et release. |
| COLB-01 | Phase 61 | Complete — 2026-10-29, plans 61-01, 61-04, 61-08 (preuves : SUMMARY des plans et porte de phase `61-08-SUMMARY.md`). |
| COLB-02 | Phase 61 | Complete — 2026-10-29, plans 61-01, 61-03, 61-08 (preuves : SUMMARY des plans et porte de phase `61-08-SUMMARY.md`). |
| COLB-03 | Phase 61 | Complete — 2026-10-29, plans 61-01, 61-03, 61-04, 61-05, 61-08 (preuves : SUMMARY des plans et porte de phase `61-08-SUMMARY.md`). |
| COLB-04 | Phase 61 | Complete — 2026-10-29, plans 61-01, 61-03, 61-05, 61-07, 61-08 (preuves : SUMMARY des plans et porte de phase `61-08-SUMMARY.md`). |
| COLB-05 | Phase 61 | Complete — 2026-10-29, plans 61-04, 61-07, 61-08 (preuves : SUMMARY des plans et porte de phase `61-08-SUMMARY.md`). |
| COLB-06 | Phase 61 | Complete — 2026-10-29, plans 61-02, 61-06, 61-07, 61-08 (preuves : SUMMARY des plans et porte de phase `61-08-SUMMARY.md`). |
| COLB-07 | Phase 61 | Complete — 2026-10-29, plans 61-01, 61-05, 61-08 (preuves : SUMMARY des plans et porte de phase `61-08-SUMMARY.md`). |
| COLB-08 | Phase 61 | Pending — 2026-10-29 : procédure de recette livrée (`61-RECETTE-LAB-REEL.md`, plan 61-05), relevé joué par D2C-RELEVE sur clones jetables ; preuve humaine attendue (P61-B-01 lab et humains, P61-B-02 trois semaines), jamais simulée. **Bloqueur humain : lab et deux humains à désigner par Samuel** (non désignés au 2026-10-29). |
| COLB-09 | Phase 61 | Partial — 2026-10-29, tous les plans 61-01 à 61-08 : aucune valeur de `.planning/instruction-budget-baselines.tsv` relevée, `check-instruction-budget.sh` rc 0 (37 fichiers, BOOTSTRAP `ligne 2610`), aucun skill ni agent touché, `scripts/hooks`, `.github` et sentinelles intacts, G-2 rc 0 (marqueurs 32/32), `check-ajout-retrait --strict` rc 0, `check-version-sync` et `check-manual` rc 0, job `gates` rejoué depuis `ci.yml` (20 rejouées, 0 en échec), quinze suites une à une vertes, arrêt avant PR ; critère 6 (`clients`, zéro nom de client) NON VÉRIFIABLE : code 2, en attente de la liste (hors dépôt), comme en Phases 58 et 60 — jamais compté vert, exigence laissée décochée. |
| PLTF-01 | Phase 62 | Complete — 2026-10-29, plan 62-01 (preuve : `62-DECISION-plateforme.md`, `62-01-SUMMARY.md`) |
| PLTF-02 | Phase 62 | Complete — 2026-10-29, décision A signée par délégation (preuve : `62-DECISION-plateforme.md` § Décision, `62-CONTEXT.md` P62-B-01 levé) ; réexamen 2027-01-31 |
| CKPT-01 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-who.sh (W1-W4) et test-cockpit-projet.sh ; 67-02-SUMMARY.md ; f40ce17c, 7420670d, 78eeee91 ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-02 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-vendor.sh (V1-V8) ; 67-03-SUMMARY.md ; e2b2eae6, cf7372eb, 7ac4805d ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-03 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-reseau.sh (R1-R3), test-cockpit-assemblage.sh, test-cockpit-vendor.sh ; 67-03/67-04-SUMMARY.md ; 6fd4ec61, 0842de46, c7b105da ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-04 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-marque-blanche.sh ; 67-03-SUMMARY.md ; e2b2eae6, cf7372eb, 7ac4805d ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-05 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-direct.sh (D1-D5), test-cockpit-serveur.sh, test-cockpit-reconnexion.sh ; 67-04-SUMMARY.md ; 6fd4ec61, 0842de46, c7b105da ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-06 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-projet.sh, test-cockpit-onglet-code.sh ; 67-02/67-05-SUMMARY.md ; 78eeee91, 5a09548d, 233c05ad ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-07 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-questions.sh, test-cockpit-robustesse.sh, test-cockpit-securite.sh ; 67-05-SUMMARY.md, 67-SECURITY.md ; 5a09548d, 233c05ad, 324986c2 ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-08 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-serveur.sh (S5-S8) ; 67-04-SUMMARY.md ; 6fd4ec61, 0842de46, c7b105da ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-09 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-chrome-fr.sh ; 67-07-SUMMARY.md ; e3e86895, bae638a6 ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-10 | Phase 67 | Complete — 2026-11-03, phase close (preuves : plugin/_internal/tests/test-vibeflow-update-cockpit.sh ; 67-06-SUMMARY.md ; 7f5f5421, ebc63e98. Le bump racine v2.75.0 est postérieur à la phase (arbitrage Samuel, AskUserQuestion session principale, 2026-11-02) : la contrainte « aucun bump » valait pendant la phase ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-11 | Phase 67 | Complete — 2026-11-03, phase close (preuves : plugin/conductor/scripts/tests/test-dag-atomic-save.sh ; 67-01-SUMMARY.md ; 0ac4e7f1, 5d535143, 3c30769b ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-12 | Phase 67 | Complete — 2026-11-03, phase close (preuves : test-cockpit-responsive.sh (R1-R4) ; 67-FIX-B-SUMMARY.md, 67-FIX-C-SUMMARY.md ; a253d713, ce63c0b1 ; recette `67-RECETTE-HUMAINE.md` validée, § 8.2 ; détail : `67-CLOTURE.md`) |
| CKPT-13 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-14 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-15 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-16 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-17 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-18 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-19 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-20 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-21 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-22 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-23 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-24 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-25 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-26 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-27 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| CKPT-28 | Phase 69 | Complete — 2026-11-04 (Phase 69, PR #198) |
| UIFN-01 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-04 (`test-cockpit-responsive.sh`, R13 à R16, 261/0 ; borne `.hl` à 342 px calculée, R4.2 mutant à 400 px) et 70-10 ; points 1 et 1 bis de `70-RECETTE-JUGES.md` (1 bis tranché par P70-D-22) ; suite à 291/0 et CI de la PR #200 verte à `a15b073d` ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur la recette par juges, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-02 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-05 (R14 verts, `aria-label` à toutes les largeurs) ; points 3, 3 bis de `70-RECETTE-JUGES.md` ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur la recette par juges, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-03 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-05 (R15.1 à R15.4c verts) ; point 2 de `70-RECETTE-JUGES.md` ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur la recette par juges, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-04 | Phase 70 | Complete — 2026-11-04 (Phase 70, PR #200 mergée, `503aa657` ; `requirements-completed` de `70-07-SUMMARY.md` ; points 4 et 4 bis de `70-RECETTE-JUGES.md`, REG-70-01 corrigée en `42ae27cb` ; visite corrigée) |
| UIFN-05 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-08 (`test-cockpit-projet.sh` 86/0, O6.1 à O6.9, O6.5 dans Chrome à 1 440 et 390 px) ; point 4 de `70-RECETTE-JUGES.md` ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur la recette par juges, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-06 | Phase 70 | Complete — 2026-11-04 (Phase 70, PR #200 mergée, `503aa657` ; `requirements-completed` de `70-03-SUMMARY.md` ; point 5 de `70-RECETTE-JUGES.md` ; anglais résiduel du chrome) |
| UIFN-07 | Phase 70 | Complete — 2026-11-04 (Phase 70, PR #200 mergée, `503aa657` ; `requirements-completed` de `70-01-SUMMARY.md` ; témoin rouge puis vert, `70-01-RED-TRACE.md` ; garde du français durci) |
| UIFN-08 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-06 (Q15 à Q17 rouges, 57 PASS / 8 FAIL, puis verts, `test-cockpit-questions.sh` 65/0 ; réponse avant et après consignée) ; aucun point de juge, preuve par suite rouge puis verte ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur preuve de suite, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-09 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-02 (`test-cockpit-marque-blanche.sh` 30/0 : M5.3 rouge sur la base puis vert, M5.1 et M5.2 gardées par un mutant chacune) ; point 6 de `70-RECETTE-JUGES.md` ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur la recette par juges, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-10 | Phase 70 | Pending — 2026-11-03 (cadrage ; captures et recette par juges, réécrite 2026-11-04, P70-D-19) ; reste décochée au 2026-11-11 : recette par juges et tri de goût faits le 2026-11-04, mais captures « avant » et « après » hors dépôt sans empreinte (P70-D-17, écart de `70-09-SUMMARY.md`) et corrections postérieures aux têtes jugées sans nouvelle capture (`70-RECETTE-JUGES.md`, écart 4) |
| UIFN-11 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-02 (cinq réglages) ; point 7 de `70-RECETTE-JUGES.md` (conforme après correction du badge hors de la carte, `643bc7ac` et `94078aab`) ; tri de goût, question 12 ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur la recette par juges, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-12 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-11 (EK1 rouge puis vert, EK8 et EK9, un mutant par témoin) ; point 8 de `70-RECETTE-JUGES.md` ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur la recette par juges, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-13 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-11 (EK2 à EK5 et W19, chacun avec son mutant : m1, m10, m8, m5, m6, posé dans la page servie ou une copie) ; aucun point de juge, preuve par suite et mutants ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur preuve de suite, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| UIFN-14 | Phase 70 | Complete — 2026-11-11 (Phase 70, PR #200 mergée, `503aa657`, publiée en `v2.76.0` ; 70-12 (R17 à R20 : 7 FAIL sur le code d'avant puis verts ; R18 non reproduit, témoin négatif ; page Équipe dans la matrice responsive, R20) ; points 3 ter et 9 de `70-RECETTE-JUGES.md` ; SUMMARY sous la clé `requirements` et non `requirements-completed` ; coché sur la recette par juges, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) |
| VFSG-01 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/signal/tests/embarque.test.tsx ; test-vibeflow-update-cockpit.sh (I9) ; claude plugin validate --strict ; 68-04-SUMMARY.md) |
| VFSG-02 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/signal/tests/embarque.test.tsx (E1, E4) ; 68-12-SUMMARY.md) |
| VFSG-03 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/scripts/tests/test-cockpit-signal.sh ; test-cockpit-signal-mod.sh ; 68-03-SUMMARY.md, 68-06-SUMMARY.md) |
| VFSG-04 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : test-cockpit-who.sh ; plugin/cockpit/signal/tests/equipe.test.tsx ; 68-07-SUMMARY.md) |
| VFSG-05 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/scripts/tests/test-cockpit-retard.sh ; 68-02-SUMMARY.md, 68-05-SUMMARY.md) |
| VFSG-06 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/scripts/tests/test-cockpit-vie.sh ; 68-01-SUMMARY.md ; 68-FIX-Q3-SUMMARY.md (P68-D-33)) |
| VFSG-07 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/signal/tests/graphite.test.tsx ; test-cockpit-signal-mod.sh (M9, M10) ; 68-08-SUMMARY.md) |
| VFSG-08 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : étape 24 du job gates de ci.yml ; runs CI 41857935466 (rouge) et 41859018567 (vert) ; 68-13-SUMMARY.md, 68-09-SUMMARY.md) |
| VFSG-09 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/signal/tests/embarque.test.tsx (E4, E4b) ; 68-12-SUMMARY.md) |
| VFSG-10 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/signal/tests/actions.test.tsx ; 68-07-SUMMARY.md) |
| VFSG-11 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/signal/tests/socle.test.tsx ; test-cockpit-signal.sh ; 68-03-SUMMARY.md, 68-05-SUMMARY.md) |
| VFSG-12 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : recette par juges 68-RECETTE-HUMAINE.md (étapes 4 et 5 reportées après la PR, P68-D-35) ; check-machine-paths.sh ; 68-10-SUMMARY.md) |
| VFSG-13 | Phase 68 | Complete — 2026-11-04 (Phase 68, PR #199 mergée le 2026-11-04, publiée en `v2.76.0` ; preuves : plugin/cockpit/VERSION v1.2.0 ; 68-RELECTURE-ADVERSE.md ; 68-11-SUMMARY.md ; bump racine, tag et release groupés hors phase (P68-D-31)) |
| TERM-01 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-02 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-03 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-04 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-05 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-06 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-07 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-08 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-09 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-10 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-11 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| TERM-12 | Phase 71 | Complete — 2026-11-05 (PR #203 et #209, recette humaine du 2026-11-05) |
| LANC-01 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-02 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-03 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-04 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-05 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-06 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-07 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-08 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-09 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-10 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-11 | Phase 72 | Complete — 2026-11-06 (suites vertes, audit du lot 3 SECURED ; PR #214 reprise dans la PR de release #217, publiée en `v2.76.0`) |
| LANC-12 | Phase 72 | Pending — 2026-11-05 (planification) ; au 2026-11-11, fait : bout en bout au faux `claude` (`test-cockpit-lancer-bout-en-bout.sh` 54/0, `72-12-SUMMARY.md`), suites vertes sous macOS et Linux (CI de la PR #217) ; manque : la recette avec le vrai `claude`, à jouer avec la reconfirmation du mode « hérité du poste » (`AUDC-Q1`) |
| GITC-01 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-02 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-03 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-04 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-05 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-06 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-07 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-08 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-09 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-10 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-11 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-12 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-13 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| GITC-14 | Phase 78 | Complete — 2026-11-06 (Phase 78, PR #216, publiée en `v2.76.0` ; revue, audit en lecture, critique design et recette par juges navigateur) |
| REGI-01 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-02 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-03 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-04 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-05 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-06 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-07 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-08 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-09 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-10 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-11 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-12 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-13 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-14 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-15 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-16 | Phase 73 | Pending — 2026-11-11 (cadrage) |
| REGI-17 | Phase 73 | Pending — 2026-11-11 (cadrage, P73-D-37) |
| TEMP-01 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-02 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-03 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-04 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-05 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-06 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-07 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-08 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-09 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-10 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-11 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| TEMP-12 | Phase 74 | Pending — posée au cadrage (2026-11-11) |
| ACTV-01 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-02 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-03 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-04 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-05 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-06 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-07 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-08 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-09 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-10 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-11 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| ACTV-12 | Phase 75 | Pending — 2026-11-11 (cadrage) |
| TRAC-01 | Phase 76 | Complete |
| TRAC-02 | Phase 76 | Complete |
| TRAC-03 | Phase 76 | Complete |
| TRAC-04 | Phase 76 | Complete |
| TRAC-05 | Phase 76 | Complete |
| TRAC-06 | Phase 76 | Complete |
| TRAC-07 | Phase 76 | Complete |
| TRAC-08 | Phase 76 | Complete |
| TRAC-09 | Phase 76 | Complete |
| TRAC-10 | Phase 76 | Complete |
| TRAC-11 | Phase 76 | Complete |
| TRAC-12 | Phase 76 | Complete |
| TRAC-13 | Phase 76 | Complete |
| SYNT-01 | Phase 77 | Complete — 2026-11-14, plans 77-05, 77-06 (PR #242) |
| SYNT-02 | Phase 77 | Complete — 2026-11-14, plans 77-01 (PR #242) |
| SYNT-03 | Phase 77 | Complete — 2026-11-14, plans 77-03 (PR #242) |
| SYNT-04 | Phase 77 | Complete — 2026-11-14, plans 77-01, 77-03, 77-06 (PR #242) |
| SYNT-05 | Phase 77 | Complete — 2026-11-14, plans 77-04, 77-08 (PR #242) |
| SYNT-06 | Phase 77 | Complete — 2026-11-14, plans 77-04, 77-08 (PR #242) |
| SYNT-07 | Phase 77 | Complete — 2026-11-14, plans 77-02, 77-04, 77-08 (PR #242) |
| SYNT-08 | Phase 77 | Complete — 2026-11-14, plans 77-02, 77-06 (PR #242) |
| SYNT-09 | Phase 77 | Complete — 2026-11-14, plans 77-02 (PR #242) |
| SYNT-10 | Phase 77 | Complete — 2026-11-14, plans 77-07 (PR #242) |
| SOCL-01 | Phase 79 | Complete — 2026-11-13, plan 79-01 (segment a) |
| SOCL-02 | Phase 79 | Complete — 2026-11-13, plan 79-02 (segment a) |
| SOCL-03 | Phase 79 | Complete — 2026-11-13, plan 79-03 (segment a) |
| SOCL-04 | Phase 79 | Complete — 2026-11-13, plan 79-03 (segment a) |
| SOCL-05 | Phase 79 | Complete — 2026-11-13, plan 79-04 (segment a) |
| SOCL-06 | Phase 79 | Complete — 2026-11-13, plan 79-05 (segment a) |
| SOCL-07 | Phase 79 | Complete — 2026-11-13, plan 79-06 (segment a) |
| SOCL-08 | Phase 79 | Complete — 2026-11-13, plan 79-06 (segment a) |
| SOCL-09 | Phase 79 | Complete — 2026-11-13, plan 79-06 (segment a) |
| SOCL-10 | Phase 79 | Complete — 2026-11-13, plan 79-07 (segment a) |
| SOCL-11 | Phase 79 | Complete — 2026-11-13, plan 79-07 (segment a) |
| SOCL-12 | Phase 79 | Complete — 2026-11-13, plan 79-08 (segment a) |
| SOCL-13 | Phase 79 | Complete — 2026-11-13, plan 79-09 (segment a) |
| SOCL-14 | Phase 79 | Complete — 2026-11-13, plan 79-10 (segment a) |
| SOCL-15 | Phase 79 | Complete — 2026-11-13, plan 79-11 (segment a) |
| SOCL-16 | Phase 79 | Complete — 2026-11-13, plan 79-12 (segment a) |
| SOCL-17 | Phase 79 | Complete — 2026-11-14, plan 79-13 |
| SOCL-18 | Phase 79 | Complete — 2026-11-14, plan 79-14 |
| SOCL-19 | Phase 79 | Complete — 2026-11-14, plan 79-15 |
| SOCL-20 | Phase 79 | Complete — 2026-11-14, plan 79-16 |
| SOCL-21 | Phase 79 | Complete — 2026-11-14, plan 79-17 |
| SOCL-22 | Phase 79 | Complete — 2026-11-14, plan 79-18 |
| SOCL-23 | Phase 79 | Complete — 2026-11-14, plan 79-15 |
| SOCL-24 | Phase 79 | Complete — 2026-11-14, plan 79-19 (sonde S0 : journal non construit) |
| SOCL-25 | Phase 79 | Complete — 2026-11-14, plan 79-20 |
| SOCL-26 | Phase 79 | Complete — 2026-11-13, plan 79-21 (segment a) |
| SOCL-27 | Phase 79 | Complete — 2026-11-14, plan 79-22 |
| FORM-01 | Phase 80 | Complete — 2026-11-12 (Phase 80, segment a, 80-01 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes, PR vers integration/cockpit-audit) |
| FORM-02 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-02, 80-14 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-03 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-09, 80-15 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-04 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-14 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-05 | Phase 80 | Complete — 2026-11-12 (Phase 80, segment a, 80-04 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes, PR vers integration/cockpit-audit) |
| FORM-06 | Phase 80 | Complete — 2026-11-12 (Phase 80, segment a, 80-03 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes, PR vers integration/cockpit-audit) |
| FORM-07 | Phase 80 | Complete — 2026-11-12 (Phase 80, segment a, 80-03 et 80-04 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes, PR vers integration/cockpit-audit) |
| FORM-08 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-08, 80-11 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-09 | Phase 80 | Complete — 2026-11-12 (Phase 80, segment a, 80-07 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes, PR vers integration/cockpit-audit) |
| FORM-10 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-05, 80-09 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-11 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-12 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-12 | Phase 80 | Complete — 2026-11-12 (Phase 80, segment a, 80-05 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes, PR vers integration/cockpit-audit) |
| FORM-13 | Phase 80 | Complete — 2026-11-12 (Phase 80, segment a, 80-06 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes, PR vers integration/cockpit-audit) |
| FORM-14 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-16, 80-17 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-15 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-13, 80-14 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-16 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-10, 80-21 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) |
| FORM-17 | Phase 80 | Pending — suites vertes sous macOS au point de fusion (2026-11-14) ; attend la CI Linux |
| FORM-18 | Phase 80 | Complete — 2026-11-14 (Phase 80, 80-14, 80-15, 80-19, 80-20 ; suites du plan vertes, SUMMARY posé ; branche feat/phase-80-trois-formes) ; réouvertures tranchées (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11) |

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
- La famille PROT (5 IDs) est inscrite par la Phase 41 le 2026-09-18, portant le ledger du
  milestone à 35 IDs — dont PROT-01 hors d'atteinte sans accès admin (mesuré le 2026-09-17) et
  PROT-05 créée en cours de phase par le recadrage sans admin (décision du manager, 2026-09-17).
- Milestone vibeflow-v2.0 — cadrages du 2026-11-11 (audit du cockpit) : **109 exigences neuves, toutes
  Pending**, en sept familles — `SOCL-01..27` (Phase 79, 27), `FORM-01..18` (Phase 80, 18), `REGI-01..17`
  (Phase 73, 17), `TEMP-01..12` (Phase 74, 12), `ACTV-01..12` (Phase 75, 12), `TRAC-01..13` (Phase 76, 13),
  `SYNT-01..10` (Phase 77, 10) — mappées aux **93 plans** écrits (79 : 22, 80 : 21, 73 : 11, 74 : 10, 75 : 12,
  76 : 9, 77 : 8), **0 non-mappé**, **0 doublon** (une ligne de traçabilité par exigence, recomptée à la source).

## Milestone fiabilite-v1.0 — « ce qui survit » (démarré 2026-08-15)

> Périmètre arbitré par Samuel le 2026-08-15 après audit d'utilité réelle et de faisabilité
> (31 → 26 exigences ; chaque famille adossée à une preuve : incident documenté, demande externe,
> ou bug récurrent par construction). Recherche : `.planning/research/SUMMARY.md` (commit
> `5916899`). Coupes : BUDG-03 différé, SKIL réduit à un cadrage go/no-go, AGTS réduit,
> MANI sans hash conffile, LOCK-03 en détection d'abord.

### Portabilité Windows II (prioritaire — demande client)
- [x] **PORT-01**: Les 3 fichiers du lot PYBIN passent par la lib partagée `vf-portable.sh` (contrat PR #29 consommé, jamais réinventé)
- [x] **PORT-02**: `merge-hooks.sh` apprend la forme exec (`args`) AVANT toute migration de fragments — ordre (a) moteur → (b) codes de sortie → (c) hooks.json encodé en vagues dépendantes du plan (spec §1.3)
- [x] **PORT-03**: Contrat de codes de sortie normalisé pour les scripts de hooks, inventaire des 19 entrées réalisé — **note (audit 2026-09-24)** : l'inventaire RÉEL mesuré fait **29 entrées, pas 19** ; le 19 de l'énoncé était un repère d'avant-mesure, jamais mis à jour après coup. Livré quand même : le contrat de codes de sortie couvre les 29 entrées réelles.
- [x] **PORT-04**: L'affectation §3.2 (résolution du chemin absolu de bash à l'install) est tranchée avec Willy et documentée avant le plan de la phase — **note (audit 2026-09-24)** : l'affectation a en réalité été **tranchée unilatéralement par Samuel**, Willy informé APRÈS coup — pas un co-arbitrage comme l'énoncé le nomme. Écart assumé, documenté ici pour ne pas le lisser.
- [x] **PORT-05**: La portabilité est prouvée en CI sur lab frais (suites windows-crlf + windows-guards + gates verts) — **note (audit 2026-09-24)** : la preuve porte sur des **fixtures qui SIMULENT Windows** (CRLF, guards) — aucun runner Windows réel n'a exécuté cette suite. Repli assumé et documenté (ADR-054), pas une preuve sur machine Windows.

### Manifeste d'install + dry-run (issue #20)
- [x] **MANI-01**: Chaque module posé écrit son manifeste de chemins (`$TARGET_ROOT/scripts/.vibeflow-manifest-<module>`, LF trié, un chemin par ligne)
- [x] **MANI-02**: `--dry-run` montre le plan de pose fichier-par-fichier sans rien écrire — même chemin de code que la pose (install + calibrate)
- [x] **MANI-03**: L'update supprime les chemins de l'ancien manifeste absents du nouveau, avec backup systématique et liste signalée à l'utilisateur
- [x] **MANI-04**: L'issue GitHub #20 est close par livraison, réponse postée sur l'issue — **état exact (audit 2026-09-24, mis à jour après le geste)** : réponse postée sur l'issue le 2026-08-16 (commentaire de `samuel-neveugall`, corps identique au brouillon `31-ISSUE-20-REPLY.md`) ; issue **fermée le 2026-09-24 par la session principale, sur autorisation explicite de Samuel** (`✓ Closed issue picmakpro/vibeflow-os#20`). La mention antérieure « superseded / gestes humains non faits en mission » est périmée, retirée.

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
- [x] **BUDG-01**: Le budget d'instructions par fichier d'agent distribué est mesuré et publié (métrique tranchée au cadrage de la phase) — **close le 2026-09-16** (plan 25-04) : `check-instruction-budget.sh` mesure 31 fichiers (lignes du fichier, instructions du body, D-01 bis), valeurs publiées dans `.planning/instruction-budget-baselines.tsv` (3641 lignes / 487 instructions) et au CHANGELOG conductor v1.37.1
- [x] **BUDG-02**: Le gate est en ratchet — avertit d'abord, bloque au merge, jamais rouge des semaines — **close le 2026-09-16** (plan 25-04) : avertissement CI non bloquant pendant la première PR (conductor v1.37.0), sentinelle posée dans le même commit que la baseline, gate armé rendant 0 sur le dépôt (jamais entré rouge) ; mutation rouge prouvée sur le dépôt réel (ligne ajoutée à `vf-dev-manager.md` → exit 1) ; conductor v1.37.1
- [x] **BUDG-04**: Le plafond ADR-029 des agents vaut 300 lignes partout où il est énoncé ou mesuré (gate, CI, suites de modules, auditeur de densité et méthodologie distribués, doctrine, manuel), avec un avertissement non bloquant dès 251 ; chaque outil garde sa mesure (fichier entier ou body) — Phase 40.1, D-01/D-05/D-06 — **close le 2026-09-17** (plan 40.1-14) : recensement versionné final rc 0, contrôles négatifs vérifiés (fixtures et clone réel), rejeu CI tests+gates vert
- [x] **BUDG-05**: Le ratchet du budget ne bloque plus que les ajouts d'instructions, par fichier ; une croissance de lignes sans instruction sous le plafond reste verte — prouvé par bascules sur fixture dans l'étape CI elle-même — Phase 40.1, D-02/D-07 — **close le 2026-09-17** (plan 40.1-14) : bascules CI prouvées par mutants (plan 40.1-03), invariants de phase verts, rejeu gates+tests vert

### Posture de protection du dépôt (Phase 41 — périmètre sans admin)
- [x] **PROT-01**: Rulesets de branche et de tags posés et prouvés par un refus réel.
  — hors d'atteinte sans accès admin : mesure `admin: false, maintain: false, push: true` sur le
  dépôt, 2026-09-17, deux lectures indépendantes (compte de Samuel `samuel-neveugall` :
  `admin: false, maintain: false, push: true`) ; le compte `picmakpro`, seul admin, est celui de
  Willy, co-mainteneur du dépôt. Reprise (2026-09-23) : fait corrigé — `picmakpro` est le compte de
  Willy, admin du dépôt (`41-CONTEXT.md` § REPRISE) ; accès admin constaté, volet côté serveur
  replanifié (plans 41-01 à 41-13) ; contournement accordé à Samuel et Willy nommément, mode
  `always` (D-02bis — arbitrage Willy, AskUserQuestion session principale, 2026-09-23). Séquence :
  Willy pose les rulesets → preuve → clôture du jalon `fiabilite-v1.0` (PROT-01 en fait partie, ne
  peut donc pas se clore avant — correction du 2026-09-23 d'une formulation antérieure qui
  inversait cette séquence, cf. `BACKLOG.md` § « Protection de `main` côté GitHub »). Renvoi :
  `BACKLOG.md` § « Protection de `main` côté GitHub — DIFFÉRÉ » et `41-CONTEXT.md` § Prémisse
  renversée (D-01 à D-08 suspendus, non annulés).
  - **Exigence close le 2026-09-24** (mandat direct, hors plan 41-13 jamais exécuté) — preuves :
    rulesets posés par Willy (`picmakpro`) le 2026-09-23 19h56 et re-mesurés le 2026-09-24
    (`gh api repos/picmakpro/vibeflow-os/rulesets`, `41-PREUVES.md` § « Clôture PROT-01 ») :
    `RULESETS-APRES` — deux rulesets `enforcement: active` (`23892920` sur `refs/heads/main`,
    `23892922` sur `refs/tags/v*`) ; `RULESET-MAIN` — règles `pull_request` (0 approbation requise,
    `require_code_owner_review: true`, méthodes merge/squash/rebase), `required_status_checks` (4
    contextes épinglés `integration_id: 15368`, politique stricte), `deletion`, `non_fast_forward` ;
    `RULESET-TAGS` — `deletion`, `non_fast_forward`, `update`, création libre ; `BYPASS-ACTEURS` —
    `current_user_can_bypass: always` mesuré en direct pour Samuel (`samuel-neveugall`, id
    `151974738`), relayé de la mesure de la session principale du 2026-09-24 pour Willy
    (`picmakpro`, id `203482067`, non re-vérifié depuis ce compte faute de moyen de s'y
    authentifier) — les deux `actor_id` correspondent à `ACTEURS-CONTOURNEMENT` (41-01, reprise) et
    aux `bypass_actors` des deux sources versionnées `.github/rulesets/*.json`. `ECART-DEFAUT-SERVEUR` —
    le champ `require_extra_approval_for_unattributed_changes: true` figure côté serveur sur les
    deux rulesets, absent des sources versionnées ; défaut GitHub non demandé, sans effet observé
    sur le comportement décrit par cette exigence, consigné et non corrigé (`BACKLOG.md` §
    « Protection de `main` côté GitHub »). Aucun refus réel de merge n'a été rejoué dans ce mandat
    (pas de PR de test délibérément non conforme poussée) — la preuve du refus tient à la
    configuration serveur mesurée (revue code owner + 4 checks requis, 0 bypass hors liste), pas à
    un rejeu observé ; recensé comme tel, jamais présenté comme un rejeu réel.
  **Note (PR #106, arbitrage Willy, WhatsApp, 2026-09-24)** : une mesure de configuration
  (lecture des rulesets) n'est pas un refus ; la PR #100, ouverte par `samuel-neveugall` et touchant
  `.github/workflows/ci.yml`, a été vue `BLOCKED` par la revue code owner exigée malgré le
  contournement disponible — c'est le refus réel observé. Son merge se fait par contournement
  tracé (`gh pr merge --admin`, arbitrage Samuel, AskUserQuestion session principale, 2026-09-25).
  - **Traçabilité (2026-10-02)** : Cochée le 2026-09-24 sur la pose des rulesets ; la mesure du refus réel d'un push direct (41-09, complément en 41-13) est confiée à Willy, complément attendu (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02).
- [x] **PROT-02**: Compatibilité avec la discipline de release du `CLAUDE.md`. **COCHÉ** —
  clôture citant les clés `REJEU-GATES` et `G3-FIXTURE` (registre `41-PREUVES.md` § 41-19) et les
  trois preuves du plan 41-17 : ordre des étapes avant `check-release-tag`, absence d'entrée
  `tags:` dans le déclencheur, voie `merge-commit-sha` pour les merges par rebase — plus le hook
  `pre-push` conservé.
- [x] **PROT-03**: Politique de contournement et de hotfix écrite. **COCHÉ** — clôture citant
  ADR-072 (plan 41-18) et son résumé dans `CLAUDE.md`, avec la précision que l'amendement d'ADR-059
  est hors périmètre faute de règle serveur qui l'appliquerait.
- [x] **PROT-04**: Observation O-3 du `25-SECURITY.md`, **signalée et tracée** par des gardes
  in-repo — non plus par `CODEOWNERS` et revue code owner, inatteignables sans admin. **COCHÉ** —
  clôture citant `check-baseline-arbitrage.sh` (plan 41-14), ses neuf mutants tués, les clés
  `G1-REEL` et `RECENSEMENT-FINAL` (registre `41-PREUVES.md` § 41-19). Ce script est le seul foyer
  de PROT-04 depuis la décision du manager du 2026-09-17 ; `check-gate-touche.sh` relève de
  PROT-05. Le changement de moyen (`CODEOWNERS` → gardes in-repo) est un arbitrage du 2026-09-17,
  pas une réduction silencieuse. Le statut d'O-3 reste « signalée et tracée » — objet distinct de
  la clôture de l'exigence, écrit dans une phrase séparée.
- [x] **PROT-05** *(exigence née du recadrage sans admin — décision du manager du 2026-09-17 sur
  remontée du planificateur, arbitrage Samuel, AskUserQuestion session principale, 2026-09-17)*:
  Les gardes in-repo de la surface de gate et du flux d'arrivée sur `main` rendent une atteinte
  visible et tracée ; aucune n'est présentée comme une protection absolue. **COCHÉ** — clôture
  citant `check-gate-touche.sh` et `check-push-sans-pr.sh` (plans 41-16 et 41-17), leurs mutants
  tués (six et cinq), les clés `G2-REEL` et `G3-FIXTURE` (registre `41-PREUVES.md` § 41-19). Née de
  la suspension de D-01 à D-08 (2026-09-17) : ces deux scripts se retrouvaient sans foyer
  d'exigence. La clause « aucune n'est présentée comme une protection absolue » est opposable —
  vérifiée par machine par `tools/check-aucune-fermeture.sh` (interdiction de co-occurrence, sonde
  de limite de fond). L'énoncé a été **reformulé** le 2026-09-17 (décision du manager, bloquant 2
  du vérificateur frais) : la première rédaction portait un jeton d'achèvement et déclenchait son
  propre recensement ; la reformulation n'en contient aucun, sans quatrième entrée d'allowlist.

### Ré-armement worktree (phase conditionnelle — jamais bloquante ; close 2026-08-26, option A)
- [~] **WKTR-01** *(requalifié, pas livré)*: la précondition externe (gsd-core > 1.10.0 releasé ET installé) est bien tombée, mais l'attestation prévue (`# vf-provides: worktree-baseref` porté par `ensure-deps.sh`) n'est pas satisfiable honnêtement — `ensure-deps.sh` ne doit pas écrire `worktree.baseRef`, donc il ne peut pas l'attester sans produire une couverture déclarée sans couverture effective (Borne 4)
- [x] **WKTR-02**: leg A prouvé (retour des commits, `2026-08-23-...md` + rejeu 2026-08-26 sur branche divergente) ; leg B mesuré (`2026-08-26-wktr-02-leg-b-base-de-fork.md`) — sûr (dégradation séquentielle si HEAD diverge) mais inerte en conditions de mission (ADR-059). **Décision humaine : ne pas ré-armer** — les deux gates (`check-agents.sh`, règle 4 de `check-capability-activation.sh`) restent en place
- [x] **WKTR-03** *(portée par la Phase 30, hors mandat de cette clôture)*: La veille de release gsd-core est active dès le jour 1

### Skill-installer global (réduit à un cadrage)
- [x] **SKIL-01**: Un cadrage go/no-go répond à « que fait-il de plus que le natif `/plugin` ? » — abandon documenté si la réponse est creuse ; aucun code avant le go — **cadrage rendu (NO-GO), 2026-09-15 : `34-SPIKE-SKIL.md`**. Règle appliquée : l'exigence demande un cadrage écrit, pas un GO — un NO-GO documenté la satisfait tout autant ; ne coche pas si le verdict avait été `MESURE INVALIDE`.

### Gaps agency-agents (réduit)
- [x] **AGTS-01**: Les gaps sont arbitrés en distillant la taxonomie du catalogue — jamais d'import des personas — **verdict par gap rendu, 2026-09-15 : `34-AUDIT-AGTS.md`** (six refusés faute de preuve D-02, un reporté sur AGTS-02, zéro combler, zéro agent créé)
- [ ] **AGTS-02**: `web-test-team` est construite SI mobile-test sort du statut expérimental pendant le milestone (seule piste alignée fiabilité) ; sinon l'exigence est reportée avec trace — **run réel joué 2026-09-15, chapeau ROUGE : `34-RUN-MOBILE.md`** (`PIPELINE: VERT` / `EQUIPE: ROUGE`) — reportée avec trace conformément à la clause de repli de l'exigence elle-même ; **déclencheur de reprise (consigné ici depuis le tri du BACKLOG du 2026-11-05, entrée archivée dans `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`) : un lab mobile Expo/React Native désigné explicitement par Samuel, hors Scroll-Off (exclu du périmètre le 2026-09-15) ou Scroll-Off re-désigné par un arbitrage explicite, avec une session reproductible sans intervention humaine** — tant qu'aucun lab n'est désigné, case décochée et `web-test-team` non construite ; protocole de sortie d'expérimental dans `plugin/mobile-test/README.md` et `plugin/mobile-test-team/README.md` § Limites

### Portabilité multi-runtime — livraison (Phase 38, prolonge le spike Phase 37)
> Espace de noms dérivé au cadrage (38-CONTEXT.md) — `PORT-xx` est PRIS (Phase 30) et exclu.
> 6 lots, ordre de dépendance imposé : FIDE → RUNT → ROLL → TGT → ADPT → MIGR.

- [x] **FIDE-01**: Un gate exécutable (`check-artifact-fidelity.sh`) compare, PAR EXÉCUTION RÉELLE de la conversion `gsd-core` (jamais une table recopiée à la main), un artefact VibeFlow source à sa forme convertie pour une cible mesurée (Codex tier-1) et rend, par champ (`model`/`memory`/`tools`/`disallowedTools`/`vf-internal`/`description`), l'un de trois verdicts : préservé / dégradé / perdu — plus le compte des marqueurs morts (`.claude/`, `Task(`) non réécrits
- [x] **FIDE-02**: L'install (`vibeflow-update.sh install`/`update`) affiche ce périmètre à la fin de la pose — jamais dans un rapport séparé qu'on ne relit pas ; sur Codex le rapport est VIDE (rien perdu, mesuré) ou ASSUMÉ (perte nommée), jamais silencieux
- [x] **FIDE-03**: Le gate déclare, par cible, le TROISIÈME fait de recette — sur Codex, `sandbox_mode`/`approval_policy`/`[permissions]` par rôle sont **acceptés puis inertes** : le confinement de `vf-reviewer`/`vf-auditer`/`vf-design-judge` n'est garanti QUE par la session read-only séparée. Déclaré au `status` ET à l'install, comme `multi_agent_v2` et `trust_level`. Le gate vérifie en outre que la commande de juge posée par 38-05 porte les QUATRE éléments (`-s read-only`, `approval_policy="never"`, `skills.include_instructions=false`, `project_doc_max_bytes=0`) et rend ROUGE s'il en manque un — c'est un ET, jamais un OU

- [x] **RUNT-01**: Les sites CLI-couplés des 4 fichiers `ensure-deps.sh` / `ensure-design-deps.sh` / `check-plugin-update.sh` / `vf-update-run.sh` passent par une détection de runtime + une table de dispatch portant les 4 verbes (`list --json`, `install`, `enable`, `marketplace add`) au lieu d'un appel `claude` figé
- [x] **RUNT-02**: Sur un runtime non détecté ou non supporté (OpenCode, kimi-code — non mesurés au 2026-08-28), le comportement est une dégradation DÉCLARÉE (étapes manuelles affichées, code de sortie propre) — jamais un échec silencieux ni un crash

- [x] **ROLL-01**: `rollback_module` restaure `agents/${mod}.md` et `agents/${mod}-references/` en plus de `skills`/`scripts` (symétrie avec ce que `backup_module` sauvegarde déjà)
- [x] **ROLL-02**: `rollback_module` restaure le fragment de hooks (`hooks/hooks.json`) sauvegardé au backup, via `remove_module_hooks`/`merge_module_hooks` (primitives existantes, jamais réimplémentées) — le trou de `merge-hooks.sh` (cross-matcher, CONCERNS HIGH) reste une dette signalée, pas corrigée par ce lot
- [x] **ROLL-03**: `rollback_module` appelle `mark_installed "$mod" "$version"` avec la VERSION restaurée (capturée au moment du backup) — le registre ne ment plus après un rollback
- [x] **ROLL-04**: Le glob de sélection du backup exclut les répertoires `-removed` de convergence et échoue BRUYAMMENT (jamais un `✓ rollback OK` sur zéro action) quand aucun backup valide n'existe
- [x] **ROLL-05**: `--dry-run` fonctionne sur `rollback` — prévisualisation de ce qui serait restauré, sans écriture (révise D-31-09 sur ce point précis, ne migre PAS `rollback_module` vers le socle manifeste)

- [x] **TGT-01**: `TARGET_ROOT` est résolu depuis un point d'injection (`--target`/variable d'environnement) en plus des deux littéraux `user`/`project`, avec repli rétro-compatible si absent
- [x] **TGT-02**: Les 16 littéraux résiduels (`gitignore_add_paths` ×14, `scripts_prefix_for_scope` ×2) suivent `TARGET_ROOT` au lieu d'un chemin `.claude` figé en dur
- [x] **TGT-03**: Le payload copié (skills/agents/commands/rules/scripts — 198 fichiers / 1130 occurrences `.claude/` mesurés) subit une réécriture des occurrences à la copie, sur le précédent `copyWithPathReplacement`
- [x] **TGT-04**: La sonde cross-module `conductor` → `dev-orchestrator` (cascade de présence de fichier, `vf-update/SKILL.md` `<S-moteur>`) résout toujours après l'évolution du layout — vérifiée par une tâche dédiée, jamais supposée

- [x] **ADPT-01** *(résolu — nœud `probe-codex` levé en session réelle le 2026-08-28)*: Un adaptateur VibeFlow minimal écrit un rôle Codex au format RÉELLEMENT dispatchable mesuré (`.toml` sous `$CODEX_HOME/agents/vibeflow/`, `name`/`description`/`developer_instructions`, tirets conservés), avec digest explicite à 4 catégories (préservé / décoratif / perdu / limite de confinement) — `sandbox_mode`/`approval_policy` sont acceptés et validés par le schéma mais mesurés INERTES au spawn (#7b, session réelle) : jamais présentés comme un substitut réel à `disallowedTools` — **note (audit 2026-09-24)** : le digest RÉELLEMENT posé porte **6 statuts mesurés**, pas les 4 catégories nommées par l'énoncé ; l'intention (préservé/décoratif/perdu/limite de confinement) est tenue AUTREMENT, avec un grain plus fin. Confirmé : `sandbox_mode`/`approval_policy` ne sont JAMAIS écrits dans le TOML posé.
- [x] **ADPT-02**: aucun mapping de nommage des 31 agents n'est construit — l'inconnu #3 est CONFIRMÉ en session réelle (les tirets passent au dispatch, `agent_type` les accepte ; la contrainte `[a-z0-9_]+` frappe uniquement le `task_name` d'invocation, jamais le nom du rôle)
- [x] **ADPT-03**: aucun forçage `fork_turns` n'est construit — l'inconnu #5 est INFIRMÉ en session réelle (mesure en base `state_5.sqlite` : le modèle enfant est enregistré identique en `fork_turns:"none"` et `"all"`) ; « un modèle par worker » tient nativement
- [x] **ADPT-04** *(énoncé CORRIGÉ le 2026-08-29 — la formulation d'origine était mesurée FAUSSE)*: Le gate de l'adaptateur prouve qu'un rôle posé est **réellement chargé** par Codex. ⚠️ L'énoncé initial (« `codex doctor --json` COMPTE les rôles chargés ») ne tient pas : mesuré, `doctor` **n'énumère JAMAIS** les rôles par nom et reste **exit 0** même avec un rôle cassé présent. Le seul signal exposé est un `startup warning` référençant le **chemin d'un rôle malformé**. Le gate vérifie donc l'**ABSENCE** de ce warning pour le fichier posé — discriminant prouvé par mutation (T4b). L'intention est tenue (« jamais *pas de crash donc c'est bon* »), le mécanisme est celui que le binaire expose réellement
- [x] **ADPT-05**: La commande de juge en session séparée porte les DEUX drapeaux d'isolation — `-c skills.include_instructions=false` **ET** `-c project_doc_max_bytes=0` — et le gate de l'adaptateur EXIGE les deux, jamais l'un : le levier skills laisse ouvert le canal `AGENTS.md` du dépôt jugé (mesuré : marqueur toujours présent sans lui). Un seul drapeau donne une porte qu'on croit fermée.
- [x] **ADPT-06**: La fermeture du canal d'injection est prouvée en **RÉPÉTITIONS** (≥ 3 runs sur le banc témoin, marqueur attendu **0/N**), jamais en un run — l'injection mesurée est **non déterministe (2/3)** : un run propre ne prouve rien. Si un seul run sur N ressort le marqueur, la porte n'est PAS fermée. Couvre désormais **les deux canaux** : `skills`/`AGENTS.md` (`0/5`, `3b7de24`) **et** `hooks`/`plugins` (`0/5`, `78648ca`, `38-ADPT06-HOOKS-REPETITIONS.md`) — deux gates vérifiés séparément sur ce second canal (confiance par défaut du projet/des hooks ; les drapeaux `features.hooks=false`/`features.plugins=false`). **Limite déclarée** : ne couvre qu'un dépôt jugé **jamais trusté** et une commande de juge sans `--dangerously-bypass-hook-trust` ; un seul type de hook mesuré (`SessionStart`) ; **pas de plugin réel construit** pour vérifier ce canal directement ; **non reproductible en suite automatisée** (nécessite un appel réseau réel).

- [x] **MIGR-01**: `.planning/config.json` porte le runtime actif ET les runtimes installés, rétro-compatible sur 3 cas (absent / scalaire / objet) — la clé `runtime` racine RESTE une chaîne (contrat `gsd-core` : `runtime-name-policy.cjs` ignore silencieusement tout candidat non-chaîne), la richesse « installés » vit dans une clé sœur dédiée à VibeFlow
- [x] **MIGR-02**: `vf-calibrate` expose la dualité propagation additive / migration soustractive explicitement DANS LA SKILL et DANS SA SORTIE — jamais implicite (D-38-A : extension, pas de verbe utilisateur neuf)
- [x] **MIGR-03**: La bascule (vs coexistence) est gatée dry-run → confirmation → écriture, jamais par défaut (ADR-031, D-38-B)
- [x] **MIGR-04**: Réversibilité prouvée fichier à fichier — install → bascule → retour, arbre comparé par `comm`, jamais par un compte de fichiers
- [x] **MIGR-05**: Un runtime coexistant qui opère sans hooks est déclaré par le gate de fidélité (FIDE) à l'install ET au `status` — pas enfoui dans un rapport qu'on ne relit pas

### Workstreams — partition du planning et collaboration concurrente (Phase 39)
> Dérivé au cadrage le 2026-09-09, discipline de mesure `awk` + `comm` (jamais `grep | sort -u` ni
> `diff` — ADR-069 §Méthode). Préfixe `PART`, pas `WSTR` (D-07) : voisinage lisible avec
> `WKTR`/`WTCH` dans une phase qui fait cohabiter les deux mots ; espace de noms dérivé au
> 2026-09-09 : 40 préfixes gravés, 41 familles réellement occupées en comptant `SIG-01..06` — cette
> famille existe bien dans le dépôt, elle est seulement non recensée dans les deux ledgers de
> traçabilité (celui-ci et ADR.md).

- [x] **PART-01**: Le **niveau 4** de résolution du pointeur de workstream
  (`.planning/active-workstream` consulté quand la session courante n'a jamais posé le sien) est
  **mesuré par exécution sur dépôt jetable**, jamais lu sur un descripteur amont —
  `active-workstream-store.cjs:286-290`, reproduit recherche
  `2026-09-09-phase-39-workstreams-mesures-de-cadrage.md` §2 : héritage confirmé (`SESS-B` sans
  marker → `active: null`, avec marker → `active: default`), isolation d'un pointeur déjà posé
  jamais franchie (même périmé), auto-nettoyage confirmé. *(Critère de succès 1)*
- [x] **PART-02**: La **non-composabilité du pointeur avec ADR-064** est **tranchée par la
  mesure**, jamais laissée implicite (D-10, recherche §3) : **refermée** entre deux sessions Claude
  Code distinctes (deux worktrees, deux process, isolation parfaite — cas A/B) ; **OUVERTE** pour
  le modèle d'équipe VibeFlow — tous les sous-agents d'une session héritent du même
  `CLAUDE_CODE_SESSION_ID` (`CLAUDE_CODE_CHILD_SESSION=1`), un manager qui dispatche des workers
  sur des worktrees différents leur fait partager un seul pointeur, dernier `set` gagnant.
  Déclarée comme **limite datée du 2026-09-09** dans l'amendement d'ADR-069, jamais comme un fait
  résolu. *(Critère de succès 2)*
- [x] **PART-03**: Au moins un dépôt — un **clone jetable de `vibeflow-os`**, histoire réelle, hors
  de l'arbre de travail (D-01) — est réellement partitionné et **TOUS** les agents `vf-*`
  dispatchés dans le run de preuve passent `--ws` **explicitement, sans exception** (D-08,
  insatisfaisable à vide). Les gates (`check-workstream-pointer.sh`, `check-state-integrity.sh`,
  `check-divergence.sh`) restent **verts** dans l'arbre non partitionné (non-régression, mesurée
  sur le dépôt vivant) **et** le deviennent dans le clone partitionné. Preuve par exécution, jamais
  par inspection de frontmatter. *(Critère de succès 3)*
- [x] **PART-04**: Le **filet de détection de divergence** existe et est **bruyant** — signature
  **S2 + S4 + S5** (numéro de phase dupliqué / cardinalité dossiers↔ROADMAP↔STATE incohérente /
  fuite de niveau au ROADMAP racine), branché **post-merge** (jamais `SessionStart`, D-12),
  **opt-in** (`git config core.hooksPath scripts/hooks`, jamais armé par défaut — précédent #38)
  **ET câblé sur le job CI `gates`** (arbitrage Samuel, 2026-09-10 — le hook local seul serait muet
  par construction sur les PR fusionnées côté GitHub, le chemin de merge dominant de ce dépôt ;
  ADR-059, « sûr mais inerte », précédent Phase 35 non répété). **Mutation rouge prouvée** (D-13)
  sur les trois variantes de split-brain de la recherche §8 (orphan, rootonly, roadmap) : le gate
  détecte les deux variantes silencieuses (`git merge-tree`/`git merge` exit 0, Git ne signalant
  rien) et reste muet sur le cas nominal non divergé ; discriminance du script lui-même prouvée par
  mutation, **à la fois localement et en CI**. *(Critère de succès 4)*
- [x] **PART-05**: Le comportement de `/gsd-pr-branch` sur un dépôt partitionné est traité **sur la
  mesure du 2026-09-09**, pas sur le libellé du 2026-08-04 (D-09, recherche §7) — le risque (b)
  d'ADR-069 a **MIGRÉ** : le silence est levé au niveau **chemin** (bloc `$OTHER`,
  `pr-branch.md:410`) mais **subsiste au niveau COMMIT** (`.planning/workstreams/<nom>/ROADMAP.md`
  ne matche pas `STRUCTURAL_RE`, ancré `^\.planning/ROADMAP\.md$`, `pr-branch.md:255`) — un commit
  qui ne touche QUE la feuille de route d'un workstream est **EXCLU dans les deux modes**
  (`pr_strict` vrai ou faux), invisible dans tout rapport. Les trois conséquences (i FAUSSE À
  MOITIÉ / ii VRAIE / iii VRAIE) sont gravées avec leur verdict. Choix explicite tranché et écrit,
  **jamais implicite** : **coût assumé, daté** (amendement d'ADR-069) — pas de correctif local de
  `pr-branch.md` (Iron Law 2 révisée interdit toujours le fork d'une capacité du moteur),
  mitigation = geste de vérification explicite existant (`workstreams.md` §4(b)) étendu pour nommer
  le niveau commit. *(Critère de succès 5)*
- [x] **PART-06**: La **couverture amont** est **re-mesurée à la date du cadrage** (K2 = 9/89 =
  10,1 %, 39 aveugles — contre 7/91 = 7,7 %, 42 aveugles au 2026-08-04 ; corpus, critère et
  commande re-dérivés en ré-exécutant le script d'ADR-069 §Méthode, jamais recopiés) et la
  remontée `GSDA-19` est **rédigée** (D-04, angle bug de comportement) et **prête à poster**, avec
  trace explicite qu'elle n'est **PAS postée** (geste humain réservé, ADR-031) — jamais un abandon
  silencieux. *(Critère de succès 6)*
- [x] **PART-07**: La preuve de partition ne s'exécute **JAMAIS** sur l'arbre de travail de
  `vibeflow-os` pendant la Phase 39 — uniquement sur un **clone jetable**, hors de l'arbre, portant
  l'histoire réelle du dépôt, détruit en fin de mission (D-01). Tout SUMMARY issu de cette preuve
  porte explicitement la nuance : preuve de **mécanisme**, jamais d'usage concurrent réel sur le
  dépôt vivant (D-03). La condition dure d'ADR-069 (« aucune partition tant qu'une phase est en
  vol ») n'est ni révisée ni contournée.
- [x] **PART-08**: La **partition réelle de `vibeflow-os`** est inscrite comme un **geste séparé,
  gaté humain, postérieur à la clôture de la Phase 39**, jamais exécutée par cette phase — avec un
  **déclencheur de reprise daté** porté au ROADMAP et au STATE (D-02), au même patron que les
  déclencheurs déjà en vigueur dans ce dépôt (`WKTR-03`, le déclencheur objectif d'ADR-069 :
  objectif, sans échéance calendaire).
- [x] **PART-09**: VF passe **`--ws` explicitement** sur ses propres appels `gsd_run` (agents
  `vf-*`, sections déjà déclarées de `vf-coder.md:43-51` et `vf-dev-manager.md:31-34`, **plus le
  gabarit de dispatch de `vf-dev-manager.md` amendé par la Tâche 4 de ce même plan pour exiger un
  `GSD_SESSION_KEY` distinct par mandat concurrent — correction 2026-09-10, C4**), **observé par
  exécution** dans le run de preuve (PART-03), avec **au moins deux workers concurrents sans
  `GSD_WORKSTREAM` exporté dans l'environnement partagé** (39-03-PLAN.md Tâche 1, corrigé le même
  jour — sinon la preuve confond « le flag fonctionne » et « l'export fonctionne ») — aucun
  workflow amont n'est réécrit (D-05). Une **veille datée sur un ÉVÉNEMENT** (prochaine publication
  `gsd-core`, qui distribuera `#4455`/`#4456`/`#4225`, fermés le 7-8 septembre 2026 mais non
  distribués en 1.13.0) remplace toute veille à seuil chiffré (D-06) — inscrite en note de
  STATE.md, jamais comme un seuil figé.

### vibeflow-head — head of minds du dev-orchestrator (Phase 40)
> Dérivé au cadrage le 2026-09-15 (`40-CONTEXT.md`, D-01..D-18, seize arbitrages Samuel —
> AskUserQuestion session principale). Préfixe `HEAD` vérifié libre par grep exhaustif sur ce
> ledger (0 occurrence avant cette entrée, re-confirmé par `40-RESEARCH.md`).

- [x] **HEAD-01**: L'échelle d'allocation (quick / debug / execute / manager, sens unique,
  `SEUIL_EQUIPE` inchangé) vit dans `head-governance.md`, renvoyée — jamais dupliquée — par
  `AGENT.md`, `intent-routing.md` et `skills/vf-auto/SKILL.md` (D-01, D-02, D-04, D-09).
  **Preuve** : `AGENT.md` (5 renvois à `head-governance.md`, lignes 53/72/148/150/157/209),
  `skills/vf-auto/SKILL.md` (1 renvoi, ligne 28) et `intent-routing.md` (1 renvoi, ligne 15,
  ajouté dans l'encadré de tête — table de routage inchangée) renvoient tous les trois. Fermée
  par correction ciblée hors lot du DAG de mission (2026-09-15) : la table de routage elle-même
  n'a pas bougé (T3 de `test-dev-orchestrator.sh` reste à son plancher).
- [x] **HEAD-02**: `check-mission-exit.sh` existe avec ses codes de sortie (3 sain / 0 manque(s)
  nommé(s) / 4 indéterminé / 64 outillage illisible), ses contrôles E1-E6 (D-07), sa suite de
  tests et sa **mutation rouge prouvée** (QUAL-01) ; le head ne rejoue qu'un gate dont la preuve
  manque au rapport, jamais un étage entier, jamais la revue (D-03, D-05, D-06, D-08, D-10 à D-12,
  D-14). **Preuve** : `plugin/dev-orchestrator/scripts/check-mission-exit.sh` (459 lignes, codes
  `exit 3`/`exit 0`/`exit 4`/`exit 64` présents, marqueurs `# E1` à `# E6` aux lignes
  155/196/213/260/321/338) ; `scripts/tests/test-check-mission-exit.sh` rejouée le 2026-09-15 :
  **23/23 cas, 0 KO**, dont les cas 19a/19b (garde D-11, mutation détectée sur copie mutée,
  original non détecté) et 21/22 (discrimination des deux causes d'E1) ; module
  `dev-orchestrator` bumpé **v2.22.0**.
- [x] **HEAD-03**: Le rapport de mission porte le bloc de preuves E6 `{commande, exit_code, sha}`
  par verdict et un décompte de coût à trois lignes (minds dispatchés, tours consommés, gates
  rejoués), relayés — jamais recalculés — dans `mission-contracts.md` §Rapport de mission et
  `agents/vf-dev-manager.md` (D-05, D-13, D-15). Le manager ne fait que RELAYER : les preuves sont
  ÉMISES par les trois workers qui rendent un verdict (`agents/vf-coder.md` verdict `recette`,
  `agents/vf-reviewer.md` verdict `revue`, `agents/vf-auditer.md` verdict `audit`), câblés par le
  lot `40-05` (amendement D-19, 2026-09-15, option b). **Preuve** :
  `mission-contracts.md:300` porte `## Contrat de preuves E6 (verdict → head)` ;
  `vf-coder.md`/`vf-reviewer.md`/`vf-auditer.md` émettent le champ `preuves` (8 occurrences
  combinées de `exit_code`/`preuves`, vérifié `grep -c`) ; `vf-dev-manager.md:244-246` relaie
  (« jamais recalculés ni agrégés en statistique de ton cru ») en restant à **250/250 lignes**
  (ADR-029, compensation stricte).
- [x] **HEAD-04**: Aucun alias `vibeflow-dev` ne survit dans `plugin/` hors CHANGELOG — vérifié par
  un test du module qui **peut rendre rouge** (mutation prouvée) ; le skill `vf-dev` conserve son
  nom et incarne `vibeflow-head` (D-17), zéro agent neuf, kernel intact (D-04, D-16, D-18).
  **Preuve** : `grep -rl vibeflow-dev plugin/` (hors CHANGELOG) → 0 fichier (2026-09-15) ; garde
  **T36** dans `test-dev-orchestrator.sh` (motif assemblé à l'exécution, jamais écrit en clair —
  sinon le gate se balaierait lui-même) avec fixture de mutation discriminante (T36(c) : détecte
  l'alias dans un fichier ordinaire, l'exempte dans un `CHANGELOG.md`, les deux dans la même
  fixture) ; diff nul vérifié sur `team-kernel.md`, `driver-lock.sh`, `dag.sh`,
  `guard-driver-lock.sh`.

### Gates de planning workstream-aware (Phase 41.1 — INSERTED 2026-09-23)
- [x] **WSAW-01**: Un mécanisme **partagé** d'énumération des compartiments, dérivé du patron de `check-divergence.sh`, rend un chemin explicite par compartiment **présent sur le disque** ; il refuse de suivre un lien symbolique, ne consulte jamais `GSD_WORKSTREAM`/`VF_WORKSTREAM`/`.planning/active-workstream`, et ne rend pas vert sur zéro compartiment découvert dans un dépôt partitionné (trou d'`exit 0` de `check-divergence.sh` fermé, double boucle inline dédupliquée). — **livré 2026-09-23/24, Phase 41.1 (PR #100) ; preuve : ligne de traçabilité**
- [x] **WSAW-02**: Les consommateurs recensés en catégorie (b) « câblé en dur » — `ci.yml:353` et le verdict R5 `ci.yml:844` — et en catégorie (c) « suppose la racine » — `check-planning-state.sh`, `detect-gsd-engine.sh`, `discover-unintegrated-docs.sh` — passent par le mécanisme ou déclarent pourquoi ils n'en relèvent pas ; le recensement est versionné et rejoué par la CI. — **livré 2026-09-23/24, Phase 41.1 (PR #100) ; preuve : ligne de traçabilité**
- [x] **WSAW-03**: La CI rend **rouge** sur une fixture jetable à **trois** compartiments dont un cassé, et **vert** sur la même fixture sans le compartiment cassé — bascule exécutée dans l'étape CI elle-même, pas seulement dans la suite du module. — **livré 2026-09-23/24, Phase 41.1 (PR #100) ; preuve : ligne de traçabilité**
- [x] **WSAW-04**: Ajouter un compartiment suffit à le faire inspecter **sans modifier aucun câblage** — prouvé par mutation (ajout d'un troisième compartiment cassé) ; un mécanisme qui cesserait d'énumérer rend **rouge**, jamais vert à vide. — **livré 2026-09-23/24, Phase 41.1 (PR #100) ; preuve : ligne de traçabilité**
- [x] **WSAW-05**: Un gate de planning distingue **trois** états — conforme / **non initialisé** (compartiment créé, jamais travaillé : verdict propre et visible, jamais un échec) / corrompu. `gouvernance/STATE.md` (sortie nominale de `workstream create`, rc=2 mesuré le 2026-09-23) relève de « non initialisé » : généraliser le balayage ne transforme pas « muet » en « rouge ». Classement justifié gate par gate contre ADR-074, jamais par une exception nominative sur un compartiment. **Porte la définition unique de « compartiment conforme »**, consommée par WSCH-02 — une seconde définition est une condition d'arrêt. — **livré 2026-09-23/24, Phase 41.1 (PR #100) ; preuve : ligne de traçabilité**
- [x] **WSAW-06**: `workstreams.md` et ADR-069 **posent** la frontière gate / workflow — formulée par le **rôle** (`GSD_WORKSTREAM` et le pointeur = canal nominal de ce qui travaille ; un gate ne dérive jamais sa cible d'une valeur qu'un `export` peut changer, parce qu'il juge celui qui pourrait l'exporter), écrite comme **précision** d'ADR-069 (forme d'ADR-074 précisant ADR-031), datée, origine nommée (angle mort de la partition D-02, 2026-09-23), et constat explicite que **l'ancrage ADR-063 initial était erroné**. Décision de la session principale (`vibeflow-head`), 2026-09-23 — pas un arbitrage de Samuel. — **livré 2026-09-23/24, Phase 41.1 (PR #100) ; preuve : ligne de traçabilité**
- [x] **WSAW-07**: `workstreams.md` énonce le **choix au démarrage**, sa valeur (deux flux disjoints en parallèle), le **non-choix par défaut** pour un lab solo, et la **procédure de bascule** avec sa précondition vérifiable (aujourd'hui absentes : §1 ne dit que « `create <nom> --migrate-name <nom>` ») ; l'affirmation de §3 « l'état nominal de tous nos labs à ce jour » — **fausse depuis la PR #94** — est corrigée. **Seul écrivain** de `workstreams.md` et `docs/ADR.md` pour les deux phases. — **livré 2026-09-23/24, Phase 41.1 (PR #100) ; preuve : ligne de traçabilité**

### Choix de la partition au démarrage (Phase 41.2 — INSERTED 2026-09-23)
- [x] **WSCH-01**: L'initialisation d'un lab pose **une** question en langage d'usage (« plusieurs personnes ou agents vont-ils travailler en parallèle sur des sujets séparés ? ») ; **zéro occurrence du mot « workstream »** dans ce qui est montré à l'utilisateur ; question sautée, session non interactive ou réponse négative ⇒ **planning unique**. — **livré 2026-10-02, Phase 41.2 (PR #130) — RÉSERVE : contrat écrit prouvé (`test-vf-split-planning.sh`), comportement de l'agent en session interactive non exercé (`41.2-VERIFICATION.md`, human_needed) ; recette réelle au BACKLOG (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08)**
- [x] **WSCH-02**: Répondre oui crée les compartiments **par le moteur** (`workstream create`, aucune réimplémentation VibeFlow), puis VibeFlow les rend conformes : un compartiment créé par VibeFlow **naît avec un frontmatter complet**, sans réparation manuelle. « Conforme » = la définition unique de WSAW-05, **consommée et jamais redéfinie**. — **livré 2026-10-02, Phase 41.2 (PR #130) ; preuve : `41.2-VERIFICATION.md`**
- [x] **WSCH-03**: Un skill de bascule porte le geste pour un lab déjà démarré et **refuse** quand une phase est en vol — précondition d'ADR-069 lue sur un **champ du disque** nommé dans le plan, jamais rappelée en prose ; refus **prouvé par mutation**. — **livré 2026-10-02, Phase 41.2 (PR #130) ; preuve : `41.2-VERIFICATION.md`**
- [x] **WSCH-04**: **Preuve d'usage (critère d'échec de la phase)** — un lab neuf initialisé en mode partitionné, sur fixture jetable en CI, voit les gates de planning passer au **vert sur chaque compartiment** sans aucune réparation manuelle. — **livré 2026-10-02, Phase 41.2 (PR #130) ; preuve : `41.2-VERIFICATION.md`**
- [x] **WSCH-05**: Le contenu doctrinal du choix (valeur, non-choix par défaut, procédure de bascule et précondition) est **remis au manager**, qui le fait porter par WSAW-07. Cette phase **n'écrit ni `workstreams.md` ni `docs/ADR.md`** — deux écrivains sur un fichier de doctrine est le conflit que la parallélisation doit éviter. — **livré 2026-10-02, Phase 41.2 (PR #130) ; preuve : `41.2-VERIFICATION.md`**

### Sobriété de méthode (Phase 41.3 — INSERTED 2026-09-29)
- [x] **SOBR-01**: Ce dépôt n'a plus de worktree, de branche locale ou distante déjà mergés, ni de stash sans propriétaire ; un outil les liste (extension de `check-method-budget.sh`), la suppression distante reste validée par un humain.
- [x] **SOBR-02**: Chaque `STATE.md` de ce dépôt est ≤ 8 Ko ; l'historique part sous `.planning/archives/state/`, rien n'est perdu, `check-state-integrity` reste vert.
- [x] **SOBR-03**: `check-blueprints` ne balaie plus `.claude/worktrees/` ; les hooks `$CLAUDE_PROJECT_DIR/.claude/*` fonctionnent dans un worktree (entrée BACKLOG du 2026-09-28).
- [x] **SOBR-04**: La procédure de release de `CLAUDE.md` exige une relecture adverse du diff fonctionnel avant le tag, avec au moins une sonde exécutée.
- [x] **SOBR-05**: Un ajout, un retrait — un nouveau gate, ADR, règle ou mémoire désigne ce qu'il remplace ou justifie qu'il n'en remplace aucun ; l'absence est visible par machine.
- [x] **SOBR-06**: Budgets étendus — plafonds mesurés sur le BACKLOG ouvert, l'index de mémoire et le ROADMAP, en plus de STATE et des worktrees ; au-delà, l'outil archive seul (déplacement tracé et réversible), écrit comme précision d'ADR-031.
- [x] **SOBR-07**: Nettoyage en fin de geste — la clôture d'une mission de manager **et** la fin d'un travail direct rangent worktrees, branches, stash et mémoires non versionnées ; gaté, pas facultatif.
- [x] **SOBR-08**: Prose plafonnée — une note de STATE ou une entrée de BACKLOG a une taille maximale ; un sujet clos quitte le fichier courant pour une archive.

### Emprunts Pocock (Phase 41.4 — INSERTED 2026-10-06)
- [x] **POCK-01**: Frontière de questions — un cadrage (head, panel du manager) ne pose que les questions dont les prérequis sont réglés, une recommandation par question, jamais un fait qu'un sous-agent peut établir ; rendu AskUserQuestion groupé par zone.
- [x] **POCK-02**: Glossaire de domaine du lab — `docs/_transverse/` porte un glossaire que le cadrage alimente (termes flous challengés, mots surchargés résolus) et que les briques lisent ; régime fixé dans `docs-flow.md`.
- [x] **POCK-03**: Frontière de phase — à la sortie d'un geste ou d'une mission, le head applique l'arbre continuer → clear → handoff → sous-agent → compact (en dernier, avec instruction), et note ce qui dans l'environnement aurait rendu la mission suivante moins chère.
- [x] **POCK-04**: Revue à deux axes — `vf-reviewer` rend Standards (conventions, smells, sécurité) et Spec (fidélité au plan de l'étape : manquant, non demandé, implémenté faux) en dispatches séparés, jamais re-rankés en un verdict unique.
- [x] **POCK-05**: Grille de rétro — la promotion d'un LEARNING trie mécanique → check déterministe, jugement → standard ; un dépôt sans garde-fou et une instruction sans effet sont des findings.
- [x] **POCK-06**: Merge-danger call — une PR ouverte par la chaîne de ship déclare porte à sens unique ou double sens et rayon d'explosion.
- [x] **POCK-07**: Skills classés — chaque skill VibeFlow est user-invoked (`disable-model-invocation: true` + équivalent Codex) ou model-invoked ; un gate rougit sur un skill non classé ; un user-invoked n'invoque jamais un autre user-invoked.
- [x] **POCK-08**: Défaillance observée — tout ajout de skill, gate ou règle cite la session ou le geste qui a mal tourné, sinon signalé ; `check-ajout-retrait` l'exige en plus de SOBR-05. *(Reformulé le 2026-10-06, P414-D-19, arbitrage Samuel, AskUserQuestion session principale, 2026-10-06.)*

### Transverse
- [x] **QUAL-01**: Tout nouveau gate du milestone naît avec ses trois issues (PASS / FAIL / imparsable BRUYANT) et sa mutation rouge prouvée — mesuré satisfait sur la Phase 41 le 2026-09-18 (vingt mutants tués sur les trois gardes plus neuf sur les deux outils de phase, total vingt-neuf, rc=0 sur les cinq suites), **puis RÉGRESSÉ** (partition du planning, PR #94, 2026-09-23, résolution de racine cassée), **réparé le 2026-09-24** (résolution par `git rev-parse --show-toplevel`), mesure alors incomplète à **28/29** (`check-trace-arbitrage.sh` refusait PAR CONCEPTION les citations multiples distinctes et conformes). **RE-SATISFAIT le 2026-09-24** : trois défauts de conception corrigés dans `check-trace-arbitrage.sh` (citations multiples distinctes conformes acceptées, merges réels de PR et commits de release exclus du jugement, mot déclencheur insensible à la casse — arbitrage Samuel, AskUserQuestion session principale, 2026-09-24), neuf cas de test et neuf mutants ajoutés (dont MUT-2 repurposé), `BASE-TRACE-ARBITRAGE` avancée de `f1d6589` à `0b4d9a7` (7 commits antérieurs acceptés en l'état, identifiant de migration sans rapport confondu avec le registre de décisions de la phase — hors des trois défauts corrigés). **Mesuré ce jour, rc=0 sur les cinq suites : `test-check-trace-arbitrage.sh` 9 mutants tués (MUT-1 à MUT-9), `test-check-aucune-fermeture.sh` 3 mutants tués (inchangé), plus les vingt mutants inchangés des trois gardes CI (`check-baseline-arbitrage.sh` 9, `check-gate-touche.sh` 6, `check-push-sans-pr.sh` 5) — total 32 mutants tués sur cinq suites, toutes vertes.**

### Out of Scope (audité le 2026-08-15 — chaque exclusion a son alternative dans le périmètre)
- **Auto-steal du lock au TTL** — lock périmé ≠ mission morte (constaté 2026-08-02) → LOCK-01 + LOCK-04. *Réévaluable post-LOCK-01 : auto-takeover sur battement mort (pas sur TTL).*
- **Notification à chaque tour / auto-kill sur stall** — spam couvert par `stop-notify`, auto-kill viole ADR-031 → WTCH-02/03
- **Dry-run en chemin de code séparé** — dérive plan/pose garantie → contrainte encodée dans MANI-02
- **Suppression silencieuse de fichiers modifiés** — perte de travail → MANI-03 backup + signalement
- **Hash conffile-style par fichier** — raffinement sans besoin prouvé, le backup couvre → différé
- **Armement via settings local** — régression #38 rejouée → gate règle 4 (WTCH-04, LOCK-02)
- **Ré-armement worktree sur issue-close** — close ≠ releasé ≠ installé → WKTR-01. **Renforcé le 2026-08-26** : même précondition externe tombée (releasé ET installé), le ré-armement reste refusé — sûr mais inerte en conditions de mission (ADR-059), seul levier effectif (`baseRef: "head"`) disqualifié car il éteint le contrôle plutôt que de le satisfaire
- **Marketplace de skills maison / mirroring tiers** — duplique `/plugin` natif → input du cadrage SKIL-01
- **Import des 230 personas agency-agents** — ADR-029 incompatible, zéro gouvernance → AGTS-01
- **Migration des hooks.json avant merge-hooks.sh** — parc cassé sans erreur (§1.3) → ordre PORT-02
- **Blocage CI dur immédiat du budget** — accoutumance au rouge → BUDG-02 ratchet
- **BUDG-03 étage d'alignement court (G2)** — différé : mécanique de workflow neuve, utilité non démontrée, aucun incident lié

## Milestone ecc-inspiration-v1.0 — « ce qu'on emprunte à ECC » (inscrit 2026-09-25)

> Phases 51-56, compartiment `fiabilite`, exécution après la clôture de `fiabilite-v1.0` (arbitrage Samuel, AskUserQuestion session principale, 2026-09-25).
> Étude source : `.planning/research/2026-09-25-ecc-inspiration-etude.md`. **Aucune exigence posée à l'inscription** : chaque phase reçoit sa
> famille à son cadrage (`gsd-discuss-phase`), comme les Phases 43-50 du jalon de Willy. Préfixes
> **réservés et vérifiés libres** le 2026-09-25 (`grep -rhoE '\b[A-Z]{4}-[0-9]{2}\b' .planning plugin docs`,
> 0 occurrence pour chacun) : `SNAP` (51, snapshot PreCompact), `TELE` (52, télémétrie d'usage et
> coût), `OBSV` (53, apprentissage par observation), `HARN` (54, audit du harness), `MRUN` (55,
> installeur et mémoire multi-runtime), `LANG` (56, packs de règles par langage). `QUAL-01`
> transverse s'applique de plein droit à tout gate ou hook livré.


## Milestone equipe-produit-v1.0 — « l'équipe produit » (inscrit 2026-10-08)

> Phases 57-62, compartiment `fiabilite`, prochain jalon exécuté (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08). Spec source :
> `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md` ; germe `SEED-001`. **Aucune exigence posée à
> l'inscription** : chaque phase reçoit sa famille à son cadrage (`gsd-discuss-phase`). Préfixes **réservés et vérifiés
> libres** le 2026-10-08 (`grep -rhoE '\bXXXX-[0-9]+' .planning docs plugin`, 0 occurrence chacun) : `DLWS` (57, verrou
> par compartiment), `RLPO` (58, rôles de poste), `PRDT` (59, bundle produit), `ARCG` (60, gate architecture), `COLB`
> (61, collaboration à deux humains), `PLTF` (62, décision plateforme). `ROLE` était déjà pris. `QUAL-01` transverse
> s'applique de plein droit.

### Verrou de driver par compartiment (Phase 57 — posées au cadrage, 2026-10-10)
- [x] **DLWS-01**: Verrou par compartiment — dans un lab partitionné, `driver-lock.sh acquire --ws=<sujet>` pose un verrou propre à ce compartiment ; deux managers sur deux compartiments distincts l'acquièrent tous deux, deux sur le même compartiment se refusent (P57-D-01, P57-D-06).
- [x] **DLWS-02**: Verrou de dépôt — release, écriture de `BACKLOG.md`/`docs/ADR.md`, fichiers racine de `.planning/` et partition/bascule prennent un verrou de dépôt court, distinct des verrous de compartiment ; deux gestes de dépôt ne se tiennent jamais en même temps (P57-D-01, P57-D-02).
- [x] **DLWS-03**: Lab plat inchangé au bit près — même chemin `.planning/DRIVER.lock`, même JSON, même comportement du guard ; les suites existantes de `driver-lock.sh` et `guard-driver-lock.sh` passent sans modification (P57-D-03).
- [x] **DLWS-04**: Résolution explicite — le compartiment vient d'un `--ws` explicite, jamais de `VF_WORKSTREAM`, `GSD_WORKSTREAM` ni du pointeur `active-workstream` ; sans `--ws` dans un lab partitionné, `acquire` prend le verrou de dépôt et le JSON le dit (`scope: depot`, raison) (P57-D-04, P57-D-05).
- [x] **DLWS-05**: Emplacement au niveau du clone — les verrous d'un lab partitionné vivent sous `git rev-parse --git-common-dir`, partagés par les worktrees d'un même clone ; hors git, repli relatif au checkout déclaré dans le JSON ; le guard résout au même endroit que `driver-lock.sh` (P57-D-07, P57-D-08).
- [x] **DLWS-06**: Guard par compartiment — Write/Edit sous `.planning/` et commits ne sont refusés que sur ce qui est tenu par autrui (commits jugés sur `git diff --cached --name-only`, index illisible = refus) ; `checkout`/`switch` restent toujours refusés sous un verrou d'autrui, exemptions D-32-06 inchangées (P57-D-09, P57-D-10, P57-D-11).
- [x] **DLWS-07**: Doctrine et consommateurs — ADR-053 reçoit un amendement daté (« un manager par compartiment, un seul geste de dépôt à la fois ») ; le head passe `--ws` et un `GSD_SESSION_KEY` distinct par manager ; les consommateurs recensés du verrou (`status`, E1 de `check-mission-exit.sh`, watchdog, `check-branch-claim.sh`, `check-guard-health.sh`, `dag.sh`, managers, `mission-flow.md`) sont alignés, chacun vérifié (P57-D-13, P57-D-15).
- [x] **DLWS-08**: Preuve de mécanisme — acquisitions concurrentes sur clone jetable (deux compartiments, partage entre worktrees, repli `scope: depot`, refus du guard selon l'index) mesurées ; QUAL-01 : chaque comportement neuf des deux scripts naît avec ses trois issues et sa mutation rouge prouvée ; l'usage concurrent réel reste à la Phase 61 (P57-D-12).

### Rôles de poste (Phase 58 — posées à la planification, 2026-10-16)
> Reformulent P58-D-01..20 (P58-D-01..14 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-16 ; P58-D-15..20 : conséquences laissées au planificateur) sans rien y ajouter. « Poste » = le rôle de l'humain sur ce projet ; un poste est une vue, pas un droit.
- [x] **RLPO-01**: Fichier de poste local — `.claude/vibeflow-role`, une seule ligne ; l'engine pose sa règle d'ignorance dans tous les scopes, par un bloc séparé de `gitignore_add_paths()`, et l'ajoute à `.worktreeinclude` (P58-D-01, P58-D-13, P58-D-16).
- [x] **RLPO-02**: Lecteur unique — un script installé sous `conductor/scripts/` rend exactement une valeur `solo|product|dev` (`VF_ROLE` puis fichier, absent = `solo`, invalide ou illisible = erreur bruyante), interface lue par les Phases 59 à 61 (P58-D-15).
- [x] **RLPO-03**: Liste de projet — clé `vf_roles` dans le `.planning/config.json` racine, jamais lue par gsd-core ; absente, un lab reste identique à l'octet près (P58-D-02).
- [x] **RLPO-04**: Clé `roles` de `module.json` — `solo` sur-ensemble implicite, valeurs admises `product` et `dev`, `roles: []` et valeur inconnue refusés bruyamment par un validateur neuf ; `roles: ["dev"]` posé sur dev-orchestrator, mobile-test et mobile-test-team seulement (P58-D-03, P58-D-06).
- [x] **RLPO-05**: Catalogue filtré — `build-module-catalog.sh --role` ou `VF_ROLE` (le drapeau l'emporte), sortie à 3 colonnes inchangée et identique à l'octet sans poste, 14 cas existants verts, fermeture des modules `product` sans module `["dev"]` (P58-D-17).
- [x] **RLPO-06**: Installeur — question du poste entre scope et type de lab, pré-cochée `solo`, seulement en scope `project` ou `local` (scope `user` = `solo` sans question), `VF_ROLE` non interactif, filtre à la pose seulement, `install --all` filtre si `VF_ROLE` explicite, `update --all` inchangé, poste jamais dans `.vibeflow-installed` ; phrase périmée sur `proposable:false` corrigée, presets proposés filtrés par le poste (`resolve-preset.sh list --role`, fermeture de dépendances ; `product` ne voit plus un preset qui contient un module de dev) (P58-D-04, P58-D-05, P58-D-08, P58-D-18, P58-D-21).
- [x] **RLPO-07**: Changement de poste — réécriture du fichier puis avis listant les modules installés hors du nouveau poste, aucune désinstallation (P58-D-07).
- [x] **RLPO-08**: Gate `check-role-consistency.sh` — forme exec, consultatif, issues 0 (poste dans la liste) / 1 (hors liste ou invalide) / 3 (silence) et erreur d'analyse bruyante sur un code distinct de 2 ; hook SessionStart de conductor et refus à la pose ; QUAL-01 : une mutation rouge prouvée par issue (P58-D-09).
- [x] **RLPO-09**: Contexte de session — le stdout du même hook SessionStart injecte une ligne « Poste : X » hors `solo`, rien en `solo`, aucun hook neuf (P58-D-10).
- [x] **RLPO-10**: Doctrine et vocabulaire — ADR-077 (« agentique first, ouvert à la collaboration humaine » ; « un poste est une vue, pas un droit ») écrit sous verrou `--depot` court ; colonne « statut » en doc seulement, sortie machine inchangée ; entrée de glossaire poste / rôle d'agent / statut (P58-D-11, P58-D-12).
- [x] **RLPO-11**: Preuves du jalon — critère 1 sur lab neuf (`VF_ROLE=product`, HOME temporaire), critère 2 par comparaison sortie et arbre posé à une install de référence, critère 5 (`check-agents.sh --strict`, aucun agent > 250 lignes), critère 6 (aucun nom de client) (P58-D-19). Définition précisée le 2026-10-20 (Q19, arbitrage Samuel, AskUserQuestion session principale, 2026-10-20) : « commande dev » = skills et agents des 3 modules `roles:["dev"]` + gsd-* ; superpowers reste posé en product par la chaîne design.
- [x] **RLPO-12**: Livraison — branche `feat/phase-58-roles-de-poste` empilée sur `docs/cloture-phase-57`, `plugin/planning-core/module.json` et `gitignore_add_paths()` non touchés, bumps de modules (conductor, dev-orchestrator, mobile-test, mobile-test-team, installer s'il porte une VERSION) avec CHANGELOG et README, sans release (P58-D-13, P58-D-14, P58-D-20).

### Bundle produit (Phase 59 — posées à la planification, 2026-10-27)
> Reformulent P59-D-01..23 (P59-D-01..12 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-27 ; P59-D-13 : fait établi ; P59-D-23 : précision de Samuel, session principale, 2026-10-27 ; P59-D-14..22 : conséquences laissées au planificateur) sans rien y ajouter. Un poste est une vue, pas un droit.

- [x] **PRDT-01**: Composition et noms — module `product-team-bundle` : front door `vibeflow-product` (`AGENT.md` à la racine, incarnée par `/vf-product` en session principale, jamais en Task), manager `vf-product-manager` non interne (allowlist `Agent(vf-product-analyst, vf-product-pm, prd-gate)` + `SendMessage`), workers internes `vf-product-analyst` (BRIEF) et `vf-product-pm` (PRD), juge interne `prd-gate` ; aucun nom ne contient « BMAD » ; `vf-product-architect` reste hors bundle (P59-D-01, P59-D-02, P59-D-13).
- [x] **PRDT-02**: Gabarit `product` — fichiers PROJECT et REQUIREMENTS produit neufs dans `planning-core`, dimension « poste » orthogonale à la rigueur (pas un 4ᵉ niveau), chaque exigence porte un critère d'acceptation et une priorité, forme de ligne `- [ ] **ID**: …` lisible par GSD ; choix du gabarit décidé par le planificateur, gabarits existants identiques à l'octet aux postes `solo` et `dev` ; la Phase 59 n'ajoute que des fichiers neufs dans `planning-core`, plus bump et changelog (P59-D-03, P59-D-16).
- [x] **PRDT-03**: BRIEF — `.planning/BRIEF.md` à côté de `PROJECT.md`, niveau produit y compris en lab partitionné, cinq rubriques (problème, utilisateurs, valeur, contraintes, hors périmètre), court et lisible sans être dev ; seul fichier nouveau du rôle, pas de `PRD.md` séparé (P59-D-04).
- [x] **PRDT-04**: Juge `prd-gate` — lecture seule, rubric /100 répartie par le planificateur, passe à 80/100 **et** aucun éliminatoire (exigence sans critère d'acceptation ; BRIEF auquel manque une des cinq rubriques), verdict JSON `score`/`eliminatoire`/`detail{}` + bloc typé du team-kernel, frontmatter des juges (Read, Glob, Grep, Bash ; `disallowedTools: Write, Edit` ; `omitClaudeMd: true` ; `vf-internal: true` avec marqueur « Worker interne ») (P59-D-05, P59-D-14).
- [x] **PRDT-05**: Script `check-prd.sh` — sous `plugin/product-team-bundle/scripts/`, lit `.planning/REQUIREMENTS.md` et `.planning/BRIEF.md`, appelé par le juge, rougit sur l'éliminatoire « exigence sans critère d'acceptation » (et sur la rubrique manquante si mesurable mécaniquement), bash portable, codes de sortie vert / rouge / indéterminé-illisible documentés, forme exec ; QUAL-01 : trois issues et une mutation rouge prouvée ; enregistré auprès de `check-planning-consumers-registered.sh` si le script entre dans son périmètre (P59-D-06, P59-D-15).
- [x] **PRDT-06**: PRD sous le seuil — halte remontée à l'humain (ADR-031) ; la main ne repasse au head qu'au-dessus du seuil ou sur un override humain explicite tracé au rapport ; au-dessus du seuil, le rapport de `vf-product-manager` propose le next step (découpage par le dev) sans le lancer ; aucun refus mécanique côté head (Phase 60) (P59-D-07, P59-D-17).
- [x] **PRDT-07**: Head — au poste `product` (lu par `vf-role.sh get`, jamais relu à la main), `vibeflow-head` redirige vers `/vf-product` au lieu de dispatcher `vf-coder` sur une intention de dev et dit pourquoi en une phrase, exécute sur demande explicite réitérée ; aux postes `solo` et `dev` rien ne change sauf qu'une intention produit explicite fait proposer `/vf-product` ; la redirection vit d'abord dans une référence chargée à la demande, baseline de `dev-orchestrator/AGENT.md` au plus 33 → 36 avec citation d'arbitrage (G-1), T3/T5/T37 verts (P59-D-08, P59-D-09, P59-D-20).
- [x] **PRDT-08**: Visibilité et exposition — `roles:["product"]`, `requires` = `conductor`, `planning-core`, `consolidator`, `audit-architecture`, `software-architecture` (sans `design-orchestrator`), RLPO-05 reste vert ; `proposable:false` jusqu'à un run réel complet (BRIEF → PRD → `prd-gate` ≥ seuil) sur un lab désigné par Samuel, bascule dans une PR tracée hors phase ; l'engine ignore `proposable` et pose le module sur `install --all` (P59-D-10, P59-D-11).
- [x] **PRDT-09**: Sobriété — agents neufs ≤ 250 lignes, frontmatters conformes à `check-agents.sh --strict` (I1, I2, I5, I6), trailers `Ajout-Retrait:` (nouveau `SKILL.md` et `check-prd.sh` : « aucun : capacité de jalon inscrite (SEED-001, ROADMAP 59) ») et `Gate-Touche:` sur toute suite surveillée touchée (P59-D-11, P59-D-12, P59-D-18).
- [x] **PRDT-10**: Suite du bundle — `test-product-team-bundle.sh` sur le modèle de `test-business-pilot-bundle.sh`, découverte automatique : `proposable:false`, `roles`, `requires`, frontmatters, lignes ≤ 250, `check-prd.sh` (vert, rouge, mutation) ; le test de `test-build-module-catalog.sh` qui boucle sur les bundles `proposable:true` est adapté pour exclure `product-team-bundle` (P59-D-18).
- [x] **PRDT-11**: Registres et documentation — une ligne par agent neuf dans `.planning/instruction-budget-baselines.tsv`, `check-agents-manifest.json` rafraîchi s'il est touché, triade `VERSION` ↔ `module.json`, compteur de modules 17 → 18 (badges et phrase « N modules » des deux README), pages du manuel FR et EN, README du bundle FR d'abord ouvrant sur « Un poste est une vue, pas un droit », disant `proposable:false`, son déclencheur de bascule et la pose par `install --all` (P59-D-19, P59-D-22).
- [x] **PRDT-12**: Livraison — `product-team-bundle` en `v1.0.0`, bump minor de `planning-core` et `dev-orchestrator` (`VERSION` lue au moment du bump), CHANGELOG et README, sans preset produit ; la release racine v2.73.0 est AUTORISÉE (arbitrage Samuel, AskUserQuestion session principale, 2026-10-29 : merger #172 avec --admin si les juges ne rendent aucun majeur et que la CI est verte, puis tag et release v2.73.0, numéro devenu 2.73.0 car v2.72.0 a été pris par la release de main, PR #178), ce qui amende la clause initiale « sans `VERSION` racine ni release » ; la Phase 45 (`gouvernance`) n'est pas un préalable : aucune coordination, aucun rebase, la PR se merge sur main telle quelle (P59-D-23) ; `PROJECT.md` racine périmé et table Coverage sans DLWS ni RLPO laissés en dette ; l'arrêt avant merge/tag/release initial est levé par l'arbitrage du 2026-10-29 ci-dessus (P59-D-03, P59-D-12, P59-D-21, P59-D-23).

### Gate architecture et phases proposées (Phase 60 — posées à la planification, 2026-10-29)
> Reformulent P60-D-01..14 (défauts documentés, source citée sur chaque ligne de `60-CONTEXT.md`) et P60-H-01..04 (hypothèses retenues faute de réponse humaine, à faire confirmer par Samuel) sans rien y ajouter ; les formes retenues dans la discrétion du planificateur sont tracées `P60-PL-NN` (`60-PLANNING-REGISTRE.md`). Mandat : Samuel, /vf-auto session principale, 2026-10-29 — il ne vaut pas arbitrage de fond. Un poste est une vue, pas un droit : rien ici n'est un contrôle d'accès, tout refus est advisory avec halte (ADR-031).

- [ ] **ARCG-01**: Marqueur de phase — champ gras `**Validation:**` dans la section de la phase (forme choisie par le planificateur, P60-PL-01), marqueur absent = phase validée (état de toutes les phases existantes) ; les lecteurs GSD (`roadmap get-phase`, `roadmap analyze`, case de checklist, `phase complete/insert/remove`) rendent le même résultat avec et sans marqueur, prouvé sur fixture ; une phase ajoutée par l'équipe au poste `product` ou `dev` naît proposée, aucune au poste `solo` ; la validation par un dev passe par un verbe de script, jamais par un skill ; la limite fail-open (« Regenerate all » d'`edit-phase`, phase ajoutée à la main hors équipe) est écrite (P60-D-02, P60-D-03, P60-D-10, P60-H-02, P60-H-03).
- [x] **ARCG-02**: Gate `check-phase-validation.sh` — sous `plugin/conductor/scripts/`, lecture seule, forme exec, bash portable, compartiment par `--ws` explicite, codes vert / rouge = proposée / indéterminé jamais vert à vide / illisible / usage sur le modèle de `check-prd.sh` ; il ne lit que le marqueur, jamais le poste ; trois issues et mutation rouge prouvée (QUAL-01) ; recensé auprès de `check-planning-consumers-registered.sh` ; trailers `Gate-Touche` sur les commits qui le touchent (P60-D-04, P60-D-11, P60-H-04).
- [x] **ARCG-03**: Refus par `vf-coder` — avant `gsd-plan-phase` et avant `gsd-execute-phase` d'une étape, `vf-coder` constate le marqueur ; phase proposée → rapport typé `blocked` avec un finding `action: ask-user`, aucune brique lancée ; `vf-dev-manager` inchangé, sa table de pilotage existante traite le bloc (P60-D-01).
- [x] **ARCG-04**: Chemin direct `vf-auto` — le skill porte le même contrôle avant la boucle du moteur `gsd-autonomous`, qui ne passe ni par le manager ni par `vf-coder` (P60-D-01).
- [x] **ARCG-05**: Découpage avant architecture — sur une intention de découpage (ajouter ou insérer une phase, nouvelle milestone, découper une étape), au poste `product` ou `dev` et seulement quand `.planning/BRIEF.md` existe, le head consulte le gate architecture via une référence chargée à la demande, s'arrête en disant pourquoi en une phrase, exécute sur demande explicite réitérée avec override tracé au rapport ; au poste `solo`, gate non consulté ; poste lu par `vf-role.sh get`, codes 1/5/64 jamais repliés sur `solo` (P60-D-01, P60-D-02, P60-H-01).
- [x] **ARCG-06**: `.planning/ARCHITECTURE.md` décisionnel — fichier niveau produit à côté de `PROJECT.md`, y compris en lab partitionné, distinct du descriptif `.planning/codebase/ARCHITECTURE.md` ; gabarit neuf dans `planning-core/references/templates/product/` (fichiers neufs plus bump et changelog seulement) ; l'état de validation vit dans le fichier (statut proposé/validé, poste et date du validateur) ; la validation appartient à un dev (P60-D-05, P60-H-02).
- [x] **ARCG-07**: Gate architecture séparé — script déterministe distinct de `check-phase-validation.sh`, même discipline (lecture seule, forme exec, codes, trois issues, mutation rouge), vert seulement si `ARCHITECTURE.md` existe, est marquée validée et porte ses rubriques minimales fixées depuis le gabarit ; résolvable depuis le head (P60-D-06, P60-D-11).
- [x] **ARCG-08**: Worker `vf-product-architect` — interne au `product-team-bundle`, dispatché par `vf-product-manager` (allowlist `Agent(...)` étendue), ≤ 250 lignes, `check-agents.sh --strict` ; il produit `ARCHITECTURE.md` proposée en assemblant le skill `software-architecture` et, quand du code existe, la carte `gsd-map-codebase`, et ne la valide jamais lui-même ; `gsd-graphify` reste refusé, mentionné seulement comme complément sous `graphify.enabled` ; une ligne neuve de baseline d'instructions pour ce fichier (P60-D-07, P60-D-08, P60-D-11).
- [ ] **ARCG-09**: Sobriété — aucune valeur existante de `.planning/instruction-budget-baselines.tsv` n'augmente (câblage par références chargées à la demande, marge de `vf-coder`, `SKILL.md` de `vf-auto`), `check-instruction-budget.sh` vert avant et après ; aucun skill neuf ; zéro nom de client ; chaque gate livré naît avec ses trois issues et sa mutation rouge, trailer `Ajout-Retrait` sur son ajout (P60-D-09, P60-D-10, P60-D-11).
- [x] **ARCG-10**: Manuel — pages FR et EN mises à jour pour l'architecture et la validation des phases, `check-manual.sh` vert (P60-D-12).
- [x] **ARCG-11**: Livraison — le dernier plan rejoue le job `gates` depuis `ci.yml` et les suites touchées, met le ledger à jour à la main et s'arrête avant PR, merge, tag et release ; les modules touchés reçoivent leur bump dans la phase ; le minor racine est décidé et fait par le manager après merge (P60-D-13, P60-D-14).

### Collaboration à deux humains (Phase 61 — posées à la planification, 2026-10-29)
> Reformulent P61-D-01..10 (défauts documentés, source citée sur chaque ligne de `61-CONTEXT.md`) et P61-H-01 (hypothèse retenue faute de réponse humaine, à faire confirmer par Samuel) sans rien y ajouter. Mandat : Samuel, /vf-auto session principale, 2026-10-29 — il ne vaut pas arbitrage de fond. COLB-08 dépend de P61-B-01 et P61-B-02 (bloqueurs humains) : elle reste décochée.

- [x] **COLB-01**: Armement par l'installeur — au poste `product` ou `dev` (P61-H-01), `role_apply()` (ou à côté) pose dans le clone un hook git `post-merge` qui joue `check-divergence.sh` après chaque fusion locale ; il le retire proprement quand le poste repasse à `solo` ou à la désinstallation ; au poste `solo` rien n'est posé et le comportement est inchangé (P61-D-01).
- [x] **COLB-02**: Jamais écraser un hook de l'utilisateur — pas de `core.hooksPath` ; le hook vit dans le répertoire de hooks réel du clone (`git rev-parse --git-path hooks`, worktrees compris) ; un `post-merge` existant qui n'est pas le nôtre n'est ni écrasé ni modifié : l'armement est refusé audiblement (message et code) avec la ligne à ajouter à la main (P61-D-02).
- [x] **COLB-03**: Le hook n'exécute jamais du code que la fusion vient d'apporter — l'exécutable `check-divergence.sh` est résolu hors de l'arbre versionné (cache du plugin installé), jamais depuis `.claude/scripts/` du lab ni `--show-toplevel` ; le répertoire inspecté reste le worktree courant ; exécutable introuvable = non vérifiable audible, jamais un faux conforme (P61-D-03).
- [x] **COLB-04**: Branchement sur les codes et journal — 1 crie, 0 et 3 silence, autre = non vérifiable sans bloquer ; chaque exécution non silencieuse ajoute une ligne horodatée à un journal non versionné propre au clone (sous le répertoire git commun), au format stable lisible par la recette ; `git pull --rebase` : la couverture par `post-rewrite` est mesurée, et s'il ne double pas `post-merge` la limite est écrite dans la doc (P61-D-04, P61-D-05).
- [x] **COLB-05**: Sortie — un opt-out explicite et documenté (variable d'environnement ou option de l'installeur), lu à chaque install ; non-interactif préservé (P61-D-06).
- [x] **COLB-06**: Champ `role:` des registres — DECISIONS, LEARNINGS et BLOCKERS portent le poste de qui a écrit l'entrée, au format existant des entrées, valeur lue par `vf-role.sh get` (codes 1, 5 et 64 jamais repliés sur `solo`) ; optionnel en lecture : une entrée sans le champ reste valide pour `check-registres`, `reindex`, `archive`, `detect-duplicates` et `detect-promotions`, prouvé par suite ; gabarit source modifié d'abord, copies ensuite (règle SYNC) (P61-D-07).
- [x] **COLB-07**: Preuve de mécanisme automatisée — une suite découverte par la CI crée un dépôt partitionné jetable, deux clones armés par le vrai chemin d'installation, fait diverger la numérotation d'un compartiment sur les deux, fusionne par un vrai `git pull`/`git merge`, et constate hook déclenché, divergence criée, ligne de journal écrite ; témoin rouge (hook désarmé ou exécutable muté, la suite rougit) ; aucun nom de client (P61-D-08).
- [ ] **COLB-08**: Preuve sur lab réel — deux humains, deux clones, postes `product` et `dev`, un workstream, trois semaines : toute divergence observée dans l'historique git est présente au journal ; la phase livre la procédure de recette (prérequis, armement, relevé hebdomadaire des journaux des deux clones, critère de passage, gabarit de compte rendu) et ne simule jamais la preuve humaine ; décochée tant que P61-B-01 (lab) et P61-B-02 (durée) ne sont pas levés (P61-D-09). **Bloqueur humain : lab et deux humains à désigner par Samuel.**
- [ ] **COLB-09**: Sobriété et livraison — aucune valeur existante de `.planning/instruction-budget-baselines.tsv` n'augmente, aucun skill neuf, agent neuf éventuel ≤ 250 lignes, bash portable (bash 3.2, ubuntu coreutils uutils, Git Bash), gates et hooks livrés en forme exec avec trois issues et mutation rouge (QUAL-01), trailer `Gate-Touche` sur tout commit qui touche `check-divergence.sh`, une suite ou une fixture surveillée, `scripts/hooks/`, `.github/` et les sentinelles `.planning/.*-armed` de ce dépôt intouchés, manuel FR et EN, le dernier plan rejoue le job `gates` depuis `ci.yml` et s'arrête avant PR, merge, tag et release (P61-D-10).

### Décision plateforme (Phase 62 — posées à la préparation, 2026-10-29)
> Reformulent P62-D-01..05 (cadrage sans humain joignable, mandat Samuel, /vf-auto session principale, 2026-10-29) sans arbitrage neuf. La phase prépare la décision ; elle ne la prend pas.
- [x] **PLTF-01**: Dossier de décision — `62-DECISION-plateforme.md` écrit sur la forme de `27-DECISION-claude-orchestration.md` : critères de la spec §4 C écrits avant les observations, mesures sourcées (commande et date, « non mesuré » pour toute mesure absente), options A / B / C avec coût, risque et prérequis, recommandation motivée, déclencheur de reprise et plancher de date proposés ; statut « PROPOSÉ ». Aucun code (P62-D-01..05).
- [x] **PLTF-02**: Décision signée par Samuel — option retenue (A, B ou C) et date de reprise confirmée ou corrigée, inscrites dans le dossier. Cochée le 2026-10-29 : option A, réexamen 2027-01-31 ; décision déléguée par Samuel, message session principale, 2026-10-29 : « décide pour moi les options A, B ou C. Choisis la meilleure option selon une étude de toi-même » ; option retenue par la session principale (P62-B-01 levé).

## Milestone vibeflow-v2.0 — « le cockpit VibeFlow » (inscrit 2026-11-01)

### Cockpit floorplan sur socle partagé (Phase 67 — posées à la planification, 2026-11-01)
> Reformulent P67-D-01..18 (`67-CONTEXT.md` ; arbitrages Samuel, AskUserQuestion session principale, 2026-11-01) sans arbitrage neuf. Famille `CKPT` vérifiée libre le 2026-11-01. Jalon `vibeflow-v2.0`.

- [x] **CKPT-01**: Socle partagé — collecteur « au travail » et graphe Projet en bibliothèque node du module, interface JSON documentée et versionnée (schéma nommé VibeFlow), test de forme des transcripts et `meta.json` de Claude Code (P67-D-12).
- [x] **CKPT-02**: Vendorisation floorplan v0.6.0 @ 92d6854 — patchs rejouables, LICENSE MIT et copyright conservés, ligne dans un fichier de licences tierces du module, `VENDORED.txt`, marqueur `vibeflow:allow-large-file` sur les fichiers vendorisés, procédure de synchro documentée (P67-D-03, P67-D-07, P67-D-11).
- [x] **CKPT-03**: Aucun appel sortant hors l'agent `claude -p` des questions — fonction Cloud retirée en entier (liste d'attente, `claude auth status`, `~/.floorplan/`) ; témoins grep et réseau qui rougissent (P67-D-02).
- [x] **CKPT-04**: Marque blanche par renommage mécanique à l'assemblage, logo VibeFlow inliné, zéro « Floorplan » visible hors commentaire de licence ; test qui rougit si une occurrence réapparaît (P67-D-03, P67-D-04).
- [x] **CKPT-05**: Serveur unique — direct SSE, questions et « au travail » sur le serveur patché, sans second port ni CORS, bind `127.0.0.1`, jeton et contrôle du Host conservés, repli par polling (P67-D-13, P67-D-16).
- [x] **CKPT-06**: Onglet Projet sur tout lab GSD (plat ou partitionné) ; onglet Code conditionnel : extracteur VibeFlow si `plugin/*/module.json`, sinon scan brut, aucun LLM à l'assemblage (P67-D-17).
- [x] **CKPT-07**: Questions — formes courantes locales, agent `claude -p` confiné (lecture bornée à la racine du lab, Bash limité aux scripts de requête), modèle `sonnet` par défaut, variable d'environnement et sélecteur de modèle validé côté serveur (P67-D-08, P67-D-15).
- [x] **CKPT-08**: Dernière commande des sessions masquée : absente du flux SSE, des fichiers générés et de l'export, révélée par requête authentifiée ponctuelle ; test qui le prouve (P67-D-14).
- [x] **CKPT-09**: Chrome en français par défaut ; les textes produits par le moteur (Santé, couverture de l'onglet Code) peuvent rester en anglais — motif : réponse E1 de Samuel (« on pourrait avoir des gens qui utilise l'anglais, donc en soit l'anglais n'est pas dérangeant et peut etre un des langues autorisées », AskUserQuestion session principale, 2026-11-01), voir `67-CONTEXT.md` P67-D-20 ; test qui rougit (P67-D-03, P67-D-18).
- [x] **CKPT-10**: Module toggable `plugin/cockpit` (`module.json`, `VERSION`, `CHANGELOG`, `README`), verbe `/vf-cockpit`, posé par l'engine y compris les binaires, sortie `.vibeflow/cockpit/` avec son `.gitignore` ; aucun bump de la `VERSION` racine (P67-D-05, P67-D-06).
- [x] **CKPT-11**: `dag.sh` — écriture atomique de `save()` (fichier temporaire du même dossier puis `os.replace`), témoin rouge d'abord (lecture pendant une écriture lente) ; validation ADR-031 limitée à ce correctif (P67-D-09).
- [x] **CKPT-12**: Responsive minimal — la fenêtre du cockpit est ajustable : de 1 024 à 2 560 px de large, au chargement comme au redimensionnement à chaud, aucune superposition ni rognage de l'en-tête, des panneaux et de la barre de question ; rendu non cassé en dessous ; la carte se recadre au redimensionnement ; test qui mesure les boîtes à 1 024, 1 280, 1 440 et 1 920 px (demande de Samuel, message session principale, 2026-11-01 : « au moins pouvoir avoir la fenêtre ajustable » ; `67-CONTEXT.md` P67-D-21).

### Suivi du travail en cours dans le cockpit (Phase 69 — posées à l'inscription, 2026-11-03)
> Reformulent P69-D-01..11 (`69-CONTEXT.md` ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) sans arbitrage neuf. Suite de la famille `CKPT` (CKPT-13 à CKPT-18 vérifiés libres le 2026-11-03). Jalon `vibeflow-v2.0`.

- [x] **CKPT-13**: `readPlanning` expose par phase un objet versionné `avancement` (`version`, `etat`, `plans`, `correctifs`, `mission`, `reste`) à quatre états, chacun prouvé par une trace locale : `a-faire` (aucun SUMMARY de plan), `en-cours` (au moins un plan fait, ou mission rattachée avec un nœud `running`), `a-recetter` (tous les plans faits, phase non cochée), `fait` (case de ROADMAP cochée) ; témoin rouge : STATE sur une autre phase et plans faits → `a-recetter` (aujourd'hui : à faire) (P69-D-02, D-03).
- [x] **CKPT-14**: Un plan est fait s'il a un `*-PLAN.md` et son `*-SUMMARY.md` ; les SUMMARY sans PLAN sont comptés à part (« N correctifs ») ; témoin rouge : 7 PLAN, 7 SUMMARY et 4 SUMMARY de correctif → `7/7 plans · 4 correctifs` (aujourd'hui : 11/7) (P69-D-04).
- [x] **CKPT-15**: Une mission est rattachée à sa phase dans l'ordre : champ `phase` du DAG, nom `MISSION-<n>`, DAG situé dans le dossier de la phase ; témoin rouge : DAG avec `phase: 67` → rattaché à la 67 (aujourd'hui : « Missions hors phase ») (P69-D-05).
- [x] **CKPT-16**: Le jalon est `en-cours` dès qu'une de ses phases est `en-cours` ou `a-recetter`, quel que soit le STATE ; son pied lit « N clos · N à recetter · N à faire · N % », pourcentage strict (phases closes seulement), jamais pondéré ; témoin rouge : jalon `📋` avec une phase `a-recetter` → `en-cours` (aujourd'hui : à faire) (P69-D-06).
- [x] **CKPT-17**: `reste` liste les étapes restantes déduites de traces locales seulement (recette humaine : un `*-RECETTE-HUMAINE.md` dont le statut n'est pas « FAITE » ; vérification : pas de `*-VERIFICATION.md` ; clôture : case de ROADMAP non cochée) ; aucune lecture réseau, CI, merge et PR ne sont ni lus ni affichés ; test qui le prouve (P69-D-07).
- [x] **CKPT-18**: La règle `ph.n === curPhase` (STATE → statut de phase) est retirée de `phaseStatus` : le STATE ne pilote plus le statut d'une phase sur la carte (un ajout = un retrait, SOBR-01..08) ; test qui rougit si elle réapparaît (P69-D-08).

### Équipe au travail dans le cockpit (Phase 69 — posées à la mise à jour du cadrage, 2026-11-03)

> Reformulent P69-D-12..24 (`69-CONTEXT.md` ; arbitrages Samuel, AskUserQuestion session principale, 2026-11-03) sans arbitrage neuf. Suite de la famille `CKPT` (CKPT-19 à CKPT-28 vérifiés libres le 2026-11-03). Jalon `vibeflow-v2.0`. Chaque exigence porte son témoin rouge, joué avant le code.

- [x] **CKPT-19**: Le collecteur `who` du socle expose l'équipe en arbre session → manager → workers (rattachement par `parentAgentId`, profondeur par `spawnDepth`), chaque agent avec son type, sa description, son état (actif ou terminé) et sa durée ; le tiroir « Au travail » affiche cet arbre à la place de la liste plate des sous-agents (un ajout = un retrait) ; témoin rouge : fixture à trois niveaux → arbre à trois niveaux (aujourd'hui : liste plate) (P69-D-14).
- [x] **CKPT-20**: L'équipe montre les agents actifs et ceux terminés depuis moins de 24 h, grisés et repliés par défaut ; au-delà de 24 h, un agent terminé n'apparaît plus ; témoin rouge : un agent `finished` depuis 2 h est présent et marqué terminé, un autre depuis 25 h est absent (aujourd'hui : tout agent `finished` est écarté) (P69-D-18).
- [x] **CKPT-21**: Chaque agent est rattaché au nœud de mission qu'il exécute, d'abord par le registre de `driver-lock.sh` (`--node`), sinon par un nom de nœud cité dans son mandat et présent dans un DAG connu du lab ; jamais deviné (un nom absent des DAG ne lie rien) ; le lien est cliquable dans les deux sens (agent → nœud, nœud → agent) ; témoin rouge : mandat qui cite « Nœud `revue-p3` » et DAG qui porte `revue-p3` → lien posé ; mandat qui cite un nœud inconnu → aucun lien (aujourd'hui : aucun lien) (P69-D-15).
- [x] **CKPT-22**: Pour chaque agent actif, une dernière action lisible (verbe et cible courte, par exemple « lit X », « lance une commande ») dérivée du dernier appel d'outil de son transcript ; jamais l'argument d'une commande, une sortie d'outil ni un chemin hors du lab, ni dans la sortie de `who`, ni dans le flux SSE ; témoin rouge : dernier appel Bash dont la commande porte un secret factice → libellé présent, secret absent de `who` et du flux (P69-D-16).
- [x] **CKPT-23**: Un troisième onglet « Équipe », en carte comme Code et Projet, montre l'équipe au travail ; libellés en français (suite de CKPT-09) ; témoin rouge : test d'assemblage qui rougit si l'onglet manque ou si un libellé anglais apparaît dans son chrome (P69-D-17).
- [x] **CKPT-24**: Le transcript d'un agent se lit à la demande, réduit à son mandat, ses messages et la liste de ses appels d'outils (nom et libellé réduit ; la commande seulement derrière « Voir la dernière commande », règle F-B de `v2.75.0`) ; jamais les sorties d'outils ni le contenu des fichiers lus ; témoin rouge : fixture dont une sortie d'outil et un fichier lu portent un marqueur → marqueur absent de la réponse (P69-D-19).
- [x] **CKPT-25**: Le transcript n'est servi que par une requête authentifiée ponctuelle (jeton et contrôle du Host, comme la dernière commande de CKPT-08), pour un identifiant d'agent connu d'une session du lab ; jamais dans le flux SSE, les fichiers générés ni l'export ; témoins rouges : requête sans jeton → refus ; identifiant hors liste ou porteur d'un chemin (`../`) → refus ; marqueur du transcript absent du flux SSE et de `.vibeflow/cockpit/` (P69-D-19).
- [x] **CKPT-26**: Le contenu de l'équipe et des transcripts est rendu comme du texte, jamais comme du HTML ; la CSP du cockpit reste celle de `v2.75.0` ; témoin rouge : message d'agent porteur de `<img src=x onerror=…>` → rendu en texte, aucun nœud `img` créé, en-tête CSP identique (P69-D-23).
- [x] **CKPT-27**: Le test de forme de Claude Code (CKPT-01) couvre tous les champs nouvellement lus (`meta.json` : `parentAgentId`, `spawnDepth`, `finished`, `toolUseId`, `requestShape` ; transcript de sous-agent : `isSidechain`, `agentId`), déclarés dans `vf-cockpit-interface.json` ; un champ disparu rend la source `forme-inconnue`, jamais un arbre faux ; témoin rouge : fixture amputée de `parentAgentId` → test rouge et source `forme-inconnue` (P69-D-22).
- [x] **CKPT-28**: Tout le calcul de l'équipe vit dans la bibliothèque du socle (`who`), sous un schéma JSON versionné dont la version monte ; aucune requête réseau ajoutée (suite de CKPT-03) ; aucune couche de synonymes ; témoin rouge : test qui rougit si la sortie ne porte pas la nouvelle version de schéma, et témoin réseau de CKPT-03 rejoué sur le serveur de la phase (P69-D-23).

### Finitions UI du cockpit (Phase 70 — posées au cadrage, 2026-11-03)
> Reformulent P70-D-01..10 et P70-D-16 (UIFN-10 réécrite le 2026-11-04 par P70-D-19 ; UIFN-11 à UIFN-14 ajoutées le 2026-11-04 par P70-D-20 et P70-D-21) (`70-CONTEXT.md` ; « Tout accepter (Recommandé) », arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 ; P70-D-07 et P70-D-08 : arbitrages antérieurs, même canal, même date ; P70-D-09 et P70-D-10 : choix du manager). Préfixe neuf `UIFN` (P70-D-12), vérifié libre le 2026-11-03. Jalon `vibeflow-v2.0`. Exécution après le merge de la Phase 69.

- [x] **UIFN-01**: À ≤ 700 px, l'en-tête tient sur une seule rangée : logo, onglets, recherche, point « au travail », bouton « ⋯ » ; le menu du « ⋯ » donne un libellé visible à chaque action (thème, Santé, Travail récent, Écrans, Visite, Exporter, Parcours, Types de liens) et porte les pastilles de compte ; témoin rouge : à 390 px, l'en-tête fait aujourd'hui 3 rangées (~148 px) et ses actions sont des icônes sans libellé ; avec les trois onglets (Code, Projet, Équipe), le groupe d'onglets garde les valeurs de `DESIGN.md` (13 px, piste à 3 px de padding) et l'en-tête tient à 390 et à 1 024 px ; la borne `.hl` et le témoin R4.2 sont recalculés, pas élargis (P70-D-01, P70-D-16). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-04 (`test-cockpit-responsive.sh`, R13 à R16, 261/0 ; borne `.hl` à 342 px calculée, R4.2 mutant à 400 px) et 70-10 ; points 1 et 1 bis de `70-RECETTE-JUGES.md` (1 bis tranché par P70-D-22) ; suite à 291/0 et CI de la PR #200 verte à `a15b073d` ; publiée en `v2.76.0`.
- [x] **UIFN-02**: À ≤ 700 px, les trois boutons de zoom forment une pile verticale à gauche, au-dessus de la barre de question, sans recouvrir « Remonter d'un niveau » ; la tablette est inchangée ; chaque bouton de zoom a un `aria-label` français à toutes les largeurs ; témoin rouge : aujourd'hui, ils sont dans l'en-tête, avec un `title` sans `aria-label` (P70-D-09). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-05 (R14 verts, `aria-label` à toutes les largeurs) ; points 3, 3 bis de `70-RECETTE-JUGES.md` ; publiée en `v2.76.0`.
- [x] **UIFN-03**: À ≤ 700 px, aucun bouton « Détail » ; le tiroir s'ouvre au tap d'une carte ou du titre de la vue d'ensemble, et porte une poignée et une croix visibles avec un nom accessible ; Échap et le tap dans le vide le ferment toujours ; témoin rouge : aujourd'hui, `#btn-panel` est visible et le tiroir n'a pas de croix (P70-D-10). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-05 (R15.1 à R15.4c verts) ; point 2 de `70-RECETTE-JUGES.md` ; publiée en `v2.76.0`.
- [x] **UIFN-04**: Visite « Par où commencer » : chaque étape cible un élément et y centre la carte, le texte s'affiche entier, « Passer » reste visible à chaque étape, un repère « n sur N » est affiché, le texte nomme les boutons tels qu'ils s'affichent (« La lire »), aucun mot anglais (« at the top », « and ») ; témoin rouge sur chacun des constats de `70-CONTEXT.md` (P70-D-02).
- [x] **UIFN-05**: L'onglet Projet a sa propre visite (jalon, phase en cours, missions, au travail), fournie par les données de la page (`tour` non vide) ; aucune étape n'y dit « La base de code » ni « dans le code » ; témoin rouge : aujourd'hui, `tour: []` et repli sur la visite du code (P70-D-02). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-08 (`test-cockpit-projet.sh` 86/0, O6.1 à O6.9, O6.5 dans Chrome à 1 440 et 390 px) ; point 4 de `70-RECETTE-JUGES.md` ; publiée en `v2.76.0`.
- [x] **UIFN-06**: Plus aucun anglais ni coquille dans l'interface en mode français : liste O5 (« Calls », « ⌫ up », compteurs Santé, phrase mixte « still use generated names », « de le CLI », « 1 fichiers »), pluriels construits à l'exécution, « Claude Code and GSD », « Contrôle De Santé », élision « de » + voyelle, statuts bruts ; les constats du panneau Santé restent en anglais (P67-D-20) ; `?lang=en` est inchangé (P70-D-03, P70-D-04).
- [x] **UIFN-07**: Le garde du français voit les formes de UIFN-06 (mots isolés, mots courts, pluriels rendus à l'exécution, gabarits pris dans le mauvais ordre) ; témoin rouge : rejoué sur le code d'avant la phase, il rougit sur au moins une chaîne de chaque forme (P70-D-04).
- [x] **UIFN-08**: Sur un lab sans `STATE.md`, « Où en est-on ? » (voie locale) omet les champs absents ou dit qu'il n'y a pas de `STATE.md`, et ne rend ni champ vide ni « ? » ; témoin rouge : aujourd'hui, « Dernière phase : ? · , le ?. » (P70-D-05). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-06 (Q15 à Q17 rouges, 57 PASS / 8 FAIL, puis verts, `test-cockpit-questions.sh` 65/0 ; réponse avant et après consignée) ; aucun point de juge, preuve par suite rouge puis verte ; publiée en `v2.76.0`.
- [x] **UIFN-09**: Conformité à `DESIGN.md` : `--st-active` vaut `var(--sev-medium)`, `--st-blocked` vaut `var(--sev-high)`, `--text-1` n'est plus utilisée, aucune couleur en dur dans `ui/00-vibeflow.js` et les fichiers `ui/*vf*` hors exceptions justifiées ; témoin rouge : sonde rejouée sur le code d'avant la phase (P70-D-07). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-02 (`test-cockpit-marque-blanche.sh` 30/0 : M5.3 rouge sur la base puis vert, M5.1 et M5.2 gardées par un mutant chacune) ; point 6 de `70-RECETTE-JUGES.md` ; publiée en `v2.76.0`.
- [ ] **UIFN-10**: Captures avant et après à 390, 768 et 1 440 px, dans les deux thèmes, consignées (les « avant » prises hors dépôt sur `794c6dba`) ; la recette est jouée par des juges frais, chacun sur son propre Chromium headless piloté par la bibliothèque `playwright` (jamais le MCP partagé), deux thèmes, 390 / 1 024 / 1 440 px, qui rendent un verdict factuel par point ; seuls les points de goût (avis humain indispensable) remontent à Samuel, groupés en un seul tri, jamais remplis ni cochés par un agent ; aucun correctif sans arbitrage (P70-D-06 amendé par P70-D-19 : arbitrage de méthode de Samuel, AskUserQuestion session principale Claude Code, 2026-11-04).
- [x] **UIFN-11**: Onglet Équipe, réglages visuels : le badge d'état n'est plus rogné (« En cours » en entier), « non rattaché (sans-citation) » tient sur une ligne, les boutons « Voir la dernière commande » et « Lire le transcript » ont le style des boutons du tiroir (DESIGN.md), les champs Rôle / État / Branche / Arbre / Nœud sont des paragraphes distincts, le lien « Nœud … » se distingue d'un texte ; régime quick, aucun nouveau test (P70-D-21, choix du manager, vf-dev-manager, 2026-11-04). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-02 (cinq réglages) ; point 7 de `70-RECETTE-JUGES.md` (conforme après correction du badge hors de la carte, `643bc7ac` et `94078aab`) ; tri de goût, question 12 ; publiée en `v2.76.0`.
- [x] **UIFN-12**: Après Entrée sur « Lire le transcript » dans le tiroir de l'onglet Équipe, le focus clavier ne tombe pas sur `BODY` ; témoin rouge : aujourd'hui, `document.activeElement` est `BODY` (P70-D-21). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-11 (EK1 rouge puis vert, EK8 et EK9, un mutant par témoin) ; point 8 de `70-RECETTE-JUGES.md` ; publiée en `v2.76.0`.
- [x] **UIFN-13**: Les cinq mineurs de la Phase 69 ont chacun un témoin capable de rougir, prouvé par un mutant appliqué à une copie : clé de rechargement effacée au changement d'agent, `sessionStorage` qui ne garde que l'identifiant, tiroir fermé non rouvert par un `who`, clause `..` de la grammaire ws, commande rendue en `textContent` (P70-D-21). Le point « écrit à <id d'agent> » est exclu : arbitrage de goût de Samuel en attente. — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-11 (EK2 à EK5 et W19, chacun avec son mutant : m1, m10, m8, m5, m6, posé dans la page servie ou une copie) ; aucun point de juge, preuve par suite et mutants ; publiée en `v2.76.0`.
- [x] **UIFN-14**: Onglet Équipe, mise en page : à toute largeur ≥ 701 px le zoom est la rangée en bas à gauche (P70-D-20, choix du manager, vf-dev-manager, 2026-11-04, pas un arbitrage de Samuel) ; le titre ne recouvre plus la première carte au premier affichage ni après ouverture d'une session ; le fil d'Ariane ne passe pas sous la recherche sur la fixture qui le provoque (ou « non reproduit, témoin négatif ») ; la page Équipe entre dans la matrice responsive ; témoins de superposition rouges avant, verts après (P70-D-21). — Livré 2026-11-04, coché 2026-11-11 (alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), preuve : 70-12 (R17 à R20 : 7 FAIL sur le code d'avant puis verts ; R18 non reproduit, témoin négatif ; page Équipe dans la matrice responsive, R20) ; points 3 ter et 9 de `70-RECETTE-JUGES.md` ; publiée en `v2.76.0`.

### vf-signal embarqué sur le socle partagé (Phase 68 — posées au cadrage, 2026-11-03)

> Reformulent P68-D-01..21 (`68-CONTEXT.md` ; arbitrages Samuel, AskUserQuestion session principale Claude Code, 2026-11-03, « Tout accepter (Recommandé) » ; décisions techniques du manager sur mesure) sans arbitrage neuf. Famille `VFSG` proposée par le handoff du 2026-10-29 § 3, vérifiée libre le 2026-11-03. Jalon `vibeflow-v2.0`. Chaque exigence porte son témoin rouge, joué avant le code.

- [x] **VFSG-01**: Le mod `vf-signal` est embarqué dans le module `cockpit` (aucun nouveau module), déclaré au niveau du plugin par un `hooks.json` qui ne porte que `modules` et ne s'appelle pas `plugin/cockpit/hooks/hooks.json` ; clés d'état `vibeflow.*` ; `claude plugin validate plugin` vert ; l'install du module `cockpit` par l'engine reste verte ; témoin rouge : un `hooks.json` sans clé `hooks` posé sous `plugin/cockpit/hooks/` fait échouer l'install (P68-D-01, D-11, D-12, D-13).
- [x] **VFSG-02**: Le mod n'enregistre ni pane, ni bandeau, ni commande sans ligne `cockpit=` dans `scripts/.vibeflow-installed` (scope projet puis user) ; témoin rouge : registre sans `cockpit=` → aucune surface (aujourd'hui : toujours actif) (P68-D-01, D-18).
- [x] **VFSG-03**: Le socle publie un émetteur JSON unique, schéma versionné déclaré dans `vf-cockpit-interface.json`, qui sérialise sans recalcul phases avec `avancement`, jalon, missions, worktrees, retard sur `main` et équipe `who@2` ; aucune lecture réseau ; la lecture maison du planning du mod (`disk.ts` : STATE, ROADMAP, MILESTONES, BACKLOG, scan des DAG par date) et le choix de phase par `current_phase` sont retirés ; témoin rouge : test qui rougit si le mod lit un fichier de `.planning/` directement (P68-D-02, D-15, D-17).
- [x] **VFSG-04**: L'arbre des agents de la pane vient de `who@2` (toutes sessions, tous worktrees, 24 h) ; les gestes « voir » et « demander l'arrêt » ne s'offrent qu'aux agents de la session courante ; témoin rouge : un agent d'une autre session apparaît dans l'arbre sans geste (P68-D-03).
- [x] **VFSG-05**: Sans réseau, l'en-tête signale un arbre en retard sur `main` local et sur `origin/main` local (« en retard de N commits sur main, dernier fetch il y a X ») et liste chaque worktree avec sa branche et sa phase active ; témoin rouge : fixture d'arbre en retard de 3 commits → badge « en retard de 3 », fixture à deux worktrees → deux lignes (aujourd'hui : rien) ; témoin réseau : aucun `git fetch` ni requête (P68-D-04).
- [x] **VFSG-06**: Dans le socle, une mission n'est « en cours » que si son verrou de driver est tenu et non périmé ou si son `progress_epoch` date de moins que le TTL (1 800 s) ; sinon elle est « abandonnée, nœuds non refermés », grisée dans la pane, avec le bouton humain d'élagage ; la version du schéma `avancement` monte ; jamais la date de modification d'un DAG ; témoin rouge : DAG avec un nœud `running` sans verrou ni progrès récent → `abandonnee` (aujourd'hui : en cours), sur la pane et sur la carte Projet (P68-D-05, D-16).
- [x] **VFSG-07**: La pane suit « Graphite » (`DESIGN.md`) : couleurs de statut seulement, tokens nommés, aucun hex en dur hors du fichier de tokens, plus de cyan ni d'orange de marque, « à recetter » écrit en toutes lettres ; témoin rouge : test qui rougit sur un hex en dur dans une vue (P68-D-06, D-17).
- [x] **VFSG-08**: La CI joue `claude plugin validate` et `claude plugin test` du mod (étape ajoutée à `ci.yml`, trailer `Gate-Touche`, revue `@picmakpro`) ; prouvé sous Linux avec un témoin rouge (test cassé → job rouge) (P68-D-07).
- [x] **VFSG-09**: Le mod embarqué détecte l'ancien `~/.claude/mods/vf-signal` et l'affiche (risque de deux panes) ; aucun retrait automatique ; le retrait est documenté comme geste humain ; témoin rouge : fixture avec l'ancien mod présent → signal affiché (P68-D-08).
- [x] **VFSG-10**: Un bouton humain « Ouvrir le cockpit » lance `vf-cockpit.mjs open` (posé, sinon depuis `$.plugin.root`) et affiche l'URL rendue ; aucun geste d'agent (ADR-031) ; test simulé qui prouve l'argv et l'analyse de la sortie (P68-D-19).
- [x] **VFSG-11**: Le mod appelle le socle par `$.process.run(['node', …])` ; un rejet (node absent du PATH) affiche « node introuvable dans le PATH » sans planter ; un JSON illisible est signalé ; la chaîne réelle node + émetteur est prouvée par un test de l'émetteur dans les suites du cockpit ; témoins rouges : rejet simulé et stdout tronqué (P68-D-14).
- [x] **VFSG-12**: Recette humaine pas à pas sur terminal plein écran, inline, VS Code et mobile, plus un passage `claude -p --plugin-dir` consigné ; doc du module et README racine FR/EN à jour ; aucun chemin de machine dans les fichiers suivis (`check-machine-paths.sh`) (P68-D-08, D-14, D-20).
- [x] **VFSG-13**: Bump minor du module `cockpit` préparé et relecture adverse SOBR-04 du diff de la phase (sonde exécutée) ; le bump racine part avec la release groupée, tag et release GitHub gestes de Samuel hors phase (P68-D-31, D-21).
### Terminal intégré au cockpit (Phase 71 — posées au cadrage, 2026-11-03)
> Dérivent de P71-D-01..17 (`71-CONTEXT.md` ; arbitrages Samuel, AskUserQuestion session principale Claude Code, 2026-11-03, relayés au manager ; décisions techniques du manager sur mesures). Famille neuve `TERM` (vérifiée libre sur `origin/main` et les branches des Phases 68, 69, 70 le 2026-11-03 : un CKPT-29+ entrerait en collision). Jalon `vibeflow-v2.0`.

- [x] **TERM-01**: Activation : sans `--terminal`, aucun second écouteur, aucune route ni tiroir terminal, la CSP de page est octet pour octet celle de `v2.75.0` ; avec, un second serveur sur `127.0.0.1` seulement, port distinct (P71-D-02).
- [x] **TERM-02**: Contrôles du second serveur : Host, Origin et jeton sur chaque requête, aucun shell avant authentification (P71-D-10). Témoins : Origin tierce, Origin `127.0.0.1:P`, Host de rebinding, sans jeton, mauvais jeton, jeton d'amorçage rejoué → refus et 0 PTY lancé.
- [x] **TERM-03**: Jetons jamais servis ni journalisés : 0 occurrence dans toute réponse HTTP de P et de Q, le SSE, `serveur.log`, l'export, `.vibeflow/cockpit/` (P71-D-11).
- [x] **TERM-04**: Amorçage dans la même fenêtre : fragment effacé, historique sans jeton, secret jamais en cookie, inaccessible depuis P (P71-D-12, P71-D-13).
- [x] **TERM-05**: Tiroir dans les pages Projet et Code, en cadre d'origine Q ; CSP de P = celle de `v2.75.0` + `frame-src` exact ; CSP de Q stricte (scripts par empreintes, `connect-src 'self'`, `frame-ancestors` = origines de P) ; 0 violation au fonctionnement normal (P71-D-08, P71-D-16).
- [x] **TERM-06**: Shell : `$SHELL -l`, `cwd` = `realpath(lab)`, environnement complet moins `CLAUDECODE`, `CLAUDE_CODE_*`, `VF_COCKPIT_*` et toute valeur de jeton (P71-D-03, P71-D-04, P71-D-14).
- [x] **TERM-07**: PTY : assistant Python stdlib, lancé isolé (`-I`), redimensionnement, Ctrl-C (SIGINT au groupe de premier plan), macOS et Linux ; sous Windows, message « indisponible » et aucun second serveur (P71-D-06, P71-D-07).
- [x] **TERM-08**: Session : une seule, la deuxième est refusée ; survie au rechargement (30 s de grâce, tampon de 256 Ko en mémoire) ; SIGHUP au groupe après la grâce ; aucun processus de la session du terminal survivant à l'arrêt du serveur, `nohup` et `disown` compris (un processus sorti de la session par `setsid` est une limite écrite, P71-D-28) ; le terminal ouvert empêche l'arrêt sur inactivité (P71-D-05).
- [x] **TERM-09**: Usage réel : un programme plein écran (alternate screen, couleurs 256/truecolor, SIGWINCH, SIGINT) se comporte normalement dans le terminal (test automatisé avec un programme témoin) ; `claude` démarre à la racine du lab et y voit son `CLAUDE.md` et ses skills, et une commande VibeFlow tourne (recette humaine, macOS ; Linux par la CI pour la partie automatisée) (P71-D-01, P71-D-06).
- [x] **TERM-10**: xterm.js vendorisé avec sha256 et licence ; aucun addon presse-papiers ; séquences OSC 52, OSC 8, DCS, CSI 21t, DECRQSS dans la sortie : presse-papiers inchangé, aucun octet choisi par la sortie réinjecté dans l'entrée du PTY (seules les réponses de format fixe d'xterm — DA1, DA2, DSR, CPR, DECRQM, couleurs OSC — le sont, F8 de l'audit, P71-D-25) (P71-D-16).
- [x] **TERM-11**: Aucune frappe ni sortie du terminal sur disque ni dans les flux du cockpit (journal, SSE, export) ; le tampon de reprise est vidé à la fin de la session.
- [x] **TERM-12**: Non-régression et chaîne XSS : toutes les suites du cockpit restent vertes ; la chaîne de `test-cockpit-chaine-xss.sh` étendue — une charge exécutée dans P qui tente `window.open` vers Q, `postMessage`, `fetch`/POST vers Q avec le jeton de page, la lecture du stockage de Q — ne crée aucun fichier marqueur par le shell.

### Lancer du travail depuis les cartes du cockpit (Phase 72 — posées à la planification, 2026-11-05)

- [x] **LANC-01**: Cartes : avec `--terminal`, les cartes de phase et de mission de l'onglet Projet portent une action principale selon l'état et un menu des autres verbes de la liste fermée (P72-D-04, P72-D-05). — Livré 2026-11-06, preuve : 72-06 (`test-cockpit-lancer-ui.sh` 45/0), 72-09, 72-14 (tiroir 75/0) ; recette par juge au SHA 4fa5fe95, étapes 1 à 6.
- [x] **LANC-02**: Sans `--terminal` : CSP de page identique octet pour octet, aucun bouton, aucune route POST (P72-D-17, TERM-01). — Livré 2026-11-06, preuve : 72-06 (LU.S1 à LU.S7) et 72-09 (CSP de `v2.75.0` identique sans `--terminal`) ; audit du lot 3 SECURED.
- [x] **LANC-03**: Route POST de P : Host, Origin exacte, jeton en temps constant, `Content-Type`, corps borné, schéma fermé ; témoins : Origin tierce, Origin absente, Origin de Q, mauvais jeton, corps trop long, champ inconnu → refus et 0 proposition (P72-D-11). — Livré 2026-11-06, preuve : 72-04 (`test-cockpit-lancer-post.sh` 95/0, douze mutants rouges) ; 72-09.
- [x] **LANC-04**: Liste fermée : une cible malformée (`72;touch M`, `$(touch M)`) ou bien formée mais absente de la liste du serveur → aucun bandeau, 0 octet au PTY, aucun marqueur (P72-D-12). — Livré 2026-11-06, preuve : 72-03 (cibles), 72-05, 72-10, 72-11 (chaîne XSS, 57/0 sous Chrome) ; audits des lots 1 à 3.
- [x] **LANC-05**: Gabarit : avec un lab de test dont le titre de phase vaut `"; touch M #` et `<img src=x onerror=…>`, la ligne écrite est exactement le gabarit, dans l'alphabet fermé ; titre affiché par `textContent` ; 0 violation CSP, 0 marqueur ; mutant qui interpole le titre → rouge (P72-D-13). — Livré 2026-11-06, preuve : 72-01 (gabarit, 51 verdicts, mutant d'interpolation rouge), 72-11 (titre hostile), 72-12 (argv comparé octet pour octet).
- [x] **LANC-06**: Premier plan : programme témoin au premier plan, confirmation → 0 octet reçu par le programme et message clair ; mutant sans contrôle → rouge (P72-D-01). — Livré 2026-11-06, preuve : 72-02 (assistant PTY 45/0, session 15/0), 72-10, correctif `ecriture` (`vf-cockpit-pty.py`, L10.1).
- [x] **LANC-07**: Double geste : aucune écriture sans clic dans Q ; clic avant le délai d'armement ignoré ; ligne écrite sans `\r` ; la charge XSS de `test-cockpit-terminal-xss.sh` (proposition, `iframe.click()`, `postMessage`, popup) ne crée aucun marqueur (P72-D-14, TERM-12). — Livré 2026-11-06, preuve : 72-02, 72-05, 72-10, 72-11 (aucun marqueur), 72-12 (clic précoce ignoré, ligne sans retour chariot, Entrée au clavier) ; audit du lot 3.
- [x] **LANC-08**: Pré-vols : chaque bloquant de P72-D-06 empêche le lancement avec son motif ; chaque avertissement s'affiche sans bloquer ; emplacement « travail non commité » prévu, inactif (P72-D-06, P72-D-07). — Livré 2026-11-06, preuve : 72-03 (50 témoins rouges puis verts), 72-09 ; correctif ST-1 (`verdict()` source unique, E2c).
- [x] **LANC-09**: Mode de permission : le bandeau propose `default`, `acceptEdits`, `plan` et « hérité » ; « hérité » = aucun drapeau ; présélection = dernier mode choisi, retenu dans le stockage de l'origine Q, `default` au premier lancement ou si la valeur retenue est hors liste ; témoins : P ne peut ni lire ni écrire ce choix (`SecurityError` mesuré), une valeur forgée dans le stockage de Q retombe sur `default` (P72-D-02, P72-D-02bis). — Livré 2026-11-06, preuve : 72-10, 72-11, 72-12 (présélection du mode) et 72-16 (fichier du lab, P72-D-20, 18 mutants) ; audit du lot 3 SECURED.
- [x] **LANC-10**: Suivi : `--session-id` généré, la carte montre « lancée » et rattache la session de l'onglet Équipe ; proposition consommée une seule fois (un rechargement ou une bascule de thème ne la fait pas revenir) (P72-D-16, P72-D-10). — Livré 2026-11-06, preuve : 72-05, 72-07 (37/0), 72-09, 72-10, 72-12 (suivi rattaché à l'onglet Équipe) ; proposition consommée une fois.
- [x] **LANC-11**: Continuer le chat : option offerte seulement si une conversation existe et si la sonde de P72-D-03 est verte ; identifiant validé UUID (P72-D-03). — Livré 2026-11-06, preuve : 72-13 : porte A5 VERTE le 2026-11-05 (claude 2.1.318) ; garde d'activation (P72-D-21, `2b9e23b9`) et manche RES (P72-D-22).
- [ ] **LANC-12**: Usage réel et non-régression : de bout en bout dans Chromium avec un faux `claude` dans le PATH (suites), puis avec le vrai `claude` (recette par juges, captures) ; toutes les suites du cockpit vertes sous macOS et Linux.

### Git dans le cockpit (Phase 78 — posées au cadrage, 2026-11-05)
> Dérivent de P78-D-01..26 (`78-CONTEXT.md` ; arbitrages Samuel, AskUserQuestion session principale Claude Code, 2026-11-05, relayés au manager , second tour pour P78-D-10 ; décisions techniques du manager sur mesures). Famille neuve `GITC` (vérifiée libre le 2026-11-05 sur `origin/main`, `feat/phase-72-lancer-depuis-cartes` et `docs/jalon-v2-phases-73-77`). Jalon `vibeflow-v2.0`. Chaque exigence porte son témoin rouge, joué avant le code.

- [x] **GITC-01**: En-tête : sur Code, Projet et Équipe, le titre à droite du logo est le nom du dossier du dépôt principal, identique sur les trois onglets, y compris depuis un worktree ; les suffixes « — Projet » et « — Équipe » disparaissent (P78-D-01, P78-D-09).
- [x] **GITC-02**: Seconde ligne de l'en-tête : branche courante, et worktree seulement hors de l'arbre principal, en petit sous le nom ; branche détachée lisible comme telle ; noms longs tronqués avec le nom complet au survol (P78-D-02, P78-D-19).
- [x] **GITC-03**: Bloc de vue à la racine : surtitre = nom de l'onglet, titre = ce que montre la vue (jalon en cours, dépôt et branche, mission en cours), sous-titre court ; plus aucune répétition du nom du projet ; sous-vues inchangées (P78-D-03).
- [x] **GITC-04**: Tiroir Git vertical à gauche, sans 4ᵉ onglet, ouvert selon P78-D-10 ; il coexiste avec le tiroir Terminal et les boutons du bas à gauche sans chevauchement, et tient en largeur mobile (P78-D-04, P78-D-10, P78-D-19).
- [x] **GITC-05**: Dégradation : Git absent du PATH ou lab hors dépôt : seconde ligne et ouvreur absents, aucune erreur dans le chrome, le reste du cockpit identique ; une commande git en échec ou hors borne rend « indisponible » dans le tiroir seulement (P78-D-11).
- [x] **GITC-06**: Graphe façon gitgraph : branches locales, worktrees et branches distantes déjà présentes sur le disque, N derniers commits bornés, branches mergées repliées, placement en couloirs déterministe ; aucun `fetch` ni lecture réseau (P78-D-05).
- [x] **GITC-07**: Détail d'un commit : auteur, date, message complet, fichiers touchés avec +/− (binaires et renommages compris), sans diff ; SHA validé par motif strict puis `rev-parse --verify` (P78-D-06, P78-D-13).
- [x] **GITC-08**: État de chaque worktree (modifiés, non suivis, avance et retard sur la base), tags, liste des stash, auteurs et activité récente par branche (P78-D-06).
- [x] **GITC-09**: Lecture seule : routes neuves en GET seul sous `/api/vf/`, derrière Host, Origin et jeton ; aucune écriture dans le dépôt ni dans `.git` ; programmes externes de git neutralisés ; sorties bornées (P78-D-07, P78-D-13).
- [x] **GITC-10**: Commandes à copier : construites par une fonction unique, refs et chemins cités pour le shell ; un nom de branche hostile ne produit jamais une commande différente de celle affichée ; copie par le presse-papiers de la page seule ; texte venu de git rendu en `textContent` (P78-D-14).
- [x] **GITC-11**: Rafraîchissement par le flux existant sur une signature bon marché (HEAD et refs des worktrees), sans relancer `git log` à chaque tick ; aucune variable CSS ni valeur d'espacement en dur, aucune valeur de padding existante modifiée (P78-D-12, P78-D-15).
- [x] **GITC-12**: Retrait et non-régression : liste « Repositories » de l'onglet Code retirée ; toutes les suites du cockpit vertes ; chaîne XSS étendue aux données git (nom de branche, message de commit, auteur hostiles) ; bump du module au-dessus de `main` (P78-D-09, P78-D-17, P78-D-18).
- [x] **GITC-13**: Lectures git existantes durcies : `vf-cockpit-who.mjs`, `vf-cockpit-arbres.mjs`, `vf-cockpit-planning.mjs`, `vf-cockpit-paths.mjs` et le moteur passent par un environnement git unique (variables `GIT_*` héritées retirées, filtres du dépôt neutralisés) ; témoin : dépôt piégé (`filter.<x>.process`, `GIT_DIR` hérité) qui déclenche sans la parade et plus avec (P78-D-25).
- [x] **GITC-14**: Attribution worktree des sous-agents : l'onglet Équipe montre le dernier worktree cité sur l'ensemble des appels de l'agent, pas le `cwd` de la session parente ; témoin : transcript dont le dernier appel ne cite aucun chemin (P78-D-26).

### Gouvernance au cockpit — la régie (Phase 73 — posées au cadrage, 2026-11-11)
> Dérivent de P73-D-01..36 (`73-CONTEXT.md` ; décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée, sur la direction « régie » retenue par Samuel le 2026-11-11, registre § 5.1). Famille neuve `REGI` (vérifiée libre le 2026-11-11 dans tous les ledgers `.planning/workstreams/*/REQUIREMENTS.md`, le dépôt et les branches des Phases 7x/8x, d'intégration et `main`). Jalon `vibeflow-v2.0`. Chaque exigence porte son témoin rouge, joué avant le code.

- [ ] **REGI-01**: Régie : l'onglet Équipe montre quatre sections dans l'ordre « À vous », « Au travail », « Terminé, à relire », « Au repos » ; un agent qui attend figure dans « À vous » et à sa place dans l'arbre ; compteurs de section = lignes, sous-titre = agents distincts en vie ; état vide dit, jamais une section masquée (P73-D-01).
- [ ] **REGI-02**: Rendu côté page depuis `who@2` et le flux `lock`, par une fonction indépendante de la source ; un adaptateur unique lit `window.VF_ETAT` s'il existe, sinon l'événement `vf-who` ; témoin : la même entrée rend le même DOM par les deux sources (P73-D-02).
- [ ] **REGI-03**: Retrait du canevas d'Équipe : plus aucune carte, plus de rechargement de page quand l'ensemble des agents change ; l'enveloppe garde `vibeflow/cockpit-equipe@1` avec `nodes` vide et sa `meta` (en-tête et parité R4.1 inchangés) ; aucun fichier du moteur vendorisé modifié (P73-D-03, P73-D-24).
- [ ] **REGI-04**: « À vous » : sessions à l'état officiel « vous attend » et phases dont un `*-VERIFICATION.md` porte `status: human_needed` (en-tête seul, ligne de niveau phase reliée à sa carte dans Projet) ; ainsi que les questions en attente des cadrages (REGI-17) ; rien d'autre n'y entre (P73-D-06, P73-D-37).
- [ ] **REGI-05**: Classement par impact : aval = nœuds non terminés en aval du nœud rattaché dans un plan de mission publié (résumé à côté du verrou, champ `dag`, Phase 79) ou déjà découvert, jamais deviné ; trois rangs (connu > 0, inconnu, connu = 0), la plus ancienne attente d'abord ; libellés « retient N nœuds », « retient toute la mission · N nœuds », « impact inconnu » (P73-D-07).
- [ ] **REGI-06**: Tenant du verrou par mission sur la ligne de mission, verrou de dépôt en en-tête ; la page n'utilise qu'une liste blanche de champs du flux `lock` ; témoin : chemin absolu et identifiant de session sentinelles absents du DOM, du stockage et de l'export (P73-D-08).
- [ ] **REGI-07**: Alerte du watchdog : « verrou abandonné » depuis `stale`, « sans progrès depuis N min » au-delà de la fenêtre de stall lue à une seule source (environnement, sinon ligne par défaut du script) ; extraction impossible = rien marqué ; témoin de mutation de la ligne source (P73-D-09).
- [ ] **REGI-08**: Arbres de travail : bloc replié en pied de régie, joint par chemin depuis `GET /api/vf/git` et `GET /api/vf/git/worktrees`, relu sur l'événement `git` ; aucun appel git neuf ; pastilles neutres (P73-D-10).
- [ ] **REGI-09**: Vivacité : « au travail » → « silencieux » (> 120 s) → « suspect » (> fenêtre de stall) ; commande en cours « au travail » jusqu'à 15 min ; orphelin sous la ligne grisée de son parent, mot neutre, sans action ; `sortisSilence` dit en pied de section quand non nul ; glyphes du lot 0 inchangés, aucune couleur d'alerte (P73-D-11, P73-D-13, P73-D-19).
- [ ] **REGI-10**: « Attend ses agents (N) » : champ facultatif `attendAgents` de `who@2`, lu sur la dernière ligne `turn_duration` (absent = 0), sessions seules, ni `actif` ni écrasé par une écriture plus récente (P73-D-12).
- [ ] **REGI-11**: « Terminé, à relire » : « lu » = transcript ouvert dans ce navigateur, `localStorage` par lab (identifiants et heure), purge à 24 h, jamais exporté ; « Tout marquer comme relu » ; « échec » ou « arrêté » écrit sur la ligne selon `finMotif` ; le tiroir « Au travail » n'est plus ouvert sur Équipe et son pli des terminés devient « N à relire dans Équipe » (P73-D-14, P73-D-15).
- [ ] **REGI-12**: Titre « (N) vous attendent » et pastille de favicon neutre, par un compositeur unique du titre ; témoin : le préfixe survit à un événement `git` et à la traduction ; seul motif « vous attend » ; jamais de focus volé (P73-D-15).
- [ ] **REGI-13**: « Ailleurs sur ce poste » : nombre et nom du lab des sessions « vous attend » hors des arbres du lab, depuis la liste officielle ; `cwd` ne sort jamais du module ; « un autre dossier » pour le dossier personnel ou un chemin court ; le nom d'un autre lab ne vit que dans la page servie, par sa propre route `GET /api/vf/ailleurs` (jamais dans l'export, un fichier du lab, `who@2`, l'état ni le flux de `vf-signal`) ; témoin de non-fuite à sentinelles précédé de son témoin positif, mutants qui laissent passer `cwd` ou versent la liste dans `who@2` (P73-D-16, P73-D-28).
- [ ] **REGI-14**: Un seul style de bouton pour les actions de la régie, seule action « Lire le rapport » ; nom d'un agent écrit une fois par ligne ; section Santé ni calculée ni injectée sur Équipe (P73-D-17, P73-D-18).
- [ ] **REGI-15**: Accroches de la Phase 74 : `section#vf-equipe`, registre `window.__vfEquipeVues`, bascule dessinée dès deux vues, événements `vf-agent:ouvrir` (annulable, repli sur le lecteur actuel) et `vf-agent:lu`, attributs `data-vf-agent` / `data-vf-noeud` / `data-vf-etat` ; ancres `#r=n:se-<id>` / `n:ag-<id>` traitées par la régie (P73-D-20).
- [ ] **REGI-16**: Non-régression : témoins du canevas re-pointés (LE.* → LR.* pour la ligne « Lancée depuis la carte », champ `lancee`), nettoyage de la branche à l'émission, export d'Équipe sans contenu de régie, recherche par lignes ; une suite neuve au plus et compteur des README recompté ; toutes les suites du cockpit vertes sous macOS et Linux (P73-D-04, P73-D-05, P73-D-21, P73-D-22, P73-D-25).
- [ ] **REGI-17**: Questions en attente des cadrages, troisième source de « À vous » : les entrées `etat` = `en-attente` de `meta.vf.questions` (contrat C76-Q2 de la Phase 76), chacune reliée à sa phase et à ce qu'elle bloque, classées par la règle de P73-D-07 ; les entrées `appliquee` (options appliquées sous délégation, contestables) en liste repliée à part, « Décisions prises pour vous, contestables (N) », jamais comptées dans le titre ni la pastille ; le bilan des autres états dit en une ligne (« N questions écrites dans un autre format, non lues ») ; jamais une entrée `mal-formee` ou `a-verifier` montrée comme une question qui attend ; champ absent (lecture de la 76 pas encore livrée) → l'emplacement le dit ; prouvé sur une fixture à la forme du contrat (P73-D-37, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11).

### L'équipe dans le temps — frise, fiche d'agent, coût, relecture (Phase 74 — posées au cadrage, 2026-11-11)

Dérivées de P74-D-01 à P74-D-56 (`74-CONTEXT.md`), décisions déléguées par Samuel (message session principale,
2026-11-08), option recommandée, sauf P74-D-46 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 :
la couleur dit l'état, le nœud s'écrit sur la voie). Préfixe `TEMP` vérifié libre le 2026-11-11. Dépendent des
contrats de la Phase 79 (figés au commit `3119d82a`, revalidés à la reprise du 2026-11-11), de la régie de la Phase 73 et de
la Phase 80.

- [ ] **TEMP-01**: Frise des sessions dans l'onglet Équipe, derrière une bascule « Régie · Frise » (régie par défaut, aucun quatrième onglet) : une voie par agent, l'enfant sous son parent avec un trait au dispatch, horloge commune au lab, fenêtres 1 h 30 (défaut), 6 h et 24 h, jamais au-delà ; une session vivante sans activité reste listée au repos ; une mission commencée avant la fenêtre le dit ; la bascule est dessinée par la régie de la Phase 73, la frise s'y déclare comme vue (P74-D-02, D-05, D-08, D-51 ; AUDC-I05, AUDC-Q2).
- [ ] **TEMP-02**: Segments et événements lisibles sans la couleur : au travail (barre pleine), vous attend (hachures sans contour coloré), attend ses agents (trait fin), au repos (pointillé) ; compaction, erreur d'outil, message humain, rapport rendu posés sur la voie ; commits sur un bandeau « Dépôt » par branche, jamais attribués à un agent, un clic ouvre le tiroir Git sur le commit ; trois teintes d'état seulement, le nœud du plan écrit sur la voie, jamais une couleur par nœud (P74-D-01, D-06, D-07 ; DESIGN.md § 9).
- [ ] **TEMP-03**: Deux lectures du même axe : Horloge (défaut, durées vraies) et Événements (silences de plus de 2 min compressés en un repère qui dit leur durée) ; l'axe dit la lecture en cours (P74-D-09).
- [ ] **TEMP-04**: Échelle : au-delà d'un seuil de voies, les workers se replient sous leur manager avec leur compte écrit (« + N agents », dépliable) ; bandeau haut avec la courbe du nombre d'agents au travail ; la frise suit le flux partagé de la Phase 79 sans qu'aucune donnée de frise ne passe dans le flux (P74-D-10, D-11).
- [ ] **TEMP-05**: Relecture au curseur : curseur au pointeur et aux flèches ; l'encart « À cet instant » dit l'état de chaque voie, les nœuds du plan portés, avec l'état de la voie qui les porte (dérivés des voies, jamais un statut de DAG inventé), et les fichiers écrits autour de l'instant (premier filtre sur la dernière écriture de chaque cible, fil réduit lu pour le seul cas incertain, voies non lues dites, P74-D-49) ; « Voir sur la carte » ouvre l'onglet Code avec ces fichiers mis en évidence (P74-D-12, D-13, D-14 ; AUDC-I06).
- [ ] **TEMP-06**: Fiche d'un agent en plein cadre dans l'onglet Équipe, ouverte depuis une voie de la frise et depuis une ligne de la régie : faits à gauche, fil à droite, une colonne au téléphone ; Échap ou « Retour » la ferme et rend le focus ; même fiche pour une session et un sous-agent, sans intertitre « Mandat » pour une session (P74-D-03, D-04 ; AUDC-I04, AUDC-M4).
- [ ] **TEMP-07**: Faits de la fiche : rattachement « Worker de <parent> · nœud <id> · Phase <n> » dont chaque terme ouvre sa cible (trois graphes reliés) ; durée au travail par segments dont temps à attendre l'humain ; contexte au dernier tour en jetons (pourcentage seulement sur une taille de fenêtre documentée) et compactions ; appels d'outil dont erreurs ; jetons par catégorie ; fichiers écrits et lus ; toute donnée absente s'écrit « inconnu », jamais zéro (P74-D-15, D-16, D-26 ; AUDC-I21, AUDC-D9).
- [ ] **TEMP-08**: Lecteur (reste de AUDC-D8) : un fil daté du mandat à maintenant, filtres messages, outils et erreurs, suivi en direct avec « Revenir au direct », coupe dite, mandat replié lu à la demande ; markdown des messages rendu en texte par un sous-ensemble fermé construit en nœuds DOM (jamais `innerHTML` d'une chaîne du transcript), liens non cliquables ; une erreur dit « échec » sans son texte, compactions et messages de l'humain marqués sans texte (P74-D-48 : « échec » posé par le réducteur, compactions et messages de l'humain fusionnés côté page depuis les événements de la voie) ; jamais une sortie d'outil ni l'argument d'une commande (P74-D-17, D-18, D-19 ; P69-D-16, P69-D-19 ; AUDC-I28, PU-G-168).
- [ ] **TEMP-09**: Coût en jetons et en durée, par agent, par mission, par phase et par étage (tête, manager, worker), chaque agrégat portant sa fenêtre ; les agents non rattachés comptés à part en « hors mission » ; temps d'agent perdu à attendre l'humain ; aucun montant en devise ni limite d'abonnement (P74-D-20, D-21, D-23, D-24 ; AUDC-I07, AUDC-I08).
- [ ] **TEMP-10**: Un seul calcul de jetons : la somme de `message.usage` dédoublonnée par identifiant de message, posée dans l'index de la Phase 79 ; la 74 l'agrège sans jamais recompter un transcript ; aucun champ affiché qui ne soit déclaré au contrat de forme ; témoin : transcript dont un message tient sur plusieurs lignes, compté une fois (P74-D-22, D-25).
- [ ] **TEMP-11**: Bornes : routes en GET seul derrière Host, Origin et jeton ; clés `doing`, `mandat`, `messages`, `outils`, `fil` refusées dans le flux ; ni frise, ni fiche, ni fil dans l'export ; aucune lecture réseau ; la dernière commande nulle part ; chaîne XSS étendue aux données de frise et de fiche (nom d'agent, nœud, titre, message hostiles) (P74-D-27 ; P67-D-02, P67-D-14, P69-D-23).
- [ ] **TEMP-12**: Forme et retrait : clavier complet (voies, curseur, filtres ; la bascule est celle de la régie), alternative textuelle de la frise pour lecteur d'écran, focus visible, mouvement réduit, deux thèmes, grille d'espacements fermée, aucune valeur en dur, interface en français ; retirés : la boîte de transcript du panneau et son bouton « Lire le transcript », la durée qui compte les veilles, la carte « Terminés depuis moins de 24 h » du canevas si elle existe encore, et le lecteur de repli de la régie avec l'export `transcript` (74-10, P73-C2) ; suites du cockpit vertes ; aucun bump propre, un seul pour la vague à la jointure (P74-D-28, D-43, D-51, D-53 ; P71.5-D-01, Q11).

### L'activité posée sur le code (Phase 75 — posées au cadrage, 2026-11-11)

> Dérivent de P75-D-01..21 (`75-CONTEXT.md` ; décisions déléguées par Samuel, message session principale, 2026-11-08, option recommandée, sur panels de recherche ; aucune ne vaut arbitrage humain). Famille neuve `ACTV`, vérifiée libre le 2026-11-11 sur tous les ledgers `.planning/workstreams/*/REQUIREMENTS.md`. Contrats de la Phase 79 consommés : `feat/phase-79-socle-cockpit`, `3119d82a`, C0 à C6.

- [ ] **ACTV-01**: Lentilles exclusives (Aucune, Points chauds, Couplage, Gardes, Empreinte) choisies dans le menu qui portait « Travail récent », à la même place et avec sa pastille de compte ; aucun bouton d'en-tête ni 4ᵉ onglet, rien ne pousse la carte ; témoin : géométrie de chaque carte identique avant et après bascule de lentille et après une mise à jour en direct, aucune relance du placement (P75-D-02, D-03, P70-D-01, P78-D-04).
- [ ] **ACTV-02**: Forme des marques : glyphe à trois paliers en teinte neutre + mot chiffré dans l'emplacement droit du pied ; teinte « en cours » réservée au fichier en cours d'écriture ; ni fond, liseré, anneau, halo ni dégradé ; contraste ≥ 3:1 dans les deux thèmes ; la marque se lit sans couleur et son mot entre dans le nom accessible de la carte ; carte de nœud = palier maximal + compte (P75-D-01, D-04, D-06, Q9, P71.5-D-19, D-21, D-28).
- [ ] **ACTV-03**: Canal de marquage unique de la page (couche nommée, table id → palier, glyphe, mot, infobulle ; agrégat aux ancêtres ; une couche active) sous un espace de noms à part (l'objet global du moteur est gelé, Phase 80), initialisé par `VF_COQUILLE.surOnglet` (A30 de la 79), partagé avec la relecture de la Phase 74 (AUDC-I06) ; témoin : deux couches posées successivement, seule la dernière est visible et la première revient à son retrait (P75-D-05).
- [ ] **ACTV-04**: Données git calculées par une tâche asynchrone sur la signature de HEAD et des refs, mono-vol, cache en mémoire, via `envGit` et `lancerGitAsync` ; route GET bornée sous `/api/vf/` derrière les contrôles C0 et `porteInterdit`, schéma `vibeflow/cockpit-activite@1` déclaré ; rien écrit dans le lab ; aucun `fetch` ; une requête pendant le calcul répond ; témoin : HEAD inchangé → aucun `git log` relancé (P75-D-09, P78-D-15, AUDC-A-04).
- [ ] **ACTV-05**: Points chauds : commits hors merges des 90 derniers jours plafonnés à 5 000, × `loc`, en rang et trois paliers par quantiles ; renommages suivis (`-M`) ; plafond mordu et clone superficiel écrits sur la lentille ; témoins sur un dépôt fixture : plafond, fenêtre, renommage, merge exclu (P75-D-07).
- [ ] **ACTV-06**: Couplage : seuils ≥ 5 révisions communes, ≥ 5 par fichier, degré ≥ 30 %, commits de 30 fichiers au plus, liste fixe de bruit ; montré à la sélection d'une carte seulement (5 voisins au plus avec leur %) et dans une section « Change souvent avec » du panneau ; aucun lien ajouté au graphe ; mutants sur chaque seuil (P75-D-08).
- [ ] **ACTV-07**: Gardes : un fichier est gardé quand une suite découverte ou un gate appelé par `ci.yml` nomme son chemin (ou son nom non ambigu), sans la part « module » ; glyphe « est une garde » ; zone sans témoin dite « aucune suite ne le nomme » ; rien du lab exécuté ; sur un lab non VibeFlow la lentille est absente et le dit ; suite d'équivalence contre `scripts/ci-suites-perimetre.sh` sur des diffs témoins (P75-D-16, D-17, P68-D-34).
- [ ] **ACTV-08**: Empreinte en direct depuis `cibles` des voies de la frise (C3), en mémoire seulement : « en cours » / « modifié » / « lu » / « fini » d'après l'état officiel ; nom = rôle, nœud, arbre, jamais l'identifiant brut ; « empreinte en cours de relecture » tant que `cibles.etat` vaut `en-construction` ; « écritures par commande non vues » dit ; jamais d'argument, de sortie d'outil ni d'export ; agrégat « agent par zone » sur les nœuds (P75-D-12, D-13, AUDC-I13, I36, AUDC-Q2, Q4).
- [ ] **ACTV-09**: Normalisation des chemins : cible ramenée à `{arbre, chemin dans l'arbre}` (A45 de la 79 : `arbre` = `null` ou nom d'un worktree prouvé du dépôt, qui compte comme le lab, P75-D-29, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11), seul un chemin qui a une carte est dessiné, le reste compté (« hors carte », « hors du lab » pour un dossier qui n'est pas un worktree prouvé) ; preuve générative sur les formes de chemin (lien symbolique, `..`, worktree hors du lab, Unicode, U+2028) (P75-D-14, AUDC-A-02).
- [ ] **ACTV-10**: Radar de collisions : même fichier écrit par deux agents (arbres différents tant que les deux existent ; même arbre si vivants ensemble et non parent-enfant), modifié sur deux branches (merge-base par paire de HEAD distincts, ≤ 12 HEAD, plafond écrit), ou prévu par deux plans d'une même vague ; lectures exclues ; glyphe neutre distinct + mot + noms au panneau + compte visible sans lentille ; jamais `git status` périodique ni `git diff` contre l'arbre de travail ; « radar incomplet » pendant la reconstruction (P75-D-10, D-15, AUDC-I12, P78-D-21).
- [ ] **ACTV-11**: Cartes « prévues » : fichiers des `files_modified` des plans non faits absents du scan, injectés après la construction du graphe avec le statut `prévu`, rattachés par les globs ou « non assignés », non comptés par Santé, sans « ouvrir » ni « taille » ; chemin hors du lab ou malformé ignoré et compté (P75-D-18, AUDC-I36).
- [ ] **ACTV-12**: Retrait et non-régression : couche « Travail récent » (`recent-work.json`, `ui/25-recent.js`, classes `.recent`, bascule) et `scripts/recent.mjs` retirés dans le même lot que la mise en service de l'empreinte (P75-D-28, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 ; P70-D-01 amendée dans cette mesure) ; jeton `--recent` gardé ; suites qui la citent adaptées, jamais supprimées ; toutes les suites du cockpit vertes sous macOS et Linux ; chaîne XSS étendue (chemin, branche, rôle, titre hostiles) ; dégradation sans git identique (P78-D-11) ; `DESIGN.md` § 2 (graphe de code) et CHANGELOG du module à jour ; relecture SOBR-04 (P75-D-11, D-20, D-21).

### Traçabilité au cockpit (Phase 76 — posées au cadrage, 2026-11-11)
> Dérivent de P76-D-01..37 (`76-CONTEXT.md` ; décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée, sauf P76-D-32 à P76-D-34 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-11). Famille neuve `TRAC` (vérifiée libre le 2026-11-11 dans tous les ledgers et dans tout le dépôt). Jalon `vibeflow-v2.0`. Chaque exigence porte son témoin rouge, joué avant le code ; lecture seule, aucun réseau, rien dans l'export.

- [x] **TRAC-01**: Section « Traçabilité » du panneau d'une phase : une ligne par exigence rattachée (table de traçabilité du ledger, à défaut `requirements:` d'un PLAN), une bande de quatre maillons lus (plan, SUMMARY, VERIFICATION, recette), chacun avec son niveau (exigence ou phase), et le premier trou dit en un mot ; absence simple en glyphe et mot neutres (P76-D-04, P76-D-13, P76-D-14).
- [x] **TRAC-02**: Contradictions du ledger montrées, jamais corrigées : case cochée sans SUMMARY lu et statut « Complete » sans plan lu en glyphe à trait corail et mot ; case non cochée avec SUMMARY lu, exigence sans ligne de traçabilité et ligne sans exigence en mot neutre ; jamais de fond teinté ni de texte coloré (P76-D-04, P76-D-15, P76-D-15bis).
- [x] **TRAC-03**: Vue d'ensemble « Jalon » : une ligne par phase du jalon actif avec le nombre de trous par maillon ; la ligne ouvre le panneau de la phase (P76-D-02, P76-D-05).
- [x] **TRAC-04**: Preuves de vérification attachées à la phase et à ses plans (AUDC-I33) : fichiers VERIFICATION (et `status:`), recette (et statut), RED-TRACE, SECURITY, VALIDATION, en liens vers leurs chemins relatifs, et critères `must_haves` des PLAN quand ils existent ; jamais un contenu de transcript ni une preuve déduite (P76-D-24).
- [x] **TRAC-05**: Décisions : ADR de `docs/ADR.md` et définitions des registres `*-CONTEXT.md` des dossiers de phase (préfixées, ou nues qualifiées par la phase de leur registre) ; section « Décisions » de la vue d'ensemble agrégée par ADR puis par registre ; panneau d'une ADR ou d'une décision avec ses voisins lus (phase, ADR citées, décisions et commits qui la citent) (P76-D-16, P76-D-17).
- [x] **TRAC-06**: Commits citants : un passage `git log` borné (référence résolue en sha, `--max-count=2000`, point git durci, asynchrone), corps des messages lu pour extraire les identifiants puis jeté ; on sert sha court, jour et sujet ; une décision nue n'est reliée à aucun commit ; borne atteinte ou délai dépassé : `tronque` ; un commit s'ouvre dans le tiroir Git (P76-D-03, P76-D-10).
- [x] **TRAC-07**: Mémoire des agents, périmètre et champs : seuls les fichiers suivis sous `.claude/agent-memory/`, lus par le point confiné ; montrés : `name`, agent, `metadata.type`, jour du dernier commit, nombre de liens entrants et sortants ; jamais `description`, corps, `~/` ni chemin absolu ; `.claude/` non suivi : état vide qui le dit avec un nombre, sans noms (P76-D-19, P76-D-20).
- [x] **TRAC-08**: Mémoire des agents, liens et états : extraction hors code et hors classes POSIX, résolution par `name:` puis par nom de fichier (état propre, compté), « cassé » sinon ; états distincts « hors index » (égalité exacte), « sans lien entrant » (filtre neutre) et « cite un chemin absent » (relatif au dépôt, absent de HEAD, présent dans l'historique lu) ; aucun verdict « périmée » tiré d'une date (P76-D-21, P76-D-22, P76-D-23).
- [x] **TRAC-09**: Navigation de proche en proche : chaque objet a un panneau qui liste ses voisins lus, ouverts d'un geste ; Retour par la pile commune de la Phase 80 (sans fil d'Ariane propre), ancre par objet ; clavier complet (focus natif, Échap) ; au plus 30 voisins d'une sorte puis « + N autres » ; aucun canevas, aucun quatrième onglet, aucune modification de `viewer.html` (P76-D-01, P76-D-02, P76-D-03, P76-D-05).
- [x] **TRAC-10**: Route `GET /api/vf/tracabilite` à la demande, schéma `vibeflow/cockpit-trace@1` déclaré au contrat de forme et au README (champs et `interdits`), règles C0 de la Phase 79 (hôte, `Origin`, jeton en temps constant, GET seul, `no-store`, garde `porteInterdit` sur la réponse, 503 si elle se déclenche), paramètres validés (400 sinon), cache par empreinte, un calcul en vol ; le planning lu dans l'instantané de la collecte (manques ajoutés en champs facultatifs de `cockpit-project@1`), ADR, commits et mémoire par lecture confinée bornée (P76-D-06 à P76-D-09, P76-D-31).
- [x] **TRAC-11**: Confidentialité et dégradation : aucune donnée de la phase dans l'export ni dans une page autonome ; aucun chemin absolu ni `~/` dans une réponse ; tout texte venu des fichiers rendu en `textContent` ; lab sans `docs/ADR.md`, sans compartiment, sans mémoire, sans git ou à traçabilité « Étape N » : une ligne neutre qui le dit, rien ne casse ailleurs (P76-D-11, P76-D-12).
- [x] **TRAC-12**: Un ajout, un retrait et non-régression : le nœud enfant « Exigences » et ses cartes d'exigence quittent le graphe Projet (le compte « x/y exigences » du pied reste) ; ligne au `CHANGELOG.md` du module ; toutes les suites du cockpit vertes sous macOS et Linux, compteur de suites des README à jour (P76-D-25, P76-D-27, P76-D-29).
- [x] **TRAC-13**: Questions en attente : la lecture du planning lit les entrées au format C76-Q1 des sections « À Samuel » des registres de phase et pose le champ facultatif `meta.vf.questions` de `cockpit-project@1` (C76-Q2) ; une entrée hors grammaire est « mal formée » avec son défaut, jamais « en attente » ; une question n'est « tranchée » ou « appliquée » (option recommandée appliquée sous délégation, contestable) que par sa ligne `État` canonique ; identifiant en double, phase incohérente, citation incohérente, fichier absent et section vide ont chacun leur témoin rouge ; la régie de la Phase 73 consomme la liste, « en attente » dans « À vous », « appliquée » à part (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 ; P76-D-34 à P76-D-37).

### Santé de la méthode et synthèse (Phase 77 — posées au cadrage, 2026-11-11)
> Dérivent de P77-D-01..18 (`77-CONTEXT.md` ; décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée ; aucun arbitrage neuf). Famille neuve `SYNT`, vérifiée libre le 2026-11-11 sur `f763b556` (`.planning/` entier, ledgers de compartiment et archives compris). Jalon `vibeflow-v2.0`. Chaque exigence porte son témoin rouge, joué avant le code.

- [x] **SYNT-01**: Synthèse sur Projet : un bouton d'en-tête « Synthèse » ouvre dans le panneau en place trois blocs (depuis votre dernière visite, burn-up, santé de la méthode), plus une ligne-résumé neutre en section d'ensemble ; aucun 4ᵉ onglet, `ui/00-vibeflow.js` et `ui/20-health.js` non modifiés, carte jamais poussée ; ni couleur d'alerte ni fond teinté, glyphe et mot, grille d'espacements fermée ; libellés français au point d'émission (P77-D-01, P77-D-02).
- [x] **SYNT-02**: Sortie machine des gates : `check-method-budget.sh` et `check-instruction-budget.sh` acceptent `--format=tsv` en lecture seule (en-tête versionné, une ligne par mesure déjà calculée, chemins relatifs à la racine, budgets effectifs) ; `--auto`/`--archive` refusés (64) ; pas de réseau ni de passe de rangement ; sans l'option, la sortie texte est identique octet pour octet ; trailer `Gate-Touche:` (P77-D-03).
- [x] **SYNT-03**: Route des jauges : `GET /api/vf/methode` à la demande, jamais dans la collecte ; cache court, un seul appel en cours, lancement asynchrone borné (le serveur répond pendant qu'un gate tourne) ; script résolu comme `driverLockScript`, jamais pris dans le lab observé ni dans `.vibeflow/` ; règles d'accès C0 de la Phase 79 ; aucun chemin du poste dans la réponse ; `.planning/` inchangé après l'appel (P77-D-04).
- [x] **SYNT-04**: Jauges : chaque budget mesuré par les deux gates (STATE, paragraphe de STATE, BACKLOG, ROADMAP, index MEMORY, worktrees, agents 251/300, skills 500, socle de démarrage et sa baseline) montre valeur, budget, unité et verdict en mot ; « non applicable dans ce lab » pour le gate de densité hors dépôt de distribution, « indisponible » pour un gate absent, ancien (64), de version inconnue ou hors délai — jamais 0 (P77-D-05, P77-D-06).
- [x] **SYNT-05**: Mémoire de la dernière visite : stockage local du navigateur, clé `vibeflow-cockpit:derniere-visite:<lab>` (jamais la clé de la visite guidée, jamais une clé par origine) ; objet `v:1` sur liste fermée (`vu`, `phases`, `tete`, `blocages` en condensats), 8 Ko au plus, sans titre, sujet, identifiant de session, commande, chemin ni texte ; valeur invalide → « première visite sur ce poste » (P77-D-07, P77-D-08).
- [x] **SYNT-06**: Avance du repère : deux instantanés ; rotation au chargement après 30 min d'absence seulement ; réécriture au passage en arrière-plan, fusion où le repère le plus récent gagne ; geste « Tout vu » propagé aux autres onglets ; effacement et limites dits dans la documentation du module (P77-D-09).
- [x] **SYNT-07**: Contenu de la synthèse : phases dont l'état a changé ; commits non-ancêtres du sommet mémorisé (jamais un filtre sur la date ; « plus de 500 » hors fenêtre) ; sessions finies depuis la visite, « au moins N » avec la réserve des 24 h quand la visite est plus ancienne ; blocages (nœud échoué, agent qui attend, section des blocages du STATE lue en lecture seule et nettoyée), nouveaux nommés, levés comptés ; différence calculée par un module pur testé sous node (P77-D-10, P77-D-11).
- [x] **SYNT-08**: Burn-up : dates de clôture et d'inscription lues dans la checklist du ROADMAP (`complete`, `completed`, `close`, `inscrite`), jamais la date d'un commit ; courbe SVG en escalier à deux séries neutres avec équivalent texte, liste datée au téléphone ; « N sur M · P % » produit par la fonction du pied de jalon (CKPT-16) ; phase close sans date nommée sous le graphe, jamais estimée ; champ facultatif `meta.vf.burnup` (P77-D-13, P77-D-14).
- [x] **SYNT-09**: Retrait : `lastDesc` n'est plus produit, la prose recopiée du STATE disparaît sous « Maintenant » ; témoin : l'assemblage de Projet ne porte plus le texte de `last_activity_desc` (P77-D-12).
- [x] **SYNT-10**: Coût par phase et par étage sur les dernières 24 h : jetons (entrée, sortie, cache lu et créé) et durée de travail par phase (via le DAG de la mission) et par étage (rôle), « non rattaché » pour une voie sans mission, jamais de monnaie ; source `GET /api/vf/frise` (C3 de la Phase 79) ; plan dépendant de la Phase 79 (et de l'agrégat de la Phase 74 s'il existe), à revalider quand elles auront livré (P77-D-15, P77-D-16).

### Socle du cockpit (Phase 79 — posées au cadrage, 2026-11-11)
> Dérivent de `79-CONTEXT.md` (contrats C0 à C6, amendements A1 à A55, décisions P79-D-01 à P79-D-33 (P79-D-33 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 ; les autres : décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée) ; arbitrages en vigueur AUDC-Q2, Q4, Q5 du 2026-11-11). Famille `SOCL`, réservée au ROADMAP pour la Phase 79. Jalon `vibeflow-v2.0`. Chaque exigence porte son témoin, rouge sur le code de la base `integration/cockpit-audit` avant le code.

- [x] **SOCL-01**: Fork assumé : `plugin/cockpit/amont/` retiré avec ses contrôles ; `VENDORED.txt` réduit à l'origine, à la sentinelle du moteur et à l'inventaire du plafond ; le contrôle de confinement de l'agent ne saute plus en silence hors de `amont/` (Q11.0) (AUDC-H5, P79-D-07).
- [x] **SOCL-02**: Une aide commune `socle-serveur.sh` lance, attend, interroge et arrête le serveur dans les suites ; toutes les suites qui lançaient `<sortie>/serve.mjs` passent par elle et chaque serveur lancé reste vu par l'hygiène des suites (AUDC-AM7, A6, P79-D-23).
- [x] **SOCL-03**: Le registre des agents d'un verrou survit au relâchement (archive 24 h, plafond de lignes) et un verbe en lecture seule rend le dernier état de chaque agent avec son nœud ; `orphans` et `status` inchangés (AUDC-D5, P79-D-17).
- [x] **SOCL-04**: Le manager qui tient un verrou publie le résumé de son plan de mission (identifiants, dépendances, statuts, compartiment, phase ; jamais de texte libre) à côté du verrou, rendu par `status --all` (A16).
- [x] **SOCL-05**: La doctrine fait écrire le nœud dans chaque mandat sous la forme que lit le cockpit et publier le plan de mission ; aucun corps d'agent n'est modifié (AUDC-I37, P79-D-18).
- [x] **SOCL-06**: Une route GET `/api/vf/*` neuve s'ajoute par une ligne de table et une réponse gardée commune (contrôles C0, garde des clés interdites, `no-store`, 503) ; un annotateur du graphe Code s'inscrit d'une ligne (A10, A11, A27).
- [x] **SOCL-07**: Le serveur est lancé depuis le module avec la sortie en argument ; aucun code ni contrat n'est lu ou évalué depuis la sortie ; un code planté dans la sortie ne s'exécute jamais ; deux labs servis par le même module ne se confondent pas (AUDC-AM4, A-03, P79-D-08, P79-D-09).
- [x] **SOCL-08**: L'empreinte de relance couvre tout le code évalué du module ; `status` et `stop` voient un serveur orphelin sans `server.json` ; la version de Claude Code est lue sans bloquer le démarrage (AUDC-H3, D-M13, AB1, P79-D-10).
- [x] **SOCL-09**: Le confinement de l'agent « Demander » est remesuré avec les chemins du module (`79-MESURE-claude-p.md`) avant tout changement de sa liste ; un verdict non confinable remonte à Samuel (P79-D-09).
- [x] **SOCL-10**: Un chemin n'est jamais jugé autrement que par sa résolution physique complète (échec = dehors), par une fonction unique partagée par le socle et le moteur ; preuve générative avec témoin de couverture ; un lien vers une cible interne protégée est masqué comme sa cible (AUDC-A-02, D-M15, P79-D-11).
- [x] **SOCL-11**: Tout lancement de git par le socle vide tous les pilotes nommés déclarés, quelle que soit la sous-commande ; tout enfant shell qui lance git reçoit l'environnement git unique (AUDC-A-04, P79-D-11).
- [x] **SOCL-12**: Index incrémental des transcripts `cockpit-index@1` (C1) : lecture des seuls octets ajoutés, jetons dédoublonnés par message, segments typés, 24 h, sans cible ni texte, non fiable à la lecture ; contrat de forme étendu et revérifié (AUDC-I20, D9, P79-D-13).
- [x] **SOCL-13**: La collecte tourne hors de la boucle du serveur (p99 d'une requête < 50 ms pendant un tour et un remplissage d'index) ; registre du verrou lu pour le rattachement ; cache du scan ; verrous projetés en liste blanche dans le flux ; `sortisSilence` et `finMotif` (AUDC-H2, A15, A17, A20, P79-D-12).
- [x] **SOCL-14**: Les chaînes du moteur sont traduites au point d'émission ; plus aucun observateur global ne réécrit une donnée du lab ; `?lang=en` rend les libellés sources (AUDC-H4, P79-D-16, P79-D-24).
- [x] **SOCL-15**: Plafond de 160 colonnes en cliquet par fichier ; le code navigateur sérialisé côté serveur est rangé en fichiers, injection toujours conditionnée par `--terminal` (AUDC-AM5, P79-D-19).
- [x] **SOCL-16**: `GET /api/vf/state` (C2) sert l'instantané d'une collecte unique ; `vf-signal` le lit quand un serveur du lab vit et garde son émetteur sinon ; battement `vie` nommé (AUDC-I19, AM1, D-M2).
- [x] **SOCL-17**: `GET /api/vf/frise` (C3) et l'événement `frise` ; `cibles` en mémoire, réduites, sur le chemin réel ; fenêtre de 24 h (AUDC-I20, A21-A24, A28).
- [x] **SOCL-18**: Un seul flux d'événements par navigateur et par lab, partagé entre les onglets, reprise sans rechargement à la fermeture de l'onglet élu ; veille de silence de 45 s (AUDC-H1, I22, D-M2, P79-D-14).
- [x] **SOCL-19**: `GET /api/vf/graphe` (C5) et l'événement `graphe` ; le serveur ne réécrit plus `project.html` ; la page Équipe n'est plus reconstruite par requête (AUDC-AM1, I31, A5, A29).
- [x] **SOCL-20**: Coquille statique servie depuis le module et mise en cache, données en JSON, `chargerOnglet`, terminal posé une fois ; un script planté dans la sortie n'est jamais exécutable par la page (AUDC-AM2, I31, A2, A3).
- [x] **SOCL-21**: Magasin d'état côté page `VF_ETAT` (C4, A13) alimenté par le flux ; les observateurs de réparation des vues abonnées sont retirés, en cliquet (AUDC-AM6, I32).
- [x] **SOCL-22**: La mise en page du canevas tourne dans un worker servi par le module (`worker-src` restreint, jamais `blob:`) ; l'export garde la mise en page en ligne ; l'API du moteur reste la même (AUDC-AM3, M7, A4, P79-D-15).
- [x] **SOCL-23**: Ni l'index, ni l'état, ni la frise, ni les cibles, ni les verrous, ni le plan de mission publié n'entrent dans l'export autonome ; témoin à marqueur avec témoin positif (A25).
- [x] **SOCL-24**: Journal des attentes par hook `command` (I18 réduit, P79-D-22), précédé d'une sonde qui peut le rendre inutile ; jamais de commande, de texte ni de chemin dans le fichier.
- [x] **SOCL-25**: Documentation du module : README (code jamais lu depuis la sortie, limite de la pose projet, CSP, `vf-signal`), CHANGELOG, version mineure ; un ajout, un retrait nommés (P79-D-27).
- [x] **SOCL-26**: La correspondance de motifs du moteur a un coût borné, au point unique, quelle que soit l'entrée fournie par le lab (motif à plusieurs `**`, chemin très long) ; preuve générative de croissance au plus linéaire (constat de la Phase 75, P79-D-32).
- [x] **SOCL-27**: `/api/vf/transcript` et `/api/vf/doing` retrouvent l'agent dans la table en mémoire de la collecte et lisent le fichier sans bloquer la boucle : N requêtes ne déclenchent aucune collecte ; aucun chemin ne sort, y compris sur le chemin d'erreur (AUDC-H2, A48, A50).

### Trois onglets, trois formes (Phase 80 — posées au cadrage, 2026-11-11)
> Dérivent de P80-D-01..60 (`80-CONTEXT.md` ; décisions déléguées par Samuel, message session principale, 2026-11-08, option recommandée, tranchées par panel sur faits établis ; P80-D-52 à P80-D-56 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-11). Famille neuve `FORM`, réservée par le ROADMAP, vérifiée libre le 2026-11-11 (0 occurrence de `FORM-<n>` sous `.planning/` et `plugin/` à `f763b556`).

- [x] **FORM-01**: Canevas au clavier : un seul arrêt de tabulation pour le canevas (Code, et Projet en mode graphe), flèches entre cartes par voisin spatial, Origine/Fin, Entrée plonge et Échap remonte avec le focus rendu à une carte ; `listbox` nommé, cartes `option` avec titre, mot d'état et compte ; arêtes masquées aux lecteurs d'écran ; témoin : 0 carte atteinte aujourd'hui → exactement 1 arrêt et une flèche qui change de carte (AUDC-BL2, P80-D-10).
- [x] **FORM-02**: Surcouches : pile unique, Échap au niveau du document ferme le dessus, modales avec piège à Tab, `inert` derrière et focus rendu à l'ouvreur, non modales sans prise de focus (Q5), terminal exclu d'Échap et son `inert` jamais levé par la pile, panneau fermé non tabulable ; les trois listes recopiées retirées ; témoins : palette ouverte + Tab + Échap → fermée, export + 15 Tab → focus dedans, panneau fermé → 0 élément tabulable (AUDC-M6, P80-D-11).
- [x] **FORM-03**: Zoom centré sur la carte sélectionnée visible, sinon sur la zone libre ; facteurs 1,25/0,8 partout (aller-retour exact) ; garde de saisie unique (`INPUT`, `TEXTAREA`, `SELECT`, `contenteditable`, modificateurs) ; aide `?` générée depuis un registre unique des raccourcis (AUDC-X3, P80-D-12, P80-D-13).
- [x] **FORM-04**: Palette de commandes : la recherche existante étendue par des sources et des actions (vue, bascule couloirs/liste/graphe, Git, aide, changement d'onglet, copier le lien de la vue), préfixe `>` ; aucune action n'envoie rien (Q4) ; entités des autres onglets après la Phase 79 (AUDC-I24, P80-D-14).
- [x] **FORM-05**: Projet en couloirs : à la racine, vue par défaut à toute largeur, un bloc par jalon actif (en-tête, barre neutre, pourcentage strict), quatre colonnes À faire, En cours, À recetter, Fait avec glyphe, mot et compte, carte de phase (numéro, titre, ligne d'état) ; graphe à la demande (bascule et `?vue=`) ; le canevas cesse d'être la vue par défaut de Projet (retrait) ; contrats P80-C76-1 à 4 tenus pour la Phase 76 (AUDC-BL1, AUDC-I23, P80-D-01 à 04).
- [x] **FORM-06**: Données de Projet : champs facultatifs `avancement` et `exigences {faits,total}` sur le nœud phase (même calcul que `piedExigences`), `vague` sur le nœud plan, `recette` ajouté aux statuts du contrat ; `cockpit-project@1` gardé (ajout seul) ; `foot` et `st` inchangés (P80-D-06).
- [x] **FORM-07**: Backlog, Graines et Releases en une liste sous les couloirs, plus de vignettes (retrait) ; le statut du backlog sort du pied de carte, la pastille dit seule l'état (AUDC-X2, P80-D-07).
- [x] **FORM-08**: Vocabulaire du planning : plus de « Élément », « module » ni « Mentions » sur Projet ; le panneau d'un plan dit statut, vague et exigences couvertes ; le texte d'une exigence n'est plus répété trois fois ; pile « Retour » du panneau, qui accepte nœuds et entrées génériques `{titre, rouvrir}` (AUDC-X1, P80-D-08, P80-C76-3, P80-C76-5).
- [x] **FORM-09**: Liste ou tableau : touche `v` et bouton, liste triable (numéro, état, plans, exigences), plans par vague et exigences en liste à cocher dans une phase, liste par défaut au téléphone, choix mémorisé par lab hors de `.planning/` (AUDC-I25, P80-D-05).
- [x] **FORM-10**: Carte du code : minicarte (≥ 1 000 px, souris) et repères de bord « N cartes par là » cliquables à toute largeur ; une seule formule de cadrage exposée et appelée par l'en-tête Git et la visite (retrait des copies) ; plancher 11/13 gardé (PU-G-026) ; `freeArea()` ne déduit pas le tiroir Git (PU-G-204) (AUDC-M1, AUDC-I26, P80-D-15, P80-D-16).
- [x] **FORM-11**: Cadrer la carte sélectionnée et ses voisins du niveau courant, plancher respecté, sans nouvelle mise en page ; le mode focus recomposé reste en réserve (AUDC-I27, P80-D-17).
- [x] **FORM-12**: Ligne d'état jointe à la minicarte (≥ 1 000 px) : branche entière, point du direct, heure de mise à jour ; rien du terminal sans `--terminal` ; au téléphone, zone basse dégagée et cibles tactiles à taille (AUDC-I29, AUDC-X8, P80-D-18).
- [x] **FORM-13**: Tiroir Git : pagination (≤ ~110 rangées au départ), worktrees repliés avec leur compte, détail d'un commit dans un volet bas lisible à 1024 × 768, poignée de largeur au clavier bornée et mémorisée, carte jamais poussée (AUDC-M12, P80-D-19).
- [x] **FORM-14**: Jetons et finitions : contraste mesuré dans les deux thèmes (texte ≥ 4,5:1, non-texte ≥ 3:1, glyphe « En cours » ≥ 3,5:1, cartes estompées ≥ 4,5:1), carte active en clair sans fond teinté, chiffres tabulaires, mêmes teintes de pastilles à toutes largeurs, une taille de bouton d'en-tête, triangles et sélecteurs à la charte ; `DESIGN.md` à jour (AUDC-X5, F1, F3, F4, F5, P80-D-20).
- [x] **FORM-15**: Lien de vue : le fragment porte vue, sélection, zoom et tiroir Git ; « Copier le lien de cette vue » ; l'état des tiroirs survit au changement d'onglet (P80-D-21).
- [x] **FORM-16**: Onglets sans rechargement sur la coquille de la Phase 79 (`VF_COQUILLE.chargerOnglet`) : routage, `vf:onglet`, Précédent/Suivant, focus annoncé, titre « <Onglet> · <nom> » ; tiroirs, zoom et historique du terminal gardés, amorce du terminal inchangée (AUDC-I30, AUDC-X7 reste, AUDC-F7, P80-D-22).
- [ ] **FORM-17**: Non-régression : toutes les suites du cockpit vertes sous macOS et Linux, aucune affaiblie ; chaque comportement porte un témoin rouge sur la base puis vert, un mutant par garde ; mouvement réduit tenu (zéro animation active) ; plafond de 300 lignes par extension ; compteur de suites, table de durées et CHANGELOG du module tenus par le plan d'assemblage (P80-D-24, P80-D-25, P80-D-26).
- [x] **FORM-18**: Réouvertures tranchées (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 ; P80-D-52 à P80-D-56) : titre de vue dans une zone réservée de 130 px au plus, flou et texte court gardés (AUDC-M2, amende Q10) ; en-tête en trois groupes libellés au-delà de 1 280 px, fil d'Ariane à chevron, trois icônes trompeuses remplacées, badge « au travail » et troncature de la branche inchangés (AUDC-M5, amende PU-G-001 en partie) ; constats de Santé traduits en français dans le collecteur, noms propres gardés, introduction non retouchée (AUDC-M8, amende P70-D-04) ; une ligne « Le terminal s'active avec --terminal » dans l'aide `?` et la palette, sans pastille, port ni route (reste de AUDC-M10, amende P71-D-02) ; ouvreur Git dessiné à 36 px avec une zone d'appui de 44 px (AUDC-F3 en partie, amende P78-D-34) ; chaque point porte un témoin rouge sur la base puis vert.

---
*Requirements defined: 2026-06-04*
*Last updated: 2026-11-11 — **jointure des sept cadrages de l'audit du cockpit** : SOCL-01..27, FORM-01..18, REGI-01..17, TEMP-01..12, ACTV-01..12, TRAC-01..13 et SYNT-01..10 posées (109 exigences, Pending ; familles neuves, préfixes vérifiés libres) ; repères de cadrage retirés ; réouvertures tranchées (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11) ; les autres décisions des cadrages : décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée ; précédent : 2026-11-11 — **UIFN-01, 02, 03, 05, 08, 09, 11, 12, 13 et 14 cochées** à l'alignement du planning sur ce qui est publié en `v2.76.0` (preuves écrites sur chaque ligne ; UIFN-10 et LANC-12 restent décochées, motifs à leur ligne de table ; alignement demandé par Samuel (session principale Claude Code, 2026-11-11)) ; précédent : 2026-11-06 — GITC-01..14 et LANC-01..11 cochées ; précédent : 2026-11-05 — TERM-01..12 et UIFN-04, 06, 07 cochées ; précédent : 2026-11-04 — VFSG-01..13 et CKPT-13..28 cochées ; précédent : 2026-11-03 — **CKPT-19..28 posées** (mise à jour du cadrage de la Phase 69 : équipe au travail, P69-D-12..24, arbitrages Samuel, AskUserQuestion session principale, 2026-11-03) ; précédent : 2026-11-03 — **CKPT-01..12 cochées** (Phase 67 close : suites du cockpit rejouées vertes, recette humaine validée par Samuel, `67-CLOTURE.md`) ; précédent : 2026-10-29 — **PLTF-02 cochée** (Phase 62 close : décision A, réexamen 2027-01-31) ; précédent : 2026-10-29 — COLB-01..07 cochées à la porte de la Phase 61 (preuve citée au SUMMARY de chaque plan et à `61-08-SUMMARY.md`) ; COLB-08 décochée (procédure de recette livrée, preuve humaine attendue : P61-B-01 lab et humains, P61-B-02 trois semaines) ; COLB-09 partielle (critère 6 `clients` au code 2, en attente de la liste) ; lectures RATIFIÉES (arbitrage Samuel, AskUserQuestion session principale, 2026-10-29 (« Oui aux propositions par défaut pour 60 et 61 »)) : COLB-01 sur P61-H-01 (armement au poste `product` ou `dev`, jamais `solo`), COLB-01 et COLB-05 sur P61-PL-03 (un refus d'armement relaie un code sans faire échouer l'installation) et P61-PL-08 (une mise à jour rafraîchit un hook déjà posé mais n'arme jamais un clone ; un lab dont le poste a été posé avant cette version s'arme par `role <poste>`) ; précédent : 2026-10-29 — PLTF-01..02 posées à la préparation de la Phase 62 (PLTF-01 cochée sur preuve du dossier, PLTF-02 décochée : décision de Samuel) ; précédent : 2026-10-22 — RLPO-11 cochée par override (critère 6 non mesuré, Samuel, session principale, 2026-10-22) ; précédent : 2026-10-20 — RLPO-01..10 et 12 cochées à la porte de la Phase 58 (RLPO-11 en attente du critère 6) ; précédent : 2026-10-16 — RLPO-01..12 posées à la planification de la Phase 58, dérivées de P58-D-01..20 sans arbitrage neuf ; précédent : 2026-10-10 — DLWS-01..08 posées au cadrage de la Phase 57, dérivées de P57-D-01..15 sans arbitrage neuf ; précédent : 2026-10-08 — jalon `equipe-produit-v1.0` inscrit (Phases 57-62, six familles réservées et vérifiées libres, exigences posées au cadrage) ; précédent : 2026-10-08 — **clôture de `fiabilite-v1.0`** : WSAW-01..07 cochées (déjà Complete en traçabilité, seules les cases avaient dérivé), WSCH-01..05 cochées (WSCH-01 avec réserve de recette en session), AGTS-02 reste reportée avec trace ; snapshot `.planning/milestones/fiabilite-v1.0-REQUIREMENTS.md` ; précédent : 2026-09-25 — jalon `ecc-inspiration-v1.0` inscrit (Phases 51-56, six familles réservées et vérifiées libres, exigences posées au cadrage, aucune ligne de traçabilité tant qu'aucun ID n'existe) ; précédent : 2026-09-23 — **HEAD-01 fermée** (correction d'un ledger périmé) :
`intent-routing.md` renvoie déjà à `head-governance.md` (lignes 15 et 17, commit `5829bd0`,
2026-09-15) et la case ci-dessus est déjà cochée avec sa preuve — seule cette note de bas de
fichier était restée en contradiction avec le disque, corrigée sans rouvrir de travail ; précédent :
2026-09-15 — Phase 40 EXÉCUTÉE (clôture documentaire) : HEAD-02, HEAD-03, HEAD-04
cochées avec preuve sur pièce (`check-mission-exit.sh` 23/23 cas + 6 mutations, contrat de preuves
E6 + ses trois émetteurs, garde anti-alias T36 avec mutation discriminante) ; précédent : 2026-09-15 — Phase 40
(vibeflow-head — head of minds du dev-orchestrator) : 4 exigences neuves en une famille
(HEAD-01..04), dérivées du cadrage `40-CONTEXT.md` (D-01..D-18, seize arbitrages Samuel), préfixe
`HEAD` vérifié libre par grep exhaustif ; QUAL-01 transverse s'applique de plein droit (HEAD-02
fait naître un gate) ; précédent : 2026-09-14 — Phase 39 SHIPPÉE v2.60.0 (PR #62) : PART-01..09 cochées, statuts de traçabilité passés à Done ; précédent : 2026-09-09 — Phase 39 (Workstreams — partition du planning et collaboration concurrente) : 9 exigences neuves en une famille (PART-01..09), dérivées du cadrage `39-CONTEXT.md` et de la recherche `2026-09-09-phase-39-workstreams-mesures-de-cadrage.md`, préfixe `PART` vérifié libre par `comm` (D-07, 41 familles réellement occupées incluant `SIG-01..06` hors ledger) ; `GSDA-19` superseded par `PART-06` (corps préservé, angle bug de comportement porté par `PART-06`, D-04), `GSDA-13..19` closes non rouvertes ; précédent : 2026-08-28 — Phase 38 (Portabilité multi-runtime, livraison) : 22 exigences neuves en 6 familles (FIDE-01/02, RUNT-01/02, ROLL-01..05, TGT-01..04, ADPT-01..04, MIGR-01..05), dérivées du cadrage `38-CONTEXT.md`, 0 collision avec `PORT-xx` (Phase 30, vérifié par commande) ; ADPT-02/03 levées en session réelle par le nœud `probe-codex` le même jour (tirets confirmés inoffensifs, fork_turns sans effet sur le modèle) — plans mis à jour en conséquence ; précédent : 2026-08-15 — roadmap fiabilite-v1.0 posée : traçabilité mappée aux phases 30-35 + 18/25 héritées (30 IDs, 0 orphelin) ; précédent : ajout milestone fiabilite-v1.0 (26 exigences en 9 familles, audit d utilite prealable, Out of Scope motive) ; precedent : ajout Phase 29 (ICMD-01..12, distillation des gains ICM G1/G2/G3/G5) ; précédent : 2026-07-26 — remise à l'heure post-audit (Phase 12 annotée post-bascule v2.33.0, Phase 13 redéfinie sans verbe, Phase 14 = v2.30.0, milestones 2-3 shipped) ; précédent : 2026-07-25 — ajout Phase 14 au Milestone 6 (ALTI-01→05 : frontière d'altitude planning-core / moteur GSD, ADR-055)*
