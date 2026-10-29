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
# critère est un CHAMP `Acceptation :` (ou `Critère d'acceptation :`, casse indifférente, blanc ou
# espace insécable admis avant les deux-points) : le mot « acceptation » n'est pas précédé d'un mot (début de
# ligne, ponctuation, tiret, parenthèse, puce ou emphase avant lui : champ ; lettre, chiffre ou apostrophe collée
# avant lui : « l'étape d'acceptation : … » n'est pas un champ). Sa valeur est utilisable si, marques de mise en
# forme en tête retirées (puces `- * + • · – — ‣ ◦ ▪ ∙ ●`, numérotées `1.` `1)`, citation, emphase, code,
# guillemets, soulignés) et blancs Unicode ramenés à l'espace (largeur nulle ignorée), elle ne commence pas par
# `[` `<` (ni leurs formes pleine chasse), n'est pas vide, ne porte ni trois points ni points de
# suspension, ne porte aucun marqueur de remplissage et compte au moins 10 CARACTÈRES non blancs (UTF-8
# compté en caractères, en awk pur sous LC_ALL=C : aucune locale UTF-8 requise). Marqueurs FORTS (en
# mot entier, partout dans la valeur) : TBD, TBA, FIXME, n/a, « à définir », « à préciser », « à compléter »,
# « à déterminer », « à remplir », « à renseigner », « à confirmer », « à décider » ; marqueurs FAIBLES, mots
# légitimes en phrase : TODO et « à venir », rouges seulement ISOLÉS (en début ou fin de valeur, ou collés à
# une ponctuation), verts au sein d'une phrase (« la todo list affiche dix éléments »). Casse et accents
# indifférents, marques combinantes comprises. Faux rouge ASSUMÉ, plutôt qu'un faux vert : un faible isolé
# dans une phrase légitime (« les évolutions à venir. »). Limite connue, laissée au juge : une mention à remplir
# qui n'est pas listée (« xxx », « lorem ipsum », « ? ») passe si elle atteint 10 caractères ; de même une emphase
# collée au mot (« la phase de **acceptation** : … ») le fait lire comme un champ. La qualité « testable » reste
# au juge. Les blocs de code et les commentaires HTML sont ignorés (un commentaire multi-ligne, lignes blanches comprises, au
# milieu d'une exigence ne la ferme pas). Une puce, même indentée, ouvre un nouvel élément : elle ne porte
# pas le critère de l'exigence qui précède. Fins de ligne CRLF et CR seules traitées comme des fins de ligne.
# Bloc de code OU commentaire HTML non fermé en fin de fichier (exigences ou rubriques) : la suite est
# illisible pour le gate, donc INDÉTERMINÉ (code 3). Ligne à case `[ ]`/`[x]` qui n'a pas la forme
# d'exigence (ID pointé, minuscules, puce `*`, numérotée) : AVERTISSEMENT par numéro de ligne (stdout et
# stderr), jamais réimprimée ; l'effet sur le code reste nul, le BILAN la compte (`non_reconnues`).
# Éliminatoire 2 : une rubrique du BRIEF manque ou n'a aucune ligne de corps (hors commentaire HTML,
# hors ligne de remplissage selon la MÊME règle que les critères : entre crochets ou chevrons après
# puce/citation/emphase, points de suspension, marqueurs ci-dessus ; sans seuil de longueur) :
# probleme, utilisateurs, valeur, contraintes, hors_perimetre (titres Markdown reconnus par préfixe
# ASCII, casse indifférente).
# Avertissement (jamais d'effet sur le code) : priorité absente ou hors {must, should, could}.

# Codes de sortie (chacun énuméré, aucun implicite) :
#   0 = conforme : aucun éliminatoire et au moins une exigence lue si --requirements est fourni.
#   1 = éliminatoire : exigence sans critère utilisable, ou rubrique du BRIEF absente ou vide.
#   3 = INDÉTERMINÉ : cible absente, zéro exigence détectée, ou bloc de code / commentaire HTML non
#       fermé en fin de fichier. Jamais un vert à vide.
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
CR=$(printf '\r')

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
# Caractères non blancs (valeur déjà normalisée par lead) : octets de continuation UTF-8 (0x80-0xBF) et marques combinantes retirés.
function nchars(s) {
  gsub(/[ \t]/, "", s)
  gsub(/\314[\200-\277]/, "", s); gsub(/\315[\200-\257]/, "", s)
  gsub(/[\200-\277]/, "", s)
  return length(s)
}
# Largeur nulle retirée, blancs Unicode (insécables, fines, ID, etc.) ramenés à l'espace simple.
function norm(s) {
  gsub(/\342\200[\213-\217]|\342\201\240|\357\273\277|\302\255|\341\240\216/, "", s)
  gsub(/\302\240|\342\200[\200-\212]|\342\200[\250\251]|\342\200\257|\342\201\237|\343\200\200|\341\232\200/, " ", s)
  return s
}
# Marques de mise en forme et de liste en tête retirées : espaces, puces (- * + • · – — ‣ ◦ ▪ ∙ ●), numérotées
# (`1.`, `1)` suivies d'un blanc ou de la fin), citation `>`, emphase, code, guillemets (" ' « “ ‘ „), # ~ = |.
function lead(v) {
  v = norm(v)
  while (v != "" && match(v, /^([ \t*_`"'>+#~=|-]|[0-9]+[.)]([ \t]|$)|\302[\253\267]|\342\200[\223\224\230\234\236\242\243]|\342\227[\246\217]|\342\226\252|\342\210\231)/)) v = substr(v, RLENGTH + 1)
  return v
}
# Marqueur « faible » (todo, à venir) : mot légitime dans une phrase, rouge seulement s'il est isolé
# (début, fin, ou collé à une ponctuation) ; au sein d'une phrase de mots, il reste vert.
function isolated(t, w,   p, off, pre, post) {
  off = 0
  while ((p = index(substr(t, off + 1), w)) > 0) {
    p += off
    pre = substr(t, 1, p - 1); post = substr(t, p + length(w))
    if (pre !~ /[a-z0-9_]$/ && post !~ /^[a-z0-9_]/) {
      sub(/[ \t]+$/, "", pre); sub(/^[ \t]+/, "", post)
      if (pre == "" || pre !~ /[a-z0-9]$/ || post == "" || post !~ /^[a-z0-9]/) return 1
    }
    off = p
  }
  return 0
}
function fillword(t,   i, n, S, W) {
  n = split("tbd|tba|fixme|n/a|a definir|a preciser|a completer|a determiner|a remplir|a renseigner|a confirmer|a decider", S, "|")
  for (i = 1; i <= n; i++) if (hasword(t, S[i])) return 1
  n = split("todo|a venir", W, "|")
  for (i = 1; i <= n; i++) if (isolated(t, W[i])) return 1
  return 0
}
# Règle de remplissage UNIQUE (critères d'acceptation ET corps de rubrique du BRIEF) : valeur vide, entre
# crochets ou chevrons (après marques de mise en forme), points de suspension, ou marqueur de remplissage.
function isfill(v,   c) {
  v = lead(v)
  if (v == "") return 1
  c = substr(v, 1, 1)
  if (c == "[" || c == "<") return 1
  if (v ~ /^(\357\274[\273\234]|\343\200\210|\342\237\250)/) return 1
  if (index(v, "...") || index(v, ell)) return 1
  return fillword(fold(v))
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
function usable(v) {
  v = lead(v)
  if (isfill(v)) return 0
  if (nchars(v) < 10) return 0
  return 1
}
# Critère : seulement comme CHAMP : le mot « acceptation » (avec ou sans « Critère d' », casse indifférente, blanc
# avant les deux-points) n'est PAS précédé d'un mot. Ce qui précède (blancs retirés) est vide ou ne se termine pas
# par une lettre, un chiffre ou une apostrophe collée à une lettre : ponctuation, tiret, parenthèse, puce, fin
# ou début d'emphase (« Texte, Acceptation : », « Texte — Acceptation : », « (Acceptation : », « Texte
# **Acceptation :** ») sont des champs ; « l'étape d'acceptation : » n'en est pas un. Lettres reconnues : ASCII,
# Latin-1, Latin étendu, grec, cyrillique, marques combinantes.
function wordbefore(p) {
  sub(/[ \t]+$/, "", p)
  return (p ~ /([A-Za-z0-9]|\303[\200-\226\230-\266\270-\277]|[\304-\311][\200-\277]|[\316-\321][\200-\277]|(\314|\315)[\200-\277])('|\342\200\231)?$/)
}
function critval(s,   low, p, off, pre, rest) {
  s = norm(s); low = tolower(s); off = 0
  while ((p = index(substr(low, off + 1), "acceptation")) > 0) {
    p += off
    pre = substr(low, 1, p - 1); rest = substr(s, p + 11)
    if (match(pre, /crit[^ \t]*[ \t]+d('|\342\200\231)[ \t]*$/)) pre = substr(pre, 1, RSTART - 1)
    if (!wordbefore(pre) && match(rest, /^[ \t]*[*_]*[ \t]*:/)) {
      if (usable(substr(rest, RLENGTH + 1))) return 1
    }
    off = p
  }
  return 0
}
function scan(s,   v, w) {
  if (critval(s)) hascrit = 1
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
    inc0 = incom; pre = line; line = strip_comments(line)
    if (line ~ /^[ \t]*$/ && (pre !~ /^[ \t]*$/ || inc0)) next
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
END { close_block(); printf "@ %d %d %d %d %d %d\n", nreq + 0, nsans + 0, nav + 0, nunk + 0, infence + 0, incom + 0 }
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
  if (isfill(t)) next
  body[cur]++
}
END {
  n = split("probleme utilisateurs valeur contraintes hors_perimetre", names, " ")
  for (i = 1; i <= n; i++) {
    k = names[i]
    if (!(k in seen)) { m++; printf "[check-prd] ELIMINATOIRE rubrique BRIEF %s : absente\n", k }
    else if (body[k] + 0 == 0) { m++; printf "[check-prd] ELIMINATOIRE rubrique BRIEF %s : vide\n", k }
  }
  printf "@ %d %d %d\n", m + 0, infence + 0, incom + 0
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
  OUT_TXT=$(sed "s/$CR\$//" "$1" | tr '\r' '\n' | awk -v bom="$BOM" -v ell="$ELL" "$AWK_LIB$NL$2")
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
    NREQ=$2; NSANS=$3; NAV=$4; NUNK=$5; NFENCE=$6; NCOM=$7
    printf '%s\n' "$OUT_TXT" | command grep -F 'AVERTISSEMENT ligne ' >&2
    if [ "$NFENCE" -ne 0 ]; then
      indetermine exigences "bloc de code non ferme en fin de fichier (exigences suivantes non lues)"
    fi
    if [ "$NCOM" -ne 0 ]; then
      indetermine exigences "commentaire HTML non ferme en fin de fichier (exigences suivantes non lues)"
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
    if [ "$3" -ne 0 ]; then
      indetermine brief "bloc de code non ferme en fin de fichier (rubriques suivantes non lues)"
    fi
    if [ "$4" -ne 0 ]; then
      indetermine brief "commentaire HTML non ferme en fin de fichier (rubriques suivantes non lues)"
    fi
    if [ "$NMANQ" -gt 0 ]; then bump 1; fi
  fi
fi

say "BILAN exigences=${NREQ} sans_critere=${NSANS} avertissements=${NAV} rubriques_manquantes=${NMANQ} non_reconnues=${NUNK} code=${WORST}"
exit "$WORST"
