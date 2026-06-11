#!/usr/bin/env bash
# audit-infra.sh — Audit infrastructure technique d'un lab VibeFlow
#
# Axes :
#   1. Runtime Claude Code (version, tools natifs)
#   2. Hooks contract (settings.json valide, events reconnus, scripts pointes existent)
#   3. Scripts integrite (syntaxe, executable, dependencies, tests)
#   4. Drift Anthropic (snapshot + diff)
#
# Usage:
#   ./audit-infra.sh                            # audit complet (4 axes)
#   ./audit-infra.sh --quick                    # audit minimal (~5s)
#   ./audit-infra.sh --axis=runtime|hooks|scripts|drift
#   ./audit-infra.sh --snapshot                 # genere INFRASTRUCTURE_SNAPSHOT.md
#   ./audit-infra.sh --diff                     # compare snapshot courant vs .prev
#   ./audit-infra.sh --if-older-than=14d        # skip si snapshot < 14j
#
# Reference : skill infrastructure-audit + ADR-031

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SNAPSHOT="$CLAUDE_DIR/INFRASTRUCTURE_SNAPSHOT.md"
SNAPSHOT_PREV="${SNAPSHOT}.prev"
KNOWN_VERSIONS="$SCRIPTS_DIR/known-versions.txt"

MODE="full"
AXIS=""
IF_OLDER_THAN=""

for arg in "$@"; do
  case "$arg" in
    --quick)             MODE="quick" ;;
    --snapshot)          MODE="snapshot" ;;
    --diff)              MODE="diff" ;;
    --axis=*)            AXIS="${arg#*=}"; MODE="axis" ;;
    --if-older-than=*)   IF_OLDER_THAN="${arg#*=}" ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
  esac
done

log() { echo "[audit-infra] $*" >&2; }

# ---------- if-older-than guard ----------
if [ -n "$IF_OLDER_THAN" ] && [ -f "$SNAPSHOT" ]; then
  # Strip 'd' suffix
  days="${IF_OLDER_THAN%d}"
  # Get snapshot age in days
  snapshot_mtime=$(stat -f %m "$SNAPSHOT" 2>/dev/null || stat -c %Y "$SNAPSHOT" 2>/dev/null || echo 0)
  age_days=$(( ($(date +%s) - snapshot_mtime) / 86400 ))
  if [ "$age_days" -lt "$days" ]; then
    log "Snapshot recent ($age_days j < $days j), skip audit"
    exit 0
  fi
fi

# ---------- Axe 1 : Runtime ----------
audit_runtime() {
  log "Axe 1 — Runtime Claude Code"

  local claude_version="unknown"
  if command -v claude >/dev/null 2>&1; then
    # Extract first semver-like pattern (handles "2.1.150 (Claude Code)" or similar)
    claude_version=$(claude --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    [ -z "$claude_version" ] && claude_version="unknown"
  fi

  local version_known="false"
  if [ -f "$KNOWN_VERSIONS" ] && grep -q "^$claude_version$" "$KNOWN_VERSIONS" 2>/dev/null; then
    version_known="true"
  fi

  cat <<EOF
{
  "axis": "runtime",
  "claude_version": "$claude_version",
  "version_known": $version_known,
  "tools_natifs_hardcoded": ["Read", "Write", "Edit", "Bash", "Skill", "Task", "WebFetch"],
  "hooks_events_hardcoded": ["SessionStart", "SessionEnd", "PreCompact", "Stop", "PreToolUse", "PostToolUse", "Notification", "UserPromptSubmit"]
}
EOF
}

# ---------- Axe 2 : Hooks ----------
audit_hooks() {
  log "Axe 2 — Hooks contract"

  local known_events="SessionStart SessionEnd PreCompact Stop PreToolUse PostToolUse Notification UserPromptSubmit"
  local errors=()
  local warnings=()
  local files_audited=()
  local total_hooks=0

  for sf in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.local.json"; do
    [ -f "$sf" ] || continue
    files_audited+=("$sf")

    # JSON valide ?
    if ! python3 -c "import json; json.load(open('$sf'))" 2>/dev/null; then
      errors+=("'$sf' : JSON invalide")
      continue
    fi

    # Parse hooks via python
    python3 - "$sf" "$known_events" <<'PYEOF' 2>/dev/null
import json
import sys
import os

sf = sys.argv[1]
known = sys.argv[2].split()

with open(sf) as f:
    data = json.load(f)

hooks = data.get("hooks", {})
if not isinstance(hooks, dict):
    sys.exit(0)

for event, configs in hooks.items():
    if event not in known:
        print(f"WARN|event_unknown|{event}|{sf}")
    if not isinstance(configs, list):
        continue
    for cfg in configs:
        if not isinstance(cfg, dict):
            continue
        for hook in cfg.get("hooks", []):
            htype = hook.get("type", "")
            if htype not in ("command", "agent"):
                print(f"ERR|type_invalid|{htype}|{sf}")
                continue
            if htype == "command":
                cmd = hook.get("command", "")
                # Extract first path that looks like a script
                tokens = cmd.split()
                for tok in tokens:
                    if tok.endswith(".sh") and "/" in tok:
                        path = tok.replace("$CLAUDE_PROJECT_DIR/", "")
                        if not os.path.exists(path):
                            print(f"ERR|script_missing|{path}|{sf}")
                        elif not os.access(path, os.X_OK):
                            print(f"WARN|script_not_executable|{path}|{sf}")
                        break
PYEOF
  done

  # Count hooks
  if [ ${#files_audited[@]} -gt 0 ]; then
    for sf in "${files_audited[@]}"; do
      hc=$(python3 -c "
import json
try:
    d = json.load(open('$sf'))
    h = d.get('hooks', {})
    if isinstance(h, dict):
        print(sum(len(v) if isinstance(v, list) else 0 for v in h.values()))
    else:
        print(0)
except: print(0)
" 2>/dev/null)
      total_hooks=$((total_hooks + hc))
    done
  fi

  # Output
  local files_json="[]"
  if [ ${#files_audited[@]} -gt 0 ]; then
    files_json="[$(printf '"%s",' "${files_audited[@]}" | sed 's/,$//')]"
  fi
  cat <<EOF
{
  "axis": "hooks",
  "settings_files_audited": $files_json,
  "total_hooks": $total_hooks,
  "errors_count": ${#errors[@]},
  "warnings_count": ${#warnings[@]}
}
EOF
}

# ---------- Axe 3 : Scripts ----------
audit_scripts() {
  log "Axe 3 — Scripts integrite"

  local total=0
  local syntax_ok=0
  local exec_ok=0
  local syntax_errs=()
  local deps=("bash" "awk" "grep" "sed" "python3" "jq" "git" "date")
  local deps_missing=()

  if [ -d "$SCRIPTS_DIR" ]; then
    for f in "$SCRIPTS_DIR"/*.sh; do
      [ -f "$f" ] || continue
      total=$((total + 1))
      bash -n "$f" 2>/dev/null && syntax_ok=$((syntax_ok + 1)) || syntax_errs+=("$f")
      [ -x "$f" ] && exec_ok=$((exec_ok + 1))
    done
  fi

  for cmd in "${deps[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || deps_missing+=("$cmd")
  done

  # Run tests si presents
  local tests_pass=0
  local tests_fail=0
  if [ -d "$SCRIPTS_DIR/tests" ]; then
    for t in "$SCRIPTS_DIR/tests/"test-*.sh; do
      [ -f "$t" ] || continue
      if "$t" >/dev/null 2>&1; then
        tests_pass=$((tests_pass + 1))
      else
        tests_fail=$((tests_fail + 1))
      fi
    done
  fi

  local deps_json="[]"
  if [ ${#deps_missing[@]} -gt 0 ]; then
    deps_json="[$(printf '"%s",' "${deps_missing[@]}" | sed 's/,$//')]"
  fi
  local syntax_errs_count=0
  [ ${#syntax_errs[@]} -gt 0 ] && syntax_errs_count=${#syntax_errs[@]}
  cat <<EOF
{
  "axis": "scripts",
  "scripts_total": $total,
  "syntax_ok": $syntax_ok,
  "syntax_errors": $syntax_errs_count,
  "executable_ok": $exec_ok,
  "deps_missing": $deps_json,
  "tests_pass": $tests_pass,
  "tests_fail": $tests_fail
}
EOF
}

# ---------- Snapshot ----------
generate_snapshot() {
  log "Generation snapshot $SNAPSHOT"

  # Backup previous
  [ -f "$SNAPSHOT" ] && mv "$SNAPSHOT" "$SNAPSHOT_PREV"

  local ts
  ts=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")

  local runtime hooks scripts
  runtime=$(audit_runtime 2>/dev/null)
  hooks=$(audit_hooks 2>/dev/null)
  scripts=$(audit_scripts 2>/dev/null)

  cat > "$SNAPSHOT" <<EOF
# Infrastructure Snapshot — $(basename "$PWD")

**Date** : $ts
**Generated by** : audit-infra.sh
**Mode** : full snapshot

## Runtime Claude Code

\`\`\`json
$runtime
\`\`\`

## Hooks Contract

\`\`\`json
$hooks
\`\`\`

## Scripts Integrite

\`\`\`json
$scripts
\`\`\`

## Modules vibeflow-os installes

EOF

  if [ -f "$SCRIPTS_DIR/.vibeflow-installed" ]; then
    echo '```' >> "$SNAPSHOT"
    cat "$SCRIPTS_DIR/.vibeflow-installed" >> "$SNAPSHOT"
    echo '```' >> "$SNAPSHOT"
  else
    echo "_Aucun module installe via vibeflow-update.sh_" >> "$SNAPSHOT"
  fi

  log "Snapshot ecrit : $SNAPSHOT"
}

# ---------- Diff ----------
do_diff() {
  if [ ! -f "$SNAPSHOT" ]; then
    log "Pas de snapshot courant. Lancer --snapshot d'abord."
    exit 1
  fi
  if [ ! -f "$SNAPSHOT_PREV" ]; then
    log "Pas de snapshot precedent (.prev). Premier snapshot, rien a diff."
    exit 0
  fi

  echo "=== Diff $SNAPSHOT_PREV vs $SNAPSHOT ==="
  diff -u "$SNAPSHOT_PREV" "$SNAPSHOT" || true
}

# ---------- Main ----------
case "$MODE" in
  quick)
    log "Audit quick"
    audit_runtime
    audit_hooks
    ;;
  axis)
    case "$AXIS" in
      runtime) audit_runtime ;;
      hooks)   audit_hooks ;;
      scripts) audit_scripts ;;
      *) log "Axe inconnu : $AXIS"; exit 1 ;;
    esac
    ;;
  snapshot)
    generate_snapshot
    ;;
  diff)
    do_diff
    ;;
  full|*)
    log "Audit complet (4 axes)"
    audit_runtime
    audit_hooks
    audit_scripts
    log "Pour generer snapshot : ./audit-infra.sh --snapshot"
    ;;
esac
