# Mission 2026-11-05 — workers orphelins du team-kernel

Mandat : correctif à livrer avec la release groupée. Arbitrage Samuel, AskUserQuestion session
principale, 2026-11-05 : « Mandat maintenant (Recommandé) ». A1 : « Oui, dans ce correctif
(Recommandé) ». A2 : « Plus tard, en spike (Recommandé) ».

Branche `fix/team-kernel-workers-orphelins`, worktree `.claude/worktrees/fix-workers-orphelins`,
verrou `--ws=fiabilite` (owner `vfdm-workers-orphelins-20261105`).

## Plan de bataille (DAG)

diag-doc ∥ diag-forensic ∥ diag-repro (A, B, C, D) → exec (lot A1 ∥ lot doctrine, par pathspec)
→ revue → correction ciblée → re-revue → gates → PR + CI.

## Diagnostic (mesuré)

- **(b) confirmée, 5 orphelins sur 5** (147 transcripts vf-coder du 3 au 5 novembre) : le
  worker rend la main pendant qu'une commande Bash tourne en fond. Dans les 5 cas, la commande
  avait été basculée en fond par le timeout Bash (120 ou 600 s), jamais par un
  `run_in_background` explicite : boucle `pgrep -f` qui se trouve elle-même, serveur jamais
  arrêté, suite qui ne rend pas la main, mutant qui boucle.
- **Cause racine** : vf-coder et les managers n'ont pas TaskStop dans leur allowlist `tools:`.
  Sonde C : un vf-coder ne voit ni TaskStop, ni ToolSearch, ni Monitor, ni ListAgents.
  Transcripts : 2 TaskStop et 15 Monitor en échec sur `No such tool`.
- **Reproduction A/B** : un worker qui laisse un `sleep` en fond reçoit le statut « waiting on
  its own background work » et est ré-invoqué à la fin du `sleep`. Le même worker qui fait
  TaskStop avant de rendre reçoit « finished ».
- **Sonde D** : un parent ne peut pas arrêter son agent enfant. TaskStop rend « Task <enfant> is
  owned by <enfant>; agent <parent> cannot stop it ». Seuls l'agent lui-même et la session
  principale peuvent arrêter une tâche. Un TaskStop sur un identifiant inconnu liste les
  « Running background agents ».
- **(a) confirmée**, mais c'est une conséquence de la cause racine. **(c) partielle** : 4 des 5
  orphelins avaient été consignés puis fermés `done` sur le résultat intermédiaire « waiting ».

## Correctif

- `team-kernel.md` §Fin de tour inerte : source unique de la règle worker et de la règle
  manager. `mission-flow.md` §Pattern I est aligné sur cette section.
- TaskStop est ajouté à 15 agents (ceux qui ont Bash ou Agent). Chacun reçoit aussi une ligne de
  règle. Densité : vf-dev-manager reste à 250 lignes.
- A1 : `check-agents.sh` rougit (règle bloquante) tout agent qui déclare Bash, Agent ou Task sans
  TaskStop. Les témoins T121a à h et le mutant MUT-TS sont dans `test-check-agents.sh`.
- A2 : le hook SubagentStop est inscrit au BACKLOG, en spike.
- Versions : conductor v1.53.2, dev-orchestrator v2.31.1, design-orchestrator v1.5.17,
  mobile-test-team v1.4.9, content-bundle v2.0.18, growth-bundle v2.0.17,
  product-team-bundle v1.1.1, business-pilot-bundle v2.0.18.

## Revue

- Revue 1, `gaps_found` : 2 bloquants (test-guard-agent-write, regex `(Agent|Task)` qui attrapait
  TaskStop), 1 majeur (T27 affaibli), plus des mineurs. Tout est corrigé par une correction
  ciblée, avec mutants.
- Re-revue fraîche, `passed` : 3 mineurs consignés, sans action.

## Consignés, non corrigés

- m1 : un agent avec `disallowedTools: Bash` rougit quand même (faux positif rare).
- Message de takeover de `driver-lock.sh` (vers la ligne 1121), non aligné sur le message de
  reclaim.
- Trailer Gate-Touche mal formé dans f58292d0 : il est couvert par les 8 trailers du commit
  suivant (check-gate-touche rc=0).
- Les suites de bundles ne lisent que la forme `tools:` sur une ligne. `check-agents.sh` reste
  le filet.

## Preuves E6

```json
[
  {"verdict": "revue", "commande": "bash plugin/conductor/scripts/tests/test-check-agents.sh", "exit_code": 0, "sha": "78065f8e"},
  {"verdict": "revue", "commande": "bash plugin/conductor/scripts/tests/test-guard-agent-write.sh", "exit_code": 0, "sha": "78065f8e"},
  {"verdict": "revue", "commande": "bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh", "exit_code": 0, "sha": "78065f8e"},
  {"verdict": "revue", "commande": "bash scripts/check-gate-touche.sh", "exit_code": 0, "sha": "78065f8e"}
]
```
