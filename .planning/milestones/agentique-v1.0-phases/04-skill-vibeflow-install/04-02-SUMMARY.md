---
phase: 04-skill-vibeflow-install
plan: 02
subsystem: infra
tags: [hooks, session-start, plugin, auto-launch, bash, jq]

requires:
  - phase: 03 (engine vibeflow-update.sh)
    provides: "registre des modules installés à $TARGET_ROOT/scripts/.vibeflow-installed — réutilisé comme marqueur de 1er lancement"
provides:
  - "Hook SessionStart d'auto-lancement : injecte /vibeflow-install au 1er lancement, silencieux ensuite"
  - "installer/hooks/hooks.json (déclaration plugin, matcher startup|clear|compact)"
  - "installer/hooks/session-start (script émetteur/silencieux)"
  - "Test isolé du hook (HOME/cwd temporaires)"
affects: [skill vibeflow-install (04-01), packaging plugin]

tech-stack:
  added: []
  patterns:
    - "Hook SessionStart calqué sur Superpowers (hookSpecificOutput.additionalContext, printf au lieu de heredoc)"
    - "Marqueur de 1er lancement aligné sur le registre de l'engine (segment scripts/) — pas de chemin divergent"

key-files:
  created:
    - installer/hooks/hooks.json
    - installer/hooks/session-start
    - installer/hooks/tests/test-session-start.sh
  modified: []

key-decisions:
  - "Pointer directement le script bash via ${CLAUDE_PLUGIN_ROOT}/hooks/session-start (pas de run-hook.cmd spécifique à Superpowers)"
  - "Marqueurs USER_MARKER=$HOME/.claude/scripts/.vibeflow-installed ET PROJECT_MARKER=./.claude/scripts/.vibeflow-installed — identiques au registre écrit par vibeflow-update.sh"
  - "Émission via printf (bug de hang heredoc bash 5.3+), échappement JSON par escape_for_json"

patterns-established:
  - "Hook lit le marqueur, ne l'écrit jamais (séparation hook=déclencheur / engine=installeur)"
  - "exit 0 inconditionnel : un hook ne casse jamais le démarrage de session"

metrics:
  duration: ~5 min
  completed: 2026-06-04
  tasks: 2
  files: 3
---

# Phase 04 Plan 02 : Hook SessionStart d'auto-lancement /vibeflow-install — Summary

Hook `SessionStart` du plugin VibeFlow qui injecte un `additionalContext` demandant d'ouvrir `/vibeflow-install` au PREMIER lancement (aucun marqueur `scripts/.vibeflow-installed`), et reste totalement silencieux une fois VibeFlow installé. Calqué sur le mécanisme Superpowers, marqueurs alignés sur le registre de l'engine `vibeflow-update.sh`.

## What Was Built

- **`installer/hooks/hooks.json`** — déclare un hook `SessionStart`, matcher `startup|clear|compact`, un hook `command` `async: false` pointant `"${CLAUDE_PLUGIN_ROOT}/hooks/session-start"`. JSON strictement valide (validé par `jq .`, pas de virgule traînante).
- **`installer/hooks/session-start`** — script bash exécutable (`set -euo pipefail`) :
  - `USER_MARKER="${HOME}/.claude/scripts/.vibeflow-installed"`, `PROJECT_MARKER="./.claude/scripts/.vibeflow-installed"` (HOME surchargeable, segment `scripts/` aligné sur l'engine) ;
  - si l'un des marqueurs existe → `exit 0` silencieux (rien sur stdout) ;
  - sinon émet `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"…/vibeflow-install…"}}` via `printf`, texte échappé par `escape_for_json` ;
  - `exit 0` inconditionnel.
- **`installer/hooks/tests/test-session-start.sh`** — test isolé (`mktemp -d` + `trap cleanup`, faux HOME + faux cwd projet). 3 cas, 8 assertions : émission (JSON parsable + `additionalContext` + `vibeflow-install`), silence marqueur user, silence marqueur project ; exit 0 partout.

## Verification

- `jq . installer/hooks/hooks.json` → exit 0 (JSON valide).
- Verify Task 1 → `OK-HOOK` (SessionStart, matcher, script pointé, additionalContext, marqueur `scripts/.vibeflow-installed`, `vibeflow-install`, script exécutable).
- Verify Task 2 → `bash installer/hooks/tests/test-session-start.sh` → **PASS : 8 / FAIL : 0**, exit 0.
- Isolation confirmée : le `~/.claude` réel n'a pas été touché (test écrit uniquement sous `mktemp`).
- Note runtime : l'ouverture EFFECTIVE de l'UX par l'agent au démarrage se valide en session réelle ; ici on valide l'émission/silence selon le marqueur.

## Threat Model Compliance

- **T-04-04 (DoS)** mitigé : `exit 0` inconditionnel, script minimal sans réseau ni écriture.
- **T-04-05 (Spoofing)** : contenu statique du plugin, échappement JSON strict (`escape_for_json`).
- **T-04-06 (Tampering)** : accepté (un marqueur falsifié rend juste le hook silencieux).

## Deviations from Plan

None — plan exécuté exactement comme écrit.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: installer/hooks/hooks.json
- FOUND: installer/hooks/session-start (exécutable)
- FOUND: installer/hooks/tests/test-session-start.sh
- FOUND commit 144418e (feat 04-02 hook)
- FOUND commit c341723 (test 04-02)
