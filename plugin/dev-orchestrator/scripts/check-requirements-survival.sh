#!/usr/bin/env bash
# check-requirements-survival.sh — Le ledger d'exigences a-t-il survécu à la clôture d'un jalon ?
# (LEDG-02, gate SessionStart)
#
# Rôle (ADR-055 §3, D-18-10) : ce script constate qu'un ledger est ABSENT là où un jalon a été
# déclaré clos, OU qu'un ID d'exigence garanti/voyageur a disparu du ledger VIVANT sans trace. Il ne
# dit JAMAIS qu'un ledger est faux, incomplet ou périmé, et il ne juge aucun statut, aucune prose,
# aucune forme de trace — seulement la présence ou l'absence d'un ID (contrat A-18-08). Lecteur
# d'absence, jamais juge de contenu.
#
# Détection UNIQUE (D-18-06) : toute la logique de détection vit dans la primitive sourcée
# requirements-survival-detect.sh (vf_ledger_state) — ce gate ne porte aucune logique propre.
#
# Cinq issues (A-18-01, tableau complet dans 18-01-PLAN.md), jamais un FAIL sur le contenu :
#   1. SILENCE   — ledger présent sans ID disparu, ou aucun jalon clos, ou pas de .planning/
#   2. SIGNAL    — [ledger-absent] : jalon clos ET REQUIREMENTS.md absent
#   2bis. SIGNAL — [ledger-exigences-disparues] : REQUIREMENTS.md présent, ≥1 ID disparu sans trace
#   3. BRUYANT   — [ledger-illisible] : MILESTONES.md/traces malformées (jamais un vert)
#   4. BRUYANT   — [ledger-outil-absent] : primitive introuvable ou non sourçable
#
# Ce script N'INVOQUE JAMAIS git : il lit deux fichiers sur disque (MILESTONES.md, REQUIREMENTS.md)
# et une archive optionnelle. Le durcissement git_safe() de T-17-06 est donc sans objet ici.
#
# Usage:
#   check-requirements-survival.sh [--path <dir>] [--hook] [--quiet]
# Defaults: --path .
#
# Exit codes (contrat interne, s'applique SANS --hook) :
#   0  = un signal a été émis ([ledger-absent] / [ledger-illisible] / [ledger-outil-absent] /
#        [ledger-exigences-disparues])
#   3  = rien à signaler (silence, ou cran avertissement sur lab non armé sans archive)
#   64 = argument inconnu, --path sans valeur, ou --hook + --quiet ensemble
#
# --hook traduit le SEUL code de silence interne (3) vers 0 à la frontière du harness (D-06). Voir
# docs/HOOKS-CONTRAT-SORTIE.md. L'issue 2bis (ids_missing) N'EST JAMAIS traduite vers le silence,
# quel que soit --hook et quel que soit VF_LEDGER_ARMED : un ID disparu sans explication n'est jamais
# silencieux (A-18-08).
set -uo pipefail

ROOT="."
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-requirements-survival] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-requirements-survival] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-requirements-survival] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

say() { [ "$QUIET" -eq 1 ] || echo "[check-requirements-survival] $*" >&2; }

hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}

PLANNING_DIR="${VF_LEDGER_PLANNING_DIR:-$ROOT/.planning}"

# --- Découverte de la primitive partagée par liste de chemins candidats, puis sourcing -----------
_SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
PRIMITIVE=""
for _cand in "$_SCRIPT_DIR/requirements-survival-detect.sh" \
             "$(dirname "$0")/requirements-survival-detect.sh"; do
  if [ -n "$_cand" ] && [ -r "$_cand" ]; then PRIMITIVE="$_cand"; break; fi
done

if [ -z "$PRIMITIVE" ] || ! . "$PRIMITIVE" 2>/dev/null || ! command -v vf_ledger_state >/dev/null 2>&1; then
  printf '%s\n' "[ledger-outil-absent] requirements-survival-detect.sh introuvable ou non chargeable."
  printf '%s\n' "                      → réinstaller le module dev-orchestrator."
  exit 0
fi

vf_ledger_state "$PLANNING_DIR"
state_rc=$?

case "$state_rc" in
  2)
    printf '%s\n' "[ledger-illisible] .planning/MILESTONES.md ou .planning/REQUIREMENTS.md illisible (motif : ${VF_LEDGER_REASON})."
    printf '%s\n' "                    → vérifier la forme des titres H2 clos et des traces carried-from:."
    exit 0
    ;;
  1)
    say "${VF_LEDGER_STATE} — rien à signaler."
    hook_exit 3
    ;;
  0)
    if [ -n "$VF_LEDGER_ARCHIVE" ]; then
      printf '%s\n' "[ledger-absent] Jalon « ${VF_LEDGER_MILESTONE} » clos, .planning/REQUIREMENTS.md absent."
      printf '%s\n' "                → propose de reconstituer le ledger depuis l'archive (restore-requirements-ledger.sh)."
      exit 0
    elif [ "$VF_LEDGER_ARMED" = "1" ]; then
      printf '%s\n' "[ledger-absent] Jalon « ${VF_LEDGER_MILESTONE} » clos, .planning/REQUIREMENTS.md absent — aucune archive à reconstituer."
      printf '%s\n' "                → aucune archive disponible, recréer .planning/REQUIREMENTS.md manuellement si nécessaire."
      exit 0
    else
      say "jalon « ${VF_LEDGER_MILESTONE} » clos, ledger absent, aucune archive, marqueur d'armement absent — cran avertissement."
      hook_exit 3
    fi
    ;;
  3)
    ids_shown="$(printf '%s\n' "$VF_LEDGER_MISSING_IDS" | tr ' ' '\n' | sed -n '1,5p' | tr '\n' ' ')"
    printf '%s\n' "[ledger-exigences-disparues] ${VF_LEDGER_MISSING_COUNT} exigence(s) d'archive disparue(s) du ledger vivant sans trace : ${ids_shown}"
    printf '%s\n' "                             → vérifier si livrée / reportée / abandonnée sans trace (archive du jalon)."
    exit 0
    ;;
  *)
    printf '%s\n' "[ledger-illisible] état inattendu (${state_rc}) de la primitive de détection."
    printf '%s\n' "                    → réinstaller le module dev-orchestrator."
    exit 0
    ;;
esac
