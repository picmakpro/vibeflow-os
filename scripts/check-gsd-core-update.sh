#!/usr/bin/env bash
# check-gsd-core-update.sh — Veille de release de `@opengsd/gsd-core` (WKTR-03, D-10).
#
# La Phase 35 (ré-armement worktree) est flottante : elle ne se déclenche QUE si une version de
# `@opengsd/gsd-core` strictement supérieure à 1.10.0 est publiée. Sans cette sonde, personne ne
# constate la sortie de cette release. Outillage de CE dépôt uniquement (pas un script de module) :
# la précondition ne concerne que vibeflow-os.
#
# Contrat :
#   - Interroge la version PUBLIÉE (`npm view <paquet> version` = dist-tag `latest`), JAMAIS le
#     dist-tag `next` (D-10) : la précondition de la Phase 35 est « releasé », pas « préversion ».
#   - Comparaison strictement supérieure par `sort -V`, jamais un tri lexical
#     (piège documenté : 1.9.0 < 1.10.0 en semver, l'inverse en lexical).
#   - Cache QUOTIDIEN : le refresh réseau est gaté par l'âge du dernier appel RÉUSSI.
#   - Backstop hors ligne : réseau/npm indisponible ⇒ le cache n'est PAS réécrit, l'état précédent
#     est conservé, rc 0, stdout vide. Jamais d'erreur, de faux signal, ni de faux silence.
#
# Cache : ${XDG_CACHE_HOME:-~/.cache}/vibeflow/gsd-core-update.json (nom distinct du cache du
# plugin, cf. plugin/conductor/scripts/check-plugin-update.sh)
#   { "threshold": "1.10.0", "latest": "x.y.z", "exceeds": bool, "checked_at": "ISO" }
#
# Usage :
#   check-gsd-core-update.sh --refresh                   # sonde réseau si le gate d'âge l'autorise,
#                                                         # met à jour le cache, silencieux (mode fond)
#   check-gsd-core-update.sh --print                     # ne parle JAMAIS au réseau ; lit le cache et
#                                                         # imprime UNE ligne si le seuil est dépassé,
#                                                         # silence total sinon
#   check-gsd-core-update.sh --hook                      # mode démarrage de session : --print puis
#                                                         # --refresh détaché en arrière-plan ; exit 0
#   check-gsd-core-update.sh --status                    # diagnostic humain sur stdout, exit 0
#   check-gsd-core-update.sh --if-older-than <N>d [...]  # surcharge le gate d'âge (défaut 1d)
#   check-gsd-core-update.sh --help
#
# Surcharges d'environnement (tests) :
#   VF_GSD_CORE_PACKAGE    (défaut @opengsd/gsd-core)
#   VF_GSD_CORE_THRESHOLD  (défaut 1.10.0)
#   VF_GSD_CORE_CACHE_DIR  (défaut ${XDG_CACHE_HOME:-~/.cache}/vibeflow)
#
# Codes de sortie : 0 = nominal ou dégradé (advisory, ADR-031) · 64 = argument inconnu ou valeur de
# gate manquante. Aucun autre code.
set -uo pipefail

PACKAGE="${VF_GSD_CORE_PACKAGE:-@opengsd/gsd-core}"
THRESHOLD="${VF_GSD_CORE_THRESHOLD:-1.10.0}"
CACHE_DIR="${VF_GSD_CORE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow}"
CACHE_FILE="$CACHE_DIR/gsd-core-update.json"
GATE_DEFAULT="1d"

MODE=""
IF_OLDER_THAN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --refresh) MODE="refresh"; shift ;;
    --print)   MODE="print"; shift ;;
    --hook)    MODE="hook"; shift ;;
    --status)  MODE="status"; shift ;;
    --if-older-than)
      shift
      [ $# -gt 0 ] || { echo "[check-gsd-core-update] --if-older-than requiert une valeur (ex: 1d)" >&2; exit 64; }
      IF_OLDER_THAN="$1"; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-gsd-core-update] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

[ -n "$MODE" ] || MODE="refresh"
[ -n "$IF_OLDER_THAN" ] || IF_OLDER_THAN="$GATE_DEFAULT"

log() { echo "[check-gsd-core-update] $*" >&2; }

# --- Comparaison semver stricte : vrai si $1 > $2 (jamais un tri lexical, piège 1.9.0/1.10.0) ---
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }

# --- Lecture de champs du cache JSON (pas de dépendance à jq) ---
read_field() { # <file> <key> -> valeur ou vide
  sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$1" 2>/dev/null | head -1
}
read_bool_field() { # <file> <key> -> true|false|vide
  # -E (ERE) : le BSD sed de macOS n'interprète pas `\|` comme une alternation en BRE.
  sed -n -E "s/.*\"$2\"[[:space:]]*:[[:space:]]*(true|false).*/\\1/p" "$1" 2>/dev/null | head -1
}

# --- Gate d'âge : suffixe malformé ⇒ fail-open sur le défaut (jamais une erreur, cf. audit-infra.sh) ---
gate_days() {
  local days="${1%d}"
  case "$days" in ''|*[!0-9]*) days="${GATE_DEFAULT%d}" ;; esac
  printf '%s' "$days"
}

is_stale() {
  # Vrai si le cache est absent ou plus vieux que le gate ⇒ le refresh réseau est autorisé.
  [ -f "$CACHE_FILE" ] || return 0
  local days m now age
  days="$(gate_days "$IF_OLDER_THAN")"
  m=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  case "$m" in ''|*[!0-9]*) m=0 ;; esac
  now=$(date +%s 2>/dev/null || echo 0)
  [ "$now" -gt 0 ] || return 0
  age=$(( (now - m) / 86400 ))
  [ "$age" -ge "$days" ]
}

do_refresh() {
  is_stale || { log "cache récent (< ${IF_OLDER_THAN} depuis le dernier appel réussi), skip"; return 0; }

  mkdir -p "$CACHE_DIR" 2>/dev/null || return 0

  # Verrou mkdir atomique : une seule sonde à la fois (--hook peut relancer vite). Périmé > 300s
  # (process tué) ⇒ cassé et repris, jamais bloqué indéfiniment.
  local lock="$CACHE_DIR/.gsd-core-check.lock"
  if ! mkdir "$lock" 2>/dev/null; then
    local lock_m now
    lock_m=$(stat -c %Y "$lock" 2>/dev/null || stat -f %m "$lock" 2>/dev/null || echo 0)
    case "$lock_m" in ''|*[!0-9]*) lock_m=0 ;; esac
    now=$(date +%s 2>/dev/null || echo 0)
    if [ "$now" -gt 0 ] && [ $((now - lock_m)) -gt 300 ]; then
      rmdir "$lock" 2>/dev/null || true
      mkdir "$lock" 2>/dev/null || return 0
    else
      return 0
    fi
  fi
  trap 'rmdir "$lock" 2>/dev/null' RETURN

  command -v npm >/dev/null 2>&1 || { log "npm absent du PATH — cache conservé tel quel (traitement identique à un réseau KO)"; return 0; }

  local latest
  latest="$(npm view "$PACKAGE" version 2>/dev/null)"
  latest="${latest%$'\r'}"
  latest="$(printf '%s' "$latest" | tr -d '[:space:]')"

  # Réponse vide/injoignable ⇒ AUCUNE réécriture du cache : l'état précédent est conservé.
  if [ -z "$latest" ]; then
    log "npm view $PACKAGE version : réponse vide (réseau KO ou registre indisponible) — cache conservé tel quel"
    return 0
  fi

  local exceeds="false"
  newer "$latest" "$THRESHOLD" && exceeds="true"

  local checked_at
  checked_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local json="{\"threshold\":\"$THRESHOLD\",\"latest\":\"$latest\",\"exceeds\":$exceeds,\"checked_at\":\"$checked_at\"}"
  # Écriture atomique : jamais de cache à moitié écrit (lu par --print/--status au démarrage suivant).
  { printf '%s\n' "$json" > "$CACHE_FILE.tmp.$$" && mv -f "$CACHE_FILE.tmp.$$" "$CACHE_FILE"; } 2>/dev/null \
    || rm -f "$CACHE_FILE.tmp.$$" 2>/dev/null || true
}

do_print() {
  [ -f "$CACHE_FILE" ] || return 0   # jamais rafraîchie / rien à signaler : silence total, rc 0

  local threshold latest exceeds
  threshold="$(read_field "$CACHE_FILE" threshold)"
  latest="$(read_field "$CACHE_FILE" latest)"
  exceeds="$(read_bool_field "$CACHE_FILE" exceeds)"

  if [ -z "$threshold" ] || [ -z "$latest" ] || [ -z "$exceeds" ]; then
    log "cache imparsable ($CACHE_FILE) — sonde muette, aucun signal émis (jamais un vert par défaut)"
    return 0
  fi

  if [ "$exceeds" = "true" ]; then
    printf 'gsd-core %s > %s publié — précondition de la Phase 35 (ré-armement worktree) constatée. Voir .planning/phases/VFDO-30-portabilit-windows-ii/30-VEILLE-GSD-CORE.md\n' "$latest" "$threshold"
  fi
}

do_hook() {
  do_print
  local self
  self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  # ⚠ setsid n'existe pas sur macOS et son échec en arrière-plan est asynchrone (leçon
  # update-banner.sh) : on teste sa présence AVANT, et on ferme stdin.
  if command -v setsid >/dev/null 2>&1; then
    ( setsid bash "$self" --refresh --if-older-than "$IF_OLDER_THAN" </dev/null >/dev/null 2>&1 & ) 2>/dev/null || true
  else
    ( bash "$self" --refresh --if-older-than "$IF_OLDER_THAN" </dev/null >/dev/null 2>&1 & ) 2>/dev/null || true
  fi
  return 0
}

do_status() {
  if [ ! -f "$CACHE_FILE" ]; then
    printf 'veille gsd-core : aucun cache — jamais rafraîchie (%s)\n' "$CACHE_FILE"
    return 0
  fi

  local threshold latest exceeds checked_at
  threshold="$(read_field "$CACHE_FILE" threshold)"
  latest="$(read_field "$CACHE_FILE" latest)"
  exceeds="$(read_bool_field "$CACHE_FILE" exceeds)"
  checked_at="$(read_field "$CACHE_FILE" checked_at)"

  if [ -z "$threshold" ] || [ -z "$latest" ] || [ -z "$exceeds" ] || [ -z "$checked_at" ]; then
    log "cache imparsable ($CACHE_FILE)"
    printf 'veille gsd-core : cache imparsable — voir stderr (%s)\n' "$CACHE_FILE"
    return 0
  fi

  printf 'veille gsd-core : seuil=%s dernière_version_vue=%s dépassement=%s dernier_appel_réussi=%s cache=%s\n' \
    "$threshold" "$latest" "$exceeds" "$checked_at" "$CACHE_FILE"
}

case "$MODE" in
  refresh) do_refresh; exit 0 ;;
  print)   do_print;   exit 0 ;;
  hook)    do_hook;    exit 0 ;;
  status)  do_status;  exit 0 ;;
esac
