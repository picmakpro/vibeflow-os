#!/usr/bin/env bash
# check-plugin-update.sh — Détecte si une nouvelle version du plugin vibeflow est publiée.
#
# Compare la version INSTALLÉE (claude plugin) au DERNIER TAG GitHub (source de vérité depuis la
# discipline de tags, cf. CLAUDE.md) et écrit un cache lu par le bandeau SessionStart.
# Best-effort : silencieux, jamais bloquant, tolère l'absence de réseau (garde l'ancien cache).
#
# Cache : ${XDG_CACHE_HOME:-~/.cache}/vibeflow/update-check.json
#   { "update_available": bool, "installed": "x.y.z", "latest": "x.y.z", "checked_at": "ISO" }
#
# Usage :
#   check-plugin-update.sh            # met à jour le cache, silencieux
#   check-plugin-update.sh --print    # met à jour le cache ET imprime le JSON sur stdout
set -uo pipefail

REPO_URL="${VF_REPO_URL:-https://github.com/picmakpro/vibeflow-os}"
PLUGIN_ID="${VF_PLUGIN_ID:-vibeflow@vibeflow-os}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow"
CACHE_FILE="$CACHE_DIR/update-check.json"

# --- Version installée : installed_plugins.json (structuré), fallback `claude plugin list` ---
installed=""
IP="$HOME/.claude/plugins/installed_plugins.json"
if [ -f "$IP" ] && command -v python3 >/dev/null 2>&1; then
  installed="$(python3 - "$IP" "$PLUGIN_ID" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    entries = d.get("plugins", {}).get(sys.argv[2], [])
    vers = [e.get("version") for e in entries if e.get("version") and e.get("version") != "unknown"]
    print(sorted(vers, key=lambda s: [int(x) for x in s.lstrip("v").split(".") if x.isdigit()])[-1] if vers else "")
except Exception:
    print("")
PY
)"
fi
if [ -z "$installed" ] && command -v claude >/dev/null 2>&1; then
  installed="$(claude plugin list 2>/dev/null | awk '/vibeflow@vibeflow-os/{f=1} f&&/Version:/{print $2; exit}')"
fi
installed="${installed#v}"

# --- Dernière version publiée : le plus grand tag vX.Y.Z du dépôt (ls-remote, sans clone) ---
latest="$(git ls-remote --tags --refs "$REPO_URL" 2>/dev/null \
  | awk -F/ '{print $NF}' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)"
latest="${latest#v}"

# Réseau KO / détection impossible : on NE réécrit PAS le cache (garde l'état précédent).
if [ -z "$latest" ]; then
  [ "${1:-}" = "--print" ] && [ -f "$CACHE_FILE" ] && cat "$CACHE_FILE"
  exit 0
fi

# --- Comparaison semver : vrai si $1 > $2 ---
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }

update_available=false
if [ -n "$installed" ] && newer "$latest" "$installed"; then
  update_available=true
fi

checked_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
json="{\"update_available\":$update_available,\"installed\":\"${installed:-unknown}\",\"latest\":\"$latest\",\"checked_at\":\"$checked_at\"}"
mkdir -p "$CACHE_DIR" 2>/dev/null || true
printf '%s\n' "$json" > "$CACHE_FILE" 2>/dev/null || true
[ "${1:-}" = "--print" ] && printf '%s\n' "$json"
exit 0
