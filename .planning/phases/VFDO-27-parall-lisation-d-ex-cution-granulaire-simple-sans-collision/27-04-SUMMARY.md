---
phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision
plan: 04
subsystem: infra
tags: [mesure, baseline, dag, emit-workflow, gsd-tools, git-log, claude_orchestration]

# Dependency graph
requires:
  - phase: 27-01/27-02/27-03 (vague 1 de cette même phase)
    provides: "les commits réels de dispatch parallèle mesurés dans le Bloc 2 ; dag.sh calcule stages (27-01), doctrine team-kernel.md (27-02), isolation worktree armée (27-03)"
provides:
  - "Corpus de mesure nommé et versionné, `27-mesure/waves-toy.json` — une vague, deux plans à files_modified strictement disjoints, prouvé parallélisable par emit-workflow (stagesByWave[0] = un seul étage de deux plans)"
  - "27-MESURE-GAIN.md : plafond d'étages Phase 24 re-dérivé (Bloc 1), baseline d'horloge inline de la vague 1 de cette phase capturée avant toute activation de claude_orchestration (Bloc 2), structure et garde-fous du Bloc 3 posés pour 27-06"
  - "Découverte : le plan 27-03 de la vague 1 s'est arrêté à mi-parcours puis a repris ~3h48 plus tard (pause d'arbitrage humain), écrite comme cinquième limite du corpus"
affects: ["27-05 (dépend de ce plan, active claude_orchestration après cette capture)", "27-06 (remplit le Bloc 3 sur l'étalon posé ici)"]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 3920
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Corpus de mesure jouet versionné dans le dossier de phase plutôt que reconstruit à la volée, pour garantir le même étalon entre baseline et mesure d'après (pattern déjà établi par ADR-069/24-COLLISIONS.md pour les documents de mesure)"
    - "Précondition vérifiée par commande shell exécutée juste avant l'écriture de l'artefact qu'elle protège, jamais supposée tenue par la seule lecture du plan"
    - "git log --grep ancré en tête de sujet (^[a-z]+\\(plan-id\\)) pour isoler les commits d'un plan sans faux positifs venant de commits de doctrine qui le mentionnent seulement"

key-files:
  created:
    - .planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-mesure/waves-toy.json
    - .planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-MESURE-GAIN.md
  modified: []

key-decisions:
  - "Écart de vague reporté en deux lectures distinctes et jamais fusionnées (fenêtre de dispatch initial continu vs écart littéral premier→dernier toutes sessions confondues), après découverte que le plan 27-03 de la vague 1 mesurée n'a pas été un dispatch continu — il s'est arrêté à mi-parcours et a repris ~3h48 plus tard, pause d'arbitrage humain documentée dans STATE.md"
  - "git log --grep ancré en tête de sujet plutôt qu'un --grep libre, après avoir constaté que le motif libre '(27-01)' remonte des faux positifs (commits de doctrine/planning mentionnant le plan sans en être un commit de tâche)"
  - "Corpus jouet à briefs anodins et files_modified strictement sous 27-mesure/scratch/ (répertoire jetable), pour ne créer aucune dépendance de contenu réel entre ce corpus et le reste du dépôt"

patterns-established:
  - "Document de mesure à trois blocs numérotés avec statut en tête, sur le modèle de 24-COLLISIONS.md — réutilisable pour toute future mesure gravée dans ce dépôt"

requirements-completed: [PAEX-07]

coverage:
  - id: D1
    description: "Corpus de mesure nommé (27-mesure/waves-toy.json), versionné, prouvé parallélisable par la même fonction amont (partitionStages via emit-workflow) qui partitionnera la vraie mesure"
    requirement: "PAEX-07"
    verification:
      - kind: integration
        ref: "node gsd-tools.cjs claude-orchestration emit-workflow --waves waves-toy.json --run-id mesure-27-baseline | python3 assertion summary.plans==2 et stagesByWave[0] un seul étage de deux plans"
        status: pass
    human_judgment: false
  - id: D2
    description: "27-MESURE-GAIN.md capturé avec la précondition tenue (claude_orchestration absent de .planning/config.json au moment de la capture), méthode re-dérivable (commande git log exacte), et les deux garde-fous d'énoncé (plafond ≠ gain d'horloge, estimation 1,8-2,5x étiquetée estimée)"
    requirement: "PAEX-07"
    verification:
      - kind: other
        ref: "verification automatisée du plan (test -f, grep claude_orchestration absent, grep baseline/gain d'horloge/estim/git log, >=4 titres)"
        status: pass
    human_judgment: true
    rationale: "La complétude et l'honnêteté du récit de mesure (dont la découverte de la pause d'arbitrage humain, hors périmètre anticipé par le plan) ne se prouvent pas par un grep de présence de chaînes seul — le contenu qualitatif mérite une relecture humaine."

# Metrics
duration: ~6min (mesuré entre les deux commits de tâche, 14:07:52 → 14:13:02 ; exclut la lecture amont non horodatée du plan, de STATE.md, de config.json et de RESEARCH.md)
completed: 2026-08-06
status: complete
---

# Phase 27 Plan 04: Baseline d'horloge capturée avant activation, méthode écrite

**Corpus de mesure jouet prouvé parallélisable et 27-MESURE-GAIN.md posé, avec la baseline d'horloge réelle de la vague 1 (12 commits sur 27-01/27-02/27-03) capturée pendant que `claude_orchestration` est encore absent de `.planning/config.json`.**

## Performance

- **Duration:** ~6min (entre le commit de la tâche 1, `08ca108` à 14:07:52+02:00, et le commit de la tâche 2, `334a339` à 14:13:02+02:00 — la lecture du plan, de `STATE.md`, de `config.json`, de `27-RESEARCH.md` §Livrable 3/5 et de `24-COLLISIONS.md` en amont n'est pas horodatée séparément)
- **Started:** voir ci-dessus
- **Completed:** 2026-08-06T14:13:02+02:00
- **Tasks:** 2/2
- **Files modified:** 2 (tous deux nouveaux)

## Accomplishments

- `27-mesure/waves-toy.json` posé : une vague, deux plans (`toy-a`/`toy-b`) à `files_modified`
  strictement disjoints sous `27-mesure/scratch/`, et **prouvé** — pas supposé — parallélisable :
  `emit-workflow --run-id mesure-27-baseline` rend `summary.plans == 2` et `stagesByWave[0]` un seul
  étage contenant les deux plans.
- `27-MESURE-GAIN.md` posé en trois blocs sur le modèle de `24-COLLISIONS.md` : le plafond d'étages
  de la Phase 24 (3,00×, 12 plans → 4 étages, 0 collision) re-dérivé et qualifié en toutes lettres de
  **compression d'étages, jamais de gain d'horloge** ; la baseline d'horloge inline de la vague 1 de
  cette phase (12 commits identifiés par `git log --grep` ancré) avec sa méthode re-dérivable ; le
  Bloc 3 structuré et vide, avec son cas de sortie honnête en cas de refus d'activation.
- **Précondition D-10 tenue et vérifiée à l'exécution** : `.planning/config.json` ne portait aucune
  clé `claude_orchestration` au moment de l'écriture (`grep -c` → 0), confirmé avant toute écriture
  de la baseline.
- **Découverte non anticipée par le plan, écrite comme cinquième limite** : le plan `27-03` de la
  vague 1 mesurée s'est arrêté à mi-parcours (4 commits, sans `SUMMARY.md`) puis n'a repris que
  ~3h48 plus tard — une pause d'arbitrage humain documentée dans `.planning/STATE.md` §Decisions.
  L'écart de vague est donc reporté en **deux lectures distinctes, jamais fusionnées** : la fenêtre
  de dispatch initial continu (33min43s) et l'écart littéral toutes sessions confondues (4h23min54s,
  dominé à plus de 90 % par la pause).
- L'estimation 1,8-2,5× de l'option d'activation reste explicitement étiquetée **estimée, jamais
  mesurée**.

## Task Commits

Chaque tâche a été commitée atomiquement :

1. **Tâche 1 — Poser le corpus de mesure nommé et prouver qu'il est réellement parallélisable** - `08ca108` (feat)
2. **Tâche 2 — Capturer la baseline d'horloge et écrire la méthode, avant toute activation** - `334a339` (docs)

_Aucune tâche TDD au sens RED→GREEN : les deux tâches sont des livrables de mesure/document, chacune
avec sa propre `<verify>` automatisée exécutée et confirmée avant commit._

## Files Created/Modified

- `.planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-mesure/waves-toy.json` — manifeste de vagues jouet (1 vague, 2 plans, `files_modified` disjoints)
- `.planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-MESURE-GAIN.md` — document de mesure de phase, 3 blocs numérotés + statuts

## Decisions Made

- **Écart de vague en deux lectures distinctes, jamais fusionnées** — voir Accomplishments. Fusionner
  aurait produit un chiffre trompeur (4h23min54s cité seul sans la note de pause humaine), exactement
  le risque `T-27-04-02`/`T-27-04-03` du threat model du plan.
- **`git log --grep` ancré en tête de sujet** (`^[a-z]+\(27-0N\)`) plutôt qu'un motif libre : un motif
  libre `(27-01)` remonte des faux positifs (commits de doctrine/planning mentionnant le plan sans en
  être un commit de tâche) — constaté en exécutant les deux formes et en comparant les sorties.
- **Corpus jouet à briefs anodins**, chemins sous `27-mesure/scratch/` (répertoire jetable, jamais
  créé par ce plan — seul le manifeste JSON l'est) : aucune dépendance de contenu réel entre l'étalon
  et le reste du dépôt.

## Deviations from Plan

None - plan exécuté exactement comme écrit. La découverte de la pause d'arbitrage humain dans le
corpus de la vague 1 n'est pas une déviation d'exécution : c'est un fait du corpus mesuré, écrit dans
`27-MESURE-GAIN.md` conformément à l'exigence `must_haves.truths` du plan (« ce que la mesure ne peut
PAS établir est écrit au même titre que ce qu'elle établit »).

## Issues Encountered

- Premier essai de `git log --grep='(27-01)'` (motif libre, non ancré) remontait des commits de
  doctrine/planning (`docs(27): ...`, `planning(27): ...`) qui mentionnent le plan sans en être un
  commit de tâche — corrigé en ancrant le motif en tête de sujet (`^[a-z]+\(27-0N\)`), vérifié par
  comparaison des deux sorties avant d'écrire les chiffres dans le document.
- La sous-commande Bash de l'environnement refuse les commandes shell composées (plusieurs `&&`/
  redirections dans un seul appel) à l'intérieur de ce worktree — sans impact sur le contenu livré,
  seulement sur la manière dont chaque vérification a été rejouée (décomposée en appels séparés).

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- `27-05` peut maintenant activer `claude_orchestration` : la baseline d'horloge et le plafond
  d'étages sont capturés et documentés, la précondition D-10 est prouvée tenue au moment de la
  capture.
- `27-06` dispose de l'étalon `27-mesure/waves-toy.json`, prouvé parallélisable, et du protocole
  complet du Bloc 3 (même manifeste, run-id fixe, ≥2 répétitions par côté) pour remplir la mesure
  après activation.
- **Point de vigilance à transmettre** : si `27-06` réutilise un jour le corpus réel de la vague 1
  (plutôt que l'étalon jouet) comme référence secondaire, il doit filtrer explicitement la pause
  d'arbitrage humain identifiée ici (23:59:31 → 03:47:44) — sans quoi l'écart de vague se
  confondrait avec un temps d'attente humain plutôt qu'avec un temps de dispatch.

## Self-Check: PASSED

- FOUND: `27-mesure/waves-toy.json`
- FOUND: `27-MESURE-GAIN.md`
- FOUND: `27-04-SUMMARY.md`
- FOUND: commit `08ca108`
- FOUND: commit `334a339`
- FOUND: commit `0a465bf`

---
*Phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision*
*Completed: 2026-08-06*
