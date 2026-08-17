#!/usr/bin/env bash
# test-vf-notify.sh — Suite de vérification du toggle /vf-notify (skill + comportement, D-33-H).
#
# Asserts DOCUMENTAIRES (grep -qF sur SKILL.md) : les 4 verbes, l'expression littérale du chemin
# par défaut du sentinel (identité avec notify.sh), le piège user_present, densité ADR-029.
#
# Asserts COMPORTEMENTAUX : reproduisent littéralement les commandes on/off/status documentées
# sous un XDG_CONFIG_HOME sandboxé (mktemp -d, jamais le vrai $HOME de la machine qui exécute la
# suite), plus le verbe test (fichier mktemp jetable + invocation réelle de notify.sh) avec DEUX
# sous-cas prouvant l'absence de mutation d'état persistant dans les deux sens.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$SCRIPT_DIR/../skills/vf-notify/SKILL.md"
NOTIFY="$SCRIPT_DIR/notify.sh"

PASS=0; FAIL=0

ok()  { if [ "$2" = "true" ]; then echo "  ✓ $1"; PASS=$((PASS+1)); else echo "  ✗ $1"; FAIL=$((FAIL+1)); fi; }
has() { grep -qF "$1" "$SKILL" 2>/dev/null && echo true || echo false; }

echo "== test-vf-notify =="

[ -f "$SKILL" ] || { echo "  ✗ SKILL.md introuvable : $SKILL"; exit 1; }
[ -f "$NOTIFY" ] || { echo "  ✗ notify.sh introuvable : $NOTIFY"; exit 1; }

# ---------- Asserts DOCUMENTAIRES ----------
echo "-- documentaire --"
ok "verbe 'on' documenté"                       "$(has '`on`')"
ok "verbe 'off' documenté"                      "$(has '`off`')"
ok "verbe 'status' documenté"                   "$(has '`status`')"
ok "verbe 'test' documenté"                     "$(has '`test`')"
ok "VF_NOTIFY_OPTIN_FILE documenté"             "$(has 'VF_NOTIFY_OPTIN_FILE')"
ok "piège user_present documenté"               "$(grep -qi 'user_present' "$SKILL" 2>/dev/null && echo true || echo false)"

# Identité de chemin : la MÊME sous-chaîne littérale doit exister dans les deux fichiers.
SENTINEL_SUBSTRING='${XDG_CONFIG_HOME:-${HOME:-}/.config}/vibeflow/notify-optin'
SKILL_HAS_PATH=$(grep -qF "$SENTINEL_SUBSTRING" "$SKILL" 2>/dev/null && echo true || echo false)
NOTIFY_HAS_PATH=$(grep -qF "$SENTINEL_SUBSTRING" "$NOTIFY" 2>/dev/null && echo true || echo false)
ok "chemin sentinel présent dans SKILL.md"      "$SKILL_HAS_PATH"
ok "chemin sentinel présent dans notify.sh (identité)" "$NOTIFY_HAS_PATH"

LINES=$(wc -l "$SKILL" | awk '{print $1}')
ok "densité SKILL.md ≤ 500 lignes ($LINES)"     "$([ "$LINES" -le 500 ] && echo true || echo false)"

# ---------- Asserts COMPORTEMENTAUX ----------
echo "-- comportemental --"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Sandbox XDG_CONFIG_HOME — jamais le vrai $HOME/.config de la machine qui exécute la suite.
SANDBOX_XDG="$WORK_DIR/xdgconfig"
mkdir -p "$SANDBOX_XDG"
SENTINEL_PATH="$SANDBOX_XDG/vibeflow/notify-optin"

# --- on : mkdir -p + touch ---
env XDG_CONFIG_HOME="$SANDBOX_XDG" bash -c 'mkdir -p "$(dirname "$1")" && touch "$1"' _ "$SENTINEL_PATH"
ok "on : le sentinel existe après armement" "$([ -f "$SENTINEL_PATH" ] && echo true || echo false)"

# --- status : test -f, après armement -> actif ---
STATUS_AFTER_ON=$([ -f "$SENTINEL_PATH" ] && echo actif || echo inactif)
ok "status après 'on' == actif" "$([ "$STATUS_AFTER_ON" = "actif" ] && echo true || echo false)"

# --- off : rm -f ---
env XDG_CONFIG_HOME="$SANDBOX_XDG" bash -c 'rm -f "$1"' _ "$SENTINEL_PATH"
ok "off : le sentinel n'existe plus après désarmement" "$([ ! -f "$SENTINEL_PATH" ] && echo true || echo false)"

STATUS_AFTER_OFF=$([ -f "$SENTINEL_PATH" ] && echo actif || echo inactif)
ok "status après 'off' == inactif" "$([ "$STATUS_AFTER_OFF" = "inactif" ] && echo true || echo false)"

# --- off idempotent quand déjà absent (pas d'erreur) ---
OFF_AGAIN_RC=0
env XDG_CONFIG_HOME="$SANDBOX_XDG" bash -c 'rm -f "$1"' _ "$SENTINEL_PATH" || OFF_AGAIN_RC=$?
ok "off idempotent (rm -f sur sentinel déjà absent : rc=0)" "$([ "$OFF_AGAIN_RC" -eq 0 ] && echo true || echo false)"

# ---------- Jeu de binaires curés + shim, réutilisé du patron test-notify.sh ----------
UTIL_DIR="$WORK_DIR/utils"
mkdir -p "$UTIL_DIR"
for t in uname dirname grep cat bash env sleep touch; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$UTIL_DIR/$t" 2>/dev/null
done

write_shim() {
  local dir="$1" name="$2"
  {
    printf '#!/bin/bash\n'
    printf 'printf x >> %q\n' "$dir/$name.count"
    printf 'exit 0\n'
  } > "$dir/$name"
  chmod +x "$dir/$name"
}
call_count() { local f="$1/$2.count"; [ -f "$f" ] && wc -c < "$f" | tr -d ' ' || echo 0; }
wait_for_file() {
  local f="$1" budget="${2:-10}" waited=0
  while [ ! -f "$f" ]; do
    "$UTIL_DIR/sleep" 0.1 2>/dev/null || sleep 0.1
    waited=$(( waited + 1 ))
    [ "$waited" -ge $(( budget * 10 )) ] && break
  done
  [ -f "$f" ]
}

# --- test : sentinel persistant ABSENT avant l'appel -> shim invoqué ET sentinel reste ABSENT ---
CHAN_DIR="$WORK_DIR/chan-absent"; mkdir -p "$CHAN_DIR"
write_shim "$CHAN_DIR" osascript
rm -f "$SENTINEL_PATH"
TMP_OPTIN_1="$WORK_DIR/tmp-optin-1"; touch "$TMP_OPTIN_1"
env PATH="$CHAN_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin VF_NOTIFY_OPTIN_FILE="$TMP_OPTIN_1" \
  bash "$NOTIFY" "VibeFlow" "Notification de test (/vf-notify test)" >/dev/null 2>&1
wait_for_file "$CHAN_DIR/osascript.count" 10
rm -f "$TMP_OPTIN_1"
ok "test (persistant absent avant) : shim invoqué (jetable armé pour ce seul appel)" \
  "$([ "$(call_count "$CHAN_DIR" osascript)" != "0" ] && echo true || echo false)"
ok "test (persistant absent avant) : sentinel persistant reste absent après" \
  "$([ ! -f "$SENTINEL_PATH" ] && echo true || echo false)"

# --- test : sentinel persistant PRÉSENT avant l'appel -> shim invoqué ET sentinel reste PRÉSENT ---
CHAN_DIR2="$WORK_DIR/chan-present"; mkdir -p "$CHAN_DIR2"
write_shim "$CHAN_DIR2" osascript
mkdir -p "$(dirname "$SENTINEL_PATH")" && touch "$SENTINEL_PATH"
TMP_OPTIN_2="$WORK_DIR/tmp-optin-2"; touch "$TMP_OPTIN_2"
env PATH="$CHAN_DIR2:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin VF_NOTIFY_OPTIN_FILE="$TMP_OPTIN_2" \
  bash "$NOTIFY" "VibeFlow" "Notification de test (/vf-notify test)" >/dev/null 2>&1
wait_for_file "$CHAN_DIR2/osascript.count" 10
rm -f "$TMP_OPTIN_2"
ok "test (persistant présent avant) : shim invoqué" \
  "$([ "$(call_count "$CHAN_DIR2" osascript)" != "0" ] && echo true || echo false)"
ok "test (persistant présent avant) : sentinel persistant reste présent après" \
  "$([ -f "$SENTINEL_PATH" ] && echo true || echo false)"

echo ""
echo "  PASS=$PASS FAIL=$FAIL"
# Garde anti-vert-à-vide.
if [ "$((PASS+FAIL))" -eq 0 ]; then
  echo "  ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"
  exit 1
fi
[ "$FAIL" -eq 0 ]
