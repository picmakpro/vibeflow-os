#!/usr/bin/env bash
# test-guard-file-size.sh — Suite du guard PreToolUse(Edit|Write) Iron Law 300L (ADR-043).
#
# T1 — fichier de code >= 300 lignes sans marqueur → DENY
# T2 — fichier de code >= 300 lignes AVEC marqueur vibeflow:allow-large-file → allow
# T3 — fichier de code court → allow
# T4 — fichier non-code (.md) long → allow
# T5 — fichier inexistant (Write initial) → allow
# T6 — stdin invalide → allow silencieux (fail-open)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD="$(cd "$TESTS_DIR/.." && pwd)/guard-file-size.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-guard-file-size (guard: $GUARD) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for i in $(seq 1 350); do echo "const x$i = $i;"; done > "$WORK/big.ts"
{ echo "// vibeflow:allow-large-file — dette tracée"; for i in $(seq 1 350); do echo "const x$i = $i;"; done; } > "$WORK/big-optout.ts"
for i in $(seq 1 50); do echo "const x$i = $i;"; done > "$WORK/small.ts"
for i in $(seq 1 400); do echo "ligne $i"; done > "$WORK/doc.md"

run_guard() { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1" | bash "$GUARD" 2>/dev/null; }

OUT="$(run_guard "$WORK/big.ts")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"' && echo "$OUT" | grep -q "allow-large-file"; then
  ok "T1 code >= 300L sans marqueur → deny avec échappatoire expliquée"
else
  ko "T1 deny attendu, obtenu : ${OUT:-<vide>}"
fi

OUT="$(run_guard "$WORK/big-optout.ts")"
[ -z "$OUT" ] && ok "T2 marqueur vibeflow:allow-large-file → allow (dette tolérée)" || ko "T2 allow attendu, obtenu : $OUT"

OUT="$(run_guard "$WORK/small.ts")"
[ -z "$OUT" ] && ok "T3 fichier court → allow" || ko "T3 allow attendu, obtenu : $OUT"

OUT="$(run_guard "$WORK/doc.md")"
[ -z "$OUT" ] && ok "T4 fichier non-code → allow" || ko "T4 allow attendu, obtenu : $OUT"

OUT="$(run_guard "$WORK/nexiste-pas.ts")"
[ -z "$OUT" ] && ok "T5 fichier inexistant (création) → allow" || ko "T5 allow attendu, obtenu : $OUT"

OUT="$(echo 'pas du json' | bash "$GUARD" 2>/dev/null)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T6 stdin invalide → allow silencieux (fail-open)"
else
  ko "T6 fail-open (rc=$RC)"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
