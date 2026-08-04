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
# Il asserte la cohérence de TROIS artefacts, et de rien d'autre :
#   1. `gsd-capabilities-index.md`  — index GÉNÉRÉ (jamais édité) : quels toggles gouvernent quoi ;
#   2. `.planning/config.json`      — configuration effective du lab : quel toggle est actif ;
#   3. le corpus documentaire       — `intent-routing.md` + `docs-flow.md` : ce que la doc promet.
#
# Deux ensembles sont calculés, tous deux en `awk` et jamais en `grep` piped (le `grep` proxifié de
# ce poste tronque silencieusement — 31 lignes rendues sur 102 mesurées) :
#   T — les toggles gouvernants lus dans l'index, sur SES DEUX tables : celle par point de hook
#       (5 colonnes → NF=7) et celle des capabilities hors point de hook (3 colonnes → NF=5).
#       Dans les deux, la clé gouvernante est le 4e champ. Une valeur qui n'est pas un identifiant
#       pointé (« — », « - », vide) est écartée : le registre déclare alors n'AVOIR aucune clé.
#   M — les toggles nommés par un marqueur conditionnel du corpus, sur la forme littérale UNIQUE
#       posée par le plan 24-06 : `(conditionnelle : <toggle>)`. Cette forme est un CONTRAT entre
#       les deux plans, pas une convention de rédaction : le gate cherche un motif, pas une
#       paraphrase.
#
# Ce que le gate NE fait PAS. Il ne classe aucune capability « dormante ». Sur les 27 capabilities
# hors point de hook mesurées, 19 sont des `runtime` et 5 des `reviewer` : n'avoir aucun étage est
# leur état NORMAL, et seules 3 sont des `feature` réellement dormantes. Confondre « sans étage » et
# « dormant » serait faux d'un facteur 9. Le gate lit des TOGGLES, il ne juge aucun rôle.
#
# Trois règles, appliquées dans cet ordre :
#
#   Règle 1 — plancher anti-vert-à-vide. T vide OU M vide ⇒ NON VÉRIFIABLE, exit 2. Un index
#     illisible ou un corpus sans aucun marqueur ne prouve RIEN : c'est exactement le mode d'échec
#     que ce gate existe pour fermer, il ne doit pas s'y laisser prendre lui-même. Jamais de repli
#     faible vers 0 (patron `check-state-integrity.sh`).
#
#   Règle 2 — promesse non marquée. Pour chaque toggle de T INACTIF sur ce lab (absent de la
#     configuration, ou présent à `false`/`null`) : si son nom littéral apparaît dans le corpus, il
#     doit y apparaître UNIQUEMENT à l'intérieur d'un marqueur conditionnel. Une occurrence hors
#     marqueur ⇒ exit 1, message nommant le toggle ET le fichier:ligne.
#
#   Règle 3 — marqueur périmé. Pour chaque toggle de M : il doit appartenir à T (un marqueur qui
#     nomme un toggle inconnu de l'index est faux) ET être INACTIF (un marqueur conditionnel qui
#     survit à l'activation de sa capability est la dérive INVERSE). Les deux ⇒ exit 1. C'est cette
#     règle qui rend la discriminance BIDIRECTIONNELLE : sans elle le gate ne verrait qu'un sens.
#
# « Actif » se lit honnêtement : la clé est PRÉSENTE et sa valeur n'est ni `false` ni `null`. Un
# toggle porté par une chaîne (les `review.models.*` nomment un modèle, pas un booléen) reste donc
# actif — traiter toute non-booléenne comme inactive aurait inventé des écarts.
#
# Lecture seule stricte : ce script n'écrit AUCUN fichier, ne déplace rien, n'efface rien. Son seul
# effet est son code de sortie et son rapport sur stderr.
#
# Usage:
#   check-capability-activation.sh [--path <dir>] [-h|--help]
# Defaults: --path = racine du dépôt déduite de l'emplacement du script (le gate est invocable
#   depuis n'importe quel répertoire de travail, notamment depuis la suite du module).
#
# Env (surcharge — testabilité, patron VF_* du module):
#   VF_CAPACT_INDEX   chemin de l'index de capabilities généré
#   VF_CAPACT_CONFIG  chemin du fichier de configuration du lab
#   VF_CAPACT_CORPUS  liste des fichiers du corpus documentaire, séparés par des espaces
#
# Exit codes:
#   0  = conforme (le rapport nomme l'univers balayé : combien de toggles, sur quels fichiers)
#   1  = écart constaté (règle 2 ou règle 3), message nommant lequel et où
#   2  = NON VÉRIFIABLE : index absent/illisible/sans toggle, corpus absent/sans marqueur,
#        configuration absente ou imparsable, `jq` introuvable
#   64 = usage (argument inconnu, --path sans valeur)
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(cd "$SELF_DIR/.." && pwd)"
ROOT="$(cd "$MODULE_DIR/../.." && pwd)"

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

INDEX="${VF_CAPACT_INDEX:-$MODULE_DIR/references/gsd-capabilities-index.md}"
CONFIG="${VF_CAPACT_CONFIG:-$ROOT/.planning/config.json}"
CORPUS_DEFAULT="$MODULE_DIR/references/intent-routing.md $MODULE_DIR/references/docs-flow.md"
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

# shellcheck disable=SC2086
set -- $CORPUS
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

# État effectif : l'ensemble des chemins pointés dont la valeur n'est ni false ni null. UN SEUL
# appel jq — une invocation par toggle serait 29 processus pour la même information.
ACTIVE="$(jq -r 'paths(scalars) as $p | select(getpath($p) != false and getpath($p) != null) | $p | join(".")' "$CONFIG" 2>/dev/null)"
if [ "$?" -ne 0 ]; then
  echo "[check-capability-activation] configuration imparsable ($CONFIG) — activation NON VÉRIFIABLE" >&2
  exit 2
fi

# Un seul awk : index PUIS corpus. Le rapport part sur stdout de awk, le bash le route sur stderr —
# aucune redirection vers un fichier n'est écrite nulle part dans ce script.
# L'ensemble actif transite par l'ENVIRONNEMENT et non par `-v` : une valeur passée à `-v` ne peut
# pas porter de saut de ligne (awk BSD rejette « newline in string mode »), et cet ensemble en est
# une liste. VF_CAPACT_ACTIVE_SET est INTERNE au script, jamais un canal de surcharge.
report="$(
  VF_CAPACT_ACTIVE_SET="$ACTIVE" \
  awk -F'|' -v IDX="$INDEX" -v CFG="$CONFIG" '
  function occ(hay, needle,   c, p) {
    # Comptage LITTERAL (index(), pas de regex) : un nom de toggle porte des points et des tirets,
    # une expression les interpreterait. Conservateur par construction.
    c = 0
    p = index(hay, needle)
    while (p > 0) {
      c++
      hay = substr(hay, p + length(needle))
      p = index(hay, needle)
    }
    return c
  }
  BEGIN {
    n = split(ENVIRON["VF_CAPACT_ACTIVE_SET"], av, "\n")
    for (i = 1; i <= n; i++) if (av[i] != "") active[av[i]] = 1
    nT = 0; nM = 0; nMarkers = 0; nCorpus = 0; nLines = 0; nInactive = 0; bad = 0
  }
  # --- Fichier 1 : index genere. Deux tables, deux arites, MEME position de champ (le 4e).
  FILENAME == IDX {
    if ($0 !~ /^\|[ \t]*`/) next          # ecarte titres, separateurs et prose
    if (NF != 5 && NF != 7) next          # 5 = table hors point de hook ; 7 = table par point de hook
    key = $4
    gsub(/[`\t ]/, "", key)
    if (key !~ /^[A-Za-z_][A-Za-z0-9_-]*(\.[A-Za-z0-9_-]+)+$/) next   # ecarte tiret cadratin, vide
    if (!(key in T)) { T[key] = 1; nT++; TORDER[nT] = key }
    next
  }
  # --- Fichiers suivants : le corpus. Chaque ligne est memorisee pour le rebalayage par toggle
  # (deux fichiers de reference du module : quelques centaines de lignes, cout negligeable).
  {
    nLines++
    LINE[nLines] = $0
    SRC[nLines] = FILENAME
    LNO[nLines] = FNR
    if (!(FILENAME in seenfile)) { seenfile[FILENAME] = 1; nCorpus++ }
    s = $0
    while (match(s, /\(conditionnelle : [A-Za-z0-9_.-]+\)/)) {
      m = substr(s, RSTART, RLENGTH)
      sub(/^\(conditionnelle : /, "", m)
      sub(/\)$/, "", m)
      nMarkers++
      if (!(m in M)) { M[m] = 1; nM++; MORDER[nM] = m; MWHERE[m] = FILENAME ":" FNR }
      s = substr(s, RSTART + RLENGTH)
    }
  }
  END {
    # --- Regle 1 : plancher anti-vert-a-vide. Aucun repli faible vers 0.
    if (nT == 0) {
      print "[check-capability-activation] aucun toggle gouvernant lisible dans " IDX " — activation NON VERIFIABLE"
      exit 2
    }
    if (nM == 0) {
      print "[check-capability-activation] aucun marqueur conditionnel dans le corpus (" nCorpus " fichier(s), " nLines " ligne(s)) — activation NON VERIFIABLE"
      exit 2
    }
    # --- Regle 2 : promesse non marquee.
    for (i = 1; i <= nT; i++) {
      k = TORDER[i]
      if (k in active) continue
      nInactive++
      marker = "(conditionnelle : " k ")"
      for (j = 1; j <= nLines; j++) {
        tot = occ(LINE[j], k)
        if (tot == 0) continue
        ins = occ(LINE[j], marker)
        if (tot > ins) {
          print "[check-capability-activation] ECART regle 2 : le toggle « " k " » est INACTIF sur ce lab (" CFG ") mais cite hors marqueur conditionnel — " SRC[j] ":" LNO[j]
          bad++
        }
      }
    }
    # --- Regle 3 : marqueur perime, ou marqueur inconnu de index. Discriminance inverse.
    for (i = 1; i <= nM; i++) {
      k = MORDER[i]
      if (!(k in T)) {
        print "[check-capability-activation] ECART regle 3 : marqueur conditionnel nommant « " k " », toggle ABSENT de " IDX " — " MWHERE[k]
        bad++
      } else if (k in active) {
        print "[check-capability-activation] ECART regle 3 : marqueur conditionnel PERIME — « " k " » est ACTIF sur ce lab (" CFG "), le marqueur doit disparaitre — " MWHERE[k]
        bad++
      }
    }
    if (bad > 0) exit 1
    print "[check-capability-activation] conforme — univers balaye : " nT " toggle(s) gouvernant(s) lus dans " IDX ", dont " nInactive " inactif(s) sur " CFG " ; " nM " toggle(s) sous marqueur (" nMarkers " occurrence(s)) dans " nCorpus " fichier(s) de corpus, " nLines " ligne(s)."
    exit 0
  }
  ' "$INDEX" "$@"
)"
rc=$?
[ -n "$report" ] && printf '%s\n' "$report" >&2
exit "$rc"
