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
#   ./audit-infra.sh --if-older-than=14d        # skip si dernier audit (stamp ou snapshot) < 14j
#   ./audit-infra.sh --strict                   # GATE (VG-5, F13) : cible absente → exit 3 ·
#                                               #   findings ERROR/tests KO → exit 1 (sinon advisory exit 0)
#
# Codes de sortie : 0 = OK (ou advisory) · 1 = findings bloquants (--strict) ·
#   3 = INDÉTERMINÉ (--strict et $CLAUDE_DIR absent : rien d'audité, aucun verdict)
# NB : --strict s'applique aux modes full/quick/axis (pas snapshot/diff, qui restent advisory).
#
# --hook (D-06/D-07, Portabilité Windows II) — PARITÉ D'INTERFACE avec les autres scripts de hook
# du dépôt : accepté par le parsing, mais PAS ENCORE passé par la ligne d'invocation du fragment
# `hooks.json` (qui reste `--quick --if-older-than=14d`, sans --strict ni --hook) — ce câblage
# appartient à la migration en forme exec de la polarité gouvernance, hors périmètre de ce plan
# (D-07). Avec cette invocation réelle, --strict n'est jamais atteint : le SEUL code silencieux
# atteignable ce jour est déjà 0. hook_exit() traduit malgré tout le code 3 (INDÉTERMINÉ,
# --strict + $CLAUDE_DIR absent) vers 0 sous --hook, par parité structurelle avec le reste du parc
# (même statut que l'INDÉTERMINÉ de check-agents.sh) et pour rester correct si --strict et --hook
# se combinent un jour. Les findings bloquants (--strict, exit 1) et les erreurs d'usage de
# --diff/--axis (exit 1, hors chemin SessionStart) ne sont JAMAIS traduits — ce sont de vrais
# problèmes, pas des signaux silencieux. Sans --hook (CLI, suites de tests), tous les codes
# documentés ci-dessus restent inchangés.
#
# Reference : skill infrastructure-audit + ADR-031

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
SNAPSHOT="$CLAUDE_DIR/INFRASTRUCTURE_SNAPSHOT.md"
SNAPSHOT_PREV="${SNAPSHOT}.prev"
KNOWN_VERSIONS="$SCRIPTS_DIR/known-versions.txt"
# Stamp du dernier audit (INF-01) : --quick n'ecrit jamais de snapshot, donc sans ce
# fichier le gate --if-older-than ne s'appliquait jamais et chaque SessionStart
# subissait l'audit complet. Dotfile local au lab (a gitignorer, sans gravite sinon).
STAMP="$CLAUDE_DIR/.last-audit"

MODE="full"
AXIS=""
IF_OLDER_THAN=""
STRICT=false
HOOK=false
# Accumulateur strict (VG-5) : les axes y versent leurs findings bloquants. Portée globale —
# valable pour les modes qui appellent les axes DANS le shell courant (full/quick/axis).
STRICT_ERRORS=0

for arg in "$@"; do
  case "$arg" in
    --quick)             MODE="quick" ;;
    --snapshot)          MODE="snapshot" ;;
    --diff)              MODE="diff" ;;
    --strict)            STRICT=true ;;
    --hook)              HOOK=true ;;
    --axis=*)            AXIS="${arg#*=}"; MODE="axis" ;;
    --if-older-than=*)   IF_OLDER_THAN="${arg#*=}" ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
  esac
done

log() { echo "[audit-infra] $*" >&2; }

# --- Traduction du silence interne vers le harness (D-06/D-07, uniquement sous --hook) ----------
# hook_exit <code> : sous --hook, le SEUL code de silence interne (3 = INDÉTERMINÉ) devient 0 à la
# frontière du harness. 1 (findings bloquants, erreurs d'usage --diff/--axis) n'est jamais traduit.
# Sans --hook, le code recu ressort inchange. Voir docs/HOOKS-CONTRAT-SORTIE.md §2.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" = true ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}

# Contrat de découverte (F13, vacuous green) : sans $CLAUDE_DIR, toutes les boucles d'audit
# sont sautées et l'exit 0 serait un vert non mérité. En --strict : exit 3 = INDÉTERMINÉ.
if $STRICT && [ ! -d "$CLAUDE_DIR" ]; then
  log "✗ INDÉTERMINÉ : $CLAUDE_DIR absent — rien à auditer, aucun verdict rendu (exit 3)"
  hook_exit 3
fi

# ---------- if-older-than guard ----------
# Le gate d'age porte sur le plus RECENT de {stamp .last-audit, snapshot} (INF-01).
# Valeur malformee (ex: 2w) → gate ignore silencieusement, l'audit tourne (INF-04 :
# fail-open explicite, plus de "[: 2w: integer expression expected" sur stderr).
if [ -n "$IF_OLDER_THAN" ]; then
  days="${IF_OLDER_THAN%d}"
  case "$days" in
    ''|*[!0-9]*) days="" ;;
  esac
  if [ -n "$days" ]; then
    ref_mtime=0
    for ref in "$SNAPSHOT" "$STAMP"; do
      [ -f "$ref" ] || continue
      # stat GNU d'abord : sur GNU, `stat -f %m` renvoie silencieusement le point de
      # montage (mode filesystem) — l'ordre inverse donnerait un mtime faux sans erreur.
      m=$(stat -c %Y "$ref" 2>/dev/null || stat -f %m "$ref" 2>/dev/null || echo 0)
      case "$m" in ''|*[!0-9]*) m=0 ;; esac
      [ "$m" -gt "$ref_mtime" ] && ref_mtime=$m
    done
    if [ "$ref_mtime" -gt 0 ]; then
      age_days=$(( ($(date +%s) - ref_mtime) / 86400 ))
      if [ "$age_days" -lt "$days" ]; then
        log "Dernier audit recent ($age_days j < $days j), skip"
        exit 0
      fi
    fi
  fi
fi

# ---------- Axe 1 : Runtime ----------
# Vrai si $1 >= $2 (semver X.Y.Z, tri numerique portable BSD+GNU).
semver_ge() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$1" ]
}

audit_runtime() {
  log "Axe 1 — Runtime Claude Code"

  local claude_version="unknown"
  if command -v claude >/dev/null 2>&1; then
    # Extract first semver-like pattern (handles "2.1.150 (Claude Code)" or similar)
    claude_version=$(claude --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    [ -z "$claude_version" ] && claude_version="unknown"
  fi

  local version_known="false"
  local version_note=""
  if [ "$claude_version" != "unknown" ] && [ -f "$KNOWN_VERSIONS" ]; then
    if grep -q "^$claude_version$" "$KNOWN_VERSIONS" 2>/dev/null; then
      version_known="true"
    else
      # INF-05 : une version PLUS RECENTE que la derniere validee est consideree known
      # (avec mention) — sinon chaque release Claude Code re-injecte "version_known:
      # false" en permanence tant que la whitelist n'est pas re-editee a la main.
      local last_known
      last_known=$(grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' "$KNOWN_VERSIONS" 2>/dev/null | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
      if [ -n "$last_known" ] && semver_ge "$claude_version" "$last_known"; then
        version_known="true"
        version_note="$claude_version > derniere version validee ($last_known), supposee compatible"
      fi
    fi
  fi

  cat <<EOF
{
  "axis": "runtime",
  "claude_version": "$claude_version",
  "version_known": $version_known,
  "version_note": "$version_note",
  "tools_natifs_hardcoded": ["Read", "Write", "Edit", "Bash", "Skill", "Task", "WebFetch"],
  "hooks_events_hardcoded": ["SessionStart", "SessionEnd", "PreCompact", "Stop", "PreToolUse", "PostToolUse", "Notification", "UserPromptSubmit"]
}
EOF
}

# ---------- Axe 2 : Hooks ----------
# Accumulateur de detections (INF-02) : une ligne formatee par probleme releve.
# Portee dynamique : `detections` est la variable locale de audit_hooks.
det_add() {
  detections="${detections}${detections:+
}$1"
}

audit_hooks() {
  log "Axe 2 — Hooks contract"

  local known_events="SessionStart SessionEnd PreCompact Stop PreToolUse PostToolUse Notification UserPromptSubmit"
  local errors_count=0
  local warnings_count=0
  local detections=""
  local files_audited=()
  local total_hooks=0
  local sf py_out sev code detail src

  for sf in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.local.json"; do
    [ -f "$sf" ] || continue
    files_audited+=("$sf")

    # JSON valide ?
    if ! python3 -c "import json; json.load(open('$sf'))" 2>/dev/null; then
      errors_count=$((errors_count + 1))
      det_add "ERR json_invalid : $sf"
      continue
    fi

    # Parse hooks via python — sortie CAPTUREE puis comptee (INF-02) : avant, les
    # lignes ERR|/WARN| fuyaient brutes sur stdout et errors_count restait a 0
    # (l'audit mentait). Le format d'echange reste SEV|code|detail|source.
    py_out="$(python3 - "$sf" "$known_events" 2>/dev/null <<'PYEOF'
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
)"

    # Comptage + formatage des detections (boucle dans le shell courant via heredoc,
    # pas de pipe : un `| while` perdrait les compteurs dans un sous-shell).
    while IFS='|' read -r sev code detail src; do
      [ -n "$sev" ] || continue
      case "$sev" in
        ERR)  errors_count=$((errors_count + 1));     det_add "ERR $code : $detail ($src)" ;;
        WARN) warnings_count=$((warnings_count + 1)); det_add "WARN $code : $detail ($src)" ;;
      esac
    done <<EOF_DET
$py_out
EOF_DET
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
  # Tableau JSON des detections : echappement minimal (backslash puis quotes),
  # une chaine par ligne accumulee.
  local det_json="[]"
  if [ -n "$detections" ]; then
    det_json="[$(printf '%s\n' "$detections" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/",/' | tr -d '\n' | sed 's/,$//')]"
  fi
  cat <<EOF
{
  "axis": "hooks",
  "settings_files_audited": $files_json,
  "total_hooks": $total_hooks,
  "errors_count": $errors_count,
  "warnings_count": $warnings_count,
  "detections": $det_json
}
EOF
  STRICT_ERRORS=$((STRICT_ERRORS + errors_count))
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
  STRICT_ERRORS=$((STRICT_ERRORS + syntax_errs_count + tests_fail + ${#deps_missing[@]}))
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
    # INF-01 : --quick n'ecrit pas de snapshot — poser un stamp pour que le gate
    # --if-older-than s'applique aux sessions suivantes (sinon audit a CHAQUE start).
    touch "$STAMP" 2>/dev/null || true
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

# Verdict --strict (VG-5) : les findings ERROR portés jusque-là uniquement par le JSON
# deviennent un exit code — un agent/CI peut enfin bloquer dessus.
if $STRICT && [ "$STRICT_ERRORS" -gt 0 ]; then
  log "✗ --strict : $STRICT_ERRORS finding(s) bloquant(s) (voir JSON ci-dessus)"
  exit 1
fi
