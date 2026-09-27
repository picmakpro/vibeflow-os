---
name: exit-gate-e4-suit-le-pointeur-workstream
description: check-mission-exit.sh E4 lit la ROADMAP du compartiment actif (pointeur = fiabilite) : sur une mission gouvernance, rc=0 « section introuvable » sans GSD_WORKSTREAM ; et execute-phase en vague parallèle crée des merges
metadata:
  type: project
---

`check-mission-exit.sh` (E4) résout ROADMAP/STATE via `workstream-policy.sh` : `GSD_WORKSTREAM` d'abord, sinon le pointeur partagé `.planning/active-workstream`, qui vaut `fiabilite` sur ce dépôt. Sur une mission du compartiment `gouvernance`, la commande nue du brief rend rc=0 `[E4] section introuvable pour l'étape 43` (constaté le 2026-09-26, Phase 43). Avec `GSD_WORKSTREAM=gouvernance`, le même rapport rend rc=3 SAIN.

**Why:** le brief impose de relayer le code tel quel. Un 0 lu comme « manque réel » ferait rouvrir une mission conforme, et un 3 obtenu en changeant la commande sans le dire serait un vert fabriqué.

**How to apply:** relayer les DEUX exécutions, la commande du brief (code verbatim) et celle avec `GSD_WORKSTREAM=<compartiment>`, en nommant la cause. Même famille que [[pointeur-workstream-partage-par-les-sous-agents]].

Corollaire de la même mission : `gsd-execute-phase` avec des exécuteurs parallèles en worktree intègre chaque plan par un commit de MERGE (vague 2 : 3 merges). Tout témoin qui compte `git rev-list --merges` sur la plage de phase rougit alors par construction. Il faut le vérifier au plan-check, sinon cela passe par un arbitrage en pleine exécution (option A de la 43 : ne compter que les merges dont un parent sort de la base). Voir [[execute-phase-filtre-par-vague-pas-par-plan]].
