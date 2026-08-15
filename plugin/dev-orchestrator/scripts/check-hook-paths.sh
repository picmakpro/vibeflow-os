#!/usr/bin/env bash
# check-hook-paths.sh — Un chemin de hook figé à l'install est-il encore vivant ? (5e signal
#                        SessionStart de dev-orchestrator, Phase 30 plan 30-09)
#
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit JAMAIS qu'un hook est
# « cassé » au sens large — seulement qu'un chemin absolu porté par une entrée en forme exec des
# réglages RÉELLEMENT posés N'EXISTE PLUS (ou n'est plus exécutable). C'est le jugement de
# l'utilisateur (ou d'un futur agent) de décider quoi en faire — la dernière ligne du signal
# renvoie déjà vers le geste correctif le plus probable (mettre à jour VibeFlow).
#
# --- LA RAISON D'ÊTRE : L'ANGLE MORT SILENCIEUX DE D-01 -------------------------------------------
# ADR-071 §Décision 2 fait écrire, à l'install, un CHEMIN ABSOLU d'interpréteur `bash` dans le
# `command` des 4 entrées SessionStart de ce module (D-01 de 30-CONTEXT.md, décision ONE-WAY,
# assumée). Le jour où ce chemin devient périmé — interpréteur mis à jour, Git Bash réinstallé
# ailleurs, `brew upgrade`, `settings.local.json` recopié d'une machine à l'autre — le hook cesse
# simplement de tourner. Pas d'erreur, pas de message : juste mort, et rien ne le constate
# aujourd'hui. Ce script EST ce constat.
#
# --- LE PARADOXE D'AMORÇAGE : POURQUOI CE SCRIPT-CI EST INVOQUÉ PAR UN NOM NU --------------------
# Ce filet diagnostique la péremption d'un chemin d'interpréteur figé à l'install. S'il dépendait
# lui-même de cette même pièce (un `command` portant le chemin absolu résolu à l'install), il
# mourrait EXACTEMENT dans le seul cas où il sert — un détecteur d'incendie alimenté par le feu
# qu'il surveille. Son entrée de hook (`plugin/dev-orchestrator/hooks/hooks.json`) porte donc un
# `command` LITTÉRAL de quatre lettres, `bash`, résolu à l'EXÉCUTION par le chemin de recherche du
# système — jamais le jeton d'interpréteur substitué à l'install.
#
# Nommer la dérogation sans lui prêter une autorité qu'elle n'a pas : ADR-071 §Décision 2 exige un
# chemin absolu d'interpréteur résolu et vérifié à l'install pour les entrées exec du périmètre
# dev, et ne prévoit AUCUNE clause d'exception. Cette entrée-ci y DÉROGE, et cette dérogation est
# autorisée par l'APPROBATION HUMAINE DE L'ADDENDUM DU 2026-08-15 — PAS PAR L'ADR ELLE-MÊME, qui
# ne documente pas encore ce cas (reliquat consigné au SUMMARY du plan 30-09 : un amendement
# d'ADR-071, ou une ADR dédiée, est dû). Ne jamais écrire ailleurs que l'ADR ratifie, prévoit ou
# autorise cette entrée — ce serait graver une affirmation fausse dans un artefact durable.
#
# Cette singularité est GARDÉE À LA MACHINE par le cas T9 de
# `plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh`, dont la discriminance est
# prouvée par mutation (m3) : un futur relecteur qui « alignerait » cette entrée sur les 4 autres,
# croyant réparer une incohérence, la fait rougir immédiatement.
#
# LA CONTREPARTIE HONNÊTE, nommée plutôt que laissée implicite : si le harness ne résolvait PAS un
# nom nu sur une machine donnée, ce filet-là ne tournerait pas non plus. C'est un angle mort
# BORNÉ (T-30-09-07, accepté) — il ne concerne que les machines où le substrat exec entier est déjà
# hors service, c'est-à-dire des machines où les 4 autres signaux de ce module sont, eux aussi,
# déjà muets pour une raison différente. Ce script ne prétend pas fermer ce cas-là.
#
# --- CE QUI EST INSPECTÉ — bornage assumé aux entrées en forme exec (A-30-09-2) ------------------
# Une entrée n'est examinée QUE si elle porte un champ `args` (forme exec, ADR-071 §Décision 1).
# Pour chacune : (a) si son `command` est un chemin ABSOLU (commence par `/`, ou par une lettre de
# lecteur suivie de deux-points et d'un séparateur — forme Windows), il doit exister ET être
# exécutable ; (b) chaque élément de `args` qui est un chemin absolu doit exister en tant que
# fichier. Un `command` qui est un NOM NU (comme celui de CE script) est ignoré — résolu par le
# chemin de recherche du système, hors périmètre de ce constat.
# Les entrées en FORME SHELL sont explicitement hors périmètre : extraire un chemin d'une ligne de
# commande demanderait de désambiguïser le quoting et produirait des faux positifs. L'acceptation
# borne CE vecteur seul, elle ne prétend pas couvrir le risque en bloc (ADR-070).
#
# --- CE QUI EST LU — quatre candidats, chacun facultatif -----------------------------------------
# Dans l'ordre : <path>/.claude/settings.json, <path>/.claude/settings.local.json (routage borné
# de D-01 — les DEUX sont obligatoires au balayage, un seul suffirait à rendre le filet aveugle sur
# la moitié du parc), puis le scope UTILISATEUR ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json
# et .../settings.local.json, ces deux derniers écartés par COMPARAISON DE CHAÎNES s'ils désignent
# le même chemin que les deux premiers (pas de canonicalisation : ADR-054 proscrit `realpath`).
# Le scope utilisateur est inclus PAR DÉCISION DE CE PLAN (A-30-09-3) : en scope utilisateur, le
# moteur d'install n'utilise pas le routage local et écrit le chemin absolu directement dans le
# fichier de réglages utilisateur (`vibeflow-update.sh` l.383-393) — l'ignorer rendrait ce filet
# aveugle sur le scope d'install le plus courant. Conséquence assumée : un constat peut porter sur
# une entrée qui n'appartient pas à VibeFlow — ce qui reste un vrai constat, ce hook-là étant mort
# lui aussi.
#
# Usage:
#   check-hook-paths.sh [--path <dir>] [--hook] [--quiet]
# Defaults: --path .
#
# Exit codes (contrat interne, s'applique SANS --hook) :
#   0  = signal [hook-paths] émis sur stdout (au moins un chemin de hook introuvable)
#   3  = rien à signaler (tout résout, ou aucun fichier de réglages, ou aucune entrée en forme
#        exec dans les fichiers lus)
#   1  = le script n'a PAS PU rendre de verdict (fichier de réglages illisible/JSON invalide, ou
#        aucun interpréteur Python utilisable) — diagnostic sur stderr, stdout vide. Cette issue
#        DOMINE un éventuel constat partiel : un verdict incomplet n'est jamais présenté comme
#        complet (QUAL-01, troisième issue — jamais un faux PASS silencieux).
#   64 = argument inconnu, --path sans valeur, ou --hook + --quiet ensemble
#
# --hook : sous ce drapeau, le SEUL code de silence interne (3) devient 0 à la frontière du
# harness (hook_exit(), même contrat que check-doc-drift.sh/check-gsd-config.sh : réplique à
# l'identique, ni renommage global ni lanceur intermédiaire, D-06). 1, 0 et 64 ressortent
# INCHANGÉS. Le code 2 n'est JAMAIS émis, sur aucune branche — ce filet est advisory par
# construction (ADR-031, D-02) : il constate, il ne répare rien, il ne bloque jamais le démarrage
# de session.
#
# Sur le chemin nominal, le stdout de ce script est STRICTEMENT VIDE (zéro octet) : sur
# SessionStart, tout stdout émis à code 0 est injecté comme contexte de session — un filet bavard
# coûterait des jetons à CHAQUE démarrage (docs/HOOKS-CONTRAT-SORTIE.md §3). Les diagnostics
# humains vont systématiquement sur stderr.
set -uo pipefail

ROOT="."
HOOK=0
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-hook-paths] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    --hook) HOOK=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-hook-paths] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

# Gate de mutuelle exclusion, avant toute autre logique (même position que dans les scripts voisins).
if [ "$HOOK" -eq 1 ] && [ "$QUIET" -eq 1 ]; then
  echo "[check-hook-paths] --hook et --quiet sont mutuellement exclusifs" >&2
  exit 64
fi

say() { [ "$QUIET" -eq 1 ] || echo "[check-hook-paths] $*" >&2; }

# --- Traduction du silence interne vers le harness (D-06, uniquement sous --hook) ---------------
# hook_exit <code> : sous --hook, le SEUL code de silence interne (3) devient 0 à la frontière du
# harness — une TRADUCTION, jamais un masquage : elle ne touche ni le code d'erreur d'argument
# (64), ni 0, ni le code 1. Sans --hook (CLI, suites de tests), le code reçu ressort inchangé. Même
# contrat, même nom, même place que check-doc-drift.sh/check-gsd-config.sh. Voir
# docs/HOOKS-CONTRAT-SORTIE.md §2.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}

# >>> vf-portable:locator (bloc canonique, contrat PR #29 §3 / D-04 — Phase 30 plan 30-05. Ne
# pas retaper à la main : copier depuis plugin/_internal/lib/vf-portable.sh entre ces deux
# marqueurs — seul le préfixe de message varie d'un consommateur à l'autre (identité vérifiée
# par somme de contrôle dans test-vf-portable.sh).
# Préfixe de ce consommateur : [check-hook-paths]
#   1. $(dirname "$0")/vf-portable.sh              → install à plat (TARGET_ROOT/scripts)
#   2. $(dirname "$0")/lib/vf-portable.sh           → engine dans le cache du plugin
#   3. remontée bornée (<= 4 niveaux) depuis $(dirname "$0") vers _internal/lib/vf-portable.sh
#      → module/installeur exécuté depuis le dépôt, quelle que soit sa profondeur réelle
#   4. $(dirname "$0")/../../scripts/vf-portable.sh → extracteur kpi copié
# Aucun candidat trouvé → message préfixé en stderr + sortie non-zéro. Jamais un `source` muet.
_vf_portable_lib=""
_vf_portable_dir="$(dirname "$0")"
for _vf_portable_cand in "$_vf_portable_dir/vf-portable.sh" "$_vf_portable_dir/lib/vf-portable.sh"; do
  [ -f "$_vf_portable_cand" ] && { _vf_portable_lib="$_vf_portable_cand"; break; }
done
if [ -z "$_vf_portable_lib" ]; then
  _vf_portable_walk="$_vf_portable_dir"
  for _vf_portable_i in 1 2 3 4; do
    _vf_portable_walk="$_vf_portable_walk/.."
    if [ -f "$_vf_portable_walk/_internal/lib/vf-portable.sh" ]; then
      _vf_portable_lib="$_vf_portable_walk/_internal/lib/vf-portable.sh"
      break
    fi
  done
fi
if [ -z "$_vf_portable_lib" ] && [ -f "$_vf_portable_dir/../../scripts/vf-portable.sh" ]; then
  _vf_portable_lib="$_vf_portable_dir/../../scripts/vf-portable.sh"
fi
if [ -z "$_vf_portable_lib" ]; then
  echo "[check-hook-paths] vf-portable.sh introuvable (candidats épuisés — installer/mettre à jour vibeflow)" >&2
  exit 1
fi
# shellcheck source=/dev/null
. "$_vf_portable_lib"
unset _vf_portable_lib _vf_portable_dir _vf_portable_cand _vf_portable_walk _vf_portable_i
# <<< vf-portable:locator

# --- Résolution de l'interpréteur — par la lib, jamais à la main ---------------------------------
# Profil COMPLET (vf_resolve_python SANS --fast) : ce script tourne une fois par session, c'est
# exactement le cas d'usage que la lib prescrit nommément pour ce profil (SessionStart, install).
# Jamais de repli sur `command -v python3` local — c'est la dette exacte que le plan 30-05 a soldée.
if ! vf_resolve_python; then
  say "aucun interpréteur Python utilisable (cascade python3 → python → py -3) — verdict non rendu."
  vf_guard_unavailable "$0" "aucun interpréteur Python utilisable pour check-hook-paths.sh"
  hook_exit 1
fi

# --- Candidats — quatre fichiers de réglages, chacun facultatif ----------------------------------
PROJ_SETTINGS="$ROOT/.claude/settings.json"
PROJ_LOCAL="$ROOT/.claude/settings.local.json"
USER_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
USER_SETTINGS="$USER_DIR/settings.json"
USER_LOCAL="$USER_DIR/settings.local.json"

CANDIDATES=("$PROJ_SETTINGS" "$PROJ_LOCAL")
[ "$USER_SETTINGS" != "$PROJ_SETTINGS" ] && CANDIDATES+=("$USER_SETTINGS")
[ "$USER_LOCAL" != "$PROJ_LOCAL" ] && CANDIDATES+=("$USER_LOCAL")

# --- Le balayage vit dans un bloc Python invoqué par vf_python (mécanique, D-06 tâche 7) ---------
# Chargé par `read -r -d ''` sur un heredoc à délimiteur quoté — SURTOUT PAS par
# `PYPROG=$(cat <<'PYEOF' … )` : bash 3.2 (macOS, ADR-054) scanne le corps d'un here-doc imbriqué
# dans une substitution de commande à la recherche de quotes, et la moindre apostrophe française
# dans un commentaire (« l'inventaire », « n'a pas ») y ouvre une chaîne fantôme et casse le script
# entier. `read -r -d ''` n'est pas une substitution de commande : le piège ne s'applique pas.
#
# Le bloc rend un rapport LIGNE À LIGNE sur SON stdout, capturé par le shell : une ligne
# `EXAMINED <n>` (nombre d'entrées en forme exec réellement examinées), une ligne `FILES <n>`
# (nombre de fichiers réellement lus et parsés), une ligne `PARSE_ERROR <fichier> <motif>` par
# fichier illisible/JSON invalide, une ligne `FINDING <fichier> <événement>/<matcher> <champ>
# <chemin>` par chemin introuvable — champs séparés par une TABULATION (le contrat visuel
# `fichier|événement/matcher|champ|chemin` de la doc de plan ; la tabulation est le séparateur
# réel, plus robuste qu'un `|` littéral qui pourrait apparaître dans un chemin Windows). Ce bloc
# sort TOUJOURS 0 : c'est un rapporteur, la décision de code de sortie appartient au shell — un
# seul point de décision, pas deux. Toute exception inattendue pendant la lecture d'UN fichier est
# convertie en PARSE_ERROR pour CE fichier (jamais une exception non rattrapée qui ferait sortir le
# bloc en dehors de {0}) ; la boucle d'ouverture/parsing de chaque candidat est la SEULE portion
# protégée, précisément parce que c'est la seule qui touche une entrée non maîtrisée (le fichier de
# réglages).
IFS= read -r -d '' PYPROG <<'PYEOF' || true
import json, os, re, sys

candidats = sys.argv[1:]
RE_LECTEUR = re.compile(r'^[A-Za-z]:[\\/]')


def est_absolu(chemin):
    """Un chemin absolu commence par une barre oblique, ou porte une lettre de lecteur suivie de
    deux-points et d'un séparateur (forme Windows). Ni l'un ni l'autre : nom nu, hors périmètre —
    résolu par le chemin de recherche du système, jamais par ce script."""
    if not isinstance(chemin, str) or not chemin:
        return False
    if chemin.startswith('/'):
        return True
    return bool(RE_LECTEUR.match(chemin))


examined = 0
files_read = 0
lignes = []

for chemin in candidats:
    if not chemin or not os.path.isfile(chemin):
        # Fichier absent : facultatif par construction (routage borné de D-01) — silencieux,
        # jamais un PARSE_ERROR. Seul un fichier PRÉSENT mais illisible/invalide en est un.
        continue
    try:
        with open(chemin, encoding='utf-8') as f:
            brut = f.read()
        data = json.loads(brut)
        if not isinstance(data, dict):
            raise ValueError('racine JSON non objet')
    except Exception as e:
        motif = str(e) or type(e).__name__
        lignes.append('PARSE_ERROR\t%s\t%s' % (chemin, motif))
        continue

    files_read += 1
    hooks = data.get('hooks')
    if not isinstance(hooks, dict):
        hooks = {}

    for evenement, groupes in hooks.items():
        if not isinstance(groupes, list):
            continue
        for g in groupes:
            if not isinstance(g, dict):
                continue
            matcher = g.get('matcher')
            matcher_label = matcher if isinstance(matcher, str) and matcher else '(aucun)'
            entrees = g.get('hooks')
            if not isinstance(entrees, list):
                continue
            for h in entrees:
                if not isinstance(h, dict) or 'args' not in h:
                    continue  # bornage : seule la forme exec (args present) est examinee
                examined += 1
                cmd = h.get('command', '')
                if est_absolu(cmd):
                    if not (os.path.isfile(cmd) and os.access(cmd, os.X_OK)):
                        lignes.append('FINDING\t%s\t%s/%s\tcommand\t%s' % (
                            chemin, evenement, matcher_label, cmd))
                args = h.get('args')
                if isinstance(args, list):
                    for a in args:
                        if est_absolu(a) and not os.path.isfile(a):
                            lignes.append('FINDING\t%s\t%s/%s\targs\t%s' % (
                                chemin, evenement, matcher_label, a))

print('EXAMINED\t%d' % examined)
print('FILES\t%d' % files_read)
for l in lignes:
    print(l)
PYEOF

RAW="$(vf_python -c "$PYPROG" "${CANDIDATES[@]}" 2>/dev/null)"

# --- Parsing du rapport (côté shell, champs tabulés) ----------------------------------------------
EXAMINED=0
FILES_READ=0
N_PARSE=0
N_FIND=0
PARSE_FILE=()
PARSE_MOTIF=()
FIND_FILE=()
FIND_EVMATCH=()
FIND_FIELD=()
FIND_PATH=()

while IFS="$(printf '\t')" read -r kind f1 f2 f3 f4; do
  [ -n "$kind" ] || continue
  case "$kind" in
    EXAMINED) EXAMINED="$f1" ;;
    FILES) FILES_READ="$f1" ;;
    PARSE_ERROR)
      PARSE_FILE[$N_PARSE]="$f1"
      PARSE_MOTIF[$N_PARSE]="$f2"
      N_PARSE=$((N_PARSE + 1)) ;;
    FINDING)
      FIND_FILE[$N_FIND]="$f1"
      FIND_EVMATCH[$N_FIND]="$f2"
      FIND_FIELD[$N_FIND]="$f3"
      FIND_PATH[$N_FIND]="$f4"
      N_FIND=$((N_FIND + 1)) ;;
  esac
done <<EOF
$RAW
EOF

# --- Décision du shell — trois issues, dans cet ordre de priorité (tâche 8) -----------------------
# 1) Erreur d'analyse : DOMINE un éventuel constat — un verdict partiel présenté comme complet
#    serait précisément le faux PASS interdit par QUAL-01. Rien sur stdout, rc 1 (jamais 2).
if [ "$N_PARSE" -gt 0 ]; then
  i=0
  while [ "$i" -lt "$N_PARSE" ]; do
    say "${PARSE_FILE[$i]} : ${PARSE_MOTIF[$i]} — le verdict de ce filet n'a pas pu être rendu."
    i=$((i + 1))
  done
  hook_exit 1
fi

# 2) Au moins un constat : signal borné à 7 lignes de stdout au total (en-tête + détails + éventuelle
#    ligne de troncature + orientation). Quand le nombre de constats dépasse 5, le nombre de lignes
#    de détail affichées est réduit à 4 pour laisser la place à la ligne de troncature — le total ne
#    dépasse jamais 7, quel que soit le nombre réel de constats.
if [ "$N_FIND" -gt 0 ]; then
  if [ "$N_FIND" -le 5 ]; then
    SHOW=$N_FIND
    TRUNC=0
  else
    SHOW=4
    TRUNC=$((N_FIND - 4))
  fi
  printf '%s\n' "[hook-paths] ${N_FIND} chemin(s) de hook introuvable(s) — ces hooks ne tournent plus, sans erreur visible."
  i=0
  while [ "$i" -lt "$SHOW" ]; do
    printf '  - %s · %s · %s → %s\n' "${FIND_FILE[$i]}" "${FIND_EVMATCH[$i]}" "${FIND_FIELD[$i]}" "${FIND_PATH[$i]}"
    i=$((i + 1))
  done
  if [ "$TRUNC" -gt 0 ]; then
    printf '… et %s autre(s).\n' "$TRUNC"
  fi
  printf '→ une mise à jour de VibeFlow réaligne ces chemins.\n'
  hook_exit 0
fi

# 3) Rien à signaler : silence fort, mesuré en octets par l'appelant (aucun printf sur stdout ici).
#    Le diagnostic stderr cite le nombre d'entrées examinées et de fichiers lus — la preuve lisible
#    qu'on n'a pas regardé le vide (garde anti-vert-à-vide, T8 de la suite dédiée).
say "${EXAMINED} entrée(s) en forme exec examinée(s) sur ${FILES_READ} fichier(s) de réglages lus — rien à signaler."
hook_exit 3
