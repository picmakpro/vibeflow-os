#!/usr/bin/env bash
# gsd-run.sh — lanceur de la CLI du moteur GSD (gsd-tools), appelable par CHEMIN depuis un agent.
#
# Pourquoi (issue #47) : `gsd_run` est une FONCTION shell définie par le préambule des fichiers de
# workflow GSD, jamais un binaire sur le PATH quand gsd-core est posé en répertoire. Un agent qui
# ouvre son propre bash ne l'a pas : l'appel en nom nu échoue en « introuvable ». Ce script porte
# la résolution à un seul endroit ; l'agent l'appelle comme il appelle ses autres scripts
# (`"$S"/gsd-run.sh <verbe> …`).
#
# Usage :   gsd-run.sh <verbe gsd-tools> [arguments…]      (ex. config-set workflow.x false --ws fiab)
#   Les arguments sont transmis tels quels (espaces et `--ws <nom>` compris) ; le moteur tourne
#   dans le répertoire courant, qui est l'ancre de `./.claude/gsd-core` ET du `.planning/` visé.
#
# Résolution — premier existant parmi (le payload installé prime sur un bin du PATH) :
#   1. $GSD_TOOLS, s'il est non vide ET un fichier régulier existant (sinon ignoré, jamais une erreur) ;
#   2. ./.claude/gsd-core/bin/gsd-tools.cjs                           (scope projet, ancré au CWD) ;
#   3. ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs  (scope user) ;
#   4. `command -v gsd-tools`, EN DERNIER, exécuté directement (pas via node), chemin absolu exigé.
#   Les candidats 1 à 3 s'exécutent par `exec node <fichier> "$@"`.
#
# Variables : GSD_TOOLS (candidat 1) · CLAUDE_CONFIG_DIR (candidat 3) · HOME. Aucune n'est écrite ;
#   ce script n'écrit jamais dans CLAUDE_ENV_FILE.
#
# Codes de sortie :
#   <rc de l'outil>  l'outil a tourné : son code est propagé tel quel (exec) ;
#   64               DÉFAUT D'OUTILLAGE : aucun candidat résolu, OU `node` absent alors que le
#                    candidat résolu est un .cjs. Message sur stderr (candidats essayés + install).
#   Un 64 propagé par l'outil lui-même est indiscernable de celui-ci : l'appelant qui doit les
#   distinguer relit l'état écrit (cf. vf-dev-manager.md, reset des flags), jamais `$?` seul.
#
# Disposition de sécurité (ADR-070 règle 2, amendement du 2026-10-29, `docs/ADR.md` ; vecteur frère : résolution CWD de
# `dag.sh`, retirée). Chaque disposition cite le vecteur qu'elle accepte, jamais le risque en bloc :
#   - ACCEPTÉ pour `./.claude/gsd-core` (raison : même frontière de confiance que
#     `./.claude/scripts`, que le manager exécute déjà via `$S` ; sans ce candidat, un lab en scope
#     projet n'a aucune résolution et la mission ne peut jamais démarrer) ;
#   - ACCEPTÉ pour `PATH` (raison : un PATH compromis compromet déjà toute la session) ; un résultat
#     non absolu (entrée relative ou vide du PATH = vecteur CWD déguisé) est REFUSÉ ;
#   - NON ACCEPTÉ pour `<racine>/gsd-core/bin/gsd-tools.cjs` NU (sans `.claude/`), ni pour aucun
#     candidat dérivé de `git rev-parse --show-toplevel` / `pwd` : chemin tracké dans l'arbre de
#     travail, posable par un checkout hostile. Sentinelle : test-gsd-run.sh, cas (e) ;
#   - NON ÉVALUÉ pour les autres voies (variable `GSD_TOOLS` posée par un environnement hostile :
#     même classe que PATH, non traitée à part).
#
# Portabilité : bash 3.2 (macOS) et Linux ; aucune commande externe, aucun code Python/Node inline.
set -u

_tried=""
_try_file() { # <chemin> : retient le candidat s'il est un fichier régulier
  _tried="${_tried:+$_tried, }$1"
  [ -f "$1" ]
}

_engine=""; _direct=0
if [ -n "${GSD_TOOLS:-}" ] && _try_file "$GSD_TOOLS"; then
  _engine="$GSD_TOOLS"
elif _try_file "./.claude/gsd-core/bin/gsd-tools.cjs"; then
  _engine="./.claude/gsd-core/bin/gsd-tools.cjs"
elif _try_file "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs"; then
  _engine="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs"
else
  _tried="${_tried:+$_tried, }gsd-tools (PATH)"
  _p="$(command -v gsd-tools 2>/dev/null || true)"
  case "$_p" in
    /*) if [ -f "$_p" ]; then _engine="$_p"; _direct=1; fi ;;
  esac
fi

if [ -z "$_engine" ]; then
  echo "gsd-run: défaut d'outillage — gsd-tools introuvable. Candidats essayés : ${_tried}." >&2
  echo "gsd-run: installer le moteur : npx -y \"@opengsd/gsd-core@^1\" --claude --local   (ou --global)" >&2
  exit 64
fi

if [ "$_direct" -eq 1 ]; then
  exec "$_engine" "$@"
fi
if ! command -v node >/dev/null 2>&1; then
  echo "gsd-run: défaut d'outillage — node absent du PATH, le moteur résolu ($_engine) ne peut pas tourner." >&2
  exit 64
fi
exec node "$_engine" "$@"
