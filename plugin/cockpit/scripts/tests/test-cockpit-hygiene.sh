#!/usr/bin/env bash
# test-cockpit-hygiene.sh — épingle les garde-fous de hygiene.sh (P67-G1, revue fix-67-d) : suite à SEC, sans serveur ni Chrome.
#   H-sonde  une sonde (processus fils, marque propre « tmp.Sd… ») vérifie G1 (marque transmise à awk), G2 (marque invalide : rien listé, init refuse,
#            chaîne entière), G3 (plafond de 20 : H1 rouge, aucun kill), G4 (ancêtres jamais visés), M1 (PID sans marque jamais visé, PIDS purgé),
#            m1 (étranger non descendant jamais listé, arbre orphelin couvert), m2 (ps inutilisable : FAIL nommé H-0)
#   H-mut    chaque garde est mutée dans une copie de hygiene.sh : la sonde DOIT rougir, et par l'assertion visée (attendu, obtenu affichés)
# Rien de réel n'est tué : VF_HYG_DRY=1 dans la sonde ; seuls ses propres leurres (marqués, créés par elle) reçoivent un signal, par vf_hyg_stop.
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
HERE_T="$(cd "$(dirname "$0")" && pwd)"; HYG="$HERE_T/hygiene.sh"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; PIDS=()
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$HYG"; vf_hyg_init
STAG="tmp.Sd$(basename "$WORK" | sed 's/^tmp\.//')"   # marque de la sonde : jamais une sous-chaîne de celle de la suite
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

cat > "$WORK/sonde.sh" <<'EOF'
# sonde.sh <hygiene.sh> <marque> <tests|all> <pid étranger> <dossier de la suite> — écrit « OK libellé » / « KO libellé | attendu | obtenu »
. "$1"; STAG="$2"; ONLY="${3:-all}"; ETR="$4"; STB="$(basename "$5")"; NOPS="$5/nops"
export VF_HYG_DRY=1; VF_HYG_TAG="$STAG"; PIDS=(); LEURRES=""
res() { if [ "$2" = "$3" ]; then echo "OK $1"; else echo "KO $1 | attendu=[$3] | obtenu=[$2]"; fi; }
veut() { [ "$ONLY" = all ] && return 0; case " $ONLY " in *" $1 "*) return 0 ;; esac; return 1; }
leurre() { bash -c 'exec -a "$0" sleep 25' "/x/$STAG/$1/$STB" </dev/null >/dev/null 2>&1 & LAST=$!; LEURRES="$LEURRES $LAST"; }
fin_leurres() { local p; for p in $LEURRES; do VF_HYG_DRY="" vf_hyg_stop "$p" >/dev/null; done; LEURRES=""; }
if veut g1; then
  leurre a; leurre b; leurre c; sleep 0.4
  res "G1 — la marque atteint awk : les 3 leurres marqués sont listés (et l'étranger non descendant ne l'est pas)" "$(vf_hyg_vivants | wc -l | tr -d ' ')" 3
  fin_leurres
fi
if veut g2; then
  bad=0; for t in "" "tmp." "tmp.ab" "tmp.abcde" "tmp.abcde.fgh" ".*" "tmp.aaaaaaaa
tmp.bbbbbbbb" " tmp.abcdefgh" "tmp.abcdefg h" "tmp.abcdef
"; do VF_HYG_TAG="$t"; vf_hyg_tag_ok && bad=$((bad+1)); done
  VF_HYG_TAG=tmp.abcdef; ok1=non; vf_hyg_tag_ok && ok1=oui; VF_HYG_TAG="$STAG"
  res "G2 — marque vide, courte, à métacaractère ou multi-ligne : aucune acceptée (chaîne entière)" "$bad" 0
  res "G2 — témoin positif : tmp.abcdef est acceptée" "$ok1" oui
  out="$( (WORK=/x/tmp.; vf_hyg_init) 2>&1; echo "rc=$?" )"
  res "G2 — init refuse une marque invalide : FAIL nommé H-1" "$(printf '%s\n' "$out" | grep -c 'H-1 marque de suite invalide')" 1
  res "G2 — init refuse une marque invalide : exit 1" "$(printf '%s\n' "$out" | grep -c '^rc=1$')" 1
  leurre a; sleep 0.3; VF_HYG_TAG=""; n0="$(vf_hyg_vivants | wc -l | tr -d ' ')"; VF_HYG_TAG="tmp."; n1="$(vf_hyg_vivants | wc -l | tr -d ' ')"; VF_HYG_TAG="$STAG"
  res "G2 — une marque vide ou « tmp. » ne liste aucun processus" "$n0+$n1" "0+0"; fin_leurres
fi
if veut g3; then
  for i in $(seq 1 22); do leurre "l$i"; done; sleep 0.6
  assert_eq() { echo "ASSERT|$1|$2|$3"; }
  out="$(vf_hyg_assert 2>&1)"
  res "G3 — plus de 20 processus marqués : l'assertion H1 (marque trop large) rougit" "$(printf '%s\n' "$out" | sed -n 's/^ASSERT|\(H[0-9-]*\) .*/\1/p')" H1
  res "G3 — H1 : 22 processus comptés" "$(printf '%s\n' "$out" | awk -F'|' '/^ASSERT/{print $3}')" 22
  res "G3 — H1 : aucun kill envoyé" "$(printf '%s\n' "$out" | grep -c '^DRY kill')" 0
  out="$(vf_hyg_fin 2>&1)"
  res "G3 — vf_hyg_fin : message « marque trop large » et aucun kill" "$(printf '%s\n' "$out" | grep -c 'H1 marque trop large')/$(printf '%s\n' "$out" | grep -c '^DRY kill')" "1/0"
  fin_leurres
fi
if veut g4; then
  leurre a; sleep 0.3
  res "G4 — témoin : la sonde et son parent portent bien la marque" "$(ps -o args= -p "$$" -p "$PPID" | grep -c "$STAG")" 2
  res "G4 — la sonde et son parent (marqués) ne sont jamais listés" "$(vf_hyg_vivants | grep -c -E "^($$|$PPID) ")" 0
  res "G4 — vf_hyg_kill refuse la sonde et son parent, pourtant marqués" "$(vf_hyg_kill TERM "$$" "$PPID" 1 0 2>&1 | grep -c '^DRY kill')" 0
  fin_leurres
fi
if veut m1pid; then
  sleep 20 & U=$!; leurre mk; sleep 0.3
  res "M1 — vf_hyg_kill refuse un PID sans la marque (pour tout appelant)" "$(vf_hyg_kill TERM "$U" 2>&1 | grep -c '^DRY kill')" 0
  res "M1 — témoin positif : vf_hyg_kill vise le leurre marqué" "$(vf_hyg_kill TERM "$LAST" 2>&1 | grep -c "^DRY kill -TERM $LAST\$")" 1
  PIDS=("$U" "$LAST" 1 "$$" "$PPID"); vf_hyg_arreter > "$5/arret.out" 2>&1
  res "M1 — arreter ne vise ni le PID sans marque, ni pid 1, ni la sonde, ni son parent" "$(grep '^DRY kill' "$5/arret.out" | awk '{print $4}' | tr '\n' ' ')" "$LAST "
  res "M1 — PIDS est vidé par arreter" "${#PIDS[@]}" 0
  PIDS=("$U" "$LAST"); vf_hyg_stop "$LAST" > "$5/stop.out" 2>&1
  res "M1 — vf_hyg_stop retire le pid arrêté de PIDS" "${PIDS[*]}" "$U"
  vf_hyg_stop "$U" > "$5/stop.out" 2>&1
  res "M1 — vf_hyg_stop d'un PID sans marque : rien n'est envoyé, il sort de PIDS" "$(grep -c '^DRY kill' "$5/stop.out")/${#PIDS[@]}" "0/0"
  kill "$U" 2>/dev/null; wait "$U" 2>/dev/null; fin_leurres  # U : enfant non encore récolté de CE shell, son PID ne peut pas être recyclé
fi
if veut m1tree; then
  M="/x/$STAG/orph/$STB"; leurre a; sleep 0.3
  ( bash -c 'bash -c "exec -a \"\$0\" sleep 25" "$0" & wait' "$M" </dev/null >/dev/null 2>&1 & )
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do n1="$(ps -eo pid,ppid,args | awk -v m="$M" 'index($0, m) > 0 && $2 == 1' | wc -l | tr -d ' ')"; [ "$n1" -ge 1 ] && break; sleep 0.2; done
  res "m1 — témoin : l'arbre orphelin est rattaché à pid 1 (launchd ou init)" "$n1" 1
  res "m1 — témoin : l'étranger non descendant porte la marque et vit" "$(ps -o args= -p "$ETR" | grep -c "$STAG")/$(kill -0 "$ETR" && echo vit)" "1/vit"
  v="$(vf_hyg_vivants)"
  res "m1 — l'étranger (marqué, ni descendant ni orphelin) n'est jamais listé" "$(printf '%s\n' "$v" | grep -c "/x/$STAG/etranger")" 0
  res "m1 — l'arbre orphelin (Chrome dont le parent node est mort) reste couvert : père et fils" "$(printf '%s\n' "$v" | grep -c "$M")" 2
  res "m1 — un descendant de la sonde est listé" "$(printf '%s\n' "$v" | grep -c "/x/$STAG/a/")" 1
  for p in $(printf '%s\n' "$v" | awk '{print $1}'); do VF_HYG_DRY="" vf_hyg_stop "$p" >/dev/null; done; LEURRES=""
fi
if veut m2; then
  mkdir -p "$NOPS"; for b in awk grep tr wc sleep basename rm cut sed; do ln -sf "$(command -v $b)" "$NOPS/$b"; done
  assert_eq() { echo "ASSERT|$1|$2|$3"; }
  out="$(PATH="$NOPS" vf_hyg_assert 2>&1)"
  res "m2 — ps inutilisable : l'assertion nommée H-0 rougit (jamais un vert aveugle)" "$(printf '%s\n' "$out" | sed -n 's/^ASSERT|\(H[0-9-]*\) .*/\1/p')" "H-0"
  out="$( (WORK=/x/tmp.abcdef12; PATH="$NOPS"; vf_hyg_init) 2>&1; echo "rc=$?" )"
  res "m2 — init avec ps inutilisable : FAIL nommé H-0 et exit 1" "$(printf '%s\n' "$out" | grep -c 'H-0 ps inutilisable')/$(printf '%s\n' "$out" | grep -c '^rc=1$')" "1/1"
fi
EOF
cat > "$WORK/muter.py" <<'EOF'
import sys
M = {
 "G1": ('ps -eo pid,ppid,args | VF_T="$VF_HYG_TAG" VF_ME="$$" VF_PP="$PPID" VF_B="$self" awk', 'VF_T="$VF_HYG_TAG" VF_ME="$$" VF_PP="$PPID" VF_B="$self" ps -eo pid,ppid,args | awk'),
 "G2": ('[ "${#t}" -ge 10 ] || return 1', 'return 0'),
 "G2-ancre": ('''case "${t#tmp.}" in ''|*[!A-Za-z0-9]*) return 1 ;; esac''', '''printf '%s' "$t" | grep -Eq '^tmp\\.[A-Za-z0-9]{6,}$' || return 1'''),
 "G3": ('-gt "$VF_HYG_MAX" ]; then assert_eq "H1', '-gt 99999 ]; then assert_eq "H1'),
 "G4-vivants": ('{ prot[p] = 1; pa[arg[p]] = 1; p = pp[p]; k++ }', '{ p = pp[p]; k++ }'),
 "G4-kill": ('case "$anc" in *" $p "*) continue ;; esac', ':'),
 "M1-kill": ('vf_hyg_marque_p "$p" || continue', ':'),
 "M1-purge": ('[ "$q" = "$p" ] || n+=("$q")', 'n+=("$q")'),
 "m1": ('if (d || index(arg[top], t) > 0) print q " " arg[q]', 'print q " " arg[q]'),
 "m2": ('vf_hyg_ps_ok() { ps -eo', 'vf_hyg_ps_ok() { return 0; ps -eo'),
 "AM7-tardif": ('. "$VF_HYG_DIR/chrome-saut.sh"', '. "$(dirname "${BASH_SOURCE[0]}")/chrome-saut.sh"'),
}
i, src, dst = sys.argv[1:4]; o, n = M[i]; s = open(src).read()
if s.count(o) != 1: sys.exit("motif muté présent %d fois" % s.count(o))
open(dst, "w").write(s.replace(o, n))
EOF
# lancer <hygiene.sh> <tests> : la sonde, sous un parent marqué, avec un étranger marqué (frère de la sonde) ; marqués aussi de la marque de la suite (fuite = H0 rouge)
lancer() {
  local etr out; bash -c 'exec -a "$0" sleep 60' "/x/$STAG/etranger/$(basename "$WORK")" </dev/null >/dev/null 2>&1 & etr=$!; PIDS+=("$etr"); sleep 0.2
  out="$(bash -c 'bash "$1" "$2" "$3" "$4" "$5" "$6"; :' "/x/$STAG/parent/$(basename "$WORK")" "$WORK/sonde.sh" "$1" "$STAG" "$2" "$etr" "$WORK" 2>&1)"
  vf_hyg_stop "$etr"; printf '%s\n' "$out"
}
echo "=== H-sonde — le vrai hygiene.sh ==="
OUT="$(lancer "$HYG" all)"; printf '%s\n' "$OUT" | grep '^KO' | sed 's/^/     /'
assert_eq "H-sonde — aucune vérification de la sonde ne rougit" "$(printf '%s\n' "$OUT" | grep -c '^KO')" "0"
assert_eq "H-sonde — la sonde a exécuté au moins 20 vérifications (anti-vert-à-vide)" "$([ "$(printf '%s\n' "$OUT" | grep -c '^OK')" -ge 20 ] && echo oui || echo non)" "oui"

echo "=== H-mut — chaque garde mutée rougit par SON assertion ==="
mutant() { # mutant <id> <tests de la sonde> <libellé exact attendu rouge>
  local rc sortie; python3 -I "$WORK/muter.py" "$1" "$HYG" "$WORK/mut-$1.sh" 2>&1; rc=$?
  assert_eq "mutant $1 — la mutation s'applique (motif présent une fois)" "$rc" "0"
  sortie="$(lancer "$WORK/mut-$1.sh" "$2")"
  printf '%s\n' "$sortie" | grep -F "KO $3" | head -1 | cut -c1-230 | sed 's/^/     /'
  assert_eq "mutant $1 — la sonde rougit pour CETTE raison : « ${3:0:70}… »" "$(printf '%s\n' "$sortie" | grep -cF "KO $3")" "1"
}
mutant G1 g1 "G1 — la marque atteint awk"
mutant G2 g2 "G2 — marque vide, courte"
mutant G2-ancre g2 "G2 — marque vide, courte"
mutant G3 g3 "G3 — plus de 20 processus marqués"
mutant G4-vivants g4 "G4 — la sonde et son parent (marqués) ne sont jamais listés"
mutant G4-kill g4 "G4 — vf_hyg_kill refuse la sonde"
mutant M1-kill m1pid "M1 — vf_hyg_kill refuse un PID sans la marque"
mutant M1-purge m1pid "M1 — vf_hyg_stop retire le pid arrêté de PIDS"
mutant m1 m1tree "m1 — l'étranger (marqué, ni descendant ni orphelin) n'est jamais listé"
mutant m2 m2 "m2 — ps inutilisable"

echo "=== H-AM7 — le filet de sortie AM7 (chrome-saut.sh) tient quand la suite est lancée par un chemin RELATIF et change de dossier ==="
cat > "$WORK/am7-essai.sh" <<'EOF'
# Suite d'essai : lancée par « bash ./essai.sh » depuis son propre dossier, source ./hygiene.sh (chemin relatif), pose CHROME vide (moitié navigateur non jouée) puis CHANGE DE DOSSIER, comme test-cockpit-questions.sh
set -uo pipefail
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; PIDS=()
trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. ./hygiene.sh; vf_hyg_init
CHROME=""
cd "$WORK"
echo "essai : moitié navigateur non jouée"
exit 0
EOF
am7() { # am7 <hygiene.sh à essayer> : « code de sortie / lignes FAIL AM7 / lignes « No such file » » de la suite d'essai, CI=1, lancée par chemin relatif
  local d out rc; [ -f "$1" ] || { printf 'copie absente'; return 0; }   # une copie manquante donnerait « No such file » sur ./hygiene.sh : un mutant mort qui ressemble à un mutant tué
  d="$(mktemp -d "$WORK/am7.XXXXXX")"
  cp "$1" "$d/hygiene.sh"; cp "$HERE_T/chrome-saut.sh" "$d/chrome-saut.sh"; cp "$WORK/am7-essai.sh" "$d/essai.sh"
  out="$( cd "$d" && env -u VF_CHROME_OPTIONNEL -u CHAINE_SANS_NAVIGATEUR -u SIGNAL_SANS_NAVIGATEUR LC_ALL=C CI=1 TMPDIR="$WORK" bash ./essai.sh 2>&1 )"; rc=$?
  printf '%s/%s/%s' "$rc" "$(printf '%s\n' "$out" | grep -c 'FAIL — AM7')" "$(printf '%s\n' "$out" | grep -c 'No such file')"
}
assert_eq "H-AM7 — suite lancée par chemin relatif, CI=1, CHROME vide, dossier changé au niveau du script : sortie 1, un message AM7, aucun chargement en échec" "$(am7 "$HYG")" "1/1/0"
python3 -I "$WORK/muter.py" AM7-tardif "$HYG" "$WORK/mut-AM7-tardif.sh" 2>&1; assert_eq "mutant AM7-tardif — la mutation s'applique (motif présent une fois)" "$?" "0"
assert_eq "mutant AM7-tardif — la copie mutée porte la résolution tardive, une seule fois (preuve qu'elle est celle qui est chargée)" "$(grep -cF '. "$(dirname "${BASH_SOURCE[0]}")/chrome-saut.sh"' "$WORK/mut-AM7-tardif.sh" 2>/dev/null)" "1"
assert_eq "mutant AM7-tardif — le chargement de chrome-saut.sh se résout de nouveau à la sortie (copie mutée bien chargée : « No such file » vu, sortie 0, aucun message AM7)" "$(am7 "$WORK/mut-AM7-tardif.sh")" "0/0/1"

vf_hyg_assert
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
echo "RÉSULTAT: $PASS passées, $FAIL échouées"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
