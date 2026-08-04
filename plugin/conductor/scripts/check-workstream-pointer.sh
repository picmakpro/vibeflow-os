#!/usr/bin/env bash
# check-workstream-pointer.sh — Le workstream actif d'un dépôt partitionné est-il résolu par un
# canal COMPOSABLE avec ADR-064 ? (Phase 24-05, exigence GSDA-16)
#
# Rôle : rendre bruyante la défaillance que le moteur traite en silence — une session qui ouvre sur
# un `.planning/` partitionné sans workstream résolu. Mesuré le 2026-08-04 sur
# `active-workstream-store.cjs` : dès qu'une clé de session résout (sous Claude Code,
# `CLAUDE_CODE_SSE_PORT` est présent), le pointeur de workstream ne vit PAS dans le dépôt mais dans
# `os.tmpdir()/gsd-workstream-sessions/<condensat sur 16 du chemin absolu réel du .planning>/<clé>`.
# Ce pointeur est effacé au redémarrage, indexé sur le chemin absolu, donc distinct par worktree et
# jamais hérité : il ne se compose pas avec « un écrivain = un worktree » (ADR-064). Pire,
# `getActiveWorkstream` AUTO-NETTOIE en silence — nom invalide ou dossier inexistant, il efface le
# pointeur et rend « aucun workstream », sans un mot.
#
# Ce gate ne consulte donc JAMAIS le pointeur de session : il ne constate que les deux canaux
# composables (`GSD_WORKSTREAM`, canal de premier rang de `resolveActiveWorkstream`, puis le
# pointeur partagé in-repo `.planning/active-workstream`), et il échoue bruyamment quand aucun des
# deux ne résout sur un dépôt partitionné. Il ne corrige rien, ne bloque rien : il CONSTATE et
# prescrit le remède (ADR-031).
#
# LECTURE SEULE, sans exception : ce script ne crée, ne modifie et n'efface aucun fichier — surtout
# pas le pointeur, dont l'effacement silencieux est précisément le comportement qu'il dénonce.
#
# États mutuellement exclusifs, évalués dans cet ordre, le premier qui matche gagne :
#
#   0. `<root>/.planning/workstreams/` n'existe pas → dépôt NON PARTITIONNÉ, rien à vérifier.
#      Exit 3, stdout strictement vide. C'est le cas nominal de tous les labs à ce jour.
#   1. `GSD_WORKSTREAM` non vide, nom valide, `<root>/.planning/workstreams/<nom>/` existe →
#      exit 0, canal `env`.
#   2. Pas de `GSD_WORKSTREAM`, pointeur partagé `<root>/.planning/active-workstream` lisible SANS
#      RISQUE (fichier régulier, PAS un lien symbolique, borné en octets), son contenu ENTIER rogné
#      de ses bords est un nom valide, le dossier correspondant existe → exit 0, canal
#      `store-partagé`. Le contenu entier, et non la 1re ligne : le moteur rogne le fichier entier,
#      « dev\nautre » lui est donc INVALIDE — le lire ligne à ligne le rendait « dev ».
#   3. Un nom est résolu par l'un des deux canaux mais `<root>/.planning/workstreams/<nom>/`
#      n'existe pas → exit 1. C'est l'auto-nettoyage silencieux du moteur rendu audible.
#   4. Dépôt partitionné, aucun des deux canaux composables ne résout → exit 1, avec le fait
#      (le pointeur de session, non composable) et le remède (`export GSD_WORKSTREAM=<nom>`).
#
# Usage:
#   check-workstream-pointer.sh [--path <dir>] [--hook]
#   check-workstream-pointer.sh --help
#
# Defaults: --path .   (le `.planning/` inspecté est `<--path>/.planning`)
#
# `--hook` ne change QUE le rendu (une ligne de signal sur stdout pour les seuls états 3 et 4,
# silence total sinon — stdout ET stderr). Il ne change AUCUN code de sortie : parité stricte avec
# les autres gates de ce dépôt.
#
# Env:
#   GSD_WORKSTREAM              — canal de premier rang du moteur ; vide ou absent = non résolu.
#   VF_WORKSTREAM_PLANNING_DIR  — surcharge du répertoire `.planning` inspecté (testabilité).
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0  = conforme — un workstream est résolu par un canal composable, son dossier existe.
#   1  = échec constaté — dépôt partitionné sans workstream composable résolu (état 4), ou nom
#        résolu dont le dossier n'existe pas (état 3).
#   2  = NON VÉRIFIABLE — hors dépôt git, `.planning/` illisible, `workstreams/` illisible ou non
#        répertoire, pointeur partagé non lisible SANS RISQUE (lien symbolique refusé, non
#        régulier, au-delà de la borne d'octets), ou nom hors de la politique du moteur.
#        Jamais un 0 de complaisance : « je n'ai pas pu regarder » ne vaut pas « conforme ».
#   3  = SILENCE — dépôt non partitionné, vérifié : il n'y a rien à dire.
#   64 = erreur d'usage (argument inconnu, option sans valeur).
set -uo pipefail

ROOT="."
HOOK=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { echo "[check-workstream-pointer] --path nécessite une valeur" >&2; exit 64; }
      ROOT="$2"; shift 2 ;;
    --path=*)
      ROOT="${1#--path=}"
      [ -n "$ROOT" ] || { echo "[check-workstream-pointer] --path nécessite une valeur" >&2; exit 64; }
      shift ;;
    --hook) HOOK=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-workstream-pointer] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Diagnostic humain : stderr, et JAMAIS en mode --hook (le coût de la garde doit être nul là où il
# n'y a rien à garder — un lab non partitionné n'imprime pas une ligne).
diag() { [ "$HOOK" -eq 1 ] && return 0; echo "[check-workstream-pointer] $*" >&2; }

# Signal actionnable : une ligne sur stdout en mode --hook, un diagnostic stderr sinon.
signal() {
  if [ "$HOOK" -eq 1 ]; then echo "[workstream-pointer] $*"
  else echo "[check-workstream-pointer] $*" >&2; fi
}

non_verifiable() {
  diag "NON VÉRIFIABLE, rien n'a pu être constaté : $1"
  exit 2
}

export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }

[ -d "$ROOT" ] || non_verifiable "--path introuvable : $ROOT"
git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || non_verifiable "$ROOT est hors d'un dépôt git"

PLANNING="${VF_WORKSTREAM_PLANNING_DIR:-$ROOT/.planning}"
if [ -e "$PLANNING" ]; then
  { [ -d "$PLANNING" ] && [ -r "$PLANNING" ] && [ -x "$PLANNING" ]; } \
    || non_verifiable "$PLANNING existe mais n'est pas un répertoire lisible"
fi

WS_ROOT="$PLANNING/workstreams"
POINTER="$PLANNING/active-workstream"

# --- État 0 : dépôt non partitionné ---------------------------------------------------------------
if [ ! -e "$WS_ROOT" ]; then
  diag "SILENCE — dépôt non partitionné ($WS_ROOT absent) : rien à vérifier."
  exit 3
fi
{ [ -d "$WS_ROOT" ] && [ -r "$WS_ROOT" ] && [ -x "$WS_ROOT" ]; } \
  || non_verifiable "$WS_ROOT existe mais n'est pas un répertoire lisible"

# Politique de nom : fichier SOURCÉ partagé par les quatre gates (planning-core). La copie locale
# qui vivait ici n'avait repris QUE la classe de caractères du moteur, en abandonnant
# `hasInvalidPathSegment` et l'ancre alphanumérique initiale : `.` et `..` sont entièrement dans la
# classe, ce gate rendait donc « exit 0 conforme » sur `..` là où le moteur rend `false` — et
# `WS_DIR="$WS_ROOT/.."` satisfait trivialement `[ -d ]`. L'en-tête ci-dessus revendiquait
# T-24-05-01 (« un nom hors classe ne traverse jamais vers un chemin ») : mitigation annoncée, non
# tenue. Elle l'est maintenant par la politique amont intégrale.
WS_POLICY=""
for _cand in "$(dirname "$0")/workstream-policy.sh" \
             "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
  [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
done
[ -n "$WS_POLICY" ] \
  || non_verifiable "workstream-policy.sh introuvable — politique de workstream non chargeable"
# shellcheck source=/dev/null
. "$WS_POLICY"

# La résolution partagée couvre les deux canaux composables dans l'ordre du moteur
# (GSD_WORKSTREAM, puis pointeur partagé) et refuse un pointeur qui ne peut pas être lu SANS
# RISQUE — lien symbolique en tête. Motif (rejoué sur dépôt piégé) : un `.planning/active-workstream`
# versionné en mode 120000 vers `../../victime/.env` faisait imprimer la 1re ligne du fichier cible
# VERBATIM sur stdout de ce hook, donc dans le contexte de session, sans aucune action de la victime
# au-delà de l'ouverture de session. Le motif de la Phase 23 (`slurp` sans `O_NOFOLLOW`), mais
# auto-déclenché et sans borne de longueur.
vf_ws_resolve "$PLANNING"; WS_RC=$?
if [ "$WS_RC" -eq 2 ]; then
  # Énumération FERMÉE de raisons — la valeur brute n'est jamais réimprimée.
  case "$VF_WS_REASON" in
    pointeur-lien-symbolique) non_verifiable "$POINTER est un lien symbolique — refus de le suivre (le contenu de la cible traverserait vers le contexte de session) ; valeur non lue, non réimprimée" ;;
    pointeur-trop-long)       non_verifiable "$POINTER dépasse $VF_WS_POINTER_MAX_BYTES octets — refus de le lire ; valeur non lue, non réimprimée" ;;
    pointeur-illisible)       non_verifiable "$POINTER existe mais n'est pas un fichier régulier lisible" ;;
    # Distincte de « hors politique » : la valeur n'est pas rejetée pour sa FORME mais pour sa
    # TAILLE. La laisser tomber dans le fourre-tout ci-dessous ferait dire « 1er caractère
    # alphanumérique… » d'une valeur parfaitement bien formée mais démesurée — un diagnostic faux,
    # et impossible à corriger en suivant son propre conseil.
    valeur-trop-longue)       non_verifiable "le canal $VF_WS_SOURCE porte une valeur de plus de $VF_WS_VALUE_MAX_BYTES octets — refus de la lire ; valeur non réimprimée" ;;
    *)                        non_verifiable "le canal $VF_WS_SOURCE porte un nom hors de la politique du moteur (1er caractère alphanumérique, puis [A-Za-z0-9._-], ni séparateur de chemin, ni '.'/'..', ni '..' en sous-chaîne) — valeur non réimprimée" ;;
  esac
fi
WS_NAME="$VF_WS_NAME"
WS_CANAL="$VF_WS_SOURCE"

# --- État 4 : partitionné, aucun canal composable ne résout ---------------------------------------
if [ -z "$WS_NAME" ]; then
  signal "\`.planning/\` est PARTITIONNÉ mais aucun canal composable ne résout de workstream (ni GSD_WORKSTREAM, ni .planning/active-workstream). Le pointeur de session du moteur, lui, vit dans os.tmpdir()/gsd-workstream-sessions/<condensat sur 16 du chemin absolu réel du .planning>/<clé de session> : effacé au redémarrage, indexé sur le chemin absolu, donc distinct par worktree et jamais hérité — non composable avec « un écrivain = un worktree » (ADR-064). Remède : \`export GSD_WORKSTREAM=<nom>\` dans ce worktree (canal de premier rang, il court-circuite le pointeur de session), ou \`gsd-tools workstream set <nom>\` si le runtime n'expose aucune clé de session."
  exit 1
fi

WS_DIR="$WS_ROOT/$WS_NAME"

# --- État 3 : nom résolu, dossier absent — l'auto-nettoyage du moteur rendu audible ----------------
if [ ! -d "$WS_DIR" ]; then
  signal "le workstream « $WS_NAME » est résolu par le canal $WS_CANAL, mais son dossier .planning/workstreams/$WS_NAME/ n'existe pas. Le moteur, lui, effacerait le pointeur en silence et rendrait « aucun workstream », sans un mot. Créer le dossier, ou corriger le canal (GSD_WORKSTREAM)."
  exit 1
fi

# --- États 1 et 2 : conforme ----------------------------------------------------------------------
diag "conforme — workstream « $WS_NAME » résolu par le canal $WS_CANAL, dossier présent : composable avec ADR-064."
exit 0
