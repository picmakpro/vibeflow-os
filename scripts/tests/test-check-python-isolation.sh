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
PY="py""thon3"

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
  i=$((i + 1)); r="$(mkrepo "bad$i")"; put "$r" plugin/x/scripts/a.sh "$line"
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
EOF

echo "== formes conformes (chacune doit rester verte : 0) =="
i=0
while IFS= read -r line; do
  i=$((i + 1)); r="$(mkrepo "good$i")"
  put "$r" plugin/x/scripts/a.sh "$line"; put "$r" plugin/x/scripts/b.sh "$PY -I -c 'import json'"
  expect "conforme : $line" 0 "$SCRIPT" "$r"
done <<EOF
$PY -I -c 'import json'
"\$PYBIN" -I - "\$f" <<'P'
$PY -P -c 'import json'
$PY -Ic 'import json'
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
EOF

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

echo "== contrôle final (arbre réel, non discriminant) =="
REAL="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$SCRIPT" --path "$REAL" --min-sites 25 >/dev/null 2>"$TMP/err"; rc=$?
[ "$rc" -eq 0 ] && ok "arbre réel : toutes les invocations inline sont isolées (>= 25 inspectées)" || ko "arbre réel" "rc=$rc — $(head -c 300 "$TMP/err")"

echo ""
echo "== bilan : $PASS OK / $FAIL KO =="
[ "$FAIL" -eq 0 ]
