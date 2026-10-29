---
phase: 60-gate-architecture-avant-d-coupage-et-validation-des-phases-p
plan: 04
subsystem: conductor
tags: [ecrivain, marqueur-de-phase, architecture, poste, qual-01, mutants]
requires: [60-01, 60-02]
provides: [vf-validation.sh]
affects: [60-06, 60-08, 60-09]
key-files:
  created: [plugin/conductor/scripts/vf-validation.sh, plugin/conductor/scripts/tests/test-vf-validation.sh]
  modified: [plugin/conductor/references/workstream-planning-consumers.md]
status: complete
commits: 3
plan_head_before: 2e3ce6f565d8f44cc67010e88a943c2016f35897
plan_head_after: 0c6f41f54eac89810db69734f4fb1e3e5007e986
actuals: {tokens: 24000, tasks: 3, commits: 3}
---

# Phase 60 Plan 04: vf-validation.sh Summary

Seul écrivain de la ligne `**Validation:**` (phase du ROADMAP et ARCHITECTURE.md) : verbe de script, une ligne changée, écriture atomique, poste lu par `vf-role.sh`, preuve moteur GSD et huit mutants tués.

## Contrat (tel qu'écrit dans l'en-tête, 292 lignes)
- `propose --phase <N> [--ws <nom>]` : insère `**Validation:** proposed` après le paragraphe Goal (ligne Goal + suites, jusqu'à ligne blanche, ligne `**` ou titre). `validate --phase <N> [--ws] [--override]` et `validate --architecture <f> [--override]` : `proposed` -> `validated (<poste>, <AAAA-MM-JJ>[, override])`. `--x=<v>` admis, `-h|--help`, une seule cible.
- Codes : 0 écrit ou déjà dans l'état visé (INCHANGE), 1 refus de poste (product sans --override), 3 cible introuvable ou état incompatible, 5 entrée ou poste illisible, 64 usage, 2 jamais. BILAN `verbe= cible= ecrit= code=`.
- Poste (validate seulement) : dev/solo écrit ; product refuse sauf `--override` tracé ; codes 1/5/64 du lecteur -> 5, jamais un repli sur solo. `propose` ne lit pas le poste.
- Jamais dégradé : propose sur validated -> 3 ; propose sur proposed, validate sur validated ou marqueur absent -> 0 sans écriture. Aucun commit, aucun verrou de driver (Pitfall 13).

## Suite (595 lignes, 35 ok, 0 ko, 0 skip, rc 0 sous bash courant et `/bin/bash` 3.2, 7 s)
- VFV-TRACE-1..4, POSTE-PRODUCT/SOLO/ILLISIBLE, PROPOSE-VALIDEE, IDEMPOTENT, ABSENT-VALIDATE, INCONNU, MULTI, SANS-GOAL, GOAL-MULTI, OCTETS (dont fichier sans fin de ligne), CRLF, MODE, WS, LIEN, ILLISIBLE (FIFO, dossier, > 1 Mio, CR isolé), ARCHI (copie brute du gabarit validée -> gate encore rouge), NOECHO, FORME.
- VFV-GSD-NEG (témoin d'abord : insertion fautive entre deux lignes du Goal différente sur le champ `goal`), PROPOSE, VALIDATE, WS : `roadmap get-phase` hors `section` et `roadmap analyze` identiques à ceux du ROADMAP sans marqueur (Goal une ligne et multi-ligne, lab plat et partitionné). Aucun SKIP sur ce poste.
- VFV-MUT-1..8 tués (une ligne changée, `cmp -s`, `bash -n`, original revérifié vert).

## Contrôles
`check-gate-touche.sh` rc 0 (15/15 marqueurs conformes) ; `check-planning-consumers-registered.sh`, `check-python-isolation.sh --min-sites 40`, `check-machine-paths.sh`, `check-ajout-retrait.sh --strict` rc 0 ; suites des deux gates voisins vertes ; ROADMAP du dépôt inchangé (cksum) ; `eval` : 0 occurrence. `check-version-sync.sh` rc 1 attendu : « 113 suites » != réel 116, jusqu'à 60-07 (P60-PL-17).

## Hypothèse portée
P60-PL-06 (refus au poste product, `--override` tracé) dépend de P60-H-02 (un dev valide), à confirmer par Samuel ; réversible : retirer une branche du script et deux cas. L'acteur de la pose (P60-PL-07) reste une hypothèse du planificateur ; un humain peut toujours éditer la ligne à la main (un poste est une vue, pas un droit).

## Deviations from Plan
- Le script est posé complet dès le commit tracer (poste, override, architecture, états), comme en 60-02 ; les commits 2 et 3 ne portent que des cas et mutants de la suite (donc pas de RED observable pour la tâche 2, la preuve de capacité à rougir vient des mutants).
- Mutant MUT-3 : la mutation retire le refus de `propose` sur validated (rc 0 sans écriture), le garde côté awk (pas d'action) restant en défense en profondeur.

## Points ouverts
- Parité mawk non rejouable sur ce poste (ni mawk ni gawk) : la CI de la PR en est le témoin.
- Commits : 9dd9ad6a (tracer, script, recensement), 59b66a5a (cas), 0c6f41f5 (preuve moteur, mutants).

## Self-Check: PASSED
