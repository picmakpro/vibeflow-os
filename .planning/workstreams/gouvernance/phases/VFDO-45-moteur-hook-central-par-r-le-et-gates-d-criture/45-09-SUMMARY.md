---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 09
subsystem: planning-core (canary de session du rôle et couverture minimale, constructeur ROLE du rejeu, rejeu réel de l'étape 4 en mesure seule)
tags: [canary, couverture-minimale, role, rejeu, f9-allowlist, mesure-seule, armement-differe, empreinte, mutation-testing]

requires:
  - phase: 45-08
    provides: evaluer_role (ligne juge, ligne worker en f9-allowlist), mode --classer, contrôle croisé avec check-agents.sh
  - phase: 45-07
    provides: G7, le banc, le rejeu de l'étape 3 (45-REJEU-ETAPE-3.md)
  - phase: 45-03
    provides: check-gates-alive.sh (CANARIS, lab synthétique), rejeu-gates.sh (CONSTRUCTEURS), rejeu-reel.sh (empreinte de tout l'arbre)
provides:
  - "check-gates-alive.sh : trois cas ROLE (ROLE-juge, ROLE-worker-Agent, ROLE-worker-Task) sur deux définitions d'agents posées par le canary dans son lab synthétique (canary-juge, canary-worker), COUVERTURE_MINIMALE (P45-D-20), étiquette de couverture par cas vérifiée contre son mode et son payload, option --couverture (code 3 si tout est couvert, 0 avec une ligne de signal sinon), couverture incomplète signalée aussi en session et sous --hook"
  - "rejeu-gates.sh : constructeur ROLE (écriture d'un livrable neutre par chaque agent de la racine d'un lab adhérent, dispatchs de sa propre allowlist, dispatch hors liste d'un worker sous Agent et sous Task), lignes ROLE-AGENT (rôle dérivé par agent) au relevé"
  - "test-planning-gates.sh : R-CANG-ROLE, R-CANG-ROLE-MORT, R-CANG-COUVERTURE, MUT-CANG-TASK, MUT-CANG-COUVERTURE (338 OK) ; test-rejeu-gates.sh : R-REJEU-ROLE, MUT-REJEU-ROLE-LEGITIME, R-REJEU-STATIQUE à quatre appels (55 OK)"
  - "45-REJEU-ETAPE-4.md : relevé du rejeu réel, 24 agents réels, COMPTE ROLE 0/0, REJEU-ETAPE-4 0/0/202, empreinte de tout l'arbre identique, section « Non armé — remonté à Willy » (armement différé)"
affects: [45-10]

plan_head_before: eca5dcb5cb2b632318b252c299b9809ff7995a5e
estimate:
  tokens: 110000
  raw_tokens: 110000
  tasks: 3
  confidence: low
actuals:
  tokens: 12236    # chars/4 sur les lignes ajoutées du diff réalisé (git diff eca5dcb..HEAD, 48947 caractères, préfixes `+` compris, relevé compris), hors ce SUMMARY
  tasks: 3         # Tâche 1 (traceur) faite ; Tâche 2 (checkpoint) relayée sans être tranchée par l'exécuteur ; Tâche 3 faite (constructeur, rejeu réel, relevé) sans armement
  commits: 3       # MESURÉ : git rev-list --count eca5dcb5cb2b632318b252c299b9809ff7995a5e..HEAD avant le commit de ce SUMMARY
commits: 3
duration: non mesurée (aucun chronomètre de plan ; rejeu réel : environ 5 minutes, test-planning-gates.sh complet : 123 s, test-rejeu-gates.sh : 64 s)

tech-stack:
  added: []
  patterns:
    - "couverture déclarée ET vérifiée : chaque cas d'un canary porte les éléments de couverture qu'il prétend assurer, et le canary refuse (indéterminé) une étiquette que le mode ou le payload du cas ne justifie pas ; les cas de dégradation ne comptent que pour le mode (script-absent, python-absent), jamais pour Task ou Agent, sinon le retrait du cas ROLE-worker-Task resterait invisible"
    - "deux mutants sur un même contrôle qui attaquent deux endroits différents : MUT-CANG-TASK retire le cas (le contrôle rougit sur l'état livré), MUT-CANG-COUVERTURE rend le calcul de couverture aveugle (le contrôle rougit sur la copie sans le cas Task) ; la copie sans Task est fabriquée depuis le script sous test, pas depuis l'original"
    - "un substitut de hook qui délègue `--classer` au vrai hook et applique la lettre de la table §5 pour le reste : la légitimité du constructeur ne dérive jamais du rôle, le dispatch de la propre allowlist d'un worker compte alors un faux refus"
    - "une mesure qui déclare sa limite d'indépendance dans son propre relevé (une ligne vérifiable par commande) au lieu de la taire"

key-files:
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-REJEU-ETAPE-4.md
  modified:
    - plugin/planning-core/scripts/check-gates-alive.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/scripts/rejeu-gates.sh
    - plugin/planning-core/scripts/tests/test-rejeu-gates.sh

key-decisions:
  - "Rejeu réel de l'étape 4 autorisé par Willy (AskUserQuestion session principale, 2026-09-30) : rejeu-oui, relayé tel quel, l'exécuteur n'a rien tranché ni redemandé (Tâche 2). F9 = f9-allowlist (même canal, même date), appliquée par le constructeur ROLE. Mise au repos des labs : Willy, AskUserQuestion session principale, 2026-09-30, « ferme les processus et go »."
  - "Amendement A1 (manager vf-dev-manager, 2026-09-30) : le rejeu de l'étape 4 est une MESURE SEULE. P45-D-03 interdit d'armer le rôle tant que G7 n'est pas armé dans l'état livré ; rien n'est armé, aucune constante ARMEMENT_* ni TABLE_ATTENDUE n'est modifiée, pas de commit d'armement (l'action 4 du plan est exécutée SANS ARMEMENT). Le relevé porte « Mesure seule — armement différé, étapes 1 à 3 mesurées à zéro mais non encore armées (P45-D-03) » et la section « Non armé — remonté à Willy » (motif : armement différé, G7 non armé, P45-D-03)."
  - "Périmètre du constructeur ROLE : les définitions de la RACINE de chaque lab adhérent (« chaque lab copié » du plan). Les `.claude/agents` des labs imbriqués ne sont pas rejoués (recensés dans le relevé). Un agent `.md` en lien symbolique n'est pas une définition (A1 de la 42, comme le hook) ; deux définitions du même nom normalisé de rôles contradictoires : agent inconnu du hook, écriture doit-passer, aucun dispatch (P45-D-11)."
  - "Étiquettes de couverture : `Task` et `Agent` ne sont attribuées qu'à des cas nominaux (le gate voit l'outil) ; les cas DEGRADE ne portent que leur mode. Choix du planificateur laissé ouvert par le plan (« chaque cas étiqueté par les éléments qu'il couvre »), tranché ici pour que MUT-CANG-TASK soit opposable."
  - "Le lab synthétique du canary : l'`ecrit:` du plan ouvert couvre désormais `livrables` (en plus du dossier nu de G7) pour que G2 (avertit) se taise sur le cas ROLE-juge et que l'observation de ROLE soit le seul signal."

requirements-completed: []
requirements-note: "à cocher par l'orchestrateur (ADR-063) ; GATE-12 (couverture minimale du canary, cas ROLE sous Agent et Task), GATE-13 (mesure du rôle agent par agent, ordre respecté) et GATE-15 sont prouvés en CI et par le relevé ; GATE-09 : le rôle est prouvé vivant et mesuré à zéro, son ARMEMENT reste ouvert (différé après G7, P45-D-03)"

status: complete
---

# Phase 45 Plan 09: canary du rôle et couverture minimale, constructeur ROLE du rejeu, rejeu réel de l'étape 4 (mesure seule) Summary

**Le canary de session prouve le rôle vivant sous `Agent` ET sous `Task` (juge, worker hors allowlist) et déclare sa couverture minimale P45-D-20, vérifiée cas par cas (script absent, python3 absent, Task, Agent, fil principal, `plugin:`) ; le constructeur ROLE mesure la légitimité sur les déclarations des agents ; le rejeu réel des deux labs rend `COMPTE ROLE faux-refus=0 faux-accept=0` sur 24 agents réels, avec l'empreinte de tout l'arbre identique : le rôle reste en `observe` (armement différé, G7 non armé, P45-D-03, amendement A1).**

## Performance

- **Tâches :** 3/3 (Tâche 1 traceur ; Tâche 2 = checkpoint relayé avec la réponse de Willy, sans décision de l'exécuteur ; Tâche 3 sans armement)
- **Commits de tâche :** 3 (mesuré depuis `plan_head_before`) : `80ae930` (Tâche 1), `c71d7e4` (Tâche 3, code), `d3fe8cd` (Tâche 3, relevé)
- **`test-planning-gates.sh` :** 333 OK (45-08) -> **338 OK · 0 KO** (trois contrôles, deux mutants)
- **`test-rejeu-gates.sh` :** 53 OK (45-08) -> **55 OK · 0 KO** (R-REJEU-ROLE, MUT-REJEU-ROLE-LEGITIME)
- **Rejeu réel, étape 4 :** `COMPTE ROLE faux-refus=0 faux-accept=0 refus-conforme-modele=0`, `REJEU-ETAPE-4 faux-refus=0 faux-accept=0 refus-conforme-modele=202`, `EMPREINTE-ARBRE-IDENTIQUE` pour les deux labs, un seul passage (code 0)

## Accomplishments

- **Canary du rôle (Tâche 1, traceur).** Le lab synthétique du canary pose lui-même `canary-juge.md` (`disallowedTools: Write, Edit`) et `canary-worker.md` (`vf-internal: true`, `tools: Read, Agent(canary-cible)`). Trois cas, attendu dérivé de la table d'armement (observation tant que ROLE est en `observe`, refus une fois armé) : `ROLE-juge` (Write de `livrables/canary.md` par `canary-juge`), `ROLE-worker-Agent` et `ROLE-worker-Task` (dispatch de `hors-liste` par `canary-worker`, refusé : absent de l'allowlist `Agent(canary-cible)`, F9 = f9-allowlist). Le payload de dispatch porte maintenant le `subagent_type` du cas (le « chemin » du payload).
- **Couverture minimale.** `COUVERTURE_MINIMALE = ("script-absent", "python-absent", "Task", "Agent", "fil-principal", "plugin")` ; `CANARIS` passe à cinq champs (`id|gate|mode|payload|couvre`) ; une étiquette fausse (mode ou payload qui ne la justifie pas) rend le canary indéterminé (code 4), jamais un vert de complaisance ; `--couverture` imprime les éléments couverts un par ligne et sort 3 (tout couvert) ou 0 avec UNE ligne de signal ; en session (y compris sous `--hook`) une couverture incomplète fait signaler le canary avant tout rejeu. `--couverture` ne lit ni stdin ni réglage.
- **Preuves (suite des gates).** `R-CANG-ROLE` (état livré : une ligne `gate=ROLE` par cas ; quatre étapes armées : un refus de gate par cas), `R-CANG-ROLE-MORT` (`evaluer_role` neutralisé : code 0, une ligne qui nomme `ROLE-juge`, observe comme armed), `R-CANG-COUVERTURE` (six éléments et code 3 ; copie sans le cas Task : code 0, une ligne qui nomme Task, cinq éléments ; en session : une ligne de signal). `MUT-CANG-TASK` (le cas retiré) et `MUT-CANG-COUVERTURE` (calcul de couverture qui ne rend jamais rien de manquant) sont TUÉS, témoin inchangé.
- **Constructeur ROLE (Tâche 3).** Pour chaque définition régulière de `.claude/agents/*.md` de la racine d'un lab dont le `.planning/` est adhérent (copie), `planning-hook.sh --classer` sur la copie du hook donne rôle, allowlist et disallowed ; écriture de `rejeu-role/<agent>.md` par l'agent (doit-refuser s'il retire Write ET Edit, sinon doit-passer), un dispatch sous `Agent` de chaque nom de SA propre allowlist (doit-passer), pour un worker le dispatch de `hors-liste-rejeu` sous `Agent` et sous `Task` (doit-refuser). Jamais `doit-refuser-modele` (`refus-conforme-modele` vaut 0 pour le rôle). Une ligne `ROLE-AGENT lab=… agent=… role=… ecriture=… dispatchs=…` par agent donne le rôle dérivé au relevé.
- **Preuves (suite du rejeu).** `R-REJEU-ROLE` : le vrai hook armé à l'étape 4 sur un lab synthétique (juge, juge dont le `name:` diffère du fichier, manager à allowlist, worker à allowlist, producteur, deux définitions contradictoires, un lien symbolique) : onze lignes conformes, `COMPTE ROLE (0, 0, 0)`, six lignes `ROLE-AGENT`, lab sans `.planning/` : aucune ligne ; à `--etape=3` ROLE est en observe, `COMPTE ROLE (0, 4, 0)` suffixé `hors-etape`, `REJEU-ETAPE-3` à 0 ; un substitut de hook qui applique la lettre (tout dispatch d'un worker refusé) compte `faux-refus=1` sur le dispatch de la propre allowlist du worker. `MUT-REJEU-ROLE-LEGITIME` (légitimité d'un dispatch jugée par le rôle) TUÉ : `(0, 0, 0)` -> `(0, 1, 0)`.
- **Rejeu réel (mesure seule, A1).** Précondition de repos tenue (Keystone 0 processus ; BusinessFlow 2 `Code Helper (Plugin)`, PID 4670 et 5146, et 2 `zsh`, PID 5119 et 65656). 24 agents réels rejoués (7 à Keystone : 6 managers, 1 juge `plan-reviewer` ; 17 à BusinessFlow : 16 producteurs, 1 `contracts` illisible), 35 lignes ROLE (24 écritures, 11 dispatchs de managers) : 34 doit-passer/passe, 1 doit-refuser/refus (`plan-reviewer`), aucun écart. Aucun worker (`vf-internal: true`) n'existe dans ces labs, y compris imbriqués (recherche en lecture seule) : la conséquence de F9 sur les labs réels est un compte de zéro. Les comptes G6, G5, G1, G7 sont ceux de l'étape 3 (196 et 6 refus conformes au modèle).
- **Relevé.** `45-REJEU-ETAPE-4.md` : en-tête « Mesure seule — armement différé… (P45-D-03) », déclaration d'une seule ligne de non-indépendance de la ligne worker (vérifiée par commande), sortie brute de `lsof`, lignes brutes des comptes et des empreintes, tableau par agent, limites, section « Non armé — remonté à Willy ».

## Lignes brutes du rejeu réel

```
COMPTE G6 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G5 faux-refus=0 faux-accept=0 refus-conforme-modele=0
COMPTE G1 faux-refus=0 faux-accept=0 refus-conforme-modele=196
COMPTE G7 faux-refus=0 faux-accept=0 refus-conforme-modele=6
COMPTE ROLE faux-refus=0 faux-accept=0 refus-conforme-modele=0
REJEU-ETAPE-4 faux-refus=0 faux-accept=0 refus-conforme-modele=202
EMPREINTE-ARBRE-IDENTIQUE ~/jarvis-keystone
EMPREINTE-ARBRE-IDENTIQUE ~/BusinessFlow-Lab
```

## Task Commits

1. **Tâche 1 (traceur) :** `80ae930` — canary du rôle sous Agent et Task, couverture minimale déclarée (deux trailers Gate-Touche : le canary, sa suite). Tracer feedback gate : `<verify>` de la Tâche 1 rejoué avant d'étendre (338 OK · 0 KO, `test-planning-hook-installed.sh` 19 OK, `--couverture` imprime les six éléments, `45-CONTROLE-MARQUEUR.sh` : `sans-marqueur=0`) : « Tracer verified end-to-end — expanding ».
2. **Tâche 2 (checkpoint) :** aucune modification ; réponse de Willy relayée (rejeu-oui, AskUserQuestion session principale, 2026-09-30).
3. **Tâche 3 :** `c71d7e4` — constructeur ROLE, R-REJEU-ROLE, MUT-REJEU-ROLE-LEGITIME, R-REJEU-STATIQUE à quatre appels (deux trailers Gate-Touche) ; `d3fe8cd` — relevé `45-REJEU-ETAPE-4.md`. **Aucun commit d'armement** (amendement A1) : `planning-hook.sh` n'est pas touché par ce plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking, conséquence du plan] R-REJEU-STATIQUE attendait trois appels de sous-processus**
- **Found during :** première exécution de `test-rejeu-gates.sh` après l'ajout du constructeur : `obtenu : violations=[] appels=4`. Le constructeur ROLE lance `planning-hook.sh --classer` (bash, argv littéral, aucun git).
- **Fix :** la garde statique attend désormais quatre appels et le dit (le hook copié : le jeu d'une écriture et `--classer` ; recalc-planning.sh ; cmp). **Commit :** `c71d7e4`.

**2. [Rule 1 - Bug, dans mon brouillon] Le substitut de la lettre jugeait aussi les autres gates**
- **Found during :** `R-REJEU-ROLE`, première exécution : `REJEU-ETAPE-4 (1, 9, 0)` avec le substitut (qui n'implémente que le rôle, les neuf lignes des autres gates sont des faux accepts du substitut). **Fix :** le contrôle ne juge que `COMPTE ROLE` pour le substitut. **Commit :** `c71d7e4`.

### Écarts de mise en oeuvre (sans changement de contrat)

**3. Lignes `ROLE-AGENT` ajoutées au relevé.** Le plan exige « rôle dérivé » par agent ; l'outil n'imprimait que des lignes par écriture. Une ligne `ROLE-AGENT` par agent (additive, sans ` | `, donc jamais lue comme une ligne d'écriture par la suite) est imprimée après `CLASSE-REGLE-ECRITE` ; documentée dans l'en-tête de l'outil.
**4. TDD.** La Tâche 3 est marquée `tdd="true"` : le constructeur a été écrit avant `R-REJEU-ROLE` (RED non observé sur le test neuf ; le seul rouge avant code était `R-REJEU-STATIQUE`). L'opposabilité est prouvée après coup : `MUT-REJEU-ROLE-LEGITIME` rend `R-REJEU-ROLE` rouge, le substitut de la lettre compte un faux refus. Le plan prescrit un commit de code unique.
**5. Rapport du rejeu réel écrit hors du dépôt.** Le relevé versionné est composé (en-tête, tableau par agent, limites) à partir du rapport brut de 4438 lignes écrit sous le scratchpad de la session, comme pour les étapes 1 à 3 ; la commande `--rapport=` du plan aurait écrasé l'en-tête.
**6. `plan_head_before`.** Le registre par plan (`gsd-plan-head-before-45-09` sous le git-dir) n'a pas été écrit ; la valeur `eca5dcb…` est celle de `HEAD` au démarrage, vérifiée par `git merge-base --is-ancestor eca5dcb HEAD` (code 0) ; `commits: 3` est mesuré par `git rev-list --count` depuis cette valeur.

### Déviation de périmètre (à signaler)

**7. `planning-hook.sh` non modifié.** Le plan le liste dans `files_modified` pour le seul commit d'armement ; sans armement (A1), il n'est pas touché (`git diff eca5dcb..HEAD` ne le nomme pas). Aucune constante `ARMEMENT_*` ni `TABLE_ATTENDUE` ne change ; STATE.md et ROADMAP.md ne sont pas touchés.

### Limites de la mesure (déclarées au relevé)

- Ligne worker non indépendante sous f9-allowlist (constructeur et politique : même prédicat), et exercée uniquement sur le corpus synthétique de la suite : aucun worker réel.
- Périmètre racine : les `.claude/agents` des labs imbriqués (quatre à Keystone, huit sous `projetflow-staging` et deux exemples de référence à BusinessFlow, hors un cache obsolète) ne sont pas rejoués.
- Agents de plugin (`<plugin>:<agent>`) non rejoués ; agents du compte utilisés seulement pour la résolution.

### Refus de garde du poste (rapportés, jamais contournés)

Six commandes Bash ont été refusées par la garde d'isolation du worktree (« too complex to verify »), puis refaites en commandes simples sans changer leur intention : (1) une édition Python en heredoc enchaînée à `bash -n` et à une exécution, refaite par un fichier posé sous le scratchpad puis lancé seul ; (2) un filtre `lsof ... | sed "s#$HOME#~#g"` (programme sed calculé à l'exécution), refait avec `awk` et un littéral ; (3) à (6) quatre commandes `check-*.sh ... | tail ; echo rc=${PIPESTATUS[0]}`, refaites sans la construction `PIPESTATUS`. Aucun refus de classifieur ni de hook de commit.

## Auth gates

Aucune.

## Suites rejouées (aucune découverte complète)

| Suite | Résultat |
|---|---|
| planning-core/test-planning-gates.sh | 338 OK · 0 KO |
| planning-core/test-rejeu-gates.sh | 55 OK · 0 KO |
| planning-core/test-planning-hook-registered.sh | 37 OK · 0 KO |
| _internal/test-planning-hook-installed.sh | 19 OK · 0 KO |
| scripts/tests/test-role-hook-vs-check-agents.sh | 6 OK · 0 KO |
| planning-core/test-check-planning-state.sh | 19 ok · 0 ko |
| planning-core/test-detect-gsd-engine.sh | 26 ok · 0 ko |
| planning-core/test-detect-planning-debt.sh | 10 passés · 0 échoués |
| planning-core/test-planning-context-hardening.sh | 38 passés · 0 échoués |
| planning-core/test-planning-core.sh | 14 passés · 0 échoués |
| planning-core/test-planning-hooks.sh | 42 PASS · 0 FAIL |
| planning-core/test-workstream-policy.sh | 22 ok · 0 ko · 0 skip |
| planning-core/test-workstream-symlink-escape.sh | 10 ok · 0 ko |
| planning-core/test-recalc-planning.sh (une fois, en fin de plan ; fichier non touché) | 347 OK · 0 KO |
| scripts/check-machine-paths.sh | ✓ 1789 fichiers suivis balayés, aucun chemin absolu de machine |
| scripts/check-gate-touche.sh | `marqueurs: lus=56 conformes=56`, `DECLARE` |
| scripts/check-version-sync.sh | ✓ sources synchronisées (v2.67.1, 17 modules), suites 98 |
| 45-CONTROLE-MARQUEUR.sh `--base=fd49137` (check-gates-alive.sh) | `MARQUEUR-BILAN commits=6 sans-marqueur=0` |
| 45-CONTROLE-MARQUEUR.sh `--base=fd49137` (hook, rejeu-gates.sh, test-rejeu-gates.sh) | `MARQUEUR-BILAN commits=17 sans-marqueur=0` |
| `ARMEMENT_*` / `TABLE_ATTENDUE` | aucune ligne ajoutée ni retirée (`git diff eca5dcb..HEAD` filtré) ; les cinq constantes valent `"observe"` |

## Known Stubs

Aucun.

## Threat Flags

Aucune surface nouvelle hors du `<threat_model>` du plan. T-45-80 (rôle supposé vivant) : mitigé (trois cas ROLE, couverture minimale déclarée et vérifiée, `MUT-CANG-TASK`). T-45-81 (rupture des workers dispatcheurs) : mesuré, zéro worker réel, zéro faux refus, aucun armement. T-45-82 (écriture dans un lab réel) : copie, empreinte de tout l'arbre identique par `cmp`, aucune commande git. T-45-83 : noms d'agents seulement dans le relevé, aucun chemin de machine. T-45-84 : déclarée en en-tête du relevé, vérifiée par commande.

## Étapes du workflow sautées (consigne du dispatcher, ADR-063)

Aucune commande `gsd-tools state <verbe>`, aucune écriture de `STATE.md` ni de `ROADMAP.md`, pas de `requirements mark-complete`, pas de `roadmap update-plan-progress`, pas d'écriture du registre `.planning/WINDOWS.md` : à la charge de l'orchestrateur. Aucun push, merge, tag.

## Deferred Issues

- Armement de l'étape 4 : après l'armement de G7 (et des étapes 1 et 2, dans l'ordre) par le manager ; le relevé et le banc sont à zéro. Le commit d'armement portera le trailer `Gate-Touche: plugin/planning-core/scripts/planning-hook.sh — armement de l'étape 4 après canary et rejeu à zéro` et devra modifier `ARMEMENT_ROLE` et `TABLE_ATTENDUE` dans le même commit (R-TABLE-01).
- Rejeu des labs imbriqués et des agents de plugin pour le rôle (limite déclarée).
- `test-vibeflow-update.sh` (18 KO préexistants relevés en 45-01) n'a pas été rejoué.

## Self-Check: PASSED

Vérifié par commandes : les cinq fichiers du périmètre existent ; les trois commits de tâche (`80ae930`, `c71d7e4`, `d3fe8cd`) sont ancêtres de HEAD ; `eca5dcb` est ancêtre de HEAD ; les cinq constantes `ARMEMENT_*` valent `"observe"` et `TABLE_ATTENDUE` est inchangée ; `git diff --stat eca5dcb..HEAD` ne nomme ni STATE.md, ni ROADMAP.md, ni `planning-hook.sh`, ni 45-REJEU-ETAPE-1/2/3.md, ni 45-REJEU-ATTENDUS.txt ; le relevé ne porte aucun chemin absolu de machine (vérifié par `awk` sur le fichier précis avant le `git add`) ; ce SUMMARY ne porte aucun chemin absolu de machine.
