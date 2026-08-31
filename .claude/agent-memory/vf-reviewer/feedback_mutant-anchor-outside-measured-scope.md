---
name: mutant-anchor-outside-measured-scope
description: Un garde `cmp -s` au niveau fichier ne prouve pas qu'un mutant a mordu DANS le segment mesuré — vérifier l'ancrage du mutant, pas seulement qu'il diffère
metadata:
  type: feedback
---

Quand une suite de tests fabrique ses propres mutants et les garde contre le no-op avec
`cmp -s <original> <mutant>`, ce garde est **au niveau du fichier**. Il ne dit rien de l'endroit où
la mutation a mordu. Si le motif de mutation existe aussi **hors du bloc / segment que l'assertion
mesure**, le mutant diffère (garde vert) mais la propriété mesurée est intacte : la suite rend
« mutant NON détecté » et **accuse l'assertion** alors que le tort est à l'ancrage du mutant.

**Why:** constaté sur la Phase 23 de vibeflow-os (`test-dev-orchestrator.sh`, mutant M1 de T27,
ancré sur `mode **superviser**` en incise). Après une réécriture licite du foyer dans une autre
graphie, le `sed` mordait le bullet « Blocage » situé hors du segment `human_needed` mesuré — 2 KO
sur une doctrine correcte. L'arbitrage ouvert O-5 affirmait pourtant « le garde `cmp -s` le dit
fort, donc pas de faux vert » : faux pour ce mutant.

**How to apply:** en revue par mutation, pour chaque mutant fabriqué par la suite elle-même,
(1) rejouer une **réécriture licite** de la cible avant de conclure à la discriminance, et
(2) exiger que le garde de morsure porte sur le **segment/bloc mesuré** (comparer les sorties de
l'extracteur, pas les fichiers). Corollaire : deux motifs qui décrivent la même notion dans deux
assertions voisines (ici `T26_ANSWER_RE` pluriel-only vs `T27_ASK_RE` deux nombres) doivent être
alignés — un désalignement introduit par le même lot produit un faux rouge dont le message accuse
la doctrine. Voir [[mutation-test-regression-claims]] et [[strict-branch-fallback-audit]].
