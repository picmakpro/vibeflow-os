---
phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
plan: 02
subsystem: governance-agent-corpus
tags: [frontmatter, vf-internal, SendMessage, check-agents, mobile-test-team, business-pilot-bundle, content-bundle]

# Dependency graph
requires: []
provides:
  - "vf-test-orchestrator conforme I1/I2/I3 (vf-internal: true + marqueur « Worker interne » dans description:, nommant ses deux dispatcheurs réels vf-dev-manager et vf-auto, D-18)"
  - "vf-business-manager conforme I6 (SendMessage ajouté à tools:)"
  - "vf-content-manager conforme I6 (SendMessage ajouté à tools:)"
  - "mobile-test-team v1.4.6, business-pilot-bundle v2.0.10, content-bundle v2.0.10 — un commit dédié par module, D-12"
affects: ["42-05", "42-06"]

# Actuals (#2632) — pairs with the plan's estimate to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 3930
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Corrections de frontmatter pur (aucune ligne de corps touchée) pour rester neutre sur le ratchet check-instruction-budget.sh"
    - "Un commit par module, bump de patch, séparé de tout commit du gate (D-12)"

key-files:
  created: []
  modified:
    - plugin/mobile-test-team/agents/vf-test-orchestrator.md
    - plugin/mobile-test-team/VERSION
    - plugin/mobile-test-team/module.json
    - plugin/mobile-test-team/CHANGELOG.md
    - plugin/mobile-test-team/README.md
    - plugin/business-pilot-bundle/agents/vf-business-manager.md
    - plugin/business-pilot-bundle/VERSION
    - plugin/business-pilot-bundle/module.json
    - plugin/business-pilot-bundle/CHANGELOG.md
    - plugin/business-pilot-bundle/README.md
    - plugin/content-bundle/agents/vf-content-manager.md
    - plugin/content-bundle/VERSION
    - plugin/content-bundle/module.json
    - plugin/content-bundle/CHANGELOG.md
    - plugin/content-bundle/README.md

key-decisions:
  - "Lecture littérale de D-07 appliquée à vf-test-orchestrator (RESEARCH.md Open Question 1, RESOLVED) : ajouter vf-internal: true + marqueur suffit à résoudre I2/I3 ET exempte automatiquement de I6 (il n'est plus « manager » au sens D-07) — aucun SendMessage ajouté sur ce fichier."
  - "I5 (omitClaudeMd sur quality-gate-client et content-clarity-judge) SORTI de ce plan (restructuration mission revise-42b/revise-42c, B1) : D-19 a rendu son verdict (omitClaudeMd retire aussi les règles .claude/rules/*.md), D-08 réexaminée avec Samuel, réponse non reçue. Sa pose vit derrière le checkpoint bloquant de 42-05 (Tâche 2)."
  - "FABR-05 NON marqué complet (gate #2388, IDs partagés) : les plans 42-01, 42-03, 42-05, 42-06 déclarent aussi FABR-05 et n'ont pas tous de SUMMARY.md à ce stade (seul 42-01 en a une) — requirements.mark-complete --ws gouvernance aurait de toute façon résolu vers le mauvais fichier (bug connu, contournement documenté dans Deviations)."

patterns-established: []

requirements-completed: []  # FABR-05 partagé avec 42-01/42-03/42-05/42-06 — non marqué complet, cf. Deviations et key-decisions

coverage:
  - id: D1
    description: "vf-test-orchestrator devient worker interne conforme I1/I2/I3 (vf-internal: true + marqueur Worker interne, corps octet-pour-octet identique à main, hors classe manager D-07)"
    requirement: "FABR-05"
    verification:
      - kind: other
        ref: "plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/mobile-test-team/agents"
        status: pass
      - kind: other
        ref: "plugin/conductor/scripts/check-instruction-budget.sh (INSTR-INCHANGE)"
        status: pass
      - kind: other
        ref: "acceptance_criteria Tâche 1 (grep/cmp/isolation-du-commit) — toutes rendent la valeur attendue"
        status: pass
    human_judgment: false
  - id: D2
    description: "vf-business-manager conforme I6 (SendMessage ajouté à tools:, corps inchangé)"
    requirement: "FABR-05"
    verification:
      - kind: other
        ref: "plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/business-pilot-bundle/agents"
        status: pass
      - kind: integration
        ref: "plugin/business-pilot-bundle/scripts/tests/test-business-pilot-bundle.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "vf-content-manager conforme I6 (SendMessage ajouté à tools:, corps inchangé)"
    requirement: "FABR-05"
    verification:
      - kind: other
        ref: "plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/content-bundle/agents"
        status: pass
      - kind: integration
        ref: "plugin/content-bundle/scripts/tests/test-content-bundle.sh"
        status: pass
    human_judgment: false

# Metrics
duration: ~20min
completed: 2026-09-24
status: complete
---

# Phase 42 Plan 02: Mise en conformité frontmatter (I3, I6) de trois modules Summary

**Ajout de `vf-internal: true` sur `vf-test-orchestrator` (I3) et de `SendMessage` sur `vf-business-manager`/`vf-content-manager` (I6), trois commits dédiés avec bump patch (mobile-test-team v1.4.6, business-pilot-bundle v2.0.10, content-bundle v2.0.10).**

## Performance

- **Duration:** ~20 min (dispatch séquentiel, pas d'horodatage PLAN_START_TIME instrumenté)
- **Completed:** 2026-09-24
- **Tasks:** 3/3
- **Files modified:** 15 (5 par module : agent, VERSION, module.json, CHANGELOG.md, README.md)

## Accomplishments
- `vf-test-orchestrator` (mobile-test-team) devient worker interne conforme I1/I2/I3 : `vf-internal: true` + marqueur « Worker interne » dans `description:`, nommant ses deux dispatcheurs réels (`vf-dev-manager` et `vf-auto`, D-18). Par lecture littérale de D-07, il sort automatiquement de la classe manager — pas de `SendMessage` ajouté.
- `vf-business-manager` (business-pilot-bundle) et `vf-content-manager` (content-bundle) déclarent désormais `SendMessage` dans leur `tools:` — conformes I6.
- Trois modules bumpés en patch dans des commits dédiés, isolés (aucun ne touche un fichier hors de son propre module), avec CHANGELOG et trace de décision.
- Les 4 juges I5 (`quality-gate-client`, `content-clarity-judge`, et par extension les deux du plan 42-03) NE SONT PAS touchés — sortis de ce plan par la restructuration mission `revise-42b`/`revise-42c` (D-19/D-08), leur pose vit derrière le checkpoint bloquant de 42-05 (Tâche 2).

## Task Commits

Each task was committed atomically:

1. **Tâche 1: mobile-test-team — vf-test-orchestrator devient worker interne (I3)** - `0ab324b` (fix)
2. **Tâche 2: business-pilot-bundle — manager avec SendMessage (I6)** - `015594f` (fix)
3. **Tâche 3: content-bundle — manager avec SendMessage (I6)** - `fde5183` (fix)

**Plan metadata:** committed together with this SUMMARY.md (docs commit, see below).

## Files Created/Modified
- `plugin/mobile-test-team/agents/vf-test-orchestrator.md` - `vf-internal: true` + marqueur « Worker interne » ; corps inchangé
- `plugin/mobile-test-team/VERSION`, `module.json`, `README.md`, `CHANGELOG.md` - bump patch v1.4.5 → v1.4.6
- `plugin/business-pilot-bundle/agents/vf-business-manager.md` - token `SendMessage` ajouté à `tools:`
- `plugin/business-pilot-bundle/VERSION`, `module.json`, `README.md`, `CHANGELOG.md` - bump patch v2.0.9 → v2.0.10
- `plugin/content-bundle/agents/vf-content-manager.md` - token `SendMessage` ajouté à `tools:`
- `plugin/content-bundle/VERSION`, `module.json`, `README.md`, `CHANGELOG.md` - bump patch v2.0.9 → v2.0.10

## Decisions Made
- Lecture littérale de D-07 (« manager = `Agent(...)` non vide ET non `vf-internal` ») appliquée à `vf-test-orchestrator` : une seule correction (`vf-internal: true` + marqueur) résout I2, I3 ET exempte de I6 — recommandation RESEARCH.md Open Question 1 (RESOLVED), suivie telle quelle.
- I5 (`omitClaudeMd` sur les 4 juges) confirmé HORS PÉRIMÈTRE de ce plan par la restructuration `revise-42b`/`revise-42c` : deux gardes anti-fusion explicites dans le `<verify>` de chaque tâche (`grep -c '^omitClaudeMd' <juge>` doit rendre 0) ont été exécutées et confirment qu'aucun juge n'a été touché.
- `dev-orchestrator` non touché : conforme aux mesures (aucune violation) et à `42-RESEARCH.md` Open Question 2 (RESOLVED).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `gsd_run query requirements.mark-complete --ws gouvernance` contourné manuellement**
- **Found during:** clôture du plan (étape marquage des exigences)
- **Issue:** connu et signalé par l'objectif de dispatch — `requirements.mark-complete --ws gouvernance` résout silencieusement vers le REQUIREMENTS.md du workstream `fiabilite` au lieu de `gouvernance`, et n'écrit rien pour un ID absent de ce fichier (no-op silencieux, pas de corruption constatée).
- **Fix:** aucune écriture tentée via cette commande. FABR-05 est de toute façon un ID PARTAGÉ (42-01, 42-02, 42-03, 42-05, 42-06 le déclarent tous) — seul 42-01 a une SUMMARY.md à ce stade (wave 1 de la phase), donc le gate #2388 (IDs partagés, non marqués tant que tous les plans déclarants n'ont pas terminé) bloque de toute façon le marquage complet à ce stade, indépendamment du bug. `requirements-completed: []` documenté explicitement en frontmatter.
- **Files modified:** aucun (pas d'édition manuelle de REQUIREMENTS.md, car la condition de complétude n'est pas atteinte)
- **Verification:** `ls .planning/workstreams/gouvernance/phases/VFDO-42.../*-SUMMARY.md` ne montre que `42-01-SUMMARY.md` et `42-02-SUMMARY.md` (celle-ci) — 42-03/42-05/42-06 manquent encore.
- **Committed in:** n/a (constat, pas une modification de fichier)

---

**Total deviations:** 1 auto-géré (contournement documenté, aucune écriture erronée).
**Impact on plan:** Aucun — le comportement attendu (ne pas marquer FABR-05 tant que les plans siblings ne sont pas tous terminés) est identique avec ou sans le bug de résolution de workstream.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Les trois modules touchés par ce plan (mobile-test-team, business-pilot-bundle, content-bundle) sont conformes I1-I3/I6 et prêts pour l'armement des invariants en erreur dans 42-05/42-06.
- FABR-05 reste `requirements-completed: []` (non marqué) tant que 42-03, 42-05 et 42-06 n'ont pas chacun leur SUMMARY.md — à marquer par le dernier plan déclarant qui termine (gate #2388).
- Le commit `mobile-test-team` (`0ab324b`) est de la polarité de Samuel (D-12) — à nommer explicitement en relecteur dans la PR de la phase (le relevé des commits par module est porté par 42-06, per l'objectif du plan).
- I5 (`omitClaudeMd` sur les 4 juges) reste bloqué derrière le checkpoint D-19 de 42-05 (Tâche 2) — aucune action requise de ce plan.

## Self-Check: PASSED

- `plugin/mobile-test-team/agents/vf-test-orchestrator.md` — FOUND, `vf-internal: true` present, corps identique à `origin/main` (cmp)
- `plugin/business-pilot-bundle/agents/vf-business-manager.md` — FOUND, `SendMessage` présent dans `tools:`, corps identique à `origin/main` (cmp)
- `plugin/content-bundle/agents/vf-content-manager.md` — FOUND, `SendMessage` présent dans `tools:`, corps identique à `origin/main` (cmp)
- Commits `0ab324b`, `015594f`, `fde5183` — FOUND (`git log --oneline` confirme les trois)
- Toutes les `<acceptance_criteria>` des trois tâches ré-exécutées : PASS
- `check-agents.sh --strict` vert sur les trois dossiers d'agents touchés ; `check-instruction-budget.sh` : `0 depassement(s)`, `code=0`, INSTR-INCHANGE sur les trois fichiers ; `check-version-sync.sh` : rc=0 ; suites `test-business-pilot-bundle.sh` et `test-content-bundle.sh` : exit 0

---
*Phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des*
*Plan: 02*
*Completed: 2026-09-24*
