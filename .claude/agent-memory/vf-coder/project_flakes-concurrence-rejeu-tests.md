---
name: flakes-concurrence-rejeu-tests
description: Sur vibeflow-os, --job tests rend « 86 suites / 1 échec » sur des suites DIFFÉRENTES d'un rejeu à l'autre ; la contre-épreuve est le rejeu ISOLÉ, pas un second rejeu complet.
metadata:
  type: project
---

`replay-ci-jobs.sh --job tests` (outil de la Phase 40.1, sous
`.planning/workstreams/fiabilite/phases/VFDO-40.1-*/tools/`) rougit régulièrement à **une** suite
sur 86, et **pas la même d'un run à l'autre**. Mesuré le 2026-09-24, deux rejeux consécutifs sur un
diff de **prose seule** (3 fichiers `docs/`+`plugin/`) :

| Run | Suite | Cas | En isolation |
|---|---|---|---|
| 1 | `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | `T2b scope=local` (stubs PATH claude/npm/node) | `227 OK / 0 KO / 0 SKIP` |
| 2 | `plugin/conductor/scripts/tests/test-check-agents.sh` | `T32` | `82 OK · 0 KO` |

**Why:** le rejeu lance les 86 suites dans un même environnement (PATH, `mktemp`, npm) et des
sessions concurrentes tournent sur d'autres worktrees. `test-check-agents.sh` a en plus son motif
SIGPIPE connu (`OUT="$(…)"` puis `echo "$OUT" | grep -q`) — T9, T29, et maintenant **T32** :
la liste des cas atteints n'est pas figée, ne t'attends pas à retrouver le même numéro.

**How to apply:** un rouge de `--job tests` ne se conclut **jamais** sur le compte global. Rejoue la
suite nommée **isolément dans le même arbre** — c'est ça la contre-épreuve. Un second rejeu complet
ne tranche rien : il peut rougir ailleurs et te faire croire à deux régressions. Puis vérifie le
**découplage** (`git diff --stat` de tes commits ∩ ce que le cas lit réellement) et **consigne sans
toucher** — voir [[fragment-hooks-casse-test-manifest]] pour le même réflexe côté `test-manifest.sh`.
