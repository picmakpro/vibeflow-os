#!/usr/bin/env bash
# check-agents.sh — Lint machine de la conformité NATIVE des agents Claude Code (ADR-044).
# Ce qui passait silencieusement : agents sans description (jamais auto-routés), sans model,
# sans memory, skills déclarés jamais créés (hallucination), champs inconnus (typos), et —
# depuis la Phase 16 — des allowlists Agent(...) opaques : noms d'agents inventés, parenthèse
# non fermée, outils hors du set connu passaient tous --strict en vert.
#
# Portée réelle du lint Agent(...) (doc sub-agents, vérifiée 2026-07-27, citation verbatim) :
#   « The Agent(agent_type) allowlist syntax applies only to an agent running as the main
#   thread with `claude --agent`. In a subagent definition, listing Agent in tools lets that
#   subagent spawn subagents of its own [...], but any type list inside the parentheses is
#   ignored. » — https://code.claude.com/docs/en/sub-agents
# Concrètement : sur un agent posé sous .claude/agents/ (donc dispatché en SOUS-agent, jamais
# incarné en thread principal), le runtime IGNORE la liste de noms entre parenthèses — seul le
# fait que `Agent`/`Task` soit présent dans `tools:` compte pour le runtime. L'allowlist
# `Agent(x, y)` n'est donc PAS un bac à sable runtime pour ces agents : c'est un CONTRAT
# documenté, désormais enforcé PAR CE LINT (et seulement par lui). Elle redevient une vraie
# restriction runtime uniquement pour un agent incarné en thread principal (`claude --agent`).
#
# Référentiel : frontmatter officiel Claude Code (docs sub-agents, vérifié 2026-07-05) +
# charte VibeFlow (souveraineté : model explicite + memory explicite + skills câblés).
#
# Usage:
#   check-agents.sh                     # lint .claude/agents/*.md · exit 1 si non conforme
#   check-agents.sh --strict            # GATE init : + les skills déclarés doivent EXISTER
#   check-agents.sh --hook              # SessionStart : compact, exit 0 toujours
#   check-agents.sh --file <agent.md>   # un seul fichier (utilisé par guard-agent-write)
#   check-agents.sh --agents-dir=PATH   # défaut .claude/agents
#   check-agents.sh --allow-empty       # avec --strict : tolère une cible vide (sinon exit 3)
#   check-agents.sh --third-party-prefix=PFX     # répétable, défaut gsd- (accumule AU-DESSUS
#                                                 # du défaut ; --no-third-party-prefix avant pour repartir de zéro)
#   check-agents.sh --no-third-party-prefix      # vide la liste des préfixes tiers
#   check-agents.sh --resolve-agents=lenient|strict  # défaut lenient (monde ouvert) — toute
#                                                 # autre valeur est REJETÉE (exit 1, jamais un skip muet)
#   check-agents.sh --agent-registry-dir=PATH    # répétable, dirs de résolution supplémentaires
#
# BLOQUANT : frontmatter absent · name absent/invalide · description absente ·
#   model absent ou hors {sonnet,opus,haiku,fable,inherit,claude-*} · memory absente ou hors
#   {user,project,local} · effort/permissionMode/isolation/background/maxTurns invalides ·
#   allowlist Agent(...)/Task(...)/Bash(...)/etc malformée (parenthèse non fermée, allowlist
#   vide, entrée vide, espace avant la parenthèse, token hors charset).
# WARNING : skills absent · skill déclaré introuvable (ERROR en --strict) · description < 30c ·
#   tools absent (hérite tout) · champ inconnu · name ≠ nom de fichier · outil hors du set
#   fermé documenté (ERROR en --strict) · nom d'agent non résolu dans une allowlist Agent(...)
#   (reste WARNING même en --strict — voir plus bas ; ERROR seulement sous
#   --resolve-agents=strict) · `Agent` nu sans allowlist (« dispatch non cloisonné »).
#
# --strict NE DURCIT PAS la résolution de noms d'agents (contrairement au reste) : un lint par
# module (un `--agents-dir` à la fois) ne connaît jamais l'univers complet des agents — durcir
# ce point ferait passer en rouge des dizaines d'entrées parfaitement saines (cross-module,
# types natifs futurs, agents tiers). Le monde fermé est strictement OPT-IN via
# --resolve-agents=strict (+ --agent-registry-dir répétés pour élargir l'univers connu) — c'est
# la CI seule (union de tous les plugin/*/agents) qui a la légitimité de l'activer.
#
# --third-party-prefix (défaut "gsd-") ACCUMULE au-dessus du défaut à chaque répétition (le
# premier --no-third-party-prefix rencontré vide la liste avant d'accumuler à nouveau — ordre
# des arguments respecté, comme tout flag CLI répétable). Il a deux effets : (a) un FICHIER
# agent dont le name matche un préfixe n'est plus linté du tout pour la charte VibeFlow (ce
# n'est pas notre agent) ; (b) une ENTRÉE d'allowlist qui matche est réputée résolvable
# (silencieuse). Les deux sont comptés et imprimés SÉPARÉMENT dans le résumé (fichiers non
# lintés ≠ entrées d'allowlist résolues — deux choses différentes, jamais un skip muet ni un
# skip mal décrit).
#
# --hook n'imprime les avertissements QUE lorsqu'il y en a (une ligne compacte avec le compte,
# renvoyant vers l'invocation explicite pour le détail) ; silence total en régime nominal (0 erreur,
# 0 avertissement). Les erreurs, quand il y en a, priment et remplacent ce résumé — le mode reste
# minimal, jamais une énumération ligne par ligne au SessionStart (le signal complet est sur
# l'appel explicite/CI).
#
# Résolution d'un skill déclaré (UAT F2) : d'abord par NOM DE DOSSIER (.claude/skills/<s>/SKILL.md),
# sinon par le frontmatter `name:` des SKILL.md installés — un skill peut porter un name différent
# de son dossier (ex. module planning-core → skill `vf-planning`).
#
# Codes de sortie : 0 = conforme · 1 = non conforme (agents non conformes, OU invocation
#   invalide — ex. --resolve-agents=<valeur inconnue>) · 3 = INDÉTERMINÉ (--strict sur cible
#   absente/vide : aucun verdict rendu — un vert sans rien vérifier serait un faux vert, F13).

set -uo pipefail

AGENTS_DIR=".claude/agents"
SKILLS_DIR=".claude/skills"
STRICT=false
HOOK_MODE=false
ALLOW_EMPTY=false
SINGLE_FILE=""
THIRD_PARTY_PREFIXES="gsd-"
RESOLVE_AGENTS="lenient"
REGISTRY_DIRS=""

for arg in "$@"; do
  case "$arg" in
    --strict)         STRICT=true ;;
    --hook)           HOOK_MODE=true ;;
    --allow-empty)    ALLOW_EMPTY=true ;;
    --file)           : ;; # valeur au prochain arg — géré ci-dessous
    --agents-dir=*)   AGENTS_DIR="${arg#*=}" ;;
    --skills-dir=*)   SKILLS_DIR="${arg#*=}" ;;
    --third-party-prefix=*)
      v="${arg#*=}"
      if [ -z "$THIRD_PARTY_PREFIXES" ]; then THIRD_PARTY_PREFIXES="$v"; else THIRD_PARTY_PREFIXES="$THIRD_PARTY_PREFIXES:$v"; fi
      ;;
    --no-third-party-prefix) THIRD_PARTY_PREFIXES="" ;;
    --resolve-agents=*) RESOLVE_AGENTS="${arg#*=}" ;;
    --agent-registry-dir=*)
      v="${arg#*=}"
      if [ -z "$REGISTRY_DIRS" ]; then REGISTRY_DIRS="$v"; else REGISTRY_DIRS="$REGISTRY_DIRS:$v"; fi
      ;;
    -h|--help)        grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  esac
done
# --file <path> (2 args)
prev=""
for arg in "$@"; do
  [ "$prev" = "--file" ] && SINGLE_FILE="$arg"
  prev="$arg"
done

# --resolve-agents ne connaît QUE lenient|strict — toute autre valeur (typo type "stricts")
# dégraderait silencieusement le gate monde fermé en vert si on la laissait passer (le code
# n'aurait alors testé que == "strict" et serait tombé en lenient sans un mot). Rejet explicite,
# exit 1 : jamais un skip muet, à l'image du contrat F13 déjà appliqué plus bas (cible vide).
case "$RESOLVE_AGENTS" in
  lenient|strict) ;;
  *)
    echo "[check-agents] ✗ --resolve-agents invalide '$RESOLVE_AGENTS' — attendu lenient|strict" >&2
    exit 1
    ;;
esac

# ADR-054 : stub Microsoft Store — `python3` présent dans le PATH mais inerte. Détection par
# CHEMIN (zéro spawn), repli `python` ; sinon message + exit 0 (advisory, comme avant).
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else echo "[check-agents] python3 requis" >&2; exit 0; fi ;;
esac

VF_AGENTS_DIR="$AGENTS_DIR" VF_SKILLS_DIR="$SKILLS_DIR" VF_STRICT="$STRICT" \
VF_HOOK="$HOOK_MODE" VF_SINGLE="$SINGLE_FILE" VF_ALLOW_EMPTY="$ALLOW_EMPTY" \
VF_THIRD_PARTY_PREFIXES="$THIRD_PARTY_PREFIXES" VF_RESOLVE_AGENTS="$RESOLVE_AGENTS" \
VF_REGISTRY_DIRS="$REGISTRY_DIRS" "$PYBIN" -c "
import glob, os, re, sys

agents_dir = os.environ[\"VF_AGENTS_DIR\"]
skills_dir = os.environ[\"VF_SKILLS_DIR\"]
strict = os.environ[\"VF_STRICT\"] == \"true\"
hook = os.environ[\"VF_HOOK\"] == \"true\"
allow_empty = os.environ[\"VF_ALLOW_EMPTY\"] == \"true\"
single = os.environ[\"VF_SINGLE\"]
third_party_prefixes = [p for p in os.environ.get(\"VF_THIRD_PARTY_PREFIXES\", \"\").split(\":\") if p]
resolve_agents_strict = os.environ.get(\"VF_RESOLVE_AGENTS\", \"lenient\") == \"strict\"
registry_dirs = [p for p in os.environ.get(\"VF_REGISTRY_DIRS\", \"\").split(\":\") if p]

# Champs officiels Claude Code (docs sub-agents, 2026-07-05) — base du lint.
# + conventions VibeFlow : vf-internal (worker interne — pas de commande d'incarnation, cf. Pattern 12) ;
#   vf-mcp-consumer (agent exécutant recevant l'allowlist MCP dérivée du lab à l'install, ADR-051) ;
#   vf-mcp-tools (allowlist MCP NOMMÉE — un serveur, une liste d'outils explicites — consommée par
#   le script d'injection du module dev-orchestrator ; coexiste avec vf-mcp-consumer sans le remplacer).
KNOWN = {\"name\", \"description\", \"tools\", \"disallowedTools\", \"model\", \"permissionMode\",
         \"maxTurns\", \"skills\", \"mcpServers\", \"hooks\", \"memory\", \"background\", \"effort\",
         \"isolation\", \"color\", \"initialPrompt\", \"vf-internal\", \"vf-mcp-consumer\", \"vf-mcp-tools\"}
MODELS = {\"sonnet\", \"opus\", \"haiku\", \"fable\", \"inherit\"}
MEMORY = {\"user\", \"project\", \"local\"}
EFFORT = {\"low\", \"medium\", \"high\", \"xhigh\", \"max\"}
PERM = {\"default\", \"acceptEdits\", \"auto\", \"dontAsk\", \"bypassPermissions\", \"plan\", \"manual\"}
NOT_AGENTS = {\"contracts.md\", \"README.md\", \"AGENTS.md\"}

# Types natifs Claude Code (doc code.claude.com/docs/en/sub-agents, verifiee 2026-07-27).
# ATTENTION rouille : Explore/Plan requierent min-version 2.1.198 ; fork requiert
# CLAUDE_CODE_FORK_SUBAGENT=1 (pas actif par defaut) ; CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1
# et CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS=1 peuvent desactiver tout ou partie de cette liste ;
# un agent utilisateur peut surcharger un nom natif. C'est PRECISEMENT pourquoi \"nom non resolu\"
# reste un WARNING (jamais une ERREUR par defaut) : la rouille de cette liste degrade en jaune.
NATIVE_TYPES = {\"explore\", \"plan\", \"general-purpose\", \"statusline-setup\", \"claude-code-guide\", \"fork\"}

# Set ferme des identifiants d'outils (doc code.claude.com/docs/en/tools-reference, verifiee
# 2026-07-27 — 43 identifiants + alias Task confirmes mot pour mot, aucun ecart).
TOOL_NAMES = {
    \"Agent\", \"Artifact\", \"AskUserQuestion\", \"Bash\", \"CronCreate\", \"CronDelete\", \"CronList\",
    \"Edit\", \"EndConversation\", \"EnterPlanMode\", \"EnterWorktree\", \"ExitPlanMode\", \"ExitWorktree\",
    \"Glob\", \"Grep\", \"ListMcpResourcesTool\", \"LSP\", \"Monitor\", \"NotebookEdit\", \"PowerShell\",
    \"PushNotification\", \"Read\", \"ReadMcpResourceTool\", \"RemoteTrigger\", \"ReportFindings\",
    \"ScheduleWakeup\", \"SendMessage\", \"SendUserFile\", \"ShareOnboardingGuide\", \"Skill\", \"TaskCreate\",
    \"TaskGet\", \"TaskList\", \"TaskOutput\", \"TaskStop\", \"TaskUpdate\", \"TodoWrite\", \"ToolSearch\",
    \"WaitForMcpServers\", \"WebFetch\", \"WebSearch\", \"Workflow\", \"Write\",
}
# Task = alias legacy d'Agent depuis Claude Code v2.1.63 — traite a l'identique partout.
AGENT_TOOL_NAMES = {\"Agent\", \"Task\"}

errors, warnings = [], []
# Deux compteurs DISTINCTS (jamais un skip mal decrit) : thirdparty_files_total = fichiers
# .md entiers exclus du lint (name matche un prefixe tiers) ; thirdparty_entries_total =
# entrees d'allowlist Agent(...)/Task(...) reputees resolvables via un prefixe tiers. Ce
# sont deux populations differentes — un agent peut avoir 0 fichier tiers et 30 entrees
# tierces dans ses allowlists, ou l'inverse.
thirdparty_files_total = 0
thirdparty_entries_total = 0

def parse_frontmatter(text):
    lines = text.split(\"\n\")
    if not lines or lines[0].strip() != \"---\":
        return None
    fm, i = {}, 1
    current_key = None
    while i < len(lines):
        line = lines[i]
        if line.strip() == \"---\":
            return fm
        m = re.match(r\"^([A-Za-z_-]+):\s*(.*)$\", line)
        if m:
            current_key = m.group(1)
            val = m.group(2).strip()
            if val.startswith(\"[\") and val.endswith(\"]\"):
                items = [x.strip().strip(chr(34)).strip(chr(39)) for x in val[1:-1].split(\",\") if x.strip()]
                fm[current_key] = items
            elif val == \"\" or val == \">\" or val == \"|\":
                # val vide : typage DIFFERE (str par defaut, converti en liste a la 1re puce) —
                # un plain scalar multi-ligne indente est du YAML valide (etait perdu avant).
                fm[current_key] = \"\" if val == \"\" else val
            else:
                # Dequotage des scalaires : name: \"x\" / model: 'sonnet' sont du YAML valide
                # (parfois OBLIGATOIRE, ex. description contenant ': ') — le runtime les accepte.
                if len(val) >= 2 and val[0] == val[-1] and val[0] in (chr(34), chr(39)):
                    val = val[1:-1]
                fm[current_key] = val
        elif current_key is not None:
            item = re.match(r\"^\s+-\s+(.+?)(\s+#.*)?$\", line)
            if item and isinstance(fm.get(current_key), list):
                fm[current_key].append(item.group(1).strip().strip(chr(34)).strip(chr(39)))
            elif item and fm.get(current_key) == \"\":
                fm[current_key] = [item.group(1).strip().strip(chr(34)).strip(chr(39))]
            elif line.startswith(\"  \") and isinstance(fm.get(current_key), str):
                fm[current_key] = (fm[current_key] + \" \" + line.strip()).strip()
        i += 1
    return None  # frontmatter jamais ferme

def frontmatter_lines(text):
    \"\"\"Retourne les lignes BRUTES entre les deux '---' (pour la re-tokenisation des
    allowlists Agent(...), qui doit repartir de la ligne source, jamais de fm[] deja mangle).\"\"\"
    lines = text.split(\"\n\")
    if not lines or lines[0].strip() != \"---\":
        return None
    for idx in range(1, len(lines)):
        if lines[idx].strip() == \"---\":
            return lines[1:idx]
    return None

_KEY_RE = re.compile(r\"^([A-Za-z_-]+):\s*(.*)$\")

def extract_raw_field(fmlines, key):
    \"\"\"Extrait la valeur BRUTE (non tokenisee) d'un champ tools:/disallowedTools:.
    Retourne (mode, raw) : mode='block' -> raw est deja une liste de tokens (puces YAML) ;
    mode in ('flow','scalar') -> raw est une chaine brute a re-tokeniser a profondeur de
    parentheses. (None, None) si la cle est absente. Mirrore le comportement de continuation
    de parse_frontmatter (ligne indentee >= 2 espaces) — une continuation NON indentee est
    perdue ici EXACTEMENT comme dans parse_frontmatter (la perte se traduit en parenthese
    non fermee au niveau du tokenizer, ce qui est le comportement voulu).
    \"\"\"
    if fmlines is None:
        return None, None
    n = len(fmlines)
    for idx in range(n):
        m = _KEY_RE.match(fmlines[idx])
        if not (m and m.group(1) == key):
            continue
        val = m.group(2).strip()
        k = idx + 1
        if val == \"\":
            bullets = []
            while k < n:
                # Une ligne vide (ou toute ligne non-puce qui n'ouvre pas une nouvelle
                # cle) est TOLEREE au milieu du bloc — a l'image de parse_frontmatter,
                # qui ne casse jamais sur une ligne vide. Seule une nouvelle cle:
                # (_KEY_RE) marque la fin LEGITIME du bloc. Avant ce correctif, un
                # simple 'break' ici faisait perdre SILENCIEUSEMENT toute puce suivant
                # une ligne vide (defaut 2, F13-like : zero warning sur l'entree perdue).
                if _KEY_RE.match(fmlines[k]):
                    break
                item = re.match(r\"^\s+-\s+(.+?)(\s+#.*)?$\", fmlines[k])
                if item:
                    bullets.append(item.group(1).strip())
                k += 1
            if bullets:
                return \"block\", bullets
            parts = []
            while k < n and fmlines[k].startswith(\"  \") and fmlines[k].strip() and not _KEY_RE.match(fmlines[k]):
                parts.append(fmlines[k].strip())
                k += 1
            return \"scalar\", \" \".join(parts)
        else:
            parts = [val]
            while k < n and fmlines[k].startswith(\"  \") and fmlines[k].strip() and not _KEY_RE.match(fmlines[k]):
                parts.append(fmlines[k].strip())
                k += 1
            raw = \" \".join(parts).strip()
            if raw.startswith(\"[\"):
                return \"flow\", raw
            return \"scalar\", raw
    return None, None

def split_depth(raw):
    \"\"\"Split a profondeur de parentheses (jamais un split(',') naif) — c'est ce qui
    laisse 'Agent(vf-coder, vf-reviewer)' intact comme UN token. Retourne (tokens, depth) ou
    depth est le solde ouvertures-fermetures EN SIGNE (0 = equilibre ; > 0 = il manque des
    fermetures ; < 0 = il y a des fermetures EN TROP, ex. 'Agent(a))') — la distinction de
    signe permet a l'appelant de ne pas dire \"non fermee\" quand le vrai probleme est l'inverse.\"\"\"
    tokens, depth, cur = [], 0, []
    for ch in raw:
        if ch == \"(\":
            depth += 1
            cur.append(ch)
        elif ch == \")\":
            depth -= 1
            cur.append(ch)
        elif ch == \",\" and depth == 0:
            tokens.append(\"\".join(cur))
            cur = []
        else:
            cur.append(ch)
    tokens.append(\"\".join(cur))
    return tokens, depth

def dequote_scalar(s):
    \"\"\"Retire UNE seule paire de guillemets englobante (\" ou ') — calque exact du
    dequotage deja applique aux scalaires par parse_frontmatter (l.195-196). Sans ca,
    'tools: \"Read, Write, Agent(vf-coder)\"' (YAML valide) etait tokenise caracteres-
    litteraux-compris et produisait de faux BLOQUANTS (charset, parenthese non fermee).\"\"\"
    if len(s) >= 2 and s[0] == s[-1] and s[0] in (chr(34), chr(39)):
        return s[1:-1]
    return s

def tokenize_field(mode, raw):
    \"\"\"mode='block' : raw deja une liste de tokens individuels (puces YAML).
    mode in ('flow','scalar') : raw est une chaine — on la dequote d'abord (voir
    dequote_scalar), on retire les crochets [ ] de la flow list puis on decoupe a
    profondeur de parentheses. Retourne (tokens, depth) — voir split_depth pour le signe.\"\"\"
    if mode == \"block\":
        return [dequote_scalar(t) for t in raw], 0
    s = dequote_scalar(raw.strip())
    if s.startswith(\"[\") and s.endswith(\"]\"):
        s = s[1:-1]
    return split_depth(s)

def analyze_token(raw_tok, field, base):
    \"\"\"Analyse structurelle d'UN token d'allowlist deja isole par tokenize_field.
    Retourne (tool_name, agent_names) : agent_names est None si pas de parametres,
    [] si allowlist vide 'Agent()', une liste sinon. Ajoute les erreurs de SYNTAXE
    (classe non affectee par --strict, toujours bloquante) a la liste errors.\"\"\"
    tok = raw_tok.strip()
    if tok == \"\":
        errors.append(f\"{base} : {field} — entree d'allowlist vide (virgule orpheline, ex. 'a,,b')\")
        return None, None
    m_space = re.match(r\"^(\S+)\s+\(\", tok)
    if m_space:
        errors.append(f\"{base} : {field} — espace avant la parenthese dans '{tok}' (attendu Nom(args))\")
        return None, None
    m = re.match(r\"^([A-Za-z0-9_-]+)\((.*)$\", tok, re.S)
    if not m:
        # pas de parenthese : nom d'outil seul (Read, Bash, ...) OU forme MCP a joker TERMINAL
        # 'mcp__<serveur>__*' — la forme sure documentee en tete d'inject-mcp-tools.sh ADR-051
        # (\"on injecte donc, par serveur, la forme sure mcp__<serveur>__*\"). Aucun joker ailleurs :
        # ni en tete, ni en milieu de chaine, ni dans le nom du serveur, ni suivi d'un suffixe
        # (mcp__*, mcp__Xcode*MCP__*, mcp__XcodeBuildMCP__*_sim restent hors charset).
        if not (re.fullmatch(r\"[A-Za-z0-9_-]+\", tok) or re.fullmatch(r\"mcp__[A-Za-z0-9_-]+__[*]\", tok)):
            errors.append(f\"{base} : {field} — token hors charset attendu '{tok}'\")
            return None, None
        return tok, None
    name, rest = m.group(1), m.group(2)
    if not rest.endswith(\")\"):
        errors.append(f\"{base} : {field} — parenthese non fermee dans '{tok}'\")
        return name, None
    inner = rest[:-1]
    if inner.strip() == \"\":
        errors.append(f\"{base} : {field} — allowlist vide '{name}()'\")
        return name, []
    agent_names = [a.strip() for a in inner.split(\",\") if a.strip() != \"\"]
    if len(agent_names) != len([a for a in inner.split(\",\")]):
        errors.append(f\"{base} : {field} — entree vide dans l'allowlist de '{name}(...)'\")
    return name, agent_names

def resolve_agent_name(name, agents_dir_local, registry_dirs_local, prefixes):
    low = name.lower()
    if low in NATIVE_TYPES:
        return \"native\"
    for pfx in prefixes:
        if pfx and name.startswith(pfx):
            return \"thirdparty\"
    if os.path.isfile(os.path.join(agents_dir_local, name + \".md\")):
        return \"resolved\"
    for rd in registry_dirs_local:
        if rd and os.path.isfile(os.path.join(rd, name + \".md\")):
            return \"resolved\"
    return \"unresolved\"

def lint_tool_field(base, field, mode, raw, do_agent_resolution):
    \"\"\"Applique le tokenizer + la classification a un champ tools:/disallowedTools:.\"\"\"
    global thirdparty_entries_total
    tokens, depth = tokenize_field(mode, raw)
    if depth > 0:
        errors.append(f\"{base} : {field} — parenthese non fermee (il manque {depth} fermeture(s), allowlist tronquee ou mal formee, verifier l'indentation de la continuation)\")
        return
    if depth < 0:
        errors.append(f\"{base} : {field} — parenthese fermante en trop ({-depth} de trop, verifier '{raw}')\")
        return
    bare_agent = False
    for raw_tok in tokens:
        name, agent_names = analyze_token(raw_tok, field, base)
        if name is None:
            continue
        is_agent_tool = name in AGENT_TOOL_NAMES
        if name not in TOOL_NAMES and not is_agent_tool and not name.startswith(\"mcp__\"):
            msg = f\"{base} : {field} — outil hors du set connu '{name}' (typo ? nouvel outil non encore reference ?)\"
            (errors if strict else warnings).append(msg)
        if is_agent_tool:
            if agent_names is None:
                if field == \"tools\":
                    bare_agent = True
            elif do_agent_resolution:
                for a in agent_names:
                    verdict = resolve_agent_name(a, agents_dir, registry_dirs, third_party_prefixes)
                    if verdict == \"thirdparty\":
                        thirdparty_entries_total += 1
                    elif verdict == \"unresolved\":
                        msg = f\"{base} : {field} — nom d'agent non resolu '{a}' (ni type natif, ni fichier {agents_dir}/{a}.md, ni registre)\"
                        if resolve_agents_strict:
                            errors.append(msg + \" [--resolve-agents=strict]\")
                        else:
                            warnings.append(msg)
    if bare_agent:
        warnings.append(f\"{base} : tools — 'Agent' sans allowlist parenthesee = dispatch non cloisonne\")

# UAT F2 : carte frontmatter name: → chemin SKILL.md, construite paresseusement UNE fois.
_skill_name_map = None
def skill_name_map():
    global _skill_name_map
    if _skill_name_map is None:
        _skill_name_map = {}
        for sk_path in sorted(glob.glob(os.path.join(skills_dir, \"*\", \"SKILL.md\"))):
            try:
                sk_fm = parse_frontmatter(open(sk_path, encoding=\"utf-8-sig\").read())
            except OSError:
                continue
            if not sk_fm:
                continue
            sk_name = sk_fm.get(\"name\")
            if isinstance(sk_name, str) and sk_name:
                _skill_name_map.setdefault(sk_name, sk_path)
    return _skill_name_map

def resolve_skill(s):
    sk = os.path.join(skills_dir, s, \"SKILL.md\")
    if os.path.isfile(sk):
        return sk
    return skill_name_map().get(s, \"\")

def agent_display_name(path, text):
    fm = parse_frontmatter(text)
    if fm and isinstance(fm.get(\"name\"), str) and fm.get(\"name\"):
        return fm[\"name\"]
    return os.path.basename(path)[:-3]

def bare_tokens(fmlines, field):
    \"\"\"Ensemble des tokens SANS parenthese d'un champ tools:/disallowedTools: — reutilise le
    MEME tokenizer a profondeur de parentheses que le lint principal (extract_raw_field +
    tokenize_field), jamais un second parseur. Un champ absent ou une allowlist mal formee
    (depth != 0) rend un ensemble vide plutot que de lever : ce garde-fou structurel ne doit
    jamais masquer les erreurs de syntaxe deja levees ailleurs par lint_tool_field.\"\"\"
    mode, raw = extract_raw_field(fmlines, field)
    if mode is None:
        return set()
    tokens, depth = tokenize_field(mode, raw)
    if depth != 0:
        return set()
    return {t.strip() for t in tokens if t.strip() and \"(\" not in t}

def check_file(path):
    base = os.path.basename(path)
    try:
        text = open(path, encoding=\"utf-8-sig\").read()   # utf-8-sig : tolere un BOM d origine externe
    except OSError as e:
        errors.append(f\"{base} : illisible ({e})\")
        return
    fm = parse_frontmatter(text)
    if fm is None:
        errors.append(f\"{base} : AUCUN frontmatter YAML (--- ... ---) — cet agent est invisible pour le routage natif\")
        return

    name = fm.get(\"name\")
    if not name or not isinstance(name, str):
        errors.append(f\"{base} : champ requis manquant — name\")
    else:
        if not re.fullmatch(r\"[a-z0-9-]+\", name):
            errors.append(f\"{base} : name invalide ({name}) — lettres minuscules et tirets uniquement\")
        if name != base[:-3]:
            warnings.append(f\"{base} : name ({name}) different du nom de fichier — source de confusion\")

    desc = fm.get(\"description\")
    if not desc or (isinstance(desc, str) and not desc.strip()) or desc == []:
        errors.append(f\"{base} : champ requis manquant — description (sans elle, agent JAMAIS auto-route)\")
    elif isinstance(desc, str) and len(desc) < 30:
        warnings.append(f\"{base} : description trop courte ({len(desc)}c) pour un routage fiable — inclure quand utiliser cet agent\")

    model = fm.get(\"model\")
    if not model:
        errors.append(f\"{base} : model absent — souverainete modele requise (sonnet|opus|haiku|fable|inherit)\")
    elif model not in MODELS and not re.fullmatch(r\"claude-[a-z0-9.-]+\", str(model)):
        errors.append(f\"{base} : model invalide ({model}) — attendu sonnet|opus|haiku|fable|inherit|claude-<id>\")

    memory = fm.get(\"memory\")
    if not memory:
        errors.append(f\"{base} : memory absente — scope memoire requis (user|project|local)\")
    elif memory not in MEMORY:
        errors.append(f\"{base} : memory invalide ({memory}) — attendu user|project|local\")

    # effort EXIGE (zone 6, Phase 24 — ADR-044 etendu) : le champ etait valide S IL ETAIT
    # PRESENT, donc omissible en silence — 0 des 25 agents livres le portait. Le bareme est
    # PAR ROLE (pilotage et jugement haut, execution mecanique bas, jamais uniformement) :
    # une omission n est pas un defaut par defaut, c est un role non declare. Meme forme a
    # deux branches que le bloc model ci-dessus, et MEME perimetre : les agents ecartes par
    # --third-party-prefix ne passent jamais ici (skip en amont, boucle principale).
    effort = fm.get(\"effort\")
    if not effort:
        errors.append(f\"{base} : effort absent — bareme par role requis (low|medium|high|xhigh|max)\")
    elif effort not in EFFORT:
        errors.append(f\"{base} : effort invalide ({effort}) — attendu low|medium|high|xhigh|max\")
    pm = fm.get(\"permissionMode\")
    if pm and pm not in PERM:
        errors.append(f\"{base} : permissionMode invalide ({pm})\")
    iso = fm.get(\"isolation\")
    # Issue #38 : \`isolation: worktree\` est INTERDIT dans le frontmatter d'un agent DISTRIBUE,
    # tant que ses deux preconditions ne le sont pas elles-memes.
    #   1. Le worktree du harness fork depuis la branche PAR DEFAUT, pas depuis le HEAD courant.
    #      La precondition qui corrige ca — \`worktree.baseRef: \"head\"\` — vit dans le settings du
    #      poste ; l'engine ne la pose NULLE PART chez l'utilisateur (verifie : zero occurrence de
    #      \`baseRef\` dans vibeflow-update.sh, merge-hooks.sh et l'installeur). Elle a ete posee
    #      dans le settings local de CE repo en Phase 27, et les 13 agents ont ete distribues sans
    #      elle : le worker atterrit sur une branche technique repartant de la branche par defaut,
    #      sans aucun fichier du mandat.
    #   2. Meme avec baseRef corrige, rien ne ramene les commits du worker vers la branche de la
    #      mission — le merge affirme n'est implemente nulle part en amont (open-gsd/gsd-core#3302,
    #      deja le motif du refus ecrit de claude_orchestration en Phase 27).
    # L'isolation reste une decision de DISPATCH du manager (team-kernel.md §Parallelisme), jamais
    # une propriete du worker : portee par le frontmatter elle devient inconditionnelle et retire au
    # manager l'arbitrage que sa propre doctrine lui confie.
    # Lever ce gate demande de distribuer la precondition ET de prouver le retour des commits — pas
    # de supprimer ces lignes.
    if iso == \"worktree\":
        errors.append(f\"{base} : isolation worktree interdite dans un agent distribue (issue #38) — le worktree fork depuis la branche par defaut, la precondition worktree.baseRef n'est pas distribuee, et rien ne ramene les commits. L'isolation est une decision de dispatch du manager.\")
    elif iso:
        errors.append(f\"{base} : isolation invalide ({iso}) — aucune valeur n'est admise dans un agent distribue (voir issue #38)\")
    bg = fm.get(\"background\")
    if bg and str(bg) not in (\"true\", \"false\"):
        errors.append(f\"{base} : background invalide ({bg}) — true|false\")
    mt = fm.get(\"maxTurns\")
    if mt and not str(mt).isdigit():
        errors.append(f\"{base} : maxTurns invalide ({mt}) — entier attendu\")

    skills = fm.get(\"skills\")
    # Gate anti-contournement : skills en chaine plate (skills: a, b) = YAML valide → normaliser
    # en liste, sinon existence/budget/disable-model-invocation etaient silencieusement sautes.
    if isinstance(skills, str) and skills.strip() and skills not in (\">\", \"|\"):
        skills = [s.strip() for s in skills.split(\",\") if s.strip()]
    if not skills:
        warnings.append(f\"{base} : aucun skill cable — agent sans expertise injectee (recommande : skills:)\")
    elif isinstance(skills, list) and os.path.isdir(skills_dir):
        # Budget de prechargement (ADR-044) : skills: injecte le SKILL.md ENTIER au startup
        # de l agent (verite runtime). Precharger = petit et systematique ; le on-demand est
        # le defaut natif (description seule au startup, contenu a l invocation).
        preload_warn = int(os.environ.get(\"VF_PRELOAD_WARN\", \"200\"))
        preload_max = int(os.environ.get(\"VF_PRELOAD_MAX\", \"1200\"))
        total_lines = 0
        for s in skills:
            sk = resolve_skill(s)
            if not sk:
                msg = f\"{base} : skill declare introuvable — {s} (ni dossier .claude/skills/{s}/, ni frontmatter name: correspondant ; le creer via skill-creator, jamais le laisser en promesse)\"
                (errors if strict else warnings).append(msg)
                continue
            try:
                sk_text = open(sk, encoding=\"utf-8\").read()
            except OSError:
                continue
            n = sk_text.count(\"\n\") + 1
            total_lines += n
            if re.search(r\"^disable-model-invocation:\s*true\", sk_text, re.M):
                errors.append(f\"{base} : skill {s} a disable-model-invocation:true — NON prechargeable (restriction runtime), le retirer de skills:\")
            elif re.search(r\"^context:\s*fork\", sk_text, re.M):
                warnings.append(f\"{base} : skill {s} est context:fork (deja isole) — le precharger est contre-productif, laisser on-demand\")
            elif n > preload_warn:
                warnings.append(f\"{base} : skill {s} precharge = {n} lignes (> {preload_warn}) — candidat on-demand (le contenu ENTIER entre au startup)\")
        if total_lines > preload_max:
            errors.append(f\"{base} : budget de prechargement depasse — {total_lines} lignes cumulees (> {preload_max}, VF_PRELOAD_MAX) : basculer les gros skills en on-demand\")

    if \"tools\" not in fm:
        warnings.append(f\"{base} : tools absent — herite de TOUS les outils (restreindre si agent en lecture/analyse)\")

    fmlines = frontmatter_lines(text)
    for field, do_resolution in ((\"tools\", True), (\"disallowedTools\", False)):
        mode, raw = extract_raw_field(fmlines, field)
        if mode is None:
            continue
        lint_tool_field(base, field, mode, raw, do_resolution)

    # Regle anti-regression (Phase 20) : memory: reinjecte SILENCIEUSEMENT Write+Edit au
    # runtime par-dessus l'allowlist tools: (contrat Claude Code confirme par sonde). Un agent
    # qui porte memory: et dont le tools: (declare) omet Write ET Edit DOIT fermer ce canal
    # explicitement via disallowedTools — sinon rien n'empeche un futur juge/reviewer de naitre
    # sans sa barriere. Purement structurel : reutilise bare_tokens() (meme tokenizer), aucune
    # analyse de texte. Warning en defaut, ERREUR en --strict — meme regime que les autres
    # classes structurelles de ce script (outil hors set connu, skill introuvable) : visible au
    # SessionStart des qu'il y en a un (D-21), bloquant sur l'appel explicite/CI --strict.
    if memory and \"tools\" in fm:
        tools_tokens = bare_tokens(fmlines, \"tools\")
        if \"Write\" not in tools_tokens and \"Edit\" not in tools_tokens:
            disallowed_tokens = bare_tokens(fmlines, \"disallowedTools\")
            if not (\"Write\" in disallowed_tokens and \"Edit\" in disallowed_tokens):
                msg = f\"{base} : memory: + tools: sans Write/Edit exige disallowedTools: Write, Edit (memory: reinjecte silencieusement ces outils au runtime — barriere structurelle requise)\"
                (errors if strict else warnings).append(msg)

    for k in fm:
        if k not in KNOWN:
            warnings.append(f\"{base} : champ inconnu du runtime — {k} (typo ? champ invente ? verifier la doc)\")

if single:
    if os.path.isfile(single):
        check_file(single)
    else:
        errors.append(f\"fichier introuvable : {single}\")
else:
    files = sorted(glob.glob(os.path.join(agents_dir, \"*.md\")))
    files = [f for f in files if os.path.basename(f) not in NOT_AGENTS]
    if not files:
        # Contrat de decouverte (F13, vacuous green) : en --strict, zero cible = zero verdict.
        # exit 3 = INDETERMINE, distinct de 0 = CONFORME. --allow-empty pour les cas legitimes.
        if strict and not allow_empty and not hook:
            print(f\"[check-agents] ✗ INDETERMINE : aucun agent dans {agents_dir} — cible absente ou vide, aucun verdict rendu (--allow-empty pour tolerer)\")
            sys.exit(3)
        if not hook:
            print(f\"[check-agents] aucun agent dans {agents_dir} — rien a verifier\")
        sys.exit(0)
    for f in files:
        try:
            ftext = open(f, encoding=\"utf-8-sig\").read()
        except OSError as e:
            errors.append(f\"{os.path.basename(f)} : illisible ({e})\")
            continue
        # --third-party-prefix : un FICHIER dont le name matche n'est plus linte pour la
        # charte VibeFlow (ce n'est pas notre agent) — compte dans le resume, jamais un skip muet.
        dname = agent_display_name(f, ftext)
        matched_prefix = next((p for p in third_party_prefixes if p and dname.startswith(p)), None)
        if matched_prefix:
            thirdparty_files_total += 1
            continue
        check_file(f)

n_err, n_warn = len(errors), len(warnings)
if hook:
    if n_err:
        print(f\"[check-agents] ✗ {n_err} agent(s) non conforme(s) :\")
        for e in errors:
            print(f\"  - {e}\")
        print(\"  Corriger le frontmatter puis relancer : bash .claude/scripts/check-agents.sh\")
    elif n_warn:
        # D-21 : le hook trouvait desormais un perimetre reel (D-18/D-19) sans jamais le dire —
        # faux vert silencieux. Une ligne compacte, jamais une enumeration (le mode reste minimal) ;
        # silence total inchange quand n_err == 0 ET n_warn == 0 (regime nominal, cf. T56/T16).
        print(f\"[check-agents] ⚠ {n_warn} avertissement(s) — detail : bash .claude/scripts/check-agents.sh\")
    sys.exit(0)

for w in warnings:
    print(f\"  ⚠ {w}\")
if thirdparty_files_total or thirdparty_entries_total:
    pfx_str = ','.join(third_party_prefixes) if third_party_prefixes else '—'
    print(f\"[check-agents] {thirdparty_files_total} fichier(s) agent tiers non linte(s) · {thirdparty_entries_total} entree(s) d'allowlist tierce(s) resolue(s) (prefixe(s) : {pfx_str})\")
if n_err:
    print(f\"[check-agents] ✗ {n_err} non-conformite(s) bloquante(s) :\")
    for e in errors:
        print(f\"  ✗ {e}\")
    sys.exit(1)
print(f\"[check-agents] ✓ agents conformes (natif + charte VibeFlow){' · ' + str(n_warn) + ' warning(s)' if n_warn else ''}\")
sys.exit(0)
"
