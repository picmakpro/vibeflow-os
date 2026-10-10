#!/usr/bin/env bash
# test-driver-lock-ws.sh — Suite NEUVE du verrou de driver PAR COMPARTIMENT (Phase 57, plan 57-01).
#
# Jamais un ajout à test-driver-lock.sh ni à test-guard-driver-lock.sh : ces deux suites sont le
# témoin de non-régression du lab PLAT (P57-D-03), elles ne bougent pas. Toute preuve neuve vit ici.
#
# Plan 57-02 : WS-LEG (ancien verrou), WS-LOC (worktrees), WS-NOGIT (repli hors git), WS-VFL (VF_DRIVER_LOCK),
# WS-FLATWS (options inertes en lab plat).
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
echo "=== Bilan : $PASS PASS · $FAIL FAIL ==="
[ "$PASS" -gt 0 ] || { echo "❌ FAIL — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
