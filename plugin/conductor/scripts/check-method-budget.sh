#!/usr/bin/env bash
# check-method-budget.sh — Budgets de méthode d'un lab (v2.67.0) : taille du fichier d'état,
# nombre de worktrees actifs, et RANGEMENT (ce qui a été créé et n'a plus de raison d'être : branches
# locales intégrées, stash sans propriétaire, mémoires d'agents hors git ou hors index, branches
# distantes intégrées de leur seul propriétaire). CONSTATE, ne corrige rien, ne supprime rien.
#
# Pourquoi : la trace d'un lab ne fait que s'accumuler si rien ne la borne. Mesuré sur un lab
# client après deux mois de missions : STATE.md à 195 Ko (1 406 lignes, un « Point du … » ajouté
# en tête à chaque mission, jamais retiré), 15 worktrees ouverts dont 7 déjà intégrés. Un STATE de
# cette taille n'est plus lu en entier par aucun agent, et chaque worktree oublié coûte un
# `pod install`, un Metro ou une question « quelle branche ? ». La doctrine existait déjà
# (planning-core bridge-memory : « STATE.md ne garde que le courant ») ; il lui manquait un seuil
# mesurable et un moment où on le mesure. Moment : la clôture de mission (mission-flow.md
# §Budgets de méthode), et à la demande.
#
# Budgets (surchargeables par l'environnement) :
#   VF_STATE_BUDGET_KB   taille max d'un STATE.md, en Ko (défaut 8)
#   VF_WORKTREE_BUDGET   worktrees actifs max par dépôt, hors arbre principal (défaut 3)
#
# Usage :
#   check-method-budget.sh [--root <dir>] [--repo <dir>]... [--strict] [--quiet]
#                          [--owner <login>]... [--no-remote]
#   --root   racine du lab (défaut .). STATE.md lus : <root>/.planning/STATE.md et celui de
#            chaque compartiment de workstream (énumérés par vf_ws_enumerate).
#   --repo   dépôt git dont compter les worktrees (répétable). Défaut : <root> s'il est un dépôt
#            git, sinon chaque sous-dossier direct de <root> qui en est un (lab multi-dépôts).
#   --strict un dépassement rend 1 (défaut : avertissement seul, rend 0).
#   --quiet  n'imprime que les dépassements et ce qui est rangeable.
#   --owner  login GitHub dont les branches distantes intégrées sont candidates (répétable ; défaut :
#            `gh api user --jq .login`). Une branche dont la PR est d'un autre auteur n'est JAMAIS
#            candidate (arbitrage Samuel, AskUserQuestion session principale, 2026-09-29 : jamais les
#            branches de Willy). Variable VF_BUDGET_GH : binaire gh à appeler (défaut gh).
#            Seules les refs du remote `origin` (celui dont origin/HEAD donne la base, et dont gh lit
#            les PR) sont examinées : la ref d'un autre remote (fork) n'est jamais candidate, même si
#            une PR du dépôt porte le même nom de branche. Une branche par défaut ou longue durée
#            (main, master, develop, dev, trunk, staging, production, release/*, ou base d'une PR
#            mergée) ne l'est jamais non plus.
#   --no-remote  ne consulte pas GitHub (aucun appel gh) : branches distantes non examinées.
#
# Sortie standard : une ligne par constat, préfixe [budget]. Pour chaque worktree actif, dit s'il
# est RANGEABLE (sa branche ou sa tête est déjà intégrée dans la branche de référence du dépôt) ou
# ORPHELIN (dossier disparu, `git worktree prune`). Jamais de suppression : ranger est un geste
# du manager ou de l'humain, sans --force, après vérification qu'aucune session ne s'en sert.
#
# Codes : 0 = dans les budgets, ou dépassement sans --strict · 1 = dépassement avec --strict ·
#         2 = non vérifiable avec --strict (compartiments de workstream illisibles, politique
#         introuvable, gh ou jq indisponible ou muet, stash illisible, branche de référence introuvable
#         ou orpheline, git for-each-ref en échec) — jamais un 0 de complaisance sous
#         --strict · 64 = argument invalide. Sous --strict, tout RANGEABLE et tout À VALIDER
#         compte comme un dépassement.
set -uo pipefail

ROOT="."
REPOS=()
STRICT=0
QUIET=0
NO_REMOTE=0
OWNERS=""
STATE_KB="${VF_STATE_BUDGET_KB:-8}"
WT_MAX="${VF_WORKTREE_BUDGET:-3}"

usage() { sed -n '/^# Usage :/,/^# Sortie standard/p' "$0" >&2; exit 64; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) [ "$#" -ge 2 ] || usage; ROOT="$2"; shift 2 ;;
    --repo) [ "$#" -ge 2 ] || usage; REPOS+=("$2"); shift 2 ;;
    --strict) STRICT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --owner) [ "$#" -ge 2 ] || usage; OWNERS="$OWNERS
$2"; shift 2 ;;
    --no-remote) NO_REMOTE=1; shift ;;
    -h|--help) usage ;;
    *) echo "[budget] argument inconnu : $1" >&2; usage ;;
  esac
done
case "$STATE_KB" in ''|*[!0-9]*) echo "[budget] VF_STATE_BUDGET_KB invalide : $STATE_KB" >&2; exit 64 ;; esac
case "$WT_MAX" in ''|*[!0-9]*) echo "[budget] VF_WORKTREE_BUDGET invalide : $WT_MAX" >&2; exit 64 ;; esac
[ -d "$ROOT" ] || { echo "[budget] racine introuvable : $ROOT" >&2; exit 64; }

OVER=0
UNVERIFIABLE=0
say() { [ "$QUIET" -eq 1 ] || echo "[budget] $*"; }
flag() { echo "[budget] $*"; }

# --- Budget 1 : taille des fichiers d'état -------------------------------------------------
STATE_FILES=()
[ -f "$ROOT/.planning/STATE.md" ] && STATE_FILES+=("$ROOT/.planning/STATE.md")
# Compartiments de workstream : énumérés par la primitive unique `vf_ws_enumerate`
# (planning-core/scripts/workstream-policy.sh, catégorie a1 du recensement
# workstream-planning-consumers.md), jamais par un glob maison. Politique sourcée SEULEMENT si
# `workstreams/` existe (même posture que check-divergence.sh) ; les trois codes du contrat sont
# traités, un compartiment non vérifiable est DIT, jamais tu.
if [ -e "$ROOT/.planning/workstreams" ]; then
  WS_POLICY=""
  for _cand in "$(dirname "$0")/workstream-policy.sh" \
               "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
    [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
  done
  if [ -z "$WS_POLICY" ]; then
    UNVERIFIABLE=1
    flag "STATE NON VÉRIFIABLE : workstream-policy.sh introuvable, compartiments de workstream non mesurés"
  else
    # shellcheck source=/dev/null
    . "$WS_POLICY"
    WS_LIST="$(vf_ws_enumerate "$ROOT/.planning")"; _ws_rc=$?
    case "$_ws_rc" in
      0)
        while IFS= read -r _wsdir; do
          [ -n "$_wsdir" ] && [ -f "$_wsdir/STATE.md" ] && STATE_FILES+=("$_wsdir/STATE.md")
        done <<EOF
$WS_LIST
EOF
        ;;
      3) : ;;
      *)
        UNVERIFIABLE=1
        flag "STATE NON VÉRIFIABLE : .planning/workstreams illisible (vf_ws_enumerate rc $_ws_rc)"
        ;;
    esac
  fi
fi
if [ "${#STATE_FILES[@]}" -eq 0 ]; then
  say "STATE : aucun fichier d'état sous $ROOT/.planning, budget non applicable"
fi
for f in "${STATE_FILES[@]+"${STATE_FILES[@]}"}"; do
  bytes=$(wc -c < "$f" | tr -d ' ')
  kb=$(( (bytes + 1023) / 1024 ))
  if [ "$bytes" -gt $(( STATE_KB * 1024 )) ]; then
    OVER=1
    flag "STATE DÉPASSÉ : $f fait $kb Ko (budget $STATE_KB Ko). Réécrire la position courante, archiver l'historique sous .planning/archives/state/"
  else
    say "STATE ok : $f fait $kb Ko (budget $STATE_KB Ko)"
  fi
done

# --- Budget 2 : worktrees actifs par dépôt -------------------------------------------------
is_repo() { git -C "$1" rev-parse --git-dir >/dev/null 2>&1; }
if [ "${#REPOS[@]}" -eq 0 ]; then
  if is_repo "$ROOT"; then
    REPOS+=("$ROOT")
  else
    for d in "$ROOT"/*/; do
      d="${d%/}"
      [ -e "$d/.git" ] && REPOS+=("$d")
    done
  fi
fi

base_ref() { # <repo> -> branche de référence (origin/HEAD, sinon main, sinon master)
  local r="$1" ref
  ref=$(git -C "$r" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$ref" ]; then echo "$ref"; return; fi
  for ref in main master; do
    git -C "$r" rev-parse -q --verify "refs/heads/$ref" >/dev/null 2>&1 && { echo "$ref"; return; }
  done
}

common_dir() { # <repo> -> dossier git commun, absolu (un worktree et son dépôt le partagent)
  local d
  d=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
  case "$d" in /*) ;; *) d="$1/$d" ;; esac
  (cd "$d" 2>/dev/null && pwd -P)
}

is_worked() { # <repo> <branche> : 0 si la branche a été travaillée (plus d'une entrée de reflog)
  # Une branche NEUVE et une branche INTÉGRÉE ont la même topologie (tête ancêtre de la base) :
  # seul le reflog les sépare. Une seule entrée (la création) = jamais travaillée = pas rangeable.
  [ "$(git -C "$1" reflog show --format=%H "refs/heads/$2" -- 2>/dev/null | grep -c .)" -gt 1 ]
}

# --- Budget 3 : rangement (lecture seule, jamais un verbe de suppression) ------------------------
GH_BIN="${VF_BUDGET_GH:-gh}"
OWNERS_OK=0

resolve_owners() { # <repo> : complète OWNERS via `gh api user` si aucun --owner ; rend 1 si impossible
  [ "$OWNERS_OK" -eq 1 ] && return 0
  if [ -z "${OWNERS//[$'\n ']/}" ]; then
    local login
    login=$(cd "$1" && "$GH_BIN" api user --jq .login 2>/dev/null) || return 1
    [ -n "$login" ] || return 1
    OWNERS="$login"
  fi
  OWNERS_OK=1
}

is_owner() { # <login> : 0 si le login figure parmi les propriétaires (insensible à la casse)
  local want have
  want=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  while IFS= read -r have; do
    [ -n "$have" ] || continue
    [ "$(printf '%s' "$have" | tr '[:upper:]' '[:lower:]')" = "$want" ] && return 0
  done <<EOF2
$OWNERS
EOF2
  return 1
}

rangement_branches() { # <repo> <base> <branches-en-worktree>
  local repo="$1" base="$2" wtb="$3" bshort cur b list rc
  bshort="${base#origin/}"
  cur=$(git -C "$repo" symbolic-ref -q --short HEAD 2>/dev/null)
  list=$(git -C "$repo" for-each-ref --merged "$base" --format='%(refname:short)' refs/heads 2>/dev/null); rc=$?
  [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches locales : git for-each-ref --merged $base a échoué (rc $rc)"; return 0; }
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    [ "$b" = "$bshort" ] && continue
    [ "$b" = "$cur" ] && continue
    case "
$wtb
" in *"
$b
"*) continue ;; esac
    is_worked "$repo" "$b" || continue
    OVER=1
    flag "RANGEABLE branche : $b déjà intégrée dans $base"
  done <<EOF2
$list
EOF2
}

rangement_stash() { # <repo> <base>
  local repo="$1" base="$2" bshort gd sha msg rest own list
  bshort="${base#origin/}"
  list=$(git -C "$repo" stash list --format='%gd%x09%H%x09%gs' 2>/dev/null)
  while IFS=$'\t' read -r gd sha msg; do
    [ -n "$gd" ] || continue
    sha="${sha:0:8}"
    case "$msg" in "WIP on "*) rest="${msg#WIP on }" ;; "On "*) rest="${msg#On }" ;; *) rest="" ;; esac
    case "$rest" in *:*) own="${rest%%:*}" ;; *) own="" ;; esac
    case "$own" in *"("*|*" "*) own="" ;; esac
    if [ -z "$own" ]; then
      UNVERIFIABLE=1
      flag "NON VÉRIFIABLE stash : $gd $sha « $msg » (branche d'origine illisible)"
      continue
    fi
    [ "$own" = "$bshort" ] && continue
    if ! git -C "$repo" rev-parse -q --verify "refs/heads/$own" >/dev/null 2>&1; then
      OVER=1; flag "RANGEABLE stash : $gd $sha « $msg »"
    elif [ -n "$base" ] && is_worked "$repo" "$own" \
         && git -C "$repo" merge-base --is-ancestor "refs/heads/$own" "$base" 2>/dev/null; then
      OVER=1; flag "RANGEABLE stash : $gd $sha « $msg »"
    fi
  done <<EOF2
$list
EOF2
}

rangement_memoires() { # <repo>
  local repo="$1" f idx list nprobe
  [ -d "$repo/.claude/agent-memory" ] || return 0
  list=$(git -C "$repo" ls-files --others --exclude-standard -- .claude/agent-memory 2>/dev/null | grep '\.md$')
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    OVER=1; flag "RANGEABLE mémoire hors git : $f"
  done <<EOF2
$list
EOF2
  list=$(git -C "$repo" ls-files -- '.claude/agent-memory/*/*.md' 2>/dev/null)
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "${f##*/}" = MEMORY.md ] && continue
    idx="$repo/${f%/*}/MEMORY.md"
    grep -qF "${f##*/}" "$idx" 2>/dev/null && continue
    OVER=1; flag "RANGEABLE mémoire hors index : $f"
  done <<EOF2
$list
EOF2
  nprobe=$(find "$repo/.claude/agent-memory" -maxdepth 1 -name 'zz-probe-*' 2>/dev/null | grep -c .)
  [ "$nprobe" -eq 0 ] || say "constat : $nprobe dossier(s) zz-probe-* sous .claude/agent-memory (sondes, jamais touchées)"
}

rangement_distantes() { # <repo> <base>
  local repo="$1" base="$2" bshort raw refs ref short name json tsv rc auths a n pr
  bshort="${base#origin/}"
  raw=$(git -C "$repo" for-each-ref --merged "$base" --format='%(refname)' refs/remotes 2>/dev/null); rc=$?
  [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : git for-each-ref --merged $base a échoué (rc $rc)"; return 0; }
  refs=""
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    short="${ref#refs/remotes/}"
    case "$short" in origin/*) name="${short#origin/}" ;; *) say "branche distante $short : hors du remote origin, jamais candidate"; continue ;; esac
    case "$name" in
      HEAD) continue ;;
      "$bshort") continue ;;
      main|master|develop|dev|development|trunk|staging|production|prod|stable|release/*|releases/*) say "branche distante $short : par défaut ou longue durée, jamais candidate"; continue ;;
    esac
    refs="$refs
$short"
  done <<EOF2
$raw
EOF2
  refs="${refs#?}"
  if [ -z "$refs" ]; then say "branches distantes : aucune candidate intégrée dans $base"; return 0; fi
  if ! command -v "$GH_BIN" >/dev/null 2>&1; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh introuvable ($GH_BIN)"; return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : jq introuvable"; return 0
  fi
  if ! resolve_owners "$repo"; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : propriétaire illisible (gh api user a échoué, aucun --owner)"; return 0
  fi
  json=$(cd "$repo" && "$GH_BIN" pr list --state merged --limit 200 --json headRefName,number,author,baseRefName 2>/dev/null); rc=$?
  if [ "$rc" -ne 0 ]; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh pr list a échoué (rc $rc)"; return 0
  fi
  case "$json" in *[![:space:]]*) ;; *) UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : gh pr list n'a rien rendu (sortie vide, rc 0)"; return 0 ;; esac
  tsv=$(printf '%s' "$json" | jq -r 'if type=="array" then .[] | [.headRefName, (.number|tostring), (.author.login // ""), (.baseRefName // "")] | @tsv else error("pas une liste") end' 2>/dev/null); rc=$?
  if [ "$rc" -ne 0 ]; then
    UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : réponse de gh illisible (JSON invalide)"; return 0
  fi
  say "branches distantes, propriétaires : $(printf '%s' "$OWNERS" | tr '\n' ' ' | sed 's/^ *//; s/ *$//')"
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    name="${ref#*/}"
    if printf '%s\n' "$tsv" | NAME="$name" awk -F'\t' '$4 == ENVIRON["NAME"] { f = 1 } END { exit !f }'; then
      say "branche distante $ref : base d'une PR mergée (longue durée), jamais candidate"; continue
    fi
    auths=$(printf '%s\n' "$tsv" | NAME="$name" awk -F'\t' '$1 == ENVIRON["NAME"] { print $3 "\t" $2 }')
    if [ -z "$auths" ]; then say "branche distante $ref : aucune PR mergée connue, jamais candidate"; continue; fi
    n=0; pr=""
    while IFS=$'\t' read -r a n_pr; do
      [ -n "$pr" ] || pr="$n_pr"
      is_owner "$a" || n=1
    done <<EOF2
$auths
EOF2
    if [ "$n" -eq 0 ]; then
      OVER=1; flag "À VALIDER branche distante : $ref (PR #$pr, $(printf '%s' "$auths" | cut -f1 | sed -n 1p)) — suppression = geste humain"
    else
      say "branche distante $ref : hors propriétaire, jamais candidate"
    fi
  done <<EOF2
$refs
EOF2
}

rangement() { # <repo> <base> <branches-en-worktree>
  local repo="$1" base="$2" wtb="$3"
  if [ -n "$base" ]; then
    rangement_branches "$repo" "$base" "$wtb"
    rangement_stash "$repo" "$base"
  fi
  rangement_memoires "$repo"
  if [ "$NO_REMOTE" -eq 1 ]; then
    say "branches distantes : non examinées (--no-remote)"
  elif [ -n "$base" ]; then
    rangement_distantes "$repo" "$base"
  fi
}

SEEN=" "
for repo in "${REPOS[@]+"${REPOS[@]}"}"; do
  if ! is_repo "$repo"; then
    say "worktrees : $repo n'est pas un dépôt git, ignoré"
    continue
  fi
  # Un worktree posé à côté du dépôt (dossier frère avec un fichier .git) désigne le MÊME dépôt :
  # compté une seule fois, sinon le budget se déclenche autant de fois qu'il y a de worktrees.
  cdir=$(common_dir "$repo") || cdir="$repo"
  case "$SEEN" in *" $cdir "*) continue ;; esac
  SEEN="$SEEN$cdir "
  repo=$(git -C "$repo" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
  [ -n "$repo" ] || continue
  porcelain=$(git -C "$repo" worktree list --porcelain 2>/dev/null)
  base=$(base_ref "$repo")
  if [ -z "$base" ]; then UNVERIFIABLE=1; flag "NON VÉRIFIABLE rangement : branche de référence introuvable dans $repo (ni origin/HEAD, ni main, ni master) : worktrees, branches, stash et branches distantes non classés"
  elif ! git -C "$repo" rev-parse -q --verify "$base^{commit}" >/dev/null 2>&1; then UNVERIFIABLE=1; flag "NON VÉRIFIABLE rangement : la branche de référence $base ne désigne aucun commit dans $repo (origin/HEAD orphelin ?) : worktrees, branches, stash et branches distantes non classés"; base=""
  fi
  active=0
  details=""
  first=1
  path=""; head=""; branch=""; prunable=0
  flush() {
    [ -n "$path" ] || return 0
    if [ "$first" -eq 1 ]; then first=0; return 0; fi  # arbre principal : hors budget
    if [ "$prunable" -eq 1 ] || [ ! -d "$path" ]; then
      details="$details
[budget]   ORPHELIN : $path (dossier absent, git worktree prune)"
      return 0
    fi
    active=$((active + 1))
    local label="${branch:-HEAD détachée ${head:0:8}}"
    local worked=1
    if [ -n "$branch" ]; then
      is_worked "$repo" "$branch" || worked=0
    fi
    if [ "$worked" -eq 0 ]; then
      [ "$QUIET" -eq 1 ] || details="$details
[budget]   actif : $path [$label] neuf, aucun commit depuis sa création"
    elif [ -n "$base" ] && git -C "$repo" merge-base --is-ancestor "$head" "$base" 2>/dev/null; then
      OVER=1
      details="$details
[budget]   RANGEABLE : $path [$label] déjà intégrée dans $base"
    elif [ "$QUIET" -eq 0 ]; then
      details="$details
[budget]   actif : $path [$label]"
    fi
  }
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) flush; path="${line#worktree }"; head=""; branch=""; prunable=0 ;;
      "HEAD "*) head="${line#HEAD }" ;;
      "branch "*) branch="${line#branch refs/heads/}" ;;
      prunable*) prunable=1 ;;
    esac
  done <<EOF
$porcelain
EOF
  flush
  if [ "$active" -gt "$WT_MAX" ]; then
    OVER=1
    flag "worktrees DÉPASSÉ : $repo en a $active actifs (budget $WT_MAX)"
  else
    say "worktrees ok : $repo en a $active actifs (budget $WT_MAX)"
  fi
  [ -n "$details" ] && printf '%s\n' "${details#?}"
  wt_branches=$(printf '%s\n' "$porcelain" | sed -n 's|^branch refs/heads/||p')
  rangement "$repo" "$base" "$wt_branches"
done

if [ "$STRICT" -eq 1 ] && [ "$UNVERIFIABLE" -eq 1 ]; then
  exit 2
fi
if [ "$OVER" -eq 1 ] && [ "$STRICT" -eq 1 ]; then
  exit 1
fi
exit 0
