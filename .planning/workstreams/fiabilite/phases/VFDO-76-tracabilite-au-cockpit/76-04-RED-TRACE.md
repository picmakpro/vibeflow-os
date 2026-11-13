BASE=b1746bc80a7e8e83ceaefba393dbcb6613dfac52

# 76-04 — trace rouge (suite écrite avant tout code ; tête de départ ci-dessus ; régime allégé : un seul témoin, le rouge d assertion)

Commande : bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-collecte.sh — sortie : 9 passés, 22 échoués (exit 1). Les rouges, assertion / attendu / obtenu :

```
  ❌ FAIL — T9.1 le nœud ph-1 porte trace.plans[0].exigences avec REQ-01 — attendu: [true] obtenu: [absent]
  ❌ FAIL — T9.1b meta.vf.trace.exigences : REQ-01 rattachée à la phase 1 — attendu: [1] obtenu: [absent]
  ❌ FAIL — T9.1c meta.vf.jalonActif = jalon mis en avant — attendu: [n:ms-v1] obtenu: [absent]
  ❌ FAIL — T9.2 vue de phase du vrai graphe = vue du harnais de 76-01 (JSON trié), une exigence — attendu: [true/1] obtenu: [false/0]
  ❌ FAIL — T9.3 sans l'option aucun champ trace ; avec { trace: true } il est rendu — attendu: [true/true] obtenu: [true/false]
  ❌ FAIL — T9.4 registre de ph-90 : P90-D-01 amendée (clé ph-90), D-04 nue — attendu: [P90-D-01/P90-D-01:ph-90/false/true,D-04/D-04:ph-90/true/false] obtenu: [absent]
  ❌ FAIL — T9.4b un seul registre (rien pour la phase 91 sans nœud) — attendu: [1] obtenu: [absent]
  ❌ FAIL — T9.4c registresSansPhase compte le CONTEXT de la phase 91 — attendu: [1] obtenu: [absent]
  ❌ FAIL — T9.5 maillon plan : REQ-02 non lisible, REQ-01 lu — attendu: [non-lisible/lu] obtenu: [absent]
  ❌ FAIL — T9.6 sous panne : les deux nœuds de phase existent et meta.vf.trace vaut { erreur: true } — attendu: [2/{"erreur":true}] obtenu: [2/undefined]
  ❌ FAIL — T9.6b témoin positif : sans la panne, meta.vf.trace.exigences est rempli — attendu: [2] obtenu: [absent]
  ❌ FAIL — T9.9b le chemin du lab est rendu relatif dans le critère — attendu: [voir docs/note.md pour le détail] obtenu: [absent]
  ❌ FAIL — T9.9c libellé et titre de définition : « un chemin hors du lab » — attendu: [true/true] obtenu: [absent]
  ❌ FAIL — T9.10 cites de REQ-01 : une décision préfixée, un ADR, une nue — attendu: [{"decisions":["P90-D-01"],"adrs":["ADR-001"],"nues":["D-04"]}] obtenu: [absent]
  ❌ FAIL — T9.10b cites de REQ-02 : trois listes vides — attendu: [{"decisions":[],"adrs":[],"nues":[]}] obtenu: [absent]
  ❌ FAIL — T9.11 mêmes identifiants dans le même ordre des deux côtés — attendu: [REQ-01,REQ-02,REQ-03|REQ-01,REQ-02,REQ-03] obtenu: [absent]
  ❌ FAIL — T9.11b coche vrai ⇔ état « fait » de la carte — attendu: [true] obtenu: [absent]
  ❌ FAIL — T9.11c libellé égal à la coupe près — attendu: [true] obtenu: [absent]
  ❌ FAIL — T9.11d chaque plan : mêmes exigences couvertes des deux côtés — attendu: [01-01-PLAN.md:true,01-02-PLAN.md:true] obtenu: [absent]
  ❌ FAIL — T9.11e témoin positif : REQ-02 dans les deux plans, REQ-03 dans aucun — attendu: [REQ-01+REQ-02/REQ-02] obtenu: [absent]
  ❌ FAIL — T9.7 le contrat déclare trace (nœud) et trace, registres, jalonActif (meta.vf) — attendu: [true/true] obtenu: [absent]
  ❌ FAIL — T9.8 la ligne POIDS est mesurée et delta > 0 — attendu: [true] obtenu: [false]
Résultats : 9 passés, 22 échoués
```

Les passes du rouge sont les témoins positifs (T9.4d, T9.5b, T9.9d, T9.10c, T9.7d), la copie mutée (T9.6a), T9.9 et T9.7b-c (champs absents donc rien à trouver, couverts par leurs voisins T9.9b-c et T9.7).
