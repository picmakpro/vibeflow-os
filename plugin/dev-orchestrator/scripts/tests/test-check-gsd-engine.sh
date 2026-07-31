#!/usr/bin/env bash
# test-check-gsd-engine.sh — Suite dédiée de check-gsd-engine.sh (SC1, SC5, SC7, Phase 19-01).
#
# 15 cas numérotés, boîte noire (subprocess réel). Chaque cas capture `out` et `rc` dans deux
# variables distinctes et les asserte séparément dans le même `if` — jamais l'un déduit de
# l'autre (piège D-14, Phase 17). `$HOME` factice via mktemp -d + trap ... EXIT ; CLAUDE_CONFIG_DIR
# explicitement retiré de l'environnement à chaque invocation (sinon une variable ambiante de la
# machine de l'exécutant rendrait la suite non hermétique).
#
# Couverture : les 3 états (1,2,3), le cas dual D-04 (4), les deux discriminants semver D-05 par
# le haut et par le bas (5,6), les assertions structurelles D-05 (7), les assertions documentaires
# D-05 (8), le scénario réel du rapport D-11 + orthogonalité au cache plugin (9), le discriminant
# de scope projet-local miroir de T2f de test-dev-orchestrator.sh (10), l'erreur d'usage (11),
# --help/--quiet (12), la robustesse sur VERSION hostile (13), bash -n (14), la lecture seule par
# empreinte find (15).
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-gsd-engine.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# mk_gsd_home <name> [legacy_version] [new_version] -> imprime le chemin d'un $HOME factice.
# Pose $HOME/.claude/get-shit-done/VERSION (si legacy_version non vide) et/ou
# $HOME/.claude/gsd-core/VERSION (si new_version non vide). Écriture par printf (jamais d'echo
# multi-mots interprété — un contenu hostile peut y être déposé, cas 13).
mk_gsd_home() { # <name> [legacy_version] [new_version]
  local name="$1" legacy="${2:-}" new="${3:-}"
  local d="$TMP/$name/home"
  mkdir -p "$d/.claude"
  if [ -n "$legacy" ]; then
    mkdir -p "$d/.claude/get-shit-done"
    printf '%s' "$legacy" > "$d/.claude/get-shit-done/VERSION"
  fi
  if [ -n "$new" ]; then
    mkdir -p "$d/.claude/gsd-core"
    printf '%s' "$new" > "$d/.claude/gsd-core/VERSION"
  fi
  printf '%s' "$d"
}

# mk_gsd_project <name> -> imprime le chemin d'un projet factice (hors dépôt git), sans payload.
mk_gsd_project() { # <name>
  local name="$1"
  local d="$TMP/$name/proj"
  mkdir -p "$d"
  printf '%s' "$d"
}

# Pose un payload gsd-core en scope PROJET (<proj>/.claude/gsd-core/VERSION).
mk_gsd_project_payload() { # <proj-dir> <version>
  local d="$1" ver="$2"
  mkdir -p "$d/.claude/gsd-core"
  printf '%s' "$ver" > "$d/.claude/gsd-core/VERSION"
}

# Invocation boîte noire standard : cd vers le projet factice, HOME surchargé,
# CLAUDE_CONFIG_DIR explicitement retiré de l'environnement.
run_gate() { # <home-dir> <proj-dir> [extra-args...]
  local home="$1" proj="$2"; shift 2
  ( cd "$proj" && env -u CLAUDE_CONFIG_DIR HOME="$home" bash "$SCRIPT" "$@" )
}

echo "== test-check-gsd-engine =="

# === Cas 1 — état absent : aucun VERSION, ni nouveau ni legacy → stdout vide, exit 3 =============
H="$(mk_gsd_home c1)"; P="$(mk_gsd_project c1)"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "1 état absent → stdout vide, exit 3"; else ko "1 état absent → stdout vide, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 2 — état legacy avec le numéro figé du paquet déprécié (1.42.3) → [gsd-migrate], exit 0
H="$(mk_gsd_home c2 "1.42.3")"; P="$(mk_gsd_project c2)"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
has_sig=0; case "$out" in *"[gsd-migrate]"*"1.42.3"*) has_sig=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_sig" -eq 1 ]; then ok "2 état legacy (1.42.3) → [gsd-migrate], exit 0"; else ko "2 état legacy (1.42.3) → [gsd-migrate], exit 0" "rc=$rc out=[$out]"; fi

# === Cas 3 — état gsd-core seul → stdout vide, exit 3 ============================================
H="$(mk_gsd_home c3 "" "1.8.0")"; P="$(mk_gsd_project c3)"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "3 état gsd-core seul → stdout vide, exit 3"; else ko "3 état gsd-core seul → stdout vide, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 4 — cas dual D-04 (piège D-14) : les deux VERSION présents → gsd-core + [gsd-leftover], exit 3
H="$(mk_gsd_home c4 "1.42.3" "1.8.0")"; P="$(mk_gsd_project c4)"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
has_leftover=0; case "$out" in *"[gsd-leftover]"*) has_leftover=1 ;; esac
if [ "$rc" -eq 3 ] && [ -n "$out" ] && [ "$has_leftover" -eq 1 ]; then ok "4 cas dual D-04 → [gsd-leftover], exit 3 (stdout non vide)"; else ko "4 cas dual D-04 → [gsd-leftover], exit 3 (stdout non vide)" "rc=$rc out=[$out]"; fi

# === Cas 5 — discriminant D-05 par le haut : legacy=9.9.9 (> tout numéro gsd-core) reste legacy ===
H="$(mk_gsd_home c5 "9.9.9")"; P="$(mk_gsd_project c5)"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
has_sig=0; case "$out" in *"[gsd-migrate]"*) has_sig=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_sig" -eq 1 ]; then ok "5 discriminant D-05 haut : legacy 9.9.9 reste legacy, exit 0"; else ko "5 discriminant D-05 haut : legacy 9.9.9 reste legacy, exit 0" "rc=$rc out=[$out]"; fi

# === Cas 6 — discriminant D-05 par le bas : gsd-core=0.0.1 (< numéro legacy) reste gsd-core =======
H="$(mk_gsd_home c6 "" "0.0.1")"; P="$(mk_gsd_project c6)"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "6 discriminant D-05 bas : gsd-core 0.0.1 reste gsd-core, exit 3"; else ko "6 discriminant D-05 bas : gsd-core 0.0.1 reste gsd-core, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 7 — assertions structurelles D-05 : ni sort -V, ni newer, ni comparaison numérique de version
SRC_NOCOMMENT="$(grep -v '^[[:space:]]*#' "$SCRIPT")"
c_sortv=$(printf '%s\n' "$SRC_NOCOMMENT" | grep -c 'sort -V')
c_newer=$(printf '%s\n' "$SRC_NOCOMMENT" | grep -c 'newer')
c_numver=$(printf '%s\n' "$SRC_NOCOMMENT" | grep -E '(VERSION_(NEW|LEGACY)|_ver|version)' | grep -Ec -- '-(lt|gt|le|ge)')
if [ "$c_sortv" -eq 0 ] && [ "$c_newer" -eq 0 ] && [ "$c_numver" -eq 0 ]; then
  ok "7 structurel D-05 : aucun sort -V / newer / comparaison numérique de version hors commentaires"
else
  ko "7 structurel D-05 : aucun sort -V / newer / comparaison numérique de version hors commentaires" "sort-V=$c_sortv newer=$c_newer numver=$c_numver"
fi

# === Cas 8 — assertions documentaires D-05 : en-tête cite 1.42.3, 1.9.0, semver ===================
# Bouge avec le texte de check-gsd-engine.sh:25 à chaque migration du poste courant (Phase
# 21-03/Changement 5) — jamais affaibli ni neutralisé, la leçon D-05 reste vraie quel que soit le
# numéro « aujourd'hui » : la migration se décide sur le nom du paquet/layout, jamais un semver.
c_142=$(grep '^# ' "$SCRIPT" | grep -c '1\.42\.3')
c_190=$(grep '^# ' "$SCRIPT" | grep -c '1\.9\.0')
c_semver=$(grep '^# ' "$SCRIPT" | grep -ci 'semver')
if [ "$c_142" -ge 1 ] && [ "$c_190" -ge 1 ] && [ "$c_semver" -ge 1 ]; then
  ok "8 documentaire D-05 : en-tête cite 1.42.3, 1.9.0 et semver"
else
  ko "8 documentaire D-05 : en-tête cite 1.42.3, 1.9.0 et semver" "142=$c_142 190=$c_190 semver=$c_semver"
fi

# === Cas 9 — scénario réel du rapport (D-11) : legacy + cache plugin planté « à jour » → toujours legacy
H="$(mk_gsd_home c9 "1.42.3")"; P="$(mk_gsd_project c9)"
mkdir -p "$H/.claude/plugins/cache/vibeflow-plugin"
printf '2.42.0' > "$H/.claude/plugins/cache/vibeflow-plugin/VERSION"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
has_sig=0; case "$out" in *"[gsd-migrate]"*) has_sig=1 ;; esac
c_cache=$(grep -v '^[[:space:]]*#' "$SCRIPT" | grep -c 'plugins/cache')
c_cpu=$(grep -v '^[[:space:]]*#' "$SCRIPT" | grep -c 'check-plugin-update')
if [ "$rc" -eq 0 ] && [ "$has_sig" -eq 1 ] && [ "$c_cache" -eq 0 ] && [ "$c_cpu" -eq 0 ]; then
  ok "9 scénario réel D-11 : legacy + cache plugin « à jour » → migration détectée, orthogonalité prouvée"
else
  ko "9 scénario réel D-11 : legacy + cache plugin « à jour » → migration détectée, orthogonalité prouvée" "rc=$rc out=[$out] cache=$c_cache cpu=$c_cpu"
fi

# === Cas 10 — discriminant de scope projet-local (miroir T2f) : $HOME vide, payload gsd-core en scope projet
H="$(mk_gsd_home c10)"; P="$(mk_gsd_project c10)"
mk_gsd_project_payload "$P" "1.8.0"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && [ -z "$out" ]; then ok "10 discriminant scope projet-local (miroir T2f) : détecté gsd-core, exit 3"; else ko "10 discriminant scope projet-local (miroir T2f) : détecté gsd-core, exit 3" "rc=$rc out=[$out]"; fi

# === Cas 11 — erreur d'usage : argument inconnu → exit 2, stdout vide, stderr non vide, jamais 1/64
errfile="$TMP/c11.err"
H="$(mk_gsd_home c11)"; P="$(mk_gsd_project c11)"
out="$( ( cd "$P" && env -u CLAUDE_CONFIG_DIR HOME="$H" bash "$SCRIPT" --flag-inconnu ) 2>"$errfile" )"; rc=$?
err="$(cat "$errfile")"
if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ -n "$err" ] && [ "$rc" -ne 1 ] && [ "$rc" -ne 64 ]; then
  ok "11 argument inconnu → exit 2, stdout vide, stderr non vide (jamais 1 ni 64)"
else
  ko "11 argument inconnu → exit 2, stdout vide, stderr non vide (jamais 1 ni 64)" "rc=$rc out=[$out] err=[$err]"
fi

# === Cas 12 — --help (exit 0, sortie non vide) et --quiet (stdout identique, stderr vide) =========
out_help="$(bash "$SCRIPT" --help 2>/dev/null)"; rc_help=$?
H="$(mk_gsd_home c12 "1.42.3")"; P="$(mk_gsd_project c12)"
out_plain="$(run_gate "$H" "$P" 2>/dev/null)"
out_quiet="$(run_gate "$H" "$P" --quiet 2>"$TMP/c12.err")"
err_quiet="$(cat "$TMP/c12.err")"
if [ "$rc_help" -eq 0 ] && [ -n "$out_help" ] && [ "$out_plain" = "$out_quiet" ] && [ -z "$err_quiet" ]; then
  ok "12 --help (exit 0, sortie non vide) et --quiet (stdout identique, stderr vide)"
else
  ko "12 --help (exit 0, sortie non vide) et --quiet (stdout identique, stderr vide)" "rc_help=$rc_help out_help=[$out_help] plain=[$out_plain] quiet=[$out_quiet] err_quiet=[$err_quiet]"
fi

# === Cas 13 — robustesse VERSION hostile (substitution de commande, octet de contrôle, >80 car.) =
HOSTILE="$(printf '$(whoami)\x01'; i=0; while [ "$i" -lt 90 ]; do printf 'A'; i=$((i+1)); done)"
H="$(mk_gsd_home c13)"
mkdir -p "$H/.claude/get-shit-done"
printf '%s' "$HOSTILE" > "$H/.claude/get-shit-done/VERSION"
P="$(mk_gsd_project c13)"
out="$(run_gate "$H" "$P" 2>/dev/null)"; rc=$?
CURRENT_USER="$(whoami)"
has_ctrl=0
case "$out" in *$'\x01'*) has_ctrl=1 ;; esac
long_line=$(printf '%s\n' "$out" | awk '{ print length }' | sort -rn | head -n1)
if [ "$rc" -eq 0 ] && ! printf '%s' "$out" | grep -qF "$CURRENT_USER" && [ "$has_ctrl" -eq 0 ] && [ "${long_line:-0}" -le 200 ]; then
  ok "13 robustesse VERSION hostile : rc=0, aucune expansion, aucun octet de contrôle, ligne bornée"
else
  ko "13 robustesse VERSION hostile : rc=0, aucune expansion, aucun octet de contrôle, ligne bornée" "rc=$rc out=[$out] long_line=$long_line"
fi

# === Cas 14 — bash -n passe sur check-gsd-engine.sh ================================================
if bash -n "$SCRIPT" 2>/dev/null; then ok "14 bash -n passe sur check-gsd-engine.sh"; else ko "14 bash -n passe sur check-gsd-engine.sh" "syntax error"; fi

# === Cas 15 — lecture seule : empreinte find identique avant/après (LC_ALL=C sort) =================
H="$(mk_gsd_home c15 "1.42.3" "1.8.0")"; P="$(mk_gsd_project c15)"
before="$(find "$H" "$P" | LC_ALL=C sort)"
run_gate "$H" "$P" >/dev/null 2>&1
after="$(find "$H" "$P" | LC_ALL=C sort)"
if [ "$before" = "$after" ]; then ok "15 lecture seule : empreinte find identique avant/après"; else ko "15 lecture seule : empreinte find identique avant/après" "before=[$before] after=[$after]"; fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
