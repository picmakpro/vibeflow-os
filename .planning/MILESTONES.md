# Milestones — VibeFlow Dev Orchestrator (VFDO)

## 🚧 dev-doctrine — Doctrine dev & consolidation (ouvert 2026-07-07)

**Statut :** planning · **Spec :** `docs/superpowers/specs/2026-07-07-dev-doctrine-consolidation-design.md`

**Périmètre prévu :** 2 phases · 12 requirements (PHIL-01..08, CONS-01..04).

**Origine :** audit du parc de modules vs `dev-orchestrator` (`scratchpad/AUDIT-modules-vs-dev-orchestrator.md`) — constat : `dev-orchestrator` est un pur routeur sans doctrine ; les philosophies de dev (DRY absent, Clean Archi/Clean Code non nommés, TDD sans carte) et les doublons se concentrent dans le cluster qualité.

- **Phase 7 — Philosophies de dev** : enrichir `software-architecture` (DRY/KISS/YAGNI, nommer Clean Architecture + Clean Code, carte TDD → skill canonique, câblage Tier 2 honnête).
- **Phase 8 — Consolidation** : fusionner/déprécier `feature-dev-gates`, dé-dupliquer `audit-architecture`, factoriser les 3 axiomes. Invariant : `dev-orchestrator` reste un pur routeur.

---

## ✅ install-ux-v1.0 — Installation plugin + UX à toggles (2026-06-05)

**Tag git :** `install-ux-v1.0` · **Release repo** `v2.4.0` · **PR** #2 (mergée)

**Périmètre :** 5 phases (2-6) · 9 plans · 39 commits atomiques

### Livré
- **Plugin Claude Code** — `.claude-plugin/plugin.json` + `marketplace.json` : installation en **2 commandes** (`marketplace add picmakpro/vibeflow-os` + `install vibeflow`), **validé zéro-auth** sur repo public.
- **Auto-lancement** — hook `SessionStart` (`installer/hooks/`) qui ouvre l'UX `/vibeflow-install` au 1er lancement (marqueur `scripts/.vibeflow-installed`), silencieux ensuite.
- **Skill `/vibeflow-install`** — UX à toggles (scope user/project/local → modules), récap des dépendances auto-résolues, install scopée. Délègue à l'engine (zéro réimplémentation).
- **Engine scope-aware** — `vibeflow-update.sh` (`--scope`, `TARGET_ROOT`, clone git supprimé, `.gitignore` local) + `ensure-deps.sh` scopé (GSD `--global`/`--local`, Superpowers `--scope`). Rétro-compat préservée.
- **Manifeste & résolveur** — `module.json` ×8 + `resolve-deps.sh` (fermeture transitive des dépendances).
- **dev-orchestrator first-use** — garde-fou dans `AGENT.md` : détecte `.planning/` absent → propose l'init via `vf-init`.

### Requirements (17/17 complétés)
MANIF-01..02 · SCOPE-01..04 · INST-01..05 · PLUG-01..04 · FIRST-01..02

### Décisions clés
- Plugin embarque tout (modules = données bundlées, `${CLAUDE_PLUGIN_ROOT}` = cache) — pas de double-chargement.
- Un seul scope (user/project/local) appliqué à tout ; le skill passe toujours `VF_SCOPE` explicite (cohérence ID4).
- Repo rendu **public source-available** (LICENSE propriétaire conservée — flip fait par le mainteneur, droits admin).

### Process GSD (dogfooding)
brainstorm → spec → new-milestone → 5× (plan → **plan-check** → exécution → vérif). Le plan-check a attrapé de **vrais blockers** aux phases 3 / 4 / 5 (faux-négatif dry-run, marqueur cassé, hook cassé en contexte plugin) — tous corrigés avant exécution.

### Vérification runtime
Repo public confirmé · `marketplace add` + `install vibeflow` **zéro-auth OK** (puis env de dev nettoyé) · tests isolés (vrai `~/.claude` jamais touché) · scan secrets CLEAN.

## ✅ vfdo-v1.0 — Module dev-orchestrator (2026-06-04)

**Tag git :** `vfdo-v1.0` · **Embarqué dans la release repo** `v2.3.0`

**Périmètre :** 1 phase · 5 plans · ~10 tasks + 1 incrément (`vf-map`) · 18 commits atomiques

### Livré
- **Agent routeur `vibeflow-dev`** (`AGENT.md`, 125L) — routage langage naturel → bon skill GSD/Superpowers, 14 cibles distinctes, ne nomme jamais « GSD », reframe en vocabulaire VibeFlow.
- **Index factuel auto-généré** — `build-gsd-index.sh` → `gsd-skills-index.md` (65-66 skills GSD réels, zéro hallucination, régénéré à l'install via `VF_INDEX_OUT`).
- **13 verbes `/vf-*`** — thin delegators construits via `writing-skills` (dont `vf-init` bootstrap, `vf-map` cartographie, `vf-auto` autonome), + `vocabulary-map.md`.
- **Bootstrap auto-install** — `ensure-deps.sh` : GSD + Superpowers non-interactif, idempotent, fallback manuel ; `gsd-new-project` jamais lancé seul (BOOT-04).
- **Intégration installeur (D7)** — `vibeflow-update.sh` copie les references d'un module agent sous `.claude/agents/<mod>-references/` + hook post-install régénérant l'index.
- **Tests** — `test-dev-orchestrator.sh` (4 axes + densité `wc -l`), portable source ↔ lab installé. 7/7 repo, 6/6+1 SKIP lab.

### Requirements (14/14 complétés)
ROUT-01..04 · IDX-01..02 · ABS-01..02 · BOOT-01..04 · VERIF-01..02

### Process GSD (dogfooding)
brainstorm → spec → init → plan (5) → **plan-check ❌ 3 blockers** → révision → **plan-check ✅** → execute (4 waves) → **verify goal-backward** → fix → incrément `vf-map` (v1.1.0) → runtime test (lab) → clôture.

### Vérification runtime
Routage NL confirmé en session par l'utilisateur · install lab end-to-end OK · bootstrap idempotent OK.

### Reporté (v2)
- VOC-01 : traduction exhaustive des artefacts GSD.
- VOC-02 : migration package `get-shit-done-cc` → `@opengsd/gsd-core`.
