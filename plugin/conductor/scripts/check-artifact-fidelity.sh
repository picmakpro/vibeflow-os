#!/usr/bin/env bash
# check-artifact-fidelity.sh — Que perd RÉELLEMENT une install multi-runtime, mesuré par
# exécution réelle de la conversion gsd-core (jamais une table recopiée à la main, Phase 38
# FIDE-01).
#
# Rôle : prend UN artefact VibeFlow source (frontmatter Claude Code) et UNE cible runtime,
# invoque la VRAIE fonction de conversion de gsd-core (convertClaudeAgentToCodexAgent pour
# --target codex, seule cible tier-1 mesurée au 2026-08-28), et rend un verdict PAR CHAMP
# (name/description/model/memory/disallowedTools/vf-internal/tools) : PRESERVED, DEGRADED ou
# LOST. Ne modifie jamais rien — gate en lecture seule.
#
# Deux champs de RECETTE (jamais un détail enfoui, toujours en tête, `--target codex`
# uniquement) : `multi_agent_v2` (sans lui aucun outil de spawn n'existe sur Codex — un lab
# VibeFlow «marche» sans le moindre sous-agent, en silence) et `trust_level` du dépôt cible
# (sans `trusted`, `.codex/agents/` n'est jamais parsé — zéro rôle VibeFlow chargé, en silence,
# alors que `codex doctor` continue de rendre `overall: ok`).
#
# Usage:
#   check-artifact-fidelity.sh [--target codex] [--json] <artefact.md>
#   check-artifact-fidelity.sh -h|--help
#
# Exit codes:
#   0 = la mesure a pu s'exécuter (MÊME si des champs sont LOST, ou multi_agent_v2/trust_level
#       défavorables — une perte déclarée n'est pas un échec du gate, c'est son objet).
#   2 = erreur d'usage (argument inconnu, artefact manquant en argument).
#   3 = INDÉTERMINÉ — gsd-core introuvable sur ce poste, artefact source introuvable sur disque,
#       ou cible inconnue (non mesurée sur ce poste). stdout VIDE dans les trois cas — jamais un
#       rapport « rien perdu » qui mentirait par absence de mesure.
set -uo pipefail

TARGET="codex"
JSON_MODE=0
ARTIFACT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --json)
      JSON_MODE=1
      shift
      ;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    -*)
      echo "[check-artifact-fidelity] argument inconnu : $1" >&2
      exit 2
      ;;
    *)
      if [ -n "$ARTIFACT" ]; then
        echo "[check-artifact-fidelity] argument inconnu (artefact déjà fourni) : $1" >&2
        exit 2
      fi
      ARTIFACT="$1"
      shift
      ;;
  esac
done

if [ -z "$ARTIFACT" ]; then
  echo "[check-artifact-fidelity] usage : check-artifact-fidelity.sh [--target codex] [--json] <artefact.md>" >&2
  exit 2
fi

if [ "$TARGET" != "codex" ]; then
  echo "[check-artifact-fidelity] cible '$TARGET' : non mesuré sur ce poste (seule --target codex est mesurée au 2026-08-28)"
  exit 3
fi

if [ ! -f "$ARTIFACT" ]; then
  echo "[check-artifact-fidelity] artefact source introuvable : $ARTIFACT" >&2
  exit 3
fi

# --- Cascade de dérivation du home gsd-core (duplication DÉLIBÉRÉE de
# check-gsd-engine.sh:default_gsd_home_new(), motivée par le même D-01 : ce gate doit rester
# testable en boîte noire sans sourcer un script à effets de bord). ---
default_gsd_home() {
  local root claude_home
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if [ -d "$root/.claude/gsd-core" ]; then
    echo "$root/.claude/gsd-core"
  else
    echo "$claude_home/gsd-core"
  fi
}
GSD_HOME="$(default_gsd_home)"
CONVERSION_LIB="$GSD_HOME/bin/lib/runtime-artifact-conversion.cjs"

if [ ! -f "$GSD_HOME/VERSION" ] || [ ! -f "$CONVERSION_LIB" ]; then
  echo "[check-artifact-fidelity] gsd-core introuvable sous '$GSD_HOME' — impossible de mesurer la conversion" >&2
  exit 3
fi

TMPDIR_GATE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_GATE"' EXIT

# --- Extraction de frontmatter (bash pur, indépendante de gsd-core : le DIFF reste auditable
# sans dépendre de la boîte noire qu'il mesure). ---
extract_frontmatter() {
  # Lignes strictement entre le 1er et le 2e délimiteur '---'.
  awk '/^---[[:space:]]*$/{c++; next} c==1' "$1"
}
extract_body() {
  # Tout ce qui suit le 2e délimiteur '---'.
  awk '/^---[[:space:]]*$/{c++; next} c>=2' "$1"
}
get_field() {
  # $1 = bloc frontmatter (variable, pas fichier), $2 = clé.
  printf '%s\n' "$1" | grep -E "^${2}:" | head -1 | sed -E "s/^${2}:[[:space:]]*//"
}

SRC_FM="$(extract_frontmatter "$ARTIFACT")"
SRC_BODY="$(extract_body "$ARTIFACT")"

FIELDS="name description model memory disallowedTools vf-internal tools"
for f in $FIELDS; do
  var="SRC_$(echo "$f" | tr '[:lower:]-' '[:upper:]_')"
  eval "$var=\"\$(get_field \"\$SRC_FM\" \"$f\")\""
done

# --- Conversion RÉELLE : invoque la seule source de vérité (jamais une table recopiée). ---
CONVERTED_FILE="$TMPDIR_GATE/converted.md"
NODE_ERR="$TMPDIR_GATE/node-err.log"
node -e '
const fs = require("fs");
const path = require("path");
const gsdHome = process.argv[1];
const srcFile = process.argv[2];
const outFile = process.argv[3];
const lib = require(path.join(gsdHome, "bin/lib/runtime-artifact-conversion.cjs"));
const content = fs.readFileSync(srcFile, "utf8");
const converted = lib.convertClaudeAgentToCodexAgent(content);
fs.writeFileSync(outFile, converted);
' "$GSD_HOME" "$ARTIFACT" "$CONVERTED_FILE" 2>"$NODE_ERR"
NODE_RC=$?
if [ "$NODE_RC" -ne 0 ]; then
  echo "[check-artifact-fidelity] échec de la conversion gsd-core réelle (node exit $NODE_RC) : $(cat "$NODE_ERR")" >&2
  exit 3
fi

CONV_FM="$(extract_frontmatter "$CONVERTED_FILE")"
CONV_BODY="$(extract_body "$CONVERTED_FILE")"

for f in name description model memory disallowedTools vf-internal; do
  var="CONV_$(echo "$f" | tr '[:lower:]-' '[:upper:]_')"
  eval "$var=\"\$(get_field \"\$CONV_FM\" \"$f\")\""
done

PRESERVED=""
DEGRADED=""
LOST=""

add_verdict() {
  # $1 = liste (nom de variable), $2 = champ
  case "$1" in
    PRESERVED) PRESERVED="${PRESERVED:+$PRESERVED,}$2" ;;
    DEGRADED)  DEGRADED="${DEGRADED:+$DEGRADED,}$2" ;;
    LOST)      LOST="${LOST:+$LOST,}$2" ;;
  esac
}

# name / description : présents des deux côtés -> PRESERVED.
if [ -n "$SRC_NAME" ]; then
  if [ -n "$CONV_NAME" ]; then add_verdict PRESERVED name; else add_verdict LOST name; fi
fi
if [ -n "$SRC_DESCRIPTION" ]; then
  if [ -n "$CONV_DESCRIPTION" ]; then add_verdict PRESERVED description; else add_verdict LOST description; fi
fi

# model / memory / disallowedTools / vf-internal : présents source, absents converti -> LOST.
if [ -n "$SRC_MODEL" ]; then
  if [ -n "$CONV_MODEL" ]; then add_verdict PRESERVED model; else add_verdict LOST model; fi
fi
if [ -n "$SRC_MEMORY" ]; then
  if [ -n "$CONV_MEMORY" ]; then add_verdict PRESERVED memory; else add_verdict LOST memory; fi
fi
if [ -n "$SRC_DISALLOWEDTOOLS" ]; then
  if [ -n "$CONV_DISALLOWEDTOOLS" ]; then add_verdict PRESERVED disallowedTools; else add_verdict LOST disallowedTools; fi
fi
if [ -n "$SRC_VF_INTERNAL" ]; then
  if [ -n "$CONV_VF_INTERNAL" ]; then add_verdict PRESERVED vf-internal; else add_verdict LOST vf-internal; fi
fi

# tools : traité à part — cherché en PROSE dans le corps <codex_agent_role> de la sortie
# convertie, jamais dans le frontmatter (le convertisseur l'embarque en prose non-enforçable).
if [ -n "$SRC_TOOLS" ]; then
  if printf '%s' "$CONV_BODY" | grep -qF -- "$SRC_TOOLS"; then
    add_verdict DEGRADED tools
  else
    add_verdict LOST tools
  fi
fi

# --- Marqueurs morts : comptés sur le CORPS (hors frontmatter) des deux versions. ---
count_markers() {
  local body="$1"
  local n_claude n_task
  n_claude=$(printf '%s' "$body" | grep -c '\.claude/' || true)
  n_task=$(printf '%s' "$body" | grep -c 'Task(' || true)
  echo $((n_claude + n_task))
}
SRC_MARKERS=$(count_markers "$SRC_BODY")
CONV_MARKERS=$(count_markers "$CONV_BODY")
if [ "$SRC_MARKERS" -eq "$CONV_MARKERS" ]; then
  DEAD_MARKERS_LABEL="$CONV_MARKERS (non réécrits)"
else
  DEAD_MARKERS_LABEL="$CONV_MARKERS (source=$SRC_MARKERS, réécriture partielle mesurée)"
fi

# --- Recette d'environnement Codex : deux mesures INDÉPENDANTES de la conversion d'artefact. ---
MULTI_AGENT_V2="non mesurable (CLI codex introuvable)"
if command -v codex >/dev/null 2>&1; then
  FEATURES_LINE=$(codex features list 2>/dev/null | grep -E '^multi_agent_v2[[:space:]]' | head -1)
  if [ -n "$FEATURES_LINE" ]; then
    MULTI_AGENT_V2=$(printf '%s\n' "$FEATURES_LINE" | awk '{print $NF}')
  else
    MULTI_AGENT_V2="non mesurable (flag multi_agent_v2 absent de 'codex features list')"
  fi
fi

TRUST_LEVEL="absent (non trusted)"
# Résolution de racine ALIGNÉE avec plugin/_internal/runtime-cli-dispatch.sh
# (ensure_codex_preconditions, repo_root) : même absence de repli sur `pwd` hors dépôt git — un
# repli divergent ferait sonder aux deux gardes deux racines différentes pour le même fait
# (revue de jointure Phase 38, join-1). Si l'autre fichier change sa résolution, réplique ici.
TARGET_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$TARGET_ROOT" ]; then
  TRUST_LEVEL="non mesurable (racine du dépôt cible introuvable)"
else
  CODEX_CONFIG="${CODEX_HOME:-$HOME/.codex}/config.toml"
  if [ -f "$CODEX_CONFIG" ]; then
    # Bloc [projects."<racine>"] portant trust_level = "trusted" — lecture seule.
    if awk -v root="$TARGET_ROOT" '
      BEGIN { in_block = 0 }
      /^\[projects\./ {
        in_block = ($0 == "[projects.\"" root "\"]")
        next
      }
      /^\[/ { in_block = 0 }
      in_block && /trust_level[[:space:]]*=[[:space:]]*"trusted"/ { found = 1 }
      END { exit found ? 0 : 1 }
    ' "$CODEX_CONFIG"; then
      TRUST_LEVEL="trusted"
    fi
  fi
fi

if [ "$JSON_MODE" -eq 0 ]; then
  echo "[fidelity-recette] multi_agent_v2=${MULTI_AGENT_V2} trust_level=${TRUST_LEVEL}"
fi

if [ "$JSON_MODE" -eq 1 ]; then
  JSON_ARGS_FILE="$TMPDIR_GATE/json-args.json"
  node -e '
const fs = require("fs");
const [artifact, target, preserved, degraded, lost, deadMarkers, multiAgentV2, trustLevel] = process.argv.slice(1);
const splitCsv = (s) => (s ? s.split(",") : []);
const out = {
  artifact,
  target,
  preserved: splitCsv(preserved),
  degraded: splitCsv(degraded),
  lost: splitCsv(lost),
  dead_markers: deadMarkers,
  multi_agent_v2: multiAgentV2,
  trust_level: trustLevel,
};
process.stdout.write(JSON.stringify(out));
' "$ARTIFACT" "$TARGET" "$PRESERVED" "$DEGRADED" "$LOST" "$DEAD_MARKERS_LABEL" "$MULTI_AGENT_V2" "$TRUST_LEVEL"
  echo
else
  echo "[fidelity] $ARTIFACT -> $TARGET: PRESERVED={$PRESERVED} DEGRADED={$DEGRADED} LOST={$LOST} DEAD_MARKERS=$DEAD_MARKERS_LABEL"
fi

exit 0
