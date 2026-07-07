#!/usr/bin/env bash
# update-banner.sh — Hook SessionStart : signale (bandeau) qu'une mise à jour vibeflow est dispo.
#
# Lit le cache écrit par check-plugin-update.sh (session PRÉCÉDENTE → lecture instantanée, ne bloque
# jamais le démarrage) puis relance la vérification en tâche de fond pour la prochaine session.
# Émet un JSON { "systemMessage": ... } si une mise à jour est dispo — sinon rien. Toujours exit 0.
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/update-check.json"

# 1) Bandeau depuis le cache existant (n'attend aucun réseau).
if [ -f "$CACHE_FILE" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$CACHE_FILE" <<'PY' 2>/dev/null || true
import json, sys
try:
    c = json.load(open(sys.argv[1]))
    if c.get("update_available"):
        i, l = c.get("installed", "?"), c.get("latest", "?")
        print(json.dumps({
            "systemMessage": f"VibeFlow : mise à jour disponible {i} → {l}. Lance /vf-update pour mettre à jour le plugin et les modules installés."
        }, ensure_ascii=False))
except Exception:
    pass
PY
fi

# 2) Rafraîchit le cache en arrière-plan (n'affecte que la prochaine session ; détaché, silencieux).
if [ -x "$DIR/check-plugin-update.sh" ]; then
  ( setsid "$DIR/check-plugin-update.sh" >/dev/null 2>&1 & ) 2>/dev/null \
    || ( "$DIR/check-plugin-update.sh" >/dev/null 2>&1 & )
fi
exit 0
