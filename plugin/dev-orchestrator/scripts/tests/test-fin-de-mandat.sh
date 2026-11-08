#!/usr/bin/env bash
# test-fin-de-mandat.sh — Garde machine de la doctrine « Fin de mandat » (issue #223).
#
# Défaut gardé : des workers d'équipe restent vivants après leur travail (rejeu en tâche de fond,
# tour rendu « en attente » jamais réveillé, travail non commité) et des managers rendent la main
# sans clore leurs enfants. La consigne existait en prose ; rien ne gardait qu'un prompt la porte.
#
# Contrat D3 :
#   - team-kernel.md porte une section `## Fin de mandat` ;
#   - tout WORKER porte l'étiquette `**Fin de mandat**` et, DANS son bloc, les jetons
#     « jamais en attente », « premier plan », « échéance », « processus », « même tour »,
#     « §Fin de mandat » ;
#   - tout MANAGER porte ce bloc worker ET `**Clôture des workers**` (TaskStop, balayage,
#     worktree-procs.sh, aucun enfant vivant, orphans, consigne de reprise, §Fin de mandat) ;
#   - le HEAD (plugin/dev-orchestrator/AGENT.md) porte `**Balayage de sortie**` (orphans, dernier
#     message, TaskStop, worktree-procs.sh, §Fin de mandat).
# Bloc = la ligne qui porte l'étiquette + ses continuations (jusqu'à ligne vide, nouvelle puce,
# nouvelle étiquette `**` en début de ligne, ou titre). Le frontmatter est exclu : un jeton ailleurs
# dans le fichier (ex. `TaskStop` de la ligne `tools:`) ne compte pas.
#
# Population : un plancher nommé + DÉRIVATION (une liste de cas ne ferme pas une classe) :
#   (a) tout agent nommé dans l'allowlist `Agent(...)` d'un manager du plancher est un worker exigé ;
#   (b) tout agent qui mentionne « Fin de tour inerte » / « Fin de mandat » doit être de la population.
# Un membre du plancher introuvable = rouge (jamais un vert à vide).
#
# Hermétique : fixtures construites sous un mktemp -d détruit par trap. FIN_DE_MANDAT_ROOT permet de
# viser une autre racine (preuve sur arbre-copie). bash 3.2 / GNU / uutils, aucune dépendance à rtk.
set -uo pipefail

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1 — attendu [$2] obtenu [$3]"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- racine du dépôt : remontée depuis l'emplacement de la suite, jusqu'à la marque du dépôt ---
find_repo_root() {
  local d
  d="$(cd "$(dirname "$0")" && pwd)"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    if [ -f "$d/plugin/dev-orchestrator/AGENT.md" ] && [ -f "$d/plugin/conductor/references/team-kernel.md" ]; then
      echo "$d"; return 0
    fi
    d="$(dirname "$d")"
  done
  return 1
}

# --- population : plancher nommé ---
FLOOR_WORKERS="vf-coder vf-reviewer vf-auditer vf-crafter vf-design-judge vf-test-runner vf-app-fixer prd-gate"
FLOOR_MANAGERS="vf-dev-manager vf-design-manager vf-test-orchestrator vf-content-manager vf-business-manager vf-growth-manager vf-product-manager"
HEAD_REL="plugin/dev-orchestrator/AGENT.md"

WORKER_LABEL='**Fin de mandat**'
MANAGER_LABEL='**Clôture des workers**'
HEAD_LABEL='**Balayage de sortie**'

# Jeton par ligne (les jetons contiennent des espaces).
WORKER_TOKENS='jamais en attente
premier plan
échéance
processus
même tour
§Fin de mandat'
MANAGER_TOKENS='TaskStop
balayage
worktree-procs.sh
aucun enfant vivant
orphans
consigne de reprise
§Fin de mandat'
HEAD_TOKENS='orphans
dernier message
TaskStop
worktree-procs.sh
§Fin de mandat'

# extract_block FILE LABEL → bloc sur stdout (vide si l'étiquette est absente). Frontmatter exclu.
extract_block() {
  awk -v lab="$2" '
    NR==1 && $0=="---" { infm=1; next }
    infm { if ($0=="---") infm=0; next }
    inb==0 { if (!done && index($0, lab)>0) { inb=1; done=1; print } ; next }
    {
      if ($0 ~ /^[ \t]*$/) exit
      if ($0 ~ /^[ \t]*([-*]|[0-9]+\.)[ \t]/) exit
      if ($0 ~ /^\*\*/) exit
      if ($0 ~ /^#/) exit
      print
    }' "$1"
}

# agent_allowlist FILE → noms de l'allowlist Agent(...) du frontmatter, un par ligne.
agent_allowlist() {
  awk 'NR==1 && $0=="---" { infm=1; next }
       infm { if ($0=="---") { exit } ; if ($0 ~ /^tools:/) print }' "$1" \
    | sed -n 's/.*Agent(\([^)]*\)).*/\1/p' | tr ',' '\n' | tr -d ' \t'
}

find_agent() { # ROOT NAME → chemin
  local f
  for f in "$1"/plugin/*/agents/"$2".md; do
    [ -f "$f" ] && { echo "$f"; return 0; }
  done
  return 1
}

VIOL=""
viol() { VIOL="${VIOL}$1"$'\n'; }

# check_block ROOT FILE LABEL TOKENS : pose des violations nommant fichier + étiquette/jeton.
check_block() {
  local rel="${2#$1/}" block t
  block="$(extract_block "$2" "$3")"
  if [ -z "$block" ]; then
    viol "$rel: étiquette $3 absente"
    return 0
  fi
  while IFS= read -r t; do
    case "$block" in
      *"$t"*) : ;;
      *) viol "$rel: jeton « $t » absent du bloc $3" ;;
    esac
  done <<EOF
$4
EOF
}

# check_root ROOT : remplit VIOL ; rc 1 si au moins une violation.
check_root() {
  local R="$1" n p kernel POP="" DERIVED="" WORKERS="" w a
  VIOL=""
  kernel="$R/plugin/conductor/references/team-kernel.md"
  if [ ! -f "$kernel" ]; then
    viol "plugin/conductor/references/team-kernel.md: fichier introuvable"
  elif ! grep -q '^## Fin de mandat' "$kernel"; then
    viol "plugin/conductor/references/team-kernel.md: section « ## Fin de mandat » absente"
  fi

  if [ ! -f "$R/$HEAD_REL" ]; then
    viol "$HEAD_REL: membre du plancher (head) introuvable"
  else
    POP="${POP}$R/$HEAD_REL"$'\n'
    check_block "$R" "$R/$HEAD_REL" "$HEAD_LABEL" "$HEAD_TOKENS"
  fi

  for n in $FLOOR_MANAGERS; do
    if ! p="$(find_agent "$R" "$n")"; then
      viol "$n: membre du plancher (manager) introuvable sous plugin/*/agents/"
      continue
    fi
    POP="${POP}$p"$'\n'
    check_block "$R" "$p" "$WORKER_LABEL" "$WORKER_TOKENS"
    check_block "$R" "$p" "$MANAGER_LABEL" "$MANAGER_TOKENS"
    while IFS= read -r a; do
      [ -z "$a" ] && continue
      DERIVED="${DERIVED}${a} "
    done <<EOF
$(agent_allowlist "$p")
EOF
  done

  WORKERS="$FLOOR_WORKERS"
  for a in $DERIVED; do
    # dérivation (a) : un agent présent sur disque, non manager, entre dans la population
    case " $FLOOR_MANAGERS " in *" $a "*) continue ;; esac
    case " $WORKERS " in *" $a "*) continue ;; esac
    find_agent "$R" "$a" >/dev/null 2>&1 && WORKERS="$WORKERS $a"
  done

  for w in $WORKERS; do
    if ! p="$(find_agent "$R" "$w")"; then
      viol "$w: membre du plancher (worker) introuvable sous plugin/*/agents/"
      continue
    fi
    POP="${POP}$p"$'\n'
    check_block "$R" "$p" "$WORKER_LABEL" "$WORKER_TOKENS"
  done

  # dérivation (b) : qui parle de la doctrine doit être de la population
  for p in "$R"/plugin/*/agents/*.md "$R"/plugin/*/AGENT.md; do
    [ -f "$p" ] || continue
    if grep -qF -e 'Fin de tour inerte' -e 'Fin de mandat' "$p"; then
      case "
$POP" in
        *"
$p
"*) : ;;
        *) viol "${p#$R/}: mentionne « Fin de tour inerte » / « Fin de mandat » mais hors population (ni plancher, ni allowlist d'un manager)" ;;
      esac
    fi
  done

  [ -z "$VIOL" ]
}

# --- fixture conforme minimale ---
BLK_WORKER='- **Fin de mandat** : jamais en attente d'"'"'une tâche de fond, attente au premier plan
  avec une échéance ; aucun processus vivant au rapport, dans le même tour (§Fin de mandat).'
BLK_MANAGER='- **Clôture des workers** : TaskStop sur chaque enfant, balayage via worktree-procs.sh,
  aucun enfant vivant ; orphans signalés, consigne de reprise écrite (§Fin de mandat).'
BLK_HEAD='- **Balayage de sortie** : orphans repérés au dernier message de chaque worker, TaskStop,
  worktree-procs.sh (§Fin de mandat).'

mk_agent() { # FILE NAME TOOLS [BLOCS...]
  local f="$1" name="$2" tools="$3" b
  mkdir -p "$(dirname "$f")"
  { printf -- '---\nname: %s\ndescription: d\ntools: %s\n---\n# %s\n\nCorps.\n' "$name" "$tools" "$name"
    shift 3
    for b in "$@"; do printf '\n%s\n' "$b"; done
    printf '\nSuite.\n'
  } > "$f"
}

mk_fixture() { # ROOT
  local R="$1" P="$1/plugin"
  mkdir -p "$P/conductor/references"
  printf '# Kernel\n\n## Fin de mandat\n\nDoctrine.\n' > "$P/conductor/references/team-kernel.md"
  mk_agent "$P/dev-orchestrator/AGENT.md" vibeflow-head "All tools" "$BLK_HEAD"
  mk_agent "$P/dev-orchestrator/agents/vf-dev-manager.md" vf-dev-manager \
    "Read, TaskStop, Agent(vf-coder, vf-reviewer, vf-auditer, general-purpose, gsd-planner)" "$BLK_WORKER" "$BLK_MANAGER"
  mk_agent "$P/design-orchestrator/agents/vf-design-manager.md" vf-design-manager \
    "Read, TaskStop, Agent(vf-crafter, vf-design-judge, vf-coder)" "$BLK_WORKER" "$BLK_MANAGER"
  mk_agent "$P/mobile-test-team/agents/vf-test-orchestrator.md" vf-test-orchestrator \
    "Read, TaskStop, Agent(vf-test-runner, vf-app-fixer)" "$BLK_WORKER" "$BLK_MANAGER"
  mk_agent "$P/content-bundle/agents/vf-content-manager.md" vf-content-manager "Read, TaskStop" "$BLK_WORKER" "$BLK_MANAGER"
  mk_agent "$P/business-pilot-bundle/agents/vf-business-manager.md" vf-business-manager "Read, TaskStop" "$BLK_WORKER" "$BLK_MANAGER"
  mk_agent "$P/growth-bundle/agents/vf-growth-manager.md" vf-growth-manager "Read, TaskStop" "$BLK_WORKER" "$BLK_MANAGER"
  mk_agent "$P/product-team-bundle/agents/vf-product-manager.md" vf-product-manager \
    "Read, TaskStop, Agent(prd-gate)" "$BLK_WORKER" "$BLK_MANAGER"
  mk_agent "$P/dev-orchestrator/agents/vf-coder.md" vf-coder "Read, TaskStop" "$BLK_WORKER"
  mk_agent "$P/dev-orchestrator/agents/vf-reviewer.md" vf-reviewer "Read, TaskStop" "$BLK_WORKER"
  mk_agent "$P/dev-orchestrator/agents/vf-auditer.md" vf-auditer "Read, TaskStop" "$BLK_WORKER"
  mk_agent "$P/design-orchestrator/agents/vf-crafter.md" vf-crafter "Read, TaskStop" "$BLK_WORKER"
  mk_agent "$P/design-orchestrator/agents/vf-design-judge.md" vf-design-judge "Read, TaskStop" "$BLK_WORKER"
  mk_agent "$P/mobile-test-team/agents/vf-test-runner.md" vf-test-runner "Read, TaskStop" "$BLK_WORKER"
  mk_agent "$P/mobile-test-team/agents/vf-app-fixer.md" vf-app-fixer "Read, TaskStop" "$BLK_WORKER"
  mk_agent "$P/product-team-bundle/agents/prd-gate.md" prd-gate "Read, TaskStop" "$BLK_WORKER"
}

# mutant NOM : copie de la fixture conforme dans $TMP/m-NOM (stdout = chemin)
new_mutant() { rm -rf "$TMP/m-$1"; cp -R "$TMP/fx" "$TMP/m-$1"; echo "$TMP/m-$1"; }
sedf() { local f="$1"; shift; sed "$@" "$f" > "$f.n" && mv "$f.n" "$f"; }

# expect_red NOM ROOT MOTIF... : rouge, et chaque motif (littéral) figure dans la sortie
expect_red() {
  local name="$1" root="$2" m miss=""
  shift 2
  if check_root "$root"; then ko "$name" "rouge" "vert"; return; fi
  for m in "$@"; do
    case "$VIOL" in *"$m"*) : ;; *) miss="$miss [$m]" ;; esac
  done
  if [ -z "$miss" ]; then ok "$name"; else ko "$name" "motifs:$*" "manquants:$miss / sortie: $(echo "$VIOL" | head -3 | tr '\n' '|')"; fi
}

# ====================================================================================
echo "== témoin positif : fixture conforme =="
mk_fixture "$TMP/fx"
if check_root "$TMP/fx"; then ok "fixture conforme → verte, aucune violation"; else ko "fixture conforme → verte" "vert" "$VIOL"; fi

echo "== mutants (chacun rouge pour SA raison) =="
M="$(new_mutant w-bloc)"
sedf "$M/plugin/dev-orchestrator/agents/vf-coder.md" '/\*\*Fin de mandat\*\*/,/§Fin de mandat/d'
expect_red "m1: bloc worker supprimé (vf-coder)" "$M" "vf-coder.md: étiquette **Fin de mandat** absente"

M="$(new_mutant w-jeton)"
sedf "$M/plugin/design-orchestrator/agents/vf-crafter.md" 's/échéance/délai/'
expect_red "m2: jeton « échéance » retiré du bloc worker (vf-crafter)" "$M" "vf-crafter.md: jeton « échéance » absent du bloc **Fin de mandat**"
case "$VIOL" in *"jeton « premier plan »"*) ko "m2b: un seul jeton signalé" "1" "plusieurs" ;; *) ok "m2b: seul le jeton retiré est signalé" ;; esac

M="$(new_mutant w-deplace)"
sedf "$M/plugin/mobile-test-team/agents/vf-test-runner.md" 's/avec une échéance//'
printf '\néchéance (hors du bloc)\n' >> "$M/plugin/mobile-test-team/agents/vf-test-runner.md"
expect_red "m3: jeton déplacé hors du bloc (vf-test-runner)" "$M" "vf-test-runner.md: jeton « échéance » absent du bloc **Fin de mandat**"

M="$(new_mutant w-fm)"
sedf "$M/plugin/product-team-bundle/agents/prd-gate.md" 's/^tools: Read, TaskStop$/tools: Read, TaskStop, jamais en attente, premier plan, échéance, processus, même tour, §Fin de mandat/'
sedf "$M/plugin/product-team-bundle/agents/prd-gate.md" '/\*\*Fin de mandat\*\*/,/§Fin de mandat).$/d'
expect_red "m4: jetons seulement dans le frontmatter ne comptent pas (prd-gate)" "$M" "prd-gate.md: étiquette **Fin de mandat** absente"

M="$(new_mutant m-bloc)"
sedf "$M/plugin/growth-bundle/agents/vf-growth-manager.md" '/\*\*Clôture des workers\*\*/,/§Fin de mandat/d'
expect_red "m5: bloc manager supprimé (vf-growth-manager)" "$M" "vf-growth-manager.md: étiquette **Clôture des workers** absente"

M="$(new_mutant m-sans-worker)"
sedf "$M/plugin/content-bundle/agents/vf-content-manager.md" '/\*\*Fin de mandat\*\*/,/§Fin de mandat/d'
expect_red "m5b: un manager sans le bloc worker est rouge" "$M" "vf-content-manager.md: étiquette **Fin de mandat** absente"

M="$(new_mutant h-msg)"
sedf "$M/plugin/dev-orchestrator/AGENT.md" 's/dernier message/dernier retour/'
expect_red "m6: « dernier message » retiré du head" "$M" "plugin/dev-orchestrator/AGENT.md: jeton « dernier message » absent du bloc **Balayage de sortie**"

M="$(new_mutant h-bloc)"
sedf "$M/plugin/dev-orchestrator/AGENT.md" '/\*\*Balayage de sortie\*\*/,/§Fin de mandat/d'
expect_red "m6b: bloc head supprimé" "$M" "plugin/dev-orchestrator/AGENT.md: étiquette **Balayage de sortie** absente"

M="$(new_mutant deriv-a)"
mk_agent "$M/plugin/dev-orchestrator/agents/vf-extra.md" vf-extra "Read, TaskStop"
sedf "$M/plugin/dev-orchestrator/agents/vf-dev-manager.md" 's/Agent(vf-coder,/Agent(vf-extra, vf-coder,/'
expect_red "m7: agent nommé dans un Agent(...) de manager, sans bloc (dérivation a)" "$M" "vf-extra.md: étiquette **Fin de mandat** absente"

M="$(new_mutant deriv-b)"
mk_agent "$M/plugin/growth-bundle/agents/vf-stray.md" vf-stray "Read" "Voir la Fin de tour inerte du kernel."
expect_red "m8: agent hors plancher mentionnant « Fin de tour inerte » (dérivation b)" "$M" "vf-stray.md: mentionne" "hors population"

M="$(new_mutant kernel)"
sedf "$M/plugin/conductor/references/team-kernel.md" 's/^## Fin de mandat/## Fin du mandat/'
expect_red "m9: section team-kernel renommée" "$M" "team-kernel.md: section « ## Fin de mandat » absente"

M="$(new_mutant absent)"
rm -f "$M/plugin/product-team-bundle/agents/prd-gate.md"
expect_red "m10: membre du plancher absent (prd-gate)" "$M" "prd-gate: membre du plancher (worker) introuvable"

M="$(new_mutant vide)"
rm -rf "$M/plugin/dev-orchestrator" "$M/plugin/mobile-test-team"
expect_red "m11: arbre sans dossiers d'agents → rouge, jamais vert à vide" "$M" "AGENT.md: membre du plancher (head) introuvable" "vf-coder: membre du plancher (worker) introuvable"

# ====================================================================================
echo "== arbre réel =="
REAL="${FIN_DE_MANDAT_ROOT:-}"
[ -z "$REAL" ] && REAL="$(find_repo_root)"
if [ -z "$REAL" ] || [ ! -d "$REAL/plugin" ]; then
  ko "racine du dépôt résolue" "dossier avec plugin/" "introuvable"
else
  t0=$SECONDS
  if check_root "$REAL"; then
    ok "arbre réel ($REAL) : doctrine « Fin de mandat » portée par toute la population"
  else
    ko "arbre réel ($REAL)" "aucune violation" "$(printf '%s' "$VIOL" | grep -c .) violation(s)"
    printf '%s' "$VIOL" | sed 's/^/      - /'
  fi
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
