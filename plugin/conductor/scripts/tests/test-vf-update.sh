#!/usr/bin/env bash
# test-vf-update.sh — Tests des scripts de mise à jour du plugin (bandeau + sélection de cache).
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"   # → conductor/scripts
PASS=0; FAIL=0
ok(){ if [ "$2" = "true" ]; then echo "  ✓ $1"; PASS=$((PASS+1)); else echo "  ✗ $1"; FAIL=$((FAIL+1)); fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "== update-banner.sh =="
export XDG_CACHE_HOME="$TMP/cache"
mkdir -p "$XDG_CACHE_HOME/vibeflow"
echo '{"update_available":true,"installed":"2.4.1","latest":"2.18.0","checked_at":"x"}' > "$XDG_CACHE_HOME/vibeflow/update-check.json"
out="$(bash "$DIR/update-banner.sh" 2>/dev/null)"
ok "émet un systemMessage si update dispo"  "$(echo "$out" | grep -q 'systemMessage' && echo true || echo false)"
ok "cite installé → latest (2.4.1 → 2.18.0)" "$(echo "$out" | grep -q '2.4.1' && echo "$out" | grep -q '2.18.0' && echo true || echo false)"

echo '{"update_available":false,"installed":"2.18.0","latest":"2.18.0","checked_at":"x"}' > "$XDG_CACHE_HOME/vibeflow/update-check.json"
out="$(bash "$DIR/update-banner.sh" 2>/dev/null)"
ok "silencieux si à jour"                    "$(echo "$out" | grep -q 'systemMessage' && echo false || echo true)"

echo "== vf-update-run.sh (sélection du cache semver le plus récent) =="
FAKE="$TMP/cache-base"
for v in 2.4.1 2.18.0 2.9.0; do
  mkdir -p "$FAKE/$v/_internal"
  printf '#!/usr/bin/env bash\necho "ENGINE cache=$VIBEFLOW_CACHE"\n' > "$FAKE/$v/_internal/vibeflow-update.sh"
done
out="$(VF_CACHE_BASE="$FAKE" bash "$DIR/vf-update-run.sh" 2>&1)"
ok "sélectionne 2.18.0 (max semver, pas 2.9.0)" "$(echo "$out" | grep -q 'cache le plus récent : 2.18.0' && echo true || echo false)"

echo; echo "== Résultat : $PASS OK · $FAIL KO =="
[ "$FAIL" -eq 0 ]
