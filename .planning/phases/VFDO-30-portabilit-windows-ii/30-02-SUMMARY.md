---
phase: 30-portabilit-windows-ii
plan: 02
subsystem: ledger-upstream
tags: [ledg-03, d-09, d-11, rfc]
requires: []
provides: [rfc-upstream-open-gsd-gsd-core-issue-3556]
affects: [.planning/REQUIREMENTS.md, .planning/STATE.md]
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/VFDO-30-portabilit-windows-ii/30-RFC-UPSTREAM.md
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
key-decisions:
  - "Brouillon rédigé et laissé non posté (commit a3e9fcb) jusqu'à validation humaine explicite du contenu (D-09) — aucun raccourci sur ce gate malgré la contrainte « jour 1 »."
  - "Une fois validé, le corps posté est identique bit-à-bit au brouillon validé — vérifié via `gh issue view --json body` (non tracé : commande exacte non retrouvée dans le message de commit, seul le résultat « corps identique » y est affirmé)."
  - "Double traçabilité D-11 : l'URL et la date sont écrites à la fois dans REQUIREMENTS.md (ligne LEDG-03) et dans STATE.md (décision datée), avec le repli GO-RÉDUIT du STUDY.md de la Phase 18 déjà écrit au cas où l'amont refuse ou ignore avant l'échéance 2026-10-26."
requirements-completed: [LEDG-03]
duration: "non tracé"
completed: "2026-08-15"
coverage:
  - deliverable: "RFC upstream ouverte sur open-gsd/gsd-core dès le jour 1 du milestone"
    verification:
      - kind: "artifact"
        ref: "https://github.com/open-gsd/gsd-core/issues/3556"
        status: pass
    human_judgment: true
  - deliverable: "Traçabilité D-11 (REQUIREMENTS.md ligne LEDG-03 + décision datée dans STATE.md)"
    verification:
      - kind: "command"
        ref: "grep -n 'LEDG-03' .planning/REQUIREMENTS.md"
        status: pass
    human_judgment: false
---

# Phase 30 Plan 02: RFC upstream open-gsd/gsd-core (LEDG-03) Summary

Brouillon de RFC demandant que la suppression de `.planning/REQUIREMENTS.md` à la clôture de
jalon devienne optionnelle (`complete-milestone.md` fait aujourd'hui un `git rm` inconditionnel,
sans flag ni gate — trou prouvé par la Phase 18, STUDY.md, verdict GO-RÉDUIT), rédigé puis déposé
publiquement après validation humaine.

**Durée** : non tracée. **Tâches** : 2 commits (brouillon, puis dépôt + traçabilité).

## Accomplissements

- `.planning/phases/VFDO-30-portabilit-windows-ii/30-RFC-UPSTREAM.md` (commit `a3e9fcb`) : brouillon
  complet, statut « brouillon — non posté » (D-09, gate humain avant tout post public). Version
  `@opengsd/gsd-core` relevée sur ce poste au moment de la rédaction : 1.10.0. Recherche read-only
  (`gh search`) n'ayant trouvé aucune RFC équivalente déjà ouverte côté amont. Section « Traçabilité
  à poser après le post » (D-11) rédigée à l'avance, avec le texte exact prévu pour
  `REQUIREMENTS.md` et `STATE.md` — ces deux fichiers restaient hors périmètre tant que le post
  n'avait pas eu lieu.
- Issue publique postée (commit `9632f50`) : https://github.com/open-gsd/gsd-core/issues/3556.
  Brouillon validé par Samuel (D-09) avant post ; corps identique bit-à-bit au brouillon validé.
  `30-RFC-UPSTREAM.md` mis à jour de « brouillon — non posté » à « postée » avec l'URL.
- `.planning/REQUIREMENTS.md` : ligne LEDG-03 du tableau et puce de section complétées avec l'URL
  et la date d'ouverture (2026-08-15).
- `.planning/STATE.md` : entrée datée en §Decisions, avec le repli GO-RÉDUIT écrit dès le dépôt
  (condition D3 du STUDY.md de la Phase 18) si l'amont refuse ou ignore avant l'échéance
  2026-10-26.

## Deviations from Plan

Non tracé — aucune déviation mentionnée dans les messages des deux commits du plan.

## Next Phase Readiness

Requirement LEDG-03 complété (RFC ouverte dès le jour 1 du milestone, deadline amont 2026-10-26
suivie). La Phase 18 dispose désormais du lien direct dans les deux fichiers où elle ira le
chercher (`STATE.md` §Decisions, `REQUIREMENTS.md` ligne LEDG-03), plus le repli GO-RÉDUIT
pré-écrit en cas de non-réponse amont.
