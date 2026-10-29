#!/usr/bin/env bash
# test-framework-version.sh — `framework-version.sh drift` (#167) : le lab est comparé au CACHE du
# plugin (A, mise à jour) en plus du stamp (B, calibration). Hermétique : HOME, cache et labs sous
# mktemp -d ; aucune variable d'environnement du poste ne fuit (env -u … + VF_PLUGIN_CACHE posé).
# FV surchargeable (FV=… bash test-framework-version.sh) pour rejouer la suite contre un autre script.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FV="${FV:-$SCRIPT_DIR/framework-version.sh}"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME"

# fv <cache> <args…> : drift isolé ; sortie dans $OUT, code dans $RC.
fv() {
  local cache="$1"; shift
  OUT="$(env -u CLAUDE_PLUGIN_ROOT -u VIBEFLOW_CACHE VF_PLUGIN_CACHE="$cache" bash "$FV" "$@" 2>&1)"; RC=$?
}
mklab() { # <nom> <conductor-registre> <stamp> [lignes registre supplémentaires]
  local l="$TMP/$1"; mkdir -p "$l/.claude/scripts"
  { printf 'conductor=%s\n' "$2"; [ -n "${4:-}" ] && printf '%s\n' "$4"; } > "$l/.claude/scripts/.vibeflow-installed"
  [ -n "$3" ] && printf '%s\n' "$3" > "$l/.claude/.vibeflow-framework-version"
  echo "$l"
}
mkcache() { # <racine> <version-plugin> <module=version…>
  local r="$1/$2"; shift 2; mkdir -p "$r/.claude-plugin"
  printf '{ "name": "vibeflow", "version": "%s" }\n' "$(basename "$r")" > "$r/.claude-plugin/plugin.json"
  local mv; for mv in "$@"; do mkdir -p "$r/${mv%%=*}"; printf '%s\n' "${mv#*=}" > "$r/${mv%%=*}/VERSION"; done
}
expect() { # <desc> <rc attendu> <motif grep -F attendu ou ''> <motif interdit ou ''>
  if [ "$RC" -ne "$2" ]; then ko "$1" "rc $RC au lieu de $2 : $OUT"; return; fi
  if [ -n "$3" ] && ! printf '%s' "$OUT" | grep -qF -- "$3"; then ko "$1" "motif absent '$3' : $OUT"; return; fi
  if [ -n "$4" ] && printf '%s' "$OUT" | grep -qF -- "$4"; then ko "$1" "motif interdit '$4' : $OUT"; return; fi
  ok "$1"
}

echo "== test-framework-version (#167) =="

# 1. cas de l'issue
C1="$TMP/c1"; mkcache "$C1" 2.71.2 conductor=v1.50.2
L="$(mklab l1 v1.49.0 1.49.0)"; fv "$C1" drift --lab-root "$L"
expect "1 retard de mise à jour (registre 1.49.0, cache 1.50.2)" 1 "conductor 1.49.0 → 1.50.2" ""
printf '%s' "$OUT" | grep -qF "plugin 2.71.2" && ok "1b cite la version du plugin" || ko "1b cite la version du plugin" "$OUT"

# 2. à jour
C2="$TMP/c2"; mkcache "$C2" 2.71.2 conductor=1.50.2 planning-core=2.5.0
L="$(mklab l2 v1.50.2 1.50.2 planning-core=v2.5.0)"; fv "$C2" drift --lab-root "$L"
expect "2 lab à jour" 0 "à jour (" "RETARD"

# 3. cache absent (inexistant, puis vide)
L="$(mklab l3 v1.49.0 1.49.0)"; fv "$TMP/inexistant" drift --lab-root "$L"
expect "3 cache inexistant → indéterminé, pas « à jour »" 0 "indéterminé" "à jour ("
mkdir -p "$TMP/vide"; fv "$TMP/vide" drift --lab-root "$L"
expect "3b cache vide → indéterminé" 0 "indéterminé" "à jour ("

# 4. --plugin-root prime sur VF_PLUGIN_CACHE et CLAUDE_PLUGIN_ROOT
C4="$TMP/c4"; mkcache "$C4" 2.71.2 conductor=1.50.2
CX="$TMP/cx"; mkcache "$CX" 2.0.0 conductor=1.0.0
L="$(mklab l4 v1.49.0 1.49.0)"
OUT="$(CLAUDE_PLUGIN_ROOT="$CX/2.0.0" VF_PLUGIN_CACHE="$CX" bash "$FV" drift --lab-root "$L" --plugin-root "$C4/2.71.2" 2>&1)"; RC=$?
expect "4 --plugin-root explicite respecté" 1 "conductor 1.49.0 → 1.50.2" ""

# 5. dernier sous-répertoire semver
C5="$TMP/c5"; mkcache "$C5" 2.9.0 conductor=1.1.0; mkcache "$C5" 2.10.0 conductor=1.2.0; mkdir -p "$C5/latest" "$C5/z9.9.9"
L="$(mklab l5 v1.0.0 1.0.0)"; fv "$C5" drift --lab-root "$L"
expect "5 2.10.0 retenu (pas 2.9.0, noms non semver ignorés)" 1 "conductor 1.0.0 → 1.2.0" ""

# 6. module autre que conductor seul
C6="$TMP/c6"; mkcache "$C6" 2.71.2 conductor=1.50.2 planning-core=2.6.0
L="$(mklab l6 v1.50.2 1.50.2 planning-core=v2.5.0)"; fv "$C6" drift --lab-root "$L"
expect "6 module seul en retard cité" 1 "planning-core 2.5.0 → 2.6.0" "conductor 1.50.2"

# 7. (B) conservé
L="$(mklab l7 v1.50.2 1.49.0)"; fv "$C6" drift --lab-root "$L"
expect "7 retard de calibration (stamp 1.49.0, registre 1.50.2)" 1 "/vf-calibrate" "/vf-update"

# 8. échelle : plugin.json 2.71.2 jamais comparé au stamp
C8="$TMP/c8"; mkcache "$C8" 2.71.2 conductor=1.49.0
L="$(mklab l8 v1.49.0 1.49.0)"; fv "$C8" drift --lab-root "$L" --plugin-root "$C8/2.71.2"
expect "8 pas de comparaison d'échelles (plugin 2.x vs module 1.x)" 0 "à jour (" "framework en 2.71.2"

# 9. CRLF dans VERSION et dans le registre
C9="$TMP/c9"; mkcache "$C9" 2.71.2 conductor=1.50.2; printf '1.50.2\r\n' > "$C9/2.71.2/conductor/VERSION"
L="$(mklab l9 v1.50.2 1.50.2)"; printf 'conductor=v1.50.2\r\n' > "$L/.claude/scripts/.vibeflow-installed"; fv "$C9" drift --lab-root "$L"
expect "9 CRLF : pas de faux RETARD" 0 "à jour (" "RETARD"

# 10. --quiet
L="$(mklab l10 v1.49.0 1.49.0)"; fv "$C1" drift --lab-root "$L" --quiet
if [ "$RC" -eq 1 ] && [ -z "$OUT" ]; then ok "10 --quiet : silence, rc 1 conservé"; else ko "10 --quiet" "rc $RC sortie '$OUT'"; fi
L="$(mklab l10b v1.50.2 1.50.2)"; fv "$C1" drift --lab-root "$L" --quiet
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then ok "10b --quiet : silence, rc 0"; else ko "10b --quiet" "rc $RC sortie '$OUT'"; fi

echo "== résultat : $PASS passés, $FAIL échoués =="
[ "$FAIL" -eq 0 ]
