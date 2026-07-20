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
# ⚠ setsid n'existe pas sur macOS, et son échec en arrière-plan est ASYNCHRONE : l'ancien
# pattern `( setsid … & ) || fallback` sortait toujours 0 → le fallback ne se déclenchait
# jamais → cache jamais rafraîchi sur macOS (bandeau mort, démontré). On teste la présence
# de setsid AVANT, et on ferme stdin (un git qui tenterait un prompt échoue au lieu de pendre).
if [ -x "$DIR/check-plugin-update.sh" ]; then
  if command -v setsid >/dev/null 2>&1; then
    ( setsid "$DIR/check-plugin-update.sh" </dev/null >/dev/null 2>&1 & ) 2>/dev/null || true
  else
    ( "$DIR/check-plugin-update.sh" </dev/null >/dev/null 2>&1 & ) 2>/dev/null || true
  fi
fi
exit 0
