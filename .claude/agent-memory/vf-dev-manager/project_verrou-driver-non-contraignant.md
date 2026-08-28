---
name: verrou-driver-non-contraignant
description: Le verrou de driver est déclaratif, pas contraignant — une mission élaguée par TTL peut continuer à commiter sans le ré-acquérir ; ne jamais présumer l'exclusivité du worktree
metadata:
  type: project
---

`driver-lock.sh` n'empêche RIEN techniquement : il n'y a ni hook ni garde en écriture qui refuse un
commit à une session sans verrou. Une mission dont le lock a été élagué par TTL continue à travailler
et à commiter comme si de rien n'était.

**Why:** constaté le 2026-07-27 sur `vibeflow-os`. Le lock de `mission-phase16` a été élagué par
récupération TTL, puis `mission-phase17` l'a acquis — et la Phase 16 a continué à commiter pendant
que la Phase 17 tenait le verrou. Horodatages entrelacés : 22:37 P16 · 22:38 P17 · 22:42 P16 ·
22:46 P16 (bump `plugin/dev-orchestrator` v2.4.0→v2.5.0) · 22:48 P17 · 22:50 P16. Conséquence
concrète : collision de numéro de version, la Phase 17 ayant planifié le v2.5.0 que la Phase 16
venait de prendre. Dette structurelle du module `conductor`, à inscrire dans
`.planning/codebase/CONCERNS.md`.

**How to apply:** tenir le verrou ne dispense pas de vérifier le worktree. Avant un nœud d'exécution
et à chaque retour de worker, relire `git log --oneline` pour détecter des commits étrangers à la
mission. Ne jamais dériver un numéro de version d'un plan écrit plus tôt : relire le `VERSION` réel
au moment du bump. Et battre le cœur du verrou PENDANT les dispatches longs (keeper en tâche de
fond), pas seulement entre les étapes — un worker de 45 min dépasse le TTL de 30 min et rend le lock
élaguable par n'importe qui.

Voir aussi [[relire-le-disque-avant-tout-rapport]] et [[verifier-contre-le-commit-de-base]].
