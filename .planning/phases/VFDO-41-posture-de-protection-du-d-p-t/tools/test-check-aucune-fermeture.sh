#!/usr/bin/env bash
# test-check-aucune-fermeture.sh — Suite de verification de check-aucune-fermeture.sh (Phase 41,
# PROT-04, QUAL-01, plan 41-15). Patron : scripts/tests/test-check-baseline-arbitrage.sh (plan
# 41-14) et .planning/phases/VFDO-40.1-.../tools/controle-negatif-reel.sh. Chaque cas construit
# SON PROPRE depot jetable sous mktemp -d, JAMAIS le depot reel ; identite git passee par -c,
# jamais la configuration du poste. Une suite incapable de rougir est un defaut, au meme titre
# que le gate qu'elle verifie.
#
# Douze controles negatifs (R0..R11) plus TROIS mutants opposables (MUT-1 a MUT-3), un par
# comparaison du script sous test — regle de comptage (avertissement 3 du verificateur frais,
# decision du manager du 2026-09-17) : chaque mutant asserte le rc EXACT sur le mutant ET sur
# l'original, et n'est credite que par une ligne de forme canonique
# « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ». Un mutant qui
# « echoue » par un plantage ou une decouverte vide n'est PAS compte comme tue.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/check-aucune-fermeture.sh"
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

git_c() {  # <root> <args...> — identite de fixture par -c, jamais la config du poste.
  local root="$1"; shift
  git -C "$root" -c user.name=CI -c user.email=ci@example.invalid -c commit.gpgsign=false "$@"
}

# mk_repo <name> -> imprime <path> ; depot jetable vierge sur `main`, aucun commit encore.
mk_repo() {
  local d="$TMP/$1"
  mkdir -p "$d" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  git_c "$d" init -q -b main >/dev/null
  printf '%s' "$d"
}

commit_all() {  # <root> <message>
  git_c "$1" add -A >/dev/null
  git_c "$1" commit -q -m "$2" >/dev/null
}

# safe_run <var_out> <var_rc> <root> [args...] — invocation TOUJOURS via --root. Ecrit la sortie
# et le rc REEL de l'outil teste dans les variables nommees. Appelee comme instruction NUE
# (jamais entouree de $(...) par l'appelant) : `set +e`/`set -e` bascule alors l'etat REEL du
# shell courant (pas celui d'un sous-shell jetable) — le seul moyen sous de faire cohabiter
# `bash -e` (impose par le verify du plan) avec un rc de fixture volontairement non nul, sans
# perdre l'affectation dans un sous-shell de substitution de commande.
safe_run() {
  local __vout="$1" __vrc="$2" __root="$3"; shift 3
  local __out __rc
  set +e
  __out="$(bash "$TARGET" --root "$__root" "$@" 2>&1)"
  __rc=$?
  set -e
  eval "$__vout=\$__out"
  eval "$__vrc=\$__rc"
}

hit_count() {  # <sortie> -> nombre de lignes qui ne sont ni perimetre:, ni allowlist:, ni limite:
  printf '%s\n' "$1" | awk '!/^perimetre: |^allowlist: |^limite: /&&NF{c++} END{print c+0}'
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

echo "== test-check-aucune-fermeture : CONTROLES NEGATIFS (R0..R11) =="

# --- R0 : depot de fixture propre -> rc 0, zero ligne de hit ---------------------------------
D="$(mk_repo r0)"
printf '%s\n' '# changelog de fixture' 'rien a signaler' > "$D/CHANGELOG.md"
commit_all "$D" "fixture: etat propre"
safe_run out rc "$D"
n="$(hit_count "$out")"
if [ "$rc" -eq 0 ] && [ "$n" -eq 0 ]; then ok "R0 depot propre -> rc 0, 0 ligne de hit"
else ko "R0 depot propre -> rc 0, 0 ligne de hit" "rc=0 n=0" "rc=$rc n=$n :: $out"; fi

# --- R1 : ligne affirmant l'achevement d'O-3 -> rc 1, une ligne imprimee ---------------------
D="$(mk_repo r1)"
printf '%s\n' '# changelog de fixture' 'O-3 est fermée maintenant.' > "$D/CHANGELOG.md"
commit_all "$D" "fixture: affirmation O-3 fermee"
safe_run out rc "$D"
n="$(hit_count "$out")"
case "$out" in *"CHANGELOG.md:2:O-3 est fermée maintenant."*) hasline=1 ;; *) hasline=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$n" -eq 1 ] && [ "$hasline" -eq 1 ]; then ok "R1 O-3 fermee -> rc 1, 1 ligne"
else ko "R1 O-3 fermee -> rc 1, 1 ligne" "rc=1 n=1 ligne presente" "rc=$rc n=$n :: $out"; fi

# --- R2 : meme affirmation sous forme NIEE -> rc 1 (la negation ne dispense pas) -------------
D="$(mk_repo r2)"
printf '%s\n' '# changelog de fixture' "O-3 n'est jamais fermée." > "$D/CHANGELOG.md"
commit_all "$D" "fixture: affirmation O-3 niee"
safe_run out rc "$D"
n="$(hit_count "$out")"
if [ "$rc" -eq 1 ] && [ "$n" -eq 1 ]; then ok "R2 negation ne dispense pas -> rc 1, 1 ligne"
else ko "R2 negation ne dispense pas -> rc 1, 1 ligne" "rc=1 n=1" "rc=$rc n=$n :: $out"; fi

# --- R3 : ligne affirmant l'achevement d'une garde nommee par son script -> rc 1 -------------
D="$(mk_repo r3)"
printf '%s\n' '# changelog de fixture' 'check-baseline-arbitrage a été fermé la semaine passée.' > "$D/CHANGELOG.md"
commit_all "$D" "fixture: garde nommee fermee"
safe_run out rc "$D"
n="$(hit_count "$out")"
if [ "$rc" -eq 1 ] && [ "$n" -eq 1 ]; then ok "R3 garde nommee fermee -> rc 1, 1 ligne"
else ko "R3 garde nommee fermee -> rc 1, 1 ligne" "rc=1 n=1" "rc=$rc n=$n :: $out"; fi

# --- R4 : ligne presente a l'allowlist -> rc 0 -----------------------------------------------
D="$(mk_repo r4)"
printf '%s\n' '# changelog de fixture' "  Windows sans privilège symlink) fermé par garde d'existence, T12 assertant l'owner" > "$D/CHANGELOG.md"
commit_all "$D" "fixture: ligne allowlistee"
safe_run out rc "$D"
n="$(hit_count "$out")"
case "$out" in *"allowlist: entrees=3 appliquees=1"*) app=1 ;; *) app=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$n" -eq 0 ] && [ "$app" -eq 1 ]; then ok "R4 ligne allowlistee -> rc 0, appliquee"
else ko "R4 ligne allowlistee -> rc 0, appliquee" "rc=0 n=0 appliquees=1" "rc=$rc n=$n :: $out"; fi

# --- R5 : jeton d'achevement SANS jeton de sujet -> rc 0 (pas de faux positif) ---------------
D="$(mk_repo r5)"
printf '%s\n' '# changelog de fixture' 'Ce chapitre est maintenant fermé.' > "$D/CHANGELOG.md"
commit_all "$D" "fixture: achevement sans sujet"
safe_run out rc "$D"
n="$(hit_count "$out")"
if [ "$rc" -eq 0 ] && [ "$n" -eq 0 ]; then ok "R5 achevement sans sujet -> rc 0"
else ko "R5 achevement sans sujet -> rc 0" "rc=0 n=0" "rc=$rc n=$n :: $out"; fi

# --- R6 : jeton `gate` + achevement -> rc 0 (borne de sujet volontaire) ----------------------
D="$(mk_repo r6)"
printf '%s\n' '# changelog de fixture' 'Le gate est fermé pour la nuit.' > "$D/CHANGELOG.md"
commit_all "$D" "fixture: gate ferme"
safe_run out rc "$D"
n="$(hit_count "$out")"
if [ "$rc" -eq 0 ] && [ "$n" -eq 0 ]; then ok "R6 gate ferme -> rc 0 (borne de sujet)"
else ko "R6 gate ferme -> rc 0 (borne de sujet)" "rc=0 n=0" "rc=$rc n=$n :: $out"; fi

# --- R7 : racine hors d'un arbre git -> rc 2 -------------------------------------------------
NONGIT="$TMP/r7-non-git"
mkdir -p "$NONGIT"
safe_run out rc "$NONGIT"
[ "$rc" -eq 2 ] && ok "R7 racine hors depot git -> rc 2" || ko "R7 racine hors depot git -> rc 2" "rc=2" "rc=$rc :: $out"

# --- R8 : option inconnue -> rc 64 -----------------------------------------------------------
D="$(mk_repo r8)"
printf '%s\n' '# changelog de fixture' 'rien a signaler' > "$D/CHANGELOG.md"
commit_all "$D" "fixture: r8"
safe_run out rc "$D" --option-bidon
[ "$rc" -eq 64 ] && ok "R8 option inconnue -> rc 64" || ko "R8 option inconnue -> rc 64" "rc=64" "rc=$rc :: $out"

# --- R9 : artefact porteur existant PRIVE de la formule -> rc 1, LIMITE-DE-FOND-ABSENTE ------
D="$(mk_repo r9)"
printf '%s\n' '# CLAUDE.md de fixture' 'Rien sur la limite de fond ici.' > "$D/CLAUDE.md"
commit_all "$D" "fixture: CLAUDE.md sans la formule"
safe_run out rc "$D"
case "$out" in *"LIMITE-DE-FOND-ABSENTE: CLAUDE.md"*) hasabs=1 ;; *) hasabs=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$hasabs" -eq 1 ]; then ok "R9 CLAUDE.md sans formule -> rc 1, LIMITE-DE-FOND-ABSENTE"
else ko "R9 CLAUDE.md sans formule -> rc 1, LIMITE-DE-FOND-ABSENTE" "rc=1 LIMITE-DE-FOND-ABSENTE: CLAUDE.md" "rc=$rc :: $out"; fi

# --- R10 : meme artefact, formule COUPEE par un retour a la ligne -> rc 0 (normalisation) ----
D="$(mk_repo r10)"
printf '%s\n' 'Cette garde peut être' "modifiée par la PR" "qu'elle juge, et rien de plus." > "$D/CLAUDE.md"
commit_all "$D" "fixture: CLAUDE.md formule coupee"
safe_run out rc "$D"
case "$out" in *"LIMITE-DE-FOND-ABSENTE"*) hasabs=1 ;; *) hasabs=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasabs" -eq 0 ]; then ok "R10 formule coupee par retour a la ligne -> rc 0 (normalisation)"
else ko "R10 formule coupee par retour a la ligne -> rc 0 (normalisation)" "rc=0 sans LIMITE-DE-FOND-ABSENTE" "rc=$rc :: $out"; fi

# --- R11 : artefact porteur absent du disque -> rc 0, compte en exiges sans etre en manquants -
D="$(mk_repo r11)"
printf '%s\n' '# changelog de fixture' 'rien a signaler ici non plus' > "$D/CHANGELOG.md"
commit_all "$D" "fixture: aucun porteur present"
safe_run out rc "$D"
case "$out" in *"limite: exiges=6 porteurs=0 manquants=aucun"*) limok=1 ;; *) limok=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$limok" -eq 1 ]; then ok "R11 aucun porteur present -> rc 0, exiges=6 porteurs=0 manquants=aucun"
else ko "R11 aucun porteur present -> rc 0, exiges=6 porteurs=0 manquants=aucun" "rc=0 exiges=6 porteurs=0 manquants=aucun" "rc=$rc :: $out"; fi

echo "== test-check-aucune-fermeture : MUTANTS (MUT-1 a MUT-3) =="

# --- MUT-1 : neutralise l'exigence de co-occurrence (jeton d'achevement seul suffit) ---------
MUT1_OLD='    if (hs == 1 && ha == 1) { print FILENAME ":" FNR ":" $0 }'
MUT1_NEW='    if (ha == 1) { print FILENAME ":" FNR ":" $0 }'
set +e
MUT1_PATH="$(make_mutant mut1 "$MUT1_OLD" "$MUT1_NEW")"
MUT1_STAT=$?
set -e
D="$(mk_repo mut1)"
printf '%s\n' '# changelog de fixture' 'Ce chapitre est maintenant fermé.' > "$D/CHANGELOG.md"
commit_all "$D" "fixture: R5 rejouee pour MUT-1"
if [ "$MUT1_STAT" -eq 1 ]; then komut 1 "exigence de co-occurrence neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT1_STAT" -eq 2 ]; then komut 1 "exigence de co-occurrence neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT1_PATH"; safe_run out_mut rc_mut "$D"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig "$D"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 1 "$rc_mut" 1 "$rc_orig" 0
  else komut 1 "exigence de co-occurrence neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-2 : neutralise l'assertion de perimetre non vide (0 fichier rendant 0) --------------
MUT2_OLD='if [ "$NFILES" -eq 0 ]; then exit 2; fi'
MUT2_NEW='if [ "$NFILES" -eq 0 ]; then :; fi'
set +e
MUT2_PATH="$(make_mutant mut2 "$MUT2_OLD" "$MUT2_NEW")"
MUT2_STAT=$?
set -e
NONGIT2="$TMP/mut2-non-git"
mkdir -p "$NONGIT2"
if [ "$MUT2_STAT" -eq 1 ]; then komut 2 "assertion de perimetre non vide neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT2_STAT" -eq 2 ]; then komut 2 "assertion de perimetre non vide neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT2_PATH"; safe_run out_mut rc_mut "$NONGIT2"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig "$NONGIT2"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 2 ]; then okmut 2 "$rc_mut" 0 "$rc_orig" 2
  else komut 2 "assertion de perimetre non vide neutralisee" "rc_mutant=0 rc_original=2" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-3 : neutralise la sonde de limite de fond (la formule n'est plus cherchee) ----------
MUT3_OLD='REQUIRE_FRAGMENT=1'
MUT3_NEW='REQUIRE_FRAGMENT=0'
set +e
MUT3_PATH="$(make_mutant mut3 "$MUT3_OLD" "$MUT3_NEW")"
MUT3_STAT=$?
set -e
D="$(mk_repo mut3)"
printf '%s\n' '# CLAUDE.md de fixture' 'Rien sur la limite de fond ici.' > "$D/CLAUDE.md"
commit_all "$D" "fixture: R9 rejouee pour MUT-3"
if [ "$MUT3_STAT" -eq 1 ]; then komut 3 "sonde de limite de fond neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT3_STAT" -eq 2 ]; then komut 3 "sonde de limite de fond neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT3_PATH"; safe_run out_mut rc_mut "$D"
  TARGET="$SCRIPT"; safe_run out_orig rc_orig "$D"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then okmut 3 "$rc_mut" 0 "$rc_orig" 1
  else komut 3 "sonde de limite de fond neutralisee" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== bilan : $PASS ok, $FAIL ko =="
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
