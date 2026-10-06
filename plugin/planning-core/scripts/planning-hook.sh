#!/usr/bin/env bash
# planning-hook.sh — hook central de planning-core (Phase 45, P45-D-15 : UN SEUL script pour les gates
# d'écriture et le cloisonnement par rôle ; Phase 46, P46-D-09 : un MODE par événement). Il n'agit que
# dans un lab adhérent `cycles-v1` (P45-D-01a) ; ailleurs — labs dev, ce dépôt compris — il ne sort
# RIEN et rend 0 (P45-D-04, P46-D-16). La racine du lab est dérivée du chemin écrit (à défaut du cwd du
# payload, à défaut du cwd physique du processus), jamais de $CLAUDE_PROJECT_DIR (P45-D-12) ; pour un
# FileChanged, du `file_path` de premier niveau du payload.
#
# Cinq événements, UNE commande enregistrée (hooks.json), le champ `hook_event_name` du payload
# aiguillant (absent : PreToolUse, compatibilité des payloads existants ; inconnu : silence, limite (aq)) :
#   PreToolUse    G1…G7, rôle, G3, G4, G4′ (sur SubagentHandback) — refus : deny JSON, code 0
#   SubagentStop  repli de G4′ hors mode auto — refus : `decision: "block"` JSON, code 0, JAMAIS le code 2 (P46-D-10, #60490)
#   SessionStart, CwdChanged, FileChanged   D1 (46-07) : ne refusent JAMAIS ; toute erreur sort en silence, code 0 (fail-open déclaré :
#                 une trace perdue est rattrapée par la réconciliation de D1, P46-D-10). SessionStart et CwdChanged renvoient la liste
#                 surveillée (`watchPaths`, fichier par fichier) ; FileChanged ne sort rien et trace ce qu'il voit au journal de D1 ; SessionStart
#                 (source `startup`) ajoute UNE ligne agrégée du canary de juge à son `additionalContext` (46-09, P46-D-06)
# La décision dans le doute (N-01, `decider_dans_le_doute`) ne vaut que pour PreToolUse : tout autre événement en doute
# sort en silence.
#
# Entrée : le payload JSON du harnais sur stdin. Sortie : rien, ou UN objet JSON (PreToolUse : hookSpecificOutput,
# refus permissionDecision deny, avertissement additionalContext ; SubagentStop : decision block ; SessionStart, CwdChanged :
# watchPaths et additionalContext, jamais une décision), toujours code 0 —
# jamais exit 2 (P45-D-08, DIV-2, P46-D-10). Aucun message ne porte de chemin absolu hors du lab, ni « no such file »,
# ni « can't open » (#60490).
#
# Contrat des codes du LANCEUR (bash) — il ne décide de RIEN : tout code non nul est repris par la
# commande enregistrée dans hooks.json, qui tranche elle-même (fail-closed dans un lab adhérent,
# silence ailleurs — P45-D-06, P45-D-06a) :
#    0  décidé (stdout vide ou UN objet JSON)
#    3  erreur Python AVANT que l'adhésion soit connue (stdout vide)
#   70  mktemp impossible
#   71  lecture de stdin impossible
#   72  aucun interpréteur Python (python3 puis python, ADR-054)
#   73  échéance interne du cœur dépassée (ECHEANCE_COEUR_S) ou lanceur disparu : stdout vide (lot A, H2)
#
# Livraison — voie (a) de P44-D-14 : le cœur Python est embarqué en heredoc quoté (patron
# recalc-planning.sh) ; l'installeur ne pose pas de fichier .py. Le programme passe par stdin, le
# payload par un fichier de transport mktemp (0600, supprimé par un trap), jamais par argv.
#
# Aucune variable d'environnement ne change l'armement ni l'adhésion (P45-D-12a) : le lanceur lit
# TMPDIR pour choisir où poser son fichier de transport, XDG_CACHE_HOME puis HOME pour les passer en
# arguments au cœur — chacune choisit un CHEMIN, jamais une décision (décisions du manager
# vf-dev-manager, 2026-09-30 : amendement de R-ENV-02). XDG_CACHE_HOME ne sert qu'au chemin du journal
# d'observation ; HOME sert à DEUX chemins et à eux seuls : le repli du journal (`<HOME>/.cache/...`) et
# la racine de résolution des agents du COMPTE (`<HOME>/.claude/agents/`, puis `<HOME>/.claude/plugins/`
# pour un agent de plugin, P45-D-05b ; amendement du manager du 2026-09-30, plan 45-08). Un HOME différent
# change la résolution d'un agent du compte, jamais l'adhésion ni l'état d'armement.
# Le cœur Python ne lit AUCUNE variable d'environnement (ni os.environ, ni expanduser, ni expandvars).
#
# Arguments du cœur Python (positions fixes, sys.argv) : [1] fichier de transport du payload (ou, en mode
# diagnostic, la définition d'agent à classer), [2] valeur de XDG_CACHE_HOME (chaîne vide si non définie),
# [3] valeur de HOME (idem), [4] `--classer` ou `--juges` en mode diagnostic, vide sinon.
#
# Mode de diagnostic (45-08) : `planning-hook.sh --classer <agent.md>` imprime UNE ligne JSON
# {"role": …, "allowlist": […], "disallowed": […]} et rend 0, sans lire stdin ni rien décider. La commande
# enregistrée ne passe jamais d'argument : le chemin de décision est inchangé.
# Mode de diagnostic du canary de juge (46-09, C-16) : `planning-hook.sh --juges <racine du lab>` imprime UNE ligne JSON
# {"prouves": […], "laxistes": […], "sans_preuve": [{"juge": …, "motif": …}]} et rend 0, sans lire stdin ni rien décider
# (patron de `--classer` ; il ne vérifie pas l'adhésion : la racine est celle que l'appelant désigne).
set -u

if [ "${1:-}" = "--classer" ] || [ "${1:-}" = "--juges" ]; then
  T="${2:-}"
else
  umask 077
  T="$(mktemp "${TMPDIR:-/tmp}/vf-planning-hook.XXXXXX")" || exit 70
  trap 'rm -f "$T"' EXIT
  cat > "$T" || exit 71
fi

# Résolution de l'interpréteur (ADR-054) : stub Microsoft Store détecté par chemin, repli python.
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then
      PYBIN=python
    else
      exit 72
    fi
    ;;
esac

"$PYBIN" -I -S - "$T" "${XDG_CACHE_HOME:-}" "${HOME:-}" "${1:-}" <<'PY_PLANNING_HOOK_EOF'
import collections
import datetime
import json
import os
import posixpath
import re
import shlex
import stat
import sys
import time
import urllib.parse

try:
    import fcntl
except ImportError:
    fcntl = None

# --- Constantes du contrat -----------------------------------------------------------------
SCHEMA_ADHESION = "cycles-v1"
# Motif de la couche shell de repli (F-02, audit de sécurité final du 2026-10-01) : la commande enregistrée de hooks.json reconnaît un lab
# adhérent par `grep -a -q -E '<ce motif>' config.json` (ligne à ligne, sans décodage JSON). Constante PARTAGÉE : G6 n'admet l'écriture
# par outil d'un config.json que si le nouveau contenu satisfait AUSSI ce motif, sinon une panne du cœur taisait tous les gates d'un lab que
# le JSON dit adhérent et que le grep ne reconnaît pas. Une suite compare cette constante au motif de hooks.json : jamais une seconde copie libre.
MOTIF_ADHESION_REPLI = '"planning_version"[[:space:]]*:[[:space:]]*"cycles-v1"'  # motif-adhesion-repli
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
# Lot A (H2 ; décisions du manager vf-dev-manager, 2026-10-01) : le cœur se borne lui-même. Passé l'échéance, ou si le lanceur
# meurt, il sort sur CODE_ECHEANCE sans rien imprimer : la couche shell de la commande enregistrée ferme alors sous adhésion
# (P45-D-06a) et reste silencieuse ailleurs. Le délai du harnais (20 s) ne tue que le shell, jamais le Python orphelin.
ECHEANCE_COEUR_S = 8.0
PAS_SURVEILLANCE_S = 0.5
CODE_ECHEANCE = 73
# --- Événements (Phase 46, P46-D-09) : un mode par `hook_event_name` ; la table des modes est plus bas (`MODES_EVENEMENT`).
EVT_PRETOOLUSE = "PreToolUse"
EVT_SUBAGENT_STOP = "SubagentStop"
EVT_SESSION_START = "SessionStart"
EVT_CWD_CHANGED = "CwdChanged"
EVT_FILE_CHANGED = "FileChanged"
EVENEMENTS_CONNUS = (EVT_PRETOOLUSE, EVT_SUBAGENT_STOP, EVT_SESSION_START, EVT_CWD_CHANGED, EVT_FILE_CHANGED)
# Un message de sortie ne contient jamais ces fragments (P46-D-10, #60490 : un refus qui les porte est lu comme « script absent »).
FRAGMENTS_INTERDITS_SORTIE = ("no such file", "can't open")

# --- Table d'armement (P45-D-03a) : l'état de chaque gate vit ICI, dans le code livré, jamais dans
# un fichier du lab ni dans une variable d'environnement (P45-D-01, P45-D-12a). Une constante par
# gate, une ligne chacune (l'outil de rejeu et les mutants réécrivent ces lignes sur une copie).
# Valeurs admises : `observe` (le gate calcule, journalise, laisse passer) | `armed` (le gate refuse).
ARMEMENT_G6 = "armed"  # etape-1
ARMEMENT_G5 = "armed"  # etape-1
ARMEMENT_G1 = "armed"  # etape-2
ARMEMENT_G7 = "armed"  # etape-3
ARMEMENT_ROLE = "armed"  # etape-4
ARMEMENT_G3 = "observe"  # etape-5
ARMEMENT_G4 = "observe"  # etape-5
ARMEMENT_G4P = "observe"  # etape-6
G2_MODE = "avertit"
ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",), ("G3", "G4"), ("G4P",))
TABLE_ARMEMENT = {"G6": ARMEMENT_G6, "G5": ARMEMENT_G5, "G1": ARMEMENT_G1, "G7": ARMEMENT_G7, "ROLE": ARMEMENT_ROLE,
                  "G3": ARMEMENT_G3, "G4": ARMEMENT_G4, "G4P": ARMEMENT_G4P}


# --- Échéance interne et surveillance du lanceur (lot A, H2) ------------------------------------------------------
_ECHEANCE = {"figee": False}


def figer_echeance():
    """Désarme l'échéance (F-03, audit de sécurité final du 2026-10-01) : à partir d'ici le code de sortie du cœur ne dépend plus du
    minuteur. L'échéance de ECHEANCE_COEUR_S ne vaut qu'AVANT l'émission de la décision (code 73, refus du fail-closed) ; une décision
    imprimée avec le code 0 est livrée telle quelle. Sans cela, un SIGALRM arrivé après l'impression tuait le cœur (73, ou 142 une fois
    l'interpréteur en fin de vie) et la commande enregistrée jetait la décision. Le drapeau est posé AVANT le désarmement : un signal
    déjà parti trouve le drapeau et ne fait rien."""
    _ECHEANCE["figee"] = True
    try:
        import signal
        if hasattr(signal, "setitimer") and hasattr(signal, "ITIMER_REAL"):
            signal.setitimer(signal.ITIMER_REAL, 0, 0)
    except (ImportError, ValueError, OSError):
        pass


def armer_echeance():
    """Arme la surveillance du cœur : toutes les PAS_SURVEILLANCE_S secondes, sortie immédiate sur CODE_ECHEANCE (aucune sortie)
    si ECHEANCE_COEUR_S est dépassée ou si le processus parent n'est plus le lanceur (il est mort : un Python orphelin ne survit
    pas à son kill). Minuterie du système (SIGALRM) : un gestionnaire de signal passe aussi pendant une expression régulière, là où
    un fil ne passerait pas (le GIL) ; sans SIGALRM (Windows), repli sur un fil démon."""
    debut = time.monotonic()
    parent = os.getppid()

    def surveiller(*_ignores):
        if _ECHEANCE["figee"]:  # echeance-fige-garde
            return
        if time.monotonic() - debut >= ECHEANCE_COEUR_S:  # echeance-delai
            os._exit(CODE_ECHEANCE)
        if os.getppid() != parent:  # echeance-parent
            os._exit(CODE_ECHEANCE)

    try:
        import signal
        if hasattr(signal, "setitimer") and hasattr(signal, "SIGALRM"):
            signal.signal(signal.SIGALRM, surveiller)
            signal.setitimer(signal.ITIMER_REAL, PAS_SURVEILLANCE_S, PAS_SURVEILLANCE_S)
            return
    except (ImportError, ValueError, OSError):
        pass
    import threading

    def boucle():
        while True:
            time.sleep(PAS_SURVEILLANCE_S)
            surveiller()

    fil = threading.Thread(target=boucle)
    fil.daemon = True
    fil.start()


# --- Lecture du payload et dérivation du lab ------------------------------------------------
def _premier_gagne(paires):
    """Clé en double : la PREMIÈRE occurrence gagne, comme la couche shell de la commande
    enregistrée (elle garde la première correspondance de chaque clé)."""
    resultat = {}
    for cle, valeur in paires:
        if cle not in resultat:
            resultat[cle] = valeur
    return resultat


def lire_payload(chemin):
    """Lit le payload du fichier de transport, puis EFFACE ce fichier (lot A, H2 : le trap du lanceur ne tourne pas sous SIGKILL, le
    contenu du payload ne reste pas sur disque le temps du calcul). Octets invalides : remplacés (jamais une exception pour un
    contenu que le harnais a déjà accepté)."""
    with open(chemin, "rb") as fh:
        octets = fh.read()
    try:
        os.unlink(chemin)  # transport-efface
    except OSError:
        pass
    texte = octets.decode("utf-8", "replace")
    payload = json.loads(texte, object_pairs_hook=_premier_gagne)
    if not isinstance(payload, dict):
        raise ValueError("payload non objet")
    return payload


def cible_de(payload, home=""):
    """(chemin écrit absolu ou None, cwd du payload ou None, formes physiques supplémentaires à juger). Clé `file_path`, sinon
    `notebook_path`, dans `tool_input`. Un chemin relatif est JOINT au cwd du payload (à défaut au
    cwd physique du processus), comme la couche shell (limite h) : les deux couches rattachent
    le chemin au même lab. Un chemin qui commence par `~` n'est JAMAIS lu comme relatif au cwd (N-03, re-audit
    du 2026-10-01) : `~` et `~/…` sont développés en HOME, argument du lanceur (le cœur ne lit pas l'environnement, R-ENV-02), de façon
    identique à la couche shell ; `~utilisateur/…`, ou un HOME absent ou non absolu, lève ValueError : la décision dans le doute
    (`decider_dans_le_doute`) prend la main. Une valeur de plus de BORNE_VALEUR caractères est lue sous deux formes (réduite
    lexicalement, physique) rendues en temps linéaire ; si l'une reste trop longue, ValeurTropLongue (décision dans le doute). Un chemin
    RELATIF sous un cwd de plus de BORNE_VALEUR caractères n'est jamais résolu contre le cwd du processus : ValueError (N3-02) ; un cwd
    long, sinon, est remplacé par sa forme réduite (`cwd_borne`)."""
    cwd = payload.get("cwd")
    if not isinstance(cwd, str):
        cwd = None
    entree = payload.get("tool_input")
    ecrit = None
    if isinstance(entree, dict):
        for cle in ("file_path", "notebook_path"):
            valeur = entree.get(cle)
            if isinstance(valeur, str):
                ecrit = valeur
                break
    longue = ecrit is not None and len(ecrit) > BORNE_VALEUR  # valeur-longue
    if ecrit is not None and ecrit.startswith("~"):  # tilde-developpe
        if (ecrit == "~" or ecrit.startswith("~/")) and isinstance(home, str) and home.startswith("/"):
            ecrit = home.rstrip("/") + ecrit[1:]
        else:
            raise ValueError("tilde non résolu")
    cwd_long = cwd is not None and len(cwd) > BORNE_VALEUR
    if ecrit is not None and not ecrit.startswith("/"):
        if cwd_long:  # cwd-long
            raise ValueError("chemin relatif sous un cwd trop long")  # N3-02 : jamais résolu contre le cwd du processus
        base = cwd if cwd is not None else os.path.realpath(os.getcwd())
        ecrit = base + "/" + ecrit
    variantes = []
    if longue:
        # N3-01 (re-audit 3 du 2026-10-02) : une valeur de plus de BORNE_VALEUR caractères n'est jamais analysée telle quelle (realpath et
        # racine_lab sont quadratiques en profondeur). Elle est lue sous DEUX formes, en temps linéaire, et refusée si l'UNE des deux
        # l'est : la forme RÉDUITE lexicalement (`posixpath.normpath`, ce que fait un harnais qui normalise avant l'appel système) et la
        # forme PHYSIQUE (`resoudre_lineaire`, ce que fait l'ancienne analyse exacte, un `..` après un lien symbolique remontant le lien).
        # Chacune qui tient sous la borne est analysée comme une valeur courte ; si l'une reste trop longue, décision dans le doute.
        joint = ecrit
        ecrit = reduire_lexicalement(joint)  # reduction-lexicale
        # Un chemin qui reste RELATIF (cwd du payload lui-même relatif) n'a pas de lab : `racine_lab` le rend None, comme avant.
        physique, existant = resoudre_lineaire(joint) if joint.startswith("/") else (ecrit, "")  # forme-physique
        if len(ecrit) > BORNE_VALEUR or len(physique) > BORNE_VALEUR:  # aiguillage-longue
            raise ValeurTropLongue([existant, resoudre_lineaire(ecrit)[1] if ecrit.startswith("/") else ""])
        if physique != ecrit:
            variantes.append(physique)  # variante-physique
    if cwd_long:
        cwd = cwd_borne(cwd)
        payload["cwd"] = cwd
    return (ecrit, cwd, variantes)


def chemin_brut(payload):
    """Valeur brute (chaîne) de `file_path`, sinon `notebook_path`, ou None : sans aucune analyse du chemin, donc qui ne peut pas lever."""
    entree = payload.get("tool_input")
    if isinstance(entree, dict):
        for cle in ("file_path", "notebook_path"):
            valeur = entree.get(cle)
            if isinstance(valeur, str):
                return valeur
    return None


BORNE_VALEUR = 4096  # même borne que la couche shell de hooks.json (PATH_MAX de Linux)


class ValeurTropLongue(ValueError):
    """Une valeur qui reste plus longue que BORNE_VALEUR une fois réduite : elle porte l'ANCÊTRE EXISTANT de chacune de ses deux formes
    (réduite lexicalement, physique), le seul morceau qui dit dans quel lab elle tombe sans parcourir la valeur entière."""

    def __init__(self, ancetres):
        ValueError.__init__(self, "valeur trop longue après réduction")
        self.ancetres = ancetres


def reduire_lexicalement(chemin):
    """Forme réduite lexicalement (`.`, `..`, `//` retirés, sans toucher au disque) en temps LINÉAIRE : `posixpath.normpath` (N3-01,
    re-audit 3 du 2026-10-02). C'est ce que fait le harnais d'un chemin avant l'appel système ; elle diffère de la résolution physique
    (realpath) quand un `..` suit un lien symbolique (limite F2, déclarée)."""
    return posixpath.normpath(chemin)


def cwd_borne(cwd):
    """`cwd` de plus de BORNE_VALEUR caractères, jamais parcouru tel quel : sa forme réduite lexicalement si elle est absolue et tient
    sous la borne (un lab nommé par un cwd qui descend puis remonte reste un lab) ; sinon le cwd physique du processus, comme la couche
    shell (None s'il est illisible)."""
    if cwd.startswith("/"):
        reduit = reduire_lexicalement(cwd)
        if len(reduit) <= BORNE_VALEUR:
            return reduit
    try:
        return os.getcwd()
    except OSError:
        return None


BORNE_LIENS = 40  # comme le noyau (ELOOP) : au-delà, un lien n'est plus suivi (realpath, lui, détecte la boucle à la première répétition ; l'écart ne porte que sur des boucles denses, que le noyau rejette en ELOOP)


def resoudre_lineaire(chemin):
    """Résolution PHYSIQUE d'un chemin absolu (liens suivis sur la partie existante, `..` après un lien remontant le lien), comme
    `os.path.realpath` non strict, mais en temps quasi LINÉAIRE : le chemin se consomme composant par composant sur une pile, et un
    composant n'est testé sur le disque (`lstat`) que si TOUS ses ancêtres existent. Un descendant d'un composant absent n'existe pas :
    il n'est jamais testé, donc une descente de 130 000 composants absents ne coûte pas 130 000 appels sur des chemins qui grossissent
    (le coût quadratique de realpath). Le nombre d'appels est borné par la profondeur RÉELLE du disque (PATH_MAX). Au-delà de BORNE_LIENS
    liens suivis (boucle), le lien n'est plus suivi ; une erreur d'`lstat` (absent, trop long) vaut « n'existe pas » ; un NUL lève
    ValueError (décision dans le doute). Rend (chemin physique, plus long préfixe qui existe) : le second est l'ancêtre existant, dont
    `racine_lab` tire le lab sans parcourir le reste."""
    restant = collections.deque(chemin.split("/"))
    pile = []
    existe = 0  # longueur du plus long préfixe de `pile` qui existe
    liens = 0
    while restant:
        c = restant.popleft()
        if c == "" or c == ".":
            continue
        if c == "..":
            if pile:
                pile.pop()
            if existe > len(pile):
                existe = len(pile)
            continue
        pile.append(c)
        if existe != len(pile) - 1:
            continue  # un ancêtre est absent : ce composant n'existe pas, inutile de le tester
        courant = "/" + "/".join(pile)
        try:
            st = os.lstat(courant)
        except OSError:
            continue
        est_lien = stat.S_ISLNK(st.st_mode)
        liens += 1 if est_lien else 0
        if not est_lien or liens > BORNE_LIENS:  # lien-suivi
            existe = len(pile)
            continue
        cible = os.readlink(courant)
        pile.pop()  # le lien est remplacé par sa cible, lue depuis le dossier qui le contient
        if cible.startswith("/"):
            pile = []
            existe = 0
        restant.extendleft(reversed(cible.split("/")))
    return ("/" + "/".join(pile), "/" + "/".join(pile[:existe]))


def nomme_un_actif_garde(texte):
    """Vrai si le texte contient `.planning` ou `.claude`, casse ignorée : seul un chemin qui les nomme peut viser un actif gardé."""
    bas = texte.casefold()
    return ".planning" in bas or ".claude" in bas  # nomme-actif-garde


def decider_dans_le_doute(payload, ancetres=()):
    """Décision pour un chemin écrit que le cœur ne sait pas analyser (surrogate isolé, NUL, `~utilisateur`, HOME inutilisable, erreur
    de realpath ou d'encodage ; N-01 et N-03, re-audit du 2026-10-01 ; décision du manager vf-dev-manager, renversable, même classe que
    GATE-03). Propriété : aucun chemin que le hook ne sait pas analyser ne peut taire les gates sur un actif sous `.planning/` ou
    `.claude/` d'un lab adhérent, quel que soit le cwd. (a) Le chemin nomme `.planning` ou `.claude` : REFUS, sans regarder le cwd.
    (b) Sinon : décision sur le cwd du payload ET sur les ANCÊTRES EXISTANTS de la valeur (`ancetres`, quand elle est trop longue : N3-01)
    — dans (ou sous) un lab adhérent, refus ; hors lab adhérent, silence (GATE-03) ; un cwd lui-même inanalysable (ou absent) : refus.
    Un cwd de plus de BORNE_VALEUR caractères y est lu sous sa forme réduite lexicalement (refus s'il reste trop long). Le texte du refus
    ne reprend jamais le chemin (un surrogate fait échouer l'encodage de la sortie). Rend True quand la décision est un refus (déjà émis)."""
    brut = chemin_brut(payload)
    if brut is None:
        return None  # aucun chemin écrit : rien à décider ici, le code 3 reste celui du repli shell
    if nomme_un_actif_garde(brut):  # doute-nomme
        sortie_refus(["[planning-core] chemin que le hook central ne sait pas analyser (caractère invalide ou forme `~`) et qui nomme "
                      ".planning ou .claude : écriture par outil refusée dans le doute"])
        return True
    cwd = payload.get("cwd")
    try:
        if not isinstance(cwd, str):
            raise ValueError("cwd absent")
        if len(cwd) > BORNE_VALEUR:  # doute-cwd-long : jamais parcouru tel quel ; réduit lexicalement, refus s'il reste trop long
            cwd = reduire_lexicalement(cwd)  # doute-cwd-reduit
            if len(cwd) > BORNE_VALEUR:
                raise ValueError("cwd trop long")
        adherent = False
        for lieu in [cwd] + list(ancetres):  # doute-ancetres
            racine = racine_lab(lieu)
            adherent = adherent or (bool(racine) and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"])  # doute-adhesion
    except BaseException:
        adherent = True  # doute-cwd : un cwd inanalysable ne tait rien
    if adherent:
        sortie_refus(["[planning-core] chemin que le hook central ne sait pas analyser (caractère invalide ou forme `~`) dans un lab "
                      "adhérent cycles-v1 : écriture par outil refusée dans le doute"])
        return True
    return False


def _partie_existante(chemin):
    """Plus proche ancêtre EXISTANT (dossier) du chemin, résolu physiquement (liens suivis sur la
    partie existante)."""
    courant = os.path.realpath(chemin)
    while not os.path.isdir(courant):
        parent = os.path.dirname(courant)
        if parent == courant:
            break
        courant = parent
    return courant


def sous_planning(chemin):
    """Vrai si un composant du chemin est `.planning` (casse ignorée). Un dossier `.planning` situé dans (ou sous) un composant
    `.planning` n'est JAMAIS une racine de lab : on remonte (amendement de P45-D-01a, décision du manager vf-dev-manager,
    2026-10-01 — un `.planning` créé sous `<phase>/` ou sous `.planning/` ne devient pas une racine sans config.json)."""
    return any(c.casefold() == ".planning" for c in chemin.split(os.sep))  # sous-planning-casse


def sous_claude(chemin):
    """Vrai si `chemin` est (ou est sous) un composant `.claude` (casse ignorée) autre que `.claude/worktrees/<nom>` : un dossier
    `.planning` qui y est créé n'est JAMAIS une racine de lab — sinon un Write de `<lab>/.claude/scripts/.planning/x` ferait de
    `.claude/scripts` une racine non adhérente et désarmerait la protection de ses scripts (amendement de P45-D-01a, décision du manager
    vf-dev-manager, 2026-10-01). Seul le DERNIER composant `.claude` compte, et `.claude/worktrees/<nom>` (là où Claude Code pose les
    worktrees d'un lab, dont celui où l'on travaille) reste une racine possible."""
    composants = chemin.split(os.sep)
    places = [i for i, c in enumerate(composants) if c.casefold() == ".claude"]  # sous-claude-casse
    if not places:
        return False
    reste = [c for c in composants[places[-1] + 1:] if c]  # sous-claude-dernier
    return not (len(reste) >= 2 and reste[0].casefold() == "worktrees")  # sous-claude-worktrees


def racine_lab(depart):
    """Racine physique du lab : le PLUS PROCHE ancêtre qui contient un DOSSIER `.planning` (le
    plus proche gagne, P45-D-01a/P45-D-12) et qui n'est pas lui-même dans (ou sous) un composant `.planning`
    (`sous_planning`), ou None. Un départ non absolu n'a pas de lab."""
    if not isinstance(depart, str) or not depart.startswith("/"):
        return None
    courant = _partie_existante(depart)
    while True:
        if os.path.isdir(os.path.join(courant, ".planning")) and not sous_planning(courant) and not sous_claude(courant):  # racine-imbriquee racine-claude
            return courant
        parent = os.path.dirname(courant)
        if parent == courant:
            return None
        courant = parent


# --- Adhésion (même lecture que le moteur de recalcul, P44-D-02) ------------------------------
def est_fichier_regulier(chemin):
    """lstat + S_ISREG, jamais de suivi de lien."""
    try:
        return stat.S_ISREG(os.lstat(chemin).st_mode)
    except OSError:
        return False


def verifier_adhesion(planning):
    """Sans config.json déclarant EXACTEMENT "planning_version": "cycles-v1", le planning n'a pas
    adhéré : fichier absent ou non régulier, JSON invalide, racine non objet, clé absente, autre
    valeur, valeur non chaîne sont TOUS non adhérents."""
    chemin = os.path.join(planning, "config.json")
    resultat = {"attendue": SCHEMA_ADHESION, "declaree": None, "adherente": False, "config": "absent"}
    if not est_fichier_regulier(chemin):
        return resultat
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
            texte = fh.read()
    except (OSError, UnicodeDecodeError):
        resultat["config"] = "illisible"
        return resultat
    try:
        donnees = json.loads(texte)
    except ValueError:
        resultat["config"] = "illisible"
        return resultat
    if not isinstance(donnees, dict):
        resultat["config"] = "illisible"
        return resultat
    resultat["config"] = "valide"
    if "planning_version" in donnees:
        resultat["declaree"] = donnees["planning_version"]
    resultat["adherente"] = isinstance(resultat["declaree"], str) and resultat["declaree"] == SCHEMA_ADHESION
    return resultat


# --- Table d'armement : cohérence de l'ordre (P45-D-03) --------------------------------------
def armement_valide(table):
    """Vrai si chaque étape armée a toutes ses étapes antérieures armées et si G6 et G5 ont la
    même valeur (l'étape 1 est UN seul geste), de même G3 et G4 (l'étape 5 est UN seul geste, Phase 46,
    P46-D-11). L'ordre est celui de ORDRE_ETAPES."""
    gates = [gate for etape in ORDRE_ETAPES for gate in etape]  # armement-valide-debut
    for gate in gates:
        if table.get(gate) not in ("observe", "armed"):
            return False
    if table.get("G6") != table.get("G5"):
        return False
    if table.get("G3") != table.get("G4"):  # armement-g3-g4
        return False
    precedente_armee = True
    for etape in ORDRE_ETAPES:
        armee = all(table.get(gate) == "armed" for gate in etape)
        if armee and not precedente_armee:
            return False
        precedente_armee = armee
    return True


# --- Parseur de frontmatter : copie ast-identique de celle du moteur de recalcul ---------------
# (dequote, CLE_RE, lire_frontmatter, _lire_liste_indentee). Un contrôle croisé de la suite des
# gates compare les arbres de syntaxe et rougit à la moindre divergence.
def dequote(valeur):
    """Dé-quote une valeur entre guillemets simples ou doubles, sans traitement d'échappement."""
    v = valeur.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in ("'", '"'):
        return v[1:-1]
    return v


CLE_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(.*)$")


def lire_frontmatter(texte):
    """Parse un frontmatter minimal (première ligne `---`, fermeture `---`) : toute forme non
    reconnue (clé dupliquée, bloc littéral, ligne orpheline, frontmatter jamais refermé) rend un
    statut d'échec distinct de « absent » — jamais une valeur devinée (Pitfall 3)."""
    lignes = texte.split("\n")
    if not lignes or lignes[0].rstrip("\r") != "---":
        return ("absent", {})
    fin = None
    for i in range(1, len(lignes)):
        if lignes[i].rstrip("\r") == "---":
            fin = i
            break
    if fin is None:
        return ("invalide:frontmatter-non-ferme", {})
    corps = lignes[1:fin]
    donnees = {}
    cles_vues = set()
    i = 0
    n = len(corps)
    while i < n:
        brute = corps[i].rstrip("\r")
        allegee = brute.strip()
        if allegee == "" or allegee.startswith("#"):
            i += 1
            continue
        if brute != brute.lstrip():
            return ("invalide:ligne-orpheline", {})
        m = CLE_RE.match(brute)
        if not m:
            return ("invalide:ligne-non-reconnue", {})
        cle, reste = m.group(1), m.group(2).strip()
        if cle in cles_vues:
            return ("invalide:cle-dupliquee", {})
        if reste == "":
            valeur, j = _lire_liste_indentee(corps, i + 1)
            if valeur is None:
                return ("invalide:liste-mal-formee", {})
            donnees[cle] = valeur
            i = j
        elif reste == "[]":
            donnees[cle] = []
            i += 1
        elif reste.startswith("[") and reste.endswith("]"):
            interieur = reste[1:-1].strip()
            donnees[cle] = [] if interieur == "" else [dequote(p.strip()) for p in interieur.split(",")]
            i += 1
        else:
            donnees[cle] = dequote(reste)
            i += 1
        cles_vues.add(cle)
    return ("ok", donnees)


def _lire_liste_indentee(corps, depart):
    """Lit une liste de scalaires (`- valeur`) ou une liste de mappings plats (`- k: v` puis
    `k2: v2` plus indentées) sous une clé vide. Renvoie (None, depart) si la forme est mixte ou
    porte un bloc littéral (invalide, jamais devinée)."""
    items = []
    mode = None
    carte_courante = None
    j = depart
    n = len(corps)
    while j < n:
        suivante = corps[j].rstrip("\r")
        if suivante.strip() == "":
            j += 1
            continue
        if suivante == suivante.lstrip():
            break
        interieur = suivante.strip()
        if interieur.startswith("|") or interieur.startswith(">"):
            return (None, j)
        if interieur.startswith("- "):
            corps_item = interieur[2:]
            mkv = CLE_RE.match(corps_item)
            if mkv:
                if mode == "scalaires":
                    return (None, j)
                mode = "mappings"
                carte_courante = {mkv.group(1): dequote(mkv.group(2))}
                items.append(carte_courante)
            else:
                if mode == "mappings":
                    return (None, j)
                mode = "scalaires"
                items.append(dequote(corps_item))
                carte_courante = None
        else:
            mkv2 = CLE_RE.match(interieur)
            if mode == "mappings" and mkv2 and carte_courante is not None:
                cle2 = mkv2.group(1)
                if cle2 in carte_courante:
                    return (None, j)
                carte_courante[cle2] = dequote(mkv2.group(2))
            else:
                return (None, j)
        j += 1
    return (items, j)


def lire_frontmatter_fichier(chemin):
    """Frontmatter d'un fichier du modèle : fichier régulier seulement (lstat, jamais de suivi de
    lien), ouverture O_NOFOLLOW, UTF-8 strict."""
    if not est_fichier_regulier(chemin):
        return ("absent", {})
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
            texte = fh.read()
    except (OSError, UnicodeDecodeError):
        return ("invalide:illisible", {})
    return lire_frontmatter(texte)


# --- Registre de cadrage : copie ast-identique de `lire_registre` du moteur de recalcul (45-06) ------
# G1 lit l'état que la 44 dérive déjà, avec la MÊME grammaire : un contrôle croisé de la suite des gates compare
# les arbres de syntaxe (R-REGISTRE) et rougit à la moindre divergence.
def lire_registre(donnees_cadrage):
    """(registre_ok, registre_clos) depuis le frontmatter DÉJÀ analysé de CADRAGE.md. Φ3 : registre
    absent ou mal formé (structurante hors oui/non, ligne qui n'est pas un mapping) -> registre_ok
    faux (`registre-invalide`). Lecture littérale spec §3.1 l.213 : TOUTE valeur non vide de
    `statut` ferme la ligne, quelle qu'elle soit — jamais une liste fermée, jamais un jugement de
    la valeur elle-même. `inconnues: []` est clos."""
    inconnues = donnees_cadrage.get("inconnues")
    if not isinstance(inconnues, list):
        return (False, False)
    clos = True
    for item in inconnues:
        if not isinstance(item, dict):
            return (False, False)
        structurante = item.get("structurante")
        if structurante not in ("oui", "non"):
            return (False, False)
        statut = item.get("statut")
        if structurante == "oui" and not (isinstance(statut, str) and statut.strip()):
            clos = False
    return (True, clos)


# --- Plans ouverts et référentiel de G2 -------------------------------------------------------
NOM_UNITE = re.compile(r"^[0-9]{2,}-[\w.-]+$")


def entree_ecrit_valide(entree):
    """Une entrée `ecrit:` valide : chemin concret relatif à la racine du lab, non vide, sans `/`
    ni `~` initial, sans segment `..`, sans caractère de contrôle ni `\\`, sans métacaractère
    `*?[]{}<>` — jamais un motif (même règle que le moteur de recalcul)."""
    if not isinstance(entree, str) or entree == "":
        return False
    if entree.startswith("/") or entree.startswith("~"):
        return False
    if ".." in entree.split("/"):
        return False
    if any(ord(c) < 0x20 or ord(c) == 0x7F for c in entree):
        return False
    if "\\" in entree:
        return False
    if any(c in entree for c in "*?[]{}<>"):
        return False
    return True


def _valeurs_ecrit(donnees):
    ecrit = donnees.get("ecrit")
    if isinstance(ecrit, str):
        return [ecrit]
    if isinstance(ecrit, list):
        return ecrit
    return None


# --- Entrées `ecrit:`, prédicat « livrable présent » et empreinte des livrables : bloc partagé (Phase 46, 46-01 ; P46-D-03a, P46-D-12) ----------
# MÊME texte dans poser-verdict.sh, planning-hook.sh et recalc-planning.sh (l'installeur ne pose que des `*.sh` : pas de module
# partagé, des copies ast-identiques que la suite test-cloture-empreintes.sh compare, R-EMP-04). Le bloc porte l'ENCHAÎNEMENT
# complet « PLAN.md -> entrées `ecrit:` -> validation -> présence -> empreinte » (`entrees_du_plan`, `livrables_presents`,
# `empreinte_livrables`) : G3, G4, la règle R4 du recalcul et la commande de pose l'appellent, aucun ne le réécrit ; ses ENTRÉES
# (parseur de frontmatter, `entree_ecrit_valide`, `_valeurs_ecrit`, `SANS_SUIVI_DE_LIEN`) sont comparées avec lui. Le parcours est
# borné PAR PLAN.md : les bornes comptent les ENTRÉES parcourues (fichiers, sous-dossiers, liens) et les octets, avec UN budget
# commun à toutes les entrées d'un même PLAN.md ; un dépassement est un refus explicite, jamais une empreinte partielle ni un
# livrable « présent ». Les noms de NOMS_EXCLUS_LIVRABLES sont ignorés partout (prédicat « vide » ET empreinte) : ouvrir un
# dossier livrable dans le Finder ou l'Explorateur ne doit pas périmer un verdict.
BORNE_FICHIERS_LIVRABLES = 2000
BORNE_OCTETS_LIVRABLES = 134217728
NOMS_EXCLUS_LIVRABLES = (".DS_Store", "Thumbs.db", "desktop.ini")
SANS_BLOCAGE = getattr(os, "O_NONBLOCK", 0)
DRAPEAUX_LIVRABLE = os.O_RDONLY | SANS_SUIVI_DE_LIEN | SANS_BLOCAGE  # livrable-ouverture
AVEC_DESCRIPTEURS = os.open in os.supports_dir_fd and hasattr(os, "O_DIRECTORY")  # livrable-dirfd


def _normaliser_livrable(entree):
    """Entrée `ecrit:` normalisée : composants non vides et différents de `.`, rejoints par `/` (barre finale retirée)."""
    return "/".join(c for c in entree.split("/") if c not in ("", "."))


def _fichier_non_vide(taille):
    """Vrai si un fichier régulier de `taille` octets (lstat) n'est pas vide."""
    return taille > 0  # livrable-vide


def _nom_sain(nom):
    """Vrai si le nom d'une entrée de dossier se décode en UTF-8 et ne porte aucun caractère de contrôle : sans cela le texte
    canonique de l'empreinte serait ambigu (tabulation, saut de ligne) ou non encodable."""
    try:
        nom.encode("utf-8")
    except UnicodeEncodeError:
        return False  # livrable-nom-utf8
    return not any(ord(c) < 0x20 or ord(c) == 0x7F for c in nom)  # livrable-nom-controle


def _borne_depassee(budget):
    """Libellé de la borne franchie par `budget` = [entrées parcourues, octets annoncés par lstat, octets lus], ou None."""
    if budget[0] > BORNE_FICHIERS_LIVRABLES:  # livrable-borne
        return "borne de %d fichiers dépassée (BORNE_FICHIERS_LIVRABLES)" % BORNE_FICHIERS_LIVRABLES
    if budget[1] > BORNE_OCTETS_LIVRABLES or budget[2] > BORNE_OCTETS_LIVRABLES:  # livrable-octets
        return "borne de %d octets dépassée (BORNE_OCTETS_LIVRABLES)" % BORNE_OCTETS_LIVRABLES
    return None


def _parcourir_livrable(dossier, relatif, budget):
    """(statut, detail, fichiers) : les fichiers réguliers du sous-arbre de `dossier` (`relatif` : son chemin relatif au lab),
    triés par chemin relatif, sous forme (relatif, taille). Lstat sur chaque entrée : un lien et un fichier spécial interne ne sont
    ni suivis ni retenus. Le tri final rend l'empreinte indépendante de l'ordre d'énumération du système de fichiers. Statut `ok`,
    `borne` (detail = libellé de la borne) ou `illisible`."""
    fichiers = []
    pile = [(dossier, relatif)]
    while pile:
        courant, rel = pile.pop()
        try:
            with os.scandir(courant) as entrees:
                for entree in entrees:
                    nom = entree.name
                    if nom in NOMS_EXCLUS_LIVRABLES:  # livrable-exclus
                        continue
                    if not _nom_sain(nom):
                        return ("illisible", rel, [])
                    info = entree.stat(follow_symlinks=False)
                    budget[0] += 1
                    if stat.S_ISREG(info.st_mode):
                        budget[1] += info.st_size
                    depasse = _borne_depassee(budget)
                    if depasse is not None:
                        return ("borne", depasse, [])
                    if stat.S_ISDIR(info.st_mode):
                        pile.append((entree.path, rel + "/" + nom))
                    elif stat.S_ISREG(info.st_mode):
                        fichiers.append((rel + "/" + nom, info.st_size))
        except OSError:
            return ("illisible", rel, [])
    fichiers.sort()  # livrable-tri
    return ("ok", relatif, fichiers)


def _examiner_livrable(racine, entree, budget):
    """(statut, detail, genre, fichiers) d'une entrée `ecrit:`. Le chemin est parcouru composant par composant par lstat : un
    lien, terminal ou intermédiaire, rend le livrable `lien` (jamais suivi). Un fichier régulier de 0 octet est `vide` ; un dossier
    sans aucun fichier régulier non vide est `vide` ; une entrée absente, un composant intermédiaire qui n'est pas un dossier ou un
    fichier spécial (FIFO, socket, périphérique) est `absent` ; une erreur de lecture est `illisible` ; un dépassement de borne est
    `borne`. `genre` vaut `fichier` ou `dossier` pour un livrable `present`. `fichiers` : (chemin relatif au lab, taille)."""
    normale = _normaliser_livrable(entree)
    composants = normale.split("/") if normale != "" else []
    if not composants:
        return ("absent", entree if entree != "" else ".", "", [])
    courant = racine
    info = None
    for rang, composant in enumerate(composants):
        courant = os.path.join(courant, composant)
        try:
            info = os.lstat(courant)  # livrable-lien
        except (FileNotFoundError, NotADirectoryError):
            return ("absent", normale, "", [])
        except OSError:
            return ("illisible", normale, "", [])
        if stat.S_ISLNK(info.st_mode):
            return ("lien", normale, "", [])
        if rang < len(composants) - 1 and not stat.S_ISDIR(info.st_mode):
            return ("absent", normale, "", [])
    if stat.S_ISREG(info.st_mode):
        budget[0] += 1
        budget[1] += info.st_size
        depasse = _borne_depassee(budget)
        if depasse is not None:
            return ("borne", depasse, "", [])
        if not _fichier_non_vide(info.st_size):
            return ("vide", normale, "", [])
        return ("present", normale, "fichier", [(normale, info.st_size)])
    if stat.S_ISDIR(info.st_mode):
        statut, detail, fichiers = _parcourir_livrable(courant, normale, budget)
        if statut != "ok":
            return (statut, detail, "", [])
        if not any(_fichier_non_vide(f[1]) for f in fichiers):
            return ("vide", normale, "", [])
        return ("present", normale, "dossier", fichiers)
    return ("absent", normale, "", [])


def livrables_presents(racine, entrees):
    """[(entrée, statut, détail)], une par entrée de `entrees` et dans leur ordre : le prédicat « livrable présent » d'un PLAN.md
    entier (P46-D-12), statut `present`, `absent`, `lien`, `vide`, `borne` ou `illisible` (voir `_examiner_livrable`). UN budget
    commun à toutes les entrées : le coût d'un PLAN.md est borné comme l'empreinte, jamais proportionnel au nombre d'entrées qui se
    recouvrent. Dès qu'une borne est franchie, cette entrée et toutes les suivantes valent `borne` (jamais `present`). Le prédicat
    unique de G3 et de la règle R4 du recalcul : aucun appelant n'examine une entrée isolément."""
    budget = [0, 0, 0]
    resultats = []
    for entree in entrees:
        depasse = _borne_depassee(budget)
        if depasse is not None:
            resultats.append((entree, "borne", depasse))
            continue
        statut, detail, _genre, _fichiers = _examiner_livrable(racine, entree, budget)  # livrables-budget-commun
        resultats.append((entree, statut, detail))
    return resultats


def _ouvrir_dossier_livrable(racine, composants):
    """Poignée du dossier `racine`/`composants`, ouvert sans suivre de lien à AUCUN composant : sous POSIX un descripteur obtenu par
    ouvertures chaînées relatives à un descripteur de dossier (openat), O_NOFOLLOW à chaque pas (DRAPEAUX_LIVRABLE) ; sans descripteurs
    de dossier (Windows), le chemin : limite déclarée. La racine du lab est celle de l'appelant, déjà résolue. Lève OSError."""
    if not AVEC_DESCRIPTEURS:
        return os.path.join(racine, *composants)
    dossier = os.open(racine, os.O_RDONLY | os.O_DIRECTORY)
    try:
        for composant in composants:
            suivant = os.open(composant, DRAPEAUX_LIVRABLE | os.O_DIRECTORY, dir_fd=dossier)
            os.close(dossier)
            dossier = suivant
    except BaseException:
        os.close(dossier)
        raise
    return dossier


def _fermer_dossier_livrable(poignee):
    if AVEC_DESCRIPTEURS:
        os.close(poignee)


def _hacher_dans(poignee, nom, budget):
    """(statut, valeur) : `ok` et le sha256 hexadécimal du fichier `nom` du dossier `poignee`, ouvert sans suivre de lien et sans
    bloquer (O_NOFOLLOW, O_NONBLOCK : un FIFO substitué à un fichier après le parcours ne bloque pas l'ouverture), puis fstat
    régulier, lu par blocs, octets lus ajoutés au budget partagé ; `borne` et le libellé de la borne ; ou `illisible`. Jamais un
    hash partiel."""
    import hashlib
    try:
        if AVEC_DESCRIPTEURS:
            descripteur = os.open(nom, DRAPEAUX_LIVRABLE, dir_fd=poignee)
        else:
            descripteur = os.open(os.path.join(poignee, nom), DRAPEAUX_LIVRABLE)
    except OSError:
        return ("illisible", "")
    hacheur = hashlib.sha256()
    try:
        with os.fdopen(descripteur, "rb") as fh:
            if not stat.S_ISREG(os.fstat(fh.fileno()).st_mode):
                return ("illisible", "")
            while True:
                bloc = fh.read(65536)
                if not bloc:
                    break
                budget[2] += len(bloc)
                depasse = _borne_depassee(budget)
                if depasse is not None:
                    return ("borne", depasse)
                hacheur.update(bloc)
    except OSError:
        return ("illisible", "")
    return ("ok", hacheur.hexdigest())


def _hacher_livrables(racine, fichiers, budget):
    """("ok", {chemin relatif: sha256}) ou (statut d'échec, chemin relatif ou libellé de borne) pour `fichiers` = [(chemin relatif au
    lab, taille)]. Chaque dossier est ouvert UNE fois (le coût d'une lecture ne dépend pas de la profondeur du fichier), sans suivre de
    lien à aucun composant : un lien substitué à un composant après le parcours rend le fichier `illisible`, jamais lu."""
    par_dossier = {}
    for rel, _taille in fichiers:
        dossier_rel, _, nom = rel.rpartition("/")
        par_dossier.setdefault(dossier_rel, []).append(nom)
    valeurs = {}
    for dossier_rel in sorted(par_dossier):
        noms = sorted(par_dossier[dossier_rel])
        try:
            poignee = _ouvrir_dossier_livrable(racine, [c for c in dossier_rel.split("/") if c != ""])
        except OSError:
            return ("illisible", dossier_rel + "/" + noms[0] if dossier_rel != "" else noms[0])
        try:
            for nom in noms:
                rel = dossier_rel + "/" + nom if dossier_rel != "" else nom
                statut, valeur = _hacher_dans(poignee, nom, budget)
                if statut != "ok":
                    return (statut, valeur if valeur != "" else rel)
                valeurs[rel] = valeur
        finally:
            _fermer_dossier_livrable(poignee)
    return ("ok", valeurs)


def empreinte_livrables(racine, entrees):
    """("ok", sha256 hexadécimal) ou (statut d'échec, entrée ou libellé de borne) pour les entrées `ecrit:` `entrees`. Texte
    canonique : entrées normalisées, dédoublonnées et triées ; une ligne `fichier<TAB><chemin relatif au lab><TAB><sha256>` par
    entrée fichier ; pour une entrée dossier, une ligne `dossier<TAB><entrée>` puis une ligne `fichier…` par fichier régulier du
    sous-arbre, triées par chemin relatif ; lignes jointes par `\\n`, saut final, haché en UTF-8. Le budget (entrées et octets) est
    commun à toutes les entrées. Une entrée qui n'est pas `present` (absente, vide, lien, borne, illisible) fait échouer le calcul."""
    import hashlib
    budget = [0, 0, 0]
    lignes = []
    for entree in sorted(set(_normaliser_livrable(e) for e in entrees)):  # empreinte-tri
        statut, detail, genre, fichiers = _examiner_livrable(racine, entree, budget)
        if statut != "present":
            return (statut, detail)
        if genre == "dossier":
            lignes.append("dossier\t" + detail)
        statut_hache, valeurs = _hacher_livrables(racine, fichiers, budget)
        if statut_hache != "ok":
            return (statut_hache, valeurs)
        for rel, _taille in fichiers:
            lignes.append("fichier\t" + rel + "\t" + valeurs[rel])
    texte = "\n".join(lignes) + "\n"
    return ("ok", hashlib.sha256(texte.encode("utf-8")).hexdigest())


def _couvre_unite(entree, unite_rel):
    """Vrai si l'entrée `ecrit:` EST le dossier de l'unité (`unite_rel`, relatif au lab) ou l'un de ses ancêtres, comparé par
    composants et sans égard à la casse (sur un système de fichiers insensible à la casse, `.PLANNING` désigne le même dossier).
    Une entrée qui se normalise en rien (`.`) n'est pas un livrable : le prédicat la rend `absente`, elle n'est pas traitée ici."""
    cible = [c.casefold() for c in _normaliser_livrable(entree).split("/") if c != ""]
    unite = [c.casefold() for c in unite_rel.split("/") if c not in ("", ".")]
    return len(cible) > 0 and len(cible) <= len(unite) and unite[:len(cible)] == cible


def entrees_du_plan(octets_plan, unite_rel):
    """(motif, détail) : `("ok", [entrées déclarées, dans l'ordre])` ou le premier échec de la chaîne PLAN.md -> entrées -> validation :
    `non-utf8` ; `frontmatter` (détail : statut du parseur) ; `absent` (`ecrit:` absent ou vide) ; `invalide` (détail : la valeur
    fautive telle que lue) ; `unite` (détail : l'entrée normalisée) quand une entrée EST ou CONTIENT le dossier de l'unité
    `unite_rel` — le verdict s'écrit dans ce dossier, donc `hash_livrables` serait périmé dès la pose (décision du manager,
    renversable). Le chemin unique de G3, G4, de R4 du recalcul et de la commande de pose : `octets_plan` est lu par l'appelant."""
    try:
        texte = octets_plan.decode("utf-8")
    except UnicodeDecodeError:
        return ("non-utf8", "")
    statut, donnees = lire_frontmatter(texte)
    if statut != "ok":
        return ("frontmatter", statut)
    valeurs = _valeurs_ecrit(donnees)
    if not valeurs:
        return ("absent", "")
    for valeur in valeurs:
        if not entree_ecrit_valide(valeur):
            return ("invalide", valeur)
    for valeur in valeurs:
        if _couvre_unite(valeur, unite_rel):  # entrees-unite
            return ("unite", _normaliser_livrable(valeur))
    return ("ok", list(valeurs))


def _sous_dossiers(dossier):
    """Noms d'unité (règle NOM_UNITE) des vrais dossiers de `dossier`, triés ; jamais un lien."""
    try:
        noms = sorted(os.listdir(dossier))
    except OSError:
        return []
    res = []
    for nom in noms:
        if not NOM_UNITE.match(nom):
            continue
        try:
            if stat.S_ISDIR(os.lstat(os.path.join(dossier, nom)).st_mode):
                res.append(nom)
        except OSError:
            continue
    return res


def plans_ouverts(racine):
    """[(chemin relatif du PLAN.md, [entrées ecrit valides])] des plans OUVERTS de forme modèle :
    `.planning/cycles/<cycle>/phases/<phase>/PLAN.md` et `.../phases/<phase>/plans/<plan>/PLAN.md`.
    Ouvert = ni CLOTURE.md ni DEROGATION.md dans son dossier. Un PLAN.md au frontmatter illisible
    est ignoré (G2 est fail-open, spec §5.1). Parcours trié."""
    base = os.path.join(racine, ".planning", "cycles")
    res = []
    for cycle in _sous_dossiers(base):
        phases = os.path.join(base, cycle, "phases")
        for phase in _sous_dossiers(phases):
            dossier_phase = os.path.join(phases, phase)
            dossiers = [dossier_phase]
            for plan in _sous_dossiers(os.path.join(dossier_phase, "plans")):
                dossiers.append(os.path.join(dossier_phase, "plans", plan))
            for dossier in dossiers:
                if os.path.lexists(os.path.join(dossier, "CLOTURE.md")) or os.path.lexists(os.path.join(dossier, "DEROGATION.md")):  # g2-clos
                    continue
                statut, donnees = lire_frontmatter_fichier(os.path.join(dossier, "PLAN.md"))
                if statut != "ok":
                    continue
                valeurs = _valeurs_ecrit(donnees) or []
                entrees = [e for e in valeurs if entree_ecrit_valide(e)]
                res.append((os.path.relpath(os.path.join(dossier, "PLAN.md"), racine), entrees))
    return res


def _couvert(composants, plans):
    """Le chemin (composants relatifs au lab) est égal à une entrée `ecrit:` d'un plan ouvert ou
    situé dessous. Union des entrées de tous les plans ouverts."""
    for _plan, entrees in plans:  # g2-union
        for entree in entrees:
            cible = [c for c in entree.split("/") if c not in ("", ".")]
            if cible and composants[: len(cible)] == cible:
                return True
    return False


def _candidats_g2(contexte):
    """Chemins ABSOLUS que l'action vise : le chemin écrit pour Write, Edit, NotebookEdit ; pour
    Bash, tout jeton de la commande qui ressemble à un chemin (contient `/` ou `.`, ou nomme une
    entrée existante), résolu contre le cwd du payload (P45-D-10 : détection, jamais une promesse)."""
    outil = contexte["outil"]
    if outil in ("Write", "Edit", "NotebookEdit"):
        return [contexte["ecrit"]] if contexte["ecrit"] else []
    if outil != "Bash":
        return []
    entree = contexte["payload"].get("tool_input")
    commande = entree.get("command") if isinstance(entree, dict) else None
    if not isinstance(commande, str):
        return []
    try:
        jetons = shlex.split(commande)
    except ValueError:
        return []
    base = contexte["cwd"] if isinstance(contexte["cwd"], str) and contexte["cwd"].startswith("/") else os.getcwd()
    res = []
    for jeton in jetons:
        jeton = re.sub(r"^[0-9]*[<>]+&?", "", jeton)
        if jeton == "" or jeton.startswith("-") or jeton.startswith("~") or "\x00" in jeton:
            continue
        if any(c in jeton for c in "{}*?$`\"'|;&<>()"):
            continue  # motif, expansion ou charge utile : pas un chemin nommé
        absolu = jeton if jeton.startswith("/") else os.path.join(base, jeton)
        if "/" in jeton or "." in jeton or os.path.lexists(absolu):
            res.append(absolu)
    return res


def evaluer_g2(contexte):
    """G2 : avertit, sans JAMAIS refuser (P45-D-03), quand une écriture par outil (ou une commande
    Bash) vise un chemin du lab hors `.planning/` et hors `.claude/` non couvert par l'`ecrit:` d'un
    plan ouvert. Toute exception est avalée : G2 est fail-open (spec §5.1)."""
    if G2_MODE != "avertit":
        return []
    try:
        racine = contexte["racine"]
        plans = plans_ouverts(racine)
        hors = []
        for absolu in _candidats_g2(contexte):
            try:
                rel = os.path.relpath(os.path.realpath(absolu), racine)
            except (OSError, ValueError):
                continue
            composants = [c for c in rel.split(os.sep) if c not in ("", ".")]
            if not composants or composants[0] == "..":
                continue
            if composants[0] in (".planning", ".claude"):
                continue
            if _couvert(composants, plans):
                continue
            if "/".join(composants) not in hors:
                hors.append("/".join(composants))
        if not hors:
            return []
        montres = ", ".join(hors[:5]) + ((" (+%d autre(s))" % (len(hors) - 5)) if len(hors) > 5 else "")
        return [("avertit", "[planning-core] G2 (avertissement, jamais un refus) : " + montres
                 + " hors de l'ecrit: de tout plan ouvert (%d plan(s) ouvert(s)). " % len(plans)
                 + "Les écritures par Bash ne sont pas couvertes par les refus : limite déclarée "
                 "(P45-D-10), détection seulement.")]
    except Exception:
        return []


# --- Sorties : UN objet JSON par exécution, jamais systemMessage (DIV-3) ----------------------
def _emettre(objet):
    texte = json.dumps(objet, ensure_ascii=False) + "\n"
    figer_echeance()  # echeance-figee-emission
    sys.stdout.buffer.write(texte.encode("utf-8"))
    sys.stdout.buffer.flush()


def sortie_refus(raisons):
    _emettre({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "\n".join(raisons),
    }})


def sortie_contexte(textes):
    _emettre({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": "\n".join(textes),
    }})


def _message_sur(texte):
    """Message de sortie d'un événement non outil (P46-D-10, #60490) : un texte qui porterait « no such file » ou « can't open » (message
    d'erreur système remonté tel quel) est remplacé par un texte neutre — le harnais lit un refus qui les porte comme « script absent »."""
    bas = texte.casefold()
    if any(fragment in bas for fragment in FRAGMENTS_INTERDITS_SORTIE):  # message-sur
        return "[planning-core] refus : le motif détaillé n'est pas reproduit (message d'erreur système écarté, P46-D-10)"
    return texte


def sortie_blocage_subagent(raisons):
    """SubagentStop : le blocage est la décision JSON `decision: "block"` avec sa `reason`, code 0 — JAMAIS le code 2 (P46-D-10 ; le
    sous-agent continue et la raison devient sa prochaine instruction, plafond natif de huit continuations). Passe par `_emettre`."""
    _emettre({"decision": "block", "reason": _message_sur("\n".join(raisons))})  # sortie-subagentstop


# --- Entonnoir de décision, journal d'observation, G5 (45-04) ------------------------------------
# Un gate qui refuserait rend une liste de Verdict(gate, chemin_rel, raison) ; `decider` est le SEUL
# endroit où un verdict devient un refus (gate armed), une observation journalisée (gate observe) ou
# un passage cité (dérogation active, consommée). `chemin_rel` vaut None pour une erreur interne.
Verdict = collections.namedtuple("Verdict", ("gate", "chemin_rel", "raison"))
OUTILS_ECRITURE = ("Write", "Edit", "NotebookEdit")
NOM_VERDICT = "verdict.md"
RAISON_G5 = ("écrire VERDICT.md par outil est refusé (P45-D-07) : posez le verdict par la commande "
             "poser-verdict.sh")


# Encodeur du journal : copie ast-identique de `_jeton_journal` de recalc-planning.sh (un contrôle
# croisé de la suite des gates compare les arbres de syntaxe et rougit à la moindre divergence).
def _jeton_journal(valeur, repli):
    """Encode une valeur arbitraire (P44-D-09 : lue, jamais validée — aucun contrôle de SENS) en
    UN jeton structurellement sûr pour une ligne de `cloture.log`, par un échappement pourcent
    INJECTIF (lot 4, correction de classe — remplace l'ancien assainissement par `_`, qui
    écrasait `"3 4"` et `"3_4"` sur le même jeton et pouvait donc faire manquer une clôture
    réellement nouvelle au dédoublonnage, P44-D-11 ; alphabet étendu F44-05/F7 : tout caractère
    NON IMPRIMABLE — `not str.isprintable()`, qui couvre NUL et les contrôles C0/C1, en plus des
    séparateurs Unicode déjà couverts par `isspace()` — était encore laissé passer BRUT, ce qui
    aurait permis d'injecter un octet de contrôle littéral dans `cloture.log`) : tout caractère
    considéré comme un espace par Python (`str.isspace()` — couvre U+2028 LIGNE SÉPARATRICE,
    U+0085 NEL et tout espace Unicode, pas seulement l'ASCII), tout caractère NON IMPRIMABLE
    (`not str.isprintable()` — NUL, contrôles C0/C1, séparateurs Unicode restants), tout `=` (qui
    ouvrirait une séquence `clé=` lisible par `LIGNE_JOURNAL_RE`), et le caractère d'échappement
    `%` lui-même, sont réécrits en `%XX` — deux chiffres hexadécimaux majuscules par OCTET de son
    encodage UTF-8 (un caractère multi-octets produit plusieurs `%XX` consécutifs, jamais un seul
    jeton non réversible). Le jeton résultant ne contient donc plus jamais d'espace, de saut de
    ligne, de `=`, ni d'octet de contrôle brut : deux valeurs distinctes produisent TOUJOURS deux
    jetons distincts (réversible par simple décodage pourcent).

    F5 (correction ciblée) : `return jeton or repli` laissait un jeton vide filer si `repli`
    lui-même était vide (repli vide -> `jeton or repli` retombe sur `""`), produisant une ligne
    que `LIGNE_JOURNAL_RE` (`\\S+` sur chaque champ) ne relirait plus jamais — une corruption
    SILENCIEUSE du journal. `repli` est un contrat interne, toujours un littéral non vide chez
    tous les appelants actuels (`"-"`, `"inconnu"`) : une erreur BRUYANTE immédiate (jamais une
    ligne illisible produite en silence) si ce contrat est un jour rompu. Une fois `repli` garanti
    non vide, `brute` (str) contient au moins un caractère, et chaque caractère produit au moins
    un caractère de sortie (lui-même, ou au moins un `%XX`) : `jeton` est donc TOUJOURS non vide,
    sans repli de dernier recours nécessaire.

    IN-02 (revue, correction ciblée) : l'invariant final est vérifié par une exception EXPLICITE,
    jamais un `assert` nu — un `assert` est désactivable en bloc par `python -O`/`PYTHONOPTIMIZE`,
    et ce moteur ne garantit nulle part que son interpréteur tourne sans cette option. Une garde de
    P44-D-11 (jamais de ligne illisible produite en silence dans `cloture.log`) reste active quel
    que soit le mode d'exécution."""
    if not repli:
        raise ValueError("_jeton_journal : 'repli' doit toujours être non vide (contrat interne)")
    brute = valeur if valeur not in (None, "") else repli
    morceaux = []
    for caractere in str(brute):
        if caractere == "%" or caractere == "=" or caractere.isspace() or not caractere.isprintable():
            for octet in caractere.encode("utf-8"):
                morceaux.append("%{:02X}".format(octet))
        else:
            morceaux.append(caractere)
    jeton = "".join(morceaux)
    if not jeton:
        raise AssertionError("_jeton_journal : jeton vide malgré un repli non vide (invariant violé)")
    return jeton


# Journal de D1 (Phase 46, 46-07 ; P46-D-07a) : copie ast-identique de `inscrire_surveillance` dans planning-hook.sh, recalc-planning.sh,
# poser-verdict.sh et deroger-gate.sh (un contrôle de test-d1-surveillance.sh compare les arbres de syntaxe, R-D1-09) : les écrivains
# du moteur y inscrivent ce qu'ils écrivent, le hook y trace ce qu'il observe.
def inscrire_surveillance(racine, genre, chemin_rel, empreinte, par, source):
    """Ajoute UNE ligne au journal de D1, `<racine>/.planning/surveillance.log` : `<horodatage ISO UTC>  genre=<g>  chemin=<jeton>  sha256=<hex|absent|->
    par=<jeton>  source=<seance|reconciliation|->` (deux espaces entre champs), chaque valeur par `_jeton_journal` (injectif : un nom de fichier
    qui porte un saut de ligne reste UNE ligne). Ajout seul (O_APPEND, O_NOFOLLOW, 0600), sous verrou exclusif quand `fcntl` existe. Un
    journal qui n'est pas un fichier régulier (lien compris), un dossier de planning en lien, toute erreur : AUCUNE ligne, jamais une
    exception qui remonte (D1 est fail-open, P46-D-10). Jamais appelée en lecture seule."""
    try:
        import time as _temps
        try:
            import fcntl as _verrou
        except ImportError:
            _verrou = None
        planning = os.path.join(racine, ".planning")
        chemin = os.path.join(planning, "surveillance.log")
        if os.path.islink(planning) or (os.path.lexists(chemin) and not stat.S_ISREG(os.lstat(chemin).st_mode)):
            return
        ligne = "{}  genre={}  chemin={}  sha256={}  par={}  source={}\n".format(
            _temps.strftime("%Y-%m-%dT%H:%M:%SZ", _temps.gmtime()), _jeton_journal(genre, "-"), _jeton_journal(chemin_rel, "-"),
            _jeton_journal(empreinte, "-"), _jeton_journal(par, "-"), _jeton_journal(source, "-"))
        descripteur = os.open(chemin, os.O_WRONLY | os.O_APPEND | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0), 0o600)
        try:
            if not stat.S_ISREG(os.fstat(descripteur).st_mode):
                return
            if hasattr(os, "fchmod"):
                os.fchmod(descripteur, 0o600)
            if _verrou is not None:
                _verrou.flock(descripteur, _verrou.LOCK_EX)
            octets = ligne.encode("utf-8")
            while octets:
                octets = octets[os.write(descripteur, octets):]
        finally:
            os.close(descripteur)
    except Exception:
        return


def chemin_journal_observation(xdg, home):
    """Chemin du journal d'observation, dérivé des deux valeurs reçues en arguments : `<xdg>/vibeflow/
    gates-observation/observation.log`, à défaut `<home>/.cache/...`. Une valeur vide ou non absolue
    est ignorée ; aucune des deux exploitable : None. Ces valeurs ne servent qu'à CE chemin (P45-D-12a)."""
    if isinstance(xdg, str) and xdg.startswith("/"):  # obs-xdg
        base = xdg
    elif isinstance(home, str) and home.startswith("/"):
        base = os.path.join(home, ".cache")
    else:
        return None
    return os.path.join(base, "vibeflow", "gates-observation", "observation.log")


def observer(verdict, contexte):
    """Écrit UNE ligne au journal d'observation (ajout seul, O_NOFOLLOW, fichier 0600, dossier 0700) :
    gate, lab, chemin, outil, raison, horodatage — jamais le contenu écrit ni la commande (T-45-36).
    Un journal impossible à écrire ne produit jamais un refus ni une exception : aucune ligne."""
    try:
        chemin = chemin_journal_observation(contexte.get("arg_xdg"), contexte.get("arg_home"))
        if chemin is None:
            return
        os.makedirs(os.path.dirname(chemin), mode=0o700, exist_ok=True)
        horodatage = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
        ligne = "{}  gate={}  lab={}  chemin={}  outil={}  raison={}\n".format(horodatage, verdict.gate, _jeton_journal(contexte.get("racine"), "-"), _jeton_journal(verdict.chemin_rel, "-"), _jeton_journal(contexte.get("outil"), "-"), _jeton_journal(verdict.raison, "-"))  # obs-ligne
        descripteur = os.open(chemin, os.O_WRONLY | os.O_APPEND | os.O_CREAT | SANS_SUIVI_DE_LIEN, 0o600)
        try:
            if hasattr(os, "fchmod"):
                os.fchmod(descripteur, 0o600)
            os.write(descripteur, ligne.encode("utf-8"))
        finally:
            os.close(descripteur)
    except Exception:
        return


# --- Dérogations nominatives (P45-D-13) : journal append-only `.planning/derogations-gates.log` ------
# Lignes `<horodatage>  derogation  id=<n>  gate=<G>  chemin=<jeton>  qui=<jeton>  canal=<jeton>
# date=<AAAA-MM-JJ>  raison=<jeton>` (écrites par deroger-gate.sh) et `<horodatage>  consommee  id=<n>
# gate=<G>  chemin=<jeton>` (écrites ici). Usage UNIQUE par (gate, chemin) : une dérogation consommée ne
# sert plus. Le journal doit être un fichier régulier (lstat) : un lien ou un autre type annule toute
# dérogation, sans erreur (T-45-35).
NOM_JOURNAL_DEROGATIONS = "derogations-gates.log"
NOM_SURVEILLANCE = "surveillance.log"  # journal de D1 (46-07, P46-D-07a) : inscrit par le moteur, protégé par G6, jamais surveillé
LIGNE_DEROGATION_RE = re.compile(r"^(\S+)  (derogation|consommee)  id=([0-9]+)  gate=(\S+)  chemin=(\S+)(?:  (.*))?$")


def _chemin_journal_derogations(racine):
    return os.path.join(racine, ".planning", NOM_JOURNAL_DEROGATIONS)


def _ouvrir_journal_derogations(racine, mode):
    """Descripteur du journal, ou None si ce n'est pas un fichier régulier (lstat) ; jamais de suivi de
    lien. Seul point d'ouverture du journal : lecture et consommation passent ici."""
    chemin = _chemin_journal_derogations(racine)
    return os.open(chemin, mode | SANS_SUIVI_DE_LIEN) if est_fichier_regulier(chemin) else None  # derog-lien


def _entrees_journal(octets):
    """Entrées du journal : dict(genre, id, gate, chemin, champs) ; une ligne mal formée est ignorée."""
    entrees = []
    for ligne in octets.decode("utf-8", "replace").split("\n"):
        m = LIGNE_DEROGATION_RE.match(ligne)
        if not m:
            continue
        champs = {}
        for morceau in (m.group(6) or "").split("  "):
            cle, separateur, valeur = morceau.partition("=")
            if separateur:
                champs[cle] = urllib.parse.unquote(valeur, errors="replace")
        entrees.append({"genre": m.group(2), "id": m.group(3), "gate": m.group(4),
                        "chemin": urllib.parse.unquote(m.group(5), errors="replace"), "champs": champs})
    return entrees


def _derogation_non_consommee(entrees, gate, chemin_rel):
    consommees = {e["id"] for e in entrees if e["genre"] == "consommee"}
    for entree in entrees:
        if entree["genre"] != "derogation" or entree["gate"] != gate or entree["chemin"] != chemin_rel:
            continue
        if entree["id"] in consommees:  # derog-consommee
            continue
        if not all(cle in entree["champs"] for cle in ("qui", "canal", "date", "raison")):
            continue
        return entree
    return None


def derogation_active(racine, gate, chemin_rel):
    """La plus ancienne dérogation non consommée qui couvre (gate, chemin_rel), ou None. Toute erreur
    de lecture : aucune dérogation (le refus est maintenu, jamais un passage par défaut)."""
    try:
        descripteur = _ouvrir_journal_derogations(racine, os.O_RDONLY)
        if descripteur is None:
            return None
        with os.fdopen(descripteur, "rb") as fh:
            octets = fh.read()
        return _derogation_non_consommee(_entrees_journal(octets), gate, chemin_rel)
    except Exception:
        return None


def consommer(racine, entree):
    """Ajoute la ligne `consommee` de la dérogation, sous verrou (lecture + ajout) quand le module
    existe : la dérogation est relue sous le verrou, une consommation concurrente l'a peut-être déjà
    prise. Vrai seulement si la ligne est écrite ; toute erreur : faux (le refus est maintenu)."""
    try:
        descripteur = _ouvrir_journal_derogations(racine, os.O_RDWR | os.O_APPEND)
        if descripteur is None:
            return False
        try:
            if fcntl is not None:
                fcntl.flock(descripteur, fcntl.LOCK_EX)
            os.lseek(descripteur, 0, os.SEEK_SET)
            morceaux = []
            while True:
                lu = os.read(descripteur, 65536)
                if not lu:
                    break
                morceaux.append(lu)
            existant = b"".join(morceaux)
            restante = _derogation_non_consommee(_entrees_journal(existant), entree["gate"], entree["chemin"])
            if restante is None or restante["id"] != entree["id"]:
                return False
            horodatage = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
            ligne = "{}  consommee  id={}  gate={}  chemin={}\n".format(horodatage, entree["id"], entree["gate"], _jeton_journal(entree["chemin"], "-"))
            octets = (("\n" if existant and not existant.endswith(b"\n") else "") + ligne).encode("utf-8")
            while octets:
                octets = octets[os.write(descripteur, octets):]
        finally:
            os.close(descripteur)
        return True
    except Exception:
        return False


def citer(entree):
    champs = entree["champs"]
    return "[planning-core] dérogation #%s consommée pour %s sur %s — accordée par %s (%s, %s) : %s" % (
        entree["id"], entree["gate"], entree["chemin"], champs["qui"], champs["canal"], champs["date"], champs["raison"])


def decider(verdicts, contexte):
    """Entonnoir unique (P45-D-03a, P45-D-08, P45-D-13) : (raisons de refus, citations). Un gate armed
    refuse, sauf si une dérogation active couvre (gate, chemin) ; un gate en observe écrit une ligne au
    journal d'observation et ne dit RIEN au modèle (une dérogation n'y sert à rien et n'y est pas consommée).
    Lot A (revue m2 ; décision du manager vf-dev-manager, 2026-10-01) : une dérogation n'est consommée et citée
    que si la décision FINALE est un passage grâce à elle — tant qu'un verdict armé reste refusé (un autre gate
    sans dérogation, le rôle par exemple), aucune dérogation n'est consommée : elle ne se brûle pas pour rien."""
    refus = []
    citations = []
    couverts = []
    for verdict in verdicts:
        etat = TABLE_ARMEMENT.get(verdict.gate)
        if etat == "armed":  # decider-armed
            entree = None if verdict.chemin_rel is None else derogation_active(contexte["racine"], verdict.gate, verdict.chemin_rel)
            if entree is None:
                refus.append("[planning-core] %s : %s" % (verdict.gate, verdict.raison))
            else:
                couverts.append((verdict, entree))
        else:
            observer(verdict, contexte)
    if refus:  # decider-global
        return refus, citations
    for verdict, entree in couverts:
        if consommer(contexte["racine"], entree):
            inscrire_ecriture_moteur(contexte["racine"], ".planning/" + NOM_JOURNAL_DEROGATIONS, PAR_HOOK)  # d1-moteur-consommation : une écriture du moteur, expliquée au journal de D1
            citations.append(citer(entree))
        else:
            refus.append("[planning-core] %s : %s" % (verdict.gate, verdict.raison))
    return refus, citations


def evaluer_g5(contexte):
    """G5 (P45-D-07, P45-D-11) : toute écriture par Write, Edit ou NotebookEdit d'un fichier dont le
    nom, casse ignorée, est VERDICT.md, sous le `.planning/` d'un lab adhérent, est un verdict de G5 —
    quel que soit le rôle (fil principal et agent inconnu compris). Le chemin est résolu physiquement.
    Seule la commande poser-verdict.sh (lancée par Bash, jamais vue ici) pose un VERDICT.md. Identité
    (45-05, Pattern 5) : un fichier existant lié en dur à un VERDICT.md du dossier de planning, sous
    un autre nom, est ce VERDICT.md."""
    racine = contexte["racine"]  # g5-sonde
    if contexte["outil"] not in OUTILS_ECRITURE or not contexte["ecrit"]:
        return []
    rel = os.path.relpath(os.path.realpath(contexte["ecrit"]), racine)
    composants = [c for c in rel.split(os.sep) if c not in ("", ".")]
    if not _lien_dur_vers_verdict(contexte["ecrit"], racine):  # g5-identite
        if not composants or composants[0].casefold() != ".planning":  # g5-perimetre
            return []
        if composants[-1].casefold() != NOM_VERDICT:  # g5-casse
            return []
    return [Verdict("G5", "/".join(composants), RAISON_G5)]


def _verdicts_du_planning(planning):
    """Chemins des VERDICT.md (casse ignorée) sous `planning` : parcours trié, liens de dossier non suivis,
    borné à BORNE_PARCOURS_VERDICTS entrées."""
    trouves, vus = [], 0
    for dossier, sous_dossiers, fichiers in os.walk(planning, followlinks=False):
        sous_dossiers.sort()
        for nom in sorted(fichiers):
            vus += 1
            if vus > BORNE_PARCOURS_VERDICTS:
                return trouves
            if nom.casefold() == NOM_VERDICT:
                trouves.append(os.path.join(dossier, nom))
    return trouves


def _lien_dur_vers_verdict(ecrit, racine):
    """Vrai si `ecrit` est un fichier régulier existant, lié en dur (st_nlink > 1), qui est le même fichier
    qu'un VERDICT.md du dossier de planning."""
    try:
        cible = os.path.realpath(ecrit)
        etat = os.stat(cible)
    except OSError:
        return False
    if not stat.S_ISREG(etat.st_mode) or etat.st_nlink <= 1:
        return False
    for verdict in _verdicts_du_planning(os.path.realpath(os.path.join(racine, ".planning"))):
        try:
            if os.path.samefile(cible, verdict):  # g5-samefile
                return True
        except OSError:
            continue
    return False


# --- G6 : fichiers générés, posés par le moteur de recalcul ou par la commande de dérogation (45-05) -
# Toute écriture par Write, Edit ou NotebookEdit de l'un des noms ci-dessous, enfant DIRECT du dossier
# de planning d'un lab adhérent, est un verdict de G6, quel que soit le rôle. Les fichiers de
# compartiment (workstreams, compartments) et tout fichier plus profond ne sont pas visés (P45-D-13,
# Pitfall 9). Le motif dit par quelle commande poser le fichier : le Stop de la 44 invite à mettre à
# jour l'état, le refus ne doit pas le contredire. Le cache du recalcul est protégé (F7b = f7b-oui, Willy,
# AskUserQuestion session principale, 2026-09-30) ; config.json l'est pour l'adhésion seulement (F6 =
# f6-oui, même canal, même date) : une écriture qui change ou retire planning_version désarmerait tous
# les gates (P45-D-01), les autres clés restent libres. Phase 46 (46-07, P46-D-07a) : le journal de D1 est protégé comme celui des
# dérogations (écriture par outil refusée, genre `d1`) ; il n'est JAMAIS surveillé (un watcher sur le fichier que sa propre trace
# réécrit bouclerait).
GENERES_PAR_RECALC = ("STATE.md", "INDEX.md", "cloture.log", ".recalc-cache.json")  # g6-noms
NOM_CONFIG = "config.json"
PROTEGES_G6 = dict([(nom.casefold(), (nom, "recalc")) for nom in GENERES_PAR_RECALC]
                   + [(NOM_JOURNAL_DEROGATIONS.casefold(), (NOM_JOURNAL_DEROGATIONS, "derog")),
                      (NOM_SURVEILLANCE.casefold(), (NOM_SURVEILLANCE, "d1")),
                      (NOM_CONFIG.casefold(), (NOM_CONFIG, "adhesion"))])
RAISON_ADHESION = ("config.json : changer ou retirer l'adhésion cycles-v1 désarmerait les gates (P45-D-01) ; "
                   "une écriture par outil doit garder planning_version = cycles-v1")
RAISON_ADHESION_FORME = ("config.json : ce contenu déclare bien planning_version = cycles-v1, mais pas sous la forme que reconnaît la couche shell de repli "
                         "de la commande enregistrée (clé et valeur sur UNE même ligne, `\"planning_version\": \"cycles-v1\"` écrit tel quel, sans échappement "
                         "de la clé ni de la valeur) ; une panne du cœur ne reconnaîtrait plus le lab adhérent et tairait les gates (F-02, N-05) — réécrire sur cette forme")
RAISON_ADHESION_INVERIFIABLE = ("config.json : cette écriture par outil ne permet pas de vérifier que l'adhésion cycles-v1 "
                                "est conservée (Edit inapplicable au contenu actuel, NotebookEdit, contenu illisible) ; "
                                "refusée par précaution (P45-D-01)")
BORNE_PARCOURS_VERDICTS = 20000


def raison_g6(nom, genre):
    if genre == "derog":
        return ("%s est un fichier inscrit par deroger-gate.sh — l'écriture par outil est refusée ; "
                "inscrivez la dérogation par deroger-gate.sh" % nom)
    if genre == "d1":
        return "%s est inscrit par le moteur (D1) : l'écriture par outil est refusée ; ce journal ne se rédige pas" % nom
    return ("%s est un fichier généré par recalc-planning.sh — l'écriture par outil est refusée ; "
            "recalculez par recalc-planning.sh" % nom)


# Identité (Pattern 5) : G6 et G5 comparent des fichiers, pas des chaînes. Une cible EXISTANTE se compare
# par `os.path.samefile` (lien dur, variante de casse du disque, alias du dossier de planning), une
# création par le dossier parent résolu physiquement et le nom passé en casefold ; `..` et les liens de
# dossier sont résolus par realpath avant toute comparaison.
def _meme_dossier(a, b):
    try:
        return os.path.samefile(a, b)
    except OSError:
        return a.casefold() == b.casefold()


def fichier_protege(ecrit, racine):
    """(nom canonique, genre) du fichier protégé de G6 que `ecrit` désigne, ou None."""
    planning = os.path.realpath(os.path.join(racine, ".planning"))
    cible = os.path.realpath(ecrit)
    parent, nom = os.path.split(cible)
    a_la_racine = _meme_dossier(parent, planning)  # g6-racine
    if a_la_racine and nom.casefold() in PROTEGES_G6:  # id-casefold
        return PROTEGES_G6[nom.casefold()]
    if os.path.lexists(cible):
        try:
            entrees = sorted(os.listdir(planning))
        except OSError:
            entrees = []
        for entree in entrees:
            if entree.casefold() not in PROTEGES_G6:
                continue
            try:
                if os.path.samefile(cible, os.path.join(planning, entree)):  # g6-samefile
                    return PROTEGES_G6[entree.casefold()]
            except OSError:
                continue
    return None


# Q-G6 = (b) (Willy, AskUserQuestion session principale, 2026-10-01) : G6 protège aussi les SCRIPTS du hook, là où
# l'installeur les pose dans un lab en scope projet (`<lab>/.claude/scripts/`) : le script du hook central et son canary.
# Même identité que les fichiers générés (existant par samefile : lien dur, lien symbolique, variante de casse ; création
# par le dossier parent résolu physiquement et le nom en casefold ; `..` et chemins relatifs par realpath). Les réglages
# `.claude/settings*.json` NE SONT PAS protégés (limite (y) déclarée) ; le scope compte (`~/.claude/scripts/`) n'est sous
# aucun lab adhérent (sauf si le HOME est lui-même un lab adhérent) : limite déclarée, jamais présentée comme protégée.
# Bash n'est pas couvert (P45-D-10). Une dérogation nominative couvre le chemin `.claude/scripts/<nom>` comme celui d'un fichier généré.
SCRIPTS_HOOK_G6 = ("planning-hook.sh", "check-gates-alive.sh")  # g6-scripts
DOSSIER_SCRIPTS_REL = (".claude", "scripts")


def script_protege(ecrit, racine):
    """Nom canonique du script du hook que `ecrit` désigne sous `<racine>/.claude/scripts/`, ou None."""
    dossier = os.path.join(racine, *DOSSIER_SCRIPTS_REL)
    cible = os.path.realpath(ecrit)
    parent, nom = os.path.split(cible)
    if _meme_dossier(parent, os.path.realpath(dossier)):  # g6-script-racine
        for canonique in SCRIPTS_HOOK_G6:
            if canonique.casefold() == nom.casefold():  # g6-script-casefold
                return canonique
    if os.path.lexists(cible):
        for canonique in SCRIPTS_HOOK_G6:
            try:
                if os.path.samefile(cible, os.path.join(dossier, canonique)):  # g6-script-samefile
                    return canonique
            except OSError:
                continue
    return None


def _appliquer_edit(cible, entree):
    """Contenu de `cible` après l'Edit, ou None si l'Edit ne s'applique pas au contenu actuel (old_string
    vide, absent, ou ambigu sans replace_all) : l'effet sur l'adhésion serait invérifiable."""
    ancien, nouveau = entree.get("old_string"), entree.get("new_string")
    if not isinstance(ancien, str) or not isinstance(nouveau, str) or ancien == "":
        return None
    try:
        descripteur = os.open(cible, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
            courant = fh.read()
    except (OSError, UnicodeDecodeError):
        return None
    n = courant.count(ancien)
    if entree.get("replace_all") is True:
        return courant.replace(ancien, nouveau) if n > 0 else None
    return courant.replace(ancien, nouveau, 1) if n == 1 else None


def _texte_adherent(texte):
    try:
        donnees = json.loads(texte)
    except ValueError:
        return False
    return isinstance(donnees, dict) and isinstance(donnees.get("planning_version"), str) \
        and donnees["planning_version"] == SCHEMA_ADHESION


def _reconnu_par_le_repli(texte):
    """Vrai si `grep -a -q -E MOTIF_ADHESION_REPLI` reconnaîtrait ce contenu. `[[:space:]]` du motif est traduit en espace, tabulation, CR, VT, FF
    (jamais le saut de ligne : grep travaille ligne à ligne, et le motif n'a aucun joker qui franchirait une ligne)."""
    motif = re.compile(MOTIF_ADHESION_REPLI.replace("[[:space:]]", r"[ \t\r\v\f]"))  # repli-espaces
    return motif.search(texte) is not None


def raison_adhesion_refusee(texte):
    """Raison du refus d'un config.json : le contenu déclare l'adhésion mais la couche shell de repli ne la reconnaît pas (N-05, re-audit du
    2026-10-01 : la contrainte de MISE EN FORME est nommée, pas « changer ou retirer l'adhésion »), sinon l'adhésion est réellement perdue."""
    return RAISON_ADHESION_FORME if _texte_adherent(texte) else RAISON_ADHESION  # raison-forme


def adhesion_conservee(contexte, cible):
    """None si l'écriture proposée laisse planning_version = cycles-v1 ; sinon la raison du refus (F6)."""
    entree = contexte["payload"].get("tool_input")
    if contexte["outil"] == "NotebookEdit" or not isinstance(entree, dict):
        return RAISON_ADHESION_INVERIFIABLE
    texte = entree.get("content") if contexte["outil"] == "Write" else _appliquer_edit(cible, entree)
    if not isinstance(texte, str):
        return RAISON_ADHESION_INVERIFIABLE
    return None if (_texte_adherent(texte) and _reconnu_par_le_repli(texte)) else raison_adhesion_refusee(texte)  # g6-adhesion


def evaluer_g6(contexte):
    """G6 (GATE-04, P45-D-13 ; F6 et F7b) : écriture par outil d'un fichier généré situé directement à la
    racine du dossier de planning d'un lab adhérent, ou d'un config.json qui perdrait l'adhésion, ou (Q-G6 = b, Willy,
    AskUserQuestion session principale, 2026-10-01) d'un script du hook posé sous `<lab>/.claude/scripts/` d'un lab adhérent.
    Seule lecture de config.json : le contenu que l'Edit produirait (P45-D-01)."""
    if contexte["outil"] not in OUTILS_ECRITURE or not contexte["ecrit"]:
        return []
    trouve = fichier_protege(contexte["ecrit"], contexte["racine"])
    if trouve is None:
        script = script_protege(contexte["ecrit"], contexte["racine"])
        if script is None:
            return []
        chemin_script = "/".join(DOSSIER_SCRIPTS_REL) + "/" + script
        return [Verdict("G6", chemin_script, ("%s est un script du hook central posé par l'installeur — l'écriture par outil est "
                                              "refusée ; mettez à jour VibeFlow (/vf-update), ou inscrivez une dérogation par "
                                              "deroger-gate.sh" % chemin_script))]
    nom, genre = trouve
    chemin_rel = ".planning/" + nom
    if genre != "adhesion":
        return [Verdict("G6", chemin_rel, raison_g6(nom, genre))]
    raison = adhesion_conservee(contexte, os.path.realpath(contexte["ecrit"]))
    return [] if raison is None else [Verdict("G6", chemin_rel, raison)]


# --- G1 : pas de plan sans cadrage (GATE-06, 45-06 ; spec §5) ----------------------------------------
# Toute écriture par Write ou Edit d'un PLAN.md de forme modèle — `.planning/cycles/<cycle>/phases/<phase>/
# PLAN.md` ou `.../phases/<phase>/plans/<plan>/PLAN.md`, chaque nom d'unité conforme à NOM_UNITE, les noms
# fixes comparés en casefold, le chemin résolu physiquement (identité de 45-05) — est jugée sur la phase : pas
# de CADRAGE.md dans son dossier, refus. Un PLAN.md hors de cette forme (socle v2, nom d'unité invalide) n'est
# jamais visé. G1 lit l'état que le modèle de la 44 dérive déjà ; il ne refuse JAMAIS un état que le modèle ne
# peut pas lire (F5 = f5-etats, P45-D-21a) : la suite compare chaque phase des bancs au recalcul.
def unite_de_plan(composants):
    """Composants du dossier de la PHASE jugée (cinq premiers composants, relatifs à la racine du lab) si
    `composants` désignent un PLAN.md de forme modèle, sinon None. Sous `plans/<plan>/`, la phase jugée reste
    la phase, jamais le plan."""
    n = len(composants)
    if n not in (6, 8) or composants[-1].casefold() != "plan.md":
        return None
    if composants[0].casefold() != ".planning" or composants[1].casefold() != "cycles" or composants[3].casefold() != "phases":
        return None
    if n == 8 and composants[5].casefold() != "plans":
        return None
    unites = [composants[2], composants[4]] + ([composants[6]] if n == 8 else [])
    if not all(NOM_UNITE.match(u) for u in unites):
        return None
    return composants[:5]  # g1-phase


def _ids_ouverts(donnees):
    """Identifiants des lignes structurantes sans statut du registre (même critère que `lire_registre`) ; `?` si la
    ligne n'en porte pas."""
    ids = []
    for item in donnees.get("inconnues", []):
        if item.get("structurante") == "oui" and not (isinstance(item.get("statut"), str) and item.get("statut").strip() != ""):
            ids.append(item["id"] if isinstance(item.get("id"), str) and item["id"] != "" else "?")
    return ids


def evaluer_g1(contexte):
    """G1 (GATE-06) : écriture par Write ou Edit d'un PLAN.md de forme modèle dans une phase sans CADRAGE.md ou dont
    le registre porte au moins une ligne `structurante: oui` sans statut (toute valeur non vide ferme la ligne,
    `inconnues: []` est clos — la valeur du statut n'est jamais jugée, spec §3.1)."""
    if contexte["outil"] not in ("Write", "Edit") or not contexte["ecrit"]:
        return []
    racine = contexte["racine"]
    rel = os.path.relpath(os.path.realpath(contexte["ecrit"]), racine)
    composants = [c for c in rel.split(os.sep) if c not in ("", ".")]
    dossier_phase = unite_de_plan(composants)  # g1-forme
    if dossier_phase is None:
        return []
    phase = dossier_phase[-1]
    chemin_rel = "/".join(composants)
    cadrage = os.path.join(racine, *dossier_phase) + os.sep + "CADRAGE.md"
    if not os.path.lexists(cadrage):  # g1-cadrage
        return [Verdict("G1", chemin_rel, "la phase %s n'a pas de CADRAGE.md — cadrez avant de planifier (spec §5)" % phase)]
    # F5 = f5-etats (P45-D-21a) : un CADRAGE.md que le modèle ne peut pas lire (non régulier — dossier, lien, autre
    # type —, frontmatter invalide, registre invalide ou format hérité sans clé `inconnues:`) est un état
    # INDÉTERMINÉ : le modèle ne l'interdit pas, G1 ne le refuse jamais (limite T-45-55, nommée et acceptée).
    if not est_fichier_regulier(cadrage):
        return []
    statut, donnees = lire_frontmatter_fichier(cadrage)
    if statut != "ok":
        return []
    registre_ok, registre_clos = lire_registre(donnees)
    if not registre_ok:  # g1-bord
        return []
    if registre_clos:  # g1-ouvert
        return []
    return [Verdict("G1", chemin_rel, "le registre de CADRAGE.md de la phase %s porte des lignes structurantes sans statut (%s) — "
                                      "tranchez-les avant de planifier (spec §5)" % (phase, ", ".join(_ids_ouverts(donnees))))]


# --- G3 : pas de clôture sans livrable (CLOT-01, 46-05 ; P46-D-01, P46-D-12) ----------------------------------------------
# Toute écriture par Write, Edit ou NotebookEdit d'un CLOTURE.md d'unité de forme modèle — `.planning/cycles/<cycle>/phases/<phase>`
# ou `.../phases/<phase>/plans/<plan>/CLOTURE.md`, noms d'unité conformes à NOM_UNITE, noms fixes en casefold, chemin résolu
# physiquement — est jugée sur le `PLAN.md` voisin : un livrable déclaré par `ecrit:` absent, vide, lien ou hors borne (le prédicat
# partagé `livrables_presents`, MÊME chaîne que la règle R4 du recalcul, R-CROISE-01) refuse ; un PLAN.md absent, illisible, de plus de
# 1 Mio (BORNE_LECTURE_PLAN : jamais lu au-delà, A11) ou sans `ecrit:` valide refuse aussi (l'unité est indéterminée au modèle, R1 et R2 :
# écart assumé avec G1, qui se tait sur un état illisible, F5). Un CLOTURE.md de toute autre forme (planning de style GSD, niveau cycle, nom voisin) n'est jamais jugé.
def unite_de_fichier(composants, nom):
    """Composants du DOSSIER de l'unité (cinq ou sept, relatifs à la racine du lab) si `composants` désignent le fichier `nom`
    (casefold) d'une unité de forme modèle, sinon None. Généralise `unite_de_plan` sans la toucher ; même forme que `forme_unite` de
    poser-verdict.sh (contrôle croisé R-FORME-01). Sous `plans/<plan>/`, l'unité jugée est le plan, jamais la phase."""
    n = len(composants)
    if n not in (6, 8) or composants[-1].casefold() != nom.casefold():
        return None
    if composants[0].casefold() != ".planning" or composants[1].casefold() != "cycles" or composants[3].casefold() != "phases":
        return None
    if n == 8 and composants[5].casefold() != "plans":
        return None
    unites = [composants[2], composants[4]] + ([composants[6]] if n == 8 else [])
    if not all(NOM_UNITE.match(u) for u in unites):
        return None
    return composants[:-1]


BORNE_LECTURE_PLAN = 1048576  # A11 (fix-46-a) : au-delà, le PLAN.md de l'unité n'est pas lu (G3 et G4 refusent)
RAISON_G3_PLAN_BORNE = ("PLAN.md de l'unité au-delà de %d octets (BORNE_LECTURE_PLAN) : non lu — l'unité est indéterminée au hook, "
                        "la clôture est refusée" % BORNE_LECTURE_PLAN)
RAISON_G4_PLAN_BORNE = ("PLAN.md de l'unité au-delà de %d octets (BORNE_LECTURE_PLAN) : non lu — le verdict ne peut pas être vérifié"
                        % BORNE_LECTURE_PLAN)


def octets_plan_du_dossier(dossier):
    """(statut, octets) du PLAN.md de l'unité `dossier` : `ok` et ses octets ; `illisible` (pas un fichier régulier — absent, lien,
    dossier, tube — ou erreur de lecture) ; `hors-borne` au-delà de BORNE_LECTURE_PLAN octets LUS (lecture bornée à
    BORNE_LECTURE_PLAN + 1 octets, jamais la taille annoncée : un fichier creux de 2 Gio ne coûte qu'un Mio). Ouverture sans suivre de
    lien ni bloquer, fstat régulier. Jamais un contenu partiel (A11, fix-46-a)."""
    chemin = os.path.join(dossier, "PLAN.md")
    if not est_fichier_regulier(chemin):
        return ("illisible", None)
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN | SANS_BLOCAGE)
        with os.fdopen(descripteur, "rb") as fh:
            if not stat.S_ISREG(os.fstat(fh.fileno()).st_mode):
                return ("illisible", None)
            octets = fh.read(BORNE_LECTURE_PLAN + 1)  # plan-lecture-bornee
    except OSError:
        return ("illisible", None)
    if len(octets) > BORNE_LECTURE_PLAN:  # plan-hors-borne
        return ("hors-borne", None)
    return ("ok", octets)


RAISON_G3_PLAN = "PLAN.md de l'unité absent, illisible ou sans ecrit: valide — l'unité est indéterminée au modèle, la clôture est refusée"
LIBELLES_LIVRABLE_G3 = {"absent": "absent", "vide": "vide", "lien": "lien", "borne": "hors borne", "illisible": "illisible"}


def evaluer_g3(contexte):
    """G3 : voir l'en-tête de section. Verdict `G3` sur le chemin relatif du CLOTURE.md écrit (dérogation nominative sur ce chemin)."""
    racine = contexte["racine"]  # g3-sonde
    if contexte["outil"] not in OUTILS_ECRITURE or not contexte["ecrit"]:
        return []
    rel = os.path.relpath(os.path.realpath(contexte["ecrit"]), racine)
    composants = [c for c in rel.split(os.sep) if c not in ("", ".")]
    unite = unite_de_fichier(composants, "CLOTURE.md")  # g3-forme
    if unite is None:
        return []
    chemin_rel = "/".join(composants)
    lecture, octets = octets_plan_du_dossier(os.path.join(racine, *unite))
    if lecture == "hors-borne":  # g3-lecture-plan
        return [Verdict("G3", chemin_rel, RAISON_G3_PLAN_BORNE)]
    motif, detail = ("frontmatter", "illisible") if octets is None else entrees_du_plan(octets, "/".join(unite))  # g3-plan
    if motif == "unite":
        return [Verdict("G3", chemin_rel, "ecrit: contient le dossier de l'unité (%s) — l'unité est indéterminée au modèle, la clôture est refusée" % detail)]
    if motif != "ok":
        return [Verdict("G3", chemin_rel, RAISON_G3_PLAN)]
    for entree, statut, _detail in livrables_presents(racine, detail):
        if statut != "present":  # g3-livrable
            return [Verdict("G3", chemin_rel, "livrable déclaré %s : %s — produisez-le (non vide, sans lien) avant de clore (spec §5)"
                            % (LIBELLES_LIVRABLE_G3.get(statut, statut), entree))]
    return []


# --- G4 : pas de SUMMARY.md sans verdict qui tienne (CLOT-02, CLOT-03, 46-05 ; P46-D-01, P46-D-03) ----------------------------
# Toute écriture par Write, Edit ou NotebookEdit d'un SUMMARY.md d'unité de forme modèle (même forme que G3, `unite_de_fichier`) est jugée
# sur le `VERDICT.md` voisin : absent, invalide (règle R6 du recalcul : constats vides ou hors passé/échec), périmé (`hash` différent du
# sha256 du PLAN.md, `hash_livrables` absent ou différent de l'empreinte des livrables), ou portant un constat `échec` -> refus ; un PLAN.md
# absent, illisible, de plus de 1 Mio (BORNE_LECTURE_PLAN, A11) ou sans `ecrit:` valide refuse aussi. Même
# ordre que le recalcul (R6, puis E, puis R7) : un verdict périmé se re-juge avant qu'on lise ses constats. Le prédicat est réévalué à
# CHAQUE écriture : retoucher le SUMMARY.md d'une unité close reste permis tant que le verdict tient. Les empreintes viennent de la copie
# partagée du bloc (jamais d'une réécriture) ; un SUMMARY.md de toute autre forme n'est jamais jugé.
RAISON_G4_PLAN = "PLAN.md de l'unité absent, illisible ou sans ecrit: valide — l'unité est indéterminée au modèle, le verdict ne peut pas être vérifié"


def _tentative_suivante(donnees):
    """Entier `tentative` + 1 lu dans le frontmatter du verdict, ou None si la valeur n'est pas un entier décimal."""
    brute = donnees.get("tentative")
    if isinstance(brute, str) and re.fullmatch(r"[0-9]{1,6}", brute.strip()):
        return int(brute.strip()) + 1
    return None


def evaluer_g4(contexte):
    """G4 : voir l'en-tête de section. Verdict `G4` sur le chemin relatif du SUMMARY.md écrit (dérogation nominative sur ce chemin)."""
    racine = contexte["racine"]  # g4-sonde
    if contexte["outil"] not in OUTILS_ECRITURE or not contexte["ecrit"]:
        return []
    rel = os.path.relpath(os.path.realpath(contexte["ecrit"]), racine)
    composants = [c for c in rel.split(os.sep) if c not in ("", ".")]
    unite = unite_de_fichier(composants, "SUMMARY.md")  # g4-forme
    if unite is None:
        return []
    import hashlib
    chemin_rel = "/".join(composants)
    dossier = os.path.join(racine, *unite)
    verdict = os.path.join(dossier, "VERDICT.md")
    if not os.path.lexists(verdict):  # g4-verdict-absent
        return [Verdict("G4", chemin_rel, "aucun VERDICT.md : faites juger l'unité (poser-verdict.sh)")]
    statut, donnees = lire_frontmatter_fichier(verdict)
    constats = donnees.get("constats") if statut == "ok" else None
    if not isinstance(constats, list) or len(constats) == 0 or any(  # g4-invalide
            not isinstance(c, dict) or c.get("resultat") not in ("passé", "échec") for c in constats):
        return [Verdict("G4", chemin_rel, "VERDICT.md invalide (règle R6)")]
    suivante = _tentative_suivante(donnees)
    reessai = "" if suivante is None else " (tentative %d)" % suivante
    lecture, octets = octets_plan_du_dossier(dossier)
    if lecture == "hors-borne":  # g4-lecture-plan
        return [Verdict("G4", chemin_rel, RAISON_G4_PLAN_BORNE)]
    motif, detail = ("frontmatter", "illisible") if octets is None else entrees_du_plan(octets, "/".join(unite))
    if motif == "unite":
        return [Verdict("G4", chemin_rel, "ecrit: contient le dossier de l'unité (%s) — l'unité est indéterminée au modèle, le verdict ne peut pas être vérifié" % detail)]
    if motif != "ok":
        return [Verdict("G4", chemin_rel, RAISON_G4_PLAN)]
    perime = Verdict("G4", chemin_rel, "verdict périmé : re-juger" + reessai)
    if donnees.get("hash") != hashlib.sha256(octets).hexdigest():  # g4-hash-plan
        return [perime]
    statut_emp, valeur_emp = empreinte_livrables(racine, detail)
    if statut_emp == "borne":
        return [Verdict("G4", chemin_rel, "livrables hors borne : %s" % valeur_emp)]
    if statut_emp != "ok" or donnees.get("hash_livrables") != valeur_emp:  # g4-hash-livrables
        return [perime]
    for constat in constats:
        if constat.get("resultat") == "échec":  # g4-echec
            return [Verdict("G4", chemin_rel, "constat en échec : %s — corrigez puis re-jugez%s" % (constat.get("critere") or "?", reessai))]
    return []


# --- G7 : pas de planning orphelin sous un lab adhérent (GATE-07, 45-07 ; P45-D-14, spec §2 D-05) ---------------
# Une écriture par Write ou NotebookEdit (Edit ne crée pas de fichier) qui CRÉE un dossier `.planning/` dans un dossier X
# (le DERNIER composant `.planning` du chemin dont le dossier n'existe pas encore ; X = son parent) est jugée : le plus
# proche ancêtre EXISTANT de X qui porte un `.planning/` est la racine du lab (le plus proche gagne, P45-D-01a) ; le
# lab est adhérent, sinon le hook s'est tu avant d'arriver ici. Passage si X porte un marqueur de projet de code — la
# MÊME liste que `has_code_signal` de detect-gsd-engine.sh (un contrôle croisé de la suite extrait le texte du détecteur
# et rougit à tout écart), plus un dossier `*.xcodeproj` directement dans X — ou un `.claude/` habité.
MARQUEURS_CODE = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle", "build.gradle.kts", "composer.json", "Gemfile", "tsconfig.json", "Package.swift")  # g7-marqueurs
SUFFIXE_XCODEPROJ = ".xcodeproj"
NOM_PLANNING = ".planning"
OUTILS_CREATION = ("Write", "NotebookEdit")


def _creation_planning(racine, composants):
    """Indice (dans `composants`, relatifs à la racine du lab) du DERNIER composant `.planning` — hors dernier composant,
    qui serait un fichier — dont le dossier n'existe pas encore sur le disque, ou None. Comparaison en casefold (identité
    de 45-05)."""
    trouve = None
    for i, composant in enumerate(composants[:-1]):
        if composant.casefold() == NOM_PLANNING and not os.path.lexists(os.path.join(racine, *composants[: i + 1])):  # g7-existe
            trouve = i
    return trouve


def porte_marqueur_code(dossier):
    """Vrai si `dossier` porte un marqueur de projet de code : un fichier (test de fichier qui suit un lien, comme `[ -f ]`
    du détecteur) de MARQUEURS_CODE, ou un dossier `*.xcodeproj` directement dedans (comme `[ -d ]`, sans fichier caché,
    comme le glob du détecteur)."""
    for nom in MARQUEURS_CODE:
        if os.path.isfile(os.path.join(dossier, nom)):
            return True
    try:
        noms = sorted(os.listdir(dossier))
    except OSError:
        return False
    return any(n.endswith(SUFFIXE_XCODEPROJ) and not n.startswith(".") and os.path.isdir(os.path.join(dossier, n)) for n in noms)


# Prédicat « habité » (P45-D-14, F4 = f4-litteral) : LE PRÉDICAT LITTÉRAL, rien de plus — au moins un fichier RÉGULIER
# `X/.claude/agents/*.md` ET au moins un fichier RÉGULIER sous `X/.claude/memory/` (lstat : jamais un lien, jamais un dossier).
# Un `.claude/` qui ne porte pas les deux — un `agent-memory/` sans fichier, des agents sans mémoire, une mémoire sans agent,
# un dossier vide — n'est pas habité. Le parcours de la mémoire est borné : au-delà de la borne le prédicat est INDÉTERMINÉ et
# G7 ne refuse pas (jamais un refus sur ce que le hook n'a pas pu lire, comme G1 pour F5).
BORNE_PARCOURS_HABITE = 20000


def _a_un_agent(dossier_claude):
    """Au moins un fichier régulier `agents/*.md` directement sous `dossier_claude` (glob : jamais un fichier caché)."""
    agents = os.path.join(dossier_claude, "agents")
    try:
        noms = sorted(os.listdir(agents))
    except OSError:
        return False
    for nom in noms:
        if nom.endswith(".md") and not nom.startswith(".") and est_fichier_regulier(os.path.join(agents, nom)):  # g7-regulier-agent
            return True
    return False


def _a_une_memoire(dossier_claude):
    """Au moins un fichier régulier sous `dossier_claude/memory/` (à toute profondeur, liens de dossier non suivis) ; vrai
    aussi quand la borne de parcours est atteinte (indéterminé : jamais un refus)."""
    vus = 0
    for dossier, sous_dossiers, fichiers in os.walk(os.path.join(dossier_claude, "memory"), followlinks=False):
        sous_dossiers.sort()
        for nom in sorted(fichiers):
            vus += 1
            if vus > BORNE_PARCOURS_HABITE:
                return True
            if est_fichier_regulier(os.path.join(dossier, nom)):  # g7-regulier-memoire
                return True
    return False


def lab_habite(dossier):
    """Le `.claude/` de `dossier` est habité : au moins un agent ET au moins une mémoire (prédicat littéral de P45-D-14)."""
    claude = os.path.join(dossier, ".claude")
    return _a_un_agent(claude) and _a_une_memoire(claude)


def evaluer_g7(contexte):
    """G7 (GATE-07) : création d'un `.planning/` dans un dossier X sans marqueur de projet de code ni `.claude/` habité,
    sous un lab adhérent (`.claude/` habité : prédicat littéral de P45-D-14, `lab_habite`)."""
    if contexte["outil"] not in OUTILS_CREATION or not contexte["ecrit"]:
        return []
    racine = contexte["racine"]
    rel = os.path.relpath(os.path.realpath(contexte["ecrit"]), racine)
    composants = [c for c in rel.split(os.sep) if c not in ("", ".")]
    indice = _creation_planning(racine, composants)
    if indice is None:
        return []
    x_rel = "/".join(composants[:indice])
    x = os.path.join(racine, *composants[:indice])
    if porte_marqueur_code(x):  # g7-marqueur
        return []
    if lab_habite(x):  # g7-habite
        return []
    return [Verdict("G7", "/".join(composants), "créer un .planning/ dans %s exige un .claude/ habité (au moins un agent et une mémoire) ou un "
                                                 "marqueur de projet de code — sinon ce planning serait orphelin (spec D-05)" % x_rel)]


# --- Rôle de l'agent écrivain (GATE-09, 45-08 ; P45-D-05, P45-D-05a, P45-D-05b, P45-D-09, P45-D-11) ------------
# Le rôle se DÉRIVE de la définition de l'agent (son frontmatter), par les prédicats de check-agents.sh :
# juge = I5 (disallowedTools retire Write ET Edit, aucune allowlist Agent(...)/Task(...) non vide) ; manager = I6
# (allowlist non vide, vf-internal ne vaut pas true) ; worker = vf-internal: true et pas juge ; producteur = tout
# autre agent résolu. Aucun champ `vf-role:`, aucune table centrale.
# Choix du planificateur (P45-D-05a) : RÉIMPLÉMENTATION, pas d'appel de check-agents.sh — planning-core ne dépend
# d'aucun module (module.json requires []), un lab qui l'installe seul n'a pas ce script, et un appel par écriture
# coûterait un processus de plus. Le contrôle croisé scripts/tests/test-role-hook-vs-check-agents.sh compare ce
# code à l'oracle sur tout le corpus d'agents du dépôt et sur des fixtures adverses, et peut rougir. Les fonctions
# portent le suffixe `_agent` : elles ne se confondent pas avec le parseur de frontmatter du modèle de la 44.
# Le tokenizer est celui de check-agents.sh : découpage à PROFONDEUR DE PARENTHÈSES, jamais un split sur la virgule.
AGENT_TOOL_NAMES = ("Agent", "Task")
OUTILS_DISPATCH = ("Agent", "Task")  # role-dispatch
_CLE_AGENT_RE = re.compile(r"^([A-Za-z_-]+):\s*(.*)$")


class _Puce(object):
    """Résultat de `puce_agent` : l'interface du `re.Match` de l'ancienne expression, `group(1)` seul."""
    __slots__ = ("_texte",)

    def __init__(self, texte):
        self._texte = texte

    def group(self, rang=0):
        return self._texte


def puce_agent(ligne):
    """Équivalent LINÉAIRE de `re.match(r"^\\s+-\\s+(.+?)(\\s+#.*)?$", ligne)` pour une ligne sans saut de ligne : un objet à `group(1)` (le
    texte de la puce, commentaire ` #…` final exclu) ou None. Lot A, H2 : l'expression était quadratique (60 Ko d'espaces dans une
    ligne de définition : plus de 20 s, un fail-open) ; la suite compare les deux sur un corpus de petits alphabets. Cas limites de
    l'ancienne expression conservés : un texte réduit à des blancs rend le dernier blanc (le premier groupe de blancs en rend un au
    texte), le commentaire ne s'ouvre que sur un `#` précédé d'un blanc, et il emporte tout le blanc qui le précède."""
    reste = ligne.lstrip()
    if len(reste) == len(ligne) or not reste.startswith("-"):
        return None
    apres = reste[1:]
    corps = apres.lstrip()
    blancs = len(apres) - len(corps)
    if blancs == 0:
        return None
    if corps == "":
        return _Puce(apres[-1]) if blancs >= 2 else None
    diese = corps.find("#", 2)
    while diese != -1:
        if corps[diese - 1].isspace():  # puce-lineaire
            debut = diese - 1
            while debut > 0 and corps[debut - 1].isspace():
                debut -= 1
            return _Puce(corps[:debut])
        diese = corps.find("#", diese + 1)
    return _Puce(corps)


def frontmatter_agent(texte):
    """Dictionnaire du frontmatter d'une définition d'agent, ou None si absent ou jamais refermé. Même
    sémantique que `parse_frontmatter` de check-agents.sh (scalaire dé-quoté, liste en ligne, puces YAML,
    continuation indentée) : `name:` et `vf-internal:` se lisent ici. Les lignes de continuation d'un scalaire
    s'accumulent dans une liste jointe une seule fois (lot A, H2 : la concaténation répétée était quadratique)."""
    lignes = texte.split("\n")
    if not lignes or lignes[0].strip() != "---":
        return None
    fm, i, cle = {}, 1, None
    suite = {}
    while i < len(lignes):
        ligne = lignes[i]
        if ligne.strip() == "---":
            return _finaliser_continuations(fm, suite)
        m = _CLE_AGENT_RE.match(ligne)
        if m:
            cle = m.group(1)
            suite.pop(cle, None)
            val = m.group(2).strip()
            if val.startswith("[") and val.endswith("]"):
                fm[cle] = [x.strip().strip(chr(34)).strip(chr(39)) for x in val[1:-1].split(",") if x.strip()]
            elif val == "" or val == ">" or val == "|":
                fm[cle] = "" if val == "" else val
            else:
                if len(val) >= 2 and val[0] == val[-1] and val[0] in (chr(34), chr(39)):
                    val = val[1:-1]
                fm[cle] = val
        elif cle is not None:
            item = puce_agent(ligne)  # puce-agent-fm
            if item and isinstance(fm.get(cle), list):
                fm[cle].append(item.group(1).strip().strip(chr(34)).strip(chr(39)))
            elif item and fm.get(cle) == "" and cle not in suite:
                fm[cle] = [item.group(1).strip().strip(chr(34)).strip(chr(39))]
            elif ligne.startswith("  ") and isinstance(fm.get(cle), str):
                morceau = ligne.strip()
                if cle in suite:
                    if morceau != "":
                        suite[cle].append(morceau)
                elif morceau == "":
                    fm[cle] = fm[cle].strip()
                elif fm[cle].strip() == "":
                    suite[cle] = [morceau]
                else:
                    suite[cle] = [fm[cle].lstrip(), morceau]
        i += 1
    return None


def _finaliser_continuations(fm, suite):
    """Joint, en une fois, les continuations accumulées : l'ancien `(valeur + " " + ligne).strip()` répété. Après la première
    continuation non vide la valeur n'a plus de blanc en bordure : seules les pièces restent à joindre par une espace."""
    for cle, morceaux in suite.items():
        fm[cle] = " ".join(morceaux)
    return fm


def lignes_frontmatter_agent(texte):
    """Lignes BRUTES entre les deux `---` (la re-tokenisation des allowlists repart de la ligne source), ou None."""
    lignes = texte.split("\n")
    if not lignes or lignes[0].strip() != "---":
        return None
    for idx in range(1, len(lignes)):
        if lignes[idx].strip() == "---":
            return lignes[1:idx]
    return None


def champ_brut_agent(lignes, cle):
    """(mode, brut) d'un champ tools:/disallowedTools: : `block` (brut = liste de jetons, puces YAML), `flow` ou
    `scalar` (brut = chaîne à re-tokeniser), (None, None) si la clé est absente. Même lecture de la continuation
    que `extract_raw_field` de check-agents.sh (ligne indentée d'au moins deux espaces ; une ligne vide ou
    non-puce est tolérée au milieu d'un bloc, seule une nouvelle clé le ferme)."""
    if lignes is None:
        return None, None
    n = len(lignes)
    for idx in range(n):
        m = _CLE_AGENT_RE.match(lignes[idx])
        if not (m and m.group(1) == cle):
            continue
        val = m.group(2).strip()
        k = idx + 1
        if val == "":
            puces = []
            while k < n:
                if _CLE_AGENT_RE.match(lignes[k]):
                    break
                item = puce_agent(lignes[k])  # puce-agent-champ
                if item:
                    puces.append(item.group(1).strip())
                k += 1
            if puces:
                return "block", puces
            parts = []
            while k < n and lignes[k].startswith("  ") and lignes[k].strip() and not _CLE_AGENT_RE.match(lignes[k]):
                parts.append(lignes[k].strip())
                k += 1
            return "scalar", " ".join(parts)
        parts = [val]
        while k < n and lignes[k].startswith("  ") and lignes[k].strip() and not _CLE_AGENT_RE.match(lignes[k]):
            parts.append(lignes[k].strip())
            k += 1
        brut = " ".join(parts).strip()
        if brut.startswith("["):
            return "flow", brut
        return "scalar", brut
    return None, None


def decouper_profondeur_agent(brut):
    """(jetons, profondeur) : découpage aux virgules de profondeur de parenthèses NULLE, jamais un split(',') naïf
    — c'est ce qui laisse `Agent(a, b)` intact comme UN jeton. Profondeur = solde ouvertures - fermetures."""
    jetons, profondeur, courant = [], 0, []
    for ch in brut:
        if ch == "(":
            profondeur += 1
            courant.append(ch)
        elif ch == ")":
            profondeur -= 1
            courant.append(ch)
        elif ch == "," and profondeur == 0:  # role-virgule
            jetons.append("".join(courant))
            courant = []
        else:
            courant.append(ch)
    jetons.append("".join(courant))
    return jetons, profondeur


def jetons_agent(mode, brut):
    """(jetons, profondeur) d'un champ : `block` = jetons déjà isolés (dé-quotés un à un) ; `flow` et `scalar` :
    dé-quotage d'UNE paire englobante, crochets retirés, puis découpage à profondeur de parenthèses."""
    def sans_guillemets(s):
        return s[1:-1] if len(s) >= 2 and s[0] == s[-1] and s[0] in (chr(34), chr(39)) else s
    if mode == "block":
        return [sans_guillemets(t) for t in brut], 0
    s = sans_guillemets(brut.strip())
    if s.startswith("[") and s.endswith("]"):
        s = s[1:-1]
    return decouper_profondeur_agent(s)


def jeton_agent(brut):
    """(outil, noms d'agents, message) d'UN jeton d'allowlist : noms None sans parenthèses, [] pour `Agent()` ; un
    message non None (syntaxe) interdit au jeton d'entrer dans une allowlist (`parse_token` de check-agents.sh)."""
    tok = brut.strip()
    if tok == "":
        return None, None, "entrée d'allowlist vide"
    if re.match(r"^(\S+)\s+\(", tok):
        return None, None, "espace avant la parenthèse"
    m = re.match(r"^([A-Za-z0-9_-]+)\((.*)$", tok, re.S)
    if not m:
        if not (re.fullmatch(r"[A-Za-z0-9_-]+", tok) or re.fullmatch(r"mcp__[A-Za-z0-9_-]+__[*]", tok)):
            return None, None, "jeton hors charset"
        return tok, None, None
    nom, reste = m.group(1), m.group(2)
    if not reste.endswith(")"):
        return nom, None, "parenthèse non fermée"
    interieur = reste[:-1]
    if interieur.strip() == "":
        return nom, [], "allowlist vide"
    noms = [a.strip() for a in interieur.split(",") if a.strip() != ""]
    if len(noms) != len(interieur.split(",")):
        return nom, noms, "entrée vide dans l'allowlist"
    return nom, noms, None


def allowlist_agent(lignes):
    """Noms d'agents des jetons `Agent(...)` et `Task(...)` de `tools:` (union), liste vide si le champ est absent
    ou si la profondeur de parenthèses n'est pas nulle (`allowlist_agents` de check-agents.sh)."""
    mode, brut = champ_brut_agent(lignes, "tools")
    if mode is None:
        return []
    jetons, profondeur = jetons_agent(mode, brut)
    if profondeur != 0:
        return []
    dispatch = []
    for jeton in jetons:
        nom, noms, message = jeton_agent(jeton)
        if message is not None or nom is None:
            continue
        if nom in AGENT_TOOL_NAMES and noms:
            dispatch.extend(noms)
    return dispatch


def jetons_nus_agent(lignes, champ):
    """Ensemble des jetons SANS parenthèse d'un champ ; vide si le champ est absent ou l'allowlist mal formée
    (`bare_tokens` de check-agents.sh)."""
    mode, brut = champ_brut_agent(lignes, champ)
    if mode is None:
        return set()
    jetons, profondeur = jetons_agent(mode, brut)
    if profondeur != 0:
        return set()
    return {t.strip() for t in jetons if t.strip() and "(" not in t}


def deriver_role(texte):
    """`juge` | `manager` | `worker` | `producteur` | `illisible` (frontmatter absent ou jamais refermé). I5 d'abord
    (juge : Write ET Edit retirés, aucune allowlist), puis I6 (manager : allowlist non vide, pas vf-internal), puis
    vf-internal: true (worker), sinon producteur (P45-D-05)."""
    lignes = lignes_frontmatter_agent(texte)
    fm = frontmatter_agent(texte)
    if lignes is None or fm is None:
        return "illisible"
    liste = allowlist_agent(lignes)
    interdits = jetons_nus_agent(lignes, "disallowedTools")
    if "Write" in interdits and "Edit" in interdits and not liste:  # role-juge
        return "juge"
    interne = str(fm.get("vf-internal", "")) == "true"
    if liste and not interne:  # role-manager
        return "manager"
    if interne:
        return "worker"
    return "producteur"


def normaliser(nom):
    """Normalisation écrite de P45-D-09 : casefold, puis `_`, espace et `-` unifiés (en `-`), des DEUX côtés d'une
    comparaison ; égalité sur la chaîne entière, aucun préfixe `<plugin>:` retiré."""
    return nom.casefold().replace("_", "-").replace(" ", "-")  # role-normaliser


BORNE_AGENTS_PAR_DOSSIER = 1000
BORNE_PARCOURS_PLUGINS = 20000
PROFONDEUR_VERSION = 4
# Lot A (H2) : une définition d'agent plus grande que BORNE_LECTURE_DEFINITION, ou portant une ligne plus longue que
# BORNE_LIGNE_DEFINITION, est INDÉTERMINÉE (rôle `illisible` : jamais un verdict de rôle) ; l'indexation d'un dossier d'agents lit au
# plus BORNE_OCTETS_INDEX octets au total.
BORNE_LECTURE_DEFINITION = 1048576
BORNE_LIGNE_DEFINITION = 32768
BORNE_OCTETS_INDEX = 8388608
BORNE_ENTETE_DEFINITION = 4096
BORNE_ENTREES_PLUGINS = 64


def lire_definition_bornee(chemin, budget=None):
    """Texte d'une définition (utf-8-sig, fins de ligne universelles comme la lecture texte d'origine), ou None — indéterminé : illisible,
    plus grande que BORNE_LECTURE_DEFINITION, ou portant une ligne plus longue que BORNE_LIGNE_DEFINITION. `budget` ([octets restants])
    décompte la lecture ; épuisé, rend None sans lire."""
    try:
        if budget is not None and budget[0] <= 0:
            return None
        with open(chemin, "rb") as fh:
            octets = fh.read(BORNE_LECTURE_DEFINITION + 1)
        if budget is not None:
            budget[0] -= len(octets)
        if len(octets) > BORNE_LECTURE_DEFINITION:
            return None
        texte = octets.decode("utf-8-sig").replace("\r\n", "\n").replace("\r", "\n")
    except (OSError, UnicodeDecodeError):
        return None
    if any(len(ligne) > BORNE_LIGNE_DEFINITION for ligne in texte.split("\n")):
        return None
    return texte


def lire_definition_agent(chemin, budget=None):
    """(rôle, nom d'agent, texte lu ou None) d'une définition : `name:` du frontmatter, à défaut le nom de fichier (comme
    `agent_display_name`, Pitfall 6) ; rôle `illisible` si le fichier ne se lit pas, dépasse les bornes ou si le frontmatter est abîmé.
    Le rôle n'est dérivé que sur demande (`deriver_role` de `texte`)."""
    repli = os.path.basename(chemin)[:-3]
    texte = lire_definition_bornee(chemin, budget)
    if texte is None:
        return "illisible", repli, None
    fm = frontmatter_agent(texte)
    nom = fm.get("name") if isinstance(fm, dict) else None
    return None, (nom if isinstance(nom, str) and nom else repli), texte


def candidat_definition(chemin, nom_fichier, cible):
    """Vrai si la définition à `chemin` PEUT porter le nom `cible` (nom normalisé) : son nom de fichier le porte, ou l'en-tête borné
    (BORNE_ENTETE_DEFINITION octets) le contient une fois normalisé, ou le frontmatter y reste ouvert (`name:` peut se trouver plus loin :
    incertain, donc candidat). Un sur-ensemble : un faux candidat est écarté par la comparaison du `name:` lu en entier ; un vrai candidat
    n'est jamais manqué (lot C, N1)."""
    if normaliser(nom_fichier[:-3]) == cible:
        return True
    try:
        with open(chemin, "rb") as fh:
            octets = fh.read(BORNE_ENTETE_DEFINITION)
    except OSError:
        return False
    texte = octets.decode("utf-8-sig", "replace").replace("\r\n", "\n").replace("\r", "\n")
    if cible in normaliser(texte):
        return True
    lignes = texte.split("\n")
    if len(octets) >= BORNE_ENTETE_DEFINITION and lignes and lignes[0].strip() == "---":
        return not any(ligne.strip() == "---" for ligne in lignes[1:])
    return False


def definitions_dossier(dossier, cible=None, signaux=None):
    """{nom normalisé: [(rôle, chemin)]} des `*.md` RÉGULIERS directement sous `dossier` (glob : jamais un fichier
    caché ; jamais un lien symbolique, comme check-agents.sh qui refuse un agent .md en lien — A1), parcours trié
    et borné. `cible` (nom normalisé de l'agent appelant) borne l'indexation à ce qui est nécessaire : seuls les fichiers CANDIDATS
    (`candidat_definition`) sont lus en entier et décomptés du budget d'octets, le rôle n'est dérivé que pour les définitions de ce nom
    (lot A, H2 ; lot C, N1 : des fichiers frères triés avant l'agent visé n'épuisent plus le budget). Un budget épuisé sur un candidat rend
    la définition INDÉTERMINÉE (rôle `illisible`) et le signale (`signaux` reçoit `budget-indexation`)."""
    res = {}
    budget = [BORNE_OCTETS_INDEX]
    try:
        noms = sorted(os.listdir(dossier))
    except OSError:
        return res
    for nom in noms[:BORNE_AGENTS_PAR_DOSSIER]:
        chemin = os.path.join(dossier, nom)
        if not nom.endswith(".md") or nom.startswith(".") or not est_fichier_regulier(chemin):
            continue
        if cible is not None and not candidat_definition(chemin, nom, cible):  # indexation-candidats
            continue
        if cible is not None and budget[0] <= 0:
            res.setdefault(cible, []).append(("illisible", chemin))
            if signaux is not None and "budget-indexation" not in signaux:
                signaux.append("budget-indexation")
            continue
        role, nom_agent, texte = lire_definition_agent(chemin, budget)
        cle = normaliser(nom_agent)
        if cible is not None and cle != cible:
            continue
        if role is None:
            role = deriver_role(texte)
        res.setdefault(cle, []).append((role, chemin))
    return res


def _cle_version(nom):
    """Clé de tri d'un nom de dossier de version : suites de chiffres comparées comme des ENTIERS (1.10.0 après 1.9.0, jamais l'ordre
    lexical), une version à suffixe de pré-version (`-beta`) avant la même version sans suffixe."""
    coeur, tiret, pre = nom.partition("-")
    nombres = tuple(int(x) for x in re.findall(r"[0-9]+", coeur))
    return (nombres, 0 if tiret else 1, pre)  # plugin-tri


def _versions_installees(base, plugin):
    """[(clé de version, dossier)] des `installPath` de `<base>/installed_plugins.json` pour `plugin` (clé `<plugin>@<marketplace>`) :
    fichier régulier (lstat, ouvert sans suivre de lien), de taille bornée, JSON ; un `installPath` n'est retenu que s'il est un
    dossier situé sous `base`. Fichier absent, irrégulier, illisible ou sans entrée utilisable : liste vide (le repli est le cache)."""
    chemin = os.path.join(base, "installed_plugins.json")
    if not est_fichier_regulier(chemin):
        return []
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "rb") as fh:
            octets = fh.read(BORNE_LECTURE_DEFINITION + 1)
        if len(octets) > BORNE_LECTURE_DEFINITION:
            return []
        donnees = json.loads(octets.decode("utf-8"))
    except (OSError, ValueError, RecursionError):
        return []
    plugins = donnees.get("plugins") if isinstance(donnees, dict) else None
    if not isinstance(plugins, dict):
        return []
    racine_plugins = os.path.realpath(base)
    res = []
    for cle, entrees in plugins.items():
        if not isinstance(cle, str) or normaliser(cle.partition("@")[0]) != plugin or not isinstance(entrees, list):
            continue
        for entree in entrees[:BORNE_ENTREES_PLUGINS]:
            installe = entree.get("installPath") if isinstance(entree, dict) else None
            if not isinstance(installe, str) or not installe.startswith("/"):
                continue
            reel = os.path.realpath(installe)
            if reel.startswith(racine_plugins + os.sep) and os.path.isdir(reel):
                res.append((_cle_version(os.path.basename(reel)), reel))
    return res


def _sous_dossiers_reels(dossier):
    """Chemins des vrais sous-dossiers (jamais un lien, jamais un nom caché) de `dossier`, triés et bornés."""
    res = []
    try:
        noms = sorted(os.listdir(dossier))
    except OSError:
        return res
    for nom in noms[:BORNE_AGENTS_PAR_DOSSIER]:
        chemin = os.path.join(dossier, nom)
        try:
            if not nom.startswith(".") and stat.S_ISDIR(os.lstat(chemin).st_mode):
                res.append(chemin)
        except OSError:
            continue
    return res


def _versions_du_cache(base, plugin):
    """[(clé de version, dossier)] de `<base>/cache/<marketplace>/<plugin>/<version>` : repli quand installed_plugins.json ne dit rien."""
    res = []
    for marketplace in _sous_dossiers_reels(os.path.join(base, "cache")):
        for dossier_plugin in _sous_dossiers_reels(marketplace):
            if normaliser(os.path.basename(dossier_plugin)) != plugin:
                continue
            for version in _sous_dossiers_reels(dossier_plugin):
                res.append((_cle_version(os.path.basename(version)), version))
    return res


def versions_actives(base, plugin):
    """Dossiers de la version ACTIVE de `plugin` : celle de installed_plugins.json (la plus haute s'il en porte plusieurs), à défaut la plus
    haute du cache (tri de version, pas lexical). Lot A, revue M1 et m5 (décision du manager vf-dev-manager, 2026-10-01) : une version
    ancienne restée en cache ne contredit plus la version active, et seul le dossier de cette version est lu."""
    versions = _versions_installees(base, plugin)  # plugin-installed
    if not versions:
        versions = _versions_du_cache(base, plugin)
    if not versions:
        return []
    haute = max(cle for cle, _chemin in versions)  # plugin-haute
    retenues = []
    for cle, chemin in versions:
        if cle == haute and chemin not in retenues:
            retenues.append(chemin)
    return retenues


def dossiers_agents_version(dossier_version):
    """Dossiers `agents` sous `dossier_version` (jusqu'à PROFONDEUR_VERSION niveaux : `<version>/agents`, `<version>/<module>/agents`,
    `<version>/<module>/content/agents`, disposition mesurée au 45-08), liens de dossier non suivis, dossiers cachés et node_modules
    ignorés, parcours trié et borné."""
    res, vus = [], 0
    for dossier, sous, _fichiers in os.walk(dossier_version, followlinks=False):
        sous[:] = sorted(s for s in sous if not s.startswith(".") and s != "node_modules")
        vus += 1
        if vus > BORNE_PARCOURS_PLUGINS:
            break
        profondeur = 0 if dossier == dossier_version else len(os.path.relpath(dossier, dossier_version).split(os.sep))
        if profondeur >= PROFONDEUR_VERSION:
            sous[:] = []
        if profondeur >= 1 and os.path.basename(dossier) == "agents":
            res.append(dossier)
    return res


def definitions_plugin(home, plugin, cible=None, signaux=None):
    """Définitions des dossiers `agents/` de la version ACTIVE du plugin `plugin` (nom normalisé) sous `<home>/.claude/plugins/`
    (`versions_actives`), les dossiers de cette seule version étant lus."""
    base = os.path.join(home, ".claude", "plugins")
    res = {}
    for version in versions_actives(base, plugin):
        for dossier in dossiers_agents_version(version):
            for cle, candidats in definitions_dossier(dossier, cible, signaux).items():
                res.setdefault(cle, []).extend(candidats)
    return res


def _choisir_definition(candidats):
    """None si aucune définition ; (`inconnu`, None) si les définitions se contredisent (rôles différents) ;
    sinon la première (rôle, chemin)."""
    if not candidats:
        return None
    if len({role for role, _chemin in candidats}) > 1:
        return ("inconnu", None)
    return candidats[0]


def resoudre_agent(agent_type, racine, home, signaux=None):
    """(rôle, chemin de la définition) de l'agent, ou (`inconnu`, None). Ordre fin de P45-D-05b, le premier niveau
    qui trouve gagne : `.claude/agents/` du lab, puis `<home>/.claude/agents/` (le compte), puis — pour un
    `agent_type` de forme `<plugin>:<agent>` — les dossiers `agents/` de la version ACTIVE du plugin sous
    `<home>/.claude/plugins/`. `home` est l'argument passé par le lanceur (P45-D-12a) : ce code ne lit aucune variable
    d'environnement. Indexation par `name:` (repli : nom de fichier), comparaison normalisée, bornée à l'agent appelant ; deux
    définitions de rôles différents au même niveau : inconnu."""
    cible = normaliser(agent_type)
    avec_home = isinstance(home, str) and home.startswith("/")
    dossier_lab = os.path.join(racine, ".claude", "agents")
    dossier_compte = os.path.join(home, ".claude", "agents") if avec_home else None  # role-home
    niveaux = [dossier_lab, dossier_compte]  # role-niveaux
    for dossier in niveaux:
        if dossier is None:
            continue
        trouve = _choisir_definition(definitions_dossier(dossier, cible, signaux).get(cible))
        if trouve is not None:
            return trouve
    plugin, separateur, agent = agent_type.partition(":")
    if avec_home and separateur and plugin and agent:
        cible_plugin = normaliser(agent)
        trouve = _choisir_definition(definitions_plugin(home, normaliser(plugin), cible_plugin, signaux).get(cible_plugin))
        if trouve is not None:
            return trouve
    return ("inconnu", None)


def allowlist_de_definition(chemin):
    """Noms de l'allowlist `Agent(...)` / `Task(...)` de la définition à `chemin` (liste vide si illisible ou hors des bornes de lecture)."""
    texte = lire_definition_bornee(chemin)
    return [] if texte is None else allowlist_agent(lignes_frontmatter_agent(texte))


RAISON_JUGE = ("%s est un juge — toute écriture par outil lui est refusée ; posez un verdict par poser-verdict.sh "
               "(spec fabrique §5)")
RAISON_WORKER = ("%s est un worker — dispatch de %s refusé : absent de son allowlist Agent(...) / Task(...) "
                 "(F9 = f9-allowlist, Willy, AskUserQuestion session principale, 2026-09-30)")


def evaluer_role(contexte):
    """Lignes juge et worker du hook par rôle (GATE-09). Un fil principal (agent_id absent), un agent_type inconnu,
    ambigu, illisible ou de plugin non résolu ne reçoit JAMAIS de verdict de rôle : seulement la ligne « Tous » et
    G1, G5, G6, G7 (P45-D-11, limite déclarée). Juge : toute écriture par Write, Edit ou NotebookEdit est un verdict
    (le verdict se pose par poser-verdict.sh). Worker : un dispatch (tool_name Agent ou Task, P45-D-09) dont le
    subagent_type normalisé n'est égal à aucun nom de la PROPRE allowlist du worker APPELANT — l'agent_type du
    payload, résolu en définition — est un verdict ; allowlist vide : tout dispatch refusé (F9 = f9-allowlist,
    Willy, AskUserQuestion session principale, 2026-09-30 : contre la lettre de GATE-09 et de la table §5 de la spec
    fabrique, « Worker : tout dispatch refusé » ; limite déclarée : l'allowlist vit dans une définition d'agent que
    G6 ne protège pas). La ligne producteur est couverte par G5 (P45-D-07), aucune règle en double. Manager : aucune."""
    racine = contexte["racine"]  # role-sonde
    outil = contexte["outil"]
    if outil not in OUTILS_ECRITURE and outil not in OUTILS_DISPATCH:
        return []
    payload = contexte["payload"]
    agent_id, agent_type = payload.get("agent_id"), payload.get("agent_type")
    avec_identite = isinstance(agent_id, str) and agent_id != "" and isinstance(agent_type, str) and agent_type != ""
    signaux = []
    role, definition = resoudre_agent(agent_type, racine, contexte.get("arg_home"), signaux) if avec_identite else ("inconnu", None)  # role-principal
    for signal in signaux:  # role-signal : un budget d'indexation épuisé ne se tait jamais (lot C, N1)
        observer(Verdict("ROLE", None, signal), contexte)
    if role == "juge" and outil in OUTILS_ECRITURE:
        chemin_rel = None
        if contexte["ecrit"]:
            rel = os.path.relpath(os.path.realpath(contexte["ecrit"]), racine)
            chemin_rel = "/".join(c for c in rel.split(os.sep) if c not in ("", "."))
        return [Verdict("ROLE", chemin_rel, RAISON_JUGE % agent_type)]
    if role == "worker" and outil in OUTILS_DISPATCH:  # role-worker
        entree = payload.get("tool_input")
        sous = entree.get("subagent_type") if isinstance(entree, dict) else None
        autorises = [normaliser(nom) for nom in allowlist_de_definition(definition)]
        if isinstance(sous, str) and normaliser(sous) in autorises:  # role-allowlist
            return []
        montre = sous if isinstance(sous, str) else "-"
        return [Verdict("ROLE", "dispatch/" + montre, RAISON_WORKER % (agent_type, montre))]
    return []


# --- G4′ : pas de rapport de sous-agent sans sortie de commande brute (CLOT-06, 46-06 ; P46-D-02, P46-D-02a, P46-D-02b, P46-D-10) ---------
# Le rapport d'un sous-agent de rôle worker ou producteur d'un lab adhérent, qui a Bash, est jugé là où il est rendu : `tool_input.message` au
# PreToolUse de SubagentHandback, `last_assistant_message` au repli SubagentStop hors mode auto. Il doit porter au moins un bloc de code délimité
# dont la première ligne non vide est une commande (`$ <commande>`) suivie d'au moins une ligne de sortie. Le gate « bloque le silence, pas la
# falsification » (spec §5) : une sortie inventée passe (limite (au)). Juges, managers, fil principal (agent_id ou agent_type absent ou vide),
# agent inconnu, ambigu ou illisible, et agent sans Bash sont hors périmètre : sans Bash le refus ne pourrait pas être levé (P46-D-02b, Willy,
# AskUserQuestion session principale, 2026-10-03, Q9 = a) ; un agent sans champ `tools:` hérite des outils de la session, Bash compris, et reste dans
# le périmètre (limite (av)).
RAISON_G4P = ("rapport de %s sans sortie de commande brute — rejouez la commande qui prouve le travail et collez-la avec sa sortie dans un bloc "
              "(première ligne « $ <commande> », puis la sortie) ; dérogation nominative : deroger-gate.sh --gate=G4P --chemin=agents/%s")
OUTIL_HANDBACK = "SubagentHandback"


def _delimiteur_ouvrant(texte):
    """(caractère, longueur) de l'ouverture d'un bloc délimité si `texte` (blancs de tête déjà retirés) commence par trois ``` ou ~~~ ou plus (une
    étiquette de langage est admise après ; pour ```, elle ne porte pas d'accent grave) ; None sinon. Parcours linéaire, aucune expression."""
    if texte[:3] not in ("```", "~~~"):
        return None
    car = texte[0]
    longueur = len(texte) - len(texte.lstrip(car))
    if car == "`" and "`" in texte[longueur:]:
        return None
    return car, longueur


def sortie_brute_presente(message):
    """Vrai si `message` (une chaîne : tout autre type n'est aucune preuve) contient au moins un bloc de code délimité par une ligne de trois ``` ou
    ~~~ (ou plus) et FERMÉ par une ligne du même caractère au moins aussi longue, dont la première ligne non vide commence par `$ ` suivi d'un
    caractère non blanc et dont la ligne non vide suivante, dans le bloc, n'est ni une fermeture ni une ligne `$ ` (P46-D-02a). Un bloc non fermé
    ne compte pas. Parcours linéaire ligne à ligne, aucune expression à retour arrière. États : 0 hors bloc, 1 bloc ouvert (commande attendue),
    2 commande vue (sortie attendue), 3 bloc conforme, 4 bloc non conforme (ignoré jusqu'à sa fermeture)."""
    if not isinstance(message, str):
        return False
    etape, car, longueur = 0, "", 0
    for ligne in message.split("\n"):
        texte = ligne.strip()
        if etape == 0:
            ouvert = _delimiteur_ouvrant(ligne.lstrip())  # g4p-ouverture
            if ouvert is not None:
                car, longueur = ouvert
                etape = 1
            continue
        if texte != "" and not texte.strip(car) and len(texte) >= longueur:
            if etape == 3:
                return True
            etape = 0
            continue
        if texte == "":
            continue
        if etape == 1:
            etape = 2 if texte.startswith("$ ") and texte[2:3].strip() != "" else 4  # g4p-commande
        elif etape == 2:
            etape = 3 if not texte.startswith("$ ") else 4  # g4p-sortie
    return False  # g4p-fermeture


def agent_a_bash(texte):
    """Capacité Bash d'une définition d'agent (P46-D-02b) : True si `tools:` est absent (l'agent hérite des outils de la session, Bash compris) ou
    nomme `Bash` ou une forme `Bash(…)`, et que `disallowedTools` ne nomme pas `Bash` ; False sinon ; None si le frontmatter ou une allowlist est
    illisible (parenthèses déséquilibrées) : l'appelant exclut alors l'agent du périmètre."""
    lignes = lignes_frontmatter_agent(texte)
    if lignes is None:
        return None
    mode, brut = champ_brut_agent(lignes, "tools")
    if mode is not None:
        jetons, profondeur = jetons_agent(mode, brut)
        if profondeur != 0:
            return None
        if not any(jeton.strip().strip(chr(34)).strip(chr(39)).partition("(")[0].strip() == "Bash" for jeton in jetons):
            return False
    mode_interdit, brut_interdit = champ_brut_agent(lignes, "disallowedTools")
    if mode_interdit is not None:
        interdits, profondeur_interdit = jetons_agent(mode_interdit, brut_interdit)
        if profondeur_interdit != 0:
            return None
        if any(jeton.strip().strip(chr(34)).strip(chr(39)) == "Bash" for jeton in interdits):
            return False
    return True


def evaluer_g4p(contexte):
    """G4′ : voir l'en-tête de section. Verdict `G4P` sur le chemin `agents/<agent_type>` (dérogation nominative sur ce chemin). Deux entrées :
    outil `SubagentHandback` (PreToolUse, `tool_input.message`) et outil `SubagentStop` (repli, `last_assistant_message`, posé par
    `mode_subagent_stop`) ; tout autre outil : aucun verdict. Identité et rôle comme `evaluer_role` (même `resoudre_agent`)."""
    outil = contexte["outil"]
    payload = contexte["payload"]
    if outil == OUTIL_HANDBACK:
        entree = payload.get("tool_input")
        message = entree.get("message") if isinstance(entree, dict) else None
    elif outil == EVT_SUBAGENT_STOP:
        message = payload.get("last_assistant_message")
    else:
        return []
    agent_id, agent_type = payload.get("agent_id"), payload.get("agent_type")
    if not (isinstance(agent_id, str) and agent_id != "" and isinstance(agent_type, str) and agent_type != ""):
        return []
    signaux = []
    role, definition = resoudre_agent(agent_type, contexte["racine"], contexte.get("arg_home"), signaux)
    for signal in signaux:
        observer(Verdict("G4P", None, signal), contexte)
    if role not in ("worker", "producteur") or definition is None:  # g4p-perimetre
        return []
    texte = lire_definition_bornee(definition)
    a_bash = None if texte is None else agent_a_bash(texte)
    if not a_bash:  # g4p-capacite
        return []
    if sortie_brute_presente(message):
        return []
    return [Verdict("G4P", "agents/" + agent_type, RAISON_G4P % (agent_type, agent_type))]  # g4p-verdict


def classer_fichier(chemin):
    """Mode de diagnostic `--classer` : UNE ligne JSON {"role", "allowlist", "disallowed"} pour la définition à
    `chemin` (rôle `illisible` si elle ne se lit pas). Aucune décision, aucune lecture du payload."""
    role, liste, interdits = "illisible", [], []
    texte = lire_definition_bornee(chemin)
    if texte is not None:
        role = deriver_role(texte)
        lignes = lignes_frontmatter_agent(texte)
        if lignes is not None:
            liste = allowlist_agent(lignes)
            interdits = sorted(jetons_nus_agent(lignes, "disallowedTools"))
    sys.stdout.write(json.dumps({"role": role, "allowlist": liste, "disallowed": interdits}, ensure_ascii=False) + "\n")


# Gates qui refusent (armed) ou observent : (nom, fonction). Une erreur interne d'un gate est un
# Verdict d'erreur : deny si le gate est armed, ligne d'observation sinon (P45-D-08, spec §5.1).
GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G1", evaluer_g1), ("G7", evaluer_g7), ("ROLE", evaluer_role), ("G3", evaluer_g3), ("G4", evaluer_g4), ("G4P", evaluer_g4p))  # gates-a-verdict


def evaluer_protege(gate, fonction, contexte):
    try:
        return list(fonction(contexte))
    except Exception as exc:
        return [Verdict(gate, None, "erreur interne du gate : " + type(exc).__name__)]  # protege-erreur


# --- Évaluation des gates (Phase B) ----------------------------------------------------------
def evaluer_gates(contexte):
    """Liste de résultats (genre, texte), genre `refuse` ou `avertit`. La table d'armement est
    vérifiée d'abord : un code livré qui viole l'ordre des étapes refuse (impossible sur un code
    sain, c'est la garde que les mutants exercent). G2 avertit ; les gates à verdict passent par
    l'entonnoir `decider`."""
    if not armement_valide(TABLE_ARMEMENT):
        return [("refuse", "[planning-core] table d'armement incohérente : l'ordre des étapes "
                           "(G6 et G5, puis G1, puis G7, puis le rôle, puis G3 et G4, puis G4′) n'est pas respecté (P45-D-03, P46-D-11)")]
    resultats = []
    resultats.extend(evaluer_g2(contexte))
    verdicts = []
    for gate, fonction in GATES_A_VERDICT:
        verdicts.extend(evaluer_protege(gate, fonction, contexte))
    refus, citations = decider(verdicts, contexte)
    resultats.extend(("refuse", texte) for texte in refus)
    resultats.extend(("avertit", texte) for texte in citations)
    return resultats


# --- D1 : écritures surveillées (Phase 46, 46-07 ; P46-D-07, P46-D-07a, P46-D-10) ---------------------------------------------------------
# Toute écriture sur un fichier surveillé d'un lab adhérent est EXPLIQUÉE par le moteur ou TRACÉE comme contournement : en séance par
# FileChanged, entre les séances par une réconciliation par hash au SessionStart. D1 DÉTECTE, ne refuse JAMAIS (fail-open déclaré : toute
# erreur sort en silence, code 0) et ne coûte rien hors adhésion (aucune liste n'est renvoyée, le watcher ne démarre pas). Fichiers surveillés,
# un par un (jamais un dossier, #91634) : cinq à la racine du dossier de planning, quatre par unité de forme modèle dont SUMMARY.md est absent
# (approximation déterministe d'« unité non close », sans recalcul). Le journal de D1 n'en fait jamais partie. Limites : (ax) à (ba) de la
# référence.
BORNE_WATCHPATHS = 128
BORNE_LECTURE_SURVEILLANCE = 4194304
PAR_HOOK = "planning-hook.sh"
FICHIERS_RACINE_SURVEILLES = ("STATE.md", "INDEX.md", "cloture.log", NOM_JOURNAL_DEROGATIONS, NOM_CONFIG)
FICHIERS_UNITE_SURVEILLES = ("PLAN.md", "CLOTURE.md", "VERDICT.md", "SUMMARY.md")
LIGNE_SURVEILLANCE_RE = re.compile(r"^(\S+)  genre=(\S+)  chemin=(\S+)  sha256=(\S+)  par=(\S+)  source=(\S+)$")


def _unites_non_closes(racine):
    """Dossiers des unités de forme modèle dont SUMMARY.md est absent, en parcours trié : pour chaque phase de chaque cycle, le dossier de la
    phase puis ceux de ses plans (comme `plans_ouverts`, sans lire ni PLAN.md ni CLOTURE.md : aucune dérivation d'état). Un générateur : le
    consommateur s'arrête dès que la borne est atteinte."""
    base = os.path.join(racine, NOM_PLANNING, "cycles")
    for cycle in _sous_dossiers(base):
        phases = os.path.join(base, cycle, "phases")
        for phase in _sous_dossiers(phases):
            dossier_phase = os.path.join(phases, phase)
            dossiers = [dossier_phase] + [os.path.join(dossier_phase, "plans", plan) for plan in _sous_dossiers(os.path.join(dossier_phase, "plans"))]
            for dossier in dossiers:
                if not os.path.lexists(os.path.join(dossier, "SUMMARY.md")):
                    yield dossier


def chemins_surveilles(racine):
    """(liste de chemins ABSOLUS, tronquée) : les cinq fichiers racine du dossier de planning puis, par unité non close, ses quatre fichiers
    (SUMMARY.md encore absent compris), FICHIER PAR FICHIER — jamais un dossier, un watcher récursif sur un dossier géant bloquant le fil
    principal (#91634). Au plus BORNE_WATCHPATHS chemins ; la troncature est signalée à l'appelant, qui la trace. Ni le journal de D1 ni le
    cache du recalcul n'en font partie."""
    planning = os.path.join(racine, NOM_PLANNING)
    liste = [os.path.join(planning, nom) for nom in FICHIERS_RACINE_SURVEILLES]
    for dossier in _unites_non_closes(racine):
        for nom in FICHIERS_UNITE_SURVEILLES:
            liste.append(os.path.join(dossier, nom))  # d1-fichier-par-fichier
        if len(liste) > BORNE_WATCHPATHS:
            break
    if len(liste) > BORNE_WATCHPATHS:  # d1-borne
        return liste[:BORNE_WATCHPATHS], True
    return liste, False


def chemin_relatif_surveille(racine, chemin):
    """Chemin relatif au lab (séparateur `/`) si `chemin` a la FORME d'un fichier surveillé — un des cinq fichiers racine du dossier de
    planning, ou un des quatre fichiers d'une unité de forme modèle, SUMMARY.md compris (sa création est précisément ce qu'un contournement
    ferait) —, sinon None : un fichier hors du dossier de planning, un livrable, le journal de D1 ne sont jamais surveillés. Le dossier parent
    est résolu physiquement (l'alias d'un dossier ne change pas le lab) ; le fichier lui-même n'est jamais suivi."""
    try:
        parent, nom = os.path.split(chemin)
        composants = os.path.relpath(os.path.join(os.path.realpath(parent), nom), racine).split(os.sep)
    except (OSError, ValueError):
        return None
    reste = composants[1:]
    if composants[0] != NOM_PLANNING:
        return None
    if len(reste) == 1:
        conforme = reste[0] in FICHIERS_RACINE_SURVEILLES
    elif len(reste) in (5, 7):
        conforme = (reste[0] == "cycles" and reste[2] == "phases" and NOM_UNITE.match(reste[1]) is not None and NOM_UNITE.match(reste[3]) is not None
                    and reste[-1] in FICHIERS_UNITE_SURVEILLES
                    and (len(reste) == 5 or (reste[4] == "plans" and NOM_UNITE.match(reste[5]) is not None)))
    else:
        conforme = False
    return "/".join(composants) if conforme else None


def empreinte_fichier(chemin):
    """sha256 hexadécimal du fichier régulier `chemin`, lu sans suivre de lien ; `absent` s'il n'existe pas ou n'est pas un fichier régulier (un
    lien, un dossier, un tube comptent comme absents) ; None si la lecture échoue ou si le fichier dépasse BORNE_OCTETS_LIVRABLES (aucune ligne :
    D1 est fail-open)."""
    import hashlib
    try:
        etat = os.lstat(chemin)
    except (FileNotFoundError, NotADirectoryError):
        return "absent"
    except OSError:
        return None
    if not stat.S_ISREG(etat.st_mode):
        return "absent"
    if etat.st_size > BORNE_OCTETS_LIVRABLES:
        return None
    try:
        hacheur = hashlib.sha256()
        with os.fdopen(os.open(chemin, DRAPEAUX_LIVRABLE), "rb") as fh:
            while True:
                bloc = fh.read(1048576)
                if not bloc:
                    break
                hacheur.update(bloc)
    except OSError:
        return None
    return hacheur.hexdigest()


def lire_surveillance(racine):
    """Entrées du journal de D1, dans l'ordre : dict(genre, chemin, sha, par, source), `chemin` décodé. Lecture bornée aux
    BORNE_LECTURE_SURVEILLANCE octets de FIN (la ligne que la fenêtre coupe est écartée : une référence plus ancienne est inconnue, la première
    observation la repose, limite (ba)). [] si le journal est absent, n'est pas un fichier régulier (un lien n'est jamais suivi) ou ne se lit
    pas ; une ligne mal formée est ignorée."""
    chemin = os.path.join(racine, NOM_PLANNING, NOM_SURVEILLANCE)
    try:
        if not est_fichier_regulier(chemin):
            return []
        with os.fdopen(os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN | SANS_BLOCAGE), "rb") as fh:
            debut = max(0, os.fstat(fh.fileno()).st_size - BORNE_LECTURE_SURVEILLANCE)  # d1-fenetre
            fh.seek(debut)
            octets = fh.read(BORNE_LECTURE_SURVEILLANCE)
    except OSError:
        return []
    if debut > 0:
        coupe = octets.find(b"\n")
        octets = octets[coupe + 1:] if coupe >= 0 else b""
    entrees = []
    for ligne in octets.decode("utf-8", "replace").split("\n"):
        m = LIGNE_SURVEILLANCE_RE.match(ligne)
        if m:
            entrees.append({"genre": m.group(2), "chemin": urllib.parse.unquote(m.group(3), errors="replace"), "sha": m.group(4),
                            "par": m.group(5), "source": m.group(6)})
    return entrees


def entrees_par_chemin(entrees):
    """Les entrées du journal groupées par chemin, chaque groupe dans l'ordre du journal : une seule passe sur le journal, quel que soit le nombre de
    chemins de la liste (le coût d'une réconciliation ne dépend pas du nombre de chemins surveillés multiplié par la taille du journal)."""
    groupes = {}
    for entree in entrees:
        groupes.setdefault(entree["chemin"], []).append(entree)
    return groupes


def decider_trace(entrees, sha):
    """Lignes que le fichier dont `entrees` sont les lignes du journal (dans l'ordre), de sha256 courant `sha` (`absent` s'il n'existe pas),
    appelle au journal. Règle d'explication, déterministe : sans référence antérieure, la première observation pose la référence sans
    contournement (limite (ba)) ; un sha égal à celui de la dernière référence n'est pas un changement (rien à inscrire : un événement répété ne se
    compte pas deux fois) ; un changement est EXPLIQUÉ s'il existe, APRÈS la dernière référence du chemin, une ligne `moteur` de sha `sha` (une
    écriture du moteur, journalisée par son écrivain) ou une ligne `intention` (une écriture par outil que le hook a laissée passer) — une intention
    n'explique qu'UN changement, puisque la référence qui suit la dépasse. Expliqué : `reference` seule ; sinon `contournement` puis `reference`."""
    derniere = None
    for rang, entree in enumerate(entrees):
        if entree["genre"] == "reference":
            derniere = rang
    if derniere is None:
        return ["reference"]
    if entrees[derniere]["sha"] == sha:
        return []
    apres = entrees[derniere + 1:]  # d1-apres
    expliquee = any((e["genre"] == "moteur" and e["sha"] == sha) or e["genre"] == "intention" for e in apres)  # d1-explique
    return ["reference"] if expliquee else ["contournement", "reference"]  # d1-contournement


def tracer_changement(racine, rel, sha, entrees, source):
    """Inscrit les lignes que `decider_trace` demande pour le fichier `rel` (`entrees` : ses lignes du journal) et rend les genres inscrits ; un
    contournement n'a pas d'auteur (`par` vide : aucun auteur dans le payload, limite (ay))."""
    genres = decider_trace(entrees, sha)
    for genre in genres:
        inscrire_surveillance(racine, genre, rel, sha, None if genre == "contournement" else PAR_HOOK, source)
    return genres


def inscrire_ecriture_moteur(racine, chemin_rel, par):
    """Après une écriture du MOTEUR sur `chemin_rel` (relatif au lab, séparateur `/`), inscrit la ligne `moteur` avec le sha256 du fichier APRÈS
    écriture : c'est elle qui explique le FileChanged qui suit. Aucune ligne si le fichier ne se lit pas ; jamais une exception : l'inscription ne
    change JAMAIS le résultat de l'écrivain (D1 est fail-open)."""
    try:
        empreinte = empreinte_fichier(os.path.join(racine, *chemin_rel.split("/")))
        if empreinte is not None:
            inscrire_surveillance(racine, "moteur", chemin_rel, empreinte, par, None)
    except Exception:
        return


def inscrire_intentions(payload, cibles):
    """Écriture par Write, Edit ou NotebookEdit que la décision FINALE du PreToolUse laisse passer sur un fichier surveillé d'un lab adhérent : une
    ligne `intention` (outil, chemin, sans sha256 — le contenu n'est pas encore écrit). Elle explique le changement que le FileChanged verra, un seul
    (limite (ay)). Jamais une exception ni un refus : un échec ne change pas la décision du hook."""
    try:
        outil = payload.get("tool_name")
        if outil not in OUTILS_ECRITURE:
            return
        for forme, racine_cible in cibles:
            rel = chemin_relatif_surveille(racine_cible, forme) if forme else None
            if rel is not None:
                inscrire_surveillance(racine_cible, "intention", rel, None, outil, None)
    except Exception:
        return


def reconcilier(racine, liste, tronquee):
    """Réconciliation par hash au SessionStart (P46-D-07) : les empreintes des fichiers surveillés sont comparées au dernier état connu du journal (une
    lecture bornée du journal, une lecture de chaque fichier de la liste). Une première observation pose la référence ; un changement que rien n'explique
    est tracé comme contournement (`source=reconciliation`) ; une troncature à la borne est tracée. Rend le signal à porter au contexte — les
    contournements tracés depuis la séance précédente, c'est-à-dire depuis la dernière ligne `signal` — ou None ; la ligne `signal` est posée, de sorte
    qu'un SessionStart sans nouveau contournement ne le répète pas."""
    entrees = lire_surveillance(racine)
    par_chemin = entrees_par_chemin(entrees)
    contournements = []
    for entree in entrees:
        if entree["genre"] == "signal":
            contournements = []
        elif entree["genre"] == "contournement":
            contournements.append(entree["chemin"])
    for chemin in liste:
        rel = os.path.relpath(chemin, racine).replace(os.sep, "/")
        sha = empreinte_fichier(chemin)
        if sha is None:
            continue
        genres = tracer_changement(racine, rel, sha, par_chemin.get(rel, []), "reconciliation")  # d1-reconciliation
        if "contournement" in genres:
            contournements.append(rel)
    if tronquee:
        inscrire_surveillance(racine, "borne", None, None, PAR_HOOK, "reconciliation")  # d1-troncature
    if not contournements:
        return None
    distincts = []
    for chemin in contournements:
        if chemin not in distincts:
            distincts.append(chemin)
    inscrire_surveillance(racine, "signal", None, None, PAR_HOOK, "reconciliation")  # d1-signal
    return ("[planning-core] D1 : %d écriture(s) non expliquée(s) de fichiers surveillés depuis la séance précédente (%s%s) — tracées dans .planning/surveillance.log"
            % (len(contournements), ", ".join(distincts[:3]), "…" if len(distincts) > 3 else ""))


def sortie_surveillance(evenement, liste, texte):
    """Objet de sortie de SessionStart (`hookSpecificOutput` : `watchPaths` et `additionalContext`, chaque clé présente seulement si non vide) ou de
    CwdChanged (`watchPaths` au PREMIER niveau ET sous `hookSpecificOutput` : la forme n'est pas mesurée, P46-D-08, les deux sont émises) ; None si rien à
    dire. Jamais une décision (`deny`, `block`) : D1 ne refuse jamais."""
    if evenement == EVT_CWD_CHANGED:
        return {"watchPaths": list(liste), "hookSpecificOutput": {"hookEventName": EVT_CWD_CHANGED, "watchPaths": list(liste)}} if liste else None
    corps = {"hookEventName": evenement}
    if liste:
        corps["watchPaths"] = list(liste)
    if texte:
        corps["additionalContext"] = _message_sur(texte)
    return {"hookSpecificOutput": corps} if len(corps) > 1 else None


def sortie_d1(objet):
    """Émet l'objet de sortie de SessionStart ou de CwdChanged (rien si vide). Un objet qui porterait une décision n'est jamais émis."""
    if not isinstance(objet, dict) or not objet:
        return
    corps = objet.get("hookSpecificOutput")
    if "decision" in objet or (isinstance(corps, dict) and ("permissionDecision" in corps or "decision" in corps)):  # d1-sans-refus
        return
    _emettre(objet)


# --- Canary de juge (Phase 46, 46-09 ; CLOT-08 ; P46-D-06, P46-D-06a, P46-D-13, P46-D-16) ---------------------------------------------------------
# Un juge qui laisse tout passer est le mode d'échec le plus coûteux d'un système multi-agents (spec d'initialisation §10, C-16). La 46 livre le
# CONTRAT et le VÉRIFICATEUR, jamais le dispatch (Phase 48) ni la fabrication des sorties piégées (Phase 50). Chaque juge du lab — les définitions de
# `.claude/agents/` du lab dont le rôle dérivé est `juge`, jamais celles du compte ni d'un plugin — a un dossier `.planning/juges/<juge>` : la sortie
# piégée `SORTIE-PIEGEE.md` (frontmatter `juge`, `critere_vise`, `provenance` ; corps : l'exemple raté qui viole le critère visé) et le verdict de canary
# `VERDICT.md`, posé par poser-verdict.sh (forme de juge de 46-01 : `hash` = sha256 des octets de la sortie piégée, pas de `hash_livrables`) et protégé par
# G5 comme tout verdict. Trois classes, déterministes : PROUVÉ (verdict valide, `hash` égal au sha256 de la sortie piégée, le critère visé porté en `échec`
# et seulement en `échec`), LAXISTE (verdict valide et à jour dont le critère visé n'est pas en `échec` : absent des constats, ou porté en `passé` ne
# serait-ce qu'une fois), SANS PREUVE (tout le reste : nom hors forme, pas de dossier, pas de sortie piégée ou sans `critere_vise`, pas de verdict, verdict invalide ou
# périmé, toute erreur de lecture) — « juge sans preuve » n'est JAMAIS vert. Aucun seuil de juge n'est lu (P46-D-13) ; config.json n'est lu que pour l'adhésion.
NOM_SORTIE_PIEGEE = "SORTIE-PIEGEE.md"
NOM_VERDICT_JUGE = "VERDICT.md"
NOM_DOSSIER_JUGES = "juges"
JUGE_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}\Z")  # même forme de nom que poser-verdict.sh
BORNE_SORTIE_PIEGEE = 1048576
BORNE_NOMS_SIGNAL = 3


def _dossier_reel(chemin):
    """Vrai si `chemin` est un dossier réel (lstat : un lien vers un dossier n'en est pas un)."""
    try:
        return stat.S_ISDIR(os.lstat(chemin).st_mode)
    except OSError:
        return False


def _verifier_un_juge(racine, juge):
    """(classe, motif) du juge `juge` (nom normalisé) : classe `prouve`, `laxiste` ou `sans-preuve` ; motif en kebab-case pour `sans-preuve`, None sinon.
    Ordre : dossier, sortie piégée (octets, `critere_vise`), verdict (règle R6 des constats, comme G4), `hash`, critère visé. Lève sur une erreur
    imprévue : l'appelant range le juge sans preuve (jamais vert)."""
    import hashlib
    if JUGE_RE.match(juge) is None:
        return "sans-preuve", "nom-hors-forme"
    dossier = os.path.join(racine, NOM_PLANNING, NOM_DOSSIER_JUGES, juge)
    if not (_dossier_reel(os.path.join(racine, NOM_PLANNING, NOM_DOSSIER_JUGES)) and _dossier_reel(dossier)):
        return "sans-preuve", "dossier-absent"  # juge-sans-preuve
    sortie = os.path.join(dossier, NOM_SORTIE_PIEGEE)
    try:
        etat = os.lstat(sortie)
    except FileNotFoundError:
        return "sans-preuve", "sortie-piegee-absente"
    if not stat.S_ISREG(etat.st_mode):
        return "sans-preuve", "sortie-piegee-invalide"
    if etat.st_size > BORNE_SORTIE_PIEGEE:
        return "sans-preuve", "sortie-piegee-hors-borne"
    with os.fdopen(os.open(sortie, DRAPEAUX_LIVRABLE), "rb") as fh:
        octets = fh.read(BORNE_SORTIE_PIEGEE + 1)
    if len(octets) > BORNE_SORTIE_PIEGEE:
        return "sans-preuve", "sortie-piegee-hors-borne"
    try:
        texte = octets.decode("utf-8")
    except UnicodeDecodeError:
        return "sans-preuve", "sortie-piegee-illisible"
    statut_s, donnees_s = lire_frontmatter(texte)
    critere = donnees_s.get("critere_vise") if statut_s == "ok" else None
    if not isinstance(critere, str) or critere.strip() == "":
        return "sans-preuve", "critere-vise-absent"
    statut_v, donnees_v = lire_frontmatter_fichier(os.path.join(dossier, NOM_VERDICT_JUGE))
    if statut_v == "absent":
        return "sans-preuve", "verdict-absent"
    constats = donnees_v.get("constats") if statut_v == "ok" else None
    if not isinstance(constats, list) or len(constats) == 0 or any(
            not isinstance(c, dict) or c.get("resultat") not in ("passé", "échec") for c in constats):
        return "sans-preuve", "verdict-invalide"
    if donnees_v.get("hash") != hashlib.sha256(octets).hexdigest():  # juge-hash
        return "sans-preuve", "verdict-perime"
    visees = [c.get("resultat") for c in constats if c.get("critere") == critere]
    if visees and all(resultat == "échec" for resultat in visees):  # juge-critere
        return "prouve", None
    return "laxiste", None


def verifier_juges(racine):
    """Vérificateur de juges du lab de racine `racine` : {"prouves": [noms], "laxistes": [noms], "sans_preuve": [{"juge": nom, "motif": motif}]}, noms
    triés. Les juges sont les définitions de `<racine>/.claude/agents/` dont le rôle dérivé est `juge` (`definitions_dossier`, `deriver_role`) ; une
    erreur sur un juge le range SANS PREUVE avec le motif `erreur-<type>`, jamais prouvé. Ne lit ni config.json ni aucun seuil (P46-D-13)."""
    prouves, laxistes, sans_preuve = [], [], []
    try:
        definitions = definitions_dossier(os.path.join(racine, ".claude", "agents"))
    except Exception:
        definitions = {}
    for nom in sorted(definitions):
        if not any(role == "juge" for role, _chemin in definitions[nom]):
            continue
        try:
            classe, motif = _verifier_un_juge(racine, nom)
        except Exception as exc:
            classe, motif = "sans-preuve", "erreur-" + type(exc).__name__
        if classe == "prouve":
            prouves.append(nom)
        elif classe == "laxiste":
            laxistes.append(nom)
        else:
            sans_preuve.append({"juge": nom, "motif": motif})
    return {"prouves": prouves, "laxistes": laxistes, "sans_preuve": sans_preuve}


def _noms_du_signal(noms):
    """Au plus BORNE_NOMS_SIGNAL noms, suivis du reste compté."""
    texte = ", ".join(noms[:BORNE_NOMS_SIGNAL])
    return texte + (" et %d autre(s)" % (len(noms) - BORNE_NOMS_SIGNAL) if len(noms) > BORNE_NOMS_SIGNAL else "")


def signal_juges(classes):
    """UNE ligne agrégée pour le contexte du SessionStart, ou None quand le lab n'a aucun juge : les prouvés comptés, les laxistes et les premiers sans
    preuve nommés (au plus BORNE_NOMS_SIGNAL, le reste compté) ; la marche à suivre n'est ajoutée que s'il reste un juge à prouver."""
    prouves, laxistes = classes["prouves"], classes["laxistes"]
    sans = [entree["juge"] for entree in classes["sans_preuve"]]
    if not (prouves or laxistes or sans):
        return None
    texte = "[planning-core] juges (C-16) : %d prouvé(s) ; %d laxiste(s)%s ; %d sans preuve%s" % (
        len(prouves), len(laxistes), " : " + _noms_du_signal(laxistes) if laxistes else "",
        len(sans), " : " + _noms_du_signal(sans) if sans else "")
    if laxistes or sans:
        texte += (" — faire passer chaque juge sur .planning/juges/<juge>/SORTIE-PIEGEE.md et poser son verdict par "
                  "poser-verdict.sh --unite=.planning/juges/<juge>")
    return texte


def juges_diagnostic(racine):
    """Mode de diagnostic `--juges` : UNE ligne JSON des trois classes pour le lab de racine `racine`. Aucune décision, aucune lecture du payload."""
    sys.stdout.write(json.dumps(verifier_juges(racine), ensure_ascii=False) + "\n")


# --- Modes par événement (Phase 46, P46-D-09, P46-D-10) ----------------------------------------------------------------
# Chaque mode reçoit le contexte du lab adhérent. Seul SubagentStop REFUSE (il rend ses raisons de blocage à `main`, qui émet la décision
# `block`, code 0) ; SessionStart, CwdChanged et FileChanged ne refusent JAMAIS. Les modes de D1 (46-07) ne rendent rien : SessionStart et
# CwdChanged déposent leur objet de sortie dans `contexte["sortie_d1"]`, que `main` émet (`watchPaths` et `additionalContext`, jamais `deny` ni
# `block`) ; FileChanged ne sort rien. Une exception d'un mode D1 sort en silence, code 0.
def mode_subagent_stop(contexte):
    """Repli de G4′ hors mode auto (P46-D-02, P46-D-10) : le rapport est `last_assistant_message`, jugé par le MÊME prédicat que le PreToolUse de
    SubagentHandback (`evaluer_g4p`) et passé par le même entonnoir (observe journalise, armé refuse, dérogation nominative à usage unique).
    En mode auto, SubagentStop n'évalue RIEN : le rapport a déjà passé le PreToolUse de SubagentHandback, et un second jugement refuserait deux
    fois le même rapport. Le refus est rendu à `main`, qui émet `decision: block` en code 0, jamais le code 2."""
    if contexte["payload"].get("permission_mode") == "auto":  # g4p-auto
        return None
    suivi = dict(contexte, outil=EVT_SUBAGENT_STOP)
    refus, _citations = decider(evaluer_protege("G4P", evaluer_g4p, suivi), suivi)
    if refus:
        return refus
    return None  # evt-mode-subagentstop


def mode_session_start(contexte):
    """D1 au SessionStart (46-07) : la liste surveillée du lab adhérent, fichier par fichier (`watchPaths`), et la réconciliation par hash des fichiers
    de cette liste avec le dernier état connu (les changements que rien n'explique sont tracés ; le signal tient en une ligne de `additionalContext`).
    L'objet de sortie est déposé dans `contexte["sortie_d1"]`, que `main` émet. Ne bloque jamais. Canary de juge (46-09, P46-D-06) : à la source `startup`
    seulement, UNE ligne agrégée de plus dans le même `additionalContext` (les juges du lab, voir `signal_juges`) ; une erreur du vérificateur la tait,
    elle ne change ni la liste ni le signal de D1."""
    racine = contexte["racine"]
    liste, tronquee = chemins_surveilles(racine)  # d1-liste
    signal = reconcilier(racine, liste, tronquee)
    if contexte["payload"].get("source") == "startup":  # juge-source
        try:
            ligne_juges = signal_juges(verifier_juges(racine))
        except Exception:
            ligne_juges = None
        signal = "\n".join(texte for texte in (signal, ligne_juges) if texte) or None
    contexte["sortie_d1"] = sortie_surveillance(EVT_SESSION_START, liste, signal)
    return None  # evt-mode-sessionstart


def mode_cwd_changed(contexte):
    """Racine lue dans `cwd` (`new_cwd` non lu, limite (ao)) ; D1 renvoie la même liste surveillée, sous les deux formes de `watchPaths`
    (`sortie_surveillance`). Pas de réconciliation : elle est faite au SessionStart. La limite (ax) (#95440 : FileChanged sourd après un `cd`) est
    rattrapée par cette réconciliation."""
    liste, _tronquee = chemins_surveilles(contexte["racine"])  # d1-cwd-liste
    contexte["sortie_d1"] = sortie_surveillance(EVT_CWD_CHANGED, liste, None)
    return None  # evt-mode-cwdchanged


def mode_file_changed(contexte):
    """D1 en séance (46-07) : un fichier surveillé d'un lab adhérent a changé (`file_path` de premier niveau, `event` change, add ou unlink).
    Son sha256 courant (`absent` s'il a disparu) est comparé à la dernière référence du journal ; un changement que rien n'explique est tracé comme
    contournement, puis la référence est mise à jour. Un fichier qui n'est pas surveillé : rien. Ne refuse jamais et ne renvoie JAMAIS de
    `watchPaths` (P46-D-07)."""
    racine, chemin = contexte["racine"], contexte["ecrit"]
    rel = chemin_relatif_surveille(racine, chemin)
    if rel is not None:
        sha = empreinte_fichier(chemin)
        if sha is not None:
            tracer_changement(racine, rel, sha, entrees_par_chemin(lire_surveillance(racine)).get(rel, []), "seance")  # d1-trace
    return None  # evt-mode-filechanged


MODES_EVENEMENT = {
    EVT_SUBAGENT_STOP: mode_subagent_stop,
    EVT_SESSION_START: mode_session_start,
    EVT_CWD_CHANGED: mode_cwd_changed,
    EVT_FILE_CHANGED: mode_file_changed,
}


def erreur_subagent_stop(exc, racine):
    """Erreur interne en phase B de SubagentStop (P46-D-10) : fail-closed pour G4′, par le même entonnoir que les autres gates — `decision: block`
    si ARMEMENT_G4P vaut `armed`, ligne d'observation sinon. Ne lève jamais, ne sort jamais par le code 2."""
    try:
        contexte = {"racine": racine, "outil": EVT_SUBAGENT_STOP,
                    "arg_xdg": sys.argv[2] if len(sys.argv) > 2 else "", "arg_home": sys.argv[3] if len(sys.argv) > 3 else ""}
        refus, _citations = decider([Verdict("G4P", None, "erreur interne du gate : " + type(exc).__name__)], contexte)
        if refus:
            sortie_blocage_subagent(refus)
    except BaseException:
        return


def evenement_de(payload):
    """Nom de l'événement du payload (`hook_event_name`). Clé absente : `PreToolUse` (les payloads d'avant la 46 ne la portaient pas
    toujours) ; valeur qui n'est pas une chaîne : chaîne vide, donc événement inconnu (silence, limite (aq))."""
    nom = payload.get("hook_event_name")
    if nom is None:  # evt-absent
        return EVT_PRETOOLUSE
    return nom if isinstance(nom, str) else ""


def depart_evenement(payload, evenement, cwd, ecrit):
    """Chemin d'où se dérive la racine du lab. FileChanged : le `file_path` de PREMIER NIVEAU (chaîne absolue sous la borne de longueur
    du cœur, sinon None : silence). Tout autre événement : le chemin écrit, sinon le cwd du payload, sinon le cwd du processus
    (logique d'avant la 46, inchangée)."""
    if evenement == EVT_FILE_CHANGED:  # evt-filechanged-depart
        chemin = payload.get("file_path")
        if isinstance(chemin, str) and chemin.startswith("/") and len(chemin) <= BORNE_VALEUR:  # evt-filechanged-chemin
            return chemin
        return None
    return ecrit if ecrit is not None else (cwd if cwd is not None else os.getcwd())


def main():
    armer_echeance()  # echeance-armee
    # Mode de diagnostic (45-08) : `--classer <agent.md>`, quatrième argument du cœur ; aucune décision.
    if len(sys.argv) > 4 and sys.argv[4] == "--classer":
        classer_fichier(sys.argv[1])
        sys.exit(0)
    # Mode de diagnostic du canary de juge (46-09) : `--juges <racine du lab>`, même patron ; aucune décision.
    if len(sys.argv) > 4 and sys.argv[4] == "--juges":
        juges_diagnostic(sys.argv[1])
        sys.exit(0)
    # Phase A : l'adhésion n'est pas encore connue. Toute erreur sort sur un code non nul SANS rien
    # imprimer : la couche shell de la commande enregistrée tranche (P45-D-08, DIV-2).
    try:
        payload = lire_payload(sys.argv[1])  # phase-a
    except BaseException:
        sys.exit(3)  # phase-a-sortie
    evenement = evenement_de(payload)  # evt-lecture
    if evenement not in EVENEMENTS_CONNUS:
        sys.exit(0)  # evt-inconnu : un événement que le hook ne connaît pas sort en silence (limite (aq))
    try:
        # N2-01 (re-audit 2 du 2026-10-02) : une valeur de plus de BORNE_VALEUR caractères ne passe JAMAIS par realpath ni racine_lab
        # (quadratiques en profondeur : l'échéance de 8 s tombait sur un chemin qui descend puis remonte et la couche shell, aveugle à
        # une forme échappée, se taisait). N3-01 (re-audit 3) : `cible_de` la lit sous deux formes en temps linéaire (réduite
        # lexicalement, physique) ; chacune qui tient sous la borne est analysée comme une valeur courte ; seule une valeur qui reste trop
        # longue lève ici et part dans la décision dans le doute sur son nom décodé. Un lab est adhérent dès que l'UNE des formes y tombe.
        ecrit, cwd, variantes = cible_de(payload, sys.argv[3] if len(sys.argv) > 3 else "")
        depart = depart_evenement(payload, evenement, cwd, ecrit)  # racine-depart evt-depart
        racine = racine_lab(depart)
        adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"]
        autres = []  # formes supplémentaires (N3-01) qui tombent, elles, dans un lab adhérent : (chemin écrit, racine du lab)
        for forme in variantes:
            racine_forme = racine_lab(forme)
            if racine_forme is not None and verifier_adhesion(os.path.join(racine_forme, ".planning"))["adherente"]:
                autres.append((forme, racine_forme))
    except BaseException as exc_doute:  # phase-a-doute
        if evenement != EVT_PRETOOLUSE:  # evt-doute-pretooluse : la décision dans le doute ne vaut que pour PreToolUse
            sys.exit(0)
        # N-01 : un chemin que l'analyse fait lever (surrogate, NUL, realpath) ne sort plus en code non nul — le payload aurait provoqué
        # lui-même la panne du cœur et fait taire les gates ; il est décidé dans le doute. Sans chemin écrit : code 3, comme avant.
        try:
            decide = decider_dans_le_doute(payload, getattr(exc_doute, "ancetres", ()))
        except BaseException:
            sys.exit(3)
        if decide is None:
            sys.exit(3)
        sys.exit(0)
    if not adherent and not autres:
        sys.exit(0)  # non-adherent
    # Phase B : le lab est adhérent. Toute erreur devient un refus explicite, code 0 (P45-D-08).
    try:
        if evenement == EVT_PRETOOLUSE:
            refus, avis = [], []
            cibles = ([(ecrit, racine)] if adherent else []) + autres
            for forme, racine_cible in (cibles or [(ecrit, racine)]):  # `or` : jamais vide sur un code sain, la sortie ci-dessus l'a écarté
                contexte = {"payload": payload, "outil": payload.get("tool_name"), "ecrit": forme,
                            "cwd": cwd, "racine": racine_cible,
                            "arg_xdg": sys.argv[2] if len(sys.argv) > 2 else "",
                            "arg_home": sys.argv[3] if len(sys.argv) > 3 else ""}
                resultats = evaluer_gates(contexte)  # phase-b
                refus.extend(texte for genre, texte in resultats if genre == "refuse" and texte not in refus)
                avis.extend(texte for genre, texte in resultats if genre == "avertit" and texte not in avis)
            if refus:
                sortie_refus(refus)
            else:
                inscrire_intentions(payload, cibles or [(ecrit, racine)])  # d1-intention : la décision finale est un passage, l'écriture par outil est tracée (D1)
                if avis:
                    sortie_contexte(avis)
        else:
            contexte = {"payload": payload, "evenement": evenement, "outil": None,
                        "ecrit": depart if evenement == EVT_FILE_CHANGED else None,
                        "cwd": cwd, "racine": racine,
                        "arg_xdg": sys.argv[2] if len(sys.argv) > 2 else "",
                        "arg_home": sys.argv[3] if len(sys.argv) > 3 else ""}
            raisons = MODES_EVENEMENT[evenement](contexte)  # evt-phase-b
            if raisons and evenement == EVT_SUBAGENT_STOP:  # seul SubagentStop REFUSE (`decision: block`) ; SessionStart, CwdChanged et FileChanged ne refusent jamais
                sortie_blocage_subagent(raisons)
            elif evenement in (EVT_SESSION_START, EVT_CWD_CHANGED):  # evt-sortie-d1 : D1 émet `watchPaths` (jamais deny ni block) ; FileChanged ne sort rien
                sortie_d1(contexte.get("sortie_d1"))
    except BaseException as exc:
        if evenement == EVT_PRETOOLUSE:  # evt-refus-pretooluse : fail-closed de PreToolUse (P45-D-08)
            sortie_refus(["[planning-core] erreur interne du hook central dans un lab adhérent "
                          "cycles-v1 : action refusée (P45-D-08) — " + type(exc).__name__])
        elif evenement == EVT_SUBAGENT_STOP:  # evt-erreur-subagentstop : fail-closed de G4′ (block si armé, observation sinon) ; SessionStart, CwdChanged, FileChanged : silence (fail-open déclaré)
            erreur_subagent_stop(exc, racine)
        else:  # SessionStart, CwdChanged, FileChanged : silence, jamais un refus (fail-open déclaré de D1, P46-D-10)
            pass  # evt-erreur-d1
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    finally:
        figer_echeance()  # echeance-figee-sortie
PY_PLANNING_HOOK_EOF
