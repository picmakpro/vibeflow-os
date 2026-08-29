---
name: 2to1-merge-hides-stream-claim
description: Un test qui capture stdout+stderr via 2>&1 ne peut jamais prouver une affirmation "sur stdout" ou "sur stderr" — rejouer en isolant les flux
metadata:
  type: feedback
---

Quand un PLAN/commentaire de test affirme qu'une sortie apparaît sur un flux précis (« affichée en
clair sur stdout »), un test qui capture `OUT=$(cmd 2>&1)` ne peut PAS distinguer stdout de stderr
— il « passe » même si l'implémentation écrit sur l'autre flux. Preuve (revue Phase 38, comblement
`--target` D-38-P) : `log()` de `vibeflow-update.sh` écrit sur **stderr** (`>&2`, ligne 32), mais
le PLAN `38-04-PLAN.md` et le commentaire du test T41 affirment « sur stdout ». Le test T41 capture
`2>&1` donc ne voit jamais l'écart. Rejoué en isolant (`2>/dev/null` pour stdout seul,
`2>&1 1>/dev/null` pour stderr seul) : la ligne est absente de stdout, confirmée sur stderr —
divergence réelle entre doc/test et code.

**Why:** trouvé par délégation `gsd-code-reviewer` (pas par ma propre première passe) — j'avais
lu le call `log(...)` et vérifié qu'il s'exécutait inconditionnellement, mais je n'avais pas
recoupé le flux revendiqué par le PLAN/commentaire contre le flux réel. Un appelant qui ne capture
que stdout (pattern `out=$(cmd)` sans `2>&1`, très courant) perdrait silencieusement cette ligne —
contredisant la garantie « jamais une surprise silencieuse » du threat model.

**How to apply:** dès qu'un PLAN/commentaire/threat-model nomme explicitement un flux (stdout OU
stderr) pour une garantie de visibilité, rejouer avec les flux isolés séparément, jamais se fier à
un test qui les fusionne. Lié à [[feedback_mutant-anchor-outside-measured-scope]] (même famille :
une preuve qui semble suffisante masque en fait la portée réelle de ce qui est mesuré).
