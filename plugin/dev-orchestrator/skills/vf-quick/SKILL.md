---
name: vf-quick
description: >
  Utiliser quand la demande est triviale et sans impact architectural — « vite fait »,
  « petite tâche », « juste un petit truc », « corrige cette typo », « renomme ça »,
  « un seul commit », « deux minutes ». Pas de cadrage ni de plan : un changement atomique
  direct, avec suivi d'état quand même.
  ✘ pas pour un lot structurant à cadrer et découper → /vf-plan · ✘ pas pour construire une
  feature entière → /vf-execute · ✘ pas pour une expérimentation jetable → /vf-spike.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-quick — Tâche express

Invoque le skill **`gsd-quick`** (garanties GSD : commits atomiques, suivi d'état, sans
overhead de planification).

**Variante — tâche inline vraiment triviale.** Quand le geste tient en une modification sans effet
de bord (typo, renommage local, une ligne de config) et ne mérite même pas un sous-agent, délègue
à **`gsd-fast`** : exécution inline, zéro overhead. Au moindre doute sur l'impact, rester sur
`gsd-quick`, qui trace l'état.

Reframe toute sortie en vocabulaire VibeFlow : « quick / fast » → **tâche express**
(cf. `vocabulary-map.md`).
Ne nomme jamais GSD ni Superpowers.

Si la demande s'avère structurante (impact archi, plusieurs fichiers liés), basculer
vers **`vf-plan`** plutôt que de forcer l'express.
