#!/usr/bin/env bash
# check-aucune-fermeture.sh — Phase 41 (PROT-04, QUAL-01), plan 41-15. Recense, dans un perimetre
# de fichiers versionnes, toute ligne ou un JETON DE SUJET (O-3, une garde de la phase, ou l'un des
# trois scripts qui les portent) co-occurre avec un JETON D'ACHEVEMENT (une forme de « ferme » ou
# « close »), NEGATIONS COMPRISES : une tournure niee ne dispense pas — seule une entree nominative
# de l'allowlist versionnee (comparaison 2) dispense. Porte aussi une seconde sonde (comparaison 3) :
# chaque artefact PORTEUR qui existe doit enoncer sa propre limite de fond, faute de quoi la garde
# resterait affirmee sans jamais dire qu'elle peut etre neutralisee par la PR qu'elle juge.
#
# ORIGINE. La contrainte de fond de la Phase 41 veut qu'aucun texte du depot n'affirme l'achevement
# d'une garde ni d'O-3 (25-SECURITY.md) — une contrainte qu'aucune machine ne verifie est une
# intention, pas une garantie (lecon « une preuve doit pouvoir rendre rouge », Phase 39, dix
# verificateurs incapables d'echouer). Toute garde in-repo de cette phase porte la MEME limite de
# fond : elle vit dans le depot, la PR qu'elle juge peut l'amender ; elle rend visible et trace, elle
# ne verrouille rien — cette limite doit etre LISIBLE dans chaque artefact porteur, jamais seulement
# affirmee dans un en-tete que rien ne mesure (avertissement 7 du verificateur frais, decision du
# manager du 2026-09-17 : la cle auto-declarative anterieure `ecrite_en_entete=oui` est supprimee).
#
# CLAUDE.md HORS DE LA LISTE DES PORTEURS, A CE STADE (mandat elargi du manager de mission, reprise
# du 2026-09-18, point 3). C'est le plan 41-18 (G-4) qui ECRIT la doctrine de cette phase dans
# `CLAUDE.md` — l'exiger comme porteur AVANT que ce contenu existe reviendrait a punir un fichier de
# ne pas porter une formule que personne n'y a encore posee. La sonde n'exige un artefact que s'il
# existe DEJA ou est CENSE exister a ce stade de la phase (cf. R11 : un artefact absent n'est jamais
# compte en manquants). `CLAUDE.md` redevient un porteur EXIGE a partir du plan 41-18 (qui y ecrit la
# formule) ; le controle final de cloture 41-19 l'inclura dans son compte complet. Ecrit ici
# explicitement pour qu'un lecteur ne prenne pas cette absence pour un oubli.
#
# JETONS. Le sujet et l'achevement sont des donnees de configuration (comparaison 1 plus bas), pas
# une phrase redigee : cet outil vit sous `.planning/phases/VFDO-41-.../tools/`, HORS du perimetre
# qu'il scanne (`scripts/check-*.sh` ne le designe pas) — il ne peut donc pas se signaler lui-meme.
# S'il etait un jour deplace sous `scripts/`, ses jetons devraient etre reconstruits par
# concatenation de fragments (discipline du plan 41-15), pour la meme raison.
#
# BORNE VOLONTAIRE 1 — `gate`/`gates` HORS des sujets. La cloture d'une EXIGENCE (« BUDG-02 close
# le ... ») est un autre objet que la cloture d'une garde ou d'O-3 ; les inclure rendrait le
# recensement si bruyant qu'il finirait desarme.
# BORNE VOLONTAIRE 2 — la forme verbale nue « ferme » (sans accent) est HORS des jetons
# d'achevement, pour que la doctrine « on ne ferme rien » reste ecrivable sans faux positif.
#
# PERIMETRE. Derive par `git ls-files` sur des pathspecs ECRITS ci-dessous. EXCLUSIONS NOMINATIVES,
# avec leur raison : les fichiers `41-*-PLAN.md` (un plan prescrit l'interdiction, donc il la cite)
# et `41-CONTEXT.md` (cadrage fige du perimetre differe, porteur des formulations de D-02). Les
# SUMMARY, eux, restent DANS le perimetre : ce sont eux qui font des affirmations. Mesure de
# reference : 16 fichiers le 2026-09-17 sur HEAD `c8489fc` (les globs de SUMMARY n'en appariaient
# encore aucun).
#
# CODES DE SORTIE.
#   0  perimetre non vide, aucune co-occurrence hors allowlist, aucun artefact porteur muet
#   1  au moins une co-occurrence non dispensee, ou au moins un artefact porteur muet
#   2  perimetre vide (racine hors depot git, ou aucun chemin du perimetre present)
#   64 argument invalide (option inconnue, --root sans valeur ou inexistant)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

usage() {
  cat <<'USAGE'
Usage: check-aucune-fermeture.sh [--root DIR] [-h|--help]

Codes de sortie :
  0  perimetre non vide, aucune co-occurrence hors allowlist, aucun artefact porteur muet
  1  au moins une co-occurrence non dispensee, ou au moins un artefact porteur muet
  2  perimetre vide (racine hors depot git, ou aucun chemin du perimetre present)
  64 argument invalide (option inconnue, --root sans valeur ou inexistant)
USAGE
}

ROOT="$DEFAULT_ROOT"
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

# ---------------------------------------------------------------------------------------------
# PERIMETRE — pathspecs ecrits ici, jamais decouverts ailleurs.
# ---------------------------------------------------------------------------------------------
PATHSPECS="scripts/check-*.sh scripts/tests/test-*.sh docs/ADR.md CLAUDE.md CHANGELOG.md .planning/BACKLOG.md .planning/REQUIREMENTS.md .planning/phases/VFDO-25-*/25-SECURITY.md .planning/phases/VFDO-41-*/41-*-SUMMARY.md .planning/phases/VFDO-41-*/41-PREUVES.md .github/workflows/ci.yml"

RAW_LIST="$(cd "$ROOT" && git ls-files -- $PATHSPECS 2>/dev/null | LC_ALL=C sort)"

FILES=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    .planning/phases/VFDO-41-*/41-*-PLAN.md) continue ;;
    .planning/phases/VFDO-41-*/41-CONTEXT.md) continue ;;
  esac
  FILES+=("$f")
done <<EOF
$RAW_LIST
EOF

NFILES=${#FILES[@]}
echo "perimetre: fichiers=$NFILES"
# MUT-2 cible cette ligne exacte : neutraliser cette assertion rend le perimetre vide invisible.
if [ "$NFILES" -eq 0 ]; then exit 2; fi

# ---------------------------------------------------------------------------------------------
# COMPARAISON 1 — co-occurrence sujet x achevement, en awk (jamais un grep -c).
# ---------------------------------------------------------------------------------------------
SUJ="O-3 garde Garde gardes Gardes check-baseline-arbitrage check-gate-touche check-push-sans-pr"
ACH="fermé Fermé fermée fermés fermées clos Clos close Close closes closed"

CANDIDATS="$(cd "$ROOT" && awk -v SUJ="$SUJ" -v ACH="$ACH" '
  BEGIN {
    nS = split(SUJ, S, " ")
    nA = split(ACH, A, " ")
  }
  {
    hs = 0
    for (i = 1; i <= nS; i++) { if (index($0, S[i]) > 0) { hs = 1; break } }
    ha = 0
    for (i = 1; i <= nA; i++) { if (index($0, A[i]) > 0) { ha = 1; break } }
    if (hs == 1 && ha == 1) { print FILENAME ":" FNR ":" $0 }
  }
' "${FILES[@]}" 2>/dev/null)"

# ---------------------------------------------------------------------------------------------
# COMPARAISON 2 — allowlist versionnee, par ligne NORMALISEE exacte (tetes/queues d'espaces
# retirees), avec sa raison. Amorcee par les TROIS seules lignes heritees mesurees le 2026-09-17
# sur HEAD `c8489fc`. Toute quatrieme entree est un diff visible, a justifier.
# ---------------------------------------------------------------------------------------------
ALLOW_CONTENT=()
ALLOW_REASON=()
ALLOW_APPLIED=()
_pending_reason=""
while IFS= read -r _al_line; do
  case "$_al_line" in
    '# raison: '*)
      _pending_reason="${_al_line#\# raison: }"
      ;;
    '')
      ;;
    *)
      ALLOW_CONTENT+=("$_al_line")
      ALLOW_REASON+=("$_pending_reason")
      ALLOW_APPLIED+=(0)
      _pending_reason=""
      ;;
  esac
done <<'ALLOWLIST_EOF'
# raison: verbe « garder » (mesure d'un outil) + clôture d'une EXIGENCE (BUDG-04) — deux objets distincts, jamais une garde ni O-3
- [x] **BUDG-04**: Le plafond ADR-029 des agents vaut 300 lignes partout où il est énoncé ou mesuré (gate, CI, suites de modules, auditeur de densité et méthodologie distribués, doctrine, manuel), avec un avertissement non bloquant dès 251 ; chaque outil garde sa mesure (fichier entier ou body) — Phase 40.1, D-01/D-05/D-06 — **close le 2026-09-17** (plan 40.1-14) : recensement versionné final rc 0, contrôles négatifs vérifiés (fixtures et clone réel), rejeu CI tests+gates vert

# raison: colonne « closed » de la table STRIDE, portée sur la MENACE T-25-16 — jamais sur l'observation O-3 citée à côté
| T-25-16 | Tampering | hausse d'une baseline sans arbitrage | high | mitigate | P-16 (+ observation O-3) | closed |

# raison: ligne historique du CHANGELOG, événement daté déjà survenu — jamais une déclaration sur O-3 ni sur une garde de la Phase 41
Windows sans privilège symlink) fermé par garde d'existence, T12 assertant l'owner
ALLOWLIST_EOF

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

HITS=0
if [ -n "$CANDIDATS" ]; then
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    path="${cand%%:*}"
    rest="${cand#*:}"
    lineno="${rest%%:*}"
    content="${rest#*:}"
    norm="$(trim "$content")"
    dispense=0
    idx=0
    while [ "$idx" -lt "${#ALLOW_CONTENT[@]}" ]; do
      if [ "$norm" = "${ALLOW_CONTENT[$idx]}" ]; then
        dispense=1
        ALLOW_APPLIED[$idx]=1
        break
      fi
      idx=$((idx + 1))
    done
    if [ "$dispense" -eq 0 ]; then
      echo "$path:$lineno:$content"
      HITS=$((HITS + 1))
    fi
  done <<EOF
$CANDIDATS
EOF
fi

ALLOW_N=${#ALLOW_CONTENT[@]}
ALLOW_M=0
for a in "${ALLOW_APPLIED[@]:-}"; do
  [ "$a" = "1" ] && ALLOW_M=$((ALLOW_M + 1))
done
echo "allowlist: entrees=$ALLOW_N appliquees=$ALLOW_M"

# ---------------------------------------------------------------------------------------------
# COMPARAISON 3 — sonde de limite de fond (avertissement 7, decision du manager du 2026-09-17).
# Chaque artefact PORTEUR qui EXISTE doit contenir le fragment canonique, cherche APRES
# normalisation des blancs (lignes jointes, suites de blancs reduites a une espace) : une formule
# coupee par un retour a la ligne reste conforme. Un artefact qui n'existe pas encore n'est pas
# manquant.
# ---------------------------------------------------------------------------------------------
FRAGMENT="modifiée par la PR qu'elle juge"
# MUT-3 cible cette ligne exacte : la faire passer a 0 neutralise la sonde sans toucher au
# comptage exiges/porteurs.
REQUIRE_FRAGMENT=1

fragment_present() {
  local norm
  norm="$(printf '%s' "$1" | tr '\n' ' ' | tr -s '[:space:]' ' ')"
  case "$norm" in
    *"$FRAGMENT"*) return 0 ;;
    *) return 1 ;;
  esac
}

EXIGES=0
PORTEURS_N=0
MANQUANTS=()

# CLAUDE.md est volontairement ABSENT de cette liste a ce stade — voir le paragraphe d'en-tete
# « CLAUDE.md HORS DE LA LISTE DES PORTEURS ». Ne pas le rajouter avant le plan 41-18.
FIXED_PORTEURS="scripts/check-baseline-arbitrage.sh scripts/check-gate-touche.sh scripts/check-push-sans-pr.sh .github/workflows/ci.yml"
for p in $FIXED_PORTEURS; do
  EXIGES=$((EXIGES + 1))
  if [ -f "$ROOT/$p" ]; then
    PORTEURS_N=$((PORTEURS_N + 1))
    content="$(cat "$ROOT/$p" 2>/dev/null)"
    if [ "$REQUIRE_FRAGMENT" -eq 1 ] && ! fragment_present "$content"; then
      echo "LIMITE-DE-FOND-ABSENTE: $p"
      MANQUANTS+=("$p")
    fi
  fi
done

# ADR-072 : artefact = la SECTION, pas le fichier entier. Section absente -> pas encore cree.
EXIGES=$((EXIGES + 1))
if [ -f "$ROOT/docs/ADR.md" ]; then
  ADR_SECTION="$(awk '
    /^## ADR-072/ { flag = 1; print; next }
    /^## / { if (flag) exit }
    flag { print }
  ' "$ROOT/docs/ADR.md")"
  if [ -n "$ADR_SECTION" ]; then
    PORTEURS_N=$((PORTEURS_N + 1))
    if [ "$REQUIRE_FRAGMENT" -eq 1 ] && ! fragment_present "$ADR_SECTION"; then
      echo "LIMITE-DE-FOND-ABSENTE: docs/ADR.md (section ## ADR-072)"
      MANQUANTS+=("docs/ADR.md (section ## ADR-072)")
    fi
  fi
fi

# Summaries de la Phase 41 (41-1*-SUMMARY.md) — liste dynamique, chacun exige des sa creation.
SUMMARIES=()
_summ_dir="$ROOT/.planning/phases"
if [ -d "$_summ_dir" ]; then
  for d in "$_summ_dir"/VFDO-41-*; do
    [ -d "$d" ] || continue
    for f in "$d"/41-1*-SUMMARY.md; do
      [ -e "$f" ] || continue
      rel="${f#"$ROOT"/}"
      SUMMARIES+=("$rel")
    done
  done
fi
for s in "${SUMMARIES[@]:-}"; do
  [ -n "$s" ] || continue
  EXIGES=$((EXIGES + 1))
  PORTEURS_N=$((PORTEURS_N + 1))
  content="$(cat "$ROOT/$s" 2>/dev/null)"
  if [ "$REQUIRE_FRAGMENT" -eq 1 ] && ! fragment_present "$content"; then
    echo "LIMITE-DE-FOND-ABSENTE: $s"
    MANQUANTS+=("$s")
  fi
done

if [ ${#MANQUANTS[@]} -eq 0 ]; then
  MQ="aucun"
else
  MQ="$(IFS=,; echo "${MANQUANTS[*]}")"
fi
echo "limite: exiges=$EXIGES porteurs=$PORTEURS_N manquants=$MQ"

if [ "$HITS" -gt 0 ] || [ ${#MANQUANTS[@]} -gt 0 ]; then
  exit 1
fi
exit 0
