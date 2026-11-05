---
name: new-child-process-shifts-pgrep-first-child-probes
description: Ajouter un processus enfant à l'assistant PTY (gardien, mission pty-orphelin) décale les sondes `pgrep -P <assistant> | sed -n 1p` des suites existantes sans les rougir ; et `ps -o sess=` vaut 0 sous macOS
metadata:
  type: feedback
---

Un processus forké AVANT le shell (gardien de vf-cockpit-pty.py, v1.3.1) devient le premier enfant de l'assistant : `shell_de()` de `test-cockpit-terminal-session.sh` (`pgrep -P "$a" | sed -n 1p`) rend désormais le gardien, pas le shell. La suite reste 57/0 : T12.2 (« même shell ») et T12.3 (shell disparu) observent le gardien, assertions affaiblies sans rougir (prouvé par `pgrep -P` + `ps` sur un assistant lancé à la main).

**Why:** une suite verte ne prouve pas que ses sondes visent toujours la même cible après l'ajout d'un enfant ; le diff ne touchait aucune assertion, donc la revue par le diff ne le voit pas.

**How to apply:** à toute revue qui ajoute un processus dans l'arbre d'un assistant/serveur, grep les `pgrep -P` des suites voisines et vérifier quelle cible elles désignent réellement. Sous macOS, `ps -o sess=` rend 0 pour tout le monde : un `dans-session=N` fondé dessus est tautologique localement (réel sous Linux). Une propriété de « fds hérités » (EOF des tubes côté serveur) ne se mesure qu'avec un survivant têtu (`trap '' HUP; exec sleep`) : sans lui le gardien vit trop peu pour retarder l'EOF (mutant sans dup2 : 0,06 s sans têtu, 3,14 s avec).
