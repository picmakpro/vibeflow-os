#!/usr/bin/env bash
# a51-commun.sh — aides communes des témoins de l'idiome A51 (80-a51), À SOURCER (jamais lancé seul) par les suites d'une famille d'extensions ui/.
#   Attend HERE_T (dossier des tests), CHROME, REAL_HOME ; rend le travail à a51-rejeu.mjs (mesure, un Chrome) et a51-verdict.mjs (jugement).
#   a51_mesurer <fichier-json> <url> <onglet> <autre> <fichiers> <jetons-de-style> <selecteurs> [<amorce>]
#   a51_verdict <fichier-json> retours|rejeu [--absent-ailleurs]   -> « ok » ou la première anomalie
a51_mesurer() {
  local sortie="$1"; shift
  REAL_HOME="${REAL_HOME:-$HOME}" node "$HERE_T/a51-rejeu.mjs" "$CHROME" "$@" > "$sortie" 2> "${sortie%.json}.err"
}
a51_verdict() { local f="$1"; shift; node "$HERE_T/a51-verdict.mjs" "$@" < "$f"; }
