---
phase: 30-portabilit-windows-ii
plan: 07
subsystem: hooks-forme-exec
tags: [port-02, adr-071, d-01, d-06]
requires: ["30-01", "30-04", "30-05"]
provides: [hooks-dev-orchestrator-forme-exec, adr-071]
affects: [plugin/dev-orchestrator/hooks/hooks.json, plugin/_internal/tests/test-vibeflow-update.sh, docs/ADR.md]
tech-stack:
  added: []
  patterns: ["forme exec des hooks (command=chemin absolu, args=[script, --hook])", "install réelle exercée par les tests (pas seulement le fragment source)"]
key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/hooks/hooks.json
    - plugin/_internal/tests/test-vibeflow-update.sh
    - docs/ADR.md
    - plugin/dev-orchestrator/VERSION
    - plugin/dev-orchestrator/module.json
    - plugin/dev-orchestrator/CHANGELOG.md
    - plugin/dev-orchestrator/README.md
    - plugin/software-architecture/VERSION
    - plugin/software-architecture/module.json
    - plugin/software-architecture/CHANGELOG.md
    - plugin/software-architecture/README.md
key-decisions:
  - "Les 4 entrées SessionStart de dev-orchestrator basculent de la forme shell (command + || true) à la forme exec (command={{VF_BASH}}, args=[script, --hook]) — même gabarit que software-architecture (plan 30-01). Classement advisory inchangé (ADR-031) ; décompte du parc inchangé à 25 avant l'ajout de la 26e entrée par le plan 30-09."
  - "Preuve d'install réelle ajoutée à test-vibeflow-update.sh (pas seulement lecture du fragment source) — motivée par la régression #38 où un gate qui n'exerce que l'arbre source ne prouve rien sur ce que l'install pose chez l'utilisateur."
  - "ADR-071 grave trois décisions : la forme exec devient la forme des hooks du périmètre dev ; command porte un chemin absolu résolu ET vérifié à l'install (settings.json devient spécifique à la machine, D-01 one-way) ; le contrat de sortie est normalisé DANS chaque script sous --hook, sans lanceur intermédiaire (D-06)."
  - "Bump mineur des deux modules touchés par le changement de forme : dev-orchestrator v2.15.0 → v2.16.0, software-architecture v1.5.2 → v1.6.0 (aucun changement de code pour ce dernier — couverture documentaire par la nouvelle doctrine, son entrée était déjà exec depuis le plan 30-01)."
requirements-completed: [PORT-02]
duration: "non tracé"
completed: "2026-08-16"
coverage:
  - deliverable: "Les 4 entrées SessionStart de dev-orchestrator en forme exec, classées advisory explicitement"
    verification:
      - kind: "command"
        ref: "bash plugin/_internal/tests/test-merge-hooks.sh"
        status: pass
    human_judgment: false
  - deliverable: "Preuve d'install réelle (settings.local.json d'un lab temporaire) + compatibilité descendante"
    verification:
      - kind: "tests/path#name"
        ref: "plugin/_internal/tests/test-vibeflow-update.sh (T10, T10b, T11, T12)"
        status: pass
    human_judgment: false
  - deliverable: "ADR-071 documentant la doctrine de la forme exec des hooks dev"
    verification:
      - kind: "artifact"
        ref: "docs/ADR.md §ADR-071"
        status: pass
    human_judgment: true
  - deliverable: "Triade VERSION/module.json/README des deux modules cohérente"
    verification:
      - kind: "command"
        ref: "bash scripts/check-version-sync.sh"
        status: pass
    human_judgment: false
---

# Phase 30 Plan 07: Migration exec des hooks dev-orchestrator + ADR-071 Summary

Bascule des 4 entrées `SessionStart` de `dev-orchestrator` de la forme shell (`bash … || true`) à
la forme exec (`command` = chemin absolu d'interpréteur résolu à l'install, `args` = script +
`--hook`), preuve d'install réelle ajoutée au gate d'intégration de l'engine, puis doctrine gravée
dans ADR-071.

**Durée** : non tracée. **Tâches** : 3 commits.

## Accomplissements

- `plugin/dev-orchestrator/hooks/hooks.json` (commit `7357043`) : les 4 entrées SessionStart
  passent de la forme shell à la forme exec (`command={{VF_BASH}}`, `args` séparés
  `[script, --hook]`) — même gabarit que `software-architecture` (plan 30-01). L'opérateur
  d'absorption shell disparaît par construction : les 4 scripts traduisent désormais leur silence
  eux-mêmes (plan 30-04, `docs/HOOKS-CONTRAT-SORTIE.md`). Classement explicite advisory dans la
  description du fragment. Décompte du parc inchangé (25, avant l'ajout de la 26e entrée par le
  plan 30-09). Suite `test-merge-hooks.sh` vérifiée verte (23 OK) après la migration.
- `plugin/_internal/tests/test-vibeflow-update.sh` (commit `6a107f3`, +222 lignes) : preuve d'install
  réelle des 5 entrées de hook du périmètre dev (4 dev-orchestrator + 1 software-architecture) dans
  le `settings.local.json` d'un lab temporaire — motivée par la régression #38 (un gate qui
  n'exerce que l'arbre source ne prouve rien sur ce que l'install pose réellement chez
  l'utilisateur). T10 : install réelle → 5 entrées exec, `command` absolu existant exécutable,
  aucun placeholder résiduel, puis désinstall → zéro entrée VF résiduelle. T10b : garde
  anti-vert-à-vide (0 entrée VF fait échouer le cas). T11 : compatibilité descendante — un lab
  portant les 4 hooks dev-orchestrator en ANCIENNE forme shell reçoit, après update réel, ces 4
  entrées purgées de `settings.json` et 4 entrées exec dans `settings.local.json`, sans doublon.
  T12 : mutation — remettre `check-doc-drift.sh` en forme shell dans le fragment fait rougir le cas
  exec-count, en nommant l'entrée fautive absente du décompte. Suite vérifiée verte : 19 OK / 0 KO
  / 0 SKIP ; `test-merge-hooks.sh` inchangé, toujours vert.
- `docs/ADR.md` (commit `a19ab2d`) : ADR-071 grave la doctrine en trois décisions — (1) la forme
  exec devient la forme des hooks du périmètre dev (bascule sur la présence du champ `args`,
  disparition par construction de l'opérateur d'absorption) ; (2) `command` porte un chemin absolu
  d'interpréteur résolu ET vérifié à l'install (conséquence assumée : `settings.json` devient
  spécifique à la machine, D-01 one-way ratifié au plan 30-01) ; (3) le contrat de sortie vers le
  harness est normalisé DANS chaque script sous `--hook`, sans lanceur intermédiaire (D-06). La
  polarité gouvernance (20 entrées restantes) est explicitement laissée hors périmètre, héritée par
  Willy.
- Bump mineur des deux modules touchés par le changement de forme : `dev-orchestrator` v2.15.0 →
  v2.16.0 (`VERSION`, `module.json`, `CHANGELOG.md`, en-tête `README.md`), `software-architecture`
  v1.5.2 → v1.6.0 (aucun changement de code — couverture documentaire par la nouvelle doctrine, son
  entrée était déjà en forme exec depuis le plan 30-01). Triade VERSION/module.json/en-tête README
  des deux modules vérifiée (`check-version-sync.sh`) ; `check-agents.sh --strict` sur
  `dev-orchestrator/agents` conforme (7 warnings pré-existants, 0 erreur). `VERSION` racine,
  `plugin.json` et `marketplace.json` non touchés (release racine = geste humain gaté).

## Deviations from Plan

Non tracé — aucune déviation mentionnée dans les messages des trois commits du plan.

## Next Phase Readiness

Requirement PORT-02 complété. Les 5 entrées de hook du périmètre dev (4 dev-orchestrator + 1
software-architecture) sont en forme exec, prouvées posées ainsi par une install réelle, et la
doctrine qui les gouverne est gravée dans ADR-071. La polarité gouvernance (20 entrées) reste
explicitement héritée par Willy pour sa propre migration.
