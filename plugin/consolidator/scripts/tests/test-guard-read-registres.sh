#!/usr/bin/env bash
# test-guard-read-registres.sh — Suite du guard PreToolUse(Read) index-first (ADR-043).
#
# T1 — registre long lu sans offset/limit → DENY (JSON permissionDecision)
# T2 — lecture avec limit borné (index) → allow
# T3 — lecture offset + limit borné (entrée ciblée) → allow
# T4 — registre court (≤ 150 lignes) → allow
# T5 — fichier hors .claude/memory → allow
# T6 — registre en archive/ → allow
# T7 — stdin invalide → allow silencieux (fail-open, exit 0)
# T8 — legacy ADR.md long → DENY (labs non migrés couverts)
# T9 — BLK-007a : offset SEUL (sans limit) → DENY (fenêtre non bornée)
# T10 — BLK-007b : limit énorme (100000) → DENY (plafond VF_GUARD_MAX_READ)
# T11 — limit juste au-dessus du plafond (61 vs 60) → DENY ; au plafond (60) → allow

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD="$(cd "$TESTS_DIR/.." && pwd)/guard-read-registres.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-guard-read-registres (guard: $GUARD) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
MEM="$WORK/lab/.claude/memory"
mkdir -p "$MEM/archive"

long_file() { for i in $(seq 1 200); do echo "ligne $i"; done > "$1"; }
long_file "$MEM/DECISIONS.md"
long_file "$MEM/ADR.md"
long_file "$MEM/archive/DECISIONS.md"
for i in $(seq 1 30); do echo "ligne $i"; done > "$MEM/BLOCKERS.md"
long_file "$WORK/lab/notes.md"

run_guard() { echo "$1" | bash "$GUARD" 2>/dev/null; }
payload() { printf '{"tool_name":"Read","tool_input":{"file_path":"%s"%s}}' "$1" "${2:-}"; }

# T1 — non ciblé sur registre long → deny
OUT="$(run_guard "$(payload "$MEM/DECISIONS.md")")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"' && echo "$OUT" | grep -q "index"; then
  ok "T1 lecture non ciblée d'un registre long → deny avec consigne index-first"
else
  ko "T1 deny attendu, obtenu : ${OUT:-<vide>}"
fi

# T2 — avec limit → allow
OUT="$(run_guard "$(payload "$MEM/DECISIONS.md" ',"limit":40')")"
[ -z "$OUT" ] && ok "T2 lecture d'index (limit) → allow" || ko "T2 allow attendu, obtenu : $OUT"

# T3 — avec offset → allow
OUT="$(run_guard "$(payload "$MEM/DECISIONS.md" ',"offset":120,"limit":30')")"
[ -z "$OUT" ] && ok "T3 lecture ciblée (offset/limit) → allow" || ko "T3 allow attendu, obtenu : $OUT"

# T4 — registre court → allow
OUT="$(run_guard "$(payload "$MEM/BLOCKERS.md")")"
[ -z "$OUT" ] && ok "T4 registre court (≤150 lignes) → allow" || ko "T4 allow attendu, obtenu : $OUT"

# T5 — hors memory → allow
OUT="$(run_guard "$(payload "$WORK/lab/notes.md")")"
[ -z "$OUT" ] && ok "T5 fichier hors .claude/memory → allow" || ko "T5 allow attendu, obtenu : $OUT"

# T6 — archive → allow
OUT="$(run_guard "$(payload "$MEM/archive/DECISIONS.md")")"
[ -z "$OUT" ] && ok "T6 registre archivé → allow" || ko "T6 allow attendu, obtenu : $OUT"

# T7 — stdin invalide → fail-open
OUT="$(echo 'pas du json' | bash "$GUARD" 2>/dev/null)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T7 stdin invalide → allow silencieux (fail-open)"
else
  ko "T7 fail-open (rc=$RC, out=$OUT)"
fi

# T8 — legacy ADR.md → deny
OUT="$(run_guard "$(payload "$MEM/ADR.md")")"
echo "$OUT" | grep -q '"permissionDecision": *"deny"' && ok "T8 legacy ADR.md long → deny" || ko "T8 deny legacy attendu"

# T9 — BLK-007a : offset seul, sans limit → deny (la faille : Read(offset=1) lisait tout)
OUT="$(run_guard "$(payload "$MEM/DECISIONS.md" ',"offset":1')")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"' && echo "$OUT" | grep -q "ne borne rien"; then
  ok "T9 offset seul (sans limit) → deny (BLK-007a)"
else
  ko "T9 deny attendu pour offset seul, obtenu : ${OUT:-<vide>}"
fi

# T10 — BLK-007b : limit énorme → deny
OUT="$(run_guard "$(payload "$MEM/DECISIONS.md" ',"offset":1,"limit":100000')")"
echo "$OUT" | grep -q '"permissionDecision": *"deny"' && ok "T10 limit=100000 → deny (BLK-007b)" || ko "T10 deny attendu, obtenu : ${OUT:-<vide>}"

# T11 — frontière du plafond (défaut 60)
OUT_61="$(run_guard "$(payload "$MEM/DECISIONS.md" ',"limit":61')")"
OUT_60="$(run_guard "$(payload "$MEM/DECISIONS.md" ',"limit":60')")"
if echo "$OUT_61" | grep -q '"permissionDecision": *"deny"' && [ -z "$OUT_60" ]; then
  ok "T11 limit=61 → deny · limit=60 → allow (frontière plafond)"
else
  ko "T11 frontière plafond (61: ${OUT_61:-allow} · 60: ${OUT_60:-allow})"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
