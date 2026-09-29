---
name: racine-session-fixe-worktree-execution
description: Règles de worktree du head — la racine de session fixe où les agents exécutent (jamais de `cd` nu) ; hooks/scripts gitignorés absents des worktrees → liens symboliques à poser à chaque création
metadata:
  type: project
---

**1. La racine de session fixe le worktree d'exécution.** Le « Primary working directory » décide où les agents exécutent, quel que soit leur `cd`. Incident du 2026-09-24 (Phase 42) : un `cd .claude/worktrees/phase-41` du head, pendant un simple état des lieux, a déplacé la racine de la session principale. `Agent(isolation="worktree")` a forké les exécuteurs depuis la branche de la 41, et le cwd Bash des agents revenait à `phase-41` : 3 exécuteurs arrêtés par leurs gardes de branche, une vague (~260k jetons) perdue. Récidive du 2026-09-28 : un `cd` dans un sous-dossier du worktree 44 a déplacé la racine dans ce sous-dossier.

**Why:** une exécution perdue et une escalade humaine alors que les plans étaient prêts.

**How to apply:** lire un autre endroit avec `git -C <chemin>` ou des chemins absolus, jamais un `cd` nu — pas même dans un sous-dossier du worktree courant. Avant de dispatcher une mission qui exécute, comparer `pwd` (sans `cd`) au worktree cible ; s'ils diffèrent, `EnterWorktree path=<cible>`, puis deux agents de test en lecture seule (un normal, un `isolation: worktree`). `EnterWorktree name=` part du HEAD local, pas d'`origin/main` : réaligner par `git reset --hard origin/main` sur la branche neuve. Une session dans un worktree refuse d'écrire hors de lui (`CLAUDE.local.md`, mémoire du checkout principal) : `ExitWorktree keep` ramène à la racine d'avant l'entrée — jamais pendant qu'une équipe travaille depuis cette racine.

**2. Les hooks et scripts de `.claude/` n'existent pas dans les worktrees** (constat du 2026-09-28). `.claude/*` est ignoré par git (`.gitignore:24`), donc `.claude/hooks/` et `.claude/scripts/` ne sont pas recopiés. Les hooks déclarés en `"$CLAUDE_PROJECT_DIR"/.claude/...` échouent en non bloquant : les gardes GSD (secrets, écritures, lecture) et `guard-driver-lock.sh` ne protègent rien dans un worktree.

**Why:** un garde qui échoue sans bloquer est un garde désactivé, en silence.

**How to apply:** à la création de chaque worktree, poser `ln -s <checkout principal>/.claude/hooks .claude/hooks` et idem pour `.claude/scripts` (ignorés par git, rien à commiter). Ne pas réécrire les commandes de hooks pour aller chercher le checkout principal : `guard-driver-lock.sh` se situe par `BASH_SOURCE` et viserait alors le mauvais dépôt ; le lien garde le chemin du worktree. Correctif durable : côté installeur, BACKLOG « hooks GSD introuvables dans les worktrees » (Samuel). Voir [[rejeu-ci-gates-bash-e]].
