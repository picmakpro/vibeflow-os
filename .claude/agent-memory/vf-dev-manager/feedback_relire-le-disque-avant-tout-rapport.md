---
name: relire-le-disque-avant-tout-rapport
description: Ne jamais décrire l'état d'une mission de mémoire — re-constater sur disque (git log + ls) juste avant d'écrire le rapport, surtout après un dispatch qui a semblé échouer
metadata:
  type: feedback
---

Avant TOUT rapport d'étape ou de mission, re-constater l'état par `git log --oneline` + `git status`
+ `ls` des chemins concernés. Ne jamais décrire un état à partir de ce qu'on croit avoir dispatché.

**Why:** le 2026-07-27, un message d'interruption d'outil (`Request interrupted by user for tool use`)
sur un dispatch de `vf-coder` m'a fait conclure que le worker n'avait jamais tourné. J'ai rendu un
rapport affirmant « aucun fichier de `plugin/**` touché, l'implémentation n'a pas commencé » et
proposant de remettre le nœud en `ready`. En réalité le worker avait travaillé 37 minutes et produit
10 commits (scripts, fragment de hooks, bump de version). Le coordinateur a dû me corriger, avec la
consigne explicite : « ne me crois pas sur parole, c'est précisément ce qui t'a fait dériver ».
Un message d'interruption ne prouve RIEN sur ce que le sous-agent a déjà écrit sur disque.

**How to apply:** au retour de tout worker — y compris et surtout quand il a semblé échouer, être
interrompu, ou mourir sur erreur API — la première action est de re-constater le disque, jamais de
marquer le DAG ou de rédiger. Un nœud ne passe `failed` qu'après avoir vérifié qu'il n'a rien laissé ;
un agent tué en cours d'écriture peut avoir commité l'essentiel. Vaut aussi pour le verrou
(`driver-lock.sh status`) et pour les versions (`cat */VERSION`).

Voir aussi [[verifier-contre-le-commit-de-base]] : même exigence, appliquée aux affirmations des
workers plutôt qu'aux miennes.
