#!/usr/bin/env bash
# test-check-baseline-arbitrage.sh — Suite de verification de check-baseline-arbitrage.sh (G-1,
# PROT-04, QUAL-01, plan 41-14). Patron : test-check-instruction-budget.sh
# (plugin/conductor/scripts/tests/). Chaque cas construit SON PROPRE depot jetable sous mktemp -d,
# JAMAIS le depot reel ; identite git passee par -c, jamais la configuration du poste ; comparaisons
# de fixtures par cmp et comm uniquement, jamais diff (proxifie menteur sur ce poste). Une suite
# incapable de rougir est un defaut, au meme titre que le gate qu'elle verifie.
#
# Trois issues QUAL-01 (PASS / FAIL / BRUYANT) plus SILENCE et USAGE, et NEUF mutants opposables
# d'origine (MUT-1 a MUT-9), un par comparaison du script sous test — regle de comptage (decision du manager,
# 2026-09-17) : chaque mutant asserte le rc EXACT attendu sur le mutant ET sur l'original. Un mutant
# qui « echoue » par un plantage (rc 2) ou une plage vide (rc 3) la ou le cas attendait un flip 0/1
# n'est PAS compte comme tue. La ligne de succes d'un mutant a une forme UNIQUE, exigee par le verify
# du plan : « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
# Section DELEGATION (2026-11-12) : une ligne portant le radical « delegu » ne vaut pas citation (hausse,
# retrait de ligne, sentinelle). Cinq verifications de mutant s'y ajoutent, soit QUATORZE au total :
# MUT-10 (exclusion retiree), MUT-10b (meme mutant, usage sentinelle), MUT-11 (radical reduit a « delegue »),
# MUT-12 (repli de l'accent combinant retire), MUT-13 (test de forme de la ligne d'information retire).
# MUT-10 a MUT-12 suivent le patron rc_mutant/rc_original ; MUT-13 compare la presence de la ligne
# INFO-LIGNE-DELEGATION-ECARTEE (rc 1 des deux cotes) et a sa propre ligne de succes.
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
  # precomposeunicode=false : sur macOS, la valeur par defaut (true) renormalise en NFC un message passe
  # par -m ; les cas DEL a accent combinant (NFD) seraient alors vides en local (revue F2).
  git_c "$root" -c core.precomposeunicode=false commit -q -m "$msg" >/dev/null
}

base_of() { git_c "$1" rev-list --max-parents=0 HEAD | tail -1; }

run() {  # <root> [args...] — invocation TOUJOURS via --root.
  local root="$1"; shift
  bash "$TARGET" --root "$root" "$@" 2>&1
}

# safe_run <var_out> <var_rc> <root> [args...] — invocation TOUJOURS via run() (donc via --root).
# Ecrit la sortie et le rc REEL de l'outil teste dans les variables nommees. Appelee comme
# instruction NUE (jamais entouree de $(...) par l'appelant) : `set +e`/`set -e` bascule alors
# l'etat REEL du shell courant (pas celui d'un sous-shell jetable) — le seul moyen de faire
# cohabiter `bash -e` (impose par le verify du plan) avec un rc de fixture volontairement non nul,
# sans perdre l'affectation dans un sous-shell de substitution de commande. AVANT ce correctif,
# tout `out="$(run ...)"; rc=$?` faisait sortir ce script sous `bash -e` des le premier cas
# attendant un rc non nul (toute la section FAIL, BRUYANT, SILENCE, USAGE et les dix-huit
# invocations de mutants) — la suite s'arretait apres PASS 6/6, sans jamais atteindre son bilan.
# Meme patron que tools/test-check-aucune-fermeture.sh (plan 41-15, Task 1) ; correctif applique
# ici au meme defaut, mesure empiriquement sur ce fichier (mandat elargi du manager de mission,
# reprise du 2026-09-18, point 4).
safe_run() {
  local __vout="$1" __vrc="$2" __root="$3"; shift 3
  local __out __rc
  set +e
  __out="$(run "$__root" "$@")"
  __rc=$?
  set -e
  eval "$__vout=\$__out"
  eval "$__vrc=\$__rc"
}

# make_mutant <name> <old> <new> -> imprime le chemin du mutant ; retour 0 = opposable et valide,
# 1 = identique a l'original (NON OPPOSABLE), 2 = syntaxe invalide.
make_mutant() {
  local name="$1" old="$2" new="$3"
  local out="$MUTD/${name}.sh"
  # ENVIRON et non -v : awk -v interprete les echappements (\314 deviendrait un octet), le mutant ne
  # retrouverait plus la ligne a remplacer.
  MUT_OLD="$old" MUT_NEW="$new" awk '{ if ($0 == ENVIRON["MUT_OLD"]) { print ENVIRON["MUT_NEW"] } else { print } }' "$SCRIPT" > "$out"
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
safe_run out rc "$D" --base-ref "$B"
case "$out" in *CONFORME*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "PASS rien ne change -> rc 0 CONFORME"
else ko "PASS rien ne change" "rc=0 CONFORME" "rc=$rc :: $out"; fi

# --- PASS 2 : baisse d'une valeur --------------------------------------------------------------------
D="$(mk_repo pass2)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}3" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: baisse instructions a.md"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS baisse de valeur -> rc 0" || ko "PASS baisse de valeur" "rc=0" "rc=$rc :: $out"

# --- PASS 3 : ajout d'une ligne -----------------------------------------------------------------------
D="$(mk_repo pass3)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}5" "plugin/demo/b.md${TAB}20${TAB}8" "plugin/demo/c.md${TAB}5${TAB}2" | w_baseline "$D"
printf 'c\n' > "$D/plugin/demo/c.md"
commit_avec "$D" "feat: ajout c.md"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS ajout de ligne -> rc 0" || ko "PASS ajout de ligne" "rc=0" "rc=$rc :: $out"

# --- PASS 4 : hausse AVEC citation conforme ------------------------------------------------------------
D="$(mk_repo pass4)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "feat: hausse instructions a.md

arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS hausse avec citation conforme -> rc 0" || ko "PASS hausse avec citation conforme" "rc=0" "rc=$rc :: $out"

# --- PASS 5 : hausse avec citation « arbitrages » au pluriel --------------------------------------------
D="$(mk_repo pass5)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "feat: hausse instructions a.md

arbitrages Samuel, AskUserQuestion session principale, 2026-09-17"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS hausse avec citation 'arbitrages' pluriel -> rc 0" || ko "PASS hausse avec citation pluriel" "rc=0" "rc=$rc :: $out"

# --- PASS 6 : sentinelle deja vide (0 octet) SUPPRIMEE avec citation conforme -> rc 0 (regression : -----
# --- la premiere version du culprit-walk exigeait une taille prealable non nulle, donc ne trouvait ------
# --- jamais le commit fautif pour une sentinelle DEJA vide -> citation jamais lue -> rc1 a tort) --------
D="$(mk_repo pass6)"; B="$(base_of "$D")"
rm -f "$D/.planning/.instruction-budget-armed"
commit_avec "$D" "chore: retire la sentinelle armed (deja vide) AVEC citation

arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS sentinelle deja vide, supprimee avec citation conforme -> rc 0" || ko "PASS sentinelle deja vide supprimee avec citation" "rc=0" "rc=$rc :: $out"

echo "== test-check-baseline-arbitrage : FAIL =="

# --- FAIL 1 : hausse INSTRUCTIONS sans citation ---------------------------------------------------------
D="$(mk_repo fail1)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "feat: hausse instructions a.md sans citation"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *HAUSSE-SANS-ARBITRAGE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL hausse sans citation -> rc 1 HAUSSE-SANS-ARBITRAGE"
else ko "FAIL hausse sans citation" "rc=1 HAUSSE-SANS-ARBITRAGE" "rc=$rc :: $out"; fi

# --- FAIL 2 : citation sans canal ni date (mot « arbitrage » seul) --------------------------------------
D="$(mk_repo fail2)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "feat: hausse instructions a.md, citation faible

arbitrage"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *HAUSSE-SANS-ARBITRAGE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL citation sans canal ni date -> rc 1"
else ko "FAIL citation sans canal ni date" "rc=1 HAUSSE-SANS-ARBITRAGE" "rc=$rc :: $out"; fi

# --- FAIL 3 : sentinelle supprimee sans citation --------------------------------------------------------
D="$(mk_repo fail3)"; B="$(base_of "$D")"
rm -f "$D/.planning/.instruction-budget-armed"
commit_avec "$D" "chore: retire la sentinelle armed sans citation"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *SENTINELLE-NEUTRALISEE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL sentinelle supprimee sans citation -> rc 1"
else ko "FAIL sentinelle supprimee sans citation" "rc=1 SENTINELLE-NEUTRALISEE" "rc=$rc :: $out"; fi

# --- FAIL 4 : sentinelle non vide videe sans citation ----------------------------------------------------
D="$(mk_repo fail4)"; B="$(base_of "$D")"
: > "$D/.planning/.requirements-survival-armed"
commit_avec "$D" "chore: vide la sentinelle requirements-survival sans citation"
safe_run out rc "$D" --base-ref "$B"
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
safe_run out rc "$D" --base-ref "$B"
case "$out" in *HAUSSE-NON-IMPUTABLE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL hausse via resolution de merge -> rc 1 HAUSSE-NON-IMPUTABLE"
else ko "FAIL hausse via resolution de merge" "rc=1 HAUSSE-NON-IMPUTABLE" "rc=$rc :: $out"; fi

# --- FAIL 6 : ligne de baseline retiree, fichier existe encore, sans citation ----------------------------
D="$(mk_repo fail6)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: retire a.md de la baseline sans citation (fichier reste)"
safe_run out rc "$D" --base-ref "$B"
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
safe_run out rc "$D" --base-ref "$BAD"
[ "$rc" -eq 2 ] && ok "BRUYANT colonne non numerique a la base -> rc 2" || ko "BRUYANT colonne non numerique" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 2 : baseline a deux champs a la base ---------------------------------------------------------
D="$(mk_repo bru2)"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: ligne a deux champs a la base"
BAD="$(git_c "$D" rev-parse HEAD)"
git_c "$D" commit -q --allow-empty -m "chore: commit suivant"
safe_run out rc "$D" --base-ref "$BAD"
[ "$rc" -eq 2 ] && ok "BRUYANT baseline a deux champs -> rc 2" || ko "BRUYANT baseline a deux champs" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 5 : colonne non numerique a HEAD (reproduction exacte de la revue, finding F1) ---------------
# La base reste valide (fixture mk_repo) ; c'est HEAD qui porte la valeur imparsable. Avant le fix,
# la comparaison arithmetique `$((10#${hi:-0}))` sur "NONNUM" plantait sous `set -uo pipefail` (sans
# -e), l'erreur arithmetique etait avalee et le script rendait CONFORME/rc 0 malgre la hausse non
# imputable a une citation.
D="$(mk_repo bru5)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "demo/a.md${TAB}10${TAB}NONNUM" | w_baseline "$D"
commit_avec "$D" "chore: colonne instructions non numerique a HEAD, sans citation"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 2 ] && ok "BRUYANT colonne non numerique a HEAD -> rc 2" || ko "BRUYANT colonne non numerique a HEAD" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 6 : baseline a deux champs a HEAD --------------------------------------------------------------
D="$(mk_repo bru6)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: ligne a deux champs a HEAD"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 2 ] && ok "BRUYANT baseline a deux champs a HEAD -> rc 2" || ko "BRUYANT baseline a deux champs a HEAD" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 3 : --base-ref vers une ref inexistante --------------------------------------------------------
D="$(mk_repo bru3)"
git_c "$D" commit -q --allow-empty -m "chore: avance HEAD"
safe_run out rc "$D" --base-ref "refs/heads/ref-inexistante-xyz"
[ "$rc" -eq 2 ] && ok "BRUYANT --base-ref inexistante -> rc 2" || ko "BRUYANT --base-ref inexistante" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 4 : --root hors d'un arbre git ------------------------------------------------------------------
NOGIT="$TMP/nogit"
mkdir -p "$NOGIT"
safe_run out rc "$NOGIT"
[ "$rc" -eq 2 ] && ok "BRUYANT --root hors d'un arbre git -> rc 2" || ko "BRUYANT --root hors d'un arbre git" "rc=2" "rc=$rc :: $out"

echo "== test-check-baseline-arbitrage : SILENCE =="

# --- SILENCE 1 : --base-ref egal a HEAD -----------------------------------------------------------------------
D="$(mk_repo sil1)"
H="$(git_c "$D" rev-parse HEAD)"
safe_run out rc "$D" --base-ref "$H"
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
safe_run out rc "$D" --base-ref "$S1"
case "$out" in *PLAGE-VIDE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "SILENCE plage ne portant que des merges -> rc 3"
else ko "SILENCE plage ne portant que des merges" "rc=3 PLAGE-VIDE" "rc=$rc :: $out"; fi

echo "== test-check-baseline-arbitrage : USAGE =="

safe_run out rc "$TMP" --option-bidon
[ "$rc" -eq 64 ] && ok "USAGE option inconnue -> 64" || ko "USAGE option inconnue" "rc=64" "rc=$rc :: $out"

safe_run out rc "$TMP/chemin-inexistant-xyz"
[ "$rc" -eq 64 ] && ok "USAGE --root inexistant -> 64" || ko "USAGE --root inexistant" "rc=64" "rc=$rc :: $out"

safe_run out rc "$TMP" --base-ref
[ "$rc" -eq 64 ] && ok "USAGE --base-ref sans valeur -> 64" || ko "USAGE --base-ref sans valeur" "rc=64" "rc=$rc :: $out"

echo "== test-check-baseline-arbitrage : CONTROLES NEGATIFS (doivent rester rc 0) =="

# --- NEG 1 : hausse seule colonne LIGNES, sans citation -------------------------------------------------------
D="$(mk_repo neg1)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}15${TAB}5" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: a.md lignes 10->15, instructions inchangees, sans citation"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *AVERTISSEMENT-LIGNES-EN-HAUSSE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "NEG hausse lignes seule sans citation -> rc 0 + AVERTISSEMENT-LIGNES-EN-HAUSSE"
else ko "NEG hausse lignes seule sans citation" "rc=0 AVERTISSEMENT-LIGNES-EN-HAUSSE" "rc=$rc :: $out"; fi

# --- NEG 2 : retrait de ligne, fichier disparu -----------------------------------------------------------------
D="$(mk_repo neg2)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
rm -f "$D/plugin/demo/a.md"
commit_avec "$D" "chore: retire a.md de la baseline et du depot, sans citation"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *AVERTISSEMENT-LIGNE-RETIREE-CIBLE-DISPARUE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "NEG retrait ligne, cible disparue -> rc 0"
else ko "NEG retrait ligne cible disparue" "rc=0 AVERTISSEMENT-LIGNE-RETIREE-CIBLE-DISPARUE" "rc=$rc :: $out"; fi

# --- NEG 3 : retrait de ligne, fichier existe encore, citation conforme -----------------------------------------
D="$(mk_repo neg3)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: retire a.md de la baseline, fichier conserve

arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"
safe_run out rc "$D" --base-ref "$B"
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
safe_run out rc "$D" --base-ref "$B2"
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
  TARGET="$MUT1_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
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
  TARGET="$MUT2_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
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
  TARGET="$MUT3_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
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
  TARGET="$MUT4_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
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
  TARGET="$MUT5_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$H"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$H"
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
  TARGET="$MUT6_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
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
  TARGET="$MUT7_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
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
  TARGET="$MUT8_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
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
  TARGET="$MUT9_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 9 "$rc_mut" 1 "$rc_orig" 0
  else komut 9 "echappatoire par citation du retrait de ligne neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== test-check-baseline-arbitrage : DELEGATION (une ligne de delegation ne vaut pas arbitrage) =="

# Une ligne du message qui porte le radical « delegu » (toute casse, avec ou sans accent) ne vaut JAMAIS
# citation, meme si elle porte « decision », deux virgules et une date : c'est la forme exacte d'une
# decision DELEGUEE, pas d'un arbitrage direct. La regle vaut pour TOUS les usages de la citation :
# hausse, retrait de ligne dont la cible existe encore, neutralisation de sentinelle. Le mot-cle
# « décision » reste volontairement en minuscules accentuees dans toutes les lignes de delegation
# ci-dessous : seule l'exclusion du radical peut alors les faire rougir.
DIRECT='arbitrage Samuel, AskUserQuestion session principale, 2026-09-17'
deleg_ligne() { printf 'décision %s par Samuel (message session principale, 2026-11-08), option recommandée' "$1"; }
DELEG="$(deleg_ligne déléguée)"
NFD_ACUTE="$(printf '\314\201')"

# cas_hausse <nom> <message> -> out, rc (hausse de a.md 5 -> 9 portee par un commit au message donne)
cas_hausse() {
  D="$(mk_repo "$1")"; B="$(base_of "$D")"
  printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
  commit_avec "$D" "$2"
  safe_run out rc "$D" --base-ref "$B"
}
# cas_retrait <nom> <message> -> out, rc (ligne a.md retiree de la baseline, fichier conserve)
cas_retrait() {
  D="$(mk_repo "$1")"; B="$(base_of "$D")"
  printf '%s\n' '# baseline de fixture' "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
  commit_avec "$D" "$2"
  safe_run out rc "$D" --base-ref "$B"
}
# cas_sentinelle <nom> <message> -> out, rc (sentinelle armed supprimee)
cas_sentinelle() {
  D="$(mk_repo "$1")"; B="$(base_of "$D")"
  rm -f "$D/.planning/.instruction-budget-armed"
  commit_avec "$D" "$2"
  safe_run out rc "$D" --base-ref "$B"
}

# --- DEL 1 : hausse dont la SEULE citation est la ligne de delegation -> rc 1 -----------------------
cas_hausse del1 "feat: hausse instructions a.md

${DELEG}"
case "$out" in *HAUSSE-SANS-ARBITRAGE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "DEL hausse, ligne de delegation seule -> rc 1 HAUSSE-SANS-ARBITRAGE"
else ko "DEL hausse, ligne de delegation seule" "rc=1 HAUSSE-SANS-ARBITRAGE" "rc=$rc :: $out"; fi
case "$out" in *INFO-LIGNE-DELEGATION-ECARTEE:*) hasinfo=1 ;; *) hasinfo=0 ;; esac
[ "$hasinfo" -eq 1 ] && ok "DEL refus hausse, delegation seule -> INFO-LIGNE-DELEGATION-ECARTEE presente" \
  || ko "DEL refus hausse, delegation seule : ligne d'information" "INFO-LIGNE-DELEGATION-ECARTEE presente" "absente :: $out"

# La derniere ligne de sortie d'un refus reste la ligne de verdict (l'etape CI en prend `tail -1`)
last="$(printf '%s\n' "$out" | tail -1)"
case "$last" in HAUSSE-SANS-ARBITRAGE:*) lastok=1 ;; *) lastok=0 ;; esac
[ "$lastok" -eq 1 ] && ok "DEL refus hausse, delegation seule -> derniere ligne = verdict" \
  || ko "DEL refus hausse, delegation seule : derniere ligne" "HAUSSE-SANS-ARBITRAGE: ..." "derniere ligne = $last"

# --- DEL 1b : refus sans aucune ligne de delegation -> pas de ligne d'information ----------------------------
cas_hausse del1b "feat: hausse instructions a.md sans citation"
case "$out" in *INFO-LIGNE-DELEGATION-ECARTEE*) hasinfo=1 ;; *) hasinfo=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$hasinfo" -eq 0 ]; then ok "DEL refus hausse sans delegation -> rc 1, pas de ligne d'information"
else ko "DEL refus hausse sans delegation" "rc=1 sans INFO-LIGNE-DELEGATION-ECARTEE" "rc=$rc :: $out"; fi

# --- DEL 1c : refus dont le message porte une ligne de delegation NON formee (sans date ni virgules) -> pas d'info
cas_hausse del1c "feat: hausse instructions a.md

décision déléguée par Samuel"
case "$out" in *INFO-LIGNE-DELEGATION-ECARTEE*) hasinfo=1 ;; *) hasinfo=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$hasinfo" -eq 0 ]; then ok "DEL refus, ligne de delegation non formee -> rc 1, pas de ligne d'information"
else ko "DEL refus, ligne de delegation non formee" "rc=1 sans INFO-LIGNE-DELEGATION-ECARTEE" "rc=$rc :: $out"; fi

# --- DEL 2 : citation directe seule, sur plusieurs lignes de corps -> rc 0 ----------------------------
cas_hausse del2 "feat: hausse instructions a.md

Contexte de la hausse.
${DIRECT}
Fin du message."
[ "$rc" -eq 0 ] && ok "DEL hausse, citation directe seule -> rc 0" || ko "DEL hausse, citation directe seule" "rc=0" "rc=$rc :: $out"

# --- DEL 3 : citation directe ET ligne de delegation, deux lignes distinctes -> rc 0 ------------------
cas_hausse del3 "feat: hausse instructions a.md

${DELEG}
${DIRECT}"
[ "$rc" -eq 0 ] && ok "DEL hausse, citation directe + ligne de delegation -> rc 0" || ko "DEL hausse, citation directe + delegation" "rc=0" "rc=$rc :: $out"

# --- DEL 3b : meme chose, delegation APRES la citation directe -> rc 0 ---------------------------------
cas_hausse del3b "feat: hausse instructions a.md

${DIRECT}
${DELEG}"
[ "$rc" -eq 0 ] && ok "DEL hausse, citation directe puis ligne de delegation -> rc 0" || ko "DEL hausse, directe puis delegation" "rc=0" "rc=$rc :: $out"

# --- DEL 4 : formes du radical, chacune SEULE -> rc 1 (casse, accents, forme decomposee) ---------------
n=0
for forme in "delegue" "DÉLÉGUÉE" "Déléguée" "DELEGUEE" "délègue" "DéLéGuée" "déléguons" "déléguant" "DÉLÉGUANT" "de${NFD_ACUTE}le${NFD_ACUTE}guee" "DE${NFD_ACUTE}LE${NFD_ACUTE}GUEE"; do
  n=$((n + 1))
  cas_hausse "del4-$n" "feat: hausse instructions a.md

$(deleg_ligne "$forme")"
  case "$out" in *HAUSSE-SANS-ARBITRAGE*) has=1 ;; *) has=0 ;; esac
  if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "DEL forme « ${forme} » seule -> rc 1 HAUSSE-SANS-ARBITRAGE"
  else ko "DEL forme « ${forme} » seule" "rc=1 HAUSSE-SANS-ARBITRAGE" "rc=$rc :: $out"; fi
done

# --- DEL 4b : une forme de delegation + citation directe -> rc 0 (formes sans accent et majuscules) ----
n=0
for forme in "delegue" "DÉLÉGUÉE" "Déléguée"; do
  n=$((n + 1))
  cas_hausse "del4b-$n" "feat: hausse instructions a.md

$(deleg_ligne "$forme")
${DIRECT}"
  [ "$rc" -eq 0 ] && ok "DEL forme « ${forme} » + citation directe -> rc 0" || ko "DEL forme « ${forme} » + citation directe" "rc=0" "rc=$rc :: $out"
done

# --- DEL 5 : retrait de ligne, cible presente, delegation seule -> rc 1 ----------------------------------
cas_retrait del5 "chore: retire a.md de la baseline, fichier conserve

${DELEG}"
case "$out" in *LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "DEL retrait cible presente, delegation seule -> rc 1 LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE"
else ko "DEL retrait cible presente, delegation seule" "rc=1 LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE" "rc=$rc :: $out"; fi
case "$out" in *INFO-LIGNE-DELEGATION-ECARTEE:*) hasinfo=1 ;; *) hasinfo=0 ;; esac
[ "$hasinfo" -eq 1 ] && ok "DEL refus retrait, delegation seule -> INFO-LIGNE-DELEGATION-ECARTEE presente" \
  || ko "DEL refus retrait, delegation seule : ligne d'information" "INFO-LIGNE-DELEGATION-ECARTEE presente" "absente :: $out"
last="$(printf '%s\n' "$out" | tail -1)"
case "$last" in LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE:*) lastok=1 ;; *) lastok=0 ;; esac
[ "$lastok" -eq 1 ] && ok "DEL refus retrait, delegation seule -> derniere ligne = verdict" \
  || ko "DEL refus retrait, delegation seule : derniere ligne" "LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE: ..." "derniere ligne = $last"

# --- DEL 6 : retrait de ligne, delegation + citation directe -> rc 0, la ligne DIRECTE est recopiee -------
cas_retrait del6 "chore: retire a.md de la baseline, fichier conserve

${DELEG}
${DIRECT}"
case "$out" in *AVERTISSEMENT-LIGNE-RETIREE-ARBITREE*) hasw=1 ;; *) hasw=0 ;; esac
case "$out" in *"citation : ${DIRECT}"*) hascit=1 ;; *) hascit=0 ;; esac
case "$out" in *"option recommandée"*) hasdel=1 ;; *) hasdel=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasw" -eq 1 ] && [ "$hascit" -eq 1 ] && [ "$hasdel" -eq 0 ]; then
  ok "DEL retrait cible presente, delegation + directe -> rc 0, ligne directe recopiee, jamais la delegation"
else ko "DEL retrait cible presente, delegation + directe" "rc=0 AVERTISSEMENT-LIGNE-RETIREE-ARBITREE, citation = ligne directe, delegation absente de la sortie" "rc=$rc :: $out"; fi

# --- DEL 7 : sentinelle supprimee, delegation seule -> rc 1 ------------------------------------------------
cas_sentinelle del7 "chore: retire la sentinelle armed

${DELEG}"
case "$out" in *SENTINELLE-NEUTRALISEE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "DEL sentinelle supprimee, delegation seule -> rc 1 SENTINELLE-NEUTRALISEE"
else ko "DEL sentinelle supprimee, delegation seule" "rc=1 SENTINELLE-NEUTRALISEE" "rc=$rc :: $out"; fi
case "$out" in *INFO-LIGNE-DELEGATION-ECARTEE:*) hasinfo=1 ;; *) hasinfo=0 ;; esac
[ "$hasinfo" -eq 1 ] && ok "DEL refus sentinelle, delegation seule -> INFO-LIGNE-DELEGATION-ECARTEE presente" \
  || ko "DEL refus sentinelle, delegation seule : ligne d'information" "INFO-LIGNE-DELEGATION-ECARTEE presente" "absente :: $out"
last="$(printf '%s\n' "$out" | tail -1)"
case "$last" in SENTINELLE-NEUTRALISEE:*) lastok=1 ;; *) lastok=0 ;; esac
[ "$lastok" -eq 1 ] && ok "DEL refus sentinelle, delegation seule -> derniere ligne = verdict" \
  || ko "DEL refus sentinelle, delegation seule : derniere ligne" "SENTINELLE-NEUTRALISEE: ..." "derniere ligne = $last"

# --- DEL 8 : sentinelle supprimee, delegation + citation directe -> rc 0 ------------------------------------
cas_sentinelle del8 "chore: retire la sentinelle armed

${DELEG}
${DIRECT}"
[ "$rc" -eq 0 ] && ok "DEL sentinelle supprimee, delegation + directe -> rc 0" || ko "DEL sentinelle supprimee, delegation + directe" "rc=0" "rc=$rc :: $out"

# --- DEL 9 : sentinelle non vide videe, delegation seule -> rc 1 (voie M -> taille nulle) ------------------
D="$(mk_repo del9)"; B="$(base_of "$D")"
: > "$D/.planning/.requirements-survival-armed"
commit_avec "$D" "chore: vide la sentinelle requirements-survival

${DELEG}"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *SENTINELLE-NEUTRALISEE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "DEL sentinelle videe, delegation seule -> rc 1 SENTINELLE-NEUTRALISEE"
else ko "DEL sentinelle videe, delegation seule" "rc=1 SENTINELLE-NEUTRALISEE" "rc=$rc :: $out"; fi

# ===================================================================================================
# Radical elargi a « deleg » (precision du 2026-11-12, decision de la session principale) : « delegation »,
# « delegate », « DÉLÉGATION » sont ecartes comme « deleguee ». Memes usages, memes temoins.
# ===================================================================================================
deleg2_ligne() { printf 'décision prise par %s de Samuel (message session principale, 2026-11-08), option recommandée' "$1"; }

# verifie_refus <libelle> <verdict> : rc 1, verdict present, INFO presente, derniere ligne = verdict
verifie_refus() {
  local lib="$1" verdict="$2" l
  case "$out" in *"${verdict}"*) has=1 ;; *) has=0 ;; esac
  case "$out" in *INFO-LIGNE-DELEGATION-ECARTEE:*) hasinfo=1 ;; *) hasinfo=0 ;; esac
  l="$(printf '%s\n' "$out" | tail -1)"
  case "$l" in "${verdict}:"*) lastok=1 ;; *) lastok=0 ;; esac
  if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ] && [ "$hasinfo" -eq 1 ] && [ "$lastok" -eq 1 ]; then ok "$lib -> rc 1 ${verdict}, INFO presente, derniere ligne = verdict"
  else ko "$lib" "rc=1 ${verdict}, INFO presente, derniere ligne = verdict" "rc=$rc info=$hasinfo derniere=$l :: $out"; fi
}

n=0
for forme in "délégation" "delegation" "delegate" "DÉLÉGATION"; do
  n=$((n + 1))
  cas_hausse "del10-$n" "feat: hausse instructions a.md

$(deleg2_ligne "$forme")"
  verifie_refus "DEL2 hausse, forme « ${forme} » seule" HAUSSE-SANS-ARBITRAGE
  cas_hausse "del10b-$n" "feat: hausse instructions a.md

$(deleg2_ligne "$forme")
${DIRECT}"
  [ "$rc" -eq 0 ] && ok "DEL2 hausse, forme « ${forme} » + citation directe -> rc 0" || ko "DEL2 hausse, forme « ${forme} » + citation directe" "rc=0" "rc=$rc :: $out"
done

for forme in "délégation" "delegate"; do
  cas_retrait "del11" "chore: retire a.md de la baseline, fichier conserve

$(deleg2_ligne "$forme")"
  verifie_refus "DEL2 retrait cible presente, forme « ${forme} » seule" LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE
  cas_retrait "del11b" "chore: retire a.md de la baseline, fichier conserve

$(deleg2_ligne "$forme")
${DIRECT}"
  case "$out" in *AVERTISSEMENT-LIGNE-RETIREE-ARBITREE*) hasw=1 ;; *) hasw=0 ;; esac
  case "$out" in *"citation : ${DIRECT}"*) hascit=1 ;; *) hascit=0 ;; esac
  case "$out" in *"option recommandée"*) hasdel=1 ;; *) hasdel=0 ;; esac
  if [ "$rc" -eq 0 ] && [ "$hasw" -eq 1 ] && [ "$hascit" -eq 1 ] && [ "$hasdel" -eq 0 ]; then ok "DEL2 retrait, forme « ${forme} » + directe -> rc 0, ligne directe recopiee"
  else ko "DEL2 retrait, forme « ${forme} » + directe" "rc=0 ARBITREE, citation = ligne directe, delegation absente" "rc=$rc :: $out"; fi

  cas_sentinelle "del12" "chore: retire la sentinelle armed

$(deleg2_ligne "$forme")"
  verifie_refus "DEL2 sentinelle supprimee, forme « ${forme} » seule" SENTINELLE-NEUTRALISEE
  cas_sentinelle "del12b" "chore: retire la sentinelle armed

$(deleg2_ligne "$forme")
${DIRECT}"
  [ "$rc" -eq 0 ] && ok "DEL2 sentinelle, forme « ${forme} » + directe -> rc 0" || ko "DEL2 sentinelle, forme « ${forme} » + directe" "rc=0" "rc=$rc :: $out"
done

# --- MUT-14 : remet le radical a « delegu » (« delegation », « delegate » doivent rester ecartes) ----------
MUT14_OLD='  return index(t, "deleg") > 0'
MUT14_NEW='  return index(t, "delegu") > 0'
MUT14_PATH="$(make_mutant mut14 "$MUT14_OLD" "$MUT14_NEW")"; MUT14_STAT=$?
cas_hausse mut14 "chore: hausse instructions a.md, forme delegation (MUT-14)

$(deleg2_ligne délégation)"
if [ "$MUT14_STAT" -ne 0 ]; then komut 14 "radical remis a delegu" "mutant opposable et valide" "statut mutant=$MUT14_STAT"
else
  D14="$D"; B14="$B"
  TARGET="$MUT14_PATH"; safe_run _mutout rc_mut "$D14" --base-ref "$B14"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D14" --base-ref "$B14"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 14 "$rc_mut" 0 "$rc_orig" 1
  else komut 14 "radical remis a delegu" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi
TARGET="$SCRIPT"

# --- MUT-10 : retire l'exclusion de la ligne de delegation (un seul point sert les trois usages) ----------
MUT10_OLD='  if (est_delegation(s)) return 0'
MUT10_NEW='  if (0) return 0'
MUT10_PATH="$(make_mutant mut10 "$MUT10_OLD" "$MUT10_NEW")"; MUT10_STAT=$?
D="$(mk_repo mut10)"; B="$(base_of "$D")"
printf '%s\n' '# baseline de fixture' "plugin/demo/a.md${TAB}10${TAB}9" "plugin/demo/b.md${TAB}20${TAB}8" | w_baseline "$D"
commit_avec "$D" "chore: hausse instructions a.md, delegation seule (MUT-10)

${DELEG}"
if [ "$MUT10_STAT" -eq 1 ]; then komut 10 "exclusion de la ligne de delegation retiree" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT10_STAT" -eq 2 ]; then komut 10 "exclusion de la ligne de delegation retiree" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT10_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 10 "$rc_mut" 0 "$rc_orig" 1
  else komut 10 "exclusion de la ligne de delegation retiree" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-10b : meme mutant, usage « sentinelle » : l'exclusion est bien au point UNIQUE ---------------------
D="$(mk_repo mut10b)"; B="$(base_of "$D")"
rm -f "$D/.planning/.instruction-budget-armed"
commit_avec "$D" "chore: retire la sentinelle armed, delegation seule (MUT-10b)

${DELEG}"
if [ "$MUT10_STAT" -eq 0 ]; then
  TARGET="$MUT10_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 10b "$rc_mut" 0 "$rc_orig" 1
  else komut 10b "exclusion retiree, usage sentinelle" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
else
  komut 10b "exclusion retiree, usage sentinelle" "mutant MUT-10 valide" "statut mutant=$MUT10_STAT"
fi

# --- MUT-11 : reduit le radical a « delegue » (une forme « deleguons » / « deleguant » doit rester ecartee) --
MUT11_OLD='  return index(t, "delegu") > 0'
MUT11_NEW='  return index(t, "delegue") > 0'
MUT11_PATH="$(make_mutant mut11 "$MUT11_OLD" "$MUT11_NEW")"; MUT11_STAT=$?
cas_hausse mut11 "chore: hausse instructions a.md, forme sans e (MUT-11)

$(deleg_ligne déléguons)"
if [ "$MUT11_STAT" -ne 0 ]; then komut 11 "radical reduit a delegue" "mutant opposable et valide" "statut mutant=$MUT11_STAT"
else
  D11="$D"; B11="$B"
  TARGET="$MUT11_PATH"; safe_run _mutout rc_mut "$D11" --base-ref "$B11"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D11" --base-ref "$B11"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 11 "$rc_mut" 0 "$rc_orig" 1
  else komut 11 "radical reduit a delegue" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-12 : retire le repli de l'accent combinant U+0301 (forme decomposee NFD) ------------------------------
MUT12_OLD='  gsub(/\314\201/, "", t)'
MUT12_NEW='  t = t'
MUT12_PATH="$(make_mutant mut12 "$MUT12_OLD" "$MUT12_NEW")"; MUT12_STAT=$?
cas_hausse mut12 "chore: hausse instructions a.md, forme NFD (MUT-12)

$(deleg_ligne "de${NFD_ACUTE}le${NFD_ACUTE}guee")"
# les octets NFD doivent etre REELLEMENT commites (macOS renormalise en NFC par defaut) : sinon le temoin est vide
if ! git_c "$D" log -1 --format=%B | od -An -tx1 | tr -d ' \n' | grep -q 'cc81'; then
  ko "MUT-12 fixture NFD" "octets cc81 dans le message commite" "absents (renormalises en NFC)"
fi
if [ "$MUT12_STAT" -ne 0 ]; then komut 12 "repli U+0301 retire" "mutant opposable et valide" "statut mutant=$MUT12_STAT"
else
  TARGET="$MUT12_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 12 "$rc_mut" 0 "$rc_orig" 1
  else komut 12 "repli U+0301 retire" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-13 : retire le test de forme de ligne_ecartee (toute ligne de delegation declencherait l'info) ------
MUT13_OLD='  return (est_delegation(s) && ligne_forme_ok(s)) ? 1 : 0'
MUT13_NEW='  return est_delegation(s) ? 1 : 0'
MUT13_PATH="$(make_mutant mut13 "$MUT13_OLD" "$MUT13_NEW")"; MUT13_STAT=$?
cas_hausse mut13 "chore: hausse instructions a.md, delegation non formee (MUT-13)

décision déléguée par Samuel"
if [ "$MUT13_STAT" -ne 0 ]; then komut 13 "test de forme de ligne_ecartee retire" "mutant opposable et valide" "statut mutant=$MUT13_STAT"
else
  TARGET="$MUT13_PATH"; safe_run out_mut rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig "$D" --base-ref "$B"
  case "$out_mut" in *INFO-LIGNE-DELEGATION-ECARTEE*) info_mut=1 ;; *) info_mut=0 ;; esac
  case "$out_orig" in *INFO-LIGNE-DELEGATION-ECARTEE*) info_orig=1 ;; *) info_orig=0 ;; esac
  if [ "$info_mut" -eq 1 ] && [ "$info_orig" -eq 0 ] && [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 1 ]; then
    echo "  ✓ MUT-13 TUE : info_mutant=1 attendu 1, info_original=0 attendu 0 (rc 1 des deux cotes)"; PASS=$((PASS + 1))
  else komut 13 "test de forme de ligne_ecartee retire" "info_mutant=1 info_original=0, rc 1 des deux" "info_mutant=$info_mut info_original=$info_orig rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== test-check-baseline-arbitrage : AUTO-DEFENSE (regression bash -e) =="

# --- AUTODEF 1 : la suite ELLE-MEME doit atteindre sa ligne de bilan sous invocation stricte
# `bash --noprofile --norc -e` (mandat elargi du manager de mission, reprise du 2026-09-18,
# point 4). AVANT le correctif safe_run de ce meme commit, cette meme suite, rejouee sous cette
# invocation, s'arretait silencieusement apres la section PASS (6/6 vertes) et n'atteignait
# JAMAIS cette ligne — c'est le defaut que ce cas prouve corrige. Garde de recursion
# (_TCBA_NORECURSE) : l'instance enfant SAUTE ce meme bloc, sinon recursion infinie (le fichier
# se relancerait lui-meme indefiniment).
if [ "${_TCBA_NORECURSE:-}" != "1" ]; then
  SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  set +e
  CHILD_OUT="$(_TCBA_NORECURSE=1 bash --noprofile --norc -e "$SELF" 2>&1)"
  CHILD_RC=$?
  set -e
  case "$CHILD_OUT" in *"== bilan : "*) reached_bilan=1 ;; *) reached_bilan=0 ;; esac
  if [ "$reached_bilan" -eq 1 ]; then
    ok "AUTODEF suite rejouee sous bash -e strict -> atteint sa ligne de bilan (rc enfant=$CHILD_RC)"
  else
    ko "AUTODEF suite rejouee sous bash -e strict -> atteint sa ligne de bilan" \
      "presence de '== bilan : ' dans la sortie de l'enfant" \
      "rc enfant=$CHILD_RC, bilan absent — derniere ligne : $(printf '%s\n' "$CHILD_OUT" | tail -1)"
  fi
fi

echo "== bilan : $PASS ok, $FAIL ko =="
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
