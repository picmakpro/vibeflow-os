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
