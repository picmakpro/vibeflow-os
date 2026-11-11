---
name: q-lance-depuis-la-copie-du-lab
description: Le processus Q du terminal cockpit s'importe depuis la copie .vibeflow/cockpit/ du lab servi, pas depuis VF_COCKPIT_SCRIPTS_DIR ; un lab de sonde doit être resynchronisé après chaque édition de vue/client/page de Q.
metadata:
  type: project
---

Sonde navigateur d'un correctif du bandeau (Phase 72, lot 8 LB2, 2026-11-06) : `VF_COCKPIT_SCRIPTS_DIR` ne pilote
que la page P ; le fils Q (`vf-cockpit-terminal-processus.mjs`) importe `vf-cockpit-terminal-vue/client/page/style.mjs`
depuis le dossier du lab (`<lab>/.vibeflow/cockpit/`). Premier réflexe faux : relancer le serveur et voir l'ANCIENNE
interface (capture « Lancer » alors que la vue du worktree disait « Préparer dans le terminal »).

**Why:** une capture « après » prise sur l'ancienne copie passe pour une preuve et ne prouve rien.
**How to apply:** avant toute capture, `cp` les modules de Q du worktree dans la copie du lab puis redémarrer le serveur
(script `sync.sh` du scratchpad) ; ne copier QUE les fichiers modifiés par soi : synchroniser aussi `vf-cockpit-server.mjs`
ou `-embed.mjs` d'un worktree plus récent que le `serve.mjs` du lab casse l'amorçage (le cadre n'apparaît jamais).
Le port de Q est tiré par le serveur (pas dans la plage donnée au mandat) : le noter pour le tuer par PID.
