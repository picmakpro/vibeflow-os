#!/usr/bin/env bash
# check-affirmation-non-mesuree.sh — G-4. Interdit qu'un fichier du depot affirme, au present, une
# protection cote serveur (rulesets/branch protection GitHub) qui n'est pas mesuree.
#
# ORIGIN. La PR #90 ecrit dans `CLAUDE.md` que « le serveur refuse le push direct » et que
# « toute mise a jour de `main` passe par une PR », au present de l'indicatif. Mesure faite au
# meme moment : `gh api repos/picmakpro/vibeflow-os/rulesets` rend `[]` — aucune regle n'est
# posee. Rien dans ce depot ne comparait une affirmation de prose a l'etat reel du serveur avant
# cette garde (tache courte, mandat vibeflow-head, 2026-09-23).
#
# LIMITE DE FOND, a lire avant tout le reste — meme formule que G-1/G-2/G-3 (ADR-072). Cette
# garde VIT DANS LE DEPOT : la PR qu'elle juge peut la modifier — elle, sa suite
# `scripts/tests/test-check-affirmation-non-mesuree.sh`, et l'etape CI qui l'invoque — et rester
# verte. Elle verifie la FORME d'une affirmation face a une MESURE DATEE, jamais sa veracite au
# moment ou quelqu'un LIT la phrase : une mesure fraiche au moment du commit peut avoir peri au
# moment de la lecture, sans que rien ici ne le detecte. Elle ne verrouille rien.
#
# CE QUE CETTE GARDE NE FAIT PAS. Elle ne parle JAMAIS au reseau — elle lit uniquement le fichier
# de mesure ecrit par le compagnon `scripts/measure-server-rulesets.sh`, jamais `gh api`
# elle-meme (mandat point 4). Elle ne juge que la FORME de l'affirmation et la FRAICHEUR/le
# CONTENU de la mesure — jamais si la mesure elle-meme a ete honnetement prise.
#
# FORMES INTERDITES (liste fermee, JAMAIS une regex ouverte sur de la prose) — chacune est
# l'affirmation, au present, d'une protection cote serveur MESURABLE par
# `gh api repos/<o>/<r>/rulesets` :
#   1. "passe par une pr"            -- toute mise a jour passe obligatoirement par une PR
#   2. "passe par une pull request"  -- variante anglaise du meme enonce
#   3. "refuse le push direct"       -- le serveur refuse un push direct (defaut reel, PR #90)
#   4. "bloque le push direct"       -- variante verbale du meme enonce
#   5. "exige une pr"                -- le serveur exige une PR pour toute mise a jour
#   6. "exige une pull request"      -- variante anglaise
# BORNE NOMMEE : "est protegee" est DELIBEREMENT ABSENTE de cette liste. Le `CLAUDE.md` de `main`
# porte « n'est protegee par aucune regle cote serveur » — negation francaise par « aucune » SANS
# « pas » : le substring "est protegee" y est litteralement present, ce qui produirait un faux
# rouge sur `main`. Verifie par grep avant livraison (aucune des six formes ci-dessus n'apparait
# aujourd'hui sur `main` dans les fichiers porteurs par defaut).
#
# QUALIFICATEURS (liste fermee) — une forme interdite trouvee dans la FENETRE (ligne precedente +
# ligne courante + ligne suivante) d'un de ces marqueurs est LICITE (cas a du mandat), quelle que
# soit la mesure :
#   1. "a la pose"          -- explicite : pas encore vrai, vrai au moment de la pose
#   2. "une fois pos"       -- couvre "une fois pose/posee/poses"
#   3. "prevu"              -- couvre "prevu/prevue/prevus"
#   4. "serait"             -- conditionnel francais
#   5. "pourrait"           -- conditionnel francais
#   6. "devrait"            -- conditionnel francais
#   7. "non gatee machine"  -- disclaimer deja en usage dans ce depot (ADR-073)
#   8. "pas gatee machine"  -- variante de negation du meme disclaimer
#
# MESURE (cas b du mandat) — lue via le fichier ecrit par `measure-server-rulesets.sh`
# (`--measurement-file`, defaut `.planning/server-rulesets-measurement.json`), A LA MEME REF que
# les fichiers porteurs (`git show <ref>:<chemin>`, jamais le disque). Champs requis :
# `measured_at` (ISO8601 UTC) et `active_count` (entier). Quatre statuts :
#   - ABSENTE   : le fichier n'existe pas a cette ref                          -> NON VERIFIABLE
#   - ILLISIBLE : JSON invalide, ou `measured_at`/`active_count` absents/non numeriques -> NON VERIFIABLE
#   - PERIMEE   : age (maintenant - measured_at) > seuil (--max-age-seconds,
#                 defaut 604800 = 7 jours, override VF_ASSERTION_MEASURE_MAX_AGE_SECONDS) -> NON VERIFIABLE
#   - FRAICHE   : dans le seuil -> CONFIRME = (active_count > 0)
# DEGRADATION HONNETE (point 5 du mandat) : ABSENTE/ILLISIBLE/PERIMEE ne rendent JAMAIS vert.
#
# VERDICTS :
#   - forme qualifiee                                    -> licite, AVERTISSEMENT-AFFIRMATION-QUALIFIEE
#   - forme non qualifiee + mesure fraiche + CONFIRME     -> licite, AVERTISSEMENT-AFFIRMATION-CONFIRMEE-PAR-MESURE
#   - forme non qualifiee + mesure fraiche + NON CONFIRME -> bloquant, AFFIRMATION-CONTREDITE-PAR-MESURE
#   - forme non qualifiee + mesure ABSENTE/ILLISIBLE/PERIMEE -> non verifiable, MESURE-ABSENTE-OU-PERIMEE
# Priorite : si les deux classes bloquant/non-verifiable coexistent, le bloquant l'emporte (rc 1).
#
# CASCADE DE LECTURE : tout est lu via `git show <ref>:<chemin>` / `git cat-file -e <ref>:<chemin>`
# — jamais le disque directement — pour pouvoir juger n'importe quelle ref (une branche distante
# non checkoutee comprise) sans jamais la modifier ni la checkouter.
#
# Usage:
#   check-affirmation-non-mesuree.sh [--root DIR] [--ref REF] [--measurement-file FICHIER]
#                                     [--carrier CHEMIN]... [--max-age-seconds N] [-h|--help]
#
# Exit codes (convention deja en usage dans ce depot) :
#   0  = CONFORME (peut porter des AVERTISSEMENT-* non bloquants — y compris zero affirmation
#        trouvee sur des fichiers porteurs effectivement lus)
#   1  = au moins un AFFIRMATION-CONTREDITE-PAR-MESURE
#   2  = NON VERIFIABLE — au moins un MESURE-ABSENTE-OU-PERIMEE, aucun cas bloquant
#   3  = NEANT — zero fichier porteur resoluble a la ref donnee (misconfiguration, jamais un vert
#        a vide)
#   64 = erreur d'usage (argument inconnu, option sans valeur, --root inexistant, ref introuvable)
set -uo pipefail

ROOT="."
REF="HEAD"
MEASURE_FILE=".planning/server-rulesets-measurement.json"
MAX_AGE="${VF_ASSERTION_MEASURE_MAX_AGE_SECONDS:-604800}"
EXTRA_CARRIERS=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      if [ "$#" -lt 2 ]; then echo "[check-affirmation-non-mesuree] --root necessite une valeur" >&2; exit 64; fi
      ROOT="$2"; shift 2 ;;
    --ref)
      if [ "$#" -lt 2 ]; then echo "[check-affirmation-non-mesuree] --ref necessite une valeur" >&2; exit 64; fi
      REF="$2"; shift 2 ;;
    --measurement-file)
      if [ "$#" -lt 2 ]; then echo "[check-affirmation-non-mesuree] --measurement-file necessite une valeur" >&2; exit 64; fi
      MEASURE_FILE="$2"; shift 2 ;;
    --carrier)
      if [ "$#" -lt 2 ]; then echo "[check-affirmation-non-mesuree] --carrier necessite une valeur" >&2; exit 64; fi
      EXTRA_CARRIERS="${EXTRA_CARRIERS}
$2"
      shift 2 ;;
    --max-age-seconds)
      if [ "$#" -lt 2 ]; then echo "[check-affirmation-non-mesuree] --max-age-seconds necessite une valeur" >&2; exit 64; fi
      MAX_AGE="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-affirmation-non-mesuree] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

if [ ! -d "$ROOT" ]; then
  echo "[check-affirmation-non-mesuree] --root introuvable : $ROOT" >&2
  exit 64
fi
ROOT="${ROOT%/}"
[ -n "$ROOT" ] || ROOT="/"

if ! cd "$ROOT" 2>/dev/null; then
  echo "[check-affirmation-non-mesuree] --root inaccessible : $ROOT" >&2
  exit 64
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[check-affirmation-non-mesuree] hors d'un arbre git : $ROOT" >&2
  exit 64
fi

if ! git rev-parse --verify -q "${REF}^{commit}" >/dev/null 2>&1; then
  echo "[check-affirmation-non-mesuree] ref introuvable : $REF" >&2
  exit 64
fi
REF_SHA="$(git rev-parse "$REF")"

path_exists_at() { git cat-file -e "${REF_SHA}:${1}" 2>/dev/null; }
content_at() { git show "${REF_SHA}:${1}" 2>/dev/null; }

# --- Resolution des fichiers porteurs -------------------------------------------------------------
DEFAULT_CARRIERS="CLAUDE.md
docs/ADR.md
README.md
README.fr.md"

MANUAL_CARRIERS="$(git ls-tree -r --name-only "$REF_SHA" -- manual 2>/dev/null | awk '/\.md$/')"

ALL_CARRIERS="$(printf '%s\n%s\n%s\n' "$DEFAULT_CARRIERS" "$MANUAL_CARRIERS" "$EXTRA_CARRIERS" | awk 'NF>0')"

FICHIERS_PORTANTS=0
EXIST_CARRIERS=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if path_exists_at "$p"; then
    EXIST_CARRIERS="${EXIST_CARRIERS}
${p}"
    FICHIERS_PORTANTS=$((FICHIERS_PORTANTS + 1))
  fi
done <<EOF_CARRIERS
$ALL_CARRIERS
EOF_CARRIERS

if [ "$FICHIERS_PORTANTS" -eq 0 ]; then
  echo "decouverte: fichiers_portants=0 affirmations_trouvees=0 qualifiees=0 mesure_statut=nonconsultee"
  echo "NEANT: aucun fichier porteur resoluble a la ref ${REF_SHA}"
  exit 3
fi

# --- Formes interdites et qualificateurs, un fichier par liste (jamais -v : accents + multi-lignes) -
FORBIDDEN_TMP="$(mktemp)"
QUALIFIER_TMP="$(mktemp)"
FACTS_TMP="$(mktemp)"
trap 'rm -f "$FORBIDDEN_TMP" "$QUALIFIER_TMP" "$FACTS_TMP"' EXIT

cat > "$FORBIDDEN_TMP" <<'EOF_FORB'
passe par une pr
passe par une pull request
refuse le push direct
bloque le push direct
exige une pr
exige une pull request
EOF_FORB

cat > "$QUALIFIER_TMP" <<'EOF_QUAL'
à la pose
une fois pos
prévu
serait
pourrait
devrait
non gatée machine
pas gatée machine
EOF_QUAL

# --- Balayage de chaque fichier porteur : tab-separe lineno / forme / qualifie(0|1) / extrait -----
scan_carrier() {
  # $1 = chemin porteur, contenu sur stdin
  awk -v forbf="$FORBIDDEN_TMP" -v qualf="$QUALIFIER_TMP" -v carrier="$1" '
    function lower_fr(s,   r) {
      r = s
      gsub(/À/,"à",r); gsub(/Â/,"â",r); gsub(/Ä/,"ä",r); gsub(/É/,"é",r); gsub(/È/,"è",r)
      gsub(/Ê/,"ê",r); gsub(/Ë/,"ë",r); gsub(/Î/,"î",r); gsub(/Ï/,"ï",r); gsub(/Ô/,"ô",r)
      gsub(/Ö/,"ö",r); gsub(/Ù/,"ù",r); gsub(/Û/,"û",r); gsub(/Ü/,"ü",r); gsub(/Ç/,"ç",r)
      r = tolower(r)
      return r
    }
    BEGIN {
      nf = 0
      while ((getline line < forbf) > 0) { if (line != "") { nf++; forb[nf] = lower_fr(line) } }
      nq = 0
      while ((getline line < qualf) > 0) { if (line != "") { nq++; qual[nq] = lower_fr(line) } }
    }
    { lines[NR] = $0; ll[NR] = lower_fr($0) }
    END {
      for (i = 1; i <= NR; i++) {
        hit = ""
        for (k = 1; k <= nf; k++) {
          if (index(ll[i], forb[k]) > 0) { hit = forb[k]; break }
        }
        if (hit == "") continue
        win = (i > 1 ? ll[i-1] : "") " " ll[i] " " (i < NR ? ll[i+1] : "")
        qualified = 0
        for (k = 1; k <= nq; k++) { if (index(win, qual[k]) > 0) { qualified = 1; break } }
        extrait = lines[i]
        gsub(/\t/, " ", extrait)
        printf "%s\t%d\t%s\t%d\t%s\n", carrier, i, hit, qualified, extrait
      }
    }
  '
}

AFFIRMATIONS=0
QUALIFIEES=0
UNQUALIFIED_COUNT=0

while IFS= read -r p; do
  [ -z "$p" ] && continue
  content_at "$p" | scan_carrier "$p" >> "$FACTS_TMP"
done <<EOF_EXIST
$EXIST_CARRIERS
EOF_EXIST

AFFIRMATIONS=$(awk -F'\t' 'NF>0{c++} END{print c+0}' "$FACTS_TMP")
QUALIFIEES=$(awk -F'\t' '$4=="1"{c++} END{print c+0}' "$FACTS_TMP")
UNQUALIFIED_COUNT=$((AFFIRMATIONS - QUALIFIEES))

# --- Mesure, lue une seule fois, uniquement si necessaire ------------------------------------------
MESURE_STATUT="nonconsultee"
ACTIVE_COUNT=0

if [ "$UNQUALIFIED_COUNT" -gt 0 ]; then
  if ! path_exists_at "$MEASURE_FILE"; then
    MESURE_STATUT="absente"
  else
    MEASURE_JSON="$(content_at "$MEASURE_FILE")"
    MEASURED_AT=""
    ACTIVE_COUNT_RAW=""
    if command -v jq >/dev/null 2>&1 && printf '%s' "$MEASURE_JSON" | jq -e . >/dev/null 2>&1; then
      MEASURED_AT="$(printf '%s' "$MEASURE_JSON" | jq -r '.measured_at // empty')"
      ACTIVE_COUNT_RAW="$(printf '%s' "$MEASURE_JSON" | jq -r '.active_count // empty')"
    else
      # Repli awk (jq indisponible ou JSON non valide pour jq) : extraction par motif sur les deux
      # champs scalaires attendus — jamais un parseur JSON generique, juste les deux champs requis.
      MEASURED_AT="$(printf '%s' "$MEASURE_JSON" | grep -o '"measured_at"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"
      ACTIVE_COUNT_RAW="$(printf '%s' "$MEASURE_JSON" | grep -o '"active_count"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | sed -E 's/.*:[[:space:]]*//')"
    fi
    if [ -z "$MEASURED_AT" ] || [ -z "$ACTIVE_COUNT_RAW" ] || ! printf '%s' "$ACTIVE_COUNT_RAW" | grep -Eq '^[0-9]+$'; then
      MESURE_STATUT="illisible"
    else
      NOW_EPOCH="$(date -u +%s)"
      MEAS_EPOCH="$(date -u -d "$MEASURED_AT" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$MEASURED_AT" +%s 2>/dev/null || echo "")"
      if [ -z "$MEAS_EPOCH" ]; then
        MESURE_STATUT="illisible"
      else
        AGE=$((NOW_EPOCH - MEAS_EPOCH))
        [ "$AGE" -lt 0 ] && AGE=0
        if [ "$AGE" -gt "$MAX_AGE" ]; then
          MESURE_STATUT="perimee"
        else
          MESURE_STATUT="fraiche"
          ACTIVE_COUNT="$ACTIVE_COUNT_RAW"
        fi
      fi
    fi
  fi
fi

# --- Rendu des verdicts, une ligne par affirmation trouvee -----------------------------------------
RC1=0
RC2=0

while IFS="$(printf '\t')" read -r fichier lineno forme qualified extrait; do
  [ -z "$fichier" ] && continue
  if [ "$qualified" = "1" ]; then
    echo "AVERTISSEMENT-AFFIRMATION-QUALIFIEE: ${fichier}:${lineno} — ${extrait}"
    continue
  fi
  case "$MESURE_STATUT" in
    fraiche)
      if [ "$ACTIVE_COUNT" -gt 0 ] 2>/dev/null; then
        echo "AVERTISSEMENT-AFFIRMATION-CONFIRMEE-PAR-MESURE: ${fichier}:${lineno} — ${extrait}"
      else
        echo "AFFIRMATION-CONTREDITE-PAR-MESURE: ${fichier}:${lineno} — ${extrait}"
        RC1=1
      fi
      ;;
    absente|illisible|perimee)
      echo "MESURE-ABSENTE-OU-PERIMEE: ${fichier}:${lineno} — mesure ${MESURE_STATUT} — ${extrait}"
      RC2=1
      ;;
  esac
done < "$FACTS_TMP"

echo "decouverte: fichiers_portants=${FICHIERS_PORTANTS} affirmations_trouvees=${AFFIRMATIONS} qualifiees=${QUALIFIEES} mesure_statut=${MESURE_STATUT}"

if [ "$RC1" -eq 1 ]; then
  exit 1
fi
if [ "$RC2" -eq 1 ]; then
  exit 2
fi

echo "CONFORME"
exit 0
