---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 02
subsystem: spec moteur de planning (documentation, sans code)
tags: [spec, amendements, tracabilite, P46-D-18, P46-D-19, G3, G4, G4-prime, empreintes, a-clore]

requires:
  - phase: 45-moteur-hook-central-par-role-et-gates-d-ecriture
    provides: forme d'amendement datee et attribuee (P45-D-14a), table des gates §5
provides:
  - spec moteur amendee le 2026-10-03 en quatre lieux (§3.1, §5, §5.1, §10), canal et date nommes pour chaque decision
  - restriction du perimetre de G4' aux agents qui ont Bash, ecrite comme arbitrage de Willy (P46-D-02b, Q9 = a)
  - texte pret de la note ROADMAP de la Phase 47 (46-NOTE-ROADMAP-47.md)
affects: [46-06, 46-12, 47]

plan_head_before: bd5174e1d7459179dad04a9e6979e7027321fbae
estimate:
  tokens: 45000
  raw_tokens: 45000
  tasks: 2
  confidence: low
actuals:
  tokens: 2416    # chars/4 sur les lignes ajoutees et retirees des deux commits (git diff de la base au HEAD), pas un compte du harnais
  tasks: 2
  commits: 2      # MESURE : git rev-list --count bd5174e1..HEAD au moment de l'ecriture du SUMMARY (commits de travail, hors commit du SUMMARY)

tech-stack:
  added: []
  patterns:
    - "amendement date jamais reecrit en silence : paragraphe 'Amendement du 2026-10-03 (P46-D-NN)' + ligne 'Decision (...)' avec canal et date"
    - "decision humaine (Willy, AskUserQuestion session principale, 2026-10-03, Qn) distinguee de la decision du manager (annoncee a Willy, renversable)"

key-files:
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-NOTE-ROADMAP-47.md
  modified:
    - docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md

key-decisions:
  - "Aucune decision nouvelle : le plan ecrit P46-D-01 a P46-D-05, P46-D-02b, P46-D-07, P46-D-10, P46-D-10a, P46-D-13 et P46-D-03b dans la spec, avec l'attribution du CONTEXT"
  - "P46-D-02b attribuee a Willy (Q9 = a), jamais au manager"

requirements-completed: [CLOT-12]

coverage:
  - id: D1
    description: "Spec moteur amendee en quatre lieux (§3.1 neuf etats, §5 G3/G4/G4'/D1, §5.1 contrat par evenement, §10 deux empreintes, plafond, seuil renvoye), chaque amendement date et attribue"
    requirement: "CLOT-12"
    verification:
      - kind: other
        ref: "awk /Amendement du 2026-10-03 \\(P46-D-/ -> 6 (>= 5) ; awk /AskUserQuestion session principale, 2026-10-03/ -> 7 (>= 4) ; awk P46-D-02b && Q9 = a && canal daté ; awk P46-D-10a ; bash scripts/check-machine-paths.sh -> 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Texte pret de la note ROADMAP de la Phase 47 (P46-D-19), ROADMAP.md non touchee"
    requirement: "CLOT-12"
    verification:
      - kind: other
        ref: "awk P46-D-19 && Depends on && Phase 47 sur 46-NOTE-ROADMAP-47.md -> 0 ; git log --grep=46-02 ne liste aucun ROADMAP.md -> 0"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-10-03
status: complete
---

# Phase 46 Plan 02: amendements de la spec moteur et note ROADMAP de la Phase 47 — Summary

**La spec moteur porte quatre amendements datés du 2026-10-03 (neuf états dérivés avec `à clore`, G3/G4 en PreToolUse et G4′ sur SubagentHandback dont le périmètre « agents qui ont Bash » est attribué à Willy sous P46-D-02b, contrat de sortie par événement, deux empreintes et plafond de trois tentatives), et le texte prêt de la note ROADMAP de la Phase 47 existe dans un fichier de phase.**

## Performance

- **Duration:** environ 15 min
- **Completed:** 2026-10-03T15:12Z
- **Tasks:** 2 (un traceur, une tâche auto)
- **Files modified:** 2 (1 modifié, 1 créé), plus ce SUMMARY

## Accomplishments

- §3.1 : amendement P46-D-04 (neuf états, `à clore` non terminal, à la place d'`indéterminé` pour « verdict passé sans SUMMARY.md », P44-D-08 levée sur ce point, Q4 = a) et précision P46-D-03b (`à juger` motif `verdict-perime` avant `SUMMARY.md`, `indéterminé` motif `livrable-modifie-apres-cloture` après). Le titre « Les huit états dérivés » n'est pas renommé.
- §5 : amendement P46-D-01/P46-D-02 (G3 et G4 par deny en PreToolUse sur l'écriture de `CLOTURE.md` et `SUMMARY.md`, `TaskCompleted` non utilisé, G4′ en PreToolUse(SubagentHandback) avec repli SubagentStop hors mode auto ; Q1 = a, Q2 = a), P46-D-10a en une phrase datée du manager (G4′ ouvert en mode dégradé hors mode auto), amendement P46-D-02b distinct (Willy, AskUserQuestion session principale, 2026-10-03, Q9 = a : workers et producteurs qui ont Bash ; « pas une décision du manager »), ligne D1 (P46-D-07, Q7 = b). La table d'origine n'est pas réécrite ; G2′ et sa ligne `TaskCompleted` restent écrites, renvoyées au cadrage de la Phase 47.
- §5.1 : contrat de sortie par événement (point 1) et G4′ ajouté à la liste fail-closed, D1 fail-open déclaré (point 2), décisions du manager (P46-D-10).
- §10 : deux empreintes `hash` et `hash_livrables` et plafond de trois tentatives (Q3 = a, Q5 = a) ; seuil de juge renvoyé à la Phase 50 (P46-D-13, manager). Les noms de champ correspondent à ce que 46-01 a livré dans `poser-verdict.sh`.
- `46-NOTE-ROADMAP-47.md` : cible (ligne `**Depends on:** Phase 46 (...)` citée telle que lue), texte de remplacement prêt, geste manuel du manager.

## Task Commits

1. **Tâche 1 : les quatre amendements de la spec moteur (traceur)** — `2a12dd65` (docs)
2. **Tâche 2 : texte prêt de la note ROADMAP de la Phase 47** — `e18fc853` (docs)

**Plan metadata :** commit du présent SUMMARY (docs, sans STATE ni ROADMAP, par mandat).

Tracer feedback gate : la vérification `<automated>` de la Tâche 1 a été rejouée après le commit, de bout en bout, verte (code 0) avant d'enchaîner sur la Tâche 2.

## Résultats des vérifications `<automated>`

| Vérification | Code de sortie |
|---|---|
| Tâche 1 : amendements `P46-D-` datés (6, seuil 5) | 0 |
| Tâche 1 : lignes de décision humaine avec canal et date (7, seuil 4) | 0 |
| Tâche 1 : P46-D-02b + Q9 = a + canal daté, et P46-D-10a | 0 |
| Critères d'acceptation de la Tâche 1 (P46-D-04, P46-D-10, P46-D-13, P46-D-02b sur une même ligne) | 0 |
| `bash scripts/check-machine-paths.sh` (1915 fichiers balayés) | 0 |
| Tâche 2 : P46-D-19 + Depends on + Phase 47 dans la note | 0 |
| Tâche 2 : aucun `ROADMAP.md` dans les commits `46-02` (liste non vide) | 0 |

Les commandes ont été jouées via des fichiers du scratchpad (`bash <fichier>`, premier plan). La preuve zsh n'est pas exigée par ce plan.

## Files Created/Modified

- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` — amendements §3.1, §5, §5.1 (points 1 et 2), §10 (deux), datés du 2026-10-03 ; +38 lignes, aucune ligne d'origine modifiée.
- `.planning/workstreams/gouvernance/phases/VFDO-46-moteur-gates-de-cl-ture-et-verdicts-hach-s/46-NOTE-ROADMAP-47.md` — texte prêt de la note P46-D-19.

## Decisions Made

None - followed plan as specified. Les attributions reprennent celles de `46-CONTEXT.md` : P46-D-01 à P46-D-05, P46-D-07 et P46-D-02b sont des arbitrages de Willy (Q1 à Q5, Q7, Q9), P46-D-03b, P46-D-10, P46-D-10a, P46-D-13 des décisions du manager, renversables.

## Deviations from Plan

None - plan executed exactly as written.

Deux notes qui ne sont pas des écarts :

- Le plan demande un trailer `Co-Authored-By: Claude Opus 5.5 (1M context)` ; le mandat de dispatch et l'attribution de la session imposent `Claude Sonnet 5.5 <noreply@anthropic.com>`, appliqué aux commits.
- À la lecture de la cible, la ROADMAP de la Phase 47 porte déjà (l. 289) une « Note du cadrage de la 46 (P46-D-19, 2026-10-03) » de même sens, posée avant l'exécution. La note de phase le signale et dit au manager comment ne pas dupliquer ; ROADMAP.md n'a pas été touchée.

## Issues Encountered

La garde d'isolation du worktree a refusé deux fois une commande composée (`cd ... && bash fichier ; echo rc=$?`), sans rien exécuter ; relancées en commande simple, elles ont passé. Aucun contournement.

## Known Stubs

None.

## Threat Flags

None - documentation uniquement, aucune surface nouvelle. T-46-021 (attribution sans canal ni date) : mitigé, chaque amendement nomme canal et date, vérifié par awk. T-46-022 (ROADMAP réécrite) : mitigé, aucun `ROADMAP.md` dans les commits `46-02`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 46-06 et 46-12 peuvent citer la spec amendée (restriction de G4′, limite P46-D-10a) sans contradiction.
- Le manager a le texte exact à poser dans la ROADMAP de la Phase 47 (geste manuel, planning sans release).
- Aucun blocage.

## Self-Check: PASSED

Fichiers présents (spec, note), commits `2a12dd65` et `e18fc853` présents dans l'historique.

---
*Phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s*
*Completed: 2026-10-03*
