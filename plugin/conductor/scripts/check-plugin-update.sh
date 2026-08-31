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

# --- Verrou : une seule vérification à la fois (update-banner peut relancer vite) ---
mkdir -p "$CACHE_DIR" 2>/dev/null || exit 0
LOCK_DIR="$CACHE_DIR/.check.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # Verrou occupé : casser s'il est périmé (> 300s — process tué), sinon céder la place.
  lock_m=$(stat -c %Y "$LOCK_DIR" 2>/dev/null || stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0)
  case "$lock_m" in ''|*[!0-9]*) lock_m=0 ;; esac
  now=$(date +%s 2>/dev/null || echo 0)
  if [ "$now" -gt 0 ] && [ $((now - lock_m)) -gt 300 ]; then
    rmdir "$LOCK_DIR" 2>/dev/null || true
    mkdir "$LOCK_DIR" 2>/dev/null || exit 0
  else
    exit 0
  fi
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT INT TERM

# --- Version installée : installed_plugins.json (structuré), fallback `claude plugin list` ---
installed=""
IP="$HOME/.claude/plugins/installed_plugins.json"
# ADR-054 : stub Microsoft Store — `python3` présent dans le PATH mais inerte. Détection par
# CHEMIN (zéro spawn), repli `python` ; sinon fallback `claude plugin list` ci-dessous.
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) command -v python >/dev/null 2>&1 && PYBIN=python || PYBIN="" ;;
esac
if [ -f "$IP" ] && [ -n "$PYBIN" ]; then
  installed="$("$PYBIN" - "$IP" "$PLUGIN_ID" <<'PY' 2>/dev/null
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
# Résolution runtime-aware (RUNT-01) : cascade EXACTE de find_hooks_merger()
# (plugin/_internal/vibeflow-update.sh) — introuvable aux deux positions → repli `claude`-figé
# ACTUEL (jamais une régression silencieuse). Best-effort : un dispatch en échec laisse
# `installed=""`, la comparaison de version est simplement sautée plus bas.
find_runtime_cli_dispatch() {
  local c
  c="${VIBEFLOW_CACHE:-.vibeflow-cache}/_internal/runtime-cli-dispatch.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/runtime-cli-dispatch.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}
if [ -z "$installed" ]; then
  RUNTIME_CLI_DISPATCH="$(find_runtime_cli_dispatch)"
  if [ -n "$RUNTIME_CLI_DISPATCH" ]; then
    installed="$(bash "$RUNTIME_CLI_DISPATCH" list-text 2>/dev/null | awk '/vibeflow@vibeflow-os/{f=1} f&&/Version:/{print $2; exit}')"
  elif command -v claude >/dev/null 2>&1; then
    installed="$(claude plugin list 2>/dev/null | awk '/vibeflow@vibeflow-os/{f=1} f&&/Version:/{print $2; exit}')"
  fi
fi
installed="${installed%$'\r'}"   # ADR-054 : python/claude natifs Windows émettent du CRLF ; un CR brut casserait le JSON du cache
installed="${installed#v}"

# --- Dernière version publiée : le plus grand tag vX.Y.Z du dépôt (ls-remote, sans clone) ---
# GIT_TERMINAL_PROMPT=0 : repo privé sans credential helper → échec propre au lieu d'un
# prompt qui pendrait en tâche de fond. lowSpeed* : borne un réseau qui rampe (TCP connect
# vers une IP non routable peut tenir > 1 min sans ça).
latest="$(GIT_TERMINAL_PROMPT=0 git -c http.lowSpeedLimit=1 -c http.lowSpeedTime=10 \
    ls-remote --tags --refs "$REPO_URL" 2>/dev/null \
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
# Écriture atomique : jamais de cache à moitié écrit (lu par le bandeau de la session suivante).
{ printf '%s\n' "$json" > "$CACHE_FILE.tmp.$$" && mv -f "$CACHE_FILE.tmp.$$" "$CACHE_FILE"; } 2>/dev/null \
  || rm -f "$CACHE_FILE.tmp.$$" 2>/dev/null || true
[ "${1:-}" = "--print" ] && printf '%s\n' "$json"
exit 0
