#!/usr/bin/env bash
# Test de resolve-deps.sh — autonome (pointe sur les vrais module.json du repo via VF_MODULES_ROOT)
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/resolve-deps.sh"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export VF_MODULES_ROOT="$REPO_ROOT"

pass=0; fail=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-resolve-deps =="

# 1. validator → fermeture transitive {consolidator, infrastructure-audit, validator} (triée, 3 lignes)
out=$(bash "$SCRIPT" validator 2>/dev/null)
exp=$(printf 'consolidator\ninfrastructure-audit\nvalidator')
[ "$out" = "$exp" ] && ok "validator → consolidator, infrastructure-audit, validator (3 lignes triées)" \
  || ko "validator: attendu [$exp] obtenu [$out]"

# 2. consolidator (sans requires) → lui-même seul (1 ligne)
out=$(bash "$SCRIPT" consolidator 2>/dev/null)
[ "$out" = "consolidator" ] && ok "consolidator → consolidator seul (1 ligne)" \
  || ko "consolidator: attendu [consolidator] obtenu [$out]"

# 3. validator consolidator → pas de doublon (consolidator une seule fois)
out=$(bash "$SCRIPT" validator consolidator 2>/dev/null)
n=$(printf '%s\n' "$out" | grep -c '^consolidator$')
[ "$n" -eq 1 ] && ok "validator consolidator → consolidator non dupliqué" \
  || ko "doublon: consolidator apparaît $n fois"

# 4. module inconnu → exit non-zéro
bash "$SCRIPT" module-inexistant-xyz >/dev/null 2>&1
[ $? -ne 0 ] && ok "module inconnu → exit non-zéro" \
  || ko "module inconnu devrait échouer (exit non-zéro)"

# 5. sortie triée alphabétiquement (consolidator < infrastructure-audit < validator)
out=$(bash "$SCRIPT" validator 2>/dev/null)
sorted=$(printf '%s\n' "$out" | sort)
[ "$out" = "$sorted" ] && ok "sortie triée alphabétiquement" \
  || ko "sortie non triée: [$out]"

echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ]
