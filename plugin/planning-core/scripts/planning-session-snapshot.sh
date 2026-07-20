#!/usr/bin/env bash
# planning-session-snapshot.sh — Hook SessionStart (toutes sources) : photographie l'état git
# au début de la session. Sert de BASELINE au guard Stop (guard-planning-updated.sh).
#
# Pourquoi (ADR-050 amendée 2026-07-20) : Stop se déclenche à CHAQUE fin de tour assistant.
# Sans baseline, le guard confondait « working tree sale » et « changé pendant CETTE session »
# → faux positifs systématiques : dirt préexistant attribué à la session ; STATE.md mis à jour
# puis COMMITTÉ donc invisible du porcelain. La baseline rend l'attribution possible :
#   - HEAD de départ  → ce qui a été committé PENDANT la session (fenêtre git log --since)
#   - porcelain hashé → dirt nouveau ou dont le contenu a changé PENDANT la session
#   - epoch de départ → signal mtime (planning touché pendant la session, même gitignoré)
#
# Snapshot : ${TMPDIR:-/tmp}/vibeflow-planning-guard/<cksum(repo)>-<session_id>.snap
#   ligne 1 : epoch du début de session
#   ligne 2 : sha de HEAD ("none" si repo sans commit)
#   ensuite : une ligne par entrée porcelain → "<hash blob|->\t<XY>\t<path>"
#             (hash blob calculé pour les 200 premiers fichiers existants ; "-" sinon)
#
# First-wins : si un snapshot existe déjà pour cette session (SessionStart ré-émis par un
# compact), on le CONSERVE — la baseline reste le vrai début de session.
# Fail-open : toute erreur → exit 0, silencieux (aucun stdout : rien à injecter au contexte).
set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"

# --- Identifiant de session (clé du snapshot) ---
SID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | tr -cd 'A-Za-z0-9._-')
[ -n "$SID" ] || exit 0

# --- Repo git requis (sinon le guard fail-open de toute façon) ---
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
TOP=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$TOP" ] || exit 0
cd "$TOP" 2>/dev/null || exit 0

DIR="${TMPDIR:-/tmp}/vibeflow-planning-guard"
mkdir -p "$DIR" 2>/dev/null || exit 0
KEY=$(printf '%s' "$TOP" | cksum 2>/dev/null | awk '{print $1}')
[ -n "$KEY" ] || exit 0
SNAP="$DIR/${KEY}-${SID}.snap"

# --- Rotation : purge des snapshots/marqueurs > 7 jours (portable, pas de mapfile) ---
find "$DIR" -type f \( -name '*.snap' -o -name '*.blocked' \) -mtime +7 -delete 2>/dev/null || true

# --- First-wins : un compact ré-émet SessionStart, on garde la baseline d'origine ---
[ -f "$SNAP" ] && exit 0

HEAD_SHA=$(git rev-parse HEAD 2>/dev/null || echo none)

# --- Un .planning existe-t-il ? (recherche bornée) Sinon : baseline minimale epoch+HEAD ---
HAS_PLANNING=$(find . -maxdepth 4 \( -name .git -o -name node_modules \) -prune -o -type d -name .planning -print 2>/dev/null | head -1)

TMP="$SNAP.tmp.$$"
{
  date +%s
  echo "$HEAD_SHA"
  if [ -n "$HAS_PLANNING" ]; then
    n=0
    git status --porcelain 2>/dev/null | head -2000 | while IFS= read -r line; do
      [ -n "$line" ] || continue
      xy="${line:0:2}"
      path="${line:3}"
      case "$path" in *" -> "*) path="${path##* -> }" ;; esac
      n=$((n+1))
      h="-"
      if [ "$n" -le 200 ] && [ -f "$path" ]; then
        h=$(git hash-object -- "$path" 2>/dev/null || echo "-")
        [ -n "$h" ] || h="-"
      fi
      printf '%s\t%s\t%s\n' "$h" "$xy" "$path"
    done
  fi
} > "$TMP" 2>/dev/null && mv -f "$TMP" "$SNAP" 2>/dev/null || rm -f "$TMP" 2>/dev/null || true

exit 0
