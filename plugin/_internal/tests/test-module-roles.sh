#!/usr/bin/env bash
# Test de module-roles.sh (Phase 58, RLPO-04/05) — autonome.
# Cas : MR-TRACE-1..4 (tracer), MR-VAL-1..3, MR-LIST, MR-REAL, MR-CLOS (+ témoin), MR-USAGE,
# mutants MR-MUT-1 (garde « liste vide » retirée) et MR-MUT-2 (garde « ensemble fermé » retirée).
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/module-roles.sh"
RESOLVE="$(cd "$(dirname "$0")/.." && pwd)/resolve-deps.sh"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLUGIN="$REPO_ROOT/plugin"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

# run <script> <root> args... -> stdout dans $OUT, stderr dans $ERR, code dans $RC
run() {
  local s="$1" root="$2"; shift 2
  OUT="$(env -u VF_ROLE VF_MODULES_ROOT="$root" bash "$s" "$@" 2>"$TMPD/err")"; RC=$?
  ERR="$(cat "$TMPD/err")"
}

echo "== test-module-roles =="

# --- tracer
run "$SCRIPT" "$PLUGIN" visible dev-orchestrator product
[ "$OUT" = "no" ] && [ $RC -eq 0 ] && ok "MR-TRACE-1 dev-orchestrator invisible à product" || ko "MR-TRACE-1 attendu [no] rc 0, obtenu [$OUT] rc $RC"
run "$SCRIPT" "$PLUGIN" visible dev-orchestrator dev; a="$OUT"
run "$SCRIPT" "$PLUGIN" visible dev-orchestrator solo; b="$OUT"
[ "$a/$b" = "yes/yes" ] && ok "MR-TRACE-2 dev-orchestrator visible à dev et solo" || ko "MR-TRACE-2 attendu [yes/yes] obtenu [$a/$b]"
run "$SCRIPT" "$PLUGIN" visible conductor product
[ "$OUT" = "yes" ] && ok "MR-TRACE-3 clé absente = visible à product" || ko "MR-TRACE-3 attendu [yes] obtenu [$OUT]"
run "$SCRIPT" "$PLUGIN" visible dev-orchestrator qa
if [ $RC -eq 1 ] && [ -z "$OUT" ] && printf '%s' "$ERR" | grep -q 'poste invalide' && ! printf '%s' "$ERR" | grep -q 'qa'; then
  ok "MR-TRACE-4 poste inconnu refusé sans réimprimer la valeur"
else ko "MR-TRACE-4 attendu rc 1, stdout vide, 'poste invalide' sans 'qa' ; obtenu rc $RC out [$OUT] err [$ERR]"; fi

# --- validate
run "$SCRIPT" "$PLUGIN" validate
[ $RC -eq 0 ] && [ -z "$OUT" ] && [ -z "$ERR" ] && ok "MR-VAL-1 validate du dépôt réel silencieux" || ko "MR-VAL-1 attendu rc 0 silencieux, obtenu rc $RC out [$OUT] err [$ERR]"

mkfix() { # mkfix <racine> <nom> <fragment roles ou vide> [requires JSON]
  mkdir -p "$1/$2"
  if [ -n "$3" ]; then printf '{"name":"%s","requires":%s,"roles":%s}\n' "$2" "${4:-[]}" "$3" > "$1/$2/module.json"
  else printf '{"name":"%s","requires":%s}\n' "$2" "${4:-[]}" > "$1/$2/module.json"; fi
}
FX="$TMPD/fx"; mkdir -p "$FX"
i=0
for val in '[]' '["qa"]' '"dev"' 'null' '["solo"]' '["product","qa"]'; do
  i=$((i+1)); n="bad$i"; mkfix "$FX" "$n" "$val"
  run "$SCRIPT" "$FX" validate "$n"; r1=$RC; o1="$OUT"; e1="$ERR"
  run "$SCRIPT" "$FX" visible "$n" product
  if [ $r1 -eq 1 ] && [ -z "$o1" ] && printf '%s' "$e1" | grep -q "$n" && [ $RC -eq 1 ]; then
    ok "MR-VAL-2 roles=$val refusé (validate+visible)"
  else ko "MR-VAL-2 roles=$val : attendu rc 1/1 stdout vide nom cité ; obtenu validate rc $r1 [$e1] visible rc $RC"; fi
done
mkfix "$FX" good1 '["product"]'; mkfix "$FX" good2 '["dev","product"]'
run "$SCRIPT" "$FX" validate good1 good2; r=$RC
run "$SCRIPT" "$FX" visible good1 product; v1="$OUT"
run "$SCRIPT" "$FX" visible good2 product; v2="$OUT"
[ $r -eq 0 ] && [ "$v1/$v2" = "yes/yes" ] && ok "MR-VAL-3 listes valides acceptées" || ko "MR-VAL-3 attendu rc 0 yes/yes obtenu rc $r $v1/$v2"

# --- list / table réelle
ALL="$(for f in "$PLUGIN"/*/module.json; do jq -r '.name' "$f"; done | LC_ALL=C sort)"
DEVS="$(printf 'dev-orchestrator\nmobile-test\nmobile-test-team\n')"
run "$SCRIPT" "$PLUGIN" list product; LP="$OUT"
exp="$(printf '%s\n' "$ALL" | LC_ALL=C sort | comm -23 - <(printf '%s\n' "$DEVS" | LC_ALL=C sort))"
run "$SCRIPT" "$PLUGIN" list dev; LD="$OUT"
run "$SCRIPT" "$PLUGIN" list solo; LS="$OUT"
if [ "$LP" = "$exp" ] && [ "$LD" = "$ALL" ] && [ "$LS" = "$ALL" ]; then ok "MR-LIST product = tous moins les trois ; dev et solo = tous"
else ko "MR-LIST product attendu [$exp] obtenu [$LP] ; dev/solo différents de la liste complète : $([ "$LD" = "$ALL" ] && echo non || echo oui)"; fi
REAL="$(for f in "$PLUGIN"/*/module.json; do jq -r 'select(has("roles")) | select(.roles == ["dev"]) | .name' "$f"; done | LC_ALL=C sort)"
REALANY="$(for f in "$PLUGIN"/*/module.json; do jq -r 'select(has("roles")) | .name' "$f"; done | LC_ALL=C sort)"
[ "$REAL" = "$DEVS" ] && [ "$REALANY" = "$DEVS" ] && ok "MR-REAL exactement trois modules à [\"dev\"]" || ko "MR-REAL attendu [$DEVS] obtenu [$REALANY]"

# --- fermeture : fuites <racine> <poste> -> modules requis invisibles au poste
fuites() {
  local root="$1" poste="$2" vis mod clos
  vis="$(env -u VF_ROLE VF_MODULES_ROOT="$root" bash "$SCRIPT" list "$poste" | LC_ALL=C sort)"
  clos="$(for mod in $vis; do VF_MODULES_ROOT="$root" bash "$RESOLVE" "$mod"; done | LC_ALL=C sort -u)"
  comm -23 <(printf '%s\n' "$clos") <(printf '%s\n' "$vis")
}
f="$(fuites "$PLUGIN" product)"
[ -z "$f" ] && ok "MR-CLOS aucune fuite dans la fermeture de product" || ko "MR-CLOS fuite : [$f]"
mkfix "$TMPD/clos" alpha "" '["beta"]'; mkfix "$TMPD/clos" beta '["dev"]'
f="$(fuites "$TMPD/clos" product)"
[ "$f" = "beta" ] && ok "MR-CLOS-TEMOIN la vérification rougit sur une fuite (beta)" || ko "MR-CLOS-TEMOIN attendu [beta] obtenu [$f]"

# --- usage
run "$SCRIPT" "$PLUGIN"; r1=$RC; e1="$ERR"
run "$SCRIPT" "$PLUGIN" frobnicate; r2=$RC
run "$SCRIPT" "$PLUGIN" visible conductor; r3=$RC; e3="$ERR"
run "$SCRIPT" "$PLUGIN" visible ../x product; r4=$RC
if [ $r1 -eq 1 ] && [ -n "$e1" ] && [ $r2 -eq 1 ] && [ $r3 -eq 1 ] && [ -n "$e3" ] && [ $r4 -eq 1 ]; then ok "MR-USAGE usages et nom de module invalides refusés"
else ko "MR-USAGE attendu rc 1 partout ; obtenu $r1 $r2 $r3 $r4"; fi

# --- mutants
mutate() { # mutate <fragment exact> <sortie> : remplace le fragment par `false`
  awk -v pat="$1" '{ i=index($0, pat); if (i>0) { $0=substr($0,1,i-1) "false" substr($0,i+length(pat)) } print }' "$SCRIPT" > "$2"
}
mut_case() { # mut_case <id> <fragment> <valeur roles> 
  local id="$1" frag="$2" val="$3" m="$TMPD/mut-$1.sh" mn="mut$1"
  mutate "$frag" "$m"
  if cmp -s "$m" "$SCRIPT"; then ko "$id mutant NON OPPOSABLE (identique à l'original)"; return; fi
  if ! bash -n "$m" 2>/dev/null; then ko "$id le mutant n'est pas un script valide"; return; fi
  mkfix "$FX" "$mn" "$val"
  run "$m" "$FX" validate "$mn"; local rm_=$RC
  run "$SCRIPT" "$FX" validate "$mn"; local ro=$RC
  if [ $rm_ -eq 0 ] && [ $ro -eq 1 ]; then ok "$id mutant tué : roles=$val accepté par le mutant (rc 0), refusé par l'original (rc 1)"
  else ko "$id rc_mutant=$rm_ (devait être 0) rc_original=$ro (attendu 1)"; fi
}
mut_case MR-MUT-1 '(.roles|length)==0' '[]'
mut_case MR-MUT-2 '(.roles|any(.[]; (.=="product" or .=="dev")|not))' '["qa"]'

echo "== resultat : $pass ok, $fail ko =="
[ "$fail" -eq 0 ]
