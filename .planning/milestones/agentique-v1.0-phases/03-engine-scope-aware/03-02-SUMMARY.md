---
phase: 03-engine-scope-aware
plan: 02
subsystem: dev-orchestrator/bootstrap
tags: [scope, ensure-deps, gsd, superpowers, dry-run, SCOPE-03]
requires:
  - "dev-orchestrator/scripts/ensure-deps.sh (état BOOT-01/02/03/04)"
provides:
  - "ensure-deps.sh scope-aware via VF_SCOPE (GSD --global/--local, Superpowers --scope user|project|local)"
  - "VF_ENSURE_FORCE : dry-run observable (logue la cmd scopée même si déps présentes, sans installer)"
  - "Validation stricte VF_SCOPE (user|project|local) en tête (err + exit 1 avant tout effet de bord)"
  - "T2b : asserts de scope dry-run forcé (3 scopes + rétro-compat + rejet invalide)"
affects:
  - "Phase 4 /vibeflow-install : passe toujours VF_SCOPE explicite à ce script (cohérence ID4)"
tech-stack:
  added: []
  patterns:
    - "Court-circuit conditionnel d'early-return : skip SAUF si (DRY_RUN && FORCE)"
    - "Validation d'entrée en tête (case) avant définition de main / tout run_cmd"
    - "Dérivation de flags scope→CLI (mapping spec §3/§8)"
key-files:
  created: []
  modified:
    - "dev-orchestrator/scripts/ensure-deps.sh"
    - "dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
decisions:
  - "VF_ENSURE_FORCE n'a d'effet QU'en dry-run (T-03-07) : hors dry-run il est ignoré, jamais d'install forcée"
  - "Validation VF_SCOPE placée après le helper err mais avant main (err disponible, aucun effet de bord)"
  - "Défaut LEGACY user conservé (rétro-compat appel-direct) — ne co-occurre jamais en prod avec le défaut engine project (ID4)"
metrics:
  duration: "~6 min"
  completed: 2026-06-04
  tasks: 2
  files: 2
---

# Phase 3 Plan 02 : ensure-deps scope-aware (VF_SCOPE) Summary

Bootstrap `ensure-deps.sh` rendu scope-aware via `VF_SCOPE` (GSD `--global`/`--local`, Superpowers `--scope user|project|local`), avec `VF_ENSURE_FORCE` pour un dry-run observable sur machine où GSD/Superpowers sont déjà installés, validation stricte du scope en tête, et test T2b couvrant les 3 scopes + rétro-compat + rejet d'un scope invalide.

## Ce qui a été fait

### Task 1 — Scoper ensure-deps.sh (commit `2ba5fab`)
- Variables : `SCOPE="${VF_SCOPE:-user}"`, `FORCE="${VF_ENSURE_FORCE:-}"`.
- Validation stricte `case "$SCOPE" in user|project|local) ;; *) err … ; exit 1` placée après le helper `err` mais **avant `main`** et tout `run_cmd` (T-03-04, exit 1 avant effet de bord).
- Dérivation : `GSD_SCOPE_FLAG` (`user`→`--global`, `project|local`→`--local`), `SUPERPOWERS_SCOPE="$SCOPE"`.
- Court-circuit des early-return : `if detect_X && ! { [ -n "$DRY_RUN" ] && [ -n "$FORCE" ]; }; then skip`. En dry-run forcé on tombe dans le chemin `run_cmd` (logue seulement). Mode normal strictement inchangé.
- `ensure_gsd` : `--global` → `"$GSD_SCOPE_FLAG"` (appel npx + message manuel).
- `ensure_superpowers` : `--scope user` → `--scope "$SUPERPOWERS_SCOPE"` (install directe + retry marketplace) ; note du scope visé ajoutée à l'étape manuelle TUI (la TUI n'a pas de flag scope).
- En-tête d'usage mis à jour (VF_SCOPE, VF_ENSURE_FORCE, mapping, note ID4, SCOPE-03).

### Task 2 — T2b asserts de scope (commit `a01e080`)
- Bloc `T2b` ajouté après T2, sans toucher T1..T6.
- Helper `assert_scope` capturant `VF_ENSURE_DRY_RUN=1 VF_ENSURE_FORCE=1 VF_SCOPE=$s` et grep des flags via `"$GREP"`.
- Asserts : user→`--global`/`--scope user`, project→`--local`/`--scope project`, local→`--local`/`--scope local`, rétro-compat (sans VF_SCOPE)→`--global`/`--scope user`, rejet `VF_SCOPE=bogus` (exit≠0, sans FORCE).
- T2 (idempotence, non forcé) intact. Aucun appel réseau (dry-run uniquement).

## Vérification

`bash -n` OK sur les deux fichiers. Suite complète verte sur cette machine (GSD + Superpowers présents) :

```
12 OK / 0 KO / 0 SKIP
```

T2b confirme les flags scopés pour les 3 scopes + rétro-compat + rejet du scope invalide ; T1-T6 préservés. Verify Task 1 (`OK`) et verify Task 2 (`OK rc=0`) passés tels qu'écrits dans le plan.

## Threat model

- T-03-04 (Tampering) mitigé : validation `user|project|local` + `err`+`exit 1` avant tout `run_cmd`/`main`.
- T-03-07 (Elevation) mitigé : `VF_ENSURE_FORCE` n'agit qu'en dry-run (logue via `run_cmd`), aucune install réelle forcée.
- T-03-05 / T-03-06 (DoS/Repudiation) inchangés : idempotence mode normal + fallbacks manuels conservés.

## Deviations from Plan

None — plan exécuté exactement comme écrit. Détail d'implémentation prévu par le plan : la validation `case` est placée après la définition du helper `err` (qu'elle appelle) tout en restant avant `main` et tout effet de bord, conformément à l'exigence « avant main / tout run_cmd ».

## Known Stubs

Aucun. `ensure-deps.sh` reste fonctionnel (install réelle hors dry-run, fallbacks manuels intacts).

## Self-Check: PASSED

- FOUND: dev-orchestrator/scripts/ensure-deps.sh
- FOUND: dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
- FOUND: .planning/phases/03-engine-scope-aware/03-02-SUMMARY.md
- FOUND commit: 2ba5fab (Task 1)
- FOUND commit: a01e080 (Task 2)
