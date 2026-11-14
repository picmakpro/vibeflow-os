#!/usr/bin/env bash
# ci-mutants-perimetre.sh — les mutants du guard de verrou ont-ils quelque chose à juger sur cette PR ?
# (mission « CI sélective » ; arbitrage « Affiner par région », Samuel, AskUserQuestion session principale,
#  2026-11-07 : une PR qui touche .github/workflows/ci.yml ne joue les mutants (job tests-mutants, ~28 min) QUE si le
#  diff de ci.yml touche GW_MODE, test-guard-driver-lock-ws, ou les jobs tests-shard / tests-mutants, délimités dans
#  le fichier par des marqueurs de région. Un diff illisible joue les mutants. Le push sur main rejoue tout : ce cas
#  est tranché par le workflow, pas par ce script.)
#
# Usage : ci-mutants-perimetre.sh <base> <head>
# Sortie (stdout) : UNE ligne `mutants=<true|false><TAB><raison>`.
# Règles, dans cet ordre :
#   1. un fichier déclencheur touché (guard, verrou, leur suite, lib portable, politique de workstream) -> true ;
#   2. ci.yml touché : une ligne ajoutée ou retirée qui cite GW_MODE ou test-guard-driver-lock-ws -> true ;
#      un hunk dont les lignes NOUVELLES tombent dans la région du fichier de head, ou dont les lignes ANCIENNES
#      tombent dans la région du fichier de base -> true ; marqueurs absents, déséquilibrés ou mal ordonnés dans
#      base ou head -> true (fail-safe) ; sinon false ;
#   3. rien de cela -> false.
# La région est l'INTÉRIEUR des marqueurs (les lignes de marqueur ne comptent pas) : retirer un marqueur n'est donc
# jamais jugé « hors région » par erreur, c'est le fail-safe des marqueurs qui le rattrape.
# Sorties : 0 = ligne rendue · 2 = diff illisible (la CI joue alors les mutants) · 64 = usage.
set -u
LC_ALL=C; export LC_ALL

TAB=$(printf '\t')
CI_YML=.github/workflows/ci.yml

usage() { echo "usage : ci-mutants-perimetre.sh <base> <head>" >&2; exit 64; }
emit() { printf 'mutants=%s\t%s\n' "$1" "$2"; exit "${3:-0}"; }

[ $# -eq 2 ] || usage
base=$1; head=$2
[ -n "$base" ] && [ -n "$head" ] || usage
case "$base" in -*) usage ;; esac
case "$head" in -*) usage ;; esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || emit true "racine git introuvable : mutants joués par défaut" 2

files="$(git -C "$ROOT" diff --name-only --no-renames "$base...$head" -- 2>/dev/null)" ||
  emit true "diff illisible (${base}...${head}) : mutants joués par défaut" 2

touche_ci=0; declencheur=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    plugin/conductor/scripts/guard-driver-lock.sh|plugin/conductor/scripts/driver-lock.sh|\
    plugin/conductor/scripts/tests/test-guard-driver-lock-ws.sh|plugin/_internal/lib/vf-portable.sh|\
    plugin/planning-core/scripts/workstream-policy.sh) [ -n "$declencheur" ] || declencheur=$f ;;
    .github/workflows/ci.yml) touche_ci=1 ;;
  esac
done <<EOF
$files
EOF

[ -z "$declencheur" ] || emit true "fichier déclencheur touché : ${declencheur}"
[ "$touche_ci" -eq 1 ] || emit false "aucun fichier déclencheur touché"

# --- ci.yml touché : lecture par région ----------------------------------------------------------------------------
# Intérieurs des paires de marqueurs, « debut,fin » séparés par des espaces ; ERR si absents, déséquilibrés ou mal ordonnés.
regions() {
  printf '%s\n' "$1" | awk '
    { l = $0; sub(/^[ \t]+/, "", l) }
    index(l, "# >>> REGION-MUTANTS") == 1 { if (open) bad = 1; open = 1; s = NR; next }
    index(l, "# <<< FIN-REGION-MUTANTS") == 1 {
      if (!open) bad = 1
      else { out = out (out == "" ? "" : " ") (s + 1) "," (NR - 1); n++ }
      open = 0; next
    }
    END { if (bad || open || n == 0) print "ERR"; else print out }'
}

contenu_base="$(git -C "$ROOT" show "$base:$CI_YML" 2>/dev/null)" || contenu_base=""
contenu_head="$(git -C "$ROOT" show "$head:$CI_YML" 2>/dev/null)" || contenu_head=""
rb="$(regions "$contenu_base")"
rh="$(regions "$contenu_head")"
[ "$rb" = ERR ] && emit true "ci.yml : marqueurs de région absents, déséquilibrés ou mal ordonnés dans la base (fail-safe)"
[ "$rh" = ERR ] && emit true "ci.yml : marqueurs de région absents, déséquilibrés ou mal ordonnés dans head (fail-safe)"

diff_ci="$(git -C "$ROOT" diff -U0 --no-renames "$base...$head" -- "$CI_YML" 2>/dev/null)" ||
  emit true "diff de ci.yml illisible : mutants joués par défaut" 2

verdict="$(printf '%s\n' "$diff_ci" | awk -v OLD="$rb" -v NEW="$rh" '
  function inter(lo, hi, spec,    n, i, r, p) {
    n = split(spec, r, " ")
    for (i = 1; i <= n; i++) {
      split(r[i], p, ",")
      if (lo <= p[2] + 0 && hi >= p[1] + 0) return 1
    }
    return 0
  }
  /^@@ / {
    inh = 1
    s = $2; t = $3; sub(/^-/, "", s); sub(/^\+/, "", t)
    split(s, A, ","); split(t, C, ",")
    a = A[1] + 0; b = (A[2] == "" ? 1 : A[2] + 0)
    c = C[1] + 0; d = (C[2] == "" ? 1 : C[2] + 0)
    if (b > 0 && inter(a, a + b - 1, OLD)) od = 1
    if (d > 0 && inter(c, c + d - 1, NEW)) nw = 1
    next
  }
  inh && /^[-+]/ {
    if (index($0, "GW_MODE") > 0 || index($0, "test-guard-driver-lock-ws") > 0) kw = 1
  }
  END { print (kw ? "kw" : (nw ? "new" : (od ? "old" : "none"))) }')"

case "$verdict" in
  kw)  emit true  "ci.yml : ligne ajoutée ou retirée qui cite GW_MODE ou test-guard-driver-lock-ws" ;;
  new) emit true  "ci.yml : lignes nouvelles dans la région des jobs tests-shard et tests-mutants" ;;
  old) emit true  "ci.yml : lignes retirées de la région des jobs tests-shard et tests-mutants" ;;
  none) emit false "ci.yml : diff hors de la région des jobs tests-shard et tests-mutants" ;;
  *)   emit true  "ci.yml : verdict de lecture indéterminé : mutants joués par défaut" 2 ;;
esac
