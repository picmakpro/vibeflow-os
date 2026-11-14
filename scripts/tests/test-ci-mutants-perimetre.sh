#!/usr/bin/env bash
# test-ci-mutants-perimetre.sh — Suite de vérification de scripts/ci-mutants-perimetre.sh (mission « CI sélective »,
# arbitrage « Affiner par région », Samuel, AskUserQuestion session principale, 2026-11-07).
#
# Dépôt git jetable sous mktemp, avec un ci.yml factice à marqueurs de région. Une branche par cas, construite une
# fois ; le script (original, puis chaque mutant) est rejoué sur ces branches avec le dépôt jetable pour répertoire
# courant. Sortie exacte vérifiée (ligne `mutants=...<TAB>raison`, code de sortie).
# MUTANTS : sed sur une copie du script ; le cas visé doit rougir (le mutant s'exécute encore et rend une sortie bien
# formée mais fausse). Un mutant qui ne change pas le fichier, ne passe plus `bash -n`, rend une sortie mal formée, ou
# dont le cas visé était déjà rouge sur l'original, n'est pas compté comme tué.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REAL="$(cd "$HERE" && git rev-parse --show-toplevel)"
SCRIPT="$REAL/scripts/ci-mutants-perimetre.sh"
TAB=$(printf '\t')

PASS=0; FAIL=0
ok() { echo "  OK $1"; PASS=$((PASS + 1)); }
ko() { echo "  KO $1"; echo "    attendu : $2"; echo "    obtenu  : $3"; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/vf-test-mutants-perimetre.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
REPO="$WORK/repo"
G() { git -C "$REPO" "$@"; }
put() { mkdir -p "$REPO/$(dirname "$1")"; printf '%s\n' "$2" > "$REPO/$1"; }

mkdir -p "$REPO" && git init -q "$REPO" && G symbolic-ref HEAD refs/heads/main
G config user.name t; G config user.email t@t; G config commit.gpgsign false

CI=.github/workflows/ci.yml
mkdir -p "$REPO/.github/workflows" "$REPO/plugin/conductor/scripts"
cat > "$REPO/$CI" <<'EOF'
# en-tete du workflow
name: CI
on: [push]
env:
  SHARDS: "9"
jobs:
  changes:
    runs-on: ubuntu-latest
    steps:
      - run: echo changes
  # >>> REGION-MUTANTS (scripts/ci-mutants-perimetre.sh) : jobs tests-shard et tests-mutants
  tests-shard:
    runs-on: ubuntu-latest
    steps:
      - run: echo shard
      - run: echo shard-bis
  tests-mutants:
    runs-on: ubuntu-latest
    steps:
      - run: echo mutants
  # <<< FIN-REGION-MUTANTS
  tests:
    runs-on: ubuntu-latest
    steps:
      - run: echo agrege
EOF
put plugin/conductor/scripts/guard-driver-lock.sh "echo guard"
put README.md "readme"
put docs/x.md "doc"
G add -A && G commit -q -m base

# Applique un remplacement littéral d'une ligne : edit <ancre exacte> <nouvelle ligne|-> (- = supprimer)
edit() {
  awk -v a="$1" -v n="$2" '$0 == a { if (n != "-") print n; next } { print }' "$REPO/$CI" > "$WORK/ci.new" && mv "$WORK/ci.new" "$REPO/$CI"
}
branche() { G checkout -q -b "$1" main; }
fini() { G add -A && G commit -q -m "$1"; G checkout -q main; }

branche br_a;  edit '      - run: echo shard-bis' '      - run: echo shard-ter'; fini a
branche br_b;  edit '# en-tete du workflow' '# en-tete du workflow, commentaire retouche'; fini b
branche br_c;  edit '  SHARDS: "9"' '  SHARDS: "GW_MODE"'; fini c
branche br_d;  edit '      - run: echo shard-bis' '-'; fini d
branche br_e;  edit '  # <<< FIN-REGION-MUTANTS' '-'; fini e
branche br_f;  put plugin/conductor/scripts/guard-driver-lock.sh "echo guard modifie"; fini f
branche br_g;  put docs/x.md "doc modifiee"; fini g
branche br_h;  edit '      - run: echo agrege' '      - run: echo agrege-bis'; fini h

# --- Exécution : sortie combinée « rc|ligne » ----------------------------------------------------------------------
lancer() { # lancer <script> <args...>
  local s="$1"; shift
  local out rc
  out="$(cd "$REPO" && bash "$s" "$@" 2>/dev/null)"; rc=$?
  printf '%s|%s' "$rc" "$out"
}
brut() { lancer "$1" main "$2"; }

R_A="0|mutants=true${TAB}ci.yml : lignes nouvelles dans la région des jobs tests-shard et tests-mutants"
R_B="0|mutants=false${TAB}ci.yml : diff hors de la région des jobs tests-shard et tests-mutants"
R_C="0|mutants=true${TAB}ci.yml : ligne ajoutée ou retirée qui cite GW_MODE ou test-guard-driver-lock-ws"
R_D="0|mutants=true${TAB}ci.yml : lignes retirées de la région des jobs tests-shard et tests-mutants"
R_E="0|mutants=true${TAB}ci.yml : marqueurs de région absents, déséquilibrés ou mal ordonnés dans head (fail-safe)"
R_F="0|mutants=true${TAB}fichier déclencheur touché : plugin/conductor/scripts/guard-driver-lock.sh"
R_G="0|mutants=false${TAB}aucun fichier déclencheur touché"
R_H="0|mutants=false${TAB}ci.yml : diff hors de la région des jobs tests-shard et tests-mutants"

cas() { # cas <script> <branche> <attendu> <libellé>   → écrit ok/ko
  local obtenu; obtenu="$(brut "$1" "$2")"
  if [ "$obtenu" = "$3" ]; then ok "$4"; else ko "$4" "$3" "$obtenu"; fi
}

echo "== Cas sur l'original =="
cas "$SCRIPT" br_a "$R_A" "(a) ligne modifiée DANS la région -> true"
cas "$SCRIPT" br_b "$R_B" "(b) commentaire HORS région (tête du fichier) -> false"
cas "$SCRIPT" br_c "$R_C" "(c) ligne HORS région qui contient GW_MODE -> true"
cas "$SCRIPT" br_d "$R_D" "(d) suppression d'une ligne dans la région -> true"
cas "$SCRIPT" br_e "$R_E" "(e) marqueur supprimé -> true, fail-safe"
cas "$SCRIPT" br_f "$R_F" "(f) guard-driver-lock.sh touché -> true"
cas "$SCRIPT" br_g "$R_G" "(g) fichier sans rapport -> false"
cas "$SCRIPT" br_h "$R_H" "(j) ligne du job agrégé, hors région, après le marqueur de fin -> false"

o="$(lancer "$SCRIPT" main deadbeefdeadbeefdeadbeefdeadbeefdeadbeef)"
case "$o" in "2|mutants=true${TAB}"*) ok "(h) sha inconnu -> rc 2, mutants=true" ;; *) ko "(h) sha inconnu -> rc 2" "2|mutants=true<TAB>..." "$o" ;; esac
o="$(lancer "$SCRIPT")"
case "$o" in 64\|*) ok "(i) sans argument -> rc 64" ;; *) ko "(i) sans argument -> rc 64" "64|" "$o" ;; esac
o="$(lancer "$SCRIPT" main)"
case "$o" in 64\|*) ok "(i) un seul argument -> rc 64" ;; *) ko "(i) un seul argument -> rc 64" "64|" "$o" ;; esac
o="$(lancer "$SCRIPT" --liste main)"
case "$o" in 64\|*) ok "(i) option inconnue -> rc 64" ;; *) ko "(i) option inconnue -> rc 64" "64|" "$o" ;; esac

echo "== Le vrai ci.yml =="
reel="$(awk '
  { l = $0; sub(/^[ \t]+/, "", l) }
  index(l, "# >>> REGION-MUTANTS") == 1 { no++; ls = NR }
  index(l, "# <<< FIN-REGION-MUTANTS") == 1 { nf++; lf = NR }
  /^  tests-shard:/ { sh = NR }
  /^  tests-mutants:/ { mu = NR }
  END { ok = (no == 1 && nf == 1 && ls < lf && sh > ls && sh < lf && mu > ls && mu < lf); print (ok ? "bien-forme" : "mal-forme no=" no " nf=" nf " ls=" ls " lf=" lf " sh=" sh " mu=" mu) }' "$REAL/$CI")"
if [ "$reel" = bien-forme ]; then ok "marqueurs présents une fois, dans l'ordre, autour de tests-shard: et tests-mutants:"; else ko "marqueurs du vrai ci.yml" "bien-forme" "$reel"; fi

echo "== Mutants =="
bien_forme() { case "$1" in [0-9]\|mutants=true"$TAB"*|[0-9]\|mutants=false"$TAB"*) return 0 ;; esac; return 1; }
mutant() { # mutant <nom> <sed-expr> <branche> <attendu-original>
  local nom="$1" expr="$2" br="$3" att="$4" mut="$WORK/mut-$1.sh" obtenu
  sed "$expr" "$SCRIPT" > "$mut"
  if cmp -s "$SCRIPT" "$mut"; then ko "mutant « $nom »" "le sed modifie le script" "fichier inchangé"; return; fi
  if ! bash -n "$mut" 2>/dev/null; then ko "mutant « $nom »" "mutant syntaxiquement valide" "bash -n échoue"; return; fi
  obtenu="$(brut "$mut" "$br")"
  if ! bien_forme "$obtenu"; then ko "mutant « $nom »" "sortie bien formée" "$obtenu"; return; fi
  if [ "$obtenu" = "$att" ]; then ko "mutant « $nom » survit (cas visé inchangé)" "différent de : $att" "$obtenu"
  else ok "mutant « $nom » tué par le cas $br — attendu : ${att#*|} / obtenu : ${obtenu#*|}"; fi
}
mutant "région ignorée" 's/if (lo <= p\[2\] + 0 \&\& hi >= p\[1\] + 0) return 1/if (0) return 1/' br_a "$R_A"
mutant "mot-clé GW_MODE ignoré" 's/test-guard-driver-lock-ws") > 0) kw = 1/test-guard-driver-lock-ws") > 0) kw = 0/;s/index(\$0, "GW_MODE") > 0 ||/0 \&\& index($0, "GW_MODE") > 0 ||/' br_c "$R_C"
mutant "lignes anciennes ignorées" 's/if (b > 0 \&\& inter/if (0 \&\& inter/' br_d "$R_D"
mutant "fail-safe des marqueurs retiré" 's/"\$rh" = ERR \]/"$rh" = ERRX ]/' br_e "$R_E"
mutant "tout ci.yml -> true (ancien comportement)" 's/\.github\/workflows\/ci\.yml) touche_ci=1 ;;/.github\/workflows\/ci.yml) touche_ci=1; declencheur=$f ;;/' br_b "$R_B"

echo
echo "Résultat : $PASS ok, $FAIL ko"
[ "$FAIL" -eq 0 ]
