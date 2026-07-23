#!/usr/bin/env bash
# guard-file-size.sh — Hook PreToolUse(Edit|Write) : porte blindée de l'Iron Law 300L
# (ADR-035 « aucun fichier de code > 300 lignes sans plan de découpe », câblé ADR-043).
#
# Câblage (posé automatiquement par l'install du module software-architecture) :
#   PreToolUse · matcher "Edit|Write" · command: bash .claude/scripts/guard-file-size.sh
#
# Règle — le guard juge le RÉSULTAT de l'opération, jamais le seul état passé du disque
# (mesurer l'ancien contenu bloquait la remédiation elle-même : un Write de refactor
# conforme, ou l'Edit qui ajoute le marqueur d'échappatoire, étaient deny → boucle
# deny/retry qui enseignait le contournement par Bash/sed) :
#   - Write : le contenu ENTRANT fait foi (le fichier est intégralement remplacé).
#     >= VF_ARCH_BLOCK (300) lignes sans marqueur `vibeflow:allow-large-file` → deny,
#     y compris pour un fichier NEUF (un Write initial de 2000 lignes ne passe plus).
#   - Edit : ne pas agrandir = toujours allow (c'est la voie de découpe) ; poser le
#     marqueur = toujours allow. Une édition qui agrandit est estimée (lignes disque
#     + delta de lignes, occurrences comptées si replace_all) : résultat >= seuil
#     sans marqueur (sur disque ou entrant) → deny.
#   Fichier non-code → allow. check-file-size.sh reste le gate CLI/pre-commit
#   (--staged / --all) ; mêmes seuils, même marqueur.
#
# Fail-open : SEUL le deny explicite bloque ; toute erreur interne (JSON invalide,
# fichier illisible, python absent) → allow silencieux. Un garde-fou cassé ne bloque
# jamais le flux. Un seul spawn python3 (parse stdin + décision + deny) par appel.

set -uo pipefail


# Préfiltre trivial sans spawn : payload sans file_path → rien à mesurer
# (couvre aussi le stdin invalide : allow silencieux immédiat).
INPUT="$(cat 2>/dev/null || true)"
case "$INPUT" in
  *file_path*) ;;
  *) exit 0 ;;
esac

# ADR-054 : le `python3` du PATH Windows peut être le stub Microsoft Store — présent
# (`command -v` réussit) mais inerte à l'exécution. Détection par CHEMIN (zéro spawn),
# repli `python` ; sinon fail-open inchangé.
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else exit 0; fi ;;
esac

# NB : programme passé en -c (sans apostrophes) ; le payload est rejoué sur le stdin
# du python. Le bash ne fait plus que router : le deny JSON est émis par python.
printf '%s' "$INPUT" | "$PYBIN" -c '
import json, os, re, sys

MARKER = "vibeflow:allow-large-file"

def head_has_marker(text):
    # Echappatoire documentee (identique a check-file-size.sh) : 5 premieres lignes.
    return MARKER in "\n".join(text.splitlines()[:5])

try:
    payload = json.load(sys.stdin)
    tool = payload.get("tool_name") or ""
    ti = payload.get("tool_input") or {}
    path = ti.get("file_path") or ""
    if not path:
        sys.exit(0)
    # Meme perimetre que check-file-size.sh : seuls les fichiers de code comptent.
    if not re.search(r"\.(ts|tsx|js|jsx|mjs|cjs|py|go|rb|java|kt|swift|rs|php)$", path):
        sys.exit(0)
    try:
        block = int(os.environ.get("VF_ARCH_BLOCK", "300"))
    except ValueError:
        block = 300

    estimated = None
    if tool == "Write":
        content = ti.get("content")
        if not isinstance(content, str) or head_has_marker(content):
            sys.exit(0)  # payload atypique, ou dette tracee dans le contenu entrant
        # splitlines compte la derniere ligne meme sans newline finale (wc -l la rate).
        estimated = len(content.splitlines())
    elif tool == "Edit":
        old = ti.get("old_string")
        new = ti.get("new_string")
        if not isinstance(old, str) or not isinstance(new, str) or not old:
            sys.exit(0)  # appel invalide : Edit produira sa propre erreur
        if MARKER in new:
            sys.exit(0)  # poser le marqueur est TOUJOURS permis (sinon deny-loop)
        # Delta de lignes exact = delta de newlines (vrai aussi pour des fragments
        # partiels de ligne, la ou un compte de lignes des fragments derive de +/-1).
        growth = new.count("\n") - old.count("\n")
        if growth <= 0:
            sys.exit(0)  # retrecir / ne pas agrandir = voie de decoupe, toujours permis
        try:
            with open(path, encoding="utf-8", errors="replace") as f:
                disk = f.read()
        except OSError:
            sys.exit(0)  # illisible ou absent : fail-open, le tool rendra sa propre erreur
        if head_has_marker(disk):
            sys.exit(0)  # dette deja tracee sur le disque
        if ti.get("replace_all"):
            occ = disk.count(old)
            if occ == 0:
                sys.exit(0)  # occurrence absente : Edit echouera de lui-meme
            growth = occ * growth
        estimated = len(disk.splitlines()) + growth
    else:
        sys.exit(0)  # autre tool (matcher plus large) : hors perimetre, allow

    if estimated is None or estimated < block:
        sys.exit(0)

    reason = (
        "Iron Law ADR-035 : cette operation amenerait " + path + " a ~" + str(estimated)
        + " lignes (seuil " + str(block) + "). Marche a suivre : 1) decouper le fichier"
        + " (SRP — extraire un module coherent) avant de poursuivre ; ou 2) tracer la"
        + " dette en ajoutant le marqueur vibeflow:allow-large-file dans les 5 premieres"
        + " lignes ET une entree dette dans le registre. Les editions qui reduisent le"
        + " fichier passent toujours. Ne contourne pas silencieusement via Bash/sed."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))
except Exception:
    sys.exit(0)  # fail-open : toute erreur interne = allow
' 2>/dev/null || exit 0
exit 0
