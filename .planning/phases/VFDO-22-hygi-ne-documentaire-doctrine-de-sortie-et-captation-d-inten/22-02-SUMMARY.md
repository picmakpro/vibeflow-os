---
phase: 22-hygiene-documentaire
plan: 02
subsystem: doctrine
tags: [dev-orchestrator, design-orchestrator, team-kernel, dag, adr-029, adr-057, adr-055]

requires:
  - phase: 22-hygiene-documentaire (plan 01)
    provides: "docs-flow.md §Déclencheurs — la table canonique que les deux managers citent par renvoi"
  - phase: 15-collaboration-inter-equipes-dev-design
    provides: "mission-cross-team.md — le précédent du renvoi cross-module design → dev que ce plan réemploie"
provides:
  - "vf-dev-manager doté du nœud `docs` agrégé, des 4 déclencheurs et du régime superviser/autonome"
  - "vf-design-manager doté du MÊME geste, par renvoi cross-module, sans aucune copie locale"
  - "Bloc T23 — le câblage des deux managers est non-régressable, discriminance prouvée par mutation"
affects: [22-03 (bump des deux modules touchés), 23 (recoupement sur la doctrine des flags documentaires)]

actuals:
  tokens: 9500
  tasks: 4
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Renvoi cross-module plutôt que copie : un module cite la doctrine d'un autre, jamais ne la duplique (ADR-057)"
    - "Assertion d'absence gardée par la disposition : une assertion « ce fichier ne doit pas exister » n'a de sens qu'en dépôt source, pas en lab installé où l'arborescence est aplatie"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/agents/vf-dev-manager.md
    - plugin/design-orchestrator/agents/vf-design-manager.md
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh

key-decisions:
  - "La table des déclencheurs n'existe qu'à UN endroit (docs-flow.md) ; les managers portent les NOMS des 4 déclencheurs + le nœud + un renvoi. Trois copies auraient divergé."
  - "Les 4 déclencheurs sont testés UN PAR UN dans T23 — un grep global aurait été satisfait par un seul motif présent, c'est-à-dire par presque rien."
  - "L'assertion d'absence de copie locale est conditionnée à la disposition dépôt source, sinon elle produirait un faux vert en lab installé."

patterns-established:
  - "Un test de câblage déclare ce qu'il ne prouve PAS : T23 porte en tête la mention explicite qu'il vérifie une présence textuelle et non un comportement d'agent (précédent Phase 19, où un compte rendu de présence avait masqué un garde-fou inerte)"

requirements-completed: [DOCF-05, DOCF-06]

coverage:
  - id: D1
    description: "vf-dev-manager sait quand poser le nœud `docs` agrégé et sous quel régime"
    requirement: "DOCF-05"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T23 (volet dev)"
        status: pass
    human_judgment: false
  - id: D2
    description: "vf-design-manager porte le même geste par renvoi cross-module, sans copie locale de la doctrine"
    requirement: "DOCF-05"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T23 (volet design + absence de copie)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Le câblage des deux managers est non-régressable et le bloc de test est discriminant"
    requirement: "DOCF-06"
    verification:
      - kind: unit
        ref: "mutation: renvoi retiré de vf-design-manager.md → 1 KO sur le message T23 attendu ; restauration → 0 KO"
        status: pass
    human_judgment: false
  - id: D4
    description: "La formulation de --force correspond à l'arbitrage rendu (D-05/D-06), pas à une interdiction générale"
    verification: []
    human_judgment: true
    rationale: "La machine prouve que les trois notions tiennent sur une ligne physique ; elle ne peut pas prouver que le texte dit ce que Samuel a décidé. Validé explicitement au checkpoint bloquant le 2026-07-31 — réponse « approuvé »."

duration: 25min
completed: 2026-07-31
status: complete
---

# Phase 22 — Plan 02 Summary

**Les deux managers de mission savent désormais quand poser le geste documentaire, lequel, et sous quel régime — par renvoi vers une doctrine unique, jamais par copie.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 4 / 4 (3 automatiques + 1 checkpoint humain bloquant, approuvé)
- **Files modified:** 3

## Accomplishments

- **`vf-dev-manager`** — §Hygiène documentaire **remplacée**, pas complétée. Les trois puces
  disaient « drift doc détecté → ajoute un nœud », sans jamais dire quand, ni lequel, ni sous quel
  régime. Elle porte maintenant : le nœud `docs` agrégé (`deps` = tous les `exec-*`), les quatre
  déclencheurs nommés, le régime superviser/autonome, la ligne rouge de la régénération.
  **217 → 231 lignes**, cible du plan ≤ 235, plafond ADR-029 250.
- **`vf-design-manager`** — première dotation documentaire du module design. Une refonte complète
  périme `ARCHITECTURE` et `README` aussi sûrement qu'un refactor : même nœud, mêmes déclencheurs,
  même régime, par renvoi cross-module au format déjà employé pour `mission-cross-team.md`.
  Frontière explicite avec le gate `DESIGN.md`, qui reste inchangé et distinct. **161 → 187 lignes.**
- **Bloc T23** — le câblage devient non-régressable des deux côtés, avec `skip` explicite si le
  module design est hors du périmètre scanné, et garde D-13 sur `check-doc-drift.sh`.

## Task Commits

1. **Tâche 1 : `vf-dev-manager`** — `c99d6df` (feat)
2. **Tâche 2 : `vf-design-manager`** — `47dd3e4` (feat)
3. **Tâche 3 : bloc T23** — `a39c37d` (test)
4. **Tâche 4 : checkpoint humain bloquant** — approuvé par Samuel le 2026-07-31, pas de commit

## Files Created/Modified

- `plugin/dev-orchestrator/agents/vf-dev-manager.md` *(217 → 231 l.)* — §Hygiène documentaire remplacée
- `plugin/design-orchestrator/agents/vf-design-manager.md` *(161 → 187 l.)* — §Hygiène documentaire créée avant §Fin de mission
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — bloc T23 (+53 l.)

## Decisions Made

- **La table des déclencheurs n'existe qu'à un seul endroit.** Le CONTEXT demandait la table dans
  `vf-dev-manager` ; la poser aussi côté design en aurait fait trois copies avec `docs-flow.md`. Les
  managers portent les **noms** des quatre déclencheurs, la doctrine porte les **constats**. C'est
  le patron déjà en place pour `mission-flow.md` §Pattern E.
- **Les quatre déclencheurs sont testés un par un.** Un `grep` global sur les quatre aurait été
  satisfait par un seul motif présent — donc par presque rien.
- **L'assertion d'absence de copie locale est conditionnée à la disposition dépôt source.** En lab
  installé l'arborescence est aplatie : l'assertion inconditionnelle aurait produit un faux vert.

## Deviations from Plan

Aucune déviation de contenu — le plan a été exécuté comme écrit.

**Écart de méthode, assumé et signalé :** les trois tâches ont été exécutées **inline** par
l'orchestrateur, non par un `gsd-executor` dispatché. L'exécuteur du plan 22-01 avait consommé
163 k tokens à relire un contexte déjà présent, avant d'être coupé par l'épuisement du quota
hebdomadaire d'API. Le contrat du plan (tâches, critères d'acceptation, preuve par mutation) a été
tenu à l'identique.

## Issues Encountered

**Deux sessions ont piloté ce dépôt en parallèle.** Une session `mission-reprise-p21-p22` détenait
le **verrou de driver** (`.planning/DRIVER.lock`, `step=planification`, acquis à 18:50:36) et a
commité **sur la branche de cette phase** :

| Commit | Contenu | Relève de |
|---|---|---|
| `bc2cc48` | `wip(22)` de sauvegarde — a emporté le fichier de test de la tâche **22-01/T2** | phases 23/24 + phase 22 mêlées |
| `05fd4a0` | `docs(23,24)` — couplage au moteur GSD | phases 23/24 |
| `f1d68ba` | `wip(hors-périmètre)` — mesure M2 | hors périmètre |
| `aed56df` | `docs(25)` — budget d'instructions | phase 25 |

**Aucun fichier de cette phase n'a été réécrit** — la suite est restée verte de bout en bout
(77 OK / 0 KO). Le dommage est de **traçabilité**, pas d'intégrité : la branche
`feat/phase-22-hygiene-doc` porte quatre commits étrangers à la phase, et la tâche 22-01/T2 n'a pas
de commit atomique propre (son contenu vit dans `bc2cc48`).

**Arbitrage de Samuel (2026-07-31) : laisser et signaler.** L'historique d'une session encore active
n'est pas réécrit — elle détient le verrou et peut avoir des commits en vol. À reporter dans la
description de la PR.

**Cause racine :** le verrou de driver protège la **même étape** contre deux pilotes, mais rien ne
protège la **même branche** contre deux écrivains. Les deux sessions étaient en règle chacune de son
côté. Candidat pour un registre de dette, hors périmètre de cette phase.

## User Setup Required

Aucune.

## Next Phase Readiness

**Le plan 22-03 reste à faire** — bump **minor** des deux modules touchés (`dev-orchestrator`,
`design-orchestrator`) : `VERSION`, `module.json`, `README.md`, `CHANGELOG.md` par module, triade
cohérente. **Release racine hors périmètre**, réservée à validation humaine.

**Passation décidée par Samuel** : le plan 22-03 est laissé au manager de la session parallèle.
Ce qu'il doit savoir pour reprendre :

- les plans 22-01 et 22-02 sont **complets et vérifiés** (SUMMARY sur disque pour les deux) ;
- le **checkpoint bloquant du plan 22-02 est approuvé** — `--force` est validé dans sa formulation
  actuelle (autorisé sur intention explicite + garde-fou en trois temps). **Ne pas le rouvrir** ;
- la suite `dev-orchestrator` est à **77 OK / 0 KO** et le compteur de suites du dépôt à **44** —
  22-03 ne doit créer aucune suite nouvelle, sans quoi `check-version-sync.sh` réclamera le
  rattrapage du compteur « N suites » dans les deux README racine ;
- l'arbre porte un `VERSION` racine à `v2.44.0` **déjà taggé** (release de la Phase 20 mergée en
  PR #21) — 22-03 ne touche **aucun** des cinq fichiers de release racine.

---
*Phase: 22-hygiene-documentaire, plan 02*
*Completed: 2026-07-31*
