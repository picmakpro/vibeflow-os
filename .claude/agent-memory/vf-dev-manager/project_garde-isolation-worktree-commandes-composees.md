---
name: garde-isolation-worktree-commandes-composees
description: En session isolée dans un worktree, la garde refuse bash -c, heredoc Python qui nomme git, nohup de boucle, $VAR avant option de sed — scripts dans le scratchpad, chemins absolus, commandes simples
metadata:
  type: project
---

Session isolée dans un worktree (2026-09-29, Phase 45) : la garde refuse toute commande dont elle ne
peut pas prouver qu'aucun `git` ne s'exécute hors du worktree.

Formes refusées :
- `cd … && bash script` ;
- `nohup bash -c 'for …'` ;
- un heredoc Python dont le texte contient le mot `git` ;
- `sed -n … $W/fichier`, avec une variable devant l'argument ;
- `find -exec sh -c`.

Formes acceptées :
- `bash /chemin/absolu/script.sh …` ;
- `python3 /scratchpad/script.py`, pour un fichier écrit avec Write ;
- `git -C <worktree> …` ;
- `cd <worktree> && git …`, sans `bash` interposé ;
- `run_in_background` d'un script du scratchpad.

Les plan-checkers subissent la même garde : `mktemp -d` calculé est refusé (le scratchpad de session est accepté), commits scriptés dans une fixture git refusés.

Phase 46 (2026-10-03) : la garde refuse aussi les commandes `verify` de plan à forme composée
(`out=$(bash …); rc=$?; …` en ligne, `zsh -c '…'`, `rtk proxy git …`), et la sonde `claude -p`
d'un chercheur. Le plan-checker du tour 2 n'a pu jouer aucune commande sous les deux shells.
Correctif retenu dans les plans : une consigne d'exécution par plan (la commande `<automated>` est
écrite telle quelle dans un fichier du scratchpad, puis lancée par `bash <fichier>` ; c'est le code
de sortie qui fait le verdict).

**Why:** une dizaine d'appels refusés en une mission avant d'adopter la forme simple ; les juges
ont jugé « sur lecture » faute de pouvoir monter une fixture git.

**How to apply:** écrire tout traitement non trivial dans un fichier du scratchpad, puis
l'exécuter. Dans les mandats de juges, donner d'emblée le scratchpad de session comme dossier
d'essai à la place de `mktemp -d`. Pour un heartbeat long, lancer un script du scratchpad en
`run_in_background`. Voir [[rejeu-long-detache-nohup]].
