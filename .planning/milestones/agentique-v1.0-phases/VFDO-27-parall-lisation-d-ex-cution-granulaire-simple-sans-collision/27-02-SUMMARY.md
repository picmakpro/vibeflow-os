---
phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision
plan: 02
subsystem: docs
tags: [team-kernel, dag.sh, claude_orchestration, roadmap, doctrine, adr-069]

# Dependency graph
requires: []
provides:
  - "team-kernel.md doctrine corrigée : parallélisme intra-étape 'éteint par défaut' (drapeau
    default-off restaurable), pas 'perdu' — nomme le chemin exact de restauration"
  - "Renvoi d'une ligne vers le champ stages de dag.sh ready (posé par 27-01), visible des 4
    managers non-dev qui ne lisent jamais mission-flow.md"
  - "ROADMAP.md §Phase 27 : divergence de comptage close, résultat re-dérivé avec méthode et
    limite d'ancrage hors dépôt"
affects: [vf-dev-manager, vf-design-manager, vf-business-manager, vf-content-manager, vf-growth-manager, vf-test-orchestrator]

# Actuals (#2632) — pairs with the plan's estimate to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 748
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - plugin/conductor/references/team-kernel.md
    - .planning/ROADMAP.md

key-decisions:
  - "Exécution directe (Read/Edit/Bash) plutôt que le skill gsd-execute-phase générique : la
    phase 27 dispatche 3 workers concurrents (27-01/27-02/27-03) sur la même vague 1, dans le
    même arbre de travail sans isolation worktree ; le skill générique n'a pas de filtre
    mono-plan et aurait redécouvert + tenté d'exécuter les 3 plans, écrasant le travail des deux
    autres workers. Suivi le contrat par-tâche d'execute-plan.md (task_commit_protocol,
    read_first, gates d'acceptance_criteria) — le même contrat qu'un sous-agent gsd-executor —
    en sautant délibérément les étapes de clôture génériques qui touchent des fichiers partagés
    non sérialisés entre les 3 workers (STATE.md advance-plan/update-progress, table de
    progression de ROADMAP.md, REQUIREMENTS.md mark-complete) : absentes du rapport attendu par
    le mandat, vraisemblablement agrégées par le manager une fois les 3 rapports reçus."
  - "Confirmé empiriquement (git log) que ce patron — 3 workers concurrents committant en direct
    sur la même branche, même arbre, sans isolation worktree — était déjà en usage actif par
    27-01 et 27-03 avant mon premier commit : validation croisée de l'approche."

requirements-completed: [PAEX-01, PAEX-02]

coverage:
  - id: D1
    description: "team-kernel.md l.64-73 : parallélisme intra-étape 'éteint par défaut' (pas
      perdu), nomme claude_orchestration + la condition exacte du gate n°4
      (dispatch.nested === true && dispatch.background === true, jamais backgroundDispatch),
      et ajoute le renvoi d'une ligne vers le champ stages de dag.sh ready (M6)"
    requirement: "PAEX-01"
    verification:
      - kind: other
        ref: "27-02-PLAN.md task 1 <verify> — grep gate à 6 assertions sur plugin/conductor/references/team-kernel.md"
        status: pass
      - kind: other
        ref: "non-regression: grep -c '^## ' inchangé (4=4) vs HEAD pré-édition"
        status: pass
    human_judgment: false
  - id: D2
    description: "ROADMAP.md §Phase 27 : bloc d'avertissement de comptage remplacé par le
      résultat re-dérivé (7/91, 45), méthode et limite d'ancrage hors dépôt
      (gsd-core/VERSION = 1.9.1)"
    requirement: "PAEX-02"
    verification:
      - kind: other
        ref: "27-02-PLAN.md task 2 <verify> — grep gate à 4 assertions sur .planning/ROADMAP.md"
        status: pass
      - kind: other
        ref: "non-regression: grep -c '^### Phase ' inchangé (14=14) vs HEAD pré-édition"
        status: pass
    human_judgment: false

# Metrics
duration: ~20min (approximatif — pas de record_start_time formel, voir Décisions)
completed: 2026-08-05
status: complete
---

# Phase 27 Plan 02: Doctrine corrigée — parallélisme éteint (pas perdu) + comptages re-dérivés Summary

**`team-kernel.md` ne déclare plus le parallélisme intra-étape « perdu » — il est « éteint par
défaut », restaurable via la capability `claude_orchestration` (gate n°4, jamais
`backgroundDispatch`) ; le ROADMAP porte désormais le résultat re-dérivé des deux comptages
divergents, pas l'avertissement.**

## Performance

- **Duration:** ~20 min (approximatif)
- **Started:** ~2026-08-05T23:24 (approximatif)
- **Completed:** 2026-08-05T23:42:39+02:00 (exact, commit `d708b72`)
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments
- `team-kernel.md:64-73` réécrit : la ligne de synthèse ne dit plus que le parallélisme
  intra-étape est **perdu** — elle dit **éteint par défaut**, nomme le chemin de restauration
  exact (`claude_orchestration`, gate n°4 lisant `dispatch.nested === true &&
  dispatch.background === true`, jamais `backgroundDispatch`), et ajoute un renvoi d'une ligne
  vers le champ `stages` de `dag.sh ready` (doctrine complète : `mission-flow.md`, posé par
  27-01) — sans dupliquer l'algorithme de partition.
- `.planning/ROADMAP.md` §Phase 27 : le bloc « Chiffres divergents, à ne pas recopier » est
  remplacé par le résultat re-dérivé verbatim fourni par le plan — les deux chiffres d'ADR-069
  (7/91, 45) tiennent chacun sur son critère nommé, avec la limite d'ancrage hors dépôt
  (`gsd-core/VERSION = 1.9.1`) écrite plutôt que tue (D-13).

## Task Commits

1. **Task 1: corriger la doctrine `team-kernel.md`** — contenu correct et vérifié sur la branche,
   mais atterri dans `da8ad8a` (commit de la tâche 2/4 du plan **27-03**, pas un commit propre à
   27-02 — voir « Déviations » ci-dessous pour le mécanisme et la vérification).
2. **Task 2: remplacer l'avertissement du ROADMAP par le résultat re-dérivé** — `d708b72`
   (`docs(27-02): ROADMAP — remplace l'avertissement de comptage par le résultat re-dérivé`),
   commit propre, scope exact (1 fichier, `.planning/ROADMAP.md`).

**Plan metadata:** pas de commit de métadonnées séparé (STATE.md/ROADMAP.md-tracking/
REQUIREMENTS.md volontairement non touchés — voir Décisions).

## Files Created/Modified
- `plugin/conductor/references/team-kernel.md` — doctrine de l'étage de parallélisme réellement
  effectif, l. 64-73 (était l. 64-68, +5 lignes nettes)
- `.planning/ROADMAP.md` — §Phase 27, bloc de citation (était l. 1898-1901 au moment du plan,
  retrouvé l. 1909-1912 au moment de l'exécution — drift bénin, voir Issues Encountered)

## Decisions Made
Voir `key-decisions` en frontmatter (exécution directe hors gsd-execute-phase générique, et
validation croisée du patron 3-workers-un-arbre-partagé).

## Deviations from Plan

### Déviation de processus — le commit de la Tâche 1 a été absorbé par un commit voisin concurrent

- **Found during:** clôture de la Tâche 1.
- **Issue:** j'ai d'abord fait un `git add plugin/conductor/references/team-kernel.md` isolé
  (écart par rapport à la consigne explicite du mandat — « par pathspec explicite
  (`git commit <chemins> -m ...`), jamais `git add -A` » — qui prescrivait un seul appel
  atomique) au lieu d'aller directement à `git commit <chemin> -m ...`. Dans la fenêtre
  d'exposition avant mon propre commit, le worker concurrent du plan **27-03** (dispatché en
  parallèle par le manager sur la même branche, le même arbre de travail, sans isolation
  worktree) a lui-même fait un `git add` de son propre fichier
  (`27-ISOLATION-PORTEE.md`) suivi d'un `git commit -m "..."` **sans restriction de pathspec**.
  Un `git commit` sans pathspec committe TOUT ce qui est alors indexé — y compris mon
  `team-kernel.md` déjà indexé par mon `git add` précédent.
- **Impact:** contenu correct à 100 %, en sécurité sur la branche — vérifié par
  `git show da8ad8a -- plugin/conductor/references/team-kernel.md` (diff exact, propre, aucune
  corruption) et par les deux gates `<verify>` automatisés du plan (PASS contre le HEAD actuel).
  Le seul défaut est l'attribution : mon changement de Tâche 1 est agrégé dans le commit
  `da8ad8a` (« docs(27-03): écrit la portée de l'isolation worktree… »), pas dans un commit
  propre à 27-02, et ce message ne mentionne ni `team-kernel.md` ni la correction de doctrine.
- **Fix:** aucun correctif appliqué. Réécrire `da8ad8a` a été envisagé et rejeté : le commit
  `8b37b69` (plan 27-01) est déjà empilé dessus, et les deux workers voisins committaient
  activement en direct pendant mon investigation — un rebase/amend sur une branche sous écriture
  concurrente live risquait d'orpheliner ou perdre un commit en vol d'un voisin, strictement
  pire qu'un commit mal attribué mais correct. Comportement corrigé immédiatement pour la Tâche
  2 : `git commit .planning/ROADMAP.md -m "..."` en un seul appel atomique, sans `git add`
  préalable — a atterri proprement (`d708b72`, 1 seul fichier).
- **Files modified:** `plugin/conductor/references/team-kernel.md` (contenu correct ; propriété
  du commit = `da8ad8a`, pas un commit de 27-02).
- **Verification:** `git show da8ad8a -- plugin/conductor/references/team-kernel.md` = diff exact
  attendu, rien d'autre. Les deux gates `<verify>` du plan passent contre le HEAD actuel.
- **Committed in:** `da8ad8a` (pas mon commit — voir ci-dessus).

---

**Total deviations:** 1 déviation de processus (attribution de commit, contenu non affecté).
**Impact on plan:** aucun impact fonctionnel ou de contenu ; un trou d'audit-trail/attribution à
signaler au manager comme constat structurel sur le patron « 3 workers concurrents, un seul
arbre + un seul index git partagés, aucune isolation worktree » que cette phase établit
elle-même — la discipline `git commit <pathspec> -m` (un seul appel atomique, jamais de `git add`
séparé) prescrite par mon mandat est la bonne parade et mérite un rappel explicite pour les
prochains dispatchs concurrents de ce type, plutôt que de supposer que chaque worker la déduit
seul.

## Issues Encountered
- Le bloc-cible du ROADMAP.md avait dérivé des lignes 1898-1901 annoncées par le plan vers les
  lignes 1909-1912 au moment de l'exécution — un commit antérieur légitime du même phase-planning
  (`6d60d58`, annotations vagues/dépendances) avait inséré du contenu plus haut dans le fichier
  avant le début de l'exécution. Conformément à la précondition de la Tâche 2, j'ai vérifié que le
  CONTENU du bloc restait verbatim identique avant de traiter ce drift comme bénin (confirmé via
  `git log` : le commit décalant prédate tous les commits de la phase d'exécution) et j'ai
  poursuivi. Aucune ambiguïté de contenu rencontrée.

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- Les deux `must_haves.truths` de ce plan sont satisfaits sur disque (vérifié par les gates du
  plan contre le HEAD courant).
- La vague 1 (27-01, 27-02, 27-03) avait encore 27-01 et 27-03 en cours au moment de l'écriture de
  ce SUMMARY (confirmé en direct via `git log` pendant l'exécution) — la vague 2 (27-04) dépend
  des trois.
- Signal pour le manager : le risque d'attribution de commit documenté ci-dessus est une
  propriété vivante du patron de dispatch actuel (3 workers `vf-coder` concurrents, un seul arbre
  de travail partagé, aucune isolation worktree) — mérite un rappel explicite (toujours
  `git commit <pathspec> -m`, jamais de `git add` isolé) plutôt que de supposer que chaque worker
  l'infère seul.

---
*Phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision*
*Completed: 2026-08-05*
