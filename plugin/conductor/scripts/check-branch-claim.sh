#!/usr/bin/env bash
# check-branch-claim.sh — La branche courante est-elle deja pilotee depuis un AUTRE arbre ? (ADR-064)
#
# Role (meme distinction FAIT/JUGEMENT que check-doc-drift.sh et check-mission-invariants.sh) :
# ce script CONSTATE qu'un lock de driver ACTIF revendique la branche git courante depuis un
# AUTRE arbre de travail. Il ne bloque rien, ne relache aucun lock, ne qualifie la situation ni
# d'« erreur » ni de « collision » : deux sessions volontairement sur la meme branche est un cas
# LEGITIME et frequent. Le jugement appartient a l'humain qui lit le signal (ADR-031).
#
# Origine : le 2026-07-31, deux sessions ont ecrit sur `feat/phase-22-hygiene-doc` sans le savoir
# (3 commits hors perimetre pousses dans la PR d'une mission qui ne les avait pas produits). Le
# verrou de driver existait — mais il revendiquait une ETAPE, et surtout il n'etait consulte QUE
# par les managers. La session qui est passee par-dessus n'en etait pas un. Un verrou que seule
# une categorie d'acteurs interroge ne protege pas contre les autres : ce script est le chemin par
# lequel le claim atteint enfin une session ordinaire.
#
# Le discriminant est l'ARBRE DE TRAVAIL, pas l'owner : deux sessions du meme worktree partagent
# de fait leur arbre (rien a signaler, elles se voient) ; c'est l'ecriture depuis un arbre TIERS
# sur une branche deja pilotee qui surprend. Un lock pose depuis le repertoire courant ne declenche
# donc jamais de signal, meme sous un autre owner.
#
# Usage:
#   check-branch-claim.sh                 # verdict humain sur stderr + code de sortie
#   check-branch-claim.sh --hook          # 1 ligne sur stdout si signal, STRICTEMENT VIDE sinon
#   check-branch-claim.sh --quiet         # aucun diagnostic, code de sortie seul
#   check-branch-claim.sh --lock=<chemin> # override du lock (defaut : $VF_DRIVER_LOCK ou .planning/DRIVER.lock)
#   check-branch-claim.sh --path=<racine> # racine du depot a inspecter (defaut : .)
#
# Contrat de sortie (meme patron a 4 codes que check-mission-invariants.sh, ou SAIN et
# INDETERMINE ne se confondent JAMAIS) :
#
#   0  = branche revendiquee par un autre arbre — signal [branch-claim] emis
#   3  = SAIN — verifie : aucun lock actif ne revendique cette branche depuis ailleurs.
#        Le SEUL code qui signifie « regarde, et rien a signaler ».
#   4  = INDETERMINE — rien n'a pu etre verifie : hors depot git, HEAD detache, ou meta de lock
#        illisible. N'autorise JAMAIS a conclure que la voie est libre.
#   64 = erreur d'usage (argument inconnu, --lock/--path invalide)
#
# Un lock PERIME (heartbeat au-dela du TTL) est traite comme absent — sinon un manager mort
# gelerait le signal pour tout le monde, exactement ce que la recuperation de claim de
# driver-lock.sh evite deja cote pilotage. TTL partage : VF_DRIVER_TTL (defaut 1800 s).

set -uo pipefail

LOCK_DIR="${VF_DRIVER_LOCK:-.planning/DRIVER.lock}"
TTL="${VF_DRIVER_TTL:-1800}"
case "$TTL" in ''|*[!0-9]*) TTL=1800 ;; esac
ROOT="."
HOOK=0
QUIET=0

for arg in "$@"; do
  case "$arg" in
    --hook)    HOOK=1 ;;
    --quiet)   QUIET=1 ;;
    --lock=*)  LOCK_DIR="${arg#*=}" ;;
    --path=*)  ROOT="${arg#*=}" ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-branch-claim] argument inconnu : $arg" >&2; exit 64 ;;
  esac
done

[ -n "$LOCK_DIR" ] || { echo "[check-branch-claim] --lock vide" >&2; exit 64; }
[ -d "$ROOT" ] || { echo "[check-branch-claim] --path introuvable : $ROOT" >&2; exit 64; }

# Diagnostic : jamais sur stdout en mode --hook (stdout y est reserve au signal, une ligne).
diag() { [ "$QUIET" -eq 1 ] && return 0; echo "[check-branch-claim] $*" >&2; }

indetermine() {
  diag "INDETERMINE, rien n'a ete verifie : $1"
  exit 4
}

cd "$ROOT" 2>/dev/null || indetermine "impossible d'entrer dans $ROOT"

git rev-parse --git-dir >/dev/null 2>&1 || indetermine "racine hors d'un depot git"

CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ -n "$CUR_BRANCH" ] || indetermine "branche courante illisible"
[ "$CUR_BRANCH" = "HEAD" ] && indetermine "HEAD detache — aucune branche a comparer"

CUR_WORKTREE="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$CUR_WORKTREE" ] || indetermine "arbre de travail courant illisible"

META="$LOCK_DIR/meta"
# Pas de lock du tout = personne ne pilote. C'est un etat VERIFIE, donc SAIN — pas indetermine.
if [ ! -d "$LOCK_DIR" ]; then
  diag "SAIN — aucun lock de driver actif (${LOCK_DIR} absent)."
  exit 3
fi
[ -r "$META" ] || indetermine "lock present mais son meta est illisible ($META)"

meta_get() { grep "^$1=" "$META" 2>/dev/null | head -1 | cut -d= -f2- || true; }

CLAIM_BRANCH="$(meta_get branch)"
CLAIM_WORKTREE="$(meta_get worktree)"
CLAIM_OWNER="$(meta_get owner)"
CLAIM_STEP="$(meta_get step)"
HB="$(meta_get heartbeat_epoch)"

# Lock pose par une version anterieure du script (sans les champs branch/worktree) : on ne peut
# rien affirmer sur la branche. INDETERMINE, jamais un SAIN de complaisance.
[ -n "$CLAIM_BRANCH" ] || indetermine "le lock ne porte pas de champ 'branch' (pose par une version anterieure de driver-lock.sh)"

case "$HB" in ''|*[!0-9]*) HB="" ;; esac
if [ -n "$HB" ]; then
  AGE=$(( $(date +%s) - HB ))
  if [ "$AGE" -gt "$TTL" ]; then
    diag "SAIN — un lock existe mais il est perime (age ${AGE}s > ${TTL}s), traite comme absent."
    exit 3
  fi
else
  AGE=""
fi

if [ "$CLAIM_BRANCH" != "$CUR_BRANCH" ]; then
  diag "SAIN — le lock actif pilote '${CLAIM_BRANCH}', pas la branche courante '${CUR_BRANCH}'."
  exit 3
fi

# Comparaison de chemins NORMALISEE (`pwd -P`), jamais litterale : sur macOS `/tmp` est un lien
# vers `/private/tmp`, si bien que le meme arbre se presente sous deux ecritures selon qui
# l'interroge. Une comparaison brute criait alors a la collision sur son PROPRE arbre — le faux
# positif exact que ce gate doit eviter, debusque par le cas 2 de sa suite. Un chemin qui n'existe
# plus (arbre supprime, claim rance) n'est pas resolvable : on retombe sur la valeur brute, ce qui
# au pire signale — jamais un silence de complaisance.
norm_path() {
  [ -d "$1" ] && (cd "$1" 2>/dev/null && pwd -P) || printf '%s' "$1"
}

# Meme branche ET meme arbre : les deux sessions partagent physiquement leur arbre de travail,
# elles se voient. Rien a signaler.
if [ "$(norm_path "$CLAIM_WORKTREE")" = "$(norm_path "$CUR_WORKTREE")" ]; then
  diag "SAIN — la branche '${CUR_BRANCH}' est pilotee depuis CET arbre de travail."
  exit 3
fi

DETAIL="owner ${CLAIM_OWNER:-?}"
[ -n "$CLAIM_STEP" ] && DETAIL="$DETAIL, etape ${CLAIM_STEP}"
[ -n "$AGE" ] && DETAIL="$DETAIL, depuis $(( AGE / 60 )) min"
[ -n "$CLAIM_WORKTREE" ] && DETAIL="$DETAIL, arbre ${CLAIM_WORKTREE}"

if [ "$HOOK" -eq 1 ]; then
  echo "[branch-claim] '${CUR_BRANCH}' est deja pilotee depuis un autre arbre de travail (${DETAIL}) — un ecrivain = un worktree (ADR-064)."
else
  diag "la branche '${CUR_BRANCH}' est revendiquee par un lock actif pose ailleurs (${DETAIL})."
fi
exit 0
