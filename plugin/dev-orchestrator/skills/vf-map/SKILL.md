---
name: vf-map
description: >
  Utiliser quand l'utilisateur veut comprendre **le code existant** avant d'y toucher —
  « map ma codebase », « cartographie le code », « c'est quoi ce repo ? », « explique-moi
  l'archi », « fais l'état des lieux du code », « comprends l'existant avant qu'on code »,
  « ça marche comment ce truc ? ». Produit une cartographie structurée (stack,
  architecture, conventions, tests, points d'attention).
  ✘ pas pour extraire les décisions passées ou le graphe de connaissance → /vf-learn ·
  ✘ pas pour écrire ou rafraîchir la doc du projet → /vf-docs · ✘ pas pour relire la
  qualité d'un diff → /vf-review.
  Invocable par l'utilisateur ET par l'agent en autonomie (typiquement avant un plan sur un
  projet existant).
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
