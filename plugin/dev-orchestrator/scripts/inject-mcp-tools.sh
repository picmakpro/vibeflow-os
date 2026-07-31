#!/usr/bin/env bash
# inject-mcp-tools.sh — Injecte les serveurs MCP déclarés par le lab dans le `tools:` des agents
#                        exécutants (ADR-051).
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
# SECOND MODE — allowlist NOMMÉE (D-05) : un agent qui porte la clé de frontmatter `vf-mcp-tools`
# (grammaire `<serveur>:<outil1>,<outil2>,…`) reçoit UNIQUEMENT les tokens `mcp__<serveur>__<outil>`
# qu'il déclare — JAMAIS le joker `mcp__<serveur>__*`. La correspondance de nom de serveur est
# INSENSIBLE À LA CASSE, en égalité stricte (jamais un motif ni une sous-chaîne) ; le token injecté
# reprend l'orthographe du `.mcp.json` du lab (liste `servers` résolue), PAS celle du frontmatter,
# car c'est cette orthographe-là qui forme le préfixe réel côté runtime. Les deux modes coexistent
# par fichier : un fichier qui porte les DEUX clés est traité en mode NOMMÉ (le plus restrictif
# l'emporte, moindre privilège), avec une ligne de log qui le signale. Ce mode est déclenché par le
# CONTENU du fichier cible, jamais par un flag — aucun appelant n'a besoin d'être modifié.
#
# SOURCES DES SERVEURS (Phase 21, ADR-051-B) : UNION de deux scopes, jamais un remplacement.
#   1. Scope PROJET  — ./.mcp.json (option --mcp-json), commité au repo du lab.
#   2. Scope GLOBAL  — ~/.claude.json (option --claude-json, défaut réel du poste), clé top-level
#      `mcpServers` (scope "user" Claude Code). C'est là qu'un serveur comme XcodeBuildMCP est
#      déclaré sur un parc de labs qui n'ont individuellement aucun `.mcp.json` — la lacune qui
#      rendait ce script structurellement inopérant sur ce type de poste (mission
#      2026-07-31-delta-gsd-core-1.9.0.md). Il existe une TROISIÈME zone dans `~/.claude.json`
#      (`projects.<cwd>.mcpServers`, scope "local" par-projet-par-utilisateur) — volontairement
#      HORS PÉRIMÈTRE ici : elle était vide sur tous les labs vérifiés au moment du diagnostic et
#      son ajout aurait élargi le contrat au-delà du seul défaut constaté ; à instruire séparément
#      si un jour un lab l'utilise réellement.
#   Précédence en cas de collision de nom (insensible à la casse) : le scope PROJET l'emporte sur
#   le scope GLOBAL pour l'ORTHOGRAPHE retenue — aligné sur la précédence Claude Code réelle
#   (projet > utilisateur). --servers explicite reste prioritaire sur les deux sources fichier,
#   inchangé. Dégradation propre sur chaque source, indépendamment : fichier absent, JSON invalide,
#   ou clé `mcpServers`/`mcp_servers` manquante → cette source contribue une liste vide + un log,
#   JAMAIS un crash ni un arrêt de l'autre source. Le verdict INDÉTERMINÉ (3 en --verify, no-op en
#   injection) ne tombe QUE si les DEUX sources (+ --servers) sont vides — jamais fabriqué depuis
#   une découverte partielle.
#
# HONNÊTETÉ (D-03) : les NOMS D'OUTILS déclarés par un agent via `vf-mcp-tools` (ex. `test_sim`,
# `build_sim`) ne sont JAMAIS confrontés à un serveur MCP vivant par ce script — aucune requête,
# aucun lancement du process serveur. Ce que ce script confirme (WINDOWS #4, Phase 21), c'est que
# le NOM DU SERVEUR cité (`vf-mcp-tools` ou un token `mcp__<serveur>__...` déjà présent) correspond
# à un serveur DÉCLARÉ par au moins une des deux sources ci-dessus — pas que ses outils existent
# réellement côté serveur, ni qu'il répond. Un serveur cité mais inconnu de toutes les sources est
# signalé (WARNING par défaut, ERROR bloquante en --strict — voir --strict plus bas) ; un serveur
# CONNU peut encore porter des noms d'outils fantaisistes non détectés par ce script. La validation
# des noms d'outils réels reste une recette humaine sur un lab équipé (WINDOWS #3, laissée ouverte).
#
# Usage:
#   inject-mcp-tools.sh --target <fichier|dossier> [options]
#
# Options:
#   --target <path>       Fichier agent .md OU dossier d'agents à balayer (REQUIS).
#   --mcp-json <path>     Scope PROJET (défaut ./.mcp.json). Absent → cette source contribue vide.
#   --claude-json <path>  Scope GLOBAL (défaut $HOME/.claude.json, ou $VF_CLAUDE_JSON si défini —
#                         override hermétique pour les tests, jamais dépendant de la machine).
#                         LECTURE SEULE, toujours. Absent/invalide → cette source contribue vide.
#   --servers "a,b,c"     Liste explicite de serveurs (l'emporte sur les DEUX sources fichier).
#   --force               Traiter un fichier même SANS le flag vf-mcp-consumer (ex. gsd-executor, hors
#                         plugin). Ignoré en mode dossier (le balayage reste filtré par le flag).
#   --dry-run             Loguer les changements prévus SANS écrire.
#   --strict               Durcit UN SEUL constat, normalement un WARNING silencieux côté exit code :
#                         un token (`vf-mcp-tools` ou `mcp__<serveur>__...` déjà présent) qui cite un
#                         serveur inconnu de TOUTES les sources découvertes (WINDOWS #4). Devient une
#                         ERROR bloquante (contribue à un exit 1) — convention alignée sur
#                         check-agents.sh --strict. N'affecte PAS le calcul manquant/conforme des
#                         tokens MCP eux-mêmes, seulement la détection de noms de serveurs inconnus.
#   --verify               Mode LECTURE SEULE (D-09) : relit le `tools:` final et le COMPARE aux
#                         serveurs attendus. Il RELIT, il COMPARE, il RAPPORTE — il ne réécrit JAMAIS
#                         rien, et ne rejoue JAMAIS --force à la place de l'appelant (réparer
#                         silencieusement détruirait exactement le signal que ce mode existe pour
#                         produire). Exits dédiés : 0 = conforme · 1 = serveur manquant (bruyant, sur
#                         stderr) — ou, sous --strict, serveur inconnu cité · 3 = INDÉTERMINÉ (pas de
#                         ligne tools:, AUCUN serveur déclaré par AUCUNE source, aucune cible retenue,
#                         ou python3 absent — ce dernier cas sort en succès best-effort dans les
#                         AUTRES modes, mais JAMAIS en --verify : un faux vert serait pire que
#                         l'absence de vérification).
#   -h | --help
#
# Comportement :
#   - Idempotent : un token déjà présent n'est jamais dupliqué ; sans changement, le fichier n'est
#     pas réécrit (mtime préservé). Re-jouable à volonté.
#   - Best-effort : python3 absent, aucun serveur trouvé par aucune source, agent sans ligne `tools:`
#     (hérite déjà tout) → no-op + log, JAMAIS d'échec (exit 0) — SAUF en --verify (voir ci-dessus,
#     exit 3 systématique quand aucun verdict n'est possible) ou --strict avec serveur inconnu cité
#     (exit 1). Args invalides → exit 1.
#   - Ne modifie QUE la ligne `tools:` du frontmatter ; le reste du fichier est préservé.
#
# Appelé par : vibeflow-update.sh (hook post-install, agents flaggés) · ensure-deps.sh (gsd-executor,
#              --force post-install GSD, puis --verify pour dire fort un écart, D-09) ·
#              /vf-calibrate (re-injection sur évolution du .mcp.json).
#
# Référence : ADR-051 (allowlist MCP dérivée du lab), Pattern 12 (cloisonnement inchangé : on
#             n'injecte que des serveurs de build/test, pas d'accès web/doc).

set -uo pipefail

log() { echo "[inject-mcp-tools] $*" >&2; }
err() { echo "[inject-mcp-tools] ERROR: $*" >&2; }

TARGET=""
MCP_JSON="./.mcp.json"
# Scope global : injectable par flag OU par variable d'environnement (testabilité hermétique —
# jamais un test qui dépend silencieusement de la config personnelle de la machine, cf. en-tête).
CLAUDE_JSON="${VF_CLAUDE_JSON:-${HOME:-}/.claude.json}"
SERVERS=""
FORCE="false"
DRY_RUN="false"
STRICT="false"
VERIFY="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)    [ "$#" -ge 2 ] || { err "--target nécessite une valeur"; exit 1; }; TARGET="$2"; shift 2 ;;
    --target=*)  TARGET="${1#--target=}"; shift ;;
    --mcp-json)  [ "$#" -ge 2 ] || { err "--mcp-json nécessite une valeur"; exit 1; }; MCP_JSON="$2"; shift 2 ;;
    --mcp-json=*) MCP_JSON="${1#--mcp-json=}"; shift ;;
    --claude-json)  [ "$#" -ge 2 ] || { err "--claude-json nécessite une valeur"; exit 1; }; CLAUDE_JSON="$2"; shift 2 ;;
    --claude-json=*) CLAUDE_JSON="${1#--claude-json=}"; shift ;;
    --servers)   [ "$#" -ge 2 ] || { err "--servers nécessite une valeur"; exit 1; }; SERVERS="$2"; shift 2 ;;
    --servers=*) SERVERS="${1#--servers=}"; shift ;;
    --force)     FORCE="true"; shift ;;
    --dry-run)   DRY_RUN="true"; shift ;;
    --strict)    STRICT="true"; shift ;;
    --verify)    VERIFY="true"; shift ;;
    -h|--help)   grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *)           err "argument inconnu : $1"; exit 1 ;;
  esac
done

[ -n "$TARGET" ] || { err "--target requis (fichier agent .md ou dossier d'agents)"; exit 1; }
[ -e "$TARGET" ] || { err "cible introuvable : $TARGET"; exit 1; }

# python3 est le cœur (parsing JSON + réécriture précise). Absent → best-effort no-op (exit 0)
# dans les modes normaux, comme check-agents.sh : jamais faire échouer une install sur une
# machine sans python3. En --verify UNIQUEMENT : ce repli deviendrait un faux vert (D-09) — le
# verdict doit rester INDÉTERMINÉ (exit 3), jamais un succès muet.
if ! command -v python3 >/dev/null 2>&1; then
  if [ "$VERIFY" = "true" ]; then
    err "python3 requis pour --verify — verdict INDÉTERMINÉ (jamais un faux vert)."
    exit 3
  fi
  log "python3 requis pour l'injection MCP — étape sautée (best-effort). Agents inchangés."
  exit 0
fi

VF_TARGET="$TARGET" VF_MCP_JSON="$MCP_JSON" VF_CLAUDE_JSON="$CLAUDE_JSON" VF_SERVERS="$SERVERS" \
VF_FORCE="$FORCE" VF_DRY_RUN="$DRY_RUN" VF_STRICT="$STRICT" VF_VERIFY="$VERIFY" python3 -c '
import json, os, re, sys, glob

target      = os.environ["VF_TARGET"]
mcp_json    = os.environ["VF_MCP_JSON"]
claude_json = os.environ["VF_CLAUDE_JSON"]
servers_arg = os.environ["VF_SERVERS"].strip()
force    = os.environ["VF_FORCE"] == "true"
dry_run  = os.environ["VF_DRY_RUN"] == "true"
strict   = os.environ["VF_STRICT"] == "true"
verify   = os.environ["VF_VERIFY"] == "true"

def logline(msg):
    print("[inject-mcp-tools] " + msg, file=sys.stderr)

def errline(msg):
    print("[inject-mcp-tools] ERROR: " + msg, file=sys.stderr)

# --- 1. Résoudre la liste des serveurs (UNION scope projet + scope global, ADR-051-B) -------------
def load_json_servers(path, what):
    """Lit un fichier JSON et renvoie la liste de noms sous la cle mcpServers/mcp_servers d une
    source nommee 'what' (pour les logs). Degradation propre et INDEPENDANTE par source : fichier
    absent, JSON invalide, ou cle manquante -> liste vide + log, JAMAIS un crash ni un arret des
    autres sources (Geste B)."""
    if not path or not os.path.isfile(path):
        logline("%s : %s introuvable — cette source ne contribue aucun serveur." % (what, path))
        return []
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        logline("%s : %s illisible/invalide (%s) — cette source ne contribue aucun serveur." % (what, path, e))
        return []
    if not isinstance(data, dict):
        logline("%s : %s — contenu JSON inattendu (pas un objet) — cette source ne contribue aucun serveur." % (what, path))
        return []
    block = data.get("mcpServers") or data.get("mcp_servers") or {}
    if not isinstance(block, dict):
        return []
    return list(block.keys())

servers = []
if servers_arg:
    servers = [s.strip() for s in servers_arg.split(",") if s.strip()]
else:
    # Precedence sur l ORTHOGRAPHE en cas de collision insensible a la casse : scope global d abord
    # (precedence basse), scope projet ensuite (precedence haute, ecrase) — aligne sur la
    # precedence Claude Code reelle (scope projet .mcp.json > scope utilisateur global).
    global_servers = load_json_servers(claude_json, "scope global (--claude-json)")
    project_servers = load_json_servers(mcp_json, "scope projet (--mcp-json)")
    merged = {}
    for s in global_servers:
        merged[s.lower()] = s
    for s in project_servers:
        merged[s.lower()] = s
    servers = list(merged.values())

# Serveurs valides pour un préfixe d outil MCP : [A-Za-z0-9_-].
servers = sorted({s for s in servers if re.fullmatch(r"[A-Za-z0-9_-]+", s)})
if not servers:
    if verify:
        errline("--verify : aucun serveur MCP declare par aucune source (scope projet %s, scope global %s) — verdict INDETERMINE." % (mcp_json, claude_json))
        sys.exit(3)
    logline("aucun serveur MCP declare par aucune source (scope projet %s, scope global %s) — no-op." % (mcp_json, claude_json))
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

# --- Mode NOMMÉ (D-05) : clé dédiée `vf-mcp-tools`, grammaire <serveur>:<outil1>,<outil2>,… -------
TOKEN_SEGMENT_RE = re.compile(r"^[A-Za-z0-9_-]+$")
NAMED_FLAG_RE = re.compile(r"^vf-mcp-tools:\s*(.*)$", re.M)

def has_named(text):
    """Présence de la clé `vf-mcp-tools` dans le frontmatter, valide ou non (pour découverte,
    garde de mode fichier unique, et détection de coexistence avec vf-mcp-consumer)."""
    span, lines = frontmatter_block(text)
    if span is None:
        return False
    fm = "\n".join(lines[span[0]:span[1]])
    return bool(NAMED_FLAG_RE.search(fm))

def named_request(text):
    """Renvoie (serveur_declare, [outils]) depuis la cle vf-mcp-tools, ou None si la cle est
    absente OU la valeur malformee (pas de deux-points, serveur vide, aucun outil declare, ou
    caractere hors du charset autorise pour un segment de token MCP). Une valeur malformee est un
    no-op journalise, jamais une erreur (best-effort, D-05)."""
    span, lines = frontmatter_block(text)
    if span is None:
        return None
    fm = "\n".join(lines[span[0]:span[1]])
    m = NAMED_FLAG_RE.search(fm)
    if not m:
        return None
    raw = m.group(1).strip()
    if ":" not in raw:
        return None
    server_part, _, tools_part = raw.partition(":")
    server = server_part.strip()
    tools = [t.strip() for t in tools_part.split(",") if t.strip()]
    if not server or not tools:
        return None
    if not TOKEN_SEGMENT_RE.match(server):
        return None
    if any(not TOKEN_SEGMENT_RE.match(t) for t in tools):
        return None
    return (server, tools)

def named_tokens_for(text, servers):
    """Renvoie la liste mcp__<serveur, orthographe du lab>__<outil> pour chaque outil declare par
    vf-mcp-tools, ou la liste vide si la cle est absente, malformee, ou si le serveur declare
    n est pas resolu dans servers (comparaison insensible a la casse, egalite stricte)."""
    req = named_request(text)
    if req is None:
        return []
    server, tools = req
    resolved = None
    for s in servers:
        if s.lower() == server.lower():
            resolved = s
            break
    if resolved is None:
        return []
    return ["mcp__%s__%s" % (resolved, t) for t in tools]

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
        if has_flag(t) or has_named(t):
            files.append(f)

if not files:
    if verify:
        errline("--verify : aucune cible retenue — verdict INDETERMINE.")
        sys.exit(3)
    logline("aucun agent cible (mode dossier : aucun fichier vf-mcp-consumer: true ni vf-mcp-tools) — no-op.")
    sys.exit(0)

# --- 2bis. WINDOWS #4 (Phase 21) : signaler un nom de serveur cite mais inconnu de toutes les ------
# sources decouvertes. Deux origines de citation : la cle vf-mcp-tools (mode NOMME, qui produisait
# jusqu ici un no-op totalement silencieux sur ce cas precis) et tout token mcp__<serveur>__...
# DEJA present dans la ligne tools: du fichier (mode joker herite d une injection anterieure, ou
# saisi a la main). Gradation alignee sur check-agents.sh --strict : WARNING par defaut (un lab
# peut legitimement citer un serveur qu il installera plus tard — une ERROR dure casserait des
# labs sains), ERROR bloquante en --strict (mode d audit explicite). Ne fabrique jamais un verdict
# a partir d une decouverte vide : cette passe ne s execute qu apres le sys.exit(3)/(0) ci-dessus,
# donc uniquement quand `servers` est non-vide.
MCP_TOKEN_RE = re.compile(r"mcp__([A-Za-z0-9_-]+)__(?:\*|[A-Za-z0-9_-]+)")

def unknown_server_refs(text, servers):
    """Renvoie la liste (contexte, serveur_cite) des noms de serveur cites dans CE fichier
    (vf-mcp-tools et/ou tokens mcp__ deja presents dans tools:) qui ne resolvent DANS AUCUNE des
    sources decouvertes (comparaison insensible a la casse, egalite stricte — jamais un motif ni
    une sous-chaine, meme convention que named_tokens_for)."""
    resolved_lower = {s.lower() for s in servers}
    found = []
    req = named_request(text)
    if req is not None and req[0].lower() not in resolved_lower:
        found.append(("vf-mcp-tools", req[0]))
    span, lines = frontmatter_block(text)
    if span is not None:
        fm_start, fm_end = span
        for i in range(fm_start, fm_end):
            if re.match(r"^tools:\s*", lines[i]):
                for m in MCP_TOKEN_RE.finditer(lines[i]):
                    srv = m.group(1)
                    if srv.lower() not in resolved_lower:
                        found.append(("tools:", srv))
                break
    return found

unknown_found = False
for path in files:
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        continue
    base = os.path.basename(path)
    # Meme filtre d eligibilite que le reste du script (D-05/D-09) : en mode fichier unique, un
    # fichier ni flagge ni --force n est de toute facon jamais traite plus loin — ne pas le
    # signaler ici serait la seule coherence possible (le mode dossier est deja filtre en amont).
    if single and not force and not (has_flag(text) or has_named(text)):
        continue
    for ctx, srv in unknown_server_refs(text, servers):
        unknown_found = True
        msg = ("%s : serveur MCP '%s' (cite via %s) inconnu de toutes les sources decouvertes "
               "(scope projet %s, scope global %s) — WINDOWS #4." % (base, srv, ctx, mcp_json, claude_json))
        if strict:
            errline(msg)
        else:
            logline("WARNING: " + msg)

# --- 3bis. Mode --verify : LECTURE SEULE, aucune écriture (D-09, P-02) ---------------------------
# Relit le tools: final, réutilise TELS QUELS les calculs de want_tokens/existing/missing du mode
# injection ci-dessous (mêmes expressions, pas réinventées — named_tokens_for est appelee ici
# EXACTEMENT comme dans le bloc d injection, jamais recalculee autrement, D-05/lecon Phase 19). Ne
# rejoue JAMAIS --force a la place de l appelant : constater et rapporter, jamais reparer.
if verify:
    determined = False
    all_missing = []
    indeterminate = []
    for path in files:
        try:
            text = open(path, encoding="utf-8").read()
        except OSError:
            continue
        base = os.path.basename(path)

        if single and not force and not (has_flag(text) or has_named(text)):
            continue

        span, lines = frontmatter_block(text)
        if span is None:
            continue

        fm_start, fm_end = span
        tools_idx = None
        for i in range(fm_start, fm_end):
            if re.match(r"^tools:\s*", lines[i]):
                tools_idx = i
                break

        if tools_idx is None:
            # Pas de ligne tools: (herite tout) : aucun verdict possible sur ce fichier.
            continue

        # Meme calcul par fichier que le bloc d injection : mode NOMME si vf-mcp-tools est
        # present, sinon le mode JOKER existant (want_tokens).
        if has_named(text):
            req = named_request(text)
            if req is None:
                logline("%s : vf-mcp-tools malformee — aucune comparaison possible sur ce fichier." % base)
                continue
            file_want_tokens = named_tokens_for(text, servers)
            if not file_want_tokens:
                # Sous-etat INDETERMINE (pas malformee, pas manquante) : le serveur declare par
                # vf-mcp-tools n est pas resolu dans le lab. Ni conforme ni manquant : aucune
                # comparaison possible. Jamais un 0 conforme (D-05).
                errline("--verify : %s — serveur %s (vf-mcp-tools) absent du lab — verdict INDETERMINE (rien a comparer, distinct d un token manquant dans tools:)." % (base, req[0]))
                indeterminate.append(base)
                continue
        else:
            file_want_tokens = want_tokens

        line = lines[tools_idx]
        prefix = re.match(r"^tools:\s*", line).group(0)
        value = line[len(prefix):]
        existing = [tok.strip() for tok in value.split(",") if tok.strip()]
        missing = [tok for tok in file_want_tokens if tok not in existing]

        determined = True
        if missing:
            all_missing.append((base, missing))

    if indeterminate:
        # Priorite absolue : un sous-etat INDETERMINE ne peut jamais etre efface par un autre
        # fichier conforme de la meme invocation — un 0 rendu sans avoir tout compare serait le
        # faux vert que ce mode existe pour empecher.
        sys.exit(3)

    if not determined:
        errline("--verify : aucune cible determinee (pas de ligne tools: exploitable) — verdict INDETERMINE.")
        sys.exit(3)

    if all_missing:
        for base, missing in all_missing:
            errline("--verify : %s — serveur(s)/outil(s) MCP manquant(s) : %s" % (base, ", ".join(missing)))
        sys.exit(1)

    if strict and unknown_found:
        errline("--verify : conforme sur les tokens attendus, mais --strict signale au moins un serveur MCP inconnu cite (WINDOWS #4, voir ci-dessus).")
        sys.exit(1)

    logline("--verify : conforme, tous les serveurs/outils attendus sont presents.")
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

    # En mode fichier unique sans --force, exiger un des deux flags (securite : ne pas ouvrir un
    # agent planif/revue/audit par erreur). En mode dossier, le filtrage est deja fait.
    if single and not force and not (has_flag(text) or has_named(text)):
        logline("%s : ni vf-mcp-consumer ni vf-mcp-tools, pas de --force — ignore." % base)
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

    # Calcul des tokens souhaites POUR CE FICHIER : mode NOMME (D-05) si vf-mcp-tools est
    # present — le plus restrictif l emporte si les deux cles coexistent — sinon le mode JOKER
    # existant (want_tokens, tous les serveurs du lab).
    if has_named(text):
        if has_flag(text):
            logline("%s : vf-mcp-consumer ET vf-mcp-tools presents — mode NOMME retenu (moindre privilege)." % base)
        req = named_request(text)
        if req is None:
            logline("%s : vf-mcp-tools malformee (attendu grammaire <serveur>:<outil1>,<outil2>,...) — no-op." % base)
            continue
        file_want_tokens = named_tokens_for(text, servers)
        if not file_want_tokens:
            logline("%s : serveur %s (vf-mcp-tools) absent du lab — no-op silencieux." % (base, req[0]))
            continue
    else:
        file_want_tokens = want_tokens

    line = lines[tools_idx]
    prefix = re.match(r"^tools:\s*", line).group(0)
    value = line[len(prefix):]
    existing = [tok.strip() for tok in value.split(",") if tok.strip()]

    missing = [tok for tok in file_want_tokens if tok not in existing]
    if not missing:
        logline("%s : deja a jour (%s)." % (base, ", ".join(file_want_tokens)))
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
if strict and unknown_found:
    errline("--strict signale au moins un serveur MCP inconnu cite (WINDOWS #4, voir ci-dessus) — exit 1.")
    sys.exit(1)
sys.exit(0)
'
