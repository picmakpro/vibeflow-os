---
name: budget-largeur-entete-partage-entre-lots
description: La largeur de l'en-tête du cockpit est un budget commun ; deux lots disjoints par fichier l'ont dépassé ensemble, chacun vert sur sa branche
metadata:
  type: feedback
---

Retours panel du cockpit (2026-11-06/07) : le lot visite a ajouté le mot du thème (05-theme.js), le lot diagnostics a laissé le bouton Écrans à 0 écran (30-screens.js). Fichiers disjoints, chaque lot annonçait test-cockpit-responsive vert ; sur la branche fusionnée, 14 FAIL (en-tête rogné à 1 024 px par le bouton, à 1 600-1 700 px par le mot). Une datation sur copies `git archive` a séparé les deux causes. L'un des « verts » avait été mesuré sur un arbre sans la fusion.

**Why:** « disjoints par fichier » ne veut pas dire disjoints par effet : tout ajout dans l'en-tête consomme la même largeur, que responsive mesure.
**How to apply:** tout lot qui ajoute un élément d'en-tête (bouton, mot, pastille) rejoue test-cockpit-responsive sur la branche FUSIONNÉE avant d'être déclaré fini ; garder une étape de jointure du groupe qui rejoue les suites de tous les lots sur l'arbre fusionné et date un rouge par copies `git archive`. Voir [[perimetre-de-mesure-vs-perimetre-de-fichiers]], [[non-regression-sur-la-decouverte-complete]].
