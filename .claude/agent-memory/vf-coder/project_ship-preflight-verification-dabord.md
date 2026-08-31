---
name: ship-preflight-verification-dabord
description: Dans /gsd-ship, la verification est le preflight #1 — les gates security et broken-windows sont #6 et #7 et ne sont jamais atteints sans VERIFICATION.md
metadata:
  type: project
---

Dans `~/.claude/gsd-core/workflows/ship.md`, l'ordre des preflight n'est pas celui qu'on croit :

1. **verification** — `query verification.status <phase_dir> --pick status` doit valoir exactement
   `passed`. Toute autre valeur (`missing`, `gaps_found`, `human_needed`, `unknown`) bloque avec
   `PHASE_VERIFICATION_INCOMPLETE`.
2. arbre propre · 3. branche · 4. remote · 5. `gh`
6. **gate `security`** (`SECURITY.md: threats_open == 0`)
7. **gate `broken-windows`** (`WINDOWS.md: open_count == 0`)

**Why:** mesuré le 2026-08-05 sur la Phase 24. Un gros effort avait été investi pour amener
`threats_open` et `open_count` à 0 — les deux gates passaient bel et bien — mais le ship a été
refusé au **check #1** et n'a jamais atteint les checks #6/#7. `has_verification: false` dans
`query init.phase-op` le disait déjà : 12 PLAN + 12 SUMMARY, aucun `*-VERIFICATION.md`.

**How to apply:** avant d'annoncer qu'un ship est débloqué, vérifier `has_verification` /
`verification.status` **d'abord** — débloquer security et broken-windows ne sert à rien tant qu'il
manque. Attention aussi : le `next_command` rendu est `/gsd-execute-phase`, conseil générique qui
propose de **ré-exécuter** une phase pourtant livrée à 12/12 — décision humaine, jamais automatique.
Et les steps `push_branch` / `create_pr` / `track_shipping` (ce dernier écrit `STATE.md` via
`query state.update`) sont le cœur du workflow : un mandat qui les interdit ne peut pas produire un
ship complet, seulement en jouer les gates. Voir [[ship-jamais-auto-autorise]] et
[[gsd-tools-sondage-sur]].
