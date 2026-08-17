#!/usr/bin/env bash
# test-guard-driver-lock.sh — Suite de tests pour guard-driver-lock.sh (LOCK-02/03/05, D-32-05).
#
# Tâche 1 (tracer) — tranche verticale commit/checkout, niveau définitif :
#   A1/A2/A4 — commit d'une session tierce sous lock vivant : deny, motif porteur, détenteur passe
#   A5 (BL-1) — chaînage par SAUT DE LIGNE : le 2e segment n'est pas invisible
#   A6 (BL-2) — options globales de `git` (-C, -c) : le sous-verbe est reconnu malgré elles
#   B1/B4     — checkout d'une session tierce : deny, détenteur passe
#   R1/R2/R3  — lock absent/périmé/pré-Phase-32 (sans session_ids) : allow inconditionnel
#   P0/P1     — préfiltre pur-bash : zéro spawn d'interprète sur payload non concerné
#
# Convention du dossier : set -uo pipefail sans -e, mktemp -d + trap EXIT, VF_* pour rediriger le
# système sous test, préflights séparés des assertions métier.

set -uo pipefail
cd "$(dirname "$0")/../.."
GUARD="$(pwd)/scripts/guard-driver-lock.sh"
DRIVER="$(pwd)/scripts/driver-lock.sh"
BASH_BIN="${BASH:-bash}"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
LOCK="$WORK_DIR/DRIVER.lock"
export VF_DRIVER_LOCK="$LOCK"

PASS=0; FAIL=0
assert()      { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_empty() { if [ -z "$2" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (sortie non vide)"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_exit()  { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }
num_eq()       { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (=$2, attendu $3)"; FAIL=$((FAIL+1)); fi; }
preflight()    { if [ "$2" -eq 0 ]; then echo "  ✅ PREFLIGHT OK — $1"; PASS=$((PASS+1)); return 0; else echo "  ❌ PREFLIGHT FAIL — $1 (fixture cassé, pas de verdict métier)"; FAIL=$((FAIL+1)); return 1; fi; }

# Payloads construits par un interprète (échappement JSON fiable), jamais par concaténation
# de chaînes à la main.
mk_bash() { # cmd session_id cwd
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]},
                   "session_id": sys.argv[2], "cwd": sys.argv[3]}))' "$1" "$2" "$3"
}

run_guard() { # payload
  printf '%s' "$1" | VF_DRIVER_LOCK="$LOCK" "$BASH_BIN" "$GUARD" 2>/dev/null
}

# Antidate un lock existant AU-DELÀ du TTL — même patron que age_stale() de test-driver-lock.sh,
# reproduit ici (pas de harness partagé entre suites du dossier, convention TESTING.md).
age_stale() {
  local lock="$1" old; old=$(( $(date +%s) - 999999 ))
  if [ -L "$lock" ]; then
    local gen; gen="$(readlink "$lock")"
    [ -f "$lock/meta" ] && sed -i.bak "s/^heartbeat_epoch=.*/heartbeat_epoch=$old/" "$lock/meta" 2>/dev/null
    rm -f "$lock/meta.bak" 2>/dev/null
    touch -t 202001010000 "$(dirname "$lock")/$gen" 2>/dev/null || true
  elif [ -f "$lock/meta" ]; then
    sed -i.bak "s/^heartbeat_epoch=.*/heartbeat_epoch=$old/" "$lock/meta" && rm -f "$lock/meta.bak"
  else
    touch -t 202001010000 "$lock" 2>/dev/null || true
  fi
}

# Retire la ligne "session_ids=" du meta — fixture de rétrocompatibilité (R3), même patron que
# meta_drop_key() de test-driver-lock.sh.
meta_drop_key() {
  local lock="$1" key="$2" meta
  if [ -L "$lock" ]; then meta="$(dirname "$lock")/$(readlink "$lock")/meta"; else meta="$lock/meta"; fi
  [ -f "$meta" ] && sed -i.bak "/^${key}=/d" "$meta" 2>/dev/null && rm -f "${meta}.bak"
}

meta_of() { # rend le chemin du meta du lock courant
  [ -L "$LOCK" ] && echo "$(dirname "$LOCK")/$(readlink "$LOCK")/meta" || echo "$LOCK/meta"
}

echo "=== Fixture principale : lock vivant, mission-X / sess-holder ==="
rm -rf "$LOCK"
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=t32 >/dev/null
ST="$("$DRIVER" status)"
case "$ST" in *'"present": true'*) preflight "fixture: lock présent" 0 ;; *) preflight "fixture: lock présent" 1 ;; esac
case "$ST" in *'"stale": false'*) preflight "fixture: lock non périmé" 0 ;; *) preflight "fixture: lock non périmé" 1 ;; esac
case "$ST" in *'sess-holder'*) preflight "fixture: session_ids peuplé (sess-holder)" 0 ;; *) preflight "fixture: session_ids peuplé (sess-holder)" 1 ;; esac
[ -x "$GUARD" ] || chmod +x "$GUARD" 2>/dev/null
case "-$(bash -n "$GUARD" 2>&1)" in -) preflight "fixture: guard syntaxiquement valide" 0 ;; *) preflight "fixture: guard syntaxiquement valide" 1 ;; esac

echo ""
echo "=== A1/A2/A4 — commit d'une session tierce sous lock vivant ==="
PAY_A1=$(mk_bash 'git add F && git commit -m "hors mandat"' sess-intrus .)
OUT_A1="$(run_guard "$PAY_A1")"
assert "A1 — deny (permissionDecision)" "$OUT_A1" '"permissionDecision": "deny"'
assert "A2a — motif porte owner mission-X" "$OUT_A1" "mission-X"
assert "A2b — motif porte la commande exacte de reclaim" "$OUT_A1" "reclaim --owner=mission-X"
PAY_A4=$(mk_bash 'git add F && git commit -m "hors mandat"' sess-holder .)
OUT_A4="$(run_guard "$PAY_A4")"
assert_empty "A4 — DISCRIMINANCE : le détenteur (sess-holder) passe, sortie vide (ne JAMAIS retirer)" "$OUT_A4"

echo ""
echo "=== A5 (BL-1) — chaînage par SAUT DE LIGNE : le commit n'est pas le 1er segment ==="
PAY_A5=$(mk_bash "$(printf 'git add F\ngit commit -m "hors mandat"')" sess-intrus .)
OUT_A5="$(run_guard "$PAY_A5")"
assert "A5 — deny malgré le saut de ligne avant le commit" "$OUT_A5" '"permissionDecision": "deny"'

echo ""
echo "=== A6 (BL-2) — options globales de git avant le sous-verbe ==="
PAY_A6a=$(mk_bash 'git -C /tmp commit -m x' sess-intrus .)
OUT_A6a="$(run_guard "$PAY_A6a")"
assert "A6a — deny malgré 'git -C /tmp'" "$OUT_A6a" '"permissionDecision": "deny"'
PAY_A6b=$(mk_bash 'git -c core.hooksPath=/dev/null commit -m x' sess-intrus .)
OUT_A6b="$(run_guard "$PAY_A6b")"
assert "A6b — deny malgré 'git -c core.hooksPath=/dev/null'" "$OUT_A6b" '"permissionDecision": "deny"'

echo ""
echo "=== B1/B4 — checkout d'une session tierce ==="
PAY_B1=$(mk_bash 'git checkout -b autre-branche' sess-intrus .)
OUT_B1="$(run_guard "$PAY_B1")"
assert "B1 — deny" "$OUT_B1" '"permissionDecision": "deny"'
PAY_B4=$(mk_bash 'git checkout -b autre-branche' sess-holder .)
OUT_B4="$(run_guard "$PAY_B4")"
assert_empty "B4 — DISCRIMINANCE : le détenteur passe (ne JAMAIS retirer)" "$OUT_B4"

echo ""
echo "=== R1 — lock ABSENT : allow inconditionnel ==="
rm -rf "$LOCK"
OUT_R1="$(run_guard "$(mk_bash 'git commit -m x' sess-intrus .)")"
assert_empty "R1 — sortie vide, aucun lock" "$OUT_R1"

echo ""
echo "=== R2 — lock PÉRIMÉ : traité comme absent ==="
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=t32 >/dev/null
age_stale "$LOCK"
OUT_R2="$(run_guard "$(mk_bash 'git commit -m x' sess-intrus .)")"
assert_empty "R2 — sortie vide, lock périmé (zombie ne bloque jamais)" "$OUT_R2"

echo ""
echo "=== R3 — lock frais SANS session_ids (rétrocompat pré-Phase-32) ==="
rm -rf "$LOCK"
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=t32 >/dev/null
meta_drop_key "$LOCK" session_ids
_r3_n=$(grep -c '^session_ids=' "$(meta_of)")
num_eq "R3.0 — (SE-7) fixture: la ligne session_ids= est réellement absente" "$_r3_n" 0
OUT_R3="$(run_guard "$(mk_bash 'git commit -m x' sess-intrus .)")"
assert_empty "R3 — sortie vide, meta sans identité (règle 2)" "$OUT_R3"

echo ""
echo "=== P0 — SE-1 : sonde d'existence AVANT tout spawn (lock absent, PATH sans interprète) ==="
rm -rf "$LOCK"
P0_BIN="$WORK_DIR/p0-bin"
mkdir -p "$P0_BIN"
for t in cat dirname basename sed grep mkdir rm date readlink stat; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$P0_BIN/$t" 2>/dev/null
done
_p0_py=0
command -v python3 >/dev/null 2>&1 && _p0_py=1
if PATH="$P0_BIN" command -v python3 >/dev/null 2>&1 || PATH="$P0_BIN" command -v python >/dev/null 2>&1; then
  preflight "P0 fixture: PATH réellement privé d'interprète" 1
else
  preflight "P0 fixture: PATH réellement privé d'interprète" 0
  PAY_P0=$(mk_bash 'git commit -m x' sess-intrus .)
  OUT_P0="$(printf '%s' "$PAY_P0" | VF_DRIVER_LOCK="$LOCK" PATH="$P0_BIN" "$BASH_BIN" "$GUARD" 2>/dev/null)"; RC_P0=$?
  assert_exit "P0 — exit 0 sans lock, même sans interprète disponible" "$RC_P0" 0
  assert_empty "P0 — sortie vide sans lock, même sans interprète disponible" "$OUT_P0"
fi

echo ""
echo "=== P1 — préfiltre : commande sans verbe concerné (lock présent, PATH sans interprète) ==="
CLAUDE_CODE_SESSION_ID=sess-holder "$DRIVER" acquire --owner=mission-X --step=t32 >/dev/null
PAY_P1=$(mk_bash 'ls -la' sess-intrus .)
OUT_P1="$(printf '%s' "$PAY_P1" | VF_DRIVER_LOCK="$LOCK" PATH="$P0_BIN" "$BASH_BIN" "$GUARD" 2>/dev/null)"; RC_P1=$?
assert_exit "P1 — exit 0, commande sans verbe concerné" "$RC_P1" 0
assert_empty "P1 — sortie vide, commande sans verbe concerné" "$OUT_P1"

"$DRIVER" release --owner=mission-X >/dev/null 2>&1

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
