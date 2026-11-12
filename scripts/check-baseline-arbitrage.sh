#!/usr/bin/env bash
# check-baseline-arbitrage.sh — G-1 (PROT-04, QUAL-01). Rougit quand une PR fait MONTER la colonne
# INSTRUCTIONS d'une ligne de `.planning/instruction-budget-baselines.tsv`, ou NEUTRALISE une
# sentinelle `.planning/.*-armed`, sans arbitrage cite (canal + date) dans le commit non-merge, propre
# a la branche, qui porte le changement.
#
# ORIGINE. Traite O-3 du `25-SECURITY.md` (T-25-16, restee procedurale : une hausse de baseline
# n'etait gardee que par la relecture humaine), faute d'acces admin sur le depot (option (a),
# arbitrage Samuel, AskUserQuestion session principale, 2026-09-17). Le statut d'O-3 devient
# « signalee et tracee », JAMAIS « fermee » — aucun texte de ce script, de sa suite ou de l'etape CI
# n'associe O-3 a un mot d'achevement.
#
# LIMITE DE FOND, a lire avant tout le reste. Cette garde VIT DANS LE DEPOT : la PR qu'elle juge peut
# la modifier — elle, sa suite `scripts/tests/test-check-baseline-arbitrage.sh`, et l'etape CI qui
# l'invoque — et rester verte. Elle REND VISIBLE et TRACE une hausse ou une neutralisation ; elle NE
# VERROUILLE RIEN. Aucun droit admin n'existe dans ce perimetre pour poser une regle cote GitHub qui
# empecherait cette meme PR de neutraliser le gate.
#
# FORMULE CANONIQUE (sonde de limite de fond, check-aucune-fermeture.sh, plan 41-15, mandat elargi
# du manager de mission, 2026-09-17) : cette garde peut etre modifiée par la PR qu'elle juge — la
# meme garde que celle decrite au paragraphe ci-dessus, reprise ici mot pour mot pour que la sonde
# ne signale plus ce script comme muet sur sa propre limite de fond.
#
# QUATRE BORNES NOMMEES (a ne jamais presenter comme couvertes) :
#   1. PUSH DIRECT SUR `main` — la base derivee (merge-base HEAD <ref>) egale alors HEAD : la plage
#      est vide, rien a juger ICI (rc 3, PLAGE-VIDE). Le cas est couvert en amont par ce meme gate
#      joue sur la PR ; un push direct est signale APRES COUP par la garde de detection (plan 41-17).
#   2. COMMIT DE MERGE EPHEMERE de GitHub (`refs/pull/N/merge`) — son diff premier-parent porterait
#      tout le contenu de la PR et son message ne peut jamais porter de citation. Les commits de
#      MERGE sont donc EXCLUS de l'imputation (comparaison 2) : sans cette exclusion, la garde
#      rougirait sur TOUTE PR legitime.
#   3. RESOLUTION DE MERGE — une hausse de bout en bout imputable a AUCUN commit non-merge (donc
#      introduite par une resolution de merge ou une reecriture) rend rc 1, verdict
#      HAUSSE-NON-IMPUTABLE : elle n'est pas silencieuse, mais elle n'est pas non plus imputee a un
#      commit precis.
#   4. NEUTRALISATION PAR LE CONTENU d'une sentinelle NON VIDE qui reste NON VIDE — non couverte par
#      ce gate (seules la disparition D/R et le vidage M->taille nulle sont detectes). Nommee, pas
#      pretendue couverte.
#
# VERIFICATION DE FORME, JAMAIS DE VERACITE. La comparaison 3 (citation) verifie qu'une ligne du
# message de commit porte le mot-cle, au moins deux virgules puis une date ISO — jamais que
# l'arbitrage cite a reellement eu lieu. Une citation fabriquee passe la garde ; c'est un choix
# assume (repudiation, T-41-58), coherent avec la convention de tracabilite du `CLAUDE.md` : le
# fait redevient relisable, l'attribution reste humaine.
#
# LIGNE DE DELEGATION EXCLUE (2026-11-12). Une ligne du message qui porte le radical « delegu » ou
# « délégu », toute casse, avec ou sans accent, ne vaut PAS citation, meme avec le mot-cle, deux
# virgules et une date : « décision déléguée par X (canal, date), option recommandée » dit qu'une
# decision a ete confiee, pas qu'un arbitrage direct a eu lieu — la meme forme pouvait donc passer
# pour un arbitrage detaille. Une AUTRE ligne du meme message qui porte une citation directe reste
# acceptee, et c'est elle (jamais la ligne de delegation) qui est recopiee sur la sortie. La regle
# vaut pour les trois usages de la citation (hausse, retrait d'une ligne dont la cible existe encore,
# neutralisation de sentinelle) : un seul predicat les sert. Origine : « Samuel, message session
# principale, 2026-11-12 : "oui tu as raison", en réponse au constat que la garde accepte la ligne de
# délégation ; durcissement avant la release = option recommandée, décision déléguée par Samuel,
# message session principale, 2026-11-08 ». Ce n'est PAS un arbitrage detaille de Samuel sur la
# regle elle-meme. LIMITE QUI DEMEURE : une citation DIRECTE fabriquee passe toujours (verification
# de forme, jamais de veracite, voir ci-dessus) ; le radical est cherche en octets (locale C) apres
# repli explicite de É/é/È/è et de l'accent combinant AIGU seul (U+0301 ; tout autre accent combinant,
# grave ou circonflexe, n'est pas replie). Ne sont PAS couvertes, par choix de ne pas elargir le
# radical (question de regle, remontee au manager) : « delegation » et « délégation » (« décision prise
# par délégation de X (…, 2026-11-08), option recommandée » reste CONFORME), « delegate », « confiée »,
# un homoglyphe ou une orthographe qui evite « delegu » (« deleg-u »). Quand un refus ecarte une ligne
# de delegation, la sortie ajoute INFO-LIGNE-DELEGATION-ECARTEE (information seule, les lignes de
# verdict sont inchangees).
#
# CASCADE DE RESOLUTION DE LA BASE (nommee, imprimee sur echec) : valeur de --base-ref si fournie,
# sinon la premiere ref qui resout parmi refs/remotes/origin/main, origin/main, refs/heads/main,
# main. Aucune ne resout -> rc 2. La base est ENSUITE `git merge-base HEAD <ref>` — JAMAIS `HEAD^`,
# jamais l'adjacence du journal, jamais un tri par date : une base mal derivee rendrait la garde
# aveugle a la toute premiere hausse d'une branche a plusieurs commits (mutant MUT-4 de la suite).
#
# UNE SEULE COLONNE EST BLOQUANTE : les INSTRUCTIONS. Depuis la Phase 40.1 le ratchet du budget
# d'instructions ne porte que sur les instructions, par fichier ; la colonne LIGNES de cette meme
# baseline est publiee mais n'est PLUS JAMAIS comparee pour un code de sortie — exiger un arbitrage
# humain pour une colonne informative fabriquerait de la friction sans rien garder (decision du
# manager, 2026-09-17, sur remontee du planificateur). Une hausse de lignes seule produit
# AVERTISSEMENT-LIGNES-EN-HAUSSE, jamais de citation exigee, jamais de code de sortie change.
#
# RETRAIT D'UNE LIGNE DE BASELINE — TROIS CAS, meme exigence de trace qu'une hausse (regle finale du
# manager, 2026-09-17, qui assouplit une version bloquante-sans-echappatoire d'abord retenue). Deux
# faits verifiables se combinent : l'existence de la cible dans l'arbre A HEAD, et la presence d'une
# citation conforme dans le commit non-merge qui retire la ligne.
#   - cible ENCORE PRESENTE a HEAD, AUCUNE citation conforme -> rc 1,
#     LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE
#   - cible encore presente, citation CONFORME -> AVERTISSEMENT-LIGNE-RETIREE-ARBITREE (rc inchange),
#     la ligne de citation trouvee est recopiee telle quelle sur la sortie
#   - cible DISPARUE du depot a HEAD -> AVERTISSEMENT-LIGNE-RETIREE-CIBLE-DISPAREE (rc inchange) : le
#     retrait suit la disparition de la cible, il n'y a rien a citer
# Une recalibration legitime peut sortir un fichier du corpus sans le supprimer ; la garde ne l'en
# empeche pas, elle exige que ce soit dit et date — meme doctrine que pour une hausse : on rend
# visible et trace, on ne ferme pas. L'existence de la cible se lit sur l'arbre de HEAD (git
# cat-file -e), jamais sur le disque du poste.
#
# Usage:
#   check-baseline-arbitrage.sh [--root DIR] [--base-ref REF]
#
# Exit codes (contrat interne, tous enumeres, patron check-instruction-budget.sh) :
#   0  = CONFORME (peut porter des AVERTISSEMENT-* non bloquants)
#   1  = au moins un verdict bloquant : HAUSSE-SANS-ARBITRAGE, HAUSSE-NON-IMPUTABLE,
#        LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE, ou SENTINELLE-NEUTRALISEE
#   2  = NON VERIFIABLE — aucune ref de base resoluble, hors d'un arbre git, ou baseline (a la base
#        OU A HEAD) imparsable (moins de 3 champs, ou colonne 2/3 non entierement numerique) : une
#        comparaison arithmetique sur une valeur non numerique doit rester detectee, jamais avalee
#        en silence par `set -uo pipefail` (sans -e)
#   3  = silence non bloquant — plage vide (base egale HEAD, ou aucun commit non-merge dans la
#        plage), ou BASELINE-ABSENTE (absente a la base ET a HEAD)
#   64 = erreur d'usage (argument inconnu, --root/--base-ref sans valeur, --root inexistant)
#
# Options reservees aux fixtures : --base-ref REF surcharge la cascade de resolution — TOUTE
# invocation de production (CI, hook, humain) l'omet et laisse la cascade jouer.
set -uo pipefail

BASELINE_PATH=".planning/instruction-budget-baselines.tsv"

ROOT="."
BASE_REF_OVERRIDE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      if [ "$#" -lt 2 ]; then
        echo "[check-baseline-arbitrage] --root necessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --base-ref)
      if [ "$#" -lt 2 ]; then
        echo "[check-baseline-arbitrage] --base-ref necessite une valeur" >&2
        exit 64
      fi
      BASE_REF_OVERRIDE="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-baseline-arbitrage] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

if [ ! -d "$ROOT" ]; then
  echo "[check-baseline-arbitrage] --root introuvable : $ROOT" >&2
  exit 64
fi
ROOT="${ROOT%/}"
[ -n "$ROOT" ] || ROOT="/"

if ! cd "$ROOT" 2>/dev/null; then
  echo "[check-baseline-arbitrage] --root inaccessible : $ROOT" >&2
  exit 64
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[check-baseline-arbitrage] hors d'un arbre git : $ROOT" >&2
  exit 2
fi

CASCADE="refs/remotes/origin/main origin/main refs/heads/main main"

resolve_ref() {
  if [ -n "$BASE_REF_OVERRIDE" ]; then
    if git rev-parse --verify -q "${BASE_REF_OVERRIDE}^{commit}" >/dev/null 2>&1; then
      printf '%s' "$BASE_REF_OVERRIDE"
      return 0
    fi
    return 1
  fi
  for r in $CASCADE; do
    if git rev-parse --verify -q "${r}^{commit}" >/dev/null 2>&1; then
      printf '%s' "$r"
      return 0
    fi
  done
  return 1
}

REF_RESOLVED="$(resolve_ref)" || {
  echo "[check-baseline-arbitrage] aucune ref resoluble (cascade : --base-ref, ${CASCADE})" >&2
  exit 2
}

# --- Derivation de la base : merge-base, jamais l'adjacence du journal (borne 1, MUT-4) -----------
BASE="$(git merge-base HEAD "$REF_RESOLVED" 2>/dev/null)"
if [ -z "$BASE" ]; then
  echo "[check-baseline-arbitrage] merge-base introuvable entre HEAD et ${REF_RESOLVED}" >&2
  exit 2
fi

HEAD_SHA="$(git rev-parse HEAD)"

# Point UNIQUE de la regle de citation : les trois usages (hausse, retrait de ligne, sentinelle) passent
# par citation_ok / extract_citation_line, qui passent tous deux par ligne_citation_ok. Une ligne qui
# porte le radical « delegu » (toute casse, avec ou sans accent) NE VAUT PAS citation : c'est la forme
# d'une decision deleguee, pas d'un arbitrage direct. La comparaison se fait en locale C (octets) : le
# tolower de certains awk ne baisse pas « É », donc les accents sont replies EXPLICITEMENT (É, é, È, è
# vers e, accent aigu combinant U+0301 retire) avant de chercher « delegu ».
AWK_CITATION_LIB='
function est_delegation(s,   t) {
  t = s
  gsub(/É/, "é", t); gsub(/È/, "è", t)
  gsub(/\314\201/, "", t)
  t = tolower(t)
  gsub(/é/, "e", t); gsub(/è/, "e", t)
  return index(t, "delegu") > 0
}
function ligne_forme_ok(s,   kw, nc, l) {
  l = s
  kw = (index(s, "arbitrage") > 0) || (index(s, "décision") > 0) || (index(s, "decision") > 0)
  nc = gsub(/,/, ",", l)
  return (kw && nc >= 2 && (s ~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) ? 1 : 0
}
function ligne_citation_ok(s) {
  if (est_delegation(s)) return 0
  return ligne_forme_ok(s)
}
function ligne_ecartee(s) {
  return (est_delegation(s) && ligne_forme_ok(s)) ? 1 : 0
}
'

citation_ok() {
  # <message complet> sur stdin (via printf par l'appelant) -> exit 0 si une ligne conforme existe.
  LC_ALL=C awk "$AWK_CITATION_LIB"'
    { if (ligne_citation_ok($0)) found = 1 }
    END { exit (found ? 0 : 1) }
  '
}

extract_citation_line() {
  # <message complet> sur stdin -> imprime la premiere ligne conforme trouvee (jamais une ligne de
  # delegation : meme predicat que citation_ok).
  LC_ALL=C awk "$AWK_CITATION_LIB"'
    { if (ligne_citation_ok($0) && !found) { print $0; found = 1 } }
  '
}

delegation_ecartee() {
  # <message complet> sur stdin -> exit 0 si une ligne a la forme d'une citation mais est ecartee
  # parce qu'elle porte le radical de delegation (sert au seul message d'information des refus).
  LC_ALL=C awk "$AWK_CITATION_LIB"'
    { if (ligne_ecartee($0)) found = 1 }
    END { exit (found ? 0 : 1) }
  '
}

info_delegation() {
  # <sha complet du commit impute> -> imprime INFO-LIGNE-DELEGATION-ECARTEE si son message en porte une.
  if git log -1 --format=%B "$1" 2>/dev/null | delegation_ecartee; then
    echo "INFO-LIGNE-DELEGATION-ECARTEE: $(git rev-parse --short "$1") — une ligne de délégation ne vaut pas citation, porter la citation directe sur sa propre ligne"
  fi
}

baseline_exists_at() { git cat-file -e "${1}:${BASELINE_PATH}" 2>/dev/null; }

baseline_data_at() {
  # <ref> -> lignes de donnees (hors commentaires et lignes vides), ou rien si absente a ce ref.
  git show "${1}:${BASELINE_PATH}" 2>/dev/null | awk -F'\t' '
    /^#/ { next }
    /^[[:space:]]*$/ { next }
    { print }
  '
}

instr_at_ref() {
  # <ref> <chemin> -> imprime la colonne instructions pour ce chemin a ce ref, ou rien si absent.
  git show "${1}:${BASELINE_PATH}" 2>/dev/null | awk -F'\t' -v want="$2" '
    /^#/ { next } /^[[:space:]]*$/ { next }
    $1 == want { print $3; found = 1 }
    END { if (!found) print "" }
  '
}

baseline_has_path_at() {
  # <ref> <chemin> -> exit 0 si la ligne existe dans la baseline a ce ref.
  git show "${1}:${BASELINE_PATH}" 2>/dev/null | awk -F'\t' -v want="$2" '
    /^#/ { next } /^[[:space:]]*$/ { next }
    $1 == want { hit = 1 }
    END { exit (hit ? 0 : 1) }
  '
}

NONMERGE_LIST="$(git rev-list --reverse --no-merges "${BASE}..${HEAD_SHA}" 2>/dev/null)"
NONMERGE_COUNT=$(printf '%s\n' "$NONMERGE_LIST" | awk 'NF > 0 { c++ } END { print c + 0 }')

SENTINEL_DIFF="$(git diff --name-status "$BASE" "$HEAD_SHA" -- '.planning' 2>/dev/null)"
SENTINEL_PATHS="$(printf '%s\n' "$SENTINEL_DIFF" | awk -F'\t' '
  { n = split($NF, a, "/"); last = a[n]; if (last ~ /^\.[^\/]*-armed$/) print $NF }
')"
SENTINELLES_SUIVIES=$(printf '%s\n' "$SENTINEL_PATHS" | awk 'NF > 0 { c++ } END { print c + 0 }')

BASE_EXISTS=0; baseline_exists_at "$BASE" && BASE_EXISTS=1
HEAD_EXISTS=0; baseline_exists_at "$HEAD_SHA" && HEAD_EXISTS=1

BASE_DATA_RAW=""
[ "$BASE_EXISTS" -eq 1 ] && BASE_DATA_RAW="$(baseline_data_at "$BASE")"
HEAD_DATA_RAW=""
[ "$HEAD_EXISTS" -eq 1 ] && HEAD_DATA_RAW="$(baseline_data_at "$HEAD_SHA")"

VALEURS_LUES=$(printf '%s\n' "$BASE_DATA_RAW" | awk 'NF > 0 { c++ } END { print c + 0 }')

echo "decouverte: commits_non_merge=${NONMERGE_COUNT} valeurs_lues=${VALEURS_LUES} sentinelles_suivies=${SENTINELLES_SUIVIES}"

# --- Assertion de non-vacuite (MUT-5) : jamais un vert a vide -------------------------------------
if [ "$NONMERGE_COUNT" -eq 0 ]; then
  echo "PLAGE-VIDE: base derivee sans commit non-merge propre a la branche (push direct sur main, ou plage ne portant que des fusions)"
  exit 3
fi

if [ "$BASE_EXISTS" -eq 0 ] && [ "$HEAD_EXISTS" -eq 0 ]; then
  echo "BASELINE-ABSENTE: ${BASELINE_PATH} absente a la base et a HEAD"
  exit 3
fi

if [ "$BASE_EXISTS" -eq 0 ] && [ "$HEAD_EXISTS" -eq 1 ]; then
  echo "BASELINE-CREEE: ${BASELINE_PATH} absente a la base, presente a HEAD — aucune hausse possible, verification des sentinelles seule"
fi

check_parsable() {
  # $1 = donnees TSV brutes, $2 = libelle (base|HEAD) pour le message d'erreur
  printf '%s\n' "$1" | awk -F'\t' '
    NF < 3 { print; exit }
    $2 !~ /^[0-9]+$/ { print; exit }
    $3 !~ /^[0-9]+$/ { print; exit }
  '
}

if [ "$BASE_EXISTS" -eq 1 ]; then
  BAD_LINE="$(check_parsable "$BASE_DATA_RAW" base)"
  if [ -n "$BAD_LINE" ]; then
    echo "[check-baseline-arbitrage] baseline de la base imparsable : ${BAD_LINE}" >&2
    exit 2
  fi
fi

if [ "$HEAD_EXISTS" -eq 1 ]; then
  BAD_LINE="$(check_parsable "$HEAD_DATA_RAW" head)"
  if [ -n "$BAD_LINE" ]; then
    echo "[check-baseline-arbitrage] baseline de HEAD imparsable : ${BAD_LINE}" >&2
    exit 2
  fi
fi

RC=0

# --- Jointure base/HEAD sur la baseline : PRESENT (dans les deux) / REMOVED (retiree) --------------
BASE_TSV="$(mktemp)"
HEAD_TSV="$(mktemp)"
FACTS="$(mktemp)"
trap 'rm -f "$BASE_TSV" "$HEAD_TSV" "$FACTS"' EXIT
printf '%s\n' "$BASE_DATA_RAW" > "$BASE_TSV"
printf '%s\n' "$HEAD_DATA_RAW" > "$HEAD_TSV"

awk -F'\t' '
  FNR == NR { if (NF >= 3 && $1 != "") { bl[$1] = $2; bi[$1] = $3; inbase[$1] = 1 }; next }
  { if (NF >= 3 && $1 != "") { hl[$1] = $2; hi[$1] = $3; inhead[$1] = 1 } }
  END {
    for (p in inbase) allp[p] = 1
    for (p in inhead) allp[p] = 1
    for (p in allp) {
      if ((p in inbase) && (p in inhead)) {
        printf "PRESENT\t%s\t%s\t%s\t%s\t%s\n", p, bl[p], bi[p], hl[p], hi[p]
      } else if ((p in inbase) && !(p in inhead)) {
        printf "REMOVED\t%s\t%s\t%s\n", p, bl[p], bi[p]
      }
    }
  }
' "$BASE_TSV" "$HEAD_TSV" > "$FACTS"

HAUSSES=""
RETRAITS=""

while IFS="$(printf '\t')" read -r kind p bl bi hl hi; do
  [ -z "$kind" ] && continue
  case "$kind" in
    PRESENT)
      lignes_over=0
      instr_over=0
      if [ "$((10#${hl:-0}))" -gt "$((10#${bl:-0}))" ]; then lignes_over=1; fi
      if [ "$((10#${hi:-0}))" -gt "$((10#${bi:-0}))" ]; then instr_over=1; fi
      if [ "$lignes_over" -eq 1 ]; then
        echo "AVERTISSEMENT-LIGNES-EN-HAUSSE: ${p} lignes ${bl} -> ${hl}"
      fi
      if [ "$instr_over" -eq 1 ]; then
        HAUSSES="${HAUSSES}
${p}"
      fi
      ;;
    REMOVED)
      RETRAITS="${RETRAITS}
${p}"
      ;;
  esac
done < "$FACTS"

# --- Comparaison 2 — imputation a un commit non-merge propre a la branche (borne 2 : commits de ---
# --- merge exclus de la marche ; borne 3 : hausse non imputable -> rc 1) --------------------------
printf '%s\n' "$HAUSSES" | while IFS= read -r p; do
  [ -z "$p" ] && continue
  culprit=""
  for c in $NONMERGE_LIST; do
    prev="$(instr_at_ref "${c}^" "$p")"
    cur="$(instr_at_ref "$c" "$p")"
    if [ -n "$prev" ] && [ -n "$cur" ]; then
      if [ "$((10#$cur))" -gt "$((10#$prev))" ]; then
        culprit="$c"
        break
      fi
    fi
  done
  if [ -z "$culprit" ]; then
    echo "HAUSSE-NON-IMPUTABLE: ${p} (aucun commit non-merge propre a la branche n'explique la hausse de bout en bout)"
    echo "RC1" >> "$FACTS.rc"
  else
    msg="$(git log -1 --format=%B "$culprit")"
    hausse_citation_ok=0
    if printf '%s' "$msg" | citation_ok; then hausse_citation_ok=1; fi
    if [ "$hausse_citation_ok" -eq 0 ]; then
      prevv="$(instr_at_ref "${culprit}^" "$p")"
      curv="$(instr_at_ref "$culprit" "$p")"
      shortsha="$(git rev-parse --short "$culprit")"
      echo "HAUSSE-SANS-ARBITRAGE: ${p} instructions ${prevv} -> ${curv} (commit ${shortsha})"
      [ -n "$culprit" ] && info_delegation "$culprit"
      echo "RC1" >> "$FACTS.rc"
    fi
  fi
done

# --- Comparaison 1 bis — retrait de ligne, trois cas ------------------------------------------------
printf '%s\n' "$RETRAITS" | while IFS= read -r p; do
  [ -z "$p" ] && continue
  culprit=""
  for c in $NONMERGE_LIST; do
    if baseline_has_path_at "${c}^" "$p" && ! baseline_has_path_at "$c" "$p"; then
      culprit="$c"
      break
    fi
  done

  target_exists=0
  if git cat-file -e "${HEAD_SHA}:${p}" 2>/dev/null; then target_exists=1; fi

  retrait_citation_ok=0
  citation_line=""
  if [ -n "$culprit" ]; then
    msg="$(git log -1 --format=%B "$culprit")"
    if printf '%s' "$msg" | citation_ok; then retrait_citation_ok=1; fi
    if [ "$retrait_citation_ok" -eq 1 ]; then
      citation_line="$(printf '%s' "$msg" | extract_citation_line)"
    fi
  fi

  if [ "$target_exists" -eq 1 ] && [ "$retrait_citation_ok" -eq 0 ]; then
    shortsha="indetermine"
    [ -n "$culprit" ] && shortsha="$(git rev-parse --short "$culprit")"
    echo "LIGNE-RETIREE-CIBLE-PRESENTE-SANS-ARBITRAGE: ${p} (commit ${shortsha})"
    [ -n "$culprit" ] && info_delegation "$culprit"
    echo "RC1" >> "$FACTS.rc"
  elif [ "$target_exists" -eq 1 ] && [ "$retrait_citation_ok" -eq 1 ]; then
    echo "AVERTISSEMENT-LIGNE-RETIREE-ARBITREE: ${p} — citation : ${citation_line}"
  else
    echo "AVERTISSEMENT-LIGNE-RETIREE-CIBLE-DISPARUE: ${p}"
  fi
done

# --- Comparaison 4 — sentinelles ---------------------------------------------------------------
printf '%s\n' "$SENTINEL_PATHS" | while IFS= read -r sp; do
  [ -z "$sp" ] && continue
  status="$(printf '%s\n' "$SENTINEL_DIFF" | awk -F'\t' -v p="$sp" '$NF == p { print $1; exit }')"
  neutralized=0
  case "$status" in D|R*) neutralized=1 ;; esac
  if [ "$status" = "M" ]; then
    base_size="$(git cat-file -s "${BASE}:${sp}" 2>/dev/null || echo 0)"
    head_size="$(git cat-file -s "${HEAD_SHA}:${sp}" 2>/dev/null || echo 0)"
    if [ "${base_size:-0}" -gt 0 ] && [ "${head_size:-0}" -eq 0 ]; then neutralized=1; fi
  fi
  if [ "$neutralized" -eq 1 ]; then
    culprit=""
    for c in $NONMERGE_LIST; do
      prev_exists=0; git cat-file -e "${c}^:${sp}" 2>/dev/null && prev_exists=1
      cur_exists=0; git cat-file -e "${c}:${sp}" 2>/dev/null && cur_exists=1
      case "$status" in
        D|R*)
          # disparition (existence uniquement) : le contenu prealable, vide ou non, n'entre pas en jeu.
          if [ "$prev_exists" -eq 1 ] && [ "$cur_exists" -eq 0 ]; then culprit="$c"; break; fi
          ;;
        M)
          prev_size="$(git cat-file -s "${c}^:${sp}" 2>/dev/null || echo 0)"
          cur_size="$(git cat-file -s "${c}:${sp}" 2>/dev/null || echo 0)"
          if [ "$prev_exists" -eq 1 ] && [ "${prev_size:-0}" -gt 0 ]; then
            if [ "$cur_exists" -eq 0 ] || [ "${cur_size:-0}" -eq 0 ]; then culprit="$c"; break; fi
          fi
          ;;
      esac
    done
    sentinel_citation_ok=0
    if [ -n "$culprit" ]; then
      msg="$(git log -1 --format=%B "$culprit")"
      if printf '%s' "$msg" | citation_ok; then sentinel_citation_ok=1; fi
    fi
    if [ "$sentinel_citation_ok" -eq 0 ]; then
      shortsha="indetermine"
      [ -n "$culprit" ] && shortsha="$(git rev-parse --short "$culprit")"
      echo "SENTINELLE-NEUTRALISEE: ${sp} (commit ${shortsha})"
      [ -n "$culprit" ] && info_delegation "$culprit"
      echo "RC1" >> "$FACTS.rc"
    fi
  fi
done

if [ -f "$FACTS.rc" ]; then
  RC=1
  rm -f "$FACTS.rc"
fi

if [ "$RC" -eq 0 ]; then
  echo "CONFORME"
fi

exit "$RC"
