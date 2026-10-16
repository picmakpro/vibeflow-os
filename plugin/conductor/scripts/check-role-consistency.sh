#!/usr/bin/env bash
# check-role-consistency.sh — Le poste de l'humain figure-t-il dans la liste du projet ?
# (Phase 58, P58-D-09 et P58-D-10, exigences RLPO-03, RLPO-08, RLPO-09)
#
# Rôle : CONSTATER, jamais corriger ni bloquer (ADR-031, ADR-074). Un poste est une vue, pas un
# droit : aucune décision de sécurité ne lit ce gate. Le poste vient du lecteur unique `vf-role.sh
# get` (P58-D-15) ; la liste du projet est la clé `vf_roles` du `.planning/config.json` de la
# RACINE (jamais d'un compartiment, P58-D-02), lue seule.
#
# LECTURE SEULE, sans exception : ce script ne crée, ne modifie et n'efface aucun fichier.
#
# États mutuellement exclusifs, évalués dans cet ordre, le premier qui matche gagne :
#
#   0. Aucune source de poste (ni `--role`, ni `VF_ROLE`, ni `<racine>/.claude/vibeflow-role`)
#      → silence, code 3, aucun octet sur stdout ni stderr.
#   1. Le lecteur refuse la valeur (invalide, fichier vide compris) → code 1.
#   2. Le lecteur ne peut pas lire le fichier de poste (lien, non régulier, illisible, trop long,
#      plusieurs lignes), ou ne répond pas → code 5, erreur d'analyse BRUYANTE.
#   3. Pas de `.planning/config.json` à la racine, ou pas de clé `vf_roles` → silence, code 3.
#   4. `config.json` illisible, ou `vf_roles` hors contrat (non-liste, liste vide, élément non
#      chaîne, valeur hors solo|product|dev) → code 5.
#   5. Le poste figure dans la liste → code 0 ; sinon → code 1 (`solo` doit être listé pour être
#      présent).
#
# Usage:
#   check-role-consistency.sh [--path <dir>] [--role <poste>] [--hook]
#   check-role-consistency.sh --help
#
# Racine : --path > CLAUDE_PROJECT_DIR > git rev-parse --show-toplevel > "." (jamais par comptage
# de ../). `--role <poste>` juge un poste CANDIDAT avant toute pose (entrée du refus à la pose de
# l'engine) : il remplace les deux autres sources.
#
# `--hook` : sur stdout, la ligne exacte `Poste : <X>` dès que le lecteur rend X différent de
# `solo` sans erreur d'analyse (lecteur ou config.json), quel que soit le verdict de cohérence
# 0, 1 ou 3 (rien en `solo`, rien sur le code 5). La valeur
# imprimée est la valeur VALIDÉE, jamais le contenu brut du fichier : seule elle entre dans le
# contexte du modèle. Seul le code 3 est traduit en 0 ; 1, 5, 17 et 64 ressortent inchangés, le
# constat va sur stderr.
#
# Env:
#   VF_ROLE            — poste de la session (lu par le lecteur).
#   CLAUDE_PROJECT_DIR — racine du projet quand `--path` est absent.
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0  = poste présent dans la liste vf_roles du projet.
#   1  = poste hors de la liste, ou valeur de poste invalide.
#   3  = SILENCE — aucune source de poste, ou pas de config.json, ou pas de clé vf_roles. Sous
#        --hook, traduit en 0 (D-06/D-07).
#   5  = erreur d'analyse ou d'outillage BRUYANTE — fichier de poste illisible, config.json
#        illisible, vf_roles hors contrat, lecteur ou vf-portable.sh introuvable. Jamais traduite,
#        jamais repliée sur 0, 1 ni 3.
#   17 = interpréteur Python indisponible (fail-open bruyant, marqueur de santé).
#   64 = erreur d'usage (argument inconnu, option sans valeur) — jamais traduit.
#   Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness.
set -uo pipefail

ROOT=""
ROLE_OPT=""
HAS_ROLE_OPT=0
HOOK=0

usage_err() { echo "[check-role-consistency] $1" >&2; exit 64; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "--path nécessite une valeur"
      ROOT="$2"; shift 2 ;;
    --path=*)
      ROOT="${1#--path=}"
      [ -n "$ROOT" ] || usage_err "--path nécessite une valeur"
      shift ;;
    --role)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "--role nécessite une valeur"
      ROLE_OPT="$2"; HAS_ROLE_OPT=1; shift 2 ;;
    --role=*)
      ROLE_OPT="${1#--role=}"
      [ -n "$ROLE_OPT" ] || usage_err "--role nécessite une valeur"
      HAS_ROLE_OPT=1; shift ;;
    --hook) HOOK=1; shift ;;
    -h|--help) awk '/^set -uo/{exit} /^# /{sub(/^# /,""); print}' "$0"; exit 0 ;;
    *) usage_err "argument inconnu" ;;
  esac
done

if [ "$HOOK" -eq 1 ]; then PFX="[role-consistency]"; else PFX="[check-role-consistency]"; fi

# Constat : stderr dans les deux modes (jamais sur stdout, qui entre dans le contexte du modèle).
signal() { echo "$PFX $*" >&2; }

# hook_exit <code> : sous --hook, SEUL le code 3 (silence) devient 0. 1, 5, 17, 64 ne sont jamais
# traduits (P58-PL-10).
hook_exit() {
  local code="$1"
  if [ "$HOOK" -eq 1 ] && [ "$code" -eq 3 ]; then exit 0; fi
  exit "$code"
}

if [ -z "$ROOT" ]; then
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    ROOT="$CLAUDE_PROJECT_DIR"
  else
    export GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_OPTIONAL_LOCKS=0
    ROOT="$(git -c core.fsmonitor= -c core.hooksPath=/dev/null rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
    [ -n "$ROOT" ] || ROOT="."
  fi
fi

# --- État 0 : aucune source de poste → silence total ---------------------------------------------
ROLE_FILE="$ROOT/.claude/vibeflow-role"
if [ "$HAS_ROLE_OPT" -eq 0 ] && [ -z "${VF_ROLE:-}" ] && [ ! -e "$ROLE_FILE" ] && [ ! -L "$ROLE_FILE" ]; then
  hook_exit 3
fi

# --- États 1 et 2 : le lecteur unique ------------------------------------------------------------
READER="$(dirname "$0")/vf-role.sh"
if [ ! -f "$READER" ]; then
  signal "erreur d'analyse : lecteur du poste introuvable"
  hook_exit 5
fi
if [ "$HAS_ROLE_OPT" -eq 1 ]; then
  ROLE_OUT="$(VF_ROLE="$ROLE_OPT" bash "$READER" get --path "$ROOT" 2>&1)"; RRC=$?
else
  ROLE_OUT="$(bash "$READER" get --path "$ROOT" 2>&1)"; RRC=$?
fi
case "$RRC" in
  0) ROLE="$ROLE_OUT" ;;
  1)
    signal "poste invalide (attendu solo|product|dev ; valeur non réimprimée)"
    hook_exit 1 ;;
  5)
    signal "erreur d'analyse : $ROLE_OUT"
    hook_exit 5 ;;
  *)
    signal "erreur d'analyse : le lecteur du poste a échoué (code $RRC)"
    hook_exit 5 ;;
esac
# Défense en profondeur : seule une valeur de l'ensemble fermé peut sortir de ce script.
case "$ROLE" in
  solo|product|dev) : ;;
  *) signal "erreur d'analyse : réponse inattendue du lecteur du poste"; hook_exit 5 ;;
esac

# verdict_exit <code> : sortie des verdicts de COHÉRENCE (0, 1, 3). La ligne de contexte dit le
# poste, pas sa cohérence : elle précède donc ces trois verdicts, quel qu'il soit. Elle ne sort
# jamais sur une erreur d'analyse (5) ni sur 17 : ces sorties passent directement par hook_exit.
verdict_exit() {
  if [ "$HOOK" -eq 1 ] && [ "$ROLE" != "solo" ]; then
    printf 'Poste : %s\n' "$ROLE"
  fi
  hook_exit "$1"
}

# --- États 3 et 4 : la liste du projet -----------------------------------------------------------
CFG="$ROOT/.planning/config.json"
[ -e "$CFG" ] || verdict_exit 3

# Un outil de la chaîne absent (la bibliothèque vf-portable.sh) est une ERREUR D'OUTILLAGE, jamais
# le verdict 1 « poste hors de la liste » : le bloc canonique ci-dessous sort 1 (son texte est figé
# par somme de contrôle, on n'y touche pas), ce filet de sortie le traduit en 5 — le code bruyant
# déjà employé plus haut pour le lecteur introuvable (état 2) — donc jamais traduit sous --hook et
# jamais silencieux (P58-PL-10). Le refus à la pose de l'engine échoue ainsi fermé, avec le bon message.
_vf_locator_done=0
_vf_locator_failed() {
  [ "$_vf_locator_done" -eq 1 ] && return 0
  trap - EXIT
  signal "erreur d'outillage : bibliothèque vf-portable.sh introuvable — cohérence du poste non vérifiable"
  hook_exit 5
}
trap _vf_locator_failed EXIT
# >>> vf-portable:locator (bloc canonique, contrat PR #29 §3 / D-04 — Phase 30 plan 30-05. Ne
# pas retaper à la main : copier depuis plugin/_internal/lib/vf-portable.sh entre ces deux
# marqueurs — seul le préfixe de message varie d'un consommateur à l'autre (identité vérifiée
# par somme de contrôle dans test-vf-portable.sh).
# Préfixe de ce consommateur : [check-role-consistency]
#   1. $(dirname "$0")/vf-portable.sh              → install à plat (TARGET_ROOT/scripts)
#   2. $(dirname "$0")/lib/vf-portable.sh           → engine dans le cache du plugin
#   3. remontée bornée (<= 4 niveaux) depuis $(dirname "$0") vers _internal/lib/vf-portable.sh
#      → module/installeur exécuté depuis le dépôt, quelle que soit sa profondeur réelle
#   4. $(dirname "$0")/../../scripts/vf-portable.sh → extracteur kpi copié
# Aucun candidat trouvé → message préfixé en stderr + sortie non-zéro. Jamais un `source` muet.
_vf_portable_lib=""
_vf_portable_dir="$(dirname "$0")"
for _vf_portable_cand in "$_vf_portable_dir/vf-portable.sh" "$_vf_portable_dir/lib/vf-portable.sh"; do
  [ -f "$_vf_portable_cand" ] && { _vf_portable_lib="$_vf_portable_cand"; break; }
done
if [ -z "$_vf_portable_lib" ]; then
  _vf_portable_walk="$_vf_portable_dir"
  for _vf_portable_i in 1 2 3 4; do
    _vf_portable_walk="$_vf_portable_walk/.."
    if [ -f "$_vf_portable_walk/_internal/lib/vf-portable.sh" ]; then
      _vf_portable_lib="$_vf_portable_walk/_internal/lib/vf-portable.sh"
      break
    fi
  done
fi
if [ -z "$_vf_portable_lib" ] && [ -f "$_vf_portable_dir/../../scripts/vf-portable.sh" ]; then
  _vf_portable_lib="$_vf_portable_dir/../../scripts/vf-portable.sh"
fi
if [ -z "$_vf_portable_lib" ]; then
  echo "[check-role-consistency] vf-portable.sh introuvable (candidats épuisés — installer/mettre à jour vibeflow)" >&2
  exit 1
fi
# shellcheck source=/dev/null
. "$_vf_portable_lib"
unset _vf_portable_lib _vf_portable_dir _vf_portable_cand _vf_portable_walk _vf_portable_i
# <<< vf-portable:locator
_vf_locator_done=1
trap - EXIT

if ! vf_resolve_python; then
  vf_guard_unavailable "check-role-consistency.sh" "aucun interpréteur Python joignable : cohérence du poste non vérifiable"
  exit $?
fi

PY_PROG='
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8-sig") as f:
        d = json.load(f)
except Exception:
    print("illisible"); sys.exit(0)
if not isinstance(d, dict):
    print("illisible"); sys.exit(0)
if "vf_roles" not in d:
    print("absente"); sys.exit(0)
v = d["vf_roles"]
if isinstance(v, list) and v and all(isinstance(x, str) and x in ("solo", "product", "dev") for x in v):
    print("liste " + " ".join(v))
else:
    print("illisible")
'
VERDICT="$(vf_python -c "$PY_PROG" "$CFG" 2>/dev/null)"; PRC=$?
if [ "$PRC" -ne 0 ]; then
  signal "erreur d'analyse : lecture de la liste vf_roles impossible"
  hook_exit 5
fi
case "$VERDICT" in
  absente) verdict_exit 3 ;;
  "liste "*)
    LISTE=" ${VERDICT#liste } "
    case "$LISTE" in
      *" $ROLE "*) verdict_exit 0 ;;
      *)
        signal "poste « $ROLE » hors de la liste du projet (vf_roles de .planning/config.json) — un poste est une vue, pas un droit ; rien n'est corrigé (ADR-031)"
        verdict_exit 1 ;;
    esac ;;
  *)
    signal "erreur d'analyse : .planning/config.json illisible ou vf_roles hors contrat (attendu une liste non vide de solo|product|dev)"
    hook_exit 5 ;;
esac
