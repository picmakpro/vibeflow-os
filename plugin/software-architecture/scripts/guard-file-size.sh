#!/usr/bin/env bash
# guard-file-size.sh — Hook PreToolUse(Edit|Write) : porte blindée de l'Iron Law 300L
# (ADR-035 « aucun fichier de code > 300 lignes sans plan de découpe », câblé ADR-043).
# Délègue la mesure à check-file-size.sh (mêmes seuils, même marqueur d'échappatoire).
#
# Câblage (posé automatiquement par l'install du module software-architecture) :
#   PreToolUse · matcher "Edit|Write" · command: bash .claude/scripts/guard-file-size.sh
#
# Règle : éditer un fichier de code déjà >= VF_ARCH_BLOCK (300) lignes SANS marqueur
# `vibeflow:allow-large-file` → deny avec la marche à suivre (découper ou tracer la dette).
# Un fichier nouveau (Write initial), non-code, ou sous le seuil passe toujours.
#
# Fail-open : toute erreur interne → allow. Un garde-fou cassé ne bloque jamais le flux.

set -uo pipefail

command -v python3 >/dev/null 2>&1 || exit 0

FILE_PATH="$(python3 -c '
import json, sys
try:
    p = json.load(sys.stdin)
    print((p.get("tool_input") or {}).get("file_path") or "")
except Exception:
    print("")
' 2>/dev/null)" || exit 0

[ -n "$FILE_PATH" ] || exit 0
[ -f "$FILE_PATH" ] || exit 0   # création de fichier : le gate mesurera aux éditions suivantes

CHECKER="$(dirname "$0")/check-file-size.sh"
[ -f "$CHECKER" ] || exit 0

if bash "$CHECKER" "$FILE_PATH" >/dev/null 2>&1; then
  exit 0
fi

# check-file-size exit 2 = blocage (>= BLOCK sans marqueur).
N_LINES="$(wc -l < "$FILE_PATH" | tr -d ' ')"
BLOCK="${VF_ARCH_BLOCK:-300}"
REASON="Fichier de code trop long pour être édité tel quel ($FILE_PATH : $N_LINES lignes >= $BLOCK). Iron Law ADR-035 : 1) découper d'abord (SRP — extraire un module cohérent) ; ou 2) tracer la dette en ajoutant le marqueur 'vibeflow:allow-large-file' dans les 5 premières lignes ET une entrée dette dans le registre. Ne contourne pas silencieusement."

python3 - "$REASON" <<'PYEOF' 2>/dev/null || exit 0
import json, sys
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": sys.argv[1],
    }
}, ensure_ascii=False))
PYEOF
exit 0
