#!/usr/bin/env bash
# Test de vf-validation.sh (Phase 60, ARCG-01, ARCG-06, ARCG-09 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P60-PL-20) : aucun dossier fixtures/ versionné, aucune
# écriture dans le ROADMAP du dépôt. L'écrivain et les deux gates juges (check-phase-validation.sh, check-architecture.sh)
# se retrouvent par ../, en source comme une fois copiés à plat par l'engine (la suite se pose sous scripts/tests/).
# Le poste est fixé par cas (VF_ROLE) ; la date du jour est lue avant et après chaque appel (deux valeurs admises).
# Cas VFV-TRACE-1..4 : poser puis valider une phase, constaté par le gate de bout en bout.
# Cas VFV-POSTE-*, VFV-PROPOSE-VALIDEE, VFV-IDEMPOTENT, VFV-ABSENT-VALIDATE, VFV-INCONNU, VFV-MULTI, VFV-SANS-GOAL,
# VFV-GOAL-MULTI, VFV-OCTETS, VFV-CRLF, VFV-MODE, VFV-WS, VFV-LIEN, VFV-ARCHI, VFV-NOECHO : règles de l'écrivain.
# Cas VFV-GSD-* : les lecteurs du moteur GSD rendent la même chose sur la sortie de l'écrivain que sans marqueur.
# Mutants VFV-MUT-1..8 : une ligne du script altérée, différente (cmp -s), valide (bash -n), sonde rouge sur le
# mutant puis verte sur l'original.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SDIR="$(cd "$HERE/.." && pwd)"
SCRIPT="$SDIR/vf-validation.sh"
GATE_P="$SDIR/check-phase-validation.sh"
GATE_A="$SDIR/check-architecture.sh"
TARGET="$SCRIPT"

PASS=0; FAIL=0; SKIPPED=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; SKIPPED=$((SKIPPED+1)); }

TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
FX="$TMP/fx"; mkdir -p "$FX" "$TMP/proj"
mkdir "$TMP/cwd"; cd "$TMP/cwd" || exit 1
RUNDIR="$TMP/cwd"; T_ROLE=""; T_PROJ="$TMP/proj"
LASTMSG=""; RC=0; OUT=""; ERR=""; D1=""; D2=""

# mklab <nom> <format printf> [args] : lab plat sous $FX/<nom>, ROADMAP du dossier de planning ; positionne RUNDIR.
mklab() {
  local n="$1" fmt="$2"; shift 2; RUNDIR="$FX/$n"
  mkdir -p "$RUNDIR/.planning"; printf -- "$fmt" "$@" > "$RUNDIR/.planning/ROADMAP.md"
}
RMF() { printf '%s' "$RUNDIR/.planning/ROADMAP.md"; }
# run <arguments séparés> -> RC, OUT, ERR ; appel borné (une attente devient un échec du cas), cwd = RUNDIR, poste et
# racine du fichier de poste fixés par T_ROLE et T_PROJ (jamais ceux de la session qui joue la suite).
run() {
  D1="$(date +%Y-%m-%d)"
  OUT="$(cd "$RUNDIR" && VF_ROLE="$T_ROLE" CLAUDE_PROJECT_DIR="$T_PROJ" perl -e 'alarm 10; exec @ARGV' bash "$TARGET" "$@" 2>"$TMP/err" < /dev/null)"; RC=$?
  D2="$(date +%Y-%m-%d)"; ERR="$(cat "$TMP/err")"
}
# gate_p <phase> [ws] -> code du gate de phase sur le ROADMAP du lab courant ; gate_a <fichier> -> idem pour l'architecture.
gate_p() {
  local ws=()
  if [ -n "${2:-}" ]; then ws=(--ws "$2"); fi
  (cd "$RUNDIR" && bash "$GATE_P" --phase "$1" ${ws[@]+"${ws[@]}"} > /dev/null 2>&1 < /dev/null)
}
gate_a() { bash "$GATE_A" --architecture "$1" > /dev/null 2>&1 < /dev/null; }
has() { command grep -qF -- "$1" <<<"$OUT"; }   # chaîne ici : jamais de tube (SIGPIPE + pipefail)
last() { printf '%s\n' "$OUT" | tail -1; }
case_() { if "$2"; then ok "$1"; else ko "$1 — $LASTMSG"; fi; }
msg() { LASTMSG="$1, obtenu rc $RC out[$(printf '%s' "$OUT" | tr '\n' '|' | cut -c1-240)] err[$(printf '%s' "$ERR" | tr '\n' '|' | cut -c1-200)]"; }
sum() { cksum < "$1"; }
# line_after <fichier> <ligne exacte> : la ligne qui suit la première occurrence de la ligne donnée.
line_after() { awk -v w="$2" 'f { print; exit } $0 == w { f = 1 }' "$1"; }
# marker_is <fichier> <début de valeur> : exactement une ligne de marqueur, valeur = début + date (avant ou après l'appel).
marker_is() {
  local a="$2" got
  got="$(awk '/^\*\*Validation:\*\*/' "$1")"
  [ "$(printf '%s\n' "$got" | awk 'END { print NR }')" = 1 ] || return 1
  [ "$got" = "**Validation:** $a$D1)" ] || [ "$got" = "**Validation:** $a$D2)" ] \
    || [ "$got" = "**Validation:** $a$D1, override)" ] || [ "$got" = "**Validation:** $a$D2, override)" ]
}

# ROADMAP de trois phases ; %s = lignes insérées sous le Goal de la phase 2.
RM3='# Roadmap\n\n## Milestone v1.0\n\n### Phase 1: Premiere\n**Goal:** un\n\n### Phase 2: Deuxieme\n**Goal:** deux\n%s\n### Phase 3: Troisieme\n**Goal:** trois\n'
PROP=$'**Validation:** proposed\n'

echo "== test-vf-validation =="

# === Tracer : poser puis valider une phase, constaté par le gate ======================================
probe_trace1() {
  mklab t1 "$RM3" ""
  run propose --phase 2
  msg "propose --phase 2 attendu rc 0 + ECRIT phase 2 : proposed"
  { [ "$RC" -eq 0 ] && has 'ECRIT phase 2 : proposed' && last | command grep -q 'BILAN verbe=propose cible=phase-2 ecrit=1 code=0$'; } || return 1
  LASTMSG="la ligne de marqueur ne suit pas immédiatement la ligne Goal de la phase 2"
  [ "$(line_after "$(RMF)" '**Goal:** deux')" = '**Validation:** proposed' ] || return 1
  LASTMSG="le gate sur la phase posée n'a pas rendu 1 (proposée)"
  gate_p 2; [ $? -eq 1 ]
}
probe_trace2() {
  mklab t2 "$RM3" ""
  run propose --phase 2
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "validate au poste dev attendu rc 0 + ECRIT phase 2 : validated (dev, <date>)"
  { [ "$RC" -eq 0 ] && has 'ECRIT phase 2 : validated (dev, '; } || return 1
  LASTMSG="la ligne de marqueur n'est pas '**Validation:** validated (dev, <date du jour>)'"
  marker_is "$(RMF)" 'validated (dev, ' || return 1
  LASTMSG="le gate sur la phase validée n'a pas rendu 0"
  gate_p 2
}
probe_trace3() {
  mklab t3 "$RM3" ""
  local a; a="$(sum "$(RMF)")"
  run propose --phase 9
  msg "propose --phase 9 (absente) attendu rc 3 + INDETERMINE phase introuvable"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  LASTMSG="le ROADMAP a changé malgré le refus"; [ "$(sum "$(RMF)")" = "$a" ]
}
probe_trace4() {
  run
  msg "aucun argument attendu rc 64 + message sur stderr"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run bogus --phase 2
  msg "verbe inconnu attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run propose --phase 2 --architecture x.md
  msg "--phase et --architecture ensemble attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run propose
  msg "aucune cible attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run propose --phase abc
  msg "--phase abc attendu rc 64"; [ "$RC" -eq 64 ]
}
case_ VFV-TRACE-1 probe_trace1
case_ VFV-TRACE-2 probe_trace2
case_ VFV-TRACE-3 probe_trace3
case_ VFV-TRACE-4 probe_trace4

# === (suite : règles de poste, états, octets, compartiments, architecture) ===

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
