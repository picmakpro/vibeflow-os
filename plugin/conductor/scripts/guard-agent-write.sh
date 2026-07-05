#!/usr/bin/env bash
# guard-agent-write.sh — Hook PreToolUse(Write) : un agent NON NATIF ne peut plus être écrit
# dans .claude/agents/ (ADR-044). Ce qui passait : agents sans description (jamais routés),
# sans model, sans memory — l'init posait des coquilles vides et personne ne le voyait.
#
# Câblage (posé automatiquement par l'install du module conductor) :
#   PreToolUse · matcher "Write" · command: bash .claude/scripts/guard-agent-write.sh
#
# Règle : Write vers .claude/agents/<nom>.md (hors contracts.md/README.md/AGENTS.md — les
# sous-dossiers *-references/ ne matchent pas) → le CONTENU proposé est validé par
# check-agents.sh --file AVANT écriture. Socle bloquant : frontmatter présent, name,
# description, model, memory + enums valides. Le deny renvoie les erreurs précises + le
# squelette canonique. Edit n'est pas guardé (contenu partiel) — rattrapé par le check
# SessionStart et le Gate C d'init.
#
# Fail-open : toute erreur interne → allow (exit 0 silencieux).

set -uo pipefail

command -v python3 >/dev/null 2>&1 || exit 0

CHECKER="$(dirname "$0")/check-agents.sh" VF_GUARD=1 python3 -c "
import json, os, subprocess, sys, tempfile

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

ti = payload.get(\"tool_input\") or {}
fp = (ti.get(\"file_path\") or \"\").replace(\"\\\\\", \"/\")
base = os.path.basename(fp)
parent = os.path.dirname(fp)
if (not parent.endswith(\".claude/agents\")
        or not base.endswith(\".md\")
        or base in (\"contracts.md\", \"README.md\", \"AGENTS.md\")):
    sys.exit(0)

content = ti.get(\"content\") or \"\"
if not content.strip():
    sys.exit(0)

checker = os.environ.get(\"CHECKER\", \"\")
if not os.path.isfile(checker):
    sys.exit(0)

with tempfile.TemporaryDirectory() as tmpd:
    target = os.path.join(tmpd, base)
    with open(target, \"w\", encoding=\"utf-8\") as f:
        f.write(content)
    try:
        r = subprocess.run([\"bash\", checker, \"--file\", target],
                           capture_output=True, text=True, timeout=20)
    except Exception:
        sys.exit(0)
    if r.returncode == 0:
        sys.exit(0)
    detail = \" ; \".join(l.strip() for l in r.stdout.splitlines() if \"✗\" in l and \" : \" in l)

reason = (
    \"Agent NON NATIF refuse (ADR-044) — corrige le frontmatter avant d ecrire. \"
    + (detail[:700] if detail else \"frontmatter non conforme\")
    + \" | Squelette canonique obligatoire : --- ; name: <kebab-case = nom du fichier> ; \"
    + \"description: <quand utiliser cet agent — declencheur du routage automatique> ; \"
    + \"model: sonnet|opus|haiku|fable|inherit ; memory: project ; \"
    + \"skills: [<skills EXISTANTS, crees via skill-creator>] ; effort: <optionnel> ; --- \"
    + \"| Verifier : bash .claude/scripts/check-agents.sh --file <fichier>\"
)
print(json.dumps({
    \"hookSpecificOutput\": {
        \"hookEventName\": \"PreToolUse\",
        \"permissionDecision\": \"deny\",
        \"permissionDecisionReason\": reason,
    }
}, ensure_ascii=False))
sys.exit(0)
" 2>/dev/null || exit 0
exit 0
