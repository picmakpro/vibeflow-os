#!/usr/bin/env bash
# test-check-affirmation-non-mesuree.sh — Suite de verification de
# check-affirmation-non-mesuree.sh (G-4). Patron : test-check-gate-touche.sh /
# test-check-baseline-arbitrage.sh (G-2/G-1). Chaque cas construit SON PROPRE depot jetable sous
# mktemp -d, JAMAIS le depot reel ; identite git passee par -c, jamais la configuration du poste ;
# comparaisons de fixtures par cmp/comm uniquement, jamais diff (proxifie menteur sur ce poste,
# cf. memoire d'agent).
#
# LIMITE DE FOND, rappelee ici comme dans le script juge : cette garde peut etre modifiée par la
# PR qu'elle juge — elle, cette suite, et l'etape CI qui l'invoque — et rester verte. Une suite
# incapable de rougir est un defaut, au meme titre que le gate qu'elle verifie.
#
# QUATRE mutants opposables (MUT-1 a MUT-4), un par mecanisme de la garde — regle de comptage
# (decision du manager, 2026-09-17, reprise du plan 41-14) : chaque mutant asserte le rc EXACT
# attendu sur le mutant ET sur l'original. La ligne de succes d'un mutant a une forme UNIQUE,
# exigee par le verify du plan :
# « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-affirmation-non-mesuree.sh"
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

git_c() {  # <root> <args...> — identite de fixture par -c, jamais la config du poste.
  local root="$1"; shift
  git -C "$root" -c user.name=CI -c user.email=ci@example.invalid -c commit.gpgsign=false "$@"
}

FRESH_MEASURE_CONFIRMS='{
  "measured_at": "%NOW%",
  "repo": "o/r",
  "ruleset_count": 1,
  "active_count": 1,
  "rulesets": [{"id":1,"enforcement":"active"}]
}'
FRESH_MEASURE_CONTREDIT='{
  "measured_at": "%NOW%",
  "repo": "o/r",
  "ruleset_count": 0,
  "active_count": 0,
  "rulesets": []
}'
# Mesure CONFIRMANTE mais PERIMEE (horodatage fige loin dans le passe, seuil par defaut de
# 604800s) : jamais "%NOW%" + --max-age-seconds 0, qui rate le cas quand la fixture et la mesure
# sont ecrites dans la meme seconde (AGE=0, 0 > 0 est faux).
STALE_MEASURE_CONFIRMS='{
  "measured_at": "2020-01-01T00:00:00Z",
  "repo": "o/r",
  "ruleset_count": 1,
  "active_count": 1,
  "rulesets": [{"id":1,"enforcement":"active"}]
}'

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# mk_repo <name> <claude_body> [measure_json] -> imprime <path> ; depot jetable a un fichier
# CLAUDE.md porteur et, optionnellement, une mesure .planning/server-rulesets-measurement.json.
mk_repo() {
  local d="$TMP/$1" body="$2" measure="${3:-}"
  mkdir -p "$d/.planning" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  git_c "$d" init -q -b main >/dev/null
  printf '%s\n' "$body" > "$d/CLAUDE.md"
  if [ -n "$measure" ]; then
    printf '%s\n' "$measure" | sed "s/%NOW%/$(now_iso)/" > "$d/.planning/server-rulesets-measurement.json"
  fi
  git_c "$d" add -A >/dev/null
  git_c "$d" commit -q -m "fixture: etat initial" >/dev/null
  printf '%s' "$d"
}

run() {  # <root> [args...] — invocation TOUJOURS via --root.
  local root="$1"; shift
  bash "$TARGET" --root "$root" "$@" 2>&1
}

safe_run() {  # <var_out> <var_rc> <root> [args...]
  local __vout="$1" __vrc="$2" root="$3"; shift 3
  local __out __rc=0
  __out="$(run "$root" "$@")" || __rc=$?
  eval "$__vout=\$__out"
  eval "$__vrc=\$__rc"
}

# make_mutant <name> <old> <new> -> imprime le chemin du mutant ; retour 0 = opposable et valide,
# 1 = identique a l'original (NON OPPOSABLE), 2 = syntaxe invalide.
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

echo "== test-check-affirmation-non-mesuree : USAGE =="

safe_run out rc "$TMP" --machin
[ "$rc" -eq 64 ] && ok "USAGE argument inconnu -> 64" || ko "USAGE argument inconnu" "rc=64" "rc=$rc :: $out"

safe_run out rc "$TMP" --root
[ "$rc" -eq 64 ] && ok "USAGE --root sans valeur -> 64" || ko "USAGE --root sans valeur" "rc=64" "rc=$rc :: $out"

safe_run out rc "/chemin/inexistant-xyz" --root "/chemin/inexistant-xyz"
[ "$rc" -eq 64 ] && ok "USAGE --root introuvable -> 64" || ko "USAGE --root introuvable" "rc=64" "rc=$rc :: $out"

echo "== test-check-affirmation-non-mesuree : NEANT =="

D="$TMP/vide"; mkdir -p "$D"; git_c "$D" init -q -b main >/dev/null
git_c "$D" commit -q --allow-empty -m "vide" >/dev/null
safe_run out rc "$D" --ref HEAD
has=0; case "$out" in *NEANT*) has=1 ;; esac
if [ "$rc" -eq 3 ] && [ "$has" -eq 1 ]; then ok "NEANT aucun fichier porteur -> rc 3"
else ko "NEANT aucun fichier porteur" "rc=3, NEANT present" "rc=$rc, NEANT=$has :: $out"; fi

echo "== test-check-affirmation-non-mesuree : BASCULE CONSULTATIVE (VF_AFFIRMATION_GATE_CONSULTATIF) =="

# ADR-074 : la bascule bloquant -> consultatif doit etre UN SEUL
# DRAPEAU, jamais une refonte. Meme fixture qu'un cas bloquant (CAS 1 ci-dessous), verdict imprime
# tel quel, mais rc=0 et un marqueur CONSULTATIF additionnel.
DCONS="$(mk_repo consultatif 'Toute mise a jour de `main` passe par une PR (0 approbation).')"
out="$(VF_AFFIRMATION_GATE_CONSULTATIF=1 bash "$TARGET" --root "$DCONS" --ref HEAD 2>&1)"; rc=$?
has_verdict=0; case "$out" in *MESURE-ABSENTE-OU-PERIMEE*) has_verdict=1 ;; esac
has_marker=0; case "$out" in *CONSULTATIF:*) has_marker=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has_verdict" -eq 1 ] && [ "$has_marker" -eq 1 ]; then
  ok "bascule consultative : rc=0, verdict imprime, marqueur CONSULTATIF present"
else
  ko "bascule consultative" "rc=0, verdict + marqueur CONSULTATIF" "rc=$rc, verdict=$has_verdict, marqueur=$has_marker :: $out"
fi

echo "== test-check-affirmation-non-mesuree : QUATRE CAS NOMINAUX DU MANDAT =="

# --- Cas 1 : affirmation au present, sans mesure confirmante (mesure ABSENTE) -> NON VERIFIABLE (2)
D1="$(mk_repo cas1 'Toute mise a jour de `main` passe par une PR (0 approbation).')"
safe_run out rc "$D1" --ref HEAD
has=0; case "$out" in *MESURE-ABSENTE-OU-PERIMEE*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "CAS 1 affirmation sans mesure -> rc 2 NON VERIFIABLE"
else ko "CAS 1 affirmation sans mesure" "rc=2, MESURE-ABSENTE-OU-PERIMEE present" "rc=$rc :: $out"; fi

# --- Cas 1bis : meme affirmation, mesure PRESENTE et FRAICHE mais CONTREDIT (active_count=0) -> rouge (1)
D1B="$(mk_repo cas1bis 'Toute mise a jour de `main` passe par une PR (0 approbation).' "$FRESH_MEASURE_CONTREDIT")"
safe_run out rc "$D1B" --ref HEAD
has=0; case "$out" in *AFFIRMATION-CONTREDITE-PAR-MESURE*) has=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "CAS 1bis affirmation contredite par mesure fraiche -> rc 1 rouge"
else ko "CAS 1bis affirmation contredite" "rc=1, AFFIRMATION-CONTREDITE-PAR-MESURE present" "rc=$rc :: $out"; fi

# --- Cas 2 : meme phrase, QUALIFIEE ("a la pose") -> vert (0), peu importe la mesure
D2="$(mk_repo cas2 'À la pose, toute mise a jour de `main` passe par une PR (0 approbation).')"
safe_run out rc "$D2" --ref HEAD
has=0; case "$out" in *AVERTISSEMENT-AFFIRMATION-QUALIFIEE*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "CAS 2 affirmation qualifiee -> rc 0 vert"
else ko "CAS 2 affirmation qualifiee" "rc=0, AVERTISSEMENT-AFFIRMATION-QUALIFIEE present" "rc=$rc :: $out"; fi

# --- Cas 3 : affirmation adossee a une mesure FRAICHE qui la CONFIRME (active_count>0) -> vert (0)
D3="$(mk_repo cas3 'Toute mise a jour de `main` passe par une PR (0 approbation).' "$FRESH_MEASURE_CONFIRMS")"
safe_run out rc "$D3" --ref HEAD
has=0; case "$out" in *AVERTISSEMENT-AFFIRMATION-CONFIRMEE-PAR-MESURE*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "CAS 3 affirmation confirmee par mesure -> rc 0 vert"
else ko "CAS 3 affirmation confirmee" "rc=0, AVERTISSEMENT-AFFIRMATION-CONFIRMEE-PAR-MESURE present" "rc=$rc :: $out"; fi

# --- Cas 4 : mesure PERIMEE (au-dela du seuil, horodatage fige dans le passe), affirmation
# presente -> NON VERIFIABLE (2)
D4="$(mk_repo cas4 'Toute mise a jour de `main` passe par une PR (0 approbation).' "$STALE_MEASURE_CONFIRMS")"
safe_run out rc "$D4" --ref HEAD
has=0; case "$out" in *MESURE-ABSENTE-OU-PERIMEE*"perimee"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "CAS 4 mesure perimee -> rc 2 NON VERIFIABLE"
else ko "CAS 4 mesure perimee" "rc=2, mesure perimee signalee" "rc=$rc :: $out"; fi

echo "== test-check-affirmation-non-mesuree : NON-REGRESSION SUR LE DEPOT REEL =="

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
safe_run out rc "$REPO_ROOT" --ref HEAD
has=0; case "$out" in *AFFIRMATION-CONTREDITE-PAR-MESURE*|*MESURE-ABSENTE-OU-PERIMEE*) has=1 ;; esac
if [ "$rc" -eq 0 ] || [ "$rc" -eq 3 ]; then ok "depot reel (HEAD, branche de la tache) -> rc=$rc, aucun bloquant/non-verifiable"
else ko "depot reel (HEAD)" "rc=0 ou 3, aucun bloquant" "rc=$rc, verdicts bloquants=$has :: $out"; fi

echo "== test-check-affirmation-non-mesuree : TEMOIN REEL (couple rouge/vert, SHA figes) =="

# Couple de temoins sur le MEME fichier, reconstruit VERBATIM (paragraphe complet, pas seulement
# la puce) depuis deux commits FIGES de la branche feat/phase-41-volet-admin — jamais l'etat
# courant d'une ref mouvante (correctif de cap du coordinateur, 2026-09-23) : la branche a ete
# corrigee apres le depart de cette tache, son SHA de tete bougera encore (merge de la PR #90),
# le SHA rouge et le SHA vert ci-dessous, eux, ne bougeront plus.
#   - ROUGE : `git show 6243c46:CLAUDE.md` — « toute mise a jour de `main` passe par une PR »,
#     present de l'indicatif, section SANS aucun des qualificateurs de cette garde, sans mesure.
#   - VERT  : `git show f5db5145f239c5c38bbe7abcd74a15981bead3c3:CLAUDE.md` (tete de la branche au
#     moment du correctif) — MEME puce, MEME phrase, mais section titree « (PAS ENCORE POSEE) »
#     dont le paragraphe d'intro porte "a la pose" et "une fois pos[e]" : c'est le couple qui
#     prouve que la portee SECTION (et non un simple ±1 ligne) de la qualification est necessaire.
TEMOIN_ROUGE='## Protection côté serveur — main et tags v*

Source versionnée `.github/rulesets/` et `.github/CODEOWNERS`, posée par l'"'"'admin après le merge de
sa source, état réel lisible par `gh api repos/picmakpro/vibeflow-os/rules/branches/main` (ADR-072
§ Amendement du 2026-09-23).

- Toute mise à jour de `main` passe par une PR (0 approbation), 4 jobs CI verts épinglés sur GitHub
  Actions, branche à jour, revue `@picmakpro` sur `.github/`, la baseline du budget d'"'"'instructions
  et les sentinelles `.planning/.*-armed`, et `scripts/hooks/` (D-03, D-04, D-05).'

TEMOIN_VERT='## Protection côté serveur — main et tags v* (PAS ENCORE POSÉE)

Source versionnée dans ce dépôt (`.github/rulesets/`, `.github/CODEOWNERS`), mais **rien n'"'"'est
encore posé côté GitHub** : `gh api repos/picmakpro/vibeflow-os/rulesets` rend `[]` (mesuré le
2026-09-23). Les règles ci-dessous décrivent ce qui **s'"'"'appliquera une fois posé**, pas l'"'"'état
actuel — même régime qu'"'"'ADR-072 : la protection s'"'"'applique **à la pose**, pas avant.

Une fois posée, la protection prévue est :

- Toute mise à jour de `main` passe par une PR (0 approbation), 4 jobs CI verts épinglés sur GitHub
  Actions, branche à jour, revue `@picmakpro` sur `.github/`, la baseline du budget d'"'"'instructions
  et les sentinelles `.planning/.*-armed`, et `scripts/hooks/` (D-03, D-04, D-05).'

DROUGE="$(mk_repo temoin-rouge-6243c46 "$TEMOIN_ROUGE")"
safe_run out rc "$DROUGE" --ref HEAD
if [ "$rc" -ne 0 ]; then ok "TEMOIN ROUGE (contenu figé du commit 6243c46) -> rc=$rc, PAS vert"
else ko "TEMOIN ROUGE (commit 6243c46)" "rc != 0" "rc=$rc :: $out"; fi

DVERT="$(mk_repo temoin-vert-f5db514 "$TEMOIN_VERT")"
safe_run out rc "$DVERT" --ref HEAD
has=0; case "$out" in *AVERTISSEMENT-AFFIRMATION-QUALIFIEE*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "TEMOIN VERT (contenu figé du commit f5db514) -> rc=0, qualifiée par la section"
else ko "TEMOIN VERT (commit f5db514)" "rc=0, AVERTISSEMENT-AFFIRMATION-QUALIFIEE present" "rc=$rc, qualifiee=$has :: $out"; fi

echo "== test-check-affirmation-non-mesuree : MUTANTS (MUT-1 a MUT-4) =="

# --- MUT-1 : neutralise la detection des formes interdites (le hit ne se produit jamais) --------
MUT1_OLD='          if (index(ll[i], forb[k]) > 0) { hit = forb[k]; break }'
MUT1_NEW='          if (index(ll[i], "NEVER-MATCH-FORBIDDEN-FORM") > 0) { hit = forb[k]; break }'
MUT1_PATH="$(make_mutant mut1 "$MUT1_OLD" "$MUT1_NEW")"; MUT1_STAT=$?
D="$(mk_repo mut1 'Toute mise a jour de `main` passe par une PR (0 approbation).')"
if [ "$MUT1_STAT" -eq 1 ]; then komut 1 "detection des formes interdites neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT1_STAT" -eq 2 ]; then komut 1 "detection des formes interdites neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT1_PATH"; safe_run _mutout rc_mut "$D" --ref HEAD
  TARGET="$SCRIPT"; safe_run _origout rc_orig "$D" --ref HEAD
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 2 ]; then okmut 1 "$rc_mut" 0 "$rc_orig" 2
  else komut 1 "detection des formes interdites neutralisee" "rc_mutant=0 rc_original=2" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-2 : neutralise la detection des qualificateurs (qualified toujours faux) ----------------
MUT2_OLD='        for (k = 1; k <= nq; k++) { if (index(win, qual[k]) > 0) { qualified = 1; break } }'
MUT2_NEW='        for (k = 1; k <= nq; k++) { if (index(win, "NEVER-MATCH-QUALIFIER") > 0) { qualified = 1; break } }'
MUT2_PATH="$(make_mutant mut2 "$MUT2_OLD" "$MUT2_NEW")"; MUT2_STAT=$?
D="$(mk_repo mut2 'À la pose, toute mise a jour de `main` passe par une PR (0 approbation).')"
if [ "$MUT2_STAT" -eq 1 ]; then komut 2 "detection des qualificateurs neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT2_STAT" -eq 2 ]; then komut 2 "detection des qualificateurs neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT2_PATH"; safe_run _mutout rc_mut "$D" --ref HEAD
  TARGET="$SCRIPT"; safe_run _origout rc_orig "$D" --ref HEAD
  if [ "$rc_mut" -eq 2 ] && [ "$rc_orig" -eq 0 ]; then okmut 2 "$rc_mut" 2 "$rc_orig" 0
  else komut 2 "detection des qualificateurs neutralisee" "rc_mutant=2 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-3 : neutralise le calcul de CONFIRME (le rameau "confirme" n'est plus jamais pris) ------
MUT3_OLD='      if [ "$ACTIVE_COUNT" -gt 0 ] 2>/dev/null; then'
MUT3_NEW='      if [ "0" -gt 0 ] 2>/dev/null; then'
MUT3_PATH="$(make_mutant mut3 "$MUT3_OLD" "$MUT3_NEW")"; MUT3_STAT=$?
D="$(mk_repo mut3 'Toute mise a jour de `main` passe par une PR (0 approbation).' "$FRESH_MEASURE_CONFIRMS")"
if [ "$MUT3_STAT" -eq 1 ]; then komut 3 "calcul de CONFIRME neutralise" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT3_STAT" -eq 2 ]; then komut 3 "calcul de CONFIRME neutralise" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT3_PATH"; safe_run _mutout rc_mut "$D" --ref HEAD
  TARGET="$SCRIPT"; safe_run _origout rc_orig "$D" --ref HEAD
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then okmut 3 "$rc_mut" 1 "$rc_orig" 0
  else komut 3 "calcul de CONFIRME neutralise" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

# --- MUT-4 : neutralise la detection de peremption (la comparaison d'age n'est plus jamais vraie) -
MUT4_OLD='        if [ "$AGE" -gt "$MAX_AGE" ]; then'
MUT4_NEW='        if [ "0" -gt "999999999999" ]; then'
MUT4_PATH="$(make_mutant mut4 "$MUT4_OLD" "$MUT4_NEW")"; MUT4_STAT=$?
D="$(mk_repo mut4 'Toute mise a jour de `main` passe par une PR (0 approbation).' "$STALE_MEASURE_CONFIRMS")"
if [ "$MUT4_STAT" -eq 1 ]; then komut 4 "detection de peremption neutralisee" "mutation differente de l'original (cmp)" "mutant identique — NON OPPOSABLE"
elif [ "$MUT4_STAT" -eq 2 ]; then komut 4 "detection de peremption neutralisee" "bash -n OK sur le mutant" "syntaxe invalide"
else
  TARGET="$MUT4_PATH"; safe_run _mutout rc_mut "$D" --ref HEAD
  TARGET="$SCRIPT"; safe_run _origout rc_orig "$D" --ref HEAD
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 2 ]; then okmut 4 "$rc_mut" 0 "$rc_orig" 2
  else komut 4 "detection de peremption neutralisee" "rc_mutant=0 rc_original=2" "rc_mutant=$rc_mut rc_original=$rc_orig"; fi
fi

TARGET="$SCRIPT"

echo "== test-check-affirmation-non-mesuree : AUTO-DEFENSE (regression bash -e) =="

# --- AUTODEF 1 : la suite ELLE-MEME doit atteindre sa ligne de bilan sous invocation stricte
# `bash --noprofile --norc -e` — meme motif que test-check-gate-touche.sh / test-check-push-sans-pr.sh.
# Garde de recursion (_TCANM_NORECURSE) : l'instance enfant SAUTE ce meme bloc.
if [ "${_TCANM_NORECURSE:-}" != "1" ]; then
  SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  set +e
  CHILD_OUT="$(_TCANM_NORECURSE=1 bash --noprofile --norc -e "$SELF" 2>&1)"
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
