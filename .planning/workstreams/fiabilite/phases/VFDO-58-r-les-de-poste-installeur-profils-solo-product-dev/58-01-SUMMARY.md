---
phase: 58
plan: 01
status: complete
requirements: [RLPO-04, RLPO-05]
---
# 58-01 — clé `roles` et validateur unique (P58-D-03, P58-D-06)

- `plugin/_internal/module-roles.sh` : verbes `validate`, `visible`, `list` ; prédicat `roles_verdict` en un seul endroit ; refus bruyant (code 1) de `[]`, valeur inconnue, chaîne, null, `solo`.
- Trois `module.json` à `"roles": ["dev"]` : dev-orchestrator, mobile-test, mobile-test-team. resolve-deps.sh et planning-core inchangés.
- Suite `plugin/_internal/tests/test-module-roles.sh` : 19 ok / 0 ko (bash et /bin/bash 3.2) : MR-TRACE-1..4, MR-VAL-1..3 (6 valeurs invalides), MR-LIST, MR-REAL, MR-CLOS + témoin MR-CLOS-TEMOIN (fuite `beta` détectée), MR-USAGE.
- Mutants tués : MR-MUT-1 (garde « liste vide » retirée : `[]` accepté rc 0 par le mutant, rc 1 par l'original), MR-MUT-2 (garde « ensemble fermé » retirée : `["qa"]`), chacun `cmp -s` différent, `bash -n` valide.
- `list product` sur le dépôt réel = tous les modules sauf dev-orchestrator, mobile-test, mobile-test-team.
- Voisines vertes : test-build-module-catalog (14/0), test-resolve-deps (5/0), test-resolve-preset (15/0).
- Écart : les deux tâches du plan sont livrées en un seul commit. check-version-sync rougira sur le compte de suites jusqu'à 58-11 (attendu).
