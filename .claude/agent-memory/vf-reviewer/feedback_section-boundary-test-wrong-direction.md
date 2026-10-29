---
name: section-boundary-test-wrong-direction
description: Un cas "ne déborde pas" qui teste la mauvaise direction ne mord pas sur la clause de fermeture de section (check-phase-validation.sh, Phase 60)
metadata:
  type: feedback
---

Un parseur de sections (marqueur dans la section de la phase N) a une clause de fermeture (`if (insec && lvl <= seclvl) insec = 0`). Le cas qui revendique « le marqueur de la phase 2 ne déborde pas sur la phase 3 » (probe_trace2, CPV) interroge la phase 3 APRÈS le marqueur : le titre de la phase 3 ouvre sa propre section, la clause de fermeture n'y sert à rien. Suppression de la clause : 46/46 vert (confirmé par mutation ; 60-VERIFICATION l'avait signalé).

**Why:** la direction qui exerce la clause est l'inverse : interroger la phase N dont la section précède un marqueur d'une section voisine (phase N+1, ou titre non-Phase comme `## Progress`). Mutant rouge observé sur cette sonde (rc 1 au lieu de 0). La même clause est mordue dans vf-validation.sh (VFV-SANS-GOAL) et check-architecture.sh (20 KO) ; seule la copie du gate de phase est nue.

**How to apply:** sur tout parseur à sections, muter la clause de fermeture et vérifier que la sonde interroge la section qui PRÉCÈDE le marqueur étranger. Survivants mineurs de la même suite : borne de niveau `lvl > 4` (niveau 5 accepté), fence indentée (`t = line` sans ltrim). Voir [[feedback_multicondition-guard-mutate-each]] et [[feedback_mutation-test-regression-claims]].
