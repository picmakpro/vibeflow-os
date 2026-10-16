#!/usr/bin/env bash
# prove-density-suites.sh — Phase 40.1. Preuve rouge/verte des seuils codés en dur des suites de
# modules (dev-orchestrator, design-orchestrator, business-pilot-bundle, content-bundle,
# growth-bundle) : à la taille verte, aucun label de dépassement ne doit apparaître dans la sortie
# de la suite ; à la taille rouge, CHAQUE label doit apparaître. Ne touche JAMAIS l'arbre réel —
# tout se joue sur une copie de plugin/ sous mktemp -d. Bash 3.2 compatible (pas de tableaux
# associatifs — table par case/esac, pas de `declare -A`).
#
# Usage : prove-density-suites.sh <cle> <taille-verte> <taille-rouge>
# Codes : 0 = les deux tailles se comportent comme attendu ; 1 = au moins une assertion en échec ;
# 2 = usage, clé inconnue, ou allongement impossible (fichier déjà au-delà de la taille verte).
set -u
export LC_ALL=C

CLE="${1:-}"
VERTE="${2:-}"
ROUGE="${3:-}"

if [ -z "$CLE" ] || [ -z "$VERTE" ] || [ -z "$ROUGE" ]; then
  echo "usage: prove-density-suites.sh <cle> <taille-verte> <taille-rouge>" >&2
  exit 2
fi
case "$VERTE" in ''|*[!0-9]*) echo "ERREUR: taille-verte invalide: $VERTE" >&2; exit 2 ;; esac
case "$ROUGE" in ''|*[!0-9]*) echo "ERREUR: taille-rouge invalide: $ROUGE" >&2; exit 2 ;; esac

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$ROOT" ] || [ ! -d "$ROOT/plugin" ]; then
  echo "ERREUR: racine du depot introuvable (ou plugin/ absent)" >&2
  exit 2
fi

# Table interne clé -> (suite, fichiers à allonger, labels de DÉPASSEMENT avec %N).
SUITE=""
FILES=()
LABELS=()

case "$CLE" in
  dev-orchestrator)
    SUITE="plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
    FILES=(
      "plugin/dev-orchestrator/AGENT.md"
      "plugin/dev-orchestrator/agents/vf-dev-manager.md"
    )
    LABELS=(
      "T3 agent : AGENT.md = %NL (>"
      "T5 densité agent : AGENT.md = %NL (>"
      "T8 agents : vf-dev-manager.md dépasse"
      "T22 captation : AGENT.md à %N lignes"
      "T31-G : vf-dev-manager.md dépasse le plafond ADR-029 (%N/"
      "T35 (d) plafond ADR-029 : vf-dev-manager.md fait %N ligne(s) (>"
    )
    ;;
  design-orchestrator)
    SUITE="plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
    FILES=(
      "plugin/design-orchestrator/AGENT.md"
      "plugin/design-orchestrator/agents/vf-design-manager.md"
    )
    LABELS=(
      "T1 agents : vf-design-manager.md dépasse"
      "T7 densité agent : AGENT.md = %NL (>"
    )
    ;;
  business-pilot-bundle)
    SUITE="plugin/business-pilot-bundle/scripts/tests/test-business-pilot-bundle.sh"
    FILES=("plugin/business-pilot-bundle/agents/vf-business-manager.md")
    LABELS=("T2 densité : vf-business-manager.md = %NL (>")
    ;;
  content-bundle)
    SUITE="plugin/content-bundle/scripts/tests/test-content-bundle.sh"
    FILES=("plugin/content-bundle/agents/vf-content-manager.md")
    LABELS=("T2 densité : vf-content-manager.md = %NL (>")
    ;;
  growth-bundle)
    SUITE="plugin/growth-bundle/scripts/tests/test-growth-bundle.sh"
    FILES=("plugin/growth-bundle/agents/vf-growth-manager.md")
    LABELS=("T2 densité : vf-growth-manager.md = %NL (>")
    ;;
  *)
    echo "ERREUR: cle inconnue: $CLE" >&2
    exit 2
    ;;
esac

if [ ! -f "$ROOT/$SUITE" ]; then
  echo "ERREUR: suite introuvable: $SUITE" >&2
  exit 2
fi

# Refus si un fichier ciblé dépasse déjà la taille verte demandée (allongement impossible : ce
# script ne sait qu'ÉTENDRE un fichier, jamais le raccourcir).
for f in "${FILES[@]}"; do
  if [ ! -f "$ROOT/$f" ]; then
    echo "ERREUR: fichier cible introuvable: $f" >&2
    exit 2
  fi
  cur=$(awk 'END{print NR}' "$ROOT/$f")
  if [ "$cur" -gt "$VERTE" ]; then
    echo "ERREUR: $f a deja $cur ligne(s), superieur a la taille verte demandee ($VERTE)" >&2
    exit 2
  fi
done

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# run_at_size <N> -> imprime le chemin du fichier de sortie de la suite sur une copie fraîche de
# plugin/ dont les FILES ont été allongés à EXACTEMENT N lignes. rc non nul = allongement échoué.
run_at_size() {
  local n="$1"
  local tmp got f target grow
  tmp="$(mktemp -d)"
  if ! cp -R "$ROOT/plugin" "$tmp/plugin" 2>/dev/null; then
    echo "ERREUR: copie de plugin/ impossible" >&2
    rm -rf "$tmp"
    return 2
  fi
  for f in "${FILES[@]}"; do
    target="$tmp/$f"
    grow="$tmp/.grow.tmp"
    awk -v n="$n" '{print} END{for (i = NR + 1; i <= n; i++) print "ligne de remplissage neutre"}' "$target" > "$grow"
    mv "$grow" "$target"
    got=$(awk 'END{print NR}' "$target")
    if [ "$got" -ne "$n" ]; then
      echo "ERREUR: allongement de $f a echoue (obtenu $got, attendu $n)" >&2
      rm -rf "$tmp"
      return 2
    fi
  done
  local out="$WORKDIR/out_${n}.txt"
  bash "$tmp/$SUITE" > "$out" 2>&1
  rm -rf "$tmp"
  printf '%s' "$out"
}

VERTE_OUT="$(run_at_size "$VERTE")"
RC=$?
if [ "$RC" -ne 0 ] || [ -z "$VERTE_OUT" ]; then
  exit 2
fi

ROUGE_OUT="$(run_at_size "$ROUGE")"
RC=$?
if [ "$RC" -ne 0 ] || [ -z "$ROUGE_OUT" ]; then
  exit 2
fi

# label_present <fichier> <label> — recherche par index() sous LC_ALL=C (octets, UTF-8 inclus).
label_present() {
  awk -v lbl="$2" 'index($0, lbl) > 0 { f=1 } END { exit(f ? 0 : 1) }' "$1"
}

FAIL=0
for label_tmpl in "${LABELS[@]}"; do
  verte_label="${label_tmpl//%N/$VERTE}"
  if label_present "$VERTE_OUT" "$verte_label"; then
    echo "  assertion : absence du label a la taille verte ($VERTE)" >&2
    echo "    attendu   : absent" >&2
    echo "    obtenu    : present -> $verte_label" >&2
    FAIL=1
  fi

  rouge_label="${label_tmpl//%N/$ROUGE}"
  if ! label_present "$ROUGE_OUT" "$rouge_label"; then
    echo "  assertion : presence du label a la taille rouge ($ROUGE)" >&2
    echo "    attendu   : present -> $rouge_label" >&2
    echo "    obtenu    : absent" >&2
    FAIL=1
  fi
done

if [ "$FAIL" -eq 1 ]; then
  exit 1
fi
exit 0
