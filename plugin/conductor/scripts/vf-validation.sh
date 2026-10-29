#!/usr/bin/env bash
# vf-validation.sh — SEUL écrivain de la ligne `**Validation:**` (Phase 60, ARCG-01, ARCG-06, ARCG-09 ;
# P60-D-05, P60-D-10, P60-H-02, P60-H-03, P60-PL-05, P60-PL-06, P60-PL-07). Le geste de validation d'un dev est un
# VERBE DE SCRIPT, jamais un skill. `propose` pose « proposed » à la création d'une phase (déclenché par la doctrine
# et le champ du brief de mission, P60-H-03) ; `validate` la bascule en « validated » (un dev valide, P60-H-02).
# Lu par `check-phase-validation.sh` et `check-architecture.sh`, dont la grammaire est reprise À L'IDENTIQUE (P60-PL-01).
#
# Usage :
#   vf-validation.sh propose  --phase <N> [--ws <nom>]
#   vf-validation.sh validate --phase <N> [--ws <nom>] [--override]
#   vf-validation.sh validate --architecture <f> [--override]
#   vf-validation.sh -h | --help
# `--x=<v>` admis. Exactement UNE cible. `--phase` : numéro `^[0-9]+(\.[0-9]+)*$`. Lab plat : ROADMAP du dossier de
# planning du répertoire courant ; lab partitionné : `--ws <nom>` EXPLICITE et obligatoire (vf_ws_name_valid puis
# vf_ws_dir_resolve, lien refusé), jamais déduit du compartiment actif. `--override` : `validate` seulement.
#
# Règles : `propose` insère `**Validation:** proposed` APRÈS le paragraphe `**Goal:**` de la section (la ligne Goal et
# ses lignes de suite, jusqu'à une ligne blanche, une ligne qui commence par `**` ou un titre). `validate` remplace
# la ligne `proposed` par `validated (<poste>, <AAAA-MM-JJ>)`. Poste lu par `vf-role.sh get` (voisin), SEULEMENT par
# `validate` : `dev` ou `solo` écrit ; `product` refuse (code 1) sauf `--override`, tracé dans la valeur
# (`validated (product, <date>, override)`) ; poste illisible (codes 1, 5, 64 du lecteur, lecteur absent) -> 5, jamais
# un repli sur `solo`. Un poste est une vue, pas un droit (ADR-077) : un humain peut toujours éditer la ligne à la main.
# Jamais dégradé : `propose` sur une phase `validated` -> 3 ; `propose` sur `proposed` et `validate` sur `validated`
# ou sur marqueur absent -> 0 sans écriture. Valeur inconnue, marqueurs multiples, phase introuvable ou multiple,
# section sans Goal, bloc de code ou commentaire HTML non fermé -> 3 sans écriture. Entrée non fiable (lien, non régulier,
# illisible, > 1048576 octets, CR isolé) -> 5 sans écriture. Les fichiers sont NON FIABLES : leur contenu n'est jamais
# réimprimé (seuls le numéro de phase validé et des étiquettes fixes le sont) ni évalué (awk seul).
# Écriture : UNE ligne changée, toutes les autres identiques à l'octet (fins de ligne CR/LF reprises de la voisine),
# `cp -p` vers un temporaire du même dossier (mode conservé), `mv -f` ; échec -> cible intacte, 5.
#
# NE FAIT PAS : aucun commit, aucun verrou de driver. À lancer hors mission, ou par le manager qui tient le verrou du
# compartiment : valider pendant qu'une mission d'autrui le tient est un geste à éviter (Pitfall 13).
# LIMITE FAIL-OPEN (P60-D-03 c) : « Regenerate all » d'`edit-phase` peut PERDRE le marqueur, une phase ajoutée à la main
# n'en a pas : l'absence vaut validée. Forme exec : `bash <chemin résolu> <verbe> ...` en arguments séparés, sans
# `|| true` ni tube masquant le code, aucun hook (P60-PL-23).
#
# Codes (aucun implicite) :
#   0 = écrit, ou déjà dans l'état visé (INCHANGE).
#   1 = refus de poste : `validate` au poste product sans --override.
#   3 = cible introuvable ou état incompatible (INDETERMINE), sans écriture.
#   5 = entrée illisible ou poste illisible (ILLISIBLE, aussi stderr), sans écriture.
#   64 = erreur d'usage.
#   Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness.
# Sortie (préfixe `[vf-validation]`) : ECRIT phase <N> : proposed | ECRIT phase <N> : validated (<poste>, <date>[, override])
#   | ECRIT architecture : validated (...) | INCHANGE <cible> : <raison> | REFUS poste product : ... | INDETERMINE <raison>
#   | ILLISIBLE <raison> ; dernière ligne `BILAN verbe=<propose|validate> cible=<phase-N|architecture> ecrit=<0|1> code=<rc>`.
set -uo pipefail
export LC_ALL=C

VF_MAX_OCTETS=1048576
VERB=""; PHASE=""; WS=""; HAS_WS=0; ARCH=""; OVERRIDE=0; WROTE=0; TGT="-"; OUTF=""; ST=""; NEWF=""
BOM=$(printf '\357\273\277')
TAG='[vf-validation]'
HERE="$(cd "$(dirname "$0")" && pwd)"
trap 'rm -f "$OUTF" "$ST" "$NEWF"' EXIT

usage_err() { printf '%s %s\n' "$TAG" "$1" >&2; exit 64; }
say() { printf '%s %s\n' "$TAG" "$*"; }
finish() { say "BILAN verbe=${VERB} cible=${TGT} ecrit=${WROTE} code=$1"; exit "$1"; }
indet() { say "INDETERMINE $1"; finish 3; }
illis() { say "ILLISIBLE $1"; printf '%s ILLISIBLE %s\n' "$TAG" "$1" >&2; finish 5; }
help_() { awk '/^set -uo/{exit} /^# /{sub(/^# /,""); print}' "$0"; exit 0; }

case "${1-}" in
  -h|--help) help_ ;;
  propose|validate) VERB=$1; shift ;;
  *) usage_err "verbe attendu : propose | validate (usage : voir --help)" ;;
esac
while [ "$#" -gt 0 ]; do
  case "$1" in
    --phase|--ws|--architecture)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "$1 nécessite une valeur"
      set -- "$1=$2" "${@:3}" ;;
    --phase=*) [ -z "$PHASE" ] || usage_err "--phase donné deux fois"; PHASE=${1#--phase=}; [ -n "$PHASE" ] || usage_err "--phase nécessite une valeur"; shift ;;
    --ws=*) [ "$HAS_WS" -eq 0 ] || usage_err "--ws donné deux fois"; WS=${1#--ws=}; HAS_WS=1; [ -n "$WS" ] || usage_err "--ws nécessite une valeur"; shift ;;
    --architecture=*) [ -z "$ARCH" ] || usage_err "--architecture donné deux fois"; ARCH=${1#--architecture=}; [ -n "$ARCH" ] || usage_err "--architecture nécessite une valeur"; shift ;;
    --override) OVERRIDE=1; shift ;;
    -h|--help) help_ ;;
    *) usage_err "argument inconnu (usage : voir --help)" ;;
  esac
done
if [ -n "$PHASE" ] && [ -n "$ARCH" ]; then usage_err "--phase et --architecture ensemble : une seule cible"; fi
if [ -z "$PHASE" ] && [ -z "$ARCH" ]; then usage_err "une cible est obligatoire (--phase <N> ou --architecture <f>)"; fi
if [ -n "$ARCH" ] && [ "$VERB" = propose ]; then usage_err "propose ne vaut que pour --phase"; fi
if [ -n "$ARCH" ] && [ "$HAS_WS" -eq 1 ]; then usage_err "--ws ne vaut que pour --phase"; fi
if [ "$OVERRIDE" -eq 1 ] && [ "$VERB" = propose ]; then usage_err "--override ne vaut que pour validate"; fi
if [ -n "$PHASE" ]; then
  case "$PHASE" in *[!0-9.]*|.*|*.|*..*) usage_err "--phase : numéro attendu (ex. 60 ou 41.1)" ;; esac
  MODE=phase; ENT=roadmap; TGT="phase-$PHASE"; CIBLE="phase $PHASE"
else
  MODE=arch; ENT=architecture; TGT=architecture; CIBLE=architecture
fi

# --- Poste (validate seulement) : lecteur voisin, codes 1/5/64 -> 5, jamais un repli sur solo.
ROLE=""; VAL="proposed"
if [ "$VERB" = validate ]; then
  ROLE=$("$HERE/vf-role.sh" get 2>/dev/null); rrc=$?
  if [ "$rrc" -ne 0 ]; then illis "poste illisible (vf-role.sh code $rrc) : aucune ecriture, jamais un repli sur solo"; fi
  case "$ROLE" in solo|dev) VAL="validated ($ROLE, $(date +%Y-%m-%d))" ;;
    product)
      if [ "$OVERRIDE" -ne 1 ]; then
        say "REFUS poste product : la validation appartient a un poste dev (--override pour passer outre, trace)"; finish 1
      fi
      VAL="validated (product, $(date +%Y-%m-%d), override)" ;;
    *) illis "poste illisible (valeur hors ensemble) : aucune ecriture" ;;
  esac
fi

# --- Cible : ROADMAP du compartiment NOMMÉ (comme le gate), ou le fichier d'architecture donné.
PLAN=".planning"; F="$ARCH"
if [ "$MODE" = phase ]; then
  F="$PLAN/ROADMAP.md"
  if [ "$HAS_WS" -eq 1 ]; then
    POLICY_OK=0
    for _cand in "$HERE/workstream-policy.sh" "$HERE/../../planning-core/scripts/workstream-policy.sh"; do
      if [ -f "$_cand" ]; then
        # shellcheck source=/dev/null
        . "$_cand"; POLICY_OK=1; break
      fi
    done
    if [ "$POLICY_OK" -ne 1 ]; then indet "politique de compartiment introuvable"; fi
    vf_ws_name_valid "$WS" || usage_err "--ws : nom de compartiment refusé par la politique"
    vf_ws_dir_resolve "$PLAN" "$WS"; wrc=$?
    case "$wrc" in
      0) F="$VF_WS_DIR/ROADMAP.md" ;;
      1) indet "compartiment absent" ;;
      *) illis "compartiment : ${VF_WS_REASON:-refus}" ;;
    esac
  elif [ -e "$PLAN/workstreams" ] || [ -L "$PLAN/workstreams" ]; then indet "lab partitionne sans --ws"; fi
fi
# Contrôle d'entrée AVANT toute lecture ; jamais le contenu imprimé.
if [ ! -e "$F" ] && [ ! -L "$F" ]; then indet "$ENT absent"; fi
if [ -L "$F" ]; then illis "$ENT : lien symbolique"; fi
if [ ! -f "$F" ]; then illis "$ENT : fichier non regulier"; fi
if [ ! -r "$F" ]; then illis "$ENT : fichier illisible"; fi
SIZE=$(wc -c < "$F" 2>/dev/null | tr -d ' \t')
case "$SIZE" in ''|*[!0-9]*) illis "$ENT : taille non numerique" ;; esac
if [ "$SIZE" -gt "$VF_MAX_OCTETS" ]; then illis "$ENT : au-dela de la borne de taille"; fi

# --- Programme awk : réécrit le fichier vers stdout en ne touchant qu'UNE ligne ; le constat va dans le fichier `st`
# (`@ sections marqueurs classe code_ouvert commentaire_ouvert fin_goal cr_isole action`). Sections, blocs de code et
# commentaires : celles des deux gates, à l'identique.
read -r -d '' AWK_PROG <<'AWKEOF'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function normnum(s,   n, p, i, o) {
  n = split(s, p, ".")
  for (i = 1; i <= n; i++) { sub(/^0+/, "", p[i]); if (p[i] == "") p[i] = "0"; o = o (i > 1 ? "." : "") p[i] }
  return o
}
function hlevel(s,   n) {
  n = 0
  while (substr(s, n + 1, 1) == "#") n++
  if (n < 1 || n > 6) return 0
  if (substr(s, n + 1, 1) !~ /^[ \t]$/) return 0
  return n
}
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
BEGIN { want = normnum(want); if (mode == "arch") { insec = 1; nsec = 1 } }
{
  raw[NR] = $0; n = NR; line = $0
  cr[NR] = (substr(line, length(line), 1) == "\r") ? "\r" : ""
  if (cr[NR] != "") line = substr(line, 1, length(line) - 1)
  if (index(line, "\r")) lonecr++
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
  if (!infence) line = strip_comments(line)
  t = line; sub(/^[ \t]+/, "", t); f3 = substr(t, 1, 3)
  if (infence) { if (f3 == fch) infence = 0; next }
  if (f3 == "```" || f3 == "~~~") { infence = 1; fch = f3; ingoal = 0; next }
  lvl = hlevel(line)
  if (lvl) {
    ingoal = 0
    if (mode == "phase") {
      if (insec && lvl <= seclvl) insec = 0
      k = secnum(line, lvl)
      if (k != "" && k == want) { nsec++; insec = 1; seclvl = lvl }
    }
    next
  }
  if (!insec) next
  if (match(line, /^[ \t]*\*\*Validation(:\*\*|\*\*[ \t]*:)/)) {
    ingoal = 0; nmark++
    if (nmark == 1) {
      mline = NR; ml = RLENGTH; match(raw[NR], /^[ \t]*/); lead = substr(raw[NR], 1, RLENGTH)
      v = trim(substr(line, ml + 1)); tok = v; sub(/[ \t].*$/, "", tok)
      rest = substr(v, length(tok) + 1); sub(/^[ \t]+/, "", rest); tok = tolower(tok)
      if (tok == "proposed") cls = "proposed"
      else if (tok == "validated" && (rest == "" || substr(rest, 1, 1) == "(")) cls = "validated"
      else cls = "inconnu"
    }
    next
  }
  if (ingoal) { if (t == "" || substr(t, 1, 2) == "**") ingoal = 0; else goalend = NR; next }
  if (mode == "phase" && !goaldone && match(line, /^[ \t]*\*\*Goal(:\*\*|\*\*[ \t]*:)/)) { ingoal = 1; goaldone = 1; goalend = NR }
}
END {
  act = "none"
  if (nsec == 1 && !infence && !incom && !lonecr && nmark <= 1 && (nmark == 0 || cls == "proposed" || cls == "validated")) {
    if (verb == "propose" && nmark == 0 && goalend > 0) act = "insert"
    if (verb == "validate" && nmark == 1 && cls == "proposed") act = "replace"
  }
  m = 0
  for (i = 1; i <= n; i++) {
    if (act == "replace" && i == mline) out[++m] = lead "**Validation:** " val cr[i]
    else out[++m] = raw[i]
    if (act == "insert" && i == goalend) out[++m] = "**Validation:** " val cr[i]
  }
  for (i = 1; i <= m; i++) { printf "%s", out[i]; if (i < m || !noeol) printf "\n" }
  printf "@ %d %d %s %d %d %d %d %s\n", nsec + 0, nmark + 0, (cls == "" ? "-" : cls), infence + 0, incom + 0, goalend + 0, lonecr + 0, act > st
  close(st)
}
AWKEOF

OUTF=$(mktemp) && ST=$(mktemp) || illis "$ENT : fichier temporaire impossible"
NOEOL=0
if [ "$SIZE" -gt 0 ] && [ "$(tail -c 1 "$F" | od -An -tx1 | tr -d ' \n')" != "0a" ]; then NOEOL=1; fi
awk -v bom="$BOM" -v want="$PHASE" -v mode="$MODE" -v verb="$VERB" -v val="$VAL" -v noeol="$NOEOL" -v st="$ST" "$AWK_PROG" "$F" > "$OUTF" 2>/dev/null
arc=$?
read -r mk nsec nmark cls infence incom goalend lonecr act < "$ST" || mk=""
if [ "$arc" -ne 0 ] || [ "$mk" != "@" ]; then illis "$ENT : analyse en echec"; fi

if [ "$lonecr" -ne 0 ]; then illis "$ENT : fin de ligne CR isole (refus, jamais reecrit)"; fi
if [ "$infence" -ne 0 ]; then indet "bloc de code non ferme"; fi
if [ "$incom" -ne 0 ]; then indet "commentaire HTML non ferme"; fi
if [ "$nsec" -eq 0 ]; then indet "phase introuvable"; fi
if [ "$nsec" -gt 1 ]; then indet "sections multiples"; fi
if [ "$nmark" -gt 1 ]; then indet "marqueurs multiples"; fi
if [ "$MODE" = arch ] && [ "$nmark" -eq 0 ]; then indet "ligne d'etat absente"; fi
if [ "$nmark" -eq 1 ] && [ "$cls" = inconnu ]; then indet "valeur de marqueur inconnue"; fi
case "$VERB:$nmark:$cls" in
  propose:0:*) if [ "$goalend" -eq 0 ]; then indet "section sans Goal"; fi ;;
  propose:1:proposed) say "INCHANGE $CIBLE : deja proposee"; finish 0 ;;
  propose:1:validated) indet "deja validee : jamais repassee a proposed" ;;
  validate:0:*) say "INCHANGE $CIBLE : deja validee (marqueur absent)"; finish 0 ;;
  validate:1:validated) say "INCHANGE $CIBLE : deja validee"; finish 0 ;;
esac
if [ "$act" = none ]; then illis "$ENT : analyse incoherente"; fi

# --- Écriture atomique : temporaire du même dossier (mode conservé par cp -p), puis renommage.
NEWF=$(mktemp "$(dirname "$F")/.vf-validation.XXXXXX") || illis "$ENT : ecriture impossible (dossier)"
if ! cp -p "$F" "$NEWF" 2>/dev/null || ! cat "$OUTF" > "$NEWF" 2>/dev/null || ! mv -f "$NEWF" "$F" 2>/dev/null; then
  illis "$ENT : ecriture impossible (cible intacte)"
fi
WROTE=1
say "ECRIT $CIBLE : $VAL"
finish 0
