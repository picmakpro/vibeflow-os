# Relevé du rejeu réel — étape 4 (hook par rôle) — 45-09

**Mesure seule — armement différé, étapes 1 à 3 mesurées à zéro mais non encore armées (P45-D-03).**

## En-tête

| Champ | Valeur |
|---|---|
| Date (UTC) | 2026-10-01 |
| Hook mesuré | `plugin/planning-core/scripts/planning-hook.sh` (les cinq constantes `ARMEMENT_*` valent `observe` dans le code livré, `TABLE_ATTENDUE` inchangée ; aucune constante ni table touchée par ce plan) |
| Outil de rejeu | `plugin/planning-core/scripts/rejeu-reel.sh --etape=4 --attendus=45-REJEU-ATTENDUS.txt` (empreinte de tout l'arbre, extérieure à `rejeu-gates.sh`) ; constructeur `ROLE` commité en `c71d7e4` |
| Décisions portées | F9 = f9-allowlist (Willy, AskUserQuestion session principale, 2026-09-30). Tâche 2 (rejeu réel de l'étape 4) : rejeu-oui (Willy, AskUserQuestion session principale, 2026-09-30). Mise au repos des labs : Willy, AskUserQuestion session principale, 2026-09-30, « ferme les processus et go ». Amendement A1 (manager vf-dev-manager, 2026-09-30) : le rejeu de l'étape 4 est une mesure seule, aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` n'est modifiée |
| Conditions | Labs en lecture seule sur copie, empreinte de tout l'arbre avant et après, aucun geste git dans les labs, chemins affichés `~/…` ; les agents du compte (`~/.claude/agents`) participent à la résolution comme en vraie session (HOME passé au hook) |
| État livré des étapes | Étape 1 (G6, G5) non armée, mesurée (`45-REJEU-ETAPE-1.md`) ; étape 2 (G1) non armée, mesurée (`45-REJEU-ETAPE-2.md`) ; étape 3 (G7) non armée, mesurée (`45-REJEU-ETAPE-3.md`) ; étape 4 (rôle) : cette mesure |
| P45-D-03b | Condition de seuil tenue sur la mesure du rôle (0 faux refus, 0 faux accept, empreintes de tout l'arbre identiques) mais armement interdit par l'ordre P45-D-03 : G7 n'est pas armé dans l'état livré |
| Déclaration de non-indépendance (F9) | sous f9-allowlist, le constructeur ROLE et la politique du hook appliquent le même prédicat de légitimité pour la ligne worker (le dispatch appartient à l'allowlist de l'appelant) ; la mesure n'est donc pas indépendante pour cette ligne — elle prouve la concordance de deux implémentations, pas la légitimité elle-même ; la ligne juge, jugée sur disallowedTools, l'est |

COMMIT-REJOUE c71d7e4fe0ec563bba82149a5f8ae3bfd3d1e1b1

Un seul passage du rejeu réel : l'empreinte de tout l'arbre est identique pour les deux labs, aucun second passage n'a été nécessaire (code de sortie 0).

### Contrôle de repos (lecture seule, `lsof -d cwd`, avant et après le rejeu)

Sortie (chemins affichés `~/…`, anonymisée : sans USER ni PID), identique avant et après :

```
COMMAND               NAME
Code Helper (Plugin)  ~/BusinessFlow-Lab
zsh                   ~/BusinessFlow-Lab
Code Helper (Plugin)  ~/BusinessFlow-Lab
zsh                   ~/BusinessFlow-Lab
```

| Lab | Processus dont le répertoire courant est sous le lab |
|---|---|
| `~/jarvis-keystone` | 0 |
| `~/BusinessFlow-Lab` | 4 : 2 `Code Helper (Plugin)` et 2 `zsh` inactifs, seuls restants annoncés (mêmes processus avant et après) |

## Comptes (lignes brutes du rejeu)

```
COMPTE G6 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G5 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G1 faux-refus=0 faux-accept=0 refus-conforme-modele=196
COMPTE G7 faux-refus=0 faux-accept=0 refus-conforme-modele=6
COMPTE ROLE faux-refus=0 faux-accept=0 refus-conforme-modele=0
REJEU-ETAPE-4 faux-refus=0 faux-accept=0 refus-conforme-modele=202
CLASSE-REGLE-ECRITE G1 lab=~/jarvis-keystone n=200
CLASSE-REGLE-ECRITE G1 lab=~/BusinessFlow-Lab n=0
EMPREINTE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-IDENTIQUE ~/BusinessFlow-Lab
EMPREINTE-ARBRE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-ARBRE-IDENTIQUE ~/BusinessFlow-Lab
```

Le relevé nominatif compte 4404 lignes (non recopié hors du rôle, il se relance par la commande ci-dessous) : 3617 en doit-passer (passage obtenu), 585 en doit-refuser (refus obtenu), 202 en doit-refuser-modele (refus obtenu), aucun écart dans aucun sens. Par rapport à l'étape 3 (4369 lignes : 3583, 584, 202), les 35 lignes en plus sont les lignes ROLE : 34 doit-passer/passe et 1 doit-refuser/refus. Les comptes G6, G5, G1 et G7 sont ceux de l'étape 3, inchangés (le rejeu de l'étape 4 simule les cinq gates armés sur la copie). Aucune commande git n'a été lancée dans les labs ; aucun préfixe de dossier personnel de la machine n'apparaît dans le relevé.

Commande : `bash plugin/planning-core/scripts/rejeu-reel.sh --lab="$HOME/jarvis-keystone" --lab="$HOME/BusinessFlow-Lab" --etape=4 --attendus=.planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-REJEU-ATTENDUS.txt --rapport=<fichier hors des labs>`.

## ROLE — agent par agent

Périmètre du constructeur : les définitions `.claude/agents/*.md` régulières de la RACINE de chaque lab (celle du `.planning/` adhérent de la racine), rôle dérivé par `planning-hook.sh --classer` sur la copie du hook. Écriture rejouée : `rejeu-role/<agent>.md` par l'agent (doit-refuser s'il retire Write ET Edit de ses outils, sinon doit-passer). Dispatchs rejoués : chaque nom de sa propre allowlist `Agent(...)` sous `Agent` (doit-passer) ; pour un worker (`vf-internal: true`), `hors-liste-rejeu` sous `Agent` et sous `Task` (doit-refuser). Aucun `doit-refuser-modele` : les déclarations d'un agent valent pour tout lab.

| Lab | Agent | Rôle dérivé | Lignes rejouées | Attendu/obtenu par ligne | Faux refus | Faux accept |
|---|---|---|---|---|---|---|
| `~/jarvis-keystone` | `data-engineer` | manager | 2 | écriture doit-passer/passe ; dispatchs : Agent Explore doit-passer/passe | 0 | 0 |
| `~/jarvis-keystone` | `plan-manager` | manager | 4 | écriture doit-passer/passe ; dispatchs : Agent data-engineer doit-passer/passe, Agent scrapper doit-passer/passe, Agent vibeflow-conductor doit-passer/passe | 0 | 0 |
| `~/jarvis-keystone` | `plan-reviewer` | juge | 1 | écriture doit-refuser/refus (motif : `plan-reviewer est un juge — toute écriture par outil lui est refusée ; posez un verdict par poser-verdict.sh`) | 0 | 0 |
| `~/jarvis-keystone` | `scrapper` | manager | 2 | écriture doit-passer/passe ; dispatchs : Agent Explore doit-passer/passe | 0 | 0 |
| `~/jarvis-keystone` | `skill-creator` | manager | 3 | écriture doit-passer/passe ; dispatchs : Agent Explore doit-passer/passe, Agent general-purpose doit-passer/passe | 0 | 0 |
| `~/jarvis-keystone` | `vibeflow-conductor` | manager | 4 | écriture doit-passer/passe ; dispatchs : Agent data-engineer doit-passer/passe, Agent skill-creator doit-passer/passe, Agent vibeflow-validator doit-passer/passe | 0 | 0 |
| `~/jarvis-keystone` | `vibeflow-validator` | manager | 2 | écriture doit-passer/passe ; dispatchs : Agent vibeflow-conductor doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `auditor` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `automation-brief-builder` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `content-producer` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `contracts` | illisible (frontmatter absent ou jamais refermé : agent inconnu du hook, jamais refusé, P45-D-11) | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `curriculum-designer` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `delivery` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `education-director` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `finance` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `lawyer` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `reporter` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `sales` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `skill-creator` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `solution-architect` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `strategist` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `vibeflow-conductor` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `vibeflow-kpi-analyst` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |
| `~/BusinessFlow-Lab` | `vibeflow-validator` | producteur | 1 | écriture doit-passer/passe | 0 | 0 |

Totaux : 24 agents (7 à Keystone, 17 à BusinessFlow), 35 lignes ROLE (24 écritures, 11 dispatchs), 0 faux refus, 0 faux accept. Lignes brutes `ROLE-AGENT` du rejeu :

```
ROLE-AGENT lab=~/jarvis-keystone agent=data-engineer role=manager ecriture=doit-passer dispatchs=1
ROLE-AGENT lab=~/jarvis-keystone agent=plan-manager role=manager ecriture=doit-passer dispatchs=3
ROLE-AGENT lab=~/jarvis-keystone agent=plan-reviewer role=juge ecriture=doit-refuser dispatchs=0
ROLE-AGENT lab=~/jarvis-keystone agent=scrapper role=manager ecriture=doit-passer dispatchs=1
ROLE-AGENT lab=~/jarvis-keystone agent=skill-creator role=manager ecriture=doit-passer dispatchs=2
ROLE-AGENT lab=~/jarvis-keystone agent=vibeflow-conductor role=manager ecriture=doit-passer dispatchs=3
ROLE-AGENT lab=~/jarvis-keystone agent=vibeflow-validator role=manager ecriture=doit-passer dispatchs=1
ROLE-AGENT lab=~/BusinessFlow-Lab agent=auditor role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=automation-brief-builder role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=content-producer role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=contracts role=illisible ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=curriculum-designer role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=delivery role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=education-director role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=finance role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=lawyer role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=reporter role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=sales role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=skill-creator role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=solution-architect role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=strategist role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=vibeflow-conductor role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=vibeflow-kpi-analyst role=producteur ecriture=doit-passer dispatchs=0
ROLE-AGENT lab=~/BusinessFlow-Lab agent=vibeflow-validator role=producteur ecriture=doit-passer dispatchs=0
```

### Conséquence de F9 sur les labs réels

Aucun worker (`vf-internal: true`) n'existe à la racine des deux labs : la ligne worker de F9 (f9-allowlist) ne refuse donc rien sur ce périmètre, et la conséquence de F9 est un compte de zéro faux refus. Les onze dispatchs rejoués sont ceux de managers (allowlist non vide, `vf-internal` absent) : la politique du hook ne refuse jamais un manager, ils comptent comme passages attendus. Relevé complémentaire en lecture seule (recherche du motif `vf-internal: true`) : aucune occurrence dans les `.claude/agents/` des racines ni dans ceux des labs imbriqués listés ci-dessous.

### Limites de la mesure

- **Non indépendance de la ligne worker** (déclarée en en-tête) : sous f9-allowlist, constructeur et politique du hook appliquent le même prédicat ; comme aucun worker réel n'existe, cette ligne n'a ici exercé que le corpus synthétique de la suite (`R-REJEU-ROLE`), pas un agent réel.
- **Périmètre racine seulement** : le constructeur rejoue les définitions de la racine de chaque lab (`~/jarvis-keystone/.claude/agents`, `~/BusinessFlow-Lab/.claude/agents`). Les `.claude/agents` des labs imbriqués ne sont pas rejoués (lecture seule, recensement : `~/jarvis-keystone/10-pilotage`, `20-ateliers/01-marche-offre`, `20-ateliers/_gabarit`, `30-captation` ; `~/BusinessFlow-Lab/projects/formation/projetflow-staging/` : `ProjetFlow`, `ProjetFlow-A2-POLLUE`, `ProjetFlow-A2-PROPRE`, `ProjetFlow-FROZEN-A3`, `ProjetFlow-FROZEN-L10`, `ProjetFlow-FROZEN-L75`, `ProjetFlow-LAB-GENERE-A3`, `lab-genere-A3`, plus deux exemples de référence `PetitsCoursFlow` et un cache obsolète) : l'écriture et les dispatchs d'un agent d'un lab imbriqué, vus depuis sa propre racine, ne sont pas mesurés ici.
- **Agents du compte** : ils participent à la résolution (HOME réel) mais ne sont pas des agents rejoués ; le niveau « lab » l'emporte sur le niveau « compte » pour un nom commun (`vibeflow-conductor`, `vibeflow-validator`, `skill-creator` existent dans les deux labs).
- **Agents de plugin** (`<plugin>:<agent>`) : non rejoués.

## Écarts

Aucun. Faux refus = 0, faux accept = 0, pour G6, G5, G1, G7 et le rôle.

## Non armé — remonté à Willy

Le rôle reste en `observe` : `ARMEMENT_ROLE = "observe"`, `TABLE_ATTENDUE` inchangée, aucun commit d'armement.

- **Motif : armement différé, G7 non armé, P45-D-03.** L'ordre d'armement est fixe (G6 et G5, puis G1, puis G7, puis le rôle) et le rôle ne s'arme jamais avant G7 (`armement_valide`) ; G7 n'est pas armé dans l'état livré, pas plus que les étapes 1 et 2. Ce relevé est une mesure seule (amendement A1, manager vf-dev-manager, 2026-09-30).
- **Condition P45-D-03b de l'étape 4 : tenue sur la mesure** — 0 faux refus, 0 faux accept (`COMPTE ROLE faux-refus=0 faux-accept=0 refus-conforme-modele=0`), banc de la suite des gates à zéro (`COMPTE ROLE faux-refus=0 faux-accept=0`), canary du rôle sain sous `Agent` et sous `Task` (45-09, Tâche 1), empreinte de tout l'arbre identique pour les deux labs, une ligne `EMPREINTE-ARBRE-IDENTIQUE` par lab. Aucune ligne non nulle à remonter ni `ESCALADE-WILLY` à émettre : le manager armera les étapes en cascade (G6 et G5, G1, G7, puis le rôle) sur ces mesures, avec un commit d'armement dans l'ordre.

> Note du 2026-10-01 (quick 45-B, B2 ; décisions du manager vf-dev-manager, 2026-10-01) : les identifiants de processus et le nom du compte local qui figuraient dans les sorties `lsof` de ce relevé ont été retirés (forme anonymisée : COMMAND et NAME en `~/…`, sans USER ni PID) ; le décompte des processus et les conclusions sont inchangés.
