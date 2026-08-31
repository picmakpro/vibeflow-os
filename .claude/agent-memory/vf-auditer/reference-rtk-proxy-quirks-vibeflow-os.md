---
name: reference-rtk-proxy-quirks-vibeflow-os
description: Pièges d'outillage mesurés sur ce poste lors des audits infra vibeflow-os (rtk proxy, grep, diff, timeout absent)
metadata:
  type: reference
---

Sur ce poste, pour les audits touchant `vibeflow-os` (et probablement ses worktrees `-p23` etc.),
plusieurs outils habituels ne sont PAS fiables tels quels — mesuré, pas supposé, lors de l'audit
Phase 23 (`audit-infra`) :

- `git diff` sous le proxy `rtk` : la forme `A..B` rend une sortie résumée sans hunks (garde verte
  à vide). Utiliser la forme à DEUX ARGUMENTS `rtk proxy git diff A B`.
- `grep` proxifié TRONQUE silencieusement au-delà d'un certain nombre de lignes (mesuré : 31 lignes
  sur 102 rendues). Pour compter ou extraire exhaustivement : `awk`, `comm`/`cmp` sur listes
  matérialisées, jamais `grep -c` pour un total qui doit être exact.
- `diff` a déjà rendu "Files are identical" sur deux fichiers réellement différents — ne pas lui
  faire confiance comme preuve d'identité/différence sans un `cmp`/`awk` de contrôle.
- `timeout` n'existe PAS sur ce macOS. Pour borner l'exécution d'un script potentiellement bloquant
  (test de DoS/FIFO), lancer en arrière-plan (`&`), garder le PID, poller `kill -0` en boucle avec
  un budget de temps explicite, puis `kill -9` soi-même si le budget est dépassé.

Voir aussi [[feedback-execute-dont-trust-green]] pour la doctrine générale de vérification par
exécution sur ce projet.
