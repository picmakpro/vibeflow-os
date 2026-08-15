# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- ✅ **install-ux-v1.0** — Phases 2-6 — clôturé 2026-06-05 (plugin + skill à toggles + scope) — release `v2.4.0`
- ✅ **dev-doctrine** — Phases 7-8 — doctrine dev (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) + consolidation des doublons qualité — clôturé 2026-07-07 — release `v2.20.0`
- ✅ **memory-swarm-rnd** — Phase 9 — R&D : transposition du modèle mémoire + patterns swarm de jcode — spike GO, shippé `v2.28.0` (ADR-052 mémoire vivante + ADR-053 swarm)
- ✅ **gsd-migration** — Phases 10-11 — clos 2026-07-26, release `v2.39.0` — migration du package GSD `get-shit-done-cc` → `@opengsd/gsd-core@^1` (VOC-02)
- ✅ **vf-routing** — Phases 12-14 — clos 2026-07-26, release `v2.37.0` — routage fin des intentions (verbes `/vf-*` à l'origine ; carte d'intention agentique depuis la bascule v2.33.0), couverture complète des skills GSD, pont spec → feuille de route, et frontière d'altitude avec le moteur de planning GSD
- ✅ **agentique-v1.0** — Phases 15→29 (18 et 25 reportées) — **clos 2026-08-15**, releases `v2.40.0` → `v2.52.0` — durcissement du moteur d'équipes agentique : collaboration inter-équipes, cloisonnement, migration `/vf-update`, alignement gsd-core, couplage et activation du moteur GSD, manuel, parallélisation, gate armement ↔ précondition (*as-installed testing*), gains ICM. **Absorbe `gsd-alignement`** (ouvert 2026-08-01 pour les phases 23-25 ; 23-24 livrées ici, 25 reportée) et solde la dérive du label `gsd-migration` resté dans STATE trois semaines après sa clôture.

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
- [ ] Phase 18: Survie du ledger d'exigences à la clôture de jalon *(reportée au prochain milestone, 2026-08-15)*
- [x] Phase 19: Migration du moteur GSD pilotée par /vf-update (completed 2026-07-28)
- [x] Phase 20: Fluidité du flux de dev sans perte de qualité (completed 2026-07-31)
- [x] Phase 21: Alignement du moteur GSD sur gsd-core 1.9.0 (completed 2026-07-31)
- [x] Phase 22: Hygiène documentaire — doctrine de sortie et captation d'intention (completed 2026-07-31)
- [x] Phase 23: Couplage explicite au moteur GSD — capabilities, flags et voie unique
- [x] Phase 24: Activation et mesure du moteur GSD — capacités dormantes et faits de runtime (completed 2026-08-05, PR #34)
- [ ] Phase 25: Budget d'instructions et étage d'alignement court *(reportée au prochain milestone, 2026-08-15)*
- [x] Phase 26: Manuel utilisateur VibeFlow (manual/) (completed 2026-08-02)
- [x] Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture (completed 2026-08-06)
- [x] Phase 28: Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur (completed 2026-08-15)
- [x] Phase 29: Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord (completed 2026-08-15)

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
| 18. Survie du ledger d'exigences | reportée | 0/0 | **Reportée au prochain milestone** (2026-08-15) — périmètre réduit le 2026-07-28 par `18-STUDY.md`, jamais planifiée | — |
| 19. Migration du moteur GSD par /vf-update | — | 3/3 | Complete — 3 plans exécutés, VERIFICATION produite, module `dev-orchestrator` v2.7.0 + `conductor` v1.16.0, ADR-058 | 2026-07-28 |
| 20. Fluidité du flux de dev sans perte de qualité | — | 7/7 | Complete — **mergée dans `main`** (PR #21, `d549b2d`), release `v2.44.0`, VERIFICATION produite | 2026-07-31 |
| 21. Alignement du moteur GSD sur gsd-core 1.9.0 | — | 5/5 | Complete — **mergée dans `main`** (PR #22, `d89a60e`), release `v2.45.0`, VERIFICATION produite, ADR-061/062/063 | 2026-07-31 |
| 22. Hygiène documentaire — doctrine de sortie | — | 3/3 | Complete — **mergée dans `main`** (PR #23, `474c3eb`), `dev-orchestrator` v2.9.0 + `design-orchestrator` v1.4.0 | 2026-07-31 |
| 23. Couplage explicite au moteur GSD | agentique-v1.0 | 8/8 | Complete — 8 SUMMARYs sur disque | 2026-08-04 |
| 24. Activation et mesure du moteur GSD | agentique-v1.0 | 12/12 | Complete — 12 SUMMARYs sur disque | 2026-08-04 |
| 25. Budget d'instructions et étage d'alignement court | reportée | 0/0 | **Reportée au prochain milestone** (2026-08-15) — G1 après 24 ; G2 dépend de 23 (les deux livrées depuis) | — |
| 26. Manuel utilisateur VibeFlow (manual/) | gsd-alignement | — | Complete (PR #28) | 2026-08-02 |
| 27. Parallélisation d'exécution — granulaire, simple, sans collision | gsd-alignement | 6/6 | Complete (PR #35) — spike `claude_orchestration` refusé par écrit | 2026-08-10 |
| 28. Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur | agentique-v1.0 | 3/3 | Complete — PR #42, release `v2.52.0`, CI main verte, gate + `lab-frais-arme` livrés | 2026-08-15 |
| 29. Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord | — | 5/5 | Complete (PR #41) — release `v2.51.0`, D-03 tenue (`dag.sh` hors diff), checkpoint humain T-29-05-3 tranché le 2026-08-15 | 2026-08-15 |

<details>
<summary>✅ agentique-v1.0 — Durcissement du moteur d'équipes agentique (Phases 15→29, 18 et 25 reportées) — SHIPPED 2026-08-15</summary>

13 phases livrées, releases `v2.40.0` → `v2.52.0`. Absorbe `gsd-alignement`.
Snapshots : `.planning/milestones/agentique-v1.0-*`. Détails : `MILESTONES.md`.

</details>

## Phases reportées (prochain milestone)

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

