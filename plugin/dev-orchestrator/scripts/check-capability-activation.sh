#!/usr/bin/env bash
# check-capability-activation.sh — Une entrée de doc peut-elle promettre un geste inerte ? (GSDA-09)
#
# Rôle (Phase 24, zone 3) : ce gate existe parce qu'un trou mesuré a été trouvé, pas par principe.
# `intent-routing.md` routait vers `gsd-graphify` et `gsd-profile-user` alors que les capabilities
# `graphify` et `profile-pipeline` valaient `false` sur ce lab — et le test d'exhaustivité du module
# vérifiait que le skill était ROUTÉ, jamais que sa capability était ACTIVE. Une couverture verte
# masquait deux gestes morts. Ce script relie enfin les deux : une entrée de documentation ne peut
# plus promettre un geste que sa capability rend inerte sans le DIRE.
#
# CE QUE « ENTRÉE » VEUT DIRE ICI, ET POURQUOI C'EST BORNÉ. Le défaut d'origine portait sur le nom
# de la BRIQUE (`gsd-graphify`), pas sur celui du toggle : une première version de ce gate ne
# cherchait que le nom littéral du toggle, si bien qu'ôter le parenthétique en gardant la promesse
# de routage la rendait VERTE — le gate ne fermait pas le trou qu'il déclarait fermer. La règle 2bis
# ci-dessous cherche donc les identifiants de BRIQUE, et elle les cherche dans les LIGNES DE TABLE
# du corpus (`|` en tête). Ce périmètre n'est pas une commodité : une ligne de table de routage EST
# l'entrée qui promet un geste, là où un titre de section ou un paragraphe de commentaire nomme une
# brique sans rien promettre (« `gsd-mempalace-capture` est délibérément absent de toute table de
# routage » ne promet pas `gsd-mempalace-capture`). Le gate ne juge donc PAS la prose, et le dire
# vaut mieux que le laisser croire.
#
# Il asserte la cohérence de TROIS artefacts, et de rien d'autre :
#   1. `gsd-capabilities-index.md`  — index GÉNÉRÉ (jamais édité) : quels toggles gouvernent quoi ;
#   2. `.planning/config.json`      — configuration effective du lab : quel toggle est actif ;
#   3. le corpus documentaire       — `intent-routing.md` + `docs-flow.md` : ce que la doc promet.
#
# Trois ensembles sont calculés, tous en `awk` et jamais en `grep` piped (le `grep` proxifié de ce
# poste tronque silencieusement — 31 lignes rendues sur 102 mesurées) :
#   T — les toggles lus dans l'index, sur SES TROIS tables : celle par point de hook (5 colonnes),
#       celle des capabilities hors point de hook (3 colonnes) et celle des toggles gouvernants
#       (4 colonnes), qui porte en plus le TYPE et le DÉFAUT AMONT de chaque clé. Les tables sont
#       repérées par leur SECTION et non par leur arité : deux tables de même largeur cohabitent
#       désormais dans l'index, et un repérage par `NF` les confondrait.
#   B — les BRIQUES routées lues dans l'index (`gsd-graphify` → `graphify.enabled`), issues des
#       tables `bySkill` et `byAgent` du registre du moteur. C'est cet ensemble, et lui seul, qui
#       relie ce qu'une entrée de doc ÉCRIT à ce qu'un toggle rend inerte.
#   M — les toggles nommés par un marqueur conditionnel du corpus, sur la forme littérale UNIQUE
#       posée par le plan 24-06 : `(conditionnelle : <toggle>)`. Cette forme est un CONTRAT entre
#       les plans, pas une convention de rédaction : le gate cherche un motif, pas une paraphrase.
#
# Ce que le gate NE fait PAS. Il ne classe aucune capability « dormante ». Sur les 27 capabilities
# hors point de hook mesurées, 19 sont des `runtime` et 5 des `reviewer` : n'avoir aucun étage est
# leur état NORMAL, et seules 3 sont des `feature` réellement dormantes. Confondre « sans étage » et
# « dormant » serait faux d'un facteur 9. Le gate lit des TOGGLES, il ne juge aucun rôle.
#
# Quatre règles, appliquées dans cet ordre :
#
#   Règle 1 — plancher anti-vert-à-vide. T vide, B vide OU M vide ⇒ NON VÉRIFIABLE, exit 2. Un index
#     illisible, un index sans table de briques ou un corpus sans aucun marqueur ne prouvent RIEN :
#     c'est exactement le mode d'échec que ce gate existe pour fermer, il ne doit pas s'y laisser
#     prendre lui-même. Jamais de repli faible vers 0 (patron `check-state-integrity.sh`).
#
#   Règle 2 — promesse non marquée (TOGGLE). Pour chaque toggle de T INACTIF sur ce lab : si son nom
#     littéral apparaît dans le corpus, il doit y apparaître UNIQUEMENT à l'intérieur d'un marqueur
#     conditionnel. Une occurrence hors marqueur ⇒ exit 1, message nommant le toggle ET fichier:ligne.
#
#   Règle 2bis — promesse non marquée (BRIQUE). Pour chaque brique de B dont le toggle gouvernant est
#     INACTIF : toute LIGNE DE TABLE du corpus qui cite son identifiant doit porter, sur la MÊME
#     ligne, le marqueur conditionnel de ce toggle. C'est la règle qui ferme le défaut mesuré ;
#     sans elle, retirer le parenthétique en gardant `gsd-graphify` en colonne « brique » passait.
#
#   Règle 3 — marqueur périmé. Pour chaque toggle de M : il doit appartenir à T (un marqueur qui
#     nomme un toggle inconnu de l'index est faux) ET être INACTIF (un marqueur conditionnel qui
#     survit à l'activation de sa capability est la dérive INVERSE). Les deux ⇒ exit 1. C'est cette
#     règle qui rend la discriminance BIDIRECTIONNELLE : sans elle le gate ne verrait qu'un sens.
#
# « ACTIF » SE LIT EN TROIS ÉTATS, jamais en deux. La clé PRÉSENTE dans le config.json est active si
# sa valeur n'est ni `false` ni `null` — un toggle porté par une chaîne, un `0`, un `""` ou un objet
# reste donc actif, et traiter toute non-booléenne comme inactive aurait inventé des écarts. La clé
# ABSENTE retombe sur le DÉFAUT AMONT que l'index déclare : sans lui, « absente » se lirait
# « inactive », ce qui est FAUX pour les 12 clés dont le registre déclare `default: true`. Quand
# l'index ne déclare aucun défaut, l'état est INDÉTERMINÉ : aucune règle ne se prononce, et le
# rapport compte ces toggles à part. Un gate ne se replie pas sur un verdict qu'il ne peut pas tenir.
#
# COMPARAISON DE NOMS : PAR FRONTIÈRE, JAMAIS PAR SOUS-CHAÎNE NUE. `workflow.code_review` est une
# sous-chaîne de `workflow.code_review_command` — la paire existe déjà dans ce lab. Comparer par
# sous-chaîne nue faisait donc voir la citation d'une clé là où le corpus en nommait une AUTRE, et
# fabriquait des écarts incorrigibles (aucune rédaction ne peut satisfaire un gate qui cherche le
# mauvais nom). Une occurrence ne compte que si ses deux voisins immédiats sortent de l'alphabet des
# identifiants (`A-Za-z0-9_.-`).
#
# Lecture seule stricte : ce script n'écrit AUCUN fichier, ne déplace rien, n'efface rien. Son seul
# effet est son code de sortie et son rapport sur stderr.
#
# Usage:
#   check-capability-activation.sh [--path <dir>] [-h|--help]
# Defaults: --path = racine du LAB, trouvée en remontant depuis l'emplacement du script jusqu'au
#   premier dossier portant `.planning/config.json`. Le gate est invocable depuis n'importe quel
#   répertoire de travail, et depuis les DEUX dispositions où il vit : le dépôt de distribution
#   (`plugin/dev-orchestrator/scripts/`) et un lab installé (`.claude/scripts/`, à plat).
#
# Env (surcharge — testabilité, patron VF_* du module):
#   VF_CAPACT_INDEX   chemin de l'index de capabilities généré
#   VF_CAPACT_CONFIG  chemin du fichier de configuration du lab
#   VF_CAPACT_CORPUS  liste des fichiers du corpus documentaire, UN PAR LIGNE (séparateur : saut de
#                     ligne, jamais l'espace — un séparateur « espace » ne peut, par construction,
#                     pas exprimer un chemin qui en contient, ce qui est le cas courant sous
#                     `~/Library/Mobile Documents/`)
#
# Exit codes:
#   0  = conforme (le rapport nomme l'univers balayé : combien de toggles, sur quels fichiers)
#   1  = écart constaté (règle 2, 2bis ou 3), message nommant lequel et où
#   2  = NON VÉRIFIABLE : index absent/illisible/sans toggle/sans brique, corpus absent/sans
#        marqueur, configuration absente ou imparsable, `jq` introuvable
#   64 = usage (argument inconnu, --path sans valeur)
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(cd "$SELF_DIR/.." && pwd)"

# --- Racine du LAB ------------------------------------------------------------------------------
# `$MODULE_DIR/../..` était FAUX hors du dépôt de distribution. Dans un lab installé, l'installeur
# dépose les scripts À PLAT dans `.claude/scripts/` : `../..` désigne alors le PARENT du lab —
# c'est-à-dire le `.planning/config.json` d'un AUTRE projet, ou rien du tout. Mesuré : le gate
# sortait 2 chez l'utilisateur, donc la suite du module y rougissait ; et quand un projet voisin
# existait, il lisait sa configuration. La résolution remonte donc jusqu'au premier ancêtre qui
# porte `.planning/config.json`, et s'arrête au premier trouvé : elle ne peut plus dépasser le lab.
#
# La remontée est ANCRÉE et BORNÉE, jamais libre : une remontée libre depuis le script TRAVERSE le
# lab dès que celui-ci n'a pas de `.planning/config.json`, et retombe sur le projet du dessus —
# c'est-à-dire exactement le défaut qu'on ferme. Trois paliers, dans cet ordre :
#   1. `--path` explicite : l'appelant a tranché, rien d'autre n'est consulté ;
#   2. l'ancre d'INSTALLATION. Le script vit soit dans le dépôt de distribution
#      (`plugin/<module>/scripts/`, ancre = racine git), soit à plat dans un lab installé
#      (`.claude/scripts/`, ancre = le PARENT de `.claude`, sans aucune remontée). Ce palier ne peut
#      pas dépasser le lab, même quand le lab n'a pas de configuration : il rend alors une ancre
#      sans `.planning/config.json` et le gate sort 2 « NON VÉRIFIABLE » — un refus honnête, jamais
#      la configuration du voisin ;
#   3. seulement si le palier 2 ne porte pas de configuration : une remontée depuis le RÉPERTOIRE
#      COURANT (le lab où l'on travaille), bornée par sa propre racine git. C'est le cas d'une
#      installation en scope UTILISATEUR (`~/.claude/scripts/`), où le script ne peut pas savoir
#      quel lab il sert — et où la seule information disponible est le répertoire de travail.
vf_capact_bounded_walk() { # <départ> <borne haute> — imprime la racine portant .planning/config.json
  local d="$1" stop="$2"
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    if [ -f "$d/.planning/config.json" ]; then printf '%s' "$d"; return 0; fi
    [ "$d" = "$stop" ] && return 1
    d="$(dirname "$d")"
  done
  return 1
}
if [ "$(basename "$MODULE_DIR")" = ".claude" ]; then
  ROOT="$(dirname "$MODULE_DIR")"
else
  ROOT="$(cd "$SELF_DIR" && git rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
  [ -n "$ROOT" ] || ROOT="$(dirname "$MODULE_DIR")"
fi
if [ ! -f "$ROOT/.planning/config.json" ]; then
  _cwd_stop="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  _cwd_root="$(vf_capact_bounded_walk "$PWD" "$_cwd_stop")" && ROOT="$_cwd_root"
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-capability-activation] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    -h|--help)
      # Docstring imprimée en `awk` et non en `grep | sed` : la docstring porte des lignes de
      # séparation nues (`#` seul) qu'un motif `^# ` perdrait, et le `grep` de ce poste est proxifié.
      awk 'NR == 1 && /^#!/ { next } /^#/ { sub(/^#[ ]?/, ""); print; next } { exit }' "$0"
      exit 0 ;;
    *)
      echo "[check-capability-activation] argument inconnu : $1" >&2
      exit 64 ;;
  esac
done

# --- Dossier des références --------------------------------------------------------------------
# Deux dispositions, une seule cascade. Dépôt de distribution : `<module>/references/`. Lab installé
# (`vibeflow-update.sh`, module à AGENT.md sans SKILL.md) : `.claude/agents/<module>-references/`,
# les scripts étant eux à plat dans `.claude/scripts/`. La première qui porte l'index l'emporte.
REF_DIR=""
for _cand in \
  "$MODULE_DIR/references" \
  "$SELF_DIR/../agents/dev-orchestrator-references" \
  "$SELF_DIR/../skills/dev-orchestrator/references"
do
  if [ -f "$_cand/gsd-capabilities-index.md" ]; then
    REF_DIR="$(cd "$_cand" && pwd)"
    break
  fi
done
[ -n "$REF_DIR" ] || REF_DIR="$MODULE_DIR/references"

INDEX="${VF_CAPACT_INDEX:-$REF_DIR/gsd-capabilities-index.md}"
CONFIG="${VF_CAPACT_CONFIG:-$ROOT/.planning/config.json}"
CORPUS_DEFAULT="$REF_DIR/intent-routing.md
$REF_DIR/docs-flow.md"
CORPUS="${VF_CAPACT_CORPUS:-$CORPUS_DEFAULT}"

# --- Préconditions : chaque manque sort en NON VÉRIFIABLE, jamais en conforme. ------------------
if [ ! -r "$INDEX" ]; then
  echo "[check-capability-activation] index de capabilities illisible ($INDEX) — activation NON VÉRIFIABLE" >&2
  exit 2
fi
if [ ! -r "$CONFIG" ]; then
  echo "[check-capability-activation] configuration du lab illisible ($CONFIG) — activation NON VÉRIFIABLE" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "[check-capability-activation] jq introuvable — état effectif des toggles illisible, activation NON VÉRIFIABLE" >&2
  exit 2
fi

# Découpage du corpus SUR LE SAUT DE LIGNE, et globbing DÉSARMÉ le temps du découpage. `set -- $VAR`
# nu faisait deux choses de trop : il coupait aussi sur l'espace (donc aucun chemin contenant un
# espace n'était exprimable, et le `CORPUS_DEFAULT` d'un lab sous `~/Library/Mobile Documents/`
# partait en exit 2 permanent), et il DÉVELOPPAIT LES GLOBS (`VF_CAPACT_CORPUS="$T/*.md"` aspirait
# des fichiers que personne n'avait nommés, ce qui rendait faux jusqu'au compteur « N fichier(s) de
# corpus » du rapport).
_old_ifs="$IFS"
set -f
IFS='
'
# shellcheck disable=SC2086
set -- $CORPUS
set +f
IFS="$_old_ifs"
if [ "$#" -eq 0 ]; then
  echo "[check-capability-activation] corpus documentaire vide — activation NON VÉRIFIABLE" >&2
  exit 2
fi
for f in "$@"; do
  if [ ! -r "$f" ]; then
    echo "[check-capability-activation] fichier de corpus illisible ($f) — activation NON VÉRIFIABLE" >&2
    exit 2
  fi
done

# État effectif : chaque chemin PRÉSENT dans la configuration, avec son état. `paths` et non
# `paths(scalars)` : une clé portant un objet ou un tableau est PRÉSENTE, et la doctrine énoncée
# plus haut la dit ACTIVE (sa valeur n'est ni `false` ni `null`) ; `paths(scalars)` l'omettait, donc
# la faisait retomber sur la branche « absente » et la déclarait inactive — l'inverse de la règle
# écrite. UN SEUL appel jq : une invocation par toggle serait des dizaines de processus pour la
# même information.
PRESENT="$(jq -r 'paths as $p | ($p | join(".")) + "\t" + (if getpath($p) == false or getpath($p) == null then "0" else "1" end)' "$CONFIG" 2>/dev/null)"
if [ "$?" -ne 0 ]; then
  echo "[check-capability-activation] configuration imparsable ($CONFIG) — activation NON VÉRIFIABLE" >&2
  exit 2
fi

# Chemins RELATIFS à la racine du lab dans les verdicts : un chemin absolu porte le nom de compte de
# la machine qui a lancé le gate, et ces messages finissent en clair dans des rapports versionnés.
REL_INDEX="${INDEX#$ROOT/}"
REL_CONFIG="${CONFIG#$ROOT/}"

# Un seul awk : index PUIS corpus. Le rapport part sur stdout de awk, le bash le route sur stderr —
# aucune redirection vers un fichier n'est écrite nulle part dans ce script.
# TOUT ce qui vient du shell transite par l'ENVIRONNEMENT, jamais par `-v` : une valeur passée à
# `-v` subit l'interprétation des échappements (un `\` dans un chemin rendait `FILENAME == IDX`
# faux, l'index était alors parcouru comme du corpus, et le gate sortait 2 sur un diagnostic
# trompeur), et elle ne peut pas porter de saut de ligne (awk BSD rejette « newline in string
# mode »), or l'état de configuration en est une liste. Ces variables sont INTERNES, jamais des
# canaux de surcharge.
report="$(
  VF_CAPACT_PRESENT="$PRESENT" \
  VF_CAPACT_IDX="$INDEX" \
  VF_CAPACT_REL_INDEX="$REL_INDEX" \
  VF_CAPACT_REL_CONFIG="$REL_CONFIG" \
  VF_CAPACT_ROOT="$ROOT" \
  awk -F'|' '
  function isid(c) { return (c ~ /^[A-Za-z0-9_.-]$/) }
  # Comptage LITTERAL A FRONTIERE (index(), pas de regex : un nom de toggle porte des points et des
  # tirets, une expression les interpreterait). Une occurrence ne compte que si ses deux voisins
  # sortent de l alphabet des identifiants — sans quoi `workflow.code_review` se compte une fois
  # dans `workflow.code_review_command`, qui nomme une AUTRE cle.
  function occ(hay, needle,   c, p, before, after, pos) {
    c = 0; pos = 0
    p = index(hay, needle)
    while (p > 0) {
      pos += p
      before = (pos == 1) ? "" : substr(hay, p - 1, 1)
      after = substr(hay, p + length(needle), 1)
      if (!isid(before) && !isid(after)) c++
      hay = substr(hay, p + length(needle))
      pos += length(needle) - 1
      p = index(hay, needle)
    }
    return c
  }
  function trimcell(s) { gsub(/[`\t ]/, "", s); return s }
  function iskey(s) { return (s ~ /^[A-Za-z_][A-Za-z0-9_-]*(\.[A-Za-z0-9_-]+)+$/) }
  # Etat resolu dun toggle : 1 actif, 0 inactif, -1 indetermine (ni present, ni defaut declare).
  function state(k) {
    if (k in cfg) return cfg[k]
    if (k in DEF) return DEF[k]
    return -1
  }
  BEGIN {
    IDX = ENVIRON["VF_CAPACT_IDX"]
    RELIDX = ENVIRON["VF_CAPACT_REL_INDEX"]
    RELCFG = ENVIRON["VF_CAPACT_REL_CONFIG"]
    ROOT = ENVIRON["VF_CAPACT_ROOT"]
    # Libelles de section — CONTRAT avec build-gsd-capabilities-index.sh (SECTION_TITLE_*). Le
    # contrat porte sur le PREFIXE STRICTEMENT ASCII de chaque titre, jamais sur le titre entier :
    # les titres reels portent des accents, et le traitement du non-ASCII varie dun awk a lautre
    # (mesure sur ce depot : une classe de caracteres multi-octets ne se comporte pas pareil en awk
    # BSD et en gawk). Comparer un prefixe ASCII est la seule forme qui tienne des deux cotes.
    S_ORPHANS = "Capabilities hors point de hook"
    S_TOGGLES = "Toggles gouvernants"
    S_BRICKS  = "Briques rout"
    n = split(ENVIRON["VF_CAPACT_PRESENT"], av, "\n")
    for (i = 1; i <= n; i++) {
      if (av[i] == "") continue
      t = index(av[i], "\t")
      if (t <= 1) continue
      cfg[substr(av[i], 1, t - 1)] = (substr(av[i], t + 1) == "1") ? 1 : 0
    }
    nT = 0; nB = 0; nM = 0; nMarkers = 0; nCorpus = 0; nLines = 0
    nInactive = 0; nUnknown = 0; nBrickInactive = 0; bad = 0; sec = ""
  }
  # --- Fichier 1 : index genere. Reperage par SECTION, jamais par arite : trois tables y vivent
  # desormais, dont deux de meme largeur — `NF` seul les confondrait.
  FILENAME == IDX {
    if ($0 ~ /^## /) {
      h = $0; sub(/^## /, "", h); gsub(/`/, "", h)
      if (index(h, S_TOGGLES) == 1) sec = "TOG"
      else if (index(h, S_BRICKS) == 1) sec = "BRK"
      else if (index(h, S_ORPHANS) == 1) sec = "ORP"
      else sec = "HOOK"
      next
    }
    if ($0 !~ /^\|[ \t]*`/) next          # ecarte titres, separateurs et prose
    if (sec == "TOG") {
      k = trimcell($2)
      if (!iskey(k)) next
      if (!(k in T)) { T[k] = 1; nT++; TORDER[nT] = k }
      d = trimcell($5)
      # « oui »/« non » : le rendu booleen de `cell()` cote generateur. Toute autre valeur (dont
      # le tiret cadratin) laisse le defaut NON DECLARE, donc letat indetermine.
      if (d == "oui") DEF[k] = 1
      else if (d == "non") DEF[k] = 0
      next
    }
    if (sec == "BRK") {
      b = trimcell($2); bk = trimcell($4)
      if (b == "" || !iskey(bk)) next     # sans toggle gouvernant, aucun verdict possible
      if (!(b in BK)) { BK[b] = bk; nB++; BORDER[nB] = b }
      next
    }
    # Tables par point de hook (NF=7) et capabilities hors point de hook (NF=5) : meme position de
    # champ pour le toggle, le 4e.
    if (NF != 5 && NF != 7) next
    k = trimcell($4)
    if (!iskey(k)) next                   # ecarte tiret cadratin, vide
    if (!(k in T)) { T[k] = 1; nT++; TORDER[nT] = k }
    next
  }
  # --- Fichiers suivants : le corpus. Chaque ligne est memorisee pour le rebalayage par toggle
  # (deux fichiers de reference du module : quelques centaines de lignes, cout negligeable).
  {
    nLines++
    LINE[nLines] = $0
    # Chemin relatif par index()/substr(), JAMAIS par sub() : le premier argument de sub() est une
    # EXPRESSION, et une racine de lab contenant un metacaractere la ferait deraper silencieusement.
    SRC[nLines] = FILENAME
    if (ROOT != "" && index(FILENAME, ROOT "/") == 1) SRC[nLines] = substr(FILENAME, length(ROOT) + 2)
    LNO[nLines] = FNR
    ROW[nLines] = ($0 ~ /^[ \t]*\|/) ? 1 : 0
    if (!(FILENAME in seenfile)) { seenfile[FILENAME] = 1; nCorpus++ }
    s = $0
    while (match(s, /\(conditionnelle : [A-Za-z0-9_.-]+\)/)) {
      m = substr(s, RSTART, RLENGTH)
      sub(/^\(conditionnelle : /, "", m)
      sub(/\)$/, "", m)
      nMarkers++
      if (!(m in M)) { M[m] = 1; nM++; MORDER[nM] = m; MWHERE[m] = SRC[nLines] ":" FNR }
      s = substr(s, RSTART + RLENGTH)
    }
  }
  END {
    # --- Regle 1 : plancher anti-vert-a-vide. Aucun repli faible vers 0.
    if (nT == 0) {
      print "[check-capability-activation] aucun toggle gouvernant lisible dans " RELIDX " — activation NON VERIFIABLE"
      exit 2
    }
    if (nB == 0) {
      print "[check-capability-activation] aucune brique routee lisible dans " RELIDX " (section « " S_BRICKS " ») — la regle 2bis serait INERTE, activation NON VERIFIABLE"
      exit 2
    }
    if (nM == 0) {
      print "[check-capability-activation] aucun marqueur conditionnel dans le corpus (" nCorpus " fichier(s), " nLines " ligne(s)) — activation NON VERIFIABLE"
      exit 2
    }
    # --- Regle 2 : promesse non marquee, par nom de TOGGLE.
    for (i = 1; i <= nT; i++) {
      k = TORDER[i]
      st = state(k)
      if (st == -1) { nUnknown++; continue }
      if (st == 1) continue
      nInactive++
      marker = "(conditionnelle : " k ")"
      for (j = 1; j <= nLines; j++) {
        tot = occ(LINE[j], k)
        if (tot == 0) continue
        ins = occ(LINE[j], marker)
        if (tot > ins) {
          print "[check-capability-activation] ECART regle 2 : le toggle « " k " » est INACTIF sur ce lab (" RELCFG ") mais cite hors marqueur conditionnel — " SRC[j] ":" LNO[j]
          bad++
        }
      }
    }
    # --- Regle 2bis : promesse non marquee, par identifiant de BRIQUE. Cest la regle qui ferme le
    # defaut mesure : le corpus ecrit `gsd-graphify`, pas `graphify.enabled`.
    for (i = 1; i <= nB; i++) {
      b = BORDER[i]
      k = BK[b]
      st = state(k)
      if (st != 0) continue
      nBrickInactive++
      marker = "(conditionnelle : " k ")"
      for (j = 1; j <= nLines; j++) {
        if (!ROW[j]) continue             # seules les lignes de table sont des « entrees »
        if (occ(LINE[j], b) == 0) continue
        if (occ(LINE[j], marker) > 0) continue
        print "[check-capability-activation] ECART regle 2bis : la brique « " b " » est promise par une entree de table alors que son toggle « " k " » est INACTIF sur ce lab (" RELCFG ") — aucun marqueur « " marker " » sur cette ligne — " SRC[j] ":" LNO[j]
        bad++
      }
    }
    # --- Regle 3 : marqueur perime, ou marqueur inconnu de index. Discriminance inverse.
    for (i = 1; i <= nM; i++) {
      k = MORDER[i]
      if (!(k in T)) {
        print "[check-capability-activation] ECART regle 3 : marqueur conditionnel nommant « " k " », toggle ABSENT de " RELIDX " — " MWHERE[k]
        bad++
      } else if (state(k) == 1) {
        print "[check-capability-activation] ECART regle 3 : marqueur conditionnel PERIME — « " k " » est ACTIF sur ce lab (" RELCFG "), le marqueur doit disparaitre — " MWHERE[k]
        bad++
      }
    }
    if (bad > 0) exit 1
    print "[check-capability-activation] conforme — univers balaye : " nT " toggle(s) lus dans " RELIDX ", dont " nInactive " inactif(s) et " nUnknown " indetermine(s) sur " RELCFG " ; " nB " brique(s) routee(s), dont " nBrickInactive " sous toggle inactif ; " nM " toggle(s) sous marqueur (" nMarkers " occurrence(s)) dans " nCorpus " fichier(s) de corpus, " nLines " ligne(s)."
    exit 0
  }
  ' "$INDEX" "$@"
)"
rc=$?
[ -n "$report" ] && printf '%s\n' "$report" >&2
exit "$rc"
