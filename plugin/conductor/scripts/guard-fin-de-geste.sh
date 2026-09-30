#!/usr/bin/env bash
# guard-fin-de-geste.sh — SOBR-07 (phase 41.3), volet TRAVAIL DIRECT. Ce qu'une session crée, elle le
# range avant de s'arrêter : à la fin d'un travail direct (hors mission de manager, dont la clôture a
# son propre contrôle : E7 de check-mission-exit.sh), ce hook archive ce qui déborde d'un budget et
# BLOQUE l'arrêt tant qu'il reste du rangement attribué à la session (arbitrage Samuel, AskUserQuestion
# session principale, 2026-09-29 : nettoyage de fin de geste, gaté ; arbitrage Samuel, AskUserQuestion
# session principale, 2026-09-30 : blocage à chaque arrêt, coupe-circuit à 3 blocages sans progrès ;
# feu vert de la vague 2 : Samuel, session principale, 2026-09-30 ; ADR-076).
#
# Deux appels, un script, le même patron que planning-session-snapshot.sh / guard-planning-updated.sh :
#   --snapshot   SessionStart (sans matcher, first-wins) : photographie, LECTURE SEULE, les lignes à
#                jetons de `check-method-budget.sh --no-remote --quiet --root <projet>` (sans --auto).
#                Stdout STRICTEMENT vide sur le chemin nominal (HOOKS-CONTRAT-SORTIE §3).
#   (aucun)      Stop : lance `check-method-budget.sh --auto --no-remote --quiet --root <projet>`.
#
# ATTRIBUTION (M3) : la garde ne juge et ne propose de ranger QUE ce qui est apparu DEPUIS le snapshot de
# CETTE session (ensemble d'après moins ensemble du snapshot). Ce qui existait au démarrage n'est jamais
# imputé. Limite assumée : deux sessions ouvertes en même temps sur le même dépôt ne se distinguent pas
# l'une de l'autre ; le message le dit (« pas de ta main : ne le supprime pas, cite-le au rapport ») et le
# coupe-circuit borne le coût d'une méprise.
#
# CE QUI BLOQUE (exit 2, stderr = la raison donnée à la session) : une ligne RANGEABLE nouvelle
# (worktree/branche intégrés, stash, mémoire non indexée) — c'est ce que la session peut ranger elle-même.
# Jamais une branche distante : geste humain.
# CE QUI NE BLOQUE JAMAIS, dit à l'UTILISATEUR (exit 0, UN document JSON sur stdout, champ `systemMessage` :
# avertissement affiché à l'utilisateur, code.claude.com/docs/en/hooks § JSON output ; le stderr d'un exit 0
# n'est PAS vu de lui) : ARCHIVÉ (déplacement tracé sous .planning/archives/INDEX.tsv, réversible, à
# commiter ; y compris celui d'un sujet clos préexistant), ARCHIVABLE resté, ARCHIVAGE REFUSÉ (source
# modifiée, dépôt non git, compartiment protégé : rien que la session puisse faire ici), ARCHIVAGE NON
# TENTÉ, DÉPASSÉ (résumé en UNE ligne), NON VÉRIFIABLE. Un seul document JSON par exécution, produit par
# un encodeur (jq, sinon python3) — HOOKS-CONTRAT-SORTIE §3 bis.
#
# COUPE-CIRCUIT : un état par session (count, taille, relâché). Un blocage par arrêt tant que l'ensemble
# attribué n'est pas vide ; après 3 blocages de suite SANS PROGRÈS (progrès = l'ensemble attribué a
# diminué, le compteur repart de zéro), le Stop laisse sortir avec un message VISIBLE et se tait ensuite.
# `stop_hook_active` n'arrête donc PLUS la garde (il la rendait muette dès le 2e arrêt) : la boucle est
# bornée par ce compteur. Ensemble vide : état effacé, sortie muette. VF_FIN_DE_GESTE = block (défaut) |
# warn (dit, exit 0, RIEN déplacé : lecture seule) | off ; snapshot, script de budget ou session_id
# absent, stdin illisible → fail-open BRUYANT (systemMessage `NON VÉRIFIABLE`, exit 0), jamais un vert
# muet. VF_METHOD_BUDGET remplace le script de budget (suites seulement).
# Jetons lus (contrat de check-method-budget.sh) : RANGEABLE, ARCHIVABLE, ARCHIVÉ, ARCHIVAGE REFUSÉ,
# ARCHIVAGE NON TENTÉ, DÉPASSÉ / PROSE DÉPASSÉE. Le jeton de remote (À VALIDER) n'est PAS lu : cette garde
# appelle le budget avec --no-remote, qui ne le rend jamais.
# Exit : 0 (autorise l'arrêt) ou 2 (bloque). Jamais d'autre code.
set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"
MODE_SNAPSHOT=0
[ "${1:-}" = "--snapshot" ] && MODE_SNAPSHOT=1

NL=$'\n'
VIS=""
vis() { VIS="${VIS}${VIS:+$NL}$1"; }
emit() {  # UN document JSON {"systemMessage": …} si du visible a été accumulé ; encodeur, jamais de concaténation
  [ -n "$VIS" ] || return 0
  if command -v jq >/dev/null 2>&1; then jq -cn --arg m "$VIS" '{systemMessage: $m}' 2>/dev/null && return 0; fi
  if command -v python3 >/dev/null 2>&1; then python3 -c 'import json,sys; print(json.dumps({"systemMessage": sys.argv[1]}))' "$VIS" 2>/dev/null && return 0; fi
  printf '%s\n' "$VIS" >&2   # aucun encodeur : dernier recours, jamais un JSON écrit à la main
}
sortie_ok() { emit; exit 0; }
nv() { vis "[fin-de-geste] NON VÉRIFIABLE : $1"; sortie_ok; }

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
BLK="$DIR/${KEY}-${SID}.blk"
SEEN="$DIR/${KEY}-${SID}.seen"
MAX_BLOCS=3
TOKENS='RANGEABLE|ARCHIVABLE|ARCHIVÉ|ARCHIVAGE REFUSÉ|DÉPASSÉ'
jetons() { { grep -E "$TOKENS" || true; } | sed 's/^\[budget\] *//' | LC_ALL=C sort -u; }

if [ "$MODE_SNAPSHOT" -eq 1 ]; then
  mkdir -p "$DIR" 2>/dev/null || nv "dossier d'état impossible : $DIR"
  find "$DIR" -type f \( -name '*.snap' -o -name '*.blk' -o -name '*.seen' -o -name '*.acted' \) -mtime +7 -delete 2>/dev/null || true
  [ -f "$SNAP" ] && exit 0                                   # first-wins : un compact ré-émet SessionStart
  OUT="$(bash "$BUDGET" --no-remote --quiet --root "$ROOT" 2>/dev/null)"; RC=$?
  [ "$RC" -le 2 ] || nv "check-method-budget a rendu $RC au snapshot, baseline non posée"
  printf '%s\n' "$OUT" | jetons > "$SNAP.tmp.$$" 2>/dev/null && mv -f "$SNAP.tmp.$$" "$SNAP" 2>/dev/null
  exit 0
fi

[ -f "$SNAP" ] || nv "snapshot de début de session absent (SessionStart non joué), rien jugé"

ARGS=(--no-remote --quiet --root "$ROOT")
# Mode warn : lecture seule, RIEN déplacé. Sinon --auto : la session décide, l'outil archive seul.
[ "$MODE" = "warn" ] || ARGS=(--auto "${ARGS[@]}")
OUT="$(bash "$BUDGET" "${ARGS[@]}" 2>/dev/null)"; RC=$?
[ "$RC" -le 2 ] || nv "check-method-budget a rendu $RC, garde sans verdict"

NOW="$DIR/$KEY-$SID.now"
printf '%s\n' "$OUT" | jetons > "$NOW" 2>/dev/null
NOUVEAU="$(LC_ALL=C comm -23 "$NOW" "$SNAP")"               # apparu depuis le snapshot de CETTE session
rm -f "$NOW"
BLOQUANT="$(printf '%s\n' "$NOUVEAU" | grep '^RANGEABLE' || true)"
ARCHIVE="$(printf '%s\n' "$NOUVEAU" | grep '^ARCHIVÉ' || true)"
RESTE="$(printf '%s\n' "$NOUVEAU" | grep -E '^(ARCHIVABLE|ARCHIVAGE REFUSÉ)' || true)"
DEPASSE="$(printf '%s\n' "$NOUVEAU" | grep 'DÉPASSÉ' || true)"
NON_TENTE="$(printf '%s\n' "$OUT" | grep 'ARCHIVAGE NON TENTÉ' | sed 's/^\[budget\] *//' || true)"

# Constats pour l'utilisateur (jamais bloquants), dédupliqués d'un arrêt à l'autre : on ne répète pas le même.
CONSTATS=""
cons() { CONSTATS="${CONSTATS}${CONSTATS:+$NL}$1"; }
[ -n "$NON_TENTE" ] && cons "[fin-de-geste] $NON_TENTE"
[ -n "$ARCHIVE" ] && cons "[fin-de-geste] Archivé sans geste humain (déplacement tracé dans .planning/archives/INDEX.tsv, réversible : git cat-file blob <ref de l'INDEX>) — à commiter, ou à restaurer si c'est une erreur :$NL$ARCHIVE"
[ -n "$RESTE" ] && cons "[fin-de-geste] Rien que cette session puisse ranger ici (source modifiée, dépôt non git, compartiment protégé), dit et non bloquant :$NL$RESTE"
[ -n "$DEPASSE" ] && cons "[fin-de-geste] budget dépassé (constat, rien à faire ici) : $(printf '%s\n' "$DEPASSE" | wc -l | tr -d ' ') ligne(s), la première : $(printf '%s\n' "$DEPASSE" | head -1 | cut -c1-160)"
publier() {  # constats non bloquants → utilisateur, une seule fois tant qu'ils ne changent pas
  [ -n "$CONSTATS" ] || return 0
  mkdir -p "$DIR" 2>/dev/null || true
  local sig; sig="$(printf '%s' "$CONSTATS" | cksum | awk '{print $1}')"
  [ "$(cat "$SEEN" 2>/dev/null)" = "$sig" ] && return 0
  vis "$CONSTATS"; printf '%s\n' "$sig" > "$SEEN" 2>/dev/null || true
}

if [ -z "$BLOQUANT" ]; then rm -f "$BLK" 2>/dev/null; publier; sortie_ok; fi   # rien d'attribué à ranger (ou fini) : état effacé

if [ "$MODE" = "warn" ]; then
  publier
  vis "[fin-de-geste] Rangement laissé par cette session (mode warn, rien déplacé, rien bloqué) :$NL$BLOQUANT"
  sortie_ok
fi

# --- Coupe-circuit : N blocages de suite sans progrès, puis on laisse sortir, visiblement ---------------
TAILLE="$(printf '%s\n' "$BLOQUANT" | wc -l | tr -d ' ')"
mkdir -p "$DIR" 2>/dev/null || true
P_COUNT=0; P_TAILLE=""; P_LACHE=0
[ -f "$BLK" ] && read -r P_COUNT P_TAILLE P_LACHE < "$BLK" 2>/dev/null
case "$P_COUNT" in ''|*[!0-9]*) P_COUNT=0 ;; esac
case "$P_LACHE" in ''|*[!0-9]*) P_LACHE=0 ;; esac
# Progrès : l'ensemble attribué a diminué depuis le dernier arrêt → le compteur repart de zéro.
case "$P_TAILLE" in ''|*[!0-9]*) ;; *) if [ "$TAILLE" -lt "$P_TAILLE" ]; then P_COUNT=0; P_LACHE=0; fi ;; esac
if [ "$P_LACHE" -eq 1 ]; then printf '%s %s 1\n' "$P_COUNT" "$TAILLE" > "$BLK" 2>/dev/null; publier; sortie_ok; fi   # déjà dit une fois
if [ "$P_COUNT" -ge "$MAX_BLOCS" ]; then
  printf '%s %s 1\n' "$P_COUNT" "$TAILLE" > "$BLK" 2>/dev/null || true
  publier
  vis "[fin-de-geste] Coupe-circuit : $MAX_BLOCS blocages de suite sans progrès, je laisse sortir. Reste non rangé (attribué à cette session par le snapshot, peut-être pas de sa main) :$NL$BLOQUANT${NL}À ranger à la main ou à citer au rapport. Toggle : VF_FIN_DE_GESTE=warn|off."
  sortie_ok
fi
P_COUNT=$((P_COUNT + 1))
printf '%s %s 0\n' "$P_COUNT" "$TAILLE" > "$BLK" 2>/dev/null || true
{
  echo "[fin-de-geste] Fin de geste : cette session laisse du rangement derrière elle (blocage $P_COUNT/$MAX_BLOCS, sans progrès le dernier laisse sortir)."
  printf '%s\n' "$BLOQUANT"
  [ -n "$CONSTATS" ] && printf '%s\n' "$CONSTATS"
  echo "À ranger, seulement ce que CETTE session a créé : worktree (git worktree remove, sans --force), branche locale intégrée (git branch -d), stash (patch sous .planning/archives/stash/ puis drop), mémoire non indexée (git add). Jamais une branche distante : geste humain. Un objet qui n'est pas de ta main (autre session) : ne le supprime pas, cite-le dans ton rapport. Toggles : VF_FIN_DE_GESTE=warn|off."
} >&2
exit 2
