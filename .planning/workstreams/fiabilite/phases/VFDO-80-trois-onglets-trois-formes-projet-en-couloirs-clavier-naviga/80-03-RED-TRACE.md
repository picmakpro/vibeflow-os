# 80-03 — RED-TRACE (P80-D-25)

## Tâche 1 — PC1, sur la base (champs absents du graphe)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet-champs.sh` à la tête 680364f1 + amendement ; sortie verbatim.
PC1.2 vert = témoin d invariance du pied (il prouve aussi que le nœud `ph-1` existe : le rouge des autres n est pas un fixture mort).

```
=== PC1 — avancement et exigences structurés sur la phase ===
  ❌ FAIL — PC1.1 — ph-1 : etat fait, plans 2/2, exigences 1 sur 2
     attendu: [fait|{"faits":2,"total":2}|{"faits":1,"total":2}]
     obtenu:  [||]
  ✅ PASS — PC1.2 — témoin d'invariance : pied et statut de ph-1 inchangés
  ❌ FAIL — PC1.3 — ph-2 sans dossier : plans 0, reste « cadrage », exigences 0 sur 0
     attendu: [0|true|{"faits":0,"total":0}]
     obtenu:  [||]
  ❌ FAIL — PC1.4 — la mission d'une phase vivante est {nom, etat}, aucune clé de verrou dans le graphe
     attendu: [{"nom":"MISSION-LIENS","etat":"running"}|false]
     obtenu:  [undefined|false]

==================================
  Résultats : 1 PASS / 3 FAIL
==================================
```

## Tâche 2 — PC2 à PC4 et mutants, sur la base (code et contrat non touchés)

Rouges pour la bonne raison : champs absents (PC2.1 : `plans` non posé), `recette` absent du contrat (PC3.1), bloc sans `optionnels` (PC3.2), pied du backlog non vidé (PC4.1).
PC3.3 : `L` vide, AVANT = HEAD et APRES = arbre : `0-|0+|aucun-changement`, attendu `1-|2+|ancre-statuts`. M-STATUTS : ancre `recette` absente du contrat de la base, donc pas de mutation possible. M-AUTRE-LIGNE : `1-|1+|hors-ancre` sur la base (la copie ne porte pas encore la correction). M-VIE passe déjà : le code de la tâche 1 est en place.

```
  ❌ FAIL — PC2.1 — ph.plans trié (vague 1, 2, null), même vague sur l'élément du graphe, pied du plan inchangé
     attendu: [[[{"id":"01-01","fichier":"01-01-PLAN.md","vague":1},{"id":"01-02","fichier":"01-02-PLAN.md","vague":2},{"id":"01-03","fichier":"01-03-PLAN.md","vague":null}]]|[1,2,null]|vague 1,vague 2,vague ?]
     obtenu:  [[null]|[null,null,null]|vague 1,vague 2,vague ?]
  ❌ FAIL — PC3.1 — « recette » dans statuts, émis par le lab à recetter, tout st émis y figure
     attendu: [true|true|]
     obtenu:  [false|true|recette]
  ❌ FAIL — PC3.2 — optionnels juste après statuts ; requis, meta et version inchangés
     attendu: [{"noeud":["avancement","exigences"],"element":["vague"]}|1|{"requis":["id","label","kind"]}|{"requis":["p","n","name"]}|{"requis":["vfTab","vf","kindLabels"]}|1]
     obtenu:  [|-5|{"requis":["id","label","kind"]}|{"requis":["p","n","name"]}|{"requis":["vfTab","vf","kindLabels"]}|1]
  ❌ FAIL — PC3.3 — le contrat ne change que sur les lignes "statuts" et "optionnels" de cockpit-project@1 (diff contre la base)
     attendu: [1-|2+|ancre-statuts]
     obtenu:  [0-|0+|aucun-changement]
  ❌ FAIL — PC4.1 — pied vide et statut inchangé : DIFFÉRÉ todo, INVESTIGUÉ done
     attendu: [[]todo,[]done]
     obtenu:  [[DIFFÉRÉ]todo,[INVESTIGUÉ]done]
  ✅ PASS — M-VIE — le mutant rougit PC1.4 : la mission projetée entière fait sortir une clé de verrou
  ❌ FAIL — M-STATUTS — le mutant rougit PC3.1 : « recette » retiré de statuts, le graphe en émet encore
     attendu: [false|true|recette]
     obtenu:  [ancre-absente]
  ❌ FAIL — M-AUTRE-LIGNE — le mutant rougit PC3.3 : la ligne "lien" du bloc cockpit-project@1 modifiée (valeur exacte)
     attendu: [2-|3+|hors-ancre]
     obtenu:  [1-|1+|hors-ancre]
  Résultats : 5 PASS / 7 FAIL
```
