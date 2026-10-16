#!/usr/bin/env bash
# prove-auditor-gate.sh — Preuve rouge/verte de la frontiere 300/301 (D-05) et de la zone
# d'avertissement 251-300 de l'auditeur de densite DISTRIBUE (module reference, plan 40.1-05).
#
# Ce module (plugin/reference/.../agent-density-auditor/) n'a AUCUNE suite de tests versionnee
# (`find` en recherche a rendu 0 resultat) : cet outil est la preuve rouge/verte de la phase,
# joue AVANT toute edition (attendu rc=1, ancien plafond 250 sans zone d'avertissement) et APRES
# (attendu rc=0). Convention ok()/ko() a trois champs, calquee sur
# plugin/conductor/scripts/tests/test-check-instruction-budget.sh.
#
# Comportement attendu (D-05, D-06) :
#   body 250 -> validate_gate exit 0, aucune "zone d'avertissement ADR-029" ; measure OK
#   body 251 -> validate_gate exit 0 + warning de zone           ; measure WARN
#   body 300 -> validate_gate exit 0 + warning de zone           ; measure WARN
#   body 301 -> validate_gate exit 1 + VIOLATION                 ; measure HEAVY
#   body 400 -> measure HEAVY ; body 401 -> measure CRITICAL
#
# Mutants opposables sur COPIE de validate_gate.sh (jamais l'original) :
#   MUT-G1 : `if (( body_lines > MAX_BODY_LINES )); then` -> `>=` (blocage decale de un)
#   MUT-G2 : la branche d'avertissement de zone neutralisee (`elif (( 0 )); then`)
#   MUT-G3 : `MAX_BODY_LINES=300` -> `MAX_BODY_LINES=250` (retour a l'ancien plafond)
# Chaque mutant est rejete (echec du test) s'il n'a rien change (cmp -s identique a l'original)
# ou si `bash -n` echoue dessus — un mutant non opposable n'est pas une preuve.
#
# Garde anti-vide : validate_gate.sh ecrit tout son verdict sur STDERR. Chaque invocation est
# capturee `> fichier 2>&1` ; avant toute assertion d'ABSENCE, on exige dans la meme capture une
# ligne `GATE PASSED` ou `GATE FAILED` — sans elle, ko trace "capture vide" (constat W5).
#
# rc 0 si tout tient, 1 sinon.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../.." && pwd)"
AUD="$ROOT/plugin/reference/content/methodology/templates/skills/agent-density-auditor/scripts"
VALIDATE="$AUD/validate_gate.sh"
MEASURE="$AUD/measure.sh"

PASS=0; FAIL=0
ok() { echo "  ok $1"; PASS=$((PASS+1)); }
# ko <assertion> <attendu> <obtenu> — trace a trois champs distincts, jamais un ko muet.
ko() {
  echo "  ko $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL+1))
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

WARN_RE="zone d'avertissement adr-029"
VIOLATION_LIT="VIOLATION: Prompt systeme trop long"

# make_agent <file> <n> — fixture 6L frontmatter + n lignes body, heading toutes les 50 lignes
# (pour ne pas confondre avec le warning "section unique trop longue" de validate_gate.sh).
make_agent() {
  local file="$1" n="$2" i sect
  {
    printf -- '---\n'
    printf 'name: demo\n'
    printf 'description: agent de demonstration\n'
    printf 'skills:\n'
    printf '  - demo\n'
    printf -- '---\n'
    i=1
    while [ "$i" -le "$n" ]; do
      if [ $(( (i - 1) % 50 )) -eq 0 ]; then
        sect=$(( (i - 1) / 50 + 1 ))
        printf '## Section %d\n' "$sect"
      else
        printf 'ligne de corps neutre %d\n' "$i"
      fi
      i=$(( i + 1 ))
    done
  } > "$file"
}

# guard_non_vide <capture> <label> -> 0 si GATE PASSED|FAILED present (rc 0), sinon ko + rc 1
guard_non_vide() {
  local cap="$1" label="$2"
  if grep -qE 'GATE PASSED|GATE FAILED' "$cap"; then
    return 0
  fi
  ko "$label - garde anti-vide" "ligne GATE PASSED ou GATE FAILED presente dans la capture" "capture vide ou sans verdict : $(cat "$cap" 2>/dev/null)"
  return 1
}

measure_status() {
  local file="$1"
  bash "$MEASURE" "$file" 2>/dev/null | grep -F "$file" | awk '{print $NF}'
}

assert_measure() {
  local file="$1" expected="$2" label="$3"
  local got
  got="$(measure_status "$file")"
  if [ "$got" = "$expected" ]; then
    ok "$label mesure=$expected"
  else
    ko "$label mesure" "$expected" "$got"
  fi
}

echo "== prove-auditor-gate =="
echo "  validate_gate.sh : $VALIDATE"
echo "  measure.sh       : $MEASURE"
echo ""
echo "== frontiere validate_gate.sh / classification measure.sh =="

# --- body=250 : exit 0, pas de warning de zone ; measure OK ---------------------------------
F250="$TMP/agent-250.md"; make_agent "$F250" 250
O250="$TMP/out-250"
RC250=0; bash "$VALIDATE" "$F250" > "$O250" 2>&1 || RC250=$?
if guard_non_vide "$O250" "body=250"; then
  [ "$RC250" -eq 0 ] && ok "body=250 exit=0" || ko "body=250 exit" "0" "$RC250"
  if grep -qi "$WARN_RE" "$O250"; then
    ko "body=250 absence de warning de zone" "absent" "present"
  else
    ok "body=250 pas de warning de zone"
  fi
fi
assert_measure "$F250" "OK" "body=250"

# --- body=251 : exit 0, warning de zone present ; measure WARN --------------------------------
F251="$TMP/agent-251.md"; make_agent "$F251" 251
O251="$TMP/out-251"
RC251=0; bash "$VALIDATE" "$F251" > "$O251" 2>&1 || RC251=$?
if guard_non_vide "$O251" "body=251"; then
  [ "$RC251" -eq 0 ] && ok "body=251 exit=0" || ko "body=251 exit" "0" "$RC251"
  if grep -qi "$WARN_RE" "$O251"; then
    ok "body=251 warning de zone present"
  else
    ko "body=251 warning de zone" "present" "absent"
  fi
fi
assert_measure "$F251" "WARN" "body=251"

# --- body=300 : exit 0, warning de zone present ; measure WARN --------------------------------
F300="$TMP/agent-300.md"; make_agent "$F300" 300
O300="$TMP/out-300"
RC300=0; bash "$VALIDATE" "$F300" > "$O300" 2>&1 || RC300=$?
if guard_non_vide "$O300" "body=300"; then
  [ "$RC300" -eq 0 ] && ok "body=300 exit=0" || ko "body=300 exit" "0" "$RC300"
  if grep -qi "$WARN_RE" "$O300"; then
    ok "body=300 warning de zone present"
  else
    ko "body=300 warning de zone" "present" "absent"
  fi
fi
assert_measure "$F300" "WARN" "body=300"

# --- body=301 : exit 1, VIOLATION ; measure HEAVY ----------------------------------------------
F301="$TMP/agent-301.md"; make_agent "$F301" 301
O301="$TMP/out-301"
RC301=0; bash "$VALIDATE" "$F301" > "$O301" 2>&1 || RC301=$?
if guard_non_vide "$O301" "body=301"; then
  [ "$RC301" -eq 1 ] && ok "body=301 exit=1" || ko "body=301 exit" "1" "$RC301"
  if grep -qF "$VIOLATION_LIT" "$O301"; then
    ok "body=301 VIOLATION presente"
  else
    ko "body=301 VIOLATION" "present" "absent"
  fi
fi
assert_measure "$F301" "HEAVY" "body=301"

# --- body=400 : measure HEAVY -------------------------------------------------------------------
F400="$TMP/agent-400.md"; make_agent "$F400" 400
assert_measure "$F400" "HEAVY" "body=400"

# --- body=401 : measure CRITICAL ------------------------------------------------------------------
F401="$TMP/agent-401.md"; make_agent "$F401" 401
assert_measure "$F401" "CRITICAL" "body=401"

echo ""
echo "== mutants opposables (COPIE de validate_gate.sh, jamais l'original) =="

MUTD="$TMP/mutants"; mkdir -p "$MUTD"

# --- MUT-G1 : blocage decale de un (`>` -> `>=`) -------------------------------------------------
MUT_G1_OLD='  if (( body_lines > MAX_BODY_LINES )); then'
MUT_G1_NEW='  if (( body_lines >= MAX_BODY_LINES )); then'
awk -v old="$MUT_G1_OLD" -v new="$MUT_G1_NEW" '{ if ($0 == old) { print new } else { print } }' "$VALIDATE" > "$MUTD/mut-g1.sh"
if cmp -s "$MUTD/mut-g1.sh" "$VALIDATE"; then
  ko "MUT-G1 blocage decale de un" "mutation differente de l'original (cmp)" "mutant identique a l'original - NON OPPOSABLE"
elif ! bash -n "$MUTD/mut-g1.sh" 2>/dev/null; then
  ko "MUT-G1 blocage decale de un" "bash -n OK sur le mutant" "syntaxe invalide - pas une preuve"
else
  RC_MUT_G1=0; bash "$MUTD/mut-g1.sh" "$F300" > "$TMP/out-mut-g1" 2>&1 || RC_MUT_G1=$?
  RC_ORIG_G1=0; bash "$VALIDATE" "$F300" > "$TMP/out-orig-g1" 2>&1 || RC_ORIG_G1=$?
  if [ "$RC_MUT_G1" -eq 1 ] && [ "$RC_ORIG_G1" -eq 0 ]; then
    ok "MUT-G1 blocage decale de un tue (cmp confirme la mutation, bash -n OK) : fixture 300 rc_mutant=$RC_MUT_G1 rc_original=$RC_ORIG_G1"
  else
    ko "MUT-G1 blocage decale de un" "rc_mutant=1 rc_original=0" "rc_mutant=$RC_MUT_G1 rc_original=$RC_ORIG_G1"
  fi
fi

# --- MUT-G2 : avertissement de zone neutralise ----------------------------------------------------
MUT_G2_OLD='  elif (( body_lines >= WARN_BODY_FROM )); then'
MUT_G2_NEW='  elif (( 0 )); then'
awk -v old="$MUT_G2_OLD" -v new="$MUT_G2_NEW" '{ if ($0 == old) { print new } else { print } }' "$VALIDATE" > "$MUTD/mut-g2.sh"
F260="$TMP/agent-260.md"; make_agent "$F260" 260
if cmp -s "$MUTD/mut-g2.sh" "$VALIDATE"; then
  ko "MUT-G2 avertissement neutralise" "mutation differente de l'original (cmp)" "mutant identique a l'original - NON OPPOSABLE"
elif ! bash -n "$MUTD/mut-g2.sh" 2>/dev/null; then
  ko "MUT-G2 avertissement neutralise" "bash -n OK sur le mutant" "syntaxe invalide - pas une preuve"
else
  bash "$MUTD/mut-g2.sh" "$F260" > "$TMP/out-mut-g2" 2>&1 || true
  bash "$VALIDATE" "$F260" > "$TMP/out-orig-g2" 2>&1 || true
  WARN_MUT=0; grep -qi "$WARN_RE" "$TMP/out-mut-g2" && WARN_MUT=1
  WARN_ORIG=0; grep -qi "$WARN_RE" "$TMP/out-orig-g2" && WARN_ORIG=1
  if [ "$WARN_MUT" -eq 0 ] && [ "$WARN_ORIG" -eq 1 ]; then
    ok "MUT-G2 avertissement neutralise tue (cmp confirme la mutation, bash -n OK) : fixture 260 warning_mutant=$WARN_MUT warning_original=$WARN_ORIG"
  else
    ko "MUT-G2 avertissement neutralise" "warning_mutant=0 warning_original=1" "warning_mutant=$WARN_MUT warning_original=$WARN_ORIG"
  fi
fi

# --- MUT-G3 : retour a l'ancien plafond (300 -> 250) -----------------------------------------------
MUT_G3_OLD='MAX_BODY_LINES=300'
MUT_G3_NEW='MAX_BODY_LINES=250'
awk -v old="$MUT_G3_OLD" -v new="$MUT_G3_NEW" '{ if ($0 == old) { print new } else { print } }' "$VALIDATE" > "$MUTD/mut-g3.sh"
if cmp -s "$MUTD/mut-g3.sh" "$VALIDATE"; then
  ko "MUT-G3 retour a l'ancien plafond" "mutation differente de l'original (cmp)" "mutant identique a l'original - NON OPPOSABLE"
elif ! bash -n "$MUTD/mut-g3.sh" 2>/dev/null; then
  ko "MUT-G3 retour a l'ancien plafond" "bash -n OK sur le mutant" "syntaxe invalide - pas une preuve"
else
  RC_MUT_G3=0; bash "$MUTD/mut-g3.sh" "$F260" > "$TMP/out-mut-g3" 2>&1 || RC_MUT_G3=$?
  RC_ORIG_G3=0; bash "$VALIDATE" "$F260" > "$TMP/out-orig-g3" 2>&1 || RC_ORIG_G3=$?
  if [ "$RC_MUT_G3" -eq 1 ] && [ "$RC_ORIG_G3" -eq 0 ]; then
    ok "MUT-G3 retour a l'ancien plafond tue (cmp confirme la mutation, bash -n OK) : fixture 260 rc_mutant=$RC_MUT_G3 rc_original=$RC_ORIG_G3"
  else
    ko "MUT-G3 retour a l'ancien plafond" "rc_mutant=1 rc_original=0" "rc_mutant=$RC_MUT_G3 rc_original=$RC_ORIG_G3"
  fi
fi

echo ""
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
