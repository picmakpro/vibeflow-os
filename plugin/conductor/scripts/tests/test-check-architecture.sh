#!/usr/bin/env bash
# Test de check-architecture.sh (Phase 60, ARCG-06, ARCG-07 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P60-PL-20) : aucun dossier fixtures/ versionné,
# octets CRLF et BOM produits par printf/awk. Le script se retrouve par ../check-architecture.sh, en source
# comme une fois copié à plat par l'engine (la suite se pose sous scripts/tests/). Le gabarit réel se lit à
# planning-core/references/templates/product/ ; introuvable (copie à plat) : SKIP nommé, jamais un vert.
# Cas CARCH-TRACE-1..4 (gabarit brut -> 1, gabarit rempli et validé -> 0, fichier absent -> 1, usage -> 64), CARCH-HELP.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-architecture.sh"
TARGET="$SCRIPT"
PLUGIN_DIR="$(cd "$HERE/../../.." && pwd)"
GAB="$PLUGIN_DIR/planning-core/references/templates/product/ARCHITECTURE.template.md"

PASS=0; FAIL=0; SKIPPED=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; SKIPPED=$((SKIPPED+1)); }

TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
FX="$TMP/fx"; mkdir -p "$FX"
: > "$TMP/rcs"; : > "$TMP/fxlist"; : > "$TMP/fxsum"
mkdir "$TMP/cwd"; cd "$TMP/cwd" || exit 1
RUNDIR="$TMP/cwd"
LASTMSG=""; RC=0; OUT=""; ERR=""

# reg <relatif> : inscrit une fixture à l'empreinte de lecture seule (contenu des fichiers réguliers).
reg() {
  echo "$FX/$1" >> "$TMP/fxlist"
  if [ -f "$FX/$1" ] && [ ! -L "$FX/$1" ]; then echo "$(cksum < "$FX/$1") $FX/$1" >> "$TMP/fxsum"; fi
}
# run <arguments séparés> -> RC, OUT, ERR ; appel borné (une attente devient un échec du cas, rc 142), cwd neutre.
run() {
  OUT="$(cd "$RUNDIR" && perl -e 'alarm 10; exec @ARGV' bash "$TARGET" "$@" 2>"$TMP/err" < /dev/null)"; RC=$?
  ERR="$(cat "$TMP/err")"
  echo "$RC" >> "$TMP/rcs"
}
# runf <fixture> : passe --architecture <fixture sous $FX> (le nom est inscrit à l'empreinte avant l'appel).
runf() { run --architecture "$FX/$1"; }
has() { command grep -qF -- "$1" <<<"$OUT"; }   # chaîne ici : jamais de tube (SIGPIPE + pipefail)
last() { printf '%s\n' "$OUT" | tail -1; }
case_() { if "$2"; then ok "$1"; else ko "$1 — $LASTMSG"; fi; }
msg() { LASTMSG="$1, obtenu rc $RC out[$(printf '%s' "$OUT" | tr '\n' '|' | cut -c1-260)] err[$(printf '%s' "$ERR" | tr '\n' '|' | cut -c1-200)]"; }

echo "== test-check-architecture =="

# === Tracer : du gabarit brut au code 1, du gabarit rempli et validé au code 0 ===================
# fill_gab <ligne d'état> : copie du gabarit réel où chaque ligne entre crochets (corps) devient une phrase.
fill_gab() { # <sortie> <ligne d'état>
  awk -v st="$2" '
    /^\*\*Validation:\*\* proposed/ { print st; next }
    /^- \[/ { print "- Une phrase de contenu réel pour cette rubrique."; next }
    /^\[/ { print "Une phrase de contenu réel pour cette rubrique."; next }
    { print }' "$GAB" > "$1"
}
probe_trace1() {
  cp "$GAB" "$FX/trace1.md"; reg trace1.md
  runf trace1.md
  msg "gabarit brut attendu rc 1 + ARCHITECTURE proposee + six rubriques vides"
  { [ "$RC" -eq 1 ] && has 'ARCHITECTURE proposee' \
    && [ "$(printf '%s\n' "$OUT" | command grep -c 'ELIMINATOIRE rubrique [a-z_]* : vide$')" -eq 6 ] \
    && last | command grep -q 'BILAN statut=proposee rubriques_manquantes=6 code=1$'; }
}
probe_trace2() {
  fill_gab "$FX/trace2.md" '**Validation:** validated (dev, 2026-10-29)'; reg trace2.md
  runf trace2.md
  msg "gabarit rempli et validé attendu rc 0 + ARCHITECTURE validee"
  { [ "$RC" -eq 0 ] && has 'ARCHITECTURE validee' && ! has 'ELIMINATOIRE' \
    && last | command grep -q 'BILAN statut=validee rubriques_manquantes=0 code=0$'; }
}
probe_trace3() {
  run --architecture "$FX/inexistant.md"
  msg "fichier absent attendu rc 1 + ARCHITECTURE absente"
  { [ "$RC" -eq 1 ] && has 'ARCHITECTURE absente' && last | command grep -q 'BILAN statut=absente .*code=1$'; }
}
probe_trace4() {
  run; msg "aucun argument attendu rc 64 + usage sur stderr"
  { [ "$RC" -eq 64 ] && printf '%s' "$ERR" | command grep -q 'usage'; } || return 1
  run --architecture ''; msg "valeur vide attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run --architecture=; msg "valeur vide (forme =) attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run --architecture; msg "option sans valeur attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run --inconnu; msg "argument inconnu attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run --architecture a.md --architecture b.md; msg "option répétée attendu rc 64"; [ "$RC" -eq 64 ]
}
probe_help() {
  run --help; msg "--help attendu rc 0 avec les codes et la phrase du code 2"
  { [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | command grep -q '^  0 = ' && printf '%s\n' "$OUT" | command grep -q '^  64 = ' \
    && has "Le code 2 n'est jamais émis"; } || return 1
  run -h; msg "-h attendu rc 0"; [ "$RC" -eq 0 ]
}
if [ -f "$GAB" ]; then
  case_ CARCH-TRACE-1 probe_trace1
  case_ CARCH-TRACE-2 probe_trace2
else
  skip "CARCH-GABARIT absent (copie à plat) : CARCH-TRACE-1 et CARCH-TRACE-2 non joués"
fi
case_ CARCH-TRACE-3 probe_trace3
case_ CARCH-TRACE-4 probe_trace4
case_ CARCH-HELP probe_help

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
