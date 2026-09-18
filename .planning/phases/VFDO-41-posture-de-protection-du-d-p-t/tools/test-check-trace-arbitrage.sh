#!/usr/bin/env bash
# test-check-trace-arbitrage.sh — Suite de verification de check-trace-arbitrage.sh (Phase 41,
# PROT-04, QUAL-01, plan 41-15, Task 2). Patron : tools/test-check-aucune-fermeture.sh (Task 1 de
# ce meme plan) et scripts/tests/test-check-baseline-arbitrage.sh (plan 41-14). Chaque cas
# construit SON PROPRE depot jetable sous mktemp -d, JAMAIS le depot reel ; identite git passee
# par -c, jamais la configuration du poste. Une suite incapable de rougir est un defaut.
#
# QUATORZE cas (C0..C13) plus SIX mutants opposables (MUT-1 a MUT-6) — MUT-1 a MUT-4 un par
# comparaison du script sous test, MUT-5 et MUT-6 sur la PORTE D'ENTREE du detecteur (liste des
# marqueurs d'invocation, decision du manager, reprise 2026-09-18, resserrement de
# check-trace-arbitrage.sh) — regle de comptage (avertissement 3 du verificateur frais, decision
# du manager du 2026-09-17) : chaque mutant asserte le rc EXACT sur le mutant ET sur l'original, et
# n'est credite que par une ligne de forme canonique
# « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ». Un mutant qui
# « echoue » par un plantage ou une plage vide n'est PAS compte comme tue. MUT-5 est le SEUL
# mutant de cette suite juge sur la plage REELLE du depot (jamais une fixture jetable) : le
# resserrement lui-meme n'est prouve que par sa capacite a distinguer un detecteur large (rouge
# sur l'historique reel) d'un detecteur resserre (vert sur ce meme historique).
set -uo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$TOOLS_DIR/check-trace-arbitrage.sh"
TARGET="$SCRIPT"
# REAL_ROOT — racine du depot reel, calculee EXACTEMENT comme DEFAULT_ROOT dans le script sous
# test (meme nombre de niveaux depuis tools/), utilisee UNIQUEMENT par MUT-5 (jamais par les
# controles C0..C13 ni MUT-1..MUT-4, tous sur fixture jetable).
REAL_ROOT="$(cd "$TOOLS_DIR/../../../.." && pwd)"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
ko() {  # <assertion> <attendu> <obtenu>
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

git_c() {  # <root> <args...> — identite de fixture par -c, jamais la config du poste.
  local root="$1"; shift
  git -C "$root" -c user.name=CI -c user.email=ci@example.invalid -c commit.gpgsign=false "$@"
}

# mk_repo <name> -> imprime <path> ; depot jetable vierge sur `main`, un premier commit neutre.
mk_repo() {
  local d="$TMP/$1"
  mkdir -p "$d" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  git_c "$d" init -q -b main >/dev/null
  printf 'depart\n' > "$d/README-fixture.md"
  git_c "$d" add -A >/dev/null
  git_c "$d" commit -q -m "chore: etat initial de fixture" >/dev/null
  printf '%s' "$d"
}

commit_msg() {  # <root> <message complet> — touche un fichier neutre pour avoir un diff a committer.
  local root="$1" msg="$2"
  date +%s%N > "$root/marqueur-fixture.txt" 2>/dev/null || echo "$RANDOM$RANDOM" > "$root/marqueur-fixture.txt"
  git_c "$root" add -A >/dev/null
  git_c "$root" commit -q -m "$msg" >/dev/null
}

rev() { git_c "$1" rev-parse "$2"; }

# mk_preuves <root> [ligne-base-trace-arbitrage] — construit le registre de fixture au meme
# chemin relatif que le vrai 41-PREUVES.md, avec ou sans la cle BASE-TRACE-ARBITRAGE.
mk_preuves() {
  local root="$1" ligne="${2:-}"
  local dir="$root/.planning/phases/VFDO-41-posture-de-protection-du-d-p-t"
  mkdir -p "$dir"
  {
    echo "# registre de fixture"
    echo ""
    if [ -n "$ligne" ]; then
      echo "$ligne"
    fi
  } > "$dir/41-PREUVES.md"
}

# safe_run <var_out> <var_rc> [args...] — invocation TOUJOURS via $TARGET --root ... deja fourni
# par l'appelant dans [args...]. Ecrit sortie et rc REEL dans les variables nommees. Appelee comme
# instruction NUE (jamais entouree de $(...)) : `set +e`/`set -e` bascule alors l'etat REEL du
# shell courant — le seul moyen de faire cohabiter `bash -e` (impose par le verify du plan) avec
# un rc de fixture volontairement non nul, sans perdre l'affectation dans un sous-shell de
# substitution de commande. Meme patron que tools/test-check-aucune-fermeture.sh (Task 1).
safe_run() {
  local __vout="$1" __vrc="$2"; shift 2
  local __out __rc
  set +e
  __out="$(bash "$TARGET" "$@" 2>&1)"
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

CANON="arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"

echo "== test-check-trace-arbitrage : CONTROLES (C0..C13) =="

# --- C0 : trois commits dont un citant conformement -> rc 0 ----------------------------------
D="$(mk_repo c0)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "chore: rien a signaler"
commit_msg "$D" "feat: hausse quelque chose

$CANON"
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C0 trois commits, un citant conformement -> rc 0" || ko "C0" "rc=0" "rc=$rc :: $out"

# --- C1 : citation « arbitrage Samuel » sans canal ni date -> rc 1 FORME-NON-CONFORME --------
D="$(mk_repo c1)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, sans canal ni date ici"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *FORME-NON-CONFORME*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "C1 citation sans canal ni date -> rc 1 FORME-NON-CONFORME"
else ko "C1" "rc=1 FORME-NON-CONFORME" "rc=$rc :: $out"; fi

# --- C2 : deux arbitrages DISTINCTS et conformes dans le meme commit -> rc 1 CITATIONS-MULTIPLES
D="$(mk_repo c2)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

$CANON

arbitrage Samuel, canal Slack de secours, 2026-09-18"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *CITATIONS-MULTIPLES*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "C2 deux arbitrages distincts conformes -> rc 1 CITATIONS-MULTIPLES"
else ko "C2" "rc=1 CITATIONS-MULTIPLES" "rc=$rc :: $out"; fi

# --- C3 : meme chaine canonique repetee deux fois -> rc 0 (controle negatif) -----------------
D="$(mk_repo c3)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

$CANON. Rappel de la meme citation : $CANON."
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C3 meme citation repetee deux fois -> rc 0" || ko "C3" "rc=0" "rc=$rc :: $out"

# --- C4 : arbitrage + date 2026-09-17 dans une forme voisine mais NON identique --------------
D="$(mk_repo c4)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, canal de secours, 2026-09-17"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *ARBITRAGE-DE-PERIMETRE-MAL-CITE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "C4 forme voisine mais non identique -> rc 1 ARBITRAGE-DE-PERIMETRE-MAL-CITE"
else ko "C4" "rc=1 ARBITRAGE-DE-PERIMETRE-MAL-CITE" "rc=$rc :: $out"; fi

# --- C5 : commits ne citant rien -> rc 0 -----------------------------------------------------
D="$(mk_repo c5)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "chore: rien a signaler ici"
commit_msg "$D" "feat: encore rien a signaler"
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C5 commits ne citant rien -> rc 0" || ko "C5" "rc=0" "rc=$rc :: $out"

# --- C6 : message au format du merge ephemere de GitHub, sans citation -> rc 0 (borne) -------
D="$(mk_repo c6)"; B="$(rev "$D" HEAD)"
H1="0000000000000000000000000000000000000001"
H2="0000000000000000000000000000000000000002"
commit_msg "$D" "Merge $H1 into $H2"
commit_msg "$D" "chore: commit normal qui suit le merge ephemere"
safe_run out rc --root "$D" --base-ref "$B"
case "$out" in *"decouverte: commits=1 "*) n1=1 ;; *) n1=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$n1" -eq 1 ]; then ok "C6 merge ephemere exclu, commit normal juge -> rc 0, commits=1"
else ko "C6" "rc=0 decouverte: commits=1" "rc=$rc :: $out"; fi

# --- C7 : --base-ref egal a HEAD -> rc 3 PLAGE-VIDE ------------------------------------------
D="$(mk_repo c7)"; H="$(rev "$D" HEAD)"
safe_run out rc --root "$D" --base-ref "$H"
case "$out" in *PLAGE-VIDE*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "C7 --base-ref egal HEAD -> rc 3 PLAGE-VIDE"
else ko "C7" "rc=3 PLAGE-VIDE" "rc=$rc :: $out"; fi

# --- C8 : --base-ref vers une ref inexistante -> rc 2 ----------------------------------------
D="$(mk_repo c8)"
safe_run out rc --root "$D" --base-ref "refs/heads/ref-inexistante-xyz"
[ "$rc" -eq 2 ] && ok "C8 --base-ref inexistante -> rc 2" || ko "C8" "rc=2" "rc=$rc :: $out"

# --- C9 : option inconnue -> rc 64 -----------------------------------------------------------
D="$(mk_repo c9)"
safe_run out rc --root "$D" --option-bidon
[ "$rc" -eq 64 ] && ok "C9 option inconnue -> rc 64" || ko "C9" "rc=64" "rc=$rc :: $out"

# --- C10 : citation conforme COUPEE par un retour a la ligne -> rc 0 (normalisation) ---------
D="$(mk_repo c10)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel,
AskUserQuestion session principale,
2026-09-17"
safe_run out rc --root "$D" --base-ref "$B"
[ "$rc" -eq 0 ] && ok "C10 citation coupee par retour a la ligne -> rc 0 (normalisation)" || ko "C10" "rc=0" "rc=$rc :: $out"

# --- C11 : commit NON conforme PLACE COMME BORNE (donc avant/a la borne), commit conforme apres
# Reutilise par MUT-3 : la borne est lue via --base-ref pointant EXACTEMENT sur le commit fautif
# lui-meme (exclusion par construction du range git A..B, exclusif de A) ; MUT-3 deplace la
# resolution d'un cran EN ARRIERE (parent de la borne au lieu de la borne elle-meme), ce qui fait
# rentrer ce commit fautif dans le range juge.
D="$(mk_repo c11)"
FAUTIF_MSG="feat: hausse quelque chose

arbitrage Samuel, sans canal ni date (fautif, place a la borne)"
commit_msg "$D" "$FAUTIF_MSG"
BORNE="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse conforme apres la borne

$CANON"
safe_run out rc --root "$D" --base-ref "$BORNE"
[ "$rc" -eq 0 ] && ok "C11 commit fautif a la borne exclu, commit conforme apres -> rc 0" || ko "C11" "rc=0" "rc=$rc :: $out"

# --- C12 : registre SANS ligne BASE-TRACE-ARBITRAGE, sans --base-ref -> rc 2 -----------------
D="$(mk_repo c12)"
commit_msg "$D" "chore: commit neutre"
mk_preuves "$D" ""
safe_run out rc --root "$D"
[ "$rc" -eq 2 ] && ok "C12 registre sans cle BASE-TRACE-ARBITRAGE -> rc 2" || ko "C12" "rc=2" "rc=$rc :: $out"

# --- C13 : registre portant une valeur NON RESOLUBLE en commit -> rc 2 ----------------------
D="$(mk_repo c13)"
commit_msg "$D" "chore: commit neutre"
mk_preuves "$D" "BASE-TRACE-ARBITRAGE: 0000000000000000000000000000000000000000"
safe_run out rc --root "$D"
[ "$rc" -eq 2 ] && ok "C13 registre avec valeur non resoluble -> rc 2" || ko "C13" "rc=2" "rc=$rc :: $out"

echo "== test-check-trace-arbitrage : MUTANTS (MUT-1 a MUT-6) =="

# --- MUT-1 : neutralise le controle de forme -> C1 devient vert sur le mutant ----------------
MUT1_OLD='  if [ "$nmatches" -eq 0 ]; then'
MUT1_NEW='  if [ "0" = "1" ]; then'
set +e
MUT1_PATH="$(make_mutant mut1 "$MUT1_OLD" "$MUT1_NEW")"
MUT1_STAT=$?
set -e
D="$(mk_repo mut1)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, sans canal ni date ici"
if [ "$MUT1_STAT" -eq 1 ]; then komut 1 "controle de forme neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT1_STAT" -eq 2 ]; then komut 1 "controle de forme neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT1_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 1 "$rc_mut" 0 "$rc_orig" 1
  else komut 1 "controle de forme neutralise" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-2 : neutralise le comptage d'unicite -> C2 devient vert sur le mutant ---------------
MUT2_OLD='  if [ "$nmatches" -gt 1 ]; then'
MUT2_NEW='  if [ "0" = "1" ]; then'
set +e
MUT2_PATH="$(make_mutant mut2 "$MUT2_OLD" "$MUT2_NEW")"
MUT2_STAT=$?
set -e
D="$(mk_repo mut2)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

$CANON

arbitrage Samuel, canal Slack de secours, 2026-09-18"
if [ "$MUT2_STAT" -eq 1 ]; then komut 2 "comptage d'unicite neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT2_STAT" -eq 2 ]; then komut 2 "comptage d'unicite neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT2_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 2 "$rc_mut" 0 "$rc_orig" 1
  else komut 2 "comptage d'unicite neutralise" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-3 : neutralise la lecture EXACTE de la borne (repli d'un cran sur son parent, un
# analogue de « adjacence » plutot que la lecture propre de BASE-TRACE-ARBITRAGE) -> la fixture
# C11 (commit fautif place EXACTEMENT a la borne, donc exclu par construction du range exclusif
# A..B) devient ROUGE sur le mutant (le parent-de-la-borne fait rentrer le commit fautif dans le
# range), reste VERTE sur l'original : c'est le mutant qui prouve que la borne resolue est bien
# CELLE LUE, jamais une adjacence de repli.
MUT3_OLD='BASE_SHA="$(git -C "$ROOT" rev-parse --verify -q "${BASE_RAW}^{commit}" 2>/dev/null || true)"'
MUT3_NEW='BASE_SHA="$(git -C "$ROOT" rev-parse --verify -q "${BASE_RAW}^" 2>/dev/null || true)"'
set +e
MUT3_PATH="$(make_mutant mut3 "$MUT3_OLD" "$MUT3_NEW")"
MUT3_STAT=$?
set -e
D="$(mk_repo mut3)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, sans canal ni date (fautif, place a la borne)"
BORNE="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse conforme apres la borne

$CANON"
if [ "$MUT3_STAT" -eq 1 ]; then komut 3 "lecture exacte de la borne neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT3_STAT" -eq 2 ]; then komut 3 "lecture exacte de la borne neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT3_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$BORNE"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$BORNE"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 3 "$rc_mut" 1 "$rc_orig" 0
  else komut 3 "lecture exacte de la borne neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-4 : neutralise la normalisation des blancs -> C10 devient ROUGE sur le mutant -------
MUT4_OLD="  tr '\\\\n' ' ' | tr -s '[:space:]' ' ' | sed -e 's/^ //' -e 's/ \$//'"
MUT4_NEW='  cat'
set +e
MUT4_PATH="$(make_mutant mut4 "$MUT4_OLD" "$MUT4_NEW")"
MUT4_STAT=$?
set -e
D="$(mk_repo mut4)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel,
AskUserQuestion session principale,
2026-09-17"
if [ "$MUT4_STAT" -eq 1 ]; then komut 4 "normalisation des blancs neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT4_STAT" -eq 2 ]; then komut 4 "normalisation des blancs neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT4_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 4 "$rc_mut" 1 "$rc_orig" 0
  else komut 4 "normalisation des blancs neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-5 : elargit la porte d'entree a la simple occurrence du mot racine (sans exiger un
# marqueur d'invocation) -> doit rendre ROUGE la mesure sur la PLAGE REELLE du depot, alors que
# l'original reste VERT (decision du manager, reprise 2026-09-18, point 4 premier mutant). SEUL
# mutant de cette suite juge sur REAL_ROOT, jamais une fixture jetable : le resserrement n'est
# prouve que par sa capacite a distinguer un detecteur large (rouge sur l'historique reel, ou des
# mentions informelles pre-existent) d'un detecteur resserre (vert sur ce meme historique).
MUT5_OLD="MARKER_REGEX='arbitrage Samuel|sur arbitrage|décision de Samuel|(^|[^0-9A-Za-z_-])D-(0[1-9]|10)([^0-9A-Za-z_]|\$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'"
MUT5_NEW="MARKER_REGEX='arbitrage|arbitrages|décision|décisions|decision|decisions'"
set +e
MUT5_PATH="$(make_mutant mut5 "$MUT5_OLD" "$MUT5_NEW")"
MUT5_STAT=$?
set -e
if [ "$MUT5_STAT" -eq 1 ]; then komut 5 "porte d'entree elargie au mot racine" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT5_STAT" -eq 2 ]; then komut 5 "porte d'entree elargie au mot racine" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT5_PATH"; safe_run out_mut rc_mut --root "$REAL_ROOT"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$REAL_ROOT"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 5 "$rc_mut" 1 "$rc_orig" 0
  else komut 5 "porte d'entree elargie au mot racine (depot reel)" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-6 : retire un marqueur d'invocation de la liste (« arbitrage Samuel ») -> doit rendre
# VERT un cas de fixture qui invoque CE marqueur sans citation canonique complete, alors que
# l'original reste ROUGE sur ce meme cas (decision du manager, reprise 2026-09-18, point 4 second
# mutant). Reutilise le scenario de C1 (citation sans canal ni date), sur une fixture jetable
# dediee — jamais le depot reel.
MUT6_OLD="MARKER_REGEX='arbitrage Samuel|sur arbitrage|décision de Samuel|(^|[^0-9A-Za-z_-])D-(0[1-9]|10)([^0-9A-Za-z_]|\$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'"
MUT6_NEW="MARKER_REGEX='sur arbitrage|décision de Samuel|(^|[^0-9A-Za-z_-])D-(0[1-9]|10)([^0-9A-Za-z_]|\$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'"
set +e
MUT6_PATH="$(make_mutant mut6 "$MUT6_OLD" "$MUT6_NEW")"
MUT6_STAT=$?
set -e
D="$(mk_repo mut6)"; B="$(rev "$D" HEAD)"
commit_msg "$D" "feat: hausse quelque chose

arbitrage Samuel, sans canal ni date ici"
if [ "$MUT6_STAT" -eq 1 ]; then komut 6 "marqueur arbitrage Samuel retire de la liste" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT6_STAT" -eq 2 ]; then komut 6 "marqueur arbitrage Samuel retire de la liste" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT6_PATH"; safe_run out_mut rc_mut --root "$D" --base-ref "$B"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig --root "$D" --base-ref "$B"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 6 "$rc_mut" 0 "$rc_orig" 1
  else komut 6 "marqueur arbitrage Samuel retire de la liste" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== bilan : $PASS ok, $FAIL ko =="
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
