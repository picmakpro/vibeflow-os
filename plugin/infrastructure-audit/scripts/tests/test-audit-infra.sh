#!/usr/bin/env bash
# test-audit-infra.sh — Suite de audit-infra.sh (fiabilisation INF-01/02/04/05).
#
# T1 — INF-01 : --quick pose le stamp .last-audit
# T2 — INF-01 : --quick --if-older-than=14d avec stamp frais → skip (aucun JSON injecté)
# T3 — INF-04 : --if-older-than=2w (malformé) → pas de "integer expression" sur stderr,
#               gate ignoré silencieusement et audit exécuté (fail-open)
# T4 — INF-02 : settings.json avec script manquant + event inconnu → errors_count/warnings_count
#               alimentés + détections formatées dans le JSON, aucune fuite brute ERR|/WARN|
# T5 — INF-05 : version listée → known ; plus récente que la dernière validée → known + note ;
#               ancienne non listée → false
# T6 — INF-05 : la whitelist couvre bien 2.1.215

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$TESTS_DIR/.." && pwd)/audit-infra.sh"
SRC_KNOWN="$(cd "$TESTS_DIR/.." && pwd)/known-versions.txt"
# Exécuter le script avec le bash qui exécute la suite (/bin/bash → validation 3.2 réelle).
BASH_BIN="${BASH:-bash}"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-audit-infra (script: $SCRIPT) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Lab propre (T1-T3, T5) + lab avec settings cassé (T4). Le script se lance depuis le
# lab (CLAUDE_DIR par défaut .claude, chemins de hooks relatifs au lab).
LAB="$WORK/lab"
LAB_ERR="$WORK/lab-err"
mkdir -p "$LAB/.claude/scripts" "$LAB_ERR/.claude/scripts"
cp "$SRC_KNOWN" "$LAB/.claude/scripts/known-versions.txt"

# Faux binaire claude (version pilotée par FAKE_CLAUDE_VERSION) pour l'axe runtime.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'SH'
#!/bin/sh
echo "${FAKE_CLAUDE_VERSION:-2.1.215} (Claude Code)"
SH
chmod +x "$WORK/bin/claude"

run_in() { # run_in <labdir> [env VAR=x ...] -- args...
  local lab="$1"; shift
  (cd "$lab" && "$@")
}

# T1 — --quick pose le stamp
run_in "$LAB" "$BASH_BIN" "$SCRIPT" --quick >/dev/null 2>&1
if [ -f "$LAB/.claude/.last-audit" ]; then
  ok "T1 INF-01 : --quick pose le stamp .claude/.last-audit"
else
  ko "T1 stamp absent après --quick"
fi

# T2 — gate d'âge : stamp frais → skip, rien sur stdout
OUT="$(run_in "$LAB" "$BASH_BIN" "$SCRIPT" --quick --if-older-than=14d 2>"$WORK/t2.err")"
if [ -z "$OUT" ] && grep -q "skip" "$WORK/t2.err"; then
  ok "T2 INF-01 : stamp frais → skip (aucune injection stdout au SessionStart)"
else
  ko "T2 skip attendu (out='$OUT', err=$(cat "$WORK/t2.err" 2>/dev/null))"
fi

# T3 — valeur malformée (2w) : silencieux sur l'erreur, audit exécuté quand même
rm -f "$LAB/.claude/.last-audit" "$LAB/.claude/INFRASTRUCTURE_SNAPSHOT.md"
OUT="$(run_in "$LAB" "$BASH_BIN" "$SCRIPT" --quick --if-older-than=2w 2>"$WORK/t3.err")"
if grep -q "integer expression" "$WORK/t3.err"; then
  ko "T3 INF-04 : 'integer expression expected' fuit encore sur stderr"
elif echo "$OUT" | grep -q '"axis": "runtime"'; then
  ok "T3 INF-04 : --if-older-than=2w → gate ignoré proprement, audit exécuté"
else
  ko "T3 audit attendu malgré la valeur malformée (out='$OUT')"
fi

# T4 — comptage + formatage des détections hooks
cat > "$LAB_ERR/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "SessionStart": [
      { "matcher": "startup", "hooks": [ { "type": "command", "command": "bash .claude/scripts/fantome.sh --quick" } ] }
    ],
    "EventInconnu": [
      { "hooks": [ { "type": "command", "command": "echo ok" } ] }
    ]
  }
}
JSON
OUT="$(run_in "$LAB_ERR" "$BASH_BIN" "$SCRIPT" --axis=hooks 2>/dev/null)"
T4_OK=1
echo "$OUT" | grep -q '"errors_count": 1' || { T4_OK=0; ko "T4 INF-02 : errors_count devrait valoir 1 (script manquant), sortie : $OUT"; }
echo "$OUT" | grep -q '"warnings_count": 1' || { T4_OK=0; ko "T4 INF-02 : warnings_count devrait valoir 1 (event inconnu)"; }
echo "$OUT" | grep -q 'script_missing' || { T4_OK=0; ko "T4 INF-02 : la détection script_missing devrait figurer dans le JSON"; }
if echo "$OUT" | grep -Eq '^(ERR|WARN)\|'; then
  T4_OK=0; ko "T4 INF-02 : des lignes brutes ERR|/WARN| fuient encore sur stdout"
fi
[ "$T4_OK" -eq 1 ] && ok "T4 INF-02 : détections comptées + formatées dans le JSON, pas de fuite brute"

# T5 — axe runtime : version listée / plus récente / ancienne inconnue
OUT="$(run_in "$LAB" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=2.1.215 "$BASH_BIN" "$SCRIPT" --axis=runtime 2>/dev/null)"
if echo "$OUT" | grep -q '"version_known": true' && echo "$OUT" | grep -q '"version_note": ""'; then
  ok "T5a INF-05 : version listée (2.1.215) → known, sans note"
else
  ko "T5a known attendu pour 2.1.215, sortie : $OUT"
fi
OUT="$(run_in "$LAB" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=2.1.999 "$BASH_BIN" "$SCRIPT" --axis=runtime 2>/dev/null)"
if echo "$OUT" | grep -q '"version_known": true' && echo "$OUT" | grep -q 'supposee compatible'; then
  ok "T5b INF-05 : version plus récente que la dernière validée → known + note explicite"
else
  ko "T5b known+note attendus pour 2.1.999, sortie : $OUT"
fi
OUT="$(run_in "$LAB" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=1.0.0 "$BASH_BIN" "$SCRIPT" --axis=runtime 2>/dev/null)"
if echo "$OUT" | grep -q '"version_known": false'; then
  ok "T5c INF-05 : version ancienne non listée → false (pas de faux positif)"
else
  ko "T5c false attendu pour 1.0.0, sortie : $OUT"
fi

# T6 — la whitelist couvre le runtime récent
if grep -q '^2\.1\.215$' "$SRC_KNOWN"; then
  ok "T6 INF-05 : known-versions.txt couvre 2.1.215"
else
  ko "T6 whitelist toujours périmée (2.1.215 absent)"
fi

# T7 — VG-5 (F13) : --strict sans .claude → exit 3 (INDÉTERMINÉ, plus de JSON à zéro en vert)
EMPTY="$WORK/no-lab"; mkdir -p "$EMPTY"
run_in "$EMPTY" "$BASH_BIN" "$SCRIPT" --strict --quick >/dev/null 2>&1
rc=$?
[ "$rc" -eq 3 ] && ok "T7 VG-5 : --strict + .claude absent → exit 3 INDÉTERMINÉ" || ko "T7 --strict sans cible devrait sortir 3, obtenu rc=$rc"

# T8 — VG-5 : --strict avec finding ERROR (script de hook manquant) → exit 1
run_in "$LAB_ERR" "$BASH_BIN" "$SCRIPT" --strict --axis=hooks >/dev/null 2>&1
rc=$?
[ "$rc" -eq 1 ] && ok "T8 VG-5 : --strict + ERROR hooks → exit 1 (le finding porte enfin un exit code)" || ko "T8 --strict avec ERROR devrait sortir 1, obtenu rc=$rc"

# T9 — VG-5 : --strict sur lab propre → exit 0 ; défaut (sans --strict) sur lab cassé → exit 0 (compat)
run_in "$LAB" "$BASH_BIN" "$SCRIPT" --strict --axis=hooks >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok "T9a VG-5 : --strict sur lab propre → exit 0" || ko "T9a lab propre devrait sortir 0 en strict, obtenu rc=$rc"
run_in "$LAB_ERR" "$BASH_BIN" "$SCRIPT" --axis=hooks >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok "T9b VG-5 : défaut (advisory) inchangé → exit 0 même avec ERROR" || ko "T9b advisory devrait rester 0, obtenu rc=$rc"

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
