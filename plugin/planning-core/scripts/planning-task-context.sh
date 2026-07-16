#!/usr/bin/env bash
# planning-task-context.sh — Injecte le STATE.md du COMPARTIMENT correspondant à la tâche.
#
# Rôle (ADR-050, event UserPromptSubmit) : sur un lab À COMPARTIMENTS, une fois la tâche connue
# (le prompt de l'utilisateur), on injecte le `.planning/STATE.md` DU compartiment que la tâche
# vise — « index d'abord (SessionStart), puis le bon planning (ici) ». On ne charge jamais tous
# les compartiments : seulement celui qui est pertinent, borné.
#
# Ne fait rien si : lab mono (pas de .planning/INDEX.md — le SessionStart a déjà injecté STATE),
# aucun compartiment ne matche le prompt, ou python3 absent. Fail-open, jamais bloquant.
#
# Câblage (posé à l'install du module) : UserPromptSubmit → bash planning-task-context.sh
set -uo pipefail

command -v python3 >/dev/null 2>&1 || exit 0
# Lab à compartiments uniquement (sinon le digest mono du SessionStart suffit).
[ -f ".planning/INDEX.md" ] || exit 0

INPUT="$(cat)"

printf '%s' "$INPUT" | python3 -c '
import json, sys, glob, os, re

MAX_LINES = 40

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

prompt = (data.get("prompt") or "").lower()
if not prompt.strip():
    sys.exit(0)

# Découvrir les compartiments : tout <dir>/.planning/STATE.md sauf le .planning/ racine du lab.
states = [p for p in glob.glob("**/.planning/STATE.md", recursive=True)
          if os.path.normpath(p) != os.path.normpath(".planning/STATE.md")]
if not states:
    sys.exit(0)

def name_of(p):
    # <...>/<compartiment>/.planning/STATE.md -> nom du compartiment
    parts = os.path.normpath(p).split(os.sep)
    return parts[-3] if len(parts) >= 3 else ""

# Matcher : le nom du compartiment (ou un segment de son chemin) apparaît dans le prompt.
best = None
for p in states:
    nm = name_of(p)
    if not nm:
        continue
    # tokens du nom (sépare kebab/snake) — match si un token >=3 lettres est dans le prompt
    tokens = [t for t in re.split(r"[-_/ ]+", nm.lower()) if len(t) >= 3]
    if nm.lower() in prompt or any(t in prompt for t in tokens):
        best = (nm, p)
        break

if not best:
    sys.exit(0)

nm, path = best
try:
    with open(path, encoding="utf-8") as f:
        lines = f.read().splitlines()
except Exception:
    sys.exit(0)

shown = lines[:MAX_LINES]
print("## 📍 Planning du compartiment ciblé : %s (injecté)" % nm)
print("")
print("Ta tâche vise le compartiment **%s**. Son état courant (%d premières lignes sur %d) :"
      % (nm, len(shown), len(lines)))
print("")
print("```")
print("\n".join(shown))
print("```")
if len(lines) > MAX_LINES:
    print("_(…tronqué — `Read %s` pour la suite.)_" % path)
' 2>/dev/null || exit 0

exit 0
