#!/usr/bin/env bash
# manual/.tools/build-nav.sh [ROOT]
#
# Régénère, depuis manual/toc.yml SEUL (D-03), les trois blocs délimités du manuel :
#   <!-- vf-manual:lang -->      sélecteur de langue        <!-- /vf-manual:lang -->
#   <!-- vf-manual:nav -->       bandeau Précédent/Sommaire/Suivant  <!-- /vf-manual:nav -->
#   <!-- vf-manual:sommaire -->  liste de liens par thème   <!-- /vf-manual:sommaire -->
#
# ROOT par défaut = le dossier parent de ce script (manual/). Idempotent : deux exécutions
# consécutives laissent l'arbre strictement identique (propriété exploitée par le contrôle
# C4 de check-manual.sh). Ce script ne s'exécute qu'à la main, en local (D-13) — jamais
# référencé dans .github/workflows/ci.yml, jamais posé sous scripts/.
#
# H-1 levée (wave 26-10, cf. toc.yml) : FR et EN peuvent avoir des dossiers ET des slugs de
# fichier différents. L'appariement d'une page/thème entre les deux langues n'est donc PLUS
# dérivé par substitution de segment dans un chemin — il est lu explicitement depuis
# `path_fr`/`path_en` (pages) et `dir_fr`/`dir_en` (thèmes) de toc.yml, entrée par entrée.
#
# Portabilité : bash 3.2 (macOS) et bash 5 (Linux) — aucun tableau associatif, aucun
# mapfile, aucune substitution ${var^^}.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
DEFAULT_ROOT="$(dirname "$SCRIPT_DIR")"
ROOT_ARG="${1:-$DEFAULT_ROOT}"
if [ ! -d "$ROOT_ARG" ]; then
  echo "✗ build-nav: ROOT introuvable: $ROOT_ARG" >&2
  exit 1
fi
ROOT="$(cd "$ROOT_ARG" && pwd)"
TOC="$ROOT/toc.yml"

if [ ! -f "$TOC" ]; then
  echo "✗ build-nav: $TOC introuvable" >&2
  exit 1
fi

# --- parsing du sous-ensemble YAML (H-2) -----------------------------------------------

# awk: trim() — retire les espaces/tabs en bord de valeur puis dé-quote si la valeur entière
# est entourée d'une paire de guillemets simples ou doubles (H-2 : les valeurs YAML peuvent
# être nues ou quotées ; un espace final ou une quote non retirée casse silencieusement la
# résolution de fichier en aval — cf 26-CONTEXT.md finding trim/dequote).
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

# extrait les entrées `pages:` -> "id<TAB>path_fr<TAB>path_en<TAB>fr<TAB>en", ordre préservé
parse_pages() {
  awk "$AWK_TRIM_FN"'
    /^pages:[[:space:]]*$/ { inpages=1; have=0; next }
    /^[a-zA-Z_]/ { inpages=0 }
    inpages && /^[[:space:]]*-[[:space:]]*id:/ {
      if (have) print id "\t" pf "\t" pe "\t" fr "\t" en
      v=$0; sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/, "", v); id=trim(v); pf=""; pe=""; fr=""; en=""; have=1
      next
    }
    inpages && /^[[:space:]]*path_fr:/ { v=$0; sub(/^[[:space:]]*path_fr:[[:space:]]*/, "", v); pf=trim(v); next }
    inpages && /^[[:space:]]*path_en:/ { v=$0; sub(/^[[:space:]]*path_en:[[:space:]]*/, "", v); pe=trim(v); next }
    inpages && /^[[:space:]]*fr:/ { v=$0; sub(/^[[:space:]]*fr:[[:space:]]*/, "", v); fr=trim(v); next }
    inpages && /^[[:space:]]*en:/ { v=$0; sub(/^[[:space:]]*en:[[:space:]]*/, "", v); en=trim(v); next }
    END { if (have) print id "\t" pf "\t" pe "\t" fr "\t" en }
  ' "$TOC"
}

# extrait les entrées `themes:` -> "id<TAB>dir_fr<TAB>dir_en<TAB>fr<TAB>en", ordre préservé
parse_themes() {
  awk "$AWK_TRIM_FN"'
    /^themes:[[:space:]]*$/ { inthemes=1; have=0; next }
    /^pages:[[:space:]]*$/ { if (have) print id "\t" df "\t" de "\t" fr "\t" en; inthemes=0; have=0 }
    inthemes && /^[[:space:]]*-[[:space:]]*id:/ {
      if (have) print id "\t" df "\t" de "\t" fr "\t" en
      v=$0; sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/, "", v); id=trim(v); df=""; de=""; fr=""; en=""; have=1
      next
    }
    inthemes && /^[[:space:]]*dir_fr:/ { v=$0; sub(/^[[:space:]]*dir_fr:[[:space:]]*/, "", v); df=trim(v); next }
    inthemes && /^[[:space:]]*dir_en:/ { v=$0; sub(/^[[:space:]]*dir_en:[[:space:]]*/, "", v); de=trim(v); next }
    inthemes && /^[[:space:]]*fr:/ { v=$0; sub(/^[[:space:]]*fr:[[:space:]]*/, "", v); fr=trim(v); next }
    inthemes && /^[[:space:]]*en:/ { v=$0; sub(/^[[:space:]]*en:[[:space:]]*/, "", v); en=trim(v); next }
    END { if (have) print id "\t" df "\t" de "\t" fr "\t" en }
  ' "$TOC"
}

PAGE_ID=(); PAGE_FR_PATH=(); PAGE_EN_PATH=(); PAGE_FR=(); PAGE_EN=()
while IFS="$(printf '\t')" read -r id pf pe f e; do
  [ -z "$id" ] && continue
  PAGE_ID+=("$id"); PAGE_FR_PATH+=("$pf"); PAGE_EN_PATH+=("$pe"); PAGE_FR+=("$f"); PAGE_EN+=("$e")
done < <(parse_pages)
N=${#PAGE_ID[@]}

THEME_ID=(); THEME_DIR_FR=(); THEME_DIR_EN=(); THEME_FR=(); THEME_EN=()
while IFS="$(printf '\t')" read -r id df de f e; do
  [ -z "$id" ] && continue
  THEME_ID+=("$id"); THEME_DIR_FR+=("$df"); THEME_DIR_EN+=("$de"); THEME_FR+=("$f"); THEME_EN+=("$e")
done < <(parse_themes)
T=${#THEME_ID[@]}

# --- validation avant toute écriture (aucune écriture partielle) -----------------------

MISSING=0
i=0
while [ "$i" -lt "$N" ]; do
  if [ ! -f "$ROOT/fr/${PAGE_FR_PATH[$i]}" ]; then
    echo "✗ build-nav: manquant $ROOT/fr/${PAGE_FR_PATH[$i]} (référencé par toc.yml, id=${PAGE_ID[$i]})" >&2
    MISSING=1
  fi
  if [ ! -f "$ROOT/en/${PAGE_EN_PATH[$i]}" ]; then
    echo "✗ build-nav: manquant $ROOT/en/${PAGE_EN_PATH[$i]} (référencé par toc.yml, id=${PAGE_ID[$i]})" >&2
    MISSING=1
  fi
  i=$((i + 1))
done
if [ "$MISSING" -eq 1 ]; then
  exit 1
fi

# guard: refuse toute écriture hors de ROOT
write_guard() {
  case "$1" in
    "$ROOT"/*) return 0 ;;
    *) echo "✗ build-nav: refus d'écrire hors de ROOT: $1" >&2; exit 1 ;;
  esac
}

# retire tout bloc <!-- vf-manual:X --> ... <!-- /vf-manual:X --> (marqueurs generiques)
strip_markers() {
  awk '
    /<!-- vf-manual:[a-z]+ -->/ { skip=1; next }
    /<!-- \/vf-manual:[a-z]+ -->/ { skip=0; next }
    skip { next }
    { print }
  '
}

# retire les lignes vides en fin de flux
rtrim_blank() {
  awk 'BEGIN{n=0} { line[++n]=$0 } END { while (n>0 && line[n]=="") n--; for (i=1;i<=n;i++) print line[i] }'
}

# retire les lignes vides en debut de flux (contrepartie de rtrim_blank — sans elle, la
# ligne vide inseree explicitement par write_page/write_readme entre un marqueur et le
# corps de page se re-agrege au corps a chaque relance, cassant l'idempotence : cf C4)
ltrim_blank() {
  awk 'BEGIN{started=0} { if (!started && $0=="") next; started=1; print }'
}

lang_block() {
  # $1 = lang courant (fr|en) ; $2 = chemin relatif vers le mirroir dans l'autre langue
  if [ "$1" = "fr" ]; then
    printf '<!-- vf-manual:lang -->\n**Français** · [English](%s)\n<!-- /vf-manual:lang -->\n' "$2"
  else
    printf '<!-- vf-manual:lang -->\n[Français](%s) · **English**\n<!-- /vf-manual:lang -->\n' "$2"
  fi
}

nav_block() {
  # $1 = lang (fr|en) ; $2 = lien prev (ou vide) ; $3 = lien next (ou vide)
  local prev_txt next_txt sommaire_txt segs
  if [ "$1" = "fr" ]; then prev_txt="← Précédent"; sommaire_txt="↑ Sommaire"; next_txt="Suivant →"
  else prev_txt="← Previous"; sommaire_txt="↑ Contents"; next_txt="Next →"; fi
  segs=""
  if [ -n "$2" ]; then segs="[${prev_txt}](${2})"; fi
  if [ -n "$segs" ]; then segs="${segs} · [${sommaire_txt}](../README.md)"; else segs="[${sommaire_txt}](../README.md)"; fi
  if [ -n "$3" ]; then segs="${segs} · [${next_txt}](${3})"; fi
  printf '<!-- vf-manual:nav -->\n%s\n<!-- /vf-manual:nav -->\n' "$segs"
}

write_page() {
  local file="$1" lang="$2" lang_link="$3" prev_link="$4" next_link="$5"
  write_guard "$file"
  local body h1 rest tmp
  body="$(strip_markers < "$file")"
  h1="$(printf '%s\n' "$body" | head -n1)"
  rest="$(printf '%s\n' "$body" | tail -n +2 | ltrim_blank | rtrim_blank)"
  tmp="$(mktemp)"
  {
    printf '%s\n\n' "$h1"
    lang_block "$lang" "$lang_link"
    printf '\n'
    printf '%s\n' "$rest"
    printf '\n'
    nav_block "$lang" "$prev_link" "$next_link"
  } > "$tmp"
  mv "$tmp" "$file"
}

write_readme() {
  local file="$1" lang="$2" lang_link="$3"
  [ -f "$file" ] || return 0
  write_guard "$file"
  local body h1 rest tmp sommaire
  body="$(strip_markers < "$file")"
  h1="$(printf '%s\n' "$body" | head -n1)"
  rest="$(printf '%s\n' "$body" | tail -n +2 | ltrim_blank | rtrim_blank)"
  sommaire="$(build_sommaire "$lang")"
  tmp="$(mktemp)"
  {
    printf '%s\n\n' "$h1"
    lang_block "$lang" "$lang_link"
    if [ -n "$rest" ]; then printf '\n%s\n' "$rest"; fi
    printf '\n'
    printf '<!-- vf-manual:sommaire -->\n%s\n<!-- /vf-manual:sommaire -->\n' "$sommaire"
  } > "$tmp"
  mv "$tmp" "$file"
}

build_sommaire() {
  # $1 = lang (fr|en). Le dossier de thème et le chemin de page utilisés dans les liens
  # doivent être ceux DE CETTE LANGUE (dir_fr/path_fr côté fr, dir_en/path_en côté en) —
  # H-1 levée, plus de segment partagé entre les deux arbres.
  local lang="$1" out="" ti tdir_fr tdir_en tdir pfr ppath
  local t=0
  while [ "$t" -lt "$T" ]; do
    tdir_fr="${THEME_DIR_FR[$t]}"
    tdir_en="${THEME_DIR_EN[$t]}"
    if [ "$lang" = "fr" ]; then ti="${THEME_FR[$t]}"; tdir="$tdir_fr"; else ti="${THEME_EN[$t]}"; tdir="$tdir_en"; fi
    out="${out}### ${ti}\n"
    local i=0
    while [ "$i" -lt "$N" ]; do
      if [ "$lang" = "fr" ]; then ppath="${PAGE_FR_PATH[$i]}"; else ppath="${PAGE_EN_PATH[$i]}"; fi
      pdir="${ppath%%/*}"
      if [ "$pdir" = "$tdir" ]; then
        if [ "$lang" = "fr" ]; then pfr="${PAGE_FR[$i]}"; else pfr="${PAGE_EN[$i]}"; fi
        out="${out}- [${pfr}](./${ppath})\n"
      fi
      i=$((i + 1))
    done
    t=$((t + 1))
  done
  printf '%b' "$out" | rtrim_blank
}

# --- application aux README de langue ---------------------------------------------------

write_readme "$ROOT/fr/README.md" fr "../en/README.md"
write_readme "$ROOT/en/README.md" en "../fr/README.md"

# --- application aux pages ---------------------------------------------------------------

i=0
while [ "$i" -lt "$N" ]; do
  fr_rel="${PAGE_FR_PATH[$i]}"
  en_rel="${PAGE_EN_PATH[$i]}"

  fr_prev=""; fr_next=""; en_prev=""; en_next=""
  if [ "$i" -gt 0 ]; then
    pfr="${PAGE_FR_PATH[$((i - 1))]}"; pen="${PAGE_EN_PATH[$((i - 1))]}"
    fr_prev="../${pfr%%/*}/${pfr##*/}"
    en_prev="../${pen%%/*}/${pen##*/}"
  fi
  if [ "$i" -lt "$((N - 1))" ]; then
    nfr="${PAGE_FR_PATH[$((i + 1))]}"; nen="${PAGE_EN_PATH[$((i + 1))]}"
    fr_next="../${nfr%%/*}/${nfr##*/}"
    en_next="../${nen%%/*}/${nen##*/}"
  fi

  write_page "$ROOT/fr/$fr_rel" fr "../../en/${en_rel}" "$fr_prev" "$fr_next"
  write_page "$ROOT/en/$en_rel" en "../../fr/${fr_rel}" "$en_prev" "$en_next"
  i=$((i + 1))
done

echo "✓ build-nav: ${N} page(s) × 2 langues, ${T} thème(s) — arbre régénéré sous $ROOT"
exit 0
