#!/usr/bin/env bash
# seed-registres.sh — Instancie les registres mémoire canoniques depuis les gabarits du module.
#
# LE DÉFAUT QUE CE SCRIPT FERME (mesuré le 2026-08-15, lab vierge + vrai engine) : `consolidator`
# s'installait complètement — hooks de gouvernance câblés, guards en place, 5 gabarits déposés sous
# `skills/consolidator/references/templates-memoire/` — et pourtant `.claude/memory/` n'existait
# pas. AUCUN script n'allait chercher ces gabarits : ils étaient posés et jamais instanciés. Un lab
# frais échouait donc son propre gate (`check-registres.sh --strict` → rc=1, 5 registres canon
# manquants) et l'utilisateur constatait, à raison, que « rien ne se capitalise ». La CI ne le
# voyait pas : elle passe `--allow-empty`, qui convertit ce rc=1 en rc=3 « indéterminé », puis
# accepte rc=3. La machinerie tournait à vide sur un dossier inexistant.
#
# Usage:
#   seed-registres.sh                     # instancie les registres manquants · exit 0
#   seed-registres.sh --project           # cible le LAB COURANT (./.claude/memory), pas le scope
#   seed-registres.sh --check             # DRY-RUN : rapporte, n'écrit rien · exit 3 si manquants
#   seed-registres.sh --quiet             # silencieux sauf anomalie (mode hook post-install)
#   seed-registres.sh --memory-dir=PATH   # défaut <racine du script>/../memory
#   seed-registres.sh --templates-dir=PATH
#
# LE MODE --project ET POURQUOI IL EXISTE. En scope `user`, les scripts vivent dans `~/.claude/` et
# le défaut ci-dessus pose donc les registres dans `~/.claude/memory/` — la mémoire DU COMPTE. Mais
# `check-registres.sh` et les guards de lecture, eux, résolvent `.claude/memory` RELATIVEMENT AU
# CWD, c'est-à-dire dans le projet ouvert. Sans `--project`, l'installation en scope user produit
# donc une divergence franche : le seeder remplit le home pendant que le lint constate un projet
# vide, et chaque projet du poste se retrouve sans mémoire propre alors que VibeFlow est installé.
# `--project` cible le lab courant, ce qui rend la mémoire réellement per-projet en scope user.
#
# GARDE DU MODE --project — ne jamais semer `.claude/memory/` n'importe où. Le cwd n'est traité
# comme un lab que s'il porte déjà `.planning/` ou `.claude/`, c'est-à-dire s'il a été touché par
# VibeFlow. Un dépôt git quelconque ouvert au passage n'en fait PAS partie : sans cette garde, le
# hook de session déposerait 5 fichiers dans le premier dossier venu. Hors lab, le mode sort en 0
# sans rien écrire ni rien dire — c'est un non-événement, pas une anomalie.
#
# CONTRAT — NON DESTRUCTIF, SANS EXCEPTION. Un registre déjà présent n'est JAMAIS touché : ni
# écrasé, ni fusionné, ni réordonné. Les registres sont append-only et portent l'historique réel du
# lab ; les écraser depuis un gabarit détruirait précisément ce que ce module existe pour protéger.
# Le script ne sait que CRÉER CE QUI MANQUE. Il est donc idempotent par construction et sûr à
# rejouer à chaque install, update et resync de gouvernance — c'est ce qui le rend transparent pour
# l'utilisateur : la mémoire arrive sans geste, y compris sur un lab configuré avant cette version.
#
# DATA-DRIVEN, AUCUN NOM DE REGISTRE EN DUR (même doctrine que build-module-catalog.sh) : la liste
# sort des fichiers `*-template.md` réellement présents dans le dossier de gabarits. Ajouter un
# 6e registre au module suffit à le faire poser ; rien à modifier ici.
#
# RÉSOLUTION DU CHEMIN. Défaut = `<racine du script>/../memory`, ce qui donne `.claude/memory` en
# scope project/local et `~/.claude/memory` en scope user — les deux se terminent par la sous-chaîne
# `.claude/memory/` qu'exigent les guards de lecture, et le scope suit celui du reste de l'install
# (ID4 : un seul scope pour tout). C'est délibérément dérivé de la position du script, PAS du cwd :
# en scope user, un défaut basé sur le cwd sèmerait un `.claude/memory/` dans le dossier d'où
# l'utilisateur a lancé l'install, qui n'est pas forcément un lab.
#
# Codes de sortie : 0 = registres en place (créés ou déjà présents) · 3 = --check et il en manque
#                 · 1 = anomalie de configuration (dossier de gabarits introuvable)
#
# Ce script ne doit JAMAIS faire échouer une install (best-effort, doctrine des hooks post-install
# de l'engine) : l'appelant ignore son code retour, et toute anomalie part sur stderr pour atterrir
# dans le journal d'installation plutôt que d'être avalée en silence.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

MEMORY_DIR="${MEMORY_DIR:-}"
TEMPLATES_DIR="${TEMPLATES_DIR:-$SELF_DIR/../skills/consolidator/references/templates-memoire}"
CHECK_ONLY=false
QUIET=false
PROJECT_MODE=false

for arg in "$@"; do
  case "$arg" in
    --project)         PROJECT_MODE=true ;;
    --check)           CHECK_ONLY=true ;;
    --quiet)           QUIET=true ;;
    --memory-dir=*)    MEMORY_DIR="${arg#*=}" ;;
    --templates-dir=*) TEMPLATES_DIR="${arg#*=}" ;;
    -h|--help)         grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[seed-registres] arg inconnu : $arg" >&2; exit 1 ;;
  esac
done

log()  { [ "$QUIET" = true ] || echo "[seed-registres] $*" >&2; }
warn() { echo "[seed-registres] $*" >&2; }   # traverse --quiet : une anomalie doit être vue

# Échappatoire globale : un utilisateur qui ne veut PAS que la mémoire se pose toute seule à
# l'ouverture d'une session la coupe d'une variable, sans désinstaller le module ni éditer un hook.
if [ "$PROJECT_MODE" = true ] && [ -n "${VF_NO_AUTO_SEED:-}" ]; then
  log "VF_NO_AUTO_SEED posé — instanciation automatique désactivée."
  exit 0
fi

# Résolution de la cible. `--memory-dir` explicite prime toujours (c'est ce que les tests utilisent).
if [ -z "$MEMORY_DIR" ]; then
  if [ "$PROJECT_MODE" = true ]; then
    # Garde de lab : sans elle, ce mode déposerait 5 fichiers dans n'importe quel dossier ouvert.
    # `.planning/` ou `.claude/` = ce projet a déjà été touché par VibeFlow. Un simple dépôt git ne
    # suffit délibérément PAS : la mémoire d'un lab arrive quand le dossier devient un lab.
    if [ ! -d ".planning" ] && [ ! -d ".claude" ]; then
      log "cwd sans .planning/ ni .claude/ — pas un lab VibeFlow, rien à instancier."
      exit 0
    fi
    MEMORY_DIR="./.claude/memory"
  else
    MEMORY_DIR="$SELF_DIR/../memory"
  fi
fi

if [ ! -d "$TEMPLATES_DIR" ]; then
  warn "gabarits introuvables ($TEMPLATES_DIR) — aucun registre instancié."
  warn "  le module consolidator est-il bien installé ? (skills/consolidator/references/templates-memoire/)"
  exit 1
fi

# Inventaire des gabarits : `<nom>-template.md` → registre canon `<NOM>.md`.
# `tr` plutôt que l'expansion `${v^^}` : celle-ci est un bashisme 4.0+, absent du bash 3.2 de macOS.
templates=()
for t in "$TEMPLATES_DIR"/*-template.md; do
  [ -f "$t" ] || continue
  templates+=("$t")
done

if [ "${#templates[@]}" -eq 0 ]; then
  warn "aucun gabarit *-template.md dans $TEMPLATES_DIR — aucun registre instancié."
  exit 1
fi

created=0
existing=0
missing=0
failed=0

for t in "${templates[@]}"; do
  base="$(basename "$t")"
  base="${base%-template.md}"
  target="$MEMORY_DIR/$(printf '%s' "$base" | tr '[:lower:]' '[:upper:]').md"

  if [ -f "$target" ]; then
    existing=$((existing + 1))
    continue
  fi

  if [ "$CHECK_ONLY" = true ]; then
    missing=$((missing + 1))
    log "manquant : $target"
    continue
  fi

  # mkdir tardif : en --check on ne crée rien du tout, pas même le dossier.
  if ! mkdir -p "$MEMORY_DIR" 2>/dev/null; then
    warn "impossible de créer $MEMORY_DIR — registres non instanciés."
    exit 1
  fi

  # `cp` sans -f et re-test d'existence : ceinture contre une course entre deux installs
  # concurrentes (deux sessions sur le même lab). Le perdant ne doit pas écraser le gagnant.
  if [ -f "$target" ]; then
    existing=$((existing + 1))
    continue
  fi

  if cp "$t" "$target" 2>/dev/null; then
    created=$((created + 1))
    log "registre créé : $target"
  else
    failed=$((failed + 1))
    warn "échec de création : $target"
  fi
done

if [ "$CHECK_ONLY" = true ]; then
  if [ "$missing" -gt 0 ]; then
    warn "$missing registre(s) canon manquant(s) dans $MEMORY_DIR (sur $((missing + existing)))."
    warn "  correctif : bash \"$0\""
    exit 3
  fi
  log "les $existing registres canon sont en place ($MEMORY_DIR)."
  exit 0
fi

if [ "$failed" -gt 0 ]; then
  warn "$failed registre(s) non créé(s) — mémoire partiellement instanciée, voir ci-dessus."
  exit 1
fi

if [ "$created" -gt 0 ]; then
  log "$created registre(s) instancié(s), $existing déjà en place → $MEMORY_DIR"
else
  log "registres déjà en place ($existing) — rien à faire."
fi
exit 0
