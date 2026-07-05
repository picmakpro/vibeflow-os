#!/usr/bin/env bash
# guard-bash-registres.sh — Hook PreToolUse(Bash) : ferme le CONTOURNEMENT SHELL du
# guard de lecture des registres (ADR-043, correctif BLK-006 du Lab). Le hook Read seul
# ne protégeait que le chemin nominal : `cat .claude/memory/DECISIONS.md` passait au travers.
#
# Câblage (posé automatiquement par l'install du module consolidator) :
#   PreToolUse · matcher "Bash" · command: bash .claude/scripts/guard-bash-registres.sh
#
# Règle — DENY si la commande Bash fait une LECTURE PLEINE d'un registre canonique
# (.claude/memory/{DECISIONS,LEARNINGS,BLOCKERS,EVALS,JOURNAL,ADR,BDR,ITERATION_LOG}.md,
# hors archive/) qui dépasse VF_GUARD_MAX_LINES (150) lignes :
#   - lecteur plein (cat, less, more, bat, nl, tac, strings, vi/vim/nano, open…) sur le registre ;
#   - head/tail NON borné (`-n +K`, N > 150) sur le registre.
# Reste AUTORISÉ (lecture ciblée ou écriture) :
#   - grep/rg, wc, ls, stat, git, diff, sed/awk (plages ciblées) ;
#   - head/tail borné (N ≤ 150, ou défaut 10 lignes) ;
#   - pipeline dont un segment AVAL limite la sortie (`cat X | head -20`, `… | grep`) ;
#   - écritures/appends (`>> registre`, `> registre`, `tee -a registre`) — l'index est
#     ensuite recalé par post-edit-reindex (qui couvre aussi Bash) ;
#   - petits registres (≤ 150 lignes), archives, fichiers hors registres.
#
# LIMITE ASSUMÉE (documentée BLK-006) : cette barrière est un garde-fou déterministe contre
# le chemin de moindre résistance, pas une sandbox — un interpréteur inline (python -c,
# node -e) peut toujours lire le fichier. Les couvrir produirait trop de faux positifs.
#
# Fail-open : toute erreur interne → allow (exit 0 silencieux).

set -uo pipefail

command -v python3 >/dev/null 2>&1 || exit 0

python3 -c '
import json, os, re, sys

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_input = payload.get("tool_input") or {}
cmd = tool_input.get("command") or ""
if not cmd:
    sys.exit(0)
cwd = payload.get("cwd") or "."

# Chemin de registre canonique DIRECTEMENT sous .claude/memory/ (archive/ ne matche pas).
REG_RE = re.compile(
    r"(?P<path>[^\s\"\x27<>|;&]*\.claude/memory/"
    r"(?:DECISIONS|ADR|BDR|LEARNINGS|BLOCKERS|EVALS|JOURNAL|ITERATION_LOG)\.md)"
)
if not REG_RE.search(cmd):
    sys.exit(0)

FULL_READERS = {"cat", "less", "more", "bat", "nl", "tac", "strings", "pv",
                "vi", "vim", "view", "nano", "emacs", "open", "column"}
LIMITERS = {"grep", "rg", "ugrep", "egrep", "fgrep", "wc", "ls", "stat", "git",
            "diff", "md5", "md5sum", "shasum", "sed", "awk", "cut", "sort", "uniq", "jq"}

max_lines = 150
try:
    max_lines = int(os.environ.get("VF_GUARD_MAX_LINES", "150"))
except ValueError:
    pass

def n_lines(path):
    p = os.path.expanduser(path)
    if not os.path.isabs(p):
        p = os.path.join(cwd, p)
    try:
        with open(p, "rb") as f:
            return sum(1 for _ in f)
    except OSError:
        return 0

def tokens(seg):
    try:
        import shlex
        return shlex.split(seg, posix=True)
    except ValueError:
        return seg.split()

def head_tail_unbounded(toks, i):
    """True si le head/tail en position i lit plus de max_lines (ou -n +K = tout)."""
    j = i + 1
    while j < len(toks):
        t = toks[j]
        val = None
        if t == "-n":
            val = toks[j + 1] if j + 1 < len(toks) else None
            j += 2
        elif t.startswith("-n") and len(t) > 2:
            val = t[2:]
            j += 1
        elif t.startswith("--lines="):
            val = t[len("--lines="):]
            j += 1
        elif re.fullmatch(r"-\d+", t):
            val = t[1:]
            j += 1
        else:
            j += 1
            continue
        if val is None:
            continue
        if val.startswith("+"):
            return True  # -n +K = lit jusqu a la fin
        try:
            if int(val) > max_lines:
                return True
        except ValueError:
            pass
    return False  # defaut head/tail = 10 lignes : borne

def segment_limits_output(seg):
    """Un segment aval qui reduit la sortie (grep, head borne, sed -n plage...)."""
    toks = tokens(seg)
    for i, t in enumerate(toks):
        name = os.path.basename(t)
        if name in LIMITERS:
            return True
        if name in ("head", "tail") and not head_tail_unbounded(toks, i):
            return True
    return False

segments = re.split(r"\|\||&&|;|\|", cmd)

for si, seg in enumerate(segments):
    m = REG_RE.search(seg)
    if not m:
        continue
    path = m.group("path")
    # Ecriture/append vers le registre : ce n est pas une lecture.
    if re.search(r">{1,2}\s*" + re.escape(path), seg):
        continue
    toks = tokens(seg)
    if any(os.path.basename(t) == "tee" for t in toks):
        continue
    full_read = False
    for i, t in enumerate(toks):
        name = os.path.basename(t)
        if name in FULL_READERS:
            full_read = True
            break
        if name in ("head", "tail") and head_tail_unbounded(toks, i):
            full_read = True
            break
    if not full_read:
        continue
    # Pipeline : un segment AVAL qui limite la sortie rend la lecture ciblee.
    if any(segment_limits_output(s) for s in segments[si + 1:]):
        continue
    n = n_lines(path)
    if n <= max_lines:
        continue
    base = os.path.basename(path)
    reason = (
        f"Lecture non ciblée d un registre via Bash interdite ({base} : {n} lignes). "
        "Règle index-first (consolidator) : 1) lis l index — Read(file_path, limit=40) ; "
        "2) repère la colonne #Ligne ; 3) cible — Read(file_path, offset=<#Ligne>, limit=<N, ≤60>) "
        "ou `sed -n <a>,<b>p` / `grep -n <ID>`. Un registre ne se charge jamais en entier "
        "hors checkpoint."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))
    sys.exit(0)

sys.exit(0)
' 2>/dev/null || exit 0
exit 0
