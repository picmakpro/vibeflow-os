#!/usr/bin/env bash
# check-gsd-engine.sh — Sur quel moteur GSD tourne ce poste ? (SC1, SC5, Phase 19)
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit JAMAIS qu'un moteur
# legacy est mauvais, ni ne l'installe ni ne le désinstalle lui-même — il CONSTATE un état parmi
# trois et propose un geste ; c'est l'agent (le skill /vf-update) qui juge et exécute, sous
# confirmation humaine explicite (ADR-031). Ce script est en lecture seule.
#
# Les 3 états rendus, décidés sur la PRÉSENCE des fichiers `VERSION` du poste (layout + nom de
# paquet), JAMAIS sur leur contenu numérique :
#   - absent   : ni le VERSION du nouveau layout (<gsd-core>/VERSION) ni celui de l'ancien
#                (~/.claude/get-shit-done/VERSION) n'existent.
#   - legacy   : seul le VERSION de l'ancien paquet (get-shit-done-cc) existe — SEUL cas
#                actionnable de ce gate.
#   - gsd-core : le VERSION du nouveau paquet (@opengsd/gsd-core) existe, avec ou sans reliquat
#                de l'ancien layout à côté (cas dual, voir plus bas).
#
# Piège n°1 — JAMAIS de détection par PATH (recopié de ensure-deps.sh:116-118) : un shim legacy
# (ex. un binaire gsd-sdk resté sur le PATH) peut survivre à une migration ; un `command -v`
# ferait alors indéfiniment croire à sa présence — panne silencieuse et durable. La seule source
# de vérité de ce gate est la présence du fichier VERSION du poste, jamais le PATH.
#
# Piège semver (D-05) — ÉCRIT NOIR SUR BLANC, à ne jamais réintroduire : le paquet legacy
# get-shit-done-cc est FIGÉ à 1.42.3 (déprécié sur npm, plus jamais republié) tandis que le
# paquet vivant @opengsd/gsd-core est à 1.8.0 aujourd'hui. Donc 1.8.0 < 1.42.3 en semver : toute
# comparaison de numéros de version (sort -V, test d'infériorité/supériorité, réutilisation d'un
# comparateur existant comme celui de check-plugin-update.sh) classerait à tort le poste legacy
# comme « à jour » — pour toujours, puisque 1.42.3 ne redescendra jamais. C'est exactement le
# trou que ce gate corrige : le classement ne compare AUCUN numéro, il ne regarde QUE la présence
# des deux fichiers VERSION.
#
# Cas dual (D-04) — rupture assumée de « exit 3 == silence », même précédent que l'en-tête de
# check-dev-bootstrap.sh (état 3 de ce script-là) : si les DEUX fichiers VERSION existent, l'état
# rendu est gsd-core (la migration a déjà eu lieu ; reproposer une install serait un no-op
# bruyant) — MAIS le gate imprime quand même UNE ligne [gsd-leftover] sur stdout, tout en sortant
# en 3. L'exit 3 n'est donc PAS toujours un silence : le sous-cas « gsd-core propre » reste
# silencieux (stdout vide), le sous-cas « gsd-core + reliquat legacy » ne l'est pas. Les deux sont
# assertés séparément par la suite dédiée — stdout ET code de sortie, jamais l'un déduit de
# l'autre (piège D-14, Phase 17).
#
# Usage:
#   check-gsd-engine.sh [--quiet]
#   check-gsd-engine.sh -h|--help
#
# --quiet supprime les diagnostics internes (stderr uniquement) ; le contenu de stdout ne change
# JAMAIS entre l'invocation avec et sans --quiet.
#
# Exit codes:
#   0 = état legacy — seul cas actionnable, signal [gsd-migrate] sur stdout (2 lignes).
#   2 = erreur d'usage (argument inconnu).
#   3 = INDÉTERMINÉ — état absent (stdout vide), état gsd-core propre (stdout vide), ou état
#       gsd-core + reliquat legacy (stdout NON vide, signal [gsd-leftover] sur 1 ligne — D-04,
#       exit 3 n'est pas synonyme de silence dans ce sous-cas précis).
set -uo pipefail

QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-gsd-engine] argument inconnu : $1" >&2; exit 2 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[check-gsd-engine] $*" >&2; }

# --- Cascade de dérivation du layout (duplication DÉLIBÉRÉE de ensure-deps.sh:60-69, motivée par
# D-01 : ce gate doit rester testable en boîte noire sans sourcer un script à effets de bord). La
# RÉFÉRENCE de contenu de cette cascade reste ensure-deps.sh — ne pas la faire diverger d'un côté
# sans reporter le changement de l'autre.
default_gsd_home_new() {
  local root claude_home
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core" ]; then
    echo "$root/.claude/gsd-core"
  else
    echo "$claude_home/gsd-core"
  fi
}
GSD_HOME_NEW="$(default_gsd_home_new)"
GSD_VERSION_FILE_NEW="$GSD_HOME_NEW/VERSION"
GSD_VERSION_FILE_LEGACY="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/get-shit-done/VERSION"

# --- Classement à 3 états, décidé sur la PRÉSENCE des fichiers, jamais leur contenu (D-03) -------
gsd_engine_state() {
  if [ -f "$GSD_VERSION_FILE_NEW" ]; then
    echo "gsd-core"
  elif [ -f "$GSD_VERSION_FILE_LEGACY" ]; then
    echo "legacy"
  else
    echo "absent"
  fi
}

has_legacy_leftover() { [ -f "$GSD_VERSION_FILE_LEGACY" ]; }

# --- Assainissement d'une valeur VERSION lue (modèle check-dev-bootstrap.sh:148-159, T-19-01-01)
# La lecture est bornée EN AMONT (200 octets max au point d'appel — jamais un `cat` intégral d'un
# fichier de taille arbitraire, T-19-01-04), puis la valeur est validée contre une classe de
# caractères restreinte. Toute valeur non conforme (substitution de commande, octet de contrôle,
# longueur excessive) est remplacée par une mention neutre et n'est JAMAIS réinjectée dans une
# expansion ni imprimée telle quelle.
sanitize_version() { # <raw>
  local v="$1"
  if [ "${#v}" -gt 80 ]; then
    printf '%s' "(version illisible)"
    return 1
  fi
  case "$v" in
    \"*) [ "${v%\"}" != "$v" ] && { v="${v#\"}"; v="${v%\"}"; } ;;
    \'*) [ "${v%\'}" != "$v" ] && { v="${v#\'}"; v="${v%\'}"; } ;;
  esac
  if printf '%s' "$v" | grep -Eq '^[0-9A-Za-z._-]{1,80}$'; then
    printf '%s' "$v"
    return 0
  fi
  printf '%s' "(version illisible)"
  return 1
}

STATE="$(gsd_engine_state)"

case "$STATE" in
  legacy)
    RAW_VERSION="$(head -c 200 "$GSD_VERSION_FILE_LEGACY" 2>/dev/null)"
    VERSION_SAFE="$(sanitize_version "$RAW_VERSION")"
    say "moteur legacy détecté (get-shit-done-cc ${VERSION_SAFE}) — migration à proposer."
    printf '%s\n' "[gsd-migrate] moteur GSD legacy (get-shit-done-cc ${VERSION_SAFE}) — bascule disponible vers @opengsd/gsd-core."
    printf '%s\n' "              → propose la migration (confirmation requise via /vf-update)."
    exit 0
    ;;
  gsd-core)
    if has_legacy_leftover; then
      # Cas dual (D-04) — rupture assumée de « exit 3 == silence » : la migration a déjà eu lieu
      # (état gsd-core), donc AUCUNE proposition d'install n'est émise — mais un reliquat legacy
      # subsiste à côté, et le taire serait un vrai silence sur un fait réel. Ce sous-cas imprime
      # donc UNE ligne [gsd-leftover] sur stdout tout en sortant en 3 quand même : reproposer une
      # install serait un no-op bruyant, mais ne rien dire du reliquat serait un silence trompeur.
      say "moteur à jour (@opengsd/gsd-core), reliquat legacy détecté — signalé sans proposer d'install."
      printf '%s\n' "[gsd-leftover] moteur @opengsd/gsd-core à jour ; reliquat legacy détecté — nettoyage manuel recommandé."
      exit 3
    fi
    say "moteur @opengsd/gsd-core détecté, rien à signaler."
    exit 3
    ;;
  *)
    say "aucun moteur GSD détecté — rien à signaler."
    exit 3
    ;;
esac
