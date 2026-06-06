#!/usr/bin/env bash
# Test de build-module-catalog.sh — ISOLÉ (fixtures mktemp via VF_MODULES_ROOT) + cas repo réel.
# Convention TESTING.md / modèle test-resolve-deps.sh. zsh aliase grep → on invoque le script
# via `bash` et on utilise `command grep` pour ne jamais hériter d'un alias.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/build-module-catalog.sh"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-build-module-catalog =="

# ---------- Fixture isolée : 2 modules avec module.json + 1 dossier SANS module.json ----------
FIX=$(mktemp -d)
trap 'rm -rf "$FIX"' EXIT

mkdir -p "$FIX/zeta" "$FIX/alpha" "$FIX/sans-manifeste"
cat > "$FIX/zeta/module.json" <<'JSON'
{ "name": "zeta", "version": "v1.0.0", "type": "single-skill", "description": "Module Zeta de test.", "requires": [] }
JSON
cat > "$FIX/alpha/module.json" <<'JSON'
{ "name": "alpha", "version": "v1.0.0", "type": "single-skill", "description": "Module Alpha de test.", "requires": [] }
JSON
# Dossier volontairement SANS module.json — doit être exclu du catalogue.
: > "$FIX/sans-manifeste/README.md"

fix_out=$(VF_MODULES_ROOT="$FIX" bash "$SCRIPT" 2>/dev/null)

# (a) sortie triée : alpha avant zeta
first=$(printf '%s\n' "$fix_out" | head -1 | cut -f1)
[ "$first" = "alpha" ] && ok "fixture : sortie triée (alpha en premier)" \
  || ko "fixture : tri attendu alpha en premier, obtenu [$first]"

# (b) dossier sans module.json exclu (jamais de ligne 'sans-manifeste')
if printf '%s\n' "$fix_out" | command grep -q '^sans-manifeste'; then
  ko "fixture : le dossier sans module.json ne doit PAS apparaître"
else
  ok "fixture : dossier sans module.json exclu"
fi

# (c) chaque ligne a une description non vide (champ 2 après TAB)
desc_ok=1
while IFS= read -r line; do
  [ -n "$line" ] || continue
  d=$(printf '%s' "$line" | cut -f2)
  [ -n "$d" ] || desc_ok=0
done <<< "$fix_out"
[ "$desc_ok" -eq 1 ] && ok "fixture : chaque ligne a une description non vide" \
  || ko "fixture : au moins une description vide"

# Compte de modules de la fixture = 2 (alpha + zeta)
nfix=$(printf '%s\n' "$fix_out" | command grep -c .)
[ "$nfix" -eq 2 ] && ok "fixture : 2 modules listés" \
  || ko "fixture : attendu 2 modules, obtenu $nfix"

# ---------- Cas repo réel : exactement 8 modules, validator + sa description présents ----------
real_out=$(VF_MODULES_ROOT="$REPO_ROOT" bash "$SCRIPT" 2>/dev/null)

nreal=$(printf '%s\n' "$real_out" | command grep -c .)
[ "$nreal" -eq 8 ] && ok "repo réel : 8 modules listés" \
  || ko "repo réel : attendu 8 modules, obtenu $nreal"

# validator présent ET avec une description non vide
vline=$(printf '%s\n' "$real_out" | command grep '^validator	' || true)
if [ -n "$vline" ] && [ -n "$(printf '%s' "$vline" | cut -f2)" ]; then
  ok "repo réel : validator présent avec description"
else
  ko "repo réel : validator + description attendus, obtenu [$vline]"
fi

echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ]
