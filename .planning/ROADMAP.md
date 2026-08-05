# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- ✅ **install-ux-v1.0** — Phases 2-6 — clôturé 2026-06-05 (plugin + skill à toggles + scope) — release `v2.4.0`
- ✅ **dev-doctrine** — Phases 7-8 — doctrine dev (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) + consolidation des doublons qualité — clôturé 2026-07-07 — release `v2.20.0`
- ✅ **memory-swarm-rnd** — Phase 9 — R&D : transposition du modèle mémoire + patterns swarm de jcode — spike GO, shippé `v2.28.0` (ADR-052 mémoire vivante + ADR-053 swarm)
- ✅ **gsd-migration** — Phases 10-11 — clos 2026-07-26, release `v2.39.0` — migration du package GSD `get-shit-done-cc` → `@opengsd/gsd-core@^1` (VOC-02)
- ✅ **vf-routing** — Phases 12-14 — clos 2026-07-26, release `v2.37.0` — routage fin des intentions (verbes `/vf-*` à l'origine ; carte d'intention agentique depuis la bascule v2.33.0), couverture complète des skills GSD, pont spec → feuille de route, et frontière d'altitude avec le moteur de planning GSD
- 🚧 **gsd-alignement** — Phases 23-25 — **ouvert le 2026-08-01**, aucune phase démarrée — couplage explicite au moteur GSD, activation des capacités dormantes, budget d'instructions

> **Origine des Phases 23 à 25, dite franchement.** Elles ont été inscrites au ROADMAP le
> 2026-07-31 par une session concurrente, **hors du périmètre confié** à la mission qui tournait
> alors (« fin de Phase 20 + toute la Phase 21 »), et poussées dans la PR #23 sans avoir été
> commandées. Le contenu a été jugé sérieux et **conservé** sur arbitrage de Samuel le
> 2026-08-01 ; ce jalon existe pour qu'elles cessent d'être des clandestines rattachées à
> aucun milestone. Leur ouverture reste soumise au cadrage normal (`gsd-discuss-phase`) —
> être inscrite au ROADMAP ne vaut pas feu vert d'exécution.

## Phases

### État des phases — checklist lue par le moteur

> **Ne pas retirer.** C'est la SEULE forme que `@opengsd/gsd-core` lit pour établir qu'une phase
> est terminée (`roadmap.cjs` → `checkboxPattern`) ; il la coche lui-même à la clôture d'une phase
> vérifiée. La table `## Progress` plus bas, elle, n'est lue par aucun outil : elle est rédigée
> pour les humains et les deux doivent rester d'accord.
>
> Cette checklist a été posée le 2026-08-01, après coup : le ROADMAP n'en avait jamais eu, si bien
> que le moteur voyait **zéro** phase terminée et rendait des compteurs faux
> (`completed_phases: 10`, `current_phase: 19` alors que la 22 était livrée). C'est aussi ce qui
> rattrape les **20 plans sans SUMMARY** des Phases 11 à 14 : `roadmap.cjs` fait explicitement
> primer la case cochée sur le disque, « pour les phases terminées avant le tracking GSD, qui
> n'ont pas les paires PLAN/SUMMARY ». Ces 4 phases sont shippées, chacune avec sa release.

- [x] Phase 1: dev-orchestrator (completed 2026-06-04)
- [x] Phase 2: Manifeste & résolveur (completed 2026-06-04)
- [x] Phase 3: Engine scope-aware (completed 2026-06-05)
- [x] Phase 4: Skill /vibeflow-install + auto-lancement (completed 2026-06-05)
- [x] Phase 5: Packaging plugin (completed 2026-06-05)
- [x] Phase 6: dev-orchestrator first-use (completed 2026-06-05)
- [x] Phase 7: Philosophies de dev (completed 2026-07-07)
- [x] Phase 8: Consolidation des doublons (completed 2026-07-07)
- [x] Phase 9: Spike transposition jcode (mémoire + swarm) (completed 2026-07-22)
- [x] Phase 10: Étude & faisabilité migration GSD (completed 2026-07-26)
- [x] Phase 11: Intégration migration GSD (completed 2026-07-26)
- [x] Phase 12: Routage fin & couverture complète des verbes (completed 2026-07-25)
- [x] Phase 13: Pont spec → feuille de route (completed 2026-07-26)
- [x] Phase 14: Frontière d'altitude planning-core / moteur GSD (completed 2026-07-25)
- [x] Phase 15: Collaboration inter-équipes dev ↔ design (completed 2026-07-27)
- [x] Phase 16: Cloisonnement complet des dispatches d'agents (completed 2026-07-27)
- [x] Phase 17: Signaux de démarrage du moteur de dev (completed 2026-07-28)
- [ ] Phase 18: Survie du ledger d'exigences à la clôture de jalon
- [x] Phase 19: Migration du moteur GSD pilotée par /vf-update (completed 2026-07-28)
- [x] Phase 20: Fluidité du flux de dev sans perte de qualité (completed 2026-07-31)
- [x] Phase 21: Alignement du moteur GSD sur gsd-core 1.9.0 (completed 2026-07-31)
- [x] Phase 22: Hygiène documentaire — doctrine de sortie et captation d'intention (completed 2026-07-31)
- [x] Phase 23: Couplage explicite au moteur GSD — capabilities, flags et voie unique
- [x] Phase 24: Activation et mesure du moteur GSD — capacités dormantes et faits de runtime (completed 2026-08-05, PR #34)
- [ ] Phase 25: Budget d'instructions et étage d'alignement court
- [x] Phase 26: Manuel utilisateur VibeFlow (manual/) (completed 2026-08-02)
- [ ] Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture

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
1 ✅ → 2 ✅ → 3 ✅ → 4 ✅ → 5 ✅ ; 6 ✅ indépendant → 7 ✅ → 8 ✅ ; **9 ✅ (R&D, shippée v2.28.0)** ; **10 🚧 → 11 🚧 (GATE : 11 conditionné au GO de 10)** ; **12 ✅ → 13 ✅ (code complet, release en attente de validation humaine)** ; **14 ✅ (indépendante)** ; **15 ✅ (shippée v2.40.0) → 16 ✅ (shippée v2.41.0)** ; **17 ✅ (indépendante de 16, terminée et vérifiée — release en attente de validation humaine) → 18 inscrite (dépend de 17)** ; **19 ✅ (2026-07-28, ADR-058) → 20 ✅ (mergée dans `main` le 2026-07-31, PR #21, release `v2.44.0`)** — ce merge **satisfait** la dépendance « Phase 20 requise » de 21, 22 et 23 ; **21 ✅ (mergée le 2026-07-31, PR #22, release `v2.45.0`) + 22 ✅ (mergée le 2026-07-31, PR #23)** — les deux livrées par la mission `reprise-p21-p22`, sans fichier commun ; leur clôture **lève la dépendance** de 23 → **23 inscrite**, périmètre partagé sur `vf-dev-manager.md` / `intent-routing.md` (arbitré le 2026-07-31 : on ne planifie pas contre une base qui bouge ; l'arbitrage des étages de revue écrit par la 21 fait autorité) → **24 inscrite (dépendance doctrinale de 23, aucun fichier commun ; son lot MESURE est déjà rendu)** → **25 inscrite : après 24** (son volet G1 pose un gate sur `plugin/*/agents/*.md`, les fichiers mêmes que M3/`effort:` et A2/`agent_skills` éditent) **et dépendante de 23** (son volet G2 insère un étage dans `discuss → plan`, dont la voie unique d'invocation est arbitrée en 23)

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
| 18. Survie du ledger d'exigences | — | 0/0 | Inscrite — périmètre réduit le 2026-07-28 par `18-STUDY.md`, non planifiée | — |
| 19. Migration du moteur GSD par /vf-update | — | 3/3 | Complete — 3 plans exécutés, VERIFICATION produite, module `dev-orchestrator` v2.7.0 + `conductor` v1.16.0, ADR-058 | 2026-07-28 |
| 20. Fluidité du flux de dev sans perte de qualité | — | 7/7 | Complete — **mergée dans `main`** (PR #21, `d549b2d`), release `v2.44.0`, VERIFICATION produite | 2026-07-31 |
| 21. Alignement du moteur GSD sur gsd-core 1.9.0 | — | 5/5 | Complete — **mergée dans `main`** (PR #22, `d89a60e`), release `v2.45.0`, VERIFICATION produite, ADR-061/062/063 | 2026-07-31 |
| 22. Hygiène documentaire — doctrine de sortie | — | 3/3 | Complete — **mergée dans `main`** (PR #23, `474c3eb`), `dev-orchestrator` v2.9.0 + `design-orchestrator` v1.4.0 | 2026-07-31 |
| 23. Couplage explicite au moteur GSD | gsd-alignement | 8/8 | In Progress|  |
| 24. Activation et mesure du moteur GSD | gsd-alignement | 0/0 | Inscrite — lot MESURE : M2 **rendu** le 2026-07-31, M1/M3 à instruire ; lot ACTIVATION : 8 items | — |
| 25. Budget d'instructions et étage d'alignement court | gsd-alignement | 0/0 | Inscrite — G1 (compteur d'instructions dans `check-agents.sh`) après 24 ; G2 (outline court `discuss`→`plan`) dépend de 23 | — |

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

**Plans:** 3/3 plans executed

Plans:

- [x] 19-01-PLAN.md — Gate `check-gsd-engine.sh` : détection à 3 états (layout/nom de paquet, jamais les numéros), contrat de sortie 0/2/3, suite dédiée + preuve Linux (vague 1)
- [x] 19-02-PLAN.md — `ensure-deps.sh` : détecteur à 3 valeurs, fin du skip sur legacy, chemin `--migrate-engine` chaîné sur la ré-injection MCP, message de nettoyage exact ; `inject-mcp-tools.sh --verify` (vague 1)
- [x] 19-03-PLAN.md — `vf-update/SKILL.md` : diagnostic à deux volets et ligne de confirmation moteur ; ADR-058 ; release-meta `dev-orchestrator` v2.7.0 + `conductor` v1.16.0 (vague 2, dépend de 19-01 et 19-02)

### Phase 20: Fluidité du flux de dev sans perte de qualité

> **Origine — second rapport de l'audit externe du 2026-07-28** (même lab `ExploreSomfy`, tranche de
> dev iOS en 5 lots dont 2 parallélisés par worktrees, ~90 commits, suite passée de 177 à 331
> tests) : `.planning/missions/2026-07-28-audit-externe-fluidite.md`. **Les 4 constats ont été
> vérifiés sur pièce le 2026-07-28** avant ouverture — 3 confirmés (dont 2 plus solidement que le
> rapport ne l'affirme), 1 **partiellement daté**. Découpage arbitré par Samuel : **une phase
> unique** pour les 4 changements, contre la recommandation de scinder le changement 2.

**Goal**: Rendre le flux de dev **plus rapide et plus fluide sans perdre en qualité**, par quatre
changements indépendants dont deux touchent la doctrine. Deux garde-fous non négociables encadrent
toute la phase, tirés des chiffres de l'audit :

- **Ne jamais réduire le nombre de tests.** Mesuré : sur 90 s de `test_sim`, les tests pèsent ~1 s,
  tout le reste est compilation et installation. Levier nul.

- **Ne jamais alléger la revue sur le chemin critique produit** — 5 bloquants y ont été trouvés en
  une journée, dont un qui cassait le geste le plus fréquent de la démo.

- **Aucun allègement ne s'applique jamais à un diff de comblement.** Sur cette tranche, **9 fois,
  puis 5, puis 4 défauts sont nés des correctifs de revue eux-mêmes**. Une re-revue reste pleine,
  quelle que soit la nature du lot d'origine.

**Changement 1 — `mcp__XcodeBuildMCP__*` à `vf-reviewer`, et révision d'ADR-051.**
`docs/ADR.md` §ADR-051 porte la prémisse contestée mot pour mot : « les agents de planif/revue/audit
(`vf-dev-manager`, `vf-reviewer`, `vf-auditer`) restent inchangés (moindre privilège — **ils ne
compilent jamais**) ». Elle confond **produire** un verdict de compilation et **en vérifier** un :
un relecteur n'a pas besoin de compiler pour livrer, il en a besoin pour ne pas *croire* un message
de commit (constaté : « la revue de phase a dû croire un message de commit »). `vf-reviewer` a déjà
`Bash`, l'outil le plus large — il ne lui manque pas l'outil dangereux, il lui manque l'outil
sanctionné, alors que le `CLAUDE.md` du lab interdit `xcodebuild` en shell.
**Fait vérifié dans ce repo, plus grave que le rapport ne le dit** — le moindre privilège invoqué
n'existe déjà plus, `memory: project` rouvrant `Write`/`Edit` au runtime :

| Agent | `tools:` déclaré sur disque | `tools:` au runtime |
|---|---|---|
| `vf-reviewer` | `Read, Bash, Glob, Grep, Agent(gsd-code-reviewer)` | + **`Write, Edit`** |
| `vf-auditer` | `Read, Bash, Glob, Grep, Agent(gsd-security-auditor)` | + **`Write, Edit`** |
| `vf-design-judge` | `Read, Bash, Glob, Grep` | + **`Write, Edit`** |

Le cas de `vf-design-judge` dépasse le constat d'origine : sa **description** affirme « Ne corrige
JAMAIS rien — **sans Write ni Edit** » — une barrière que le runtime ne pose pas, et cette phrase
est lue par les agents qui le dispatchent. Le « je juge, je ne corrige pas » est une consigne de
prompt, pas une barrière.
**À instruire AVANT de livrer, par le test et non par la supposition** : ADR-051 établit que
`mcp__*` est refusé en allowlist et que seule la forme par-serveur `mcp__<serveur>__*` est admise —
il ne dit **rien** du nom d'outil exact. Si une allowlist fine (`test_sim` / `build_sim` seulement)
passe dans le `tools:` d'un subagent, elle est préférable au wildcard. **Coût à assumer et à
écrire** : un relecteur qui peut lancer les tests va les lancer — +90 s par revue et un slot de
simulateur consommé.

**Changement 2 — sortir la revue de `vf-coder` et la graduer par RISQUE.**
Défaut de **placement**, pas de doctrine. `vf-dev-manager.md:93-94` sait déjà graduer (« une étape UI
saute l'audit sécurité ; une étape sécurité le garde ») et l'audit est conditionnel (`:103`). La
revue, elle, est **en dur à l'étape 4 du cycle interne de `vf-coder`** (`vf-coder.md:34`, sans
condition). **Fait vérifié qui verrouille le diagnostic** : `vf-dev-manager.md:108` interdit
explicitement au manager d'en ajouter une — « **Pas de double revue** : si le rapport typé de
`vf-coder` est `passed` avec verdict revue PASS, ne re-dispatche pas de revue de code ». La revue est
donc le seul étage à la fois **obligatoire et hors de portée du manager**.
La seule gradation existante est indexée sur le **volume** : `SEUIL_EQUIPE = 3`
(`mission-contracts.md:105`) compte des étapes restantes. Mauvais axe — trois lignes sur un chemin
BLE partagé sont minuscules et à très haut risque ; 400 lignes de Domain pur prouvées par mutation
sont grosses et à bas risque.
**Rendement observé par nature de lot** (aucun rattrapable par les tests, sauf la dernière ligne) :

| Nature du lot | Bloquants trouvés |
|---|---|
| Adaptateur matériel (non injectable, non testable) | 3 |
| Contrôleur partagé entre features | 3 |
| **Jointures entre lots parallèles** | **4 bloquants + 9 majeurs** — « aucun relecteur cadré sur un seul lot ne les aurait vus » |
| Geste utilisateur / géométrie de vue | 3 (trouvés par géométrie et capture d'écran) |
| **Domain pur avec tests de mutation** | **0** — terrain le mieux couvert |
| Documentation / catalogue de chaînes | 0 bug, mais 2 faits faux bloquants pour la mission suivante |

**Changement 3 — `.planning/MISSION-INVARIANTS.md`.**
Le constat incrimine son auteur, et les deux faits qui le fondent sont vérifiés :
`mission-contracts.md` dit bien « le brief ne porte QUE ce qui n'est pas sur disque, il ne paraphrase
jamais `ROADMAP.md`/`STATE.md`/`PROJECT.md` », et `vf-dev-manager.md:29` lit déjà le `CLAUDE.md` du
projet avec préséance. Recopier les conventions à la main dans chaque brief duplique donc ce que la
machine lira de toute façon — et c'est cette recopie qui a produit une contradiction interne à
corriger en cours de mission. **Le gabarit n'a pas manqué : il a été court-circuité.**
Mais **trois invariants ne vivent nulle part sur disque** et aucun agent ne peut les deviner : le
**seuil de tests courant** (mouvant : 177 → 331 en une journée) ; la **table des fichiers gelés** par
mission en vol ; les **motifs de risque récurrents** du projet (« la neuvième occurrence du motif de
la phase » — donc connu, mais écrit nulle part). Le fichier reste court, relu par le manager au même
titre que `STATE.md` ; le brief garde ses champs minimaux.
**Coût à écrire noir sur blanc : s'il ment, il est pire que rien** — précédent réel d'un `CLAUDE.md`
affirmant encore « deux trous interdisent toute installation device » alors que la mission suivante
devait recetter sur device. **Prévoir comment il est tenu à jour, ou ne pas le créer.** Sa table des
fichiers gelés alimente directement le critère (b) du changement 2.

**Changement 4 — scope des hooks de conformité. ⚠ CONSTAT PARTIELLEMENT DATÉ.**
**La moitié demandée est déjà livrée** : l'option d'exclusion existe et `gsd-` est son **défaut** —
`check-agents.sh` §Usage (`--third-party-prefix=PFX`, répétable) et `:84`
(`THIRD_PARTY_PREFIXES="gsd-"`), livrés en **Phase 16 / v2.41.0 le 2026-07-27**, soit la veille du
rapport. **Mesuré le 2026-07-28** sur `~/.claude/agents` avec la version du repo (identique à celle
installée) : **23 lignes, pas 68** — 21 warnings **tous sur des agents `vf-*`**, 34 agents tiers
`gsd-*` écartés proprement, **zéro finding `gsd-`**. Le motif du refus du 28/07 (« 68 lignes dont 66
de bruit ») ne tient plus. La phase ne doit donc **pas** créer un `--exclude=GLOB` redondant.
**Ce qui reste vrai et non corrigé** : `check-agents.sh:78` fixe `AGENTS_DIR=".claude/agents"`
**relatif au cwd**, le hook `SessionStart` de `conductor/hooks/hooks.json` appelle
`check-agents.sh --hook` **sans `--agents-dir`**, et un lab en scope user n'a aucun agent dans son
projet. **Vérifié : le hook tel qu'il tourne sort 0 ligne** — le garde-fou de conformité ne regarde
rien. Même diagnostic pour `check-debug-research.sh --hook`. Les deux sont en plus masqués par
`|| true`.
**La conséquence s'inverse** : corriger le scope produirait aujourd'hui **21 warnings de signal
réel** sur les agents que VibeFlow gouverne — dont, précisément, l'écart `tools:` déclaré/runtime du
changement 1. Impraticable le 28/07, praticable maintenant.

**Requirements**: SC1, SC2, SC3, SC4, SC5, SC6, SC7 (les 7 critères de succès ci-dessous servent
d'IDs de traçabilité — aucun ID formel `REQ-` n'existe pour cette phase dans `REQUIREMENTS.md`,
même convention que les Phases 15 à 19 ; numérotation reprise telle quelle par `20-RESEARCH.md`,
`20-VALIDATION.md` et le champ `requirements` de chaque `20-NN-PLAN.md`).
**Depends on:** aucune — indépendante des Phases 18 (bloquée par RFC upstream) et 19 (livrée).
**Success Criteria** (what must be TRUE):

  1. **ADR-051 est révisé** sur ce seul point, avec l'argument explicite « un relecteur ne PRODUIT
     pas de verdict de compilation, il en VÉRIFIE un », et `vf-reviewer` obtient l'accès MCP — **à
     lui seul**, ni `vf-auditer` ni `vf-dev-manager`. La granularité (allowlist fine vs wildcard
     par serveur) est tranchée **par un test réel**, pas par lecture de doc.

  2. **L'écart `tools:` déclaré / runtime est traité, pas seulement constaté** : la description de
     `vf-design-judge` cesse d'affirmer une barrière `Write`/`Edit` que le runtime ne pose pas, et
     le repo dit quelque part que `memory:` rouvre ces outils.

  3. **La revue est un étage de premier rang piloté par le manager**, au même titre que l'audit et
     le test — sans quoi la gradation n'a nulle part où s'appliquer. La règle « pas de double
     revue » (`vf-dev-manager.md:108`) est réécrite en conséquence, pas contournée.

  4. **Les critères de déclenchement sont objectifs, jamais des seuils au jugé** : revue renforcée
     non négociable si le diff touche (a) un adaptateur d'infra non couvert par les tests, (b) un
     fichier partagé avec une mission parallèle en vol, (c) du code que la mutation ne couvre pas,
     (d) un geste utilisateur ou une géométrie de vue. **Revue de jointure obligatoire, en nœud
     séparé**, dès que deux lots parallèles fusionnent — meilleur rendement de toute la tranche,
     étage qui n'existe aujourd'hui que parce qu'il a été créé à la main. Revue allégée réservée au
     Domain pur à mutation verte, à la documentation et aux catalogues sans ajout de clé.
     **En cas de doute, revue pleine** — le classement du lot est un point de décision, donc un
     point d'erreur : le défaut par défaut doit être le sûr.

  5. **`MISSION-INVARIANTS.md` porte les 3 invariants + la contrainte d'outillage du moment**, le
     brief reste à ses champs minimaux, et **son mécanisme de mise à jour est spécifié** — faute de
     quoi le fichier n'est pas créé (critère falsifiable : un invariant périmé doit être détectable).

  6. **Le scope des deux hooks est corrigé** (`check-agents.sh --hook`,
     `check-debug-research.sh --hook`) et le garde-fou devient **silencieux en régime nominal et
     utile sur les dérives** — **sans** créer d'option d'exclusion redondante avec
     `--third-party-prefix`, déjà livrée et déjà réglée sur `gsd-`.

  7. Gouvernance tenue : `check-agents.sh` vert, densité ADR-029, portabilité macOS + Linux prouvée
     par exécution, modules bumpés, release racine + tag annoté, `check-release-tag.sh --remote` ✓.

**Livrable attendu du cadrage** : pour chaque changement — ce qui bouge fichier par fichier, le
gain, **le coût et le risque**, sa réversibilité, et l'ADR à créer ou réviser. **Distinguer
nettement une correction de configuration (changement 4) d'un changement de doctrine (1, 2, 3).**

**Déjà appliqué le 2026-07-28 côté lab, à ne pas refaire** : profils de session XcodeBuildMCP
désactivés (`XCODEBUILDMCP_DISABLE_SESSION_DEFAULTS=true`) — le serveur n'a qu'**un seul
`SessionStore` global** partagé par la fenêtre principale et tous les sous-agents, et `build_sim` /
`test_sim` n'exposaient **aucun paramètre de projet** dans ce mode ; constaté : une exécution
complète partie sur le code d'un autre worktree. **Conséquence à propager : chaque appel de build
doit porter son `projectPath`, son `scheme` et son `simulatorId`/`deviceId`.** Purge du cache
`test-products` (12 Go → 1,3 Go) également faite.

**Piège d'outillage à inscrire dans la doctrine de gate** : un `build_sim` **en cache** (zéro tâche
`SwiftCompile`) annonce « 0 warning » **sans rien compiler**. Un verdict de warnings non précédé
d'un `clean` est structurellement invérifiable.

**Réserve de cadrage, inscrite pour mémoire** : le découpage recommandé était {1,4} (conformité des
agents observable — le 4 est ce qui rend le 1 visible) et {2,3} (pilotage de mission) en deux
phases. Samuel a tranché pour une phase unique. Le changement 2 vaut à lui seul plus que les trois
autres réunis — si l'exécution déborde, c'est par là qu'il faudra scinder.

**Plans:** 7/7 plans executed

Plans:

- [x] 20-01-PLAN.md — Changement 5 : périmètre explicite des 2 hooks de conformité, avertissements conditionnels en mode hook, charset de token MCP, clé `vf-mcp-tools` connue du gate ; chemin par défaut enfin testé (vague 1)
- [x] 20-02-PLAN.md — `dag.sh` : `--scope` sur `add`, `review_regime` forcé à `full` par `reopen`, périmètres gelés exposés par `status` (vague 1)
- [x] 20-03-PLAN.md — Changement 1 : mode d'injection MCP nommé dans `inject-mcp-tools.sh`, `vf-reviewer` déclare son allowlist et son protocole d'appel (vague 2, dépend de 20-01)
- [x] 20-04-PLAN.md — Critère 2, sens ouverture : `disallowedTools: Write, Edit` sur les 4 juges, `vf-design-judge` cesse d'affirmer une barrière que le runtime ne pose pas (vague 1)
- [x] 20-05-PLAN.md — Changement 3 : `.planning/MISSION-INVARIANTS.md` réduit aux éléments falsifiables + `check-mission-invariants.sh` et sa suite (vague 2, dépend de 20-02, checkpoint humain D-16)
- [x] 20-06-PLAN.md — Changement 2 : la revue devient un étage de premier rang piloté par le manager, graduée par risque, revue de jointure sur topologie (vague 3, dépend de 20-02/20-03/20-05, checkpoint humain D-11)
- [x] 20-07-PLAN.md — Gouvernance : ADR-051 révisée + ADR-060, doctrine `team-kernel`/README alignée, 6 modules bumpés, gates de sortie (vague 4, dépend de tous)

### Phase 21: Alignement du moteur GSD sur gsd-core 1.9.0

> **Origine** — mise à jour du moteur de 1.8.0 vers 1.9.0 sur le poste de Samuel le 2026-07-31
> (11:35). Delta établi **sur pièce** par `npm pack` des deux versions et diff intégral des
> tarballs, plus vérification de l'installation vivante :
> `.planning/missions/2026-07-31-delta-gsd-core-1.9.0.md`. Découpage arbitré par Samuel le
> 2026-07-31 : **une phase unique**, périmètre exhaustif, **rituel allégé**.

**Goal**: Faire coller VibeFlow à `@opengsd/gsd-core` 1.9.0 — réparer le seul défaut actif,
adopter les contrats amont qui créent une perte silencieuse, instruire les recouvrements
d'architecture, et purger la dette de version — puis **publier une release racine** (tag annoté +
release GitHub, discipline `CLAUDE.md`).

**Le point de départ n'est pas une panne.** Vérifié avant ouverture : aucun frontmatter d'agent ne
change entre 1.8.0 et 1.9.0 (les 10 agents modifiés ne bougent que dans le corps — `description:`,
`tools:` et `model:` identiques), 71 skills des deux côtés sans ajout ni suppression,
`_runtime-launcher.snippet.sh` identique, les 43 suites vertes, aucun hook déclaré manquant, gates
`check-gsd-engine.sh` et `detect-gsd-engine.sh` au vert. **Le dispatch tient.** Cette phase est de
l'alignement, pas du sauvetage — à l'exception du changement 1.

**Changement 1 — l'injection MCP (ADR-051) est structurellement inopérante sur ce poste.**
Seul défaut qui dégrade réellement le fonctionnement. L'update a réécrit
`~/.claude/agents/gsd-executor.md` (mtime identique à celui de `gsd-core/VERSION`) et effacé
`mcp__XcodeBuildMCP__*` de son `tools:` — comportement connu, documenté au README v2.43.0
(l'installeur amont classe l'injection en « local patch »). Mais la remédiation prévue **ne peut
pas s'appliquer** : `inject-mcp-tools.sh` dérive les serveurs de `./.mcp.json` (défaut de
`--mcp-json`), or **aucun lab de `~/Documents/dev` n'a de `.mcp.json`** — `XcodeBuildMCP` est
déclaré en **scope global** dans `~/.claude.json`. `--verify` sort donc en `3 / INDÉTERMINÉ` au lieu
de signaler le manque, et `ensure-deps.sh --migrate-engine` ne rattrape rien. Conséquence : sur un
projet iOS, `gsd-executor` dispatché par `vf-coder` est **aveugle à XcodeBuildMCP** (un sous-agent
n'hérite pas des serveurs MCP de la session), alors que le `CLAUDE.md` de RoastMyRoom interdit
`xcodebuild` brut. La cause n'est pas la 1.9.0 — c'est une **lacune de scope dans notre propre
script**, que chaque update du moteur révèle à nouveau.

**Changement 2 — câbler le contrat `estimate:` / `actuals:` (ADR-2629 amont, #2632).**
`gsd-planner` émet désormais un bloc `estimate:` (`tokens`, `raw_tokens`, `tasks`, `confidence`
— cette dernière **dérivée du nombre d'échantillons, jamais auto-évaluée**) dans le frontmatter du
`PLAN.md` ; `gsd-executor` doit écrire `actuals:` (`tokens`, `tasks`, `commits`) dans le `SUMMARY`
quand le plan portait un `estimate`. Deux exigences amont à respecter : **même échelle** des deux
côtés (`chars/4` sur le diff réalisé, **pas** un compteur du harness — sinon on mesure les méthodes
de mesure), et **aucun arrondi flatteur**. `dev-orchestrator/references/mission-contracts.md`
définit les contrats de sortie typés de `vf-coder` et des workers et **ignore ces deux champs** :
les missions pilotées par `vf-dev-manager` traversent la chaîne sans jamais alimenter la boucle de
calibration. Rien n'échoue — la donnée n'existe simplement pas. **Perte silencieuse**, d'où sa
place dans le périmètre.

**Changement 3 — instruire le recouvrement avec les lanes de revue amont (ADR-2782 Phase 1,
#2794, clôt #2690).** `review-lane-descriptor.cjs` déclare **en données** le contrat des reviewers
cross-AI, jusqu'ici éclaté sur trois surfaces (roster, ~640 lignes de bash par CLI dans
`workflows/review.md`, en-têtes codés en dur dans `write_reviews`). Le module **déclare, il
n'exécute pas** — `invoke_reviewers` garde ses jambes manuelles jusqu'à la Phase 5b amont (#2799) ;
l'apport est `checkReviewerLaneParity`. À trancher **explicitement plutôt que par omission** : le
recouvrement avec l'**étage de revue de premier rang** livré en 20-06 (`vf-reviewer` →
`gsd-code-reviewer`). Ce sont a priori deux objets distincts — revue **cross-AI de plans** en amont,
revue de **diff de code** chez nous — mais l'arbitrage doit être écrit.

**Changement 4 — instruire `runtime-aware-dispatch` (#2505 Phase 4 / #2508) et
`executor-isolation-dispatch`.** L'amont distingue les runtimes à **dispatch nommé**
(`hostIntegration.dispatch.namedDispatch: true` — Claude Code, OpenCode, Cursor, Cline) des
runtimes **built-in-only** (kimi-code : `coder`, `explore`, `plan`), où un nom de rôle GSD est
inconnu et doit tomber sur le built-in le plus proche. Nos managers dispatchent des agents nommés
**en dur** ; `.gsd-runtime` vaut `claude` ici, donc aucun effet immédiat — mais l'hypothèse « le
dispatch nommé marche toujours » est désormais fausse en général et **n'est écrite nulle part chez
nous**. À recouper aussi : `gsd-executor` accepte maintenant `agent-<id>` **ou**
`worktree-agent-<id>` (#1995), et remonte un nouveau cas d'échec `staging_failed` /
`staging_timeout` à ne pas retenter (#2608) — à confronter à `gsd-worktree-path-guard`.

**Changement 5 — purger la dette de version figée sur 1.8.0.** `gsd-skills-index.md` est
**auto-généré** et porte « depuis @opengsd/gsd-core@1.8.0 », daté 2026-07-26 → regénérer via
`build-gsd-index.sh` ; `mission-contracts.md` cite « gsd-core 1.8.0 » (:148) et « tag stable =
1.8.0 » (:172) ; `check-gsd-engine.sh` (:25) et `detect-gsd-engine.sh` (:30) citent 1.8.0.
⚠️ **Piège à préserver, pas à corriger** : `test-check-gsd-engine.sh` **cas 8 asserte la présence
littérale de la chaîne `1.8.0`** dans l'en-tête — le test doit bouger avec le texte. Et la leçon
elle-même reste vraie : le fork repart de zéro, donc **1.9.0 < 1.42.3 en semver** — la migration se
décide sur le **nom du paquet et le layout**, jamais sur la comparaison des numéros.

**Changement 6 — statuer sur les hooks 1.9.0 non câblés.** `gsd-ensure-canonical-path.js` et
`gsd-update-banner.js` sont posés par 1.9.0 et absents de `settings.json` (les `gsd-cursor-*` /
`gsd-windsurf-*` sont normalement dormants hors de leur runtime, `gsd-check-update-worker.js` est
un interne appelé par son parent). Rien n'est cassé, mais une fonctionnalité amont est peut-être
inactive faute de câblage. Décider si `merge-hooks.sh` doit en tenir compte — ou acter que c'est un
sujet `gsd-core`, hors périmètre VibeFlow.

**Requirements**: Changements 1 à 6 + le point hérité (anomalie d'agrégation `STATE.md`) servent
d'IDs de traçabilité — aucun ID formel `REQ-` n'existe pour cette phase dans `REQUIREMENTS.md`
(le ledger s'arrête à ALTI-05 / Phase 14, vérifié sur pièce), même convention que les Phases 15 à
20 ; numérotation reprise telle quelle par le champ `requirements-completed` de chaque
`21-0N-PLAN.md`/`SUMMARY.md`.
**Depends on:** Phase 20 — **merge requis avant exécution**. Même règle que le diagnostic du
2026-07-29 : les phases qui touchent le couplage au moteur attendent que la 20 soit mergée pour
éviter les conflits sur les fichiers partagés.
**Plans:** 5/5 plans executed

Plans:

- [x] 21-01-PLAN.md — Changement 1 : `inject-mcp-tools.sh` découvre les serveurs MCP en union de deux scopes (`./.mcp.json` projet ∪ `~/.claude.json` global), corrige le défaut actif ADR-051 (vague 1)
- [x] 21-02-PLAN.md — Changements 2, 3, 4 : contrat `estimate:`/`actuals:` relayé verbatim, ADR-061 (recouvrement lanes de revue amont vs étage 20-06), hypothèse datée du dispatch nommé + recoupement #1995/#2608 (vague 1)
- [x] 21-03-PLAN.md — Changements 5, 6 : purge de la dette de version 1.8.0 → 1.9.0, ADR-062 (hooks 1.9.0 non câblés, absence correcte dans les deux cas) (vague 2)
- [x] 21-04-PLAN.md — Point hérité : `check-state-integrity.sh` (gate anti-régression du frontmatter de `STATE.md`, module `conductor` v1.18.0) et ADR-063 (arbitrage de l'anomalie d'agrégation) (vague 2)
- [x] 21-05-PLAN.md — Gouvernance : CI remise au vert (compteur de suites), 2 modules bumpés (`dev-orchestrator` v2.10.0 — v2.9.0 étant déjà prise en amont, `planning-core` v2.5.3), ROADMAP recalé, 4 warnings traités, `STATE.md` recalé, release racine v2.45.0 préparée (vague 3, dépend de tous)

### Phase 22: Hygiène documentaire — doctrine de sortie et captation d'intention

> **Origine** — demande de Samuel le 2026-07-31 : « le dev-orchestrator n'a pas de workflow de
> mise à jour de doc avec les commandes GSD qui maintiennent la doc et les specs ». Gap établi
> **sur pièce** par lecture des workflows amont (`gsd-core/workflows/docs-update.md` 1177 lignes,
> `ingest-docs.md`, `map-codebase.md`, `extract-learnings.md`) confrontés à l'état du module.

**Goal**: Donner au moteur de dev une **doctrine documentaire de sortie** — symétrique de la
doctrine d'entrée déjà écrite (`ingestion-flow.md`) — et la **captation d'intention en langage
naturel** qui la déclenche, de sorte que (a) `vf-dev-manager` et `vf-design-manager` sachent
QUAND poser un nœud de doc et LEQUEL, et (b) l'utilisateur obtienne le bon geste sans jamais
nommer une commande, exactement comme « on en est où ? » tombe aujourd'hui sur `gsd-progress`.

**Le point de départ n'est pas un manque d'outils — c'est un manque de discernement.**
Les quatre familles documentaires que GSD maintient sont **outillées séparément amont** et
**fondues en une seule ligne** chez nous (`intent-routing.md` : « mets à jour la doc / génère le
README / la doc est périmée » → `gsd-docs-update`) :

| Famille | Brique | Ce qui est réellement maintenu |
|---|---|---|
| doc **produit** | `gsd-docs-update` | 6 docs toujours-on (README, ARCHITECTURE, GETTING-STARTED, DEVELOPMENT, TESTING, CONFIGURATION) + 3 conditionnelles (API si routes, CONTRIBUTING si OSS, DEPLOYMENT si config de déploiement), **plus** une *review queue* des docs écrites à la main vérifiées contre le code, **plus** une détection de trous. CHANGELOG **jamais** régénéré. |
| doc **d'entrée** | `gsd-ingest-docs`, `gsd-import` | specs/ADR/PRD → `.planning/`. Doctrine déjà écrite (`ingestion-flow.md`). |
| doc **du code** | `gsd-map-codebase` | `.planning/codebase/` (STACK, ARCHITECTURE, CONVENTIONS, CONCERNS…), modes `--fast` / `--query refresh`. |
| doc **de savoir** | `gsd-extract-learnings`, `gsd-graphify` | LEARNINGS.md de phase, graphe de connaissance. |

**Lacune 1 — aucune doctrine de sortie.** L'entrée a ses 94 lignes de garde-fous ; la sortie n'a
qu'une ligne de table. Un agent à qui l'on dit « mets à jour la doc » ne sait pas s'il s'agit du
README, de `.planning/codebase/`, ou de `STATE`. Les **flags porteurs de sens** de
`gsd-docs-update` ne sont exposés nulle part : `--verify-only` (auditer sans écrire — la doc
est-elle encore juste ?) et `--force` (régénérer, écrase le manuscrit) répondent à **deux
intentions distinctes** aujourd'hui indiscernables.

**Lacune 2 — captation d'intention famélique.** Une seule ligne de formulations pour un geste que
l'utilisateur exprime de vingt façons : « la doc est fausse », « ça correspond plus au code »,
« documente ce module », « il manque la doc d'API », « vérifie que la doc dit encore vrai »,
« on a changé l'archi », « qu'est-ce qu'on a appris ». Aucune ne tombe de façon fiable.

**Lacune 3 — managers sans moments déclencheurs.** `vf-dev-manager` porte 3 puces d'hygiène et
une seule mention outillée (« drift doc détecté → ajoute un nœud `gsd-docs-update` ») ; il
n'existe aucune table « à ce moment du cycle → cette brique, à cette condition ».
`vf-design-manager` n'a **aucun** geste documentaire : son gate `DESIGN.md` ne parle jamais à la
doc produit, alors qu'une refonte d'écran périme ARCHITECTURE/README aussi sûrement qu'un refactor.

**Lacune 4 — le signal existe, le destinataire n'est pas outillé.** Le hook `[doc-drift]`
(`check-doc-drift.sh`, Phase 17) constate déjà le FAIT — N commits de code sans commit de doc —
et propose `gsd-docs-update`. Personne n'est équipé pour transformer ce constat en geste gradué
(vérifier ? régénérer une doc ? toutes ?).

**Requirements**: DOCF-01, DOCF-02, DOCF-03, DOCF-04, DOCF-05, DOCF-06, DOCF-07
*(IDs créés au plan du 2026-07-31 — aucun préfixe existant du ledger ne couvrait ce périmètre ;
définis dans `.planning/REQUIREMENTS.md` §Hors-milestone — Phase 22.)*
**Depends on:** Phase 20 — **merge requis avant exécution**. Périmètre à fichiers partagés avec
la 20 (`intent-routing.md`, `mission-contracts.md`, `vf-dev-manager.md`). **Indépendante de la
Phase 21** (alignement gsd-core 1.9.0) : aucun fichier commun, l'ordre d'exécution est libre.
**Plans:** 1/3 plans executed
partagé par les plans 01 et 02 — pas de parallélisme possible). Découpage tracer-first : le plan
01 prouve la chaîne complète sur UNE intention avant d'écrire les trois autres familles.

Plans:

- [x] 22-01-PLAN.md — doctrine de sortie `docs-flow.md` (4 familles, 3 régimes, garde-fous) +
  captation d'intention dans `intent-routing.md` + câblage `AGENT.md` au chemin d'install D7 +
  bloc de garde T22. *Tracer : la doctrine existe, est référencée, s'installe réellement et est
  gardée — prouvé sur une seule intention avant toute expansion.* (DOCF-01→04, DOCF-06)

- [ ] 22-02-PLAN.md — les deux managers dotés du nœud `docs` agrégé et des 4 déclencheurs, par
  renvoi vers la doctrine (aucune copie) + bloc de garde T23 + checkpoint humain sur la
  formulation de `--force` (D-05/D-06). (DOCF-05, DOCF-06)

- [ ] 22-03-PLAN.md — bump **minor** des 2 modules touchés (`dev-orchestrator` v2.9.0,
  `design-orchestrator` v1.4.0), triades + CHANGELOG, `check-version-sync.sh` ✓. Release racine
  **hors périmètre**, réservée à validation humaine. (DOCF-07)

### Phase 23: Couplage explicite au moteur GSD — capabilities, flags et voie unique

> **Origine** — analyse du 2026-07-31, déclenchée par l'observation d'un `gsd-pattern-mapper`
> spawné en session **inline** (hors `vf-dev-manager`) et la question de Samuel : « dev-manager a-t-il
> accès à cet outil, et sait-il utiliser GSD avec le bon workflow, au bon moment, quand c'est
> réellement utile ? ». Gap établi **sur pièce** contre `@opengsd/gsd-core@1.9.0` **installé**
> (`~/.claude/gsd-core/VERSION` = 1.9.0, pas le 1.8.0 de l'index versionné) : lecture de
> `workflows/plan-phase.md`, `workflows/execute-phase.md`, `bin/lib/config.cjs`,
> `bin/lib/capability-registry.cjs`, et **sortie réelle** de
> `gsd-tools.cjs loop render-hooks` sur 6 points de hook.

**Goal**: Rendre le couplage du moteur de dev à GSD **explicite et arbitré** — (a) une **voie
unique** d'invocation des briques de cycle, (b) une **doctrine de flags** par sous-phase, (c) une
**table des capabilities/hooks** qui dit qui couvre quoi, (d) un **contrat de checkpoint aligné**
sur celui du moteur (type × `gate`, continuation) et (e) des **budgets de boucle additionnés** —
de sorte que la chaîne d'équipe cesse de superposer des étages que GSD lance déjà, de laisser
accessible sans garde-fou une voie qui en désactive la moitié, et de pouvoir trancher seule un
checkpoint que le moteur a refusé de trancher.

**Ordre de traitement imposé** : la **Lacune 6 (sûreté) passe en premier** — c'est la seule dont la
conséquence est un mauvais comportement silencieux, les autres coûtant du volume ou de la
cohérence. Elle est aussi le prérequis de la Lacune 3 : la doctrine de flags ne peut pas être
écrite sans savoir ce qu'un `--auto` auto-approuve.

**Le point de départ n'est pas une panne.** La chaîne tourne, les agents ont les accès, aucune
suite n'échoue. Le défaut est un **couplage implicite** : le module raisonne comme si GSD était une
liste de skills à appeler, alors que GSD 1.9 est un **moteur à capabilities** qui insère ses étages
lui-même.

**Constat 0 — l'accès n'est pas le sujet.** `gsd-pattern-mapper` est déclaré dans les allowlists
`Agent(...)` de `vf-dev-manager.md:4` **et** `vf-coder.md:4` ; et `team-kernel.md:23` acte que cette
allowlist est **un contrat documenté, pas un cloisonnement runtime** pour un agent dispatché en
sous-agent. Le pattern-mapper de la capture n'a d'ailleurs été choisi par **aucun** agent :
`plan-phase.md:651` — « Pattern mapper activation is owned by the `pattern-mapper` capability's
`plan:pre` step hook ». La bonne question n'est donc pas « y a-t-il accès », c'est « qui décide,
et le module le sait-il ».

**Constat 1 — le mécanisme de capabilities est invisible pour le module.**
`grep -r "capabilit\|render-hooks\|plan:pre\|verify:post"` sur `plugin/dev-orchestrator/` →
**zéro occurrence**. `gsd-pattern-mapper`, `gsd-verifier` et `gsd-nyquist-auditor` n'apparaissent
**que** dans les lignes `tools:`, jamais dans une doctrine d'usage. Hooks réellement actifs
(mesurés, pas déduits) :

| Point | Capability → brique | Toggle (défaut **true**, `config.cjs:243-273`) |
|---|---|---|
| `plan:pre` | `gsd-phase-researcher`, **`gsd-pattern-mapper`**, `ui-phase`, `ai-integration-phase` | `research`, `pattern_mapper`, `ui_phase` |
| `plan:post` | gap-analysis | `post_planning_gaps` |
| `execute:post` | skill **`code-review`** | `code_review` |
| `verify:post` | **`validate-phase`** (nyquist), **`secure-phase`**, **`ui-review`** | `nyquist_validation`, `security_enforcement`, `ui_review` |

`execute-phase.md` rend **à lui seul** `execute:post` (:1210) **et** `verify:post` (:1152) — un
seul appel de skill déclenche donc revue de code, validation nyquist et audit sécurité.

**Lacune 1 — doublons d'étage non arbitrés.** `vf-dev-manager.md:114-129` pose `revue-N`
**systématiquement** (Pattern E, `mission-flow.md:176-206`) et `vf-auditer` conditionnellement,
par-dessus les hooks `code-review` et `secure-phase` que GSD a déjà lancés. Deux revues du même
diff, deux budgets, deux `reopen` possibles. Ce n'est pas nécessairement faux — la **revue de
jointure** a un rendement prouvé (`mission-flow.md:238` : 4 bloquants + 9 majeurs sur la tranche
Phase 20) — mais l'arbitrage n'est écrit nulle part. À trancher **explicitement plutôt que par
omission**, et **une seule fois** : recouper avec le changement 3 de la Phase 21 (recouvrement avec
les lanes de revue cross-AI amont), qui instruit le même genre de frontière.

**Lacune 2 — une voie dégradée accessible sans garde-fou.** `vf-coder.md:31-32` offre
« ou dispatche l'agent `gsd-planner` » / « ou dispatche `gsd-executor` » **à égalité** avec
l'invocation du skill. Or l'agent nu fait sauter research, pattern-mapper, plan-checker,
gap-analysis, drift gate, waves, verifier, code-review, nyquist et secure-phase — **sans que rien
ne le signale** au rapport typé. C'est le trou le plus grave : un worker peut rendre `passed` en
ayant désactivé la moitié du moteur.

**Lacune 3 — aucune doctrine de flags.** Un seul flag GSD dans tout le module (`--auto` sur
`gsd-discuss-phase`, `vf-coder.md:27`). Deux faits mesurés qui rendent le silence coûteux :

- `plan-phase.md:333` **prompte** sur la recherche si ni `--research` ni `--skip-research` ni
  `--auto` — et `vf-coder` **n'a pas `AskUserQuestion`** (blocage ou auto-réponse silencieuse) ;

- `plan-phase.md:1557-1577` : `--auto` **persiste** `workflow._auto_chain_active` puis enchaîne
  seul `gsd-execute-phase --auto` et la phase suivante. Un `--auto` par réflexe **exécuterait hors
  frontière DAG**, contre le pipelining N/N+1 (`mission-flow.md:98-132`).

Le réglage juste est donc **étroit** (`--research`/`--skip-research` explicite, `--text` si besoin,
**jamais** `--auto` sur plan/execute) et il n'est écrit nulle part.
**Frontière avec la Phase 22** : la 22 porte les flags de la famille **documentaire**
(`--verify-only` / `--force` de `gsd-docs-update`) ; celle-ci porte ceux du **cycle**
discuss/plan/execute. Une seule surface de doctrine, pas deux — la première exécutée fixe la forme.

**Lacune 4 — briques routées mais jamais mobilisées en mission.** Présentes dans
`intent-routing.md` (couverture 100 % vérifiée machine) et absentes du cycle d'équipe :
`gsd-spec-phase`, `gsd-add-tests`, `gsd-extract-learnings` (l'hygiène du manager ne cite que
`gsd-docs-update`), `gsd-debug` — `vf-dev-manager` n'a même pas `gsd-debugger` en allowlist, donc
après la recherche doc d'ADR-045 il n'a **rien** —, `gsd-undo` sur échec, `gsd-forensics` après
blocage, et `gsd-ship`/`gsd-pr-branch` : le manager ouvre la PR à la main (ADR-059) alors que
`GSD-PIPELINE.md:19` place `gsd-ship` dans le cycle canonique — **tension non tranchée**.

**Lacune 5 — le `config.json` du lab n'est pas aligné sur le moteur.** `gsd-tools` avertit à chaque
appel : « unknown config key(s) in .planning/config.json: `gates`, `safety` — these will be
ignored » (deux blocs entiers **inertes**, dont `confirm_plan`) ; et `pattern_mapper`,
`code_review`, `ui_review` sont **absentes** → au défaut `true` sans que personne ne l'ait décidé.
Le lab pilote donc ses étages par omission.

**Lacune 6 — la taxonomie de checkpoint GSD est ignorée (SÛRETÉ, priorité de la phase).**
GSD 1.9 porte un contrat de checkpoint **à deux couches** (type × `gate`) que le module ne
connaît pas : `grep -rn "checkpoint"` sur `plugin/dev-orchestrator/` → 4 occurrences, **toutes** au
sens du mode superviser VibeFlow, **aucune** au sens GSD. `references/checkpoints.md` décrit
pourtant exactement notre configuration comme le mode de défaillance à éviter : « *An orchestrator
that dispatches on checkpoint **type** alone would auto-approve the very checkpoint the executor
just refused to auto-approve, nullifying that refusal one layer up.* » Trois faits :

- **(a) `gate="blocking-human"` n'est jamais honoré.** `gsd-executor.md:330-332` : en auto-mode
  l'exécuteur auto-approuve `human-verify` et auto-sélectionne `decision` — **sauf**
  `gate="blocking-human"` (et sauf les checkpoints de légitimité de paquet), qu'il **refuse** de
  trancher et escalade exprès via `checkpoint_return_format`. `vf-dev-manager.md:157` pilote sur son
  `statut` maison (`passed|gaps_found|human_needed|blocked`) : **aucun mapping** n'existe entre le
  gate amont et `human_needed`, donc un manager en mode autonome peut « continuer » sur le seul
  checkpoint que le moteur a explicitement refusé d'auto-approuver. Même chose pour les
  **préconditions non satisfaites** (`gsd-executor.md:150`), « NEVER auto-approved, even under
  `AUTO_CFG=true` ».

- **(b) l'auto-mode auto-tranche les décisions.** Règle 5 de `checkpoints.md` : dès que
  `workflow._auto_chain_active` **ou** `workflow.auto_advance` est vrai, `human-verify`
  auto-approuve et `decision` **auto-sélectionne la première option**. Aucun agent du module ne lit
  ni ne remet ce flag à zéro — alors que `plan-phase.md:1560` sait l'écrire (cf. Lacune 3). Le
  couplage des deux lacunes est le vrai danger : un `--auto` mal placé ne fait pas que dérouler,
  il **tranche des décisions à notre place**.

- **(c) un worker interrompu par checkpoint ne reprend pas.** `execute-plan.md:321` :
  « *You will NOT be resumed* » — l'orchestrateur doit spawner une **continuation** portant l'état
  des tâches déjà faites, sur un contrat en 4 blocs (Completed Tasks / Current Task / Checkpoint
  Details / Awaiting). Le bloc typé ADR-053 ne porte **aucun** de ces champs, et `dag.sh reopen` ne
  modélise pas un plan **partiellement** exécuté : au reopen, `vf-coder` repart de l'étape, pas de
  la tâche. Risque : travail refait, ou commits orphelins d'un premier passage.

**Lacune 7 — les budgets de boucle se superposent en silence.** `workflow.node_repair` est **ON par
défaut** (budget 2) : sur échec de vérification, GSD tente seul RETRY / DECOMPOSE / PRUNE avant
d'escalader (`execute-plan.md:330-345`). Les « 3 tours max » de la boucle de revue
(`mission-flow.md` §Pattern E) et celle de comblement s'empilent donc **par-dessus** deux
réparations déjà consommées à l'intérieur de chaque tour — budget réel ≈ 3 × (1+2), jamais écrit,
jamais consigné au rapport. Un blocage « après 3 tours » a en réalité coûté jusqu'à neuf tentatives.

**Requirements**: GSDC-01, GSDC-02, GSDC-03, GSDC-04, GSDC-05, GSDC-06, GSDC-07, GSDC-08, GSDC-09,
GSDC-10 *(créés au plan du 2026-08-01, préfixe `GSDC` — cf. `.planning/REQUIREMENTS.md`)*
**Depends on:** Phase 20 — **merge requis avant exécution** (périmètre à fichiers partagés :
`vf-coder.md`, `vf-dev-manager.md`, `mission-contracts.md`, `intent-routing.md`).
**Recoupements à instruire, pas des dépendances d'ordre** : Phase 21 (changement 3 — arbitrage des
étages de revue) et Phase 22 (doctrine de flags documentaires). L'ordre est libre ; l'arbitrage
écrit par la première exécutée **fait autorité**, la suivante s'y réfère sans le dupliquer.
**Plans:** 8/8 plans executed
quasi-séquentielle ; seuls 23-01 et 23-02 sont parallélisables en vague 1)

Plans:

- [x] 23-01-PLAN.md — **Zone 1, SÛRETÉ, priorité imposée** : champ `gate` et mapping unique vers
  `human_needed` de bout en bout, reset de `workflow._auto_chain_active` au démarrage de mission,
  minimum de reprise, halt de nœud, réponse humaine portée par le manager. Blocs T24/T25/T26,
  discriminance prouvée par mutation. (GSDC-01, GSDC-02)

- [x] 23-02-PLAN.md — **Zone 5, parallèle de 23-01** : `check-gsd-config.sh` (advisory, exit 0/3/64,
  clés connues lues depuis `gsd-core`) + suite dédiée + câblage `SessionStart` ; blocs `gates` et
  `safety` supprimés du `config.json` du lab et 5 toggles écrits à une valeur décidée. (GSDC-07)

- [x] 23-03-PLAN.md — **Zone 2** : `GSD-PIPELINE.md` §9 doctrine de flags de cycle en **allowlist
  stricte** (clause de fermeture par défaut, gradation `--research` factuelle, renvoi croisé vers
  `docs-flow.md`), ligne `gsd-ship` du cycle canonique corrigée. Bloc T27. (GSDC-03)

- [x] 23-04-PLAN.md — **Zone 2** : générateur `build-gsd-capabilities-index.sh` →
  `references/gsd-capabilities-index.md` sur les **12** points de hook (liste découverte depuis le
  registre amont), renvoi depuis la doctrine, régénération à l'install. Bloc T28. (GSDC-04)

- [x] 23-05-PLAN.md — **Zone 3, le trou le plus grave** : voie dégradée supprimée du corps de
  prompt de `vf-coder`, `gsd-planner`/`gsd-executor` retirés des lignes `tools:` des **deux**
  agents (arbitrage du Finding 1), doctrine de voie unique et continuation par voie skill. Bloc
  T29. (GSDC-05)

- [x] 23-06-PLAN.md — **Zone 4** : verdicts de hooks au bloc typé (`pass|fail|absent`), ADR-061
  étendue d'un **troisième objet revu** sur les mêmes 3 axes (hook vs `revue-N`, hook vs
  `vf-auditer` avec le delta `CONCERNS.md`). Bloc T30. (GSDC-06)

- [x] 23-07-PLAN.md — **Zones 6 et 7** : budget de tours **partagé par étape**, halt `blocked` +
  décompte complet avec l'invisibilité `node_repair` nommée, table des moments déclencheurs des 4
  briques dormantes, mandat de debug par le skill. Blocs T31/T32. (GSDC-08, GSDC-09)

- [x] 23-08-PLAN.md — **Clôture** : bump **minor** du module (v2.10.0 → v2.11.0), triade +
  CHANGELOG, compteur de suites des 2 README racine 46 → 47, `check-version-sync.sh` ✓, ledger
  d'exigences, rejeu des 11 gates de sortie. Release racine **hors périmètre**, réservée à
  validation humaine. (GSDC-10)

### Phase 24: Activation et mesure du moteur GSD — capacités dormantes et faits de runtime

> **Origine** — second temps de l'audit du 2026-07-31 (le premier a produit la Phase 23), sur
> demande de Samuel d'aller au bout des gaps VibeFlow ↔ GSD. Établi **sur pièce** contre
> `@opengsd/gsd-core@1.9.0` installé : inventaire des **44 capabilities** et des **12 points de
> hook** (`bin/lib/capability-registry.cjs`, exports `capabilities` / `byLoopPoint` /
> `capabilityClusters`), du **descripteur d'hôte `claude`**, de `bin/lib/init.cjs`
> (`buildAgentSkillsBlock`), de `bin/lib/host-integration.cjs` (`shouldFlattenDispatch`) et des
> hooks réellement posés dans `~/.claude/settings.json`.

**Goal**: Cesser de payer l'installation d'un moteur sans en prendre les bénéfices — **activer**
les capacités GSD déjà installées mais dormantes, **mesurer** les faits de runtime que VibeFlow
présume, et **fermer** les routes qui mènent à un geste inerte. La Phase 23 rend le couplage
explicite ; celle-ci rend le moteur **effectivement employé**.

**Le point de départ n'est ni une panne ni un couplage flou — c'est de la valeur laissée sur la
table.** Chaque item ci-dessous est une brique du moteur **présente sur le disque**, dont le
toggle est à `false` ou dont le canal est vide, et que VibeFlow soit ignore, soit ré-implémente à
la main.

**Ordre imposé — le lot MESURE d'abord.** Le constat M2 portait sur le cœur du gain de la Phase 20 :
il devait être connu **avant** d'activer quoi que ce soit d'autre. **M2 est mesuré et rendu**
(2026-07-31, verdict ci-dessous : les acquis tiennent, le gap se déplace) ; M1 et M3 restent des
constats de lecture à instruire au plan. Aucun lot d'activation ne démarre avant que les trois
soient traités.

#### Lot MESURE — trois faits présumés (M2 mesuré le 2026-07-31, M1 et M3 à instruire)

Le descripteur officiel du runtime `claude` dans GSD 1.9 (capability `claude`, clé
`hostIntegration.dispatch`) dit :

```
{ namedDispatch: true, nested: true, maxDepth: 5,
  background: true, backgroundDispatch: false,
  subagentToolkit: "full", isolation: "harness-worktree" }
```

**M1 — la profondeur de dispatch disponible est 5, VibeFlow en consomme 3.** `nested: true`,
`maxDepth: 5`, `subagentToolkit: "full"` : la chaîne `vf-dev-manager → vf-coder → agent gsd-*`
tient, avec **deux niveaux de marge**. Ce fait **clôt** la question du nesting posée à l'ouverture
de l'audit et n'est écrit nulle part dans le module — ni la limite, ni la marge, ni ce qu'elle
autorise (un worker pourrait légitimement dispatcher un sous-worker).

**M2 — ✅ MESURÉ le 2026-07-31 : le moteur s'auto-bride, le runtime sait paralléliser.**
Preuve complète et protocole : `.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md`.
`shouldFlattenDispatch()` (`bin/lib/host-integration.cjs:464`) renvoie `true` dès que
`background && backgroundDispatch` n'est pas vrai — donc **true pour Claude Code** : GSD
**aplatit** ses dispatches, et la capability `claude-orchestration` (1.9.0, **default-off**, BETA)
existe pour « *restoring the wave parallelism the #853 backgrounded-agent nesting limitation forces
inline on Claude Code* ». Deux acquis VibeFlow reposaient sur la capacité inverse — le **fan-out de
la frontière `ready`** (`vf-dev-manager.md:90-96`) et la **recherche doc en tâche de fond**
(`vf-dev-manager.md:180-184`, ADR-045). **Mesure par sondes horodatées (busy-loop 20 s, PID
distincts, 12 cœurs)** :

| Configuration | Recouvrement | Verdict |
|---|---|---|
| Contrôle — fenêtre principale → 2 agents en un message | 18 259 / 20 000 ms (**91 %**) | parallèle |
| **Sous-agent** → 2 agents en un message (le cas `vf-dev-manager`) | 18 460 / 20 000 ms (**92 %**) | **parallèle** |
| **Sous-agent** → 1 enfant en tâche de fond, puis travail propre | parent démarré 1018 ms **avant** l'enfant, fini 18 s avant lui | **non bloquant** |

**Les deux acquis tiennent** — statistiquement indiscernables du contrôle. `backgroundDispatch:
false` est **fail-closed par conception, pas descriptif** de la capacité réelle du runtime. **Le gap
se déplace donc, il ne disparaît pas** : `gsd-execute-phase` sérialise ses vagues **par décision du
moteur** alors que le runtime sait les paralléliser → le parallélisme **intra-étape** (vagues de
plans d'une même phase) est perdu, et seul subsiste le parallélisme **inter-nœuds** porté par
`vf-dev-manager`. Conséquence doctrinale à écrire : sur ce runtime, notre couche d'orchestration ne
duplique pas celle de GSD, **elle est la seule qui parallélise réellement**.

**Voies retenues (arbitrées par Samuel le 2026-07-31), deux sur trois :**

1. **Acter et documenter** — écrire en doctrine que sur ce runtime le parallélisme **inter-nœuds**
   porté par `vf-dev-manager` est le seul effectif, et que le parallélisme **intra-étape** des vagues
   GSD est perdu par décision du moteur. Gratuit, immédiat, et consolide l'architecture existante au
   lieu de la remettre en cause.

2. **Signaler le descripteur en amont** — remonter à `@opengsd/gsd-core`, **mesure horodatée à
   l'appui**, que `backgroundDispatch: false` est *fail-closed* mais non descriptif du runtime
   Claude Code. Bénéfice collectif : débloquerait le parallélisme intra-étape pour tous les labs.

3. ~~Activer `claude_orchestration.enabled`~~ — **ÉCARTÉ pour l'instant** : placer un backend
   **BETA** sur le chemin critique d'exécution n'est pas justifié quand notre propre parallélisme
   fonctionne (mesuré). À reconsidérer seulement si le parallélisme intra-étape devient un besoin
   démontré, ou si la voie 2 échoue.

Reste non mesuré : la profondeur 2 → 3 (`vf-coder → gsd-executor`), couverte en **déclaration** par
M1 (`maxDepth: 5`), pas par l'expérience.

**M3 — `effort:` est supporté, validé, et déclaré par aucun agent.** Le harness l'expose
(`agentFrontmatterExtensions: ["effort"]`), notre propre gate le **valide déjà**
(`check-agents.sh:514`, `low|medium|high|xhigh|max`), les skills GSD l'emploient (`effort: max` sur
`gsd-plan-phase`) — et `grep -rln "^effort:" plugin/*/agents/*.md` → **aucun résultat**. Managers,
juges et workers tournent tous à l'effort par défaut. À trancher par rôle (pilotage et jugement
haut, exécution mécanique bas), pas uniformément.

#### Lot ACTIVATION — capacités installées, dormantes

**A1 — broken-windows : le ledger est au bon format, le gate est éteint.** `.planning/WINDOWS.md`
porte `open_count: 2` — **exactement** le frontmatter que le gate `ship:pre` évalue
(`predicate: artifact-frontmatter-equals`, `artifact: WINDOWS.md`, `field: open_count`,
`equals: 0`). Mais `workflow.windows_enforce` est **absent** du `config.json` → défaut **`false`**,
et la description amont est sans ambiguïté : « *When false (default), windows are still tracked
(the executor and verifier still populate WINDOWS.md) but ship does not block — teams can adopt
tracking before enforcement* » (#1950). Nous sommes exactement dans cet état intermédiaire : le
tracking tourne, l'enforcement non — sauf que nous tenons le ledger **à la main** (commits
`chore(20): WINDOWS #2 résolu`) sans savoir que le moteur l'alimente et saurait bloquer le ship.
**Le plus actionnable de la phase** : une clé de config et une décision.

**A2 — `agent_skills` : le canal officiel de transmission de doctrine est vide.**
`buildAgentSkillsBlock` (`bin/lib/init.cjs:1731`) injecte des skills dans le prompt des agents
GSD via **17 slots** (`AGENT_SKILLS_PLANNER`, `EXECUTOR`, `REVIEWER`, `VERIFIER`, `AUDITOR`,
`DEBUGGER`, `MAPPER`, `CHECKER`, `ANALYZER`, `ADVISOR`, `ROADMAPPER`, `SYNTHESIZER`, `FIXER`,
`RESEARCHER`, `UI*`), consommés par **19 workflows**, et accepte les skills de **plugin
namespacés** (`global:<plugin>:<skill>`). Le `config.json` du lab : `agent_skills: {}`. Conséquence
structurante : la doctrine de dev du lab (Phases 7-8 — SOLID/DRY/KISS/YAGNI/Clean Archi/TDD)
**n'atteint jamais** `gsd-planner` ni `gsd-executor`, c'est-à-dire les agents qui écrivent
réellement le plan et le code. Le « digest de mission » (`mission-contracts.md`) ne va qu'aux
workers `vf-*` et s'arrête à la frontière du moteur. C'est le gap avec le plus fort levier
qualité de tout l'audit.

**A3 — `workflow.tdd_mode = false` alors que la doctrine TDD est écrite.** `plan-phase.md:80` :
quand la capability `tdd` est active, le planner applique `type: tdd` aux tâches éligibles via
`references/tdd.md`, et un hook `execute:post` porte un review-checkpoint TDD. Le lab a une
doctrine TDD (Phase 7) et un skill `tdd` — et le toggle qui la câblerait au moteur est à `false`.

**A4 — les profils de contexte (`contexts/dev|review|research.md`) ne sont pas employés.** Chargés
par la clé `context:` du `config.json` (**absente**), ils fixent style de sortie, focus et
**verbosité** par mode. Or `mission-flow.md` §Pattern C légifère précisément là-dessus (« la prose
libre est du volume mort ») : nous ré-implémentons en doctrine ce que le moteur porte en config.
À arbitrer : adopter, ou acter que notre contrat typé est plus strict et pourquoi.

**A5 — deux hooks machine opt-in, non branchés.** `hooks.workflow_guard` (garde d'enchaînement de
workflow, `gsd-workflow-guard.js:70-79`) et `hooks.community` (Conventional Commits bloquants,
`gsd-validate-commit.sh`) sont **installés et inertes**. Le lab impose déjà des commits
conventionnels en français **par consigne** — un gate existe.

**A6 — `workflow.inline_plan_threshold` (défaut 2) est un levier de coût inconnu.** Un plan de
≤ 2 tâches s'exécute **inline** au lieu de spawner un sous-agent : « *avoids ~14K token subagent
spawn overhead and preserves prompt cache* » (`execute-plan.md:100`). À confronter à la doctrine
de délégation systématique du module.

**A7 — `intel` (`intel.enabled: false`, agent `gsd-intel-updater`, cible `.planning/intel/`).**
Jamais instruit, alors que `.planning/codebase/` (via `gsd-map-codebase`) est pleinement employé et
lu par `vf-dev-manager` au démarrage. Frontière à écrire : que ferait `intel` que `codebase/` ne
fait pas — ou acter le refus.

**A8 — la carte de routage envoie sur des gestes inertes.** `intent-routing.md` route « le graphe
de connaissance » → `gsd-graphify` et « profile ma façon de bosser » → `gsd-profile-user`, or
`graphify.enabled` et `profile-pipeline.enabled` valent **`false`**. Le test d'exhaustivité du
module (`test-dev-orchestrator.sh`) vérifie que **le skill est routé**, jamais que **la capability
est active** : une couverture verte peut donc masquer un geste mort. Deux issues : activer, ou
marquer l'entrée comme conditionnelle — et dans les deux cas, **étendre le test à l'activation**
(sinon le même trou se rouvre au prochain skill ajouté).

**A9 — les workstreams : chantiers parallèles en `.planning/`, capacité native à 18 % de
couverture.** Entré au lot le **2026-08-02**, à la suite de la **PR #27** (partition de `.planning`
en workstreams dev/gouvernance, proposée par Willy, **revue en `CHANGES_REQUESTED`**). Le besoin est
réel et démontré : `ROADMAP.md` et `STATE.md` sont **mono-position** et ne savent pas décrire deux
chantiers simultanés — chaque avancée de l'un réécrit la position de l'autre.

GSD porte la réponse nativement (`.planning/workstreams/<nom>/`, flag `--ws`, `bin/lib/workstream.cjs`,
`gsd-tools workstream list` → `"mode": "workstream"`). **Mais la capacité est à moitié câblée en
amont** : sur les **91 workflows** de gsd-core **1.9.1**, **16 bruts / 15 réels** la connaissent au
critère le plus large (`K3` : le mot `workstream`, l'option `--ws` ou la variable `GSD_WS` — un faux
positif nommé, `reapply-patches.md:220`, qui ne cite `${GSD_WS}` que comme exemple de dérive), et
**45 codent en dur** `.planning/ROADMAP.md` / `STATE.md` / `phases/` (`add-phase`, `verify-phase`,
`next`, `pr-branch`, `execute-plan`, `extract-learnings`, `complete-milestone`…). Couverture :
**17,6 % bruts / 16,5 % réels** au critère K3, **7,7 %** au critère K2 (« le workflow sait-il
résoudre un scope »). Adopter en l'état, c'est faire tourner le lab contre sa propre chaîne
d'outils — le cas que visait l'**Iron Law 2**.

> **Faits corrigés le 2026-08-04 (nœud 24-13), les seuls de ce paragraphe.** Trois périmés y
> figuraient et sont rectifiés ci-dessus : le **« 37 en dur »**, jamais réconcilié avec la mesure
> finale (**45**) ; la version du moteur (**1.9.0 → 1.9.1**) ; et le **~18 %** laissé sans critère,
> désormais nommé (K3) et daté. L'**Iron Law 2** figurait ici dans sa formulation **pré-révision**
> avec une ancre périmée (`conductor/AGENT.md:114`, qui est aujourd'hui l'**Iron Law 1**) : elle a
> été révisée par **ADR-069** en « *Router, jamais forker — une capacité amont partiellement
> couverte se câble en écrivant ses limites, elle ne se réimplémente pas* », et se lit désormais en
> `plugin/conductor/AGENT.md:115` avec sa trace de révision juste en dessous. Le reste de ce bloc
> n'est PAS recalé : il appartient au nœud de documentation de fin de mission.

Faits établis en bac à sable sur la PR #27 (worktree `c0908fd`, gsd-core 1.9.0), qui bornent
l'arbitrage :

- **Notre propre outillage est aveugle.** `check-dev-bootstrap.sh:28` cherche `.planning/ROADMAP.md`
  à la racine → le `SessionStart` repasse de `[gsd-engine] phase 26 en cours` à `[bootstrap] feuille
  de route absente`. `check-state-integrity.sh` (câblé `ci.yml:117` en Phase 21) sort **exit 2**.
  `vf-dev-manager.md` lit les chemins racine en dur (7 occurrences) ; sur tout `plugin/`, **3
  fichiers** mentionnent « workstream », tous des tables de routage.

- **`/gsd-pr-branch` s'inverse.** Ses regex sont ancrées (`pr-branch.md:232-234`) :
  `.planning/workstreams/dev/STATE.md` ne matche plus `STRUCTURAL` → reclassé **transient →
  EXCLUDED**. Les commits de feuille de route disparaissent silencieusement des branches de PR.

- **Le pointeur de workstream ne vit pas où on croit.** Dès qu'une clé de session résout, ce n'est
  pas `.planning/active-workstream` mais
  `os.tmpdir()/gsd-workstream-sessions/<sha1(chemin absolu du .planning)>/<clé>`
  (`active-workstream-store.cjs:95-111`) : effacé au reboot, **et indexé sur le chemin absolu, donc
  distinct par worktree, jamais hérité**. Sur cette machine `CLAUDE_SESSION_ID` n'est pas défini —
  la clé effective est `CLAUDE_CODE_SSE_PORT`, un port recyclable par l'OS.

- **Migration à conflit nul, donc à divergence invisible.** `git merge-tree` d'une branche de travail
  post-partition → **exit 0** avec le dossier de phase en cours **orphelin à la racine** pendant que
  le `STATE.md` du workstream le déclare courant. Git ne signale rien.

**Le recouvrement à instruire est avec ADR-064, pas avec le moteur.** Le quick `260801-17w`
(2026-08-01) a déjà tranché la concurrence multi-session par l'**isolation physique** — « un
écrivain = un worktree », `check-branch-claim.sh` au `SessionStart`, claim de branche élargi —
d'après `shanraisshan/claude-code-best-practice`. Les workstreams sont une **seconde réponse au même
problème, conventionnelle** celle-là, et les deux se composent mal : le pointeur étant indexé sur le
chemin du `.planning`, **chaque worktree ouvre sans workstream résolu**, et aucun agent `vf-*` ne
sait passer `--ws`. Or M2 (lot MESURE) a établi que le parallélisme **inter-nœuds** de
`vf-dev-manager` est le **seul effectif** sur ce runtime : le seul étage de parallélisme qui
fonctionne est aussi celui que la partition fragilise le plus.

**À trancher au plan — la question est ouverte, l'adoption n'est pas acquise :** (a) **adopter** les
workstreams et payer la mise à niveau de notre couche (`check-dev-bootstrap.sh`,
`check-state-integrity.sh`, `planning-context.sh` workstream-aware, `--ws` câblé dans les agents
`vf-*`, gate sur le pointeur, CI étendue) ; (b) **refuser** et traiter les chantiers parallèles par
jalons distincts dans une ROADMAP partagée, l'isolation restant physique par ADR-064 ; (c) **borner**
— workstreams réservés à un usage où les 42 workflows aveugles (critère K2) ne sont jamais sollicités, ce qui
demande de dire lesquels. Dans les cas (a) et (c), la **remontée upstream** des workflows aveugles
est le préalable, au même titre que la RFC de la Phase 18 et la voie 2 de M2. Condition commune aux
trois : **aucune partition tant qu'une phase est en vol** (cf. divergence invisible ci-dessus).

> ### ⚠️ Lettrage — deux jeux de lettres ont coexisté sur A9, un seul fait foi
>
> Les lettres `(a) (b) (c)` ci-dessus sont celles du **cadrage de ce ROADMAP**. L'arbitrage
> `24-ARBITRAGES.md` § Zone 5 en a posé **d'autres**, à quatre branches, et c'est **le lettrage de
> l'arbitrage qui est normatif** — c'est lui que citent `ADR-069` et toute décision postérieure.
> Les lettres du ROADMAP sont conservées pour la trace, **elles ne sont plus une référence
> citable**.
>
> | ROADMAP (historique, non citable) | Arbitrage § Zone 5 / ADR-069 (**normatif**) |
> |---|---|
> | **(a)** adopter | **C** — adopter et payer la mise à niveau de notre couche |
> | **(b)** refuser | **A** — refuser sec · **D** — refuser + remontée amont (l'arbitrage a scindé le refus en deux) |
> | **(c)** borner | **B** — borner à un usage restreint, sous liste de workflows interdits |
>
> **Pourquoi cet encadré existe.** La confusion a effectivement eu lieu : la ligne de décision du
> tableau de clôture a été écrite « voie (c) bornée » en pensant à l'**option C de l'arbitrage**
> (= adopter), glosée avec la lettre `(c)` du ROADMAP (= borner) — soit l'exact contraire de la
> décision de Samuel. Corrigé le 2026-08-05. **Ne jamais désigner une voie A9 par une lettre nue :
> nommer le jeu (« option C de l'arbitrage ») et le geste (« adoption »).**

> **Chiffre recalé le 2026-08-04.** Ce paragraphe et le précédent citaient « **37** workflows
> aveugles ». Ce nombre n'a jamais été réconcilié avec une mesure : les aveugles sont **42** au
> critère **K2** (43 au K1, 35 au K3), sur **45** qui codent des chemins en dur. Le critère fait
> partie du chiffre — voir le tableau de clôture en fin de section, et ADR-069 pour la commande.

---

#### État à la clôture — ce que la phase a effectivement tranché (2026-08-04)

> **Comment lire tout ce qui précède.** Les lots MESURE et ACTIVATION ci-dessus décrivent l'état
> **au cadrage** (2026-07-31 / 2026-08-02). Ils sont conservés tels quels : ils portent le
> raisonnement qui a produit les plans, et les réécrire effacerait la trace de ce qui était su
> quand la phase a été ouverte. Le tableau ci-dessous dit ce qu'ils sont **devenus**, mesuré sur
> l'arbre le 2026-08-04 au soir. **En cas de contradiction, c'est ce tableau qui fait foi.**

| Constat du cadrage | État mesuré à la clôture | Où |
|---|---|---|
| **M1** — profondeur 5 disponible, 3 consommée, écrite nulle part | **écrite** dans les agents | 24-01 |
| **M2** — ✅ mesuré le 2026-07-31 | **voie 1 livrée** — acté en doctrine (`team-kernel.md:55-89`) ; **voie 2 non livrée** — `backgroundDispatch` compte 24 occurrences sur 872 fichiers suivis, **0 dans `.planning/upstream/`** (1 seul fichier, sans rapport avec M2) : aucune remontée amont du descripteur n'a été rédigée ni déposée | 24-01, 24-10 |
| **M3** — « `effort:` déclaré par **aucun** agent » | **PÉRIMÉ** — **31 agents sur 31** le déclarent (25 en `agents/<nom>.md` **+ 6 en `AGENT.md`** de module : le second balayage est celui que le cadrage oubliait) | 24-01 |
| **A1** — `workflow.windows_enforce` absent → défaut `false` | **PÉRIMÉ** — présent et à **`true`** (dégel, ADR-066) | 24-02 |
| **A2** — `agent_skills: {}` | **PÉRIMÉ** — slot **PLANNER ouvert** (2 skills) ; `gsd-executor` délibérément non câblé | 24-03 |
| **A3** — `tdd_mode` à `false` | **inchangé, par décision écrite** — clé non posée | 24-03 |
| **A4** — profils de contexte non employés | **refusés**, par décision écrite | 24-07, ADR-068 |
| **A5** — deux hooks opt-in inertes | `hooks.workflow_guard` **à `true`** ; `hooks.community` **refusé** | 24-02 |
| **A6** — `inline_plan_threshold`, levier inconnu | **chiffré**, laissé au défaut | 24-07 |
| **A7** — `intel` jamais instruit | **PÉRIMÉ** — `intel.enabled: true` | 24-06 |
| **A8** — routes vers des gestes inertes, test aveugle à l'activation | `graphify` et `profile-pipeline` **refusés**, entrées de doc **marquées conditionnelles**, et le trou **fermé par un gate** (`check-capability-activation.sh`) câblé au job `gates` de la CI | 24-06, 24-11 |
| **A9** — workstreams : « notre propre outillage est aveugle » | **PÉRIMÉ sur les deux volets.** Outillage : les quatre gates sont workstream-aware et exercés en CI sur un arbre réellement partitionné. **Adoption : ACQUISE** depuis `ADR-069` (2026-08-04) — voir la décision ci-dessous | 24-04, 24-05, 24-08, 24-09 |

**La décision A9, écrite : ADOPTION — *option C de l'arbitrage* (`24-ARBITRAGES.md` § Zone 5), soit
la *voie (a) du lettrage historique de ce ROADMAP* — avec ses quatre limites datées et la condition
dure « aucune partition tant qu'une phase est en vol ».** L'usage restreint sous liste d'exclusions
(option **B** de l'arbitrage = voie `(c)` du ROADMAP) est **explicitement rejeté** par ADR-069, tout
comme le refus (options **A** et **D**). Cf. l'encadré « Lettrage » plus haut dans cette section.
`ADR-069` acte la révision de l'**Iron Law 2** (« *Router, jamais forker — une capacité amont
partiellement couverte se câble en écrivant ses limites, elle ne se réimplémente pas* ») et grave
la couverture **avec son critère et sa commande rejouable**, parce qu'un nombre sans critère est
précisément ce qui avait produit trois chiffres inconciliables. **Re-dérivé le 2026-08-04 au soir
par la commande d'ADR-069 elle-même**, identique au fichier près :

| Critère | Ce qu'il demande | Workflows | Couverture | En dur | Aveugles |
|---|---|---|---|---|---|
| K1 | le mot `workstream` seul | 5 | 5,5 % | 45 | 43 |
| **K2** | **`workstream` ou `--ws` — *résout un scope*** | **7** | **7,7 %** | **45** | **42** |
| K3 | K2 ou `GSD_WS` — toute forme de surface | 16 bruts / 15 réels | 17,6 % / 16,5 % | 45 | 35 |

Univers : **91 workflows** de `@opengsd/gsd-core` **1.9.1**, compteur d'**atteinte** inclus dans la
commande (`atteinte=91`) — une invocation antérieure avait rendu **4** en silence. Le **« 37 en
dur »** qui figurait dans ce document n'a jamais été réconcilié : la mesure est **45**, et les
**42** aveugles sont ceux du critère **K2**.

**Requirements**: GSDA-01 → GSDA-22 (créés au plan du 2026-08-04 — préfixe `GSDA`, « GSD
Activation », distinct du `GSDC` de la Phase 23 ; détail et mapping aux plans dans
`.planning/REQUIREMENTS.md`)
**Depends on:** Phase 23 — dépendance **doctrinale**, pas de fichiers : la 23 écrit la table des
capabilities et la voie unique ; la 24 décide quoi activer dedans. Activer avant de savoir qui
couvre quoi reviendrait à empiler des étages sur un couplage encore implicite. Le **lot MESURE**
est en revanche exécutable **sans attendre** la 23 (lecture et instrumentation seules, aucun
fichier de doctrine touché) — et M2 gagne à être connu tôt.
**Plans:** 12/12 plans executed

Plans:

- [x] 24-01-PLAN.md — **Lot MESURE, M1 + M3** : profondeur de dispatch et parallélisme gravés dans
  les agents ; `effort:` propagé sur **31 agents sur 31** (barème par rôle) et exigé par
  `check-agents.sh`. `GSDA-20/21/22`.
- [x] 24-02-PLAN.md — **Zone 2** : `workflow.windows_enforce` et `hooks.workflow_guard` **activés**
  (dégel, **ADR-066** — un prérequis de version insatisfiable ne gate pas) ; `hooks.community`
  **refusé**. `GSDA-01/04/05/06`.
- [x] 24-03-PLAN.md — **Zone 1** : slot `agent_skills` **PLANNER** ouvert (la doctrine du lab
  atteint enfin `gsd-planner`) ; `tdd_mode` non posé, par décision écrite. `GSDA-02/03`.
- [x] 24-04-PLAN.md — **Zone 4** : trois gates rendus **workstream-aware**, sur une politique de
  nom **partagée** et conforme au moteur amont. `GSDA-13/14`.
- [x] 24-05-PLAN.md — **Zone 4** : `check-workstream-pointer.sh` — l'auto-nettoyage silencieux du
  moteur rendu **audible**, câblé au `SessionStart`. `GSDA-16`.
- [x] 24-06-PLAN.md — **Zone 3** : `intel` **activé** (la promesse publiée par notre doc devient
  tenue) ; `graphify` et `profile-pipeline` **refusés**, et les refus **indexés**. `GSDA-07/08`.
- [x] 24-07-PLAN.md — **Zones A4/A6** : profils de contexte **refusés** (**ADR-068**), seuil inline
  **chiffré** et laissé au défaut. `GSDA-10/11`.
- [x] 24-08-PLAN.md — **Zone 4** : les agents `vf-*` savent enfin dire au moteur **sur quel scope**
  ils travaillent. `GSDA-15`.
- [x] 24-09-PLAN.md — **Zone 4, CI** : les gates workstream exercés sur un arbre **réellement
  partitionné**, fixture prouvée **discriminante**, + non-régression sur la racine. `GSDA-17`.
- [x] 24-10-PLAN.md — **Zone 5** : **ADR-069** — Iron Law 2 révisée (« router, jamais forker »),
  couverture workstreams gravée **avec son critère et sa commande**, remontée amont déposée.
  `GSDA-12/18/19`.
- [x] 24-11-PLAN.md — **Zone 3, la cause** : `check-capability-activation.sh` — une entrée de doc
  ne peut plus promettre un geste inerte ; câblé au job `gates` de la CI. `GSDA-09/08/15/02`.
- [x] 24-12-PLAN.md — **Clôture** : **10 modules** bumpés (dont 2 mono-agents que le plan avait
  sous-recensés), compteur de suites des deux README recalé, `check-version-sync.sh` vert, et la
  **frontière de release non franchie** — 0 ligne d'écart depuis `main`.

> **Ce que cette checklist ne dit pas.** Douze plans exécutés ne valent pas phase close : le gate
> de sécurité reste **bloquant** (`24-SECURITY.md`, `threats_open: 1`) sur `T-24-02-01`, qui
> demande une **décision humaine** de re-disposition et non du code. Aucun tag, aucune release :
> la release racine est un geste humain gaté (`CLAUDE.md` § Discipline de release).

### Phase 25: Budget d'instructions et étage d'alignement court

> **Origine** — audit du 2026-07-31 de `shanraisshan/claude-code-best-practice` (65k ★, veille
> communautaire Claude Code), demandé par Samuel pour vérifier si le pari GSD tenait. Verdict sur
> ce point : **GSD y est cité** (rang 7/12 des workflows, `README.md:122`) — la ligne pointait
> simplement le repo archivé, corrigé en amont par PR #169. Deux constats **méthodologiques**
> survivent à l'audit et n'appartiennent ni à la Phase 23 ni à la Phase 24 : ils sont ci-dessous.
> Source primaire commune : Dex Horthy (HumanLayer), *« Everything We Got Wrong About
> Research-Plan-Implement »*, MLOps Community, 2026-03-24.

**Goal**: Corriger deux défauts de **notre propre couche**, indépendants du moteur — (a) la densité
d'agents et de skills est bornée par une métrique qui ne prédit pas l'adhérence, (b) le seul
document que l'humain relit avant l'écriture du code est trop long pour être relu. Les deux
attaquent la même chose : **ce que le modèle suit réellement, et ce que l'humain peut réellement
corriger avant qu'il soit trop tard.**

**Le point de départ n'est ni une panne ni un couplage — c'est un mauvais instrument de mesure
dans un cas, un artefact manquant dans l'autre.**

#### G1 — Le budget d'instructions n'est pas mesuré

Fait amont : les LLM frontier suivent **~150-200 instructions** avec constance ; au-delà,
l'adhérence devient stochastique. HumanLayer l'a payé cash — leur méga-prompt `create_plan`
portait **85 instructions** et **sautait ses étapes à plus haute valeur ~50 % du temps** (poser les
questions, aligner avant d'écrire). Le correctif qui a marché n'a pas été une meilleure rédaction
mais le **découpage** : `research → plan → implement` est devenu sept prompts de moins de 40
instructions chacun.

État du lab : **ADR-029 borne les lignes** (agents ≤ 250, skills ≤ 500) et `check-agents.sh`
l'applique. Les lignes sont un proxy défaillant — une skill de 200 lignes portant 90 impératifs
est plus dangereuse qu'une de 400 lignes en portant 30. Nous mesurons le volume, pas la charge
d'instruction, et rien ne dit aujourd'hui laquelle de nos briques est en zone rouge.

À trancher au plan : la métrique exacte (quelles formes comptent comme instruction normative), le
seuil, la portée (agents seuls ou agents + skills), et si le dépassement **bloque** ou **signale** —
recouper avec l'Axiome 1 et la doctrine ADR-031.

#### G2 — L'étage d'alignement court manque entre `discuss` et `plan`

Fait amont : *« Don't read the plans. Please read the code. »* Un plan de 1000 lignes produit
~1000 lignes de code à 10 % près — le relire n'est pas du levier, c'est le même travail deux fois,
et le code livré diffère du plan. Leur substitution : un **design doc ~200 lignes** puis un
**structure outline de 2 pages** (« si le plan est l'implémentation, l'outline c'est le fichier
`.h` ») revus **avant** l'écriture, où une correction coûte une phrase au lieu d'un refactor.

État du lab, **vérifié sur pièce** (Phase 22) : l'étage « design » **existe déjà** —
`22-CONTEXT.md` fait **361 lignes** et porte frontière, décisions et références. C'est l'étage
**outline** qui manque : le document réellement soumis au jugement humain reste PLAN.md, soit
**1291 lignes sur 3 plans** pour cette seule phase. Le dernier point de correction bon marché
n'existe pas.

Corollaire à instruire : le même travail établit que les modèles écrivent **systématiquement des
plans horizontaux** (toute la DB, puis toute l'API, puis tout le front) et qu'**aucun prompt ne
l'empêche** — l'outline est le seul correctif structurel connu. Le lab **pratique** déjà le
tracer-first (3 plans Phase 22) **sans l'avoir doctriné** : à acter comme règle ou à écarter
explicitement.

À trancher au plan : forme de l'artefact (document propre, section de CONTEXT.md, ou capability
accrochée à `plan:pre`), et si CONTEXT.md doit maigrir en conséquence plutôt que s'ajouter à la
pile.

#### Frontières — ce que cette phase ne fait pas

- **vs Phase 23 (couplage explicite au moteur).** G2 insère un étage dans la chaîne
  `discuss → plan`. Le point d'insertion **ne peut pas être décidé** avant que la voie unique
  d'invocation et la doctrine de flags soient arrêtées. Cette phase **dépend** de 23 et ne la
  préempte pas ; si l'artefact prend la forme d'une capability `plan:pre`, la table
  capabilities/hooks de la Phase 23 fait foi.

- **vs Phase 24 (activation et mesure).** M3 (`effort:` par rôle) et A2 (`agent_skills`)
  éditent tous deux `plugin/*/agents/*.md` — les fichiers mêmes sur lesquels G1 pose un gate.
  Ordonnancement **après 24** pour ne pas calibrer un seuil sur un état qui bouge, et pour éviter
  les éditions concurrentes.

- **G1 n'est pas une capability GSD.** C'est une règle de densité propre à VibeFlow (ADR-029)
  outillée par notre propre gate. Aucun recouvrement avec le lot ACTIVATION de la Phase 24.

**Requirements**: TBD (à mapper au ledger pendant le plan)
**Depends on:** Phase 24 (et Phase 23 pour le volet G2)
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 25 to break down)

### Phase 26: Manuel utilisateur VibeFlow (manual/)

**Goal:** Créer un manuel utilisateur « vitrine » sous `manual/` à la racine — destiné aux humains
qui arrivent sur le repo, distinct des docs de gestion de projet (`docs/`, `.planning/`) et
volontairement hors du contexte des agents qui maintiennent VibeFlow. Arborescence thématique à
préfixes numériques (get started/install, philosophie, cycle de dev, équipe d'agents, sous le
capot…) qui descend progressivement dans la profondeur : pages courtes (un sujet = un fichier, on
divise plutôt qu'allonger), chaînées par navigation `← Précédent · ↑ Sommaire · Suivant →`, index
`manual/README.md` avec carte du manuel (graphiques mermaid) et tutos. Bilingue FR + EN (comme les
deux README). `README.md`/`README.fr.md` et `INSTALL.md` maigrissent et pointent vers le manuel au
lieu de dupliquer — le manuel devient la version guidée et pédagogique.

> **Amendement de mission (2026-08-01)** — `manual/` **reste local, hors git** (`.git/info/exclude`,
> aucune entrée `.gitignore`). Aucun fichier du manuel n'entre dans un commit. Le volet « les README
> maigrissent et pointent vers le manuel » est **SUSPENDU, pas abandonné** : pointer vers un dossier
> absent du dépôt casserait les liens des visiteurs. `README.md`, `README.fr.md`, `INSTALL.md`,
> `scripts/` et `.github/` sortent du périmètre d'écriture ; l'outillage vit sous `manual/.tools/`
> et n'entre pas en CI. Seuls `.planning/**` sont committés.
> Cadrage complet : `.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md` (D-1 à D-13) et
> `.planning/phases/VFDO-26-manuel-utilisateur-vibeflow-manual/26-CONTEXT.md` (D-01 à D-14).

**Requirements**: aucun ID formel — `REQUIREMENTS.md` ne porte aucun `REQ-` pour cette phase (le
ledger s'arrête à ALTI-05 / Phase 14), même convention que les Phases 15 à 21. La traçabilité est
assurée par les **décisions D-01 à D-14** de `26-CONTEXT.md` et les **manques M-1 à M-12** de
`26-INVENTAIRE-MATIERE.md`, repris par le champ `must_haves` de chaque `26-0N-PLAN.md`.
**Depends on:** Phase 25
**Plans:** 9/9 plans executed

Plans:

- [x] 26-01-PLAN.md — Infrastructure : `toc.yml` (D-03), `manual/.tools/build-nav.sh` (nav générée), `manual/.tools/check-manual.sh` (gate à 7 contrôles, refus du verdict vide, D-13), `manual/README.md` bilingue (vague 1)
- [x] 26-02-PLAN.md — Priorité du mandat 1/2 : les deux README de langue (carte mermaid décorative + navigation réelle, D-06) et le thème `01-demarrer` complet FR+EN, 7 pages — comble M-1, M-6 (scope), M-12 (vague 2)
- [x] 26-03-PLAN.md — Priorité du mandat 2/2 : thème `02-concepts` complet FR+EN, 7 pages — comble M-2 (glossaire produit), M-3 (« lab » enfin défini), M-5 (VibeFlow ↔ GSD ↔ Superpowers) ; documente 9 principes sourcés du canon (D-09) (vague 3)
- [x] 26-04-PLAN.md — Thème `03-modules` FR+EN, 6 pages : catalogue et choix de modules **dérivés du disque**, zéro version en dur (D-11) — comble M-6 (modules) (vague 4)
- [x] 26-05-PLAN.md — Thème `04-cycle-de-dev` FR+EN, 6 pages : cadrer → planifier → exécuter → livrer, écrit du point de vue de l'humain (vague 5)
- [x] 26-06-PLAN.md — Thème `05-equipe-agents` FR+EN, 6 pages : missions longues, ce qu'on vous demande (M-8), branches et worktrees (ADR-059, ADR-064) (vague 6)
- [x] 26-07-PLAN.md — Thème `06-reference` FR+EN, 6 pages : commandes/skills/agents énumérés depuis le disque (D-11) — comble M-7 (dépannage après install) et M-11 (coût et modèles) (vague 7)
- [x] 26-08-PLAN.md — Thème `07-sous-le-capot` FR+EN, 6 pages : anatomie d'un lab installé (M-4), engine d'install, gates, 15 ADR à valeur utilisateur, pont vers `docs/` (vague 8)
- [x] 26-09-PLAN.md — Clôture : ROADMAP et STATE recalés sur le réel livré, **checkpoint humain bloquant** puis unique commit de la phase, par chemins explicites (D-14, one-way) (vague 9)

**Découpe différable.** Les vagues 4 à 8 (un thème chacune, bilingue) peuvent être différées sans
casser le manuel ni son gate : `toc.yml` ne référence à tout instant que des pages réellement
écrites dans les deux langues, donc un arrêt entre deux vagues laisse un manuel plus court et
cohérent, `check-manual.sh` au vert. La priorité du mandat est tenue dès la vague 3.

### Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture

> **Origine** — demande directe de Samuel le 2026-08-05, à la clôture de la Phase 24 : « parallélisation
> complète, simple et granulaire. Le but est de gagner du temps d'exécution sans que les agents se
> marchent dessus. » La recherche de cadrage (2026-08-05, scratchpad `parallel-research.md`) a
> **renversé la prémisse** sur laquelle la demande reposait — voir ci-dessous.

> **Spec** : `docs/superpowers/specs/2026-08-05-parallelisation-execution-design.md`
> **Recherche** : `.planning/research/2026-08-05-parallelisation-execution.md`

**Goal**: Prendre un gain de vitesse **déjà disponible et non pris**, et le rendre **sûr par
construction**. La Phase 24 avait conclu que le parallélisme intra-étape était *perdu* ; la
re-vérification montre qu'il est seulement **désactivé par défaut**. Dans le même temps, la
disjonction des périmètres — la seule chose qui empêche deux agents de s'écraser — est aujourd'hui
**déclarée mais jamais calculée**. La phase doit donc fermer l'écart dans les deux sens : activer ce
qui dort, et outiller ce qui n'est tenu que par le jugement.

#### La correction de prémisse — le parallélisme intra-étape n'est pas perdu, il est éteint

`plugin/conductor/references/team-kernel.md:64-65` affirme que le parallélisme intra-étape est
« **perdu** ». **C'est faux, et la doctrine livrée doit être corrigée.** Ce qui est vrai :
`shouldFlattenDispatch()` rend bien `true` sous Claude Code (re-vérifié le 2026-08-05) — mais le
chemin qui restaure le parallélisme **ne passe pas par cette fonction**. La capability
`claude_orchestration` s'appuie sur l'outil **Workflow**, et son gate n° 4 lit `nested && background`
(tous deux `true` ici), **jamais `backgroundDispatch`**. Le commentaire amont le dit mot pour mot :
*« sidestepping the backgroundDispatch:false limitation »* (`claude-orchestration.cjs:186-192`).

Le seul verrou réel est le **gate n° 5** : `agent_sdk_version_unknown`. Claude Code embarque son SDK
dans un binaire au lieu de l'exposer en paquet npm, donc le routeur ne trouve aucune version sur
disque. La variable `GSD_AGENT_SDK_VERSION` est le contournement documenté en amont
(`claude-orchestration-command-router.cjs:157`).

#### Le chiffre qui devrait décider la phase

Le partitionneur amont (`partitionStages`) a été appliqué aux **12 plans réels de la Phase 24** :

| Vague | Plans | Étages après partition | Paires en collision de fichier |
|---|---|---|---|
| 1 | 5 | 1 | **0** |
| 2 | 4 | 1 | **0** |
| 3 | 2 | 1 | **0** |
| 4 | 1 | 1 | 0 |

**12 exécutions sérielles → 4 étages, soit un plafond de 3,00×** — et **zéro collision de fichier sur
les quatre vagues**. Le planificateur produit déjà des vagues parfaitement disjointes : le
parallélisme est **sûr et gratuit aujourd'hui**. C'est un **plafond d'étages mesuré, pas un gain
d'horloge** — la distinction est à tenir dans toute la phase.

#### Le trou de granularité, mesuré

`dag.sh` déclare un champ `scope[]` par nœud mais **ne calcule jamais** la disjonction. Testé :
trois nœuds dont **deux déclarent le même fichier** → `ready: ["a","b","c"]`. **Les deux écrivains du
même fichier sortent en parallèle.** La sécurité du parallélisme inter-nœuds ne repose donc sur
aucune machine — seulement sur le jugement du manager, à chaque dispatch.

Piège de nommage à ne pas répéter : `check-overlaps.sh`, malgré son nom, traite du **routage entre
briques tierces** (ADR-057), pas des périmètres d'écriture.

#### Les workstreams ne sont pas l'outil — c'est mesuré

Samuel demandait de s'en inspirer. `grep -c "workstream" execute-phase.md` → **0** : le workflow qui
dispatche les agents **ne connaît pas le concept**. Les workstreams compartimentent le **planning**
(feuille de route, état), jamais l'**exécution**. Le mécanisme qui répond au besoin s'appelle
`isolation: worktree`.

> **Chiffres divergents, à ne pas recopier.** La recherche obtient **6** fichiers mentionnant
> `workstream` et **73** codant `.planning/` en dur, là où la Phase 24 (ADR-069) grave **7/91** et
> **45**. L'écart sur 45 → 73 est trop large pour du bruit. À re-dériver avec un critère nommé avant
> toute citation ; ADR-069 fait foi jusque-là.

#### Les trois options, et le chemin

| | Option | Coût | Gain | Nature |
|---|---|---|---|---|
| **1** | **`isolation: worktree` en frontmatter d'agent** | frontmatters + `.gitignore` (`.claude/worktrees/` non couvert) + `.worktreeinclude` (absent) | **aucun gain de vitesse** | **prérequis de sécurité** — `check-agents.sh` liste déjà `isolation` dans ses `KNOWN` et n'admet que `worktree`, mais **0 agent sur 25** le déclare |
| **2** | **Activer `claude_orchestration`** | **zéro ligne de logique**, repli fail-closed intégral | **1,8–2,5× d'horloge estimé** (dit comme estimé) | active une capacité amont déjà écrite |
| **3** | **Porter le partitionneur dans `dag.sh`** | réimplémentation locale | — | **à ne pas faire maintenant** : duplique l'amont, exactement ce que l'Iron Law 2 révisée (ADR-069) proscrit |

**Chemin proposé : 1 → spike de 2 → 2.** L'option 1 d'abord parce qu'elle ne fait rien gagner mais
rend le reste sûr ; le spike parce que l'option 2 change le mode de dispatch de toute exécution.

#### Les deux points qui appellent un arbitrage humain, pas une décision technique

**A — Le mur ADR-031.** Un workflow **n'accepte aucune entrée utilisateur en cours de run**, et ses
sous-agents tournent **toujours en `acceptEdits`** — éditions auto-approuvées quel que soit le mode
de session. Or ADR-031 (« jamais de fix sans validation humaine ») est un socle du lab, et le
team-kernel a déjà vu une mission gelée par un `AskUserQuestion` indisponible en dispatch sous-agent.
Le repli documenté (« un étage = un workflow ») existe mais doit être **re-prouvé sous Workflow**.

**B — `worktree.baseRef`.** Le défaut `"fresh"` branche depuis `main` et **ferait perdre le travail en
cours** d'une mission. `"head"` semble requis — mais c'est un réglage **global**, donc un choix qui
engage au-delà de cette phase.

#### Contraintes non négociables

- **Simple avant complet.** Samuel l'a posé en premier. Une solution qui demande de penser à trois
  choses avant chaque dispatch ne sera pas tenue, donc ne comptera pas.
- **Corriger la doctrine fausse** de `team-kernel.md:64-65` fait partie du périmètre — une doctrine
  livrée qui affirme « perdu » là où c'est « éteint » induit chaque lecteur en erreur.
- **Aucune régression de sécurité de la Phase 24** — le motif d'échappement par lien symbolique en
  était à son quatrième passage ; toute primitive de chemin passe par les primitives partagées de
  `workstream-policy.sh`, jamais par une réimplémentation locale.
- **Tout chiffre gravé porte sa méthode et se re-dérive au moment de l'écriture** — la Phase 24 a
  produit quatre décomptes justes portant sur le mauvais ensemble, et la divergence 45 → 73
  ci-dessus en est la cinquième occurrence.
- **La mesure du gain est un livrable, pas une promesse** : baseline d'horloge avant, mesure après,
  méthode écrite. Un plafond d'étages n'est pas un gain d'horloge.

**Plans**:
- [ ] TBD (run /gsd-plan-phase 27 to break down)
