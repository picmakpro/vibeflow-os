---
name: vf-testgen
description: >
  Utiliser quand il manque des tests et qu'il faut les **écrire** — « écris les tests »,
  « il manque des tests », « on a zéro test là-dessus », « couvre cette étape »,
  « ajoute des tests unitaires », « faut sécuriser ce module avec des tests »,
  « la couverture est ridicule ». Génère les tests d'une étape terminée à partir de ses
  critères de recette et des chemins critiques non couverts.
  ✘ pas pour constater que ça marche / faire la recette → /vf-test · ✘ pas pour réparer un
  test qui casse → /vf-debug · ✘ pas pour relire la qualité du code → /vf-review.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-testgen — Écriture des tests manquants

Délègue à `gsd-add-tests` : génération des tests d'une étape achevée, dérivés de ses critères de
recette et des trous de couverture réels.

Reframe toute sortie en vocabulaire VibeFlow : « add-tests » → **écriture des tests manquants**,
« UAT criteria » → **critères de recette**, « phase » → **étape/sprint**
(cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-add-tests` à l'utilisateur.

**Jamais d'affaiblissement** : un test existant n'est ni supprimé ni relâché pour passer au vert —
on ajoute de la couverture, on n'en retire pas.

Enchaînement typique : `vf-test` (la recette révèle un trou) → `vf-testgen` (on le comble) →
`vf-review`.
