#!/usr/bin/env bash
# test-check-baseline-arbitrage.sh — Suite de verification de check-baseline-arbitrage.sh (G-1,
# PROT-04, QUAL-01, plan 41-14). Patron : test-check-instruction-budget.sh
# (plugin/conductor/scripts/tests/). Chaque cas construit SON PROPRE depot jetable sous mktemp -d,
# JAMAIS le depot reel ; identite git passee par -c, jamais la configuration du poste ; comparaisons
# de fixtures par cmp et comm uniquement, jamais diff (proxifie menteur sur ce poste). Une suite
# incapable de rougir est un defaut, au meme titre que le gate qu'elle verifie.
#
# Trois issues QUAL-01 (PASS / FAIL / BRUYANT) plus SILENCE et USAGE, et NEUF mutants opposables
# (MUT-1 a MUT-9), un par comparaison du script sous test — regle de comptage (decision du manager,
# 2026-09-17) : chaque mutant asserte le rc EXACT attendu sur le mutant ET sur l'original. Un mutant
# qui « echoue » par un plantage (rc 2) ou une plage vide (rc 3) la ou le cas attendait un flip 0/1
# n'est PAS compte comme tue. La ligne de succes d'un mutant a une forme UNIQUE, exigee par le verify
# du plan : « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-baseline-arbitrage.sh"
TARGET="$SCRIPT"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
# ko <assertion> <attendu> <obtenu> — trace a trois champs distincts, jamais un « KO » muet.
ko() {
  echo "  ✗ $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL + 1))
}
okmut() {  # <n> <rc_mutant> <attendu_mut> <rc_original> <attendu_orig>
  echo "  ✓ MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5"
  PASS=$((PASS + 1))
}
komut() {  # <n> <assertion> <attendu> <obtenu>
  echo "  ✗ MUT-$1 NON TUE : $2"
  echo "    assertion : MUT-$1 $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  FAIL=$((FAIL + 1))
}

TMP="$(mktemp -d)"
MUTD="$(mktemp -d)"
trap 'rm -rf "$TMP" "$MUTD"' EXIT

TAB="$(printf '\t')"

# ===================================================================================================
# Constructeurs de fixture — depots jetables purs sous $TMP, jamais le depot reel.
# ===================================================================================================

git_c() {  # <root> <args...> — identite de fixture par -c, jamais la config du poste.
  local root="$1"; shift
  git -C "$root" -c user.name=CI -c user.email=ci@example.invalid -c commit.gpgsign=false "$@"
}

# mk_repo <name> -> imprime <path> ; depot jetable, baseline a deux lignes, deux sentinelles, un
# premier commit sur `main`.
mk_repo() {
  local d="$TMP/$1"
  mkdir -p "$d/plugin/demo" "$d/.planning" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  git_c "$d" init -q -b main >/dev/null
  printf '%s\n' \
    '# baseline de fixture' \
    "plugin/demo/a.md${TAB}10${TAB}5" \
    "plugin/demo/b.md${TAB}20${TAB}8" \
    > "$d/.planning/instruction-budget-baselines.tsv"
  : > "$d/.planning/.instruction-budget-armed"
  printf 'arme\n' > "$d/.planning/.requirements-survival-armed"
  printf 'contenu a\n' > "$d/plugin/demo/a.md"
  printf 'contenu b\n' > "$d/plugin/demo/b.md"
  git_c "$d" add -A >/dev/null
  git_c "$d" commit -q -m "fixture: etat initial" >/dev/null
  printf '%s' "$d"
}

w_baseline() { cat > "$1/.planning/instruction-budget-baselines.tsv"; }

commit_avec() {  # <root> <message>
  local root="$1" msg="$2"
  git_c "$root" add -A >/dev/null
  git_c "$root" commit -q -m "$msg" >/dev/null
}

base_of() { git_c "$1" rev-list --max-parents=0 HEAD | tail -1; }

run() {  # <root> [args...] — invocation TOUJOURS via --root.
  local root="$1"; shift
  bash "$TARGET" --root "$root" "$@" 2>&1
}

# make_mutant <name> <old> <new> -> imprime le chemin du mutant ; retour 0 = opposable et valide,
# 1 = identique a l'original (NON OPPOSABLE), 2 = syntaxe invalide.
make_mutant() {
  local name="$1" old="$2" new="$3"
  local out="$MUTD/${name}.sh"
  awk -v old="$old" -v new="$new" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$out"
  if cmp -s "$out" "$SCRIPT"; then
    echo "$out"
    return 1
  fi
  if ! bash -n "$out" 2>/dev/null; then
    echo "$out"
    return 2
  fi
  echo "$out"
  return 0
}

echo "== test-check-baseline-arbitrage : PASS =="

# --- PASS 1 : rien ne change ------------------------------------------------------------------------
D="$(mk_repo pass1)"; B="$(base_of "$D")"
git_c "$D" commit -q --allow-empty -m "chore: rien ne change"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *CONFORME*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "PASS rien ne change -> rc 0 CONFORME"
else ko "PASS rien ne change" "rc=0 CONFORME" "rc=$rc :: $out"; fi

# --- PASS 2 : baisse d'une valeur --------------------------------------------------------------------
D="$(mk_repo pass2)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}3" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: baisse instructions a.md"
out="$(run "$D" --base-ref "$B")"; rc=$?
[ "$rc" -eq 0 ] && ok "PASS baisse de valeur -> rc 0" || ko "PASS baisse de valeur" "rc=0" "rc=$rc :: $out"

# --- PASS 3 : ajout d'une ligne -----------------------------------------------------------------------
D="$(mk_repo pass3)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}5" "plugin/demo/b.md${TAB}20${TAB}8" "plugin/demo/c.md${TAB}5${TAB}2" | w_baseline "$D"
printf 'c\n' > "$D/plugin/demo/c.md"
commit_avec "$D" "feat: ajout c.md"
out="$(run "$D" --base-ref "$B")"; rc=$?
[ "$rc" -eq 0 ] && ok "PASS ajout de ligne -> rc 0" || ko "PASS ajout de ligne" "rc=0" "rc=$rc :: $out"

# --- PASS 4 : hausse AVEC citation conforme ------------------------------------------------------------
D="$(mk_repo pass4)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "feat: hausse instructions a.md

arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"
out="$(run "$D" --base-ref "$B")"; rc=$?
[ "$rc" -eq 0 ] && ok "PASS hausse avec citation conforme -> rc 0" || ko "PASS hausse avec citation conforme" "rc=0" "rc=$rc :: $out"

# --- PASS 5 : hausse avec citation « arbitrages » au pluriel --------------------------------------------
D="$(mk_repo pass5)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "feat: hausse instructions a.md

arbitrages Samuel, AskUserQuestion session principale, 2026-09-17"
out="$(run "$D" --base-ref "$B")"; rc=$?
[ "$rc" -eq 0 ] && ok "PASS hausse avec citation 'arbitrages' pluriel -> rc 0" || ko "PASS hausse avec citation pluriel" "rc=0" "rc=$rc :: $out"

# --- PASS 6 : sentinelle deja vide (0 octet) SUPPRIMEE avec citation conforme -> rc 0 (regression : -----
# --- la premiere version du culprit-walk exigeait une taille prealable non nulle, donc ne trouvait ------
# --- jamais le commit fautif pour une sentinelle DEJA vide -> citation jamais lue -> rc1 a tort) --------
D="$(mk_repo pass6)"; B="$(base_of "$D")"
rm -f "$D/.planning/.instruction-budget-armed"
commit_avec "$D" "chore: retire la sentinelle armed (deja vide) AVEC citation

arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"
out="$(run "$D" --base-ref "$B")"; rc=$?
[ "$rc" -eq 0 ] && ok "PASS sentinelle deja vide, supprimee avec citation conforme -> rc 0" || ko "PASS sentinelle deja vide supprimee avec citation" "rc=0" "rc=$rc :: $out"

echo "== test-check-baseline-arbitrage : FAIL =="

# --- FAIL 1 : hausse INSTRUCTIONS sans citation ---------------------------------------------------------
D="$(mk_repo fail1)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "feat: hausse instructions a.md sans citation"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *HAUSSE-SANS-ARBITRAGE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL hausse sans citation -> rc 1 HAUSSE-SANS-ARBITRAGE"
else ko "FAIL hausse sans citation" "rc=1 HAUSSE-SANS-ARBITRAGE" "rc=$rc :: $out"; fi

# --- FAIL 2 : citation sans canal ni date (mot « arbitrage » seul) --------------------------------------
D="$(mk_repo fail2)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "feat: hausse instructions a.md, citation faible

arbitrage"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *HAUSSE-SANS-ARBITRAGE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL citation sans canal ni date -> rc 1"
else ko "FAIL citation sans canal ni date" "rc=1 HAUSSE-SANS-ARBITRAGE" "rc=$rc :: $out"; fi

# --- FAIL 3 : sentinelle supprimee sans citation --------------------------------------------------------
D="$(mk_repo fail3)"; B="$(base_of "$D")"
rm -f "$D/.planning/.instruction-budget-armed"
commit_avec "$D" "chore: retire la sentinelle armed sans citation"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *SENTINELLE-NEUTRALISEE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL sentinelle supprimee sans citation -> rc 1"
else ko "FAIL sentinelle supprimee sans citation" "rc=1 SENTINELLE-NEUTRALISEE" "rc=$rc :: $out"; fi

# --- FAIL 4 : sentinelle non vide videe sans citation ----------------------------------------------------
D="$(mk_repo fail4)"; B="$(base_of "$D")"
: > "$D/.planning/.requirements-survival-armed"
commit_avec "$D" "chore: vide la sentinelle requirements-survival sans citation"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *SENTINELLE-NEUTRALISEE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL sentinelle non vide videe sans citation -> rc 1"
else ko "FAIL sentinelle non vide videe sans citation" "rc=1 SENTINELLE-NEUTRALISEE" "rc=$rc :: $out"; fi

# --- FAIL 5 : hausse d'instructions introduite par une resolution de merge -------------------------------
D="$(mk_repo fail5)"; B="$(base_of "$D")"
git_c "$D" checkout -q -b side
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}5" "plugin/demo/b.md${TAB}21${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore(side): touche b.md seulement"
git_c "$D" checkout -q main
git_c "$D" merge -q --no-ff -m "merge: fusion side" side >/dev/null
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}21${TAB}8" | w_baseline "$D"
git_c "$D" add -A >/dev/null
git_c "$D" commit --amend -q -m "merge: fusion side (amende, hausse involontaire de a.md)" >/dev/null
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *HAUSSE-NON-IMPUTABLE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL hausse via resolution de merge -> rc 1 HAUSSE-NON-IMPUTABLE"
else ko "FAIL hausse via resolution de merge" "rc=1 HAUSSE-NON-IMPUTABLE" "rc=$rc :: $out"; fi

# --- FAIL 6 : ligne de baseline retiree, fichier existe encore, sans citation ----------------------------
D="$(mk_repo fail6)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: retire a.md de la baseline sans citation (fichier reste)"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL ligne retiree, cible presente, sans citation -> rc 1"
else ko "FAIL ligne retiree cible presente sans citation" "rc=1 LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE" "rc=$rc :: $out"; fi

echo "== test-check-baseline-arbitrage : BRUYANT =="

# --- BRUYANT 1 : colonne non numerique a la base ---------------------------------------------------------
D="$(mk_repo bru1)"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}dix${TAB}5" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: colonne lignes non numerique a la base"
BAD="$(git_c "$D" rev-parse HEAD)"
git_c "$D" commit -q --allow-empty -m "chore: commit suivant, range non vide"
out="$(run "$D" --base-ref "$BAD")"; rc=$?
[ "$rc" -eq 2 ] && ok "BRUYANT colonne non numerique a la base -> rc 2" || ko "BRUYANT colonne non numerique" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 2 : baseline a deux champs a la base ---------------------------------------------------------
D="$(mk_repo bru2)"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: ligne a deux champs a la base"
BAD="$(git_c "$D" rev-parse HEAD)"
git_c "$D" commit -q --allow-empty -m "chore: commit suivant"
out="$(run "$D" --base-ref "$BAD")"; rc=$?
[ "$rc" -eq 2 ] && ok "BRUYANT baseline a deux champs -> rc 2" || ko "BRUYANT baseline a deux champs" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 3 : --base-ref vers une ref inexistante --------------------------------------------------------
D="$(mk_repo bru3)"
git_c "$D" commit -q --allow-empty -m "chore: avance HEAD"
out="$(run "$D" --base-ref "refs/heads/ref-inexistante-xyz")"; rc=$?
[ "$rc" -eq 2 ] && ok "BRUYANT --base-ref inexistante -> rc 2" || ko "BRUYANT --base-ref inexistante" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 4 : --root hors d'un arbre git ------------------------------------------------------------------
NOGIT="$TMP/nogit"
mkdir -p "$NOGIT"
out="$(run "$NOGIT")"; rc=$?
[ "$rc" -eq 2 ] && ok "BRUYANT --root hors d'un arbre git -> rc 2" || ko "BRUYANT --root hors d'un arbre git" "rc=2" "rc=$rc :: $out"

echo "== test-check-baseline-arbitrage : SILENCE =="

# --- SILENCE 1 : --base-ref egal a HEAD -----------------------------------------------------------------------
D="$(mk_repo sil1)"
H="$(git_c "$D" rev-parse HEAD)"
out="$(run "$D" --base-ref "$H")"; rc=$?
case "$out" in *PLAGE-VIDE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "SILENCE --base-ref egal HEAD -> rc 3 PLAGE-VIDE"
else ko "SILENCE --base-ref egal HEAD" "rc=3 PLAGE-VIDE" "rc=$rc :: $out"; fi

# --- SILENCE 2 : plage ne portant que des commits de merge -----------------------------------------------------
D="$(mk_repo sil2)"
git_c "$D" checkout -q -b side
git_c "$D" commit -q --allow-empty -m "chore(side): commit non-merge"
S1="$(git_c "$D" rev-parse HEAD)"
git_c "$D" checkout -q main
git_c "$D" merge -q --no-ff -m "merge: fusion side (range ne portant que ce merge)" side >/dev/null
out="$(run "$D" --base-ref "$S1")"; rc=$?
case "$out" in *PLAGE-VIDE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "SILENCE plage ne portant que des merges -> rc 3"
else ko "SILENCE plage ne portant que des merges" "rc=3 PLAGE-VIDE" "rc=$rc :: $out"; fi

echo "== test-check-baseline-arbitrage : USAGE =="

out="$(bash "$TARGET" --root "$TMP" --option-bidon 2>&1)"; rc=$?
[ "$rc" -eq 64 ] && ok "USAGE option inconnue -> 64" || ko "USAGE option inconnue" "rc=64" "rc=$rc :: $out"

out="$(bash "$TARGET" --root "$TMP/chemin-inexistant-xyz" 2>&1)"; rc=$?
[ "$rc" -eq 64 ] && ok "USAGE --root inexistant -> 64" || ko "USAGE --root inexistant" "rc=64" "rc=$rc :: $out"

out="$(bash "$TARGET" --root "$TMP" --base-ref 2>&1)"; rc=$?
[ "$rc" -eq 64 ] && ok "USAGE --base-ref sans valeur -> 64" || ko "USAGE --base-ref sans valeur" "rc=64" "rc=$rc :: $out"

echo "== test-check-baseline-arbitrage : CONTROLES NEGATIFS (doivent rester rc 0) =="

# --- NEG 1 : hausse seule colonne LIGNES, sans citation -------------------------------------------------------
D="$(mk_repo neg1)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}15${TAB}5" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: a.md lignes 10->15, instructions inchangees, sans citation"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *AVERTISSEMENT-LIGNES-EN-HAUSSE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "NEG hausse lignes seule sans citation -> rc 0 + AVERTISSEMENT-LIGNES-EN-HAUSSE"
else ko "NEG hausse lignes seule sans citation" "rc=0 AVERTISSEMENT-LIGNES-EN-HAUSSE" "rc=$rc :: $out"; fi

# --- NEG 2 : retrait de ligne, fichier disparu -----------------------------------------------------------------
D="$(mk_repo neg2)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
rm -f "$D/plugin/demo/a.md"
commit_avec "$D" "chore: retire a.md de la baseline et du depot, sans citation"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *AVERTISSEMENT-LIGNE-RETIREE-CIBLE-DISPARUE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "NEG retrait ligne, cible disparue -> rc 0"
else ko "NEG retrait ligne cible disparue" "rc=0 AVERTISSEMENT-LIGNE-RETIREE-CIBLE-DISPARUE" "rc=$rc :: $out"; fi

# --- NEG 3 : retrait de ligne, fichier existe encore, citation conforme -----------------------------------------
D="$(mk_repo neg3)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: retire a.md de la baseline, fichier conserve

arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"
out="$(run "$D" --base-ref "$B")"; rc=$?
case "$out" in *AVERTISSEMENT-LIGNE-RETIREE-ARBITREE*) hasw=1 ;; *) hasw=0 ;; esac
case "$out" in *"arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"*) hascit=1 ;; *) hascit=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasw" -eq 1 ] && [ "$hascit" -eq 1 ]; then ok "NEG retrait ligne, cible presente, citation conforme -> rc 0, citation recopiee"
else ko "NEG retrait ligne cible presente citation conforme" "rc=0 AVERTISSEMENT-LIGNE-RETIREE-ARBITREE + citation recopiee" "rc=$rc :: $out"; fi

# --- NEG 4 : valeur zero-paddee legitime (007 face a 7, egalite numerique) --------------------------------------
D="$(mk_repo neg4)"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}007" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: base zero-paddee 007"
B2="$(git_c "$D" rev-parse HEAD)"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}7" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: meme valeur ecrite sans zero-padding (007 == 7)"
out="$(run "$D" --base-ref "$B2")"; rc=$?
[ "$rc" -eq 0 ] && ok "NEG valeur zero-paddee 007 == 7 -> rc 0" || ko "NEG valeur zero-paddee" "rc=0" "rc=$rc :: $out"

echo "== test-check-baseline-arbitrage : MUTANTS (MUT-1 a MUT-9) =="

# --- MUT-1 : neutralise la comparaison numerique de hausse d'INSTRUCTIONS ----------------------------------------
MUT1_OLD='      if [ "$((10#${hi:-0}))" -gt "$((10#${bi:-0}))" ]; then instr_over=1; fi'
MUT1_NEW='      if [ "0" = "1" ]; then instr_over=1; fi'
MUT1_PATH="$(make_mutant mut1 "$MUT1_OLD" "$MUT1_NEW")"; MUT1_STAT=$?
D="$(mk_repo mut1)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: hausse instructions a.md sans citation (fixture MUT-1)"
if [ "$MUT1_STAT" -eq 1 ]; then komut 1 "comparaison INSTRUCTIONS neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT1_STAT" -eq 2 ]; then komut 1 "comparaison INSTRUCTIONS neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT1_PATH"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 1 "$rc_mut" 0 "$rc_orig" 1
  else komut 1 "comparaison INSTRUCTIONS neutralisee" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-2 : neutralise la verification de forme de la citation (toute ligne acceptee) ---------------------------
MUT2_OLD='    END { exit (found ? 0 : 1) }'
MUT2_NEW='    END { exit 0 }'
MUT2_PATH="$(make_mutant mut2 "$MUT2_OLD" "$MUT2_NEW")"; MUT2_STAT=$?
D="$(mk_repo mut2)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: hausse instructions a.md, citation faible

arbitrage"
if [ "$MUT2_STAT" -eq 1 ]; then komut 2 "verification de forme de la citation neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT2_STAT" -eq 2 ]; then komut 2 "verification de forme de la citation neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT2_PATH"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 2 "$rc_mut" 0 "$rc_orig" 1
  else komut 2 "verification de forme de la citation neutralisee" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-3 : neutralise la detection de disparition de sentinelle ------------------------------------------------
MUT3_OLD='  case "$status" in D|R*) neutralized=1 ;; esac'
MUT3_NEW='  case "$status" in ZZZ-JAMAIS) neutralized=1 ;; esac'
MUT3_PATH="$(make_mutant mut3 "$MUT3_OLD" "$MUT3_NEW")"; MUT3_STAT=$?
D="$(mk_repo mut3)"; B="$(base_of "$D")"
rm -f "$D/.planning/.instruction-budget-armed"
commit_avec "$D" "chore: retire la sentinelle armed sans citation (MUT-3)"
if [ "$MUT3_STAT" -eq 1 ]; then komut 3 "detection de disparition de sentinelle neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT3_STAT" -eq 2 ]; then komut 3 "detection de disparition de sentinelle neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT3_PATH"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 3 "$rc_mut" 0 "$rc_orig" 1
  else komut 3 "detection de disparition de sentinelle neutralisee" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-4 : remplace merge-base par l'adjacence HEAD^ -------------------------------------------------------------
MUT4_OLD='BASE="$(git merge-base HEAD "$REF_RESOLVED" 2>/dev/null)"'
MUT4_NEW='BASE="$(git rev-parse HEAD^ 2>/dev/null)"'
MUT4_PATH="$(make_mutant mut4 "$MUT4_OLD" "$MUT4_NEW")"; MUT4_STAT=$?
D="$(mk_repo mut4)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: commit 1 - hausse instructions a.md sans citation (MUT-4)"
printf 'v2\n' > "$D/plugin/demo/other.txt"
commit_avec "$D" "chore: commit 2 - fichier neutre"
printf 'v3\n' > "$D/plugin/demo/other.txt"
commit_avec "$D" "chore: commit 3 - fichier neutre encore"
if [ "$MUT4_STAT" -eq 1 ]; then komut 4 "derivation de la base par adjacence HEAD^" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT4_STAT" -eq 2 ]; then komut 4 "derivation de la base par adjacence HEAD^" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT4_PATH"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 4 "$rc_mut" 0 "$rc_orig" 1
  else komut 4 "derivation de la base par adjacence HEAD^" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-5 : neutralise l'assertion de decouverte non vide ---------------------------------------------------------
MUT5_OLD='if [ "$NONMERGE_COUNT" -eq 0 ]; then'
MUT5_NEW='if [ "0" = "1" ]; then'
MUT5_PATH="$(make_mutant mut5 "$MUT5_OLD" "$MUT5_NEW")"; MUT5_STAT=$?
D="$(mk_repo mut5)"
H="$(git_c "$D" rev-parse HEAD)"
if [ "$MUT5_STAT" -eq 1 ]; then komut 5 "assertion de decouverte non vide neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT5_STAT" -eq 2 ]; then komut 5 "assertion de decouverte non vide neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT5_PATH"; run "$D" --base-ref "$H" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$H" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 3 ]; then okmut 5 "$rc_mut" 0 "$rc_orig" 3
  else komut 5 "assertion de decouverte non vide neutralisee" "rc_mutant=0 rc_original=3" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-6 : rend BLOQUANTE la hausse de la colonne LIGNES ------------------------------------------------------------
MUT6_OLD='      if [ "$instr_over" -eq 1 ]; then'
MUT6_NEW='      if [ "$instr_over" -eq 1 ] || [ "$lignes_over" -eq 1 ]; then'
MUT6_PATH="$(make_mutant mut6 "$MUT6_OLD" "$MUT6_NEW")"; MUT6_STAT=$?
D="$(mk_repo mut6)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}15${TAB}5" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: a.md lignes 10->15 seul, sans citation (MUT-6)"
if [ "$MUT6_STAT" -eq 1 ]; then komut 6 "colonne LIGNES rendue bloquante" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT6_STAT" -eq 2 ]; then komut 6 "colonne LIGNES rendue bloquante" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT6_PATH"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 6 "$rc_mut" 1 "$rc_orig" 0
  else komut 6 "colonne LIGNES rendue bloquante" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-7 : force le test d'existence de la cible d'une ligne retiree a « absente » ------------------------------------
MUT7_OLD='  if git cat-file -e "${HEAD_SHA}:${p}" 2>/dev/null; then target_exists=1; fi'
MUT7_NEW='  if false; then target_exists=1; fi'
MUT7_PATH="$(make_mutant mut7 "$MUT7_OLD" "$MUT7_NEW")"; MUT7_STAT=$?
D="$(mk_repo mut7)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: retire a.md de la baseline sans citation, fichier reste (MUT-7)"
if [ "$MUT7_STAT" -eq 1 ]; then komut 7 "test d'existence de la cible force a absente" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT7_STAT" -eq 2 ]; then komut 7 "test d'existence de la cible force a absente" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT7_PATH"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 7 "$rc_mut" 0 "$rc_orig" 1
  else komut 7 "test d'existence de la cible force a absente" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-8 : force ce meme test a « presente » ---------------------------------------------------------------------------
MUT8_OLD='  if git cat-file -e "${HEAD_SHA}:${p}" 2>/dev/null; then target_exists=1; fi'
MUT8_NEW='  if true; then target_exists=1; fi'
MUT8_PATH="$(make_mutant mut8 "$MUT8_OLD" "$MUT8_NEW")"; MUT8_STAT=$?
D="$(mk_repo mut8)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
rm -f "$D/plugin/demo/a.md"
commit_avec "$D" "chore: retire a.md de la baseline et du depot (cible disparue, MUT-8)"
if [ "$MUT8_STAT" -eq 1 ]; then komut 8 "test d'existence de la cible force a presente" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT8_STAT" -eq 2 ]; then komut 8 "test d'existence de la cible force a presente" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT8_PATH"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 8 "$rc_mut" 1 "$rc_orig" 0
  else komut 8 "test d'existence de la cible force a presente" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-9 : neutralise l'echappatoire par citation du retrait de ligne -----------------------------------------------------
MUT9_OLD='    if printf '"'"'%s'"'"' "$msg" | citation_ok; then retrait_citation_ok=1; fi'
MUT9_NEW='    if false; then retrait_citation_ok=1; fi'
MUT9_PATH="$(make_mutant mut9 "$MUT9_OLD" "$MUT9_NEW")"; MUT9_STAT=$?
D="$(mk_repo mut9)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: retire a.md de la baseline, fichier conserve

arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"
if [ "$MUT9_STAT" -eq 1 ]; then komut 9 "echappatoire par citation du retrait de ligne neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT9_STAT" -eq 2 ]; then komut 9 "echappatoire par citation du retrait de ligne neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT9_PATH"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" --base-ref "$B" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 9 "$rc_mut" 1 "$rc_orig" 0
  else komut 9 "echappatoire par citation du retrait de ligne neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== bilan : $PASS ok, $FAIL ko =="
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
