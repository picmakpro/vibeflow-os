---
name: invariant-t21b-nom-de-variable
description: Dans dev-orchestrator, l'invariant T21b (SC5) de test-dev-orchestrator.sh contraint le NOM des variables de redirection d'écriture — un nom prescrit par un plan peut le violer.
metadata:
  type: project
---

`plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` porte des invariants **SC5**
appliqués par grep sur trois scripts du module (`check-dev-bootstrap.sh`, `check-doc-drift.sh`,
`discover-unintegrated-docs.sh`) :

- **T21a** : aucun `exit 1` littéral (contrat 0/3/64) ;
- **T21b** : toute redirection d'écriture cible `/dev/null`, un descripteur `&N`, **ou une
  variable dont le NOM CONTIENT `TMP`** (regex `\$\{?[A-Za-z_]*TMP[A-Za-z_]*\}?`, **majuscules**) ;
- **T21c** : aucune écriture directe (`mkdir`/`touch`/`tee`/`cp`/`mv`/`sed -i`) ;
- **T21d** : tout `mktemp` apparié à un `trap … EXIT` dans le même fichier.

**Why:** mesuré le 2026-09-24 (plan 41.1-04). Le `<action>` du plan prescrivait littéralement
`_WS_LIST="$(mktemp)"` puis `> "$_WS_LIST"` — nom sans `TMP`, donc
`✗ T21b … redirection hors /dev/null|&N|*TMP*`, suite rc=1 et rejeu `--job tests` rouge. Le nom
d'une variable n'a pas l'air d'être un contrat : ici il en est un, et le plan l'ignorait.
Renommé `_WS_TMP` — incohérence **créée** par le plan, donc fermée par lui.

**How to apply:** avant d'ajouter une redirection dans l'un de ces trois scripts, nommer la
variable temporaire en `*TMP*` (majuscules) et rejouer `test-dev-orchestrator.sh` — pas seulement
la suite propre du script touché, qui ne porte aucun de ces invariants. Une grille de nommage
identique existe peut-être ailleurs : quand un plan dicte un nom de variable en toutes lettres,
grep les suites du module pour ce nom avant de l'écrire. Voisin de
[[project_libelle-de-cas-couple-au-verify-du-plan]] et de [[project_plans-code-normatif]] : le
texte d'un plan est normatif sur le comportement, jamais sur les noms — c'est le dépôt qui tranche.
