#!/usr/bin/env bash
# test-check-python-isolation.sh — Suite de scripts/check-python-isolation.sh.
#
# La discriminance est prouvée par MUTATION, organe par organe : une suite qui n'exercerait que
# « propre → 0 / sale → 1 » resterait verte si le détecteur s'éteignait, si l'échappatoire cessait
# d'être lue, ou si l'exclusion des suites (`*/tests/*`) disparaissait.
#   - MUT1 : détecteur neutralisé → le dépôt SALE doit devenir vert (donc le gate le voyait) ;
#   - MUT2 : marqueur `vf-py-isolation-ok` non lu → le dépôt marqué (vert) doit devenir ROUGE ;
#   - MUT3 : exclusion `*/tests/*` retirée → le dépôt dont seul un fichier de test est sale doit
#            devenir ROUGE (l'exclusion est réellement appliquée, pas décorative) ;
#   - MUT4 : saut du fichier lancé (`python3 "$f" < x`) retiré → ce dépôt (vert) doit devenir ROUGE.
# Fixtures : dépôts git JETABLES sous mktemp -d. Les littéraux fautifs sont assemblés à l'exécution
# (variable $PY) : cette suite est un fichier versionné, hors du balayage (`*/tests/*`), mais on ne
# s'appuie pas sur cette exclusion pour sa propre propreté.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-python-isolation.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS + 1)); echo "  ok  $1"; }
ko() { FAIL=$((FAIL + 1)); echo "  KO  $1 — $2"; }
TMP="$(mktemp -d "${TMPDIR:-/tmp}/test-cpi.XXXXXX")" || exit 3
trap 'rm -rf "$TMP"' EXIT
PYB="py""thon"; PY="${PYB}3"

mkrepo() { # <nom> → crée $TMP/<nom> (dépôt git avec plugin/x/scripts/)
  local d="$TMP/$1"; mkdir -p "$d/plugin/x/scripts" "$d/scripts" "$d/.github"
  git -C "$d" init -q; printf '%s\n' "$d"
}
put() { # <repo> <chemin relatif> <contenu>
  mkdir -p "$(dirname "$1/$2")"; printf '%s\n' "$3" > "$1/$2"; git -C "$1" add -- "$2" >/dev/null 2>&1
}
run() { # <script> <repo> → rc
  bash "$1" --path "$2" >"$TMP/out" 2>"$TMP/err"; return $?
}
expect() { # <libellé> <rc attendu> <script> <repo>
  local rc; run "$3" "$4"; rc=$?
  if [ "$rc" -eq "$2" ]; then ok "$1 → $rc"; else ko "$1" "rc=$rc (attendu $2) : $(head -c 160 "$TMP/err")"; fi
}

echo "== formes fautives (chacune doit rougir : 1) =="
i=0
while IFS= read -r line; do
  i=$((i + 1)); r="$(mkrepo "bad$i")"; put "$r" plugin/x/scripts/a.sh "$line"; put "$r" plugin/x/scripts/b.sh "$PY -I -c 'import json'"
  expect "fautif : $line" 1 "$SCRIPT" "$r"
done <<EOF
$PY -c 'import json'
x=\$($PY -c 'import json')
"\$PYBIN" -c 'import json'
printf x | "\$pybin" - "\$f" <<'P'
$PY - <<'P'
\$py_invoke <<'P'
py -3 -c ''
$PY -u -c 'import json'
timeout 5 \$cand -c "\$probe"
"\$PYBIN" - "\$f"
/usr/bin/$PY -c 'import json'
"\$HOME/.venv/bin/${PYB}" -c 'import json'
${PYB}3.12 -c 'import json'
${PYB}3.14 - <<'P'
$PY -W ignore -c 'import json'
$PY -X utf8 -c 'import json'
$PY -Wignore -X dev -c 'import json'
\${PYTHON:-$PY} -c 'import json'
"\${PYBIN:-$PY}" -c 'import json'
"\${RUNTIME:-$PY}" -c 'import json'
\$PYTHON3 -c 'import json'
\$PY3 -c 'import json'
$PY -m json.tool x.json
$PY -u -m http.server
$PY <script.py
$PY -c 'import json, sys; sys.path[:] = [p for p in sys.path if p]'
$PY -c 'import sys; sys.path[:] = [p for p in sys.path if p]; import yaml' ; $PY -c 'import json'
$PY -P -c 'import json'
$PY -Pc 'import json'
EOF

echo "== formes fautives multi-lignes (variable affectée, continuation) =="
nl='
'
badml() { # <libellé> <contenu>
  i=$((i + 1)); r="$(mkrepo "ml$i")"; put "$r" plugin/x/scripts/a.sh "$2"; put "$r" plugin/x/scripts/b.sh "$PY -I -c 'import json'"
  expect "fautif : $1" 1 "$SCRIPT" "$r"
}
badml "variable sans py affectée à un python (INTERP)" "INTERP=$PY${nl}\"\$INTERP\" -c 'import json'"
badml "variable sans py (RUNTIME = command -v)" "RUNTIME=\"\$(command -v $PY)\"${nl}\$RUNTIME -c 'import json'"
badml "variable sans py (bin, stdin)" "bin=$PY${nl}printf x | \$bin - <<'P'"
badml "variable de boucle for … in" "for runner in $PY python; do${nl}  \$runner -c 'import json'${nl}done"
badml "continuation interpréteur puis -c à la ligne suivante" "$PY \\${nl}  -c 'import json'"
badml "continuation après -W" "$PY -W ignore \\${nl}  -c 'import json'"

echo "== formes conformes (chacune doit rester verte : 0) =="
i=0
while IFS= read -r line; do
  i=$((i + 1)); r="$(mkrepo "good$i")"
  put "$r" plugin/x/scripts/a.sh "$line"; put "$r" plugin/x/scripts/b.sh "$PY -I -c 'import json'"
  expect "conforme : $line" 0 "$SCRIPT" "$r"
done <<EOF
$PY -I -c 'import json'
"\$PYBIN" -I - "\$f" <<'P'
$PY -P -c 'import json' # vf-py311 : le site vérifie sys.version_info >= (3, 11) avant
$PY -Ic 'import json'
$PY -I -W ignore -c 'import json'
$PY -W ignore -I -c 'import json'
$PY -I -m json.tool x.json
/usr/bin/$PY -I -c 'import json'
$PY "\$script" -c 'import json'
$PY -u "\$script" -m x
timeout 5 \$cand -I -c "\$probe"
py -3 -I -c ''
$PY "\$PASS_A_PY" < "\$LIST" > out
cat > "\$PASS_A_PY" << 'P'
command -v $PY >/dev/null 2>&1
echo "$PY requis"
# $PY -c 'import json' (commentaire)
vf_python -c 'import json'
$PY -c 'import sys; sys.path[:] = [p for p in sys.path if p]; import yaml'
$PY -c 'import json' # vf-py-isolation-ok : le littéral est le sujet
$PY -c 'import sys; sys.path[:] = [p for p in sys.path if p]; import yaml' ; $PY -I -c 'import json'
EOF

echo "== formes conformes multi-lignes =="
goodml() { # <libellé> <contenu>
  i=$((i + 1)); r="$(mkrepo "gml$i")"; put "$r" plugin/x/scripts/a.sh "$2"; put "$r" plugin/x/scripts/b.sh "$PY -I -c 'import json'"
  expect "conforme : $1" 0 "$SCRIPT" "$r"
}
goodml "une variable qui capture la SORTIE d'un python n'est pas un interpréteur" "out=\$($PY -I -c 'print(1)')${nl}printf x | \$out -c y"
goodml "continuation avec -I" "$PY -I \\${nl}  -c 'import json'"

echo "== exclusions =="
r="$(mkrepo excl)"
put "$r" plugin/x/scripts/ok.sh "$PY -I -c 'import json'"
put "$r" plugin/x/scripts/tests/test-x.sh "$PY -c 'import json'"
put "$r" plugin/x/README.md "$PY -c 'import json'"
put "$r" plugin/x/scripts/t.py "$PY -c 'x'"
expect "tests/, *.md et *.py exclus (sale seulement là) → vert" 0 "$SCRIPT" "$r"

echo "== échappatoire : ne vaut QUE sur sa ligne =="
r="$(mkrepo marq)"
put "$r" plugin/x/scripts/a.sh "$PY -c 'import json' # vf-py-isolation-ok : sujet
$PY -c 'import json'"
expect "marqueur sur la ligne 1 ne couvre pas la ligne 2" 1 "$SCRIPT" "$r"

echo "== non vérifiable (3) / usage (64) =="
mkdir -p "$TMP/nogit"; expect "hors dépôt git" 3 "$SCRIPT" "$TMP/nogit"
r="$(mkrepo vide)"; expect "univers vide" 3 "$SCRIPT" "$r"
r="$(mkrepo zero)"; put "$r" plugin/x/scripts/a.sh "echo rien"
expect "zéro invocation inspectée (vert à vide interdit)" 3 "$SCRIPT" "$r"
bash "$SCRIPT" --bogus >/dev/null 2>&1; rc=$?; [ "$rc" -eq 64 ] && ok "option inconnue → 64" || ko "usage" "rc=$rc"
bash "$SCRIPT" --min-sites x >/dev/null 2>&1; rc=$?; [ "$rc" -eq 64 ] && ok "--min-sites non entier → 64" || ko "usage" "rc=$rc"
r="$(mkrepo min)"; put "$r" plugin/x/scripts/a.sh "$PY -I -c 'x'"
bash "$SCRIPT" --path "$r" --min-sites 2 >/dev/null 2>&1; rc=$?; [ "$rc" -eq 3 ] && ok "--min-sites 2 avec 1 site → 3" || ko "min-sites" "rc=$rc"

echo "== mutation =="
mutate() { # <nom> <awk-ou-sed-programme> → $TMP/<nom>.sh (échoue si inchangé)
  local out="$TMP/$1.sh"; sed "$2" "$SCRIPT" > "$out"
  if cmp -s "$out" "$SCRIPT"; then ko "$1" "la mutation n'a RIEN changé — mutant NON OPPOSABLE"; return 1; fi
  return 0
}
dirty="$(mkrepo mdirty)"; put "$dirty" plugin/x/scripts/a.sh "$PY -c 'import json'"
if mutate MUT1 's/^    if (!prog) { i = j; continue }.*$/    next/'; then
  run "$TMP/MUT1.sh" "$dirty"; rc=$?
  [ "$rc" -ne 1 ] && ok "MUT1 détecteur coupé → le dépôt sale n'est plus rouge (rc=$rc)" || ko "MUT1" "toujours rouge — le détecteur n'est pas ce qui rougit"
fi
marked="$(mkrepo mmark)"; put "$marked" plugin/x/scripts/a.sh "$PY -c 'import json' # vf-py-isolation-ok : sujet
$PY -I -c 'x'"
expect "témoin MUT2 : dépôt marqué vert" 0 "$SCRIPT" "$marked"
if mutate MUT2 's/vf-py-isolation-ok/vf-py-isolation-nope/'; then
  run "$TMP/MUT2.sh" "$marked"; rc=$?
  [ "$rc" -eq 1 ] && ok "MUT2 marqueur non lu → rouge (1)" || ko "MUT2" "rc=$rc (attendu 1) — l'échappatoire n'est pas lue"
fi
tonly="$(mkrepo mtest)"; put "$tonly" plugin/x/scripts/ok.sh "$PY -I -c 'x'"; put "$tonly" plugin/x/scripts/tests/test-x.sh "$PY -c 'import json'"
expect "témoin MUT3 : seul un fichier de test sale → vert" 0 "$SCRIPT" "$tonly"
if mutate MUT3 's#\*/tests/\*|##'; then
  run "$TMP/MUT3.sh" "$tonly"; rc=$?
  [ "$rc" -eq 1 ] && ok "MUT3 exclusion retirée → rouge (1)" || ko "MUT3" "rc=$rc (attendu 1) — l'exclusion tests/ n'est pas appliquée"
fi
runfile="$(mkrepo mfile)"; put "$runfile" plugin/x/scripts/b.sh "$PY -I -c 'x'"; put "$runfile" plugin/x/scripts/a.sh "$PY \"\$PASS_A_PY\" < \"\$LIST\" > out"
expect "témoin MUT4 : lancement d'un fichier → vert" 0 "$SCRIPT" "$runfile"
if mutate MUT4 's/^    if (!prog) { i = j; continue }/    if (!prog) { continue }/'; then
  run "$TMP/MUT4.sh" "$runfile"; rc=$?
  [ "$rc" -eq 1 ] && ok "MUT4 saut du fichier retiré → rouge (1)" || ko "MUT4" "rc=$rc (attendu 1) — le saut n'est pas appliqué"
fi

# Mutants de l'élargissement du détecteur (H1-H3, revue + audit 2026-10-20). Chaque mutant désarme UN
# organe ; le dépôt fautif correspondant (rouge avec le script réel, cf. « formes fautives ») doit
# cesser d'être rouge. mut_green <nom> <sed> <contenu> <organe>.
mut_green() {
  local name="$1" prog="$2" content="$3" what="$4" d
  d="$(mkrepo "m$name")"; put "$d" plugin/x/scripts/a.sh "$content"; put "$d" plugin/x/scripts/b.sh "$PY -I -c 'x'"
  expect "témoin $name : dépôt fautif → rouge" 1 "$SCRIPT" "$d"
  if mutate "$name" "$prog"; then
    run "$TMP/$name.sh" "$d"; rc=$?
    [ "$rc" -ne 1 ] && ok "$name $what → le dépôt fautif n'est plus rouge (rc=$rc)" || ko "$name" "toujours rouge — $what n'est pas l'organe qui rougit"
  fi
}
mut_green MUT5 's#sub(/\.\*\\//, "", b)#b = b#' "/usr/bin/$PY -c 'import json'" "basename du chemin retiré"
mut_green MUT6 's/c == "W" || c == "X" || c == "Q"/c == "Z"/' "$PY -W ignore -c 'import json'" "options à argument (-W/-X/-Q) non consommées"
mut_green MUT7 's/purge_ok(span)/purge_ok(line)/' "$PY -c 'import sys; sys.path[:] = [p for p in sys.path if p]; import yaml' ; $PY -c 'import json'" "exemption de purge étendue à la ligne"
mut_green MUT8 's/c == "c" || c == "m"/c == "c"/' "$PY -m json.tool x.json" "-m non traité comme programme inline"
mut_green MUT9 's/acc = acc raw; continue/acc = ""; continue/' "$PY \\${nl}  -c 'import json'" "jonction des continuations retirée"
mut_green MUT10 's/if (name in PYVARS) return 1/if (0) return 1/' "INTERP=$PY${nl}\"\$INTERP\" -c 'import json'" "variables affectées à un python non reconnues"
mut_green MUT11 's/return !pre_import_bad(substr(span, 1, idx - 1))/return 1/' "$PY -c 'import json, sys; sys.path[:] = [p for p in sys.path if p]'" "précédence de la purge non vérifiée"
mut_green MUT12 's/if (pflag \&\& index(span, "vf-py311") > 0) continue/if (pflag) continue/' "$PY -P -c 'import json'" "-P accepté sans garantie 3.11"
mut_green MUT13 's/if (rest ~ PYWORD_RE) return 1/if (0) return 1/' "\"\${RUNTIME:-$PY}\" -c 'import json'" "défaut \${NOM:-python3} non lu"
mut_green MUT14 's/name = line; sub(/name = "zz"; sub(/' "for runner in $PY python; do${nl}  \$runner -c 'import json'${nl}done" "variable de boucle for non reconnue"

echo "== contrôle final (arbre réel, non discriminant) =="
REAL="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$SCRIPT" --path "$REAL" --min-sites 40 >/dev/null 2>"$TMP/err"; rc=$?
[ "$rc" -eq 0 ] && ok "arbre réel : toutes les invocations inline sont isolées (>= 40 inspectées)" || ko "arbre réel" "rc=$rc — $(head -c 300 "$TMP/err")"

echo ""
echo "== bilan : $PASS OK / $FAIL KO =="
[ "$FAIL" -eq 0 ]
