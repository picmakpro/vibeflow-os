# Relevé du rejeu réel final — étape 4 sur le code livré après les lots D et E (45-D, 45-E)

**Mesure seule — aucun armement, aucune modification de code, de suite, d'attendus, de constante `ARMEMENT_*` ni de `TABLE_ATTENDUE`.**

## En-tête

| Champ | Valeur |
|---|---|
| Date | 2026-10-01 |
| Mission / nœud | `vf-dev-manager-p45-exec`, nœud `rejeu-final-4` (compartiment gouvernance, Phase 45) |
| Code mesuré | HEAD `a2a2a9ff` de la branche `gouvernance/phase-45-execution` (lots D et E livrés : G6 protège aussi `planning-hook.sh` et `check-gates-alive.sh` sous `<lab>/.claude/scripts/` ; un `.planning` sous `.claude` n'est jamais une racine de lab) |
| Outil de rejeu | `plugin/planning-core/scripts/rejeu-reel.sh --etape=4 --attendus=45-REJEU-ATTENDUS.txt` (même commande que `45-REJEU-ETAPE-4.md`, simule les cinq gates armés sur copie) |
| Décisions portées | Rejeux réels en lecture seule, sur copie, empreinte avant/après, aucun geste git dans les labs (Willy, AskUserQuestion session principale, 2026-09-30) ; Q-ARM oui (Willy, AskUserQuestion session principale, 2026-09-30) ; P45-D-21a (classification par le modèle : « refus conforme au modèle, lab non migré » ne compte pas comme faux refus) |
| Condition de l'armement en cascade | 0 faux refus, 0 faux accept ET empreintes de tout l'arbre identiques pour les deux labs |

COMMIT-REJOUE a2a2a9ff2ddfeb15d973e3bb389fae56a1bc0a53

Un seul passage du rejeu réel (code de sortie 0), à charge faible au lancement (`uptime` : 3.7 sur 1 minute). Aucun refus ne porte la marque d'une échéance (aucune occurrence de `Alarm clock` ni du code 73) : aucun second passage n'a été nécessaire.

### Contrôle de repos (lecture seule)

Avant (15:55) et après (15:58), forme anonymisée (sans USER ni PID) :

| Relevé | Avant | Après |
|---|---|---|
| Processus dont le répertoire courant est sous `~/jarvis-keystone` (`lsof -d cwd`) | 0 | 0 |
| Processus dont le répertoire courant est sous `~/BusinessFlow-Lab` (`lsof -d cwd`) | 0 | 0 |
| Fichiers ouverts sous `~/jarvis-keystone/.planning` (`lsof +D`) | 0 | 0 |
| Fichiers ouverts sous `~/BusinessFlow-Lab/.planning` (`lsof +D`) | 0 | 0 |
| Transcript le plus récent, BusinessFlow-Lab | 2026-10-01 09:13 (plus de 6 h) | inchangé |
| Transcript le plus récent, jarvis-keystone | 2026-09-24 21:56 | inchangé |

Aucun lecteur (Preview, QuickLook) n'a été observé. Les quatre processus inactifs de BusinessFlow-Lab de l'étape 4 du matin ont disparu.

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

Le relevé nominatif compte 4404 lignes : 3617 en doit-passer (passage obtenu), 585 en doit-refuser (refus obtenu), 202 en doit-refuser-modele (refus obtenu), aucun écart dans aucun sens. Répartition par gate : G1 451, G5 410, G6 112 (42 à Keystone, 70 à BusinessFlow), G7 30, ROLE 35, 3366 lignes hors gate nommé.

Commande : `bash plugin/planning-core/scripts/rejeu-reel.sh --lab="$HOME/jarvis-keystone" --lab="$HOME/BusinessFlow-Lab" --etape=4 --attendus=.planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-REJEU-ATTENDUS.txt --rapport=<fichier hors des labs>`.

## Écart par rapport à l'étape 4 du 2026-10-01 (`45-REJEU-ETAPE-4.md`)

Aucun écart de compte : mêmes totaux (4404 lignes ; 3617 / 585 / 202), mêmes lignes `COMPTE`, mêmes `CLASSE-REGLE-ECRITE`, mêmes 24 lignes `ROLE-AGENT` (7 à Keystone, 17 à BusinessFlow), mêmes classes de rôle (dont `contracts` illisible, jamais refusé, P45-D-11 ; `plan-reviewer` juge, seule écriture refusée).

**Lignes nouvelles venues des scripts du hook sous G6 : zéro.** Mesure : ni `planning-hook.sh` ni `check-gates-alive.sh` n'existent sous `.claude/scripts/` d'aucun des deux labs (les labs ne sont pas migrés : leurs `.claude/scripts/` ne portent pas ces fichiers), et le relevé ne contient aucune ligne qui les nomme. Le corpus G6 du rejeu est construit à partir de ce qui existe dans les labs ; l'extension de la protection G6 aux scripts du hook (lots D et E) n'a donc aucune cible réelle ici. Elle est prouvée par les suites (45-D, 45-E), pas par ce rejeu. Conséquence : le fichier d'attendus n'a aucune ligne à couvrir pour ces scripts, aucun écart de classification, aucune modification d'attendus.

Le décompte des processus du contrôle de repos diffère de celui du matin (0 contre 4 inactifs à BusinessFlow-Lab) : sans effet sur la mesure.

## ROLE — agent par agent

Identique à l'étape 4 : 24 agents (7 à Keystone, 17 à BusinessFlow), 35 lignes ROLE (24 écritures, 11 dispatchs), 0 faux refus, 0 faux accept. Lignes brutes `ROLE-AGENT` du rejeu :

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

Limites de la mesure inchangées par rapport à l'étape 4 : ligne worker non indépendante sous f9-allowlist (aucun worker réel à la racine des labs), périmètre racine seulement (labs imbriqués non rejoués), agents de plugin non rejoués.

## Écarts

Aucun. Faux refus = 0, faux accept = 0 pour G6, G5, G1, G7 et le rôle ; empreintes de tout l'arbre identiques pour les deux labs ; aucune ligne nouvelle non couverte par les attendus.

## Verdict de seuil — non armé par ce nœud

La condition de l'armement en cascade est tenue sur cette mesure (0 faux refus, 0 faux accept, `EMPREINTE-ARBRE-IDENTIQUE` pour les deux labs). Ce nœud n'arme rien : aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` n'a été touchée, la décision d'armement et son ordre (G6 et G5, G1, G7, puis le rôle) reviennent au manager.
