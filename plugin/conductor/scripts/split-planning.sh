#!/usr/bin/env bash
# split-planning.sh — Le geste de partition : créer un sujet PAR LE MOTEUR et le rendre conforme PAR LE
# MOTEUR, après avoir vérifié par machine la précondition d'ADR-069. (Phase 41.2, WSCH-02 / WSCH-03)
#
# Le moteur est le SEUL écrivain (P412-D-01, arbitrage Samuel, AskUserQuestion session principale,
# 2026-10-01) : ce script n'écrit lui-même aucun fichier de planning, ne commite rien (P412-D-03 : le
# skill propose le commit) et ne réimplémente rien du moteur. Il encadre :
#   1. précondition  check-planning-not-inflight.sh --path <racine>, AVANT tout appel d'écriture
#                    (rc 1 REFUSÉ et rc 2 NON VÉRIFIABLE repris tels quels ; stdout plat|partitionne
#                    choisit la forme de `workstream create`) ;
#   2. moteur        cascade GSD_TOOLS -> `gsd-tools` sur le PATH -> ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/
#                    gsd-core/bin/gsd-tools.cjs ; AUCUN candidat relatif au cwd ni au dépôt. Chaque appel
#                    moteur passe par la fonction unique `engine`, sous `env -u GSD_WORKSTREAM` ;
#   3. lab plat      lecture seule du frontmatter du STATE racine : `milestone` ET `current_phase` présents
#                    => aucune séquence (état « deja-complet ») ; NI l'un NI l'autre (produit brut de
#                    gsd-new-project) => pré-capture `state get Phase --raw` (doit commencer par un chiffre,
#                    sinon NON VÉRIFIABLE, aucune écriture) et jalon lu du ROADMAP par `init progress` ;
#                    UNE SEULE des deux clés => NON VÉRIFIABLE « état à moitié renseigné », AVANT tout
#                    `workstream create` (disque intact) : la séquence, destructive sur un lab démarré,
#                    n'est jamais jouée là, et aucune voie moteur ne pose `milestone` seul sans effet de
#                    bord (41.2-CORRECTION-01-SUMMARY.md, C1) ;
#   4. create        `workstream create <nom> --migrate-name <nom>` (plat, MÊME nom) ou
#                    `workstream create <nom>` (partitionné) ; `already_exists` => REFUSÉ, aucune écriture ;
#   5. nom retenu    le champ `.workstream` rendu par le moteur (normalisé), jamais la saisie, validé par
#                    `vf_ws_name_valid` ;
#   6. séquence      (plat sans état complet) `state get Phase --raw --ws <sujet>` doit égaler la
#                    pré-capture, puis `state milestone-switch --milestone <v> --name <sujet>`, puis
#                    `state patch` du JSON fabriqué par `jq -cn --arg` ; post-condition lue sur le disque
#                    (milestone, current_phase numérique, UNE seule ligne ^Phase:).
# Aucun rollback automatique (ADR-031) : si le sujet est créé et l'état incomplet, le message dit « sujet
# créé, état à compléter » et rend NON VÉRIFIABLE. La séquence d'état est destructive sur un lab démarré
# (mesuré, 41.2-MESURE-VERBE-ETAT.md) : d'où sa condition « STATE migré sans milestone NI current_phase ».
#
# Usage:
#   split-planning.sh --name <nom> [--path <dir>] [--milestone <v>]
#   split-planning.sh --help
#
# Defaults: --path .   --milestone = le jalon courant du ROADMAP du lab (moteur : `init progress`,
# milestone_version), à défaut de jalon lisible v1.0 (le gabarit de roadmap du moteur nomme le greenfield
# v1.0). Un --milestone explicite l'emporte toujours.
# Validation : nom = premier caractère [A-Za-z0-9] puis [A-Za-z0-9 ._-], 64 au plus, sans « .. » ;
# jalon = [A-Za-z0-9._-], 32 au plus. Tout écart ou argument inconnu => 64. Les classes sont listées
# caractère par caractère : un intervalle [A-Za-z] dépend de la locale (bash 3.2 y laisse passer é, ñ).
#
# Sortie : une seule ligne JSON sur stdout pour le code 0 : {"mode":"plat|partitionne","subject":"<nom>",
# "state":"complete|deja-complet|non-initialise"} ; diagnostics sur stderr (préfixe [split-planning]).
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0  = FAIT — sujet créé (et état complété si lab plat à état vierge).
#   1  = REFUSÉ — phase en vol (ADR-069), ou sujet déjà existant ; aucune écriture.
#   2  = NON VÉRIFIABLE — outil/moteur absent, lab illisible, Phase: non numérique, sortie moteur
#        inattendue ; « aucune écriture » ou « sujet créé, état à compléter » est dit dans le message.
#   64 = erreur d'usage (option inconnue, valeur manquante, nom ou jalon invalide).
set -uo pipefail

ROOT="."; NAME=""; MILESTONE="v1.0"; MILESTONE_SET=0; HAVE_NAME=0
ALNUM="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

usage_err() { echo "[split-planning] $*" >&2; exit 64; }
nv() { echo "[split-planning] NON VÉRIFIABLE : $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)      [ "$#" -ge 2 ] || usage_err "--path nécessite une valeur"; ROOT="$2"; shift 2 ;;
    --path=*)    ROOT="${1#--path=}"; shift ;;
    --name)      [ "$#" -ge 2 ] || usage_err "--name nécessite une valeur"; NAME="$2"; HAVE_NAME=1; shift 2 ;;
    --name=*)    NAME="${1#--name=}"; HAVE_NAME=1; shift ;;
    --milestone) [ "$#" -ge 2 ] || usage_err "--milestone nécessite une valeur"; MILESTONE="$2"; MILESTONE_SET=1; shift 2 ;;
    --milestone=*) MILESTONE="${1#--milestone=}"; MILESTONE_SET=1; shift ;;
    -h|--help)   grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *)           usage_err "argument inconnu : $1" ;;
  esac
done

[ "$HAVE_NAME" -eq 1 ] || usage_err "--name est obligatoire"
[ -n "$ROOT" ] || usage_err "--path nécessite une valeur"
[ -n "$NAME" ] || usage_err "--name ne peut pas être vide"
[ "${#NAME}" -le 64 ] || usage_err "--name : 64 caractères au plus"
case "$NAME" in
  *..*) usage_err "--name ne doit pas contenir « .. »" ;;
  [$ALNUM]*) ;;
  *) usage_err "--name doit commencer par une lettre ASCII ou un chiffre" ;;
esac
case "$NAME" in
  *[!$ALNUM\ ._-]*) usage_err "--name : caractères autorisés : lettres ASCII, chiffres, espace, point, tiret, souligné" ;;
esac
[ -n "$MILESTONE" ] && [ "${#MILESTONE}" -le 32 ] || usage_err "--milestone : 1 à 32 caractères"
case "$MILESTONE" in
  *[!$ALNUM._-]*) usage_err "--milestone : caractères autorisés : lettres ASCII, chiffres, point, tiret, souligné" ;;
esac

[ -d "$ROOT" ] || nv "--path introuvable : $ROOT — aucune écriture"
ROOT="$(cd "$ROOT" && pwd)"
PLANNING="$ROOT/.planning"
HERE="$(dirname "$0")"

# --- 1. Précondition ADR-069, AVANT tout écrit -----------------------------------------------------
MODE="$("${BASH:-bash}" "$HERE/check-planning-not-inflight.sh" --path "$ROOT")"; pre_rc=$?
case "$pre_rc" in
  0) : ;;
  1) echo "[split-planning] REFUSÉ (ADR-069) : une phase est en vol — aucune écriture." >&2; exit 1 ;;
  2) nv "la précondition d'ADR-069 n'a pu être lue — aucune écriture" ;;
  *) nv "précondition en erreur inattendue (rc=$pre_rc) — aucune écriture" ;;
esac
case "$MODE" in
  plat|partitionne) : ;;
  *) nv "précondition : sortie inattendue [$MODE] — aucune écriture" ;;
esac

# --- 2. Outils et moteur (aucun candidat relatif au cwd ni au dépôt) -------------------------------------
command -v jq >/dev/null 2>&1 || nv "jq introuvable — aucune écriture"
_POLICY=""
for _cand in "$HERE/workstream-policy.sh" "$HERE/../../planning-core/scripts/workstream-policy.sh"; do
  [ -f "$_cand" ] && { _POLICY="$_cand"; break; }
done
[ -n "$_POLICY" ] || nv "script des règles des sujets introuvable — aucune écriture"
# shellcheck source=/dev/null
. "$_POLICY"

GT=""
if [ -n "${GSD_TOOLS:-}" ] && [ -f "$GSD_TOOLS" ]; then GT="$GSD_TOOLS"
elif command -v gsd-tools >/dev/null 2>&1; then GT="$(command -v gsd-tools)"
elif [ -f "${CLAUDE_CONFIG_DIR:-${HOME:-/nonexistent}/.claude}/gsd-core/bin/gsd-tools.cjs" ]; then
  GT="${CLAUDE_CONFIG_DIR:-${HOME:-/nonexistent}/.claude}/gsd-core/bin/gsd-tools.cjs"
fi
[ -n "$GT" ] || nv "moteur gsd-tools introuvable (GSD_TOOLS, PATH, ~/.claude/gsd-core) — aucune écriture"
case "$GT" in
  *.cjs) command -v node >/dev/null 2>&1 || nv "node introuvable (le moteur est un .cjs) — aucune écriture"; RUN=(node "$GT") ;;
  *) RUN=("$GT") ;;
esac

engine() { env -u GSD_WORKSTREAM "${RUN[@]}" --cwd "$ROOT" "$@"; }

fm_get() { # <STATE.md> <clé> : valeur de la clé dans le frontmatter (lecture seule)
  awk -v k="$2" '/^---[[:space:]]*$/{n++; if(n==1) next; if(n==2) exit} n==1 && $0 ~ "^"k":"{sub("^"k":[[:space:]]*",""); gsub(/^["'\'']|["'\'']$/,""); print; exit}' "$1"
}

# --- 3. Lab plat : séquence d'état nécessaire ? ------------------------------------------------------------
# Trois états du STATE racine, jamais deux manières de le lire : complet (les deux clés), brut (aucune des
# deux : produit de gsd-new-project), partiel (une seule : lab démarré, séquence destructive => refus).
NEED_SEQ=0; PRECAP=""
if [ "$MODE" = "plat" ]; then
  ROOT_STATE="$PLANNING/STATE.md"
  HAS_M="$(fm_get "$ROOT_STATE" milestone)"; HAS_C="$(fm_get "$ROOT_STATE" current_phase)"
  if [ -n "$HAS_M" ] && [ -n "$HAS_C" ]; then
    NEED_SEQ=0
  elif [ -z "$HAS_M" ] && [ -z "$HAS_C" ]; then
    NEED_SEQ=1
    PRECAP="$(engine state get Phase --raw 2>/dev/null)" || nv "lecture de la ligne Phase: par le moteur en échec — aucune écriture"
    case "$PRECAP" in
      [0-9]*) : ;;
      *) nv "ligne Phase: non numérique [$PRECAP] — aucune écriture" ;;
    esac
    if [ "$MILESTONE_SET" -eq 0 ]; then
      # Jalon courant du ROADMAP du lab (lecture seule, mesurée) ; rien de lisible ou forme refusée => v1.0.
      _ms="$(engine init progress 2>/dev/null | jq -r '.milestone_version // empty' 2>/dev/null)"
      if [ -n "$_ms" ] && [ "${#_ms}" -le 32 ]; then
        case "$_ms" in *[!$ALNUM._-]*) : ;; *) MILESTONE="$_ms" ;; esac
      fi
    fi
  else
    nv "l'état d'avancement du planning est à moitié renseigné (le jalon ou la phase courante manque) : je ne sépare pas ce planning, pour ne pas remettre l'avancement à zéro — aucune écriture ; à trancher avec l'équipe"
  fi
fi

# --- 4. Création par le moteur ------------------------------------------------------------------------------
if [ "$MODE" = "plat" ]; then
  CREATED="$(engine workstream create "$NAME" --migrate-name "$NAME" 2>/dev/null)"; c_rc=$?
else
  CREATED="$(engine workstream create "$NAME" 2>/dev/null)"; c_rc=$?
fi
if printf '%s' "$CREATED" | jq -e '.error == "already_exists"' >/dev/null 2>&1; then
  echo "[split-planning] REFUSÉ : le sujet existe déjà (already_exists) — aucune écriture." >&2; exit 1
fi
[ "$c_rc" -eq 0 ] || nv "création du sujet en échec (rc=$c_rc) — état du lab à vérifier"
printf '%s' "$CREATED" | jq -e '.created == true and (.workstream | type == "string")' >/dev/null 2>&1 \
  || nv "création du sujet : sortie inattendue — état du lab à vérifier"

# --- 5. Nom retenu = nom canonique du moteur --------------------------------------------------------------------
SUBJECT="$(printf '%s' "$CREATED" | jq -r '.workstream')"
vf_ws_name_valid "$SUBJECT" || nv "nom canonique rendu par le moteur invalide — sujet créé, état à compléter"
if [ "$MODE" = "plat" ]; then
  printf '%s' "$CREATED" | jq -e --arg s "$SUBJECT" '.migration.migrated == true and .migration.workstream == $s' >/dev/null 2>&1 \
    || nv "migration non confirmée par le moteur — sujet créé, état à compléter"
else
  [ -d "$PLANNING/workstreams/$SUBJECT" ] || nv "dossier du sujet absent après create — sujet créé, état à compléter"
fi

# --- 6. Séquence d'état (lab plat à état vierge seulement) ---------------------------------------------------------
STATE_OUT="non-initialise"
if [ "$MODE" = "plat" ] && [ "$NEED_SEQ" -eq 0 ]; then
  STATE_OUT="deja-complet"
elif [ "$MODE" = "plat" ]; then
  SUBJ_PHASE="$(engine state get Phase --raw --ws "$SUBJECT" 2>/dev/null)" \
    || nv "relecture de Phase: par le moteur en échec — sujet créé, état à compléter"
  [ "$SUBJ_PHASE" = "$PRECAP" ] || nv "Phase: du sujet [$SUBJ_PHASE] différente de la pré-capture [$PRECAP] — sujet créé, état à compléter"
  engine state milestone-switch --milestone "$MILESTONE" --name "$SUBJECT" --ws "$SUBJECT" >/dev/null 2>&1 \
    || nv "state milestone-switch en échec — sujet créé, état à compléter"
  patch_json="$(jq -cn --arg v "$PRECAP" '{Phase:$v}')"
  engine state patch "$patch_json" --ws "$SUBJECT" >/dev/null 2>&1 \
    || nv "state patch en échec — sujet créé, état à compléter"
  SUBJ_STATE="$PLANNING/workstreams/$SUBJECT/STATE.md"
  [ -f "$SUBJ_STATE" ] || nv "STATE du sujet absent après la séquence — sujet créé, état à compléter"
  _cp="$(fm_get "$SUBJ_STATE" current_phase)"
  case "$_cp" in ''|*[!0-9]*) nv "current_phase absent ou non numérique après la séquence — sujet créé, état à compléter" ;; esac
  [ -n "$(fm_get "$SUBJ_STATE" milestone)" ] || nv "milestone absent après la séquence — sujet créé, état à compléter"
  [ "$(grep -c '^Phase:' "$SUBJ_STATE")" = "1" ] || nv "ligne ^Phase: absente ou en double après la séquence — sujet créé, état à compléter"
  STATE_OUT="complete"
fi

# --- 7. Sortie -------------------------------------------------------------------------------------------------------
jq -cn --arg mode "$MODE" --arg subject "$SUBJECT" --arg state "$STATE_OUT" '{mode:$mode,subject:$subject,state:$state}'
exit 0
