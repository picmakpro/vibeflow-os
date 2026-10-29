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
# marker_is <fichier> <début de valeur> [fin, défaut ")"] : exactement une ligne de marqueur, valeur exacte =
# début + date (avant ou après l'appel) + fin.
marker_is() {
  local a="$2" z="${3:-)}" got
  got="$(awk '/^\*\*Validation:\*\*/' "$1")"
  [ "$(printf '%s\n' "$got" | awk 'END { print NR }')" = 1 ] || return 1
  [ "$got" = "**Validation:** $a$D1$z" ] || [ "$got" = "**Validation:** $a$D2$z" ]
}
# nmark <fichier> : nombre de lignes de marqueur.
nmark() { awk '/^\*\*Validation:\*\*/ { n++ } END { print n + 0 }' "$1"; }

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

# === Poste du validateur (P60-H-02, P60-PL-06) =========================================================
probe_poste_product() {
  mklab pp "$RM3" ""; run propose --phase 2
  local a; a="$(sum "$(RMF)")"
  T_ROLE=product run validate --phase 2; T_ROLE=""
  msg "validate au poste product sans --override attendu rc 1 + REFUS poste product"
  { [ "$RC" -eq 1 ] && has 'REFUS poste product' && last | command grep -q 'ecrit=0 code=1$'; } || return 1
  LASTMSG="le ROADMAP a changé malgré le refus"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  T_ROLE=product run validate --phase 2 --override; T_ROLE=""
  msg "validate --override au poste product attendu rc 0 + ECRIT phase 2 : validated (product, "
  { [ "$RC" -eq 0 ] && has 'ECRIT phase 2 : validated (product, '; } || return 1
  LASTMSG="la valeur écrite n'est pas exactement 'validated (product, <date>, override)'"
  marker_is "$(RMF)" 'validated (product, ' ', override)' || return 1
  LASTMSG="le gate sur la phase validée sous override n'a pas rendu 0"; gate_p 2
}
probe_poste_solo() {
  mklab ps "$RM3" ""; run propose --phase 2
  T_ROLE=solo run validate --phase 2; T_ROLE=""
  msg "validate au poste solo attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="la valeur écrite n'est pas 'validated (solo, <date>)'"; marker_is "$(RMF)" 'validated (solo, ' || return 1
  # Fichier de poste absent : le lecteur répond solo (code 0), ce n'est pas un repli de l'écrivain.
  mklab ps2 "$RM3" ""; run propose --phase 2; run validate --phase 2
  msg "validate sans poste ni fichier de poste attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="la valeur écrite n'est pas 'validated (solo, <date>)' (fichier de poste absent)"; marker_is "$(RMF)" 'validated (solo, '
}
probe_poste_illisible() {
  mklab pi "$RM3" ""; run propose --phase 2
  local a; a="$(sum "$(RMF)")"
  T_ROLE=bogus run validate --phase 2; T_ROLE=""
  msg "poste invalide (lecteur code 1) attendu rc 5 + ILLISIBLE poste"
  { [ "$RC" -eq 5 ] && has 'ILLISIBLE poste illisible'; } || return 1
  LASTMSG="le ROADMAP a changé (poste invalide)"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  LASTMSG="validated (solo, ...) écrit sur un poste illisible"; [ "$(nmark "$(RMF)")" -eq 1 ] || return 1
  mkdir -p "$FX/pj/.claude"; printf 'dev\n' > "$FX/pj/target"; ln -s ../target "$FX/pj/.claude/vibeflow-role"
  T_PROJ="$FX/pj" run validate --phase 2; T_PROJ="$TMP/proj"
  msg "fichier de poste lien symbolique (lecteur code 5) attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  LASTMSG="le ROADMAP a changé (fichier de poste lien symbolique)"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  grep -q 'proposed' "$(RMF)"
}
case_ VFV-POSTE-PRODUCT probe_poste_product
case_ VFV-POSTE-SOLO probe_poste_solo
case_ VFV-POSTE-ILLISIBLE probe_poste_illisible

# === États jamais dégradés ===============================================================================
VALD=$'**Validation:** validated (dev, 2026-10-29)\n'
probe_propose_validee() {
  mklab pv "$RM3" "$VALD"; local a; a="$(sum "$(RMF)")"
  run propose --phase 2
  msg "propose sur une phase validated attendu rc 3, jamais repassée à proposed"; [ "$RC" -eq 3 ] || return 1
  LASTMSG="le ROADMAP a changé"; [ "$(sum "$(RMF)")" = "$a" ]
}
probe_idempotent() {
  mklab id "$RM3" ""; run propose --phase 2; run propose --phase 2
  msg "second propose attendu rc 0 + INCHANGE phase 2 : deja proposee"
  { [ "$RC" -eq 0 ] && has 'INCHANGE phase 2 : deja proposee'; } || return 1
  LASTMSG="plus d'une ligne de marqueur après deux propose"; [ "$(nmark "$(RMF)")" -eq 1 ]
}
probe_absent_validate() {
  mklab av "$RM3" ""; local a; a="$(sum "$(RMF)")"
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "validate sur marqueur absent attendu rc 0 + INCHANGE deja validee"
  { [ "$RC" -eq 0 ] && has 'INCHANGE phase 2 : deja validee'; } || return 1
  LASTMSG="le ROADMAP a changé (marqueur absent)"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  mklab av2 "$RM3" "$VALD"; a="$(sum "$(RMF)")"
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "validate sur une phase déjà validated attendu rc 0 + INCHANGE"
  { [ "$RC" -eq 0 ] && has 'INCHANGE phase 2 : deja validee'; } || return 1
  LASTMSG="le ROADMAP a changé (déjà validée)"; [ "$(sum "$(RMF)")" = "$a" ]
}
probe_inconnu() {
  mklab in "$RM3" $'**Validation:** ok\n'; local a; a="$(sum "$(RMF)")"
  run propose --phase 2
  msg "propose sur valeur inconnue attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "validate sur valeur inconnue attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  LASTMSG="le ROADMAP a changé"; [ "$(sum "$(RMF)")" = "$a" ]
}
probe_multi() {
  mklab mu "$RM3" $'**Validation:** proposed\n**Validation:** proposed\n'; local a; a="$(sum "$(RMF)")"
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "deux lignes de marqueur attendu rc 3 + marqueurs multiples"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE marqueurs multiples'; } || return 1
  run propose --phase 2
  msg "propose avec deux marqueurs attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  LASTMSG="le ROADMAP a changé"; [ "$(sum "$(RMF)")" = "$a" ]
}
probe_sans_goal() {
  mklab sg '# Roadmap\n\n### Phase 1: Premiere\n**Goal:** un\n\n### Phase 2: Deuxieme\nUne description sans but.\n\n### Phase 3: Troisieme\n**Goal:** trois\n'
  local a; a="$(sum "$(RMF)")"
  run propose --phase 2
  msg "section sans **Goal:** attendu rc 3 + section sans Goal"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE section sans Goal'; } || return 1
  LASTMSG="le ROADMAP a changé"; [ "$(sum "$(RMF)")" = "$a" ]
}
case_ VFV-PROPOSE-VALIDEE probe_propose_validee
case_ VFV-IDEMPOTENT probe_idempotent
case_ VFV-ABSENT-VALIDATE probe_absent_validate
case_ VFV-INCONNU probe_inconnu
case_ VFV-MULTI probe_multi
case_ VFV-SANS-GOAL probe_sans_goal

# === Goal multi-ligne, octets, fins de ligne, mode ======================================================
RMG='# Roadmap\n\n### Phase 1: Premiere\n**Goal:** un\n\n### Phase 2: Deuxieme\n**Goal:** deux\nsuite du but\n%s**Requirements**: TBD\n\n### Phase 3: Troisieme\n**Goal:** trois\n'
probe_goal_multi() {
  mklab gm1 "$RMG" ""; run propose --phase 2
  msg "Goal sur deux lignes (suivi de **Requirements** sans blanc) attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur n'est pas inséré après la SECONDE ligne du Goal"
  [ "$(line_after "$(RMF)" 'suite du but')" = '**Validation:** proposed' ] || return 1
  [ "$(line_after "$(RMF)" '**Validation:** proposed')" = '**Requirements**: TBD' ] || return 1
  LASTMSG="le gate sur le Goal multi-ligne n'a pas rendu 1"; gate_p 2; [ $? -eq 1 ] || return 1
  mklab gm2 "$RMG" $'\n'; run propose --phase 2
  msg "Goal sur deux lignes (suivi d'une ligne blanche) attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur n'est pas inséré juste après la seconde ligne du Goal (variante avec ligne blanche)"
  [ "$(line_after "$(RMF)" 'suite du but')" = '**Validation:** proposed' ] || return 1
  gate_p 2; [ $? -eq 1 ]
}
probe_octets() {
  mklab oc "$RM3" ""; cp "$(RMF)" "$TMP/oc.orig"
  run propose --phase 2
  awk '!/^\*\*Validation:\*\*/' "$(RMF)" > "$TMP/oc.strip"
  LASTMSG="après propose, le fichier privé de la ligne de marqueur n'est pas identique à l'original (cmp)"
  cmp -s "$TMP/oc.orig" "$TMP/oc.strip" || return 1
  cp "$(RMF)" "$TMP/oc.prop"
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  LASTMSG="après validate, il n'y a pas exactement une ligne qui diffère (ou le nombre de lignes a changé)"
  awk 'NR == FNR { a[FNR] = $0; n = FNR; next } { if (a[FNR] != $0) d++; m = FNR } END { exit !(d == 1 && n == m) }' "$TMP/oc.prop" "$(RMF)" || return 1
  # Dernière ligne sans fin de ligne : le marqueur devient la dernière ligne, sans fin de ligne non plus.
  mklab ne '# Roadmap\n\n### Phase 1: A\n**Goal:** un'
  run propose --phase 1
  printf '# Roadmap\n\n### Phase 1: A\n**Goal:** un\n**Validation:** proposed' > "$TMP/ne.exp"
  msg "fichier sans fin de ligne finale attendu octet pour octet"; [ "$RC" -eq 0 ] && cmp -s "$TMP/ne.exp" "$(RMF)"
}
probe_crlf() {
  mkdir -p "$FX/crlf/.planning"; RUNDIR="$FX/crlf"
  printf "$RM3" "" | awk '{ printf "%s\r\n", $0 }' > "$(RMF)"
  run propose --phase 2
  msg "ROADMAP CRLF attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="la ligne insérée ne porte pas le CR de sa voisine"
  [ "$(awk '/^\*\*Validation:\*\* proposed\r$/ { n++ } END { print n + 0 }' "$(RMF)")" -eq 1 ] || return 1
  LASTMSG="une ligne du ROADMAP a perdu son CR"; awk '{ n++ } /\r$/ { c++ } END { exit !(n == c) }' "$(RMF)" || return 1
  LASTMSG="le gate sur le ROADMAP CRLF n'a pas rendu 1"; gate_p 2; [ $? -eq 1 ] || return 1
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "validate sur ROADMAP CRLF attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="la ligne remplacée ne porte pas le CR de l'ancienne"
  [ "$(awk '/^\*\*Validation:\*\* validated \(dev, [0-9-]*\)\r$/ { n++ } END { print n + 0 }' "$(RMF)")" -eq 1 ] || return 1
  gate_p 2
}
probe_mode() {
  mklab mo "$RM3" ""; chmod 0640 "$(RMF)"
  local m1 m2
  m1="$(ls -l "$(RMF)" | cut -d' ' -f1)"
  run propose --phase 2; T_ROLE=dev run validate --phase 2; T_ROLE=""
  m2="$(ls -l "$(RMF)" | cut -d' ' -f1)"
  LASTMSG="le mode du fichier a changé ($m1 -> $m2)"; [ "$m1" = "$m2" ] || return 1
  LASTMSG="un fichier temporaire est resté dans le dossier de planning"
  [ "$(ls -A "$RUNDIR/.planning" | wc -l | tr -d ' ')" = 1 ]
}
case_ VFV-GOAL-MULTI probe_goal_multi
case_ VFV-OCTETS probe_octets
case_ VFV-CRLF probe_crlf
case_ VFV-MODE probe_mode

# === Compartiments et entrées non fiables ================================================================
mkws() { # <nom> : lab partitionné sous $FX/<nom> (racine, w1, w2) ; positionne RUNDIR
  RUNDIR="$FX/$1"; mkdir -p "$RUNDIR/.planning/workstreams/w1" "$RUNDIR/.planning/workstreams/w2"
  printf "$RM3" "" > "$RUNDIR/.planning/ROADMAP.md"
  printf "$RM3" "" > "$RUNDIR/.planning/workstreams/w1/ROADMAP.md"
  printf "$RM3" "" > "$RUNDIR/.planning/workstreams/w2/ROADMAP.md"
}
probe_ws() {
  mkws ws; local P="$RUNDIR/.planning" r w2
  r="$(sum "$P/ROADMAP.md")"; w2="$(sum "$P/workstreams/w2/ROADMAP.md")"
  run propose --phase 2 --ws w1
  msg "propose --ws w1 attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le compartiment w2 ou la racine a changé"
  [ "$(sum "$P/workstreams/w2/ROADMAP.md")" = "$w2" ] && [ "$(sum "$P/ROADMAP.md")" = "$r" ] || return 1
  LASTMSG="w1 n'a pas reçu le marqueur"; gate_p 2 w1; [ $? -eq 1 ] || return 1
  LASTMSG="w2 ne devait pas être touché"; gate_p 2 w2 || return 1
  printf 'w1\n' > "$P/active-workstream"
  export GSD_WORKSTREAM=w1 VF_WORKSTREAM=w1
  run propose --phase 2
  unset GSD_WORKSTREAM VF_WORKSTREAM
  msg "lab partitionné sans --ws (compartiment actif w1 présent) attendu rc 3 + lab partitionne sans --ws"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE lab partitionne sans --ws'; } || return 1
  LASTMSG="une écriture a eu lieu sans --ws"
  [ "$(sum "$P/workstreams/w2/ROADMAP.md")" = "$w2" ] && [ "$(sum "$P/ROADMAP.md")" = "$r" ] || return 1
  run propose --phase 2 --ws nope
  msg "compartiment absent attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  run propose --phase 2 --ws ../x
  msg "nom de compartiment refusé attendu rc 64"; [ "$RC" -eq 64 ]
}
probe_lien() {
  mklab ln "$RM3" ""; mv "$(RMF)" "$RUNDIR/real.md"; ln -s ../real.md "$(RMF)"
  local a; a="$(sum "$RUNDIR/real.md")"
  run propose --phase 2
  msg "ROADMAP lien symbolique attendu rc 5 + ILLISIBLE roadmap : lien symbolique"
  { [ "$RC" -eq 5 ] && has 'ILLISIBLE roadmap : lien symbolique'; } || return 1
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "validate sur ROADMAP lien symbolique attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  LASTMSG="la cible du lien a changé"; [ "$(sum "$RUNDIR/real.md")" = "$a" ] && [ -L "$(RMF)" ] || return 1
  mkws wl; mv "$RUNDIR/.planning/workstreams/w1" "$RUNDIR/real-w1"; ln -s ../../real-w1 "$RUNDIR/.planning/workstreams/w1"
  run propose --phase 2 --ws w1
  msg "compartiment lien symbolique attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  LASTMSG="le dossier cible du lien a été écrit"; gate_p 2 w2 && ! grep -q 'Validation' "$RUNDIR/real-w1/ROADMAP.md"
}
probe_illisible() {
  mklab il "$RM3" ""; rm "$(RMF)"; mkfifo "$(RMF)"
  run propose --phase 2
  msg "ROADMAP FIFO attendu rc 5 (refus avant lecture)"; [ "$RC" -eq 5 ] || return 1
  mklab il2 "$RM3" ""; rm "$(RMF)"; mkdir "$(RMF)"
  run propose --phase 2
  msg "ROADMAP dossier attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  mklab il3 "$RM3" ""; head -c 1048577 /dev/zero | tr '\0' 'a' > "$(RMF)"; local a; a="$(sum "$(RMF)")"
  run propose --phase 2
  msg "ROADMAP au-delà de 1048576 octets attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  LASTMSG="le gros fichier a changé"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  mklab il4 '### Phase 2: X\n**Goal:** a\rb\n'; a="$(sum "$(RMF)")"
  run propose --phase 2
  msg "CR isolé attendu rc 5 (jamais réécrit)"; [ "$RC" -eq 5 ] || return 1
  LASTMSG="le fichier à CR isolé a changé"; [ "$(sum "$(RMF)")" = "$a" ]
}
case_ VFV-WS probe_ws
case_ VFV-LIEN probe_lien
case_ VFV-ILLISIBLE probe_illisible

# === Architecture (P60-D-05) ===============================================================================
ARCH_OK=$'# Architecture — Demo\n\n**Validation:** proposed\n\n## Contexte\nProduit de demonstration.\n\n## Choix structurants\n- Choix un\n\n## Composants et responsabilites\n- Composant un\n\n## Données\nLes donnees vivent dans une base.\n\n## Contraintes\n- Contrainte une\n\n## Risques et questions ouvertes\n- Risque un\n'
TPL="$SDIR/../../planning-core/references/templates/product/ARCHITECTURE.template.md"
probe_archi() {
  RUNDIR="$FX/ar"; mkdir -p "$RUNDIR"; printf '%s' "$ARCH_OK" > "$RUNDIR/A.md"
  gate_a "$RUNDIR/A.md"; [ $? -eq 1 ] || { LASTMSG="témoin : l'architecture proposée n'est pas rouge au gate"; return 1; }
  T_ROLE=dev run validate --architecture "$RUNDIR/A.md"; T_ROLE=""
  msg "validate --architecture au poste dev attendu rc 0 + ECRIT architecture : validated (dev, "
  { [ "$RC" -eq 0 ] && has 'ECRIT architecture : validated (dev, ' && last | command grep -q 'cible=architecture ecrit=1 code=0$'; } || return 1
  marker_is "$RUNDIR/A.md" 'validated (dev, ' || { LASTMSG="ligne d'état non validated (dev, <date>)"; return 1; }
  LASTMSG="check-architecture n'a pas rendu 0 sur l'architecture complète validée"; gate_a "$RUNDIR/A.md" || return 1
  if [ -f "$TPL" ]; then
    cp "$TPL" "$RUNDIR/B.md"
    T_ROLE=dev run validate --architecture "$RUNDIR/B.md"; T_ROLE=""
    msg "validate sur la copie brute du gabarit attendu rc 0 (l'écrivain ne juge pas les rubriques)"; [ "$RC" -eq 0 ] || return 1
    marker_is "$RUNDIR/B.md" 'validated (dev, ' || { LASTMSG="ligne d'état du gabarit non validated"; return 1; }
    LASTMSG="la validation a contourné les rubriques vides : le gate devait rester rouge (1)"; gate_a "$RUNDIR/B.md"; [ $? -eq 1 ] || return 1
  fi
  T_ROLE=dev run validate --architecture "$RUNDIR/absent.md"
  msg "fichier absent attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  printf '# Architecture\n\n## Contexte\nrien\n' > "$RUNDIR/C.md"; local a; a="$(sum "$RUNDIR/C.md")"
  T_ROLE=dev run validate --architecture "$RUNDIR/C.md"; T_ROLE=""
  msg "ligne d'état absente attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  printf '%s' "$ARCH_OK" > "$RUNDIR/D.md"; a="$(sum "$RUNDIR/D.md")"
  T_ROLE=product run validate --architecture "$RUNDIR/D.md"; T_ROLE=""
  msg "architecture au poste product sans --override attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  LASTMSG="le fichier a changé malgré le refus"; [ "$(sum "$RUNDIR/D.md")" = "$a" ] || return 1
  T_ROLE=product run validate --architecture "$RUNDIR/D.md" --override; T_ROLE=""
  msg "architecture au poste product avec --override attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  marker_is "$RUNDIR/D.md" 'validated (product, ' ', override)'
}
case_ VFV-ARCHI probe_archi

# === Aucun écho du contenu, formes d'appel ===================================================================
probe_noecho() {
  mklab ne2 '# Roadmap\n\n### Phase 2: zzSECRETzz titre\n**Goal:** zzSECRETzz\n'
  run propose --phase 2; local o="$OUT$ERR"
  T_ROLE=dev run validate --phase 2; T_ROLE=""; o="$o$OUT$ERR"
  mklab ne3 '# Roadmap\n\n### Phase 2: zzSECRETzz titre\n**Goal:** g\n**Validation:** zzSECRETzz\n'
  run propose --phase 2; o="$o$OUT$ERR"
  T_ROLE=dev run validate --phase 2; T_ROLE=""; o="$o$OUT$ERR"
  LASTMSG="le contenu du ROADMAP est réimprimé (zzSECRETzz sur stdout ou stderr)"
  case "$o" in *zzSECRETzz*) return 1 ;; esac
  return 0
}
probe_forme() {
  mklab fo "$RM3" ""
  run propose --phase=2
  msg "--phase=2 attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  run --help
  msg "--help attendu rc 0 + contrat"; { [ "$RC" -eq 0 ] && has 'Le code 2 n'"'"'est jamais émis' && has '--override'; } || return 1
  run propose --phase 2 --phase 3
  msg "--phase répété attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run propose --phase 2 --override
  msg "propose --override attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run validate --architecture x.md --ws w1
  msg "--architecture avec --ws attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run propose --architecture x.md
  msg "propose --architecture attendu rc 64"; [ "$RC" -eq 64 ] || return 1
  run validate --phase
  msg "--phase sans valeur attendu rc 64"; [ "$RC" -eq 64 ]
}
case_ VFV-NOECHO probe_noecho
case_ VFV-FORME probe_forme

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
