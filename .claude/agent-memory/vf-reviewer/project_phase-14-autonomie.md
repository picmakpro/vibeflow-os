---
name: phase-14-autonomie-vs-phase-12
description: La phase 14 (frontière d'altitude planning/moteur de dev) doit rester autonome de la phase 12 — le verbe /vf-milestone est interdit dans ses livrables
metadata:
  type: project
---

Les livrables de la phase `14-frontiere-altitude-planning-gsd` ne doivent citer **aucun verbe né en
phase 12**, `vf-milestone` en tête : ce verbe n'existait pas au démarrage de la phase 14.

**Why:** les deux phases avancent en parallèle (phase 12 : plan 12-01 livré, 12-02→12-06 restants au
2026-07-25). Si un livrable de la 14 référence un verbe de la 12, la 14 ne peut plus être mergée ni
releasée seule — elle devient dépendante d'une phase inachevée.

**How to apply:** en revue de tout commit de la phase 14, grep `vf-milestone` (attendu : 0) et se
méfier de toute redirection d'intention « clôturer un jalon / archiver le milestone » vers autre chose
que `/vf-progress`. La table de redirection canonique vit dans
`plugin/planning-core/references/gsd-handoff.md`, pas dans le SKILL.
