---
name: doc-d-agent-rejouer-le-budget-d-instructions
description: un diff « docs » d'un AGENT.md peut rougir check-instruction-budget — le compteur prend toute ligne avec jamais/doit/ne…pas, même descriptive ; la revue ne l'a pas vu
metadata:
  type: feedback
---

Toute modification d'un `AGENT.md` ou d'un `agents/*.md`, même « docs seule », exige de rejouer
`plugin/conductor/scripts/check-instruction-budget.sh` AVANT le bump. Pour trouver le commit fautif,
mesurer commit par commit dans des worktrees jetables.

**Why:** v2.71.2, 2026-10-24. Le commit #160 (2a79238e) a ajouté une phrase descriptive contenant
« jamais » : `dev-orchestrator/AGENT.md` est passé de 33 à 34 instructions, baseline 33, rc=1. La
revue vf-reviewer a contrôlé les lignes (212 < 251), pas les instructions. Le rouge n'est apparu
qu'au rejeu du job `gates`, après le commit de release : il a fallu remettre le commit de release
en dernière position par cherry-pick, ce qui n'était possible que parce que la branche n'était pas
encore poussée.

**How to apply:**
- Rejouer le job `gates` AVANT de dispatcher le bump, pas après.
- Pour redescendre sous la baseline, il y a deux voies. Reformuler une phrase descriptive : à
  signaler en « à décider », cela peut ressembler à un contournement. Relever la baseline : cela
  demande un arbitrage cité.
- En local, `test-guard-driver-lock-ws.sh` (55 mutants) dépasse 10 min. Ne pas le lancer quand
  le diff ne touche pas la garde : la CI le joue.

Voir [[non-regression-complete-est-un-geste-de-manager]] et [[liste-de-gates-jamais-la-reference]].
