# 75-09b — trace de rouge (retrait de la couche « Travail récent », page et jetons)

Base du rouge : `c93844712` (tête après 75-09a). Chemins relativisés.

## Inventaire avant, écarts avec 75-RESEARCH § Retrait

Le grep d'inventaire de 75-09a (`btn-recent` compris) rend, côté page, des numéros de ligne déplacés par 74, 79, 80 et 75-07/08 : `viewer.html` 203-227 (pastille `.rw`, règles `.card.recent`), 333-336 (infobulle), 837-847 (état), 1024-1038 (pied de carte), 1080-1081 (classes), 1103-1117 (`recentTip`), 1665-1670 (bascule de « Types de liens ») ; `ui/00-vibeflow.js:111` (survol de l'ancien bouton) ; commentaires de `01-vf-responsive.js` et `02-vf-telephone.js`.
Hors liste de `files_modified`, nécessaires au retrait de `ui/25-recent.js` : `test-cockpit-coquille.sh` (K6 prenait `ui/25-recent.js` pour cible du mutant de module ; K5 nommait le fichier de la couche dans sa liste de routes refusées) ; `fixtures/test-cockpit-ecrans-recent/canal-harness.mjs` (neuf).
Forme de `VENDORED.txt` livrée par 79-01 : lignes `AJOUT` et `TAILLE` seulement (V10.3c : une ligne `RETRAIT` serait une ligne hors grammaire) ; `ui/25-recent.js` et `scripts/recent.mjs` n'y figuraient pas (fichiers d'origine, non `AJOUT`) : aucune ligne à poser ni à retirer (tâche 0 : la trace du retrait vit dans ce fichier et le CHANGELOG de 75-10).

## Comptes d'assertions (avant -> après) et intention conservée

| suite | avant | après |
|---|---|---|
| `test-cockpit-ecrans-recent.sh` | 12 | 18 (+6 : Q8.1 à Q8.4, Q8b.1, Q10.1) |
| `test-cockpit-responsive.sh` | 379 (370 PASS + 9 FAIL mesurés par 75-08) | 380 (+1 : Q9.1) |
| `test-cockpit-coquille.sh` | inchangé | inchangé (K5.1 et K6.1 changent de cible, pas de nombre) |

| ancienne assertion | nouvelle | intention conservée |
|---|---|---|
| R1.1 « badge : 3 cartes (4 entrées, a.js touché par deux tâches) » | R1.1 « pastille du sélecteur : 3 cartes (4 écritures d'agents, a.js écrit par deux agents) » | un fichier touché deux fois = une carte ; lu sur la table des marques (fonctions pures de `75-vf-activite-tables.js`) |
| R1.2 « panneau d'ensemble : même nombre que le badge » | R1.2 « table des marques : même nombre que la pastille, une rangée par carte » | le total affiché = le nombre de cartes |
| R2.1 « panneau d'une partie : 3 modifiés à l'intérieur » | R2.1 « agrégat du nœud sur le canal : 3 en écriture » | un nœud compte les mêmes cartes que ses fichiers (`VF_MARQUES.lire('n:part')`) |
| R2.2 « une ligne par carte » | R2.2 « une seule marque sur la carte écrite par deux agents » | pas de doublon par carte |
| `recent-doublons.json` (graphe `recent`) | table de marques (3 fichiers, 4 écritures d'agents) | même doublon, même attendu (3) ; témoin Q10.1 : 4/3 |
| E1 à E4 | inchangées | |
| R13.3 (responsive) | libellé « huit avec le sélecteur de lentilles et Écrans » ; badge posé sur `#btn-lentilles` | une entrée du « ⋯ » par action, libellé égal, pastille reportée |
| injection de l'ancien bouton (en-tête et o2b) | retirée : le sélecteur est posé par la page ; `screens-btn` reste injecté | pire en-tête réel à 1 024 px |

## Rouge sur la base `c93844712` (`ECRANS_MOTEUR` = arbre de la base, 15 PASS / 3 FAIL)

| assertion | attendu | obtenu | bonne raison |
|---|---|---|---|
| Q8.1 | `0` | `2` | `25-recent.js` et `00-vibeflow.js` portent encore l'ancien bouton |
| Q8.2 | `0` | `3` | `.rw`, bascule et infobulle subsistent dans la page et `25-recent.js` |
| Q8.3 | `0` | `1` | la règle `.card.recent` est active |

Verts dès la base, par nature : R1 et R2 (le canal de 75-07 existe), Q8.4 (jeton gardé), Q8b.1 (`showBoard` reste), Q10.1 (fixture), E1 à E4 (non-régression). Le rouge de `test-cockpit-responsive.sh` est celui mesuré par 75-08 sur l'ancienne suite à la tête `26bf0a3c` (370 PASS / 9 FAIL : R1, R2, R8, R9, D39.6, R13.3, par la coexistence des deux boutons) ; la suite migrée n'a pas été rejouée sur la base (17 minutes de Chrome) : son verdict vert est celui du code livré.

## Jetons (P71.5-D-29)

Propriétés personnalisées définies dans `viewer.html` : 103 avant, 103 après, `comm -3` vide ; `--recent`, `--on-recent-text`, `--recent-text` définis en clair et en sombre ; `--recent` employé par `75-vf-marques-glyphes.js` (glyphe « en écriture ») et par `00-vibeflow.js` (`--st-done`).

## Lignes de `viewer.html`

2 646 avant, 2 600 après (-46).

## Après

`test-cockpit-ecrans-recent.sh` : 18 PASS / 0 FAIL. `test-cockpit-vendor.sh` : 253 PASS / 0 FAIL. `test-cockpit-chaine-xss.sh` : 34 PASS. `test-cockpit-responsive.sh` (premier jeu, trois suites Chrome en parallèle) : 377 PASS / 3 FAIL : R13.3 (cause : `chrome-responsive.mjs` comptait les neuf rangées du menu des lentilles parmi les actions d'en-tête, « 9 entrées pour 15 actions » ; filtre ajouté, rejoué en fin de lot), D39m1a (mutant de plancher : valeur vide sous charge, rejeu isolé), H0 (un Chrome d'une suite voisine du même lot compté comme survivant). `test-cockpit-coquille.sh` : 111 PASS / 3 FAIL (C6.1 ids, M-ECOUTEURS, M-HEAD), IDENTIQUE à la tête `c93844712` rejouée sur une copie de l'archive : régression antérieure à ce plan, pas la sienne.
