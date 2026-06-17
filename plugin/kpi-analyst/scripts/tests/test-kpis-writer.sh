#!/usr/bin/env bash
# test-kpis-writer.sh — Tests du contrat de l'assembleur déterministe kpis-writer.sh.
# Couvre : schéma → index + payload, extracteurs valides agrégés, garde-fou "pas de source → low",
# extracteur invalide ignoré, et IDEMPOTENCE (2 runs = même payload hors generatedAt).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WRITER="$HERE/../kpis-writer.sh"
PASS=0 FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
nok()  { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/.claude/kpi/extractors" "$TMP/.claude/memory"

# Schéma validé (stable keys)
cat > "$TMP/.claude/kpi/schema.json" <<'JSON'
{
  "domain": "business",
  "kpis": [
    { "key": "ca_realise", "label": "CA réalisé", "unit": "€", "target": 50000, "domain": "business", "sortOrder": 0 },
    { "key": "leads_actifs", "label": "Leads actifs", "unit": "nb", "domain": "business", "sortOrder": 1 },
    { "key": "abonnes_ig", "label": "Abonnés IG", "unit": "nb", "domain": "business", "sortOrder": 2 }
  ]
}
JSON

# Extracteur 1 — valeur déterministe sourcée (high)
cat > "$TMP/.claude/kpi/extractors/ca_realise.sh" <<'SH'
#!/usr/bin/env bash
jq -nc '{key:"ca_realise", value:42000, source:"business/pipeline/clients/", confidence:"high"}'
SH

# Extracteur 2 — sans source explicite → le writer doit forcer confidence "low"
cat > "$TMP/.claude/kpi/extractors/leads_actifs.sh" <<'SH'
#!/usr/bin/env bash
jq -nc '{key:"leads_actifs", value:12}'
SH

# Extracteur 3 — sortie invalide (pas de key) → doit être ignoré sans crash
cat > "$TMP/.claude/kpi/extractors/casse.sh" <<'SH'
#!/usr/bin/env bash
echo '{"value":999}'
SH
chmod +x "$TMP/.claude/kpi/extractors/"*.sh

OUT="$TMP/.claude/memory/KPIS.md"
( cd "$TMP" && bash "$WRITER" --lab demo --schema .claude/kpi/schema.json \
    --extractors .claude/kpi/extractors --out .claude/memory/KPIS.md ) >/dev/null 2>&1 \
  || { nok "exécution writer (rc=0)"; echo "RÉSULTAT: $PASS ok / $FAIL ko"; exit 1; }
ok "exécution writer (rc=0)"

[ -f "$OUT" ] && ok "KPIS.md créé" || nok "KPIS.md créé"

# Extraire le bloc JSON (entre les fences ```json ... ```)
PAYLOAD=$(awk '/^```json$/{f=1;next} /^```$/{f=0} f' "$OUT")
echo "$PAYLOAD" | jq empty 2>/dev/null && ok "bloc JSON valide" || nok "bloc JSON valide"

# Schéma : 3 KPIs, clés stables présentes
[ "$(echo "$PAYLOAD" | jq '.schema | length')" = "3" ] && ok "schéma = 3 KPIs" || nok "schéma = 3 KPIs"

# Valeurs : 2 valides agrégées (l'extracteur cassé est ignoré)
[ "$(echo "$PAYLOAD" | jq '.values | length')" = "2" ] && ok "2 valeurs (cassé ignoré)" || nok "2 valeurs (cassé ignoré)"

# Valeur high sourcée
v=$(echo "$PAYLOAD" | jq -r '.values[] | select(.key=="ca_realise") | "\(.value)|\(.confidence)"')
[ "$v" = "42000|high" ] && ok "ca_realise = 42000 / high" || nok "ca_realise = 42000 / high (got $v)"

# Garde-fou : valeur sans source → confidence forcée à low
c=$(echo "$PAYLOAD" | jq -r '.values[] | select(.key=="leads_actifs") | .confidence')
[ "$c" = "low" ] && ok "garde-fou: sans source → low" || nok "garde-fou: sans source → low (got $c)"

# Index human-readable présent
grep -q "## Index" "$OUT" && ok "index présent" || nok "index présent"

# Idempotence : 2e run → payload identique hors generatedAt
( cd "$TMP" && bash "$WRITER" --lab demo --schema .claude/kpi/schema.json \
    --extractors .claude/kpi/extractors --out "$TMP/KPIS2.md" ) >/dev/null 2>&1
P2=$(awk '/^```json$/{f=1;next} /^```$/{f=0} f' "$TMP/KPIS2.md")
A=$(echo "$PAYLOAD" | jq 'del(.generatedAt)')
B=$(echo "$P2" | jq 'del(.generatedAt)')
[ "$A" = "$B" ] && ok "idempotence (payload stable)" || nok "idempotence (payload stable)"

echo
echo "RÉSULTAT: $PASS ok / $FAIL ko"
[ "$FAIL" -eq 0 ]
