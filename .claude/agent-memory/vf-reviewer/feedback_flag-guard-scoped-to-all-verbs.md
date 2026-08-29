---
name: flag-guard-scoped-to-all-verbs
description: Une garde ajoutée dans le bloc de résolution --target/--scope s'exécute avant cmd="$1" — elle mord aussi les verbes en lecture seule (status, sync, aucune commande) si elle n'est pas explicitement scopée
metadata:
  type: feedback
---

Dans `vibeflow-update.sh`, le dispatch de sous-commande (`cmd="$1"`) arrive TRÈS tard (ligne
~2724) — tout le bloc de résolution `--target`/`--scope`/`--dry-run` s'exécute avant. Une garde de
sécurité ajoutée dans ce bloc (ex. refus de cible non vide, D-38-P) protège donc `install`
autant que `status`, `sync` (no-op documenté) et même l'appel SANS sous-commande (censé imprimer
l'usage et `exit 0`). Preuve (revue Phase 38, comblement `--target`) : `--target "$X" status` sur
une cible non vide sans registre échoue avec le même message « refusé pour éviter de disperser le
payload », alors que `status` ne pose jamais de payload — et `--target "$X"` seul (sans verbe)
casse le contrat documenté usage+exit0.

**Why:** trouvé par délégation `gsd-code-reviewer`, pas par ma propre première passe — j'avais
vérifié les 4 cas nominaux (install acceptés/refusés) mais jamais testé la garde contre un verbe
en lecture seule. Le fichier a DÉJÀ le bon pattern pour ce problème (`vf_dry_run &&
[ "$#" -gt 0 ]` puis `case "$1" in install|update|rollback`, ligne ~123-126) — un précédent que la
nouvelle garde n'a pas réutilisé.

**How to apply:** pour toute nouvelle garde posée dans ce bloc de résolution précoce, toujours
rejouer avec un verbe en lecture seule (`status`) et sans verbe du tout avant de conclure au PASS —
si la garde n'est pas explicitement scopée aux verbes qui écrivent, elle mord large par défaut.
