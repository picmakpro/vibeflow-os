#!/usr/bin/env bash
# check-overlaps.sh — Inventaire des recouvrements de déclenchement avec les briques TIERCES (ADR-057).
# Ce qui passait silencieusement : des briques VibeFlow/GSD en concurrence de routage avec des
# briques tierces présentes en session (superpowers, feature-dev, natif Claude Code) — 3 objets
# nommés « skill-creator », debug/review/brainstorm en doublon — sans qu'aucune frontière machine
# ne dise qui est canon pour quoi. VibeFlow ne peut pas dé-publier une brique tierce : il documente
# la frontière et la rend détectable (méthode ADR-055 : script + doctrine courte, pas de prose de
# préséance).
#
# Référentiel : ADR-057 (frontières avec les briques tierces — détection outillée) ·
# audit 2026-07-25 §C et G.17.
#
# Usage:
#   check-overlaps.sh                        # advisory : inventorie les paires connues présentes · exit 0 toujours
#   check-overlaps.sh --strict               # exit 1 si un recouvrement SANS frontière documentée est détecté
#                                            # (heuristique : 2 briques locales sur une même racine debug/review/skill-creat)
#   check-overlaps.sh --skills-dir=PATH      # défaut ./.claude/skills
#   check-overlaps.sh --agents-dir=PATH      # défaut ./.claude/agents
#   check-overlaps.sh --user-skills-dir=PATH # défaut ~/.claude/skills
#   check-overlaps.sh --plugins-dir=PATH     # défaut ~/.claude/plugins/cache (briques tierces installées)
#   check-overlaps.sh --allow-empty          # avec --strict : tolère une cible locale vide (sinon exit 3)
#
# ADVISORY (défaut) : pour chaque paire CONNUE dont les DEUX côtés sont présents dans le lab,
#   affiche la frontière canonique. Les recouvrements hors table sont signalés en ⚠.
# BLOQUANT (--strict) : un recouvrement hors table = erreur (la paire doit entrer dans la table
#   avec sa frontière, ou les déclencheurs doivent être disjoints).
#
# Codes de sortie : 0 = inventaire rendu (advisory, ou rien à inventorier) · 1 = --strict et
#   recouvrement sans frontière documentée · 3 = INDÉTERMINÉ (--strict sur cible locale
#   absente/vide : aucune brique découverte, aucun verdict — F13).

set -uo pipefail

SKILLS_DIR=".claude/skills"
AGENTS_DIR=".claude/agents"
USER_SKILLS_DIR="$HOME/.claude/skills"
PLUGINS_DIR="$HOME/.claude/plugins/cache"
STRICT=false
ALLOW_EMPTY=false

for arg in "$@"; do
  case "$arg" in
    --strict)              STRICT=true ;;
    --allow-empty)         ALLOW_EMPTY=true ;;
    --skills-dir=*)        SKILLS_DIR="${arg#*=}" ;;
    --agents-dir=*)        AGENTS_DIR="${arg#*=}" ;;
    --user-skills-dir=*)   USER_SKILLS_DIR="${arg#*=}" ;;
    --plugins-dir=*)       PLUGINS_DIR="${arg#*=}" ;;
    -h|--help)             grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  esac
done

# ── Table des recouvrements CONNUS (ADR-057) ─────────────────────────────────────────────────
# Format : brique VibeFlow/GSD | brique tierce | frontière canonique (une ligne, sans '|').
# Préfixes côté tierce : `plugin:skill` = skill d'un plugin tiers (cherché dans --plugins-dir) ;
# `native:x` = brique native Claude Code (toujours présente) ; sans préfixe = skill/agent local.
KNOWN_PAIRS=$(cat <<'EOF'
gsd-debug|superpowers:systematic-debugging|systematic-debugging = méthode de debug dans la session courante ; gsd-debug = état de debug persistant cross-session (canon dès que le debug survit à un reset de contexte)
gsd-code-review|feature-dev:code-reviewer|gsd-code-review = canon dans un projet GSD ; feature-dev:code-reviewer = revue générique hors chaîne GSD
gsd-code-review|native:code-review|gsd-code-review = canon dans un projet GSD ; /code-review natif = revue ponctuelle du diff courant hors chaîne GSD
gsd-code-review|superpowers:requesting-code-review|gsd-code-review = canon dans un projet GSD ; requesting-code-review = protocole de revue superpowers hors chaîne GSD
skill-creator|superpowers:writing-skills|module skill-creator = fabrication de capacités de LAB avec eval-loop (recherche par facettes → draft → éval) ; writing-skills = doctrine d'écriture de skills — coexistence, aucune exclusivité
mobile-test|gsd-verify-work|mobile-test = preuve sur cible mobile réelle (simulateur/émulateur, Maestro) ; gsd-verify-work = recette conversationnelle d'une feature ; boucle autonome test+fix = équipe mobile-test-team
gsd-explore|superpowers:brainstorming|brainstorming = concevoir une idée avant d'implémenter ; gsd-explore = exploration socratique et routage d'idée
consolidator|gsd-mempalace-capture|consolidator = canon mémoire de lab (in-repo, machine-enforced, ADR-052) ; mempalace = opt-in, exige MemPalace, mémorise des artefacts de phase GSD via le loop-bus interne — non activé, non répliqué
consolidator|gsd-mempalace-recall|consolidator = canon mémoire de lab (in-repo, machine-enforced, ADR-052) ; mempalace = opt-in, exige MemPalace, mémorise des artefacts de phase GSD via le loop-bus interne — non activé, non répliqué
vibeflow-dev|gsd-next|vibeflow-dev = front door unique du lab (agent routeur) ; gsd-next = front door de GSD pour qui n'a pas d'agent routeur — ne jamais router gsd-next (empilerait deux routeurs, ADR-057)
EOF
)

# Présence d'une brique dans le lab, selon son préfixe.
present() {
  ref="$1"
  case "$ref" in
    native:*) return 0 ;;  # brique native Claude Code — toujours présente en session
    *:*)
      plug="${ref%%:*}"; sk="${ref#*:}"
      [ -d "$PLUGINS_DIR" ] || return 1
      hit="$(find "$PLUGINS_DIR" -maxdepth 6 -type d \
               \( -path "*/$plug/*/skills/$sk" -o -path "*/$plug/skills/$sk" \) \
               -print 2>/dev/null | head -1)"
      [ -n "$hit" ]
      ;;
    *)
      [ -f "$SKILLS_DIR/$ref/SKILL.md" ] && return 0
      [ -f "$USER_SKILLS_DIR/$ref/SKILL.md" ] && return 0
      [ -f "$AGENTS_DIR/$ref.md" ] && return 0
      return 1
      ;;
  esac
}

# Une paire (n1, n2) est « connue » si une ligne de la table porte exactement ces deux noms
# (préfixe plugin retiré pour la comparaison).
pair_known() {
  p1="$1"; p2="$2"
  while IFS='|' read -r a b _; do
    [ -n "$a" ] || continue
    as="${a##*:}"; bs="${b##*:}"
    if { [ "$p1" = "$as" ] && [ "$p2" = "$bs" ]; } || { [ "$p1" = "$bs" ] && [ "$p2" = "$as" ]; }; then
      return 0
    fi
  done <<EOF
$KNOWN_PAIRS
EOF
  return 1
}

# ── Inventaire des briques LOCALES (skills projet + skills user + agents) ────────────────────
local_names=""
for d in "$SKILLS_DIR" "$USER_SKILLS_DIR"; do
  [ -d "$d" ] || continue
  for f in "$d"/*/SKILL.md; do
    [ -f "$f" ] || continue
    local_names="$local_names $(basename "$(dirname "$f")")"
  done
done
if [ -d "$AGENTS_DIR" ]; then
  for f in "$AGENTS_DIR"/*.md; do
    [ -f "$f" ] || continue
    b="$(basename "$f" .md)"
    case "$b" in README|AGENTS|contracts) continue ;; esac
    local_names="$local_names $b"
  done
fi

if [ -z "${local_names// /}" ]; then
  # Contrat de découverte (F13, vacuous green) : en --strict, zéro brique = zéro verdict.
  if $STRICT && ! $ALLOW_EMPTY; then
    echo "[check-overlaps] ✗ INDÉTERMINÉ : aucune brique locale dans $SKILLS_DIR/$AGENTS_DIR — cible absente ou vide, aucun verdict rendu (--allow-empty pour tolérer)"
    exit 3
  fi
  echo "[check-overlaps] aucune brique locale dans $SKILLS_DIR/$AGENTS_DIR — rien à inventorier"
  exit 0
fi

# ── 1. Paires connues dont les deux côtés sont présents → afficher la frontière ──────────────
found=0
while IFS='|' read -r a b frontier; do
  [ -n "$a" ] || continue
  if present "$a" && present "$b"; then
    [ "$found" -eq 0 ] && echo "[check-overlaps] recouvrements connus présents dans le lab (ADR-057) :"
    found=$((found+1))
    echo "  ↔ $a ↔ $b"
    echo "      frontière : $frontier"
  fi
done <<EOF
$KNOWN_PAIRS
EOF

# ── 2. Heuristique des recouvrements NON documentés (racines à haut risque de collision) ─────
# Exclusions : les verbes vf-* (couche de routage VibeFlow, frontière portée par intent-routing.md),
# les paires où un nom contient l'autre (compagnons d'un même module, ex. skill-creator /
# skill-creator-workflow), et les paires INTRA-famille (même préfixe, ex. gsd-review ↔
# gsd-ui-review : combinatoire interne d'un même framework, hors périmètre tierces ADR-057).
unknown=0
uniq_names="$(printf '%s\n' $local_names | grep -v '^vf-' | sort -u)"
for root in debug review skill-creat; do
  matches="$(printf '%s\n' "$uniq_names" | grep -i -- "$root" || true)"
  n="$(printf '%s\n' "$matches" | grep -c . || true)"
  [ "$n" -ge 2 ] || continue
  for n1 in $matches; do
    for n2 in $matches; do
      [ "$n1" \< "$n2" ] || continue
      case "$n1" in *"$n2"*) continue ;; esac
      case "$n2" in *"$n1"*) continue ;; esac
      [ "${n1%%-*}" = "${n2%%-*}" ] && continue  # même famille (préfixe commun)
      if ! pair_known "$n1" "$n2"; then
        echo "  ⚠ recouvrement NON documenté (racine « $root ») : $n1 ↔ $n2 — aucune frontière dans la table ADR-057"
        unknown=$((unknown+1))
      fi
    done
  done
done

# ── Verdict ──────────────────────────────────────────────────────────────────────────────────
if [ "$unknown" -gt 0 ]; then
  if $STRICT; then
    echo "[check-overlaps] ✗ $unknown recouvrement(s) sans frontière documentée (ADR-057) — ajouter la paire à la table avec sa frontière, ou disjoindre les déclencheurs"
    exit 1
  fi
  echo "[check-overlaps] ⚠ $unknown recouvrement(s) sans frontière documentée — advisory, voir ADR-057"
fi
if [ "$found" -gt 0 ]; then
  echo "[check-overlaps] ✓ $found frontière(s) active(s) inventoriée(s) — advisory, aucun blocage"
else
  echo "[check-overlaps] ✓ aucun recouvrement connu présent des deux côtés — rien à signaler"
fi
exit 0
