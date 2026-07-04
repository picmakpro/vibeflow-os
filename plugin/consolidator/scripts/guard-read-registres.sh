#!/usr/bin/env bash
# guard-read-registres.sh — Hook PreToolUse(Read) : interdit la lecture NON CIBLÉE
# d'un registre mémoire canonique. Donne des dents à l'Iron Law du consolidator :
# « lecture d'un registre = lecture de l'index uniquement par défaut » (ADR-032, ADR-043).
#
# Câblage (posé automatiquement par l'install du module consolidator) :
#   PreToolUse · matcher "Read" · command: bash .claude/scripts/guard-read-registres.sh
#
# Règle :
#   - fichier lu ∈ {DECISIONS,LEARNINGS,BLOCKERS,EVALS,JOURNAL}.md (+ legacy ADR/BDR/ITERATION_LOG)
#     sous .claude/memory/ (hors archive/)
#   - ET l'appel Read ne précise NI offset NI limit
#   - ET le registre dépasse VF_GUARD_MAX_LINES (défaut 150) lignes
#   → BLOQUE (permissionDecision "deny") avec la marche à suivre index-first.
#   Tout le reste passe (lecture d'index avec limit, lecture ciblée offset/limit,
#   petits registres, fichiers hors registres, archives).
#
# NB : le programme python est passé en -c (PAS en heredoc sur stdin) — le payload JSON
# du hook arrive sur stdin et doit rester lisible par json.load(sys.stdin).
#
# Fail-open : toute erreur interne → allow (exit 0 silencieux). Un garde-fou cassé
# ne doit jamais bloquer le travail.

set -uo pipefail

command -v python3 >/dev/null 2>&1 || exit 0

python3 -c '
import json, os, sys

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_input = payload.get("tool_input") or {}
file_path = tool_input.get("file_path") or ""
if not file_path:
    sys.exit(0)

# Lecture ciblée (offset et/ou limit fournis) : toujours autorisée.
if tool_input.get("offset") is not None or tool_input.get("limit") is not None:
    sys.exit(0)

REGISTRES = {
    "DECISIONS.md", "LEARNINGS.md", "BLOCKERS.md", "EVALS.md", "JOURNAL.md",
    # Legacy encore lus par les scripts (labs non migrés) :
    "ADR.md", "BDR.md", "ITERATION_LOG.md",
}

norm = file_path.replace("\\\\", "/")
base = os.path.basename(norm)
parent = os.path.dirname(norm)
if base not in REGISTRES:
    sys.exit(0)
# Registre canonique = directement sous .claude/memory/ (l archive reste libre).
if not parent.endswith(".claude/memory"):
    sys.exit(0)

max_lines = 150
try:
    max_lines = int(os.environ.get("VF_GUARD_MAX_LINES", "150"))
except ValueError:
    pass

try:
    with open(file_path, "rb") as f:
        n_lines = sum(1 for _ in f)
except OSError:
    sys.exit(0)  # fichier illisible/absent : laisser Read produire sa propre erreur

if n_lines <= max_lines:
    sys.exit(0)

reason = (
    f"Lecture non ciblée d un registre interdite ({base} : {n_lines} lignes). "
    "Règle index-first (consolidator) : 1) lis l index en en-tête — Read(file_path, limit=40) ; "
    "2) repère la colonne #Ligne de l entrée visée ; "
    "3) lis uniquement cette entrée — Read(file_path, offset=<#Ligne>, limit=<taille entrée>). "
    "Un registre ne se charge jamais en entier hors checkpoint."
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }
}, ensure_ascii=False))
sys.exit(0)
' 2>/dev/null || exit 0
exit 0
