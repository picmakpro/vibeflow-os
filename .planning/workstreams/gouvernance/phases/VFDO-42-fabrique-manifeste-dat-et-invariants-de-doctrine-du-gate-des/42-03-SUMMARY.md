---
phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des
plan: 03
subsystem: agents
tags: [frontmatter, SendMessage, team-kernel, growth-bundle, design-orchestrator, invariant-I6]

# Dependency graph
requires:
  - phase: 42-01
    provides: plugin/conductor/scripts/check-agents-manifest.json, gate durci sur les 6 listes datées
  - phase: 42-02
    provides: patron de mise en conformité I6 (SendMessage sur manager) déjà appliqué à business-pilot-bundle et content-bundle
provides:
  - "vf-growth-manager.md et vf-design-manager.md portent SendMessage (invariant I6, D-07) — les deux derniers managers du corpus en violation I6 sont désormais conformes"
  - "growth-bundle bumpé v2.0.9 -> v2.0.10, design-orchestrator bumpé v1.5.8 -> v1.5.9, chacun dans un commit dédié"
affects: [42-05, 42-06]

# Actuals (#2632)
actuals:
  tokens: 2265
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Correction de frontmatter pur (invariant I6) : insertion du token SendMessage juste avant Agent( dans la ligne tools:, corps de l'agent inchangé octet pour octet (cmp), colonne du ratchet d'instructions inchangée (INSTR-INCHANGE)"

key-files:
  created: []
  modified:
    - plugin/growth-bundle/agents/vf-growth-manager.md
    - plugin/growth-bundle/VERSION
    - plugin/growth-bundle/module.json
    - plugin/growth-bundle/CHANGELOG.md
    - plugin/growth-bundle/README.md
    - plugin/design-orchestrator/agents/vf-design-manager.md
    - plugin/design-orchestrator/VERSION
    - plugin/design-orchestrator/module.json
    - plugin/design-orchestrator/CHANGELOG.md
    - plugin/design-orchestrator/README.md

key-decisions:
  - "I5 (omitClaudeMd sur growth-quality-judge.md et vf-design-judge.md) est sortie de ce plan — restructuration mission revise-42b/B1 : D-19 a rendu son verdict (omitClaudeMd retire aussi les règles .claude/rules/*.md), D-08 est réexaminée avec Samuel, réponse non reçue. Sa pose vit désormais derrière le checkpoint bloquant de 42-05 (Tâche 2), conditionnelle à cet arbitrage."
  - "SendMessage sur les deux managers reste inconditionnel en vague 1 (ne dépend d'aucune réponse de Samuel) — appliqué tel quel par ce plan."
  - "design-orchestrator est de la polarité de Samuel (D-12) : son commit est explicitement destiné à sa relecture en PR, consigné dans le corps du commit."

patterns-established:
  - "Un commit par module (D-12), séparé du gate, chacun avec son bump patch (VERSION, module.json, README, CHANGELOG) — reproduit identiquement à 42-02 pour les deux derniers managers I6."

requirements-completed: []  # FABR-05 est partagée (42-01/02/03/05/06, gate #2388) — pas encore prête : 42-05/42-06 n'ont pas de SUMMARY.md à ce stade de la vague. requirements.mark-complete --ws gouvernance a par ailleurs un bug connu dans cette version de gsd-core (résout silencieusement fiabilite) — non invoqué pour cette raison en plus de la garde #2388.

coverage:
  - id: D1
    description: "vf-growth-manager.md porte SendMessage dans tools:, juste avant Agent( ; corps inchangé octet pour octet à main ; growth-quality-judge.md non touché"
    requirement: "FABR-05"
    verification:
      - kind: other
        ref: "sonde CORPUS-GB-OK (verify Tâche 1) : cmp corps + check-agents.sh --strict + test-growth-bundle.sh + check-version-sync.sh, tous verts"
        status: pass
      - kind: other
        ref: "check-instruction-budget.sh : INSTR-INCHANGE pour vf-growth-manager.md, BILAN 0 depassement(s) code=0"
        status: pass
    human_judgment: false
  - id: D2
    description: "vf-design-manager.md porte SendMessage dans tools:, juste avant Agent( ; T8 de test-design-orchestrator.sh reste vert (allowlist complète, vf-dev-manager absent, parenthèse fermée) ; vf-design-judge.md non touché"
    requirement: "FABR-05"
    verification:
      - kind: other
        ref: "sonde CORPUS-DO-OK (verify Tâche 2) : cmp corps + check-agents.sh --strict + test-design-orchestrator.sh (incl. T8) + check-version-sync.sh, tous verts"
        status: pass
      - kind: other
        ref: "check-instruction-budget.sh : INSTR-INCHANGE pour vf-design-manager.md, BILAN 0 depassement(s) code=0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Deux modules bumpés en patch (growth-bundle v2.0.9->v2.0.10, design-orchestrator v1.5.8->v1.5.9), triade VERSION/module.json/README/CHANGELOG cohérente, chacun dans un commit dédié séparé du gate et de .planning/"
    requirement: "FABR-05"
    verification:
      - kind: other
        ref: "scripts/check-version-sync.sh — rc 0, triade 17 modules alignée"
        status: pass
      - kind: other
        ref: "git diff --name-only entre les deux commits confirme aucun fichier hors plugin/growth-bundle/ ou plugin/design-orchestrator/"
        status: pass
    human_judgment: false

duration: ~15min
completed: 2026-09-24
status: complete
---

# Phase 42 Plan 03: growth-bundle et design-orchestrator — managers conformes à I6 (SendMessage) Summary

**vf-growth-manager et vf-design-manager gagnent SendMessage dans leur allowlist `tools:` (invariant I6, D-07), frontmatter pur, un commit par module avec son bump patch — I5 sur les deux juges reste hors périmètre, réservée au checkpoint D-19 de 42-05.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-09-24T21:34:02Z
- **Tasks:** 2/2
- **Files modified:** 10 (5 par module)

## Accomplishments
- `vf-growth-manager.md` : `SendMessage` inséré juste avant `Agent(` dans `tools:` — le manager n'avait jusqu'ici que `AskUserQuestion`, muet en sous-agent.
- `vf-design-manager.md` : même correction — `T8` de `test-design-orchestrator.sh` (allowlist complète, `vf-dev-manager` absent, parenthèse fermée en fin de ligne) reste vert.
- `growth-bundle` bumpé v2.0.9 → v2.0.10 et `design-orchestrator` bumpé v1.5.8 → v1.5.9, chacun dans son propre commit (VERSION, module.json, README, CHANGELOG), séparé de tout commit du gate.
- `growth-quality-judge.md` et `vf-design-judge.md` (I5) confirmés intacts par sonde négative (`grep -c '^omitClaudeMd'` rend 0 sur les deux) — leur mise en conformité reste conditionnelle au checkpoint D-19 de 42-05.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Tâche 1 : growth-bundle — manager avec SendMessage (I6)** - `3d1c018` (fix)
2. **Tâche 2 : design-orchestrator — manager avec SendMessage (I6)** - `f820f08` (fix)

_Note : ces deux commits sont les seuls produits par ce plan ; le commit de métadonnées (SUMMARY + REQUIREMENTS) suit séparément, hors STATE.md/ROADMAP.md (délégués à l'orchestrateur de la vague)._

## Files Created/Modified
- `plugin/growth-bundle/agents/vf-growth-manager.md` — ajout `SendMessage` dans `tools:`, corps inchangé
- `plugin/growth-bundle/VERSION`, `module.json`, `README.md`, `CHANGELOG.md` — bump patch v2.0.10
- `plugin/design-orchestrator/agents/vf-design-manager.md` — ajout `SendMessage` dans `tools:`, corps inchangé
- `plugin/design-orchestrator/VERSION`, `module.json`, `README.md`, `CHANGELOG.md` — bump patch v1.5.9

## Decisions Made
- I5 (omitClaudeMd sur les deux juges de ce module) SORTI de ce plan — restructuration mission `revise-42b`/B1 : le verdict D-19 (`42-D19-MESURE.md`, 2026-09-24) confirme qu'`omitClaudeMd` retire aussi les règles `.claude/rules/*.md`, et D-08 est réexaminée avec Samuel sans réponse à ce jour. Sa pose vit désormais derrière le checkpoint bloquant D-19 de 42-05 (Tâche 2), qui couvre aussi les deux juges de 42-02.
- `SendMessage` reste inconditionnel en vague 1 (ne dépend d'aucun arbitrage en attente) — appliqué tel quel.
- `design-orchestrator` est de la polarité de Samuel (D-12) : le corps du commit `f820f08` nomme explicitement sa relecture attendue en PR.

## Deviations from Plan

None - plan exécuté exactement comme écrit (après la restructuration mission `revise-42b`/`revise-42c` déjà actée dans le PLAN.md lui-même avant exécution — pas une déviation en cours d'exécution).

## Issues Encountered

- **Commit via heredoc en `$(...)` cassé par un `(` non refermé dans le texte du message** (littéral `Agent(` cité dans le message de commit) — bug de parsing bash 3.2 (macOS) connu : un parenthèse non équilibrée dans un heredoc imbriqué dans une substitution de commande `$(cat <<'EOF' ... EOF)"` casse le tokenizer avant même l'exécution. Contournement : message de commit écrit dans un fichier temporaire (`scratchpad/commit_msg_task{1,2}.txt`) et `git commit -F <fichier>` à la place du heredoc inline. Aucun impact sur le contenu des commits, purement mécanique.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- Les deux derniers managers en violation I6 du corpus initial (D-11) sont désormais conformes ; combiné à 42-02 (business-pilot-bundle, content-bundle), l'invariant I6 est fermé sur l'ensemble du corpus mesuré au 2026-09-23.
- I5 (4 juges au total : `quality-gate-client`, `content-clarity-judge`, `growth-quality-judge`, `vf-design-judge`) reste entièrement en attente du checkpoint D-19 de 42-05 — aucun blocage pour ce plan, mais 42-05 ne doit pas être exécutée avant que l'arbitrage D-08/Samuel soit tranché.
- `requirements-completed` volontairement vide : FABR-05 est une exigence partagée par 42-01/02/03/05/06 (gate #2388) — elle ne deviendra `Complete` que lorsque 42-05 et 42-06 auront aussi produit leur SUMMARY.md.

---
*Phase: 42-fabrique-manifeste-dat-et-invariants-de-doctrine-du-gate-des*
*Completed: 2026-09-24*

## Self-Check: PASSED

- `[ -f plugin/growth-bundle/agents/vf-growth-manager.md ]` → FOUND
- `[ -f plugin/design-orchestrator/agents/vf-design-manager.md ]` → FOUND
- `git log --oneline --all | grep -q 3d1c018` → FOUND
- `git log --oneline --all | grep -q f820f08` → FOUND
- Acceptance criteria (Tâche 1 et Tâche 2) re-exécutés ci-dessus : tous PASS (CORPUS-GB-OK, CORPUS-DO-OK, INSTR-INCHANGE ×2, sondes anti-fusion I5 = 0, triade version alignée, diffs de portée nuls hors module)
- Plan-level `<verification>` re-exécuté : `check-agents.sh --strict` rc=0 sur les deux dossiers, `check-instruction-budget.sh` BILAN 0 dépassement code=0, `check-version-sync.sh` rc=0, deux commits confirmés (un par module, aucun ne touche le gate ni `.planning/`)
