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
# Résolution et validation du nom : `workstream-policy.sh` (ce module), fichier SOURCÉ et partagé
# par les quatre gates — voir son en-tête pour la politique UNIQUE, la parité amont exacte et la
# gradation par rôle du cas « résolu mais dossier absent ». La surcharge historique
# VF_CONTEXT_WORKSTREAM reste le premier canal ; un nom hors politique n'est JAMAIS concaténé, et
# sa valeur brute jamais réimprimée (T-24-04-01).
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

# Une option sans valeur ne doit JAMAIS être avalée : un `${2:-défaut}` + `shift 2` ne consommait
# rien et bouclait à l'infini (gel du SessionStart jusqu'au timeout). Les gardes explicites
# ci-dessous rendent 64 comme les scripts frères, là où `${2:?}` rendait 1 (code d'erreur du shell,
# pas un code d'usage) et où un flag inconnu était avalé en exit 0 — un `--max-lines` mal
# orthographié se lisait alors comme un succès silencieux.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      [ "$#" -ge 2 ] || { echo "[planning-context] --path nécessite une valeur" >&2; exit 64; }
      PLANNING_DIR="$2"; shift 2 ;;
    --max-lines)
      [ "$#" -ge 2 ] || { echo "[planning-context] --max-lines nécessite une valeur" >&2; exit 64; }
      MAX_LINES="$2"; shift 2 ;;
    --defer-to-gsd) DEFER_TO_GSD=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[planning-context] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# --max-lines est un COMPTE DE LIGNES, et il est passé tel quel à `head -n`. Sans cette validation,
# `--max-lines abc` faisait entrer « head: illegal line count -- abc » DANS le bloc présenté comme
# l'état du lab, en exit 0 : un message d'erreur d'outil injecté dans le contexte de session et
# offert à la lecture comme un fait du projet. Un entier strictement positif, ou rien.
case "$MAX_LINES" in
  ''|*[!0-9]*) echo "[planning-context] --max-lines attend un entier positif" >&2; exit 64 ;;
esac
[ "$MAX_LINES" -ge 1 ] || { echo "[planning-context] --max-lines attend un entier positif" >&2; exit 64; }

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
# La politique de nom n'est PLUS recopiée ici : elle est SOURCÉE (le fichier est possédé par CE
# module — voir son en-tête pour la politique UNIQUE et sa gradation par rôle).
WS_POLICY=""
for _cand in "$(dirname "$0")/workstream-policy.sh" \
             "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
  [ -r "$_cand" ] && { WS_POLICY="$_cand"; break; }
done

WS_LABEL=""
WS_NOTE=""
if [ -z "$WS_POLICY" ]; then
  # RÔLE INJECTEUR : fail-open, jamais muet, jamais un exit non nul (hook SessionStart).
  WS_NOTE="_(politique de workstream non chargeable — extrait de la racine.)_"
else
  # shellcheck source=/dev/null
  . "$WS_POLICY"
  vf_ws_resolve "$PLANNING_DIR" "${VF_CONTEXT_WORKSTREAM:-}"; ws_rc=$?
  if [ "$ws_rc" -eq 2 ]; then
    # La valeur brute n'est JAMAIS réimprimée : elle traverserait vers le contexte de session
    # (frontière T-17-01) et elle est non maîtrisée par construction. Seule la raison, prise dans
    # une énumération fermée, est imprimable.
    WS_NOTE="_(workstream rejeté par la politique amont : $VF_WS_REASON — extrait de la racine.)_"
  elif [ -n "$VF_WS_NAME" ]; then
    if [ -f "$PLANNING_DIR/workstreams/$VF_WS_NAME/STATE.md" ]; then
      STATE_FILE="$PLANNING_DIR/workstreams/$VF_WS_NAME/STATE.md"
      WS_LABEL="$VF_WS_NAME"
    else
      WS_NOTE="_(workstream \`$VF_WS_NAME\` actif, mais aucun \`$PLANNING_DIR/workstreams/$VF_WS_NAME/STATE.md\` — extrait de la racine.)_"
    fi
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
