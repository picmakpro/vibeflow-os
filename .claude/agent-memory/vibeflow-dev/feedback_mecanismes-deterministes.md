---
name: mecanismes-deterministes
description: Willy tranche systématiquement pour le mécanisme déterministe (gate, script, manifeste) plutôt que pour celui qui repose sur le jugement d'un LLM ou sur une convention documentée
metadata:
  type: feedback
---

Quand plusieurs options d'architecture se valent, choisir celle dont la garantie est **portée par
une machine** — un gate qui échoue, un script qui copie, un manifeste vérifiable — et non par le
jugement d'un agent, la discipline d'un contributeur, ou une règle écrite dans un document.

**Why:** énoncé explicitement le 2026-08-02 lors du cadrage de la portabilité Windows : « je
préfère que ça soit un mécanisme assez déterministe, donc qui ne repose pas sur la condition de
l'LLM, mais que ce soit solide ». Ce n'est pas une préférence de style : le dépôt a déjà payé le
prix inverse — la résolution Python dupliquée dans 15 scripts par convention a produit une dérive
mécanique (7 scripts oubliés lors d'un correctif), et 14 versions ont été publiées sans tag parce
que la discipline de release était documentée au lieu d'être gardée par un script. Le repo a
converti ces leçons en gates (`check-version-sync.sh`, `check-release-tag.sh`, `check-agents.sh`) —
c'est le motif attendu par défaut.

**How to apply:** sur toute décision d'architecture, préférer l'option vérifiable par exécution.
Quand une exigence dit « aucun script ne doit faire X », la livrer avec le gate qui le prouve, pas
seulement avec la correction. Quand deux options diffèrent surtout par « qui garantit l'invariant »,
c'est ce critère qui tranche — pas l'élégance ni le nombre de lignes. Voir aussi
[[verifier-fraicheur-avant-audit]] : même exigence de preuve par exécution plutôt que par lecture.
