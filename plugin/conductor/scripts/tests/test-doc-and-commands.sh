#!/usr/bin/env bash
# test-doc-and-commands.sh — Tests ADR-042 : generate-agent-commands.sh + scaffold-docs.sh.
# Portable, sans réseau. Fabrique un faux lab dans un tmpdir.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GEN="$SCRIPT_DIR/generate-agent-commands.sh"
SCAFFOLD="$SCRIPT_DIR/scaffold-docs.sh"
PASS=0; FAIL=0

ok()    { if [ "$2" = "true" ]; then echo "  ✓ $1"; PASS=$((PASS+1)); else echo "  ✗ $1"; FAIL=$((FAIL+1)); fi; }
exists(){ [ -f "$1" ] && echo true || echo false; }
has()   { grep -qF "$2" "$1" 2>/dev/null && echo true || echo false; }

echo "== test-doc-and-commands (ADR-042) =="

# ---------- generate-agent-commands.sh ----------
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
LAB="$TMP/.claude"
mkdir -p "$LAB/agents"
printf 'name: alpha\ndescription: Agent de test alpha.\n\nCorps alpha.\n' > "$LAB/agents/alpha.md"
printf 'name: beta\n\nCorps beta sans description.\n' > "$LAB/agents/beta.md"
# Bruit : un dossier -references ne doit PAS produire de commande.
mkdir -p "$LAB/agents/alpha-references"
printf 'x\n' > "$LAB/agents/alpha-references/note.md"

VF_TARGET_ROOT="$LAB" bash "$GEN" >/dev/null 2>&1
ok "commande alpha créée"                 "$(exists "$LAB/commands/alpha.md")"
ok "commande beta créée"                  "$(exists "$LAB/commands/beta.md")"
ok "pas de commande pour -references"     "$([ ! -e "$LAB/commands/note.md" ] && echo true || echo false)"
ok "commande référence @agents/alpha.md"  "$(has "$LAB/commands/alpha.md" "@.claude/agents/alpha.md")"
ok "commande dit fenêtre principale"      "$(has "$LAB/commands/alpha.md" "fenêtre principale")"
ok "commande interdit sous-agent Task"    "$(has "$LAB/commands/alpha.md" "sans** déléguer")"
ok "commande porte \$ARGUMENTS"           "$(has "$LAB/commands/alpha.md" '$ARGUMENTS')"
ok "desc agent réutilisée (alpha)"        "$(has "$LAB/commands/alpha.md" "Agent de test alpha.")"

# Idempotence + non-écrasement d'une customisation.
printf 'CUSTOM\n' > "$LAB/commands/alpha.md"
VF_TARGET_ROOT="$LAB" bash "$GEN" >/dev/null 2>&1
ok "commande existante NON écrasée"       "$(has "$LAB/commands/alpha.md" "CUSTOM")"

# Mode --agent ciblé.
rm -f "$LAB/commands/beta.md"
VF_TARGET_ROOT="$LAB" bash "$GEN" --agent beta >/dev/null 2>&1
ok "--agent beta régénère beta"           "$(exists "$LAB/commands/beta.md")"

# ---------- scaffold-docs.sh ----------
TMP2=$(mktemp -d); trap 'rm -rf "$TMP" "$TMP2"' EXIT
cd "$TMP2"

bash "$SCAFFOLD" projet-a projet-b >/dev/null 2>&1
ok "docs/_transverse/INDEX.md créé"       "$(exists "docs/_transverse/INDEX.md")"
ok "docs/_transverse/REFERENCE.md créé"   "$(exists "docs/_transverse/REFERENCE.md")"
ok "docs/projet-a/ contextuel créé"       "$(exists "docs/projet-a/REFERENCE.md")"
ok "docs/projet-b/ contextuel créé"       "$(exists "docs/projet-b/INDEX.md")"

# Idempotence : un doc existant n'est jamais réécrit.
printf 'MINE\n' > "docs/projet-a/REFERENCE.md"
bash "$SCAFFOLD" projet-a projet-b >/dev/null 2>&1
ok "doc existant préservé (idempotent)"   "$(has "docs/projet-a/REFERENCE.md" "MINE")"

# Mono-projet : transverse seul, pas de compartiment.
cd "$TMP"; rm -rf docs
bash "$SCAFFOLD" >/dev/null 2>&1
ok "mono-projet : _transverse seul"       "$(exists "docs/_transverse/INDEX.md")"

echo ""
echo "  PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
