---
name: assouplir-sur-indetermine-rouvre-un-fail-open
description: Corriger une régression « le consommateur bloque sur rc 3 » en le faisant continuer sur tout rc 3 laisse passer ce que le gate n'a pas pu lire — trier les causes de l'indéterminé, pas le code
metadata:
  type: feedback
---

Phase 60 (2026-10-29) : le gate `check-phase-validation.sh` rendait 3 sur des phases que gsd-core sert
(ids custom, `<details>`), et vf-coder s'arrêtait au poste solo — régression. Le tour 2 a fait
« continuer sur 3/64 » ; le juge suivant a montré qu'une phase réellement `proposed` passait (marqueur
illisible, sections multiples, lab partitionné sans `--ws`, commentaire non fermé : tous rc 3). Le tour 3
a distingué `marqueur=inconnu|multiple` ; le juge d'après a trouvé d'autres causes encore émises en
`marqueur=-`. Budget anti-thrash épuisé, deux majeurs remontés à Samuel.

**Why:** un code « indéterminé » agrège des causes de natures opposées (rien à lire / lecture
impossible) ; toute règle consommatrice écrite sur le code seul est soit fail-closed (régression), soit
fail-open (contournement).

**How to apply:** dans un mandat de correction d'une régression « bloque sur indéterminé », exiger
d'abord l'inventaire de TOUTES les causes émettant ce code, chacune classée « absence » ou « lecture
impossible », avec un champ machine distinct ; jamais « continue sur 3 » en un tour. Prolonge
[[liste-de-cas-ne-ferme-pas-une-classe]].
