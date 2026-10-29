#!/usr/bin/env bash
# vf-validation.sh — SEUL écrivain de la ligne `**Validation:**` (Phase 60, ARCG-01, ARCG-06, ARCG-09 ;
# P60-D-05, P60-D-10, P60-H-02, P60-H-03, P60-PL-05, P60-PL-06, P60-PL-07). Le geste de validation d'un dev est un
# VERBE DE SCRIPT, jamais un skill. `propose` pose « proposed » à la création d'une phase (déclenché par la doctrine
# et le champ du brief de mission, P60-H-03) ; `validate` la bascule en « validated » (un dev valide, P60-H-02).
# Lu par `check-phase-validation.sh` et `check-architecture.sh`, dont la grammaire est reprise À L'IDENTIQUE (P60-PL-01) ; titres de
# phase, sosies du marqueur et refus (64) des formes qui désignent une phase existante sous une autre identité (`60-02`, `60-gate-architecture`,
# `CK-03-auth-flow`, `AUTH-login`, `60_gate` : préfixe d'un titre du ROADMAP suivi de `-`, `_` ou `.`, ou dossier de phase du même nom), après
# normalisation de l'argument (blancs, séparateur final isolé), sont ceux de `check-phase-validation.sh`.
# LIMITES : `check-architecture.sh` rejette une rubrique dont le corps commence par `[` (lien) : faux rouge contournable, documenté, non corrigé ;
# le marqueur n'est jamais commité par ce script, un worktree ne le voit donc pas : inerte tant que l'isolation reste séquentielle (ADR-059).
#
# Usage :
#   vf-validation.sh propose  --phase <N> [--ws <nom>]
#   vf-validation.sh validate --phase <N> [--ws <nom>] [--override]
#   vf-validation.sh validate --architecture <f> [--override]
#   vf-validation.sh -h | --help
# `--x=<v>` admis. Exactement UNE cible. `--phase` : identifiant de la grammaire de gsd-core (`12`, `7.1`, `12A`, `AUTH`, `CK-03` ;
# voir `check-phase-validation.sh`, mêmes règles, sections de jalons livrés `<details>` ignorées, sauf `<summary>` à marqueur d'activité). Lab plat : ROADMAP du dossier de
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
# Bornes (écrivain : il écrit où on le lui dit) : `--architecture` doit se résoudre (dossiers parents en lien
# symbolique résolus) à l'intérieur de la racine, le répertoire courant physique, sinon refus audible (5), jamais
# écrit ; un `.planning` en lien symbolique est refusé (5) comme un compartiment en lien.
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
  # Normalisation AVANT tout refus (identique à check-phase-validation.sh) : blancs de début et de fin ôtés, puis UN séparateur final isolé.
  PHASE=${PHASE#"${PHASE%%[![:space:]]*}"}; PHASE=${PHASE%"${PHASE##*[![:space:]]}"}
  case "$PHASE" in *[./-]) PHASE=${PHASE%?} ;; esac
  [ -n "$PHASE" ] || usage_err "--phase nécessite une valeur"
  case "$PHASE" in *[!A-Za-z0-9._-]*|[!A-Za-z0-9]*|*.|*..*) usage_err "--phase : identifiant attendu (ex. 60, 41.1, 12A, AUTH, CK-03)" ;; esac
  [ "${#PHASE}" -le 64 ] || usage_err "--phase : identifiant trop long"
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
# --architecture écrit où on lui dit : borné à l'intérieur de la racine (le répertoire courant, physique), liens des
# dossiers parents résolus ; un fichier hors racine est refusé AVANT toute lecture, bruyamment (rc 5). Un dossier qui
# n'existe pas laisse passer : le fichier est alors absent (rc 3).
if [ "$MODE" = arch ]; then
  ROOTP=$(pwd -P 2>/dev/null) || illis "architecture : racine illisible"
  DIRP=$(cd "$(dirname -- "$F")" 2>/dev/null && pwd -P) || DIRP=""
  ROOTP=${ROOTP%/}
  if [ -n "$DIRP" ]; then
    case "$DIRP/" in "$ROOTP"/*) : ;; *) illis "architecture : hors de la racine du depot (refus, jamais ecrit)" ;; esac
  fi
else
  if [ -L "$PLAN" ]; then illis "planning : lien symbolique (refus, comme un compartiment en lien)"; fi
fi
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
# (`@ sections marqueurs classe code_ouvert commentaire_ouvert fin_goal cr_isole action alias`). Sections, blocs de code et
# commentaires : celles des deux gates, à l'identique.
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
# Niveau du titre Markdown (nombre de #, 1 à 6) si la ligne en est un, sinon 0. Indentation de 3 espaces au plus (comme gsd-core,
# `^ {0,3}#{2,4}`). L'espace après les # est exigé, SAUF devant un titre de phase (`###Phase 5:`) : gsd-core lit `#{2,4}\s*Phase`.
function hlevel(s,   n, t, i, r) {
  match(s, /^ */); i = RLENGTH
  if (i >= 4) return 0
  t = substr(s, i + 1); n = 0
  while (substr(t, n + 1, 1) == "#") n++
  if (n < 1 || n > 6) return 0
  r = substr(t, n + 1)
  if (r ~ /^[ \t]/) return n
  if (n >= 2 && n <= 4 && phasehead(r)) return n
  return 0
}
# Tête de titre de phase, casse indifférente (gsd-core : drapeau `i`) : tag entre crochets facultatif (`[WIP] Phase`), puis `Phase` et un blanc.
function phasehead(h,   l) {
  l = tolower(h); sub(/^[ \t]+/, "", l)
  if (match(l, /^\[[^]]+\][ \t]*/)) l = substr(l, RLENGTH + 1)
  return (l ~ /^phase[ \t]+/)
}
# Identifiant brut si le titre est `Phase <id>[ (tag)] :` de niveau 2 à 4, sinon "". Même grammaire que gsd-core : `Phase` sans
# casse, tag de jalon entre crochets avant `Phase`, indentation <= 3, aucun espace exigé après les #.
function secid(s, lvl,   h, r) {
  if (lvl < 2 || lvl > 4) return ""
  match(s, /^ */)
  h = trim(substr(s, RLENGTH + lvl + 1))
  if (match(h, /^\[[^]]+\][ \t]*/)) h = substr(h, RLENGTH + 1)
  if (!match(h, /^[Pp][Hh][Aa][Ss][Ee][ \t]+[A-Za-z0-9][A-Za-z0-9_-]*(\.[A-Za-z0-9_-]+)*/)) return ""
  r = substr(h, RLENGTH + 1); h = substr(h, 1, RLENGTH)
  sub(/^[Pp][Hh][Aa][Ss][Ee][ \t]+/, "", h)
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
# lit pas STATE.md : il sur-approxime un cas — un bloc actif que gsd cacherait faute de jalon résolu est lu, et une
# phase `proposed` y rend 1 (refus sûr) plutôt que 3 (non constatable, la boucle continue). Ce n'est PAS un surensemble : un jalon actif replié sans marqueur d'activité, que gsd sert via STATE.md, reste caché ici (limite documentée). Un `<summary>` sans marqueur
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
# Alias à la manière de gsd (Phase 60, correction de revue) : l'argument n'est le titre d'AUCUNE phase, mais il commence par l'identifiant
# d'un titre du ROADMAP lu, suivi d'un séparateur (`-`, `_`, `.`) : nom de dossier (`CK-03-auth-flow`, `AUTH-login`), identifiant de plan
# (`60-02`), forme à suffixe (`60_gate`, `60.gate`). Le plus long préfixe gagne ; un `.` suivi d'un chiffre est une décimale (`60.1`), jamais
# un séparateur. Rend l'identifiant du titre (déjà validé par secid : caractères sûrs), ou "-".
function aliasof(   w, j, ch, cand, i) {
  w = toupper(want)
  for (j = length(w); j >= 2; j--) {
    ch = substr(w, j, 1)
    if (ch != "-" && ch != "_" && ch != ".") continue
    if (ch == "." && substr(w, j + 1, 1) ~ /[0-9]/) continue
    cand = substr(w, 1, j - 1)
    for (i = 1; i <= nid; i++)
      if (idkey(cand, 0) == idkey(ids[i], 0) || idkey(cand, 1) == idkey(ids[i], 1)) return ids[i]
  }
  return "-"
}
BEGIN {
  wk[1] = idkey(want, 0); wk[2] = idkey(want, 1)
  if (mode == "arch") { insec[1] = 1; nsec[1] = 1 }
}
# Ligne qui RESSEMBLE à un marqueur sans en avoir la forme exacte (Phase 60, correction de revue, P60-H-04) : puce, citation,
# libellé sans gras, en italique, en minuscules, espace avant le deux-points, suivi d'une valeur qui commence par
# `propos` ou `valid`. Lue « absent », elle ferait passer une phase proposée (fail-open) ; elle est donc un marqueur
# ILLISIBLE (arrêt des consommateurs), jamais une validation. N'est appelée que si la forme exacte n'a pas reconnu la ligne.
function loosemark(s,   t, w, c) {
  t = s
  while (1) {
    sub(/^[ \t]+/, "", t)
    if (substr(t, 1, 1) == ">" || substr(t, 1, 1) == "|") { t = substr(t, 2); continue }
    if (match(t, /^([-*+]|[0-9]+[.)])[ \t]+/)) { t = substr(t, RLENGTH + 1); continue }
    if (match(t, /^\[[ xX]\][ \t]+/)) { t = substr(t, RLENGTH + 1); continue }
    break
  }
  sub(/^[*_]+/, "", t)
  if (tolower(substr(t, 1, 10)) != "validation") return 0
  t = substr(t, 11)
  t = skipsp(t)  # blancs avant le séparateur
  c = substr(t, 1, 1)
  if (c == ":" || c == "|") t = substr(t, 2)
  else if (substr(t, 1, 3) == "\342\200\224" || substr(t, 1, 3) == "\342\200\223") t = substr(t, 4)
  else return 0
  t = skipsp(t)
  w = tolower(substr(t, 1, 5))
  return (w == "propo" || w == "valid")
}
# Saute les blancs, le gras, les guillemets et les espaces typographiques : insécable U+00A0 (\302\240) et fine insécable U+202F (\342\200\257).
function skipsp(t) {
  while (1) {
    if (substr(t, 1, 2) == "\302\240") { t = substr(t, 3); continue }
    if (substr(t, 1, 3) == "\342\200\257") { t = substr(t, 4); continue }
    if (match(t, /^[ \t*_`"']+/)) { t = substr(t, RLENGTH + 1); continue }
    return t
  }
}
# Une ligne, déjà débarrassée des blocs <details> (les lignes cachées arrivent vides, la sortie reprend raw[]). Deux
# lectures de la cible en parallèle : (1) exacte, (2) tolérante au préfixe projet ; (2) ne sert que si (1) ne trouve rien.
function proc(line, nr,   t, f, lvl, id, p, v, tok, rest, c, isc) {
  if (!infence) line = strip_comments(line)
  t = line; sub(/^[ \t]+/, "", t)
  if (infence) { if (fclose(line)) infence = 0; return }
  c = fopen(line)
  if (c) { infence = 1; flen = c; for (p = 1; p <= 2; p++) ingoal[p] = 0; return }
  lvl = hlevel(line)
  if (lvl) {
    for (p = 1; p <= 2; p++) ingoal[p] = 0
    if (mode == "phase") {
      id = secid(line, lvl)
      if (id != "") ids[++nid] = id
      for (p = 1; p <= 2; p++) {
        if (insec[p] && lvl <= seclvl[p]) insec[p] = 0
        if (id != "" && idkey(id, p == 2) == wk[p]) { nsec[p]++; insec[p] = 1; seclvl[p] = lvl }
      }
    }
    return
  }
  isc = match(line, /^[ \t]*\*\*Validation(:\*\*|\*\*[ \t]*:)/)
  if (isc || loosemark(line)) {
    if (isc) {
      f = RLENGTH
      v = trim(substr(line, f + 1)); tok = v; sub(/[ \t].*$/, "", tok)
      rest = substr(v, length(tok) + 1); sub(/^[ \t]+/, "", rest); tok = tolower(tok)
      if (tok == "proposed") c = "proposed"
      else if (tok == "validated" && (rest == "" || substr(rest, 1, 1) == "(")) c = "validated"
      else c = "inconnu"
    } else c = "inconnu"
    for (p = 1; p <= 2; p++) if (insec[p]) {
      ingoal[p] = 0; nmark[p]++
      if (nmark[p] == 1) {
        mline[p] = nr; match(raw[nr], /^[ \t]*/); lead[p] = substr(raw[nr], 1, RLENGTH); cls[p] = c
      }
    }
    return
  }
  for (p = 1; p <= 2; p++) {
    if (!insec[p]) continue
    if (ingoal[p]) { if (t == "" || substr(t, 1, 2) == "**") ingoal[p] = 0; else goalend[p] = nr; continue }
    if (mode == "phase" && !goaldone[p] && match(line, /^[ \t]*\*\*Goal(:\*\*|\*\*[ \t]*:)/)) { ingoal[p] = 1; goaldone[p] = 1; goalend[p] = nr }
  }
}
{
  raw[NR] = $0; n = NR; line = $0
  cr[NR] = (substr(line, length(line), 1) == "\r") ? "\r" : ""
  if (cr[NR] != "") line = substr(line, 1, length(line) - 1)
  if (index(line, "\r")) lonecr++
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
  feed(line, NR)
}
END {
  flush_pending()
  p = (nsec[1] > 0) ? 1 : 2
  act = "none"
  if (nsec[p] == 1 && !infence && !incom && !lonecr && nmark[p] <= 1 && (nmark[p] == 0 || cls[p] == "proposed" || cls[p] == "validated")) {
    if (verb == "propose" && nmark[p] == 0 && goalend[p] > 0) act = "insert"
    if (verb == "validate" && nmark[p] == 1 && cls[p] == "proposed") act = "replace"
  }
  m = 0
  for (i = 1; i <= n; i++) {
    if (act == "replace" && i == mline[p]) out[++m] = lead[p] "**Validation:** " val cr[i]
    else out[++m] = raw[i]
    if (act == "insert" && i == goalend[p]) out[++m] = "**Validation:** " val cr[i]
  }
  for (i = 1; i <= m; i++) { printf "%s", out[i]; if (i < m || !noeol) printf "\n" }
  printf "@ %d %d %s %d %d %d %d %s %s\n", nsec[p] + 0, nmark[p] + 0, (cls[p] == "" ? "-" : cls[p]), infence + 0, incom + 0, goalend[p] + 0, lonecr + 0, act, (mode == "phase" && nsec[p] == 0 ? aliasof() : "-") > st
  close(st)
}
AWKEOF

OUTF=$(mktemp) && ST=$(mktemp) || illis "$ENT : fichier temporaire impossible"
NOEOL=0
if [ "$SIZE" -gt 0 ] && [ "$(tail -c 1 "$F" | od -An -tx1 | tr -d ' \n')" != "0a" ]; then NOEOL=1; fi
awk -v bom="$BOM" -v want="$PHASE" -v mode="$MODE" -v verb="$VERB" -v val="$VAL" -v noeol="$NOEOL" -v st="$ST" "$AWK_PROG" "$F" > "$OUTF" 2>/dev/null
arc=$?
read -r mk nsec nmark cls infence incom goalend lonecr act alias < "$ST" || mk=""
if [ "$arc" -ne 0 ] || [ "$mk" != "@" ]; then illis "$ENT : analyse en echec"; fi

if [ "$lonecr" -ne 0 ]; then illis "$ENT : fin de ligne CR isole (refus, jamais reecrit)"; fi
if [ "$infence" -ne 0 ]; then indet "bloc de code non ferme"; fi
if [ "$incom" -ne 0 ]; then indet "commentaire HTML non ferme"; fi
if [ "$nsec" -eq 0 ] && [ "$MODE" = phase ]; then
  # Même règle que check-phase-validation.sh : désigner une phase existante sous une autre forme est un refus d'usage (64), jamais « introuvable ».
  if [ "$alias" != "-" ]; then usage_err "--phase : '$PHASE' n'est pas un titre du ROADMAP mais désigne la phase $alias (utilise --phase $alias)"; fi
  if { [ "$HAS_WS" -eq 1 ] && [ -d "$VF_WS_DIR/phases/$PHASE" ]; } || { [ "$HAS_WS" -eq 0 ] && [ -d "$PLAN/phases/$PHASE" ]; }; then
    usage_err "--phase : '$PHASE' est un nom de dossier de phase, pas le numéro d'un titre du ROADMAP (utilise le numéro du titre)"
  fi
fi
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
