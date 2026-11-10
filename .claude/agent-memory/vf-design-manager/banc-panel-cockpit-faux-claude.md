---
name: banc-panel-cockpit-faux-claude
description: Monter un banc de juges sur le cockpit sans vraie session Claude — pièges du PATH zsh, du chat claude -p, de l'amorce terminal 60 s et du panneau Format masqué sur un lab conforme
metadata:
  type: feedback
---

Un faux `claude` en tête du PATH ne suffit pas : le terminal du cockpit lance `zsh -l`, et `~/.zshrc` de Samuel re-préfixe `~/.local/bin` (le vrai claude). Il faut aussi un `ZDOTDIR` isolé dont `.zshrc`/`.zlogin` remettent le faux en tête, puis vérifier `command -v claude` DANS le terminal de la page avant tout dispatch. Le chat de l'onglet Projet appelle `claude -p` via `which` côté serveur : `FLOORPLAN_CLAUDE=<faux>` plus un faux qui rend un `result` stream-json avec `structured_output`.

Autres pièges (panel du 2026-11-06) : `--no-open --terminal` écrit une amorce valable 60 s, la page doit être ouverte en `project.html#t=<amorce>` (relancer `open` sur un serveur vivant ré-amorce) ; le panneau « Format de la planification » est masqué quand le lab est conforme, aucun juge ne l'a vu au tour 1, il a fallu injecter une dérive et relancer les juges ; le scratchpad est partagé entre managers parallèles, travailler dans un sous-dossier dédié.

**Why:** un juge qui appuie sur Entrée dans le terminal lancerait sinon une vraie session ; un état masqué par défaut n'est jamais jugé.

**How to apply:** à tout panel ou recette Playwright du cockpit, reprendre ce montage (relais `cockpit.sh` du panel) et vérifier la liste des états à fabriquer avant le dispatch. Voir [[reprise-apres-crash-transcripts]].

Recette du 2026-11-08 (PR #218) : le vrai `claude` existe AUSSI dans `/usr/local/bin` et `/opt/homebrew/bin`, et le `path_helper` de `zsh -l` met `/usr/local/bin` devant : avec `env -i HOME=<home isolé>`, poser `.zshrc`, `.zlogin` et `.zprofile` dans ce HOME qui re-préfixent le faux, puis vérifier `command -v claude` dans le terminal de la page. Banc complet rejouable : `setup-lab.sh` + `cockpit.sh <profil>[-old] open|url|stop` (version jointe 4461-4464, v2.76.0 4481-4484 via `git archive <commit> plugin`, sans worktree), titres /rename injectés par une ligne `{"type":"custom-title","customTitle":…}` dans le transcript de session, secrets factices par une ligne `tool_use` Bash ajoutée aux transcripts d'agents actifs.

L'état attendu par proposition se dérive des messages de commit (`rtk proxy git log --format=%s%n%b`, et parser les listes « PU-G-026, 027 » et les plages « PU-G-163 à 190 », pas seulement l'identifiant préfixé) recoupés avec CHANGELOG § Non publié et BACKLOG ; `rtk` filtre `grep` et `git log` sans prévenir : passer par `rtk proxy`.
