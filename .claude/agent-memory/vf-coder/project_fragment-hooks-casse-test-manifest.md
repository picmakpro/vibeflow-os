---
name: fragment-hooks-casse-test-manifest
description: Phase 38 lot 2 — test-manifest.sh (T6/TD1, software-architecture.json) rouge en concurrence, hors périmètre du mandat de correction ciblée
metadata:
  type: project
---

Pendant le mandat de correction ciblée du lot 2 (RUNT-01/02, findings garde T9e / véracité
« confirmé » / test dispatch réel), `bash plugin/_internal/tests/test-manifest.sh` rendait 2 KO
(T6, TD1) sur `.vibeflow-fragments/software-architecture.json` — manquant du manifeste / manquant
au plan dry-run. Aucun des 4 fichiers autorisés par le mandat (runtime-cli-dispatch.sh, les 2
CHANGELOG, test-design-orchestrator.sh) ne touche à `vibeflow-update.sh` ni à la logique de
manifeste ; `git status` confirmait aussi des modifications non miennes en cours dans le même
worktree scratch (memory files, `vibeflow-update.sh` en cours de réécriture par un autre worker
au même instant, cf. digest de mission).

**Why** : un `find plugin scripts -type f` / suite complète rejoué dans un worktree scratch
partagé avec un autre worker en cours d'écriture peut faire remonter un rouge qui n'est PAS une
régression du mandat courant — c'est le même risque que « ne jamais lancer plusieurs rejeux en
parallèle sur un même worktree scratch » (47 faux échecs déjà constatés une fois côté manager).

**How to apply** : avant de traiter un test rouge hors du périmètre de fichiers explicitement
autorisé par le mandat, vérifier `git diff --stat` sur SES fichiers modifiés seulement ; si le
test rouge ne recoupe aucun fichier touché, le signaler comme bruit de concurrence dans le rapport
plutôt que de le corriger (le mandat interdit explicitement de toucher `vibeflow-update.sh`).
Voir [[project_check-agents-scope]] pour le même réflexe de vérifier le périmètre réel avant
d'agir sur un signal rouge.
