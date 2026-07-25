#!/usr/bin/env bash
# probe-memory-guards.sh — Signal SessionStart : les gardes mémoire sont-elles RÉELLEMENT actives ?
# (ADR-054 — suggestion du rapport terrain adoptée telle quelle : « une ligne visible au démarrage,
# du type "garde mémoire inactive : python3 injoignable", changerait la nature du problème ».)
#
# Les gardes (guard-read / guard-bash / post-edit-reindex) sont fail-open par design : sans
# interpréteur Python UTILISABLE, elles laissent passer sans bloquer le travail. Sous Windows, le
# stub Microsoft Store `python3` rend ce repli INVISIBLE : présent dans le PATH (`command -v`
# réussit) mais inerte à l'exécution — la garde paraît installée et ne protège rien. Cas aggravant
# couvert ici : l'environnement d'installation et celui des hooks peuvent différer — ce probe
# tourne dans l'ENVIRONNEMENT RÉEL DES HOOKS, à chaque démarrage de session.
#
# UNE sonde d'exécution réelle par session (budget SessionStart — jamais par tool call, les gardes
# gardent leur détection par chemin à zéro spawn). Silence = tout va bien. Advisory : exit 0
# toujours (wiring `|| true` en plus).
#
# VG-7 (F13) : la sonde ne vérifiait QUE l'interpréteur Python, jamais le câblage des gardes —
# son silence valait « tout va bien » même gardes absentes. Elle vérifie désormais AUSSI que les
# trois scripts de garde sont posés à côté d'elle (même dossier d'install, copy_module_scripts).
# `--strict` (usage gate/CI, PAS le hook) : exit 1 si au moins un signal émis.
set -uo pipefail

STRICT=false
[ "${1:-}" = "--strict" ] && STRICT=true
FINDINGS=0

probe() {
  # Exécution réelle, version ≥ 3 exigée ; timeout-gardée là où timeout existe (Git Bash : oui ;
  # macOS : non, mais le stub n'y existe pas). Rejet des chemins WindowsApps (stub Store).
  local cand="$1"
  command -v "$cand" >/dev/null 2>&1 || return 1
  case "$(command -v "$cand" 2>/dev/null)" in *WindowsApps*) return 1 ;; esac
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 "$cand" -c 'import sys; sys.exit(0 if sys.version_info[0]>=3 else 1)' >/dev/null 2>&1
  else
    "$cand" -c 'import sys; sys.exit(0 if sys.version_info[0]>=3 else 1)' >/dev/null 2>&1
  fi
}

if ! probe python3 && ! probe python; then
  echo "⚠ VibeFlow : gardes mémoire INACTIVES — python3/python injoignable depuis les hooks (stub Microsoft Store ou Python absent). Lecture index-first et réindexation des registres sont en fail-open : elles ne protègent RIEN tant qu'un vrai Python n'est pas dans le PATH de Git Bash (installer depuis python.org en cochant « Add to PATH »)."
  FINDINGS=$((FINDINGS + 1))
fi

# Câblage : les gardes existent-elles là où l'install les pose (même dossier que ce probe) ?
DIR="$(cd "$(dirname "$0")" && pwd)"
missing=""
for g in guard-read-registres.sh guard-bash-registres.sh post-edit-reindex.sh; do
  [ -f "$DIR/$g" ] || missing="${missing}${missing:+, }$g"
done
if [ -n "$missing" ]; then
  echo "⚠ VibeFlow : gardes mémoire NON POSÉES — script(s) manquant(s) dans $DIR : $missing. Réinstaller le module consolidator (/vf-update) pour restaurer la protection des registres."
  FINDINGS=$((FINDINGS + 1))
fi

if $STRICT && [ "$FINDINGS" -gt 0 ]; then exit 1; fi
exit 0
