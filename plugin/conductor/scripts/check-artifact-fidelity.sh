#!/usr/bin/env bash
# check-artifact-fidelity.sh — Que perd RÉELLEMENT une install multi-runtime, mesuré par
# exécution réelle de la conversion qui écrit l'artefact SUR DISQUE (Phase 38, FIDE-01 ; corrigé
# en correction ciblée post-mesure-codex, cf. CHANGELOG conductor).
#
# Rôle : prend UN artefact VibeFlow source (frontmatter Claude Code) et UNE cible runtime,
# invoque la conversion qui produit RÉELLEMENT l'artefact posé par une install (`--target codex`
# -> agent-to-codex.mjs, la MÊME fonction que register-codex-agent.sh utilise pour écrire le
# TOML sous $CODEX_HOME/agents/vibeflow/*.toml — jamais une conversion parallèle qui n'atterrit
# jamais sur disque), et rend un verdict PAR CHAMP (name/description/model/memory/
# disallowedTools/vf-internal/tools) : PRESERVED, DEGRADED ou LOST. Ne modifie jamais rien — gate
# en lecture seule (mktemp -d pour la conversion, jamais une écriture sous $CODEX_HOME).
#
# ⚠️ Historique du défaut corrigé ici : avant cette version, ce gate invoquait la fonction de
# conversion de gsd-core (`convertClaudeAgentToCodexAgent`), qui rend un Markdown QUI N'EST
# JAMAIS ÉCRIT PAR AUCUNE INSTALL — deux mesures divergeaient donc sous la MÊME étiquette
# [fidelity] (ex. `model` LOST côté gsd-core / PRESERVED côté TOML réel), sans qu'aucun opérateur
# lisant le log d'install ne puisse savoir laquelle décrivait l'artefact réellement sur son
# disque. La mesure gsd-core reste disponible en MODE DE REPLI UNIQUEMENT (adaptateur Codex
# introuvable sur ce poste — cf. find_codex_adapter ci-dessous), et la ligne rendue porte alors
# `MODE=gsdcore-fallback`, JAMAIS confondue avec `MODE=adapter` (mesure de l'artefact réel).
#
# Ligne de recette (jamais un détail enfoui, toujours en tête, `--target codex` uniquement) :
# `multi_agent_v2` (sans lui aucun outil de spawn n'existe sur Codex — un lab VibeFlow «marche»
# sans le moindre sous-agent, en silence), `trust_level` du dépôt cible (sans `trusted`,
# `.codex/agents/` n'est jamais parsé — zéro rôle VibeFlow chargé, en silence, alors que
# `codex doctor` continue de rendre `overall: ok`), et `role_confinement` (FIDE-03, D-38-O) : sur
# Codex, `sandbox_mode`/`approval_policy`/`[permissions]` déclarés PAR RÔLE sont acceptés puis
# INERTES — mesuré en session réelle (un rôle `read-only` a réellement écrit sur disque). Le
# confinement d'un juge (`vf-reviewer`/`vf-auditer`/`vf-design-judge`) n'est garanti QUE par une
# session `codex exec -s read-only` séparée, jamais par le fichier de rôle. Ce troisième fait est
# une CONSTANTE déclarée pour `--target codex` (pas une mesure par exécution, comme les deux
# premiers) — c'est un comportement documenté du binaire, pas un état du poste.
#
# Usage:
#   check-artifact-fidelity.sh [--target codex] [--json] <artefact.md>
#   check-artifact-fidelity.sh --check-judge-command <fichier>
#   check-artifact-fidelity.sh -h|--help
#
# --check-judge-command <fichier> : vérifie que le fichier contient LA COMMANDE de session
#   read-only séparée posée par le lot 5 (FIDE-03, D-38-O), avec ses QUATRE éléments requis
#   (ET, jamais OU — omettre `skills.include_instructions=false` laisse ouvert le canal
#   AGENTS.md du dépôt jugé, ADPT-05) :
#     1. `-s read-only`
#     2. `approval_policy` = never
#     3. `skills.include_instructions=false`
#     4. `project_doc_max_bytes=0`
#   Exit 0 si les quatre sont présents, 1 s'il en manque au moins un (ROUGE — jamais un OU),
#   3 si le fichier n'existe pas (le lot 5 n'a pas encore posé la commande — INDÉTERMINÉ,
#   JAMAIS un vert : contrat F13 appliqué à ce gate lui-même).
#
# Exit codes:
#   0 = la mesure a pu s'exécuter (MÊME si des champs sont LOST, ou multi_agent_v2/trust_level
#       défavorables — une perte déclarée n'est pas un échec du gate, c'est son objet). Avec
#       --check-judge-command : les quatre éléments sont présents.
#   1 = --check-judge-command uniquement : au moins un des quatre éléments manque.
#   2 = erreur d'usage (argument inconnu, artefact manquant en argument).
#   3 = INDÉTERMINÉ — ni l'adaptateur Codex (agent-to-codex.mjs) ni gsd-core (mode de repli) ne
#       sont disponibles sur ce poste, artefact source introuvable sur disque, cible inconnue
#       (non mesurée sur ce poste), ou (--check-judge-command) commande de juge pas encore posée
#       sur disque. stdout VIDE dans ces cas — jamais un rapport qui mentirait par absence de
#       mesure.
set -uo pipefail

TARGET="codex"
JSON_MODE=0
ARTIFACT=""
JUDGE_CMD_FILE=""
COEXISTENCE_MODE=0
COEXISTENCE_CONFIG=".planning/config.json"

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
    --check-judge-command)
      JUDGE_CMD_FILE="${2:-}"
      shift 2
      ;;
    --coexistence-report)
      COEXISTENCE_MODE=1
      shift
      ;;
    --config)
      COEXISTENCE_CONFIG="${2:-}"
      shift 2
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

# --- Mode --check-judge-command : vérifie les 4 éléments de la commande de session read-only
# séparée (FIDE-03). Mode INDÉPENDANT de l'artefact — pas besoin d'ARTIFACT ni de gsd-core.
if [ -n "$JUDGE_CMD_FILE" ]; then
  if [ -n "$ARTIFACT" ]; then
    echo "[check-artifact-fidelity] --check-judge-command et un artefact ne se combinent pas (deux mesures distinctes)" >&2
    exit 2
  fi
  if [ "$TARGET" != "codex" ]; then
    echo "[check-artifact-fidelity] cible '$TARGET' : --check-judge-command n'est mesuré que pour codex" >&2
    exit 3
  fi
  if [ ! -f "$JUDGE_CMD_FILE" ]; then
    echo "[check-artifact-fidelity] commande de juge introuvable : $JUDGE_CMD_FILE (lot 5 — pose des rôles Codex, FIDE-03/D-38-O — pas encore livré sur ce poste)" >&2
    exit 3
  fi
  # Scope à jamais la mesure au BLOC DE COMMANDE (premier fence ```bash … ```), JAMAIS au
  # fichier entier. Défaut mesuré (revue Phase 38, FIDE-03) : le fichier répète chaque flag en
  # PROSE sous le bloc (ex. titre, liste explicative « 1. `-s read-only` — … ») — muter
  # UNIQUEMENT la ligne de commande réelle en laissant cette prose intacte laissait l'ancien
  # gate (aplatissement `tr` du fichier entier) à COMPLET, les 4 fois, sur les 4 mutations.
  # La commande qu'un opérateur copie-colle est CE bloc, jamais le texte autour — c'est donc lui,
  # et lui seul, que ce gate doit vérifier.
  CMD_BLOCK="$(awk '
    found_done { next }
    /^```bash[[:space:]]*$/ { c=1; next }
    /^```[[:space:]]*$/ { if (c == 1) { c = 0; found_done = 1 }; next }
    c { print }
  ' "$JUDGE_CMD_FILE" | tr '\n' ' ')"
  if [ -z "$CMD_BLOCK" ]; then
    echo "[check-artifact-fidelity] aucun bloc de commande (\`\`\`bash ... \`\`\`) dans $JUDGE_CMD_FILE — impossible de mesurer la commande réelle (jamais un repli sur la prose)" >&2
    exit 3
  fi
  MISSING=""
  printf '%s' "$CMD_BLOCK" | grep -qE -- '-s[[:space:]]+read-only' \
    || MISSING="${MISSING:+$MISSING,}sandbox_mode(-s read-only)"
  printf '%s' "$CMD_BLOCK" | grep -qE 'approval_policy[^,]*never' \
    || MISSING="${MISSING:+$MISSING,}approval_policy=never"
  printf '%s' "$CMD_BLOCK" | grep -qF 'skills.include_instructions=false' \
    || MISSING="${MISSING:+$MISSING,}skills.include_instructions=false"
  printf '%s' "$CMD_BLOCK" | grep -qF 'project_doc_max_bytes=0' \
    || MISSING="${MISSING:+$MISSING,}project_doc_max_bytes=0"

  if [ -z "$MISSING" ]; then
    echo "[fidelity-judge-command] $JUDGE_CMD_FILE -> $TARGET: COMPLET (les 4 éléments présents : sandbox_mode, approval_policy=never, skills.include_instructions=false, project_doc_max_bytes=0)"
    exit 0
  else
    echo "[fidelity-judge-command] $JUDGE_CMD_FILE -> $TARGET: INCOMPLET — manque={$MISSING} (ET requis, pas OU — ADPT-05)"
    exit 1
  fi
fi

# --- Mode --coexistence-report (MIGR-05, Phase 38) : mode GLOBAL, pas par-fichier — déclare, pour
# CHAQUE runtime installé AUTRE que `claude`, qu'il opère SANS gouvernance de hooks (aucun
# mécanisme équivalent mesuré à ce jour). `installed` réduit à ["claude"] seul (ou registre
# absent/vide) -> silence total, rien à déclarer. Exit 0 dans tous les cas où la lecture a pu
# s'exécuter — une coexistence sans hooks n'est pas un échec du gate, c'est son objet (même
# doctrine que le reste de ce gate).
if [ "$COEXISTENCE_MODE" -eq 1 ]; then
  if [ -n "$ARTIFACT" ]; then
    echo "[check-artifact-fidelity] --coexistence-report et un artefact ne se combinent pas (deux mesures distinctes)" >&2
    exit 2
  fi
  # Même dossier que ce gate (conductor/scripts/) aux DEUX positions posées (TARGET_ROOT/scripts/
  # ou CACHE_DIR/conductor/scripts/, cf. find_fidelity_gate côté vibeflow-update.sh) — jamais une
  # 2e résolution divergente de runtime-registry.sh (lot 6, tâche 1, MIGR-01), toujours co-posé.
  COEX_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  REGISTRY_SCRIPT="$COEX_SCRIPT_DIR/runtime-registry.sh"
  if [ ! -f "$REGISTRY_SCRIPT" ] || [ ! -f "$COEXISTENCE_CONFIG" ]; then
    # Registre ou config absents -> rien à mesurer, silence total (best-effort, jamais un échec).
    exit 0
  fi
  INSTALLED_RUNTIMES="$(bash "$REGISTRY_SCRIPT" list-installed --config "$COEXISTENCE_CONFIG" 2>/dev/null)" || exit 0
  for _rt in $INSTALLED_RUNTIMES; do
    [ "$_rt" = "claude" ] && continue
    echo "[fidelity-coexistence] $_rt : opère SANS gouvernance de hooks (aucun mécanisme équivalent mesuré à ce jour — cf. 38-CONTEXT.md)"
  done
  exit 0
fi

if [ -z "$ARTIFACT" ]; then
  echo "[check-artifact-fidelity] usage : check-artifact-fidelity.sh [--target codex] [--json] <artefact.md>" >&2
  exit 2
fi

if [ "$TARGET" != "codex" ]; then
  echo "[check-artifact-fidelity] cible '$TARGET' : non mesuré sur ce poste (seule --target codex est mesurée au 2026-08-28)" >&2
  exit 3
fi

if [ ! -f "$ARTIFACT" ]; then
  echo "[check-artifact-fidelity] artefact source introuvable : $ARTIFACT" >&2
  exit 3
fi

# --- Résolution de l'adaptateur Codex réel (agent-to-codex.mjs) : SEULE conversion qui produit
# l'artefact RÉELLEMENT posé par une install (le TOML sous $CODEX_HOME/agents/vibeflow/*.toml,
# écrit par register-codex-agent.sh, lot 5/ADPT-01). Cascade à 1 candidat, MÊME patron relatif que
# find_fidelity_gate()/find_codex_registrar() côté vibeflow-update.sh : ce gate vit sous
# <racine>/<module>/scripts/check-artifact-fidelity.sh, agent-to-codex.mjs sous
# <racine>/_internal/runtime-adapter/ — la remontée `../../_internal/...` résout identiquement
# que <racine> soit le dépôt source (dev/tests) ou un CACHE_DIR d'install réel (module et
# _internal sont TOUS DEUX des enfants directs de <racine>, même structure des deux côtés).
# INTROUVABLE (ex. gate posé À PLAT sous TARGET_ROOT/scripts/, où _internal n'est JAMAIS mirroré
# — cf. find_codex_registrar) -> repli sur l'ancienne mesure gsd-core, TOUJOURS marquée
# MODE=gsdcore-fallback sur la ligne rendue (jamais confondue avec la mesure de l'artefact réel).
find_codex_adapter() {
  local here c
  here="$(cd "$(dirname "$0")" && pwd)"
  c="$here/../../_internal/runtime-adapter/agent-to-codex.mjs"
  if [ -f "$c" ]; then
    printf '%s/agent-to-codex.mjs' "$(cd "$(dirname "$c")" && pwd)"
    return 0
  fi
  echo ""
}
ADAPTER_MJS="$(find_codex_adapter)"

# --- Extraction de frontmatter (bash pur, indépendante de la boîte noire qu'elle mesure — le
# DIFF reste auditable sans dépendre de l'adaptateur ni de gsd-core). ---
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

# --- Marqueurs morts : comptés sur le CORPS (hors frontmatter). Fonction partagée par les deux
# modes de mesure (adapter / gsdcore-fallback), et extraite isolément par T7. ---
count_markers() {
  # grep -o compte les OCCURRENCES (une ligne peut porter deux marqueurs) — grep -c compterait
  # cette ligne une seule fois et sous-déclarerait DEAD_MARKERS.
  local body="$1"
  local n_claude n_task
  n_claude=$(printf '%s' "$body" | grep -o '\.claude/' | wc -l | tr -d ' ')
  n_task=$(printf '%s' "$body" | grep -o 'Task(' | wc -l | tr -d ' ')
  echo $((n_claude + n_task))
}
SRC_MARKERS=$(count_markers "$SRC_BODY")

PRESERVED=""
DEGRADED=""
LOST=""
MAPPED=""
add_verdict() {
  # $1 = liste (nom de variable), $2 = champ
  case "$1" in
    PRESERVED) PRESERVED="${PRESERVED:+$PRESERVED,}$2" ;;
    DEGRADED)  DEGRADED="${DEGRADED:+$DEGRADED,}$2" ;;
    LOST)      LOST="${LOST:+$LOST,}$2" ;;
    MAPPED)    MAPPED="${MAPPED:+$MAPPED,}$2" ;;
  esac
}

TMPDIR_GATE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_GATE"' EXIT

MEASURE_MODE=""
DEAD_MARKERS_LABEL=""

if [ -n "$ADAPTER_MJS" ] && command -v node >/dev/null 2>&1; then
  # --- MODE RÉEL (MODE=adapter) : invoque la MÊME conversion que register-codex-agent.sh (lot
  # 5) — celle qui écrit réellement le .toml posé sur disque à l'install. Le digest per-champ
  # (name/description/model/effort/memory/tools/disallowedTools/vf-internal) sort sur stderr, un
  # champ par ligne (`field: STATUS[ — note]`) — SEULE source de vérité, jamais recalculée à la
  # main ici : c'est ce qui rend structurellement impossible la divergence corrigée par ce
  # correctif (le gate lit le MÊME digest que celui relayé [codex-adapter] à l'install).
  MEASURE_MODE="adapter"
  CONVERTED_FILE="$TMPDIR_GATE/converted.toml"
  NODE_ERR="$TMPDIR_GATE/node-err.log"
  node "$ADAPTER_MJS" "$ARTIFACT" --out "$CONVERTED_FILE" 2>"$NODE_ERR" >/dev/null
  NODE_RC=$?
  if [ "$NODE_RC" -ne 0 ]; then
    echo "[check-artifact-fidelity] échec de la conversion Codex réelle (agent-to-codex.mjs, node exit $NODE_RC) : $(cat "$NODE_ERR")" >&2
    exit 3
  fi
  DIGEST_TEXT="$(cat "$NODE_ERR")"

  digest_status() {
    # $1 = nom de champ digest (identique au frontmatter, cf. agent-to-codex.mjs formatDigest).
    printf '%s\n' "$DIGEST_TEXT" | grep -E "^${1}: " | head -1 | sed -E 's/^[^:]+: ([A-Z_]+).*/\1/'
  }
  digest_note() {
    # $1 = nom de champ digest. Rend le texte après « — » (vide si le digest n'en porte pas).
    printf '%s\n' "$DIGEST_TEXT" | grep -E "^${1}: " | head -1 | sed -E 's/^[^:]+: [A-Z_]+( — )?//'
  }
  map_and_add() {
    # $1 = champ [fidelity], $2 = nom de champ côté digest, $3 = valeur SRC_* (gate n'émet un
    # verdict QUE si la source portait le champ — même doctrine que l'ancien mode).
    #
    # MAPPED (4e verdict, à côté de PRESERVED/DEGRADED/LOST) : la valeur source a été TRADUITE
    # vers une valeur cible différente mais VALIDE pour Codex (ex. model `opus` -> Codex
    # `gpt-5.6-terra`, table CLAUDE_TO_CODEX_MODEL) — ce n'est ni une conservation littérale
    # (PRESERVED, qui suppose la MÊME valeur des deux côtés) ni une perte (LOST). agent-to-codex.mjs
    # n'émet JAMAIS `MAPPED` pour une cible invalide : une cible absente de la table de mapping
    # fait échouer la conversion (node exit != 0, capté plus haut), donc `MAPPED` ici signifie
    # toujours une valeur posée et valide côté Codex — jamais un LOST déguisé sous une étiquette
    # neutre (défaut corrigé : avant, `MAPPED` tombait dans le `*)` ci-dessous et ressortait LOST).
    local field="$1" digest_field="$2" src_value="$3" status note src_v tgt_v
    [ -n "$src_value" ] || return 0
    status="$(digest_status "$digest_field")"
    case "$status" in
      PRESERVED|PRESERVED_BY_OMISSION) add_verdict PRESERVED "$field" ;;
      MAPPED)
        note="$(digest_note "$digest_field")"
        src_v="$(printf '%s' "$note" | sed -nE 's/.*source "([^"]*)".*/\1/p')"
        tgt_v="$(printf '%s' "$note" | sed -nE 's/.*cible [A-Za-z]+ "([^"]*)".*/\1/p')"
        add_verdict MAPPED "${field}(${src_v:-?}->${tgt_v:-?})"
        ;;
      PENDING) add_verdict DEGRADED "$field" ;;
      *) add_verdict LOST "$field" ;;
    esac
  }
  map_and_add name name "$SRC_NAME"
  map_and_add description description "$SRC_DESCRIPTION"
  map_and_add model model "$SRC_MODEL"
  map_and_add memory memory "$SRC_MEMORY"
  map_and_add disallowedTools disallowedTools "$SRC_DISALLOWEDTOOLS"
  map_and_add vf-internal vf-internal "$SRC_VF_INTERNAL"
  map_and_add tools tools "$SRC_TOOLS"

  extract_toml_multiline() {
    # $1 = fichier, $2 = clé TOML. Ancré sur le gabarit EXACT émis par agent-to-codex.mjs
    # (`key = """` seule en tête de ligne, corps, `"""` seule sur sa ligne de fermeture — cf.
    # escapeTomlMultiline/convertAgentToCodexRole).
    awk -v key="$2" '
      $0 == key " = \"\"\"" { c=1; next }
      c && $0 == "\"\"\"" { c=0; next }
      c { print }
    ' "$1"
  }
  CONV_BODY="$(extract_toml_multiline "$CONVERTED_FILE" "developer_instructions")"
  CONV_MARKERS=$(count_markers "$CONV_BODY")
  if [ "$SRC_MARKERS" -eq "$CONV_MARKERS" ]; then
    DEAD_MARKERS_LABEL="$CONV_MARKERS (non réécrits)"
  else
    DEAD_MARKERS_LABEL="$CONV_MARKERS (source=$SRC_MARKERS, réécriture partielle mesurée)"
  fi
else
  # --- MODE DE REPLI (MODE=gsdcore-fallback) : adaptateur Codex introuvable sur ce poste (ex.
  # gate posé À PLAT sous TARGET_ROOT/scripts/, _internal jamais mirroré à cette position — cf.
  # commentaire de find_codex_adapter ci-dessus). Bascule sur la conversion gsd-core
  # (duplication DÉLIBÉRÉE de check-gsd-engine.sh:default_gsd_home_new(), motivée par le même
  # D-01 : ce gate doit rester testable en boîte noire sans sourcer un script à effets de bord).
  # Mesure un Markdown de conversion QUI N'EST PAS L'ARTEFACT INSTALLÉ — jamais confondue avec la
  # mesure réelle ci-dessus sous la même étiquette (MODE le distingue toujours).
  MEASURE_MODE="gsdcore-fallback"

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
    echo "[check-artifact-fidelity] ni l'adaptateur Codex (agent-to-codex.mjs) ni gsd-core ('$GSD_HOME') ne sont disponibles sur ce poste — impossible de mesurer la conversion" >&2
    exit 3
  fi

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
    echo "[check-artifact-fidelity] échec de la conversion gsd-core de repli (node exit $NODE_RC) : $(cat "$NODE_ERR")" >&2
    exit 3
  fi

  CONV_FM="$(extract_frontmatter "$CONVERTED_FILE")"
  CONV_BODY="$(extract_body "$CONVERTED_FILE")"

  for f in name description model memory disallowedTools vf-internal; do
    var="CONV_$(echo "$f" | tr '[:lower:]-' '[:upper:]_')"
    eval "$var=\"\$(get_field \"\$CONV_FM\" \"$f\")\""
  done

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

  CONV_MARKERS=$(count_markers "$CONV_BODY")
  if [ "$SRC_MARKERS" -eq "$CONV_MARKERS" ]; then
    DEAD_MARKERS_LABEL="$CONV_MARKERS (non réécrits)"
  else
    DEAD_MARKERS_LABEL="$CONV_MARKERS (source=$SRC_MARKERS, réécriture partielle mesurée)"
  fi
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

# --- role_confinement (FIDE-03, D-38-O) : CONSTANTE déclarée pour --target codex — pas une
# mesure de poste comme les deux champs précédents, un comportement documenté du binaire
# (sandbox_mode/approval_policy/[permissions] par rôle acceptés puis inertes, session-only). ---
ROLE_CONFINEMENT="inerte-par-role (garanti UNIQUEMENT par session -s read-only separee, jamais par le fichier de role — D-38-O)"

if [ "$JSON_MODE" -eq 0 ]; then
  echo "[fidelity-recette] multi_agent_v2=${MULTI_AGENT_V2} trust_level=${TRUST_LEVEL} role_confinement=${ROLE_CONFINEMENT}"
fi

if [ "$JSON_MODE" -eq 1 ]; then
  node -e '
const fs = require("fs");
const [artifact, target, preserved, degraded, lost, mapped, deadMarkers, multiAgentV2, trustLevel, roleConfinement, mode] = process.argv.slice(1);
const splitCsv = (s) => (s ? s.split(",") : []);
const out = {
  artifact,
  target,
  preserved: splitCsv(preserved),
  degraded: splitCsv(degraded),
  lost: splitCsv(lost),
  mapped: splitCsv(mapped),
  dead_markers: deadMarkers,
  multi_agent_v2: multiAgentV2,
  trust_level: trustLevel,
  role_confinement: roleConfinement,
  mode,
};
process.stdout.write(JSON.stringify(out));
' "$ARTIFACT" "$TARGET" "$PRESERVED" "$DEGRADED" "$LOST" "$MAPPED" "$DEAD_MARKERS_LABEL" "$MULTI_AGENT_V2" "$TRUST_LEVEL" "$ROLE_CONFINEMENT" "$MEASURE_MODE"
  echo
else
  echo "[fidelity] $ARTIFACT -> $TARGET: PRESERVED={$PRESERVED} DEGRADED={$DEGRADED} LOST={$LOST} MAPPED={$MAPPED} DEAD_MARKERS=$DEAD_MARKERS_LABEL MODE=$MEASURE_MODE"
fi

exit 0
