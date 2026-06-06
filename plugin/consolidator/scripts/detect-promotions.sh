#!/usr/bin/env bash
# detect-promotions.sh — Sort candidats promotion learning -> rule
#
# Criteres OR :
#   1. Operationnel : presence de mots-cles "toujours", "jamais", "eviter", "forcer", "obligatoire"
#   2. Cluster : >= 3 learnings sur meme tag/categorie sans rule
#   3. Non-encode : champ "Encode dans:" vide ou "Non encode"
#
# Output : JSON sur stdout
#
# Usage:
#   ./detect-promotions.sh
#
# Reference : ADR-032 pilier 4 (Promotion)

set -euo pipefail

MEMORY_DIR="${MEMORY_DIR:-.claude/memory}"
LEARNINGS_FILE="$MEMORY_DIR/LEARNINGS.md"
RULES_DIR="${RULES_DIR:-.claude/rules}"

[ -f "$LEARNINGS_FILE" ] || { echo "{\"error\": \"$LEARNINGS_FILE not found\"}"; exit 1; }

# ---------- Helpers ----------
# Extract LRN entries with categorie + title + "encode_status"
extract_learnings() {
  python3 - <<PYEOF 2>/dev/null
import re

with open("$LEARNINGS_FILE") as f:
    content = f.read()

# Split by "## LRN-XXX" headers
sections = re.split(r'\n(?=## LRN-\d+)', content)

entries = []
for sec in sections:
    if not sec.startswith('## LRN-'):
        continue
    id_match = re.match(r'## (LRN-\d+)', sec)
    if not id_match:
        continue
    lrn_id = id_match.group(1)

    title_match = re.match(r'## LRN-\d+\s*[:—-]\s*(.+)', sec.split('\n')[0])
    title = title_match.group(1).strip() if title_match else ''

    cat_match = re.search(r'\*\*Categorie\*\*\s*:\s*(.+)', sec)
    cat = cat_match.group(1).strip().split('|')[0].strip() if cat_match else 'Other'

    encode_match = re.search(r'\*\*Encode dans\*\*\s*:\s*(.+)', sec)
    encode_status = encode_match.group(1).strip() if encode_match else 'Non encode'
    encoded = encode_status not in ('Non encode', '[Non encode]', '', '[.claude/rules/xxx.md]')

    # Detect operational keywords in title + first lines
    body_preview = sec[:500].lower()
    keywords = ['toujours', 'jamais', 'eviter', 'forcer', 'obligatoire', 'interdire', 'prefer', 'always', 'never', 'avoid', 'must']
    operational = any(kw in body_preview for kw in keywords)

    entries.append((lrn_id, title, cat, encoded, operational))

# Operational singles (non encoded)
print("###OPERATIONAL###")
for lrn_id, title, cat, encoded, op in entries:
    if op and not encoded:
        print(f"{lrn_id}|{title[:80]}|{cat}")

# Clusters by category (>=3 non-encoded)
print("###CLUSTERS###")
from collections import defaultdict
clusters = defaultdict(list)
for lrn_id, title, cat, encoded, op in entries:
    if not encoded:
        clusters[cat].append(lrn_id)
for cat, ids in clusters.items():
    if len(ids) >= 3:
        print(f"{cat}|{','.join(ids)}")
PYEOF
}

# ---------- Main ----------
data=$(extract_learnings)

# Parse OPERATIONAL section
operational_section=$(echo "$data" | awk '/###OPERATIONAL###/{flag=1; next} /###CLUSTERS###/{flag=0} flag')
clusters_section=$(echo "$data" | awk '/###CLUSTERS###/{flag=1; next} flag')

echo "{"
echo "  \"timestamp\": \"$(date -Iseconds 2>/dev/null || date)\","
echo "  \"candidates\": ["

first=true
while IFS='|' read -r lrn_id title cat; do
  [ -z "$lrn_id" ] && continue
  $first || echo ","
  first=false
  # Generate slug from title
  slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c 1-50)
  printf '    {"type": "operational_single", "lrn_id": "%s", "title": "%s", "category": "%s", "rule_slug": "%s", "confidence": 0.85}' \
    "$lrn_id" "$title" "$cat" "$slug"
done <<< "$operational_section"

while IFS='|' read -r cat ids; do
  [ -z "$cat" ] && continue
  $first || echo ","
  first=false
  slug=$(echo "$cat" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  printf '    {"type": "frequency_cluster", "category": "%s", "lrn_ids": "%s", "rule_slug": "cluster-%s", "confidence": 0.7}' \
    "$cat" "$ids" "$slug"
done <<< "$clusters_section"

echo ""
echo "  ]"
echo "}"
