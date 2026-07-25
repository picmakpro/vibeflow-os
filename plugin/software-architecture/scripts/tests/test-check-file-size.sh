#!/usr/bin/env bash
# Test de check-file-size.sh — autonome (crée des fixtures temporaires)
#
# 1-4 : seuils, marqueur opt-out, périmètre code/non-code
# 5   : ARC-05 — 300 lignes SANS newline finale → blocage (wc -l disait 299 → passait)
# 6-7 : ARC-04 — --all sans mapfile (compat bash 3.2 macOS, plus de rc=127)
# 8   : ARC-04 — --staged sans mapfile (pre-commit) dans un repo git temporaire
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-file-size.sh"
# Exécuter le script avec le bash qui exécute la suite (/bin/bash → validation 3.2 réelle).
BASH_BIN="${BASH:-bash}"
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
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" "$TMP/small.ts" >/dev/null 2>&1
[ $? -eq 0 ] && ok "petit fichier (100L) → exit 0" || ko "petit fichier devrait passer"

# 2. Gros fichier → blocage (exit 2)
gen "$TMP/big.ts" 320
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" "$TMP/big.ts" >/dev/null 2>&1
[ $? -eq 2 ] && ok "gros fichier (320L) → exit 2 (blocage)" || ko "gros fichier devrait bloquer"

# 3. Gros fichier avec marqueur opt-out → toléré (exit 0)
gen "$TMP/legacy.ts" 320
sed -i.bak '1s/^/\/\/ vibeflow:allow-large-file\n/' "$TMP/legacy.ts" 2>/dev/null || \
  { printf '// vibeflow:allow-large-file\n%s' "$(cat "$TMP/legacy.ts")" > "$TMP/legacy.ts.new" && mv "$TMP/legacy.ts.new" "$TMP/legacy.ts"; }
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" "$TMP/legacy.ts" >/dev/null 2>&1
[ $? -eq 0 ] && ok "marqueur opt-out → exit 0 (toléré)" || ko "opt-out devrait tolérer"

# 4. Fichier non-code (.md) → ignoré
gen "$TMP/doc.md" 500
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" "$TMP/doc.md" >/dev/null 2>&1
[ $? -eq 0 ] && ok "fichier non-code (.md 500L) → ignoré" || ko ".md devrait être ignoré"

# 5. ARC-05 : 300 lignes SANS newline finale → blocage (avant : wc -l = 299 → passait)
{ for ((i=1;i<300;i++)); do echo "const n$i = $i;"; done; printf 'const n300 = 300;'; } > "$TMP/nonewline.ts"
VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" "$TMP/nonewline.ts" >/dev/null 2>&1
[ $? -eq 2 ] && ok "ARC-05 : 300L sans newline finale → exit 2 (compte exact)" || ko "ARC-05 : off-by-one, 300L sans \\n final devrait bloquer"

# 6. ARC-04 : --all sans mapfile → détecte la violation (exit 2, PAS 127 sous bash 3.2)
mkdir -p "$TMP/proj/src"
gen "$TMP/proj/src/gros.ts" 320
(cd "$TMP/proj" && VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" --all >/dev/null 2>&1)
rc=$?
[ "$rc" -eq 2 ] && ok "ARC-04 : --all → exit 2 sur violation (pas de mapfile)" || ko "ARC-04 : --all devrait sortir 2, obtenu rc=$rc"

# 7. ARC-04 : --all sans violation → exit 0
mkdir -p "$TMP/proj-ok/src"
gen "$TMP/proj-ok/src/petit.ts" 50
(cd "$TMP/proj-ok" && VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" --all >/dev/null 2>&1)
rc=$?
[ "$rc" -eq 0 ] && ok "ARC-04 : --all propre → exit 0" || ko "ARC-04 : --all propre devrait sortir 0, obtenu rc=$rc"

# 8. ARC-04 : --staged (pre-commit) dans un repo git temporaire
mkdir -p "$TMP/repo"
gen "$TMP/repo/enorme.ts" 320
gen "$TMP/repo/mini.ts" 30
if (cd "$TMP/repo" && git init -q . && git add enorme.ts mini.ts) >/dev/null 2>&1; then
  (cd "$TMP/repo" && VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" --staged >/dev/null 2>&1)
  rc=$?
  [ "$rc" -eq 2 ] && ok "ARC-04 : --staged avec gros fichier indexé → exit 2 (pas de mapfile)" || ko "ARC-04 : --staged devrait sortir 2, obtenu rc=$rc"
  (cd "$TMP/repo" && git rm --cached -q enorme.ts && VF_ARCH_WARN=250 VF_ARCH_BLOCK=300 "$BASH_BIN" "$SCRIPT" --staged >/dev/null 2>&1)
  rc=$?
  [ "$rc" -eq 0 ] && ok "ARC-04 : --staged propre → exit 0" || ko "ARC-04 : --staged propre devrait sortir 0, obtenu rc=$rc"
else
  ko "ARC-04 : impossible d'initialiser le repo git de test"
fi

# 9. VG-6 (F13) : aucun argument → erreur d'usage exit 3 (avant : exit 0 = faux vert)
"$BASH_BIN" "$SCRIPT" >/dev/null 2>&1
rc=$?
[ "$rc" -eq 3 ] && ok "VG-6 : sans argument → exit 3 (erreur d'usage, plus de faux vert)" || ko "VG-6 : sans argument devrait sortir 3, obtenu rc=$rc"

echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ]
