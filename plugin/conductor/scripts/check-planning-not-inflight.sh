#!/usr/bin/env bash
# check-planning-not-inflight.sh — Une phase est-elle EN VOL dans ce lab ? La précondition d'ADR-069
# de la bascule vers un planning partitionné, lue sur le DISQUE. (Phase 41.2, exigence WSCH-03)
#
# Question tranchée : « peut-on déplacer le contenu resté à la racine de .planning/ vers un
# compartiment sans casser une exécution en cours ? ». Réponse par machine, jamais présumée depuis la
# mémoire d'une session.
#
# LECTURE SEULE, sans exception : ce script ne crée, ne modifie et n'efface aucun fichier. Il ne
# lance jamais un verbe d'écriture du moteur : seul `query roadmap.analyze` (lecture) est appelé.
#
# La règle est celle de `plugin/dev-orchestrator/references/workstreams.md` §1 point 1 / §5, CONSOMMÉE
# et jamais reformulée ici. Elle remplace D-11 (2026-09-23), périmée : `workstream progress` ne rend
# aucune phase sur un arbre plat, et `progress` rend « Planned » (jamais « In Progress ») pour un PLAN
# sans SUMMARY. Trois lectures, toutes évaluées, le message nomme chaque lecture déclenchée :
#   (a)  la clé `status:` du frontmatter du STATE.md racine vaut `executing` (guillemets rognés, casse
#        ignorée) ;
#   (b)  `query roadmap.analyze` rend au moins une phase dont plan_count > summary_count ;
#   (b') au moins un sous-dossier direct de `phases/` contient un `*-PLAN.md` et AUCUN `*-SUMMARY.md`
#        (la lettre de §1 point 1 : « aucun dossier de phase dont le SUMMARY manque »).
# Jamais `workstream progress`, jamais STATE.md.current_phase.
# LIMITE RÉSIDUELLE de (b') : un dossier hors ROADMAP qui porte des SUMMARY partiels (au moins un
# SUMMARY, mais pas pour tous ses PLAN) passe : ni le moteur (b) ni (b') ne le voient.
#
# Ordre : usage -> --path -> .planning -> partition (vf_ws_enumerate : 0 = partitionné, accepté sans
# autre lecture ; 3 = plat, on continue ; autre = NON VÉRIFIABLE) -> jq -> (a) -> moteur -> (b) -> (b').
#
# Le moteur est résolu par la cascade GSD_TOOLS (fichier existant) -> `gsd-tools` sur le PATH ->
# ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs. AUCUN candidat relatif au cwd ni au
# dépôt : un fichier versionné dans une branche ne doit jamais être exécuté. GSD_WORKSTREAM hérité est
# neutralisé sur l'appel moteur (il vide `roadmap.analyze` en silence), et la forme du JSON est
# validée AVANT tout filtre.
#
# Usage:
#   check-planning-not-inflight.sh [--path <dir>]
#   check-planning-not-inflight.sh --help
#
# Defaults: --path .   (le `.planning/` inspecté est `<--path>/.planning`)
#
# Sortie : un seul mot sur stdout pour le code 0 (`plat` ou `partitionne`) ; diagnostics sur stderr.
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0  = ACCEPTÉ — aucune phase en vol (stdout `plat`), ou lab déjà partitionné (stdout `partitionne`).
#   1  = REFUSÉ (ADR-069) — (a), (b) ou (b') déclenchée ; clore la phase avant de partitionner.
#   2  = NON VÉRIFIABLE — --path introuvable, pas de `.planning/`, `workstreams/` illisible (vide,
#        lien symbolique, fichier), `jq`/`node`/moteur absents, STATE.md absent ou sans clé `status`,
#        `roadmap.analyze` en échec, en erreur, sans phase ou à compteurs non numériques. Jamais un 0
#        de complaisance : « je n'ai pas pu regarder » ne vaut pas « accepté ».
#   64 = erreur d'usage (option inconnue, option sans valeur).
set -uo pipefail

ROOT="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { echo "[check-planning-not-inflight] --path nécessite une valeur" >&2; exit 64; }
      ROOT="$2"; shift 2 ;;
    --path=*)
      ROOT="${1#--path=}"
      [ -n "$ROOT" ] || { echo "[check-planning-not-inflight] --path nécessite une valeur" >&2; exit 64; }
      shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-planning-not-inflight] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

nv() { echo "[check-planning-not-inflight] NON VÉRIFIABLE : $*" >&2; exit 2; }

[ -d "$ROOT" ] || nv "--path introuvable : $ROOT"
ROOT="$(cd "$ROOT" && pwd)"
PLANNING="$ROOT/.planning"
[ -d "$PLANNING" ] || nv "pas de répertoire .planning sous $ROOT"

# --- Partition : primitive d'énumération (0 = partitionné, 3 = plat, 2 = illisible) ----------------
_POLICY=""
for _cand in "$(dirname "$0")/workstream-policy.sh" \
             "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
  [ -f "$_cand" ] && { _POLICY="$_cand"; break; }
done
[ -n "$_POLICY" ] || nv "script des règles des sujets introuvable — règles non chargeables"
# shellcheck source=/dev/null
. "$_POLICY"
vf_ws_enumerate "$PLANNING" >/dev/null 2>&1; _enum_rc=$?
case "$_enum_rc" in
  0) echo "partitionne"; exit 0 ;;
  3) : ;;
  *) nv "le dossier des sujets est présent mais illisible (vf_ws_enumerate rc=$_enum_rc)" ;;
esac

command -v jq >/dev/null 2>&1 || nv "jq introuvable"

# --- (a) clé status: du frontmatter du STATE.md racine ----------------------------------------------
STATE="$PLANNING/STATE.md"
{ [ -f "$STATE" ] && [ -r "$STATE" ]; } || nv "STATE.md racine absent ou illisible : $STATE"
# BOM UTF-8 et CR final tolérés : même lecture que fm_get de split-planning.sh (relecture SOBR-04, v2.69.0).
status="$(LC_ALL=C awk 'NR==1 && index($0,"\357\273\277")==1{$0=substr($0,4)} {sub(/\r$/,"")} /^---[[:space:]]*$/{n++; if(n==1) next; if(n==2) exit} n==1 && /^status:/{sub(/^status:[[:space:]]*/,""); gsub(/^["'\'']|["'\'']$/,""); print; exit}' "$STATE")"
[ -n "$status" ] || nv "frontmatter de $STATE sans clé status"
status_lc="$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]*$//')"
hit_a=0
if [ "$status_lc" = "executing" ]; then hit_a=1; fi

# --- Moteur : cascade sans candidat relatif au cwd ni au dépôt --------------------------------------
GT=""
if [ -n "${GSD_TOOLS:-}" ] && [ -f "$GSD_TOOLS" ]; then GT="$GSD_TOOLS"
elif command -v gsd-tools >/dev/null 2>&1; then GT="$(command -v gsd-tools)"
elif [ -f "${CLAUDE_CONFIG_DIR:-${HOME:-/nonexistent}/.claude}/gsd-core/bin/gsd-tools.cjs" ]; then
  GT="${CLAUDE_CONFIG_DIR:-${HOME:-/nonexistent}/.claude}/gsd-core/bin/gsd-tools.cjs"
fi
[ -n "$GT" ] || nv "moteur gsd-tools introuvable (GSD_TOOLS, PATH, ~/.claude/gsd-core)"
case "$GT" in
  *.cjs) command -v node >/dev/null 2>&1 || nv "node introuvable (le moteur est un .cjs)"; RUN=(node "$GT") ;;
  *) RUN=("$GT") ;;
esac

# --- (b) roadmap.analyze : forme validée AVANT tout filtre ------------------------------------------
json="$(env -u GSD_WORKSTREAM "${RUN[@]}" --cwd "$ROOT" query roadmap.analyze 2>/dev/null)" \
  || nv "la lecture de la feuille de route par le moteur a échoué"
VALID_JQ='(.error // null) == null and (.phases | type == "array") and (.phases | length >= 1) and (.phases | all(.[]; (.plan_count | type == "number") and (.summary_count | type == "number")))'
printf '%s' "$json" | jq -e "$VALID_JQ" >/dev/null 2>&1 \
  || nv "sortie du moteur imparsable, en erreur, sans phase, ou à compteurs non numériques"
inflight_b="$(printf '%s' "$json" | jq -r '[.phases[] | select(.plan_count > .summary_count) | .number] | join(",")')"

# --- (b') dossiers de phases/ avec PLAN et sans aucun SUMMARY ---------------------------------------
bp_min=1
inflight_bp=""
for _d in "$PLANNING"/phases/*/; do
  [ -d "$_d" ] || continue
  _nplan=0; _nsum=0
  for _f in "$_d"*-PLAN.md; do [ -e "$_f" ] && _nplan=$((_nplan+1)); done
  for _f in "$_d"*-SUMMARY.md; do [ -e "$_f" ] && _nsum=$((_nsum+1)); done
  if [ "$_nplan" -ge "$bp_min" ] && [ "$_nsum" -eq 0 ]; then
    _n="${_d%/}"; inflight_bp="${inflight_bp:+$inflight_bp,}${_n##*/}"
  fi
done

# --- Verdict ----------------------------------------------------------------------------------------
if [ "$hit_a" -eq 1 ] || [ -n "$inflight_b" ] || [ -n "$inflight_bp" ]; then
  echo "[check-planning-not-inflight] REFUSÉ (ADR-069) : une phase est en vol. Clore avant de partitionner." >&2
  [ "$hit_a" -eq 1 ] && echo "  (a) status: executing dans le frontmatter de $STATE" >&2
  [ -n "$inflight_b" ] && echo "  (b) phase(s) [$inflight_b] : plans sans SUMMARY (roadmap.analyze)" >&2
  [ -n "$inflight_bp" ] && echo "  (b') dossier(s) de phases/ [$inflight_bp] : PLAN sans aucun SUMMARY" >&2
  exit 1
fi

echo "plat"
exit 0
