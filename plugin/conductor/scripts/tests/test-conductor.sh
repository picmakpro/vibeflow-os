#!/usr/bin/env bash
# test-conductor.sh — Tests du suivi de version framework (framework-version.sh).
# Portable, sans réseau. Fabrique un faux plugin-root + un faux lab.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FV="$SCRIPT_DIR/framework-version.sh"
PASS=0; FAIL=0

eq() { # <desc> <expected> <actual>
  if [ "$2" = "$3" ]; then echo "  ✓ $1"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu '$2', obtenu '$3'"; FAIL=$((FAIL+1)); fi
}
code() { # <desc> <expected_code> <actual_code>
  if [ "$2" -eq "$3" ]; then echo "  ✓ $1 (exit $3)"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu exit $2, obtenu $3"; FAIL=$((FAIL+1)); fi
}

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PLUG="$TMP/plugin"; LAB="$TMP/lab"
mkdir -p "$PLUG/.claude-plugin" "$LAB"
printf '{ "name": "vibeflow", "version": "2.6.0" }\n' > "$PLUG/.claude-plugin/plugin.json"

echo "== test-conductor =="

# current depuis plugin.json
eq "current = 2.6.0" "2.6.0" "$(bash "$FV" current --plugin-root "$PLUG")"

# recorded inconnu au départ
eq "recorded = unknown" "unknown" "$(bash "$FV" recorded --lab-root "$LAB")"

# drift sans stamp → advisory exit 0
( bash "$FV" drift --plugin-root "$PLUG" --lab-root "$LAB" --quiet ); code "drift non-stampé = 0" 0 $?

# stamp puis recorded = 2.6.0
bash "$FV" stamp --plugin-root "$PLUG" --lab-root "$LAB" --quiet
eq "recorded après stamp" "2.6.0" "$(bash "$FV" recorded --lab-root "$LAB")"

# drift à jour → exit 0
( bash "$FV" drift --plugin-root "$PLUG" --lab-root "$LAB" --quiet ); code "drift à jour = 0" 0 $?

# le plugin avance → drift = retard → exit 1
printf '{ "name": "vibeflow", "version": "3.0.0" }\n' > "$PLUG/.claude-plugin/plugin.json"
( bash "$FV" drift --plugin-root "$PLUG" --lab-root "$LAB" --quiet ); code "drift retard (2.6.0<3.0.0) = 1" 1 $?

# lab en avance sur plugin → exit 0
printf '%s\n' "3.1.0" > "$LAB/.claude/.vibeflow-framework-version"
( bash "$FV" drift --plugin-root "$PLUG" --lab-root "$LAB" --quiet ); code "lab en avance = 0" 0 $?

# fallback VERSION si pas de plugin.json
rm "$PLUG/.claude-plugin/plugin.json"; printf 'v2.9.0\n' > "$PLUG/VERSION"
eq "current via fallback VERSION" "2.9.0" "$(bash "$FV" current --plugin-root "$PLUG")"

# --- UAT F3 : stamp en LAB, sans plugin-root, via le registre engine .vibeflow-installed ---
LAB2="$TMP/lab2"; mkdir -p "$LAB2/.claude/scripts"
printf 'planning-core=v2.5.0\nconductor=v1.14.0\n' > "$LAB2/.claude/scripts/.vibeflow-installed"
( CLAUDE_PLUGIN_ROOT= VIBEFLOW_CACHE= bash "$FV" stamp --lab-root "$LAB2" --quiet ); code "stamp lab sans plugin-root = 0 (F3, fallback registre)" 0 $?
eq "recorded après stamp lab (F3) = version du socle conductor" "1.14.0" "$(bash "$FV" recorded --lab-root "$LAB2")"
( CLAUDE_PLUGIN_ROOT= VIBEFLOW_CACHE= bash "$FV" drift --lab-root "$LAB2" --quiet ); code "drift lab (même cascade des deux côtés) = 0" 0 $?
# lab jamais installé (aucun registre) ET aucun plugin-root → stamp échoue toujours proprement
LAB3="$TMP/lab3"; mkdir -p "$LAB3"
( CLAUDE_PLUGIN_ROOT= VIBEFLOW_CACHE= bash "$FV" stamp --lab-root "$LAB3" --quiet 2>/dev/null ); code "stamp sans registre ni plugin-root = 1" 1 $?

echo "== résultat : $PASS passés, $FAIL échoués =="
[ "$FAIL" -eq 0 ]
