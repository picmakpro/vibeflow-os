#!/usr/bin/env bash
# driver-lock.sh — Lock de driver unique pour vf-dev-manager (ADR-053, Pattern A)
#
# Empeche deux missions/sessions de piloter la MEME etape en parallele (collision de pilotage
# sur les backups isoles ADR-048/049). Recuperation de claim perime livree d'emblee
# (heartbeat + TTL) : un manager qui meurt ne gele pas les missions.
#
# FORME DU LOCK — le chemin public est un LIEN SYMBOLIQUE vers un dossier de generation qui
# porte le `meta`. Les consommateurs ne changent pas : `[ -d "$LOCK" ]` et `"$LOCK/meta"`
# traversent le lien (check-branch-claim.sh est inchange).
#
# POURQUOI PAS `mkdir` SEUL. La forme precedente prenait la PRESENCE DU DOSSIER pour le lock, et
# recuperait un claim perime en le DEPLACANT (`mv`) avant de le recreer. Pendant ce deplacement le
# chemin du lock n'existe pas — et le `mkdir` de la voie normale, qui ne peut pas distinguer
# « libre » de « en cours de recuperation », y entre. Mesure : 24 acquisitions concurrentes sur un
# lock perime rendaient jusqu'a 5 gagnants simultanes (macOS ET Linux). Ce n'est pas une fenetre a
# retrecir : deux correctifs de fenetre ont ete mesures PIRES que l'original (8 et 6 gagnants).
# Le lien, lui, est REMPLACE par rename(2) — il n'est jamais absent, donc il n'y a pas d'instant
# ou le lock parait libre. La recuperation est en plus serialisee par un mutex nomme d'apres la
# generation observee : un seul recuperateur par generation, les retardataires refusent.
#
# Usage:
#   driver-lock.sh acquire   --owner=<id> --step=<etape>   # pose le lock (refuse si perime, D-32-02)
#   driver-lock.sh takeover  --owner=<id> [--step=<etape>] # reprend un lock PERIME (geste explicite) ; avec --ws, refuse comme acquire si l'ancien verrou est tenu (vivant : legacy-lock-held ; perime : stale-requires-takeover)
#   driver-lock.sh reclaim   --owner=<id>                  # re-rattache la session courante a un lock VIVANT dont on est deja owner
#   driver-lock.sh heartbeat --owner=<id> [--step=<etape>] # rafraichit le heartbeat entre etapes
#   driver-lock.sh mark-progress --owner=<id>              # avance progress_epoch (D-33-A), JAMAIS heartbeat_epoch
#   driver-lock.sh release   --owner=<id>                  # relache (clôture RAII : succes/echec/abandon)
#   driver-lock.sh status                                  # etat courant (JSON, + children_running)
#   driver-lock.sh recover                                 # elague un lock perime (sinon refuse)
#
# Registre des agents dispatches (issue #82), frere du lock, JAMAIS dedans :
#   driver-lock.sh register --agent=<id> --role=<role> [--node=<id DAG>] [--parent=<id>] [--depth=<n>] [--owner=<id>]
#   driver-lock.sh close    --agent=<id> --status=done|failed|stopped   # ferme une entree (append)
#   driver-lock.sh orphans                                              # entrees encore `running`, feuille -> racine
#
# Sortie : JSON une ligne (parsing). Exit 0 = action reussie ; exit 1 = refus (lock tenu, pas owner…).
#
# Variables : VF_DRIVER_LOCK (defaut .planning/DRIVER.lock), VF_DRIVER_TTL (defaut 1800 s),
#             VF_DRIVER_SESSION_MAX (defaut 8, plafond LRU de session_ids),
#             VF_DRIVER_CHILDREN (defaut <lock>.children.jsonl, registre des agents dispatches).
# Reference : ADR-053 + .planning/phases/VFDO-09-*/09-CADRAGE-swarm.md §2.
#
# LAB PARTITIONNE (Phase 57) — un verrou NOMME par cible, au lieu du verrou unique :
#   --ws=<sujet>   le verrou du compartiment <sujet> (un manager par compartiment, en parallele)
#   --depot        le verrou de DEPOT (gestes qui touchent l'ensemble : release, fichiers racine…)
#   sans --ws      = verrou de depot ; le JSON porte alors "scope_reason": "ws-absent"
# Le compartiment ne vient JAMAIS que d'un --ws explicite : ni GSD_WORKSTREAM, ni VF_WORKSTREAM, ni
# le pointeur active-workstream ne deplacent la cible (un export oublie ne verrouille pas le mauvais
# sujet en silence). Un lab est partitionne quand .planning/workstreams existe (dossier, lien ou
# fichier : un etat illisible est un refus nomme "partition-unreadable", jamais un repli plat).
# Emplacement : <git-common-dir>/vf-driver/{ws/<sujet>,repo}/DRIVER.lock, un dossier par verrou,
# partage entre les worktrees du clone. Le JSON des verbes porte "scope" (compartiment|depot),
# "ws" ("" pour le depot) et "location" (git-common-dir). Refus nommes, chacun avec un "hint" :
# unknown-ws, ws-invalid, partition-unreadable, policy-missing, not-at-lab-root (P57-D-39 : --ws ou
# --depot lance d'un dossier sans .planning/ propre alors que la racine git en porte les compartiments ;
# hint « lance depuis la racine du lab »). Le nom du sujet est valide par
# vf_ws_name_valid puis vf_ws_dir_resolve AVANT d'entrer dans un chemin ou un JSON.
# ANCIEN VERROU (P57-D-14, P57-D-24, P57-D-26) : en lab partitionne, un .planning/DRIVER.lock tenu
# vaut verrou de depot. Tout acquire (compartiment ou depot), et takeover --ws sur un ancien verrou VIVANT
# ou PERIME (Q5 puis C option (a), arbitrage Samuel, AskUserQuestion session principale, 2026-10-13 : meme sonde
# avant la reprise, meme re-sonde apres la pose, meme refus octet pour octet ; un refus sur la re-sonde restitue
# le verrou de compartiment anterieur, sa suppression ne vient qu'apres), refuse "legacy-lock-held" avec en hint la
# commande de release exacte ; perime, "stale-requires-takeover" avec le recover cible. Rien n'est
# repris, relache ni supprime en silence, et aucun verbe n'est neuf : l'ancien verrou se manie par
# VF_DRIVER_LOCK=.planning/DRIVER.lock. Les verbes autres qu'acquire, appeles sans --ws ni --depot
# quand le verrou de depot est absent, retombent sur l'ancien verrou ("scope_reason":
# "legacy-fallback", "legacy_lock": true) : un manager en vol pendant la mise a jour garde son verrou.
# status porte toujours "legacy_lock" (true|false) en lab partitionne. Un ancien verrou qui apparait ENTRE la
# sonde et la pose (R-4) est re-sonde apres la pose : le processus retire sa propre pose et rend le MEME refus.
# Un ancien verrou perime rend le meme reason "stale-requires-takeover" qu'un compartiment perime, avec un hint
# different (VF_DRIVER_LOCK=<ancien verrou> driver-lock.sh recover) : c'est le hint qui les distingue.
# HORS GIT (P57-D-07) : sans dossier commun, le repli est .planning/DRIVER.lock.d/{ws/<sujet>,repo}/
# DRIVER.lock, sous le motif .planning/DRIVER.lock* du .gitignore ; le JSON dit "location": "checkout".
# LIMITE ECRITE (A4, T-57-37) : un worktree sur une branche d'avant la partition n'a pas de dossier
# de compartiments, il bascule donc en regime plat (verrou historique) alors que le clone est
# partitionne ; non mesure ici, l'usage reel releve de la Phase 61.
# STATUS --ALL (P57-D-24, P57-D-31, P57-D-32) : en lab partitionne, une ligne JSON {"present": <au moins
# une entree presente>, "scope": "lab", "location", "legacy_lock", "locks": [ une entree par verrou ],
# "children_running": <somme>}. Entrees dans l'ordre depot, ancien verrou (s'il existe), chaque
# compartiment du disque, puis tout verrou de compartiment present sous le dossier commun sans dossier
# de compartiment. Chaque entree est la ligne de status de CE verrou (ttl compris pour une entree
# presente). Un nom de dossier ecarte par vf_ws_name_valid n'entre jamais dans le JSON : il est
# compte sur stderr. --all n'est accepte que par status ; avec --ws ou --depot en lab partitionne
# -> ws-invalid. Mode verrou unique : exactement la sortie de status.
# REGISTRE PAR VERROU (P57-D-31) : en lab partitionne le registre des agents est le frere du verrou
# resolu (vf-driver/ws/<sujet>/DRIVER.lock.children.jsonl) ; VF_DRIVER_CHILDREN n'est honoree qu'en
# mode verrou unique. Tous les verbes portent --ws et le suffixe de portee (scope, ws, location).
# VF_DRIVER_LOCK non vide, ou lab plat : mode verrou unique, --ws/--depot acceptes et sans effet
# (P57-D-22, P57-D-31) ; vf_dl_resolve rend la main avant toute lecture de ces options.
# LAB PLAT, ou VF_DRIVER_LOCK pose : comportement historique, au bit pres — la politique de noms
# n'est meme pas chargee. LIMITE ECRITE (P57-D-29) : deux .planning/ dans un meme clone partagent
# vf-driver/, hors perimetre.

set -uo pipefail

LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"
TTL="${VF_DRIVER_TTL:-1800}"
META="$LOCK_DIR/meta"
case "$TTL" in ''|*[!0-9]*) TTL=1800 ;; esac  # garde : TTL non numerique -> defaut (L3)
SESSION_MAX="${VF_DRIVER_SESSION_MAX:-8}"
case "$SESSION_MAX" in ''|*[!0-9]*) SESSION_MAX=8 ;; esac  # meme garde que TTL (D-32-03, plafond LRU)

ACTION=""; OWNER=""; STEP=""
WS=""; WS_GIVEN=0; DEPOT=0; ALL=0
AGENT=""; ROLE=""; NODE=""; PARENT=""; DEPTH=""; CSTATUS=""
for arg in "$@"; do
  case "$arg" in
    acquire|heartbeat|release|status|recover|takeover|reclaim|mark-progress|register|close|orphans) ACTION="$arg" ;;
    --owner=*)  OWNER="${arg#*=}" ;;
    --step=*)   STEP="${arg#*=}" ;;
    --ws=*)     WS="${arg#*=}"; WS_GIVEN=1 ;;
    --depot)    DEPOT=1 ;;
    --all)      ALL=1 ;;
    --agent=*)  AGENT="${arg#*=}" ;;
    --role=*)   ROLE="${arg#*=}" ;;
    --node=*)   NODE="${arg#*=}" ;;
    --parent=*) PARENT="${arg#*=}" ;;
    --depth=*)  DEPTH="${arg#*=}" ;;
    --status=*) CSTATUS="${arg#*=}" ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

# --all n'est accepte que par status (P57-D-31) : message d'usage sur stderr, rien sur stdout, exit 1.
if [ "$ALL" = 1 ] && [ "$ACTION" != status ]; then
  echo "Usage: $0 status --all (--all n'est accepte que par status)" >&2
  exit 1
fi

log() { echo "[driver-lock.sh] $*" >&2; }
now() { date +%s; }
iso() { date +%Y-%m-%dT%H:%M:%S; }
meta_get() { [ -f "$META" ] && grep "^$1=" "$META" 2>/dev/null | head -1 | cut -d= -f2- || true; }

# Assainit un identifiant de session (D-32-03(a)) : le champ meta est une liste separee par des
# virgules, un identifiant qui en porterait une casserait la lecture. On SUPPRIME les caracteres
# hors classe (tr -dc), pas de substitution — une substitution (comme le "_" du mutex L200)
# laisserait un caractere a la place, une virgule injectee resterait un separateur potentiel.
sanitize_session_id() { printf '%s' "$1" | tr -dc 'A-Za-z0-9._-'; }

# Assainit un champ LIBRE (owner/step, correction juge #3) destine a l'ecriture meta ET a chaque
# printf JSON direct de ce script (acquire/takeover/reclaim/heartbeat emettent owner/step SANS
# repasser par le meta relu). Repro mesuree : `acquire --owner='mission"X'` rendait un JSON
# INVALIDE (guillemet non echappe casse le parsing en aval — driver-lock.sh status | jq -r
# .generation, prescrit par team-kernel.md, casse a la source). BEAUCOUP moins restrictif que
# sanitize_session_id() (allowliste stricte, adaptee a un identifiant technique) : owner/step
# restent du texte libre pour un humain (espaces, accents, slashes, '=' preserves — aucun des deux
# ne sert de separateur dans le meta, qui coupe sur le PREMIER '=' seulement, cote bash ET cote
# python du guard) — SEULS les caracteres qui rendent un printf JSON direct invalide disparaissent :
# guillemet double et antislash. Assaini UNE SEULE FOIS a l'entree (juste apres le parsing des
# arguments ci-dessous), jamais recalcule ailleurs : toute lecture ulterieure de $OWNER/$STEP,
# qu'elle aille au meta ou a un printf JSON immediat, voit deja la forme assainie.
sanitize_field() { printf '%s' "$1" | tr -d '"\\\n'; }
OWNER="$(sanitize_field "$OWNER")"
STEP="$(sanitize_field "$STEP")"

# Valeur brute (CSV) du champ additif session_ids. Vide si la cle est absente du meta — meta_get
# rend deja le vide sans echouer, donc un lock pose par une version anterieure du script (sans
# cette ligne) reste lisible (retrocompatibilite, T18).
lock_session_ids() { meta_get session_ids; }

# Emet un tableau JSON depuis la chaine CSV de session_ids. CSV vide -> "[]". `sanitize_session_id`
# garantit qu'aucun caractere a echapper (guillemet, backslash...) n'entre jamais dans le champ :
# aucun echappement n'est donc requis ni ecrit ici.
json_session_ids() {
  local csv="$1" out="" first=true id
  [ -z "$csv" ] && { echo '[]'; return; }
  local IFS=','
  for id in $csv; do
    [ -z "$id" ] && continue
    if $first; then out="\"$id\""; first=false; else out="${out}, \"$id\""; fi
  done
  echo "[$out]"
}

# Ajoute un identifiant a la liste CSV de session_ids (D-32-03, reserve "croissance non bornee"
# levee au plan) : dedup — l'identifiant deja present est retire de sa position puis reecrit en
# queue — puis plafond LRU : au-dela de SESSION_MAX (garde de numericite ci-dessus), les entrees
# les plus ANCIENNES sont evincees par la tete, le nouvel identifiant restant en queue.
#
# Arbitrage : le plafond LRU est retenu contre la purge agressive ("garder seulement l'identifiant
# courant plus celui qui vient d'etre ajoute") parce qu'une mission qui alterne entre deux fenetres
# verrait la purge evincer une identite deja re-rattachee, et re-declencherait un refus pour un
# detenteur legitime — exactement le mode de defaillance que reclaim existe pour fermer. Huit
# entrees bornent le champ sous ~350 octets ; au-dela de huit identites distinctes pour un meme
# mandat, le probleme n'est plus la taille du fichier.
#
# `takeover` n'a besoin d'AUCUNE purge : il passe par new_generation(), son meta est ecrit a neuf,
# la liste est structurellement reduite au seul repreneur (cas T31) — cette fonction n'est donc
# appelee QUE par `reclaim`.
session_ids_append() {
  local csv="$1" id="$2" out="" existing e n=0 excess trimmed k
  local IFS=','
  for existing in $csv; do
    [ -z "$existing" ] && continue
    [ "$existing" = "$id" ] && continue
    if [ -z "$out" ]; then out="$existing"; else out="${out},${existing}"; fi
  done
  if [ -z "$out" ]; then out="$id"; else out="${out},${id}"; fi
  for e in $out; do n=$((n+1)); done
  if [ "$n" -gt "$SESSION_MAX" ]; then
    excess=$((n - SESSION_MAX)); trimmed=""; k=0
    for e in $out; do
      k=$((k+1))
      [ "$k" -le "$excess" ] && continue
      if [ -z "$trimmed" ]; then trimmed="$e"; else trimmed="${trimmed},${e}"; fi
    done
    out="$trimmed"
  fi
  printf '%s' "$out"
}

# ---------------------------------------------------------------------------------------------
# RESOLUTION DU VERROU NOMME (Phase 57) — UN SEUL point d'insertion. LOCK_DIR et META sont
# reassignes ICI, avant que LOCK_PARENT, LOCK_BASE, REG, les mutex `.rec.*`, le journal
# `.events.log` et la generation n'en soient derives : toute la mecanique d'acquisition (lien
# remplace par rename(2), mutex nomme d'apres la generation observee) est PARAMETREE par
# l'emplacement, jamais retouchee (en-tete l.15-17 : deux correctifs de fenetre mesures pires).
#
# LAB PLAT, ou VF_DRIVER_LOCK pose et non vide : la fonction ne fait RIEN — ni `source`, ni `git`,
# ni test de plus que `-e`/`-L` sur le dossier des compartiments (P57-D-03, comportement historique
# au bit pres). Le lab est dit partitionne quand .planning/workstreams existe ou est un lien : le
# test nu `-d` ignorerait un lien et un fichier regulier, qui seraient alors pris pour un lab plat
# en silence (P57-D-25) ; la detection fine est vf_ws_enumerate, rc 0/2/3.
# ---------------------------------------------------------------------------------------------
PARTITIONED=0; SCOPE=""; LOCATION=""; SCOPE_JSON=""; LOCK_ROOT=""
# Option de cible a rejouer avec une commande nommee par un hint (R-1) : " --ws=<sujet>" ou " --depot"
# en lab partitionne, vide ailleurs (le hint du lab plat reste celui d'avant la phase, octet pour octet).
HINT_TARGET=""
# Ancien verrou unique (P57-D-26) : le chemin historique, evalue par rapport au cwd comme le defaut
# de LOCK_DIR. Lu seulement en lab partitionne ; jamais cree, jamais supprime par la resolution.
LEGACY_DIR=".planning/DRIVER.lock"; LEGACY_PRESENT=false

# Refus nomme, rejouable. La cle de tete suit le verbe (`error` pour status/orphans : JAMAIS une
# cle `present`, qui se lirait « relache »). $3 = nom de sujet DEJA valide (jamais une valeur brute).
vf_dl_refuse() { # <raison> <hint> [sujet-valide]
  local reason="$1" hint="$2" extra="" key
  [ -n "${3:-}" ] && extra=", \"ws\": \"$3\""
  case "$ACTION" in
    acquire|takeover)        key='"acquired": false' ;;
    reclaim)                 key='"reclaimed": false' ;;
    heartbeat|mark-progress) key='"ok": false' ;;
    release)                 key='"released": false' ;;
    recover)                 key='"recovered": false' ;;
    register)                key='"registered": false' ;;
    close)                   key='"closed": false' ;;
    *)                       key="\"error\": \"$reason\"" ;;
  esac
  printf '{%s, "reason": "%s", "hint": "%s"%s}\n' "$key" "$reason" "$hint" "$extra"
  exit 1
}

# Dossier commun du clone, CANONICALISE (`cd` + `pwd -P`, jamais comparé brut : `--git-common-dir`
# rend un chemin relatif au cwd dans un checkout simple, absolu dans un worktree lie ; jamais
# `--path-format=absolute`, absent des git anciens). Rend 1 hors depot git.
vf_dl_common_dir() {
  local d
  d="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
  [ -n "$d" ] || return 1
  case "$d" in /*) ;; *) d="$PWD/$d" ;; esac
  (cd "$d" 2>/dev/null && pwd -P)
}

# P57-D-56 (revise P57-D-25) : un dossier des compartiments PRESENT mais SANS AUCUN compartiment (vide, ou ne
# portant que des fichiers comme .gitkeep) se traite comme un lab plat, comme en v2.69.1. Un lien symbolique ou un
# fichier regulier a la place du dossier reste « present » (refuse plus loin : partition-unreadable). Un lien ou un
# sous-dossier non cache dans le dossier suffit a le dire present : leur jugement revient a vf_ws_enumerate.
vf_dl_ws_present() { # <chemin du dossier workstreams> -> 0 = partitionne (ou illisible), 1 = absent ou vide
  local w="$1" e
  [ -e "$w" ] || [ -L "$w" ] || return 1
  if [ -L "$w" ] || [ ! -d "$w" ] || [ ! -r "$w" ] || [ ! -x "$w" ]; then return 0; fi
  for e in "$w"/*; do
    if [ -L "$e" ] || [ -d "$e" ]; then return 0; fi
  done
  return 1  # D56-VIDE
}

vf_dl_resolve() {
  [ -n "$ACTION" ] || return 0
  [ -z "${VF_DRIVER_LOCK:-}" ] || return 0
  # HORS RACINE DU LAB (P57-D-39, correction F-2) : `--ws` ou `--depot` lance d'un dossier qui ne porte pas son
  # propre `.planning/` alors que la racine git en porte les compartiments. Sans ce refus la detection (relative
  # au cwd) rendrait le lab « plat », le verrou d'autrui ne serait pas vu et un `.planning/DRIVER.lock` parasite
  # serait cree dans le sous-dossier. Un dossier portant SON `.planning/` (P57-D-29) n'est pas concerne.
  # #58 : meme refus AVEC ou SANS option, en lab partitionne comme en lab plat (`--ws`/`--depot` sont inertes en lab
  # plat, P57-D-03, mais l'ecriture d'un verrou dans le sous-dossier ne l'est pas), des que la racine git porte un
  # `.planning/` que le cwd n'a pas — sinon le chemin relatif cree un verrou fantome `<sous-dossier>/.planning/DRIVER.lock` et deux
  # missions croient chacune tenir le verrou. `status` et `orphans` sans option (lecture seule, ne creent rien) restent
  # inchanges : check-guard-health.sh lit `status --all` depuis un cwd quelconque et ne doit pas devenir bruyant.
  if [ ! -e .planning ] && [ ! -L .planning ]; then
    local top="" named=0 mutating=1
    if [ "$WS_GIVEN" = 1 ] || [ "$DEPOT" = 1 ]; then named=1; fi
    case "$ACTION" in status|orphans) mutating=0 ;; esac
    if [ "$named" = 1 ] || [ "$mutating" = 1 ]; then
      top="$(git rev-parse --show-toplevel 2>/dev/null)" || top=""
      local why=""
      if [ -n "$top" ] && vf_dl_ws_present "$top/.planning/workstreams"; then
        why="ce dossier n'est pas la racine du lab partitionne : lance driver-lock.sh depuis la racine du lab (le dossier qui porte .planning/workstreams), puis rejoue la commande avec la meme option --ws ou --depot"
      elif [ -n "$top" ] && [ "$mutating" = 1 ] && { [ -d "$top/.planning" ] || [ -L "$top/.planning" ]; }; then
        why="ce dossier ne porte pas son propre .planning/ alors que la racine git en porte un : lance driver-lock.sh depuis la racine du lab (le dossier qui porte .planning), puis rejoue la commande avec la meme option --ws ou --depot si tu en passais une"
      fi
      if [ -n "$why" ]; then
        vf_dl_refuse not-at-lab-root "$why"
      fi
    fi
  fi
  vf_dl_ws_present .planning/workstreams || return 0

  local policy="" cand common rc=0
  for cand in "$(dirname "$0")/workstream-policy.sh" \
              "$(dirname "$0")/../../planning-core/scripts/workstream-policy.sh"; do
    [ -f "$cand" ] && { policy="$cand"; break; }
  done
  [ -n "$policy" ] || vf_dl_refuse policy-missing "script workstream-policy.sh introuvable : /vf-update reinstalle le module planning-core puis rejouer la commande"
  # shellcheck source=/dev/null
  . "$policy"

  # Detection fine du regime. rc 3 = le dossier a disparu entre les deux tests : regime plat.
  vf_ws_enumerate ".planning" >/dev/null 2>&1; rc=$?
  case "$rc" in
    0) ;;
    3) return 0 ;;
    *) vf_dl_refuse partition-unreadable "le dossier des compartiments est illisible (lien symbolique, fichier regulier ou compartiment en lien) : le rendre a l'etat de dossier reel puis rejouer la commande" ;;
  esac
  PARTITIONED=1

  # Emplacement (P57-D-07, P57-D-21) : le dossier commun du clone, partage par tous ses worktrees ;
  # hors depot git, repli sous .planning/DRIVER.lock.d (couvert par le motif .planning/DRIVER.lock*
  # du .gitignore), que le JSON declare ("location": "checkout").
  if common="$(vf_dl_common_dir)"; then
    LOCK_ROOT="$common/vf-driver"; LOCATION="git-common-dir"
  else
    LOCK_ROOT=".planning/DRIVER.lock.d"; LOCATION="checkout"
  fi

  # status --all vise le lab entier : une cible designee en plus est une erreur (P57-D-32).
  if [ "$ALL" = 1 ] && { [ "$WS_GIVEN" = 1 ] || [ "$DEPOT" = 1 ]; }; then
    vf_dl_refuse ws-invalid "--all lit tous les verrous du lab : rejouer sans --ws ni --depot, ou avec --ws=<sujet> sans --all"
  fi
  if [ "$WS_GIVEN" = 1 ]; then
    # Validation AVANT tout chemin ou JSON (T-57-01, T-57-06). La liste n'est jamais passee dans
    # un pipeline vers une recherche a sortie anticipee (SIGPIPE sous pipefail, piege P1).
    [ "$DEPOT" = 0 ] || vf_dl_refuse ws-invalid "--ws et --depot s'excluent : choisir l'un ou l'autre"
    [ -n "$WS" ] && vf_ws_name_valid "$WS" || vf_dl_refuse ws-invalid "--ws attend un nom de sujet (lettres, chiffres, point, souligne, tiret) : rejouer avec --ws=<sujet>, ou --depot pour le verrou de depot"
    vf_ws_dir_resolve ".planning" "$WS"; rc=$?
    case "$rc" in
      0) ;;
      2) vf_dl_refuse ws-invalid "le compartiment designe est un lien symbolique, refuse : rejouer avec un compartiment reel" ;;
      *) vf_dl_refuse unknown-ws "aucun compartiment de ce nom : lister les compartiments avec driver-lock.sh status --all puis rejouer" "$WS" ;;
    esac
    LOCK_DIR="$LOCK_ROOT/ws/$WS/DRIVER.lock"
    SCOPE="compartiment"
    HINT_TARGET=" --ws=$WS"
    SCOPE_JSON=", \"scope\": \"$SCOPE\", \"ws\": \"$WS\", \"location\": \"$LOCATION\""
  else
    # Cible = DEPOT : un emplacement distinct (`repo/`, jamais `ws/…`), independant de tout verrou
    # de compartiment (P57-D-01, P57-D-02). Sans --ws NI --depot, la cible n'a pas ete designee :
    # le JSON le dit (`scope_reason`), un export oublie ne se transforme jamais en verrou de sujet.
    LOCK_DIR="$LOCK_ROOT/repo/DRIVER.lock"
    SCOPE="depot"
    HINT_TARGET=" --depot"
    SCOPE_JSON=", \"scope\": \"$SCOPE\", \"ws\": \"\", \"location\": \"$LOCATION\""
    [ "$DEPOT" = 1 ] || SCOPE_JSON="$SCOPE_JSON, \"scope_reason\": \"ws-absent\""
    # Repli sur l'ancien verrou (P57-D-24) : un verbe autre qu'acquire, sans --ws ni --depot, quand
    # le verrou de depot est absent et l'ancien present, vise l'ancien. C'est ce qui garde un manager
    # en vol pendant la mise a jour : ses verbes sans --ws retombent sur SON verrou.
    if [ "$ACTION" != acquire ] && [ "$ALL" = 0 ] && [ "$DEPOT" = 0 ] && [ ! -L "$LOCK_DIR" ] && [ ! -d "$LOCK_DIR" ] \
       && { [ -L "$LEGACY_DIR" ] || [ -d "$LEGACY_DIR" ]; }; then
      LOCK_DIR="$LEGACY_DIR"
      LOCATION="checkout"
      SCOPE_JSON=", \"scope\": \"$SCOPE\", \"ws\": \"\", \"location\": \"$LOCATION\", \"scope_reason\": \"legacy-fallback\", \"legacy_lock\": true"
    fi
  fi
  # status expose toujours legacy_lock en lab partitionne (P57-D-26, P57-D-32), cible ou non.
  if [ -L "$LEGACY_DIR" ] || [ -d "$LEGACY_DIR" ]; then LEGACY_PRESENT=true; fi
  if [ "$ACTION" = status ]; then
    case "$SCOPE_JSON" in *'"legacy_lock"'*) ;; *) SCOPE_JSON="$SCOPE_JSON, \"legacy_lock\": $LEGACY_PRESENT" ;; esac
  fi
  META="$LOCK_DIR/meta"
}
vf_dl_resolve

LOCK_PARENT="$(dirname "$LOCK_DIR")"
LOCK_BASE="$(basename "$LOCK_DIR")"

# Remplacement ATOMIQUE d'un lien : rename(2) par-dessus le lien existant. Sans option, `mv`
# SUIT un lien vers un dossier et deplace la source DEDANS (verifie sur ce poste) — le lock
# serait alors intact et le nouveau claim invisible. BSD/macOS : -h ; GNU/Linux : -T.
mv_link() {
  mv -h "$1" "$2" 2>/dev/null || mv -T "$1" "$2" 2>/dev/null
}

# Deplacement SANS ECRASER ET SANS SUIVRE un lien (AU3-04) : `mv -n` seul, si la destination est un lien vers un
# dossier, y deplacerait la source (elle serait enterree dans la generation d'un autre tenant). BSD/macOS : -nh ;
# GNU/Linux : -nT. Le code de sortie n'est pas fiable (BSD rend 0 devant une destination prise) : l'appelant VERIFIE
# le resultat (lock_gen), jamais ce code.
mv_noclobber() {
  mv -nh "$1" "$2" 2>/dev/null || mv -nT "$1" "$2" 2>/dev/null
}

# Creation ATOMIQUE d'un lien, qui ECHOUE si le nom est deja pris — c'est le primitif qui
# departage les acquisitions concurrentes. MEME PIEGE que `mv` : sans option, `ln -s A B` ou B
# est un lien vers un dossier cree `B/A` et rend 0. Le lock paraissait alors libre a chaque
# acquisition (mesure : 8 gagnants sur 8). BSD/macOS : -h ; GNU/Linux : -n. L'enchainement
# couvre les deux — sur l'un l'option manquante echoue, sur l'autre elle fait le travail, et un
# nom deja pris echoue des deux cotes (c'est le refus recherche).
ln_atomic() {
  ln -sh "$1" "$2" 2>/dev/null || ln -sn "$1" "$2" 2>/dev/null
}

# age du lock en secondes. heartbeat_epoch s'il est numerique ; SINON mtime de la CIBLE du lien
# (fix H2 : un meta vide/partiel — process mort entre la creation et l'ecriture — devient
# recuperable apres TTL au lieu de rester eternellement "frais" et de geler toutes les missions).
lock_age() {
  local hb; hb="$(meta_get heartbeat_epoch)"
  case "$hb" in ''|*[!0-9]*) hb="" ;; esac
  # GNU (-c) AVANT BSD (-f) : sur GNU, `stat -f` = mode filesystem — il imprime un bloc
  # multi-lignes sur stdout PUIS échoue, et la substitution capturait bloc + fallback
  # (hb non numérique → staleness jamais détectée). BSD échoue proprement sur -c.
  [ -z "$hb" ] && hb="$(stat -c %Y "$LOCK_DIR" 2>/dev/null || stat -f %m "$LOCK_DIR" 2>/dev/null || now)"
  echo "$(( $(now) - hb ))"
}

# Age de la LEASE (D-32-01) : depuis combien de temps CETTE mission tient le lock, independamment
# de son dernier battement. INFORMATIONNEL SEUL — n'entre dans AUCUN calcul de peremption ni dans
# AUCUN refus. Une borne de duree totale sur la lease contredirait frontalement « lock perime !=
# mission morte » : ce serait ouvrir le mode de defaillance symetrique de celui que cette phase
# existe pour fermer (une mission longue mais vivante ne doit jamais etre volee au motif de son
# anciennete — lock_age()/TTL/stale restent adosses au SEUL heartbeat_epoch, sans changement ici).
# Absente/non numerique -> la fonction n'emet RIEN et rend non nul, l'appelant rend alors `null`
# en JSON — jamais un 0, qui se lirait faussement « lease posee a l'instant ».
lease_age() {
  local ap; ap="$(meta_get acquired_epoch)"
  case "$ap" in ''|*[!0-9]*) return 1 ;; esac
  echo "$(( $(now) - ap ))"
}

# Age du PROGRES (D-33-A, WTCH-01) : depuis combien de temps le dernier `mark-progress` a ete
# emis, INDEPENDAMMENT du heartbeat. DONNEE BRUTE exposee pour un consommateur externe (plan
# 33-03, le detecteur de stall) — ce fichier ne decide JAMAIS "stall" ou "abandon" a partir de
# cette valeur, il ne fait qu'exposer. Meme garde de numericite que lease_age(). Absente/non
# numerique -> la fonction n'emet RIEN et rend non nul, l'appelant rend alors `null` en JSON —
# jamais un 0, qui se lirait faussement "progres a l'instant".
progress_age() {
  local pe; pe="$(meta_get progress_epoch)"
  case "$pe" in ''|*[!0-9]*) return 1 ;; esac
  echo "$(( $(now) - pe ))"
}

# Presence du lock, quelle que soit sa forme : lien (nominal) ou dossier reel (lock legacy pose
# par une version anterieure, ou dossier nu cree a la main). Les deux doivent rester gerables,
# sinon une mise a jour du script gelerait les sessions en cours.
lock_present() { [ -L "$LOCK_DIR" ] || [ -d "$LOCK_DIR" ]; }
# Nom de la generation courante — sert d'identite au mutex de recuperation. Un lock legacy
# (dossier reel) n'a pas de generation : on lui en donne une stable et distincte.
lock_gen() { if [ -L "$LOCK_DIR" ]; then readlink "$LOCK_DIR"; else echo "legacy"; fi; }

# Branche et arbre de travail du poseur du lock (ADR-064). Le claim ne disait QUE l'etape :
# il ne permettait pas de repondre a « qui tient CETTE branche ? », la question posee par la
# collision du 2026-07-31. Champs ADDITIFS. Capture faite a l'ACQUISITION et PRESERVEE au
# heartbeat (meme patron que acquired_epoch) : un heartbeat emis apres un `git checkout` ne doit
# pas reecrire le claim, sinon le lock revendiquerait une branche que personne n'a decide de piloter.
git_branch() { git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n' || true; }
git_worktree() { git rev-parse --show-toplevel 2>/dev/null | tr -d '\n' || true; }

# Cree une generation NEUVE (dossier + meta complet) et rend son nom. Le meta est ecrit AVANT que
# la generation ne soit publiee : un lock publie est toujours un lock complet — c'est cette
# propriete qui supprime la fenetre « present mais vide » de la forme precedente.
new_generation() {
  local ts iso_ts gen
  ts="$(now)"; iso_ts="$(iso)"
  gen="${LOCK_BASE}.gen.${ts}.$$"
  mkdir -p "$LOCK_PARENT" 2>/dev/null || true
  mkdir "$LOCK_PARENT/$gen" 2>/dev/null || return 1
  {
    printf 'owner=%s\n'           "$(printf '%s' "$OWNER" | tr -d '\n')"
    printf 'step=%s\n'            "$(printf '%s' "$STEP"  | tr -d '\n')"
    printf 'branch=%s\n'          "$(printf '%s' "$(git_branch)"   | tr -d '\n')"
    printf 'worktree=%s\n'        "$(printf '%s' "$(git_worktree)" | tr -d '\n')"
    printf 'session_ids=%s\n'     "$(sanitize_session_id "${CLAUDE_CODE_SESSION_ID:-}")"
    printf 'acquired_epoch=%s\n'  "$ts"
    printf 'acquired_iso=%s\n'    "$iso_ts"
    printf 'heartbeat_epoch=%s\n' "$ts"
    printf 'progress_epoch=%s\n'  "$ts"
  } > "$LOCK_PARENT/$gen/meta" || { rm -rf "$LOCK_PARENT/$gen"; return 1; }
  echo "$gen"
}

# Reecrit le meta de la generation COURANTE en place (heartbeat, re-acquisition du meme owner,
# reclaim). Le lien ne bouge pas : rien a serialiser, l'owner est deja etabli.
#
# (SE-3) Second parametre POSITIONNEL optionnel pour session_ids : "${2-$(lock_session_ids)}" —
# PAS "${2:-...}" (une chaine vide EST une valeur valide, ne doit jamais retomber sur le fichier).
# Absent -> lecture du fichier courant, le comportement EXACT des deux appelants historiques a un
# seul argument : la ré-acquisition idempotente dans `acquire` (voie occupee/meme owner) et le
# battement dans `heartbeat`. SEUL `reclaim` passe ce second argument explicitement — c'est la
# valeur decidee SOUS MUTEX, jamais relue du fichier apres coup, sinon l'ecriture ne serait pas
# celle qui a ete arbitree pendant la fenetre de serialisation.
#
# (D-33-A) 3e parametre POSITIONNEL optionnel pour progress_epoch, MEME patron EXACT que le 2e
# (session_ids) : "${3-$(meta_get progress_epoch)}" — PAS "${3:-...}", une chaine vide EST une
# valeur valide. Absent -> lecture du fichier courant, donc `heartbeat` (1 argument) et `reclaim`
# (2 arguments) PRESERVENT progress_epoch sans le savoir. SEUL `mark-progress` passe ce 3e
# argument explicitement, et seulement lui.
rewrite_meta() {
  local ap ai br wt si pe
  ap="$(meta_get acquired_epoch)"; ai="$(meta_get acquired_iso)"
  br="$(meta_get branch)"; wt="$(meta_get worktree)"
  # session_ids est LU depuis le meta courant par defaut, JAMAIS depuis l'environnement de la
  # session qui appelle rewrite_meta — c'est ce qui fait qu'un heartbeat emis d'un autre contexte
  # (ADR-064, meme patron que branch/worktree ci-dessus) ne peut jamais reecrire l'identite du
  # detenteur, sauf appel explicite (reclaim) qui passe la valeur decidee sous mutex.
  si="${2-$(lock_session_ids)}"
  pe="${3-$(meta_get progress_epoch)}"
  {
    printf 'owner=%s\n'           "$(printf '%s' "$OWNER" | tr -d '\n')"
    printf 'step=%s\n'            "$(printf '%s' "$STEP"  | tr -d '\n')"
    printf 'branch=%s\n'          "$br"
    printf 'worktree=%s\n'        "$wt"
    printf 'session_ids=%s\n'     "$si"
    printf 'acquired_epoch=%s\n'  "$ap"
    printf 'acquired_iso=%s\n'    "$ai"
    printf 'heartbeat_epoch=%s\n' "$1"
    printf 'progress_epoch=%s\n'  "$pe"
  } > "$META"
}

# Supprime lien + generation pointee (ou le dossier reel d'un lock legacy).
drop_lock() {
  if [ -L "$LOCK_DIR" ]; then
    local gen; gen="$(readlink "$LOCK_DIR")"
    rm -f "$LOCK_DIR"
    case "$gen" in */*|'') ;; *) rm -rf "${LOCK_PARENT:?}/$gen" ;; esac
  else
    rm -rf "$LOCK_DIR"
  fi
}

# Journal append-only des evenements de reprise (D-32-02) : takeover, reclaim, recover. FRERE du
# lock, JAMAIS dedans — `drop_lock` et la reprise (takeover/reclaim) detruisent le dossier de
# generation, donc toute trace ecrite dedans mourrait avec ce qu'elle documente. Le nom s'ecarte du
# "$LOCK_BASE.takeovers.log" indicatif du cadrage parce que le fichier journalise TROIS natures
# d'evenement (reprise, re-rattachement, elagage), pas une seule — un nom qui n'en nomme qu'une
# induirait en erreur son futur lecteur.
#
# BEST-EFFORT : un echec d'ecriture n'echoue JAMAIS l'operation appelante — seulement diagnostique
# sur stderr par `log`. Un journal indisponible ne bloque jamais le verrou (T45) ; un echappement
# SILENCIEUX serait exactement la dette que cette phase ferme ailleurs.
#
# `owner` est une chaine LIBRE, jamais validee par ce script (32-TERRAIN.md §1) : les champs de
# type chaine passent par `sanitize_session_id` (meme assainissement par classe de caracteres,
# reutilise plutot que reinvente) pour qu'une entree non fiable ne puisse jamais casser le JSON du
# journal.
#
# (MI-4) Pas de rotation ni de plafond de taille : une ligne courte par evenement de reprise, un
# evenement RARE par construction (le fichier ne croit qu'au rythme des reprises, pas des commits).
# Choix assume, pas un oubli — une rotation ajouterait de la complexite pour un gain non mesure. A
# revisiter si le volume observe le justifie un jour, pas dans cette phase.
journal_event() {
  local event="$1" prev="$2" new="$3" sid="$4" age="$5" gen="$6"
  local log_path="$LOCK_PARENT/${LOCK_BASE}.events.log"
  local p n s
  p="$(sanitize_session_id "$prev")"; n="$(sanitize_session_id "$new")"; s="$(sanitize_session_id "$sid")"
  gen="$(printf '%s' "$gen" | tr -dc 'A-Za-z0-9._-')"
  case "$age" in ''|*[!0-9]*) age=0 ;; esac
  if ! printf '{"ts": "%s", "epoch": %s, "event": "%s", "previous_owner": "%s", "new_owner": "%s", "session_id": "%s", "age_seconds": %s, "generation": "%s"}\n' \
    "$(iso)" "$(now)" "$event" "$p" "$n" "$s" "$age" "$gen" >> "$log_path" 2>/dev/null; then
    log "journal indisponible ($log_path) — reprise non tracee mais non bloquee"
  fi
}

# ---------------------------------------------------------------------------------------------
# Registre des agents dispatches (issue #82).
#
# POURQUOI ICI, et pas dans le dag.json de mission. Quand un manager meurt (chien de garde,
# coupure), ses workers et leurs propres sous-agents survivent sans proprietaire ; un manager de
# remplacement doit pouvoir les retrouver AVANT de savoir quoi que ce soit de la mission. Le lock
# est le seul chemin fixe et connu de tous (manager, workers, gate de sortie) : le registre vit
# donc a cote de lui, sous un nom derive du sien, comme le journal des reprises. Le dag.json, lui,
# est un fichier par mission dont le chemin n'est connu que du manager qui l'a cree ; un worker
# qui dispatche une brique GSD ne l'a pas sous la main, et un noeud peut porter plusieurs agents
# au fil des relances.
#
# FORME : JSON Lines, APPEND-ONLY. Chaque ligne est un evenement complet (`register` ou `close`)
# ecrit d'un seul printf en O_APPEND : plusieurs workers d'un meme etage peuvent consigner en meme
# temps sans mutex ni lecture-modification-ecriture, et une mort entre deux lignes ne corrompt
# rien. L'etat courant se DERIVE en repliant les lignes (derniere ligne par agent_id gagne) ;
# `registry_fold` ci-dessous est l'unique lecteur, jamais un parse a la main ailleurs.
#
# FRERE du lock, JAMAIS dedans : `drop_lock`/`takeover` detruisent la generation, or les
# orphelins a retrouver sont precisement ceux de la generation qui vient de mourir. Le registre
# survit donc a la reprise ; il n'est supprime que par un `release` sans enfant `running`.
#
# STATUT CONSIGNE, pas statut runtime : le registre dit ce que les agents ont DECLARE. La verite
# de vie d'un agent reste `ListAgents` cote Claude Code ; `orphans` liste ce qu'il faut ALLER
# verifier, et `close --status=stopped` se pose apres la verification, jamais avant.
# ---------------------------------------------------------------------------------------------
if [ "$PARTITIONED" = 1 ]; then
  REG="$LOCK_PARENT/${LOCK_BASE}.children.jsonl"   # frere du verrou resolu ; VF_DRIVER_CHILDREN ignoree (P57-D-31)
else
  REG="${VF_DRIVER_CHILDREN:-$LOCK_PARENT/${LOCK_BASE}.children.jsonl}"
fi
TAB="$(printf '\t')"

# Champ libre du registre (role, node) : meme classe que sanitize_field, plus la tabulation, qui
# est le separateur interne de registry_fold.
sanitize_reg_field() { printf '%s' "$1" | tr -d '"\\\n\t'; }

# Replie le registre en une table TSV, une ligne par agent_id, dans l'ordre de premiere
# apparition. Colonnes :
#   1 agent_id · 2 parent · 3 role · 4 node · 5 owner · 6 generation · 7 dispatched_at
#   8 epoch · 9 depth (explicite au register, sinon derivee de la chaine parent, sinon 1)
#   10 status (derniere ligne gagne ; un `close` d'un agent jamais consigne est ignore)
# Registre absent -> aucune sortie, code 0.
registry_fold() {
  [ -f "$REG" ] || return 0
  awk '
    function val(s, key,   m) {
      if (match(s, "\"" key "\": \"[^\"]*\"")) {
        m = substr(s, RSTART, RLENGTH); sub(/^[^:]*: "/, "", m); sub(/"$/, "", m); return m
      }
      return ""
    }
    function num(s, key,   m) {
      if (match(s, "\"" key "\": [0-9]+")) {
        m = substr(s, RSTART, RLENGTH); sub(/^[^:]*: /, "", m); return m
      }
      return ""
    }
    {
      ev = val($0, "event"); id = val($0, "agent_id")
      if (id == "") next
      if (ev == "register") {
        if (!(id in seen)) { order[++n] = id; seen[id] = 1 }
        parent[id] = val($0, "parent"); role[id] = val($0, "role"); node[id] = val($0, "node")
        owner[id] = val($0, "owner"); gen[id] = val($0, "generation")
        at[id] = val($0, "dispatched_at"); ep[id] = num($0, "epoch"); dp[id] = num($0, "depth")
        status[id] = "running"
      } else if (ev == "close") {
        if (!(id in seen)) next
        s = val($0, "status"); if (s != "") status[id] = s
      }
    }
    END {
      for (i = 1; i <= n; i++) {
        id = order[i]
        d = dp[id]
        if (d == "") {
          d = 1; p = parent[id]; hops = 0
          while (p != "" && (p in seen) && hops < 64) { d++; p = parent[p]; hops++ }
        }
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", id, parent[id], role[id], node[id],
               owner[id], gen[id], at[id], (ep[id] == "" ? 0 : ep[id]), d, status[id]
      }
    }
  ' "$REG"
}

# Entrees encore `running`, ordonnees FEUILLE -> RACINE (profondeur decroissante, puis dispatch
# le plus recent d'abord). C'est l'ordre d'arret impose par la doctrine de reprise, car tuer un
# parent avant son enfant laisse l'enfant reveiller un parent que la session croit fini.
orphans_tsv() { registry_fold | awk -F'\t' '$10 == "running"' | sort -t "$TAB" -k9,9nr -k8,8nr; }
orphans_count() { orphans_tsv | awk 'END { print NR }'; }
orphans_ids_json() {
  local out; out="$(orphans_tsv | awk -F'\t' '{ printf "%s\"%s\"", (NR > 1 ? ", " : ""), $1 }')"
  printf '[%s]' "$out"
}
orphans_json() {
  local nowts; nowts="$(now)"
  local out; out="$(orphans_tsv | awk -F'\t' -v now="$nowts" '{
    printf "%s{\"agent_id\": \"%s\", \"parent\": \"%s\", \"role\": \"%s\", \"node\": \"%s\", \"owner\": \"%s\", \"generation\": \"%s\", \"dispatched_at\": \"%s\", \"age_seconds\": %d, \"depth\": %d, \"status\": \"running\"}",
      (NR > 1 ? ", " : ""), $1, $2, $3, $4, $5, $6, $7, ($8 > 0 ? now - $8 : 0), $9
  }')"
  printf '[%s]' "$out"
}
# Enfants directs encore `running` d'un agent donne (ids JSON) : rendu par `close`, pour qu'un
# parent qui se ferme voie ce qu'il laisse derriere lui.
children_running_of_json() {
  local out; out="$(orphans_tsv | awk -F'\t' -v p="$1" '$2 == p { printf "%s\"%s\"", (c++ > 0 ? ", " : ""), $1 }')"
  printf '[%s]' "$out"
}

json_status() {
  # children_running (issue #82) : nombre d'entrees du registre encore `running`, sur les DEUX
  # branches (lock absent compris) : un lock relache avec des enfants consignes ouverts est
  # exactement le cas « manager termine, enfant jamais ferme » que le gate de sortie doit voir.
  local children; children="$(orphans_count)"
  if [ "$1" = false ]; then
    printf '{"present": false, "lock": "%s", "children_running": %s%s}\n' "$LOCK_DIR" "$children" "$SCOPE_JSON"; return
  fi
  local o s age stale gen sids lease guard_eff pe page
  o="$(meta_get owner)"; s="$(meta_get step)"; age="$(lock_age)"
  [ "$age" -gt "$TTL" ] && stale=true || stale=false
  gen="$(lock_gen)"; sids="$(json_session_ids "$(lock_session_ids)")"
  lease="$(lease_age)" && : || lease="null"  # lease_age() echoue -> null JSON, jamais un 0 trompeur
  # guard_effective (correction juge #6) : rend OBSERVABLE ce que la regle 2 de
  # guard-driver-lock.sh (retrocompat, D-32-03) decide en silence. Un lock ne AVEC session_ids=[]
  # rend le guard INERTE sur TOUTE sa duree de vie (heartbeat ne repeuple jamais session_ids, seul
  # reclaim le fait) sans qu'aucune trace ne le signale ailleurs — mesure en revue : une session
  # tierce commite, rc=0, sous le lock meme de CETTE mission. La regle 2 elle-meme n'est PAS
  # touchee ici (choix assume et teste, R3/T18) : ce champ EXPOSE l'etat, il ne le change pas.
  [ "$sids" = "[]" ] && guard_eff=false || guard_eff=true
  # progress_epoch/progress_age_seconds (D-33-A, WTCH-01) : meme patron que generation/lease —
  # nombre brut si numerique, sinon `null` litteral (jamais entre guillemets, jamais un 0
  # trompeur). Un lock pose par l'ancien script (pas de ligne progress_epoch=) rend `null` sur les
  # deux champs, aucun verbe ne plante (T56).
  pe="$(meta_get progress_epoch)"
  case "$pe" in ''|*[!0-9]*) pe="null" ;; esac
  page="$(progress_age)" && : || page="null"
  printf '{"present": true, "owner": "%s", "step": "%s", "age_seconds": %s, "ttl": %s, "stale": %s, "generation": "%s", "session_ids": %s, "lease_seconds": %s, "guard_effective": %s, "progress_epoch": %s, "progress_age_seconds": %s, "children_running": %s%s}\n' \
    "$o" "$s" "$age" "$TTL" "$stale" "$gen" "$sids" "$lease" "$guard_eff" "$pe" "$page" "$children" "$SCOPE_JSON"
}

# Une entree de status --all : la ligne de json_status d'UN verrou, dans un sous-shell qui reassigne les
# globales derivees du verrou (LOCK_DIR, META, LOCK_PARENT, LOCK_BASE, REG, SCOPE_JSON). Jamais une
# seconde mise en forme du JSON. Rend trois lignes : presence (true|false), children_running, JSON.
vf_dl_entry() { # <dossier du verrou> <suffixe de portee>
  (
    LOCK_DIR="$1"; SCOPE_JSON="$2"; META="$LOCK_DIR/meta"
    LOCK_PARENT="$(dirname "$LOCK_DIR")"; LOCK_BASE="$(basename "$LOCK_DIR")"
    REG="$LOCK_PARENT/${LOCK_BASE}.children.jsonl"
    if lock_present; then echo true; else echo false; fi
    orphans_count
    if lock_present; then json_status true; else json_status false; fi
  )
}

# Aggregat de status --all en lab partitionne (P57-D-24, P57-D-32). Ajoute une entree a ALL_LOCKS,
# somme les enfants, retient la presence. $3 = "optionnel" : une entree absente est alors ecartee.
ALL_LOCKS=""; ALL_CHILDREN=0; ALL_PRESENT=false; ALL_SKIPPED=0
vf_dl_all_add() { # <dossier du verrou> <suffixe de portee> [optionnel]
  local e pres kids json
  e="$(vf_dl_entry "$1" "$2")"
  pres="$(printf '%s\n' "$e" | sed -n 1p)"; kids="$(printf '%s\n' "$e" | sed -n 2p)"; json="$(printf '%s\n' "$e" | sed -n 3p)"
  if [ "${3:-}" = optionnel ] && [ "$pres" != true ]; then return 0; fi
  [ "$pres" = true ] && ALL_PRESENT=true
  ALL_CHILDREN=$((ALL_CHILDREN + kids))
  if [ -z "$ALL_LOCKS" ]; then ALL_LOCKS="$json"; else ALL_LOCKS="$ALL_LOCKS, $json"; fi
}

vf_dl_status_all() {
  local ws_list p name known=" " d lp
  # depot
  vf_dl_all_add "$LOCK_ROOT/repo/DRIVER.lock" ", \"scope\": \"depot\", \"ws\": \"\", \"location\": \"$LOCATION\""
  # ancien verrou, s'il existe
  if [ "$LEGACY_PRESENT" = true ]; then
    vf_dl_all_add "$LEGACY_DIR" ", \"scope\": \"depot\", \"ws\": \"\", \"location\": \"checkout\", \"scope_reason\": \"legacy-fallback\", \"legacy_lock\": true"
  fi
  # compartiments du disque : sortie capturee en variable, jamais un pipeline vers une recherche a sortie
  # anticipee (piege P1) ; chaque nom revalide avant d'entrer dans un chemin ou le JSON
  ws_list="$(vf_ws_enumerate ".planning" 2>/dev/null)"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    name="$(basename "$p")"
    if ! vf_ws_name_valid "$name"; then ALL_SKIPPED=$((ALL_SKIPPED + 1)); continue; fi
    known="$known$name "
    vf_dl_all_add "$LOCK_ROOT/ws/$name/DRIVER.lock" ", \"scope\": \"compartiment\", \"ws\": \"$name\", \"location\": \"$LOCATION\""
  done <<EOF
$ws_list
EOF
  # verrous de compartiment presents sans dossier de compartiment sur le disque
  for d in "$LOCK_ROOT"/ws/*/; do
    [ -e "$d" ] || continue
    d="${d%/}"; name="$(basename "$d")"
    if [ -L "$d" ] || ! vf_ws_name_valid "$name"; then ALL_SKIPPED=$((ALL_SKIPPED + 1)); continue; fi
    case "$known" in *" $name "*) continue ;; esac
    lp="$d/DRIVER.lock"
    { [ -L "$lp" ] || [ -d "$lp" ]; } || continue
    vf_dl_all_add "$lp" ", \"scope\": \"compartiment\", \"ws\": \"$name\", \"location\": \"$LOCATION\"" optionnel
  done
  [ "$ALL_SKIPPED" -eq 0 ] || log "status --all : $ALL_SKIPPED nom(s) de dossier ecarte(s) (nom invalide ou lien symbolique), jamais imprime(s) dans le JSON"
  printf '{"present": %s, "scope": "lab", "location": "%s", "legacy_lock": %s, "locks": [%s], "children_running": %s}\n' \
    "$ALL_PRESENT" "$LOCATION" "$LEGACY_PRESENT" "$ALL_LOCKS" "$ALL_CHILDREN"
}

# Sonde de l'ancien verrou unique (P57-D-26), appelee en tete d'acquire en lab partitionne. Evalue
# l'ancien verrou en REUTILISANT lock_present, lock_age et meta_get dans un sous-shell qui reassigne
# LOCK_DIR/META : aucune copie de leur logique, et le shell appelant garde sa cible. Rend trois
# lignes (etat vivant|perime, age, owner) ou rien si l'ancien verrou est absent. Lecture seule :
# ni reprise, ni suppression, ni relachement.
vf_dl_legacy_probe() {
  (
    LOCK_DIR="$LEGACY_DIR"; META="$LOCK_DIR/meta"
    lock_present || exit 0
    _age="$(lock_age)"
    if [ "$_age" -le "$TTL" ]; then echo vivant; else echo perime; fi
    echo "$_age"
    sanitize_field "$(meta_get owner)"; echo
  )
}

# Refus d'acquisition devant un ancien verrou tenu (P57-D-26) : UN SEUL texte, qu'il soit rendu avant la pose ou
# apres (correction R-4, re-sonde). Argument : la sortie de vf_dl_legacy_probe (etat, age, owner). Sort en 1.
vf_dl_legacy_refuse() { # <sortie de vf_dl_legacy_probe>
  local st age owner
  st="$(printf '%s\n' "$1" | sed -n 1p)"
  age="$(printf '%s\n' "$1" | sed -n 2p)"
  owner="$(printf '%s\n' "$1" | sed -n 3p)"
  if [ "$st" = vivant ]; then
    printf '{"acquired": false, "reason": "legacy-lock-held", "held_by": "%s", "age_seconds": %s, "hint": "VF_DRIVER_LOCK=%s driver-lock.sh release --owner=%s"%s}\n' \
      "$owner" "$age" "$LEGACY_DIR" "$owner" "$SCOPE_JSON"
  else
    printf '{"acquired": false, "reason": "stale-requires-takeover", "held_by": "%s", "age_seconds": %s, "hint": "VF_DRIVER_LOCK=%s driver-lock.sh recover"%s}\n' \
      "$owner" "$age" "$LEGACY_DIR" "$SCOPE_JSON"
  fi
  exit 1
}

require_owner() {
  [ -n "$OWNER" ] || { log "--owner requis pour '$ACTION'"; printf '{"error": "owner-required"%s}\n' "$SCOPE_JSON"; exit 1; }
}

case "$ACTION" in
  acquire)
    require_owner
    # 0. ANCIEN VERROU (P57-D-26) : en lab partitionne, un .planning/DRIVER.lock tenu vaut verrou de
    #    depot, donc il refuse toute acquisition neuve, compartiment compris. Refus nomme avec la
    #    commande exacte a rejouer ; JAMAIS de reprise, de relachement ni de suppression ici. Place
    #    AVANT new_generation : un refus ne laisse aucun dechet de generation.
    if [ "$PARTITIONED" = 1 ]; then
      _leg="$(vf_dl_legacy_probe)"
      if [ -n "$_leg" ]; then
        vf_dl_legacy_refuse "$_leg"
      fi
    fi
    # 1. VOIE LIBRE — generation complete d'abord, publication par `ln -s` ensuite. `ln -s` echoue
    #    si le nom existe : c'est le primitif atomique qui departage, et il ne publie qu'un lock
    #    deja complet.
    #
    # GEL-2 (2026-08-17, amendement a D-32-02 — fermeture d'un trou de la voie LEGACY, PAS une
    # reouverture du protocole de reprise) : garde d'EXISTENCE, testee AVANT `ln_atomic`, sur
    # `lock_present()` (couvre `-L` ET `-d`, donc les deux formes). Mesure sur le script d'avant
    # cet amendement : un lock LEGACY (vrai dossier, pas un lien) frais et tenu par un autre owner
    # laissait `ln_atomic` echouer a departager — `ln -sh`/`ln -sn` ne protegent que si la cible
    # EST un lien ; sur un dossier reel, le lien candidat atterrit DEDANS (meme piege documente
    # pour `mv_link`) et la commande rend 0 — un `acquire` ordinaire rendait alors
    # `"acquired": true`, DEUX detenteurs actifs simultanement. Cette garde ne touche NI la
    # creation de generation candidate, NI le mutex de reprise, NI sa revalidation : elle ferme un
    # trou de la voie LIBRE, elle ne rouvre pas le protocole de reprise (T0, T12.2).
    gen="$(new_generation)" || { printf '{"acquired": false, "reason": "generation-failed"%s}\n' "$SCOPE_JSON"; exit 1; }
    if ! lock_present && ln_atomic "$gen" "$LOCK_DIR"; then
      # R-4 : l'ancien verrou a pu apparaitre ENTRE la sonde de l'etape 0 et la pose ci-dessus. Re-sonde apres la
      # pose ; s'il est la, on retire SA propre pose (le lien, puis sa generation) et on refuse exactement comme
      # si l'ancien verrou avait ete la avant : meme reason, meme hint, aucun champ neuf. Lab partitionne seulement.
      if [ "$PARTITIONED" = 1 ]; then
        _leg_after="$(vf_dl_legacy_probe)"
        if [ -n "$_leg_after" ]; then
          [ "$(readlink "$LOCK_DIR" 2>/dev/null)" = "$gen" ] && rm -f "$LOCK_DIR"
          rm -rf "${LOCK_PARENT:?}/${gen:?}"
          vf_dl_legacy_refuse "$_leg_after"
        fi
      fi
      _lease="$(lease_age)" && : || _lease="null"
      # orphans_count (issue #82) : un registre laisse par une mission precedente (release avec
      # enfants ouverts, ou lock elague par `recover`) est signale des l'acquisition, le nouveau
      # manager inventorie et arrete AVANT son premier dispatch (mission-flow.md §Pattern I).
      _orph="$(orphans_count)"
      [ "$_orph" -gt 0 ] && log "registre : $_orph agent(s) consigne(s) encore running avant cette acquisition. Inventorier (orphans) avant tout dispatch"
      printf '{"acquired": true, "owner": "%s", "step": "%s", "generation": "%s", "session_ids": %s, "lease_seconds": %s, "orphans_count": %s, "orphans": %s%s}\n' \
        "$OWNER" "$STEP" "$(lock_gen)" "$(json_session_ids "$(lock_session_ids)")" "$_lease" "$_orph" "$(orphans_ids_json)" "$SCOPE_JSON"
      exit 0
    fi
    # 2. OCCUPE — notre generation ne sert pas encore ; on la garde pour une eventuelle
    #    recuperation et on l'elague sur tous les chemins de sortie.
    age="$(lock_age)"; held="$(meta_get owner)"; observed_gen="$(lock_gen)"
    if [ "$age" -le "$TTL" ]; then
      rm -rf "${LOCK_PARENT:?}/$gen"
      if [ "$held" = "$OWNER" ]; then
        # meme owner : ré-acquisition idempotente (rafraichit heartbeat, maj etape si fournie)
        [ -z "$STEP" ] && STEP="$(meta_get step)"
        rewrite_meta "$(now)"
        _lease="$(lease_age)" && : || _lease="null"
        printf '{"acquired": true, "owner": "%s", "step": "%s", "reentrant": true, "generation": "%s", "session_ids": %s, "lease_seconds": %s%s}\n' \
          "$OWNER" "$STEP" "$(lock_gen)" "$(json_session_ids "$(lock_session_ids)")" "$_lease" "$SCOPE_JSON"
        exit 0
      fi
      printf '{"acquired": false, "reason": "held", "held_by": "%s", "age_seconds": %s%s}\n' "$held" "$age" "$SCOPE_JSON"
      exit 1
    fi
    # 3. PERIME (D-32-02, LOCK-04) — la reprise d'un lock perime est desormais un geste EXPLICITE,
    #    jamais un effet de bord d'une acquisition ordinaire : `acquire` REFUSE et nomme la marche
    #    a suivre (`takeover`) au lieu de voler. Ce bloc ne recupere plus rien lui-meme — la danse
    #    de mutex + double revalidation qui vivait ici a DEMENAGE, telle quelle, sous le verbe
    #    `takeover` ci-dessous.
    rm -rf "${LOCK_PARENT:?}/$gen"
    log "lock perime (age ${age}s > ${TTL}s, owner=$held) — takeover requis"
    printf '{"acquired": false, "reason": "stale-requires-takeover", "held_by": "%s", "age_seconds": %s, "hint": "driver-lock.sh takeover --owner=%s --step=<etape>%s"%s}\n' \
      "$held" "$age" "$OWNER" "$HINT_TARGET" "$SCOPE_JSON"
    exit 1
    ;;

  takeover)
    require_owner
    # ANCIEN VERROU (P57-D-26, meme regle qu'`acquire`, arbitrage Samuel, AskUserQuestion session
    # principale, 2026-10-13) : en lab partitionne, un ancien verrou tenu vaut verrou de depot, donc
    # une reprise de compartiment ne passe pas non plus. Sonde AVANT toute generation ; meme refus,
    # meme reason, meme hint (vf_dl_legacy_refuse) qu'acquire dans le meme etat : vivant, legacy-lock-held ;
    # PERIME, stale-requires-takeover avec le recover cible. Rien n'est repris ni supprime.
    if [ "$PARTITIONED" = 1 ]; then
      _leg="$(vf_dl_legacy_probe)"
      [ -n "$_leg" ] && vf_dl_legacy_refuse "$_leg"
    fi
    lock_present || { printf '{"acquired": false, "reason": "no-lock"%s}\n' "$SCOPE_JSON"; exit 1; }
    age="$(lock_age)"; held="$(meta_get owner)"; observed_gen="$(lock_gen)"
    if [ "$age" -le "$TTL" ]; then
      printf '{"acquired": false, "reason": "still-fresh", "held_by": "%s", "age_seconds": %s, "ttl": %s%s}\n' \
        "$held" "$age" "$TTL" "$SCOPE_JSON"
      exit 1
    fi
    # L'ORDRE compte : dans l'ancien bloc PERIME d'`acquire`, la generation candidate etait creee
    # AVANT de savoir si la voie etait libre (necessaire a la voie libre elle-meme). Ici, elle n'a
    # de sens qu'une fois la peremption etablie — creer d'abord et tester ensuite laisserait un
    # dechet de generation a chaque refus (still-fresh, no-lock).
    gen="$(new_generation)" || { printf '{"acquired": false, "reason": "generation-failed"%s}\n' "$SCOPE_JSON"; exit 1; }
    # DEPLACE tel quel depuis l'ancien bloc 3 « PERIME » d'`acquire` (D-32-02) — un SEUL
    # recuperateur par generation. Le mutex porte le nom de la generation observee : `ln -s`
    # echoue si un concurrent l'a deja pris, et une generation neuve donnerait un autre nom (donc
    # pas de mutex zombie qui bloquerait la suivante).
    mutex="${LOCK_DIR}.rec.$(printf '%s' "$observed_gen" | tr -c 'A-Za-z0-9._-' '_')"
    if ! ln_atomic "$$" "$mutex"; then
      rm -rf "${LOCK_PARENT:?}/$gen"
      printf '{"acquired": false, "reason": "race-during-recovery"%s}\n' "$SCOPE_JSON"; exit 1
    fi
    # BL-3 (fuite de mutex sous panne) : liberation GARANTIE, meme si ce process est tue entre la
    # prise du mutex et sa liberation normale. Aujourd'hui ce mutex est pris sur une generation
    # PERIMEE que la reprise elle-meme va DETRUIRE (une fuite ici serait indolore, elle meurt avec
    # sa cible) — mais `reclaim` reutilise EXACTEMENT ce meme patron sur une generation VIVANTE et
    # DURABLE, a CHAQUE `/clear` (le cas nominal, pas un cas rare). Sans ce `trap`, un
    # `takeover`/`reclaim` tue entre la prise du mutex et sa liberation laisse un mutex PERMANENT,
    # et tout `takeover`/`reclaim` ulterieur sur ce lock refuse pour toujours en
    # `race-during-recovery`/`race-during-reclaim` : le lock devient DEFINITIVEMENT non-reprenable.
    # Aucun `trap EXIT` n'est pose ailleurs dans ce script (verifie) : celui-ci n'en ecrase donc
    # aucun. DESARME sur CHAQUE chemin de sortie (succes, echec de revalidation, echec de bascule).
    trap 'rm -f "$mutex"' EXIT INT TERM
    # Re-verifier APRES le mutex, SUR LES DEUX CRITERES. La generation ne suffit pas : un
    # retardataire qui lit l'age AVANT le remplacement et la generation APRES obtient un mutex
    # libre (celui de la generation NEUVE) et passe le test d'egalite — il recupere alors un lock
    # frais sur la foi d'un verdict de peremption perime. C'est ce qui laissait 2 gagnants apres
    # la bascule du protocole. L'age est donc RELU ici, et c'est lui qui tranche.
    if [ "$(lock_gen)" != "$observed_gen" ] || [ "$(lock_age)" -le "$TTL" ]; then
      rm -rf "${LOCK_PARENT:?}/$gen"
      rm -f "$mutex"; trap - EXIT INT TERM
      printf '{"acquired": false, "reason": "race-during-recovery"%s}\n' "$SCOPE_JSON"; exit 1
    fi
    old_gen="$observed_gen"
    if [ -L "$LOCK_DIR" ]; then
      ln_atomic "$gen" "${LOCK_DIR}.new.$$" && mv_link "${LOCK_DIR}.new.$$" "$LOCK_DIR"
    else
      # lock legacy (dossier reel) : pas de lien a remplacer. On le met de cote (jamais supprime avant la
      # re-sonde : il est restitue si elle refuse), puis on publie.
      mv "$LOCK_DIR" "${LOCK_DIR}.old.$$" && ln_atomic "$gen" "$LOCK_DIR"
    fi
    if [ "$(lock_gen)" = "$gen" ]; then
      rm -f "${LOCK_DIR}.new.$$"
      # R-4 (meme re-sonde qu'`acquire`) : un ancien verrou, vivant OU perime, apparu ENTRE la sonde de tete
      # et la pose. On retire SA propre pose (lien puis generation) et on RESTITUE le verrou de compartiment
      # anterieur (lien vers old_gen, generation et registre intacts) : la suppression de old_gen vient
      # APRES la re-sonde, jamais avant, sinon le refus detruirait ce qu'il pretend ne pas avoir repris (AU2-04).
      # Le mutex reste tenu jusqu'a la restitution.
      if [ "$PARTITIONED" = 1 ]; then
        _tk_after="$(vf_dl_legacy_probe)"
        if [ -n "$_tk_after" ]; then
          if [ -e "${LOCK_DIR}.old.$$" ]; then
            # Dossier reel (lock legacy du compartiment) : un seul `mv -n`, apres le retrait de NOTRE lien. Si un
            # tenant concurrent a pris le nom dans l'intervalle, rien n'est ecrase et rien n'est enterre : la
            # verification ci-dessous le constate.
            rm -f "$LOCK_DIR"; mv_noclobber "${LOCK_DIR}.old.$$" "$LOCK_DIR"
          else
            ln_atomic "$old_gen" "${LOCK_DIR}.new.$$" && mv_link "${LOCK_DIR}.new.$$" "$LOCK_DIR"
            rm -f "${LOCK_DIR}.new.$$"
          fi
          # La generation posee ne se supprime QU'APRES avoir constate la restitution (lock_gen == old_gen, et plus
          # de `.old.$$`) ; sinon elle reste en place avec le dossier mis de cote, et le refus le dit (AU3-04).
          if [ "$(lock_gen)" = "$old_gen" ] && [ ! -e "${LOCK_DIR}.old.$$" ]; then
            rm -rf "${LOCK_PARENT:?}/$gen" # retire sa pose
            rm -f "$mutex"; trap - EXIT INT TERM # mutex-refus
            vf_dl_legacy_refuse "$_tk_after"
          fi
          rm -f "$mutex"; trap - EXIT INT TERM
          log "restitution du verrou anterieur impossible : generation posee et ${LOCK_DIR}.old.$$ laisses en place"
          printf '{"acquired": false, "reason": "restore-failed", "detail": "le verrou anterieur n a pas pu etre restitue ; la generation posee et son dossier mis de cote sont laisses en place"%s}\n' "$SCOPE_JSON"; exit 1
        fi
      fi
      case "$old_gen" in */*|''|legacy) ;; *) rm -rf "${LOCK_PARENT:?}/$old_gen" ;; esac
      rm -rf "${LOCK_DIR}.old.$$"
      rm -f "$mutex"; trap - EXIT INT TERM
      _lease="$(lease_age)" && : || _lease="null"
      journal_event takeover "$held" "$OWNER" "" "$age" "$(lock_gen)"
      # orphans (issue #82) : les agents consignes par le tenant mort sont rendus ICI, feuille ->
      # racine, parce que c'est le moment ou le repreneur decide de son premier dispatch.
      _orph="$(orphans_count)"
      [ "$_orph" -gt 0 ] && log "registre : $_orph agent(s) consigne(s) par l'ancien tenant encore running. Les arreter (feuille -> racine) avant tout dispatch"
      printf '{"acquired": true, "owner": "%s", "step": "%s", "recovered": true, "previous_owner": "%s", "generation": "%s", "session_ids": %s, "lease_seconds": %s, "orphans_count": %s, "orphans": %s%s}\n' \
        "$OWNER" "$STEP" "$held" "$(lock_gen)" "$(json_session_ids "$(lock_session_ids)")" "$_lease" "$_orph" "$(orphans_ids_json)" "$SCOPE_JSON"
      exit 0
    fi
    rm -f "${LOCK_DIR}.new.$$"; rm -rf "${LOCK_PARENT:?}/$gen"
    [ -e "${LOCK_DIR}.old.$$" ] && [ ! -e "$LOCK_DIR" ] && [ ! -L "$LOCK_DIR" ] && mv_noclobber "${LOCK_DIR}.old.$$" "$LOCK_DIR"
    rm -f "$mutex"; trap - EXIT INT TERM
    printf '{"acquired": false, "reason": "race-during-recovery"%s}\n' "$SCOPE_JSON"; exit 1
    ;;

  reclaim)
    require_owner
    lock_present || { printf '{"reclaimed": false, "reason": "no-lock"%s}\n' "$SCOPE_JSON"; exit 1; }
    sid="$(sanitize_session_id "${CLAUDE_CODE_SESSION_ID:-}")"
    [ -n "$sid" ] || { printf '{"reclaimed": false, "reason": "no-session-id"%s}\n' "$SCOPE_JSON"; exit 1; }
    age="$(lock_age)"; held="$(meta_get owner)"; observed_gen="$(lock_gen)"
    if [ "$age" -gt "$TTL" ]; then
      printf '{"reclaimed": false, "reason": "stale-requires-takeover"%s}\n' "$SCOPE_JSON"; exit 1
    fi
    if [ "$held" != "$OWNER" ]; then
      printf '{"reclaimed": false, "reason": "not-owner", "held_by": "%s"%s}\n' "$held" "$SCOPE_JSON"; exit 1
    fi
    # (D-32-03(f)) MEME mutex, MEME construction de nom que `takeover` — `reclaim` ne reinvente
    # PAS un patron de concurrence separe, il reutilise mot pour mot celui mesure correct.
    mutex="${LOCK_DIR}.rec.$(printf '%s' "$observed_gen" | tr -c 'A-Za-z0-9._-' '_')"
    if ! ln_atomic "$$" "$mutex"; then
      printf '{"reclaimed": false, "reason": "race-during-reclaim"%s}\n' "$SCOPE_JSON"; exit 1
    fi
    # BL-3 : MEME trap que `takeover`. C'est ICI, sur `reclaim`, que la fuite mesuree est la plus
    # grave — ce mutex se prend sur une generation VIVANTE et DURABLE (a chaque `/clear`), jamais
    # sur une generation qui va etre detruite par la reprise elle-meme. Sans ce `trap`, un
    # `reclaim` tue entre la prise du mutex et sa liberation laisse le lock DEFINITIVEMENT
    # non-reprenable (T41b) — c'est le cas NOMINAL de reclaim, pas un cas rare.
    trap 'rm -f "$mutex"' EXIT INT TERM
    # Seam de test UNIQUEMENT (QUAL-01, T41b) : un SIGTERM/SIGINT reel n'est PAS un moyen fiable
    # de prouver ce trap — bash, une fois qu'il trappe un signal, ne termine PAS le process apres
    # avoir execute le handler (verifie empiriquement : le script REPREND son execution normale
    # apres le trap, sauf si le handler appelle `exit`). Seul un veritable `exit` (ou un SIGKILL,
    # jamais trappable par construction — aucun trap ne peut jamais s'en proteger) simule "le
    # process meurt ici". Ce point d'injection, INERTE par defaut (aucun effet en usage reel), est
    # le seul moyen deterministe de prouver BL-3 sans loterie de timing sur un busy-poll.
    [ -n "${VF_DRIVER_TEST_DIE_AFTER_MUTEX:-}" ] && exit 137
    # Revalidation post-mutex sur les TROIS faits qui ont fonde la decision : generation
    # inchangee, age toujours sous le TTL, owner toujours le meme. Le controle d'owner s'ajoute a
    # la transposition exacte de la revalidation de `takeover` parce que reclaim s'applique a un
    # lock VIVANT, dont l'owner peut changer par release puis acquire pendant la fenetre.
    if [ "$(lock_gen)" != "$observed_gen" ] || [ "$(lock_age)" -gt "$TTL" ] || [ "$(meta_get owner)" != "$OWNER" ]; then
      rm -f "$mutex"; trap - EXIT INT TERM
      printf '{"reclaimed": false, "reason": "race-during-reclaim"%s}\n' "$SCOPE_JSON"; exit 1
    fi
    new_sids="$(session_ids_append "$(lock_session_ids)" "$sid")"
    hb="$(meta_get heartbeat_epoch)"
    # step preserve s'il n'est pas fourni ; heartbeat_epoch REECRIT A SA VALEUR EXISTANTE — un
    # reclaim n'est pas un battement, il ne doit pas prolonger la fraicheur du lock (T41).
    [ -z "$STEP" ] && STEP="$(meta_get step)"
    rewrite_meta "$hb" "$new_sids"
    rm -f "$mutex"; trap - EXIT INT TERM
    _lease="$(lease_age)" && : || _lease="null"
    journal_event reclaim "" "$OWNER" "$sid" "$age" "$observed_gen"
    # orphans (issue #82) : un reclaim est le geste d'une reprise de session, donc le manager qui
    # revient (ou son remplacant, meme owner) voit d'un coup ce qui tourne encore en son nom.
    _orph="$(orphans_count)"
    [ "$_orph" -gt 0 ] && log "registre : $_orph agent(s) consigne(s) encore running sous ce lock. Verifier ListAgents, arreter feuille -> racine, puis close --status=stopped"
    printf '{"reclaimed": true, "owner": "%s", "session_id": "%s", "session_ids": %s, "generation": "%s", "lease_seconds": %s, "orphans_count": %s, "orphans": %s%s}\n' \
      "$OWNER" "$sid" "$(json_session_ids "$(lock_session_ids)")" "$(lock_gen)" "$_lease" "$_orph" "$(orphans_ids_json)" "$SCOPE_JSON"
    exit 0
    ;;

  heartbeat)
    require_owner
    lock_present || { printf '{"ok": false, "reason": "no-lock"%s}\n' "$SCOPE_JSON"; exit 1; }
    if [ "$(meta_get owner)" = "$OWNER" ]; then
      # rafraichit l'horodatage (maj step si --step fourni) — un seul ts pour meta + rapport
      [ -z "$STEP" ] && STEP="$(meta_get step)"
      ts="$(now)"
      rewrite_meta "$ts"
      printf '{"ok": true, "owner": "%s", "heartbeat_epoch": %s%s}\n' "$OWNER" "$ts" "$SCOPE_JSON"
      exit 0
    fi
    printf '{"ok": false, "reason": "not-owner", "held_by": "%s"%s}\n' "$(meta_get owner)" "$SCOPE_JSON"; exit 1
    ;;

  mark-progress)
    require_owner
    lock_present || { printf '{"ok": false, "reason": "no-lock"%s}\n' "$SCOPE_JSON"; exit 1; }
    if [ "$(meta_get owner)" = "$OWNER" ]; then
      # (D-33-A) Garde OBLIGATOIRE, EXACTEMENT le meme patron que heartbeat/reclaim ci-dessus :
      # mark-progress n'a PAS de flag --step=, donc $STEP est TOUJOURS vide a ce point. Sans cette
      # ligne, rewrite_meta() reemettrait 'step=' VIDE (elle reecrit step depuis la globale $STEP,
      # jamais depuis le fichier — le seul champ de rewrite_meta() sans repli sur meta_get) et
      # effacerait le step au premier appel.
      [ -z "$STEP" ] && STEP="$(meta_get step)"
      ts="$(now)"
      # Les deux premiers arguments sont RELUS du fichier, INCHANGES — c'est cette ligne, et elle
      # seule, qui garantit que heartbeat_epoch ne bouge JAMAIS sous mark-progress. Le 3e argument
      # ($ts) est le SEUL champ que ce verbe avance.
      rewrite_meta "$(meta_get heartbeat_epoch)" "$(lock_session_ids)" "$ts"
      printf '{"ok": true, "owner": "%s", "progress_epoch": %s%s}\n' "$OWNER" "$ts" "$SCOPE_JSON"
      exit 0
    fi
    printf '{"ok": false, "reason": "not-owner", "held_by": "%s"%s}\n' "$(meta_get owner)" "$SCOPE_JSON"; exit 1
    ;;

  release)
    require_owner
    lock_present || { printf '{"released": false, "reason": "no-lock"%s}\n' "$SCOPE_JSON"; exit 0; }
    held="$(meta_get owner)"
    if [ "$held" = "$OWNER" ]; then
      drop_lock
      # Registre (issue #82) : un release avec des enfants consignes encore `running` RELACHE quand
      # meme (geste RAII, jamais conditionnel) mais garde le registre et le dit, c'est le cas
      # « manager termine, enfant jamais ferme » ; le gate de sortie le lit via status. Sans enfant
      # ouvert, le registre est supprime : la mission est close proprement, rien a retrouver.
      _orph="$(orphans_count)"
      if [ "$_orph" -gt 0 ]; then
        log "release avec $_orph agent(s) consigne(s) encore running : registre conserve ($REG), a inventorier (orphans)"
        printf '{"released": true, "owner": "%s", "children_running": %s, "orphans": %s%s}\n' "$OWNER" "$_orph" "$(orphans_ids_json)" "$SCOPE_JSON"
      else
        rm -f "$REG"
        printf '{"released": true, "owner": "%s", "children_running": 0%s}\n' "$OWNER" "$SCOPE_JSON"
      fi
      exit 0
    fi
    printf '{"released": false, "reason": "not-owner", "held_by": "%s"%s}\n' "$held" "$SCOPE_JSON"; exit 1
    ;;

  status)
    if [ "$ALL" = 1 ] && [ "$PARTITIONED" = 1 ]; then vf_dl_status_all; exit 0; fi
    lock_present && json_status true || json_status false
    exit 0
    ;;

  recover)
    lock_present || { printf '{"recovered": false, "reason": "no-lock"%s}\n' "$SCOPE_JSON"; exit 0; }
    age="$(lock_age)"; held="$(meta_get owner)"
    if [ "$age" -gt "$TTL" ]; then
      observed_gen="$(lock_gen)"
      mutex="${LOCK_DIR}.rec.$(printf '%s' "$observed_gen" | tr -c 'A-Za-z0-9._-' '_')"
      if ! ln_atomic "$$" "$mutex"; then
        printf '{"recovered": false, "reason": "race-during-recovery"%s}\n' "$SCOPE_JSON"; exit 1
      fi
      # BL-3 (correction juge #2, meme patron EXACT que takeover et reclaim) : `recover` prend le
      # MEME mutex, sur la MEME construction de nom, dans le MEME espace de noms que les deux
      # autres verbes de reprise — sans ce trap, un `recover` tue entre la prise du mutex et sa
      # liberation normale laisse un mutex PERMANENT, et tout `takeover`/`reclaim` ULTERIEUR sur ce
      # lock refuse pour toujours en race-during-recovery : le lock devient DEFINITIVEMENT non
      # reprenable par les verbes du script — precisement le mode de defaillance que ce lot dit
      # avoir ferme, laisse ouvert sur ce troisieme verbe. Meme seam de test que reclaim
      # (VF_DRIVER_TEST_DIE_AFTER_MUTEX, T41b) et meme raison : un signal reel n'est pas fiable ici
      # (bash REPREND son execution apres un trap de signal, seul un `exit` reel simule la mort).
      trap 'rm -f "$mutex"' EXIT INT TERM
      [ -n "${VF_DRIVER_TEST_DIE_AFTER_MUTEX:-}" ] && exit 137
      if [ "$(lock_gen)" != "$observed_gen" ] || [ "$(lock_age)" -le "$TTL" ]; then
        rm -f "$mutex"; trap - EXIT INT TERM
        printf '{"recovered": false, "reason": "race-during-recovery"%s}\n' "$SCOPE_JSON"; exit 1
      fi
      drop_lock; rm -f "$mutex"; trap - EXIT INT TERM
      # (correction juge #7) new_owner/session_id journalises quand CONNUS : `recover` n'exige pas
      # --owner (elagage anonyme reste possible, comportement inchange) mais si l'appelant en passe
      # un, la chaine "perime -> elague -> repris" ne perd plus l'identite du repreneur. L'`acquire`
      # qui suit reste un evenement SEPARE, non journalise ici par construction (le journal ne
      # couvre QUE les TROIS natures de reprise — takeover/reclaim/recover — jamais l'acquisition
      # ordinaire, meme apres un takeover : voir le docstring de journal_event ci-dessus).
      journal_event recover "$held" "$OWNER" "$(sanitize_session_id "${CLAUDE_CODE_SESSION_ID:-}")" "$age" "$observed_gen"
      printf '{"recovered": true, "previous_owner": "%s", "age_seconds": %s%s}\n' "$held" "$age" "$SCOPE_JSON"; exit 0
    fi
    printf '{"recovered": false, "reason": "still-fresh", "age_seconds": %s, "ttl": %s%s}\n' "$age" "$TTL" "$SCOPE_JSON"
    exit 1
    ;;

  register)
    # Consigne un dispatch (issue #82). Aucune condition sur le lock : un worker qui dispatche une
    # brique GSD ne tient pas le lock et ne connait pas forcement son owner, il consigne quand
    # meme, c'est tout l'objet. owner/generation sont RELEVES sur le lock courant s'il existe
    # (sauf --owner explicite), pour que l'inventaire puisse dire « consigne sous quel mandat ».
    AGENT="$(sanitize_session_id "$AGENT")"
    [ -n "$AGENT" ] || { log "--agent requis pour 'register'"; printf '{"registered": false, "reason": "agent-required"%s}\n' "$SCOPE_JSON"; exit 1; }
    ROLE="$(sanitize_reg_field "$ROLE")"
    [ -n "$ROLE" ] || { log "--role requis pour 'register'"; printf '{"registered": false, "reason": "role-required"%s}\n' "$SCOPE_JSON"; exit 1; }
    NODE="$(sanitize_reg_field "$NODE")"; PARENT="$(sanitize_session_id "$PARENT")"
    case "$DEPTH" in ''|*[!0-9]*) DEPTH="" ;; esac
    _reg_owner="$OWNER"; _reg_gen=""
    if lock_present; then
      [ -n "$_reg_owner" ] || _reg_owner="$(meta_get owner)"
      _reg_gen="$(lock_gen)"
    fi
    _reg_gen="$(printf '%s' "$_reg_gen" | tr -dc 'A-Za-z0-9._-')"
    mkdir -p "$LOCK_PARENT" 2>/dev/null || true
    # depth n'est ecrit que s'il est explicite : absent, registry_fold le derive de la chaine parent.
    _depth_field=""; [ -n "$DEPTH" ] && _depth_field=", \"depth\": $DEPTH"
    if ! printf '{"event": "register", "agent_id": "%s", "parent": "%s", "role": "%s", "node": "%s", "owner": "%s", "generation": "%s", "status": "running", "dispatched_at": "%s", "epoch": %s%s}\n' \
        "$AGENT" "$PARENT" "$ROLE" "$NODE" "$_reg_owner" "$_reg_gen" "$(iso)" "$(now)" "$_depth_field" >> "$REG" 2>/dev/null; then
      # BRUYANT et non nul, a l'inverse du journal des reprises : un dispatch non consigne est
      # precisement l'orphelin introuvable que ce registre existe pour empecher.
      log "registre inaccessible en ecriture ($REG) : dispatch NON consigne"
      printf '{"registered": false, "reason": "registry-unwritable", "registry": "%s"%s}\n' "$REG" "$SCOPE_JSON"; exit 1
    fi
    printf '{"registered": true, "agent_id": "%s", "role": "%s", "node": "%s", "parent": "%s", "owner": "%s", "registry": "%s"%s}\n' \
      "$AGENT" "$ROLE" "$NODE" "$PARENT" "$_reg_owner" "$REG" "$SCOPE_JSON"
    exit 0
    ;;

  close)
    # Ferme une entree par APPEND (jamais une reecriture du registre) : `done`/`failed` au retour
    # normal d'un agent, `stopped` apres un arret verifie par ListAgents (jamais sur la seule
    # reponse de TaskStop, qui peut etre sans effet immediat).
    AGENT="$(sanitize_session_id "$AGENT")"
    [ -n "$AGENT" ] || { log "--agent requis pour 'close'"; printf '{"closed": false, "reason": "agent-required"%s}\n' "$SCOPE_JSON"; exit 1; }
    case "$CSTATUS" in
      done|failed|stopped) ;;
      *) log "--status attendu parmi done|failed|stopped pour 'close'"; printf '{"closed": false, "reason": "invalid-status", "status": "%s"%s}\n' "$(sanitize_reg_field "$CSTATUS")" "$SCOPE_JSON"; exit 1 ;;
    esac
    [ -f "$REG" ] || { printf '{"closed": false, "reason": "no-registry"%s}\n' "$SCOPE_JSON"; exit 1; }
    _known="$(registry_fold | awk -F'\t' -v a="$AGENT" '$1 == a { print $10; exit }')"
    [ -n "$_known" ] || { printf '{"closed": false, "reason": "unknown-agent", "agent_id": "%s"%s}\n' "$AGENT" "$SCOPE_JSON"; exit 1; }
    if ! printf '{"event": "close", "agent_id": "%s", "status": "%s", "closed_at": "%s", "epoch": %s}\n' \
        "$AGENT" "$CSTATUS" "$(iso)" "$(now)" >> "$REG" 2>/dev/null; then
      log "registre inaccessible en ecriture ($REG) : fermeture NON consignee"
      printf '{"closed": false, "reason": "registry-unwritable", "registry": "%s"%s}\n' "$REG" "$SCOPE_JSON"; exit 1
    fi
    # children_running : ce que ce parent laisse derriere lui. Un parent ferme avec un enfant
    # encore running est le motif exact du reveil d'un parent « completed » (issue #82, cas 2 et 3).
    _kids="$(children_running_of_json "$AGENT")"
    [ "$_kids" != "[]" ] && log "close $AGENT : des enfants consignes tournent encore ($_kids). Les fermer ou les arreter, sinon ils restent orphelins"
    printf '{"closed": true, "agent_id": "%s", "status": "%s", "previous_status": "%s", "children_running": %s%s}\n' \
      "$AGENT" "$CSTATUS" "$_known" "$_kids" "$SCOPE_JSON"
    exit 0
    ;;

  orphans)
    # Lecture seule, exit 0 dans tous les cas (registre absent compris) : c'est un inventaire, pas
    # un verdict. Ordre FEUILLE -> RACINE, l'ordre d'arret impose par la reprise.
    if [ -f "$REG" ]; then
      printf '{"present": true, "registry": "%s", "count": %s, "orphans": %s%s}\n' "$REG" "$(orphans_count)" "$(orphans_json)" "$SCOPE_JSON"
    else
      printf '{"present": false, "registry": "%s", "count": 0, "orphans": []%s}\n' "$REG" "$SCOPE_JSON"
    fi
    exit 0
    ;;

  *)
    echo "Usage: $0 {acquire|takeover|reclaim|heartbeat|mark-progress|release|status|recover|register|close|orphans} [--owner=ID] [--step=X] [--agent=ID] [--role=R] [--node=N] [--parent=ID] [--depth=D] [--status=S]" >&2
    exit 1
    ;;
esac
