#!/usr/bin/env bash
# planning-context.sh — Injecte un DIGEST planning au démarrage de session (SessionStart).
#
# Rôle (ADR-050) : là où check-planning-state.sh se contente de SIGNALER la fraîcheur,
# ce script INJECTE réellement le contexte planning — en respectant la structuration du
# contexte (index-first, jamais saturant) :
#   - lab À COMPARTIMENTS (.planning/INDEX.md présent) → injecte l'INDEX (compartiments +
#     statut 1 ligne) + une directive « lis le STATE du compartiment ciblé avant d'agir ».
#     Le STATE du bon compartiment est injecté APRÈS, à la tâche, par planning-task-context.sh
#     (UserPromptSubmit) — on ne charge donc jamais tous les compartiments d'un coup.
#   - lab MONO (.planning/STATE.md présent, pas d'INDEX) → injecte un EXTRAIT BORNÉ de STATE.md.
#   - lab non amorcé (pas de .planning/) → rien (check-planning-state.sh porte déjà le rappel).
#
# Sortie = texte markdown sur stdout (ajouté au contexte de session par Claude Code au SessionStart).
# Fail-open : jamais bloquant, toute erreur → exit 0 silencieux.
#
# Usage:
#   planning-context.sh [--path <dir>] [--max-lines <N>] [--defer-to-gsd]
# Defaults: --path .planning  --max-lines 45
#
# Env (workstreams GSD, GSDA-14) :
#   VF_CONTEXT_WORKSTREAM (workstream actif ; prime sur GSD_WORKSTREAM et sur le pointeur)
#   GSD_WORKSTREAM        (canal de premier rang du moteur GSD amont)
#
# WORKSTREAMS — QUEL RÉGIME EST AFFECTÉ, LESQUELS NE LE SONT PAS :
# Le moteur amont peut partitionner le planning en `.planning/workstreams/<nom>/`. SEUL le régime
# « lab MONO » suit le compartiment actif : l'extrait injecté vient alors de
# `<planning>/workstreams/<nom>/STATE.md` et l'en-tête d'injection NOMME le workstream — sans quoi
# l'injection mentirait par omission sur la provenance de l'état. Le régime « lab À COMPARTIMENTS »
# (INDEX.md présent) est INCHANGÉ, à l'octet près : l'INDEX est de l'altitude LAB, antérieur et
# orthogonal aux workstreams du moteur ; la résolution se fait donc APRÈS sa branche. Le régime
# « lab non amorcé » est inchangé lui aussi.
# Ordre de résolution, court-circuitant : VF_CONTEXT_WORKSTREAM, puis GSD_WORKSTREAM, puis la 1re
# ligne du pointeur PARTAGÉ in-repo `<planning>/active-workstream`. Nom validé contre la politique
# du moteur (workstream-name-policy.cjs : 1er caractère alphanumérique, puis alphanumériques, point,
# souligné, tiret ; ni séparateur de chemin, ni `.`/`..`, ni `..` en sous-chaîne) plus une borne
# locale de 80 caractères ; un nom hors politique n'est JAMAIS concaténé (T-24-04-01).
# FRONTIÈRE ASSUMÉE : le pointeur de SESSION en os.tmpdir() n'est PAS lu ici — indexé sur un
# condensat de chemin absolu et une clé de session que bash ne reproduit pas fidèlement.
# FAIL-OPEN INTACT : un workstream résolu SANS STATE.md ne bloque rien — repli sur la racine PLUS
# une ligne qui le nomme. Fail-open ne veut pas dire muet, et aucun cas ne sort non nul.
#
# --defer-to-gsd (ADR-055) : opt-in, câblé dans hooks.json uniquement. Sur un lab MONO dont le
# moteur GSD est actif, gsd-session-state.sh a déjà injecté l'état du projet → on se retire pour
# ne pas payer le contexte deux fois. Un lab À COMPARTIMENTS garde son injection : l'INDEX.md est
# de l'altitude LAB, GSD ne le produit pas. SANS ce flag, le comportement est strictement inchangé.
set -uo pipefail

PLANNING_DIR=".planning"
MAX_LINES=45
DEFER_TO_GSD=0

# NB : ${2:?} obligatoire (convention des scripts frères) — un ${2:-défaut} + shift 2 sans
# valeur ne consommait rien et bouclait à l'infini (gel du SessionStart jusqu'au timeout).
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path) PLANNING_DIR="${2:?--path nécessite une valeur}"; shift 2 ;;
    --max-lines) MAX_LINES="${2:?--max-lines nécessite une valeur}"; shift 2 ;;
    --defer-to-gsd) DEFER_TO_GSD=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) shift ;;
  esac
done

# Pas de socle → rien à injecter (le rappel "non amorcé" vient de check-planning-state.sh).
[ -d "$PLANNING_DIR" ] || exit 0

INDEX_FILE="$PLANNING_DIR/INDEX.md"
STATE_FILE="$PLANNING_DIR/STATE.md"

# --- ADR-055 : altitude lab uniquement quand GSD tient le projet ---
# Lab à compartiments (INDEX.md présent) → l'INDEX est de l'altitude LAB, GSD ne le produit
# pas : on injecte. Lab mono-projet sous moteur GSD → gsd-session-state.sh a déjà injecté
# l'état du projet : on se retire pour ne pas payer le contexte deux fois.
# NB : ce bloc doit rester APRÈS la définition de $INDEX_FILE — sinon la condition teste une
# variable vide et le lab à compartiments perd son injection (régression silencieuse).
if [ "$DEFER_TO_GSD" -eq 1 ] && [ ! -f "$INDEX_FILE" ]; then
  DETECT="$(dirname "$0")/detect-gsd-engine.sh"
  if [ -f "$DETECT" ]; then
    bash "$DETECT" --quiet --path "$PLANNING_DIR" && exit 0
  fi
fi

if [ -f "$INDEX_FILE" ]; then
  # --- Lab à compartiments : index-first ---
  INDEX_MAX=80
  total=$(wc -l < "$INDEX_FILE" | tr -d ' ')
  echo "## 📍 Contexte planning (injecté — lab à compartiments)"
  echo ""
  echo "Voici l'INDEX des compartiments du lab. **Avant d'agir sur un compartiment, lis d'abord son"
  echo "\`.planning/STATE.md\`** (borné) — ne charge pas tous les compartiments d'un coup (structuration"
  echo "du contexte). Le STATE du compartiment ciblé te sera injecté automatiquement quand ta tâche sera connue."
  echo ""
  echo '```'
  head -n "$INDEX_MAX" "$INDEX_FILE"
  echo '```'
  # Signaler la troncature (comme le chemin mono STATE) : sinon le modèle croit avoir tout l'INDEX.
  [ "$total" -gt "$INDEX_MAX" ] && echo "_(…tronqué — \`Read $INDEX_FILE\` pour la suite.)_"
  exit 0
fi

# --- Résolution du workstream actif (GSDA-14) — régime « lab MONO » UNIQUEMENT ------------------
# Position volontaire : APRÈS le bloc de retrait ADR-055 (qui doit rester après $INDEX_FILE) ET
# après la branche INDEX, qui sort en 0. C'est ce qui garantit que le régime « lab à compartiments »
# reste identique à l'octet près, workstream posé ou non.
# Politique de nom recopiée du moteur amont ; la borne de longueur est une addition LOCALE,
# strictement plus sévère — elle ne peut donc accepter aucun nom qu'amont refuserait.
ws_trim() { printf '%s' "$1" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

ws_name_valid() { # <nom>
  local n="$1"
  [ -n "$n" ] || return 1
  [ "${#n}" -le 80 ] || return 1
  case "$n" in */*|*\\*|.|..|*..*) return 1 ;; esac
  printf '%s' "$n" | grep -Eq '^[a-zA-Z0-9][a-zA-Z0-9._-]*$'
}

# Imprime le nom résolu ET valide, ou RIEN. Sort en 2 sans rien imprimer quand un nom résolu est
# hors politique — la valeur brute n'est jamais ré-imprimée : elle traverserait vers le contexte de
# session (frontière T-17-01), et elle est non maîtrisée par construction.
ws_resolve() {
  local n=""
  if [ -n "${VF_CONTEXT_WORKSTREAM:-}" ]; then
    n="$VF_CONTEXT_WORKSTREAM"
  elif [ -n "${GSD_WORKSTREAM:-}" ]; then
    n="$GSD_WORKSTREAM"
  elif [ -r "$PLANNING_DIR/active-workstream" ]; then
    n="$(head -n 1 "$PLANNING_DIR/active-workstream" 2>/dev/null)"
  fi
  n="$(ws_trim "$n")"
  [ -n "$n" ] || return 0
  ws_name_valid "$n" || return 2
  printf '%s' "$n"
}

WS="$(ws_resolve)"; ws_rc=$?
WS_LABEL=""
WS_NOTE=""
if [ "$ws_rc" -eq 2 ]; then
  WS_NOTE="_(un nom de workstream invalide a été ignoré — extrait de la racine.)_"
elif [ -n "$WS" ]; then
  if [ -f "$PLANNING_DIR/workstreams/$WS/STATE.md" ]; then
    STATE_FILE="$PLANNING_DIR/workstreams/$WS/STATE.md"
    WS_LABEL="$WS"
  else
    WS_NOTE="_(workstream \`$WS\` actif, mais aucun \`$PLANNING_DIR/workstreams/$WS/STATE.md\` — extrait de la racine.)_"
  fi
fi
# Émis AVANT la branche STATE : même sans STATE.md de racine, le signalement ne se perd pas.
[ -n "$WS_NOTE" ] && { echo "$WS_NOTE"; echo ""; }

if [ -f "$STATE_FILE" ]; then
  # --- Lab mono : injecter un extrait borné de STATE.md ---
  total=$(wc -l < "$STATE_FILE" | tr -d ' ')
  if [ -n "$WS_LABEL" ]; then
    echo "## 📍 Contexte planning (injecté — STATE.md du workstream \`$WS_LABEL\`, extrait borné)"
  else
    echo "## 📍 Contexte planning (injecté — STATE.md, extrait borné)"
  fi
  echo ""
  echo "État courant du lab (${MAX_LINES} premières lignes sur ${total} — lis le reste à la demande) :"
  echo ""
  echo '```'
  head -n "$MAX_LINES" "$STATE_FILE"
  echo '```'
  [ "$total" -gt "$MAX_LINES" ] && echo "_(…tronqué — \`Read $STATE_FILE\` pour la suite.)_"
  exit 0
fi

# .planning/ existe mais ni INDEX ni STATE : laisser check-planning-state.sh signaler.
exit 0
