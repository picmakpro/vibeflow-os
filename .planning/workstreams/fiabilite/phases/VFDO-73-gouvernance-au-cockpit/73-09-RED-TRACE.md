base: 852e638e9b76985e987acfe534a9d4a199784fab

# 73-09 — trace du rouge (régime allégé : le test d'abord, vu rouge, puis le code)

Un plan de re-pointage de témoins : aucun code de production. Le « rouge » est celui de l'ancien support, joué sur une copie jetable où
`vf-cockpit-equipe-carte.mjs` est réduit à l'enveloppe sans cartes (forme du plan 73-08) et où `ui/72-vf-equipe.js` est absent (retrait du canevas).
Commandes : les suites de la base (`git show <base>:<chemin>`) jouées dans une copie de `plugin/cockpit/scripts` portant cette enveloppe.

## Tâche 1 — LE → LR, W23, D2c, D3b, D2.7, D4.4, D4.5

| identifiant | ancien support | rouge observé à la réduction (copie jetable) | nouveau support |
|---|---|---|---|
| LE.0b | copie figée comparée à `vf-cockpit-equipe-carte.mjs` (import 72-07 et trois lignes `garde:`) | rouge : la copie ne diffère plus de l'enveloppe par ces seules lignes | LR.0b : sept empreintes sha256 distinctes, littéral de la suite, celles du commit de capture (73-03) |
| LE.0c | mutant de la copie figée | (non rejoué : dépend de LE.0b) | LR.0c : un mutant de `vf-cockpit-who.mjs` dont la cible est absente est détecté (code 1), témoin positif code 0 |
| LE.1 | sortie de `buildEquipeGraph` identique octet pour octet à la copie figée | rouge : plus de cartes dans la sortie | LR.1 (déjà en place depuis 73-03, empreintes de capture) |
| LE.2, LE.3 | ligne « Lancée depuis la carte » dans le détail d'une carte | rouge : aucun nœud | LR.2, LR.3 (donnée sur who@2) + LR.2b, LR.3b, LR.3c (texte sur la ligne de la régie, vm-regie-page.mjs) |
| LE.4, LE.5 | valeurs hostiles, hors session, sur la carte | rouge : aucun nœud | LR.4, LR.5 (who@2, déjà en place) |
| LE.6 | `name`, `nom`, `title`, `customTitle` hostiles, libellé de la carte | rouge : aucun nœud | LR.7 : who@2 sans champ `titre` ni texte hostile, ligne de régie « Session principale » |
| M-LANCEES-HORS-SESSION, M-LIGNE-SANS-VALIDATION, M-LIGNE-VIDE-TOUJOURS | `mut_le`, marqueurs de la carte | rouge : « mutant sans effet » (cible absente) × 3 | M-LANCEE-HORS-SESSION, M-LANCEE-SANS-VALIDATION (existants), M-LANCEE-VIDE-TOUJOURS (neuf, vu rouge sur LR.1) |
| W23.0 à W23.11, M-W23-BRANCHE, M-W23-BRANCHE-DETAIL | libellé et détail d'une carte (`buildEquipeGraph`) ; mutants dans `vf-cockpit-equipe-carte.mjs` | rouge : la fabrique de W23 lève sur le graphe sans cartes (W23.0 rouge, W23.1 à W23.11 rouges), ancres des deux mutants absentes | titre et branche lus sur who@2 (`collectWho`), texte lu sur la ligne de la régie ; mutants re-ancrés sur `garde:nettoie` de `vf-cockpit-who.mjs` |
| D2.7, D4.4, D4.5 | nœud `se-…` / `ag-…` de `buildEquipeGraph` | rouge : D2.7 (aucun nœud), D4.4 et D4.5 (section sans total) | ligne de la régie : section, mot, `data-vf-etat`, détail |
| D2c, D3b | `ui/72-vf-equipe.js` rejoué en vm (`SC.rerender`, panneau, pied de carte) | rouge : fichier absent de l'enveloppe du plan 73-08 | régie jouée par vm-regie-page.mjs : mot et section à chaque poussée, minuterie de 30 s, aucune écriture si le texte est identique |

Verts sur la tête de la tâche, joués une fois : `test-cockpit-lancer-suivi.sh` 57 PASS / 0 FAIL (47 à la base), `test-cockpit-who.sh` 157 PASS / 0 FAIL (157 à la base),
`test-cockpit-equipe-etats.sh` 86 PASS / 0 FAIL (86 à la base). Nombre de lignes `assert_` : lancer-suivi 39 → 50, who 151 → 151, equipe-etats 0 → 0 (ses assertions s'appellent `ok` et `eq` : 86 → 86).

Les sections re-pointées n'appellent pas `buildEquipeGraph` : seules D2.8 et M3.6 le gardent, pour `meta.vf.compte` (P73-D-03) ; la copie figée de la suite LR/LE ne le définit que comme document de provenance.

Rouge d'une garde : M-LANCEE-VIDE-TOUJOURS (champ `lancee` posé sur tout travailleur) rougit LR.1 ; M-W23-BRANCHE et M-W23-BRANCHE-DETAIL rougissent W23.10 ; chacun est joué sur le code sain avant d'être muté.

## Tâche 2 — largeur, visite, en-tête, accessibilité

| identifiant | ancien support | rouge observé | nouveau support |
|---|---|---|---|
| R14.1 (boucle `equipe`) | zoom du canevas dans l'en-tête, Équipe | rouge mesuré par 73-05 (`false\|false` pour `false\|true`) | la boucle sort `equipe` (raison écrite) ; R14.7 neuf : aucun zoom visible sur Équipe ; R14.2, R14.3 gardés sur Code et Projet |
| R17.0, R17.1, R17.1b | cartes et zoom du canevas (`nCartes`, `zoomCartes`) | rouge mesuré par 73-05 ; par construction à la réduction (aucune carte) | ligne de régie mesurée par chrome-cdp ; témoin négatif « aucun zoom de canevas », positif gardé sur Projet (R17.2) |
| R19.1, R19.2 | `#context h1` contre la première carte | rouge mesuré par 73-05 | `#vf-equipe-entete` contre la première section, avant et après dépliage de la première ligne |
| O6.14a | `VibeFlow.graph.nodes.length >= 2` | rouge par construction (enveloppe sans nœuds) | au moins deux `li.vf-rg-lig` ; O6.14 et O6.14b inchangés |
| H6.2 | `#context` (surtitre, h1, ligne « Agents : … ») | rouge par construction | `#vf-equipe-entete h1` et `.vf-rg-sous` ; deux cas restent ROUGES, voir le SUMMARY |
| X4.5, X7.3 | compte des `<main>` ; titre exact | — | régions `main, [role=main]` visibles ; préfixe « (N) vous attendent » toléré, N égal aux lignes de « À vous » (X7.3b) ; M-X45-DEUX-MAIN neuf |
| chargement de chrome-accessibilite.mjs | attend `#viewport .node` sur Équipe | rouge par construction après 73-08 | attend la régie montée et ses lignes |

Verts joués une fois : accessibilité 37 PASS / 0 FAIL (35 à la base) ; responsive 375 PASS / 0 FAIL ; projet-visite 114 PASS / 1 FAIL (R3.18, hors périmètre) ;
git-entete 117 PASS / 19 FAIL (les 17 de la 79 et deux cas de H6.2). Nombre de lignes `assert_` : responsive 125 → 126, accessibilité 29 → 31, projet-visite 68 → 68, git-entete 105 → 105.
