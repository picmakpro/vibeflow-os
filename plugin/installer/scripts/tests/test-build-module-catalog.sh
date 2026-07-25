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

# ---------- Fixture isolée : optionnels + 1 mandatory + 1 proposable:false + 1 sans manifeste ----------
FIX=$(mktemp -d)
trap 'rm -rf "$FIX"' EXIT

mkdir -p "$FIX/zeta" "$FIX/alpha" "$FIX/boss" "$FIX/cache" "$FIX/sans-manifeste"
cat > "$FIX/zeta/module.json" <<'JSON'
{ "name": "zeta", "version": "v1.0.0", "type": "single-skill", "description": "Module Zeta de test.", "requires": [] }
JSON
cat > "$FIX/alpha/module.json" <<'JSON'
{ "name": "alpha", "version": "v1.0.0", "type": "single-skill", "description": "Module Alpha de test.", "requires": [] }
JSON
# Module obligatoire (baseline) — doit sortir avec role=mandatory.
cat > "$FIX/boss/module.json" <<'JSON'
{ "name": "boss", "version": "v1.0.0", "type": "agent", "description": "Module Boss obligatoire.", "mandatory": true, "requires": [] }
JSON
# Module non proposable (WIP) — doit être EXCLU du catalogue.
cat > "$FIX/cache/module.json" <<'JSON'
{ "name": "cache", "version": "v1.0.0", "type": "doc-only", "description": "Module caché WIP.", "proposable": false, "requires": [] }
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

# (b2) module proposable:false EXCLU (jamais de ligne 'cache')
if printf '%s\n' "$fix_out" | command grep -q '^cache	'; then
  ko "fixture : un module proposable:false ne doit PAS apparaître"
else
  ok "fixture : module proposable:false exclu (WIP)"
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

# (d) colonne role : boss=mandatory, alpha/zeta=optional
bossrole=$(printf '%s\n' "$fix_out" | command grep '^boss	' | cut -f3)
[ "$bossrole" = "mandatory" ] && ok "fixture : boss marqué mandatory" \
  || ko "fixture : boss attendu role=mandatory, obtenu [$bossrole]"
alpharole=$(printf '%s\n' "$fix_out" | command grep '^alpha	' | cut -f3)
[ "$alpharole" = "optional" ] && ok "fixture : alpha marqué optional (défaut)" \
  || ko "fixture : alpha attendu role=optional, obtenu [$alpharole]"

# Compte de modules de la fixture = 3 (alpha + boss + zeta ; cache exclu)
nfix=$(printf '%s\n' "$fix_out" | command grep -c .)
[ "$nfix" -eq 3 ] && ok "fixture : 3 modules listés (cache exclu)" \
  || ko "fixture : attendu 3 modules, obtenu $nfix"

# ---------- Cas repo réel : 1 ligne par module.json proposable ; conductor=mandatory ----------
real_out=$(VF_MODULES_ROOT="$REPO_ROOT" bash "$SCRIPT" 2>/dev/null)

nreal=$(printf '%s\n' "$real_out" | command grep -c .)
# Attendu = nombre de module.json sur disque MOINS ceux marqués proposable:false (bundles WIP).
ndisk=$(find "$REPO_ROOT" -mindepth 2 -maxdepth 2 -name module.json | command grep -c .)
nhidden=$(find "$REPO_ROOT" -mindepth 2 -maxdepth 2 -name module.json -exec jq -r '.proposable == false' {} \; | command grep -c '^true$' || true)
nexpected=$((ndisk - nhidden))
{ [ "$nreal" -eq "$nexpected" ] && [ "$nreal" -ge 8 ]; } && ok "repo réel : $nreal modules listés (= $ndisk sur disque − $nhidden non proposables)" \
  || ko "repo réel : attendu $nexpected modules (≥8), obtenu $nreal"

# conductor présent ET marqué mandatory (baseline obligatoire)
cline=$(printf '%s\n' "$real_out" | command grep '^conductor	' || true)
crole=$(printf '%s' "$cline" | cut -f3)
if [ -n "$cline" ] && [ "$crole" = "mandatory" ]; then
  ok "repo réel : conductor présent et mandatory"
else
  ko "repo réel : conductor mandatory attendu, obtenu [$cline]"
fi

# les 3 bundles métier sont matérialisés (proposable:true, v2.0.0 chacun) et
# DOIVENT apparaître au catalogue
for bundle in content-bundle growth-bundle business-pilot-bundle; do
  if printf '%s\n' "$real_out" | command grep -qE "^${bundle}	"; then
    ok "repo réel : ${bundle} (matérialisé, proposable:true) présent au catalogue"
  else
    ko "repo réel : ${bundle} manquant au catalogue alors que proposable:true"
  fi
done

# validator présent ET avec une description non vide
vline=$(printf '%s\n' "$real_out" | command grep '^validator	' || true)
if [ -n "$vline" ] && [ -n "$(printf '%s' "$vline" | cut -f2)" ]; then
  ok "repo réel : validator présent avec description"
else
  ko "repo réel : validator + description attendus, obtenu [$vline]"
fi

echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ]
