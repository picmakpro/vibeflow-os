#!/usr/bin/env bash
# discover-unintegrated-docs.sh — Quels cadrages écrits ne sont pas encore intégrés à la feuille
#                                  de route ? (BRDG-02)
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit PAS si un document est
# un ADR, une SPEC, un PRD ou un DOC — ça reste du jugement porté par l'agent (vibeflow-dev, plan
# 13-02). Il dit seulement : « ce document existe sous docs/superpowers/{specs,plans}/, et aucun
# registre ne le cite » — et à quel GRAIN il appartient (spec | plan).
#
# Usage:
#   discover-unintegrated-docs.sh [--path <dir>] [--hook] [--quiet]
# Defaults: --path .
#
# --hook (plan 17-02, additif) : change UNIQUEMENT le format d'affichage — au lieu de la liste
# grain<TAB>chemin, émet une ligne agrégée [docs-ingest] (compte total + ventilation spec/plan)
# suivie de sa ligne de geste, dans les MÊMES conditions d'exit (0/3/64) que le mode par défaut.
# Le contrat historique grain<TAB>chemin, consommé par ingestion-flow.md, reste le seul mode actif
# sans --hook — il ne bouge pas d'un octet. --hook et --quiet sont mutuellement exclusifs (exit 64).
#
# Sources scannées (grain) :
#   <sources>/specs/*.md  → grain spec
#   <sources>/plans/*.md  → grain plan
#
# Registres de citation consultés :
#   <planning>/ROADMAP.md, <planning>/REQUIREMENTS.md, <planning>/MILESTONES.md,
#   <planning>/PROJECT.md, <planning>/milestones/*.md, <adr>
#   <planning>/phases/** est EXCLU : ce sont des sorties du moteur, pas des entrées.
#
# Règle de citation : un document est « intégré » si son basename (extension .md incluse), borné
# des DEUX côtés (début/fin de ligne ou caractère hors [0-9A-Za-z._-]), apparaît dans une ligne
# d'un registre. Jamais de match sur le stem, jamais par préfixe de dossier, jamais sur un
# basename plus long se terminant par le sien (ex. redesign.md ne cite pas design.md). Une ligne
# de registre contenant un glob (ex. docs/superpowers/specs/*.md) est ignorée comme source de
# citation.
#
# Env (surcharge — testabilité, modèle VF_GSD_SKILLS_DIR de build-gsd-index.sh) :
#   VF_INGEST_SOURCES_DIR   (défaut <path>/docs/superpowers) — racine contenant specs/ et plans/
#   VF_INGEST_PLANNING_DIR  (défaut <path>/.planning)        — racine des registres GSD
#   VF_INGEST_ADR_FILE      (défaut <path>/docs/ADR.md)      — registre hors chaîne GSD
#
# Sortie : une ligne par document non intégré, "grain<TAB>chemin" (chemin relatif à --path),
# triée. Rien d'autre — pas de prose, pas d'en-tête.
#
# Exit codes :
#   0  = au moins un document non intégré (listé sur stdout)
#   3  = rien à intégrer (corpus vide, corpus entièrement cité, ou .planning/ absent)
#   64 = argument inconnu
set -uo pipefail
shopt -s nullglob

ROOT="."
QUIET=0
HOOK=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[discover-unintegrated-docs] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    --hook) HOOK=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[discover-unintegrated-docs] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique (même position que le gate --path).
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[discover-unintegrated-docs] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

SOURCES_ROOT="${VF_INGEST_SOURCES_DIR:-$ROOT/docs/superpowers}"
PLANNING_DIR="${VF_INGEST_PLANNING_DIR:-$ROOT/.planning}"
ADR_FILE="${VF_INGEST_ADR_FILE:-$ROOT/docs/ADR.md}"
SPECS_DIR="$SOURCES_ROOT/specs"
PLANS_DIR="$SOURCES_ROOT/plans"

say() { [ "$QUIET" -eq 1 ] || echo "[discover-unintegrated-docs] $*" >&2; }

# --- .planning/ absent : pas de moteur de planning, rien à évaluer contre ---
if [ ! -d "$PLANNING_DIR" ]; then
  say "$PLANNING_DIR absent — aucun registre à consulter."
  exit 3
fi

# --- Collecte des documents source (grain, chemin relatif à --path) ---
DOCS_TMP="$(mktemp)" || { echo "[discover-unintegrated-docs] mktemp a échoué" >&2; exit 64; }
REG_TMP="$(mktemp)" || { echo "[discover-unintegrated-docs] mktemp a échoué" >&2; rm -f "$DOCS_TMP"; exit 64; }
OUT_TMP="$(mktemp)" || { echo "[discover-unintegrated-docs] mktemp a échoué" >&2; rm -f "$DOCS_TMP" "$REG_TMP"; exit 64; }
trap 'rm -f "$DOCS_TMP" "$REG_TMP" "$OUT_TMP"' EXIT

for f in "$SPECS_DIR"/*.md; do printf 'spec\t%s\n' "$f" >> "$DOCS_TMP"; done
for f in "$PLANS_DIR"/*.md; do printf 'plan\t%s\n' "$f" >> "$DOCS_TMP"; done

if [ ! -s "$DOCS_TMP" ]; then
  say "Aucun document source sous $SPECS_DIR ou $PLANS_DIR."
  exit 3
fi

# --- Concaténation des registres existants (les lignes glob sont filtrées au moment du match) ---
for r in "$PLANNING_DIR/ROADMAP.md" "$PLANNING_DIR/REQUIREMENTS.md" "$PLANNING_DIR/MILESTONES.md" \
         "$PLANNING_DIR/PROJECT.md" "$PLANNING_DIR/milestones"/*.md "$ADR_FILE"; do
  [ -f "$r" ] && cat "$r" >> "$REG_TMP"
done

# Un document est cité si son basename, borné des DEUX côtés (par le début/fin de ligne ou un
# caractère hors [0-9A-Za-z._-]), apparaît dans une ligne NON glob d'un registre. Padding d'un
# espace en début ET en fin de ligne : évite l'ancrage ^/$ à l'intérieur d'une alternative ERE
# (portabilité awk POSIX), les bornes sont alors toujours "caractère hors [0-9A-Za-z._-]".
# Tous les métacaractères ERE actifs du basename sont échappés caractère par caractère (pas de
# gsub global sur une classe : piège à écrire correctement en awk POSIX portable).
is_cited() { # <basename>
  awk -v base="$1" '
    BEGIN {
      special = "\\.[]()*+?{}|^$"
      esc = ""
      n = length(base)
      for (i = 1; i <= n; i++) {
        c = substr(base, i, 1)
        if (index(special, c) > 0) esc = esc "\\" c
        else esc = esc c
      }
      pat = "[^0-9A-Za-z._-]" esc "[^0-9A-Za-z._-]"
    }
    index($0, "/*") > 0 { next }
    { line = " " $0 " "; if (line ~ pat) { found = 1; exit } }
    END { exit (found ? 0 : 1) }
  ' "$REG_TMP"
}

while IFS="$(printf '\t')" read -r grain path; do
  [ -z "$grain" ] && continue
  base="$(basename "$path")"
  if is_cited "$base"; then
    continue
  fi
  rel="$path"
  case "$rel" in
    "$ROOT"/*) rel="${rel#"$ROOT"/}" ;;
  esac
  printf '%s\t%s\n' "$grain" "$rel" >> "$OUT_TMP"
done < "$DOCS_TMP"

if [ ! -s "$OUT_TMP" ]; then
  say "Corpus entièrement cité — rien à intégrer."
  exit 3
fi

# --- Mode --hook (additif) : une ligne agrégée au lieu de la liste, mêmes exits (D-06) -----------
# Compte total + ventilation par grain en une seule passe awk POSIX. Le calcul amont ($OUT_TMP) et
# les trois exits ne sont pas modifiés — cette branche ne fait que remplacer le rendu.
if [ "$HOOK" -eq 1 ]; then
  IFS="$(printf '\t')" read -r TOTAL NSPEC NPLAN <<HOOKEOF
$(awk -F'\t' '{c[$1]++; n++} END{printf "%d\t%d\t%d\n", n, c["spec"]+0, c["plan"]+0}' "$OUT_TMP")
HOOKEOF
  printf '%s\n' "[docs-ingest] ${TOTAL} documents de cadrage hors feuille de route (${NSPEC} spec, ${NPLAN} plan)."
  printf '%s\n' "            → propose l'ingestion (gsd-ingest-docs --mode merge / gsd-import), jamais sans confirmation."
  exit 0
fi

[ "$QUIET" -eq 1 ] && exit 0

LC_ALL=C sort "$OUT_TMP"
exit 0
