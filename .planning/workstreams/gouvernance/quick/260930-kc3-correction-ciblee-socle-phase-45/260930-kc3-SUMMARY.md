---
quick_id: 260930-kc3
status: complete
description: Correction ciblée du socle Phase 45 (revue anticipée revue-45-socle) — M1 M2 m1 m3 m4 m5
base: 6ef026f
commits: [541462e, fde964a, d121db9, 7900a11, 2052d1c]
---

# Quick 260930-kc3 — correction ciblée du socle Phase 45

Constats corrigés, chacun test rouge d'abord, correctif, vert, mutant.

| Id | Fichiers | Commit |
|----|----------|--------|
| M1, M2, m5 | rejeu-reel.sh, test-rejeu-gates.sh (R-REEL-05..08, mutants REEL-REALPATH, REEL-RAPPORT, REEL-REFUS64, REEL-MTIME, REEL-MODE, REEL-SHA) | 541462e |
| m3 | check-gates-alive.sh, test-planning-hook-installed.sh (R-CAN-08, MUT-CAN-RAISON) | fde964a |
| m4 | test-planning-gates.sh (R-ENV-02, MUT-ENV-STATIQUE, MUT-ENV-LANCEUR) | d121db9 |
| m5 (flake) | test-rejeu-gates.sh, mtime constant du cas « contenu » | 7900a11 |
| m1 | hooks.json (vf_norm), test-planning-hook-registered.sh (A16-A18, EXT-10, EXT-11) | 2052d1c |

Hors mandat, non touché : m2 (config.json illisible, refus en panne, P45-D-06a).
Exécution directe par vf-coder : aucun exécuteur isolé lancé (aucun worktree secondaire).
