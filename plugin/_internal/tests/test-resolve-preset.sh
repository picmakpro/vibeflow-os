#!/usr/bin/env bash
# Test de resolve-preset.sh — autonome : cas réels (presets.json + module.json du repo) et
# fixtures hostiles (preset vers un module WIP, vers un module absent, fichier cassé).
#
# Chaque cas négatif est un MUTANT : un résolveur qui élaguerait en silence un module WIP, ou
# rendrait une fermeture partielle avec exit 0, doit rendre ce test rouge.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/resolve-preset.sh"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
export VF_MODULES_ROOT="$REPO_ROOT"

pass=0; fail=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-resolve-preset =="

# 1. list → au moins le preset `dev`, 4 colonnes TSV
out=$(bash "$SCRIPT" list 2>/dev/null)
if printf '%s\n' "$out" | grep -q '^dev	'; then
  ok "list : le preset 'dev' est listé"
else
  ko "list : preset 'dev' absent de [$out]"
fi
cols=$(printf '%s\n' "$out" | head -1 | awk -F'\t' '{print NF}')
[ "$cols" -eq 4 ] && ok "list : 4 colonnes TSV (name, titre, description, modules)" \
  || ko "list : $cols colonnes au lieu de 4"

# 2. dev → fermeture contenant dev-orchestrator ET ses deps déclarées (conductor, design-orchestrator)
out=$(bash "$SCRIPT" dev 2>/dev/null)
for m in dev-orchestrator conductor design-orchestrator; do
  printf '%s\n' "$out" | grep -qx "$m" && ok "dev : fermeture contient $m" \
    || ko "dev : $m absent de la fermeture [$out]"
done

# 3. dev-mobile → contient mobile-test (dep transitive de mobile-test-team, jamais recopiée dans le preset)
out=$(bash "$SCRIPT" dev-mobile 2>/dev/null)
printf '%s\n' "$out" | grep -qx "mobile-test" && ok "dev-mobile : mobile-test résolu par transitivité" \
  || ko "dev-mobile : mobile-test absent de [$out]"

# 4. sortie triée, dédupliquée (même contrat que resolve-deps)
sorted=$(printf '%s\n' "$out" | sort -u)
[ "$out" = "$sorted" ] && ok "dev-mobile : sortie triée et dédupliquée" \
  || ko "dev-mobile : sortie non triée/dédupliquée [$out]"

# 5. tout preset du fichier réel se résout (exit 0, sortie non vide)
all_ok=1
while IFS=$'\t' read -r name _rest; do
  [ -n "$name" ] || continue
  r=$(bash "$SCRIPT" "$name" 2>/dev/null) || { all_ok=0; echo "    → $name : échec"; }
  [ -n "$r" ] || { all_ok=0; echo "    → $name : fermeture vide"; }
done < <(bash "$SCRIPT" list 2>/dev/null)
[ "$all_ok" -eq 1 ] && ok "tous les presets réels se résolvent" || ko "au moins un preset réel ne se résout pas"

# 6. preset inconnu → exit non-zéro, message nommant les presets disponibles
errout=$(bash "$SCRIPT" preset-inexistant-xyz 2>&1 >/dev/null); rc=$?
[ "$rc" -ne 0 ] && printf '%s' "$errout" | grep -q 'dev' \
  && ok "preset inconnu → exit non-zéro + liste des presets" \
  || ko "preset inconnu : rc=$rc, stderr=[$errout]"

# --- Fixtures hostiles -------------------------------------------------------
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/mods/ok-mod" "$tmp/mods/wip-mod"
printf '{"name":"ok-mod","requires":[]}\n' > "$tmp/mods/ok-mod/module.json"
printf '{"name":"wip-mod","proposable":false,"requires":[]}\n' > "$tmp/mods/wip-mod/module.json"
cat > "$tmp/presets.json" <<'EOF'
{"presets":[
  {"name":"p-wip","titre":"t","description":"d","modules":["ok-mod","wip-mod"]},
  {"name":"p-absent","titre":"t","description":"d","modules":["ok-mod","module-fantome"]},
  {"name":"p-vide","titre":"t","description":"d","modules":[]},
  {"name":"p-ok","titre":"t","description":"d","modules":["ok-mod"]}
]}
EOF

# 7. MUTANT : preset vers un module proposable:false → refus ENTIER (exit ≠ 0, rien sur stdout)
out=$(VF_MODULES_ROOT="$tmp/mods" VF_PRESETS_FILE="$tmp/presets.json" bash "$SCRIPT" p-wip 2>/dev/null); rc=$?
[ "$rc" -ne 0 ] && [ -z "$out" ] && ok "preset vers un module WIP → refusé en entier (pas d'élagage silencieux)" \
  || ko "preset WIP : rc=$rc, stdout=[$out] (attendu : refus, stdout vide)"

# 8. MUTANT : preset vers un module sans manifeste → exit ≠ 0, stdout vide (pas de fermeture partielle)
out=$(VF_MODULES_ROOT="$tmp/mods" VF_PRESETS_FILE="$tmp/presets.json" bash "$SCRIPT" p-absent 2>/dev/null); rc=$?
[ "$rc" -ne 0 ] && [ -z "$out" ] && ok "preset vers un module absent → exit non-zéro, aucune fermeture partielle" \
  || ko "preset absent : rc=$rc, stdout=[$out]"

# 9. preset sans module → refusé
VF_MODULES_ROOT="$tmp/mods" VF_PRESETS_FILE="$tmp/presets.json" bash "$SCRIPT" p-vide >/dev/null 2>&1
[ $? -ne 0 ] && ok "preset sans module → refusé" || ko "preset vide accepté"

# 10. témoin positif sur la fixture : p-ok → ok-mod seul
out=$(VF_MODULES_ROOT="$tmp/mods" VF_PRESETS_FILE="$tmp/presets.json" bash "$SCRIPT" p-ok 2>/dev/null)
[ "$out" = "ok-mod" ] && ok "fixture p-ok → ok-mod (témoin positif)" || ko "p-ok : attendu [ok-mod] obtenu [$out]"

# 11. fichier de presets cassé → exit ≠ 0
printf '{"presets": "pas un tableau"}\n' > "$tmp/broken.json"
VF_PRESETS_FILE="$tmp/broken.json" bash "$SCRIPT" list >/dev/null 2>&1
[ $? -ne 0 ] && ok "presets.json invalide → exit non-zéro" || ko "presets.json invalide accepté"

# 12. sans argument → usage, exit ≠ 0
bash "$SCRIPT" >/dev/null 2>&1
[ $? -ne 0 ] && ok "sans argument → exit non-zéro" || ko "sans argument accepté"

echo "== résultat : $pass OK / $fail KO =="
[ "$fail" -eq 0 ]
