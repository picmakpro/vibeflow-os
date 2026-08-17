#!/usr/bin/env bash
# test-check-guard-health.sh — Suite de vérification de check-guard-health.sh (QUAL-01, D-32-05).
#
# Un cas par comportement du contrat (cf. en-tête du script). Fixtures ISOLÉES via mktemp -d +
# --dir=<repertoire fictif> : AUCUN cas ne doit pouvoir lire ou toucher le vrai repertoire de
# sante du poste (préflight dédié ci-dessous, sortie 2 en cas d'échec — fixture cassée, pas un
# verdict). Chaque assertion capture stdout ET le code de retour dans deux variables distinctes,
# assertées séparément — jamais l'une déduite de l'autre.
#
# D13 (tâche 2) : boucle producteur -> marqueur -> lecteur, bout en bout avec le VRAI
# guard-driver-lock.sh (plan 32-03) — reprend le montage du cas Q4 de sa propre suite
# (test-guard-driver-lock.sh), pas de marqueur fabriqué à la main.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-guard-health.sh"
GUARD_LOCK="$(cd "$(dirname "$0")/.." && pwd)/guard-driver-lock.sh"
DRIVER_LOCK="$(cd "$(dirname "$0")/.." && pwd)/driver-lock.sh"
BASH_BIN="${BASH:-bash}"

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

# --- Isolation VF_DRIVER_LOCK, PAR DÉFAUT, pour TOUTE la suite (correctif ciblé, mandat 2026-08-17,
# Bloquant 2) : check_driver_stall() dans check-guard-health.sh lit TOUJOURS `driver-lock.sh
# status`, y compris pour les cas hérités D1-D7/D9-D11 qui ne le savent pas. Sans cet export, ces
# cas hériteraient du VRAI verrou de pilotage du dépôt (.planning/DRIVER.lock, defaut de
# driver-lock.sh en l'absence de VF_DRIVER_LOCK) — vert en CI (pas de lock), rouge sur le poste
# d'un développeur pendant une mission réelle. Chemin JAMAIS acquis (`driver-lock.sh acquire` n'est
# jamais appelé dessus) : `status` y rend systématiquement present=false -> SAIN, exactement le
# comportement neutre qu'attendaient déjà D1-D11 avant l'introduction du sous-contrôle stall (33-03).
# Les cas D14-D25 gardent leur propre surcharge inline (`VF_DRIVER_LOCK="$D1x_LOCK" bash "$SCRIPT"
# ...`) : une surcharge inline ne modifie que l'environnement de CETTE commande, jamais la variable
# de ce shell — donc $VF_DRIVER_LOCK redevient ce défaut juste après, sans discontinuité pour les
# cas suivants.
export VF_DRIVER_LOCK="$WORK_DIR/default-unacquired-lock"

# Garde structurelle (Bloquant 2) : rend l'oubli futur IMPOSSIBLE plutôt que documenté seul. Un
# `trap ... DEBUG` s'exécute avant CHAQUE commande simple du corps du script (pas dans les traps
# eux-mêmes, pas de récursion) et fait échouer la suite (exit 2, fixture cassée — jamais un verdict
# métier) si la variable de CE shell a été réassignée hors de $WORK_DIR. Une surcharge inline
# (`VF_DRIVER_LOCK=... bash "$SCRIPT"`) n'affecte jamais cette variable de shell — seule une
# réassignation durable (`VF_DRIVER_LOCK=/vrai/chemin` sans préfixe de commande, l'erreur qu'un
# futur cas pourrait introduire par inadvertance) la déclenche.
assert_lock_isolated() {
  case "$VF_DRIVER_LOCK" in
    "$WORK_DIR"/*) : ;;
    *)
      echo "GARDE STRUCTURELLE — VF_DRIVER_LOCK hors de \$WORK_DIR : [$VF_DRIVER_LOCK] (aurait pu lire le vrai verrou du dépôt)" >&2
      exit 2
      ;;
  esac
}
trap 'assert_lock_isolated' DEBUG

echo "== test-check-guard-health =="

# === D8 — CAS DISCRIMINANT, NE JAMAIS RETIRER (Bloquant 1, mandat 2026-08-17) : exécution DIRECTE
# du VRAI $SCRIPT sur disque (PAS `bash "$SCRIPT"`, qui contourne le bit exécutable en forçant un
# interprète). Le plan 33-05 invoque le relais par exec direct (`subprocess.run([check_guard_health_sh,
# "--hook"], ...)`) — c'est CE chemin que toute la suite, jusqu'ici, ne testait jamais : elle passait
# systématiquement par `bash "$SCRIPT" ...`, qui reste vert même si le fichier est commité en 100644
# (non exécutable). Mesuré avant correctif : `./check-guard-health.sh --hook` -> permission denied,
# exit 126, et l'exception Python correspondante (`PermissionError [Errno 13]`) est avalée par le
# try/except englobant de check_stall_signal() -> D-33-F ne relaie jamais rien, en silence. Si ce
# cas est un jour retiré ou réécrit pour repasser par `bash "$SCRIPT"`, cette régression redevient
# invisible à la suite tout en la laissant verte.
D8_DIR="$WORK_DIR/d8-exec-direct"
D8_OUT="$("$SCRIPT" --dir="$D8_DIR" 2>/dev/null)"; D8_RC=$?
[ "$D8_RC" -eq 3 ] && ok "D8 : exécution DIRECTE (bit +x, pas de \`bash\` explicite) → exit 3 (SAIN)" || ko "D8 exit" "rc=$D8_RC attendu 3 (126 = script non exécutable, régression Bloquant 1)"
[ -z "$D8_OUT" ] && ok "D8 : stdout strictement vide" || ko "D8 stdout" "out=[$D8_OUT]"
D8H_OUT="$("$SCRIPT" --dir="$WORK_DIR/d8-hook" --hook 2>/dev/null)"; D8H_RC=$?
[ "$D8H_RC" -eq 0 ] && ok "D8/--hook : exécution DIRECTE sous --hook → exit 0 (relais fonctionnel, pas 126)" || ko "D8/--hook exit" "rc=$D8H_RC attendu 0"

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

# --- Helpers de forgeage direct du meta driver-lock.sh (D14-D24, plan 33-03) --------------------
# MEME PATRON EXACT que test-driver-lock.sh:51-113 (age_stale/meta_drop_key/progress_backdate) :
# `sed -i.bak "..." "$meta" && rm -f "${meta}.bak"`, JAMAIS `sed -i` nu (GNU-only, casse sur macOS).
# Reproduits LOCALEMENT ici (jamais en sourçant l'autre suite, qui a son propre trap/mktemp/état
# top-level) plutôt qu'en réinventer un patron différent.
lock_meta_path() { # <lock>
  if [ -L "$1" ]; then
    echo "$(dirname "$1")/$(readlink "$1")/meta"
  else
    echo "$1/meta"
  fi
}

progress_backdate() { # <lock> <secs> — recule progress_epoch, JAMAIS heartbeat_epoch
  local meta secs now old
  meta="$(lock_meta_path "$1")"
  secs="$2"
  [ -f "$meta" ] || return 1
  now="$(date +%s)"
  old=$(( now - secs ))
  sed -i.bak "s/^progress_epoch=.*/progress_epoch=$old/" "$meta" && rm -f "${meta}.bak"
}

heartbeat_backdate() { # <lock> <secs> — recule heartbeat_epoch, JAMAIS progress_epoch
  local meta secs now old
  meta="$(lock_meta_path "$1")"
  secs="$2"
  [ -f "$meta" ] || return 1
  now="$(date +%s)"
  old=$(( now - secs ))
  sed -i.bak "s/^heartbeat_epoch=.*/heartbeat_epoch=$old/" "$meta" && rm -f "${meta}.bak"
}

meta_drop_key() { # <lock> <key> — simule un lock posé par une version ANTÉRIEURE du protocole
  local meta
  meta="$(lock_meta_path "$1")"
  [ -f "$meta" ] && sed -i.bak "/^${2}=/d" "$meta" 2>/dev/null && rm -f "${meta}.bak"
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
# D7 DURCI — ts malformé/absent → repli sur mtime_epoch(). Ces 3 marqueurs viennent d'être écrits
# (mtime = maintenant) : le repli DOIT retomber dans la fenêtre et signaler (exit 0), jamais être
# classé périmé (exit 3) faute de quoi un marqueur frais serait tu (cf. mtime_epoch() du script :
# ordre GNU (-c) avant BSD (-f) obligatoire — un ordre inversé fait échouer silencieusement le
# repli mtime sous Linux et classe à tort ces marqueurs frais comme périmés).
[ "$D7_RC" -eq 0 ] && ok "D7 durci : ts malformé + mtime fraîche → SIGNALÉ (jamais classé périmé)" || ko "D7 durci exit" "rc=$D7_RC attendu 0 (repli mtime doit rester dans la fenêtre)"

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
# GNU (-c) AVANT BSD (-f) : meme anti-motif que mtime_epoch() du script teste — ici sans
# consequence (snapshot() est appele symetriquement avant/apres), mais ne pas laisser ce sens-la
# comme modele a recopier (deja corrige 2 fois dans ce depot).
snapshot() { ( cd "$1" && find . -type f -exec sh -c 'printf "%s %s %s\n" "$1" "$(wc -c < "$1" | tr -d " ")" "$(stat -c %Y "$1" 2>/dev/null || stat -f %m "$1")"' _ {} \; | sort ); }
D9_BEFORE="$(snapshot "$D9_DIR")"
bash "$SCRIPT" --dir="$D9_DIR" >/dev/null 2>&1
D9_AFTER="$(snapshot "$D9_DIR")"
[ "$D9_BEFORE" = "$D9_AFTER" ] && ok "D9 : répertoire de santé INCHANGÉ après exécution (liste, tailles, mtimes)" || ko "D9 lecture seule" "avant=[$D9_BEFORE] après=[$D9_AFTER]"

# === D14-D25 — sous-contrôle stall/abandon (plan 33-03, WTCH-02, D-33-A/D-33-E) ===================
# Chaque cas isole VF_DRIVER_LOCK sous $WORK_DIR : AUCUNE invocation de $SCRIPT dans ce bloc ne doit
# jamais laisser VF_DRIVER_LOCK non défini, sous peine de lire (voire, sous une régression future,
# de perturber) le VRAI lock de pilotage du dépôt qui exécute cette suite (.planning/DRIVER.lock).

echo ""
echo "=== D14 — aucun lock jamais acquis -> SAIN, aucune ligne de stall ==="
D14_LOCK="$WORK_DIR/d14-lock"
D14_HEALTH="$WORK_DIR/d14-health"
D14_OUT="$(VF_DRIVER_LOCK="$D14_LOCK" bash "$SCRIPT" --dir="$D14_HEALTH" 2>/dev/null)"; D14_RC=$?
[ "$D14_RC" -eq 3 ] && ok "D14 : aucun lock -> exit 3 (SAIN)" || ko "D14 exit" "rc=$D14_RC attendu 3"
[ -z "$D14_OUT" ] && ok "D14 : stdout strictement vide, aucune ligne de stall" || ko "D14 stdout" "out=[$D14_OUT]"

echo ""
echo "=== D15 — lock acquis, heartbeat ET progress frais -> SAIN, aucune ligne de stall ==="
D15_LOCK="$WORK_DIR/d15-lock"
D15_HEALTH="$WORK_DIR/d15-health"
VF_DRIVER_LOCK="$D15_LOCK" "$DRIVER_LOCK" acquire --owner=d15-owner --step=d15-step >/dev/null 2>&1
D15_OUT="$(VF_DRIVER_LOCK="$D15_LOCK" bash "$SCRIPT" --dir="$D15_HEALTH" 2>/dev/null)"; D15_RC=$?
[ "$D15_RC" -eq 3 ] && ok "D15 : lock frais des deux horloges -> exit 3 (SAIN)" || ko "D15 exit" "rc=$D15_RC attendu 3"
[ -z "$D15_OUT" ] && ok "D15 : stdout strictement vide" || ko "D15 stdout" "out=[$D15_OUT]"
VF_DRIVER_LOCK="$D15_LOCK" "$DRIVER_LOCK" release --owner=d15-owner >/dev/null 2>&1

echo ""
echo "=== D16 — heartbeat frais, progress_epoch antidaté au-delà du seuil (forgé) -> SIGNAL stall ==="
D16_LOCK="$WORK_DIR/d16-lock"
D16_HEALTH="$WORK_DIR/d16-health"
VF_DRIVER_LOCK="$D16_LOCK" "$DRIVER_LOCK" acquire --owner=d16-owner --step=d16-step >/dev/null 2>&1
progress_backdate "$D16_LOCK" 1000   # > 900 (STALL_WINDOW défaut), heartbeat_epoch INCHANGÉ (reste frais)
D16_OUT="$(VF_DRIVER_LOCK="$D16_LOCK" bash "$SCRIPT" --dir="$D16_HEALTH" 2>/dev/null)"; D16_RC=$?
[ "$D16_RC" -eq 0 ] && ok "D16 : progrès figé au-delà du seuil -> exit 0 (signal)" || ko "D16 exit" "rc=$D16_RC attendu 0"
case "$D16_OUT" in
  *"stall"*"d16-owner"*"d16-step"*) ok "D16 : la ligne mentionne 'stall', l'owner et le step" ;;
  *) ko "D16 contenu" "out=[$D16_OUT]" ;;
esac
VF_DRIVER_LOCK="$D16_LOCK" "$DRIVER_LOCK" release --owner=d16-owner >/dev/null 2>&1

echo ""
echo "=== D17 — heartbeat antidaté au-delà du TTL (forgé) -> SIGNAL abandon, JAMAIS confondu avec stall ==="
D17_LOCK="$WORK_DIR/d17-lock"
D17_HEALTH="$WORK_DIR/d17-health"
VF_DRIVER_LOCK="$D17_LOCK" "$DRIVER_LOCK" acquire --owner=d17-owner --step=d17-step >/dev/null 2>&1
heartbeat_backdate "$D17_LOCK" 2000   # > 1800 (VF_DRIVER_TTL défaut) -> stale=true
D17_OUT="$(VF_DRIVER_LOCK="$D17_LOCK" bash "$SCRIPT" --dir="$D17_HEALTH" 2>/dev/null)"; D17_RC=$?
[ "$D17_RC" -eq 0 ] && ok "D17 : heartbeat mort (lock périmé) -> exit 0 (signal)" || ko "D17 exit" "rc=$D17_RC attendu 0"
case "$D17_OUT" in
  *"abandon"*"d17-owner"*"d17-step"*) ok "D17 : la ligne mentionne 'abandon', l'owner et le step" ;;
  *) ko "D17 contenu" "out=[$D17_OUT]" ;;
esac
case "$D17_OUT" in
  *"stall détecté"*|*"stall detecte"*) ko "D17 confusion" "la ligne d'abandon NE DOIT JAMAIS mentionner un stall" ;;
  *) ok "D17 : jamais confondue avec la ligne de stall (D16)" ;;
esac
VF_DRIVER_LOCK="$D17_LOCK" "$DRIVER_LOCK" release --owner=d17-owner >/dev/null 2>&1

echo ""
echo "=== D18 — rétrocompat : meta SANS progress_epoch= (ancien protocole), heartbeat frais -> SAIN ==="
D18_LOCK="$WORK_DIR/d18-lock"
D18_HEALTH="$WORK_DIR/d18-health"
VF_DRIVER_LOCK="$D18_LOCK" "$DRIVER_LOCK" acquire --owner=d18-owner --step=d18-step >/dev/null 2>&1
meta_drop_key "$D18_LOCK" progress_epoch
# Contrôle positif OBLIGATOIRE (même exigence que 33-01) : la ligne progress_epoch= doit être
# ABSENTE du meta AVANT d'invoquer le script sous test — sinon ce cas ne prouverait rien.
D18_META="$(lock_meta_path "$D18_LOCK")"
if grep -q '^progress_epoch=' "$D18_META" 2>/dev/null; then
  ko "D18 contrôle positif" "progress_epoch= encore présent dans le meta AVANT l'appel — fixture cassée"
else
  ok "D18 : contrôle positif — progress_epoch= bien ABSENT du meta avant l'appel"
fi
D18_OUT="$(VF_DRIVER_LOCK="$D18_LOCK" bash "$SCRIPT" --dir="$D18_HEALTH" 2>/dev/null)"; D18_RC=$?
[ "$D18_RC" -eq 3 ] && ok "D18 : rétrocompat (pas de progress_epoch) -> exit 3 (SAIN, jamais un faux positif)" || ko "D18 exit" "rc=$D18_RC attendu 3"
[ -z "$D18_OUT" ] && ok "D18 : stdout strictement vide" || ko "D18 stdout" "out=[$D18_OUT]"
VF_DRIVER_LOCK="$D18_LOCK" "$DRIVER_LOCK" release --owner=d18-owner >/dev/null 2>&1

echo ""
echo "=== D19 — sibling driver-lock.sh ABSENT -> INDÉTERMINÉ + marqueur BRUYANT + stderr (QUAL-01) ==="
D19_ISO="$WORK_DIR/d19-iso"; mkdir -p "$D19_ISO"
cp "$SCRIPT" "$D19_ISO/check-guard-health.sh"; chmod +x "$D19_ISO/check-guard-health.sh"
D19_HEALTH="$WORK_DIR/d19-health"
if [ -e "$D19_HEALTH" ]; then echo "PRÉFLIGHT FIXTURE CASSÉ — D19_HEALTH déjà présent avant l'appel" >&2; exit 2; fi
D19_ERR="$WORK_DIR/d19.err"
D19_OUT="$(VF_DRIVER_LOCK="$WORK_DIR/d19-lock" bash "$D19_ISO/check-guard-health.sh" --dir="$D19_HEALTH" 2>"$D19_ERR")"; D19_RC=$?
D19_STDERR="$(cat "$D19_ERR" 2>/dev/null)"
[ "$D19_RC" -eq 4 ] && ok "D19 : sibling absent -> exit 4 (INDÉTERMINÉ, JAMAIS 3/SAIN)" || ko "D19 exit" "rc=$D19_RC attendu 4"
[ -z "$D19_OUT" ] && ok "D19 : stdout vide" || ko "D19 stdout" "out=[$D19_OUT]"
[ -f "$D19_HEALTH/check-guard-health.sh.marker" ] && ok "D19 : marqueur écrit dans HEALTH_DIR, MÊME absent avant l'appel" || ko "D19 marqueur" "absent : $D19_HEALTH/check-guard-health.sh.marker"
[ -n "$D19_STDERR" ] && ok "D19 : message sur stderr" || ko "D19 stderr" "vide"
D19H_OUT="$(VF_DRIVER_LOCK="$WORK_DIR/d19-lock-hook" bash "$D19_ISO/check-guard-health.sh" --dir="$WORK_DIR/d19-health-hook" --hook 2>/dev/null)"; D19H_RC=$?
[ "$D19H_RC" -eq 0 ] && ok "D19/--hook : INDÉTERMINÉ traduit en 0 au harness" || ko "D19/--hook exit" "rc=$D19H_RC attendu 0"
[ -z "$D19H_OUT" ] && ok "D19/--hook : stdout toujours vide (jamais un signal fantôme)" || ko "D19/--hook stdout" "out=[$D19H_OUT]"

echo ""
echo "=== D20 — sibling présent+exécutable, AUCUN interprète Python -> INDÉTERMINÉ + marqueur + stderr ==="
D20_ISO="$WORK_DIR/d20-iso"; mkdir -p "$D20_ISO"
cp "$SCRIPT" "$D20_ISO/check-guard-health.sh"
cp "$DRIVER_LOCK" "$D20_ISO/driver-lock.sh"
chmod +x "$D20_ISO/check-guard-health.sh" "$D20_ISO/driver-lock.sh"
D20_BIN="$WORK_DIR/d20-bin"; mkdir -p "$D20_BIN"
for t in bash env cat dirname basename sed grep mkdir rm mv date readlink stat ls; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$D20_BIN/$t" 2>/dev/null
done
# Contrôle positif OBLIGATOIRE (même patron D13) : AUCUN de python3/python/py ne doit être joignable
# dans ce PATH restreint AVANT d'invoquer la copie isolée — sinon la cascade ne serait pas exercée.
D20_PY_OK=1
for py in python3 python py; do
  PATH="$D20_BIN" command -v "$py" >/dev/null 2>&1 && D20_PY_OK=0
done
[ "$D20_PY_OK" -eq 1 ] && ok "D20 : contrôle positif — python3/python/py tous injoignables dans le PATH restreint" || ko "D20 contrôle positif" "au moins un interprète encore joignable — fixture cassée"
D20_HEALTH="$WORK_DIR/d20-health"
D20_ERR="$WORK_DIR/d20.err"
D20_OUT="$(PATH="$D20_BIN" VF_DRIVER_LOCK="$WORK_DIR/d20-lock" "$D20_BIN/bash" "$D20_ISO/check-guard-health.sh" --dir="$D20_HEALTH" 2>"$D20_ERR")"; D20_RC=$?
D20_STDERR="$(cat "$D20_ERR" 2>/dev/null)"
[ "$D20_RC" -eq 4 ] && ok "D20 : aucun interprète -> exit 4 (INDÉTERMINÉ)" || ko "D20 exit" "rc=$D20_RC attendu 4"
[ -z "$D20_OUT" ] && ok "D20 : stdout vide" || ko "D20 stdout" "out=[$D20_OUT]"
[ -f "$D20_HEALTH/check-guard-health.sh.marker" ] && ok "D20 : marqueur écrit" || ko "D20 marqueur" "absent"
[ -n "$D20_STDERR" ] && ok "D20 : message sur stderr" || ko "D20 stderr" "vide"

echo ""
echo "=== D21 — sibling isolé rendant un JSON structurellement inattendu -> fail-open SILENCIEUX (SAIN) ==="
D21_ISO="$WORK_DIR/d21-iso"; mkdir -p "$D21_ISO"
cp "$SCRIPT" "$D21_ISO/check-guard-health.sh"; chmod +x "$D21_ISO/check-guard-health.sh"
cat > "$D21_ISO/driver-lock.sh" <<'FAKE_DRIVER_LOCK'
#!/usr/bin/env bash
# Faux driver-lock.sh isolé (D21, plan 33-03) : rend 0 mais un texte NON-JSON sur stdout.
echo "ceci n'est pas du JSON"
exit 0
FAKE_DRIVER_LOCK
chmod +x "$D21_ISO/driver-lock.sh"
D21_HEALTH="$WORK_DIR/d21-health"
D21_OUT="$(VF_DRIVER_LOCK="$WORK_DIR/d21-lock" bash "$D21_ISO/check-guard-health.sh" --dir="$D21_HEALTH" 2>/dev/null)"; D21_RC=$?
[ "$D21_RC" -eq 3 ] && ok "D21 : JSON imparsable -> exit 3 (SAIN, fail-open SILENCIEUX)" || ko "D21 exit" "rc=$D21_RC attendu 3"
[ -z "$D21_OUT" ] && ok "D21 : stdout vide" || ko "D21 stdout" "out=[$D21_OUT]"
[ ! -e "$D21_HEALTH" ] && ok "D21 : aucun marqueur écrit, HEALTH_DIR reste absent (fail-open jamais bruyant ici)" || ko "D21 HEALTH_DIR" "créé à tort : $D21_HEALTH"

echo ""
echo "=== D22 — signal combiné : marqueur de garde EXISTANT + stall simultané -> DEUX lignes distinctes ==="
D22_LOCK="$WORK_DIR/d22-lock"
D22_HEALTH="$WORK_DIR/d22-health"
write_marker "$D22_HEALTH" "guard-combo.sh" "$(now_iso)" "guard-combo.sh" "motif combo"
VF_DRIVER_LOCK="$D22_LOCK" "$DRIVER_LOCK" acquire --owner=d22-owner --step=d22-step >/dev/null 2>&1
progress_backdate "$D22_LOCK" 1000
D22_OUT="$(VF_DRIVER_LOCK="$D22_LOCK" bash "$SCRIPT" --dir="$D22_HEALTH" 2>/dev/null)"; D22_RC=$?
[ "$D22_RC" -eq 0 ] && ok "D22 : marqueur + stall -> exit 0" || ko "D22 exit" "rc=$D22_RC attendu 0"
D22_LINES="$(printf '%s\n' "$D22_OUT" | grep -c .)"
[ "$D22_LINES" -eq 2 ] && ok "D22 : EXACTEMENT deux lignes (une par famille de signal, jamais fusionnées)" || ko "D22 nb lignes" "=$D22_LINES attendu 2"
case "$D22_OUT" in *"guard-combo.sh"*) ok "D22 : la famille marqueurs-de-garde est présente" ;; *) ko "D22 marqueurs" "out=[$D22_OUT]" ;; esac
case "$D22_OUT" in *"stall"*"d22-owner"*) ok "D22 : la famille stall-de-mission est présente" ;; *) ko "D22 stall" "out=[$D22_OUT]" ;; esac
VF_DRIVER_LOCK="$D22_LOCK" "$DRIVER_LOCK" release --owner=d22-owner >/dev/null 2>&1

echo ""
echo "=== D23 — BUG BLOQUANT CORRIGÉ : stall pur + HEALTH_DIR ABSENT -> SIGNAL, répertoire reste ABSENT ==="
D23_LOCK="$WORK_DIR/d23-lock"
D23_HEALTH="$WORK_DIR/d23-health"
if [ -e "$D23_HEALTH" ]; then echo "PRÉFLIGHT FIXTURE CASSÉ — D23_HEALTH déjà présent avant l'appel" >&2; exit 2; fi
VF_DRIVER_LOCK="$D23_LOCK" "$DRIVER_LOCK" acquire --owner=d23-owner --step=d23-step >/dev/null 2>&1
progress_backdate "$D23_LOCK" 1000
D23_OUT="$(VF_DRIVER_LOCK="$D23_LOCK" bash "$SCRIPT" --dir="$D23_HEALTH" 2>/dev/null)"; D23_RC=$?
[ "$D23_RC" -eq 0 ] && ok "D23 : stall pur, HEALTH_DIR absent -> exit 0 (SIGNAL, jamais 3/SAIN — bug d'ordonnancement fermé)" || ko "D23 exit" "rc=$D23_RC attendu 0"
case "$D23_OUT" in *"stall"*"d23-owner"*) ok "D23 : la ligne de stall est bien émise" ;; *) ko "D23 contenu" "out=[$D23_OUT]" ;; esac
[ ! -e "$D23_HEALTH" ] && ok "D23 : HEALTH_DIR reste ABSENT après l'appel (stall pur ne crée JAMAIS le répertoire)" || ko "D23 HEALTH_DIR" "créé à tort : $D23_HEALTH"
VF_DRIVER_LOCK="$D23_LOCK" "$DRIVER_LOCK" release --owner=d23-owner >/dev/null 2>&1

echo ""
echo "=== D24 — configuration du seuil : VF_STALL_WINDOW (variable) et --stall-window= (flag, prioritaire) ==="
D24_LOCK="$WORK_DIR/d24-lock"
D24_HEALTH="$WORK_DIR/d24-health"
VF_DRIVER_LOCK="$D24_LOCK" "$DRIVER_LOCK" acquire --owner=d24-owner --step=d24-step >/dev/null 2>&1
progress_backdate "$D24_LOCK" 90   # au-delà de 60 (VF_STALL_WINDOW), en-deçà du défaut 900
D24_OUT="$(VF_DRIVER_LOCK="$D24_LOCK" VF_STALL_WINDOW=60 bash "$SCRIPT" --dir="$D24_HEALTH" 2>/dev/null)"; D24_RC=$?
[ "$D24_RC" -eq 0 ] && ok "D24 : VF_STALL_WINDOW=60, progress=90s -> exit 0 (signal, variable bien lue)" || ko "D24 exit" "rc=$D24_RC attendu 0"
case "$D24_OUT" in *"stall"*) ok "D24 : ligne de stall émise sous la variable d'environnement" ;; *) ko "D24 contenu" "out=[$D24_OUT]" ;; esac
D24B_HEALTH="$WORK_DIR/d24b-health"
D24B_OUT="$(VF_DRIVER_LOCK="$D24_LOCK" VF_STALL_WINDOW=60 bash "$SCRIPT" --dir="$D24B_HEALTH" --stall-window=3600 2>/dev/null)"; D24B_RC=$?
[ "$D24B_RC" -eq 3 ] && ok "D24b : --stall-window=3600 l'emporte sur VF_STALL_WINDOW=60 -> exit 3 (SAIN)" || ko "D24b exit" "rc=$D24B_RC attendu 3"
[ -z "$D24B_OUT" ] && ok "D24b : stdout strictement vide" || ko "D24b stdout" "out=[$D24B_OUT]"
VF_DRIVER_LOCK="$D24_LOCK" "$DRIVER_LOCK" release --owner=d24-owner >/dev/null 2>&1

echo ""
echo "=== D25 — PREUVE DE PROTOCOLE RÉEL (S1 option b, décision Samuel) : heartbeat réel, jamais mark-progress, jamais de forgeage ==="
D25_LOCK="$WORK_DIR/d25-lock"
D25_HEALTH="$WORK_DIR/d25-health"
VF_DRIVER_LOCK="$D25_LOCK" "$DRIVER_LOCK" acquire --owner=tester --step=d25-step >/dev/null 2>&1
D25_META="$(lock_meta_path "$D25_LOCK")"
D25_PROGRESS_BEFORE="$(grep '^progress_epoch=' "$D25_META" 2>/dev/null)"
D25_START="$(date +%s)"
# EXCEPTION EXPLICITE ET DOCUMENTÉE à la prohibition « aucun sleep non borné » de cette suite (voir
# 33-03-PLAN.md, S1 option (b)) : boucle BORNÉE (3 itérations, ~3s), le VRAI verbe `heartbeat`
# (JAMAIS mark-progress, JAMAIS de forgeage/sed sur le meta) — seule façon de faire naître la
# divergence des deux horloges du PROTOCOLE lui-même, pas d'un epoch fabriqué. NE JAMAIS généraliser
# ce patron à un autre cas de cette suite : D14-D24 restent tous forgés, sans attente réelle.
for _ in 1 2 3; do
  sleep 1
  VF_DRIVER_LOCK="$D25_LOCK" "$DRIVER_LOCK" heartbeat --owner=tester >/dev/null 2>&1
done
D25_END="$(date +%s)"
D25_DURATION=$(( D25_END - D25_START ))
D25_PROGRESS_AFTER="$(grep '^progress_epoch=' "$D25_META" 2>/dev/null)"
[ "$D25_DURATION" -le 5 ] && ok "D25 : boucle bornée, durée réelle mesurée ${D25_DURATION}s (<=5s)" || ko "D25 durée" "=${D25_DURATION}s attendu <=5s"
[ "$D25_PROGRESS_BEFORE" = "$D25_PROGRESS_AFTER" ] && ok "D25 : progress_epoch= INCHANGÉ avant/après la boucle (${D25_PROGRESS_BEFORE}) — seule l'horloge murale a créé l'écart, jamais une édition" || ko "D25 stabilité progress_epoch" "avant=[$D25_PROGRESS_BEFORE] après=[$D25_PROGRESS_AFTER]"
D25_GREPC="$(grep -c '^progress_epoch=' "$D25_META" 2>/dev/null)"
[ "$D25_GREPC" -eq 1 ] && ok "D25 : grep -c progress_epoch= == 1 (ligne unique, jamais dupliquée/retirée)" || ko "D25 grep -c" "=$D25_GREPC attendu 1"
D25_OUT="$(VF_DRIVER_LOCK="$D25_LOCK" VF_STALL_WINDOW=1 bash "$SCRIPT" --dir="$D25_HEALTH" 2>/dev/null)"; D25_RC=$?
[ "$D25_RC" -eq 0 ] && ok "D25 : verdict -> exit 0 (signal)" || ko "D25 exit" "rc=$D25_RC attendu 0"
case "$D25_OUT" in
  *"stall"*"tester"*) ok "D25 : ligne STALL constatée (owner=tester), issue du protocole réel" ;;
  *) ko "D25 contenu" "out=[$D25_OUT]" ;;
esac
case "$D25_OUT" in
  *"abandon"*) ko "D25 confusion" "ne doit JAMAIS être classé abandon (heartbeat réel frais, stale doit rester false)" ;;
  *) ok "D25 : jamais classé abandon (stale reste faux, bien sous le TTL 1800s)" ;;
esac
VF_DRIVER_LOCK="$D25_LOCK" "$DRIVER_LOCK" release --owner=tester >/dev/null 2>&1

# === D13 — BOUCLE COMPLÈTE, bout en bout : le VRAI guard-driver-lock.sh écrit le marqueur, ce
# script le lit. Aucun marqueur n'est fabriqué à la main dans ce cas. =============================
echo ""
echo "=== D13 — boucle producteur -> marqueur -> lecteur (guard-driver-lock.sh réel) ==="

D13_GUARD_OK=1
[ -x "$GUARD_LOCK" ] || D13_GUARD_OK=0
[ -x "$DRIVER_LOCK" ] || D13_GUARD_OK=0

if [ "$D13_GUARD_OK" -eq 0 ]; then
  echo "  ⏭  D13 SAUTÉ EXPLICITEMENT — guard-driver-lock.sh/driver-lock.sh absents (plan 32-03 non exécuté sur cet arbre)"
else
  D13_HEALTH="$WORK_DIR/d13-health"
  D13_LOCK="$WORK_DIR/d13-DRIVER.lock"

  # PRÉFLIGHT SÉPARÉ, obligatoire : le répertoire de santé redirigé doit être VIDE avant
  # l'invocation — un marqueur résiduel d'un autre cas ferait passer D13 sans qu'aucune boucle
  # n'ait été réellement prouvée (le faux vert exact que ce cas existe pour interdire). Une
  # contamination ici est un bug de FIXTURE, pas un verdict métier : sortie 2 immédiate.
  if [ -e "$D13_HEALTH" ] && [ -n "$(ls -A "$D13_HEALTH" 2>/dev/null)" ]; then
    echo "PRÉFLIGHT FIXTURE CASSÉ — D13_HEALTH non vide AVANT l'invocation : $D13_HEALTH" >&2
    exit 2
  fi

  CLAUDE_CODE_SESSION_ID=sess-holder-d13 VF_DRIVER_LOCK="$D13_LOCK" "$DRIVER_LOCK" acquire --owner=mission-d13 --step=d13 >/dev/null 2>&1

  # Environnement SANS interprète joignable — même montage que Q4 de test-guard-driver-lock.sh :
  # un dossier de binaires ne contenant que les outils nécessaires, aucun python3/python.
  D13_BIN="$WORK_DIR/d13-bin"
  mkdir -p "$D13_BIN"
  for t in cat dirname basename sed grep mkdir rm mv date readlink stat ls; do
    p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$D13_BIN/$t" 2>/dev/null
  done
  D13_TOOLS_OK=1
  for t in cat dirname mkdir mv rm date ls; do [ -x "$D13_BIN/$t" ] || D13_TOOLS_OK=0; done
  if PATH="$D13_BIN" command -v python3 >/dev/null 2>&1 || PATH="$D13_BIN" command -v python >/dev/null 2>&1; then D13_TOOLS_OK=0; fi

  if [ "$D13_TOOLS_OK" -eq 0 ]; then
    ko "D13 préflight" "fixture cassée : outils manquants ou interprète encore joignable"
  else
    # Payload construit AVANT la restriction de PATH (l'échappement JSON a besoin de python3).
    D13_PAYLOAD="$(python3 -c '
import json
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": "git commit -m x"},
                   "session_id": "sess-intrus-d13", "cwd": "."}))')"

    D13_RC=0
    D13_OUT="$(printf '%s' "$D13_PAYLOAD" | VF_DRIVER_LOCK="$D13_LOCK" VF_GUARD_HEALTH_DIR="$D13_HEALTH" PATH="$D13_BIN" "$BASH_BIN" "$GUARD_LOCK" 2>/dev/null)" || D13_RC=$?

    [ "$D13_RC" -eq 17 ] && ok "D13 : guard-driver-lock.sh réel, interprète absent → code de garde 17" || ko "D13 producteur exit" "rc=$D13_RC attendu 17"
    [ -z "$D13_OUT" ] && ok "D13 : guard-driver-lock.sh réel → stdout vide" || ko "D13 producteur stdout" "out=[$D13_OUT]"

    D13_READER_OUT="$(bash "$SCRIPT" --dir="$D13_HEALTH" 2>/dev/null)"; D13_READER_RC=$?
    [ "$D13_READER_RC" -eq 0 ] && ok "D13 : le doctor lit le marqueur RÉEL → exit 0 (signal)" || ko "D13 lecteur exit" "rc=$D13_READER_RC attendu 0"
    case "$D13_READER_OUT" in
      *"guard-driver-lock.sh"*) ok "D13 : la ligne du doctor nomme guard-driver-lock.sh" ;;
      *) ko "D13 lecteur contenu" "out=[$D13_READER_OUT]" ;;
    esac
  fi

  VF_DRIVER_LOCK="$D13_LOCK" "$DRIVER_LOCK" release --owner=mission-d13 >/dev/null 2>&1
fi

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
