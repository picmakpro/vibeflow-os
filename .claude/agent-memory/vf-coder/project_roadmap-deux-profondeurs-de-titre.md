---
name: roadmap-deux-profondeurs-de-titre
description: Le ROADMAP mêle `### Phase` et `#### Phase` (13 + 13 = 26) — toute assertion ancrée sur une seule profondeur compte moitié et rougit à tort
metadata:
  type: project
---

`.planning/ROADMAP.md` mêle **deux profondeurs de titre** pour ses phases. Mesuré le 2026-08-04 :
**13** en-têtes `### Phase ` et **13** en-têtes `#### Phase `, soit **26** — la valeur que porte
`STATE.md` (`total_phases: 26`).

Une assertion « le ROADMAP porte exactement 26 en-têtes `### Phase ` » compte **13** et rougit à
tort. Compter les deux :
`awk '/^#{3,4} Phase [0-9]/{n++} END{exit !(n==26)}' .planning/ROADMAP.md`

**Why:** un plan de la Phase 24 (24-10) portait exactement cette assertion, en garde de
non-régression du verdict « PAS DE PHASE 27 ». À l'exécution elle aurait rougi sur un fichier
pourtant intact — et le risque réel n'est pas le faux rouge, c'est qu'un exécuteur « répare » le
ROADMAP pour satisfaire le gate. Un garde-fou qui rougit à tort sur l'objet qu'il protège finit par
faire modifier cet objet.

**How to apply:** avant de graver un compteur d'en-têtes dans un gate ou un critère d'acceptation,
mesurer les **deux** profondeurs séparément et vérifier la somme contre `STATE.md`. Le repo n'est pas
homogène : les phases 1-14 sont majoritairement en `####`, les phases 15-26 en `###`. Vaut pour tout
compteur structurel sur ce fichier, pas seulement les phases.

Voisin de [[recette-grep-c-litteral]] et de [[roadmap-faits-perissables]] : même famille de piège —
l'ancre paraît évidente, elle est partielle, et le vert/rouge ne dit pas laquelle.
