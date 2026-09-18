#!/usr/bin/env bash
# check-trace-arbitrage.sh — Phase 41 (PROT-04, QUAL-01), plan 41-15, Task 2. Controle de FORME
# et d'UNICITE de la citation d'arbitrage/decision sur les commits NON-MERGE-EPHEMERE de la plage
# <base>..HEAD, ou <base> est LUE dans la ligne `BASE-TRACE-ARBITRAGE:` du registre
# `41-PREUVES.md` — jamais derivee par `merge-base` ni par l'adjacence `HEAD^` (bloquant 1 du
# verificateur frais, decision du manager du 2026-09-17). Ne verifie JAMAIS la veracite de
# l'arbitrage — seulement sa FORME (nom, canal, date ISO) : « un simple "arbitrage Samuel" a la
# meme forme qu'il soit vrai ou fabrique », et c'est justement la forme longue qui rend
# l'attribution relisable (CLAUDE.md, § Tracabilite des arbitrages). L'attribution reste un geste
# humain relisable, jamais une garantie machine.
#
# BORNE DE PORTEE, PAS DEVINEE, AVEC SON MOTIF MESURE. Les commits ANTERIEURS a
# BASE-TRACE-ARBITRAGE — cadrage, planification, decisions de recadrage — precedent la garde et ne
# sont PAS rejuges. Rejoue sans borne sur `5238cba..HEAD`, ce controle rendait 8 commits fautifs
# qu'aucun plan de cette phase ne peut corriger (ils sont anterieurs a la Phase 41 elle-meme), ce
# qui en aurait fait un rouge permanent — donc un verificateur qu'on finit par desarmer. La garde
# juge ce que la phase ECRIT ENCORE, et le dit.
#
# BORNE DU MERGE EPHEMERE DE GITHUB. Un commit dont le message entier (normalise) correspond a
# « Merge <40 hex> into <40 hex> » est un artefact de fusion genere par GitHub pour previsualiser
# une PR, jamais ecrit par un humain ni par un agent de la phase — son diff premier-parent
# porterait tout le contenu de la PR et son message ne peut jamais porter de citation. Il est
# exclu du compte de decouverte ET de l'imputation.
#
# NORMALISATION DES BLANCS AVANT TOUTE COMPARAISON (bloquant 1 (a) du verificateur frais). Le
# message integral de chaque commit (`git log -1 --format=%B`) est joint en une seule chaine
# (retours a la ligne remplaces par une espace), puis toute suite de blancs est reduite a une
# espace unique, tetes et queues retirees. Toutes les comparaisons portent sur cette chaine
# normalisee, JAMAIS sur les lignes brutes : une citation coupee en fin de ligne est CONFORME —
# la refuser serait le meme faux rouge que celui deja corrige sur le ledger de ce depot.
#
# CODES DE SORTIE.
#   0  plage non vide, tous les commits juges conformes
#   1  au moins un ecart : FORME-NON-CONFORME, CITATIONS-MULTIPLES, ou
#      ARBITRAGE-DE-PERIMETRE-MAL-CITE
#   2  hors d'un arbre git, ou BASE-TRACE-ARBITRAGE absente/illisible/non hexadecimale/non
#      resoluble en commit dans ce depot (NON-VERIFIABLE — jamais un vert, jamais un repli
#      silencieux sur merge-base ou HEAD^)
#   3  PLAGE-VIDE : borne egale HEAD, ou zero commit juge apres exclusion des merges ephemeres
#   64 argument invalide (option inconnue, --base-ref sans valeur, --root sans valeur ou
#      inexistant)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PREUVES_REL=".planning/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md"

usage() {
  cat <<'USAGE'
Usage: check-trace-arbitrage.sh [--root DIR] [--base-ref REF] [-h|--help]

--base-ref ne sert QU'AUX FIXTURES de test : sur un usage reel, la base est LUE dans
BASE-TRACE-ARBITRAGE: du registre 41-PREUVES.md, jamais derivee.

Codes de sortie :
  0  plage non vide, tous les commits juges conformes
  1  au moins un ecart (FORME-NON-CONFORME, CITATIONS-MULTIPLES, ARBITRAGE-DE-PERIMETRE-MAL-CITE)
  2  hors d'un arbre git, ou BASE-TRACE-ARBITRAGE absente/illisible/non resoluble en commit
  3  PLAGE-VIDE
  64 argument invalide
USAGE
}

ROOT="$DEFAULT_ROOT"
BASE_REF_OVERRIDE=""
HAS_BASE_REF_OVERRIDE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      if [ $# -lt 2 ]; then
        echo "ERREUR: --root requiert une valeur" >&2
        exit 64
      fi
      ROOT="$2"
      shift 2
      ;;
    --base-ref)
      if [ $# -lt 2 ]; then
        echo "ERREUR: --base-ref requiert une valeur" >&2
        exit 64
      fi
      BASE_REF_OVERRIDE="$2"
      HAS_BASE_REF_OVERRIDE=1
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERREUR: option inconnue: $1" >&2
      exit 64
      ;;
  esac
done

if [ ! -d "$ROOT" ]; then
  echo "ERREUR: racine inexistante: $ROOT" >&2
  exit 64
fi
ROOT="$(cd "$ROOT" && pwd)"

if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERREUR: hors d'un arbre git: $ROOT" >&2
  exit 2
fi

# ---------------------------------------------------------------------------------------------
# RESOLUTION DE LA BASE — LUE, JAMAIS DERIVEE. --base-ref ne sert qu'aux fixtures de test.
# ---------------------------------------------------------------------------------------------
if [ "$HAS_BASE_REF_OVERRIDE" -eq 1 ]; then
  BASE_RAW="$BASE_REF_OVERRIDE"
  BASE_SOURCE="--base-ref (fixture)"
else
  PREUVES_PATH="$ROOT/$PREUVES_REL"
  BASE_SOURCE="$PREUVES_REL"
  if [ ! -f "$PREUVES_PATH" ]; then
    echo "NON-VERIFIABLE: registre absent: $PREUVES_REL" >&2
    exit 2
  fi
  BASE_RAW="$(awk '/^BASE-TRACE-ARBITRAGE: /{sub(/^BASE-TRACE-ARBITRAGE: /, ""); print; exit}' "$PREUVES_PATH")"
  if [ -z "$BASE_RAW" ]; then
    echo "NON-VERIFIABLE: cle BASE-TRACE-ARBITRAGE absente ou illisible dans $PREUVES_REL" >&2
    exit 2
  fi
fi

case "$BASE_RAW" in
  *[!0-9a-fA-F]*)
    echo "NON-VERIFIABLE: valeur BASE-TRACE-ARBITRAGE non hexadecimale: $BASE_RAW" >&2
    exit 2
    ;;
esac

BASE_SHA="$(git -C "$ROOT" rev-parse --verify -q "${BASE_RAW}^{commit}" 2>/dev/null || true)"
if [ -z "$BASE_SHA" ]; then
  echo "NON-VERIFIABLE: BASE-TRACE-ARBITRAGE ne resout pas en commit dans ce depot: $BASE_RAW" >&2
  exit 2
fi

HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD)"
echo "borne: sha=$BASE_SHA source=$BASE_SOURCE"

# ---------------------------------------------------------------------------------------------
# DECOUVERTE — merges compris, sauf le merge ephemere de GitHub (exclu de n ET de l'imputation).
# ---------------------------------------------------------------------------------------------
normalize() {  # <message brut> sur stdin -> chaine normalisee sur stdout (une seule ligne)
  tr '\n' ' ' | tr -s '[:space:]' ' ' | sed -e 's/^ //' -e 's/ $//'
}

is_ephemeral_merge() {  # <message normalise> sur stdin -> exit 0 si forme "Merge <hex40> into <hex40>"
  grep -Eq '^Merge [0-9a-fA-F]{40} into [0-9a-fA-F]{40}$'
}

KEYWORDS="arbitrage arbitrages décision décisions decision decisions"
CANON="arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"

# IDENTIFIANTS EXCLUS DE LA DETECTION DE MOT-CLE (pas du texte imprime). Le nom de fichier
# `check-baseline-arbitrage.sh` contient le jeton `arbitrage` comme simple COMPOSANT
# D'IDENTIFIANT (script G-1), jamais comme citation d'un arbitrage humain — le mentionner (dans
# un message de commit, un trailer Gate-Touche, ...) ne doit pas etre traite comme une tentative
# de citation. Retire AVANT la detection de mot-cle et l'extraction de citation ; la chaine
# imprimee en cas d'ecart reste `$norm` (non filtree), pour ne rien cacher au lecteur.
FILENAME_TOKENS="check-baseline-arbitrage.sh check-baseline-arbitrage"

scan_strip() {  # <chaine normalisee> -> meme chaine, identifiants de fichier retires
  local s="$1" tok
  for tok in $FILENAME_TOKENS; do
    s="${s//$tok/}"
  done
  printf '%s' "$s"
}

kw_present() {  # <chaine de scan> -> exit 0 si au moins un mot-cle est present
  local s="$1" k
  for k in $KEYWORDS; do
    case "$s" in *"$k"*) return 0 ;; esac
  done
  return 1
}

N=0
M=0
DEVIATIONS=0

ALL_SHAS="$(git -C "$ROOT" rev-list --reverse "${BASE_SHA}..${HEAD_SHA}" 2>/dev/null || true)"

while IFS= read -r sha; do
  [ -n "$sha" ] || continue
  raw_msg="$(git -C "$ROOT" log -1 --format=%B "$sha")"
  norm="$(printf '%s\n' "$raw_msg" | normalize)"

  if printf '%s\n' "$norm" | is_ephemeral_merge; then
    continue
  fi
  N=$((N + 1))

  scan="$(scan_strip "$norm")"
  if ! kw_present "$scan"; then
    continue
  fi
  M=$((M + 1))

  short="$(git -C "$ROOT" rev-parse --short "$sha")"

  # Comparaison 1 + 2 — extraction des citations CONFORMES distinctes (mot-cle, deux virgules,
  # date ISO), sur la chaine de scan (identifiants de fichier retires). PORTEE BORNEE entre
  # mot-cle/virgules/date ({0,80} caracteres, ni virgule ni point) : une citation reelle est
  # courte et locale (« arbitrage Samuel, AskUserQuestion session principale, 2026-09-17 ») ; sans
  # cette borne, `[^,]*` non borne peut relier deux virgules et une date SANS RAPPORT situees
  # dans un paragraphe ou un trailer plus loin dans un long message de commit, fabriquant une
  # fausse conformite (mesure empiriquement pendant l'ecriture de cet outil, mandat elargi
  # 2026-09-18).
  matches="$(printf '%s\n' "$scan" | awk '
    {
      s = $0
      while (match(s, /(arbitrage|arbitrages|décision|décisions|decision|decisions)[^,.]{0,80},[^,.]{0,80},[^,.]{0,40}[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
        print substr(s, RSTART, RLENGTH)
        s = substr(s, RSTART + RLENGTH)
      }
    }
  ' | LC_ALL=C sort -u)"
  nmatches=0
  if [ -n "$matches" ]; then
    nmatches="$(printf '%s\n' "$matches" | awk 'NF{c++} END{print c+0}')"
  fi

  if [ "$nmatches" -eq 0 ]; then
    echo "$short FORME-NON-CONFORME : $norm"
    DEVIATIONS=$((DEVIATIONS + 1))
    continue
  fi
  if [ "$nmatches" -gt 1 ]; then
    echo "$short CITATIONS-MULTIPLES : $norm"
    DEVIATIONS=$((DEVIATIONS + 1))
    continue
  fi

  # Comparaison 3 — arbitrage du perimetre : forme generique conforme, mais si le commit cite
  # `arbitrage` ET la date `2026-09-17`, il doit porter la chaine EXACTE de l'arbitrage du
  # perimetre (comparee elle aussi apres normalisation, donc insensible a une coupure de ligne).
  # Sur `$scan` (identifiants de fichier retires), meme raison que comparaison 1.
  has_arbitrage=0
  case "$scan" in *arbitrage*) has_arbitrage=1 ;; esac
  has_date_perimetre=0
  case "$scan" in *"2026-09-17"*) has_date_perimetre=1 ;; esac
  if [ "$has_arbitrage" -eq 1 ] && [ "$has_date_perimetre" -eq 1 ]; then
    case "$norm" in
      *"$CANON"*) : ;;
      *)
        echo "$short ARBITRAGE-DE-PERIMETRE-MAL-CITE : $norm"
        DEVIATIONS=$((DEVIATIONS + 1))
        continue
        ;;
    esac
  fi
done <<EOF
$ALL_SHAS
EOF

echo "decouverte: commits=$N citants=$M"

if [ "$N" -eq 0 ]; then
  echo "PLAGE-VIDE: borne=$BASE_SHA HEAD=$HEAD_SHA (aucun commit juge apres exclusion des merges ephemeres)"
  exit 3
fi

if [ "$DEVIATIONS" -gt 0 ]; then
  exit 1
fi
exit 0
