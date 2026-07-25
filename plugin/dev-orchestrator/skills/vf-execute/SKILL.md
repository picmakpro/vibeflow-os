---
name: vf-execute
description: >
  Utiliser quand un plan de travail existe et qu'il faut le construire **pour de vrai** —
  « code », « implémente », « ajoute cette feature », « construis », « développe »,
  « exécute le plan », « vas-y, fais-le ». Demande structurante avec impact, livrée en
  commits atomiques.
  ✘ pas pour un one-liner trivial sans impact → /vf-quick · ✘ pas pour une expérimentation
  jetable qui répond à une question → /vf-spike · ✘ pas pour enchaîner toutes les étapes
  restantes sans supervision → /vf-auto.
  Invocable par l'utilisateur ET par l'agent en autonomie (après vf-plan, avant vf-test).
---

# vf-execute — Exécution du plan de travail

Invoque le skill **`gsd-execute-phase`**.

Reframe toute sortie en vocabulaire VibeFlow : « SUMMARY » → **rapport de sprint**,
« phase » → **étape/sprint** (cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Toujours fermer la boucle : proposer la **recette** (`vf-test`) puis la **revue** (`vf-review`).
