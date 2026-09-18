#!/usr/bin/env bash
# test-check-gate-touche.sh — Suite de verification de check-gate-touche.sh (G-2, PROT-05,
# QUAL-01, plan 41-16). Patron : test-check-baseline-arbitrage.sh (plan 41-14). Chaque cas
# construit SON PROPRE depot jetable sous mktemp -d, JAMAIS le depot reel ; identite git passee
# par -c, jamais la configuration du poste ; comparaisons de fixtures par cmp/comm uniquement,
# jamais diff (proxifie menteur sur ce poste).
#
# LIMITE DE FOND, rappelee ici comme dans le script juge : cette garde peut etre modifiée par la
# PR qu'elle juge — elle, cette suite, et l'etape CI qui l'invoque — et rester verte. Une suite
# incapable de rougir est un defaut, au meme titre que le gate qu'elle verifie.
#
# Trois issues QUAL-01 (PASS / FAIL / BRUYANT) plus SILENCE et USAGE, et CINQ mutants opposables
# (MUT-1 a MUT-5), un par comparaison du script sous test — regle de comptage (decision du
# manager, 2026-09-17, reprise du plan 41-14) : chaque mutant asserte le rc EXACT attendu sur le
# mutant ET sur l'original. Un mutant qui « echoue » par un plantage (rc 2) ou une plage vide
# (rc 3) la ou le cas attendait un autre flip n'est PAS compte comme tue. La ligne de succes d'un
# mutant a une forme UNIQUE, exigee par le verify du plan :
# « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-gate-touche.sh"
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

# ===================================================================================================
# Constructeurs de fixture — depots jetables purs sous $TMP, jamais le depot reel.
# ===================================================================================================

git_c() {  # <root> <args...> — identite de fixture par -c, jamais la config du poste.
  local root="$1"; shift
  git -C "$root" -c user.name=CI -c user.email=ci@example.invalid -c commit.gpgsign=false "$@"
}

# mk_repo <name> -> imprime <path> ; depot jetable portant la surface reelle en miniature (les
# cinq classes, un chemin hors surface, un gate d'un AUTRE module) et un premier commit sur main.
mk_repo() {
  local d="$TMP/$1"
  mkdir -p "$d/scripts/tests" "$d/scripts/hooks" \
    "$d/plugin/conductor/scripts/tests" "$d/plugin/dev-orchestrator/scripts" \
    "$d/.github/workflows" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  git_c "$d" init -q -b main >/dev/null
  printf '#!/bin/sh\necho demo\n' > "$d/scripts/check-demo.sh"
  printf '#!/bin/sh\necho demo\n' > "$d/scripts/tests/test-check-demo.sh"
  printf '#!/bin/sh\necho demo\n' > "$d/plugin/conductor/scripts/check-demo.sh"
  printf '#!/bin/sh\necho demo\n' > "$d/plugin/conductor/scripts/tests/test-check-demo.sh"
  printf '#!/bin/sh\necho demo\n' > "$d/scripts/hooks/pre-push-demo"
  printf 'name: ci\n' > "$d/.github/workflows/ci.yml"
  printf '#!/bin/sh\necho autre module\n' > "$d/plugin/dev-orchestrator/scripts/check-demo.sh"
  printf '# demo readme\n' > "$d/README.md"
  git_c "$d" add -A >/dev/null
  git_c "$d" commit -q -m "fixture: etat initial" >/dev/null
  printf '%s' "$d"
}

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

# safe_run <var_out> <var_rc> <root> [args...] — invocation TOUJOURS via run() (donc via --root).
# Ecrit la sortie et le rc REEL de l'outil teste dans les variables nommees, sans jamais faire
# sortir CETTE suite sous `bash -e` (impose par le verify du plan) des le premier rc non nul —
# meme patron que test-check-baseline-arbitrage.sh (plan 41-14, correctif documente).
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
#
# NOTE : `awk -v` applique un traitement d'echappement C (POSIX) a sa valeur — `\/` y devient `/`,
# ce qui casse toute comparaison exacte `$0 == old` des lors que `old` contient un antislash
# (les motifs de la comparaison 1 en portent, ex. `[^\/]`). Les valeurs transitent donc par
# ENVIRON (variables d'environnement, jamais retraitees par awk) plutot que par -v.
make_mutant() {
  local name="$1" old="$2" new="$3"
  local out="$MUTD/${name}.sh"
  MUT_OLD_ENV="$old" MUT_NEW_ENV="$new" awk '
    { if ($0 == ENVIRON["MUT_OLD_ENV"]) { print ENVIRON["MUT_NEW_ENV"] } else { print } }
  ' "$SCRIPT" > "$out"
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

echo "== test-check-gate-touche : PASS =="

# --- PASS 1 : classe 1 (gate plugin/conductor) touchee, trailer exact -> rc0 ------------------------
D="$(mk_repo pass1)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/plugin/conductor/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate conductor

Gate-Touche: plugin/conductor/scripts/check-demo.sh — demo pour le cas PASS classe gate conductor"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *DECLARE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "PASS classe gate-conductor, trailer exact -> rc 0 DECLARE"
else ko "PASS classe gate-conductor" "rc=0 DECLARE" "rc=$rc :: $out"; fi

# --- PASS 2 : classe 2 (gate scripts/) touchee, trailer exact -> rc0 --------------------------------
D="$(mk_repo pass2)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts

Gate-Touche: scripts/check-demo.sh — demo pour le cas PASS classe gate scripts"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS classe gate-scripts, trailer exact -> rc 0" || ko "PASS classe gate-scripts" "rc=0" "rc=$rc :: $out"

# --- PASS 3 : classe 3a (suite plugin/conductor) touchee, trailer exact -> rc0 ----------------------
D="$(mk_repo pass3)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/plugin/conductor/scripts/tests/test-check-demo.sh"
commit_avec "$D" "test: touche suite conductor

Gate-Touche: plugin/conductor/scripts/tests/test-check-demo.sh — demo pour le cas PASS suite conductor"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS classe suite-conductor, trailer exact -> rc 0" || ko "PASS classe suite-conductor" "rc=0" "rc=$rc :: $out"

# --- PASS 4 : classe 3b (suite scripts/tests) touchee, trailer exact -> rc0 -------------------------
D="$(mk_repo pass4)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/tests/test-check-demo.sh"
commit_avec "$D" "test: touche suite scripts

Gate-Touche: scripts/tests/test-check-demo.sh — demo pour le cas PASS suite scripts"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS classe suite-scripts, trailer exact -> rc 0" || ko "PASS classe suite-scripts" "rc=0" "rc=$rc :: $out"

# --- PASS 5 : classe 4 (ci.yml) touchee, trailer exact -> rc0 ---------------------------------------
D="$(mk_repo pass5)"; B="$(base_of "$D")"
printf 'name: ci2\n' > "$D/.github/workflows/ci.yml"
commit_avec "$D" "chore: touche ci.yml

Gate-Touche: .github/workflows/ci.yml — demo pour le cas PASS classe ci"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS classe ci.yml, trailer exact -> rc 0" || ko "PASS classe ci.yml" "rc=0" "rc=$rc :: $out"

# --- PASS 6 : classe 5 (hooks/) touchee, trailer exact -> rc0 ---------------------------------------
D="$(mk_repo pass6)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/hooks/pre-push-demo"
commit_avec "$D" "chore: touche hook

Gate-Touche: scripts/hooks/pre-push-demo — demo pour le cas PASS classe hooks"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS classe hooks, trailer exact -> rc 0" || ko "PASS classe hooks" "rc=0" "rc=$rc :: $out"

# --- PASS 7 : chemin couvert par un motif glob -> rc0 -----------------------------------------------
D="$(mk_repo pass7)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts, couverture par motif

Gate-Touche: scripts/check-*.sh — couverture par motif glob pour tout le lot de gates scripts"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS couverture par motif glob -> rc 0" || ko "PASS couverture par motif glob" "rc=0" "rc=$rc :: $out"

# --- PASS 8 : trailer porte par un commit ULTERIEUR (portee branche) -> rc0 -------------------------
D="$(mk_repo pass8)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts sans trailer ici"
git_c "$D" commit -q --allow-empty -m "doc: couverture retroactive

Gate-Touche: scripts/check-demo.sh — couverture retroactive posee sur un commit ulterieur"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS trailer sur commit ulterieur (portee branche) -> rc 0" || ko "PASS trailer sur commit ulterieur" "rc=0" "rc=$rc :: $out"

# --- PASS 9 : trailer au separateur tiret simple (borne ASCII) -> rc0 -------------------------------
D="$(mk_repo pass9)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts, tiret simple

Gate-Touche: scripts/check-demo.sh - raison suffisamment longue avec un tiret simple ici"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS separateur tiret simple (borne ASCII) -> rc 0" || ko "PASS separateur tiret simple" "rc=0" "rc=$rc :: $out"

# --- PASS 10 : plusieurs chemins couverts par plusieurs trailers d'un meme commit -> rc0 -------------
D="$(mk_repo pass10)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/tests/test-check-demo.sh"
commit_avec "$D" "feat: touche deux chemins, deux trailers

Gate-Touche: scripts/check-demo.sh — premier chemin du lot couvert par ce commit
Gate-Touche: scripts/tests/test-check-demo.sh — second chemin du lot couvert par ce commit"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS deux chemins, deux trailers d'un meme commit -> rc 0" || ko "PASS deux chemins deux trailers" "rc=0" "rc=$rc :: $out"

# --- PASS 11 : chemin SUPPRIME mais declare -> rc0 ---------------------------------------------------
D="$(mk_repo pass11)"; B="$(base_of "$D")"
git_c "$D" rm -q scripts/check-demo.sh >/dev/null
commit_avec "$D" "chore: supprime le gate demo

Gate-Touche: scripts/check-demo.sh — suppression volontaire du gate demo, declaree"
safe_run out rc "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "PASS chemin supprime mais declare -> rc 0" || ko "PASS chemin supprime declare" "rc=0" "rc=$rc :: $out"

echo "== test-check-gate-touche : FAIL =="

# --- FAIL 1 : chemin de surface touche sans aucun trailer -> rc1 CHEMIN-NON-DECLARE ------------------
D="$(mk_repo fail1)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts sans trailer"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *CHEMIN-NON-DECLARE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL chemin surface sans trailer -> rc 1 CHEMIN-NON-DECLARE"
else ko "FAIL chemin surface sans trailer" "rc=1 CHEMIN-NON-DECLARE" "rc=$rc :: $out"; fi

# --- FAIL 2 : trailer sans separateur -> rc1 MARQUEUR-MAL-FORME --------------------------------------
D="$(mk_repo fail2)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts, trailer casse

Gate-Touche: scripts/check-demo.sh sans separateur du tout dans cette ligne ici"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *MARQUEUR-MAL-FORME*) hasm=1 ;; *) hasm=0 ;; esac
case "$out" in *CHEMIN-NON-DECLARE*) hasc=1 ;; *) hasc=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$hasm" -eq 1 ] && [ "$hasc" -eq 1 ]; then ok "FAIL trailer sans separateur -> rc 1 MARQUEUR-MAL-FORME + CHEMIN-NON-DECLARE"
else ko "FAIL trailer sans separateur" "rc=1 MARQUEUR-MAL-FORME + CHEMIN-NON-DECLARE" "rc=$rc :: $out"; fi

# --- FAIL 3 : trailer avec raison de moins de 10 caracteres -> rc1 -----------------------------------
D="$(mk_repo fail3)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts, raison courte

Gate-Touche: scripts/check-demo.sh — trop court"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *MARQUEUR-MAL-FORME*) hasm=1 ;; *) hasm=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$hasm" -eq 1 ]; then ok "FAIL trailer raison trop courte -> rc 1 MARQUEUR-MAL-FORME"
else ko "FAIL trailer raison trop courte" "rc=1 MARQUEUR-MAL-FORME" "rc=$rc :: $out"; fi

# --- FAIL 4 : trailer dont le motif n'apparie pas le chemin touche -> rc1 ----------------------------
D="$(mk_repo fail4)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts, motif non apparie

Gate-Touche: scripts/check-autre-chose.sh — motif qui ne correspond pas au chemin reellement touche"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *CHEMIN-NON-DECLARE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL motif ne correspond pas au chemin -> rc 1 CHEMIN-NON-DECLARE"
else ko "FAIL motif ne correspond pas" "rc=1 CHEMIN-NON-DECLARE" "rc=$rc :: $out"; fi

# --- FAIL 5 : deux chemins touches, un seul declare -> rc1 avec UN seul verdict de chemin ------------
D="$(mk_repo fail5)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/tests/test-check-demo.sh"
commit_avec "$D" "feat: touche deux chemins, un seul declare

Gate-Touche: scripts/check-demo.sh — seul le premier chemin est couvert par ce commit"
safe_run out rc "$D" --base-ref "$B"
nverdicts=$(printf '%s\n' "$out" | awk '/^CHEMIN-NON-DECLARE:/ { c++ } END { print c + 0 }')
case "$out" in *"CHEMIN-NON-DECLARE: scripts/tests/test-check-demo.sh"*) hasgood=1 ;; *) hasgood=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$nverdicts" -eq 1 ] && [ "$hasgood" -eq 1 ]; then ok "FAIL deux chemins un seul declare -> rc 1, un seul verdict de chemin"
else ko "FAIL deux chemins un seul declare" "rc=1, 1 verdict CHEMIN-NON-DECLARE (test-check-demo.sh)" "rc=$rc verdicts=$nverdicts :: $out"; fi

echo "== test-check-gate-touche : BRUYANT =="

# --- BRUYANT 1 : --base-ref vers une ref inexistante -------------------------------------------------
D="$(mk_repo bru1)"
git_c "$D" commit -q --allow-empty -m "chore: avance HEAD"
safe_run out rc "$D" --base-ref "refs/heads/ref-inexistante-xyz"
[ "$rc" -eq 2 ] && ok "BRUYANT --base-ref inexistante -> rc 2" || ko "BRUYANT --base-ref inexistante" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 2 : --root hors d'un arbre git -----------------------------------------------------------
NOGIT="$TMP/nogit"
mkdir -p "$NOGIT"
safe_run out rc "$NOGIT"
[ "$rc" -eq 2 ] && ok "BRUYANT --root hors d'un arbre git -> rc 2" || ko "BRUYANT --root hors d'un arbre git" "rc=2" "rc=$rc :: $out"

echo "== test-check-gate-touche : SILENCE =="

# --- SILENCE 1 : seul un chemin hors surface est touche (README.md) -> rc3 RIEN-A-JUGER --------------
D="$(mk_repo sil1)"; B="$(base_of "$D")"
printf 'contenu modifie\n' > "$D/README.md"
commit_avec "$D" "docs: touche readme seul"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *RIEN-A-JUGER*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "SILENCE chemin hors surface seul -> rc 3 RIEN-A-JUGER"
else ko "SILENCE chemin hors surface seul" "rc=3 RIEN-A-JUGER" "rc=$rc :: $out"; fi

# --- SILENCE 2 : gate d'un AUTRE module touche seul -> rc3 (controle negatif de la borne) ------------
D="$(mk_repo sil2)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho autre v2\n' > "$D/plugin/dev-orchestrator/scripts/check-demo.sh"
commit_avec "$D" "chore: touche un gate hors surface (autre module)"
safe_run out rc "$D" --base-ref "$B"
case "$out" in *RIEN-A-JUGER*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "SILENCE gate d'un autre module seul -> rc 3 (controle negatif)"
else ko "SILENCE gate d'un autre module seul" "rc=3 RIEN-A-JUGER" "rc=$rc :: $out"; fi

# --- SILENCE 3 : --base-ref egal a HEAD -> rc3 PLAGE-VIDE ---------------------------------------------
D="$(mk_repo sil3)"
H="$(git_c "$D" rev-parse HEAD)"
safe_run out rc "$D" --base-ref "$H"
case "$out" in *PLAGE-VIDE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "SILENCE --base-ref egal HEAD -> rc 3 PLAGE-VIDE"
else ko "SILENCE --base-ref egal HEAD" "rc=3 PLAGE-VIDE" "rc=$rc :: $out"; fi

echo "== test-check-gate-touche : USAGE =="

safe_run out rc "$TMP" --option-bidon
[ "$rc" -eq 64 ] && ok "USAGE option inconnue -> 64" || ko "USAGE option inconnue" "rc=64" "rc=$rc :: $out"

safe_run out rc "$TMP/chemin-inexistant-xyz"
[ "$rc" -eq 64 ] && ok "USAGE --root inexistant -> 64" || ko "USAGE --root inexistant" "rc=64" "rc=$rc :: $out"

safe_run out rc "$TMP" --base-ref
[ "$rc" -eq 64 ] && ok "USAGE --base-ref sans valeur -> 64" || ko "USAGE --base-ref sans valeur" "rc=64" "rc=$rc :: $out"

echo "== test-check-gate-touche : MUTANTS (MUT-1 a MUT-5) =="

# --- MUT-1 : retire la classe des suites (scripts/tests/test-*.sh) ----------------------------------
MUT1_OLD='    if (p ~ /^scripts\/tests\/test-[^\/]+\.sh$/) return "suite"'
MUT1_NEW='    if (p ~ /^NEVER-MATCH-SUITE-CLASS$/) return "suite"'
MUT1_PATH="$(make_mutant mut1 "$MUT1_OLD" "$MUT1_NEW")"; MUT1_STAT=$?
D="$(mk_repo mut1)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/tests/test-check-demo.sh"
commit_avec "$D" "test: touche suite scripts sans trailer (fixture MUT-1)"
if [ "$MUT1_STAT" -eq 1 ]; then komut 1 "classe des suites retiree" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT1_STAT" -eq 2 ]; then komut 1 "classe des suites retiree" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT1_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 3 ] && [ "$rc_orig" -eq 1 ]; then okmut 1 "$rc_mut" 3 "$rc_orig" 1
  else komut 1 "classe des suites retiree" "rc_mutant=3 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-2 : neutralise la recherche de trailer (couverture toujours acquise) -----------------------
MUT2_OLD='  covered=0'
MUT2_NEW='  covered=1'
MUT2_PATH="$(make_mutant mut2 "$MUT2_OLD" "$MUT2_NEW")"; MUT2_STAT=$?
D="$(mk_repo mut2)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts sans trailer (fixture MUT-2)"
if [ "$MUT2_STAT" -eq 1 ]; then komut 2 "recherche de trailer neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT2_STAT" -eq 2 ]; then komut 2 "recherche de trailer neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT2_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 2 "$rc_mut" 0 "$rc_orig" 1
  else komut 2 "recherche de trailer neutralisee" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-3 : neutralise le controle de forme du marqueur (raison vide/courte acceptee) ---------------
MUT3_OLD='        if [ "${#reason_stripped}" -lt 10 ]; then'
MUT3_NEW='        if [ "0" -eq 1 ]; then'
MUT3_PATH="$(make_mutant mut3 "$MUT3_OLD" "$MUT3_NEW")"; MUT3_STAT=$?
D="$(mk_repo mut3)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts, raison courte (fixture MUT-3)

Gate-Touche: scripts/check-demo.sh — trop court"
if [ "$MUT3_STAT" -eq 1 ]; then komut 3 "controle de forme (longueur de raison) neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT3_STAT" -eq 2 ]; then komut 3 "controle de forme (longueur de raison) neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT3_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 3 "$rc_mut" 0 "$rc_orig" 1
  else komut 3 "controle de forme (longueur de raison) neutralise" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-4 : rend la correspondance chemin <-> motif universelle -------------------------------------
MUT4_OLD='        ($motif) covered=1; break ;;'
MUT4_NEW='        (*) covered=1; break ;;'
MUT4_PATH="$(make_mutant mut4 "$MUT4_OLD" "$MUT4_NEW")"; MUT4_STAT=$?
D="$(mk_repo mut4)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "feat: touche gate scripts, motif non apparie (fixture MUT-4)

Gate-Touche: scripts/check-autre-chose.sh — motif qui ne correspond pas au chemin touche ici"
if [ "$MUT4_STAT" -eq 1 ]; then komut 4 "correspondance de motif rendue universelle" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT4_STAT" -eq 2 ]; then komut 4 "correspondance de motif rendue universelle" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT4_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 4 "$rc_mut" 0 "$rc_orig" 1
  else komut 4 "correspondance de motif rendue universelle" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-5 : remplace merge-base par l'adjacence HEAD^ (derivation de la base) ------------------------
MUT5_OLD='BASE="$(git merge-base HEAD "$REF_RESOLVED" 2>/dev/null)"'
MUT5_NEW='BASE="$(git rev-parse HEAD^ 2>/dev/null)"'
MUT5_PATH="$(make_mutant mut5 "$MUT5_OLD" "$MUT5_NEW")"; MUT5_STAT=$?
D="$(mk_repo mut5)"; B="$(base_of "$D")"
printf '#!/bin/sh\necho v2\n' > "$D/scripts/check-demo.sh"
commit_avec "$D" "chore: commit 1 - touche gate scripts sans trailer (fixture MUT-5)"
printf 'v2\n' > "$D/scripts/other.txt"
commit_avec "$D" "chore: commit 2 - fichier neutre"
printf 'v3\n' > "$D/scripts/other.txt"
commit_avec "$D" "chore: commit 3 - fichier neutre encore"
if [ "$MUT5_STAT" -eq 1 ]; then komut 5 "derivation de la base par adjacence HEAD^" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT5_STAT" -eq 2 ]; then komut 5 "derivation de la base par adjacence HEAD^" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT5_PATH"; safe_run _mutout rc_mut "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run _mutout rc_orig "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 3 ] && [ "$rc_orig" -eq 1 ]; then okmut 5 "$rc_mut" 3 "$rc_orig" 1
  else komut 5 "derivation de la base par adjacence HEAD^" "rc_mutant=3 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== bilan : $PASS ok, $FAIL ko =="
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
