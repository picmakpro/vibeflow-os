---
name: harness-worktree-refuse-scripts-non-suivis
description: En worktree isolé, le harness refuse `bash <script non suivi>`, les pipes composés et git via rtk ; rejouer la CI par l'outil suivi replay-ci-jobs.sh de la 40.1
metadata:
  type: project
---

En worktree isolé (hotfix v2.63.2, 2026-09-17), le harness du manager refuse plusieurs formes de commande :
- `bash` sur un script non suivi, même copié dans un dossier ignoré ;
- `bash` suivi d'un pipe, avec `$PIPESTATUS` ;
- `sed -i` enchaîné par `&&` ;
- `git` passé par `rtk proxy`.

Il accepte :
- `cd <wt> && bash <script SUIVI> args`, y compris `| tail` ou `| awk` ;
- `/usr/bin/git -C <wt> …` en commande simple ;
- `python3 -c` pour les éditions de fichier.

**Why:** le harness ne peut pas prouver qu'un script non suivi ne lance pas git hors du worktree. Une heure s'est perdue à extraire les `run:` de ci.yml avant de trouver l'outil déjà versionné.

**How to apply:** pour rejouer la CI, lancer `bash .planning/phases/VFDO-40.1-r-vision-adr-029-et-du-gate-du-budget-d-instructions/tools/replay-ci-jobs.sh --job gates` puis `--job tests`. Cet outil respecte déjà `bash -e` sans pipefail et saute les étapes `if:`. Pour obtenir un code de sortie, `> /dev/null 2>&1 || echo $?`. Les workers ne subissent pas tous ces refus. Voir [[rejeu-ci-avec-le-mauvais-shell]].
