# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- ✅ **install-ux-v1.0** — Phases 2-6 — clôturé 2026-06-05 (plugin + skill à toggles + scope) — release `v2.4.0`
- ✅ **dev-doctrine** — Phases 7-8 — doctrine dev (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) + consolidation des doublons qualité — clôturé 2026-07-07 — release `v2.20.0`
- ✅ **memory-swarm-rnd** — Phase 9 — R&D : transposition du modèle mémoire + patterns swarm de jcode — spike GO, shippé `v2.28.0` (ADR-052 mémoire vivante + ADR-053 swarm)
- ✅ **gsd-migration** — Phases 10-11 — clos 2026-07-26, release `v2.39.0` — migration du package GSD `get-shit-done-cc` → `@opengsd/gsd-core@^1` (VOC-02)
- ✅ **vf-routing** — Phases 12-14 — clos 2026-07-26, release `v2.37.0` — routage fin des intentions (verbes `/vf-*` à l'origine ; carte d'intention agentique depuis la bascule v2.33.0), couverture complète des skills GSD, pont spec → feuille de route, et frontière d'altitude avec le moteur de planning GSD
- ✅ **agentique-v1.0** — Phases 15→29 (18 et 25 reportées) — **clos 2026-08-15**, releases `v2.40.0` → `v2.52.0` — durcissement du moteur d'équipes agentique : collaboration inter-équipes, cloisonnement, migration `/vf-update`, alignement gsd-core, couplage et activation du moteur GSD, manuel, parallélisation, gate armement ↔ précondition (*as-installed testing*), gains ICM. **Absorbe `gsd-alignement`** (ouvert 2026-08-01 pour les phases 23-25 ; 23-24 livrées ici, 25 reportée) et solde la dérive du label `gsd-migration` resté dans STATE trois semaines après sa clôture.
- 🚧 **fiabilite-v1.0** — « ce qui survit » — Phases 30-35 + Phases 18 et 25 héritées — **démarré
  2026-08-15** — fermer les dettes de gouvernance nées d'incidents réels du milestone précédent
  (driver-lock contourné ×2, stall silencieux de 18 h, dérive du ledger re-constatée, régression
  #38) et rendre l'install/update digne de confiance sur toutes les plateformes — Windows en tête
  (demande client). Périmètre arbitré par Samuel le 2026-08-15 (familles PORT/MANI/LOCK/WTCH/LEDG/
  BUDG/WKTR/SKIL/AGTS + QUAL-01 transverse). Recherche : `.planning/research/SUMMARY.md` +
  `ARCHITECTURE.md` (ordre de construction dicté par les fichiers).

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
- [x] Phase 18: Survie du ledger d'exigences à la clôture de jalon (completed 2026-08-18 — 3 plans exécutés, non shippée : PR/tag/release restent des gestes humains non posés)
- [x] Phase 19: Migration du moteur GSD pilotée par /vf-update (completed 2026-07-28)
- [x] Phase 20: Fluidité du flux de dev sans perte de qualité (completed 2026-07-31)
- [x] Phase 21: Alignement du moteur GSD sur gsd-core 1.9.0 (completed 2026-07-31)
- [x] Phase 22: Hygiène documentaire — doctrine de sortie et captation d'intention (completed 2026-07-31)
- [x] Phase 23: Couplage explicite au moteur GSD — capabilities, flags et voie unique
- [x] Phase 24: Activation et mesure du moteur GSD — capacités dormantes et faits de runtime (completed 2026-08-05, PR #34)
- [ ] Phase 25: Budget d'instructions
- [x] Phase 26: Manuel utilisateur VibeFlow (manual/) (completed 2026-08-02)
- [x] Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture (completed 2026-08-06)
- [x] Phase 28: Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur (completed 2026-08-15)
- [x] Phase 29: Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord (completed 2026-08-15)
- [x] Phase 30: Portabilité Windows II (completed 2026-08-16)
- [x] Phase 31: Manifeste d'install + dry-run (issue #20) (completed 2026-08-16)
- [x] Phase 32: Durcissement du driver-lock (completed 2026-08-17)
- [x] Phase 33: Watchdog & notifications des missions (completed 2026-08-17)
- [ ] Phase 34: Gaps agency-agents & cadrage skill-installer
- [x] Phase 35: Ré-armement worktree (conditionnelle) — CLOSE 2026-08-26, option A (pas de ré-armement)
- [x] Phase 37: Portabilité multi-runtime — spike (Codex, OpenCode, Kimi) (completed 2026-08-28 — spike + étude livrés, décisions rendues ; suite → Phase 38)
- [~] Phase 38: Portabilité multi-runtime — livraison (canal d'install, migration de lab, adaptateur) (exécutée 2026-08-29 — **critère 2 NON PROUVÉ** : aller-retour manager→worker à profondeur 1/2, quota Codex épuisé jusqu'au 2026-09-27 ; **critère 1 partiel** : hooks non portés, perte déclarée ; non shippée, runbook de mesure finale posé)

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
1 ✅ → 2 ✅ → 3 ✅ → 4 ✅ → 5 ✅ ; 6 ✅ indépendant → 7 ✅ → 8 ✅ ; **9 ✅ (R&D, shippée v2.28.0)** ; **10 🚧 → 11 🚧 (GATE : 11 conditionné au GO de 10)** ; **12 ✅ → 13 ✅ (code complet, release en attente de validation humaine)** ; **14 ✅ (indépendante)** ; **15 ✅ (shippée v2.40.0) → 16 ✅ (shippée v2.41.0)** ; **17 ✅ (indépendante de 16, terminée et vérifiée — release en attente de validation humaine) → 18 inscrite (dépend de 17)** ; **19 ✅ (2026-07-28, ADR-058) → 20 ✅ (mergée dans `main` le 2026-07-31, PR #21, release `v2.44.0`)** — ce merge **satisfait** la dépendance « Phase 20 requise » de 21, 22 et 23 ; **21 ✅ (mergée le 2026-07-31, PR #22, release `v2.45.0`) + 22 ✅ (mergée le 2026-07-31, PR #23)** — les deux livrées par la mission `reprise-p21-p22`, sans fichier commun ; leur clôture **lève la dépendance** de 23 → **23 inscrite**, périmètre partagé sur `vf-dev-manager.md` / `intent-routing.md` (arbitré le 2026-07-31 : on ne planifie pas contre une base qui bouge ; l'arbitrage des étages de revue écrit par la 21 fait autorité) → **24 inscrite (dépendance doctrinale de 23, aucun fichier commun ; son lot MESURE est déjà rendu)** → **25 inscrite : après 24** (son volet G1 pose un gate sur `plugin/*/agents/*.md`, les fichiers mêmes que M3/`effort:` et A2/`agent_skills` éditent) **et dépendante de 23** (son volet G2 insère un étage dans `discuss → plan`, dont la voie unique d'invocation est arbitrée en 23) ; **milestone fiabilite-v1.0 (2026-08-15)** : **30 → 31 (strictement séquentielles — mêmes fichiers `_internal/`) → 32 → 33 (adjacentes — heartbeat partagé, WTCH après LOCK) → 18 (héritée — livrée avant clôture ; sa RFC part en Phase 30) → 34 → 25 (héritée — avant-dernière, après tout ajout d'agents)** ; **35 flottante conditionnelle** (gsd-core > 1.10.0 releasé ET installé), jamais bloquante

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
| 18. Survie du ledger d'exigences | fiabilite-v1.0 | 0/0 | Not started — héritée (périmètre réduit 2026-07-28, `STUDY.md`) ; LEDG-03 (RFC) portée par la Phase 30 | — |
| 19. Migration du moteur GSD par /vf-update | — | 3/3 | Complete — 3 plans exécutés, VERIFICATION produite, module `dev-orchestrator` v2.7.0 + `conductor` v1.16.0, ADR-058 | 2026-07-28 |
| 20. Fluidité du flux de dev sans perte de qualité | — | 7/7 | Complete — **mergée dans `main`** (PR #21, `d549b2d`), release `v2.44.0`, VERIFICATION produite | 2026-07-31 |
| 21. Alignement du moteur GSD sur gsd-core 1.9.0 | — | 5/5 | Complete — **mergée dans `main`** (PR #22, `d89a60e`), release `v2.45.0`, VERIFICATION produite, ADR-061/062/063 | 2026-07-31 |
| 22. Hygiène documentaire — doctrine de sortie | — | 3/3 | Complete — **mergée dans `main`** (PR #23, `474c3eb`), `dev-orchestrator` v2.9.0 + `design-orchestrator` v1.4.0 | 2026-07-31 |
| 23. Couplage explicite au moteur GSD | agentique-v1.0 | 8/8 | Complete — 8 SUMMARYs sur disque | 2026-08-04 |
| 24. Activation et mesure du moteur GSD | agentique-v1.0 | 12/12 | Complete — 12 SUMMARYs sur disque | 2026-08-04 |
| 25. Budget d'instructions | fiabilite-v1.0 | 0/0 | Not started — héritée, périmètre réduit à BUDG-01/02 (G2/BUDG-03 différé) ; après la Phase 34 | — |
| 26. Manuel utilisateur VibeFlow (manual/) | gsd-alignement | — | Complete (PR #28) | 2026-08-02 |
| 27. Parallélisation d'exécution — granulaire, simple, sans collision | gsd-alignement | 6/6 | Complete (PR #35) — spike `claude_orchestration` refusé par écrit | 2026-08-10 |
| 28. Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur | agentique-v1.0 | 3/3 | Complete — PR #42, release `v2.52.0`, CI main verte, gate + `lab-frais-arme` livrés | 2026-08-15 |
| 29. Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord | — | 5/5 | Complete (PR #41) — release `v2.51.0`, D-03 tenue (`dag.sh` hors diff), checkpoint humain T-29-05-3 tranché le 2026-08-15 | 2026-08-15 |
| 30. Portabilité Windows II | fiabilite-v1.0 | 8/8 | Complete — PR #43, release `v2.53.0`, CI verte (run 31918283177, 4/4 jobs) | 2026-08-16 |
| 31. Manifeste d'install + dry-run (issue #20) | fiabilite-v1.0 | 8/8 | Complete — 8 SUMMARYs sur disque, module `conductor` v1.25.0, MANI-04 superseded (réponse #20 en DRAFT, jamais postée) | 2026-08-16 |
| 32. Durcissement du driver-lock | fiabilite-v1.0 | 0/0 | Not started — son hook naît en forme exec (après 30) ; spike `reference-transaction` avant LOCK-03 | — |
| 33. Watchdog & notifications des missions | fiabilite-v1.0 | 0/0 | Not started — heartbeat partagé avec la 32 (conçues ensemble, WTCH après LOCK) | — |
| 34. Gaps agency-agents & cadrage skill-installer | fiabilite-v1.0 | 0/0 | Not started — après la 31 (MANI avant SKIL) ; SKIL-01 = cadrage go/no-go rattaché | — |
| 35. Ré-armement worktree (conditionnelle) | fiabilite-v1.0 | 0/0 | Flottante — précondition externe NON satisfaite au 2026-08-15 (npm latest = 1.10.0) ; jamais bloquante | — |
| 37. Portabilité multi-runtime — spike | fiabilite-v1.0 | — | Complete — spike de mesure sans plan : DISCUSS + SPIKE-REPORT + ETUDE-CANAL-ET-MIGRATION (3 tours de revue adversariale), décisions rendues le 2026-08-28, branche `feat/phase-37-spike-portabilite-multi-runtime` non mergée | 2026-08-28 |
| 38. Portabilité multi-runtime — livraison | fiabilite-v1.0 | 0/0 | Not started — cadrage factuel = livrables de la 37 ; 6 lots candidats, go/no-go adaptateur à trancher au cadrage | — |

<details>
<summary>✅ agentique-v1.0 — Durcissement du moteur d'équipes agentique (Phases 15→29, 18 et 25 reportées) — SHIPPED 2026-08-15</summary>

13 phases livrées, releases `v2.40.0` → `v2.52.0`. Absorbe `gsd-alignement`.
Snapshots : `.planning/milestones/agentique-v1.0-*`. Détails : `MILESTONES.md`.

</details>

## 🚧 Milestone fiabilite-v1.0 — « ce qui survit » (Phases 30-35 + 18 et 25 héritées)

**Milestone Goal :** fermer les dettes de gouvernance nées d'incidents réels du milestone précédent
(deux contournements du driver-lock, un stall silencieux de 18 h, la dérive du ledger re-constatée à
la clôture d'agentique-v1.0, la régression #38) et rendre l'install/update digne de confiance sur
toutes les plateformes — Windows en tête (demande client). Périmètre arbitré par Samuel le
2026-08-15 (`REQUIREMENTS.md` §Milestone fiabilite-v1.0 : 30 IDs en 9 familles + QUAL-01
transverse). Recherche : `.planning/research/SUMMARY.md` (commit `5916899`) + `ARCHITECTURE.md`
(ordre de construction en 9 étapes, rationale fichier-niveau).

**Numérotation — arbitrage humain (2026-08-15) :** les phases héritées gardent leur numéro
historique — la 18 (dossier `VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon/`, étude
`STUDY.md`) et la 25 (dossier `VFDO-25-budget-d-instructions-et-tage-d-alignement-court/`, slug
historique conservé). Les nouvelles phases continuent la numérotation du milestone précédent,
arrêtée à 29 → elles démarrent à 30.

**Ordre de construction (non négociable — dicté par les fichiers, ARCHITECTURE.md §4) :**

- **30 → 31 strictement séquentielles** : les deux travaillent les mêmes fichiers
  `plugin/_internal/` (`vibeflow-update.sh`, `merge-hooks.sh`) — jamais en parallèle, un seul
  propriétaire du moteur à la fois.

- **30 en premier** : Windows II réécrit le contrat de sortie des hooks et la forme exec que les
  phases 32, 33 et 18 consomment — toute entrée de hook créée avant serait à re-migrer. C'est aussi
  la demande client prioritaire.

- **32 → 33 adjacentes** : LOCK et WTCH partagent le même battement (un émetteur, deux
  consommateurs) — conçues ensemble, livrées séparément, WTCH après LOCK.

- **18 avant la clôture du milestone** (sinon 3ᵉ dérive du ledger) ; sa latence externe (RFC
  upstream, LEDG-03) part dès le jour 1, portée par la Phase 30.

- **31 avant 34** : le manifeste est la fondation de tout uninstall propre — le cadrage
  skill-installer (SKIL-01) ne se décide pas sans lui.

- **25 avant-dernière** : ne jamais calibrer un seuil sur un corpus d'agents qui bouge — après la
  Phase 34 et tout ajout d'agents.

- **35 flottante, jamais bloquante** : conditionnée à une release externe (gsd-core > 1.10.0
  releasé ET installé) ; sa veille (WKTR-03) est active dès le jour 1, portée par la Phase 30.

**Critère transverse (QUAL-01), reporté sur chaque phase qui livre un gate :** le gate naît avec ses
trois issues (PASS / FAIL / imparsable BRUYANT) et sa mutation rouge prouvée — l'imparsable n'est
jamais un vert par défaut (l'ennemi n°1 du repo, incident D-04).

### Phase 30: Portabilité Windows II

**Goal**: Une install VibeFlow sur Windows pose des hooks qui fonctionnent — le substrat des hooks
(forme exec, codes de sortie normalisés, cascade `vf_python`) est réécrit une fois pour toutes, et
les deux latences externes du milestone (RFC ledger, veille gsd-core) sont lancées le jour 1.
Spec : `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md`.
**Depends on**: — (première phase du milestone). **Pré-requis de cadrage LEVÉ le 2026-08-15** :
PORT-04 a été tranché par Samuel sans Willy (le tracer 01-01 amont n'a jamais été livré) — la
Phase 30 porte l'intégralité du volet `merge-hooks.sh` ET écrit elle-même `vf-portable.sh` +
`copy_engine_lib()`. La question ouverte du contrat PR #29 (exit code de `vf_guard_unavailable`
sur PreToolUse) est close : code non nul ≠ 2. Traces : `30-CONTEXT.md` (D-01, D-02, D-04),
encart §3.2 de la spec, commentaire posté sur la PR #29.
**Requirements**: PORT-01, PORT-02, PORT-03, PORT-04, PORT-05 + gestes jour 1 : LEDG-03, WKTR-03
**Success Criteria** (what must be TRUE):

  1. La portabilité est prouvée en CI sur lab frais : suites windows-crlf + windows-guards + gates
     verts (PORT-05) — par exécution, jamais par lecture.

  2. `merge-hooks.sh` sait poser, dédupliquer (cross-forme) et retirer une entrée en forme exec
     AVANT toute migration de fragments — ordre (a) moteur → (b) codes de sortie → (c) hooks.json
     encodé en vagues dépendantes du plan (PORT-02, spec §1.3) ; un update ne double jamais un hook
     et un module reste désinstallable.

  3. Les scripts de hooks respectent le contrat de codes de sortie normalisé (0 = silence à la
     frontière harness, classement advisory/bloquant explicite), inventaire des 19 entrées réalisé
     (PORT-03) — un démarrage de session sain reste silencieux, aucun exit 2 involontaire.

  4. Les 3 fichiers du lot PYBIN passent par la lib partagée `vf-portable.sh` (contrat PR #29
     consommé, jamais réinventé) (PORT-01) ; l'affectation §3.2 est documentée avant le plan
     (PORT-04) — `guard-file-size.sh` gaté séparément si la lib tarde (tracer 01-01 Willy).

  5. Jour 1 (asynchrone, hors substrat) : la RFC upstream `open-gsd/gsd-core` (suppression de
     `REQUIREMENTS.md` rendue optionnelle) est déposée et traçable depuis le repo (LEDG-03,
     deadline amont 2026-10-26) ET la veille de release gsd-core > 1.10.0 est active
     (`npm view @opengsd/gsd-core version`, jamais le dist-tag `next`) (WKTR-03).

**Transverse (QUAL-01)** : tout gate né dans la phase (contrat de sortie, dédup cross-forme) naît
avec ses trois issues (PASS / FAIL / imparsable BRUYANT) et sa mutation rouge prouvée.
**Plans**: 8 plans (4 vagues — l'ordre spec §2 (a) moteur → (b) codes de sortie → (c) fragments est
encodé en vagues dépendantes ; les 2 gestes jour 1 sont parallèles à la vague 1)
Plans:
**Wave 1**

- [ ] 30-01-PLAN.md — tracer : `merge-hooks.sh` apprend `args` + chemin absolu de bash à l'install, l'entrée `software-architecture` migre en forme exec, suite étendue (dédup cross-forme, remove exec, sonde de parc) — vague 1 (PORT-02, PORT-04)
- [ ] 30-02-PLAN.md — geste jour 1 : RFC upstream `open-gsd/gsd-core` (brouillon, gate humain, dépôt, double traçabilité STATE/REQUIREMENTS) — vague 1 (LEDG-03)
- [ ] 30-03-PLAN.md — geste jour 1 : veille de release gsd-core (sonde à cache quotidien, suite, armement local + trace versionnée) — vague 1 (WKTR-03)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 30-04-PLAN.md — inventaire machine des 25 entrées + contrat de sortie écrit + normalisation des 4 scripts dev + suite capturant stdout/stderr séparément — vague 2 (PORT-03)
- [ ] 30-05-PLAN.md — lib `vf-portable.sh` (5 symboles, bloc localisateur) + `copy_engine_lib()` + les 3 consommateurs PYBIN + somme de contrôle du bloc — vague 2 (PORT-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 30-06-PLAN.md — normalisation du parc gouvernance (8 scripts, 4 modules) + suite de parc anti-vert-à-vide + bumps — vague 3 (PORT-03)
- [ ] 30-07-PLAN.md — les 4 entrées `dev-orchestrator` en forme exec, classées advisory + preuve as-installed + ADR de suite + bumps dev — vague 3 (PORT-02)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 30-08-PLAN.md — preuve CI sur lab frais (forme exec telle qu'installée, conditions Windows simulées) + compteurs README + CI verte constatée — vague 4 (PORT-05)

### Phase 31: Manifeste d'install + dry-run (issue #20)

**Goal**: L'install/update devient prévisible et réversible — chaque pose est tracée
fichier-par-fichier, prévisualisable sans rien écrire, et l'update supprime ce qui a disparu sans
jamais toucher un fichier tiers (le bug réel des verbes v1.x survivants ne peut plus se produire).
**Depends on**: Phase 30 (mêmes fichiers `_internal/` — strictement séquentielles, jamais
parallèles ; le `--dry-run` s'écrit une seule fois, contre le moteur de hooks final).
**Requirements**: MANI-01, MANI-02, MANI-03, MANI-04
**Success Criteria** (what must be TRUE):

  1. Chaque module posé écrit son manifeste de chemins
     (`$TARGET_ROOT/scripts/.vibeflow-manifest-<module>`, LF trié, un chemin relatif par ligne) —
     l'engine est le seul écrivain (MANI-01).

  2. `--dry-run` montre le plan de pose fichier-par-fichier (y compris le merge de hooks) sans rien
     écrire, sur le MÊME chemin de code que la pose (install + calibrate) — prouvé par un test
     « dry-run == diff disque réel », sous mutation (MANI-02).

  3. À l'update, les chemins de l'ancien manifeste absents du nouveau sont supprimés avec backup
     systématique et liste signalée à l'utilisateur ; un fichier tiers non manifesté reste intact
     (test dédié) (MANI-03).

  4. L'issue GitHub #20 est close par livraison, réponse postée sur l'issue (MANI-04).

**Transverse (QUAL-01)** : la suite `test-manifest.sh` et le contrôle dry-run naissent avec leurs
trois issues (manifeste illisible = BRUYANT) et leur mutation rouge prouvée.

> **Note sur le critère 4** : le texte ci-dessus (« close par livraison, réponse postée ») est
> **superseded par `31-CONTEXT.md` §4 point 8** — la réponse est un **BROUILLON sur disque**
> (`31-ISSUE-20-REPLY.md`), jamais postée, et l'issue n'est jamais close par la phase. Poster et
> clore sont des gestes humains (ADR-031).

**Plans**: 8 plans

Plans:
**Wave 1**

- [ ] 31-01-PLAN.md — TRACER : socle manifeste (7 fonctions) + UN site câblé bout en bout + suite `test-manifest.sh` + compteurs README — vague 1 (MANI-01, QUAL-01)
- [ ] 31-02-PLAN.md — `merge-hooks.sh` apprend le mode `plan` (régime B, D-31-04) + 5 cas de suite — vague 1 (MANI-02, QUAL-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 31-03-PLAN.md — checkpoint de ratification + migration mécanique des ~35 sites d'écriture + preuve d'exhaustivité manifeste ↔ disque — vague 2 (MANI-01, QUAL-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 31-04-PLAN.md — `--dry-run` : pré-parse, refus bruyant sur les 4 verbes destructifs, régimes A/B/C + les DEUX preuves de MANI-02 — vague 3 (MANI-02, QUAL-01)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 31-05-PLAN.md — convergence MANI-03 (six conditions, backup avant suppression) + manifeste imparsable BRUYANT + 2 mutations rouges — vague 4 (MANI-03, QUAL-01)

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 31-06-PLAN.md — câblage `/vibeflow-install` étape 5 et `/vf-calibrate` étape 4 + bumps — vague 5, **ABANDONNABLE** (MANI-02)
- [ ] 31-07-PLAN.md — `uninstall_module` lit le manifeste (D-31-09) — vague 5, **ABANDONNABLE, sacrifice désigné en premier** (MANI-01)

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 31-08-PLAN.md — brouillon de réponse à l'issue #20 (disque seulement) + bilan suite complète sur l'arbre commité — vague 6 (MANI-04, QUAL-01)

### Phase 32: Durcissement du driver-lock

**Goal**: Les deux contournements constatés pendant agentique-v1.0 (commit et checkout concurrents
sous lock) ne peuvent plus se reproduire en silence — le lock a un battement distinct de sa lease,
un enforcement à la source qui voyage avec le plugin, et un takeover toujours explicite. Le
protocole d'acquisition symlink-génération, mesuré, n'est PAS rouvert : le durcissement s'ajoute
autour.
**Depends on**: Phase 30 (son entrée de hook naît en forme exec sur le moteur final) — ordonnée
après la Phase 31 ; ne touche que `conductor`. **Research flag** : spike `reference-transaction`
git AVANT d'en dépendre pour LOCK-03 (couverture checkout incertaine) ; rejouer les 2 contournements
réels comme cas de test AVANT de choisir le mécanisme.
*Amendements de périmètre (tranchés par Samuel le 2026-08-17, après re-validation externe des plans) :*
*(a) « ne touche que `conductor` » est **faux à l'épreuve du plan**. `acquire` cessant de récupérer un*
*lock périmé (LOCK-04), **5 agents managers dans 4 modules tiers** plus `mission-flow.md` et le README*
*de `dev-orchestrator` continueraient de prescrire l'ancien contrat : un manager sur lock périmé ne*
*connaîtrait pas le verbe `takeover` et la mission gèlerait — critère 4 vert dans le code, faux en*
*production. Option **3B** retenue : synchronisation doctrinale COMPLÈTE des 7 fichiers (+ bumps des*
*modules touchés), plus un champ `hint` in-band sur le refus. S'y ajoutent trois écritures transverses*
*imposées par des gates existants : `docs/HOOKS-CONTRAT-SORTIE.md` (assertion de recomptage,*
*tolérance +1), les deux README racine (compteurs gatés par `check-version-sync.sh`), et*
*`plugin/_internal/tests/test-vf-portable.sh` (couverture checksum du bloc localisateur). Formulation*
*exacte : « aucun module tiers n'est refondu ; leur doctrine du verrou est resynchronisée, et les*
*gates machine du dépôt sont honorés ».*
*(b) **Option 4A** : le trou de la voie **legacy** du protocole d'acquisition est corrigé dans la phase.*
*Mesuré sur le script non modifié : un lock `legacy` (vrai dossier) frais et tenu par ALICE laisse*
*`acquire --owner=BOB` rendre `acquired:true` — deux détenteurs, et le cas T12 censé être le filet*
*anti-deadlock passe **par ce bug**. Nominal sur Git Bash Windows sans privilège de lien symbolique,*
*sur un milestone Windows-first. Ce n'est **pas** une réouverture du protocole symlink-génération :*
*c'est la fermeture d'un trou de sa voie legacy.*
**Requirements**: LOCK-01, LOCK-02, LOCK-03, LOCK-04, LOCK-05
**Success Criteria** (what must be TRUE):

  1. Un manager vivant renouvelle son battement sans que le TTL monte — heartbeat séparé de la
     lease, TTL par défaut inchangé (un lock périmé ≠ une mission morte, constat du 2026-08-02)
     (LOCK-01).

  2. Un commit sous le lock d'autrui est bloqué à la source (guard `PreToolUse(Bash)` dont
     l'ENTRÉE naît toujours de `merge-hooks` — jamais posée à la main dans un settings ni via un
     hook git hors du mécanisme distribué ; sa COMMANDE, elle, peut légitimement pointer un
     chemin absolu machine-spécifique résolu par `merge-hooks` et rangé dans une cible
     `--settings-local` *(arbitré par Samuel le 2026-08-15 : un chemin machine ne doit jamais
     voyager ; les gardes restent distribuées — leur entrée naît toujours de `merge-hooks` — c'est
     leur COMMANDE qui est locale)* ; armement prouvé par le gate règle 4) ; le contournement réel
     rejoué comme cas de test rougit sans le guard (LOCK-02).

  3. Un checkout de branche sous le lock d'autrui est détecté et signalé bruyamment — blocage
     seulement si le spike `reference-transaction` le prouve sûr (LOCK-03). *Amendé au cadrage
     (D-32-A, tranché par Samuel le 2026-08-16) : le spike a rendu **PAS SÛR** — `reference-transaction`
     wedge `rebase` (son propre `--abort` est refusé), casse `worktree add` en fuitant la branche,
     se contourne par `-c core.hooksPath=/dev/null` (que nos propres `check-*.sh` utilisent déjà),
     est aveugle sur git < 2.46 et ne voyage pas avec le plugin. Le blocage du seul
     `git checkout|switch` de branche est donc porté par le guard `PreToolUse(Bash)` du critère 2,
     qui refuse **avant** que git ne tourne et n'a aucun de ces défauts ; échappatoire nommée
     (worktree), le détenteur du lock passe toujours. Preuve : `32-SPIKE-reference-transaction.md`.*

  4. Le takeover d'un lock périmé est explicite et tracé avec l'ID du repreneur — jamais
     d'auto-steal au TTL (LOCK-04).

  5. Les commits de mission portent un jeton de fence en trailer — « quel commit sous quel mandat »
     est auditable (LOCK-05).

**Transverse (QUAL-01)** : le guard naît bloquant déclaré, avec ses trois issues (dont fail-open
BRUYANT si le lock est illisible — jamais un vert) et sa mutation rouge prouvée. *Amendé au plan
(D-32-QUAL, tranché par Samuel le 2026-08-16) : **quatre** issues, pas trois — PASS · DENY ·
imparsable → fail-open silencieux · indisponible → fail-open bruyant ; le « bruyant » est réalisé
par le marqueur de santé PLUS un hook doctor `SessionStart` générique livré dans la phase
(plan 32-05, **abandonnable**).*

**Plans**: 6 plans livrés (32-01 → 32-05, 32-07), 4 vagues — le plan de bilan initialement prévu en
32-06 a été rendu directement en `32-RELIQUATS.md` (pas de PLAN/SUMMARY numérotés séparés) ; 32-07
s'est ajouté au plan pour porter les amendements 3B/4A tranchés par Samuel le 2026-08-17.

Plans:

- [x] 32-01-PLAN.md — champs additifs `session_ids`/`generation` en JSON + heartbeat séparé de la lease, TTL inchangé — vague 1 (LOCK-01, QUAL-01)
- [x] 32-02-PLAN.md — `takeover` + `reclaim` + journal append-only, retrait de l'auto-steal — vague 2 (LOCK-04, QUAL-01)
- [x] 32-03-PLAN.md — guard `PreToolUse` (Bash + Write|Edit) + entrée hooks armée (une seule, contournement du bug d'idempotence cross-matcher de `merge-hooks.sh`) — vague 3, **checkpoint humain** (LOCK-02, LOCK-03, QUAL-01)
- [x] 32-04-PLAN.md — convention de jeton de fence `Fence:` dans le contrat invariant du kernel — vague 3 (LOCK-05)
- [x] 32-05-PLAN.md — `check-guard-health.sh`, hook doctor `SessionStart` générique (lecteur des marqueurs de santé du parc) — vague 4 (QUAL-01)
- [x] 32-07-PLAN.md — synchronisation doctrinale complète (option 3B : 5 agents managers de 4 modules tiers + `mission-flow.md` + README) et fermeture du trou de la voie legacy du protocole d'acquisition (option 4A) — vague 4 (LOCK-04 amendé)
- [x] 32-06-PLAN.md — clôture : bilan du parc complet sur l'arbre commité, gates transverses, `CHANGELOG`/`README` de `conductor` et bump du module en v1.26.0 — vague 5 (LOCK-01..05, QUAL-01). *Ce plan ne produit pas de `SUMMARY` : son livrable est `32-RELIQUATS.md`.*
- [x] bilan de clôture rendu en `32-RELIQUATS.md` — parc complet (64 suites / 0 échec), gates transverses, état réel des 5 critères et de QUAL-01, reliquats consignés (LOCK-01..05, QUAL-01)

### Phase 33: Watchdog & notifications des missions

**Goal**: Un stall de mission ne survit pas au prochain geste d'une session VF vivante — chaque
nœud du DAG écrit un progrès, l'absence de progrès se voit et se signale, et les jalons de mission
notifient nativement sur l'OS, sans jamais tuer ni spammer.
**Amendement du 2026-08-17 (D-33-B, approuvé par Samuel)** : la promesse initiale (« ne reste plus
jamais silencieux 18 h ») est remplacée par cette formulation — aucune horloge n'existe côté
plateforme (spike hooks async, verdict PAS SÛR : les hooks Claude Code ne sont jamais périodiques,
ils ne réveillent qu'une session déjà active), la détection ne peut donc se faire qu'aux moments
d'activité d'une session VF vivante, jamais par un démon. **Limite assumée, écrite noir sur
blanc** : une machine laissée sans aucune session VF ouverte peut connaître un silence prolongé —
cette phase ne le ferme pas, elle l'accepte comme contrepartie de « zéro démon, portable d'un seul
geste ». L'option observateur externe (cron/launchd/Tâche planifiée Windows) est explicitement
**écartée** : installation système par OS, non portable d'un seul geste, contraire à la sobriété
d'install du milestone Windows-first.
**Depends on**: Phase 32 (même battement — conçues ensemble, WTCH consomme le heartbeat de LOCK).
**Recherche menée en ouverture de mission (2026-08-17), verdicts actés (cadrage complet :
`.planning/phases/VFDO-33-watchdog-notifications-des-missions/33-CONTEXT.md`)** :

- Hooks async / `asyncRewake` — **PAS SÛR** pour bâtir une horloge de watchdog
  (`33-SPIKE-hooks-async.md`) : jamais périodiques, ne réveillent qu'une session déjà active.

- Canal de notification Windows — **retenu : WinRT `ToastNotificationManager` sous
  `powershell.exe` 5.1** (PAS `pwsh` — les assemblies WinRT n'y sont pas incluses), AUMID emprunté
  à PowerShell, testé par shims d'argv en CI Linux (`33-SPIKE-canal-notification.md`). Preuve
  réelle sur Win10/11 non exécutée pendant le cadrage (aucune machine disponible) — recette de
  validation humaine en **condition de clôture de phase**, rattachée au fil testeurs Windows de
  l'issue #20 (§7, existence vérifiée).

- La définition de « progrès » (décision de cadrage n°1) — **tranchée : D-33-A**, deux horloges
  sur le même `meta` du lock (`heartbeat_epoch` existant + `progress_epoch` additif), stall =
  vivant mais progrès figé, abandon = les deux horloges mortes.
**Requirements**: WTCH-01, WTCH-02, WTCH-03, WTCH-04
**Success Criteria** (what must be TRUE):

  1. Chaque nœud du DAG de mission écrit un battement de progression — même battement que LOCK-01
     (même `meta`, même mécanisme d'écriture additive ADR-064), deux consommateurs
     (`heartbeat_epoch` pour la vivacité, `progress_epoch` pour le progrès), aucun second
     mécanisme (WTCH-01).

  2. Un stall est détecté par ABSENCE de progrès au-delà du seuil, lock vivant par ailleurs —
     jamais par auto-déclaration ; le watchdog signale et suggère, ne tue jamais (ADR-031) ; le cas
     « vivant mais bouclant » (heartbeat frais, progrès figé) est couvert par test (WTCH-02).

  3. Une notification OS native part aux jalons de mission (fin de nœud, halt condition) — jamais à
     chaque tour ; `notify.sh` est posé par l'engine (best-effort, fail-open silencieux), portable
     Windows dès la v1, prouvé par shims CI ; validation humaine réelle sur Win10/11 en condition
     de clôture de phase (WTCH-03).

  4. L'armement (hooks, notify) passe par le gate qui le vérifie réellement — pour les entrées
     `hooks.json`, c'est le gate CI PORT-05 (établi Phase 32, D-32-07 corollaire), jamais un
     settings local (leçon #38 : un réglage local ne voyage pas) ; `check-capability-activation.sh`
     (règle 4) ne s'applique que si un nouvel armement de frontmatter agent/skill est introduit —
     non requis par le périmètre actuel (WTCH-04).

**Transverse (QUAL-01)** : le signal de stall naît avec ses quatre issues (PASS / stall détecté /
imparsable-fail-open-silencieux / progrès illisible-fail-open-BRUYANT, réutilisant le canal
`vf_guard_unavailable` + le hook doctor `check-guard-health.sh` déjà posé en Phase 32) et sa
mutation rouge prouvée.
**Plans**: 33-01 (progress_epoch dans driver-lock.sh), 33-02 (wiring dag.sh au point `mark`),
33-03 (détection de stall, canal BRUYANT), 33-04 (notify.sh portable + détecteur WSL dans
vf-portable.sh), 33-05 (jalons de notification + recette de clôture Windows) — affinage au plan.

- [x] 33-01-PLAN.md — `progress_epoch` additif au `meta` du lock (D-33-A), verbe `mark-progress` — vague 1 (WTCH-01)
- [x] 33-02-PLAN.md — `record_progress()` câblé à `dag.sh mark`, APRÈS `save(dag)` — vague 2 (WTCH-01)
- [x] 33-03-PLAN.md — sous-contrôle stall/abandon dans `check-guard-health.sh`, canal BRUYANT, mutation rouge — vague 2 (WTCH-02, QUAL-01)
- [x] 33-04-PLAN.md — `notify.sh` portable (macOS/Linux/Windows/WSL), détecteur WSL dans `vf-portable.sh`, T12 mis à jour — vague 1, indépendant (WTCH-03)
- [x] 33-05-PLAN.md — `check_stall_signal()` (D-33-F) + `record_milestone()` câblés au point `mark`, recette de clôture Windows (D-33-C) — vague 3 (WTCH-02/03/04)
- **Vérification goal-backward (`33-VERIFICATION.md`, 2026-08-17)** : `gaps_found`, 3/4 critères ATTEINTS (WTCH-01, WTCH-03 limite assumée, WTCH-04), WTCH-02 **PARTIEL** — le relais du verdict stall au geste `mark` (D-33-F) est structurellement inatteignable pour un STALL du lock courant (`record_progress()` avant `check_stall_signal()` dans le même bloc). Correctif en cours par un autre worker sur `dag.sh`/`test-dag.sh` au moment où cette ligne est écrite — état non préjugé ici.
- **ANNEXE — Phase 33 ROUVERTE le 2026-08-17 pour son annexe notifications (D-33-H)** : l'émission de WTCH-03 passe en **opt-in (défaut OFF, toggle `/vf-notify`)** et les jalons GSD (fin de phase, fin de milestone) sont relayés vers l'**app Claude** via la session principale — `PushNotification` n'existant pas en sous-agent. Correction **pré-distribution** : la release **v2.56.0 a été retirée** (revert `07ff554`, `VERSION` revenue à v2.55.1), aucun lab n'a donc jamais reçu le défaut d'émission. **Les deux plans de l'annexe sont écrits ET exécutés** (2026-08-17, branche `feat/phase-33-annexe-notifications-opt-in`). Cadrage complet en `33-CONTEXT.md` § D-33-H.
- [x] 33-06-PLAN.md — gate d'opt-in par fichier-sentinelle (`${XDG_CONFIG_HOME:-${HOME:-}/.config}/vibeflow/notify-optin`) dans `notify.sh`, AVANT toute détection de canal, + toggle `/vf-notify` (`on`/`off`/`status`/`test`) — module `conductor` v1.28.0 (D-33-H Q5, WTCH-03 amendé)
- [x] 33-07-PLAN.md — **Pattern H** : relais `SendMessage(main)` des jalons GSD (fin de phase ET fin de milestone) vers l'app Claude via la session principale — module `dev-orchestrator` v2.18.0 (D-33-H Q1/Q6)
- **Vérification goal-backward de l'annexe (`33-VERIFICATION-ANNEXE.md`, 2026-08-17)** : `gaps_found`, **5/6 critères D-33-H ATTEINTS**, critère 1 **PARTIEL** — `$HOME` déréférencé sans garde sous `set -u` falsifiait le fail-open *inconditionnel* promis en tête de `notify.sh` (jamais le défaut OFF, le script mourant avant tout `command -v`). Gap **fermé par la correction post-revue `401c903`** : garde `${HOME:-}` appliquée à l'identique dans `notify.sh`, `SKILL.md` et l'assertion d'identité, plus le cas **N19** (les trois variables absentes → exit 0, stderr vide, zéro invocation), prouvé rouge sous mutation. Mesures re-dérivées après correction : **66 suites découvertes / 66 OK / 0 KO**, `check-version-sync.sh` exit 0, `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents` exit 0, arbre de travail propre.
- **SHIPPÉE `v2.56.0`** (2026-08-17, vérifié machine) — les gestes humains (ADR-031) ont été posés : PR **#50** mergée dans `main` (`f639108`), commit de release `4431ed1`, tag annoté `v2.56.0` poussé sur `origin`, **release GitHub publiée** le 2026-08-17T18:40Z, `scripts/check-release-tag.sh --remote` → ✓. Suivi de `e2af6b1` (le manuel annonçait six commandes, il y en a sept — `/vf-notify` documentée). La `v2.56.0` avait été retirée avant distribution (revert `07ff554`) puis **re-publiée** après revue du défaut : aucun lab n'a jamais reçu l'émission par défaut. **Phase CLOSE**, à une réserve près — la recette Windows (`33-CLOTURE-WINDOWS.md`) n'a jamais été exécutée : laissée **en suspens** sur décision de Samuel (2026-08-17), en attente du retour des testeurs (issue #20) ou d'un poste Windows équipé ; ne jamais la compter comme verte à la clôture du milestone.

### Phase 18: Survie du ledger d'exigences à la clôture de jalon

> **Héritée d'agentique-v1.0** (numéro historique conservé — dossier
> `.planning/phases/VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon/`, étude `STUDY.md`).
> **Périmètre réduit le 2026-07-28** par l'étude d'implémentation (verdict **GO-RÉDUIT**) :
> l'intitulé précédent — *Capability living-specs (conventions OpenSpec)* — et ses quatre briques
> (grammaire delta, ledger par capability, overlay `.gsd/capabilities/` @ `ship:post`, skill de
> spec-sync agent-driven) sont **écartés** — quatrième registre sans en retirer aucun, chemin
> agent-driven d'OpenSpec sans ses 16 garde-fous, ancrage `ship:post` inopérant ici. Chiffrage
> STUDY §7.3 : ≈ 370-470 lignes, soit 25-30 % du coût de la version écartée.

**Goal**: Faire **survivre les exigences à la clôture de jalon** — un fichier qui existe déjà, aucun
nouveau registre, aucune nouvelle grammaire, aucun overlay. Fait porteur (STUDY §7.1) :
`gsd-complete-milestone` exécute `git rm .planning/REQUIREMENTS.md` **inconditionnellement** et le
jalon suivant régénère de zéro — aucun lab GSD conforme n'a de réponse durable à « qu'est-ce que ce
système garantit aujourd'hui ? ». La dérive a été **re-constatée à la clôture d'agentique-v1.0**
(2026-08-15) : la conservation du ledger y est une déviation manuelle assumée, pas un comportement
outillé — 2ᵉ occurrence ; cette phase existe pour qu'il n'y ait pas de 3ᵉ.
**Depends on**: Phase 30 (le hook `SessionStart` du gate naît en forme exec sur le moteur de la
Phase 30). **La clause de conditionnement à la RFC amont est sans objet (D-18-07)** : le rattrapage
outillé devient **permanent** si la RFC #3556 (OPEN, triage COLLABORATOR « deferred — awaiting
maintainer review ») est refusée ou sans réponse au **2026-10-26** — aucun ré-arbitrage à conduire,
l'exécution part sans attendre l'issue amont (Iron Law 2).
**Requirements**: LEDG-01, LEDG-02 *(LEDG-03 — dépôt de la RFC — est portée par la Phase 30)*
**Success Criteria** (what must be TRUE):

  1. La clôture de jalon fait un roll-over outillé du ledger : les exigences non livrées voyagent
     avec trace `carried-from:` — rejoué sur la clôture réelle d'agentique-v1.0 (LEDG-01).

  2. `check-requirements-survival.sh` rend ROUGE si une exigence disparaît du ledger sans issue
     tracée (livrée / reportée / abandonnée) — gate **lecteur/diff en détection d'absence
     uniquement**, jamais un régénérateur, jamais l'heuristique « n'a pas bougé » (neutralisée en
     Phase 17) (LEDG-02).

  3. La doctrine est écrite dans `plugin/dev-orchestrator/AGENT.md` : les archives
     `milestones/*-REQUIREMENTS.md` sont des **instantanés**, `.planning/REQUIREMENTS.md` est la
     seule source vivante.

  4. Aucun objet nouveau dans le socle : zéro fichier de registre créé, zéro grammaire de merge,
     zéro overlay ; gouvernance conductor tenue (`check-agents.sh` vert, densité ADR-029),
     portabilité prouvée par exécution.

  5. La phase est livrée **avant la clôture de ce milestone** — sinon 3ᵉ dérive du ledger.

**Transverse (QUAL-01)** : `check-requirements-survival.sh` naît avec ses trois issues
(PASS / FAIL / imparsable BRUYANT — un `MILESTONES.md` illisible n'est jamais un vert) et sa
mutation rouge prouvée (convention du module : suite ~1,5× la taille du script).

**Bénéfice explicitement NON capté** — à ne pas revendiquer : l'indexation par capability. Un
`REQUIREMENTS.md` qui survit reste indexé par jalon ; cette part du besoin reste ouverte sous les
conditions E1/E2 du STUDY §8 — pas déclarée sans objet.
**Plans**: 18-01 (LEDG-02, gate `check-requirements-survival.sh` + primitive
`requirements-survival-detect.sh`), 18-02 (LEDG-01, rattrapage `restore-requirements-ledger.sh`),
18-03 (doctrine D-18-14 + bump module `dev-orchestrator` v2.18.0 → v2.19.0). Les 3 plans sont
**exécutés** (`18-01-SUMMARY.md`, `18-02-SUMMARY.md`, `18-03-SUMMARY.md`) ; la phase n'est **pas
encore shippée** — PR, tag et release restent des gestes humains non posés (CLAUDE.md racine,
ADR-031).

### Phase 34: Gaps agency-agents & cadrage skill-installer

**Goal**: La couverture du parc d'agents est arbitrée sur pièces — la taxonomie du catalogue
`agency-agents` est distillée, jamais importée — et le skill-installer global a un verdict go/no-go
écrit avant toute ligne de code.
**Depends on**: Phase 31 (le manifeste est la fondation de tout uninstall propre — MANI avant
SKIL ; un éventuel GO hériterait du traçage manifeste dès le premier jour). AGTS-02 est
conditionnée à la sortie du statut expérimental de `mobile-test` pendant le milestone.
**Requirements**: AGTS-01, AGTS-02, SKIL-01
**Success Criteria** (what must be TRUE):

  1. Les gaps de couverture sont arbitrés en distillant la taxonomie du catalogue — **zéro persona
     importée** (ADR-029 incompatible, zéro gouvernance) ; tout agent retenu passe
     `check-agents.sh` (ADR-044) et la règle 4 s'il est armé (AGTS-01).

  2. `web-test-team` est construite SI `mobile-test` sort du statut expérimental pendant le
     milestone (seule piste alignée fiabilité, moule prouvé) ; sinon l'exigence est **reportée avec
     trace** — jamais abandonnée en silence (AGTS-02).

  3. Le cadrage SKIL-01 répond par écrit à « que fait-il de plus que le natif `/plugin` ? » —
     abandon documenté si la réponse est creuse ; **aucun code avant le go** ; périmètre = câblage,
     pas catalogue ; collision de nom = refus (SKIL-01).

**Plans**: TBD

### Phase 25: Budget d'instructions

> **Héritée d'agentique-v1.0** (numéro historique conservé — dossier
> `.planning/phases/VFDO-25-budget-d-instructions-et-tage-d-alignement-court/`, slug historique
> conservé). **Périmètre réduit à l'arbitrage du 2026-08-15 : BUDG-01/02 seulement** — le volet G2
> (étage d'alignement court entre `discuss` et `plan`, ex-candidat BUDG-03) est **différé**
> (mécanique de workflow neuve, utilité non démontrée, aucun incident lié — Out of Scope du
> ledger). Origine (2026-07-31) : audit de `shanraisshan/claude-code-best-practice`, source
> primaire Dex Horthy (HumanLayer) — les LLM frontier suivent ~150-200 instructions avec
> constance ; ADR-029 borne les **lignes**, un proxy qui ne prédit pas l'adhérence (une skill de
> 200 lignes portant 90 impératifs est plus dangereuse qu'une de 400 lignes en portant 30).

**Goal**: La densité des agents distribués est bornée par une métrique qui prédit l'adhérence — la
charge d'instructions est mesurée et publiée, et son gate monte en ratchet, jamais rouge des
semaines.
**Depends on**: Phase 34 (ne jamais calibrer un seuil sur un corpus d'agents qui bouge — après tous
les ajouts d'agents du milestone).
**Requirements**: BUDG-01, BUDG-02
**Success Criteria** (what must be TRUE):

  1. Le budget d'instructions par fichier d'agent distribué est **mesuré et publié** — la métrique
     (quelles formes comptent comme instruction normative), le seuil et la portée sont tranchés au
     cadrage de la phase (BUDG-01).

  2. Le gate est en **ratchet** : il avertit d'abord, bloque au merge qui livre la remédiation, et
     n'est jamais rouge des semaines (précédent `workflow.windows_enforce`, spec Windows II §7)
     (BUDG-02).

  3. La mesure est calibrée sur le corpus **final** du milestone (post-Phase 34) — jamais sur un
     état qui bouge.

**Transverse (QUAL-01)** : le gate budget naît avec ses trois issues (un agent imparsable est
BRUYANT, jamais compté vert) et sa mutation rouge prouvée.
**Plans**: TBD

### Phase 35: Ré-armement worktree (conditionnelle) — CLOSE 2026-08-26

> **Close par la preuve, pas par abandon.** Le déclencheur externe est tombé le 2026-08-23 :
> `open-gsd/gsd-core#3302` releasé en **1.11.0**, installé sur le poste. Les deux legs de la
> régression #38 ont été mesurés — leg A (retour des commits) et leg B (base de fork du worktree,
> l'axe que la preuve du 2026-08-23 laissait dégénéré). Verdict : ré-armer serait **sûr** (le
> moteur 1.11.0 dégrade en séquentiel plutôt que de casser en silence) mais **inerte** en
> conditions de mission (ADR-059 impose une branche dédiée, donc HEAD diverge toujours de
> `origin/HEAD`, donc dégradation systématique — zéro parallélisme gagné). **Décision humaine
> (Samuel, 2026-08-26) : option A, ne pas ré-armer.** Les deux gates qui l'interdisent restent en
> place, en connaissance de cause. Dossiers : `.planning/research/2026-08-23-wktr-02-preuve-retour-commits-worktree.md`
> (amendé) et `.planning/research/2026-08-26-wktr-02-leg-b-base-de-fork.md`.

**Goal (atteint autrement)** : la phase ne ré-arme pas `isolation: worktree` — elle **clôt la
question** sous preuve machine, sans jamais rejouer la régression #38 ni laisser la phase flottante
indéfiniment.
**Depends on**: précondition externe (gsd-core > 1.10.0 releasé ET installé) — tombée le
2026-08-23.
**Requirements**: WKTR-01 *(requalifié — énoncé non satisfiable honnêtement, close sans être
livré)*, WKTR-02 *(done, option A)* — *(WKTR-03, la veille, reste portée par la Phase 30)*
**Success Criteria — résultat réel** :

  1. La précondition a été machine-vérifiée RELEASÉE (1.11.0) ET installée. WKTR-01 est
     **requalifié** plutôt que livré : l'attestation prévue (`# vf-provides: worktree-baseref` par
     `ensure-deps.sh`) n'est pas satisfiable honnêtement — ce script ne doit pas écrire
     `worktree.baseRef`, donc il ne peut pas l'attester sans produire une couverture déclarée sans
     couverture effective (Borne 4 de `check-capability-activation.sh`).

  2. Le retour des commits (leg A) est **prouvé** deux fois — fast-forward, dont un rejeu sur
     branche réellement divergente le 2026-08-26. La base de fork (leg B) est **mesurée** : sûre,
     inerte en conditions de mission. Conséquence : **le ré-armement n'a PAS eu lieu**, par
     décision humaine sur preuve, et non par blocage technique (WKTR-02).

  3. La phase ne reste pas flottante : clôturée sur ce verdict, sans attendre un événement de
     plus.

**Transverse (QUAL-01)** : **non déclenché** — la phase ne fait naître aucun gate ni comparateur
neuf (option A), donc rien à tester ; ce n'est pas une dette.
**Plans**: aucun — clôture documentaire directe (mandat de clôture ciblée vf-coder, 2026-08-26),
pas de PLAN.md d'exécution.

### Phase 37: Portabilité multi-runtime — spike (Codex, OpenCode, Kimi)

**Goal:** Mesurer ce que VibeFlow peut réellement poser sur les runtimes non-Claude (Codex CLI,
OpenCode, Kimi Code) en s'appuyant sur la surface multi-runtime **déjà livrée par gsd-core 1.11.0**,
et rendre un go/no-go documenté. Spike de mesure, pas de livraison : aucune cible n'est promise
tant que la pose n'est pas constatée sur disque.

**Prémisse (déclarée par Samuel, à confirmer par la mesure)** : gsd-core est portable. Constaté à
l'œil : `bin/shared/runtime-aliases.manifest.json` déclare 13 runtimes ; `bin/lib/` porte
`runtime-artifact-conversion.cjs`, `runtime-artifact-layout.cjs`, `runtime-artifact-install-plan.cjs`,
`runtime-hooks-surface.cjs`, `runtime-homes.cjs`, `runtime-config-adapter-registry.cjs`,
`runtime-slash.cjs`, `host-runtime-detection.cjs` ; `references/runtime-aware-dispatch.md` distingue
les runtimes à dispatch nommé (claude, opencode, cursor) des runtimes built-in-only (kimi-code :
`coder`/`explore`/`plan`), la persona passant par `AGENT_SKILLS_<ROLE>`.

**Doctrine** : VibeFlow **consomme** cette surface, il ne la réimplémente pas. Aucun transpileur
maison, aucun « skill de conversion » à l'exécution (non déterministe, non testable).

**Questions à trancher par le spike :**

1. Quelle est l'API réellement appelable de la surface runtime gsd-core (queries `gsd-tools`,
   modules `bin/lib/`) — et est-elle stable / publique, ou interne au moteur ?

2. Que reste-t-il de **spécifiquement VibeFlow** à porter une fois gsd-core en place ? Hypothèse à
   vérifier : les 50 agents, les 6 fragments de hooks, le packaging `.claude-plugin/`, et le
   protocole d'escalade `AskUserQuestion`/`SendMessage`.

3. Les 25 SKILL.md sont-ils posables tels quels ? 22/25 sont conformes au standard Agent Skills ;
   3 ont `name` ≠ dossier (`vf-planning`, `vf-mobile-test`, `vibeflow-install`). 9/25 appellent des
   skills `gsd-*`, 9/25 supposent des sous-agents, 3 supposent `AskUserQuestion`.

4. Que devient l'équipe de mission (team-kernel) hors Claude ? **Mesuré le 2026-08-28, contre une
   première analyse erronée** : le registre `gsd-core` déclare `namedDispatch: true` pour **codex**
   (tier-1, `tier: "full"`, `per-agent sandbox tiers`, surface de hooks `config.toml` + `hooks.json`)
   comme pour opencode et cursor ; le convertisseur `convertClaudeAgentToCodexAgent` **existe déjà**.
   Côté produit, Codex CLI porte **MultiAgentV2** (v0.128.0) : rôles custom en `[agents]` de
   `config.toml` — modèle, instructions, sandbox et serveurs MCP par rôle —, built-ins
   `default`/`worker`/`explorer`/`monitor`, fan-out `spawn_agents`, et `report_agent_job_result`
   **obligatoire** par worker : le rapport typé du team-kernel a un équivalent natif.
   Deux produits Kimi distincts à ne pas confondre : `kimi` (Python, `namedDispatch: true`, layout
   kimi-agents YAML) vs `kimi-code` (Node, `namedDispatch: false`, 3 built-ins seulement).
   → L'hypothèse de travail devient **portage plein de l'équipe sur codex et opencode**, dégradation
   réservée à `kimi-code` et aux runtimes `namedDispatch: false` (hermes, pi).
   Frictions à mesurer, pas des murs : openai/codex#14579 (rôles custom du `.codex/config.toml` de
   **projet** invisibles pour `spawn_agent` → déclarer les workers au scope user), openai/codex#31814
   (modèle par sous-agent non spécifiable sous certains modèles → le pattern manager opus / workers
   sonnet ne tient pas), `backgroundDispatch: false` sur un des blocs du descripteur codex (à
   confirmer — touche le watchdog et les missions longues).

4b. **Le seul trou structurel identifié** : `AskUserQuestion` et `SendMessage` n'ont d'équivalent sur
   aucun runtime non-Claude. C'est l'escalade vivante d'un manager vers l'humain. Le contournement
   documenté côté VibeFlow (`SendMessage(main)`) s'appuie lui-même sur du Claude. Quelle forme prend
   un arbitrage humain hors Claude — et comment garantir qu'il ne soit jamais **inféré** ?

5. Où vit la déclaration de capacité par cible — `module.json` (`full` / `skills-only` /
   `unsupported`) ou descripteur consommé depuis gsd-core ?

6. `vibeflow-update.sh` : extension par `--target` (TARGET_ROOT déjà scopé) ou délégation au
   `runtime-artifact-install-plan` du moteur ?

**Risque à ne pas rater** : la dégradation silencieuse. Un lab qui croit avoir VibeFlow et n'en a
qu'un tiers, sans que rien ne le dise. Même doctrine que « aucun vert auto-déclaré ne tient ».

**Précondition — LEVÉE le 2026-08-28** : s'appuyer sur la surface runtime de 1.11.0 exige
**Node ≥ 24**. Livré hors Phase 37 par la **PR #54** (`2226e0d`, branche `feat/node-24-auto-install`) :
`plugin/dev-orchestrator/scripts/ensure-deps.sh` porte `NODE_MIN_MAJOR=24` et **répare au lieu de
refuser** (`528a538`, BOOT-01) — auto-install par gestionnaire de version sous `$HOME` (nvm épinglé
`v0.40.7`, jamais de `sudo` ni de gestionnaire système), refus explicite sous MSYS2, mesure en
conteneur du 2026-08-27 (`node:22-slim` → 1.10.0 / `node:24-slim` → 1.11.0). Tests isolés de
`NVM_DIR` (`efa87e2`). **Rien à re-traiter dans cette phase.**

**Sortie attendue** : un rapport de spike + une décision go/no-go sur une éventuelle phase de
livraison. Pas de code de production.

**Requirements**: TBD
**Depends on:** aucune (indépendante ; adjacente à Phase 34 — cadrage skill-installer)
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 37 to break down)

**Livrables produits (2026-08-28)** :
`.planning/phases/VFDO-37-portabilit-multi-runtime-spike-codex-opencode-kimi/DISCUSS.md`
(les 6 questions ci-dessus, mesurées), `SPIKE-REPORT.md` (verdict + recommandation) et
`ETUDE-CANAL-ET-MIGRATION.md` (second mandat, à la demande de Samuel : canal d'install hors
marketplace Claude, migration d'un lab existant, mémoire d'agent — axes A, B, B7). Les
chiffres du cadrage ci-dessus ont été **re-dérivés et corrigés** dans `DISCUSS.md` (section
« Corrections au cadrage ROADMAP ») — renvoi sans recopie ici, sauf la ligne « 9/25 appellent des
skills `gsd-*` » (Q3 ci-dessus, l. 1000-1002), **intentionnellement laissée intacte** : sa méthode
de mesure est documentée avec sa nuance dans `DISCUSS.md`.

**Plans**: aucun — spike de mesure, pas de plan d'exécution.

**Décisions humaines rendues le 2026-08-28** (à la lecture des livrables) :
- **Phase 38 à part** pour le canal d'install et la migration de lab (option recommandée par
  l'étude, §Proposition de cadrage) — voir la section Phase 38 ci-dessous.
- **Superpowers** : révisé sur prémisse démentie (le catalogue est déjà multi-runtime, 8 manifestes) —
  **rendre l'installeur VibeFlow multi-runtime**, rapatriement conservé en plan de secours chiffré.
- **Mémoire d'agent** : le traitement rejoint la déclaration `memory: project` — `.gitignore`
  corrigé (`.claude/*` + `!.claude/agent-memory/`), 116 fichiers versionnés après revue.
- **`description: >`** (15/21 skills détruits à la conversion) : corrigé, branche
  `fix/skill-description-monoline`.

**Reste non tranché** : le go/no-go sur l'**adaptateur VibeFlow minimal** (préservation de
`model`/`memory`/`tools`/allowlist, mapping des noms `[a-z0-9_]+`, digest explicite) et la
**démarche amont** vers gsd-core (élargissement du SDK public). Les deux sont **à trancher au cadrage
de la Phase 38**, où ils forment des lots candidats — pas ici. Argumentaire : `SPIKE-REPORT.md`
§Recommandation.

### Phase 38: Portabilité multi-runtime — livraison (canal d'install, migration de lab, adaptateur)

**Goal:** Rendre VibeFlow **installable et migrable** sur un runtime non-Claude — Codex en cible tier-1
mesurée, OpenCode et kimi-code sous réserve de mesure réelle — **sans dégradation silencieuse** : tout
ce qui est perdu sur une cible est **déclaré** à l'install, jamais subi. Prolonge la Phase 37, dont les
trois livrables (`DISCUSS.md`, `SPIKE-REPORT.md`, `ETUDE-CANAL-ET-MIGRATION.md`) sont le cadrage
factuel de cette phase — aucun chiffre n'est à re-mesurer, mais aucun descripteur gsd-core n'est une
preuve (un sur trois démenti en exécution : `maxDepth`).

**Lots candidats** (issus de l'étude, à confirmer au cadrage — `gsd-discuss-phase 38`) :
1. **Gate de fidélité** — compter par cible les champs perdus (`model`/`memory`/`tools`/
   `disallowedTools`/`vf-internal`/allowlist, `description`) et les marqueurs morts (`.claude`, `Task(`) ;
   bannière d'install qui déclare le périmètre réellement actif. Première brique : sans elle, toute
   install multi-runtime est la dégradation que la 37 a chiffrée (156 conversions, 0 diagnostic).
2. **Installeur multi-runtime** — les 11 sites `claude plugin install` / `command -v claude` des deux
   scripts `ensure` (superpowers et gsd-core se posent par leurs propres manifestes ailleurs). Décidé,
   ne dépend d'aucun autre arbitrage.
3. **Trou de `rollback`** — ne restaure que skills et scripts, jamais agents ni hooks, n'appelle jamais
   `mark_installed`, `rm -rf` avant copie (étude B2). Défaut de l'engine **actuel**, indépendant du
   multi-runtime — lot nommé même si le reste tarde.
4. **`--target`** — 1 site `TARGET_ROOT` + 15 littéraux côté engine, mais **198 fichiers / 1130
   occurrences `.claude/`** côté payload à réécrire à la copie (précédent amont :
   `copyWithPathReplacement`). Enregistrement Codex à alimenter en second geste (`~/.codex/agents/`,
   `[agents]`) : le canal plugin transporte (470/470 byte-identique) mais n'enregistre ni agents ni
   commandes.
5. **Adaptateur VibeFlow minimal + démarche amont** — go/no-go **non rendu** (voir Phase 37) ; à trancher
   au cadrage. Doctrine : VibeFlow consomme gsd-core, mais la surface d'artefacts visée est **interne**
   par contrat écrit — dépendre de l'interne tel quel est la voie la moins défendable.
6. **Migration d'un lab** — frontière `.planning/` fuyante (81 % des PLAN.md ouvrent sur un
   `@$HOME/.claude/…`), runtime à **inscrire** dans `.planning/config.json` plutôt que détecté, sort de
   `vf-calibrate` (nom déjà pris pour « migration de lab ») à décider avant tout verbe neuf, bascule
   vs coexistence non tranché. Escalade humaine : **jamais de question dans un worker headless**, relais
   Pattern H/`SendMessage` (actif portable) ; `opencode run --auto` formellement interdit.

**Contraintes** : aucun vert auto-déclaré (pose constatée sur disque, exécution réelle) ; Windows en
branche de dégradation explicite (symlinks inapplicables sous MSYS) ; OpenCode et kimi-code **jamais
installés** au 2026-08-28 — tout ce qui les concerne est dérivé de descripteurs jusqu'à mesure.

**Requirements**: FIDE-01/02, RUNT-01/02, ROLL-01..05, TGT-01..04, ADPT-01..04, MIGR-01..05 (22 IDs,
6 familles — `PORT-xx` évité, pris par la Phase 30 ; voir REQUIREMENTS.md §Portabilité multi-runtime)
**Depends on:** Phase 37 (cadrage factuel) ; adjacente à Phase 34 (skill-installer) — lot 2 partage la
surface installeur, à séquencer au cadrage.
**Plans:** 7 plans

Plans:

- [x] 38-01-PLAN.md — Gate de fidélité (champs perdus + marqueurs morts par cible, bannière d'install)
- [x] 38-02-PLAN.md — Installeur multi-runtime (12 sites CLI-couplés sur 4 fichiers, table de dispatch à 4 verbes)
- [x] 38-03-PLAN.md — Trou de rollback (agents+hooks+mark_installed+glob, --dry-run)
- [x] 38-04-PLAN.md — `--target` injectable + réécriture du payload à la copie + sonde cross-module
- [x] 38-05-PLAN.md — Adaptateur Codex minimal (rôle .toml dispatchable, limite de confinement déclarée)
- [x] 38-06-PLAN.md — Migration de lab (runtime dans config.json, coexistence/bascule gatée, réversibilité)
- [x] 38-07-PLAN.md — Correction des 3 bloquants de la mesure Codex (enregistrement des 12 agents, uninstall symétrique, déclaration des hooks)

**Dette nommée (D-38-K, option A non retenue — correction ciblée post-ROLL, 2026-08-28)** :
atomicité par staging (`<TARGET_ROOT>/.vibeflow-staging/<mod>/` + `mv` sur même volume) pour
`rollback_module`, écartée du lot de correction ciblée D-38-J/D-38-K — aurait débordé le
périmètre (plus de 2 fonctions de l'engine touchées : `rollback_module`, `backup_module`,
potentiellement `install_module`). Retenu à la place : option B, `trap ERR` + `set -E` qui
déclare l'état `INCONSISTENT:<étape>:<version_cible>` au registre plutôt que de le laisser
mentir sur la version pré-rollback (`show_status` l'affiche). Réévaluer l'option A si de
nouveaux points de panne mi-restauration apparaissent au-delà des 5 étapes déjà couvertes
(skills/scripts/agents/agent-references/registre).

**Dette nommée — garde de cible unifiée pour les scopes littéraux et `--target`** (D-38-Q,
2026-08-29, Phase 38). **Fait mesuré** : pour la **même cible physique**, `--scope user` est
accepté (**rc=0**) et `--target "$HOME/.claude"` refusé (**rc=1**), sur un contenu identique — la
garde D-38-P ne vit que dans la branche `--target`, la branche des scopes littéraux ne la traverse
jamais. **Non traité en Phase 38, délibérément** : harmoniser changerait le comportement de
`--scope user`, c'est-à-dire le **chemin nominal de tous les labs existants**, en fin de mission et
hors périmètre. Retenu à la place : rendre l'asymétrie **visible** — `--scope user` affiche
désormais sa cible résolue comme `--target` le fait. **Déclencheur de reprise** : le portage
multi-runtime amène des adaptateurs à construire des `--target` explicites plutôt qu'à passer par
`user`/`project`/`local` ; le jour où ce chemin devient majoritaire, le plus contraint des deux
sera aussi le plus fréquent, et l'unification cessera d'être cosmétique.

**Dette nommée — texte faux du gate de coexistence hors périmètre** (D-38-R, 2026-08-29,
Phase 38, plan 38-07, CODEX-B6 second volet). **Fait mesuré** :
`plugin/conductor/scripts/check-artifact-fidelity.sh:175` affirme qu'un runtime coexistant
« opère SANS gouvernance de hooks (aucun mécanisme équivalent mesuré à ce jour) » —
affirmation **démentie** par la mesure de bout en bout du 2026-08-29 (38-CONTEXT.md
lignes 1156-1164) : Codex 0.150.1 porte une surface de hooks **prouvée exécutante** (un
`$CODEX_HOME/hooks.json` en forme strictement Claude Code a réellement déclenché un hook sous
`--dangerously-bypass-hook-trust`), un **sur-ensemble** des événements Claude Code
(`SubagentStart`, `Interrupt`, `PostCompact`…), les mêmes clés (`matcher`/`timeoutSec`/`async`/
`permissionDecision`), et même un **importeur natif** `settings.json -> hooks.json`. Le vrai
trou : l'install VibeFlow merge dans `settings.json`, jamais lu par Codex, au lieu de
`hooks.json`. **Non traité en Phase 38, délibérément** : le fichier porteur du texte vit sous
`plugin/conductor/**`, hors périmètre strict du plan 38-07 (`plugin/_internal/vibeflow-update.sh`,
`plugin/_internal/tests/`, `plugin/_internal/runtime-adapter/register-codex-agent.sh` uniquement) —
un autre worker corrige en parallèle, sur ce même worktree partagé, un défaut différent du même
gate (commit `9af7a4b`). Le plan 38-07 traite le PREMIER volet de CODEX-B6 (la déclaration de
coexistence, jusque-là inerte faute d'écriture dans le registre de runtime au moment de
l'install/status — désormais câblée via `record_codex_runtime_if_applicable()`). **Déclencheur de
reprise** : corriger le texte de la ligne 175 dès que ce worker parallèle livre sa propre
correction du même fichier (remplacer la négation par : Codex expose une surface de hooks prouvée
exécutante, non ENCORE ciblée par l'install VibeFlow qui merge dans `settings.json` au lieu de
`hooks.json`) ; et/ou planifier une conversion réelle `settings.json -> hooks.json` comme geste
dédié, jamais promise avant d'être livrée.
