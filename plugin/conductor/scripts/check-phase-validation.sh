#!/usr/bin/env bash
# check-phase-validation.sh — constat déterministe du marqueur de phase (Phase 60, ARCG-01, ARCG-02 ;
# P60-D-02, P60-D-03, P60-D-04, P60-PL-01, P60-PL-02). Appelé par vf-coder avant plan et exécution d'une
# étape, et par vf-auto avant sa boucle (P60-D-01) : sans lui, le refus d'une phase proposée serait un vert
# auto-déclaré, porté par la lecture d'un agent.
#
# Rôle : CONSTATER, jamais corriger. LECTURE SEULE, sans exception : aucun fichier créé, modifié ni effacé,
# aucune écriture hors stdout et stderr. Le ROADMAP est écrit par des agents et des humains : NON FIABLE.
# Aucune de ses lignes n'est réimprimée (la sortie entre dans le contexte d'un agent) : seuls sont imprimés
# le numéro de phase déjà validé par motif et des étiquettes fixes. Son contenu n'est jamais évalué (awk seul).
# Le gate ne lit QUE le marqueur, jamais le poste (P60-H-04) : une phase proposée rend 1 quel que soit le
# poste, `solo` compris. Aucune variable d'environnement ni pointeur de compartiment actif n'est lu.
#
# Usage :
#   check-phase-validation.sh --phase <N> [--ws <nom>]
#   check-phase-validation.sh -h | --help
# `--phase` est obligatoire (`--phase=<N>` admis), identifiant `^[A-Za-z0-9][A-Za-z0-9._-]*$` de 64 caractères au plus,
# sans `..` ni point final : la grammaire des phases que sert gsd-core (numéro `12`, décimal `7.1`, suffixe lettre
# `12A`, id custom `AUTH` posé par `phase add --id`, préfixe projet `CK-03`). Comparaison sans casse, zéros de tête
# des segments numériques ôtés (`01.1` = `1.1`, `02` = `2`, `12a` = `12A`) ; forme exacte d'abord (préfixe projet
# conservé), puis, SEULEMENT si aucune section ne porte l'identifiant, forme tolérante au préfixe (`3` désigne
# `CK-03`), comme la lecture de gsd. Lab plat : ROADMAP du dossier de planning du répertoire courant. Lab
# partitionné (le dossier des compartiments existe) : `--ws <nom>` est EXPLICITE et obligatoire, validé par
# vf_ws_name_valid puis résolu par vf_ws_dir_resolve (lien symbolique refusé), jamais déduit. Forme exec :
# l'appelant écrit `bash <chemin résolu> --phase <N> [--ws <nom>]` en arguments séparés, sans `|| true` ni tube
# qui masquerait le code ; le script porte seul la sémantique de son code ; aucun hook (P60-PL-23).
#
# Marqueur (P60-PL-01) : dans la section de la phase, une ligne `**Validation:** <valeur>` (variante
# `**Validation**:` tolérée). Jeton = premier mot en minuscules : `proposed` -> proposée ; `validated` -> validée,
# suffixe `(<poste>, <AAAA-MM-JJ>[, override])` toléré ; tout autre jeton -> INDÉTERMINÉ. Plusieurs lignes de
# marqueur -> INDÉTERMINÉ. Une ligne qui RESSEMBLE à un marqueur sans en avoir la forme (puce, citation, libellé sans gras ou en
# minuscules, espace avant le deux-points, valeur `propos…` ou `valid…`) est un marqueur illisible : INDÉTERMINÉ, jamais « absent ».
# Aucune ligne : phase VALIDÉE (P60-D-02, état de toutes les phases existantes).
# Section : titre `#{2,4} Phase <id>`, tag entre parenthèses toléré, deux-points EXIGÉ (`## Phase 41 — note` n'en
# est pas une), qui se ferme au titre suivant de niveau inférieur ou égal ; blocs de code et commentaires HTML
# ignorés ; deux sections pour le même identifiant -> INDÉTERMINÉ. Les blocs `<details>` exacts (jalons livrés)
# sont cachés comme le fait gsd-core : un `<details open>` reste visible, le premier `</details>` ferme, un
# opener sans fermeture avant le suivant n'ouvre rien ; un bloc dont le `<summary>` porte un marqueur d'activité
# (`in progress`, 🚧, 🔄, ACTIVE, WIP, STARTED : jalon actif que `roadmap get-phase` sert) reste VISIBLE. Barrières de code CommonMark : ouverture = 3 accents graves
# ou tildes ou plus, indentation <= 3 espaces, sans accent grave dans l'info string d'une barrière d'accents
# graves ; fermeture = même caractère, série au moins aussi longue, sans info string.
#
# LIMITE FAIL-OPEN, écrite en clair (P60-D-03 c, P60-H-03) : le mode « Regenerate all » d'`edit-phase`
# reconstruit la section à partir de ses champs et peut PERDRE le marqueur ; la phase redevient alors validée.
# Une phase ajoutée à la main hors de l'équipe n'a pas de marqueur. Le gate ne prétend voir ni l'un ni l'autre.
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0 = validée : marqueur `validated`, ou marqueur absent.
#   1 = proposée : marqueur `proposed`. Ni plan ni exécution de cette phase.
#   3 = INDÉTERMINÉ (marqueur non constatable : ROADMAP absent, phase introuvable, sections ou marqueurs multiples,
#       valeur inconnue ou ligne qui ressemble à un marqueur sans en avoir la forme, bloc de code ou commentaire non
#       fermé, lab partitionné sans --ws, compartiment absent). Jamais un vert à vide. Conduite des consommateurs
#       (vf-coder, vf-auto ; P60-D-15, arbitrage Samuel, AskUserQuestion session principale, 2026-10-29) : SEUL le cas
#       « phase introuvable » laisse continuer, et la ligne BILAN le dit par `marqueur=introuvable` (la phase n'est pas
#       au ROADMAP, sans autre défaut) ; tout autre code 3, le code 64 et le code 5 ARRÊTENT.
#   5 = entrée illisible, BRUYANTE : lien symbolique, non régulier (FIFO, dossier), illisible, taille non
#       numérique, au-delà de 1048576 octets, analyse en échec. Refus AVANT lecture.
#   64 = erreur d'usage (phase absente ou mal formée, nom de compartiment refusé, option inconnue ou sans valeur).
#   Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness.
# Entre plusieurs constats, l'ordre 5 > 1 > 3 > 0 décide.
#
# Sortie : lignes préfixées `[check-phase-validation]` puis une étiquette ASCII fixe :
#   PHASE <N> validee (marqueur absent)     PHASE <N> validee     PHASE <N> proposee
#   INDETERMINE <raison>     ILLISIBLE <entree> : <raison> (aussi sur stderr)
#   BILAN phase=<N> marqueur=<absent|proposed|validated|inconnu|multiple|introuvable|-> code=<rc>
set -uo pipefail
export LC_ALL=C

CPV_MAX_OCTETS=1048576
PHASE=""; WS=""; HAS_WS=0
NL=$'\n'
CR=$(printf '\r')
BOM=$(printf '\357\273\277')
TAG='[check-phase-validation]'

usage_err() { printf '%s %s\n' "$TAG" "$1" >&2; exit 64; }
say() { printf '%s %s\n' "$TAG" "$*"; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --phase)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "--phase nécessite une valeur"
      PHASE=$2; shift 2 ;;
    --phase=*)
      PHASE=${1#--phase=}; [ -n "$PHASE" ] || usage_err "--phase nécessite une valeur"
      shift ;;
    --ws)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "--ws nécessite une valeur"
      WS=$2; HAS_WS=1; shift 2 ;;
    --ws=*)
      WS=${1#--ws=}; [ -n "$WS" ] || usage_err "--ws nécessite une valeur"
      HAS_WS=1; shift ;;
    -h|--help) awk '/^set -uo/{exit} /^# /{sub(/^# /,""); print}' "$0"; exit 0 ;;
    *) usage_err "argument inconnu (usage : --phase <N> [--ws <nom>])" ;;
  esac
done
[ -n "$PHASE" ] || usage_err "--phase est obligatoire (usage : --phase <N> [--ws <nom>])"
case "$PHASE" in
  *[!A-Za-z0-9._-]*|[!A-Za-z0-9]*|*.|*..*) usage_err "--phase : identifiant attendu (ex. 60, 41.1, 12A, AUTH, CK-03)" ;;
esac
[ "${#PHASE}" -le 64 ] || usage_err "--phase : identifiant trop long"

# --- Programme awk : une ligne rendue, `@ sections marqueurs classe code_ouvert commentaire_ouvert`.
read -r -d '' AWK_PROG <<'AWKEOF'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
# Clé d'identifiant de phase (grammaire de gsd-core : jeton numérique à suffixe lettre, id custom, préfixe projet) :
# majuscules, zéros de tête de chaque segment numérique retirés (`01.1` = `1.1`, `02a` = `2A`).
function idnorm(s,   n, p, i, o, seg, d) {
  n = split(s, p, ".")
  for (i = 1; i <= n; i++) {
    seg = p[i]
    if (match(seg, /^[0-9]+/)) { d = substr(seg, 1, RLENGTH); seg = substr(seg, RLENGTH + 1); sub(/^0+/, "", d); if (d == "") d = "0"; seg = d seg }
    o = o (i > 1 ? "." : "") seg
  }
  return o
}
# Forme stricte (préfixe projet `CK-` conservé) puis forme tolérante (préfixe ôté : `3` désigne `CK-03`).
function idkey(s, loose,   u) {
  u = toupper(s)
  if (match(u, /^[A-Z][A-Z0-9_]*-[0-9]/)) return (loose ? "" : substr(u, 1, RLENGTH - 1)) idnorm(substr(u, RLENGTH))
  return idnorm(u)
}
# Niveau du titre Markdown (nombre de #, 1 à 6) si la ligne en est un, sinon 0.
function hlevel(s,   n) {
  n = 0
  while (substr(s, n + 1, 1) == "#") n++
  if (n < 1 || n > 6) return 0
  if (substr(s, n + 1, 1) !~ /^[ \t]$/) return 0
  return n
}
# Identifiant brut si le titre est `Phase <id>[ (tag)] :` de niveau 2 à 4, sinon "".
function secid(s, lvl,   h, r) {
  if (lvl < 2 || lvl > 4) return ""
  h = trim(substr(s, lvl + 1))
  if (!match(h, /^Phase[ \t]+[A-Za-z0-9][A-Za-z0-9_-]*(\.[A-Za-z0-9_-]+)*/)) return ""
  r = substr(h, RLENGTH + 1); h = substr(h, 1, RLENGTH)
  sub(/^Phase[ \t]+/, "", h)
  if (match(r, /^[ \t]*\([^)]*\)/)) r = substr(r, RLENGTH + 1)
  if (r !~ /^[ \t]*:/) return ""
  return h
}
# Barrière de bloc de code (CommonMark) : retour = longueur de la série (>= 3) si la ligne ouvre une barrière, sinon 0 ;
# fixe fch. Indentation <= 3 espaces (une tabulation en vaut 4), série d'accents graves ou de tildes, accent grave
# interdit dans l'info string d'une barrière d'accents graves.
function fopen(s,   i, c, n) {
  match(s, /^ */); i = RLENGTH
  if (i > 3) return 0
  c = substr(s, i + 1, 1)
  if (c != "`" && c != "~") return 0
  n = 0
  while (substr(s, i + n + 1, 1) == c) n++
  if (n < 3) return 0
  if (c == "`" && index(substr(s, i + n + 1), "`")) return 0
  fch = c
  return n
}
# Fermeture : même caractère, série au moins aussi longue que l'ouvreur, aucune info string.
function fclose(s,   i, n) {
  match(s, /^ */); i = RLENGTH
  if (i > 3 || substr(s, i + 1, 1) != fch) return 0
  n = 0
  while (substr(s, i + n + 1, 1) == fch) n++
  if (n < flen) return 0
  return (substr(s, i + n + 1) ~ /^[ \t]*$/)
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
# Jalon ACTIF (le bloc que gsd-core sert) : un bloc `<details>` dont le `<summary>` porte un marqueur d'activité
# (STARTED, ACTIVE, WIP, `in progress`, 🚧, 🔄 : MILESTONE_ACTIVE_MARKER_PATTERN de gsd-core) reste visible. gsd-core ne
# le cache que par `stripShippedMilestones`, mais `roadmap get-phase` cherche d'abord dans la fenêtre du jalon courant
# (`extractCurrentMilestone`), qui garde ce bloc quand le jalon est résolu (STATE.md ou puce 🚧 du ROADMAP). Le gate ne
# lit pas STATE.md : il sur-approxime (surensemble) — un bloc actif que gsd cacherait faute de jalon résolu est lu, et une
# phase `proposed` y rend 1 (refus sûr) plutôt que 3 (non constatable, la boucle continue). Un `<summary>` sans marqueur
# d'activité reste caché (README conductor, limite des `<details>`), tout comme un bloc ouvert et fermé sur une même ligne
# (rien n'y est lisible en début de ligne). Texte du bloc : de l'opener jusqu'au `</details>`.
function active_block(rl, w, b,   t, k, s) {
  t = ""
  for (k = 1; k <= pq_n; k++) t = t pq_not[k] "\n"
  t = t substr(rl, 1, length(rl) - length(w) + b - 1)
  t = tolower(t)
  if (!match(t, /<summary[^>]*>[^<]*<\/summary>/)) return 0
  s = substr(t, RSTART, RLENGTH); sub(/^<summary[^>]*>/, "", s); sub(/<\/summary>$/, "", s)
  if (match(s, /(^|[^a-z0-9_])(started|active|wip)([^a-z0-9_]|$)/)) return 1
  if (s ~ /in[ \t\n]+progress/) return 1
  return (index(s, "🚧") > 0 || index(s, "🔄") > 0)
}
# Blocs `<details>` exacts (jalons livrés) : cachés comme le fait gsd-core (`stripShippedMilestones`), opener `<details>`
# sans attribut, casse indifférente, le premier `</details>` ferme, pas d'imbrication, un opener sans fermeture avant le
# suivant (ou la fin) n'ouvre rien. La décision d'une ligne peut dépendre des suivantes : les lignes en suspens sont
# retenues (pq_*) puis rendues à proc() dans l'ordre, cachées (vides) ou telles quelles ; les numéros de ligne sont conservés.
function feed(rl, i,   w, tw, vis, a, b, c, inq, k, full) {
  w = rl; tw = tolower(rl); vis = ""; inq = 0
  while (1) {
    if (!pend) {
      a = index(tw, "<details>")
      if (!a) { vis = vis w; break }
      pend = 1; pq_n = 1; pq_i[1] = i; pq_blk[1] = vis substr(w, 1, a - 1); pq_not[1] = vis w; inq = 1
      w = substr(w, a + 9); tw = substr(tw, a + 9); vis = ""
      continue
    }
    c = index(tw, "<details>"); b = index(tw, "</details>")
    if (b && (!c || b < c)) {
      if (!inq && active_block(rl, w, b)) {
        flush_pending()
        vis = substr(rl, 1, length(rl) - length(w) + b - 1)
      } else {
        for (k = 1; k <= pq_n - inq; k++) proc(pq_blk[k], pq_i[k])
        vis = inq ? pq_blk[pq_n] : ""
      }
      pend = 0; pq_n = 0; inq = 0
      w = substr(w, b + 10); tw = substr(tw, b + 10)
      continue
    }
    if (c) {
      for (k = 1; k <= pq_n - inq; k++) proc(pq_not[k], pq_i[k])
      if (inq) { full = pq_not[pq_n]; vis = substr(full, 1, length(full) - length(w) + c - 1) }
      else vis = substr(rl, 1, length(rl) - length(w) + c - 1)
      pend = 0; pq_n = 0; inq = 0
      w = substr(w, c); tw = substr(tw, c)
      continue
    }
    if (!inq) { pq_n++; pq_i[pq_n] = i; pq_blk[pq_n] = ""; pq_not[pq_n] = rl }
    break
  }
  if (!pend) proc(vis, i)
}
function flush_pending(   k) {
  if (!pend) return
  for (k = 1; k <= pq_n; k++) proc(pq_not[k], pq_i[k])
  pend = 0; pq_n = 0
}
BEGIN { wk[1] = idkey(want, 0); wk[2] = idkey(want, 1) }
# Ligne qui RESSEMBLE à un marqueur sans en avoir la forme exacte (Phase 60, correction de revue, P60-H-04) : puce, citation,
# libellé sans gras, en italique, en minuscules, espace avant le deux-points, suivi d'une valeur qui commence par
# `propos` ou `valid`. Lue « absent », elle ferait passer une phase proposée (fail-open) ; elle est donc un marqueur
# ILLISIBLE (arrêt des consommateurs), jamais une validation. N'est appelée que si la forme exacte n'a pas reconnu la ligne.
function loosemark(s,   t, w) {
  t = s
  while (1) {
    sub(/^[ \t]+/, "", t)
    if (substr(t, 1, 1) == ">") { t = substr(t, 2); continue }
    if (match(t, /^([-*+]|[0-9]+[.)])[ \t]+/)) { t = substr(t, RLENGTH + 1); continue }
    if (match(t, /^\[[ xX]\][ \t]+/)) { t = substr(t, RLENGTH + 1); continue }
    break
  }
  sub(/^[*_]+/, "", t)
  if (tolower(substr(t, 1, 10)) != "validation") return 0
  t = substr(t, 11)
  sub(/^[*_]*[ \t]*/, "", t)
  if (substr(t, 1, 1) != ":") return 0
  t = substr(t, 2)
  sub(/^[ \t*_`"']+/, "", t)
  w = tolower(substr(t, 1, 5))
  return (w == "propo" || w == "valid")
}
# Une ligne, déjà débarrassée des blocs <details> : sections, marqueurs, blocs de code, commentaires. Deux lectures de la
# cible en parallèle : (1) exacte, (2) tolérante au préfixe projet ; (2) ne sert que si (1) ne trouve aucune section.
function proc(line, nr,   t, lvl, id, p, v, tok, rest, c) {
  if (!infence) line = strip_comments(line)
  if (infence) { if (fclose(line)) infence = 0; return }
  c = fopen(line)
  if (c) { infence = 1; flen = c; return }
  lvl = hlevel(line)
  if (lvl) {
    id = secid(line, lvl)
    for (p = 1; p <= 2; p++) {
      if (insec[p] && lvl <= seclvl[p]) insec[p] = 0
      if (id != "" && idkey(id, p == 2) == wk[p]) { nsec[p]++; insec[p] = 1; seclvl[p] = lvl }
    }
    return
  }
  if (match(line, /^[ \t]*\*\*Validation(:\*\*|\*\*[ \t]*:)/)) {
    v = trim(substr(line, RLENGTH + 1)); tok = v; sub(/[ \t].*$/, "", tok)
    rest = substr(v, length(tok) + 1); sub(/^[ \t]+/, "", rest); tok = tolower(tok)
    if (tok == "proposed") c = "proposed"
    else if (tok == "validated" && (rest == "" || substr(rest, 1, 1) == "(")) c = "validated"
    else c = "inconnu"
    for (p = 1; p <= 2; p++) if (insec[p]) { nmark[p]++; if (nmark[p] == 1) cls[p] = c }
  } else if (loosemark(line)) {
    for (p = 1; p <= 2; p++) if (insec[p]) { nmark[p]++; if (nmark[p] == 1) cls[p] = "inconnu" }
  }
}
{
  line = $0
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
  feed(line, NR)
}
END {
  flush_pending()
  p = (nsec[1] > 0) ? 1 : 2
  printf "@ %d %d %s %d %d\n", nsec[p] + 0, nmark[p] + 0, (cls[p] == "" ? "-" : cls[p]), infence + 0, incom + 0
}
AWKEOF

WORST=0; MARK="-"
bump() { # <code> : ordre 5 > 1 > 3 > 0
  case "$1" in
    5) WORST=5 ;;
    1) if [ "$WORST" -ne 5 ]; then WORST=1; fi ;;
    3) if [ "$WORST" -eq 0 ]; then WORST=3; fi ;;
  esac
}
illisible() { # <entree> <raison>
  say "ILLISIBLE $1 : $2"; printf '%s ILLISIBLE %s : %s\n' "$TAG" "$1" "$2" >&2; bump 5
}
indetermine() { say "INDETERMINE $1"; bump 3; }

PLAN=".planning"
ROADMAP="$PLAN/ROADMAP.md"
# Règles de nom et de résolution du compartiment : sourcées seulement quand --ws est donné (`$HERE` d'abord, copie
# à plat par l'engine, puis le module voisin dans l'arbre du dépôt).
POLICY_OK=0
if [ "$HAS_WS" -eq 1 ]; then
  HERE="$(cd "$(dirname "$0")" && pwd)"
  for _cand in "$HERE/workstream-policy.sh" "$HERE/../../planning-core/scripts/workstream-policy.sh"; do
    if [ -f "$_cand" ]; then
      # shellcheck source=/dev/null
      . "$_cand"; POLICY_OK=1; break
    fi
  done
fi
# Cible : la valeur de --ws seule, jamais un canal implicite. Rend 0 si ROADMAP résolu, sinon 3 ou 5 (déjà signalé).
resolve() {
  local rc
  if [ "$HAS_WS" -eq 1 ]; then
    if [ "$POLICY_OK" -ne 1 ]; then indetermine "politique de compartiment introuvable"; return 3; fi
    vf_ws_name_valid "$WS" || usage_err "--ws : nom de compartiment refusé par la politique"
    vf_ws_dir_resolve "$PLAN" "$WS"; rc=$?
    case "$rc" in
      0) ROADMAP="$VF_WS_DIR/ROADMAP.md"; return 0 ;;
      1) indetermine "compartiment absent"; return 3 ;;
      *) illisible compartiment "${VF_WS_REASON:-refus}"; return 5 ;;
    esac
  fi
  if [ -e "$PLAN/workstreams" ] || [ -L "$PLAN/workstreams" ]; then indetermine "lab partitionne sans --ws"; return 3; fi
  return 0
}

# Contrôle d'entrée AVANT toute lecture ; rend 0 si lisible, sinon 3 ou 5 (déjà signalé, jamais le contenu).
guard() { # <chemin>
  local f=$1 size
  if [ ! -e "$f" ] && [ ! -L "$f" ]; then indetermine "roadmap absent"; return 3; fi
  if [ -L "$f" ]; then illisible roadmap "lien symbolique"; return 5; fi
  if [ ! -f "$f" ]; then illisible roadmap "fichier non regulier"; return 5; fi
  if [ ! -r "$f" ]; then illisible roadmap "fichier illisible"; return 5; fi
  size=$(wc -c < "$f" 2>/dev/null | tr -d ' \t')
  case "$size" in ''|*[!0-9]*) illisible roadmap "taille non numerique"; return 5 ;; esac
  if [ "$size" -gt "$CPV_MAX_OCTETS" ]; then illisible roadmap "au-dela de la borne de taille"; return 5; fi
  return 0
}

if resolve; then guard "$ROADMAP"; fi

if [ "$WORST" -eq 0 ]; then
  OUT_TXT=$(sed "s/$CR\$//" "$ROADMAP" | tr '\r' '\n' | awk -v bom="$BOM" -v want="$PHASE" "$AWK_PROG"); arc=$?
  case "$OUT_TXT" in "@ "*) : ;; *) arc=1 ;; esac
  if [ "$arc" -ne 0 ]; then
    illisible roadmap "analyse en echec"
  else
    set -- $OUT_TXT
    NSEC=$2; NMARK=$3; CLS=$4; NFENCE=$5; NCOM=$6
    if [ "$NFENCE" -ne 0 ]; then indetermine "bloc de code non ferme"; fi
    if [ "$NCOM" -ne 0 ]; then indetermine "commentaire HTML non ferme"; fi
    if [ "$NSEC" -eq 0 ]; then
      # Seul constat « sans autre défaut » : la phase n'est pas au ROADMAP (P60-D-15). Avec un bloc ou un commentaire
      # non fermé, la phase a pu être avalée : le BILAN ne dit alors pas `introuvable`, les consommateurs s'arrêtent.
      if [ "$WORST" -eq 0 ]; then MARK=introuvable; fi
      indetermine "phase introuvable"
    elif [ "$NSEC" -gt 1 ]; then indetermine "sections multiples"
    elif [ "$NMARK" -eq 0 ]; then
      MARK=absent; if [ "$WORST" -eq 0 ]; then say "PHASE $PHASE validee (marqueur absent)"; fi
    elif [ "$NMARK" -gt 1 ]; then MARK=multiple; indetermine "marqueurs multiples"
    else
      case "$CLS" in
        proposed) MARK=proposed; say "PHASE $PHASE proposee"; bump 1 ;;
        validated) MARK=validated; if [ "$WORST" -eq 0 ]; then say "PHASE $PHASE validee"; fi ;;
        *) MARK=inconnu; indetermine "valeur de marqueur inconnue" ;;
      esac
    fi
  fi
fi

say "BILAN phase=${PHASE} marqueur=${MARK} code=${WORST}"
exit "$WORST"
