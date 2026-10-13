# Mission « dette avant la PR de la Phase 57 » — 2026-10-12 / 2026-10-13

Manager : vf-dev-manager, owner `mission-dette-p57`, verrou du compartiment `fiabilite` (gestes de dépôt courts
sous `--depot` pour `BACKLOG.md` et `CONCERNS.md`). Branche `feat/phase-57-verrou-compartiment`, base `10273142`.
Brief : arbitrage Samuel, AskUserQuestion session principale, 2026-10-12 (dettes nées de la 57, budget de méthode
fiabilite, suite instable). Ni push, ni PR, ni tag, ni bump de `VERSION`.

## Plan de bataille (DAG)

| Nœud | Worker | Dépend de | Périmètre |
|------|--------|-----------|-----------|
| conductor | vf-coder | — | guard + driver : F-3, R-5, R-6, R-4, C3, R-7 |
| c1 | vf-coder | — | `check-mission-exit.sh` et ses suites |
| flaky | vf-coder (debug) | — | `check-description-fidelity.sh` et sa suite |
| state | manager | — | frontmatter du STATE fiabilite |
| backlog-evidence | general-purpose (lecture) | — | preuves de livraison des 37 sujets |
| backlog | vf-coder | backlog-evidence | `BACKLOG.md`, archive SOBR |
| revue / audit | vf-reviewer / vf-auditer | lots de code | lecture seule, en parallèle |
| fix-juges | vf-coder | revue, audit | correction ciblée unique (AUD-1, S1 à S5) |
| changelog | vf-coder | revue, audit | CHANGELOG, CONCERNS, 57-REVIEW/SECURITY/VERIFICATION/CONTEXT |
| gates | manager | tout | rejeu `ci.yml` (gates, tests), budget |

Neuf workers dispatchés, un seul tour de correction après les juges.

## Résultats par chantier

1. **Dettes de la 57.**
   - C1 corrigée dans le code distribué (`fc763a72` RED, `dcba414d`, `5eccb6e0`) : dans le dépôt source,
     `check-mission-exit.sh` prend le module conductor voisin avant `$HOME/.claude/scripts`. Un lab installé garde
     l'ordre d'avant.
   - F-3 (`c5ccbab7`, `63d5cc4c`, `08d25595`) : 12 globaux git sans argument et `exec` sont reconnus, en lab
     partitionné seulement (P57-D-42).
   - R-5 (`63d5cc4c`, `b66a7dbe`) : en lab partitionné, un préfixe `GIT_*=` du même segment rend la cible
     incertaine (P57-D-43).
   - R-6 (`63d5cc4c`) : le crochet de test est retiré de la production.
   - R-4 (`6333d8e4`, `8689bbd7`) : le driver re-sonde l'ancien verrou après la pose. Le défaut était réel : deux
     détenteurs avant le correctif. La prose est dans `mission-flow.md`.
   - C3 (`6333d8e4`, `1f6b555b`) : six mutants ajoutés.
   - R-7 (`6333d8e4`, `8b957f62`) : une empreinte épinglée remplace le SKIP en clone shallow.
   - Compteurs du STATE : `d0a2eb23` (P57-D-41).
   - Prose et registres : `ce172d64`, `69481213`, `e6241a95`.
   - Le seuil du watchdog n'est PAS corrigé : c'est un choix de comportement, voir Q1.
2. **Budget de méthode.**
   - PROSE DÉPASSÉE : 5 → 0. L284 est close, les quatre autres entrées sont condensées. Le texte intégral est
     archivé (`2f33dd53`, `38619dce`, `7c20cd49`) ; les déclencheurs ont été vérifiés par script (5/5).
   - Sujets ouverts : 37 → 31. Six sont clos sur preuve rejouée (L242, L284, L421, L588, L625, L643) ; le chiffre
     n'a pas été forcé (Q3).
   - ROADMAP fiabilite : inchangée, 167 Ko (Q2).
3. **Suite instable.** Deux causes, toutes deux dans la suite (`c580b45e`, `06af9fdc`) :
   - T10 exigeait un arbre vierge, et un worker voisin le salissait ;
   - T9 lisait le tmpdir global du poste ;
   - de plus, `mktemp -d` sans gabarit ignorait `TMPDIR` dans le gate.
   Mesure : 20 rouges sur 30 avant, 0 sur 30 après (bash, et sous HOME neuf), 0 sur 5 sous zsh. Quatre mutants
   restent rouges pour la bonne raison.

## Budgets (check-method-budget.sh --no-remote, côté fiabilite)

| Budget | Avant | Après |
|--------|-------|-------|
| PROSE DÉPASSÉE (BACKLOG) | 5 entrées | 0 |
| Sujets ouverts (BACKLOG) | 37 / 20 | 31 / 20 |
| ROADMAP fiabilite | 167 Ko / 64 | 167 Ko / 64 |
| STATE fiabilite | 5 Ko / 8 | 5 Ko / 8 |
| Worktrees | 3 / 3 | 3 / 3 |

## Juges

- vf-reviewer, jointure des trois lots : `passed`, Spec et Standards. Six mineurs : S1 à S5 corrigés dans
  `b66a7dbe` à `5eccb6e0`, S6 consigné.
- vf-auditer, guard et driver : `passed`, six lows. AUD-1 et AUD-5 sont corrigés. AUD-2, AUD-3, AUD-4 et AUD-6
  sont consignés dans CONCERNS (limites b à e) ou corrigés en prose.

## Questions ouvertes pour Samuel

- **Q1 — watchdog.** `progress_epoch` n'avance qu'au `dag.sh mark`. Un plan plus long que 900 s déclenche donc un
  stall, alors que la mission progresse : constaté deux fois dans cette mission, à 1 587 s et 1 589 s. `STALL_WINDOW`
  doit rester sous le TTL de 1 800 s (D-33-E). Options :
  - (a) relever ensemble le seuil et le TTL ;
  - (b) compter un commit comme progrès dans le calcul du stall ;
  - (c) imposer `mark-progress` aux workers à chaque commit.
  Recommandation : (b), seule voie qui ne dépend pas de l'observance d'un agent.
- **Q2 — ROADMAP.** Le budget compte les octets bruts : un bloc `<details>` ne fait rien gagner. Le seul jalon
  livré, `fiabilite-v1.0` (107 Ko), est déjà replié ; le reste pèse 63 Ko. Options :
  - (a) archiver les 17 dossiers de phase du jalon, puis `--archive roadmap` ;
  - (b) garder les en-têtes `### Phase N` et archiver les corps à la main : environ 64,9 Ko pour un budget de
    65,5 Ko, marge d'environ 600 octets ;
  - (c) laisser le dépassement ou relever le budget des compartiments.
- **Q3 — BACKLOG.** 31 sujets restent ouverts, sans preuve de livraison :
  - Équivalent Codex des skills Type 1 ;
  - routage « crée une PR » ;
  - juges d'artefact de planning ;
  - formats de sortie des suites ;
  - `save()` de dag.sh ;
  - gate d'observance de mission-flow ;
  - AI Agents in Depth ;
  - ICM ;
  - template d'agent installable ;
  - AGTS-02 ;
  - couverture de check-agents ;
  - évasion par bloc fenced ;
  - blocs verify sans trap ;
  - dérive documentaire ;
  - protection de main côté GitHub ;
  - index ADR-071 ;
  - test-scaffold-docs cas 22 ;
  - corpus de skills en dérive ;
  - vf-mcp-consumer ;
  - écart D-08(b) ;
  - collision de noms A2 ;
  - grilles des juges ;
  - socle du bootstrap sous 2 000 tokens ;
  - inject-mcp-tools --verify ;
  - recalc-planning.sh ;
  - faux rouge de test-vibeflow-update ;
  - EnterWorktree en lab plat ;
  - vf_ws_enumerate et le saut de ligne ;
  - vf_ws_enumerate et `found=1` ;
  - résidus de la 41.3 ;
  - recette de /vf-split-planning.

  Trois déclencheurs sont déjà levés : AI Agents in Depth, puisque fiabilite-v1.0 est clos ; le corpus de skills,
  à 32 avertissements ; le socle du bootstrap, à 2 610 tokens. L'entrée ICM est PARTIELLE : seul G4 reste. Pour
  EnterWorktree, il faut attendre le merge de la 57.
- **Q4 — F-3 en lab plat.** Le corriger change le lab plat. L'A/B « au bit près » contre la copie gelée doit alors
  être rebasé (P57-D-42).
- **Q5 — même classe, hors mandat.** Des formes passent encore (ALLOW) :
  - les globaux git à argument : `--git-dir <p>`, `--config-env=`, … ;
  - les wrappers à option-argument : `env -u`, `nice -n`, `exec -a`, `bash -c` ;
  - `export GIT_INDEX_FILE` dans un autre segment ;
  - `takeover --ws`, qui ne sonde pas l'ancien verrou (AUD-6).
  Il faut décider : corriger, ou laisser en limite écrite (CONCERNS b, c, e).
- **Q6 — épingle R-7.** Une même PR peut modifier la fixture et son épingle sans rien faire rougir. `tests/fixtures/`
  n'est pas dans la surface G-2 (AUD-3). Faut-il étendre G-2 ? C'est un changement de gate.
- **Q7 — prose des autres managers.** `vf-content-manager`, `vf-business-manager` et `vf-growth-manager` écrivent
  encore « stale-requires-takeover → takeover » sans le cas `recover`. Les corriger demande un bump de leurs trois
  modules, que je n'ai pas fait.

## Rejeu de fin de mission (HEAD e6241a95)

- Job `gates` de ci.yml, par `replay-ci-jobs.sh` sous un HOME neuf : 19 étapes rejouées, 3 sautées
  (conditionnelles à main ou à une action), 0 en échec.
- Job `tests` : 102 suites, 98 vertes. Les 4 rouges viennent de l'environnement : le moteur gsd-core est absent
  d'un HOME neuf, alors que la CI l'installe et que le rejeu saute cette étape.
  - Les suites concernées sont `test-dag.sh` (stages calculés par `~/.claude/gsd-core`),
    `test-check-planning-not-inflight.sh`, `test-split-planning.sh` et `test-check-gsd-config.sh`.
  - Rejouées sous le HOME réel (moteur présent), les quatre sont vertes : 161/0, 37/0, 69/0 et 37/0.
- `check-divergence.sh` : rc 0. `check-machine-paths.sh` et `check-mission-exit.sh` : voir le rapport compact.

## Preuves E6

Verdicts relayés verbatim depuis les blocs typés des workers et depuis le rejeu du manager.

```json
{"preuves": [
 {"verdict": "recette", "commande": "bash plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh", "exit_code": 0, "sha": "5eccb6e0"},
 {"verdict": "recette", "commande": "bash plugin/conductor/scripts/tests/test-driver-lock-ws.sh", "exit_code": 0, "sha": "5eccb6e0"},
 {"verdict": "recette", "commande": "bash plugin/conductor/scripts/tests/test-check-description-fidelity.sh", "exit_code": 0, "sha": "5eccb6e0"},
 {"verdict": "recette", "commande": "bash plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh", "exit_code": 0, "sha": "5eccb6e0"},
 {"verdict": "audit", "commande": "bash plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh", "exit_code": 0, "sha": "c580b45e"},
 {"verdict": "revue", "commande": "bash plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh", "exit_code": 0, "sha": "c580b45e"},
 {"verdict": "recette", "commande": "bash plugin/conductor/scripts/tests/test-dag.sh", "exit_code": 0, "sha": "e6241a95"}
]}
```

## Next step

Arbitrer Q1 à Q7, puis ouvrir la PR de `feat/phase-57-verrou-compartiment` vers `main`, sur demande explicite de
Samuel. Les questions ne bloquent pas la PR : aucune ne touche un critère de la Phase 57.

## Tour 2 — arbitrages Q1 à Q7 (2026-10-13), EN ATTENTE D'ARBITRAGE

Arbitrage Samuel, AskUserQuestion session principale, 2026-10-13. État au commit qui ajoute cette section :

- Faits et prouvés (RED puis GREEN, mutants tués) :
  - Q1 : `f162a9c3`, `070fe50d`, `6d63fb54`, `42d490b1` ;
  - Q2 : `4a8535ee`, 17 dossiers vers `.planning/milestones/fiabilite-v1.0-phases/` selon l'étape `archive_phases` de
    gsd-cleanup ; ROADMAP à 63 376 octets ;
  - Q4/Q5 guard : `719099dc`, `4fd77ed3` ;
  - Q5 takeover : `a038c8b6` ;
  - Q6 : `f76de68b`, `3e426f02`, `42d490b1` ;
  - Q7 : `576ba249`.
- Juges : l'audit rend `passed` avec 8 lows (AU2-01 à AU2-08) et 2 infos (AU2-09, AU2-10). La revue de remplacement
  rend `human_needed` : la référence A/B (RV3-01) remonte à Samuel. Le premier réviseur s'est figé sans rendre et a
  été remplacé.
- Bloquant : `check-divergence` est rouge en S4(b) depuis l'archivage (`completed_phases=18` pour 2 dossiers
  présents).
- Questions renvoyées à Samuel :
  - S4(b) ;
  - forme de la référence A/B ;
  - ancien verrou périmé face à `takeover --ws` ;
  - branche lue par le watchdog quand le verrou est partagé entre worktrees.
- Reste à faire après sa réponse :
  - une correction ciblée : AU2-01 à AU2-06 et AU2-08 à AU2-10, puis RV3-02, RV3-03, RV3-06 et RV3-07 ;
  - le chemin périmé de `workstream-planning-consumers.md:93` ;
  - les docs : CONCERNS, CHANGELOG conductor, prose D-33-E de `mission-flow.md`, « cinq classes » (CLAUDE.md, ADR-072,
    ci.yml), P57-D-44 et suivants ;
  - une revue et un audit de ce tour ;
  - le rejeu de fin de mission.

### Addendum : le premier réviseur a fini par rendre (2026-10-13)

Le premier réviseur n'était pas mort. Il a rendu `gaps_found` après son remplacement, avec deux findings majeurs :

- **F1 (Q1)** : la règle « un commit récent écarte le stall » n'est testée qu'en lab plat. Le mutant qui retire `eff()`
  sur la branche `locks` (lab partitionné, cas réel du dépôt) survit. Il faut un cas partitionné qui le tue.
- **F2** : correspond à la question A (S4(b)). L'étape CI `ci.yml:1290` rougira tant que la question n'est pas
  tranchée.

Il a aussi rendu des mineurs :

- F3 : CHANGELOG conductor, et « cinq classes » à corriger.
- F4 : correspond à AU2-10.
- F5 : `%ct` contre `%at`, aucun cas ne les distingue.
- F6 : `gw_ab_check` exige `seen > 0` et non `seen == GW_AB_ENUM_N`.
- F7 : la formulation de Q7 n'est épinglée par aucun test.
- F8 : correspond à AU2-04.

F1 et F6 rejoignent le tour de correction qui suivra les arbitrages.
