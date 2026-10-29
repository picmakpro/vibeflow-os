#!/usr/bin/env bash
# test-divergence-deux-clones.sh — Preuve de mecanisme du filet de divergence arme (Phase 61, plan 61-01).
#
# Deux (ou plus) clones jetables d'un meme depot partitionne, sur la meme machine : chaque clone est
# arme PAR LE VRAI CHEMIN D'INSTALLATION (`vibeflow-update.sh install`, scope project, poste product
# ou dev), la numerotation d'un compartiment est rendue divergente, la fusion est un vrai
# `git pull --no-rebase`, et la suite constate : hook declenche, divergence criee, ligne de journal.
#
# Cas de CE plan (61-01) :
#   D2C-TRACE            tracer : install poste dev -> pull divergent -> cri + une ligne de journal
#   D2C-TRACE-SOLO       sans poste ou au poste solo : aucun hook, aucun dossier de journal, aucun
#                        core.hooksPath (critere 2 du jalon)
#   D2C-TRACE-TIERS      un post-merge tiers n'est ni ecrase ni modifie : armement refuse en code 1,
#                        installation aboutie (code 0), le hook tiers fonctionne toujours
#   D2C-TRACE-INTROUVABLE  script du cache disparu : NON VERIFIABLE audible et journalise
# Cas du plan 61-05 (preuve complete) :
#   D2C-FF               la fusion de l'autre humain, poussee puis recue en AVANCE RAPIDE au pull suivant,
#                        est criee (post-merge) et journalisee avec le HEAD du clone qui tire
#   D2C-REBASE           `git pull --rebase` avec commit local : seul post-rewrite se declenche ; monde frais
#                        et conforme avant la divergence ; champ 2 du journal = post-rewrite
# Cas du plan 61-05 a suivre dans ce fichier (silence, worktree, branche piegee,
# trois temoins rouges, releve de la recette).
# Sonde de la preuve : `sonde_cri` (cri sur stderr ET exactement une ligne de journal DIVERGENCE portant le HEAD
# du clone). Chaque monde frais est arme PAR L'INSTALL (`monde`), jamais par un appel direct a `arm`.
#
# ISOLATION (P61-PL-18) : HOME jetable, GIT_CONFIG_NOSYSTEM, GIT_CONFIG_GLOBAL vers un fichier vide,
# XDG_CONFIG_HOME et VF_DIVERGENCE_HOOK retires, identite git posee dans chaque clone, caches HORS
# des clones. Fixtures generees a l'execution (compartiment `w1`, phases `x` et `y`).
# Comptages de lignes par awk, contenus exacts par cmp -s, jamais diff.
# Convention : ok()/ko(), exit 0 si tout passe, exit 1 au moindre KO.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }
GREP="$(command -v grep)"
TAB="$(printf '\t')"

# PYTHONUSERBASE exporte AVANT de changer HOME : un site-packages utilisateur ne doit pas migrer avec lui.
PYTHONUSERBASE="${PYTHONUSERBASE:-$HOME/.local}"; export PYTHONUSERBASE

echo "== test-divergence-deux-clones (engine: $INSTALLER) =="

WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT
FH="$WORK/home"; mkdir -p "$FH"
: > "$WORK/gitconfig"
unset XDG_CONFIG_HOME VF_DIVERGENCE_HOOK VF_ROLE VF_SCOPE VF_TARGET GSD_WORKSTREAM VF_WORKSTREAM VF_WORKSTREAM_PLANNING_DIR
export HOME="$FH" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_TERMINAL_PROMPT=0

nlines() { awk 'END { print NR }' "$1"; }
# field <fichier> <ligne> <n> — champ n (tabulation) de la ligne donnee.
field() { awk -F "$TAB" -v l="$2" -v n="$3" 'NR==l { print $n; exit }' "$1"; }
# ligne2 <fichier> — deuxieme ligne du fichier.
ligne2() { awk 'NR==2 { print; exit }' "$1"; }

git_init() { # <dir> — depot a branche main
  git init -q -b main "$1" >/dev/null 2>&1 || { git init -q "$1" >/dev/null 2>&1 && git -C "$1" symbolic-ref HEAD refs/heads/main; }
}
git_init_bare() { # <dir>
  git init -q --bare -b main "$1" >/dev/null 2>&1 || { git init -q --bare "$1" >/dev/null 2>&1 && git --git-dir="$1" symbolic-ref HEAD refs/heads/main; }
}
ident() { git -C "$1" config user.email "test@example.invalid"; git -C "$1" config user.name "test"; }

# mk_cache <dir> — cache de plugin de test : conductor, planning-core, validator, et la bibliotheque portable.
mk_cache() {
  local m
  for m in conductor planning-core validator; do
    mkdir -p "$1/$m" && cp -R "$REPO/$m/." "$1/$m/" || return 1
  done
  mkdir -p "$1/_internal/lib" && cp "$INTERNAL_DIR/lib/vf-portable.sh" "$1/_internal/lib/" || return 1
}

# inst <clone> <cache> [VAR=val ...] -- <args engine...> — sorties dans $WORK/out et $WORK/err.
inst() {
  local clone="$1" cache="$2"; shift 2
  local envs=()
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  shift
  local rc=0
  (cd "$clone" && env -u VF_ROLE -u VF_SCOPE -u VF_TARGET -u XDG_CONFIG_HOME -u VF_DIVERGENCE_HOOK \
     HOME="$FH" VF_RUNTIME=claude VIBEFLOW_CACHE="$cache" \
     ${envs[@]+"${envs[@]}"} "${BASH:-bash}" "$INSTALLER" "$@") > "$WORK/out" 2> "$WORK/err" || rc=$?
  return "$rc"
}

# local_commit <clone> <suffixe> — ajoute le dossier de phase 02-<suffixe> au compartiment w1 et commite.
local_commit() {
  mkdir -p "$1/.planning/workstreams/w1/phases/02-$2"
  printf 'phase 2 %s\n' "$2" > "$1/.planning/workstreams/w1/phases/02-$2/02-CONTEXT.md"
  git -C "$1" add -- .planning
  git -C "$1" commit -q -m "phase 2 $2"
}

# pull_divergent <clone> — vrai `git pull --no-rebase` ; stderr dans $WORK/pull.err.
pull_divergent() {
  git -C "$1" pull -q --no-rebase --no-edit > "$WORK/pull.out" 2> "$WORK/pull.err"
}

# jfile <clone> — journal du clone (dossier git COMMUN : identique depuis un worktree lie).
jfile() {
  local c
  c="$(git -C "$1" rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$c" in /*|[A-Za-z]:*) : ;; *) c="$1/$c" ;; esac
  printf '%s/vf-divergence/journal.tsv' "$c"
}
# jdata <clone> — lignes de DONNEES du journal (en-tete exclu) ; 0 si le journal n'existe pas.
jdata() {
  local jf
  jf="$(jfile "$1")" || { printf '0'; return 0; }
  [ -f "$jf" ] || { printf '0'; return 0; }
  awk 'NR > 1 { n++ } END { print n + 0 }' "$jf"
}

# sonde_cri <clone> <fichier stderr> <lignes de journal avant> — la sonde de la preuve (P61-D-08).
# 0 si stderr contient `[vf-divergence] DIVERGENCE` ET si le journal a gagne EXACTEMENT une ligne, de verdict
# DIVERGENCE et dont le HEAD est celui du clone ; non nul sinon, avec SONDE_WHY qui dit laquelle des trois
# conditions manque. Un temoin ne rougit que par cette fonction : elle ne lit rien d'autre.
sonde_cri() {
  local clone="$1" err="$2" avant="$3" jf apres head last
  SONDE_WHY=""
  if ! "$GREP" -qF '[vf-divergence] DIVERGENCE' "$err"; then SONDE_WHY="cri absent de stderr"; return 1; fi
  jf="$(jfile "$clone")" || { SONDE_WHY="journal introuvable"; return 1; }
  apres="$(jdata "$clone")"
  if [ "$apres" -ne $((avant + 1)) ]; then SONDE_WHY="journal muet ou bavard : $((apres - avant)) ligne(s) gagnee(s), attendu 1"; return 1; fi
  head="$(git -C "$clone" rev-parse HEAD)"
  last="$(awk -F "$TAB" -v n=$((apres + 1)) 'NR == n { print $3 "|" $5; exit }' "$jf")"
  if [ "$last" != "DIVERGENCE|$head" ]; then SONDE_WHY="derniere ligne du journal « $last » (attendu DIVERGENCE|$head)"; return 1; fi
  return 0
}

if ! mk_cache "$WORK/cache"; then
  echo "  ⊘ SKIP conductor/planning-core/validator non copiables dans le cache de test"
  exit 0
fi

# ---------------------------------------------------------------------------
# Depot d'origine partitionne : un compartiment `w1`, une phase 1, conforme.
# ---------------------------------------------------------------------------
git_init_bare "$WORK/origin.git"
git_init "$WORK/seed"; ident "$WORK/seed"
mkdir -p "$WORK/seed/.planning/workstreams/w1/phases/01-a"
printf '### Phase 1: a\n' > "$WORK/seed/.planning/workstreams/w1/ROADMAP.md"
printf -- '---\nprogress:\n  completed_phases: 1\n---\n' > "$WORK/seed/.planning/workstreams/w1/STATE.md"
printf 'phase 1\n' > "$WORK/seed/.planning/workstreams/w1/phases/01-a/01-CONTEXT.md"
git -C "$WORK/seed" add -- .planning
git -C "$WORK/seed" commit -q -m "seed"
git -C "$WORK/seed" remote add origin "$WORK/origin.git"
git -C "$WORK/seed" push -q origin main 2>/dev/null

CD="$WORK/cache/conductor/scripts/check-divergence.sh"
RC=0; bash "$CD" --path "$WORK/seed" >/dev/null 2>&1 </dev/null || RC=$?
if [ "$RC" -ne 0 ]; then
  ko "pre-condition : le depot d'origine n'est pas conforme (check-divergence rc=$RC) — la suite ne prouverait rien"
fi

for n in A B C D E G; do
  git clone -q "$WORK/origin.git" "$WORK/$n" 2>/dev/null; ident "$WORK/$n"
done

# Temoin : la liste du dossier de hooks d'un depot neuf (modeles de git comprises).
git_init "$WORK/temoin"
ls -1 "$WORK/temoin/.git/hooks" > "$WORK/hooks.temoin"

# ---------------------------------------------------------------------------
# D2C-TRACE — A (product) et B (dev) armes par l'install ; A pousse la phase 2-x, B commite la 2-y et tire.
# ---------------------------------------------------------------------------
miss=0
inst "$WORK/A" "$WORK/cache" VF_ROLE=product VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE pre-condition : install A rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
inst "$WORK/B" "$WORK/cache" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE pre-condition : install B rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }

HB="$WORK/B/.git/hooks/post-merge"
[ -f "$HB" ] || { ko "D2C-TRACE : l'install au poste dev n'a pas pose de post-merge dans B"; miss=1; }
case "$(ligne2 "$HB" 2>/dev/null)" in
  "# vibeflow:vf-divergence-hook v1"*) : ;;
  *) ko "D2C-TRACE : ligne 2 du post-merge de B ≠ marqueur « # vibeflow:vf-divergence-hook v1 »"; miss=1 ;;
esac
[ -x "$HB" ] || { ko "D2C-TRACE : le post-merge de B n'est pas executable"; miss=1; }

# A pousse la phase 2-x (dossier + en-tete au ROADMAP du compartiment).
mkdir -p "$WORK/A/.planning/workstreams/w1/phases/02-x"
printf 'phase 2 x\n' > "$WORK/A/.planning/workstreams/w1/phases/02-x/02-CONTEXT.md"
printf '### Phase 2: x\n' >> "$WORK/A/.planning/workstreams/w1/ROADMAP.md"
git -C "$WORK/A" add -- .planning
git -C "$WORK/A" commit -q -m "phase 2 x"
git -C "$WORK/A" push -q origin main 2>/dev/null || { ko "D2C-TRACE pre-condition : push de A refuse"; miss=1; }

# B commite sa propre phase 2 (numero identique, nom different) puis tire pour de vrai.
local_commit "$WORK/B" y
pull_divergent "$WORK/B"; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE : le pull de B a echoue (rc=$RC) — un post-merge ne doit jamais l'annuler"; miss=1; }
"$GREP" -qF '[vf-divergence] DIVERGENCE' "$WORK/pull.err" || { ko "D2C-TRACE : stderr du pull sans « [vf-divergence] DIVERGENCE » — $(tail -3 "$WORK/pull.err")"; miss=1; }

JB="$WORK/B/.git/vf-divergence/journal.tsv"
if [ -f "$JB" ]; then
  [ "$(nlines "$JB")" -eq 2 ] || { ko "D2C-TRACE : le journal de B n'a pas exactement 2 lignes ($(nlines "$JB"))"; miss=1; }
  [ "$(field "$JB" 2 1 | awk '/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/ { n++ } END { print n+0 }')" -eq 1 ] \
    || { ko "D2C-TRACE : champ 1 du journal ≠ date UTC AAAA-MM-JJTHH:MM:SSZ"; miss=1; }
  [ "$(awk -F "$TAB" 'NR==2 { print NF }' "$JB")" -eq 7 ] || { ko "D2C-TRACE : la ligne de journal n'a pas 7 champs"; miss=1; }
  [ "$(field "$JB" 2 2)" = "post-merge" ] || { ko "D2C-TRACE : champ 2 ≠ post-merge"; miss=1; }
  [ "$(field "$JB" 2 3)" = "DIVERGENCE" ] || { ko "D2C-TRACE : champ 3 ≠ DIVERGENCE"; miss=1; }
  [ "$(field "$JB" 2 4)" = "1" ] || { ko "D2C-TRACE : champ 4 ≠ 1"; miss=1; }
  [ "$(field "$JB" 2 5)" = "$(git -C "$WORK/B" rev-parse HEAD)" ] || { ko "D2C-TRACE : champ 5 ≠ HEAD complet de B"; miss=1; }
  case "$(field "$JB" 2 6)" in *S2*) : ;; *) ko "D2C-TRACE : champ 6 ne contient pas S2"; miss=1 ;; esac
  [ "$(field "$JB" 2 7)" = "-" ] || { ko "D2C-TRACE : champ 7 ≠ -"; miss=1; }
  [ "$(awk -F "$TAB" 'NR==1 { print $1 }' "$JB")" = "# vf-divergence journal v1" ] || { ko "D2C-TRACE : en-tete du journal ≠ « # vf-divergence journal v1 »"; miss=1; }
else
  ko "D2C-TRACE : aucun journal sous le .git de B"; miss=1
fi
[ "$miss" -eq 0 ] && ok "D2C-TRACE (P61-D-01, P61-D-04, P61-D-08) : install dev -> vrai pull divergent -> cri sur stderr + une ligne de journal v1 a sept champs"

# ---------------------------------------------------------------------------
# D2C-TRACE-SOLO — sans poste, puis au poste solo : aucun hook, aucun journal, aucun core.hooksPath
# ---------------------------------------------------------------------------
miss=0
inst "$WORK/C" "$WORK/cache" VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE-SOLO pre-condition : install sans poste rc=$RC"; miss=1; }
inst "$WORK/C" "$WORK/cache" VF_ROLE=solo VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE-SOLO pre-condition : install solo rc=$RC"; miss=1; }
local_commit "$WORK/C" y
pull_divergent "$WORK/C"; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE-SOLO : le pull de C a echoue (rc=$RC)"; miss=1; }
ls -1 "$WORK/C/.git/hooks" > "$WORK/hooks.c"
cmp -s "$WORK/hooks.c" "$WORK/hooks.temoin" || { ko "D2C-TRACE-SOLO : le dossier de hooks de C differe de celui d'un git init neuf"; miss=1; }
[ ! -e "$WORK/C/.git/vf-divergence" ] || { ko "D2C-TRACE-SOLO : un dossier vf-divergence existe sous le .git de C"; miss=1; }
git -C "$WORK/C" config --get core.hooksPath > /dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] || { ko "D2C-TRACE-SOLO : core.hooksPath est configure dans C (rc=$RC)"; miss=1; }
if "$GREP" -qF '[vf-divergence]' "$WORK/pull.err"; then ko "D2C-TRACE-SOLO : stderr du pull de C porte [vf-divergence]"; miss=1; fi
[ "$miss" -eq 0 ] && ok "D2C-TRACE-SOLO (critere 2 du jalon) : sans poste puis solo, aucun hook, aucun journal, aucun core.hooksPath, pull muet"

# ---------------------------------------------------------------------------
# D2C-TRACE-TIERS — un post-merge tiers n'est ni ecrase ni modifie ; l'install aboutit
# ---------------------------------------------------------------------------
miss=0
printf '#!/bin/sh\necho ran > "%s/tiers-witness"\n' "$WORK" > "$WORK/D/.git/hooks/post-merge"
chmod 755 "$WORK/D/.git/hooks/post-merge"
cp "$WORK/D/.git/hooks/post-merge" "$WORK/tiers.orig"
inst "$WORK/D" "$WORK/cache" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE-TIERS : l'install doit aboutir malgre le refus d'armement (rc=$RC)"; miss=1; }
[ -f "$WORK/D/.claude/vibeflow-role" ] || { ko "D2C-TRACE-TIERS : le fichier de poste n'a pas ete pose"; miss=1; }
cmp -s "$WORK/D/.git/hooks/post-merge" "$WORK/tiers.orig" || { ko "D2C-TRACE-TIERS : le hook tiers a ete modifie"; miss=1; }
"$GREP" -qF 'ARMEMENT REFUSE (code 1)' "$WORK/err" || { ko "D2C-TRACE-TIERS : stderr de l'install sans « ARMEMENT REFUSE (code 1) »"; miss=1; }
"$GREP" -qF 'LIGNE A AJOUTER A LA MAIN' "$WORK/err" || { ko "D2C-TRACE-TIERS : stderr de l'install sans la ligne a ajouter a la main"; miss=1; }
git -C "$WORK/D" config --get core.hooksPath > /dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] || { ko "D2C-TRACE-TIERS : core.hooksPath est configure dans D (rc=$RC)"; miss=1; }
rm -f "$WORK/tiers-witness"
local_commit "$WORK/D" y
pull_divergent "$WORK/D"; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE-TIERS : le pull de D a echoue (rc=$RC)"; miss=1; }
[ -f "$WORK/tiers-witness" ] || { ko "D2C-TRACE-TIERS : le hook tiers ne s'est pas execute au pull"; miss=1; }
[ ! -e "$WORK/D/.git/vf-divergence" ] || { ko "D2C-TRACE-TIERS : un journal existe alors que rien n'est arme"; miss=1; }
[ "$miss" -eq 0 ] && ok "D2C-TRACE-TIERS (P61-D-02) : hook tiers intact a l'octet, armement refuse en code 1, install aboutie, core.hooksPath absent, le hook tiers fonctionne toujours"

# ---------------------------------------------------------------------------
# D2C-TRACE-INTROUVABLE — script du cache disparu : NON VERIFIABLE audible et journalise
# ---------------------------------------------------------------------------
miss=0
mk_cache "$WORK/cache-ephemere" || { ko "D2C-TRACE-INTROUVABLE pre-condition : cache ephemere non construit"; miss=1; }
inst "$WORK/E" "$WORK/cache-ephemere" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE-INTROUVABLE pre-condition : install E rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
[ -f "$WORK/E/.git/hooks/post-merge" ] || { ko "D2C-TRACE-INTROUVABLE pre-condition : E n'est pas arme"; miss=1; }
rm -rf "$WORK/cache-ephemere"
local_commit "$WORK/E" y
pull_divergent "$WORK/E"; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-TRACE-INTROUVABLE : le pull de E a echoue (rc=$RC) — un hook ne doit jamais annuler la fusion"; miss=1; }
"$GREP" -qF '[vf-divergence] NON VERIFIABLE' "$WORK/pull.err" || { ko "D2C-TRACE-INTROUVABLE : stderr du pull sans « [vf-divergence] NON VERIFIABLE » (un silence se lirait comme un conforme)"; miss=1; }
"$GREP" -qF 'introuvable' "$WORK/pull.err" || { ko "D2C-TRACE-INTROUVABLE : stderr du pull sans « introuvable »"; miss=1; }
JE="$WORK/E/.git/vf-divergence/journal.tsv"
if [ -f "$JE" ]; then
  [ "$(nlines "$JE")" -eq 2 ] || { ko "D2C-TRACE-INTROUVABLE : le journal de E n'a pas exactement 2 lignes ($(nlines "$JE"))"; miss=1; }
  [ "$(awk -F "$TAB" 'NR==2 { print NF }' "$JE")" -eq 7 ] || { ko "D2C-TRACE-INTROUVABLE : la ligne de journal n'a pas 7 champs"; miss=1; }
  [ "$(field "$JE" 2 2)" = "post-merge" ] || { ko "D2C-TRACE-INTROUVABLE : champ 2 ≠ post-merge"; miss=1; }
  [ "$(field "$JE" 2 3)" = "NON-VERIFIABLE" ] || { ko "D2C-TRACE-INTROUVABLE : champ 3 ≠ NON-VERIFIABLE"; miss=1; }
  [ "$(field "$JE" 2 4)" = "-" ] || { ko "D2C-TRACE-INTROUVABLE : champ 4 ≠ -"; miss=1; }
  [ "$(field "$JE" 2 5)" = "$(git -C "$WORK/E" rev-parse HEAD)" ] || { ko "D2C-TRACE-INTROUVABLE : champ 5 ≠ HEAD complet de E"; miss=1; }
  [ "$(field "$JE" 2 6)" = "-" ] || { ko "D2C-TRACE-INTROUVABLE : champ 6 ≠ -"; miss=1; }
  [ "$(field "$JE" 2 7)" = "introuvable" ] || { ko "D2C-TRACE-INTROUVABLE : champ 7 ≠ introuvable"; miss=1; }
  [ "$(awk -F "$TAB" 'NR==1 { print $1 }' "$JE")" = "# vf-divergence journal v1" ] || { ko "D2C-TRACE-INTROUVABLE : en-tete du journal ≠ « # vf-divergence journal v1 »"; miss=1; }
else
  ko "D2C-TRACE-INTROUVABLE : aucun journal sous le .git de E"; miss=1
fi
[ "$miss" -eq 0 ] && ok "D2C-TRACE-INTROUVABLE (P61-D-03) : cache disparu -> NON VERIFIABLE sur stderr + ligne de journal « introuvable », pull abouti"

# ---------------------------------------------------------------------------
# monde <nom> <cache> <poste1> <poste2> — origine nue FRAICHE issue de la graine (compartiment w1, phase 1,
# conforme) et deux clones <nom>-1, <nom>-2 armes PAR L'INSTALL (VF_ROLE=<poste>, scope project) depuis <cache>.
# Jamais d'appel direct a `arm` : l'armement est celui de l'engine (COLB-07).
# ---------------------------------------------------------------------------
monde() {
  local nom="$1" cache="$2" i role
  MONDE_WHY=""
  git clone -q --bare "$WORK/seed" "$WORK/$nom.git" 2>/dev/null || { MONDE_WHY="origine $nom non creee"; return 1; }
  i=1
  for role in "$3" "$4"; do
    git clone -q "$WORK/$nom.git" "$WORK/$nom-$i" 2>/dev/null || { MONDE_WHY="clone $nom-$i non cree"; return 1; }
    ident "$WORK/$nom-$i"
    if ! inst "$WORK/$nom-$i" "$cache" "VF_ROLE=$role" VF_SCOPE=project -- install validator; then
      MONDE_WHY="install $nom-$i (poste $role) rc!=0 — $(tail -3 "$WORK/err")"; return 1
    fi
    i=$((i + 1))
  done
  return 0
}

# phase_poussee <clone> <numero> <suffixe> — dossier de phase + en-tete au ROADMAP du compartiment, commite et pousse.
phase_poussee() {
  mkdir -p "$1/.planning/workstreams/w1/phases/0$2-$3"
  printf 'phase %s %s\n' "$2" "$3" > "$1/.planning/workstreams/w1/phases/0$2-$3/0$2-CONTEXT.md"
  printf '### Phase %s: %s\n' "$2" "$3" >> "$1/.planning/workstreams/w1/ROADMAP.md"
  git -C "$1" add -- .planning
  git -C "$1" commit -q -m "phase $2 $3"
  git -C "$1" push -q origin main 2>/dev/null
}

# ---------------------------------------------------------------------------
# D2C-FF — B pousse sa fusion divergente ; A (arme par l'install, poste product) la recoit en AVANCE RAPIDE
# ---------------------------------------------------------------------------
miss=0
git -C "$WORK/B" push -q origin main 2>/dev/null || { ko "D2C-FF pre-condition : push de la fusion de B refuse"; miss=1; }
AV="$(jdata "$WORK/A")"
git -C "$WORK/A" pull -q --no-rebase > "$WORK/ff.out" 2> "$WORK/ff.err"; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-FF : le pull de A a echoue (rc=$RC) — un post-merge ne doit jamais l'annuler"; miss=1; }
[ "$(git -C "$WORK/A" rev-parse HEAD)" = "$(git -C "$WORK/B" rev-parse HEAD)" ] \
  || { ko "D2C-FF pre-condition : A n'est pas a la fusion de B (le pull n'etait pas une avance rapide)"; miss=1; }
sonde_cri "$WORK/A" "$WORK/ff.err" "$AV" || { ko "D2C-FF : sonde rouge sur A — $SONDE_WHY"; miss=1; }
JA="$(jfile "$WORK/A")"
[ "$(field "$JA" $((AV + 2)) 2)" = "post-merge" ] || { ko "D2C-FF : champ 2 du journal de A ≠ post-merge"; miss=1; }
[ "$miss" -eq 0 ] && ok "D2C-FF (P61-D-05) : la fusion de l'autre humain, faite ailleurs et vue au pull suivant en avance rapide, est criee (post-merge) et journalisee avec le HEAD de A"

# ---------------------------------------------------------------------------
# D2C-REBASE — `git pull --rebase` AVEC commit local : seul post-rewrite se declenche. Monde frais et conforme
# (le seul desaccord est 03-p / 03-q), arme par l'install (rb-1 product, rb-2 dev).
# ---------------------------------------------------------------------------
miss=0
if ! monde rb "$WORK/cache" product dev; then
  ko "D2C-REBASE pre-condition : $MONDE_WHY"; miss=1
else
  for n in 1 2; do
    RC=0; bash "$CD" --path "$WORK/rb-$n" >/dev/null 2>&1 </dev/null || RC=$?
    [ "$RC" -eq 0 ] || { ko "D2C-REBASE pre-condition : rb-$n n'est pas conforme avant la divergence (rc=$RC) — la preuve ne dirait rien"; miss=1; }
  done
  # rb-1 : phase 3-p LOCALE (en-tete en fin de ROADMAP) ; rb-2 : phase 3-q POUSSEE (en-tete en tete de ROADMAP :
  # deux zones disjointes, pas de conflit textuel au rebase).
  mkdir -p "$WORK/rb-1/.planning/workstreams/w1/phases/03-p" "$WORK/rb-2/.planning/workstreams/w1/phases/03-q"
  printf 'phase 3 p\n' > "$WORK/rb-1/.planning/workstreams/w1/phases/03-p/03-CONTEXT.md"
  printf '### Phase 3: p\n' >> "$WORK/rb-1/.planning/workstreams/w1/ROADMAP.md"
  git -C "$WORK/rb-1" add -- .planning; git -C "$WORK/rb-1" commit -q -m "phase 3 p"
  printf 'phase 3 q\n' > "$WORK/rb-2/.planning/workstreams/w1/phases/03-q/03-CONTEXT.md"
  { printf '### Phase 3: q\n'; cat "$WORK/rb-2/.planning/workstreams/w1/ROADMAP.md"; } > "$WORK/rb-2.roadmap"
  cp "$WORK/rb-2.roadmap" "$WORK/rb-2/.planning/workstreams/w1/ROADMAP.md"
  git -C "$WORK/rb-2" add -- .planning; git -C "$WORK/rb-2" commit -q -m "phase 3 q"
  git -C "$WORK/rb-2" push -q origin main 2>/dev/null || { ko "D2C-REBASE pre-condition : push de rb-2 refuse"; miss=1; }
  AV="$(jdata "$WORK/rb-1")"
  git -C "$WORK/rb-1" pull -q --rebase > "$WORK/rb.out" 2> "$WORK/rb.err"; RC=$?
  [ "$RC" -eq 0 ] || { ko "D2C-REBASE : le pull --rebase de rb-1 a echoue (rc=$RC) — $(tail -3 "$WORK/rb.err")"; miss=1; }
  sonde_cri "$WORK/rb-1" "$WORK/rb.err" "$AV" || { ko "D2C-REBASE : sonde rouge sur rb-1 — $SONDE_WHY"; miss=1; }
  JR="$(jfile "$WORK/rb-1")"
  [ "$(field "$JR" $((AV + 2)) 2)" = "post-rewrite" ] || { ko "D2C-REBASE : champ 2 du journal de rb-1 ≠ post-rewrite"; miss=1; }
  [ "$(field "$JR" $((AV + 2)) 5)" = "$(git -C "$WORK/rb-1" rev-parse HEAD)" ] || { ko "D2C-REBASE : champ 5 ≠ HEAD de rb-1 apres le rebase"; miss=1; }
  case "$(field "$JR" $((AV + 2)) 6)" in *S2*) : ;; *) ko "D2C-REBASE : champ 6 ne contient pas S2"; miss=1 ;; esac
fi
[ "$miss" -eq 0 ] && ok "D2C-REBASE (P61-D-05) : pull --rebase avec commit local, seul le hook post-rewrite se declenche : divergence criee, ligne de journal post-rewrite portant le HEAD de rb-1 apres rebase"

# ---------------------------------------------------------------------------
# D2C-PLAN — le plan --dry-run declare la cible, rien n'est ecrit
# ---------------------------------------------------------------------------
miss=0
inst "$WORK/G" "$WORK/cache" VF_ROLE=dev VF_SCOPE=project -- --dry-run install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-PLAN pre-condition : dry-run rc=$RC"; miss=1; }
"$GREP" -qF "[plan] ~ $WORK/G/.git/hooks/post-merge  (filet de divergence : hook git du clone, hors de l'arbre versionn" "$WORK/out" \
  || { ko "D2C-PLAN : ligne de plan du hook absente — $("$GREP" -F 'plan' "$WORK/out" | tail -3)"; miss=1; }
[ ! -e "$WORK/G/.git/hooks/post-merge" ] || { ko "D2C-PLAN : le dry-run a pose un hook"; miss=1; }
[ "$miss" -eq 0 ] && ok "D2C-PLAN : --dry-run declare la cible du hook git et n'ecrit rien"

# ---------------------------------------------------------------------------
# D2C-VERBES — --refresh, disarm, hors depot git (contrat du script)
# ---------------------------------------------------------------------------
HK="$REPO/conductor/scripts/vf-divergence-hook.sh"
CHK="$WORK/cache/conductor/scripts/vf-divergence-hook.sh"
miss=0
# --refresh sur un clone non arme : rc 0, rien d'ecrit
bash "$CHK" arm --refresh --path "$WORK/C" > /dev/null 2>&1; RC=$?
{ [ "$RC" -eq 0 ] && [ ! -e "$WORK/C/.git/hooks/post-merge" ]; } || { ko "D2C-VERBES : --refresh sur un clone non arme (rc=$RC) a arme ou echoue"; miss=1; }
# --refresh sur un clone arme : identique a l'octet
cp "$WORK/B/.git/hooks/post-merge" "$WORK/b.before"
bash "$CHK" arm --refresh --path "$WORK/B" > /dev/null 2>&1; RC=$?
{ [ "$RC" -eq 0 ] && cmp -s "$WORK/B/.git/hooks/post-merge" "$WORK/b.before"; } || { ko "D2C-VERBES : --refresh sur un clone arme (rc=$RC) a change le hook"; miss=1; }
# disarm sur le hook tiers : intact
bash "$CHK" disarm --path "$WORK/D" > /dev/null 2>&1; RC=$?
{ [ "$RC" -eq 0 ] && cmp -s "$WORK/D/.git/hooks/post-merge" "$WORK/tiers.orig"; } || { ko "D2C-VERBES : disarm a touche le hook tiers (rc=$RC)"; miss=1; }
# disarm sur un clone arme : hook retire, journal conserve
bash "$CHK" disarm --path "$WORK/B" > /dev/null 2>&1; RC=$?
{ [ "$RC" -eq 0 ] && [ ! -e "$WORK/B/.git/hooks/post-merge" ]; } || { ko "D2C-VERBES : disarm n'a pas retire le hook de B (rc=$RC)"; miss=1; }
[ "$(nlines "$WORK/B/.git/vf-divergence/journal.tsv" 2>/dev/null)" -eq 2 ] || { ko "D2C-VERBES : disarm a touche au journal de B"; miss=1; }
# status : B desarme -> 1, A arme -> 0
bash "$CHK" status --path "$WORK/B" > /dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] || { ko "D2C-VERBES : status d'un clone desarme (rc=$RC, attendu 1)"; miss=1; }
bash "$CHK" status --path "$WORK/A" > /dev/null 2>&1; RC=$?
[ "$RC" -eq 0 ] || { ko "D2C-VERBES : status d'un clone arme (rc=$RC, attendu 0)"; miss=1; }
# hors depot git : 3
mkdir -p "$WORK/horsgit"
for v in "arm --check" "arm" "disarm" "status"; do
  (cd "$WORK/horsgit" && bash "$CHK" $v > /dev/null 2>&1 </dev/null); RC=$?
  [ "$RC" -eq 3 ] || { ko "D2C-VERBES : « $v » hors depot git rend $RC (attendu 3)"; miss=1; }
done
# usage : 64
bash "$CHK" arm --inconnu > /dev/null 2>&1; RC=$?
[ "$RC" -eq 64 ] || { ko "D2C-VERBES : option inconnue rend $RC (attendu 64)"; miss=1; }
bash "$CHK" run --hook inconnu > /dev/null 2>&1; RC=$?
[ "$RC" -eq 64 ] || { ko "D2C-VERBES : run --hook inconnu rend $RC (attendu 64)"; miss=1; }
# aucune ecriture de configuration git dans le script
[ "$(awk '!/^[[:space:]]*#/ && /git config/ && !/--get/ { n++ } END { print n+0 }' "$HK")" -eq 0 ] || { ko "D2C-VERBES : le script ecrit une configuration git"; miss=1; }
[ "$miss" -eq 0 ] && ok "D2C-VERBES : --refresh n'arme jamais et ne change rien d'un hook a jour, disarm retire le notre et jamais un autre, journal conserve, status, hors depot = 3, usage = 64"

# ---------------------------------------------------------------------------
echo "== resultat : $pass ok, $fail ko =="
[ "$fail" -eq 0 ] || exit 1
exit 0
