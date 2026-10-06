# Sonde POCK-04 — la revue à deux axes voit la tâche omise (P414-D-07)

**Sonde** : dispatcher `vf-reviewer` sur `diff-propre-omet-tache-2.patch` appliqué à `base/` (`patch -p1 -d <copie de base/> -i diff-propre-omet-tache-2.patch`), brief portant `MINI-PLAN.md` comme PLAN de l'étape (chemin relatif au dépôt : `.planning/workstreams/fiabilite/phases/VFDO-41.4-emprunts-pocock-disciplines-de-cadrage-de-revue-et-de-skills/sonde-pock04/MINI-PLAN.md`).

**Qui la joue** : le MANAGER seul, à la profondeur 1 (manager 1, `vf-reviewer` 2, `gsd-code-reviewer` 3) ; jamais un exécuteur, qui ne peut pas la jouer à cette profondeur.

**Attendu** : `axes.standards.statut = passed` ; `axes.spec.statut = gaps_found` avec un finding dont `ref` cite `MINI-PLAN.md` à la ligne de la Tâche 2 (l.25 ou l.27) ; statut global `gaps_found` ; findings Spec tagués `"axe": "spec"`.

**Consigner** : le bloc typé verbatim et le SHA du HEAD dans `41.4-SONDE-POCK04.md` (preuve E6).

**Propreté du diff côté Standards** (revue W1, 2026-10-06) : au premier tour, le diff « propre » rendait `gaps_found` côté Standards (code 2 de `grep` masqué par `|| true`, pas de `--`, options inconnues et arguments en trop ignorés). Le patch est désormais réellement propre : code de `grep` propagé (2 = lecture impossible), `--` avant le fichier, option inconnue et argument en trop refusés (usage, 64), `-q` sans sortie y compris en erreur de lecture (seul le message documenté va sur stderr), codes 0/1/2/64 documentés en en-tête. La Tâche 2 (`--version`) reste OMISE : l'option est refusée comme inconnue (64). Seule la divergence au PLAN doit donc faire rougir la revue.

**Invalide la sonde** : axe Spec `passed`, ou findings des deux axes fusionnés (un seul `review_path`, un seul rapport).
