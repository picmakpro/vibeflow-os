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
#   - lecteur plein (cat, less, more, bat, nl, tac, strings, vi/vim/nano, open…) sur le
#     registre, UNIQUEMENT en position de COMMANDE (CSL-04 : `grep -n open REG` est un
#     motif de recherche légitime, pas un lecteur) ;
#   - head/tail NON borné (`-n +K`, N > 150) sur le registre.
# Reste AUTORISÉ (lecture ciblée ou écriture) :
#   - grep/rg, wc, ls, stat, git, diff, sed/awk (plages ciblées) ;
#   - head/tail borné (N ≤ 150, ou défaut 10 lignes) ;
#   - pipeline dont un segment AVAL limite la sortie (`cat X | head -20`, `… | grep`) ;
#   - écritures/appends (`>> registre`, `> registre` — cible quotée comprise, CSL-06 —
#     `tee -a registre`) — l'index est ensuite recalé par post-edit-reindex ;
#   - contenu de heredoc (CSL-05 : une doc qui CITE `cat registre` n'est pas une lecture) ;
#   - petits registres (≤ 150 lignes), archives, fichiers hors registres.
#
# LIMITE ASSUMÉE (documentée BLK-006) : cette barrière est un garde-fou déterministe contre
# le chemin de moindre résistance, pas une sandbox — un interpréteur inline (python -c,
# node -e) peut toujours lire le fichier. Les couvrir produirait trop de faux positifs.
#
# Fail-open : toute erreur interne → allow (exit 0 silencieux).

set -uo pipefail

# CSL-13 : préfiltre pur bash AVANT le spawn python3 (~80-120 ms payés sinon sur CHAQUE
# commande Bash, même sans rapport avec un registre). SURENSEMBLE STRICT du domaine de
# deny du python : celui-ci ne peut denier que si REG_RE matche la commande, ce qui
# exige la sous-chaîne littérale « .claude/memory/ » — présente telle quelle dans le
# payload JSON (l'encodeur JSON standard n'échappe ni « . » ni « / »). Un payload sans
# cette sous-chaîne ⇒ le python sortirait 0 de toute façon : le skip est sans perte.
PAYLOAD="$(cat 2>/dev/null || true)"
case "$PAYLOAD" in
  *'.claude/memory/'*) : ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 0

printf '%s' "$PAYLOAD" | python3 -c '
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

# CSL-05 : le contenu d un heredoc est du TEXTE, pas des commandes — une doc qui cite
# `cat REG` ne doit pas bloquer. Troncature au premier marqueur << ; une ecriture
# `>> REG << EOF` garde sa cible AVANT le marqueur, donc reste couverte plus bas.
cmd = cmd.split("<<", 1)[0]

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
# CSL-04 : wrappers transparents — la commande reelle vient APRES eux.
WRAPPERS = {"sudo", "env", "command", "nohup", "time", "xargs", "nice", "stdbuf", "caffeinate"}

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

def command_positions(toks):
    """CSL-04 : indices des tokens en position de COMMANDE — debut de segment, ou
    apres un wrapper (sudo/env/nohup/xargs...) en sautant ses options et les
    affectations VAR=val. Un nom de lecteur plein en position d ARGUMENT (motif
    grep, nom de fichier) ne declenche plus le deny."""
    out = []
    i = 0
    n = len(toks)
    while i < n:
        t = toks[i]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            i += 1
            continue
        out.append(i)
        if os.path.basename(t) in WRAPPERS:
            i += 1
            while i < n and toks[i].startswith("-"):
                i += 1
            continue
        break
    return out

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
    # CSL-06 : tolerer une quote ouvrante avant la cible (`>> "REG"`).
    if re.search(r">{1,2}\s*[\"\x27]?" + re.escape(path), seg):
        continue
    toks = tokens(seg)
    if any(os.path.basename(t) == "tee" for t in toks):
        continue
    full_read = False
    for i in command_positions(toks):
        name = os.path.basename(toks[i])
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
