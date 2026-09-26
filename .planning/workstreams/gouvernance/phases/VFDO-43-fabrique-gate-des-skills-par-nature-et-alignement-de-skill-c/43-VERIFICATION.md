---
phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c
verified: 2026-09-26T00:00:00Z
status: passed
score: 10/10 must-haves verified
covered_files: [".planning/instruction-budget-baselines.tsv", ".planning/workstreams/gouvernance/REQUIREMENTS.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-01-PLAN.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-01-SUMMARY.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-02-PLAN.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-02-SUMMARY.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-03-PLAN.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-03-SUMMARY.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-04-PLAN.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-04-SUMMARY.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-05-PLAN.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-05-SUMMARY.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-06-PLAN.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-06-SUMMARY.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-07-PLAN.md", ".planning/workstreams/gouvernance/phases/VFDO-43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-c/43-07-SUMMARY.md", "docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md", "plugin/_internal/tests/test-vibeflow-update.sh", "plugin/_internal/vibeflow-update.sh", "plugin/conductor/CHANGELOG.md", "plugin/conductor/README.md", "plugin/conductor/VERSION", "plugin/conductor/module.json", "plugin/conductor/scripts/check-agents-manifest.json", "plugin/conductor/scripts/check-agents.sh", "plugin/conductor/scripts/check-instruction-budget.sh", "plugin/conductor/scripts/check-skills.sh", "plugin/conductor/scripts/tests/test-check-agents.sh", "plugin/conductor/scripts/tests/test-check-instruction-budget.sh", "plugin/conductor/scripts/tests/test-check-skills.sh", "plugin/conductor/skills/vf-calibrate/SKILL.md", "plugin/dev-orchestrator/CHANGELOG.md", "plugin/dev-orchestrator/README.md", "plugin/dev-orchestrator/VERSION", "plugin/dev-orchestrator/module.json", "plugin/dev-orchestrator/scripts/inject-mcp-tools.sh", "plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh", "plugin/skill-creator/CHANGELOG.md", "plugin/skill-creator/README.md", "plugin/skill-creator/VERSION", "plugin/skill-creator/module.json", "plugin/skill-creator/skills/skill-creator-workflow/SKILL.md", "plugin/skill-creator/skills/skill-creator/SKILL.md"]
covered_digest: "v1:sha256:709f7352f72d1acdd22bb3e4a44b60b60ae8e1fc10b750b2dfefc637118c601e"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator Verification Report

**Phase Goal:** Chaque skill déclare sa nature (`vf-nature: referentiel | outil | procedure`, défaut
« outil ») ; une procédure sans `ecrit:` ni rubrique de juge est refusée ; la dérive de forme
procédurale non déclarée est détectée ; `skill-creator` demande la nature ; les deux déclarations
MCP (`vf-mcp-consumer` / `vf-mcp-tools`) sont conservées comme réponses à deux besoins distincts
(décision 1 d'ADR-051), la spec fabrique §1.2/§7.2 est amendée en ce sens et le mécanisme conservé
est durci (grammaire de `vf-mcp-tools` validée, serveur nommé absent signalé, textes à une seule clé
corrigés). Les trois marqueurs de détection de dérive forment un contrat unique, posé tel quel par
l'initialisation en questions factuelles (C-15), sans redéfinir la nature.

**Verified:** 2026-09-26
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `check-skills.sh` découvre récursivement le corpus (21 SKILL.md, 4 exclus doc-only), refuse une `procedure` sans `ecrit:`/`vf-rubrique-juge`, défaut « outil » jamais silencieux sur une valeur invalide | ✓ VERIFIED | `test-check-skills.sh` T1–T21 green (74 OK/0 KO, see full run below); real-tree check `T4`/`T32` confirm 21 found = 21 judged |
| 2 | Manifeste daté étendu à une septième liste `champs_frontmatter_skills`, validée identiquement par `check-agents.sh` et `check-skills.sh` (contrat FABR-09 « même manifeste ») | ✓ VERIFIED | `check-agents-manifest.json` has 7 keys incl. `champs_frontmatter_skills`; `test-check-agents.sh` T107 green |
| 3 | La dérive de forme procédurale non déclarée (un marqueur en titre, ou ≥2 marqueurs distincts en prose) est détectée dans les deux sens, en avertissement seul (jamais un refus) | ✓ VERIFIED | `test-check-skills.sh` T22–T32 (T26a-h) green incl. MUT-DR1/DR2/DR3 killed with trace; corpus real measure `[T32] modules jugés=15 · avertissements=26` |
| 4 | `skill-creator` (moteur interne ET workflow templaté) pose la question `vf-nature` en étape distincte de « Évaluer la nature du sujet », défaut « outil », jamais fixé d'office | ✓ VERIFIED | grep confirms both SKILL.md files (l.55/72 engine, l.52/57/208 workflow); moteur interne 493 lignes (≤500 plafond) |
| 5 | Les deux déclarations MCP (`vf-mcp-consumer`/`vf-mcp-tools`) sont conservées comme réponses à deux besoins distincts, jamais fusionnées | ✓ VERIFIED | spec fabrique §1.2 amended (« Deux déclarations MCP, deux besoins distincts »); real corpus grep: 4 agents `vf-mcp-consumer: true`, `vf-reviewer.md` sole `vf-mcp-tools` consumer |
| 6 | La grammaire `vf-mcp-tools` est validée à l'identique par le gate (`check-agents.sh`) et l'injecteur (`inject-mcp-tools.sh`), une valeur malformée refusée (rc 1), jamais un no-op silencieux | ✓ VERIFIED | `test-check-agents.sh` T108-T115 green (200 OK/0 KO); `test-inject-mcp-tools.sh` T22e-j green (47 OK/0 KO) |
| 7 | Un serveur nommé par `vf-mcp-tools` et absent de l'union des scopes (projet ∪ global) est signalé par une ligne WARNING, relayée jusqu'au journal d'installation (plus un no-op silencieux) — sauf union totalement vide, cas explicitement hors périmètre (documenté en 43-05-PLAN.md) | ✓ VERIFIED | reproduced live: fresh lab with `.mcp.json` containing one dummy server shows `WARNING: vf-reviewer.md : serveur MCP XcodeBuildMCP … inconnu de union …` relayed by `vibeflow-update.sh` install log |
| 8 | Les textes à une seule clé MCP (`vibeflow-update.sh` ×3, `vf-calibrate/SKILL.md`) nomment désormais aussi `vf-mcp-tools` | ✓ VERIFIED | grep confirms all 4 sites now mention both keys |
| 9 | `check-instruction-budget.sh` plafonne les SKILL.md à 500 lignes et fait de la hausse du socle du bootstrap au-dessus de `@bootstrap:socle` un blocage (rc 1 sous ratchet armé), plafond ADR-029 de 2000 restant un objectif non bloquant | ✓ VERIFIED | live run on real repo: `BILAN-SKILLS : 21 SKILL.md, 0 depassement(s)…`, `BOOTSTRAP : 2499 tokens … verdict AU-DESSUS-PLAFOND-ADR029`, rc=0; `test-check-instruction-budget.sh` SKILL-1..6/BOOT-1..5/MUT-8..12 green (64 OK/0 KO) |
| 10 | Les trois marqueurs de dérive forment un contrat unique, réutilisé tel quel par l'initialisation (C-15) sans redéfinir la nature | ✓ VERIFIED | `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` §5.2/C-15 already references the same three markers (pre-existing source, cited not modified by this phase) |

**Score:** 10/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `plugin/conductor/scripts/check-skills.sh` | new gate (FABR-06) | ✓ VERIFIED | executable, 34850 bytes, `decouvrir_skills`, `invariant_procedure`, `detecter_derive`, `ecart_nature_marqueurs` all present and wired |
| `plugin/conductor/scripts/tests/test-check-skills.sh` | T1–T32 + mutants | ✓ VERIFIED | ran live: 74 OK · 0 KO |
| `plugin/conductor/scripts/check-agents-manifest.json` | 7th list | ✓ VERIFIED | 7 keys incl. `champs_frontmatter_skills` |
| `plugin/conductor/scripts/check-agents.sh` | widened to 7 lists, `valider_mcp_tools` | ✓ VERIFIED | ran live: 200 OK · 0 KO (incl. T107–T115) |
| `plugin/conductor/scripts/check-instruction-budget.sh` | SKILL.md cap + bootstrap ratchet | ✓ VERIFIED | ran live: 64 OK · 0 KO; real-repo run rc=0 |
| `.planning/instruction-budget-baselines.tsv` | `@bootstrap:socle` line | ✓ VERIFIED | `@bootstrap:socle	0	2499` present, cited decision |
| `plugin/skill-creator/skills/skill-creator/SKILL.md` | vf-nature question | ✓ VERIFIED | 493 lines (≤500), question present, distinct step |
| `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` | vf-nature question | ✓ VERIFIED | 312 lines, distinct step from "Evaluer la nature du sujet" |
| `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` | malformed refusal + absent-server WARNING | ✓ VERIFIED | ran live: 47 OK · 0 KO; live WARNING reproduced on fresh lab |
| `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` | §1.2/§7.2 amended | ✓ VERIFIED | "Deux déclarations MCP, deux besoins distincts" present, 4-agent count matches real corpus |
| `plugin/conductor/skills/vf-calibrate/SKILL.md` | last single-key MCP text corrected | ✓ VERIFIED | l.92-93 now names both `vf-mcp-consumer` and `vf-mcp-tools` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `check-skills.sh` (`charger_manifeste`) | `check-agents-manifest.json` | 7-list validation | ✓ WIRED | `MANIFESTE-ILLISIBLE` on amputated manifest (T5/T107) |
| `check_file()` | `invariant_procedure()`/`valider_nature()`/`valider_ecrit()` | single `errors.extend(...)` calls | ✓ WIRED | `grep -c` each returns 1; MUT-S1/S2/S3 killed |
| `check_file()` | `detecter_derive()`/`ecart_nature_marqueurs()` | single `warnings.extend(...)` calls, never `errors` | ✓ WIRED | `grep -c 'errors.extend(detecter_derive('` = 0; MUT-DR1/DR2/DR3 killed with trace |
| `valider_mcp_tools()` (check-agents.sh) | `named_request()` (inject-mcp-tools.sh) | identical extraction rule | ✓ WIRED | T22e-j / T110-T115 render identical verdicts across both scripts |
| `inject_lab_mcp_into_agents()` (vibeflow-update.sh) | WARNING/ERROR lines of inject-mcp-tools.sh | stderr relayed to install journal | ✓ WIRED | reproduced live on fresh lab with dummy `.mcp.json` server |
| Installeur (module conductor) | `.claude/scripts/check-skills.sh` + manifest | fresh-lab witness | ✓ WIRED | reproduced live: `TRACER-SKILLS-OK` |

### Behavioral Spot-Checks / Live Test Runs

| Suite / Check | Command | Result | Status |
|---------------|---------|--------|--------|
| test-check-skills.sh | `bash plugin/conductor/scripts/tests/test-check-skills.sh` | 74 OK · 0 KO | ✓ PASS |
| test-check-agents.sh | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | 200 OK · 0 KO | ✓ PASS |
| test-inject-mcp-tools.sh | `bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` | 47 OK · 0 KO | ✓ PASS |
| test-check-instruction-budget.sh | `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` | 64 OK · 0 KO | ✓ PASS |
| Real corpus (check-skills.sh) | 15 non-doc-only module dirs, `--strict` | fail=0 | ✓ PASS |
| Real corpus (check-agents.sh, CI-equivalent glob `plugin/*/agents` + `plugin/*/AGENT.md`) | per-module `--strict --manifest-freshness=strict` | 6+6 found, 0 fail | ✓ PASS |
| check-instruction-budget.sh (real repo) | `bash plugin/conductor/scripts/check-instruction-budget.sh` | rc=0, `BILAN-SKILLS: 0 depassement`, `BOOTSTRAP: … AU-DESSUS-PLAFOND-ADR029` (non-blocking) | ✓ PASS |
| check-version-sync.sh | `bash scripts/check-version-sync.sh` | rc=0, v2.66.0, 17 modules, 90 suites | ✓ PASS |
| check-blueprints.sh | `bash plugin/conductor/scripts/check-blueprints.sh` | rc=0, 9 blueprints conformes | ✓ PASS |
| G-1 check-baseline-arbitrage.sh | `bash scripts/check-baseline-arbitrage.sh` | `CONFORME`, rc=0 | ✓ PASS |
| G-2 check-gate-touche.sh | `bash scripts/check-gate-touche.sh` | `DECLARE`, marqueurs 38/38, rc=0 | ✓ PASS |
| Fresh lab (conductor deps) | installer conductor into empty HOME/git dir | `TRACER-SKILLS-OK` | ✓ PASS |
| Fresh lab (dev-orchestrator deps, dummy `.mcp.json`) | installer + grep journal | `WARNING: … XcodeBuildMCP … inconnu de union …` relayed | ✓ PASS |
| Root VERSION/marketplace untouched | `git diff B43 HEAD -- VERSION .claude-plugin/marketplace.json plugin/.claude-plugin/plugin.json` | empty diff | ✓ PASS |
| `.github/` untouched | `git diff --name-only B43 HEAD -- .github/` | 0 files | ✓ PASS |
| No upstream merges in range | custom rev-list/parents walk | `MERGES-DANS-LA-PLAGE 0` | ✓ PASS |
| Base de phase (B43) ownership | single commit, exact subject, sole file, parent = B43 | confirmed via `git log --diff-filter=A` and `git rev-parse <commit>^` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|-------------|--------|----------|
| FABR-06 | 43-01 | `check-skills.sh` gate: nature, `ecrit:`/`vf-rubrique-juge` required for `procedure` | ✓ SATISFIED | T1-T21 green, corpus real T4 green |
| FABR-07 | 43-02 | Dérive procédurale non déclarée détectée en avertissement, deux sens | ✓ SATISFIED | T22-T32 green, corpus mesuré (26 avertissements/11 SKILL.md) |
| FABR-08 | 43-03 | `skill-creator` (moteur + workflow) demande `vf-nature` | ✓ SATISFIED | grep confirms both files, distinct step, ≤500 lines |
| FABR-09 | 43-01, 43-04, 43-06 | Manifeste 7 listes; plafond SKILL.md 500 lignes; ratchet bootstrap `@bootstrap:socle` | ✓ SATISFIED | live runs rc=0 on real repo, baseline TSV present, README/CHANGELOG document all three gates |
| FABR-10 | 43-05, 43-06, 43-07 | Spec amendée, grammaire `vf-mcp-tools` durcie, serveur absent signalé, textes à deux clés | ✓ SATISFIED | spec amended, 200/47 OK test suites, live WARNING reproduced, all 4 single-key sites corrected |

REQUIREMENTS.md still lists FABR-06..10 as "Pending" — this is expected: per the mandate for this
verification run, `requirements.mark-complete` and STATE/ROADMAP updates are out of scope for the
verifier (orchestrator applies them after this report is accepted).

No orphaned requirements found (Phase 43 mapping in REQUIREMENTS.md matches exactly the 5 IDs
declared across the 7 plans' frontmatter).

### Anti-Patterns Found

None. Scanned all key implementation files (`check-skills.sh`, `check-agents.sh`,
`check-instruction-budget.sh`, `inject-mcp-tools.sh`, both skill-creator `SKILL.md`,
`vf-calibrate/SKILL.md`, the amended spec) for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`.
The only matches (`DEC-XXX` in `skill-creator-workflow/SKILL.md` l.292/296) are intentional
template placeholder text for skill authors to replace with their own decision-record ID, not an
unresolved debt marker in the delivered code.

### Human Verification Required

None. All must-haves resolve to concrete, live-reproduced evidence (test suites, real-repo gate
runs, fresh-lab witnesses, git history checks) rather than static presence alone.

### Gaps Summary

No gaps. One area investigated closely and found to be an intentional, documented design boundary
rather than a defect: `inject-mcp-tools.sh` only emits the "named server absent" WARNING when the
union of resolved MCP scopes (project ∪ global) is non-empty; a totally empty union (no MCP server
configured anywhere) short-circuits to a silent no-op. This is explicitly called out in
`43-05-PLAN.md` ("Union vide … : l'injecteur garde son no-op journalisé existant … ce n'est pas un
cas (b) — un lab sans MCP n'est pas en faute.") and does not contradict the must-have truth ("rc 0
par défaut (un lab sans serveur Xcode reste sain)"). Reproduced both branches live: empty union →
silent no-op; non-empty union with the named server absent → WARNING relayed to the install
journal, matching the plan's own witness setup (`.mcp.json` with a dummy `mobile-mcp` entry).

---
*Verified: 2026-09-26*
*Verifier: Claude (gsd-verifier)*
