#!/usr/bin/env bash
# test-driver-lock-ws.sh — Suite NEUVE du verrou de driver PAR COMPARTIMENT (Phase 57, plan 57-01).
#
# Jamais un ajout à test-driver-lock.sh : cette suite est le témoin de non-régression du lab PLAT (P57-D-03),
# elle ne bouge pas. test-guard-driver-lock.sh, elle, a bougé pendant la phase (S11, S13, C7u à C7zh, Q4, Q5) : son
# témoin du lab plat reste son cadre d'origine, ses cas partitionnés sont les ajouts de la phase. Toute preuve neuve du verrou vit ici.
#
# Plan 57-02 : WS-LEG (ancien verrou), WS-LOC (worktrees), WS-NOGIT (repli hors git), WS-VFL (VF_DRIVER_LOCK),
# WS-FLATWS (options inertes en lab plat).
# Plan 57-04 : WS-CONC (un gagnant par verrou sous concurrence, 24 x 5 tours), puis WS-AB et mutants DL-M-a a DL-M-i.
# Q5 (arbitrage Samuel, AskUserQuestion session principale, 2026-10-13) : WS-TKA à WS-TKD, takeover --ws applique la règle
# d'acquire vis-à-vis de l'ancien verrou (TKA vivant avant : refus legacy-lock-held ; TKB apparu entre la sonde et la pose :
# pose retirée, même refus ; TKC témoin sans ancien verrou ; TKD ancien verrou périmé : refus aligné sur acquire, stale-requires-takeover avec le
# hint recover, rien repris ni supprimé, arbitrage C option (a), AskUserQuestion session principale, 2026-10-13 ; TKB
# restitue en plus le verrou de compartiment antérieur, AU2-04). Mutants tk_nosonde (TKA), tk_reprobe_none, tk_restore_none,
# tk_gen_kept, tk_old_deleted (TKB), tk_stale_resume (TKD). Tour 3 (RV4-01, AU3-04) : la restitution est vérifiée, le refus libère
# le mutex et rend restore-failed si elle échoue ; mutants tk_mutex_kept, tk_restore_dir_none, tk_final_restore_none, tk_verify_none,
# tk_noclobber_none (WS-TKB.10 à 12, WS-TKR, WS-TKV, WS-TKP).
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
# c, d, g, i : les familles WS-ALL-5, WS-LEG-5, WS-R4A, WS-R4B et WS-R4C (réserve C3, correction R-4) rougissent aussi
# sous ces mutants (mesuré puis relu : le refus d'un compartiment, l'ancien verrou, la cible par dossier commun en dépendent)
MUT_C="WS-ALL-1 WS-ALL-2 WS-ALL-3 WS-ALL-5 WS-ENV WS-HINT-3 WS-LEG-1 WS-LEG-2 WS-LEG-3 WS-LEG-5 WS-NOWS WS-VERBS-4"
MUT_D="WS-LEG-1 WS-LEG-4 WS-R4A WS-R4B WS-TKA WS-TKB WS-TKD WS-TKR WS-TKV"
MUT_E="WS-ENV"
MUT_F="WS-AB"
MUT_G="WS-ALL-2 WS-ALL-3 WS-LEG-1 WS-LEG-2 WS-LEG-3 WS-LEG-4 WS-R4A WS-R4B WS-ROOT-13 WS-ROOT-6 WS-TKA WS-TKB WS-TKD WS-TKR WS-TKV WS-VFL"
MUT_H="WS-ALL-4 WS-RC2-file WS-RC2-lien"
# j (correction F-2, P57-D-39) : le refus hors racine du lab retiré — seuls les trois cas de refus de WS-ROOT basculent
# (g y ajoute WS-ROOT-6, le cas VF_DRIVER_LOCK ; i y ajoute WS-ROOT-8, le témoin acquire depuis la racine) ;
# WS-ROOT-12b bascule aussi : sans refus, les acquire 11/17/18 réussissent depuis le sous-dossier et y posent un verrou fantôme que le status voit
MUT_J="WS-ROOT-1 WS-ROOT-10 WS-ROOT-11 WS-ROOT-12b WS-ROOT-17 WS-ROOT-18 WS-ROOT-2 WS-ROOT-3 WS-ROOT-9"
# acq_fallback à gen_kept (réserve C3 de 57-VERIFICATION.md et correction R-4) : acq_fallback = acquire sans cible
# retombe sur le repli de l'ancien verrou (le suffixe JSON du refus change) ; fallback_depotpresent = le repli ne
# regarde plus si le verrou de dépôt existe ; skip_link_d = un lien symbolique n'est plus écarté par status --all ;
# reprobe_none = la re-sonde après la pose est neutralisée ; pose_kept = la pose du processus n'est pas retirée ;
# gen_kept = sa génération n'est pas retirée.
# k (revue adverse de #58) : status et orphans deviennent mutants — la garde « la racine git a .planning/, le cwd non »
# refuse alors aussi la lecture seule depuis un sous-dossier ; basculent les cas de non-refus de status : WS-ROOT-4 (lab
# partitionné), WS-ROOT-7 (lab plat, --ws), WS-ROOT-12 (assert_not) et WS-ROOT-12b (positif)
MUT_K="WS-ROOT-12 WS-ROOT-12b WS-ROOT-4 WS-ROOT-7"
MUT_ACQ="WS-LEG-1"
MUT_FDP="WS-LEG-5"
MUT_SKL="WS-ALL-5"
MUT_REP="WS-R4A WS-R4B"
# takeover --ws : tk_nosonde fait basculer WS-TKA ; tk_stale_resume (la sonde de tête ne refuse plus que le vivant) WS-TKD ;
# tk_reprobe_none, tk_restore_none (le verrou antérieur n'est pas restitué), tk_gen_kept, tk_old_deleted (old_gen supprimé avant la re-sonde) WS-TKB
MUT_TKH="WS-TKA WS-TKD"
MUT_TKR="WS-TKB"
MUT_TKO="WS-TKB"
MUT_TKS="WS-TKD"
# RV4-01 / AU3-04 : tk_mutex_kept (le mutex fuit après le refus : TKB.10-12, TKR.7-8), tk_restore_dir_none (le dossier réel
# n'est pas restitué : TKR, et TKV dont la copie perd son ancre), tk_final_restore_none (chemin final : TKP),
# tk_verify_none (la génération posée est supprimée sans constater la restitution : TKV), tk_noclobber_none (le mv écrase
# ou enterre : TKV)
MUT_TKM="WS-TKB WS-TKR"
MUT_TKRP="WS-TKB WS-TKR WS-TKV"   # tk_reprobe_none : la reprise réussit aussi sur les formes dossier réel
MUT_TKGK="WS-TKB WS-TKR"          # tk_gen_kept : la génération posée reste aussi après le refus en dossier réel
MUT_TKD2="WS-TKR WS-TKV"
MUT_TKF="WS-TKP"
MUT_TKV="WS-TKV"
MUT_I="WS-ALL-1 WS-ALL-2 WS-ALL-5 WS-DEPOT WS-ENV WS-FIRST WS-HINT-1 WS-HINT-2 WS-INV-lien WS-LEG-1 WS-LEG-2 WS-LEG-3 WS-LEG-4 WS-LOC-1 WS-LOC-3 WS-NOGIT-1 WS-NOGIT-3 WS-R4A WS-R4B WS-R4C WS-ROOT-8 WS-TKA WS-TKB WS-TKC WS-TKD WS-TKP WS-TKR WS-TKV WS-TRACE-1 WS-TRACE-2 WS-TRACE-3 WS-VERBS-1 WS-VERBS-2 WS-VERBS-3 WS-VERBS-4 WS-VIDE-temoin"
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
rc2_case lien  brk_link
rc2_case file  brk_file

echo
echo "=== WS-VIDE — dossier des compartiments présent mais SANS AUCUN compartiment : lab plat (P57-D-56, révise P57-D-25) ==="
# Le dossier vide, ou qui ne porte qu'un .gitkeep, se traite comme en v2.69.1 : le verrou unique de .planning/DRIVER.lock,
# sur TOUS les verbes (status et release compris). Le lien et le fichier à sa place restent refusés (WS-RC2-lien/file).
brk_empty()   { rm -rf "$1"; mkdir "$1"; }
brk_gitkeep() { rm -rf "$1"; mkdir "$1"; : > "$1/.gitkeep"; }
vide_case() { # <id> <fabrique la panne dans $1>
  local id="$1" breaker="$2" lab gc o r
  lab="$(mk_lab "vide-$id")"; gc="$(fixture_common_dir "$lab")"
  "$breaker" "$lab/.planning/workstreams"
  o="$(dl "$lab" sess-A status)"; r=$?
  assert_exit "WS-VIDE-$id.1 — status : exit 0 (jamais partition-unreadable)" "$r" 0
  assert_not "WS-VIDE-$id.2 — status : pas d'erreur de partition" "$o" 'partition-unreadable'
  assert "WS-VIDE-$id.3 — status : verrou libre" "$o" '"present": false'
  o="$(dl "$lab" sess-A release --owner=m1)"; r=$?
  assert_exit "WS-VIDE-$id.4 — release sans verrou : exit 0, comme un lab plat" "$r" 0
  o="$(dl "$lab" sess-A acquire --owner=m1 --step=s)"; r=$?
  assert_exit "WS-VIDE-$id.5 — acquire sans --ws : exit 0" "$r" 0
  assert "WS-VIDE-$id.6 — acquired true" "$o" '"acquired": true'
  assert_not "WS-VIDE-$id.7 — pas de portée de compartiment (sortie de lab plat)" "$o" '"scope"'
  [ -e "$lab/.planning/DRIVER.lock" ] || [ -L "$lab/.planning/DRIVER.lock" ]
  assert_exit "WS-VIDE-$id.8 — le verrou unique vit sous .planning/DRIVER.lock" "$?" 0
  [ ! -e "$gc/vf-driver" ]; assert_exit "WS-VIDE-$id.9 — rien sous le dossier commun (aucun verrou de compartiment)" "$?" 0
  o="$(dl "$lab" sess-A status)"; r=$?
  assert_exit "WS-VIDE-$id.10 — status du verrou tenu : exit 0" "$r" 0
  assert "WS-VIDE-$id.11 — propriétaire m1" "$o" '"owner": "m1"'
  o="$(dl "$lab" sess-A release --owner=m1)"; r=$?
  assert_exit "WS-VIDE-$id.12 — release : exit 0" "$r" 0
  assert "WS-VIDE-$id.13 — released true" "$o" '"released": true'
}
vide_case vide    brk_empty
vide_case gitkeep brk_gitkeep
# Témoin discriminant : un .gitkeep à côté d'un VRAI compartiment ne rend pas le lab plat.
lab="$(mk_lab vide-temoin)"; : > "$lab/.planning/workstreams/.gitkeep"
o="$(dl "$lab" sess-A acquire --ws=alpha --owner=m1 --step=s)"; r=$?
assert_exit "WS-VIDE-temoin.1 — .gitkeep + compartiment alpha : acquire --ws exit 0" "$r" 0
assert "WS-VIDE-temoin.2 — toujours un verrou de compartiment" "$o" '"scope": "compartiment"'

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
assert "WS-LEG-1.14 — le refus sans --ws garde la portée dépôt « ws-absent » (réserve C3, repli ancien verrou réservé aux autres verbes)" "$out" '"scope_reason": "ws-absent"'
assert_not "WS-LEG-1.15 — le refus d'acquire sans --ws ne porte jamais le suffixe du repli legacy" "$out" 'legacy-fallback'
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

echo
echo "=== WS-LEG-5 — verrou de dépôt ET ancien verrou présents : un verbe sans cible vise le dépôt, jamais le repli (P57-D-24 ; réserve C3) ==="
LAB="$(mk_lab leg5)"
dl "$LAB" sess-A acquire --depot --owner=m1 --step=s >/dev/null
mk_legacy "$LAB" old
out="$(dl "$LAB" sess-A status)"
assert "WS-LEG-5.1 — status sans cible lit le verrou de dépôt (owner m1)" "$out" '"owner": "m1"'
assert_not "WS-LEG-5.2 — aucun repli sur l'ancien verrou tant que le verrou de dépôt existe" "$out" 'legacy-fallback'

echo
echo "=== WS-R4 — l'ancien verrou apparaît ENTRE la sonde et la pose : la pose est retirée, le refus est celui d'un ancien verrou présent avant (correction R-4) ==="
# Ordonnancement déterministe : une COPIE du script (fabriquée ici, dossier temporaire de la suite, jamais un crochet en
# production) pose l'ancien verrou entre `ln_atomic` réussi et la re-sonde. L'appel interne passe par VF_DRIVER_LOCK
# (mode verrou unique, partition inerte) : pas de récursion.
mk_race_copy() { # <vivant|perime> <dossier> : écrit <dossier>/driver-lock.sh, côte à côte avec la politique
  mkdir -p "$2"; cp "$POLICY" "$2/workstream-policy.sh"
  python3 -I - "$SCRIPT" "$2/driver-lock.sh" "$1" <<'PYRACE'
import sys
src, dst, mode = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(src, encoding="utf-8").read()
a = '    if ! lock_present && ln_atomic "$gen" "$LOCK_DIR"; then\n'
inj = '( VF_DRIVER_LOCK=.planning/DRIVER.lock CLAUDE_CODE_SESSION_ID=sess-old bash "$0" acquire --owner=old --step=old >/dev/null 2>&1 )'
if mode == "perime":
    inj += '; sed "s/^heartbeat_epoch=.*/heartbeat_epoch=1000/" .planning/DRIVER.lock/meta > .planning/DRIVER.lock/meta.tmp && mv .planning/DRIVER.lock/meta.tmp .planning/DRIVER.lock/meta'
b = '    if ! lock_present && ln_atomic "$gen" "$LOCK_DIR" && { [ "$PARTITIONED" = 1 ] && { ' + inj + '; }; true; }; then\n'
if t.count(a) != 1:
    sys.stderr.write("ancre non unique (%d)\n" % t.count(a)); sys.exit(3)
open(dst, "w", encoding="utf-8").write(t.replace(a, b))
PYRACE
  chmod +x "$2/driver-lock.sh"
}
age_norm() { sed -E 's/"age_seconds": [0-9]+/"age_seconds": N/'; }
race_case() { # <A|B> <vivant|perime> <libellé du refus attendu> <reason> <fragment du hint>
  local tag="$1" mode="$2" reason="$4" hint="$5" lab ref gcm out before rc
  lab="$(mk_lab "r4$tag")"; gcm="$(fixture_common_dir "$lab")"
  mk_race_copy "$mode" "$WORK_DIR/race-$tag"
  out="$( cd "$lab" && CLAUDE_CODE_SESSION_ID=sess-A "$WORK_DIR/race-$tag/driver-lock.sh" acquire --ws=alpha --owner=m1 --step=s )"; rc=$?
  assert_exit "WS-R4$tag.1 — ancien verrou apparu entre la sonde et la pose ($mode) : exit 1" "$rc" 1
  assert "WS-R4$tag.2 — reason $reason" "$out" "\"reason\": \"$reason\""
  assert "WS-R4$tag.3 — held_by old" "$out" '"held_by": "old"'
  assert "WS-R4$tag.4 — hint : $hint" "$out" "$hint"
  json_ok "$out"; assert_exit "WS-R4$tag.5 — JSON valide" "$?" 0
  assert "WS-R4$tag.6 — le refus porte la portée demandée" "$out" '"scope": "compartiment", "ws": "alpha"'
  [ ! -e "$gcm/vf-driver/ws/alpha/DRIVER.lock" ] && [ ! -L "$gcm/vf-driver/ws/alpha/DRIVER.lock" ]
  assert_exit "WS-R4$tag.7 — la pose du processus est retirée : aucun verrou de compartiment" "$?" 0
  assert_exit "WS-R4$tag.8 — aucune génération laissée par la pose retirée" "$(find "$gcm/vf-driver/ws/alpha" -name 'DRIVER.lock.gen.*' 2>/dev/null | wc -l | tr -d ' ')" 0
  [ -L "$lab/.planning/DRIVER.lock" ]; assert_exit "WS-R4$tag.9 — l'ancien verrou est intact" "$?" 0
  # même refus que si l'ancien verrou était là AVANT (script ordinaire, ancien verrou posé d'abord)
  ref="$(mk_lab "r4ref$tag")"
  mk_legacy "$ref" old
  if [ "$mode" = perime ]; then backdate_legacy "$ref"; fi
  before="$(dl "$ref" sess-A acquire --ws=alpha --owner=m1 --step=s)"
  [ "$(printf '%s' "$out" | age_norm | sed "s|$lab|<LAB>|g")" = "$(printf '%s' "$before" | age_norm | sed "s|$ref|<LAB>|g")" ]
  assert_exit "WS-R4$tag.10 — MÊME refus, octet pour octet (âge normalisé), que celui d'un ancien verrou présent avant" "$?" 0
  [ "$(printf '%s' "$out" | python3 -c 'import json,sys; print(sorted(json.load(sys.stdin).keys()))')" = "$(printf '%s' "$before" | python3 -c 'import json,sys; print(sorted(json.load(sys.stdin).keys()))')" ]
  assert_exit "WS-R4$tag.11 — aucun champ JSON neuf, aucune valeur de reason neuve" "$?" 0
}
race_case A vivant x legacy-lock-held "release --owner=old"
race_case B perime x stale-requires-takeover "driver-lock.sh recover"
LAB="$(mk_lab r4ok)"
out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-R4C.1 — témoin : sans ancien verrou, la même acquisition réussit (la re-sonde ne refuse rien à tort)" "$rc" 0
assert "WS-R4C.2 — acquired true" "$out" '"acquired": true'

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

echo
echo "=== WS-ALL-5 — un lien symbolique parmi les verrous de compartiments est écarté, jamais listé (réserve C3) ==="
LAB="$(mk_lab all5)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s >/dev/null
mkdir -p "$WORK_DIR/lnkreal/DRIVER.lock"
printf 'owner=lien\nstep=x\nheartbeat_epoch=%s\n' "$(date +%s)" > "$WORK_DIR/lnkreal/DRIVER.lock/meta"
ln -s "$WORK_DIR/lnkreal" "$GC/vf-driver/ws/lnk"
out="$(dl "$LAB" sess-A status --all)"; err="$(dl "$LAB" sess-A status --all 2>&1 >/dev/null)"
assert "WS-ALL-5.1 — locks : depot, alpha, omega (le lien lnk n'y figure pas)" "$(pj "$out" '[e["ws"] for e in d["locks"]]')" "['', 'alpha', 'omega']"
assert "WS-ALL-5.2 — le lien est compté parmi les noms écartés (stderr)" "$err" "ecart"

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
echo "=== WS-TK — takeover --ws applique la règle d'acquire vis-à-vis de l'ancien verrou : sonde avant, re-sonde après la pose (Q5, arbitrage Samuel, AskUserQuestion session principale, 2026-10-13) ==="
# Compartiment alpha PÉRIMÉ (tenu par mA) + ancien verrou VIVANT : avant la correction, takeover rendait
# acquired true, recovered true (AUD-6). Le refus doit être celui d'acquire, octet pour octet (âge normalisé).
dir_mtime_ns() { python3 -I -c 'import os,sys; print(os.stat(sys.argv[1]).st_mtime_ns)' "$1"; }
backdate_alpha() { # <lab> : antidate heartbeat et progress du compartiment alpha de <lab>
  backdate_lock "$(fixture_common_dir "$1")" ws/alpha
}
LAB="$(mk_lab tka)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=mA --step=sa >/dev/null
backdate_alpha "$LAB"
mk_legacy "$LAB" old
tka_mt="$(dir_mtime_ns "$GC/vf-driver/ws/alpha")"
out="$(dl "$LAB" sess-T takeover --ws=alpha --owner=m9 --step=t)"; rc=$?
assert_exit "WS-TKA.1 — takeover d'un alpha périmé, ancien verrou vivant : refus, exit 1" "$rc" 1
assert "WS-TKA.2 — reason legacy-lock-held" "$out" '"reason": "legacy-lock-held"'
assert "WS-TKA.3 — held_by old" "$out" '"held_by": "old"'
assert "WS-TKA.4 — hint : release ciblé sur l'ancien verrou" "$out" "$LEGACY_ENV driver-lock.sh release --owner=old"
assert_not "WS-TKA.5 — aucun acquired true ni recovered" "$out" '"recovered"'
json_ok "$out"; assert_exit "WS-TKA.6 — JSON valide" "$?" 0
assert "WS-TKA.7 — le compartiment alpha est resté à mA (aucune reprise)" "$(meta_of "$GC" ws/alpha owner)" "mA"
[ ! -e "$GC/vf-driver/ws/alpha/DRIVER.lock.events.log" ]; assert_exit "WS-TKA.8 — aucun événement de reprise journalisé" "$?" 0
assert_exit "WS-TKA.9 — aucune génération neuve (une seule : celle de mA)" "$(find "$GC/vf-driver/ws/alpha" -name 'DRIVER.lock.gen.*' 2>/dev/null | wc -l | tr -d ' ')" 1
[ -L "$LAB/.planning/DRIVER.lock" ]; assert_exit "WS-TKA.10 — l'ancien verrou est intact" "$?" 0
assert "WS-TKA.12 — la sonde de tête refuse AVANT toute écriture : le dossier du compartiment n'a pas été touché (mtime_ns)" "$(dir_mtime_ns "$GC/vf-driver/ws/alpha")" "$tka_mt"
ref="$(mk_lab tkaref)"; mk_legacy "$ref" old
before="$(dl "$ref" sess-T acquire --ws=alpha --owner=m9 --step=t)"
[ "$(printf '%s' "$out" | age_norm | sed "s|$LAB|<LAB>|g")" = "$(printf '%s' "$before" | age_norm | sed "s|$ref|<LAB>|g")" ]
assert_exit "WS-TKA.11 — MÊME refus, octet pour octet (âge normalisé), que celui d'acquire" "$?" 0

# L'ancien verrou apparaît ENTRE la sonde de tête et la pose : la pose est retirée, le refus est celui d'un ancien
# verrou présent avant. Copie du script, dossier temporaire de la suite (jamais un crochet en production).
mk_takeover_race_copy() { # <dossier>
  mkdir -p "$1"; cp "$POLICY" "$1/workstream-policy.sh"
  python3 -I - "$SCRIPT" "$1/driver-lock.sh" <<'PYTK'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding="utf-8").read()
a = "      # R-4 (meme re-sonde qu'`acquire`)"
inj = '      ( VF_DRIVER_LOCK=.planning/DRIVER.lock CLAUDE_CODE_SESSION_ID=sess-old bash "$0" acquire --owner=old --step=old >/dev/null 2>&1 )\n'
if t.count(a) != 1:
    sys.stderr.write("ancre non unique (%d)\n" % t.count(a)); sys.exit(3)
open(dst, "w", encoding="utf-8").write(t.replace(a, inj + a))
PYTK
  chmod +x "$1/driver-lock.sh"
}
LAB="$(mk_lab tkb)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=mA --step=sa >/dev/null
dl "$LAB" sess-A register --ws=alpha --agent=ag-1 --role=r --node=n >/dev/null
backdate_alpha "$LAB"
tkb_link_avant="$(readlink "$GC/vf-driver/ws/alpha/DRIVER.lock")"
tkb_reg="$(ls "$GC"/vf-driver/ws/alpha/*children* 2>/dev/null | sed -n 1p)"
[ -n "$tkb_reg" ] && cp "$tkb_reg" "$WORK_DIR/tkb-reg-avant"
tkb_meta_avant="$(cat "$GC/vf-driver/ws/alpha/$tkb_link_avant/meta" 2>/dev/null)"
mk_takeover_race_copy "$WORK_DIR/race-tk"
out="$( cd "$LAB" && CLAUDE_CODE_SESSION_ID=sess-T "$WORK_DIR/race-tk/driver-lock.sh" takeover --ws=alpha --owner=m9 --step=t )"; rc=$?
assert_exit "WS-TKB.1 — ancien verrou apparu entre la sonde et la pose : exit 1" "$rc" 1
assert "WS-TKB.2 — reason legacy-lock-held" "$out" '"reason": "legacy-lock-held"'
assert "WS-TKB.3 — held_by old" "$out" '"held_by": "old"'
json_ok "$out"; assert_exit "WS-TKB.4 — JSON valide" "$?" 0
assert "WS-TKB.5 — la pose du processus est retirée ET le verrou antérieur est restitué : le lien vise de nouveau la génération de mA" "$(readlink "$GC/vf-driver/ws/alpha/DRIVER.lock")" "$tkb_link_avant"
assert_exit "WS-TKB.5b — la génération antérieure existe encore, meta octet pour octet" "$([ "$(cat "$GC/vf-driver/ws/alpha/$tkb_link_avant/meta" 2>/dev/null)" = "$tkb_meta_avant" ] && [ -n "$tkb_meta_avant" ]; echo $?)" 0
assert "WS-TKB.5c — owner du compartiment resté mA" "$(meta_of "$GC" ws/alpha owner)" "mA"
cmp -s "$tkb_reg" "$WORK_DIR/tkb-reg-avant" && [ -s "$WORK_DIR/tkb-reg-avant" ]; assert_exit "WS-TKB.5d — le registre des agents est intact, octet pour octet (et non vide)" "$?" 0
assert_exit "WS-TKB.6 — aucune génération laissée par la pose retirée (une seule : celle de mA)" "$(find "$GC/vf-driver/ws/alpha" -name 'DRIVER.lock.gen.*' 2>/dev/null | wc -l | tr -d ' ')" 1
[ -L "$LAB/.planning/DRIVER.lock" ]; assert_exit "WS-TKB.7 — l'ancien verrou est intact" "$?" 0
[ ! -e "$GC/vf-driver/ws/alpha/DRIVER.lock.events.log" ]; assert_exit "WS-TKB.8 — aucun événement de reprise journalisé" "$?" 0
[ "$(printf '%s' "$out" | age_norm | sed "s|$LAB|<LAB>|g")" = "$(printf '%s' "$before" | age_norm | sed "s|$ref|<LAB>|g")" ]
assert_exit "WS-TKB.9 — MÊME refus, octet pour octet (âge normalisé), que celui d'acquire avec ancien verrou présent avant" "$?" 0

# RV4-01 (mutex) : le refus de WS-TKB libère le mutex (nommé d'après old_gen, qui est restitué), sinon tout takeover ou
# reclaim suivant sur ce compartiment rendrait race-during-recovery pour toujours. Une fois l'ancien verrou levé, un
# second takeover réussit.
assert_exit "WS-TKB.10 — le mutex de reprise est libéré après le refus (aucun DRIVER.lock.rec.*)" "$(find "$GC/vf-driver/ws/alpha" -name 'DRIVER.lock.rec.*' 2>/dev/null | wc -l | tr -d ' ')" 0
( cd "$LAB" && VF_DRIVER_LOCK=.planning/DRIVER.lock CLAUDE_CODE_SESSION_ID=sess-old "$SCRIPT" release --owner=old >/dev/null 2>&1 )
out="$(dl "$LAB" sess-T takeover --ws=alpha --owner=m9 --step=t)"; rc=$?
assert_exit "WS-TKB.11 — ancien verrou levé : un second takeover du même compartiment réussit (pas de race-during-recovery permanent)" "$rc" 0
assert "WS-TKB.12 — acquired true, recovered true" "$out" '"acquired": true, "owner": "m9", "step": "t", "recovered": true'

# Copies du script pour les scénarios de restitution (dossier temporaire de la suite, jamais un crochet en production).
# race = ancien verrou apparu entre la sonde et la pose (comme mk_takeover_race_copy) ; gap = en plus, un tenant
# concurrent prend le nom ENTRE le retrait du lien et le `mv -n` de la restitution ; pubfail = la publication de la
# génération échoue après la mise de côté du dossier réel (chemin final). Une ancre absente laisse la copie intacte :
# les assertions du scénario rougissent alors (jamais un vert muet).
mk_takeover_copy() { # <dossier> <race|gap|pubfail>
  mkdir -p "$1"; cp "$POLICY" "$1/workstream-policy.sh"
  python3 -I - "$SCRIPT" "$1/driver-lock.sh" "$2" <<'PYTK2'
import sys
src, dst, mode = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(src, encoding="utf-8").read()
a = "      # R-4 (meme re-sonde qu'`acquire`)"
inj = '      ( VF_DRIVER_LOCK=.planning/DRIVER.lock CLAUDE_CODE_SESSION_ID=sess-old bash "$0" acquire --owner=old --step=old >/dev/null 2>&1 )\n'
if mode in ("race", "gap") and t.count(a) == 1:
    t = t.replace(a, inj + a)
if mode == "gap":
    g = 'rm -f "$LOCK_DIR"; mv_noclobber "${LOCK_DIR}.old.$$" "$LOCK_DIR"'
    if t.count(g) == 1:
        t = t.replace(g, 'rm -f "$LOCK_DIR"; mkdir "$LOCK_PARENT/GTENANT"; ln -s GTENANT "$LOCK_DIR"; mv_noclobber "${LOCK_DIR}.old.$$" "$LOCK_DIR"')
if mode == "pubfail":
    p = 'mv "$LOCK_DIR" "${LOCK_DIR}.old.$$" && ln_atomic "$gen" "$LOCK_DIR"'
    if t.count(p) == 1:
        t = t.replace(p, 'mv "$LOCK_DIR" "${LOCK_DIR}.old.$$" && false')
open(dst, "w", encoding="utf-8").write(t)
PYTK2
  chmod +x "$1/driver-lock.sh"
}
# Compartiment alpha sous forme « dossier réel » (lock legacy du compartiment : lock_present l'accepte, lock_gen rend
# `legacy`) : la génération posée par acquire devient le dossier DRIVER.lock lui-même.
mk_realdir_alpha() { # <lab>
  local gc a g; gc="$(fixture_common_dir "$1")"; a="$gc/vf-driver/ws/alpha"
  g="$(readlink "$a/DRIVER.lock")"; rm "$a/DRIVER.lock" && mv "$a/$g" "$a/DRIVER.lock"
}
count_in() { find "$1" -name "$2" 2>/dev/null | wc -l | tr -d ' '; }

# WS-TKR (AU3-04) : forme dossier réel (atteignable : un DRIVER.lock de compartiment posé à la main ou par une version
# antérieure ; lock_present l'accepte) ; l'ancien verrou apparaît entre la sonde et la pose. Le dossier est restitué par
# un seul `mv -n`, la génération posée est retirée APRÈS la restitution constatée, le mutex est libéré.
LAB="$(mk_lab tkr)"; GC="$(fixture_common_dir "$LAB")"; TKA="$GC/vf-driver/ws/alpha"
dl "$LAB" sess-A acquire --ws=alpha --owner=mA --step=sa >/dev/null
mk_realdir_alpha "$LAB"; backdate_alpha "$LAB"
cp "$TKA/DRIVER.lock/meta" "$WORK_DIR/tkr-meta-avant"
mk_takeover_copy "$WORK_DIR/tkr-copy" race
out="$( cd "$LAB" && CLAUDE_CODE_SESSION_ID=sess-T "$WORK_DIR/tkr-copy/driver-lock.sh" takeover --ws=alpha --owner=m9 --step=t )"; rc=$?
assert_exit "WS-TKR.1 — dossier réel, ancien verrou apparu entre la sonde et la pose : exit 1" "$rc" 1
assert "WS-TKR.2 — reason legacy-lock-held" "$out" '"reason": "legacy-lock-held"'
[ -d "$TKA/DRIVER.lock" ] && [ ! -L "$TKA/DRIVER.lock" ]; assert_exit "WS-TKR.3 — le dossier réel est restitué à sa place (ni lien ni absent)" "$?" 0
cmp -s "$TKA/DRIVER.lock/meta" "$WORK_DIR/tkr-meta-avant" && [ -s "$WORK_DIR/tkr-meta-avant" ]; assert_exit "WS-TKR.4 — meta octet pour octet" "$?" 0
assert_exit "WS-TKR.5 — aucun DRIVER.lock.old.* laissé" "$(count_in "$TKA" 'DRIVER.lock.old.*')" 0
assert_exit "WS-TKR.6 — la génération posée est retirée (aucun DRIVER.lock.gen.*)" "$(count_in "$TKA" 'DRIVER.lock.gen.*')" 0
assert_exit "WS-TKR.7 — le mutex de reprise est libéré (aucun DRIVER.lock.rec.*)" "$(count_in "$TKA" 'DRIVER.lock.rec.*')" 0
( cd "$LAB" && VF_DRIVER_LOCK=.planning/DRIVER.lock CLAUDE_CODE_SESSION_ID=sess-old "$SCRIPT" release --owner=old >/dev/null 2>&1 )
out="$(dl "$LAB" sess-T takeover --ws=alpha --owner=m9 --step=t)"; rc=$?
assert_exit "WS-TKR.8 — ancien verrou levé : un second takeover réussit" "$rc" 0

# WS-TKV (AU3-04) : un tenant concurrent prend le nom ENTRE le retrait du lien et la restitution. Rien n'est écrasé,
# rien n'est enterré dans sa génération, la génération posée et le dossier mis de côté restent en place, et le refus le dit.
LAB="$(mk_lab tkv)"; GC="$(fixture_common_dir "$LAB")"; TKA="$GC/vf-driver/ws/alpha"
dl "$LAB" sess-A acquire --ws=alpha --owner=mA --step=sa >/dev/null
mk_realdir_alpha "$LAB"; backdate_alpha "$LAB"
cp "$TKA/DRIVER.lock/meta" "$WORK_DIR/tkv-meta-avant"
mk_takeover_copy "$WORK_DIR/tkv-copy" gap
out="$( cd "$LAB" && CLAUDE_CODE_SESSION_ID=sess-T "$WORK_DIR/tkv-copy/driver-lock.sh" takeover --ws=alpha --owner=m9 --step=t )"; rc=$?
assert_exit "WS-TKV.1 — restitution impossible : exit 1" "$rc" 1
assert "WS-TKV.2 — le refus dit restore-failed (et non un refus d'ancien verrou)" "$out" '"reason": "restore-failed"'
json_ok "$out"; assert_exit "WS-TKV.3 — JSON valide" "$?" 0
assert "WS-TKV.4 — le tenant concurrent garde le nom (rien n'est écrasé)" "$(readlink "$TKA/DRIVER.lock")" "GTENANT"
assert_exit "WS-TKV.5 — rien n'est enterré dans la génération du tenant concurrent" "$(find "$TKA/GTENANT" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')" 0
assert_exit "WS-TKV.6 — le dossier mis de côté reste en place (un seul DRIVER.lock.old.*)" "$(count_in "$TKA" 'DRIVER.lock.old.*')" 1
old_dir="$(find "$TKA" -name 'DRIVER.lock.old.*' 2>/dev/null | sed -n 1p)"
cmp -s "$old_dir/meta" "$WORK_DIR/tkv-meta-avant" && [ -s "$WORK_DIR/tkv-meta-avant" ]; assert_exit "WS-TKV.7 — son meta est intact, octet pour octet" "$?" 0
assert_exit "WS-TKV.8 — la génération posée n'est PAS supprimée tant que la restitution n'est pas constatée (une DRIVER.lock.gen.*)" "$(count_in "$TKA" 'DRIVER.lock.gen.*')" 1
assert_exit "WS-TKV.9 — le mutex est tout de même libéré (aucun DRIVER.lock.rec.*)" "$(count_in "$TKA" 'DRIVER.lock.rec.*')" 0

# WS-TKP : la publication de la génération échoue après la mise de côté du dossier réel (chemin final) : le dossier est
# restitué, sans enterrement, la génération candidate retirée, le mutex libéré.
LAB="$(mk_lab tkp)"; GC="$(fixture_common_dir "$LAB")"; TKA="$GC/vf-driver/ws/alpha"
dl "$LAB" sess-A acquire --ws=alpha --owner=mA --step=sa >/dev/null
mk_realdir_alpha "$LAB"; backdate_alpha "$LAB"
cp "$TKA/DRIVER.lock/meta" "$WORK_DIR/tkp-meta-avant"
mk_takeover_copy "$WORK_DIR/tkp-copy" pubfail
out="$( cd "$LAB" && CLAUDE_CODE_SESSION_ID=sess-T "$WORK_DIR/tkp-copy/driver-lock.sh" takeover --ws=alpha --owner=m9 --step=t )"; rc=$?
assert_exit "WS-TKP.1 — publication échouée : exit 1" "$rc" 1
assert "WS-TKP.2 — reason race-during-recovery" "$out" '"reason": "race-during-recovery"'
[ -d "$TKA/DRIVER.lock" ] && [ ! -L "$TKA/DRIVER.lock" ]; assert_exit "WS-TKP.3 — le dossier réel est restitué à sa place" "$?" 0
cmp -s "$TKA/DRIVER.lock/meta" "$WORK_DIR/tkp-meta-avant" && [ -s "$WORK_DIR/tkp-meta-avant" ]; assert_exit "WS-TKP.4 — meta octet pour octet" "$?" 0
assert_exit "WS-TKP.5 — aucun DRIVER.lock.old.* ni DRIVER.lock.gen.* ni DRIVER.lock.rec.* laissé" "$(( $(count_in "$TKA" 'DRIVER.lock.old.*') + $(count_in "$TKA" 'DRIVER.lock.gen.*') + $(count_in "$TKA" 'DRIVER.lock.rec.*') ))" 0

# Témoin : sans ancien verrou, la même reprise réussit (la sonde ne refuse rien à tort).
LAB="$(mk_lab tkc)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=mA --step=sa >/dev/null
backdate_alpha "$LAB"
out="$(dl "$LAB" sess-T takeover --ws=alpha --owner=m9 --step=t)"; rc=$?
assert_exit "WS-TKC.1 — témoin : sans ancien verrou, takeover réussit" "$rc" 0
assert "WS-TKC.2 — acquired true, recovered true" "$out" '"acquired": true, "owner": "m9", "step": "t", "recovered": true'
# Ancien verrou PÉRIMÉ (arbitrage Samuel, AskUserQuestion session principale, 2026-10-13, C option (a)) : takeover --ws
# refuse exactement comme acquire dans le même état (stale-requires-takeover, hint recover) ; rien n'est repris ni supprimé.
LAB="$(mk_lab tkd)"; GC="$(fixture_common_dir "$LAB")"
dl "$LAB" sess-A acquire --ws=alpha --owner=mA --step=sa >/dev/null
dl "$LAB" sess-A register --ws=alpha --agent=ag-1 --role=r --node=n >/dev/null
backdate_alpha "$LAB"
mk_legacy "$LAB" old; backdate_legacy "$LAB"
tkd_link_avant="$(readlink "$GC/vf-driver/ws/alpha/DRIVER.lock")"
tkd_reg="$(ls "$GC"/vf-driver/ws/alpha/*children* 2>/dev/null | sed -n 1p)"
tkd_mt="$(dir_mtime_ns "$GC/vf-driver/ws/alpha")"
out="$(dl "$LAB" sess-T takeover --ws=alpha --owner=m9 --step=t)"; rc=$?
assert_exit "WS-TKD.1 — ancien verrou périmé : takeover refuse, exit 1" "$rc" 1
assert "WS-TKD.2 — reason stale-requires-takeover" "$out" '"reason": "stale-requires-takeover"'
assert "WS-TKD.3 — hint recover sur l'ancien verrou" "$out" "$LEGACY_ENV driver-lock.sh recover"
assert_not "WS-TKD.4 — aucun acquired true ni recovered" "$out" '"recovered"'
json_ok "$out"; assert_exit "WS-TKD.5 — JSON valide" "$?" 0
tkd_ref="$(mk_lab tkdref)"; mk_legacy "$tkd_ref" old; backdate_legacy "$tkd_ref"
dl "$tkd_ref" sess-A acquire --ws=alpha --owner=mA --step=sa >/dev/null
backdate_alpha "$tkd_ref"
tkd_acq="$(dl "$tkd_ref" sess-T acquire --ws=alpha --owner=m9 --step=t)"
[ "$(printf '%s' "$out" | age_norm | sed "s|$LAB|<LAB>|g")" = "$(printf '%s' "$tkd_acq" | age_norm | sed "s|$tkd_ref|<LAB>|g")" ] && [ -n "$tkd_acq" ]
assert_exit "WS-TKD.6 — MÊME refus, octet pour octet (âge normalisé), que celui d'acquire dans le même état (ancien verrou périmé)" "$?" 0
assert "WS-TKD.7 — le compartiment alpha périmé est resté à mA (lien intact)" "$(readlink "$GC/vf-driver/ws/alpha/DRIVER.lock")" "$tkd_link_avant"
assert "WS-TKD.8 — owner resté mA" "$(meta_of "$GC" ws/alpha owner)" "mA"
[ -s "$tkd_reg" ]; assert_exit "WS-TKD.9 — le registre des agents est intact" "$?" 0
[ -L "$LAB/.planning/DRIVER.lock" ]; assert_exit "WS-TKD.10 — l'ancien verrou périmé n'est pas supprimé" "$?" 0
[ ! -e "$GC/vf-driver/ws/alpha/DRIVER.lock.events.log" ]; assert_exit "WS-TKD.11 — aucun événement de reprise journalisé" "$?" 0
assert_exit "WS-TKD.12 — aucune génération neuve" "$(find "$GC/vf-driver/ws/alpha" -name 'DRIVER.lock.gen.*' 2>/dev/null | wc -l | tr -d ' ')" 1
assert "WS-TKD.13 — la sonde de tête refuse AVANT toute écriture : le dossier du compartiment n'a pas été touché (mtime_ns)" "$(dir_mtime_ns "$GC/vf-driver/ws/alpha")" "$tkd_mt"

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

echo "=== WS-ROOT — --ws ou --depot hors de la racine d'un lab partitionné : refus nommé not-at-lab-root, jamais un verrou parasite (P57-D-39, correction F-2) ==="
LAB="$(mk_lab root)"; GC="$(fixture_common_dir "$LAB")"
mkdir -p "$LAB/plugin/sub" "$LAB/autre/.planning"
SUBD="$LAB/plugin/sub"
dl_in() { # <cwd> <session> <args...> : le script lancé depuis un dossier donné (sous-dossier du lab)
  local cwd="$1" sid="$2"; shift 2
  ( cd "$cwd" && CLAUDE_CODE_SESSION_ID="$sid" "${DL_SCRIPT:-$SCRIPT}" "$@" )
}
out="$(dl_in "$SUBD" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-ROOT-1.1 — acquire --ws depuis un sous-dossier : exit 1" "$rc" 1
assert "WS-ROOT-1.2 — reason not-at-lab-root" "$out" '"reason": "not-at-lab-root"'
assert "WS-ROOT-1.3 — le hint dit de lancer depuis la racine du lab" "$out" 'racine du lab'
json_ok "$out"; assert_exit "WS-ROOT-1.4 — JSON valide" "$?" 0
[ ! -e "$GC/vf-driver" ] && [ ! -e "$SUBD/.planning" ]; assert_exit "WS-ROOT-1.5 — ni verrou ni .planning parasite créés" "$?" 0
out="$(dl_in "$SUBD" sess-A acquire --depot --owner=m1 --step=s)"; rc=$?
assert_exit "WS-ROOT-2.1 — acquire --depot depuis un sous-dossier : exit 1" "$rc" 1
assert "WS-ROOT-2.2 — reason not-at-lab-root" "$out" '"reason": "not-at-lab-root"'
[ ! -e "$GC/vf-driver" ] && [ ! -e "$SUBD/.planning" ]; assert_exit "WS-ROOT-2.3 — ni verrou ni .planning parasite créés" "$?" 0
out="$(dl_in "$SUBD" sess-A status --ws=alpha)"; rc=$?
assert_exit "WS-ROOT-3.1 — status --ws depuis un sous-dossier : exit 1" "$rc" 1
assert "WS-ROOT-3.2 — clé de tête error, jamais present" "$out" '"error": "not-at-lab-root"'
assert_not "WS-ROOT-3.3 — status refusé ne porte pas present" "$out" '"present"'
out="$(dl_in "$SUBD" sess-A status)"
assert_not "WS-ROOT-4 — sans --ws ni --depot, rien ne change (pas de refus not-at-lab-root)" "$out" 'not-at-lab-root'
out="$(dl_in "$LAB/autre" sess-A status --ws=alpha)"
assert_not "WS-ROOT-5 — dossier portant son PROPRE .planning (P57-D-29, hors périmètre) : pas de refus not-at-lab-root" "$out" 'not-at-lab-root'
out="$(cd "$SUBD" && CLAUDE_CODE_SESSION_ID=sess-A VF_DRIVER_LOCK="$WORK_DIR/root-unique/DRIVER.lock" "${DL_SCRIPT:-$SCRIPT}" status --ws=alpha)"
assert_not "WS-ROOT-6 — VF_DRIVER_LOCK posé force le verrou unique (P57-D-22) : pas de refus not-at-lab-root" "$out" 'not-at-lab-root'
FLATR="$(mk_flat rootflat)"; mkdir -p "$FLATR/plugin/sub"
out="$(dl_in "$FLATR/plugin/sub" sess-A status --ws=alpha)"
assert_not "WS-ROOT-7 — lab PLAT : --ws depuis un sous-dossier reste sans effet (P57-D-03), pas de refus" "$out" 'not-at-lab-root'
out="$(dl "$LAB" sess-A acquire --ws=alpha --owner=m1 --step=s)"
assert "WS-ROOT-8 — témoin : depuis la racine du lab, le même acquire réussit" "$out" '"acquired": true'
# #58 : le même refus SANS option, en lab partitionné comme en lab plat (verrou fantôme <sous-dossier>/.planning/DRIVER.lock)
LAB9="$(mk_lab root9)"; GC9="$(fixture_common_dir "$LAB9")"; mkdir -p "$LAB9/plugin/sub"; SUB9="$LAB9/plugin/sub"
out="$(dl_in "$SUB9" sess-A acquire --owner=m1 --step=s)"; rc=$?
assert_exit "WS-ROOT-9.1 — lab partitionné : acquire SANS option depuis un sous-dossier : exit 1" "$rc" 1
assert "WS-ROOT-9.2 — reason not-at-lab-root" "$out" '"reason": "not-at-lab-root"'
assert "WS-ROOT-9.3 — clé de tête acquired false" "$out" '"acquired": false'
[ ! -e "$GC9/vf-driver" ] && [ ! -e "$SUB9/.planning" ] && [ ! -e "$LAB9/.planning/DRIVER.lock" ]; assert_exit "WS-ROOT-9.4 — ni verrou ni .planning fantôme créés" "$?" 0
FLAT10="$(mk_flat root10)"; mkdir -p "$FLAT10/plugin/sub"; SUB10="$FLAT10/plugin/sub"
out="$(dl_in "$SUB10" sess-A acquire --owner=m1 --step=s)"; rc=$?
assert_exit "WS-ROOT-10.1 — lab plat : acquire depuis un sous-dossier : exit 1" "$rc" 1
assert "WS-ROOT-10.2 — reason not-at-lab-root" "$out" '"reason": "not-at-lab-root"'
json_ok "$out"; assert_exit "WS-ROOT-10.3 — JSON valide" "$?" 0
[ ! -e "$SUB10/.planning" ] && [ ! -e "$FLAT10/.planning/DRIVER.lock" ]; assert_exit "WS-ROOT-10.4 — ni verrou ni .planning fantôme créés" "$?" 0
out="$(dl_in "$SUB10" sess-A heartbeat --owner=m1)"; rc=$?
assert_exit "WS-ROOT-11.1 — lab plat : heartbeat depuis un sous-dossier : exit 1" "$rc" 1
assert "WS-ROOT-11.2 — reason not-at-lab-root" "$out" '"reason": "not-at-lab-root"'
out="$(dl_in "$SUB10" sess-A status)"
assert_not "WS-ROOT-12 — lab plat : status (lecture seule) depuis un sous-dossier reste sans refus" "$out" 'not-at-lab-root'
assert "WS-ROOT-12b — positif : le status rendu est bien la lecture du verrou, pas une autre erreur" "$out" '"present": false'
out="$(cd "$SUB10" && CLAUDE_CODE_SESSION_ID=sess-A VF_DRIVER_LOCK="$WORK_DIR/root-unique10/DRIVER.lock" "${DL_SCRIPT:-$SCRIPT}" acquire --owner=m1 --step=s)"
assert "WS-ROOT-13 — VF_DRIVER_LOCK posé : comportement historique, acquire depuis un sous-dossier réussit" "$out" '"acquired": true'
# revue adverse de #58 : `--ws` et `--depot` en lab PLAT depuis un sous-dossier créaient encore <sous-dossier>/.planning
# (options inertes en lab plat, P57-D-03, mais l'écriture du verrou ne l'est pas)
out="$(dl_in "$SUB10" sess-A acquire --ws=alpha --owner=m1 --step=s)"; rc=$?
assert_exit "WS-ROOT-17.1 — lab plat : acquire --ws depuis un sous-dossier : exit 1" "$rc" 1
assert "WS-ROOT-17.2 — reason not-at-lab-root" "$out" '"reason": "not-at-lab-root"'
json_ok "$out"; assert_exit "WS-ROOT-17.3 — JSON valide" "$?" 0
[ ! -e "$SUB10/.planning" ] && [ ! -e "$FLAT10/.planning/DRIVER.lock" ]; assert_exit "WS-ROOT-17.4 — ni verrou ni .planning fantôme créés" "$?" 0
out="$(dl_in "$SUB10" sess-A acquire --depot --owner=m1 --step=s)"; rc=$?
assert_exit "WS-ROOT-18.1 — lab plat : acquire --depot depuis un sous-dossier : exit 1" "$rc" 1
assert "WS-ROOT-18.2 — reason not-at-lab-root" "$out" '"reason": "not-at-lab-root"'
[ ! -e "$SUB10/.planning" ] && [ ! -e "$FLAT10/.planning/DRIVER.lock" ]; assert_exit "WS-ROOT-18.3 — ni verrou ni .planning fantôme créés" "$?" 0
mkdir -p "$LAB9/autre/.planning"; out="$(dl_in "$LAB9/autre" sess-A acquire --owner=m1 --step=s)"
assert_not "WS-ROOT-14 — dossier portant son PROPRE .planning (P57-D-29) : acquire sans option, pas de refus" "$out" 'not-at-lab-root'
assert "WS-ROOT-14b — positif : l'acquire a réellement réussi" "$out" '"acquired": true'
mkdir -p "$WORK_DIR/root15-git/sub"; git -C "$WORK_DIR/root15-git" init -q >/dev/null 2>&1
out="$(dl_in "$WORK_DIR/root15-git/sub" sess-A acquire --owner=m1 --step=s)"
assert_not "WS-ROOT-15 — dépôt git dont la racine ne porte aucun .planning : pas de refus" "$out" 'not-at-lab-root'
assert "WS-ROOT-15b — positif : l'acquire a réellement réussi" "$out" '"acquired": true'
mkdir -p "$WORK_DIR/root16-nogit/sub"
out="$(cd "$WORK_DIR/root16-nogit/sub" && GIT_CEILING_DIRECTORIES="$WORK_DIR" CLAUDE_CODE_SESSION_ID=sess-A "${DL_SCRIPT:-$SCRIPT}" acquire --owner=m1 --step=s)"
assert_not "WS-ROOT-16 — hors dépôt git : inchangé, pas de refus" "$out" 'not-at-lab-root'
assert "WS-ROOT-16b — positif : l'acquire a réellement réussi" "$out" '"acquired": true'

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

# Intégrité de la copie gelée (T-57-40, correction R-7). Empreinte ÉPINGLÉE dans la suite : le blob git de
# `git rev-parse $AB_REF:$AB_PATH_IN_REF`, dérivé de l'objet de référence puis gelé ici. Elle se vérifie SANS
# historique : un clone superficiel (le job `tests` de la CI fait un `actions/checkout` sans `fetch-depth`) ne
# l'ignore plus. Quand l'objet est présent, la copie est en plus comparée au blob du dépôt et l'épingle à la
# référence : un gel dérivé de la référence, jamais d'un vert muet.
AB_BLOB=4f6b5c1be98110fe39c2daa0f5bb74ca70b1db5c
ab_pin_ok() { # <fichier> <blob attendu>
  [ "$(git hash-object --no-filters "$1" 2>/dev/null)" = "$2" ]
}
ab_pin_ok "$FROZEN" "$AB_BLOB"; assert_exit "WS-AB-INTEGRITE.0 — la copie gelée porte l'empreinte épinglée (blob $AB_BLOB), historique présent ou non" "$?" 0
cp "$FROZEN" "$WORK_DIR/ab-alteree.sh"; printf '#' >> "$WORK_DIR/ab-alteree.sh"
ab_pin_ok "$WORK_DIR/ab-alteree.sh" "$AB_BLOB"; assert_exit "WS-AB-INTEGRITE.0b — témoin négatif : la même copie altérée d'un octet est REJETÉE par la vérification" "$?" 1
if git -C "$HERE" cat-file -e "$AB_REF:$AB_PATH_IN_REF" 2>/dev/null; then
  git -C "$HERE" show "$AB_REF:$AB_PATH_IN_REF" > "$WORK_DIR/ab-ref.sh" 2>/dev/null
  cmp -s "$FROZEN" "$WORK_DIR/ab-ref.sh"; assert_exit "WS-AB-INTEGRITE.1 — la copie gelée est identique à git show $AB_REF:$AB_PATH_IN_REF" "$?" 0
  assert "WS-AB-INTEGRITE.3 — l'empreinte épinglée est celle de la référence (git rev-parse $AB_REF:$AB_PATH_IN_REF)" "$(git -C "$HERE" rev-parse "$AB_REF:$AB_PATH_IN_REF" 2>/dev/null)" "$AB_BLOB"
else
  echo "  NOTE-INTEGRITE (objet absent) — $AB_REF non disponible localement (clone superficiel) : comparaison à la référence non faite ici, l'empreinte épinglée est contrôlée par WS-AB-INTEGRITE.0"
fi
[ -x "$FROZEN" ]; assert_exit "WS-AB-INTEGRITE.2 — la copie gelée est exécutable" "$?" 0

if [ "$DLWS_MODE" = full ]; then
echo
echo "=== MUTANTS DL-M-a à DL-M-j, puis DL-M-acq_fallback à DL-M-tk_old_deleted — chaque comportement neuf de driver-lock.sh rougit sous sa mutation (QUAL-01, P57-D-12, P57-D-28) ==="
# Chaque mutant = une substitution `sed` sur UNE ligne-ancre (compte = 1) d'une COPIE du script, posée à côté
# d'une copie de workstream-policy.sh (sinon policy-missing rougirait pour la mauvaise raison). La matrice (les
# cas WS-* hors concurrence, WS-AB compris) est rejouée en sous-processus contre la copie ; l'ensemble des cas
# dont le verdict bascule est comparé EXACTEMENT à l'attendu (un cas basculé hors de l'ensemble fait échouer).
MUT_KILLED=0; MUT_TOTAL=29; t0=$SECONDS
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
  # SIGPIPE RESTAURÉ à son action par défaut : le runner GitHub Actions lance ses étapes avec SIGPIPE IGNORÉ (hérité), et
  # bash ne peut pas défaire une ignorance héritée. Le mutant i modélise précisément un pipeline à sortie anticipée
  # sous pipefail (piège P1) : sans SIGPIPE vivant, le rédacteur n'est jamais tué et le mutant ne bascule presque rien
  # (CI, 2026-10-14 : 1 famille sur 35). python3 est déjà requis ; os.execvp conserve l'action SIG_DFL.
  DLWS_MODE=matrice DLWS_SCRIPT="$1" python3 -c 'import os, signal, sys; signal.signal(signal.SIGPIPE, signal.SIG_DFL); os.execvp(sys.argv[1], sys.argv[1:])' bash "$SUITE" > "$2" 2>&1
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

# vide (P57-D-56, révise P57-D-25) : le dossier des compartiments VIDE redevient « partitionné » — seuls les cas WS-VIDE (hors témoin) basculent
mutant vide 'return 1  # D56-VIDE' 's@return 1  # D56-VIDE@return 0  # D56-VIDE@' "WS-VIDE-vide WS-VIDE-gitkeep"
mutant j 'vf_dl_refuse not-at-lab-root' 's@vf_dl_refuse not-at-lab-root .*$@:@' "$MUT_J"
mutant k 'status|orphans) mutating=0 ;; esac' 's@status|orphans) mutating=0 ;; esac@status|orphans) mutating=1 ;; esac@' "$MUT_K"
mutant acq_fallback 'if \[ "$ACTION" != acquire \] && \[ "$ALL" = 0 \]' 's@\[ "$ACTION" != acquire \] \&\& @@' "$MUT_ACQ"
mutant fallback_depotpresent '\[ ! -L "$LOCK_DIR" \] && \[ ! -d "$LOCK_DIR" \]' 's@ \&\& \[ ! -L "$LOCK_DIR" \] \&\& \[ ! -d "$LOCK_DIR" \]@@' "$MUT_FDP"
mutant skip_link_d 'if \[ -L "$d" \] || ! vf_ws_name_valid "$name"; then' 's@\[ -L "$d" \] || @@' "$MUT_SKL"
mutant reprobe_none '_leg_after="$(vf_dl_legacy_probe)"' 's@_leg_after="$(vf_dl_legacy_probe)"@_leg_after=""@' "$MUT_REP"
mutant pose_kept '= "$gen" \] && rm -f "$LOCK_DIR"' 's@\&\& rm -f "$LOCK_DIR"@\&\& :@' "$MUT_REP"
mutant gen_kept '{gen:?}' 's@rm -rf "${LOCK_PARENT:?}/${gen:?}"@:@' "$MUT_REP"
# takeover --ws (Q5, arbitrage Samuel, AskUserQuestion session principale, 2026-10-13) : sonde de tête, re-sonde, retrait de la pose.
mutant tk_nosonde '\[ -n "$_leg" \] && vf_dl_legacy_refuse "$_leg"' 's@\[ -n "$_leg" \] \&\& vf_dl_legacy_refuse "$_leg"@[ -n "$_leg" ] \&\& :@' "$MUT_TKH"
mutant tk_stale_resume '\[ -n "$_leg" \] && vf_dl_legacy_refuse "$_leg"' 's@\[ -n "$_leg" \] && vf_dl_legacy_refuse "$_leg"@case "$_leg" in vivant*) vf_dl_legacy_refuse "$_leg" ;; esac@' "$MUT_TKS"
mutant tk_reprobe_none '_tk_after="$(vf_dl_legacy_probe)"' 's@_tk_after="$(vf_dl_legacy_probe)"@_tk_after=""@' "$MUT_TKRP"
mutant tk_restore_none 'ln_atomic "$old_gen"' 's@ln_atomic "$old_gen" "${LOCK_DIR}.new.$$" \&\& mv_link "${LOCK_DIR}.new.$$" "$LOCK_DIR"@:@' "$MUT_TKR"
mutant tk_gen_kept 'retire sa pose$' 's@rm -rf "${LOCK_PARENT:?}/$gen"@:@' "$MUT_TKGK"
mutant tk_mutex_kept '# mutex-refus$' 's@rm -f "\$mutex"; trap - EXIT INT TERM # mutex-refus@trap - EXIT INT TERM@' "$MUT_TKM"
mutant tk_restore_dir_none 'rm -f "$LOCK_DIR"; mv_noclobber' 's@; mv_noclobber "${LOCK_DIR}.old.$$" "$LOCK_DIR"$@@' "$MUT_TKD2"
mutant tk_final_restore_none '&& \[ ! -L "$LOCK_DIR" \] && mv_noclobber' 's@&& mv_noclobber "${LOCK_DIR}.old.$$" "$LOCK_DIR"@\&\& :@' "$MUT_TKF"
mutant tk_verify_none 'if \[ "$(lock_gen)" = "$old_gen" \] && \[ ! -e' 's@if \[ "$(lock_gen)" = "$old_gen" \] && \[ ! -e "${LOCK_DIR}.old.$$" \]; then@if true; then@' "$MUT_TKV"
mutant tk_noclobber_none 'mv -nh "$1" "$2"' 's@mv -nh "$1" "$2" 2>/dev/null || mv -nT "$1" "$2" 2>/dev/null@mv "$1" "$2"@' "$MUT_TKV"
mutant tk_old_deleted '_tk_after="$(vf_dl_legacy_probe)"' 's@_tk_after="$(vf_dl_legacy_probe)"@case "$old_gen" in */*|"") ;; *) rm -rf "${LOCK_PARENT:?}/$old_gen" ;; esac; _tk_after="$(vf_dl_legacy_probe)"@' "$MUT_TKO"

wait
for id in $MUT_IDS; do mutant_eval "$id"; done
echo "  durée des mutants : $((SECONDS-t0))s"
if [ "$MUT_KILLED" -eq "$MUT_TOTAL" ]; then
  echo "== mutants : 29/29 tués =="
else
  echo "== mutants : $MUT_KILLED/29 tués =="
  FAIL=$((FAIL+1))
fi
fi   # DLWS_MODE = full (mutants)

echo
echo "=== Bilan : $PASS PASS · $FAIL FAIL ==="
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$PASS" -gt 0 ] || { echo "❌ FAIL — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ]
