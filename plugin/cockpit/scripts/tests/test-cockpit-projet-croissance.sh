#!/usr/bin/env bash
# test-cockpit-projet-croissance.sh — P10.3 : le mutant de la coupe de valeur (ancienne coupe de valeur de « Depends on » rétablie dans une copie de vf-cockpit-formats.mjs) fait rougir le test de croissance
# générique (projet-croissance.mjs, UNE source partagée avec P10.1, P10.2, P10.4 et P10.5 de test-cockpit-projet-graphe.sh). C'est la preuve par mutant la plus longue du graphe Projet : isolée pour tenir la durée d'un job de CI.
# Découpe de l'ancien test-cockpit-projet.sh (arbitrage Samuel, AskUserQuestion session principale, 2026-11-07) ; le socle commun est projet-commun.sh. Sans navigateur. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
. "$(dirname "$0")/projet-commun.sh"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null   # environnement d'origine : posé par le bloc Chrome de l'ancienne suite unique, il valait pour les sections suivantes (en CI, Chrome présent) ; ni config git système ni globale du poste

# ---------- P10 — croissance : aucune regex lue sur le planning n'est plus que linéaire (classe fermée, pas une forme à la fois) ----------
# Inventaire des regex appliquées au texte du planning (formats.mjs : tous les motifs de champ, de titre, d'exigence, de coupe et du diagnostic ; planning.mjs : nom de case, suffixe de statut,
# jalons, frontmatter ; drift.mjs : espace avant « : », coupe « · », phases illisibles, jalons ; project.mjs : objectif de plan, intertitres de BACKLOG ; avancement.mjs : statut de recette).
# Le test fabrique pour chaque forme lue et chaque caractère pathologique une ligne à N puis 2N, lue par readPlanning ET detectDrift ; il juge le RAPPORT des temps, pas un temps absolu seul.
echo "=== P10.3 — mutant de la coupe de valeur : le test de croissance rougit ==="
mut7 cr-coupe vf-cockpit-formats.mjs "(?::\\\\*\\\\*|\\\\*\\\\*\${COLON})))" "(?:\${COLON}\\\\*\\\\*|\\\\*\\\\*\${COLON})))" > "$WORK/ancre-cr2.txt"
assert_eq "P10.3 — mutant (ancienne coupe de valeur rétablie, ancre présente) : le test de croissance rougit" "$(cat "$WORK/ancre-cr2.txt")|$(CROISSANCE_FORME='Depends on:** 1 **' node "$CROISSANCE" "$WORK/mut-cr-coupe" | grep -c 'échec(s) sur')" "muté|1"

bilan
