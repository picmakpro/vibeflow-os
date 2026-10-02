---
name: rapport-de-mission-passe-les-gates
description: le rapport de mission est un fichier versionné — un chemin absolu dans le bloc E6 a rougi gates ET tests (check-machine-paths) après une livraison verte
metadata:
  type: feedback
---

Avant de pousser un rapport de mission, lancer `bash scripts/check-machine-paths.sh` (et tout gate qui scanne `.planning/`), puis attendre la CI du commit du rapport. Le 2026-10-02 (PR #132), la PR était verte à `deef907a`. Le commit du rapport `e5578b76` portait `--root /Users/samuel/...` dans une commande du bloc E6 : les jobs `gates` et `tests` ont rougi. Je l'ai découvert seulement parce qu'un juge en retard a signalé que le HEAD avait bougé.

**Why:** j'avais traité le rapport comme une trace hors code, « qui ne change pas l'arbre jugé ». Or la CI juge tout fichier suivi, et la clôture vient APRÈS le dernier rejeu.

**How to apply:** dans le bloc E6, écrire `<worktree>` / `<arbre>` à la place des chemins absolus. Rejouer `check-machine-paths` avant le push du rapport, et vérifier les checks de la PR sur le SHA du rapport avant de relâcher le verrou. Voir [[attestation-sur-sha-fige]], [[lire-la-ci-de-la-branche-des-la-reprise]].
