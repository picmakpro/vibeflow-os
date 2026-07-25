---
name: vf-spike
description: >
  Utiliser quand la seule façon de répondre à la question est d'**écrire du code qu'on
  jettera** — « teste cette approche pour voir », « prototype jetable », « spike »,
  « est-ce que c'est seulement faisable ? », « bricole un truc vite fait pour vérifier »,
  « on essaie et on jette », « je veux voir si cette lib tient la charge ». Expérimentation
  cadrée et sacrifiable, dont le livrable est une réponse — pas une feature.
  ✘ pas pour idéer sans écrire de code → /vf-explore · ✘ pas pour concevoir la solution sur
  le papier → /vf-brainstorm · ✘ pas pour figer le QUOI attendu → /vf-spec · ✘ pas pour
  **constater** qu'un travail livré fonctionne (recette) → /vf-test · ✘ pas pour implémenter
  pour de vrai → /vf-execute · ✘ pas pour une maquette visuelle jetable → /vf-sketch ·
  ✘ pas pour explorer une direction visuelle → /vf-design.
  Invocable par l'utilisateur ET par l'agent en autonomie.
---

# vf-spike — Expérimentation jetable

Délègue à `gsd-spike` : exploration **expérientielle** d'une idée par le code — et, en mode
frontière, proposition de ce qu'il serait utile de spiker ensuite.

Reframe toute sortie en vocabulaire VibeFlow : « spike » → **expérimentation jetable**,
« frontier mode » → **proposition d'expérimentation** (cf. `vocabulary-map.md`). Ne nomme jamais
GSD ni `gsd-spike` à l'utilisateur.

**Le code d'un spike se jette.** S'il finit en production, ce n'était pas un spike : la conclusion
repart en `/vf-plan` puis `/vf-execute`, réimplémentée proprement.

Frontière avec `/vf-sketch` (module design) : ici le jetable est **fonctionnel** (ça tourne, ça
répond à une question technique) ; là-bas il est **visuel** (à quoi ça ressemblerait).

Enchaînement typique : `vf-explore` (question floue) → `vf-spike` (réponse par le code) →
`vf-plan` (on implémente pour de vrai).
