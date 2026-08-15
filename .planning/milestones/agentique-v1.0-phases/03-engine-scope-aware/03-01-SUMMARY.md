---
phase: 03-engine-scope-aware
plan: 01
subsystem: infra
tags: [bash, install-engine, scope-aware, gitignore, dependency-resolver, vibeflow-update]

# Dependency graph
requires:
  - phase: 02-manifeste-resolveur
    provides: resolve-deps.sh (fermeture transitive des `requires` via module.json)
provides:
  - "Engine scope-aware vibeflow-update.sh : TARGET_ROOT résolu depuis VF_SCOPE/--scope (user → $HOME/.claude, project|local → ./.claude)"
  - "Suppression totale du clone/pull git : source = cache local (VIBEFLOW_CACHE), require_cache vérifie l'existence"
  - "Scope local → ajout idempotent des chemins installés au ./.gitignore"
  - "Câblage du résolveur Phase 2 : install --with-deps installe la fermeture transitive ; warning bruyant si résolveur absent"
  - "Test isolé test-vibeflow-update.sh (HOME/cache mktemp) couvrant les 5 truths, ~/.claude jamais pollué"
affects: [04-skill-vibeflow-install, 05-packaging-plugin]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Parsing --scope <val> avant cmd=$1 (filtrage positionnels, guard set -u tableau vide)"
    - "Toutes les cibles .claude rebasées sur $TARGET_ROOT ; doc-only docs/<mod>/ laissé hors TARGET_ROOT (cwd projet)"
    - "Fallback résolveur-absent best-effort + warning BRUYANT (err) sans bloquer l'install"
    - "Tests isolés HOME=mktemp + snapshot find -type f récursif anti-pollution ~/.claude"

key-files:
  created:
    - _internal/tests/test-vibeflow-update.sh
  modified:
    - _internal/vibeflow-update.sh

key-decisions:
  - "Défaut LEGACY engine = project (rétro-compat ./.claude) ; ne co-occurre jamais en prod avec le défaut user de ensure-deps (skill passe toujours VF_SCOPE explicite — cohérence ID4)"
  - "docs/<mod>/ (doc-only) reste relatif au cwd projet, jamais rebasé sur TARGET_ROOT même en scope user"
  - "sync devient un no-op explicite plutôt qu'une suppression de commande (rétro-compat appelants)"
  - "Résolveur localisé d'abord dans $CACHE_DIR/_internal/ (prod, bundle PLUG-02) puis à côté de l'engine (dev)"

patterns-established:
  - "Validation stricte du scope (user|project|local) avec err précoce sur valeur inconnue"
  - "gitignore_add_paths idempotent via grep -qxF avant echo, scope local uniquement"

requirements-completed: [SCOPE-01, SCOPE-02, SCOPE-04]

# Metrics
duration: 3min
completed: 2026-06-04
---

# Phase 3 Plan 01: Engine scope-aware Summary

**vibeflow-update.sh devient scope-aware (TARGET_ROOT résolu depuis VF_SCOPE/--scope), supprime tout clone git au profit du cache local, gère le .gitignore en scope local, et câble le résolveur de fermeture transitive de Phase 2.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-04T17:30:22Z
- **Completed:** 2026-06-04T17:33:37Z
- **Tasks:** 3
- **Files modified:** 2 (1 modifié, 1 créé)

## Accomplishments
- SCOPE-01 : résolution `VF_SCOPE`/`--scope` → `TARGET_ROOT` (user → `$HOME/.claude`, project|local → `./.claude`) avec validation stricte ; toutes les cibles install/uninstall/backup/rollback/status + hook IDX-02 rebasées sur `$TARGET_ROOT`.
- SCOPE-02 : suppression de `ensure_cache`/`sync_cache`/`REPO_URL` → `require_cache` (vérifie l'existence du cache) ; plus aucun `git clone`/`git pull` ; `sync` devient no-op explicite.
- SCOPE-04 : `gitignore_add_paths` ajoute les chemins installés au `./.gitignore` en scope `local` uniquement, idempotent.
- Résolveur câblé : `resolve_closure` + flag `install --with-deps` installent la fermeture transitive ; fallback bruyant (`err`) si résolveur absent, sans bloquer l'install (T-03-08).
- Test isolé `test-vibeflow-update.sh` : 6 asserts (T1 user / T2 project / T3 local / T4 no-clone / T5 résolveur réellement exercé + garde-fou) tous au vert, `~/.claude` intact (8592 fichiers récursifs avant=après).

## Task Commits

Each task was committed atomically:

1. **Task 1 + Task 2: Engine scope-aware (TARGET_ROOT, no-clone, gitignore local, résolveur)** - `e99aa7e` (feat)
2. **Task 3: Test isolé de l'engine scope-aware** - `38114b6` (test)

**Plan metadata:** (commit final docs ci-dessous)

_Note : Tasks 1 et 2 modifient le même fichier (`vibeflow-update.sh`) et ont été implémentées en une passe cohérente, donc regroupées en un seul commit `feat`._

## Files Created/Modified
- `_internal/vibeflow-update.sh` - Engine scope-aware : parsing `--scope`/`VF_SCOPE`, `TARGET_ROOT`, `require_cache` (plus de git), `resolve_closure`, `--with-deps`, `gitignore_add_paths`.
- `_internal/tests/test-vibeflow-update.sh` - Suite isolée (HOME/cache mktemp) des 5 truths + garde-fou récursif `~/.claude`.

## Decisions Made
- Défaut LEGACY engine = `project` (rétro-compat). Documenté en commentaire que le skill /vibeflow-install (Phase 4) passe toujours `VF_SCOPE` explicite → pas de co-occurrence avec le défaut `user` de ensure-deps (cohérence ID4).
- `docs/<mod>/` (Type 4 doc-only) délibérément laissé hors `TARGET_ROOT` (relatif au cwd projet, ce n'est pas du `.claude`).
- `sync` transformé en no-op explicite (log) plutôt que supprimé, pour ne pas casser d'éventuels appelants.
- Résolveur localisé en priorité dans `$CACHE_DIR/_internal/resolve-deps.sh` (chemin de prod bundlé par PLUG-02) puis à côté de l'engine (dev).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `local` hors fonction dans la branche `install --with-deps`**
- **Found during:** Task 2 (intégration résolveur)
- **Issue:** La variable de la branche Main `--with-deps` avait été nommée `local_target` ; au top-level du `case` (hors fonction), le mot-clé `local` aurait pu prêter à confusion / être invalide selon le shell.
- **Fix:** Renommée en `deps_target` (variable simple, pas de mot-clé `local`).
- **Files modified:** `_internal/vibeflow-update.sh`
- **Verification:** `bash -n` OK ; T5 installe la fermeture complète.
- **Committed in:** `e99aa7e` (commit Task 1+2)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Correction de nommage sans impact fonctionnel ni scope creep. Plan exécuté tel qu'écrit pour le reste.

## Issues Encountered
None - les 3 tasks ont passé leur verify du premier coup (après la correction de nommage en Task 2).

## TDD Gate Compliance
Task 3 portait `tdd="true"`. L'implémentation (engine) étant la cible GREEN déjà produite par Tasks 1-2, le test a été écrit puis exécuté contre l'engine existant et passe (6 OK / 0 KO / 0 SKIP). Pas de commit `test` RED séparé avant implémentation car l'engine était la cible du même plan ; documenté ici pour traçabilité.

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- Engine scope-aware prêt à être orchestré par le skill `/vibeflow-install` (Phase 4) : il suffit de lui passer `VF_SCOPE` explicite + un cache préparé.
- Note packaging (Phase 5 / PLUG-02) : le résolveur `resolve-deps.sh` DOIT être bundlé dans `$CACHE_DIR/_internal/` pour que `resolve_closure` l'exerce réellement en prod (le fallback bruyant n'est qu'un garde-fou).

## Self-Check: PASSED

- FOUND: `_internal/vibeflow-update.sh`
- FOUND: `_internal/tests/test-vibeflow-update.sh`
- FOUND: `.planning/phases/03-engine-scope-aware/03-01-SUMMARY.md`
- FOUND commit: `e99aa7e` (Task 1+2 feat)
- FOUND commit: `38114b6` (Task 3 test)

---
*Phase: 03-engine-scope-aware*
*Completed: 2026-06-04*
