#!/usr/bin/env bash
# inject-mcp-tools.sh — Injecte les serveurs MCP déclarés par le lab dans le `tools:` des agents
#                        exécutants (ADR-047).
#
# Problème résolu : un sous-agent (Task) n'hérite PAS des serveurs MCP de la session. Il ne voit,
# côté MCP, que ce que son `tools:` autorise explicitement (`mcp__<serveur>__*`). Les agents
# exécutants VibeFlow (vf-coder, vf-app-fixer, vf-test-runner, vf-test-orchestrator) portent une
# allowlist fermée → aveugles au serveur MCP du projet (XcodeBuildMCP, mobile-mcp, une DB métier…).
# Le glob générique `mcp__*` N'EST PAS accepté en allowlist `tools:` (seulement dans disallowedTools) :
# on injecte donc, par serveur, la forme sûre `mcp__<serveur>__*` — dérivée du `.mcp.json` du lab.
#
# Le geste est GÉNÉRIQUE (aucun nom de serveur en dur) et SCOPE-AWARE (moindre privilège : chaque
# lab n'obtient que les serveurs qu'il déclare). Data-driven côté agents : ne touche QUE les fichiers
# marqués `vf-mcp-consumer: true` (sélecteur analogue à `mandatory:` / `vf-internal:`).
#
# Usage:
#   inject-mcp-tools.sh --target <fichier|dossier> [options]
#
# Options:
#   --target <path>     Fichier agent .md OU dossier d'agents à balayer (REQUIS).
#   --mcp-json <path>   Source des serveurs (défaut ./.mcp.json). Absent → no-op (rien à injecter).
#   --servers "a,b,c"   Liste explicite de serveurs (l'emporte sur --mcp-json ; utile tests/défaut).
#   --force             Traiter un fichier même SANS le flag vf-mcp-consumer (ex. gsd-executor, hors
#                       plugin). Ignoré en mode dossier (le balayage reste filtré par le flag).
#   --dry-run           Loguer les changements prévus SANS écrire.
#   -h | --help
#
# Comportement :
#   - Idempotent : un token déjà présent n'est jamais dupliqué ; sans changement, le fichier n'est
#     pas réécrit (mtime préservé). Re-jouable à volonté.
#   - Best-effort : python3 absent, .mcp.json absent ou sans serveurs, agent sans ligne `tools:`
#     (hérite déjà tout) → no-op + log, JAMAIS d'échec (exit 0). Args invalides → exit 1.
#   - Ne modifie QUE la ligne `tools:` du frontmatter ; le reste du fichier est préservé.
#
# Appelé par : vibeflow-update.sh (hook post-install, agents flaggés) · ensure-deps.sh (gsd-executor,
#              --force post-install GSD) · /vf-calibrate (re-injection sur évolution du .mcp.json).
#
# Référence : ADR-047 (allowlist MCP dérivée du lab), Pattern 12 (cloisonnement inchangé : on
#             n'injecte que des serveurs de build/test, pas d'accès web/doc).

set -uo pipefail

log() { echo "[inject-mcp-tools] $*" >&2; }
err() { echo "[inject-mcp-tools] ERROR: $*" >&2; }

TARGET=""
MCP_JSON="./.mcp.json"
SERVERS=""
FORCE="false"
DRY_RUN="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)    [ "$#" -ge 2 ] || { err "--target nécessite une valeur"; exit 1; }; TARGET="$2"; shift 2 ;;
    --target=*)  TARGET="${1#--target=}"; shift ;;
    --mcp-json)  [ "$#" -ge 2 ] || { err "--mcp-json nécessite une valeur"; exit 1; }; MCP_JSON="$2"; shift 2 ;;
    --mcp-json=*) MCP_JSON="${1#--mcp-json=}"; shift ;;
    --servers)   [ "$#" -ge 2 ] || { err "--servers nécessite une valeur"; exit 1; }; SERVERS="$2"; shift 2 ;;
    --servers=*) SERVERS="${1#--servers=}"; shift ;;
    --force)     FORCE="true"; shift ;;
    --dry-run)   DRY_RUN="true"; shift ;;
    -h|--help)   grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *)           err "argument inconnu : $1"; exit 1 ;;
  esac
done

[ -n "$TARGET" ] || { err "--target requis (fichier agent .md ou dossier d'agents)"; exit 1; }
[ -e "$TARGET" ] || { err "cible introuvable : $TARGET"; exit 1; }

# python3 est le cœur (parsing JSON + réécriture précise). Absent → best-effort no-op (exit 0),
# comme check-agents.sh : jamais faire échouer une install sur une machine sans python3.
if ! command -v python3 >/dev/null 2>&1; then
  log "python3 requis pour l'injection MCP — étape sautée (best-effort). Agents inchangés."
  exit 0
fi

VF_TARGET="$TARGET" VF_MCP_JSON="$MCP_JSON" VF_SERVERS="$SERVERS" \
VF_FORCE="$FORCE" VF_DRY_RUN="$DRY_RUN" python3 -c '
import json, os, re, sys, glob

target   = os.environ["VF_TARGET"]
mcp_json = os.environ["VF_MCP_JSON"]
servers_arg = os.environ["VF_SERVERS"].strip()
force    = os.environ["VF_FORCE"] == "true"
dry_run  = os.environ["VF_DRY_RUN"] == "true"

def logline(msg):
    print("[inject-mcp-tools] " + msg, file=sys.stderr)

# --- 1. Résoudre la liste des serveurs -----------------------------------------------------------
servers = []
if servers_arg:
    servers = [s.strip() for s in servers_arg.split(",") if s.strip()]
else:
    if not os.path.isfile(mcp_json):
        logline("pas de %s dans le lab — aucun serveur MCP a injecter (no-op)." % mcp_json)
        sys.exit(0)
    try:
        with open(mcp_json, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        logline("%s illisible/invalide (%s) — no-op." % (mcp_json, e))
        sys.exit(0)
    block = data.get("mcpServers") or data.get("mcp_servers") or {}
    if isinstance(block, dict):
        servers = list(block.keys())

# Serveurs valides pour un préfixe d outil MCP : [A-Za-z0-9_-].
servers = sorted({s for s in servers if re.fullmatch(r"[A-Za-z0-9_-]+", s)})
if not servers:
    logline("aucun serveur MCP declare — no-op.")
    sys.exit(0)

want_tokens = ["mcp__%s__*" % s for s in servers]

# --- 2. Déterminer les fichiers cibles -----------------------------------------------------------
FLAG_RE = re.compile(r"^vf-mcp-consumer:\s*true\s*$", re.M)

def frontmatter_block(text):
    """Renvoie (start_idx, end_idx) des lignes du frontmatter (entre les deux ---), ou None."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None, lines
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return (1, i), lines
    return None, lines

def has_flag(text):
    span, lines = frontmatter_block(text)
    if span is None:
        return False
    fm = "\n".join(lines[span[0]:span[1]])
    return bool(FLAG_RE.search(fm))

files = []
if os.path.isfile(target):
    files = [target]
    single = True
else:
    single = False
    for f in sorted(glob.glob(os.path.join(target, "*.md"))):
        try:
            t = open(f, encoding="utf-8").read()
        except OSError:
            continue
        if has_flag(t):
            files.append(f)

if not files:
    logline("aucun agent cible (mode dossier : aucun fichier vf-mcp-consumer: true) — no-op.")
    sys.exit(0)

# --- 3. Injection idempotente sur la ligne tools: ------------------------------------------------
changed_total = 0
for path in files:
    try:
        text = open(path, encoding="utf-8").read()
    except OSError as e:
        logline("%s illisible (%s) — ignore." % (os.path.basename(path), e))
        continue

    base = os.path.basename(path)

    # En mode fichier unique sans --force, exiger le flag (securite : ne pas ouvrir un agent
    # planif/revue/audit par erreur). En mode dossier, le filtrage par flag est deja fait.
    if single and not force and not has_flag(text):
        logline("%s : pas de flag vf-mcp-consumer et pas de --force — ignore." % base)
        continue

    span, lines = frontmatter_block(text)
    if span is None:
        logline("%s : pas de frontmatter — ignore." % base)
        continue

    fm_start, fm_end = span
    tools_idx = None
    for i in range(fm_start, fm_end):
        if re.match(r"^tools:\s*", lines[i]):
            tools_idx = i
            break

    if tools_idx is None:
        # Pas de ligne tools: → l agent herite de TOUS les outils (donc deja tout le MCP). No-op.
        logline("%s : pas de ligne tools: (herite tout) — rien a injecter." % base)
        continue

    line = lines[tools_idx]
    prefix = re.match(r"^tools:\s*", line).group(0)
    value = line[len(prefix):]
    existing = [tok.strip() for tok in value.split(",") if tok.strip()]

    missing = [tok for tok in want_tokens if tok not in existing]
    if not missing:
        logline("%s : deja a jour (%s)." % (base, ", ".join(want_tokens)))
        continue

    new_tokens = existing + missing
    lines[tools_idx] = prefix + ", ".join(new_tokens)
    new_text = "\n".join(lines)

    if dry_run:
        logline("%s : (dry-run) ajouterait %s" % (base, ", ".join(missing)))
        changed_total += 1
        continue

    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(new_text)
    os.replace(tmp, path)
    logline("%s : injecte %s" % (base, ", ".join(missing)))
    changed_total += 1

logline("termine : %d fichier(s) modifie(s), serveurs = [%s]." % (changed_total, ", ".join(servers)))
sys.exit(0)
'
