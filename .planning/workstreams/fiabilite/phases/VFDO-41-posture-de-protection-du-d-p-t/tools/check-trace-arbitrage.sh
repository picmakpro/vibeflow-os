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
# PORTEE DE LA DETECTION — MARQUEURS D'INVOCATION EXPLICITES, LISTE FERMEE (decision du manager,
# reprise 2026-09-18). Ce controle ne rougit QUE sur une INVOCATION d'autorite humaine, reconnue
# par un jeu de marqueurs explicites et FERMES : « arbitrage Samuel », « sur arbitrage »,
# « décision de Samuel », une cle `D-01`..`D-10`, une cle generique `*-DECISION:` (n'importe quel
# prefixe suivi de `-DECISION:`), ou `REGLES_MAIN_FORCE_PUSH_SUPPRESSION`. Une mention informelle
# des mots « décision » ou « arbitrage » HORS de ces marqueurs est HORS PERIMETRE PAR CONCEPTION —
# ce n'est plus un cas qui fait rougir cet outil. Motif : une garde qui rougit sur de la prose
# descriptive apprend au lecteur a l'ignorer, et une garde qu'on apprend a ignorer ne garde plus
# rien. Fait mesure qui a conduit a ce resserrement : AVANT lui, 4 commits de la plage jugee
# rougissaient en FORME-NON-CONFORME alors qu'aucun n'invoquait la moindre autorisation humaine —
# tous des mentions informelles (« les decisions du manager du 2026-09-17 », « une citation
# d'arbitrage pourtant conforme », « anterieurs a la decision de sonde du 2026-09-17 », un message
# de commit documentant honnetement cette meme mesure) ; c'est le mode de defaut exact que cette
# phase combat, applique cette fois au detecteur lui-meme. « décision du manager » (la decision qui
# a produit CE resserrement, et le libelle que chaque commit de cette reprise doit porter par
# convention de dispatch) n'est PAS un marqueur : ce n'est pas une autorite humaine, et l'ajouter
# ferait rougir sur sa propre reformulation. Une invocation reconnue exige TOUJOURS la citation
# canonique complete (nom, canal, date ISO), comparee apres normalisation des blancs, exactement
# comme avant ce resserrement — seule la PORTE D'ENTREE (quels mots declenchent le controle) a
# change, jamais l'exigence de forme une fois la porte franchie.
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

# RESOLUTION DE RACINE — jamais un comptage de `../` (fragile a toute repartition du planning,
# defaut mesure le 2026-09-24 : la partition workstreams/fiabilite/ a insere deux niveaux entre
# `.planning/` et `phases/`, rendant NON-VERIFIABLE un controle qui rendait FORME-NON-CONFORME
# avant elle). `git rev-parse --show-toplevel` depuis SCRIPT_DIR, JAMAIS derive silencieusement :
# echoue -> DEFAULT_ROOT reste vide, et un usage reel (sans --root) sort en NON-VERIFIABLE (rc 2)
# plus bas, jamais une racine devinee.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
# 41-PREUVES.md est VOISIN du script (dossier parent de tools/), mais sa position n'est JAMAIS
# calculee depuis $0 : un script copie ailleurs pour un test de mutation (tools/test-check-*.sh)
# n'a plus ce voisinage sur le disque. Localise a la place par un SUFFIXE STABLE (le nom de la
# phase, qui ne bouge pas avec une repartition du planning) cherche sous $ROOT/.planning — jamais
# un nombre de niveaux compte. Suit le fichier quel que soit --root (racine reelle OU fixture
# jetable de test), et jamais une racine devinee : zero ou plusieurs correspondances sortent en
# NON-VERIFIABLE plus bas.
PREUVES_SUFFIX="phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md"

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
ROOT_OVERRIDDEN=0
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
      ROOT_OVERRIDDEN=1
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

if [ "$ROOT_OVERRIDDEN" -eq 0 ] && [ -z "$DEFAULT_ROOT" ]; then
  echo "NON-VERIFIABLE: impossible de resoudre la racine du depot (git rev-parse --show-toplevel a echoue depuis $SCRIPT_DIR — hors d'un arbre git, ou git absent)" >&2
  exit 2
fi

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
  if [ ! -d "$ROOT/.planning" ]; then
    echo "NON-VERIFIABLE: pas de .planning sous $ROOT — registre introuvable (suffixe attendu: $PREUVES_SUFFIX)" >&2
    exit 2
  fi
  PREUVES_MATCHES="$(find "$ROOT/.planning" -type f -path "*/$PREUVES_SUFFIX" 2>/dev/null | LC_ALL=C sort)"
  PREUVES_N=0
  if [ -n "$PREUVES_MATCHES" ]; then
    PREUVES_N="$(printf '%s\n' "$PREUVES_MATCHES" | awk 'NF{c++} END{print c+0}')"
  fi
  if [ "$PREUVES_N" -eq 0 ]; then
    echo "NON-VERIFIABLE: registre introuvable sous $ROOT/.planning (suffixe attendu: $PREUVES_SUFFIX)" >&2
    exit 2
  fi
  if [ "$PREUVES_N" -gt 1 ]; then
    echo "NON-VERIFIABLE: registre ambigu, $PREUVES_N correspondances sous $ROOT/.planning (suffixe attendu: $PREUVES_SUFFIX)" >&2
    exit 2
  fi
  PREUVES_PATH="$(printf '%s\n' "$PREUVES_MATCHES" | head -1)"
  BASE_SOURCE="$PREUVES_PATH (localise par suffixe stable)"
  BASE_RAW="$(awk '/^BASE-TRACE-ARBITRAGE: /{sub(/^BASE-TRACE-ARBITRAGE: /, ""); print; exit}' "$PREUVES_PATH")"
  if [ -z "$BASE_RAW" ]; then
    echo "NON-VERIFIABLE: cle BASE-TRACE-ARBITRAGE absente ou illisible dans $PREUVES_PATH" >&2
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

# MARQUEURS D'INVOCATION — LISTE FERMEE ET EXPLICITE (voir PORTEE DE LA DETECTION en en-tete).
# Regex etendue (ERE, testee via `[[ =~ ]]` bash) : chaque alternative est un marqueur EXACT, pas
# un mot-racine generique. « décision du manager » n'y figure PAS (decision du manager elle-meme,
# point 3 : ce n'est pas une autorite humaine).
# BORNE SYMETRIQUE, LES DEUX COTES DE D-NN (revue F5, 2026-09-18) : le cote gauche exclut deja le
# tiret ([^0-9A-Za-z_-]) pour qu'un identifiant compose ne matche pas ("xD-01" ne matche pas) ;
# avant le fix, le cote droit ([^0-9A-Za-z_]) omettait le tiret et laissait "D-01-suite" matcher a
# tort (un identifiant compose se terminant par un suffixe, jamais une citation D-NN reelle).
MARKER_REGEX='arbitrage Samuel|sur arbitrage|décision de Samuel|(^|[^0-9A-Za-z_-])D-(0[1-9]|10)([^0-9A-Za-z_-]|$)|[A-Za-z0-9_]+-DECISION:|REGLES_MAIN_FORCE_PUSH_SUPPRESSION'
CANON="arbitrage Samuel, AskUserQuestion session principale, 2026-09-17"

# IDENTIFIANTS EXCLUS DE LA DETECTION DE MARQUEUR (pas du texte imprime). Le nom de fichier
# `check-baseline-arbitrage.sh` contient le jeton `arbitrage` comme simple COMPOSANT
# D'IDENTIFIANT (script G-1), jamais comme citation d'un arbitrage humain — le mentionner (dans
# un message de commit, un trailer Gate-Touche, ...) ne doit pas etre traite comme une tentative
# de citation. Retire AVANT la detection de marqueur et l'extraction de citation ; la chaine
# imprimee en cas d'ecart reste `$norm` (non filtree), pour ne rien cacher au lecteur.
FILENAME_TOKENS="check-baseline-arbitrage.sh check-baseline-arbitrage"

scan_strip() {  # <chaine normalisee> -> meme chaine, identifiants de fichier retires
  local s="$1" tok
  for tok in $FILENAME_TOKENS; do
    s="${s//$tok/}"
  done
  printf '%s' "$s"
}

kw_present() {  # <chaine de scan> -> exit 0 si au moins un marqueur d'invocation EXACT est present
  local s="$1"
  [[ "$s" =~ $MARKER_REGEX ]]
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
