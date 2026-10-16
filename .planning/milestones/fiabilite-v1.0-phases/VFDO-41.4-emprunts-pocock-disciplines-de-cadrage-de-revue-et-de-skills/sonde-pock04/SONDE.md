# Sonde POCK-04 — la revue à deux axes voit la tâche omise (P414-D-07) et la convention violée (P414-D-21)

Deux sondes (P414-D-21 : la fixture de P414-D-07 est étendue, jamais contredite) : **sonde 1** ci-dessous (diff propre qui omet une tâche) et **sonde 2** en fin de fichier (fixture inverse, sous `inverse/`). Chacune est rejouée par le manager et consignée en preuve E6.

## Sonde 1 — diff propre qui omet la Tâche 2

**Sonde** : dispatcher `vf-reviewer` sur `diff-propre-omet-tache-2.patch` appliqué à `base/` (`patch -p1 -d <copie de base/> -i diff-propre-omet-tache-2.patch`), brief portant `MINI-PLAN.md` comme PLAN de l'étape (chemin relatif au dépôt : `.planning/workstreams/fiabilite/phases/VFDO-41.4-emprunts-pocock-disciplines-de-cadrage-de-revue-et-de-skills/sonde-pock04/MINI-PLAN.md`).

**Qui la joue** : le MANAGER seul, à la profondeur 1 (manager 1, `vf-reviewer` 2, `gsd-code-reviewer` 3) ; jamais un exécuteur, qui ne peut pas la jouer à cette profondeur.

**Attendu** : `axes.standards.statut = passed` ; `axes.spec.statut = gaps_found` avec un finding dont `ref` cite `MINI-PLAN.md` à la ligne de la Tâche 2 (l.25 ou l.27) ; statut global `gaps_found` ; findings Spec tagués `"axe": "spec"`.

**Consigner** : le bloc typé verbatim et le SHA du HEAD dans `41.4-SONDE-POCK04.md` (preuve E6).

**Propreté du diff côté Standards** (revue W1, 2026-10-06) : au premier tour, le diff « propre » rendait `gaps_found` côté Standards (code 2 de `grep` masqué par `|| true`, pas de `--`, options inconnues et arguments en trop ignorés). Le patch est désormais réellement propre : code de `grep` propagé (2 = lecture impossible), `--` avant le fichier, option inconnue et argument en trop refusés (usage, 64), `-q` sans sortie y compris en erreur de lecture (seul le message documenté va sur stderr), codes 0/1/2/64 documentés en en-tête. La Tâche 2 (`--version`) reste OMISE : l'option est refusée comme inconnue (64). Seule la divergence au PLAN doit donc faire rougir la revue.

**Correctif du tour 3 (2026-10-06, corr-c, P414-D-21)** : l'opérande `-` est refusé partout (usage, 64), `--` compris, et documenté en en-tête (l'entrée standard n'est pas prise en charge ; un fichier nommé « - » se désigne par `./-`) ; la cause de l'erreur de lecture est qualifiée (absent, répertoire, illisible) et le nom du fichier est affiché échappé (`%q`) ; un échec d'écriture sur stderr ne change jamais le code de sortie (`|| true`) et celui d'écriture de la sortie vaut 2, documenté ; l'en-tête est cohérent avec les codes. Sondé : fichier plein, vide, absent, répertoire, illisible, `-h`, `-q -q`, `f -q` (64), `-` (64), `-- -` (64), `./-`, nom à saut de ligne, stdout et stderr fermés.

**Invalide la sonde** : axe Spec `passed`, ou findings des deux axes fusionnés (un seul `review_path`, un seul rapport).

## Sonde 2 — fixture inverse : plan entièrement implémenté, convention écrite violée (P414-D-21)

**Sonde** : dispatcher `vf-reviewer` sur `inverse/diff-conforme-au-plan-viole-convention.patch` appliqué à `inverse/base/` (`patch -p1 -d <copie de inverse/base/> -i inverse/diff-conforme-au-plan-viole-convention.patch`), brief portant `inverse/MINI-PLAN.md` comme PLAN de l'étape (chemin relatif au dépôt : `.planning/workstreams/fiabilite/phases/VFDO-41.4-emprunts-pocock-disciplines-de-cadrage-de-revue-et-de-skills/sonde-pock04/inverse/MINI-PLAN.md`) et `inverse/base/CONVENTIONS.md` (présent dans la copie) comme convention écrite du lot pour l'axe Standards.

**Qui la joue** : le MANAGER seul, à la profondeur 1, comme la sonde 1.

**Nature du diff** : le patch implémente EXACTEMENT les trois tâches du plan (chaque comportement, message et code de sortie ; tous les `<done>` passent, vérifiés), sans rien de plus, et viole UNE convention écrite : le message d'erreur est écrit sur la sortie standard (`echo "erreur: $1"`) alors que `CONVENTIONS.md` n°2 exige la sortie d'erreur. Le plan ne fixe pas le flux ; ses `<done>` capturent `2>&1`, donc aucun ne change.

**Attendu** : `axes.spec.statut = passed` (aucun finding Spec bloquant ou majeur) ; `axes.standards.statut = gaps_found` avec au moins un finding de sévérité majeure dont la description cite `CONVENTIONS.md` (règle 2, flux d'erreur) et dont `ref` pointe `saluer.sh` à la ligne du `echo "erreur: …"` ; statut global `gaps_found` ; findings Standards tagués `"axe": "standards"` ; deux `review_path` distincts.

**Consigner** : le bloc typé verbatim et le SHA du HEAD dans `41.4-SONDE-POCK04.md` (preuve E6), à côté de la sonde 1.

**Invalide la sonde** : axe Standards `passed` (la convention violée n'est pas vue), axe Spec `gaps_found` pour un comportement du plan (le patch les implémente tous), ou findings des deux axes fusionnés.
