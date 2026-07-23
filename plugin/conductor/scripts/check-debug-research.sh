#!/usr/bin/env bash
# check-debug-research.sh — Lint de la présence de la phase RECHERCHE DOCUMENTAIRE avant debug (ADR-045).
# Ce qui passait silencieusement : des briques de dépannage (skills/agents) qui partent en debug
# empirique sans jamais chercher une cause connue (issue GitHub, note de version) → cycles perdus
# sur des bugs de lib/framework/natif/version déjà documentés.
#
# Référentiel : règle canonique doc-research-before-debug (module software-architecture) +
# garde-fou 6 de autonomous-guardrails.md. Prolonge LRN-106 « Audit avant fix ».
#
# Usage:
#   check-debug-research.sh                   # audit .claude/{skills,agents} · exit 1 si une brique debug n'a pas la phase
#   check-debug-research.sh --strict          # GATE : promeut les warnings en erreurs bloquantes
#   check-debug-research.sh --hook            # SessionStart : compact, exit 0 toujours
#   check-debug-research.sh --file <x.md>     # une seule brique
#   check-debug-research.sh --agents-dir=PATH # défaut .claude/agents
#   check-debug-research.sh --skills-dir=PATH # défaut .claude/skills
#
# Une brique est « de dépannage » si son name/description matche : debug|diagnos|dépannage|
#   depannage|crash|stack trace|ça plante|ca plante. Elle est CONFORME si son corps mentionne la
#   phase de recherche doc AVANT le fix : un renvoi à `doc-research-before-debug`, un heading
#   « Recherche documentaire », OU une mention `context7` / `resolve-library-id` / `query-docs`.
#   Les wrappers minces qui délèguent (ex. `Invoque … gsd-debug`) sont conformes s'ils portent la
#   pré-étape doc (le wrapper VibeFlow standard `vf-debug` la porte).
#
# BLOQUANT (exit 1) : une brique debug SANS marqueur de recherche documentaire.
# WARNING : brique debug qui délègue sans marqueur explicite (ERROR en --strict).
#
# Codes de sortie : 0 = conforme (ou hook, ou rien à vérifier) · 1 = non conforme
# Fail-open : python3 absent → exit 0 silencieux (ne bloque pas la session).

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
prev=""
for arg in "$@"; do
  [ "$prev" = "--file" ] && SINGLE_FILE="$arg"
  prev="$arg"
done

# ADR-054 : stub Microsoft Store — `python3` présent dans le PATH mais inerte. Détection par
# CHEMIN (zéro spawn), repli `python` ; sinon message + exit 0 (advisory, comme avant).
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else echo "[check-debug-research] python3 requis" >&2; exit 0; fi ;;
esac

VF_AGENTS_DIR="$AGENTS_DIR" VF_SKILLS_DIR="$SKILLS_DIR" VF_STRICT="$STRICT" \
VF_HOOK="$HOOK_MODE" VF_SINGLE="$SINGLE_FILE" "$PYBIN" -c "
import glob, os, re, sys

agents_dir = os.environ[\"VF_AGENTS_DIR\"]
skills_dir = os.environ[\"VF_SKILLS_DIR\"]
strict = os.environ[\"VF_STRICT\"] == \"true\"
hook = os.environ[\"VF_HOOK\"] == \"true\"
single = os.environ[\"VF_SINGLE\"]

NOT_AGENTS = {\"contracts.md\", \"README.md\", \"AGENTS.md\"}

# Une brique est 'de dépannage' si name/description matche ce motif. Resserré (audit S061) :
# 'crash-free' (KPI mobile) et 'diagnos' isolé ('Diagnostique la santé du funnel', 'pass/fail +
# diagnostic') ne sont PAS du dépannage — 'diagnos' ne compte qu'en co-occurrence bug/erreur/panne.
DEBUG_RE = re.compile(r\"\bdebug|d[ée]pannage|crash(?!-free)|stack ?trace|[cç]a plante\", re.I)
DIAG_RE = re.compile(r\"diagnos\", re.I)
DIAG_CTX_RE = re.compile(r\"\b(bug|bogue|erreur|error|panne|incident|d[ée]faillance)\", re.I)
# Marqueurs de présence d'une phase recherche documentaire.
RESEARCH_RE = re.compile(r\"doc-research-before-debug|recherche documentaire|context7|resolve-library-id|query-docs\", re.I)
# Wrapper mince qui délègue (heuristique) — sans marqueur, c'est un warning ciblé.
DELEGATE_RE = re.compile(r\"invoque .*(gsd-debug|debugger)|d[ée]l[èe]gue\", re.I)

errors, warnings, checked = [], [], 0

def label_for(path):
    if os.path.basename(path) == \"SKILL.md\":
        return os.path.basename(os.path.dirname(path)) + \"/SKILL.md\"
    return os.path.basename(path)

def frontmatter_block(text):
    lines = text.split(\"\n\")
    if not lines or lines[0].strip() != \"---\":
        return \"\", text
    for i in range(1, len(lines)):
        if lines[i].strip() == \"---\":
            return \"\n\".join(lines[1:i]), \"\n\".join(lines[i+1:])
    return \"\", text

def field(fm, key):
    m = re.search(r\"^\s*\" + key + r\":\s*(.*)$\", fm, re.M)
    return m.group(1).strip() if m else \"\"

def check_file(path):
    global checked
    base = label_for(path)
    try:
        text = open(path, encoding=\"utf-8\").read()
    except OSError:
        return
    fm, body = frontmatter_block(text)
    name = field(fm, \"name\")
    desc = field(fm, \"description\")
    # Signature debug cherchée dans name + description (routage), pas dans tout le corps.
    signature = (name + \" \" + desc) if (name or desc) else text[:400]
    is_debug = bool(DEBUG_RE.search(signature)) or (
        bool(DIAG_RE.search(signature)) and bool(DIAG_CTX_RE.search(signature)))
    if not is_debug:
        return  # pas une brique de dépannage — hors périmètre
    checked += 1
    if RESEARCH_RE.search(text):
        return  # conforme : phase recherche doc présente ou référencée
    if DELEGATE_RE.search(body):
        warnings.append(f\"{base} : brique de dépannage qui délègue SANS pré-étape recherche documentaire explicite — ajouter un renvoi à doc-research-before-debug (ADR-045)\")
    else:
        errors.append(f\"{base} : brique de dépannage SANS phase recherche documentaire (ADR-045) — aucune mention de doc-research-before-debug / context7 / 'recherche documentaire' avant le fix\")

if single:
    if os.path.isfile(single):
        check_file(single)
    else:
        errors.append(f\"fichier introuvable : {single}\")
else:
    files = sorted(glob.glob(os.path.join(skills_dir, \"*\", \"SKILL.md\")))
    files += [f for f in sorted(glob.glob(os.path.join(agents_dir, \"*.md\")))
              if os.path.basename(f) not in NOT_AGENTS]
    if not files:
        if not hook:
            print(f\"[check-debug-research] aucune brique dans {skills_dir}/{agents_dir} — rien a verifier\")
        sys.exit(0)
    for f in files:
        check_file(f)

if strict:
    errors.extend(warnings)
    warnings = []

n_err, n_warn = len(errors), len(warnings)
if hook:
    if n_err:
        print(f\"[check-debug-research] ✗ {n_err} brique(s) debug sans recherche documentaire (ADR-045) :\")
        for e in errors:
            print(f\"  - {e}\")
        print(\"  Ajouter la phase recherche doc puis relancer : bash .claude/scripts/check-debug-research.sh\")
    sys.exit(0)

for w in warnings:
    print(f\"  ⚠ {w}\")
if n_err:
    print(f\"[check-debug-research] ✗ {n_err} non-conformite(s) bloquante(s) (ADR-045) :\")
    for e in errors:
        print(f\"  ✗ {e}\")
    sys.exit(1)
if checked == 0:
    print(\"[check-debug-research] ✓ aucune brique de dépannage détectée — rien a auditer\")
else:
    print(f\"[check-debug-research] ✓ {checked} brique(s) de dépannage conforme(s) ADR-045{' · ' + str(n_warn) + ' warning(s)' if n_warn else ''}\")
sys.exit(0)
"
