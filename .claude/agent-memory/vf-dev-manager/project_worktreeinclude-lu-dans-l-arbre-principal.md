---
name: worktreeinclude-lu-dans-l-arbre-principal
description: `.worktreeinclude` est lu dans l'arbre de travail du checkout principal, pas dans le commit de base du worktree ; les worktrees du harness partent d'origin/main, pas de HEAD
metadata:
  type: project
---

Mesuré le 2026-09-29 (Phase 41.3, deux sondes `isolation: worktree` avec témoins ignorés) : les
worktrees d'agent partaient de `6e7c40d7` (origin/main), PAS du HEAD de la branche de mission, et
pourtant la ligne `.claude/hooks/` ajoutée seulement sur la branche a agi — retirée de l'arbre de
travail principal (non commitée), le témoin disparaît. Témoin positif `.claude/agent-memory/`,
négatif `.claude/logs/` (non listé).

**Why:** un worker en isolation ne voit PAS le code de la branche de mission (il part de main),
mais hérite des fichiers ignorés selon l'état NON COMMITÉ du checkout principal. Une sonde ou un
worker isolé qui « teste la branche » teste en fait main.

**How to apply:** pour prouver une règle `.worktreeinclude`, un contrôle causal par retrait
temporaire de la ligne dans l'arbre principal suffit (pas de commit) ; ne jamais dispatcher un
worker isolé pour valider du code de la branche. Lien : [[baseref-head-contamine-les-mesures-isolation]].
