#!/usr/bin/env bash
# framework-version.sh — Suivi de la version du framework VibeFlow installée dans un lab.
#
# C'est le socle de la propagation d'update (façon GSD) : le lab enregistre la version du framework
# avec laquelle il a été configuré ; on compare ensuite à la version courante du plugin pour détecter
# qu'il a "pris de l'avance" (structure/doctrine) et qu'une recalibration est conseillée.
#
# Sous-commandes :
#   current   → version courante du framework (depuis le plugin / cache)
#   recorded  → version enregistrée dans le lab (ou "unknown")
#   stamp     → enregistre la version courante dans le lab
#   drift     → compare recorded vs current ; advisory (jamais bloquant)
#
# Usage:
#   framework-version.sh current   [--plugin-root <dir>]
#   framework-version.sh recorded  [--lab-root <dir>]
#   framework-version.sh stamp     [--plugin-root <dir>] [--lab-root <dir>] [--version <vX.Y.Z>]
#   framework-version.sh drift     [--plugin-root <dir>] [--lab-root <dir>] [--quiet]
#
# Résolution plugin-root (cache du plugin) : --plugin-root > $CLAUDE_PLUGIN_ROOT > $VIBEFLOW_CACHE.
# lab-root défaut = "." (cwd du lab). Le fichier d'enregistrement : <lab-root>/.claude/.vibeflow-framework-version
#
# Fallback lab (UAT F3) : sans plugin-root (CLAUDE_PLUGIN_ROOT/VIBEFLOW_CACHE vides — cas normal
# d'un `bash .claude/scripts/framework-version.sh stamp` depuis un lab), la version courante se lit
# dans le registre posé par l'engine : <lab-root>/.claude/scripts/.vibeflow-installed
# (une ligne `module=version` par module) — ligne du socle `conductor` (mandatory, c'est lui qui
# livre ce script). Les DEUX côtés du drift (current et recorded) résolvent par la même cascade :
# la comparaison reste cohérente. `stamp` ne sort donc plus en erreur dans un lab installé.
#
# Exit codes (drift) : 0 = à jour OU inconnu (advisory)  1 = retard détecté (recalibration conseillée)
set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${VIBEFLOW_CACHE:-}}"
LAB_ROOT="."
FORCE_VERSION=""
QUIET=0

cmd="${1:-}"; shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --plugin-root) PLUGIN_ROOT="${2:?}"; shift 2 ;;
    --lab-root) LAB_ROOT="${2:?}"; shift 2 ;;
    --version) FORCE_VERSION="${2:?}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    *) echo "[framework-version] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[framework-version] $*"; }
record_file() { echo "$LAB_ROOT/.claude/.vibeflow-framework-version"; }

# Normalise "v2.6.0" / "2.6.0" → "2.6.0". Retire aussi tout \r résiduel : le jq Windows natif
# écrit en mode texte (\n → \r\n) et `$()` ne retire que le \n final — sans ce strip, la
# comparaison `[ "$cur" = "$rec" ]` du drift serait structurellement fausse sous Git Bash (ADR-054).
norm() { local s="${1#v}"; printf '%s\n' "${s//$'\r'/}"; }

# jqx — wrapper jq (ADR-054) : neutralise le CRLF du jq Windows natif au plus près de la source
# (norm() strip aussi : ceinture, couvre les fallbacks VERSION lus par head -1).
jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )

current_version() {
  [ -n "$FORCE_VERSION" ] && { norm "$FORCE_VERSION"; return; }
  local pj="$PLUGIN_ROOT/.claude-plugin/plugin.json"
  if [ -n "$PLUGIN_ROOT" ] && [ -f "$pj" ] && command -v jq >/dev/null 2>&1; then
    norm "$(jqx -r '.version // empty' "$pj")"; return
  fi
  # Fallbacks : VERSION à la racine du plugin, puis du repo.
  for f in "$PLUGIN_ROOT/VERSION" "$PLUGIN_ROOT/../VERSION"; do
    [ -f "$f" ] && { norm "$(head -1 "$f")"; return; }
  done
  # Fallback lab (UAT F3) : registre d'install de l'engine (module=version par ligne).
  # La version du socle `conductor` sert de version de méthode quand le cache plugin est
  # hors de portée — même cascade des deux côtés du drift, comparaison cohérente.
  local reg="$LAB_ROOT/.claude/scripts/.vibeflow-installed" line
  if [ -f "$reg" ]; then
    line="$(grep -E '^conductor=' "$reg" 2>/dev/null | head -1)"
    [ -n "$line" ] && { norm "${line#conductor=}"; return; }
  fi
  echo ""
}

recorded_version() {
  local rf; rf="$(record_file)"
  [ -f "$rf" ] && norm "$(head -1 "$rf")" || echo ""
}

# Retourne 0 si $1 < $2 (strictement), via tri sémver portable.
semver_lt() {
  [ "$1" = "$2" ] && return 1
  local first
  first="$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)"
  [ "$first" = "$1" ]
}

case "$cmd" in
  current)
    v="$(current_version)"; [ -n "$v" ] && echo "$v" || { say "version courante introuvable (plugin-root=$PLUGIN_ROOT)"; exit 1; } ;;
  recorded)
    v="$(recorded_version)"; echo "${v:-unknown}" ;;
  stamp)
    v="$(current_version)"; [ -n "$v" ] || { say "impossible de déterminer la version courante à enregistrer"; exit 1; }
    mkdir -p "$LAB_ROOT/.claude"; echo "$v" > "$(record_file)"
    say "version framework enregistrée : $v → $(record_file)" ;;
  drift)
    cur="$(current_version)"; rec="$(recorded_version)"
    if [ -z "$cur" ]; then say "version courante inconnue — drift indéterminé."; exit 0; fi
    if [ -z "$rec" ]; then say "lab non stampé (version framework inconnue). Lancer: framework-version.sh stamp"; exit 0; fi
    if [ "$cur" = "$rec" ]; then say "à jour (framework $cur)."; exit 0; fi
    if semver_lt "$rec" "$cur"; then
      say "RETARD : lab en $rec, framework en $cur → recalibration conseillée (/vf-calibrate)."; exit 1
    else
      say "lab ($rec) en avance sur le plugin ($cur) — rien à faire."; exit 0
    fi ;;
  ""|-h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  *) echo "[framework-version] sous-commande inconnue : $cmd" >&2; exit 64 ;;
esac
