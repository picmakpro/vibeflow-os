#!/usr/bin/env bash
# archive.sh — Archive les entrees obsoletes d'un registre selon 3 criteres AND
#
# Criteres (TOUS doivent etre vrais pour archiver) :
#   C1 — Statut : RESOLU | OBSOLETE | SUPERSEDED | Deprecee | Archivee | Rejetee | Differee
#   C2 — Age   : > THRESHOLD_DAYS (90 par defaut)
#   C3 — Refs recentes : 0 mention dans ITERATION_LOG.md ET JOURNAL.md (5 dernieres sessions)
#
# Usage:
#   ./archive.sh --apply
#   ./archive.sh --dry-run --threshold-days=60
#   ./archive.sh --async --apply  # mode hook SessionEnd (se detache reellement)
#
# Fiabilisation (CSL 2026-07) :
#   - CSL-02 : idempotent — une entree deja presente dans l'archive n'est jamais re-appendee
#     (le hook SessionEnd repasse a chaque session sur les memes candidats)
#   - CSL-03 : --async reel — relance en arriere-plan via nohup + exit 0 immediat
#     (l'archivage synchrone, mesure 92 s sur gros lab, etait tue par le timeout hook 60 s)
#   - CSL-10 : C3 cumule ITERATION_LOG.md (legacy) ET JOURNAL.md (canon)
#   - CSL-14 : verrou mkdir atomique + stale 300 s + trap quote (chemins a espaces, kill)
#   - CSL-15 : compteur hors sous-shell, aucune creation dans un repertoire non
#     initialise, rotation simple du log
#
# Reference : ADR-032 pilier 2 (Archivage)

set -euo pipefail

MEMORY_DIR="${MEMORY_DIR:-.claude/memory}"
ARCHIVE_DIR="${ARCHIVE_DIR:-$MEMORY_DIR/archive}"
ALLOWLIST="${ALLOWLIST:-.claude/scripts/archive.allowlist}"
LOCK_DIR="${LOCK_DIR:-$MEMORY_DIR/.archive.lock.d}"
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

# CSL-15 : repertoire non initialise (pas de .claude/memory) = rien a archiver, et
# surtout ne RIEN creer (le hook SessionEnd tourne aussi hors labs — il polluait
# n'importe quel cwd avec .claude/memory/archive + .claude/logs).
[ -d "$MEMORY_DIR" ] || exit 0

# CSL-03 : --async reel. SessionEnd a un timeout hook (~60 s) : l'archivage synchrone
# d'un gros lab (mesure 92 s) etait tue en plein vol → archive partielle + lock qui
# fuit. On se detache donc VRAIMENT : relance de soi-meme en arriere-plan (nohup,
# stdio rediriges), exit 0 immediat. Garde d'environnement VF_ARCHIVE_BG : le
# processus enfant ne se re-detache pas (pas de fork-bomb).
if [ "$ASYNC" = true ] && [ -z "${VF_ARCHIVE_BG:-}" ]; then
  export VF_ARCHIVE_BG=1
  nohup bash "$0" "$@" >/dev/null 2>&1 </dev/null &
  disown 2>/dev/null || true
  exit 0
fi

mkdir -p "$ARCHIVE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# CSL-15 : rotation simple du log — si > 500 lignes, garder les 250 dernieres
# (le hook SessionEnd append a chaque session, sans borne le log grossit sans fin).
if [ -f "$LOG_FILE" ]; then
  _log_lines=$(wc -l < "$LOG_FILE" | tr -d ' ')
  if [ "${_log_lines:-0}" -gt 500 ] 2>/dev/null; then
    tail -250 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
  fi
fi

log() {
  local ts
  ts=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")
  echo "$ts [archive.sh] $*" | tee -a "$LOG_FILE" >&2
}

# ---------- Lock (CSL-14 : mkdir atomique, stale 300 s, trap quote) ----------
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # mtime portable — GNU d'abord (l'ordre inverse renvoie silencieusement le mount
  # point sur GNU stat).
  lock_age=$(( $(date +%s) - $(stat -c %Y "$LOCK_DIR" 2>/dev/null || stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0) ))
  if [ "$lock_age" -lt 300 ]; then
    log "lock actif ($lock_age s < 300 s), skip"
    exit 0
  fi
  # Verrou perime (process tue) : on le casse, une seule retentative.
  rm -rf "$LOCK_DIR" 2>/dev/null || true
  mkdir "$LOCK_DIR" 2>/dev/null || { log "lock occupe, skip"; exit 0; }
fi
# Trap en quotes SIMPLES : expansion au moment du signal, pas a la definition —
# resiste aux chemins a espaces. INT/TERM relaient vers EXIT (un kill ne fuit
# plus le verrou ; seul SIGKILL echappe, couvert par l'age stale 300 s).
trap 'rm -rf "$LOCK_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

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

# Count references to ID in the session logs (last ~5 sessions)
# CSL-10 : les labs canon ecrivent JOURNAL.md (ITERATION_LOG.md = legacy) — ne lire
# que le legacy rendait C3 aveugle sur ces labs → archivage a tort. On CUMULE les deux.
recent_refs() {
  local id="$1"
  local total=0 f count
  for f in "$MEMORY_DIR/ITERATION_LOG.md" "$MEMORY_DIR/JOURNAL.md"; do
    [ -f "$f" ] || continue
    # Take last ~500 lines (approximate "5 sessions")
    # grep -c returns "0" with exit 1 if no match — handle to avoid double output
    count=$(tail -500 "$f" | grep -c "$id" 2>/dev/null) || count=0
    # Strip whitespace/newlines defensively
    count=$(echo "$count" | tr -d '\n ')
    total=$(( total + ${count:-0} ))
  done
  echo "$total"
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
TOTAL_ARCHIVED=0

scan_register() {
  local file="$1"
  local archived=0
  local id date status start end age refs base archive_file

  [ -f "$file" ] || return 0
  log "scan $file"

  # Find all body sections, capture ID + Date + Statut.
  # CSL-15 : boucle alimentee par process substitution (PAS par un pipe) — l'increment
  # de $archived survit a la boucle (un pipe la confinait dans un sous-shell :
  # compteur toujours a 0 + un « 0 » parasite emis sur stdout).
  while IFS='|' read -r id date status start end; do
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
      base=$(basename "$file" .md)
      archive_file="$ARCHIVE_DIR/${base}-archive.md"
      # CSL-02 : idempotence — v1 ne purge pas la source, donc le hook SessionEnd
      # represente les MEMES candidats a chaque session ; sans ce garde, l'archive
      # accumulait les memes sections en doublons croissants.
      if [ -f "$archive_file" ] && grep -q "^## ${id}[ :]" "$archive_file"; then
        log "  $id: deja dans l'archive, skip"
        continue
      fi
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
  done < <(awk '
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
  ' "$file")

  TOTAL_ARCHIVED=$(( TOTAL_ARCHIVED + archived ))
  return 0
}

# ---------- Main ----------
for f in "$MEMORY_DIR"/ADR.md "$MEMORY_DIR"/BDR.md "$MEMORY_DIR"/LEARNINGS.md "$MEMORY_DIR"/BLOCKERS.md "$MEMORY_DIR"/EVALS.md "$MEMORY_DIR"/DECISIONS.md; do
  [ -f "$f" ] || continue
  scan_register "$f" || true
done

# Note: actual deletion from source file requires careful handling
# For v1: archive.sh appends to archive only, manual cleanup of source recommended via /consolidate review
# This is intentional safety: no destructive op without /consolidate review

log "done ($TOTAL_ARCHIVED entree(s) archivee(s))"
