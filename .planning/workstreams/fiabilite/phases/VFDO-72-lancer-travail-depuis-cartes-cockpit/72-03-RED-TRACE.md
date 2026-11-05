# 72-03 — trace du rouge (suite jouée sur la base, avant tout code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-cibles.sh` sur HEAD `b75074ef` (aucun `vf-cockpit-lancer-cibles.mjs` : le module est absent).
Résultat : `Résultats : 1 PASS / 50 FAIL`, rc=1 ; rejoué sous zsh (`zsh -c "bash …"`) : même bandeau. Commit des témoins : `b75074ef`.

## Vert sur la base : le témoin de la fixture

- **PAR.0** (le graphe réel `buildProjectGraph` des deux labs fixtures porte les identifiants écrits en littéraux dans la suite)
  - attendu : lab partitionné `dag-MISSION-72 dag-MISSION-LIBRE ph-42 ph-72 ph-73@fiabilite ph-73@gouvernance ph-74 ph-75 ph-76 ph-90 ph-91`, lab plat `dag-MISSION-2 ph-1 ph-2 ph-3`
  - obtenu : identique. Sans ce vert la fixture ne mesurerait rien (la parité PAR.1 serait vide contre vide).
  - Incident de fixture, corrigé AVANT le commit : un premier jeu de compartiments hostiles portait `Fiabilite` à côté de `fiabilite` ; sur APFS (insensible à la casse) c'est le même dossier, le ROADMAP hostile écrasait l'autre et PAR.0 rendait `dag-MISSION-72 dag-MISSION-LIBRE ph-42 ph-73 ph-90 ph-91` (phases 72, 74, 75, 76 perdues). C'est PAR.0 qui l'a dit. La majuscule hostile est devenue `Alpha`.

## Rouges sur la base (assertion, attendu, obtenu)

Toutes les assertions ci-dessous sont rouges pour la bonne raison : l'import du module échoue, `M` vaut `null`, chaque assertion lève et `chk` la consigne en FAIL.

- **C0** les huit noms exportés
  - attendu `[]`
  - obtenu `["module absent"]`
- **C1** identifiants `ph-72, ph-73@fiabilite, ph-73@gouvernance, ph-74, dag-LIBRE, dag-MISSION-72`, tous uniques
  - attendu l'objet `{ids, uniques:true}`
  - obtenu `exception: Cannot read properties of null (reading 'calculerCibles')`
- **C2, C3, C4, C5, P1 (cartes), P2, P3, PAR.1, PAR.2, PAR.3, B1, B2 (neuf variantes), B3, A1, A2, A4, A5, R1, X1, X2, X3, X4** : même obtenu, `reading 'calculerCibles'`
- **P1** table d'états de `actionPrincipale`
  - attendu `["cadrer","planifier","executer","executer","verifier",null]`
  - obtenu `exception: A is not a function`
- **Q1, Q2, Q3**
  - attendu : six clés / `["ph-72"]` / trois cibles saines
  - obtenu `exception: Cannot read properties of null (reading 'listePourQ')`
- **B4, R2, A3**
  - attendu : catalogue de neuf codes / réserve hors catalogue / `RECENCE_MS = 900000`
  - obtenu `exception: … (reading 'BLOQUANTS')`, `'AVERTISSEMENTS_RESERVES'`, `'RECENCE_MS'`
- **T1** module pur de moins de 300 lignes
  - attendu `ok`
  - obtenu `absent`

## Mutants sur la base : « sans effet », attendu

Les dix mutants sont rouges en tant que SUITE (FAIL « mutant sans effet ») : l'ancre (`export function <nom>(` ou `export const RECENCE_MS = `) n'existe pas encore dans le module absent. C'est le comportement voulu (« un mutant sans effet est un FAIL ») :
M-ID-SANS-WS, M-PRINCIPAL-FIXE, M-HORS-MOTIF-FUITE, M-FAIT-LANCABLE, M-TERMINAL-ARRETE-OUBLIE, M-MISSION-HORS-PHASE-OK, M-AVERT-BLOQUE, M-DEP-IGNORE, M-RECENCE-INFINIE, M-NONCOMMITE-ACTIF
  - attendu `effet`
  - obtenu `sans effet`
