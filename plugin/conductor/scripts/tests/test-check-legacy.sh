#!/usr/bin/env bash
# test-check-legacy.sh — détection scope-aware du legacy (pré ADR-052/053).
# ISOLATION : HOME forcé vers un temp SANS .claude → seul le scope projet (cwd/.claude) est inspecté.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-legacy.sh"
PASS=0; FAIL=0
assert() { # assert "label" "haystack" "needle"
  if printf '%s' "$2" | grep -qF "$3"; then echo "  ✅ $1"; PASS=$((PASS+1))
  else echo "  ❌ $1"; echo "     attendu: $3"; echo "     obtenu : $2"; FAIL=$((FAIL+1)); fi
}

# fabrique un lab jetable avec un registre + (optionnellement) les artefacts
mklab() { # mklab <version-dev-orch> <with_artifacts:yes|no>
  local ver="$1" arts="$2" lab; lab="$(mktemp -d)"
  mkdir -p "$lab/.claude/scripts"
  printf 'dev-orchestrator=%s\n' "$ver" > "$lab/.claude/scripts/.vibeflow-installed"
  if [ "$arts" = "yes" ]; then
    : > "$lab/.claude/scripts/dag.sh"
    : > "$lab/.claude/scripts/driver-lock.sh"
    mkdir -p "$lab/.claude/agents/dev-orchestrator-references"
    : > "$lab/.claude/agents/dev-orchestrator-references/mission-flow.md"
  fi
  printf '%s' "$lab"
}
run() { ( cd "$1"; HOME="$1/nohome" bash "$SCRIPT" "${2:-}" ); }

echo "=== T1 — version legacy (v1.6.0 < v1.7.0) → action-needed ==="
LAB=$(mklab "v1.6.0" no)
out=$(run "$LAB" --print)
assert "T1.1 — verdict action-needed" "$out" '"verdict": "action-needed"'
assert "T1.2 — statut legacy"         "$out" '"status": "legacy"'
rm -rf "$LAB"

echo "=== T2 — version OK mais artefacts manquants → drift ==="
LAB=$(mklab "v1.7.0" no)
out=$(run "$LAB" --print)
assert "T2.1 — statut drift"          "$out" '"status": "drift"'
assert "T2.2 — dag.sh listé manquant" "$out" 'scripts/dag.sh'
rm -rf "$LAB"

echo "=== T3 — version OK + artefacts présents → current ==="
LAB=$(mklab "v1.7.0" yes)
out=$(run "$LAB" --print)
assert "T3.1 — verdict current"       "$out" '"verdict": "current"'
rm -rf "$LAB"

echo "=== T4 — aucun module concerné → pas de faux positif ==="
LAB="$(mktemp -d)"; mkdir -p "$LAB/.claude/scripts"; : > "$LAB/.claude/scripts/.vibeflow-installed"
out=$(run "$LAB" --print)
assert "T4.1 — verdict current (rien installé)" "$out" '"verdict": "current"'
assert "T4.2 — scopes vide"                     "$out" '"scopes": []'
rm -rf "$LAB"

echo "=== T5 — sortie humaine : nudge /vf-update ==="
LAB=$(mklab "v1.6.0" no)
out=$(run "$LAB")
assert "T5.1 — nudge /vf-update" "$out" '/vf-update'
rm -rf "$LAB"

echo ""
echo "=================================="
echo "  check-legacy : $PASS PASS / $FAIL FAIL"
echo "=================================="
[ "$FAIL" -eq 0 ]
