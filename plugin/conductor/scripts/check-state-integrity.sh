#!/usr/bin/env bash
# check-state-integrity.sh — Anti-régression du frontmatter de `.planning/STATE.md` (Phase 21-04).
#
# Rôle : transformer en échec bruyant l'anomalie d'agrégation constatée le 2026-07-31 (clôture
# 20-07) — une écriture d'état a fait RÉGRESSER `completed_phases` (11→10), `total_plans`
# (53→49) et `completed_plans` (37→29) alors que la Phase 20 venait de se terminer, silencieusement,
# sans qu'aucun gate ne s'en aperçoive. Cause amont identifiée (gsd-core 1.9.0, `bin/lib/state.cjs`) :
# `buildStateFrontmatter()` ne retombe jamais sur le ROADMAP quand des `SUMMARY.md` manquent (à la
# différence de `roadmap analyze`, qui a ce repli) — dette d'artefact locale, pas une panne. Ce gate
# n'essaie PAS de corriger la cause amont (hors périmètre, lecture seule sur le paquet tiers) : il
# rend la régression IMPOSSIBLE À MANQUER la prochaine fois qu'elle se produit.
#
# Deux invariants distincts, vérifiés dans le même script parce qu'ils protègent le même fichier
# contre le même défaut de fond (une réécriture qui régresse ou duplique un état déjà correct) :
#
#   1. RÉGRESSION DE COMPTEUR — au sein d'un même jalon (`milestone:` identique des deux côtés),
#      `completed_phases`, `completed_plans`, `total_plans` et `current_phase` ne décroissent JAMAIS
#      entre l'état `--against` (défaut HEAD) et l'état courant (`--current-ref`, défaut : fichier de
#      travail) — couvre exactement les 4 champs de l'incident du 2026-07-31 cité ci-dessus. Un
#      changement de jalon (clôture + `gsd-new-milestone`) réinitialise légitimement ces compteurs —
#      l'invariant ne s'applique donc QUE si `milestone:` est identique des deux côtés ; un `milestone:`
#      absent/illisible d'UN SEUL côté n'est PAS traité comme un changement de jalon (ce serait un
#      skip silencieux) mais comme une intégrité de frontmatter compromise (exit 2), même posture que
#      pour un compteur illisible.
#
#   2. LIGNE `^Phase:` UNIQUE — cause B du diagnostic de mission : `stateExtractField(body, 'Phase')`
#      (amont) prend le PREMIER `^Phase:` du corps entier, sans scope, alors que le corps de ce
#      fichier empile un historique de sections archivées qui commencent toutes par `Phase: N`. Le
#      corps DOIT contenir exactement une ligne `^Phase:` — celle de la phase courante ; toute
#      section archivée doit utiliser une forme qui ne matche pas cette ancre (convention posée par
#      ADR-063, cf. `docs/ADR.md`).
#
# Usage:
#   check-state-integrity.sh [--path <dir>] [--file <relpath>] [--current-ref <ref>] [--against <ref>]
#   check-state-integrity.sh --help
#
# Defaults: --path .  --file <résolu : racine OU compartiment de workstream, cf. ci-dessous>
#           --current-ref <fichier de travail, non commité>  --against HEAD
#
# WORKSTREAMS GSD (GSDA-13) — RÉSOLUTION DU DÉFAUT DE `--file` :
# Le moteur amont peut partitionner le planning en `.planning/workstreams/<nom>/`. Quand `--file`
# n'est PAS fourni, le défaut est résolu : workstream actif → `.planning/workstreams/<nom>/STATE.md`,
# sinon `.planning/STATE.md` (comportement historique, strictement inchangé).
# `--file` EXPLICITE PRIME TOUJOURS : la résolution automatique ne le réécrase JAMAIS, quelle que
# soit la valeur de GSD_WORKSTREAM ou du pointeur.
# PRÉCONDITION DE PARTITIONNEMENT : la résolution ne s'arme QUE si `<path>/.planning/workstreams/`
# existe. Sans elle, ce script était le seul des quatre à rendre un verdict sur un dépôt NON
# partitionné : `GSD_WORKSTREAM=feature-x` le faisait sortir en 2 là où ses trois pairs
# poursuivaient — et le déclencheur n'avait rien d'hypothétique, `check-workstream-pointer.sh`
# PRESCRIT littéralement `export GSD_WORKSTREAM=<nom>` comme remède.
# Politique de nom et ordre de résolution : `workstream-policy.sh` (planning-core), fichier SOURCÉ
# et partagé par les quatre gates — voir son en-tête pour la politique UNIQUE, la parité amont et
# la gradation par rôle du cas « résolu mais dossier absent ». La surcharge historique
# VF_STATE_WORKSTREAM reste le premier canal.
# FRONTIÈRE ASSUMÉE : le pointeur de SESSION en os.tmpdir() n'est PAS lu ici — indexé sur un
# condensat de chemin absolu et une clé de session que bash ne reproduit pas fidèlement.
#
# --current-ref permet de comparer deux refs git entre elles (utile en CI post-commit ou en test) ;
# par défaut, "courant" désigne le fichier de travail tel qu'il est sur disque — le point d'usage
# principal est un gate PRE-COMMIT : intercepter une régression AVANT qu'elle ne soit commitée par
# `gsd-tools state record-session` ou tout écrivain équivalent.
# Note : `--file` attend un chemin RELATIF (au `--path`, résolu en objet git via `<ref>:<relpath>`) —
# un `--file` absolu combiné à `--current-ref` n'est pas un usage supporté.
#
# Codes de sortie : 0 = conforme · 1 = régression ou invariant rompu (message stderr précise lequel)
#                   2 = erreur d'intégrité (hors dépôt git, fichier/ref illisible, champ imparsable,
#                       workstream résolu dont le dossier `.planning/workstreams/<nom>/` est
#                       introuvable, OU nom/pointeur REJETÉ par la politique amont — même posture
#                       fail-closed que ligne « hors dépôt git » : on ne retombe JAMAIS en silence
#                       sur le STATE.md de la racine, ce serait rendre « conforme » sur un fichier
#                       que l'on n'a pas vérifié. Le rejet d'un nom retombait précisément sur la
#                       racine en rendant « exit 0 conforme » — fail-OPEN, l'exact inverse de ce
#                       que cette ligne jure.)
#                   64 = usage
set -uo pipefail

ROOT="."
FILE_REL=".planning/STATE.md"
FILE_REL_EXPLICIT=0   # 1 dès que --file est fourni → la résolution de workstream se retire
CURRENT_REF=""       # vide = fichier de travail
AGAINST_REF="HEAD"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { echo "[check-state-integrity] --path nécessite une valeur" >&2; exit 64; }
      ROOT="$2"; shift 2 ;;
    --file)
      [ "$#" -ge 2 ] || { echo "[check-state-integrity] --file nécessite une valeur" >&2; exit 64; }
      FILE_REL="$2"; FILE_REL_EXPLICIT=1; shift 2 ;;
    --current-ref)
      [ "$#" -ge 2 ] || { echo "[check-state-integrity] --current-ref nécessite une valeur" >&2; exit 64; }
      CURRENT_REF="$2"; shift 2 ;;
    --against)
      [ "$#" -ge 2 ] || { echo "[check-state-integrity] --against nécessite une valeur" >&2; exit 64; }
      AGAINST_REF="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-state-integrity] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }

if ! git_safe rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[check-state-integrity] $ROOT hors d'un dépôt git — intégrité non vérifiable" >&2
  exit 2
fi

# --- Résolution du workstream actif (GSDA-13) — APRÈS le gate « hors dépôt git » -------------------
# Position volontaire : la précondition « on est dans un dépôt » reste le premier échec de premier
# rang. Position volontaire aussi vis-à-vis de `--file` : la résolution ne s'applique QUE si
# l'appelant n'a rien imposé (FILE_REL_EXPLICIT=0), jamais l'inverse.
# La politique de nom n'est PLUS recopiée ici : elle est SOURCÉE (voir en-tête). Une copie locale
# avait divergé du moteur amont ET de ses trois pairs en un seul lot de travail parallèle.
WS_POLICY=""
for _cand in "$(dirname "$0")/workstream-policy.sh" \
             "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
  [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
done
if [ -z "$WS_POLICY" ]; then
  # Fail-closed, même posture que « hors dépôt git » : sans la politique, ce script ne peut pas
  # savoir QUEL fichier il doit vérifier. Rendre « conforme » sur la racine serait un vert rendu
  # par défaut d'outillage. Le cas est structurellement impossible dans un lab conforme (conductor
  # requiert planning-core), donc jamais un coût en régime nominal.
  echo "[check-state-integrity] workstream-policy.sh introuvable — politique de workstream non chargeable, intégrité non vérifiable" >&2
  exit 2
fi
# shellcheck source=/dev/null
. "$WS_POLICY"

if [ "$FILE_REL_EXPLICIT" -eq 0 ] && [ -d "$ROOT/.planning/workstreams" ]; then
  vf_ws_resolve "$ROOT/.planning" "${VF_STATE_WORKSTREAM:-}"; ws_rc=$?
  if [ "$ws_rc" -eq 2 ]; then
    # Le REJET est fail-closed, comme le dossier absent ci-dessous. Il retombait auparavant sur le
    # STATE.md de la racine en rendant « exit 0 conforme » : un nom rejeté désarmait le gate.
    # Seule la RAISON est imprimée — jamais la valeur, non maîtrisée par construction (T-24-04-01).
    echo "[check-state-integrity] workstream rejeté par la politique amont ($VF_WS_REASON, canal $VF_WS_SOURCE) — aucun chemin construit, intégrité non vérifiable" >&2
    exit 2
  fi
  if [ -n "$VF_WS_NAME" ]; then
    if [ -d "$ROOT/.planning/workstreams/$VF_WS_NAME" ]; then
      FILE_REL=".planning/workstreams/$VF_WS_NAME/STATE.md"
    else
      # Fail-closed : ne JAMAIS retomber sur le STATE.md de la racine — ce serait rendre un verdict
      # de conformité sur un fichier autre que celui que l'appelant croit vérifier.
      echo "[check-state-integrity] workstream « $VF_WS_NAME » actif mais .planning/workstreams/$VF_WS_NAME introuvable sous $ROOT — intégrité non vérifiable" >&2
      exit 2
    fi
  fi
fi

case "$FILE_REL" in
  /*) FILE_PATH="$FILE_REL" ;;
  *)  FILE_PATH="$ROOT/$FILE_REL" ;;
esac

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

# --- Charge le contenu "courant" -------------------------------------------------------------------
if [ -n "$CURRENT_REF" ]; then
  if ! git_safe show "$CURRENT_REF:$FILE_REL" > "$TMPD/current.md" 2>/dev/null; then
    echo "[check-state-integrity] $FILE_REL introuvable à --current-ref=$CURRENT_REF" >&2
    exit 2
  fi
else
  [ -r "$FILE_PATH" ] || { echo "[check-state-integrity] fichier introuvable : $FILE_PATH" >&2; exit 2; }
  cat "$FILE_PATH" > "$TMPD/current.md"
fi

# --- Charge le contenu de référence (--against). Deux échecs distincts, jamais confondus (F13,
# anti-vert-par-absence) : une REF qui ne résout à rien est une erreur d'usage (--against mal
# orthographié ne doit jamais dégrader en "rien à comparer" — ce serait un gate qui se désarme
# silencieusement sur une faute de frappe) ; une ref valide dont le FICHIER est absent est un cas
# légitime (fichier tout juste créé, rien à régresser). --------------------------------------------
if ! git_safe rev-parse --verify --quiet "${AGAINST_REF}^{commit}" >/dev/null 2>&1; then
  echo "[check-state-integrity] --against=$AGAINST_REF ne résout à aucun commit — usage invalide" >&2
  exit 2
fi
HAVE_BASELINE=1
if ! git_safe show "$AGAINST_REF:$FILE_REL" > "$TMPD/against.md" 2>/dev/null; then
  HAVE_BASELINE=0
fi

# --- Extraction du bloc frontmatter (entre les deux premières lignes "---" exactes) ----------------
frontmatter_block() { # <fichier source> -> stdout : lignes du frontmatter, délimiteurs exclus
  awk '
    /^---[[:space:]]*$/ { n++; if (n==1) next; if (n==2) exit }
    n==1 { print }
  ' "$1"
}
frontmatter_block "$TMPD/current.md" > "$TMPD/current.fm"
if [ "$HAVE_BASELINE" -eq 1 ]; then
  frontmatter_block "$TMPD/against.md" > "$TMPD/against.fm"
fi

extract_int() { # <fichier .fm> <regex ancrée du champ>
  grep -E "$2" "$1" 2>/dev/null | head -1 | sed -E 's/^[^:]+:[[:space:]]*([0-9]+).*/\1/'
}
extract_str() { # <fichier .fm> <regex ancrée du champ>
  grep -E "$2" "$1" 2>/dev/null | head -1 | sed -E 's/^[^:]+:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/'
}

FAIL=0
say_fail() { printf '[check-state-integrity] ✗ %s\n' "$1" >&2; FAIL=1; }

# === Invariant 1 — régression de compteur, au sein d'un même jalon =================================
# Revue (plan 21-04) : deux correctifs. (1) total_plans rejoint les champs protégés — l'incident qui
# motive ce gate (cf. en-tête) régressait AUSSI total_plans (53→49), le laisser hors invariant aurait
# contredit la promesse documentée du script. (2) un champ `milestone:` absent/illisible D'UN SEUL
# côté n'est PLUS traité comme "jalon différent" (skip silencieux) : c'est une intégrité de
# frontmatter compromise, même posture fail-closed que pour un compteur illisible ci-dessous — sinon
# une corruption qui casse à la fois les compteurs ET la ligne milestone désarmerait le gate qu'elle
# devrait justement déclencher.
if [ "$HAVE_BASELINE" -eq 1 ]; then
  cur_milestone="$(extract_str "$TMPD/current.fm" '^milestone:')"
  base_milestone="$(extract_str "$TMPD/against.fm" '^milestone:')"

  if [ -z "$cur_milestone" ] || [ -z "$base_milestone" ]; then
    echo "[check-state-integrity] milestone introuvable ou illisible ($AGAINST_REF=\"$base_milestone\" ↔ courant=\"$cur_milestone\") — intégrité du frontmatter compromise" >&2
    exit 2
  fi

  if [ "$cur_milestone" = "$base_milestone" ]; then
    for field in current_phase completed_phases completed_plans total_plans; do
      case "$field" in
        current_phase) regex='^current_phase:[[:space:]]*[0-9]+' ;;
        *)             regex="^[[:space:]]+${field}:[[:space:]]*[0-9]+" ;;
      esac
      cur_val="$(extract_int "$TMPD/current.fm" "$regex")"
      base_val="$(extract_int "$TMPD/against.fm" "$regex")"
      if [ -z "$cur_val" ] || [ -z "$base_val" ]; then
        echo "[check-state-integrity] $field introuvable ou non numérique — intégrité du frontmatter compromise" >&2
        exit 2
      fi
      if [ "$cur_val" -lt "$base_val" ]; then
        say_fail "RÉGRESSION $field : $base_val ($AGAINST_REF) → $cur_val (courant) — jalon inchangé ($cur_milestone)"
      fi
    done
  else
    echo "[check-state-integrity] jalon différent ($AGAINST_REF=\"$base_milestone\" ↔ courant=\"$cur_milestone\") — invariant de compteur non applicable, ignoré" >&2
  fi
else
  echo "[check-state-integrity] aucune référence à $AGAINST_REF pour $FILE_REL — rien à régresser, invariant de compteur ignoré" >&2
fi

# === Invariant 2 — exactement une ligne ^Phase: dans le corps courant (cause B, ADR-063) ===========
phase_lines="$(grep -c '^Phase:' "$TMPD/current.md" 2>/dev/null || true)"
case "$phase_lines" in ''|*[!0-9]*) phase_lines=0 ;; esac
if [ "$phase_lines" -ne 1 ]; then
  say_fail "$phase_lines ligne(s) '^Phase:' dans $FILE_REL (attendu exactement 1 — cf. ADR-063, archive toute section passée sous une forme qui ne matche pas '^Phase:')"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "[check-state-integrity] ✓ $FILE_REL conforme (compteurs non régressés, 1 ligne '^Phase:')"
  exit 0
fi
exit 1
