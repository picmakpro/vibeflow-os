#!/usr/bin/env bash
# guard-read-registres.sh — Hook PreToolUse(Read) : interdit la lecture NON CIBLÉE
# d'un registre mémoire canonique. Donne des dents à l'Iron Law du consolidator :
# « lecture d'un registre = lecture de l'index uniquement par défaut » (ADR-032, ADR-043).
#
# Câblage (posé automatiquement par l'install du module consolidator) :
#   PreToolUse · matcher "Read" · command: bash .claude/scripts/guard-read-registres.sh
#
# Règle (resserrée BLK-007 : valider les VALEURS des paramètres, pas leur présence —
# un Read(offset=1) sans limit, ou limit=100000, lisait tout le fichier) :
#   - fichier lu ∈ {DECISIONS,LEARNINGS,BLOCKERS,EVALS,JOURNAL}.md (+ legacy ADR/BDR/ITERATION_LOG)
#     sous .claude/memory/ (hors archive/)
#   - ET le registre dépasse VF_GUARD_MAX_LINES (défaut 150) lignes
#   - ET la fenêtre de lecture n'est pas bornée : limit ABSENT, ou limit > VF_GUARD_MAX_READ
#     (défaut 60) — offset seul ne borne RIEN.
#   → BLOQUE (permissionDecision "deny") avec la marche à suivre index-first.
#   Passe : lecture bornée (limit ≤ 60, avec ou sans offset), petits registres (≤ 150),
#   fichiers hors registres, archives.
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

# BLK-007 : ce qui borne une lecture, c est la VALEUR de limit — pas la présence d un
# paramètre. offset seul = lecture jusqu au bout ; limit énorme = fenêtre non bornée.
max_read = 60
try:
    max_read = int(os.environ.get("VF_GUARD_MAX_READ", "60"))
except ValueError:
    pass

limit = tool_input.get("limit")
try:
    limit = int(limit) if limit is not None else None
except (TypeError, ValueError):
    limit = None

if limit is not None and 0 < limit <= max_read:
    sys.exit(0)

if limit is None:
    cause = "appel sans limit (un offset seul ne borne rien : lecture jusqu au bout du fichier)"
else:
    cause = f"limit={limit} > plafond {max_read}"
reason = (
    f"Lecture non bornée d un registre interdite ({base} : {n_lines} lignes — {cause}). "
    f"Règle index-first (consolidator) : 1) lis l index en en-tête — Read(file_path, limit=40) ; "
    f"2) repère la colonne #Ligne de l entrée visée ; "
    f"3) lis uniquement cette entrée — Read(file_path, offset=<#Ligne>, limit=<taille entrée, ≤ {max_read}>). "
    f"Entrée plus longue que {max_read} lignes : enchaîne plusieurs fenêtres. "
    f"Un registre ne se charge jamais en entier hors checkpoint."
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
