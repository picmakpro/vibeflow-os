---
name: balayer-processus-des-workers
description: « waiting on its own background work » après un rapport = un processus égaré du worker (grep -r sur /tmp, serve --help | head) ; balayer par ps sur le chemin du scratchpad avant de rendre
metadata:
  type: feedback
---

Un worker qui a rendu son rapport mais que la notification dit « waiting on its own background
work » a laissé un processus vivant. Le 2026-11-06, deux cas en une mission : un `grep -rn` lancé via
`scratchpad/.../fx162/../../../../../../../tmp` (remonté à `/tmp` entier, 2 h 35 de vie) et un
`node serve.mjs --help | head -5` resté bloqué 2 h 09 (le worker disait « sorti seul »).

**Why:** ces processus survivent au worker, chargent un poste déjà saturé (charge 150 ce jour-là) et
démentent le « aucun PID restant » du rapport.

**How to apply:** avant le rapport final, `ps -axo pid,etime,command | awk '/<sous-dossier scratchpad>|<worktrees de la mission>/'`,
inspecter chaque ligne (`ps -o … -p`, `pgrep -P`), tuer par PID exact, jamais par motif
([[project_hygiene-test-tue-tout-awk-env]]). Lié à [[project_workers-orphelins-apres-manager]] et
[[feedback_scratchpad-partage-vert-emprunte]].
