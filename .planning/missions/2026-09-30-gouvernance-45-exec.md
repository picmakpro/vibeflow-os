# Mission gouvernance-45-exec — exécution de la Phase 45 (compartiment `gouvernance`)

- Manager : `vf-dev-manager`, identité de verrou `vf-dev-manager-p45-exec`, génération
  `DRIVER.lock.gen.1790763864.25868`. Mode : autonome sous le head, `design: off`.
- Feu vert : Willy, message en session principale, 2026-09-30.
- Worktree : `.claude/worktrees/gouvernance-45`, branche `gouvernance/phase-45-execution` (poussée,
  sans PR à ce stade). Base de phase : `0c5e631` (= origin/main, CI verte run 36701943812).
- Plan de bataille : `.planning/missions/2026-09-30-gouvernance-45-exec.dag.json`.
- Statut final (2026-10-01) : **10/10 plans livrés, cinq gates armés, vérification human_needed 14/15**
  (GATE-15 : CI Linux de l'état armé, lue sur la PR). Statut à la première remise (2026-09-30) : bloqué
  sur 45-02 (refus du classifieur), levé par Willy.

## Démarrage

- `$S` = `plugin/conductor/scripts` (identique octet pour octet à `./.claude/scripts`, lien vers la
  racine du dépôt).
- Verrou acquis ; `check-mission-invariants.sh` → 3 (SAIN) ; flags d'enchaînement
  (`_auto_chain_active`, `auto_advance`) déjà à `false` dans `.planning/config.json` (lus).
- Recompte des suites sur la base `0c5e631` : **93** (`find plugin scripts -type f -path
  '*/tests/test-*.sh'` et `git ls-files | awk` concordent). Le « 92 » du rapport précédent était
  périmé.
- Rejeu local du job `tests` de `ci.yml` (outil suivi `replay-ci-jobs.sh`, HOME jetable, sans moteur
  GSD installé) : 93 suites, **11 échecs d'environnement**, tous hors planning-core (codex, gsd-core
  absent, etc.). Ensemble de référence pour toutes les comparaisons (par `comm`).

## Arbitrages humains

Escalade des cinq checkpoints de décision d'un coup (aucun ne dépend d'un résultat d'exécution).
Réponse relayée par la session principale : **Willy, AskUserQuestion session principale,
2026-09-30** — recommandations du manager suivies partout :

| Plan | Point | Réponse |
|---|---|---|
| 45-02 | F10 / F7a | f10-archive / f7a-racine |
| 45-04 | F8 / A3 | f8-agnostique / a3-plan |
| 45-05 | F6 / F7b / rejeu étape 1 | f6-oui / f7b-oui / rejeu-oui |
| 45-08 | F9 | f9-allowlist (contre le défaut du plan) — limite déclarée : l'allowlist vit dans une définition d'agent que G6 ne protège pas |
| 45-09 | rejeu étape 4 | rejeu-oui |

Rejeux réels : lecture seule, copie, empreinte avant/après, aucun geste git sur `~/jarvis-keystone`
ni `~/BusinessFlow-Lab`.

## Déroulé

| Nœud | Résultat | Commits |
|---|---|---|
| exec-45-01 | livré 3/3 (exécuteur en `isolation="worktree"` imposé par la garde du harnais, rapatrié en fast-forward) | `d54b4b5`..`02d848b` |
| exec-45-02 | **bloqué** : l'exécuteur a été refusé par le classifieur du mode auto (« Instruction Poisoning ») sur `sed -n 2830,3010p plugin/planning-core/scripts/tests/test-recalc-planning.sh` (fixtures adverses R-LABS-ADVERSES / R-CODE2-MIGRATION). Non contourné. Aucune tâche commitée ; modification partielle non commitée de `recalc-planning.sh` laissée dans `.claude/worktrees/agent-a05dcaacc665102e9` | — |
| exec-45-03 | livré 3/3 (un seul `gsd-executor`, base vérifiée contenant `02d848b`), rapatrié en fast-forward | `cd14335`..`6ef026f` |
| revue-45-socle | revue anticipée 45-01+45-03 : correctifs requis (M1, M2 majeurs dans `rejeu-reel.sh` ; m1, m3, m4, m5) | — |
| fix-socle-1 | quick `260930-kc3` : 6 constats corrigés, chacun rouge→vert puis mutation tuée ; m1 aligné (fuzz différentiel ~1250 chemins, 0 divergence sous sh/bash/dash/zsh) | `541462e`..`696979f` |

Non-régression complète (manager, `comm` contre la base) :

| HEAD | Suites | Échecs | Nouveaux | Disparus |
|---|---|---|---|---|
| `0c5e631` (base) | 93 | 11 | — | — |
| `02d848b` (45-01) | 95 | 11 | 0 | 0 |
| `6ef026f` (45-03) | 97 | 11 | 0 | 0 |
| `696979f` (correction) | 97 | 11 | 0 | 0 |

Preuve de zéro régression dev (45-01, commande enregistrée rejouée hors lab adhérent, ce dépôt) :
Write, Edit, NotebookEdit, Bash, Agent, Task → `rc=0`, stdout 0 octet, stderr 0 octet ;
`RESULTAT mauvais=0`.

## État d'armement des gates à la remise

Aucun gate armé : G6+G5 (45-05), G1 (45-06), G7 (45-07), rôle (45-08/09) ne sont pas encore
construits. G2 livré en avertissement (45-01). Table d'armement du hook : tout en `observe`.
Faux refus mesurés : aucun rejeu réel encore lancé (45-03 a livré l'outil, testé sur fixtures).

## À porter en 45-10 (limites déclarées) et aux mandats suivants

- m2 (revue du socle) : en mode panne (script ou python3 absent), la couche shell tient pour
  adhérent un `config.json` à virgule finale, clé dupliquée, valeur imbriquée ou BOM UTF-8 que le
  cœur Python tient pour non adhérent → refus en panne. Cohérent avec P45-D-06a ; à déclarer.
- Rejeux réels (45-05 à 45-09) : l'empreinte inclut les mtime ; lancer sur des labs **au repos**
  (une session vivante produirait un faux `DIVERGENTE`).
- 45-04 touche `test-planning-gates.sh`, modifié par la correction : partir de `696979f`.
- Les exécuteurs partent en `isolation="worktree"` : vérifier la base puis rapatrier en
  fast-forward à chaque plan.

## Décisions prises en autonomie (manager)

- Escalade groupée des cinq checkpoints avant l'exécution (aucun ne dépend d'un résultat).
- 45-03 exécuté seul (un exécuteur), pas `--wave 2` : 45-04 dépend de 45-02, non livré.
- Revue anticipée du socle pendant l'attente de la décision humaine, puis correction ciblée.
- Branche poussée tôt pour la CI Linux (run 36719732281, en file d'attente à la remise).

## Décompte

- Minds dispatchés : 4 (vf-coder vague 1, vf-coder 45-03, vf-reviewer socle, vf-coder correction).
- Tours consommés : 1 tour de revue, 1 tour de correction.

## Preuves E6

```json
{
  "preuves": [
    {"verdict": "recette", "preuve": "amont"},
    {"verdict": "gate:zero-regression-dev", "commande": "rejeu de la commande enregistrée de plugin/planning-core/hooks/hooks.json hors lab adhérent (preuve-dev.py de l'exécuteur 45-01)", "exit_code": 0, "sha": "02d848b"},
    {"verdict": "gate:suites-planning-core", "commande": "runall.sh du scratchpad du correcteur (12 suites planning-core + test-planning-hook-installed, hors test-recalc-planning.sh)", "exit_code": 0, "sha": "2052d1c"},
    {"verdict": "gate:non-regression-complete", "commande": "HOME=<jetable> bash .planning/workstreams/fiabilite/phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job tests (comparé par comm à la base)", "exit_code": 1, "sha": "696979f"}
  ]
}
```

Le `exit_code: 1` de la non-régression complète est celui des 11 échecs d'environnement de la base,
identiques en ensemble (`comm` vide dans les deux sens) : aucun échec introduit.

## Suite et clôture de l'exécution (2026-09-30 → 2026-10-01)

Le détail du 2026-09-30 (45-02 à 45-10, revue et audit en deux tours, lots A, B, C) est tracé dans les
SUMMARY des plans et des quick. Ce qui suit couvre la reprise du 2026-10-01.

### Pilotage
- **Verrou :** repris par takeover (lock périmé, l'orphelin a5e063ef était le worker du lot D, mort
  avec la session), puis réacquis à chaque relance du head. DAG de reprise :
  `.planning/missions/2026-10-01-gouvernance-45-reprise.dag.json`. L'ancien DAG n'était plus tenu
  depuis le 2026-09-30.
- **Gate d'invariants :** 3 (SAIN). Flags d'enchaînement : déjà à false (lu dans `.planning/config.json`).
- **Remises forcées :** trois remises intérimaires ont été imposées par le harnais pendant l'attente
  d'un worker. Leçon consignée en mémoire d'agent (`project_attente-au-premier-plan.md`).

### Provenance des arbitrages (constat F2 de la revue de l'armement)
- **Q-ARM :**
  - Question posée par le manager, relayée à Willy par la session principale le 2026-09-30 :
    « autoriser l'adaptation des deux suites couplées à « tout en observe ». C'était le refus du
    classifieur « Security Test Removal ». Sans cette autorisation, aucun armement n'est possible. »
  - Réponse rapportée par la session principale dans le mandat de reprise du 2026-10-01, texte exact :
    « Q-ARM, 2026-09-30 : oui pour les quatre étapes d'armement. Découplage des suites autorisé, sans
    supprimer aucun cas ni aucun mutant, chaque cas modifié prouvé rouge sur son mutant. »
  - Canal déclaré : AskUserQuestion session principale. Le manager n'a pas vu la réponse de Willy
    elle-même, seulement ce relais.
- **Q-G6 = (b) :** même canal, 2026-10-01. G6 protège `planning-hook.sh` et `check-gates-alive.sh` ;
  `.claude/settings*.json` reste une limite déclarée.

### Déroulé

| Nœud | Résultat | Commits |
|---|---|---|
| verif-D | lot D vérifié : gates 430/0, rejeu 91/0, registered 44/0, installed 23/0, rôle 6/0, recalc 358/0 ; indépendance à l'armement sur 5 états | `731abf55` |
| revue-D | gaps_found : F1 majeur (un `.planning` créé sous `.claude` désarmait G6-scripts par Write seul), F2-F4 mineurs | — |
| fix-45-E | quick 261001-kp5 : un `.planning` sous `.claude` n'est jamais racine, sauf `.claude/worktrees/<nom>` (décision du manager, renversable) ; F2-F4 fermés | `8a86ed25`, `a2a2a9ff` |
| revue-E | PASSED : l'exception worktrees ne rouvre rien ; 4 implémentations d'accord (126 chemins, 0 écart) ; 5 mineurs | — |
| rejeu-final-4 | 0 faux refus, 0 faux accept, REJEU-ETAPE-4 0/0/202, empreintes de tout l'arbre identiques sur les deux labs ; labs au repos avant et après | `708debcb` |
| fix-45-F | quick 261001-m8c : M1-M5 ; M3 déclaré avec l'effet mesuré (décision du manager) | `b9071496`..`07edca9e` |
| arm-1..4 | G6+G5, G1, G7, rôle ; après chaque commit : gates 446/0, registered 50/0, rejeu 91/0, installed 23/0, rôle 6/0 ; zéro régression dev 12/12 ; canary rc=3 ; marqueurs sans-marqueur=0 | `3d06e503`, `bf6cfa87`, `b6609fa6`, `239df76d` |
| revue-arm | gaps_found : F1 README (« journalisent sans refuser » sur des gates armés), F2 provenance Q-ARM (voir ci-dessus), mineurs | — |
| maj-45-10 | quick 261001-owx : README, CHANGELOG, 45-10-SUMMARY, 45-COUT-MIGRATION et 45-VALIDATION à l'état armé ; limite (z) ; chemins de machine du lot F | `3a2495fb`..`4cc09106` |
| verif-45 | `human_needed` 14/15 : seul GATE-15 (CI Linux de l'état armé) reste à lire ; GATE-09 tenu sous l'override F9 | `74868a60` |

### Non-régression complète (job tests de la CI, HOME jetable, `comm` contre la base)

| HEAD | Suites | Nouveaux échecs |
|---|---|---|
| `731abf55` | 98 | 0 (flake SIGPIPE de `test-restore-requirements-ledger.sh`, 3/3 vert rejoué seul) |
| `a2a2a9ff` | 98 | 0 |
| `239df76d` | 98 | 1 : `test-check-machine-paths.sh`, régression réelle du lot F (`/Users/<compte>` dans 261001-m8c-PLAN.md), corrigée en `3a2495fb` ; gate rc=0 sur 1806 fichiers |

### État d'armement livré
- Gates armés : G6, G5, G1, G7 et rôle. G2 avertit.
- Faux refus mesurés en réel : 0 dans les deux sens.
- Points de surveillance :
  - **Limite (z) :** faux refus fail-closed sous forte charge (échéance de 8 s du cœur, « Alarm clock »),
    vu en suites sous une charge de 20 à 35, jamais en réel.
  - L'extension de G6 aux scripts du hook n'est prouvée qu'en suites : aucun lab réel ne porte ces scripts.

### Décompte
- **Minds dispatchés pendant la reprise :** 9 mandats. Sur ce compte : 2 réveils de workers existants,
  3 vf-coder neufs (lot E, rejeu final, documentation), 3 vf-reviewer et 1 gsd-verifier.
- **Sous-agents lancés par les workers :** planner, plan-checker, executor, verifier, non inscrits au registre.
- **Tours de revue :** 3. **Lots de correction :** 3 (E, F, owx).

## Preuves E6

```json
{
  "preuves": [
    {"verdict": "recette", "preuve": "amont"},
    {"verdict": "gate:suites-planning-core", "commande": "bash plugin/planning-core/scripts/tests/test-planning-gates.sh (et registered, rejeu, installed, rôle) après chaque commit d'armement", "exit_code": 0, "sha": "239df76d"},
    {"verdict": "gate:zero-regression-dev", "commande": "rejeu de la commande enregistrée de hooks.json hors lab adhérent, 6 outils x 2 shells", "exit_code": 0, "sha": "239df76d"},
    {"verdict": "gate:rejeu-reel-final", "commande": "rejeu-reel.sh --lab=~/jarvis-keystone --lab=~/BusinessFlow-Lab --etape=4", "exit_code": 0, "sha": "a2a2a9ff"},
    {"verdict": "gate:non-regression-complete", "commande": "HOME=<jetable> replay-ci-jobs.sh --job tests, comparé par comm", "exit_code": 1, "sha": "239df76d"},
    {"verdict": "gate:machine-paths", "commande": "scripts/check-machine-paths.sh", "exit_code": 0, "sha": "4cc09106"},
    {"verdict": "verification", "commande": "gsd-verifier --ws gouvernance", "exit_code": 0, "sha": "74868a60"}
  ]
}
```

Le `exit_code: 1` de la non-régression à `239df76d` vient d'échecs d'environnement de la base,
plus la régression de chemin de machine corrigée ensuite en `3a2495fb`.
