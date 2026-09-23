---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 01
subsystem: infra
tags: [github, rulesets, gh-api, ci, security, gitops]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t
    provides: "41-CONTEXT.md § REPRISE (D-02bis, accès admin constaté 2026-09-23) et 41-PREUVES.md
      § 41-01 — préalables externes (CONTEXTES-CHECKS du 2026-09-17)"
affects: [41-02, 41-03, 41-04, 41-05, 41-06, 41-07, 41-08, 41-09, 41-11, 41-12, 41-13]

# Actuals (#2632)
actuals:
  tokens: 9000
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Génération des contextes de required_status_checks par jq depuis les check runs live
      (app.id 15368) intersectés avec les 4 `name:` de jobs de `ci.yml`, jamais une liste tapée"
    - "Identifiants de bypass_actors lus programmatiquement dans une section `ACTEURS-CONTOURNEMENT:`
      mesurée du registre de preuves, jamais recopiés depuis le CONTEXT"

key-files:
  created:
    - .github/rulesets/main.json
    - .github/rulesets/tags-v.json
  modified:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md
    - .planning/WINDOWS.md

key-decisions:
  - "L'ancienne Task 2 du plan (sonde humaine de l'identifiant du rôle `write`) est SANS OBJET
    depuis D-02bis (2026-09-23) : le contournement par rôle est remplacé par deux `User` nommés
    (samuel-neveugall, picmakpro) — rien à sonder côté rôle."
  - "La fermeture de la PR #29 (D-08) est CONSTATÉE (relue CLOSED, closedAt 2026-09-23T10:48:32Z),
    jamais rejouée par ce plan : elle avait déjà été faite hors de cette session."
  - "L'inventaire des PR en vol (PR-EN-VOL-REPRISE) a dû être re-mesuré deux fois pendant
    l'exécution : la PR #89 est passée d'OPEN à MERGED entre la première et la seconde mesure
    (concurrence réelle sur le dépôt), faisant aussi avancer `origin/main` de `e429cb1` à
    `6a7b15b`. Les deux sources JSON et la section de preuves ont été régénérées contre le SHA
    final avant la clôture du plan — aucune valeur mesurée en amont de la dérive n'est restée
    dans un fichier committé."
  - "Un commit initial du plan (Task 1) citait `D-08` sans la citation d'arbitrage requise par le
    contrôle de trace de ce même plan ; corrigé par un `git reset --soft` local (aucun push,
    aucune perte de contenu de fichier) suivi d'un nouveau message sans cette citation
    superflue — Rule 1, bug d'auto-vérification, corrigé avant la fin de la Task 2."

requirements-completed: []  # PROT-01 reste NON coché : `requirements.ready-ids` confirme 0/1 prêt
  # (les plans frères 41-02..41-13 qui déclarent PROT-01 n'ont pas encore de SUMMARY — la pose
  # effective du ruleset, qui seule ferme PROT-01, est au plan 41-05).

coverage:
  - id: D1
    description: "Préalables de la reprise re-mesurés à l'exécution et consignés dans
      41-PREUVES.md § 41-01 — reprise du volet admin : identité admin, deux acteurs de
      contournement, #29 CLOSED, rulesets vides, PR en vol, 4 contextes de checks"
    requirement: PROT-01
    verification:
      - kind: other
        ref: "3 blocs <automated> de la Task 1 du plan (identité/admin/collaborateurs ;
          consignation croisée avec l'API ; contextes de checks vs ci.yml et vs la mesure du
          2026-09-17), rejoués après régénération sur le SHA final"
        status: pass
    human_judgment: false
  - id: D2
    description: ".github/rulesets/main.json et .github/rulesets/tags-v.json écrits depuis les
      valeurs mesurées (D-02bis compris) — deletion/non_fast_forward/pull_request/
      required_status_checks pour main, deletion/non_fast_forward/update (sans creation) pour
      tags-v ; bypass_actors = deux User en always"
    requirement: PROT-01
    verification:
      - kind: other
        ref: "3 blocs <automated> de la Task 2 (conformité champ par champ de main.json, de
          tags-v.json, égalité des contextes avec l'API et ci.yml), rejoués après régénération"
        status: pass
    human_judgment: false
  - id: D3
    description: "Aucune écriture chez GitHub ; check-machine-paths et rejeu gates (14 étapes)
      verts ; tout commit du plan citant D-01..D-10 ou D-02bis porte l'arbitrage attendu"
    verification:
      - kind: other
        ref: "bash scripts/check-machine-paths.sh (rc 0) ; replay-ci-jobs.sh --job gates
          (rc 0, 14 rejouées, 3 sautées) ; contrôle de trace des arbitrages sur la plage de
          commits du plan (rc 0, 3 commits de plan, 0 sans citation)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Rejeu tests : deux rouges rencontrés (test-register-codex-agent-path-traversal.sh
      T4 majuscules ; test-check-description-fidelity.sh, PyYAML absent pour python3), confirmés
      préexistants par extraction git archive d'origin/main, hors périmètre de ce plan"
    verification:
      - kind: integration
        ref: "replay-ci-jobs.sh --job tests (bilan 83 suites, 2 échecs) ; reproduction identique
          des deux échecs sur `git archive origin/main` extrait à part ; consignés au ledger
          .planning/WINDOWS.md (entrées #6, #7, status=open)"
        status: fail
    human_judgment: true
    rationale: "Le plan prescrit explicitement de ne jamais neutraliser ni déclarer vert un rouge
      qui se reproduit sur une extraction propre d'origin/main — de le consigner et de le
      remonter human_needed. Les deux fichiers en cause (plugin/_internal/runtime-adapter,
      plugin/conductor) sont hors du périmètre de ce plan (sources JSON de rulesets sous
      .github/rulesets/) ; les corriger sans validation humaine violerait ADR-031. Un humain doit
      confirmer soit un correctif ciblé (bug de validation des majuscules) soit un geste
      d'environnement (installer PyYAML) avant que ce critère referme au vert."

status: complete
duration: ~40min
completed: 2026-09-23
---

# Phase 41 Plan 01: Reprise du volet admin — préalables re-mesurés et sources JSON des rulesets Summary

**Reprise de la Task 1 (préalables re-mesurés sous D-02bis) et de la Task 2 (sources JSON des deux
rulesets écrites depuis les valeurs mesurées, rien posé chez GitHub) — l'ancienne sonde du rôle
`write` est sans objet, #29 est constatée close, pas rejouée.**

## Performance

- **Duration:** ~40 min (interactif, dont ~10 min de rejeu `tests` en tâche de fond)
- **Completed:** 2026-09-23
- **Tasks:** 2/2
- **Files modified:** 4 (2 créés sous `.github/rulesets/`, 2 mis à jour :
  `41-PREUVES.md`, `.planning/WINDOWS.md`)

## Accomplishments
- Préalables de la reprise re-mesurés à l'exécution (identité `picmakpro` admin, deux acteurs de
  contournement `samuel-neveugall`/`picmakpro`, #29 `CLOSED`, `rulesets` vides, PR en vol, 4
  contextes de checks) et consignés dans `41-PREUVES.md` § 41-01 — reprise du volet admin
- `.github/rulesets/main.json` écrit : `deletion`, `non_fast_forward`, `pull_request` (0
  approbation, revue code owner requise, merge/squash/rebase), `required_status_checks` (4
  contextes, `integration_id` 15368, strict) ; `bypass_actors` = deux `User` (`samuel-neveugall`,
  `picmakpro`) en `always` (D-02bis)
- `.github/rulesets/tags-v.json` écrit : `deletion`, `non_fast_forward`, `update` (aucune règle
  `creation` — D-07) ; mêmes `bypass_actors`
- Rejeu `gates` vert (14 étapes) ; `check-machine-paths` vert ; contrôle de trace des arbitrages
  vert sur les 3 commits du plan
- Deux rouges préexistants du rejeu `tests` confirmés hors périmètre (extraction `git archive`
  d'`origin/main`) et consignés au ledger `.planning/WINDOWS.md`, remontés `human_needed`

## Task Commits

Each task was committed atomically:

1. **Task 1: re-mesure à la reprise** - `20448bf` (docs) — recommité une fois pour retirer une
   citation `D-08` sans son arbitrage requis (voir Deviations)
2. **Task 2: écrire les deux JSON depuis les valeurs mesurées** - `d6323c9` (feat)
3. **Consignation ledger des deux rouges préexistants** - `620a1e5` (docs, rattaché à la Task 2)

**Plan metadata:** commit à suivre (SUMMARY + STATE + ROADMAP)

## Files Created/Modified
- `.github/rulesets/main.json` - source versionnée du ruleset de branche `main`
- `.github/rulesets/tags-v.json` - source versionnée du ruleset de tags `v*`
- `.planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md` - section `## 41-01 —
  reprise du volet admin (2026-09-23)`
- `.planning/WINDOWS.md` - deux entrées `deviation` (id 6, 7) pour les rouges préexistants

## Decisions Made
- L'ancienne Task 2 (sonde de l'`actor_id` du rôle `write`) devient sans objet : D-02bis remplace
  le contournement par rôle par deux utilisateurs nommés — rien à sonder.
- La fermeture de #29 (D-08) est constatée, pas rejouée : elle avait déjà eu lieu avant cette
  session (`closedAt=2026-09-23T10:48:32Z`).
- Les valeurs mesurées (PR en vol, SHA d'`origin/main`, contextes de checks) ont dû être
  re-mesurées en cours d'exécution après qu'une PR concurrente (#89) a été mergée pendant le
  travail — `41-PREUVES.md` et les deux JSON reflètent la mesure finale, cohérente entre eux.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Commit Task 1 citait D-08 sans l'arbitrage requis par le contrôle de trace du
plan lui-même**
- **Found during:** Task 2, dernier bloc `<automated>` (contrôle de trace des arbitrages)
- **Issue:** Le message du commit `c689c38` (première version de la Task 1) contenait
  « #29 relue CLOSED (D-08 constaté, pas rejoué) », ce qui fait matcher le motif D-01..D-10 du
  contrôle sans porter la citation « arbitrage Samuel, AskUserQuestion session principale,
  2026-09-17 » exigée par ce même contrôle.
- **Fix:** `git reset --soft HEAD~2` (local, non poussé, aucune perte de fichier — l'index et le
  répertoire de travail restent identiques), puis recommit de la Task 1 sans la mention nue de
  `D-08` (« #29 relue CLOSED (constat, pas rejoué) »), puis recommit de la Task 2 à l'identique.
- **Files modified:** aucun fichier de contenu (seul le message de commit change)
- **Verification:** contrôle de trace des arbitrages rejoué, `sans_canal=0`
- **Committed in:** `20448bf` (Task 1 recommise), `d6323c9` (Task 2 recommise)

---

**Total deviations:** 1 auto-fixé (1 bug de discipline de commit)
**Impact on plan:** Correction locale avant toute publication, aucun contenu de fichier affecté,
aucune perte de travail. Pas de dérive de portée.

## Issues Encountered
- Une PR concurrente (#89) est passée d'`OPEN` à `MERGED` pendant l'exécution, faisant avancer
  `origin/main` de `e429cb1` à `6a7b15b` entre la première et la seconde mesure. Résolu en
  re-mesurant tout (identité, collaborateurs, PR en vol, contextes de checks, régénération des
  deux JSON) contre le SHA final juste avant de committer et de vérifier — aucune valeur périmée
  n'est restée dans un fichier committé.
- Rejeu `tests` (bilan 83 suites, 2 échecs) : `plugin/_internal/runtime-adapter/tests/test-register-codex-agent-path-traversal.sh`
  (T4, cas majuscules accepté à tort) et `plugin/conductor/scripts/tests/test-check-description-fidelity.sh`
  (36 KO, module Python PyYAML introuvable pour python3 sur ce poste). Les deux rouges se
  reproduisent à l'identique sur une extraction `git archive origin/main` isolée — préexistants,
  hors du périmètre de ce plan (sources JSON de rulesets). Non neutralisés, non déclarés verts,
  consignés au ledger `.planning/WINDOWS.md` (entrées #6 et #7, `status=open`) et remontés
  `human_needed` conformément à l'instruction explicite du plan.

## Next Phase Readiness
- Les deux sources JSON sont prêtes à être mergées dans `main` (plan 41-04) puis posées (plan
  41-05, checkpoint humain) — rien n'est encore actif chez GitHub, `PROT-01` reste non coché.
- Les plans 41-02 à 41-13 restent à exécuter dans l'ordre du plan (revue code owner, pose,
  preuves à deux branches, rejeu du flux de release sous la règle).
- Les deux rouges préexistants du rejeu `tests` (ci-dessus) sont un blocage potentiel pour la
  vérification finale de phase si elle exige `tests rc=0` — à trancher par un humain avant la
  clôture de la phase (ledger `.planning/WINDOWS.md`).

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Completed: 2026-09-23*

## Self-Check: PASSED
- `.github/rulesets/main.json` : FOUND
- `.github/rulesets/tags-v.json` : FOUND
- `41-01-SUMMARY.md` : FOUND
- Commits `20448bf`, `d6323c9`, `620a1e5`, `abe7e1f` : FOUND dans `git log`
