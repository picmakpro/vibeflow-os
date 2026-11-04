# 68-10 — Trace du rouge de la doc (VFSG-12), tâche 1 partie 1

Base : `d4f3bbb5` (branche `feat/phase-68-doc`), avant toute ligne de doc. Claude Code 2.1.318. Sorties brutes dans le scratchpad de session (`d2.out`, `d4a.out`, `d4b.out`).

## Témoins joués avant l'écriture

| Id | Commande | Attendu avant la doc | Obtenu |
|----|----------|----------------------|--------|
| D1a | `grep -c 'Pane terminal' plugin/cockpit/README.md` | 0 (rouge) | 0 |
| D1b | `grep -c 'cockpit=' plugin/cockpit/README.md` | 0 (rouge) | 0 |
| D1c | `grep -c 'signal@1' plugin/cockpit/README.md` | 0 (rouge) | 0 |
| D2 | `bash scripts/check-version-sync.sh` (contrôle positif) | exit 0, compte des suites juste (153) | exit 0 ; `README.md suites 153`, `README.fr.md suites 153`, `sources synchronisées (v2.75.1, 19 modules)` |
| D3a | `grep -c 'vf-signal' README.md` | 0 (rouge) | 0 |
| D3b | `grep -c 'vf-signal' README.fr.md` | 0 (rouge) | 0 |
| D4a | `bash scripts/tests/test-check-machine-paths.sh` (le gate sait rougir) | exit 0 | exit 0 ; `bilan : 19 OK / 0 KO` |
| D4b | `bash scripts/check-machine-paths.sh` | exit 0 | exit 0 ; `2496 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` |

Lecture : D1 et D3 sont rouges (la doc manque), D2 est le contrôle positif (le compte des suites est juste avant la doc et doit le rester : la doc ne touche ni la mention « N suites », ni les badges, ni l'historique), D4 prouve que le gate de chemins sait rougir et qu'il est vert sur l'arbre.
Ces trois rouges et ces deux verts sont les attendus du plan ; aucun n'a été un faux départ.

## Porte de phase (tâche 3) — rejeu du job `gates`, job `tests` cité

Date : 2026-11-04. Arbre : branche `feat/phase-68-clo`, partie de `b2fa4a90` (tête de `feat/phase-68-vf-signal` au moment du rejeu). Claude Code 2.1.318.

### Job `gates`

Commande : `bash .planning/milestones/fiabilite-v1.0-phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job gates` -> **exit 0**, 56 s.
Ligne de bilan : `BILAN REJEU gates : 21 rejouee(s), 4 sautee(s), 0 en echec`.

| Étape | Gate | Code |
|-------|------|------|
| 1 | action (installation du CLI), sautée | sautée |
| 2 | check-agents --strict sur `plugin/*/agents` | 0 |
| 3 | check-agents --strict sur `plugin/*/AGENT.md` | 0 |
| 4 | check-agents --resolve-agents=strict | 0 |
| 5 | check-skills | 0 |
| 6 | check-blueprints | 0 |
| 7 | check-version-sync | 0 |
| 8 | check-state-integrity | 0 |
| 9 | check-capability-activation | 0 |
| 10 | check-machine-paths | 0 |
| 11 | check-python-isolation | 0 |
| 12 | check-instruction-budget | 0 |
| 13 | gates workstream-aware sur arbre partitionné (fixture jetable) | 0 |
| 14 | check-divergence en CI (mutation rouge sur fixture divergente) | 0 |
| 15 | check-planning-consumers-registered | 0 |
| 16 | check-baseline-arbitrage (G-1) | 0 |
| 17 | check-gate-touche (G-2) | 0 |
| 18 | check-ajout-retrait (SOBR-05, consultatif) | 0 |
| 19 | check-affirmation-non-mesuree (G-4) | 0 |
| 20 | check-manual | 0 |
| 21 | check-push-sans-pr (G-3, preuve par fixture) | 0 |
| 22 | check-push-sans-pr (mesure réelle), conditionnée à un push sur `main` | sautée |
| 23 | action, sautée | sautée |
| 24 | mod vf-signal : `claude plugin validate --strict` et `claude plugin test` (VFSG-08) | 0 |
| 25 | check-release-tag, conditionnée à un push sur `main` | sautée |

Les lignes `BILAN : … code=1` / `code=3` du journal appartiennent aux cas négatifs de l'étape 12 (témoins qui doivent rougir) ; l'étape rend 0.
Étapes 1, 22, 23 et 25 : sautées par l'outil comme conditionnelles ou comme actions, pas d'échec.

### Job `tests` — écart assumé

Le plan (tâche 3) demandait de jouer toute la découverte `scripts/ci-shard-suites.sh --all` en local. Le mandat de clôture le remplace : le job `tests` (7 shards) n'est pas rejoué ici, il est cité depuis la CI de la PR #199.
Écart : aucun run complet vert n'existe sur la tête `b2fa4a90` au moment de la clôture ; la preuve du job `tests` sur cette tête reste à lire dans le run final que le manager citera dans la PR.

Runs CI de la PR #199 (`gh run list --branch feat/phase-68-vf-signal`) :

| Run | Tête | Conclusion |
|-----|------|------------|
| 41836708459 | `36501b66` | **success** (dernier vert complet : 7 shards, « Suites de tests (découverte non vide) », gates, labs frais, mutants du guard) |
| 41852552073 | `20d61bc4` | failure : shard 6, `test-check-method-budget.sh` rc=1 (30/30 jouées, 1 échec) — flake connue de cette suite, non établie comme telle sur ce run |
| 41845534785, 41846897284, 41846651687, 41848643579, 41857139610, 41857935466, 41859018567 | divers | cancelled (annulés par un push suivant) |
| 41860086952 | `5ff97435` | queued |
| 41863039549 | `b2fa4a90` | queued ; `gh pr checks 199` : tous les jobs « pending », Socket Security pass |

Conclusion de la porte : `gates` rejoué vert localement sur la tête relue ; `tests` non rejoué (mandat), dernier vert cité `36501b66`, un rouge `20d61bc4` à surveiller sur le run final.
