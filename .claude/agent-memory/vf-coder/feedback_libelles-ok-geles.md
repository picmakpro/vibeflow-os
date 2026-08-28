---
name: libelles-ok-geles
description: Quand les libellés d'`ok` d'une suite servent de base de comparaison, ajouter une assertion plutôt que réécrire — et laisser un libellé sous-déclarer
metadata:
  type: feedback
---

Quand une mission gèle les libellés `ok` existants d'une suite de tests (« les N libellés
actuels doivent rester identiques à l'identique ; tu peux en ajouter »), la bonne manœuvre est
d'**ajouter** une assertion à côté, jamais d'élargir celle qui existe. Si l'élargissement rend
l'ancien libellé imprécis, le laisser **sous-déclarer** : un libellé qui sous-déclare ne ment
jamais sur ce qui est garanti, et la revendication précise est portée par la nouvelle
assertion. Poser un commentaire au-dessus qui dit que la sous-déclaration est volontaire.

Deux corollaires vérifiés sur la Phase 23 (nœud `exec-01`, arbitrages A-1..A-4) :

- Un libellé **interpolé** (`… exactement les $N noms …`) change de texte sans qu'aucune
  assertion soit renommée. Le prouver au manager par un `comm` entre la liste des libellés
  avant/après : la seule différence légitime est la valeur mesurée.
- Le message de **KO**, lui, n'est pas gelé — et il doit rester exact quand la sonde s'élargit,
  sinon la prochaine panne oriente le lecteur vers la mauvaise cause.

**Why:** l'humain se sert de la stabilité des libellés comme base de comparaison entre deux
missions ; renommer une assertion pour la rendre « plus juste » détruit cette base et masque
si une propriété a été perdue en route.

**How to apply:** avant de toucher une assertion existante, se demander si une assertion
supplémentaire ferait le même travail. Voir aussi [[gate-jamais-de-repli]] et
[[mutation-test-discriminating-cases]].
