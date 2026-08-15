---
phase: 29-distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a
plan: 04
subsystem: infra
tags: [bash, scaffolding, documentation, adr-042, adr-055]

requires:
  - phase: 29-01
    provides: forme de la table Charge / NE charge PAS (G1), reprise ici pour le corps du CONTEXT.md
provides:
  - "scaffold-docs.sh pose un CONTEXT.md de routage (≤ 80 lignes) par compartiment de documentation"
  - "scaffold-docs.sh --index <dossier> pose un _index.md de contenu pour tout dossier de références"
  - "première suite de tests du scaffolder (25 cas), couvrant l'extension ET le comportement préexistant"
  - "première application réelle du pattern _index.md : plugin/dev-orchestrator/references/_index.md"
affects: ["29-05"]

actuals:
  tokens: 3404
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns: ["contrat de routage par dossier (CONTEXT.md)", "index de contenu de dossier de références (_index.md)"]

key-files:
  created:
    - plugin/conductor/scripts/tests/test-scaffold-docs.sh
    - plugin/dev-orchestrator/references/_index.md
  modified:
    - plugin/conductor/scripts/scaffold-docs.sh

key-decisions:
  - "Stubs posés à la création (pas en rattrapage) : le scaffolder est déjà idempotent, un rattrapage exigerait un second mécanisme."
  - "_index.md rédigé à la main plutôt que machine-généré : un résumé utile est un acte d'écriture, pas une extraction automatique."
  - "Le seul chemin d'écriture reste write_stub() — aucun nouveau chemin, aucune réécriture."

patterns-established:
  - "CONTEXT.md : titre + blockquote de rôle + table Tâche/Charge/NE charge PAS + ligne Voir aussi, ≤ 80 lignes, jamais de contenu de fond."
  - "_index.md : titre + blockquote de rôle (seuil > 10 fichiers) + table Fichier/Résumé, ne s'auto-liste jamais."

requirements-completed: [ICMD-10, ICMD-11]

coverage:
  - id: D1
    description: "CONTEXT.md de routage ≤ 80 lignes posé par compartiment de documentation (transverse et par sous-projet), via le seul chemin d'écriture idempotent write_stub()"
    requirement: ICMD-10
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-scaffold-docs.sh (cas 1-13)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Flag --index <dossier> posant un _index.md de contenu (table Fichier/Résumé), idempotent, distinct sémantiquement du tableau de bord INDEX.md existant"
    requirement: ICMD-11
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-scaffold-docs.sh (cas 14-21)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Première application réelle du pattern _index.md sur plugin/dev-orchestrator/references/ (11 fichiers, résumés d'une ligne, aucune auto-citation)"
    requirement: ICMD-11
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-scaffold-docs.sh (cas 22)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Section « Bornes et vocabulaire » dans l'en-tête du script (deux compartiments homonymes, trois rôles de fichiers, deux noms d'index) + garde ADR-055 (aucune écriture sous .planning/)"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-scaffold-docs.sh (cas 23-24)"
        status: pass
    human_judgment: false

duration: n/a
completed: 2026-08-15
status: complete
---

# Phase 29 (plan 04) : le contrat par lieu — CONTEXT.md de compartiment + _index.md de dossier

**`scaffold-docs.sh` pose désormais un CONTEXT.md de routage (table Tâche/Charge/NE charge PAS, ≤ 80 lignes) par compartiment de documentation et un `_index.md` sur demande pour tout dossier de références > 10 fichiers, avec sa première application réelle sur `plugin/dev-orchestrator/references/` (11 fichiers).**

## Performance

- **Tasks:** 3 (tracer TDD + auto TDD + auto)
- **Files modified:** 3 (1 créé : test-scaffold-docs.sh, 1 créé : _index.md, 1 modifié : scaffold-docs.sh)
- **Commits:** 3

## Accomplishments
- `scaffold-docs.sh` pose un `CONTEXT.md` ≤ 80 lignes par compartiment (transverse + par sous-projet), en table `Tâche / Charge / NE charge PAS`, exclusivement via `write_stub()` — aucun nouveau chemin d'écriture, aucune réécriture.
- Flag `--index <dossier>` (formes séparée et accolée) posant un `_index.md` de contenu (`| Fichier | Résumé |`), sémantiquement distinct du tableau de bord `INDEX.md` déjà en place, idempotent, refusant un dossier inexistant (exit 2) ou une valeur absente (exit 2).
- Première application réelle : `plugin/dev-orchestrator/references/_index.md`, 11 lignes de données (une par fichier markdown du dossier), résumés d'une ligne dérivés du rôle déclaré de chaque fichier, sans auto-citation.
- Section « Bornes et vocabulaire » dans l'en-tête du script : tranche par écrit lequel des deux « compartiment » homonymes ce script sert (documentation ADR-042, pas planning), les trois rôles disjoints de fichiers, et les deux noms d'index qui ne fusionnent jamais.
- Première suite de tests du scaffolder (25 cas), née avec l'extension et couvrant AUSSI le comportement préexistant (les 4 stubs `INDEX.md`/`REFERENCE.md`) — la non-régression est prouvée, pas supposée.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Tâche 1 : tranche traçante — CONTEXT.md + sa suite** — `1b466ca` (feat)
2. **Tâche 2 : pattern `_index.md` — stub + application réelle** — `1c9dd45` (feat)
3. **Tâche 3 : Bornes et vocabulaire + garde `.planning/`** — `ab7a9c4` (docs)

_Note : les 3 tâches sont TDD (tests écrits avant l'extension, tâche par tâche) mais chaque paire test+extension a été committée en un seul commit atomique par tâche, cohérent avec le style du dépôt._

## Files Created/Modified
- `plugin/conductor/scripts/scaffold-docs.sh` — extension : CONTEXT.md de routage, flag `--index`, section « Bornes et vocabulaire ». Correction ciblée (exec-04, revue) : la validation de `--index` (dossier existant) est remontée AVANT toute écriture — auparavant les stubs transverses (`docs/_transverse/{INDEX,REFERENCE,CONTEXT}.md`) étaient posés avant l'échec, rendant « rien créé » faux ; un seul chemin d'écriture (`write_stub()`) toujours respecté.
- `plugin/conductor/scripts/tests/test-scaffold-docs.sh` (créé) — 25 cas, `PASS=25 FAIL=0`. Correction ciblée : cas 17 durci (atomicité, vérifie aussi l'absence de `docs/`) + cas 17b ajouté (nom à tiret initial `-evilname`, mitigation T-29-04-02 réellement testée).
- `plugin/dev-orchestrator/references/_index.md` (créé) — application réelle du pattern G2. Correction ciblée : résumé de `mission-flow.md` corrigé (« 7 patterns A à G », pas « 3 patterns »).

## Decisions Made
- Stubs posés à la création plutôt qu'en rattrapage (tranché en amont dans le PLAN — décision reprise verbatim, non rediscutée en exécution).
- `_index.md` rédigé à la main plutôt que machine-généré (idem — tranché en amont).
- Table `routing_table()` factorisée en fonction bash pour éviter la duplication entre le stub transverse et le stub par compartiment (déviation mineure de forme, pas de contenu — le plan ne prescrivait pas cette factorisation mais elle réduit la duplication de code sans changer le comportement observable).

## Deviations from Plan

None — plan exécuté tel qu'écrit. La factorisation `routing_table()` est une décision d'implémentation locale (DRY), pas un écart de comportement ou de périmètre.

## Issues Encountered
- Cas de test initiaux avec un motif `grep` trop large (comptait la ligne d'en-tête de table en plus des lignes de données) : corrigé dans la suite avant le premier vert, sans toucher au script.

## User Setup Required
None — aucune configuration externe requise.

## Next Phase Readiness
- G2 livré : le pattern de contrat par lieu existe comme doctrine ET comme preuve (application réelle).
- Reliquat porté par **29-05** (ICMD-12) : le compteur « N suites » des deux README racine doit être re-dérivé pour refléter `test-scaffold-docs.sh` (+1 suite).
- `dag.sh` et `compartments.md` intacts (`git diff --name-only` vide sur les deux) ; suites `test-dag.sh` (99 PASS) et `test-vf-new-lab.sh` (21 PASS) toujours vertes.

---
*Phase: 29-distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a*
*Plan: 04*
*Completed: 2026-08-15*
