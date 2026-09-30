# Mission gouvernance-45-exec — exécution de la Phase 45 (compartiment `gouvernance`)

- Manager : `vf-dev-manager`, identité de verrou `vf-dev-manager-p45-exec`, génération
  `DRIVER.lock.gen.1790763864.25868`. Mode : autonome sous le head, `design: off`.
- Feu vert : Willy, message en session principale, 2026-09-30.
- Worktree : `.claude/worktrees/gouvernance-45`, branche `gouvernance/phase-45-execution` (poussée,
  sans PR à ce stade). Base de phase : `0c5e631` (= origin/main, CI verte run 36701943812).
- Plan de bataille : `.planning/missions/2026-09-30-gouvernance-45-exec.dag.json`.
- Statut à la remise : **partiel — bloqué sur une décision humaine** (45-02, refus du classifieur
  de permissions). 45-04 à 45-10, vérification, revue et audit finaux, PR : non commencés.

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
