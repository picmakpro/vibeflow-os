#!/usr/bin/env bash
# restore-requirements-ledger.sh — Rattrapage outillé : roll-forward du ledger d'exigences depuis
# l'archive d'un jalon clos (LEDG-01, plan 18-02).
#
# Rôle (Iron Law 2) : ce script est un POST-TRAITEMENT PUR. Il ne touche JAMAIS l'archive (lecture
# seule stricte), ne réimplémente ni `complete-milestone`, ni l'archivage, ni la génération de
# ROADMAP. Il lit une archive de jalon clos, classe chaque exigence via `vf_ledger_classify` (source
# unique de la précédence, requirements-survival-detect.sh, plan 18-01), et propose un
# `.planning/REQUIREMENTS.md` reconstitué — jamais en silence (D-18-06, ADR-031) : par défaut il
# affiche un diff, il n'écrit QUE sous --write explicite. Il n'y a pas de troisième mode.
#
# Zéro normalisation (D-18-13) : les lignes classées Garantie ou Voyage sont réimprimées SOURCE,
# verbatim, à l'octet près — seul le suffixe littéral ` — carried-from: <jalon>` est ajouté aux
# lignes Voyage (D-18-12), le libellé du jalon repris tel quel (VF_LEDGER_MILESTONE, déjà assaini
# par la primitive du plan 18-01, jamais une seconde extraction) — jamais un `v` fabriqué devant.
#
# Les exigences classées Caduque (code 2) ou Forme non reconnue (code 3) ne sont écrites NULLE PART
# dans le fichier reconstitué : Caduque reste uniquement dans l'archive (doctrine D-18-11) ; Forme
# non reconnue est un repli conservateur — jamais deviné, toujours signalé sur stderr avec son ID
# dans les DEUX modes (diff et --write), jamais absorbé sans trace (T-18-09).
#
# Ce script n'est JAMAIS appelé par un hook (A-18-11) : le gate SessionStart du plan 18-01 se
# contente d'IMPRIMER ce geste, il ne l'exécute jamais. Aucune contrainte de latence de session ici.
#
# Usage:
#   restore-requirements-ledger.sh [--path <dir>] [--write] [--overwrite-live] [--quiet] [-h|--help]
# Defaults: --path .  (mode diff, aucune écriture)
#
# Garde de non-écrasement (défense en profondeur, au-delà du contrat déjà tenu par
# vf_ledger_state — qui ne signale absent_after_close QUE si REQUIREMENTS.md est absent) :
# --write REFUSE d'écrire si .planning/REQUIREMENTS.md existe déjà, quel que soit son contenu.
# --overwrite-live (jamais impliqué par --write seul) autorise le remplacement, et seulement
# après une sauvegarde REQUIREMENTS.md.bak-<jalon> écrite et tracée en sortie.
#
# Exit codes :
#   0  = diff affiché, ou écriture faite sous --write
#   1  = rien à reconstituer (ledger vivant présent, aucun jalon clos, état illisible, ou aucune
#        archive disponible), OU refus d'écraser un ledger vivant sans --overwrite-live — ce
#        script ne force jamais une reconstitution hors du cas détecté par le gate du plan 18-01
#   64 = argument inconnu, ou --path sans valeur
set -uo pipefail

ROOT="."
WRITE=0
QUIET=0
OVERWRITE_LIVE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[restore-requirements-ledger] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --write) WRITE=1; shift ;;
    --overwrite-live) OVERWRITE_LIVE=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[restore-requirements-ledger] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[restore-requirements-ledger] $*" >&2; }

PLANNING_DIR="$ROOT/.planning"
LIVE="$PLANNING_DIR/REQUIREMENTS.md"

# --- Découverte de la primitive partagée, mêmes chemins candidats que le gate du plan 18-01 -------
_SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
PRIMITIVE=""
for _cand in "$_SCRIPT_DIR/requirements-survival-detect.sh" \
             "$(dirname "$0")/requirements-survival-detect.sh"; do
  if [ -n "$_cand" ] && [ -r "$_cand" ]; then PRIMITIVE="$_cand"; break; fi
done
if [ -z "$PRIMITIVE" ] || ! . "$PRIMITIVE" 2>/dev/null || ! command -v vf_ledger_classify >/dev/null 2>&1; then
  echo "[restore-requirements-ledger] requirements-survival-detect.sh introuvable ou non chargeable — aucune reconstitution possible." >&2
  exit 1
fi

vf_ledger_state "$PLANNING_DIR"
state_rc=$?

# --overwrite-live est le SEUL cas où ce script continue malgré un $LIVE présent : vf_ledger_state
# rend TOUJOURS "nominal" (jamais absent_after_close) dès que REQUIREMENTS.md existe — par contrat,
# quelle que soit la raison de l'appel. Sans ce contournement explicite, --overwrite-live ne pourrait
# jamais être atteint : le early-exit ci-dessous tuerait le script avant la garde de la ligne ~245.
# Le chemin d'archive n'est alors PAS fourni par la primitive (VF_LEDGER_ARCHIVE reste vide dans la
# branche nominal) : il est reconstruit ici à partir de VF_LEDGER_MILESTONE — déjà assaini par la
# primitive (T-18-01, plan 18-01), jamais une seconde extraction brute.
OVERRIDE_ARCHIVE=""
# La condition VF_LEDGER_STATE="nominal" seule était TROP ÉTROITE (bug constaté en cours de
# rédaction) : quand $LIVE existe ET porte des IDs manquants (LEDG-02), vf_ledger_state rend
# ids_missing (3), pas nominal (1) — --overwrite-live restait inatteignable dans ce cas très
# probable (le ledger qu'on veut écraser a justement des raisons d'être remplacé). Le SEUL critère
# fiable est [ -f "$LIVE" ] (déjà vérifié explicitement ci-dessous) : peu importe la RAISON du
# state_rc != 0, du moment que $LIVE existe et qu'un jalon clos avec archive a été identifié.
if [ "$state_rc" -ne 0 ] && [ "$OVERWRITE_LIVE" -eq 1 ] \
   && [ -n "${VF_LEDGER_MILESTONE:-}" ] && [ -f "$LIVE" ]; then
  _cand_archive="${PLANNING_DIR}/milestones/${VF_LEDGER_MILESTONE}-REQUIREMENTS.md"
  if [ -f "$_cand_archive" ] && [ ! -L "$_cand_archive" ]; then
    OVERRIDE_ARCHIVE="$_cand_archive"
  fi
fi

if [ "$state_rc" -ne 0 ] && [ -z "$OVERRIDE_ARCHIVE" ]; then
  case "$VF_LEDGER_STATE" in
    nominal) say "rien à reconstituer — ledger vivant présent, ou aucun jalon clos déclaré." ;;
    unreadable) say "état illisible (motif : ${VF_LEDGER_REASON}) — rien à reconstituer sans un constat fiable." ;;
    ids_missing) say "ledger vivant présent (des IDs manquent, hors périmètre de ce rattrapage) — rien à reconstituer." ;;
    *) say "état inattendu (${VF_LEDGER_STATE:-?}) — rien à reconstituer." ;;
  esac
  exit 1
fi

if [ -n "$OVERRIDE_ARCHIVE" ]; then
  ARCHIVE="$OVERRIDE_ARCHIVE"
else
  if [ -z "$VF_LEDGER_ARCHIVE" ]; then
    say "aucune archive ${PLANNING_DIR}/milestones/${VF_LEDGER_MILESTONE}-REQUIREMENTS.md à reconstituer."
    exit 1
  fi
  ARCHIVE="$VF_LEDGER_ARCHIVE"
fi
MILESTONE="$VF_LEDGER_MILESTONE"

TMPD="$(mktemp -d)" || { echo "[restore-requirements-ledger] mktemp -d a échoué" >&2; exit 1; }
trap 'rm -rf "$TMPD"' EXIT

# --- Extraction structurée (famille, ID, ligne de corps, ligne de traçabilité), UNE passe pour la
# table de traçabilité (premier arg) + UNE passe pour le corps (second arg, même fichier) ----------
awk '
  FNR == NR {
    if ($0 ~ /^## Traceability[ \t]*$/) { intrace = 1; next }
    if (intrace == 1 && match($0, /^\| [A-Z]+-[0-9]+ \|/)) {
      line = $0
      if (match(line, /[A-Z]+-[0-9]+/)) {
        id = substr(line, RSTART, RLENGTH)
        # Duplication signalee (correctif 2026-08-18, revue de code) : deux lignes de tracabilite
        # pour un meme ID s ecrasaient silencieusement, sans jamais annoncer le choix retenu
        # (D-18-06/D-18-10). Le dernier gagne toujours (comportement deterministe, inchange), mais
        # la duplication est desormais annoncee sur stderr avec les DEUX lignes en conflit. Note
        # d hygiene shell : ce commentaire evite toute apostrophe francaise car il vit DANS un
        # script awk lui-meme entre quotes simples bash — une apostrophe y romprait la citation.
        if (id in traceline && traceline[id] != line) {
          printf "[restore-requirements-ledger] traçabilité dupliquée pour %s — ancienne ligne écrasée : %s -> %s\n", id, traceline[id], line > "/dev/stderr"
        }
        traceline[id] = line
      }
    }
    next
  }
  {
    if ($0 ~ /^## Traceability[ \t]*$/) { exit }
    if ($0 ~ /^### /) { fam = $0; next }
    if (match($0, /^- \[.\] \*\*[A-Z]+-[0-9]+\*\*/)) {
      line = $0
      if (match(line, /[A-Z]+-[0-9]+/)) {
        id = substr(line, RSTART, RLENGTH)
        tl = (id in traceline) ? traceline[id] : ""
        printf "%s\037%s\037%s\037%s\n", fam, id, line, tl
      }
    }
  }
' "$ARCHIVE" "$ARCHIVE" > "$TMPD/tuples.tsv"

: > "$TMPD/garanties.txt"
: > "$TMPD/voyage.tsv"
: > "$TMPD/trace.txt"
: > "$TMPD/code3.txt"
: > "$TMPD/caduque.txt"

while IFS=$'\037' read -r fam id bodyline traceline; do
  [ -n "$id" ] || continue
  vf_ledger_classify "$bodyline" "$traceline"
  code=$?
  case "$code" in
    0) printf '%s\n' "$bodyline" >> "$TMPD/garanties.txt" ;;
    1)
      printf '%s\037%s — carried-from: %s\n' "$fam" "$bodyline" "$MILESTONE" >> "$TMPD/voyage.tsv"
      [ -n "$traceline" ] && printf '%s\n' "$traceline" >> "$TMPD/trace.txt"
      ;;
    2) printf '%s\n' "$id" >> "$TMPD/caduque.txt" ;;
    3) printf '%s\n' "$id" >> "$TMPD/code3.txt" ;;
  esac
done < "$TMPD/tuples.tsv"

# --- Familles groupées (code 1 uniquement), ordre de première apparition dans l'archive -----------
if [ -s "$TMPD/voyage.tsv" ]; then
  awk -F'\037' '
    !seen[$1]++ { order[++n] = $1 }
    { items[$1] = items[$1] $2 "\n" }
    END {
      for (i = 1; i <= n; i++) {
        fam = order[i]
        if (fam != "") print fam
        print ""
        printf "%s", items[fam]
        print ""
      }
    }
  ' "$TMPD/voyage.tsv" > "$TMPD/families.md"
else
  : > "$TMPD/families.md"
fi

# --- Titre/frontmatter : repris du vivant s'il subsiste, sinon de l'archive (jamais fabriqué) -----
# Arrêt au premier titre de N'IMPORTE QUEL niveau ≥2 (## à ######), jamais seulement ## : une
# archive dont la première famille (###) suit directement le titre sans conteneur ## intercalé ne
# doit jamais laisser fuiter du contenu classé (garanti/voyageur/caduc) dans le bloc de titre.
if [ -f "$LIVE" ] && head -n 1 "$LIVE" 2>/dev/null | grep -q '^# Requirements:'; then
  awk '/^#{2,6} /{exit} {print}' "$LIVE" > "$TMPD/title.md"
else
  awk '/^#{2,6} /{exit} {print}' "$ARCHIVE" > "$TMPD/title.md"
fi

# --- Out of Scope, repris verbatim de l'archive SI présent, sinon omis -----------------------------
awk '
  /^## Out of Scope[ \t]*$/ { grab = 1 }
  grab == 1 && /^## / && !/^## Out of Scope[ \t]*$/ { exit }
  grab == 1 { print }
' "$ARCHIVE" > "$TMPD/outofscope.md"

RECON_DATE="$(date -u +%Y-%m-%d)"

{
  cat "$TMPD/title.md"
  printf '\n> **Reconstitution du %s.** Roll-forward depuis le jalon clos `%s` (archive `%s`), outillé\n> par restore-requirements-ledger.sh (LEDG-01). Les exigences caduques restent uniquement dans\n> l'"'"'archive source.\n\n' "$RECON_DATE" "$MILESTONE" "$ARCHIVE"
  echo "## Garanties"
  echo ""
  cat "$TMPD/garanties.txt"
  echo ""
  # Les voyageuses portent leur PROPRE H2 (## Reportées), jamais nichées sous ## Garanties : la
  # même règle « jusqu'au prochain H1/H2 » qui borne updateTraceabilityCell() (gsd-core, invoquée
  # pour justifier l'innocuité de ## Garanties, D-18-03) ramasserait sinon les familles ### qui
  # suivent SANS H2 intercalé — un lecteur qui applique cette règle recevrait des exigences
  # explicitement carried-from: (donc non livrées) comme des garanties. ## Garanties, ## Reportées,
  # ## Out of Scope et ## Traceability sont quatre sections H2 SŒURS, chacune bornée par la même
  # règle sans ambiguïté.
  if [ -s "$TMPD/families.md" ]; then
    echo "## Reportées"
    echo ""
    cat "$TMPD/families.md"
  fi
  if [ -s "$TMPD/outofscope.md" ]; then
    cat "$TMPD/outofscope.md"
    echo ""
  fi
  echo "## Traceability"
  echo ""
  echo "| Requirement | Phase | Status |"
  echo "|---|---|---|"
  cat "$TMPD/trace.txt"
  echo ""
  printf '*Reconstitué depuis l'"'"'archive %s le %s par restore-requirements-ledger.sh (LEDG-01).*\n' "$ARCHIVE" "$RECON_DATE"
} > "$TMPD/proposed.md"

GARANTIES_N="$(wc -l < "$TMPD/garanties.txt" | tr -d ' ')"
# VOYAGE_N depuis voyage.tsv (une ligne par item code 1), PAS trace.txt : un item voyageur SANS
# ligne de traçabilité correspondante (cas réel ARMD-*/PAEX-*, 21 IDs) n'écrit rien dans trace.txt
# mais figure bien dans le fichier écrit sous sa famille — le compter depuis trace.txt le faisait
# disparaître du RÉSUMÉ imprimé (jamais du fichier lui-même, la présence réelle était déjà correcte).
VOYAGE_N="$(wc -l < "$TMPD/voyage.tsv" | tr -d ' ')"
CADUQUE_N="$(wc -l < "$TMPD/caduque.txt" | tr -d ' ')"
CODE3_N="$(wc -l < "$TMPD/code3.txt" | tr -d ' ')"

if [ "$CODE3_N" -gt 0 ]; then
  say "forme non reconnue (code 3), $CODE3_N item(s) — ni écrits ni ignorés silencieusement :"
  while IFS= read -r cid; do [ -n "$cid" ] && say "  - $cid"; done < "$TMPD/code3.txt"
fi

if [ "$WRITE" -eq 0 ]; then
  printf '[restore-requirements-ledger] proposition de reconstitution depuis %s (jalon %s) — relancer avec --write pour écrire.\n' "$ARCHIVE" "$MILESTONE"
  # --label donne un nom STABLE aux deux côtés du diff — jamais le chemin volatil sous mktemp
  # (déterminisme du stdout entre deux exécutions successives, T-18-tests).
  DIFF_SRC="/dev/null"; [ -f "$LIVE" ] && DIFF_SRC="$LIVE"
  # Neutralisation d'injection de terminal (correctif 2026-08-18, revue de code + audit sécurité,
  # sévérité élevée) : le contenu de l'ARCHIVE (potentiellement hostile) est réimprimé verbatim dans
  # ce diff — tout le gate ADR-031 repose dessus, l'humain valide sur ce qu'il voit. Une archive
  # portant des séquences ANSI (déplacement de curseur, effacement de ligne) ou `BEL` pourrait
  # masquer des lignes que l'humain croit lire intégralement, défaisant la validation humaine
  # elle-même. La neutralisation porte UNIQUEMENT sur cet AFFICHAGE terminal : `tr` retire les
  # octets de contrôle C0 (0x00-0x08, 0x0B-0x1F, 0x7F — donc ESC 0x1B et BEL 0x07) tout en préservant
  # tabulation/saut de ligne (0x09/0x0A) et tous les octets UTF-8 (>=0x80, hors de cette plage) —
  # aucun accent ni caractère multi-octets n'est touché. Le FICHIER écrit sous --write (cp plus bas)
  # reste, lui, verbatim à l'octet près : D-18-13 gouverne le contenu écrit, pas le rendu terminal.
  diff -u --label "REQUIREMENTS.md (actuel)" "$DIFF_SRC" --label "REQUIREMENTS.md (proposé)" "$TMPD/proposed.md" \
    | tr -d '\000-\010\013-\037\177'
  exit 0
fi

# --- Sauvegarde avant écrasement (défense en profondeur) ------------------------------------------
# Le refus d'écraser $LIVE sans --overwrite-live est déjà tranché PLUS HAUT (le early-exit qui suit
# vf_ledger_state) : c'est le SEUL endroit du script où $LIVE présent peut laisser passer un
# --write, et uniquement sous --overwrite-live explicite (OVERRIDE_ARCHIVE non vide). Cette
# instruction est donc un GARDE-FOU REDONDANT, volontaire — si un futur remaniement de ce fichier
# réordonne la logique et fait atteindre ce point avec $LIVE présent sans le drapeau, ce script
# refuse quand même d'écraser plutôt que de compter uniquement sur l'ordre des instructions plus
# haut. Ce n'est PAS le point que la suite de tests mute pour prouver la garde (voir le early-exit).
if [ -f "$LIVE" ] && [ "$OVERWRITE_LIVE" -ne 1 ]; then
  echo "[restore-requirements-ledger] $LIVE existe déjà — refus d'écraser un ledger vivant (relancer avec --overwrite-live pour forcer, après sauvegarde)." >&2
  exit 1
fi

BACKUP_PATH=""
if [ -f "$LIVE" ] && [ "$OVERWRITE_LIVE" -eq 1 ]; then
  BACKUP_PATH="${LIVE}.bak-${MILESTONE}"
  cp "$LIVE" "$BACKUP_PATH" || { echo "[restore-requirements-ledger] sauvegarde de $LIVE a échoué — écriture annulée" >&2; exit 1; }
fi

mkdir -p "$PLANNING_DIR"
WRITE_TMP="$(mktemp "${PLANNING_DIR}/.REQUIREMENTS.md.XXXXXX")" || { echo "[restore-requirements-ledger] mktemp d'écriture a échoué" >&2; exit 1; }
# `cp` et `mv` sont désormais GARDÉS explicitement (correctif 2026-08-18, revue de code, bloquant
# #2) : sous `set -uo pipefail` (SANS `-e`), un `cp` en échec (disque plein, quota, permission) ne
# stoppait rien — le `mv` suivant déplaçait alors un fichier vide/tronqué PAR-DESSUS le ledger
# vivant, et le script sortait en exit 0 avec un message de succès. La sauvegarde (ligne au-dessus)
# était déjà gardée par `||` ; cette asymétrie est corrigée ici.
if ! cp "$TMPD/proposed.md" "$WRITE_TMP"; then
  echo "[restore-requirements-ledger] copie vers le fichier temporaire d'écriture a échoué — $LIVE non touché" >&2
  rm -f "$WRITE_TMP"
  exit 1
fi
# 0644 explicite (correctif, mineur) : `mktemp` crée le temporaire en 0600, alors qu'un
# REQUIREMENTS.md tracké par git attend des permissions de fichier ordinaire (0644).
chmod 0644 "$WRITE_TMP" 2>/dev/null || true
if ! mv "$WRITE_TMP" "$LIVE"; then
  echo "[restore-requirements-ledger] déplacement atomique vers $LIVE a échoué — $LIVE non touché" >&2
  rm -f "$WRITE_TMP"
  exit 1
fi

if [ -n "$BACKUP_PATH" ]; then
  printf '[restore-requirements-ledger] écrit %s (sauvegarde : %s) — Garanties: %s, Voyage: %s, Caduques laissées en archive: %s, Forme non reconnue (stderr): %s\n' \
    "$LIVE" "$BACKUP_PATH" "$GARANTIES_N" "$VOYAGE_N" "$CADUQUE_N" "$CODE3_N"
else
  printf '[restore-requirements-ledger] écrit %s — Garanties: %s, Voyage: %s, Caduques laissées en archive: %s, Forme non reconnue (stderr): %s\n' \
    "$LIVE" "$GARANTIES_N" "$VOYAGE_N" "$CADUQUE_N" "$CODE3_N"
fi
exit 0
