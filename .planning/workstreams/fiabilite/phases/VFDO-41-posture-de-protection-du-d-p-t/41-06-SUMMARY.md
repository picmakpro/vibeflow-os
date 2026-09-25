---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 06
subsystem: infra
tags: [github-rulesets, branch-protection, codeowners, ci, gh-api, gh-pr]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t (41-05)
    provides: deux rulesets GitHub actifs (branche main, tags v*), critère de succès 1 atteint
provides:
  - trois PR de preuve jetables ouvertes et lues côté serveur (PR-P/#101, PR-BASELINE/#102, PR-SENTINELLE/#103)
  - CO-VERDICT ECART mesuré et consigné (mergeStateStatus=CLEAN, reviewDecision vide sur les trois PR, contre BLOCKED/REVIEW_REQUIRED attendus)
  - CO-DECISION accepter-et-documenter (Willy, AskUserQuestion session principale, 2026-09-24)
  - entrée WINDOWS.md #9 (écart tracé au ledger)
affects: [41-07, 41-08, 41-09, 41-10, 41-11, 41-13]

actuals:
  tokens: 9304
  tasks: 4
  commits: 5
plan_head_before: db548e7871e3cc6a0d52752dace3df797be6f475

tech-stack:
  added: []
  patterns:
    - "Construction de commits de preuve par plomberie git (GIT_INDEX_FILE, hash-object, write-tree, commit-tree) sans changer de branche ni toucher l'arbre de travail"
    - "Provenance d'un refus gh pr merge classée serveur/client_gh/indeterminee sur la forme de la sortie collée, jamais supposée"

key-files:
  created: []
  modified:
    - .planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md
    - .planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-06-PLAN.md
    - .planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-07-PLAN.md
    - .planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-08-PLAN.md
    - .planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-09-PLAN.md
    - .planning/WINDOWS.md

key-decisions:
  - "CO-DECISION: option=accepter-et-documenter decideur=Willy canal=AskUserQuestion-session-principale date=2026-09-24 — l'écart CO-VERDICT: ECART est accepté et documenté tel que mesuré, sans correction ni nouvelle tentative"
  - "Écart cadré par l'orchestrateur avant la Task 1 : la précondition de PR en vol prend désormais la ligne d'inventaire la plus récente entre PR-EN-VOL-APRES: et PR-EN-VOL-41-0N:, sur les plans 41-06 à 41-09 (commit 7799575, hors du périmètre strict de ce plan mais nécessaire à sa Task 1)"

requirements-completed: []  # PROT-04 déjà Complete depuis le plan 41-14 (G-1) — non retouché ici. PROT-01 reste explicitement Pending : ce plan mesure un ECART sur le temps (i) du critère 2, accepté et documenté (pas conforme) ; la clôture de PROT-01 reste gatée au plan 41-13 sur pièce, comme pour 41-05.

coverage:
  - id: D1
    description: "Trois PR de preuve construites par plomberie (PR-P sur README .github/rulesets/, PR-BASELINE sur la baseline du budget d'instructions, PR-SENTINELLE sur la sentinelle armée), publiées par Willy, CI verte sur les deux événements, lues côté serveur via l'API"
    requirement: "PROT-04"
    verification:
      - kind: integration
        ref: "gh pr view 101/102/103 --json headRefOid,state,files,mergeStateStatus,reviewDecision — comparaison têtes vs PR-P-COMMITS:/PR-CO-COMMITS:, fichiers vs chemin unique visé"
        status: pass
    human_judgment: false
  - id: D2
    description: "Temps (i) du critère 2 mesuré : mergeStateStatus=CLEAN (jamais BLOCKED) et reviewDecision vide (jamais REVIEW_REQUIRED) sur les trois PR malgré un ruleset actif exigeant require_code_owner_review — CO-VERDICT: ECART, recalculé et consigné sans correction (ADR-031)"
    requirement: "PROT-01"
    verification:
      - kind: manual_procedural
        ref: "gh pr view --json mergeStateStatus,reviewDecision collé par Willy (Task 2) + relecture indépendante de l'agent (Task 3) — les deux concordent sur CLEAN/vide"
        status: pass
    human_judgment: true
    rationale: "Le verdict ECART engage une interprétation (contournement always de picmakpro masquant le blocage plutôt qu'absence réelle de couverture CODEOWNERS) non prouvée au sens strict — la Task 4 l'a donc soumise à Willy plutôt que de l'inférer"
  - id: D3
    description: "Décision humaine explicite sur l'écart : accepter-et-documenter, jamais inférée — CO-DECISION consignée et committée séparément"
    verification:
      - kind: manual_procedural
        ref: "CO-DECISION: option=accepter-et-documenter decideur=Willy canal=AskUserQuestion-session-principale date=2026-09-24, 41-PREUVES.md, commit 55da448"
        status: pass
    human_judgment: true
    rationale: "Décision d'arbitrage humain par construction (checkpoint:decision, gate=blocking-human) — jamais auto-sélectionnable, même en mode auto"

duration: ~42min (09:28:21 à 10:10:14, horodatages des commits)
completed: 2026-09-24
status: complete
---

# Phase 41 Plan 06: Revue code owner — trois PR de preuve, écart mesuré, accepté et documenté Summary

**Trois PR de preuve (PR-P, PR-BASELINE, PR-SENTINELLE) ouvertes par Willy et lues côté serveur : `mergeStateStatus=CLEAN` et `reviewDecision` vide au lieu de `BLOCKED`/`REVIEW_REQUIRED` attendus — CO-VERDICT: ECART, accepté et documenté (Willy, 2026-09-24), imputé au contournement `always` des deux seuls collaborateurs du dépôt.**

## Performance

- **Duration:** ~42 min (09:28:21 à 10:10:14, horodatages des commits ; cette session a repris à la Task 4)
- **Started:** 2026-09-24T09:28:21+02:00
- **Completed:** 2026-09-24T10:10:14+02:00
- **Tasks:** 4/4 exécutées (Task 4 déclenchée : `CO-VERDICT: ECART`)
- **Files modified:** 6 (dont 5 touchés par un correctif de précondition transverse antérieur à la Task 1, hors périmètre strict de ce plan)

## Accomplishments
- P1/P2 (README `.github/rulesets/`, contenu français, aucun chemin de machine) et CB/CS (une ligne de commentaire ajoutée à la baseline et à la sentinelle, jamais de retrait) construits par plomberie sur `origin/main`, prouvés localement, sans changer de branche
- Willy (`picmakpro`) a publié les trois commits, ouvert PR-P (#101), PR-BASELINE (#102), PR-SENTINELLE (#103) ; CI verte sur les deux événements (`push`, `pull_request`) sur PR-P, `behind_by=0`
- Relecture API indépendante : les trois PR sont lues `mergeStateStatus=CLEAN` et `reviewDecision` vide, contre `BLOCKED`/`REVIEW_REQUIRED` attendus par le plan — mesure recalculée deux fois (collage de Willy, lecture propre de l'agent), concordante
- `merge_sans_contournement=non_tente` (jamais `refuse` ni `merge`) : conforme à l'instruction — aucune tentative de merge n'a eu lieu hors `BLOCKED`, l'ordre de sûreté de T-41-23 reste intact, rien n'a menacé d'atterrir sur `main`
- `CO-VERDICT: ECART` consigné tel quel, sans correction (ADR-031) ; Task 4 déclenchée
- Décision de Willy : **ACCEPTER ET DOCUMENTER** — `CO-DECISION: option=accepter-et-documenter decideur=Willy canal=AskUserQuestion-session-principale date=2026-09-24`, consignée et committée séparément (`55da448`)
- Écart tracé au ledger `WINDOWS.md` (entrée #9, `status=open`)

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Task 1 (précondition + Task 1) : mesure PR-EN-VOL-41-06** - `7394ca7` (docs, agent précédent)
2. **Correctif transverse de précondition (41-06 à 41-09)** - `7799575` (docs, agent précédent — hors strict périmètre de ce plan, nécessaire à la Task 1)
3. **Task 1 : commits de preuve préparés (P1/P2/CB/CS)** - `cf60d1e` (docs, agent précédent)
4. **Task 3 : temps (i) de la revue code owner consigné, provenance du refus** - `810c614` (docs, agent précédent — D-05, arbitrage Samuel, AskUserQuestion session principale, 2026-09-17)
5. **Task 4 : CO-DECISION consignée** - `55da448` (docs, cette session — arbitrage Willy, AskUserQuestion session principale, 2026-09-24)

**Plan metadata:** committée séparément après ce SUMMARY

_Task 2 (checkpoint:human-action) n'a laissé aucun commit d'agent — les gestes de Willy (publication, ouverture des trois PR, tentatives conditionnées à `BLOCKED`) sont recopiés verbatim dans le commit de la Task 3 (`810c614`)._

## Files Created/Modified
- `.planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md` - `PR-EN-VOL-41-06:`, `MAIN-AVANT-PREUVES:`, `PR-P-COMMITS:`, `PR-CO-COMMITS:`, `PR-P:`, `PR-BASELINE:`, `PR-SENTINELLE:`, `CO-I:`, `CO-I-MSG:`, `CO-I-GH-MSG:`, `CO-BASELINE:`, `CO-SENTINELLE:`, `CO-VERDICT:`, `CO-DECISION:`
- `.planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-06-PLAN.md`, `41-07-PLAN.md`, `41-08-PLAN.md`, `41-09-PLAN.md` - précondition de PR en vol élargie à la ligne d'inventaire la plus récente (correctif transverse, commit `7799575`)
- `.planning/WINDOWS.md` - entrée #9 (écart `CO-VERDICT: ECART` tracé au ledger, `status=open`)

## Decisions Made
- **CO-DECISION** : Willy tranche « ACCEPTER ET DOCUMENTER » (AskUserQuestion session principale, 2026-09-24). L'écart est écrit fidèlement, sans l'adoucir : les deux seuls collaborateurs du dépôt (`samuel-neveugall`, `picmakpro`) ont le contournement `always` (D-02bis) ; `mergeStateStatus` et `reviewDecision` sont calculés pour le compte lecteur ; aucun acteur réel du dépôt n'observe donc le refus par défaut ni la revue code owner exigée — la règle est posée et effective (`rules/branches/main`), mais elle ne s'impose qu'à un acteur hors liste, ce que le plan 41-09 mesurera avec une clé de déploiement temporaire pour le push direct. Le critère 2 du ROADMAP n'est pas tenu tel que formulé.
- **Suite prescrite, respectée sans anticipation** : PR-BASELINE (#102) et PR-SENTINELLE (#103) restent ouvertes — leur fermeture et la suppression de leurs branches sont le pas 0 de la Task 2 du plan 41-07, pas un geste de ce plan. PR-P (#101) reste ouverte pour le temps (ii) du plan 41-08.
- **Aucun `requirements mark-complete`** : PROT-04 est déjà `Complete` depuis le plan 41-14 (G-1) et n'est pas retouché ; PROT-01 reste `Pending` — sa clôture reste gatée au plan 41-13 sur pièce, l'ECART de ce plan ne le fait pas avancer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Précondition de PR en vol élargie à la ligne d'inventaire la plus récente**
- **Found during:** avant la Task 1 (agent précédent, hors de cette session)
- **Issue:** le contrôle de précondition de la Task 1 des plans 41-06 à 41-09 ne visait que `PR-EN-VOL-APRES:` (ligne historique de 41-05, périmée par le merge de `#93` et l'ouverture de `#99`/`#100`) — bloquant l'exécution sur un inventaire obsolète
- **Fix:** le contrôle prend désormais la ligne d'inventaire la plus récente parmi `PR-EN-VOL-APRES:` et `PR-EN-VOL-41-0N:`, sans affaiblir le contrôle (toute PR ouverte hors de cet inventaire reste un arrêt)
- **Files modified:** `41-06-PLAN.md`, `41-07-PLAN.md`, `41-08-PLAN.md`, `41-09-PLAN.md`
- **Verification:** précondition de la Task 1 de ce plan passée avec la ligne `PR-EN-VOL-41-06:` mesurée le 2026-09-24
- **Committed in:** `7799575` (agent précédent)

### Constat documenté, non corrigé (ECART mesuré, pas un bug de ce plan)

**2. `CO-VERDICT: ECART` — refus non observable depuis le seul compte disponible**
- **Trouvé pendant :** Task 3, relecture API des trois PR de preuve
- **Constat :** `mergeStateStatus=CLEAN` et `reviewDecision` vide sur PR-P/PR-BASELINE/PR-SENTINELLE, malgré CI verte, `behind_by=0` et un ruleset actif exigeant `require_code_owner_review: true` sur les trois chemins visés — l'explication la plus compatible (non prouvée au sens strict) est le contournement `always` de `picmakpro`, qui rend la PR mergeable pour son propre compte lecteur
- **Pourquoi non corrigé :** ni CODEOWNERS ni le ruleset ne sont modifiables sans arbitrage (Task 4, décision humaine explicite) ; aucun compte hors liste de contournement n'était disponible pour relire ces PR depuis cette session — c'est exactement le témoin discriminant que T-41-62 et le plan 41-07 (`CO-TEMOIN:`) visent à produire
- **Consigné dans :** `41-PREUVES.md` (`CO-I:`, `CO-BASELINE:`, `CO-SENTINELLE:`, `CO-VERDICT:`, `CO-DECISION:`), `WINDOWS.md` (entrée #9)

---

**Total deviations:** 1 auto-fix (1 blocking, précondition transverse) ; 1 écart mesuré, accepté et documenté sur décision humaine explicite (pas une correction de code).
**Impact on plan:** L'ECART n'a permis aucune tentative de merge sans contournement sur les trois PR — l'ordre de sûreté T-41-23 reste intact. Le plan 41-07 reste conditionné à `merge_sans_contournement=refuse`, absent ici (`non_tente`) : sa précondition dure doit donc être relue à la lumière de `CO-DECISION: option=accepter-et-documenter` (le plan 41-07 accepte explicitement `CO-DECISION: option=accepter-et-documenter` ET `merge_sans_contournement=refuse` comme alternative à `CO-VERDICT: CONFORME` — ici seule la première moitié est vraie, à vérifier par l'exécuteur du plan 41-07).

## Issues Encountered
- Aucun problème d'exécution — le comportement mesuré est l'écart lui-même, documenté ci-dessus, pas un incident technique.

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- `CO-DECISION: option=accepter-et-documenter` disponible pour la précondition du plan 41-07 (à lire avec `CO-I: merge_sans_contournement=non_tente`, pas `refuse` — l'exécuteur de 41-07 doit statuer si sa précondition dure est satisfaite par cette combinaison)
- PR-BASELINE (#102) et PR-SENTINELLE (#103) encore ouvertes : à fermer sans merge et supprimer leurs branches au pas 0 de la Task 2 du plan 41-07, comme prescrit
- PR-P (#101) encore ouverte, tête = `dc05507`, prête à servir de support pour le temps (ii) du plan 41-08
- `CO-TEMOIN:` (plan 41-07) doit encore produire le témoin discriminant hors CODEOWNERS pour confirmer ou infirmer l'hypothèse du contournement `always`
- Écart tracé au ledger `WINDOWS.md` (#9, `status=open`) — visible à `/gsd-ship`

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Completed: 2026-09-24*
