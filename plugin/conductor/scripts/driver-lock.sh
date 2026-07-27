#!/usr/bin/env bash
# driver-lock.sh — Lock de driver unique pour vf-dev-manager (ADR-053, Pattern A)
#
# Empeche deux missions/sessions de piloter la MEME etape en parallele (collision de pilotage
# sur les backups isoles ADR-048/049). Acquisition ATOMIQUE par `mkdir` (le seul primitif atomique
# portable). Recuperation de claim perime livree d'emblee (heartbeat + TTL) : un manager qui meurt
# ne gele pas les missions.
#
# Usage:
#   driver-lock.sh acquire   --owner=<id> --step=<etape>   # pose le lock (ou le recupere si perime)
#   driver-lock.sh heartbeat --owner=<id> [--step=<etape>] # rafraichit le heartbeat entre etapes
#   driver-lock.sh release   --owner=<id>                  # relache (clôture RAII : succes/echec/abandon)
#   driver-lock.sh status                                  # etat courant (JSON)
#   driver-lock.sh recover                                 # elague un lock perime (sinon refuse)
#
# Sortie : JSON une ligne (parsing). Exit 0 = action reussie ; exit 1 = refus (lock tenu, pas owner…).
#
# Variables : VF_DRIVER_LOCK (defaut .planning/DRIVER.lock), VF_DRIVER_TTL (defaut 1800 s).
# Reference : ADR-053 + .planning/phases/VFDO-09-*/09-CADRAGE-swarm.md §2.

set -uo pipefail

LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"
TTL="${VF_DRIVER_TTL:-1800}"
META="$LOCK_DIR/meta"
case "$TTL" in ''|*[!0-9]*) TTL=1800 ;; esac  # garde : TTL non numerique -> defaut (L3)

ACTION=""; OWNER=""; STEP=""
for arg in "$@"; do
  case "$arg" in
    acquire|heartbeat|release|status|recover) ACTION="$arg" ;;
    --owner=*) OWNER="${arg#*=}" ;;
    --step=*)  STEP="${arg#*=}" ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

log() { echo "[driver-lock.sh] $*" >&2; }
now() { date +%s; }
iso() { date +%Y-%m-%dT%H:%M:%S; }
# lit une cle du meta (vide si absent) — 1re ligne, pas de saut
meta_get() { [ -f "$META" ] && grep "^$1=" "$META" 2>/dev/null | head -1 | cut -d= -f2- || true; }

# age du lock en secondes. heartbeat_epoch s'il est numerique ; SINON mtime du dossier de lock
# (fix H2 : un meta vide/partiel — process mort entre mkdir et write_meta — devient recuperable
# apres TTL au lieu de rester eternellement "frais" et de geler toutes les missions).
lock_age() {
  local hb; hb="$(meta_get heartbeat_epoch)"
  case "$hb" in ''|*[!0-9]*) hb="" ;; esac
  # GNU (-c) AVANT BSD (-f) : sur GNU, `stat -f` = mode filesystem — il imprime un bloc
  # multi-lignes sur stdout PUIS échoue, et la substitution capturait bloc + fallback
  # (hb non numérique → staleness jamais détectée). BSD échoue proprement sur -c.
  [ -z "$hb" ] && hb="$(stat -c %Y "$LOCK_DIR" 2>/dev/null || stat -f %m "$LOCK_DIR" 2>/dev/null || now)"
  echo "$(( $(now) - hb ))"
}

write_meta() {
  {
    printf 'owner=%s\n'           "$(printf '%s' "$OWNER" | tr -d '\n')"
    printf 'step=%s\n'            "$(printf '%s' "$STEP"  | tr -d '\n')"
    printf 'acquired_epoch=%s\n'  "$1"
    printf 'acquired_iso=%s\n'    "$2"
    printf 'heartbeat_epoch=%s\n' "$3"
  } > "$META"
}

json_status() {
  if [ "$1" = false ]; then
    printf '{"present": false, "lock": "%s"}\n' "$LOCK_DIR"; return
  fi
  local o s age stale
  o="$(meta_get owner)"; s="$(meta_get step)"; age="$(lock_age)"
  [ "$age" -gt "$TTL" ] && stale=true || stale=false
  printf '{"present": true, "owner": "%s", "step": "%s", "age_seconds": %s, "ttl": %s, "stale": %s}\n' \
    "$o" "$s" "$age" "$TTL" "$stale"
}

require_owner() {
  [ -n "$OWNER" ] || { log "--owner requis pour '$ACTION'"; echo '{"error": "owner-required"}'; exit 1; }
}
ensure_parent() { mkdir -p "$(dirname "$LOCK_DIR")" 2>/dev/null || true; }

case "$ACTION" in
  acquire)
    require_owner
    ensure_parent
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      write_meta "$(now)" "$(iso)" "$(now)"
      printf '{"acquired": true, "owner": "%s", "step": "%s", "recovered": false}\n' "$OWNER" "$STEP"
      exit 0
    fi
    age="$(lock_age)"; held="$(meta_get owner)"
    if [ "$age" -gt "$TTL" ]; then
      log "lock perime (age ${age}s > ${TTL}s, owner=$held) — recuperation"
      # H1 : elagage ATOMIQUE par rename. `mv` reussit pour UN SEUL concurrent (les autres voient
      # la source deja deplacee) → pas de double-acquisition pendant la recuperation.
      stale="${LOCK_DIR}.stale.$$"
      if mv "$LOCK_DIR" "$stale" 2>/dev/null; then
        # H1-ABA : entre NOTRE verdict "perime" et ce mv, un concurrent a pu recuperer PUIS
        # recreer un lock FRAIS — le mv reussit alors sur ce lock vivant (double "recovered"
        # observe en CI, T13.1). Re-verifier le heartbeat du meta DEPLACE : frais → on le remet
        # en place et on rend la main. (Fenetre residuelle theorique si un 3e mkdir s'intercale
        # pendant ces quelques instructions — le heartbeat du proprietaire depossede la detecte.)
        mhb="$(grep '^heartbeat_epoch=' "$stale/meta" 2>/dev/null | head -1 | cut -d= -f2-)"
        case "$mhb" in ''|*[!0-9]*) mhb="" ;; esac
        if [ -n "$mhb" ] && [ "$(( $(now) - mhb ))" -le "$TTL" ]; then
          mv "$stale" "$LOCK_DIR" 2>/dev/null || rm -rf "$stale"
          printf '{"acquired": false, "reason": "race-during-recovery"}\n'; exit 1
        fi
        rm -rf "$stale"
        if mkdir "$LOCK_DIR" 2>/dev/null; then
          write_meta "$(now)" "$(iso)" "$(now)"
          printf '{"acquired": true, "owner": "%s", "step": "%s", "recovered": true, "previous_owner": "%s"}\n' \
            "$OWNER" "$STEP" "$held"
          exit 0
        fi
      fi
      printf '{"acquired": false, "reason": "race-during-recovery"}\n'; exit 1
    fi
    if [ "$held" = "$OWNER" ]; then
      # meme owner : ré-acquisition idempotente (rafraichit heartbeat, maj etape si fournie)
      [ -z "$STEP" ] && STEP="$(meta_get step)"
      write_meta "$(meta_get acquired_epoch)" "$(meta_get acquired_iso)" "$(now)"
      printf '{"acquired": true, "owner": "%s", "step": "%s", "reentrant": true}\n' "$OWNER" "$STEP"
      exit 0
    fi
    printf '{"acquired": false, "reason": "held", "held_by": "%s", "age_seconds": %s}\n' "$held" "$age"
    exit 1
    ;;

  heartbeat)
    require_owner
    [ -d "$LOCK_DIR" ] || { echo '{"ok": false, "reason": "no-lock"}'; exit 1; }
    if [ "$(meta_get owner)" = "$OWNER" ]; then
      # rafraichit l'horodatage (maj step si --step fourni) — un seul ts pour meta + rapport
      [ -z "$STEP" ] && STEP="$(meta_get step)"
      ts="$(now)"
      write_meta "$(meta_get acquired_epoch)" "$(meta_get acquired_iso)" "$ts"
      printf '{"ok": true, "owner": "%s", "heartbeat_epoch": %s}\n' "$OWNER" "$ts"
      exit 0
    fi
    printf '{"ok": false, "reason": "not-owner", "held_by": "%s"}\n' "$(meta_get owner)"; exit 1
    ;;

  release)
    require_owner
    [ -d "$LOCK_DIR" ] || { echo '{"released": false, "reason": "no-lock"}'; exit 0; }
    held="$(meta_get owner)"
    if [ "$held" = "$OWNER" ]; then
      rm -rf "$LOCK_DIR"
      printf '{"released": true, "owner": "%s"}\n' "$OWNER"; exit 0
    fi
    printf '{"released": false, "reason": "not-owner", "held_by": "%s"}\n' "$held"; exit 1
    ;;

  status)
    [ -d "$LOCK_DIR" ] && json_status true || json_status false
    exit 0
    ;;

  recover)
    [ -d "$LOCK_DIR" ] || { echo '{"recovered": false, "reason": "no-lock"}'; exit 0; }
    age="$(lock_age)"; held="$(meta_get owner)"
    if [ "$age" -gt "$TTL" ]; then
      stale="${LOCK_DIR}.stale.$$"
      if mv "$LOCK_DIR" "$stale" 2>/dev/null; then
        rm -rf "$stale"
        printf '{"recovered": true, "previous_owner": "%s", "age_seconds": %s}\n' "$held" "$age"; exit 0
      fi
      printf '{"recovered": false, "reason": "race-during-recovery"}\n'; exit 1
    fi
    printf '{"recovered": false, "reason": "still-fresh", "age_seconds": %s, "ttl": %s}\n' "$age" "$TTL"
    exit 1
    ;;

  *)
    echo "Usage: $0 {acquire|heartbeat|release|status|recover} [--owner=ID] [--step=X]" >&2
    exit 1
    ;;
esac
