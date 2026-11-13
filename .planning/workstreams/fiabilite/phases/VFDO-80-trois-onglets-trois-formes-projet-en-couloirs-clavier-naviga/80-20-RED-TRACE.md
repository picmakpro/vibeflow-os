# 80-20 — RED-TRACE (témoins rouges sur la base fusionnée)

Régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) : pas de mutant.
Base : tête 64fad93da de la branche, sans aucun changement de ce plan.

## Tâche 1 — la zone du titre (suite test-cockpit-entete.sh, EN1)

Rouges attendus : EN1.1, EN1.5, EN1.6. Témoins d'invariance verts sur la base : EN1.2, EN1.2b, EN1.3, EN1.4 (relevés AVANT recopiés dans la suite).

```
  ✅ PASS — EN0 — serveur du lab démarré (avec --terminal)
  ❌ FAIL — EN1.1 (code1440) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context
     attendu: [[true,0,0,32]]
     obtenu:  [[true,32,24,32]]
  ❌ FAIL — EN1.1 (code800) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context
     attendu: [[true,0,0,32]]
     obtenu:  [[true,32,24,32]]
  ❌ FAIL — EN1.1 (code390) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context
     attendu: [[true,0,0,32]]
     obtenu:  [[true,24,24,32]]
  ❌ FAIL — EN1.1 (graphe1440) — après un glisser qui amène une carte sous le titre, puis « + » : aucune .card ni g.node ne passe sous les 8 × 4 points de #context
     attendu: [[true,0,0,32]]
     obtenu:  [[true,32,16,32]]
  ✅ PASS — EN1.2 — hauteur de la zone ≤ 130 px, le texte du titre et le flou (halo de #context::before) sont gardés
  ✅ PASS — EN1.2b — freeArea() et la transformation après « f » (Code à 1440, 800, 390 px, graphe de Projet) égales à la base fusionnée : la mise en page ne change pas
  ✅ PASS — EN1.3 — couloirs et liste : #svg sans découpe
  ✅ PASS — EN1.4 — zone basse (lab --terminal, feuille ouverte) à 390 et 800 px : rectangles de #ask, #zoom, de la pastille « Terminal », de la feuille et --vf-bas (au pa
  ❌ FAIL — EN1.5 — Code → Projet → Code par VF_ONGLETS.aller (même document : timeOrigin) : Projet sans découpe, Code de nouveau sans carte sous le titre, découpe reposée
     attendu: [[true,"none",0,32,true]]
     obtenu:  [[true,"none",32,32,false]]
  ❌ FAIL — EN1.6 — A51 (P80-D-59) : après Code → Projet → Code (deux fois), un seul ResizeObserver et un seul écouteur resize de 01-vf-ensemble.js, comme à froid ; 01-vf-
     attendu: [[true,true,true,true]]
     obtenu:  [[false,false,true,true]]
  ✅ PASS — H0 — aucun serveur ni Chrome de cette suite ne survit (avant : 0)
  Résultats : 6 PASS / 6 FAIL
```
