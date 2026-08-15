---
phase: 01-dev-orchestrator
plan: 04
subsystem: abstraction-layer
tags: [skills, vf-verbs, thin-delegator, vocabulary, abstraction, writing-skills, gsd, superpowers]

# Dependency graph
requires:
  - "Index factuel gsd-skills-index.md généré (Plan 01-01) — chaque mapping pointe vers un nom réel"
  - "Bootstrap scripts/ensure-deps.sh livré (Plan 01-02) — invoqué par vf-init"
  - "Agent vibeflow-dev (AGENT.md) avec 12 cibles canoniques figées (Plan 01-03) — source d'alignement"
provides:
  - "Set complet de 12 verbes /vf-* (thin delegators vers GSD/Superpowers/bootstrap) (ABS-01)"
  - "Table de traduction de vocabulaire GSD → VibeFlow (vocabulary-map.md) (ABS-02)"
  - "Couche d'abstraction hybride D2/D6 : raccourcis utilisateur + handles nommés pour l'agent en autonomie"
affects: [01-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Skill thin delegator : frontmatter (name + description multiline FR) + corps minimal (instruction de délégation + reframe), calqué sur consolidator/SKILL.md"
    - "Discipline writing-skills (superpowers 5.1.0) : description 'Utiliser quand...' avec triggers de déclenchement concrets, PAS de résumé de workflow, 1 responsabilité, concision"
    - "Cibles /vf-* strictement alignées sur les 12 cibles canoniques de AGENT.md (aucun mapping orphelin, dépendance 04→03)"
    - "Reframe vocabulaire systématique via renvoi à vocabulary-map.md ; masquage total GSD/Superpowers côté utilisateur"

key-files:
  created:
    - dev-orchestrator/references/vocabulary-map.md
    - dev-orchestrator/skills/vf-dev/SKILL.md
    - dev-orchestrator/skills/vf-brainstorm/SKILL.md
    - dev-orchestrator/skills/vf-plan/SKILL.md
    - dev-orchestrator/skills/vf-execute/SKILL.md
    - dev-orchestrator/skills/vf-quick/SKILL.md
    - dev-orchestrator/skills/vf-test/SKILL.md
    - dev-orchestrator/skills/vf-review/SKILL.md
    - dev-orchestrator/skills/vf-debug/SKILL.md
    - dev-orchestrator/skills/vf-auto/SKILL.md
    - dev-orchestrator/skills/vf-ship/SKILL.md
    - dev-orchestrator/skills/vf-progress/SKILL.md
    - dev-orchestrator/skills/vf-init/SKILL.md
  modified: []

key-decisions:
  - "Authoring via discipline writing-skills (non skill-creator) : skill-creator est un workflow de recherche 5 phases surdimensionné pour des thin delegators sans contenu de connaissance à rechercher"
  - "Descriptions rédigées 'Utiliser quand...' énonçant les triggers de déclenchement concrets (formulations utilisateur couvertes), jamais un résumé de workflow — conformément à la section CSO de writing-skills"
  - "12 cibles identiques à AGENT.md : brainstorming (Superpowers), gsd-discuss-phase + gsd-plan-phase (vf-plan enchaîne les deux), gsd-execute-phase, gsd-quick, gsd-verify-work, gsd-code-review, gsd-debug, gsd-autonomous, gsd-ship, gsd-progress ; vf-init = bootstrap interne (ensure-deps.sh + map-codebase + new-project sur confirmation)"
  - "vocabulary-map.md = traduction du vocabulaire EXPOSÉ uniquement (pas une traduction exhaustive des artefacts) — différé v2 (VOC-01)"
  - "Chaque skill explicite qu'il est invocable par l'utilisateur ET par l'agent en autonomie (D6) ; vf-dev sert de point d'entrée générique de routage"

patterns-established:
  - "Verbe /vf-* = thin delegator : reframe + délégation, ne réimplémente jamais la logique de l'outil"
  - "Alignement strict verbes↔agent sur un jeu unique de cibles canoniques pour éviter toute divergence (warning replan)"

requirements-completed: [ABS-01, ABS-02]

# Metrics
metrics:
  duration: ~6 min
  tasks-completed: 2
  files-created: 13
  completed-date: 2026-06-04
---

# Phase 1 Plan 4 : Couche d'abstraction /vf-* + table de vocabulaire — Summary

**One-liner** : 12 skills `/vf-*` thin delegators (frontmatter + délégation + reframe) mappant 1:1 vers les 12 cibles canoniques de l'agent `vibeflow-dev`, rédigés selon la discipline writing-skills (descriptions à triggers de déclenchement, 1 responsabilité), + une table de traduction GSD → VibeFlow qui masque la plomberie côté utilisateur.

## Ce qui a été livré

- **`references/vocabulary-map.md`** (Task 1) : table `| Terme GSD | Terme VibeFlow |` couvrant SUMMARY → rapport de sprint, ROADMAP → feuille de route, PLAN → plan de travail, phase → étape, milestone → jalon, verify/UAT → recette, + une vingtaine d'autres termes. Note de périmètre explicite (traduction de l'exposé uniquement, v2 VOC-01) et règles d'usage (aucune fuite, reframe systématique).
- **12 skills `/vf-*`** (Task 2) sous `skills/vf-*/SKILL.md`, chacun thin (16–26 lignes, très en dessous de la charte ≤500L) :

| Verbe | Cible réelle (canonique, = AGENT.md) |
|---|---|
| vf-dev | route générique (délègue à vibeflow-dev / au bon verbe) |
| vf-brainstorm | `brainstorming` (Superpowers) |
| vf-plan | `gsd-discuss-phase` puis `gsd-plan-phase` |
| vf-execute | `gsd-execute-phase` |
| vf-quick | `gsd-quick` |
| vf-test | `gsd-verify-work` |
| vf-review | `gsd-code-review` |
| vf-debug | `gsd-debug` |
| vf-auto | `gsd-autonomous` |
| vf-ship | `gsd-ship` |
| vf-progress | `gsd-progress` |
| vf-init | bootstrap interne : `ensure-deps.sh` + `gsd-map-codebase` (si code) + `gsd-new-project` (sur confirmation, BOOT-04) |

## Application de writing-skills (contrainte impérative)

SKILL.md de `writing-skills` (superpowers 5.1.0) lu **avant** d'écrire, puis appliqué :
- **Description = triggers, pas workflow** : chaque description commence par « Utiliser quand… » et énumère des formulations utilisateur concrètes (ex. vf-debug : « ça plante », « crash », « stack trace »), jamais un résumé de la séquence d'actions — conformément à la section CSO (« Description = When to Use, NOT What the Skill Does »).
- **Troisième personne, concision** : descriptions en FR, courtes, sans première personne.
- **Une responsabilité** : un verbe = une cible. vf-dev est explicitement le seul verbe de routage générique.
- **skill-creator NON utilisé** : workflow de recherche 5 phases surdimensionné pour des thin delegators sans connaissance à rechercher (décision documentée).

## Verification

- **Task 1 verify** (`test -f` + `grep 'rapport de sprint'` + `grep 'feuille de route'`) → **exit 0**.
- **Task 2 verify** (boucle 12 verbes : fichier présent + ≤500L + frontmatter `name: vf-<v>` ; puis `gsd-execute-phase`, `gsd-autonomous`, `ensure-deps` présents) → **exit 0**.
- Verifies exécutés sous `/bin/bash -c` avec `command grep` (l'env zsh aliase `grep` en shell function ugrep/rtk) pour un résultat fiable.
- Contrôle complémentaire : les 12 cibles référencées sont identiques à la table de routage de AGENT.md (aucun mapping orphelin), line counts 16–26L.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. Les skills sont des thin delegators par conception (pas de logique métier à câbler) ; chaque corps contient une instruction de délégation effective vers une cible réelle vérifiée.

## Commits

- `5a847b8` feat(01-04): table de traduction de vocabulaire GSD → VibeFlow
- `10f019b` feat(01-04): 12 skills /vf-* thin delegators (ABS-01)

## Self-Check: PASSED

13 fichiers créés + SUMMARY vérifiés présents sur disque ; commits `5a847b8` et `10f019b` présents dans git log.
