---
phase: 69-suivi-travail-en-cours-cockpit
plan: 01
requirements: [CKPT-13, CKPT-14, CKPT-15, CKPT-16, CKPT-17, CKPT-18]
estimate:
  tokens: 95000
  tasks: 3
actuals:
  tasks: 3
  commits: 6
---

# 69-01 — avancement des phases (CKPT-13 à CKPT-18)

Trace du rouge avant le code : `69-01-RED-TRACE.md` (25 témoins rouges, 10 contrôles positifs verts).

## Commits

- `4fce7e42` test : suite `test-cockpit-avancement.sh` seule (commit A)
- `55c97762` docs : trace du rouge (commit B)
- `efccf803` feat : décompte plans/correctifs jusqu'à la carte (commit C, A1 vert)
- `838982ea` feat : états, rattachement des missions, pied du jalon, reste, retrait de la règle STATE
- `3ea407b6` feat : contrat `avancement@1`, libellés de « Prochaines phases »

## Assertions réécrites par conception (CKPT-18, règle STATE -> statut retirée)

- P1.1 : `ph-1:done,ph-2:active` -> `ph-1:done,ph-2:todo` (le STATE pointe la phase 2 mais aucun plan n'y est fait).
- P1.2 : `01-01:done,02-01:active` -> `02-01:todo` (aucun nœud `running` ne désigne le plan, P69-PL-04).
- P1.5 : pied `1/2 phases · 50 %` -> `1 clos · 0 à recetter · 1 à faire · 50 %` (P69-PL-03).

`test-cockpit-direct.sh` et `test-cockpit-questions.sh` : aucune autre assertion n'a changé de sens.

## Écarts et consignes

- Le voisin 69-02 a commité entre-temps dans le même arbre ; périmètre non touché.
- Ajout non prévu : A18.0 (le source réel ne contient plus `=== curPhase`).
- A4.3 est strict (pied complet égal) au lieu de « contient ».
- Complément de mandat du manager (DA Graphite) : le code neuf de `00-vibeflow.js` n'utilise que des classes existantes (`vst-todo`, `vst-active`), aucune couleur en dur ; non vérifié visuellement dans les deux thèmes (aucun navigateur lancé).
