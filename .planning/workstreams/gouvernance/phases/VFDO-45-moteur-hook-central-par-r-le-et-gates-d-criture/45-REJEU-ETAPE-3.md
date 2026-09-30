# Relevé du rejeu réel — étape 3 (G7) — 45-07

**Mesure seule — armement différé : étape 1 non encore armée, P45-D-03.**

## En-tête

| Champ | Valeur |
|---|---|
| Date (UTC) | 2026-10-01 |
| Hook mesuré | `plugin/planning-core/scripts/planning-hook.sh` (G7 en observation dans le code livré ; aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` touchée) |
| Outil de rejeu | `plugin/planning-core/scripts/rejeu-reel.sh --etape=3 --attendus=45-REJEU-ATTENDUS.txt` (empreinte de tout l'arbre, extérieure à `rejeu-gates.sh`) |
| Décisions portées | F4 = f4-litteral : prédicat « habité » littéral de P45-D-14 (au moins un agent ET au moins une mémoire non vide), table D-05 amendée (P45-D-14a, Willy, AskUserQuestion session principale, 2026-09-29). Rejeu réel autorisé, modèle de référence sur lab non migré : P45-D-21 et P45-D-21a (même canal, même date). Mise au repos des labs : Willy, AskUserQuestion session principale, 2026-09-30, « ferme les processus et go » |
| Conditions | Labs en lecture seule sur copie, empreinte de tout l'arbre avant et après, aucun geste git dans les labs, chemins affichés `~/…` |
| État livré des étapes | Étape 1 non armée ; étape 2 mesurée (`45-REJEU-ETAPE-2.md`), non armée ; étape 3 : G7 en observation |
| P45-D-03b | Condition de seuil tenue sur la mesure (0 faux refus, 0 faux accept, empreintes identiques) mais armement interdit par l'ordre P45-D-03 tant que l'étape 1 n'est pas armée |

COMMIT-REJOUE dd86b2646887e11649599cceb286dc9e62e167f3

Un premier passage sans `--attendus` a servi à lister les `.planning/` imbriqués réels (14 dossiers) : sans attendus, les six dossiers refusés par le prédicat ressortaient en faux refus, ce qui a confirmé la liste de la table D-05 amendée sans `.planning/` imbriqué inattendu. Aucune divergence d'empreinte sur aucun des deux passages.

### Contrôle de repos (lecture seule, `lsof -d cwd`, avant et après le rejeu)

| Lab | Processus dont le répertoire courant est sous le lab |
|---|---|
| `~/jarvis-keystone` | 0 |
| `~/BusinessFlow-Lab` | 4 : 2 `Code Helper (Plugin)` (PID 4670, 5146) et 2 `zsh` inactifs (PID 5119, 65656), seuls restants annoncés (mêmes processus avant et après) |

## Comptes (lignes brutes du rejeu)

```
COMPTE G6 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G5 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G1 faux-refus=0 faux-accept=0 refus-conforme-modele=196
COMPTE G7 faux-refus=0 faux-accept=0 refus-conforme-modele=6
REJEU-ETAPE-3 faux-refus=0 faux-accept=0 refus-conforme-modele=202
CLASSE-REGLE-ECRITE G1 lab=~/jarvis-keystone n=200
CLASSE-REGLE-ECRITE G1 lab=~/BusinessFlow-Lab n=0
EMPREINTE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-IDENTIQUE ~/BusinessFlow-Lab
EMPREINTE-ARBRE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-ARBRE-IDENTIQUE ~/BusinessFlow-Lab
```

Le relevé nominatif compte 4369 lignes (non recopié, il se relance par la commande de l'en-tête) : 3583 en doit-passer (passage obtenu), 584 en doit-refuser (refus obtenu), 202 en doit-refuser-modele (refus obtenu), aucun écart dans aucun sens. Aucune commande git n'a été lancée dans les labs ; aucun préfixe de dossier personnel de la machine n'apparaît dans le relevé.

## G7 — lab par lab

Prédicat mesuré en lecture seule avant le rejeu : agents = fichiers `.claude/agents/*.md`, mémoire = fichiers réguliers sous `.claude/memory/`.

| Lab | X (dossier du `.planning/`) | Attendu D-05 amendé | Obtenu | Agents | Mémoire |
|---|---|---|---|---|---|
| `~/jarvis-keystone` | `10-pilotage` | doit-passer | passe | 4 | 9 |
| `~/jarvis-keystone` | `20-ateliers/01-marche-offre` | doit-passer | passe | 17 | 120 |
| `~/jarvis-keystone` | `20-ateliers/_gabarit` | doit-passer | passe | 1 | 1 |
| `~/jarvis-keystone` | `30-captation` | doit-passer | passe | 1 | 9 |
| `~/jarvis-keystone` | `00-doctrine` | doit-refuser-modele | refus | 0 | 0 |
| `~/BusinessFlow-Lab` | `projects/avma` | doit-refuser-modele | refus | 0 | 0 |
| `~/BusinessFlow-Lab` | `projects/dmflow` | doit-refuser-modele | refus | 0 | 0 |
| `~/BusinessFlow-Lab` | `projects/lead-recovery` | doit-refuser-modele | refus | 0 | 0 |
| `~/BusinessFlow-Lab` | `projects/formation` | doit-refuser-modele | refus | 0 | 0 |
| `~/BusinessFlow-Lab` | `projects/formation/projetflow-staging/ProjetFlow-FROZEN-A1` | doit-refuser-modele | refus | 0 | 5 |
| `~/BusinessFlow-Lab` | `projects/formation/projetflow-staging/ProjetFlow-A2-POLLUE` | doit-passer (défaut) | passe | 1 | 5 |
| `~/BusinessFlow-Lab` | `projects/formation/projetflow-staging/ProjetFlow-A2-PROPRE` | doit-passer (défaut) | passe | 1 | 5 |
| `~/BusinessFlow-Lab` | `projects/formation/projetflow-staging/ProjetFlow-FROZEN-A3` | doit-passer (défaut) | passe | 1 | 5 |
| `~/BusinessFlow-Lab` | `projects/formation/projetflow-staging/ProjetFlow-LAB-GENERE-A3` | doit-passer (défaut) | passe | 2 | 5 |

Racines : `~/jarvis-keystone` (7 agents, 10 mémoires) et `~/BusinessFlow-Lab` (17 agents, 63 mémoires) sont habitées, doit-passer par construction (la racine n'est pas un `.planning/` imbriqué). Les 16 créations injectées sous un dossier synthétique vide `rejeu-orphelin-g7/` (une par racine ou par planning imbriqué adhérent) sont toutes refusées comme attendu (doit-refuser, refus obtenu).

## Refus conformes au modèle, lab non migré

202 refus conformes au modèle (P45-D-21a), ni faux refus ni faux accepts : 196 pour G1 (inchangés depuis l'étape 2, tous sur `~/jarvis-keystone`, plans écrits sous l'ancienne discipline) et 6 pour G7 ci-dessous.

| Lab | Gate | Motif | n |
|---|---|---|---|
| `~/jarvis-keystone` | G7 | non-lab, table D-05 amendée (P45-D-14a) : `00-doctrine`, `.claude/` sans agent ni mémoire non vide (`agent-memory/` seul, sans fichier, re-mesuré le 2026-10-01) | 1 |
| `~/BusinessFlow-Lab` | G7 | orphelin D-05 : `avma`, `dmflow`, `lead-recovery`, `formation` | 4 |
| `~/BusinessFlow-Lab` | G7 | mémoire sans agent (P45-D-14) — lecture du manager, 2026-09-29 (P45-D-14a) : `ProjetFlow-FROZEN-A1` | 1 |
| `~/jarvis-keystone` | G1 | refus conforme au modèle, lab non migré (détail : `45-REJEU-ETAPE-2.md`) | 196 |
| `~/BusinessFlow-Lab` | G1 | (aucun) | 0 |

Par lab pour G7 : `~/jarvis-keystone` 1, `~/BusinessFlow-Lab` 5.

## Écarts

Aucun. Faux refus = 0, faux accept = 0, pour G1, G5, G6 et G7.

Re-mesure demandée par l'exécuteur de 45-07, en lecture seule, le 2026-10-01 : le `.claude/` de `00-doctrine` ne contient qu'un dossier `agent-memory/` (sous-dossier `vibeflow-conductor`) sans aucun fichier régulier, 0 agent et 0 mémoire. La mesure du 2026-09-29 sur laquelle s'appuie la spec tient.

Aucun `.planning/` imbriqué réel absent de la table D-05 amendée, hors les quatre autres `ProjetFlow-*`, habités (agent ET mémoire), restés doit-passer par défaut et passés.

## Décision d'armement

Non décidée ici : mesure seule. La condition P45-D-03b de l'étape 3 tient sur la mesure (0/0, empreintes de tout l'arbre identiques, `refus-conforme-modele=202` compté à part), mais l'ordre P45-D-03 interdit d'armer l'étape 3 tant que l'étape 1 n'est pas armée. Le manager armera les étapes en cascade sur ces mesures.
