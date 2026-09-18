#!/usr/bin/env bash
# check-gate-touche.sh — G-2 (PROT-05). Rend visible et trace le fait qu'une PR modifie CE QUI LA
# JUGE — un gate, sa suite, l'etape CI qui l'invoque, ou un hook — en exigeant un marqueur
# declaratif `Gate-Touche: <chemin-ou-motif> — <raison>` dans un commit non-merge de la branche.
#
# ORIGINE. Traite la seconde phrase d'O-3 du `25-SECURITY.md` : « une meme PR peut modifier le
# gate, sa suite et l'etape CI » cesse d'etre invisible. Faute d'acces admin sur ce depot (option
# (a), arbitrage Samuel, AskUserQuestion session principale, 2026-09-17), aucune regle cote
# GitHub ne peut empecher cette meme PR de neutraliser le gate qu'elle juge. G-2 ne l'empeche pas :
# elle le SIGNALE ET LE TRACE.
#
# LIMITE DE FOND, a lire avant tout le reste, vraie de CETTE garde en PREMIER LIEU. Ce script VIT
# DANS LE DEPOT, dans la surface qu'il surveille lui-meme (`scripts/check-*.sh`) : la PR qu'il juge
# peut modifier ce script, sa suite `scripts/tests/test-check-gate-touche.sh`, et l'etape CI qui
# l'invoque, et rester verte. Il REND VISIBLE et TRACE une modification de la surface de gate ; il
# NE VERROUILLE RIEN. Aucun droit admin n'existe dans ce perimetre pour poser une regle cote GitHub
# qui empecherait cette meme PR de neutraliser le gate.
#
# FORMULE CANONIQUE (sonde de limite de fond, check-aucune-fermeture.sh, plan 41-15, mandat elargi
# du manager de mission, 2026-09-17) : cette garde peut etre modifiée par la PR qu'elle juge —
# reprise ici mot pour mot pour que la sonde ne signale plus ce script comme muet sur sa propre
# limite de fond.
#
# CINQ CLASSES DE LA SURFACE SURVEILLEE, ecrites en toutes lettres, celle-la meme et aucune autre :
#   1. plugin/conductor/scripts/check-*.sh   (un seul niveau, jamais un chemin plus profond)
#   2. scripts/check-*.sh                    (un seul niveau, jamais un chemin plus profond)
#   3. leurs suites : plugin/conductor/scripts/tests/test-*.sh ET scripts/tests/test-*.sh
#      (une seule classe combinee — un mutant qui neutralise cette classe retire les DEUX chemins)
#   4. .github/workflows/ci.yml              (chemin exact, pas un motif)
#   5. tout chemin commencant par scripts/hooks/ (profondeur libre)
# BORNE NOMMEE, JAMAIS UN OUBLI : les gates des AUTRES modules (par exemple
# plugin/dev-orchestrator/scripts/check-*.sh, plugin/software-architecture/scripts/check-file-size.sh)
# sont HORS SURFACE par l'arbitrage du perimetre du 2026-09-17 (sans acces admin, la phase 41 ne
# couvre que ce que le role `write` peut poser : ce depot n'a aucun CODEOWNERS qui distinguerait un
# module d'un autre). Un gate d'un autre module touche seul ne rougit JAMAIS cette garde — c'est un
# controle negatif exerce par sa suite, pas un angle mort tolere en silence.
#
# MARQUEUR DECLARATIF, JAMAIS DE VERACITE VERIFIEE. Un trailer conforme est reconnu a sa FORME
# SEULE : `Gate-Touche: <chemin-ou-motif> — <raison de 10 caracteres non blancs au moins>`. Le
# separateur NOMINAL est le tiret cadratin ` — ` ; le tiret simple ` - ` est AUSSI ACCEPTE — borne
# ASCII ecrite ici pour qu'un environnement qui mange l'UTF-8 (terminal, hook, pipe CI) ne fabrique
# jamais un faux rouge sur un trailer par ailleurs legitime. La garde ne verifie JAMAIS que la
# raison citee correspond a la realite de la modification : un trailer fabrique passe la garde,
# choix assume (repudiation, T-41-69), coherent avec la convention de tracabilite du `CLAUDE.md` —
# le fait redevient relisable, l'attribution reste humaine.
#
# PORTEE BRANCHE, PAS COMMIT. Le marqueur peut vivre dans N'IMPORTE QUEL commit non-merge de la
# plage <base>..HEAD — pas necessairement celui qui touche le chemin. Consequence explicite : un
# chemin touche AVANT L'EXISTENCE de cette garde reste couvrable par un commit de documentation
# ULTERIEUR de la meme branche, sans jamais amender ni reecrire un commit deja pousse.
#
# VERT A VIDE INTERDIT. rc 0 n'est rendu que si AU MOINS UN chemin de la surface est touche ET
# couvert. Zero chemin de la surface touche, ou plage vide, rendent rc 3 — jamais rc 0 : la plupart
# des PR de ce depot ne touchent rien de cette surface, et ce silence ne doit jamais se lire comme
# un succes de la garde.
#
# CASCADE DE RESOLUTION DE LA BASE (nommee, imprimee sur echec) : valeur de --base-ref si fournie,
# sinon la premiere ref qui resout parmi refs/remotes/origin/main, origin/main, refs/heads/main,
# main. Aucune ne resout -> rc 2. La base est ENSUITE `git merge-base HEAD <ref>` — JAMAIS
# l'adjacence du journal (`HEAD^`), jamais un tri par date : une base mal derivee rendrait la garde
# aveugle a la toute premiere modification de surface d'une branche a plusieurs commits.
#
# QUATRE COMPARAISONS.
#   1. Appartenance a la surface — `git diff --name-status <base> HEAD`, lu UNE SEULE FOIS,
#      classe chaque chemin touche (statuts A/M/D/R tous comptes comme « touche » — un gate
#      supprime est la modification la plus radicale).
#   2. Recolte des marqueurs — messages de TOUS les commits de `git rev-list <base>..HEAD`,
#      merges compris (un commit de documentation peut porter les trailers d'un lot).
#   3. Forme du marqueur — separateur + raison, decrits plus haut ; un trailer non conforme est
#      IGNORE pour la couverture et signale par MARQUEUR-MAL-FORME, ligne recopiee. BORNE SUR LE
#      MOTIF, nommee ici et pas seulement dans le code : un motif (premier champ, avant le
#      separateur) qui contient une VIRGULE LITTERALE est TOUJOURS MARQUEUR-MAL-FORME, meme si le
#      reste de la forme (separateur, raison de 10 caracteres) est par ailleurs correct. Raison :
#      `case "$chemin" in ($motif)` (comparaison 4) ne fait JAMAIS d'union sur une virgule — un
#      motif du genre `a.sh, b.sh` ne matchera JAMAIS ni `a.sh` ni `b.sh` via `case`, il se
#      declarerait conforme sans jamais rien couvrir. Angle mort mesure : le commit `6e7c727`
#      (plan 41-14) porte exactement ce trailer, inoffensif aujourd'hui puisque les deux chemins
#      qu'il visait sont couverts par ailleurs — mais un futur contributeur qui reprendrait ce
#      style croirait couvrir deux chemins avec un seul trailer et se retrouverait avec une
#      couverture nulle, sans diagnostic pointant la vraie cause. « Un trailer = un chemin ou
#      motif, jamais une liste separee par virgule. »
#   4. Correspondance chemin <-> motif — `case "$chemin" in ($motif) …` (jamais `eval`, jamais une
#      regex construite par concatenation) : un motif glob (`scripts/check-*.sh`) couvre tout
#      chemin qu'il apparie, pas seulement une egalite exacte.
#
# Usage:
#   check-gate-touche.sh [--root DIR] [--base-ref REF]
#
# Exit codes (contrat interne, tous enumeres) :
#   0  = DECLARE — au moins un chemin de la surface touche, tous couverts par un trailer conforme
#   1  = au moins un CHEMIN-NON-DECLARE (chemin de surface non couvert). MARQUEUR-MAL-FORME peut
#        accompagner ce meme rc quand un trailer present echoue la verification de forme.
#   2  = NON VERIFIABLE — aucune ref de base resoluble, hors d'un arbre git, ou sortie de
#        `git diff --name-status` imparsable
#   3  = silence non bloquant — RIEN-A-JUGER (aucun chemin de la surface touche) ou PLAGE-VIDE
#        (base egale HEAD, ou zero commit dans la plage)
#   64 = erreur d'usage (argument inconnu, --root/--base-ref sans valeur, --root inexistant)
#
# Options reservees aux fixtures : --base-ref REF surcharge la cascade de resolution — TOUTE
# invocation de production (CI, hook, humain) l'omet et laisse la cascade jouer.
set -uo pipefail

ROOT="."
BASE_REF_OVERRIDE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      if [ "$#" -lt 2 ]; then
        echo "[check-gate-touche] --root necessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --base-ref)
      if [ "$#" -lt 2 ]; then
        echo "[check-gate-touche] --base-ref necessite une valeur" >&2
        exit 64
      fi
      BASE_REF_OVERRIDE="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-gate-touche] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

if [ ! -d "$ROOT" ]; then
  echo "[check-gate-touche] --root introuvable : $ROOT" >&2
  exit 64
fi
ROOT="${ROOT%/}"
[ -n "$ROOT" ] || ROOT="/"

if ! cd "$ROOT" 2>/dev/null; then
  echo "[check-gate-touche] --root inaccessible : $ROOT" >&2
  exit 64
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[check-gate-touche] hors d'un arbre git : $ROOT" >&2
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
  echo "[check-gate-touche] aucune ref resoluble (cascade : --base-ref, ${CASCADE})" >&2
  exit 2
}

# --- Derivation de la base : merge-base, jamais l'adjacence du journal ----------------------------
BASE="$(git merge-base HEAD "$REF_RESOLVED" 2>/dev/null)"
if [ -z "$BASE" ]; then
  echo "[check-gate-touche] merge-base introuvable entre HEAD et ${REF_RESOLVED}" >&2
  exit 2
fi

HEAD_SHA="$(git rev-parse HEAD)"

COMMITS_COUNT="$(git rev-list --count "${BASE}..${HEAD_SHA}" 2>/dev/null)"
COMMITS_COUNT="${COMMITS_COUNT:-0}"

if [ "$COMMITS_COUNT" -eq 0 ]; then
  echo "decouverte: commits=0 chemins_diff=0 chemins_surface=0 marqueurs_conformes=0"
  echo "PLAGE-VIDE: base derivee sans commit dans la plage (base egale HEAD, ou push direct)"
  exit 3
fi

TMPD="$(mktemp -d)"
DIFF_RAW="$TMPD/diff_raw"
SURFACE_TOUCHED="$TMPD/surface_touched"
TRAILERS_OK="$TMPD/trailers_ok"
trap 'rm -rf "$TMPD"' EXIT

if ! git diff --name-status "$BASE" "$HEAD_SHA" > "$DIFF_RAW" 2>/dev/null; then
  echo "[check-gate-touche] sortie de git diff --name-status illisible" >&2
  exit 2
fi

# --- Validation de forme des lignes de diff (statut reconnu) --------------------------------------
if ! awk -F'\t' '
  { if ($1 !~ /^[AMDTU]$/ && $1 !~ /^[RC][0-9]*$/) { exit 1 } }
' "$DIFF_RAW"; then
  echo "[check-gate-touche] sortie de git diff --name-status imparsable" >&2
  exit 2
fi

CHEMINS_DIFF=$(awk 'NF > 0 { c++ } END { print c + 0 }' "$DIFF_RAW")

# --- Comparaison 1 — appartenance a la surface, cinq classes, une seule lecture du diff -----------
awk -F'\t' '
  function classify(p) {
    if (p ~ /^plugin\/conductor\/scripts\/check-[^\/]+\.sh$/) return "gate-conductor"
    if (p ~ /^scripts\/check-[^\/]+\.sh$/) return "gate-scripts"
    if (p ~ /^plugin\/conductor\/scripts\/tests\/test-[^\/]+\.sh$/) return "suite"
    if (p ~ /^scripts\/tests\/test-[^\/]+\.sh$/) return "suite"
    if (p == ".github/workflows/ci.yml") return "ci"
    if (p ~ /^scripts\/hooks\//) return "hooks"
    return ""
  }
  {
    status = $1
    if (status ~ /^[RC]/) { old = $2; new = $3 } else { old = ""; new = $2 }
    if (old != "") { c = classify(old); if (c != "") printf "%s\t%s\t%s\n", status, old, c }
    if (new != "") { c = classify(new); if (c != "") printf "%s\t%s\t%s\n", status, new, c }
  }
' "$DIFF_RAW" > "$SURFACE_TOUCHED"

CHEMINS_SURFACE=$(awk 'NF > 0 { c++ } END { print c + 0 }' "$SURFACE_TOUCHED")

# --- Comparaisons 2 et 3 — recolte des marqueurs Gate-Touche, portee branche, forme --------------
MARQ_LUS=0
MARQ_OK=0
: > "$TRAILERS_OK"

COMMITS_LIST="$(git rev-list "${BASE}..${HEAD_SHA}" 2>/dev/null)"
while IFS= read -r c; do
  [ -z "$c" ] && continue
  msg="$(git log -1 --format=%B "$c" 2>/dev/null)"
  while IFS= read -r line; do
    trimmed="${line#"${line%%[![:space:]]*}"}"
    case "$trimmed" in
      Gate-Touche:*)
        MARQ_LUS=$((MARQ_LUS + 1))
        value="${trimmed#Gate-Touche:}"
        value="${value# }"
        sep=""
        case "$value" in
          *' — '*) sep=' — ' ;;
          *' - '*) sep=' - ' ;;
        esac
        if [ -z "$sep" ]; then
          echo "MARQUEUR-MAL-FORME: ${trimmed}"
          continue
        fi
        motif="${value%%"$sep"*}"
        reason="${value#*"$sep"}"
        if [ -z "$motif" ]; then
          echo "MARQUEUR-MAL-FORME: ${trimmed}"
          continue
        fi
        case "$motif" in
          *,*)
            echo "MARQUEUR-MAL-FORME: ${trimmed} (motif contient une virgule — un trailer = un chemin ou motif, jamais une liste separee par virgule ; \`case\` ne fait pas d'union sur une virgule)"
            continue
            ;;
        esac
        reason_stripped="$(printf '%s' "$reason" | tr -d '[:space:]')"
        # ${#var} compte des OCTETS quand la locale d'execution est byte-oriented (LC_ALL=C) — une
        # raison accentuee (ex. "éàçèùî", 6 caracteres, 12 octets en UTF-8) franchirait alors le
        # seuil de 10 sans jamais avoir 10 caracteres reels : verdict qui depend de la locale du
        # shell appelant plutot que du contenu du trailer (revue F2, 2026-09-18). Fix : compte de
        # CODEPOINTS UTF-8, jamais d'octets, par une methode qui ne depend d'AUCUNE locale installee
        # (contrairement a `LC_ALL=C.UTF-8 wc -m`, non garanti present sur toute image CI) — od
        # dumpe les octets en decimal, awk ne garde que les octets qui ne sont PAS une suite de
        # continuation UTF-8 (10xxxxxx, soit 128-191) : chaque octet ASCII ou tete de sequence
        # multi-octets compte pour un caractere, chaque octet de continuation ne compte pas.
        reason_charcount="$(printf '%s' "$reason_stripped" | od -An -tu1 | tr -s ' \n' '\n' | awk 'NF && ($1 < 128 || $1 >= 192) { n++ } END { print n + 0 }')"
        if [ "${reason_charcount:-0}" -lt 10 ]; then
          echo "MARQUEUR-MAL-FORME: ${trimmed}"
          continue
        fi
        MARQ_OK=$((MARQ_OK + 1))
        printf '%s\t%s\n' "$motif" "$reason" >> "$TRAILERS_OK"
        ;;
    esac
  done <<EOF_MSG
$msg
EOF_MSG
done <<EOF_COMMITS
$COMMITS_LIST
EOF_COMMITS

echo "decouverte: commits=${COMMITS_COUNT} chemins_diff=${CHEMINS_DIFF} chemins_surface=${CHEMINS_SURFACE} marqueurs_conformes=${MARQ_OK}"
echo "marqueurs: lus=${MARQ_LUS} conformes=${MARQ_OK}"

if [ "$CHEMINS_SURFACE" -eq 0 ]; then
  echo "RIEN-A-JUGER: aucun chemin de la surface surveillee n'est touche entre ${BASE} et HEAD"
  exit 3
fi

# --- Comparaison 4 — correspondance chemin <-> motif, case uniquement, jamais eval ----------------
RC=0
while IFS="$(printf '\t')" read -r status path class; do
  [ -z "$path" ] && continue
  covered=0
  if [ -s "$TRAILERS_OK" ]; then
    while IFS="$(printf '\t')" read -r motif reason; do
      [ -z "$motif" ] && continue
      case "$path" in
        ($motif) covered=1; break ;;
      esac
    done < "$TRAILERS_OK"
  fi
  if [ "$covered" -eq 0 ]; then
    echo "CHEMIN-NON-DECLARE: ${path} (statut ${status}, classe ${class})"
    RC=1
  fi
done < "$SURFACE_TOUCHED"

if [ "$RC" -eq 0 ]; then
  echo "DECLARE"
fi

exit "$RC"
