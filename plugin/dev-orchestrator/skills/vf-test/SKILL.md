---
name: vf-test
description: >
  Utiliser quand l'utilisateur veut valider qu'un travail livré fonctionne — « teste »,
  « vérifie », « valide », « ça marche ? », « fais la recette », « contrôle ». Intervient
  typiquement après vf-execute pour fermer la boucle. Invocable par l'utilisateur ET par
  l'agent en autonomie.
---

# vf-test — Recette

Invoque le skill **`gsd-verify-work`** (UAT conversationnelle).

Reframe toute sortie en vocabulaire VibeFlow : « verify / UAT » → **recette**
(cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Étape suivante naturelle après une recette OK : **`vf-review`** puis **`vf-ship`**.
