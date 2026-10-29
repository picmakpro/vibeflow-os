#!/usr/bin/env bash
# test-vf-divergence-hook.sh — Suite de vf-divergence-hook.sh (Phase 61, plan 61-03, COLB-02/03/04/09).
#
# Le script pose, refuse, retire et juge ; la suite le prouve sur des depots jetables :
#   VDH-TRACE            tracer : clone arme, fusion divergente (pull --no-rebase) -> cri + ligne de journal
#   VDH-REWRITE          clone arme avec commit local, pull --rebase -> cri, hook post-rewrite journalise
#   VDH-REWRITE-AMEND    git commit --amend sur un arbre divergent -> silence, aucune ligne de journal
#   VDH-JOURNAL          format v1 du journal : en-tete, sept champs, date, HEAD, aucun nom de phase
# (ajoutes par les taches suivantes du plan, voir les sections plus bas : VDH-ARM-*, VDH-DISARM*,
#  VDH-STATUS, VDH-NOGIT, VDH-USAGE, VDH-RUN-*, VDH-INTROUVABLE, VDH-JOURNAL-LIEN, VDH-CODES, VDH-MUT-1..12.)
#
# ISOLATION (P61-PL-18) : HOME jetable, GIT_CONFIG_NOSYSTEM=1, GIT_CONFIG_GLOBAL vers un fichier vide,
# variables VF_* et GIT_DIR retirees, identite git posee localement dans chaque clone, caches de test sous
# $TMP/cache (copie des trois fichiers utiles), JAMAIS sous un depot de fixture. Fixtures generees par
# printf a l'execution (compartiment `w1`, phases `x`, `y`, `p`, `q`). Comparaisons de contenus par
# cmp -s / cksum / comm, jamais diff. Chaque appel du script et chaque commande git de fusion est borne
# par une alarme perl (une FIFO ou un hook bloque ne doit jamais bloquer la suite).
# Convention : ok()/ko()/skip(), exit 0 si tout passe, exit 1 au moindre KO.

set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/vf-divergence-hook.sh"
CONDUCTOR_DIR="$(dirname "$SCRIPT")"
POLICY="$(cd "$CONDUCTOR_DIR/../../planning-core/scripts" 2>/dev/null && pwd)/workstream-policy.sh"
TARGET="$SCRIPT"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; }
GREP="$(command -v grep)"
TAB="$(printf '\t')"

TMP="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR XDG_CONFIG_HOME VF_DIVERGENCE_HOOK VF_ROLE VF_SCOPE VF_TARGET GSD_WORKSTREAM VF_WORKSTREAM VF_WORKSTREAM_PLANNING_DIR
mkdir -p "$TMP/home"; : > "$TMP/gitconfig"
export HOME="$TMP/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$TMP/gitconfig" GIT_TERMINAL_PROMPT=0

echo "== test-vf-divergence-hook =="

if [ ! -f "$POLICY" ] || [ ! -f "$CONDUCTOR_DIR/check-divergence.sh" ] || ! command -v perl > /dev/null 2>&1 || ! command -v git > /dev/null 2>&1; then
  skip "git, perl, check-divergence.sh ou workstream-policy.sh introuvables : la suite ne prouverait rien"
  exit 0
fi

nlines() { awk 'END { print NR }' "$1"; }
# field <fichier> <ligne> <n> — champ n (tabulation) de la ligne donnee.
field() { awk -F "$TAB" -v l="$2" -v n="$3" 'NR==l { print $n; exit }' "$1"; }
runb() { perl -e 'alarm 30; exec @ARGV' "$@"; }

# mk_cache <dossier> <script du hook> — cache de plugin de test : le hook, son voisin check-divergence.sh et
# la politique de compartiment. Hors de tout depot de fixture.
mk_cache() {
  mkdir -p "$1/conductor/scripts" "$1/planning-core/scripts" || return 1
  cp "$2" "$1/conductor/scripts/vf-divergence-hook.sh" \
    && cp "$CONDUCTOR_DIR/check-divergence.sh" "$1/conductor/scripts/check-divergence.sh" \
    && cp "$POLICY" "$1/planning-core/scripts/workstream-policy.sh"
}

# hk <args...> — appelle TARGET (borne) ; sorties $TMP/hk.out et $TMP/hk.err, code dans HKRC, trace "<verbe> <rc>"
# dans $TMP/rcs. HKDIR (facultatif) = repertoire courant de l'appel.
hk() {
  HKRC=0
  (cd "${HKDIR:-.}" && perl -e 'alarm 30; exec @ARGV' bash "$TARGET" "$@") > "$TMP/hk.out" 2> "$TMP/hk.err" < /dev/null || HKRC=$?
  printf '%s %s\n' "$1" "$HKRC" >> "$TMP/rcs"
}

git_init() { git init -q -b main "$1" > /dev/null 2>&1 || { git init -q "$1" > /dev/null 2>&1 && git -C "$1" symbolic-ref HEAD refs/heads/main; }; }
git_init_bare() { git init -q --bare -b main "$1" > /dev/null 2>&1 || { git init -q --bare "$1" > /dev/null 2>&1 && git --git-dir="$1" symbolic-ref HEAD refs/heads/main; }; }
ident() { git -C "$1" config user.email "test@example.invalid"; git -C "$1" config user.name "test"; git -C "$1" config commit.gpgsign false; }

# mk_pair <id> — depot d'origine partitionne (compartiment `w1`, phase 1 conforme) et deux clones `a` et `b`
# dans $TMP/<id>/.
mk_pair() {
  P="$TMP/$1"; mkdir -p "$P"
  git_init_bare "$P/origin.git"
  git_init "$P/seed"; ident "$P/seed"
  mkdir -p "$P/seed/.planning/workstreams/w1/phases/01-a"
  printf '### Phase 1: a\n' > "$P/seed/.planning/workstreams/w1/ROADMAP.md"
  printf -- '---\nprogress:\n  completed_phases: 1\n---\n' > "$P/seed/.planning/workstreams/w1/STATE.md"
  printf 'phase 1\n' > "$P/seed/.planning/workstreams/w1/phases/01-a/01-CONTEXT.md"
  git -C "$P/seed" add -- .planning
  git -C "$P/seed" commit -q -m "seed"
  git -C "$P/seed" remote add origin "$P/origin.git"
  git -C "$P/seed" push -q origin main 2> /dev/null
  git clone -q "$P/origin.git" "$P/a" 2> /dev/null; ident "$P/a"
  git clone -q "$P/origin.git" "$P/b" 2> /dev/null; ident "$P/b"
}

# add_phase <clone> <numero> <suffixe> [roadmap] — dossier de phase du compartiment w1, commit ; `roadmap` ajoute
# aussi l'en-tete de phase au ROADMAP (a ne faire que d'un seul cote : deux ajouts au meme endroit se heurteraient).
add_phase() {
  local d="$1/.planning/workstreams/w1/phases/$2-$3"
  mkdir -p "$d"
  printf 'phase %s %s\n' "$2" "$3" > "$d/$2-CONTEXT.md"
  [ "${4:-}" = "roadmap" ] && printf '### Phase %s: %s\n' "$((10#$2))" "$3" >> "$1/.planning/workstreams/w1/ROADMAP.md"
  git -C "$1" add -- .planning
  git -C "$1" commit -q -m "phase $2 $3"
}

# pull_in <clone> <--no-rebase|--rebase> — vrai pull, borne ; stderr dans $TMP/pull.err, code dans PULLRC.
pull_in() {
  PULLRC=0
  runb git -C "$1" pull -q "$2" --no-edit > "$TMP/pull.out" 2> "$TMP/pull.err" < /dev/null || PULLRC=$?
}

# arm_in <clone> — arme par le script du cache ; code dans HKRC.
arm_in() { hk arm --path "$1"; }

# Cache de test (jamais sous un depot de fixture).
mk_cache "$TMP/cache" "$SCRIPT" || { echo "  ✗ pre-condition : cache de test non construit"; exit 1; }
TARGET="$TMP/cache/conductor/scripts/vf-divergence-hook.sh"
: > "$TMP/rcs"

# ===========================================================================
# VDH-TRACE — clone arme, fusion divergente par vrai pull --no-rebase
# ===========================================================================
miss=0
mk_pair t1
arm_in "$P/b"; [ "$HKRC" -eq 0 ] || { ko "VDH-TRACE pre-condition : arm rc=$HKRC — $(tail -3 "$TMP/hk.err")"; miss=1; }
add_phase "$P/a" 02 x roadmap
git -C "$P/a" push -q origin main 2> /dev/null || { ko "VDH-TRACE pre-condition : push de a refuse"; miss=1; }
add_phase "$P/b" 02 y
pull_in "$P/b" --no-rebase
[ "$PULLRC" -eq 0 ] || { ko "VDH-TRACE : le pull a echoue (rc=$PULLRC) — un post-merge ne doit jamais annuler la fusion"; miss=1; }
"$GREP" -qF '[vf-divergence] DIVERGENCE' "$TMP/pull.err" || { ko "VDH-TRACE : stderr du pull sans « [vf-divergence] DIVERGENCE » — $(tail -3 "$TMP/pull.err")"; miss=1; }
J1="$P/b/.git/vf-divergence/journal.tsv"
if [ -f "$J1" ]; then
  [ "$(nlines "$J1")" -eq 2 ] || { ko "VDH-TRACE : le journal n'a pas exactement 2 lignes ($(nlines "$J1"))"; miss=1; }
  [ "$(field "$J1" 2 2)" = "post-merge" ] || { ko "VDH-TRACE : champ 2 ≠ post-merge"; miss=1; }
  [ "$(field "$J1" 2 3)" = "DIVERGENCE" ] || { ko "VDH-TRACE : champ 3 ≠ DIVERGENCE"; miss=1; }
  [ "$(field "$J1" 2 4)" = "1" ] || { ko "VDH-TRACE : champ 4 ≠ 1"; miss=1; }
else
  ko "VDH-TRACE : aucun journal sous le .git du clone"; miss=1
fi
[ "$miss" -eq 0 ] && ok "VDH-TRACE (P61-D-04) : clone arme par arm, vrai pull --no-rebase divergent -> cri sur stderr + une ligne « post-merge DIVERGENCE 1 »"

# ===========================================================================
# VDH-REWRITE — pull --rebase avec commit local : seul post-rewrite se declenche (P61-D-05)
# ===========================================================================
miss=0
mk_pair r1
arm_in "$P/b"; [ "$HKRC" -eq 0 ] || { ko "VDH-REWRITE pre-condition : arm rc=$HKRC"; miss=1; }
[ -f "$P/b/.git/hooks/post-rewrite" ] || { ko "VDH-REWRITE : arm n'a pas pose post-rewrite"; miss=1; }
add_phase "$P/b" 03 p
add_phase "$P/a" 03 q roadmap
git -C "$P/a" push -q origin main 2> /dev/null || { ko "VDH-REWRITE pre-condition : push de a refuse"; miss=1; }
pull_in "$P/b" --rebase
[ "$PULLRC" -eq 0 ] || { ko "VDH-REWRITE : le pull --rebase a echoue (rc=$PULLRC)"; miss=1; }
"$GREP" -qF '[vf-divergence] DIVERGENCE apres post-rewrite' "$TMP/pull.err" || { ko "VDH-REWRITE : stderr sans « DIVERGENCE apres post-rewrite » (le pull --rebase echappe au filet) — $(tail -3 "$TMP/pull.err")"; miss=1; }
JR="$P/b/.git/vf-divergence/journal.tsv"
if [ -f "$JR" ]; then
  [ "$(nlines "$JR")" -eq 2 ] || { ko "VDH-REWRITE : le journal n'a pas exactement 2 lignes ($(nlines "$JR"))"; miss=1; }
  [ "$(field "$JR" 2 2)" = "post-rewrite" ] || { ko "VDH-REWRITE : champ 2 ≠ post-rewrite (« $(field "$JR" 2 2) »)"; miss=1; }
  [ "$(field "$JR" 2 3)" = "DIVERGENCE" ] || { ko "VDH-REWRITE : champ 3 ≠ DIVERGENCE"; miss=1; }
  [ "$(field "$JR" 2 5)" = "$(git -C "$P/b" rev-parse HEAD)" ] || { ko "VDH-REWRITE : champ 5 ≠ HEAD de b apres rebase"; miss=1; }
else
  ko "VDH-REWRITE : aucun journal sous le .git du clone"; miss=1
fi
[ "$miss" -eq 0 ] && ok "VDH-REWRITE (P61-D-05) : vrai git pull --rebase avec commit local -> cri « apres post-rewrite » + ligne de journal de hook post-rewrite, HEAD apres rebase"

# ===========================================================================
# VDH-REWRITE-AMEND — git commit --amend : silence, aucune ligne
# ===========================================================================
miss=0
mk_pair r2
arm_in "$P/b"; [ "$HKRC" -eq 0 ] || { ko "VDH-REWRITE-AMEND pre-condition : arm rc=$HKRC"; miss=1; }
add_phase "$P/b" 02 x roadmap
add_phase "$P/b" 02 y
RC=0; bash "$TMP/cache/conductor/scripts/check-divergence.sh" --path "$P/b" > /dev/null 2>&1 < /dev/null || RC=$?
[ "$RC" -eq 1 ] || { ko "VDH-REWRITE-AMEND pre-condition : l'arbre n'est pas divergent (check-divergence rc=$RC) — le silence ne prouverait rien"; miss=1; }
AMRC=0
runb git -C "$P/b" commit -q --amend --no-edit > "$TMP/amend.out" 2> "$TMP/amend.err" < /dev/null || AMRC=$?
[ "$AMRC" -eq 0 ] || { ko "VDH-REWRITE-AMEND : le amend a echoue (rc=$AMRC)"; miss=1; }
if "$GREP" -qF '[vf-divergence]' "$TMP/amend.err"; then ko "VDH-REWRITE-AMEND : le amend a produit une sortie [vf-divergence]"; miss=1; fi
[ ! -e "$P/b/.git/vf-divergence/journal.tsv" ] || { ko "VDH-REWRITE-AMEND : une ligne de journal a ete ecrite par un amend"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-REWRITE-AMEND (P61-D-05) : commit --amend sur un arbre divergent -> aucune sortie, aucun journal"

# ===========================================================================
# VDH-JOURNAL — format v1 (P61-PL-06), sur les journaux des deux cas precedents
# ===========================================================================
miss=0
for jf in "$J1" "$JR"; do
  if [ ! -f "$jf" ]; then ko "VDH-JOURNAL : journal absent ($jf)"; miss=1; continue; fi
  [ "$(awk -F "$TAB" 'NR==1 { print $1 }' "$jf")" = "# vf-divergence journal v1" ] || { ko "VDH-JOURNAL : en-tete ≠ « # vf-divergence journal v1 »"; miss=1; }
  [ "$(awk -F "$TAB" 'NR==1 { print $2 "," $3 "," $4 "," $5 "," $6 "," $7 "," $8 }' "$jf")" = "date,hook,verdict,code,head,signaux,raison" ] || { ko "VDH-JOURNAL : les sept noms de champs de l'en-tete sont absents ou dans un autre ordre"; miss=1; }
  [ "$(awk -F "$TAB" 'NR>1 && NF!=7 { n++ } END { print n+0 }' "$jf")" -eq 0 ] || { ko "VDH-JOURNAL : une ligne de donnees n'a pas sept champs"; miss=1; }
  [ "$(awk -F "$TAB" 'NR>1 && $1 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/ { n++ } END { print n+0 }' "$jf")" -eq "$(( $(nlines "$jf") - 1 ))" ] || { ko "VDH-JOURNAL : champ 1 ≠ AAAA-MM-JJTHH:MM:SSZ"; miss=1; }
  [ "$(awk -F "$TAB" 'NR>1 && ($5 ~ /^[0-9a-f]+$/) && (length($5)==40 || length($5)==64) { n++ } END { print n+0 }' "$jf")" -eq "$(( $(nlines "$jf") - 1 ))" ] || { ko "VDH-JOURNAL : champ 5 n'est pas un HEAD hexadecimal de 40 ou 64 caracteres"; miss=1; }
  [ "$(awk 'NR>1 && /[0-9][0-9]-[xypq]/ { n++ } END { print n+0 }' "$jf")" -eq 0 ] || { ko "VDH-JOURNAL : un nom de dossier de phase est entre dans le journal"; miss=1; }
done
[ "$miss" -eq 0 ] && ok "VDH-JOURNAL (P61-PL-06) : en-tete v1 + sept noms de champs, sept champs par ligne, date UTC, HEAD de 40 ou 64 hexadecimaux, aucun nom de phase"

# ===========================================================================
# Helpers de la tache 2
# ===========================================================================
# diverge <pusher> <puller> <num> — le pusher pousse la phase <num>-x (avec en-tete), le puller commite <num>-y
# puis tire (vrai pull --no-rebase) : divergence de numerotation, fusion sans conflit textuel.
diverge() {
  add_phase "$1" "$3" x roadmap
  git -C "$1" push -q origin main 2> /dev/null
  add_phase "$2" "$3" y
  pull_in "$2" --no-rebase
}
# hand_of <nom> — la ligne imprimee par le refus « LIGNE A AJOUTER A LA MAIN (<nom>) : ... » (stderr de hk).
hand_of() {
  awk -v n="($1) : " 'index($0, "LIGNE A AJOUTER A LA MAIN " n) { sub(/^.*LIGNE A AJOUTER A LA MAIN \([a-z-]*\) : /, ""); print; exit }' "$TMP/hk.err"
}
# put_tiers <clone> <nom> [ligne] — hook tiers (sh) ; avec <ligne>, il la porte.
put_tiers() {
  mkdir -p "$1/.git/hooks"
  if [ -n "${3:-}" ]; then printf '#!/bin/sh\necho tiers\n%s\n' "$3" > "$1/.git/hooks/$2"; else printf '#!/bin/sh\necho tiers\n'  > "$1/.git/hooks/$2"; fi
  chmod 755 "$1/.git/hooks/$2"
}
no_hook() { [ ! -e "$1/.git/hooks/post-merge" ] && [ ! -e "$1/.git/hooks/post-rewrite" ]; }

# ===========================================================================
# VDH-ARM-TIERS — un seul hook tiers suffit a ne RIEN ecrire (refus avant toute ecriture)
# ===========================================================================
miss=0
mk_pair t2
put_tiers "$P/b" post-rewrite
cp "$P/b/.git/hooks/post-rewrite" "$TMP/tiers.orig"
arm_in "$P/b"
[ "$HKRC" -eq 1 ] || { ko "VDH-ARM-TIERS : arm rend $HKRC (attendu 1)"; miss=1; }
"$GREP" -qF 'REFUS hook-tiers:post-rewrite' "$TMP/hk.err" || { ko "VDH-ARM-TIERS : stderr sans « REFUS hook-tiers:post-rewrite »"; miss=1; }
"$GREP" -qF 'LIGNE A AJOUTER A LA MAIN (post-rewrite)' "$TMP/hk.err" || { ko "VDH-ARM-TIERS : la ligne a ajouter a la main est absente"; miss=1; }
"$GREP" -qF 'SORTIE : VF_DIVERGENCE_HOOK=off' "$TMP/hk.err" || { ko "VDH-ARM-TIERS : la sortie documentee est absente"; miss=1; }
[ ! -e "$P/b/.git/hooks/post-merge" ] || { ko "VDH-ARM-TIERS : post-merge a ete ecrit malgre le refus (ecriture partielle)"; miss=1; }
cmp -s "$P/b/.git/hooks/post-rewrite" "$TMP/tiers.orig" || { ko "VDH-ARM-TIERS : le hook tiers a ete modifie"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-ARM-TIERS (P61-D-02) : post-rewrite tiers -> rc 1, REFUS hook-tiers:post-rewrite, aucun des deux hooks ecrit, tiers intact a l'octet"

# ===========================================================================
# VDH-ARM-MAIN — armé à la main (ligne a jour) / ligne perimee
# ===========================================================================
miss=0
mk_pair t3
put_tiers "$P/b" post-merge
put_tiers "$P/b" post-rewrite
arm_in "$P/b"
LM="$(hand_of post-merge)"; LR="$(hand_of post-rewrite)"
{ [ -n "$LM" ] && [ -n "$LR" ]; } || { ko "VDH-ARM-MAIN pre-condition : lignes a ajouter a la main non recuperees"; miss=1; }
put_tiers "$P/b" post-merge "$LM"; put_tiers "$P/b" post-rewrite "$LR"
cp "$P/b/.git/hooks/post-merge" "$TMP/m.orig"; cp "$P/b/.git/hooks/post-rewrite" "$TMP/r.orig"
arm_in "$P/b"
[ "$HKRC" -eq 0 ] || { ko "VDH-ARM-MAIN : arm rend $HKRC avec les deux lignes a jour (attendu 0) — $(tail -3 "$TMP/hk.err")"; miss=1; }
[ "$("$GREP" -cF 'ARME-A-LA-MAIN' "$TMP/hk.err")" -eq 2 ] || { ko "VDH-ARM-MAIN : « ARME-A-LA-MAIN » attendu deux fois"; miss=1; }
{ cmp -s "$P/b/.git/hooks/post-merge" "$TMP/m.orig" && cmp -s "$P/b/.git/hooks/post-rewrite" "$TMP/r.orig"; } || { ko "VDH-ARM-MAIN : un hook arme a la main a ete modifie"; miss=1; }
# Ligne perimee : meme ligne, autre chemin du script.
OLDM="$(printf '%s' "$LM" | sed "s#'[^']*'#'/autre/cache/conductor/scripts/vf-divergence-hook.sh'#")"
put_tiers "$P/b" post-merge "$OLDM"
cp "$P/b/.git/hooks/post-merge" "$TMP/m.orig"
arm_in "$P/b"
[ "$HKRC" -eq 1 ] || { ko "VDH-ARM-MAIN : ligne perimee, arm rend $HKRC (attendu 1)"; miss=1; }
"$GREP" -qF 'REFUS ligne-perimee:post-merge' "$TMP/hk.err" || { ko "VDH-ARM-MAIN : stderr sans « REFUS ligne-perimee:post-merge »"; miss=1; }
"$GREP" -qF "'$TARGET' run --hook post-merge" "$TMP/hk.err" || { ko "VDH-ARM-MAIN : la ligne a jour n'est pas imprimee"; miss=1; }
cmp -s "$P/b/.git/hooks/post-merge" "$TMP/m.orig" || { ko "VDH-ARM-MAIN : le hook a ligne perimee a ete modifie"; miss=1; }
# Une ligne commentee n'arme rien.
put_tiers "$P/b" post-merge "# $LM"
arm_in "$P/b"
[ "$HKRC" -eq 1 ] || { ko "VDH-ARM-MAIN : une ligne commentee est prise pour une ligne d'appel (rc=$HKRC)"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-ARM-MAIN (P61-PL-04) : lignes a jour -> ARME-A-LA-MAIN rc 0 fichiers intacts ; autre chemin -> REFUS ligne-perimee et ligne a jour ; ligne commentee ignoree"

# ===========================================================================
# VDH-ARM-HOOKSPATH — core.hooksPath local, puis global : rien d'ecrit nulle part
# ===========================================================================
miss=0
mk_pair t4
mkdir -p "$P/b/husky"
git -C "$P/b" config core.hooksPath "$P/b/husky"
arm_in "$P/b"
[ "$HKRC" -eq 1 ] || { ko "VDH-ARM-HOOKSPATH : core.hooksPath local, arm rend $HKRC (attendu 1)"; miss=1; }
"$GREP" -qF 'REFUS core.hooksPath' "$TMP/hk.err" || { ko "VDH-ARM-HOOKSPATH : stderr sans « REFUS core.hooksPath »"; miss=1; }
no_hook "$P/b" || { ko "VDH-ARM-HOOKSPATH : un hook a ete ecrit dans .git/hooks"; miss=1; }
[ "$(ls -A "$P/b/husky" | awk 'END { print NR }')" -eq 0 ] || { ko "VDH-ARM-HOOKSPATH : le dossier designe par core.hooksPath a ete ecrit"; miss=1; }
mk_pair t5
mkdir -p "$TMP/globalhooks"
printf '[core]\n\thooksPath = %s\n' "$TMP/globalhooks" > "$TMP/gitconfig"
arm_in "$P/b"
RCG="$HKRC"
: > "$TMP/gitconfig"
[ "$RCG" -eq 1 ] || { ko "VDH-ARM-HOOKSPATH : core.hooksPath global, arm rend $RCG (attendu 1)"; miss=1; }
"$GREP" -qF 'REFUS core.hooksPath' "$TMP/hk.err" || { ko "VDH-ARM-HOOKSPATH : global, stderr sans « REFUS core.hooksPath »"; miss=1; }
no_hook "$P/b" || { ko "VDH-ARM-HOOKSPATH : global, un hook a ete ecrit dans .git/hooks"; miss=1; }
[ "$(ls -A "$TMP/globalhooks" | awk 'END { print NR }')" -eq 0 ] || { ko "VDH-ARM-HOOKSPATH : le dossier global designe par core.hooksPath a ete ecrit"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-ARM-HOOKSPATH (P61-PL-03) : core.hooksPath local puis global -> rc 1, REFUS core.hooksPath, rien d'ecrit ni dans .git/hooks ni dans le dossier designe"

# ===========================================================================
# VDH-ARM-ARBRE — script situe sous l'arbre de travail : refuse
# ===========================================================================
miss=0
mk_pair t6
mk_cache "$P/b/outils/cache" "$SCRIPT" || { ko "VDH-ARM-ARBRE pre-condition : cache sous le clone non construit"; miss=1; }
SAVE_TARGET="$TARGET"; TARGET="$P/b/outils/cache/conductor/scripts/vf-divergence-hook.sh"
arm_in "$P/b"
TARGET="$SAVE_TARGET"
[ "$HKRC" -eq 1 ] || { ko "VDH-ARM-ARBRE : arm depuis une copie sous l'arbre rend $HKRC (attendu 1)"; miss=1; }
"$GREP" -qF 'REFUS executable-dans-l-arbre' "$TMP/hk.err" || { ko "VDH-ARM-ARBRE : stderr sans « REFUS executable-dans-l-arbre »"; miss=1; }
no_hook "$P/b" || { ko "VDH-ARM-ARBRE : un hook a ete ecrit"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-ARM-ARBRE (P61-D-03) : arm depuis une copie sous le clone -> rc 1, REFUS executable-dans-l-arbre, rien d'ecrit"

# ===========================================================================
# VDH-ARM-RACINE — lab qui n'est pas la racine du depot : refuse
# ===========================================================================
miss=0
mk_pair t7
arm_in "$P/b/.planning"
[ "$HKRC" -eq 1 ] || { ko "VDH-ARM-RACINE : arm sur un sous-dossier rend $HKRC (attendu 1)"; miss=1; }
"$GREP" -qF 'REFUS lab-hors-racine-git' "$TMP/hk.err" || { ko "VDH-ARM-RACINE : stderr sans « REFUS lab-hors-racine-git »"; miss=1; }
no_hook "$P/b" || { ko "VDH-ARM-RACINE : un hook a ete ecrit"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-ARM-RACINE (P61-PL-03) : --path d'un sous-dossier -> rc 1, REFUS lab-hors-racine-git, rien d'ecrit"

# ===========================================================================
# VDH-ARM-QUOTE — chemin non sur (apostrophe) : non verifiable, rien d'ecrit
# ===========================================================================
miss=0
mk_pair t8
mk_cache "$TMP/o'q/cache" "$SCRIPT" || { ko "VDH-ARM-QUOTE pre-condition : cache a apostrophe non construit"; miss=1; }
SAVE_TARGET="$TARGET"; TARGET="$TMP/o'q/cache/conductor/scripts/vf-divergence-hook.sh"
arm_in "$P/b"
TARGET="$SAVE_TARGET"
[ "$HKRC" -eq 2 ] || { ko "VDH-ARM-QUOTE : arm depuis un chemin a apostrophe rend $HKRC (attendu 2)"; miss=1; }
"$GREP" -qF 'NON VERIFIABLE chemin-non-sur' "$TMP/hk.err" || { ko "VDH-ARM-QUOTE : stderr sans « NON VERIFIABLE chemin-non-sur »"; miss=1; }
no_hook "$P/b" || { ko "VDH-ARM-QUOTE : un hook a ete ecrit"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-ARM-QUOTE (T-61-11) : chemin du script a apostrophe -> rc 2, NON VERIFIABLE chemin-non-sur, rien d'ecrit"

# ===========================================================================
# VDH-ARM-IDEMPOTENT — deux arm, memes octets
# ===========================================================================
miss=0
mk_pair t9
arm_in "$P/b"; [ "$HKRC" -eq 0 ] || { ko "VDH-ARM-IDEMPOTENT : premier arm rc=$HKRC"; miss=1; }
cp "$P/b/.git/hooks/post-merge" "$TMP/m.1"; cp "$P/b/.git/hooks/post-rewrite" "$TMP/r.1"
ls -A "$P/b/.git/hooks" > "$TMP/ls.1"
arm_in "$P/b"; [ "$HKRC" -eq 0 ] || { ko "VDH-ARM-IDEMPOTENT : second arm rc=$HKRC"; miss=1; }
{ cmp -s "$P/b/.git/hooks/post-merge" "$TMP/m.1" && cmp -s "$P/b/.git/hooks/post-rewrite" "$TMP/r.1"; } || { ko "VDH-ARM-IDEMPOTENT : les hooks different apres le second arm"; miss=1; }
ls -A "$P/b/.git/hooks" > "$TMP/ls.2"
cmp -s "$TMP/ls.1" "$TMP/ls.2" || { ko "VDH-ARM-IDEMPOTENT : le contenu du dossier de hooks a change (temporaire oublie ou doublon)"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-ARM-IDEMPOTENT : deux arm successifs -> hooks identiques a l'octet, dossier de hooks identique"

# ===========================================================================
# VDH-ARM-WORKTREE — worktree lie : dossier de hooks commun, journal commun
# ===========================================================================
miss=0
mk_pair t10
WT="$TMP/t10/wt"
git -C "$P/b" worktree add -q "$WT" -b wtbranch 2> /dev/null || { ko "VDH-ARM-WORKTREE pre-condition : worktree lie non cree"; miss=1; }
WT="$(cd "$WT" 2> /dev/null && pwd -P)"
arm_in "$WT"
[ "$HKRC" -eq 0 ] || { ko "VDH-ARM-WORKTREE : arm --path <worktree lie> rend $HKRC — $(tail -3 "$TMP/hk.err")"; miss=1; }
{ [ -f "$P/b/.git/hooks/post-merge" ] && [ -f "$P/b/.git/hooks/post-rewrite" ]; } || { ko "VDH-ARM-WORKTREE : les hooks ne sont pas dans le dossier de hooks commun"; miss=1; }
add_phase "$P/a" 02 x roadmap
git -C "$P/a" push -q origin main 2> /dev/null
git -C "$P/b" fetch -q origin 2> /dev/null
add_phase "$P/b" 02 y
pull_in "$P/b" --no-rebase
"$GREP" -qF '[vf-divergence] DIVERGENCE' "$TMP/pull.err" || { ko "VDH-ARM-WORKTREE : la fusion divergente du worktree principal ne crie pas"; miss=1; }
add_phase "$WT" 02 z
WTRC=0; runb git -C "$WT" merge -q --no-edit origin/main > "$TMP/wt.out" 2> "$TMP/wt.err" < /dev/null || WTRC=$?
[ "$WTRC" -eq 0 ] || { ko "VDH-ARM-WORKTREE : la fusion dans le worktree lie a echoue (rc=$WTRC) — $(tail -3 "$TMP/wt.err")"; miss=1; }
"$GREP" -qF '[vf-divergence] DIVERGENCE' "$TMP/wt.err" || { ko "VDH-ARM-WORKTREE : la fusion divergente du worktree lie ne crie pas — $(tail -3 "$TMP/wt.err")"; miss=1; }
JW="$P/b/.git/vf-divergence/journal.tsv"
[ -f "$JW" ] && [ "$(nlines "$JW")" -eq 3 ] || { ko "VDH-ARM-WORKTREE : le journal commun n'a pas trois lignes (en-tete + une par fusion)"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-ARM-WORKTREE (P61-PL-02) : arm sur un worktree lie -> hooks dans le dossier commun ; fusion divergente criee et journalisee dans le worktree principal ET dans le lie, meme journal"

# ===========================================================================
# VDH-DISARM / VDH-DISARM-TIERS
# ===========================================================================
miss=0
mk_pair t11
arm_in "$P/b"
diverge "$P/a" "$P/b" 02
JD="$P/b/.git/vf-divergence/journal.tsv"
[ -f "$JD" ] || { ko "VDH-DISARM pre-condition : aucun journal"; miss=1; }
cksum < "$JD" > "$TMP/j.before"
hk disarm --path "$P/b"
[ "$HKRC" -eq 0 ] || { ko "VDH-DISARM : disarm rend $HKRC (attendu 0)"; miss=1; }
no_hook "$P/b" || { ko "VDH-DISARM : un hook nostre subsiste"; miss=1; }
cksum < "$JD" > "$TMP/j.after"
cmp -s "$TMP/j.before" "$TMP/j.after" || { ko "VDH-DISARM : le journal a ete modifie ou retire"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-DISARM : clone arme -> rc 0, les deux hooks retires, journal present et inchange (cksum)"

miss=0
mk_pair t12
arm_in "$P/b"
put_tiers "$P/b" post-merge
arm_in "$P/b"; LM="$(hand_of post-merge)"
put_tiers "$P/b" post-merge "$LM"
cp "$P/b/.git/hooks/post-merge" "$TMP/m.orig"
hk disarm --path "$P/b"
[ "$HKRC" -eq 1 ] || { ko "VDH-DISARM-TIERS : disarm rend $HKRC (attendu 1)"; miss=1; }
cmp -s "$P/b/.git/hooks/post-merge" "$TMP/m.orig" || { ko "VDH-DISARM-TIERS : le hook tiers a ete modifie ou retire"; miss=1; }
"$GREP" -qF 'LIGNE A RETIRER A LA MAIN (post-merge)' "$TMP/hk.err" || { ko "VDH-DISARM-TIERS : stderr sans la ligne a retirer a la main"; miss=1; }
[ ! -e "$P/b/.git/hooks/post-rewrite" ] || { ko "VDH-DISARM-TIERS : notre post-rewrite n'a pas ete retire"; miss=1; }
# Un tiers sans la ligne : ni touche ni signale en echec.
mk_pair t13
put_tiers "$P/b" post-merge
cp "$P/b/.git/hooks/post-merge" "$TMP/m.orig"
hk disarm --path "$P/b"
{ [ "$HKRC" -eq 0 ] && cmp -s "$P/b/.git/hooks/post-merge" "$TMP/m.orig"; } || { ko "VDH-DISARM-TIERS : un tiers sans ligne d'appel a ete touche (rc=$HKRC)"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-DISARM-TIERS (T-61-14) : tiers avec la ligne d'appel -> rc 1, intact, LIGNE A RETIRER A LA MAIN ; notre hook voisin retire ; tiers sans ligne intact rc 0"

# ===========================================================================
# VDH-STATUS
# ===========================================================================
miss=0
mk_pair t14
arm_in "$P/b"
diverge "$P/a" "$P/b" 02
hk status --path "$P/b"
[ "$HKRC" -eq 0 ] || { ko "VDH-STATUS : clone arme, rc=$HKRC (attendu 0)"; miss=1; }
{ "$GREP" -qxF 'HOOK post-merge ARME' "$TMP/hk.out" && "$GREP" -qxF 'HOOK post-rewrite ARME' "$TMP/hk.out"; } || { ko "VDH-STATUS : lignes « HOOK … ARME » absentes — $(cat "$TMP/hk.out")"; miss=1; }
"$GREP" -qxF "JOURNAL $P/b/.git/vf-divergence/journal.tsv lignes=1" "$TMP/hk.out" || { ko "VDH-STATUS : ligne JOURNAL fausse (attendu lignes=1) — $("$GREP" JOURNAL "$TMP/hk.out")"; miss=1; }
"$GREP" -qxF 'BILAN verbe=status code=0' "$TMP/hk.out" || { ko "VDH-STATUS : BILAN absent"; miss=1; }
hk disarm --path "$P/b"
hk status --path "$P/b"
{ [ "$HKRC" -eq 1 ] && "$GREP" -qxF 'HOOK post-merge ABSENT' "$TMP/hk.out"; } || { ko "VDH-STATUS : clone desarme, rc=$HKRC / ABSENT absent"; miss=1; }
put_tiers "$P/b" post-merge
hk status --path "$P/b"
{ [ "$HKRC" -eq 1 ] && "$GREP" -qxF 'HOOK post-merge TIERS' "$TMP/hk.out"; } || { ko "VDH-STATUS : hook tiers sans ligne, rc=$HKRC / TIERS absent"; miss=1; }
rm -f "$P/b/.git/hooks/post-merge"
put_tiers "$P/b" post-merge; put_tiers "$P/b" post-rewrite
arm_in "$P/b"; LM="$(hand_of post-merge)"; LR="$(hand_of post-rewrite)"
put_tiers "$P/b" post-merge "$LM"; put_tiers "$P/b" post-rewrite "$LR"
hk status --path "$P/b"
{ [ "$HKRC" -eq 0 ] && "$GREP" -qxF 'HOOK post-merge ARME-A-LA-MAIN' "$TMP/hk.out"; } || { ko "VDH-STATUS : armes a la main, rc=$HKRC / ARME-A-LA-MAIN absent"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-STATUS : arme -> rc 0 + deux HOOK ARME + JOURNAL lignes=1 ; desarme -> rc 1 ABSENT ; tiers -> rc 1 TIERS ; arme a la main -> rc 0"

# ===========================================================================
# VDH-NOGIT / VDH-USAGE
# ===========================================================================
miss=0
mkdir -p "$TMP/horsgit"
for v in "arm" "arm --check" "disarm" "status"; do
  HKDIR="$TMP/horsgit" hk $v
  [ "$HKRC" -eq 3 ] || { ko "VDH-NOGIT : « $v » hors depot git rend $HKRC (attendu 3)"; miss=1; }
done
[ "$miss" -eq 0 ] && ok "VDH-NOGIT : arm, arm --check, disarm et status hors depot git -> rc 3"

miss=0
for v in "bogus" "run --hook" "run --hook pre-push" "run" "arm --inconnu" "arm --path" "disarm --check" "status extra"; do
  hk $v
  [ "$HKRC" -eq 64 ] || { ko "VDH-USAGE : « $v » rend $HKRC (attendu 64)"; miss=1; }
  [ -s "$TMP/hk.err" ] || { ko "VDH-USAGE : « $v » sans message sur stderr"; miss=1; }
done
[ "$miss" -eq 0 ] && ok "VDH-USAGE : verbe inconnu, --hook sans valeur, hook inconnu, option inconnue -> rc 64 et message sur stderr"

# ===========================================================================
# Tache 3 : garde d'execution, journal blinde, non verifiable observe
# ===========================================================================
N=0
LASTMSG=""
# hand_hook <clone> <nom> <script> — hook ecrit a la main (sh) qui designe <script>.
hand_hook() {
  mkdir -p "$1/.git/hooks"
  printf '#!/bin/sh\nexec bash %s run --hook %s "$@"\n' "'$3'" "$2" > "$1/.git/hooks/$2"
  chmod 755 "$1/.git/hooks/$2"
}

# --- VDH-RUN-ARBRE : le fichier de hook designe une copie SOUS l'arbre ; son check-divergence.sh voisin est un piege
miss=0
mk_pair t20
mk_cache "$P/b/outils/cache" "$SCRIPT" || { ko "VDH-RUN-ARBRE pre-condition : copie sous l'arbre non construite"; miss=1; }
printf '#!/usr/bin/env bash\necho piege > "%s/piege"\nexit 1\n' "$TMP" > "$P/b/outils/cache/conductor/scripts/check-divergence.sh"
rm -f "$TMP/piege"
hand_hook "$P/b" post-merge "$P/b/outils/cache/conductor/scripts/vf-divergence-hook.sh"
diverge "$P/a" "$P/b" 02
[ "$PULLRC" -eq 0 ] || { ko "VDH-RUN-ARBRE : le pull a echoue (rc=$PULLRC)"; miss=1; }
"$GREP" -qF 'NON VERIFIABLE' "$TMP/pull.err" || { ko "VDH-RUN-ARBRE : stderr sans « NON VERIFIABLE » — $(tail -3 "$TMP/pull.err")"; miss=1; }
[ ! -e "$TMP/piege" ] || { ko "VDH-RUN-ARBRE : le check-divergence.sh de l'arbre A ETE EXECUTE (piege declenche)"; miss=1; }
JA="$P/b/.git/vf-divergence/journal.tsv"
{ [ -f "$JA" ] && [ "$(field "$JA" 2 7)" = "executable-dans-l-arbre" ] && [ "$(field "$JA" 2 3)" = "NON-VERIFIABLE" ]; } || { ko "VDH-RUN-ARBRE : ligne de journal sans la raison executable-dans-l-arbre"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-RUN-ARBRE (T-61-09, P61-PL-09) : hook designant une copie sous l'arbre -> NON VERIFIABLE, raison executable-dans-l-arbre au journal, le piege voisin n'est jamais execute"

# --- VDH-RUN-SILENCE : rien a dire -> rien dit, rien journalise
miss=0
mk_pair t21
arm_in "$P/a"
add_phase "$P/b" 02 n roadmap
git -C "$P/b" push -q origin main 2> /dev/null
pull_in "$P/a" --no-rebase
RC=0; bash "$TMP/cache/conductor/scripts/check-divergence.sh" --path "$P/a" > /dev/null 2>&1 < /dev/null || RC=$?
[ "$RC" -eq 0 ] || { ko "VDH-RUN-SILENCE pre-condition : l'arbre fusionne n'est pas conforme (rc=$RC)"; miss=1; }
if "$GREP" -qF '[vf-divergence]' "$TMP/pull.err"; then ko "VDH-RUN-SILENCE : fusion conforme et sortie [vf-divergence]"; miss=1; fi
[ ! -e "$P/a/.git/vf-divergence/journal.tsv" ] || { ko "VDH-RUN-SILENCE : fusion conforme et ligne de journal"; miss=1; }
# depot non partitionne : silence (code 3 de check-divergence)
P="$TMP/t22"; mkdir -p "$P"
git_init_bare "$P/origin.git"; git_init "$P/seed"; ident "$P/seed"
printf 'x\n' > "$P/seed/f.txt"; git -C "$P/seed" add f.txt; git -C "$P/seed" commit -q -m seed
git -C "$P/seed" remote add origin "$P/origin.git"; git -C "$P/seed" push -q origin main 2> /dev/null
git clone -q "$P/origin.git" "$P/a" 2> /dev/null; ident "$P/a"; git clone -q "$P/origin.git" "$P/b" 2> /dev/null; ident "$P/b"
arm_in "$P/b"
printf 'y\n' > "$P/a/g.txt"; git -C "$P/a" add g.txt; git -C "$P/a" commit -q -m g; git -C "$P/a" push -q origin main 2> /dev/null
pull_in "$P/b" --no-rebase
RC=0; bash "$TMP/cache/conductor/scripts/check-divergence.sh" --path "$P/b" > /dev/null 2>&1 < /dev/null || RC=$?
[ "$RC" -eq 3 ] || { ko "VDH-RUN-SILENCE pre-condition : depot non partitionne, check-divergence rc=$RC (attendu 3)"; miss=1; }
if "$GREP" -qF '[vf-divergence]' "$TMP/pull.err"; then ko "VDH-RUN-SILENCE : depot non partitionne et sortie [vf-divergence]"; miss=1; fi
[ ! -e "$P/b/.git/vf-divergence/journal.tsv" ] || { ko "VDH-RUN-SILENCE : depot non partitionne et ligne de journal"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-RUN-SILENCE : fusion conforme puis depot non partitionne -> aucune sortie [vf-divergence], aucun journal"

# --- VDH-RUN-NV : politique de compartiment introuvable -> check-divergence rend 2 -> NON VERIFIABLE journalise
mk_nopol() { # <dossier> — cache prive sans planning-core (check-divergence rend 2 sur un depot partitionne)
  mkdir -p "$1/conductor/scripts" && cp "$TARGET" "$1/conductor/scripts/vf-divergence-hook.sh" && cp "$CONDUCTOR_DIR/check-divergence.sh" "$1/conductor/scripts/check-divergence.sh"
}
probe_nv() {
  mk_pair "p$((++N))"
  mk_nopol "$TMP/nopol$N" || { LASTMSG="cache prive non construit"; return 1; }
  local save="$TARGET"; TARGET="$TMP/nopol$N/conductor/scripts/vf-divergence-hook.sh"
  arm_in "$P/b"; local arc="$HKRC"
  TARGET="$save"
  [ "$arc" -eq 0 ] || { LASTMSG="arm depuis le cache prive rc=$arc"; return 1; }
  diverge "$P/a" "$P/b" 02
  "$GREP" -qF '[vf-divergence] NON VERIFIABLE (code 2)' "$TMP/pull.err" || { LASTMSG="stderr sans « NON VERIFIABLE (code 2) » (silence : lu comme un conforme) — $(tail -2 "$TMP/pull.err")"; return 1; }
  local j="$P/b/.git/vf-divergence/journal.tsv"
  { [ -f "$j" ] && [ "$(field "$j" 2 3)" = "NON-VERIFIABLE" ] && [ "$(field "$j" 2 7)" = "code-2" ]; } || { LASTMSG="ligne de journal NON-VERIFIABLE / code-2 absente"; return 1; }
  return 0
}
case_() { # <id> <sonde> <description>
  if "$2" < /dev/null; then ok "$1 $3"; else ko "$1 — $LASTMSG"; fi
}
case_ VDH-RUN-NV probe_nv "(T-61-09, P61-PL-10) : check-divergence rend 2 -> « NON VERIFIABLE (code 2) » sur stderr + ligne de journal raison code-2"
# run direct : codes 0 / 1 / 2
miss=0
mk_pair t23
HKDIR="$P/a" hk run --hook post-merge
{ [ "$HKRC" -eq 0 ] && ! "$GREP" -qF '[vf-divergence]' "$TMP/hk.err"; } || { ko "VDH-RUN-NV : run direct sur un clone conforme rend $HKRC (attendu 0, aucune sortie [vf-divergence])"; miss=1; }
HKDIR="$P/a" hk run --hook post-rewrite amend
{ [ "$HKRC" -eq 0 ] && [ ! -s "$TMP/hk.err" ]; } || { ko "VDH-RUN-NV : run --hook post-rewrite amend rend $HKRC (attendu 0, silence)"; miss=1; }
diverge "$P/a" "$P/b" 02
HKDIR="$P/b" hk run --hook post-merge
{ [ "$HKRC" -eq 1 ] && "$GREP" -qF '[vf-divergence] DIVERGENCE' "$TMP/hk.err"; } || { ko "VDH-RUN-NV : run direct sur un clone divergent rend $HKRC (attendu 1 + cri)"; miss=1; }
HKDIR="$TMP/horsgit" hk run --hook post-merge
{ [ "$HKRC" -eq 2 ] && "$GREP" -qF 'NON VERIFIABLE' "$TMP/hk.err"; } || { ko "VDH-RUN-NV : run hors depot git rend $HKRC (attendu 2 + NON VERIFIABLE)"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-RUN-NV : run direct -> 0 silencieux (conforme, amend), 1 criant (divergent), 2 NON VERIFIABLE (hors depot)"

# --- VDH-INTROUVABLE : script supprime du cache apres l'armement -> repli du fichier de hook
miss=0
mk_pair t24
mk_cache "$TMP/cache-ephemere" "$SCRIPT"
SAVE_TARGET="$TARGET"; TARGET="$TMP/cache-ephemere/conductor/scripts/vf-divergence-hook.sh"
arm_in "$P/b"; [ "$HKRC" -eq 0 ] || { ko "VDH-INTROUVABLE pre-condition : arm rc=$HKRC"; miss=1; }
TARGET="$SAVE_TARGET"
rm -rf "$TMP/cache-ephemere"
diverge "$P/a" "$P/b" 02
[ "$PULLRC" -eq 0 ] || { ko "VDH-INTROUVABLE : le pull a echoue (rc=$PULLRC)"; miss=1; }
"$GREP" -qF '[vf-divergence] NON VERIFIABLE' "$TMP/pull.err" || { ko "VDH-INTROUVABLE : stderr sans « NON VERIFIABLE »"; miss=1; }
JI="$P/b/.git/vf-divergence/journal.tsv"
{ [ -f "$JI" ] && [ "$(field "$JI" 2 7)" = "introuvable" ] && [ "$(field "$JI" 2 2)" = "post-merge" ]; } || { ko "VDH-INTROUVABLE : ligne de journal de raison introuvable absente"; miss=1; }
# meme repli, journal remplace par un lien : jamais suivi
mk_pair t25
mk_cache "$TMP/cache-ephemere" "$SCRIPT"
SAVE_TARGET="$TARGET"; TARGET="$TMP/cache-ephemere/conductor/scripts/vf-divergence-hook.sh"
arm_in "$P/b"; TARGET="$SAVE_TARGET"
rm -rf "$TMP/cache-ephemere"
mkdir -p "$P/b/.git/vf-divergence"; printf 'X\n' > "$P/cible"; cp "$P/cible" "$TMP/cible.orig"
ln -s "$P/cible" "$P/b/.git/vf-divergence/journal.tsv"
diverge "$P/a" "$P/b" 02
"$GREP" -qF 'JOURNAL NON ECRIT : lien' "$TMP/pull.err" || { ko "VDH-INTROUVABLE : le repli du hook ne refuse pas un journal lien symbolique"; miss=1; }
cmp -s "$P/cible" "$TMP/cible.orig" || { ko "VDH-INTROUVABLE : le repli du hook a ecrit a travers le lien symbolique"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-INTROUVABLE (P61-D-03) : cache supprime -> NON VERIFIABLE + ligne « introuvable » ; repli : journal lien symbolique jamais suivi"

# --- VDH-JOURNAL-LIEN : lien, FIFO, dossier, dossier lien : jamais ouverts, verdict inchange
jl_variant() { # <kind> — pose le journal piege, joue une fusion divergente
  mk_pair "jl$((++N))"
  arm_in "$P/b"
  mkdir -p "$P/b/.git/vf-divergence"
  case "$1" in
    lien) printf 'X\n' > "$P/cible"; cp "$P/cible" "$TMP/cible.orig"; ln -s "$P/cible" "$P/b/.git/vf-divergence/journal.tsv" ;;
    fifo) mkfifo "$P/b/.git/vf-divergence/journal.tsv" ;;
    dir) mkdir "$P/b/.git/vf-divergence/journal.tsv" ;;
    dlien) rmdir "$P/b/.git/vf-divergence"; mkdir "$P/dest"; ln -s "$P/dest" "$P/b/.git/vf-divergence" ;;
  esac
  diverge "$P/a" "$P/b" 02
}
probe_lien() {
  jl_variant lien
  [ "$PULLRC" -eq 0 ] || { LASTMSG="le pull a echoue (rc=$PULLRC)"; return 1; }
  cmp -s "$P/cible" "$TMP/cible.orig" || { LASTMSG="la cible du lien symbolique a ete ecrite"; return 1; }
  "$GREP" -qF '[vf-divergence] JOURNAL NON ECRIT : lien' "$TMP/pull.err" || { LASTMSG="stderr sans « JOURNAL NON ECRIT : lien »"; return 1; }
  "$GREP" -qF '[vf-divergence] DIVERGENCE' "$TMP/pull.err" || { LASTMSG="le verdict n'est plus crie"; return 1; }
  return 0
}
probe_jl_autres() {
  if ! command -v mkfifo > /dev/null 2>&1; then return 0; fi
  jl_variant fifo
  [ "$PULLRC" -eq 0 ] || { LASTMSG="FIFO : le pull n'a pas abouti (rc=$PULLRC, 142 = alarme : bloque sur la FIFO)"; return 1; }
  "$GREP" -qF 'JOURNAL NON ECRIT : fifo' "$TMP/pull.err" || { LASTMSG="FIFO : stderr sans « JOURNAL NON ECRIT : fifo »"; return 1; }
  "$GREP" -qF '[vf-divergence] DIVERGENCE' "$TMP/pull.err" || { LASTMSG="FIFO : verdict non crie"; return 1; }
  jl_variant dir
  { [ "$PULLRC" -eq 0 ] && "$GREP" -qF 'JOURNAL NON ECRIT : non-regulier' "$TMP/pull.err"; } || { LASTMSG="journal-dossier : pas de « JOURNAL NON ECRIT : non-regulier »"; return 1; }
  [ "$(ls -A "$P/b/.git/vf-divergence/journal.tsv" | awk 'END { print NR }')" -eq 0 ] || { LASTMSG="journal-dossier : le dossier a recu un fichier"; return 1; }
  jl_variant dlien
  { [ "$PULLRC" -eq 0 ] && "$GREP" -qF 'JOURNAL NON ECRIT : dossier-lien' "$TMP/pull.err"; } || { LASTMSG="dossier lien : pas de « JOURNAL NON ECRIT : dossier-lien »"; return 1; }
  [ "$(ls -A "$P/dest" | awk 'END { print NR }')" -eq 0 ] || { LASTMSG="dossier lien : la cible du lien a recu un fichier"; return 1; }
  return 0
}
case_ VDH-JOURNAL-LIEN probe_lien "(T-61-12) : journal lien symbolique -> cible intacte, « JOURNAL NON ECRIT : lien », verdict toujours crie"
case_ VDH-JOURNAL-LIEN-AUTRES probe_jl_autres "(T-61-12) : FIFO (pull abouti, sous l'alarme), journal dossier, dossier lien -> « JOURNAL NON ECRIT », rien d'ecrit, verdict crie"

# --- VDH-CODES : codes observes sur l'ensemble des appels directs
miss=0
RUNCODES="$(awk '$1=="run" { print $2 }' "$TMP/rcs" | sort -u | awk '{ printf "%s%s", (NR>1 ? " " : ""), $1 }')"
ARMCODES="$(awk '$1=="arm" { print $2 }' "$TMP/rcs" | sort -u | awk '{ printf "%s%s", (NR>1 ? " " : ""), $1 }')"
[ "$RUNCODES" = "0 1 2 64" ] || { ko "VDH-CODES : codes de run observes « $RUNCODES » (attendu « 0 1 2 64 »)"; miss=1; }
[ "$ARMCODES" = "0 1 2 3 64" ] || { ko "VDH-CODES : codes de arm observes « $ARMCODES » (attendu « 0 1 2 3 64 »)"; miss=1; }
[ "$miss" -eq 0 ] && ok "VDH-CODES (QUAL-01) : run observe {0, 1, 2, 64}, arm observe {0, 1, 2, 3, 64} — trois issues plus l'indetermine"

# ===========================================================================
# Sondes des mutants (chacune rend 0 sur l'original, non nul sur le mutant)
# ===========================================================================
probe_trace() { # M1
  mk_pair "p$((++N))"; arm_in "$P/b"; [ "$HKRC" -eq 0 ] || { LASTMSG="arm rc=$HKRC"; return 1; }
  diverge "$P/a" "$P/b" 02
  "$GREP" -qF '[vf-divergence] DIVERGENCE' "$TMP/pull.err" || { LASTMSG="divergence non criee (silence sur le code 1)"; return 1; }
  return 0
}
probe_journal() { # M2
  mk_pair "p$((++N))"; arm_in "$P/b"
  diverge "$P/a" "$P/b" 02
  local j="$P/b/.git/vf-divergence/journal.tsv" n=0
  [ -f "$j" ] && n="$(nlines "$j")"
  [ "$n" -eq 2 ] || { LASTMSG="journal: $n lignes (attendu 2)"; return 1; }
  return 0
}
probe_tiers() { # M4
  mk_pair "p$((++N))"; put_tiers "$P/b" post-rewrite
  arm_in "$P/b"
  { [ "$HKRC" -eq 1 ] && [ ! -e "$P/b/.git/hooks/post-merge" ]; } || { LASTMSG="arm rc=$HKRC (attendu 1), post-merge ecrit=$([ -e "$P/b/.git/hooks/post-merge" ] && echo oui || echo non)"; return 1; }
  return 0
}
probe_disarm_tiers() { # M5
  mk_pair "p$((++N))"
  local lm="bash '$TARGET' run --hook post-merge \"\$@\""
  put_tiers "$P/b" post-merge "$lm"; cp "$P/b/.git/hooks/post-merge" "$TMP/m.probe"
  hk disarm --path "$P/b"
  { [ "$HKRC" -eq 1 ] && cmp -s "$P/b/.git/hooks/post-merge" "$TMP/m.probe"; } || { LASTMSG="disarm rc=$HKRC (attendu 1), tiers intact=$(cmp -s "$P/b/.git/hooks/post-merge" "$TMP/m.probe" 2>/dev/null && echo oui || echo non)"; return 1; }
  return 0
}
probe_hooksp() { # M6
  mk_pair "p$((++N))"; mkdir -p "$P/b/husky"; git -C "$P/b" config core.hooksPath "$P/b/husky"
  arm_in "$P/b"
  { [ "$HKRC" -eq 1 ] && [ "$(ls -A "$P/b/husky" | awk 'END { print NR }')" -eq 0 ]; } || { LASTMSG="arm rc=$HKRC (attendu 1), husky contient $(ls -A "$P/b/husky" | awk 'END { print NR }') fichier(s)"; return 1; }
  return 0
}
probe_arbre() { # M7
  mk_pair "p$((++N))"; mk_cache "$P/b/outils/cache" "$TARGET"
  local save="$TARGET"; TARGET="$P/b/outils/cache/conductor/scripts/vf-divergence-hook.sh"
  arm_in "$P/b"; TARGET="$save"
  { [ "$HKRC" -eq 1 ] && no_hook "$P/b"; } || { LASTMSG="arm depuis l'arbre rc=$HKRC (attendu 1), hook ecrit=$(no_hook "$P/b" && echo non || echo oui)"; return 1; }
  return 0
}
probe_run_arbre() { # M8
  mk_pair "p$((++N))"; mk_cache "$P/b/outils/cache" "$TARGET"
  printf '#!/usr/bin/env bash\necho piege > "%s/piege"\nexit 1\n' "$TMP" > "$P/b/outils/cache/conductor/scripts/check-divergence.sh"
  rm -f "$TMP/piege"
  hand_hook "$P/b" post-merge "$P/b/outils/cache/conductor/scripts/vf-divergence-hook.sh"
  diverge "$P/a" "$P/b" 02
  [ ! -e "$TMP/piege" ] || { LASTMSG="le check-divergence.sh de l'arbre a ete execute (piege declenche)"; return 1; }
  return 0
}
probe_rewrite() { # M9
  mk_pair "p$((++N))"; arm_in "$P/b"
  add_phase "$P/b" 03 p; add_phase "$P/a" 03 q roadmap; git -C "$P/a" push -q origin main 2> /dev/null
  pull_in "$P/b" --rebase
  "$GREP" -qF 'DIVERGENCE apres post-rewrite' "$TMP/pull.err" || { LASTMSG="pull --rebase non crie (echappe au filet)"; return 1; }
  return 0
}
probe_amend() { # M10
  mk_pair "p$((++N))"; arm_in "$P/b"
  add_phase "$P/b" 02 x roadmap; add_phase "$P/b" 02 y
  runb git -C "$P/b" commit -q --amend --no-edit > /dev/null 2> "$TMP/amend.err" < /dev/null || :
  if "$GREP" -qF '[vf-divergence]' "$TMP/amend.err"; then LASTMSG="le amend a produit une sortie [vf-divergence]"; return 1; fi
  return 0
}
probe_quote() { # M11
  mk_pair "p$((++N))"; mk_cache "$TMP/o'q$N/cache" "$TARGET"
  local save="$TARGET"; TARGET="$TMP/o'q$N/cache/conductor/scripts/vf-divergence-hook.sh"
  arm_in "$P/b"; TARGET="$save"
  { [ "$HKRC" -eq 2 ] && no_hook "$P/b"; } || { LASTMSG="arm depuis un chemin a apostrophe rc=$HKRC (attendu 2), hook ecrit=$(no_hook "$P/b" && echo non || echo oui)"; return 1; }
  return 0
}

# ===========================================================================
# Mutants (QUAL-01) : une ligne altree chacun, cmp -s different, bash -n valide, sonde rouge sur le mutant
# puis verte sur l'original.
# ===========================================================================
MUTDIR="$TMP/mut"
mk_cache "$MUTDIR" "$SCRIPT" || { ko "mutants pre-condition : copie de travail non construite"; MUTDIR=""; }
MUTBIN="$MUTDIR/conductor/scripts/vf-divergence-hook.sh"
ORIG_TARGET="$TARGET"

# mutant <id> <ligne repere> <ancien> <nouveau> <sonde> <description> : dans la SEULE ligne qui contient le repere,
# remplace la premiere occurrence litterale de <ancien> par <nouveau> (chaines passees par l'environnement).
mutant() {
  local id="$1" needle="$2" old="$3" new="$4" probe="$5" desc="$6"
  [ -n "$MUTDIR" ] || { ko "$id mutants indisponibles"; return; }
  if ! declare -F "$probe" > /dev/null; then ko "$id sonde $probe NON DEFINIE — $desc"; return; fi
  NEEDLE="$needle" OLD="$old" NEW="$new" awk 'BEGIN { n = ENVIRON["NEEDLE"]; o = ENVIRON["OLD"]; w = ENVIRON["NEW"] }
    { if (index($0, n)) { i = index($0, o); if (i) $0 = substr($0, 1, i - 1) w substr($0, i + length(o)) } print }' \
    "$SCRIPT" > "$MUTBIN"
  if cmp -s "$MUTBIN" "$SCRIPT"; then ko "$id mutant NON OPPOSABLE (copie identique a l'original) — $desc"; return; fi
  if ! bash -n "$MUTBIN" 2> /dev/null; then ko "$id mutant invalide (bash -n) — $desc"; return; fi
  local nl; nl="$(awk 'NR==FNR { a[FNR] = $0; next } a[FNR] != $0 { n++ } END { print n + 0 }' "$SCRIPT" "$MUTBIN")"
  if [ "$nl" != 1 ]; then ko "$id mutant mal cible ($nl lignes changees au lieu de 1) — $desc"; return; fi
  TARGET="$MUTBIN"; LASTMSG=""; "$probe" < /dev/null; local mrc=$?; local mmsg="$LASTMSG"
  TARGET="$ORIG_TARGET"; LASTMSG=""; "$probe" < /dev/null; local orc=$?
  if [ "$mrc" -ne 0 ] && [ "$orc" -eq 0 ]; then
    ok "$id tue ($desc) — sur le mutant : $mmsg"
  elif [ "$mrc" -eq 0 ]; then
    ko "$id mutant SURVIVANT ($desc) — la sonde ${probe#probe_} reste verte sur le mutant"
  else
    ko "$id original rouge apres mutation ($desc) — $LASTMSG"
  fi
  TARGET="$ORIG_TARGET"
}

mutant VDH-MUT-1 'DIVERGENCE apres $hook' 'say "' ': "' probe_trace \
  "code 1 rendu silencieux : la divergence n'est plus criee"
mutant VDH-MUT-2 "printf '# vf-divergence journal v1" '>> "$f"' '> /dev/null' probe_journal \
  "ecriture du journal neutralisee"
mutant VDH-MUT-3 '    0|3)' '0|3)' '0|2|3)' probe_nv \
  "code inattendu rendu silencieux (NON VERIFIABLE avale)"
mutant VDH-MUT-4 '[ "$refused" -eq 0 ] ||' '|| refus_fin' '|| :' probe_tiers \
  "refus du hook tiers retire"
mutant VDH-MUT-5 '"$MARKER"*) return 0 ;;' '"$MARKER"*)' '*)' probe_disarm_tiers \
  "test du marqueur retire : disarm retire un hook tiers"
mutant VDH-MUT-6 '0) [ -n "$v" ] && return 0; return 1 ;;' 'return 0' 'return 1' probe_hooksp \
  "refus core.hooksPath retire (valeur lue puis ignoree)"
mutant VDH-MUT-7 'in_tree() {' '"$2"/*) return 0' '"$2"/*) return 1' probe_arbre \
  "refus du script sous l'arbre retire a l'armement"
mutant VDH-MUT-8 'if in_tree "$SELF_DIR" "$rootp"; then' 'in_tree "$SELF_DIR" "$rootp"' 'false' probe_run_arbre \
  "garde d'execution hors de l'arbre retiree"
mutant VDH-MUT-9 '[ "${1:-}" = "rebase" ] || exit 0 ;;' '"rebase"' '"xrebase"' probe_rewrite \
  "argument rebase ignore : pull --rebase echappe de nouveau au filet"
mutant VDH-MUT-10 '[ "${1:-}" = "rebase" ] || exit 0 ;;' '|| exit 0' '|| :' probe_amend \
  "amend non filtre : le amend est juge comme un rebase"
mutant VDH-MUT-11 '*[[:cntrl:]]*) return 1 ;;' 'return 1' 'return 0' probe_quote \
  "controle du chemin non sur retire : un chemin a apostrophe est embarque dans le hook"
mutant VDH-MUT-12 "printf 'lien'" '[ -L "$f" ]' 'false' probe_lien \
  "lien symbolique du journal suivi"
TARGET="$ORIG_TARGET"

# ===========================================================================
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
