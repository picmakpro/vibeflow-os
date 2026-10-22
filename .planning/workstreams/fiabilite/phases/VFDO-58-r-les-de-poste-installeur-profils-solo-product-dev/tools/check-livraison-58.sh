#!/usr/bin/env bash
# check-livraison-58.sh — Outil de livraison de la Phase 58 (plan 58-09, RLPO-11, RLPO-12).
#
# Rôle : mesurer, depuis la BASE DE PHASE, ce que la Phase 58 a touché ou non, et le critère 6
# (aucun nom de client dans le dépôt). Un outil qui ne peut pas regarder ne rend jamais vert.
#
# Sous-commandes :
#   base                                imprime le SHA complet de la base de phase
#   gitignore-intact [--base <ref>] [--engine <fichier>]
#                                       gitignore_add_paths() identique octet pour octet à celle de la base (P58-D-13)
#   fichiers-intacts [--base <ref>] [--liste-fichiers <fichier>]
#                                       aucun fichier interdit modifié par la branche, archives intactes (P58-D-13, P58-D-20)
#   clients [--base <ref>]              aucun nom de la liste VF_CLIENT_NAMES_FILE (défaut ~/.config/vibeflow/clients.txt)
#                                       dans le diff, les chemins et les messages de commit de la phase (critère 6, P58-PL-11)
# Codes : 0 conforme · 1 écart trouvé · 2 NON-VÉRIFIABLE · 64 usage.
#
# BASE DE PHASE (documentée ici, avec sa raison). `--base <ref>` sinon : le parent du premier commit de
# `git merge-base HEAD origin/main..HEAD` dont le sujet commence par `<type>(58):` (lu par
# `git log --reverse --format='%H %s'`) ; aucun tel commit -> la merge-base ; ni l'une ni l'autre -> 2.
# Motif : la branche est empilée sur la clôture de la Phase 57 (commits non mergés qui touchent les archives
# de planning, le BACKLOG, le STATE) ; la merge-base les verrait comme des changements de la 58. La base de
# phase les exclut, survit à un rebase sur main (les sujets de commit sont conservés) et inclut le commit de
# cadrage `docs(58): cadrage…` dans le balayage du critère 6.
#
# CRITÈRE 6 : la liste de noms n'existe PAS dans le dépôt. Elle est fournie à l'exécution par
# VF_CLIENT_NAMES_FILE, défaut ~/.config/vibeflow/clients.txt (fichier régulier, lisible, non vide, HORS du dépôt ;
# variable posée mais vide = liste absente, code 2). Le script n'imprime JAMAIS un nom
# ni la ligne qui le contient : compteurs, chemins de fichiers et hashs de commit seulement.
set -uo pipefail

USAGE="usage: check-livraison-58.sh base | gitignore-intact [--base <ref>] [--engine <fichier>] | fichiers-intacts [--base <ref>] [--liste-fichiers <fichier>] | clients [--base <ref>]"

die_usage() { echo "$USAGE" >&2; exit 64; }

TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "NON-VÉRIFIABLE : hors d'un dépôt git" >&2; exit 2; }
cd "$TOP" || exit 2

# phase_base — imprime la base de phase ; rc 2 si introuvable.
phase_base() {
  local mb first
  mb="$(git merge-base HEAD origin/main 2>/dev/null)" || mb=""
  if [ -n "$mb" ]; then
    first="$(git log --reverse --format='%H %s' "$mb..HEAD" 2>/dev/null | awk '$2 ~ /^[a-z]+\(58\):$/ { print $1; exit }')"
    if [ -n "$first" ]; then
      git rev-parse "$first^" 2>/dev/null && return 0
    fi
    echo "$mb"; return 0
  fi
  return 2
}

resolve_base() { # <ref|vide> -> BASE ; rc 2 si illisible
  if [ -n "$1" ]; then
    BASE="$(git rev-parse --verify --quiet "$1^{commit}" 2>/dev/null)" || return 2
  else
    BASE="$(phase_base)" || return 2
  fi
  [ -n "$BASE" ] || return 2
  return 0
}

SUB="${1-}"; [ -n "$SUB" ] || die_usage
shift

ARG_BASE=""; ARG_ENGINE=""; ARG_LISTE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --base) [ "$#" -ge 2 ] || die_usage; ARG_BASE="$2"; shift 2 ;;
    --engine) [ "$#" -ge 2 ] || die_usage; ARG_ENGINE="$2"; shift 2 ;;
    --liste-fichiers) [ "$#" -ge 2 ] || die_usage; ARG_LISTE="$2"; shift 2 ;;
    *) die_usage ;;
  esac
done

extract_fn() { # <fichier> — gitignore_add_paths() de la ligne d'ouverture à la première `}` en colonne 0
  awk '/^gitignore_add_paths\(\) \{/ { p = 1 } p { print } p && /^\}/ { exit }' "$1"
}

case "$SUB" in
  base)
    [ -z "$ARG_ENGINE$ARG_LISTE" ] || die_usage
    if ! resolve_base "$ARG_BASE"; then echo "NON-VÉRIFIABLE : base de phase introuvable" >&2; exit 2; fi
    echo "$BASE"; exit 0 ;;

  gitignore-intact)
    [ -z "$ARG_LISTE" ] || die_usage
    resolve_base "$ARG_BASE" || { echo "NON-VÉRIFIABLE : base de phase introuvable" >&2; exit 2; }
    ENG="${ARG_ENGINE:-plugin/_internal/vibeflow-update.sh}"
    [ -f "$ENG" ] || { echo "NON-VÉRIFIABLE : engine illisible ($ENG)" >&2; exit 2; }
    TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
    git show "$BASE:plugin/_internal/vibeflow-update.sh" > "$TMPD/base.sh" 2>/dev/null || { echo "NON-VÉRIFIABLE : engine de la base illisible" >&2; exit 2; }
    extract_fn "$TMPD/base.sh" > "$TMPD/base.fn"
    extract_fn "$ENG" > "$TMPD/cur.fn"
    if [ ! -s "$TMPD/base.fn" ] || [ ! -s "$TMPD/cur.fn" ]; then echo "NON-VÉRIFIABLE : extraction de gitignore_add_paths() vide" >&2; exit 2; fi
    if cmp -s "$TMPD/base.fn" "$TMPD/cur.fn"; then
      echo "✓ gitignore_add_paths() identique à celle de la base ($BASE)"; exit 0
    fi
    echo "✗ gitignore_add_paths() diffère de celle de la base ($BASE)"; exit 1 ;;

  fichiers-intacts)
    [ -z "$ARG_ENGINE" ] || die_usage
    TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
    if [ -n "$ARG_LISTE" ]; then
      [ -f "$ARG_LISTE" ] || { echo "NON-VÉRIFIABLE : liste de fichiers illisible" >&2; exit 2; }
      cp "$ARG_LISTE" "$TMPD/liste"
      BASE="(liste fournie)"
    else
      resolve_base "$ARG_BASE" || { echo "NON-VÉRIFIABLE : base de phase introuvable" >&2; exit 2; }
      git diff --name-only "$BASE" HEAD > "$TMPD/liste" 2>/dev/null || { echo "NON-VÉRIFIABLE : diff illisible" >&2; exit 2; }
    fi
    is_forbidden() {
      case "$1" in
        plugin/planning-core/module.json) return 0 ;;
        plugin/*/agents/*) return 0 ;;
        plugin/*/AGENT.md) return 0 ;;
        .github/*) return 0 ;;
        .planning/workstreams/gouvernance/*) return 0 ;; # vf-allow-unregistered-planning-path
        VERSION|plugin/.claude-plugin/plugin.json|.claude-plugin/marketplace.json) return 0 ;;
        # resolve-preset.sh n'est plus interdit : le plan 58-12 le modifie par arbitrage (P58-D-21).
        plugin/_internal/resolve-deps.sh|plugin/_internal/presets.json) return 0 ;;
        plugin/_internal/tests/test-vibeflow-update.sh) return 0 ;;
        plugin/installer/scripts/tests/test-build-module-catalog.sh) return 0 ;;
        .planning/instruction-budget-baselines.tsv) return 0 ;;
      esac
      return 1
    }
    : > "$TMPD/fautifs"
    while IFS= read -r f || [ -n "$f" ]; do
      [ -n "$f" ] || continue
      if is_forbidden "$f"; then echo "$f" >> "$TMPD/fautifs"; fi
    done < "$TMPD/liste"
    if [ -z "$ARG_LISTE" ]; then
      # archives : tout fichier MODIFIÉ ou SUPPRIMÉ (jamais un ajout) autre que l'index.
      git diff --name-only --diff-filter=MD "$BASE" HEAD -- .planning/archives 2>/dev/null \
        | awk '$0 != ".planning/archives/INDEX.tsv"' >> "$TMPD/fautifs"
    fi
    if [ -s "$TMPD/fautifs" ]; then
      echo "✗ fichiers interdits modifiés par la branche depuis $BASE :"; sort -u "$TMPD/fautifs"; exit 1
    fi
    echo "✓ aucun fichier interdit modifié depuis $BASE ($(awk 'END { print NR }' "$TMPD/liste") chemins examinés)"; exit 0 ;;

  clients)
    [ -z "$ARG_ENGINE$ARG_LISTE" ] || die_usage
    NV="NON-VÉRIFIABLE : liste de noms absente (en attente de la liste), vide, illisible ou située dans le dépôt — critère 6 non vérifié, jamais vert"
    F="${VF_CLIENT_NAMES_FILE-$HOME/.config/vibeflow/clients.txt}"
    [ -n "$F" ] && [ -f "$F" ] && [ -r "$F" ] && [ -s "$F" ] || { echo "$NV"; exit 2; }
    FDIR="$(cd "$(dirname "$F")" 2>/dev/null && pwd -P)" || { echo "$NV"; exit 2; }
    FPHYS="$FDIR/$(basename "$F")"
    TOPP="$(cd "$TOP" && pwd -P)"
    case "$FPHYS" in "$TOPP"/*|"$TOPP") echo "$NV"; exit 2 ;; esac
    resolve_base "$ARG_BASE" || { echo "NON-VÉRIFIABLE : base de phase introuvable" >&2; exit 2; }
    TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
    # Noms : bords rognés (espaces, CR), lignes vides et lignes commençant par # ignorées.
    LC_ALL=C sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$F" | awk 'length($0) > 0 && substr($0, 1, 1) != "#"' > "$TMPD/noms"
    [ -s "$TMPD/noms" ] || { echo "$NV"; exit 2; }
    match() { grep -iqF -f "$TMPD/noms" 2>/dev/null; }  # lit stdin, jamais d'affichage
    git diff --name-only "$BASE" HEAD > "$TMPD/fichiers" 2>/dev/null || { echo "NON-VÉRIFIABLE : diff illisible" >&2; exit 2; }
    : > "$TMPD/out"
    nd=0; np=0; nm=0
    while IFS= read -r f || [ -n "$f" ]; do
      [ -n "$f" ] || continue
      if printf '%s\n' "$f" | match; then np=$((np+1)); echo "fichier: $f" >> "$TMPD/out"; continue; fi
      if git diff -U0 "$BASE" HEAD -- "$f" 2>/dev/null | awk '/^\+/ && !/^\+\+\+/' | match; then
        nd=$((nd+1)); echo "fichier: $f" >> "$TMPD/out"
      fi
    done < "$TMPD/fichiers"
    for c in $(git rev-list "$BASE..HEAD" 2>/dev/null); do
      if git log -1 --format=%B "$c" 2>/dev/null | match; then nm=$((nm+1)); echo "commit: $c" >> "$TMPD/out"; fi
    done
    echo "diff=$nd chemins=$np messages=$nm"
    if [ "$((nd + np + nm))" -gt 0 ]; then LC_ALL=C sort -u "$TMPD/out"; exit 1; fi
    exit 0 ;;

  *) die_usage ;;
esac
