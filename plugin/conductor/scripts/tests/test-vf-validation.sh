#!/usr/bin/env bash
# Test de vf-validation.sh (Phase 60, ARCG-01, ARCG-06, ARCG-09 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P60-PL-20) : aucun dossier fixtures/ versionné, aucune
# écriture dans le ROADMAP du dépôt. L'écrivain et les deux gates juges (check-phase-validation.sh, check-architecture.sh)
# se retrouvent par ../, en source comme une fois copiés à plat par l'engine (la suite se pose sous scripts/tests/).
# Le poste est fixé par cas (VF_ROLE) ; la date du jour est lue avant et après chaque appel (deux valeurs admises).
# Cas VFV-TRACE-1..4 : poser puis valider une phase, constaté par le gate de bout en bout.
# Cas VFV-POSTE-*, VFV-PROPOSE-VALIDEE, VFV-IDEMPOTENT, VFV-ABSENT-VALIDATE, VFV-INCONNU, VFV-MULTI, VFV-SANS-GOAL,
# VFV-GOAL-MULTI, VFV-OCTETS, VFV-INDENT, VFV-CRLF, VFV-MODE, VFV-WS, VFV-LIEN, VFV-ARCHI, VFV-NOECHO : règles de l'écrivain.
# Cas VFV-GSD-* : les lecteurs du moteur GSD rendent la même chose sur la sortie de l'écrivain que sans marqueur.
# Cas VFV-IDS, VFV-DETAILS, VFV-FENCE-COMMONMARK, VFV-ARCHI-BORNE, VFV-PLANNING-LIEN (grammaire de gsd-core, jalons livrés, barrières
# CommonMark, bornes de --architecture et de .planning).
# Mutants VFV-MUT-1..22 : une ligne du script altérée, différente (cmp -s), valide (bash -n), sonde rouge sur le
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
  rm -rf "$RUNDIR"
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
  run propose --phase .5
  msg "--phase .5 attendu rc 64"; [ "$RC" -eq 64 ]
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
  rm -rf "$FX/pj"; mkdir -p "$FX/pj/.claude"; printf 'dev\n' > "$FX/pj/target"; ln -s ../target "$FX/pj/.claude/vibeflow-role"
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
probe_ressemblant() {
  # P60-H-04 : une ligne qui ressemble à un marqueur sans en avoir la forme (puce, citation, minuscules…) n'est ni
  # « absent » ni écrasée : l'écrivain la lit comme un marqueur illisible (rc 3) et ne touche pas au fichier.
  local m n=0 a
  for m in '- **Validation:** proposed' '> **Validation:** proposed' 'Validation: proposed' '**validation:** proposed'; do
    n=$((n+1)); mklab "re$n" "$RM3" "$m"$'\n'; a="$(sum "$(RMF)")"
    run propose --phase 2
    msg "propose sur la ligne « $m » attendu rc 3 (marqueur illisible), jamais une ligne ajoutée à côté"; [ "$RC" -eq 3 ] || return 1
    T_ROLE=dev run validate --phase 2; T_ROLE=""
    msg "validate sur la ligne « $m » attendu rc 3, jamais rc 0 « absent »"; [ "$RC" -eq 3 ] || return 1
    LASTMSG="le ROADMAP a changé"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  done
  mklab "re-t" "$RM3" $'Validation: les tests passent\n'
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "ligne ordinaire sur la validation des tests : validate attendu rc 0 (marqueur absent), pas de sur-détection"; [ "$RC" -eq 0 ]
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
case_ VFV-RESSEMBLANT probe_ressemblant
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
  RUNDIR="$FX/crlf"; rm -rf "$RUNDIR"; mkdir -p "$RUNDIR/.planning"
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
probe_indent() {
  local pad nm
  for pad in '  ' $'\t'; do
    nm=in$(printf '%s' "$pad" | od -An -tx1 | tr -d ' \n')
    mklab "$nm" "$RM3" "${pad}**Validation:** proposed"$'\n'; cp "$(RMF)" "$TMP/in.orig"
    T_ROLE=dev run validate --phase 2; T_ROLE=""
    msg "validate sur un marqueur indenté attendu rc 0"; [ "$RC" -eq 0 ] || return 1
    LASTMSG="l'indentation de la ligne de marqueur n'est pas conservée (ligne attendue : indentation + validated (dev, <date>))"
    local got; got="$(awk '/^[ \t]*\*\*Validation:\*\*/' "$(RMF)")"
    [ "$got" = "${pad}**Validation:** validated (dev, $D1)" ] || [ "$got" = "${pad}**Validation:** validated (dev, $D2)" ] || return 1
    LASTMSG="plus d'une ligne diffère de l'original, ou le nombre de lignes a changé"
    awk 'NR == FNR { a[FNR] = $0; n = FNR; next } { if (a[FNR] != $0) d++; m = FNR } END { exit !(d == 1 && n == m) }' "$TMP/in.orig" "$(RMF)" || return 1
    LASTMSG="le gate sur le marqueur indenté validé n'a pas rendu 0"; gate_p 2 || return 1
  done
}
case_ VFV-OCTETS probe_octets
case_ VFV-INDENT probe_indent
case_ VFV-CRLF probe_crlf
case_ VFV-MODE probe_mode

# === Compartiments et entrées non fiables ================================================================
mkws() { # <nom> : lab partitionné sous $FX/<nom> (racine, w1, w2) ; positionne RUNDIR
  RUNDIR="$FX/$1"; rm -rf "$RUNDIR"; mkdir -p "$RUNDIR/.planning/workstreams/w1" "$RUNDIR/.planning/workstreams/w2"
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
  RUNDIR="$FX/ar"; rm -rf "$RUNDIR"; mkdir -p "$RUNDIR"; printf '%s' "$ARCH_OK" > "$RUNDIR/A.md"
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

# === Grammaire de --phase alignée sur gsd-core, jalons livrés, barrières CommonMark, bornes de --architecture ==
# written_after <fichier> <ligne exacte> : la ligne de marqueur suit immédiatement la ligne donnée.
written_after() { [ "$(line_after "$1" "$2")" = '**Validation:** proposed' ]; }
probe_ids_w() {
  mklab iw1 '# Roadmap\n\n### Phase AUTH: Auth\n**Goal:** goal-auth\n\n### Phase 12A: Suf\n**Goal:** goal-12a\n\n### Phase 7.1A: Dec\n**Goal:** goal-71a\n'
  run propose --phase AUTH
  msg "propose --phase AUTH (id custom) attendu rc 0 + ECRIT phase AUTH : proposed"; { [ "$RC" -eq 0 ] && has 'ECRIT phase AUTH : proposed'; } || return 1
  LASTMSG="la ligne de marqueur ne suit pas le Goal de la phase AUTH"; written_after "$(RMF)" '**Goal:** goal-auth' || return 1
  LASTMSG="le gate sur AUTH n'a pas rendu 1"; gate_p AUTH; [ $? -eq 1 ] || return 1
  T_ROLE=dev run validate --phase auth; T_ROLE=""
  msg "validate --phase auth (casse indifférente) attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le gate sur AUTH n'a pas rendu 0 après validate"; gate_p AUTH || return 1
  run propose --phase 12A
  msg "propose --phase 12A attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur de 12A n'est pas sous son Goal"; written_after "$(RMF)" '**Goal:** goal-12a' || return 1
  run propose --phase 7.1A
  msg "propose --phase 7.1A attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur de 7.1A n'est pas sous son Goal"; written_after "$(RMF)" '**Goal:** goal-71a' || return 1
  run propose --phase 12
  msg "12 ne désigne pas 12A, attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  mklab iw2 '# Roadmap\n\n### Phase 3: Nue\n**Goal:** goal-nue\n\n### Phase CK-03: Pref\n**Goal:** goal-pref\n'
  run propose --phase 3
  msg "la forme exacte gagne : propose --phase 3 attendu rc 0 (jamais sections multiples)"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur de la phase 3 n'est pas sous son Goal"; written_after "$(RMF)" '**Goal:** goal-nue' || return 1
  LASTMSG="la phase CK-03 a été écrite à tort"; [ "$(line_after "$(RMF)" '**Goal:** goal-pref')" = '' ] || return 1
  mklab iw3 '# Roadmap\n\n### Phase CK-03: Pref\n**Goal:** goal-pref\n'
  run propose --phase 3
  msg "lecture tolérante : propose --phase 3 désigne CK-03, attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur de CK-03 n'est pas sous son Goal"; written_after "$(RMF)" '**Goal:** goal-pref' || return 1
  local bad
  for bad in .5 'a;b' 'a..b'; do
    run propose --phase "$bad"
    msg "propose --phase « $bad » attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  done
}
probe_details_w() {
  mklab dw1 '# Roadmap\n\n<details>\n<summary>v1.0 shipped</summary>\n\n### Phase 1: Vieille\n**Goal:** goal-vieux\n\n### Phase 5: Seule\n**Goal:** goal-seule\n\n</details>\n\n### Phase 1: Neuve\n**Goal:** goal-neuf\n'
  local a; a="$(sum "$(RMF)")"
  run propose --phase 1
  msg "phase 1 vivante à côté d'une phase 1 du bloc livré : attendu rc 0, jamais sections multiples"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur n'est pas sous le Goal de la phase vivante"; written_after "$(RMF)" '**Goal:** goal-neuf' || return 1
  LASTMSG="le bloc livré a été écrit"; [ "$(line_after "$(RMF)" '**Goal:** goal-vieux')" = '' ] || return 1
  [ "$(nmark "$(RMF)")" = 1 ] || { LASTMSG="plus d'un marqueur écrit"; return 1; }
  mklab dw2 '# Roadmap\n\n<details>\n### Phase 5: Seule\n**Goal:** goal-seule\n</details>\n'
  a="$(sum "$(RMF)")"
  run propose --phase 5
  msg "phase présente seulement dans le bloc livré attendu rc 3 + phase introuvable"; { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  LASTMSG="le ROADMAP a changé malgré le refus"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  mklab dw3 '# Roadmap\n\n### Phase 3: Titre<details>\ncache\n</details>\n**Goal:** goal-t\n'
  run propose --phase 3
  msg "le titre qui précède un <details> sur sa ligne reste visible : attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur n'est pas sous le Goal"; written_after "$(RMF)" '**Goal:** goal-t'
}
# Jalon ACTIF en <details> : le gate le lit, le verbe d'écriture voit la même phase (même grammaire, même jalon).
probe_details_actif_w() {
  mklab da1 '# Roadmap\n\n<details>\n<summary>🚧 v2.0 in progress</summary>\n\n### Phase 5: Active\n**Goal:** goal-actif\n\n</details>\n'
  run propose --phase 5
  msg "phase d'un jalon actif en <details> : propose attendu rc 0 (la même phase que lit le gate)"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur n'est pas sous le Goal de la phase active"; written_after "$(RMF)" '**Goal:** goal-actif' || return 1
  mklab da2 '# Roadmap\n\n<details>\n<summary>✅ v1.0 SHIPPED</summary>\n\n### Phase 5: Livree\n**Goal:** goal-livre\n\n</details>\n'
  local a; a="$(sum "$(RMF)")"
  run propose --phase 5
  msg "phase d'un jalon livré : propose attendu rc 3 + phase introuvable"; { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  LASTMSG="le ROADMAP a changé malgré le refus"; [ "$(sum "$(RMF)")" = "$a" ]
}
probe_fence_w() {
  mklab fw1 '# Roadmap\n\n### Phase 2: Deux\n``` `x` ```\n**Goal:** goal-deux\n'
  run propose --phase 2
  msg "une ligne trois-accents-graves + info string à accent grave n'est pas une barrière : le Goal reste vu, attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur n'est pas sous le Goal"; written_after "$(RMF)" '**Goal:** goal-deux' || return 1
  mklab fw2 '# Roadmap\n\n### Phase 2: Deux\n````\n**Goal:** dedans\n```\n**Goal:** goal-deux\n'
  local a; a="$(sum "$(RMF)")"
  run propose --phase 2
  msg "une barrière de 4 accents n'est pas fermée par 3 : bloc jamais fermé, attendu rc 3 + bloc de code non ferme"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE bloc de code non ferme'; } || return 1
  LASTMSG="le ROADMAP a changé malgré le refus"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  mklab fw3 '# Roadmap\n\n### Phase 2: Deux\n```\n```js\n**Goal:** dedans\n```\n**Goal:** goal-deux\n'
  run propose --phase 2
  msg "une ligne trois-accents-graves+js (info string) ne ferme pas : le premier Goal reste caché, attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  LASTMSG="le marqueur doit suivre le Goal hors bloc"; written_after "$(RMF)" '**Goal:** goal-deux'
}
probe_arch_borne() {
  RUNDIR="$FX/ab"; rm -rf "$RUNDIR"; mkdir -p "$RUNDIR/lab/sub" "$RUNDIR/outside"
  printf '%s' "$ARCH_OK" > "$RUNDIR/outside/A.md"; printf '%s' "$ARCH_OK" > "$RUNDIR/lab/sub/A.md"
  ln -s ../outside "$RUNDIR/lab/lien"
  local a; a="$(sum "$RUNDIR/outside/A.md")"; local root="$RUNDIR"; RUNDIR="$root/lab"
  T_ROLE=dev run validate --architecture ../outside/A.md; T_ROLE=""
  msg "--architecture ../outside/A.md (hors racine) attendu rc 5 + ILLISIBLE hors de la racine"; { [ "$RC" -eq 5 ] && has 'hors de la racine'; } || return 1
  LASTMSG="le fichier hors racine a été écrit"; [ "$(sum "$root/outside/A.md")" = "$a" ] || return 1
  T_ROLE=dev run validate --architecture "$root/outside/A.md"; T_ROLE=""
  msg "--architecture absolu hors racine attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  T_ROLE=dev run validate --architecture lien/A.md; T_ROLE=""
  msg "--architecture par un dossier en lien symbolique vers l'extérieur attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  LASTMSG="le fichier derrière le lien a été écrit"; [ "$(sum "$root/outside/A.md")" = "$a" ] || return 1
  T_ROLE=dev run validate --architecture sub/A.md; T_ROLE=""
  msg "témoin positif : --architecture sub/A.md (dans la racine) attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  T_ROLE=dev run validate --architecture sub/../sub/absent.md; T_ROLE=""
  msg "fichier absent dans la racine attendu rc 3"; [ "$RC" -eq 3 ]
}
probe_arch_cwd() {
  # P60-H : la racine de --architecture est le RÉPERTOIRE COURANT, pas la racine du dépôt git : un fichier du dépôt mais hors du
  # répertoire courant est refusé (rc 5), jamais écrit.
  command -v git >/dev/null 2>&1 || { LASTMSG="git absent"; return 0; }
  RUNDIR="$FX/ac"; rm -rf "$RUNDIR"; mkdir -p "$RUNDIR/lab"
  ( cd "$RUNDIR" && git init -q . ) >/dev/null 2>&1 || { LASTMSG="git init impossible"; return 1; }
  printf '%s' "$ARCH_OK" > "$RUNDIR/A.md"; printf '%s' "$ARCH_OK" > "$RUNDIR/lab/A.md"
  local a; a="$(sum "$RUNDIR/A.md")"; local root="$RUNDIR"; RUNDIR="$root/lab"
  T_ROLE=dev run validate --architecture ../A.md; T_ROLE=""
  msg "--architecture ../A.md (dans le dépôt git, hors du répertoire courant) attendu rc 5 + hors de la racine"; { [ "$RC" -eq 5 ] && has 'hors de la racine'; } || return 1
  LASTMSG="le fichier du dépôt, hors du répertoire courant, a été écrit"; [ "$(sum "$root/A.md")" = "$a" ] || return 1
  T_ROLE=dev run validate --architecture A.md; T_ROLE=""
  msg "témoin positif : --architecture A.md (dans le répertoire courant) attendu rc 0"; [ "$RC" -eq 0 ]
}
probe_planning_lien() {
  mklab pl "$RM3" ""; mv "$RUNDIR/.planning" "$RUNDIR/vrai-planning"; ln -s vrai-planning "$RUNDIR/.planning"
  local a; a="$(sum "$RUNDIR/vrai-planning/ROADMAP.md")"
  run propose --phase 2
  msg ".planning en lien symbolique attendu rc 5 + ILLISIBLE planning : lien symbolique"; { [ "$RC" -eq 5 ] && has 'ILLISIBLE planning : lien symbolique'; } || return 1
  T_ROLE=dev run validate --phase 2; T_ROLE=""
  msg "validate avec .planning en lien symbolique attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  LASTMSG="le ROADMAP derrière le lien a changé"; [ "$(sum "$RUNDIR/vrai-planning/ROADMAP.md")" = "$a" ] || return 1
  mklab pl2 "$RM3" ""
  run propose --phase 2
  msg "témoin positif : .planning réel attendu rc 0"; [ "$RC" -eq 0 ]
}
case_ VFV-IDS probe_ids_w

probe_ids_slug_w() {
  # Revue 2026-10-29 : mêmes refus que le gate pour un nom de dossier ou un identifiant de plan (64), sans écriture.
  local s a verb
  mklab sw1 '# Roadmap\n\n### Phase 60: Gate\n**Goal:** g\n'; a="$(sum "$(RMF)")"
  for s in 60-gate-architecture 60-02 12A-x; do
    for verb in propose validate; do
      T_ROLE=dev run "$verb" --phase "$s"; T_ROLE=""
      msg "$verb --phase $s attendu rc 64 (jamais 3 introuvable)"; [ "$RC" -eq 64 ] || return 1
    done
  done
  LASTMSG="le ROADMAP a changé"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  run propose --phase 60
  msg "propose --phase 60 attendu rc 0"; [ "$RC" -eq 0 ]
}
probe_titres_gsd_w() {
  local h n=0
  for h in '### phase 2: X' '### PHASE 2: X' '### [WIP] Phase 2: X' '###Phase 2: X' ' ### Phase 2: X'; do
    n=$((n+1)); mklab "tw-$n" '# Roadmap\n\n%s\n**Goal:** g\n' "$h"
    run propose --phase 2
    msg "propose sur le titre « $h » attendu rc 0 (section lue comme par le gate)"; [ "$RC" -eq 0 ] || return 1
    LASTMSG="le gate ne lit pas la phase proposée sur « $h »"; gate_p 2; [ $? -eq 1 ] || return 1
  done
}
probe_sosies_typo_w() {
  local m n=0 a nb=$'\xc2\xa0' nn=$'\xe2\x80\xaf'
  for m in "**Validation${nb}:** proposed" "**Validation${nn}:** proposed" '| Validation | proposed |' 'Validation — proposed'; do
    n=$((n+1)); mklab "sw-$n" "$RM3" "$m"$'\n'; a="$(sum "$(RMF)")"
    run propose --phase 2
    msg "propose sur le sosie « $m » attendu rc 3 (marqueur illisible), jamais une ligne ajoutée à côté"; [ "$RC" -eq 3 ] || return 1
    LASTMSG="le ROADMAP a changé"; [ "$(sum "$(RMF)")" = "$a" ] || return 1
  done
}
case_ VFV-IDS-SLUG probe_ids_slug_w
case_ VFV-TITRES-GSD probe_titres_gsd_w
case_ VFV-SOSIES-TYPO probe_sosies_typo_w
case_ VFV-DETAILS probe_details_w
case_ VFV-DETAILS-ACTIF probe_details_actif_w
case_ VFV-FENCE-COMMONMARK probe_fence_w
case_ VFV-ARCHI-BORNE probe_arch_borne
case_ VFV-ARCHI-CWD probe_arch_cwd
case_ VFV-PLANNING-LIEN probe_planning_lien

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

# === Preuve moteur GSD : la sortie de l'écrivain ne change rien pour les lecteurs du moteur (P60-D-03 a, P60-PL-19) ===
# Même méthode que la preuve du gate de phase, écrite ICI sans dépendance d'une suite à l'autre : fixtures générées sous
# $TMP/gsd, moteur lancé avec --cwd sur ces seuls labs, jamais dans le dépôt. Aucun numéro de version du moteur.
GSDJS="${HOME:-/nonexistent}/.claude/gsd-core/bin/gsd-tools.cjs"
GSD="$TMP/gsd"; mkdir -p "$GSD"
GRC=0

# gsd_roadmap <titre de la phase 2> <ligne après la 1re ligne du Goal ou vide> <ligne de suite du Goal ou vide> : ROADMAP à
# trois phases, sur la forme que le moteur écrit (**Goal:**, **Requirements**, **Depends on:**, **Plans:**).
gsd_roadmap() {
  printf '# Roadmap\n\n## Milestone v1.0\n\n- [ ] Phase 1: Premiere\n- [ ] Phase 2: Deuxieme\n- [ ] Phase 3: Troisieme\n\n'
  printf '### Phase 1: Premiere\n**Goal:** un\n**Requirements**: TBD\n**Depends on:** Nothing\n**Plans:** 0 plans\n\n'
  printf '%s\n**Goal:** deux\n' "$1"
  if [ -n "$2" ]; then printf '%s\n' "$2"; fi
  if [ -n "$3" ]; then printf '%s\n' "$3"; fi
  printf '**Requirements**: TBD\n**Depends on:** Phase 1\n**Plans:** 0 plans\n\n'
  printf '### Phase 3: Troisieme\n**Goal:** trois\n**Requirements**: TBD\n**Depends on:** Phase 2\n**Plans:** 0 plans\n'
}
# gsd_mklab <nom> <compartiment ou -> <1re ligne après Goal> <suite du Goal> : lab sous $GSD/<nom>.
gsd_mklab() {
  local d="$GSD/$1/.planning"
  if [ "$2" != - ]; then d="$d/workstreams/$2"; fi
  mkdir -p "$d"; gsd_roadmap '### Phase 2: Deuxieme' "$3" "$4" > "$d/ROADMAP.md"
}
gsd_do() { # <lab> <compartiment ou -> <fichier de sortie> <arguments du moteur...>
  local lab="$1" ws="$2" out="$3"; shift 3
  if [ "$ws" = - ]; then
    (cd "$TMP" && perl -e 'alarm 30; exec @ARGV' node "$GSDJS" "$@" --cwd "$lab") > "$out" 2> "$out.err" < /dev/null
  else
    (cd "$TMP" && perl -e 'alarm 30; exec @ARGV' node "$GSDJS" "$@" --cwd "$lab" --ws "$ws") > "$out" 2> "$out.err" < /dev/null
  fi
  GRC=$?
}
# gsd_norm <drop> <lab> <fichier brut> : chemin du lab remplacé par un jeton fixe ; drop=1 retire la seule ligne "section":.
gsd_norm() {
  LAB="$2" awk -v drop="$1" 'BEGIN { l = ENVIRON["LAB"] }
    { if (drop == "1" && $0 ~ /^[ \t]*"section":/) next
      while ((i = index($0, l)) > 0) $0 = substr($0, 1, i - 1) "<LAB>" substr($0, i + length(l))
      print }' "$3"
}
# gsd_same <drop> <compartiment ou -> <attendu> <labA> <labB> <arguments du moteur...> -> 0 identique, 1 différent,
# 2 référence inutilisable (moteur en erreur, sortie vide ou sans le jeton <attendu> : un « identique » ne vaudrait rien).
gsd_same() {
  local drop="$1" ws="$2" want="$3" a="$4" b="$5"; shift 5
  gsd_do "$a" "$ws" "$TMP/gsd.a" "$@"
  if [ "$GRC" -ne 0 ] || [ ! -s "$TMP/gsd.a" ] || ! command grep -qF -- "$want" "$TMP/gsd.a"; then
    LASTMSG="référence inutilisable (rc $GRC, jeton [$want] attendu) err[$(tr '\n' '|' < "$TMP/gsd.a.err" | cut -c1-200)]"; return 2
  fi
  gsd_do "$b" "$ws" "$TMP/gsd.b" "$@"
  if [ "$GRC" -ne 0 ]; then LASTMSG="le moteur rend rc $GRC sur le second lab"; return 1; fi
  gsd_norm "$drop" "$a" "$TMP/gsd.a" > "$TMP/gsd.na"; gsd_norm "$drop" "$b" "$TMP/gsd.b" > "$TMP/gsd.nb"
  if cmp -s "$TMP/gsd.na" "$TMP/gsd.nb"; then return 0; fi
  LASTMSG="sorties différentes"; return 1
}
gsd_must_differ() { # attendu « différent » : un 0 est un comparateur aveugle, un 2 une référence inutilisable
  gsd_same "$@"; local r=$?
  if [ "$r" -eq 0 ]; then LASTMSG="comparateur aveugle : un témoin négatif est déclaré identique (${*:3:3})"; return 1; fi
  if [ "$r" -eq 2 ]; then return 1; fi
  return 0
}
gsd_must_match() { gsd_same "$@"; local r=$?; if [ "$r" -eq 0 ]; then return 0; fi; LASTMSG="${LASTMSG} (${*:3:3})"; return 1; }
# gsd_write <lab> <compartiment ou -> <verbe> : l'ÉCRIVAIN sur le ROADMAP du lab (poste dev), code 0 exigé.
gsd_write() {
  local ws=()
  if [ "$2" != - ]; then ws=(--ws "$2"); fi
  RUNDIR="$GSD/$1"; T_ROLE=dev run "$3" --phase 2 ${ws[@]+"${ws[@]}"}; T_ROLE=""
  msg "l'écrivain ($3) sur $1 attendu rc 0"; [ "$RC" -eq 0 ]
}

if [ -f "$GSDJS" ] && command -v node > /dev/null 2>&1; then
  PH2='"phase_name": "Deuxieme"'; CNT='"phase_count": 3'
  gsd_mklab A1 - '' ''
  gsd_mklab A2 - '' 'suite du but'
  gsd_mklab N2 - '**Validation:** proposed' 'suite du but'   # insertion FAUTIVE, entre les deux lignes du Goal
  # Témoin négatif d'abord, avant toute comparaison positive : le comparateur doit savoir rougir (champ goal).
  probe_gsd_neg() {
    gsd_must_match 1 - "$PH2" "$GSD/A2" "$GSD/A2" roadmap get-phase 2 || { LASTMSG="témoin positif A2 = A2 non identique (comparateur toujours différent) — $LASTMSG"; return 1; }
    gsd_must_differ 1 - "$PH2" "$GSD/A2" "$GSD/N2" roadmap get-phase 2
  }
  case_ VFV-GSD-NEG probe_gsd_neg

  probe_gsd_propose() {
    local v
    for v in 1 2; do
      cp -R "$GSD/A$v" "$GSD/P$v"
      gsd_write "P$v" - propose || return 1
      gsd_must_match 1 - "$PH2" "$GSD/A$v" "$GSD/P$v" roadmap get-phase 2 || return 1
      gsd_must_match 0 - "$CNT" "$GSD/A$v" "$GSD/P$v" roadmap analyze || return 1
    done
    # Le champ retiré de la comparaison porte bien le marqueur : le retrait n'efface pas une différence réelle.
    gsd_do "$GSD/P2" - "$TMP/gsd.sec" roadmap get-phase 2
    LASTMSG="la section de P2 ne porte pas la ligne de marqueur après la seconde ligne du Goal"
    command grep -qF 'suite du but\n**Validation:** proposed' "$TMP/gsd.sec"
  }
  case_ VFV-GSD-PROPOSE probe_gsd_propose

  probe_gsd_validate() {
    local v
    for v in 1 2; do
      cp -R "$GSD/P$v" "$GSD/V$v"
      gsd_write "V$v" - validate || return 1
      gsd_must_match 1 - "$PH2" "$GSD/A$v" "$GSD/V$v" roadmap get-phase 2 || return 1
      gsd_must_match 0 - "$CNT" "$GSD/A$v" "$GSD/V$v" roadmap analyze || return 1
    done
  }
  case_ VFV-GSD-VALIDATE probe_gsd_validate

  # Lab partitionné : mêmes comparaisons avec --ws w1 (compartiment de fixture, aucun nom réel).
  gsd_mklab Aw w1 '' 'suite du but'
  gsd_mklab Nw w1 '**Validation:** proposed' 'suite du but'
  probe_gsd_ws() {
    gsd_must_differ 1 w1 "$PH2" "$GSD/Aw" "$GSD/Nw" roadmap get-phase 2 || return 1
    cp -R "$GSD/Aw" "$GSD/Pw"
    gsd_write Pw w1 propose || return 1
    gsd_must_match 1 w1 "$PH2" "$GSD/Aw" "$GSD/Pw" roadmap get-phase 2 || return 1
    gsd_must_match 0 w1 "$CNT" "$GSD/Aw" "$GSD/Pw" roadmap analyze || return 1
    cp -R "$GSD/Pw" "$GSD/Vw"
    gsd_write Vw w1 validate || return 1
    gsd_must_match 1 w1 "$PH2" "$GSD/Aw" "$GSD/Vw" roadmap get-phase 2 || return 1
    gsd_must_match 0 w1 "$CNT" "$GSD/Aw" "$GSD/Vw" roadmap analyze
  }
  case_ VFV-GSD-WS probe_gsd_ws
else
  skip "VFV-GSD moteur GSD absent (node ou gsd-tools.cjs introuvable : la CI installe le moteur et tranche)"
fi

# === Mutants (QUAL-01) ===============================================================================
MUTDIR="$TMP/mut"; mkdir -p "$MUTDIR"
MUTBIN="$MUTDIR/vf-validation.sh"
# Lecteur de poste et règles de compartiment à côté de la copie (à plat), comme chez l'utilisateur.
cp "$SDIR/vf-role.sh" "$MUTDIR/vf-role.sh"
for _p in "$HERE/../workstream-policy.sh" "$HERE/../../../planning-core/scripts/workstream-policy.sh"; do
  if [ -f "$_p" ]; then cp "$_p" "$MUTDIR/workstream-policy.sh"; break; fi
done

# mutant <id> <ligne repère> <ancien> <nouveau> <sonde> <description> : dans UNE ligne du script (celle qui
# contient le repère), remplace la première occurrence littérale de <ancien> par <nouveau> (chaînes passées par
# l'environnement : aucune séquence d'échappement interprétée). La sonde doit échouer sur le mutant, réussir
# sur l'original ; code attendu/obtenu imprimé par msg.
mutant() {
  local id="$1" needle="$2" old="$3" new="$4" probe="$5" desc="$6"
  if ! declare -F "$probe" > /dev/null; then ko "$id sonde $probe NON DÉFINIE à cet endroit — $desc"; return; fi
  NEEDLE="$needle" OLD="$old" NEW="$new" awk 'BEGIN { n = ENVIRON["NEEDLE"]; o = ENVIRON["OLD"]; w = ENVIRON["NEW"] }
    { if (index($0, n)) { i = index($0, o); if (i) $0 = substr($0, 1, i - 1) w substr($0, i + length(o)) } print }' \
    "$SCRIPT" > "$MUTBIN"
  if cmp -s "$MUTBIN" "$SCRIPT"; then ko "$id mutant NON OPPOSABLE (copie identique à l'original) — $desc"; return; fi
  if ! bash -n "$MUTBIN" 2>/dev/null; then ko "$id mutant invalide (bash -n) — $desc"; return; fi
  local nl; nl="$(diff "$SCRIPT" "$MUTBIN" | command grep -c '^<')"
  if [ "$nl" != 1 ]; then ko "$id mutant mal ciblé ($nl lignes changées au lieu de 1) — $desc"; return; fi
  TARGET="$MUTBIN"; "$probe" < /dev/null; local mrc=$?; local mmsg="$LASTMSG"
  TARGET="$SCRIPT"; "$probe" < /dev/null; local orc=$?
  if [ "$mrc" -ne 0 ] && [ "$orc" -eq 0 ]; then
    ok "$id tue ($desc) — sur le mutant : $mmsg"
  elif [ "$mrc" -eq 0 ]; then
    ko "$id mutant SURVIVANT ($desc) — la sonde ${probe#probe_} reste verte sur le mutant"
  else
    ko "$id original rouge après mutation ($desc) — $LASTMSG"
  fi
  TARGET="$SCRIPT"
}

mutant VFV-MUT-1 'if [ "$OVERRIDE" -ne 1 ]; then' '[ "$OVERRIDE" -ne 1 ]' 'false' probe_poste_product \
  "refus du poste product retiré"
mutant VFV-MUT-2 'if [ "$rrc" -ne 0 ]; then illis' 'illis "poste illisible (vf-role.sh code $rrc) : aucune ecriture, jamais un repli sur solo"' 'ROLE=solo' probe_poste_illisible \
  "échec du lecteur de poste replié sur solo"
mutant VFV-MUT-3 'propose:1:validated)' 'indet "deja validee : jamais repassee a proposed"' 'finish 0' probe_propose_validee \
  "propose sur une phase validée n'est plus refusé"
mutant VFV-MUT-4 'if (ingoal[p]) { if (t == ""' 'else goalend[p] = nr;' 'else goalend[p] = goalend[p];' probe_goal_multi \
  "insertion juste après la première ligne du Goal"
mutant VFV-MUT-5 'if [ -L "$F" ]; then illis' '[ -L "$F" ]' 'false' probe_lien \
  "refus du lien symbolique retiré"
mutant VFV-MUT-6 'if [ "$nsec" -eq 0 ]; then indet' 'indet "phase introuvable"' 'finish 0' probe_trace3 \
  "phase introuvable rendue 0"
mutant VFV-MUT-7 'VAL="validated (product,' ', override)' ')' probe_poste_product \
  "override absent de la valeur écrite"
mutant VFV-MUT-8 'then indet "lab partitionne sans --ws"' '[ -e "$PLAN/workstreams" ] || [ -L "$PLAN/workstreams" ]' 'false' probe_ws \
  "lab partitionné sans --ws traité comme lab plat"
mutant VFV-MUT-9 'out[++m] = lead[p] "**Validation:** " val cr[i]' 'lead[p] "**Validation:** "' '"**Validation:** "' probe_indent \
  "indentation de la ligne de marqueur remplacée perdue à la réécriture"

mutant VFV-MUT-10 'hors de la racine du depot' 'illis "architecture' ': "architecture' probe_arch_borne \
  "refus d'un --architecture hors de la racine retiré"
mutant VFV-MUT-11 'DIRP=$(cd' '&& pwd -P' '&& pwd' probe_arch_borne \
  "liens symboliques des dossiers parents non résolus avant la comparaison à la racine"
mutant VFV-MUT-12 'if [ -L "$PLAN" ]; then illis' '[ -L "$PLAN" ]' 'false' probe_planning_lien \
  "refus d'un .planning en lien symbolique retiré"
mutant VFV-MUT-13 'if (c == "`" && index(substr(s, i + n + 1), "`")) return 0' 'c == "`" &&' '0 &&' probe_fence_w \
  "un accent grave dans l'info string n'empêche plus l'ouverture d'une barrière"
mutant VFV-MUT-14 'if (n < flen) return 0' 'n < flen' '0' probe_fence_w \
  "une barrière de fermeture plus courte que l'ouvreur la ferme"
mutant VFV-MUT-15 'return (substr(s, i + n + 1) ~' '~ /^[ \t]*$/' '~ /^/' probe_fence_w \
  "une ligne de fermeture avec info string ferme la barrière"
mutant VFV-MUT-16 'a = index(tw, "<details>")' '"<details>"' '"<detailz>"' probe_details_w \
  "les blocs <details> des jalons livrés ne sont plus cachés"
mutant VFV-MUT-17 'p = (nsec[1] > 0) ? 1 : 2' '(nsec[1] > 0) ? 1 : 2' '2' probe_ids_w \
  "la lecture tolérante au préfixe projet prime sur la lecture exacte"
mutant VFV-MUT-18 'p = (nsec[1] > 0) ? 1 : 2' '(nsec[1] > 0) ? 1 : 2' '1' probe_ids_w \
  "plus de lecture tolérante au préfixe projet"
mutant VFV-MUT-19 'if (!match(h, /^[Pp][Hh][Aa][Ss][Ee][ \t]+[A-Za-z0-9]' '[A-Za-z0-9][A-Za-z0-9_-]*' '[0-9]' probe_ids_w \
  "un titre à id custom n'est plus une section"
mutant VFV-MUT-20 'if (!match(h, /^[Pp][Hh][Aa][Ss][Ee][ \t]+[A-Za-z0-9]' '(\.[A-Za-z0-9_-]+)*' '(\.[0-9]+)*' probe_ids_w \
  "un segment décimal à suffixe lettre n'est plus une section"
mutant VFV-MUT-21 'u = toupper(s)' 'toupper(s)' 's' probe_ids_w \
  "la casse des identifiants de phase devient significative"
mutant VFV-MUT-22 'pq_blk[1] = vis substr(w, 1, a - 1)' 'substr(w, 1, a - 1)' '""' probe_details_w \
  "le texte qui précède un <details> sur sa ligne est perdu"

mutant VFV-MUT-23 'if (!inq && active_block(rl, w, b)) {' 'active_block(rl, w, b)' '0' probe_details_actif_w \
  "le jalon actif en <details> est caché comme un jalon livré"
mutant VFV-MUT-24 'if (!inq && active_block(rl, w, b)) {' 'active_block(rl, w, b)' '1' probe_details_actif_w \
  "tout bloc <details> devient visible, le jalon livré aussi"

mutant VFV-MUT-25 '  if (isc || loosemark(line)) {' 'loosemark(line)' '0' probe_ressemblant \
  "une ligne qui ressemble à un marqueur est lue « absent » par l'écrivain (une ligne canonique est insérée à côté)"
mutant VFV-MUT-26 'return (w == "propo" || w == "valid")' 'w == "propo" || w == "valid"' '1' probe_ressemblant \
  "toute ligne « Validation: … » est un marqueur illisible (sur-détection)"

mutant VFV-MUT-27 'ROOTP=$(pwd -P' 'pwd -P' 'git rev-parse --show-toplevel' probe_arch_cwd \
  "la racine de --architecture devient la racine du dépôt git au lieu du répertoire courant"

mutant VFV-MUT-28 '_pre=${PHASE%%-*}' '[0-9]*-*)' '[x]*-*)' probe_ids_slug_w \
  "un nom de dossier ou un identifiant de plan n'est plus refusé (64)"
mutant VFV-MUT-29 'if (n >= 2 && n <= 4 && phasehead(r)) return n' 'phasehead(r)' '0' probe_titres_gsd_w \
  "« ###Phase 2: » sans espace n'est plus un titre"
mutant VFV-MUT-30 'if (!match(h, /^[Pp][Hh]' '[Pp][Hh][Aa][Ss][Ee]' 'Phase' probe_titres_gsd_w \
  "« ### PHASE 2: » (casse) n'est plus une section"
mutant VFV-MUT-31 'substr(t, 1, 2) == "\302\240"' '"\302\240"' '"@@"' probe_sosies_typo_w \
  "l'espace insécable U+00A0 avant le deux-points n'est plus un sosie"
mutant VFV-MUT-32 'substr(t, 1, 3) == "\342\200\257"' '"\342\200\257"' '"@@@"' probe_sosies_typo_w \
  "l'espace fine insécable U+202F avant le deux-points n'est plus un sosie"
mutant VFV-MUT-33 'if (c == ":" || c == "|")' ' || c == "|"' '' probe_sosies_typo_w \
  "la ligne de tableau n'est plus un sosie"
mutant VFV-MUT-34 'substr(t, 1, 3) == "\342\200\224"' '"\342\200\224"' '"@@@"' probe_sosies_typo_w \
  "le tiret cadratin n'est plus un sosie"

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
