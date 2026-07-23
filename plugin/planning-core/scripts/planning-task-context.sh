#!/usr/bin/env bash
# planning-task-context.sh — Injecte le STATE.md du COMPARTIMENT correspondant à la tâche.
#
# Rôle (ADR-050, event UserPromptSubmit) : sur un lab À COMPARTIMENTS, une fois la tâche connue
# (le prompt de l'utilisateur), on injecte le `.planning/STATE.md` DU compartiment que la tâche
# vise — « index d'abord (SessionStart), puis le bon planning (ici) ». On ne charge jamais tous
# les compartiments : seulement celui qui est pertinent, borné.
#
# Ne fait rien si : lab mono (pas de .planning/INDEX.md — le SessionStart a déjà injecté STATE),
# aucun compartiment ne matche le prompt, match ambigu, ou python3 absent. Fail-open, jamais bloquant.
#
# Ce hook tourne à CHAQUE prompt → découverte par globs BORNÉS (jamais ** récursif, qui
# marcherait tout le repo — node_modules compris — à chaque frappe), et matching par
# FRONTIÈRE DE MOT (une sous-chaîne nue ferait matcher « informations » → formation et
# présenterait le mauvais STATE au modèle comme « ta tâche vise… » : désinformation active).
#
# Câblage (posé à l'install du module) : UserPromptSubmit → bash planning-task-context.sh
set -uo pipefail

# ADR-054 : le `python3` du PATH Windows peut être le stub Microsoft Store — présent
# (`command -v` réussit) mais inerte à l'exécution. Détection par CHEMIN (zéro spawn),
# repli `python` ; sinon fail-open inchangé.
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else exit 0; fi ;;
esac
# Lab à compartiments uniquement (sinon le digest mono du SessionStart suffit).
[ -f ".planning/INDEX.md" ] || exit 0

INPUT="$(cat)"

printf '%s' "$INPUT" | "$PYBIN" -c '
import json, sys, glob, os, re

MAX_LINES = 40
MIN_TOKEN = 4   # taille minimale des tokens de nom (anti faux positifs sur mots courts)

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

prompt = (data.get("prompt") or "").lower()
if not prompt.strip():
    sys.exit(0)

# Découvrir les compartiments par globs BORNÉS — jamais ** récursif (tournerait sur tout
# le repo à chaque prompt). Profondeurs couvertes : <comp>/ et <groupe>/<comp>/ (dont
# projects/<comp>/), dédupliquées par chemin normalisé.
seen = {}
for pat in ("*/.planning/STATE.md", "*/*/.planning/STATE.md", "projects/*/.planning/STATE.md"):
    for p in glob.glob(pat):
        seen[os.path.normpath(p)] = True
seen.pop(os.path.normpath(".planning/STATE.md"), None)  # jamais le .planning racine du lab
states = sorted(seen)  # ordre déterministe (plus jamais tributaire de la traversée du glob)
if not states:
    sys.exit(0)

def name_of(p):
    # <...>/<compartiment>/.planning/STATE.md -> nom du compartiment
    parts = os.path.normpath(p).split(os.sep)
    return parts[-3] if len(parts) >= 3 else ""

def word_in(w, text):
    # Frontière de mot : « informations » ne matche plus « formation » (sous-chaîne interdite).
    return re.search(r"\b" + re.escape(w) + r"\b", text) is not None

def score(nm):
    # (2, len) si le nom complet apparaît en mot entier ; sinon (1, len du meilleur token) ;
    # (0, 0) sans match. Nom exact > token entier, puis le plus long gagne.
    nml = nm.lower()
    if len(nml) >= 3 and word_in(nml, prompt):
        return (2, len(nml))
    best = 0
    for t in re.split(r"[-_/ ]+", nml):
        if len(t) >= MIN_TOKEN and len(t) > best and word_in(t, prompt):
            best = len(t)
    return (1, best) if best else (0, 0)

# Scorer TOUS les candidats, tri déterministe : score décroissant puis chemin alphabétique.
scored = sorted(((score(name_of(p)), p) for p in states if name_of(p)),
                key=lambda x: (-x[0][0], -x[0][1], x[1]))
scored = [s for s in scored if s[0][0] > 0]
if not scored:
    sys.exit(0)
# Égalité parfaite entre deux compartiments distincts = ambigu -> silence (fail-open) :
# mieux vaut ne rien injecter que présenter le mauvais STATE comme la tâche en cours.
if len(scored) >= 2 and scored[0][0] == scored[1][0]:
    sys.exit(0)

path = scored[0][1]
nm = name_of(path)
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
