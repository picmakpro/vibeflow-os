---
phase: 59-bundle-produit-front-door-vibeflow-product-brief-et-juge-prd
plan: 02
subsystem: product-team-bundle
tags: [gate-deterministe, prd-gate, qual-01, mutation]
requires: []
provides: [plugin/product-team-bundle/scripts/check-prd.sh, plugin/product-team-bundle/scripts/tests/test-check-prd.sh]
key-files:
  created: [plugin/product-team-bundle/scripts/check-prd.sh, plugin/product-team-bundle/scripts/tests/test-check-prd.sh]
  modified: []
requirements-completed: [PRDT-03, PRDT-05, PRDT-09]
status: complete
commits: 4
plan_head_before: e11e6c28fa52ed273912dab4b47f32969b389a1e
plan_head_after: e3845b9451c711090b168fe96bd9a2648e13001a
actuals: {tokens: 7600, tasks: 4, commits: 4}
---

# Phase 59 Plan 02: check-prd.sh Summary

Gate déterministe des deux éliminatoires du PRD et du BRIEF, trois issues plus l'indéterminé, huit mutants tués.

- Contrat (en-tête du script, 293 lignes) : `check-prd.sh --requirements <f> [--brief <f>]`, `--brief <f>` seul, `--x=<f>` admis, `-h|--help`, aucun chemin par défaut. Codes 0 conforme, 1 éliminatoire, 3 INDÉTERMINÉ (cible absente, zéro exigence), 5 illisible BRUYANT (lien, non régulier, illisible, au-delà de 1048576 octets, analyse en échec), 64 usage ; le 2 n'est jamais émis ; ordre 5 > 1 > 3 > 0.
- Étiquettes : `ELIMINATOIRE exigence <ID>`, `ELIMINATOIRE rubrique BRIEF <nom> : absente|vide`, `AVERTISSEMENT exigence <ID> : priorite absente|hors {must, should, could}`, `INDETERMINE`, `ILLISIBLE` (aussi stderr), `BILAN ...` en dernière ligne ; toutes préfixées `[check-prd]`, 50 lignes au plus par catégorie.
- Suite (40 cas, 8 mutants) : CPRD-TRACE-1..4, GABARIT, COURT, TBD, TBD-MOT, POINTS, ANCRE, FENCE, CRLF, BOM, PRIO, BRIEF-OK/MANQUE/VIDE/FENCE/NUM/SEUL, MIX, NOECHO, ABSENT, LIEN, FIFO, DOSSIER, GROS, ILLISIBLE, MIX5, EXEC, RO, CODES (observé {0, 1, 3, 5, 64}), CPRD-MUT-1..8 tous tués.
- Durée de la suite : 2 s (bash courant et `/bin/bash` 3.2). `check-ajout-retrait.sh --root . --strict` : `AJOUT-COUVERT: plugin/product-team-bundle/scripts/check-prd.sh (fichier)`, `COUVERT`, rc 0.
- Gates : `check-planning-consumers-registered.sh`, `check-python-isolation.sh --min-sites 40`, `check-machine-paths.sh` rc 0. `check-version-sync.sh` rouge sur le compte de suites (111 contre 112), attendu jusqu'à 59-06 (P59-PL-15).
- Commits : 96a64378 (script, tracer, trailer), 03d13af4, 200c244e, e3845b94.

## Deviations from Plan

1. [Rule 1 - Bug] CPRD-GABARIT : la fixture `[critère mesurable : …]` portait aussi des points de suspension, que la règle des points rejetait seule ; le mutant CPRD-MUT-2 (filtre de crochet retiré) survivait. Fixture ramenée au texte exact du gabarit (`[critère mesurable : quoi, combien, en combien de temps]`) ; CPRD-POINTS couvre désormais la règle des points.
2. TBD et TODO comptent en mots entiers (pas en sous-chaîne) : `autodocumentation` contient `todo` et serait rejeté à tort ; cas CPRD-TBD-MOT. Précision de P59-PL-18, pas un choix neuf.
3. Le script a été écrit d'un seul tenant au commit du tracer ; les commits des tâches 2 et 3 n'ajoutent que leurs cas de test (pas de rouge intermédiaire séparé). Ils sont en `test(59)` et non `feat(59)`. CPRD-ARGV fusionné dans CPRD-EXEC.
4. Longueur mesurée en octets (`LC_ALL=C`) pour les « 10 caractères non blancs » ; documenté dans l'en-tête.

## Self-Check: PASSED
