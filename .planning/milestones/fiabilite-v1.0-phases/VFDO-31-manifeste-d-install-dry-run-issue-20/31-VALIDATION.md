---
phase: 31
slug: manifeste-d-install-dry-run-issue-20
status: reviewed
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-16
updated: 2026-08-16
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash test scripts — no external runner. Convention: `set -uo pipefail`, `ok()/ko()/skip()` helpers, numbered asserts, exit 1 if ≥1 KO. Model: `plugin/_internal/tests/test-vibeflow-update.sh:29-41`. |
| **Config file** | none — CI discovers suites by filesystem glob, no registration file |
| **Quick run command** | `bash plugin/_internal/tests/test-manifest.sh` |
| **Full suite command** | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| while read t; do bash "$t" \|\| echo "FAIL $t"; done` (mirrors `.github/workflows/ci.yml:210-237`) |
| **Estimated runtime** | ~5-15 seconds per suite (bash, no network, no build step) |

---

## Sampling Rate

- **After every task commit:** Run `bash plugin/_internal/tests/test-manifest.sh` (once it exists) plus the two non-regression suites (`test-vibeflow-update.sh`, `test-merge-hooks.sh`)
- **After every plan wave:** Run the full discovery command above, on the tree **as committed** (not the working tree — 31-CONTEXT.md §4 point 5)
- **Before `/gsd-verify-work`:** Full suite must be green, mutation-red trace recorded (assertion / expected / actual) for every new suite
- **Max feedback latency:** ~30 seconds (no test in this phase touches network or a build pipeline)

---

## Per-Task Verification Map

> Renseigné depuis les 8 plans réels (revue ciblée du 2026-08-16, findings BL-1..BL-11). Chaque
> ligne pointe la tâche du plan qui la couvre effectivement, pas un slot générique.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01/T1 | 31-01 | 1 | MANI-01 (tracer) | T-31-01/02/05 | socle manifeste + 1 site câblé, écriture atomique tmp+mv | integration | `bash plugin/_internal/tests/test-vibeflow-update.sh && bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ exists (non-régression) | ⬜ pending |
| 31-01/T2 | 31-01 | 1 | MANI-01, QUAL-01 (T1-T5), D-31-08 | T-31-06 | manifeste conforme D-31-02/D-31-03 sur 1 site réel ; compteurs README à jour dans le même commit | integration | `bash plugin/_internal/tests/test-manifest.sh` | ❌ créé par cette tâche | ⬜ pending |
| 31-02/Tp1-5 | 31-02 | 1 | MANI-02 (régime B), QUAL-01 | T-31-09 | `merge-hooks.sh` mode `plan` délégué, aucune écriture, même répartition local/projet que `merge` | integration | `bash plugin/_internal/tests/test-merge-hooks.sh` | ❌ cas ajoutés par cette tâche | ⬜ pending |
| 31-03/checkpoint | 31-03 | 2 | — | — | ratification de la couture d'écriture avant migration des ~35 sites | human gate | — | — | ⬜ pending |
| 31-03/T2 | 31-03 | 2 | MANI-01 (mécanique) | T-31-04/11/12/13 | ~35 sites routés, zéro régression, `set -e`×rc respecté (gardes conservées) | regression | `bash plugin/_internal/tests/test-vibeflow-update.sh && bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ exists (non-régression) | ⬜ pending |
| 31-03/T3 | 31-03 | 2 | MANI-01, QUAL-01 (T6-T9) | T-31-11/12 | égalité totale manifeste↔disque, grain fichier sur `cp -r`, asymétrie `docs/` (moitié manifeste) | integration + mutation | `bash plugin/_internal/tests/test-manifest.sh` | ❌ cas ajoutés par cette tâche | ⬜ pending |
| 31-04/T2 | 31-04 | 3 | MANI-02 | T-31-08/09/10 | `--dry-run` n'écrit rien, régime A prédit exactement (garde côté SOURCE), régime B délégué, régime C annoncé | integration | `bash -n plugin/_internal/vibeflow-update.sh && bash plugin/_internal/tests/test-vibeflow-update.sh && bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ exists (non-régression) | ⬜ pending |
| 31-04/T3 | 31-04 | 3 | MANI-02, QUAL-01 (T10, T10b, T11-T13, T13b, T14) | T-31-08 | égalité totale (fixture sans régime C) + discriminance régime A (fixture dédiée) + asymétrie `docs/` (moitié plan) + refus bruyant sur `uninstall --dry-run` | integration + mutation | `bash plugin/_internal/tests/test-manifest.sh` | ❌ cas ajoutés par cette tâche | ⬜ pending |
| 31-05/T2 | 31-05 | 4 | MANI-03 | V5 path-traversal / absolute-path rejection | convergence deletes only manifested+absent+on-disk+under-TARGET_ROOT paths, with backup; third-party file untouched | integration | `bash -n plugin/_internal/vibeflow-update.sh && bash plugin/_internal/tests/test-vibeflow-update.sh && bash plugin/_internal/tests/test-merge-hooks.sh` | ✅ exists (non-régression) | ⬜ pending |
| 31-05/T3 | 31-05 | 4 | MANI-03, QUAL-01 (T15-T20) | V5 unparsable = LOUD + non-destructive | 3 issues (PASS/FAIL/imparsable) couverts, mutation rouge tracée, resync sans manifeste partiel | integration + mutation | `bash plugin/_internal/tests/test-manifest.sh` | ❌ cas ajoutés par cette tâche | ⬜ pending |
| 31-06/T1-T2 | 31-06 | 5 | D-31-10 | — | wiring skills `/vibeflow-install`/`vf-calibrate` + bump conductor | doc + gate | `bash scripts/check-version-sync.sh && bash scripts/check-machine-paths.sh` | ✅ gates existants | ⬜ pending |
| 31-07/T1-T2 | 31-07 | 5 | MANI-01 (D-31-09, lot abandonnable) | — | `uninstall_module` lit le manifeste au lieu de reconstruire depuis le cache ; repli gracieux si absent | integration | `bash plugin/_internal/tests/test-manifest.sh` | ❌ cas ajoutés par cette tâche | ⬜ pending |
| 31-08/T1 | 31-08 | 6 | QUAL-01 (doc de clôture) | — | brouillon de réponse à l'issue #20, aucune commande GitHub exécutée | doc | manuel (attesté dans SUMMARY) | ❌ créé par cette tâche | ⬜ pending |
| 31-08/T2 | 31-08 | 6 | MANI-04 (bilan), Non-régression | T-31-13 | suite complète verte sur l'arbre TEL QUE COMMITÉ, compteurs README exacts, aucun untracked étranger commité | regression | `bash scripts/check-version-sync.sh && bash scripts/check-machine-paths.sh` (+ rejeu complet `git archive HEAD`) | ✅ gates existants | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky — tous `⬜ pending` car ce plan n'a pas encore été exécuté ; cette carte sera mise à jour par `/gsd-execute-phase`, pas par cette correction ciblée.*

---

## Wave 0 Requirements

- [x] `plugin/_internal/tests/test-manifest.sh` — créée en 31-01/T2 (cas T1-T5), étendue en
      31-03/T3 (T6-T9), 31-04/T3 (T10, T10b, T11-T13, T13b, T14), 31-05/T3 (T15-T20), 31-07 (cas
      module absent du cache). Couvre MANI-01/02/03 et les trois issues de QUAL-01 + l'exigence de
      mutation rouge (voir la carte ci-dessus). Aucun framework de fixtures partagé requis au-delà du
      style temp-dir-par-test déjà en place (`test-vibeflow-update.sh`).
- [x] `plugin/_internal/merge-hooks.sh` mode `plan` — créé en 31-02, cas `Tp1-5` dans
      `test-merge-hooks.sh`.

*No framework install needed — bash + coreutils already present, `python3` already used by
`merge-hooks.sh`.*

---

## Manual-Only Verifications

*None — all phase behaviors (manifest write, dry-run parity, convergence delete, unparsable refusal)
are scriptable against a fixture module in a temp `TARGET_ROOT`, matching the existing suite's style.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — vérifié sur les 8 plans ; seule
      la tâche de checkpoint (31-03) n'en porte pas, ce qui est attendu pour un `type="checkpoint:decision"`.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify — le seul « trou » est le
      checkpoint de 31-03, encadré de tâches vertes de part et d'autre.
- [x] Wave 0 covers all MISSING references — `test-manifest.sh` et le mode `plan` de
      `merge-hooks.sh` sont les deux seuls artefacts neufs référencés par tous les plans avals.
- [x] No watch-mode flags — toutes les commandes de `<verify>` sont one-shot bash.
- [x] Feedback latency < 30s — suites bash sans réseau ni build, quelques secondes chacune.
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validation renseignée depuis les plans réels (correction ciblée du 2026-08-16,
findings BL-1..BL-11) ; reste `pending` sur le fond — l'approbation d'exécution appartient au
manager, pas à cette correction de planning.
