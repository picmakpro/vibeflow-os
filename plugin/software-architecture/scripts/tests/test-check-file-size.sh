#!/usr/bin/env bash
# Test de check-file-size.sh — autonome (crée des fixtures temporaires)
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-file-size.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }

gen() { # gen <file> <nlines>
  local f="$1" n="$2"; mkdir -p "$(dirname "$f")"
  : > "$f"; for ((i=1;i<=n;i++)); do echo "const x$i = $i;" >> "$f"; done
}

echo "== test-check-file-size =="

# 1. Petit fichier → OK (exit 0)
gen "$TMP/small.ts" 100
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 bash "$SCRIPT" "$TMP/small.ts" >/dev/null 2>&1
[ $? -eq 0 ] && ok "petit fichier (100L) → exit 0" || ko "petit fichier devrait passer"

# 2. Gros fichier → blocage (exit 2)
gen "$TMP/big.ts" 320
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 bash "$SCRIPT" "$TMP/big.ts" >/dev/null 2>&1
[ $? -eq 2 ] && ok "gros fichier (320L) → exit 2 (blocage)" || ko "gros fichier devrait bloquer"

# 3. Gros fichier avec marqueur opt-out → toléré (exit 0)
gen "$TMP/legacy.ts" 320
sed -i.bak '1s/^/\/\/ vibeflow:allow-large-file\n/' "$TMP/legacy.ts" 2>/dev/null || \
  { printf '// vibeflow:allow-large-file\n%s' "$(cat "$TMP/legacy.ts")" > "$TMP/legacy.ts.new" && mv "$TMP/legacy.ts.new" "$TMP/legacy.ts"; }
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 bash "$SCRIPT" "$TMP/legacy.ts" >/dev/null 2>&1
[ $? -eq 0 ] && ok "marqueur opt-out → exit 0 (toléré)" || ko "opt-out devrait tolérer"

# 4. Fichier non-code (.md) → ignoré
gen "$TMP/doc.md" 500
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 bash "$SCRIPT" "$TMP/doc.md" >/dev/null 2>&1
[ $? -eq 0 ] && ok "fichier non-code (.md 500L) → ignoré" || ko ".md devrait être ignoré"

echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ]
