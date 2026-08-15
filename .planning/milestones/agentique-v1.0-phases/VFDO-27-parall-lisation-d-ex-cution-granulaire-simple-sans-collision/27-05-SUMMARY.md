---
phase: VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision
plan: 05

subsystem: infra
tags: [claude-agent-sdk, workflow-tool, dispatch-backend, worktree, gsd-core]

requires:
  - phase: VFDO-27 plan 03
    provides: ".worktreeinclude, 27-ISOLATION-PORTEE.md (hypotheses A1/A2/A4/A5 ouvertes)"
  - phase: VFDO-27 plan 04
    provides: "27-mesure/waves-toy.json (corpus etalon parallelisable) et baseline inline"
provides:
  - "Verdict ecrit et opposable sur claude_orchestration : refus motive, deja consigne"
  - "GSD_AGENT_SDK_VERSION etablie depuis une installation reelle (0.3.223), avec sa limite ecrite"
  - "Persistance operante au niveau machine (~/.claude, option 3) pour resoudre le SDK sans drapeau"
  - "Premieres observations reelles des hypotheses A1/A2/A4/A5 de l'isolation par worktree"
  - "Declencheur objectif de reprise de la capability"
affects: [gestion-du-backend-de-dispatch, futurs-spikes-outil-workflow, mission-de-cloture-phase-27]

actuals:
  tokens: 5311
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Spike a verdict oppose : criteres PASS/FAIL figes avant observation, disjonction pour FAIL"
    - "Persistance de version SDK sur la chaine de resolution __dirname (~/.claude), pas un drapeau ni une valeur figee"

key-files:
  created:
    - .planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-DECISION-claude-orchestration.md
  modified:
    - .planning/config.json

key-decisions:
  - "Refus motive de claude_orchestration : le run reel diverge du chemin inline (critere FAIL n2) — aucun commit de worker, aucun SUMMARY, aucun merge, worktrees non nettoyes"
  - "Persistance de GSD_AGENT_SDK_VERSION tranchee par Samuel : option 3 (installation reelle dans ~/.claude), acquise et non desinstallee malgre le refus"
  - "Le refus est localise (brief jouet incomplet + absence de merge/nettoyage cote orchestrateur), pas une disqualification de l'outil Workflow lui-meme"

patterns-established:
  - "Document de decision de spike sur la convention 24-COLLISIONS.md : bandeau de statut, table de verdicts, sections narratives, declencheur objectif de reprise"

requirements-completed: [PAEX-08, PAEX-09]

coverage:
  - id: D1
    description: "GSD_AGENT_SDK_VERSION etablie par installation reelle (0.3.223), version lue dans le package.json d'un paquet reellement installe"
    requirement: "PAEX-08"
    verification:
      - kind: manual_procedural
        ref: "npm --prefix <jetable> install @anthropic-ai/claude-agent-sdk puis lecture de la cle version"
        status: pass
    human_judgment: false
  - id: D2
    description: "Echelle des 7 gates franchie sans drapeau manuel grace a la persistance option 3, verdict brut consigne"
    requirement: "PAEX-08"
    verification:
      - kind: manual_procedural
        ref: "resolve-wave-dispatch --waves 27-mesure/waves-toy.json --run-id spike-27 (sans --agent-sdk-version)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Run Workflow reel sur corpus etalon : isolation sans collision, mais divergence du chemin inline (pas de commit, pas de SUMMARY, pas de merge, worktrees non nettoyes)"
    requirement: "PAEX-09"
    verification:
      - kind: manual_procedural
        ref: "run wf_fea42b76-3e2, releve au checkpoint tache 2, transcrit dans 27-DECISION-claude-orchestration.md §4"
        status: fail
    human_judgment: true
    rationale: "Le statut fail porte sur le critere FAIL n2 du plan (divergence artefacts), verifie et transcrit — juge humain requis uniquement pour confirmer la lecture du critere, pas pour re-executer le run"
  - id: D4
    description: "Sous-experience Decision A : absence d'entree utilisateur ne produit pas de silence dangereux (issue n3)"
    requirement: "PAEX-09"
    verification:
      - kind: manual_procedural
        ref: "run wf_5ad43149-45e, releve au checkpoint tache 2, transcrit dans 27-DECISION-claude-orchestration.md §4"
        status: pass
    human_judgment: false
  - id: D5
    description: "Document de decision ecrit avec verdict, motif et declencheur objectif de reprise ; .planning/config.json regle sur enabled: false, coherent avec le refus"
    verification:
      - kind: other
        ref: "verification automatisee tache 3 (grep + python3 json.load), executee dans cette session"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-08-06
status: complete
---

# Phase VFDO-27 Plan 05: Spike claude_orchestration Summary

**Refus motivé de `claude_orchestration` : l'échelle des 7 gates est franchie sans drapeau
manuel (persistance réelle du SDK dans `~/.claude`), mais le run Workflow réel diverge du
chemin inline — aucun commit de worker, aucun merge, worktrees résiduels — donc `enabled`
repasse à `false`, avec un déclencheur objectif de reprise.**

## Performance

- **Duration:** 9 min (commits `bb83a94` → `0483ad1`)
- **Started:** 2026-08-06T12:20:01Z
- **Completed:** 2026-08-06T12:28:47Z
- **Tasks:** 3 (tâche 1 auto, tâche 2 checkpoint humain conduit en session principale, tâche 3 auto)
- **Files modified:** 2 (`.planning/config.json`, `27-DECISION-claude-orchestration.md`)

## Accomplissements

- `GSD_AGENT_SDK_VERSION` établie par installation réelle (`0.3.223`), jamais déduite du
  binaire `claude` — la recherche du plan a établi que les deux schémas de version sont
  indépendants.
- Décision de persistance de cette version au runtime tranchée par Samuel au checkpoint :
  option 3 (installation réelle et persistante dans `~/.claude`, sur la chaîne de résolution
  `__dirname` que `resolve-wave-dispatch` emprunte réellement en production). Prouvée
  opérante : `resolve-wave-dispatch` résout `workflow` sans aucun drapeau manuel.
- Run Workflow réel conduit sur le corpus étalon `27-mesure/waves-toy.json` : isolation sans
  collision, 32 s, 0 erreur, sans intervention humaine — mais diverge du chemin inline au
  sens exact du critère FAIL n°2 du plan (aucun commit de worker, aucun `SUMMARY.md`, aucun
  merge vers l'arbre principal, worktrees non nettoyés).
- Sous-expérience Décision A confirmée sûre : absence d'entrée utilisateur en cours de run
  ne produit pas de silence dangereux (issue n°3 — question remontée en rapport, 0 écriture).
- Repli fail-closed re-testé après manipulation de la config : retour identique, à l'octet
  près, au comportement d'aujourd'hui.
- Quatre sondes d'hypothèse de l'isolation par worktree observées pour la première fois sous
  run réel (A1 présent, A2 hors namespace attendu, A4 vide, A5 échec de lecture — causes
  établies, pas seulement constatées).
- `27-DECISION-claude-orchestration.md` écrit sur la convention `24-COLLISIONS.md` : critères
  PASS/FAIL recopiés, provenance du SDK, décision de persistance, verdict de l'échelle,
  observations transcrites, sondes, verdict final et déclencheur objectif de reprise.
- `.planning/config.json` réglé sur le verdict : `claude_orchestration.enabled: false`,
  jamais un état à demi activé.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Tâche 1 : Établir honnêtement la version du SDK et franchir l'échelle de gates** —
   `bb83a94` (feat) — session précédente
2. **Tâche 2 : Checkpoint humain — run Workflow réel et sous-expérience Décision A** — conduite
   en session principale (l'outil Workflow n'est pas porté par un sous-agent), aucun commit de
   tâche propre — observations rendues à l'exécuteur pour transcription par la tâche 3
3. **Tâche 3 : Écrire la décision, régler la configuration** — `0483ad1` (fix)

**Plan metadata:** commit final de clôture ci-dessous (docs).

## Files Created/Modified

- `.planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-DECISION-claude-orchestration.md` —
  document de décision : critères figés, provenance SDK, décision de persistance, verdict de
  l'échelle, quatre observations transcrites, quatre sondes, verdict et déclencheur de reprise.
- `.planning/config.json` — bloc `claude_orchestration.enabled` repassé à `false`
  (`execution_backend` inchangé à `"auto"`).

## Decisions Made

- **Refus motivé de `claude_orchestration`** : deux des trois conditions PASS sont satisfaites
  (échelle franchie sans drapeau, Décision A sûre), mais le critère FAIL n°2 est constitué —
  disjonction, une seule condition suffit. Le run réel produit des artefacts qui divergent du
  chemin inline (pas de commit de worker, pas de merge, worktrees non nettoyés) : ce n'est pas
  une défaillance de l'échelle de gates ni de l'isolation, c'est un défaut structurel localisé
  (brief jouet sans protocole `execute-plan.md` complet + absence de mécanisme de merge/
  nettoyage côté orchestrateur pour les worktrees changés).
- **La persistance de `GSD_AGENT_SDK_VERSION` (option 3, `~/.claude`) reste acquise** malgré le
  refus de la capability : elle n'est pas liée au verdict et n'est pas désinstallée. Elle a
  d'ailleurs prouvé sa valeur — c'est elle qui a permis d'observer le vrai chemin de production
  (`workflow` résolu sans drapeau) au lieu de rester bloqué en amont sur `agent_sdk_version_unknown`.
- **Déclencheur objectif de reprise consigné**, sur le patron des capacités dormantes refusées
  en Phase 24 (GSDA-06, GSDA-08, GSDA-10) : rouvrir ssi (1) le brief émis embarque le protocole
  d'exécution GSD complet (commit + `SUMMARY.md`) et (2) un mécanisme de merge/nettoyage
  existe côté orchestrateur pour les worktrees changés — les deux à établir sous un nouveau run
  réel, pas supposés.

## Deviations from Plan

None - plan exécuté exactement comme écrit. Les critères PASS/FAIL ont été appliqués
mécaniquement, sans renégociation, comme demandé par les instructions de reprise.

## Issues Encountered

None au-delà de ce que le run réel a lui-même révélé (et qui constitue le contenu du verdict,
pas un problème d'exécution de ce plan). Le run réel de la tâche 2 a mis au jour une lacune
structurelle du couplage brief-jouet + outil Workflow (absence de protocole d'exécution complet
et de mécanisme de merge/nettoyage) — documentée en détail dans
`27-DECISION-claude-orchestration.md` §4 et §6, avec son déclencheur de reprise.

## User Setup Required

None - aucune configuration de service externe requise. La persistance machine
(`~/.claude/node_modules/@anthropic-ai/claude-agent-sdk`) a été posée pendant le checkpoint de
la tâche 2, directement par Samuel et l'orchestrateur de session, et est documentée dans
`27-DECISION-claude-orchestration.md` §2bis.

## Next Phase Readiness

- `claude_orchestration` reste désactivée (`enabled: false`) — le backend de dispatch de
  toute exécution future du lab retombe sur `inline`, identique au comportement d'aujourd'hui.
- La persistance `GSD_AGENT_SDK_VERSION` (option 3) reste opérante au niveau machine pour tout
  futur spike ou reprise de la capability — pas besoin de la rejouer.
- Le déclencheur objectif de reprise et les deux faits à établir sont écrits dans
  `27-DECISION-claude-orchestration.md` §6 — condition à vérifier avant toute réouverture
  future, pas une date.
- Cette exécution ne touche ni `27-MESURE-GAIN.md`, ni `27-ISOLATION-PORTEE.md`, ni
  `.planning/STATE.md`, ni `.planning/ROADMAP.md`, par contrainte explicite de périmètre du
  plan — leur mise à jour appartient au manager de mission à la clôture de la phase.

---
*Phase: VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision*
*Completed: 2026-08-06*
