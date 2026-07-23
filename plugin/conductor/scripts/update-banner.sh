#!/usr/bin/env bash
# update-banner.sh — Hook SessionStart : signale (bandeau) qu'une action VibeFlow est dispo.
#
# Deux signaux fusionnés en UN seul systemMessage (jamais deux JSON) :
#   1. Mise à jour du PLUGIN — lit le cache écrit par check-plugin-update.sh (session précédente →
#      lecture instantanée, ne bloque jamais le démarrage).
#   2. Méthode LEGACY — check-legacy.sh (scope-aware, instantané, sans réseau) : un lab déjà à la
#      bonne version de plugin peut avoir des modules non migrés (pré ADR-052/053). Nudge /vf-update.
# Émet le JSON seulement s'il y a quelque chose à dire — sinon rien. Toujours exit 0.
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/update-check.json"

# Signal 2 (synchrone, négligeable : lit un registre + stat quelques fichiers).
LEGACY_JSON=""
[ -x "$DIR/check-legacy.sh" ] && LEGACY_JSON="$(bash "$DIR/check-legacy.sh" --print 2>/dev/null || true)"

# ADR-054 : stub Microsoft Store — `python3` présent dans le PATH mais inerte. Détection par
# CHEMIN (zéro spawn), repli `python` ; sinon pas de bandeau (advisory).
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) command -v python >/dev/null 2>&1 && PYBIN=python || PYBIN="" ;;
esac
if [ -n "$PYBIN" ]; then
  CACHE_FILE="$CACHE_FILE" LEGACY_JSON="$LEGACY_JSON" "$PYBIN" <<'PY' 2>/dev/null || true
import json, os
msgs = []
# 1) mise à jour du plugin (depuis le cache)
try:
    cf = os.environ.get("CACHE_FILE", "")
    if cf and os.path.isfile(cf):
        c = json.load(open(cf))
        if c.get("update_available"):
            msgs.append(f"mise à jour disponible {c.get('installed','?')} → {c.get('latest','?')}")
except Exception:
    pass
# 2) méthode legacy / drift d'artefacts (scope-aware)
try:
    lj = os.environ.get("LEGACY_JSON", "")
    if lj:
        d = json.loads(lj)
        if d.get("verdict") == "action-needed":
            mods = sorted({m["module"] for s in d.get("scopes", [])
                           for m in s["modules"] if m["status"] != "current"})
            msgs.append("nouvelle méthode disponible (" + ", ".join(mods) + ")")
except Exception:
    pass
if msgs:
    print(json.dumps({"systemMessage": "VibeFlow : " + " ; ".join(msgs)
                      + ". Lance /vf-update pour mettre à jour le plugin et les modules installés."},
                     ensure_ascii=False))
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
