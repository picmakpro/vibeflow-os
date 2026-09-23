# Phase 40: vibeflow-head — head of minds du dev-orchestrator - Pattern Map

**Mapped:** 2026-09-15
**Files analyzed:** 23 (3 new, 7 structurally modified, 13 rename-only)
**Analogs found:** 23 / 23 (all tracked source, `git ls-files` verified — no gitignored mirror in the mix)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/dev-orchestrator/scripts/check-mission-exit.sh` (NEW) | utility (gate script) | batch, read-only verification | `plugin/conductor/scripts/check-mission-invariants.sh` | exact |
| `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh` (NEW) | test | batch (fixture-driven assertions) | `plugin/conductor/scripts/tests/test-check-mission-invariants.sh` | exact |
| `plugin/dev-orchestrator/references/head-governance.md` (NEW) | config/doc (on-demand reference) | transform (doctrine, no runtime behavior) | `plugin/dev-orchestrator/references/mission-flow.md` (structure) + `mission-contracts.md` (contract-table style) | role-match |
| `plugin/dev-orchestrator/AGENT.md` | controller/agent (conversational router) | request-response | itself (prior revision) — renvoi pattern borrowed from `vf-dev-manager.md`→`mission-flow.md` | self / role-match |
| `plugin/dev-orchestrator/references/mission-contracts.md` | config/doc (contract) | transform | itself, §Contrat `estimate:`/`actuals:` (lines 151-186) as the direct precedent for E6 | exact (self-precedent) |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` | controller/agent (team manager) | event-driven (mission dispatch/report) | itself, §Rapport de mission + lock-release (lines 243-250) | exact (self-precedent) |
| `plugin/dev-orchestrator/references/_index.md` | config (static index) | CRUD (append one row) | itself, existing 10-row table | exact |
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | test | batch (grep-based structural assertions) | itself, T13 "façade morte" block (lines 1577-1602) + `$GREP`/`deleted_hits()` helpers (lines 155, 234-244) | exact (self-precedent, extended scope) |
| `plugin/conductor/scripts/check-overlaps.sh` | config data (KNOWN_PAIRS heredoc) + utility | transform | itself, line 67 (`vibeflow-dev\|gsd-next` entry) | exact |
| `plugin/conductor/scripts/tests/test-check-overlaps.sh` | test | batch | itself, T15/T16 (lines 186-210) | exact |
| `plugin/dev-orchestrator/skills/vf-dev/SKILL.md` | config (skill descriptor) | request-response (incarnation target) | itself (lines 3, 8) | exact |
| `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` | config (skill descriptor) | request-response | itself (lines 19, 28-34, `SEUIL_EQUIPE` block) — no `vibeflow-dev` string found, only a citation to add | n/a (discretionary addition, not a rename) |
| `plugin/dev-orchestrator/references/GSD-PIPELINE.md` | doc (reference) | n/a (string rename) | mention pattern shared with `docs-flow.md`/`ingestion-flow.md` | role-match |
| `plugin/dev-orchestrator/references/docs-flow.md` | doc (reference) | n/a | same header-mention pattern | role-match |
| `plugin/dev-orchestrator/references/ingestion-flow.md` | doc (reference) | n/a | same header-mention pattern | role-match |
| `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` | utility (comment only, l.6) | n/a | n/a — single comment-line rename | exact (trivial) |
| `plugin/design-orchestrator/AGENT.md` | agent (frontmatter description, l.3) | n/a | n/a — single string rename in prose | exact (trivial) |
| `plugin/planning-core/SKILL.md` | config (skill descriptor, l.3, l.81) | n/a | n/a — string rename in prose | exact (trivial) |
| `plugin/planning-core/references/gsd-handoff.md` | doc (reference, l.31/35/43) | n/a | n/a — **omitted from 40-CONTEXT.md canonical_refs, confirmed present by direct grep this session** (see Pitfall below) | exact (trivial, but must not be forgotten) |
| `plugin/commands/vf-planning.md` | command doc (l.15, l.18) | n/a | n/a — string rename | exact (trivial) |
| `plugin/software-architecture/rules/doc-research-before-debug.md` | rule doc (l.24, l.88) | n/a | n/a — string rename | exact (trivial) |
| `README.md` / `README.fr.md` | doc (root, l.46 each) | n/a | n/a — string rename | exact (trivial) |
| `plugin/dev-orchestrator/README.md` | doc (module) | n/a | itself — **6 occurrences found** (l.4, 22, 43, 74, 149, 306 — l.306 sits in a "Changelog" prose section of the README itself, not `CHANGELOG.md`) | exact, ⚠ see Pitfall below |
| `plugin/dev-orchestrator/module.json`, `VERSION`, `CHANGELOG.md` | config / doc | n/a | `module.json` description string rename + version bump (D-16); `CHANGELOG.md` gets a **new entry only**, prior entries never rewritten (explicit exemption) | exact |

## Pattern Assignments

### `plugin/dev-orchestrator/scripts/check-mission-exit.sh` (utility, batch/read-only verification)

**Analog:** `plugin/conductor/scripts/check-mission-invariants.sh` (172 lines, read intact this session — copy its skeleton verbatim, do not invent a new exit-code convention)

**Header/contract-doc pattern** (lines 1-56 of the analog): a long `#`-comment block stating role (FAIT vs JUGEMENT distinction, ADR-055 §3), source of truth, method, and the **exact exit-code contract** — `check-mission-exit.sh` must open with the same style, substituting E1-E6 for the invariants-specific checks:
```bash
#   3  = SAIN — ... C'est le SEUL code qui signifie « vérifié, conforme ».
#   4  = INDÉTERMINÉ — rien n'a été vérifié, pour l'une de ces raisons (diagnostic sur stderr,
#        sauf --quiet, précisant laquelle). Un exit 4 n'autorise JAMAIS à conclure que ... est à jour.
#   0  = au moins un manque nommé — signal [nom-du-gate] émis, une ligne par manque.
#   64 = argument inconnu, --path/--file sans valeur, ... ou fichier EXPLICITEMENT désigné illisible.
```

**Arg-parsing + hardening pattern** (lines 57-102, verbatim to reproduce):
```bash
set -uo pipefail
shopt -s nullglob

ROOT="."
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-mission-invariants] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-mission-invariants] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-mission-invariants] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

say() { [ "$QUIET" -eq 1 ] || echo "[check-mission-invariants] $*" >&2; }

export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() {
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}
```
Rename `[check-mission-invariants]` → `[check-mission-exit]` throughout (message prefix convention, one gate = one bracket tag).

**Core pattern — per-check detection + exit selection** (lines 104-172): read source of truth (here: `.planning/MISSION-INVARIANTS.md` §1 globs vs `git ls-files`), accumulate a `DEAD`/`GAPS` string, exit `3` if empty else `0` printing one line per gap prefixed `[tag] …`. `check-mission-exit.sh` reproduces this shape per E1-E6 sub-check but must also implement D-06 (no source of truth → global `4`) and D-07's four-way split — closer in that regard to the INDÉTERMINÉ branches at lines 110-124 (file unreadable → `4`, not-a-git-repo → `4`) than to any single-cause script.

**E1 (lock) — read via `jq`, never text-splitting** [source: `plugin/conductor/scripts/driver-lock.sh:322-347`, verified this session]:
```bash
# lock absent:
printf '{"present": false, "lock": "%s"}\n' "$LOCK_DIR"
# lock present (full record):
printf '{"present": true, "owner": "%s", "step": "%s", "age_seconds": %s, "ttl": %s, "stale": %s, "generation": "%s", "session_ids": %s, "lease_seconds": %s, "guard_effective": %s, "progress_epoch": %s, "progress_age_seconds": %s}\n' ...
```
Read pattern to reuse:
```bash
present="$("$S"/driver-lock.sh status | jq -r '.present')"   # E1 sain ⟺ present == "false"
```

**Script-sibling resolution — cascade `$S`, never a hardcoded path** [source: `plugin/dev-orchestrator/references/mission-flow.md:17-18`, verified]:
```bash
S="$( for d in "./.claude/scripts" "$HOME/.claude/scripts" "${CLAUDE_PLUGIN_ROOT:-}/conductor/scripts" "${CLAUDE_PLUGIN_ROOT:-}/dev-orchestrator/scripts"; do
        [ -f "$d/dag.sh" ] && { printf '%s' "$d"; break; }; done )"
```
Sentinel is `dag.sh`, not `driver-lock.sh` — keep the same sentinel for consistency with any other invocation in the same mandate (per mission-flow.md's own note). Local lab scope PRIMES (`./.claude/scripts` first) — never prefer the user scope by default.

**E2 (dirty tree) — rtk pitfall**: measure `git status --porcelain` directly, or explicitly `rtk proxy git status --porcelain` if the `rtk` hook is active — never `git status --porcelain | wc -l` under an active `rtk` hook (empty output becomes 1 line under rtk, per memory `rtk-fausse-les-verifications-d-etat.md`, Phase 18).

**Error handling**: same as analog — no `try/catch` (bash), every failure path is an explicit `exit <code>` with a `say`/`echo >&2` diagnostic; never a silent `3` default on an unexpected `jq`/git failure (Security Domain note in RESEARCH.md: a gate that defaults to green on tool failure is the anti-pattern).

---

### `plugin/dev-orchestrator/scripts/tests/test-check-mission-exit.sh` (test, batch)

**Analog:** `plugin/conductor/scripts/tests/test-check-mission-invariants.sh` (185 lines, read intact)

**Structure to copy**:
```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-mission-exit.sh"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
```
Fixtures built with `mktemp -d` + `git init -q -b main` (fallback `git init -q` for older git) — **never** on the real repo. Each case captures stdout AND `$?` into two separate variables, asserted separately.

**Mandatory case categories, mapped from the analog's 12 cases to HEAD-02's E1-E6 + D-06/D-07/D-08 contract:**
- one E-check failing (named gap) → signal line naming that check, exit `0` (mirrors analog Case 1)
- all E-checks passing → stdout empty, exit `3` (mirrors Case 2)
- no source of truth for one E-check (no `gh`, no remote, non-git root) → exit `4`, stderr diagnostic, **never** silently treated as pass (mirrors Cases 3/5/6, and directly implements D-06)
- **Case 5b-equivalent (mutation-red, QUAL-01 discriminant)**: prove `rc(sain) != rc(indéterminé)` — the exact discrimination-machine pattern already used once in this repo (lines 104-120 of the analog) is the template for the mandatory mutation-red proof this gate must ship with.
- malformed arguments (`--path` without value, unknown flag) → exit `64` (mirrors Cases 4/7/7b/7c/7d)
- `--help` → exit `0`, non-empty output (mirrors Case 8)
- read-only proof: `find "$D" | sort` identical before/after invocation, `.git` included (mirrors Case 9) — directly satisfies D-10 ("une lecture, pas une production").
- `bash -n "$SCRIPT"` syntax check (mirrors Case 11).

---

### `plugin/dev-orchestrator/references/head-governance.md` (NEW, config/doc)

**Analog (structure, not content):** `plugin/dev-orchestrator/references/mission-flow.md` (patterns lettered A-G, each a `##` section with a short "What/When" framing) and `mission-contracts.md` (contract tables + fenced-code examples for exact formats).

**Renvoi discipline (ADR-030) — pattern to copy from `vf-dev-manager.md` → `mission-flow.md`** [source: `plugin/dev-orchestrator/agents/vf-dev-manager.md:249-250`, verified]:
```
**Avant de rendre le rapport, relâche le verrou de driver** :
`"$S"/driver-lock.sh release --owner=<id>` (geste de clôture garanti, quel que soit l'issue).
```
i.e. the agent file states the rule in one line and cites the reference file for the full doctrine — `head-governance.md` is the target of that citation for the allocation-scale/sequencing/exit-governance/economy rules; `AGENT.md` must never re-explain them locally (same anti-pattern class as "Créer un second format de bloc typé pour E6").

**`_index.md` entry to add** [source: `plugin/dev-orchestrator/references/_index.md`, full file read, 21 lines]:
```
| [head-governance.md](head-governance.md) | <résumé> |
```
inserted alongside the 10 existing rows, alphabetically consistent with the table's current ordering (`GSD-PIPELINE.md` → `workstreams.md`).

---

### `plugin/dev-orchestrator/references/mission-contracts.md` — E6 + décompte (structural addition)

**Analog:** the file's own §Contrat `estimate:`/`actuals:` (lines 151-186) — explicitly named by RESEARCH.md as the direct template for E6, since it solves the identical problem (relay a proof produced upstream, never recompute it).

**Exact 3 non-negotiable rules to mirror** [source: lines 154-158, verified]:
```
- «confidence» est DÉRIVÉE du nombre d'échantillons, jamais auto-évaluée
- Même échelle des deux côtés : «actuals.tokens» se mesure en chars/4 sur les fichiers
  réellement changés, jamais un compteur du harness
- Aucun arrondi flatteur
```
For E6 the equivalent non-negotiable is: a verdict without a replayable command is `preuve: amont` and is **never replayed** (D-05) — never invent a command for a hook-relayed verdict.

**Field-addition pattern** [source: lines 171-176]:
```
"estimate": { "tokens": …, "raw_tokens": …, "tasks": …, "confidence": "low|med|high" },
"actuals":  { "tokens": …, "tasks": …, "commits": … }
```
E6 follows the same shape as two **optional sibling fields** of `statut`/`findings`/`noeuds_debloques` in Pattern C (`mission-flow.md:220-228`) — proposed field per Open Question 1 of RESEARCH.md:
```json
"preuves": [
  { "verdict": "recette|revue|audit|gate:<nom>", "commande": "…", "exit_code": N, "sha": "…" }
]
```
with `"preuve": "amont"` replacing the triplet for a verbatim-relayed GSD engine hook.

**Rapport de mission gabarit — 3 lines to add** [source: lines 300-313, verified verbatim]:
```
RAPPORT DE MISSION
- Verdict global : ✅ | partiel | bloqué
- Par sprint : fait / verdicts (recette, revue, audit + hooks moteur relayés verbatim) / commits (SHA)
- Calibration (si portée) : estimate vs actuals par sprint — recopiés verbatim, jamais recalculés
- Décisions prises en autonomie (et par quel panel)
- Blocages & points nécessitant l'utilisateur
- Décompte (si bloqué) : tours consommés par boucle + findings non résolus — recopié verbatim, jamais recalculé
- Rapport détaillé : <chemin du fichier écrit sur disque>
```
D-13's three new lines ("Décompte (mission) : N minds dispatchés / N tours consommés / N gates rejoués (E6)") are added **at the same nesting level** as the existing "Décompte (si bloqué)" line — same bullet style, same "recopié verbatim, jamais recalculé" qualifier.

---

### `plugin/dev-orchestrator/agents/vf-dev-manager.md` — E6 relay + rename (structural + trivial)

**Analog:** itself, §Rapport de mission (lines 243-250, verified) — the relay-discipline paragraph is the direct template for how E6 gets worded:
```
**Calibration `estimate:`/`actuals:`** (contrat : `mission-contracts.md` §Contrat
`estimate:`/`actuals:`) : quand le bloc typé d'un `vf-coder` porte `estimate`/`actuals`, relaie-les
**verbatim** dans la ligne « Calibration » du gabarit — simple concaténation par sprint, jamais un
recalcul ni une statistique agrégée de ton cru. **Même règle pour `verdicts`** ...
```
Add an equivalent "**Preuves E6**" paragraph, same phrasing register, immediately before or after the calibration paragraph.

**Lock-release anchor point (D-11 depends on this exact location)** [source: line 249-250]:
```
**Avant de rendre le rapport, relâche le verrou de driver** :
`"$S"/driver-lock.sh release --owner=<id>` (geste de clôture garanti, quel que soit l'issue).
```
Do not move this line — E1 of the gate assumes release happens here, right before the report.

**Trivial rename** [source: line 3, verified]: `Dispatché par l'agent vibeflow-dev (proposition acceptée) ou par vf-auto (mission déclenchée) — jamais l'inverse.` → replace `vibeflow-dev` with `vibeflow-head`.

---

### `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — rename target + anti-alias test (structural)

**Trivial rename** [source: line 1298, verified — matches 40-CONTEXT.md's cited "l.1297-1298"]:
```bash
# vf-dev = incarnation de l'agent vibeflow-dev → cible agent acceptée.
if "$GREP" -Eq 'vibeflow-dev|vf-dev-manager' "$skill_md"; then
```
→ `vibeflow-dev` becomes `vibeflow-head` in both the comment and the regex alternation.

**Closest existing precedent for the anti-alias/mutation-red pattern (partial match, no exact prior art in this repo — see "No Analog Found" below):** T13 "façade est morte" block [source: lines 1577-1602, verified]:
```bash
t13_ok=1
[ ! -f "$REFS_DIR/vocabulary-map.md" ] || { ko "T13 façade : vocabulary-map.md existe encore ($REFS_DIR)"; t13_ok=0; }
[ ! -f "$MOD/rules/vf-verb-precedence.md" ] || { ko "T13 façade : rules/vf-verb-precedence.md existe encore"; t13_ok=0; }
for v in $DELETED_VERBS; do
  [ ! -d "$MOD/skills/$v" ] || { ko "T13 façade : skills/$v/ existe encore (verbe supprimé)"; t13_ok=0; }
done
t13_files="$AGENT_FILE"
for a in $TEAM_AGENTS; do [ -f "$MOD/agents/$a.md" ] && t13_files="$t13_files $MOD/agents/$a.md"; done
for r in "$REFS_DIR"/*.md; do [ -f "$r" ] && t13_files="$t13_files $r"; done
for f in $t13_files; do
  hits="$(deleted_hits "$f")"
  [ -z "$hits" ] || { ko "T13 façade : $(basename "$f") référence un verbe supprimé — $hits"; t13_ok=0; }
done
```
This is **bounded to a curated file list** (`t13_files`), not a repo-wide recursive grep. The new anti-alias test must widen scope to `find plugin -type f` (excluding `CHANGELOG.md`) — no existing test in this repo does that yet, so this part is genuinely new construction, only the **helper style** (`$GREP` forced to system binary, word-boundary regex, `ko`/`ok` accumulation) is copied.

**`$GREP` system-binary convention (avoid zsh/rtk grep aliasing)** [source: line 155, verified — this matters directly for Phase 40 because the user's own zsh session wraps `grep` through `ugrep`/Claude Code's own binary, confirmed live this session]:
```bash
# grep insensible à l'alias zsh (ugrep) : on force le binaire système.
GREP="$(command -v grep)"
```
Reuse verbatim — do not call bare `grep` in the new anti-alias test.

**Word-boundary regex convention** [source: lines 230-244, `DELETED_VERBS`/`DELETED_RE`/`deleted_hits()`]:
```bash
DELETED_RE="(${DELETED_RE})([^a-z0-9-]|\$)"
deleted_hits() { "$GREP" -oE "$DELETED_RE" "$1" 2>/dev/null | "$GREP" -oE 'vf-[a-z-]+' | sort -u | tr '\n' ' '; }
```
For the anti-alias test, the equivalent is a single-term boundary check for `vibeflow-dev` (no alternation needed, only one banned string) — but the boundary discipline (`vf-dev ≠ vf-dev-manager`, documented at lines 233-234) is the reason `vibeflow-dev` needs the same non-word-character boundary, not a bare substring grep (`vibeflow-dev` is not a substring of any other live token here, but the discipline should still be applied for consistency with the file's own convention).

---

### `plugin/conductor/scripts/check-overlaps.sh` + `test-check-overlaps.sh` — ADR-057 line rename (trivial, paired)

**Analog:** itself, `KNOWN_PAIRS` heredoc line 67 [verified]:
```
vibeflow-dev|gsd-next|vibeflow-dev = front door unique du lab (agent routeur) ; gsd-next = front door de GSD pour qui n'a pas d'agent routeur — ne jamais router gsd-next (empilerait deux routeurs, ADR-057)
```
→ rename `vibeflow-dev` (both the pair key and the prose) to `vibeflow-head` in the same commit as its test fixtures.

**Test fixtures T15/T16** [source: `test-check-overlaps.sh:186-210`, verified]:
```bash
# T15 — les 3 frontières mempalace/gsd-next (ADR-057) : les deux côtés présents → affichées
reset_all
skill "consolidator"
agent "vibeflow-dev"
user_skill "gsd-mempalace-capture"
...
# T16 — un seul côté présent pour chaque paire mempalace/gsd-next → aucune frontière affichée
reset_all
skill "consolidator"
agent "vibeflow-dev"
...
```
→ `agent "vibeflow-dev"` becomes `agent "vibeflow-head"` in both T15 and T16 — rename script and test fixtures **together**, per RESEARCH.md's explicit integration point ("`check-overlaps.sh` ↔ `test-check-overlaps.sh` : renommer les deux dans le même lot").

---

### Trivial rename-only files (role varies, no structural change — closest analog is the surrounding prose itself)

For each of the following, the pattern is a plain string substitution `vibeflow-dev` → `vibeflow-head`, confirmed present by direct grep this session (bypassing the zsh/rtk grep alias, `/usr/bin/grep` used for verification):

| File | Lines confirmed | Context |
|---|---|---|
| `README.md` | 46 | `the \`vibeflow-dev\` agent detects the intent and runs the GSD pipeline` |
| `README.fr.md` | 46 | `l'agent \`vibeflow-dev\` détecte l'intention et déroule le` |
| `plugin/design-orchestrator/AGENT.md` | 3 | frontmatter `description:`, `... ou par vibeflow-dev quand un cycle atteint une phase de design.` |
| `plugin/planning-core/SKILL.md` | 3, 81 | `gsd-new-project (garde-fou first-use de l'agent vibeflow-dev)`; `via l'agent \`vibeflow-dev\`` |
| `plugin/planning-core/references/gsd-handoff.md` | 31, 35, 43 | 3 occurrences — **confirmed present, must be added to the rename lot's target list** (see Pitfall) |
| `plugin/commands/vf-planning.md` | 15, 18 | `vers la bonne brique GSD (ou l'agent \`vibeflow-dev\`)` |
| `plugin/software-architecture/rules/doc-research-before-debug.md` | 24, 88 | `... est portée par le skill \`vf-debug\`, l'agent \`vibeflow-dev\` et, en boucle autonome,` |
| `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` | 6 | comment only: `... ça reste du jugement porté par l'agent (vibeflow-dev, plan ...` |
| `plugin/dev-orchestrator/references/GSD-PIPELINE.md` | 3, 103, 156 | 3 occurrences |
| `plugin/dev-orchestrator/references/docs-flow.md` | 3, 6 | 2 occurrences |
| `plugin/dev-orchestrator/references/ingestion-flow.md` | 3, 6 | 2 occurrences |
| `plugin/dev-orchestrator/skills/vf-dev/SKILL.md` | 3, 8 | `Incarne l'agent vibeflow-dev` — **incarnation target changes, skill name `vf-dev` stays (D-17)** |
| `plugin/dev-orchestrator/README.md` | 4, 22, 43, 74, 149, 306 | **6 occurrences, not 1 as a shallow scan might suggest** — l.306 sits in the README's own "Changelog" prose section (distinct from `CHANGELOG.md`, which is exempt); confirm at plan time whether that historical line is renamed or left as a dated reference |
| `plugin/dev-orchestrator/module.json` | description string | version bump to next minor (D-16) alongside the string rename |
| `plugin/dev-orchestrator/VERSION` | `v2.21.0` → next minor | D-16 |

`plugin/dev-orchestrator/skills/vf-auto/SKILL.md`: **no `vibeflow-dev` string found** by direct grep this session — this file's change is a **discretionary addition** (cite the allocation-scale rule from `head-governance.md`), not a rename. Its existing `SEUIL_EQUIPE`/`vf-dev-manager` block (lines 19, 28-34) is the anchor point for that citation:
```
Applique le seuil canonique `SEUIL_EQUIPE` (défini dans ...
- **N < SEUIL_EQUIPE ET aucun signal de durée** ... 
- **N ≥ SEUIL_EQUIPE OU signal de durée** → **équipe** : dispatche l'agent `vf-dev-manager`
```

## Shared Patterns

### Exit-code convention (3 sain / 0 manque(s) / 4 indéterminé / 64 outillage illisible)
**Source:** `plugin/conductor/scripts/check-mission-invariants.sh:33-43`
**Apply to:** `check-mission-exit.sh` exclusively (the only new gate in this phase) — but this is the repo-wide convention shared by `check-doc-drift.sh`, `check-gsd-engine.sh`, and every other gate; diverging from it would break inter-gate readability that D-07 explicitly requires.

### Git hardening wrapper (`git_safe`)
**Source:** `plugin/conductor/scripts/check-mission-invariants.sh:96-102`
**Apply to:** `check-mission-exit.sh` (E2, E3 both invoke git)
```bash
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }
```

### Cascade `$S` script resolution
**Source:** `plugin/dev-orchestrator/references/mission-flow.md:17-18`
**Apply to:** `check-mission-exit.sh` (to find `driver-lock.sh`), and `head-governance.md` (documents the cascade for anyone invoking the gate)

### `$GREP` system-binary forcing (avoid shell alias interception)
**Source:** `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:155`
**Apply to:** the new anti-alias test in `test-dev-orchestrator.sh`, and any grep call inside `test-check-mission-exit.sh` — **directly relevant to this session's own environment**, where the user's zsh `grep` function wraps `ugrep`/Claude Code's binary and silently changes multi-file grep output (confirmed live: a naive multi-file grep under the wrapped shell function returned 1/13 files where `/usr/bin/grep` returned 13/13).

### Pattern C typed block, E6 insertion point
**Source:** `plugin/dev-orchestrator/references/mission-flow.md:210-228`
**Apply to:** `mission-contracts.md` (defines the field), `vf-dev-manager.md` (relays it), `check-mission-exit.sh` (reads it for E6) — one format, three consumers, per RESEARCH.md's Integration Points.

### Renvoi-only doctrine (ADR-030, one voice)
**Source:** `plugin/dev-orchestrator/agents/vf-dev-manager.md:249-250` citing `mission-flow.md`
**Apply to:** `AGENT.md` citing `head-governance.md` — the agent states the rule in one line and points to the reference, never reformulates it locally.

## No Analog Found

| File/Pattern | Role | Data Flow | Reason |
|---|---|---|---|
| Repo-wide recursive anti-alias grep (`find plugin -type f`, excluding `CHANGELOG.md`, over the whole `plugin/` tree) | test (structural) | batch | No existing test in this repo does a tree-wide grep for a banned string — the closest precedent (T13 "façade morte") is bounded to a curated file list (`$t13_files`), not `find`-driven. The planner should treat this as **genuinely new construction**, reusing only the `$GREP`-forcing and word-boundary-regex conventions, not a structural copy. |

## Metadata

**Analog search scope:** `plugin/conductor/scripts/`, `plugin/conductor/scripts/tests/`, `plugin/dev-orchestrator/` (all subdirs), `plugin/planning-core/`, `plugin/design-orchestrator/AGENT.md`, `plugin/commands/`, `plugin/software-architecture/rules/`, root `README.md`/`README.fr.md`.
**Files scanned:** 23 target files + 5 analog files read in full (`check-mission-invariants.sh`, `test-check-mission-invariants.sh`, `check-overlaps.sh` excerpt, `test-check-overlaps.sh` excerpt, `test-dev-orchestrator.sh` excerpts) + 3 reference docs read in part (`mission-flow.md`, `mission-contracts.md`, `driver-lock.sh`).
**Tracked-source gate:** all analog paths verified via `git ls-files` this session — no gitignored mirror in the analog set.
**Pattern extraction date:** 2026-09-15
