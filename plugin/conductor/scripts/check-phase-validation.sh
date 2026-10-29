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
# `--phase` est obligatoire (`--phase=<N>` admis), numéro `^[0-9]+(\.[0-9]+)*$`, segments comparés sans zéros
# de tête (`01.1` = `1.1`, `02` = `2`). Lab plat : ROADMAP du dossier de planning du répertoire courant. Lab
# partitionné (le dossier des compartiments existe) : `--ws <nom>` est EXPLICITE et obligatoire, validé par
# vf_ws_name_valid puis résolu par vf_ws_dir_resolve (lien symbolique refusé), jamais déduit. Forme exec :
# l'appelant écrit `bash <chemin résolu> --phase <N> [--ws <nom>]` en arguments séparés, sans `|| true` ni tube
# qui masquerait le code ; le script porte seul la sémantique de son code ; aucun hook (P60-PL-23).
#
# Marqueur (P60-PL-01) : dans la section de la phase, une ligne `**Validation:** <valeur>` (variante
# `**Validation**:` tolérée). Jeton = premier mot en minuscules : `proposed` -> proposée ; `validated` -> validée,
# suffixe `(<poste>, <AAAA-MM-JJ>[, override])` toléré ; tout autre jeton -> INDÉTERMINÉ. Plusieurs lignes de
# marqueur -> INDÉTERMINÉ. Aucune ligne : phase VALIDÉE (P60-D-02, état de toutes les phases existantes).
# Section : titre `#{2,4} Phase N`, tag entre parenthèses toléré, deux-points EXIGÉ (`## Phase 41 — note` n'en
# est pas une), qui se ferme au titre suivant de niveau inférieur ou égal ; blocs de code et commentaires HTML
# ignorés ; deux sections pour N -> INDÉTERMINÉ.
#
# LIMITE FAIL-OPEN, écrite en clair (P60-D-03 c, P60-H-03) : le mode « Regenerate all » d'`edit-phase`
# reconstruit la section à partir de ses champs et peut PERDRE le marqueur ; la phase redevient alors validée.
# Une phase ajoutée à la main hors de l'équipe n'a pas de marqueur. Le gate ne prétend voir ni l'un ni l'autre.
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0 = validée : marqueur `validated`, ou marqueur absent.
#   1 = proposée : marqueur `proposed`. Ni plan ni exécution de cette phase.
#   3 = INDÉTERMINÉ : ROADMAP absent, phase introuvable, sections ou marqueurs multiples, valeur inconnue, bloc
#       de code ou commentaire non fermé, lab partitionné sans --ws, compartiment absent. Jamais un vert à vide.
#   5 = entrée illisible, BRUYANTE : lien symbolique, non régulier (FIFO, dossier), illisible, taille non
#       numérique, au-delà de 1048576 octets, analyse en échec. Refus AVANT lecture.
#   64 = erreur d'usage (phase absente ou mal formée, nom de compartiment refusé, option inconnue ou sans valeur).
#   Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness.
# Entre plusieurs constats, l'ordre 5 > 1 > 3 > 0 décide.
#
# Sortie : lignes préfixées `[check-phase-validation]` puis une étiquette ASCII fixe :
#   PHASE <N> validee (marqueur absent)     PHASE <N> validee     PHASE <N> proposee
#   INDETERMINE <raison>     ILLISIBLE <entree> : <raison> (aussi sur stderr)
#   BILAN phase=<N> marqueur=<absent|proposed|validated|inconnu|multiple|-> code=<rc>
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
  *[!0-9.]*|.*|*.|*..*) usage_err "--phase : numéro attendu (ex. 60 ou 41.1)" ;;
esac

# --- Programme awk : une ligne rendue, `@ sections marqueurs classe code_ouvert commentaire_ouvert`.
read -r -d '' AWK_PROG <<'AWKEOF'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function normnum(s,   n, p, i, o) {
  n = split(s, p, ".")
  for (i = 1; i <= n; i++) { sub(/^0+/, "", p[i]); if (p[i] == "") p[i] = "0"; o = o (i > 1 ? "." : "") p[i] }
  return o
}
# Niveau du titre Markdown (nombre de #, 1 à 6) si la ligne en est un, sinon 0.
function hlevel(s,   n) {
  n = 0
  while (substr(s, n + 1, 1) == "#") n++
  if (n < 1 || n > 6) return 0
  if (substr(s, n + 1, 1) !~ /^[ \t]$/) return 0
  return n
}
# Numéro normalisé si le titre est `Phase N[ (tag)] :` de niveau 2 à 4, sinon "".
function secnum(s, lvl,   h, r) {
  if (lvl < 2 || lvl > 4) return ""
  h = trim(substr(s, lvl + 1))
  if (!match(h, /^Phase[ \t]+[0-9]+(\.[0-9]+)*/)) return ""
  r = substr(h, RLENGTH + 1); h = substr(h, 1, RLENGTH)
  sub(/^Phase[ \t]+/, "", h)
  if (match(r, /^[ \t]*\([^)]*\)/)) r = substr(r, RLENGTH + 1)
  if (r !~ /^[ \t]*:/) return ""
  return normnum(h)
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
BEGIN { want = normnum(want) }
{
  line = $0
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
  if (!infence) line = strip_comments(line)
  t = line; sub(/^[ \t]+/, "", t); f3 = substr(t, 1, 3)
  if (infence) { if (f3 == fch) infence = 0; next }
  if (f3 == "```" || f3 == "~~~") { infence = 1; fch = f3; next }
  lvl = hlevel(line)
  if (lvl) {
    if (insec && lvl <= seclvl) insec = 0
    n = secnum(line, lvl)
    if (n != "" && n == want) { nsec++; insec = 1; seclvl = lvl }
    next
  }
  if (insec && match(line, /^[ \t]*\*\*Validation(:\*\*|\*\*[ \t]*:)/)) {
    nmark++
    if (nmark == 1) {
      v = trim(substr(line, RLENGTH + 1)); tok = v; sub(/[ \t].*$/, "", tok)
      rest = substr(v, length(tok) + 1); sub(/^[ \t]+/, "", rest); tok = tolower(tok)
      if (tok == "proposed") cls = "proposed"
      else if (tok == "validated" && (rest == "" || substr(rest, 1, 1) == "(")) cls = "validated"
      else cls = "inconnu"
    }
  }
}
END { printf "@ %d %d %s %d %d\n", nsec + 0, nmark + 0, (cls == "" ? "-" : cls), infence + 0, incom + 0 }
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

if resolve && [ ! -e "$ROADMAP" ] && [ ! -L "$ROADMAP" ]; then indetermine "roadmap absent"; fi

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
    if [ "$NSEC" -eq 0 ]; then indetermine "phase introuvable"
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
