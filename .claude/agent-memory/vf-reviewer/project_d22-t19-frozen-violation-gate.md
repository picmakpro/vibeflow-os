---
name: d22-t19-frozen-violation-gate
description: T19 (test-dev-orchestrator.sh) exige positivement la présence de gsd-debugger dans l'allowlist Agent(...) de vf-coder.md — honorer D-22 en le retirant fait rougir T19, pas seulement laisser un écart neutre
metadata:
  type: project
---

À la revue de 23-07 (nœud `revue-07`), l'amendement du plan avait re-scopé trois sites qui
certifiaient la conformité à D-22 « par ricochet » (une truth, SC5, une ligne de vérification) pour
dire « volet dispatch, et lui seul ». Un **quatrième site, non vu par cet amendement** : `T19` dans
`plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (Phase 16 / 23-05, pré-existant,
non touché par 23-07) porte `gsd-debugger` dans `CODER_ALLOWED` et affirme
`"T19 cloisonnement : vf-coder — allowlist Agent(...) complète, nom par nom"` — un critère machine
qui EXIGE la présence de `gsd-debugger` pour passer.

**Prouvé par mutation** (sandbox tar sans `.git`, `sed` retire `gsd-debugger, ` de la ligne
`tools:` de `vf-coder.md`) : la suite tombe de 161→159 OK, 1 KO — `« gsd-debugger » absent de
l'allowlist de vf-coder`. Donc honorer D-22 (« aucun gsd-debugger en allowlist, aucune exception »)
en éditant SEULEMENT `vf-coder.md` **casse la CI**, parce que T19 traite l'état actuel (violant)
comme la référence correcte.

**Why:** cette famille (couverture apparente qui certifie une conformité qui n'existe pas) est
précisément ce que la Phase 23 existe pour fermer — la laisser vivre dans l'étape juste avant la
gouvernance (23-08) l'aurait rendue invisible au moment de l'arbitrage.

**How to apply:** au prochain arbitrage humain sur D-22 (retirer `gsd-debugger` de `vf-coder.md` OU
amender D-22 pour y inscrire l'exception), `T19` (`CODER_ALLOWED`) doit être mis à jour EN MÊME
TEMPS que la décision — sinon la CI casse ou continue de certifier un état que Samuel vient de
trancher autrement. Vérifier ce couplage à la prochaine revue qui touche `vf-coder.md:tools:` ou
`T19`. Voir aussi [[feedback_mutation-test-regression-claims]] (méthode : revert + relancer pour
prouver qu'un gate mord réellement) et [[feedback_mirror-gate-superset-drift]] (famille : un gate
qui certifie par sur-couverture plutôt que par preuve).
