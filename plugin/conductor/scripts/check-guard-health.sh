#!/usr/bin/env bash
# check-guard-health.sh — Le "hook doctor" : un garde du parc a-t-il ete incapable de tourner ? (QUAL-01)
#
# Role (meme distinction FAIT/JUGEMENT que check-branch-claim.sh et check-mission-invariants.sh) :
# ce script CONSTATE que des marqueurs de sante ecrits par vf_guard_unavailable (Phase 30,
# plugin/_internal/lib/vf-portable.sh) signalent qu'un garde n'a pas pu tourner recemment. Il ne
# corrige rien, ne bloque rien, ne qualifie rien d'« erreur » — l'arbitrage (installer un
# interprete, mettre a jour vibeflow) appartient a l'humain (ADR-031). Il ne connait AUCUN garde en
# particulier : il agrege les marqueurs de TOUTES les entrees du parc, pas seulement ceux du guard
# du driver-lock — c'est un lecteur GENERIQUE, pas un lecteur special-lock.
#
# Origine : `vf_guard_unavailable` ecrit un troisieme etat depuis la Phase 30 — « n'a pas pu
# tourner », distinct de « a tourne et a trouve un probleme » et de « a tourne et n'a rien trouve »
# — et ce marqueur n'avait, jusqu'a ce script, AUCUN CONSOMMATEUR dans tout `plugin/` (mesure
# 32-TERRAIN.md §11 : `grep -rn "guard-health\|VF_GUARD_HEALTH_DIR" plugin/ scripts/` hors
# vf-portable.sh et tests/ rendait zero resultat). Le "hook doctor" est specifie depuis le
# 2026-08-02 (docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md:205-207) et
# jamais ecrit avant ce script.
#
# Usage:
#   check-guard-health.sh                # verdict humain sur stderr + code de sortie
#   check-guard-health.sh --hook         # 1 ligne sur stdout si signal, STRICTEMENT VIDE sinon
#   check-guard-health.sh --quiet        # aucun diagnostic, code de sortie seul
#   check-guard-health.sh --dir=<chemin> # override du repertoire de sante (defaut : voir ci-dessous)
#   check-guard-health.sh --window=<sec> # override de la fenetre de rapport (defaut : 86400 = 24h)
#   check-guard-health.sh --stall-window=<sec> # override du seuil de stall de mission (defaut :
#                                         # 900 = VF_STALL_WINDOW ; le flag l'emporte toujours sur
#                                         # la variable d'environnement)
#
# Repertoire de sante par defaut — COUPLAGE CRITIQUE, seul endroit du depot ou ces deux chemins
# DOIVENT s'accorder : `${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}`,
# EXACTEMENT la meme derivation que celle ECRITE par `vf_guard_unavailable` dans
# plugin/_internal/lib/vf-portable.sh:147. Un ecart de convention entre l'ecrivain et le lecteur
# rendrait ce script aveugle sans jamais le signaler — d'ou la derivation dupliquee ICI a l'identique,
# plutot que source une lib externe pour une seule ligne (et zero spawn d'interprete ajoute).
#
# Contrat de sortie (meme patron a 4 codes que check-branch-claim.sh, ou SAIN et INDETERMINE ne se
# confondent JAMAIS) :
#
#   0  = signal — au moins un marqueur de sante RECENT existe. UNE SEULE ligne sur stdout, jamais
#        une par marqueur (une injection de contexte de session verbeuse est une regression pour
#        tout le parc qui l'installe).
#   3  = SAIN — verifie : aucun marqueur recent (repertoire absent, vide, ou marqueurs tous perimes).
#        Le SEUL code qui signifie « regarde, et rien a signaler ».
#   4  = INDETERMINE — rien n'a pu etre verifie : repertoire de sante present mais illisible
#        (permissions). N'autorise JAMAIS a conclure que la voie est libre — ce serait exactement
#        le vert de complaisance que QUAL-01 interdit.
#  64  = erreur d'usage (argument inconnu, --dir/--window invalide)
#
# Fenetre de rapport et SON MOTIF : `vf_guard_unavailable` REECRIT (jamais n'ajoute) son marqueur a
# CHAQUE invocation du garde en panne — donc un marqueur dont l'horodatage depasse la fenetre de
# rapport signifie que la panne a CESSE (le garde a du tourner sans probleme depuis, sinon le
# marqueur aurait ete rafraichi). Un tel marqueur perime n'est jamais signale.
#
# Lecture seule STRICTE sur les marqueurs des AUTRES gardes : ce script ne cree, ne modifie, ni ne
# supprime AUCUN fichier ECRIT par un AUTRE garde — jamais de `rm`, `mv` ni `touch` sur les
# marqueurs qui ne sont pas les siens. Un lecteur qui elaguerait des marqueurs etrangers serait un
# correcteur deguise (ADR-031), et l'elagage effacerait la trace au moment ou elle devient utile a
# un humain qui viendrait l'inspecter plus tard.
#
# SEULE EXCEPTION (Phase 33, WTCH-02) : ce script ecrit UNE fois, atomiquement (tmp + `mv -f`,
# meme patron que le producteur qu'il lit ailleurs), SON PROPRE marqueur d'indisponibilite
# (`check-guard-health.sh.marker`) quand SA PROPRE dependance (le sibling `driver-lock.sh`, ou tout
# interprete Python) est indisponible — voir `report_self_unavailable()` plus bas. Ce n'est pas un
# elagage des marqueurs des autres gardes (aucun autre `rm`/`mv`/`touch` nulle part ailleurs dans ce
# fichier, code seul — voir les criteres de comptage exact du plan).
#
# SOUS-CONTROLE STALL/ABANDON (Phase 33, WTCH-02, D-33-A/D-33-E) — sur le battement pose par la
# Phase 32/33-01 : ce script lit AUSSI `driver-lock.sh status` (sibling resolu par repertoire de
# script, meme motif que dag.sh en 33-02) et distingue TROIS verdicts : SAIN (les deux horloges
# fraiches, ou aucun lock present), STALL (heartbeat frais, `progress_age_seconds` au-dela du seuil
# `STALL_WINDOW`), ABANDON (`stale: true`, heartbeat mort). Le sous-controle (`check_driver_stall()`)
# s'EXECUTE TOUJOURS AVANT les trois sorties precoces liees a l'existence/lisibilite de HEALTH_DIR
# — placer ce controle APRES ces sorties le rendrait mort en production sur le cas majoritaire
# (machine saine, repertoire absent) tout en restant vert en test (fixtures qui font `mkdir -p`) :
# exactement le garde aveugle que QUAL-01 interdit. `STALL_WINDOW` (defaut 900s, override
# `--stall-window=`/`VF_STALL_WINDOW`) DOIT rester STRICTEMENT SOUS `VF_DRIVER_TTL` (driver-lock.sh,
# defaut 1800s) — voir le commentaire dedie plus bas pour le motif mesure. Une ligne PAR FAMILLE de
# signal (marqueurs de garde, stall de mission) est imprimee — jamais une par marqueur individuel au
# sein d'une famille — donc au plus DEUX lignes au total.
#
# REGLE DE PROGRESSION (arbitrage Samuel, AskUserQuestion session principale, 2026-10-13, Q1 option b) :
# `progress_age_seconds` du verrou n'avance que par `dag.sh mark` / `driver-lock.sh mark-progress` ; or un
# plan peut durer plus que STALL_WINDOW sans marquer aucun noeud (faux stall constate a 1587 s et 1589 s le
# 2026-10-12). L'age de progression EFFECTIF est donc mesure depuis le plus recent de (a) `progress_epoch`
# du verrou et (b) l'horodatage du commit le plus recent parmi les HEAD de TOUS les worktrees du dossier git
# commun (`git worktree list --porcelain -z`, lecture separee par NUL, puis UN SEUL `git log --no-walk --format=%ct` pour tous
# les HEAD, repli par HEAD ; AU3-05, AU3-06 ; arbitrage Samuel,
# AskUserQuestion session principale, 2026-10-13, D option b) : un verrou partage entre worktrees (vf-driver/
# sous le git-common-dir) est travaille depuis le worktree de son proprietaire, pas forcement celui ou tourne
# le watchdog. Un commit plus recent que la fenetre ecarte le STALL. Seuil, TTL, verdict ABANDON (heartbeat
# mort : un commit n'y change rien) et forme de sortie sont inchanges ; la ligne de stall imprime l'age
# effectif. Horodatage retenu : celui du COMMITTER (`%ct`), pas de l'auteur (`%at`) — l'auteur est conserve
# par rebase, cherry-pick et amend, il peut donc dater de plusieurs jours alors que le commit vient d'etre
# ecrit (un commit rebase hier a l'instant, vu comme vieux = faux stall) ; `%ct` dit « quand ce commit est
# entre dans la branche », seule date qui prouve une activite recente. Sont ignores, chacun pour son compte :
# un worktree illisible ou perime (prunable), un HEAD sans commit, un commit date du futur (horloge decalee :
# il masquerait un stall pour de bon). Liste des worktrees vide ou en erreur, ou aucun HEAD lisible : repli
# sur le HEAD du repertoire courant, comme avant ; sans depot git, sans commit, git absent ou lecture en
# echec : la lecture est ignoree et le comportement est celui d'avant — jamais un SAIN fabrique par une lecture
# ratee, jamais un crash. git est lance durci (modele de `git_hardened` de guard-driver-lock.sh : GIT_DIR,
# GIT_WORK_TREE, GIT_INDEX_FILE et consorts herites neutralises, ni fsmonitor ni hooks du depot, pas de
# verrou optionnel, pas de configuration systeme, pas d'invite). En lab partitionne, la logique « entree la
# plus grave » sur `locks` (P57-D-31) s'applique a l'age effectif de chaque entree.
# Limite ecrite, ACCEPTEE : un commit sans rapport dans un autre worktree du meme depot peut masquer un vrai
# stall ; le watchdog est consultatif (ADR-031), il ne tue ni ne bloque rien, et le cout d'un faux SAIN
# est inferieur a celui d'un faux stall a chaque plan multi-worktrees.

set -uo pipefail

DEFAULT_HEALTH_DIR="${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}"
HEALTH_DIR="$DEFAULT_HEALTH_DIR"
WINDOW=86400
HOOK=0
QUIET=0

SCRIPT_DIR_SELF="$(cd "$(dirname "$0")" && pwd 2>/dev/null || dirname "$0")"
DRIVER_LOCK_SH="$SCRIPT_DIR_SELF/driver-lock.sh"
# D-33-E (2026-08-17) : STALL_WINDOW doit rester STRICTEMENT SOUS VF_DRIVER_TTL
# (driver-lock.sh:40, defaut 1800s) — sinon un lock devient `stale` (verdict ABANDON) avant
# meme que progress_age_seconds ne depasse ce seuil, et le verdict STALL redevient
# inatteignable en production (regression mesuree : les deux valaient 1800 dans une version
# anterieure). Toute revision future de l'une ou l'autre constante doit re-verifier
# l'inegalite stricte.
STALL_WINDOW="${VF_STALL_WINDOW:-900}"

for arg in "$@"; do
  case "$arg" in
    --hook)     HOOK=1 ;;
    --quiet)    QUIET=1 ;;
    --dir=*)    HEALTH_DIR="${arg#*=}" ;;
    --window=*) WINDOW="${arg#*=}" ;;
    --stall-window=*) STALL_WINDOW="${arg#*=}" ;;
    -h|--help)  grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-guard-health] argument inconnu : $arg" >&2; exit 64 ;;
  esac
done

[ -n "$HEALTH_DIR" ] || { echo "[check-guard-health] --dir vide" >&2; exit 64; }
case "$WINDOW" in ''|*[!0-9]*) echo "[check-guard-health] --window invalide : $WINDOW" >&2; exit 64 ;; esac
case "$STALL_WINDOW" in ''|*[!0-9]*) echo "[check-guard-health] --stall-window invalide : $STALL_WINDOW" >&2; exit 64 ;; esac

# Diagnostic : jamais sur stdout en mode --hook (stdout y est reserve au signal, une ligne).
diag() { [ "$QUIET" -eq 1 ] && return 0; echo "[check-guard-health] $*" >&2; }

# --- Traduction du silence interne vers le harness (uniquement sous --hook) ----------------------
# hook_exit <code> : sous --hook, les codes SILENCIEUX (3 = SAIN, 4 = INDETERMINE — aucun des deux
# n'est un signal a relayer) deviennent 0 a la frontiere du harness. Le signal (0, deja 0) et
# l'erreur d'usage (64) ne sont JAMAIS traduits. Sans --hook (CLI, suites de tests), le code recu
# ressort inchange. Voir docs/HOOKS-CONTRAT-SORTIE.md §2.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && { [ "$code" -eq 3 ] || [ "$code" -eq 4 ]; }; then
    exit 0
  fi
  exit "$code"
}

# report_self_unavailable() : reproduit LOCALEMENT (jamais en sourcant vf-portable.sh) les trois
# actions de son producteur (plugin/_internal/lib/vf-portable.sh:145-158) — marqueur atomique
# tmp+mv du marqueur de CE script sur LUI-MEME, stderr prefixe, retour non nul — sur le MEME
# HEALTH_DIR deja resolu plus haut. Ce script N'EST PAS un consommateur du bloc localisateur
# canonique (deja justifie en tete de fichier pour la derivation de HEALTH_DIR elle-meme).
# Correction post-33-04 : notify.sh non plus (33-04 a tranche une resolution tolerante propre,
# hors perimetre) — le compteur de consommateurs du bloc canonique reste inchange par toute la
# Phase 33. `mkdir -p` est le SEUL cas ou ce script cree HEALTH_DIR — jamais pour un stall pur
# (voir check_driver_stall() plus bas, cas D23 du plan).
report_self_unavailable() { # <motif>
  local motif="$1"
  local marker="$HEALTH_DIR/check-guard-health.sh.marker"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if mkdir -p "$HEALTH_DIR" 2>/dev/null; then
    { printf '%s\t%s\t%s\n' "$ts" "check-guard-health.sh" "$motif" > "${marker}.tmp.$$" \
        && mv -f "${marker}.tmp.$$" "$marker"; } 2>/dev/null \
      || rm -f "${marker}.tmp.$$" 2>/dev/null || true
  fi
  echo "[check-guard-health] $motif" >&2
  return 1
}

indetermine() {
  diag "INDETERMINE, rien n'a ete verifie : $1"
  hook_exit 4
}

# py_resolve_local() : reproduit LOCALEMENT (jamais en sourcant vf-portable.sh) la cascade
# python3 -> python -> py -3 de son producteur (plugin/_internal/lib/vf-portable.sh:104-124),
# rejet du stub Microsoft Store (*WindowsApps*) par CHEMIN pour CHAQUE candidat — perdre ce
# rejet rouvrirait la regression Windows fermee en Phase 30, cette fois sur un script de hook du
# parc entier. Profil PRESENCE SEULE (aucune sonde d'execution reelle) : ce sous-controle tourne
# a SessionStart, une latence de spawn Python supplementaire par candidat serait superflue ici,
# contrairement au profil complet utilise ailleurs pour une resolution one-shot plus critique.
# Imprime le token d'invocation retenu (python3, python, ou py -3) sur stdout et rend 0 si un
# candidat passe, rend 1 sans rien imprimer sinon.
py_resolve_local() {
  local cand bin
  for cand in python3 python "py -3"; do
    bin="${cand%% *}"
    command -v "$bin" >/dev/null 2>&1 || continue
    case "$(command -v "$bin" 2>/dev/null)" in *WindowsApps*) continue ;; esac
    printf '%s' "$cand"
    return 0
  done
  return 1
}

# cgh_git() : git durci, modele de `git_hardened` (guard-driver-lock.sh) — l'environnement herite (GIT_DIR,
# GIT_WORK_TREE, GIT_INDEX_FILE, ...) pointerait ailleurs que le depot du repertoire courant ; ni fsmonitor ni
# hooks du depot, pas de verrou optionnel, pas de configuration systeme, pas d'invite.
cgh_git() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY \
      -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_NAMESPACE -u GIT_PREFIX \
      GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_OPTIONAL_LOCKS=0 \
      git -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@" </dev/null
}

# commit_epoch_of() : %ct de <rev> si numerique et pas dans le futur, sinon rien (lecture ignoree).
commit_epoch_of() { # <rev> <now>
  local ct
  ct="$(cgh_git log -1 --format=%ct "$1" 2>/dev/null)" || return 0
  case "$ct" in ''|*[!0-9]*) return 0 ;; esac
  [ "$2" -ge "$ct" ] && printf '%s' "$ct"
  return 0
}

# worktree_head_shas() : imprime, un par ligne, le HEAD de chaque worktree du dossier git commun (hors prunable, hors
# bloc suspect). Lecture SEPAREE PAR NUL (`worktree list --porcelain -z`, git >= 2.36) : un chemin de worktree peut
# contenir un saut de ligne, et en lecture par lignes ce chemin forgeait une ligne `HEAD <sha>` (mesure : age 214 082
# 152 s -> 0 s, AU3-05). Avec -z un chemin reste UN champ, qui commence par `worktree ` ; un bloc dont le premier champ
# n'est pas `worktree ` est rejete en entier. REPLI SUR : un git qui ne connait pas `-z` echoue (exit 129), la liste
# est alors vide et l'appelant retombe sur le HEAD du repertoire courant (jamais une lecture par lignes).
worktree_head_shas() {
  local line sha="" skip=0 first=1 bad=0
  { cgh_git worktree list --porcelain -z 2>/dev/null; printf '\0'; } | while IFS= read -r -d '' line; do
    if [ -z "$line" ]; then
      # Champ vide = fin de bloc (un bloc par worktree).
      case "$sha" in
        ''|*[!0-9a-f]*) : ;;
        *) [ "$skip" -eq 0 ] && [ "$bad" -eq 0 ] && printf '%s\n' "$sha" ;;
      esac
      sha=""; skip=0; first=1; bad=0
      continue
    fi
    if [ "$first" -eq 1 ]; then
      first=0
      case "$line" in "worktree "*) : ;; *) bad=1 ;; esac
    fi
    case "$line" in
      "HEAD "*) sha="${line#HEAD }" ;;
      prunable*) skip=1 ;;
    esac
  done
  return 0
}

# latest_commit_epoch() : imprime le %ct le plus recent parmi les HEAD de tous les worktrees du dossier git commun
# (REGLE DE PROGRESSION, en-tete), vide si rien de lisible. Jamais d'echec. UN SEUL `git log --no-walk` pour tous les
# HEAD (AU3-06) ; si git le refuse (un HEAD illisible fait echouer l'ensemble), repli sur un processus par HEAD, chaque
# HEAD juge pour son compte.
latest_commit_epoch() {
  command -v git >/dev/null 2>&1 || return 0
  local now_s best="" sha ct out
  local -a shas=()
  now_s="$(date +%s)"
  while IFS= read -r sha; do
    [ -n "$sha" ] && shas+=("$sha")
  done <<EOF_SHAS
$(worktree_head_shas)
EOF_SHAS
  if [ "${#shas[@]}" -gt 0 ]; then
    if out="$(cgh_git log --no-walk=unsorted --format=%ct "${shas[@]}" -- 2>/dev/null)" && [ -n "$out" ]; then
      while IFS= read -r ct; do
        case "$ct" in ''|*[!0-9]*) continue ;; esac
        [ "$now_s" -ge "$ct" ] || continue   # commit dans le futur : ignore
        { [ -z "$best" ] || [ "$ct" -gt "$best" ]; } && best="$ct"
      done <<EOF_CTS
$out
EOF_CTS
    else
      for sha in "${shas[@]}"; do
        ct="$(commit_epoch_of "$sha" "$now_s")"
        [ -n "$ct" ] && { [ -z "$best" ] || [ "$ct" -gt "$best" ]; } && best="$ct"
      done
    fi
  fi
  # Liste vide, en erreur ou sans HEAD lisible : comportement d'avant, le HEAD du repertoire courant.
  [ -n "$best" ] || best="$(commit_epoch_of HEAD "$now_s")"
  printf '%s' "$best"
  return 0
}

# check_driver_stall() : lit `driver-lock.sh status --all` (sibling resolu par repertoire de script,
# DRIVER_LOCK_SH ci-dessus) et distingue TROIS verdicts (D-33-A) : SAIN (rien a signaler), STALL
# (heartbeat frais, progres fige au-dela de STALL_WINDOW), ABANDON (heartbeat mort, `stale: true`).
# Positionne STALL_INDETERMINATE et STALL_LINE — jamais n'imprime elle-meme, jamais de code de
# sortie : c'est le flux principal, plus bas (EXECUTE AVANT les trois sorties precoces historiques
# liees a HEALTH_DIR), qui decide du verdict final. QUATRE issues (QUAL-01) : SAIN (rien
# positionne) / SIGNAL (STALL_LINE positionnee) / imparsable -> fail-open SILENCIEUX (rien
# positionne, jamais un plantage) / dependance indisponible -> fail-open BRUYANT
# (STALL_INDETERMINATE=1 + marqueur + stderr via report_self_unavailable()).
check_driver_stall() {
  STALL_INDETERMINATE=0
  STALL_LINE=""

  if [ ! -f "$DRIVER_LOCK_SH" ] || [ ! -x "$DRIVER_LOCK_SH" ]; then
    report_self_unavailable "driver-lock.sh introuvable ou non executable ($DRIVER_LOCK_SH)"
    STALL_INDETERMINATE=1
    return 0
  fi

  local py_invoke
  py_invoke="$(py_resolve_local)" || {
    report_self_unavailable "aucun interprete Python utilisable (cascade python3/python/py -3)"
    STALL_INDETERMINATE=1
    return 0
  }

  local out rc_status
  out="$("$DRIVER_LOCK_SH" status --all 2>/dev/null)"
  rc_status=$?
  if [ "$rc_status" -ne 0 ]; then
    report_self_unavailable "driver-lock.sh status --all a rendu un code non nul ($rc_status)"
    STALL_INDETERMINATE=1
    return 0
  fi

  # Parse du JSON via variable d'environnement, JAMAIS par argv ni par concatenation (T-33-10) —
  # le JSON traverse une frontiere de confiance (sous-processus non fiable). $py_invoke reste NON
  # quote volontairement : c'est ce qui permet a "py -3" de porter son argument de lanceur (meme
  # patron que le producteur reproduit ici).
  # Age du commit le plus recent parmi les HEAD de tous les worktrees (REGLE DE PROGRESSION, en-tete) : vide si illisible.
  local commit_age="" ct="" now_s
  ct="$(latest_commit_epoch)"
  case "$ct" in
    ''|*[!0-9]*) : ;;
    *) now_s="$(date +%s)"; [ "$now_s" -ge "$ct" ] && commit_age=$(( now_s - ct )) ;;
  esac

  local parsed rc_py
  # shellcheck disable=SC2086
  parsed="$(STATUS_JSON="$out" STALL_WINDOW="$STALL_WINDOW" COMMIT_AGE="$commit_age" $py_invoke -I <<'PYEOF'
import json, os, sys
raw = os.environ.get("STATUS_JSON", "")
ca_raw = os.environ.get("COMMIT_AGE", "")
commit_age = int(ca_raw) if ca_raw.isdigit() else None
def eff(pa):
    # age de progression effectif = le plus recent de progress_epoch (pa) et du dernier commit
    if isinstance(pa, int) and not isinstance(pa, bool) and commit_age is not None:
        return min(pa, commit_age)
    return pa
try:
    data = json.loads(raw)
except Exception:
    sys.exit(1)
if not isinstance(data, dict):
    sys.exit(1)
# Deux formes (P57-D-31) : lab partitionne -> objet portant `locks` (une entree par verrou) ; lab plat ou
# VF_DRIVER_LOCK -> objet unique, la sortie de `status`. Forme `locks` : on retient l entree la plus grave
# (verrou present et perime = abandon, puis present au progres fige au-dela du seuil = stall), une seule ligne
# pour la famille ; `extra_signals` compte les AUTRES entrees en signal.
ws = ""
scope = ""
extra = 0
if "locks" in data:
    locks = data.get("locks")
    if not isinstance(locks, list):
        sys.exit(1)
    try:
        win = int(os.environ.get("STALL_WINDOW", "900"))
    except Exception:
        win = 900
    best = None
    best_rank = 0
    signals = 0
    first_present = None
    for e in locks:
        if not isinstance(e, dict) or not e.get("present"):
            continue
        if first_present is None:
            first_present = e
        pa = eff(e.get("progress_age_seconds"))
        if e.get("stale"):
            rank = 2
        elif isinstance(pa, int) and not isinstance(pa, bool) and pa > win:
            rank = 1
        else:
            rank = 0
        if rank:
            signals += 1
            if best is None or rank > best_rank:
                best, best_rank = e, rank
    entry = best if best is not None else first_present
    if entry is None:
        entry = {"present": False}
    else:
        extra = signals - 1 if best is not None else 0
        scope = str(entry.get("scope", ""))
        ws = str(entry.get("ws", "")) if scope == "compartiment" else ""
else:
    entry = data
present = entry.get("present")
stale = entry.get("stale")
owner = entry.get("owner")
step = entry.get("step")
progress_age = eff(entry.get("progress_age_seconds"))
ttl = entry.get("ttl")
print("present=%s" % ("true" if present else "false"))
print("stale=%s" % ("true" if stale else "false"))
print("owner=%s" % (owner if owner is not None else ""))
print("step=%s" % (step if step is not None else ""))
print("progress_age_seconds=%s" % ("" if progress_age is None else progress_age))
print("ttl=%s" % ("" if ttl is None else ttl))
print("ws=%s" % ws)
print("scope=%s" % scope)
print("extra_signals=%s" % extra)
PYEOF
)"
  rc_py=$?
  if [ "$rc_py" -ne 0 ] || [ -z "$parsed" ]; then
    return 0
  fi

  local d_present="" d_stale="" d_owner="" d_step="" d_progress_age="" d_ttl="" d_ws="" d_scope="" d_extra=0
  while IFS='=' read -r k v; do
    case "$k" in
      present) d_present="$v" ;;
      stale) d_stale="$v" ;;
      owner) d_owner="$v" ;;
      step) d_step="$v" ;;
      progress_age_seconds) d_progress_age="$v" ;;
      ttl) d_ttl="$v" ;;
      ws) d_ws="$v" ;;
      scope) d_scope="$v" ;;
      extra_signals) d_extra="$v" ;;
    esac
  done <<STATUS_PARSED
$parsed
STATUS_PARSED

  [ "$d_present" = "true" ] || return 0

  # D-33-E (correction ciblee revue, MAJEUR 2) : verification CROISEE de l'invariant documente
  # en tete de fichier — STALL_WINDOW DOIT rester STRICTEMENT SOUS le ttl reellement en vigueur
  # (VF_DRIVER_TTL au moment ou driver-lock.sh a pose CE lock, pas au moment ou ce script tourne).
  # `driver-lock.sh status` expose deja ce ttl : c'est le SEUL canal disponible pour croiser les
  # deux valeurs a l'execution (STALL_WINDOW et VF_DRIVER_TTL sont deux variables d'environnement
  # INDEPENDANTES, jamais lues par le meme processus sinon). AVERTIT SEULEMENT (stderr, jamais
  # stdout — pas un signal de la famille --hook), n'echoue JAMAIS, ne bloque JAMAIS (ADR-031) :
  # relever VF_STALL_WINDOW au niveau de VF_DRIVER_TTL reintroduit silencieusement la regression
  # deja mesuree (les deux a 1800 rendait le verdict STALL inatteignable), donc merite un signal,
  # mais l'arbitrage reste humain.
  case "$d_ttl" in
    ''|*[!0-9]*) : ;;
    *) [ "$STALL_WINDOW" -ge "$d_ttl" ] && echo "[check-guard-health] AVERTISSEMENT invariant : STALL_WINDOW (${STALL_WINDOW}s) >= ttl du lock (${d_ttl}s) — le verdict STALL redevient inatteignable (regression deja mesuree), baissez VF_STALL_WINDOW sous VF_DRIVER_TTL" >&2 ;;
  esac

  # Portee du verrou retenu (lab partitionne seulement) : le sujet nomme, ou le depot ; vide en lab plat.
  local tag="" suffix=""
  case "$d_scope" in
    compartiment) [ -n "$d_ws" ] && tag=" ws=$d_ws" ;;
    depot) tag=" scope=depot" ;;
  esac
  case "$d_extra" in ''|*[!0-9]*) d_extra=0 ;; esac
  [ "$d_extra" -gt 0 ] && suffix=" (+${d_extra} autre(s) verrou(s) en signal — driver-lock.sh status --all)"

  if [ "$d_stale" = "true" ]; then
    STALL_LINE="[mission-watchdog] abandon detecte — owner=$d_owner step=$d_step$tag (heartbeat mort, lock perime) — ne JAMAIS tuer (ADR-031), takeover disponible si legitime$suffix"
    return 0
  fi

  case "$d_progress_age" in
    ''|*[!0-9]*) return 0 ;;
  esac
  if [ "$d_progress_age" -gt "$STALL_WINDOW" ]; then
    STALL_LINE="[mission-watchdog] stall detecte — owner=$d_owner step=$d_step$tag (progres fige depuis ${d_progress_age}s, heartbeat frais, seuil=${STALL_WINDOW}s) — verifier la session en cours, ne JAMAIS tuer (ADR-031)$suffix"
  fi
  return 0
}

# Sous-controle EXECUTE ICI, AVANT toute decision de sortie liee a l'existence/lisibilite de
# HEALTH_DIR (bug bloquant corrige, D23) — positionne STALL_INDETERMINATE/STALL_LINE consommes
# par les trois points de sortie precoce ci-dessous ET par le verdict final plus bas.
check_driver_stall

# Repertoire absent : etat VERIFIE (aucun garde n'a jamais ecrit de marqueur) — SAUF si le
# sous-controle ci-dessus a lui-meme cree HEALTH_DIR entre-temps pour y ecrire SON PROPRE marqueur
# d'indisponibilite (report_self_unavailable(), cas D19/D20) : dans ce cas la condition
# ci-dessous est deja fausse au moment ou on l'atteint, le flux normal (plus bas) prend le relais
# et le verdict final tranche sur STALL_INDETERMINATE. Ici, HEALTH_DIR est TOUJOURS reste absent :
# soit rien a signaler, soit un stall PUR (D23 — jamais de creation du repertoire pour un stall
# seul).
if [ ! -e "$HEALTH_DIR" ]; then
  if [ "$STALL_INDETERMINATE" -eq 1 ]; then
    indetermine "sous-controle driver-lock indisponible"
  elif [ -n "$STALL_LINE" ]; then
    echo "$STALL_LINE"
    hook_exit 0
  else
    diag "SAIN — aucun repertoire de sante (${HEALTH_DIR} absent)."
    hook_exit 3
  fi
fi

[ -d "$HEALTH_DIR" ] || indetermine "chemin de sante present mais n'est pas un repertoire ($HEALTH_DIR)"

# Listage NON destructif — un `ls -A` qui echoue (permissions retirees) est le signal fiable d'un
# repertoire illisible. Aucun fichier temporaire n'est cree pour capturer le detail de l'erreur
# (ce diagnostic-la n'ecrit rien — la SEULE ecriture de tout le fichier est l'unique marqueur
# d'auto-indisponibilite de report_self_unavailable() plus haut, pas ce chemin-ci) : le diagnostic
# reste generique, le code de sortie (4) porte deja toute l'information qui compte.
LIST_OUT="$(ls -A "$HEALTH_DIR" 2>/dev/null)"; LIST_RC=$?
if [ "$LIST_RC" -ne 0 ]; then
  indetermine "repertoire de sante non listable ($HEALTH_DIR) — permissions insuffisantes ?"
fi

NOW="$(date +%s)"
FRESH_COUNT=0
LATEST_EPOCH=-1
LATEST_SCRIPT=""
LATEST_MOTIF=""

# ISO8601 UTC -> epoch, portable BSD (macOS) ET GNU (Linux) — meme patron que
# plugin/planning-core/scripts/check-planning-state.sh:date_to_epoch, adapte au format horodate.
iso_to_epoch() {
  date -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null || true
}

# GNU (-c) AVANT BSD (-f) : sur GNU, `stat -f` = mode filesystem — il imprime un bloc
# multi-lignes sur stdout PUIS échoue, et la substitution capturait bloc + fallback
# (epoch non numérique → marqueur frais classé perime). BSD echoue proprement sur -c.
# Meme patron que driver-lock.sh:lock_age() — ne pas re-inverser (deja corrige 2 fois).
mtime_epoch() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0
}

if [ -n "$LIST_OUT" ]; then
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    file="$HEALTH_DIR/$entry"
    [ -f "$file" ] || continue

    # Premiere ligne uniquement, champs separes par tabulation (format ECRIT par vf_guard_unavailable :
    # "ts\tscript\tmotif\n"). Un marqueur vide, tronque ou binaire n'interrompt JAMAIS le parcours
    # (D7) : `read` s'arrete proprement (variable(s) vide(s)) sans faire echouer le script.
    ts=""; script=""; motif=""
    IFS=$'\t' read -r ts script motif < "$file" 2>/dev/null || true

    # Marqueur malforme (pas de nom de script exploitable) : repli sur le nom du fichier, motif
    # generique — jamais un plantage, jamais plus d'une ligne au final (D7).
    [ -n "$script" ] || script="${entry%.marker}"
    [ -n "$motif" ] || motif="marqueur illisible ou malforme"

    epoch=""
    [ -n "$ts" ] && epoch="$(iso_to_epoch "$ts")"
    [ -n "$epoch" ] || epoch="$(mtime_epoch "$file")"
    case "$epoch" in ''|*[!0-9]*) epoch=0 ;; esac

    age=$(( NOW - epoch ))
    [ "$age" -lt 0 ] && age=0

    if [ "$age" -le "$WINDOW" ]; then
      FRESH_COUNT=$((FRESH_COUNT + 1))
      if [ "$epoch" -gt "$LATEST_EPOCH" ]; then
        LATEST_EPOCH="$epoch"
        LATEST_SCRIPT="$script"
        LATEST_MOTIF="$motif"
      fi
    fi
  done <<EOF_ENTRIES
$LIST_OUT
EOF_ENTRIES
fi

# Combinaison finale (D-33-A/D-33-E) : STALL_INDETERMINATE prime TOUJOURS — un sous-controle qui
# n'a pas pu tourner ne doit jamais se degrader en vert de complaisance, meme si HEALTH_DIR est par
# ailleurs propre. Ce cas correspond a HEALTH_DIR PRESENT et listable (sinon deja traite plus haut,
# avant le scan des marqueurs) mais avec une dependance indisponible.
if [ "$STALL_INDETERMINATE" -eq 1 ]; then
  indetermine "sous-controle driver-lock indisponible (deja signale sur stderr / marqueur ecrit ci-dessus)"
fi

if [ "$FRESH_COUNT" -eq 0 ] && [ -z "$STALL_LINE" ]; then
  diag "SAIN — aucun marqueur de garde recent dans ${HEALTH_DIR} (fenetre ${WINDOW}s), aucun stall de mission."
  hook_exit 3
fi

# UNE SEULE ligne PAR FAMILLE de signal (marqueurs de garde, stall de mission), jamais une par
# marqueur individuel au sein d'une famille (D6 amende) — au plus DEUX lignes au total, chacune sur
# SA PROPRE ligne, jamais fusionnees.
if [ "$FRESH_COUNT" -gt 0 ]; then
  echo "[guard-health] ${FRESH_COUNT} garde(s) du parc indisponible(s) — le plus recent : ${LATEST_SCRIPT} (${LATEST_MOTIF}) — verifier l'environnement (interprete manquant ?) et envisager /vf-update si le probleme persiste."
fi
if [ -n "$STALL_LINE" ]; then
  echo "$STALL_LINE"
fi
hook_exit 0
