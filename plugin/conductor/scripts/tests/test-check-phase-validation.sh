#!/usr/bin/env bash
# Test de check-phase-validation.sh (Phase 60, ARCG-01, ARCG-02 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P60-PL-20) : aucun dossier fixtures/ versionné,
# octets CRLF et BOM produits par printf. Le script se retrouve par ../check-phase-validation.sh, en source
# comme une fois copié à plat par l'engine (la suite se pose sous scripts/tests/).
# Cas CPV-TRACE-1..4 (du marqueur `proposed` au code 1, phase absente, ROADMAP absent, usage).
# Les cas CPV-GSD-* (preuve que le marqueur ne change rien pour le moteur GSD) s'ajoutent en 60-03.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-phase-validation.sh"
TARGET="$SCRIPT"

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
# mklab <nom> <format printf> [args] : lab plat sous $FX/<nom>, ROADMAP du dossier de planning ; positionne RUNDIR.
mklab() {
  RUNDIR="$FX/$1"; local fmt="$2"; shift 2
  mkdir -p "$RUNDIR/.planning"; printf -- "$fmt" "$@" > "$RUNDIR/.planning/ROADMAP.md"
  reg "$1"; reg "$1/.planning"; reg "$1/.planning/ROADMAP.md"
}
# run <arguments séparés> -> RC, OUT, ERR ; appel borné (une attente devient un échec du cas, rc 142), cwd = RUNDIR.
run() {
  OUT="$(cd "$RUNDIR" && perl -e 'alarm 10; exec @ARGV' bash "$TARGET" "$@" 2>"$TMP/err")"; RC=$?
  ERR="$(cat "$TMP/err")"
  echo "$RC" >> "$TMP/rcs"
}
has() { command grep -qF -- "$1" <<<"$OUT"; }   # chaîne ici : jamais de tube (SIGPIPE + pipefail)
last() { printf '%s\n' "$OUT" | tail -1; }
case_() { if "$2"; then ok "$1"; else ko "$1 — $LASTMSG"; fi; }
msg() { LASTMSG="$1, obtenu rc $RC out[$(printf '%s' "$OUT" | tr '\n' '|' | cut -c1-200)] err[$(printf '%s' "$ERR" | tr '\n' '|' | cut -c1-200)]"; }

# ROADMAP de trois phases ; %s = lignes insérées sous le Goal de la phase 2.
RM3='# Roadmap\n\n## Milestone v1.0\n\n### Phase 1: Premiere\n**Goal:** un\n\n### Phase 2: Deuxieme\n**Goal:** deux\n%s\n### Phase 3: Troisieme\n**Goal:** trois\n'
PROP=$'**Validation:** proposed\n'

echo "== test-check-phase-validation =="

# === Tracer : du marqueur proposed au code 1 =====================================================
probe_trace1() {
  mklab t1 "$RM3" ""
  run --phase 2
  msg "aucun marqueur attendu rc 0 + PHASE 2 validee (marqueur absent)"
  { [ "$RC" -eq 0 ] && has 'PHASE 2 validee (marqueur absent)' \
    && last | command grep -q 'BILAN phase=2 marqueur=absent code=0$'; }
}
probe_trace2() {
  mklab t2 "$RM3" "$PROP"
  run --phase 2
  msg "marqueur proposed en phase 2 attendu rc 1 + PHASE 2 proposee"
  { [ "$RC" -eq 1 ] && has 'PHASE 2 proposee' && last | command grep -q 'BILAN phase=2 marqueur=proposed code=1$'; } || return 1
  run --phase 3
  msg "le marqueur de la phase 2 ne déborde pas sur la phase 3, attendu rc 0"
  [ "$RC" -eq 0 ]
}
probe_trace3() {
  mklab t3 "$RM3" ""
  run --phase 9
  msg "phase 9 absente attendu rc 3 + INDETERMINE phase introuvable"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  RUNDIR="$FX/t3b"; mkdir -p "$RUNDIR/.planning"; reg t3b; reg t3b/.planning
  run --phase 2
  msg "ROADMAP absent attendu rc 3 + INDETERMINE roadmap absent"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE roadmap absent'; }
}
probe_trace4() {
  RUNDIR="$FX/t1"
  run
  msg "aucun argument attendu rc 64 + message sur stderr"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run --phase
  msg "--phase sans valeur attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run --phase abc
  msg "--phase abc attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run --phase 2 --inconnu
  msg "argument inconnu attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; }
}
case_ CPV-TRACE-1 probe_trace1
case_ CPV-TRACE-2 probe_trace2
case_ CPV-TRACE-3 probe_trace3
case_ CPV-TRACE-4 probe_trace4

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
