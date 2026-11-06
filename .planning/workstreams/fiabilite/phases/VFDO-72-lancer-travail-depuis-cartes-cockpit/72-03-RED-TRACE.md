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

## Corrections de la suite avant le code (aucune assertion affaiblie)

Trois attendus erronés, constatés avant que le module existe (commits `6e9f5f94` et `6ae76755`) : **Q3** et **P1 (cartes)** joignaient `null` par `join`, qui le rend en chaîne vide, si bien que l'attendu `null` ne pouvait jamais être atteint ; **C5** cherchait le texte hostile dans tout l'objet, identifiant compris, alors que l'identifiant garde le numéro du ROADMAP (parité PAR.1). Les trois restaient rouges sur la base (module absent) ; le contrôle de C5 porte maintenant sur les champs autres que `id`.
Un `verdict` minimal est livré avec la Tâche 2 : C0 exige les huit noms exportés, et la commande `cibles` doit être verte.

## Mutants rouges des cibles (Tâche 2, HEAD `fdb6de06`)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-cibles.sh cibles` -> `Résultats : 21 PASS / 0 FAIL`, rc=0 (bash puis `zsh -c "bash …"`). Le module livré : 94 lignes à ce stade.

| Mutant | Rouge sur (obtenu) | Sondes exigées | Ligne qui le tue |
|--------|--------------------|----------------|------------------|
| M-ID-SANS-WS (suffixe `@<ws>` retiré) | C1 C2 PAR.1 PAR.3 | C1 PAR.1 | C1 : obtenu `ph-73` deux fois au lieu de `ph-73@fiabilite` et `ph-73@gouvernance` ; PAR.1 : `absente:ph-73@fiabilite` |
| M-PRINCIPAL-FIXE (`executer` sauf `fait`) | P1 P2 PAR.3 | P1 | P1 : premier cas obtenu `executer` au lieu de `cadrer` |
| M-HORS-MOTIF-FUITE (`listePourQ` rend tout) | PAR.2 Q1 Q2 Q3 | Q1 Q2 Q3 | Q2 : neuf identifiants rendus au lieu de `["ph-72"]` ; Q1 : clés `principal`, `bloquants`, `titre` présentes |

Les sondes rouges en plus des sondes exigées (C2, PAR.3, P2, PAR.2) sont légitimes : elles lisent aussi les identifiants, les principaux ou la projection.

## Mutants rouges des pré-vols et verts finaux (Tâche 3, HEAD `46930e1c`)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-cibles.sh` -> `Résultats : 51 PASS / 0 FAIL`, rc=0 ; sous zsh (`zsh -c "bash …"`) : `51 PASS / 0 FAIL` ; `cibles` seul : `21 PASS / 0 FAIL` ; `previols` seul : `30 PASS / 0 FAIL`. Module : 117 lignes. Les mutants sont rejoués en mode `tout` pour relever aussi les sondes rouges en plus des exigées.

| Mutant | Sondes exigées | Rouge en mode `tout` | Obtenu (ligne qui le tue) |
|--------|----------------|----------------------|----------------------------|
| M-FAIT-LANCABLE | B2 B3 | P1 P3 B2 B3 | B2 phase finie : obtenu `[[],true]`, attendu `[["phase-finie"],false]` ; B3 : `ensemblesOk` 72 sur 120 |
| M-TERMINAL-ARRETE-OUBLIE | B2 B3 | B2 B3 | B2 terminal arrêté : obtenu `[[],true]` ; B3 : `ensemblesOk` 80, `lancableOk` 118 |
| M-MISSION-HORS-PHASE-OK | B2 B3 | C4 B2 B3 | C4 : obtenu `[[],null,null]` ; B3 : `ensemblesOk` 108 |
| M-AVERT-BLOQUE | A1 A5 | A1 A5 | A1 : `lancable` faux pour les cinq cas isolés ; A5 : `[["dependance-non-close",…],false]` |
| M-DEP-IGNORE | A1 A5 | A1 A5 | A1 : premier cas obtenu `[[],true]` au lieu de `[["dependance-non-close"],true]` ; A5 : trois codes au lieu de quatre |
| M-RECENCE-INFINIE | A3 | A3 | A3 : `RECENCE_MS` obtenu `null` (Infinity sérialisé) et un lancement à 900001 ms avertit encore |
| M-NONCOMMITE-ACTIF | R1 | R1 | R1 : obtenu `{"appels":1,"emis":true}` au lieu de `{"appels":0,"emis":false}` |

Les dix mutants du plan sont donc rouges, ceux de la section des cibles consignés plus haut.

## Écart et points de jugement

- Compartiment hostile `Fiabilite` : remplacé par `Alpha` dans le lab partitionné (même dossier que `fiabilite` sur APFS). Le motif reste testé avec `Fiabilite` en lecteur littéral (C5).
- `listePourQ` exclut aussi toute carte dont les bloquants portent `phase-hors-motif` ou `compartiment-hors-motif`. Sans cela une carte au compartiment hostile porte `ws: null`, indiscernable d'un lab plat, et Q la proposerait sans compartiment (PAR.2, Q2 : sonde `q90`).
