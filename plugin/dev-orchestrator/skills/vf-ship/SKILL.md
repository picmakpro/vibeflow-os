---
name: vf-ship
description: >
  Utiliser quand le travail est validé et prêt à partir — « crée une PR », « livre »,
  « ship », « mets en prod », « pousse », « ouvre la pull request ». Crée la PR, lance la
  revue et prépare le merge après recette. Invocable par l'utilisateur ET par l'agent en
  autonomie (après vf-test/vf-review).
---

# vf-ship — Livraison

Invoque le skill **`gsd-ship`** (crée la PR, lance la revue, prépare le merge).

Reframe toute sortie en vocabulaire VibeFlow : « ship » → **livraison**
(cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Pré-requis : la **recette** (`vf-test`) doit être passée avant de livrer.
