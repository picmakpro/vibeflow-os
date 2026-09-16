#!/usr/bin/env bash
# check-module-bump.sh — verifie qu'un module a ete bumpe par un commit PROPRE A LA BRANCHE
# (jamais un numero de version fige : la cible est DERIVEE de la VERSION qui precede ce commit).
#
# Usage: check-module-bump.sh <module> patch|minor [--main-ref <ref>] [--root <dir>]
#
# La base de comparaison vient TOUJOURS de phase-base.sh (jamais recalculee ici) : sans
# --main-ref, phase-base.sh auto-resout origin/main / main ; avec --main-ref, il est transmis
# tel quel. « Commit propre » = git rev-list --no-merges HEAD --not <base> -- <chemin> : aucun
# tri par sujet de commit.
#
# Exit codes: 0 = bump conforme ; 1 = aucun bump propre, ou triade/CHANGELOG desalignes ;
#             2 = usage invalide, module absent, ou pas un depot git (propage aussi depuis
#             phase-base.sh, par ex. aucune ref main resolue).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHASE_BASE="$SCRIPT_DIR/phase-base.sh"

MODULE=""
KIND=""
MAIN_REF=""
ROOT="."
POS=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --main-ref)
      [ "$#" -ge 2 ] || { echo "[check-module-bump] --main-ref necessite une valeur" >&2; exit 2; }
      MAIN_REF="$2"; shift 2 ;;
    --root)
      [ "$#" -ge 2 ] || { echo "[check-module-bump] --root necessite une valeur" >&2; exit 2; }
      ROOT="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    -*) echo "[check-module-bump] argument inconnu : $1" >&2; exit 2 ;;
    *)
      if [ "$POS" -eq 0 ]; then MODULE="$1"; POS=1;
      elif [ "$POS" -eq 1 ]; then KIND="$1"; POS=2;
      else echo "[check-module-bump] argument positionnel en trop : $1" >&2; exit 2; fi
      shift ;;
  esac
done

[ -n "$MODULE" ] && [ -n "$KIND" ] || { echo "[check-module-bump] usage: check-module-bump.sh <module> patch|minor [--main-ref <ref>] [--root <dir>]" >&2; exit 2; }
case "$KIND" in
  patch|minor) ;;
  *) echo "[check-module-bump] type inconnu (attendu patch|minor) : $KIND" >&2; exit 2 ;;
esac

git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "[check-module-bump] --root n'est pas un depot git : $ROOT" >&2
  exit 2
}

[ -d "$ROOT/plugin/$MODULE" ] || {
  echo "[check-module-bump] module absent : plugin/$MODULE" >&2
  exit 2
}

TMPD="$(mktemp -d)" || { echo "[check-module-bump] mktemp -d a echoue" >&2; exit 2; }
trap 'rm -rf "$TMPD"' EXIT

BASE=""
if [ -n "$MAIN_REF" ]; then
  BASE="$(bash "$PHASE_BASE" --root "$ROOT" --main-ref "$MAIN_REF" 2>"$TMPD/pb.err")"
else
  BASE="$(bash "$PHASE_BASE" --root "$ROOT" 2>"$TMPD/pb.err")"
fi
PB_RC=$?
if [ "$PB_RC" -ne 0 ] || [ -z "$BASE" ]; then
  cat "$TMPD/pb.err" >&2
  echo "[check-module-bump] base de branche introuvable (phase-base.sh rc=$PB_RC)" >&2
  exit 2
fi

VFILE="plugin/$MODULE/VERSION"
COMMITS_FILE="$TMPD/commits"
git -C "$ROOT" rev-list --no-merges HEAD --not "$BASE" -- "$VFILE" > "$COMMITS_FILE" 2>"$TMPD/rl.err"

C="$(awk 'NR==1{print; exit}' "$COMMITS_FILE")"
if [ -z "$C" ]; then
  echo "[check-module-bump] $MODULE : aucun bump propre a la branche"
  exit 1
fi

read_version() { # <commit-ish>:<path> -> version brute (avec prefixe v), stdout
  git -C "$ROOT" show "$1" 2>/dev/null | awk 'NR==1{print; exit}'
}

split_version() { # <v-prefixed> -> X Y Z sur stdout (une ligne "X Y Z"), rc 1 si mal forme
  local raw="$1" bare
  bare="${raw#v}"
  bare="$(printf '%s' "$bare" | tr -d '[:space:]')"
  case "$bare" in
    [0-9]*.[0-9]*.[0-9]*)
      local x y z rest
      x="${bare%%.*}"; rest="${bare#*.}"
      y="${rest%%.*}"; z="${rest#*.}"
      case "$x$y$z" in
        *[!0-9]*) return 1 ;;
      esac
      printf '%s %s %s\n' "$x" "$y" "$z"
      return 0 ;;
    *) return 1 ;;
  esac
}

PRECEDENTE="$(read_version "$C^:$VFILE")"
if [ -z "$PRECEDENTE" ]; then
  echo "[check-module-bump] $MODULE : VERSION illisible avant le commit propre $C" >&2
  exit 1
fi

PARTS="$(split_version "$PRECEDENTE")" || {
  echo "[check-module-bump] $MODULE : VERSION precedente mal formee : $PRECEDENTE" >&2
  exit 1
}
X="$(printf '%s' "$PARTS" | awk '{print $1}')"
Y="$(printf '%s' "$PARTS" | awk '{print $2}')"
Z="$(printf '%s' "$PARTS" | awk '{print $3}')"

if [ "$KIND" = "patch" ]; then
  Z=$((Z + 1))
else
  Y=$((Y + 1)); Z=0
fi
CIBLE="v${X}.${Y}.${Z}"

echo "cible derivee $MODULE : $PRECEDENTE → $CIBLE"

FAIL=0

CUR_VERSION_RAW="$(awk 'NR==1{print; exit}' "$ROOT/$VFILE" 2>/dev/null)"
CUR_VERSION="$(printf '%s' "$CUR_VERSION_RAW" | tr -d '[:space:]')"
if [ "$CUR_VERSION" != "$CIBLE" ]; then
  echo "[check-module-bump] $MODULE : VERSION courant '$CUR_VERSION' != cible '$CIBLE'" >&2
  FAIL=1
fi

MJSON="$ROOT/plugin/$MODULE/module.json"
MJ_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MJSON" 2>/dev/null | head -1)"
if [ "$MJ_VERSION" != "$CIBLE" ]; then
  echo "[check-module-bump] $MODULE : module.json .version '$MJ_VERSION' != cible '$CIBLE'" >&2
  FAIL=1
fi

README="$ROOT/plugin/$MODULE/README.md"
if [ -f "$README" ]; then
  RLINE="$(grep -m1 '\*\*Version\*\*' "$README" 2>/dev/null || true)"
  if [ -n "$RLINE" ]; then
    case "$RLINE" in
      *"$CIBLE"*) ;;
      *)
        echo "[check-module-bump] $MODULE : README **Version** ne cite pas $CIBLE : $RLINE" >&2
        FAIL=1 ;;
    esac
  fi
fi

CHANGELOG="$ROOT/plugin/$MODULE/CHANGELOG.md"
CL_LINE="$(awk '/^## \[/{print; exit}' "$CHANGELOG" 2>/dev/null || true)"
case "$CL_LINE" in
  "## [$CIBLE]"*)
    case "$CL_LINE" in
      *"Phase 40.1"*) ;;
      *)
        echo "[check-module-bump] $MODULE : entree CHANGELOG sans 'Phase 40.1' : $CL_LINE" >&2
        FAIL=1 ;;
    esac ;;
  *)
    echo "[check-module-bump] $MODULE : premiere entree CHANGELOG '$CL_LINE' != '## [$CIBLE]…'" >&2
    FAIL=1 ;;
esac

TOUCHED="$TMPD/touched"
git -C "$ROOT" diff-tree --no-commit-id --name-only -r "$C" > "$TOUCHED" 2>"$TMPD/dt.err"
if ! grep -Fxq "plugin/$MODULE/module.json" "$TOUCHED"; then
  echo "[check-module-bump] $MODULE : le commit propre $C ne touche pas module.json" >&2
  FAIL=1
fi
if ! grep -Fxq "plugin/$MODULE/CHANGELOG.md" "$TOUCHED"; then
  echo "[check-module-bump] $MODULE : le commit propre $C ne touche pas CHANGELOG.md" >&2
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "[check-module-bump] $MODULE : bump $KIND conforme ($PRECEDENTE → $CIBLE)"
  exit 0
fi

exit 1
