---
name: case-insensitive-fs-defeats-path-string-guard
description: Une garde de chemin en comparaison de chaînes (cd -P + pwd -P) est contournable sur macOS via une simple variation de casse — comparer par inode/device, pas par string
metadata:
  type: feedback
---

Une garde qui refuse `$HOME` (ou tout chemin sensible) en comparant deux résultats de
`cd -P "$X" && pwd -P` comme des CHAÎNES ne protège pas sur un filesystem insensible à la casse
mais préservant la casse (APFS/HFS+ par défaut sur macOS) : `pwd -P` renvoie la casse **telle que
demandée pour atteindre le chemin**, pas la casse stockée sur disque. `cd -P "$LAB/HOME"` et
`cd -P "$LAB/home"` résolvent le **même inode** mais produisent deux chaînes différentes
(`.../HOME` vs `.../home`) → la comparaison `[ "$A" = "$B" ]` échoue et laisse passer.

**Preuve (revue Phase 38, comblement `--target` D-38-P, 2026-08-29)** : `vibeflow-update.sh`
refusait `--target "$HOME"` littéral et résolu, mais `--target "$LAB/HOME"` (casse différente
d'un `$FAKE_HOME` = `$LAB/home`) passait la garde avec rc=0 et posait le payload complet dans le
vrai `$FAKE_HOME` — confirmé par `stat -f '%i'` identique sur les deux chemins ET par la présence
réelle du payload après coup. Le message d'erreur de la garde n'apparaissait jamais.

**Why:** ce n'est pas une négligence du coder — la doctrine D-31-15 (résolution physique via
`cd -P`/`pwd -P`) est correcte pour neutraliser symlinks et `../..`, mais ne neutralise PAS la
casse sur un FS case-insensitive. La confusion vient du fait que la garde semble « physique donc
robuste » alors qu'elle reste une comparaison de représentation textuelle.

**How to apply:** sur toute garde de chemin qui compare deux résolutions `cd -P`/`pwd -P` par
égalité de chaîne (particulièrement sur macOS, plateforme par défaut de ce repo), tester
explicitement une variante de casse du chemin protégé, avec vérification d'inode (`stat -f '%i:%d'`
ou équivalent) pour confirmer que c'est bien le même fichier physique avant de crier au bug. Le
correctif robuste est de comparer par inode/device plutôt que par chaîne, ou de canonicaliser la
casse avant comparaison. Lié à [[project_symlink-ancestor-bypasses-target-root-check]] (même
famille : une résolution "physique" incomplète laisse passer une classe de contournement précise).
