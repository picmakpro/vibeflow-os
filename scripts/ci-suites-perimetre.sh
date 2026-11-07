#!/usr/bin/env bash
# ci-suites-perimetre.sh — périmètre des suites de tests à jouer, calculé depuis les fichiers touchés
# (mission « CI sélective » ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-07 :
#  « PR sélective, main complète » — les PR ne jouent que les suites des zones touchées, le push sur main rejoue
#  tout, un label « ci: complet » force le run complet ;
#  « Module + dépendances citées » — un fichier touché sous plugin/<module>/ joue les suites de ce module, plus
#  toute suite du dépôt qui cite un chemin touché (le chemin, ou le nom de fichier quand la suite le compose).
#  Un fichier partagé joue tout. Une PR docs seules ne joue que le job des gates.)
#
# Usage : ci-suites-perimetre.sh [--liste] <base> <head>     périmètre de `git diff --name-only --no-renames <base>...<head>`
#         ci-suites-perimetre.sh [--liste] --tout "<motif>"  toutes les suites jouées avec ce motif, sans git diff
#
# Sortie par défaut (stdout) : une ligne `# mode=<tout|selection|docs-seules|vide><TAB><raison>`, puis UNE ligne par
# suite de la découverte complète, triée LC_ALL=C : `<jouee|ecartee><TAB><chemin-suite><TAB><motif>`.
# Avec --liste : seulement les chemins des suites JOUÉES, un par ligne, triés.
# Une suite a UN seul motif : tout > module > citée, et le premier fichier touché en ordre trié.
#
# La découverte passe TOUJOURS par `scripts/ci-shard-suites.sh --all` (une seule source). Les suites sont lues dans
# l'arbre de travail courant ; la racine se résout par `git rev-parse --show-toplevel`.
# Défaut conservateur : sous-sélectionner est le défaut à éviter, sur-sélectionner est acceptable.
#
# Sorties : 0 = périmètre rendu (y compris vide ou docs seules ; mode vide aussi quand aucune suite n'est retenue) · 2 = diff illisible (base/head inconnu) : la CI
# retombe alors sur le mode tout · 64 = usage.
set -u
LC_ALL=C; export LC_ALL

TAB=$(printf '\t')
usage() { echo "usage : ci-suites-perimetre.sh [--liste] <base> <head> | [--liste] --tout \"<motif>\"" >&2; exit 64; }

LISTE=0; TOUT=0; MOTIF=""; n=0; base=""; head=""
while [ $# -gt 0 ]; do
  case "$1" in
    --liste) LISTE=1 ;;
    --tout) [ $# -ge 2 ] || usage; [ -n "$2" ] || usage; TOUT=1; MOTIF=$2; shift ;;
    -*) usage ;;
    *) n=$((n + 1)); case $n in 1) base=$1 ;; 2) head=$1 ;; *) usage ;; esac ;;
  esac
  shift
done
if [ "$TOUT" -eq 1 ]; then [ "$n" -eq 0 ] || usage; else [ "$n" -eq 2 ] || usage; fi

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "ci-suites-perimetre : hors dépôt git" >&2; exit 2; }
cd "$root" || exit 2
T=$(mktemp -d "${TMPDIR:-/tmp}/vf-perimetre.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT

bash scripts/ci-shard-suites.sh --all > "$T/suites" || { echo "ci-suites-perimetre : découverte des suites en échec" >&2; exit 1; }
SUITES=(); while IFS= read -r s; do SUITES[${#SUITES[@]}]=$s; done < "$T/suites"

# cite_files <motif> : suites dont le contenu contient le motif (chaîne fixe), triées.
cite_files() {
  [ "${#SUITES[@]}" -gt 0 ] || return 0
  grep -lF -e "$1" -- "${SUITES[@]}" 2>/dev/null | sort
}

# --- Sortie ---------------------------------------------------------------------------------------------------
emit() { # $1 = mode, $2 = raison ; lit $T/joued (suite<TAB>motif)
  if [ "$LISTE" -eq 1 ]; then
    awk -F'\t' 'FILENAME == ARGV[1] { m[$1] = 1; next } ($0 in m)' "$T/joued" "$T/suites"
  else
    printf '# mode=%s\t%s\n' "$1" "$2"
    awk -F'\t' 'FILENAME == ARGV[1] { m[$1] = $2; next }
      { if ($0 in m) printf "jouee\t%s\t%s\n", $0, m[$0]; else printf "ecartee\t%s\thors périmètre\n", $0 }' "$T/joued" "$T/suites"
  fi
  exit 0
}
tout_pour_tous() { # $1 = motif ; toutes les suites jouées
  awk -v m="$1" '{ printf "%s\t%s\n", $0, m }' "$T/suites" > "$T/joued"
}

if [ "$TOUT" -eq 1 ]; then
  tout_pour_tous "tout — $MOTIF"
  emit tout "toutes les suites : $MOTIF"
fi

# --- Diff -----------------------------------------------------------------------------------------------------
git rev-parse --verify -q "${base}^{commit}" > /dev/null 2>&1 || { echo "ci-suites-perimetre : base inconnue : $base" >&2; exit 2; }
git rev-parse --verify -q "${head}^{commit}" > /dev/null 2>&1 || { echo "ci-suites-perimetre : head inconnu : $head" >&2; exit 2; }
git -c core.quotepath=off diff --name-only --no-renames "$base...$head" 2> /dev/null | sort -u > "$T/changed"
[ "${PIPESTATUS[0]}" -eq 0 ] || { echo "ci-suites-perimetre : diff illisible : $base...$head" >&2; exit 2; }
: > "$T/joued"
if [ ! -s "$T/changed" ]; then emit vide "aucun fichier touché"; fi

git ls-files | sort > "$T/tracked"
awk -F/ '{ print $NF }' "$T/tracked" > "$T/bn"

# ambigu <nom> <chemin> : le nom de fichier est porté par au moins 2 fichiers suivis (le fichier touché compte
# même quand il n'est plus suivi : supprimé ou ancien chemin d'un renommage).
ambigu() {
  local c
  c=$(grep -cxF -e "$1" "$T/bn" || true)
  grep -qxF -e "$2" "$T/tracked" || c=$((c + 1))
  [ "$c" -ge 2 ]
}

# --- Carte de classement d'un fichier touché ------------------------------------------------------------------
# classe <chemin> → doc | partage | module:<m> | hors   (le premier motif qui correspond gagne)
classe() {
  case "$1" in
    # 1. Docs : aucune suite par eux-mêmes, et ils ne déclenchent pas non plus la règle « citée ».
    #    Arbitrage Samuel, AskUserQuestion session principale, 2026-11-07, option (a) « Hors plugin/ seulement » : sont des docs
    #    docs/, .planning/, .claude/agent-memory/ et les .md À LA RACINE (sans « / » dans le chemin). Un .md sous plugin/<m>/
    #    (agent, SKILL.md, README ou CHANGELOG de module) suit la règle module + citée, parce que des suites le lisent (mesuré :
    #    37 suites lisent un agent ou un SKILL.md, 19 lisent docs/, 110 lisent .planning/). Un .md ailleurs (.github/…) est hors carte.
    docs/*|.planning/*|.claude/agent-memory/*) echo doc ;;
    # 2. Partagé → tout. (Les bibliothèques de test partagées et les scripts conductor appelés ailleurs sont
    #    reconnus dans classe_plugin ; scripts/ passe avant `*.md` : une fixture sous scripts/tests/ n'est pas une doc.)
    plugin/_internal/*) echo partage ;;
    scripts/*|.github/workflows/ci.yml) echo partage ;;
    # 3. Module : plugin/<m>/ où module.json existe (voir classe_plugin), sinon hors carte.
    plugin/*) classe_plugin "$1" ;;
    # 1 (suite). Un .md hors de la racine, hors plugin/ et hors des dossiers de docs n'est PAS une doc : hors carte (tout).
    */*.md) echo hors ;;
    *.md) echo doc ;;
    # 4. Hors carte → tout (VERSION racine, .claude-plugin/, .github/ autre que ci.yml, …).
    *) echo hors ;;
  esac
}
classe_plugin() {
  local f=$1 m name
  m=${f#plugin/}; m=${m%%/*}
  name=${f##*/}
  [ -f "plugin/$m/module.json" ] || { echo hors; return; }
  # Conductor appelé par un autre module : le nom du script est cité par un fichier suivi d'un AUTRE module.
  case "$f" in
    plugin/conductor/scripts/*)
      if conductor_appele_ailleurs "$name"; then echo partage; return; fi ;;
  esac
  # Bibliothèque de test partagée : sous un dossier tests/, ni suite test-*.sh ni fixture, nom cité par ≥ 2 suites.
  case "$f" in
    */tests/*)
      case "$f" in
        */fixtures/*) ;;
        *)
          case "$name" in
            test-*.sh) ;;
            *) if [ "$(cite_files "$name" | wc -l | tr -d ' ')" -ge 2 ]; then echo partage; return; fi ;;
          esac ;;
      esac ;;
  esac
  echo "module:$m"
}
# conductor_appele_ailleurs <nom> : cité par un fichier suivi sous plugin/<autre module>/ (autre ≠ conductor).
conductor_appele_ailleurs() {
  git grep -lF -e "$1" -- plugin 2> /dev/null | while IFS= read -r g; do
    a=${g#plugin/}; a=${a%%/*}
    [ "$a" = conductor ] && continue
    [ -f "plugin/$a/module.json" ] && echo "$g"
  done | grep -q .
}

: > "$T/classes"
while IFS= read -r f; do
  printf '%s\t%s\n' "$f" "$(classe "$f")" >> "$T/classes"
done < "$T/changed"

nondoc=$(awk -F'\t' '$2 != "doc"' "$T/classes" | wc -l | tr -d ' ')
if [ "$nondoc" -eq 0 ]; then emit docs-seules "documentation seule : aucune suite à jouer"; fi

# --- Tout ----------------------------------------------------------------------------------------------------
premier_tout=$(awk -F'\t' '$2 == "partage" || $2 == "hors" { print $2 "\t" $1; exit }' "$T/classes")
if [ -n "$premier_tout" ]; then
  k=${premier_tout%%"$TAB"*}; f=${premier_tout#*"$TAB"}
  if [ "$k" = partage ]; then tout_pour_tous "tout — fichier partagé $f"; else tout_pour_tous "tout — hors carte $f"; fi
  emit tout "$f déclenche toutes les suites"
fi

# --- Module + citée ------------------------------------------------------------------------------------------
: > "$T/cand"
# Module : (module, premier fichier trié) ; suites sous plugin/<m>/.
awk -F'\t' '$2 ~ /^module:/ { m = substr($2, 8); if (!(m in v)) { v[m] = 1; print m "\t" $1 } }' "$T/classes" > "$T/mods"
awk -F'\t' 'FILENAME == ARGV[1] { f[$1] = $2; next }
  { p = $0; sub(/^plugin\//, "", p); sub(/\/.*/, "", p); if (substr($0, 1, 7) == "plugin/" && (p in f)) printf "%s\t2\t%s\tmodule %s — %s\n", $0, f[p], p, f[p] }' "$T/mods" "$T/suites" >> "$T/cand"

# Citée : chemin complet, ou nom de fichier ; nom ambigu → la suite doit AUSSI citer le dossier parent (ou le module).
while IFS="$TAB" read -r f c; do
  name=${f##*/}; dir=${f%/*}
  { cite_files "$f"
    if ambigu "$name" "$f"; then
      { cite_files "$dir"
        case "$f" in plugin/*/*) mod=${f#plugin/}; cite_files "${mod%%/*}" ;; esac
      } | sort -u > "$T/d"
      cite_files "$name" | comm -12 - "$T/d"
    else
      cite_files "$name"
    fi
  } | sort -u | awk -v f="$f" '{ printf "%s\t3\t%s\tcitée — %s\n", $0, f, f }' >> "$T/cand"
done < <(awk -F'\t' '$2 != "doc"' "$T/classes")

# Citée par motif : un motif de chemin écrit dans une suite (contenant « * » et visant plugin/) EST une citation de chemin. La
# suite est retenue quand un fichier touché correspond au motif (case), ou à un fichier sous le dossier qu'il désigne.
cat > "$T/glob.awk" <<'AWK'
{
  n = split($0, w, /[ \t]+/)
  for (i = 1; i <= n; i++) {
    t = w[i]
    if (t !~ /\*/ || t !~ /[Pp][Ll][Uu][Gg][Ii][Nn]/) continue
    gsub(/["\047();|<>`,]/, "", t)
    if (t ~ /plugin\//) sub(/^.*plugin\//, "plugin/", t)
    else if (t ~ /\$\{?[A-Za-z_]*PLUGIN[A-Za-z_]*\}?\//) sub(/^.*\$\{?[A-Za-z_]*PLUGIN[A-Za-z_]*\}?\//, "plugin/", t)
    else continue
    if (t !~ /^plugin\// || t !~ /\*/ || (FILENAME "\t" t) in vu) continue
    vu[FILENAME "\t" t] = 1
    print FILENAME "\t" t
  }
}
AWK
: > "$T/globs"
[ "${#SUITES[@]}" -gt 0 ] && awk -f "$T/glob.awk" "${SUITES[@]}" > "$T/globs"
while IFS="$TAB" read -r suite pat; do
  [ -n "$pat" ] || continue
  while IFS="$TAB" read -r f c; do
    [ "$c" = doc ] && continue
    case "$pat" in
      */) m="$pat*" ;;
      *) m="$pat" ;;
    esac
    case "$f" in
      $m|$m/*) printf '%s\t3\t%s\tcitée — %s (motif %s)\n' "$suite" "$f" "$f" "$pat" >> "$T/cand"; break ;;
    esac
  done < "$T/classes"
done < "$T/globs"

sort -t "$TAB" -k1,1 -k2,2 -k3,3 -k4,4 "$T/cand" | awk -F'\t' '!s[$1]++ { printf "%s\t%s\n", $1, $4 }' > "$T/joued"
nj=$(wc -l < "$T/joued" | tr -d ' '); nt=$(wc -l < "$T/suites" | tr -d ' ')
if [ "$nj" -eq 0 ]; then
  premier=$(awk -F'\t' '$2 != "doc" { print $1; exit }' "$T/classes")
  emit vide "aucune suite du module ni citation pour $premier"   # jamais une liste vide en mode selection
fi
emit selection "$nj suite(s) jouée(s) sur $nt"
