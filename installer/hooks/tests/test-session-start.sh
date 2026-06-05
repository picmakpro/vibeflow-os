#!/usr/bin/env bash
# Test isolé du hook SessionStart (installer/hooks/session-start).
# Usage: ./test-session-start.sh
# Exit code: 0 si tous les tests passent, 1 sinon.
#
# Isolation TOTALE : faux HOME + faux cwd projet sous mktemp, trap cleanup.
# Le vrai $HOME et le vrai ./.claude ne sont JAMAIS touchés.

set -uo pipefail

# Chemin absolu du script testé (résolu avant tout cd).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../session-start"

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

HOME_FAKE="$WORK/home"
PROJ_FAKE="$WORK/proj"
mkdir -p "$HOME_FAKE" "$PROJ_FAKE"

PASS=0; FAIL=0

assert() {
  local name="$1" actual="$2" expected="$3"
  if [[ "$actual" == *"$expected"* ]]; then
    echo "  ✅ PASS — $name"; PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL — $name"
    echo "     Expected (contains): $expected"
    echo "     Actual:              $actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_empty() {
  local name="$1" actual="$2"
  if [ -z "$actual" ]; then
    echo "  ✅ PASS — $name"; PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL — $name (stdout non vide)"
    echo "     Actual: $actual"
    FAIL=$((FAIL + 1))
  fi
}

# Exécute le hook dans l'isolation : cwd=$PROJ_FAKE, HOME=$HOME_FAKE.
run_hook() {
  ( cd "$PROJ_FAKE" && HOME="$HOME_FAKE" bash "$HOOK" )
}

echo "=== T1 — 1er lancement (aucun marqueur) : émet additionalContext ==="
out="$(run_hook)"; rc=$?
assert "T1.1 — exit code 0" "$rc" "0"
assert "T1.2 — contient additionalContext" "$out" "additionalContext"
assert "T1.3 — nomme /vibeflow-install" "$out" "vibeflow-install"
if printf '%s' "$out" | jq . >/dev/null 2>&1; then
  echo "  ✅ PASS — T1.4 — sortie JSON parsable"; PASS=$((PASS + 1))
else
  echo "  ❌ FAIL — T1.4 — sortie JSON NON parsable"; FAIL=$((FAIL + 1))
fi

echo ""
echo "=== T2 — marqueur user présent : silence (garde-fou user-scope) ==="
mkdir -p "$HOME_FAKE/.claude/scripts"
: > "$HOME_FAKE/.claude/scripts/.vibeflow-installed"
out="$(run_hook)"; rc=$?
assert "T2.1 — exit code 0" "$rc" "0"
assert_empty "T2.2 — stdout VIDE" "$out"

echo ""
echo "=== T3 — marqueur project présent : silence ==="
# Nettoyer le marqueur user pour isoler le cas project.
rm -f "$HOME_FAKE/.claude/scripts/.vibeflow-installed"
mkdir -p "$PROJ_FAKE/.claude/scripts"
: > "$PROJ_FAKE/.claude/scripts/.vibeflow-installed"
out="$(run_hook)"; rc=$?
assert "T3.1 — exit code 0" "$rc" "0"
assert_empty "T3.2 — stdout VIDE" "$out"

echo ""
echo "=== BILAN ==="
echo "PASS : $PASS / FAIL : $FAIL"
[ "$FAIL" -eq 0 ]
