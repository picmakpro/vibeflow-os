---
phase: 38-portabilit-multi-runtime-livraison-canal-d-install-migration
plan: 01
subsystem: infra
tags: [bash, gsd-core, codex, install-engine, fidelity-gate]

requires: []
provides:
  - "check-artifact-fidelity.sh : gate lecture seule mesurant, par exécution réelle de la conversion gsd-core, ce qu'un artefact VibeFlow perd vers Codex (name/description/model/memory/disallowedTools/vf-internal/tools) + champs de recette multi_agent_v2/trust_level"
  - "vibeflow-update.sh : bannière [fidelity]/[fidelity-recette] câblée en best-effort à la fin de install_module() et update_module(), sortie relayée verbatim sur stdout"
affects: [38-02, 38-04, 38-05, 38-06]

actuals:
  tokens: 46000
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Résolution de script conductor par cascade 2 positions (TARGET_ROOT/scripts puis CACHE_DIR/conductor/scripts), même patron que generate_agent_command_for/inject_lab_mcp_into_agents — distinct de find_hooks_merger (_internal)"

key-files:
  created:
    - plugin/conductor/scripts/check-artifact-fidelity.sh
    - plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh
  modified:
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/tests/test-vibeflow-update.sh
    - plugin/conductor/VERSION
    - plugin/conductor/CHANGELOG.md
    - plugin/conductor/module.json
    - plugin/conductor/README.md

key-decisions:
  - "Tâche 2 (FIDE-02) : la cascade de résolution du gate décrite littéralement au plan (TARGET_ROOT/scripts -> dirname \"$0\" -> CACHE_DIR/_internal) ne correspond pas à l'emplacement réel de check-artifact-fidelity.sh (conductor/scripts/, jamais _internal/) — appliquée telle quelle elle ne résout JAMAIS le gate. Remplacée par le patron déjà en place dans ce fichier pour les scripts hébergés par conductor (2 positions : TARGET_ROOT/scripts/ puis CACHE_DIR/conductor/scripts/), prouvé par install réelle en sandbox."
  - "Root README.md/README.fr.md hors périmètre du mandat (69->70 suites déjà couvert par un lot concurrent, check-version-sync.sh déjà vert à 70/70) : aucune modification nécessaire, conforme à l'interdiction explicite du mandat de toucher ces fichiers."

requirements-completed: [FIDE-01, FIDE-02]

coverage:
  - id: D1
    description: "check-artifact-fidelity.sh mesure par exécution réelle de gsd-core (convertClaudeAgentToCodexAgent) ce qui est PRESERVED/DEGRADED/LOST par champ, pour --target codex, sur un artefact réel du dépôt"
    requirement: "FIDE-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Champs de recette multi_agent_v2/trust_level déclarés en tête de sortie (ligne [fidelity-recette]), avant la ligne [fidelity]"
    requirement: "FIDE-01"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh#T6.ordre"
        status: pass
    human_judgment: false
  - id: D3
    description: "install_module()/update_module() invoquent le gate en best-effort et relaient sa sortie verbatim sur le stdout de l'install/update, pour tout module posant un artefact agent"
    requirement: "FIDE-02"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T24"
        status: pass
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T26"
        status: pass
    human_judgment: false
  - id: D4
    description: "Absence best-effort : gate/conductor absent du cache -> install continue (rc=0), silence total, jamais une dégradation du reste du diagnostic d'install"
    requirement: "FIDE-02"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T25"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-08-28
status: complete
---

# Phase 38 Plan 01: Gate de fidélité de conversion gsd-core + bannière câblée dans l'engine Summary

**check-artifact-fidelity.sh mesure par exécution réelle de gsd-core ce qu'une conversion vers
Codex perd (model/memory/disallowedTools/vf-internal, tools dégradé en prose) et déclare
multi_agent_v2/trust_level comme préconditions de recette ; vibeflow-update.sh relaie cette mesure
verbatim à la fin de chaque install/update d'un module à agent.**

## Performance

- **Duration:** ~55 min (Tâche 1 déjà livrée au commit `540324c` lors d'une session antérieure ;
  cette exécution reprend à la Tâche 2, FIDE-02)
- **Tasks:** 2 (Tâche 1 pré-existante, Tâche 2 exécutée dans cette session)
- **Files modified (Tâche 2):** 6

## Accomplishments
- Gate de fidélité `check-artifact-fidelity.sh` (Tâche 1, déjà livré) : verdict par champ mesuré
  par exécution réelle de `convertClaudeAgentToCodexAgent`, jamais une table recopiée.
- Bannière `[fidelity]`/`[fidelity-recette]` câblée dans `install_module()` et `update_module()`
  (Tâche 2, cette session) : sortie relayée verbatim, best-effort, deux points de couture.
- `find_fidelity_gate()` : cascade de résolution corrigée (déviation documentée ci-dessous) pour
  correspondre à l'emplacement réel du script.
- 3 tests neufs (T24/T25/T26) dans `test-vibeflow-update.sh`, rouge-avant-vert prouvé.
- `conductor` bumpé v1.28.4 → v1.29.0 (minor) sur les 4 sources.

## Task Commits

1. **Tâche 1 : gate de fidélité (FIDE-01)** - `540324c` (feat, session antérieure)
2. **Tâche 2 : test rouge-avant-vert (FIDE-02)** - `f43f76c` (test)
3. **Tâche 2 : câblage engine + bump conductor (FIDE-02)** - `e6df9cc` (feat)

## Files Created/Modified
- `plugin/conductor/scripts/check-artifact-fidelity.sh` - gate de fidélité (Tâche 1)
- `plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh` - suite dédiée (Tâche 1, 17/17)
- `plugin/_internal/vibeflow-update.sh` - `find_fidelity_gate()` + `report_artifact_fidelity()`,
  appelées en fin de `install_module()` et `update_module()`
- `plugin/_internal/tests/test-vibeflow-update.sh` - T24 (bannière à l'install), T25 (silence
  best-effort), T26 (bannière à l'update, 2e couture)
- `plugin/conductor/VERSION`, `module.json`, `CHANGELOG.md`, `README.md` - bump v1.29.0 (minor)

## Decisions Made
- **Cascade de résolution du gate corrigée (Rule 1 — bug de spécification).** Le plan décrivait
  une cascade `TARGET_ROOT/scripts/` → `$(dirname "$0")` → `CACHE_DIR/_internal/`, présentée comme
  « déjà écrite dans vf-update/SKILL.md ». Vérification faite : le SKILL.md documente une cascade
  DIFFÉRENTE côté consommateur lab (`$HOME/.claude/scripts/` → `./.claude/scripts/` →
  `${CLAUDE_PLUGIN_ROOT}/conductor/scripts/`), et ni l'une ni l'autre ne correspond à
  l'emplacement réel de `check-artifact-fidelity.sh` (`plugin/conductor/scripts/`, jamais
  `_internal/` — `$(dirname "$0")` résout vers `_internal/` car c'est le dossier de
  `vibeflow-update.sh` lui-même, pas du gate). Appliquée littéralement, la cascade du plan ne
  résout JAMAIS le fichier : le gate serait introuvable sur toute install réelle et FIDE-02 serait
  un no-op silencieux permanent. Remplacée par le patron déjà exercé dans ce même fichier pour les
  scripts hébergés par `conductor` (`generate_agent_command_for` ligne ~922,
  `inject_lab_mcp_into_agents` ligne ~960) : `TARGET_ROOT/scripts/` puis
  `CACHE_DIR/conductor/scripts/`. Prouvé par install réelle en sandbox `mktemp -d`, avec conductor
  au cache (bannière produite) et sans (silence best-effort, rc=0).
- **Root README.md/README.fr.md non touchés.** Le plan (Tâche 2) prévoyait de corriger
  « 68 suites » → « 69 suites » dans les deux README racine. Mesure faite : le dépôt affiche déjà
  70 suites (`find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` = 70), et
  `scripts/check-version-sync.sh` est déjà vert à 70/70 — un autre lot concurrent de la Phase 38 a
  déjà fait progresser ce compteur. Aucune édition nécessaire ; conforme aussi à l'interdiction
  explicite du mandat reçu de toucher ces deux fichiers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Cascade de résolution du gate corrigée**
- **Found during:** Tâche 2, écriture de `find_fidelity_gate()`
- **Issue:** La cascade décrite au plan (`TARGET_ROOT/scripts` → `dirname "$0"` → `CACHE_DIR/_internal`) ne peut jamais résoudre `check-artifact-fidelity.sh`, hébergé sous `conductor/scripts/`
- **Fix:** Cascade à 2 positions alignée sur le patron déjà en place pour les scripts conductor (`TARGET_ROOT/scripts/` puis `CACHE_DIR/conductor/scripts/`)
- **Files modified:** `plugin/_internal/vibeflow-update.sh`
- **Verification:** Install réelle en sandbox avec/sans conductor au cache (bannière produite / silence best-effort), T24/T25/T26
- **Committed in:** `e6df9cc`

---

**Total deviations:** 1 auto-fixed (1 bug de spécification, cascade de résolution corrigée pour correspondre à l'emplacement réel du fichier)
**Impact on plan:** Correction nécessaire à la correction de fonctionnement même de FIDE-02 — sans elle, la bannière ne serait jamais apparue. Aucune dérive de périmètre.

## Issues Encountered
None.

## Verification (plan-level)

1. `bash plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh` → **17/17 OK, exit 0**
2. Install de sonde (sandbox `mktemp -d`, `content-bundle` + `conductor` au cache) → ligne
   `[fidelity] ./.claude/agents/content-clarity-judge.md -> codex: PRESERVED={name,description}
   DEGRADED={tools} LOST={model,memory,disallowedTools,vf-internal} DEAD_MARKERS=0 (non
   réécrits)` capturée verbatim sur stdout, précédée de `[fidelity-recette] multi_agent_v2=false
   trust_level=non mesurable (racine du dépôt cible introuvable)`.
3. `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` = **70** ; les deux README
   racine affichent déjà `70 suites` (aucune modification requise ce lot-ci).
4. `bash scripts/check-version-sync.sh` → **exit 0**.
5. Rejeu ciblé (périmètre du mandat uniquement, pas la découverte complète — geste réservé au
   manager) :
   - `bash plugin/_internal/tests/test-vibeflow-update.sh` → **34/34 OK, 0 KO**
   - `bash plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh` → **17/17 OK, 0 KO**

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Lot 1 (FIDE-01/02) complet : `exec-gate` et `exec-gate-wire` peuvent tous deux passer `done`
  côté DAG mission ; `revue-gate` (dépend des deux) est débloquée côté manager.
- Le champ FIDE au `status` cité par les lots ADPT (5) et MIGR (6) a son point d'ancrage réel :
  la bannière `[fidelity]` est désormais produite par l'engine, pas seulement par le gate isolé.
- Aucun blocage.

---
*Phase: 38-portabilit-multi-runtime-livraison-canal-d-install-migration*
*Completed: 2026-08-28*
