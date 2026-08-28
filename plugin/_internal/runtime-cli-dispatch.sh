#!/usr/bin/env bash
# runtime-cli-dispatch.sh — table de dispatch runtime-aware pour les verbes CLI compagnons
# (list [--json|texte], install, enable, marketplace-add), partagée par les fichiers dont le
# couplage réel à `claude` dépasse le motif de l'étude Phase 37 (12 sites exécutables sur 4
# fichiers — 38-CONTEXT.md §« Corrections aux chiffres de l'étude 37 »). RUNT-01/RUNT-02.
#
# Usage :
#   runtime-cli-dispatch.sh detect
#   runtime-cli-dispatch.sh list-json
#   runtime-cli-dispatch.sh list-text
#   runtime-cli-dispatch.sh install <id> --scope <s>
#   runtime-cli-dispatch.sh enable <id> --scope <s>
#   runtime-cli-dispatch.sh marketplace-add <repo> --scope <s>
#   runtime-cli-dispatch.sh ensure-codex-preconditions
#
# Détection (`detect_agent_runtime`) : `VF_RUNTIME` (override explicite, prioritaire) sinon
# cascade de présence `command -v` dans l'ordre claude, codex, opencode, kimi-code — premier
# trouvé gagne, aucun trouvé → chaîne vide (« absent »). Jamais de détection via une variable
# d'environnement propriétaire d'un runtime tiers non mesurée.
#
# Runtimes RÉELLEMENT exécutés : `claude` (comportement actuel inchangé — `claude plugin ...`) et
# `codex` (canal natif `codex plugin`, assumé par défaut — MÊME forme d'arguments — mais NON
# mesuré sur le binaire réel : 38-CONTEXT.md liste en « Inconnus déclarés » que la commande exacte
# de sous-installation Codex après `codex plugin marketplace add` n'est pas mesurée). Tout le reste
# (opencode, kimi-code — non mesurés sur ce poste, ou runtime absent)
# → message d'étape manuelle + exit 0 (RUNT-02 : dégradation DÉCLARÉE, jamais un crash, jamais une
# exécution devinée pour une cible non mesurée).
#
# Contrat de sortie des verbes ACTIONNABLES (install/enable/marketplace-add) : sur runtime
# claude/codex, le code de sortie ET le stderr du sous-processus RÉEL sont RELAYÉS tels quels —
# jamais un succès supposé. Sur runtime non supporté (ou absent) : exit 0 systématique, jamais un
# crash qui interromprait l'appelant (ensure-deps.sh etc. — T-38-04).
#
# D-37-4 : `opencode run --auto` reste FORMELLEMENT INTERDIT — jamais construit ni suggéré ici,
# même pour OpenCode (seul mécanisme identifié qui convertit l'absence d'humain en consentement
# automatique).
#
# Résolution par les appelants : cascade à 2 positions, SYNTAXIQUEMENT identique à celle de
# `find_hooks_merger()` (plugin/_internal/vibeflow-update.sh) mais PAS la même garantie — l'analogie
# était fausse et a longtemps masqué un défaut (correction ciblée jointure, 38-CONTEXT.md). Pour
# `find_hooks_merger()`, `$0` désigne `vibeflow-update.sh` lui-même, dont la position reste TOUJOURS
# adjacente à `_internal/` : le candidat 2 y résout systématiquement. Pour ce fichier, `$0` désigne
# l'APPELANT (ensure-deps.sh, ensure-design-deps.sh, check-plugin-update.sh) — un script MODULE,
# jamais adjacent à `_internal/`. Le candidat 2 (`$(dirname "$0")/…`) ne résout QUE si ce fichier a
# lui-même été posé À PLAT à côté de l'appelant, sous `$TARGET_ROOT/scripts/` — ce que fait
# `copy_runtime_dispatch()` (plugin/_internal/vibeflow-update.sh, miroir de `copy_engine_lib()`
# pour `vf-portable.sh`), inconditionnellement à chaque exécution de l'engine. Sans cette pose,
# AUCUN des deux candidats ne résout en régime établi (ré-invocation via `/vf-update`, SessionStart,
# `/vf-calibrate`) — seule l'install initiale (où `$0` reste dans le cache) voyait le candidat 1
# résoudre. Introuvable aux deux positions → repli du CALLER sur son comportement `claude`-figé
# ACTUEL, jamais une régression silencieuse.

# Pas de `-e` : les détections (command -v, sous-processus CLI tiers) doivent pouvoir échouer sans
# tuer ce script — c'est précisément la dégradation gracieuse attendue (RUNT-02).
set -uo pipefail

# ---------- Détection du runtime ----------
detect_agent_runtime() {
  if [ -n "${VF_RUNTIME:-}" ]; then
    printf '%s' "$VF_RUNTIME"
    return 0
  fi
  local rt
  for rt in claude codex opencode kimi-code; do
    command -v "$rt" >/dev/null 2>&1 && { printf '%s' "$rt"; return 0; }
  done
  printf '%s' ""
}

# ---------- Message d'étape manuelle (runtime non supporté ou absent) ----------
manual_step_message() {
  local action="$1" arg="$2" scope="$3" detected="$4"
  local name="${arg%%@*}"
  {
    if [ -n "$detected" ]; then
      echo "[runtime-cli-dispatch] runtime détecté ('$detected') non supporté pour le dispatch CLI automatique (OpenCode/kimi-code : non mesurés sur ce poste, RUNT-02) — geste manuel requis."
    else
      echo "[runtime-cli-dispatch] aucun runtime CLI détecté — geste manuel requis."
    fi
    case "$action" in
      install)
        echo "  Étape manuelle ($name) : claude plugin install $arg${scope:+ --scope $scope} (ou l'équivalent CLI de votre runtime)"
        ;;
      enable)
        echo "  Étape manuelle ($name) : claude plugin enable $arg${scope:+ --scope $scope} (ou l'équivalent CLI de votre runtime)"
        ;;
      marketplace-add)
        echo "  Étape manuelle (marketplace $arg) : claude plugin marketplace add $arg${scope:+ --scope $scope} (ou l'équivalent CLI de votre runtime)"
        ;;
    esac
  } >&2
}

# ---------- Construction + exécution d'un verbe CLI sur un runtime SUPPORTÉ ----------
# claude/codex partagent la MÊME grammaire d'arguments (assumé par défaut, non mesuré sur le
# binaire réel — 38-CONTEXT.md). Le code de
# sortie et le stderr du sous-processus réel sont relayés tels quels — jamais avalés.
run_supported() {
  local runtime="$1" action="$2"
  shift 2
  case "$action" in
    list-json)      "$runtime" plugin list --json ;;
    list-text)      "$runtime" plugin list ;;
    install)        "$runtime" plugin install "$@" ;;
    enable)         "$runtime" plugin enable "$@" ;;
    marketplace-add) "$runtime" plugin marketplace add "$@" ;;
    *)
      echo "[runtime-cli-dispatch] verbe inconnu : $action" >&2
      return 2
      ;;
  esac
}

# ---------- Précondition Codex : multi_agent_v2 posé, trust_level DÉCLARÉ (jamais écrit) ----------
ensure_codex_preconditions() {
  command -v codex >/dev/null 2>&1 || return 0

  # 1) multi_agent_v2 — sans elle, AUCUN outil de spawn n'existe (38-CONTEXT.md l.445-456).
  #    Idempotent : on ne rappelle `enable` que si l'état lu est inactif.
  local list_out state
  list_out="$(codex features list 2>/dev/null || true)"
  # Dernier champ de la ligne portant le nom exact en 1er champ = état booléen (le libellé de
  # stade au milieu peut compter plusieurs mots — jamais présumer un nombre fixe de colonnes).
  state="$(printf '%s\n' "$list_out" | awk '$1=="multi_agent_v2"{print $NF}')"
  if [ "$state" = "false" ]; then
    echo "[runtime-cli-dispatch] Codex : multi_agent_v2 inactif — activation via 'codex features enable multi_agent_v2'." >&2
    if codex features enable multi_agent_v2 >/dev/null 2>&1; then
      echo "[runtime-cli-dispatch] Codex : multi_agent_v2 activé." >&2
    else
      echo "[runtime-cli-dispatch] Codex : ERREUR activation multi_agent_v2 — best-effort, ne bloque pas le reste du bootstrap." >&2
    fi
  elif [ "$state" = "true" ]; then
    : # déjà actif — idempotent, aucun appel `enable`.
  else
    echo "[runtime-cli-dispatch] Codex : état de multi_agent_v2 indéterminé ('codex features list' n'a pas rendu la ligne attendue) — non modifié." >&2
  fi

  # 2) trust_level — DÉCLARÉ, jamais auto-écrit (ADR-031). Aucune commande `codex trust`/`codex
  #    config set` n'existe sur ce binaire (mesuré) — la seule opération licite ici est la LECTURE.
  #    Résolution de racine ALIGNÉE avec plugin/conductor/scripts/check-artifact-fidelity.sh
  #    (TARGET_ROOT) : jamais de repli sur `pwd` hors dépôt git — un repli plus permissif ferait
  #    sonder aux deux gardes deux racines différentes pour le même fait (revue de jointure
  #    Phase 38, join-1). Si l'autre fichier change sa résolution, réplique ici.
  local repo_root codex_home cfg
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -z "$repo_root" ]; then
    echo "[runtime-cli-dispatch] Codex : trust_level non mesurable (racine du dépôt cible introuvable — hors dépôt git)." >&2
    return 0
  fi
  codex_home="${CODEX_HOME:-$HOME/.codex}"
  cfg="$codex_home/config.toml"
  if [ -f "$cfg" ] && grep -qF "[projects.\"$repo_root\"]" "$cfg" 2>/dev/null; then
    if awk -v marker="[projects.\"$repo_root\"]" '
        $0 == marker { in_block=1; next }
        in_block && /^\[/ { in_block=0 }
        in_block && /trust_level[[:space:]]*=[[:space:]]*"trusted"/ { found=1 }
        END { exit(found ? 0 : 1) }
      ' "$cfg" 2>/dev/null; then
      : # trust_level=trusted déjà déclaré pour ce dépôt — rien à dire.
    else
      echo "[runtime-cli-dispatch] Codex : trust_level non confirmé pour ce dépôt ('$repo_root') — .codex/agents/ ne sera pas parsé tant qu'un lancement interactif de 'codex' dans ce dossier n'aura pas répondu au prompt de confiance." >&2
    fi
  else
    echo "[runtime-cli-dispatch] Codex : trust_level non confirmé pour ce dépôt ('$repo_root') — .codex/agents/ ne sera pas parsé tant qu'un lancement interactif de 'codex' dans ce dossier n'aura pas répondu au prompt de confiance." >&2
  fi

  return 0
}

# ---------- Main ----------
VERB="${1:-}"
[ -n "$VERB" ] || { echo "[runtime-cli-dispatch] usage: runtime-cli-dispatch.sh <verb> [args...]" >&2; exit 2; }
shift || true

RUNTIME="$(detect_agent_runtime)"

case "$VERB" in
  detect)
    printf '%s\n' "$RUNTIME"
    exit 0
    ;;
  ensure-codex-preconditions)
    [ "$RUNTIME" = "codex" ] || exit 0
    ensure_codex_preconditions
    exit 0
    ;;
  list-json | list-text)
    case "$RUNTIME" in
      claude | codex)
        run_supported "$RUNTIME" "$VERB"
        exit $?
        ;;
      *)
        # Lecture pure : pas de message d'étape manuelle (rien à installer/activer) — sortie
        # vide, exit 0, l'appelant traite comme « indéterminé » (cascade S1/S2 déjà en place).
        exit 0
        ;;
    esac
    ;;
  install | enable | marketplace-add)
    ARG="${1:-}"
    # Extraction du --scope éventuel, sans supposer sa position.
    SCOPE=""
    args=("$@")
    for ((i = 0; i < ${#args[@]}; i++)); do
      if [ "${args[$i]}" = "--scope" ] && [ $((i + 1)) -lt ${#args[@]} ]; then
        SCOPE="${args[$((i + 1))]}"
        break
      fi
    done
    case "$RUNTIME" in
      claude | codex)
        run_supported "$RUNTIME" "$VERB" "$@"
        exit $?
        ;;
      *)
        manual_step_message "$VERB" "$ARG" "$SCOPE" "$RUNTIME"
        exit 0
        ;;
    esac
    ;;
  *)
    echo "[runtime-cli-dispatch] verbe inconnu : $VERB" >&2
    exit 2
    ;;
esac
