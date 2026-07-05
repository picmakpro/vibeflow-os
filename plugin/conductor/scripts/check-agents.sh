#!/usr/bin/env bash
# check-agents.sh — Lint machine de la conformité NATIVE des agents Claude Code (ADR-044).
# Ce qui passait silencieusement : agents sans description (jamais auto-routés), sans model,
# sans memory, skills déclarés jamais créés (hallucination), champs inconnus (typos).
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
#
# BLOQUANT : frontmatter absent · name absent/invalide · description absente ·
#   model absent ou hors {sonnet,opus,haiku,fable,inherit,claude-*} · memory absente ou hors
#   {user,project,local} · effort/permissionMode/isolation/background/maxTurns invalides.
# WARNING : skills absent · skill déclaré introuvable (ERROR en --strict) · description < 30c ·
#   tools absent (hérite tout) · champ inconnu · name ≠ nom de fichier.
#
# Codes de sortie : 0 = conforme · 1 = non conforme

set -uo pipefail

AGENTS_DIR=".claude/agents"
SKILLS_DIR=".claude/skills"
STRICT=false
HOOK_MODE=false
SINGLE_FILE=""

for arg in "$@"; do
  case "$arg" in
    --strict)         STRICT=true ;;
    --hook)           HOOK_MODE=true ;;
    --file)           : ;; # valeur au prochain arg — géré ci-dessous
    --agents-dir=*)   AGENTS_DIR="${arg#*=}" ;;
    --skills-dir=*)   SKILLS_DIR="${arg#*=}" ;;
    -h|--help)        grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  esac
done
# --file <path> (2 args)
prev=""
for arg in "$@"; do
  [ "$prev" = "--file" ] && SINGLE_FILE="$arg"
  prev="$arg"
done

command -v python3 >/dev/null 2>&1 || { echo "[check-agents] python3 requis" >&2; exit 0; }

VF_AGENTS_DIR="$AGENTS_DIR" VF_SKILLS_DIR="$SKILLS_DIR" VF_STRICT="$STRICT" \
VF_HOOK="$HOOK_MODE" VF_SINGLE="$SINGLE_FILE" python3 -c "
import glob, os, re, sys

agents_dir = os.environ[\"VF_AGENTS_DIR\"]
skills_dir = os.environ[\"VF_SKILLS_DIR\"]
strict = os.environ[\"VF_STRICT\"] == \"true\"
hook = os.environ[\"VF_HOOK\"] == \"true\"
single = os.environ[\"VF_SINGLE\"]

# Champs officiels Claude Code (docs sub-agents, 2026-07-05) — base du lint.
KNOWN = {\"name\", \"description\", \"tools\", \"disallowedTools\", \"model\", \"permissionMode\",
         \"maxTurns\", \"skills\", \"mcpServers\", \"hooks\", \"memory\", \"background\", \"effort\",
         \"isolation\", \"color\", \"initialPrompt\"}
MODELS = {\"sonnet\", \"opus\", \"haiku\", \"fable\", \"inherit\"}
MEMORY = {\"user\", \"project\", \"local\"}
EFFORT = {\"low\", \"medium\", \"high\", \"xhigh\", \"max\"}
PERM = {\"default\", \"acceptEdits\", \"auto\", \"dontAsk\", \"bypassPermissions\", \"plan\", \"manual\"}
NOT_AGENTS = {\"contracts.md\", \"README.md\", \"AGENTS.md\"}

errors, warnings = [], []

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
                fm[current_key] = [] if val == \"\" else val
            else:
                fm[current_key] = val
        elif current_key is not None:
            item = re.match(r\"^\s+-\s+(.+?)(\s+#.*)?$\", line)
            if item and isinstance(fm.get(current_key), list):
                fm[current_key].append(item.group(1).strip())
            elif line.startswith(\"  \") and isinstance(fm.get(current_key), str):
                fm[current_key] = fm[current_key] + \" \" + line.strip()
        i += 1
    return None  # frontmatter jamais fermé

def check_file(path):
    base = os.path.basename(path)
    try:
        text = open(path, encoding=\"utf-8\").read()
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

    effort = fm.get(\"effort\")
    if effort and effort not in EFFORT:
        errors.append(f\"{base} : effort invalide ({effort}) — attendu low|medium|high|xhigh|max\")
    pm = fm.get(\"permissionMode\")
    if pm and pm not in PERM:
        errors.append(f\"{base} : permissionMode invalide ({pm})\")
    iso = fm.get(\"isolation\")
    if iso and iso != \"worktree\":
        errors.append(f\"{base} : isolation invalide ({iso}) — seul worktree est admis\")
    bg = fm.get(\"background\")
    if bg and str(bg) not in (\"true\", \"false\"):
        errors.append(f\"{base} : background invalide ({bg}) — true|false\")
    mt = fm.get(\"maxTurns\")
    if mt and not str(mt).isdigit():
        errors.append(f\"{base} : maxTurns invalide ({mt}) — entier attendu\")

    skills = fm.get(\"skills\")
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
            sk = os.path.join(skills_dir, s, \"SKILL.md\")
            if not os.path.isfile(sk):
                msg = f\"{base} : skill declare introuvable — {s} (le creer via skill-creator, jamais le laisser en promesse)\"
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
        if not hook:
            print(f\"[check-agents] aucun agent dans {agents_dir} — rien a verifier\")
        sys.exit(0)
    for f in files:
        check_file(f)

n_err, n_warn = len(errors), len(warnings)
if hook:
    if n_err:
        print(f\"[check-agents] ✗ {n_err} agent(s) non conforme(s) :\")
        for e in errors:
            print(f\"  - {e}\")
        print(\"  Corriger le frontmatter puis relancer : bash .claude/scripts/check-agents.sh\")
    sys.exit(0)

for w in warnings:
    print(f\"  ⚠ {w}\")
if n_err:
    print(f\"[check-agents] ✗ {n_err} non-conformite(s) bloquante(s) :\")
    for e in errors:
        print(f\"  ✗ {e}\")
    sys.exit(1)
print(f\"[check-agents] ✓ agents conformes (natif + charte VibeFlow){' · ' + str(n_warn) + ' warning(s)' if n_warn else ''}\")
sys.exit(0)
"
