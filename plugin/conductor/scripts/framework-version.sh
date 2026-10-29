#!/usr/bin/env bash
# framework-version.sh — Suivi de la version du framework VibeFlow installée dans un lab.
#
# Suit la version du framework avec laquelle un lab a été configuré, et dit deux choses distinctes
# (sous-commande `drift`, chacune sur une échelle cohérente) :
#   (A) RETARD DE MISE À JOUR — chaque module du registre du lab (<lab-root>/.claude/scripts/
#       .vibeflow-installed, une ligne `module=version`) est comparé à <cache>/<module>/VERSION, le
#       cache du plugin. Un lab dont les modules ont du retard sur le cache → /vf-update. (#167)
#       Cache introuvable → « indéterminé », jamais « à jour » ; module absent du cache → ignoré.
#   (B) RETARD DE CALIBRATION — la version stampée (.claude/.vibeflow-framework-version) est comparée
#       à la version courante : celle de `conductor=` du registre quand il existe (échelle module,
#       celle où `stamp` écrit en lab) si son majeur est celui du stamp ; sinon `plugin.json` du cache
#       (un stamp posé sous --plugin-root est sur l'échelle plugin) si son majeur est celui du stamp ;
#       sinon « échelle indéterminée », rc 0. Retard → /vf-calibrate. LIMITE : cette discrimination
#       par majeur tient tant que le plugin (2.x) et conductor (1.x) n'ont pas le même majeur.
#
# Sous-commandes :
#   current   → version courante du framework (plugin / cache, sinon registre du lab)
#   recorded  → version enregistrée dans le lab (ou "unknown")
#   stamp     → enregistre la version courante dans le lab
#   drift     → constats (A) et (B) ; advisory (jamais bloquant). rc 1 si l'un des deux constate un retard
#
# Usage:
#   framework-version.sh current   [--plugin-root <dir>]
#   framework-version.sh recorded  [--lab-root <dir>]
#   framework-version.sh stamp     [--plugin-root <dir>] [--lab-root <dir>] [--version <vX.Y.Z>]
#   framework-version.sh drift     [--plugin-root <dir>] [--lab-root <dir>] [--quiet]
#
# Cache du plugin pour (A) : --plugin-root > $CLAUDE_PLUGIN_ROOT > $VIBEFLOW_CACHE (racine de plugin,
# lue telle quelle) > $VF_PLUGIN_CACHE (défaut $HOME/.claude/plugins/cache/vibeflow-os/vibeflow, dont on
# prend le DERNIER sous-répertoire semver, tri numérique : 2.10.0 > 2.9.0 ; noms non semver ignorés).
# lab-root défaut = "." (cwd du lab). Le fichier d'enregistrement : <lab-root>/.claude/.vibeflow-framework-version
#
# Fallback lab (UAT F3) : sans plugin-root (cas normal d'un `bash .claude/scripts/framework-version.sh
# stamp` depuis un lab), `current` et `stamp` lisent la ligne `conductor=` du registre du lab. Ce repli
# sert au stamp ; il ne dit RIEN du retard sur le cache — c'est le rôle de (A).
#
# Exit codes (drift) : 0 = à jour OU indéterminé (advisory)  1 = retard détecté (mise à jour ou recalibration)
set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${VIBEFLOW_CACHE:-}}"
# Sans HOME, pas de cache par défaut (jamais d'erreur sous set -u).
VF_PLUGIN_CACHE="${VF_PLUGIN_CACHE:-${HOME:+$HOME/.claude/plugins/cache/vibeflow-os/vibeflow}}"
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

# Racine du cache du plugin pour (A) : plugin-root explicite/env, sinon dernier sous-répertoire semver
# de $VF_PLUGIN_CACHE. Rend "" si introuvable.
cache_root() {
  [ -n "$PLUGIN_ROOT" ] && { [ -d "$PLUGIN_ROOT" ] && echo "$PLUGIN_ROOT"; return 0; }
  [ -n "$VF_PLUGIN_CACHE" ] && [ -d "$VF_PLUGIN_CACHE" ] || return 0
  local d n best=""
  for d in "$VF_PLUGIN_CACHE"/*/; do
    [ -d "$d" ] || continue
    n="$(basename "$d")"
    printf '%s' "$n" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || continue
    if [ -z "$best" ] || semver_lt "$best" "$n"; then best="$n"; fi
  done
  [ -n "$best" ] && echo "$VF_PLUGIN_CACHE/$best"
  return 0
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
    reg="$LAB_ROOT/.claude/scripts/.vibeflow-installed"; rec="$(recorded_version)"
    retard=0; a_state=none; b_state=none

    # (A) retard de mise à jour : registre du lab vs cache du plugin.
    if [ -f "$reg" ]; then
      croot="$(cache_root)"
      if [ -n "$croot" ] && [ -f "$croot/conductor/VERSION" ]; then
        a_state=ok; late=""; first=""
        while IFS= read -r line || [ -n "$line" ]; do
          line="${line//$'\r'/}"
          case "$line" in ''|'#'*|*=*) ;; *) continue ;; esac
          [ -n "$line" ] || continue
          mod="${line%%=*}"; lv="$(norm "${line#*=}")"
          [ -f "$croot/$mod/VERSION" ] || continue
          cv="$(norm "$(head -1 "$croot/$mod/VERSION")")"
          [ -n "$lv" ] && [ -n "$cv" ] || continue
          if semver_lt "$lv" "$cv"; then
            a_state=retard
            if [ "$mod" = "conductor" ]; then first="conductor $lv → $cv"; else late="$late, $mod $lv → $cv"; fi
          fi
        done < "$reg"
        if [ "$a_state" = retard ]; then
          pv="?"; pj="$croot/.claude-plugin/plugin.json"
          [ -f "$pj" ] && command -v jq >/dev/null 2>&1 && pv="$(norm "$(jqx -r '.version // empty' "$pj")")"
          [ -n "$pv" ] || pv="?"
          detail="$first$late"; detail="${detail#, }"
          say "RETARD (plugin $pv) : $detail → mise à jour conseillée (/vf-update)."; retard=1
        fi
      else
        a_state=indet
      fi
    fi

    # (B) retard de calibration : le stamp est comparé à une référence de MÊME échelle (majeur).
    #   registre conductor= (échelle module) si son majeur = celui du stamp ; sinon plugin.json du cache
    #   résolu (échelle plugin, un stamp posé sous --plugin-root) si son majeur = celui du stamp ;
    #   sinon échelle indéterminée. Sans conductor= au registre : version courante, comme avant.
    ref=""; regc=""
    [ -f "$reg" ] && regc="$(norm "$(grep -E '^conductor=' "$reg" 2>/dev/null | head -1 | cut -d= -f2-)")"
    if [ -n "$FORCE_VERSION" ]; then ref="$(norm "$FORCE_VERSION")"
    elif [ -n "$regc" ]; then
      if [ -n "$rec" ] && [ "${rec%%.*}" != "${regc%%.*}" ]; then
        pjc="$(cache_root)/.claude-plugin/plugin.json"; pvc=""
        [ -n "$(cache_root)" ] && [ -f "$pjc" ] && command -v jq >/dev/null 2>&1 && pvc="$(norm "$(jqx -r '.version // empty' "$pjc")")"
        if [ -n "$pvc" ] && [ "${pvc%%.*}" = "${rec%%.*}" ]; then ref="$pvc"; else ref="?"; fi
      else ref="$regc"; fi
    else ref="$(current_version)"; fi
    if [ -z "$rec" ]; then b_state=nostamp; say "lab non stampé (version framework inconnue). Lancer: framework-version.sh stamp"
    elif [ "$ref" = "?" ]; then b_state=undet; say "calibration : échelle indéterminée (stamp $rec, aucune référence de même échelle)."
    elif [ -z "$ref" ]; then b_state=unknown
    elif [ "$ref" = "$rec" ]; then b_state=ok
    elif semver_lt "$rec" "$ref"; then
      b_state=retard; retard=1
      say "RETARD : lab en $rec, framework en $ref → recalibration conseillée (/vf-calibrate)."
    else b_state=ok; say "lab ($rec) en avance sur le plugin ($ref) — rien à faire."; fi

    [ "$retard" -eq 1 ] && exit 1
    case "$a_state:$b_state" in
      ok:ok|ok:nostamp) say "à jour (modules du lab = cache du plugin${ref:+, framework $ref})." ;;
      indet:*) say "indéterminé : cache du plugin introuvable (retard de mise à jour non vérifiable)." ;;
      none:ok) say "indéterminé : registre du lab absent, mise à jour non vérifiable (calibration à jour, framework $ref)." ;;
      *) [ "$b_state" = unknown ] && say "version courante inconnue — drift indéterminé." ;;
    esac
    exit 0 ;;
  ""|-h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  *) echo "[framework-version] sous-commande inconnue : $cmd" >&2; exit 64 ;;
esac
