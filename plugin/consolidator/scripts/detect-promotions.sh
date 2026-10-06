#!/usr/bin/env bash
# detect-promotions.sh — Sort candidats promotion learning -> rule
#
# Criteres OR :
#   1. Operationnel : presence de mots-cles "toujours", "jamais", "eviter", "forcer", "obligatoire"
#   2. Cluster : >= 3 learnings sur meme tag/categorie sans rule
#   3. Non-encode : champ "Encode dans:" vide ou "Non encode"
#
# Tri de chaque candidate (POCK-05, P414-D-10) :
#   nature      mecanique | jugement  (heuristique lexicale, defaut jugement ; tri final humain)
#   proposition check | brouillon-regle  (mecanique -> check ; jugement -> brouillon de regle)
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

# Indices lexicaux d'un motif mecanique (heuristique : defaut jugement, tri final humain).
INDICES_MECANIQUES = ['lint', 'hook', 'regex', 'grep', 'commit', 'chemin', 'fichier',
                      'import', 'console.log', 'frontmatter', 'job ci']
RE_MECA = re.compile(r'\b(?:' + '|'.join(re.escape(i) for i in INDICES_MECANIQUES) + r')s?\b'
                     r'|\.(?:sh|md|json|ya?ml|ts|tsx|js|jsx|py|swift|go)\b')

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

    nature = 'mecanique' if RE_MECA.search(title.lower() + ' ' + body_preview) else 'jugement'

    entries.append((lrn_id, title, cat, encoded, operational, nature))

# Operational singles (non encoded)
print("###OPERATIONAL###")
for lrn_id, title, cat, encoded, op, nature in entries:
    if op and not encoded:
        print(f"{lrn_id}|{title[:80]}|{cat}|{nature}")

# Clusters by category (>=3 non-encoded)
print("###CLUSTERS###")
from collections import defaultdict
clusters = defaultdict(list)
for lrn_id, title, cat, encoded, op, nature in entries:
    if not encoded:
        clusters[cat].append((lrn_id, nature))
for cat, members in clusters.items():
    if len(members) >= 3:
        # Cluster mecanique seulement si TOUS ses membres le sont.
        cluster_nature = 'mecanique' if all(n == 'mecanique' for _, n in members) else 'jugement'
        print(f"{cat}|{','.join(i for i, _ in members)}|{cluster_nature}")
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
# Proposition derivee de la nature (enumeration fermee : mecanique -> check, sinon brouillon-regle)
proposition_of() {
  case "$1" in
    mecanique) echo "check" ;;
    *) echo "brouillon-regle" ;;
  esac
}

while IFS='|' read -r lrn_id title cat nature; do
  [ -z "$lrn_id" ] && continue
  $first || echo ","
  first=false
  [ "$nature" = "mecanique" ] || nature="jugement"
  proposition=$(proposition_of "$nature")
  # Generate slug from title
  slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c 1-50)
  printf '    {"type": "operational_single", "lrn_id": "%s", "title": "%s", "category": "%s", "rule_slug": "%s", "nature": "%s", "proposition": "%s", "confidence": 0.85}' \
    "$lrn_id" "$title" "$cat" "$slug" "$nature" "$proposition"
done <<< "$operational_section"

while IFS='|' read -r cat ids nature; do
  [ -z "$cat" ] && continue
  $first || echo ","
  first=false
  [ "$nature" = "mecanique" ] || nature="jugement"
  proposition=$(proposition_of "$nature")
  slug=$(echo "$cat" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  printf '    {"type": "frequency_cluster", "category": "%s", "lrn_ids": "%s", "rule_slug": "cluster-%s", "nature": "%s", "proposition": "%s", "confidence": 0.7}' \
    "$cat" "$ids" "$slug" "$nature" "$proposition"
done <<< "$clusters_section"

echo ""
echo "  ]"
echo "}"
