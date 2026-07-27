#!/usr/bin/env bash
# check-doc-drift.sh — La documentation a-t-elle suivi le code ? (SIG-03)
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit JAMAIS que la doc est
# fausse ou périmée — seulement qu'elle N'A PAS BOUGÉ depuis N commits de code. C'est le jugement
# de l'agent (ou de l'utilisateur) de décider si cette absence de mouvement est un problème réel.
#
# Heuristique (D-07) : nombre de commits ayant touché du code source depuis le dernier commit ayant
# touché soit docs/ (arbre entier), soit un README* À LA RACINE SEULEMENT — un README.md de module
# (plugin/<mod>/README.md) ne compte PAS comme mise à jour de doc, sans quoi tout commit touchant
# l'un des N modules ferait taire le signal pour tout le dépôt. Le pathspec `README*` (sans slash)
# est nativement ancré à la racine par git : un chemin qui ne COMMENCE PAS par "README" ne matche
# jamais, donc plugin/*/README.md est exclu par construction (vérifié empiriquement, aucune magie
# supplémentaire requise).
#
# Aucun commit de doc dans tout l'historique (y compris un dépôt à 0 commit) → silence, exit 3 —
# jamais de division par un historique vide. Un commit qui touche À LA FOIS du code et docs/ (ou un
# README* racine) COMPTE comme commit de doc : il devient le SHA de départ, le compteur des commits
# de code repart de 0 juste après lui.
#
# Le décompte se fait avec `git rev-list --count <SHA>..HEAD -- . ':!docs' ':!README*'` — un
# ENSEMBLE d'ancêtres borné par le graphe de commits, jamais une liste triée par horodatage. C'est
# ce qui rend le compte déterministe même quand deux commits partagent le même horodatage (le
# parcours du graphe par git est stable pour un état de dépôt donné, l'ordre de tri par date seul
# ne le serait pas).
#
# Seuil (D-08) : --threshold <N>, défaut 20. compte < seuil → silence, exit 3 ; compte >= seuil →
# signal [doc-drift], exit 0. Validation du seuil (résolution de l'arête "precision", non couverte
# littéralement par D-08 mais cohérente avec la convention du dépôt "argument invalide → 64") :
# --threshold sans valeur → 64 ; valeur ne matchant pas ^[0-9]+$ (donc vide, négative, ou non
# entière) → message sur stderr + 64. --threshold 0 EST une valeur valide et rend le signal
# systématique dès qu'un commit de doc existe — ce n'est pas un accident, c'est la sémantique
# attendue d'un seuil réglable à zéro.
#
# Silence hors dépôt git (D-09) : `git rev-parse --is-inside-work-tree` échoue (dossier hors d'un
# arbre de travail git) → silence total sur stdout, exit 3, sans message d'erreur imprimé sur
# stdout (les diagnostics de git restent sur stderr, jamais capturés dans le signal).
#
# Durcissement git (T-17-06) : ce script est le PREMIER de plugin/**/scripts/ à shell-out vers git.
# --path pointe potentiellement vers un dépôt cloné non maîtrisé — sa configuration (.git/config)
# ne doit jamais pouvoir faire exécuter un programme lors d'une simple lecture au SessionStart.
# TOUTES les invocations git passent par le wrapper unique git_safe() (voir plus bas), qui applique
# systématiquement `-c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks`, en plus des
# variables d'environnement GIT_CONFIG_NOSYSTEM=1, GIT_TERMINAL_PROMPT=0, GIT_OPTIONAL_LOCKS=0
# exportées en tête de script. Motif écrit une seule fois, jamais répété par invocation.
#
# Usage:
#   check-doc-drift.sh [--path <dir>] [--threshold <N>] [--hook] [--quiet]
# Defaults: --path .  --threshold 20
#
# --hook change UNIQUEMENT le format d'affichage (parité avec les deux autres scripts de la phase) ;
# ce script n'a qu'un seul gabarit de signal, donc --hook n'altère aucun rendu — il ne sert qu'à la
# cohérence d'interface et au gate de mutuelle exclusion avec --quiet. Les 3 exits (0/3/64) restent
# identiques avec ou sans --hook.
#
# Exit codes:
#   0  = signal [doc-drift] émis (seuil atteint ou dépassé)
#   3  = rien à signaler (hors dépôt git, aucun commit de doc, ou compte < seuil)
#   64 = argument inconnu, --path sans valeur, --threshold sans valeur ou invalide, ou --hook +
#        --quiet ensemble
set -uo pipefail
shopt -s nullglob

ROOT="."
THRESHOLD="20"
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-doc-drift] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --threshold)
      if [ "$#" -lt 2 ]; then
        echo "[check-doc-drift] --threshold nécessite une valeur" >&2
        exit 64
      fi
      THRESHOLD="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-doc-drift] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique (même position que le gate --path).
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-doc-drift] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

# Validation du seuil : vide, non entier, ou négatif → 64. 0 est valide.
case "$THRESHOLD" in
  ''|*[!0-9]*)
    echo "[check-doc-drift] --threshold doit être un entier positif ou nul (reçu : '$THRESHOLD')" >&2
    exit 64
    ;;
esac

say() { [ "$QUIET" -eq 1 ] || echo "[check-doc-drift] $*" >&2; }

# --- Durcissement git (T-17-06) : un dépôt cloné non maîtrisé ne doit jamais pouvoir faire exécuter
# un programme via sa propre configuration lors d'une simple lecture au SessionStart. Motif écrit
# une seule fois, appliqué par TOUTES les invocations git de ce script via ce wrapper.
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() { # <args...> — toute invocation git de ce script passe par ici, jamais un appel nu.
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}

# --- Silence hors dépôt git (D-09) --------------------------------------------------------------
if ! git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  say "$ROOT hors d'un arbre de travail git — rien à constater."
  exit 3
fi

# --- SHA du dernier commit de doc (docs/ arbre entier, ou README* racine seulement) --------------
# 'docs' (sans wildcard) = motif littéral, matche récursivement tout le sous-arbre. 'README*'
# (wildcard sans slash) est nativement ancré au début du chemin relatif à $ROOT par git : un
# chemin qui ne commence pas par "README" ne matche jamais, donc plugin/*/README.md est exclu par
# construction — vérifié empiriquement (D-07), aucune magie pathspec supplémentaire nécessaire.
DOC_SHA="$(git_safe log -1 --format=%H -- docs 'README*' 2>/dev/null)"

if [ -z "$DOC_SHA" ]; then
  say "aucun commit de documentation dans l'historique — rien à constater."
  exit 3
fi

# --- Décompte des commits de code depuis ce SHA (exclu) jusqu'à HEAD -----------------------------
# Ensemble d'ancêtres borné par le graphe (rev-list --count), jamais une liste triée par
# horodatage — déterministe même si deux commits de doc partagent le même horodatage. Les mêmes
# chemins de doc que ceux qui définissent le point de départ sont exclus du décompte : un commit
# mixte code+docs devient donc le SHA de départ (car il touche docs/), et le compteur des commits
# de code repart de 0 juste après lui.
COUNT="$(git_safe rev-list --count "${DOC_SHA}..HEAD" -- . ':!docs' ':!README*' 2>/dev/null)"
case "$COUNT" in ''|*[!0-9]*) COUNT=0 ;; esac

# --- Comparaison au seuil (D-08) ------------------------------------------------------------------
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  say "seuil atteint : ${COUNT} commits de code depuis la dernière mise à jour de la doc (seuil ${THRESHOLD})."
  printf '%s\n' "[doc-drift] ${COUNT} commits de code depuis la dernière mise à jour de la doc."
  printf '%s\n' "            → propose gsd-docs-update."
  exit 0
fi

say "${COUNT} commits de code depuis la dernière mise à jour de la doc, sous le seuil (${THRESHOLD}) — rien à signaler."
exit 3
