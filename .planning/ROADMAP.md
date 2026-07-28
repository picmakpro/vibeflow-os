# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- ✅ **install-ux-v1.0** — Phases 2-6 — clôturé 2026-06-05 (plugin + skill à toggles + scope) — release `v2.4.0`
- ✅ **dev-doctrine** — Phases 7-8 — doctrine dev (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) + consolidation des doublons qualité — clôturé 2026-07-07 — release `v2.20.0`
- ✅ **memory-swarm-rnd** — Phase 9 — R&D : transposition du modèle mémoire + patterns swarm de jcode — spike GO, shippé `v2.28.0` (ADR-052 mémoire vivante + ADR-053 swarm)
- ✅ **gsd-migration** — Phases 10-11 — clos 2026-07-26, release `v2.39.0` — migration du package GSD `get-shit-done-cc` → `@opengsd/gsd-core@^1` (VOC-02)
- ✅ **vf-routing** — Phases 12-14 — clos 2026-07-26, release `v2.37.0` — routage fin des intentions (verbes `/vf-*` à l'origine ; carte d'intention agentique depuis la bascule v2.33.0), couverture complète des skills GSD, pont spec → feuille de route, et frontière d'altitude avec le moteur de planning GSD

## Phases

<details>
<summary>✅ vfdo-v1.0 — Module dev-orchestrator (Phase 1) — SHIPPED 2026-06-04</summary>

### Phase 1: dev-orchestrator

**Goal**: Module `dev-orchestrator/` distribuable (agent routeur, index auto, verbes `/vf-*`, bootstrap auto-install).
**Plans**: 5 plans (4 waves) — tous complétés.
Snapshots : `.planning/milestones/vfdo-v1.0-*`. Détails : `MILESTONES.md`.

</details>

### 🚧 Install UX (Phases 2-6)

**Milestone Goal:** Réduire l'install de VibeFlow + modules à 2 commandes (plugin) + une UX à toggles
qui se lance automatiquement, avec choix de scope (user/project/local) appliqué à tout (modules + GSD + Superpowers).
Spec : `docs/superpowers/specs/2026-06-04-install-ux-design.md`.

#### Phase 2: Manifeste & résolveur

**Goal**: Doter chaque module d'un `module.json` machine-lisible + un résolveur de dépendances transitives.
**Depends on**: Phase 1
**Requirements**: MANIF-01, MANIF-02
**Success Criteria** (what must be TRUE):

  1. Les 8 modules ont un `module.json` valide (name, version, type, description, `requires[]`).
  2. Le résolveur, donné une sélection, retourne la fermeture transitive correcte (validator → +consolidator +infrastructure-audit).

**Plans**: 2 plans (2 waves)
Plans:

- [x] 02-01-PLAN.md — 8 module.json (name, version, type, description, requires) pour les 8 modules (MANIF-01)
- [x] 02-02-PLAN.md — résolveur de fermeture transitive `_internal/resolve-deps.sh` + test (MANIF-02)

#### Phase 3: Engine scope-aware

**Goal**: `vibeflow-update.sh` + `ensure-deps.sh` installent au scope choisi, depuis le cache du plugin.
**Depends on**: Phase 2
**Requirements**: SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04
**Success Criteria** (what must be TRUE):

  1. `--scope user` cible `~/.claude/` ; `project`/`local` cible `./.claude/` ; `local` ajoute au `.gitignore`.
  2. Les modules sont installés depuis le cache du plugin (plus de `git clone`).
  3. `ensure-deps.sh` installe GSD + Superpowers au scope demandé.

**Plans**: 2 plans (1 wave — parallèles, fichiers disjoints)
Plans:

- [x] 03-01-PLAN.md — vibeflow-update.sh scope-aware : TARGET_ROOT + suppression clone + gitignore local + résolveur câblé + test isolé (SCOPE-01, SCOPE-02, SCOPE-04)
- [x] 03-02-PLAN.md — ensure-deps.sh scopé (GSD --global/--local, Superpowers --scope) + test 3 scopes en dry-run (SCOPE-03)

#### Phase 4: Skill /vibeflow-install + auto-lancement

**Goal**: Le skill interactif (toggles scope + modules, récap déps, orchestration) + auto-lancement au 1er démarrage.
**Depends on**: Phase 2, Phase 3
**Requirements**: INST-01, INST-02, INST-03, INST-04, INST-05
**Success Criteria** (what must be TRUE):

  1. L'UX propose un toggle scope puis un toggle modules (depuis les `module.json`).
  2. Les dépendances sont auto-résolues et récapitulées avant install.
  3. L'install s'effectue au scope choisi (modules + GSD + Superpowers).
  4. Un hook `SessionStart` ouvre l'UX automatiquement au 1er lancement (marqueur).

**Plans**: 2 plans (1 wave — parallèles, fichiers disjoints)
Plans:

- [x] 04-01-PLAN.md — catalogue modules `build-module-catalog.sh` + skill `/vibeflow-install` (toggles scope+modules, récap déps, orchestration scope-aware) + test (INST-01..04)
- [x] 04-02-PLAN.md — hook `SessionStart` + marqueur de 1er lancement (modèle Superpowers) + test isolé (INST-05)

#### Phase 5: Packaging plugin

**Goal**: VibeFlow installable comme plugin Claude Code (marketplace), repo public.
**Depends on**: Phase 4
**Requirements**: PLUG-01, PLUG-02, PLUG-03, PLUG-04
**Success Criteria** (what must be TRUE):

  1. `plugin.json` + `marketplace.json` valides ; le plugin bundle modules + skill + engine + manifeste.
  2. `claude plugin marketplace add picmakpro/vibeflow-os` + `install vibeflow` fonctionnent en zéro-auth (repo public).

**Plans**: 2 plans (2 waves — Plan 02 CONFIRMATION-GATED / non-autonome)
Plans:

- [x] 05-01-PLAN.md — `.claude-plugin/plugin.json` + `marketplace.json` (calque Superpowers) + câblage VIBEFLOW_CACHE=${CLAUDE_PLUGIN_ROOT} dans le skill + doc d'install 2-commandes (PLUG-01, PLUG-02)
- [ ] 05-02-PLAN.md — checklist pré-public + flip repo public + validation marketplace add/install zéro-auth — CONFIRMÉ HORS-AGENT (PLUG-03, PLUG-04)

#### Phase 6: dev-orchestrator first-use

**Goal**: Au 1er usage, l'agent détecte un projet non GSD-initialisé et propose l'init.
**Depends on**: Phase 1 (indépendant des phases 2-5)
**Requirements**: FIRST-01, FIRST-02
**Success Criteria** (what must be TRUE):

  1. L'agent détecte l'absence de `.planning/` au premier usage.
  2. Il propose map-codebase puis new-project sur confirmation (jamais `gsd-new-project` seul).

**Plans**: 1 plan (1 wave)
Plans:

- [x] 06-01-PLAN.md — garde-fou first-use dans AGENT.md (détection `.planning/PROJECT.md` absent → délégation vf-init, new-project jamais seul) + axe de test T7 (FIRST-01, FIRST-02)

### 🚧 Doctrine dev & consolidation (Phases 7-8)

**Milestone Goal:** Combler les philosophies de dev manquantes (DRY absent ; Clean Architecture,
Clean Code non nommés ; TDD sans carte) dans le foyer `software-architecture`, puis consolider les
doublons du cluster qualité (`software-architecture` / `feature-dev-gates` / `audit-architecture`).
`dev-orchestrator` reste un pur routeur (invariant).
Spec : `docs/superpowers/specs/2026-07-07-dev-doctrine-consolidation-design.md`.

#### Phase 7: Philosophies de dev

**Goal**: Enrichir `software-architecture` — DRY/KISS/YAGNI écrits, Clean Architecture + Clean Code nommés, carte TDD renvoyant au skill canonique, câblage Tier 2 honnête. Sans dupliquer l'existant.
**Depends on**: — (module déjà en place)
**Requirements**: PHIL-01..08
**Success Criteria** (what must be TRUE):

  1. `principles.md` porte DRY + KISS + YAGNI (contrats vérifiables) + une carte TDD renvoyant au skill canonique.
  2. Clean Architecture (Dependency Rule) et Clean Code sont **nommés** dans `solid-soc.md`.
  3. `SKILL.md` câble DRY/KISS-YAGNI/Clean Code en Tier 2, référence `principles.md`, étend le frontmatter — **aucun faux gate machine**.
  4. `module.json` bumpé v1.2.0 + CHANGELOG/README ; densité `.md` sous seuils ADR-029.

**Plans**: 2 plans (2 waves) — ✅ complétés, vérif goal-backward PASS (`07-VERIFICATION.md`)
Plans:

- [x] 07-01-PLAN.md — nommage Clean Archi/Clean Code + `principles.md` (DRY/KISS/YAGNI + carte TDD) + table universelle (PHIL-01..05, 07)
- [x] 07-02-PLAN.md — câblage Tier 2 `SKILL.md` + release-meta module v1.2.0 (PHIL-06, 08)

#### Phase 8: Consolidation des doublons

**Goal**: Assainir le cluster qualité — fusionner/déprécier `feature-dev-gates` dans un foyer de gates unique, dé-dupliquer `audit-architecture` (renvois au lieu de re-description), factoriser les 3 axiomes, corriger les descriptions legacy.
**Depends on**: Phase 7
**Requirements**: CONS-01..04
**Success Criteria** (what must be TRUE):

  1. Un seul foyer de rule de gates de code (plus de doublon de globs `src/** app/** lib/** features/**`).
  2. `audit-architecture` renvoie au lieu de dupliquer ; sa `module.json` legacy corrigée.
  3. Les 3 axiomes (enforcement>prose, filet fonctionnel, preuve avant done) ont une source unique.
  4. Invariant vérifié : `dev-orchestrator` inchangé (pur routeur).

**Plans**: 4 plans — ✅ complétés, vérif goal-backward PASS (`08-VERIFICATION.md`)
Plans:

- [x] 08-01-PLAN.md — fusion gates Nyquist+Decision Coverage → software-architecture v1.3.0 (CONS-01)
- [x] 08-02-PLAN.md — suppression feature-dev-gates + `cleanup_retired_modules` engine + test T7 + doc refs (CONS-01)
- [x] 08-03-PLAN.md — reference/AXIOMES-ENFORCEMENT.md source unique + renvois (CONS-03)
- [x] 08-04-PLAN.md — dé-dup Instance C audit-architecture + fix description legacy v1.0.1 (CONS-02)

### 🔬 R&D mémoire & swarm (Phase 9)

**Milestone Goal:** Évaluer, par spike sur lab témoin, la transposition du modèle mémoire riche de jcode
(trust/confidence/décroissance/supersession/arêtes typées) et de ses patterns swarm de sûreté
(lock de driver unique, DAG ready/blocked) dans le `consolidator` et l'équipe `vf-dev-manager`.
**Ne produit PAS de release** — décision go/no-go avant tout ADR ou changement du format mémoire officiel.
Source : `.planning/research/jcode-memory-swarm-transposition-NOTE.md`.

#### Phase 9: Spike transposition jcode (mémoire + swarm)

**Goal**: Prototyper les 3 gestes mémoire les moins chers (frontmatter `trust`/`confidence`/`superseded_by`

+ règle de décroissance par catégorie dans `consolidator`) sur un lab témoin, mesurer le coût de maintenance

réel, et statuer go/no-go. Volet swarm (lock de driver + DAG) = second spike indépendant, conditionné à des
collisions observées sur les backups isolés (ADR-048/049).
**Depends on**: — (R&D exploratoire, hors chaîne de release)
**Requirements**: RND-01, RND-02
**Success Criteria** (what must be TRUE):

  1. Le format mémoire enrichi (3 gestes : `trust`/`confidence`/`superseded_by`) est prototypé sur ≥1 lab
     témoin et le `consolidator` sait le tenir à jour **automatiquement** — round-trip lit→recalcule→réécrit
     sans édition humaine, entrée `superseded_by` archivée sans suppression (sinon → no-go documenté).

  2. Les demi-vies de décroissance sont re-calibrées pour l'usage VibeFlow multi-métiers (pas les valeurs
     jcode brutes).

  3. Une décision go/no-go écrite tranche : (a) écrire un ADR + toucher le format officiel, ou (b) archiver.
  4. Le volet swarm est cadré (lock de driver + DAG) mais **non implémenté** tant que les collisions ne sont
     pas observées en pratique.
**Plans**: à cadrer (`/gsd:discuss-phase 9` puis `plan-phase`)
Plans:

- [x] 09-01 — spike frontmatter mémoire enrichi (3 gestes) + règle décroissance `consolidator` sur lab témoin (RND-01) → **GO** (round-trip idempotent + archivage non destructif vérifiés, `spike/`)
- [x] 09-02 — note go/no-go mémoire (verdict + demi-vies recalibrées, `09-GO-NOGO-memoire.md`) + mini-cadrage écrit du volet swarm non implémenté (`09-CADRAGE-swarm.md`) (RND-02)

### 🚧 Migration package GSD (Phases 10-11)

**Milestone Goal:** Basculer la dépendance GSD de `get-shit-done-cc` vers `@opengsd/gsd-core` (VOC-02)
sans casser l'auto-install, l'index factuel ni le routage. On sépare **l'étude** (la bascule est-elle
mûre, quelle surface d'impact, quelle stratégie) de **l'intégration** (implémentation outillée + release
taggée). L'intégration est **conditionnée au GO** de l'étude — un no-go documenté archive le chantier
sans toucher le code.

#### Phase 10: Étude & faisabilité migration GSD

**Goal**: Cartographier toute la surface d'usage de GSD dans VibeFlow, évaluer la maturité et la parité du package cible `@opengsd/gsd-core`, et trancher par une note go/no-go écrite (bascule maintenant / attendre / stratégie de migration + fenêtre de compat).
**Depends on**: — (chantier indépendant, hors chaîne des milestones précédents)
**Requirements**: GSDM-01, GSDM-02, GSDM-03
**Success Criteria** (what must be TRUE):

  1. La **surface d'impact** est inventoriée exhaustivement : tous les points de contact GSD (`ensure-deps.sh`, `build-gsd-index.sh`, binaire `gsd-sdk`, chemins `~/.claude/get-shit-done/`, pins `PROJECT.md`, hooks, références docs) sont listés avec le changement attendu pour chacun.
  2. Le package cible `@opengsd/gsd-core` est **caractérisé** : existence/stabilité npm, commande d'install non-interactive équivalente, nom du binaire, structure de dossier, parité fonctionnelle des skills/SDK consommés — écarts documentés.
  3. Une **note go/no-go écrite** tranche : (a) migrer maintenant (avec stratégie + fenêtre de compat), (b) attendre (déclencheur de resurgence explicite), ou (c) archiver. Un no-go clôt le milestone sans Phase 11.

**Plans**: à cadrer (`/gsd:discuss-phase 10` puis `plan-phase`)

#### Phase 11: Intégration migration GSD

**Goal**: Exécuter la bascule décidée en Phase 10 — basculer les points d'install et l'index vers `@opengsd/gsd-core`, mettre à jour les références, prouver la non-régression en isolé, documenter et livrer une release taggée.
**Depends on**: Phase 10 (**GATE** : n'exécuter que si go/no-go = GO)
**Requirements**: GSDM-04, GSDM-05, GSDM-06
**Success Criteria** (what must be TRUE):

  1. `ensure-deps.sh` et les pins (`PROJECT.md`) installent `@opengsd/gsd-core` en non-interactif, idempotent, avec fallback manuel — GSD `get-shit-done-cc` n'est plus référencé.
  2. L'index factuel (`build-gsd-index.sh`) est régénéré depuis le nouveau package/binaire, zéro hallucination, et les références docs pointent la nouvelle source.
  3. Non-régression prouvée en **isolé** (dry-run 3 scopes + idempotence, vrai `~/.claude` jamais touché) ; CHANGELOG/README à jour ; release bumpée + **tag annoté poussé** (`scripts/check-release-tag.sh --remote` → ✓).

**Plans**: à cadrer (`/gsd:discuss-phase 11` puis `plan-phase`)

### 🚧 Routage fin & verbes VibeFlow (Phases 12-14)

**Milestone Goal:** Faire qu'une intention formulée en langage naturel atterrisse **toujours** sur le bon
verbe `/vf-*` — et qu'il existe un verbe pour chaque geste réellement formulable, les ~35 gestes d'outillage
restants étant routés par doctrine. Puis fermer le seul maillon non outillé du cycle : le passage d'un
cadrage écrit (spec) aux étapes de la feuille de route.
Spec : `docs/superpowers/specs/2026-07-25-routage-fin-verbes-vf-design.md`.

#### Phase 12: Routage fin & couverture complète des verbes `/vf-*`

**Goal**: Trois niveaux de routage (descriptions déclencheuses, rule de préséance globale, agent + doctrine
exhaustive on-demand) et 19 nouveaux verbes, pour qu'aucune intention de dev ne tombe dans le vide et
qu'aucun skill `gsd-*` ne gagne l'arbitrage en entrée de chaîne.
**Depends on**: — (chantier indépendant des milestones 10-11)
**Requirements**: VERB-01, VERB-02, VERB-03, VERB-04, VERB-05
**Success Criteria** (what must be TRUE):

  1. La table de routage de `AGENT.md` ne cite plus aucune cible `gsd-*` : chaque intention pointe un verbe
     `/vf-*`. `AGENT.md` reste ≤ 250 L (déport de la doctrine exhaustive dans `references/intent-routing.md`).

  2. 19 verbes sont livrés (18 dans `dev-orchestrator`, `vf-sketch` dans `design-orchestrator`), chacun
     déléguant à une cible GSD existante — aucune logique d'outil réimplémentée.

  3. Les 33 descriptions suivent le gabarit déclencheur (formulations FR réelles + contre-exemples nommant
     les voisins), et les groupes de collision identifiés (`vf-test`/`vf-testgen`, `vf-review`/`vf-gaps`,
     le quatuor amont, `vf-map`/`vf-learn`, `vf-progress`/`vf-resume`, `vf-gaps`/`/vf-audit`) sont démarqués.

  4. `rules/vf-verb-precedence.md` (≤ 40 L, globale) est installée en `.claude/rules/` et interdit
     l'invocation directe d'un `gsd-*`/`superpowers:*` en entrée de chaîne.

  5. `intent-routing.md` couvre 100 % des skills de `gsd-skills-index.md` ; les tests du module passent —
     **fixture T4 étendue aux nouvelles cibles** (sinon orphelins hors poste de dev), + T12 (anti-collision),
     T13 (préséance), T14 (exhaustivité).
**Plans**: 6 plans (3 vagues) — ✅ complétés. Livré : **31 verbes** dans `dev-orchestrator` (14 → 31) et 2
dans `design-orchestrator`, `AGENT.md` 218 L, rule 40 L, `intent-routing.md` 65/65 skills routés,
suite de tests 25 OK / 0 KO / 1 SKIP (le SKIP est `vf-ingest`, attendu en Phase 13).
Release `v2.31.0` — dev-orchestrator v1.8.1, design-orchestrator v1.1.0, conductor v1.12.2.
⚠️ *Post-scriptum 2026-07-26* : la **façade `/vf-*` et la rule de préséance ont été supprimées en
v2.33.0** (bascule agentique, spec `2026-07-25-suppression-facade-vf-design.md`). Les critères 2 et 4
ci-dessus décrivent l'état livré en v2.31.0, plus l'état courant — subsistent la carte d'intention
unique de `vibeflow-dev`, `vf-auto` et `vf-dev` ; la suite de tests a été refondue (26 OK en v2.33.0).
Plans:

- [x] 12-01 — fondations : gabarit de description + doctrine `intent-routing.md` + rule de préséance (VERB-01, VERB-04, VERB-05)
- [x] 12-02 — 17 verbes `/vf-*` neufs dans `dev-orchestrator` (VERB-02)
- [x] 12-03 — verbe `/vf-sketch` dans `design-orchestrator` (VERB-02)
- [x] 12-04 — réécriture des 14 descriptions existantes sur le gabarit + démarcations croisées (VERB-03)
- [x] 12-05 — table de routage de l'agent vers les verbes + point d'entrée générique (VERB-01)
- [x] 12-06 — trois axes de vérification machine (T12/T13/T14) + fixture T4 étendue (VERB-05)

**Écarts assumés** (tracés) : le verbe prévu `vf-audit` s'appelle **`vf-gaps`** — `/vf-audit` était déjà
pris par l'audit de conformité du lab (`plugin/commands/vf-audit.md` → `vibeflow-validator`). Le bloc
« cibles canoniques figées » de `AGENT.md` a été supprimé plutôt que conservé (D-09) : le maintenir aurait
exigé le résidu même que VERB-01 supprime ; T3 mesure désormais la couverture sur les verbes, à seuil
identique. Les axes de test portent les numéros T12/T13/T14 et non T11/T12/T13 : `T11` était déjà pris par
l'axe de généricité (DM5).

**Soldes livrés dans la foulée** : bornage de T5/T11 au module (en lab, `skills/` et `agents/` sont plats
et partagés), correction des deux textes qui décrivaient mal le chargement des rules (installeur + Pattern
05), gabarit de description sur les trois verbes du `conductor`, frontière d'altitude ADR-055 portée par
les cinq verbes `.planning`-centrés, et purge des mentions d'un projet tiers dans tout le dépôt (public).

#### Phase 13: Pont spec → feuille de route (ingestion portée par l'agent)

> Redéfinie le 2026-07-26 : la phase avait été écrite autour du verbe `/vf-ingest`, or la façade `/vf-*`
> a été supprimée en v2.33.0 (bascule agentique, spec `2026-07-25-suppression-facade-vf-design.md`).
> La capacité est désormais portée par l'agent `vibeflow-dev` — aucun verbe-façade n'est créé.

**Goal**: Outiller le passage d'un cadrage écrit aux étapes de la feuille de route — une spec devient des
étapes + des exigences, un plan devient le plan d'une étape — en déléguant aux moteurs GSD existants et
sans contourner leurs garde-fous.
**Depends on**: Phase 12 (carte d'intention unique de `vibeflow-dev` en place)
**Requirements**: BRDG-01, BRDG-02, BRDG-03
**Success Criteria** (what must be TRUE):

  1. L'agent `vibeflow-dev` traite les deux grains : spec → `gsd-ingest-docs --mode merge` (étapes +
     exigences), plan → `gsd-import --from` (PLAN.md d'une étape) — sans réimplémenter de parseur maison.

  2. La découverte des specs/plans non encore intégrés est **outillée** (`discover-unintegrated-docs.sh` :
     chemin non cité dans les 6 registres, détection du grain) ; l'agent construit le manifest YAML —
     l'utilisateur n'écrit jamais de manifest à la main.

  3. Gate BLOCKER jamais contourné, confirmation humaine avant toute écriture dans `.planning/` (ADR-031),
     `--mode merge` par défaut sur projet existant, cap 50 documents signalé.

  4. En fin de cadrage (brainstorm → spec écrite), l'agent propose l'ingestion comme next step — plus
     aucune spec orpheline, sans ressusciter le cycle de verbes supprimé en v2.33.0.

  5. Release livrée : CHANGELOG/README des modules à jour, bump racine + **tag annoté poussé**
     (`scripts/check-release-tag.sh --remote` → ✓).
**Plans**: 2 plans (2 vagues) — ✅ complétés, vérif goal-backward **PASS** (`13-VERIFICATION.md` : 4/4
critères dans le mandat, 3/3 BRDG, 22/22 must-haves, 0 blocker). Livré : `discover-unintegrated-docs.sh`
(16 cas, 3 mutants sur 4 tués) et la doctrine `references/ingestion-flow.md` câblée dans `AGENT.md`
(158 L) + `intent-routing.md`, axes T16/T17. Module `dev-orchestrator` **v2.2.0**. Suites : 16 ok · 30 OK
· 10 OK · `check-agents` ✓ · `check-version-sync` ✓.
Plans:

- [x] 13-01-PLAN.md — `discover-unintegrated-docs.sh` : le fait « quels cadrages ne sont pas dans la
  feuille de route », 6 registres, grain spec/plan, exits 0/3/64 (BRDG-02)

- [x] 13-02-PLAN.md — doctrine `ingestion-flow.md` + câblage agent (manifest, délégation
  `gsd-ingest-docs --mode merge` / `gsd-import --from`, 4 garde-fous) + T16/T17 (BRDG-01, BRDG-03)

**Reste-à-faire assumé** : le **critère 5 (release + tag)** est hors du mandat de la mission — réservé à
validation humaine. Deux points ouverts tracés : l'arbitrage doctrinal sur la portée de `vf-dev-manager`
face à l'ingestion (audit BRDG-03), et le filtre glob du script non couvert par la suite (mutant
survivant — effet possible faux négatif, jamais faux positif).

#### Phase 14: Frontière d'altitude planning-core / moteur GSD (rescope de `vf-planning`)

**Goal**: Faire cesser la concurrence entre `vf-planning` et le moteur de planning GSD — deux moteurs
produisaient les mêmes fichiers dans le même dossier avec des frontmatters incompatibles. Un projet de code
a désormais un seul moteur (GSD) ; `planning-core` tient l'altitude lab et la couche mémoire/enforcement.
**Depends on**: — (indépendante de la Phase 12 : les 4 verbes cibles `/vf-init`, `/vf-progress`, `/vf-plan`,
`/vf-map` existent déjà parmi les 14 verbes actuels)
**Requirements**: ALTI-01, ALTI-02, ALTI-03, ALTI-04, ALTI-05
**Success Criteria** (what must be TRUE):

  1. `scripts/detect-gsd-engine.sh` répond au fait « un moteur de planning est-il en place ? » par 4 exits
     ordonnés par priorité, **sans jamais inférer de métier** ; 10 cas de test passent, dont la primauté du
     marqueur GSD sur les signaux de code.

  2. La description de `vf-planning` ne revendique plus aucune intention de projet dev et nomme ses voisins
     en contre-exemples ; le SKILL branche sur deux séquences (A : socle universel non-dev, B : couche lab).
     Sur un lab dev, **aucun** artefact de projet n'est généré.

  3. La double injection `SessionStart` est terminée (`--defer-to-gsd`, opt-in, câblé dans `hooks.json`) — le
     comportement par défaut des scripts est **inchangé** et l'`INDEX.md` du lab reste injecté (altitude lab).

  4. `guard-planning-updated.sh` reste **bloquant** (exception motivée : il vérifie un résultat, ne génère
     rien) et aucun `.planning/` existant n'est jamais réécrit (ADR-031, protocole de migration exit 2).

  5. Non-régression prouvée : les 4 bundles non-dev passent par la séquence A, la suite de tests du module est
     verte, `check-agents.sh` OK ; release bumpée + **tag annoté poussé** (`check-release-tag.sh --remote` → ✓).
**Plans**: 7 plans (4 waves ; 14-07 né du rapport d'exécution) — portés depuis `docs/superpowers/plans/2026-07-25-rescope-vf-planning-gsd.md`
Plans:

- [x] 14-01-PLAN.md — `detect-gsd-engine.sh` : fait vérifiable « un moteur est-il en place », 4 exits + 10 tests (ALTI-01)
- [x] 14-02-PLAN.md — `references/gsd-handoff.md` : doctrine d'altitude + table intention → verbe + protocole de migration (ALTI-04)
- [x] 14-03-PLAN.md — `--defer-to-gsd` sur 2 hooks : fin de la double injection SessionStart, défaut inchangé (ALTI-03)
- [x] 14-04-PLAN.md — `SKILL.md` : description désarmée + étape 0 + séquences A/B (ALTI-02)
- [x] 14-05-PLAN.md — commande, `domain-detection.md`, ADR-055 au registre (ALTI-04)
- [x] 14-06-PLAN.md — release : module v2.4.0, racine v2.30.0, tag annoté poussé (ALTI-05)
- [x] 14-07-PLAN.md — route `vf-new-lab` → moteur GSD documentée + 3 formulations alignées ADR-055 (ALTI-04 ; né du rapport d'exécution)

## Progress

**Execution Order:**
1 ✅ → 2 ✅ → 3 ✅ → 4 ✅ → 5 ✅ ; 6 ✅ indépendant → 7 ✅ → 8 ✅ ; **9 ✅ (R&D, shippée v2.28.0)** ; **10 🚧 → 11 🚧 (GATE : 11 conditionné au GO de 10)** ; **12 ✅ → 13 ✅ (code complet, release en attente de validation humaine)** ; **14 ✅ (indépendante)** ; **15 ✅ (shippée v2.40.0) → 16 ✅ (shippée v2.41.0)** ; **17 ✅ (indépendante de 16, terminée et vérifiée — release en attente de validation humaine) → 18 inscrite (dépend de 17)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. dev-orchestrator | vfdo-v1.0 | 5/5 | Complete | 2026-06-04 |
| 2. Manifeste & résolveur | Install UX | 2/2 | Complete | 2026-06-04 |
| 3. Engine scope-aware | Install UX | 2/2 | Complete | 2026-06-05 |
| 4. Skill /vibeflow-install | Install UX | 2/2 | Complete | 2026-06-05 |
| 5. Packaging plugin | Install UX | 2/2 | Complete | 2026-06-05 |
| 6. dev-orchestrator first-use | Install UX | 1/1 | Complete | 2026-06-05 |
| 7. Philosophies de dev | dev-doctrine | 2/2 | Complete | 2026-07-07 |
| 8. Consolidation des doublons | dev-doctrine | 4/4 | Complete | 2026-07-07 |
| 9. Spike transposition jcode | memory-swarm-rnd | 2/2 | Complete — shippée `v2.28.0` (ADR-052/053) | 2026-07-22 |
| 10. Étude & faisabilité migration GSD | gsd-migration | 3/3 | Complete — GO humain validé 2026-07-26 (10-ETUDE + 10-SOLUTIONS + 10-APPROFONDISSEMENT) | 2026-07-26 |
| 11. Intégration migration GSD | gsd-migration | 6/6 | Complete — bascule @opengsd/gsd-core livrée, vérif goal-backward PASS (3/3 critères), audit sans bloquant — release `v2.39.0` | 2026-07-26 |
| 12. Routage fin & verbes /vf-* | vf-routing | 6/6 | Complete — release `v2.31.0` | 2026-07-25 |
| 13. Pont spec → feuille de route | vf-routing | 2/2 | Complete — release `v2.37.0` — module v2.2.0, vérif PASS | 2026-07-26 |
| 14. Frontière d'altitude planning-core / GSD | vf-routing | 7/7 | Complete — release `v2.30.0` (ADR-055) | 2026-07-25 |
| 15. Collaboration inter-équipes dev ↔ design | — | 7/7 | Complete — release `v2.40.0` (5/5 critères), 2 points escaladés → Phase 16 | 2026-07-27 |
| 16. Cloisonnement complet des dispatches | — | 8/8 | Complete — release `v2.41.0` (4/4 critères, SC3 amendé : contrat + lint, pas sandbox runtime) | 2026-07-27 |
| 17. Signaux de démarrage du moteur de dev | — | 3/3 | Complete — module v2.6.0, SC5/SC6 vérifiés par exécution, release racine en attente de validation humaine | 2026-07-28 |

### Phase 15: Collaboration inter-équipes dev ↔ design

**Goal**: Faire collaborer les deux équipes de mission (dev-orchestrator, design-orchestrator) **par
étages croisés sous un seul manager** — option A de l'étude du 2026-07-27 : un seul verrou de driver,
un seul DAG, un seul rapport. `vf-dev-manager` gagne un étage design (nœuds `craft:<écran>` via
`vf-crafter` avant l'exécution d'une étape à dominante UI, `critique:<écran>` via `vf-design-judge`
en parallèle de la revue code) ; `vf-design-manager` gagne un étage implémentation (`vf-coder` pour
incarner les specs+tokens du crafter — comble le trou « specs jamais implémentées »). L'imbrication
manager→manager reste INTERDITE (Pattern A, prouvée bloquante par test) ; le kernel `dag.sh` accepte
déjà les DAG hétérogènes et le reopen cross-métier (7/7 tests empiriques verts). Inclut le fix de
l'aiguillage `vf-auto` (dominante design → `Task(vf-design-manager)`) pour honorer la description
déjà publiée de `vf-design-manager`.
**Requirements**: TBD (à dériver au cadrage)
**Depends on:** Phase 14
**Success Criteria** (what must be TRUE):

  1. `vf-dev-manager` sait insérer les étages design (craft avant exec, critique en parallèle de la
     revue) sur une étape à dominante UI, avec workers `vf-crafter`/`vf-design-judge` — sans jamais
     dispatcher `vf-design-manager` (pas d'imbrication de managers, Pattern A intact).

  2. `vf-design-manager` sait dispatcher `vf-coder` pour implémenter les specs du crafter, avec le
     même contrat typé — le « vert » design reste la critique scorée ≥ seuil.

  3. `vf-auto` route une mission longue à dominante design vers `Task(vf-design-manager)` (aiguillage
     documenté, cohérent avec la description publiée de l'agent).

  4. Le cloisonnement machine-enforced tient : `check-agents.sh` passe, les juges restent sans
     Write/Edit effectif, les workers internes restent `vf-internal: true`.

  5. Tests : les suites des deux modules couvrent le scénario croisé (DAG mixte, reopen cross-métier,
     interdiction d'imbrication) et restent vertes ; release bumpée + tag annoté poussé
     (`check-release-tag.sh --remote` → ✓).
**Plans:** livrée en mission d'équipe (DAG de mission, 2026-07-27) — pas de PLAN.md par plan

Plans:

- [x] Contrats et doctrine croisée — `mission-contracts.md` (champs de brief `design:`/`livrable:`, digest croisé), nouvelle référence `mission-cross-team.md`, « Pattern D » de renvoi, table `team-kernel.md`
- [x] Étages croisés sur les deux managers — étage design dans `vf-dev-manager`, étage implémentation dans `vf-design-manager`, allowlists `Agent(...)` (18 et 6 noms)
- [x] Aiguillage et descriptions — `vf-auto` D-11, dispatch élargi des 4 workers, signaux de mission des deux `AGENT.md`
- [x] Tests croisés — T18/T18b (dev), T8/T8b + T4 durci (design), T12 (DAG hétérogène cross-métier), chacun prouvé discriminant par mutation
- [x] Portée réelle du cloisonnement — garantie attribuée au verrou de driver, dette `Agent` non scopé des workers consignée dans CONCERNS.md
- [x] Bumps par module — conductor v1.14.6, design-orchestrator v1.3.0, dev-orchestrator v2.4.0
- [x] **Release racine + tag annoté + release GitHub** — `v2.40.0` validée humainement et publiée le 2026-07-27 (`check-release-tag.sh --remote` → ✓)

### Phase 16: Cloisonnement complet des dispatches d'agents

**Goal**: Fermer les deux trous escaladés par la mission de la Phase 15, tous deux sur le même
sujet : le cloisonnement des dispatches est aujourd'hui **documenté et testé par module**, mais pas
**garanti par le gate partagé**, et il ne couvre que le chemin direct manager→manager. (1) Écrire le
lint réel des allowlists `Agent(...)` dans `check-agents.sh` — le script ne lit actuellement jamais
le contenu du champ `tools:`, si bien que des noms d'agents inventés, une parenthèse non fermée ou
des outils inexistants passent `--strict` en vert. (2) Scoper l'accès `Agent` de `vf-coder`,
`vf-reviewer` et `vf-auditer`, qui laissent ouvert le chemin indirect manager→worker→manager.
**Requirements**: TBD (à dériver au cadrage)
**Depends on:** Phase 15
**Success Criteria** (what must be TRUE):

  1. `check-agents.sh` valide le **contenu** des allowlists `Agent(...)` : syntaxe (parenthèse
     fermée, séparateurs) et existence de chaque nom — sans rendre rouges des allowlists correctes
     qui référencent des types natifs sans fichier `.md` (`general-purpose`) ou des agents externes
     fournis par `@opengsd/gsd-core` (`gsd-*`). Ce piège est la raison pour laquelle le lint n'a pas
     été écrit en Phase 15.

  2. Les allowlists de `vf-coder`, `vf-reviewer` et `vf-auditer` sont posées après le **même
     recensement exhaustif** que celui de la Phase 15 — dispatches directs **et** agents dispatchés
     par les skills que ces workers invoquent (l'angle mort qui avait produit 4 omissions).

  3. Le chemin indirect manager→worker→manager est structurellement fermé ; la dette correspondante
     sort de `CONCERNS.md`.

  4. Les tests de suite existants (T18/T18b, T8/T8b) restent verts et le nouveau lint est prouvé
     discriminant par mutation ; les 39 suites du repo passent.
**Plans:** livrée en mission d'équipe (2026-07-27) — cadrage rétroactif, pas de PLAN.md par plan

**Amendement au SC3 (découverte de la mission, actée)** : le runtime Claude Code **ignore** la liste
de noms entre parenthèses dans la définition d'un sous-agent — la doc officielle est explicite, et
elle est désormais citée verbatim dans l'en-tête de `check-agents.sh`. Une allowlist `Agent(x, y)`
n'est donc **pas** un bac à sable runtime pour un agent posé sous `.claude/agents/` : c'est un
**contrat documenté, enforcé par le lint et par lui seul**. Elle ne redevient une vraie restriction
runtime que pour un agent incarné en thread principal (`claude --agent`). Le SC3 est tenu au sens
« contrat + gate machine », pas au sens « sandbox runtime ». Cette honnêteté doctrinale vaut
rétroactivement pour les allowlists des deux managers posées en Phase 15.

Plans:

- [x] Lint des allowlists dans `check-agents.sh` — syntaxe et existence des noms, sur `tools:` comme `disallowedTools:` ; suite `test-check-agents` portée de 38 à 58 axes
- [x] Résolution graduée du piège natifs/externes — sévérité indexée sur ce qui est vérifiable indépendamment du périmètre installé : syntaxe → erreur dure, outils → erreur en `--strict`, **nom d'agent non résolu → warning même en `--strict`**, erreur seulement sous `--resolve-agents=strict` (mode opt-in réservé à la CI, seul endroit où l'univers des agents est connu)
- [x] Fermeture de la dette connexe `CONCERNS.md:52-59` — `--third-party-prefix` règle les 66 faux positifs du scope user
- [x] Allowlists des 3 workers après double recensement indépendant — `vf-coder` (22 noms), `vf-reviewer` (1), `vf-auditer` (1) ; écart de 5 noms entre les deux dérivations sur `vf-coder`, union retenue (coût d'erreur asymétrique)
- [x] Correctifs remontés par les juges — T19/T19e étaient **tautologiques** (grep sur toute la ligne `tools:` : un nom retiré de l'allowlist mais replacé en `Bash(...)` laissait la suite verte), 2 faux-bloquants du lint neuf, et `--resolve-agents=<valeur inconnue>` qui dégradait le gate en silence
- [x] Sortie de dette — entrées « accès `Agent` non scopé » et « `check-agents --strict` sans périmètre tiers » retirées de `CONCERNS.md` (la seconde vérifiée empiriquement sur `~/.claude/agents`)
- [x] Bumps par module — `conductor` v1.15.0, `dev-orchestrator` v2.5.0
- [x] Release racine `v2.41.0` — taggée et publiée le 2026-07-27

### Phase 17: Signaux de démarrage du moteur de dev

Spec : `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md`.

**Goal**: Rendre implicites les gestes de démarrage et d'hygiène documentaire (`gsd-onboard`,
`gsd-config`, `gsd-map-codebase`, `gsd-ingest-docs`, `gsd-docs-update`), qui ne se déclenchent
aujourd'hui que si le modèle y pense. `dev-orchestrator` est le seul module structurant **sans
aucun hook** — conséquence directe : `discover-unintegrated-docs.sh`, livré en Phase 13 avec un
contrat propre et testé, n'est jamais appelé automatiquement, et rien ne guide l'utilisateur
au-delà de l'init d'un projet. Poser au module un fragment `hooks/hooks.json` sur le modèle de
`planning-core` : trois scripts constatent des FAITS au `SessionStart` et injectent des signaux
courts et **auto-portants** (chaque ligne porte son propre geste, comme `[planning-debt]`).
**Depends on**: — (indépendante de la Phase 16 ; s'appuie sur l'acquis des Phases 13 et 14)
**Requirements**: SIG-01 (continuum `check-dev-bootstrap.sh` — 4 états mutuellement exclusifs, un
seul script) · SIG-02 (`discover-unintegrated-docs.sh --hook`, non-régression du contrat historique
`grain<TAB>chemin` + exits 0/3/64) · SIG-03 (`check-doc-drift.sh` — heuristique commits, seuil
réglable, silence hors dépôt git) · SIG-04 (contrat advisory/lecture seule des 3 scripts — aucune
écriture, aucun exit 1, aucun blocage de tour) · SIG-05 (gate ADR-044 réellement falsifiable sur
`AGENT.md` racine de module via `check-agents.sh --file`, fermé par test embarqué plutôt que
documenté) · SIG-06 (portabilité macOS/Linux prouvée par conteneur avant push, non cochée sur un
run macOS seul)
**Success Criteria** (what must be TRUE):

  1. Sur un repo sain et complètement cadré, les trois scripts sortent en 3 et la **seule** ligne
     injectée est le `[gsd-engine]` d'orientation. *(Amendé le 2026-07-27 — arbitrage humain de
     Samuel, cf. `.planning/STATE.md` §Decisions : le libellé original « aucune ligne n'est
     injectée » contredisait la spec §4.2/§7 et se contredisait lui-même avec SC2/SC2bis
     ci-dessous, qui exigent le signal `[gsd-engine]`. La spec fait foi.)*

  2. `check-dev-bootstrap.sh` couvre le continuum de démarrage en un seul script : silence si ni
     code ni `.planning/`, signal `onboard` si code sans `.planning/`, signal `bootstrap` listant
     les items manquants (`config.json`, `codebase/`, ROADMAP sans phase) sinon, signal
     d'orientation `gsd-engine` si complet. Les trois signaux sont prouvés mutuellement exclusifs
     par test.
  2bis. Le signal `gsd-engine` ferme le trou de routage constaté le 2026-07-27 sur ce repo : une
     demande de conception adressée au Claude principal est partie sur `superpowers:brainstorming`
     alors que le projet tournait sous GSD avec une Phase 16 inscrite. Cause structurelle —
     `planning-core` se retire quand GSD tient le projet (`--defer-to-gsd`) et aucun module ne
     prend le relais ; le routage de `vibeflow-dev` n'existe que si son `AGENT.md` est lu, donc
     seulement une fois l'agent invoqué. Le signal lit le frontmatter réel de `STATE.md`
     (milestone, phase, statut) et retombe en silence s'il est illisible — jamais d'état inventé.

  3. `discover-unintegrated-docs.sh --hook` agrège le compte en une ligne **sans toucher** au
     contrat historique (`grain<TAB>chemin`, exits 0/3/64) consommé par `ingestion-flow.md` ;
     `--hook` avec `--quiet` sort en 64.

  4. `check-doc-drift.sh` signale au-delà d'un seuil de commits de code sans mise à jour de doc
     (défaut 20, réglable), et reste silencieux hors dépôt git ou sans commit de doc.

  5. Les trois scripts sont en **lecture seule** et **advisory** : aucune écriture, aucun exit 1,
     aucun blocage de tour — la confirmation humaine reste devant chaque geste proposé (ADR-031,
     garde-fous BRDG-03 pour l'ingestion).

  6. Les hooks sont câblés par l'engine sans le modifier (`merge_module_hooks` gère déjà le
     fragment), `check-agents.sh` passe après modification d'`AGENT.md`, et les tests des trois
     scripts passent sous `bash` macOS **et** Linux (portabilité CI — régression du 2026-07-27).
**Plans:** 3 plans (3 vagues) — ✅ complétés. Livré : `check-dev-bootstrap.sh`, `check-doc-drift.sh`,
`discover-unintegrated-docs.sh --hook`, `hooks/hooks.json`, section *Signaux de démarrage* dans
`AGENT.md`, 2 nouvelles suites de tests. Module `dev-orchestrator` **v2.6.0** (collision de version
avec la Phase 16 concurrente, qui avait déjà pris v2.5.0 — cible ajustée v2.5.0 → v2.6.0, commit
`5a8b6a8`).

**SC5 (advisory / lecture seule) — CONFORME**, prouvé par exécution : seul `mktemp` du module
(`discover-unintegrated-docs.sh:91-93`) apparié à un `trap ... EXIT`, borné à `$TMPDIR` ; aucun
`exit 1` (seuls 0/3/64, `set -uo pipefail` sans `set -e`) ; aucun blocage de tour (`hooks.json` =
un seul groupe `SessionStart`, chaque commande suffixée `|| true`) ; 5 fixtures de frontmatter
hostiles (injection shell, octet de contrôle 0x01, délimiteur tronqué, `$(whoami)`) → stdout vide et
exit 3 dans les 5 cas ; `node_modules` 20 000 fichiers → 0.007s (élagage `-prune` confirmé).

**SC6 (portabilité macOS ET Linux) — PROUVÉ** : compteurs identiques sur macOS bash 3.2.57, Debian 12
bash 5.2.15, Ubuntu 24.04 bash 5.2.21 (OS exact de `runs-on: ubuntu-latest`) — `test-check-dev-bootstrap.sh`
23 ok/0 ko · `test-check-doc-drift.sh` 21 ok/0 ko · `test-discover-unintegrated-docs.sh` 22 ok/0 ko.
Aucun test sauté silencieusement, aucun edit de `ci.yml` nécessaire.

**Comblement post-exécution** (commit `6e33b14`, après fusion des verdicts gate portabilité + audit
advisory) : cas 7 de `test-discover-unintegrated-docs.sh` rendu discriminant (tautologique — vert
avec ou sans le filtre glob, prouvé par mutation) ; boucle T21 de `test-dev-orchestrator.sh` élargie
à `discover-unintegrated-docs.sh`, seul des 3 scripts à utiliser `mktemp`.

**Reste-à-faire assumé** : la **release racine + tag** est hors du mandat de la mission — réservée à
validation humaine. Pré-requis identifié : `scripts/check-version-sync.sh` est rouge (README/README.fr
annoncent « 39 suites » contre 41 réelles). Deux dettes constatées et inscrites à `CONCERNS.md` (non
corrigées, hors mandat de clôture) : le verrou de driver est déclaratif et non contraignant ; le gate
ADR-044 est un faux vert dans son invocation nue prescrite par la spec.

Plans:
**Wave 1**

- [x] 17-01-PLAN.md — Tranche traçante : `check-dev-bootstrap.sh` (continuum à 4 états) + fragment `hooks/hooks.json`, prouvé de bout en bout sur ce dépôt (vague 1)

**Wave 2**

- [x] 17-02-PLAN.md — Expansion : `check-doc-drift.sh` (seuil réglable, silence hors git) + `discover-unintegrated-docs.sh --hook` strictement additif (vague 2)

**Wave 3**

- [x] 17-03-PLAN.md — Doctrine `AGENT.md`, gates T20/T21 falsifiables (ADR-044, SC5), preuve de portabilité Linux en conteneur, module `v2.6.0` (vague 3)

### Phase 18: Survie du ledger d'exigences à la clôture de jalon

> **Périmètre réduit le 2026-07-28** par l'étude d'implémentation
> `.planning/phases/VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon/STUDY.md` (verdict
> **GO-RÉDUIT**). L'intitulé précédent — *Capability living-specs (conventions OpenSpec)* — et ses
> quatre briques (grammaire delta ADDED/MODIFIED/REMOVED/RENAMED, ledger indexé par capability,
> ancrage overlay `.gsd/capabilities/` @ `ship:post`, skill de spec-sync agent-driven) sont
> **écartés**, pour trois raisons prouvées : le plan créait un quatrième registre sans en retirer
> aucun (`ROUT-01` existe déjà en 3 copies) ; il volait à OpenSpec le chemin agent-driven
> (`/opsx:sync`) sans les ~2 253 lignes et 16 garde-fous du chemin `archive` déterministe qui le
> rattrapent ; et l'ancrage `ship:post`, bien que réel en gsd-core 1.8.0, ne fire que dans
> `/gsd-ship` — chemin que ce repo n'emprunte jamais — avec `onError: skip` masquant les échecs et
> le gate `bundleContentHash` désarmant la capability à la première édition du bundle.

**Goal**: Faire **survivre les exigences à la clôture de jalon** — un fichier qui existe déjà, aucun
nouveau registre, aucune nouvelle grammaire, aucun overlay. Fait porteur (STUDY §7.1) :
`gsd-complete-milestone` exécute `git rm .planning/REQUIREMENTS.md` **inconditionnellement** (aucun
flag, aucune gate, aucun `--keep-requirements` — `complete-milestone.md:474, 527, 530, 786`) et
`new-milestone.md:475` le régénère de zéro au jalon suivant. Conséquence : **aucun lab GSD conforme
n'a de réponse durable à « qu'est-ce que ce système garantit aujourd'hui ? »** — seulement une pile
d'archives par jalon jamais fusionnées ; le `REQUIREMENTS.md` à 5 blocs de ce repo est une déviation
manuelle non reproductible ailleurs. La phase livre trois choses (STUDY §7.2) : (1) un **gate
machine** `check-requirements-survival.sh` dans `plugin/dev-orchestrator/scripts/`, sur le modèle de
`check-doc-drift.sh`, en **détection d'absence uniquement** — jamais « n'a pas bougé », heuristique
que `check-doc-drift.sh` se refuse explicitement en en-tête ; (2) une **ligne de doctrine** dans
`plugin/dev-orchestrator/AGENT.md` (« à la clôture de jalon, le ledger d'exigences survit ; l'archive
est un instantané, pas un déménagement ») ; (3) une **RFC upstream** vers `open-gsd/gsd-core` rendant
la suppression optionnelle. La variante réduit le double état existant au lieu d'en ajouter : les
archives `.planning/milestones/*-REQUIREMENTS.md` deviennent explicitement des instantanés, donc
`.planning/REQUIREMENTS.md` redevient la seule source vivante.

**⚠ Dépendance bloquante — la RFC conditionne le GO, pas le code** (STUDY §7.2 encadré, condition
**D3**) : le levier qui rend le geste durable est **chez un tiers**. Sans elle, le moteur supprime le
fichier à chaque clôture et le gate échoue — VibeFlow planterait un piquet **contre sa propre chaîne
d'outils**, cas interdit par l'Iron Law 2 (`plugin/conductor/AGENT.md:114`, « Router, jamais
réimplémenter »). **La RFC part avant toute implémentation du gate.** Si elle est refusée ou reste
sans réponse au **2026-10-26**, la phase est intégralement ré-arbitrée : doctrine seule sans machine,
ou conflit récurrent assumé.

**Requirements**: TBD (à dériver au cadrage)
**Depends on:** Phase 17
**Success Criteria** (what must be TRUE):

  1. La RFC est **déposée** sur `open-gsd/gsd-core` (suppression de `REQUIREMENTS.md` rendue
     optionnelle) **avant** que le gate ne soit posé, et son issue/PR est traçable depuis le repo.

  2. `check-requirements-survival.sh` échoue si `.planning/MILESTONES.md` déclare un jalon clos alors
     que `.planning/REQUIREMENTS.md` est **absent** — et **ne prétend jamais** qu'un fichier présent
     mais figé serait périmé (pas de récidive de l'heuristique neutralisée en Phase 17).

  3. Le gate est **falsifiable, prouvé par mutation** : sa suite de tests échoue si on le neutralise
     (convention du module : ~1,5× la taille du script testé, cf. `test-check-doc-drift.sh`).

  4. La doctrine est écrite dans `plugin/dev-orchestrator/AGENT.md` et le rôle d'**instantané** des
     archives `milestones/*-REQUIREMENTS.md` est explicite — `.planning/REQUIREMENTS.md` désigné
     comme seule source vivante.

  5. **Aucun objet nouveau dans le socle** : zéro fichier de registre créé, zéro grammaire de merge
     introduite, zéro overlay `.gsd/capabilities/`. Gouvernance conductor tenue (`check-agents.sh`
     vert, densité ADR-029), portabilité macOS + Linux prouvée par exécution.

  6. Module `dev-orchestrator` bumpé, release racine + tag annoté poussé (discipline `CLAUDE.md`),
     `check-release-tag.sh --remote` ✓.

**Chiffrage** (STUDY §7.3) : ≈ **370-470 lignes**, 1 module bumpé — contre ≈ 1 300-2 000 lignes et
5 objets à maintenir pour la version complète écartée. Soit **25-30 % du coût**.

**Bénéfice explicitement NON capté** — à ne pas revendiquer : l'**indexation par capability**. Un
`REQUIREMENTS.md` qui survit reste indexé **par jalon** ; répondre à « que garantit le routage
aujourd'hui ? » exigera toujours de réconcilier `ROUT-01..04`, `VERB-02` (« caduc depuis v2.33.0 »)
et `PROJECT.md:84`. Cette part du besoin reste ouverte et peut être rouverte plus tard sous les
conditions **E1/E2** du STUDY §8 — pas déclarée sans objet.

**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 18 to break down)

### Phase 19: Migration du moteur GSD pilotée par /vf-update

> **Origine — audit externe vérifié sur pièce le 2026-07-28**, mené sur un second poste (lab
> `ExploreSomfy`, scope user) : `.planning/missions/2026-07-28-audit-externe-migration-opengsd.md`.
> Les cinq constats ont été **recoupés ligne à ligne** dans ce repo avant ouverture de la phase.

**Goal**: Faire que la migration `get-shit-done-cc` → `@opengsd/gsd-core` livrée en **v2.39.0**
atteigne les **postes déjà équipés**, et pas seulement les installations neuves. Fait porteur : sur
un poste à jour côté plugin (**2.42.0**, cache rafraîchi), le moteur était toujours
`~/.claude/get-shit-done/VERSION` = **1.42.3** posé le 16/07 — **12 jours après l'install initiale et
2 jours après la livraison de la migration**. Le poste portait le *code* de la migration sans en
porter l'*effet*, et rien dans l'interface ne le disait. Trois causes enchaînées, toutes vérifiées
dans ce repo : (a) `ensure-deps.sh:119-120` — `detect_gsd()` renvoie vrai sur le VERSION file legacy
via un `||` écrit pour la tolérance dual-layout (D-01/D3, Phase 10), et `:133` en fait un `skip`,
donc **même appelé, le script sauterait la migration** ; (b) aucun chemin de mise à jour n'appelle
`ensure_gsd()` — `vf-update/SKILL.md` §Garde-fous place explicitement le moteur **hors périmètre**
(« la chaîne d'outils interne a sa propre mise à jour »), frontière que cette phase révise puisque
la version du moteur est décidée par VibeFlow (`@^1`, `ensure-deps.sh:166`) ; (c)
`log_legacy_cleanup_if_needed()` (`:184`) n'est appelé que depuis `ensure_gsd()`, donc joignable
uniquement par `/vf-init` et `/vf-calibrate` — **un garde-fou correct sur un chemin que le régime
nominal n'emprunte jamais**, exactement le motif déjà rencontré ailleurs.

**Piège de version à écrire noir sur blanc** : le fork **repart de zéro** —
`get-shit-done-cc 1.42.3` (déprécié, figé) contre `@opengsd/gsd-core 1.8.0` (vivant). **1.8.0 <
1.42.3 en semver.** La doctrine « ne jamais downgrader » du skill `vf-update`, saine partout
ailleurs, interdirait précisément le geste à faire. La migration se décide donc sur le **nom du
paquet et le layout du dossier**, jamais sur la comparaison des numéros. Nuance portée au rapport
d'origine : `check-plugin-update.sh` ne compare que les **tags GitHub du plugin VibeFlow**, jamais un
numéro de moteur — il n'y a donc **aucun comparateur en défaut aujourd'hui**, le piège concerne le
détecteur qui reste à écrire.

**Effet de bord à couvrir dans le même geste** : l'installeur amont `gsd-core` réécrit
`agents/gsd-executor.md` et classe l'injection ADR-051 en « local patch » — `mcp__XcodeBuildMCP__*`
**disparaît du `tools:`**. `ensure-deps.sh:248` (`patch_gsd_executor_mcp`, `--force`, idempotent) sait
la restaurer, mais `_internal/vibeflow-update.sh:268` n'injecte que dans les agents flaggés
`vf-mcp-consumer` — flag que `gsd-executor` **ne porte pas** (fichier hors plugin, `:268` de
`ensure-deps.sh`). Deux chemins, une seule couverture : toute migration automatique du moteur doit
**enchaîner** sur la ré-injection, sinon l'exécutant perd silencieusement son accès MCP.

**Requirements**: TBD (à dériver au cadrage)
**Depends on:** aucune — **indépendante de la Phase 18**, dont le GO est suspendu à une RFC upstream
`open-gsd/gsd-core`. La Phase 19 ne touche ni au ledger d'exigences ni à `gsd-complete-milestone`.
**Success Criteria** (what must be TRUE):

  1. `detect_gsd()` renvoie un **état à trois valeurs** — `absent` / `legacy` / `gsd-core` — et
     « legacy » est **actionnable**, plus jamais un `skip`. La décision se prend sur le layout et le
     nom du paquet ; **aucune comparaison de numéros** n'entre dans le classement.

  2. `/vf-update` **dit l'état du moteur** dans le même récapitulatif que le plugin et les modules,
     et propose la migration comme **une ligne de plus dans la confirmation `AskUserQuestion`
     existante** (ADR-031). Refus accepté sans effet de bord ; **aucune migration silencieuse**.

  3. Toute installation ou réinstallation du moteur **enchaîne** sur `inject-mcp-tools.sh --force`
     pour `gsd-executor`, avec **vérification après coup** : si le `tools:` final ne contient pas les
     serveurs déclarés dans le `.mcp.json` du lab, c'est dit fort.

  4. Le message de nettoyage legacy est **atteignable** en régime nominal et **exact** : `npm
     uninstall -g` n'est proposé que si le paquet est réellement installé en global (constaté faux
     sur le poste audité : install `npx`, jamais globale), et le retrait de l'arborescence vide
     laissée debout par l'installeur est inclus.

  5. **Tests de non-régression** : le couple exact `1.42.3 → 1.8.0` est classé « à migrer » ; et un
     test de cohabitation couvre le **scénario réel** — poste legacy déjà installé + plugin à jour →
     migration **détectée**. La suite `test-gsd-cohabitation.sh` livrée en v2.39.0 ne teste que le
     merger `settings.json`, sinon le trou aurait été vu.

  6. **Repli legacy préservé** : la cascade à 4 niveaux de `detect-gsd-engine.sh` /
     `build-gsd-index.sh` continue de fonctionner pour les postes non encore migrés — c'est le
     **skip** qu'on corrige, pas le repli. Plafond `@^1` **inchangé**.

  7. Gouvernance tenue : `check-agents.sh` vert, densité ADR-029, portabilité macOS + Linux prouvée
     par exécution, module bumpé, release racine + tag annoté poussé, `check-release-tag.sh
     --remote` ✓.

**Hors périmètre, décidé** : aucun **hook `SessionStart` supplémentaire** sur l'état du moteur. Le
signal passe par `/vf-update`, pas par une ligne de plus au démarrage de chaque session.

**Doctrine à réviser** : la frontière de périmètre de `vf-update/SKILL.md` §Garde-fous (« la chaîne
d'outils interne a sa propre mise à jour — hors périmètre ») devient fausse et doit être réécrite —
ADR à créer, c'est un **changement de doctrine**, pas un correctif de configuration.

**Plans:** 2/3 plans executed

Plans:

- [x] 19-01-PLAN.md — Gate `check-gsd-engine.sh` : détection à 3 états (layout/nom de paquet, jamais les numéros), contrat de sortie 0/2/3, suite dédiée + preuve Linux (vague 1)
- [x] 19-02-PLAN.md — `ensure-deps.sh` : détecteur à 3 valeurs, fin du skip sur legacy, chemin `--migrate-engine` chaîné sur la ré-injection MCP, message de nettoyage exact ; `inject-mcp-tools.sh --verify` (vague 1)
- [ ] 19-03-PLAN.md — `vf-update/SKILL.md` : diagnostic à deux volets et ligne de confirmation moteur ; ADR-058 ; release-meta `dev-orchestrator` v2.7.0 + `conductor` v1.16.0 (vague 2, dépend de 19-01 et 19-02)
