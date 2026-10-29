#!/usr/bin/env bash
# check-architecture.sh — gate déterministe de l'architecture avant découpage (Phase 60, ARCG-06, ARCG-07 ;
# P60-D-05, P60-D-06, P60-PL-03, P60-PL-04). Appelé par le head et par le manager produit : sans lui, « le head
# refuse le découpage tant que l'architecture n'est pas validée » serait la lecture d'un agent, un vert
# auto-déclaré (A-08). Distinct de check-phase-validation.sh : celui-ci juge UN fichier, pas une phase.
#
# Rôle : CONSTATER, jamais corriger. LECTURE SEULE, sans exception : aucun fichier créé, modifié ni effacé,
# aucune écriture hors stdout et stderr. Le fichier est écrit par un worker ou un humain : NON FIABLE. Son
# contenu n'est jamais réimprimé (la sortie entre dans le contexte d'un agent) : seuls sont imprimés des noms de
# rubrique FIXES, embarqués dans ce script, et des étiquettes. Son contenu n'est jamais évalué (awk seul).
# Ne lit QUE le fichier passé : jamais le gabarit, jamais la carte descriptive du code existant ni la
# documentation du dépôt, qui portent le même nom de fichier (Pitfall 7).
#
# Usage :
#   check-architecture.sh --architecture <f>
#   check-architecture.sh -h | --help
# `--architecture` est obligatoire (`--architecture=<f>` admis), sans chemin par défaut, donné une seule fois.
# Forme exec : l'appelant écrit `bash <chemin résolu> --architecture <f>` en arguments séparés, sans `|| true`
# ni tube qui masquerait le code ; le script porte seul la sémantique de son code ; aucun hook (P60-PL-23).
#
# Ligne d'état (même grammaire que le marqueur de phase, P60-PL-01) : exactement UNE ligne `**Validation:**
# <valeur>` (variante `**Validation**:` tolérée) hors bloc de code et hors commentaire HTML. Jeton = premier mot en
# minuscules : `proposed` -> proposée ; `validated` -> validée, suffixe `(<poste>, <AAAA-MM-JJ>[, override])`
# toléré, tout autre texte après lui -> INDÉTERMINÉ ; tout autre jeton -> INDÉTERMINÉ. Aucune ligne ou plusieurs
# lignes -> INDÉTERMINÉ. La validation appartient à un dev : ce script constate la ligne, il ne vérifie ni
# l'auteur ni la date (limite écrite : une ligne `validated` posée à la main est crue).
#
# Six rubriques minimales (P60-PL-04), titres Markdown de tout niveau reconnus par préfixe ASCII du libellé
# (casse, accents, numérotation, emphase indifférents) : contexte, choix_structurants (« choix »), composants
# (« composant »), donnees (« donn »), contraintes (« contrainte »), risques (« risque »). Une rubrique se ferme
# au titre suivant de niveau égal ou inférieur ; un sous-titre plus profond lui appartient. Corps = au moins une
# ligne non blanche hors bloc de code et hors commentaire HTML qui, marqueurs de citation `>` et de liste de tête
# retirés (`- `, `* `, `+ `, `N. `, `N) `), ne commence pas par `[` (emphase de tête ignorée), ne contient ni TBD
# ni TODO (mots entiers, casse indifférente) et porte au moins une lettre ou un chiffre. Un titre n'est jamais un
# corps. Une carte descriptive du code (Layers, Data Flow...) n'a pas ces rubriques : rouge.
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0 = validée et complète : ligne d'état `validated` ET les six rubriques ont un corps. Seule porte verte.
#   1 = fichier absent (cas nominal à refuser, différence assumée avec les gates d'entrée voisins qui rendent 3),
#       ligne d'état `proposed`, ou rubrique absente ou vide.
#   3 = INDÉTERMINÉ : ligne d'état absente, de valeur inconnue ou multiple ; bloc de code ou commentaire HTML
#       non fermé. Jamais un vert à vide.
#   5 = entrée illisible, BRUYANTE : lien symbolique, non régulier (FIFO, dossier), illisible, taille non
#       numérique, au-delà de 1048576 octets, analyse en échec. Refus AVANT lecture.
#   64 = erreur d'usage (aucune entrée, valeur vide, option inconnue ou répétée).
#   Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness.
# Entre plusieurs constats, l'ordre 5 > 1 > 3 > 0 décide.
#
# Sortie : lignes préfixées `[check-architecture]` puis une étiquette ASCII fixe :
#   ARCHITECTURE absente    ARCHITECTURE proposee    ARCHITECTURE validee (seulement si le code final est 0)
#   ELIMINATOIRE rubrique <nom> : absente | vide
#   INDETERMINE statut : absent | valeur inconnue | multiple
#   INDETERMINE bloc de code non ferme    INDETERMINE commentaire HTML non ferme
#   ILLISIBLE <raison> (aussi sur stderr)
#   BILAN statut=<absente|proposee|validee|inconnu> rubriques_manquantes=<n> code=<rc>
# `rubriques_manquantes` compte les lignes ELIMINATOIRE : 0 quand le fichier n'a pas été analysé.
set -uo pipefail
export LC_ALL=C

CARCH_MAX_OCTETS=1048576
ARCH=""; HAS_ARCH=0
NL=$'\n'
CR=$(printf '\r')
BOM=$(printf '\357\273\277')
TAG='[check-architecture]'

usage_err() { printf '%s %s\n' "$TAG" "$1" >&2; exit 64; }
say() { printf '%s %s\n' "$TAG" "$*"; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --architecture)
      [ "$HAS_ARCH" -eq 0 ] || usage_err "--architecture donné deux fois"
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "--architecture nécessite une valeur"
      ARCH=$2; HAS_ARCH=1; shift 2 ;;
    --architecture=*)
      [ "$HAS_ARCH" -eq 0 ] || usage_err "--architecture donné deux fois"
      ARCH=${1#--architecture=}; [ -n "$ARCH" ] || usage_err "--architecture nécessite une valeur"
      HAS_ARCH=1; shift ;;
    -h|--help) awk '/^set -uo/{exit} /^# /{sub(/^# /,""); print}' "$0"; exit 0 ;;
    *) usage_err "argument inconnu (usage : --architecture <f>)" ;;
  esac
done
[ "$HAS_ARCH" -eq 1 ] || usage_err "--architecture est obligatoire (usage : --architecture <f>)"

# --- Programme awk : lignes ELIMINATOIRE puis `@ marqueurs classe code_ouvert commentaire_ouvert manquantes`.
read -r -d '' AWK_PROG <<'AWKEOF'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
# Minuscules ASCII, accents français repliés (UTF-8 lu en octets).
function fold(s) {
  s = tolower(s)
  gsub(/\314[\200-\277]|\315[\200-\257]/, "", s)
  gsub(/à|À|â|Â/, "a", s); gsub(/é|É|è|È|ê|Ê|ë|Ë/, "e", s)
  gsub(/î|Î|ï|Ï/, "i", s); gsub(/ô|Ô/, "o", s); gsub(/ù|Ù|û|Û/, "u", s); gsub(/ç|Ç/, "c", s)
  return s
}
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
# Ligne de corps : citation et puce de tête retirées, ni entre crochets, ni TBD/TODO, au moins une lettre ou un chiffre.
function isbody(t,   v, k, w) {
  v = t
  for (k = 0; k < 8; k++) {
    sub(/^[ \t>]+/, "", v)
    if (!sub(/^([-*+]|[0-9]+[.)])[ \t]+/, "", v)) break
  }
  w = v; sub(/^[*_`~ \t]+/, "", w)
  if (substr(w, 1, 1) == "[") return 0
  v = fold(v)
  if (hasword(v, "tbd") || hasword(v, "todo")) return 0
  if (v !~ /[a-z0-9]|\303[\200-\277]|[\304-\311][\200-\277]|[\316-\337][\200-\277]|[\344-\351][\200-\277][\200-\277]/) return 0
  return 1
}
# Contenu d'un span de code en ligne : un `<!--` n'y ouvre aucun commentaire (marqueur \004, retiré en sortie
# de strip_comments). Appariement CommonMark des séries d'accents graves ; sans fermeture, elle reste littérale.
function neutral(s,   n, P, i, k, nr, K, A, NX, LAST, r, c, out) {
  n = split(s, P, "`")
  if (n < 3) return s
  nr = 0; i = 1
  while (i < n) {
    k = 1
    while (i + k < n && P[i + k] == "") k++
    nr++; K[nr] = k; A[nr] = i; i += k
  }
  split("", LAST)
  for (r = nr; r >= 1; r--) { NX[r] = (K[r] in LAST) ? LAST[K[r]] : 0; LAST[K[r]] = r }
  r = 1
  while (r <= nr) {
    if (NX[r]) {
      c = NX[r]
      for (i = A[r] + K[r]; i <= A[c]; i++) gsub(/<!--/, "<\004!--", P[i])
      r = c + 1
    } else r++
  }
  out = P[1]
  for (i = 2; i <= n; i++) out = out "`" P[i]
  return out
}
function strip_comments(s,   a, b) {
  if (incom) {
    b = index(s, "-->")
    if (!b) return ""
    s = substr(s, b + 3); incom = 0
  }
  if (index(s, "`") && index(s, "<!--")) s = neutral(s)
  while ((a = index(s, "<!--")) > 0) {
    b = index(substr(s, a + 4), "-->")
    if (!b) { incom = 1; s = substr(s, 1, a - 1); gsub(/\004/, "", s); return s }
    s = substr(s, 1, a - 1) substr(s, a + b + 6)
  }
  gsub(/\004/, "", s)
  return s
}
BEGIN { nn = split("contexte choix_structurants composants donnees contraintes risques", NAMES, " ") }
{
  line = $0
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
  if (!infence) line = strip_comments(line)
  t = trim(line); f3 = substr(t, 1, 3)
  if (infence) { if (f3 == fch) infence = 0; next }
  if (f3 == "```" || f3 == "~~~") { infence = 1; fch = f3; next }
  if (line ~ /^#+[ \t]/) {
    lvl = 0
    while (substr(line, lvl + 1, 1) == "#") lvl++
    lab = fold(substr(line, lvl + 1))
    gsub(/[*_`~-]/, " ", lab); gsub(/[ \t]+/, " ", lab); sub(/^[^a-z]+/, "", lab)
    name = ""
    if (index(lab, "contexte") == 1) name = "contexte"
    else if (index(lab, "choix") == 1) name = "choix_structurants"
    else if (index(lab, "composant") == 1) name = "composants"
    else if (index(lab, "donn") == 1) name = "donnees"
    else if (index(lab, "contrainte") == 1) name = "contraintes"
    else if (index(lab, "risque") == 1) name = "risques"
    if (cur == "" || lvl <= curlvl) {
      cur = ""
      if (name != "") { cur = name; curlvl = lvl; seen[name] = 1 }
    }
    next
  }
  if (match(line, /^[ \t]*\*\*Validation(:\*\*|\*\*[ \t]*:)/)) {
    nmark++
    if (nmark == 1) {
      v = trim(substr(line, RLENGTH + 1)); tok = v; sub(/[ \t].*$/, "", tok)
      rest = substr(v, length(tok) + 1); sub(/^[ \t]+/, "", rest); tok = tolower(tok)
      if (tok == "proposed") cls = "proposed"
      else if (tok == "validated" && (rest == "" || substr(rest, 1, 1) == "(")) cls = "validated"
      else cls = "inconnu"
    }
    next
  }
  if (cur == "" || t == "") next
  if (isbody(t)) body[cur]++
}
END {
  for (i = 1; i <= nn; i++) {
    k = NAMES[i]
    if (!(k in seen)) { m++; printf "[check-architecture] ELIMINATOIRE rubrique %s : absente\n", k }
    else if (body[k] + 0 == 0) { m++; printf "[check-architecture] ELIMINATOIRE rubrique %s : vide\n", k }
  }
  printf "@ %d %s %d %d %d\n", nmark + 0, (cls == "" ? "-" : cls), infence + 0, incom + 0, m + 0
}
AWKEOF

WORST=0; STATUT=inconnu; NMANQ=0
bump() { # <code> : ordre 5 > 1 > 3 > 0
  case "$1" in
    5) WORST=5 ;;
    1) if [ "$WORST" -ne 5 ]; then WORST=1; fi ;;
    3) if [ "$WORST" -eq 0 ]; then WORST=3; fi ;;
  esac
}
illisible() { # <raison>
  say "ILLISIBLE $1"; printf '%s ILLISIBLE %s\n' "$TAG" "$1" >&2; bump 5
}
indetermine() { say "INDETERMINE $1"; bump 3; }

# Contrôle d'entrée AVANT toute lecture ; rend 0 si lisible, sinon 1 ou 5 (déjà signalé, jamais le contenu).
guard() { # <chemin>
  local f=$1 size
  if [ ! -e "$f" ] && [ ! -L "$f" ]; then say "ARCHITECTURE absente"; STATUT=absente; bump 1; return 1; fi
  if [ -L "$f" ]; then illisible "lien symbolique"; return 5; fi
  if [ ! -f "$f" ]; then illisible "fichier non regulier"; return 5; fi
  if [ ! -r "$f" ]; then illisible "fichier illisible"; return 5; fi
  size=$(wc -c < "$f" 2>/dev/null | tr -d ' \t')
  case "$size" in ''|*[!0-9]*) illisible "taille non numerique"; return 5 ;; esac
  if [ "$size" -gt "$CARCH_MAX_OCTETS" ]; then illisible "au-dela de la borne de taille"; return 5; fi
  return 0
}

if guard "$ARCH"; then
  OUT_TXT=$(sed "s/$CR\$//" "$ARCH" | tr '\r' '\n' | awk -v bom="$BOM" "$AWK_PROG"); arc=$?
  case "$OUT_TXT" in
    *"$NL"*) LAST=${OUT_TXT##*"$NL"} ;;
    *) LAST=$OUT_TXT ;;
  esac
  case "$LAST" in "@ "*) : ;; *) arc=1 ;; esac
  if [ "$arc" -ne 0 ]; then
    illisible "analyse en echec"
  else
    case "$OUT_TXT" in *"$NL"*) printf '%s\n' "${OUT_TXT%"$NL"*}" ;; esac
    set -- $LAST
    NMARK=$2; CLS=$3; NFENCE=$4; NCOM=$5; NMANQ=$6
    if [ "$NMANQ" -gt 0 ]; then bump 1; fi
    if [ "$NFENCE" -ne 0 ]; then indetermine "bloc de code non ferme"; fi
    if [ "$NCOM" -ne 0 ]; then indetermine "commentaire HTML non ferme"; fi
    if [ "$NMARK" -eq 0 ]; then indetermine "statut : absent"
    elif [ "$NMARK" -gt 1 ]; then indetermine "statut : multiple"
    else
      case "$CLS" in
        proposed) STATUT=proposee; say "ARCHITECTURE proposee"; bump 1 ;;
        validated) STATUT=validee ;;
        *) indetermine "statut : valeur inconnue" ;;
      esac
    fi
    if [ "$STATUT" = "validee" ] && [ "$WORST" -eq 0 ]; then say "ARCHITECTURE validee"; fi
  fi
fi

say "BILAN statut=${STATUT} rubriques_manquantes=${NMANQ} code=${WORST}"
exit "$WORST"
