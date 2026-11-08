#!/usr/bin/env bash
# Test de worktree-procs.sh (issue #223) — autonome, borné, sans orphelin.
# Chaque leurre (`sleep 300`) a son PID consigné dans $TMP/pids et tué par le trap EXIT.
# Chaque garde est prouvée par un mutant : copie du script SANS la garde, le cas correspondant doit
# rougir (trace : cas, attendu, obtenu). Les cas de refus ne lancent que `list` sur les mutants :
# `stop` n'est joué que sur le vrai script, avec --max=1 (filet : si un refus régresse, rc 3, rien tué).
set -uo pipefail

REAL="$(cd "$(dirname "$0")/.." && pwd)/worktree-procs.sh"
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
    case "$c" in *"sleep 300"*) kill -KILL "$p" 2>/dev/null || : ;; esac
    { wait "$p"; } 2>/dev/null || :
  done < "$TMP/pids"
  : > "$TMP/pids"
}
trap 'tuer_tout; rm -rf "$TMP"' EXIT

DETAIL=""
assert_eq() { # label attendu obtenu
  [ "$2" = "$3" ] && return 0
  DETAIL="cas [$1] attendu [$2] obtenu [$3]"; return 1
}
leurre() { # leurre <dir> [ignterm] -> LP
  if [ "${2:-}" = "ignterm" ]; then (cd "$1" && trap '' TERM && exec sleep 300) &
  else (cd "$1" && exec sleep 300) & fi
  LP=$!; echo "$LP" >> "$TMP/pids"
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
  cible liste; leurre "$CIB"; local a=$LP; leurre "$CIB/sous"; local b=$LP; sleep 0.3
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
  cible frere; leurre "$CIB"; local a=$LP; leurre "$CIB-b"; local f=$LP; sleep 0.3
  run "$1" list --path="$CIB"
  assert_eq "list ne cite pas le frère" 0 "$(printf '%s\n' "$OUT" | grep -c "^$f$(printf '\t')")" || return 1
  run "$1" stop --path="$CIB"
  assert_eq "stop rc" 0 "$RC" || return 1
  assert_eq "leurre cible" mort "$(etat $a)" || return 1
  assert_eq "frère préfixe cible-b" vivant "$(etat $f)" || return 1
  tuer_tout
}
cas_hors() {
  cible hors; leurre "$TMP/hors/hors"; local h=$LP; mkdir -p "$TMP/hors/hors"; sleep 0.3
  run "$1" list --path="$CIB"
  assert_eq "list rc (rien dans la cible)" 0 "$RC" || return 1
  run "$1" stop --path="$CIB"
  assert_eq "stop rc" 0 "$RC" || return 1
  assert_eq "leurre hors cible" vivant "$(etat $h)" || return 1
  tuer_tout
}
cas_appelant() {
  cible appelant; leurre "$CIB"; local a=$LP; sleep 0.3
  local got
  got="$(bash -c 'cd "$1" && bash "$2" stop --path="$1" >/dev/null 2>&1; echo "rc=$?"; echo VIVANT' _ "$CIB" "$1" 2>/dev/null | tr '\n' ' ')"
  assert_eq "shell appelant (cwd dans la cible) survit" "rc=0 VIVANT " "$got" || return 1
  assert_eq "leurre cible" mort "$(etat $a)" || return 1
  tuer_tout
}
cas_plafond() {
  cible plafond; local i pids=""
  for i in 1 2 3 4; do leurre "$CIB"; pids="$pids $LP"; done; sleep 0.3
  run "$1" stop --path="$CIB" --max=3
  assert_eq "stop 4 > --max=3 rc" 3 "$RC" || return 1
  local p v=""; for p in $pids; do v="$v$(etat $p) "; done
  assert_eq "tous survivent" "vivant vivant vivant vivant " "$v" || return 1
  run "$1" stop --path="$CIB" --max=4
  assert_eq "stop 4 <= --max=4 rc" 0 "$RC" || return 1
  tuer_tout
}
cas_sigkill() {
  cible sigkill; leurre "$CIB" ignterm; local a=$LP; sleep 0.3
  run "$1" stop --path="$CIB"
  assert_eq "stop d'un leurre qui ignore SIGTERM rc" 0 "$RC" || return 1
  assert_eq "leurre" mort "$(etat $a)" || return 1
  tuer_tout
}
cas_indet_aucune() {
  cible indetA; leurre "$CIB"; local a=$LP; sleep 0.3
  OUT="$(VF_WTP_METHODE=aucune bash "$1" list --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "list sans méthode rc" 4 "$RC" || return 1
  OUT="$(VF_WTP_METHODE=aucune bash "$1" stop --path="$CIB" 2>/dev/null)"; RC=$?
  assert_eq "stop sans méthode rc" 4 "$RC" || return 1
  assert_eq "leurre épargné" vivant "$(etat $a)" || return 1
  tuer_tout
}
cas_indet_vide() {
  cible indetV; mkdir -p "$TMP/fakebin"; printf '#!/bin/sh\nexit 0\n' > "$TMP/fakebin/lsof"; chmod +x "$TMP/fakebin/lsof"
  leurre "$CIB"; local a=$LP; sleep 0.3
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

echo "== test-worktree-procs =="
for c in liste_arret frere hors appelant plafond sigkill indet_aucune indet_vide refus_absolu refus_dotdot refus_inexistant refus_composants refus_home refus_ancetre stop_refus_reel usage; do
  DETAIL=""
  if cas_$c "$REAL"; then ok "cas $c"; else ko "cas $c — $DETAIL"; tuer_tout; fi
done

# --- mutants : la copie sans la garde DOIT rougir sur le cas désigné
mutant() { # mutant <nom> <cas> <sed args...>
  local nom="$1" cas="$2"; shift 2
  local m="$TMP/mut-$nom.sh"
  sed "$@" "$REAL" > "$m"
  if cmp -s "$REAL" "$m"; then ko "mutant $nom identique au script (sed sans effet)"; return; fi
  DETAIL=""
  if "cas_$cas" "$m"; then ko "mutant $nom SURVIT : le cas $cas reste vert sans la garde"; tuer_tout
  else ok "mutant $nom tué — rouge : $DETAIL"; tuer_tout; fi
}
mutant frontiere      frere            -e 's/index(\$2, P "\/") == 1/index($2, P) == 1/'
mutant selection-tout hors             -e 's/(\$2 == P || index(\$2, P "\/") == 1)/1/'
mutant ancetres       appelant         -e 's/p=\$\$; i=0/p=""; i=0/'
mutant plafond        plafond          -e 's/\[ "\$n" -gt "\$MAX" \]/false/'
mutant sigkill        sigkill          -e '/# GARDE:sigkill/d'
mutant lecture-vide   indet_vide       -e '/# GARDE:lecture-vide/d'
mutant methode-absente indet_aucune    -e '/# GARDE:lecture-vide/d' -e 's/\*) return 4 ;;/*) : ;;/'
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
