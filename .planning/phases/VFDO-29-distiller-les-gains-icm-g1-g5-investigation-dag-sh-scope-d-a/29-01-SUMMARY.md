---
phase: 29-distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a
plan: 01
subsystem: docs
tags: [dag, requirements-ledger, investigation, non-regression]

requires:
  - phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision
    provides: "dag.sh --scope declaration (Phase 20) + stages/partitionStages() disjunction (Phase 27, ADR-069/070)"
provides:
  - "Rapport durable d'investigation dag.sh --scope (reports/research/2026-08-15-investigation-dag-scope.md) : historique en deux phases par commit, inventaire des consommateurs, couverture test-dag.sh, verdict intouchable/extensible, voie G1"
  - "Ledger .planning/REQUIREMENTS.md section Phase 29 : 12 exigences ICMD-01..12, tracées aux 5 plans de la phase, couverture 0 non-mappé"
affects: [29-02, 29-03, 29-04, 29-05]

actuals:
  tokens: 5440
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - reports/research/2026-08-15-investigation-dag-scope.md
  modified:
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Le négatif du périmètre de G1 se compose de deux champs déjà émis (scope[] du nœud + status --frozen des autres nœuds) : zéro ligne de dag.sh à toucher pour livrer G1 (D-03 suffisant sans activer le repli doctrine-seule)."
  - "Citation historique corrigée : le mécanisme --scope vient de Phase 20 (D-13 de 20-CONTEXT.md), pas de Phase 27 — la forme fautive amalgamant les deux n'apparaît nulle part dans le rapport ni ailleurs sous plugin/ ou reports/."
  - "Préfixe ICMD justifié en tête de section comme acronyme interne de traçabilité, explicitement non constitutif d'une adoption du label de la méthodologie externe."

patterns-established:
  - "Rapport d'investigation consolidé et durable sous reports/research/ plutôt qu'un artefact de planification périssable — reproductible pour toute future précondition transverse de non-régression."

requirements-completed: [ICMD-01, ICMD-02]

coverage:
  - id: D1
    description: "Baseline test-dag.sh constatée verte par exécution avant tout geste (99 PASS / 0 FAIL), et re-vérifiée verte après commit"
    requirement: "ICMD-02"
    verification:
      - kind: other
        ref: "bash plugin/conductor/scripts/tests/test-dag.sh (exécuté 3x pendant la tâche : avant écriture, après rapport, après ledger)"
        status: pass
  - id: D2
    description: "Rapport d'investigation dag.sh --scope autonome, sourcé (3 SHA courts, 13 références fichier:ligne), 5 sections, verdict INTOUCHABLE (4 entrées) / EXTENSIBLE (3 entrées), voie G1 avec clause de halte"
    requirement: "ICMD-01"
    verification:
      - kind: other
        ref: "reports/research/2026-08-15-investigation-dag-scope.md"
        status: pass
  - id: D3
    description: "Aucune occurrence de la citation historique fautive (amalgame Phase 27 / D-13 de 20-CONTEXT.md) dans le rapport ni ailleurs sous plugin/ ou reports/"
    requirement: "ICMD-01"
    verification:
      - kind: other
        ref: "grep -rn '27/D-13' plugin/ reports/ → aucune ligne"
        status: pass
  - id: D4
    description: "dag.sh et test-dag.sh hors du diff des deux commits de ce plan"
    requirement: "ICMD-02"
    verification:
      - kind: other
        ref: "git diff --name-only -- plugin/conductor/scripts/dag.sh plugin/conductor/scripts/tests/test-dag.sh → vide"
        status: pass
  - id: D5
    description: "12 exigences ICMD-01..12 créées, vérifiables, tracées (table Traceability) et couvertes (paragraphe Coverage), union des champs requirements: des 5 PLAN.md = 12 IDs exacts"
    requirement: "ICMD-01, ICMD-02"
    verification:
      - kind: other
        ref: "grep -c '^- \\[ \\] \\*\\*ICMD-' .planning/REQUIREMENTS.md → 12 ; boucle traçabilité → traceability-ok ; comm sur requirements: des 5 plans → 12"
        status: pass
---

## Accomplishments

- Baseline `test-dag.sh` constatée verte AVANT toute écriture (99 PASS / 0 FAIL, rc=0) — précondition
  D-03 satisfaite par exécution réelle, jamais présumée.
- `reports/research/2026-08-15-investigation-dag-scope.md` créé : consolide `29-RESEARCH.md`
  §Investigation (l.341-448) en livrable durable et autonome — historique en deux phases par
  commit (Phase 20 déclaration D-13, Phase 27 calcul `stages` + fermeture RCE ADR-069/070),
  inventaire de 11 lignes couvrant les objets liés à `scope[]` (9 consommateurs réels, 2 objets
  distincts signalés comme tels et exclus du compte) avec leur nature exacte, couverture des 33 cas de
  `test-dag.sh` sur le périmètre, verdict INTOUCHABLE (4 entrées) / EXTENSIBLE SANS RISQUE
  (3 entrées), et la voie retenue pour G1 (négatif composé de deux champs déjà émis, zéro ligne de
  `dag.sh` à toucher) avec sa clause de halte.
- Correction de la citation historique fautive (§Pitfall 1 de `29-RESEARCH.md`) appliquée dans le
  rapport sans jamais reproduire la forme incorrecte — vérifié par grep repo-wide (`plugin/`,
  `reports/`) : aucune occurrence.
- Section « Hors-milestone — Phase 29 » ajoutée à `.planning/REQUIREMENTS.md` : 12 exigences
  `ICMD-01..12` vérifiables couvrant l'investigation, G3, G1+G5, G2 et la clôture de distribution,
  chacune renvoyant à sa décision (D-01/D-02/D-03) quand applicable, tracées dans la table
  `## Traceability` (`Planned — plan 29-0N`), et couvertes par un paragraphe `**Coverage:**` dédié.
  Bloc « Hors périmètre, verrouillé » nommant G4, les gains secondaires, `dag.sh` et `.planning/`.
- `dag.sh` et `test-dag.sh` restent intacts sur les deux commits de ce plan (`git diff --name-only`
  vide) ; suite re-vérifiée verte après chaque écriture.

## Deviations from Plan

Aucune. Les deux tâches ont été exécutées telles que planifiées, dans l'ordre, avec vérification
de chaque critère d'acceptance avant commit.

## Note hors périmètre du plan (observation, pas une action)

`git status --porcelain .planning/` filtré (hors `REQUIREMENTS.md`/`ROADMAP.md`/`STATE.md`/
`phases/VFDO-29-*`) fait apparaître deux entrées untracked pré-existantes au démarrage de ce
mandat : `.planning/DRIVER.lock` et `.planning/DRIVER.lock.gen.1786761864.49593/` (mécanisme de
verrou de driver, hors du `files_modified` de ce plan, non créées ni modifiées par cette tâche).
Signalé pour traçabilité, sans action — hors du périmètre de fichiers `exec-01`.
