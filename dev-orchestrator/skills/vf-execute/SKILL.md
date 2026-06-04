---
name: vf-execute
description: >
  Utiliser quand un plan de travail existe et qu'il faut le construire — « code »,
  « implémente », « ajoute cette feature », « construis », « développe », « exécute le
  plan ». Demande structurante avec impact (pas un one-liner trivial → voir vf-quick).
  Invocable par l'utilisateur ET par l'agent en autonomie (après vf-plan, avant vf-test).
---

# vf-execute — Exécution du plan de travail

Invoque le skill **`gsd-execute-phase`**.

Reframe toute sortie en vocabulaire VibeFlow : « SUMMARY » → **rapport de sprint**,
« phase » → **étape/sprint** (cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Toujours fermer la boucle : proposer la **recette** (`vf-test`) puis la **revue** (`vf-review`).
