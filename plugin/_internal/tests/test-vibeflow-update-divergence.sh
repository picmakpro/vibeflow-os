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

echo ""
echo "Bilan : $pass OK, $fail KO — durée ${SECONDS}s"
[ "$fail" -eq 0 ]
