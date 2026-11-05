---
name: taskstop-proprietaire-seul
description: TaskStop n'arrête que ses propres tâches ; un parent ne peut pas stopper son agent enfant, et un « waiting on its own background work » n'est pas un retour
metadata:
  type: project
---

Mesuré le 2026-11-05 (mission workers orphelins, PR #210) :
- Un parent qui TaskStop son agent enfant reçoit « Task X is owned by X; agent Y cannot stop it ». Seuls l'agent lui-même et la session principale peuvent l'arrêter.
- Un worker qui rend la main avec un Bash vivant en fond reçoit le statut `completed` « waiting on its own background work » (résultat intermédiaire), et il reste vivant. Les 5 orphelins des 3-5 novembre venaient de commandes basculées en fond par le timeout Bash, jamais d'un run_in_background explicite.
- Avant le correctif, les managers et vf-coder n'avaient pas TaskStop dans `tools:`. check-agents l'exige désormais pour tout agent qui déclare Bash ou Agent.

**Why:** des managers fermaient l'enfant `close --status=done` sur le « waiting », donc le registre affichait 0 alors que l'enfant tournait encore.
**How to apply:** pour un enfant en « waiting », ne pas le fermer. Lui demander par SendMessage d'arrêter sa propre tâche. Ce qui reste vivant se relaie à main avec les agentId. Ma propre attente : `python3 time.sleep` ≤ 165 s, et tout run détaché (nohup) se tue avant de rendre. Voir [[verrou-driver-non-contraignant]] et [[joignabilite-asymetrique-manager-worker]].
