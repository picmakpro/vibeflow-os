# 80-09 — trace des témoins rouges sur la base (P80-D-25, régime allégé)

Base : tête 68343e27 (Phase 79 fusionnée jusqu'à 79-16). Suite test-cockpit-zoom-garde.sh jouée avant tout changement du moteur.

```
  ✅ PASS — ZG0 — serveur du lab démarré
  ❌ FAIL — ZG1.1 — niveau de 70 cartes : après « f », state.t égale VibeFlow.cadrage() (1e-6) et k >= 11/13
     attendu: [["function",true,true]]
     obtenu:  [["undefined",false,true]]
  ❌ FAIL — ZG1.2 — #vf-coin affiché : aucune carte entière ne le touche après « f » ; tiroir Git ouvert puis fermé : state.t et freeArea().w inchangés
     attendu: [[true,true,0,true]]
     obtenu:  [[true,true,2,true]]
  ❌ FAIL — ZG1.4 — après Projet puis Code (coquille) : le premier rendu est cadré dans le champ, « f » rend le même state.t, un appel du fournisseur par cadrage
     attendu: [[true,true,[1,1]]]
     obtenu:  [[false,true,null]]
  ❌ FAIL — ZG1.5a — Code chargé sous /project.html : plancher 11/13 appliqué (kFit du niveau dessous), pour les deux sources de l'onglet
     attendu: [[{"chemin":"/project.html","plafonne":true,"bas":true},{"chemin":"/project.html","plafonne":true,"bas":true}]]
     obtenu:  [[{"chemin":"/project.html","plafonne":false,"bas":true},{"chemin":"/project.html","plafonne":false,"bas":true}]]
  ❌ FAIL — ZG1.5b — Projet chargé sous / : aucun plancher (k = kFit, sous 11/13), pour les deux sources (onglet() puis meta.vfTab)
     attendu: [[{"chemin":"/","libre":true,"bas":true,"onglet":"projet"},{"chemin":"/","libre":true,"bas":true,"onglet":null}]]
     obtenu:  [[{"chemin":"/index.html","libre":false,"bas":true,"onglet":"projet"},{"chemin":"/index.html","libre":false,"bas":true,"onglet":null}]]
  ❌ FAIL — ZG2.1 — « + » puis « - » : state.t identique (1e-6), facteur 1,25
     attendu: [[true,true]]
     obtenu:  [[false,false]]
  ❌ FAIL — ZG2.2 — carte sélectionnée visible : son centre écran ne bouge pas (0,5 px)
     attendu: [true]
     obtenu:  [false]
  ❌ FAIL — ZG2.3 — sans sélection : le centre du champ de lecture reste fixe, boutons = touches (même facteur, même centre), retour exact
     attendu: [[true,true,true]]
     obtenu:  [[false,false,false]]
  ❌ FAIL — ZG3.1 — « f », « p », « + », Retour arrière dans un TEXTAREA, un SELECT, un contenteditable : vue, panneau et niveau inchangés, lettres tapées
     attendu: [[true,"fp","fp"]]
     obtenu:  [[false,"fp+","fp+"]]
  ❌ FAIL — ZG3.2 — Ctrl+p, Alt+f, ⌘f : aucun basculement ni cadrage
     attendu: [true]
     obtenu:  [false]
  ❌ FAIL — ZG3.3 — VibeFlow.enSaisie : vrai pour INPUT, TEXTAREA, SELECT, contenteditable, faux pour un div
     attendu: [[true,true,true,true,false]]
     obtenu:  [null]
  ❌ FAIL — ZG4.1 — 40-tour.js cadre par SC.cadrage( ; la formule n'existe plus que dans viewer.html
     attendu: [1|0]
     obtenu:  [0|1]
  ✅ PASS — ZG4.3 — mouvement réduit : aucune animation active après « + », « - », « f »
  ✅ PASS — ZG5.1 — un seul écouteur de document actif : au chargement, sur Projet, sur Code, après deux allers-retours
  ✅ PASS — ZG9 — témoin : aucune section du pilote n'a échoué
  ✅ PASS — ZG0t — serveur du lab --terminal démarré
  ❌ FAIL — ZG2.4 (tactile, feuille ouverte) — pastille présente, carte sélectionnée immobile à + puis -, ni #ask, #zoom, pastille ni feuille touchées, centre du champ fixe
     attendu: [[true,true,true,true,true]]
     obtenu:  [[true,false,false,false,false]]
  ❌ FAIL — ZG2.4 (tactile, feuille fermee) — pastille présente, carte sélectionnée immobile à + puis -, ni #ask, #zoom, pastille ni feuille touchées, centre du champ fixe
     attendu: [[true,true,true,true,true]]
     obtenu:  [[true,false,false,false,false]]
  ❌ FAIL — ZG2.4 (moyen, feuille ouverte) — pastille présente, carte sélectionnée immobile à + puis -, ni #ask, #zoom, pastille ni feuille touchées, centre du champ fixe
     attendu: [[true,true,true,true,true]]
     obtenu:  [[true,false,true,false,false]]
  ❌ FAIL — ZG2.4 (moyen, feuille fermee) — pastille présente, carte sélectionnée immobile à + puis -, ni #ask, #zoom, pastille ni feuille touchées, centre du champ fixe
     attendu: [[true,true,true,true,true]]
     obtenu:  [[true,false,true,false,false]]
  ✅ PASS — ZG2.9 — témoin : aucune section du pilote n'a échoué (zone basse)
  ✅ PASS — H0 — aucun serveur ni Chrome de cette suite ne survit (avant : 0)
  Résultats : 7 PASS / 16 FAIL
```

ZG5.1 (idiome A51 de 04-vf-clavier-canevas.js) : VERT sur la base — la portée de 79-16 retire déjà l'écouteur de document du fichier (posé dans init, rendu comme nettoyage) ; le témoin n'a donc pas de rouge à tracer, il reste comme garde de non-régression (voir le SUMMARY).
