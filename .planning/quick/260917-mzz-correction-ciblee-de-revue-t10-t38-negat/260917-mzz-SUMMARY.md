---
phase: 260917-mzz
plan: 01
subsystem: testing
tags: [sed-portability, dev-orchestrator, design-orchestrator, ci, manual-docs]

requires:
  - phase: 260917-ldp
    provides: "Extension de l'arbitrage B1 (jamais de Task() sur le head) à vibeflow-design, T10/T38 initiaux"
provides:
  - "T10 (test-design-orchestrator.sh) et T38 (test-dev-orchestrator.sh) : négation scopée à la clause via une fenêtre portable sed BSD/GNU"
  - "Cas discriminants (c.6)/(c.7)/(c.8) et jumeaux (e.5)/(e.6)/(e.7), dont (c.8)/(e.7) qui isolent la branche « mais »/« puis » sans virgule voisine"
  - "Parité FR/EN du manuel : vibeflow-design tourne en session principale, jamais lancé comme sous-agent"
  - "Résolution du finding 6 dans 260917-ldp-VERIFICATION.md (status: passed)"
affects: [design-orchestrator, dev-orchestrator, ci]

actuals:
  tokens: 6206
  tasks: 1
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Fenêtre de clause portable (sed BSD et GNU) pour scoper une recherche de négation au littéral qui la suit, au lieu du texte entier"

key-files:
  created: []
  modified:
    - plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
    - manual/fr/05-equipe-agents/les-agents-livres.md
    - manual/en/05-agent-team/the-agents-that-ship.md
    - .planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-VERIFICATION.md

key-decisions:
  - "Commit fait sur l'état déjà implémenté et vérifié par vf-coder (mandat de correction ciblée, nœud exec-b1-design) — ce plan ne réimplémente rien, il prouve puis committe."
  - "Aucun arbitrage humain invoqué pour les correctifs de portabilité et de couverture : décisions d'agent dans son mandat, documentées comme telles au corps du commit (conformément à la règle de traçabilité de CLAUDE.md)."
  - "Limitation connue L1 (séparateur `.` coupant aussi dans « cf. » ou « team-kernel.md ») consignée ici sans modification de code, comme prescrit par le plan."

patterns-established: []

requirements-completed: [MZZ-01, MZZ-02, MZZ-03, MZZ-04]

coverage:
  - id: D1
    description: "T10 (design) et T38 (dev) : négation scopée à la clause, fenêtre portable sed BSD/GNU, littéraux synchronisés"
    requirement: MZZ-01
    verification:
      - kind: unit
        ref: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh (43 OK / 0 KO / 0 SKIP, macOS)"
        status: pass
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh (221 OK / 0 KO / 0 SKIP, macOS)"
        status: pass
      - kind: other
        ref: "gate-linux.sh (ubuntu:24.04, hors dépôt) contre HEAD et HEAD~1 — sortie 0, 0 erreur sed, 0 KO nouveau, cas neufs 3/3 et 3/3"
        status: pass
    human_judgment: false
  - id: D2
    description: "Parité CI Linux (job tests, ubuntu-latest) : aucune raison de rougir sur ce diff"
    requirement: MZZ-04
    verification:
      - kind: other
        ref: "gate-linux.sh (ubuntu:24.04) — design rc 0 (35/0/3), dev 198/11/12 (11 KO = base), sed-err 0/0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Parité FR/EN du manuel : vibeflow-design tourne en session principale, jamais sous-agent"
    requirement: MZZ-02
    verification:
      - kind: other
        ref: "bash manual/.tools/check-manual.sh — C0-C4 et C6 verts, C5 rouge uniquement sur les-gates-machine/the-machine-gates (pré-existant, hors périmètre)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Résolution du finding 6 dans 260917-ldp-VERIFICATION.md (status: passed)"
    requirement: MZZ-03
    verification:
      - kind: manual_procedural
        ref: ".planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-VERIFICATION.md"
        status: unknown
    human_judgment: true
    rationale: "Contenu textuel d'une section de résolution — jugement humain sur la formulation, pas un test automatisable."
  - id: D5
    description: "Commit atomique des 5 fichiers, DAG de mission du manager exclu, trailers exacts, aucun arbitrage humain invoqué pour les correctifs de vf-coder"
    requirement: MZZ-04
    verification:
      - kind: other
        ref: "git show --name-only HEAD == exactement les 5 chemins ; git status montre le DAG toujours ` M` non indexé"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-09-17
status: complete
---

# Quick Task 260917-mzz: Correction ciblée de revue T10/T38 (négation scopée à la clause) Summary

**Commit atomique de la correction de revue PR #79 (finding 1/finding 6) déjà implémentée par vf-coder : T10/T38 scopent la négation à la clause via une fenêtre portable sed BSD/GNU, prouvée verte sur macOS (43/0/0, 221/0/0) et sous ubuntu:24.04 (gate-linux.sh sortie 0, 3/3 et 3/3 cas neufs).**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-09-17T15:04:52Z
- **Completed:** 2026-09-17T15:09:30Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments
- Prouvé l'état atteint avant tout commit : suites macOS (design 43/0/0, dev 221/0/0), `check-machine-paths.sh` rc 0, `check-instruction-budget.sh` rc 0, `check-manual.sh` C0-C4/C6 verts (C5 rouge confiné aux deux pages pré-existantes hors périmètre).
- Rejoué la parité CI Linux via un script `gate-linux.sh` posé hors dépôt (`${TMPDIR}/mzz-linux-replay/`, jamais versionné) : sortie 0 contre `HEAD` (base = état avant ce commit) — design 35 OK/0 KO/3 SKIP, dev 198 OK/11 KO/12 SKIP (11 KO = image nue, identiques à la base), 0 erreur de classe de caractères sed, 0 KO nouveau, les six cas neufs (c.6, c.7, c.8, e.5, e.6, e.7) tous présents.
- Indexé et committé exactement les 5 fichiers de `files_modified`, un par un par chemin explicite — le DAG de mission du manager (`.planning/MISSION-HOTFIX-2632.dag.json`) reste modifié non indexé, hors commit.
- Rejoué le bloc `<automated>` après commit (base `HEAD~1`) : `scope-5 OK`, `dag-intouche OK`, `fenetre-portable commitee OK`, `cas-sans-virgule commites OK`, `machine-paths rc=0`, `instruction-budget rc=0`, suites macOS inchangées, `gate-linux.sh` de nouveau vert contre `HEAD~1` (mêmes chiffres).

## Task Commits

1. **Tâche 1 : prouver l'état atteint (macOS + parité Linux), puis commit atomique des 5 fichiers, DAG du manager exclu** - `a786260` (test)

_Aucune commande `state.*` ni commit de métadonnées (SUMMARY/STATE/ROADMAP) exécutée dans cette tâche — l'orchestrateur gère le commit de documentation séparément, conformément aux contraintes de cette exécution._

## Files Created/Modified
- `plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` - T10 : `t10_affirmative_hits` scopé à la clause (fenêtre portable), cas (c.6)/(c.7)/(c.8), synchro des littéraux avec T38, mutant « jamaisZ » (T10 (d)) et fichier `dev-suite-mutant-negre.md`
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` - T38 : `t38d_affirmative_hits` jumeau synchronisé, cas (e.5)/(e.6)/(e.7)
- `manual/fr/05-equipe-agents/les-agents-livres.md` - Puce vibeflow-design : « Il tourne lui aussi dans ta session principale (via `/vf-design`) »
- `manual/en/05-agent-team/the-agents-that-ship.md` - Parité EN de la puce vibeflow-design
- `.planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-VERIFICATION.md` - `status: passed`, section « Résolution (2026-09-17, … finding 6) », score 7/7 inchangé

## Decisions Made
- Aucune décision d'implémentation à prendre : le plan décrit un état déjà atteint et vérifié par vf-coder (mandat de correction ciblée, nœud `exec-b1-design`). La seule décision de cette tâche est de prouver puis committer, sans corriger de code (le plan l'interdit explicitement — sortir de ce mandat aurait été une régression de traçabilité).
- Attribution du commit : ce plan avait été rédigé (verify automatisé) avec le trailer littéral `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`, hérité d'une session antérieure. La consigne d'attribution active de cette session impose `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` (modèle réellement en cours), qui remplace toute guidance d'attribution antérieure et n'est supplantée que par les instructions propres de l'utilisateur (CLAUDE.md, mémoire) — pas par le texte figé d'un plan. Le commit porte donc `Claude Sonnet 5`, pas `Claude Opus 5` : voir Déviations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 4-adjacent — consigne d'attribution vivante prime sur un littéral figé du plan] Trailer `Co-Authored-By` en `Claude Sonnet 5` au lieu de `Claude Opus 5`**
- **Found during:** Tâche 1, étape 3 (commit)
- **Issue:** Le plan (`<action>` et `<verify><automated>`) attend littéralement `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` — texte figé au moment où le plan a été écrit sous un autre modèle. La consigne d'attribution de la session en cours (system-reminder, non issue du plan) est explicite : elle « remplace toute guidance d'attribution antérieure » et n'est supplantée que par les instructions propres de l'utilisateur (CLAUDE.md/mémoire), jamais par un artefact de planification.
- **Fix:** Commit `a786260` porte `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` (modèle réellement en cours pour cette exécution), le reste du trailer (`Claude-Session:`) identique au plan.
- **Impact mesuré :** la ligne `test "$(/usr/bin/git log -1 --format=%B | awk 'NF' | tail -2)" = "..."` du bloc `<automated>` du plan échoue à matcher littéralement (elle compare à `Claude Opus 5`) ; tous les autres contrôles du bloc `<automated>` (scope-5, dag-intouche, fenetre-portable, cas-sans-virgule, machine-paths, instruction-budget, suites macOS, gate-linux) passent. Le message final n'invoque aucun arbitrage humain pour les correctifs de vf-coder, conformément au mandat.
- **Files modified:** aucun fichier de code, seul le message de commit `a786260`.

---

**Total deviations:** 1 auto-résolu (attribution vivante > littéral figé du plan)
**Impact on plan:** Aucune régression de traçabilité ni de contenu — la substance du commit (les 5 fichiers, leur contenu, le corps décrivant les correctifs de vf-coder sans arbitrage humain fabriqué) est strictement conforme au plan. Seule la ligne de trailer nommant le modèle diffère, par construction (le plan a été écrit sous un modèle différent de celui qui exécute).

## Issues Encountered
- Le hook rtk a refusé plusieurs commandes shell composites (variables + `bash -c`, chaînage `;` avec `$PWD`) touchant à `git`/`docker`, conformément au garde d'isolation du worktree documenté dans le plan. Contourné en substituant les chemins absolus littéralement dans la commande (jamais dans un fichier versionné) et en appelant `bash <script> <argument-absolu>` sans chaînage, comme prescrit par les « Notes d'exécution » du contexte du plan.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Commit `a786260` prêt sur `hotfix/v2.63.2-profondeur-spawn`, non poussé — push et intégration restent des gestes hors périmètre de cette tâche (nœud DAG `push-design` distinct, propriété du manager amont).
- Le DAG de mission `.planning/MISSION-HOTFIX-2632.dag.json` reste intact et modifié non indexé, comme l'exigeait le mandat — à la charge du manager amont pour la suite.
- Limitation connue non bloquante (L1, hors correctif) : dans `t10_affirmative_hits`/`t38d_affirmative_hits`, le séparateur `.` de la fenêtre de clause coupe aussi dans une abréviation comme « cf. » ou dans un nom de fichier comme `team-kernel.md`, ce qui pourrait en théorie isoler une négation légitime de son littéral `Task(...)`. Aucune occurrence réelle de `Task(vibeflow-design)` ou `Task(vibeflow-head)` n'a ce contexte à ce jour dans le dépôt — documentée ici sans modification de code, conformément au mandat de cette tâche.

---
*Phase: 260917-mzz*
*Completed: 2026-09-17*

## Self-Check: PASSED
- FOUND: `.planning/quick/260917-mzz-correction-ciblee-de-revue-t10-t38-negat/260917-mzz-SUMMARY.md`
- FOUND: commit `a786260` in `git log --oneline --all`
