#!/usr/bin/env bash
# register-codex-agent.sh — Orchestration de pose (et retrait) d'un rôle Codex depuis un agent
# VibeFlow (Phase 38, lot 5, ADPT-01/ADPT-04 ; --remove ajouté en 38-07, CODEX-B5).
#
# Usage:
#   register-codex-agent.sh <agent.md> [--codex-home <chemin>] [--verify]
#   register-codex-agent.sh <agent.md> [--codex-home <chemin>] --remove
#
# Résout CODEX_HOME (--codex-home sinon ${CODEX_HOME:-$HOME/.codex}), appelle le convertisseur
# pur agent-to-codex.mjs, écrit le .toml résultant sous $CODEX_HOME/agents/vibeflow/<name>.toml
# (SEULE surface d'écriture — jamais [agents.<n>] de config.toml, doctrine mesurée
# 38-CONTEXT.md lignes 359-373 : aucune commande `codex config` n'existe, une écriture dans
# config.toml ne pourrait être défaite que par édition TOML, avec risque de mutiler des tables
# voisines). Écriture idempotente : un rôle déjà posé est ÉCRASÉ, jamais dupliqué.
#
# --verify : après écriture, appelle `codex doctor --json` sur CE CODEX_HOME et COMPTE les
# rôles chargés (ADPT-04). Le gate est ce comptage — jamais "pas de crash donc c'est bon"
# (piège n°1 mesuré : un rôle malformé est ignoré en silence par Codex, simple startup warning
# invisible en usage normal). Sort non-zéro si le rôle posé n'apparaît pas dans le compte, ou si
# `codex` est introuvable dans le PATH (message explicite, jamais un succès supposé).
#
# --remove : retrait symétrique, idempotent, SANS dépendance à node (le retrait ne doit jamais
# dépendre d'un binaire dont l'absence ne devrait pourtant jamais bloquer un uninstall).
# Incompatible avec --verify (rejeté avec un message d'usage explicite). Dérive AGENT_NAME
# exactement comme la pose (même ligne sed), `rm -f` le .toml s'il existe, sinon no-op — jamais
# fatal, jamais de création de $AGENTS_DIR s'il est absent (rien à retirer d'un répertoire qui
# n'a jamais existé). Doctrine "atomique, sans parsing" (38-CONTEXT.md:363), appliquée par rôle
# plutôt qu'en `rm -rf` global du répertoire — un uninstall_module() d'un SEUL module ne doit
# jamais supprimer les rôles d'un AUTRE module encore installé en coexistence.
#
# Imprime le digest (une ligne par champ, LOST/PENDING/PRESERVED/PRESERVED_BY_OMISSION/ABSENT)
# sur stdout, TEL QUEL — jamais résumé.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONVERTER="$SCRIPT_DIR/agent-to-codex.mjs"

usage() {
  echo "usage: register-codex-agent.sh <agent.md> [--codex-home <chemin>] [--verify]" >&2
  echo "       register-codex-agent.sh <agent.md> [--codex-home <chemin>] --remove" >&2
}

AGENT_MD=""
CODEX_HOME_ARG=""
DO_VERIFY=0
DO_REMOVE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --codex-home)
      CODEX_HOME_ARG="${2:-}"
      shift 2
      ;;
    --verify)
      DO_VERIFY=1
      shift
      ;;
    --remove)
      DO_REMOVE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "[register-codex-agent] argument inconnu : $1" >&2
      usage
      exit 2
      ;;
    *)
      if [ -n "$AGENT_MD" ]; then
        echo "[register-codex-agent] argument inconnu (agent déjà fourni) : $1" >&2
        exit 2
      fi
      AGENT_MD="$1"
      shift
      ;;
  esac
done

if [ -z "$AGENT_MD" ]; then
  usage
  exit 2
fi
if [ ! -f "$AGENT_MD" ]; then
  echo "[register-codex-agent] agent introuvable : $AGENT_MD" >&2
  exit 2
fi
if [ "$DO_REMOVE" -eq 1 ] && [ "$DO_VERIFY" -eq 1 ]; then
  echo "[register-codex-agent] --remove et --verify sont incompatibles (rien à vérifier sur un rôle qu'on vient de retirer)" >&2
  usage
  exit 2
fi

RESOLVED_CODEX_HOME="${CODEX_HOME_ARG:-${CODEX_HOME:-$HOME/.codex}}"
AGENTS_DIR="$RESOLVED_CODEX_HOME/agents/vibeflow"

# Nom du rôle : dérivé du frontmatter `name`, pas du nom de fichier (le convertisseur lui-même
# ne l'expose pas côté CLI — on le relit ici, une ligne, cohérent avec la doctrine "name ne
# vient pas du nom de fichier"). Dérivation partagée à l'identique par la pose ET le retrait —
# UNIQUE source de vérité pour ce calcul (jamais dupliquée dans vibeflow-update.sh).
AGENT_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$AGENT_MD" | head -1 | tr -d '[:space:]')"
if [ -z "$AGENT_NAME" ]; then
  echo "[register-codex-agent] impossible de dériver le nom du rôle depuis $AGENT_MD (champ 'name' absent du frontmatter)" >&2
  exit 1
fi

# Validation de charset AU POINT D'USAGE, avant toute construction de chemin dérivé de
# AGENT_NAME (écriture à la pose, suppression au --remove). Même règle que le gate ADR-044
# (plugin/conductor/scripts/check-agents.sh:510 : re.fullmatch(r"[a-z0-9-]+", name)) — ce gate
# ne protège que les agents DE CE DÉPÔT en CI, jamais un module tiers ni un lab modifié après
# coup, et vibeflow-update.sh ne l'invoque jamais. Un name hors charset (traversée de chemin,
# absolu, vide après nettoyage, slash, majuscules, espaces internes, point initial...) est un
# REFUS bruyant — jamais une normalisation "best effort", jamais un repli silencieux.
case "$AGENT_NAME" in
  *[!a-z0-9-]*|"")
    echo "[register-codex-agent] name invalide ('$AGENT_NAME') dans $AGENT_MD — seuls [a-z0-9-]+ sont acceptés (même règle que check-agents.sh ADR-044) ; refus, aucune normalisation" >&2
    exit 1
    ;;
esac

ROLE_TOML="$AGENTS_DIR/${AGENT_NAME}.toml"

if [ "$DO_REMOVE" -eq 1 ]; then
  if [ -f "$ROLE_TOML" ]; then
    rm -f "$ROLE_TOML"
    echo "[register-codex-agent] rôle retiré : $ROLE_TOML"
  else
    echo "[register-codex-agent] rôle déjà absent (rien à retirer) : $ROLE_TOML"
  fi
  exit 0
fi

if ! command -v node >/dev/null 2>&1; then
  echo "[register-codex-agent] node introuvable dans le PATH — pose impossible" >&2
  exit 3
fi

mkdir -p "$AGENTS_DIR"

DIGEST_OUTPUT="$(node "$CONVERTER" "$AGENT_MD" --out "$ROLE_TOML" 2>&1 1>/dev/null)"
CONVERT_STATUS=$?
if [ "$CONVERT_STATUS" -ne 0 ]; then
  echo "[register-codex-agent] échec de conversion pour $AGENT_MD :" >&2
  echo "$DIGEST_OUTPUT" >&2
  exit 1
fi

echo "[register-codex-agent] rôle posé : $ROLE_TOML"
echo "$DIGEST_OUTPUT"

if [ "$DO_VERIFY" -eq 1 ]; then
  if ! command -v codex >/dev/null 2>&1; then
    echo "[register-codex-agent] codex introuvable dans le PATH — vérification ADPT-04 impossible, pose déclarée NON VÉRIFIÉE (jamais un succès supposé)" >&2
    exit 3
  fi
  # MESURÉ (Codex 0.150.1, sur ce poste) : 'codex doctor --json' n'ÉNUMÈRE PAS les rôles
  # chargés avec succès — aucune clé ne liste les agents valides par nom. La SEULE trace
  # observable est un "startup warning" ("Ignoring malformed agent role definition: agent role
  # file at <chemin> must define ...") qui apparaît UNIQUEMENT quand un rôle est malformé, et
  # qui référence le CHEMIN du fichier fautif verbatim. Un `codex doctor --json` global exit=0
  # NE PROUVE RIEN (mesuré : exit 0 y compris avec un rôle cassé présent, seul overallStatus
  # passe à "warning") — piège n°1 exactement décrit par 38-CONTEXT.md.
  # → Le gate ADPT-04 est donc une vérification par ABSENCE : le chemin du rôle qu'on vient de
  # poser NE DOIT PAS apparaître référencé dans un "startup warning" de cette sortie. C'est une
  # mesure positive du comportement observable du binaire (pas "pas de crash donc c'est bon") ;
  # une absence de warning référençant CE fichier précis est le seul signal que Codex expose.
  DOCTOR_JSON="$(CODEX_HOME="$RESOLVED_CODEX_HOME" codex doctor --json 2>/dev/null)"
  if [ -z "$DOCTOR_JSON" ] || ! printf '%s' "$DOCTOR_JSON" | head -c1 | grep -q '{'; then
    echo "[register-codex-agent] 'codex doctor --json' n'a rendu aucun JSON exploitable sur CODEX_HOME=$RESOLVED_CODEX_HOME — vérification ADPT-04 impossible" >&2
    exit 1
  fi
  # MESURÉ (Codex 0.150.1, revue Phase 38 ADPT-04) : un SECOND cas de "startup warning" existe,
  # sur une famille de malformation DIFFÉRENTE de celle ci-dessus — une COLLISION DE NOM entre
  # deux rôles ("Ignoring malformed agent role definition: duplicate agent role name `<name>`
  # discovered in <AGENTS_DIR>"). Ce warning ne référence JAMAIS le chemin du .toml (ni le
  # fautif, ni celui qu'on vient de poser) — seulement AGENT_NAME et le RÉPERTOIRE PARENT
  # $CODEX_HOME/agents. Un check limité à `grep -F "$ROLE_TOML"` (le cas malformé ci-dessus) ne
  # voit donc RIEN passer : reproductible en réel, le rôle qu'on vient de poser peut être celui
  # que Codex ignore silencieusement, et ADPT-04 se déclarerait quand même "vérifié".
  WARNING_LINES="$(printf '%s' "$DOCTOR_JSON" | grep -i 'startup warning')"
  DUPLICATE_PATTERN="duplicate agent role name \`${AGENT_NAME}\`"
  if printf '%s' "$WARNING_LINES" | grep -qF "$ROLE_TOML"; then
    echo "[register-codex-agent] ADPT-04 ÉCHEC : '$ROLE_TOML' apparaît dans un 'startup warning' de 'codex doctor --json' — rôle malformé, IGNORÉ en silence par Codex (piège n°1)" >&2
    printf '%s\n' "$WARNING_LINES" | grep -F "$ROLE_TOML" >&2
    exit 1
  fi
  if printf '%s' "$WARNING_LINES" | grep -qF "$DUPLICATE_PATTERN"; then
    echo "[register-codex-agent] ADPT-04 ÉCHEC : collision de nom — un 'startup warning' de 'codex doctor --json' signale '$DUPLICATE_PATTERN' (rôle IGNORÉ en silence par Codex ; ce warning ne cite jamais '\$ROLE_TOML', seulement le nom et \$CODEX_HOME/agents — un check limité au chemin ne l'aurait pas vu)" >&2
    printf '%s\n' "$WARNING_LINES" | grep -F "$DUPLICATE_PATTERN" >&2
    exit 1
  fi
  echo "[register-codex-agent] ADPT-04 vérifié : aucun 'startup warning' de 'codex doctor --json' ne référence '$ROLE_TOML' ni une collision de nom sur '$AGENT_NAME' (CODEX_HOME=$RESOLVED_CODEX_HOME) — vérification par ABSENCE sur les deux familles de malformation mesurées, seul signal exposé par le binaire (il n'énumère jamais les rôles valides par nom)"
fi

exit 0
