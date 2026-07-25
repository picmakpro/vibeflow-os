# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- ✅ **install-ux-v1.0** — Phases 2-6 — clôturé 2026-06-05 (plugin + skill à toggles + scope) — release `v2.4.0`
- ✅ **dev-doctrine** — Phases 7-8 — doctrine dev (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) + consolidation des doublons qualité — clôturé 2026-07-07 — release `v2.20.0`
- 🔬 **memory-swarm-rnd** — Phase 9 — R&D : transposition du modèle mémoire + patterns swarm de jcode (spike, pas release)
- 🚧 **gsd-migration** — Phases 10-11 — migration du package GSD `get-shit-done-cc` → `@opengsd/gsd-core` (VOC-02) : étude de faisabilité + go/no-go, puis intégration outillée
- 🚧 **vf-routing** — Phases 12-14 — routage fin des intentions vers les verbes `/vf-*`, couverture complète des skills GSD, pont spec → feuille de route, et frontière d'altitude avec le moteur de planning GSD

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

### 🚧 Routage fin & verbes VibeFlow (Phases 12-13)

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

#### Phase 13: Pont spec → feuille de route (`/vf-ingest`)
**Goal**: Outiller le passage d'un cadrage écrit aux étapes de la feuille de route — une spec devient des
étapes + des exigences, un plan devient le plan d'une étape — en déléguant aux moteurs GSD existants et
sans contourner leurs garde-fous.
**Depends on**: Phase 12 (le verbe suppose le gabarit de description et la rule de préséance en place)
**Requirements**: BRDG-01, BRDG-02, BRDG-03
**Success Criteria** (what must be TRUE):
  1. `/vf-ingest` traite les deux grains : spec → `gsd-ingest-docs --mode merge` (étapes + exigences),
     plan → `gsd-import --from` (PLAN.md d'une étape) — sans réimplémenter de parseur maison.
  2. Le verbe découvre les specs/plans non encore intégrés (chemin absent de `ROADMAP.md`), détecte le grain
     et construit le manifest YAML : l'utilisateur n'écrit jamais de manifest à la main.
  3. Gate BLOCKER jamais contourné, confirmation humaine avant toute écriture dans `.planning/` (ADR-031),
     `--mode merge` par défaut sur projet existant, cap 50 documents signalé.
  4. `vf-brainstorm` propose `/vf-ingest` en fin de cadrage — le cycle `vf-brainstorm → vf-ingest → vf-plan
     → vf-execute` est bouclé, plus aucune spec orpheline.
  5. Release livrée : CHANGELOG/README des deux modules à jour, bump racine + **tag annoté poussé**
     (`scripts/check-release-tag.sh --remote` → ✓).
**Plans**: à cadrer (`/gsd:discuss-phase 13` puis `plan-phase`)

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
- [x] 14-06-PLAN.md — release : module v2.4.0, racine v2.29.0, tag annoté poussé (ALTI-05)

## Progress

**Execution Order:**
1 ✅ → 2 ✅ → 3 ✅ → 4 ✅ → 5 ✅ ; 6 ✅ indépendant → 7 ✅ → 8 ✅ ; **9 🔬 (R&D, hors release)** ; **10 🚧 → 11 🚧 (GATE : 11 conditionné au GO de 10)** ; **12 ✅ → 13 🚧** ; **14 ✅ (indépendante)**

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
| 9. Spike transposition jcode | memory-swarm-rnd | 0/2 | Not started (R&D) | — |
| 10. Étude & faisabilité migration GSD | gsd-migration | 0/? | Not planned yet | — |
| 11. Intégration migration GSD | gsd-migration | 0/? | Not planned yet (GATE Phase 10) | — |
| 12. Routage fin & verbes /vf-* | vf-routing | 6/6 | Complete — release `v2.31.0` | 2026-07-25 |
| 13. Pont spec → feuille de route | vf-routing | 0/? | Not planned yet (dépend Phase 12) | — |
| 14. Frontière d'altitude planning-core / GSD | vf-routing | 7/7 | Complete — release `v2.30.0` (ADR-055) | 2026-07-25 |
