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
#                    UNE SEULE des deux clés (P412-D-07) : le jalon manque, la phase courante est posée, ET le
#                    ROADMAP déclare un jalon => le MOTEUR l'écrit par un `state patch` anodin (voie mesurée sûre,
#                    41.2-CORRECTION-01-SUMMARY.md C1), puis post-conditions et empreinte (jalon posé, corps et
#                    lignes d'origine du frontmatter intacts, reste du planning intact) ; sinon NON VÉRIFIABLE
#                    « état à moitié renseigné » AVANT tout `workstream create` (disque intact) ;
#   4. create        `workstream create <nom> --migrate-name <nom>` (plat, MÊME nom) ou
#                    `workstream create <nom>` (partitionné) ; `already_exists` => REFUSÉ, aucune écriture ;
#   5. nom retenu    le champ `.workstream` rendu par le moteur (normalisé), jamais la saisie, validé par
#                    `vf_ws_name_valid` ;
#   6. séquence      (plat sans état complet) `state get Phase --raw --ws <sujet>` doit égaler la
#                    pré-capture, puis `state milestone-switch --milestone <v> --name <sujet>`, puis
#                    `state patch` du JSON fabriqué par `jq -cn --arg` ; post-condition lue sur le disque
#                    (milestone, current_phase numérique, UNE seule ligne ^Phase:).
#   7. sujet par défaut (P412-D-10, arbitrage Samuel, AskUserQuestion session principale, 2026-10-02,
#                    « Le premier sujet (Recommandé) ») : la migration d'un lab plat fait écrire PAR LE MOTEUR le
#                    pointeur partagé `.planning/active-workstream` = le premier sujet (mesuré : `workstream create`
#                    l'écrit lui-même quand AUCUNE clé de session ne résout ; sinon il écrit sous `os.tmpdir()`,
#                    non composable). L'appel `create` d'un lab plat passe donc sous `env -u <clés de session>` et
#                    stdin fermé. Un sujet AJOUTÉ à un lab déjà partitionné ne change JAMAIS le sujet par défaut :
#                    son `create` est détourné vers un pointeur de session jetable (clé forcée, TMPDIR jetable).
#                    Post-condition : fichier régulier (pas un lien), contenu = nom canonique ; ou, pour un sujet
#                    ajouté, pointeur strictement inchangé.
# Aucun rollback automatique (ADR-031) : si le sujet est créé et l'état incomplet, le message dit « sujet
# créé, état à compléter » et rend NON VÉRIFIABLE. La séquence d'état est destructive sur un lab démarré
# (mesuré, 41.2-MESURE-VERBE-ETAT.md) : d'où sa condition « STATE migré sans milestone NI current_phase ».
#
# Usage:
#   split-planning.sh --name <nom> [--path <dir>] [--milestone <v>]
#   split-planning.sh --lab-state [--path <dir>]
#   split-planning.sh --help
#
# --lab-state (P412-D-08, lecture seule) : rend « neuf » (ni jalon ni phase courante renseignés : produit brut de
# l'initialisation) ou « demarre » (au moins l'un des deux) sur stdout, rc 0 ; état illisible => rc 2. Aucune
# écriture, aucun appel moteur, aucun nom requis : c'est le MÊME critère que le geste (fm_get ci-dessous), le skill
# l'appelle au lieu de dupliquer le critère. Tolère fins de ligne CRLF et BOM UTF-8.
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

ROOT="."; NAME=""; MILESTONE="v1.0"; MILESTONE_SET=0; HAVE_NAME=0; LABSTATE=0
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
    --lab-state) LABSTATE=1; shift ;;
    -h|--help)   grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *)           usage_err "argument inconnu : $1" ;;
  esac
done

fm_get() { # <STATE.md> <clé> : valeur de la clé dans le frontmatter (lecture seule ; BOM UTF-8 et CR final tolérés)
  LC_ALL=C awk -v k="$2" 'NR==1 && index($0,"\357\273\277")==1{$0=substr($0,4)} {sub(/\r$/,"")} /^---[[:space:]]*$/{n++; if(n==1) next; if(n==2) exit} n==1 && $0 ~ "^"k":"{sub("^"k":[[:space:]]*",""); gsub(/^["'\'']|["'\'']$/,""); print; exit}' "$1"
}

if [ "$LABSTATE" -eq 1 ]; then
  [ -d "$ROOT" ] && [ -r "$ROOT/.planning/STATE.md" ] || { echo "[split-planning] NON VÉRIFIABLE : l'état d'avancement du planning est illisible — aucune écriture" >&2; exit 2; }
  if [ -n "$(fm_get "$ROOT/.planning/STATE.md" milestone)" ] || [ -n "$(fm_get "$ROOT/.planning/STATE.md" current_phase)" ]; then echo demarre; else echo neuf; fi
  exit 0
fi

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

# PTR_ENV : réglages d'environnement SUPPLÉMENTAIRES du seul appel `create` (vide partout ailleurs), cf. étape 4.
PTR_ENV=()
# Clés de session que le moteur consulte pour choisir son pointeur (active-workstream-store, mesuré 2026-10-02) :
# aucune ne résout => le pointeur écrit est le pointeur PARTAGÉ du dépôt.
PTR_NOKEY=(-u GSD_SESSION_KEY -u CODEX_THREAD_ID -u CLAUDE_SESSION_ID -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_SSE_PORT
  -u OPENCODE_SESSION_ID -u GEMINI_SESSION_ID -u CURSOR_SESSION_ID -u WINDSURF_SESSION_ID -u TERM_SESSION_ID
  -u WT_SESSION -u TMUX_PANE -u ZELLIJ_SESSION_NAME -u TTY -u SSH_TTY)
engine() { env -u GSD_WORKSTREAM ${PTR_ENV[@]+"${PTR_ENV[@]}"} "${RUN[@]}" --cwd "$ROOT" "$@"; }
PTR_FILE="$PLANNING/active-workstream"
ptr_snapshot() { # empreinte du pointeur partagé : « absent » ou cksum du contenu (lien ou non régulier => « atypique »)
  if [ -L "$PTR_FILE" ]; then echo atypique
  elif [ -f "$PTR_FILE" ]; then cksum < "$PTR_FILE"
  elif [ -e "$PTR_FILE" ]; then echo atypique
  else echo absent; fi
}

# --- 3. Lab plat : séquence d'état nécessaire ? ------------------------------------------------------------
# Trois états du STATE racine, jamais deux manières de le lire : complet (les deux clés), brut (aucune des
# deux : produit de gsd-new-project), partiel (une seule : lab démarré, séquence destructive => refus).
NEED_SEQ=0; PRECAP=""; REPAIRED=0
roadmap_milestone() { # jalon courant du ROADMAP du lab (lecture seule, mesurée) ; vide si rien de lisible ou forme refusée
  local ms; ms="$(engine init progress 2>/dev/null | jq -r '.milestone_version // empty' 2>/dev/null)"
  if [ -n "$ms" ] && [ "${#ms}" -le 32 ]; then case "$ms" in *[!$ALNUM._-]*) : ;; *) printf '%s' "$ms" ;; esac; fi
}
tree_sum() { # empreinte du planning HORS STATE.md racine (contenu), pour prouver que seul l'état a bougé
  find "$PLANNING" -type f -not -path "$PLANNING/STATE.md" -exec cksum {} + 2>/dev/null | LC_ALL=C sort
}
state_split() { # <STATE.md> <fm|body> : frontmatter (sans les barres, guillemets de valeur retirés : le moteur
  # réécrit '1.0' en "1.0", même valeur) ou corps
  LC_ALL=C awk -v w="$2" 'NR==1 && index($0,"\357\273\277")==1{$0=substr($0,4)} /^---[[:space:]]*$/{n++; next} (w=="fm" && n==1) || (w=="body" && n>=2){print}' "$1" \
    | if [ "$2" = "fm" ]; then sed -e "s/^\([^:]*:\)[[:space:]]*[\"']\(.*\)[\"']\$/\1 \2/"; else cat; fi
}
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
      _ms="$(roadmap_milestone)"; [ -z "$_ms" ] || MILESTONE="$_ms"   # rien de lisible => v1.0
    fi
  elif [ -z "$HAS_M" ]; then
    # Lab démarré (la phase courante est posée, le jalon manque) : P412-D-07. Le jalon est DÉRIVÉ du plan de route
    # par le moteur ; un `state patch` anodin le fait écrire, sans autre effet de bord (mesuré, correction 01 C1).
    # Sans jalon déclaré au plan de route, aucune voie sûre : refus, disque intact.
    _ms="$(roadmap_milestone)"
    [ -n "$_ms" ] || nv "l'état d'avancement du planning est à moitié renseigné (le jalon manque) et le plan de route ne déclare aucun jalon : je ne sépare pas ce planning, pour ne pas remettre l'avancement à zéro — aucune écriture. Déclarez d'abord un jalon dans le plan de route (commande /gsd-new-milestone), puis relancez la séparation"
    if [ "$MILESTONE_SET" -eq 1 ] && [ "$MILESTONE" != "$_ms" ]; then
      nv "le jalon demandé ($MILESTONE) diffère de celui du plan de route ($_ms) : l'état d'avancement du planning, à moitié renseigné, prend celui du plan de route — aucune écriture"
    fi
    _fm0="$(state_split "$ROOT_STATE" fm | LC_ALL=C sort)"; _body0="$(state_split "$ROOT_STATE" body | cksum)"; _tree0="$(tree_sum)"
    _la="$(engine state get "Last activity" --raw 2>/dev/null)" || _la=""
    # P412-D-09 : le moteur n'écrit que la ligne « Last activity » : elle doit exister, être renseignée et se relire à
    # l'identique (sinon le moteur lirait une autre ligne ou une valeur rognée, et l'empreinte ne refuserait qu'APRÈS l'écriture)
    _la_raw="$(grep -m1 '^Last activity:' "$ROOT_STATE" 2>/dev/null | sed 's/^Last activity:[[:space:]]*//')"
    { [ -n "$_la_raw" ] && [ "$_la_raw" = "$_la" ]; } || nv "la ligne « Last activity » de l'état d'avancement est absente, vide ou ne se relit pas à l'identique (espaces en fin de ligne, par exemple) : je ne sépare pas ce planning — aucune écriture. Corrigez cette ligne, puis relancez la séparation"
    la_json="$(jq -cn --arg v "$_la" '{"Last activity":$v}')"
    engine state patch "$la_json" >/dev/null 2>&1 || nv "le moteur n'a pas pu compléter l'état d'avancement du planning — état à vérifier, aucune séparation faite"
    # Post-conditions et empreinte : le jalon est posé, le corps est identique octet pour octet, aucune ligne du
    # frontmatter d'origine n'a changé ou disparu, rien d'autre dans le planning n'a bougé.
    _fm1="$(state_split "$ROOT_STATE" fm | LC_ALL=C sort)"
    [ -n "$(fm_get "$ROOT_STATE" milestone)" ] || nv "le moteur n'a pas posé le jalon dans l'état d'avancement — état à vérifier, aucune séparation faite"
    [ "$_body0" = "$(state_split "$ROOT_STATE" body | cksum)" ] || nv "le moteur a modifié le corps de l'état d'avancement — état à vérifier, aucune séparation faite"
    [ -z "$(LC_ALL=C comm -23 <(cat <<<"$_fm0") <(cat <<<"$_fm1"))" ] || nv "le moteur a modifié l'avancement déjà renseigné — état à vérifier, aucune séparation faite"
    [ "$_tree0" = "$(tree_sum)" ] || nv "le moteur a modifié d'autres fichiers du planning — état à vérifier, aucune séparation faite"
    REPAIRED=1
  else
    nv "l'état d'avancement du planning est à moitié renseigné (la phase courante manque) : je ne sépare pas ce planning, pour ne pas remettre l'avancement à zéro — aucune écriture ; à trancher avec l'équipe"
  fi
fi

# --- 4. Création par le moteur ------------------------------------------------------------------------------
PTR_BEFORE="$(ptr_snapshot)"; SCRATCH=""
if [ "$MODE" = "plat" ]; then
  # P412-D-10 : aucune clé de session => le moteur écrit lui-même le pointeur PARTAGÉ = le premier sujet.
  PTR_ENV=("${PTR_NOKEY[@]}")
  CREATED="$(engine workstream create "$NAME" --migrate-name "$NAME" 2>/dev/null </dev/null)"; c_rc=$?
  PTR_ENV=()
else
  # Sujet ajouté : le sujet par défaut ne bouge pas. Le moteur écrit son pointeur de SESSION (clé forcée) sous un
  # TMPDIR jetable, jamais le pointeur partagé.
  SCRATCH="$(mktemp -d 2>/dev/null)" || nv "dossier temporaire indisponible — aucune écriture"
  PTR_ENV=("GSD_SESSION_KEY=vf-split-$$" "TMPDIR=$SCRATCH")
  CREATED="$(engine workstream create "$NAME" 2>/dev/null </dev/null)"; c_rc=$?
  PTR_ENV=()
  rm -rf "$SCRATCH"
fi
if [ -n "$CREATED" ] && printf '%s' "$CREATED" | jq -e '.error == "already_exists"' >/dev/null 2>&1; then
  echo "[split-planning] REFUSÉ : le sujet existe déjà (already_exists) — aucune écriture." >&2; exit 1
fi
[ "$c_rc" -eq 0 ] || nv "création du sujet en échec (rc=$c_rc) — état du lab à vérifier"
[ -n "$CREATED" ] || nv "création du sujet : le moteur n'a rien répondu — état du lab à vérifier"
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
  STATE_OUT="deja-complet"; [ "$REPAIRED" -eq 1 ] && STATE_OUT="complete"
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

# --- 7. Sujet par défaut (P412-D-10) ------------------------------------------------------------------------------
if [ "$MODE" = "plat" ]; then
  { [ -f "$PTR_FILE" ] && [ ! -L "$PTR_FILE" ] && [ "$(cat "$PTR_FILE" 2>/dev/null)" = "$SUBJECT" ]; } \
    || nv "le sujet par défaut n'a pas été posé par le moteur (fichier absent, lien, ou autre contenu que « $SUBJECT ») — sujet créé, sujet par défaut à poser"
else
  [ "$(ptr_snapshot)" = "$PTR_BEFORE" ] || nv "le sujet par défaut a changé pendant l'ajout du sujet — sujet créé, sujet par défaut à vérifier"
fi

# --- 8. Sortie -------------------------------------------------------------------------------------------------------
jq -cn --arg mode "$MODE" --arg subject "$SUBJECT" --arg state "$STATE_OUT" '{mode:$mode,subject:$subject,state:$state}'
exit 0
