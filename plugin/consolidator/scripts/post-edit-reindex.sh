#!/usr/bin/env bash
# post-edit-reindex.sh — Hook PostToolUse(Edit|Write|Bash) : si un registre mémoire
# canonique a été modifié, régénère son index (#Ligne) via reindex.sh --apply.
# L'index ne peut plus dériver du body : il est maintenu par la machine (ADR-043).
#
# Câblage (posé automatiquement par l'install du module consolidator) :
#   PostToolUse · matcher "Edit|Write|Bash" · command: bash .claude/scripts/post-edit-reindex.sh
#
# Edit/Write : le registre = tool_input.file_path. Bash (BLK-006) : détecte une ÉCRITURE
# vers un registre dans la commande (`>>`/`>` ou `tee [-a]` visant le registre — cible
# quotée comprise, CSL-07) — un `cat >> DECISIONS.md << EOF` recale donc aussi l'index.
#
# Fail-open : toute erreur → exit 0 silencieux (un hook de maintenance ne casse jamais le flux).

set -uo pipefail

# CSL-13 : préfiltre pur bash AVANT le spawn python3 (~80-120 ms payés sinon sur CHAQUE
# Edit/Write/Bash, même hors registres). SURENSEMBLE STRICT du domaine d'action du
# python : il ne retourne un chemin que si celui-ci contient .claude/memory/<REGISTRE>.md
# (REG_RE côté Bash, filtre parent/base côté Edit/Write) — la sous-chaîne littérale
# « .claude/memory/ » est donc présente dans le payload JSON dès qu'une action est due
# (l'encodeur JSON standard n'échappe ni « . » ni « / »). Skip sans perte sinon.
PAYLOAD="$(cat 2>/dev/null || true)"
case "$PAYLOAD" in
  *'.claude/memory/'*) : ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 0

FILE_PATH="$(printf '%s' "$PAYLOAD" | python3 -c '
import json, os, re, sys
try:
    p = json.load(sys.stdin)
except Exception:
    print("")
    sys.exit(0)
ti = p.get("tool_input") or {}
if p.get("tool_name") == "Bash":
    cmd = ti.get("command") or ""
    reg = (r"(?P<path>[^\s\"\x27<>|;&]*\.claude/memory/"
           r"(?:DECISIONS|ADR|BDR|LEARNINGS|BLOCKERS|EVALS|JOURNAL|ITERATION_LOG)\.md)")
    hit = ""
    for m in re.finditer(reg, cmd):
        path = m.group("path")
        before = cmd[:m.start()]
        # Ecriture = redirection juste avant le chemin, ou tee visant le chemin.
        # CSL-07 : tolerer une quote ouvrante avant la cible (`>> "REG"`) — symetrique
        # de l exclusion ecriture du guard Bash (CSL-06), sinon l index ne se recalait
        # jamais apres un append quote.
        if re.search(r">{1,2}\s*[\"\x27]?$", before) or re.search(r"\btee\s+(-a\s+)?[\"\x27]?$", before):
            hit = path
            break
    if hit and not os.path.isabs(hit):
        hit = os.path.join(p.get("cwd") or ".", hit)
    print(hit)
else:
    print(ti.get("file_path") or "")
' 2>/dev/null)" || exit 0

[ -n "$FILE_PATH" ] || exit 0

BASE="$(basename "$FILE_PATH")"
PARENT="$(dirname "$FILE_PATH")"
# Registre canonique = DIRECTEMENT sous .claude/memory (frontière de chemin exigée,
# symétrique CSL-12 : le motif `*.claude/memory` matchait aussi "my.claude/memory"
# et aurait réindexé — donc réécrit — un fichier hors registres).
case "$PARENT" in
  .claude/memory|*/.claude/memory) : ;;
  *) exit 0 ;;
esac

case "$BASE" in
  DECISIONS.md)     REGISTER="DECISIONS" ;;
  LEARNINGS.md)     REGISTER="LEARNINGS" ;;
  BLOCKERS.md)      REGISTER="BLOCKERS" ;;
  EVALS.md)         REGISTER="EVALS" ;;
  JOURNAL.md)       REGISTER="JOURNAL" ;;
  ADR.md)           REGISTER="ADR" ;;
  BDR.md)           REGISTER="BDR" ;;
  ITERATION_LOG.md) REGISTER="ITERATION_LOG" ;;
  *) exit 0 ;;
esac

REINDEX="$(dirname "$0")/reindex.sh"
[ -f "$REINDEX" ] || exit 0

# MEMORY_DIR = dossier réel du fichier édité (le lab peut être ouvert depuis n'importe quel cwd).
# reindex.sh --apply isole désormais les backups dans <memory>/.backups/ (gitignoré) ET les
# fait tourner (garde 3) lui-même (ADR-049) — ce hook n'a plus de rotation à faire.
MEMORY_DIR="$PARENT" bash "$REINDEX" "--register=$REGISTER" --apply >/dev/null 2>&1 || true
exit 0
