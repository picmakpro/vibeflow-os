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
# Lecture seule STRICTE : ce script ne cree, ne modifie, ni ne supprime AUCUN fichier du
# repertoire de sante — jamais de `rm`, `mv` ni `touch` sur ce repertoire. Un lecteur qui elaguerait
# ses marqueurs serait un correcteur deguise (ADR-031), et l'elagage effacerait la trace au moment
# ou elle devient utile a un humain qui viendrait l'inspecter plus tard.

set -uo pipefail

DEFAULT_HEALTH_DIR="${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}"
HEALTH_DIR="$DEFAULT_HEALTH_DIR"
WINDOW=86400
HOOK=0
QUIET=0

for arg in "$@"; do
  case "$arg" in
    --hook)     HOOK=1 ;;
    --quiet)    QUIET=1 ;;
    --dir=*)    HEALTH_DIR="${arg#*=}" ;;
    --window=*) WINDOW="${arg#*=}" ;;
    -h|--help)  grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-guard-health] argument inconnu : $arg" >&2; exit 64 ;;
  esac
done

[ -n "$HEALTH_DIR" ] || { echo "[check-guard-health] --dir vide" >&2; exit 64; }
case "$WINDOW" in ''|*[!0-9]*) echo "[check-guard-health] --window invalide : $WINDOW" >&2; exit 64 ;; esac

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

indetermine() {
  diag "INDETERMINE, rien n'a ete verifie : $1"
  hook_exit 4
}

# Repertoire absent : etat VERIFIE (aucun garde n'a jamais ecrit de marqueur), pas une indetermination.
if [ ! -e "$HEALTH_DIR" ]; then
  diag "SAIN — aucun repertoire de sante (${HEALTH_DIR} absent)."
  hook_exit 3
fi

[ -d "$HEALTH_DIR" ] || indetermine "chemin de sante present mais n'est pas un repertoire ($HEALTH_DIR)"

# Listage NON destructif — un `ls -A` qui echoue (permissions retirees) est le signal fiable d'un
# repertoire illisible. Aucun fichier temporaire n'est cree pour capturer le detail de l'erreur
# (ce script n'ecrit RIEN, nulle part — pas meme un scratch a nettoyer ensuite) : le diagnostic
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

mtime_epoch() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
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

if [ "$FRESH_COUNT" -eq 0 ]; then
  diag "SAIN — aucun marqueur de garde recent dans ${HEALTH_DIR} (fenetre ${WINDOW}s)."
  hook_exit 3
fi

# UNE SEULE ligne sur stdout, jamais une par marqueur (D6) — nomme le compte, le plus recent avec
# son motif, et la marche a suivre SANS l'executer (l'installation d'un interprete ou la mise a
# jour du plugin sont des gestes humains, ADR-031).
echo "[guard-health] ${FRESH_COUNT} garde(s) du parc indisponible(s) — le plus recent : ${LATEST_SCRIPT} (${LATEST_MOTIF}) — verifier l'environnement (interprete manquant ?) et envisager /vf-update si le probleme persiste."
hook_exit 0
