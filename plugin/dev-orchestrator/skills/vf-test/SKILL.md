---
name: vf-test
description: >
  Utiliser quand l'utilisateur veut **constater** qu'un travail livré fonctionne — « teste »,
  « vérifie », « valide », « ça marche ? », « fais la recette », « contrôle », « fais-moi
  voir que ça tourne ». Recette conversationnelle sur les critères de l'étape ; intervient
  typiquement après vf-execute pour fermer la boucle.
  ✘ pas pour **écrire** les tests qui manquent → /vf-testgen · ✘ pas pour diagnostiquer un
  plantage → /vf-debug · ✘ pas pour éprouver une approche avec du code jetable (« teste
  cette lib pour voir ») → /vf-spike · ✘ pas pour relire la qualité du code → /vf-review.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-test — Recette

Invoque le skill **`gsd-verify-work`** (UAT conversationnelle).

Reframe toute sortie en vocabulaire VibeFlow : « verify / UAT » → **recette**
(cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Étape suivante naturelle après une recette OK : **`vf-review`** puis **`vf-ship`**.
