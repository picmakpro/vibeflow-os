#!/usr/bin/env bash
# test-check-guard-health.sh — Suite de vérification de check-guard-health.sh (QUAL-01, D-32-05).
#
# Un cas par comportement du contrat (cf. en-tête du script). Fixtures ISOLÉES via mktemp -d +
# --dir=<repertoire fictif> : AUCUN cas ne doit pouvoir lire ou toucher le vrai repertoire de
# sante du poste (préflight dédié ci-dessous, sortie 2 en cas d'échec — fixture cassée, pas un
# verdict). Chaque assertion capture stdout ET le code de retour dans deux variables distinctes,
# assertées séparément — jamais l'une déduite de l'autre.
#
# D13 (boucle producteur -> marqueur -> lecteur, bout en bout avec guard-driver-lock.sh réel) est
# AJOUTÉ par la tâche 2 de ce plan — pas dans ce fichier au moment de la tâche 1.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-guard-health.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }

WORK_DIR="$(mktemp -d)"
trap 'chmod -R 755 "$WORK_DIR" 2>/dev/null; rm -rf "$WORK_DIR"' EXIT

# --- Préflight anti-fixture-réelle : AUCUN cas de cette suite n'a le droit d'invoquer le script
# sans --dir explicite pointant SOUS $WORK_DIR — sinon un test pourrait lire (ou pire, sous une
# régression future, écrire) le vrai repertoire de sante du poste qui l'exécute. -----------------
case "$WORK_DIR" in
  /*) : ;;
  *) echo "PRÉFLIGHT FIXTURE CASSÉ — WORK_DIR non absolu : $WORK_DIR" >&2; exit 2 ;;
esac
[ -d "$WORK_DIR" ] || { echo "PRÉFLIGHT FIXTURE CASSÉ — WORK_DIR introuvable : $WORK_DIR" >&2; exit 2; }

echo "== test-check-guard-health =="

# Écrit un marqueur au FORMAT RÉEL de vf_guard_unavailable (plugin/_internal/lib/vf-portable.sh:152) :
# une ligne "horodatage-ISO8601-UTC\tscript\tmotif\n". Fixture consignée mot pour mot dans le
# SUMMARY pour qu'une future évolution du format côté lib soit repérable.
write_marker() { # <dir> <filename-sans-suffixe> <ts-iso8601> <script> <motif>
  mkdir -p "$1"
  printf '%s\t%s\t%s\n' "$3" "$4" "$5" > "$1/$2.marker"
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
old_iso() { # <jours>
  date -u -v-"$1"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "$1 days ago" +%Y-%m-%dT%H:%M:%SZ
}

# === D2 — répertoire de santé EXISTANT et VIDE : SAIN, stdout STRICTEMENT VIDE ===================
D2_DIR="$WORK_DIR/d2-empty"; mkdir -p "$D2_DIR"
D2_OUT="$(bash "$SCRIPT" --dir="$D2_DIR" 2>/dev/null)"; D2_RC=$?
[ "$D2_RC" -eq 3 ] && ok "D2 : répertoire vide → exit 3 (SAIN)" || ko "D2 exit" "rc=$D2_RC attendu 3"
[ -z "$D2_OUT" ] && ok "D2 : stdout strictement vide" || ko "D2 stdout" "out=[$D2_OUT]"

# === D3 — répertoire de santé ABSENT : même verdict SAIN que D2 ===================================
D3_DIR="$WORK_DIR/d3-absent"
D3_OUT="$(bash "$SCRIPT" --dir="$D3_DIR" 2>/dev/null)"; D3_RC=$?
[ "$D3_RC" -eq 3 ] && ok "D3 : répertoire absent → exit 3 (SAIN)" || ko "D3 exit" "rc=$D3_RC attendu 3"
[ -z "$D3_OUT" ] && ok "D3 : stdout strictement vide" || ko "D3 stdout" "out=[$D3_OUT]"

# === D1 — signal : un marqueur RÉCENT redirige vers exit 0, une ligne nommant script + motif =====
D1_DIR="$WORK_DIR/d1-fresh"
write_marker "$D1_DIR" "some-guard.sh" "$(now_iso)" "some-guard.sh" "aucun interprète Python utilisable"
D1_OUT="$(bash "$SCRIPT" --dir="$D1_DIR" 2>/dev/null)"; D1_RC=$?
[ "$D1_RC" -eq 0 ] && ok "D1 : marqueur récent → exit 0 (signal)" || ko "D1 exit" "rc=$D1_RC attendu 0"
case "$D1_OUT" in
  *"some-guard.sh"*"aucun interprète Python utilisable"*) ok "D1 : signal nomme script et motif" ;;
  *) ko "D1 contenu" "out=[$D1_OUT]" ;;
esac
D1_LINES="$(printf '%s\n' "$D1_OUT" | wc -l | tr -d ' ')"
[ "$D1_LINES" -eq 1 ] && ok "D1 : exactement UNE ligne" || ko "D1 nb lignes" "=$D1_LINES attendu 1"

# === D5 — marqueur PÉRIMÉ (au-delà de la fenêtre de rapport) : non signalé, verdict SAIN ==========
# Fenêtre par défaut 86400s (24h) ; l'horodatage forgé est délibérément ANCIEN (30 jours), jamais
# une attente réelle (aucun sleep dans cette suite).
D5_DIR="$WORK_DIR/d5-stale"
write_marker "$D5_DIR" "old-guard.sh" "$(old_iso 30)" "old-guard.sh" "motif ancien, panne cessée"
D5_OUT="$(bash "$SCRIPT" --dir="$D5_DIR" 2>/dev/null)"; D5_RC=$?
[ "$D5_RC" -eq 3 ] && ok "D5 : marqueur périmé → exit 3 (SAIN, jamais signalé)" || ko "D5 exit" "rc=$D5_RC attendu 3"
[ -z "$D5_OUT" ] && ok "D5 : stdout strictement vide" || ko "D5 stdout" "out=[$D5_OUT]"
# Surcharge explicite de la fenêtre : le même marqueur devient un signal sous une fenêtre plus large.
D5B_OUT="$(bash "$SCRIPT" --dir="$D5_DIR" --window=31536000 2>/dev/null)"; D5B_RC=$?
[ "$D5B_RC" -eq 0 ] && ok "D5b : même marqueur, fenêtre élargie → exit 0 (signal)" || ko "D5b exit" "rc=$D5B_RC attendu 0"

# === D4 — répertoire présent mais ILLISIBLE (panne injectée) : INDÉTERMINÉ, jamais SAIN ===========
D4_DIR="$WORK_DIR/d4-unreadable"; mkdir -p "$D4_DIR"
: > "$D4_DIR/x.marker"
chmod 000 "$D4_DIR"
D4_ERR="$WORK_DIR/d4.err"
# Restauration des permissions GARANTIE quoi qu'il arrive (y compris si l'assertion échoue) — sinon
# le nettoyage final du répertoire de travail échouerait à supprimer $D4_DIR.
D4_OUT="$(bash "$SCRIPT" --dir="$D4_DIR" 2>"$D4_ERR")"; D4_RC=$?
D4_STDERR="$(cat "$D4_ERR" 2>/dev/null)"
chmod 755 "$D4_DIR"
[ "$D4_RC" -eq 4 ] && ok "D4 : répertoire illisible → exit 4 (INDÉTERMINÉ)" || ko "D4 exit" "rc=$D4_RC attendu 4 (JAMAIS 3)"
[ -z "$D4_OUT" ] && ok "D4 : stdout vide (diagnostic sur stderr seul)" || ko "D4 stdout" "out=[$D4_OUT]"
case "$D4_STDERR" in *INDETERMINE*) ok "D4 : diagnostic dit INDÉTERMINÉ sur stderr" ;; *) ko "D4 stderr" "$D4_STDERR" ;; esac
# Sous --hook, l'INDÉTERMINÉ se traduit vers 0 au harness — mais reste INDÉTERMINÉ en interne :
# stdout doit rester vide (jamais un signal fantôme).
chmod 000 "$D4_DIR"
D4H_OUT="$(bash "$SCRIPT" --dir="$D4_DIR" --hook 2>/dev/null)"; D4H_RC=$?
chmod 755 "$D4_DIR"
[ "$D4H_RC" -eq 0 ] && ok "D4/--hook : INDÉTERMINÉ traduit en 0 au harness" || ko "D4/--hook exit" "rc=$D4H_RC attendu 0"
[ -z "$D4H_OUT" ] && ok "D4/--hook : stdout toujours vide" || ko "D4/--hook stdout" "out=[$D4H_OUT]"

# === D6 — compacité : QUATRE marqueurs récents → UNE SEULE ligne, portant le compte ===============
D6_DIR="$WORK_DIR/d6-compact"
write_marker "$D6_DIR" "guard-a.sh" "$(now_iso)" "guard-a.sh" "motif a"
write_marker "$D6_DIR" "guard-b.sh" "$(now_iso)" "guard-b.sh" "motif b"
write_marker "$D6_DIR" "guard-c.sh" "$(now_iso)" "guard-c.sh" "motif c"
write_marker "$D6_DIR" "guard-d.sh" "$(now_iso)" "guard-d.sh" "motif d"
D6_OUT="$(bash "$SCRIPT" --dir="$D6_DIR" 2>/dev/null)"; D6_RC=$?
[ "$D6_RC" -eq 0 ] && ok "D6 : quatre marqueurs récents → exit 0" || ko "D6 exit" "rc=$D6_RC attendu 0"
D6_LINES="$(printf '%s\n' "$D6_OUT" | wc -l | tr -d ' ')"
[ "$D6_LINES" -eq 1 ] && ok "D6 : UNE SEULE ligne malgré 4 marqueurs (jamais 4)" || ko "D6 nb lignes" "=$D6_LINES attendu 1"
case "$D6_OUT" in *"4"*) ok "D6 : la ligne porte le compte (4)" ;; *) ko "D6 compte" "out=[$D6_OUT]" ;; esac

# === D7 — marqueurs MALFORMÉS : vide, sans tabulation, binaire — jamais de plantage ================
D7_DIR="$WORK_DIR/d7-malformed"; mkdir -p "$D7_DIR"
: > "$D7_DIR/empty.sh.marker"
printf 'juste-du-texte-sans-tabulation\n' > "$D7_DIR/notab.sh.marker"
printf '\x00\x01\xff\xfe binaire \x00' > "$D7_DIR/binary.sh.marker"
D7_OUT="$(bash "$SCRIPT" --dir="$D7_DIR" 2>/dev/null)"; D7_RC=$?
case "$D7_RC" in
  0|3) ok "D7 : marqueurs malformés → code dans {signal, SAIN} (=$D7_RC), jamais de plantage" ;;
  *) ko "D7 exit" "rc=$D7_RC hors de {0,3}" ;;
esac
D7_LINES="$(printf '%s\n' "$D7_OUT" | grep -c . 2>/dev/null || echo 0)"
[ "$D7_LINES" -le 1 ] && ok "D7 : au plus une ligne sur stdout" || ko "D7 nb lignes" "=$D7_LINES attendu <=1"

# === D10 — argument inconnu : erreur d'usage (64), stdout vide ====================================
D10_OUT="$(bash "$SCRIPT" --argument-inconnu 2>/dev/null)"; D10_RC=$?
[ "$D10_RC" -eq 64 ] && ok "D10 : argument inconnu → exit 64" || ko "D10 exit" "rc=$D10_RC attendu 64"
[ -z "$D10_OUT" ] && ok "D10 : stdout vide sur erreur d'usage" || ko "D10 stdout" "out=[$D10_OUT]"
# Usage ne se traduit JAMAIS sous --hook.
D10H_RC=0; bash "$SCRIPT" --argument-inconnu --hook >/dev/null 2>&1 || D10H_RC=$?
[ "$D10H_RC" -eq 64 ] && ok "D10/--hook : erreur d'usage JAMAIS traduite (reste 64)" || ko "D10/--hook exit" "rc=$D10H_RC attendu 64"

# === D11 — GÉNÉRICITÉ : un marqueur d'un garde d'un AUTRE module est signalé identiquement =========
# Le lecteur ne connaît AUCUN garde en particulier — c'est ce qui justifie l'extension de périmètre.
D11_DIR="$WORK_DIR/d11-generic"
write_marker "$D11_DIR" "guard-file-size.sh" "$(now_iso)" "guard-file-size.sh" "interprète absent (software-architecture)"
D11_OUT="$(bash "$SCRIPT" --dir="$D11_DIR" 2>/dev/null)"; D11_RC=$?
[ "$D11_RC" -eq 0 ] && ok "D11 : garde d'un AUTRE module (software-architecture) → signalé pareil" || ko "D11 exit" "rc=$D11_RC attendu 0"
case "$D11_OUT" in *"guard-file-size.sh"*) ok "D11 : nomme le garde d'un module tiers" ;; *) ko "D11 contenu" "out=[$D11_OUT]" ;; esac

# === D9 — LECTURE SEULE STRICTE : le contenu du répertoire est IDENTIQUE avant/après ==============
D9_DIR="$WORK_DIR/d9-readonly"
write_marker "$D9_DIR" "guard-x.sh" "$(now_iso)" "guard-x.sh" "motif x"
snapshot() { ( cd "$1" && find . -type f -exec sh -c 'printf "%s %s %s\n" "$1" "$(wc -c < "$1" | tr -d " ")" "$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1")"' _ {} \; | sort ); }
D9_BEFORE="$(snapshot "$D9_DIR")"
bash "$SCRIPT" --dir="$D9_DIR" >/dev/null 2>&1
D9_AFTER="$(snapshot "$D9_DIR")"
[ "$D9_BEFORE" = "$D9_AFTER" ] && ok "D9 : répertoire de santé INCHANGÉ après exécution (liste, tailles, mtimes)" || ko "D9 lecture seule" "avant=[$D9_BEFORE] après=[$D9_AFTER]"

echo ""
echo "=== D12 — anti-vert-à-vide : le compteur d'assertions exécutées n'est jamais zéro ==="
D12_TOTAL=$((PASS+FAIL))
[ "$D12_TOTAL" -gt 0 ] && ok "D12 : au moins une assertion exécutée (=$D12_TOTAL, jamais 0)" || ko "D12" "total=$D12_TOTAL"

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
# Garde anti-vert-à-vide STRUCTURELLE, dans l'épilogue lui-même (même patron que
# test-guard-driver-lock.sh) : si AUCUNE assertion n'a tourné, le résultat n'est jamais un succès.
if [ "$((PASS+FAIL))" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
