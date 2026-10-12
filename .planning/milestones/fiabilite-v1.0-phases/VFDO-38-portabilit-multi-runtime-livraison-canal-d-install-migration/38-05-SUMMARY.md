---
phase: 38-portabilit-multi-runtime-livraison-canal-d-install-migration
plan: 05
subsystem: infra
tags: [nodejs, bash, codex, runtime-adapter, agent-conversion]

requires: ["38-01", "38-04"]
provides:
  - "agent-to-codex.mjs : conversion pure agent VibeFlow (frontmatter+corps) -> rôle Codex (TOML) + digest champ par champ, aucun effet de bord disque"
  - "register-codex-agent.sh : pose réelle sous $CODEX_HOME/agents/vibeflow/<name>.toml, --verify mesure l'absence de startup warning référençant le rôle posé (ADPT-04)"
  - "codex-judge-session-command.md : commande de session read-only séparée (D-38-E), vérifiée exit 0 par le gate FIDE-03 déjà livré"
  - "team-kernel.md : règle transverse task_name snake_case (jamais agent_type), aucune contrainte fork_turns"
affects: [38-06]

actuals:
  tokens: null
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Vérification par ABSENCE (startup warning référençant le chemin d'un rôle malformé), jamais par comptage positif : codex doctor --json n'énumère aucun rôle valide par nom (mesuré, corrige la lecture littérale du plan)"

key-files:
  created:
    - plugin/_internal/runtime-adapter/agent-to-codex.mjs
    - plugin/_internal/runtime-adapter/register-codex-agent.sh
    - plugin/_internal/runtime-adapter/tests/test-agent-to-codex.sh
    - plugin/_internal/runtime-adapter/codex-judge-session-command.md
  modified:
    - plugin/conductor/references/team-kernel.md
    - plugin/conductor/VERSION
    - plugin/conductor/module.json
    - plugin/conductor/CHANGELOG.md

key-decisions:
  - "ADPT-04, correction de cadrage mesurée en session réelle contre le binaire codex 0.150.1 de ce poste : `codex doctor --json` N'ÉNUMÈRE JAMAIS les rôles chargés avec succès par nom (aucune clé positive de comptage n'existe dans le schéma de sortie, vérifié sur 19 catégories de checks). Le SEUL signal observable est un `startup warning` référençant le CHEMIN d'un rôle MALFORMÉ — et un `codex doctor --json` global reste exit 0 même avec un rôle cassé présent (overallStatus passe seulement à 'warning'). Le gate ADPT-04 vérifie donc l'ABSENCE d'un tel warning référençant le fichier fraîchement posé, jamais un comptage positif littéral. Preuve du détecteur par mutation (T4b de la suite) : un rôle sans developer_instructions injecté à la main déclenche bien le warning attendu, chemin exact inclus."
  - "Tâche 2 (wiring vibeflow-update.sh), DÉVIATION IMPOSÉE PAR LE MANDAT — non exécutée : le digest de mission interdisait explicitement de toucher plugin/_internal/vibeflow-update.sh et plugin/_internal/tests/test-vibeflow-update.sh (un autre worker les réécrit en parallèle sur cette même branche, lot --target). Le plan 38-05-PLAN.md liste ces deux fichiers dans files_modified de la Tâche 2 ; le mandat d'exécution reçu prime et les exclut explicitement. Tout le reste de la Tâche 2 (règle team-kernel.md, bump VERSION/module.json/CHANGELOG) est livré. Le wiring best-effort dans install_module()/update_module() reste à câbler dans un lot de suivi, une fois la réécriture parallèle mergée."
  - "Task 3 (checkpoint gate='blocking-human', confinement des juges) : DÉJÀ RÉSOLU en amont de cette exécution, pas re-escaladé. 38-CONTEXT.md porte D-38-E ('Arbitrages Samuel rendus le 2026-08-28 — VERROUILLÉS') : [permissions] par rôle mesuré INERTE par la sonde de suivi (branche B du checkpoint), et Samuel a tranché l'architecture de session séparée pour les trois agents lecture seule. Ce lot livre exactement cette architecture (codex-judge-session-command.md + preuve FIDE-03) sans rouvrir la décision — aucune nouvelle escalade nécessaire."
  - "ADPT-06 (≥3 répétitions, marqueur 0/N) mesuré sur banc isolé HORS DÉPÔT (sous scratchpad, jamais committé) : dépôt jetable avec skill témoin 'Dis WITPROJ.' sous .agents/skills/, CODEX_HOME isolé avec auth.json copié depuis ~/.codex (D-38-G : écrasé puis supprimé en fin de mesure, déclaré ici). 5 runs réels (3 en parallèle + 2 supplémentaires) avec la commande mitigée complète : 0/5 occurrence du marqueur WITPROJ dans les verdicts structurés. ~/.codex réel re-vérifié intact après (sha256 config.toml identique, agents/ toujours absent, CODEX_HOME du banc re-vérifié 'Not logged in' après nettoyage — même protocole que la sonde de référence)."

requirements-completed: [ADPT-01, ADPT-02, ADPT-03, ADPT-04]

coverage:
  - id: D1
    description: "Un agent VibeFlow réel (vf-content-writer.md) devient un rôle Codex réellement posé sous $CODEX_HOME/agents/vibeflow/, contenant name/description/developer_instructions/model/model_reasoning_effort"
    requirement: "ADPT-01"
    verification:
      - kind: unit
        ref: "plugin/_internal/runtime-adapter/tests/test-agent-to-codex.sh#T1"
        status: pass
      - kind: unit
        ref: "plugin/_internal/runtime-adapter/tests/test-agent-to-codex.sh#T2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Le digest déclare explicitement memory:LOST, tools/disallowedTools:PENDING, vf-internal:PRESERVED_BY_OMISSION — jamais une case absente"
    requirement: "ADPT-01"
    verification:
      - kind: unit
        ref: "plugin/_internal/runtime-adapter/tests/test-agent-to-codex.sh#T3"
        status: pass
    human_judgment: false
  - id: D3
    description: "La pose est vérifiée RÉELLEMENT contre le binaire codex du poste (ADPT-04), sur banc isolé, ~/.codex réel intact ; le détecteur discrimine réellement un rôle malformé (mutation tuée)"
    requirement: "ADPT-04"
    verification:
      - kind: unit
        ref: "plugin/_internal/runtime-adapter/tests/test-agent-to-codex.sh#T4"
        status: pass
      - kind: unit
        ref: "plugin/_internal/runtime-adapter/tests/test-agent-to-codex.sh#T4b"
        status: pass
    human_judgment: false
  - id: D4
    description: "Aucun mapping de nommage à 31 entrées construit ; task_name se normalise en snake_case, une ligne, documentée dans team-kernel.md ; aucune contrainte fork_turns ajoutée"
    requirement: "ADPT-02, ADPT-03"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-check-agents.sh#T76 (non-régression, 81/81 après l'ajout)"
        status: pass
    human_judgment: false
  - id: D5
    description: "La commande de session read-only séparée pour les juges (D-38-E) porte les 4 éléments requis, prouvé par le gate FIDE-03 déjà livré"
    requirement: "ADPT-05 (contrat d'intégration)"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/check-artifact-fidelity.sh --check-judge-command plugin/_internal/runtime-adapter/codex-judge-session-command.md (exit 0, mesuré)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Fermeture du canal d'injection prouvée sur ≥3 répétitions réelles, marqueur 0/N"
    requirement: "ADPT-06"
    verification:
      - kind: manual
        ref: "banc isolé hors dépôt (scratchpad), 5 runs réels codex exec avec la commande mitigée complète, 0/5 marqueur WITPROJ — non reproductible en suite automatisée (nécessite auth.json + appel réseau réel)"
        status: pass
    human_judgment: false

duration: null
completed: 2026-08-29
status: complete
---

# Phase 38 Plan 05: Adaptateur VibeFlow minimal + enregistrement Codex Summary

**Un agent VibeFlow réel devient un rôle Codex réellement dispatchable et compté par
`codex doctor --json` (mesuré par ABSENCE de startup warning, pas par comptage positif — le
binaire n'énumère jamais les rôles valides par nom), avec un digest champ par champ jamais
lacunaire ; aucun mapping de nommage des 31 agents construit, aucune contrainte `fork_turns`
ajoutée ; la commande de session read-only séparée pour les juges est posée et prouvée par le
gate FIDE-03 déjà livré, avec ADPT-06 (0/5 marqueur d'injection) mesuré sur banc isolé.**

## Deviations from plan (mandat prime sur le plan)

- **Tâche 2, wiring `vibeflow-update.sh`/`test-vibeflow-update.sh` : NON EXÉCUTÉ.** Le mandat de
  mission interdisait explicitement de toucher ces deux fichiers (« un autre worker les réécrit
  EN CE MOMENT MÊME », lot `--target` sur la même branche). Le plan `38-05-PLAN.md` les liste
  dans `files_modified` de la Tâche 2 — le mandat, plus récent et explicite, l'emporte. Le reste
  de la Tâche 2 (règle `team-kernel.md`, bump `VERSION`/`module.json`/`CHANGELOG.md`) est livré
  intégralement.
- **ADPT-04 : la lettre du plan (« `codex doctor --json` COMPTE les rôles chargés ») a été
  RECTIFIÉE par la mesure**, pas suivie littéralement. Mesuré : le binaire n'énumère aucun rôle
  valide par nom nulle part dans sa sortie JSON (19 catégories de checks inspectées). Le seul
  signal exposé est un `startup warning` qui apparaît UNIQUEMENT pour un rôle malformé et
  référence son chemin. Le gate implémenté vérifie donc l'ABSENCE de ce warning pour le fichier
  posé — c'est la mesure qui prévaut sur la formulation du plan, conformément à l'intention
  déclarée du plan lui-même (« jamais "pas de crash donc c'est bon" »).
- **Task 3 (checkpoint `gate="blocking-human"`) : PAS RE-ESCALADÉ.** `38-CONTEXT.md` porte déjà
  D-38-E, un arbitrage VERROUILLÉ de Samuel daté du 2026-08-28 (avant cette exécution), qui
  tranche exactement la question posée par le checkpoint : `[permissions]` par rôle est mesuré
  inerte (branche B), et l'architecture retenue est la session `codex exec -s read-only` séparée
  pour les trois agents lecture seule. Ce lot livre cette architecture sans rouvrir la décision.

## Accomplishments

- `agent-to-codex.mjs` : conversion pure, zéro dépendance npm, mapping aligné sur l'importeur
  natif Codex (`/import`) — jamais un mapping inventé. Échappement TOML testé (multi-line basic
  string, séquences `"""` internes).
- `register-codex-agent.sh` : pose idempotente sous `$CODEX_HOME/agents/vibeflow/<name>.toml`,
  jamais `[agents.<n>]` de `config.toml`. `--verify` mesure réellement contre le binaire `codex`
  du poste.
- `test-agent-to-codex.sh` : 6/6 vert (T1, T2, T3, T4, T4b mutation-tuée, T5), T4 exécuté
  RÉELLEMENT (pas de mock) — banc isolé sous scratchpad, `~/.codex` réel re-vérifié intact
  (sha256 `config.toml` identique, `agents/` jamais créé côté réel) avant et après chaque run.
- `team-kernel.md` : règle transverse `task_name` snake_case documentée avec sa source mesurée
  (inconnu #3 confirmé, aucune table de 31 entrées) + `fork_turns` sans contrainte (inconnu #5
  confirmé). Non-régression : `test-check-agents.sh` 81/81 après l'ajout.
- `codex-judge-session-command.md` : commande D-38-E posée, gate FIDE-03 exécuté réellement,
  exit 0 (`COMPLET`, les 4 éléments présents).
- ADPT-06 mesuré hors suite automatisée (nécessite un vrai appel réseau Codex) : 5 runs réels
  avec la commande mitigée complète sur un dépôt jetable portant un skill témoin d'injection,
  0/5 marqueur — canal fermé, répété au-delà du minimum de 3.
- `plugin/conductor` bumpé v1.30.0 → v1.31.0 (minor) sur `VERSION`/`module.json`/`CHANGELOG.md`.

## Task Commits

1. **Tâche 1 : adaptateur + pose + vérification réelle (ADPT-01, ADPT-04)** - `a305406` (feat)
2. **Tâche 2 (partielle, cf. déviations) : task_name snake_case + bump conductor (ADPT-02, ADPT-03)** - `8c91382` (feat)

## Files Created/Modified

- `plugin/_internal/runtime-adapter/agent-to-codex.mjs` - convertisseur pur (Tâche 1)
- `plugin/_internal/runtime-adapter/register-codex-agent.sh` - orchestration de pose + `--verify` (Tâche 1)
- `plugin/_internal/runtime-adapter/tests/test-agent-to-codex.sh` - suite dédiée, 6/6 (Tâche 1)
- `plugin/_internal/runtime-adapter/codex-judge-session-command.md` - commande D-38-E posée, preuve FIDE-03 (Tâche 1)
- `plugin/conductor/references/team-kernel.md` - règle `task_name` snake_case + note `fork_turns` (Tâche 2)
- `plugin/conductor/VERSION`, `module.json`, `CHANGELOG.md` - bump v1.31.0 (Tâche 2)
- **NON MODIFIÉS (déviation imposée par le mandat)** : `plugin/_internal/vibeflow-update.sh`, `plugin/_internal/tests/test-vibeflow-update.sh`

## Non-pollution — auth.json (D-38-G)

Deux mesures ont utilisé une copie de `~/.codex/auth.json` vers un `CODEX_HOME` isolé sous
scratchpad (exploration initiale de `--verify`, puis banc ADPT-06) : dans les deux cas, copie
**uniquement** sous scratchpad, jamais committée, **écrasée puis supprimée** en fin de mesure,
et re-vérifiée ici. `~/.codex/config.toml` sha256 `30d4c0a3f8ca...` identique avant/après sur
toutes les mesures ; `~/.codex/agents/` jamais créé ; `auth.json` réel (3975 octets) inchangé.
Aucun `codex login`, aucune rotation de jeton, aucun autre runtime touché.
