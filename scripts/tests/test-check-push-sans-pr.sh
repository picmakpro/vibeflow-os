#!/usr/bin/env bash
# test-check-push-sans-pr.sh — Suite de verification de check-push-sans-pr.sh (G-3, PROT-05,
# QUAL-01, plan 41-17). Patron : test-check-gate-touche.sh (plan 41-16).
#
# AUCUN APPEL RESEAU DANS CETTE SUITE, jamais. Toutes les reponses d'API sont des fichiers JSON
# ecrits sous mktemp et passes par --pulls-file/--closed-pulls-file : une suite qui interrogerait
# GitHub serait rouge hors ligne et muette en cas de quota — incapable de prouver quoi que ce
# soit de facon stable. La commande d'appel a l'API GitHub (celle que le script sous test invoque
# en production) n'apparait JAMAIS, meme en commentaire, dans ce fichier — un verify du plan la
# recherche comme preuve d'absence.
#
# LIMITE DE FOND, rappelee comme dans le script juge : cette garde peut etre modifiée par la PR
# qu'elle juge — elle, cette suite, et l'etape CI qui l'invoque — et rester verte. Une suite
# incapable de rougir est un defaut, au meme titre que le gate qu'elle verifie.
#
# Trois issues QUAL-01 (PASS / FAIL / BRUYANT) plus SILENCE, USAGE et un CONTROLE NEGATIF, et
# CINQ mutants opposables (MUT-1 a MUT-5), un par comparaison du script sous test — regle de
# comptage (decision du manager, 2026-09-17, reprise du plan 41-14) : chaque mutant asserte le rc
# EXACT attendu sur le mutant ET sur l'original. La ligne de succes d'un mutant a une forme
# UNIQUE, exigee par le verify du plan :
# « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-push-sans-pr.sh"
TARGET="$SCRIPT"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
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

SHA="1111111111111111111111111111111111111111"
BEFORE="2222222222222222222222222222222222222222"

# run [args...] — invocation TOUJOURS via --repo o/r --sha $SHA --before $BEFORE, sauf override.
run() {
  bash "$TARGET" --repo o/r --sha "$SHA" --before "$BEFORE" "$@" 2>&1
}

# safe_run <var_out> <var_rc> [args...] — n'entraine jamais CETTE suite (imposee sous `bash -e`
# par le verify du plan) hors dela premiere commande a rc non nul. Meme patron que
# test-check-gate-touche.sh (plan 41-16) et test-check-baseline-arbitrage.sh (plan 41-14).
safe_run() {
  local __vout="$1" __vrc="$2"; shift 2
  local __out __rc
  set +e
  __out="$(run "$@")"
  __rc=$?
  set -e
  eval "$__vout=\$__out"
  eval "$__vrc=\$__rc"
}

ecrire_json() {  # <chemin> <contenu>
  printf '%s' "$2" > "$1"
}

# make_mutant <name> <old_line> <new_line> -> imprime le chemin du mutant ; retour 0 = opposable
# et valide, 1 = identique a l'original (NON OPPOSABLE), 2 = syntaxe invalide. Substitution par
# ligne exacte, jamais sed -i — meme patron que test-check-gate-touche.sh.
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

echo "== test-check-push-sans-pr : PASS =="

# --- PASS 1 : premiere lecture porte une PR -> rc0 voie=commits-pulls -------------------------------
P="$TMP/pass1_pulls.json"; ecrire_json "$P" '[{"number":9}]'
safe_run out rc --pulls-file "$P"
case "$out" in *"voie=commits-pulls"*) hasv=1 ;; *) hasv=0 ;; esac
case "$out" in *"pr_associee=9"*) hasp=1 ;; *) hasp=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasv" -eq 1 ] && [ "$hasp" -eq 1 ]; then ok "PASS premiere lecture une PR -> rc 0 voie=commits-pulls pr_associee=9"
else ko "PASS premiere lecture une PR" "rc=0 voie=commits-pulls pr_associee=9" "rc=$rc :: $out"; fi

# --- PASS 2 : premiere vide, seconde porte le merge_commit_sha du sha juge (merge par rebase) -------
P="$TMP/pass2_pulls.json"; ecrire_json "$P" '[]'
C="$TMP/pass2_closed.json"; ecrire_json "$C" "[{\"number\":11,\"merge_commit_sha\":\"${SHA}\"}]"
safe_run out rc --pulls-file "$P" --closed-pulls-file "$C"
case "$out" in *"voie=merge-commit-sha"*) hasv=1 ;; *) hasv=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasv" -eq 1 ]; then ok "PASS merge par rebase (cascade merge_commit_sha) -> rc 0 voie=merge-commit-sha"
else ko "PASS merge par rebase" "rc=0 voie=merge-commit-sha" "rc=$rc :: $out"; fi

# --- PASS 3 : premiere lecture porte deux PR -> rc0 --------------------------------------------------
P="$TMP/pass3_pulls.json"; ecrire_json "$P" '[{"number":3},{"number":4}]'
safe_run out rc --pulls-file "$P"
[ "$rc" -eq 0 ] && ok "PASS premiere lecture deux PR -> rc 0" || ko "PASS premiere lecture deux PR" "rc=0" "rc=$rc :: $out"

# --- PASS 4 : merge_commit_sha correspondant en casse differente (insensible a la casse) -------------
P="$TMP/pass4_pulls.json"; ecrire_json "$P" '[]'
SHA_MAJ="$(printf '%s' "$SHA" | tr '[:lower:]' '[:upper:]')"
C="$TMP/pass4_closed.json"; ecrire_json "$C" "[{\"number\":12,\"merge_commit_sha\":\"${SHA_MAJ}\"}]"
safe_run out rc --pulls-file "$P" --closed-pulls-file "$C"
case "$out" in *"voie=merge-commit-sha"*) hasv=1 ;; *) hasv=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasv" -eq 1 ]; then ok "PASS merge_commit_sha casse differente (insensible a la casse) -> rc 0"
else ko "PASS casse differente" "rc=0 voie=merge-commit-sha" "rc=$rc :: $out"; fi

echo "== test-check-push-sans-pr : CONTROLE NEGATIF =="

# --- CN 1 : premiere lecture deja associee -> la cascade ne doit JAMAIS s'executer --------------------
# --closed-pulls-file pointe un contenu illisible ; si la cascade s'executait, elle rendrait
# NON-VERIFIABLE (rc 2). Le rc 0 attendu prouve donc la non-execution, pas seulement un resultat.
P="$TMP/cn1_pulls.json"; ecrire_json "$P" '[{"number":7}]'
C="$TMP/cn1_closed.json"; ecrire_json "$C" 'CECI NEST PAS DU JSON'
safe_run out rc --pulls-file "$P" --closed-pulls-file "$C"
case "$out" in *"voie=commits-pulls"*) hasv=1 ;; *) hasv=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasv" -eq 1 ]; then ok "CONTROLE NEGATIF premiere associee -> cascade non executee, rc 0 malgre un second fichier illisible"
else ko "CONTROLE NEGATIF cascade non executee" "rc=0 voie=commits-pulls" "rc=$rc :: $out"; fi

echo "== test-check-push-sans-pr : FAIL =="

# --- FAIL 1 : les deux lectures vides -> rc1 PUSH-SANS-PR ---------------------------------------------
P="$TMP/fail1_pulls.json"; ecrire_json "$P" '[]'
C="$TMP/fail1_closed.json"; ecrire_json "$C" '[]'
safe_run out rc --pulls-file "$P" --closed-pulls-file "$C"
case "$out" in *PUSH-SANS-PR*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "FAIL deux lectures vides -> rc 1 PUSH-SANS-PR"
else ko "FAIL deux lectures vides" "rc=1 PUSH-SANS-PR" "rc=$rc :: $out"; fi

# --- FAIL 2 : premiere vide, seconde porte des PR sans merge_commit_sha correspondant -----------------
P="$TMP/fail2_pulls.json"; ecrire_json "$P" '[]'
C="$TMP/fail2_closed.json"; ecrire_json "$C" '[{"number":5,"merge_commit_sha":"cafebabecafebabecafebabecafebabecafebabe"}]'
safe_run out rc --pulls-file "$P" --closed-pulls-file "$C"
case "$out" in *"closed_examinees=1"*) hasn=1 ;; *) hasn=0 ;; esac
case "$out" in *PUSH-SANS-PR*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ] && [ "$hasn" -eq 1 ]; then ok "FAIL seconde lecture sans correspondance -> rc 1, closed_examinees=1 non nul"
else ko "FAIL seconde lecture sans correspondance" "rc=1 PUSH-SANS-PR closed_examinees=1" "rc=$rc :: $out"; fi

echo "== test-check-push-sans-pr : BRUYANT =="

# --- BRUYANT 1 : premiere lecture JSON tronque -> rc2 -------------------------------------------------
P="$TMP/bru1_pulls.json"; ecrire_json "$P" '[{"number":1,'
safe_run out rc --pulls-file "$P"
[ "$rc" -eq 2 ] && ok "BRUYANT premiere lecture JSON tronque -> rc 2" || ko "BRUYANT premiere JSON tronque" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 2 : premiere vide, seconde JSON tronque -> rc2 --------------------------------------------
P="$TMP/bru2_pulls.json"; ecrire_json "$P" '[]'
C="$TMP/bru2_closed.json"; ecrire_json "$C" '[{"merge_commit'
safe_run out rc --pulls-file "$P" --closed-pulls-file "$C"
[ "$rc" -eq 2 ] && ok "BRUYANT seconde lecture JSON tronque -> rc 2" || ko "BRUYANT seconde JSON tronque" "rc=2" "rc=$rc :: $out"

# --- BRUYANT 3 : fichier de fixture inexistant -> rc64 --------------------------------------------------
safe_run out rc --pulls-file "$TMP/chemin-inexistant-xyz.json"
[ "$rc" -eq 64 ] && ok "BRUYANT --pulls-file inexistant -> rc 64" || ko "BRUYANT --pulls-file inexistant" "rc=64" "rc=$rc :: $out"

# --- BRUYANT 4 : simulation d'echec d'auth (reponse d'erreur, pas un tableau) -> rc2, jamais rc1 --------
# Precedent nomme : faux negatif d'auth, v2.39.0 du 2026-07-26 — un echec d'API lu comme une liste
# vide aurait produit une fausse alarme PUSH-SANS-PR au lieu de signaler l'impossibilite de juger.
P="$TMP/bru4_pulls.json"; ecrire_json "$P" '{"message":"Bad credentials","documentation_url":"https://docs.github.com"}'
safe_run out rc --pulls-file "$P"
[ "$rc" -eq 2 ] && ok "BRUYANT echec d'auth simule (precedent v2.39.0) -> rc 2 jamais rc 1" || ko "BRUYANT echec d'auth simule" "rc=2" "rc=$rc :: $out"

echo "== test-check-push-sans-pr : SILENCE =="

# --- SILENCE 1 : --before a 40 zeros -> rc3 CREATION-DE-REF ---------------------------------------------
safe_run out rc --before "0000000000000000000000000000000000000000"
case "$out" in *CREATION-DE-REF*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "SILENCE --before 40 zeros -> rc 3 CREATION-DE-REF"
else ko "SILENCE --before 40 zeros" "rc=3 CREATION-DE-REF" "rc=$rc :: $out"; fi

# --- SILENCE 2 : --before a 7 zeros -> rc3 ----------------------------------------------------------------
safe_run out rc --before "0000000"
case "$out" in *CREATION-DE-REF*) has=1 ;; *) has=0 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "SILENCE --before 7 zeros -> rc 3 CREATION-DE-REF"
else ko "SILENCE --before 7 zeros" "rc=3 CREATION-DE-REF" "rc=$rc :: $out"; fi

echo "== test-check-push-sans-pr : USAGE =="

# Toute invocation passe par safe_run() (jamais un appel direct) : la suite tourne sous `bash -e`
# (impose par le verify du plan), et un appel direct `out="$(...)"; rc=$?` sur une commande dont
# le rc attendu est non nul ferait sortir toute la suite via errexit — meme correctif documente
# par test-check-gate-touche.sh et test-check-baseline-arbitrage.sh.
safe_run out rc --option-bidon
[ "$rc" -eq 64 ] && ok "USAGE option inconnue -> 64" || ko "USAGE option inconnue" "rc=64" "rc=$rc :: $out"

# run() prefixe deja --repo o/r --sha $SHA --before $BEFORE ; un second --sha sans valeur en fin
# de ligne de commande demeure un --sha sans valeur pour le parseur (dernier gagne).
safe_run out rc --sha
[ "$rc" -eq 64 ] && ok "USAGE --sha sans valeur -> 64" || ko "USAGE --sha sans valeur" "rc=64" "rc=$rc :: $out"

# --repo mal forme (sans barre oblique) : contrat choisi en Task 1 -> rc 2 (categorise comme une
# configuration non exploitable, pas une erreur de syntaxe CLI) ; asserte ici la valeur retenue.
# Le second --repo (fin de ligne) ecrase le --repo o/r prefixe par run() (dernier gagne).
safe_run out rc --repo sansbarreoblique
[ "$rc" -eq 2 ] && ok "USAGE --repo malforme (sans /) -> 2 (contrat retenu)" || ko "USAGE --repo malforme" "rc=2" "rc=$rc :: $out"

echo "== test-check-push-sans-pr : MUTANTS (MUT-1 a MUT-5) =="

# --- MUT-1 : neutralise le test de vacuite de la premiere lecture (toujours associee) -----------------
# Fixture "deux lectures vides". Original : n=0 correctement classe VIDE -> cascade -> VIDE -> rc 1
# PUSH-SANS-PR. Mutant : n=0 force dans la branche ASSOCIEE ; sans numero de PR lisible (tableau
# vide), l'assertion de non-vacuite (intacte, MUT-5 la cible separement) rattrape rc 2. Flip reel
# 1 -> 2 qui prouve que ce test est necessaire meme sous l'assertion de non-vacuite : sans lui, un
# « deux lectures vides » n'est plus signale comme PUSH-SANS-PR mais comme NON-VERIFIABLE.
MUT1_OLD='    if [ "$n" -eq 0 ]; then'
MUT1_NEW='    if [ "0" -eq 1 ]; then'
MUT1_PATH="$(make_mutant mut1 "$MUT1_OLD" "$MUT1_NEW")"; MUT1_STAT=$?
P="$TMP/mut1_pulls.json"; ecrire_json "$P" '[]'
C="$TMP/mut1_closed.json"; ecrire_json "$C" '[]'
if [ "$MUT1_STAT" -eq 1 ]; then komut 1 "test de vacuite de la premiere lecture neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT1_STAT" -eq 2 ]; then komut 1 "test de vacuite de la premiere lecture neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT1_PATH"; safe_run _mutout rc_mut --pulls-file "$P" --closed-pulls-file "$C"
  TARGET="$SCRIPT"; safe_run _origout rc_orig --pulls-file "$P" --closed-pulls-file "$C"
  if [ "$rc_mut" -eq 2 ] && [ "$rc_orig" -eq 1 ]; then okmut 1 "$rc_mut" 2 "$rc_orig" 1
  else komut 1 "test de vacuite de la premiere lecture neutralise" "rc_mutant=2 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-2 : neutralise la cascade merge_commit_sha (seconde lecture ignoree) --------------------------
# Fixture "merge par rebase". Mutant : la recherche de correspondance de la seconde lecture est
# aiguillee vers un sha bidon qui ne matchera jamais -> ETAT2 force a VIDE -> rc 1, jamais rc 2 (un
# rc 2 signifierait un plantage, pas un flip). Original : rc 0 voie=merge-commit-sha. C'est le
# mutant qui prouve que la cascade existe pour une raison mesuree, pas par prudence decorative.
MUT2_OLD='CLASSIFY2="$(classify_closed_pulls "$CLOSED_RAW" "$CLOSED_CALL_RC" "$SHA")"'
MUT2_NEW='CLASSIFY2="$(classify_closed_pulls "$CLOSED_RAW" "$CLOSED_CALL_RC" "0000000000000000000000000000000000000000")"'
MUT2_PATH="$(make_mutant mut2 "$MUT2_OLD" "$MUT2_NEW")"; MUT2_STAT=$?
P="$TMP/mut2_pulls.json"; ecrire_json "$P" '[]'
C="$TMP/mut2_closed.json"; ecrire_json "$C" "[{\"number\":11,\"merge_commit_sha\":\"${SHA}\"}]"
if [ "$MUT2_STAT" -eq 1 ]; then komut 2 "cascade merge_commit_sha neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT2_STAT" -eq 2 ]; then komut 2 "cascade merge_commit_sha neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT2_PATH"; safe_run _mutout rc_mut --pulls-file "$P" --closed-pulls-file "$C"
  TARGET="$SCRIPT"; safe_run _origout rc_orig --pulls-file "$P" --closed-pulls-file "$C"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 2 "$rc_mut" 1 "$rc_orig" 0
  else komut 2 "cascade merge_commit_sha neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-3 : confond echec d'API et liste vide ----------------------------------------------------------
# Fixture "echec d'auth" (reponse d'erreur, pas un tableau) + seconde lecture vide. Cible la ligne
# de sortie du controle de type JSON (identique dans les deux fonctions de classification — une
# mutation par ligne exacte touche les deux, sans effet sur la seconde lecture puisqu'un tableau
# genuinement vide passe deja ce controle). Original : la reponse d'erreur echoue le controle de
# type -> INDETERMINE -> rc 2. Mutant : la meme reponse d'erreur est classee VIDE et retournee
# immediatement -> cascade -> seconde lecture genuinement vide -> rc 1. Precedent nomme : faux
# negatif d'auth de la v2.39.0 du 2026-07-26.
MUT3_OLD='      printf '"'"'INDETERMINE\t0\t\n'"'"'; return'
MUT3_NEW='      printf '"'"'VIDE\t0\t\n'"'"'; return'
MUT3_PATH="$(make_mutant mut3 "$MUT3_OLD" "$MUT3_NEW")"; MUT3_STAT=$?
P="$TMP/mut3_pulls.json"; ecrire_json "$P" '{"message":"Bad credentials"}'
C="$TMP/mut3_closed.json"; ecrire_json "$C" '[]'
if [ "$MUT3_STAT" -eq 1 ]; then komut 3 "distinction echec d'API / liste vide neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT3_STAT" -eq 2 ]; then komut 3 "distinction echec d'API / liste vide neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT3_PATH"; safe_run _mutout rc_mut --pulls-file "$P" --closed-pulls-file "$C"
  TARGET="$SCRIPT"; safe_run _origout rc_orig --pulls-file "$P" --closed-pulls-file "$C"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 2 ]; then okmut 3 "$rc_mut" 1 "$rc_orig" 2
  else komut 3 "distinction echec d'API / liste vide neutralisee" "rc_mutant=1 rc_original=2" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-4 : neutralise le traitement de la creation de ref ---------------------------------------------
# Fixture --before a 40 zeros, deux lectures vides. Original : rc 3 CREATION-DE-REF avant toute
# lecture. Mutant : la detection est neutralisee, la comparaison 1 ne declenche jamais -> les deux
# lectures (vides) sont effectivement menees -> rc 1 PUSH-SANS-PR.
MUT4_OLD='  if is_all_zero "$BEFORE"; then'
MUT4_NEW='  if false; then'
MUT4_PATH="$(make_mutant mut4 "$MUT4_OLD" "$MUT4_NEW")"; MUT4_STAT=$?
P="$TMP/mut4_pulls.json"; ecrire_json "$P" '[]'
C="$TMP/mut4_closed.json"; ecrire_json "$C" '[]'
if [ "$MUT4_STAT" -eq 1 ]; then komut 4 "traitement de la creation de ref neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT4_STAT" -eq 2 ]; then komut 4 "traitement de la creation de ref neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT4_PATH"; safe_run _mutout rc_mut --before "0000000000000000000000000000000000000000" --pulls-file "$P" --closed-pulls-file "$C"
  TARGET="$SCRIPT"; safe_run _origout rc_orig --before "0000000000000000000000000000000000000000" --pulls-file "$P" --closed-pulls-file "$C"
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 3 ]; then okmut 4 "$rc_mut" 1 "$rc_orig" 3
  else komut 4 "traitement de la creation de ref neutralise" "rc_mutant=1 rc_original=3" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-5 : neutralise l'assertion de non-vacuite (rc 0 rendu sans pr_associee) ------------------------
# Fixture : premiere lecture non vide (un element) mais sans champ number lisible. Cible la ligne
# de condition seule (identique dans les deux branches ASSOCIEE — la mutation touche les deux,
# sans effet sur la seconde puisque cette fixture ne declenche jamais la cascade). Original : etat
# ASSOCIEE mais numero vide -> l'assertion de non-vacuite rattrape en rc 2. Mutant : la condition
# ne peut plus jamais etre vraie (sentinelle non vide) -> rc 0 rendu avec pr_associee vide.
MUT5_OLD='  if [ -z "$PR_ASSOCIEE" ]; then'
MUT5_NEW='  if [ -z "SENTINELLE-JAMAIS-VIDE" ]; then'
MUT5_PATH="$(make_mutant mut5 "$MUT5_OLD" "$MUT5_NEW")"; MUT5_STAT=$?
P="$TMP/mut5_pulls.json"; ecrire_json "$P" '[{"pas_de_champ_number":true}]'
if [ "$MUT5_STAT" -eq 1 ]; then komut 5 "assertion de non-vacuite neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT5_STAT" -eq 2 ]; then komut 5 "assertion de non-vacuite neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT5_PATH"; safe_run _mutout rc_mut --pulls-file "$P"
  TARGET="$SCRIPT"; safe_run _origout rc_orig --pulls-file "$P"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 2 ]; then okmut 5 "$rc_mut" 0 "$rc_orig" 2
  else komut 5 "assertion de non-vacuite neutralisee" "rc_mutant=0 rc_original=2" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== bilan : $PASS ok, $FAIL ko =="
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
