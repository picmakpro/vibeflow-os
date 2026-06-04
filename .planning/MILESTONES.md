# Milestones — VibeFlow Dev Orchestrator (VFDO)

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
