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

# --- Repertoire courant NEUTRE (Q1, 2026-10-13) : check-guard-health.sh lit le dernier commit du depot git
# du repertoire courant ; un cas D14-D25 lance depuis le depot qui execute la suite lirait SES commits
# (frais) et perdrait son stall. La suite tourne donc dans $WORK_DIR, hors de tout depot git (preflight).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE   # une suite jouee depuis un hook git heriterait du depot du hook
cd "$WORK_DIR" || { echo "PRÉFLIGHT FIXTURE CASSÉ — cd $WORK_DIR impossible" >&2; exit 2; }
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "PRÉFLIGHT FIXTURE CASSÉ — $WORK_DIR est dans un depot git (TMPDIR sous un depot ?)" >&2; exit 2
fi

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

# === Q1 — le commit de la branche courante compte comme progression (arbitrage Samuel, AskUserQuestion
# session principale, 2026-10-13, Q1 option b) ====================================================
# Pendant un plan plus long que STALL_WINDOW aucun noeud n'est marque : sans cette regle, faux stall a
# chaque plan (constate a 1587 s et 1589 s le 2026-10-12). Le script lit le dernier commit (%ct, date de
# COMMIT) de la branche courante du depot git du repertoire courant ; chaque cas tourne dans un depot
# fictif sous $WORK_DIR, jamais dans le depot qui execute la suite.
q1_repo() { # <dir> <secs-d-anciennete-du-commit> — depot git avec UN commit dont %ct = maintenant - secs
  local d="$1" secs="$2" when
  mkdir -p "$d" && git -C "$d" init -q 2>/dev/null || return 1
  when=$(( $(date +%s) - secs ))
  GIT_COMMITTER_DATE="$when +0000" GIT_AUTHOR_DATE="$when +0000" \
    git -C "$d" -c user.name=q1 -c user.email=q1@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null \
    commit -q --allow-empty -m q1 2>/dev/null
}
q1_commit() { # <dir> <secs-commit> <secs-auteur> <msg> — commit vide dont %ct = maintenant - secs-commit et %at = maintenant - secs-auteur
  local d="$1" now cwhen awhen
  now="$(date +%s)"; cwhen=$(( now - $2 )); awhen=$(( now - $3 ))
  GIT_COMMITTER_DATE="$cwhen +0000" GIT_AUTHOR_DATE="$awhen +0000" \
    git -C "$d" -c user.name=q1 -c user.email=q1@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null \
    commit -q --allow-empty -m "$4" 2>/dev/null
}
q1_wt_repo() { # <repo> <worktree> <secs-commit-principal> <secs-commit-secondaire> — depot + worktree secondaire (branche q1wt)
  q1_repo "$1" "$3" || return 1
  git -C "$1" worktree add -q -b q1wt "$2" >/dev/null 2>&1 || return 1
  q1_commit "$2" "$4" "$4" q1wt
}
# Age extrait de « depuis <N>s » dans la sortie, vide si absent. Encadrement numerique (jamais une chaine litterale
# d'age : sous charge la mesure derive de plusieurs secondes — constate 1004 s et 1009 s pour 1000 s attendues).
q1_age_of() { printf '%s' "$1" | sed -n 's/.*depuis \([0-9][0-9]*\)s.*/\1/p' | head -1; }
q1_age_in() { # <sortie> <attendu> — vrai si age extrait dans [attendu, attendu + 60]
  local a; a="$(q1_age_of "$1")"
  case "$a" in ''|*[!0-9]*) return 1 ;; esac
  [ "$a" -ge "$2" ] && [ "$a" -le $(( $2 + 60 )) ]
}
q1_run() { # <repo-ou-dir> <lock> <health> — le script tourne DANS <repo-ou-dir>, lock backdate fait par l'appelant
  ( cd "$1" && VF_DRIVER_LOCK="$2" bash "$SCRIPT" --dir="$3" 2>/dev/null )
}

echo ""
echo "=== Q1a — progress_epoch fige a 1000 s, heartbeat frais, commit de branche RECENT -> SAIN (pas de faux stall) ==="
Q1A_LOCK="$WORK_DIR/q1a-lock"; Q1A_REPO="$WORK_DIR/q1a-repo"
q1_repo "$Q1A_REPO" 60 || ko "Q1a fixture" "depot git non cree"
VF_DRIVER_LOCK="$Q1A_LOCK" "$DRIVER_LOCK" acquire --owner=q1a-owner --step=q1a-step >/dev/null 2>&1
progress_backdate "$Q1A_LOCK" 1000
Q1A_OUT="$(q1_run "$Q1A_REPO" "$Q1A_LOCK" "$WORK_DIR/q1a-health")"; Q1A_RC=$?
[ "$Q1A_RC" -eq 3 ] && ok "Q1a : commit de branche a 60 s -> exit 3 (SAIN)" || ko "Q1a exit" "rc=$Q1A_RC attendu 3 (faux stall malgre un commit recent)"
[ -z "$Q1A_OUT" ] && ok "Q1a : stdout strictement vide" || ko "Q1a stdout" "out=[$Q1A_OUT]"
VF_DRIVER_LOCK="$Q1A_LOCK" "$DRIVER_LOCK" release --owner=q1a-owner >/dev/null 2>&1

echo ""
echo "=== Q1b — TEMOIN : meme verrou, commit de branche ANCIEN (2000 s) -> STALL maintenu, age effectif imprime ==="
Q1B_LOCK="$WORK_DIR/q1b-lock"; Q1B_REPO="$WORK_DIR/q1b-repo"
q1_repo "$Q1B_REPO" 2000 || ko "Q1b fixture" "depot git non cree"
VF_DRIVER_LOCK="$Q1B_LOCK" "$DRIVER_LOCK" acquire --owner=q1b-owner --step=q1b-step >/dev/null 2>&1
progress_backdate "$Q1B_LOCK" 1000
Q1B_OUT="$(q1_run "$Q1B_REPO" "$Q1B_LOCK" "$WORK_DIR/q1b-health")"; Q1B_RC=$?
[ "$Q1B_RC" -eq 0 ] && ok "Q1b : commit ancien -> exit 0 (signal)" || ko "Q1b exit" "rc=$Q1B_RC attendu 0"
case "$Q1B_OUT" in
  *"stall"*"q1b-owner"*"q1b-step"*"seuil=900s"*) ok "Q1b : ligne de stall, owner, step, seuil inchange" ;;
  *) ko "Q1b contenu" "out=[$Q1B_OUT]" ;;
esac
if q1_age_in "$Q1B_OUT" 1000; then ok "Q1b : age imprime = celui du verrou (le plus recent des deux, ici progress_epoch), dans [1000, 1060]"
else ko "Q1b age" "attendu dans [1000, 1060], obtenu [$(q1_age_of "$Q1B_OUT")] out=[$Q1B_OUT]"; fi
VF_DRIVER_LOCK="$Q1B_LOCK" "$DRIVER_LOCK" release --owner=q1b-owner >/dev/null 2>&1

echo ""
echo "=== Q1c — commit a 1000 s (> seuil), progress_epoch a 1700 s -> STALL, age effectif = celui du COMMIT ==="
Q1C_LOCK="$WORK_DIR/q1c-lock"; Q1C_REPO="$WORK_DIR/q1c-repo"
q1_repo "$Q1C_REPO" 1000 || ko "Q1c fixture" "depot git non cree"
VF_DRIVER_LOCK="$Q1C_LOCK" "$DRIVER_LOCK" acquire --owner=q1c-owner --step=q1c-step >/dev/null 2>&1
progress_backdate "$Q1C_LOCK" 1700
Q1C_OUT="$(q1_run "$Q1C_REPO" "$Q1C_LOCK" "$WORK_DIR/q1c-health")"; Q1C_RC=$?
[ "$Q1C_RC" -eq 0 ] && ok "Q1c : exit 0 (signal)" || ko "Q1c exit" "rc=$Q1C_RC attendu 0"
if q1_age_in "$Q1C_OUT" 1000; then ok "Q1c : age effectif = depuis le dernier commit (plus recent que progress_epoch), dans [1000, 1060]"
else ko "Q1c age" "attendu dans [1000, 1060] (et non 1700), obtenu [$(q1_age_of "$Q1C_OUT")] out=[$Q1C_OUT]"; fi
VF_DRIVER_LOCK="$Q1C_LOCK" "$DRIVER_LOCK" release --owner=q1c-owner >/dev/null 2>&1

echo ""
echo "=== Q1d — pas de depot git (repertoire courant hors git) -> comportement d'avant : STALL, jamais SAIN fabrique ==="
Q1D_LOCK="$WORK_DIR/q1d-lock"; Q1D_DIR="$WORK_DIR/q1d-nogit"; mkdir -p "$Q1D_DIR"
VF_DRIVER_LOCK="$Q1D_LOCK" "$DRIVER_LOCK" acquire --owner=q1d-owner --step=q1d-step >/dev/null 2>&1
progress_backdate "$Q1D_LOCK" 1000
Q1D_OUT="$(q1_run "$Q1D_DIR" "$Q1D_LOCK" "$WORK_DIR/q1d-health")"; Q1D_RC=$?
[ "$Q1D_RC" -eq 0 ] && ok "Q1d : hors git -> exit 0 (stall maintenu)" || ko "Q1d exit" "rc=$Q1D_RC attendu 0"
case "$Q1D_OUT" in *"stall"*"q1d-owner"*) ok "Q1d : ligne de stall" ;; *) ko "Q1d contenu" "out=[$Q1D_OUT]" ;; esac
VF_DRIVER_LOCK="$Q1D_LOCK" "$DRIVER_LOCK" release --owner=q1d-owner >/dev/null 2>&1

echo ""
echo "=== Q1e — lecture git qui ECHOUE (depot sans aucun commit) -> comportement d'avant : STALL, pas de crash ==="
Q1E_LOCK="$WORK_DIR/q1e-lock"; Q1E_REPO="$WORK_DIR/q1e-repo"
mkdir -p "$Q1E_REPO" && git -C "$Q1E_REPO" init -q 2>/dev/null
VF_DRIVER_LOCK="$Q1E_LOCK" "$DRIVER_LOCK" acquire --owner=q1e-owner --step=q1e-step >/dev/null 2>&1
progress_backdate "$Q1E_LOCK" 1000
Q1E_OUT="$(q1_run "$Q1E_REPO" "$Q1E_LOCK" "$WORK_DIR/q1e-health")"; Q1E_RC=$?
[ "$Q1E_RC" -eq 0 ] && ok "Q1e : git log en echec -> exit 0 (stall maintenu)" || ko "Q1e exit" "rc=$Q1E_RC attendu 0"
case "$Q1E_OUT" in *"stall"*"q1e-owner"*) ok "Q1e : ligne de stall" ;; *) ko "Q1e contenu" "out=[$Q1E_OUT]" ;; esac
VF_DRIVER_LOCK="$Q1E_LOCK" "$DRIVER_LOCK" release --owner=q1e-owner >/dev/null 2>&1

echo ""
echo "=== Q1f — commit date dans le FUTUR (horloge decalee) -> ignore, STALL maintenu (un commit futur ne masque jamais un stall) ==="
Q1F_LOCK="$WORK_DIR/q1f-lock"; Q1F_REPO="$WORK_DIR/q1f-repo"
q1_repo "$Q1F_REPO" -86400 || ko "Q1f fixture" "depot git non cree"
VF_DRIVER_LOCK="$Q1F_LOCK" "$DRIVER_LOCK" acquire --owner=q1f-owner --step=q1f-step >/dev/null 2>&1
progress_backdate "$Q1F_LOCK" 1000
Q1F_OUT="$(q1_run "$Q1F_REPO" "$Q1F_LOCK" "$WORK_DIR/q1f-health")"; Q1F_RC=$?
[ "$Q1F_RC" -eq 0 ] && ok "Q1f : commit futur -> exit 0 (stall maintenu)" || ko "Q1f exit" "rc=$Q1F_RC attendu 0"
VF_DRIVER_LOCK="$Q1F_LOCK" "$DRIVER_LOCK" release --owner=q1f-owner >/dev/null 2>&1

echo ""
echo "=== Q1g — ABANDON inchange : heartbeat mort + commit recent -> abandon (le commit n'efface jamais un heartbeat mort) ==="
Q1G_LOCK="$WORK_DIR/q1g-lock"; Q1G_REPO="$WORK_DIR/q1g-repo"
q1_repo "$Q1G_REPO" 30 || ko "Q1g fixture" "depot git non cree"
VF_DRIVER_LOCK="$Q1G_LOCK" "$DRIVER_LOCK" acquire --owner=q1g-owner --step=q1g-step >/dev/null 2>&1
heartbeat_backdate "$Q1G_LOCK" 2000
Q1G_OUT="$(q1_run "$Q1G_REPO" "$Q1G_LOCK" "$WORK_DIR/q1g-health")"; Q1G_RC=$?
[ "$Q1G_RC" -eq 0 ] && ok "Q1g : exit 0 (signal)" || ko "Q1g exit" "rc=$Q1G_RC attendu 0"
case "$Q1G_OUT" in *"abandon"*"q1g-owner"*) ok "Q1g : ligne d'abandon malgre le commit recent" ;; *) ko "Q1g contenu" "out=[$Q1G_OUT]" ;; esac
VF_DRIVER_LOCK="$Q1G_LOCK" "$DRIVER_LOCK" release --owner=q1g-owner >/dev/null 2>&1

# === Q1h-Q1m — la progression est le commit le plus recent parmi les HEAD de TOUS les worktrees du dossier git
# commun (arbitrage Samuel, AskUserQuestion session principale, 2026-10-13, D option b) ======================
# Un verrou partage entre worktrees (vf-driver/ sous le git-common-dir) est travaille depuis un autre worktree que
# celui ou tourne le watchdog : lire le seul HEAD courant le declarait fige alors que son proprietaire commitait.
echo ""
echo "=== Q1h — commit recent SEULEMENT dans le worktree secondaire, verrou fige -> SAIN (le watchdog tourne dans le principal) ==="
Q1H_LOCK="$WORK_DIR/q1h-lock"; Q1H_REPO="$WORK_DIR/q1h-repo"; Q1H_WT="$WORK_DIR/q1h-wt"
q1_wt_repo "$Q1H_REPO" "$Q1H_WT" 2000 60 || ko "Q1h fixture" "depot ou worktree non cree"
VF_DRIVER_LOCK="$Q1H_LOCK" "$DRIVER_LOCK" acquire --owner=q1h-owner --step=q1h-step >/dev/null 2>&1
progress_backdate "$Q1H_LOCK" 1000
Q1H_OUT="$(q1_run "$Q1H_REPO" "$Q1H_LOCK" "$WORK_DIR/q1h-health")"; Q1H_RC=$?
[ "$Q1H_RC" -eq 3 ] && ok "Q1h : HEAD recent dans un autre worktree -> exit 3 (SAIN)" || ko "Q1h exit" "rc=$Q1H_RC attendu 3 (faux stall : seul le HEAD courant est lu)"
[ -z "$Q1H_OUT" ] && ok "Q1h : stdout strictement vide" || ko "Q1h stdout" "out=[$Q1H_OUT]"
VF_DRIVER_LOCK="$Q1H_LOCK" "$DRIVER_LOCK" release --owner=q1h-owner >/dev/null 2>&1

echo ""
echo "=== Q1i — TEMOIN : tous les HEAD anciens (2000 s et 1500 s) -> STALL maintenu ==="
Q1I_LOCK="$WORK_DIR/q1i-lock"; Q1I_REPO="$WORK_DIR/q1i-repo"; Q1I_WT="$WORK_DIR/q1i-wt"
q1_wt_repo "$Q1I_REPO" "$Q1I_WT" 2000 1500 || ko "Q1i fixture" "depot ou worktree non cree"
VF_DRIVER_LOCK="$Q1I_LOCK" "$DRIVER_LOCK" acquire --owner=q1i-owner --step=q1i-step >/dev/null 2>&1
progress_backdate "$Q1I_LOCK" 1000
Q1I_OUT="$(q1_run "$Q1I_REPO" "$Q1I_LOCK" "$WORK_DIR/q1i-health")"; Q1I_RC=$?
[ "$Q1I_RC" -eq 0 ] && ok "Q1i : tous les HEAD anciens -> exit 0 (signal)" || ko "Q1i exit" "rc=$Q1I_RC attendu 0"
case "$Q1I_OUT" in *"stall"*"q1i-owner"*) ok "Q1i : ligne de stall" ;; *) ko "Q1i contenu" "out=[$Q1I_OUT]" ;; esac
if q1_age_in "$Q1I_OUT" 1000; then ok "Q1i : age effectif = celui du verrou (1000), les deux HEAD etant plus vieux"
else ko "Q1i age" "attendu dans [1000, 1060], obtenu [$(q1_age_of "$Q1I_OUT")]"; fi
VF_DRIVER_LOCK="$Q1I_LOCK" "$DRIVER_LOCK" release --owner=q1i-owner >/dev/null 2>&1

echo ""
echo "=== Q1j — worktree secondaire PRUNABLE (repertoire disparu) a HEAD recent -> ignore, STALL maintenu ==="
Q1J_LOCK="$WORK_DIR/q1j-lock"; Q1J_REPO="$WORK_DIR/q1j-repo"; Q1J_WT="$WORK_DIR/q1j-wt"
q1_wt_repo "$Q1J_REPO" "$Q1J_WT" 2000 60 || ko "Q1j fixture" "depot ou worktree non cree"
rm -rf "$Q1J_WT"
# Controle positif : git declare bien le worktree prunable AVANT l'appel, sinon le cas ne prouverait rien.
case "$(git -C "$Q1J_REPO" worktree list --porcelain 2>/dev/null)" in
  *prunable*) ok "Q1j : controle positif — git marque le worktree disparu 'prunable'" ;;
  *) ko "Q1j controle positif" "worktree non marque prunable — fixture cassee" ;;
esac
VF_DRIVER_LOCK="$Q1J_LOCK" "$DRIVER_LOCK" acquire --owner=q1j-owner --step=q1j-step >/dev/null 2>&1
progress_backdate "$Q1J_LOCK" 1000
Q1J_OUT="$(q1_run "$Q1J_REPO" "$Q1J_LOCK" "$WORK_DIR/q1j-health")"; Q1J_RC=$?
[ "$Q1J_RC" -eq 0 ] && ok "Q1j : worktree prunable ignore -> exit 0 (stall maintenu)" || ko "Q1j exit" "rc=$Q1J_RC attendu 0"
case "$Q1J_OUT" in *"stall"*"q1j-owner"*) ok "Q1j : ligne de stall" ;; *) ko "Q1j contenu" "out=[$Q1J_OUT]" ;; esac
VF_DRIVER_LOCK="$Q1J_LOCK" "$DRIVER_LOCK" release --owner=q1j-owner >/dev/null 2>&1

echo ""
echo "=== Q1k — commit FUTUR dans le worktree secondaire, commit RECENT dans le principal -> le futur est ignore, le recent compte (SAIN) ==="
# Si le futur etait retenu comme « le plus recent » puis rejete en bloc, le commit recent du principal serait perdu
# et le watchdog declarerait un faux stall : chaque HEAD est donc juge pour son compte avant le choix du maximum.
Q1K_LOCK="$WORK_DIR/q1k-lock"; Q1K_REPO="$WORK_DIR/q1k-repo"; Q1K_WT="$WORK_DIR/q1k-wt"
q1_wt_repo "$Q1K_REPO" "$Q1K_WT" 60 -86400 || ko "Q1k fixture" "depot ou worktree non cree"
VF_DRIVER_LOCK="$Q1K_LOCK" "$DRIVER_LOCK" acquire --owner=q1k-owner --step=q1k-step >/dev/null 2>&1
progress_backdate "$Q1K_LOCK" 1000
Q1K_OUT="$(q1_run "$Q1K_REPO" "$Q1K_LOCK" "$WORK_DIR/q1k-health")"; Q1K_RC=$?
[ "$Q1K_RC" -eq 3 ] && ok "Q1k : futur ignore, recent du principal retenu -> exit 3 (SAIN)" || ko "Q1k exit" "rc=$Q1K_RC attendu 3 (le commit futur a masque le commit recent)"
[ -z "$Q1K_OUT" ] && ok "Q1k : stdout strictement vide" || ko "Q1k stdout" "out=[$Q1K_OUT]"
VF_DRIVER_LOCK="$Q1K_LOCK" "$DRIVER_LOCK" release --owner=q1k-owner >/dev/null 2>&1

echo ""
echo "=== Q1l — date d'AUTEUR ancienne (5 j), date de COMMIT recente (30 s) -> SAIN : %ct et non %at ==="
Q1L_LOCK="$WORK_DIR/q1l-lock"; Q1L_REPO="$WORK_DIR/q1l-repo"
mkdir -p "$Q1L_REPO" && git -C "$Q1L_REPO" init -q 2>/dev/null
q1_commit "$Q1L_REPO" 30 432000 q1l || ko "Q1l fixture" "commit non cree"
# Controle positif : les deux dates divergent bien dans le depot de fixture.
Q1L_AT="$(git -C "$Q1L_REPO" log -1 --format=%at 2>/dev/null)"; Q1L_CT="$(git -C "$Q1L_REPO" log -1 --format=%ct 2>/dev/null)"
case "$Q1L_AT:$Q1L_CT" in
  *[!0-9:]*|:*|*:) ko "Q1l controle positif" "dates illisibles at=[$Q1L_AT] ct=[$Q1L_CT]" ;;
  *) [ $(( Q1L_CT - Q1L_AT )) -gt 400000 ] && ok "Q1l : controle positif — %ct est plus recent que %at de plus de 400000 s" || ko "Q1l controle positif" "at=$Q1L_AT ct=$Q1L_CT : dates non divergentes" ;;
esac
VF_DRIVER_LOCK="$Q1L_LOCK" "$DRIVER_LOCK" acquire --owner=q1l-owner --step=q1l-step >/dev/null 2>&1
progress_backdate "$Q1L_LOCK" 1000
Q1L_OUT="$(q1_run "$Q1L_REPO" "$Q1L_LOCK" "$WORK_DIR/q1l-health")"; Q1L_RC=$?
[ "$Q1L_RC" -eq 3 ] && ok "Q1l : commit rebase a l'instant (auteur ancien) -> exit 3 (SAIN)" || ko "Q1l exit" "rc=$Q1L_RC attendu 3 (la date d'auteur a ete lue)"
[ -z "$Q1L_OUT" ] && ok "Q1l : stdout strictement vide" || ko "Q1l stdout" "out=[$Q1L_OUT]"
VF_DRIVER_LOCK="$Q1L_LOCK" "$DRIVER_LOCK" release --owner=q1l-owner >/dev/null 2>&1

echo ""
echo "=== Q1m — GIT_DIR herite (hook git, shell parent) pointant un AUTRE depot ancien -> ignore : git durci, depot du cwd lu (SAIN) ==="
Q1M_LOCK="$WORK_DIR/q1m-lock"; Q1M_REPO="$WORK_DIR/q1m-repo"; Q1M_OTHER="$WORK_DIR/q1m-other"
q1_repo "$Q1M_REPO" 60 || ko "Q1m fixture" "depot recent non cree"
q1_repo "$Q1M_OTHER" 2000 || ko "Q1m fixture" "depot ancien non cree"
VF_DRIVER_LOCK="$Q1M_LOCK" "$DRIVER_LOCK" acquire --owner=q1m-owner --step=q1m-step >/dev/null 2>&1
progress_backdate "$Q1M_LOCK" 1000
Q1M_OUT="$( cd "$Q1M_REPO" && GIT_DIR="$Q1M_OTHER/.git" GIT_WORK_TREE="$Q1M_OTHER" VF_DRIVER_LOCK="$Q1M_LOCK" bash "$SCRIPT" --dir="$WORK_DIR/q1m-health" 2>/dev/null )"; Q1M_RC=$?
[ "$Q1M_RC" -eq 3 ] && ok "Q1m : GIT_DIR/GIT_WORK_TREE herites ignores -> exit 3 (SAIN)" || ko "Q1m exit" "rc=$Q1M_RC attendu 3 (git lit le depot ancien designe par l'environnement)"
[ -z "$Q1M_OUT" ] && ok "Q1m : stdout strictement vide" || ko "Q1m stdout" "out=[$Q1M_OUT]"
VF_DRIVER_LOCK="$Q1M_LOCK" "$DRIVER_LOCK" release --owner=q1m-owner >/dev/null 2>&1

# === Q1n-Q1q — lecture des worktrees SEPAREE PAR NUL, et un seul `git log` (AU3-05, AU3-06) ================
# AU3-05 : un chemin de worktree peut contenir des sauts de ligne ; lu par lignes, il forgeait un bloc `HEAD <sha>` (age
# 214 082 152 s -> 0 s). Le HEAD du seul worktree reel est ANCIEN (2000 s) ; le sha recent n'existe que sur une branche
# sans worktree et dans le NOM du chemin : le verdict juste est STALL.
q1n_repo() { # <repo> <worktree-forge> — rend 0 si le depot est pret ; ecrit le sha recent dans <repo>.rec
  local repo="$1" wt="$2" tmp="$1-recwt" sha
  q1_repo "$repo" 2000 || return 1
  git -C "$repo" worktree add -q -b q1nrec "$tmp" >/dev/null 2>&1 || return 1
  q1_commit "$tmp" 60 60 q1nrec || return 1
  sha="$(git -C "$tmp" rev-parse HEAD 2>/dev/null)"; [ -n "$sha" ] || return 1
  git -C "$repo" worktree remove --force "$tmp" >/dev/null 2>&1 || return 1
  printf '%s' "$sha" > "$repo.rec"
  wt="${wt}
 
HEAD ${sha}

x"
  git -C "$repo" worktree add -q -b q1n "$wt" >/dev/null 2>&1
}
# Shim `git` : journalise les appels `log`, refuse `-z` (git < 2.36 : exit 129) quand Q1_SHIM_NOZ=1, fait echouer
# `log --no-walk` quand Q1_SHIM_NOWALK_FAIL=1 ; le reste est delegue au vrai git.
Q1_REALGIT="$(command -v git)"
mkdir -p "$WORK_DIR/q1shim"
cat > "$WORK_DIR/q1shim/git" <<EOSHIM
#!/bin/bash
for a in "\$@"; do
  [ "\$a" = "worktree" ] && [ -n "\${Q1_SHIM_WTOUT:-}" ] && { cat "\$Q1_SHIM_WTOUT"; exit 0; }
  [ "\$a" = "log" ] && echo "log" >> "\${Q1_SHIM_LOG:-/dev/null}"
  [ "\$a" = "-z" ] && [ "\${Q1_SHIM_NOZ:-0}" = 1 ] && { echo "error: unknown switch 'z'" >&2; exit 129; }
  [ "\$a" = "--no-walk=unsorted" ] && [ "\${Q1_SHIM_NOWALK_FAIL:-0}" = 1 ] && exit 1
done
exec "$Q1_REALGIT" "\$@"
EOSHIM
chmod +x "$WORK_DIR/q1shim/git"

echo ""
echo "=== Q1n — chemin de worktree a sauts de ligne forgeant un HEAD recent -> ignore, STALL maintenu ==="
Q1N_LOCK="$WORK_DIR/q1n-lock"; Q1N_REPO="$WORK_DIR/q1n-repo"; Q1N_WT="$WORK_DIR/q1n-wt"
q1n_repo "$Q1N_REPO" "$Q1N_WT" || ko "Q1n fixture" "depot ou worktree a chemin forge non cree"
# Controle positif : la lecture PAR LIGNES de git verrait bien une ligne `HEAD <sha recent>` forgee ; sans cela le cas ne prouverait rien.
Q1N_SHA="$(cat "$Q1N_REPO.rec" 2>/dev/null)"
[ -n "$Q1N_SHA" ] && git -C "$Q1N_REPO" worktree list --porcelain 2>/dev/null | grep -qx "HEAD $Q1N_SHA" \
  && ok "Q1n : controle positif — la sortie par lignes de git contient la ligne HEAD forgee" \
  || ko "Q1n controle positif" "ligne HEAD forgee absente de la sortie par lignes — fixture cassee"
VF_DRIVER_LOCK="$Q1N_LOCK" "$DRIVER_LOCK" acquire --owner=q1n-owner --step=q1n-step >/dev/null 2>&1
progress_backdate "$Q1N_LOCK" 1000
Q1N_OUT="$(q1_run "$Q1N_REPO" "$Q1N_LOCK" "$WORK_DIR/q1n-health")"; Q1N_RC=$?
[ "$Q1N_RC" -eq 0 ] && ok "Q1n : HEAD forge ignore -> exit 0 (stall maintenu)" || ko "Q1n exit" "rc=$Q1N_RC attendu 0 (un nom de chemin a forge un HEAD recent)"
if q1_age_in "$Q1N_OUT" 1000; then ok "Q1n : age effectif = celui du verrou (1000)"; else ko "Q1n age" "attendu dans [1000, 1060], obtenu [$(q1_age_of "$Q1N_OUT")]"; fi
VF_DRIVER_LOCK="$Q1N_LOCK" "$DRIVER_LOCK" release --owner=q1n-owner >/dev/null 2>&1

echo ""
echo "=== Q1o — git sans -z (exit 129) : repli SUR sur le HEAD courant, jamais une lecture par lignes (STALL, aucun HEAD forge lu) ==="
Q1O_LOCK="$WORK_DIR/q1o-lock"; Q1O_SHIMLOG="$WORK_DIR/q1o-shim.log"; : > "$Q1O_SHIMLOG"
VF_DRIVER_LOCK="$Q1O_LOCK" "$DRIVER_LOCK" acquire --owner=q1o-owner --step=q1o-step >/dev/null 2>&1
progress_backdate "$Q1O_LOCK" 1000
Q1O_OUT="$( cd "$Q1N_REPO" && PATH="$WORK_DIR/q1shim:$PATH" Q1_SHIM_NOZ=1 Q1_SHIM_LOG="$Q1O_SHIMLOG" VF_DRIVER_LOCK="$Q1O_LOCK" bash "$SCRIPT" --dir="$WORK_DIR/q1o-health" 2>/dev/null )"; Q1O_RC=$?
[ "$Q1O_RC" -eq 0 ] && ok "Q1o : sans -z -> exit 0 (stall, HEAD courant seul)" || ko "Q1o exit" "rc=$Q1O_RC attendu 0"
if q1_age_in "$Q1O_OUT" 1000; then ok "Q1o : age effectif = celui du verrou (1000)"; else ko "Q1o age" "attendu dans [1000, 1060], obtenu [$(q1_age_of "$Q1O_OUT")]"; fi
VF_DRIVER_LOCK="$Q1O_LOCK" "$DRIVER_LOCK" release --owner=q1o-owner >/dev/null 2>&1

echo ""
echo "=== Q1p — un seul processus git log pour tous les HEAD (3 worktrees) ==="
Q1P_LOCK="$WORK_DIR/q1p-lock"; Q1P_REPO="$WORK_DIR/q1p-repo"; Q1P_WT="$WORK_DIR/q1p-wt"; Q1P_WT2="$WORK_DIR/q1p-wt2"; Q1P_SHIMLOG="$WORK_DIR/q1p-shim.log"; : > "$Q1P_SHIMLOG"
q1_wt_repo "$Q1P_REPO" "$Q1P_WT" 2000 60 && git -C "$Q1P_REPO" worktree add -q -b q1wt2 "$Q1P_WT2" >/dev/null 2>&1 || ko "Q1p fixture" "depot ou worktrees non crees"
VF_DRIVER_LOCK="$Q1P_LOCK" "$DRIVER_LOCK" acquire --owner=q1p-owner --step=q1p-step >/dev/null 2>&1
progress_backdate "$Q1P_LOCK" 1000
Q1P_OUT="$( cd "$Q1P_REPO" && PATH="$WORK_DIR/q1shim:$PATH" Q1_SHIM_LOG="$Q1P_SHIMLOG" VF_DRIVER_LOCK="$Q1P_LOCK" bash "$SCRIPT" --dir="$WORK_DIR/q1p-health" 2>/dev/null )"; Q1P_RC=$?
[ "$Q1P_RC" -eq 3 ] && ok "Q1p : verdict inchange (HEAD recent du worktree secondaire) -> exit 3" || ko "Q1p exit" "rc=$Q1P_RC attendu 3"
Q1P_N="$(grep -c '^log$' "$Q1P_SHIMLOG" 2>/dev/null)"
[ "$Q1P_N" = 1 ] && ok "Q1p : un seul appel git log pour 3 worktrees" || ko "Q1p nombre de git log" "obtenu [$Q1P_N] attendu 1"
VF_DRIVER_LOCK="$Q1P_LOCK" "$DRIVER_LOCK" release --owner=q1p-owner >/dev/null 2>&1

echo ""
echo "=== Q1q — git log --no-walk refuse (un HEAD illisible) : repli par HEAD, verdict inchange (SAIN) ==="
Q1Q_LOCK="$WORK_DIR/q1q-lock"; Q1Q_REPO="$WORK_DIR/q1q-repo"; Q1Q_WT="$WORK_DIR/q1q-wt"
q1_wt_repo "$Q1Q_REPO" "$Q1Q_WT" 2000 60 || ko "Q1q fixture" "depot ou worktree non cree"
VF_DRIVER_LOCK="$Q1Q_LOCK" "$DRIVER_LOCK" acquire --owner=q1q-owner --step=q1q-step >/dev/null 2>&1
progress_backdate "$Q1Q_LOCK" 1000
Q1Q_OUT="$( cd "$Q1Q_REPO" && PATH="$WORK_DIR/q1shim:$PATH" Q1_SHIM_NOWALK_FAIL=1 VF_DRIVER_LOCK="$Q1Q_LOCK" bash "$SCRIPT" --dir="$WORK_DIR/q1q-health" 2>/dev/null )"; Q1Q_RC=$?
[ "$Q1Q_RC" -eq 3 ] && ok "Q1q : repli par HEAD -> exit 3 (SAIN)" || ko "Q1q exit" "rc=$Q1Q_RC attendu 3"
VF_DRIVER_LOCK="$Q1Q_LOCK" "$DRIVER_LOCK" release --owner=q1q-owner >/dev/null 2>&1

echo ""
echo "=== Q1r — sortie -z dont un bloc ne commence pas par « worktree » (HEAD recent seul) -> bloc rejete, STALL maintenu ==="
Q1R_LOCK="$WORK_DIR/q1r-lock"; Q1R_WTOUT="$WORK_DIR/q1r-wtout"
printf 'HEAD %s\0\0' "$Q1N_SHA" > "$Q1R_WTOUT"
VF_DRIVER_LOCK="$Q1R_LOCK" "$DRIVER_LOCK" acquire --owner=q1r-owner --step=q1r-step >/dev/null 2>&1
progress_backdate "$Q1R_LOCK" 1000
Q1R_OUT="$( cd "$Q1N_REPO" && PATH="$WORK_DIR/q1shim:$PATH" Q1_SHIM_WTOUT="$Q1R_WTOUT" VF_DRIVER_LOCK="$Q1R_LOCK" bash "$SCRIPT" --dir="$WORK_DIR/q1r-health" 2>/dev/null )"; Q1R_RC=$?
[ "$Q1R_RC" -eq 0 ] && ok "Q1r : bloc sans en-tete rejete -> exit 0 (stall maintenu)" || ko "Q1r exit" "rc=$Q1R_RC attendu 0"
VF_DRIVER_LOCK="$Q1R_LOCK" "$DRIVER_LOCK" release --owner=q1r-owner >/dev/null 2>&1

# --- Mutants de la lecture des worktrees (AU3-05, AU3-06) : chaque mutation doit faire rougir SON cas. Copie du module
# (conductor/scripts + planning-core/scripts, memes positions relatives) sous $WORK_DIR, le script y est muté puis rejoué
# sur le cas Q1n (lecture par lignes forgee), Q1h (seul HEAD d'un autre worktree), Q1p (un seul git log).
Q1_MUTBASE="$WORK_DIR/q1mut"
mkdir -p "$Q1_MUTBASE/conductor" "$Q1_MUTBASE/planning-core"
cp -R "$(cd "$(dirname "$SCRIPT")" && pwd)" "$Q1_MUTBASE/conductor/scripts"
cp -R "$(cd "$(dirname "$SCRIPT")/../../planning-core/scripts" && pwd)" "$Q1_MUTBASE/planning-core/scripts"
q1_mut_rc() { # <script> <repo> <lock-nom> [VAR=valeur] -> rc du script, depot <repo>
  local s="$1" repo="$2" lk="$WORK_DIR/q1mut-$3-lock" extra="${4:-Q1_UNUSED=1}"
  VF_DRIVER_LOCK="$lk" "$DRIVER_LOCK" acquire --owner=q1mut --step=q1mut >/dev/null 2>&1
  progress_backdate "$lk" 1000
  ( cd "$repo" && env "$extra" PATH="$WORK_DIR/q1shim:$PATH" Q1_SHIM_LOG="$WORK_DIR/q1mut-$3.log" VF_DRIVER_LOCK="$lk" bash "$s" --dir="$WORK_DIR/q1mut-$3-health" >/dev/null 2>&1 ); local rc=$?
  VF_DRIVER_LOCK="$lk" "$DRIVER_LOCK" release --owner=q1mut >/dev/null 2>&1
  return $rc
}
q1_mutant() { # <id> <ancre BRE> <expr sed> <cas qui doit basculer : n|h|p>
  local id="$1" anchor="$2" expr="$3" kind="$4" d="$Q1_MUTBASE/$1" n rc cnt
  mkdir -p "$d"; cp "$Q1_MUTBASE/conductor/scripts/check-guard-health.sh" "$d/check-guard-health.sh.orig"
  cp "$d/check-guard-health.sh.orig" "$d/m.sh"
  n="$(grep -c -e "$anchor" "$d/m.sh")"
  [ "$n" = 1 ] || { ko "Q1-M-$id" "ancre non unique ($n)"; return; }
  sed -i.bak -e "/$anchor/$expr" "$d/m.sh"; rm -f "$d/m.sh.bak"
  cmp -s "$d/m.sh" "$d/check-guard-health.sh.orig" && { ko "Q1-M-$id" "mutant NON OPPOSABLE (rien change)"; return; }
  bash -n "$d/m.sh" 2>/dev/null || { ko "Q1-M-$id" "le mutant n'est pas un script valide"; return; }
  cp "$d/m.sh" "$Q1_MUTBASE/conductor/scripts/check-guard-health.sh"   # le module copie porte le mutant
  case "$kind" in
    n) q1_mut_rc "$Q1_MUTBASE/conductor/scripts/check-guard-health.sh" "$Q1N_REPO" "$id"; rc=$?
       [ "$rc" -eq 3 ] && ok "Q1-M-$id : mutant tue (le HEAD forge est lu : exit 3 au lieu de 0)" || ko "Q1-M-$id" "mutant survivant : rc=$rc attendu 3" ;;
    h) q1_mut_rc "$Q1_MUTBASE/conductor/scripts/check-guard-health.sh" "$Q1H_REPO" "$id"; rc=$?
       [ "$rc" -eq 0 ] && ok "Q1-M-$id : mutant tue (le HEAD d'un autre worktree n'est plus lu : exit 0 au lieu de 3)" || ko "Q1-M-$id" "mutant survivant : rc=$rc attendu 0" ;;
    r) q1_mut_rc "$Q1_MUTBASE/conductor/scripts/check-guard-health.sh" "$Q1N_REPO" "$id" Q1_SHIM_WTOUT="$Q1R_WTOUT"; rc=$?
       [ "$rc" -eq 3 ] && ok "Q1-M-$id : mutant tue (le bloc sans en-tete worktree est lu : exit 3 au lieu de 0)" || ko "Q1-M-$id" "mutant survivant : rc=$rc attendu 3" ;;
    p) : > "$WORK_DIR/q1mut-$id.log"; q1_mut_rc "$Q1_MUTBASE/conductor/scripts/check-guard-health.sh" "$Q1P_REPO" "$id"
       cnt="$(grep -c '^log$' "$WORK_DIR/q1mut-$id.log" 2>/dev/null)"
       [ "$cnt" != 1 ] && ok "Q1-M-$id : mutant tue ($cnt appels git log au lieu de 1)" || ko "Q1-M-$id" "mutant survivant : toujours 1 appel git log" ;;
  esac
  cp "$d/check-guard-health.sh.orig" "$Q1_MUTBASE/conductor/scripts/check-guard-health.sh"
}
# DRIVER_LOCK de la suite (script du depot) reste utilise pour poser/lever les verrous ; seul check-guard-health.sh est muté.
q1_mutant lecture_par_lignes 'cgh_git worktree list --porcelain -z 2>' "s@ -z 2>/dev/null;@ 2>/dev/null | tr '\\\\n' '\\\\0';@" n
q1_mutant sans_z 'cgh_git worktree list --porcelain -z 2>' 's@ -z 2>/dev/null;@ 2>/dev/null;@' h
q1_mutant bloc_non_rejete '\*) bad=1 ;; esac' 's@bad=1@bad=0@' r
q1_mutant un_git_log_par_head 'if out="$(cgh_git log --no-walk=unsorted' 's@if out=.*; then$@if false; then@' p

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
