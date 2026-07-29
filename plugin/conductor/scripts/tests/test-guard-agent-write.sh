#!/usr/bin/env bash
# test-guard-agent-write.sh — Suite du guard PreToolUse(Write) sur .claude/agents/ (ADR-044,
# durcissement Phase 20 T20 : le checker est invoque avec --strict, un agent non conforme
# est REELLEMENT refuse, pas seulement averti).
#
# Chaque test invoque le guard REEL avec un payload PreToolUse (stdin) construit par python
# (echappement JSON fiable) — comme le runtime le ferait, jamais une lecture de code.
#
# T1  — ecriture conforme (frontmatter valide, Write+Edit dans tools:) → allow
# T2  — regression Phase 20 (memory: + tools: sans Write/Edit, sans disallowedTools) → deny
# T3  — le message de deny (T2) explique quoi corriger (disallowedTools + squelette canonique)
# T4  — skill declare introuvable (AUTRE regle promue par --strict, pas seulement memory/tools) → deny
# T5  — exemption hors-lab : cible hors cwd, contenu non conforme quand meme → allow
# T6  — chemin hors .claude/agents/ → allow
# T7  — basename exclu (README.md/contracts.md/AGENTS.md) sous .claude/agents/ → allow
# T8  — stdin invalide (pas du JSON) → allow silencieux (fail-open)
# T9  — content vide → allow (coquille tolerée, rattrapee au SessionStart)
# T10 — extension non-.md → allow
# T11 — prefiltre pur-bash : payload sans la sous-chaine '.claude' → allow (zero spawn)
# T12 — frontiere anti-faux-positif : parent 'my.claude/agents' ne matche pas → allow
# T13 — fail-open : checker absent a cote du guard → allow malgre contenu non conforme
# T14 — anti-regression structurelle : le guard invoque bien le checker AVEC --strict (grep source)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD="$(cd "$TESTS_DIR/.." && pwd)/guard-agent-write.sh"
BASH_BIN="${BASH:-bash}"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-guard-agent-write (guard: $GUARD) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/.claude/agents" "$WORK/.claude/skills"

run_guard() { printf '%s' "$1" | (cd "$WORK" && "$BASH_BIN" "$GUARD") 2>/dev/null; }

mk_write() { # file content
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))' "$1" "$2"
}

# --- Fixtures ---------------------------------------------------------------

CONFORME='---
name: test-agent-conforme
description: Agent de test conforme utilise par test-guard-agent-write pour prouver qu une ecriture licite passe le guard durci --strict.
model: sonnet
memory: project
tools: [Read, Write, Edit, Bash, Glob, Grep]
---

Corps de test.
'

NON_CONFORME_MEMOIRE_TOOLS='---
name: test-agent-non-conforme
description: Agent de test fabrique pour prouver le refus --strict du guard (memory + tools sans Write/Edit, sans disallowedTools).
model: sonnet
memory: project
tools: [Read, Bash, Glob, Grep]
---

Corps de test.
'

NON_CONFORME_SKILL_FANTOME='---
name: test-agent-skill-fantome
description: Agent de test avec skill fictif pour prouver que --strict promeut aussi skill declare introuvable en erreur.
model: sonnet
memory: project
tools: [Read, Write, Edit, Bash]
skills: [ghost-skill-inexistant]
---

Corps de test.
'

# --- T1 — ecriture conforme -------------------------------------------------

OUT="$(run_guard "$(mk_write "$WORK/.claude/agents/test-agent-conforme.md" "$CONFORME")")"
[ -z "$OUT" ] && ok "T1 ecriture conforme (Write+Edit dans tools:) → allow" || ko "T1 allow attendu, obtenu : $OUT"

# --- T2 — regression Phase 20 : memory + tools sans Write/Edit -------------

OUT="$(run_guard "$(mk_write "$WORK/.claude/agents/test-agent-non-conforme.md" "$NON_CONFORME_MEMOIRE_TOOLS")")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"'; then
  ok "T2 memory: + tools: sans Write/Edit ni disallowedTools → deny (durcissement --strict)"
else
  ko "T2 deny attendu, obtenu : ${OUT:-<vide>}"
fi

# --- T3 — le message explique quoi corriger ---------------------------------

if echo "$OUT" | grep -q "disallowedTools" && echo "$OUT" | grep -q "Squelette canonique"; then
  ok "T3 le message de deny nomme le champ manquant (disallowedTools) ET donne le squelette de correction"
else
  ko "T3 message actionnable attendu, obtenu : ${OUT:-<vide>}"
fi

# --- T4 — skill declare introuvable (autre regle promue par --strict) ------

OUT="$(run_guard "$(mk_write "$WORK/.claude/agents/test-agent-skill-fantome.md" "$NON_CONFORME_SKILL_FANTOME")")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"' && echo "$OUT" | grep -q "skill declare introuvable"; then
  ok "T4 skill declare introuvable → deny (le durcissement n est pas ad hoc a une seule regle)"
else
  ko "T4 deny attendu (skill declare introuvable), obtenu : ${OUT:-<vide>}"
fi

# --- T5 — exemption hors-lab -------------------------------------------------

OUTSIDE="$(mktemp -d)"
mkdir -p "$OUTSIDE/.claude/agents"
OUT="$(run_guard "$(mk_write "$OUTSIDE/.claude/agents/test-agent-non-conforme.md" "$NON_CONFORME_MEMOIRE_TOOLS")")"
[ -z "$OUT" ] && ok "T5 cible hors cwd (contenu non conforme quand meme) → allow (exemption hors-lab, CND-05/T20)" \
  || ko "T5 allow attendu (hors-lab), obtenu : $OUT"
rm -rf "$OUTSIDE"

# --- T6 — chemin hors .claude/agents/ ---------------------------------------

OUT="$(run_guard "$(mk_write "$WORK/.claude/skills/test-agent-non-conforme.md" "$NON_CONFORME_MEMOIRE_TOOLS")")"
[ -z "$OUT" ] && ok "T6 chemin hors .claude/agents/ → allow" || ko "T6 allow attendu, obtenu : $OUT"

# --- T7 — basename exclu -----------------------------------------------------

OUT="$(run_guard "$(mk_write "$WORK/.claude/agents/README.md" "$NON_CONFORME_MEMOIRE_TOOLS")")"
[ -z "$OUT" ] && ok "T7 README.md sous .claude/agents/ → allow (exclu du lint)" || ko "T7 allow attendu, obtenu : $OUT"

# --- T8 — stdin invalide ------------------------------------------------------

OUT="$(echo 'pas du json' | (cd "$WORK" && "$BASH_BIN" "$GUARD") 2>/dev/null)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T8 stdin invalide → allow silencieux (fail-open)"
else
  ko "T8 fail-open attendu (rc=$RC), obtenu : $OUT"
fi

# --- T9 — content vide --------------------------------------------------------

OUT="$(run_guard "$(mk_write "$WORK/.claude/agents/test-agent-vide.md" "")")"
[ -z "$OUT" ] && ok "T9 content vide → allow (coquille tolérée)" || ko "T9 allow attendu, obtenu : $OUT"

# --- T10 — extension non-.md ---------------------------------------------------

OUT="$(run_guard "$(mk_write "$WORK/.claude/agents/test-agent-non-conforme.txt" "$NON_CONFORME_MEMOIRE_TOOLS")")"
[ -z "$OUT" ] && ok "T10 extension non-.md → allow" || ko "T10 allow attendu, obtenu : $OUT"

# --- T11 — prefiltre pur-bash --------------------------------------------------

OUT="$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"/tmp/sans-rapport.md","content":"x"}}' | (cd "$WORK" && "$BASH_BIN" "$GUARD") 2>/dev/null)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T11 payload sans la sous-chaine '.claude' → allow (prefiltre pur-bash, zero spawn)"
else
  ko "T11 allow attendu (rc=$RC), obtenu : $OUT"
fi

# --- T12 — frontiere anti-faux-positif -----------------------------------------

mkdir -p "$WORK/my.claude/agents"
OUT="$(run_guard "$(mk_write "$WORK/my.claude/agents/test-agent-non-conforme.md" "$NON_CONFORME_MEMOIRE_TOOLS")")"
[ -z "$OUT" ] && ok "T12 parent 'my.claude/agents' ne matche pas '.claude/agents' → allow" || ko "T12 allow attendu, obtenu : $OUT"

# --- T13 — fail-open : checker absent -------------------------------------------

LONELY="$WORK/lonely/scripts"
mkdir -p "$LONELY"
cp "$GUARD" "$LONELY/guard-agent-write.sh"
OUT="$(printf '%s' "$(mk_write "$WORK/.claude/agents/test-agent-non-conforme.md" "$NON_CONFORME_MEMOIRE_TOOLS")" | (cd "$WORK" && "$BASH_BIN" "$LONELY/guard-agent-write.sh") 2>/dev/null)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T13 checker absent a cote du guard → allow (fail-open, jamais de deny aveugle)"
else
  ko "T13 fail-open attendu (rc=$RC), obtenu : $OUT"
fi

# --- T14 — anti-regression structurelle -----------------------------------------

# Le bloc python est une chaine bash double-quotee (voir guard-agent-write.sh) : les guillemets
# y sont echappes litteralement (\"--strict\"). On grep le motif EXACT tel qu'il apparait dans
# la ligne subprocess.run(...) — pas une regex approximative.
if grep -q 'subprocess\.run(\[\\"bash\\", checker, \\"--file\\", target, \\"--strict\\"\]' "$GUARD"; then
  ok "T14 le guard invoque bien check-agents.sh avec --strict (anti-regression source)"
else
  ko "T14 '--strict' absent (ou deplace) de l invocation du checker dans $GUARD — le durcissement a ete retire"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
