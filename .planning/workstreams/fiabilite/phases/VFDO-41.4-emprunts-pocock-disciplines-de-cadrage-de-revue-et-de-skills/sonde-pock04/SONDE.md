# Sonde POCK-04 — la revue à deux axes voit la tâche omise (P414-D-07)

**Sonde** : dispatcher `vf-reviewer` sur `diff-propre-omet-tache-2.patch` appliqué à `base/` (`patch -p1 -d <copie de base/> -i diff-propre-omet-tache-2.patch`), brief portant `MINI-PLAN.md` comme PLAN de l'étape (chemin relatif au dépôt : `.planning/workstreams/fiabilite/phases/VFDO-41.4-emprunts-pocock-disciplines-de-cadrage-de-revue-et-de-skills/sonde-pock04/MINI-PLAN.md`).

**Qui la joue** : le MANAGER seul, à la profondeur 1 (manager 1, `vf-reviewer` 2, `gsd-code-reviewer` 3) ; jamais un exécuteur, qui ne peut pas la jouer à cette profondeur.

**Attendu** : `axes.standards.statut = passed` ; `axes.spec.statut = gaps_found` avec un finding dont `ref` cite `MINI-PLAN.md` à la ligne de la Tâche 2 (l.25 ou l.27) ; statut global `gaps_found` ; findings Spec tagués `"axe": "spec"`.

**Consigner** : le bloc typé verbatim et le SHA du HEAD dans `41.4-SONDE-POCK04.md` (preuve E6).

**Invalide la sonde** : axe Spec `passed`, ou findings des deux axes fusionnés (un seul `review_path`, un seul rapport).
