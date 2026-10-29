#!/usr/bin/env bash
# test-vibeflow-update-divergence.sh — Suite du volet « filet de divergence » de l'engine (Phase 61, plan 61-04).
#
# Couvre le CYCLE DE VIE du filet par l'installeur (P61-D-01, P61-D-06, P61-PL-07, P61-PL-08) : armement aux
# postes product et dev (install, verbe role), retrait au poste solo, a `uninstall --all` et sous
# VF_DIVERGENCE_HOOK=off, rafraichissement du chemin du cache a `update --all` (sans jamais armer un clone qui
# ne l'etait pas), script cherche dans le cache du plugin et nulle part ailleurs (P61-D-03), refus d'armement
# relaye sans faire echouer l'installation (P61-PL-03), plan --dry-run, poste solo inchange.
#
# Cas : VUD-TRACE (tracer), VUD-ROLE-SOLO, VUD-ROLE-DEV, VUD-PRODUCT, VUD-LOCAL, VUD-SOLO, VUD-USER,
# VUD-TARGET, VUD-NOGIT, VUD-TIERS, VUD-DRY, VUD-IDEMPOTENT, VUD-OPTOUT, VUD-OPTOUT-INV, VUD-UNINSTALL,
# VUD-UPDATE-REFRESH, VUD-CACHE-SEUL.
# Mutants de l'engine (QUAL-01, VUD-MUT-1..10), copie de _internal, l'original n'est jamais touche :
#   1 appel de divergence_hook_apply retire de role_apply        6 rafraichissement de `update --all` neutralise
#   2 armement etendu au poste solo                              7 repli de find_divergence_hook sur la cible
#   3 retrait au poste solo neutralise                           8 refus (code 1) non relaye
#   4 retrait de `uninstall --all` neutralise                    9 --dry-run qui arme pour de vrai
#   5 sortie `off` ignoree                                      10 valeur invalide de VF_DIVERGENCE_HOOK acceptee
#
# Cette suite exerce `vf-divergence-hook.sh` (livre par 61-01, durci par 61-03) : le comportement du script
# lui-meme est prouve par ses propres suites, ici on prouve ce que l'ENGINE en fait.
#
# ISOLATION (P61-PL-18) : HOME jetable, GIT_CONFIG_NOSYSTEM, GIT_CONFIG_GLOBAL vers un fichier vide,
# XDG_CONFIG_HOME, VF_ROLE, VF_SCOPE, VF_TARGET et VF_DIVERGENCE_HOOK retires de l'environnement, identite git
# posee dans chaque lab, caches HORS des labs (un cache sous le lab serait refuse). Fixtures generees a
# l'execution (compartiment `w1`, phases `x` et `y`), aucun nom de client. `ENG` designe l'engine joue.
# Comptages par awk, contenus exacts par cmp -s, jamais diff.
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

# PYTHONUSERBASE exporte AVANT de changer HOME : un site-packages utilisateur ne doit pas migrer avec lui.
PYTHONUSERBASE="${PYTHONUSERBASE:-$HOME/.local}"; export PYTHONUSERBASE

echo "== test-vibeflow-update-divergence (engine: $INSTALLER) =="

WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT
FH="$WORK/home"; mkdir -p "$FH"
: > "$WORK/gitconfig"
unset XDG_CONFIG_HOME VF_DIVERGENCE_HOOK VF_ROLE VF_SCOPE VF_TARGET GSD_WORKSTREAM VF_WORKSTREAM VF_WORKSTREAM_PLANNING_DIR
export HOME="$FH" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_TERMINAL_PROMPT=0

MARQUEUR='# vibeflow:vf-divergence-hook v1'
HOOKSCRIPT_REL="conductor/scripts/vf-divergence-hook.sh"

nlines() { awk 'END { print NR }' "$1"; }
# ligne2 <fichier> — deuxieme ligne du fichier.
ligne2() { awk 'NR==2 { print; exit }' "$1"; }
# count_in <fichier> <chaine fixe> — nombre de lignes du fichier contenant la chaine.
count_in() { awk -v p="$2" 'index($0, p) { n++ } END { print n+0 }' "$1"; }

git_init() { # <dir> — depot a branche main
  git init -q -b main "$1" >/dev/null 2>&1 || { git init -q "$1" >/dev/null 2>&1 && git -C "$1" symbolic-ref HEAD refs/heads/main; }
}

# Cache de plugin de test : conductor, planning-core, validator et la bibliotheque portable.
mk_cache() { # <dir>
  local m
  for m in conductor planning-core validator; do
    mkdir -p "$1/$m" && cp -R "$REPO/$m/." "$1/$m/" || return 1
  done
  mkdir -p "$1/_internal/lib" && cp "$INTERNAL_DIR/lib/vf-portable.sh" "$1/_internal/lib/" || return 1
}

# mk_lab — lab git neuf (hors de tout cache) ; pose LAB.
mk_lab() {
  LAB="$(mktemp -d "$WORK/lab.XXXXXX")"
  git_init "$LAB"
  git -C "$LAB" config user.email "test@example.invalid"; git -C "$LAB" config user.name "test"
}

# lab_run <lab> [VAR=val ...] -- <args engine...> — sorties : $WORK/out et $WORK/err ; rend le code de l'engine.
ENG="$INSTALLER"
CACHE="$WORK/cache"
lab_run() {
  local lab="$1"; shift
  local envs=()
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do envs+=("$1"); shift; done
  shift
  local rc=0
  (cd "$lab" && env -u VF_ROLE -u VF_SCOPE -u VF_TARGET -u XDG_CONFIG_HOME -u VF_DIVERGENCE_HOOK \
     HOME="$FH" VF_RUNTIME=claude VIBEFLOW_CACHE="$CACHE" \
     ${envs[@]+"${envs[@]}"} "${BASH:-bash}" "$ENG" "$@") > "$WORK/out" 2> "$WORK/err" || rc=$?
  return "$rc"
}

# is_ours <fichier> — vrai si la ligne 2 est le marqueur du filet.
is_ours() {
  [ -f "$1" ] || return 1
  case "$(ligne2 "$1")" in "$MARQUEUR"*) return 0 ;; *) return 1 ;; esac
}
# ours_count <lab> — nombre de hooks nostres (post-merge, post-rewrite) dans le dossier de hooks du lab.
ours_count() {
  local n=0 h
  for h in post-merge post-rewrite; do
    if is_ours "$1/.git/hooks/$h"; then n=$((n+1)); fi
  done
  echo "$n"
}
# hooks_same_as_witness <lab> — la liste du dossier de hooks est identique a celle d'un `git init` temoin.
hooks_same_as_witness() { ls -1 "$1/.git/hooks" > "$WORK/hooks.lab" 2>/dev/null; cmp -s "$WORK/hooks.lab" "$WORK/hooks.temoin"; }
# div_lines — nombre de lignes `[divergence]` du dernier run (stderr).
div_lines() { awk 'index($0, "[divergence]") { n++ } END { print n+0 }' "$WORK/err"; }
# files_with <lab> <chaine> — nombre de fichiers de hooks du lab qui contiennent la chaine (fixe).
files_with() {
  local n=0 h
  for h in post-merge post-rewrite; do
    if [ -f "$1/.git/hooks/$h" ] && [ "$(count_in "$1/.git/hooks/$h" "$2")" -gt 0 ]; then n=$((n+1)); fi
  done
  echo "$n"
}
# put_journal <lab> — ecrit a la main un journal v1 non vide ; son cksum est rendu par journal_ck.
put_journal() {
  mkdir -p "$1/.git/vf-divergence"
  printf '# vf-divergence journal v1\tdate\thook\tverdict\tcode\thead\tsignaux\traison\n2026-01-01T00:00:00Z\tpost-merge\tDIVERGENCE\t1\t-\tS2\t-\n' > "$1/.git/vf-divergence/journal.tsv"
}
journal_ck() { cksum < "$1/.git/vf-divergence/journal.tsv" 2>/dev/null || echo absent; }

# mk_diverg <lab> — compartiment w1 dont la phase 2 existe sous deux noms (signal S2 de check-divergence).
mk_diverg() {
  mkdir -p "$1/.planning/workstreams/w1/phases/01-a" "$1/.planning/workstreams/w1/phases/02-x" "$1/.planning/workstreams/w1/phases/02-y"
  printf '### Phase 1: a\n### Phase 2: x\n' > "$1/.planning/workstreams/w1/ROADMAP.md"
  printf -- '---\nprogress:\n  completed_phases: 1\n---\n' > "$1/.planning/workstreams/w1/STATE.md"
  printf 'phase 1\n' > "$1/.planning/workstreams/w1/phases/01-a/01-CONTEXT.md"
  printf 'phase 2 x\n' > "$1/.planning/workstreams/w1/phases/02-x/02-CONTEXT.md"
  printf 'phase 2 y\n' > "$1/.planning/workstreams/w1/phases/02-y/02-CONTEXT.md"
}

if ! mk_cache "$CACHE"; then
  echo "  ⊘ SKIP conductor/planning-core/validator non copiables dans le cache de test"
  exit 0
fi
if [ ! -f "$CACHE/$HOOKSCRIPT_REL" ]; then
  echo "  ⊘ SKIP $HOOKSCRIPT_REL absent du cache de test (plan 61-01 non livre)"
  exit 0
fi
HK="$CACHE/$HOOKSCRIPT_REL"

# Temoin : la liste du dossier de hooks d'un depot neuf (modeles de git compris).
git_init "$WORK/temoin"
ls -1 "$WORK/temoin/.git/hooks" > "$WORK/hooks.temoin"

# ---------------------------------------------------------------------------
# VUD-TRACE (tracer) — install au poste dev : chaque cible de `arm --check` est un fichier au marqueur
# ---------------------------------------------------------------------------
miss=0
mk_lab; L1="$LAB"
lab_run "$L1" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-TRACE : install dev rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
"$GREP" -qF '[divergence] filet armé' "$WORK/err" || { ko "VUD-TRACE : stderr sans « [divergence] filet armé »"; miss=1; }
bash "$HK" arm --check --path "$L1" > "$WORK/cibles" 2>/dev/null </dev/null
n=0
while IFS= read -r l; do
  case "$l" in
    "CIBLE "*)
      f="${l#CIBLE }"; n=$((n+1))
      is_ours "$f" || { ko "VUD-TRACE : $f absent ou sans le marqueur en ligne 2"; miss=1; }
      ;;
  esac
done < "$WORK/cibles"
[ "$n" -eq 2 ] || { ko "VUD-TRACE : arm --check imprime $n cible(s), attendu 2 (post-merge, post-rewrite)"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-TRACE (P61-D-01) : install au poste dev -> chaque cible de arm --check est un fichier au marqueur, ligne « filet armé » sur stderr"

# ---------------------------------------------------------------------------
# VUD-ROLE-SOLO — role solo retire le filet, le journal reste intact
# ---------------------------------------------------------------------------
miss=0
put_journal "$L1"; AVANT="$(journal_ck "$L1")"
lab_run "$L1" VF_SCOPE=project -- role solo; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-ROLE-SOLO : role solo rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
[ "$(ours_count "$L1")" -eq 0 ] || { ko "VUD-ROLE-SOLO : un hook a marqueur reste apres role solo"; miss=1; }
hooks_same_as_witness "$L1" || { ko "VUD-ROLE-SOLO : le dossier de hooks differe de celui d'un git init neuf"; miss=1; }
[ "$(journal_ck "$L1")" = "$AVANT" ] || { ko "VUD-ROLE-SOLO : le journal a change au retrait (cksum)"; miss=1; }
"$GREP" -qF '[divergence] filet retiré' "$WORK/err" || { ko "VUD-ROLE-SOLO : stderr sans « [divergence] filet retiré »"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-ROLE-SOLO (P61-H-01) : role solo retire les deux hooks, dossier de hooks = temoin, journal intact (cksum), « filet retiré » dit"

# ---------------------------------------------------------------------------
# VUD-ROLE-DEV — install sans poste, puis role dev : le filet est pose
# ---------------------------------------------------------------------------
miss=0
mk_lab; L2="$LAB"
lab_run "$L2" VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-ROLE-DEV pre-condition : install sans poste rc=$RC"; miss=1; }
[ "$(ours_count "$L2")" -eq 0 ] || { ko "VUD-ROLE-DEV : un hook pose par une install SANS poste"; miss=1; }
lab_run "$L2" VF_SCOPE=project -- role dev; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-ROLE-DEV : role dev rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
[ "$(ours_count "$L2")" -eq 2 ] || { ko "VUD-ROLE-DEV : $(ours_count "$L2") hook(s) a marqueur apres role dev, attendu 2"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-ROLE-DEV : install sans poste = aucun hook ; role dev = deux hooks a marqueur"

# ---------------------------------------------------------------------------
# VUD-PRODUCT / VUD-LOCAL
# ---------------------------------------------------------------------------
mk_lab; L3="$LAB"
lab_run "$L3" VF_ROLE=product VF_SCOPE=project -- install validator; RC=$?
if [ "$RC" -eq 0 ] && [ "$(ours_count "$L3")" -eq 2 ]; then ok "VUD-PRODUCT : le poste product arme le clone"; else ko "VUD-PRODUCT : rc=$RC hooks=$(ours_count "$L3")"; fi
mk_lab; L4="$LAB"
lab_run "$L4" VF_ROLE=dev VF_SCOPE=local -- install validator; RC=$?
if [ "$RC" -eq 0 ] && [ "$(ours_count "$L4")" -eq 2 ]; then ok "VUD-LOCAL : le scope local arme le clone"; else ko "VUD-LOCAL : rc=$RC hooks=$(ours_count "$L4")"; fi

# ---------------------------------------------------------------------------
# VUD-SOLO — sans poste et au poste solo : rien, liste du dossier de hooks = temoin (critere 2 du jalon)
# ---------------------------------------------------------------------------
miss=0
mk_lab; L5="$LAB"
lab_run "$L5" VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-SOLO pre-condition : install sans poste rc=$RC"; miss=1; }
[ "$(div_lines)" -eq 0 ] || { ko "VUD-SOLO : une ligne [divergence] sans poste"; miss=1; }
lab_run "$L5" VF_ROLE=solo VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-SOLO pre-condition : install solo rc=$RC"; miss=1; }
[ "$(div_lines)" -eq 0 ] || { ko "VUD-SOLO : une ligne [divergence] au poste solo"; miss=1; }
hooks_same_as_witness "$L5" || { ko "VUD-SOLO : le dossier de hooks differe de celui d'un git init neuf"; miss=1; }
[ ! -e "$L5/.git/vf-divergence" ] || { ko "VUD-SOLO : un dossier vf-divergence existe"; miss=1; }
git -C "$L5" config --get core.hooksPath >/dev/null 2>&1; RC=$?
[ "$RC" -eq 1 ] || { ko "VUD-SOLO : core.hooksPath configure (rc=$RC)"; miss=1; }
# Fichier de poste existant : un install solo passe par le retrait, sans rien dire quand il n'y a rien a retirer.
lab_run "$L5" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
lab_run "$L5" VF_SCOPE=project -- role solo >/dev/null 2>&1 || true
lab_run "$L5" VF_ROLE=solo VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-SOLO : install solo sur fichier de poste existant rc=$RC"; miss=1; }
[ "$(div_lines)" -eq 0 ] || { ko "VUD-SOLO : ligne [divergence] a l'install solo sur fichier de poste existant sans hook a retirer"; miss=1; }
hooks_same_as_witness "$L5" || { ko "VUD-SOLO : dossier de hooks different du temoin apres le retour a solo"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-SOLO (P61-H-01, critere 2) : sans poste ou solo, dossier de hooks = temoin, aucun vf-divergence, aucun core.hooksPath, aucune ligne [divergence]"

# ---------------------------------------------------------------------------
# VUD-USER — scope user : rien dans le depot du cwd ; un clone arme n'est pas touche
# ---------------------------------------------------------------------------
miss=0
mk_lab; L6="$LAB"
lab_run "$L6" VF_ROLE=solo -- --scope user install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-USER pre-condition : install scope user rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
[ "$(div_lines)" -eq 0 ] || { ko "VUD-USER : une ligne [divergence] en scope user"; miss=1; }
hooks_same_as_witness "$L6" || { ko "VUD-USER : le dossier de hooks du lab differe du temoin"; miss=1; }
[ ! -e "$L6/.git/vf-divergence" ] || { ko "VUD-USER : un dossier vf-divergence existe"; miss=1; }
mk_lab; L6b="$LAB"
lab_run "$L6b" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
lab_run "$L6b" -- --scope user update --all >/dev/null 2>&1 || true
lab_run "$L6b" -- --scope user uninstall --all >/dev/null 2>&1 || true
[ "$(ours_count "$L6b")" -eq 2 ] || { ko "VUD-USER : update/uninstall --all en scope user a touche le filet du clone ($(ours_count "$L6b") hook(s))"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-USER (T-61-17) : scope user = aucun hook, aucune ligne ; update --all et uninstall --all en scope user laissent un clone arme intact"

# ---------------------------------------------------------------------------
# VUD-TARGET — sous --target : aucun hook, un clone arme n'est pas touche
# ---------------------------------------------------------------------------
miss=0
mk_lab; L7="$LAB"
T7="$WORK/tgt7"
lab_run "$L7" VF_ROLE=dev VF_SCOPE=project -- --target "$T7" install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-TARGET pre-condition : install --target rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
[ "$(ours_count "$L7")" -eq 0 ] || { ko "VUD-TARGET : un hook pose sous --target"; miss=1; }
hooks_same_as_witness "$L7" || { ko "VUD-TARGET : le dossier de hooks differe du temoin sous --target"; miss=1; }
mk_lab; L7b="$LAB"
lab_run "$L7b" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
lab_run "$L7b" VF_SCOPE=project -- --target "$T7" uninstall --all >/dev/null 2>&1 || true
lab_run "$L7b" VF_SCOPE=project -- --target "$T7" update --all >/dev/null 2>&1 || true
[ "$(ours_count "$L7b")" -eq 2 ] || { ko "VUD-TARGET : uninstall/update --all sous --target a touche le filet du clone ($(ours_count "$L7b") hook(s))"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-TARGET (T-61-17) : sous --target, aucun hook pose et un clone arme n'est ni retire ni rafraichi"

# ---------------------------------------------------------------------------
# VUD-NOGIT — lab sans depot git : install reussit, information, rien d'arme
# ---------------------------------------------------------------------------
miss=0
LN="$(mktemp -d "$WORK/nogit.XXXXXX")"
lab_run "$LN" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-NOGIT : install rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
"$GREP" -qF '[divergence] pas de dépôt git' "$WORK/err" || { ko "VUD-NOGIT : stderr sans « [divergence] pas de dépôt git »"; miss=1; }
[ ! -e "$LN/.git" ] || { ko "VUD-NOGIT : un .git a ete cree"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-NOGIT : lab non git, install rc 0, « pas de dépôt git » dit, rien d'arme"

# ---------------------------------------------------------------------------
# VUD-TIERS — un post-merge tiers n'est ni ecrase ni modifie ; le refus est relaye, l'install aboutit
# ---------------------------------------------------------------------------
miss=0
mk_lab; L8="$LAB"
mkdir -p "$L8/.git/hooks"
printf '#!/bin/sh\necho hook-tiers\n' > "$L8/.git/hooks/post-merge"; chmod +x "$L8/.git/hooks/post-merge"
cp "$L8/.git/hooks/post-merge" "$WORK/tiers.ref"
lab_run "$L8" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-TIERS : install rc=$RC (un refus d'armement ne fait jamais echouer l'install)"; miss=1; }
"$GREP" -qF 'ARMEMENT REFUSE (code 1)' "$WORK/err" || { ko "VUD-TIERS : stderr sans « ARMEMENT REFUSE (code 1) »"; miss=1; }
"$GREP" -qF 'LIGNE A AJOUTER A LA MAIN' "$WORK/err" || { ko "VUD-TIERS : stderr sans la ligne « LIGNE A AJOUTER A LA MAIN » du script"; miss=1; }
cmp -s "$L8/.git/hooks/post-merge" "$WORK/tiers.ref" || { ko "VUD-TIERS : le hook tiers a change (cmp -s)"; miss=1; }
[ -f "$L8/.claude/vibeflow-role" ] || { ko "VUD-TIERS : le fichier de poste n'a pas ete pose"; miss=1; }
[ "$(ours_count "$L8")" -eq 0 ] || { ko "VUD-TIERS : un hook a marqueur apres un refus"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-TIERS (P61-PL-03) : hook tiers intact a l'octet, refus relaye (code 1 + ligne a ajouter), poste pose, engine rc 0"

# ---------------------------------------------------------------------------
# VUD-DRY — --dry-run declare chaque cible et n'ecrit rien
# ---------------------------------------------------------------------------
miss=0
mk_lab; L9="$LAB"
lab_run "$L9" VF_ROLE=dev VF_SCOPE=project -- --dry-run install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-DRY : --dry-run install rc=$RC"; miss=1; }
bash "$HK" arm --check --path "$L9" > "$WORK/cibles" 2>/dev/null </dev/null
ncib=0
while IFS= read -r l; do
  case "$l" in
    "CIBLE "*)
      f="${l#CIBLE }"; ncib=$((ncib+1))
      if [ "$(count_in "$WORK/out" "[plan] ~ $f  (filet de divergence : hook git du clone, hors de l'arbre versionné)")" -ne 1 ]; then
        ko "VUD-DRY : cible $f non declaree par « [plan] ~ »"; miss=1
      fi
      ;;
  esac
done < "$WORK/cibles"
[ "$ncib" -eq 2 ] || { ko "VUD-DRY : arm --check imprime $ncib cible(s), attendu 2"; miss=1; }
hooks_same_as_witness "$L9" || { ko "VUD-DRY : le dry-run a ecrit dans le dossier de hooks"; miss=1; }
[ ! -e "$L9/.claude/vibeflow-role" ] || { ko "VUD-DRY : le dry-run a pose le fichier de poste"; miss=1; }
# Retrait declare : lab arme, install solo en dry-run -> `[plan] -` par hook nostre, hooks encore la.
lab_run "$L1" VF_SCOPE=project VF_ROLE=dev -- install validator >/dev/null 2>&1 || true
lab_run "$L1" VF_ROLE=solo VF_SCOPE=project -- --dry-run install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-DRY : --dry-run install solo rc=$RC"; miss=1; }
[ "$(awk 'index($0, "(filet de divergence : hook VibeFlow retiré)") && index($0, "[plan] - ") == 1 { n++ } END { print n+0 }' "$WORK/out")" -eq 2 ] \
  || { ko "VUD-DRY : le retrait n'est pas declare par deux lignes « [plan] - … (filet de divergence : hook VibeFlow retiré) »"; miss=1; }
[ "$(ours_count "$L1")" -eq 2 ] || { ko "VUD-DRY : le dry-run a retire des hooks"; miss=1; }
# Rafraichissement declare : update --all en dry-run sur un lab arme ; rien sur un lab non arme.
lab_run "$L1" VF_SCOPE=project -- --dry-run update --all; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-DRY : --dry-run update --all rc=$RC"; miss=1; }
[ "$(awk 'index($0, "(filet de divergence : hook git du clone, hors de l'"'"'arbre versionné)") && index($0, "[plan] ~ ") == 1 { n++ } END { print n+0 }' "$WORK/out")" -eq 2 ] \
  || { ko "VUD-DRY : update --all en dry-run ne declare pas les deux hooks nostres"; miss=1; }
lab_run "$L2" VF_SCOPE=project -- role solo >/dev/null 2>&1 || true
lab_run "$L2" VF_SCOPE=project -- --dry-run update --all >/dev/null 2>&1 || true
[ "$(count_in "$WORK/out" "filet de divergence")" -eq 0 ] || { ko "VUD-DRY : update --all en dry-run declare le filet d'un clone NON arme"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-DRY (P61-PL-03) : --dry-run declare « [plan] ~ » par cible, « [plan] - » au retrait, rafraichissement des seuls hooks nostres, rien d'ecrit"

# ---------------------------------------------------------------------------
# VUD-IDEMPOTENT — deux installs au meme poste : hooks identiques a l'octet
# ---------------------------------------------------------------------------
miss=0
mk_lab; L10="$LAB"
lab_run "$L10" VF_ROLE=dev VF_SCOPE=project -- install validator || miss=1
cp "$L10/.git/hooks/post-merge" "$WORK/pm.1"; cp "$L10/.git/hooks/post-rewrite" "$WORK/pr.1"
lab_run "$L10" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-IDEMPOTENT : seconde install rc=$RC"; miss=1; }
cmp -s "$L10/.git/hooks/post-merge" "$WORK/pm.1" || { ko "VUD-IDEMPOTENT : post-merge different apres la seconde install"; miss=1; }
cmp -s "$L10/.git/hooks/post-rewrite" "$WORK/pr.1" || { ko "VUD-IDEMPOTENT : post-rewrite different apres la seconde install"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-IDEMPOTENT : deux installs au poste dev laissent les hooks identiques a l'octet"

# ---------------------------------------------------------------------------
# VUD-OPTOUT — VF_DIVERGENCE_HOOK=off : rien n'est arme, un hook nostre est retire, le journal reste
# ---------------------------------------------------------------------------
miss=0
mk_lab; L11="$LAB"
lab_run "$L11" VF_ROLE=dev VF_SCOPE=project VF_DIVERGENCE_HOOK=off -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-OPTOUT : install dev sous off rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
[ "$(ours_count "$L11")" -eq 0 ] || { ko "VUD-OPTOUT : un hook arme malgre off"; miss=1; }
# lab arme puis install sous off : retire, journal conserve
lab_run "$L11" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
[ "$(ours_count "$L11")" -eq 2 ] || { ko "VUD-OPTOUT pre-condition : lab non arme"; miss=1; }
put_journal "$L11"; AVANT="$(journal_ck "$L11")"
lab_run "$L11" VF_ROLE=dev VF_SCOPE=project VF_DIVERGENCE_HOOK=off -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-OPTOUT : install sous off sur lab arme rc=$RC"; miss=1; }
[ "$(ours_count "$L11")" -eq 0 ] || { ko "VUD-OPTOUT : off n'a pas retire les hooks nostres a l'install"; miss=1; }
[ "$(journal_ck "$L11")" = "$AVANT" ] || { ko "VUD-OPTOUT : le journal a change sous off"; miss=1; }
# update --all sous off
lab_run "$L11" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
lab_run "$L11" VF_SCOPE=project VF_DIVERGENCE_HOOK=off -- update --all; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-OPTOUT : update --all sous off rc=$RC"; miss=1; }
[ "$(ours_count "$L11")" -eq 0 ] || { ko "VUD-OPTOUT : off n'a pas retire les hooks nostres a update --all"; miss=1; }
# verbe role sous off
lab_run "$L11" VF_SCOPE=project VF_DIVERGENCE_HOOK=off -- role dev; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-OPTOUT : role dev sous off rc=$RC"; miss=1; }
[ "$(ours_count "$L11")" -eq 0 ] || { ko "VUD-OPTOUT : role dev sous off a arme"; miss=1; }
# valeur explicite on : arme comme le defaut
lab_run "$L11" VF_SCOPE=project VF_DIVERGENCE_HOOK=on -- role dev >/dev/null 2>&1 || true
[ "$(ours_count "$L11")" -eq 2 ] || { ko "VUD-OPTOUT : VF_DIVERGENCE_HOOK=on n'arme pas comme le defaut"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-OPTOUT (P61-D-06) : off = rien arme (install, role), hook nostre retire (install, update --all), journal conserve ; on = defaut"

# ---------------------------------------------------------------------------
# VUD-OPTOUT-INV — valeur invalide : refus a install et role, ignoree ailleurs, jamais reimprimee
# ---------------------------------------------------------------------------
miss=0
SECRET='zzSECRETzz'
mk_lab; L12="$LAB"
lab_run "$L12" VF_ROLE=dev VF_SCOPE=project VF_DIVERGENCE_HOOK="$SECRET" -- install validator; RC=$?
[ "$RC" -eq 1 ] || { ko "VUD-OPTOUT-INV : install dev sous valeur invalide rc=$RC, attendu 1"; miss=1; }
if "$GREP" -qF "$SECRET" "$WORK/out" "$WORK/err"; then ko "VUD-OPTOUT-INV : la valeur invalide est reimprimee"; miss=1; fi
"$GREP" -qF 'VF_DIVERGENCE_HOOK invalide' "$WORK/err" || { ko "VUD-OPTOUT-INV : message de refus absent"; miss=1; }
[ ! -e "$L12/.claude" ] || { ko "VUD-OPTOUT-INV : un .claude a ete pose malgre le refus"; miss=1; }
hooks_same_as_witness "$L12" || { ko "VUD-OPTOUT-INV : un hook a ete pose malgre le refus"; miss=1; }
lab_run "$L12" VF_SCOPE=project VF_DIVERGENCE_HOOK="$SECRET" -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-OPTOUT-INV : install SANS poste sous valeur invalide rc=$RC, attendu 0 (valeur ignoree)"; miss=1; }
lab_run "$L12" VF_SCOPE=project VF_DIVERGENCE_HOOK="$SECRET" -- role dev; RC=$?
[ "$RC" -eq 1 ] || { ko "VUD-OPTOUT-INV : role dev sous valeur invalide rc=$RC, attendu 1"; miss=1; }
if "$GREP" -qF "$SECRET" "$WORK/out" "$WORK/err"; then ko "VUD-OPTOUT-INV : role reimprime la valeur"; miss=1; fi
[ "$(ours_count "$L12")" -eq 0 ] || { ko "VUD-OPTOUT-INV : role a arme malgre le refus"; miss=1; }
# update --all et uninstall --all : ignoree avec une ligne de log, jamais armee, jamais un echec
lab_run "$L12" VF_SCOPE=project VF_DIVERGENCE_HOOK="$SECRET" -- update --all; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-OPTOUT-INV : update --all sous valeur invalide rc=$RC, attendu 0"; miss=1; }
if "$GREP" -qF "$SECRET" "$WORK/out" "$WORK/err"; then ko "VUD-OPTOUT-INV : update --all reimprime la valeur"; miss=1; fi
"$GREP" -qF '[divergence] VF_DIVERGENCE_HOOK invalide' "$WORK/err" || { ko "VUD-OPTOUT-INV : update --all sans ligne de log sur la valeur ignoree"; miss=1; }
[ "$(ours_count "$L12")" -eq 0 ] || { ko "VUD-OPTOUT-INV : update --all a arme un clone non arme"; miss=1; }
lab_run "$L12" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
lab_run "$L12" VF_SCOPE=project VF_DIVERGENCE_HOOK="$SECRET" -- update --all >/dev/null 2>&1 || true
[ "$(ours_count "$L12")" -eq 2 ] || { ko "VUD-OPTOUT-INV : update --all sous valeur invalide a retire le filet (un invalide ne vaut pas off)"; miss=1; }
lab_run "$L12" VF_SCOPE=project VF_DIVERGENCE_HOOK="$SECRET" -- uninstall --all; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-OPTOUT-INV : uninstall --all sous valeur invalide rc=$RC, attendu 0"; miss=1; }
if "$GREP" -qF "$SECRET" "$WORK/out" "$WORK/err"; then ko "VUD-OPTOUT-INV : uninstall reimprime la valeur"; miss=1; fi
"$GREP" -qF '[divergence] VF_DIVERGENCE_HOOK invalide' "$WORK/err" || { ko "VUD-OPTOUT-INV : uninstall --all sans ligne de log sur la valeur ignoree"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-OPTOUT-INV (T-61-18) : refus rc 1 sans écho a install et role (rien pose) ; ignoree avec une ligne de log a update --all et uninstall --all, jamais armee"

# ---------------------------------------------------------------------------
# VUD-UNINSTALL — uninstall --all retire les hooks nostres, garde le journal, laisse un hook tiers
# ---------------------------------------------------------------------------
miss=0
mk_lab; L13="$LAB"
lab_run "$L13" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
[ "$(ours_count "$L13")" -eq 2 ] || { ko "VUD-UNINSTALL pre-condition : lab non arme"; miss=1; }
put_journal "$L13"; AVANT="$(journal_ck "$L13")"
lab_run "$L13" VF_SCOPE=project -- uninstall --all; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-UNINSTALL : uninstall --all rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
[ "$(ours_count "$L13")" -eq 0 ] || { ko "VUD-UNINSTALL : un hook nostre reste apres uninstall --all"; miss=1; }
[ "$(journal_ck "$L13")" = "$AVANT" ] || { ko "VUD-UNINSTALL : le journal n'a pas survecu intact"; miss=1; }
"$GREP" -qF '[divergence] filet retiré' "$WORK/err" || { ko "VUD-UNINSTALL : stderr sans « [divergence] filet retiré »"; miss=1; }
# hook tiers present : intact
mk_lab; L14="$LAB"
lab_run "$L14" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
printf '#!/bin/sh\necho hook-tiers\n' > "$L14/.git/hooks/post-merge"; chmod +x "$L14/.git/hooks/post-merge"
cp "$L14/.git/hooks/post-merge" "$WORK/tiers14.ref"
lab_run "$L14" VF_SCOPE=project -- uninstall --all; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-UNINSTALL : uninstall --all avec hook tiers rc=$RC"; miss=1; }
cmp -s "$L14/.git/hooks/post-merge" "$WORK/tiers14.ref" || { ko "VUD-UNINSTALL : le hook tiers a ete modifie ou retire"; miss=1; }
is_ours "$L14/.git/hooks/post-rewrite" && { ko "VUD-UNINSTALL : le post-rewrite nostre reste"; miss=1; }
# uninstall d'un module seul : le filet reste (le hook vit du cache, pas d'un module)
mk_lab; L15="$LAB"
lab_run "$L15" VF_ROLE=dev VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
lab_run "$L15" VF_SCOPE=project -- uninstall validator >/dev/null 2>&1 || true
[ "$(ours_count "$L15")" -eq 2 ] || { ko "VUD-UNINSTALL : « uninstall <module> » a retire le filet (reserve a uninstall --all)"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-UNINSTALL (T-61-20) : uninstall --all retire les hooks nostres, journal intact (cksum), hook tiers intact ; uninstall <module> n'y touche pas"

# ---------------------------------------------------------------------------
# VUD-UPDATE-REFRESH — le chemin du cache suit update --all ; un clone non arme ne l'est jamais
# ---------------------------------------------------------------------------
miss=0
CA="$WORK/cache-a"; CB="$WORK/cache-b"; CC="$WORK/cache-c"
mk_cache "$CA" && mk_cache "$CB" && mk_cache "$CC" || { ko "VUD-UPDATE-REFRESH pre-condition : caches non copiables"; miss=1; }
mk_lab; L16="$LAB"
lab_run "$L16" VIBEFLOW_CACHE="$CA" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-UPDATE-REFRESH pre-condition : install depuis cache-a rc=$RC"; miss=1; }
[ "$(files_with "$L16" "$CA/")" -eq 2 ] || { ko "VUD-UPDATE-REFRESH pre-condition : les hooks ne designent pas cache-a"; miss=1; }
lab_run "$L16" VIBEFLOW_CACHE="$CB" VF_SCOPE=project -- update --all; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-UPDATE-REFRESH : update --all depuis cache-b rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
[ "$(files_with "$L16" "$CB/")" -eq 2 ] || { ko "VUD-UPDATE-REFRESH : les hooks ne designent pas cache-b apres update --all ($(files_with "$L16" "$CB/") fichier(s))"; miss=1; }
[ "$(files_with "$L16" "$CA/")" -eq 0 ] || { ko "VUD-UPDATE-REFRESH : un hook designe encore cache-a"; miss=1; }
[ "$(ours_count "$L16")" -eq 2 ] || { ko "VUD-UPDATE-REFRESH : le marqueur a disparu apres le rafraichissement"; miss=1; }
# cache-a disparu : une fusion divergente crie toujours, sans « introuvable »
rm -rf "$CA"
mk_diverg "$L16"
bash "$CB/conductor/scripts/check-divergence.sh" --path "$L16" >/dev/null 2>&1 </dev/null; RC=$?
[ "$RC" -eq 1 ] || { ko "VUD-UPDATE-REFRESH pre-condition : le lab de test n'est pas divergent (check-divergence rc=$RC)"; miss=1; }
(cd "$L16" && sh .git/hooks/post-merge 0 >"$WORK/hook.out" 2>"$WORK/hook.err" </dev/null); RC=$?
# `run` rend 1 sur une divergence (git ignore le code d'un post-merge : la fusion n'est jamais annulee).
[ "$RC" -eq 1 ] || { ko "VUD-UPDATE-REFRESH : code du hook = $RC, attendu 1 (divergence criee)"; miss=1; }
"$GREP" -qF '[vf-divergence] DIVERGENCE' "$WORK/hook.err" || { ko "VUD-UPDATE-REFRESH : le hook ne crie pas apres la disparition de cache-a — $(tail -3 "$WORK/hook.err")"; miss=1; }
if "$GREP" -qi 'introuvable' "$WORK/hook.err"; then ko "VUD-UPDATE-REFRESH : le hook dit « introuvable » apres le rafraichissement"; miss=1; fi
# clone non arme : update --all ne l'arme jamais
mk_lab; L17="$LAB"
lab_run "$L17" VIBEFLOW_CACHE="$CC" VF_SCOPE=project -- install validator >/dev/null 2>&1 || true
lab_run "$L17" VIBEFLOW_CACHE="$CB" VF_SCOPE=project -- update --all; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-UPDATE-REFRESH : update --all sur clone non arme rc=$RC"; miss=1; }
[ "$(ours_count "$L17")" -eq 0 ] || { ko "VUD-UPDATE-REFRESH : update --all a ARME un clone qui ne l'etait pas"; miss=1; }
hooks_same_as_witness "$L17" || { ko "VUD-UPDATE-REFRESH : le dossier de hooks du clone non arme a change"; miss=1; }
[ "$(div_lines)" -eq 0 ] || { ko "VUD-UPDATE-REFRESH : ligne [divergence] sur un clone non arme"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-UPDATE-REFRESH (P61-PL-08, T-61-19) : update --all re-pointe les hooks nostres vers le nouveau cache, le hook crie encore cache-a disparu, un clone non arme reste non arme"

# ---------------------------------------------------------------------------
# VUD-CACHE-SEUL — le script n'est cherche que dans le cache ; un piege dans le lab ne s'execute jamais
# ---------------------------------------------------------------------------
miss=0
CP="$WORK/cache-priv"
mk_cache "$CP" && rm -f "$CP/$HOOKSCRIPT_REL" || { ko "VUD-CACHE-SEUL pre-condition : cache prive non constituable"; miss=1; }
mk_lab; L18="$LAB"
mkdir -p "$L18/.claude/scripts" "$L18/scripts"
PIEGE="$WORK/piege"
for d in "$L18/.claude/scripts" "$L18/scripts"; do
  printf '#!/bin/sh\n: > "%s"\nexit 0\n' "$PIEGE" > "$d/vf-divergence-hook.sh"; chmod +x "$d/vf-divergence-hook.sh"
done
lab_run "$L18" VIBEFLOW_CACHE="$CP" VF_ROLE=dev VF_SCOPE=project -- install validator; RC=$?
[ "$RC" -eq 0 ] || { ko "VUD-CACHE-SEUL : install rc=$RC — $(tail -3 "$WORK/err")"; miss=1; }
"$GREP" -qF '[divergence] NON VERIFIABLE : vf-divergence-hook.sh absent du cache' "$WORK/err" || { ko "VUD-CACHE-SEUL : stderr sans la ligne « NON VERIFIABLE : vf-divergence-hook.sh absent du cache »"; miss=1; }
[ ! -e "$PIEGE" ] || { ko "VUD-CACHE-SEUL : le script piege du lab a ete EXECUTE"; miss=1; }
[ "$(ours_count "$L18")" -eq 0 ] || { ko "VUD-CACHE-SEUL : un hook arme sans script dans le cache"; miss=1; }
# retrait et rafraichissement : le meme piege reste inerte
lab_run "$L18" VIBEFLOW_CACHE="$CP" VF_SCOPE=project -- role solo >/dev/null 2>&1 || true
lab_run "$L18" VIBEFLOW_CACHE="$CP" VF_SCOPE=project -- update --all >/dev/null 2>&1 || true
lab_run "$L18" VIBEFLOW_CACHE="$CP" VF_SCOPE=project -- uninstall --all >/dev/null 2>&1 || true
[ ! -e "$PIEGE" ] || { ko "VUD-CACHE-SEUL : le piege a ete execute par role solo, update --all ou uninstall --all"; miss=1; }
[ "$miss" -eq 0 ] && ok "VUD-CACHE-SEUL (T-61-16, P61-D-03) : script absent du cache = « NON VERIFIABLE » nomme, aucun repli, le piege pose dans le lab n'est jamais execute"

# ---------------------------------------------------------------------------
# Mutants (QUAL-01) — copie de _internal, l'original n'est jamais touche
# ---------------------------------------------------------------------------
MUT="$WORK/mut"; mkdir -p "$MUT"; cp -R "$INTERNAL_DIR" "$MUT/_internal"; rm -rf "$MUT/_internal/tests"
mutate() { # <n> → ecrit le mutant et rend son chemin ; 1 = identique a l'original, 2 = invalide
  local out="$MUT/_internal/vibeflow-update.sh"
  awk -v MODE="$1" '
    MODE == "1" && $0 == "  divergence_hook_apply \"$poste\"" { print "  :"; next }
    MODE == "2" && $0 == "    product|dev) : ;;" { print "    product|dev|solo) : ;;"; next }
    MODE == "3" && $0 == "    solo) divergence_hook_disarm; return 0 ;;" { print "    solo) return 0 ;;"; next }
    MODE == "4" && $0 == "      divergence_hook_disarm_scoped" { print "      :"; next }
    MODE == "5" && index($0, "divergence_off() {") == 1 { print "divergence_off() { false; }"; next }
    MODE == "6" && $0 == "      divergence_hook_refresh_scoped" { print "      :"; next }
    MODE == "7" && $0 == "find_divergence_hook() {" { inf = 1 }
    MODE == "7" && inf && $0 == "  [ -f \"$c\" ] && { echo \"$c\"; return 0; }" { print; print "  c=\"$TARGET_ROOT/scripts/vf-divergence-hook.sh\"; [ -f \"$c\" ] && { echo \"$c\"; return 0; }"; inf = 0; next }
    MODE == "8" && index($0, "    1) log \"[divergence] ARMEMENT REFUSE (code 1)") == 1 { print "    1) : ;;"; next }
    MODE == "9" && $0 == "divergence_hook_apply() {" { ina = 1 }
    MODE == "9" && ina && $0 == "  if vf_dry_run; then" { print "  if false; then"; ina = 0; next }
    MODE == "10" && index($0, "*) err \"VF_DIVERGENCE_HOOK invalide") > 0 { sub(/\*\) err .*$/, "*) : ;;"); print; next }
    { print }' "$INTERNAL_DIR/vibeflow-update.sh" > "$out"
  cmp -s "$out" "$INTERNAL_DIR/vibeflow-update.sh" && return 1
  bash -n "$out" || return 2
  echo "$out"
}

# Sondes : chacune rend un jeton court, compare entre l'original (attendu) et le mutant (obtenu).
probe_trace() { # 1 : le poste dev arme-t-il ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=dev VF_SCOPE=project -- install validator
  printf 'ours=%s' "$(ours_count "$LAB")"
}
probe_solo() { # 2 : sans poste, role solo, install solo : rien n'est arme
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_SCOPE=project -- install validator
  lab_run "$LAB" VF_SCOPE=project -- role solo
  lab_run "$LAB" VF_ROLE=solo VF_SCOPE=project -- install validator
  printf 'ours=%s' "$(ours_count "$LAB")"
}
probe_role_solo() { # 3 : role solo retire-t-il le filet ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=dev VF_SCOPE=project -- install validator
  lab_run "$LAB" VF_SCOPE=project -- role solo
  printf 'ours=%s' "$(ours_count "$LAB")"
}
probe_uninstall() { # 4 : uninstall --all retire-t-il le filet ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=dev VF_SCOPE=project -- install validator
  lab_run "$LAB" VF_SCOPE=project -- uninstall --all
  printf 'ours=%s' "$(ours_count "$LAB")"
}
probe_optout() { # 5 : off arme-t-il quand meme ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=dev VF_SCOPE=project VF_DIVERGENCE_HOOK=off -- install validator
  printf 'ours=%s' "$(ours_count "$LAB")"
}
probe_refresh() { # 6 : update --all re-pointe-t-il les hooks vers le nouveau cache ?
  local pa pb
  pa="$WORK/pcache-a"; pb="$WORK/pcache-b"; rm -rf "$pa" "$pb"; mk_cache "$pa"; mk_cache "$pb"
  mk_lab; ENG="$1"
  lab_run "$LAB" VIBEFLOW_CACHE="$pa" VF_ROLE=dev VF_SCOPE=project -- install validator
  lab_run "$LAB" VIBEFLOW_CACHE="$pb" VF_SCOPE=project -- update --all
  printf 'a=%s b=%s' "$(files_with "$LAB" "$pa/")" "$(files_with "$LAB" "$pb/")"
}
probe_cache_seul() { # 7 : un script du lab est-il execute quand le cache n'en a pas ?
  rm -f "$PIEGE"; mk_lab; ENG="$1"
  mkdir -p "$LAB/.claude/scripts"
  printf '#!/bin/sh\n: > "%s"\nexit 0\n' "$PIEGE" > "$LAB/.claude/scripts/vf-divergence-hook.sh"; chmod +x "$LAB/.claude/scripts/vf-divergence-hook.sh"
  lab_run "$LAB" VIBEFLOW_CACHE="$CP" VF_ROLE=dev VF_SCOPE=project -- install validator
  if [ -e "$PIEGE" ]; then printf 'piege=oui'; else printf 'piege=non'; fi
  rm -f "$PIEGE"
}
probe_tiers() { # 8 : le refus d'armement est-il relaye ?
  mk_lab; ENG="$1"
  mkdir -p "$LAB/.git/hooks"; printf '#!/bin/sh\necho hook-tiers\n' > "$LAB/.git/hooks/post-merge"; chmod +x "$LAB/.git/hooks/post-merge"
  lab_run "$LAB" VF_ROLE=dev VF_SCOPE=project -- install validator
  if "$GREP" -qF 'ARMEMENT REFUSE (code 1)' "$WORK/err"; then printf 'refuse=oui'; else printf 'refuse=non'; fi
}
probe_dry() { # 9 : --dry-run arme-t-il pour de vrai ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=dev VF_SCOPE=project -- --dry-run install validator
  printf 'hooks=%s plan=%s' "$(ours_count "$LAB")" "$(count_in "$WORK/out" "(filet de divergence")"
}
probe_inv() { # 10 : une valeur invalide est-elle refusee ?
  mk_lab; ENG="$1"
  lab_run "$LAB" VF_ROLE=dev VF_SCOPE=project VF_DIVERGENCE_HOOK=zzSECRETzz -- install validator; local rc=$?
  printf 'rc=%s hooks=%s' "$rc" "$(ours_count "$LAB")"
}

kill_mutant() { # <n> <sonde> <attendu sur l'original> <libelle>
  local n="$1" probe="$2" want="$3" label="$4" m orig got mrc
  m="$(mutate "$n")"; mrc=$?
  if [ "$mrc" -ne 0 ] || [ -z "$m" ]; then ko "VUD-MUT-$n : mutant non produit ou invalide (rc=$mrc) — $label"; return; fi
  orig="$("$probe" "$INSTALLER")"
  got="$("$probe" "$m")"
  if [ "$orig" = "$want" ] && [ "$got" != "$orig" ]; then
    ok "VUD-MUT-$n mutant tué : $label — attendu « $orig », obtenu « $got »"
  else
    ko "VUD-MUT-$n : mutant survivant ou témoin rouge — $label — original « $orig » (voulu « $want »), mutant « $got »"
  fi
}
kill_mutant 1 probe_trace 'ours=2' "appel de divergence_hook_apply retire de role_apply"
kill_mutant 2 probe_solo 'ours=0' "armement etendu au poste solo"
kill_mutant 3 probe_role_solo 'ours=0' "retrait au poste solo neutralise"
kill_mutant 4 probe_uninstall 'ours=0' "retrait de uninstall --all neutralise"
kill_mutant 5 probe_optout 'ours=0' "sortie off ignoree"
kill_mutant 6 probe_refresh 'a=0 b=2' "rafraichissement de update --all neutralise"
kill_mutant 7 probe_cache_seul 'piege=non' "repli de find_divergence_hook sur le dossier de la cible"
kill_mutant 8 probe_tiers 'refuse=oui' "refus d'armement (code 1) non relaye"
kill_mutant 9 probe_dry 'hooks=0 plan=2' "--dry-run qui arme pour de vrai"
kill_mutant 10 probe_inv 'rc=1 hooks=0' "valeur invalide de VF_DIVERGENCE_HOOK acceptee"
ENG="$INSTALLER"

echo ""
echo "Bilan : $pass OK, $fail KO — durée ${SECONDS}s"
[ "$fail" -eq 0 ]
