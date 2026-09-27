# Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator - Pattern Map

**Mapped:** 2026-09-25
**Files analyzed:** 14 (2 new, 12 modified)
**Analogs found:** 14 / 14 (all tracked source; no gitignored mirrors encountered)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/conductor/scripts/check-skills.sh` (NEW) | script (lint gate) | batch / transform (file discovery → frontmatter parse → verdict report) | `plugin/conductor/scripts/check-agents.sh` | exact — explicitly ordered as a structural mirror by D-Q6/Claude's Discretion |
| `plugin/conductor/scripts/check-agents-manifest.json` (MODIFIED — 7th list) | config (datée, single source of truth) | batch (static data, read-only) | itself (existing 6 lists) | exact — additive extension of the same schema, never a second manifest |
| `plugin/conductor/scripts/tests/test-check-skills.sh` (NEW) | test | batch | `plugin/conductor/scripts/tests/test-check-agents.sh` | exact — same harness (`ok/ko/okmut/komut`, mutation by `cmp`) |
| `plugin/conductor/scripts/check-instruction-budget.sh` (MODIFIED — extend) | script (lint/budget gate) | batch / transform | itself (existing agent-discovery loop + `check-agents.sh`'s `decouvrir_agents` for the new recursive SKILL.md walk) | role-match — additive second discovery + second metric in the same file |
| `plugin/conductor/scripts/tests/test-check-instruction-budget.sh` (MODIFIED — new cases) | test | batch | itself + `test-check-agents.sh` fixture style | exact |
| `plugin/skill-creator/skills/skill-creator/SKILL.md` (MODIFIED) | prompt/skill (agentic interview, non-templated engine) | request-response (interview flow, not code) | itself (existing "Write the SKILL.md" / "Capture Intent" sections) | exact — same file, new interview item |
| `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` (MODIFIED) | prompt/skill (templated workflow, propagated to labs) | request-response | itself (existing Phase 1 Cadrage, item 4 "nature du sujet") | exact — same file, sibling item, distinct name (D-Q2) |
| `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (MODIFIED — durcissements a/b) | script (installer, file transform) | file-I/O (reads `.mcp.json`×2 scopes, rewrites agent `tools:`) | itself (existing `named_request`/`has_named`/no-op sites) | exact — hardening two existing silent branches in place |
| `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` (MODIFIED — harden T16/T22) | test | batch | itself + `test-check-agents.sh`'s `ok/ko` idiom | exact |
| `plugin/_internal/vibeflow-update.sh` (MODIFIED — 3 text fixes, lines 1276, 1308, 2423) | installer script / prose | doc/prose (log strings and comments, not executable logic) | itself | exact |
| `plugin/conductor/skills/vf-calibrate/SKILL.md` (MODIFIED — line 92 text fix) | skill doc | doc/prose | itself | exact |
| `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` (MODIFIED — §1.2, §7.2 amendment) | doc/spec | doc/prose | itself | exact |
| `.github/workflows/ci.yml` (MODIFIED — new `check-skills` step, implied by architecture) | CI config | batch (invocation, non-interactive) | existing `check-agents --strict` steps (lines 252-297) in same file | role-match |
| `plugin/conductor/hooks/hooks.json` (MODIFIED — SessionStart entry, implied by architecture) | config (hook registration) | event-driven (SessionStart) | existing `check-agents.sh --hook` entry (line 22) in same file | role-match |

**Note on the last two rows:** neither `43-CONTEXT.md` nor `43-RESEARCH.md` names these two files explicitly as files to touch — they are structurally implied by "miroir de `check-agents.sh`" (a gate that is never wired into CI/hook is a gate nobody runs) and by the RESEARCH architecture diagram. Flag at plan time whether wiring `check-skills.sh` into CI/hook is in scope for this phase or deferred; if wired, both files carry the `Gate-Touche:` trailer requirement (G-2, CLAUDE.md).

## Pattern Assignments

### `plugin/conductor/scripts/check-skills.sh` (NEW — script, batch/transform)

**Analog:** `plugin/conductor/scripts/check-agents.sh` (1260 lines)

**Header/contract pattern** (lines 1-75, imports/usage doc) — copy the documentation discipline itself, not just code: the exit-code contract (0/1/3), the manifest-freshness doctrine, and the recursive-discovery doctrine are all declared in a structured comment block before any code, e.g.:
```
# Usage:
#   check-agents.sh                     # lint .claude/agents/*.md · exit 1 si non conforme
#   check-agents.sh --strict            # GATE init : + les skills déclarés doivent EXISTER
#   check-agents.sh --hook              # SessionStart : compact, exit 0 toujours
#   check-agents.sh --file <agent.md>   # un seul fichier (utilisé par guard-agent-write)
#   check-agents.sh --manifest-freshness=lenient|strict  # défaut lenient — strict seul rend
#                                                 # INDETERMINE (exit 3) sur manifeste perime,
#                                                 # reserve a la CI du depot (D-04)
```
`check-skills.sh` needs the equivalent block naming its own flags (`--skills-dir`, `--strict`, `--hook`, `--file`) and its own doctrine cross-references (D-Q1 écart, D-Q5 avertissement, FABR-06/07).

**Recursive discovery pattern** (lines 291-316, `decouvrir_agents`) — reuse verbatim, filtered on filename instead of extension. This is the function that resolves Pitfall 1 (25 real SKILL.md at three depths, not the two the CONTEXT glob assumed):
```python
def decouvrir_agents(racine, refuses=None):
    trouves = []
    for dirpath, dirnames, filenames in os.walk(racine, followlinks=False):
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        dirnames[:] = [d for d in dirnames if not d.endswith('-references')]
        for fn in filenames:
            if fn.endswith('.md') and fn not in NOT_AGENTS:
                full = os.path.join(dirpath, fn)
                if os.path.islink(full):
                    if refuses is not None:
                        refuses.append(full)
                    continue
                trouves.append(full)
    return sorted(trouves)
```
Adapt the inner filter to `if fn == 'SKILL.md':` — keep `followlinks=False`, the hidden-dir exclusion, the `-references` exclusion, and the symlink refusal *character for character*: each is mutation-proven (MUT-D1, MUT-D2, Phase 42) and re-deriving any of them risks reintroducing an already-fixed bug. Plan must decide explicitly whether `plugin/reference/**` (4 of the 25 files, `type: doc-only` templates with `[NOM_LAB]` placeholders) is included or excluded (Pitfall 1/Assumption A3) — do not leave it implicit.

**Manifest loading pattern** (lines 348-390, `charger_manifeste`) — reuse this function unchanged if the manifest schema is extended additively (new 7th key inside `listes`, e.g. `champs_frontmatter_skills`), since it already validates `cles_listes` against a fixed set:
```python
def charger_manifeste(chemin):
    with open(chemin, encoding="utf-8") as fh:
        m = json.load(fh)
    if not isinstance(m, dict):
        raise ValueError("racine du manifeste — attendu un objet JSON")
    cles_racine = {"valide_jours", "rafraichissement", "listes"}
    ...
    cles_listes = {"outils", "champs_frontmatter", "types_natifs", "modeles", "modes_permission", "niveaux_effort"}
    if set(listes.keys()) != cles_listes:
        raise ValueError(f"listes — attendu exactement les six cles {sorted(cles_listes)}, trouve {sorted(listes.keys())}")
```
**Load-bearing detail:** the `cles_listes` set is checked with strict equality (`!=`), not subset. Adding a 7th key to `check-agents-manifest.json` (e.g. `champs_frontmatter_skills`) will make `check-agents.sh`'s own `charger_manifeste` call *fail* unless this line is also widened, or `check-skills.sh` uses a sibling validator. Plan must trace this explicitly (RESEARCH Wave 0 Gap, "manifeste étendu... sans casser la validation existante des 6 listes agents").

**Frontmatter tokenizer pattern** (lines 456-503, `parse_frontmatter` + `frontmatter_lines`) — reuse verbatim; this is the same YAML-tolerant scalar/list/continuation parser needed to read `vf-nature:`, `ecrit:`, and a judge-rubric field:
```python
def parse_frontmatter(text):
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    fm, i = {}, 1
    current_key = None
    while i < len(lines):
        line = lines[i]
        if line.strip() == "---":
            return fm
        m = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        ...
    return None  # frontmatter jamais ferme
```

**Blocking-invariant pattern** (lines 778-795, `invariant_i1`) — the direct template for FABR-06 (`vf-nature: procedure` without `ecrit:`/judge rubric → refusal). Same shape: returns a list of messages, never a boolean; two-directional check kept for FABR-07 (drift), single-directional refusal kept for FABR-06:
```python
def invariant_i1(base, fm):
    is_internal = str(fm.get("vf-internal", "")) == "true"
    desc = fm.get("description")
    ...
    has_marker = "Worker interne" in desc_text
    if is_internal and not has_marker:
        return [f"{base} : invariant I1 — vf-internal: true sans le marqueur « Worker interne » dans description: (D-06)"]
    if has_marker and not is_internal:
        return [f"{base} : invariant I1 — description: porte « Worker interne » sans vf-internal: true (D-06)"]
    return []
```
FABR-06 concretely (see RESEARCH § Code Examples for the fuller draft):
```python
def invariant_procedure_sans_juge(base, fm):
    nature = str(fm.get("vf-nature", "outil"))  # défaut "outil" — jamais un refus silencieux
    if nature != "procedure":
        return []
    a_ecrit = bool(fm.get("ecrit"))
    a_rubrique_juge = bool(fm.get("rubrique-juge"))  # nom de clé exact à trancher au plan (Open Question 1)
    manquants = [n for n, present in (("ecrit:", a_ecrit), ("rubrique de juge", a_rubrique_juge)) if not present]
    if manquants:
        return [f"{base} : vf-nature: procedure sans {' ni '.join(manquants)} (B-03, FABR-06)"]
    return []
```

**Exit-code contract pattern** (lines 1140-1260, tail of the embedded Python + `hook_exit`) — reuse the 0/1/3 shape and the D-05 downgrade-to-warning idiom (never a separate exit regime) for FABR-07's drift warning:
```python
if n_err:
    print(f"[check-agents] ✗ {n_err} non-conformite(s) bloquante(s) :")
    for e in errors:
        print(f"  ✗ {e}")
    if not (perimees and manifest_freshness_strict):
        sys.exit(1)
if perimees and manifest_freshness_strict:
    print("[check-agents] ✗ INDETERMINE — MANIFESTE-PERIME : aucun verdict rendu (D-04) ...")
    sys.exit(3)
print(f"[check-agents] ✓ agents conformes (natif + charte VibeFlow){' · ' + str(n_warn) + ' warning(s)' if n_warn else ''}")
sys.exit(0)
```
And the shell-side hook translation (exit 3 → 0 only under `--hook`, never 0/1 translated):
```bash
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK_MODE" = true ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}
```

**Drift-detection pattern (FABR-07, no direct precedent — see "No Analog Found" below)** — closest shape is still `invariant_i1`'s two-way check, but the *vocabulary* of body-text markers has no existing implementation (RESEARCH Pitfall 2/Assumption A2). Anchor any regex discipline to `check-instruction-budget.sh`'s `MARKER_RE`/`RULES_TITLE_RE` scoping idiom (see below) to avoid the 25-false-positive failure mode already measured in this repo.

---

### `plugin/conductor/scripts/check-agents-manifest.json` (MODIFIED — additive 7th list)

**Analog:** itself (existing structure, lines 1-45)

**Pattern to extend** — each list is `{verifie_le, source, valeurs}`, validated against `_VALEUR_RE` (`[A-Za-z0-9_-]+`) per value and an ISO date + `https://` source:
```json
"champs_frontmatter": {
  "verifie_le": "2026-09-23",
  "source": "https://code.claude.com/docs/en/sub-agents",
  "valeurs": ["name", "description", "tools", "disallowedTools", "model", "permissionMode",
    "maxTurns", "skills", "mcpServers", "hooks", "memory", "background", "omitClaudeMd",
    "effort", "isolation", "color", "initialPrompt", "experimental"]
}
```
A new `champs_frontmatter_skills` list (or equivalent name) follows the exact same shape (`verifie_le`/`source`/`valeurs`), values restricted to `[A-Za-z0-9_-]+` (so `vf-nature`, `ecrit`, and any judge-rubric key name must fit that charset — no colon, no space). **Load-bearing constraint:** `charger_manifeste`'s `cles_listes` equality check (see above) must be updated in lockstep in whichever script reads this manifest, or the addition breaks `check-agents.sh` itself.

---

### `plugin/conductor/scripts/tests/test-check-skills.sh` (NEW — test, batch)

**Analog:** `plugin/conductor/scripts/tests/test-check-agents.sh` (3557 lines)

**Harness pattern** (lines 245-260):
```bash
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
okmut() {  # <id> <rc_mutant> <attendu_mut> <rc_original> <attendu_orig>
  echo "  ✓ MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5"
  pass=$((pass+1))
}
komut() {  # <id> <assertion> <attendu> <obtenu>
  echo "  ✗ MUT-$1 NON TUE : $2"
  ...
  fail=$((fail+1))
}
```

**Mutation-proof pattern** (lines 338-374, `make_gate_mutant`) — a mutant is only "killed" if both `bash -n` succeeds AND the mutated file differs from the original AND both rc values match expectations; comparison is always by `cmp`, never `diff` ("menteur ici" per the header comment):
```bash
make_gate_mutant() { # <id> <age_jours> <motif> <remplacement> [operation]
  ...
  n="$(grep -Fc -- "$motif" "$orig")"
  if [ "$n" -ne 1 ]; then
    komut "$id" "motif fixe unique dans check-agents.sh" "exactement 1 occurrence" "MOTIF AMBIGU OU ABSENT (n=$n)"
    ...
  fi
  ...
  if cmp -s "$tmp" "$orig"; then
    komut "$id" "mutation produit un fichier different de l'original" "fichiers distincts" "NON OPPOSABLE (identique)"
    ...
  fi
  if ! bash -n "$tmp" 2>/dev/null; then
    komut "$id" "mutant syntaxiquement valide" "bash -n reussit" "bash -n ECHOUE"
    ...
  fi
}
```
`test-check-skills.sh` needs a sibling `make_gate_mutant`-equivalent scoped to `check-skills.sh`, at minimum one mutation per blocking invariant (FABR-06), per RESEARCH's Wave 0 Gap checklist. Every rule needs a negative twin (a fixture that violates it) — this is the standing convention across every gate in `plugin/conductor/scripts/tests/`.

**Dated-manifest test fixture pattern** (lines 271-336, `mk_manifest`/`mk_gate_dir`) — the suite judges gate logic against a manifest re-dated to "today" at each run, never the committed manifest as-is (whose own freshness is judged only by CI) — reuse the same `mk_manifest`-style harness, parameterized to the manifest path `check-skills.sh` actually reads (the same file, extended).

---

### `plugin/conductor/scripts/check-instruction-budget.sh` (MODIFIED — additive extension)

**Analog:** itself (394 lines) — extend in place; `check-agents.sh`'s `decouvrir_agents` is the secondary analog for the new recursive SKILL.md walk this file currently lacks.

**Existing exit-code contract** (lines 26-35, comment) — preserve exactly, do not invent a new regime for the SKILL.md/bootstrap additions:
```
# Exit codes (contrat interne, tous enumeres, aucun implicite — patron check-divergence.sh) :
#   0  = ARME et aucun depassement (peut porter un verdict AVERTISSEMENT-ADR029 non bloquant,
#        des 251 lignes, ou LIGNES-EN-HAUSSE informatif)
#   1  = ARME et au moins un depassement ...
#   2  = NON VERIFIABLE — decouverte vide, fichier imparsable, ou contrat de baseline incoherent
#   3  = NON ARME — rapport imprime integralement, jamais bloquant (D-04)
#   64 = erreur d'usage
```

**Existing discovery pattern to leave UNCHANGED** (lines 14-15 comment + 93-106 code, D-03, one-level glob):
```bash
# Decouverte (D-03) : glob a UN SEUL NIVEAU, plugin/*/agents/*.md + plugin/*/AGENT.md — jamais un
# find recursif, qui capturerait bien plus de fichiers que le corpus d'agents distribues.
...
for f in "$ROOT"/plugin/*/agents/*.md; do
  [ -f "$f" ] || continue
  rel="${f#"$ROOT"/}"
  printf '%s\n' "$rel" >> "$FILES_LIST"
done
```
Per D-Q4/Pattern 3 of RESEARCH, this loop is NOT touched — a second, independent discovery loop for `SKILL.md` (recursive, `decouvrir_agents`-style) is added alongside it, with its own `FILES_LIST`/`REPORT`/verdict counters, never merged into the agent corpus.

**Reusable metric functions** (lines 142-219, `frontmatter_state`/`body_only`/`lines_count`/`count_instructions`) — generic over any markdown-with-frontmatter file, reusable as-is for the SKILL.md 500-line cap:
```bash
frontmatter_state() { # <file> -> "open" | "closed" | "none"
  awk '
    NR==1 && /^---[[:space:]]*$/ { started=1; infm=1; next }
    infm && /^---[[:space:]]*$/ { infm=0; closed=1; next }
    END { if (!started) { print "none" } else if (closed) { print "closed" } else { print "open" } }
  ' "$1" 2>/dev/null
}
```
```bash
lines_count() { # <file> -> nombre de lignes du fichier ENTIER, jamais wc -l (sous-compte sans \n final)
  awk 'END { print NR }' "$1" 2>/dev/null || echo 0
}
```
**Marker regex scoping discipline** (lines 84-87, `MARKER_RE`/`RULES_TITLE_RE`) — the anti-false-positive pattern any new drift-vocabulary regex (FABR-07, in `check-skills.sh`) or any new frontmatter-based measurement here should imitate: scope to titles that "reopen" a rules section, never a bare keyword match:
```bash
MARKER_RE='jamais|toujours|ne .* pas|doit|must|never|always|interdit|obligatoire'
RULES_TITLE_RE='r[eè]gles|garde-fous|iron law|anti-pattern|lignes rouges|discipline'
```

**New constant needed (not a reuse)** — SKILL.md cap is a *different* number and needs its own name, never shared with the agent cap:
```bash
VF_SKILL_LINE_CAP=500   # ADR-029 : "skills ≤ 500", distinct du plafond agent 300/warn 251
```

**Bootstrap metric — net-new, no function to extend** (RESEARCH Pitfall 5): the bootstrap budget is the sum of estimated tokens across `name:` + `description:` of the discovered SKILL.md corpus, NOT a line count, NOT a hook's stdout. `body_only()`'s inverse is the extraction pattern to imitate (same `NR==1` anchor, never diverge on what counts as frontmatter):
```bash
frontmatter_name_desc() { # <file> -> "name" et "description" concaténés, pour estimation de tokens
  awk '
    NR==1 && /^---[[:space:]]*$/ { infm=1; next }
    infm && /^---[[:space:]]*$/ { infm=0; next }
    infm && /^(name|description):/ { print }
  ' "$1"
}
```
The dépôt's already-documented (but never implemented) token-estimation factor for this: ×12 tokens/line for body content is documented at `plugin/reference/content/methodology/templates/skills/agent-density-auditor/references/thresholds.md:17` — reuse this factor by cohérence rather than introducing a real tokenizer dependency (repo has already ruled that out, `.planning/research/FEATURES.md:79-82`, ADR-054 portability).

---

### `plugin/conductor/scripts/tests/test-check-instruction-budget.sh` (MODIFIED — new cases)

**Analog:** itself + `test-check-agents.sh`'s fixture-building idiom.

New cases needed per RESEARCH Wave 0 Gaps: a fixture SKILL.md > 500 lines and one under 500 (discovery + cap verdict), and a fixture with a deliberately long `description:` (bootstrap metric). Follow the existing script's verdict vocabulary (`SANS-BASELINE`, `DEPASSEMENT-ADR029`, `DEPASSEMENT-INSTR`, `MARGE`, `+LIGNES-EN-HAUSSE`, `+AVERTISSEMENT-ADR029`) — do not invent new verdict strings without a documented reason; the SKILL.md corpus should get its own verdict namespace (e.g. `DEPASSEMENT-SKILL`) analogous to `DEPASSEMENT-ADR029`, distinct so a CI reader can tell which corpus tripped.

---

### `plugin/skill-creator/skills/skill-creator/SKILL.md` (MODIFIED — moteur interne)

**Analog:** itself (485 lines) — insertion point identified exactly by RESEARCH.

**"Write the SKILL.md" section** (lines 62-69) — insertion point for a new component:
```markdown
Based on the user interview, fill in these components:

- **name**: Skill identifier
- **description**: When to trigger, what it does. ...
- **compatibility**: Required tools, dependencies (optional, rarely needed)
- **the rest of the skill :)**
```
Recommended insertion (D-Q6): a new bullet, e.g. `**vf-nature** : referentiel | outil | procedure — défaut « outil » ; si « procedure », exige ecrit: et une rubrique de juge (B-03)`.

**Progressive Disclosure section** (lines 86-93) — the load-bearing citation for FABR-09's bootstrap metric definition, confirming "metadata (name+description) always in context" is a *native* Claude Code mechanism, not a repo convention:
```markdown
Skills use a three-level loading system:
1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** - As needed (unlimited, scripts can execute without loading)
```

---

### `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` (MODIFIED — workflow templaté)

**Analog:** itself (301 lines) — item 4 is the existing, DISTINCT question (D-Q2) that `vf-nature` must sit beside, never fuse with.

**Phase 1 Cadrage, items 1-4** (lines 35-56, verbatim):
```markdown
1. Lire le brief. Identifier :
   - Sujet du skill (quelle competence exacte ?)
   - Probleme resolu (quelle douleur operationnelle ?)
   - Cas d'usage cibles (2-3 situations concretes)
   - **Type : META ou LIVRABLE** ? (si applicable)
   - Agents pressentis (indicatif — [ORCHESTRATING_AGENT] decide l'attribution)
   - Perimetre exclu (ce qui n'est PAS dans le skill)
...
4. Evaluer la nature du sujet :
   - **Methodologique [NOM_LAB]** → vocabulaire et principes [NOM_LAB] centraux
   - **Agnostique** → vocabulaire natif du domaine, pas de folklore [NOM_LAB] force
   - **Zone grise** → framing qui sert la pertinence du sujet
```
Recommended insertion (D-Q2, distinct, never fused): a new item 6 (after the existing item 5 livrable step), e.g. `6. Déclarer vf-nature (B-03) : referentiel | outil | procedure — défaut outil. Si procedure : capturer ecrit: et la rubrique de juge associée.`

**Checklist qualité section** (lines 196-198) — sibling item to add for consistency (same file already has "Type clair" as a checklist entry mirroring the item-4 question):
```markdown
### Checklist qualite (ordre par priorite)

- [ ] **Type clair** (META ou LIVRABLE — si applicable) : skill au bon endroit
```
A frère item `vf-nature déclarée` belongs here by the same pattern.

---

### `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (MODIFIED — durcissements a/b, D-Q3)

**Analog:** itself (590 lines) — two specific silent branches to harden, confirmed at their current (not stale) line numbers this session.

**Durcissement (a) — grammar validation site** (lines 542-551, confirmed current, matches RESEARCH's cited 549-551):
```python
if has_named(text):
    if has_flag(text):
        logline("%s : vf-mcp-consumer ET vf-mcp-tools presents — mode NOMME retenu (moindre privilege)." % base)
    req = named_request(text)
    if req is None:
        logline("%s : vf-mcp-tools malformee (attendu grammaire <serveur>:<outil1>,<outil2>,...) — no-op." % base)
        continue
```
The `named_request` function itself (lines 305-329) is where malformed-grammar detection already lives — it currently returns `None` silently on any of: no colon, empty server, no tools, or a charset violation (`TOKEN_SEGMENT_RE = re.compile(r"^[A-Za-z0-9_-]+$")`). Durcissement (a) turns this `continue`-and-log into a louder signal (exit code and/or `--strict`-gated refusal — to be decided at plan time per RESEARCH Wave 0 Gap: "le durcissement change-t-il le comportement PAR DÉFAUT, ou seulement sous un futur `--strict`").

**Durcissement (b) — named-server-absent site** (lines 552-555, confirmed current, matches RESEARCH's cited 554):
```python
        file_want_tokens = named_tokens_for(text, servers)
        if not file_want_tokens:
            logline("%s : serveur %s (vf-mcp-tools) absent du lab — no-op silencieux." % (base, req[0]))
            continue
```
**Load-bearing constraint (Pitfall 3, confirmed in code):** `servers` at this point is already the UNION of project + global scope (lines 222-267 below) — durcissement (b) must judge "absent" against this union, never against the project scope alone, matching the already-corrected erratum in `43-CONTEXT.md`.

**Union-of-scopes resolution** (lines 222-267, ADR-051-B, confirmed current — comment says "UNION scope projet + scope global"):
```python
# --- 1. Résoudre la liste des serveurs (UNION scope projet + scope global, ADR-051-B) -------------
def load_json_servers(path, what):
    if not path or not os.path.isfile(path):
        logline("%s : %s introuvable — cette source ne contribue aucun serveur." % (what, path))
        return []
    ...

servers = []
if servers_arg:
    servers = [s.strip() for s in servers_arg.split(",") if s.strip()]
else:
    global_servers = load_json_servers(claude_json, "scope global (--claude-json)")
    project_servers = load_json_servers(mcp_json, "scope projet (--mcp-json)")
    merged = {}
    for s in global_servers:
        merged[s.lower()] = s
    for s in project_servers:
        merged[s.lower()] = s
    servers = list(merged.values())
```

---

### `plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` (MODIFIED — harden T16/T22)

**Analog:** itself (476 lines) — existing cases to extend, not create from scratch.

**T16 (currently asserts the no-op is silent and idempotent)** — lines 352-359:
```bash
# === T16 — Serveur nommé absent de la liste résolue : no-op, exit 0 ===========================
N16="$WORK/t16.md"; mk_named "$N16"; n16_before="$(md5of "$N16")"
bash "$SCRIPT" --target "$N16" --servers "mobile-mcp" >/dev/null 2>&1; rc16=$?
if [ "$rc16" -eq 0 ] && [ "$(md5of "$N16")" = "$n16_before" ]; then
  ok "T16 serveur nommé absent du lab → no-op silencieux, exit 0"
else
  ko "T16 échec (rc=$rc16)"
fi
```
Per RESEARCH's Wave 0 Gap, the plan must clarify whether hardening (b) changes T16's asserted behavior (exit code and/or stderr content) for the default invocation, or only under a new `--strict`-like flag — if the latter, T16 stays green unchanged and a new `Tn` case asserts the louder signal under the new flag; if the former, T16 itself must be rewritten (still following the same `ok`/`ko` shape, `md5of` diffing idiom).

**T22 (grammar malformed, two sub-cases already exist)** — lines 430-468, same idiom, same decision point applies for durcissement (a).

---

### `plugin/_internal/vibeflow-update.sh` (MODIFIED — durcissement c, 3 text fixes)

**Analog:** itself — **RE-GREP BEFORE EDITING** (Pitfall 4: line 2413 cited by `43-CONTEXT.md` has drifted to 2423; the other two, 1276 and 1308, are confirmed current this session).

**Line 1276** (header comment, names only `vf-mcp-consumer`):
```bash
# ---------- Injection MCP dérivée du lab (ADR-051) ----------
# Un sous-agent (Task) n'hérite PAS des serveurs MCP de la session : il ne voit, côté MCP, que ce
# que son `tools:` autorise (`mcp__<serveur>__*`). Les agents exécutants (flag vf-mcp-consumer:true)
# doivent donc recevoir les serveurs que le LAB déclare dans son ./.mcp.json.
```

**Line 1308** (log string, names only `vf-mcp-consumer`):
```bash
    log "  serveurs MCP du lab injectés dans les agents exécutants flaggés (vf-mcp-consumer, ADR-051)"
```

**Line 2423** (confirmed current — was 2413 in CONTEXT.md, drifted +10 lines):
```bash
  # Injection MCP dérivée du lab (ADR-051) : si ce module a posé des agents, injecter dans les
  # exécutants flaggés (vf-mcp-consumer) les serveurs MCP que le lab déclare dans ./.mcp.json.
```
All three need `vf-mcp-tools` mentioned alongside `vf-mcp-consumer` per D-Q3(c) — "produire ≠ vérifier", not "one mechanism".

---

### `plugin/conductor/skills/vf-calibrate/SKILL.md` (MODIFIED — durcissement c, line 92)

**Analog:** itself — confirmed current, sole `vf-mcp` occurrence in the file.

**Line 92** (in context, lines 87-93):
```markdown
3. **Ré-affirmer l'allowlist MCP des agents exécutants** (ADR-051) : si le lab a gagné (ou perdu)
   un serveur MCP — dans son `./.mcp.json` (scope projet) **ou** en scope global `~/.claude.json`
   (union des deux sources depuis Phase 21, ADR-051-B ...) — **sans** bump de
   module (l'`update` ne re-copie pas les agents à version inchangée), re-jouer l'injection
   idempotente sur les agents flaggés `vf-mcp-consumer` :
   ```sh
   .claude/scripts/inject-mcp-tools.sh --target .claude/agents --mcp-json ./.mcp.json
   ```
```
Same fix: mention `vf-mcp-tools` alongside `vf-mcp-consumer`.

---

### `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` (MODIFIED — §1.2/§7.2 amendment, D-Q3/FABR-10)

**Analog:** itself — exact lines confirmed current this session.

**§1.2, lines 37-39 (factual errors to correct):**
```markdown
- **Deux conventions MCP concurrentes** pour un même besoin : `vf-mcp-consumer` en booléen sur trois
  agents, `vf-mcp-tools` en liste sur un seul — et ce seul est un agent de revue de code, pas un
  consommateur Xcode.
```
Three corrections required (per `43-CONTEXT.md` D-Q3): `vf-mcp-consumer: true` is on **4** agents not 3 (`vf-coder`, `vf-test-runner`, `vf-test-orchestrator`, `vf-app-fixer`); `vf-reviewer` **is** an Xcode consumer via `vf-mcp-tools`, not a generic isolated case; "deux conventions concurrentes pour un même besoin" must become "deux besoins distincts, deux déclarations" (ADR-051 decision 1).

**§7.2, lines 176-182 (intent to fuse, must be reversed):**
```markdown
### 7.2 MCP reste sur le mécanisme maison, unifié

`mcpServers:` est un champ officiel, mais **ignoré pour les sous-agents de plugin**. ...
En revanche les **deux conventions concurrentes fusionnent** en une seule — deux mécanismes pour un
besoin sont la moitié d'une dérive.
```
The last sentence ("les deux conventions concurrentes fusionnent en une seule") is the one D-Q3 explicitly overturns — Willy's decision keeps both declarations, no migration. Replace with prose citing ADR-051 decision 1 (produce vs. verify) as the reason the two coexist.

**§6, lines 145-165 (unaffected by D-Q3, but is the canonical vocabulary source for FABR-06/07 — cite, do not re-invent):**
```markdown
`vf-nature: referentiel | outil | procedure`, **défaut « outil »** — donc aucun des 142 skills
existants ne change de comportement, et la migration coûte zéro.

- Une **procédure** doit déclarer son périmètre (`ecrit:`) et sa **rubrique de juge**. Sans les deux,
  refus.
- Un **référentiel** et un **outil** ne déclarent rien de plus.
- **Détection de dérive** : le gate signale tout skill qui porte les marqueurs d'une procédure — un
  gate bloquant, un livrable remis à un tiers, une couche de qualité — sans se déclarer comme telle.
```
Note: the "9/142... 32 (23%)" corpus cited immediately after this block is from a *different* repo's corpus (RESEARCH confirms) — do not reuse those numbers for this repo's fixtures; re-measure `find plugin -name SKILL.md | wc -l` (25) before writing test cases.

---

### `.github/workflows/ci.yml` (MODIFIED — new `check-skills` step, IF wired this phase)

**Analog:** existing `check-agents --strict` steps in the same file (lines 245-267 excerpted):
```yaml
      - name: check-agents --strict sur chaque plugin/*/agents (découverte non vide)
        run: |
          set -u
          found=0
          fail=0
          for d in plugin/*/agents; do
            [ -d "$d" ] || continue
            found=$((found + 1))
            echo "== $d =="
            bash plugin/conductor/scripts/check-agents.sh --strict --manifest-freshness=strict --agents-dir="$d" || fail=$((fail + 1))
          done
          if [ "$found" -eq 0 ]; then
            echo "::error::aucun dossier plugin/*/agents découvert — la CI refuse de rendre un verdict vide"
```
Same idiom for `check-skills`: never a "found=0 passes silently" branch (F13 vacuous-green discipline), `--manifest-freshness=strict` reserved to CI exactly as for agents.

---

### `plugin/conductor/hooks/hooks.json` (MODIFIED — SessionStart entry, IF wired this phase)

**Analog:** existing `check-agents.sh --hook` entry, line 22:
```json
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-agents.sh --hook --agents-dir={{VF_SCRIPTS}}/../agents --skills-dir={{VF_SCRIPTS}}/../skills || true" },
```
A sibling `check-skills.sh --hook ... || true` entry follows the same `|| true` fail-open idiom (a hook must never block session start on a gate failure).

## Shared Patterns

### Exit-code contract (0/1/3, F13)
**Source:** `plugin/conductor/scripts/check-agents.sh` (comment block lines 20-40, enforcement lines 1140-1258) and `hook_exit()` (lines ~233-242).
**Apply to:** `check-skills.sh` (new), any extension to `check-instruction-budget.sh` that adds a new verdict path.
```bash
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK_MODE" = true ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}
```
0 = conforme (possibly with non-blocking warnings), 1 = non-conforme bloquant, 3 = INDÉTERMINÉ (never silently downgraded except under `--hook`, at the shell boundary, never inside the Python block).

### Downgrade-to-warning, never a second exit regime (D-05 pattern)
**Source:** `plugin/conductor/scripts/check-agents.sh`, manifest-staleness downgrade (D-05, lines 26-40 comment, `rapport_manifeste_perime()` lines 1209-1215).
**Apply to:** `check-skills.sh`'s FABR-07 drift detection (D-Q5: warning only, never a refusal, never a separate exit code) — same idiom: print a `⚠` line, keep `sys.exit(0)`, never invent a new code for "detected but not blocking".

### Recursive discovery with two mutation-proven exclusions
**Source:** `plugin/conductor/scripts/check-agents.sh`, `decouvrir_agents` (lines 291-316).
**Apply to:** `check-skills.sh` (new discovery filtered on `SKILL.md`) and `check-instruction-budget.sh`'s new second discovery loop for the same corpus.
```python
dirnames[:] = [d for d in dirnames if not d.startswith('.')]
dirnames[:] = [d for d in dirnames if not d.endswith('-references')]
```

### Frontmatter tokenizer (parse_frontmatter / frontmatter_lines / extract_raw_field)
**Source:** `plugin/conductor/scripts/check-agents.sh`, lines 456-557.
**Apply to:** `check-skills.sh` for `vf-nature`/`ecrit`/judge-rubric extraction; `check-instruction-budget.sh`'s new `frontmatter_name_desc()` needs the identical `NR==1` anchor as the existing `frontmatter_state()`/`body_only()` (lines 142-167) so the two functions never disagree on what counts as frontmatter.

### "Never a silent no-op" doctrine (HONNÊTETÉ, D-03/D-05/D-09)
**Source:** `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` header (lines 42-49) and the two sites being hardened (lines 550, 554); mirrored by `check-agents.sh`'s "jamais un skip muet" idiom (used 3× in its own header, e.g. line 67, 72).
**Apply to:** durcissements (a)(b) of `inject-mcp-tools.sh`; any new `check-skills.sh` branch that currently would silently accept a malformed field.

### Test harness: ok()/ko()/okmut()/komut(), mutation proven by `cmp`
**Source:** `plugin/conductor/scripts/tests/test-check-agents.sh`, lines 245-260 (assertion helpers) and 338-374 (`make_gate_mutant`).
**Apply to:** `test-check-skills.sh` (new), extensions to `test-check-instruction-budget.sh` and `test-inject-mcp-tools.sh`.
```bash
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
```
Every blocking rule needs: a positive twin (conforms, green), a negative twin (violates, red), and — for at least the newly-blocking invariants (FABR-06) — a mutation proven dead by `cmp` (never `diff`).

### Marker-regex scoping discipline (anti-false-positive)
**Source:** `plugin/conductor/scripts/check-instruction-budget.sh`, lines 84-87 (`MARKER_RE`/`RULES_TITLE_RE`) and the 25-false-positive incident documented at lines 185-187 of the same file.
**Apply to:** FABR-07's drift-vocabulary regex in `check-skills.sh` — no bare keyword match (e.g. `"qualit"` alone); scope any marker search the way `RULES_TITLE_RE` scopes rule-bullet counting.

## No Analog Found

| File / Concern | Role | Data Flow | Reason |
|---|---|---|---|
| FABR-07 drift-vocabulary regex (inside `check-skills.sh`) | detection logic (not a separate file) | transform | No codified precedent in this repo for matching prose markers ("gate bloquant", "livrable remis à un tiers", "couche de qualité") against a corpus — `invariant_i1`'s two-way check is the closest *shape*, but the *vocabulary* is net-new design work, explicitly flagged LOW confidence in RESEARCH (Pitfall 2, Assumption A2, Open Question 2). Plan must document the chosen regex as an explicit decision, not an implicit hypothesis. |
| Bootstrap-budget metric (`frontmatter_name_desc` + token-sum, inside `check-instruction-budget.sh`) | metric function | transform | No existing function sums frontmatter metadata across a corpus for token estimation — `body_only()` measures the opposite (body, excluding frontmatter). This is additive, not reusable (RESEARCH Pitfall 5, Open Question 3: whole corpus vs. "universal" subset still undecided). |

## Metadata

**Analog search scope:** `plugin/conductor/scripts/`, `plugin/conductor/scripts/tests/`, `plugin/dev-orchestrator/scripts/`, `plugin/dev-orchestrator/scripts/tests/`, `plugin/skill-creator/skills/`, `plugin/conductor/skills/vf-calibrate/`, `plugin/_internal/`, `docs/superpowers/specs/`, `.github/workflows/`, `plugin/conductor/hooks/`.
**Files scanned:** 14 target files + `check-agents-manifest.json` schema + `docs/ADR.md` (ADR-051 cross-reference, not modified this phase).
**Tracked-source gate:** all 12 analog paths confirmed via `git ls-files` (non-empty output) before citation — no gitignored install/runtime mirrors encountered; no `.gsd/capabilities/` paths involved in this phase.
**Pattern extraction date:** 2026-09-25.
