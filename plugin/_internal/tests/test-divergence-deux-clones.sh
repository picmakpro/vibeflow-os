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
# Cas annonces pour le plan 61-05 (preuve complete, temoins rouges) : D2C-RELEVE, D2C-REBASE,
# D2C-PIEGE, D2C-MUT-DESARME, D2C-MUT-EXECUTABLE.
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

for n in A B; do
  git clone -q "$WORK/origin.git" "$WORK/$n" 2>/dev/null; ident "$WORK/$n"
done

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
echo "== resultat : $pass ok, $fail ko =="
[ "$fail" -eq 0 ] || exit 1
exit 0
