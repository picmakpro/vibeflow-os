---
name: project-phase68-reaudit-partiel
description: Re-audit Phase 68 (HEAD 6b76c42c, 2026-11-04) INTERROMPU par le manager : seules 2 sondes executees (script plante, fsmonitor) ; le reste lu sans sonde ; ST-2 + gating par registre du lab = un meme arbitrage
metadata:
  type: project
---
Sondees (temoin positif) : driver-lock.sh plante dans lab (.claude/scripts, plugin/conductor, .vibeflow/cockpit) avec HOME=reel/lab/lab-home jamais execute, verrous lus via conductor voisin ; core.fsmonitor du .git/config non execute par l emetteur alors que git status nu l execute.
Non sondes : filter.clean (temoin negatif aveugle : meme git nu ne l a pas declenche), fuzz ANSI global, secrets, DoS taille/nombre de worktrees, absence de reseau, mod en harnais.
Lu : gating.ts lit .claude/scripts/.vibeflow-installed du LAB (cockpit=) => un depot peut allumer le mod et le bouton "Ouvrir le cockpit" qui execute <lab>/.claude/scripts/vf-cockpit.mjs (actions.ts:36-42) : meme famille que ST-2, a arbitrer par Samuel.
**How to apply:** reprendre par le fuzz ESC+U+009B sur tout le JSON signal@1 et par la sonde de taille (DAG enorme, 200 worktrees).
