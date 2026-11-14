---
name: redos-trois-tours-sans-preuve-generative
description: Une tolérance de regex élargie rouvre le coût quadratique ; un test à formes listées l'a laissé passer 3 tours de suite — exiger dès le 1er mandat un test de croissance N/2N généré
metadata:
  type: feedback
---
Exiger dès le premier mandat, pour toute regex élargie, un test de croissance généré : chaque forme × chaque caractère des classes (U+2028/U+2029 compris) × fin de ligne avec et sans `\n`, mesuré par le rapport t(2N)/t(N), à travers TOUS les lecteurs (lecture, diagnostic, graphe).

**Why:** mission parseurs cockpit, 2026-11-06. L'élargissement des regex demandé par le brief les a rendues quadratiques : ligne de 100 000 espaces en 7 à 24 s, contre 5 ms avant. Il a fallu trois revues pour fermer la classe. Revue 1 : P9.1 listait 6 formes. Revue 2 : 5 familles restaient (lookahead, parenthèses, shift, dernière ligne sans `\n`, chiffres). Revue 3 : U+2028 et project.mjs n'étaient pas couverts. Revue 4 : un mutant survivait encore, faute d'une forme de case. Chaque tour a coûté environ 400k tokens au codeur.

**How to apply:** si un mandat élargit une regex, inscrire la propriété « linéaire quel que soit le caractère » et le test génératif dès le premier tour, avec des mutants par regex, et pas seulement une forme témoin. Voir [[liste-de-cas-ne-ferme-pas-une-classe]].
