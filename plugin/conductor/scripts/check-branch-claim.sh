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
LOCK_GIVEN=0; [ -n "${VF_DRIVER_LOCK:-}" ] && LOCK_GIVEN=1
TTL="${VF_DRIVER_TTL:-1800}"
case "$TTL" in ''|*[!0-9]*) TTL=1800 ;; esac
ROOT="."
HOOK=0
QUIET=0

for arg in "$@"; do
  case "$arg" in
    --hook)    HOOK=1 ;;
    --quiet)   QUIET=1 ;;
    --lock=*)  LOCK_DIR="${arg#*=}"; LOCK_GIVEN=1 ;;
    --path=*)  ROOT="${arg#*=}" ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-branch-claim] argument inconnu : $arg" >&2; exit 64 ;;
  esac
done

[ -n "$LOCK_DIR" ] || { echo "[check-branch-claim] --lock vide" >&2; exit 64; }
[ -d "$ROOT" ] || { echo "[check-branch-claim] --path introuvable : $ROOT" >&2; exit 64; }

# Diagnostic : jamais sur stdout en mode --hook (stdout y est reserve au signal, une ligne).
diag() { [ "$QUIET" -eq 1 ] && return 0; echo "[check-branch-claim] $*" >&2; }

# --- Traduction du silence interne vers le harness (D-06/D-07, uniquement sous --hook) ----------
# hook_exit <code> : sous --hook, les codes SILENCIEUX (3 = SAIN, 4 = INDETERMINE — aucun des deux
# n'est un signal a bloquer ou a relayer) deviennent 0 a la frontiere du harness. Le signal (0) et
# l'erreur d'usage (64) ne sont JAMAIS traduits. Sans --hook (CLI, suites de tests), le code recu
# ressort inchange. Voir docs/HOOKS-CONTRAT-SORTIE.md §2 et l'entree #5 de l'inventaire.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && { [ "$code" -eq 3 ] || [ "$code" -eq 4 ]; }; then
    exit 0
  fi
  exit "$code"
}

indetermine() {
  diag "INDETERMINE, rien n'a ete verifie : $1"
  hook_exit 4
}

cd "$ROOT" 2>/dev/null || indetermine "impossible d'entrer dans $ROOT"

git rev-parse --git-dir >/dev/null 2>&1 || indetermine "racine hors d'un depot git"

CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ -n "$CUR_BRANCH" ] || indetermine "branche courante illisible"
[ "$CUR_BRANCH" = "HEAD" ] && indetermine "HEAD detache — aucune branche a comparer"

CUR_WORKTREE="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$CUR_WORKTREE" ] || indetermine "arbre de travail courant illisible"

# Comparaison de chemins NORMALISEE (`pwd -P`), jamais litterale : sur macOS `/tmp` est un lien
# vers `/private/tmp`, si bien que le meme arbre se presente sous deux ecritures selon qui
# l'interroge. Une comparaison brute criait alors a la collision sur son PROPRE arbre — le faux
# positif exact que ce gate doit eviter, debusque par le cas 2 de sa suite. Un chemin qui n'existe
# plus (arbre supprime, claim rance) n'est pas resolvable : on retombe sur la valeur brute, ce qui
# au pire signale — jamais un silence de complaisance.
norm_path() {
  [ -d "$1" ] && (cd "$1" 2>/dev/null && pwd -P) || printf '%s' "$1"
}

# claim_check_lock <dossier-de-verrou> : juge UN verrou, sans rien imprimer (Phase 57, P57-D-15).
# Rend 0 = signal (CL_DETAIL positionne), 3 = SAIN, 4 = INDETERMINE ; CL_MSG porte le diagnostic
# (sans prefixe INDETERMINE : l'appelant le pose). Meme logique que le verrou unique d'avant.
CL_MSG=""; CL_DETAIL=""; CL_META=""
meta_get() { grep "^$1=" "$CL_META" 2>/dev/null | head -1 | cut -d= -f2- || true; }
claim_check_lock() {
  local dir="$1" claim_branch claim_worktree claim_owner claim_step hb age
  CL_MSG=""; CL_DETAIL=""; CL_META="$dir/meta"
  # Pas de lock du tout = personne ne pilote. C'est un etat VERIFIE, donc SAIN — pas indetermine.
  if [ ! -d "$dir" ]; then
    CL_MSG="SAIN — aucun lock de driver actif (${dir} absent)."
    return 3
  fi
  if [ ! -r "$CL_META" ]; then
    CL_MSG="lock present mais son meta est illisible ($CL_META)"
    return 4
  fi

  claim_branch="$(meta_get branch)"
  claim_worktree="$(meta_get worktree)"
  claim_owner="$(meta_get owner)"
  claim_step="$(meta_get step)"
  hb="$(meta_get heartbeat_epoch)"

  # Lock pose par une version anterieure du script (sans les champs branch/worktree) : on ne peut
  # rien affirmer sur la branche. INDETERMINE, jamais un SAIN de complaisance.
  if [ -z "$claim_branch" ]; then
    CL_MSG="le lock ne porte pas de champ 'branch' (pose par une version anterieure de driver-lock.sh)"
    return 4
  fi

  case "$hb" in ''|*[!0-9]*) hb="" ;; esac
  if [ -n "$hb" ]; then
    age=$(( $(date +%s) - hb ))
    if [ "$age" -gt "$TTL" ]; then
      CL_MSG="SAIN — un lock existe mais il est perime (age ${age}s > ${TTL}s), traite comme absent."
      return 3
    fi
  else
    age=""
  fi

  if [ "$claim_branch" != "$CUR_BRANCH" ]; then
    CL_MSG="SAIN — le lock actif pilote '${claim_branch}', pas la branche courante '${CUR_BRANCH}'."
    return 3
  fi

  # Meme branche ET meme arbre : les deux sessions partagent physiquement leur arbre de travail,
  # elles se voient. Rien a signaler.
  if [ "$(norm_path "$claim_worktree")" = "$(norm_path "$CUR_WORKTREE")" ]; then
    CL_MSG="SAIN — la branche '${CUR_BRANCH}' est pilotee depuis CET arbre de travail."
    return 3
  fi

  CL_DETAIL="owner ${claim_owner:-?}"
  [ -n "$claim_step" ] && CL_DETAIL="$CL_DETAIL, etape ${claim_step}"
  [ -n "$age" ] && CL_DETAIL="$CL_DETAIL, depuis $(( age / 60 )) min"
  [ -n "$claim_worktree" ] && CL_DETAIL="$CL_DETAIL, arbre ${claim_worktree}"
  return 0
}

emit_signal() { # <detail>
  if [ "$HOOK" -eq 1 ]; then
    echo "[branch-claim] '${CUR_BRANCH}' est deja pilotee depuis un autre arbre de travail ($1) — un ecrivain = un worktree (ADR-064)."
  else
    diag "la branche '${CUR_BRANCH}' est revendiquee par un lock actif pose ailleurs ($1)."
  fi
  exit 0
}

# --- Verrous du clone (Phase 57, P57-D-07, P57-D-15) ---------------------------------------------
# Dans un lab partitionne, les verrous vivent au niveau du CLONE (un dossier par verrou, partage entre
# worktrees) : le seul .planning/DRIVER.lock du checkout courant est alors toujours absent, donc un faux
# SAIN. On lit les dossiers de verrous du clone tels qu'ils sont, sans detecter la partition ni nommer
# le dossier des compartiments. --lock / VF_DRIVER_LOCK designe UN verrou : seul celui-la est examine.
CLONE_N=0
CLONE_LIST=""
if [ "$LOCK_GIVEN" -eq 0 ]; then
  COMMON="$(git rev-parse --git-common-dir 2>/dev/null || true)"
  [ -n "$COMMON" ] && COMMON="$(cd "$COMMON" 2>/dev/null && pwd -P || true)"
  add_cand() { # <dossier> : retenu s'il existe (un motif non developpe n'est pas un dossier)
    if [ -d "$1" ]; then
      CLONE_N=$((CLONE_N+1))
      CLONE_LIST="$CLONE_LIST$1
"
    fi
  }
  if [ -n "$COMMON" ]; then
    add_cand "$COMMON/vf-driver/repo/DRIVER.lock"
    for cand in "$COMMON/vf-driver/ws/"*/DRIVER.lock; do add_cand "$cand"; done
  fi
  add_cand "$CUR_WORKTREE/.planning/DRIVER.lock.d/repo/DRIVER.lock"
  for cand in "$CUR_WORKTREE/.planning/DRIVER.lock.d/ws/"*/DRIVER.lock; do add_cand "$cand"; done
fi

# Aucun verrou du clone : le chemin d'avant, rejoue tel quel (lab plat inchange, P57-D-03).
if [ "$CLONE_N" -eq 0 ]; then
  claim_check_lock "$LOCK_DIR"; rc=$?
  case "$rc" in
    0) emit_signal "$CL_DETAIL" ;;
    3) diag "$CL_MSG"; hook_exit 3 ;;
    *) indetermine "$CL_MSG" ;;
  esac
fi

# Agregation : un signal l'emporte, sinon un indetermine, sinon SAIN. Le verrou du checkout, s'il
# existe, est examine avec les autres.
if [ -d "$LOCK_DIR" ]; then
  CLONE_N=$((CLONE_N+1))
  CLONE_LIST="$CLONE_LIST$LOCK_DIR
"
fi
INDET_MSG=""
while IFS= read -r lk; do
  [ -n "$lk" ] || continue
  claim_check_lock "$lk"; rc=$?
  case "$rc" in
    0)
      case "$lk" in
        */ws/*/DRIVER.lock) sj="${lk%/DRIVER.lock}"; CL_DETAIL="$CL_DETAIL, compartiment ${sj##*/}" ;;
        */repo/DRIVER.lock) CL_DETAIL="$CL_DETAIL, verrou de depot" ;;
      esac
      emit_signal "$CL_DETAIL" ;;
    4) [ -n "$INDET_MSG" ] || INDET_MSG="$CL_MSG ($lk)" ;;
  esac
done <<EOF2
$CLONE_LIST
EOF2
[ -z "$INDET_MSG" ] || indetermine "$INDET_MSG"
diag "SAIN — ${CLONE_N} lock(s) de driver examine(s), aucun ne revendique '${CUR_BRANCH}' depuis un autre arbre de travail."
hook_exit 3
