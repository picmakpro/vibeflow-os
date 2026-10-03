# Relevé du rejeu réel — étape 1 (G6 et G5) — 45-05

## En-tête

| Champ | Valeur |
|---|---|
| Date (UTC) | 2026-09-30 |
| Hook mesuré | `plugin/planning-core/scripts/planning-hook.sh` au commit `186daa3` (G6 et G5 encore en observation dans le code livré) |
| Outil de rejeu | `plugin/planning-core/scripts/rejeu-reel.sh` (empreinte de tout l'arbre, extérieure à `rejeu-gates.sh`) puis `rejeu-gates.sh --etape=1`, constructeurs G6 et G5 du commit `186daa3` |
| Réponse de la Tâche 2 (relayée, non tranchée par l'exécuteur) | F6 = f6-oui (config.json : l'adhésion `planning_version` est protégée par G6) ; F7b = f7b-oui (`.recalc-cache.json` protégé par G6) ; rejeu réel de l'étape 1 autorisé en lecture seule sur copie (rejeu-oui). Canal : Willy, AskUserQuestion session principale, 2026-09-30 |
| Règle d'armement (P45-D-03b, verrouillée) | G6 et G5 passent ensemble à `armed` SEULEMENT si le banc ET le rejeu réel rendent faux-refus=0 et faux-accept=0, et si l'empreinte de tout l'arbre de chaque lab réel est identique avant et après. Le compte `refus-conforme-modele` (P45-D-21a) est compté à part. Aucun seuil de tolérance n'est décidé en mission |

## Statut du rejeu réel : NON EFFECTUÉ (précondition non tenue)

Précondition du plan 45-05 (Tâche 3) : les deux labs existent ET sont au repos (aucune session ouverte sur `~/jarvis-keystone` ni sur `~/BusinessFlow-Lab`). Un lab sous session ouverte écrit pendant la mesure : l'empreinte de tout l'arbre divergerait pour une raison étrangère au rejeu, et la mesure ne prouverait plus rien.

Contrôle, lecture seule (`lsof -d cwd`, répertoire courant des processus), fait trois fois au fil de l'exécution du plan (première lecture avant le commit de code de la Tâche 3, dernière lecture : 2026-09-30T19:38Z), même résultat à chaque fois :

| Lab | Dossier de planning | Processus dont le répertoire courant est sous le lab |
|---|---|---|
| `~/jarvis-keystone` | présent | 0 |
| `~/BusinessFlow-Lab` | présent | 26 : 12 `node`, 5 `zsh`, 2 `uv`, 2 `python3.11`, 2 `Code Helper (Plugin)`, 1 `sleep`, 2 sessions Claude Code (2.1.284 et 2.1.283) |

Conséquences, telles que le plan les fixe :

- aucun rejeu réel n'a été lancé, sur aucun des deux labs (le plan exige les deux, au repos) ;
- aucune empreinte de l'arbre n'a été prise : il n'existe donc ni ligne de comptes `REJEU-ETAPE-1`, ni ligne d'empreinte d'arbre, identique ou divergente ;
- aucun armement : `ARMEMENT_G6` et `ARMEMENT_G5` restent `"observe"`, `TABLE_ATTENDUE` de la suite reste inchangée ;
- les deux labs n'ont pas été lus, hors l'existence de leur dossier de planning et les répertoires courants des processus ; aucune commande git n'a été lancée dans l'un ni l'autre.

## Ce qui est mesuré, en CI (banc synthétique, copie armée)

| Mesure | Résultat |
|---|---|
| `COMPTE G5` du banc complet (R-ID-06) | faux-refus=0 faux-accept=0 |
| `COMPTE G6` du banc complet (R-ID-06) | faux-refus=0 faux-accept=0 |
| Rejeu de l'étape 1 avec le vrai hook sur deux labs synthétiques (R-REJEU-G6G5) | faux-refus=0 faux-accept=0, une ligne par clé distincte |
| Canary de session (R-CANG-01 à 03) | vert en observation comme armé ; un gate neutralisé fait signaler le canary |

Le banc est nul dans les deux sens. La moitié « labs réels » de la règle d'armement reste à faire.

## Non armé — remonté à Willy

Aucune ligne non nulle à remonter (aucune mesure réelle n'a eu lieu). Motif unique du non-armement :

| Chemin | Gate | Raison |
|---|---|---|
| `~/BusinessFlow-Lab` | G6 et G5 (étape 1, un seul geste) | labs réels non au repos : 26 processus (dont deux sessions Claude Code 2.1.284 et 2.1.283 et des aides VS Code) ont leur répertoire courant sous le lab ; un rejeu sous session ouverte ne prouve pas l'absence d'écriture |
| `~/jarvis-keystone` | G6 et G5 (étape 1) | aucun obstacle propre (0 processus) ; non rejoué parce que le plan exige les deux labs au repos pour une mesure unique |

Pour lever : fermer les sessions ouvertes sur `~/BusinessFlow-Lab` (ou décider autrement, par un arbitrage explicite), puis relancer, depuis la racine du dépôt, `bash plugin/planning-core/scripts/rejeu-reel.sh --lab="$HOME/jarvis-keystone" --lab="$HOME/BusinessFlow-Lab" --etape=1 --rapport=<ce fichier>`. Si l'empreinte de l'arbre diverge, rejouer UNE fois au repos avant toute escalade ; jamais d'armement sur une divergence.

ESCALADE-WILLY ETAPE-1 labs réels non au repos

## Rejeu réel du 2026-09-30 (reprise)

Reprise du rejeu après mise au repos des labs. Canal des décisions : mise au repos ordonnée par Willy, AskUserQuestion session principale, 2026-09-30 (« ferme les processus et go ») ; autorisation du rejeu réel, F6 = f6-oui, F7b = f7b-oui, rejeu-oui : Willy, AskUserQuestion session principale, 2026-09-30. Hook rejoué : `planning-hook.sh` au commit `8da8c6e` (G6 et G5 encore en observation dans le code). Les lignes de la section précédente (« NON EFFECTUÉ ») restent vraies pour leur date ; celle-ci les remplace pour la décision d'armement.

### Contrôle de repos (lecture seule, `lsof -d cwd`, juste avant le rejeu)

| Lab | Processus dont le répertoire courant est sous le lab |
|---|---|
| `~/jarvis-keystone` | 0 |
| `~/BusinessFlow-Lab` | 4 : 2 `Code Helper (Plugin)` et 2 `zsh` inactifs, seuls restants annoncés, n'écrivant pas dans le lab |

### Comptes (lignes brutes du rejeu)

```
COMPTE G6 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G5 faux-refus=0 faux-accept=0 refus-conforme-modele=0
REJEU-ETAPE-1 faux-refus=0 faux-accept=0 refus-conforme-modele=0
EMPREINTE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-IDENTIQUE ~/BusinessFlow-Lab
EMPREINTE-ARBRE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-ARBRE-IDENTIQUE ~/BusinessFlow-Lab
```

Le relevé nominatif du rejeu compte 4284 lignes : 506 en doit-refuser (refus obtenu) et 3771 en doit-passer (passage obtenu), aucun écart ; il n'est pas recopié ici, il se relance par la commande ci-dessus. Aucune commande git n'a été lancée dans les labs ; aucun chemin de machine n'apparaît dans le rapport (vérifié : aucun préfixe de dossier personnel de la machine).

### Décision d'armement (P45-D-03b, mécanique)

Les trois conditions tiennent : une ligne `EMPREINTE-ARBRE-IDENTIQUE` par lab, aucune divergence, `faux-refus=0 faux-accept=0`. Le banc de la suite des gates (R-ID-06) rend aussi 0/0.

Non armé dans le code à ce stade, pour une raison d'outillage et non de mesure : passer `ARMEMENT_G6` et `ARMEMENT_G5` à `armed` (et `TABLE_ATTENDUE`) rend rouges deux suites qui supposent ces constantes à `observe` — `test-planning-gates.sh` (R-ENV-01 : la copie à l'armement forcé réécrit cinq constantes, n'en trouve plus que trois ; R-TABLE-03 : la table incohérente « G1 armé sans G6 ni G5 » devient cohérente) et `test-planning-hook-installed.sh` (motif `ARMEMENT_G6 = "observe"` introuvable dans la copie). Corriger ces suites est une modification de test que le classifieur du harnais a refusée ; elle est remontée à Willy plutôt que contournée. Constantes restées à `"observe"`, aucun commit d'armement.

ESCALADE-WILLY ETAPE-1 suites couplées à l'état observe

> Note du 2026-10-01 (quick 45-B, B2 ; décisions du manager vf-dev-manager, 2026-10-01) : les identifiants de processus et le nom du compte local qui figuraient dans les sorties `lsof` de ce relevé ont été retirés (forme anonymisée : COMMAND et NAME en `~/…`, sans USER ni PID) ; le décompte des processus et les conclusions sont inchangés.
