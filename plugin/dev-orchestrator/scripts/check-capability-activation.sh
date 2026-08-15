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
# BORNES DÉCLARÉES DE LA RÈGLE 4 (Phase 28, plan 28-02) — ce qu'elle couvre, et ce qu'elle ne
# couvre pas. Un gate qui laisse croire qu'il couvre plus que son périmètre réel est exactement le
# mode d'échec qu'il existe pour fermer (D-01b).
#
# Borne 1 — LA LISTE CLOSE, énumérée à la main, jamais déduite. Deux lignes aujourd'hui :
#   `isolation` et le couple de clés MCP (`vf-mcp-consumer`, `vf-mcp-tools`). Tout armement absent
#   de cette liste n'est vu que s'il est DÉCLARÉ par l'artefact (moitié D-01, règle 4bis). La liste
#   s'élargit ligne à ligne quand un cas nouveau se présente, jamais par heuristique — un gate qui
#   devinerait la frontière serait « soit inerte soit insupportable » (`.planning/ROADMAP.md:2064`).
#
# Borne 2 — LA HIÉRARCHIE AVEC `check-agents.sh`. Deux gardes coexistent sur `isolation:`, et ne
#   disent PAS la même chose. `check-agents.sh:546-549` est un PALIER DUR : interdiction de forme,
#   aucune valeur d'`isolation:` n'est admise dans un agent distribué, corpus = les frontmatters
#   d'agents d'un `agents_dir` à la fois, levée = distribuer la précondition ET prouver le retour
#   des commits. La règle 4 de CE gate est un PALIER DE RELATION : un armement n'est admis que si
#   sa précondition est distribuée, corpus = les artefacts distribués (agents, `AGENT.md`,
#   `SKILL.md`, en deux dispositions), levée = prouver la précondition seule. Pourquoi l'autre
#   subsiste : la règle 4 ne juge QUE la première des deux préconditions de #38 — le retour des
#   commits d'un worker isolé (`open-gsd/gsd-core#3302`) n'est attestable par AUCUN
#   `# vf-provides:`, donc un VERT de la règle 4 n'autorise JAMAIS de ré-armer `isolation:`.
#
# Borne 3 — L'ASYMÉTRIE AGENT / SKILL. Le corpus d'armement inclut les `SKILL.md` distribués, donc
#   la règle 4 est le SEUL contrôle machine qui existe sur une clé de frontmatter de `SKILL.md` :
#   aucun linter de clés n'existe pour eux dans ce dépôt (les scripts qui lisent un `SKILL.md` le
#   font pour résoudre un `name:`, jamais pour valider un jeu de clés). Conséquence : la règle 4
#   vérifie la RELATION armement ↔ précondition sur ces fichiers, et RIEN D'AUTRE de leur
#   frontmatter.
#
# Borne 4 — LE NOM DU PATRON, ET LA LIMITE HONNÊTE. Le patron s'appelle as-installed testing
#   (autopkgtest Debian) : tester l'artefact TEL QU'INSTALLÉ dans un lab vierge, jamais l'arbre
#   source — tester l'arbre source ne prouve rien sur ce que l'install pose (D-04). Ce que la
#   règle 4 établit ici est une couverture declaree, pas une couverture effective : elle vérifie
#   qu'un `# vf-provides:` existe et qu'un cas de la suite prouve sa discriminance ; elle ne
#   vérifie PAS, à l'instant de l'usage chez l'utilisateur, que la précondition est effectivement
#   satisfaite — cela relève du script de preuve lui-même, que ce gate n'exécute JAMAIS (lecture
#   seule stricte, ci-dessous).
#
# Borne 5 — PRÉCONDITION DURE CONTRE TUNING À DÉFAUT SÛR, TRANCHÉE. La règle 4 rend DEUX verdicts
#   (VERT / ROUGE) et AUCUN troisième état PAR ARTEFACT ; le troisième état de la doctrine de ce
#   gate reste porté par les PLANCHERS (exit 2, NON VÉRIFIABLE) ci-dessous, qui disent que le gate
#   ne peut pas se prononcer, jamais qu'un artefact serait « à moitié armé ». Motif : la jointure
#   est STATIQUE (A-4 i, ce gate n'exécute rien) — il ne peut donc pas observer une dégradation
#   gracieuse au moment de l'usage ; un « jaune » par artefact serait un verdict qu'il ne peut pas
#   tenir, ce que la doctrine des trois états ci-dessus interdit déjà explicitement (« Un gate ne se
#   replie pas sur un verdict qu'il ne peut pas tenir »). C'est une DIVERGENCE ASSUMÉE avec la
#   recommandation « trois verdicts » de `28-RESEARCH.md` Open Question 2, et A-9 l'autorise à
#   condition d'écrire le motif — le voici.
#
#   Corollaire (garde-fou A-9 contre le cas de preuve creux) — `isolation:` RESTE dans la liste
#   close, motif RÉÉCRIT pour gsd-core 1.10.0 : (a) le moteur ne casse plus en silence, il dégrade
#   en séquentiel avec message — `worktree.baseRef` a bien glissé de PRÉCONDITION DURE vers TUNING
#   À DÉFAUT SÛR ; (b) et cela ne désarme rien, parce que poser `baseRef: "head"` TAIT LA
#   VÉRIFICATION SANS RÉSOUDRE LA BASE (le moteur le dit lui-même, `worktree-base-ref.cjs`), et
#   parce que le second verrou (`open-gsd/gsd-core#3302`) est intact. Un armement dont le réglage
#   « sûr » consiste à ÉTEINDRE le contrôle n'est pas un armement sûr. La ligne reste, avec ce
#   motif — voir la table des armements plus bas.
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
#   VF_CAPACT_ARMED     liste des artefacts à balayer pour la règle 4 (armement `isolation:` etc.),
#                       UN PAR LIGNE — défaut : `plugin/*/agents/*.md` + `plugin/*/AGENT.md` +
#                       `plugin/*/SKILL.md` + `plugin/*/skills/*/SKILL.md` (dépôt) ou
#                       `.claude/agents/*.md` + `.claude/skills/*/SKILL.md` (lab installé)
#   VF_CAPACT_PROVIDERS liste des scripts à balayer pour le marqueur `# vf-provides:`, UN PAR LIGNE —
#                       défaut : `plugin/*/scripts/*.sh` (dépôt) ou `.claude/scripts/*.sh` (lab)
#
# Exit codes:
#   0  = conforme (le rapport nomme l'univers balayé : combien de toggles, sur quels fichiers)
#   1  = écart constaté (règle 2, 2bis, 3, 4 ou 4bis), message nommant lequel et où
#   2  = NON VÉRIFIABLE : index absent/illisible/sans toggle/sans brique, corpus absent/sans
#        marqueur, configuration absente ou imparsable, `jq` introuvable, corpus d'armement ou de
#        preuve de la règle 4 vide/illisible ou sans aucun `# vf-provides:`
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
CORPUS_FILES=("$@")

# --- Regle 4 : corpus d'armement (frontmatter des artefacts distribues) et corpus de preuve
# (en-tete des scripts distribues). Memes DEUX dispositions et meme decoupage DESARME que CORPUS
# ci-dessus (VF_CAPACT_ARMED / VF_CAPACT_PROVIDERS : canaux de testabilite, patron VF_CAPACT_CORPUS).
# Non surchargeables : la LISTE CLOSE des armements et la TABLE DES IDS legaux, elles, vivent dans
# l'awk plus bas et ne recoivent JAMAIS de variable d'environnement (T-28-01-05) — la doctrine ne se
# deplace pas par `export`.
vf_capact_glob_list() { # <motif...> -> chemins EXISTANTS, FICHIERS reguliers, jamais un lien
                         # symbolique ; bases exclues (contracts.md/README.md/AGENTS.md, patron
                         # check-agents.sh:165)
  # Chaque motif est de la forme `$ROOT/segment/fixe/*/reste/*.md` : un `for f in $pat` NU sur la
  # CHAINE ENTIERE fait subir le word-splitting AVANT le globbing — si `$ROOT` contient un espace,
  # le motif est coupe en deux mots et plus rien ne matche (meme piege que CORPUS_DEFAULT documente
  # plus haut, `~/Library/Mobile Documents/`). Glober `"$parent"/$wildcard` (parent QUOTE) ne marche
  # PAS non plus : le `*` a l'interieur d'une chaine quotee reste litteral, il n'est jamais reconnu
  # comme metacaractere par le shell.
  #
  # La seule construction correcte : isoler la partie FIXE du motif (le prefixe SANS aucun
  # metacaractere — c'est elle, et elle seule, qui peut contenir l'espace de `$ROOT`) de sa partie
  # GLOB (le reste, un texte statique du script, jamais issu d'une variable), `cd` dans la partie
  # fixe (chemin quote, donc l'espace ne la coupe pas), puis glober la partie GLOB, non quotee,
  # DANS ce repertoire — ou aucun `$ROOT` n'entre plus en jeu.
  local pat f head tail
  for pat in "$@"; do
    head="$pat"; tail=""
    while :; do
      case "$head" in
        *'*'*|*'?'*|*'['*) : ;;
        *) break ;;
      esac
      case "$head" in
        */*) tail="${head##*/}${tail:+/$tail}"; head="${head%/*}" ;;
        *) tail="$head${tail:+/$tail}"; head="."; break ;;
      esac
    done
    [ -d "$head" ] || continue
    ( cd "$head" 2>/dev/null || exit 0
      # shellcheck disable=SC2231,SC2086
      for f in $tail; do
        [ -e "$f" ] || continue
        [ -L "$f" ] && continue
        [ -f "$f" ] || continue
        case "$(basename "$f")" in
          contracts.md|README.md|AGENTS.md) continue ;;
        esac
        printf '%s\n' "$f"
      done
    ) | while IFS= read -r f; do printf '%s/%s\n' "$head" "$f"; done
  done
}

if [ "$(basename "$MODULE_DIR")" = ".claude" ]; then
  ARMED_DEFAULT="$(vf_capact_glob_list "$ROOT/.claude/agents/*.md" "$ROOT/.claude/skills/*/SKILL.md")"
  PROVIDERS_DEFAULT="$(vf_capact_glob_list "$ROOT/.claude/scripts/*.sh")"
else
  ARMED_DEFAULT="$(vf_capact_glob_list "$ROOT/plugin/*/agents/*.md" "$ROOT/plugin/*/AGENT.md" "$ROOT/plugin/*/SKILL.md" "$ROOT/plugin/*/skills/*/SKILL.md")"
  PROVIDERS_DEFAULT="$(vf_capact_glob_list "$ROOT/plugin/*/scripts/*.sh")"
fi
# `-` et non `:-` : une surcharge EXPLICITEMENT vide (VF_CAPACT_ARMED="") doit rendre un univers
# VRAIMENT vide (testabilité des planchers, tâche 2) — jamais retomber sur le défaut comme le
# ferait `:-`. Seule l'ABSENCE totale de la variable retombe sur la cascade.
ARMED="${VF_CAPACT_ARMED-$ARMED_DEFAULT}"
PROVIDERS="${VF_CAPACT_PROVIDERS-$PROVIDERS_DEFAULT}"

_old_ifs="$IFS"
set -f
IFS='
'
# shellcheck disable=SC2086
set -- $ARMED
set +f
IFS="$_old_ifs"
ARMED_FILES=("$@")

_old_ifs="$IFS"
set -f
IFS='
'
# shellcheck disable=SC2086
set -- $PROVIDERS
set +f
IFS="$_old_ifs"
PROV_FILES=("$@")

# Lisibilite : meme patron que la boucle CORPUS ci-dessus (:233-238). Un chemin ANNONCE (par
# defaut ou par surcharge) mais illisible sort en 2, jamais un saut silencieux.
for f in "${ARMED_FILES[@]+"${ARMED_FILES[@]}"}"; do
  if [ ! -r "$f" ]; then
    echo "[check-capability-activation] artefact d'armement illisible ($f) — activation NON VÉRIFIABLE" >&2
    exit 2
  fi
done
for f in "${PROV_FILES[@]+"${PROV_FILES[@]}"}"; do
  if [ ! -r "$f" ]; then
    echo "[check-capability-activation] script de preuve illisible ($f) — activation NON VÉRIFIABLE" >&2
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
  VF_CAPACT_ISARM="$(printf '%s\n' "${ARMED_FILES[@]+"${ARMED_FILES[@]}"}")" \
  VF_CAPACT_ISPRV="$(printf '%s\n' "${PROV_FILES[@]+"${PROV_FILES[@]}"}")" \
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
    # --- Regle 4 : vocabulaire, litteral et non surchargeable (A-1 : un registre = vocabulaire
    # seul). Liste CLOSE des armements surveilles : issue #38.
    #   isolation -> worktree-baseref. Motif REECRIT pour gsd-core 1.10.0 (Phase 28, plan 28-02,
    #   borne 5 de len-tete) : (a) le moteur ne casse plus en silence, il degrade en sequentiel
    #   avec message -- worktree.baseRef a bien glisse de PRECONDITION DURE vers TUNING A DEFAUT
    #   SUR ; (b) et cela ne desarme rien : poser baseRef: head TAIT LA VERIFICATION SANS RESOUDRE
    #   LA BASE (le moteur le dit lui-meme, worktree-base-ref.cjs), et le second verrou
    #   open-gsd/gsd-core#3302 (retour des commits dun worker isole) reste intact. Un armement dont
    #   le reglage sur consiste a ETEINDRE le controle nest pas un armement sur. La ligne reste.
    # Ces deux tables ne recoivent AUCUNE variable de surcharge.
    ARM["isolation"] = "worktree-baseref"
    # Seconde ligne (Phase 28, plan 28-02) : un artefact qui recoit une allowlist MCP derivee du
    # lab depend dune precondition externe -- lexistence reelle des serveurs cites -- que rien ne
    # garantit chez lutilisateur ; le contre-fait mesure est que ce depot na AUCUN .mcp.json, donc
    # lallowlist nommee de vf-reviewer.md:10 ny est prouvee par rien. Les deux grammaires
    # (vf-mcp-consumer: true selecteur booleen, vf-mcp-tools: serveur:outils allowlist nommee)
    # exigent la MEME precondition mcp-servers, deja admise dans OKID depuis 28-01. Le token MCP
    # litteral (mcp double-underscore) nentre JAMAIS dans cette table : la liste close se lit sur
    # des CLES de frontmatter, et sa seule occurrence dans les sources est une phrase de prose
    # (vf-reviewer.md:45) que la regle 4 ne doit surtout pas confondre avec un armement.
    ARM["vf-mcp-consumer"] = "mcp-servers"
    ARM["vf-mcp-tools"] = "mcp-servers"
    nArmTable = 0
    for (armk in ARM) nArmTable++
    OKID["worktree-baseref"] = 1
    OKID["mcp-servers"] = 1
    nOkidTable = 0
    for (okidk in OKID) nOkidTable++
    # Membres des deux corpus neufs, portes par lENVIRONNEMENT (jamais awk -v, motif ci-dessus) :
    # ISARM/ISPRV sont des ensembles de FILENAME exacts, tels que passes en argv plus bas, pour que
    # le troisieme discriminant (FILENAME in ISARM / FILENAME in ISPRV) fonctionne par egalite
    # stricte de chaine.
    nUnivArm = 0
    n = split(ENVIRON["VF_CAPACT_ISARM"], isaArr, "\n")
    for (i = 1; i <= n; i++) { if (isaArr[i] == "") continue; ISARM[isaArr[i]] = 1; nUnivArm++ }
    nUnivPrv = 0
    n = split(ENVIRON["VF_CAPACT_ISPRV"], ispArr, "\n")
    for (i = 1; i <= n; i++) { if (ispArr[i] == "") continue; ISPRV[ispArr[i]] = 1; nUnivPrv++ }
    nArmPairs = 0; nReqFiles = 0; nProv = 0
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
  # --- Regle 4, fichier 2 : le frontmatter des artefacts armes. Insere AVANT le bloc corpus SANS
  # CONDITION plus bas : sans cela ces frontmatters tomberaient dans nLines et fausseraient le
  # compteur de corpus (non-regression exigee par la tache 2). Bloc ferme sur la LIGNE `---`
  # exacte : nouvrir qua la premiere, fermer a la suivante, jamais au-dela.
  FILENAME in ISARM {
    if (FNR == 1) { afm_state = 0 }
    if (afm_state == 0) {
      if ($0 == "---") afm_state = 1
      next
    }
    if (afm_state == 1) {
      if ($0 == "---") { afm_state = 2; next }
      t = index($0, ":")
      if (t > 1) {
        k = substr($0, 1, t - 1)
        v = substr($0, t + 1)
        gsub(/^[ \t]+/, "", k); gsub(/[ \t]+$/, "", k)
        gsub(/^[ \t]+/, "", v); gsub(/[ \t]+$/, "", v)
        gsub(/^"/, "", v); gsub(/"$/, "", v)
        # Multi-cle, jamais mono-slot (correction ciblee, Phase 28 post-revue) : un artefact peut
        # porter DEUX armements de la liste close a la fois (ex. isolation: worktree ET
        # vf-mcp-consumer: true) ; enregistrer CHAQUE paire (fichier, armement) au lieu du seul
        # premier armement rencontre par fichier evite le faux VERT ou seul le premier armement
        # etait confronte a vf-requires. Cle de dedoublonnage = FILENAME SUBSEP k : la MEME cle
        # relue deux fois (ligne dupliquee) ne cree pas deux entrees.
        if ((k in ARM) && v != "") {
          armpairkey = FILENAME SUBSEP k
          if (!(armpairkey in ARM_SEEN)) {
            ARM_SEEN[armpairkey] = 1
            ARMPAIR_FILE[++nArmPairs] = FILENAME
            ARMPAIR_KEY[nArmPairs] = k
            ARMPAIR_LINE[nArmPairs] = FNR
          }
        }
        if (k == "vf-requires" && v != "") {
          if (!(FILENAME in REQ_VAL)) { REQFILE_ORDER[++nReqFiles] = FILENAME }
          REQ_VAL[FILENAME] = v
          REQ_LINE[FILENAME] = FNR
        }
      }
      next
    }
    next
  }
  # --- Regle 4, fichier 3 : le bloc de commentaires de tete des scripts porteurs de preuve. Le
  # marqueur nest cherche que dans ce bloc — jusqua la premiere ligne NON commentee — jamais au
  # milieu dun script (patron de la docstring imprimee en --help, :162-164 historique).
  FILENAME in ISPRV {
    if (FNR == 1) { prv_open = 1 }
    if (prv_open) {
      if ($0 !~ /^#/) { prv_open = 0; next }
      if ($0 ~ /^# vf-provides: /) {
        id = $0
        sub(/^# vf-provides: /, "", id)
        gsub(/^[ \t]+/, "", id); gsub(/[ \t]+$/, "", id)
        if (id != "" && !(id in PROV)) { PROV[id] = 1; nProv++ }
      }
    }
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
    # --- Planchers anti-vert-a-vide de la regle 4. Meme forme mot pour mot que ceux de la regle 1
    # ci-dessus : chaque plancher nomme QUELLE regle il rend INERTE, et sort en 2. Aucune de ces
    # quatre conditions ne peut se produire par une simple absence darmement (etat NORMAL) : elles
    # signalent labsence de LUNIVERS lui-meme, jamais labsence de contenu arme dedans.
    if (nUnivArm == 0) {
      print "[check-capability-activation] aucun artefact lisible dans le corpus darmement (" nUnivArm " fichier(s) annonce(s)) — la regle 4 serait INERTE, activation NON VERIFIABLE"
      exit 2
    }
    if (nProv == 0) {
      print "[check-capability-activation] aucun marqueur # vf-provides: dans le corpus de scripts balaye (" nUnivPrv " fichier(s)) — la moitie preuve de la regle 4 serait INERTE, activation NON VERIFIABLE"
      exit 2
    }
    if (nArmTable == 0) {
      print "[check-capability-activation] table des armements surveilles vide — la regle 4 serait INERTE, activation NON VERIFIABLE"
      exit 2
    }
    if (nOkidTable == 0) {
      print "[check-capability-activation] table des ids de precondition legaux vide — la regle 4 et la regle 4bis seraient INERTES, activation NON VERIFIABLE"
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
    # --- Regle 4 : armement sans precondition distribuee (issue #38). Trois sous-cas ROUGE : (a)
    # aucun vf-requires, (b) vf-requires ne cite pas lid exige par CET armement, (c) id legal mais
    # aucun # vf-provides le levant dans le corpus de preuve balaye. Le ROUGE nait de l ARMEMENT
    # SEUL (A-3) : vf-requires ne fait que le LEVER.
    #
    # Boucle sur les PAIRES (fichier, armement) — jamais sur les fichiers seuls (correction ciblee,
    # Phase 28 post-revue) : un artefact bi-arme (ex. isolation: worktree ET vf-mcp-consumer: true)
    # voit chacun de ses armements evalue INDEPENDAMMENT contre le meme vf-requires du fichier —
    # sans cela, un vf-requires ne couvrant que le PREMIER armement rencontre laissait le SECOND
    # totalement hors de vue, faux VERT (rc=0) sur un artefact reellement sous-arme.
    for (i = 1; i <= nArmPairs; i++) {
      f = ARMPAIR_FILE[i]
      armkey = ARMPAIR_KEY[i]
      armline = ARMPAIR_LINE[i]
      reqid = ARM[armkey]
      relf = f
      if (ROOT != "" && index(f, ROOT "/") == 1) relf = substr(f, length(ROOT) + 2)
      if (!(f in REQ_VAL) || REQ_VAL[f] == "") {
        print "[check-capability-activation] ECART regle 4 : artefact « " relf " » arme « " armkey " » sans precondition declaree (vf-requires: absent) — exige « " reqid " » — " relf ":" armline
        bad++
        continue
      }
      if (REQ_VAL[f] != reqid) {
        print "[check-capability-activation] ECART regle 4 : artefact « " relf " » arme « " armkey " » mais vf-requires cite « " REQ_VAL[f] " », pas id exige « " reqid " » — " relf ":" armline
        bad++
        continue
      }
      if (!(reqid in PROV)) {
        print "[check-capability-activation] ECART regle 4 : artefact « " relf " » arme « " armkey " », vf-requires « " reqid " » legal, mais aucun # vf-provides: " reqid " dans le corpus de scripts balaye — " relf ":" armline
        bad++
        continue
      }
    }
    # --- Regle 4bis : hygiene de declaration, symetrique de la regle 3. Un vf-requires citant un
    # id HORS de la table des ids legaux est une ERREUR DE DECLARATION (A-1), jamais un vert. A
    # linverse, un vf-requires LEGAL porte par un artefact SANS armement nest jamais un ecart :
    # cest la moitie declaree de D-01, elle doit rester ouverte aux preconditions que la liste
    # close ne connait pas — cette boucle ne verifie QUE la legalite de lid, jamais la presence dun
    # armement correspondant.
    for (i = 1; i <= nReqFiles; i++) {
      f = REQFILE_ORDER[i]
      id = REQ_VAL[f]
      if (id in OKID) continue
      relf = f
      if (ROOT != "" && index(f, ROOT "/") == 1) relf = substr(f, length(ROOT) + 2)
      print "[check-capability-activation] ECART regle 4bis : artefact « " relf " » declare vf-requires « " id " », absent de la table des ids legaux — " relf ":" REQ_LINE[f]
      bad++
    }
    if (bad > 0) exit 1
    print "[check-capability-activation] conforme — univers balaye : " nT " toggle(s) lus dans " RELIDX ", dont " nInactive " inactif(s) et " nUnknown " indetermine(s) sur " RELCFG " ; " nB " brique(s) routee(s), dont " nBrickInactive " sous toggle inactif ; " nM " toggle(s) sous marqueur (" nMarkers " occurrence(s)) dans " nCorpus " fichier(s) de corpus, " nLines " ligne(s)."
    exit 0
  }
  ' "$INDEX" "${CORPUS_FILES[@]+"${CORPUS_FILES[@]}"}" "${ARMED_FILES[@]+"${ARMED_FILES[@]}"}" "${PROV_FILES[@]+"${PROV_FILES[@]}"}"
)"
rc=$?
[ -n "$report" ] && printf '%s\n' "$report" >&2
exit "$rc"
