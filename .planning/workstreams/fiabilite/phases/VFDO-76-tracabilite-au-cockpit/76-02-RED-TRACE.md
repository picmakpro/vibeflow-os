# 76-02 — Trace rouge

Régime allégé : seul témoin exigé, le test vu rouge avant le code (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Tâche 1 — T5.1 (modules `vf-cockpit-registres.mjs` et `vf-cockpit-trace-git.mjs` absents)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-decisions.sh`

```
  ❌ FAIL — T5.1 — le commit qui cite ADR-001 est relié à la section (h7, jour, sujet) et son corps n'est pas servi
     attendu: [true|7|true|false]
     obtenu:  [absent]
  ✅ PASS — T5.2 — témoin positif : le corps du commit contient bien le marqueur dans git
  Résultats : 1 PASS / 1 FAIL
```

Rouge par l'assertion visée : le harnais attrape l'échec d'import et imprime `{"erreur":"module-absent"}`, rendu `absent`. T5.2 vert dès le départ (la fabrication du marqueur est prouvée).

## Tâche 2 — T5.4 à T5.7 (`definitionsRegistre` posée en coque vide, aucune arête décision)

Même commande. T5.1 à T5.3 et les témoins positifs verts ; rouges par l'assertion visée :

```
  ❌ FAIL — T5.4 — définitions : doublon en une entrée amendée, nue qualifiée par sa phase, titre ### et bloc de code ignorés, phase décimale lue
     attendu: [[1,1,0,0,[true,["ADR-001"],false,"P90-D-01:ph-90",1],[true,"D-04:ph-90"],["P90.5-D-01",false,"P90.5-D-01:ph-90.5"],["P90.5-D-02",false,"P90.5-D-02:ph-90.5"]]]
     obtenu:  [[0,0,0,0]]
  ❌ FAIL — T5.4 — un commit qui cite P90.5-D-01 est relié à la définition de la phase décimale
     obtenu:  [illisible]   (parDecision vide : la clé P90.5-D-01:ph-90.5 n'existe pas)
  ❌ FAIL — T5.5 — décision préfixée reliée à son commit, nue sans commit, le commit « D-04 » remonté par son ADR
     obtenu:  [illisible]   (parDecision vide)
  ❌ FAIL — T5.6 — ADR -> décisions : arête lue dans la ligne de définition, aucune arête exigence -> décision
     attendu: [[["P90-D-01:ph-90"],false]]
     obtenu:  [[[],false]]
  ❌ FAIL — T5.7 — titre de 150 caractères et plus coupé à 80 au plus, sans gras ni accent grave
     attendu: [[[true,true,false]]]
     obtenu:  [[]]
  Résultats : 5 PASS / 5 FAIL
```
