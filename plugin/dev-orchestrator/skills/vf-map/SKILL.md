---
name: vf-map
description: >
  Utiliser quand l'utilisateur veut comprendre un code existant avant d'y toucher —
  « cartographie le code », « c'est quoi ce repo ? », « explique-moi l'archi », « fais
  l'état des lieux du codebase », « comprends l'existant avant qu'on code ». Produit une
  cartographie structurée du code (stack, architecture, conventions, tests, points
  d'attention). Invocable par l'utilisateur ET par l'agent en autonomie (typiquement avant
  un plan sur un projet existant).
---

# vf-map — Cartographie du code

Délègue à `gsd-map-codebase` : analyse multi-agents du dépôt → documents structurés
(stack, architecture, structure, conventions, tests, intégrations, points d'attention).
Non-interactif : peut tourner seul sur un projet qui contient déjà du code.

Reframe toute sortie en vocabulaire VibeFlow : « codebase map » → **cartographie du code**
(cf. `vocabulary-map.md`). Ne nomme jamais GSD ni `gsd-map-codebase` à l'utilisateur.

Enchaînement typique en autonomie : `vf-map` (comprendre l'existant) → `vf-plan` →
`vf-execute`. Pour un dossier vierge sans code, préférer `vf-init` (bootstrap + démarrage
de projet sur confirmation).
