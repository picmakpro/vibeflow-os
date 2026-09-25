#!/usr/bin/env bash
# detect-gsd-engine.sh — Le MOTEUR de planning GSD est-il en place sur ce lab ?
#
# Rôle (ADR-055) : répondre à une question FACTUELLE, jamais à une question de métier.
# Le métier d'un lab relève du JUGEMENT du skill (references/domain-detection.md) — un
# détecteur bash s'y tromperait (un lab de contenu peut avoir un package.json). Ce script
# ne dit donc PAS « ce lab est dev » : il dit « il y a (ou non) un moteur GSD en place »,
# et le skill décide ensuite.
#
# Usage:
#   detect-gsd-engine.sh [--path <dir>] [--quiet]
# Defaults: --path .planning
# Env: GSD_HOME — surchargeable pour les tests. Non fourni, résolu par cascade (gsd-core
#   projet-local > gsd-core global > legacy get-shit-done > défaut gsd-core) ; voir détail
#   dans default_gsd_home() plus bas.
#
# Exit codes, évalués dans CET ordre (le premier qui matche gagne) :
#   1 = chaîne GSD absente de la machine — aucun moteur disponible
#   0 = moteur GSD ACTIF — le STATE.md racine porte gsd_state_version, OU (Phase 41.1 / D-04) au
#       moins un compartiment `.planning/workstreams/<nom>/STATE.md` porte gsd_state_version, OU à
#       défaut porte `workstream:`+`created:` (facture de `workstream create`)
#   2 = signalement de MIGRATION (STATE.md de facture planning-core + signaux de code)
#   3 = aucun moteur en place (pas de .planning/, ou socle sans marqueur ni signal de code)
#  64 = argument inconnu
set -uo pipefail

PLANNING_DIR=".planning"

# Fenêtre de compat dual-layout (D-01, 11-CONTEXT.md) : gsd-core (nouveau) prioritaire, legacy
# get-shit-done en repli. Cascade à 4 niveaux, résolue uniquement si GSD_HOME n'est pas déjà
# fourni par l'environnement (préserve les appels qui fixent GSD_HOME explicitement) :
#   1. <projet>/.claude/gsd-core     — scope --local de gsd-core 1.9.0 (payload projet)
#   2. $CLAUDE_CONFIG_DIR|$HOME/.claude/gsd-core — scope --global de gsd-core
#   3. $CLAUDE_CONFIG_DIR|$HOME/.claude/get-shit-done — legacy (pas de variante projet-local :
#      antérieur au scope --local, aucune preuve qu'il ait pu être posé à l'échelle projet)
#   4. défaut — nomme le futur (gsd-core) dans les messages d'erreur, pas le passé
default_gsd_home() {
  local root claude_home
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core" ]; then
    echo "$root/.claude/gsd-core"
  elif [ -d "$claude_home/gsd-core" ]; then
    echo "$claude_home/gsd-core"
  elif [ -d "$claude_home/get-shit-done" ]; then
    echo "$claude_home/get-shit-done"
  else
    echo "$claude_home/gsd-core"
  fi
}
GSD_HOME="${GSD_HOME:-$(default_gsd_home)}"
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path) PLANNING_DIR="${2:?--path nécessite une valeur}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[detect-gsd-engine] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[gsd-engine] $*"; }

# --- Priorité 1 : la chaîne GSD est-elle installée ? ---
if [ ! -d "$GSD_HOME" ]; then
  say "Chaîne GSD absente ($GSD_HOME) — aucun moteur de planning disponible."
  exit 1
fi

STATE_FILE="$PLANNING_DIR/STATE.md"

# Le marqueur du moteur est une clé du FRONTMATTER, pas une chaîne du fichier. Un `grep` non borné
# prendrait un `gsd_state_version:` cité dans le CORPS (bloc d'exemple YAML, doc inline) pour le
# marqueur réel : le script sortirait « moteur actif » sur un socle planning-core, et les deux hooks
# qui le câblent en `&& exit 0` se retireraient à tort. D'où la borne.
# Modèle : extract_frontmatter_field() dans plugin/dev-orchestrator/scripts/build-gsd-index.sh.
# Réimplémenté localement et non sourcé : planning-core ne dépend d'aucun module (`requires: []`).
has_frontmatter_key() { # <file> <key>
  awk -v key="$2" '
    NR == 1 && $0 ~ /^---[[:space:]]*$/   { in_fm = 1; next }
    in_fm && $0 ~ /^---[[:space:]]*$/     { exit }
    in_fm && $0 ~ "^" key ":[[:space:]]*" { found = 1; exit }
    END { exit (found ? 0 : 1) }
  ' "$1"
}

# Politique de workstream (Phase 41.1 / D-01) — sourcing DIRECT : ce script vit dans
# `planning-core/scripts/`, voisin du fichier de politique, et `planning-core: requires: []` n'a
# besoin d'aucun repli inter-module. Si le sourcing échoue, `vf_ws_enumerate` sera introuvable et
# la priorité 2bis retombera sur sa branche `*)` (code imprévu 127) — annoncée, jamais silencieuse.
# shellcheck source=/dev/null
. "$(dirname "$0")/workstream-policy.sh"

# --- Priorité 2 : moteur GSD actif ? (marqueur = clé du frontmatter) ---
if [ -f "$STATE_FILE" ] && has_frontmatter_key "$STATE_FILE" gsd_state_version; then
  say "Moteur GSD actif — le planning de ce projet appartient à GSD."
  exit 0
fi

# --- Priorité 2bis : au moins un compartiment de workstream porte le marqueur --------------------
# AUCUNE DÉGRADATION SILENCIEUSE (invariant de mission, CORRECTION C-06 du juge frais, 2e passe).
# Patron IDENTIQUE aux plans 41.1-02 et 41.1-04, et pour les mêmes raisons :
#   - énumération vers un FICHIER TEMPORAIRE, jamais `$(...)` : une substitution de commande PERD
#     le code de retour dès qu'on teste la chaîne produite ;
#   - rc CAPTURÉ dans une variable préfixée ;
#   - stderr LAISSÉ PASSER (`2>&2`), jamais `2>/dev/null` ;
#   - `case` avec branche `*)` NOMMÉE.
# MESURE qui motive : les DEUX formes de rc=2 de `vf_ws_enumerate` (lien symbolique sur
# `workstreams/`, vide après filtrage anti-lien) rendent 0 ligne sur stdout et portent leur raison
# UNIQUEMENT sur stderr. Avec le rc jeté et stderr coupé, un `.planning/workstreams` détourné en
# lien symbolique — le vecteur T-41.1-01 du plan 41.1-01 lui-même — devient INDISTINGUABLE d'un
# dépôt non partitionné (rc=3, également 0 ligne) : ce script conclurait « Aucun moteur de planning
# en place » sans qu'AUCUNE ligne ne dise pourquoi l'invariant a été sauté.
# Le script reste NON BLOQUANT : une ligne de stderr n'est pas un blocage, les codes de sortie du
# script sont INCHANGÉS.
_dge_tmp="$(mktemp)" || _dge_tmp=""
if [ -z "$_dge_tmp" ]; then
  echo "[detect-gsd-engine] mktemp en échec — priorité 2bis SAUTÉE, le verdict qui suit ne porte que sur la racine et peut donc dire « aucun moteur » à tort" >&2
else
  vf_ws_enumerate "$PLANNING_DIR" > "$_dge_tmp" 2>&2
  _dge_rc=$?
  case "$_dge_rc" in
  0)
    : # au moins un compartiment vérifiable — suite du bloc ci-dessous
    ;;
  3)
    # SILENCE — `workstreams/` absent : dépôt NON PARTITIONNÉ, état NOMINAL (D-01). Aucun écart,
    # aucune annonce : on poursuit vers la priorité 3 exactement comme avant cette phase.
    rm -f "$_dge_tmp"; _dge_tmp=""
    ;;
  2)
    echo "[detect-gsd-engine] vf_ws_enumerate : workstreams/ présent mais AUCUN compartiment vérifiable (lien symbolique, illisible, ou vide après filtrage anti-lien) — priorité 2bis SAUTÉE, le verdict qui suit ne porte QUE sur la racine" >&2
    rm -f "$_dge_tmp"; _dge_tmp=""
    ;;
  *)
    echo "[detect-gsd-engine] vf_ws_enumerate : code de sortie imprévu ($_dge_rc, attendu 0/2/3) — priorité 2bis SAUTÉE, verdict racine seule" >&2
    rm -f "$_dge_tmp"; _dge_tmp=""
    ;;
  esac
fi
if [ -n "$_dge_tmp" ]; then
  while IFS= read -r _wsdir; do
    [ -n "$_wsdir" ] || continue
    if [ -f "$_wsdir/STATE.md" ] && has_frontmatter_key "$_wsdir/STATE.md" gsd_state_version; then
      rm -f "$_dge_tmp"
      say "Moteur GSD actif — le compartiment « $(basename "$_wsdir") » appartient à GSD."
      exit 0
    fi
  done < "$_dge_tmp"
  # Aucun compartiment conforme trouvé, mais au moins un existe : le moteur est quand même présent
  # dès qu'un `STATE.md` porte AU MOINS `workstream:`+`created:` (facture de `workstream create`).
  # CORRECTION post plan-checker (FLAG-1) : ce test ne compte PAS les clés du frontmatter — il ne
  # peut donc PAS établir la classe D-02 « non initialisé » (qui exige EXACTEMENT ces deux clés,
  # rien d'autre) ; un compartiment CORROMPU qui porterait aussi `workstream:`+`created:` PARMI
  # d'autres clés passerait ce test tout autant. Le verdict imprimé n'EMPRUNTE donc PLUS le nom de
  # la classe D-02 — il énonce le seul fait vérifié ici (présence des deux clés), jamais un
  # classement qu'il n'a pas les moyens d'établir :
  while IFS= read -r _wsdir; do
    [ -n "$_wsdir" ] || continue
    if [ -f "$_wsdir/STATE.md" ] && has_frontmatter_key "$_wsdir/STATE.md" workstream \
       && has_frontmatter_key "$_wsdir/STATE.md" created; then
      rm -f "$_dge_tmp"
      say "Moteur GSD actif — compartiment « $(basename "$_wsdir") » : frontmatter réduit détecté (workstream:+created: présents, gsd_state_version absent). Ce script ne classe pas ce compartiment (conforme/non-initialisé/corrompu, D-02) ; il constate seulement qu'un moteur GSD y est présent."
      exit 0
    fi
  done < "$_dge_tmp"
  rm -f "$_dge_tmp"
fi

# --- Priorité 3 : socle planning-core + signaux de code → migration à examiner ---
# Les signaux de code sont un indice de SURFACE : ils déclenchent un examen, jamais un verdict.
has_code_signal() {
  local f
  for f in package.json go.mod Cargo.toml pyproject.toml pom.xml build.gradle \
           build.gradle.kts composer.json Gemfile tsconfig.json Package.swift; do
    [ -f "./$f" ] && return 0
  done
  # Projet Xcode : dossier *.xcodeproj à la racine.
  for f in ./*.xcodeproj; do [ -d "$f" ] && return 0; done
  return 1
}

if [ -f "$STATE_FILE" ] && has_frontmatter_key "$STATE_FILE" planning_version; then
  if has_code_signal; then
    say "Socle de facture planning-core en présence de code — migration à examiner (ne rien réécrire)."
    exit 2
  fi
fi

# --- Priorité 4 : terrain libre — le jugement métier décide seul ---
say "Aucun moteur de planning en place."
exit 3
