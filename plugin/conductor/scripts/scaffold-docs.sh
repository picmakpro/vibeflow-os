#!/usr/bin/env bash
# scaffold-docs.sh — Externalise la documentation du lab et la rend CONTEXTUELLE par compartiment.
#
# Doctrine (ADR-042) : l'init du CLAUDE.md déclenche l'externalisation de la doc. La doc ne vit
# JAMAIS inlinée dans le CLAUDE.md ; elle vit sous docs/ et le CLAUDE.md y POINTE via @docs/...
#   - docs/_transverse/   → doc transverse au lab (REFERENCE, conventions, glossaire…)
#   - docs/<projet>/       → doc CONTEXTUELLE d'un sous-projet (compartiment qualifié)
#
# Le CLAUDE.md racine mappe chaque compartiment → @docs/<projet>/ (fait par l'appelant, prose).
#
# Usage:
#   ./scaffold-docs.sh                       # squelette transverse seul (lab mono-projet)
#   ./scaffold-docs.sh projet-a projet-b     # + un docs/<projet>/ par compartiment QUALIFIÉ
#   ./scaffold-docs.sh --docs-dir docs projet-a
#
# Proportionnalité : ne PAS passer un compartiment par micro-dossier. Passer uniquement les
# compartiments qualifiés (même seuil d'autonomie que les .planning/ — cf. planning-core
# references/compartments.md). Sous le seuil → pas de docs/<projet>/, une ligne d'index suffit.
#
# Garde-fous : IDEMPOTENT — ne touche JAMAIS un fichier doc existant (création de stubs manquants).

set -euo pipefail

DOCS_DIR="docs"
COMPARTMENTS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --docs-dir)   DOCS_DIR="$2"; shift 2 ;;
    --docs-dir=*) DOCS_DIR="${1#--docs-dir=}"; shift ;;
    -*) echo "[scaffold-docs] argument inconnu : $1" >&2; exit 2 ;;
    *) COMPARTMENTS+=("$1"); shift ;;
  esac
done

log() { echo "[scaffold-docs] $*" >&2; }

# Écrit un fichier stub seulement s'il n'existe pas (idempotent).
write_stub() {
  local path="$1"; shift
  if [ -f "$path" ]; then
    log "conservé (existant) : $path"
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$@" > "$path"
  log "créé : $path"
}

# ---- Doc transverse (toujours) ----
write_stub "$DOCS_DIR/_transverse/INDEX.md" \
  "# Documentation transverse" \
  "" \
  "> Doc commune à tout le lab. Le \`CLAUDE.md\` racine pointe ici via \`@$DOCS_DIR/_transverse/\`." \
  "" \
  "- [REFERENCE.md](REFERENCE.md) — source de vérité transverse (vocabulaire, conventions, stack)." \
  "- Ajouter ici les docs qui concernent l'ensemble des sous-projets."

write_stub "$DOCS_DIR/_transverse/REFERENCE.md" \
  "# REFERENCE — Source de vérité transverse" \
  "" \
  "> Externalisée du CLAUDE.md (ADR-042). Le CLAUDE.md y pointe, ne la duplique pas." \
  "" \
  "## Vocabulaire" \
  "" \
  "## Conventions" \
  "" \
  "## Stack / contraintes communes"

# ---- Doc contextuelle par compartiment qualifié ----
for c in "${COMPARTMENTS[@]:-}"; do
  [ -n "$c" ] || continue
  write_stub "$DOCS_DIR/$c/INDEX.md" \
    "# Documentation — $c" \
    "" \
    "> Doc CONTEXTUELLE du sous-projet \`$c\`. Le \`CLAUDE.md\` racine y pointe via \`@$DOCS_DIR/$c/\`." \
    "" \
    "- [REFERENCE.md](REFERENCE.md) — source de vérité propre à $c." \
    "" \
    "Ajouter ici uniquement ce qui est spécifique à $c (les éléments transverses vont dans \`_transverse/\`)."
  write_stub "$DOCS_DIR/$c/REFERENCE.md" \
    "# REFERENCE — $c" \
    "" \
    "## Objectif du sous-projet" \
    "" \
    "## Spécificités (vs transverse)"
done

log "✓ doc externalisée sous $DOCS_DIR/ (transverse${COMPARTMENTS:+ + ${#COMPARTMENTS[@]} compartiment(s)})"
