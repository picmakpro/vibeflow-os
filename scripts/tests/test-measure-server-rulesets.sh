#!/usr/bin/env bash
# test-measure-server-rulesets.sh — Suite de verification de measure-server-rulesets.sh, le
# compagnon-mesure de G-4 (`scripts/check-affirmation-non-mesuree.sh`). Patron : les suites
# voisines de ce dossier (test-check-affirmation-non-mesuree.sh, test-check-push-sans-pr.sh) —
# compteur ok/ko, ligne de bilan `== bilan : N ok, M ko ==`, mutation par remplacement de ligne
# exacte via awk (jamais un patch textuel approximatif).
#
# OBJET CENTRAL DE CETTE SUITE : `--dry-run` n'ecrit RIEN sur disque et emet, sur stdout, le MEME
# JSON que le mode normal aurait ecrit dans le fichier --out. Aucun appel reseau reel dans cette
# suite : `--rulesets-file` court-circuite `gh api` a chaque invocation.
#
# Comparaisons de fixtures par cmp/comm UNIQUEMENT, jamais diff (proxifie menteur sur ce poste,
# cf. memoire d'agent). Codes de retour mesures par `rc=0; out="$(cmd)" || rc=$?`, jamais derriere
# un pipe vers tail/head.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/measure-server-rulesets.sh"
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
okmut() { echo "  ✓ MUT-$1 TUE : $2"; PASS=$((PASS + 1)); }
komut() {
  echo "  ✗ MUT-$1 NON TUE : $2"
  echo "    assertion : MUT-$1 $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  FAIL=$((FAIL + 1))
}

TMP="$(mktemp -d)"
MUTD="$(mktemp -d)"
trap 'rm -rf "$TMP" "$MUTD"' EXIT

# --- Fixtures de reponse brute (contenu simule d'un `gh api repos/<o>/<r>/rulesets`) --------------
RS_MIXED="$TMP/rulesets-mixed.json"
cat > "$RS_MIXED" <<'EOF'
[{"id":1,"name":"main","enforcement":"active"},{"id":2,"name":"draft","enforcement":"disabled"},{"id":3,"name":"tags","enforcement":"active"}]
EOF

RS_EMPTY="$TMP/rulesets-empty.json"
printf '[]\n' > "$RS_EMPTY"

RS_NONARRAY="$TMP/rulesets-nonarray.json"
printf '{"message":"Not Found"}\n' > "$RS_NONARRAY"

# --- Outillage --------------------------------------------------------------------------------------
run() {  # [args...] -> lance $TARGET, sortie combinee stdout+stderr sur stdout de la fonction
  bash "$TARGET" "$@" 2>&1
}
safe_run() {  # <var_out> <var_rc> [args...]
  local __vout="$1" __vrc="$2"; shift 2
  local __out __rc=0
  __out="$(run "$@")" || __rc=$?
  eval "$__vout=\$__out"
  eval "$__vrc=\$__rc"
}
run_split() {  # <var_stdout> <var_stderr> <var_rc> [args...] — stdout et stderr separes
  local __vso="$1" __vse="$2" __vrc="$3"; shift 3
  local __so __se __rc=0
  __so="$(bash "$TARGET" "$@" 2>"$TMP/.stderr_capture")" || __rc=$?
  __se="$(cat "$TMP/.stderr_capture")"
  eval "$__vso=\$__so"
  eval "$__vse=\$__se"
  eval "$__vrc=\$__rc"
}

# snapshot_dir <dir> <outfile> — empreinte de l'arbre (chemins + checksums), triee, PAS de mtime
# (portable macOS/Linux) : deux arbres identiques en contenu produisent la MEME empreinte.
snapshot_dir() {
  ( cd "$1" && find . -type f -exec cksum {} \; ) | sort > "$2"
}

redact_measured_at() {  # <fichier> -> imprime le contenu avec measured_at neutralise
  sed 's/"measured_at": "[^"]*"/"measured_at": "REDACTED"/' "$1"
}

# make_mutant <name> <old_line> <new_line> -> imprime le chemin du mutant ; retour 0 = opposable et
# valide, 1 = identique a l'original (NON OPPOSABLE), 2 = syntaxe invalide.
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

echo "== test-measure-server-rulesets : USAGE =="

safe_run out rc --repo o/r --rulesets-file "$RS_MIXED" --machin
[ "$rc" -eq 64 ] && ok "USAGE argument inconnu -> 64" || ko "USAGE argument inconnu" "rc=64" "rc=$rc :: $out"

safe_run out rc --repo o/r --rulesets-file "$RS_MIXED" --out
[ "$rc" -eq 64 ] && ok "USAGE --out sans valeur -> 64" || ko "USAGE --out sans valeur" "rc=64" "rc=$rc :: $out"

safe_run out rc --repo
[ "$rc" -eq 64 ] && ok "USAGE --repo sans valeur -> 64" || ko "USAGE --repo sans valeur" "rc=64" "rc=$rc :: $out"

safe_run out rc --repo o/r --rulesets-file "$RS_MIXED" --dry-run --out "$TMP/should-not-write.json"
[ "$rc" -eq 64 ] && ok "USAGE --dry-run + --out combines -> 64 (contradiction refusee)" || ko "USAGE --dry-run + --out" "rc=64" "rc=$rc :: $out"
[ ! -e "$TMP/should-not-write.json" ] && ok "USAGE --dry-run + --out -> le fichier --out n'est pas cree" || ko "USAGE --dry-run + --out, fichier non cree" "absent" "present"

echo "== test-measure-server-rulesets : MODE NORMAL =="

OUT1="$TMP/normal.json"
safe_run out rc --repo picmakpro/vibeflow-os --rulesets-file "$RS_MIXED" --out "$OUT1"
if [ "$rc" -eq 0 ] && [ -f "$OUT1" ]; then ok "MODE NORMAL rc=0, fichier ecrit"
else ko "MODE NORMAL ecrit le fichier" "rc=0, fichier present" "rc=$rc, fichier=$([ -f "$OUT1" ] && echo present || echo absent) :: $out"; fi

if command -v jq >/dev/null 2>&1; then
  FIELDS_OK=1
  for f in measured_at repo ruleset_count active_count rulesets; do
    jq -e "has(\"$f\")" "$OUT1" >/dev/null 2>&1 || FIELDS_OK=0
  done
  [ "$FIELDS_OK" -eq 1 ] && ok "MODE NORMAL les 5 champs documentes sont presents" || ko "MODE NORMAL 5 champs presents" "measured_at,repo,ruleset_count,active_count,rulesets" "un champ manque : $(cat "$OUT1")"
  REPO_VAL="$(jq -r '.repo' "$OUT1")"
  [ "$REPO_VAL" = "picmakpro/vibeflow-os" ] && ok "MODE NORMAL repo correct" || ko "MODE NORMAL repo" "picmakpro/vibeflow-os" "$REPO_VAL"
fi

echo "== test-measure-server-rulesets : COMPTAGE ruleset_count / active_count =="

OUT2="$TMP/counts.json"
safe_run out rc --repo o/r --rulesets-file "$RS_MIXED" --out "$OUT2"
RSC="$(jq -r '.ruleset_count' "$OUT2" 2>/dev/null || echo '?')"
ACC="$(jq -r '.active_count' "$OUT2" 2>/dev/null || echo '?')"
if [ "$rc" -eq 0 ] && [ "$RSC" = "3" ] && [ "$ACC" = "2" ]; then
  ok "COMPTAGE 3 rulesets dont 2 actifs -> ruleset_count=3, active_count=2"
else
  ko "COMPTAGE mixte" "rc=0, ruleset_count=3, active_count=2" "rc=$rc, ruleset_count=$RSC, active_count=$ACC"
fi

echo "== test-measure-server-rulesets : TABLEAU VIDE (zero ruleset pose, PAS une erreur) =="

OUT3="$TMP/empty.json"
safe_run out rc --repo o/r --rulesets-file "$RS_EMPTY" --out "$OUT3"
RSC0="$(jq -r '.ruleset_count' "$OUT3" 2>/dev/null || echo '?')"
if [ "$rc" -eq 0 ] && [ "$RSC0" = "0" ] && [ -f "$OUT3" ]; then
  ok "TABLEAU VIDE [] -> rc=0, ruleset_count=0, mesure ecrite (pas une erreur)"
else
  ko "TABLEAU VIDE" "rc=0, ruleset_count=0, fichier ecrit" "rc=$rc, ruleset_count=$RSC0"
fi

echo "== test-measure-server-rulesets : REPONSE NON-TABLEAU -> NON VERIFIABLE =="

# --out TOUJOURS explicite ici, meme si le chemin normal n'ecrit jamais sur ce cas (guard non-
# tableau declenche avant toute ecriture) : la garantie du mandat porte sur CHAQUE invocation de
# cette suite, jamais seulement sur celles qui, par construction du script intact, se trouvent ne
# rien ecrire — un mutant qui neutralise ce guard (MUT-4 plus bas) doit retomber sur un chemin
# --out isole, jamais sur le defaut relatif au cwd (qui serait la copie de travail reelle).
safe_run out rc --repo o/r --rulesets-file "$RS_NONARRAY" --out "$TMP/nonarray-should-not-exist.json"
if [ "$rc" -eq 2 ]; then ok "REPONSE NON-TABLEAU -> rc=2 NON VERIFIABLE"
else ko "REPONSE NON-TABLEAU" "rc=2" "rc=$rc :: $out"; fi

echo "== test-measure-server-rulesets : --dry-run N'ECRIT RIEN (assertion centrale) =="

WITNESS="$TMP/witness"
mkdir -p "$WITNESS/.planning"
# Fichier PRE-EXISTANT au chemin par defaut de --out : doit rester BYTE POUR BYTE inchange.
printf '{"pre":"existing","untouched":true}\n' > "$WITNESS/.planning/server-rulesets-measurement.json"
printf 'decoy\n' > "$WITNESS/decoy.txt"

snapshot_dir "$WITNESS" "$TMP/witness-before.snap"
DRYRUN_STDOUT="$( cd "$WITNESS" && bash "$TARGET" --repo o/r --rulesets-file "$RS_MIXED" --dry-run 2>"$TMP/dryrun.stderr" )"
DRYRUN_RC=$?
snapshot_dir "$WITNESS" "$TMP/witness-after.snap"

if [ "$DRYRUN_RC" -eq 0 ] && cmp -s "$TMP/witness-before.snap" "$TMP/witness-after.snap"; then
  ok "DRY-RUN n'ecrit rien : empreinte de l'arbre temoin identique avant/apres (rc=0)"
else
  ko "DRY-RUN n'ecrit rien" "rc=0, empreinte identique" "rc=$DRYRUN_RC, empreinte $(cmp -s "$TMP/witness-before.snap" "$TMP/witness-after.snap" && echo identique || echo DIFFERENTE)"
fi

# Le fichier par defaut lui-meme reste, litteralement, celui pose par la fixture — jamais reecrit.
if cmp -s "$WITNESS/.planning/server-rulesets-measurement.json" <(printf '{"pre":"existing","untouched":true}\n'); then
  ok "DRY-RUN le fichier de mesure par defaut au chemin par defaut n'est pas reecrit"
else
  ko "DRY-RUN fichier par defaut non reecrit" "contenu pre-existant inchange" "contenu modifie"
fi

echo "== test-measure-server-rulesets : --dry-run emet sur stdout ce que le mode normal aurait ecrit =="

OUT_WOULD="$TMP/would-write.json"
safe_run _ _rc --repo o/r --rulesets-file "$RS_MIXED" --out "$OUT_WOULD"
DRYRUN2_STDOUT="$( bash "$TARGET" --repo o/r --rulesets-file "$RS_MIXED" --dry-run 2>/dev/null )"
printf '%s\n' "$DRYRUN2_STDOUT" > "$TMP/dryrun2-stdout.json"
redact_measured_at "$OUT_WOULD" > "$TMP/would-redacted.json"
redact_measured_at "$TMP/dryrun2-stdout.json" > "$TMP/dryrun2-redacted.json"
if cmp -s "$TMP/would-redacted.json" "$TMP/dryrun2-redacted.json"; then
  ok "DRY-RUN stdout == contenu que le mode normal aurait ecrit (hors horodatage)"
else
  ko "DRY-RUN stdout identique au mode normal" "contenus identiques hors measured_at" "divergence :: $(cmp "$TMP/would-redacted.json" "$TMP/dryrun2-redacted.json" 2>&1)"
fi

echo "== test-measure-server-rulesets : SEPARATION stdout (donnee) / stderr (diagnostics) =="

run_split so se rc2 --repo o/r --rulesets-file "$RS_MIXED" --dry-run
so_is_json=0; case "$so" in '{'*) so_is_json=1 ;; esac
se_has_decouverte=0; case "$se" in *decouverte:*) se_has_decouverte=1 ;; esac
if [ "$rc2" -eq 0 ] && [ "$so_is_json" -eq 1 ] && [ "$se_has_decouverte" -eq 1 ]; then
  ok "SEPARATION dry-run : stdout commence par '{', stderr porte 'decouverte:'"
else
  ko "SEPARATION dry-run stdout/stderr" "stdout='{'..., stderr contient decouverte:" "so_is_json=$so_is_json se_has_decouverte=$se_has_decouverte rc=$rc2"
fi

run_split so3 se3 rc3 --repo o/r --rulesets-file "$RS_MIXED" --out "$TMP/split-normal.json"
if [ "$rc3" -eq 0 ] && [ -z "$so3" ]; then
  ok "SEPARATION mode normal : stdout vide (la donnee va dans --out, pas sur stdout)"
else
  ko "SEPARATION mode normal stdout vide" "stdout vide, rc=0" "stdout='$so3' rc=$rc3"
fi

echo "== test-measure-server-rulesets : MUTANTS (MUT-1 a MUT-4) =="

# --- MUT-1 : neutralise la branche --dry-run elle-meme (le mutant ECRIT MALGRE --dry-run) --------
# C'EST LE MUTANT CENTRAL DU CORRECTIF : sans lui, rien ne prouve que le mode inspection inspecte
# vraiment. Detection PAR EMPREINTE D'ARBRE (pas par rc : le mutant rend rc=0 comme l'original,
# puisqu'il tombe dans le chemin d'ecriture normal qui reussit aussi).
MUT1_OLD='if [ "$DRY_RUN" -eq 1 ]; then'
MUT1_NEW='if [ "$DRY_RUN" -eq 2 ]; then'
MUT1_PATH="$(make_mutant mut1 "$MUT1_OLD" "$MUT1_NEW")"; MUT1_STAT=$?
if [ "$MUT1_STAT" -eq 1 ]; then
  komut 1 "--dry-run ecrit malgre lui" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT1_STAT" -eq 2 ]; then
  komut 1 "--dry-run ecrit malgre lui" "bash -n OK sur le mutant" "syntaxe invalide"
else
  MW="$TMP/mutwitness1"
  mkdir -p "$MW/.planning"
  printf '{"pre":"existing"}\n' > "$MW/.planning/server-rulesets-measurement.json"
  snapshot_dir "$MW" "$TMP/mutwitness1-before.snap"
  ( cd "$MW" && bash "$MUT1_PATH" --repo o/r --rulesets-file "$RS_MIXED" --dry-run >/dev/null 2>&1 )
  snapshot_dir "$MW" "$TMP/mutwitness1-after.snap"
  MUT_WROTE=1; cmp -s "$TMP/mutwitness1-before.snap" "$TMP/mutwitness1-after.snap" && MUT_WROTE=0
  ORIG_WROTE=1; cmp -s "$TMP/witness-before.snap" "$TMP/witness-after.snap" && ORIG_WROTE=0
  if [ "$MUT_WROTE" -eq 1 ] && [ "$ORIG_WROTE" -eq 0 ]; then
    okmut 1 "arbre_mutant=modifie (ecriture malgre --dry-run), arbre_original=inchange"
  else
    komut 1 "--dry-run ecrit malgre lui" "arbre_mutant=modifie, arbre_original=inchange" "arbre_mutant=$([ "$MUT_WROTE" -eq 1 ] && echo modifie || echo inchange), arbre_original=$([ "$ORIG_WROTE" -eq 1 ] && echo modifie || echo inchange)"
  fi
fi

# --- MUT-2 : neutralise le refus de la combinaison --dry-run + --out ------------------------------
MUT2_OLD='if [ "$DRY_RUN" -eq 1 ] && [ "$OUT_EXPLICIT" -eq 1 ]; then'
MUT2_NEW='if [ "$DRY_RUN" -eq 1 ] && [ "$OUT_EXPLICIT" -eq 2 ]; then'
MUT2_PATH="$(make_mutant mut2 "$MUT2_OLD" "$MUT2_NEW")"; MUT2_STAT=$?
if [ "$MUT2_STAT" -eq 1 ]; then
  komut 2 "contradiction --dry-run + --out non refusee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT2_STAT" -eq 2 ]; then
  komut 2 "contradiction --dry-run + --out non refusee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT2_PATH"; safe_run _mutout rc_mut --repo o/r --rulesets-file "$RS_MIXED" --dry-run --out "$TMP/mut2-out.json"
  TARGET="$SCRIPT"; safe_run _origout rc_orig --repo o/r --rulesets-file "$RS_MIXED" --dry-run --out "$TMP/mut2-out.json"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 64 ]; then okmut 2 "rc_mutant=$rc_mut attendu 0, rc_original=$rc_orig attendu 64"
  else komut 2 "contradiction --dry-run + --out non refusee" "rc_mutant=0 rc_original=64" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-3 : neutralise le calcul de active_count (compte TOUT au lieu du seul "active") ----------
MUT3_OLD='  ACTIVE_COUNT="$(printf '"'"'%s'"'"' "$CONTENT" | jq '"'"'[.[] | select(.enforcement == "active")] | length'"'"')"'
MUT3_NEW='  ACTIVE_COUNT="$(printf '"'"'%s'"'"' "$CONTENT" | jq '"'"'length'"'"')"'
MUT3_PATH="$(make_mutant mut3 "$MUT3_OLD" "$MUT3_NEW")"; MUT3_STAT=$?
if [ "$MUT3_STAT" -eq 1 ]; then
  komut 3 "active_count compte tout au lieu du seul enforcement=active" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT3_STAT" -eq 2 ]; then
  komut 3 "active_count compte tout au lieu du seul enforcement=active" "bash -n OK sur le mutant" "syntaxe invalide"
else
  MUT3OUT="$TMP/mut3-out.json"
  bash "$MUT3_PATH" --repo o/r --rulesets-file "$RS_MIXED" --out "$MUT3OUT" >/dev/null 2>&1
  ACC_MUT="$(jq -r '.active_count' "$MUT3OUT" 2>/dev/null || echo '?')"
  ACC_ORIG="$ACC"
  if [ "$ACC_MUT" = "3" ] && [ "$ACC_ORIG" = "2" ]; then
    okmut 3 "active_count_mutant=$ACC_MUT attendu 3, active_count_original=$ACC_ORIG attendu 2"
  else
    komut 3 "active_count compte tout" "active_count_mutant=3, active_count_original=2" "active_count_mutant=$ACC_MUT, active_count_original=$ACC_ORIG"
  fi
fi

# --- MUT-4 : neutralise la detection non-tableau (accepte n'importe quel JSON valide) -------------
MUT4_OLD="is_array_jq() { command -v jq >/dev/null 2>&1 && printf '%s' \"\$1\" | jq -e 'type == \"array\"' >/dev/null 2>&1; }"
MUT4_NEW="is_array_jq() { command -v jq >/dev/null 2>&1 && printf '%s' \"\$1\" | jq -e 'true' >/dev/null 2>&1; }"
MUT4_PATH="$(make_mutant mut4 "$MUT4_OLD" "$MUT4_NEW")"; MUT4_STAT=$?
if [ "$MUT4_STAT" -eq 1 ]; then
  komut 4 "reponse non-tableau acceptee a tort" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT4_STAT" -eq 2 ]; then
  komut 4 "reponse non-tableau acceptee a tort" "bash -n OK sur le mutant" "syntaxe invalide"
else
  # --out TOUJOURS explicite : ce mutant neutralise justement le guard qui empechait l'ecriture,
  # donc SANS --out il ecrirait au chemin par defaut relatif au cwd — la copie de travail reelle.
  TARGET="$MUT4_PATH"; safe_run _mutout rc_mut --repo o/r --rulesets-file "$RS_NONARRAY" --out "$TMP/mut4-out.json"
  TARGET="$SCRIPT"; safe_run _origout rc_orig --repo o/r --rulesets-file "$RS_NONARRAY" --out "$TMP/mut4-orig-out.json"
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 2 ]; then okmut 4 "rc_mutant=$rc_mut attendu 0, rc_original=$rc_orig attendu 2"
  else komut 4 "reponse non-tableau acceptee a tort" "rc_mutant=0 rc_original=2" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== bilan : $PASS ok, $FAIL ko =="
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
