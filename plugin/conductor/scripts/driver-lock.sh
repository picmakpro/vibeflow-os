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
#   driver-lock.sh takeover  --owner=<id> [--step=<etape>] # reprend un lock PERIME (geste explicite)
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

set -uo pipefail

LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"
TTL="${VF_DRIVER_TTL:-1800}"
META="$LOCK_DIR/meta"
case "$TTL" in ''|*[!0-9]*) TTL=1800 ;; esac  # garde : TTL non numerique -> defaut (L3)
SESSION_MAX="${VF_DRIVER_SESSION_MAX:-8}"
case "$SESSION_MAX" in ''|*[!0-9]*) SESSION_MAX=8 ;; esac  # meme garde que TTL (D-32-03, plafond LRU)

ACTION=""; OWNER=""; STEP=""
AGENT=""; ROLE=""; NODE=""; PARENT=""; DEPTH=""; CSTATUS=""
for arg in "$@"; do
  case "$arg" in
    acquire|heartbeat|release|status|recover|takeover|reclaim|mark-progress|register|close|orphans) ACTION="$arg" ;;
    --owner=*)  OWNER="${arg#*=}" ;;
    --step=*)   STEP="${arg#*=}" ;;
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

LOCK_PARENT="$(dirname "$LOCK_DIR")"
LOCK_BASE="$(basename "$LOCK_DIR")"

# Remplacement ATOMIQUE d'un lien : rename(2) par-dessus le lien existant. Sans option, `mv`
# SUIT un lien vers un dossier et deplace la source DEDANS (verifie sur ce poste) — le lock
# serait alors intact et le nouveau claim invisible. BSD/macOS : -h ; GNU/Linux : -T.
mv_link() {
  mv -h "$1" "$2" 2>/dev/null || mv -T "$1" "$2" 2>/dev/null
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
REG="${VF_DRIVER_CHILDREN:-$LOCK_PARENT/${LOCK_BASE}.children.jsonl}"
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
    printf '{"present": false, "lock": "%s", "children_running": %s}\n' "$LOCK_DIR" "$children"; return
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
  printf '{"present": true, "owner": "%s", "step": "%s", "age_seconds": %s, "ttl": %s, "stale": %s, "generation": "%s", "session_ids": %s, "lease_seconds": %s, "guard_effective": %s, "progress_epoch": %s, "progress_age_seconds": %s, "children_running": %s}\n' \
    "$o" "$s" "$age" "$TTL" "$stale" "$gen" "$sids" "$lease" "$guard_eff" "$pe" "$page" "$children"
}

require_owner() {
  [ -n "$OWNER" ] || { log "--owner requis pour '$ACTION'"; echo '{"error": "owner-required"}'; exit 1; }
}

case "$ACTION" in
  acquire)
    require_owner
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
    gen="$(new_generation)" || { echo '{"acquired": false, "reason": "generation-failed"}'; exit 1; }
    if ! lock_present && ln_atomic "$gen" "$LOCK_DIR"; then
      _lease="$(lease_age)" && : || _lease="null"
      # orphans_count (issue #82) : un registre laisse par une mission precedente (release avec
      # enfants ouverts, ou lock elague par `recover`) est signale des l'acquisition, le nouveau
      # manager inventorie et arrete AVANT son premier dispatch (mission-flow.md §Pattern I).
      _orph="$(orphans_count)"
      [ "$_orph" -gt 0 ] && log "registre : $_orph agent(s) consigne(s) encore running avant cette acquisition. Inventorier (orphans) avant tout dispatch"
      printf '{"acquired": true, "owner": "%s", "step": "%s", "generation": "%s", "session_ids": %s, "lease_seconds": %s, "orphans_count": %s, "orphans": %s}\n' \
        "$OWNER" "$STEP" "$(lock_gen)" "$(json_session_ids "$(lock_session_ids)")" "$_lease" "$_orph" "$(orphans_ids_json)"
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
        printf '{"acquired": true, "owner": "%s", "step": "%s", "reentrant": true, "generation": "%s", "session_ids": %s, "lease_seconds": %s}\n' \
          "$OWNER" "$STEP" "$(lock_gen)" "$(json_session_ids "$(lock_session_ids)")" "$_lease"
        exit 0
      fi
      printf '{"acquired": false, "reason": "held", "held_by": "%s", "age_seconds": %s}\n' "$held" "$age"
      exit 1
    fi
    # 3. PERIME (D-32-02, LOCK-04) — la reprise d'un lock perime est desormais un geste EXPLICITE,
    #    jamais un effet de bord d'une acquisition ordinaire : `acquire` REFUSE et nomme la marche
    #    a suivre (`takeover`) au lieu de voler. Ce bloc ne recupere plus rien lui-meme — la danse
    #    de mutex + double revalidation qui vivait ici a DEMENAGE, telle quelle, sous le verbe
    #    `takeover` ci-dessous.
    rm -rf "${LOCK_PARENT:?}/$gen"
    log "lock perime (age ${age}s > ${TTL}s, owner=$held) — takeover requis"
    printf '{"acquired": false, "reason": "stale-requires-takeover", "held_by": "%s", "age_seconds": %s, "hint": "driver-lock.sh takeover --owner=%s --step=<etape>"}\n' \
      "$held" "$age" "$OWNER"
    exit 1
    ;;

  takeover)
    require_owner
    lock_present || { echo '{"acquired": false, "reason": "no-lock"}'; exit 1; }
    age="$(lock_age)"; held="$(meta_get owner)"; observed_gen="$(lock_gen)"
    if [ "$age" -le "$TTL" ]; then
      printf '{"acquired": false, "reason": "still-fresh", "held_by": "%s", "age_seconds": %s, "ttl": %s}\n' \
        "$held" "$age" "$TTL"
      exit 1
    fi
    # L'ORDRE compte : dans l'ancien bloc PERIME d'`acquire`, la generation candidate etait creee
    # AVANT de savoir si la voie etait libre (necessaire a la voie libre elle-meme). Ici, elle n'a
    # de sens qu'une fois la peremption etablie — creer d'abord et tester ensuite laisserait un
    # dechet de generation a chaque refus (still-fresh, no-lock).
    gen="$(new_generation)" || { echo '{"acquired": false, "reason": "generation-failed"}'; exit 1; }
    # DEPLACE tel quel depuis l'ancien bloc 3 « PERIME » d'`acquire` (D-32-02) — un SEUL
    # recuperateur par generation. Le mutex porte le nom de la generation observee : `ln -s`
    # echoue si un concurrent l'a deja pris, et une generation neuve donnerait un autre nom (donc
    # pas de mutex zombie qui bloquerait la suivante).
    mutex="${LOCK_DIR}.rec.$(printf '%s' "$observed_gen" | tr -c 'A-Za-z0-9._-' '_')"
    if ! ln_atomic "$$" "$mutex"; then
      rm -rf "${LOCK_PARENT:?}/$gen"
      printf '{"acquired": false, "reason": "race-during-recovery"}\n'; exit 1
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
      printf '{"acquired": false, "reason": "race-during-recovery"}\n'; exit 1
    fi
    old_gen="$observed_gen"
    if [ -L "$LOCK_DIR" ]; then
      ln_atomic "$gen" "${LOCK_DIR}.new.$$" && mv_link "${LOCK_DIR}.new.$$" "$LOCK_DIR"
    else
      # lock legacy (dossier reel) : pas de lien a remplacer, on elague puis on publie.
      rm -rf "$LOCK_DIR" && ln_atomic "$gen" "$LOCK_DIR"
    fi
    if [ "$(lock_gen)" = "$gen" ]; then
      rm -f "${LOCK_DIR}.new.$$"
      case "$old_gen" in */*|''|legacy) ;; *) rm -rf "${LOCK_PARENT:?}/$old_gen" ;; esac
      rm -f "$mutex"; trap - EXIT INT TERM
      _lease="$(lease_age)" && : || _lease="null"
      journal_event takeover "$held" "$OWNER" "" "$age" "$(lock_gen)"
      # orphans (issue #82) : les agents consignes par le tenant mort sont rendus ICI, feuille ->
      # racine, parce que c'est le moment ou le repreneur decide de son premier dispatch.
      _orph="$(orphans_count)"
      [ "$_orph" -gt 0 ] && log "registre : $_orph agent(s) consigne(s) par l'ancien tenant encore running. Les arreter (feuille -> racine) avant tout dispatch"
      printf '{"acquired": true, "owner": "%s", "step": "%s", "recovered": true, "previous_owner": "%s", "generation": "%s", "session_ids": %s, "lease_seconds": %s, "orphans_count": %s, "orphans": %s}\n' \
        "$OWNER" "$STEP" "$held" "$(lock_gen)" "$(json_session_ids "$(lock_session_ids)")" "$_lease" "$_orph" "$(orphans_ids_json)"
      exit 0
    fi
    rm -f "${LOCK_DIR}.new.$$"; rm -rf "${LOCK_PARENT:?}/$gen"
    rm -f "$mutex"; trap - EXIT INT TERM
    printf '{"acquired": false, "reason": "race-during-recovery"}\n'; exit 1
    ;;

  reclaim)
    require_owner
    lock_present || { echo '{"reclaimed": false, "reason": "no-lock"}'; exit 1; }
    sid="$(sanitize_session_id "${CLAUDE_CODE_SESSION_ID:-}")"
    [ -n "$sid" ] || { echo '{"reclaimed": false, "reason": "no-session-id"}'; exit 1; }
    age="$(lock_age)"; held="$(meta_get owner)"; observed_gen="$(lock_gen)"
    if [ "$age" -gt "$TTL" ]; then
      echo '{"reclaimed": false, "reason": "stale-requires-takeover"}'; exit 1
    fi
    if [ "$held" != "$OWNER" ]; then
      printf '{"reclaimed": false, "reason": "not-owner", "held_by": "%s"}\n' "$held"; exit 1
    fi
    # (D-32-03(f)) MEME mutex, MEME construction de nom que `takeover` — `reclaim` ne reinvente
    # PAS un patron de concurrence separe, il reutilise mot pour mot celui mesure correct.
    mutex="${LOCK_DIR}.rec.$(printf '%s' "$observed_gen" | tr -c 'A-Za-z0-9._-' '_')"
    if ! ln_atomic "$$" "$mutex"; then
      echo '{"reclaimed": false, "reason": "race-during-reclaim"}'; exit 1
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
      echo '{"reclaimed": false, "reason": "race-during-reclaim"}'; exit 1
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
    printf '{"reclaimed": true, "owner": "%s", "session_id": "%s", "session_ids": %s, "generation": "%s", "lease_seconds": %s, "orphans_count": %s, "orphans": %s}\n' \
      "$OWNER" "$sid" "$(json_session_ids "$(lock_session_ids)")" "$(lock_gen)" "$_lease" "$_orph" "$(orphans_ids_json)"
    exit 0
    ;;

  heartbeat)
    require_owner
    lock_present || { echo '{"ok": false, "reason": "no-lock"}'; exit 1; }
    if [ "$(meta_get owner)" = "$OWNER" ]; then
      # rafraichit l'horodatage (maj step si --step fourni) — un seul ts pour meta + rapport
      [ -z "$STEP" ] && STEP="$(meta_get step)"
      ts="$(now)"
      rewrite_meta "$ts"
      printf '{"ok": true, "owner": "%s", "heartbeat_epoch": %s}\n' "$OWNER" "$ts"
      exit 0
    fi
    printf '{"ok": false, "reason": "not-owner", "held_by": "%s"}\n' "$(meta_get owner)"; exit 1
    ;;

  mark-progress)
    require_owner
    lock_present || { echo '{"ok": false, "reason": "no-lock"}'; exit 1; }
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
      printf '{"ok": true, "owner": "%s", "progress_epoch": %s}\n' "$OWNER" "$ts"
      exit 0
    fi
    printf '{"ok": false, "reason": "not-owner", "held_by": "%s"}\n' "$(meta_get owner)"; exit 1
    ;;

  release)
    require_owner
    lock_present || { echo '{"released": false, "reason": "no-lock"}'; exit 0; }
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
        printf '{"released": true, "owner": "%s", "children_running": %s, "orphans": %s}\n' "$OWNER" "$_orph" "$(orphans_ids_json)"
      else
        rm -f "$REG"
        printf '{"released": true, "owner": "%s", "children_running": 0}\n' "$OWNER"
      fi
      exit 0
    fi
    printf '{"released": false, "reason": "not-owner", "held_by": "%s"}\n' "$held"; exit 1
    ;;

  status)
    lock_present && json_status true || json_status false
    exit 0
    ;;

  recover)
    lock_present || { echo '{"recovered": false, "reason": "no-lock"}'; exit 0; }
    age="$(lock_age)"; held="$(meta_get owner)"
    if [ "$age" -gt "$TTL" ]; then
      observed_gen="$(lock_gen)"
      mutex="${LOCK_DIR}.rec.$(printf '%s' "$observed_gen" | tr -c 'A-Za-z0-9._-' '_')"
      if ! ln_atomic "$$" "$mutex"; then
        printf '{"recovered": false, "reason": "race-during-recovery"}\n'; exit 1
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
        printf '{"recovered": false, "reason": "race-during-recovery"}\n'; exit 1
      fi
      drop_lock; rm -f "$mutex"; trap - EXIT INT TERM
      # (correction juge #7) new_owner/session_id journalises quand CONNUS : `recover` n'exige pas
      # --owner (elagage anonyme reste possible, comportement inchange) mais si l'appelant en passe
      # un, la chaine "perime -> elague -> repris" ne perd plus l'identite du repreneur. L'`acquire`
      # qui suit reste un evenement SEPARE, non journalise ici par construction (le journal ne
      # couvre QUE les TROIS natures de reprise — takeover/reclaim/recover — jamais l'acquisition
      # ordinaire, meme apres un takeover : voir le docstring de journal_event ci-dessus).
      journal_event recover "$held" "$OWNER" "$(sanitize_session_id "${CLAUDE_CODE_SESSION_ID:-}")" "$age" "$observed_gen"
      printf '{"recovered": true, "previous_owner": "%s", "age_seconds": %s}\n' "$held" "$age"; exit 0
    fi
    printf '{"recovered": false, "reason": "still-fresh", "age_seconds": %s, "ttl": %s}\n' "$age" "$TTL"
    exit 1
    ;;

  register)
    # Consigne un dispatch (issue #82). Aucune condition sur le lock : un worker qui dispatche une
    # brique GSD ne tient pas le lock et ne connait pas forcement son owner, il consigne quand
    # meme, c'est tout l'objet. owner/generation sont RELEVES sur le lock courant s'il existe
    # (sauf --owner explicite), pour que l'inventaire puisse dire « consigne sous quel mandat ».
    AGENT="$(sanitize_session_id "$AGENT")"
    [ -n "$AGENT" ] || { log "--agent requis pour 'register'"; echo '{"registered": false, "reason": "agent-required"}'; exit 1; }
    ROLE="$(sanitize_reg_field "$ROLE")"
    [ -n "$ROLE" ] || { log "--role requis pour 'register'"; echo '{"registered": false, "reason": "role-required"}'; exit 1; }
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
      printf '{"registered": false, "reason": "registry-unwritable", "registry": "%s"}\n' "$REG"; exit 1
    fi
    printf '{"registered": true, "agent_id": "%s", "role": "%s", "node": "%s", "parent": "%s", "owner": "%s", "registry": "%s"}\n' \
      "$AGENT" "$ROLE" "$NODE" "$PARENT" "$_reg_owner" "$REG"
    exit 0
    ;;

  close)
    # Ferme une entree par APPEND (jamais une reecriture du registre) : `done`/`failed` au retour
    # normal d'un agent, `stopped` apres un arret verifie par ListAgents (jamais sur la seule
    # reponse de TaskStop, qui peut etre sans effet immediat).
    AGENT="$(sanitize_session_id "$AGENT")"
    [ -n "$AGENT" ] || { log "--agent requis pour 'close'"; echo '{"closed": false, "reason": "agent-required"}'; exit 1; }
    case "$CSTATUS" in
      done|failed|stopped) ;;
      *) log "--status attendu parmi done|failed|stopped pour 'close'"; printf '{"closed": false, "reason": "invalid-status", "status": "%s"}\n' "$(sanitize_reg_field "$CSTATUS")"; exit 1 ;;
    esac
    [ -f "$REG" ] || { echo '{"closed": false, "reason": "no-registry"}'; exit 1; }
    _known="$(registry_fold | awk -F'\t' -v a="$AGENT" '$1 == a { print $10; exit }')"
    [ -n "$_known" ] || { printf '{"closed": false, "reason": "unknown-agent", "agent_id": "%s"}\n' "$AGENT"; exit 1; }
    if ! printf '{"event": "close", "agent_id": "%s", "status": "%s", "closed_at": "%s", "epoch": %s}\n' \
        "$AGENT" "$CSTATUS" "$(iso)" "$(now)" >> "$REG" 2>/dev/null; then
      log "registre inaccessible en ecriture ($REG) : fermeture NON consignee"
      printf '{"closed": false, "reason": "registry-unwritable", "registry": "%s"}\n' "$REG"; exit 1
    fi
    # children_running : ce que ce parent laisse derriere lui. Un parent ferme avec un enfant
    # encore running est le motif exact du reveil d'un parent « completed » (issue #82, cas 2 et 3).
    _kids="$(children_running_of_json "$AGENT")"
    [ "$_kids" != "[]" ] && log "close $AGENT : des enfants consignes tournent encore ($_kids). Les fermer ou les arreter, sinon ils restent orphelins"
    printf '{"closed": true, "agent_id": "%s", "status": "%s", "previous_status": "%s", "children_running": %s}\n' \
      "$AGENT" "$CSTATUS" "$_known" "$_kids"
    exit 0
    ;;

  orphans)
    # Lecture seule, exit 0 dans tous les cas (registre absent compris) : c'est un inventaire, pas
    # un verdict. Ordre FEUILLE -> RACINE, l'ordre d'arret impose par la reprise.
    if [ -f "$REG" ]; then
      printf '{"present": true, "registry": "%s", "count": %s, "orphans": %s}\n' "$REG" "$(orphans_count)" "$(orphans_json)"
    else
      printf '{"present": false, "registry": "%s", "count": 0, "orphans": []}\n' "$REG"
    fi
    exit 0
    ;;

  *)
    echo "Usage: $0 {acquire|takeover|reclaim|heartbeat|mark-progress|release|status|recover|register|close|orphans} [--owner=ID] [--step=X] [--agent=ID] [--role=R] [--node=N] [--parent=ID] [--depth=D] [--status=S]" >&2
    exit 1
    ;;
esac
