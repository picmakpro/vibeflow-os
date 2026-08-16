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
#   driver-lock.sh acquire   --owner=<id> --step=<etape>   # pose le lock (ou le recupere si perime)
#   driver-lock.sh heartbeat --owner=<id> [--step=<etape>] # rafraichit le heartbeat entre etapes
#   driver-lock.sh release   --owner=<id>                  # relache (clôture RAII : succes/echec/abandon)
#   driver-lock.sh status                                  # etat courant (JSON)
#   driver-lock.sh recover                                 # elague un lock perime (sinon refuse)
#
# Sortie : JSON une ligne (parsing). Exit 0 = action reussie ; exit 1 = refus (lock tenu, pas owner…).
#
# Variables : VF_DRIVER_LOCK (defaut .planning/DRIVER.lock), VF_DRIVER_TTL (defaut 1800 s).
# Reference : ADR-053 + .planning/phases/VFDO-09-*/09-CADRAGE-swarm.md §2.

set -uo pipefail

LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"
TTL="${VF_DRIVER_TTL:-1800}"
META="$LOCK_DIR/meta"
case "$TTL" in ''|*[!0-9]*) TTL=1800 ;; esac  # garde : TTL non numerique -> defaut (L3)

ACTION=""; OWNER=""; STEP=""
for arg in "$@"; do
  case "$arg" in
    acquire|heartbeat|release|status|recover) ACTION="$arg" ;;
    --owner=*) OWNER="${arg#*=}" ;;
    --step=*)  STEP="${arg#*=}" ;;
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
  } > "$LOCK_PARENT/$gen/meta" || { rm -rf "$LOCK_PARENT/$gen"; return 1; }
  echo "$gen"
}

# Reecrit le meta de la generation COURANTE en place (heartbeat, re-acquisition du meme owner).
# Le lien ne bouge pas : rien a serialiser, l'owner est deja etabli.
rewrite_meta() {
  local ap ai br wt si
  ap="$(meta_get acquired_epoch)"; ai="$(meta_get acquired_iso)"
  br="$(meta_get branch)"; wt="$(meta_get worktree)"
  # session_ids est LU depuis le meta courant, JAMAIS depuis l'environnement de la session qui
  # appelle rewrite_meta — c'est ce qui fait qu'un heartbeat emis d'un autre contexte (ADR-064,
  # meme patron que branch/worktree ci-dessus) ne peut jamais reecrire l'identite du detenteur.
  si="$(lock_session_ids)"
  {
    printf 'owner=%s\n'           "$(printf '%s' "$OWNER" | tr -d '\n')"
    printf 'step=%s\n'            "$(printf '%s' "$STEP"  | tr -d '\n')"
    printf 'branch=%s\n'          "$br"
    printf 'worktree=%s\n'        "$wt"
    printf 'session_ids=%s\n'     "$si"
    printf 'acquired_epoch=%s\n'  "$ap"
    printf 'acquired_iso=%s\n'    "$ai"
    printf 'heartbeat_epoch=%s\n' "$1"
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

json_status() {
  if [ "$1" = false ]; then
    printf '{"present": false, "lock": "%s"}\n' "$LOCK_DIR"; return
  fi
  local o s age stale gen sids lease
  o="$(meta_get owner)"; s="$(meta_get step)"; age="$(lock_age)"
  [ "$age" -gt "$TTL" ] && stale=true || stale=false
  gen="$(lock_gen)"; sids="$(json_session_ids "$(lock_session_ids)")"
  lease="$(lease_age)" && : || lease="null"  # lease_age() echoue -> null JSON, jamais un 0 trompeur
  printf '{"present": true, "owner": "%s", "step": "%s", "age_seconds": %s, "ttl": %s, "stale": %s, "generation": "%s", "session_ids": %s, "lease_seconds": %s}\n' \
    "$o" "$s" "$age" "$TTL" "$stale" "$gen" "$sids" "$lease"
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
    gen="$(new_generation)" || { echo '{"acquired": false, "reason": "generation-failed"}'; exit 1; }
    if ln_atomic "$gen" "$LOCK_DIR"; then
      _lease="$(lease_age)" && : || _lease="null"
      printf '{"acquired": true, "owner": "%s", "step": "%s", "recovered": false, "generation": "%s", "session_ids": %s, "lease_seconds": %s}\n' \
        "$OWNER" "$STEP" "$(lock_gen)" "$(json_session_ids "$(lock_session_ids)")" "$_lease"
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
    # 3. PERIME — un SEUL recuperateur par generation. Le mutex porte le nom de la generation
    #    observee : `ln -s` echoue si un concurrent l'a deja pris, et une generation neuve
    #    donnerait un autre nom (donc pas de mutex zombie qui bloquerait la suivante).
    log "lock perime (age ${age}s > ${TTL}s, owner=$held) — recuperation"
    mutex="${LOCK_DIR}.rec.$(printf '%s' "$observed_gen" | tr -c 'A-Za-z0-9._-' '_')"
    if ! ln_atomic "$$" "$mutex"; then
      rm -rf "${LOCK_PARENT:?}/$gen"
      printf '{"acquired": false, "reason": "race-during-recovery"}\n'; exit 1
    fi
    # Re-verifier APRES le mutex, SUR LES DEUX CRITERES. La generation ne suffit pas : un
    # retardataire qui lit l'age AVANT le remplacement et la generation APRES obtient un mutex
    # libre (celui de la generation NEUVE) et passe le test d'egalite — il recupere alors un lock
    # frais sur la foi d'un verdict de peremption perime. C'est ce qui laissait 2 gagnants apres
    # la bascule du protocole. L'age est donc RELU ici, et c'est lui qui tranche.
    if [ "$(lock_gen)" != "$observed_gen" ] || [ "$(lock_age)" -le "$TTL" ]; then
      rm -f "$mutex"; rm -rf "${LOCK_PARENT:?}/$gen"
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
      rm -f "$mutex" "${LOCK_DIR}.new.$$"
      case "$old_gen" in */*|''|legacy) ;; *) rm -rf "${LOCK_PARENT:?}/$old_gen" ;; esac
      printf '{"acquired": true, "owner": "%s", "step": "%s", "recovered": true, "previous_owner": "%s"}\n' \
        "$OWNER" "$STEP" "$held"
      exit 0
    fi
    rm -f "$mutex" "${LOCK_DIR}.new.$$"; rm -rf "${LOCK_PARENT:?}/$gen"
    printf '{"acquired": false, "reason": "race-during-recovery"}\n'; exit 1
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

  release)
    require_owner
    lock_present || { echo '{"released": false, "reason": "no-lock"}'; exit 0; }
    held="$(meta_get owner)"
    if [ "$held" = "$OWNER" ]; then
      drop_lock
      printf '{"released": true, "owner": "%s"}\n' "$OWNER"; exit 0
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
      if [ "$(lock_gen)" != "$observed_gen" ] || [ "$(lock_age)" -le "$TTL" ]; then
        rm -f "$mutex"
        printf '{"recovered": false, "reason": "race-during-recovery"}\n'; exit 1
      fi
      drop_lock; rm -f "$mutex"
      printf '{"recovered": true, "previous_owner": "%s", "age_seconds": %s}\n' "$held" "$age"; exit 0
    fi
    printf '{"recovered": false, "reason": "still-fresh", "age_seconds": %s, "ttl": %s}\n' "$age" "$TTL"
    exit 1
    ;;

  *)
    echo "Usage: $0 {acquire|heartbeat|release|status|recover} [--owner=ID] [--step=X]" >&2
    exit 1
    ;;
esac
