---
name: force-push-refuse-classifieur
description: Le classifieur de permissions refuse git push --force-with-lease, même sur la branche de la mission ; « bump isolé en dernier commit » ne tient plus une fois la PR poussée
metadata:
  type: project
---
Le 2026-11-06 (PR #215), un `git push --force-with-lease=<branche>:<sha>` sur ma propre branche de mission a été refusé par le classifieur auto mode (« Git Destructive »). Le vf-coder l'avait déjà refusé de lui-même, parce que l'autorisation venait d'un agent.

**Why:** la consigne d'ordonnancement « bumps isolés dans le DERNIER commit » oblige à réécrire la branche après chaque correction. Tant que la branche n'est pas poussée, cela passe. Une fois poussée, il faut un force-push, qui est refusé.

**How to apply:** pousser la PR seulement quand les juges sont clos. Sinon, poser les corrections suivantes en avance rapide après le bump, garder en local la version isolée (même arbre, vérifié par `git diff` vide) et la signaler dans la PR. Ne jamais contourner le refus. Voir [[halt-tardif-cherry-pick-pas-stash]].
