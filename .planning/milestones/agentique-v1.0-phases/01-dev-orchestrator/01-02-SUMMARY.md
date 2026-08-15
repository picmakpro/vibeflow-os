---
phase: 01-dev-orchestrator
plan: 02
subsystem: infra
tags: [bash, bootstrap, auto-install, gsd, superpowers, idempotence]

# Dependency graph
requires:
  - "Module dev-orchestrator/ scaffoldé (Plan 01-01)"
provides:
  - "ensure-deps.sh : bootstrap auto-install non-interactif GSD (npx) + Superpowers (plugin Claude Code)"
  - "Contrat de test VF_ENSURE_DRY_RUN (détection sans exécution réseau, consommé par Plan 05)"
  - "Garde-fou BOOT-04 : gsd-new-project jamais lancé seul (init sur confirmation uniquement)"
affects: [01-03, 01-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bootstrap idempotent non-interactif : détecte avant d'installer, 2e run = no-op"
    - "set -uo pipefail (PAS -e) : les détections command -v/grep peuvent échouer sans tuer le script"
    - "run_cmd() : wrapper exec-ou-logue piloté par VF_ENSURE_DRY_RUN (tests sans réseau)"
    - "Jamais d'échec silencieux : tout prérequis manquant ou install KO → étapes manuelles + exit 0"
    - "Fallback en cascade Superpowers : install directe → marketplace add + re-install → étape manuelle TUI"

key-files:
  created:
    - dev-orchestrator/scripts/ensure-deps.sh
  modified: []

key-decisions:
  - "set -uo pipefail (sans -e) imposé par le plan : detect_gsd/detect_superpowers reposent sur des codes de sortie non-zéro normaux"
  - "Détection Superpowers double : claude plugin list (si CLI présent) OU find sous ~/.claude/plugins/cache (robuste sans CLI)"
  - "Détection codebase via find -maxdepth 2 sur extensions courantes (ts/js/py/go/swift/rs/java) — heuristique légère, non bloquante"
  - "guard_init n'imprime qu'un message d'invitation ; gsd-new-project reste purement documentaire (commentaire/message)"

patterns-established:
  - "Contrat de test VF_ENSURE_DRY_RUN=1 : permet de valider l'idempotence (2 runs consécutifs identiques) sans déclencher npx/claude"

requirements-completed: [BOOT-01, BOOT-02, BOOT-03, BOOT-04]

# Metrics
metrics:
  duration: ~10 min
  tasks-completed: 2
  files-touched: 1
  completed-date: 2026-06-04
---

# Phase 1 Plan 02 : Bootstrap auto-install des dépendances (ensure-deps.sh) Summary

**One-liner :** `ensure-deps.sh` auto-installe GSD (npx get-shit-done-cc --claude --global) et Superpowers (claude plugin install --scope user) de manière idempotente et non-interactive, avec fallback marketplace, étapes manuelles si prérequis manquant, et garde-fou empêchant tout lancement de `gsd-new-project`.

## What Was Built

Le script bootstrap `dev-orchestrator/scripts/ensure-deps.sh` (169 lignes) qui rend les deux dépendances invisibles (vision §1, D3) :

- **Pilier GSD (BOOT-01)** — `detect_gsd()` (binaire `gsd-sdk` OU `~/.claude/get-shit-done/VERSION`) + `ensure_gsd()` qui skippe si présent, bascule sur étapes manuelles si `npm` absent, sinon installe via `npx -y get-shit-done-cc@latest --claude --global` (flags qui bypassent les prompts readline) et vérifie le code de sortie.
- **Pilier Superpowers (BOOT-02)** — `detect_superpowers()` (`claude plugin list | grep superpowers` OU dossier sous `~/.claude/plugins/cache`) + `ensure_superpowers()` : skip si présent, étape manuelle TUI si CLI `claude` absente, sinon `claude plugin install superpowers@claude-plugins-official --scope user` avec fallback `claude plugin marketplace add anthropics/claude-plugins-official` + re-tentative, puis étape manuelle si tout échoue.
- **Idempotence globale (BOOT-03)** — chaque pilier détecte avant d'installer ; 2 runs consécutifs sont un no-op ; jamais d'échec silencieux (toujours exit 0 avec message clair). Mode `VF_ENSURE_DRY_RUN=1` pour tester sans réseau.
- **Garde-fou init (BOOT-04)** — `detect_codebase()` + `guard_init()` impriment une invitation à l'init (et un message map-codebase conditionné par `VF_ENSURE_AUTO_MAP=1`) sans JAMAIS exécuter `gsd-new-project`.
- **`main()`** enchaîne `ensure_gsd` → `ensure_superpowers` → `guard_init` puis logue un résumé final (`GSD=... ; Superpowers=...`).

Conventions respectées : shebang bash, header purpose/usage, `set -uo pipefail`, helpers `log()`/`err()` calqués sur `vibeflow-update.sh`, fonctions snake_case préfixées `detect_`/`ensure_`, sections `# ---------- ... ----------`.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Détection + auto-install GSD | 536cf66 | dev-orchestrator/scripts/ensure-deps.sh |
| 2 | Pilier Superpowers + garde-fou init + idempotence globale | 6110042 | dev-orchestrator/scripts/ensure-deps.sh |

## Verification

| Critère | Commande | Résultat |
| ------- | -------- | -------- |
| Task 1 | `bash -n … && grep get-shit-done-cc && grep gsd-sdk` | exit 0 |
| Task 2 | `bash -n … && grep superpowers@… && grep 'marketplace add anthropics/…' && ! grep '^…gsd-new-project' && VF_ENSURE_DRY_RUN=1 bash …` | exit 0 |
| Idempotence | 2 runs `VF_ENSURE_DRY_RUN=1` consécutifs | identiques, exit 0, no-op |
| min_lines (≥60) | `wc -l` | 169 |
| BOOT-04 | grep négatif gsd-new-project exécuté | aucune occurrence (commentaires/messages uniquement) |

Note : sur la machine de dev, GSD et Superpowers sont déjà présents → la branche idempotente "skip" est celle exercée par les tests dry-run. Les branches d'install (npx/claude) ne sont pas exécutées en réseau, conformément à la consigne.

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates

None.

## Known Stubs

None — le script est fonctionnellement complet ; les branches d'install réseau sont volontairement non testées en exécution réelle (consigne) mais entièrement implémentées.

## Self-Check: PASSED

- FOUND: dev-orchestrator/scripts/ensure-deps.sh
- FOUND commit: 536cf66
- FOUND commit: 6110042
