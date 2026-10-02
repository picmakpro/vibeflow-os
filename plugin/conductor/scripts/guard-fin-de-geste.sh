#!/usr/bin/env bash
# guard-fin-de-geste.sh — SOBR-07 (phase 41.3), volet TRAVAIL DIRECT. Ce qu'une session crée, elle le
# range avant de s'arrêter : à chaque fin de tour (le Stop part à chaque fin de tour, pas seulement à la
# fin de la session), ce hook archive ce qui déborde d'un budget et
# BLOQUE l'arrêt tant qu'il reste du rangement attribué à la session (arbitrage Samuel, AskUserQuestion
# session principale, 2026-09-29 : nettoyage de fin de geste, gaté ; arbitrage Samuel, AskUserQuestion
# session principale, 2026-09-30 : blocage à chaque arrêt, coupe-circuit à 3 blocages sans progrès ;
# feu vert de la vague 2 : Samuel, session principale, 2026-09-30 ; ADR-076).
#
# ACTIVATION (arbitrage Samuel, AskUserQuestion session principale, 2026-10-01 : « sentinelle armée ») : la garde
# n'agit QUE dans un dépôt armé, c'est-à-dire dont la racine (git rev-parse --show-toplevel du cwd, à défaut $PWD)
# porte le fichier `.planning/.fin-de-geste-armed` (même modèle que .instruction-budget-armed et
# .requirements-survival-armed). Sans lui : exit 0, aucune sortie, aucun fichier créé, aucun archivage, en
# --snapshot comme en Stop. Motif : le hook est câblé en scope user et s'activait sinon dans TOUS les dépôts de
# l'utilisateur, VibeFlow ou non. Lue tout en haut, avant tout effet ; VF_FIN_DE_GESTE=off|warn garde son sens
# dans un dépôt armé.
#
# Deux appels, un script, le même patron que planning-session-snapshot.sh / guard-planning-updated.sh :
#   --snapshot   SessionStart (sans matcher, first-wins) : photographie, LECTURE SEULE, les lignes à
#                jetons de `check-method-budget.sh --no-remote --quiet --root <projet>` (sans --auto).
#                Stdout STRICTEMENT vide sur le chemin nominal (HOOKS-CONTRAT-SORTIE §3).
#   (aucun)      Stop : lance `check-method-budget.sh --auto --no-remote --quiet --root <projet>`.
#
# PÉRIMÈTRE (dit tel qu'il est tenu) : le hook ne sait PAS si la session a conduit une mission de manager ; il
# s'applique à tout arrêt de session, et la référence de son attribution est le snapshot de DÉBUT DE SESSION.
# Une mission a son propre contrôle de clôture, E7 de check-mission-exit.sh, dont la référence est le snapshot de
# DÉBUT DE MISSION : les deux se cumulent, avec des références différentes, et peuvent nommer le même objet.
#
# ATTRIBUTION (M3) : la garde ne juge et ne propose de ranger QUE ce qui est apparu DEPUIS le snapshot de
# CETTE session (ensemble d'après moins ensemble du snapshot). Ce qui existait au démarrage n'est jamais
# imputé. Limite assumée : deux sessions ouvertes en même temps sur le même dépôt ne se distinguent pas
# l'une de l'autre ; le message le dit (« pas de ta main : ne le supprime pas, cite-le au rapport ») et le
# coupe-circuit borne le coût d'une méprise. Un stash est désigné par son SHA (jamais par sa position stash@{N},
# qui se décale à chaque nouveau stash et ferait imputer à la session un stash préexistant).
#
# CE QUI BLOQUE (exit 2, stderr = la raison donnée à la session) : une ligne RANGEABLE nouvelle
# (worktree/branche intégrés, stash, mémoire non indexée) — c'est ce que la session peut ranger elle-même.
# Jamais une branche distante : geste humain.
# CE QUI NE BLOQUE JAMAIS, dit à l'UTILISATEUR (exit 0, UN document JSON sur stdout, champ `systemMessage` :
# avertissement affiché à l'utilisateur, code.claude.com/docs/en/hooks § JSON output ; le stderr d'un exit 0
# n'est PAS vu de lui) : ARCHIVÉ (déplacement tracé sous .planning/archives/INDEX.tsv, réversible, à
# commiter ; y compris celui d'un sujet clos préexistant ; quand le MÊME arrêt bloque, l'avis est gardé dans
# l'état de la session et dit à l'utilisateur au premier exit 0 qui suit : un archivage automatique est dit
# au moins une fois), ARCHIVABLE resté, ARCHIVAGE REFUSÉ (source
# modifiée, dépôt non git, compartiment protégé : rien que la session puisse faire ici), ARCHIVAGE NON
# TENTÉ, DÉPASSÉ (résumé en UNE ligne), NON VÉRIFIABLE. Un seul document JSON par exécution, produit par un
# encodeur awk SANS dépendance (ni jq, ni python3) — HOOKS-CONTRAT-SORTIE §3 bis.
#
# COUPE-CIRCUIT : un état par session (compteur, plus bas atteint, relâché) dans un dossier PROPRE À
# L'UTILISATEUR (`$TMPDIR/vibeflow-fin-de-geste-<uid>`, droits 700, refusé s'il n'est pas à lui ou si c'est un
# lien). Un blocage par arrêt tant que l'ensemble attribué n'est pas vide ; après 3 blocages de suite SANS
# PROGRÈS (progrès = l'ensemble attribué est PLUS PETIT que le plus bas jamais atteint : l'alternance −1/+1 ne
# remet donc rien à zéro ; le compteur repart de zéro), le Stop laisse sortir avec un message VISIBLE et se tait
# ensuite. Toute écriture d'état ratée (compteur, avis en attente, snapshot) est DITE à l'utilisateur et relâche
# la garde : jamais un blocage qu'aucun compteur ne borne, jamais un silence.
# `stop_hook_active` n'arrête donc PLUS la garde (il la rendait muette dès le 2e arrêt) : la boucle est
# bornée par ce compteur. Ensemble vide : état effacé, sortie muette. VF_FIN_DE_GESTE = block (défaut) |
# warn (dit, exit 0, RIEN déplacé : lecture seule) | off ; snapshot, script de budget, session_id ou dossier
# d'état absents ou inutilisables, stdin illisible → fail-open BRUYANT (systemMessage `NON VÉRIFIABLE`, exit 0), jamais un vert
# muet. VF_METHOD_BUDGET remplace le script de budget (suites seulement).
# Jetons lus (contrat de check-method-budget.sh) : RANGEABLE, ARCHIVABLE, ARCHIVÉ, ARCHIVAGE REFUSÉ,
# ARCHIVAGE NON TENTÉ, DÉPASSÉ / PROSE DÉPASSÉE. Le jeton de remote (À VALIDER) n'est PAS lu : cette garde
# appelle le budget avec --no-remote, qui ne le rend jamais.
# Exit : 0 (autorise l'arrêt) ou 2 (bloque). Jamais d'autre code.
set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"
MODE_SNAPSHOT=0
[ "${1:-}" = "--snapshot" ] && MODE_SNAPSHOT=1

# Sentinelle d'armement : tout en haut, avant tout effet (état, budget, archivage).
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
[ -n "$ROOT" ] || ROOT="$PWD"
[ -f "$ROOT/.planning/.fin-de-geste-armed" ] || exit 0

NL=$'\n'
VIS=""
vis() { VIS="${VIS}${VIS:+$NL}$1"; }
# Encodeur JSON SANS dépendance : awk seul. Le message passe par l'environnement (ENVIRON n'interprète aucun
# échappement, contrairement à -v) ; octets ≥ 0x80 rendus tels quels (UTF-8 valide), contrôles échappés.
json_doc() {
  VFJ_MSG="$1" LC_ALL=C awk 'BEGIN {
    for (i = 1; i < 32; i++) ctl[sprintf("%c", i)] = sprintf("\\u%04x", i)
    ctl["\n"] = "\\n"; ctl["\t"] = "\\t"; ctl["\r"] = "\\r"
    s = ENVIRON["VFJ_MSG"]; n = length(s); out = ""
    for (k = 1; k <= n; k++) {
      c = substr(s, k, 1)
      if (c == "\\") o = "\\\\"; else if (c == "\"") o = "\\\""; else if (c in ctl) o = ctl[c]; else o = c
      out = out o
    }
    printf "{\"systemMessage\":\"%s\"}\n", out
  }'
}
emit() {  # UN document JSON {"systemMessage": …} si du visible a été accumulé
  [ -n "$VIS" ] || return 0
  json_doc "$VIS" 2>/dev/null || printf '%s\n' "$VIS" >&2
}
sortie_ok() { emit; exit 0; }
nv() { vis "[fin-de-geste] NON VÉRIFIABLE : $1"; sortie_ok; }
# Écriture d'état VÉRIFIÉE : fichier temporaire, renommage, relecture. Rend 1 si l'un des trois échoue.
wr() { # <fichier> <contenu>
  printf '%s\n' "$2" > "$1.t.$$" 2>/dev/null && mv -f "$1.t.$$" "$1" 2>/dev/null && [ -f "$1" ] && [ "$(cat "$1" 2>/dev/null)" = "$2" ] \
    || { rm -f "$1.t.$$" 2>/dev/null; return 1; }
}

MODE="${VF_FIN_DE_GESTE:-block}"
[ "$MODE" = "off" ] && exit 0

SID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | tr -cd 'A-Za-z0-9._-')
[ -n "$SID" ] || nv "session_id illisible sur stdin, garde sans objet pour cette session"

BUDGET="${VF_METHOD_BUDGET:-$(dirname "$0")/check-method-budget.sh}"
[ -f "$BUDGET" ] || nv "script de budget introuvable : $BUDGET"

UIDN="$(id -u 2>/dev/null)"
case "$UIDN" in ''|*[!0-9]*) nv "uid illisible, dossier d'état propre à l'utilisateur non calculable" ;; esac
DIR="${TMPDIR:-/tmp}/vibeflow-fin-de-geste-$UIDN"
KEY=$(printf '%s' "$ROOT" | cksum 2>/dev/null | awk '{print $1}')
[ -n "$KEY" ] || nv "clé de dépôt non calculable"
SNAP="$DIR/${KEY}-${SID}.snap"
BLK="$DIR/${KEY}-${SID}.blk"
SEEN="$DIR/${KEY}-${SID}.seen"
PEND="$DIR/${KEY}-${SID}.pend"
MAX_BLOCS=3
TOKENS='RANGEABLE|ARCHIVABLE|ARCHIVÉ|ARCHIVAGE REFUSÉ|DÉPASSÉ'
jetons() { { grep -E "$TOKENS" || true; } | sed 's/^\[budget\] *//' | LC_ALL=C sort -u; }
prep_dir() {  # dossier d'état : à l'utilisateur, jamais un lien, droits 700 ; 1 sinon
  [ -d "$DIR" ] || mkdir -m 700 "$DIR" 2>/dev/null
  [ -d "$DIR" ] && [ ! -L "$DIR" ] && [ -O "$DIR" ] || return 1
  chmod 700 "$DIR" 2>/dev/null
  return 0
}

if [ "$MODE_SNAPSHOT" -eq 1 ]; then
  prep_dir || nv "dossier d'état inutilisable (absent, lien, ou pas à cet utilisateur) : $DIR"
  find "$DIR" -type f \( -name '*.snap' -o -name '*.blk' -o -name '*.seen' -o -name '*.pend' -o -name '*.acted' \) -mtime +7 -delete 2>/dev/null || true
  [ -f "$SNAP" ] && exit 0                                   # first-wins : un compact ré-émet SessionStart
  OUT="$(bash "$BUDGET" --no-remote --quiet --root "$ROOT" 2>/dev/null)"; RC=$?
  [ "$RC" -le 2 ] || nv "check-method-budget a rendu $RC au snapshot, baseline non posée"
  wr "$SNAP" "$(printf '%s\n' "$OUT" | jetons)" || nv "snapshot de début de session non écrit ($SNAP) : rien ne sera jugé à l'arrêt"
  exit 0
fi

[ -f "$SNAP" ] || nv "snapshot de début de session absent (SessionStart non joué), rien jugé"
prep_dir || nv "dossier d'état inutilisable (absent, lien, ou pas à cet utilisateur) : $DIR"

ARGS=(--no-remote --quiet --root "$ROOT")
# Mode warn : lecture seule, RIEN déplacé. Sinon --auto : la session décide, l'outil archive seul.
[ "$MODE" = "warn" ] || ARGS=(--auto "${ARGS[@]}")
OUT="$(bash "$BUDGET" "${ARGS[@]}" 2>/dev/null)"; RC=$?
[ "$RC" -le 2 ] || nv "check-method-budget a rendu $RC, garde sans verdict"

NOW="$DIR/$KEY-$SID.now"
printf '%s\n' "$OUT" | jetons > "$NOW" 2>/dev/null || nv "état de travail non écrit ($NOW), rien jugé"
NOUVEAU="$(LC_ALL=C comm -23 "$NOW" "$SNAP")"               # apparu depuis le snapshot de CETTE session
rm -f "$NOW"
annoter() {  # un stash est désigné par son SHA : dire aussi sa position ACTUELLE, pour celui qui doit agir
  local l sha pos
  while IFS= read -r l; do
    case "$l" in
      "RANGEABLE stash : "*)
        sha="${l#RANGEABLE stash : }"; sha="${sha%% *}"
        pos="$(git -C "$ROOT" stash list --format='%gd %H' 2>/dev/null | awk -v s="$sha" 'index($2, s) == 1 { print $1; exit }')"
        [ -z "$pos" ] || l="$l (position actuelle : $pos)" ;;
    esac
    printf '%s\n' "$l"
  done
}
BLOQUANT="$(printf '%s\n' "$NOUVEAU" | grep '^RANGEABLE' | annoter || true)"
ARCHIVE="$(printf '%s\n' "$NOUVEAU" | grep '^ARCHIVÉ' || true)"
RESTE="$(printf '%s\n' "$NOUVEAU" | grep -E '^(ARCHIVABLE|ARCHIVAGE REFUSÉ)' || true)"
DEPASSE="$(printf '%s\n' "$NOUVEAU" | grep 'DÉPASSÉ' || true)"
NON_TENTE="$(printf '%s\n' "$OUT" | grep 'ARCHIVAGE NON TENTÉ' | sed 's/^\[budget\] *//' || true)"

# Constats pour l'utilisateur (jamais bloquants), dédupliqués d'un arrêt à l'autre : on ne répète pas le même.
CONSTATS=""
cons() { CONSTATS="${CONSTATS}${CONSTATS:+$NL}$1"; }
ARCHIVE_MSG=""
[ -n "$ARCHIVE" ] && ARCHIVE_MSG="[fin-de-geste] Archivé sans geste humain (déplacement tracé dans .planning/archives/INDEX.tsv, réversible : git cat-file blob <ref de l'INDEX>) — à commiter, ou à restaurer si c'est une erreur :$NL$ARCHIVE"
[ -n "$NON_TENTE" ] && cons "[fin-de-geste] $NON_TENTE"
[ -n "$ARCHIVE_MSG" ] && cons "$ARCHIVE_MSG"
[ -n "$RESTE" ] && cons "[fin-de-geste] Rien que cette session puisse ranger ici (source modifiée, dépôt non git, compartiment protégé, verrou tenu), dit et non bloquant :$NL$RESTE"
[ -n "$DEPASSE" ] && cons "[fin-de-geste] budget dépassé (constat, rien à faire ici) : $(printf '%s\n' "$DEPASSE" | wc -l | tr -d ' ') ligne(s), la première : $(printf '%s\n' "$DEPASSE" | head -1 | cut -c1-160)"
publier() {  # avis en attente puis constats non bloquants → utilisateur ; ces derniers une seule fois tant qu'ils ne changent pas
  local pend="" out="" sig
  [ -f "$PEND" ] && pend="$(cat "$PEND" 2>/dev/null)"
  if [ -n "$CONSTATS" ]; then
    sig="$(printf '%s' "$CONSTATS" | cksum | awk '{print $1}')"
    if [ "$(cat "$SEEN" 2>/dev/null)" != "$sig" ]; then out="$CONSTATS"; wr "$SEEN" "$sig" || true; fi
  fi
  # L'avis d'archivage déjà dit dans ce même exit 0 (CONSTATS le porte) n'est pas répété
  [ -n "$pend" ] && case "$out" in *"$pend"*) ;; *) vis "$pend" ;; esac
  [ -n "$out" ] && vis "$out"
  [ -z "$pend" ] || rm -f "$PEND" 2>/dev/null
  return 0
}
relache() {  # <raison> : l'état de la garde n'est pas persistable → dit, relâche, ne bloque JAMAIS sans compteur
  publier
  [ -z "$ARCHIVE_MSG" ] || case "$VIS" in *"$ARCHIVE_MSG"*) ;; *) vis "$ARCHIVE_MSG" ;; esac
  vis "[fin-de-geste] NON VÉRIFIABLE : $1 — garde relâchée, rien n'est bloqué. Reste non rangé (attribué à cette session par le snapshot) :$NL$BLOQUANT"
  sortie_ok
}

if [ -z "$BLOQUANT" ]; then rm -f "$BLK" 2>/dev/null; publier; sortie_ok; fi   # rien d'attribué à ranger (ou fini) : état effacé

if [ "$MODE" = "warn" ]; then
  publier
  vis "[fin-de-geste] Rangement laissé par cette session (mode warn, rien déplacé, rien bloqué) :$NL$BLOQUANT"
  sortie_ok
fi

# --- Coupe-circuit : N blocages de suite sans progrès, puis on laisse sortir, visiblement ---------------
TAILLE="$(printf '%s\n' "$BLOQUANT" | wc -l | tr -d ' ')"
P_COUNT=0; P_LOW=""; P_LACHE=0
[ -f "$BLK" ] && read -r P_COUNT P_LOW P_LACHE < "$BLK" 2>/dev/null
case "$P_COUNT" in ''|*[!0-9]*) P_COUNT=0 ;; esac
case "$P_LACHE" in ''|*[!0-9]*) P_LACHE=0 ;; esac
case "$P_LOW" in ''|*[!0-9]*) P_LOW="$TAILLE" ;; esac
# Progrès : l'ensemble attribué est PLUS PETIT que le plus bas jamais atteint (et non que le dernier arrêt :
# −1 puis +1 ne serait jamais un progrès net) → le compteur repart de zéro.
if [ "$TAILLE" -lt "$P_LOW" ]; then P_LOW="$TAILLE"; P_COUNT=0; P_LACHE=0; fi
if [ "$P_LACHE" -eq 1 ]; then   # déjà dit une fois
  wr "$BLK" "$P_COUNT $P_LOW 1" || vis "[fin-de-geste] NON VÉRIFIABLE : état du coupe-circuit non écrivable ($BLK), garde relâchée"
  publier; sortie_ok
fi
if [ "$P_COUNT" -ge "$MAX_BLOCS" ]; then
  wr "$BLK" "$P_COUNT $P_LOW 1" || vis "[fin-de-geste] NON VÉRIFIABLE : état du coupe-circuit non écrivable ($BLK), ce message peut se répéter"
  publier
  vis "[fin-de-geste] Coupe-circuit : $MAX_BLOCS blocages de suite sans progrès, je laisse sortir. Reste non rangé (attribué à cette session par le snapshot, peut-être pas de sa main) :$NL$BLOQUANT${NL}À ranger à la main ou à citer au rapport. Toggle : VF_FIN_DE_GESTE=warn|off."
  sortie_ok
fi
P_COUNT=$((P_COUNT + 1))
# Le compteur DOIT être persisté avant de bloquer : sans lui, rien ne borne la boucle.
wr "$BLK" "$P_COUNT $P_LOW 0" || relache "compteur du coupe-circuit non persistable ($BLK)"
# L'avis d'archivage ne peut pas partir à l'utilisateur dans un exit 2 (stdout ignoré) : gardé pour le prochain exit 0.
if [ -n "$ARCHIVE_MSG" ]; then
  PEND_OLD="$(cat "$PEND" 2>/dev/null)"
  wr "$PEND" "${PEND_OLD}${PEND_OLD:+$NL}$ARCHIVE_MSG" || relache "avis d'archivage non persistable ($PEND)"
fi
{
  echo "[fin-de-geste] Fin de geste : cette session laisse du rangement derrière elle (blocage $P_COUNT/$MAX_BLOCS, sans progrès le dernier laisse sortir)."
  printf '%s\n' "$BLOQUANT"
  [ -n "$CONSTATS" ] && printf '%s\n' "$CONSTATS"
  echo "À ranger, seulement ce que CETTE session a créé : worktree (git worktree remove, sans --force), branche locale intégrée (git branch -d), stash (patch sous .planning/archives/stash/ puis drop), mémoire non indexée (git add PUIS une entrée dans le MEMORY.md du dossier : après git add elle passe « hors index » tant qu'elle n'y figure pas). Jamais une branche distante : geste humain. Un objet qui n'est pas de ta main (autre session) : ne le supprime pas, cite-le dans ton rapport. Toggles : VF_FIN_DE_GESTE=warn|off."
} >&2
exit 2
