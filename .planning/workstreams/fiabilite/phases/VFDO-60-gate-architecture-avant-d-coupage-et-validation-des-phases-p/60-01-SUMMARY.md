---
phase: 60-gate-architecture-avant-d-coupage-et-validation-des-phases-p
plan: 01
subsystem: conductor
tags: [gate, marqueur-de-phase, qual-01, mutants]
requires: []
provides: [check-phase-validation.sh]
affects: [60-03, 60-04, 60-06, 60-08, 60-09]
key-files:
  created: [plugin/conductor/scripts/check-phase-validation.sh, plugin/conductor/scripts/tests/test-check-phase-validation.sh]
  modified: [plugin/conductor/references/workstream-planning-consumers.md]
status: complete
commits: 3
plan_head_before: 90a8f6e3709b351f597fb83e378732006a552c2e
plan_head_after: d693e9c4eec5bbc57c544e865f7d92c901b40c9b
actuals: {tokens: 30000, tasks: 3, commits: 3}
---

# Phase 60 Plan 01: check-phase-validation.sh Summary

Gate déterministe du marqueur `**Validation:**` d'une phase du ROADMAP, lecture seule, ne lisant jamais le poste, avec suite à dix mutants tués.

## Contrat (tel qu'écrit dans l'en-tête, 268 lignes)
- `check-phase-validation.sh --phase <N> [--ws <nom>]`, `--x=<v>` admis, `-h|--help`. Lab plat : ROADMAP du dossier de planning du cwd. Lab partitionné : `--ws` explicite obligatoire (`vf_ws_name_valid` puis `vf_ws_dir_resolve`), sans `--ws` -> 3.
- Codes : 0 validée (marqueur `validated` ou absent), 1 proposée, 3 indéterminé, 5 illisible bruyant, 64 usage, 2 jamais émis ; ordre 5 > 1 > 3 > 0. Borne `CPV_MAX_OCTETS=1048576`, refus avant lecture.
- Étiquettes : `PHASE <N> validee (marqueur absent)`, `PHASE <N> validee`, `PHASE <N> proposee`, `INDETERMINE <raison>`, `ILLISIBLE <entree> : <raison>` (aussi stderr), `BILAN phase=<N> marqueur=<absent|proposed|validated|inconnu|multiple|-> code=<rc>`.
- Limite fail-open (« Regenerate all » d'edit-phase, phase ajoutée à la main) écrite en clair en en-tête.

## Suite et résultats
- 30 cas CPV-* (TRACE-1..4, VALIDATED, INCONNU, MULTI, FENCE, FENCE-OUVERTE, TAG, DOUBLE, SECTIONS, DECIMAL, CRLF, BOM, WS, WS-SANS, WS-ABSENT, WS-NOM, WS-LIEN, POSTE, LIEN, FIFO, DOSSIER, GROS, ILLISIBLE, NOECHO, EXEC, RO, CODES) + CPV-MUT-1..10 tués : `40 ok, 0 ko`, rc 0 sous bash courant et `/bin/bash` 3.2, durée 3 s.
- `check-ajout-retrait.sh --root . --strict` rc 0, `AJOUT-COUVERT: plugin/conductor/scripts/check-phase-validation.sh (fichier)`.
- `check-gate-touche.sh` rc 0 (`marqueurs: lus=6 conformes=6`, DECLARE). `check-planning-consumers-registered.sh`, `check-python-isolation.sh --min-sites 40`, `check-machine-paths.sh` rc 0. Sonde FIFO hors suite : rc 5.
- `check-version-sync.sh` rouge attendu : « 113 suites » ≠ 114, jusqu'à 60-07 (P60-PL-17).

## Deviations from Plan
- [Rule 2 - sûreté] Deux raisons de 3 ajoutées à la liste du plan : `commentaire HTML non ferme` (sinon un `<!--` jamais fermé masquerait la section et rendrait un vert) et `politique de compartiment introuvable` (`--ws` sans `workstream-policy.sh`).
- Les lignes de mutants impriment `tue` sans accent, pour satisfaire littéralement le critère d'acceptation (`CPV-MUT-… tue`).
- `validated` suivi d'un texte hors parenthèses -> 3 (strict, jamais un vert permissif) ; couvert par CPV-VALIDATED.

## Points ouverts
- Parité mawk non rejouable sur ce poste (hypothèse A1, ni mawk ni gawk installés) : la CI de la PR en est le témoin.
- Commits : de4bb575 (tracer + recensement), 17a59a0c (grammaire, compartiment), d693e9c4 (garde, mutants).

## Self-Check: PASSED
