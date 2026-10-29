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
# espace insécable admis avant les deux-points ; la valeur s'arrête au champ SUIVANT reconnu : `Priorité :` ou une
# autre `Acceptation :`, un champ vide suivi d'un autre sur la même ligne reste vide) : le mot « acceptation » n'est pas précédé d'un mot (début de
# ligne, ponctuation, tiret entouré d espaces, parenthèse, puce ou emphase avant lui : champ ; lettre, chiffre ou apostrophe collée
# avant lui : « l'étape d'acceptation : … » n'est pas un champ). Sa valeur est utilisable si, marques de mise en
# forme en tête retirées (puces `- * + • · – — ‣ ◦ ▪ ∙ ●`, numérotées `1.` `1)`, citation, emphase, code,
# guillemets, soulignés) et blancs Unicode ramenés à l'espace (largeur nulle ignorée), elle ne commence pas par
# `[` `<` (ni leurs formes pleine chasse), n'est pas vide, ne porte ni trois points ni points de
# suspension, ne porte aucun marqueur de remplissage et compte au moins 10 CARACTÈRES non blancs (UTF-8
# compté en caractères, en awk pur sous LC_ALL=C : aucune locale UTF-8 requise). MISE EN FORME EN LIGNE : avant les tests de
# mots et le décompte, TOUTE emphase (`*` `_` `~`), code en ligne et guillemets (droits, courbes, chevrons) est retirée
# partout, en tête, en fin et autour des mots, puis la ponctuation de tête et de fin et les blancs multiples ; à point
# fixe (borné), à l'identique pour les critères et les corps de rubrique : un marqueur entouré de n'importe quelle
# emphase (`_À définir_`, `__TBD__`, `**à** **définir**`) vaut le marqueur nu. Un `_` entre deux caractères de mot
# (`tbd_label`) reste. Une valeur faite de ponctuation seule est vide. Marqueurs FORTS (en
# mot entier, partout dans la valeur) : TBD, TBA, FIXME, n/a, « à définir », « à préciser », « à compléter »,
# « à déterminer », « à remplir », « à renseigner », « à confirmer », « à décider » ; marqueurs FAIBLES, mots
# légitimes en phrase : TODO et « à venir », rouges seulement ISOLÉS (en début ou fin de valeur, ou collés à
# une ponctuation), verts au sein d'une phrase (« la todo list affiche dix éléments »). Casse et accents
# indifférents, marques combinantes comprises. Faux rouge ASSUMÉ, plutôt qu'un faux vert : un faible isolé
# dans une phrase légitime (« les évolutions à venir. »). Limite connue, laissée au juge : une mention à remplir
# qui n'est pas listée (« xxx », « lorem ipsum », « ? », « {…} », « (critère à écrire) », « to be determined later »)
# passe si elle atteint 10 caractères ; de même une emphase collée au mot (« la phase de **acceptation** : … ») le
# fait lire comme un champ ; les champs en anglais (`Acceptance:`) ne sont pas reconnus ; un « n/a » cité ou des points
# de suspension légitimes sont rouges. La qualité « testable » reste
# au juge. Les blocs de code et les commentaires HTML sont ignorés (un `<!--` dans un span de code en ligne n'ouvre
# aucun commentaire : appariement des séries d'accents graves à la CommonMark ; un commentaire multi-ligne, lignes blanches comprises, au
# milieu d'une exigence ne la ferme pas). Une puce, même indentée, ouvre un nouvel élément : elle ne porte
# pas le critère de l'exigence qui précède. Fins de ligne CRLF et CR seules traitées comme des fins de ligne.
# Bloc de code OU commentaire HTML non fermé en fin de fichier (exigences ou rubriques) : la suite est
# illisible pour le gate, donc INDÉTERMINÉ (code 3). Ligne à case `[ ]`/`[x]` qui n'a pas la forme
# d'exigence (ID pointé, minuscules, puce `*`, numérotée) : AVERTISSEMENT par numéro de ligne (stdout et
# stderr), jamais réimprimée, et INDÉTERMINÉ (code 3) : une exigence que le gate ne lit pas est une exigence que le gate ne
# juge pas, donc jamais un vert (arbitrage Samuel, AskUserQuestion session principale, 2026-10-29). Le code 3 cède devant 1
# et 5 ; le BILAN compte ces lignes (`non_reconnues`).
# Séparateur avant le champ : `,` `—` `–` `-` (entouré d'espaces) et `(` précèdent un champ, au même titre que la
# ponctuation et la puce (« Priorité : must, Acceptation : … ») ; un tiret COLLÉ à un mot (« pré-acceptation : ») fait un
# mot composé, pas un champ ; « il faut, acceptation : » sans valeur reste rouge (champ vide). Une valeur qui répète le
# libellé (`Acceptation : Acceptation`, `Acceptation : Critère d'acceptation`) est un remplissage. Le texte des gabarits
# livrés, crochets retirés (consignes du BRIEF, « quoi, combien, en combien de temps »), est un remplissage (tmplword).
# Éliminatoire 2 : une rubrique du BRIEF manque ou n'a aucune ligne de corps (hors commentaire HTML,
# hors ligne de remplissage selon la MÊME règle que les critères : entre crochets ou chevrons après
# puce/citation/emphase, points de suspension, marqueurs ci-dessus ; sans seuil de longueur) :
# probleme, utilisateurs, valeur, contraintes, hors_perimetre (titres Markdown reconnus par préfixe, à la
# typographie près : casse, accents, trait d'union, souligné, espaces multiples ou insécables, emphase). Le contenu
# sous un sous-titre plus profond appartient à la rubrique ; un titre de niveau égal ou inférieur la ferme. Limite
# connue : un sous-titre plus profond qui porte un nom de rubrique reste dans la rubrique ouverte, il ne déclare pas
# la sienne.
# Avertissement (jamais d'effet sur le code) : priorité absente ou hors {must, should, could}.

# Codes de sortie (chacun énuméré, aucun implicite) :
#   0 = conforme : aucun éliminatoire et au moins une exigence lue si --requirements est fourni.
#   1 = éliminatoire : exigence sans critère utilisable, ou rubrique du BRIEF absente ou vide.
#   3 = INDÉTERMINÉ : cible absente, zéro exigence détectée, ligne à case à cocher non reconnue comme
#       exigence, ou bloc de code / commentaire HTML non fermé en fin de fichier. Jamais un vert à vide.
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
# Texte des gabarits LIVRÉS (BRIEF.template.md, REQUIREMENTS.template.md du poste product) une fois les crochets retirés :
# une consigne recopiée sans ses crochets reste un remplissage. Sous-chaîne du texte replié (accents, casse, apostrophe
# ramenée à l'espace par plain). La suite compare ces fragments aux gabarits réels : un gabarit qui change sans eux rougit.
function tmplword(t,   i, n, T) {
  n = split("quel probleme rencontre-t-on|qui utilisera ce produit|qu est-ce qui change concretement|quelles limites s imposent|qu est-ce qui est volontairement exclu|quoi, combien, en combien de temps", T, "|")
  for (i = 1; i <= n; i++) if (index(t, T[i])) return 1
  return 0
}
function fillword(t,   i, n, S, W) {
  if (tmplword(t)) return 1
  n = split("tbd|tba|fixme|n/a|a definir|a preciser|a completer|a determiner|a remplir|a renseigner|a confirmer|a decider", S, "|")
  for (i = 1; i <= n; i++) if (hasword(t, S[i])) return 1
  n = split("todo|a venir", W, "|")
  for (i = 1; i <= n; i++) if (isolated(t, W[i])) return 1
  return 0
}
# Mise en forme Markdown EN LIGNE retirée, à point fixe : marques de tête (lead), emphase `*` `_` `~`, code, guillemets
# (`"` « » “ ” „ ‘ ’ `'`), partout (en tête, en fin, autour des mots), puis ponctuation de tête et de fin et blancs
# repliés. Un `_` entre deux caractères de mot (snake_case) reste : ce n'est pas une mise en forme.
# Chaque retrait peut en découvrir un autre (`**1.** tbd`), d'où la boucle jusqu'à stabilité (bornée). Appliquée À
# L'IDENTIQUE aux critères et aux corps de rubrique : un marqueur entouré de n'importe quelle emphase vaut le marqueur nu.
function protect_us(v,   o) {
  o = ""
  while (match(v, /[A-Za-z0-9\200-\377]_[A-Za-z0-9\200-\377]/)) { o = o substr(v, 1, RSTART) "\001"; v = substr(v, RSTART + 2) }
  return o v
}
function plain(v,   k, o) {
  for (k = 0; k < 8; k++) {
    o = v
    v = lead(v)
    gsub(/\342\200\231/, "'", v)
    v = protect_us(v)
    gsub(/[*_`"~']|\302[\253\273]|\342\200[\230-\237]/, " ", v)
    gsub(/\001/, "_", v)
    gsub(/[ \t]+/, " ", v)
    sub(/^([] \t.,;:!?(){}[<>|=#+\/-]|\342\200[\223\224\242\246]|\302\267)+/, "", v)
    sub(/([] \t.,;:!?(){}[<>|=#+\/-]|\342\200[\223\224\242\246]|\302\267)+$/, "", v)
    if (v == o) break
  }
  return v
}
# Règle de remplissage UNIQUE (critères d'acceptation ET corps de rubrique du BRIEF) : valeur vide, entre
# crochets ou chevrons (après marques de mise en forme), points de suspension, ou marqueur de remplissage.
function isfill(v,   c, p) {
  v = lead(v)
  if (v == "") return 1
  c = substr(v, 1, 1)
  if (c == "[" || c == "<") return 1
  if (v ~ /^(\357\274[\273\234]|\343\200\210|\342\237\250)/) return 1
  if (index(v, "...") || index(v, ell)) return 1
  p = plain(v)
  if (p == "") return 1
  return fillword(fold(p))
}
# Contenu d'un span de code en ligne : un `<!--` n'y ouvre aucun commentaire. Le marqueur invisible \004 y est inséré
# (retiré en sortie de strip_comments). Appariement CommonMark : une série de n accents graves ferme sur la série de
# longueur exactement n qui suit ; sans fermeture, elle reste littérale. Linéaire (split, tableaux, aucune recopie).
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
AWKEOF

# --- Exigences : un enregistrement par ligne, tout est imprimé par awk, dernière ligne `@ n s a`.
read -r -d '' AWK_REQ <<'AWKEOF'
function usable(v,   p) {
  v = lead(v)
  if (isfill(v)) return 0
  p = fold(plain(v))
  if (p == "acceptation" || p == "critere d acceptation") return 0
  if (nchars(plain(v)) < 10) return 0
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
# Libellé de champ « acceptation » reconnu à la position p de low (s en casse d'origine) : pose lstart (début du
# libellé, « Critère d' » compris) et lend (premier caractère de la valeur, après les deux-points).
function acclabel(low, s, p,   pre, rest) {
  pre = substr(low, 1, p - 1); rest = substr(s, p + 11); lstart = p
  if (match(pre, /crit[^ \t]*[ \t]+d('|\342\200\231)[ \t]*$/)) { lstart = RSTART; pre = substr(pre, 1, RSTART - 1) }
  if (wordbefore(pre)) return 0
  if (pre ~ /([A-Za-z0-9]|[\200-\377])-$/) return 0
  if (!match(rest, /^[ \t]*[*_]*[ \t]*:/)) return 0
  lend = p + 11 + RLENGTH
  return 1
}
# La valeur d'un champ s'arrête au champ SUIVANT reconnu : Priorité (même règle de mot précédent), ou une autre
# Acceptation. Un champ vide suivi d'un autre sur la même ligne reste vide.
function fieldcut(v,   low, p, off, q, cut) {
  low = tolower(v); cut = 0; off = 0
  while (match(substr(low, off + 1), /priorit(e|\303[\210-\212\250-\252]|e\314[\200-\277])?[ \t*_]*:/)) {
    p = off + RSTART
    if (!wordbefore(substr(low, 1, p - 1))) { cut = p; break }
    off = p
  }
  off = 0
  while ((q = index(substr(low, off + 1), "acceptation")) > 0) {
    q += off
    if (cut && q >= cut) break
    if (acclabel(low, v, q)) { cut = lstart; break }
    off = q
  }
  if (cut) v = substr(v, 1, cut - 1)
  return v
}
function critval(s,   low, p, off) {
  s = norm(s); low = tolower(s); off = 0
  while ((p = index(substr(low, off + 1), "acceptation")) > 0) {
    p += off
    if (acclabel(low, s, p) && usable(fieldcut(substr(s, lend)))) return 1
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
    lab = fold(norm(substr(line, lvl + 1)))
    gsub(/[*_`~-]|\342\200[\220-\225]|\342\210\222/, " ", lab); gsub(/[ \t]+/, " ", lab); sub(/^[^a-z]+/, "", lab)
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
    if [ "$NUNK" -gt 0 ]; then
      indetermine exigences "case a cocher non reconnue comme exigence (lignes signalees par AVERTISSEMENT ligne)"
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
