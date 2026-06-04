# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- 🚧 **Install UX** — Phases 2-6 (en cours) — install plugin + skill à toggles + scope

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
- [ ] 05-01-PLAN.md — `.claude-plugin/plugin.json` + `marketplace.json` (calque Superpowers) + câblage VIBEFLOW_CACHE=${CLAUDE_PLUGIN_ROOT} dans le skill + doc d'install 2-commandes (PLUG-01, PLUG-02)
- [ ] 05-02-PLAN.md — checklist pré-public + flip repo public + validation marketplace add/install zéro-auth — CONFIRMÉ HORS-AGENT (PLUG-03, PLUG-04)

#### Phase 6: dev-orchestrator first-use
**Goal**: Au 1er usage, l'agent détecte un projet non GSD-initialisé et propose l'init.
**Depends on**: Phase 1 (indépendant des phases 2-5)
**Requirements**: FIRST-01, FIRST-02
**Success Criteria** (what must be TRUE):
  1. L'agent détecte l'absence de `.planning/` au premier usage.
  2. Il propose map-codebase puis new-project sur confirmation (jamais `gsd-new-project` seul).
**Plans**: TBD

## Progress

**Execution Order:**
1 ✅ → 2 → 3 → 4 → 5 ; 6 indépendant (peut partir tôt)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. dev-orchestrator | vfdo-v1.0 | 5/5 | Complete | 2026-06-04 |
| 2. Manifeste & résolveur | Install UX | 2/2 | Complete | 2026-06-04 |
| 3. Engine scope-aware | Install UX | 0/2 | Not started | - |
| 4. Skill /vibeflow-install | Install UX | 0/2 | Not started | - |
| 5. Packaging plugin | Install UX | 0/2 | Planned | - |
| 6. dev-orchestrator first-use | Install UX | 0/TBD | Not started | - |
