---
name: sonde-estanglais-e23-7-mot-outil
description: Un nouveau libellé UI dans 00-vibeflow.js du cockpit rougit E23.7 (test-cockpit-equipe.sh) s'il n'a aucun mot-outil français ni accent.
metadata:
  type: project
---

`estAnglais` (vf-cockpit-fr-inventaire.mjs) juge anglais tout gabarit sans accent ni mot-outil (le, du, des, de…) ; E23.7 de test-cockpit-equipe.sh le signale. « Lignes non comprises » a rougi, « Lignes du planning non comprises » passe.

**Why:** découvert au rejeu de la suite équipe (156/1), invisible dans test-cockpit-projet.sh.
**How to apply:** après tout texte UI ajouté à `00-vibeflow.js`, rejouer test-cockpit-equipe.sh (et chrome-fr) ; mettre un mot-outil dans le titre plutôt qu'élargir CONNU.
