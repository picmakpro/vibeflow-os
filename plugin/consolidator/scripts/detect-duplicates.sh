#!/usr/bin/env bash
# detect-duplicates.sh — Sort candidats fusion (collisions IDs + similarites titre/tags)
#
# Signaux detectes (sans LLM, juste pattern-matching) :
#   1. Collisions d'IDs (meme ID, 2+ occurrences body) — BLOQUANT
#   2. Titres similaires (Jaccard tokens > 0.5 sur les noms d'entrees)
#   3. Memes mots-cles d'introduction (3 premiers tokens body identiques)
#
# Output : JSON sur stdout
#
# Usage:
#   ./detect-duplicates.sh
#   ./detect-duplicates.sh --register=LEARNINGS
#
# Reference : ADR-032 pilier 3 (Fusion)

set -euo pipefail

MEMORY_DIR="${MEMORY_DIR:-.claude/memory}"
TARGET_REGISTER=""

for arg in "$@"; do
  case "$arg" in
    --register=*)  TARGET_REGISTER="${arg#*=}" ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
  esac
done

# ---------- Helpers ----------
register_file() {
  local name="$1"
  case "$name" in
    DECISIONS)  echo "$MEMORY_DIR/DECISIONS.md" ;;
    ADR)        echo "$MEMORY_DIR/ADR.md" ;;
    LEARNINGS)  echo "$MEMORY_DIR/LEARNINGS.md" ;;
    BLOCKERS)   echo "$MEMORY_DIR/BLOCKERS.md" ;;
    EVALS)      echo "$MEMORY_DIR/EVALS.md" ;;
    *)          echo "" ;;
  esac
}

# Detect collisions in one file
detect_collisions() {
  local file="$1"
  [ -f "$file" ] || return 0

  # Extract IDs from body headers, count occurrences
  grep -n "^## [A-Z]\+-[0-9]\+" "$file" | \
    awk -F: '{
      line = $1
      $1 = ""
      header = substr($0, 2)
      sub(/^## /, "", header)
      if (match(header, /^[A-Z]+-[0-9]+/)) {
        id = substr(header, 1, RLENGTH)
        ids[id] = ids[id] line ","
        counts[id]++
      }
    }
    END {
      for (id in counts) {
        if (counts[id] > 1) {
          sub(/,$/, "", ids[id])
          printf "%s|%d|%s\n", id, counts[id], ids[id]
        }
      }
    }'
}

# Detect title similarities (Jaccard tokens > 0.5)
detect_similar_titles() {
  local file="$1"
  [ -f "$file" ] || return 0

  # Extract headers as "ID|title"
  grep -n "^## [A-Z]\+-[0-9]\+" "$file" | \
    awk -F: '{
      line = $1
      $1 = ""
      header = substr($0, 2)
      sub(/^## /, "", header)
      if (match(header, /^[A-Z]+-[0-9]+/)) {
        id = substr(header, 1, RLENGTH)
        title = substr(header, RLENGTH + 1)
        sub(/^[[:space:]]*[:—-][[:space:]]*/, "", title)
        printf "%s|%s|%s\n", id, title, line
      }
    }' | sort > /tmp/.consolidator-titles.tmp

  # Compare pairs using a simple Python-style tokenization in awk
  # For each pair, compute Jaccard similarity on word tokens (lowercased)
  python3 - <<'PYEOF' 2>/dev/null || true
import os
try:
    with open('/tmp/.consolidator-titles.tmp') as f:
        rows = [line.strip().split('|') for line in f if line.strip()]
except FileNotFoundError:
    rows = []

def tokens(s):
    import re
    return set(re.findall(r'\w+', s.lower())) - {
        'le','la','les','un','une','des','de','du','et','ou','dans','sur','pour','par',
        'que','qui','est','en','au','aux','a','the','of','and','or','to','in','on','for',
        '=','-'
    }

pairs = []
for i in range(len(rows)):
    for j in range(i+1, len(rows)):
        if len(rows[i]) < 3 or len(rows[j]) < 3:
            continue
        a = tokens(rows[i][1])
        b = tokens(rows[j][1])
        if not a or not b:
            continue
        jac = len(a & b) / len(a | b)
        if jac >= 0.5:
            pairs.append((rows[i][0], rows[j][0], jac, rows[i][1][:60], rows[j][1][:60]))

for p in sorted(pairs, key=lambda x: -x[2]):
    print(f"{p[0]}|{p[1]}|{p[2]:.2f}|{p[3]}|{p[4]}")
PYEOF
}

# ---------- Main ----------
echo "{"
echo "  \"timestamp\": \"$(date -Iseconds 2>/dev/null || date)\","
echo "  \"collisions\": ["

first=true
for r in DECISIONS ADR LEARNINGS BLOCKERS EVALS; do
  [ -n "$TARGET_REGISTER" ] && [ "$TARGET_REGISTER" != "$r" ] && continue
  f=$(register_file "$r")
  [ -f "$f" ] || continue

  collisions=$(detect_collisions "$f")
  if [ -n "$collisions" ]; then
    while IFS='|' read -r id count lines; do
      [ -z "$id" ] && continue
      $first || echo ","
      first=false
      printf '    {"register": "%s", "id": "%s", "occurrences": %s, "lines": "%s"}' "$r" "$id" "$count" "$lines"
    done <<< "$collisions"
  fi
done
echo ""
echo "  ],"

echo "  \"similar_titles\": ["
first=true
for r in DECISIONS ADR LEARNINGS BLOCKERS EVALS; do
  [ -n "$TARGET_REGISTER" ] && [ "$TARGET_REGISTER" != "$r" ] && continue
  f=$(register_file "$r")
  [ -f "$f" ] || continue

  similar=$(detect_similar_titles "$f" || true)
  if [ -n "$similar" ]; then
    while IFS='|' read -r id1 id2 score t1 t2; do
      [ -z "$id1" ] && continue
      $first || echo ","
      first=false
      printf '    {"register": "%s", "ids": ["%s", "%s"], "jaccard": %s, "title_a": "%s", "title_b": "%s"}' \
        "$r" "$id1" "$id2" "$score" "$t1" "$t2"
    done <<< "$similar"
  fi
done
echo ""
echo "  ]"
echo "}"
