#!/usr/bin/env bash
# Test de check-prd.sh (Phase 59, PRDT-03, PRDT-05, PRDT-09 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P59-PL-07) : aucun dossier fixtures/ versionné,
# octets CRLF et BOM produits par printf. Le script se retrouve par ../check-prd.sh, en source comme une fois
# copié à plat par l'engine (la suite se pose sous scripts/tests/).
# Cas CPRD-TRACE-1..4 (exigence sans critère jusqu'au code 1, aucune exigence, usage).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-prd.sh"
TARGET="$SCRIPT"

PASS=0; FAIL=0; SKIPPED=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; SKIPPED=$((SKIPPED+1)); }

TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
FX="$TMP/fx"; mkdir -p "$FX"
: > "$TMP/rcs"; : > "$TMP/fxlist"
MARK="zzSECRETzz"
LASTMSG=""; RC=0; OUT=""; ERR=""

# w <relatif> <format printf> [args] : écrit une fixture sous $FX et l'inscrit à l'empreinte de lecture seule.
reg() { echo "$FX/$1" >> "$TMP/fxlist"; }
w() { local rel="$1" fmt="$2"; shift 2; mkdir -p "$(dirname "$FX/$rel")"; printf -- "$fmt" "$@" > "$FX/$rel"; reg "$rel"; }

# run <arguments séparés> -> RC, OUT, ERR ; appel borné (une attente devient un échec du cas, rc 142).
run() {
  OUT="$(perl -e 'alarm 10; exec @ARGV' bash "$TARGET" "$@" 2>"$TMP/err")"; RC=$?
  ERR="$(cat "$TMP/err")"
  echo "$RC" >> "$TMP/rcs"
}
has() { printf '%s\n' "$OUT" | command grep -qF -- "$1"; }
last() { printf '%s\n' "$OUT" | tail -1; }
# case_ <id> <sonde> : une sonde rend 0 quand le comportement attendu est observé.
case_() { if "$2"; then ok "$1"; else ko "$1 — $LASTMSG"; fi; }
msg() { LASTMSG="$1, obtenu rc $RC out[$OUT] err[$ERR]"; }

A1="- [ ] **PRD-01**: Afficher le tarif. Acceptation : le tarif s'affiche en moins de 2 secondes. Priorité : must"
A2="- [ ] **PRD-02**: Exporter la liste. Acceptation : un fichier CSV est téléchargé en moins de 5 secondes. Priorité : should"
B1="- [ ] **PRD-01**: Afficher le tarif\n  Acceptation : le tarif s'affiche en moins de 2 secondes\n  Priorité : must"
B2="- [ ] **PRD-02**: Exporter la liste\n  Acceptation : un fichier CSV est téléchargé en moins de 5 secondes\n  Priorité : could"
NOCRIT="- [ ] **PRD-02**: Exporter la liste\n  Priorité : should"

echo "== test-check-prd =="

# === Tracer : de l'exigence sans critère au code 1 ================================================
probe_trace1() {
  w okA.md '# Exigences\n\n%s\n%s\n' "$A1" "$A2"
  w okB.md "# Exigences\n\n$B1\n$B2\n"
  run --requirements "$FX/okA.md"
  msg "forme A attendu rc 0 + BILAN exigences=2 sans_critere=0"
  { [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=2 sans_critere=0 '; } || return 1
  run --requirements "$FX/okB.md"
  msg "forme B attendu rc 0 + BILAN exigences=2 sans_critere=0"
  [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=2 sans_critere=0 '
}
probe_trace2() {
  w trois.md "# Exigences\n\n%s\n$NOCRIT\n%s\n" "$A1" "$A2"
  run --requirements "$FX/trois.md"
  msg "attendu rc 1 + ELIMINATOIRE exigence PRD-02 seule"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-02' \
    && ! printf '%s\n' "$OUT" | command grep 'ELIMINATOIRE' | command grep -q 'PRD-01'
}
probe_trace3() {
  w prose.md '# Exigences\n\nUn titre et de la prose, sans aucune exigence.\n\n## Suite\n\nEncore du texte.\n'
  run --requirements "$FX/prose.md"
  msg "attendu rc 3 + INDETERMINE"
  [ "$RC" -eq 3 ] && has 'INDETERMINE exigences'
}
probe_trace4() {
  run; msg "sans argument attendu rc 64 + usage sur stderr"
  { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run --requirements; msg "--requirements sans valeur attendu rc 64"
  [ "$RC" -eq 64 ] || return 1
  run --inconnu; msg "argument inconnu attendu rc 64"
  [ "$RC" -eq 64 ]
}
case_ CPRD-TRACE-1 probe_trace1
case_ CPRD-TRACE-2 probe_trace2
case_ CPRD-TRACE-3 probe_trace3
case_ CPRD-TRACE-4 probe_trace4

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
