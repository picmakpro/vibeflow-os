---
phase: VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision
plan: 06
subsystem: planning
tags: [mesure, ab-testing, claude-orchestration, dispatch, non-mesurabilite]

# Dependency graph
requires:
  - phase: VFDO-27 (plan 27-04)
    provides: "structure du bloc 3 de 27-MESURE-GAIN.md, corpus étalon 27-mesure/waves-toy.json, baseline inline (blocs 1-2)"
  - phase: VFDO-27 (plan 27-05)
    provides: "verdict écrit de la capability claude_orchestration (27-DECISION-claude-orchestration.md) — REFUS MOTIVÉ"
provides:
  - "Bloc 3 de 27-MESURE-GAIN.md clos dans son issue de non-mesurabilité, motif et déclencheur de reprise recopiés fidèlement"
  - "Protocole d'A/B conservé inchangé pour la reprise, une fois le déclencheur satisfait"
affects: [claude_orchestration, mesure-du-gain, capacites-dormantes]

# Actuals (#2632)
actuals:
  tokens: 1600
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Marqueur de statut machine-lisible binaire (STATUT-BLOC-3) sur sa propre ligne pour empêcher un document de mesure de rester à demi rempli"
    - "Motif et déclencheur de reprise recopiés verbatim (blockquote) depuis le document de décision source, jamais paraphrasés"

key-files:
  created: []
  modified:
    - ".planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-MESURE-GAIN.md"

key-decisions:
  - "Bloc 3 fermé en NON-MESURABLE — le plan 27-05 a rendu un refus motivé (critère FAIL n°2, artefacts différents + worktrees non nettoyés), donc aucun A/B n'a eu lieu conformément à la branche refus du how-to-verify de la Tâche 1"
  - "Motif et déclencheur objectif de reprise recopiés à l'identique (blockquote) depuis 27-DECISION-claude-orchestration.md §6, jamais paraphrasés de mémoire"
  - "Protocole d'A/B (manifeste unique, run-id fixe, ≥2 répétitions, garde-fou de verdict backend par répétition B3) conservé tel quel dans le bloc, pour être rejoué sans réécriture le jour où le déclencheur sera satisfait"
  - "Les deux garde-fous d'énoncé (plafond 3,00x jamais un gain d'horloge D-10 ; estimation 1,8-2,5x étiquetée estimée D-13) reconduits explicitement puisque l'A/B n'a rien remplacé"

patterns-established:
  - "Sortie honnête d'un livrable de mesure sur refus amont : statut binaire + motif recopié + déclencheur factuel, patron des capacités dormantes de la Phase 24 (GSDA-06/08/10)"

requirements-completed: [PAEX-10]

coverage:
  - id: D1
    description: "Bloc 3 de 27-MESURE-GAIN.md rempli avec le marqueur STATUT-BLOC-3: NON-MESURABLE, motif et déclencheur de reprise recopiés depuis 27-DECISION-claude-orchestration.md, protocole et garde-fous D-10/D-13 reconduits"
    requirement: "PAEX-10"
    verification:
      - kind: other
        ref: "grep -qE '^STATUT-BLOC-3: (MESURE|NON-MESURABLE)$' 27-MESURE-GAIN.md && grep -q \"pas un gain d.horloge\" 27-MESURE-GAIN.md && grep -qi 'estim' 27-MESURE-GAIN.md && grep -qF 'waves-toy.json' 27-MESURE-GAIN.md && grep -qF '27-DECISION-claude-orchestration' 27-MESURE-GAIN.md"
        status: pass
      - kind: other
        ref: "git diff --stat HEAD~1 HEAD -- .planning/phases/VFDO-27-.../27-MESURE-GAIN.md — un seul fichier modifié, blocs 1-2 byte-identiques (diff n'ajoute qu'après le titre du bloc 3)"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-08-06
status: complete
---

# Phase VFDO-27 Plan 06: Clôture de la mesure du gain — non-mesurabilité motivée Summary

**Bloc 3 de `27-MESURE-GAIN.md` clos en `NON-MESURABLE` : le plan `27-05` a refusé l'activation de `claude_orchestration` (critère FAIL n°2), donc l'A/B n'a jamais eu lieu — motif et déclencheur de reprise recopiés verbatim depuis la décision, protocole conservé intact pour la reprise.**

## Performance

- **Duration:** ~12 min (Tâche 2 seule — la Tâche 1, checkpoint de session, a été conduite par l'orchestrateur en amont de ce mandat)
- **Started:** 2026-08-06T12:22:00Z (reprise post-checkpoint)
- **Completed:** 2026-08-06T12:34:24Z
- **Tasks:** 1/1 exécutée par cet exécuteur (Tâche 2 ; Tâche 1 déjà close par l'orchestrateur — voir `<checkpoint_result>`)
- **Files modified:** 1

## Accomplishments
- Bloc 3 de `27-MESURE-GAIN.md` ouvert par le marqueur machine-lisible `STATUT-BLOC-3: NON-MESURABLE`, seul sur sa ligne
- Motif du refus recopié verbatim depuis `27-DECISION-claude-orchestration.md` §6 (critère FAIL n°2 : artefacts différents — aucun commit de worker, aucun `SUMMARY.md`, aucun merge — et worktrees non nettoyés, malgré une échelle de 7 gates intégralement franchie sans drapeau manuel)
- Déclencheur objectif de reprise recopié verbatim (les deux faits à établir par un nouveau run réel : brief embarquant le protocole GSD complet, mécanisme de merge/nettoyage côté orchestrateur pour les worktrees changés)
- Protocole d'A/B (manifeste unique `27-mesure/waves-toy.json`, run-id fixe, ≥2 répétitions par côté, garde-fou du verdict `backend` relevé avant chacune des deux répétitions côté workflow — correction de revue B3) conservé tel quel, pour être rejoué sans réécriture le jour où le déclencheur sera satisfait
- Les deux garde-fous d'énoncé (D-10 : plafond 3,00x jamais un gain d'horloge — déjà vrai dans le Bloc 1, reconduit explicitement dans le Bloc 3 ; D-13 : estimation 1,8-2,5x reste étiquetée estimée, jamais mesurée) réaffirmés dans le bloc, puisque l'A/B n'a rien remplacé
- État de la capability à la clôture consigné : `claude_orchestration.enabled` reste `false`, ce plan ne touche pas cette clé

## Task Commits

Chaque tâche a été commitée atomiquement. La Tâche 1 (checkpoint de session) n'a produit aucun commit — c'est un checkpoint d'observation conduit au niveau de la session, pas une écriture de fichier (voir `<files>(aucun — checkpoint de session...)` dans `27-06-PLAN.md`).

1. **Tâche 2 : Écrire le bloc 3 — l'écart et ses limites, ou la non-mesurabilité et son déclencheur** - `b33f6c2` (docs)

**Plan metadata:** commit final à suivre (voir `<final_commit>`)

## Files Created/Modified
- `.planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-MESURE-GAIN.md` - Bloc 3 rempli en `NON-MESURABLE` ; blocs 1-2 inchangés (diff ne montre d'ajout qu'après le titre du bloc 3)

## Decisions Made

- **Issue légitime choisie : `NON-MESURABLE`, pas `MESURE`.** Conforme au verdict de `27-DECISION-claude-orchestration.md` (REFUS MOTIVÉ) et à la branche « refus » explicite du `how-to-verify` de la Tâche 1 — aucune interprétation, le document de décision tranche sans ambiguïté.
- **Motif et déclencheur recopiés en blockquote, pas paraphrasés.** Choix délibéré pour respecter à la fois l'instruction explicite du contexte de mission (« recopie-le fidèlement depuis le document, ne le paraphrase pas de mémoire ») et le garde-fou D-13 (tout chiffre/affirmation gravé se re-dérive sans accès à la session).
- **Protocole d'A/B conservé dans le bloc plutôt que supprimé.** Le patron des capacités dormantes (GSDA-06/08/10, Phase 24) est un différé nommé, pas un abandon — le protocole reste la référence opérationnelle exacte pour la reprise, y compris le garde-fou de verdict `backend` par répétition ajouté en revue (B3), qui n'existait pas encore quand le protocole a été posé par `27-04`.

## Deviations from Plan

None - plan exécuté exactement comme écrit. La Tâche 1 (checkpoint bloquant) avait déjà été conduite par l'orchestrateur avant le mandat de cet exécuteur, conformément à l'objectif de mission qui délègue explicitement ce geste à la session principale (un exécuteur de plan est un sous-agent, il ne peut pas mener l'A/B lui-même — voir `27-06-PLAN.md` §"Ce que la mesure peut établir, et ce qu'elle ne peut pas").

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Le bloc 3 de `27-MESURE-GAIN.md` est clos dans une issue légitime et complète — plus rien n'attend d'être rempli dans ce document. La capability `claude_orchestration` reste `false` (verdict `27-05`, non modifié par ce plan). Le déclencheur objectif de reprise est écrit et consultable à deux endroits cohérents (`27-DECISION-claude-orchestration.md` §6 et `27-MESURE-GAIN.md` Bloc 3) : rouvrir la mesure suppose qu'un futur spike établisse, sous un run réel, (1) un brief embarquant le protocole d'exécution GSD complet et (2) un mécanisme de merge/nettoyage côté orchestrateur pour les worktrees changés de l'outil Workflow. Aucun blocage pour la clôture de la Phase 27 — c'est au manager de mission de statuer si ce différé nommé suffit à clore le livrable 5 du ROADMAP ou s'il doit être tracé ailleurs (STATE.md, hors périmètre de ce plan).

---
*Phase: VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision*
*Completed: 2026-08-06*
