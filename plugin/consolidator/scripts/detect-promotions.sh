#!/usr/bin/env bash
# detect-promotions.sh — Sort candidats promotion learning -> rule
#
# Criteres OR :
#   1. Operationnel : presence de mots-cles "toujours", "jamais", "eviter", "forcer", "obligatoire"
#   2. Cluster : >= 3 learnings sur meme tag/categorie sans rule
#   3. Non-encode : champ "Encode dans:" vide ou "Non encode"
#
# Tri de chaque candidate (POCK-05, P414-D-10) :
#   nature      mecanique | jugement  (heuristique lexicale GROSSIERE, defaut jugement ; tri final humain)
#   proposition check | brouillon-regle  (mecanique -> check ; jugement -> brouillon de regle)
#   Indices de nature : portes par l'APPRENTISSAGE (titre + prose, jamais les metadonnees du registre)
#   et seulement des motifs de controle sans ambiguite (lint, regex, grep, console.log, frontmatter,
#   job ci, extension de script) — un mot courant (fichier, commit, chemin, import, hook) ne suffit pas.
# Findings (tableau "findings", POCK-05) : depot_sans_garde_fou — aucun workflow CI
#   (.github/workflows/*.yml|*.yaml), aucun check-*.sh (.claude/scripts/, scripts/), aucun hook declare
#   (entree non vide dans .claude/settings.json ou settings.local.json, .pre-commit-config.yaml,
#   .husky/, .githooks/) dans la RACINE du lab du registre analyse (parent de .claude/memory ; le
#   repertoire courant si MEMORY_DIR n'est pas de la forme <racine>/.claude/memory).
# Output : JSON valide sur stdout, quel que soit le contenu des titres
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
# Extract LRN entries and print one JSON candidate per line (json.dumps : un titre ne casse jamais le JSON
# ni ne decale un champ). Operational singles d'abord, puis clusters par categorie.
extract_candidates() {
  python3 - <<PYEOF 2>/dev/null
import json
import re
from collections import defaultdict

with open("$LEARNINGS_FILE") as f:
    content = f.read()

# Split by "## LRN-XXX" headers
sections = re.split(r'\n(?=## LRN-\d+)', content)

# Indices lexicaux d'un motif mecanique (heuristique : defaut jugement, tri final humain).
INDICES_MECANIQUES = ['lint', 'regex', 'grep', 'console.log', 'frontmatter', 'job ci', 'ci job']
RE_MECA = re.compile(r'\b(?:' + '|'.join(re.escape(i) for i in INDICES_MECANIQUES) + r')s?\b'
                     r'|\.(?:sh|json|ya?ml|ts|tsx|js|jsx|py|swift|go)\b')
RE_METADONNEE = re.compile(r'\s*(?:[-*]\s*)?\*\*[^*]+\*\*\s*:')

def slugify(texte, longueur):
    return re.sub(r'[^a-z0-9]+', '-', texte.lower()).strip('-')[:longueur]

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

    # Nature : indices portes par l'apprentissage (titre + prose), pas par les lignes de metadonnees
    prose = '\n'.join(l for l in sec.split('\n')[1:] if not RE_METADONNEE.match(l))[:500]
    nature = 'mecanique' if RE_MECA.search(title.lower() + ' ' + prose.lower()) else 'jugement'

    entries.append((lrn_id, title, cat, encoded, operational, nature))

def proposition_of(nature):
    return 'check' if nature == 'mecanique' else 'brouillon-regle'

candidates = []
# Operational singles (non encoded)
for lrn_id, title, cat, encoded, op, nature in entries:
    if op and not encoded:
        candidates.append({"type": "operational_single", "lrn_id": lrn_id, "title": title[:80], "category": cat,
                           "rule_slug": slugify(title[:80], 50), "nature": nature,
                           "proposition": proposition_of(nature), "confidence": 0.85})

# Clusters by category (>=3 non-encoded)
clusters = defaultdict(list)
for lrn_id, title, cat, encoded, op, nature in entries:
    if not encoded:
        clusters[cat].append((lrn_id, nature))
for cat, members in clusters.items():
    if len(members) >= 3:
        # Cluster mecanique seulement si TOUS ses membres le sont.
        cluster_nature = 'mecanique' if all(n == 'mecanique' for _, n in members) else 'jugement'
        candidates.append({"type": "frequency_cluster", "category": cat, "lrn_ids": ','.join(i for i, _ in members),
                           "rule_slug": "cluster-" + slugify(cat, 200), "nature": cluster_nature,
                           "proposition": proposition_of(cluster_nature), "confidence": 0.7})

for cand in candidates:
    print(json.dumps(cand, ensure_ascii=False))
PYEOF
}

# Racine du lab = celle du registre analyse (MEMORY_DIR = <racine>/.claude/memory), pas le cwd par defaut.
case "$MEMORY_DIR" in
  .claude/memory|.claude/memory/) LAB_ROOT="." ;;
  */.claude/memory|*/.claude/memory/) LAB_ROOT="${MEMORY_DIR%/.claude/memory*}" ;;
  *) LAB_ROOT="." ;;
esac

# ---------- Main ----------
data=$(extract_candidates)

echo "{"
echo "  \"timestamp\": \"$(date -Iseconds 2>/dev/null || date)\","
echo "  \"candidates\": ["

first=true
while IFS= read -r cand_line; do
  [ -z "$cand_line" ] && continue
  $first || echo ","
  first=false
  printf '    %s' "$cand_line"
done <<< "$data"

echo ""
echo "  ],"

# ---------- Findings (POCK-05, Q7 : MESURE) ----------
# Depot sans garde-fou : aucune des familles n'est presente dans la racine du lab du registre —
# workflow CI, script check-*.sh, hook declare (entree NON VIDE du JSON parse, jamais la simple
# chaine "hooks"), configuration pre-commit, .husky/, .githooks/.
# Globs non apparies laisses litteraux puis ecartes par [ -e ] : sans danger sous set -e.
# L'instruction sans effet (no-op) est du JUGEMENT : doctrine de references/promotion.md, jamais calculee ici.
hook_declare() {  # <settings.json> : au moins une entree de hook non vide dans le JSON parse
  [ -f "$1" ] || return 1
  python3 - "$1" <<'PYEOF' 2>/dev/null
import json
import sys

def declare(h):
    if not isinstance(h, dict):
        return False
    for v in h.values():
        if not isinstance(v, list):
            continue
        for e in v:
            if not isinstance(e, dict):
                continue
            if e.get("command"):
                return True
            sous = e.get("hooks")
            if isinstance(sous, list) and any(isinstance(x, dict) and x.get("command") for x in sous):
                return True
    return False

try:
    with open(sys.argv[1]) as fh:
        data = json.load(fh)
except Exception:
    sys.exit(1)
if isinstance(data, dict):
    if declare(data.get("hooks")):
        sys.exit(0)
sys.exit(1)
PYEOF
}
has_guard=false
for f in "$LAB_ROOT"/.github/workflows/*.yml "$LAB_ROOT"/.github/workflows/*.yaml "$LAB_ROOT"/.claude/scripts/check-*.sh "$LAB_ROOT"/scripts/check-*.sh \
         "$LAB_ROOT"/.pre-commit-config.yaml "$LAB_ROOT"/.husky/pre-commit "$LAB_ROOT"/.githooks/pre-commit; do
  if [ -e "$f" ]; then has_guard=true; break; fi
done
if ! $has_guard; then
  for f in "$LAB_ROOT"/.claude/settings.json "$LAB_ROOT"/.claude/settings.local.json; do
    if hook_declare "$f"; then has_guard=true; break; fi
  done
fi

echo "  \"findings\": ["
if ! $has_guard; then
  echo '    {"type": "depot_sans_garde_fou", "detail": "aucun workflow CI, aucun script check-*.sh, aucun hook declare"}'
fi
echo "  ]"
echo "}"
