#!/usr/bin/env bash
# test-fin-de-mandat.sh — Garde machine de la doctrine « Fin de mandat » (issue #223).
#
# Défaut gardé : des workers d'équipe restent vivants après leur travail (rejeu en tâche de fond,
# tour rendu « en attente » jamais réveillé, travail non commité) et des managers rendent la main
# sans clore leurs enfants. La consigne existait en prose ; rien ne gardait qu'un prompt la porte.
#
# Contrat D3 (v3) :
#   - team-kernel.md porte une section `## Fin de mandat` ;
#   - tout WORKER porte l'étiquette `**Fin de mandat**` et, DANS son bloc, les jetons « aucune main
#     rendue en attente », « premier plan », « échéance », « processus », « même tour »,
#     « id de tâche », « par PID », « §Fin de mandat » ;
#   - tout MANAGER porte ce bloc worker ET `**Clôture des workers**` (TaskStop, owned by, balayage,
#     worktree-procs.sh, worktree secondaire, arbre partagé, checkout principal, aucun enfant vivant, orphans, consigne
#     de reprise, §Fin de mandat), avec la première occurrence de `TaskStop` AVANT la première de `close` ;
#   - le HEAD (plugin/dev-orchestrator/AGENT.md) porte `**Balayage de sortie**` (orphans, dernier
#     message, TaskStop, worktree-procs.sh, worktree secondaire, checkout principal, autre mission, §Fin de mandat).
# Étiquette : reconnue en DÉBUT DE LIGNE (après une puce ou une numérotation éventuelle), jamais au
# milieu d'une phrase ; première occurrence gagne. Bloc = cette ligne + ses continuations, jusqu'à
# ligne vide, nouvelle puce, nouvelle étiquette `**` (indentée ou non) ou titre. Sont ignorés pour la
# recherche d'étiquette et de jetons : le frontmatter (un jeton de la ligne `tools:` ne compte pas),
# les blocs de code ``` … ``` et les commentaires HTML <!-- … --> (mono- ou multi-ligne).
#
# Population = plancher nommé + DÉRIVATION (une liste de cas ne ferme pas une classe) :
#   managers du plancher : vf-dev-manager vf-design-manager vf-test-orchestrator vf-content-manager
#     vf-business-manager vf-growth-manager vf-product-manager ;
#   workers du plancher : vf-coder vf-reviewer vf-auditer vf-crafter vf-design-judge vf-test-runner
#     vf-app-fixer prd-gate ; head : plugin/dev-orchestrator/AGENT.md.
#   (a) MANAGERS dérivés : tout plugin/*/agents/*.md hors plancher worker dont l'allowlist `Agent(...)`
#       nomme au moins un agent présent sous plugin/*/agents est un manager exigé (blocs worker + manager) ;
#   (b) WORKERS dérivés : tout agent de plugin/*/agents nommé dans l'allowlist `Agent(...)` d'un manager
#       (plancher ou dérivé), qui n'est pas lui-même manager ET qui a `Bash` ou `Agent` dans son `tools:`
#       (ou pas de ligne `tools:`, donc tous les outils) : sans l'un ni l'autre il ne peut pas avoir de
#       tâche de fond, il reste hors population sauf s'il cite la doctrine (c) ;
#   (c) tout plugin/*/agents/*.md ou plugin/*/AGENT.md qui mentionne « Fin de tour inerte » ou « Fin de
#       mandat » (insensible à la casse, espaces et retours à la ligne normalisés) doit appartenir à la
#       population.
# L'allowlist se lit dans `tools:` en ligne OU en liste YAML multiligne, TOUTES les occurrences d'`Agent(`.
# Les plugin/*/AGENT.md (agents incarnés en session principale) restent HORS dérivation (a) et (b) :
# seul le head nommé est exigé ; la règle (c) les rattrape s'ils citent la doctrine.
# Un membre du plancher introuvable sur disque = rouge (jamais un vert à vide).
#
# Preuves de rouge : (1) fixture conforme verte ; (2) 38 cas de base (m1..m11 avec m2b, m5b, m6b ; o1, n1..n3, x2..x4 ; c1a..c5e, 17 cas),
# 4 cas du budget d'instructions (b1, b2, b2b, b3), chacun rouge ou vert pour SA raison, message vérifié ;
# (3) 12 « méta-mutants » : une copie de CETTE suite dont on retire un correctif (ligne repérée par
# un jeton `FDM-…` en fin de ligne) doit rougir sur le cas qui le garde.
#
# Hermétique : fixtures sous un mktemp -d détruit par trap. FIN_DE_MANDAT_ROOT vise une autre racine
# (preuve sur arbre-copie). FDM_META / FDM_ONLY / FDM_BUDGET_ROOT : usage interne des méta-mutants.
# bash 3.2 / GNU / uutils, aucune dépendance à rtk.
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
WORKER_TOKENS='aucune main rendue en attente
premier plan
échéance
processus
même tour
id de tâche
par PID
§Fin de mandat'
MANAGER_TOKENS='TaskStop
owned by
balayage
worktree-procs.sh
worktree secondaire
arbre partagé
checkout principal
aucun enfant vivant
orphans
consigne de reprise
§Fin de mandat'
HEAD_TOKENS='orphans
dernier message
TaskStop
worktree-procs.sh
worktree secondaire
autre mission
checkout principal
§Fin de mandat'

# extract_block FILE LABEL → bloc sur stdout (vide si l'étiquette est absente).
# Ignorés : frontmatter, blocs ``` … ```, commentaires HTML (mono- ou multi-ligne).
extract_block() {
  awk -v lab="$2" '
    function strip_comments(s,   out, i, j) {
      out = ""
      while (length(s) > 0) {
        if (incom) {
          j = index(s, "-->")
          if (j == 0) return out
          s = substr(s, j + 3); incom = 0
        } else {
          i = index(s, "<!--")
          if (i == 0) { out = out s; return out }
          out = out substr(s, 1, i - 1)
          s = substr(s, i + 4); incom = 1
        }
      }
      return out
    }
    NR==1 && $0=="---" { infm=1; next }
    infm { if ($0=="---") infm=0; next }
    {
      raw = $0
      t = raw; sub(/^[ \t]+/, "", t)
      if (!incom && t ~ /^```/) { infence = !infence; next }
      if (infence) next # FDM-P1F
      line = strip_comments(raw) # FDM-P1C
      if (line != raw && line ~ /^[ \t]*$/) next
      if (!inb) {
        if (done) next
        rest = line
        sub(/^[ \t]*(([-*+]|[0-9]+[.)])[ \t]+)?/, "", rest)
        if (index(rest, lab) == 1) { inb=1; done=1; print line } # FDM-P3
        next
      }
      if (line ~ /^[ \t]*$/) exit
      if (line ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]/) exit
      if (line ~ /^[ \t]*\*\*/) exit # FDM-P2
      if (line ~ /^#/) exit
      print line
    }' "$1"
}

# allowlists FILE... → lignes « chemin<TAB>nom » : TOUTES les occurrences Agent(...) de `tools:` (ligne
# ou liste YAML), plus « chemin<TAB>@exec » si l'agent a Bash ou Agent (ou pas de ligne `tools:`).
allowlists() {
  awk '
    function flush(   s, n, arr, i) {
      if (fn == "") return
      if (!seen || buf ~ /(^|[^A-Za-z_])(Bash|Agent)([^A-Za-z_]|$)/) print fn "\t@exec"
      while (match(buf, /Agent\([^)]*\)/)) { # FDM-P5A
        s = substr(buf, RSTART+6, RLENGTH-7); gsub(/[ \t]/, "", s)
        n = split(s, arr, ",")
        for (i = 1; i <= n; i++) if (arr[i] != "") print fn "\t" arr[i]
        buf = substr(buf, RSTART+RLENGTH)
      }
    }
    FNR==1 { flush(); fn=FILENAME; infm=($0=="---"); on=0; seen=0; ended=0; buf=""; next }
    ended { next }
    infm {
      if ($0=="---") { infm=0; ended=1; next }
      if ($0 ~ /^tools:/) { on=1; seen=1; buf = buf " " $0; next }
      if (on && ($0 ~ /^[ \t]/ || $0 ~ /^-/)) { buf = buf " " $0; next } # FDM-P5L
      if ($0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:/) on=0
    }
    END { flush() }' "$@"
}

find_agent() { # ROOT NAME → chemin
  local f
  for f in "$1"/plugin/*/agents/"$2".md; do
    [ -f "$f" ] && { echo "$f"; return 0; }
  done
  return 1
}

# doctrine_mentions FILE... → chemins des fichiers qui mentionnent « Fin de tour inerte » / « Fin de mandat »,
# casse, tabulations, retours à la ligne et espaces multiples normalisés (un seul awk pour tous les fichiers).
doctrine_mentions() {
  awk '
    function flush(   s) {
      if (fn == "") return
      s = tolower(buf) # FDM-P4I
      gsub(/[ \t]+/, " ", s) # FDM-P4S
      if (index(s, "fin de tour inerte") || index(s, "fin de mandat")) print fn
    }
    FNR==1 { flush(); fn=FILENAME; buf="" }
    { buf = buf " " $0 } # FDM-P4W
    END { flush() }' "$@"
}

VIOL=""
DERIVED_MGR=""
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
  if [ "$3" = "$MANAGER_LABEL" ]; then
    case "$block" in
      *TaskStop*)
        case "${block%%TaskStop*}" in *close*) viol "$rel: dans le bloc $3, « close » précède la première occurrence de « TaskStop »" ;; esac # FDM-O1
        ;;
    esac
  fi
}

# check_root ROOT : remplit VIOL et DERIVED_MGR ; rc 1 si au moins une violation.
check_root() {
  local R="$1" n p kernel MENT="" POP="" DERIVED="" WORKERS="" MANAGERS="" DMGR="" EXEC="" w a name ap an ALLOW=""
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

  set -- "$R"/plugin/*/agents/*.md
  if [ -f "$1" ]; then ALLOW="$(allowlists "$@")"; fi

  # dérivation (a) : managers hors plancher worker dont l'allowlist nomme un agent présent sur disque ;
  # relève aussi les agents capables de tâche de fond (@exec)
  while IFS=$'\t' read -r ap an; do
    [ -z "$ap" ] && continue
    name="${ap##*/}"; name="${name%.md}"
    if [ "$an" = "@exec" ]; then EXEC="$EXEC $name"; continue; fi
    case " $FLOOR_WORKERS $FLOOR_MANAGERS$DMGR " in *" $name "*) continue ;; esac
    if find_agent "$R" "$an" >/dev/null 2>&1; then
      DMGR="$DMGR $name" # FDM-P5M
    fi
  done <<EOF
$ALLOW
EOF
  DERIVED_MGR="$DMGR"
  MANAGERS="$FLOOR_MANAGERS$DMGR"

  for n in $MANAGERS; do
    if ! p="$(find_agent "$R" "$n")"; then
      viol "$n: membre du plancher (manager) introuvable sous plugin/*/agents/"
      continue
    fi
    POP="${POP}$p"$'\n'
    check_block "$R" "$p" "$WORKER_LABEL" "$WORKER_TOKENS"
    check_block "$R" "$p" "$MANAGER_LABEL" "$MANAGER_TOKENS"
  done
  while IFS=$'\t' read -r ap an; do
    case "$an" in ""|@*) continue ;; esac
    name="${ap##*/}"; name="${name%.md}"
    case " $MANAGERS " in *" $name "*) DERIVED="$DERIVED $an" ;; esac
  done <<EOF
$ALLOW
EOF

  # dérivation (b) : workers nommés dans l'allowlist d'un manager ET capables de tâche de fond
  WORKERS="$FLOOR_WORKERS"
  for a in $DERIVED; do
    case " $MANAGERS " in *" $a "*) continue ;; esac
    case " $WORKERS " in *" $a "*) continue ;; esac
    case " $EXEC " in *" $a "*) : ;; *) continue ;; esac # FDM-P6X
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

  # (c) : qui parle de la doctrine doit être de la population
  set --
  for p in "$R"/plugin/*/agents/*.md "$R"/plugin/*/AGENT.md; do
    [ -f "$p" ] && set -- "$@" "$p"
  done
  MENT=""
  if [ $# -gt 0 ]; then MENT="$(doctrine_mentions "$@")"; fi
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    case "
$POP" in
      *"
$p
"*) : ;;
      *) viol "${p#$R/}: mentionne « Fin de tour inerte » / « Fin de mandat » mais hors population (ni plancher, ni allowlist d'un manager)" ;;
    esac
  done <<EOF
$MENT
EOF

  [ -z "$VIOL" ]
}

# --- fixture conforme minimale ---
BLK_WORKER='- **Fin de mandat** : aucune main rendue en attente d'"'"'une tâche de fond, attente au premier plan
  avec une échéance ; aucun processus vivant au rapport, dans le même tour, id de tâche rendu sinon, arrêt par PID (§Fin de mandat).'
BLK_MANAGER='- **Clôture des workers** : TaskStop sur chaque enfant (owned by le mandat), puis close au registre ;
  balayage via worktree-procs.sh, worktree secondaire ou arbre partagé, hors du checkout principal,
  aucun enfant vivant ; orphans signalés, consigne de reprise écrite (§Fin de mandat).'
BLK_HEAD='- **Balayage de sortie** : orphans repérés au dernier message de chaque worker, TaskStop,
  worktree-procs.sh sur tout worktree secondaire, hors checkout principal, sans toucher une autre mission (§Fin de mandat).'

mk_agent() { # FILE NAME TOOLS [BLOCS...]
  local f="$1" name="$2" tools="$3" b
  mkdir -p "${f%/*}"
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

# new_mutant NOM : copie de la fixture conforme dans $TMP/m-NOM (stdout = chemin).
# Avec FDM_ONLY=<nom> (méta-mutants), tout autre cas est sauté : racine factice, expect_* muets.
new_mutant() {
  if [ -n "${FDM_ONLY:-}" ] && [ "$1" != "$FDM_ONLY" ]; then mkdir -p "$TMP/skip"; echo "$TMP/skip"; return; fi
  rm -rf "$TMP/m-$1"; cp -R "$TMP/fx" "$TMP/m-$1"; echo "$TMP/m-$1"
}
sedf() { local f="$1"; shift; [ -f "$f" ] || return 0; sed "$@" "$f" > "$f.n" && mv "$f.n" "$f"; }

# expect_red NOM ROOT MOTIF... : rouge, et chaque motif (littéral) figure dans la sortie
expect_red() {
  local name="$1" root="$2" m miss=""
  [ "$root" = "$TMP/skip" ] && return 0
  shift 2
  if check_root "$root"; then ko "$name" "rouge" "vert"; return; fi
  for m in "$@"; do
    case "$VIOL" in *"$m"*) : ;; *) miss="$miss [$m]" ;; esac
  done
  if [ -z "$miss" ]; then ok "$name"; else ko "$name" "motifs:$*" "manquants:$miss / sortie: $(echo "$VIOL" | head -3 | tr '\n' '|')"; fi
}
expect_green() { # NOM ROOT
  [ "$2" = "$TMP/skip" ] && return 0
  if check_root "$2"; then ok "$1"; else ko "$1" "vert" "$(echo "$VIOL" | head -3 | tr '\n' '|')"; fi
}

BT='```'
# ====================================================================================
echo "== témoin positif : fixture conforme =="
mk_fixture "$TMP/fx"
if check_root "$TMP/fx"; then ok "fixture conforme → verte, aucune violation"; else ko "fixture conforme → verte" "vert" "$VIOL"; fi

if [ -z "${FDM_META:-}" ]; then
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
sedf "$M/plugin/product-team-bundle/agents/prd-gate.md" 's/^tools: Read, TaskStop$/tools: Read, TaskStop, aucune main rendue en attente, premier plan, échéance, processus, même tour, §Fin de mandat/'
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
mk_agent "$M/plugin/dev-orchestrator/agents/vf-extra.md" vf-extra "Read, Bash"
sedf "$M/plugin/dev-orchestrator/agents/vf-dev-manager.md" 's/Agent(vf-coder,/Agent(vf-extra, vf-coder,/'
expect_red "m7: agent AVEC Bash nommé dans un Agent(...) de manager, sans bloc → rouge" "$M" "vf-extra.md: étiquette **Fin de mandat** absente"

M="$(new_mutant deriv-b)"
mk_agent "$M/plugin/growth-bundle/agents/vf-stray.md" vf-stray "Read" "Voir la Fin de tour inerte du kernel."
expect_red "m8: agent hors plancher mentionnant « Fin de tour inerte » (règle c)" "$M" "vf-stray.md: mentionne" "hors population"

M="$(new_mutant kernel)"
sedf "$M/plugin/conductor/references/team-kernel.md" 's/^## Fin de mandat/## Fin du mandat/'
expect_red "m9: section team-kernel renommée" "$M" "team-kernel.md: section « ## Fin de mandat » absente"

M="$(new_mutant absent)"
rm -f "$M/plugin/product-team-bundle/agents/prd-gate.md"
expect_red "m10: membre du plancher absent (prd-gate)" "$M" "prd-gate: membre du plancher (worker) introuvable"

M="$(new_mutant vide)"
rm -rf "$M/plugin/dev-orchestrator" "$M/plugin/mobile-test-team"
expect_red "m11: arbre sans dossiers d'agents → rouge, jamais vert à vide" "$M" "AGENT.md: membre du plancher (head) introuvable" "vf-coder: membre du plancher (worker) introuvable"
fi

# ====================================================================================
echo "== contrat v3 : ordre TaskStop/close et population par outils =="
M="$(new_mutant o1)"
sedf "$M/plugin/dev-orchestrator/agents/vf-dev-manager.md" 's/TaskStop sur chaque enfant/close du registre puis TaskStop sur chaque enfant/'
expect_red "o1: « close » avant « TaskStop » dans le bloc manager → rouge" "$M" "vf-dev-manager.md: dans le bloc **Clôture des workers**, « close » précède la première occurrence de « TaskStop »"
M="$(new_mutant x2)"
mk_agent "$M/plugin/dev-orchestrator/agents/vf-quiet.md" vf-quiet "Read, TaskStop"
sedf "$M/plugin/dev-orchestrator/agents/vf-dev-manager.md" 's/Agent(vf-coder,/Agent(vf-quiet, vf-coder,/'
expect_green "x2: agent dérivé SANS Bash ni Agent, sans bloc → vert (pas de tâche de fond possible)" "$M"
M="$(new_mutant x3)"
mk_agent "$M/plugin/dev-orchestrator/agents/vf-agt.md" vf-agt "Read, Agent(general-purpose)"
sedf "$M/plugin/dev-orchestrator/agents/vf-dev-manager.md" 's/Agent(vf-coder,/Agent(vf-agt, vf-coder,/'
expect_red "x3: agent dérivé avec Agent (sans Bash), sans bloc → rouge" "$M" "vf-agt.md: étiquette **Fin de mandat** absente"
M="$(new_mutant x4)"
mk_agent "$M/plugin/dev-orchestrator/agents/vf-notools.md" vf-notools "" 
sed '/^tools:/d' "$M/plugin/dev-orchestrator/agents/vf-notools.md" > "$M/n" && mv "$M/n" "$M/plugin/dev-orchestrator/agents/vf-notools.md"
sedf "$M/plugin/dev-orchestrator/agents/vf-dev-manager.md" 's/Agent(vf-coder,/Agent(vf-notools, vf-coder,/'
expect_red "x4: agent dérivé sans ligne tools: (tous les outils), sans bloc → rouge" "$M" "vf-notools.md: étiquette **Fin de mandat** absente"
M="$(new_mutant n1)"
sedf "$M/plugin/design-orchestrator/agents/vf-crafter.md" 's/par PID/par signal/'
expect_red "n1: jeton « par PID » retiré du bloc worker → rouge" "$M" "vf-crafter.md: jeton « par PID » absent du bloc **Fin de mandat**"
M="$(new_mutant n2)"
sedf "$M/plugin/growth-bundle/agents/vf-growth-manager.md" 's/hors du checkout principal/hors du dépôt/'
expect_red "n2: jeton « checkout principal » retiré du bloc manager → rouge" "$M" "vf-growth-manager.md: jeton « checkout principal » absent du bloc **Clôture des workers**"
M="$(new_mutant n3)"
sedf "$M/plugin/dev-orchestrator/AGENT.md" 's/hors checkout principal/hors dépôt/'
expect_red "n3: jeton « checkout principal » retiré du bloc head → rouge" "$M" "plugin/dev-orchestrator/AGENT.md: jeton « checkout principal » absent du bloc **Balayage de sortie**"


# ====================================================================================
echo "== sondage de la revue adverse (c1..c5) =="
CODER="plugin/dev-orchestrator/agents/vf-coder.md"
BASE_LINE='- **Fin de mandat** : aucune main rendue en attente, au premier plan, processus, même tour, id de tâche, par PID (§Fin de mandat).'

# c1 : blocs de code et commentaires HTML
M="$(new_mutant c1a)"
mk_agent "$M/$CODER" vf-coder "Read, TaskStop" "$BT
$BLK_WORKER
$BT"
expect_red "c1a: bloc entier dans un bloc de code → étiquette absente" "$M" "vf-coder.md: étiquette **Fin de mandat** absente"
M="$(new_mutant c1b)"
mk_agent "$M/$CODER" vf-coder "Read, TaskStop" "$BASE_LINE
  $BT
  échéance
  $BT"
expect_red "c1b: jeton seulement dans un bloc de code du bloc → absent" "$M" "vf-coder.md: jeton « échéance » absent du bloc **Fin de mandat**"
M="$(new_mutant c1c)"
mk_agent "$M/$CODER" vf-coder "Read, TaskStop" "<!-- $BLK_WORKER -->"
expect_red "c1c: étiquette dans un commentaire HTML mono-ligne → absente" "$M" "vf-coder.md: étiquette **Fin de mandat** absente"
M="$(new_mutant c1d)"
mk_agent "$M/$CODER" vf-coder "Read, TaskStop" "<!--
$BLK_WORKER
-->"
expect_red "c1d: bloc dans un commentaire HTML multi-ligne → étiquette absente" "$M" "vf-coder.md: étiquette **Fin de mandat** absente"
M="$(new_mutant c1e)"
mk_agent "$M/$CODER" vf-coder "Read, TaskStop" "$BASE_LINE
  <!--
  échéance
  -->"
expect_red "c1e: jeton seulement dans un commentaire multi-ligne du bloc → absent" "$M" "vf-coder.md: jeton « échéance » absent du bloc **Fin de mandat**"

# c2 : étiquette d'une autre règle, indentée, dans le même paragraphe
M="$(new_mutant c2)"
mk_agent "$M/$CODER" vf-coder "Read, TaskStop" "$BASE_LINE
  **Autre règle** : échéance"
expect_red "c2: jeton porté par une autre règle indentée → absent du bloc" "$M" "vf-coder.md: jeton « échéance » absent du bloc **Fin de mandat**"

# c3 : mention en prose avant le vrai bloc, et étiquette nue / numérotée
M="$(new_mutant c3)"
mk_agent "$M/$CODER" vf-coder "Read, TaskStop" "Voir aussi **Fin de mandat** dans le kernel." "$BLK_WORKER"
expect_green "c3: mention en prose de l'étiquette avant le vrai bloc → vert" "$M"
M="$(new_mutant c3b)"
mk_agent "$M/$CODER" vf-coder "Read, TaskStop" "1. ${BLK_WORKER#- }"
mk_agent "$M/plugin/dev-orchestrator/agents/vf-reviewer.md" vf-reviewer "Read, TaskStop" "${BLK_WORKER#- }"
expect_green "c3b: étiquette numérotée ou nue en début de ligne → verte" "$M"

# c4 : règle (c) insensible à la casse, aux espaces et aux retours à la ligne
M="$(new_mutant c4a)"
mk_agent "$M/plugin/growth-bundle/agents/vf-stray.md" vf-stray "Read" "voir la FIN DE MANDAT du kernel."
expect_red "c4a: mention en majuscules hors population" "$M" "vf-stray.md: mentionne"
M="$(new_mutant c4b)"
mk_agent "$M/plugin/growth-bundle/agents/vf-stray.md" vf-stray "Read" "voir la Fin  de   mandat du kernel."
expect_red "c4b: mention à espaces multiples hors population" "$M" "vf-stray.md: mentionne"
M="$(new_mutant c4c)"
mk_agent "$M/plugin/growth-bundle/agents/vf-stray.md" vf-stray "Read" "voir la Fin de
mandat du kernel."
expect_red "c4c: mention coupée par un retour à la ligne hors population" "$M" "vf-stray.md: mentionne"

# c5 : allowlist en liste YAML, plusieurs Agent(, managers dérivés
M="$(new_mutant c5a)"
mk_agent "$M/plugin/growth-bundle/agents/vf-growth-manager.md" vf-growth-manager "
  - Read
  - Agent(vf-extra2)" "$BLK_WORKER" "$BLK_MANAGER"
mk_agent "$M/plugin/growth-bundle/agents/vf-extra2.md" vf-extra2 "Read, Bash"
expect_red "c5a: allowlist en liste YAML multiligne lue" "$M" "vf-extra2.md: étiquette **Fin de mandat** absente"
M="$(new_mutant c5b)"
mk_agent "$M/plugin/growth-bundle/agents/vf-growth-manager.md" vf-growth-manager "Agent(vf-coder), Read, Agent(vf-extra3)" "$BLK_WORKER" "$BLK_MANAGER"
mk_agent "$M/plugin/growth-bundle/agents/vf-extra3.md" vf-extra3 "Read, Bash"
expect_red "c5b: seconde occurrence Agent( lue" "$M" "vf-extra3.md: étiquette **Fin de mandat** absente"
M="$(new_mutant c5b2)"
mk_agent "$M/plugin/growth-bundle/agents/vf-growth-manager.md" vf-growth-manager "Agent(vf-extra4), Read, Agent(vf-coder)" "$BLK_WORKER" "$BLK_MANAGER"
mk_agent "$M/plugin/growth-bundle/agents/vf-extra4.md" vf-extra4 "Read, Bash"
expect_red "c5b2: première occurrence Agent( lue (pas seulement la dernière)" "$M" "vf-extra4.md: étiquette **Fin de mandat** absente"
M="$(new_mutant c5c)"
mk_agent "$M/plugin/growth-bundle/agents/vf-submgr.md" vf-submgr "Read, Agent(vf-coder)"
expect_red "c5c: manager dérivé (hors plancher) sans blocs → rouge" "$M" "vf-submgr.md: étiquette **Clôture des workers** absente" "vf-submgr.md: étiquette **Fin de mandat** absente"
M="$(new_mutant c5d)"
mk_agent "$M/plugin/growth-bundle/agents/vf-submgr.md" vf-submgr "Read, Agent(vf-coder)" "$BLK_WORKER" "$BLK_MANAGER"
expect_green "c5d: manager dérivé qui porte ses deux blocs → vert" "$M"
M="$(new_mutant c5e)"
mk_agent "$M/plugin/growth-bundle/agents/vf-solo.md" vf-solo "Read, Agent(general-purpose, gsd-planner)"
expect_green "c5e: allowlist ne nommant que des agents hors plugin → pas un manager" "$M"

# ====================================================================================
# Budget d'instructions : les blocs de la fixture conforme ne déclenchent AUCUN marqueur de
# check-instruction-budget.sh (motif lu dans le script, jamais recopié ; insensible à la casse comme
# lui). Appliqué à la fixture seulement : sur l'arbre réel, c'est le gate de budget qui juge.
# Les méta-mutants (FDM_META) sautent cette section et l'arbre réel.
BUDGET_ROOT="${FDM_BUDGET_ROOT:-$(find_repo_root)}"
if [ -z "${FDM_META:-}" ]; then
echo "== blocs de la fixture et marqueurs du budget d'instructions =="
BUDGET_SH="$BUDGET_ROOT/plugin/conductor/scripts/check-instruction-budget.sh"
MARKER_RE="$(sed -n "s/^MARKER_RE='\(.*\)'\$/\1/p" "$BUDGET_SH" 2>/dev/null | head -1)"

# marker_hits ROOT : lignes de blocs (worker, manager, head) qui matchent MARKER_RE, sur toute la fixture
marker_hits() {
  local f lab blk
  for f in "$1"/plugin/*/agents/*.md "$1"/plugin/*/AGENT.md; do
    [ -f "$f" ] || continue
    for lab in "$WORKER_LABEL" "$MANAGER_LABEL" "$HEAD_LABEL"; do
      blk="$(extract_block "$f" "$lab" | tr '[:upper:]' '[:lower:]')"
      if grep -Eq -e "$MARKER_RE" <<<"$blk"; then echo "${f#$1/}: $lab"; fi
    done
  done
}

if [ -z "$MARKER_RE" ]; then
  ko "MARKER_RE lu depuis check-instruction-budget.sh" "motif non vide" "introuvable ($BUDGET_SH)"
else
  H="$(marker_hits "$TMP/fx")"
  if [ -z "$H" ]; then ok "b1: aucune ligne de bloc de la fixture conforme ne matche MARKER_RE"; else ko "b1: fixture sans marqueur" "aucune ligne" "$H"; fi
  M="$(new_mutant b-jamais)"
  sedf "$M/plugin/dev-orchestrator/agents/vf-coder.md" 's/au rapport/jamais au rapport/'
  H="$(marker_hits "$M")"
  case "$H" in
    *"vf-coder.md: **Fin de mandat**"*) ok "b2: « jamais » remis dans un bloc → le cas rougit (vf-coder)" ;;
    *) ko "b2: mutant « jamais » dans un bloc" "rouge sur vf-coder" "[$H]" ;;
  esac
  check_root "$M" && ok "b2b: ce mutant reste vert pour la garde de jetons (seul le budget le voit)" || ko "b2b" "vert" "$VIOL"
  M="$(new_mutant b-doit)"
  sedf "$M/plugin/dev-orchestrator/AGENT.md" 's/orphans repérés/Il DOIT voir les orphans repérés/'
  H="$(marker_hits "$M")"
  case "$H" in
    *"plugin/dev-orchestrator/AGENT.md: **Balayage de sortie**"*) ok "b3: marqueur en majuscules dans le bloc head → rouge (insensible à la casse)" ;;
    *) ko "b3: mutant « DOIT » dans le head" "rouge" "[$H]" ;;
  esac
fi

# ====================================================================================
# Méta-mutants : une copie de CETTE suite dont on retire un correctif doit rougir sur le cas qui le
# garde. Lancés en parallèle (wait borné) ; chaque copie ne rejoue que son cas (FDM_META, FDM_ONLY).
echo "== méta-mutants : retirer un correctif de la suite → le cas gardien rougit =="
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
: > "$TMP/meta.list"
meta() { # ID CAS SED... : mutation par sed sur la ligne à jeton FDM-ID
  local id="$1" cas="$2"; shift 2
  local cp="$TMP/meta-$id.sh"
  sed "$@" "$SELF" > "$cp"
  if cmp -s "$SELF" "$cp"; then ko "meta $id: mutation appliquée" "copie différente" "identique"; return; fi
  echo "$id|$cas" >> "$TMP/meta.list"
  ( FDM_META=1 FDM_ONLY="$cas" FDM_BUDGET_ROOT="$BUDGET_ROOT" bash "$cp" > "$TMP/meta-$id.out" 2>&1; echo $? > "$TMP/meta-$id.rc" ) &
}
meta P1F c1b "/# FDM-P1F\$/d"
meta P1C c1d "/# FDM-P1C\$/s/.*/      line = raw/"
meta P2  c2  "/# FDM-P2\$/d"
meta P3  c3  "/# FDM-P3\$/s/index(rest, lab) == 1/index(line, lab) > 0/"
meta P4I c4a "/# FDM-P4I\$/s/tolower(buf)/buf/"
meta P4S c4b "/# FDM-P4S\$/d"
meta P4W c4c "/# FDM-P4W\$/s/buf = buf \" \" \$0/buf = buf \$0/"
meta P5L c5a "/# FDM-P5L\$/s/if (on \&\&/if (0 \&\&/"
meta P5A c5b "/# FDM-P5A\$/s/while (match/if (match/"
meta P5M c5c "/# FDM-P5M\$/s/.*/      :/"
meta O1  o1  "/# FDM-O1\$/s/.*/        :/"
meta P6X x2  "/# FDM-P6X\$/d"
wait
while IFS='|' read -r id cas; do
  rc="$(cat "$TMP/meta-$id.rc" 2>/dev/null)"
  if [ "${rc:-0}" != "0" ] && grep -qF "✗ $cas:" "$TMP/meta-$id.out"; then
    ok "meta $id: correctif retiré → ✗ $cas (rc $rc)"
  else
    ko "meta $id: correctif retiré" "rc≠0 et ✗ $cas" "rc=${rc:-?} / $(grep -c '✗' "$TMP/meta-$id.out" 2>/dev/null) ✗"
  fi
done < "$TMP/meta.list"

# ====================================================================================
echo "== arbre réel =="
REAL="${FIN_DE_MANDAT_ROOT:-}"
[ -z "$REAL" ] && REAL="$(find_repo_root)"
if [ -z "$REAL" ] || [ ! -d "$REAL/plugin" ]; then
  ko "racine du dépôt résolue" "dossier avec plugin/" "introuvable"
else
  if check_root "$REAL"; then
    ok "arbre réel ($REAL) : doctrine « Fin de mandat » portée par toute la population"
  else
    ko "arbre réel ($REAL)" "aucune violation" "$(printf '%s' "$VIOL" | grep -c .) violation(s)"
    printf '%s' "$VIOL" | sed 's/^/      - /'
  fi
  echo "  managers dérivés (hors plancher) : ${DERIVED_MGR:-aucun}"
fi
fi

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
