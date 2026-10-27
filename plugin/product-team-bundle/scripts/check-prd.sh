#!/usr/bin/env bash
# check-prd.sh — gate déterministe des deux éliminatoires du PRD et du BRIEF (Phase 59, PRDT-03,
# PRDT-05, PRDT-09 ; P59-D-05, P59-D-06, P59-PL-04). Appelé par le juge `prd-gate` : sans lui,
# l'éliminatoire « exigence sans critère d'acceptation » serait un vert auto-déclaré.
#
# Rôle : CONSTATER, jamais corriger. LECTURE SEULE, sans exception : aucun fichier créé, modifié ni
# effacé, aucune écriture hors stdout et stderr. Les entrées sont des fichiers d'un lab, écrits par
# un worker ou un humain : NON FIABLES. Leur contenu n'est jamais réimprimé (la sortie entre dans
# le contexte du juge) : seuls sont imprimés l'identifiant d'exigence capturé par le motif
# d'ouvreur et des noms de rubrique fixes. Leur contenu n'est jamais évalué (awk seul).
#
# Usage :
#   check-prd.sh --requirements <f> [--brief <f>]
#   check-prd.sh --brief <f>
#   check-prd.sh -h | --help
# Au moins une des deux entrées, aucun chemin par défaut (`--option=<f>` admis). `--requirements`
# désigne le fichier d'exigences du lab : le fichier passé par --requirements ; `--brief`
# désigne le BRIEF produit (.planning/BRIEF.md). Forme exec : l'appelant écrit
# `bash <chemin résolu> --requirements <f> --brief <f>` en arguments séparés, sans `|| true` ni
# tube qui masquerait le code ; le script porte seul la sémantique de son code ; aucun hook.
#
# Éliminatoire 1 : une exigence `- [ ] **ID**: ...` sans critère d'acceptation utilisable. Le
# critère est une ligne (celle de l'exigence ou une continuation indentée) `Acceptation :` suivie
# d'une valeur qui ne commence pas par `[` ou `<`, sans marqueur de remplissage en mot entier (TBD,
# TODO, TBA, FIXME, n/a, « à définir », « à préciser », « à compléter », « à venir », « à déterminer »,
# « à remplir », « à renseigner », « à confirmer », « à décider » ; casse et accents indifférents, y compris
# les marques combinantes), sans trois points ni points de suspension, d'au moins 10 CARACTÈRES non
# blancs (UTF-8 compté en caractères, en awk pur sous LC_ALL=C : aucune locale UTF-8 requise). La
# qualité « testable » du critère reste au juge. Les blocs de code et les commentaires HTML sont
# ignorés (un commentaire multi-ligne au milieu d'une exigence ne la ferme pas). Une puce, même
# indentée, ouvre un nouvel élément : elle ne porte pas le critère de l'exigence qui précède.
# Bloc de code non fermé en fin de fichier : les exigences suivantes sont illisibles pour le gate,
# donc INDÉTERMINÉ (code 3). Ligne à case `[ ]`/`[x]` qui n'a pas la forme d'exigence (ID pointé,
# minuscules, puce `*`, numérotée) : AVERTISSEMENT par numéro de ligne (stdout et stderr), jamais
# réimprimée ; l'effet sur le code reste nul, le BILAN la compte (`non_reconnues`).
# Éliminatoire 2 : une rubrique du BRIEF manque ou n'a aucune ligne de corps (hors commentaire
# HTML, hors ligne commençant par `[`, hors TBD/TODO) : probleme, utilisateurs, valeur,
# contraintes, hors_perimetre (titres Markdown reconnus par préfixe ASCII, casse indifférente).
# Avertissement (jamais d'effet sur le code) : priorité absente ou hors {must, should, could}.
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0 = conforme : aucun éliminatoire et au moins une exigence lue si --requirements est fourni.
#   1 = éliminatoire : exigence sans critère utilisable, ou rubrique du BRIEF absente ou vide.
#   3 = INDÉTERMINÉ : cible absente, zéro exigence détectée, ou bloc de code non fermé en fin de
#       fichier. Jamais un vert à vide.
#   5 = entrée illisible, BRUYANTE : lien symbolique, non régulier (FIFO, dossier), illisible,
#       taille non numérique, au-delà de 1048576 octets, analyse en échec. Refus AVANT lecture.
#   64 = erreur d'usage (aucune entrée, option inconnue ou sans valeur).
#   Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness.
# Entre plusieurs constats, l'ordre 5 > 1 > 3 > 0 décide ; une entrée non fournie ne compte pas.
#
# Sortie : lignes préfixées `[check-prd]` puis une étiquette ASCII :
#   ELIMINATOIRE exigence <ID> : aucun critere d'acceptation utilisable
#   ELIMINATOIRE rubrique BRIEF <nom> : absente | vide
#   AVERTISSEMENT exigence <ID> : priorite absente | priorite hors {must, should, could}
#   AVERTISSEMENT ligne <n> : case a cocher non reconnue comme exigence (aussi sur stderr)
#   INDETERMINE <entree> : <raison>        ILLISIBLE <entree> : <raison> (aussi sur stderr)
#   BILAN exigences=<n> sans_critere=<n> avertissements=<n> rubriques_manquantes=<n> non_reconnues=<n> code=<rc>
# Au plus 50 lignes par catégorie ; les compteurs du BILAN restent exacts.
set -uo pipefail
export LC_ALL=C

PRD_MAX_OCTETS=1048576
REQ=""; BRIEF=""; HAS_REQ=0; HAS_BRIEF=0
NL=$'\n'
BOM=$(printf '\357\273\277')
ELL=$(printf '\342\200\246')

usage_err() { printf '[check-prd] %s\n' "$1" >&2; exit 64; }
say() { printf '[check-prd] %s\n' "$*"; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --requirements)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "--requirements nécessite une valeur"
      REQ=$2; HAS_REQ=1; shift 2 ;;
    --requirements=*)
      REQ=${1#--requirements=}; [ -n "$REQ" ] || usage_err "--requirements nécessite une valeur"
      HAS_REQ=1; shift ;;
    --brief)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "--brief nécessite une valeur"
      BRIEF=$2; HAS_BRIEF=1; shift 2 ;;
    --brief=*)
      BRIEF=${1#--brief=}; [ -n "$BRIEF" ] || usage_err "--brief nécessite une valeur"
      HAS_BRIEF=1; shift ;;
    -h|--help) awk '/^set -uo/{exit} /^# /{sub(/^# /,""); print}' "$0"; exit 0 ;;
    *) usage_err "argument inconnu (usage : --requirements <f> [--brief <f>] | --brief <f>)" ;;
  esac
done
[ "$HAS_REQ" -eq 1 ] || [ "$HAS_BRIEF" -eq 1 ] \
  || usage_err "aucune entrée (usage : --requirements <f> [--brief <f>] | --brief <f>)"

# --- Fonctions awk communes aux deux analyses.
read -r -d '' AWK_LIB <<'AWKEOF'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function hasword(t, w,   p, b, a, off) {
  off = 0
  while ((p = index(substr(t, off + 1), w)) > 0) {
    p += off
    b = (p == 1) ? " " : substr(t, p - 1, 1)
    a = substr(t, p + length(w), 1)
    if (b !~ /[a-z0-9_]/ && a !~ /[a-z0-9_]/) return 1
    off = p
  }
  return 0
}
# Minuscules ASCII, accents français repliés (UTF-8 lu en octets), marques combinantes retirées.
function fold(s) {
  s = tolower(s)
  gsub(/\314[\200-\277]|\315[\200-\257]/, "", s)
  gsub(/à|À|â|Â/, "a", s); gsub(/é|É|è|È|ê|Ê|ë|Ë/, "e", s)
  gsub(/î|Î|ï|Ï/, "i", s); gsub(/ô|Ô/, "o", s); gsub(/ù|Ù|û|Û/, "u", s); gsub(/ç|Ç/, "c", s)
  return s
}
# Caractères non blancs : octets de continuation UTF-8 (0x80-0xBF) et marques combinantes retirés.
function nchars(s) {
  gsub(/[ \t]/, "", s)
  gsub(/\314[\200-\277]/, "", s); gsub(/\315[\200-\257]/, "", s)
  gsub(/[\200-\277]/, "", s)
  return length(s)
}
function isfiller(v,   t, i, n, F) {
  t = fold(v)
  n = split("tbd|todo|tba|fixme|n/a|a definir|a preciser|a completer|a venir|a determiner|a remplir|a renseigner|a confirmer|a decider", F, "|")
  for (i = 1; i <= n; i++) if (hasword(t, F[i])) return 1
  return 0
}
function strip_comments(s,   a, b) {
  if (incom) {
    b = index(s, "-->")
    if (!b) return ""
    s = substr(s, b + 3); incom = 0
  }
  while ((a = index(s, "<!--")) > 0) {
    b = index(substr(s, a + 4), "-->")
    if (!b) { incom = 1; return substr(s, 1, a - 1) }
    s = substr(s, 1, a - 1) substr(s, a + b + 6)
  }
  return s
}
AWKEOF

# --- Exigences : un enregistrement par ligne, tout est imprimé par awk, dernière ligne `@ n s a`.
read -r -d '' AWK_REQ <<'AWKEOF'
function usable(v,   c) {
  c = substr(v, 1, 1)
  if (c == "[" || c == "<") return 0
  if (isfiller(v)) return 0
  if (index(v, "...") || index(v, ell)) return 0
  if (nchars(v) < 10) return 0
  return 1
}
function scan(s,   v, w) {
  if (match(s, /[Aa]cceptation[ \t]*:/)) {
    v = trim(substr(s, RSTART + RLENGTH))
    if (usable(v)) hascrit = 1
  }
  if (prio == "" && match(s, /(^|[^A-Za-z])[Pp]riorit[^:]*:/)) {
    v = trim(substr(s, RSTART + RLENGTH))
    sub(/^[*`_ \t]+/, "", v)
    w = "-"
    if (match(v, /^[A-Za-z]+/)) w = tolower(substr(v, RSTART, RLENGTH))
    prio = w
  }
}
function close_block() {
  if (!inblk) return
  inblk = 0
  nreq++
  if (!hascrit) {
    nsans++
    if (nsans <= 50) printf "[check-prd] ELIMINATOIRE exigence %s : aucun critere d'acceptation utilisable\n", id
  }
  if (prio == "") {
    nav++
    if (nav <= 50) printf "[check-prd] AVERTISSEMENT exigence %s : priorite absente\n", id
  } else if (prio != "must" && prio != "should" && prio != "could") {
    nav++
    if (nav <= 50) printf "[check-prd] AVERTISSEMENT exigence %s : priorite hors {must, should, could}\n", id
  }
}
{
  line = $0
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
  if (!infence) {
    pre = line; line = strip_comments(line)
    if (line ~ /^[ \t]*$/ && pre !~ /^[ \t]*$/) next
  }
  t = line; sub(/^[ \t]+/, "", t)
  f3 = substr(t, 1, 3)
  if (infence) { if (f3 == fch) infence = 0; next }
  if (f3 == "```" || f3 == "~~~") { close_block(); infence = 1; fch = f3; next }
  if (match(line, /^[ \t]*- \[[ xX]\] \*\*[A-Z][A-Z0-9]*-[A-Za-z0-9_-]+\*\*/)) {
    close_block()
    s = substr(line, RSTART, RLENGTH)
    k = index(s, "**")
    id = substr(s, k + 2, length(s) - k - 3)
    inblk = 1; hascrit = 0; prio = ""
    scan(substr(line, RSTART + RLENGTH))
    next
  }
  if (line ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+\[[ xX]\]/) {
    nunk++
    if (nunk <= 50) printf "[check-prd] AVERTISSEMENT ligne %d : case a cocher non reconnue comme exigence\n", NR
  }
  if (!inblk) next
  if (line ~ /^[ \t]*$/ || line ~ /^#/ || line ~ /^[ \t]*([-*+]|[0-9]+\.)[ \t]/ || line !~ /^[ \t]/) { close_block(); next }
  scan(line)
}
END { close_block(); printf "@ %d %d %d %d %d\n", nreq + 0, nsans + 0, nav + 0, nunk + 0, infence + 0 }
AWKEOF

# --- BRIEF : cinq rubriques, chacune avec au moins une ligne de corps ; dernière ligne `@ m`.
read -r -d '' AWK_BRIEF <<'AWKEOF'
{
  line = $0
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
  if (!infence) line = strip_comments(line)
  t = trim(line)
  f3 = substr(t, 1, 3)
  if (infence) { if (f3 == fch) infence = 0; next }
  if (f3 == "```" || f3 == "~~~") { infence = 1; fch = f3; next }
  if (line ~ /^#+[ \t]/) {
    lvl = 0
    while (substr(line, lvl + 1, 1) == "#") lvl++
    lab = tolower(substr(line, lvl + 1)); sub(/^[^a-z]+/, "", lab)
    name = ""
    if (index(lab, "probl") == 1) name = "probleme"
    else if (index(lab, "utilisateur") == 1) name = "utilisateurs"
    else if (index(lab, "valeur") == 1) name = "valeur"
    else if (index(lab, "contrainte") == 1) name = "contraintes"
    else if (index(lab, "hors p") == 1) name = "hors_perimetre"
    if (cur == "" || lvl <= curlvl) {
      cur = ""
      if (name != "") { cur = name; curlvl = lvl; seen[name] = 1 }
    }
    next
  }
  if (cur == "" || t == "") next
  if (substr(t, 1, 1) == "[") next
  if (hasword(tolower(t), "tbd") || hasword(tolower(t), "todo")) next
  if (t !~ /[^-*_=|#> \t]/) next
  body[cur]++
}
END {
  n = split("probleme utilisateurs valeur contraintes hors_perimetre", names, " ")
  for (i = 1; i <= n; i++) {
    k = names[i]
    if (!(k in seen)) { m++; printf "[check-prd] ELIMINATOIRE rubrique BRIEF %s : absente\n", k }
    else if (body[k] + 0 == 0) { m++; printf "[check-prd] ELIMINATOIRE rubrique BRIEF %s : vide\n", k }
  }
  printf "@ %d\n", m + 0
}
AWKEOF

WORST=0; NREQ=0; NSANS=0; NAV=0; NMANQ=0; NUNK=0; NFENCE=0
bump() { # <code> : ordre 5 > 1 > 3 > 0
  case "$1" in
    5) WORST=5 ;;
    1) if [ "$WORST" -ne 5 ]; then WORST=1; fi ;;
    3) if [ "$WORST" -eq 0 ]; then WORST=3; fi ;;
  esac
}
illisible() { # <entree> <raison>
  say "ILLISIBLE $1 : $2"; printf '[check-prd] ILLISIBLE %s : %s\n' "$1" "$2" >&2; bump 5
}
indetermine() { say "INDETERMINE $1 : $2"; bump 3; }

# Contrôle d'entrée AVANT toute lecture ; rend 0 si lisible, sinon 3 ou 5 (déjà signalé).
guard() { # <entree> <chemin>
  local name=$1 f=$2 size
  if [ ! -e "$f" ] && [ ! -L "$f" ]; then indetermine "$name" "cible absente"; return 3; fi
  if [ -L "$f" ]; then illisible "$name" "lien symbolique"; return 5; fi
  if [ ! -f "$f" ]; then illisible "$name" "fichier non regulier"; return 5; fi
  if [ ! -r "$f" ]; then illisible "$name" "fichier illisible"; return 5; fi
  size=$(wc -c < "$f" 2>/dev/null | tr -d ' \t')
  case "$size" in ''|*[!0-9]*) illisible "$name" "taille non numerique"; return 5 ;; esac
  if [ "$size" -gt "$PRD_MAX_OCTETS" ]; then illisible "$name" "au-dela de la borne de taille"; return 5; fi
  return 0
}

# Analyse : $OUT_TXT = sortie d'awk ; le code rendu est celui du tube (tr | awk) sous pipefail.
analyse() { # <chemin> <programme>
  OUT_TXT=$(tr -d '\r' < "$1" | awk -v bom="$BOM" -v ell="$ELL" "$AWK_LIB$NL$2")
}
# Sépare les lignes imprimées de la ligne de compteurs ; imprime les premières, range la seconde.
split_out() {
  case "$OUT_TXT" in
    *"$NL"*) printf '%s\n' "${OUT_TXT%"$NL"*}"; LAST=${OUT_TXT##*"$NL"} ;;
    *) LAST=$OUT_TXT ;;
  esac
}

if [ "$HAS_REQ" -eq 1 ] && guard exigences "$REQ"; then
  analyse "$REQ" "$AWK_REQ"; arc=$?
  split_out
  case "$LAST" in
    "@ "*) : ;;
    *) arc=1 ;;
  esac
  if [ "$arc" -ne 0 ]; then
    illisible exigences "analyse en echec"
  else
    set -- $LAST
    NREQ=$2; NSANS=$3; NAV=$4; NUNK=$5; NFENCE=$6
    printf '%s\n' "$OUT_TXT" | command grep -F 'AVERTISSEMENT ligne ' >&2
    if [ "$NFENCE" -ne 0 ]; then
      indetermine exigences "bloc de code non ferme en fin de fichier (exigences suivantes non lues)"
    fi
    if [ "$NREQ" -eq 0 ]; then
      indetermine exigences "aucune exigence detectee (forme attendue - [ ] **ID**: ...)"
    fi
    if [ "$NSANS" -gt 0 ]; then
      bump 1
    fi
  fi
fi

if [ "$HAS_BRIEF" -eq 1 ] && guard brief "$BRIEF"; then
  analyse "$BRIEF" "$AWK_BRIEF"; arc=$?
  split_out
  case "$LAST" in
    "@ "*) : ;;
    *) arc=1 ;;
  esac
  if [ "$arc" -ne 0 ]; then
    illisible brief "analyse en echec"
  else
    set -- $LAST
    NMANQ=$2
    if [ "$NMANQ" -gt 0 ]; then bump 1; fi
  fi
fi

say "BILAN exigences=${NREQ} sans_critere=${NSANS} avertissements=${NAV} rubriques_manquantes=${NMANQ} non_reconnues=${NUNK} code=${WORST}"
exit "$WORST"
