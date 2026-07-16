#!/usr/bin/env bash
# guard-planning-updated.sh — Hook Stop : bloque la fin de session si le planning est en dette.
#
# Rôle (ADR-050) : un `.planning/` pas à jour est de la dette. Si des LIVRABLES ont changé
# pendant la session mais qu'AUCUN `.planning/STATE.md` n'a été mis à jour, on bloque l'arrêt
# une fois et on demande la mise à jour (Phase 7 de la boucle de mission, skill metier-orchestration).
#
# Event : Stop. Blocage = exit 2 (stderr renvoyé à Claude, qui continue). C'est le SEUL event
# capable de bloquer réellement la fin de session (SessionEnd est un cleanup non bloquant).
#
# GARDE-FOUS ANTI-PIÈGE (obligatoires) :
#   - anti-boucle : si `stop_hook_active` est déjà vrai (on continue DÉJÀ suite à un blocage
#     précédent), on n'arrête plus JAMAIS → au pire un seul blocage par session, jamais de trappe.
#   - ne bloque QUE si : repo git + un `.planning/` existe + des livrables ont changé + le planning
#     n'a PAS changé. Session read-only / config / hors-git → jamais bloquée.
#   - échappatoire explicite : marqueur `.planning/.session-noop` ou `.session-noop` → autorise
#     (l'utilisateur affirme « rien à noter »). Consommé (one-shot).
#   - toggle : VF_PLANNING_STOP = block (défaut) | warn (avertit, n'arrête pas) | off (désactivé).
#
# Fail-open partout : toute condition non réunie ou toute erreur → exit 0 (autorise l'arrêt).
set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"

# --- Anti-boucle : ne jamais re-bloquer une continuation déclenchée par un Stop précédent ---
case "$INPUT" in
  *'"stop_hook_active": true'*|*'"stop_hook_active":true'*) exit 0 ;;
esac

MODE="${VF_PLANNING_STOP:-block}"
[ "$MODE" = "off" ] && exit 0

# --- Doit être un repo git (sinon on ne sait pas ce qui a changé → pas de trappe) ---
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# --- Un socle .planning/ doit exister quelque part (lab amorcé) ---
has_planning=$(find . -type d -name .planning -not -path '*/.git/*' 2>/dev/null | head -1)
[ -n "$has_planning" ] || exit 0

# --- Échappatoire : marqueur "rien à noter" (consommé) ---
for marker in ".planning/.session-noop" ".session-noop"; do
  if [ -f "$marker" ]; then
    rm -f "$marker" 2>/dev/null || true
    exit 0
  fi
done

# --- Qu'est-ce qui a changé ? (working tree) ---
changes="$(git status --porcelain 2>/dev/null || true)"
[ -n "$changes" ] || exit 0   # rien n'a changé → rien à tracer → autorise

deliverable_changed=0
planning_changed=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  path="${line:3}"                              # retire "XY " (statut porcelain)
  case "$path" in *" -> "*) path="${path##* -> }";; esac   # rename → cible
  case "$path" in
    .planning/*|*/.planning/*) planning_changed=1 ;;       # planning mis à jour
    .claude/*|*/.claude/*)     : ;;                        # méta (registres, config) → ignoré
    *)                         deliverable_changed=1 ;;    # livrable métier
  esac
done <<EOF
$changes
EOF

# --- Décision : livrables changés MAIS planning pas mis à jour → dette ---
if [ "$deliverable_changed" -eq 1 ] && [ "$planning_changed" -eq 0 ]; then
  REASON="⛔ Planning pas à jour (dette). Des livrables ont changé cette session mais aucun .planning/STATE.md n'a été mis à jour. Avant de terminer : mets à jour le STATE.md du compartiment concerné (état, ce qui vient d'être livré, prochaines étapes) — Phase 7 de la boucle de mission. Si vraiment rien à noter : crée le marqueur .planning/.session-noop. Désactiver ce garde-fou : VF_PLANNING_STOP=off ; simple avertissement : VF_PLANNING_STOP=warn."
  if [ "$MODE" = "warn" ]; then
    echo "[planning-guard] $REASON"          # advisory : n'arrête pas
    exit 0
  fi
  echo "$REASON" >&2                          # block : stderr renvoyé à Claude
  exit 2
fi

exit 0
