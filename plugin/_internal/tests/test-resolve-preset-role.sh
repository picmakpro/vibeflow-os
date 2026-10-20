#!/usr/bin/env bash
# Test de resolve-preset.sh list sous un poste (Phase 58, RLPO-06, P58-D-21) — autonome.
# Cas PRE-TRACE-1..3 ; la sortie sans poste est comparée À L'OCTET (cmp -s) à celle de la copie
# gelée d'avant la phase (fixtures/resolve-preset-pre-58.sh = octets de a2ed5094), lancée depuis
# un miroir temporaire de _internal/ (elle résout ses voisins par son propre dossier).
# Aucune syntaxe propre à bash 4 : la suite tourne aussi sous /bin/bash 3.2.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/resolve-preset.sh"
INTERNAL="$(cd "$HERE/.." && pwd)"
FROZEN="$HERE/fixtures/resolve-preset-pre-58.sh"
REPO_ROOT="$(cd "$HERE/../../.." && pwd)"
PLUGIN="$REPO_ROOT/plugin"
ROLES_SH="$INTERNAL/module-roles.sh"
TARGET="$SCRIPT"
MARK="zzSECRETzz"

pass=0; fail=0; skipped=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
OUTS="$TMP/outs"; mkdir -p "$OUTS"; nout=0

echo "== test-resolve-preset-role =="

# run <racine modules> <fichier presets|-> <VAR=val|-> args... -> $RC, $TMP/o, $TMP/e (archive stdout pour PRE-COL4)
run() {
  local root="$1" pf="$2" ev="$3"; shift 3
  local e
  e=(env -u VF_ROLE "VF_MODULES_ROOT=$root")
  [ "$pf" = "-" ] || e+=("VF_PRESETS_FILE=$pf")
  [ "$ev" = "-" ] || e+=("$ev")
  "${e[@]}" bash "$TARGET" "$@" >"$TMP/o" 2>"$TMP/e"; RC=$?
  nout=$((nout+1)); cp "$TMP/o" "$OUTS/$nout"
}
names() { cut -f1 "$1"; }

# ---------- Fixture : dépendance directe et TRANSITIVE vers un module de dev ------------------------
FIX="$TMP/fix"; mkdir -p "$FIX/mods/base" "$FIX/mods/devx" "$FIX/mods/mid"
echo '{"name":"base","requires":[]}' > "$FIX/mods/base/module.json"
echo '{"name":"devx","requires":[],"roles":["dev"]}' > "$FIX/mods/devx/module.json"
echo '{"name":"mid","requires":["devx"]}' > "$FIX/mods/mid/module.json"
cat > "$FIX/presets.json" <<'JSON'
{"presets":[
  {"name":"p-base","titre":"Base","description":"sans dev","modules":["base"]},
  {"name":"p-direct","titre":"Direct","description":"module de dev direct","modules":["devx"]},
  {"name":"p-transitif","titre":"Transitif","description":"requires vers un module de dev","modules":["mid"]},
  {"name":"p-mixte","titre":"Mixte","description":"base plus dev","modules":["base","devx"]}
]}
JSON
FX="$FIX/mods"; FP="$FIX/presets.json"
printf 'p-base\n' > "$TMP/exp-base"
printf 'p-base\np-direct\np-transitif\np-mixte\n' > "$TMP/exp-all"

# Miroir d'_internal/ pour la copie gelée (elle trouve resolve-deps.sh et presets.json par son dossier)
MIR="$TMP/mirror/_internal"; mkdir -p "$MIR"
cp "$FROZEN" "$MIR/resolve-preset.sh"; cp "$INTERNAL/resolve-deps.sh" "$INTERNAL/presets.json" "$MIR/"
frozen_run() { local t="$TARGET"; TARGET="$MIR/resolve-preset.sh"; run "$@"; TARGET="$t"; }

# ---------- PRE-TRACE-1 -----------------------------------------------------------------------------
probe_trace1() {
  run "$FX" "$FP" - list --role product; local rp="$RC"; names "$TMP/o" > "$TMP/n-prod"
  run "$FX" "$FP" - list --role dev;     local rd="$RC"; names "$TMP/o" > "$TMP/n-dev"
  run "$FX" "$FP" - list --role solo;    local rs="$RC"; names "$TMP/o" > "$TMP/n-solo"
  [ "$rp" -eq 0 ] && [ "$rd" -eq 0 ] && [ "$rs" -eq 0 ] \
    && cmp -s "$TMP/n-prod" "$TMP/exp-base" && cmp -s "$TMP/n-dev" "$TMP/exp-all" && cmp -s "$TMP/n-solo" "$TMP/exp-all"
}
probe_trace1 && ok "PRE-TRACE-1 fixture (dépendance directe, transitive, mixte) : product ne voit que p-base ; dev et solo voient les quatre" \
  || ko "PRE-TRACE-1 attendu product=[p-base] dev=solo=[4 presets], obtenu product=[$(tr '\n' ' ' < "$TMP/n-prod")] dev=[$(tr '\n' ' ' < "$TMP/n-dev")] solo=[$(tr '\n' ' ' < "$TMP/n-solo")]"

# ---------- PRE-TRACE-2 : sortie sans poste = octets d'avant la phase -------------------------------
run "$FX" "$FP" - list; cp "$TMP/o" "$TMP/new-fix"
frozen_run "$FX" "$FP" - list; cp "$TMP/o" "$TMP/old-fix"
run "$PLUGIN" - - list; cp "$TMP/o" "$TMP/new-real"
frozen_run "$PLUGIN" - - list; cp "$TMP/o" "$TMP/old-real"
{ cmp -s "$TMP/new-fix" "$TMP/old-fix" && [ -s "$TMP/new-fix" ] && cmp -s "$TMP/new-real" "$TMP/old-real" && [ -s "$TMP/new-real" ]; } \
  && ok "PRE-TRACE-2 list sans poste identique à l'octet (cmp -s) à la copie gelée, fixture et dépôt réel" \
  || ko "PRE-TRACE-2 attendu sortie identique à la copie gelée, obtenu un écart ou une sortie vide"

# ---------- PRE-TRACE-3 : dépôt réel, la liste est DÉRIVÉE de la fermeture --------------------------
run "$PLUGIN" - - list; names "$TMP/o" | LC_ALL=C sort > "$TMP/real-all"
run "$PLUGIN" - - list --role product; RCP="$RC"; names "$TMP/o" | LC_ALL=C sort > "$TMP/real-prod"
LC_ALL=C comm -23 "$TMP/real-all" "$TMP/real-prod" > "$TMP/real-removed"
LC_ALL=C comm -12 "$TMP/real-all" "$TMP/real-prod" > "$TMP/real-kept"
bad=0; detail=""
invisible_in_closure() { # <preset> -> 0 si la fermeture contient un module invisible au poste product
  local p="$1" m
  VF_MODULES_ROOT="$PLUGIN" bash "$SCRIPT" "$p" > "$TMP/clo" 2>/dev/null || { echo "fermeture de $p irrésoluble"; return 2; }
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    [ "$(VF_MODULES_ROOT="$PLUGIN" bash "$ROLES_SH" visible "$m" product 2>/dev/null)" = "no" ] && return 0
  done < "$TMP/clo"
  return 1
}
while IFS= read -r p; do
  [ -n "$p" ] || continue
  invisible_in_closure "$p"; r=$?
  [ "$r" -eq 1 ] || { bad=$((bad+1)); detail="$detail kept:$p(rc$r)"; }
done < "$TMP/real-kept"
while IFS= read -r p; do
  [ -n "$p" ] || continue
  invisible_in_closure "$p"; r=$?
  [ "$r" -eq 0 ] || { bad=$((bad+1)); detail="$detail removed:$p(rc$r)"; }
done < "$TMP/real-removed"
{ [ "$RCP" -eq 0 ] && [ "$bad" -eq 0 ] && [ -s "$TMP/real-all" ]; } \
  && ok "PRE-TRACE-3 dépôt réel, product : $(wc -l < "$TMP/real-kept" | tr -d ' ') presets gardés (fermeture 100% visible), $(wc -l < "$TMP/real-removed" | tr -d ' ') retirés (fermeture avec un module invisible)" \
  || ko "PRE-TRACE-3 attendu rc 0 et filtre conforme à la fermeture, obtenu rc $RCP écarts:$detail"

echo "== Résultat : $pass OK, $fail KO =="
[ "$skipped" -eq 0 ] || echo "   ($skipped SKIP)"
[ "$fail" -eq 0 ]
