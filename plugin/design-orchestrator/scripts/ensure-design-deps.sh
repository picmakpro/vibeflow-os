#!/usr/bin/env bash
# ensure-design-deps.sh — Bootstrap auto-install non-interactif de la chaîne d'outils design
# (design-orchestrator).
#
# Objet : vérifier PRÉSENCE **ET ACTIVATION** des 4 plugins de la chaîne design
# (superpowers, ui-ux-pro-max, frontend-design, impeccable), et corriger ce qui manque en
# non-interactif — un plugin installé mais DÉSACTIVÉ est traité comme manquant et reçoit un
# `claude plugin enable` scopé, JAMAIS un `install` nu. C'est le trou que ce script ferme :
# `claude plugin list | grep <nom>` (seule détection outillée précédente du repo, cf.
# `ensure-deps.sh` de dev-orchestrator) est aveugle à l'état enabled/disabled — un plugin
# désactivé matche le grep et passe pour présent.
#
# Autonomie (D-04) : ce script ne source, n'appelle et ne suppose présent AUCUN artefact d'un
# autre module (ni `dev-orchestrator/scripts/ensure-deps.sh`, ni aucun de ses helpers). La
# parenté de forme avec ce bootstrap voisin (en-tête documenté, log/err, run_cmd, validation
# VF_SCOPE en tête, parsing d'arguments tolérant, résumé final) est une DUPLICATION DÉLIBÉRÉE —
# du même ordre que celle déjà assumée entre `ensure-deps.sh` et `check-gsd-engine.sh`. Aucun
# `source`, aucun `bash "$(dirname "$0")/../<autre-module>/..."`.
#
# Jumelle documentaire : la table des 4 plugins ci-dessous (TABLE) est la JUMELLE de la table
# d'install de `references/design-toolchain.md` §Vérification de présence. Modifier l'une sans
# reporter dans l'autre est le défaut à éviter — les deux tables doivent toujours dire la même
# chose (mêmes 4 plugins, mêmes marketplaces, même dépôt tiers pour impeccable).
#
# Usage :
#   ./ensure-design-deps.sh                                  # détecte + corrige ce qui manque
#   VF_DESIGN_ENSURE_DRY_RUN=1 ./ensure-design-deps.sh        # logue les commandes SANS les exécuter
#   VF_SCOPE=project ./ensure-design-deps.sh                  # scope (user|project|local), défaut user
#   VF_DESIGN_ENSURE_DRY_RUN=1 VF_DESIGN_ENSURE_FORCE=1 ./ensure-design-deps.sh
#     # dry-run observable : logue les 4 commandes scopées même sur une machine déjà équipée
#
# Variables d'environnement :
#   VF_DESIGN_ENSURE_DRY_RUN (défaut vide) — 1 → `run_cmd` logue au lieu d'exécuter.
#   VF_DESIGN_ENSURE_FORCE   (défaut vide) — 1 → EN DRY-RUN UNIQUEMENT, court-circuite
#                             l'early-return « déjà actif » pour rendre les 4 commandes scopées
#                             observables sur une machine déjà équipée. SANS EFFET hors dry-run :
#                             jamais d'install/enable forcé en réel.
#   VF_SCOPE                 (défaut user) — scope : user|project|local. Validé EN TÊTE, avant
#                             toute définition de `main` et tout `run_cmd` (une valeur invalide
#                             sort en 1 avant tout effet de bord). Mapping DIRECT
#                             `--scope "$VF_SCOPE"` — pas de dérivation : la chaîne design n'a
#                             pas l'asymétrie global/local du bootstrap de dev (contrat de scope
#                             unique du repo, ID4).
#
# Nommage délibérément PAS partagé avec le bootstrap de dev (`VF_ENSURE_*`) : les scripts des
# deux modules atterrissent À PLAT dans le même `$TARGET_ROOT/scripts/` chez l'utilisateur
# (`copy_module_scripts()` de `vibeflow-update.sh`) — un nom d'env partagé piloterait deux
# bootstraps différents par un seul export. D'où le préfixe `VF_DESIGN_` sur les deux flags
# propres à ce script (VF_SCOPE reste partagé : c'est le contrat de scope unique du repo).
#
# Flags CLI (rétro-compat : tout argument inconnu est IGNORÉ avec une ligne log, jamais un exit
# non-zéro — un rejet strict casserait un appelant non recensé) :
#   -h | --help   Affiche cet en-tête (grep '^# ') et exit 0.
#
# Contrat de sortie : toujours exit 0, SAUF `VF_SCOPE` invalide (exit 1, avant tout effet de
# bord). Jamais d'échec silencieux : CLI `claude` absente → 4 étapes manuelles affichées, exit 0.
# Idempotent : un 2e run consécutif en dry-run est un no-op stable (sortie identique).
#
# Référence : D-01/D-02/D-03/D-04, threat register T-Q-01..T-Q-05 (voir PLAN quick 260810-fh3).

# Pas de `-e` : les détections (command -v, grep, claude plugin …) doivent pouvoir échouer sans
# tuer le script — c'est précisément la dégradation gracieuse attendue.
set -uo pipefail

# ---------- Variables ----------
DRY_RUN="${VF_DESIGN_ENSURE_DRY_RUN:-}"
FORCE="${VF_DESIGN_ENSURE_FORCE:-}"
SCOPE="${VF_SCOPE:-user}"

# ---------- Helpers ----------
log() { echo "[ensure-design-deps] $*" >&2; }
err() { echo "[ensure-design-deps] ERROR: $*" >&2; }

# ---------- Validation du scope — EN TÊTE, avant tout run_cmd et toute définition de main ----------
case "$SCOPE" in
  user | project | local) ;;
  *)
    err "VF_SCOPE invalide : $SCOPE (attendu user|project|local)"
    exit 1
    ;;
esac

# Exécute une commande, ou la logue seulement en dry-run. Arguments TOUJOURS en mots argv
# séparés — jamais une chaîne montée puis ré-évaluée, jamais d'`eval` (T-Q-01).
run_cmd() {
  if [ -n "$DRY_RUN" ]; then
    log "(dry-run) $*"
    return 0
  fi
  "$@"
}

# ---------- Garde ADR-054 : stub Microsoft Store `python3` ----------
# Duplication DÉLIBÉRÉE du motif de `plugin/conductor/scripts/check-plugin-update.sh:43-46` —
# même précédent que l'en-tête de ce fichier (D-04) : ce script reste testable en boîte noire
# sans sourcer un script à effets de bord. `python3` peut être un stub inerte de Windows
# (WindowsApps), détecté par CHEMIN (zéro spawn) ; repli `python`, sinon vide.
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  '' | *WindowsApps*) command -v python >/dev/null 2>&1 && PYBIN=python || PYBIN="" ;;
esac

# ---------- Validation d'un identifiant de plugin avant tout passage en argument (T-Q-01) ----------
# Un `id` issu d'une sortie de commande (`claude plugin list`) n'est JAMAIS réinjecté en argument
# sans ces deux gardes : forme `<nom>@<marketplace>` stricte, ET partie nom = l'un des 4
# littéraux de la table (jamais dérivé de l'environnement — T-Q-02).
valid_plugin_id() {
  local id="$1" nm
  printf '%s' "$id" | grep -Eq '^[A-Za-z0-9._-]+@[A-Za-z0-9._/-]+$' || return 1
  nm="${id%%@*}"
  case "$nm" in
    superpowers | ui-ux-pro-max | frontend-design | impeccable) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------- Étape manuelle par plugin (jumelle du tableau design-toolchain.md) ----------
print_manual_step() {
  case "$1" in
    superpowers)
      log "  Étape manuelle (superpowers) : claude plugin install superpowers@claude-plugins-official"
      ;;
    ui-ux-pro-max)
      log "  Étape manuelle (ui-ux-pro-max) : claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill"
      ;;
    frontend-design)
      log "  Étape manuelle (frontend-design) : claude plugin install frontend-design@claude-plugins-official"
      ;;
    impeccable)
      log "  Étape manuelle (impeccable, deux temps) : claude plugin marketplace add pbakaus/impeccable && claude plugin install impeccable@impeccable"
      ;;
  esac
}

# ---------- Détection — cascade de sources, jamais un verdict sans preuve (T-Q-04) ----------
CLAUDE_AVAILABLE=0
INDETERMINE=0
SOURCE_LINES=""

detect_all() {
  command -v claude >/dev/null 2>&1 && CLAUDE_AVAILABLE=1

  if [ "$CLAUDE_AVAILABLE" -eq 0 ]; then
    # Aucune source exploitable. `installed_plugins.json` n'est PAS une source de repli ici :
    # il ne porte AUCUN champ d'activation (`enabled`) — c'est l'origine même du trou que ce
    # script ferme (découverte 2). Jamais un « présent » par défaut : indéterminé + manuel.
    INDETERMINE=1
    return 0
  fi

  # S1 (primaire) : `claude plugin list --json`, parsé par $PYBIN. Une ligne `<id> <enabled>`
  # par entrée. Purger le CR (ADR-054) avant tout parse.
  local json_tmp s1_usable
  json_tmp="$(mktemp 2>/dev/null)"
  [ -n "$json_tmp" ] || json_tmp="/tmp/vf-design-deps-json.$$"
  claude plugin list --json 2>/dev/null | tr -d '\r' >"$json_tmp" 2>/dev/null

  s1_usable=0
  if [ -n "$PYBIN" ] && [ -s "$json_tmp" ]; then
    SOURCE_LINES="$("$PYBIN" - "$json_tmp" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
if not isinstance(data, list):
    sys.exit(1)
for e in data:
    if not isinstance(e, dict):
        continue
    pid = e.get("id", "")
    if not pid:
        continue
    en = "true" if e.get("enabled") else "false"
    print("%s %s" % (pid, en))
sys.exit(0)
PY
)"
    [ $? -eq 0 ] && s1_usable=1
  fi
  rm -f "$json_tmp" 2>/dev/null

  if [ "$s1_usable" -eq 1 ]; then
    return 0
  fi

  # S2 (repli) — uniquement si S1 ne rend rien d'exploitable (CLI trop ancienne sans --json,
  # PYBIN vide, sortie non-JSON). Machine à états awk sur `claude plugin list` nu : une ligne
  # d'en-tête « <nom>@<marketplace> » ouvre une entrée, la ligne « Status: » qui suit la ferme.
  # Discrimine sur les MOTS enabled/disabled, jamais sur les glyphes de décoration (une décoration
  # mutilée par la locale/l'encodage ne doit jamais retourner le verdict en silence).
  local plain_tmp
  plain_tmp="$(mktemp 2>/dev/null)"
  [ -n "$plain_tmp" ] || plain_tmp="/tmp/vf-design-deps-plain.$$"
  claude plugin list 2>/dev/null | tr -d '\r' >"$plain_tmp" 2>/dev/null
  SOURCE_LINES="$(awk '
    {
      if (match($0, /[A-Za-z0-9._-]+@[A-Za-z0-9._-]+/) > 0) {
        id = substr($0, RSTART, RLENGTH)
        next
      }
      if ($0 ~ /Status:/) {
        if (id != "") {
          if ($0 ~ /enabled/) { print id, "true" }
          else if ($0 ~ /disabled/) { print id, "false" }
          id = ""
        }
      }
    }
  ' "$plain_tmp")"
  rm -f "$plain_tmp" 2>/dev/null
}

# ---------- État final par plugin (résumé) ----------
ST_superpowers=""
ST_ui_ux_pro_max=""
ST_frontend_design=""
ST_impeccable=""

set_final_state() {
  case "$1" in
    superpowers) ST_superpowers="$2" ;;
    ui-ux-pro-max) ST_ui_ux_pro_max="$2" ;;
    frontend-design) ST_frontend_design="$2" ;;
    impeccable) ST_impeccable="$2" ;;
  esac
}

# ---------- Traitement d'un plugin de la table ----------
process_plugin() { # name marketplace mkt_add
  local name="$1" marketplace="$2" mkt_add="$3"
  local matches state effective final

  if [ "$INDETERMINE" -eq 1 ]; then
    print_manual_step "$name"
    set_final_state "$name" "indetermine"
    return 0
  fi

  # État par plugin, dérivé de la cascade : « enabled » = au moins une entrée du même nom porte
  # enabled=true (preuve terrain : frontend-design a 2 marketplaces, un actif un non — découverte
  # 4). « disabled » = au moins une entrée existe, aucune n'est active. « absent » = aucune entrée.
  matches="$(printf '%s\n' "$SOURCE_LINES" | grep -E "^${name}@[^ ]+ (true|false)\$" 2>/dev/null || true)"
  if printf '%s\n' "$matches" | grep -q ' true$' 2>/dev/null; then
    state="enabled"
  elif [ -n "$matches" ]; then
    state="disabled"
  else
    state="absent"
  fi

  # FORCE (dry-run uniquement) : court-circuite le verdict réel pour rendre observable la commande
  # scopée qui serait émise, même sur une machine déjà équipée — jamais d'effet en réel.
  effective="$state"
  if [ -n "$DRY_RUN" ] && [ -n "$FORCE" ]; then
    effective="absent"
  fi

  case "$effective" in
    enabled)
      log "$name : déjà actif (skip)."
      final="actif"
      ;;
    disabled)
      local canonical chosen
      canonical="$(printf '%s\n' "$matches" | grep -F "@${marketplace} " | head -1)"
      if [ -n "$canonical" ]; then
        chosen="$(printf '%s\n' "$canonical" | awk '{print $1}')"
      else
        chosen="$(printf '%s\n' "$matches" | head -1 | awk '{print $1}')"
      fi
      if valid_plugin_id "$chosen"; then
        if run_cmd claude plugin enable "$chosen" --scope "$SCOPE"; then
          final="réactivé"
        else
          err "$name : échec de la réactivation ($chosen)."
          print_manual_step "$name"
          final="manquant"
        fi
      else
        err "$name : identifiant rejeté par la validation avant passage en argument ($chosen)."
        print_manual_step "$name"
        final="manquant"
      fi
      ;;
    absent)
      if [ "$mkt_add" != "-" ]; then
        run_cmd claude plugin marketplace add "$mkt_add" \
          || log "$name : ajout du marketplace $mkt_add en échec (peut-être déjà enregistré) — tentative d'install quand même."
      fi
      if run_cmd claude plugin install "${name}@${marketplace}" --scope "$SCOPE"; then
        final="installé"
      else
        err "$name : échec de l'installation."
        print_manual_step "$name"
        final="manquant"
      fi
      ;;
  esac

  set_final_state "$name" "$final"
}

# ---------- Main ----------
main() {
  log "Bootstrap chaîne d'outils design (mode=$([ -n "$DRY_RUN" ] && echo dry-run || echo apply), scope=$SCOPE)"

  detect_all

  if [ "$INDETERMINE" -eq 1 ]; then
    err "CLI 'claude' introuvable — impossible de vérifier présence/activation. Étapes manuelles :"
  fi

  # TABLE DES 4 PLUGINS — littérale, jamais dérivée de l'environnement ni d'une entrée JSON
  # (T-Q-02). Trois champs : nom, marketplace canonique, dépôt de marketplace à ajouter d'abord
  # (tiret = aucun). Jumelle de la table d'install de design-toolchain.md (voir en-tête).
  while IFS=' ' read -r p_name p_marketplace p_mkt_add; do
    [ -n "$p_name" ] || continue
    process_plugin "$p_name" "$p_marketplace" "$p_mkt_add"
  done <<'TABLE'
superpowers claude-plugins-official -
ui-ux-pro-max ui-ux-pro-max-skill -
frontend-design claude-plugins-official -
impeccable impeccable pbakaus/impeccable
TABLE

  log "Résumé : superpowers=${ST_superpowers} ; ui-ux-pro-max=${ST_ui_ux_pro_max} ; frontend-design=${ST_frontend_design} ; impeccable=${ST_impeccable}"
  return 0
}

# ---------- Parsing minimal des arguments ----------
# Seul -h/--help est reconnu ; tout le reste est IGNORÉ avec une ligne log, jamais un exit
# non-zéro (rétro-compat, cf. en-tête).
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) log "argument ignoré (rétro-compat, non reconnu) : $arg" ;;
  esac
done

main "$@"
