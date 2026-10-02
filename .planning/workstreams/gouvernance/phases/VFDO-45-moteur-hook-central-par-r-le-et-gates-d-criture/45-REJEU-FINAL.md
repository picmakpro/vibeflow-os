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

## Rejeu post-audit (2026-10-01)

**Mesure seule — aucun armement, aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` touchée.** Le code du hook a changé après le rejeu réel final (`708debcb`) : la correction ciblée de l'audit de sécurité final (F-01 borne de la couche shell de repli, F-02 motif d'adhésion partagé entre G6 et le repli, F-03 minuteur désarmé après la décision ; quick 261001-urj) a modifié `hooks.json`, `planning-hook.sh` et la copie de référence du canary. Ce rejeu mesure donc le code corrigé.

| Champ | Valeur |
|---|---|
| Date | 2026-10-01 |
| Code mesuré | HEAD `0f8f2946` de la branche `gouvernance/phase-45-execution` |
| Commande | celle du rejeu final ci-dessus (`rejeu-reel.sh` sur les deux labs, `--etape=4`, mêmes attendus) |
| Autorisation | rejeu réel en lecture seule (Willy, AskUserQuestion session principale, 2026-09-30, reprise dans le mandat du 2026-10-01) |
| Passages | un seul, code de sortie 0 ; charge machine élevée (suites de la correction rejouées juste avant), sans effet sur la mesure |

### Contrôle de repos (lecture seule), forme anonymisée (sans USER ni PID)

Avant (22:42) et après (22:47) :

| Relevé | Avant | Après |
|---|---|---|
| Processus dont le répertoire courant est sous `~/jarvis-keystone` ou `~/BusinessFlow-Lab` (`lsof -d cwd`) | 0 | 0 |
| Fichiers ouverts sous `~/jarvis-keystone/.planning` (`lsof +D`) | 0 | 0 |
| Fichiers ouverts sous `~/BusinessFlow-Lab/.planning` (`lsof +D`) | 0 | 0 |
| Transcript le plus récent, BusinessFlow-Lab | 2026-10-01 20:05 (plus de 2 h 30) | inchangé |
| Transcript le plus récent, jarvis-keystone | 2026-09-24 21:56 | inchangé |

### Comptes (lignes brutes du rejeu)

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

Le relevé nominatif compte 4404 lignes : 3617 en doit-passer (passage obtenu), 585 en doit-refuser (refus obtenu), 202 en doit-refuser-modele (refus obtenu), aucun écart dans aucun sens. Les 24 lignes `ROLE-AGENT` sont identiques à celles du rejeu final. Aucune occurrence de `Alarm clock` ni de « hook central indisponible » dans la sortie ni dans le relevé.

### Écarts

Aucun : mêmes totaux que le rejeu final (4404 lignes ; 3617 / 585 / 202), 0 faux refus, 0 faux accept, empreintes de tout l'arbre identiques pour les deux labs.

### Mesure des `config.json` réels pour F-02 (lecture seule)

Les `config.json` racine des deux labs, et ceux des quatre compartiments de `jarvis-keystone`, portent `"planning_version": "2.0"` (non adhérents : G6 ne s'y applique pas). Leur transposition à `cycles-v1` à mise en forme identique (une clé par ligne) est admise par G6 corrigé (la clé et la valeur tiennent sur une ligne, le motif du repli la reconnaît) : aucun faux refus attendu à la migration.

## Rejeu post-re-audit (2026-10-02)

**Mesure seule — aucun armement, aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` touchée.** Le code du hook a changé après le rejeu post-audit (`0f8f2946`) : la correction ciblée du re-audit (N-01 chemin inanalysable et borne longue du repli, N-03 chemin `~` développé en HOME, N-05 raison de G6 sur la mise en forme du repli, N-04 texte de `poser-verdict.sh` ; quick 261001-wtd) a modifié `hooks.json`, `planning-hook.sh`, `check-gates-alive.sh` et `poser-verdict.sh`. Ce rejeu mesure donc le code corrigé.

| Champ | Valeur |
|---|---|
| Date | 2026-10-02 |
| Code mesuré | HEAD `a4afbe3f` de la branche `gouvernance/phase-45-execution` |
| Commande | celle du rejeu final ci-dessus (`rejeu-reel.sh` sur les deux labs, `--etape=4`, mêmes attendus) |
| Autorisation | rejeu réel en lecture seule (Willy, AskUserQuestion session principale, 2026-09-30, reprise dans le mandat du 2026-10-01) |
| Passages | un seul ; aucune occurrence de `Alarm clock` ni de « hook central indisponible » dans le relevé |

### Contrôle de repos (lecture seule), forme anonymisée (sans USER ni PID)

Avant (00:10) et après (00:16) :

| Relevé | Avant | Après |
|---|---|---|
| Processus dont le répertoire courant est sous `~/jarvis-keystone` ou `~/BusinessFlow-Lab` (`lsof -d cwd`) | 0 | 0 |
| Fichiers ouverts sous `~/jarvis-keystone/.planning` (`lsof +D`) | 0 | 0 |
| Fichiers ouverts sous `~/BusinessFlow-Lab/.planning` (`lsof +D`) | 0 | 0 |
| Transcripts modifiés depuis moins de 30 minutes (les deux dossiers de projet) | 0 | 0 |
| Transcript le plus récent, BusinessFlow-Lab | 2026-10-01 20:05 (plus de 4 h) | inchangé |
| Transcript le plus récent, jarvis-keystone | 2026-09-24 21:56 | inchangé |

### Comptes (lignes brutes du rejeu)

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

### Écarts

Aucun : mêmes totaux que le rejeu post-audit (0 faux refus, 0 faux accept, 202 refus conformes au modèle), empreintes de tout l'arbre identiques pour les deux labs. Les refus de G6 sur `config.json` portent toujours leur raison d'origine pour les écritures qui retirent réellement l'adhésion ; la nouvelle raison (mise en forme du repli) ne concerne que les contenus qui déclarent `cycles-v1` hors de la forme reconnue par le repli.

## Rejeu post-re-audit 2 (2026-10-02)

**Mesure seule — aucun armement, aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` touchée.** Le code du hook a changé après le rejeu post-re-audit (`a4afbe3f`) : la correction de classe du re-audit 2 (N2-01 : valeur longue que le hook ne sait pas analyser, repli et cœur ; quick 261002-1dv) a modifié `hooks.json`, `planning-hook.sh` et `check-gates-alive.sh`. Ce rejeu mesure donc le code corrigé.

| Champ | Valeur |
|---|---|
| Date | 2026-10-02 |
| Code mesuré | commit `19d9c32d` de la branche `gouvernance/phase-45-execution` |
| Commande | celle du rejeu final ci-dessus (`rejeu-reel.sh` sur les deux labs, `--etape=4`, mêmes attendus) |
| Autorisation | rejeu réel en lecture seule (Willy, AskUserQuestion session principale, 2026-09-30, reprise dans le mandat du 2026-10-02) |
| Passages | un seul ; aucune occurrence de `Alarm clock` ni de « hook central indisponible » dans le relevé |

### Contrôle de repos (lecture seule), forme anonymisée (sans USER ni PID)

Avant (juste avant le rejeu) et après (01:37) :

| Relevé | Avant | Après |
|---|---|---|
| Processus dont le répertoire courant est sous `~/jarvis-keystone` ou `~/BusinessFlow-Lab` (`lsof -d cwd`) | 0 | 0 |
| Fichiers ouverts sous `~/jarvis-keystone/.planning` (`lsof +D`) | 0 | 0 |
| Fichiers ouverts sous `~/BusinessFlow-Lab/.planning` (`lsof +D`) | 0 | 0 |
| Transcripts modifiés depuis moins de 30 minutes (les deux dossiers de projet) | 0 | 0 |

### Comptes (lignes brutes du rejeu)

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

### Écarts

Aucun : mêmes totaux que le rejeu post-re-audit (0 faux refus, 0 faux accept, 202 refus conformes au modèle), empreintes de tout l'arbre identiques pour les deux labs.

## Rejeu post-re-audit 3 (2026-10-02)

**Mesure seule — aucun armement, aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` touchée.** Le code du hook a changé après le rejeu post-re-audit 2 : la correction du re-audit 3 (N3-01 : une valeur de plus de 4096 caractères est lue sous deux formes en temps linéaire et analysée comme une valeur courte ; N3-02 : un chemin relatif sous un `cwd` long passe par la décision dans le doute ; quick 261002-3rx) a modifié `planning-hook.sh`. Ce rejeu mesure donc le code corrigé.

| Champ | Valeur |
|---|---|
| Date | 2026-10-02 |
| Code mesuré | commit `1d9425f7` de la branche `gouvernance/phase-45-execution` |
| Commande | celle du rejeu final ci-dessus (`rejeu-reel.sh` sur les deux labs, `--etape=4`, mêmes attendus, rapport hors des labs) |
| Autorisation | rejeu réel en lecture seule (Willy, AskUserQuestion session principale, 2026-09-30, reprise dans le mandat du 2026-10-02) |
| Passages | un seul (code de sortie 0) ; aucune occurrence de `Alarm clock` ni de « hook central indisponible » dans la sortie ni dans le relevé nominatif ; charge machine élevée au lancement (`uptime` : 4,40 sur 1 minute, 10,08 sur 5), sans effet sur le résultat |

### Contrôle de repos (lecture seule), forme anonymisée (sans USER ni PID)

Avant (04:06) et après (04:09) :

| Relevé | Avant | Après |
|---|---|---|
| Processus dont le répertoire courant est sous `~/jarvis-keystone` ou `~/BusinessFlow-Lab` (`lsof -d cwd`) | 0 | 0 |
| Fichiers ouverts sous `~/jarvis-keystone/.planning` (`lsof +D`) | 0 | 0 |
| Fichiers ouverts sous `~/BusinessFlow-Lab/.planning` (`lsof +D`) | 0 | 0 |
| Transcripts modifiés depuis moins de 30 minutes (les deux dossiers de projet) | 0 | 0 |

### Comptes (lignes brutes du rejeu)

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

Le relevé nominatif (rapport écrit hors des labs) compte 4440 lignes, dont 4428 lignes de verdict : 3640 en doit-passer, 586 en doit-refuser et 202 en doit-refuser-modele, toutes obtenues conformes à l'attendu (faux refus 0, faux accept 0). Il est plus long que celui du 2026-10-01 (4404 lignes : 3617, 585, 202) parce que les labs réels ont évolué depuis, pas parce que le hook rend autre chose : les lignes `COMPTE` sont identiques.

### Écarts

Aucun : mêmes lignes `COMPTE` que le rejeu post-re-audit 2 (0 faux refus, 0 faux accept, 202 refus conformes au modèle), empreintes de tout l'arbre identiques pour les deux labs. Les chemins du rejeu sont courts (aucune valeur de plus de 4096 caractères) : ce rejeu confirme l'absence de régression sur les valeurs courtes, que le différentiel à trois versions de la quick 261002-3rx établit aussi (2 128 cas courts sans écart, `court-different=0` sur 552 cas courts supplémentaires).

## Rejeu post-pré-filtre (2026-10-02)

**Mesure seule — aucun armement, aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` touchée.** Le code a changé après le rejeu post-re-audit 3 : le pré-filtre hors adhésion a été corrigé (parcours borné, coût cubique et bande 4083-4096 ; quick 261002-uhn, re-audit du pré-filtre). Ce rejeu mesure le code à ce commit.

**Portée de la preuve.** Le rejeu juge le cœur sur copie de labs non migrés : le pré-filtre de la commande enregistrée est prouvé par `test-planning-prefilter.sh`, pas par ce rejeu.

| Champ | Valeur |
|---|---|
| Date | 2026-10-02 |
| Code mesuré | commit `5d6ba02c` de la branche `gouvernance/phase-45-execution` |
| Commande | celle du rejeu final ci-dessus (`rejeu-reel.sh` sur les deux labs, `--etape=4`, mêmes attendus, rapport hors des labs) |
| Autorisation | rejeu réel en lecture seule (Willy, AskUserQuestion session principale, 2026-09-30, reprise dans le mandat du 2026-10-02) |
| Passages | deux, sans échéance : le premier n'a pas écrit son rapport (dossier de destination absent, code de sortie 1, aucun relevé exploitable) ; le second est complet et fait foi. Aucune occurrence de `Alarm clock` ni de « hook central indisponible ». Charge machine au lancement du second : 7,64 sur 1 minute, 7,01 sur 5 |

### Contrôle de repos (lecture seule), forme anonymisée (sans USER ni PID)

Avant (23:46) et après (23:54) :

| Relevé | Avant | Après |
|---|---|---|
| Processus `claude` ou `node` dont le répertoire courant est sous `~/jarvis-keystone` ou `~/BusinessFlow-Lab` (`lsof -d cwd`) | 0 | 0 |
| Autres processus dont le répertoire courant est sous un lab | 1 (shell `zsh` inactif, ne bloque pas) | non relevé |
| Fichiers ouverts sous `~/jarvis-keystone/.planning` (`lsof +D`) | 0 | 0 |
| Fichiers ouverts sous `~/BusinessFlow-Lab/.planning` (`lsof +D`) | 0 | 0 |
| Transcripts de lab modifiés depuis moins de 30 minutes | 0 (le plus récent date de plus de 3 heures) | 0 |

### Comptes (lignes brutes du rejeu)

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

Le relevé nominatif (rapport écrit hors des labs) compte 4440 lignes, comme celui du rejeu post-re-audit 3.

### Écarts

Aucun : mêmes lignes `COMPTE` que le rejeu post-re-audit 3 (0 faux refus, 0 faux accept, 202 refus conformes au modèle), empreintes de tout l'arbre identiques pour les deux labs.
