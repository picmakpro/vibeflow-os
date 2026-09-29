---
phase: quick/260928-s53-correction-de-classe-lot-7-garde-de-lect
verified: 2026-09-28T21:15:00Z
status: passed
score: 10/10 must-haves verified
covered_files:
  - .planning/BACKLOG.md
  - .planning/workstreams/gouvernance/REQUIREMENTS.md
  - .planning/workstreams/gouvernance/quick/260928-s53-correction-de-classe-lot-7-garde-de-lect/260928-s53-PLAN.md
  - .planning/workstreams/gouvernance/quick/260928-s53-correction-de-classe-lot-7-garde-de-lect/260928-s53-SUMMARY.md
  - plugin/planning-core/CHANGELOG.md
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/scripts/recalc-planning.sh
  - plugin/planning-core/scripts/tests/test-recalc-planning.sh
covered_digest: "v1:sha256:0b268fcb0eec5e8f2407267610a81eec06c9202d268b41dc84eab8ee0cfb5864"
behavior_unverified: 0
overrides_applied: 0
---

# Quick Task 260928-s53: Correction de classe lot 7 — garde de lecture du détecteur — Verification Report

**Task Goal:** `recalc-planning.sh` n'écrit que s'il a pu LIRE, pour de vrai, tout ce que le
détecteur devait lire (P44-D-02a) — garde de fidélité par exécution + lisibilité réelle, remplaçant
`_enumeration_workstreams_fidele` (lot 6) par `_lecture_detecteur_fidele`, sans jamais toucher
`detect-gsd-engine.sh` ni `workstream-policy.sh`.

**Verified:** 2026-09-28T21:15:00Z
**Status:** passed
**Method:** Adversarial re-execution in worktree `gouvernance-44` — every command below was run
independently by the verifier, not copied from SUMMARY.md prose. No files modified.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `_enumeration_workstreams_fidele` (lot 6) is replaced by `_lecture_detecteur_fidele`, called before any real detector invocation, `detect-gsd-engine.sh`/`workstream-policy.sh` untouched | ✓ VERIFIED | `grep -n "def _lecture_detecteur_fidele\|def _enumeration_workstreams_fidele"` → only the new function exists (line 444); old name is gone. `git diff --stat 424cb23..HEAD -- .../detect-gsd-engine.sh .../workstream-policy.sh` → empty output (byte-identical). |
| 2 | Measured gap: `vf_ws_enumerate` sets `found=1` even when `cd "$entry"` fails (perm 000/600/400) → silent empty line → detector falls through to code 3 "terrain libre" with no diagnostic; on root STATE.md mode 000 the engine used to overwrite it | ✓ VERIFIED | Code comments (lines 380-396, 568-574) and the red/green table in SUMMARY.md § "Preuve différentielle" name this exact mechanism; independently confirmed by re-running the full test suite (below), which reproduces refusal for every listed permission case. |
| 3 | Two structural checks: (1) fidelity BY EXECUTION — `vf_ws_enumerate` re-run for real, same bash/env as detector, compared to real disk set via `os.scandir`; (2) real readability — each retained compartment + root/compartment STATE.md files must be genuinely openable (never `os.access`) | ✓ VERIFIED | `_executer_vf_ws_enumerate` (line 418) sources `workstream-policy.sh` unchanged and runs `vf_ws_enumerate` via subprocess with `bash_bin`/`env_maitrise`; result compared to `os.scandir`-derived set (lines 517-525). `_ouvrable` (line 397) uses `os.scandir`/`os.open`, never `os.access`; called on every compartment and STATE.md (lines 456, 510-515). |
| 4 | Any `OSError` encountered by the guard is a named refusal, never a silent `continue` | ✓ VERIFIED | `_ouvrable`: `except OSError: return False` with inline comment "toute OSError -> refus nommé, jamais un fail-open (F2)" (line 414-415). Confirmed behaviorally: `MUT-OSERROR-IGNOREE` mutant (fail-open on OSError) is killed by the test suite — see spot-check below. |
| 5 | F3 docstring fix: "absent" (code 3, nominal silence) distinguished from "symlink/non-dir/unreadable" (code 2) | ✓ VERIFIED | `_lecture_detecteur_fidele` docstring (lines 447-450): "Liste vide et `fidele=True` si `<planning_abs>/workstreams/` est absent (SILENCE, code 3 ... état NOMINAL), en lien symbolique, ou non-répertoire (ces deux derniers cas sont DÉJÀ fermés par le détecteur lui-même, code 2 ...)". |
| 6 | Generic test loop over 4 elements × degraded permissions 000/600/400: masking → refusal (rc=3, cites lot 7 guard, fingerprint unchanged); non-masking (owner-readable 600/400) → verdict unchanged, guard never fires; explicit skip only under UID 0 | ✓ VERIFIED | Verifier is UID 501 (not root) — confirmed via `id -u`. Full suite re-run (independently, twice) shows `R-LECTURE-FIDELE [...]` PASS lines for workstreams-dir/compartiment-dir/compartiment-state/root-state × 000/600/400, including explicit "TÉMOIN non masquant" assertions for 600/400 file cases. |
| 7 | Nominal multi-workstream lab (several compartments, no GSD marker) keeps prior write behavior; a single unreadable compartment among several is enough to refuse (never an average) | ✓ VERIFIED | `R-LECTURE-FIDELE-MULTI-NOMINAL` and `R-LECTURE-FIDELE-MULTI-UN-ILLISIBLE` both present in re-run output: "code de sortie 0 (trois compartiments réels, aucun marqueur — écriture inchangée)" and "refus malgré deux compartiments lisibles sur trois". |
| 8 | `test-recalc-planning.sh` reaches 303 OK / 0 KO (285 before this lot, +18), 0 surviving mutant; `MUT-LECTURE-FIDELE-PERM` and `MUT-OSERROR-IGNOREE` killed for the exact measured reason | ✓ VERIFIED | Independently re-run twice: `== Résultat : 303 OK · 0 KO ==` both times. `✓ MUT-LECTURE-FIDELE-PERM TUÉ — ... écriture silencieuse sur un compartiment chmod 000 réellement tenu par GSD ...` and `✓ MUT-OSERROR-IGNOREE TUÉ — ... écriture silencieuse — le détecteur réel ... retombe sur code 3 ...` both present verbatim in output. |
| 9 | No out-of-scope regression: `detect-gsd-engine.sh`/`workstream-policy.sh` byte-identical since 424cb23; 8 sibling suites under `plugin/planning-core/scripts/tests/` unchanged and green | ✓ VERIFIED | `git diff --stat 424cb23..HEAD -- .../detect-gsd-engine.sh .../workstream-policy.sh` → empty. All 8 sibling suites independently re-run: `19 ok/0 ko`, `26 ok/0 ko`, `10 passés/0 échoués`, `38 passés/0 échoués`, `14 passés/0 échoués`, `42 PASS/0 FAIL`, `22 ok/0 ko/0 skip`, `10 ok/0 ko` — exact match to SUMMARY.md claim. |
| 10 | `modele-cycles.md` + CHANGELOG (Lot 7 paragraph under existing `[v2.8.0]`, no version bump) document the principle/finding/limitation; `.planning/BACKLOG.md` carries a new entry for Samuel about `found=1` on `cd` failure | ✓ VERIFIED | `grep "Garde de lecture du détecteur"` → present at modele-cycles.md:137, includes explicit "Limite assumée" paragraph on the local-residue caveat. `grep "Lot 7 (correction de CLASSE...)"` → present at CHANGELOG.md:130 under the existing `[v2.8.0]` header (no new `## [` header added). `VERSION` file still reads `v2.8.0`. BACKLOG.md tail contains "Pour Samuel — `vf_ws_enumerate` pose `found=1` même quand `cd` échoue" section with root-cause detail and owner/trigger. |

**Score:** 10/10 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `plugin/planning-core/scripts/recalc-planning.sh` | `_ouvrable`, `_executer_vf_ws_enumerate`, `_lecture_detecteur_fidele` replacing `_enumeration_workstreams_fidele`, called before `subprocess.run` in `detection_gsd()` | ✓ VERIFIED | All three functions present (lines 397, 418, 444); old function name absent; call site at line 610, before `subprocess.run` at line 630; `env_maitrise`/`bash_bin` resolved at lines 586/603, before the guard call. |
| `plugin/planning-core/scripts/tests/test-recalc-planning.sh` | `R-LECTURE-FIDELE` generic loop, `R-LECTURE-FIDELE-MULTI-NOMINAL`, `R-LECTURE-FIDELE-MULTI-UN-ILLISIBLE`, `MUT-LECTURE-FIDELE-PERM`, `MUT-OSERROR-IGNOREE` | ✓ VERIFIED | All present in suite output, all passing/killed as claimed. |
| `plugin/planning-core/references/modele-cycles.md` | "Garde de lecture du détecteur (P44-D-02a, lot 7, correction de CLASSE)" paragraph | ✓ VERIFIED | Present at line 137, full principle + measured finding + assumed limitation. |
| `plugin/planning-core/CHANGELOG.md` | Lot 7 entry under `[v2.8.0]` | ✓ VERIFIED | Present at line 130; `VERSION` file unchanged at v2.8.0 (no bump, as required). |
| `.planning/BACKLOG.md` | Entry for Samuel on `found=1` despite `cd` failure | ✓ VERIFIED | Present at file tail, with root-cause quote, owner (Samuel, Phase 41.1), and resume trigger. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `detection_gsd()` | `_lecture_detecteur_fidele()` | Direct call before `subprocess.run`; non-fidèle → `"non-concluante"` without invoking the detector; `bash_bin`/`env_maitrise` resolved before this call | ✓ WIRED | Confirmed at lines 603-621: `env_maitrise`/`bash_bin` built first, `_lecture_detecteur_fidele` called at line 610, `if not fidele: ... return "non-concluante"` at lines 613-621, real detector `subprocess.run` only reached afterward (line 630). |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full `test-recalc-planning.sh` reaches 303/0 | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` (run once, independently) | `== Résultat : 303 OK · 0 KO ==`, `MUT-LECTURE-FIDELE-PERM TUÉ`, `MUT-OSERROR-IGNOREE TUÉ` | ✓ PASS |
| `detect-gsd-engine.sh`/`workstream-policy.sh` byte-identical since 424cb23 | `git diff --stat 424cb23..HEAD -- plugin/planning-core/scripts/detect-gsd-engine.sh plugin/planning-core/scripts/workstream-policy.sh` | empty output | ✓ PASS |
| 8 sibling suites unaffected | individually ran each of the 8 `test-*.sh` files | 19/0, 26/0, 10/0, 38/0, 14/0, 42/0, 22/0/0skip, 10/0 — identical to SUMMARY.md's claimed counts | ✓ PASS |
| Embedded Python engine parses under Python 3.9 feature-set (PY39 probe) | extracted heredoc body (lines 68-1857) and ran `ast.parse(src, feature_version=(3,9))` independently | `PY39-OK` | ✓ PASS |
| Only the 5 declared files changed since prior commit | `git diff --stat 707be8d..HEAD` | exactly `.planning/BACKLOG.md`, `CHANGELOG.md`, `modele-cycles.md`, `recalc-planning.sh`, `test-recalc-planning.sh` | ✓ PASS |
| `check-version-sync.sh` green | `bash scripts/check-version-sync.sh` | `✓ sources synchronisées (v2.66.0, 17 modules)` | ✓ PASS |
| `check-gate-touche.sh` green | `bash scripts/check-gate-touche.sh` | `RIEN-A-JUGER: aucun chemin de la surface surveillee n'est touche` | ✓ PASS |
| `check-machine-paths.sh` green | `bash scripts/check-machine-paths.sh` | `✓ 1702 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` | ✓ PASS |
| `check-planning-consumers-registered.sh` green | `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` | `✓ ... 21 consommateur(s) détecté(s), tous recensés` | ✓ PASS |

Note on `CONTRAT-CROISE-OK 42 / 42`: this probe is described in SUMMARY.md as an ad-hoc executor
check with no committed script under version control (`grep -rn "CONTRAT-CROISE"` across
`plugin/planning-core/` returns no hits). Not independently reproducible by the verifier as a
named command; not treated as a gap since it is not a `must_haves` artifact/truth in the PLAN
frontmatter, and the PY39 probe (which the plan lists alongside it) was independently reproduced
and passed.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| MOTR-02 | 260928-s53-PLAN.md | Altitude lab served to dev labs too | ✓ SATISFIED (pre-existing) | Already marked Complete in `.planning/workstreams/gouvernance/REQUIREMENTS.md` under Phase 44 (267b041); this lot does not touch the mechanism it covers and does not regress it (no changes to `detect-gsd-engine.sh`/`workstream-policy.sh`, sibling suites green). |
| MOTR-04 | 260928-s53-PLAN.md | Read-only mode | ✓ SATISFIED (pre-existing) | Same as above; `--read-only` path untouched by this lot's diff (guard only applies inside `detection_gsd()`, called regardless of read-only, but no read-only-specific regression found in test suite). |
| MOTR-11 | 260928-s53-PLAN.md | `cloture.log` append-only | ✓ SATISFIED (pre-existing) | Unaffected by this lot; sibling test coverage (`R-DEDOUBLONNAGE-ASSAINI`, `R-INJECTIF-ROUNDTRIP`) still green in the re-run. |
| MOTR-12 | 260928-s53-PLAN.md | Python 3.9+, stdlib only | ✓ SATISFIED | Independently confirmed via PY39 AST probe on the full embedded engine body post-lot-7. |
| MOTR-16 | 260928-s53-PLAN.md | Bash test suites + mutation testing | ✓ SATISFIED | New mutants `MUT-LECTURE-FIDELE-PERM`/`MUT-OSERROR-IGNOREE` both independently confirmed killed. |
| MOTR-18 | 260928-s53-PLAN.md | `plugin/planning-core` minor version bump | ✓ SATISFIED (pre-existing, not by this lot) | This lot explicitly does NOT bump the version (v2.8.0 unchanged) — the minor bump for the new capability happened earlier in Phase 44 (already recorded); this lot is documented as a correction/fix riding under the same `[v2.8.0]` entry, consistent with CLAUDE.md's "une release seulement pour une évolution fonctionnelle" doctrine (no new functional capability here, a correctness fix). |

No orphaned requirements found for this quick task's declared scope.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | none found | — | `grep -E "TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER"` across all 5 modified files returned only false positives (`\uXXXX`/`\UXXXXXXXX` unicode-escape notation in comments, and a `DEC-XXX` decision-ID pattern in CHANGELOG.md prose) — no real debt markers. |

### Human Verification Required

None. All must-haves are structural/behavioral claims fully exercised by the (independently
re-run) automated test suite and machine gates; no visual, real-time, or external-service
behavior is involved.

### Gaps Summary

None. Every must-have truth, artifact, and key link in the PLAN.md frontmatter was independently
reproduced against the actual codebase at commit `4b666e9`:

- The old lot-6 function is gone; the new guard exists, is wired before the detector subprocess
  call, and refuses without invoking the detector when reading fails.
- `detect-gsd-engine.sh` and `workstream-policy.sh` are provably byte-identical since `424cb23`.
- The full test suite (303/0) and all 8 sibling suites were re-run independently by the verifier
  (not copied from SUMMARY.md) and matched the claimed counts exactly, including the two named
  mutants (`MUT-LECTURE-FIDELE-PERM`, `MUT-OSERROR-IGNOREE`) both killed for the specific measured
  defect.
- The verifier ran under a non-root UID, so the permission-based (000/600/400) test cases
  exercised real filesystem behavior rather than being skipped.
- Documentation (modele-cycles.md, CHANGELOG.md, BACKLOG.md) and the absence of a version bump
  were all independently confirmed.
- Four machine gates (`check-version-sync.sh`, `check-gate-touche.sh`, `check-machine-paths.sh`,
  `check-planning-consumers-registered.sh`) were re-run and are green.

One minor note (not a gap): the `CONTRAT-CROISE-OK 42/42` probe mentioned in the plan's
verification section has no committed script and could not be independently reproduced by name;
it is not part of the PLAN's `must_haves` frontmatter and does not affect the phase-goal
determination.

---

_Verified: 2026-09-28T21:15:00Z_
_Verifier: Claude (gsd-verifier)_
