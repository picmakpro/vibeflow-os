---
phase: "57"
slug: "verrou-de-driver-par-compartiment"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 57 — Validation Strategy

> Contrat de validation de la phase, utilisé pour l'échantillonnage du retour pendant l'exécution.
> Source : `57-RESEARCH.md` § Validation Architecture (mesures sur clone jetable de `c6606cd0`).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | suites bash maison (`set -uo pipefail`, `assert`/`assert_exit`, `mktemp -d` + `trap`) ; pas de harnais partagé entre suites (TESTING.md) |
| **Config file** | none — découverte CI `find plugin scripts -type f -path '*/tests/test-*.sh'` (`ci.yml`) |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-driver-lock-ws.sh && bash plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh && bash plugin/conductor/scripts/tests/test-driver-lock.sh && bash plugin/conductor/scripts/tests/test-guard-driver-lock.sh` |
| **Full suite command** | `for t in $(find plugin scripts -type f -path '*/tests/test-*.sh' \| sort); do bash "$t" \|\| echo "FAIL $t"; done` + `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` + `bash plugin/conductor/scripts/check-instruction-budget.sh` (à rejouer sous `HOME=$(mktemp -d)` pour le job `tests`) |
| **Estimated runtime** | plusieurs minutes pour le quick run (les suites neuves rejouent mutants et boucles de concurrence, à détacher par `nohup`, borne 600 s) ; boucle complète > 600 s, à détacher |

---

## Sampling Rate

- **After every task commit:** les 4 suites du Quick run.
- **After every plan wave:** suites existantes de la classe E (driver-lock, guard, dag, guard-health, branch-claim, mission-exit, dev-orchestrator, design-orchestrator, hook-exit-*) + les 4 suites neuves + lint des consommateurs + budget d'instructions.
- **Before `/gsd-verify-work`:** boucle CI complète verte (rejeu des commandes du job `gates` de `ci.yml`, jamais une liste de rapport).
- **Max feedback latency:** 600 s (suites neuves détachées).

---

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| DLWS-01 | deux compartiments acquis ; même compartiment refusé `held` ; 1ᵉʳ ET dernier compartiment exercés ; 24 acquisitions concurrentes × 2 compartiments → 1 gagnant chacun | unit + concurrence | `bash plugin/conductor/scripts/tests/test-driver-lock-ws.sh` | ❌ W0 | ⬜ pending |
| DLWS-02 | verrou de dépôt indépendant des compartiments ; deux `--depot` concurrents → 1 gagnant | concurrence | idem | ❌ W0 | ⬜ pending |
| DLWS-03 | lab plat : sortie A/B octet pour octet contre `git show <base>:…/driver-lock.sh` ; `test-driver-lock.sh` et `test-guard-driver-lock.sh` verts ET `git diff --stat <base> -- <ces deux fichiers>` vide | non-régression | `bash …/test-driver-lock-ws.sh` (A/B) ; `bash …/test-driver-lock.sh` ; `bash …/test-guard-driver-lock.sh` | ❌ W0 (A/B) / ✅ | ⬜ pending |
| DLWS-04 | `--ws` inconnu / invalide → refus nommé + `hint` ; `GSD_WORKSTREAM`/`VF_WORKSTREAM` posés et ignorés ; sans `--ws` → `scope: depot` + raison | unit + mutant | `bash …/test-driver-lock-ws.sh` | ❌ W0 | ⬜ pending |
| DLWS-05 | partage entre worktrees ; hors git → repli déclaré dans `location` ; guard résout au même endroit | intégration fixture | `bash …/test-driver-lock-ws.sh` ; `bash …/test-guard-driver-lock-ws.sh` | ❌ W0 | ⬜ pending |
| DLWS-06 | Write/Edit et commit refusés sur ce qui est tenu par autrui seulement ; index illisible / crash → deny ; checkout/switch refusés ; exemptions D-32-06 ; 4 issues du guard (PASS / DENY / imparsable silencieux / code 17) | unit + mutant | `bash plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh` | ❌ W0 | ⬜ pending |
| DLWS-07 | `status` par compartiment, E1, watchdog, branch-claim, guard-health, `dag.sh` alignés ; lint de recensement rc=0 ; budget d'instructions rc=0 ; ADR-053 amendé et daté | intégration + grep | `bash …/test-driver-lock-consumers-ws.sh` ; `bash plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh` ; lint ; budget | ❌ W0 | ⬜ pending |
| DLWS-08 | chaque comportement neuf a ses issues et sa mutation rouge prouvée (bilan codé en dur, trace du rouge : assertion, attendu, obtenu) | mutation | sections « mutants » des suites neuves | ❌ W0 | ⬜ pending |

*Le détail par tâche (`{N}-PP-TT`) est porté par les blocs `<verify>` des plans ; cette table est re-dérivée à la validation de phase.*

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `plugin/conductor/scripts/tests/test-driver-lock-ws.sh` — DLWS-01..05, 08 ; constructeur de clone partitionné jetable + préflight anti-pollution du vrai `.git` (le `--git-common-dir` du cwd doit être sous `$WORK_DIR`)
- [ ] `plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh` — DLWS-05 (guard), 06, 08
- [ ] `plugin/conductor/scripts/tests/test-driver-lock-consumers-ws.sh` — DLWS-07 (branch-claim, guard-health, dag)
- [ ] `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit-ws.sh` — DLWS-07 (E1)

*Aucun framework à installer. Les suites existantes ne reçoivent AUCUNE modification (témoin DLWS-03).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Usage concurrent réel, à deux humains | hors périmètre | Phase 61 | — |
| Comportement sous Windows (MSYS) et Linux du chemin `--git-common-dir` | DLWS-05 | aucun runner Windows ; Linux couvert par la CI seulement | relire la CI Linux de la branche ; Windows `[ASSUMED]` tracé |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 600s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
