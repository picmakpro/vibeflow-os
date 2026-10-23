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
# CE QU'IL RECONNAÎT COMME INVOCATION : un mot-interpréteur suivi, après d'éventuelles options,
# d'un programme INLINE (`-c`, `-m`, `-` ou une redirection `<`/`<<`/`<<<`). Mot-interpréteur :
#   - le BASENAME vaut `py`, `python`, `python3`, `python3.12`, `python3.14t`, `python.exe`, `pypy3`…
#     (`/usr/bin/python3`, `"$HOME/.venv/bin/python"`), ou `py -3` ;
#   - une variable dont le nom contient `py` sans casse, chiffres admis (`$PYBIN`, `$py_invoke`,
#     `$PYTHON3`, `$PY3`, `${PYTHON:-python3}`), ou `$cand` (sondes) ;
#   - une variable SANS « py » dont le MÊME fichier affecte une valeur qui est un python
#     (`INTERP=python3`, `RUNTIME="$(command -v python3)"`, `for runner in python3 python`) ou dont
#     le défaut `${NOM:-python3}` en est un. Une valeur qui LANCE python (`out=$(python3 -c …)`)
#     capture une sortie : ce n'est pas un interpréteur.
# Les options `-W`/`-X`/`-Q` et `--check-hash-based-pycs` consomment leur argument (`python3 -W ignore
# -c`), les lignes jointes par `\` sont lues comme une seule (`python3 \` puis `-c` à la ligne
# suivante). Les opérateurs collés au mot suivant sont séparés avant lecture (`echo x|python3 -c`,
# `;python3`, `&&python3`, `$(…|python3 -c …)`, `<(python3 -c …)`) : `PYBIN=python3; "$PYBIN" -c …` et
# `[ -n "$PYBIN" ] || PYBIN=python3; "$PYBIN" -c …` sont donc lus en deux commandes. `-m` met aussi le cwd
# en tête de `sys.path` : c'est une invocation à isoler. Ce qui rend une invocation conforme :
#   - `-I` (en grappe aussi : `-Ic`) ;
#   - `-P` SEULEMENT si l'invocation porte le marqueur `vf-py311` (le site garantit Python >= 3.11 ;
#     `-P` n'existe pas avant — `/usr/bin/python3` de macOS est un 3.9) ;
#   - la purge `sys.path[:] = [p for p in sys.path if p]`, portée par CETTE invocation (jusqu'au
#     prochain interpréteur de la ligne, pas la ligne entière) et placée AVANT le premier import
#     d'un module autre que `sys` (`import json, sys; sys.path[:] = …` reste refusé) ;
#   - le marqueur `vf-py-isolation-ok` dans l'invocation — réservé au cas où le littéral EST le sujet.
# MODE UTF-8 INCONDITIONNEL (H7, révisé par #153). `-I` implique `-E` : un `PYTHONUTF8=1` posé par
# l'utilisateur serait perdu en silence, et sous Windows (CPython, cp1252 par défaut) un `print("✓")` ou
# la lecture d'un JSON accentué échoue. Le mode UTF-8 est donc posé SANS condition (`-X utf8` agit malgré
# `-I`; PEP 540, défaut en Python 3.15 — PEP 686) : toute invocation isolée par `-I` doit porter `$PYX`,
# NON quoté (un `"$PYX"` vide serait un argument vide), après `-I` :
#   `python3 -I $PYX -c …`, avec, une fois par fichier, la définition canonique `PYX="-Xutf8"`
#   (sans elle, `set -u` est fatal : refusé). TOUTE autre définition de PYX est refusée — notamment
#   l'ancienne forme conditionnelle `PYX=""; [ "${PYTHONUTF8:-}" != "1" ] || PYX="-Xutf8"`, qui laissait
#   Windows en cp1252 tant que l'utilisateur n'avait pas posé PYTHONUTF8=1.
# Exemption : le marqueur `vf-pyx-ok` SUR LA LIGNE (sonde de version, sortie jetée). `vf_python` (lib
# vf-portable.sh) passe toujours `-X utf8` elle-même ; les invocations à purge de `sys.path` ne sont pas
# visées (elles ne portent pas `-I`).
# Les lignes de commentaire pur sont ignorées.
# TAILLE DES PROGRAMMES `-c` LITTÉRAUX (#149). Windows plafonne la ligne de commande d'un processus à
# 32 767 caractères : un `python3 -c "…"` de 60 Ko y échoue (`Argument list too long`, rc 126), et un hook
# câblé en `|| true` ou `|| exit 0` devient inerte en silence. Tout littéral entre guillemets qui suit `-c`
# (simples ou doubles, sur plusieurs lignes, fichier entier hors `*/tests/*`) est mesuré en OCTETS
# (majorant des caractères UTF-16) et refusé au-delà de ARGMAX = 30 000. Un gros programme passe par
# l'entrée standard (`python3 -I $PYX - <<<"…"`) ou, si l'entrée standard porte déjà une charge, en tête
# de celle-ci (guard-driver-lock.sh). HORS PORTÉE : un programme tenu dans une variable (`-c "$PROG"`).
#
# HORS PORTÉE (dit, pas promis) : une variable sans « py » dont l'affectation vit hors du fichier
# (environnement, fichier sourcé) ; un opérateur ou un nom de commande reconstruit à l'exécution
# (`eval`, `$(printf …)`), un alias, un interpréteur nommé autrement (`python3.14-x`, `cpython`) ; un
# `;`/`|` figurant DANS un littéral entre guillemets (la normalisation ne lit pas les guillemets : au pire
# un faux positif de comptage, jamais un trou) ; l'exigence `$PYX` des lancements de FICHIER (`-E`) ; `python3` nu en bout de tube (programme lu sur stdin sans `-`) ;
# `__import__` avant la purge ; les instructions EN PROSE exécutées par un modèle (`*.md` — liste
# connue : plugin/skill-creator/skills/skill-creator/SKILL.md l.238, 391, 422, `python -m scripts.*`,
# skill VENDU en amont, non modifié ici) ; les skills vendus en général ; les suites `*/tests/*`.
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
# Mot dépouillé de ses guillemets, de "$(" et d'un préfixe NOM= (variable d'environnement posée).
function strip(w) {
  sub(/^[A-Za-z_][A-Za-z0-9_]*=/, "", w)
  sub(/^[("'`]+/, "", w); sub(/^\$\(/, "", w); sub(/^[("'`]+/, "", w)
  sub(/[)"'`;]+$/, "", w)
  return w
}
# Un chemin/mot est un interpréteur si son BASENAME vaut py, python, python3, python3.12…
function is_pyword(s,   b) {
  b = s; sub(/.*\//, "", b)
  return (b ~ /^(py|python|pypy)[0-9.]*[tdm]*(\.exe)?$/)
}
# Une variable est un interpréteur si : son nom contient « py » (sans casse, chiffres admis :
# $PY3, $PYTHON3), OU c'est $cand (sondes), OU le même fichier lui affecte une valeur qui est un
# python (NOM=python3, NOM="$(command -v python3)", for NOM in python3 …), OU son défaut
# ${NOM:-python3} en est un. Une variable sans « py » dont l'affectation est hors du fichier
# n'est PAS vue (limite assumée, écrite dans l'en-tête).
function var_is_interp(w,   inner, name, rest) {
  inner = w; sub(/^\$\{?/, "", inner); sub(/\}$/, "", inner)
  name = inner; sub(/[^A-Za-z0-9_].*$/, "", name)
  rest = substr(inner, length(name) + 1)
  if (name == "PYX") return 0   # mode UTF-8 (H7/#153) : une option, pas un interpréteur
  if (name ~ /[Pp][Yy]/) return 1
  if (name == "cand") return 1
  if (name in PYVARS) return 1
  if (rest ~ PYWORD_RE) return 1
  return 0
}
function is_interp(w) {
  if (w ~ /^\$/) return var_is_interp(w)
  return is_pyword(w)
}
# Affectations d'un python à une variable, relevées sur la ligne jointe.
function collect_vars(line,   n, w, i, k, name, tail) {
  n = split(line, w, /[ \t]+/)
  for (i = 1; i <= n; i++) {
    if (w[i] !~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue
    name = w[i]; sub(/=.*/, "", name)
    tail = ""
    for (k = i; k <= n; k++) tail = tail " " w[k]
    sub(/^[^=]*=/, "", tail)
    # une valeur qui LANCE python (NOM=$(python3 -c …)) capture une sortie, pas un interpréteur
    if (tail ~ PYWORD_RE && tail !~ /(python[0-9.]*|py)[ \t]+(-[A-Za-z]|<)/) PYVARS[name] = 1
  }
  if (line ~ /(^|[ \t;])for[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]+in[ \t]/ && line ~ PYWORD_RE) {
    name = line; sub(/.*for[ \t]+/, "", name); sub(/[ \t].*/, "", name); PYVARS[name] = 1
  }
}
# Vrai si un import d'un module AUTRE que sys figure dans p (le début de l'invocation, avant la purge).
function pre_import_bad(p,   rest) {
  rest = p
  while (match(rest, /(^|[^A-Za-z0-9_])(import|from)[ \t]+/)) {
    rest = substr(rest, RSTART + RLENGTH)
    if (rest ~ /^sys[ \t]*($|[;'"])/) continue
    return 1
  }
  return 0
}
# La purge exempte l'INVOCATION (span) qui la porte, et seulement si aucun import d'un module non
# sys ne la précède dans cette invocation.
function purge_ok(span,   idx) {
  idx = index(span, PURGE)
  if (idx == 0) return 0
  return !pre_import_bad(substr(span, 1, idx - 1))
}
# Sépare les opérateurs collés au mot suivant (`echo x|python3 -c`, `;python3`, `&&python3`,
# `<(python3 -c …)`) : sans cela le mot-interpréteur est invisible, collé à son voisin. `&` seul
# (`2>&1`) n'est pas touché.
function normalize(line) {
  gsub(/[<>]\(/, " ( ", line)
  gsub(/&&/, " \\&\\& ", line)
  gsub(/[|;]/, " & ", line)
  return line
}
function scan_line(f, ln, line,   n, w, i, j, k, word, iso, pflag, prog, skip, x, c, m, span, len, hasx, qx) {
  if (line ~ /^[ \t]*#/) return
  n = split(normalize(line), w, /[ \t]+/)
  for (i = 1; i <= n; i++) {
    word = strip(w[i])
    if (!is_interp(word)) continue
    if (i > 1 && w[i - 1] ~ /^[0-9]*(>|>>|<|<<)$/) continue   # cible d'une redirection, pas un interpreteur
    j = i + 1
    if (word == "py" && w[j] == "-3") j++
    iso = 0; pflag = 0; prog = 0; skip = 0; hasx = 0; qx = 0
    for (; j <= n; j++) {
      x = w[j]
      if (skip) { skip = 0; continue }
      if (x ~ /^\$(\{PYX\}|PYX)$/) { hasx = 1; continue }  # mode UTF-8 inconditionnel (H7/#153), NON quoté
      if (x ~ /^"\$(\{PYX\}|PYX)"$/) { qx = 1; continue }   # quotée : un argument vide casserait l'appel
      if (x ~ /^[0-9]*>/) continue                            # 2>/dev/null intercalé
      if (x ~ /^</) { prog = 1; break }                       # stdin : < f, <<EOF, <<<
      if (x == "-") { prog = 1; break }                       # programme sur stdin
      if (x == "--check-hash-based-pycs") { skip = 1; continue }   # seule option longue à argument
      if (x ~ /^--/) continue                                 # --version…
      if (x !~ /^-/) break                                    # un fichier : sys.path[0] = son dossier
      len = length(x)
      for (k = 2; k <= len; k++) {
        c = substr(x, k, 1)
        if (c == "I") iso = 1
        else if (c == "P") pflag = 1
        else if (c == "c" || c == "m") { prog = 1; break }    # -c / -m : le reste est le programme
        else if (c == "W" || c == "X" || c == "Q") { if (k == len) skip = 1; break }   # consomment un argument
      }
      if (prog) break
    }
    if (!prog) { i = j; continue }   # lancement d'un fichier : ses arguments ne sont pas des interpreteurs
    SITES++
    # span = cette invocation seule : jusqu'au prochain interpréteur de la ligne (H2)
    m = n + 1
    for (k = j + 1; k <= n; k++) {
      if (is_interp(strip(w[k])) && !(w[k - 1] ~ /^[0-9]*(>|>>|<|<<)$/)) { m = k; break }
    }
    span = ""
    for (k = i; k < m; k++) span = span " " w[k]
    if (qx) { BAD++; printf "%s:%d: $PYX quoté (argument vide) : %s\n", f, ln, substr(line, 1, 140) > "/dev/stderr"; break }
    if (iso) {
      # H7/#153 : -I ignore PYTHONUTF8 ; chaque invocation isolée doit poser le mode UTF-8 ($PYX) ou déclarer
      # `vf-pyx-ok` SUR LA LIGNE (sonde de version dont la sortie est jetée ; la ligne, pas l'invocation :
      # `$PY3_PROBE` est lui-même vu comme un interpréteur et couperait l'invocation avant le marqueur).
      if (hasx || index(line, "vf-pyx-ok") > 0) continue
      BAD++
      printf "%s:%d: -I sans $PYX (mode UTF-8 non posé) : %s\n", f, ln, substr(line, 1, 140) > "/dev/stderr"
      break
    }
    if (pflag && index(span, "vf-py311") > 0) continue   # -P (Python >= 3.11) : le site déclare la garantie
    if (index(span, "vf-py-isolation-ok") > 0) continue
    if (purge_ok(span)) continue
    BAD++
    printf "%s:%d: %s\n", f, ln, substr(line, 1, 160) > "/dev/stderr"
    break
  }
}
# #149 : un littéral `-c "…"` / `-c '…'` de plus de ARGMAX octets ne passe pas la ligne de commande Windows.
function scan_argmax(f, txt,   base, rest, q, i, n, c, len, pre) {
  base = 0; rest = txt
  while (match(rest, /-c[ \t]+["']/)) {
    q = substr(rest, RSTART + RLENGTH - 1, 1)
    i = RSTART + RLENGTH; n = 0; len = length(rest)
    while (i <= len) {
      c = substr(rest, i, 1)
      if (q == "\"" && c == "\\") { i += 2; n += 2; continue }
      if (c == q) break
      i++; n++
    }
    if (n > ARGMAX) {
      BAD++
      pre = substr(txt, 1, base + RSTART)
      printf "%s:%d: programme -c de %d octets (> %d) : Argument list too long sous Windows — le passer par l'entrée standard\n", f, gsub(/\n/, "", pre) + 1, n, ARGMAX > "/dev/stderr"
    }
    base += i; rest = substr(rest, i + 1)
  }
}
function scan_file(f,   nl, raw, acc, start, cnt, k, L, LN, uses, hasdef, t, TXT) {
  delete PYVARS
  nl = 0; acc = ""; start = 0; cnt = 0; TXT = ""
  while ((getline raw < f) > 0) {
    TXT = TXT raw "\n"
    cnt++
    if (acc == "") start = cnt
    if (raw !~ /^[ \t]*#/ && raw ~ /\\[ \t]*$/) { sub(/\\[ \t]*$/, " ", raw); acc = acc raw; continue }
    nl++; L[nl] = acc raw; LN[nl] = start; acc = ""
  }
  if (acc != "") { nl++; L[nl] = acc; LN[nl] = start }
  close(f)
  uses = 0; hasdef = 0
  for (k = 1; k <= nl; k++) {
    if (L[k] ~ /^[ \t]*#/) continue
    if (L[k] ~ /\$\{?PYX\}?/) uses = 1
    t = L[k]; sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
    if (t == CANON) hasdef = 1
    else if (L[k] ~ /(^|[^A-Za-z0-9_])PYX=/) {   # #153 : aucune autre définition de PYX (forme conditionnelle, PYX="" …)
      BAD++
      printf "%s:%d: définition de PYX autre que la canonique (%s) — l'UTF-8 doit être inconditionnel : %s\n", f, LN[k], CANON, substr(L[k], 1, 120) > "/dev/stderr"
    }
  }
  if (uses && !hasdef) {
    BAD++
    printf "%s:1: $PYX utilisé sans la définition canonique (%s) — set -u fatal\n", f, CANON > "/dev/stderr"
  }
  scan_argmax(f, TXT)
  for (k = 1; k <= nl; k++) collect_vars(L[k])
  for (k = 1; k <= nl; k++) scan_line(f, LN[k], L[k])
}
BEGIN {
  PYVARS["_"] = 1; delete PYVARS
  PURGE = "sys.path[:] = [p for p in sys.path if p]"
  CANON = "PYX=\"-Xutf8\""
  ARGMAX = 30000
  PYWORD_RE = "(^|[^A-Za-z0-9_])(python[0-9.]*[tdm]*(\\.exe)?|pypy[0-9.]*|py)([^A-Za-z0-9_]|$)"
}
FNR == 1 { scan_file(FILENAME) }
{ next }
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
  echo "[check-python-isolation] ÉCHEC : $BAD violation(s) sur $SITES invocation(s) inspectée(s) — isolation : ajouter -I (ou la purge de sys.path avant tout import, ou -P + vf-py311) ; taille -c : passer le programme par l'entrée standard" >&2
  exit 1
fi
echo "[check-python-isolation] OK : $SITES invocation(s) inline inspectée(s), toutes isolées (${#FILES[@]} fichiers)"
exit 0
