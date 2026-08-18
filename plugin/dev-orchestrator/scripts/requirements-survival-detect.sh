#!/usr/bin/env bash
# requirements-survival-detect.sh — primitive PARTAGÉE de détection de survie du ledger (LEDG-02).
# À SOURCER, jamais à exécuter (même contrat que workstream-policy.sh). Deux consommateurs, tous
# deux dans dev-orchestrator (A-18-03) : check-requirements-survival.sh (ce plan) et
# restore-requirements-ledger.sh (rattrapage, plan 18-02).
#
# Expose vf_ledger_state <planning_dir>. Contrat de retour : CODE DE SORTIE discriminant + variables
# VF_LEDGER_* — jamais de parsing de sortie texte entre scripts (D-18-06, une primitive deux
# consommateurs).
#
#   Code | VF_LEDGER_STATE     | Sens
#   0    | absent_after_close  | jalon déclaré clos ET REQUIREMENTS.md absent
#   1    | nominal             | rien à signaler
#   2    | unreadable          | état illisible — bruyant, jamais un vert (VF_LEDGER_REASON renseigné)
#   3    | ids_missing         | REQUIREMENTS.md présent, ≥1 ID garanti/voyageur disparu sans trace
#
# Variables toujours vidées en tête d'appel, jamais héritées d'un appel précédent :
#   VF_LEDGER_STATE, VF_LEDGER_MILESTONE, VF_LEDGER_ARCHIVE, VF_LEDGER_ARMED, VF_LEDGER_REASON,
#   VF_LEDGER_MISSING_IDS, VF_LEDGER_MISSING_COUNT.
#
# Lecteur d'absence, jamais juge de contenu (D-18-10) : présence/absence d'un ID ou d'un fichier
# est binaire et falsifiable. Aucun statut ni prose n'est jamais lu ou jugé, sauf le diff d'IDs
# (A-18-08) qui ne lit QUE des IDs et le jeton littéral `caduc`, jamais une phrase.
#
# Marqueur d'armement (D-18-09, A-18-02, checkpoint T1 tranché par Samuel 2026-08-18 — option-a) :
# fichier-sentinelle VERSIONNÉ dans le lab, <planning_dir>/.requirements-survival-armed. Sa lecture
# est confinée à cette unique fonction. Précédent de la MÉCANIQUE « marqueur par fichier-sentinelle »
# dans ce dépôt : la sentinelle d'opt-in de /vf-notify (scope user, HORS dépôt) et le marqueur
# d'install scripts/.vibeflow-installed (vit sous .claude/, EXCLU du dépôt par .gitignore:20) — ni
# l'un ni l'autre n'est un précédent de sentinelle VERSIONNÉE PAR GIT : c'est bien le premier objet
# de ce type dans ce repo (cf. plugin/dev-orchestrator/AGENT.md).
#
# T-18-01/T-18-02 : le libellé du jalon extrait de MILESTONES.md est validé contre la liste blanche
# stricte ^[0-9A-Za-z._ /-]{1,80}$ (modèle sanitize_value de check-dev-bootstrap.sh) AVANT toute
# réimpression et avant toute construction de chemin d'archive. Échec → unreadable, jamais la valeur
# brute imprimée ou concaténée.
#
# T-18-03 : lecture de MILESTONES.md bornée à 400 lignes (awk, garde anti-gel SessionStart). Le
# diff d'IDs (A-18-08) parcourt l'archive et le vivant chacun UNE seule fois côté awk, sans boucle
# imbriquée sur le contenu de dépôt.

vf_ledger_state() { # <planning_dir>
  local planning_dir="$1"
  VF_LEDGER_STATE="" VF_LEDGER_MILESTONE="" VF_LEDGER_ARCHIVE="" VF_LEDGER_ARMED=""
  VF_LEDGER_REASON="" VF_LEDGER_MISSING_IDS="" VF_LEDGER_MISSING_COUNT="0"

  VF_LEDGER_ARMED=0
  [ -f "$planning_dir/.requirements-survival-armed" ] && VF_LEDGER_ARMED=1

  local milestones="$planning_dir/MILESTONES.md"
  if [ ! -d "$planning_dir" ] || [ ! -f "$milestones" ]; then
    VF_LEDGER_STATE="nominal"; return 1
  fi

  # Premier titre H2 CLOS rencontré de haut en bas (le fichier est anté-chronologique par
  # convention) ; aucune date de prose n'est jamais lue — dater serait juger du contenu (D-18-10).
  local heading
  heading="$(awk '
    NR > 400 { exit }
    /^## / {
      any_h2 = 1
      if (index($0, "\xe2\x9c\x85") > 0 && !found) { print $0; found = 1; exit }
    }
    END { if (!found) print (any_h2 ? "__NOCLOSE__" : "__NOHEADING__") }
  ' "$milestones")"

  case "$heading" in
    __NOHEADING__) VF_LEDGER_STATE="unreadable"; VF_LEDGER_REASON="no_heading"; return 2 ;;
    __NOCLOSE__)   VF_LEDGER_STATE="nominal"; return 1 ;;
  esac

  local label
  label="$(awk -v line="$heading" 'BEGIN {
    s = line
    sub(/^## /, "", s)
    sub(/^[^0-9A-Za-z]*/, "", s)
    idx = index(s, "\xe2\x80\x94")
    if (idx > 0) s = substr(s, 1, idx - 1)
    gsub(/[ \t]+$/, "", s)
    print s
  }')"
  if ! printf '%s' "$label" | grep -Eq '^[0-9A-Za-z._ /-]{1,80}$'; then
    VF_LEDGER_STATE="unreadable"; VF_LEDGER_REASON="label_rejected"; return 2
  fi
  VF_LEDGER_MILESTONE="$label"

  local archive="$planning_dir/milestones/${label}-REQUIREMENTS.md"
  local live="$planning_dir/REQUIREMENTS.md"

  if [ -f "$live" ]; then
    # Trace bien formée (D-18-12) : le jeton, exactement une espace, puis une étiquette conforme
    # à ^[0-9A-Za-z._-]{1,80}$. Toute ligne portant le jeton hors de cette forme → illisible — SAUF
    # une mention NUE du jeton (ex. prose documentant la convention entre backticks, sans valeur
    # après les deux-points : cas réel de .planning/REQUIREMENTS.md:932, "trace `carried-from:`")
    # : ce n'est pas une tentative de trace, donc pas un motif d'illisibilité (D-18-10 : lire une
    # absence, jamais juger la prose qui la décrit).
    if grep -n 'carried-from:' "$live" 2>/dev/null \
        | grep -vE 'carried-from:`|carried-from:[[:space:]]*$' \
        | grep -vE 'carried-from: [0-9A-Za-z._-]{1,80}' | grep -q .; then
      VF_LEDGER_STATE="unreadable"; VF_LEDGER_REASON="trace_malformed"; return 2
    fi
    if [ -f "$archive" ] && [ ! -L "$archive" ]; then
      local diff_out missing_count missing_list
      diff_out="$(awk '
        FNR == NR {
          if ($0 ~ /^## Traceability[ \t]*$/) { intrace = 1; next }
          if (intrace == 0) {
            if (match($0, /^- \[.\] \*\*[A-Z]+-[0-9]+\*\*/)) {
              line = $0
              if (match(line, /[A-Z]+-[0-9]+/)) {
                id = substr(line, RSTART, RLENGTH)
                bodyline[id] = line; bodyseen[id] = 1
              }
            }
          } else {
            if (match($0, /^\| [A-Z]+-[0-9]+ \|/)) {
              line = $0
              if (match(line, /[A-Z]+-[0-9]+/)) {
                id = substr(line, RSTART, RLENGTH)
                traceline[id] = line; traceseen[id] = 1
              }
            }
          }
          next
        }
        {
          lline = $0
          while (match(lline, /\*\*[A-Z]+-[0-9]+\*\*/)) {
            tok = substr(lline, RSTART + 2, RLENGTH - 4)
            livepresent[tok] = 1
            lline = substr(lline, RSTART + RLENGTH)
          }
        }
        END {
          mc = 0; ml = ""
          for (id in bodyseen) {
            if (!(id in traceseen)) continue
            combo = tolower(bodyline[id] "\n" traceline[id])
            if (combo ~ /caduc/) continue
            if (id in livepresent) continue
            mc++
            ml = (ml == "" ? id : ml " " id)
          }
          printf "%d\t%s\n", mc, ml
        }
      ' "$archive" "$live")"
      missing_count="${diff_out%%$'\t'*}"
      missing_list="${diff_out#*$'\t'}"
      case "$missing_count" in ''|*[!0-9]*) missing_count=0 ;; esac
      if [ "$missing_count" -gt 0 ]; then
        VF_LEDGER_STATE="ids_missing"
        VF_LEDGER_ARCHIVE="$archive"
        VF_LEDGER_MISSING_IDS="$missing_list"
        VF_LEDGER_MISSING_COUNT="$missing_count"
        return 3
      fi
    fi
    VF_LEDGER_STATE="nominal"; return 1
  fi

  # REQUIREMENTS.md ABSENT — chemin construit à partir du libellé DÉJÀ validé (T-18-02).
  if [ -f "$archive" ] && [ ! -L "$archive" ]; then
    VF_LEDGER_ARCHIVE="$archive"
  fi
  VF_LEDGER_STATE="absent_after_close"; return 0
}
