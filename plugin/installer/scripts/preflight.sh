#!/usr/bin/env bash
# preflight.sh — Vérification des prérequis système AVANT toute install VibeFlow (ADR-054).
#
# Contrôles :
#   1. bash (version, informatif) et git (dur)
#   2. jq (DUR — requis par build-module-catalog.sh et resolve-deps.sh) + sonde CRLF informative
#   3. python3 utilisable (DUR si aucun interpréteur — requis par merge-hooks.sh pour câbler les
#      hooks de gouvernance). Piège Windows : le stub Microsoft Store `python3.exe` EXISTE dans le
#      PATH (`command -v` réussit) mais PEND ou échoue à l'exécution (App Execution Alias) ; et
#      l'installeur python.org ne fournit PAS de `python3.exe` (seulement `python.exe` + `py`).
#      → sonde d'EXÉCUTION réelle, gardée par `timeout` sous Windows (présent dans Git Bash ;
#        absent de macOS où le stub n'existe pas → sonde simple).
#
# Sortie : une ligne [preflight] par contrôle.
# Exit codes : 0 = environnement OK (avertissements possibles) · 1 = prérequis dur manquant.
set -uo pipefail

FAIL=0
say()  { echo "[preflight] $*"; }
ok()   { echo "[preflight] ✓ $*"; }
warn() { echo "[preflight] ⚠ $*"; }
ko()   { echo "[preflight] ✗ $*" >&2; FAIL=1; }

case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=1 ;;
  *)                    IS_WINDOWS=0 ;;
esac

# ── 1. bash + git ───────────────────────────────────────────────────────────────────────────────
ok "bash $BASH_VERSION"
if command -v git >/dev/null 2>&1; then
  ok "git $(git --version 2>/dev/null | head -1 | sed 's/^git version //' | tr -d '\r')"
else
  ko "git introuvable — requis (Claude Code sous Windows requiert Git for Windows)."
fi

# ── 2. jq — prérequis DUR de l'engine (parse des module.json) ───────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  ver="$(jq --version 2>/dev/null | tr -d '\r')"
  # Sonde CRLF : le jq Windows natif écrit en mode texte (\n → \r\n). L'engine normalise
  # désormais toutes ses captures (wrapper jqx, ADR-054) → informatif, plus bloquant.
  if printf '{}' | jq -c . 2>/dev/null | LC_ALL=C grep -q "$(printf '\r')"; then
    ok "jq ${ver:-?} (sorties CRLF détectées — normalisées automatiquement par l'engine)"
  else
    ok "jq ${ver:-?}"
  fi
else
  ko "jq introuvable — REQUIS. Installer : macOS 'brew install jq' (natif depuis macOS 15) · Windows (Git Bash) 'winget install jqlang.jq' · Debian/Ubuntu 'sudo apt-get install jq'"
fi

# ── 3. python3 utilisable — câblage des hooks de gouvernance (merge-hooks.sh) ───────────────────
# Sonde un candidat : présent dans le PATH, pas le stub WindowsApps, s'exécute réellement ET est
# un Python 3 (un python2 passerait `-c ''` mais casserait les f-strings de merge-hooks).
PY3_PROBE='import sys; sys.exit(0 if sys.version_info[0]>=3 else 1)'
py_probe() {
  local cand="$1" resolved
  command -v "$cand" >/dev/null 2>&1 || return 1
  if [ "$IS_WINDOWS" -eq 1 ]; then
    resolved="$(command -v "$cand" 2>/dev/null)"
    case "$resolved" in *WindowsApps*) return 1 ;; esac   # stub Store : peut pendre en non-TTY
    if command -v timeout >/dev/null 2>&1; then
      timeout 5 "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || return 1
    else
      "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || return 1
    fi
  else
    "$cand" -c "$PY3_PROBE" >/dev/null 2>&1 || return 1
  fi
  return 0
}
py_version() { "$1" -c 'import sys;print(".".join(map(str,sys.version_info[:3])))' 2>/dev/null | tr -d '\r'; }

if py_probe python3; then
  ok "python3 $(py_version python3)"
elif py_probe python; then
  warn "python3 indisponible mais python $(py_version python) utilisable — l'install s'adapte (merge-hooks), MAIS les hooks de gouvernance runtime invoquent 'python3' (fail-open : protections inactives tant que python3 n'est pas exposé dans le PATH de Git Bash)."
elif [ "$IS_WINDOWS" -eq 1 ] && command -v py >/dev/null 2>&1 && py -3 -c '' >/dev/null 2>&1; then
  # KO et pas warn : l'engine invoque `python3`/`python`, jamais `py` — l'install perdrait ses
  # hooks de gouvernance en silence (cause n°5 de l'ADR-054).
  ko "Python présent uniquement via le lanceur 'py' — INSUFFISANT : l'engine invoque 'python3'/'python'. Réinstaller depuis python.org en cochant « Add to PATH » (ou exposer python.exe dans le PATH de Git Bash)."
else
  ko "python3 introuvable ou inutilisable — REQUIS (câblage des hooks de gouvernance). Windows : installer depuis python.org en cochant « Add to PATH » (le stub Microsoft Store 'python3' du PATH n'est PAS un vrai interpréteur)."
fi

# ── Verdict ─────────────────────────────────────────────────────────────────────────────────────
if [ "$FAIL" -eq 1 ]; then
  say "prérequis manquants — corriger ci-dessus PUIS relancer /vibeflow-install."
  exit 1
fi
say "environnement OK."
exit 0
