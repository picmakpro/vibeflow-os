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
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
