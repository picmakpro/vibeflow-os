#!/usr/bin/env bash
# check-method-budget.sh — Budgets de méthode d'un lab (v2.67.0) : taille du fichier d'état et
# nombre de worktrees actifs. CONSTATE, ne corrige rien, ne supprime rien.
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
#   --root   racine du lab (défaut .). STATE.md lus : <root>/.planning/STATE.md et celui de
#            chaque compartiment de workstream (énumérés par vf_ws_enumerate).
#   --repo   dépôt git dont compter les worktrees (répétable). Défaut : <root> s'il est un dépôt
#            git, sinon chaque sous-dossier direct de <root> qui en est un (lab multi-dépôts).
#   --strict un dépassement rend 1 (défaut : avertissement seul, rend 0).
#   --quiet  n'imprime que les dépassements et les worktrees rangeables.
#
# Sortie standard : une ligne par constat, préfixe [budget]. Pour chaque worktree actif, dit s'il
# est RANGEABLE (sa branche ou sa tête est déjà intégrée dans la branche de référence du dépôt) ou
# ORPHELIN (dossier disparu, `git worktree prune`). Jamais de suppression : ranger est un geste
# du manager ou de l'humain, sans --force, après vérification qu'aucune session ne s'en sert.
#
# Codes : 0 = dans les budgets, ou dépassement sans --strict · 1 = dépassement avec --strict ·
#         2 = non vérifiable avec --strict (compartiments de workstream illisibles, politique
#         introuvable) — jamais un 0 de complaisance sous --strict · 64 = argument invalide.
set -uo pipefail

ROOT="."
REPOS=()
STRICT=0
QUIET=0
STATE_KB="${VF_STATE_BUDGET_KB:-8}"
WT_MAX="${VF_WORKTREE_BUDGET:-3}"

usage() { sed -n '/^# Usage :/,/^# Sortie standard/p' "$0" >&2; exit 64; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) [ "$#" -ge 2 ] || usage; ROOT="$2"; shift 2 ;;
    --repo) [ "$#" -ge 2 ] || usage; REPOS+=("$2"); shift 2 ;;
    --strict) STRICT=1; shift ;;
    --quiet) QUIET=1; shift ;;
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
    # Une branche NEUVE et une branche INTÉGRÉE ont la même topologie (tête ancêtre de la base) :
    # seul le reflog les sépare. Une seule entrée (la création) = jamais travaillée = pas rangeable.
    local worked=1
    if [ -n "$branch" ]; then
      [ "$(git -C "$repo" reflog show --format=%H "refs/heads/$branch" -- 2>/dev/null | grep -c .)" -le 1 ] && worked=0
    fi
    if [ "$worked" -eq 0 ]; then
      [ "$QUIET" -eq 1 ] || details="$details
[budget]   actif : $path [$label] neuf, aucun commit depuis sa création"
    elif [ -n "$base" ] && git -C "$repo" merge-base --is-ancestor "$head" "$base" 2>/dev/null; then
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
done

if [ "$STRICT" -eq 1 ] && [ "$UNVERIFIABLE" -eq 1 ]; then
  exit 2
fi
if [ "$OVER" -eq 1 ] && [ "$STRICT" -eq 1 ]; then
  exit 1
fi
exit 0
