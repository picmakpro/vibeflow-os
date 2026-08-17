#!/usr/bin/env bash
# test-notify.sh — Suite de vérification de notify.sh (canal de notification best-effort,
# Phase 33, WTCH-03/QUAL-01).
#
# N1  — darwin, terminal-notifier absent : osascript invoqué, argv exact du spike.
# N2  — darwin, terminal-notifier présent : lui seul invoqué (osascript jamais appelé).
# N3  — linux : notify-send invoqué, argv contient -a VibeFlow et les deux valeurs.
# N4  — windows : powershell.exe (jamais pwsh) invoqué par stdin, AUMID + ToastNotificationManager
#       dans le script PS, TITLE/BODY visibles en variables d'environnement.
# N5  — WSL + notify-send ET powershell.exe présents, DÉTECTION RÉELLE (pas forcée) : powershell.exe
#       choisi, notify-send JAMAIS invoqué — DISCRIMINANCE CLÉ, NE JAMAIS RETIRER.
# N6  — aucun canal disponible : exit 0, zéro invocation, stdout/stderr vides.
# N7  — valeurs hostiles (", `, $(...), <a&b>) : argv/env capturés bit à bit identiques à l'entrée.
# N8  — détachement mesuré côté process bash (retour avant écriture du fichier "terminé").
# N9  — arguments manquants : exit 0, zéro invocation.
# N10 — grep statique : vf_guard_unavailable absent de notify.sh.
# N11 — repli lib absente : notify.sh sort quand même 0 (jamais exit 1), canal forcé reste atteignable.
# N12 — shim présent mais non exécutable : traité comme absent, pas de fuite "permission denied".
# N13 — anti-vert-à-vide : le compteur d'assertions exécutées n'est jamais zéro.
# N14 — grep statique : set -e absent, set -uo pipefail présent.
# N15 — DISCRIMINANCE CLÉ, NE JAMAIS RETIRER : appelant qui capture stdout/stderr façon
#       subprocess.run(capture_output=True) reprend la main bien avant la fin du canal détaché —
#       seule mesure qui distingue un détachement réel d'un détachement de façade (cf. N8).
# N16 — invocation par CHEMIN RELATIF depuis un cwd différent : la résolution de vf-portable.sh
#       (donc le canal forcé) reste atteignable. COUVERTURE, PAS DISCRIMINANCE : voir la note
#       en tête du test — notify.sh ne fait jamais de `cd` interne après résolution, donc un
#       dirname "$0" brut et sa forme canonicalisée pointent vers le même fichier ici ; ce cas ne
#       rougit pas si on retire la canonicalisation (vérifié empiriquement, cf. correction ciblée).
#
# Convention du dossier (test-guard-driver-lock.sh) : set -uo pipefail sans -e, mktemp -d + trap
# EXIT, helpers assert/assert_empty/assert_exit, préflights séparés des assertions métier, garde
# d'épilogue anti-vert-à-vide.
#
# ZÉRO TOAST RÉEL : cette machine est un vrai macOS — chaque test qui n'utilise pas
# VF_NOTIFY_FORCE_CHANNEL isole PATH à un jeu de binaires curés (uname/dirname/grep/cat), sans
# jamais laisser /usr/bin:/bin réel dans PATH, pour empêcher un `osascript` réel d'être trouvé.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$HERE/.." && pwd)"
NOTIFY="$SCRIPTS_DIR/notify.sh"

PASS=0; FAIL=0; SKIPPED=0
assert()       { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_empty() { if [ -z "$2" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (sortie non vide)"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_exit()  { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }
assert_eq()    { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
preflight()    { if [ "$2" -eq 0 ]; then echo "  ✅ PREFLIGHT OK — $1"; PASS=$((PASS+1)); return 0; else echo "  ❌ PREFLIGHT FAIL — $1"; FAIL=$((FAIL+1)); return 1; fi; }
skip()         { echo "  ⊘ SKIP — $1"; SKIPPED=$((SKIPPED+1)); }

[ -f "$NOTIFY" ] || { echo "FATAL: notify.sh introuvable : $NOTIFY" >&2; exit 1; }
bash -n "$NOTIFY" || { echo "FATAL: notify.sh syntaxiquement invalide" >&2; exit 1; }

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# ---------- Jeu de binaires curés (jamais /usr/bin:/bin réel dans les PATH de test) ----------
# bash/python3 y figurent aussi : ce sont des utilitaires d'exécution du harnais de test, jamais
# des candidats de canal de notification (osascript/notify-send/powershell.exe/terminal-notifier
# restent délibérément absents de ce dossier).
UTIL_DIR="$WORK_DIR/utils"
mkdir -p "$UTIL_DIR"
for t in uname dirname grep cat bash python3 env sleep touch; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$UTIL_DIR/$t" 2>/dev/null
done

# ---------- Fabrique de shims — journalise argv (un token/ligne), stdin, env, compteur d'appels ----------
# [sleep_seconds] optionnel : dort avant de toucher <dir>/<name>.done (mesure de détachement).
write_shim() {
  local dir="$1" name="$2" sleep_s="${3:-}"
  {
    printf '#!/bin/bash\n'
    printf 'printf "%%s\\n" "$@" > %q 2>/dev/null\n' "$dir/$name.argv"
    printf 'cat > %q 2>/dev/null\n' "$dir/$name.stdin"
    printf 'env > %q 2>/dev/null\n' "$dir/$name.env"
    printf 'printf x >> %q\n' "$dir/$name.count"
    if [ -n "$sleep_s" ]; then
      printf 'sleep %q\n' "$sleep_s"
      printf 'touch %q\n' "$dir/$name.done"
    fi
    printf 'exit 0\n'
  } > "$dir/$name"
  chmod +x "$dir/$name"
}

call_count() { # dir name -> nombre d'appels (0 si jamais appelé)
  local f="$1/$2.count"
  [ -f "$f" ] && wc -c < "$f" | tr -d ' ' || echo 0
}

# Attente ACTIVE (jamais un sleep fixe fragile) : le canal réel est détaché en arrière-plan
# (( … & ) &), le délai de scheduling du fork n'est pas garanti sous une borne fixe — surtout au
# tout premier appel du process de test, et encore moins sur un poste chargé (flakiness mesurée :
# 3s trop court sur N4/N5/N11, cf. correction ciblée revue — 5 runs consécutifs, 1 à 2 FAIL par
# run avant durcissement). Poll jusqu'à ce que le fichier existe ou que le budget (par défaut 10s,
# gonflé en dur — jamais un sleep fixe rallongé, le pas de 0.1s garde la suite rapide dans le cas
# nominal) soit épuisé.
#
# CAUSE RÉELLE DE LA FLAKINESS RÉSIDUELLE (mesurée après le premier durcissement à 10s, toujours
# 4/10 runs en échec — grep_c/call_count sur .count restait à 0 malgré un .argv déjà présent) :
# write_shim() écrit .argv PUIS .stdin PUIS .env PUIS .count, séquentiellement, DANS LE MÊME
# PROCESS shim. Attendre .argv (premier fichier écrit) ne garantit PAS que .count (dernier fichier
# écrit, celui que call_count() lit réellement) soit déjà là — sous charge, la fenêtre entre les
# deux écritures suffit à faire lire un compteur encore vide. Le vrai correctif n'est pas la taille
# du budget mais la CIBLE du poll : attendre le DERNIER fichier écrit par le shim (.count, ou
# .done quand un sleep_s est fourni), jamais le premier — alors l'existence du marqueur garantit
# que tous les fichiers précédents (argv/stdin/env) sont déjà complets.
wait_for_file() { # path [timeout_seconds]
  local f="$1" budget="${2:-10}" waited=0
  while [ ! -f "$f" ]; do
    "$UTIL_DIR/sleep" 0.1 2>/dev/null || sleep 0.1
    waited=$(( waited + 1 ))
    [ "$waited" -ge $(( budget * 10 )) ] && break
  done
  [ -f "$f" ]
}

echo "=== N1 — darwin, terminal-notifier absent : osascript invoqué, argv exact ==="
N1_DIR="$WORK_DIR/n1"; mkdir -p "$N1_DIR"
write_shim "$N1_DIR" osascript
N1_RC=0
env PATH="$N1_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin bash "$NOTIFY" "Titre N1" "Corps N1" >/dev/null 2>&1 || N1_RC=$?
wait_for_file "$N1_DIR/osascript.count" 10
assert_exit "N1 — notify.sh sort 0" "$N1_RC" 0
N1_ARGV="$(cat "$N1_DIR/osascript.argv" 2>/dev/null || true)"
assert "N1 — argv contient 'on run argv'" "$N1_ARGV" "on run argv"
assert "N1 — argv contient la clause display notification" "$N1_ARGV" 'display notification (item 2 of argv) with title (item 1 of argv)'
assert "N1 — argv contient 'end run'" "$N1_ARGV" "end run"
assert "N1 — argv porte Titre N1" "$N1_ARGV" "Titre N1"
assert "N1 — argv porte Corps N1" "$N1_ARGV" "Corps N1"

echo ""
echo "=== N2 — darwin, terminal-notifier présent : lui seul invoqué ==="
N2_DIR="$WORK_DIR/n2"; mkdir -p "$N2_DIR"
write_shim "$N2_DIR" osascript
write_shim "$N2_DIR" terminal-notifier
env PATH="$N2_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin bash "$NOTIFY" "Titre N2" "Corps N2" >/dev/null 2>&1
wait_for_file "$N2_DIR/terminal-notifier.count" 10
N2_TN="$(call_count "$N2_DIR" terminal-notifier)"
N2_OS="$(call_count "$N2_DIR" osascript)"
assert "N2 — terminal-notifier invoqué (compteur > 0)" "$([ "$N2_TN" != "0" ] && echo yes || echo no)" "yes"
assert_eq "N2 — osascript JAMAIS invoqué (compteur = 0)" "$N2_OS" "0"
N2_ARGV="$(cat "$N2_DIR/terminal-notifier.argv" 2>/dev/null || true)"
assert "N2 — argv terminal-notifier porte Titre N2" "$N2_ARGV" "Titre N2"
assert "N2 — argv terminal-notifier porte Corps N2" "$N2_ARGV" "Corps N2"

echo ""
echo "=== N3 — linux : notify-send invoqué, -a VibeFlow + les deux valeurs ==="
N3_DIR="$WORK_DIR/n3"; mkdir -p "$N3_DIR"
write_shim "$N3_DIR" notify-send
env PATH="$N3_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=linux bash "$NOTIFY" "Titre N3" "Corps N3" >/dev/null 2>&1
wait_for_file "$N3_DIR/notify-send.count" 10
N3_ARGV="$(cat "$N3_DIR/notify-send.argv" 2>/dev/null || true)"
assert "N3 — argv contient -a" "$N3_ARGV" "-a"
assert "N3 — argv contient VibeFlow" "$N3_ARGV" "VibeFlow"
assert "N3 — argv porte Titre N3" "$N3_ARGV" "Titre N3"
assert "N3 — argv porte Corps N3" "$N3_ARGV" "Corps N3"

echo ""
echo "=== N4 — windows : powershell.exe (jamais pwsh) par stdin, AUMID + ToastNotificationManager ==="
N4_DIR="$WORK_DIR/n4"; mkdir -p "$N4_DIR"
write_shim "$N4_DIR" powershell.exe
env PATH="$N4_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=windows bash "$NOTIFY" "Titre N4" "Corps N4" >/dev/null 2>&1
wait_for_file "$N4_DIR/powershell.exe.count" 10
N4_ARGV="$(cat "$N4_DIR/powershell.exe.argv" 2>/dev/null || true)"
N4_STDIN="$(cat "$N4_DIR/powershell.exe.stdin" 2>/dev/null || true)"
N4_ENV="$(cat "$N4_DIR/powershell.exe.env" 2>/dev/null || true)"
assert "N4 — argv contient -NoProfile" "$N4_ARGV" "-NoProfile"
assert "N4 — argv contient -NonInteractive" "$N4_ARGV" "-NonInteractive"
assert "N4 — argv contient -Command" "$N4_ARGV" "-Command"
assert "N4 — stdin contient ToastNotificationManager" "$N4_STDIN" "ToastNotificationManager"
assert "N4 — stdin contient l'AUMID PowerShell littéral" "$N4_STDIN" '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
assert "N4 — env porte VF_NOTIFY_TITLE=Titre N4" "$N4_ENV" "VF_NOTIFY_TITLE=Titre N4"
assert "N4 — env porte VF_NOTIFY_BODY=Corps N4" "$N4_ENV" "VF_NOTIFY_BODY=Corps N4"

echo ""
echo "=== N5 (DISCRIMINANCE CLÉ, NE JAMAIS RETIRER) — WSL détecté réellement : powershell.exe choisi, notify-send JAMAIS invoqué ==="
N5_DIR="$WORK_DIR/n5"; mkdir -p "$N5_DIR"
write_shim "$N5_DIR" powershell.exe
write_shim "$N5_DIR" notify-send
cat > "$N5_DIR/uname" <<'SH'
#!/bin/bash
echo Linux
SH
chmod +x "$N5_DIR/uname"
N5_PROC="$WORK_DIR/n5-proc-version"
printf 'Linux version 5.15.0-microsoft-standard-WSL2\n' > "$N5_PROC"
env PATH="$N5_DIR:$UTIL_DIR" VF_PROC_VERSION_PATH="$N5_PROC" bash "$NOTIFY" "Titre N5" "Corps N5" >/dev/null 2>&1
wait_for_file "$N5_DIR/powershell.exe.count" 10
N5_PS="$(call_count "$N5_DIR" powershell.exe)"
N5_NS="$(call_count "$N5_DIR" notify-send)"
assert "N5 — powershell.exe invoqué (compteur > 0), détection RÉELLE via IS_WSL" "$([ "$N5_PS" != "0" ] && echo yes || echo no)" "yes"
assert_eq "N5 — notify-send JAMAIS invoqué (compteur = 0) — ne jamais retirer" "$N5_NS" "0"

echo ""
echo "=== N6 — aucun canal disponible : exit 0, zéro invocation, stdout/stderr vides ==="
N6_OUT_FILE="$WORK_DIR/n6.out"; N6_ERR_FILE="$WORK_DIR/n6.err"
N6_RC=0
env PATH="$UTIL_DIR" bash "$NOTIFY" "Titre N6" "Corps N6" >"$N6_OUT_FILE" 2>"$N6_ERR_FILE" || N6_RC=$?
assert_exit "N6 — exit 0 même sans aucun canal" "$N6_RC" 0
assert_empty "N6 — stdout vide" "$(cat "$N6_OUT_FILE")"
assert_empty "N6 — stderr vide" "$(cat "$N6_ERR_FILE")"

echo ""
echo "=== N7 — valeurs hostiles : argv/env capturés bit à bit identiques à l'entrée ==="
HOSTILE_TITLE='titre " backtick ` $(cmd) <a&b>'
HOSTILE_BODY='corps " backtick ` $(cmd) <a&b>'
N7D_DIR="$WORK_DIR/n7d"; mkdir -p "$N7D_DIR"
write_shim "$N7D_DIR" osascript
env PATH="$N7D_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin bash "$NOTIFY" "$HOSTILE_TITLE" "$HOSTILE_BODY" >/dev/null 2>&1
wait_for_file "$N7D_DIR/osascript.count" 10
N7D_LAST2="$(tail -n2 "$N7D_DIR/osascript.argv" 2>/dev/null)"
N7D_EXPECTED="$(printf '%s\n%s' "$HOSTILE_TITLE" "$HOSTILE_BODY")"
assert_eq "N7 — darwin : les deux derniers tokens argv = TITLE/BODY hostiles bit à bit" "$N7D_LAST2" "$N7D_EXPECTED"

N7L_DIR="$WORK_DIR/n7l"; mkdir -p "$N7L_DIR"
write_shim "$N7L_DIR" notify-send
env PATH="$N7L_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=linux bash "$NOTIFY" "$HOSTILE_TITLE" "$HOSTILE_BODY" >/dev/null 2>&1
wait_for_file "$N7L_DIR/notify-send.count" 10
N7L_LAST2="$(tail -n2 "$N7L_DIR/notify-send.argv" 2>/dev/null)"
assert_eq "N7 — linux : les deux derniers tokens argv = TITLE/BODY hostiles bit à bit" "$N7L_LAST2" "$N7D_EXPECTED"

N7W_DIR="$WORK_DIR/n7w"; mkdir -p "$N7W_DIR"
write_shim "$N7W_DIR" powershell.exe
env PATH="$N7W_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=windows bash "$NOTIFY" "$HOSTILE_TITLE" "$HOSTILE_BODY" >/dev/null 2>&1
wait_for_file "$N7W_DIR/powershell.exe.count" 10
N7W_ENV="$(cat "$N7W_DIR/powershell.exe.env" 2>/dev/null || true)"
assert "N7 — windows : env VF_NOTIFY_TITLE hostile identique bit à bit" "$N7W_ENV" "VF_NOTIFY_TITLE=$HOSTILE_TITLE"
assert "N7 — windows : env VF_NOTIFY_BODY hostile identique bit à bit" "$N7W_ENV" "VF_NOTIFY_BODY=$HOSTILE_BODY"

echo ""
echo "=== N8 — détachement (mesure côté process bash) : retour avant écriture du fichier terminé ==="
N8_DIR="$WORK_DIR/n8"; mkdir -p "$N8_DIR"
write_shim "$N8_DIR" osascript 2
N8_RC=0
env PATH="$N8_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin bash "$NOTIFY" "Titre N8" "Corps N8" >/dev/null 2>&1 || N8_RC=$?
assert_exit "N8 — notify.sh rend la main (process bash), exit 0" "$N8_RC" 0
if [ -f "$N8_DIR/osascript.done" ]; then
  echo "  ❌ FAIL — N8 le fichier .done existe déjà juste après le retour de notify.sh (pas détaché)"; FAIL=$((FAIL+1))
else
  echo "  ✅ PASS — N8 le fichier .done n'existe pas encore juste après le retour (détachement)"; PASS=$((PASS+1))
fi
wait_for_file "$N8_DIR/osascript.done" 10
[ -f "$N8_DIR/osascript.done" ] && N8_EVENTUAL=yes || N8_EVENTUAL=no
assert "N8 — le shim a fini par tourner en arrière-plan (.done finit par apparaître)" "$N8_EVENTUAL" "yes"

echo ""
echo "=== N9 — arguments manquants : exit 0, zéro invocation ==="
N9A_DIR="$WORK_DIR/n9a"; mkdir -p "$N9A_DIR"
write_shim "$N9A_DIR" osascript
N9A_RC=0
env PATH="$N9A_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin bash "$NOTIFY" >/dev/null 2>&1 || N9A_RC=$?
assert_exit "N9 — sans aucun argument : exit 0" "$N9A_RC" 0
assert_eq "N9 — sans aucun argument : zéro invocation osascript" "$(call_count "$N9A_DIR" osascript)" "0"

N9B_DIR="$WORK_DIR/n9b"; mkdir -p "$N9B_DIR"
write_shim "$N9B_DIR" osascript
N9B_RC=0
env PATH="$N9B_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin bash "$NOTIFY" "Titre seul" >/dev/null 2>&1 || N9B_RC=$?
assert_exit "N9 — TITLE seul (BODY absent) : exit 0" "$N9B_RC" 0
assert_eq "N9 — TITLE seul : zéro invocation osascript" "$(call_count "$N9B_DIR" osascript)" "0"

echo ""
echo "=== N10 — grep statique : la fonction de marqueur de garde n'est jamais appelée dans notify.sh ==="
N10_COUNT="$(grep -c 'vf_guard_unavailable' "$NOTIFY")"
assert_eq "N10 — grep -c vf_guard_unavailable notify.sh == 0" "$N10_COUNT" "0"

echo ""
echo "=== N11 — repli lib absente : notify.sh sort quand même 0 (jamais exit 1), canal forcé reste atteignable ==="
N11_ISO="$WORK_DIR/n11-isolated"
mkdir -p "$N11_ISO"
cp "$NOTIFY" "$N11_ISO/notify.sh"
N11_RC=0
env PATH="$UTIL_DIR" bash "$N11_ISO/notify.sh" "Titre N11" "Corps N11" >/dev/null 2>&1 || N11_RC=$?
assert_exit "N11 — aucun candidat vf-portable.sh trouvable : exit 0 quand même (jamais 1)" "$N11_RC" 0
N11W_DIR="$WORK_DIR/n11w"; mkdir -p "$N11W_DIR"
write_shim "$N11W_DIR" powershell.exe
env PATH="$N11W_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=windows bash "$N11_ISO/notify.sh" "Titre N11f" "Corps N11f" >/dev/null 2>&1
wait_for_file "$N11W_DIR/powershell.exe.count" 10
assert "N11 — canal forcé reste atteignable malgré la lib absente (powershell.exe invoqué)" "$([ "$(call_count "$N11W_DIR" powershell.exe)" != "0" ] && echo yes || echo no)" "yes"

echo ""
echo "=== N12 — shim présent mais non exécutable : traité comme absent, pas de fuite ==="
N12_DIR="$WORK_DIR/n12"; mkdir -p "$N12_DIR"
write_shim "$N12_DIR" osascript
chmod -x "$N12_DIR/osascript"
N12_OUT="$WORK_DIR/n12.out"; N12_ERR="$WORK_DIR/n12.err"
N12_RC=0
env PATH="$N12_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin bash "$NOTIFY" "Titre N12" "Corps N12" >"$N12_OUT" 2>"$N12_ERR" || N12_RC=$?
sleep 0.3
assert_exit "N12 — shim non exécutable : exit 0 quand même" "$N12_RC" 0
assert_empty "N12 — stdout vide" "$(cat "$N12_OUT")"
assert_empty "N12 — stderr vide (pas de 'permission denied' qui fuit)" "$(cat "$N12_ERR")"
assert_eq "N12 — zéro invocation journalisée (shim non exécutable jamais lancé)" "$(call_count "$N12_DIR" osascript)" "0"

echo ""
echo "=== N13 — anti-vert-à-vide : le compteur d'assertions exécutées n'est jamais zéro ==="
N13_TOTAL=$((PASS+FAIL))
assert_eq "N13 — au moins une assertion exécutée avant l'épilogue (jamais 0)" "$([ "$N13_TOTAL" -gt 0 ] && echo 1 || echo 0)" "1"

echo ""
echo "=== N14 — grep statique : set -e absent, set -uo pipefail présent ==="
assert_eq "N14 — grep -c '^set -e' notify.sh == 0" "$(grep -c '^set -e' "$NOTIFY")" "0"
N14_HAS_PIPEFAIL=0
grep -qE 'set -uo pipefail' "$NOTIFY" && N14_HAS_PIPEFAIL=1
assert_eq "N14 — 'set -uo pipefail' présent" "$N14_HAS_PIPEFAIL" "1"

echo ""
echo "=== N15 (DISCRIMINANCE CLÉ, NE JAMAIS RETIRER) — appelant capturant reprend la main AVANT la fin du canal ==="
if command -v python3 >/dev/null 2>&1; then
  N15_DIR="$WORK_DIR/n15"; mkdir -p "$N15_DIR"
  write_shim "$N15_DIR" osascript 3
  N15_ELAPSED=$(PATH="$N15_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=darwin python3 -c "
import subprocess, time, os, sys
env = dict(os.environ)
t0 = time.time()
subprocess.run(['bash', '$NOTIFY', 'Titre N15', 'Corps N15'], capture_output=True, env=env)
print(time.time() - t0)
")
  N15_OK=0
  python3 -c "import sys; sys.exit(0 if float('$N15_ELAPSED') < 1.5 else 1)" 2>/dev/null && N15_OK=1
  if [ "$N15_OK" = "1" ]; then
    echo "  ✅ PASS — N15 appelant capturant (subprocess.run capture_output=True) reprend la main en ${N15_ELAPSED}s (< 1.5s, shim dort 3s)"
    PASS=$((PASS+1))
  else
    echo "  ❌ FAIL — N15 appelant capturant a mis ${N15_ELAPSED}s à reprendre la main (attendu < 1.5s, shim dort 3s) — détachement de façade ?"
    FAIL=$((FAIL+1))
  fi
else
  skip "N15 — python3 indisponible, appelant capturant non mesurable"
fi

echo ""
echo "=== N16 — invocation par chemin RELATIF depuis un cwd différent : canal forcé atteignable ==="
# NOTE HONNÊTETÉ (correction ciblée revue, MAJEUR 1) : ce cas est une couverture, PAS un cas
# discriminant par mutation. notify.sh ne fait jamais lui-même de `cd` après avoir résolu
# _vf_notify_dir — la résolution de vf-portable.sh se fait par simple concaténation de chaîne,
# jamais par `cd` dans le répertoire résolu. Tant qu'aucun `cd` interne n'existe, un dirname "$0"
# brut et un `cd "$(dirname "$0")" && pwd` canonicalisé pointent vers EXACTEMENT le même fichier
# pour toute invocation par chemin relatif où le cwd ne change pas en cours de script — y compris
# celle exercée ici. Revert de la canonicalisation (mutation) laisse donc CE cas vert : ce test
# documente la non-régression (chemin relatif reste atteignable) et referme le trou de couverture
# signalé par la revue ("non couvert par test-notify.sh"), sans prétendre prouver un rouge sous
# mutation que le code ne permet pas de produire ici (vérifié empiriquement en correction ciblée :
# `cd`/`pwd` sans -P suit la même résolution logique que la concaténation brute tant qu'aucun `cd`
# n'intervient entre-temps — aucun scénario ne fait rougir ce test précis sous cette mutation).
N16_CWD="$WORK_DIR/n16-cwd"; mkdir -p "$N16_CWD"
# realpath() des deux côtés, PAS le chemin logique brut : sur macOS, $WORK_DIR (mktemp -d) vit
# sous /var/folders/... qui est lui-même un symlink vers /private/var/folders/... — un relpath
# calculé sur la forme logique compte un niveau de moins que ce que le kernel résout après un `cd`
# réel, et le "../../..." obtenu pointe à côté (127, "No such file or directory" mesuré ici même).
N16_REL="$(python3 -c "import os,sys; print(os.path.relpath(os.path.realpath(sys.argv[1]), os.path.realpath(sys.argv[2])))" "$NOTIFY" "$N16_CWD" 2>/dev/null || true)"
if [ -n "$N16_REL" ]; then
  N16_DIR="$WORK_DIR/n16"; mkdir -p "$N16_DIR"
  write_shim "$N16_DIR" powershell.exe
  N16_RC=0
  ( cd "$N16_CWD" && env PATH="$N16_DIR:$UTIL_DIR" VF_NOTIFY_FORCE_CHANNEL=windows bash "$N16_REL" "Titre N16" "Corps N16" >/dev/null 2>&1 ) || N16_RC=$?
  wait_for_file "$N16_DIR/powershell.exe.count" 10
  assert_exit "N16 — invocation par chemin relatif depuis un cwd différent : exit 0" "$N16_RC" 0
  assert "N16 — canal forcé atteignable via chemin relatif (powershell.exe invoqué)" "$([ "$(call_count "$N16_DIR" powershell.exe)" != "0" ] && echo yes || echo no)" "yes"
else
  skip "N16 — python3 indisponible, chemin relatif non calculable"
fi

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL / $SKIPPED SKIP"
echo "=================================="
# Garde anti-vert-à-vide STRUCTURELLE dans l'épilogue lui-même — pas seulement N13 mid-suite
# (qui pourrait être neutralisé en même temps que le reste) : si AUCUNE assertion n'a tourné
# (PASS+FAIL == 0), le résultat n'est jamais un succès, quel que soit FAIL.
if [ "$((PASS+FAIL))" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
