#!/usr/bin/env bash
# test-driver-lock-ws.sh — Suite NEUVE du verrou de driver PAR COMPARTIMENT (Phase 57, plan 57-01).
#
# Jamais un ajout à test-driver-lock.sh ni à test-guard-driver-lock.sh : ces deux suites sont le
# témoin de non-régression du lab PLAT (P57-D-03), elles ne bougent pas. Toute preuve neuve vit ici.
#
# Plan 57-02 : WS-LEG (ancien verrou), WS-LOC (worktrees), WS-NOGIT (repli hors git), WS-VFL (VF_DRIVER_LOCK),
# WS-FLATWS (options inertes en lab plat).
# Plan 57-04 : WS-CONC (un gagnant par verrou sous concurrence, 24 x 5 tours), puis WS-AB et mutants DL-M-a a DL-M-i.
#
# TRACER (tâche 1) — un compartiment se verrouille au niveau du clone, de bout en bout :
#   WS-TRACE-1 acquire --ws → JSON de portée · WS-TRACE-2 lien dans le dossier commun du clone, rien
#   dans .planning/ · WS-TRACE-3 status puis release · WS-TRACE-4 préflight anti-pollution du vrai .git
#
# Toute invocation du script se fait depuis un sous-shell qui `cd` dans une fixture jetable, jamais
# depuis le vrai dépôt (piège P2) : le dossier commun du clone vient de `git rev-parse` sur le cwd.
#
# Exit 0 si tout passe, 1 sinon, 2 si la fixture est cassée (préflight).

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/driver-lock.sh"
# Ensembles de cas dont le verdict DOIT basculer sous chaque mutant (mesurés puis relus un par un : le cas nommé
# par le plan en fait partie ; WS-LAST est ABSENT de DL-M-i, signature du piège P1 : le dernier compartiment passe).
MUT_A="WS-LOC-1 WS-LOC-2 WS-LOC-3 WS-LOC-4"
MUT_B="WS-INV WS-INV-dotdot WS-INV-quote WS-INV-slash WS-VERBS-5a WS-VERBS-5b WS-VERBS-5c WS-VERBS-5d WS-VERBS-5e WS-VERBS-5f WS-VERBS-5g WS-VERBS-5h WS-VERBS-5i WS-VERBS-5j"
MUT_C="WS-ALL-1 WS-ALL-2 WS-ALL-3 WS-ENV WS-LEG-1 WS-LEG-2 WS-LEG-3 WS-NOWS WS-VERBS-4"
MUT_D="WS-LEG-1 WS-LEG-4"
MUT_E="WS-ENV"
MUT_F="WS-AB"
MUT_G="WS-ALL-2 WS-ALL-3 WS-LEG-1 WS-LEG-2 WS-LEG-3 WS-LEG-4 WS-VFL"
MUT_H="WS-ALL-4 WS-RC2-file WS-RC2-lien WS-RC2-vide"
MUT_I="WS-ALL-1 WS-ALL-2 WS-DEPOT WS-ENV WS-FIRST WS-INV-lien WS-LEG-1 WS-LEG-2 WS-LEG-3 WS-LEG-4 WS-LOC-1 WS-LOC-3 WS-NOGIT-1 WS-NOGIT-3 WS-TRACE-1 WS-TRACE-2 WS-TRACE-3 WS-VERBS-1 WS-VERBS-2 WS-VERBS-3 WS-VERBS-4"
# Mode de la suite. `full` (défaut) : tout, concurrence et mutants compris. `matrice` : sous-processus d'un
# mutant (DL-M-*), qui rejoue les cas WS-* hors concurrence contre une COPIE mutée du script (DLWS_SCRIPT)
# posée à côté de sa politique ; il n'y a alors ni concurrence ni mutants (pas de récursion).
DLWS_MODE="${DLWS_MODE:-full}"
SUITE="$HERE/$(basename "$0")"
[ -z "${DLWS_SCRIPT:-}" ] || SCRIPT="$DLWS_SCRIPT"
POLICY="$(cd "$HERE/../../../planning-core/scripts" && pwd)/workstream-policy.sh"

# DÉSARMEMENT en tête (P57-D-22) : un VF_DRIVER_LOCK hérité forcerait le mode « verrou unique » et
# la suite ne mesurerait plus rien ; les autres variables déplaceraient la cible ou le TTL. GIT_* :
# une suite jouée depuis un hook git hériterait du dépôt du hook, pas de la fixture.
unset VF_DRIVER_LOCK VF_DRIVER_CHILDREN VF_DRIVER_TTL VF_DRIVER_SESSION_MAX VF_DRIVER_TEST_DIE_AFTER_MUTEX \
      GSD_WORKSTREAM VF_WORKSTREAM CLAUDE_CODE_SESSION_ID GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

WORK_DIR="$(mktemp -d)"
WORK_DIR="$(cd "$WORK_DIR" && pwd -P)"   # macOS : /var → /private/var, comparé canonicalisé
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     interdit: $3"; echo "     obtenu:   $2"; FAIL=$((FAIL+1)); fi; }
assert_exit(){ if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (exit $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }

# Validité JSON par un parse RÉEL, jamais par grep seul.
json_ok() { printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }

# Laboratoire PARTITIONNÉ jetable : dépôt git, deux compartiments (alpha = 1er, omega = dernier par
# ordre alphabétique — piège P1, les DEUX bouts sont exercés). Imprime le chemin du lab.
mk_lab() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning/workstreams/alpha" "$d/.planning/workstreams/omega"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/alpha/STATE.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/omega/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  preflight "$d"
  printf '%s' "$d"
}

# Laboratoire PLAT jetable : un STATE.md racine, aucun dossier de compartiments.
mk_flat() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning"
  printf '# projet\n' > "$d/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/STATE.md"
  git -C "$d" init -q -b main >/dev/null 2>&1 || git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  preflight "$d"
  printf '%s' "$d"
}

# Dossier commun du clone d'une fixture, canonicalisé (git rendu relatif au cwd, puis pwd -P).
fixture_common_dir() { # <lab>
  local gc
  gc="$(cd "$1" && git rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$gc" in /*) ;; *) gc="$1/$gc" ;; esac
  (cd "$gc" 2>/dev/null && pwd -P)
}

# PRÉFLIGHT anti-pollution (T-57-03, piège P2) : le dossier commun de la fixture DOIT être sous
# $WORK_DIR canonicalisé, sinon une écriture irait dans le vrai .git du dépôt. Arrêt AVANT toute
# écriture du script, exit 2.
preflight() { # <lab>
  local gc; gc="$(fixture_common_dir "$1")" || gc=""
  case "$gc" in
    "$WORK_DIR"/*) return 0 ;;
    *) echo "PRÉFLIGHT FIXTURE CASSÉ — dossier commun '$gc' hors de '$WORK_DIR' : arrêt avant toute écriture" >&2
       exit 2 ;;
  esac
}

# Invocation du script DEPUIS la fixture, sous une session simulée. Jamais depuis le vrai dépôt.
# DL_SCRIPT (optionnel) substitue une copie isolée du script (WS-POL).
dl() { # <lab> <session> <args...>
  local lab="$1" sid="$2"; shift 2
  ( cd "$lab" && CLAUDE_CODE_SESSION_ID="$sid" "${DL_SCRIPT:-$SCRIPT}" "$@" )
}

echo "=== WS-TRACE — verrou d'un compartiment, de bout en bout, sur clone jetable ==="
LAB="$(mk_lab trace)"
GC="$(fixture_common_dir "$LAB")"
assert "WS-TRACE-4 — préflight : le dossier commun de la fixture est sous le répertoire de travail" "$GC" "$WORK_DIR/"

out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-TRACE-1.1 — acquire --ws=alpha exit 0" "$rc" 0
json_ok "$out"; assert_exit "WS-TRACE-1.2 — JSON valide (parse python)" "$?" 0
assert "WS-TRACE-1.3 — acquired true" "$out" '"acquired": true'
assert "WS-TRACE-1.4 — scope compartiment" "$out" '"scope": "compartiment"'
assert "WS-TRACE-1.5 — ws alpha" "$out" '"ws": "alpha"'
assert "WS-TRACE-1.6 — location git-common-dir" "$out" '"location": "git-common-dir"'

[ -L "$GC/vf-driver/ws/alpha/DRIVER.lock" ]; assert_exit "WS-TRACE-2.1 — lien <dossier commun>/vf-driver/ws/alpha/DRIVER.lock" "$?" 0
leftover="$(ls -d "$LAB"/.planning/DRIVER.lock* 2>/dev/null)"
assert "WS-TRACE-2.2 — aucun .planning/DRIVER.lock* créé dans le clone" "[$leftover]" "[]"

out="$(dl "$LAB" sess-A status --ws=alpha)"; rc=$?
assert_exit "WS-TRACE-3.1 — status --ws=alpha exit 0" "$rc" 0
json_ok "$out"; assert_exit "WS-TRACE-3.2 — JSON de status valide" "$?" 0
assert "WS-TRACE-3.3 — present true" "$out" '"present": true'
assert "WS-TRACE-3.4 — owner m1" "$out" '"owner": "m1"'
assert "WS-TRACE-3.5 — portée du status" "$out" '"scope": "compartiment", "ws": "alpha", "location": "git-common-dir"'
out="$(dl "$LAB" sess-A release --ws=alpha --owner=m1)"; rc=$?
assert_exit "WS-TRACE-3.6 — release --ws=alpha exit 0" "$rc" 0
assert "WS-TRACE-3.7 — released true" "$out" '"released": true'
json_ok "$out"; assert_exit "WS-TRACE-3.8 — JSON de release valide" "$?" 0
out="$(dl "$LAB" sess-A status --ws=alpha)"
assert "WS-TRACE-3.9 — status après release : present false" "$out" '"present": false'

#
# Cible et refus (tâche 2) — chaque comportement neuf a ses TROIS issues nommées : succès, refus
# nommé, illisible bruyant. Chaque cas vit sur sa propre fixture.

echo
echo "=== WS-FIRST / WS-LAST — deux compartiments, deux owners, les DEUX bouts alphabétiques (P1) ==="
LAB="$(mk_lab first)"; GC="$(fixture_common_dir "$LAB")"
out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-FIRST.1 — le 1er compartiment (alpha) est acquis" "$rc" 0
assert "WS-FIRST.2 — alpha acquis, ws alpha" "$out" '"ws": "alpha"'
out="$(dl "$LAB" sess-B acquire --ws=omega --owner=m2 --step=s)"; rc=$?
assert_exit "WS-LAST.1 — le dernier compartiment (omega) est acquis en même temps, par un autre owner" "$rc" 0
assert "WS-LAST.2 — omega acquis, ws omega" "$out" '"ws": "omega"'
[ -L "$GC/vf-driver/ws/omega/DRIVER.lock" ]; assert_exit "WS-LAST.3 — lien omega distinct de celui d'alpha" "$?" 0
out="$(dl "$LAB" sess-C acquire --ws=alpha --owner=m3 --step=s)"; rc=$?
assert_exit "WS-FIRST.3 — alpha par un 3e owner : refus, exit 1" "$rc" 1
assert "WS-FIRST.4 — refus held" "$out" '"reason": "held"'
assert "WS-FIRST.5 — held_by m1" "$out" '"held_by": "m1"'
assert "WS-FIRST.6 — le refus porte la portée" "$out" '"scope": "compartiment", "ws": "alpha"'
out="$(dl "$LAB" sess-C acquire --ws=omega --owner=m3 --step=s)"; rc=$?
assert_exit "WS-LAST.4 — omega par un 3e owner : refus, exit 1" "$rc" 1
assert "WS-LAST.5 — refus held, held_by m2" "$out" '"held_by": "m2"'

echo
echo "=== WS-DEPOT — le verrou de dépôt est un emplacement distinct, indépendant des compartiments ==="
LAB="$(mk_lab depot)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
out="$(dl "$LAB" sess-B acquire --depot --owner=m2 --step=s)"; rc=$?
assert_exit "WS-DEPOT.1 — --depot acquis pendant qu'alpha est tenu" "$rc" 0
json_ok "$out"; assert_exit "WS-DEPOT.2 — JSON valide" "$?" 0
assert "WS-DEPOT.3 — scope depot, ws vide, location" "$out" '"scope": "depot", "ws": "", "location": "git-common-dir"'
assert_not "WS-DEPOT.4 — --depot explicite : pas de scope_reason" "$out" 'scope_reason'
[ -L "$GC/vf-driver/repo/DRIVER.lock" ]; assert_exit "WS-DEPOT.5 — lien <commun>/vf-driver/repo/DRIVER.lock" "$?" 0
out="$(dl "$LAB" sess-C acquire --depot --owner=m3 --step=s)"; rc=$?
assert_exit "WS-DEPOT.6 — un second --depot d'un autre owner : refus, exit 1" "$rc" 1
assert "WS-DEPOT.7 — refus held, held_by m2" "$out" '"held_by": "m2"'
out="$(dl "$LAB" sess-B status --depot)"
assert "WS-DEPOT.8 — status --depot lit le verrou de dépôt" "$out" '"owner": "m2"'
out="$(dl "$LAB" sess-A status --ws=alpha)"
assert "WS-DEPOT.9 — status --ws=alpha lit toujours alpha, pas le dépôt" "$out" '"owner": "m1"'
LAB="$(mk_lab depot-rec)"
dl "$LAB" sess-A acquire --depot --owner=m1 --step=s >/dev/null
out="$(dl "$LAB" sess-B acquire --ws=omega --owner=m2 --step=s)"; rc=$?
assert_exit "WS-DEPOT.10 — réciproque : omega acquis pendant que le dépôt est tenu" "$rc" 0
out="$(dl "$LAB" sess-A release --depot --owner=m1)"
assert "WS-DEPOT.11 — release --depot relâche le dépôt" "$out" '"released": true'
assert "WS-DEPOT.12 — release --depot porte la portée dépôt" "$out" '"scope": "depot"'

echo
echo "=== WS-NOWS — sans --ws, le verrou de dépôt, et le JSON le dit (P57-D-05) ==="
LAB="$(mk_lab nows)"; GC="$(fixture_common_dir "$LAB")"
out="$(dl "$LAB" sess-A acquire --owner=m1 --step=s)"; rc=$?
assert_exit "WS-NOWS.1 — acquire sans --ws exit 0" "$rc" 0
assert "WS-NOWS.2 — portée dépôt" "$out" '"scope": "depot", "ws": "", "location": "git-common-dir"'
assert "WS-NOWS.3 — scope_reason ws-absent" "$out" '"scope_reason": "ws-absent"'
json_ok "$out"; assert_exit "WS-NOWS.4 — JSON valide" "$?" 0
[ -L "$GC/vf-driver/repo/DRIVER.lock" ]; assert_exit "WS-NOWS.5 — le verrou de dépôt est posé" "$?" 0
out="$(dl "$LAB" sess-A status)"
assert "WS-NOWS.6 — status sans --ws : verrou de dépôt, scope_reason ws-absent" "$out" '"scope_reason": "ws-absent"'
assert "WS-NOWS.7 — status sans --ws : owner m1" "$out" '"owner": "m1"'

echo
echo "=== WS-ENV — GSD_WORKSTREAM, VF_WORKSTREAM et le pointeur ne déplacent JAMAIS la cible (P57-D-04) ==="
LAB="$(mk_lab env)"; GC="$(fixture_common_dir "$LAB")"
printf 'omega\n' > "$LAB/.planning/active-workstream"
out="$( export GSD_WORKSTREAM=omega VF_WORKSTREAM=omega; dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s )"; rc=$?
assert_exit "WS-ENV.1 — acquire --ws=alpha malgré les trois canaux posés sur omega" "$rc" 0
assert "WS-ENV.2 — le verrou est celui d'alpha" "$out" '"ws": "alpha"'
[ -L "$GC/vf-driver/ws/alpha/DRIVER.lock" ]; assert_exit "WS-ENV.3 — lien alpha posé" "$?" 0
[ ! -e "$GC/vf-driver/ws/omega" ]; assert_exit "WS-ENV.4 — aucun verrou omega créé" "$?" 0
out="$( export GSD_WORKSTREAM=omega VF_WORKSTREAM=omega; dl "$LAB" sess-B acquire --owner=m2 --step=s )"; rc=$?
assert_exit "WS-ENV.5 — acquire sans --ws avec les canaux posés : exit 0" "$rc" 0
assert "WS-ENV.6 — sans --ws : le dépôt, jamais omega" "$out" '"scope": "depot"'
[ ! -e "$GC/vf-driver/ws/omega" ]; assert_exit "WS-ENV.7 — toujours aucun verrou omega" "$?" 0

echo
echo "=== WS-INV — désignation fautive : ws-invalid, hint rejouable, jamais la valeur brute ==="
LAB="$(mk_lab inv)"; GC="$(fixture_common_dir "$LAB")"
ln -s alpha "$LAB/.planning/workstreams/lnk"
inv_case() { # <id> <valeur brute à ne jamais retrouver> <args...>
  local id="$1" raw="$2"; shift 2
  local o r
  o="$(dl "$LAB" sess-A acquire --owner=m1 --step=s "$@")"; r=$?
  assert_exit "$id.1 — exit 1" "$r" 1
  assert "$id.2 — reason ws-invalid" "$o" '"reason": "ws-invalid"'
  assert "$id.3 — hint présent" "$o" '"hint": "'
  json_ok "$o"; assert_exit "$id.4 — JSON valide" "$?" 0
  [ -z "$raw" ] || assert_not "$id.5 — la valeur brute n'est jamais réimprimée" "$o" "$raw"
}
inv_case "WS-INV-dotdot"  '../x'  '--ws=../x'
inv_case "WS-INV-slash"   'a/b'   '--ws=a/b'
inv_case "WS-INV-quote"   'a"b'   '--ws=a"b'
inv_case "WS-INV-vide"    ''      '--ws='
inv_case "WS-INV-depot"   ''      '--ws=alpha' '--depot'
inv_case "WS-INV-lien"    ''      '--ws=lnk'
[ ! -e "$GC/vf-driver" ]; assert_exit "WS-INV.9 — aucune écriture dans le dossier commun après tous ces refus" "$?" 0
out="$(dl "$LAB" sess-A status --ws=../x)"; rc=$?
assert_exit "WS-INV.10 — status --ws=../x : exit 1" "$rc" 1
assert "WS-INV.11 — clé de tête error, jamais present" "$out" '"error": "ws-invalid"'
assert_not "WS-INV.12 — status refusé ne porte pas present" "$out" '"present"'

echo
echo "=== WS-UNK — nom valide, dossier absent : unknown-ws ==="
LAB="$(mk_lab unk)"
out="$(dl "$LAB" sess-A acquire --ws=zeta --owner=m1 --step=s)"; rc=$?
assert_exit "WS-UNK.1 — exit 1" "$rc" 1
assert "WS-UNK.2 — reason unknown-ws" "$out" '"reason": "unknown-ws"'
assert "WS-UNK.3 — le nom (passé par la politique) est imprimé" "$out" '"ws": "zeta"'
assert "WS-UNK.4 — hint rejouable" "$out" '"hint": "'
json_ok "$out"; assert_exit "WS-UNK.5 — JSON valide" "$?" 0

echo
echo "=== WS-RC2 — dossier des compartiments illisible : partition-unreadable, jamais un repli plat (P57-D-25) ==="
mkdir -p "$WORK_DIR/elsewhere/alpha"
rc2_case() { # <id> <fabrique la panne dans $1>
  local id="$1" breaker="$2" lab gc o r
  lab="$(mk_lab "rc2-$id")"; gc="$(fixture_common_dir "$lab")"
  "$breaker" "$lab/.planning/workstreams"
  o="$(dl "$lab" sess-A acquire --ws=alpha --owner=m1 --step=s)"; r=$?
  assert_exit "WS-RC2-$id.1 — acquire --ws : exit 1" "$r" 1
  assert "WS-RC2-$id.2 — reason partition-unreadable" "$o" '"reason": "partition-unreadable"'
  assert "WS-RC2-$id.3 — hint présent" "$o" '"hint": "'
  assert_not "WS-RC2-$id.4 — jamais une acquisition de lab plat" "$o" '"acquired": true'
  o="$(dl "$lab" sess-A acquire --owner=m1 --step=s)"; r=$?
  assert_exit "WS-RC2-$id.5 — acquire sans --ws : exit 1 aussi" "$r" 1
  assert "WS-RC2-$id.6 — reason partition-unreadable" "$o" '"reason": "partition-unreadable"'
  o="$(dl "$lab" sess-A status)"; r=$?
  assert_exit "WS-RC2-$id.7 — status : exit 1" "$r" 1
  assert "WS-RC2-$id.8 — clé de tête error" "$o" '"error": "partition-unreadable"'
  assert_not "WS-RC2-$id.9 — status ne rend pas present (sortie de lab plat)" "$o" '"present"'
  json_ok "$o"; assert_exit "WS-RC2-$id.10 — JSON valide" "$?" 0
  [ -z "$(ls -d "$lab"/.planning/DRIVER.lock* 2>/dev/null)" ] && [ ! -e "$gc/vf-driver" ]
  assert_exit "WS-RC2-$id.11 — aucun verrou posé nulle part" "$?" 0
}
brk_link()  { rm -rf "$1"; ln -s "$WORK_DIR/elsewhere" "$1"; }
brk_file()  { rm -rf "$1"; printf 'pas un dossier\n' > "$1"; }
brk_empty() { rm -rf "$1"; mkdir "$1"; }
rc2_case lien  brk_link
rc2_case file  brk_file
rc2_case vide  brk_empty

echo
echo "=== WS-POL — politique introuvable : policy-missing en lab partitionné, jamais en lab plat ==="
ISO="$WORK_DIR/isolated"; mkdir -p "$ISO"; cp "$SCRIPT" "$ISO/driver-lock.sh"; chmod +x "$ISO/driver-lock.sh"
LAB="$(mk_lab pol)"
out="$(DL_SCRIPT="$ISO/driver-lock.sh" dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-POL.1 — lab partitionné sans politique voisine : exit 1" "$rc" 1
assert "WS-POL.2 — reason policy-missing" "$out" '"reason": "policy-missing"'
assert "WS-POL.3 — hint nomme /vf-update" "$out" '/vf-update'
FLAT="$(mk_flat pol-flat)"
out="$(DL_SCRIPT="$ISO/driver-lock.sh" dl "$FLAT" sess-A acquire --owner=m1 --step=s)"; rc=$?
assert_exit "WS-POL.4 — lab plat sans politique voisine : fonctionne" "$rc" 0
assert "WS-POL.5 — acquis" "$out" '"acquired": true'
assert_not "WS-POL.6 — aucun champ de portée en lab plat" "$out" '"scope"'
[ -L "$FLAT/.planning/DRIVER.lock" ]; assert_exit "WS-POL.7 — verrou historique .planning/DRIVER.lock" "$?" 0

echo
echo "=== WS-LEG — ancien verrou unique tenu à la mise à jour : refusé, jamais repris en silence (P57-D-14, P57-D-24, P57-D-26) ==="
LEGACY_ENV='VF_DRIVER_LOCK=.planning/DRIVER.lock'
# Pose un ancien verrou unique (mode verrou unique, livré dès 57-01) dans le lab <lab>, owner <owner>.
mk_legacy() { # <lab> <owner>
  ( cd "$1" && VF_DRIVER_LOCK=.planning/DRIVER.lock CLAUDE_CODE_SESSION_ID=sess-old "$SCRIPT" acquire --owner="$2" --step=old >/dev/null )
}
# Antidate le heartbeat de l'ancien verrou (réécriture du meta, jamais une suppression).
backdate_legacy() { # <lab>
  local m="$1/.planning/DRIVER.lock/meta"
  sed 's/^heartbeat_epoch=.*/heartbeat_epoch=1000/' "$m" > "$m.tmp" && mv "$m.tmp" "$m"
}
LAB="$(mk_lab leg1)"; GC="$(fixture_common_dir "$LAB")"
mk_legacy "$LAB" old
out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-LEG-1.1 — acquire --ws=alpha avec ancien verrou vivant : exit 1" "$rc" 1
assert "WS-LEG-1.2 — reason legacy-lock-held" "$out" '"reason": "legacy-lock-held"'
assert "WS-LEG-1.3 — held_by old" "$out" '"held_by": "old"'
assert "WS-LEG-1.4 — hint : variable d'ancien verrou" "$out" "$LEGACY_ENV"
assert "WS-LEG-1.5 — hint : release de l'owner exact" "$out" 'release --owner=old'
json_ok "$out"; assert_exit "WS-LEG-1.6 — JSON valide" "$?" 0
assert "WS-LEG-1.7 — le refus porte la portée demandée" "$out" '"scope": "compartiment", "ws": "alpha"'
out="$(dl "$LAB" sess-A acquire --depot --owner=m1 --step=s)"; rc=$?
assert_exit "WS-LEG-1.8 — acquire --depot : exit 1 aussi" "$rc" 1
assert "WS-LEG-1.9 — reason legacy-lock-held" "$out" '"reason": "legacy-lock-held"'
out="$(dl "$LAB" sess-A acquire --owner=m1 --step=s)"; rc=$?
assert_exit "WS-LEG-1.10 — acquire sans --ws : exit 1 aussi" "$rc" 1
assert "WS-LEG-1.11 — reason legacy-lock-held" "$out" '"reason": "legacy-lock-held"'
[ ! -e "$GC/vf-driver" ]; assert_exit "WS-LEG-1.12 — aucun verrou neuf posé dans le dossier commun" "$?" 0
[ -L "$LAB/.planning/DRIVER.lock" ]; assert_exit "WS-LEG-1.13 — l'ancien verrou est intact" "$?" 0

LAB="$(mk_lab leg2)"
mk_legacy "$LAB" old
out="$(dl "$LAB" sess-old release --owner=old)"; rc=$?
assert_exit "WS-LEG-2.1 — release sans --ws vise l'ancien verrou : exit 0" "$rc" 0
assert "WS-LEG-2.2 — released true" "$out" '"released": true'
assert "WS-LEG-2.3 — scope_reason legacy-fallback" "$out" '"scope_reason": "legacy-fallback"'
assert "WS-LEG-2.4 — legacy_lock true" "$out" '"legacy_lock": true'
json_ok "$out"; assert_exit "WS-LEG-2.5 — JSON valide" "$?" 0
[ ! -e "$LAB/.planning/DRIVER.lock" ] && [ ! -L "$LAB/.planning/DRIVER.lock" ]; assert_exit "WS-LEG-2.6 — l'ancien verrou est relâché" "$?" 0
out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-LEG-2.7 — acquire --ws=alpha après le release : exit 0" "$rc" 0
assert "WS-LEG-2.8 — acquired true" "$out" '"acquired": true'
LAB="$(mk_lab leg2b)"
mk_legacy "$LAB" old
out="$(dl "$LAB" sess-X release --owner=autre)"; rc=$?
assert_exit "WS-LEG-2.9 — release d'un autre owner sur l'ancien verrou : refus, exit 1" "$rc" 1
assert "WS-LEG-2.10 — not-owner, held_by old" "$out" '"held_by": "old"'
[ -L "$LAB/.planning/DRIVER.lock" ]; assert_exit "WS-LEG-2.11 — l'ancien verrou reste en place" "$?" 0

LAB="$(mk_lab leg3)"
mk_legacy "$LAB" old
out="$(dl "$LAB" sess-old heartbeat --owner=old)"; rc=$?
assert_exit "WS-LEG-3.1 — heartbeat sans --ws vise l'ancien verrou : exit 0" "$rc" 0
assert "WS-LEG-3.2 — ok true" "$out" '"ok": true'
out="$(dl "$LAB" sess-old status)"; rc=$?
assert_exit "WS-LEG-3.3 — status sans --ws exit 0" "$rc" 0
assert "WS-LEG-3.4 — status expose legacy_lock true" "$out" '"legacy_lock": true'
assert "WS-LEG-3.5 — status lit l'ancien verrou (owner old)" "$out" '"owner": "old"'
json_ok "$out"; assert_exit "WS-LEG-3.6 — JSON de status valide" "$?" 0
out="$(dl "$LAB" sess-old status --ws=alpha)"
assert "WS-LEG-3.7 — status --ws=alpha expose aussi legacy_lock true" "$out" '"legacy_lock": true'
assert "WS-LEG-3.8 — status --ws=alpha ne lit pas l'ancien verrou" "$out" '"present": false'
dl "$LAB" sess-old release --owner=old >/dev/null
out="$(dl "$LAB" sess-old status)"
assert "WS-LEG-3.9 — ancien verrou absent : legacy_lock false" "$out" '"legacy_lock": false'
assert "WS-LEG-3.10 — ancien verrou absent : present false" "$out" '"present": false'
LAB="$(mk_lab leg3b)"
out="$(dl "$LAB" sess-A heartbeat --owner=old)"; rc=$?
assert_exit "WS-LEG-3.11 — heartbeat sans aucun verrou : no-lock, exit 1" "$rc" 1
assert "WS-LEG-3.12 — reason no-lock" "$out" '"reason": "no-lock"'

LAB="$(mk_lab leg4)"; GC="$(fixture_common_dir "$LAB")"
mk_legacy "$LAB" old
backdate_legacy "$LAB"
out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-LEG-4.1 — ancien verrou périmé : acquire refusé, exit 1" "$rc" 1
assert "WS-LEG-4.2 — reason stale-requires-takeover" "$out" '"reason": "stale-requires-takeover"'
assert "WS-LEG-4.3 — held_by old" "$out" '"held_by": "old"'
assert "WS-LEG-4.4 — hint : recover ciblé sur l'ancien verrou" "$out" "$LEGACY_ENV driver-lock.sh recover"
json_ok "$out"; assert_exit "WS-LEG-4.5 — JSON valide" "$?" 0
[ -d "$LAB/.planning/DRIVER.lock" ]; assert_exit "WS-LEG-4.6 — aucune suppression implicite de l'ancien verrou" "$?" 0
[ ! -e "$GC/vf-driver" ]; assert_exit "WS-LEG-4.7 — aucun verrou neuf posé" "$?" 0

echo
echo "=== WS-LOC — un verrou de compartiment est partagé entre les worktrees du clone (P57-D-07) ==="
LAB="$(mk_lab loc)"; GC="$(fixture_common_dir "$LAB")"
WT="$WORK_DIR/loc-wt"
git -C "$LAB" worktree add -q -b loc-branch "$WT" >/dev/null 2>&1
# Préflight du worktree : son dossier commun DOIT être celui de la fixture, sous $WORK_DIR.
wtc="$(fixture_common_dir "$WT")" || wtc=""
if [ "$wtc" != "$GC" ]; then echo "PRÉFLIGHT FIXTURE CASSÉ — worktree '$wtc' ≠ clone '$GC'" >&2; exit 2; fi
out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-LOC-1.1 — alpha pris depuis le checkout principal" "$rc" 0
out="$(dl "$WT" sess-B acquire --ws=alpha --owner=m2 --step=s)"; rc=$?
assert_exit "WS-LOC-1.2 — depuis le worktree lié : acquire --ws=alpha refusé, exit 1" "$rc" 1
assert "WS-LOC-1.3 — reason held, held_by m1" "$out" '"held_by": "m1"'
out="$(dl "$WT" sess-B acquire --ws=omega --owner=m2 --step=s)"; rc=$?
assert_exit "WS-LOC-2.1 — omega pris depuis le worktree lié" "$rc" 0
out="$(dl "$LAB" sess-A acquire --ws=omega --owner=m1 --step=s)"; rc=$?
assert_exit "WS-LOC-2.2 — réciproque : depuis le checkout principal, omega refusé, exit 1" "$rc" 1
assert "WS-LOC-2.3 — reason held, held_by m2" "$out" '"held_by": "m2"'
out="$(dl "$WT" sess-B status --ws=alpha)"
assert "WS-LOC-3.1 — status --ws=alpha depuis le worktree lit le verrou du principal" "$out" '"owner": "m1"'
leftover="$(ls -d "$WT"/.planning/DRIVER.lock* "$LAB"/.planning/DRIVER.lock* 2>/dev/null)"
assert "WS-LOC-3.2 — aucun .planning/DRIVER.lock* créé, ni dans le worktree ni dans le principal" "[$leftover]" "[]"
out="$(dl "$WT" sess-B acquire --depot --owner=m3 --step=s)"; rc=$?
assert_exit "WS-LOC-4.1 — le dépôt est pris depuis le worktree" "$rc" 0
out="$(dl "$LAB" sess-C acquire --depot --owner=m4 --step=s)"; rc=$?
assert_exit "WS-LOC-4.2 — réciproque : le dépôt est refusé depuis le principal, exit 1" "$rc" 1

echo
echo "=== WS-NOGIT — hors git, le lab partitionné se replie sous .planning/DRIVER.lock.d, et le JSON le déclare (P57-D-07, P57-D-21) ==="
mk_nogit() { # <nom>
  local d="$WORK_DIR/$1"
  mkdir -p "$d/.planning/workstreams/alpha" "$d/.planning/workstreams/omega"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/alpha/STATE.md"
  printf -- '---\nstatus: active\n---\n' > "$d/.planning/workstreams/omega/STATE.md"
  # PRÉFLIGHT : la fixture NE DOIT PAS être dans un dépôt git, sinon le cas ne mesure plus le repli.
  if ( cd "$d" && git rev-parse --git-common-dir >/dev/null 2>&1 ); then
    echo "PRÉFLIGHT FIXTURE CASSÉ — '$d' est dans un dépôt git : le repli hors git n'est pas mesurable" >&2; exit 2
  fi
  printf '%s' "$d"
}
NG="$(mk_nogit nogit)"
out="$(dl "$NG" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-NOGIT-1.1 — acquire --ws=alpha hors git : exit 0" "$rc" 0
json_ok "$out"; assert_exit "WS-NOGIT-1.2 — JSON valide" "$?" 0
assert "WS-NOGIT-1.3 — location checkout" "$out" '"location": "checkout"'
assert "WS-NOGIT-1.4 — scope compartiment, ws alpha" "$out" '"scope": "compartiment", "ws": "alpha"'
[ -L "$NG/.planning/DRIVER.lock.d/ws/alpha/DRIVER.lock" ]; assert_exit "WS-NOGIT-1.5 — lien .planning/DRIVER.lock.d/ws/alpha/DRIVER.lock" "$?" 0
out="$(dl "$NG" sess-B acquire --ws=alpha --owner=m2 --step=s)"; rc=$?
assert_exit "WS-NOGIT-1.6 — un second owner sur alpha : refus, exit 1" "$rc" 1
assert "WS-NOGIT-1.7 — reason held" "$out" '"reason": "held"'
out="$(dl "$NG" sess-B acquire --depot --owner=m2 --step=s)"; rc=$?
assert_exit "WS-NOGIT-2.1 — acquire --depot hors git : exit 0" "$rc" 0
assert "WS-NOGIT-2.2 — location checkout, scope depot" "$out" '"scope": "depot", "ws": "", "location": "checkout"'
[ -L "$NG/.planning/DRIVER.lock.d/repo/DRIVER.lock" ]; assert_exit "WS-NOGIT-2.3 — lien .planning/DRIVER.lock.d/repo/DRIVER.lock" "$?" 0
out="$(dl "$NG" sess-A status --ws=alpha)"
assert "WS-NOGIT-3.1 — status --ws=alpha hors git : owner m1, location checkout" "$out" '"owner": "m1"'
assert "WS-NOGIT-3.2 — status porte location checkout" "$out" '"location": "checkout"'
out="$(dl "$NG" sess-A release --ws=alpha --owner=m1)"
assert "WS-NOGIT-3.3 — release --ws=alpha hors git" "$out" '"released": true'
# Le chemin de repli est ignoré par le .gitignore du dépôt (mesuré sur une copie, dans un dépôt jetable).
REPO_ROOT="$(cd "$HERE/../../../.." && pwd)"
IGN="$WORK_DIR/ign"; mkdir -p "$IGN"; git -C "$IGN" init -q >/dev/null 2>&1
cp "$REPO_ROOT/.gitignore" "$IGN/.gitignore"
( cd "$IGN" && git check-ignore -q ".planning/DRIVER.lock.d/ws/alpha/DRIVER.lock" ); assert_exit "WS-NOGIT-4.1 — le verrou de compartiment de repli est ignoré par git" "$?" 0
( cd "$IGN" && git check-ignore -q ".planning/DRIVER.lock.d/repo/DRIVER.lock" ); assert_exit "WS-NOGIT-4.2 — le verrou de dépôt de repli est ignoré par git" "$?" 0
( cd "$IGN" && git check-ignore -q ".planning/DRIVER.lock.d/ws/alpha/DRIVER.lock.children.jsonl" ); assert_exit "WS-NOGIT-4.3 — le registre voisin du repli est ignoré par git" "$?" 0
( cd "$IGN" && git check-ignore -q ".planning/workstreams/alpha/STATE.md" ); assert_exit "WS-NOGIT-4.4 — témoin négatif : un fichier de compartiment n'est PAS ignoré (rc 1 attendu)" "$((1 - $?))" 0

echo
echo "=== WS-VFL — VF_DRIVER_LOCK posé force le mode verrou unique, même en lab partitionné (P57-D-22) ==="
LAB="$(mk_lab vfl)"; GC="$(fixture_common_dir "$LAB")"
VFL_PATH="$WORK_DIR/vfl-out/DRIVER.lock"; mkdir -p "$WORK_DIR/vfl-out"
out="$( export VF_DRIVER_LOCK="$VFL_PATH"; dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s )"; rc=$?
assert_exit "WS-VFL.1 — acquire --ws=alpha sous VF_DRIVER_LOCK : exit 0" "$rc" 0
assert "WS-VFL.2 — acquis" "$out" '"acquired": true'
assert_not "WS-VFL.3 — aucun champ de portée" "$out" '"scope"'
[ -L "$VFL_PATH" ]; assert_exit "WS-VFL.4 — verrou posé au chemin désigné" "$?" 0
[ ! -e "$GC/vf-driver" ]; assert_exit "WS-VFL.5 — rien dans le dossier commun du clone" "$?" 0
out="$( export VF_DRIVER_LOCK="$VFL_PATH"; dl "$LAB" sess-B acquire --depot --owner=m2 --step=s )"; rc=$?
assert_exit "WS-VFL.6 — --depot sans effet : le même verrou unique est tenu, refus exit 1" "$rc" 1
assert "WS-VFL.7 — reason held, held_by m1" "$out" '"held_by": "m1"'
out="$( export VF_DRIVER_LOCK="$VFL_PATH"; dl "$LAB" sess-B acquire --ws=zeta --owner=m2 --step=s )"; rc=$?
assert_exit "WS-VFL.8 — --ws=zeta (inconnu) sans effet : pas de refus de compartiment, refus held exit 1" "$rc" 1
assert_not "WS-VFL.9 — pas de unknown-ws" "$out" 'unknown-ws'
out="$( export VF_DRIVER_LOCK="$VFL_PATH"; dl "$LAB" sess-A status --ws=alpha )"
assert_not "WS-VFL.10 — status sans portée" "$out" '"scope"'
assert_not "WS-VFL.11 — status sans legacy_lock" "$out" 'legacy_lock'
assert "WS-VFL.12 — status lit le verrou désigné" "$out" '"owner": "m1"'

echo
echo "=== WS-FLATWS — lab plat : --ws et --depot sont acceptés et sans effet, octet pour octet (P57-D-03, P57-D-31) ==="
norm() { sed -e 's/[0-9]\{10\}/EPOCH/g' -e 's/"age_seconds": [0-9]*/"age_seconds": N/g' -e 's/"progress_age_seconds": [0-9]*/"progress_age_seconds": N/g' -e 's/"lease_seconds": [0-9]*/"lease_seconds": N/g' -e 's/\.gen\.EPOCH\.[0-9]*/.gen.EPOCH.PID/g'; }
flat_run() { # <nom> <opt> → écrit $WORK_DIR/flat-<nom>.out : acquire, status, release avec l'option
  local nom="$1" opt="$2" lab f
  lab="$(mk_flat "flat-$nom")"; f="$WORK_DIR/flat-$nom.out"; : > "$f"
  { dl "$lab" sess-A acquire ${opt:+"$opt"} --owner=m1 --step=s; echo "rc=$?"
    dl "$lab" sess-A status ${opt:+"$opt"}; echo "rc=$?"
    dl "$lab" sess-A release ${opt:+"$opt"} --owner=m1; echo "rc=$?"
  } 2>&1 | norm > "$f"
}
flat_run base ""
flat_run ws "--ws=alpha"
flat_run depot "--depot"
[ -s "$WORK_DIR/flat-base.out" ]; assert_exit "WS-FLATWS.1 — la sortie de référence n'est pas vide (témoin)" "$?" 0
assert "WS-FLATWS.2 — la référence contient acquire, status et release" "$(cat "$WORK_DIR/flat-base.out")" '"released": true'
cmp -s "$WORK_DIR/flat-base.out" "$WORK_DIR/flat-ws.out"; assert_exit "WS-FLATWS.3 — acquire/status/release --ws=alpha identiques à la référence" "$?" 0
cmp -s "$WORK_DIR/flat-base.out" "$WORK_DIR/flat-depot.out"; assert_exit "WS-FLATWS.4 — acquire/status/release --depot identiques à la référence" "$?" 0
assert_not "WS-FLATWS.5 — aucun champ de portée en lab plat" "$(cat "$WORK_DIR/flat-ws.out" "$WORK_DIR/flat-depot.out")" '"scope"'
assert_not "WS-FLATWS.6 — aucun legacy_lock en lab plat" "$(cat "$WORK_DIR/flat-ws.out" "$WORK_DIR/flat-depot.out")" 'legacy_lock'

echo
echo "=== WS-ALL — status --all : tous les verrous d'un lab partitionne d'un seul appel (P57-D-24, P57-D-31, P57-D-32) ==="
# Evalue une expression python sur le JSON passe en $1 (parse REEL, jamais un grep) ; imprime le resultat.
pj() { printf '%s' "$1" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(eval(sys.argv[1]))' "$2" 2>&1; }
LAB="$(mk_lab all1)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
dl "$LAB" sess-B acquire --depot --owner=m2 --step=sd >/dev/null
out="$(dl "$LAB" sess-A status --all)"; rc=$?
assert_exit "WS-ALL-1.1 — status --all exit 0" "$rc" 0
json_ok "$out"; assert_exit "WS-ALL-1.2 — une ligne JSON valide (parse python)" "$?" 0
assert "WS-ALL-1.3 — une seule ligne" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" "1"
assert "WS-ALL-1.4 — scope lab" "$(pj "$out" 'd["scope"]')" "lab"
assert "WS-ALL-1.5 — present vrai si au moins une entree est presente" "$(pj "$out" 'd["present"]')" "True"
assert "WS-ALL-1.6 — locks : depot, alpha, omega, dans cet ordre" "$(pj "$out" '[e["ws"] for e in d["locks"]]')" "['', 'alpha', 'omega']"
assert "WS-ALL-1.7 — omega est une entree absente" "$(pj "$out" '[e["present"] for e in d["locks"]]')" "[True, True, False]"
assert "WS-ALL-1.8 — chaque entree porte scope, ws et location" "$(pj "$out" 'all(k in e for e in d["locks"] for k in ("scope","ws","location"))')" "True"
assert "WS-ALL-1.9 — chaque entree presente conserve son ttl" "$(pj "$out" 'all(e["ttl"] == 1800 for e in d["locks"] if e["present"])')" "True"
assert "WS-ALL-1.10 — owners par entree" "$(pj "$out" '[e.get("owner") for e in d["locks"]]')" "['m2', 'm1', None]"
assert "WS-ALL-1.11 — scopes par entree" "$(pj "$out" '[e["scope"] for e in d["locks"]]')" "['depot', 'compartiment', 'compartiment']"
assert "WS-ALL-1.12 — legacy_lock faux au niveau lab" "$(pj "$out" 'd["legacy_lock"]')" "False"
assert "WS-ALL-1.13 — children_running somme (0)" "$(pj "$out" 'd["children_running"]')" "0"

LAB="$(mk_lab all2)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
dl "$LAB" sess-B acquire --depot --owner=m2 --step=sd >/dev/null
# verrou de compartiment tenu SANS dossier de compartiment sur le disque : pose en mode verrou unique
mkdir -p "$GC/vf-driver/ws/zeta"
( cd "$LAB" && VF_DRIVER_LOCK="$GC/vf-driver/ws/zeta/DRIVER.lock" CLAUDE_CODE_SESSION_ID=sess-Z "$SCRIPT" acquire --owner=mz --step=sz >/dev/null )
# noms forges dans le dossier commun : ne doivent JAMAIS entrer dans le JSON (T-57-38)
mkdir -p "$GC/vf-driver/ws/bad name/DRIVER.lock" "$GC/vf-driver/ws/a\"b/DRIVER.lock"
dl "$LAB" sess-A register --ws=alpha --agent=a1 --role=coder >/dev/null
dl "$LAB" sess-A register --ws=alpha --agent=a2 --role=coder >/dev/null
dl "$LAB" sess-A register --ws=omega --agent=a3 --role=coder >/dev/null
dl "$LAB" sess-A close --ws=omega --agent=a3 --status=done >/dev/null
dl "$LAB" sess-A register --depot --agent=a4 --role=coder >/dev/null
mk_legacy "$LAB" old
out="$(dl "$LAB" sess-A status --all)"; err="$(dl "$LAB" sess-A status --all 2>&1 >/dev/null)"
json_ok "$out"; assert_exit "WS-ALL-2.1 — JSON valide avec ancien verrou, zeta et noms forges" "$?" 0
assert "WS-ALL-2.2 — ordre : depot, ancien verrou, alpha, omega, zeta" "$(pj "$out" '[e["ws"] for e in d["locks"]]')" "['', '', 'alpha', 'omega', 'zeta']"
assert "WS-ALL-2.3 — l'entree de l'ancien verrou est marquee" "$(pj "$out" '[e.get("legacy_lock") for e in d["locks"]]')" "[None, True, None, None, None]"
assert "WS-ALL-2.4 — l'ancien verrou tient son propre owner" "$(pj "$out" 'd["locks"][1]["owner"]')" "old"
assert "WS-ALL-2.5 — zeta (sans dossier de compartiment) est present dans locks" "$(pj "$out" '[e["present"] for e in d["locks"] if e["ws"] == "zeta"]')" "[True]"
assert "WS-ALL-2.6 — legacy_lock vrai au niveau lab" "$(pj "$out" 'd["legacy_lock"]')" "True"
assert "WS-ALL-2.7 — children_running = somme des registres consignes (alpha 2 + omega 0 + depot 1)" "$(pj "$out" 'd["children_running"]')" "3"
assert "WS-ALL-2.8 — children_running par entree : depot 1, ancien 0, alpha 2, omega 0, zeta 0" "$(pj "$out" '[e["children_running"] for e in d["locks"]]')" "[1, 0, 2, 0, 0]"
assert_not "WS-ALL-2.9 — un nom forge n'est jamais imprime (espace)" "$out" "bad name"
assert_not "WS-ALL-2.10 — un nom forge n'est jamais imprime (guillemet)" "$out" 'a\"b'
assert "WS-ALL-2.11 — les noms ecartes sont signales sur stderr" "$err" "ecart"
assert "WS-ALL-2.12 — present vrai" "$(pj "$out" 'd["present"]')" "True"

LAB="$(mk_lab all3)"
out="$(dl "$LAB" sess-A status --all)"; rc=$?
assert_exit "WS-ALL-3.1 — aucun verrou tenu : exit 0" "$rc" 0
assert "WS-ALL-3.2 — present faux" "$(pj "$out" 'd["present"]')" "False"
assert "WS-ALL-3.3 — locks complet : depot, alpha, omega, tous absents" "$(pj "$out" '[(e["ws"], e["present"]) for e in d["locks"]]')" "[('', False), ('alpha', False), ('omega', False)]"
FLAT="$(mk_flat all3-flat)"
a="$(dl "$FLAT" sess-A status | norm)"; b="$(dl "$FLAT" sess-A status --all | norm)"
[ -n "$a" ]; assert_exit "WS-ALL-3.4 — temoin : status de lab plat non vide" "$?" 0
assert "WS-ALL-3.5 — lab plat vide : status --all identique a status" "[$b]" "[$a]"
dl "$FLAT" sess-A acquire --owner=m1 --step=s >/dev/null
a="$(dl "$FLAT" sess-A status | norm)"; b="$(dl "$FLAT" sess-A status --all | norm)"
assert "WS-ALL-3.6 — lab plat tenu : status --all identique a status" "[$b]" "[$a]"
assert_not "WS-ALL-3.7 — lab plat : aucun champ lab" "$b" '"locks"'
VP="$WORK_DIR/all3-vfl/DRIVER.lock"; mkdir -p "$WORK_DIR/all3-vfl"
( export VF_DRIVER_LOCK="$VP"; dl "$LAB" sess-A acquire --owner=m1 --step=s >/dev/null )
a="$( export VF_DRIVER_LOCK="$VP"; dl "$LAB" sess-A status | norm )"; b="$( export VF_DRIVER_LOCK="$VP"; dl "$LAB" sess-A status --all | norm )"
[ -n "$a" ]; assert_exit "WS-ALL-3.8 — temoin : status sous VF_DRIVER_LOCK non vide" "$?" 0
assert "WS-ALL-3.9 — VF_DRIVER_LOCK : status --all identique a status" "[$b]" "[$a]"
assert_not "WS-ALL-3.10 — VF_DRIVER_LOCK : aucun champ lab" "$b" '"locks"'

LAB="$(mk_lab all4)"
out="$(dl "$LAB" sess-A orphans --all 2>/dev/null)"; rc=$?
assert_exit "WS-ALL-4.1 — orphans --all : exit 1" "$rc" 1
assert "WS-ALL-4.2 — orphans --all : rien sur stdout" "[$out]" "[]"
err="$(dl "$LAB" sess-A orphans --all 2>&1 >/dev/null)"
assert "WS-ALL-4.3 — message d'usage sur stderr, --all nomme" "$err" "--all"
out="$(dl "$LAB" sess-A acquire --all --owner=m1 2>/dev/null)"; rc=$?
assert_exit "WS-ALL-4.4 — acquire --all : exit 1, rien acquis" "$rc" 1
assert "WS-ALL-4.5 — acquire --all : rien sur stdout" "[$out]" "[]"
FLAT="$(mk_flat all4-flat)"
dl "$FLAT" sess-A release --all --owner=m1 >/dev/null 2>&1; assert_exit "WS-ALL-4.6 — lab plat : release --all : exit 1 aussi" "$?" 1
out="$(dl "$LAB" sess-A status --all --ws=alpha)"; rc=$?
assert_exit "WS-ALL-4.7 — status --all --ws=alpha : exit 1" "$rc" 1
assert "WS-ALL-4.8 — reason ws-invalid, cle de tete error" "$out" '"error": "ws-invalid"'
assert_not "WS-ALL-4.9 — jamais present" "$out" '"present"'
json_ok "$out"; assert_exit "WS-ALL-4.10 — JSON valide" "$?" 0
out="$(dl "$LAB" sess-A status --all --depot)"; rc=$?
assert_exit "WS-ALL-4.11 — status --all --depot : exit 1" "$rc" 1
assert "WS-ALL-4.12 — reason ws-invalid" "$out" '"reason": "ws-invalid"'
LAB="$(mk_lab all4-unreadable)"
rm -rf "$LAB/.planning/workstreams"; printf 'pas un dossier\n' > "$LAB/.planning/workstreams"
out="$(dl "$LAB" sess-A status --all)"; rc=$?
assert_exit "WS-ALL-4.13 — workstreams illisible : exit 1" "$rc" 1
assert "WS-ALL-4.14 — partition-unreadable, cle de tete error" "$out" '"error": "partition-unreadable"'
assert_not "WS-ALL-4.15 — jamais present" "$out" '"present"'

echo
echo "=== WS-VERBS — tous les verbes visent le verrou de leur compartiment, et leur JSON le dit (P57-D-24, P57-D-32) ==="
# Valeur d'un champ du meta d'un verrou : <dossier commun> <ws|repo> <cle>
meta_of() { grep "^$3=" "$1/vf-driver/$2/DRIVER.lock/meta" 2>/dev/null | head -1 | cut -d= -f2-; }
# Antidate heartbeat ET progress d'un verrou (reecriture du meta, jamais une suppression).
backdate_lock() { # <dossier commun> <ws/alpha|repo>
  local m="$1/vf-driver/$2/DRIVER.lock/meta"
  sed -e 's/^heartbeat_epoch=.*/heartbeat_epoch=1000/' -e 's/^progress_epoch=.*/progress_epoch=1000/' "$m" > "$m.tmp" && mv "$m.tmp" "$m"
}
scoped() { # <id> <json> <scope> <ws> : le JSON est valide et porte scope, ws, location
  json_ok "$2"; assert_exit "$1.json — JSON valide" "$?" 0
  assert "$1.scope — scope $3, ws '$4', location" "$2" "\"scope\": \"$3\", \"ws\": \"$4\", \"location\": \"git-common-dir\""
}

LAB="$(mk_lab verbs1)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
dl "$LAB" sess-B acquire --depot --owner=m2 --step=sd >/dev/null
backdate_lock "$GC" ws/alpha; backdate_lock "$GC" repo
out="$(dl "$LAB" sess-A mark-progress --ws=alpha --owner=m1)"; rc=$?
assert_exit "WS-VERBS-1.1 — mark-progress --ws=alpha exit 0" "$rc" 0
scoped "WS-VERBS-1.2" "$out" compartiment alpha
assert "WS-VERBS-1.3 — progress_epoch d'alpha avance" "[$(meta_of "$GC" ws/alpha progress_epoch)]" "[$(printf '%s' "$out" | sed -n 's/.*"progress_epoch": \([0-9]*\).*/\1/p')]"
assert "WS-VERBS-1.4b — heartbeat_epoch d'alpha reste 1000" "$(meta_of "$GC" ws/alpha heartbeat_epoch)" "1000"
assert "WS-VERBS-1.5 — le depot n'a pas bouge (progress_epoch 1000)" "$(meta_of "$GC" repo progress_epoch)" "1000"
out="$(dl "$LAB" sess-A heartbeat --ws=alpha --owner=m1)"; rc=$?
assert_exit "WS-VERBS-1.6 — heartbeat --ws=alpha exit 0" "$rc" 0
scoped "WS-VERBS-1.7" "$out" compartiment alpha
assert_not "WS-VERBS-1.8 — heartbeat_epoch d'alpha avance" "[$(meta_of "$GC" ws/alpha heartbeat_epoch)]" "[1000]"
assert "WS-VERBS-1.9 — le depot n'a pas bouge (heartbeat_epoch 1000)" "$(meta_of "$GC" repo heartbeat_epoch)" "1000"
out="$(dl "$LAB" sess-A status --ws=alpha)"
assert "WS-VERBS-1.10 — status --ws=alpha lit l'avance (age_seconds < 100)" "$(pj "$out" 'd["age_seconds"] < 100')" "True"
out="$(dl "$LAB" sess-B status --depot)"
assert "WS-VERBS-1.11 — status --depot lit un verrou toujours perime" "$(pj "$out" 'd["stale"]')" "True"
out="$(dl "$LAB" sess-A heartbeat --ws=alpha --owner=autre)"; rc=$?
assert_exit "WS-VERBS-1.12 — heartbeat d'un autre owner : refus, exit 1" "$rc" 1
scoped "WS-VERBS-1.13" "$out" compartiment alpha
assert "WS-VERBS-1.14 — not-owner" "$out" '"reason": "not-owner"'
out="$(dl "$LAB" sess-A heartbeat --ws=omega --owner=m1)"; rc=$?
assert_exit "WS-VERBS-1.15 — heartbeat sur un compartiment non tenu : no-lock, exit 1" "$rc" 1
scoped "WS-VERBS-1.16" "$out" compartiment omega
assert "WS-VERBS-1.17 — no-lock" "$out" '"reason": "no-lock"'
out="$(dl "$LAB" sess-A mark-progress --ws=alpha)"; rc=$?
assert_exit "WS-VERBS-1.18 — mark-progress sans owner : exit 1" "$rc" 1
scoped "WS-VERBS-1.19" "$out" compartiment alpha
assert "WS-VERBS-1.20 — owner-required" "$out" '"error": "owner-required"'

LAB="$(mk_lab verbs2)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
dl "$LAB" sess-B acquire --depot --owner=m2 --step=sd >/dev/null
out="$(dl "$LAB" sess-T takeover --ws=alpha --owner=m9 --step=t)"; rc=$?
assert_exit "WS-VERBS-2.1 — takeover d'un alpha FRAIS : refus, exit 1" "$rc" 1
scoped "WS-VERBS-2.2" "$out" compartiment alpha
assert "WS-VERBS-2.3 — still-fresh" "$out" '"reason": "still-fresh"'
backdate_lock "$GC" ws/alpha
out="$(dl "$LAB" sess-T takeover --ws=alpha --owner=m9 --step=t)"; rc=$?
assert_exit "WS-VERBS-2.4 — takeover --ws=alpha d'un alpha perime : exit 0" "$rc" 0
scoped "WS-VERBS-2.5" "$out" compartiment alpha
assert "WS-VERBS-2.6 — acquis, previous_owner m1" "$out" '"previous_owner": "m1"'
assert "WS-VERBS-2.7 — le verrou d'alpha est a m9" "$(meta_of "$GC" ws/alpha owner)" "m9"
assert "WS-VERBS-2.8 — le depot est intact (m2)" "$(meta_of "$GC" repo owner)" "m2"
[ -f "$GC/vf-driver/ws/alpha/DRIVER.lock.events.log" ]; assert_exit "WS-VERBS-2.9 — journal des reprises frere du verrou d'alpha" "$?" 0
[ ! -e "$GC/vf-driver/repo/DRIVER.lock.events.log" ]; assert_exit "WS-VERBS-2.10 — aucun journal cote depot" "$?" 0
out="$(dl "$LAB" sess-NEW reclaim --ws=alpha --owner=m9)"; rc=$?
assert_exit "WS-VERBS-2.11 — reclaim --ws=alpha avec une session neuve : exit 0" "$rc" 0
scoped "WS-VERBS-2.12" "$out" compartiment alpha
assert "WS-VERBS-2.13 — reclaimed true, session sess-NEW" "$out" '"session_id": "sess-NEW"'
assert "WS-VERBS-2.14 — la session neuve est dans alpha" "$(meta_of "$GC" ws/alpha session_ids)" "sess-NEW"
assert_not "WS-VERBS-2.15 — pas dans le depot" "$(meta_of "$GC" repo session_ids)" "sess-NEW"
out="$(dl "$LAB" sess-NEW reclaim --ws=alpha --owner=autre)"; rc=$?
assert_exit "WS-VERBS-2.16 — reclaim d'un autre owner : refus, exit 1" "$rc" 1
scoped "WS-VERBS-2.17" "$out" compartiment alpha
out="$(dl "$LAB" sess-NEW recover --ws=alpha)"; rc=$?
assert_exit "WS-VERBS-2.18 — recover --ws=alpha d'un verrou frais : refus, exit 1" "$rc" 1
scoped "WS-VERBS-2.19" "$out" compartiment alpha
backdate_lock "$GC" ws/alpha
out="$(dl "$LAB" sess-NEW recover --ws=alpha)"; rc=$?
assert_exit "WS-VERBS-2.20 — recover --ws=alpha d'un verrou perime : exit 0" "$rc" 0
scoped "WS-VERBS-2.21" "$out" compartiment alpha
assert "WS-VERBS-2.22 — recovered true, previous_owner m9" "$out" '"previous_owner": "m9"'
[ ! -e "$GC/vf-driver/ws/alpha/DRIVER.lock" ]; assert_exit "WS-VERBS-2.23 — le verrou d'alpha est elague" "$?" 0
[ -L "$GC/vf-driver/repo/DRIVER.lock" ]; assert_exit "WS-VERBS-2.24 — le depot est toujours tenu" "$?" 0
out="$(dl "$LAB" sess-NEW recover --ws=alpha)"; rc=$?
assert_exit "WS-VERBS-2.25 — recover sans verrou : no-lock, exit 0" "$rc" 0
scoped "WS-VERBS-2.26" "$out" compartiment alpha
out="$(dl "$LAB" sess-T takeover --ws=omega --owner=m9)"; rc=$?
assert_exit "WS-VERBS-2.27 — takeover d'un compartiment non tenu : no-lock, exit 1" "$rc" 1
scoped "WS-VERBS-2.28" "$out" compartiment omega
out="$(dl "$LAB" sess-NEW reclaim --ws=omega --owner=m9)"; rc=$?
scoped "WS-VERBS-2.29" "$out" compartiment omega

LAB="$(mk_lab verbs3)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
OTHER="$WORK_DIR/other.children.jsonl"
out="$( export VF_DRIVER_CHILDREN="$OTHER"; dl "$LAB" sess-A register --ws=alpha --agent=a1 --role=coder --node=n1 )"; rc=$?
assert_exit "WS-VERBS-3.1 — register --ws=alpha exit 0" "$rc" 0
scoped "WS-VERBS-3.2" "$out" compartiment alpha
REGA="$GC/vf-driver/ws/alpha/DRIVER.lock.children.jsonl"
[ -f "$REGA" ]; assert_exit "WS-VERBS-3.3 — registre frere du verrou d'alpha" "$?" 0
[ ! -e "$OTHER" ]; assert_exit "WS-VERBS-3.4 — VF_DRIVER_CHILDREN ignoree en lab partitionne" "$?" 0
assert "WS-VERBS-3.5 — le JSON nomme le registre d'alpha" "$out" "\"registry\": \"$REGA\""
out="$( export VF_DRIVER_CHILDREN="$OTHER"; dl "$LAB" sess-A orphans --ws=alpha )"; rc=$?
assert_exit "WS-VERBS-3.6 — orphans --ws=alpha exit 0" "$rc" 0
scoped "WS-VERBS-3.7" "$out" compartiment alpha
assert "WS-VERBS-3.8 — un agent running dans alpha" "$(pj "$out" 'd["count"]')" "1"
out="$(dl "$LAB" sess-A orphans --depot)"
scoped "WS-VERBS-3.9" "$out" depot ""
assert "WS-VERBS-3.10 — le depot ne voit pas le registre d'alpha" "$(pj "$out" 'd["count"]')" "0"
out="$( export VF_DRIVER_CHILDREN="$OTHER"; dl "$LAB" sess-A close --ws=alpha --agent=a1 --status=done )"; rc=$?
assert_exit "WS-VERBS-3.11 — close --ws=alpha exit 0" "$rc" 0
scoped "WS-VERBS-3.12" "$out" compartiment alpha
assert "WS-VERBS-3.13 — previous_status running" "$out" '"previous_status": "running"'
out="$(dl "$LAB" sess-A orphans --ws=alpha)"
assert "WS-VERBS-3.14 — plus aucun agent running dans alpha" "$(pj "$out" 'd["count"]')" "0"
out="$(dl "$LAB" sess-A close --ws=omega --agent=a1 --status=done)"; rc=$?
assert_exit "WS-VERBS-3.15 — close dans un compartiment sans registre : no-registry, exit 1" "$rc" 1
scoped "WS-VERBS-3.16" "$out" compartiment omega
assert "WS-VERBS-3.17 — no-registry" "$out" '"reason": "no-registry"'
out="$(dl "$LAB" sess-A register --ws=alpha --agent=a2)"; rc=$?
assert_exit "WS-VERBS-3.18 — register sans role : exit 1" "$rc" 1
scoped "WS-VERBS-3.19" "$out" compartiment alpha
out="$(dl "$LAB" sess-A close --ws=alpha --agent=a1 --status=nimporte)"; rc=$?
assert_exit "WS-VERBS-3.20 — close avec un statut invalide : exit 1" "$rc" 1
scoped "WS-VERBS-3.21" "$out" compartiment alpha
out="$(dl "$LAB" sess-A release --ws=alpha --owner=m1)"
assert "WS-VERBS-3.22 — release --ws=alpha sans enfant ouvert supprime le registre d'alpha" "[$([ -e "$REGA" ] && echo present || echo absent)]" "[absent]"

LAB="$(mk_lab verbs4)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
dl "$LAB" sess-B acquire --depot --owner=m2 --step=sd >/dev/null
chk_depot() { # <id> <json> : portee depot, cible non designee
  scoped "$1" "$2" depot ""
  assert "$1.reason — scope_reason ws-absent" "$2" '"scope_reason": "ws-absent"'
}
out="$(dl "$LAB" sess-B heartbeat --owner=m2)"; chk_depot "WS-VERBS-4.1" "$out"
assert "WS-VERBS-4.1b — ok true" "$out" '"ok": true'
out="$(dl "$LAB" sess-B mark-progress --owner=m2)"; chk_depot "WS-VERBS-4.2" "$out"
out="$(dl "$LAB" sess-B2 reclaim --owner=m2)"; chk_depot "WS-VERBS-4.3" "$out"
assert "WS-VERBS-4.3b — reclaimed true" "$out" '"reclaimed": true'
out="$(dl "$LAB" sess-B takeover --owner=m2)"; chk_depot "WS-VERBS-4.4" "$out"
out="$(dl "$LAB" sess-B recover)"; chk_depot "WS-VERBS-4.5" "$out"
out="$(dl "$LAB" sess-B register --agent=d1 --role=coder)"; chk_depot "WS-VERBS-4.6" "$out"
[ -f "$GC/vf-driver/repo/DRIVER.lock.children.jsonl" ]; assert_exit "WS-VERBS-4.7 — registre du depot dans vf-driver/repo" "$?" 0
out="$(dl "$LAB" sess-B orphans)"; chk_depot "WS-VERBS-4.8" "$out"
assert "WS-VERBS-4.8b — un agent running au depot" "$(pj "$out" 'd["count"]')" "1"
out="$(dl "$LAB" sess-B close --agent=d1 --status=done)"; chk_depot "WS-VERBS-4.9" "$out"
assert "WS-VERBS-4.10 — alpha n'a jamais bouge (m1)" "$(meta_of "$GC" ws/alpha owner)" "m1"
out="$(dl "$LAB" sess-B release --owner=m2)"; chk_depot "WS-VERBS-4.11" "$out"
assert "WS-VERBS-4.11b — depot relache" "$out" '"released": true'
[ -L "$GC/vf-driver/ws/alpha/DRIVER.lock" ]; assert_exit "WS-VERBS-4.12 — alpha toujours tenu" "$?" 0
out="$(dl "$LAB" sess-B heartbeat --depot --owner=m2)"; rc=$?
assert_exit "WS-VERBS-4.13 — heartbeat --depot sur un depot relache : no-lock, exit 1" "$rc" 1
scoped "WS-VERBS-4.14" "$out" depot ""
assert_not "WS-VERBS-4.15 — --depot explicite : pas de scope_reason" "$out" 'scope_reason'

LAB="$(mk_lab verbs5)"
refus_case() { # <id> <cle de tete attendue> <verbe> <args...>
  local id="$1" key="$2" verb="$3" o r; shift 3
  o="$(dl "$LAB" sess-A "$verb" "$@" --ws=../x)"; r=$?
  assert_exit "$id.1 — $verb --ws=../x : exit 1" "$r" 1
  assert "$id.2 — cle de tete $key" "$o" "{$key"
  assert "$id.3 — reason ws-invalid" "$o" '"reason": "ws-invalid"'
  assert "$id.4 — hint present" "$o" '"hint": "'
  assert_not "$id.5 — la valeur brute n'est pas reimprimee" "$o" '../x'
  assert_not "$id.6 — jamais la cle present" "$o" '"present"'
  json_ok "$o"; assert_exit "$id.7 — JSON valide" "$?" 0
}
refus_case "WS-VERBS-5a" '"acquired": false' takeover --owner=m1
refus_case "WS-VERBS-5b" '"reclaimed": false' reclaim --owner=m1
refus_case "WS-VERBS-5c" '"ok": false' heartbeat --owner=m1
refus_case "WS-VERBS-5d" '"ok": false' mark-progress --owner=m1
refus_case "WS-VERBS-5e" '"released": false' release --owner=m1
refus_case "WS-VERBS-5f" '"recovered": false' recover
refus_case "WS-VERBS-5g" '"registered": false' register --agent=a --role=r
refus_case "WS-VERBS-5h" '"closed": false' close --agent=a --status=done
refus_case "WS-VERBS-5i" '"error": "ws-invalid"' orphans
refus_case "WS-VERBS-5j" '"error": "ws-invalid"' status

echo
echo "=== WS-HINT — le hint d'un refus, rejoué LITTÉRALEMENT, vise la cible du refus qui le porte (P57-D-24, correction R-1) ==="
# Un verrou de compartiment ET un verrou de dépôt, tous deux périmés, d'owners différents : un hint qui
# oublie l'option de cible reprend le mauvais des deux sans rien dire.
hint_of() { pj "$1" 'd["hint"]'; }
hint_replay() { # <lab> <session> <hint> : rejoue la commande nommée par le hint, mot pour mot (<etape> → s)
  local a; a="${3#*driver-lock.sh }"; a="${a//<etape>/s}"
  local -a w; read -r -a w <<< "$a"
  dl "$1" "$2" "${w[@]}"
}
LAB="$(mk_lab hint1)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
dl "$LAB" sess-D acquire --depot --owner=olddepot --step=sd >/dev/null
backdate_lock "$GC" ws/alpha; backdate_lock "$GC" repo
out="$(dl "$LAB" sess-N acquire --ws=alpha --owner=m2 --step=s)"; rc=$?
assert_exit "WS-HINT-1.1 — acquire --ws=alpha sur un alpha périmé : refus, exit 1" "$rc" 1
assert "WS-HINT-1.2 — reason stale-requires-takeover" "$out" '"reason": "stale-requires-takeover"'
h="$(hint_of "$out")"
assert "WS-HINT-1.3 — le hint nomme la cible du refus (--ws=alpha)" "$h" ' --ws=alpha'
assert "WS-HINT-1.4 — le hint garde son owner et son verbe" "$h" 'takeover --owner=m2'
out2="$(hint_replay "$LAB" sess-N "$h")"; rc=$?
assert_exit "WS-HINT-1.5 — le hint rejoué littéralement réussit" "$rc" 0
assert "WS-HINT-1.6 — il reprend le verrou du COMPARTIMENT (previous_owner m1)" "$out2" '"previous_owner": "m1"'
assert "WS-HINT-1.7 — portée compartiment alpha" "$out2" '"scope": "compartiment", "ws": "alpha"'
assert "WS-HINT-1.8 — le verrou de dépôt périmé n'a pas été repris" "$(meta_of "$GC" repo owner)" "olddepot"
assert "WS-HINT-1.9 — alpha est à m2" "$(meta_of "$GC" ws/alpha owner)" "m2"

LAB="$(mk_lab hint2)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
dl "$LAB" sess-D acquire --depot --owner=olddepot --step=sd >/dev/null
backdate_lock "$GC" ws/alpha; backdate_lock "$GC" repo
out="$(dl "$LAB" sess-N acquire --depot --owner=m2 --step=s)"; rc=$?
assert_exit "WS-HINT-2.1 — acquire --depot sur un dépôt périmé : refus, exit 1" "$rc" 1
h="$(hint_of "$out")"
assert "WS-HINT-2.2 — le hint nomme la cible du refus (--depot)" "$h" ' --depot'
out2="$(hint_replay "$LAB" sess-N "$h")"; rc=$?
assert_exit "WS-HINT-2.3 — le hint rejoué littéralement réussit" "$rc" 0
assert "WS-HINT-2.4 — il reprend le verrou de DÉPÔT (previous_owner olddepot)" "$out2" '"previous_owner": "olddepot"'
assert "WS-HINT-2.5 — portée dépôt" "$out2" '"scope": "depot"'
assert "WS-HINT-2.6 — alpha n'a pas été repris" "$(meta_of "$GC" ws/alpha owner)" "m1"

# Sans cible désignée (ni --ws ni --depot) en lab partitionné : la cible EST le dépôt, le hint le dit.
LAB="$(mk_lab hint3)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-D acquire --depot --owner=olddepot --step=sd >/dev/null
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=sa >/dev/null
backdate_lock "$GC" ws/alpha; backdate_lock "$GC" repo
out="$(dl "$LAB" sess-N acquire --owner=m2 --step=s)"
h="$(hint_of "$out")"
assert "WS-HINT-3.1 — cible implicite : le hint nomme --depot" "$h" ' --depot'
out2="$(hint_replay "$LAB" sess-N "$h")"
assert "WS-HINT-3.2 — rejoué, il reprend le dépôt" "$out2" '"previous_owner": "olddepot"'

# Lab PLAT : le hint reste celui d'avant la phase (octet pour octet, témoin WS-AB).
LAB="$(mk_flat hint4)"
dl "$LAB" sess-A acquire --owner=m1 --step=sa >/dev/null
sed -e 's/^heartbeat_epoch=.*/heartbeat_epoch=1000/' -e 's/^progress_epoch=.*/progress_epoch=1000/' "$LAB/.planning/DRIVER.lock/meta" > "$LAB/.planning/DRIVER.lock/meta.tmp" \
  && mv "$LAB/.planning/DRIVER.lock/meta.tmp" "$LAB/.planning/DRIVER.lock/meta"
out="$(dl "$LAB" sess-N acquire --owner=m2 --step=s)"
assert "WS-HINT-4.1 — lab plat : hint inchangé" "$(hint_of "$out")" 'driver-lock.sh takeover --owner=m2 --step=<etape>'
assert_not "WS-HINT-4.2 — lab plat : aucune option de cible dans le hint" "$(hint_of "$out")" ' --'"depot"

if [ "$DLWS_MODE" = full ]; then
echo
echo "=== WS-CONC — un SEUL gagnant par verrou sous concurrence : 24 par verrou × 5 tours (patron T13/T32, P57-D-12) ==="
# Protocole de test-driver-lock.sh T13/T32 : lancement en arrière-plan, `wait`, gagnants comptés par
# fichier contenant `"acquired": true` (boucle shell, aucun pipeline de comptage). Fixtures sous $WORK_DIR
# seulement (préflight de mk_lab) ; le dossier de verrous du clone est vidé entre deux tours.
CONC_N=24; CONC_ROUNDS=5
num_eq() { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
conc_won() { # <préfixe de fichiers résultat> → nombre de fichiers où un verrou a été acquis
  local f n=0
  for f in "$1"*; do [ -e "$f" ] || continue; grep -q '"acquired": true' "$f" && n=$((n+1)); done
  printf '%s' "$n"
}
# Témoin du compteur lui-même (un compteur incapable de voir 0 ou 2 gagnants rendrait un vert à vide) :
# trois fichiers synthétiques, deux « acquired: true » → 2 ; aucun → 0.
mkdir -p "$WORK_DIR/conc-temoin"
printf '{"acquired": true}\n' > "$WORK_DIR/conc-temoin/w.1"; printf '{"acquired": true}\n' > "$WORK_DIR/conc-temoin/w.2"
printf '{"acquired": false}\n' > "$WORK_DIR/conc-temoin/w.3"; printf '{"acquired": false}\n' > "$WORK_DIR/conc-temoin/l.1"
num_eq "WS-CONC-TEMOIN.1 — le compteur voit 2 gagnants quand il y en a 2" "$(conc_won "$WORK_DIR/conc-temoin/w.")" 2
num_eq "WS-CONC-TEMOIN.2 — le compteur voit 0 gagnant quand il n'y en a aucun" "$(conc_won "$WORK_DIR/conc-temoin/l.")" 0
# Antidate le heartbeat d'un verrou posé (réécriture du meta, jamais une suppression) : périmé au sens du TTL.
conc_age() { # <dossier commun> <chemin relatif sous vf-driver du lien DRIVER.lock>
  local m="$1/vf-driver/$2/meta"
  sed 's/^heartbeat_epoch=.*/heartbeat_epoch=1000/' "$m" > "$m.tmp" && mv "$m.tmp" "$m"
}

# --- WS-CONC-ACQ : deux compartiments EN MÊME TEMPS, 24 acquéreurs chacun, 5 tours ---
LAB="$(mk_lab conc-acq)"; GC="$(fixture_common_dir "$LAB")"; R="$WORK_DIR/conc-acq.res"
bad=0; worst_round=0; worst_a=1; worst_o=1; t0=$SECONDS
for round in $(seq 1 "$CONC_ROUNDS"); do
  rm -rf "$GC/vf-driver" "$R".*
  for i in $(seq 1 "$CONC_N"); do
    ( dl "$LAB" "sess-A$i" acquire --ws=alpha --owner="A$i" --step=y >"$R.a$i" 2>/dev/null ) &
    ( dl "$LAB" "sess-O$i" acquire --ws=omega --owner="O$i" --step=y >"$R.o$i" 2>/dev/null ) &
  done
  wait
  wa="$(conc_won "$R.a")"; wo="$(conc_won "$R.o")"
  if [ "$wa" -ne 1 ] || [ "$wo" -ne 1 ]; then bad=$((bad+1)); worst_round="$round"; worst_a="$wa"; worst_o="$wo"; fi
done
[ "$bad" -eq 0 ] || echo "     pire tour : tour $worst_round, alpha=$worst_a gagnant(s), omega=$worst_o gagnant(s)"
num_eq "WS-CONC-ACQ — $CONC_ROUNDS tours × ($CONC_N alpha + $CONC_N omega) simultanés : rounds hors contrat : $bad (attendu 1 gagnant par compartiment à chaque tour ; ${SECONDS}s écoulées, ce bloc $((SECONDS-t0))s)" "$bad" 0
rm -rf "$R".*

# --- WS-CONC-TKO : takeover concurrent d'un verrou PÉRIMÉ, par compartiment ---
LAB="$(mk_lab conc-tko)"; GC="$(fixture_common_dir "$LAB")"; R="$WORK_DIR/conc-tko.res"
bad=0; worst_round=0; worst_a=1; worst_o=1; t0=$SECONDS
for round in $(seq 1 "$CONC_ROUNDS"); do
  rm -rf "$GC/vf-driver" "$R".*
  dl "$LAB" sess-DA acquire --ws=alpha --owner=DEAD-A --step=x >/dev/null 2>&1
  dl "$LAB" sess-DO acquire --ws=omega --owner=DEAD-O --step=x >/dev/null 2>&1
  conc_age "$GC" ws/alpha/DRIVER.lock; conc_age "$GC" ws/omega/DRIVER.lock
  for i in $(seq 1 "$CONC_N"); do
    ( dl "$LAB" "sess-A$i" takeover --ws=alpha --owner="TA$i" --step=y >"$R.a$i" 2>/dev/null ) &
    ( dl "$LAB" "sess-O$i" takeover --ws=omega --owner="TO$i" --step=y >"$R.o$i" 2>/dev/null ) &
  done
  wait
  wa="$(conc_won "$R.a")"; wo="$(conc_won "$R.o")"
  if [ "$wa" -ne 1 ] || [ "$wo" -ne 1 ]; then bad=$((bad+1)); worst_round="$round"; worst_a="$wa"; worst_o="$wo"; fi
done
[ "$bad" -eq 0 ] || echo "     pire tour : tour $worst_round, alpha=$worst_a gagnant(s), omega=$worst_o gagnant(s)"
num_eq "WS-CONC-TKO — $CONC_ROUNDS tours × ($CONC_N takeover alpha + $CONC_N omega) sur verrous périmés : rounds hors contrat : $bad (attendu 1 gagnant par compartiment ; ce bloc $((SECONDS-t0))s)" "$bad" 0
rm -rf "$R".*

# --- WS-CONC-DEPOT : le verrou de dépôt, 24 acquéreurs ---
LAB="$(mk_lab conc-depot)"; GC="$(fixture_common_dir "$LAB")"; R="$WORK_DIR/conc-depot.res"
bad=0; worst_round=0; worst=1; t0=$SECONDS
for round in $(seq 1 "$CONC_ROUNDS"); do
  rm -rf "$GC/vf-driver" "$R".*
  for i in $(seq 1 "$CONC_N"); do ( dl "$LAB" "sess-D$i" acquire --depot --owner="D$i" --step=y >"$R.d$i" 2>/dev/null ) & done
  wait
  w="$(conc_won "$R.d")"
  if [ "$w" -ne 1 ]; then bad=$((bad+1)); worst_round="$round"; worst="$w"; fi
done
[ "$bad" -eq 0 ] || echo "     pire tour : tour $worst_round, $worst gagnant(s)"
num_eq "WS-CONC-DEPOT — $CONC_ROUNDS tours × $CONC_N acquire --depot simultanés : rounds hors contrat : $bad (attendu 1 gagnant ; ce bloc $((SECONDS-t0))s)" "$bad" 0
rm -rf "$R".*

# --- WS-CONC-WT : 12 depuis le checkout principal + 12 depuis un worktree lié, même compartiment ---
LAB="$(mk_lab conc-wt)"; GC="$(fixture_common_dir "$LAB")"; R="$WORK_DIR/conc-wt.res"
WT="$WORK_DIR/conc-wt-tree"
git -C "$LAB" worktree add -q -b conc-wt-branch "$WT" >/dev/null 2>&1
wtc="$(fixture_common_dir "$WT")" || wtc=""
if [ "$wtc" != "$GC" ]; then echo "PRÉFLIGHT FIXTURE CASSÉ — worktree '$wtc' ≠ clone '$GC'" >&2; exit 2; fi
bad=0; worst_round=0; worst=1; t0=$SECONDS; HALF=$((CONC_N/2))
for round in $(seq 1 "$CONC_ROUNDS"); do
  rm -rf "$GC/vf-driver" "$R".*
  for i in $(seq 1 "$HALF"); do
    ( dl "$LAB" "sess-M$i" acquire --ws=alpha --owner="M$i" --step=y >"$R.m$i" 2>/dev/null ) &
    ( dl "$WT"  "sess-W$i" acquire --ws=alpha --owner="W$i" --step=y >"$R.w$i" 2>/dev/null ) &
  done
  wait
  w="$(conc_won "$R.m")"; w=$((w + $(conc_won "$R.w")))
  if [ "$w" -ne 1 ]; then bad=$((bad+1)); worst_round="$round"; worst="$w"; fi
done
[ "$bad" -eq 0 ] || echo "     pire tour : tour $worst_round, $worst gagnant(s) au total"
num_eq "WS-CONC-WT — $CONC_ROUNDS tours × ($HALF checkout principal + $HALF worktree lié) sur alpha : rounds hors contrat : $bad (attendu 1 gagnant au total ; ce bloc $((SECONDS-t0))s)" "$bad" 0
rm -rf "$R".*
leftover="$(ls -d "$WT"/.planning/DRIVER.lock* "$LAB"/.planning/DRIVER.lock* 2>/dev/null)"
assert "WS-CONC-WT.2 — aucun .planning/DRIVER.lock* créé dans le principal ni le worktree" "[$leftover]" "[]"

fi   # DLWS_MODE = full (concurrence)

echo
echo "=== WS-AB — lab plat : la copie gelée d'avant la phase et le script courant rendent la MÊME transcription, octet pour octet (P57-D-03, P57-D-37) ==="
# Référence : copie gelée de driver-lock.sh d'avant la Phase 57 (dernier commit e8771d94 qui touchait le
# script), jamais modifiée. Même séquence jouée par elle et par le script courant, chacun sur une fixture
# reconstruite à neuf AU MÊME CHEMIN (les champs `lock`/`registry` portent des chemins), transcriptions
# (code, stdout, stderr de chaque étape) normalisées puis comparées par `cmp -s` : une assertion de
# sous-chaîne ne prouve pas le bit près (piège P10).
# A/B : --help est EXCLU, et par construction : l'aide s'imprime depuis les lignes `# ` de l'en-tête du
# script (`grep '^# ' "$0"`), que les plans de la phase ont réécrites — la comparer rougirait à tort (P57-D-37).
FROZEN="$HERE/fixtures/driver-lock-pre-e8771d9.sh"
AB_REF=e8771d94
AB_PATH_IN_REF=plugin/conductor/scripts/driver-lock.sh
echo "  A/B : --help exclu (P57-D-37)"

# Normalisation : le chemin du script (la ligne `Usage:` l'imprime par $0), epoch à 10 chiffres, âges, ISO,
# suffixe de génération `.gen.<epoch>.<pid>`. Les âges avant l'epoch générique pour garder leur clé lisible.
ab_norm() { # <chemin du script à masquer> ; tout en ERE (-E), jamais de mélange avec la BRE
  sed -E -e "s|$1|<SCRIPT>|g" \
      -e 's/\.gen\.[0-9]{10}\.[0-9]*/.gen.EPOCH.PID/g' \
      -e 's/"(age_seconds|lease_seconds|progress_age_seconds)": [0-9]+/"\1": N/g' \
      -e 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]*/ISO/g' \
      -e 's/[0-9]{10}/EPOCH/g'
}

# ab_run <script> <chemin VF_DRIVER_LOCK ou vide> <fichier de transcription normalisée>
ab_run() {
  local script="$1" lock="$2" out="$3" lab="$WORK_DIR/ab/lab" raw="$WORK_DIR/ab.raw" lockpath
  rm -rf "$WORK_DIR/ab"; mkdir -p "$lab/.planning"
  printf '# projet\n' > "$lab/.planning/PROJECT.md"
  printf -- '---\nstatus: active\n---\n' > "$lab/.planning/STATE.md"
  git -C "$lab" init -q -b main >/dev/null 2>&1 || git -C "$lab" init -q >/dev/null 2>&1
  git -C "$lab" add -A >/dev/null 2>&1
  git -C "$lab" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m init >/dev/null 2>&1
  preflight "$lab"
  lockpath="${lock:-.planning/DRIVER.lock}"
  : > "$raw"
  ab_step() { # <nom> <session> <args...>
    local name="$1" sid="$2" rc; shift 2
    if [ -n "$lock" ]; then
      ( cd "$lab" && export VF_DRIVER_LOCK="$lock" CLAUDE_CODE_SESSION_ID="$sid" && "$script" "$@" ) >"$WORK_DIR/ab.so" 2>"$WORK_DIR/ab.se"; rc=$?
    else
      ( cd "$lab" && export CLAUDE_CODE_SESSION_ID="$sid" && "$script" "$@" ) >"$WORK_DIR/ab.so" 2>"$WORK_DIR/ab.se"; rc=$?
    fi
    { echo "### $name rc=$rc"; echo "--- stdout"; cat "$WORK_DIR/ab.so"; echo "--- stderr"; cat "$WORK_DIR/ab.se"; } >> "$raw"
  }
  ab_age() { # antidate le heartbeat du verrou (identique des deux côtés)
    local m="$lab/$lockpath/meta"
    sed 's/^heartbeat_epoch=.*/heartbeat_epoch=1000/' "$m" > "$m.tmp" && mv "$m.tmp" "$m"
  }
  ab_step "01 acquire m1"                 sess-A acquire --owner=m1 --step=s1
  ab_step "02 acquire m1 (même owner)"    sess-A acquire --owner=m1 --step=s1
  ab_step "03 acquire m2 (autre owner)"   sess-B acquire --owner=m2 --step=s2
  ab_step "04 status"                     sess-A status
  ab_step "05 heartbeat"                  sess-A heartbeat --owner=m1 --step=s3
  ab_step "06 mark-progress"              sess-A mark-progress --owner=m1
  ab_step "07 register"                   sess-A register --agent=a1 --role=coder --node=n1 --depth=2 --owner=m1
  ab_step "08 orphans"                    sess-A orphans
  ab_step "09 close"                      sess-A close --agent=a1 --status=done
  ab_step "10 reclaim (autre session)"    sess-C reclaim --owner=m1
  ab_step "11 status après reclaim"       sess-C status
  ab_age
  ab_step "12 acquire sur verrou périmé"  sess-B acquire --owner=m3 --step=s4
  ab_step "13 takeover"                   sess-B takeover --owner=m3 --step=s4
  ab_age
  ab_step "14 recover"                    sess-B recover
  ab_step "15 recover (rien à élaguer)"   sess-B recover
  ab_step "16 acquire m4"                 sess-D acquire --owner=m4 --step=s5
  ab_step "17 release m4"                 sess-D release --owner=m4
  ab_step "18 release m4 (déjà relâché)"  sess-D release --owner=m4
  ab_step "19 status final"               sess-D status
  ab_step "20 verbe inconnu"              sess-D frobnicate
  ab_norm "$script" < "$raw" > "$out"
}

# Première ligne divergente de deux transcriptions, avec son numéro (awk : jamais `diff`, qui ne sert pas
# à comparer des ensembles sur ce poste).
ab_first_divergence() { # <A> <B>
  awk 'NR==FNR{a[FNR]=$0; na=FNR; next} {nb=FNR; if(!(FNR in a) || a[FNR]!=$0){print "ligne " FNR " : A=[" a[FNR] "] B=[" $0 "]"; found=1; exit}} END{if(!found && na!=nb) print "longueurs différentes : A=" na " B=" nb}' "$1" "$2"
}

ab_ok=1
for mode in "sans VF_DRIVER_LOCK:" "avec VF_DRIVER_LOCK:.planning/alt/DRIVER.lock"; do
  label="${mode%%:*}"; lockv="${mode#*:}"
  ab_run "$FROZEN" "$lockv" "$WORK_DIR/ab-frozen.txt"
  ab_run "$SCRIPT" "$lockv" "$WORK_DIR/ab-current.txt"
  if [ -s "$WORK_DIR/ab-frozen.txt" ] && grep -q 'acquired": true' "$WORK_DIR/ab-frozen.txt" && grep -q 'released": true' "$WORK_DIR/ab-frozen.txt" \
     && grep -q 'stale-requires-takeover' "$WORK_DIR/ab-frozen.txt" && grep -q 'Unknown arg' "$WORK_DIR/ab-frozen.txt"; then
    assert_exit "WS-AB.témoin — la transcription de référence ($label) contient acquire, release, le refus périmé et le verbe inconnu" 0 0
  else
    assert_exit "WS-AB.témoin — la transcription de référence ($label) est vide ou incomplète" 1 0
  fi
  if cmp -s "$WORK_DIR/ab-frozen.txt" "$WORK_DIR/ab-current.txt"; then
    assert_exit "WS-AB.$label — copie gelée et script courant : transcriptions identiques ($(grep -c '^### ' "$WORK_DIR/ab-frozen.txt") étapes)" 0 0
  else
    assert_exit "WS-AB.$label — transcriptions DIFFÉRENTES" 1 0
    echo "     première divergence : $(ab_first_divergence "$WORK_DIR/ab-frozen.txt" "$WORK_DIR/ab-current.txt")"
    ab_ok=0
  fi
done
if [ "$ab_ok" = 1 ]; then echo "  A/B lab plat : IDENTIQUE"; else echo "  A/B lab plat : DIFFÉRENT"; fi

# Intégrité de la copie gelée (T-57-40) : identique au blob du dépôt quand l'objet est présent ; absent
# (clone superficiel de la CI), la ligne SKIP est écrite — jamais un vert muet.
if git -C "$HERE" cat-file -e "$AB_REF:$AB_PATH_IN_REF" 2>/dev/null; then
  git -C "$HERE" show "$AB_REF:$AB_PATH_IN_REF" > "$WORK_DIR/ab-ref.sh" 2>/dev/null
  cmp -s "$FROZEN" "$WORK_DIR/ab-ref.sh"; assert_exit "WS-AB-INTEGRITE.1 — la copie gelée est identique à git show $AB_REF:$AB_PATH_IN_REF" "$?" 0
else
  echo "  SKIP-INTEGRITE (objet absent) — $AB_REF non disponible localement (clone superficiel) : intégrité de la copie gelée NON vérifiée ici"
fi
[ -x "$FROZEN" ]; assert_exit "WS-AB-INTEGRITE.2 — la copie gelée est exécutable" "$?" 0

if [ "$DLWS_MODE" = full ]; then
echo
echo "=== MUTANTS DL-M-a à DL-M-i — chaque comportement neuf de driver-lock.sh rougit sous sa mutation (QUAL-01, P57-D-12, P57-D-28) ==="
# Chaque mutant = une substitution `sed` sur UNE ligne-ancre (compte = 1) d'une COPIE du script, posée à côté
# d'une copie de workstream-policy.sh (sinon policy-missing rougirait pour la mauvaise raison). La matrice (les
# cas WS-* hors concurrence, WS-AB compris) est rejouée en sous-processus contre la copie ; l'ensemble des cas
# dont le verdict bascule est comparé EXACTEMENT à l'attendu (un cas basculé hors de l'ensemble fait échouer).
MUT_KILLED=0; MUT_TOTAL=9; t0=$SECONDS
mut_families() { # <journal> → familles de cas en échec, triées, une par ligne
  LC_ALL=C sed -n 's/^  ❌ FAIL — \([^ ]*\) .*/\1/p' "$1" | LC_ALL=C sed 's/\..*$//' | LC_ALL=C sort -u
}
mut_trace() { # <journal> <famille> → première assertion violée de la famille, attendu/obtenu (octets : LC_ALL=C)
  LC_ALL=C awk -v f="$2" '
    /^  ❌ FAIL — /{ t=$0; sub(/^  ❌ FAIL — /,"",t); k=t; sub(/ .*$/,"",k); sub(/\..*$/,"",k)
                    if (!done && k==f) { print "      rouge " f " : " t; p=1; done=1; next } p=0 }
    p && /^     /{ print "        " $0; next }
    { p=0 }' "$1"
}
mut_run() { # <script> <journal> → code de sortie du sous-processus
  DLWS_MODE=matrice DLWS_SCRIPT="$1" bash "$SUITE" > "$2" 2>&1
}
MUT_IDS=""
mutant() { # <id> <ancre BRE> <expression sed s> <attendu : cas séparés par des espaces>
  # Prépare le mutant puis lance sa matrice EN ARRIÈRE-PLAN (neuf matrices en série dépassent la borne de durée) ;
  # le verdict est rendu par mutant_eval, dans l'ordre, après `wait`. Chaque sous-processus a son propre WORK_DIR.
  local id="$1" anchor="$2" expr="$3" expected="$4" dir="$WORK_DIR/mut-$1" n
  mkdir -p "$dir"; MUT_IDS="$MUT_IDS $id"
  printf '%s\n' $expected | LC_ALL=C sort -u > "$dir/attendu.txt"
  cp "$SCRIPT" "$dir/driver-lock.sh"; cp "$POLICY" "$dir/workstream-policy.sh"
  cp "$dir/driver-lock.sh" "$dir/copie-temoin.sh"
  n="$(grep -c -e "$anchor" "$dir/driver-lock.sh")"
  if [ "$n" != "1" ]; then echo "ancre non unique ($n occurrences de [$anchor])" > "$dir/prepko"; return; fi
  sed -i.bak -e "/$anchor/$expr" "$dir/driver-lock.sh"; rm -f "$dir/driver-lock.sh.bak"
  if cmp -s "$dir/driver-lock.sh" "$dir/copie-temoin.sh"; then echo "mutant NON OPPOSABLE : la substitution n'a rien changé" > "$dir/prepko"; return; fi
  if ! bash -n "$dir/driver-lock.sh" 2>/dev/null; then echo "le mutant n'est pas un script valide (il rougirait pour la mauvaise raison)" > "$dir/prepko"; return; fi
  chmod +x "$dir/driver-lock.sh"
  ( mut_run "$dir/driver-lock.sh" "$dir/matrice.log"; echo $? > "$dir/rc" ) &
}
mutant_eval() { # <id>
  local id="$1" dir="$WORK_DIR/mut-$1" rc got
  if [ -f "$dir/prepko" ]; then assert_exit "DL-M-$id — $(cat "$dir/prepko")" 1 0; return; fi
  rc="$(cat "$dir/rc" 2>/dev/null || echo absent)"
  if [ "$rc" != 0 ] && [ "$rc" != 1 ]; then assert_exit "DL-M-$id — la matrice a planté (exit $rc), pas un échec de cas" 1 0; return; fi
  grep -q '^=== Bilan : ' "$dir/matrice.log" || { assert_exit "DL-M-$id — la matrice n'a pas atteint son bilan" 1 0; return; }
  mut_families "$dir/matrice.log" > "$dir/obtenu.txt"
  got="$(tr '\n' ' ' < "$dir/obtenu.txt")"
  if cmp -s "$dir/attendu.txt" "$dir/obtenu.txt"; then
    assert_exit "DL-M-$id — mutant tué : bascule exactement {$(tr '\n' ' ' < "$dir/attendu.txt")}" 0 0
    while IFS= read -r fam; do mut_trace "$dir/matrice.log" "$fam"; done < "$dir/obtenu.txt"
    MUT_KILLED=$((MUT_KILLED+1))
  else
    assert_exit "DL-M-$id — ensemble basculé INATTENDU" 1 0
    echo "     attendu: {$(tr '\n' ' ' < "$dir/attendu.txt")}"
    echo "     obtenu:  {$got}"
  fi
}

# Témoin préalable : la copie NON mutée (script + politique côte à côte) ne bascule AUCUN cas.
mkdir -p "$WORK_DIR/mut-temoin"; cp "$SCRIPT" "$WORK_DIR/mut-temoin/driver-lock.sh"; cp "$POLICY" "$WORK_DIR/mut-temoin/workstream-policy.sh"
chmod +x "$WORK_DIR/mut-temoin/driver-lock.sh"
mut_run "$WORK_DIR/mut-temoin/driver-lock.sh" "$WORK_DIR/mut-temoin/matrice.log"; rc=$?
tn="$(mut_families "$WORK_DIR/mut-temoin/matrice.log" | wc -l | tr -d ' ')"
assert_exit "DL-M-témoin — la copie non mutée rend zéro cas en échec (exit $rc, $tn famille(s) en échec, ${SECONDS}s écoulées)" "$((rc + tn))" 0

mutant a 'd="$(git rev-parse --git-common-dir' 's@--git-common-dir@--git-dir@' "$MUT_A"
mutant b 'vf_ws_name_valid "$WS" ||' 's@vf_ws_name_valid "$WS" ||@true ||@' "$MUT_B"
mutant c 'DEPOT" = 1 ] || SCOPE_JSON' 's@SCOPE_JSON="$SCOPE_JSON, .*$@vf_dl_refuse ws-invalid "mutant"@' "$MUT_C"
mutant d 'lock_present || exit 0' 's@lock_present || exit 0@exit 0@' "$MUT_D"
mutant e '^  if \[ "$WS_GIVEN" = 1 \]; then$' 's@^  if \[ "$WS_GIVEN" = 1 \]; then$@  if [ -n "${GSD_WORKSTREAM:-}" ] \&\& [ "$WS_GIVEN" = 0 ]; then WS="$GSD_WORKSTREAM"; WS_GIVEN=1; fi; if [ "$WS_GIVEN" = 1 ]; then@' "$MUT_E"
mutant f '"step": "%s", "generation": "%s", "session_ids"' 's@"orphans": %s%s}@"orphans": %s%s, "x": 1}@' "$MUT_F"
mutant g 'z "${VF_DRIVER_LOCK:-}" ] || return 0' 's@\[ -z "${VF_DRIVER_LOCK:-}" \] || return 0@:@' "$MUT_G"
mutant h 'vf_dl_refuse partition-unreadable' 's@\*) vf_dl_refuse partition-unreadable .*@*) return 0 ;;@' "$MUT_H"
mutant i 'vf_ws_dir_resolve ".planning" "$WS"; rc=$?' 's@vf_ws_dir_resolve ".planning" "$WS"; rc=$?@_l="$(vf_ws_enumerate ".planning" 2>/dev/null)"; { for _e in $_l; do printf "%s\\n" "$_e"; sleep 0.3; done; } | grep -q -- "/$WS\$"; rc=$?@' "$MUT_I"

wait
for id in $MUT_IDS; do mutant_eval "$id"; done
echo "  durée des mutants : $((SECONDS-t0))s"
if [ "$MUT_KILLED" -eq "$MUT_TOTAL" ]; then
  echo "== mutants : 9/9 tués =="
else
  echo "== mutants : $MUT_KILLED/9 tués =="
  FAIL=$((FAIL+1))
fi
fi   # DLWS_MODE = full (mutants)

echo
echo "=== Bilan : $PASS PASS · $FAIL FAIL ==="
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$PASS" -gt 0 ] || { echo "❌ FAIL — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
