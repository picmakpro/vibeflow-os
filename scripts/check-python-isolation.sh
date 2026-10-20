#!/usr/bin/env bash
# check-python-isolation.sh — Gate : aucune invocation inline de Python non isolée dans les
# scripts livrés (H-1, audit Phase 58 ; hotfix 2026-10-20).
#
# LE DÉFAUT QU'IL GARDE. `python3 -c …` et `python3 - <<EOF` (stdin) mettent '' — le dossier
# courant — en tête de `sys.path`. Un `json.py` posé à la racine d'un dépôt cloné est alors importé
# et EXÉCUTÉ par tout script VibeFlow lancé depuis ce lab : hooks PreToolUse (à chaque outil),
# garde mémoire, merge-hooks à la pose. Le correctif est `-I` (mode isolé : ni cwd, ni PYTHON*, ni
# site utilisateur) ; la forme alternative reconnue est la purge explicite `sys.path[:] = [p for p
# in sys.path if p]` — seule façon d'isoler SANS perdre le site utilisateur (PyYAML en `--user`)
# sur un Python < 3.11, où `-P` n'existe pas. `vf_python` isole elle-même : ses appelants n'ont rien
# à écrire. Une invocation qui lance un FICHIER (`python3 "$script"`) n'est pas visée : sys.path[0]
# y est le dossier du script, jamais le cwd.
#
# CE QU'IL BALAIE : les fichiers SUIVIS par git sous plugin/, scripts/ et .github/, hors
# `*/tests/*` (les suites tournent depuis le dépôt de distribution, sur des fixtures qu'elles
# fabriquent — elles ne sont pas posées chez l'utilisateur), hors `*.md` (prose) et `*.py` (du
# Python, pas une invocation), hors ce gate. Lecture à `awk` seul : le `grep` de certains postes de
# dev est proxifié et tronque en silence — un gate qui compte dessus rend un vert à vide.
#
# CE QU'IL RECONNAÎT COMME INVOCATION : un mot-interpréteur — `python`, `python3`, `py -3`, ou une
# variable dont le nom contient `py` (`$PYBIN`, `$pybin`, `$py_invoke`…), `$cand` (sondes) — suivi, après
# d'éventuelles options, de `-c`, de `-` (programme sur stdin) ou d'une redirection `<`/`<<`. Une
# option `-I` ou `-P` (en grappe aussi : `-Ic`) rend l'invocation conforme. Les lignes de
# commentaire pur sont ignorées. Échappatoire explicite, ligne par ligne : le marqueur
# `vf-py-isolation-ok` sur la ligne — réservé au cas où le littéral EST le sujet.
#
# Codes de sortie (QUAL-01) :
#   0  = aucune invocation inline non isolée
#   1  = au moins une (liste fichier:ligne sur stderr)
#   3  = NON VÉRIFIABLE — pas un dépôt git, univers vide, ou ZÉRO invocation inspectée (un gate qui
#        n'a rien vu ne rend jamais un vert)
#   64 = erreur d'usage
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
usage() { echo "usage : check-python-isolation.sh [--path DIR] [--min-sites N]" >&2; exit 64; }
MIN_SITES=1
while [ $# -gt 0 ]; do
  case "$1" in
    --path)      [ $# -ge 2 ] || usage; ROOT="$2"; shift 2 ;;
    --path=*)    ROOT="${1#--path=}"; shift ;;
    --min-sites) [ $# -ge 2 ] || usage; MIN_SITES="$2"; shift 2 ;;
    -h|--help)   usage ;;
    *)           echo "[check-python-isolation] argument inconnu : $1" >&2; usage ;;
  esac
done
case "$MIN_SITES" in ''|*[!0-9]*) echo "[check-python-isolation] --min-sites attend un entier" >&2; exit 64 ;; esac

if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[check-python-isolation] NON VÉRIFIABLE : $ROOT n'est pas un dépôt git" >&2
  exit 3
fi
cd "$ROOT" || exit 3

FILES=()
while IFS= read -r -d '' f; do
  case "$f" in
    */tests/*|*.md|*.py|scripts/check-python-isolation.sh) continue ;;
  esac
  [ -f "$f" ] || continue
  FILES+=("$f")
done < <(git ls-files -z -- plugin scripts .github 2>/dev/null)
if [ "${#FILES[@]}" -eq 0 ]; then
  echo "[check-python-isolation] NON VÉRIFIABLE : aucun fichier à balayer sous plugin/ scripts/ .github/" >&2
  exit 3
fi

PROG="$(mktemp "${TMPDIR:-/tmp}/check-python-isolation.XXXXXX")" || exit 3
trap 'rm -f "$PROG" "$PROG.out"' EXIT
cat > "$PROG" <<'AWK'
# Un mot est un interpréteur s'il (dépouillé de ses guillemets et de "$(") vaut python, python3,
# py (suivi de -3), une variable dont le nom contient py (sans casse) ou $cand (candidat de sonde).
function strip(w) {
  sub(/^[A-Za-z_][A-Za-z0-9_]*=/, "", w)
  sub(/^[("'`]+/, "", w); sub(/^\$\(/, "", w); sub(/^[("'`]+/, "", w)
  sub(/[)"'`;]+$/, "", w)
  return w
}
function is_interp(w) {
  if (w == "python" || w == "python3" || w == "py") return 1
  if (w ~ /^\$\{?[A-Za-z_]*[Pp][Yy][A-Za-z_]*\}?$/) return 1
  if (w == "$cand" || w == "${cand}") return 1
  return 0
}
{
  line = $0
  if (line ~ /^[ \t]*#/) next
  n = split(line, w, /[ \t]+/)
  for (i = 1; i <= n; i++) {
    word = strip(w[i])
    if (!is_interp(word)) continue
    if (i > 1 && w[i - 1] ~ /^[0-9]*(>|>>|<|<<)$/) continue   # cible d'une redirection, pas un interpreteur
    j = i + 1
    if (word == "py" && w[j] == "-3") j++
    iso = 0; prog = 0
    for (; j <= n; j++) {
      x = w[j]
      if (x ~ /^-[A-Za-z]*[IP][A-Za-z]*$/) { iso = 1; prog = 1; break }
      if (x == "-c" || x == "-" || x ~ /^-[A-Za-z]*c$/ || x ~ /^<</ || x == "<") { prog = 1; break }
      if (x ~ /^-/) continue
      break
    }
    if (!prog) { i = j; continue }   # lancement d'un fichier : ses arguments ne sont pas des interpreteurs
    SITES++
    if (iso) continue
    if (index(line, "vf-py-isolation-ok") > 0) continue
    if (index(line, "sys.path[:] = [p for p in sys.path if p]") > 0) continue
    BAD++
    printf "%s:%d: %s\n", FILENAME, FNR, substr(line, 1, 160) > "/dev/stderr"
    break
  }
}
END { printf "%d %d\n", SITES + 0, BAD + 0 }
AWK
LC_ALL=C awk -f "$PROG" "${FILES[@]}" > "$PROG.out" 2>&1
RC_AWK=$?
if [ "$RC_AWK" -ne 0 ]; then
  cat "$PROG.out" >&2
  echo "[check-python-isolation] NON VÉRIFIABLE : le balayage awk a échoué (rc=$RC_AWK)" >&2
  exit 3
fi
# La dernière ligne est le compte ; le reste (stderr d'awk, fusionné) est la liste des violations.
COUNTS="$(tail -n 1 "$PROG.out")"
SITES="${COUNTS%% *}"; BAD="${COUNTS##* }"
case "$SITES$BAD" in ''|*[!0-9]*) cat "$PROG.out" >&2; echo "[check-python-isolation] NON VÉRIFIABLE : sortie awk illisible" >&2; exit 3 ;; esac
if [ "$SITES" -lt "$MIN_SITES" ]; then
  echo "[check-python-isolation] NON VÉRIFIABLE : $SITES invocation(s) inspectée(s) (< $MIN_SITES) — un balayage qui n'a rien vu n'est pas un vert" >&2
  exit 3
fi
if [ "$BAD" -gt 0 ]; then
  sed '$d' "$PROG.out" >&2
  echo "[check-python-isolation] ÉCHEC : $BAD invocation(s) inline non isolée(s) sur $SITES inspectée(s) — ajouter -I (ou -P, ou la purge de sys.path)" >&2
  exit 1
fi
echo "[check-python-isolation] OK : $SITES invocation(s) inline inspectée(s), toutes isolées (${#FILES[@]} fichiers)"
exit 0
