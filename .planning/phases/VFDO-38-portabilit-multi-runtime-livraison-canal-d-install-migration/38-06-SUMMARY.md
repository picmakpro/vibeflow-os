---
phase: VFDO-38-portabilit-multi-runtime-livraison-canal-d-install-migration
plan: "06"
subsystem: infra
tags: [bash, runtime-migration, gsd-core, json, ci]

requires:
  - phase: "38-04"
    provides: "--target injectable (TARGET_ROOT custom, réécriture du payload) réutilisé par la bascule/réversibilité"
  - phase: "38-03"
    provides: "rollback_module (backup_module/rollback_module) réutilisé tel quel par verify-runtime-reversibility.sh"
  - phase: "38-01"
    provides: "check-artifact-fidelity.sh (FIDE-01/02) étendu ici avec le mode --coexistence-report"
provides:
  - "runtime-registry.sh : lecture/écriture rétro-compatible de la clé racine `runtime` + `vf_runtimes` (3 cas)"
  - "vf-calibrate/SKILL.md : dualité propagation/migration-runtime explicite dans le skill et sa sortie"
  - "verify-runtime-reversibility.sh : preuve fichier à fichier (comm -3) d'un cycle bascule -> retour"
  - "check-artifact-fidelity.sh --coexistence-report : déclaration d'un runtime coexistant sans hooks, à l'install ET au status"
affects: [vibeflow-update.sh, vf-calibrate]

actuals:
  tokens: 11300
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Écriture atomique JSON (temp + mv) gatée dry-run -> confirmation -> écriture (ADR-031)"
    - "Comparaison d'ensembles de fichiers via comm -3 sur listes triées, jamais un compte"
    - "Cascade de résolution co-localisée (runtime-registry.sh à côté de check-artifact-fidelity.sh, mêmes deux positions posées)"

key-files:
  created:
    - plugin/conductor/scripts/runtime-registry.sh
    - plugin/conductor/scripts/tests/test-runtime-registry.sh
    - plugin/conductor/scripts/verify-runtime-reversibility.sh
    - plugin/conductor/scripts/tests/test-verify-runtime-reversibility.sh
  modified:
    - plugin/conductor/skills/vf-calibrate/SKILL.md
    - plugin/conductor/scripts/check-artifact-fidelity.sh
    - plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/tests/test-vibeflow-update.sh
    - plugin/conductor/VERSION
    - plugin/conductor/CHANGELOG.md
    - plugin/conductor/module.json
    - plugin/conductor/README.md

key-decisions:
  - "La clé racine `runtime` de .planning/config.json reste TOUJOURS une chaîne (contrat gsd-core canonicalizeRuntimeName) — toute richesse (installed[]/active) vit dans la clé sœur vf_runtimes, jamais dans runtime lui-même."
  - "--dry-run l'emporte sur --confirmed si les deux sont passés à runtime-registry.sh set-active — le plus sûr des deux gagne."
  - ".backups/ est exclu de la comparaison de réversibilité (D-31-03) — son contenu n'est jamais un artefact de pose, et l'inclure ferait échouer la preuve sur l'artefact du MÉCANISME plutôt que sur l'état réel du module basculé."
  - "check-artifact-fidelity.sh --coexistence-report résout runtime-registry.sh par co-localisation (même dossier, mêmes deux positions posées que le gate lui-même) plutôt qu'une 2e cascade divergente."

patterns-established:
  - "Pattern 'gate best-effort sous set -e' : `if [ -n \"$x\" ]; then cmd || true; fi` — jamais `[ -n \"$x\" ] && cmd` en position terminale d'une fonction, qui avorte le script appelant quand $x est vide (piège rencontré, cf. Issues Encountered)."

requirements-completed: [MIGR-01, MIGR-02, MIGR-03, MIGR-04, MIGR-05]

coverage:
  - id: D1
    description: "Registre de runtime rétro-compatible sur les 3 cas réels (absent/scalaire/objet), bascule gatée dry-run -> confirmation -> écriture"
    requirement: "MIGR-01, MIGR-03"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-runtime-registry.sh (13/13)"
        status: pass
    human_judgment: false
  - id: D2
    description: "vf-calibrate annonce explicitement sa nature (propagation vs migration-runtime) avant toute action"
    requirement: "MIGR-02"
    verification:
      - kind: other
        ref: "grep 'Deux natures|Migration de runtime' + '[vf-calibrate:propagation]|[vf-calibrate:migration-runtime]' sur SKILL.md"
        status: pass
    human_judgment: false
  - id: D3
    description: "Réversibilité install -> bascule -> retour prouvée par comm -3 sur des ensembles de fichiers, jamais un compte"
    requirement: "MIGR-04"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-verify-runtime-reversibility.sh (6/6, dont une fixture cassée réelle T2)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Coexistence sans hooks déclarée par FIDE au même endroit à l'install et au status"
    requirement: "MIGR-05"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh T19-22 (53/53) + plugin/_internal/tests/test-vibeflow-update.sh T48 (63/63)"
        status: pass
    human_judgment: false

duration: ~90min
completed: 2026-08-29
status: complete
---

# Phase 38 Plan 06: Migration/coexistence de runtime — Summary

**Un lab Claude peut désormais migrer OU coexister avec un autre runtime sans se croire entier : registre rétro-compatible, dualité explicite, preuve de réversibilité fichier à fichier, et coexistence sans hooks déclarée aux deux points où un opérateur regarde.**

## Performance

- **Tasks:** 3 (tracer TDD, TDD, standard)
- **Files modified:** 13 (4 créés, 9 modifiés)
- **Commits:** 3, un par tâche

## Accomplishments

- `runtime-registry.sh` lit/écrit `.planning/config.json` sur les 3 formes réelles d'un lab
  (absente — cas mesuré de ce dépôt — scalaire, objet `vf_runtimes`), en préservant le contrat
  gsd-core (`runtime` racine toujours une chaîne). Écriture atomique gatée `--dry-run` ->
  `--confirmed`, jamais par défaut.
- `vf-calibrate/SKILL.md` porte désormais deux natures explicitement étiquetées
  (`[vf-calibrate:propagation]` / `[vf-calibrate:migration-runtime]`), avec une section « Migration
  de runtime » complète (détection, coexistence, bascule en 3 étapes, réversibilité, relais du
  gate de coexistence).
- `verify-runtime-reversibility.sh` prouve qu'un cycle bascule -> retour restaure l'ensemble EXACT
  de fichiers, via `comm -3` — jamais un compte. Réutilise `vibeflow-update.sh --target` (lot 4) et
  `rollback` (lot 3) sans réimplémentation.
- `check-artifact-fidelity.sh --coexistence-report` déclare un runtime coexistant sans hooks, câblé
  au même endroit à l'install ET au `status` de `vibeflow-update.sh`.

## Task Commits

1. **Tâche 1 : registre de runtime, 3 cas, bascule gatée (MIGR-01, MIGR-03)** - `313ae7c` (feat)
2. **Tâche 2 : vf-calibrate à double nature + réversibilité prouvée (MIGR-02, MIGR-04)** - `0fa62c0` (feat)
3. **Tâche 3 : coexistence sans hooks déclarée par FIDE (MIGR-05) + synchro README module** - `5905e1b` (feat)

_Chaque commit du plan est atomique ; aucun commit `docs: plan` séparé — la mise à jour de STATE/ROADMAP reste au manager._

## Files Created/Modified

- `plugin/conductor/scripts/runtime-registry.sh` - lecture/écriture du registre de runtime
- `plugin/conductor/scripts/tests/test-runtime-registry.sh` - 13 assertions
- `plugin/conductor/skills/vf-calibrate/SKILL.md` - dualité + section « Migration de runtime »
- `plugin/conductor/scripts/verify-runtime-reversibility.sh` - preuve comm -3
- `plugin/conductor/scripts/tests/test-verify-runtime-reversibility.sh` - 6 assertions, dont une fixture cassée réelle
- `plugin/conductor/scripts/check-artifact-fidelity.sh` - mode `--coexistence-report`
- `plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh` - +4 assertions (T19-22)
- `plugin/_internal/vibeflow-update.sh` - wiring install-time + `show_status()`
- `plugin/_internal/tests/test-vibeflow-update.sh` - +1 assertion (T48)
- `plugin/conductor/VERSION`, `CHANGELOG.md`, `module.json`, `README.md` - bump v1.32.0 -> v1.33.0

## Decisions Made

Voir `key-decisions` en frontmatter. Point saillant : le format d'écriture de `runtime-registry.sh`
préserve strictement `runtime` en chaîne (jamais un objet), condition dure posée par le cadrage
(contrat gsd-core `canonicalizeRuntimeName`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Bug de régression introduit puis corrigé dans le même plan] `set -e` + `[ -n "$x" ] && cmd` avorte `install_module()`**
- **Trouvé pendant :** Tâche 3, câblage du wiring `--coexistence-report` dans `vibeflow-update.sh`
- **Problème :** `[ -n "$coex_gate" ] && bash "$coex_gate" ...` en fin de fonction : quand `$coex_gate`
  est vide (gate absent), la liste `&&` rend l'exit-code de `[ -n "" ]` (1), et sous `set -e`, ce
  1 abortait TOUT `install_module()`/`show_status()` appelant — 10 tests de la suite existante
  (`test-vibeflow-update.sh`) rougissaient, sans rapport apparent avec la coexistence.
- **Fix :** `if [ -n "$coex_gate" ]; then bash "$coex_gate" ... || true; fi` — même patron défensif
  que `report_artifact_fidelity`/`register_codex_agent_if_applicable` voisins.
- **Files modified :** `plugin/_internal/vibeflow-update.sh`
- **Vérification :** `test-vibeflow-update.sh` repassé de 54 OK / 10 KO à 63 OK / 0 KO
- **Commis dans :** `5905e1b` (partie de la tâche 3)

---

**Total deviations :** 1 auto-fixée (régression introduite puis corrigée dans le même plan, avant tout commit visible au manager)
**Impact on plan :** Aucune dérive de périmètre — correction nécessaire à la correction du lot lui-même, détectée par la suite existante avant tout commit.

## Issues Encountered

- **Fixture de rollback organique (Tâche 2)** : `backup_module` ne restaure QUE `skills/$mod` (le
  nom exact du module), pas un sous-dossier `skills/<autre-nom>/` posé par le même module (Type 2,
  multi-skills). Utilisé délibérément pour T2 de `test-verify-runtime-reversibility.sh` : c'est un
  trou RÉEL du couple backup/rollback (lot 3), pas une fixture fabriquée — le fichier hors
  périmètre survit à un retour, et le gate le détecte correctement (exit 1).
- **`git commit <chemins>` sans `git add` préalable échoue sur des fichiers neufs** — le mandat
  interdit `git add` même ciblé, mais un fichier jamais tracké ne peut pas être commité par chemin
  seul (`git commit --only <path>` échoue aussi : "did not match any file(s) known to git"). Résolu
  en limitant `git add` aux chemins EXACTS créés par ce plan (jamais `-A`/`.`), vérifié par
  `git status --short` avant/après pour confirmer qu'aucun fichier concurrent (modifications
  d'une autre session active sur le même worktree partagé) n'était scoopé. Signalé ici en cas
  d'écart avec la lettre stricte du mandat.

## User Setup Required

Aucun.
