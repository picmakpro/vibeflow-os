#!/usr/bin/env bash
# check-blueprints.sh — Lint de la conformité des BLUEPRINTS d'agents à leur propre gate (ADR-044).
#
# Ce qui passait silencieusement : un blueprint publie un « frontmatter cible » que `vf-new-lab`
# recopie tel quel dans l'agent instancié — mais ce frontmatter n'est jamais soumis à
# `check-agents.sh`. La fabrique et son contrôleur peuvent donc diverger sans que rien ne le voie.
# Mesuré le 2026-09-22 : les 9 blueprints du dépôt omettaient tous `effort`, bloquant depuis la
# Phase 24, et un lab fabriqué depuis l'un d'eux voyait son Write REFUSÉ par guard-agent-write.sh.
#
# Le gate ne juge pas le blueprint : il matérialise son frontmatter cible en agent jetable et le
# soumet au gate qui s'appliquera vraiment. Un seul référentiel, donc aucune seconde vérité à tenir.
#
# Usage:
#   check-blueprints.sh                        # audit plugin/*/content/agents/*.blueprint.md
#   check-blueprints.sh --strict               # propage --strict au gate sous-jacent
#   check-blueprints.sh --hook                 # SessionStart : compact, exit 0 toujours
#   check-blueprints.sh --file <x.blueprint.md>  # un seul blueprint
#   check-blueprints.sh --blueprints-dir=PATH  # racine de recherche, défaut : racine du dépôt
#   check-blueprints.sh --allow-empty          # tolère une cible vide (sinon exit 3)
#
# BLOQUANT : tout ce que `check-agents.sh` juge bloquant sur le frontmatter matérialisé, plus
#   l'absence de bloc ```yaml``` dans un blueprint (un blueprint sans frontmatter cible ne dit pas
#   quoi instancier — c'est un défaut, pas une exemption).
# NON BLOQUANT : les warnings du gate sous-jacent, dont « skill déclaré introuvable » — les skills
#   d'un blueprint sont créés dans le lab au moment de l'instanciation, pas présents ici. C'est
#   pourquoi --strict n'est PAS le mode par défaut : il exigerait que les skills du lab existent
#   dans le plugin, ce qui est faux par construction.
#
# Codes de sortie : 0 = conforme · 1 = non conforme ou invocation invalide · 3 = INDÉTERMINÉ
#   (aucun blueprint trouvé sans --allow-empty, ou gate sous-jacent introuvable). Jamais un vert
#   sur une cible vide : un gate qui passe quand il n'a rien mesuré n'est pas un gate.
#
# Limite honnête : ce gate valide le frontmatter cible, pas le corps de l'agent instancié ni la
# fidélité du blueprint à l'agent livré équivalent. Il ferme la classe « la fabrique produit ce que
# le contrôleur refuse », pas « le blueprint décrit bien son agent ».

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/check-agents.sh"

STRICT=0
HOOK=0
ALLOW_EMPTY=0
ONE_FILE=""
ROOT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1 ;;
    --hook) HOOK=1 ;;
    --allow-empty) ALLOW_EMPTY=1 ;;
    --file) shift; ONE_FILE="${1:-}" ;;
    --file=*) ONE_FILE="${1#*=}" ;;
    --blueprints-dir=*) ROOT="${1#*=}" ;;
    *) echo "check-blueprints.sh : argument inconnu « $1 »" >&2; exit 1 ;;
  esac
  shift
done

# hook_exit : sous --hook, aucun code ne remonte au harnais (SessionStart ne peut pas bloquer —
# docs/HOOKS-CONTRAT-SORTIE.md). L'impression, elle, a déjà eu lieu : un silence de code n'est pas
# un silence de message.
hook_exit() { [ "$HOOK" -eq 1 ] && exit 0; exit "$1"; }

if [ ! -f "$GATE" ]; then
  echo "✗ check-agents.sh introuvable ($GATE) — conformité NON VÉRIFIABLE" >&2
  hook_exit 3
fi

if [ -z "$ROOT" ]; then
  ROOT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
fi

# Collecte des blueprints
BPS=()
if [ -n "$ONE_FILE" ]; then
  [ -f "$ONE_FILE" ] || { echo "✗ blueprint introuvable : $ONE_FILE" >&2; hook_exit 1; }
  BPS+=("$ONE_FILE")
else
  while IFS= read -r f; do [ -n "$f" ] && BPS+=("$f"); done < <(
    find "$ROOT" -type f -name '*.blueprint.md' -not -path '*/node_modules/*' 2>/dev/null | sort
  )
fi

if [ "${#BPS[@]}" -eq 0 ]; then
  if [ "$ALLOW_EMPTY" -eq 1 ]; then
    echo "· aucun blueprint (cible vide tolérée)"
    hook_exit 0
  fi
  echo "✗ aucun blueprint trouvé sous $ROOT — INDÉTERMINÉ (utilise --allow-empty si c'est voulu)" >&2
  hook_exit 3
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

KO=0
OK=0
NOYAML=0

for bp in "${BPS[@]}"; do
  rel="${bp#"$ROOT"/}"

  # Extraction du premier bloc ```yaml du blueprint = le frontmatter cible.
  yaml="$(awk '/^```yaml[[:space:]]*$/{y=1;next} y&&/^```/{exit} y{print}' "$bp")"

  if [ -z "$yaml" ]; then
    echo "✗ $rel : aucun bloc \`\`\`yaml — le blueprint ne dit pas quoi instancier"
    NOYAML=$((NOYAML+1)); KO=$((KO+1))
    continue
  fi

  # Le nom de fichier de l'agent doit valoir son `name` (le gate le vérifie).
  nom="$(printf '%s\n' "$yaml" | sed -n 's/^name:[[:space:]]*//p' | head -1 | tr -d '\r')"
  [ -n "$nom" ] || nom="$(basename "$bp" .blueprint.md)"

  # Matérialisation : le frontmatter cible, plus un corps minimal. check-agents.sh ne mesure pas
  # le corps (c'est check-instruction-budget.sh qui le fait) — un corps non vide suffit.
  agent="$TMP/$nom.md"
  {
    printf -- '---\n'
    printf '%s\n' "$yaml" | sed -e 's/^---$//' -e '/^[[:space:]]*$/d'
    printf -- '---\n\n'
    printf 'Corps matérialisé par check-blueprints.sh pour le contrôle du frontmatter cible.\n'
  } > "$agent"

  args=(--file "$agent")
  [ "$STRICT" -eq 1 ] && args+=(--strict)

  if out="$(bash "$GATE" "${args[@]}" 2>&1)"; then
    OK=$((OK+1))
  else
    KO=$((KO+1))
    echo "✗ $rel"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi
done

echo
if [ "$KO" -gt 0 ]; then
  echo "✗ $KO blueprint(s) sur ${#BPS[@]} produisent un agent que check-agents.sh REFUSE."
  [ "$NOYAML" -gt 0 ] && echo "  dont $NOYAML sans bloc \`\`\`yaml."
  echo "  Un lab fabriqué depuis l'un d'eux verra son Write refusé par guard-agent-write.sh."
  hook_exit 1
fi

echo "✓ ${#BPS[@]} blueprint(s) : frontmatter cible conforme à check-agents.sh"
hook_exit 0
