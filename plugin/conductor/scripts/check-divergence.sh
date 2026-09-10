#!/usr/bin/env bash
# check-divergence.sh — Filet de détection de divergence de workstream (split-brain), Phase 39,
# Success Criterion 4 (PART-04). Recherche : .planning/research/2026-09-09-phase-39-workstreams-
# mesures-de-cadrage.md §8-9 (D-11, D-12).
#
# Rôle : aujourd'hui, `git merge-tree`/`git merge` fusionnent en SILENCE une branche qui a fait
# diverger la numérotation des phases d'un compartiment de workstream (un merge sans conflit
# textuel, mais dont le résultat est structurellement incohérent). Les trois gates existants
# (`check-workstream-pointer.sh`, `check-state-integrity.sh`, `workstream-policy.sh`) rendent tous
# « conforme » sur un tel arbre mesuré (research §9) : il n'y a aucun filet. Ce script EST ce
# filet.
#
# Trois variantes de split-brain mesurées (research §8), chacune couverte par un signal distinct :
#   - orphan   : deux dossiers de phase du MÊME compartiment partagent le même préfixe numérique
#                (une branche a créé une phase N sans savoir qu'une autre l'avait déjà prise)
#                → signal S2.
#   - roadmap-conflict : un compartiment a plus de dossiers de phase (ou un `completed_phases`
#                dépassant le nombre de dossiers) que son propre ROADMAP.md ne documente
#                → signal S4 (a: orphelin non documenté, b: compteur incohérent).
#   - rootonly : un numéro de phase possédé par un compartiment de workstream réapparaît en
#                en-tête `### Phase N` du ROADMAP.md RACINE (fuite de niveau)
#                → signal S5.
#
# DISCIPLINE DE COMPARAISON NUMÉRIQUE (BLOQUANTE, pas un style) : tout préfixe numérique extrait
# est une CHAÎNE (« 01 », « 39 ») et doit être NORMALISÉ (zéros de tête retirés) AVANT toute
# comparaison ou insertion dans un ensemble « vu » — sans quoi un dossier zéro-paddé (`01-`) et un
# en-tête ROADMAP non paddé (`### Phase 1`, la convention réelle de ce dépôt) sont jugés distincts
# à tort. Normalisation en arithmétique bash à base 10 EXPLICITE, `n=$((10#$int))` — jamais un
# `$((int))` nu : bash traite un `0` de tête comme un préfixe octal, `$((08))`/`$((09))` échouent
# pour les numéros de phase 8 et 9, entièrement ordinaires (mesuré sur bash 3.2.57).
#
# Compartiments inspectés :
#   - la racine `.planning/` — UNIQUEMENT si `.planning/phases/` y existe (repli legacy d'un dépôt
#     partitionné qui garde encore des phases non migrées à la racine) ;
#   - chaque `.planning/workstreams/<nom>/` (un lien symbolique, sur `workstreams/` lui-même ou sur
#     un compartiment, n'est JAMAIS suivi — refus audible, même posture que `workstream-policy.sh`).
#
# Usage:
#   check-divergence.sh [--path <dir>]
#   check-divergence.sh --help
#
# Defaults: --path .   (le `.planning/` inspecté est `<--path>/.planning`)
#
# Codes de sortie (chacun énuméré, aucun implicite) :
#   0  = conforme — au moins un compartiment a été inspecté, aucun de S2/S4/S5 n'a signalé.
#   1  = DIVERGENCE constatée — au moins un de S2/S4/S5 a signalé (message stderr précise lequel,
#        et nomme le(s) numéro(s) impliqué(s) sous leur forme NORMALISÉE).
#   2  = NON VÉRIFIABLE — hors dépôt git, `.planning/` illisible, `workstreams/` illisible ou lien
#        symbolique, `workstream-policy.sh` introuvable. Jamais un 0 de complaisance.
#   3  = SILENCE — `.planning/workstreams/` absent : dépôt non partitionné, rien à vérifier. C'est
#        l'état nominal de ce dépôt aujourd'hui, et de tout lab non partitionné.
#   64 = erreur d'usage (argument inconnu, option sans valeur).
set -uo pipefail

ROOT="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { echo "[check-divergence] --path nécessite une valeur" >&2; exit 64; }
      ROOT="$2"; shift 2 ;;
    --path=*)
      ROOT="${1#--path=}"
      [ -n "$ROOT" ] || { echo "[check-divergence] --path nécessite une valeur" >&2; exit 64; }
      shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-divergence] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }

[ -d "$ROOT" ] || { echo "[check-divergence] --path introuvable : $ROOT" >&2; exit 2; }
git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "[check-divergence] $ROOT hors d'un dépôt git — non vérifiable" >&2; exit 2; }

PLANNING="$ROOT/.planning"
if [ -e "$PLANNING" ]; then
  { [ -d "$PLANNING" ] && [ -r "$PLANNING" ] && [ -x "$PLANNING" ]; } \
    || { echo "[check-divergence] $PLANNING existe mais n'est pas un répertoire lisible — non vérifiable" >&2; exit 2; }
fi

WS_ROOT="$PLANNING/workstreams"

# --- État SILENCE : dépôt non partitionné (avant tout sourcing de politique, même posture que
# check-workstream-pointer.sh) ----------------------------------------------------------------------
if [ ! -e "$WS_ROOT" ]; then
  exit 3
fi

WS_POLICY=""
for _cand in "$(dirname "$0")/workstream-policy.sh" \
             "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
  [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
done
[ -n "$WS_POLICY" ] \
  || { echo "[check-divergence] workstream-policy.sh introuvable — politique non chargeable, non vérifiable" >&2; exit 2; }
# shellcheck source=/dev/null
. "$WS_POLICY"

vf_ws_path_nolink "$WS_ROOT"; _rc=$?
if [ "$_rc" -eq 2 ]; then
  echo "[check-divergence] $WS_ROOT est un lien symbolique — refus de le suivre, non vérifiable" >&2
  exit 2
fi
if [ "$_rc" -eq 1 ] || [ ! -d "$WS_ROOT" ]; then
  exit 3
fi

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

FAIL_MSGS=()
CHECKED=0

# --- Extraction / normalisation --------------------------------------------------------------------
PHASE_DIR_RE='^([A-Za-z]+-)?([0-9]+(\.[0-9]+)?)-'
ROADMAP_HEADER_RE='^### Phase ([0-9]+(\.[0-9]+)?)'

extract_num() { # <basename> -> imprime le préfixe numérique brut, 1 si aucune correspondance
  local name="$1"
  if [[ "$name" =~ $PHASE_DIR_RE ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
}

normalize_num() { # <brut, ex "01" ou "05.2"> -> forme décimale canonique ("1", "5.2")
  local raw="$1" int frac="" n
  # `int` est affecté en instruction SÉPARÉE de sa déclaration `local` : dans `local a=$1 b=$a`,
  # bash expand TOUS les mots (dont `$a`) AVANT que `local` n'exécute la première affectation —
  # `$a` référerait alors la variable `a` de la portée ENGLOBANTE (souvent non liée sous `set -u`),
  # jamais la valeur qu'on croit venir de fixer sur la même ligne. Mesuré ici : "raw: unbound
  # variable" sur la toute première normalisation de la suite de tests.
  int="$raw"
  case "$raw" in
    *.*) int="${raw%%.*}"; frac="${raw#*.}" ;;
  esac
  n=$((10#$int))
  if [ -n "$frac" ]; then printf '%s.%s' "$n" "$frac"; else printf '%s' "$n"; fi
}

frontmatter_block() { # <fichier> -> stdout : lignes du frontmatter (copié de check-state-integrity.sh)
  awk '
    /^---[[:space:]]*$/ { n++; if (n==1) next; if (n==2) exit }
    n==1 { print }
  ' "$1"
}

list_phase_dirs() { # <phases_dir> -> un basename par ligne, répertoires uniquement
  local d="$1" p
  [ -d "$d" ] || return 0
  for p in "$d"/*/; do
    [ -d "$p" ] || continue
    basename "$p"
  done
}

# --- S2 : au sein d'un compartiment, deux dossiers partageant le même numéro normalisé ------------
check_s2() { # <label> <phases_dir>
  local label="$1" dir="$2" name num norm
  local pairs="$TMPD/s2_pairs"; : > "$pairs"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    num="$(extract_num "$name")" || continue
    norm="$(normalize_num "$num")"
    printf '%s\t%s\n' "$norm" "$name" >> "$pairs"
  done < <(list_phase_dirs "$dir")
  [ -s "$pairs" ] || return 0
  LC_ALL=C sort "$pairs" -o "$pairs"
  local dupes="$TMPD/s2_dupes"
  awk -F'\t' '
    { cnt[$1]++; names[$1] = (names[$1] == "") ? $2 : names[$1]", "$2 }
    END { for (k in cnt) if (cnt[k] > 1) print k"\t"names[k] }
  ' "$pairs" | LC_ALL=C sort > "$dupes"
  [ -s "$dupes" ] || return 0
  local one_num one_names
  while IFS=$'\t' read -r one_num one_names; do
    FAIL_MSGS+=("S2 : compartiment « $label » — numéro de phase $one_num dupliqué entre : $one_names")
  done < "$dupes"
  return 1
}

# --- S4(a) : orphelin non documenté (dossier présent, aucun en-tête ROADMAP correspondant) --------
check_s4a() { # <label> <phases_dir> <roadmap_file>
  local label="$1" dir="$2" roadmap="$3" name num norm line hnum hnorm
  if [ ! -f "$roadmap" ]; then
    echo "[check-divergence] S4 non applicable — pas de ROADMAP.md dans ce compartiment ($label)" >&2
    return 0
  fi
  local dirs="$TMPD/s4a_dirs"; : > "$dirs"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    num="$(extract_num "$name")" || continue
    norm="$(normalize_num "$num")"
    printf '%s\n' "$norm" >> "$dirs"
  done < <(list_phase_dirs "$dir")
  [ -s "$dirs" ] || return 0
  LC_ALL=C sort -u "$dirs" -o "$dirs"

  local headers="$TMPD/s4a_headers"; : > "$headers"
  while IFS= read -r line; do
    [[ "$line" =~ $ROADMAP_HEADER_RE ]] || continue
    hnum="${BASH_REMATCH[1]}"
    hnorm="$(normalize_num "$hnum")"
    printf '%s\n' "$hnorm" >> "$headers"
  done < "$roadmap"
  LC_ALL=C sort -u "$headers" -o "$headers"

  local orphans="$TMPD/s4a_orphans"
  comm -23 "$dirs" "$headers" > "$orphans"
  [ -s "$orphans" ] || return 0
  local list
  list="$(tr '\n' ' ' < "$orphans" | sed 's/[[:space:]]*$//')"
  FAIL_MSGS+=("S4(a) : compartiment « $label » — numéro(s) de phase sans en-tête ROADMAP correspondant : $list")
  return 1
}

# --- S4(b) : completed_phases (STATE.md) strictement supérieur au nombre de dossiers de phase -----
check_s4b() { # <label> <phases_dir> <state_file>
  local label="$1" dir="$2" state="$3" completed count p
  [ -f "$state" ] || return 0
  completed="$(frontmatter_block "$state" \
    | grep -E '^[[:space:]]+completed_phases:[[:space:]]*[0-9]+' | head -1 \
    | sed -E 's/^[^:]+:[[:space:]]*([0-9]+).*/\1/')"
  [ -n "$completed" ] || return 0
  count=0
  for p in "$dir"/*/; do
    [ -d "$p" ] && count=$((count + 1))
  done
  if [ "$completed" -gt "$count" ]; then
    FAIL_MSGS+=("S4(b) : compartiment « $label » — completed_phases=$completed supérieur au nombre de dossiers de phase présents ($count)")
    return 1
  fi
  return 0
}

# --- S5 : un numéro de phase de workstream réapparaît en en-tête à la RACINE du ROADMAP ------------
check_s5() {
  local root_roadmap="$PLANNING/ROADMAP.md"
  [ -f "$root_roadmap" ] || return 0
  local ws_nums="$TMPD/s5_ws_nums"; : > "$ws_nums"
  local wsdir wsname p name num norm rc
  for wsdir in "$WS_ROOT"/*/; do
    [ -d "$wsdir" ] || continue
    wsname="$(basename "$wsdir")"
    vf_ws_path_nolink "$wsdir"; rc=$?
    [ "$rc" -eq 0 ] || continue
    [ -d "$wsdir/phases" ] || continue
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      num="$(extract_num "$name")" || continue
      norm="$(normalize_num "$num")"
      printf '%s\t%s\n' "$norm" "$wsname" >> "$ws_nums"
    done < <(list_phase_dirs "$wsdir/phases")
  done
  [ -s "$ws_nums" ] || return 0

  local headers="$TMPD/s5_root_headers"; : > "$headers"
  local line hnum hnorm
  while IFS= read -r line; do
    [[ "$line" =~ $ROADMAP_HEADER_RE ]] || continue
    hnum="${BASH_REMATCH[1]}"
    hnorm="$(normalize_num "$hnum")"
    printf '%s\n' "$hnorm" >> "$headers"
  done < "$root_roadmap"
  [ -s "$headers" ] || return 0
  LC_ALL=C sort -u "$headers" -o "$headers"

  local one_norm one_ws leaked=0
  while IFS=$'\t' read -r one_norm one_ws; do
    if grep -qxF "$one_norm" "$headers"; then
      FAIL_MSGS+=("S5 : le workstream « $one_ws » possède la phase $one_norm, aussi présente en en-tête à la RACINE de .planning/ROADMAP.md (fuite de niveau)")
      leaked=1
    fi
  done < "$ws_nums"
  [ "$leaked" -eq 0 ] || return 1
  return 0
}

# --- Compartiment racine (repli legacy) --------------------------------------------------------
if [ -d "$PLANNING/phases" ]; then
  CHECKED=1
  check_s2 "racine" "$PLANNING/phases" || true
  check_s4a "racine" "$PLANNING/phases" "$PLANNING/ROADMAP.md" || true
  check_s4b "racine" "$PLANNING/phases" "$PLANNING/STATE.md" || true
fi

# --- Compartiments de workstream -----------------------------------------------------------------
for _wsdir in "$WS_ROOT"/*/; do
  [ -d "$_wsdir" ] || continue
  _wsname="$(basename "$_wsdir")"
  vf_ws_path_nolink "$_wsdir"; _rc=$?
  if [ "$_rc" -eq 2 ]; then
    echo "[check-divergence] compartiment « $_wsname » est un lien symbolique — refus de le suivre, ignoré" >&2
    continue
  fi
  [ "$_rc" -eq 0 ] || continue
  CHECKED=1
  check_s2 "$_wsname" "$_wsdir/phases" || true
  check_s4a "$_wsname" "$_wsdir/phases" "$_wsdir/ROADMAP.md" || true
  check_s4b "$_wsname" "$_wsdir/phases" "$_wsdir/STATE.md" || true
done

# --- S5, une seule fois, sur l'ensemble des compartiments de workstream ---------------------------
check_s5 || true

if [ "${#FAIL_MSGS[@]}" -gt 0 ]; then
  for _m in "${FAIL_MSGS[@]}"; do
    echo "[check-divergence] $_m" >&2
  done
  exit 1
fi

if [ "$CHECKED" -eq 1 ]; then
  # Le mot « divergence » n'apparaît JAMAIS sur le chemin conforme : un test qui cherche la
  # sous-chaîne « divergence » sur la sortie doit pouvoir discriminer conforme (0) de signalé (1)
  # rien qu'à sa présence — cf. must_have « output does not contain the word "divergence" ».
  echo "[check-divergence] conforme — compartiment(s) inspecté(s), aucun signal S2/S4/S5" >&2
else
  echo "[check-divergence] $WS_ROOT présent mais vide — rien à inspecter" >&2
fi
exit 0
