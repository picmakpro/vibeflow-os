#!/usr/bin/env bash
# manual/.tools/check-manual.sh [ROOT]
#
# Gate de cohérence du manuel utilisateur (D-13). Sept contrôles, tous exécutés (pas d'arrêt
# au premier), sortie ✓/✗ par contrôle, exit 1 dès qu'un contrôle a échoué.
#
#   C0  verdict non vide            — refuse de rendre un verdict sur un manuel vide
#   C1  isomorphisme fr/en          — pour chaque id de toc.yml, path_fr ET path_en existent
#   C2  toc.yml <-> disque          — bijection stricte, PAR LANGUE, entre toc.yml et les .md
#   C3  liens relatifs              — aucun lien markdown relatif mort
#   C4  bandeau <-> toc             — rejoue build-nav.sh sur une copie, diffe
#   C5  zéro version en dur (D-11)  — aucun motif vX.Y.Z hors bloc de code
#   C6  format de page (D-04)       — <=300 lignes, <=3 H2 ; 100-200 lignes recommandé (warning)
#
# H-1 levée (wave 26-10, cf. toc.yml) : FR et EN peuvent avoir des chemins différents
# (dossiers ET fichiers). C1 et C2 ne comparent donc plus des CHEMINS bruts entre les deux
# arbres — ils comparent des IDENTIFIANTS LOGIQUES DE PAGE, appariés à un `path_fr`/`path_en`
# explicite lu dans toc.yml. Un id présent des deux côtés de toc.yml mais dont un seul des
# deux fichiers existe sur disque est une rupture d'isomorphisme (C1). Un fichier sur disque
# sans entrée toc.yml correspondante DANS SA LANGUE, ou une entrée toc.yml dont le fichier de
# sa langue est absent, est une rupture de bijection (C2).
#
# Ce gate ne s'exécute qu'à la main, en local (D-13) — jamais référencé dans
# .github/workflows/ci.yml, jamais posé sous scripts/.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
DEFAULT_ROOT="$(dirname "$SCRIPT_DIR")"
ROOT_ARG="${1:-$DEFAULT_ROOT}"
if [ ! -d "$ROOT_ARG" ]; then
  echo "✗ check-manual: ROOT introuvable: $ROOT_ARG" >&2
  exit 1
fi
ROOT="$(cd "$ROOT_ARG" && pwd)"
TOC="$ROOT/toc.yml"

FAIL=0
CLEANUP_DIRS=""
cleanup() {
  local d
  for d in $CLEANUP_DIRS; do rm -rf "$d"; done
}
trap cleanup EXIT

fail() { echo "✗ $1"; FAIL=1; }
ok()   { echo "✓ $1"; }

# --- collecte de l'état disque -----------------------------------------------------------

if [ -d "$ROOT/fr" ]; then
  FR_PAGES="$(find "$ROOT/fr" -mindepth 2 -maxdepth 2 -name '*.md' 2>/dev/null | sed "s#^$ROOT/fr/##" | sort)"
else
  FR_PAGES=""
fi
FR_PAGE_COUNT=$(printf '%s\n' "$FR_PAGES" | grep -c . || true)
[ -z "$FR_PAGES" ] && FR_PAGE_COUNT=0

if [ -d "$ROOT/en" ]; then
  EN_PAGES="$(find "$ROOT/en" -mindepth 2 -maxdepth 2 -name '*.md' 2>/dev/null | sed "s#^$ROOT/en/##" | sort)"
else
  EN_PAGES=""
fi
EN_PAGE_COUNT=$(printf '%s\n' "$EN_PAGES" | grep -c . || true)
[ -z "$EN_PAGES" ] && EN_PAGE_COUNT=0

# id<TAB>path_fr<TAB>path_en pour chaque entrée pages: de toc.yml (H-1 levée — appariement
# explicite, plus de segment de chemin partagé entre fr et en). Trim/dé-quote comme
# build-nav.sh (H-2) pour ne jamais désaccorder les deux scripts sur la même entrée.
AWK_TRIM_FN='
  function trim(s,   c) {
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    if (length(s) >= 2) {
      c = substr(s, 1, 1)
      if ((c == "\"" || c == "\047") && substr(s, length(s), 1) == c) {
        s = substr(s, 2, length(s) - 2)
      }
    }
    return s
  }
'
TOC_PAIRS_FILE=$(mktemp)
CLEANUP_DIRS="$CLEANUP_DIRS $TOC_PAIRS_FILE"
if [ -f "$TOC" ]; then
  awk "$AWK_TRIM_FN"'
    /^pages:[[:space:]]*$/ { inpages=1; have=0; next }
    /^[a-zA-Z_]/ { inpages=0 }
    inpages && /^[[:space:]]*-[[:space:]]*id:/ {
      if (have) print id "\t" pf "\t" pe
      v=$0; sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/, "", v); id=trim(v); pf=""; pe=""; have=1
      next
    }
    inpages && /^[[:space:]]*path_fr:/ { v=$0; sub(/^[[:space:]]*path_fr:[[:space:]]*/, "", v); pf=trim(v); next }
    inpages && /^[[:space:]]*path_en:/ { v=$0; sub(/^[[:space:]]*path_en:[[:space:]]*/, "", v); pe=trim(v); next }
    END { if (have) print id "\t" pf "\t" pe }
  ' "$TOC" > "$TOC_PAIRS_FILE"
else
  : > "$TOC_PAIRS_FILE"
fi
TOC_PAGE_COUNT=$(grep -c . "$TOC_PAIRS_FILE" || true)
[ -z "$TOC_PAGE_COUNT" ] && TOC_PAGE_COUNT=0

# --- C0 : verdict non vide (D-13) ---------------------------------------------------------

if [ "$FR_PAGE_COUNT" -eq 0 ] || [ "$TOC_PAGE_COUNT" -eq 0 ]; then
  fail "C0 verdict non vide — 0 page découverte (disque: $FR_PAGE_COUNT, toc.yml: $TOC_PAGE_COUNT). Refus de rendre un verdict sur un manuel vide."
else
  ok "C0 verdict non vide — $FR_PAGE_COUNT page(s) sur disque, $TOC_PAGE_COUNT dans toc.yml."
fi

# --- C1 : isomorphisme fr/en, PAR APPARIEMENT LOGIQUE (D-01, H-1 levée) --------------------
#
# Pour chaque id de toc.yml, path_fr ET path_en doivent tous les deux exister sur disque.
# Un id dont un seul des deux côtés existe est une rupture d'isomorphisme — même sens que
# l'ancien diff d'arbres, mais évalué entrée par entrée via l'appariement explicite plutôt
# que par ressemblance de chemin.

C1_BAD=0
while IFS="$(printf '\t')" read -r id pf pe; do
  [ -z "$id" ] && continue
  fr_ok=1; en_ok=1
  [ -f "$ROOT/fr/$pf" ] || fr_ok=0
  [ -f "$ROOT/en/$pe" ] || en_ok=0
  if [ "$fr_ok" -eq 0 ] && [ "$en_ok" -eq 1 ]; then
    echo "    id '$id' : manual/en/$pe existe mais manual/fr/$pf est absent"
    C1_BAD=1
  elif [ "$fr_ok" -eq 1 ] && [ "$en_ok" -eq 0 ]; then
    echo "    id '$id' : manual/fr/$pf existe mais manual/en/$pe est absent"
    C1_BAD=1
  elif [ "$fr_ok" -eq 0 ] && [ "$en_ok" -eq 0 ]; then
    echo "    id '$id' : ni manual/fr/$pf ni manual/en/$pe n'existent"
    C1_BAD=1
  fi
done < "$TOC_PAIRS_FILE"

if [ "$C1_BAD" -eq 1 ]; then
  fail "C1 isomorphisme fr/en — au moins un id sans sa paire complète (voir détail ci-dessus)."
else
  ok "C1 isomorphisme fr/en — chaque id de toc.yml a sa paire fr+en complète sur disque."
fi

# --- C2 : toc.yml <-> disque, bijection PAR LANGUE (D-03, H-1 levée) -----------------------
#
# Chaque langue est vérifiée indépendamment : tout .md de niveau page sur disque doit
# correspondre à exactement une entrée toc.yml (path_fr côté fr, path_en côté en), et
# réciproquement.

TOC_FR_PATHS=$(mktemp); CLEANUP_DIRS="$CLEANUP_DIRS $TOC_FR_PATHS"
TOC_EN_PATHS=$(mktemp); CLEANUP_DIRS="$CLEANUP_DIRS $TOC_EN_PATHS"
cut -f2 "$TOC_PAIRS_FILE" | sort > "$TOC_FR_PATHS"
cut -f3 "$TOC_PAIRS_FILE" | sort > "$TOC_EN_PATHS"

C2_BAD=0

while IFS="$(printf '\t')" read -r id pf pe; do
  [ -z "$id" ] && continue
  if [ ! -f "$ROOT/fr/$pf" ]; then
    echo "    toc.yml (id '$id') référence path_fr '$pf' mais le fichier est absent"
    C2_BAD=1
  fi
  if [ ! -f "$ROOT/en/$pe" ]; then
    echo "    toc.yml (id '$id') référence path_en '$pe' mais le fichier est absent"
    C2_BAD=1
  fi
done < "$TOC_PAIRS_FILE"

if [ -n "$FR_PAGES" ]; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if ! grep -qxF "$p" "$TOC_FR_PATHS"; then
      echo "    manual/fr/$p existe sur disque mais n'est référencé par aucune entrée 'path_fr:' de toc.yml"
      C2_BAD=1
    fi
  done <<EOF_FR_PAGES
$FR_PAGES
EOF_FR_PAGES
fi

if [ -n "$EN_PAGES" ]; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if ! grep -qxF "$p" "$TOC_EN_PATHS"; then
      echo "    manual/en/$p existe sur disque mais n'est référencé par aucune entrée 'path_en:' de toc.yml"
      C2_BAD=1
    fi
  done <<EOF_EN_PAGES
$EN_PAGES
EOF_EN_PAGES
fi

if [ "$C2_BAD" -eq 1 ]; then
  fail "C2 toc.yml <-> disque — désaccord (voir détail ci-dessus)."
else
  ok "C2 toc.yml <-> disque — bijection stricte vérifiée pour les deux langues."
fi

# --- C3 : liens relatifs (D-01) -------------------------------------------------------------

C3_BAD=0
if [ -d "$ROOT/fr" ] || [ -d "$ROOT/en" ]; then
  ALL_MD=$(find "$ROOT" -name '*.md' 2>/dev/null)
  for f in $ALL_MD; do
    dir=$(dirname "$f")
    # filtre les blocs de code (``` ancré en colonne 0 OU indenté sous une puce) avant
    # d'extraire les liens — sinon un exemple de lien mort dans un bloc de code devient un
    # faux positif. L'extraction s'arrête au premier espace/parenthèse : un lien titré
    # `[t](x.md "Titre")` ne capture que `x.md`, jamais le titre entre guillemets.
    content=$(awk '/^[[:space:]]*```/ { incode = !incode; next } incode { next } { print }' "$f")
    targets=$(printf '%s\n' "$content" | grep -oE '\]\([^()[:space:]]+' | sed -E 's/^\]\(//')
    for t in $targets; do
      case "$t" in
        http://*|https://*|mailto:*|\#*) continue ;;
      esac
      t_nofrag="${t%%#*}"
      [ -z "$t_nofrag" ] && continue
      resolved="$dir/$t_nofrag"
      if command -v realpath >/dev/null 2>&1; then
        resolved="$(cd "$dir" 2>/dev/null && realpath -q "$t_nofrag" 2>/dev/null || echo "$dir/$t_nofrag")"
      fi
      if [ ! -f "$resolved" ]; then
        # repli sans realpath : normalisation manuelle non nécessaire, on tente cd direct
        if ! (cd "$dir" 2>/dev/null && [ -f "$t_nofrag" ]); then
          echo "    lien mort dans ${f#$ROOT/}: $t"
          C3_BAD=1
        fi
      fi
    done
  done
fi

if [ "$C3_BAD" -eq 1 ]; then
  fail "C3 liens relatifs — au moins un lien mort (voir détail ci-dessus)."
else
  ok "C3 liens relatifs — aucun lien mort détecté."
fi

# --- C4 : bandeau <-> toc (D-03) -------------------------------------------------------------

if [ "$FR_PAGE_COUNT" -gt 0 ] || [ -f "$ROOT/fr/README.md" ] || [ -f "$ROOT/en/README.md" ]; then
  C4_TMP=$(mktemp -d)
  CLEANUP_DIRS="$CLEANUP_DIRS $C4_TMP"
  cp -R "$ROOT"/. "$C4_TMP"/ 2>/dev/null
  if "$SCRIPT_DIR/build-nav.sh" "$C4_TMP" >/dev/null 2>&1; then
    C4_DIFF=$(diff -r "$ROOT" "$C4_TMP" 2>&1 || true)
    if [ -n "$C4_DIFF" ]; then
      fail "C4 bandeau <-> toc — l'arbre diffère de ce que build-nav.sh produirait :"
      printf '%s\n' "$C4_DIFF" | sed 's/^/    /' | head -20
    else
      ok "C4 bandeau <-> toc — bandeaux à jour."
    fi
  else
    fail "C4 bandeau <-> toc — build-nav.sh a échoué sur une copie de l'arbre (toc.yml référence probablement un fichier absent)."
  fi
else
  ok "C4 bandeau <-> toc — rien à régénérer (manuel vide)."
fi

# --- C5 : zéro version en dur (D-11) ----------------------------------------------------------

C5_BAD=0
if [ -d "$ROOT/fr" ] || [ -d "$ROOT/en" ]; then
  ALL_MD=$(find "$ROOT" -name '*.md' 2>/dev/null)
  for f in $ALL_MD; do
    hits=$(awk '
      /^[[:space:]]*```/ { incode = !incode; next }
      incode { next }
      /manual-allow-version/ { next }
      /v?[0-9]+\.[0-9]+\.[0-9]+/ { print NR": "$0 }
    ' "$f")
    if [ -n "$hits" ]; then
      echo "    numéro de version en dur dans ${f#$ROOT/}:"
      printf '%s\n' "$hits" | sed 's/^/      /'
      C5_BAD=1
    fi
  done
fi

if [ "$C5_BAD" -eq 1 ]; then
  fail "C5 zéro version en dur — au moins une occurrence (voir détail ci-dessus)."
else
  ok "C5 zéro version en dur — aucune occurrence hors bloc de code."
fi

# --- C6 : format de page (D-04) ---------------------------------------------------------------

C6_BAD=0
if [ "$FR_PAGE_COUNT" -gt 0 ]; then
  PAGE_FILES=$(find "$ROOT/fr" "$ROOT/en" -mindepth 2 -maxdepth 2 -name '*.md' 2>/dev/null)
  for f in $PAGE_FILES; do
    lines=$(wc -l < "$f" | tr -d ' ')
    h2=$(grep -c '^## ' "$f" || true)
    [ -z "$h2" ] && h2=0
    if [ "$lines" -gt 300 ]; then
      echo "    ${f#$ROOT/} : $lines lignes (> 300, bascule ferme D-04)"
      C6_BAD=1
    fi
    if [ "$h2" -gt 3 ]; then
      echo "    ${f#$ROOT/} : $h2 titres H2 (> 3, bascule ferme D-04)"
      C6_BAD=1
    fi
    if [ "$lines" -lt 100 ] || [ "$lines" -gt 200 ]; then
      echo "    (avertissement, non bloquant) ${f#$ROOT/} : $lines lignes hors de la fourchette 100-200"
    fi
  done
fi

if [ "$C6_BAD" -eq 1 ]; then
  fail "C6 format de page — au moins une page dépasse la bascule ferme (voir détail ci-dessus)."
else
  ok "C6 format de page — aucune page au-delà de la bascule ferme (300 lignes / 3 H2)."
fi

# --- verdict -------------------------------------------------------------------------------

echo
if [ "$FAIL" -eq 1 ]; then
  echo "✗ check-manual: au moins un contrôle a échoué."
  exit 1
else
  echo "✓ check-manual: tous les contrôles passent."
  exit 0
fi
