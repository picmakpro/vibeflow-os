---
name: vf-quick
description: >
  Utiliser quand la demande est triviale et sans impact architectural — « vite fait »,
  « petite tâche », « juste un petit truc », « corrige cette typo », « renomme ça »,
  « un seul commit ». Pas de cadrage ni de plan : un changement atomique direct.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-quick — Tâche express

Invoque le skill **`gsd-quick`** (garanties GSD : commits atomiques, suivi d'état, sans
overhead de planification).

Reframe toute sortie en vocabulaire VibeFlow (cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Si la demande s'avère structurante (impact archi, plusieurs fichiers liés), basculer
vers **`vf-plan`** plutôt que de forcer l'express.
