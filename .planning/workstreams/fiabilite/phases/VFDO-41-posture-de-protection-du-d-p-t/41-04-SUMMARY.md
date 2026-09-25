---
phase: 41-posture-de-protection-du-d-p-t
plan: 04
subsystem: infra
tags: [github-rulesets, codeowners, ci, pull-request, gouvernance-depot]

# Dependency graph
requires:
  - phase: 41-01
    provides: sources JSON versionnées des rulesets, identité picmakpro admin
  - phase: 41-02
    provides: CODEOWNERS posé (périmètre étroit), REQUIREMENTS.md amendé
  - phase: 41-03
    provides: ADR-072 amendée, ADR-059 amendée, section CLAUDE.md « Protection côté serveur »
provides:
  - PR de la phase (#90) mergée dans origin/main sans règle active en vol (D-M14 tenu)
  - branche B feat/phase-41-preuves-release ouverte depuis origin/main, porte les écritures suivantes (D-03)
  - ligne PR-PHASE consignée dans 41-PREUVES.md avec identité réelle du mergeur
affects: [41-05, 41-06, 41-07, 41-08, 41-09, 41-11, 41-12, 41-13]

actuals:
  tokens: 9000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Séquence D-M14 : PR de la phase mergée AVANT toute pose de règle, rulesets encore [] au merge"
    - "Identité réelle d'un geste externe consignée verbatim, jamais réécrite pour correspondre à l'intention"

key-files:
  created:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-04-SUMMARY.md
  modified:
    - .planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md
    - .planning/STATE.md

key-decisions:
  - "Fait consigné tel quel : la PR #90 a été mergée par samuel-neveugall (2026-09-23T14:41:20Z), pas par Willy — le geste de merge de Willy est arrivé après coup, GitHub a répondu « already merged »"
  - "Branche A locale (feat/phase-41-volet-admin) fast-forwardée sur origin avant comparaison des blobs .github/ : un tiers (samuel-neveugall) avait poussé un commit de fusion supplémentaire (f5db514, débogage PR #90) sur la branche distante entre l'ouverture et le merge"

patterns-established: []

requirements-completed: []

coverage:
  - id: D1
    description: "PR de la phase (#90) mergée dans origin/main, tête verte 8/8, 0 erreur CODEOWNERS, rulesets encore vides au merge"
    requirement: "PROT-01"
    verification:
      - kind: other
        ref: "gh pr view 90 --json state,mergeCommit ; gh api commits/{tete}/check-runs ; gh api codeowners/errors ; gh api rulesets"
        status: pass
    human_judgment: false
  - id: D2
    description: "Blobs .github/CODEOWNERS, .github/rulesets/main.json, .github/rulesets/tags-v.json identiques entre origin/main et la branche A relue"
    verification:
      - kind: other
        ref: "git rev-parse origin/main:.github/... == git rev-parse feat/phase-41-volet-admin:.github/..."
        status: pass
    human_judgment: false
  - id: D3
    description: "Branche B feat/phase-41-preuves-release ouverte depuis origin/main, ligne PR-PHASE consignée, rejeux gates et tests"
    verification:
      - kind: other
        ref: "bash .../replay-ci-jobs.sh --job gates (14 étapes, 0 échec) ; --job tests (84 suites, 2 échecs = WINDOWS #6/#7 préexistants)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-09-23
status: complete
---

# Phase 41 Plan 04: Merge de la PR de la phase et ouverture de la branche des preuves Summary

**PR #90 mergée dans `origin/main` sans qu'aucun ruleset n'existe encore (D-M14 tenu) — mergée en réalité par `samuel-neveugall`, pas par Willy, fait consigné tel quel ; branche `feat/phase-41-preuves-release` ouverte pour porter les preuves et la release.**

## Performance

- **Duration:** ~25 min (cette session de continuation — Task 1 et la résolution de Task 2 ont eu lieu dans des sessions antérieures)
- **Tasks:** 3/3 (Task 1 lecture seule déjà faite, Task 2 checkpoint humain déjà résolu, Task 3 exécutée dans cette session)
- **Files modified:** 3 (`41-PREUVES.md`, `STATE.md`, ce SUMMARY)

## Accomplishments

- Relecture post-merge complète : PR #90 `MERGED`, commit de merge `e70b22b71b5271c596ed5ff9cd053b498feefc8e` ancêtre d'`origin/main`, tête `f5db5145f239c5c38bbe7abcd74a15981bead3c3` verte 8/8 (4 jobs × 2 événements), `codeowners/errors=0` sur la branche par défaut, `rulesets=0`.
- Blobs `.github/CODEOWNERS`, `.github/rulesets/main.json`, `.github/rulesets/tags-v.json` vérifiés identiques entre `origin/main` et la branche A relue (`feat/phase-41-volet-admin`, fast-forwardée sur `origin` avant comparaison — un commit de fusion supplémentaire y avait été poussé entre l'ouverture de la PR et son merge, voir Déviations).
- Branche B `feat/phase-41-preuves-release` créée depuis `origin/main` ; ligne `PR-PHASE:` consignée dans `41-PREUVES.md` avec le numéro de PR, le sha de merge, le sha de tête, les checks, `codeowners_errors`, `rulesets_au_merge` et l'identité réelle du mergeur.
- Rejeu `gates` vert (14 étapes, 0 en échec). Rejeu `tests` : 84 suites, 2 échecs — les deux mêmes rouges locaux préexistants déjà consignés au ledger `.planning/WINDOWS.md` (#6, #7 : path-traversal T4 majuscules, module PyYAML absent pour python3), reproduits à l'identique sur la branche B, non régressifs, hors périmètre de ce plan.
- `STATE.md` mis à jour (note dans `## Current Position`, corps du fichier — le frontmatter reste fermé ligne 52, sous la fenêtre de 60 lignes lue par `check-dev-bootstrap.sh`).

## Task Commits

1. **Task 1 : branche A intégrée** — lecture seule, aucun commit (exécutée dans une session antérieure).
2. **Task 2 : gestes humains de Willy** — checkpoint humain, aucun commit direct produit par cette exécution (résolu par les gestes externes de la session principale, voir Décisions).
3. **Task 3 : relecture post-merge, branche B ouverte, `PR-PHASE:` consignée** — `2fb4f7d` (docs)

**Plan metadata:** commit à suivre (docs: complete plan)

## Files Created/Modified

- `.planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md` — section `## 41-04 — PR de la phase`, ligne `PR-PHASE:` et note narrative sur l'identité réelle du mergeur
- `.planning/STATE.md` — note `## Current Position` (corps uniquement, frontmatter intact)
- `.planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-04-SUMMARY.md` — ce fichier

## Decisions Made

- **Fait consigné tel quel, jamais réécrit** : la PR #90 a été mergée par `samuel-neveugall` (id 151974738) à `2026-09-23T14:41:20Z`, commit de merge `e70b22b71b5271c596ed5ff9cd053b498feefc8e`. Au moment du geste de merge de Willy (`gh pr merge 90 --merge`, décision AskUserQuestion session principale, 2026-09-23 — « Je merge depuis la session »), GitHub a répondu « already merged ». Willy n'a pas mergé cette PR — consigné explicitement dans `41-PREUVES.md` et `STATE.md` pour ne jamais laisser croire le contraire à un lecteur ultérieur.
- **Fast-forward de la branche A locale avant la comparaison des blobs** : entre l'ouverture de la PR et son merge, `samuel-neveugall` a poussé un commit de fusion (`f5db514`, « Merge origin/main dans feat/phase-41-volet-admin (débogage PR #90) ») rattrapant 7 commits arrivés sur `main` entre-temps (PR #91). La branche A locale (`63870e2`) était donc en retard sur ce qui a réellement été mergé ; un fast-forward (`git merge --ff-only origin/feat/phase-41-volet-admin`) l'a alignée avant que le contrôle d'égalité des blobs `.github/` ne soit joué, pour que la comparaison porte sur ce qui a réellement atterri sur `main`, pas sur un état local périmé.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Branche A locale en retard sur ce qui a réellement été mergé**
- **Found during:** Task 3 (relecture post-merge)
- **Issue:** La commande de merge du plan supposait un fast-forward simple depuis la tête connue de la Task 1 (`63870e2`). En réalité, un tiers (`samuel-neveugall`, dans une autre session, « débogage PR #90 ») avait poussé un commit de fusion supplémentaire sur la branche distante `feat/phase-41-volet-admin` avant le merge, pour rattraper 7 commits arrivés entre-temps sur `main` (PR #91). Sans réalignement, le contrôle d'égalité des blobs `.github/` de la Task 3 aurait comparé `origin/main` à un état local périmé.
- **Fix:** `git fetch origin` puis `git merge --ff-only origin/feat/phase-41-volet-admin` sur la branche A locale, confirmé fast-forward pur (aucune divergence, `63870e2` ancêtre de `f5db514`). La comparaison des blobs a ensuite porté sur l'état réellement mergé.
- **Files modified:** aucun fichier de contenu (fast-forward de branche uniquement)
- **Verification:** les trois blobs `.github/CODEOWNERS`, `.github/rulesets/main.json`, `.github/rulesets/tags-v.json` rendent le même sha entre `origin/main` et `feat/phase-41-volet-admin` après le fast-forward
- **Committed in:** aucun commit (mise à jour de référence de branche, pas de contenu)

---

**Total deviations:** 1 auto-fixed (1 bloquant)
**Impact on plan:** Nécessaire pour que le contrôle d'égalité des blobs porte sur l'état réellement mergé plutôt que sur un état local périmé. Aucune dérive de périmètre.

## Issues Encountered

Rejeu `tests` : 84 suites, 2 échecs — mêmes rouges locaux préexistants que ceux déjà consignés au ledger `.planning/WINDOWS.md` (#6 : `test-register-codex-agent-path-traversal.sh`, T4 majuscules accepté à tort ; #7 : `test-check-description-fidelity.sh`, module PyYAML introuvable pour `python3` sur ce poste). Reproduits à l'identique sur la branche B, non régressifs, hors périmètre de ce plan, jamais neutralisés ni corrigés sans validation humaine (ADR-031). Le rejeu `gates`, seul exigé vert par la précondition de la phase, est vert (14 étapes, 0 en échec).

## Known Stubs

Aucun.

## User Setup Required

None - aucune configuration de service externe requise par ce plan.

## Next Phase Readiness

- La source relue est sur `main`, aucune règle n'a changé en vol (`rulesets` toujours `[]` au merge et à la relecture).
- La branche B `feat/phase-41-preuves-release` est ouverte depuis `origin/main` et porte désormais toutes les écritures de la suite de la phase (D-03 : plus aucun commit direct sur `main`).
- `PROT-01` reste **non coché** — la pose effective des deux rulesets (plan 41-05) est la prochaine étape ; ce plan ne fait que lever le préalable D-M14 (source mergée, `main` verte).

---
*Phase: 41-posture-de-protection-du-d-p-t*
*Completed: 2026-09-23*
