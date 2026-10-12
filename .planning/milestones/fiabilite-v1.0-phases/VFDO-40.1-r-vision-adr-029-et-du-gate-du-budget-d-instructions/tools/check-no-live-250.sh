#!/usr/bin/env bash
# check-no-live-250.sh — Phase 40.1 (BUDG-04). Recense les énonciations VIVANTES de l'ancien
# plafond « 250 » (agents/lignes) dans le dépôt, pour prouver qu'aucune ne survit à la révision
# ADR-029 (250 -> 300, avertissement dès 251). Codes de sortie : 0 = aucun hit vivant ; 1 = au
# moins un hit vivant (liste imprimée, triée) ; 2 = usage/erreur (pas un dépôt git, git grep en
# échec anormal). Volontairement SANS numéro de ligne dans les règles d'exclusion : une exclusion
# ligne-à-ligne se fait sur le CONTENU de la ligne (ere), jamais sur sa position, pour rester
# valide si le fichier est réédité au-dessus ou en dessous.
set -eu
export LC_ALL=C

cd "${1:-.}" || exit 2

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERREUR: pas un depot git" >&2
  exit 2
}

RE='(^|[^0-9.])250([^0-9]|$)'

# Règles d'exclusion, format « glob ::: ere » (un couple par ligne non vide, non commentaire).
# glob = motif de chemin (bash [[ == ]], `.` = fichier entier auquel cas l'ere est ignorée) ;
# ere = expression régulière étendue testée contre le CONTENU de la ligne (bash =~).
RULES='
# (c) ARCHIVE datée, jamais touchée.
.planning/milestones/* ::: .
.planning/missions/* ::: .
.planning/MISSION-*.dag.json ::: .
.planning/quick/* ::: .
.planning/research/* ::: .
reports/* ::: .
docs/superpowers/* ::: .
CHANGELOG.md ::: .
plugin/*/CHANGELOG.md ::: .
README.md ::: ^\| `v[0-9]+\.[0-9]+\.[0-9]+` \|
README.fr.md ::: ^\| `v[0-9]+\.[0-9]+\.[0-9]+` \|
# ÉCART (a) : les quatre règles de dossiers de phase du manager (une par plage numérique de
# dossier VFDO, plus une pour la phase 40 et une pour la sous-phase courante) sont fusionnées en
# une règle unique — un dossier de phase est par construction un artefact daté, jamais une
# énonciation vivante de la charte. Contient l'\''auto-reference de la sous-phase courante (qui DOIT
# citer l'\''ancien plafond, y compris ces outils).
.planning/phases/* ::: .

# (s) auto-référence de la Phase 40.1 hors dossier de phase.
.planning/ROADMAP.md ::: au plafond de 250\. Samuel ne veut
.planning/ROADMAP.md ::: aucun .*250.* vivant rattach

# (b) AUTRE SENS (software-architecture, VF_ARCH_WARN/BLOCK), jamais touché.
plugin/software-architecture/README.md ::: check-file-size\.sh
plugin/software-architecture/SKILL.md ::: check-file-size\.sh.*250L
plugin/software-architecture/SKILL.md ::: s'\''approche de\) 250-300 lignes
plugin/software-architecture/references/restructuration-playbook.md ::: warn 250L / block 300
plugin/software-architecture/rules/production-code-architecture.md ::: Seuil de taille
plugin/software-architecture/scripts/check-file-size.sh ::: VF_ARCH_WARN
plugin/software-architecture/scripts/tests/test-check-file-size.sh ::: VF_ARCH_WARN=250 VF_ARCH_BLOCK=300
plugin/software-architecture/scripts/tests/test-guard-file-size.sh ::: replace_all
plugin/consolidator/scripts/archive.sh ::: LOG_FILE|rotation simple du log
manual/en/07-under-the-hood/the-machine-gates.md ::: 300-line code threshold
manual/fr/07-sous-le-capot/les-gates-machine.md ::: ^  avertissement .*250 lignes avant le blocage ferme
.planning/codebase/CONVENTIONS.md ::: VF_ARCH_WARN
.planning/ROADMAP.md ::: pr-branch\.md:250-270
.planning/STATE.md ::: 170-250 l\. de tests
.planning/instruction-budget-baselines.tsv ::: ^plugin/[^[:space:]]+[[:space:]]+250[[:space:]]
plugin/reference/content/examples/PetitsCoursFlow/CLAUDE.md ::: 250 EUR
plugin/skill-creator/INSTALL.md ::: ~250 lignes \(workflow\)

# (h) HISTOIRE datée — classement tranché par le manager vf-dev-manager (digest de mission,
# 2026-09-16), d'\''apres CONTEXT « l'\''histoire ne se reecrit pas ».
docs/ADR.md ::: orchestrator-template\.md` \(.*250L, ADR-029\)
.planning/STATE.md ::: 209/250 l\.|250/250 l\.|241/250
.planning/REQUIREMENTS.md ::: VERIF-02|`AGENT\.md` reste .*250 L\.|250/250 lignes
.planning/ROADMAP.md ::: `AGENT\.md` reste .*250 L \(d|exact de 250 lignes|L'\''agent reste .*250 lignes \(ADR-029\)|AGENT\.md restructur.*250 lignes
.planning/BACKLOG.md ::: ^250 lignes\) est un geste|Mesure r.*elle : 250|reste .*250/250
.planning/codebase/CONCERNS.md ::: 249/250 lignes
.claude/agent-memory/* ::: .
plugin/dev-orchestrator/references/mission-flow.md ::: 249/250 lignes
plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh ::: \(249/250\)
plugin/reference/content/VERSION.md ::: 8 templates agents|La v2\.0 impose
plugin/reference/content/methodology/VIBEFLOW_CORE.md ::: ^\| \*\*v4\.1 \(CORE\)\*\*
'

# ÉCART (b) : la règle d'exclusion fichier-entier du seed d'équipe produit est RETIREE — le
# manager verse la contrainte PROSPECTIVE du seed (« Aucun nouvel agent > … lignes ») au lot
# vivant ; elle sera passée à 300 par un plan ultérieur de cette phase.
#
# ÉCART (c) : la règle BACKLOG `reste .*250/250` est CONSERVÉE (pas versée au lot vivant) — lue en
# place (.planning/BACKLOG.md, item « Dérive documentaire… DIFFÉRÉ (2026-09-15) », point 1), la
# ligne cite entre guillemets une MESURE datée du CHANGELOG validator pour dater un mensonge du
# README ; elle n'énonce aucune règle. Traité sur le fond par le plan 40.1-11.

set +e
HITS="$(git -c core.quotepath=off -c color.grep=never -c grep.fullName=false grep -a -n -E -e "$RE")"
RC=$?
set -e

if [ "$RC" -ne 0 ] && [ "$RC" -ne 1 ]; then
  echo "ERREUR: git grep rc=$RC" >&2
  exit 2
fi

if [ "$RC" -eq 1 ] || [ -z "$HITS" ]; then
  exit 0
fi

REMAINING=""
while IFS= read -r h; do
  [ -n "$h" ] || continue
  path="${h%%:*}"
  rest="${h#*:}"
  content="${rest#*:}"
  excluded=0
  while IFS= read -r rule; do
    case "$rule" in
      ''|'#'*) continue ;;
    esac
    glob="${rule%% ::: *}"
    re="${rule#* ::: }"
    # trim leading/trailing spaces left by the here-string split
    glob="${glob# }"; glob="${glob% }"
    re="${re# }"; re="${re% }"
    if [[ "$path" == $glob ]]; then
      if [ "$re" = "." ]; then
        excluded=1
        break
      fi
      if [[ "$content" =~ $re ]]; then
        excluded=1
        break
      fi
    fi
  done <<< "$RULES"
  if [ "$excluded" -eq 0 ]; then
    REMAINING="${REMAINING}${h}
"
  fi
done <<< "$HITS"

if [ -z "$REMAINING" ]; then
  exit 0
fi

printf '%s' "$REMAINING" | sort
exit 1
