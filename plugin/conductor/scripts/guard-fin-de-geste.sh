#!/usr/bin/env bash
# guard-fin-de-geste.sh — SOBR-07 (phase 41.3), volet TRAVAIL DIRECT. Ce qu'une session crée, elle le
# range avant de s'arrêter : à la fin d'un travail direct (hors mission de manager, dont la clôture a
# son propre contrôle : E7 de check-mission-exit.sh), ce hook archive ce qui déborde d'un budget et
# bloque UNE FOIS pour que la session range ce qu'elle a laissé (arbitrage Samuel, AskUserQuestion
# session principale, 2026-09-29 et 2026-09-30 ; ADR-076).
#
# Deux appels, un script, le même patron que planning-session-snapshot.sh / guard-planning-updated.sh :
#   --snapshot   SessionStart (sans matcher, first-wins) : photographie, LECTURE SEULE, les lignes à
#                jetons de `check-method-budget.sh --no-remote --quiet --root <projet>` (sans --auto).
#                Stdout STRICTEMENT vide (HOOKS-CONTRAT-SORTIE §3).
#   (aucun)      Stop : lance `check-method-budget.sh --auto --no-remote --quiet --root <projet>` ;
#                nouveau = lignes à jetons d'après moins celles du snapshot, plus toute ligne ARCHIVÉ.
#                Non vide : BLOCAGE (stderr + exit 2, forme du contrat de sortie) qui dit ce qui a été
#                archivé sans geste humain (INDEX, restauration, à commiter) et demande de ranger ce que
#                la session a créé — worktree (remove sans --force), branche locale (-d), stash (patch
#                sous .planning/archives/stash/ puis drop), mémoire (git add) ; JAMAIS une branche
#                distante (geste humain, jamais celles de Willy). Le reste va au rapport.
#
# Jetons lus (contrat de check-method-budget.sh) : RANGEABLE, ARCHIVABLE, ARCHIVÉ, ARCHIVAGE REFUSÉ,
# À VALIDER (bloquent s'ils sont NOUVEAUX) ; DÉPASSÉ / PROSE DÉPASSÉ = constat, cité sur stderr, ne bloque
# jamais ; ARCHIVAGE NON TENTÉ = dit sur stderr (rien déplacé), ne bloque pas.
#
# GARDE-FOUS (T-41.3-10) : un blocage AU PLUS par session (marqueur posé dès que le Stop agit) ; aucun
# Stop suivant n'archive ni ne re-bloque ; `stop_hook_active` → exit 0 ; VF_FIN_DE_GESTE = block (défaut) |
# warn (stderr, exit 0, RIEN déplacé : le mode lecture seule) | off ; snapshot, script de budget ou
# session_id absent, stdin illisible → fail-open BRUYANT (stderr `NON VÉRIFIABLE`, exit 0), jamais un vert
# muet. VF_METHOD_BUDGET remplace le script de budget (suites seulement).
# Exit : 0 (autorise l'arrêt) ou 2 (bloque, une fois). Jamais d'autre code.
set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"
MODE_SNAPSHOT=0
[ "${1:-}" = "--snapshot" ] && MODE_SNAPSHOT=1

nv() { echo "[fin-de-geste] NON VÉRIFIABLE : $1" >&2; exit 0; }

if [ "$MODE_SNAPSHOT" -eq 0 ]; then
  case "$INPUT" in
    *'"stop_hook_active": true'*|*'"stop_hook_active":true'*) exit 0 ;;
  esac
fi

MODE="${VF_FIN_DE_GESTE:-block}"
[ "$MODE" = "off" ] && exit 0

SID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | tr -cd 'A-Za-z0-9._-')
[ -n "$SID" ] || nv "session_id illisible sur stdin, garde sans objet pour cette session"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
[ -n "$ROOT" ] || ROOT="$PWD"
BUDGET="${VF_METHOD_BUDGET:-$(dirname "$0")/check-method-budget.sh}"
[ -f "$BUDGET" ] || nv "script de budget introuvable : $BUDGET"

DIR="${TMPDIR:-/tmp}/vibeflow-fin-de-geste"
KEY=$(printf '%s' "$ROOT" | cksum 2>/dev/null | awk '{print $1}')
[ -n "$KEY" ] || nv "clé de dépôt non calculable"
SNAP="$DIR/${KEY}-${SID}.snap"
ACTED="$DIR/${KEY}-${SID}.acted"
TOKENS='RANGEABLE|ARCHIVABLE|ARCHIVÉ|ARCHIVAGE REFUSÉ|À VALIDER|DÉPASSÉ'
jetons() { { grep -E "$TOKENS" || true; } | sed 's/^\[budget\] *//' | LC_ALL=C sort -u; }

if [ "$MODE_SNAPSHOT" -eq 1 ]; then
  mkdir -p "$DIR" 2>/dev/null || nv "dossier d'état impossible : $DIR"
  find "$DIR" -type f \( -name '*.snap' -o -name '*.acted' \) -mtime +7 -delete 2>/dev/null || true
  [ -f "$SNAP" ] && exit 0                                   # first-wins : un compact ré-émet SessionStart
  OUT="$(bash "$BUDGET" --no-remote --quiet --root "$ROOT" 2>/dev/null)"; RC=$?
  [ "$RC" -le 2 ] || nv "check-method-budget a rendu $RC au snapshot, baseline non posée"
  printf '%s\n' "$OUT" | jetons > "$SNAP.tmp.$$" 2>/dev/null && mv -f "$SNAP.tmp.$$" "$SNAP" 2>/dev/null
  exit 0
fi

# Déjà agi une fois dans cette session : ni archivage, ni re-blocage.
[ -f "$ACTED" ] && exit 0
[ -f "$SNAP" ] || nv "snapshot de début de session absent (SessionStart non joué), rien jugé"

ARGS=(--no-remote --quiet --root "$ROOT")
# Mode warn : lecture seule, RIEN déplacé. Sinon --auto : la session décide, l'outil archive seul.
[ "$MODE" = "warn" ] || ARGS=(--auto "${ARGS[@]}")
OUT="$(bash "$BUDGET" "${ARGS[@]}" 2>/dev/null)"; RC=$?
[ "$RC" -le 2 ] || nv "check-method-budget a rendu $RC, garde sans verdict"

printf '%s\n' "$OUT" | jetons > "$DIR/$KEY-$SID.now" 2>/dev/null
NOUVEAU="$(LC_ALL=C comm -23 "$DIR/$KEY-$SID.now" "$SNAP" | grep -v 'DÉPASSÉ')"
DEPASSE="$(grep 'DÉPASSÉ' "$DIR/$KEY-$SID.now")"
rm -f "$DIR/$KEY-$SID.now"
NON_TENTE="$(printf '%s\n' "$OUT" | grep 'ARCHIVAGE NON TENTÉ')"
[ -n "$NON_TENTE" ] && echo "[fin-de-geste] $NON_TENTE" >&2
[ -n "$DEPASSE" ] && printf '[fin-de-geste] budget dépassé (constat, rien à faire ici) :\n%s\n' "$DEPASSE" >&2
[ -n "$NOUVEAU" ] || exit 0

ARCH=""
case "$NOUVEAU" in
  *ARCHIVÉ*) ARCH="
Déjà ARCHIVÉ sans geste humain : un déplacement tracé dans .planning/archives/INDEX.tsv, réversible (git cat-file blob <ref de l'INDEX>) — à commiter, ou à restaurer si c'est une erreur." ;;
esac
MSG="⛔ Fin de geste : cette session laisse du rangement derrière elle.
$NOUVEAU
$ARCH
À ranger : worktree créé (git worktree remove, sans --force), branche locale intégrée (git branch -d), stash (patch sous .planning/archives/stash/ puis drop), mémoire non indexée (git add). Jamais une branche distante : geste humain. Ce qui n'est pas rangeable va dans ton rapport.
Ce garde ne bloquera plus cette session. Toggles : VF_FIN_DE_GESTE=warn|off."

if [ "$MODE" = "warn" ]; then
  echo "[fin-de-geste] $MSG" >&2
  exit 0
fi
mkdir -p "$DIR" 2>/dev/null || true
# Au pire UN blocage par session.
: > "$ACTED" 2>/dev/null || true
echo "$MSG" >&2
exit 2
