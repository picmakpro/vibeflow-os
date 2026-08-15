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
#   ./scaffold-docs.sh --index plugin/mon-module/references  # pose un _index.md de dossier
#
# Proportionnalité : ne PAS passer un compartiment par micro-dossier. Passer uniquement les
# compartiments qualifiés (même seuil d'autonomie que les .planning/ — cf. planning-core
# references/compartments.md). Sous le seuil → pas de docs/<projet>/, une ligne d'index suffit.
#
# Garde-fous : IDEMPOTENT — ne touche JAMAIS un fichier doc existant (création de stubs manquants).
#
# ---- Bornes et vocabulaire ----
#
# Quel « compartiment » : ce script sert le compartiment de DOCUMENTATION de sous-projet (ADR-042),
# PAS le compartiment de PLANNING à seuil d'autonomie décrit par
# plugin/planning-core/references/compartments.md — deux objets homonymes sans lien. La clause de
# proportionnalité ci-dessus emprunte quand même le SEUIL de ce dernier (même critère de
# qualification), sans en être le même objet.
#
# Les trois fichiers d'un compartiment de documentation, rôles disjoints : INDEX.md liste ce que le
# dossier contient · REFERENCE.md fait autorité sur le fond · CONTEXT.md route les tâches vers l'un
# ou l'autre et déclare ce qu'on ne charge pas.
#
# Les deux noms d'index, pourquoi ils ne fusionnent pas : INDEX.md est le tableau de bord d'un
# compartiment de documentation (posé toujours, ci-dessus) ; _index.md (préfixé d'un soulignement)
# est l'index de CONTENU d'un dossier de références qui franchit le seuil de plus de 10 fichiers
# (--index). Sémantiques différentes, portées différentes, jamais l'un renommé en l'autre.
#
# Borne de 80 lignes du CONTEXT.md : au-delà, le contrat de routage redevient le fichier de fond
# qu'ADR-042 a précisément externalisé — il route, il ne documente pas.
#
# Ce que ce script NE fait PAS : il ne réécrit ni ne supprime jamais un fichier existant, il ne
# vérifie pas la cohérence d'un _index.md avec son dossier (il pose, il ne juge pas), et il n'écrit
# jamais sous un chemin .planning/ (domaine du moteur amont, ADR-055).

set -euo pipefail

DOCS_DIR="docs"
INDEX_DIR=""
COMPARTMENTS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --docs-dir)   DOCS_DIR="$2"; shift 2 ;;
    --docs-dir=*) DOCS_DIR="${1#--docs-dir=}"; shift ;;
    --index)
      if [ "$#" -lt 2 ]; then
        echo "[scaffold-docs] --index nécessite une valeur" >&2
        exit 2
      fi
      INDEX_DIR="$2"; shift 2 ;;
    --index=*) INDEX_DIR="${1#--index=}"; shift ;;
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

# Corps de routage commun aux CONTEXT.md (table Tâche / Charge / NE charge PAS). Routage pur,
# jamais de contenu de fond (ADR-042) — c'est ce qui tient le fichier sous 80 lignes.
routing_table() {
  echo "| Tâche | Charge | NE charge PAS |"
  echo "|---|---|---|"
  echo "| [tâche à préciser] | [fichier ou dossier précis] | [fichier ou dossier précis] |"
  echo "| [tâche à préciser] | [fichier ou dossier précis] | [fichier ou dossier précis] |"
}

# ---- Doc transverse (toujours) ----
write_stub "$DOCS_DIR/_transverse/INDEX.md" \
  "# Documentation transverse" \
  "" \
  "> Doc commune à tout le lab. Le \`CLAUDE.md\` racine pointe ici via \`@$DOCS_DIR/_transverse/\`." \
  "" \
  "- [REFERENCE.md](REFERENCE.md) — source de vérité transverse (vocabulaire, conventions, stack)." \
  "- [CONTEXT.md](CONTEXT.md) — contrat de routage : quelle tâche charge quoi ici." \
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

write_stub "$DOCS_DIR/_transverse/CONTEXT.md" \
  "# Contrat de routage — transverse" \
  "" \
  "> Ce fichier route, il ne contient rien : le fond vit dans les fichiers pointés (ADR-042)." \
  "> Tenu en 80 lignes par contrat." \
  "" \
  "$(routing_table)" \
  "" \
  "Voir aussi : [INDEX.md](INDEX.md) liste ce que ce dossier contient · [REFERENCE.md](REFERENCE.md)" \
  "fait autorité sur le fond transverse · ce fichier route seulement."

# ---- Doc contextuelle par compartiment qualifié ----
for c in "${COMPARTMENTS[@]:-}"; do
  [ -n "$c" ] || continue
  write_stub "$DOCS_DIR/$c/INDEX.md" \
    "# Documentation — $c" \
    "" \
    "> Doc CONTEXTUELLE du sous-projet \`$c\`. Le \`CLAUDE.md\` racine y pointe via \`@$DOCS_DIR/$c/\`." \
    "" \
    "- [REFERENCE.md](REFERENCE.md) — source de vérité propre à $c." \
    "- [CONTEXT.md](CONTEXT.md) — contrat de routage : quelle tâche charge quoi ici." \
    "" \
    "Ajouter ici uniquement ce qui est spécifique à $c (les éléments transverses vont dans \`_transverse/\`)."
  write_stub "$DOCS_DIR/$c/REFERENCE.md" \
    "# REFERENCE — $c" \
    "" \
    "## Objectif du sous-projet" \
    "" \
    "## Spécificités (vs transverse)"
  write_stub "$DOCS_DIR/$c/CONTEXT.md" \
    "# Contrat de routage — $c" \
    "" \
    "> Ce fichier route, il ne contient rien : le fond vit dans les fichiers pointés (ADR-042)." \
    "> Tenu en 80 lignes par contrat." \
    "" \
    "$(routing_table)" \
    "" \
    "Voir aussi : [INDEX.md](INDEX.md) liste ce que ce dossier contient · [REFERENCE.md](REFERENCE.md)" \
    "fait autorité sur le fond de $c · ce fichier route seulement."
done

log "✓ doc externalisée sous $DOCS_DIR/ (transverse${COMPARTMENTS:+ + ${#COMPARTMENTS[@]} compartiment(s)})"

# ---- Index de dossier de références (--index <dossier>) ----
# Pattern distinct de INDEX.md ci-dessus : un tableau de bord de compartiment (l.51-57) n'est pas
# un index de contenu de dossier. Posé à la demande de l'appelant sur tout dossier de références
# qui franchit 10 fichiers markdown — sous le seuil, le geste reste possible mais explicite.
if [ -n "$INDEX_DIR" ]; then
  if [ ! -d "$INDEX_DIR" ]; then
    echo "[scaffold-docs] --index : dossier introuvable : $INDEX_DIR" >&2
    exit 2
  fi
  n_md="$(find "$INDEX_DIR" -maxdepth 1 -type f -name '*.md' ! -name '_index.md' | wc -l | tr -d ' ')"
  if [ "$n_md" -gt 10 ]; then
    log "seuil franchi ($n_md fichiers > 10) : _index.md justifié dans $INDEX_DIR"
  else
    log "seuil non franchi ($n_md fichiers, seuil > 10) : _index.md posé sur demande explicite dans $INDEX_DIR"
  fi
  write_stub "$INDEX_DIR/_index.md" \
    "# Index — $INDEX_DIR" \
    "" \
    "> Cet index existe pour qu'un agent choisisse un fichier sans les ouvrir tous. Il est posé à" \
    "> partir de plus de 10 fichiers dans un dossier de références. Il liste, il ne fait pas" \
    "> autorité." \
    "" \
    "| Fichier | Résumé |" \
    "|---|---|" \
    "| [nom-de-fichier.md] | [ce que ce fichier tranche] |" \
    "" \
    "Cet index doit rester cohérent avec le contenu du dossier."
fi
