#!/usr/bin/env bash
# archive.sh — Archive les entrees obsoletes d'un registre selon 3 criteres AND
#
# Criteres (TOUS doivent etre vrais pour archiver) :
#   C1 — Statut : RESOLU | OBSOLETE | SUPERSEDED | Deprecee | Archivee | Rejetee | Differee
#   C2 — Age   : > THRESHOLD_DAYS (90 par defaut)
#   C3 — Refs recentes : 0 mention dans ITERATION_LOG.md (5 dernieres sessions)
#
# Usage:
#   ./archive.sh --apply
#   ./archive.sh --dry-run --threshold-days=60
#   ./archive.sh --async --apply  # mode hook SessionEnd
#
# Reference : ADR-032 pilier 2 (Archivage)

set -euo pipefail

MEMORY_DIR="${MEMORY_DIR:-.claude/memory}"
ARCHIVE_DIR="${ARCHIVE_DIR:-$MEMORY_DIR/archive}"
ALLOWLIST="${ALLOWLIST:-.claude/scripts/archive.allowlist}"
LOCK_FILE="$MEMORY_DIR/.lock"
LOG_FILE="${LOG_FILE:-.claude/logs/archive.log}"

DRY_RUN=true
ASYNC=false
THRESHOLD_DAYS=90

# ---------- Arg parsing ----------
for arg in "$@"; do
  case "$arg" in
    --apply)              DRY_RUN=false ;;
    --dry-run)            DRY_RUN=true ;;
    --async)              ASYNC=true ;;
    --threshold-days=*)   THRESHOLD_DAYS="${arg#*=}" ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
  esac
done

mkdir -p "$ARCHIVE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  local ts
  ts=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")
  echo "$ts [archive.sh] $*" | tee -a "$LOG_FILE" >&2
}

# ---------- Lock ----------
if [ -f "$LOCK_FILE" ]; then
  # macOS: stat -f %m, Linux: stat -c %Y
  lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0) ))
  if [ "$lock_age" -lt 300 ]; then
    log "lock active ($lock_age s < 300 s), skip"
    exit 0
  fi
fi
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

log "start (threshold=${THRESHOLD_DAYS}j, mode=$([ "$DRY_RUN" = true ] && echo dry-run || echo apply))"

# ---------- Helpers ----------
# Check if ID is in allowlist
in_allowlist() {
  local id="$1"
  [ -f "$ALLOWLIST" ] || return 1
  grep -q "^${id}$" "$ALLOWLIST"
}

# Get age in days from date string YYYY-MM-DD
age_days() {
  local date_str="$1"
  local entry_epoch
  # macOS BSD date
  entry_epoch=$(date -j -f "%Y-%m-%d" "$date_str" "+%s" 2>/dev/null || \
                date -d "$date_str" "+%s" 2>/dev/null || \
                echo 0)
  [ "$entry_epoch" = "0" ] && echo 0 && return
  local now_epoch
  now_epoch=$(date +%s)
  echo $(( (now_epoch - entry_epoch) / 86400 ))
}

# Count references to ID in ITERATION_LOG.md (last 5 sessions)
recent_refs() {
  local id="$1"
  local log_file="$MEMORY_DIR/ITERATION_LOG.md"
  if [ ! -f "$log_file" ]; then
    echo 0
    return
  fi
  # Take last ~500 lines (approximate "5 sessions")
  # grep -c returns "0" with exit 1 if no match — handle to avoid double output
  local count
  count=$(tail -500 "$log_file" | grep -c "$id" 2>/dev/null) || count=0
  # Strip whitespace/newlines defensively
  echo "$count" | tr -d '\n '
}

# Statuts archivables (case-insensitive matching + accents francais)
is_archivable_status() {
  local status="$1"
  case "$status" in
    *RESOLU*|*Resolu*|*resolu*|*RÉSOLU*|*Résolu*|*résolu*) return 0 ;;
    *OBSOLETE*|*Obsolete*|*obsolete*|*OBSOLÈTE*|*Obsolète*|*obsolète*) return 0 ;;
    *SUPERSEDED*|*Superseded*|*Supersedee*|*supersedee*|*Supersédée*|*Supersedée*) return 0 ;;
    *Deprecee*|*Deprecated*|*deprecee*|*Dépréciée*|*dépréciée*) return 0 ;;
    *Archivee*|*Archived*|*archivee*|*Archivée*|*archivée*) return 0 ;;
    *Rejetee*|*Rejected*|*rejetee*|*Rejetée*|*rejetée*) return 0 ;;
    *Differee*|*Deferred*|*differee*|*Différée*|*différée*) return 0 ;;
  esac
  return 1
}

# ---------- Core scan ----------
scan_register() {
  local file="$1"
  local archived=0

  [ -f "$file" ] || return 0
  log "scan $file"

  # Find all body sections, capture ID + Date + Statut
  # awk parses contiguous blocks starting with "## XXX-YYY :"
  awk '
    /^## [A-Z]+-[0-9]+/ {
      if (id != "") {
        print id "|" date "|" status "|" start_line "|" (NR - 1)
      }
      # Extract ID
      line = $0
      sub(/^## /, "", line)
      if (match(line, /^[A-Z]+-[0-9]+/)) {
        id = substr(line, 1, RLENGTH)
      } else {
        id = ""
      }
      date = ""
      status = ""
      start_line = NR
      next
    }
    /^\*\*Date[^\*]*\*\* *:/ {
      # Match "**Date** :" OR "**Date ouverture** :" OR "**Date de creation** :" etc.
      d = $0
      sub(/^\*\*Date[^*]*\*\* *: */, "", d)
      sub(/^\[/, "", d)
      sub(/\].*$/, "", d)
      # Keep only first YYYY-MM-DD found
      if (match(d, /[0-9]{4}-[0-9]{2}-[0-9]{2}/)) {
        date = substr(d, RSTART, RLENGTH)
      }
    }
    /^\*\*Statut\*\* *:/ {
      s = $0
      sub(/^\*\*Statut\*\* *: */, "", s)
      status = s
    }
    END {
      if (id != "") {
        print id "|" date "|" status "|" start_line "|" NR
      }
    }
  ' "$file" | while IFS='|' read -r id date status start end; do
    [ -z "$id" ] && continue

    # C1 — Statut
    if ! is_archivable_status "$status"; then
      continue
    fi

    # Allowlist
    if in_allowlist "$id"; then
      log "  $id: in allowlist, skip"
      continue
    fi

    # C2 — Age
    if [ -z "$date" ]; then
      continue
    fi
    age=$(age_days "$date")
    if [ "$age" -lt "$THRESHOLD_DAYS" ]; then
      continue
    fi

    # C3 — Refs recentes
    refs=$(recent_refs "$id")
    if [ "$refs" -gt 0 ]; then
      log "  $id: $refs refs recentes, skip"
      continue
    fi

    log "  $id: C1=ok C2=ok ($age j) C3=ok (0 refs) -> ARCHIVABLE"

    if [ "$DRY_RUN" = false ]; then
      # Move section to archive
      base=$(basename "$file" .md)
      archive_file="$ARCHIVE_DIR/${base}-archive.md"
      [ -f "$archive_file" ] || {
        echo "# Archive — $base" > "$archive_file"
        echo "" >> "$archive_file"
        echo "> Entrees deplacees depuis $file" >> "$archive_file"
        echo "" >> "$archive_file"
      }
      # Extract section content (line $start to $end) and append
      sed -n "${start},${end}p" "$file" >> "$archive_file"
      echo "" >> "$archive_file"
      log "  $id: appended to $archive_file"
      archived=$((archived + 1))
    fi
  done

  echo "$archived"
}

# ---------- Main ----------
total=0
for f in "$MEMORY_DIR"/ADR.md "$MEMORY_DIR"/LEARNINGS.md "$MEMORY_DIR"/BLOCKERS.md "$MEMORY_DIR"/EVALS.md "$MEMORY_DIR"/DECISIONS.md; do
  [ -f "$f" ] || continue
  scan_register "$f" || true
done

# Note: actual deletion from source file requires careful handling
# For v1: archive.sh appends to archive only, manual cleanup of source recommended via /consolidate review
# This is intentional safety: no destructive op without /consolidate review

log "done"
