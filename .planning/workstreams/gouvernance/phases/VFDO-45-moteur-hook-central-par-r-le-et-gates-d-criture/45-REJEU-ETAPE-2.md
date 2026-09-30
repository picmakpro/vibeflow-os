# Relevé du rejeu réel — étape 2 (G1) — 45-06

**Mesure seule — armement différé : l'étape 1 n'est pas encore armée (autorisation d'adaptation des suites en attente), P45-D-03.**

## En-tête

| Champ | Valeur |
|---|---|
| Date (UTC) | 2026-09-30 |
| Hook mesuré | `plugin/planning-core/scripts/planning-hook.sh` au commit `630478c` (G1 en observation dans le code livré ; aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` touchée) |
| Outil de rejeu | `plugin/planning-core/scripts/rejeu-reel.sh --etape=2` (empreinte de tout l'arbre, extérieure à `rejeu-gates.sh`, puis constructeur G1 à classification totale, règle « hors étape ») |
| Décisions portées | Rejeu réel autorisé, modèle de référence sur lab non migré : P45-D-21 et P45-D-21a (Willy, AskUserQuestion session principale, 2026-09-29). Mise au repos des labs : Willy, AskUserQuestion session principale, 2026-09-30, « ferme les processus et go » |
| Conditions | Labs en lecture seule sur copie, empreinte de tout l'arbre avant et après, aucun geste git dans les labs, chemins affichés `~/…` |
| Statut | Mesure seule. Aucun armement, aucun commit de code ni de test |

### Contrôle de repos (lecture seule, `lsof -d cwd`, avant et après le rejeu)

| Lab | Processus dont le répertoire courant est sous le lab |
|---|---|
| `~/jarvis-keystone` | 0 |
| `~/BusinessFlow-Lab` | 4 : 2 `Code Helper (Plugin)` (PID 4670, 5146) et 2 `zsh` inactifs (PID 5119, 65656), seuls restants annoncés |

## Comptes (lignes brutes du rejeu)

```
COMPTE G6 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G5 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G1 faux-refus=0 faux-accept=0 refus-conforme-modele=196
REJEU-ETAPE-2 faux-refus=0 faux-accept=0 refus-conforme-modele=196
CLASSE-REGLE-ECRITE G1 lab=~/jarvis-keystone n=200
CLASSE-REGLE-ECRITE G1 lab=~/BusinessFlow-Lab n=0
EMPREINTE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-IDENTIQUE ~/BusinessFlow-Lab
EMPREINTE-ARBRE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-ARBRE-IDENTIQUE ~/BusinessFlow-Lab
```

Le relevé nominatif compte 4339 lignes (non recopié, il se relance par la commande de l'en-tête) : 3575 en doit-passer (passage obtenu), 568 en doit-refuser (refus obtenu), 196 en doit-refuser-modele (refus obtenu), aucun écart dans aucun sens. Aucune commande git n'a été lancée dans les labs ; aucun préfixe de dossier personnel de la machine n'apparaît dans le relevé.

## Refus conformes au modèle, lab non migré

196 refus de G1, tous sur `~/jarvis-keystone` (0 sur `~/BusinessFlow-Lab`). Ce sont des plans écrits sous l'ancienne discipline : le modèle (P45-D-21a) les refuserait, le lab n'a pas encore été migré. Ce ne sont ni des faux refus ni des faux accepts.

| Lab | Motif | n |
|---|---|---|
| `~/jarvis-keystone` | refus conforme au modèle, lab non migré | 189 |
| `~/jarvis-keystone` | refus conforme au modèle, lab non migré ; classé par la règle écrite, état dérivé absent : pas-de-cadrage | 7 |
| `~/BusinessFlow-Lab` | (aucun) | 0 |

Répartition par phase (atelier `20-ateliers/01-marche-offre`, sauf mention) :

| Motif | Phase | n |
|---|---|---|
| non migré | cycle 01-la-recherche / 01-la-cascade-des-17-etapes | 1 |
| non migré | cycle 01-la-recherche / 02-rendre-le-corpus-interrogeable | 3 |
| non migré | cycle 02-le-nom / 01-generer-et-cribler | 1 |
| non migré | cycle 03-l-offre / 01-l-escalier-de-prix | 1 |
| non migré | cycle 04-la-charte-et-la-boutique / 01-la-charte | 6 |
| non migré | cycle 04-la-charte-et-la-boutique / 02-le-theme | 1 |
| non migré | cycle 05-le-tunnel / 01-les-autopsies-de-reference | 1 |
| non migré | cycle 05-le-tunnel / 02-la-copie | 3 |
| non migré | cycle 05-le-tunnel / 03-les-visuels | 10 |
| non migré | cycle 05-le-tunnel / 04-le-montage-boutique | 4 |
| non migré | cycle 05-le-tunnel / 05-la-cloture-de-l-advertorial | 7 |
| non migré | cycle 05-le-tunnel / 06-la-cloture-de-la-fiche-produit | 53 |
| non migré | cycle 05-le-tunnel / 07-l-apparence | 1 |
| non migré | cycle 06-la-publicite / 01-la-doctrine-de-test | 2 |
| non migré | cycle 06-la-publicite / 02-le-sourcing-du-marche | 74 |
| non migré | cycle 06-la-publicite / 03-les-creatives-produites | 21 |
| pas-de-cadrage | `.planning` racine, cycle 05-le-tunnel / 06-la-cloture-de-la-fiche-produit | 1 |
| pas-de-cadrage | cycle 07-armer-les-agents / 01-la-matiere-de-metier | 1 |
| pas-de-cadrage | cycle 07-armer-les-agents / 02-la-surface-d-ecriture-et-le-registre | 3 |
| pas-de-cadrage | cycle 07-armer-les-agents / 03-la-direction-artistique | 1 |
| pas-de-cadrage | cycle 07-armer-les-agents / 04-les-documents-fondateurs-a-jour | 1 |

Classification par la règle écrite (`CLASSE-REGLE-ECRITE`) : 200 sur `~/jarvis-keystone` (193 « état dérivé absent : herite », passent ; 7 « état dérivé absent : pas-de-cadrage », comptés dans les 196), 0 sur `~/BusinessFlow-Lab`.

## Écarts

Aucun. Faux refus = 0, faux accept = 0, pour G1, G5 et G6.

Phase dérogée (DEROGATION.md, état dérivé gelé, abandonné ou remplacé) sans CADRAGE.md, écart signalé par l'exécuteur de 45-06 : **0 occurrence** sur les deux labs réels (aucune ligne doit-passer refusée par G1). L'écart reste donc propre au lab synthétique ; le rejeu réel ne le manifeste pas.

Les 42 refus de G1 doit-refuser sur `~/jarvis-keystone` et les 20 sur `~/BusinessFlow-Lab` sont les cas injectés par le rejeu (phases `99-rejeu-*`, registre ouvert ou sans cadrage), tous refusés comme attendu.

## Décision d'armement

Non décidée ici : mesure seule. La condition P45-D-03b de l'étape 2 tient sur la mesure (0/0, empreintes de tout l'arbre identiques, `refus-conforme-modele=196` compté à part), mais l'ordre P45-D-03 interdit d'armer l'étape 2 tant que l'étape 1 n'est pas armée. Le manager armera les étapes en cascade sur ces mesures.
