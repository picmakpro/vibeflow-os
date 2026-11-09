#!/usr/bin/env bash
# Test de worktree-procs.sh (issue #223) — autonome, borné, sans orphelin.
# Chaque leurre (`sleep 300`) a son PID consigné dans $TMP/pids et tué par le trap EXIT.
# Chaque garde est prouvée par un mutant : copie du script SANS la garde, le cas correspondant doit
# rougir (trace : cas, attendu, obtenu). Un mutant ne joue `stop` QUE dans une cible temporaire sous $TMP
# (leurres seuls) ; les cas de refus et de sélection large ne lancent que `list` sur les mutants. `stop` sur
# des chemins dangereux n'est joué que sur le vrai script, avec --max=1 (filet : rc 3, rien tué).
# Un rc 2 (survivant après SIGKILL) n'est pas simulable sans processus infaillible : il l'est via
# VF_WTP_SANS_SIGNAL=1 (aucun signal envoyé), seule direction sûre d'un tel réglage.
# WTP_SCRIPT=<chemin> juge un autre script ; WTP_SEUL="cas1 cas2" ne joue que ces cas (sans mutants).
set -uo pipefail

REAL="${WTP_SCRIPT:-$(cd "$(dirname "$0")/.." && pwd)/worktree-procs.sh}"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

TMP="$(cd -P "$(mktemp -d)" && pwd -P)"
: > "$TMP/pids"

tuer_tout() {
  local p c
  while read -r p; do
    [ -n "$p" ] || continue
    c="$(ps -o command= -p "$p" 2>/dev/null)"
    case "$c" in *"sleep 300"*|*wtp-mobile*) kill -KILL "$p" 2>/dev/null || : ;; esac
    { wait "$p"; } 2>/dev/null || :
  done < "$TMP/pids"
  : > "$TMP/pids"
}
trap 'tuer_tout; rm -rf "$TMP"' EXIT

DETAIL=""
assert_eq() { # label attendu obtenu
  [ "$2" = "$3" ] && return 0
  DETAIL="cas [$1] attendu [$2] obtenu [$3]"
  [ -n "${ERR:-}" ] && DETAIL="$DETAIL | stderr du script : $(printf '%s' "$ERR" | tr '\n' ' ' | cut -c1-400)"
  return 1
}
cwd_de() { if [ -r /proc/self/cwd ]; then readlink "/proc/$1/cwd" 2>/dev/null; else lsof -a -d cwd -p "$1" -Fn 2>/dev/null | sed -n 's/^n//p'; fi; }
leurre() { # leurre <dir> [ignterm|mobile] -> LP ; attend (<= 5 s) que le cwd du leurre soit visible
  case "${2:-}" in
    ignterm) (cd "$1" && trap '' TERM && exec sleep 300) & ;;
    mobile) (cd "$1" && exec bash -c ': wtp-mobile; trap "cd /" TERM; while :; do sleep 1; done') & ;;
    *) (cd "$1" && exec sleep 300) & ;;
  esac
  LP=$!; echo "$LP" >> "$TMP/pids"
  local i=0
  while [ "$i" -lt 50 ] && [ "$(cwd_de "$LP")" != "$1" ]; do sleep 0.1; i=$((i+1)); done
}
vivant() { local s; s="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"; [ -n "$s" ] && [ "${s#Z}" = "$s" ]; }
etat() { if vivant "$1"; then echo vivant; else echo mort; fi; }
run() { # run <script> args... -> RC OUT ERR
  local sc="$1"; shift
  OUT="$(bash "$sc" "$@" 2>"$TMP/err")"; RC=$?; ERR="$(cat "$TMP/err")"
}
cible() { mkdir -p "$TMP/$1/cible" "$TMP/$1/cible/sous" "$TMP/$1/cible-b" "$TMP/$1/hors"; CIB="$TMP/$1/cible"; }

# --- cas : chacun prend le script à juger, rend 0 (ok) ou 1 (DETAIL posé)
cas_liste_arret() {
  cible liste; leurre "$CIB"; local a=$LP; leurre "$CIB/sous"; local b=$LP
  run "$1" list --path="$CIB"
  assert_eq "list rc" 1 "$RC" || return 1
  assert_eq "list nb lignes" 2 "$(printf '%s\n' "$OUT" | grep -c .)" || return 1
  assert_eq "list format pid<TAB>cwd<TAB>cmd" 1 "$(printf '%s\n' "$OUT" | grep -c "^$a$(printf '\t')$CIB$(printf '\t')sleep 300")" || return 1
  run "$1" stop --path="$CIB"
  assert_eq "stop rc" 0 "$RC" || return 1
  assert_eq "leurre cible" mort "$(etat $a)" || return 1
  assert_eq "leurre sous-dossier" mort "$(etat $b)" || return 1
  tuer_tout
}
cas_frere() {
  cible frere; leurre "$CIB"; local a=$LP; leurre "$CIB-b"; local f=$LP
  run "$1" list --path="$CIB"
  assert_eq "list ne cite pas le frère" 0 "$(printf '%s\n' "$OUT" | grep -c "^$f$(printf '\t')")" || return 1
  run "$1" stop --path="$CIB"
  assert_eq "stop rc" 0 "$RC" || return 1
  assert_eq "leurre cible" mort "$(etat $a)" || return 1
  assert_eq "frère préfixe cible-b" vivant "$(etat $f)" || return 1
  tuer_tout
}
cas_hors() { # list seulement : jouable sur un mutant à sélection large
  cible hors; leurre "$TMP/hors/hors"; local h=$LP
  run "$1" list --path="$CIB"
  assert_eq "list rc (rien dans la cible)" 0 "$RC" || return 1
  assert_eq "leurre hors cible" vivant "$(etat $h)" || return 1
  tuer_tout
}
cas_hors_stop() { # vrai script seulement
  cible horss; leurre "$TMP/horss/hors"; local h=$LP; leurre "$CIB"; local a=$LP
  run "$1" stop --path="$CIB"
  assert_eq "stop rc" 0 "$RC" || return 1
  assert_eq "leurre cible" mort "$(etat $a)" || return 1
  assert_eq "leurre hors cible" vivant "$(etat $h)" || return 1
  tuer_tout
}
cas_appelant() {
  cible appelant; leurre "$CIB"; local a=$LP
  local got
  got="$(bash -c 'cd "$1" && bash "$2" stop --path="$1" >/dev/null 2>&1; echo "rc=$?"; echo VIVANT' _ "$CIB" "$1" 2>/dev/null | tr '\n' ' ')"
  assert_eq "shell appelant (cwd dans la cible) survit" "rc=0 VIVANT " "$got" || return 1
  assert_eq "leurre cible" mort "$(etat $a)" || return 1
  tuer_tout
}
cas_plafond() {
  cible plafond; local i pids=""
  for i in 1 2 3 4; do leurre "$CIB"; pids="$pids $LP"; done
  run "$1" stop --path="$CIB" --max=3
  assert_eq "stop 4 > --max=3 rc" 3 "$RC" || return 1
  local p v=""; for p in $pids; do v="$v$(etat $p) "; done
  assert_eq "tous survivent" "vivant vivant vivant vivant " "$v" || return 1
  run "$1" stop --path="$CIB" --max=4
  assert_eq "stop 4 <= --max=4 rc" 0 "$RC" || return 1
  tuer_tout
}
cas_sigkill() {
  cible sigkill; leurre "$CIB" ignterm; local a=$LP
  run "$1" stop --path="$CIB"
  assert_eq "stop d'un leurre qui ignore SIGTERM rc" 0 "$RC" || return 1
  assert_eq "leurre" mort "$(etat $a)" || return 1
  tuer_tout
}
cas_indet_aucune() {
  cible indetA; leurre "$CIB"; local a=$LP
  OUT="$(VF_WTP_METHODE=aucune bash "$1" list --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "list sans méthode rc" 4 "$RC" || return 1
  OUT="$(VF_WTP_METHODE=aucune bash "$1" stop --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "stop sans méthode rc" 4 "$RC" || return 1
  assert_eq "leurre épargné" vivant "$(etat $a)" || return 1
  tuer_tout
}
cas_indet_vide() {
  cible indetV; mkdir -p "$TMP/fakebin"; printf '#!/bin/sh\nexit 0\n' > "$TMP/fakebin/lsof"; chmod +x "$TMP/fakebin/lsof"
  leurre "$CIB"; local a=$LP
  OUT="$(PATH="$TMP/fakebin:$PATH" VF_WTP_METHODE=lsof bash "$1" list --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "list, lsof muet (sortie vide) rc" 4 "$RC" || return 1
  OUT="$(PATH="$TMP/fakebin:$PATH" VF_WTP_METHODE=lsof bash "$1" stop --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "stop, lsof muet rc" 4 "$RC" || return 1
  assert_eq "leurre épargné" vivant "$(etat $a)" || return 1
  tuer_tout
}
refus_list() { # refus_list <label> <script> <chemin> [HOME]
  local h="${4:-$HOME}"
  OUT="$(HOME="$h" bash "$2" list --path="$3" 2>/dev/null)"; RC=$?
  assert_eq "$1 rc" 64 "$RC" || return 1
  assert_eq "$1 stdout vide" "" "$OUT" || return 1
}
cas_refus_absolu() { cible rabs; ( cd "$TMP/rabs" && OUT="$(bash "$1" list --path=cible 2>/dev/null)"; echo "$?" > "$TMP/rc" ); assert_eq "chemin relatif rc" 64 "$(cat "$TMP/rc")"; }
cas_refus_dotdot() { cible rdd; refus_list "chemin avec .." "$1" "$TMP/rdd/cible/../cible"; }
cas_refus_inexistant() {
  cible rin; refus_list "chemin inexistant" "$1" "$TMP/rin/nope" || return 1
  : > "$TMP/rin/fichier"; refus_list "chemin = fichier" "$1" "$TMP/rin/fichier"
}
cas_refus_composants() { refus_list "racine /" "$1" / || return 1; refus_list "1 composant /usr" "$1" /usr; }
cas_refus_home() {
  mkdir -p "$TMP/h1/u/v" "$TMP/h1/u/w"
  refus_list "chemin = HOME" "$1" "$TMP/h1/u/v" "$TMP/h1/u/v" || return 1
  OUT="$(HOME="$TMP/h1/u/v" bash "$1" list --path="$TMP/h1/u/w" 2>/dev/null)"; RC=$?
  assert_eq "témoin : voisin de HOME accepté rc" 0 "$RC"
}
cas_refus_ancetre() {
  mkdir -p "$TMP/h2/u/v" "$TMP/h2/u/w"
  refus_list "ancêtre de HOME" "$1" "$TMP/h2/u" "$TMP/h2/u/v" || return 1
  OUT="$(HOME="$TMP/h2/u/v" bash "$1" list --path="$TMP/h2/u/w" 2>/dev/null)"; RC=$?
  assert_eq "témoin : voisin de HOME accepté rc" 0 "$RC"
}
cas_stop_refus_reel() { # vrai script seulement ; --max=1 = filet
  local d
  for d in / /usr "$HOME"; do
    run "$1" stop --path="$d" --max=1
    assert_eq "stop $d refusé rc" 64 "$RC" || return 1
  done
}
cas_usage() {
  run "$1" ; assert_eq "sans verbe rc" 64 "$RC" || return 1
  run "$1" list ; assert_eq "sans --path rc" 64 "$RC" || return 1
  cible usage; run "$1" list --path="$CIB" --max=abc ; assert_eq "--max non entier rc" 64 "$RC" || return 1
  run "$1" list --path="$CIB" --bidon ; assert_eq "option inconnue rc" 64 "$RC"
}

# --- correction ciblée de revue (M1-M3, m1-m3, m5)
UTF8=0; LOCALES="$(locale -a 2>/dev/null)"; printf '%s\n' "$LOCALES" | grep -i 'utf-\{0,1\}8' >/dev/null && UTF8=1
run_borne() { # run_borne <secondes> <script> args... -> RC (124 si dépassé), OUT
  local n=$(( $1 * 10 )) sc="$2" i=0; shift 2
  bash "$sc" "$@" >"$TMP/borne.out" 2>/dev/null & local bp=$!
  while kill -0 "$bp" 2>/dev/null && [ "$i" -lt "$n" ]; do sleep 0.1; i=$((i+1)); done
  if kill -0 "$bp" 2>/dev/null; then kill -KILL "$bp" 2>/dev/null; { wait "$bp"; } 2>/dev/null; RC=124
  else { wait "$bp"; } 2>/dev/null; RC=$?; fi
  OUT="$(cat "$TMP/borne.out")"
}
cas_m1_accent() { # chemin accentué trouvé même sous LC_ALL=C si une locale UTF-8 existe, sinon rc 4 (méthode lsof forcée)
  command -v lsof >/dev/null 2>&1 || { SKIP=1; return 0; }
  mkdir -p "$TMP/m1/cíble-é-🙂"; leurre "$TMP/m1/cíble-é-🙂"; local a=$LP
  OUT="$(env -i PATH="$PATH" HOME="$HOME" LC_ALL=C VF_WTP_METHODE=lsof bash "$1" list --path="$TMP/m1/cíble-é-🙂" 2>/dev/null)"; RC=$?
  if [ "$UTF8" -eq 1 ]; then assert_eq "list accentué sous LC_ALL=C (UTF-8 dispo)" 1 "$RC" || return 1
    OUT="$(env -i PATH="$PATH" HOME="$HOME" LC_ALL=C VF_WTP_METHODE=lsof bash "$1" stop --path="$TMP/m1/cíble-é-🙂" 2>/dev/null)"; RC=$?
    assert_eq "stop accentué rc" 0 "$RC" || return 1
    assert_eq "leurre accentué" mort "$(etat $a)" || return 1
  else assert_eq "list accentué sans locale UTF-8" 4 "$RC" || return 1; fi
  tuer_tout
}
cas_m1_sans_locale() { # non-ASCII et aucune locale UTF-8 : rc 4, jamais un vide
  mkdir -p "$TMP/m1b/cíble"; leurre "$TMP/m1b/cíble"; local a=$LP
  OUT="$(VF_WTP_LOCALE=aucune bash "$1" list --path="$TMP/m1b/cíble" 2>/dev/null)"; RC=$?
  assert_eq "list non-ASCII sans locale rc" 4 "$RC" || return 1
  OUT="$(VF_WTP_LOCALE=aucune bash "$1" stop --path="$TMP/m1b/cíble" 2>/dev/null)"; RC=$?
  assert_eq "stop non-ASCII sans locale rc" 4 "$RC" || return 1
  assert_eq "leurre épargné" vivant "$(etat $a)" || return 1
  tuer_tout
}
cas_m1_caracteres() { # backslash, tabulation : non représentable sans ambiguïté -> rc 4, rien tué
  local d n=0
  for d in 'bs\\x' "tab$(printf '\t')x"; do
    n=$((n+1)); mkdir -p "$TMP/m1c$n/$d"; leurre "$TMP/m1c$n/$d"; local a=$LP
    run "$1" list --path="$TMP/m1c$n/$d"; assert_eq "list chemin #$n rc" 4 "$RC" || return 1
    run "$1" stop --path="$TMP/m1c$n/$d"; assert_eq "stop chemin #$n rc" 4 "$RC" || return 1
    assert_eq "leurre #$n épargné" vivant "$(etat $a)" || return 1
  done
  tuer_tout
}
cas_m2_partiel() { # faux lsof : un seul PID étranger, rc 1 -> lecture partielle = rc 4
  cible m2; mkdir -p "$TMP/fakep"; printf '#!/bin/sh\necho p1234; echo fcwd; echo n/ailleurs; exit 1\n' > "$TMP/fakep/lsof"; chmod +x "$TMP/fakep/lsof"
  leurre "$CIB"; local a=$LP
  OUT="$(PATH="$TMP/fakep:$PATH" VF_WTP_METHODE=lsof bash "$1" list --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "list lecture partielle rc" 4 "$RC" || return 1
  OUT="$(PATH="$TMP/fakep:$PATH" VF_WTP_METHODE=lsof bash "$1" stop --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "stop lecture partielle rc" 4 "$RC" || return 1
  assert_eq "leurre épargné" vivant "$(etat $a)" || return 1
  tuer_tout
}
cas_m3_ps() { # ps en échec : la chaîne d'ancêtres ne remonte pas -> rc 4 AVANT tout signal, appelant vivant
  cible m3; mkdir -p "$TMP/fakeps"; printf '#!/bin/sh\ncase "$*" in *ppid=*) exit 1 ;; *) exec %s "$@" ;; esac\n' "$(command -v ps)" > "$TMP/fakeps/ps"; chmod +x "$TMP/fakeps/ps"
  leurre "$CIB"; local a=$LP got
  got="$(PATH="$TMP/fakeps:$PATH" VF_WTP_PPID=ps bash -c 'cd "$1" && bash "$2" stop --path="$1" >/dev/null 2>&1; echo "rc=$?"; echo VIVANT' _ "$CIB" "$1" 2>/dev/null | tr '\n' ' ')"
  assert_eq "ps en échec : rc 4 et shell appelant vivant" "rc=4 VIVANT " "$got" || return 1
  assert_eq "leurre épargné" vivant "$(etat $a)" || return 1
  tuer_tout
}
cas_m1_casse() { # Darwin, volume insensible à la casse : autre casse = rc 4, jamais un 0 faux
  [ "$(uname -s)" = Darwin ] || { SKIP=1; return 0; }
  mkdir -p "$TMP/m1k/Cible"; [ -d "$TMP/m1k/cIBLE" ] || { SKIP=1; return 0; }
  leurre "$TMP/m1k/Cible"; local a=$LP
  run "$1" list --path="$TMP/m1k/cIBLE"
  assert_eq "list autre casse rc" 4 "$RC" || return 1
  run "$1" stop --path="$TMP/m1k/cIBLE"
  assert_eq "stop autre casse rc" 4 "$RC" || return 1
  assert_eq "leurre épargné" vivant "$(etat $a)" || return 1
  tuer_tout
}
cas_m2_git() { # chemin englobant un dépôt ou des worktrees : 64 ; .git fichier (worktree) accepté
  mkdir -p "$TMP/m2g/dep/.git" "$TMP/m2g/wts/.claude/worktrees" "$TMP/m2g/wt"; : > "$TMP/m2g/wt/.git"
  refus_list "chemin avec .git répertoire" "$1" "$TMP/m2g/dep" || return 1
  refus_list "chemin avec .claude/worktrees" "$1" "$TMP/m2g/wts" || return 1
  run "$1" list --path="$TMP/m2g/wt"
  assert_eq "témoin : .git fichier accepté rc" 0 "$RC"
}
cas_famille() { # chemin englobant : .claude, .claude/worktrees, parent d'un dépôt = 64 ; worktree seul accepté
  mkdir -p "$TMP/fam/repo/.git" "$TMP/fam/repo/.claude/worktrees/wt" "$TMP/fam/wt0" "$TMP/fam2/x/.claude/worktrees/vide"
  : > "$TMP/fam/repo/.claude/worktrees/wt/.git"; : > "$TMP/fam/wt0/.git"
  refus_list "parent d'un dépôt (.git à 1 niveau : fam/repo/.git)" "$1" "$TMP/fam" || return 1
  refus_list "dossier .claude seul (par le nom)" "$1" "$TMP/fam2/x/.claude" || return 1
  refus_list "dossier .claude/worktrees seul (par le nom)" "$1" "$TMP/fam2/x/.claude/worktrees" || return 1
  refus_list "repo/.claude (.git à 1 niveau sous worktrees/wt)" "$1" "$TMP/fam/repo/.claude" || return 1
  mkdir -p "$TMP/ws/x/repo/.git"   # refusé UNIQUEMENT par le glob à 2 niveaux (ws/x/repo/.git), hors .claude
  refus_list "parent de x/repo/.git (.git à 2 niveaux)" "$1" "$TMP/ws" || return 1
  run "$1" list --path="$TMP/fam/wt0"
  assert_eq "témoin : worktree (.git fichier racine) accepté rc" 0 "$RC"
}
cas_vivant_sans_ps() { # ps sait donner le parent mais pas l'état : rc 4 avant SIGTERM, leurre épargné (chemin ps seulement)
  [ -r /proc/self/stat ] && { SKIP=1; return 0; }
  cible vps; mkdir -p "$TMP/fakevps"; REALPS="$(command -v ps)"
  printf '#!/bin/sh\ncase "$*" in *stat=*) exit 1 ;; *) exec %s "$@" ;; esac\n' "$REALPS" > "$TMP/fakevps/ps"; chmod +x "$TMP/fakevps/ps"
  leurre "$CIB" ignterm; local a=$LP
  OUT="$(PATH="$TMP/fakevps:$PATH" bash "$1" stop --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "stop, état illisible rc" 4 "$RC" || return 1
  assert_eq "leurre épargné (aucun signal)" vivant "$(etat $a)" || return 1
  tuer_tout
}
fake_readlink() { # échoue pour /proc/$WTP_FAIL_PID/cwd, délègue sinon
  mkdir -p "$TMP/fakerl"
  printf '#!/bin/sh\n[ "$1" = "/proc/$WTP_FAIL_PID/cwd" ] && exit 1\nexec %s "$@"\n' "$(command -v readlink)" > "$TMP/fakerl/readlink"; chmod +x "$TMP/fakerl/readlink"
}
cas_proc_priv() { # Linux : même uid, cwd refusé, cause PROUVÉE (capacités supérieures) -> ignoré avec une note, le reste est lu
  [ -r /proc/self/cwd ] || { SKIP=1; return 0; }
  cible pp; fake_readlink; leurre "$CIB"; local a=$LP; leurre "$TMP/pp/hors"; local x=$LP
  mkdir -p "$TMP/stfx/$x"; printf 'CapPrm:\tffffffffffffffff\n' > "$TMP/stfx/$x/status"
  OUT="$(PATH="$TMP/fakerl:$PATH" WTP_FAIL_PID=$x VF_WTP_STATUS_DIR="$TMP/stfx" bash "$1" list --path="$CIB" 2>"$TMP/err")"; RC=$?; ERR="$(cat "$TMP/err")"
  assert_eq "list avec un processus plus privilégié illisible rc" 1 "$RC" || return 1
  assert_eq "seul le leurre de la cible est listé" 1 "$(printf '%s\n' "$OUT" | grep -c .)" || return 1
  assert_eq "une seule note (les exclus réels du runner s'y ajoutent)" 1 "$(printf '%s\n' "$ERR" | grep -c 'worktree-procs: note —')" || return 1
  assert_eq "le leurre est nommé pid:cmdline(capacités)" 1 "$(printf '%s\n' "$ERR" | grep -c "$x:sleep[^ ]*(capacités)")" || return 1
  VF_WTP_STATUS_DIR="$TMP/stfx" PATH="$TMP/fakerl:$PATH" WTP_FAIL_PID=$x run "$1" stop --path="$CIB"
  assert_eq "stop : une seule note" 1 "$(printf '%s\n' "$ERR" | grep -c 'worktree-procs: note —')" || return 1
  tuer_tout
}
cas_proc_nondump() { # Linux : même uid, /proc/<pid> à nous mais entrées (environ) à root = non dumpable -> ignoré et nommé ; avec CAP_SYS_PTRACE -> rc 4
  [ -r /proc/self/cwd ] || { SKIP=1; return 0; }
  [ -e /etc/hosts ] && [ ! -O /etc/hosts ] || { SKIP=1; return 0; }   # fixture : un fichier qui n'est pas à nous
  cible nd; fake_readlink; leurre "$CIB"; leurre "$TMP/nd/hors"; local x=$LP
  mkdir -p "$TMP/stfx3/$x" "$TMP/stfx3/self"; ln -sf /etc/hosts "$TMP/stfx3/$x/environ"
  printf 'CapPrm:\t0000000000000000\n' > "$TMP/stfx3/self/status"
  OUT="$(PATH="$TMP/fakerl:$PATH" WTP_FAIL_PID=$x VF_WTP_STATUS_DIR="$TMP/stfx3" bash "$1" list --path="$CIB" 2>"$TMP/err")"; RC=$?; ERR="$(cat "$TMP/err")"
  assert_eq "non dumpable ignoré : list rc" 1 "$RC" || return 1
  assert_eq "non dumpable nommé pid:cmdline" 1 "$(printf '%s\n' "$ERR" | grep -c "$x:sleep[^ ]*(non-dumpable)")" || return 1
  printf 'CapPrm:\t0000000000080000\n' > "$TMP/stfx3/self/status"
  OUT="$(PATH="$TMP/fakerl:$PATH" WTP_FAIL_PID=$x VF_WTP_STATUS_DIR="$TMP/stfx3" bash "$1" list --path="$CIB" 2>"$TMP/err")"; RC=$?; ERR="$(cat "$TMP/err")"
  assert_eq "non dumpable avec CAP_SYS_PTRACE : rc" 4 "$RC" || return 1
  tuer_tout
}
fixture_illisibles() { # fixture_illisibles <dir> : tout pid réel du runner au cwd illisible (même uid) est déclaré « plus privilégié »
  local d p
  for d in /proc/[0-9]*; do
    p="${d#/proc/}"
    readlink "$d/cwd" >/dev/null 2>&1 && continue
    [ -e "$d" ] && [ -O "$d" ] || continue
    mkdir -p "$1/$p"; printf 'CapPrm:\tffffffffffffffff\n' > "$1/$p/status"
  done
}
cas_proc_ptrace() { # Linux : si NOUS avons CAP_SYS_PTRACE (bit 19), la preuve « plus privilégié » est inapplicable -> rc 4
  [ -r /proc/self/cwd ] || { SKIP=1; return 0; }
  cible pt; fake_readlink; leurre "$CIB"; leurre "$TMP/pt/hors"; local x=$LP
  mkdir -p "$TMP/stfx2/$x" "$TMP/stfx2/self"
  fixture_illisibles "$TMP/stfx2"   # isole la garde mesurée des processus réels (ex. systemd --user, (sd-pam)) du runner
  printf 'CapPrm:\tffffffffffffffff\n' > "$TMP/stfx2/$x/status"; printf 'CapPrm:\t0000000000080000\n' > "$TMP/stfx2/self/status"
  OUT="$(PATH="$TMP/fakerl:$PATH" WTP_FAIL_PID=$x VF_WTP_STATUS_DIR="$TMP/stfx2" bash "$1" list --path="$CIB" 2>"$TMP/err")"; RC=$?; ERR="$(cat "$TMP/err")"
  assert_eq "avec CAP_SYS_PTRACE, cwd refusé = indéterminé rc" 4 "$RC" || return 1
  assert_eq "garde nommée" 1 "$(printf '%s\n' "$ERR" | grep -c 'indéterminé — proc-illisible')" || return 1
  tuer_tout
}
cas_proc_inexplique() { # Linux : même uid, cwd refusé SANS cause prouvée -> rc 4 nommant la garde
  [ -r /proc/self/cwd ] || { SKIP=1; return 0; }
  cible pi; fake_readlink; leurre "$CIB"; leurre "$TMP/pi/hors"; local x=$LP
  OUT="$(PATH="$TMP/fakerl:$PATH" WTP_FAIL_PID=$x bash "$1" list --path="$CIB" 2>"$TMP/err")"; RC=$?; ERR="$(cat "$TMP/err")"
  assert_eq "cwd illisible sans cause prouvée rc" 4 "$RC" || return 1
  assert_eq "garde nommée sur stderr" 1 "$(printf '%s\n' "$ERR" | grep -c 'indéterminé — proc-illisible')" || return 1
  tuer_tout
}
cas_proc_ancetre() { # Linux : le cwd illisible d'un ANCÊTRE (jamais signalé) n'est pas une raison d'indéterminer
  [ -r /proc/self/cwd ] || { SKIP=1; return 0; }
  cible pa; fake_readlink
  local got
  got="$(PATH="$TMP/fakerl:$PATH" bash -c 'WTP_FAIL_PID=$$ bash "$1" list --path="$2" >/dev/null 2>&1; echo "rc=$?"' _ "$1" "$CIB" 2>/dev/null)"
  assert_eq "ancêtre illisible, cible vide rc" "rc=0" "$got"
}
cas_m3_lsof_bloque() { # lsof figé : échéance, rc 4, faux lsof tué
  cible m3b; mkdir -p "$TMP/fakeb"; rm -f "$TMP/fakeb.pid"
  printf '#!/bin/sh\necho $$ > "%s"\nexec sleep 300\n' "$TMP/fakeb.pid" > "$TMP/fakeb/lsof"; chmod +x "$TMP/fakeb/lsof"
  local t0=$SECONDS
  PATH="$TMP/fakeb:$PATH" VF_WTP_METHODE=lsof VF_WTP_ECHEANCE=2 run_borne 15 "$1" list --path="$CIB"
  [ -s "$TMP/fakeb.pid" ] && cat "$TMP/fakeb.pid" >> "$TMP/pids"
  assert_eq "lsof figé : rc (124 = jamais rendu)" 4 "$RC" || return 1
  [ $((SECONDS - t0)) -le 8 ] || { DETAIL="cas [échéance] attendu [<= 8 s] obtenu [$((SECONDS - t0)) s]"; return 1; }
  assert_eq "faux lsof tué à l'échéance" mort "$(etat "$(cat "$TMP/fakeb.pid" 2>/dev/null || echo 0)")" || return 1
  tuer_tout
}
cas_comm() { # survivant déplacé (plus dans la cible après SIGTERM) : jamais de SIGKILL (anti-PID réutilisé)
  cible comm; leurre "$CIB" mobile; local m=$LP
  run "$1" stop --path="$CIB"
  assert_eq "stop rc" 0 "$RC" || return 1
  assert_eq "processus sorti de la cible épargné" vivant "$(etat $m)" || return 1
  tuer_tout
}
cas_survivants() { # rc 2 : signaux neutralisés, le leurre reste -> survivants listés
  cible surv; leurre "$CIB"; local a=$LP
  VF_WTP_SANS_SIGNAL=1 run "$1" stop --path="$CIB"
  assert_eq "stop sans effet rc" 2 "$RC" || return 1
  assert_eq "survivants listés" 1 "$(printf '%s\n' "$ERR" | grep -c "^$a$(printf '\t')")" || return 1
  assert_eq "leurre" vivant "$(etat $a)" || return 1
  tuer_tout
}

SKIP=0
CASES="liste_arret frere hors hors_stop appelant plafond sigkill indet_aucune indet_vide refus_absolu refus_dotdot refus_inexistant refus_composants refus_home refus_ancetre stop_refus_reel usage m1_accent m1_sans_locale m1_caracteres m2_partiel m3_ps m1_casse m2_git famille vivant_sans_ps proc_priv proc_nondump proc_ptrace proc_inexplique proc_ancetre m3_lsof_bloque comm survivants"
[ -n "${WTP_SEUL:-}" ] && CASES="$WTP_SEUL"
echo "== test-worktree-procs =="
for c in $CASES; do
  DETAIL=""; SKIP=0; ERR=""
  if cas_$c "$REAL"; then if [ "$SKIP" -eq 1 ]; then ok "cas $c (non applicable ici, ignoré)"; else ok "cas $c"; fi
  else ko "cas $c — $DETAIL"; tuer_tout; fi
done
if [ -n "${WTP_SEUL:-}" ]; then echo "== $PASS ok, $FAIL ko (WTP_SEUL : mutants non joués) =="; [ "$FAIL" -eq 0 ]; exit; fi

# --- mutants : la copie sans la garde DOIT rougir sur le cas désigné
mutant() { # mutant <nom> <cas> <sed args...>
  local nom="$1" cas="$2"; shift 2
  local m="$TMP/mut-$nom.sh"
  sed "$@" "$REAL" > "$m"
  if cmp -s "$REAL" "$m"; then ko "mutant $nom identique au script (sed sans effet)"; return; fi
  DETAIL=""; SKIP=0; ERR=""
  if "cas_$cas" "$m"; then
    if [ "$SKIP" -eq 1 ]; then ok "mutant $nom non jouable ici (cas non applicable)"; tuer_tout; return; fi
    ko "mutant $nom SURVIT : le cas $cas reste vert sans la garde"; tuer_tout
  else ok "mutant $nom tué — rouge : $DETAIL"; tuer_tout; fi
}
mutant frontiere      frere            -e 's/index(c,p"\/")==1/index(c,p)==1/'
mutant selection-tout hors             -e 's/(c==p||index(c,p"\/")==1)/1/'
mutant ancetres       appelant         -e 's/p=\$\$; i=0; reached=0/p=1; i=0; reached=0/'
mutant chaine         m3_ps            -e '/# GARDE:chaine/d'
mutant plafond        plafond          -e 's/\[ "\$n" -gt "\$MAX" \]/false/'
mutant sigkill        sigkill          -e '/# GARDE:sigkill/d'
mutant comm-12        comm             -e 's|^comm -12 "\$WORK/s1" "\$WORK/s2" > "\$WORK/surv"|cat "$WORK/s1" > "$WORK/surv"|'
mutant survivants     survivants       -e 's/exit 2   # GARDE:survivants/exit 0/'
mutant canari         m2_partiel       -e '/# GARDE:canari/d'
mutant canari-vide    indet_vide       -e '/# GARDE:canari/d'
mutant methode-absente indet_aucune    -e '/# GARDE:canari/d' -e 's/\*) indet [^;]*; return 4 ;;/*) : ;;/'
mutant echeance       m3_lsof_bloque   -e '/# GARDE:echeance/d'
mutant caracteres     m1_caracteres    -e '/# GARDE:caracteres/d'
mutant locale         m1_sans_locale   -e 's/ \&\& \[ -z "\$LOCALE_LSOF" \]/ \&\& false/'
mutant locale-forcee  m1_accent        -e 's/LC_ALL="\${LOCALE_LSOF:-C}" lsof/lsof/'
mutant casse          m1_casse         -e 's/ || { indet casse[^}]*}   # GARDE:casse/ || :/'
mutant famille-nom    famille          -e '/# GARDE:famille-nom/d'
mutant famille-git    famille          -e 's/\[ ! -e "\$g" \] || refus "englobe un autre dépôt ou worktree"/:/'
mutant famille-git-2n famille          -e 's|for g in "\$P"/\*/.git "\$P"/\*/\*/.git; do|for g in "$P"/*/.git; do|'
mutant privilegie     proc_priv        -e 's/if plus_privilegie "\$pid"; then/if false; then/'
mutant non-dumpable   proc_nondump     -e 's/ \&\& non_dumpable "\$d" "\$pid"/ \&\& false/'
mutant ptrace-nd      proc_nondump     -e '/# GARDE:ptrace-nd$/d'
mutant ptrace         proc_ptrace      -e '/# GARDE:ptrace$/d'
mutant proc-illisible proc_inexplique  -e 's/; return 4   # GARDE:proc-illisible/; continue   # GARDE:proc-illisible/'
mutant ancetre-ignore proc_ancetre     -e '/# GARDE:ancetre-ignore/d'
mutant vivant         vivant_sans_ps   -e '/# GARDE:vivant/d'
mutant git            m2_git           -e '/# GARDE:git/d'
mutant worktrees      m2_git           -e '/# GARDE:worktrees/d'
mutant absolu         refus_absolu     -e '/# GARDE:absolu/d'
mutant dotdot         refus_dotdot     -e '/# GARDE:dotdot/d'
mutant inexistant     refus_inexistant -e '/# GARDE:inexistant/d' -e 's/^\[ -n "\$P" \] || refus "illisible"/P="${P:-$PATH_ARG}"/'
mutant composants     refus_composants -e '/# GARDE:composants/d'
mutant home           refus_home       -e '/# GARDE:home/d'
mutant ancetre-home   refus_ancetre    -e '/# GARDE:ancetre-home/d'

# --- aucun orphelin
tuer_tout_check=0
while read -r p; do vivant "$p" && tuer_tout_check=1; done < "$TMP/pids"
assert_eq "aucun leurre vivant en fin de suite" 0 "$tuer_tout_check" && ok "aucun orphelin" || ko "orphelin — $DETAIL"

echo "== $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
