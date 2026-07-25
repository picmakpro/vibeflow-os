---
name: vf-phase
description: >
  Utiliser quand c'est la **feuille de route elle-même** qu'il faut modifier — « ajoute une
  étape », « supprime ce sprint », « intercale une étape avant la 3 », « réordonne la
  feuille de route », « renomme l'étape 4 », « la roadmap ne tient plus, faut la retoucher ».
  Ajoute, insère, retire ou édite une étape de la feuille de route sans toucher au travail
  qu'elle contient.
  ✘ pas pour cadrer et découper le contenu d'une étape → /vf-plan · ✘ pas pour ouvrir ou
  clore un jalon → /vf-milestone · ✘ pas pour annuler du travail déjà fait → /vf-undo.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-phase — Édition de la feuille de route

Délègue à `gsd-phase` : ajout, insertion, suppression et édition d'une étape dans la feuille de
route, avec renumérotation et cohérence des dépendances.

Reframe toute sortie en vocabulaire VibeFlow : « ROADMAP » → **feuille de route**, « phase » →
**étape/sprint** (cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-phase` à l'utilisateur.

Frontière avec `/vf-plan` : ici on décide **quelles étapes existent et dans quel ordre** ; là-bas
on décide **ce qu'il y a dedans**.

Enchaînement typique : `vf-progress` (le plan ne colle plus) → `vf-phase` (on retouche la feuille
de route) → `vf-plan` (on cadre la nouvelle étape).
