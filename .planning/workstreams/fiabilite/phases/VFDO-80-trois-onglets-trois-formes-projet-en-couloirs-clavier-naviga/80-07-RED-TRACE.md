# 80-07 : trace du rouge (témoins écrits avant le code)

Base : 07b4a15e + amendement (aucun fichier de 80-07 dans `ui/`) ; suite jouée dans une copie de base, TMPDIR du scratchpad.
Résultat sur la base : 3 PASS / 39 FAIL (PL0, PL3.3b, H0 verts : le serveur démarre, rien ne s'écrit sous `.planning/`, aucun processus ne survit).

```
  ❌ FAIL — PL1.1 — ?vue=liste : un table par bloc, rangées En cours, À recetter, À faire, Fait puis numéro ; aria-sort ascendant sur État seul
     attendu: [[true,["n:ph-4","n:ph-6","n:ph-3","n:ph-5","n:ph-1","n:ph-2"],[["etat","ascending"]]]]
     obtenu:  [[false,[],[]]]
  ❌ FAIL — PL1.2 — la bascule a trois boutons aria-pressed, un seul à true (Liste)
     attendu: [[["Couloirs","false"],["Liste","true"],["Graphe","false"]]]
     obtenu:  [[["Couloirs","true"],["Graphe","false"]]]
  ❌ FAIL — PL1.3 — clic sur la rangée de la phase 2 : sélection et aria-current sur la rangée
     attendu: [["n:ph-2",["n:ph-2"]]]
     obtenu:  [mesure absente : Cannot read properties of undefined (reading 'sel')]
--
  ❌ FAIL — PL2.1 — phase 1 : h1 « Phase 1 », vagues 1, 2, Sans vague ; statut de chaque plan ; « 2 exigences couvertes », « 1 exigence couverte », aucun segment
     attendu: [[true,["Vague 1","Vague 2","Sans vague"],[["01-01","2 exigences couvertes"],["01-02","1 exigence couverte"],["01-03",""]]]]
     obtenu:  [mesure absente : Cannot read properties of undefined (reading 'h1')]
--
  ❌ FAIL — PL2.3 — un seul arrêt de tabulation pour les plans ; ↓ d'une vague à l'autre, ↑, Fin, Origine ; la sélection suit
     attendu: [[3,1,[1,2,2,1,2,0],true]]
     obtenu:  [mesure absente : Cannot read properties of undefined (reading 'n')]
--
  ❌ FAIL — PL2.8 — Espace sélectionne, Entrée plonge, sur un plan Entrée ouvre le panneau ; au toucher : sélection sans plongée, bouton d'ouverture, Entrée plonge
     attendu: [["n:ph-3",["n:ph-3"],"n:ph-3",true,[true,true,"n:ph-1"],["n:ph-3",true,"root",1],"n:ph-4","n:ph-4"]]
     obtenu:  [mesure absente : Cannot read properties of undefined (reading 'espace')]
--
  ❌ FAIL — PL2.9 — porte substituée : le lab n'a aucune exigence (témoin positif) ; avec la fausse porte, deux exigences et « 2 exigences couvertes » par plan ; restaurée : vide
     attendu: [[[0,0],0,2,true,true,0]]
     obtenu:  [mesure absente : Cannot read properties of undefined (reading 'graphe')]
--
  ❌ FAIL — PL3.1 — v : couloirs → liste → graphe → couloirs ; focus sur l'élément équivalent (même phase), jamais body ; annonce « Affichage en liste, 6 phases »
     attendu: [["liste,graphe,couloirs","n:ph-4","Affichage en liste, 6 phases",true]]
     obtenu:  [["couloirs,couloirs,couloirs","n:ph-4","",true]]
  ❌ FAIL — PL3.2 — v dans un TEXTAREA et avec Alt, Ctrl, ⌘ : aucune bascule, la lettre est tapée ; témoin : v seule bascule
     attendu: [[["couloirs","v"],"couloirs,couloirs,couloirs","liste"]]
     obtenu:  [[["couloirs","v"],"couloirs,couloirs,couloirs","couloirs"]]
--
  ❌ FAIL — PL3.4 — tri par Plans : ascendant puis descendant, annonces, sans plan en dernier ; donnée absente après « aucune », texte masqué
     attendu: [["n:ph-3,n:ph-4,n:ph-1,n:ph-2,n:ph-6,n:ph-5","plans","Trié par Plans, croissant","n:ph-1,n:ph-2,n:ph-6,n:ph-4,n:ph-3,n:ph-5",1,"Trié par Plans, décroissant","n:ph-3","donnée non disponible"]]
     obtenu:  [mesure absente : Cannot read properties of undefined (reading 'asc')]
  ❌ FAIL — PL3.5 — 390 px : rôles posés, quatre boutons de tri ≥ 44 px, bascule à trois segments ≥ 44 px pleine largeur sous le h1 ; aucun défilement horizontal (390 et 800)
     attendu: [["true,true,true,true",4,true,3,true,true,true,"true,true,true","true,true,true","true,true,true","true,true,true"]]
     obtenu:  [["false,false,false,false",0,true,2,true,false,false,"true,true,true","true,true,true","true,true,true","false,true,false"]]
```

Raisons : la forme « liste » n'existe pas (obtenu : aucune table, bascule à deux segments « Couloirs », « Graphe », pas de touche v, pas de mémoire) ; PL2.9 : « window.VF_EXIGENCES » est indéfinie sur la base. Les sections de mutants échouent en « mutation impossible » : les fichiers à muter n'existent pas.
