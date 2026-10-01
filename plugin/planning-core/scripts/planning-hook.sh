#!/usr/bin/env bash
# planning-hook.sh — hook central PreToolUse de planning-core (Phase 45, P45-D-15 : UN SEUL script
# pour les gates d'écriture et le cloisonnement par rôle). Il n'agit que dans un lab adhérent
# `cycles-v1` (P45-D-01a) ; ailleurs — labs dev, ce dépôt compris — il ne sort RIEN et rend 0
# (P45-D-04). La racine du lab est dérivée du chemin écrit (à défaut du cwd du payload, à défaut du
# cwd physique du processus), jamais de $CLAUDE_PROJECT_DIR (P45-D-12).
#
# Entrée : le payload JSON du harnais sur stdin. Sortie : rien, ou UN objet JSON hookSpecificOutput
# (refus : permissionDecision deny ; avertissement : additionalContext), toujours code 0 — jamais
# exit 2 (P45-D-08, DIV-2).
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
# [3] valeur de HOME (idem), [4] `--classer` en mode diagnostic, vide sinon.
#
# Mode de diagnostic (45-08) : `planning-hook.sh --classer <agent.md>` imprime UNE ligne JSON
# {"role": …, "allowlist": […], "disallowed": […]} et rend 0, sans lire stdin ni rien décider. La commande
# enregistrée ne passe jamais d'argument : le chemin de décision est inchangé.
set -u

if [ "${1:-}" = "--classer" ]; then
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
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
# Lot A (H2 ; décisions du manager vf-dev-manager, 2026-10-01) : le cœur se borne lui-même. Passé l'échéance, ou si le lanceur
# meurt, il sort sur CODE_ECHEANCE sans rien imprimer : la couche shell de la commande enregistrée ferme alors sous adhésion
# (P45-D-06a) et reste silencieuse ailleurs. Le délai du harnais (20 s) ne tue que le shell, jamais le Python orphelin.
ECHEANCE_COEUR_S = 8.0
PAS_SURVEILLANCE_S = 0.5
CODE_ECHEANCE = 73

# --- Table d'armement (P45-D-03a) : l'état de chaque gate vit ICI, dans le code livré, jamais dans
# un fichier du lab ni dans une variable d'environnement (P45-D-01, P45-D-12a). Une constante par
# gate, une ligne chacune (l'outil de rejeu et les mutants réécrivent ces lignes sur une copie).
# Valeurs admises : `observe` (le gate calcule, journalise, laisse passer) | `armed` (le gate refuse).
ARMEMENT_G6 = "armed"  # etape-1
ARMEMENT_G5 = "armed"  # etape-1
ARMEMENT_G1 = "observe"  # etape-2
ARMEMENT_G7 = "observe"  # etape-3
ARMEMENT_ROLE = "observe"  # etape-4
G2_MODE = "avertit"
ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",))
TABLE_ARMEMENT = {"G6": ARMEMENT_G6, "G5": ARMEMENT_G5, "G1": ARMEMENT_G1, "G7": ARMEMENT_G7, "ROLE": ARMEMENT_ROLE}


# --- Échéance interne et surveillance du lanceur (lot A, H2) ------------------------------------------------------
def armer_echeance():
    """Arme la surveillance du cœur : toutes les PAS_SURVEILLANCE_S secondes, sortie immédiate sur CODE_ECHEANCE (aucune sortie)
    si ECHEANCE_COEUR_S est dépassée ou si le processus parent n'est plus le lanceur (il est mort : un Python orphelin ne survit
    pas à son kill). Minuterie du système (SIGALRM) : un gestionnaire de signal passe aussi pendant une expression régulière, là où
    un fil ne passerait pas (le GIL) ; sans SIGALRM (Windows), repli sur un fil démon."""
    debut = time.monotonic()
    parent = os.getppid()

    def surveiller(*_ignores):
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


def cible_de(payload):
    """(chemin écrit absolu ou None, cwd du payload ou None). Clé `file_path`, sinon
    `notebook_path`, dans `tool_input`. Un chemin relatif est JOINT au cwd du payload (à défaut au
    cwd physique du processus), comme la couche shell (limite h) : les deux couches rattachent
    le chemin au même lab."""
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
    if ecrit is not None and not ecrit.startswith("/"):
        base = cwd if cwd is not None else os.path.realpath(os.getcwd())
        ecrit = base + "/" + ecrit
    return (ecrit, cwd)


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
    même valeur (l'étape 1 est UN seul geste). L'ordre est celui de ORDRE_ETAPES."""
    gates = [gate for etape in ORDRE_ETAPES for gate in etape]  # armement-valide-debut
    for gate in gates:
        if table.get(gate) not in ("observe", "armed"):
            return False
    if table.get("G6") != table.get("G5"):
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
                brut = donnees.get("ecrit")
                valeurs = [brut] if isinstance(brut, str) else (brut if isinstance(brut, list) else [])
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
# les gates (P45-D-01), les autres clés restent libres.
GENERES_PAR_RECALC = ("STATE.md", "INDEX.md", "cloture.log", ".recalc-cache.json")  # g6-noms
NOM_CONFIG = "config.json"
PROTEGES_G6 = dict([(nom.casefold(), (nom, "recalc")) for nom in GENERES_PAR_RECALC]
                   + [(NOM_JOURNAL_DEROGATIONS.casefold(), (NOM_JOURNAL_DEROGATIONS, "derog")),
                      (NOM_CONFIG.casefold(), (NOM_CONFIG, "adhesion"))])
RAISON_ADHESION = ("config.json : changer ou retirer l'adhésion cycles-v1 désarmerait les gates (P45-D-01) ; "
                   "une écriture par outil doit garder planning_version = cycles-v1")
RAISON_ADHESION_INVERIFIABLE = ("config.json : cette écriture par outil ne permet pas de vérifier que l'adhésion cycles-v1 "
                                "est conservée (Edit inapplicable au contenu actuel, NotebookEdit, contenu illisible) ; "
                                "refusée par précaution (P45-D-01)")
BORNE_PARCOURS_VERDICTS = 20000


def raison_g6(nom, genre):
    if genre == "derog":
        return ("%s est un fichier inscrit par deroger-gate.sh — l'écriture par outil est refusée ; "
                "inscrivez la dérogation par deroger-gate.sh" % nom)
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


def adhesion_conservee(contexte, cible):
    """None si l'écriture proposée laisse planning_version = cycles-v1 ; sinon la raison du refus (F6)."""
    entree = contexte["payload"].get("tool_input")
    if contexte["outil"] == "NotebookEdit" or not isinstance(entree, dict):
        return RAISON_ADHESION_INVERIFIABLE
    texte = entree.get("content") if contexte["outil"] == "Write" else _appliquer_edit(cible, entree)
    if not isinstance(texte, str):
        return RAISON_ADHESION_INVERIFIABLE
    return None if _texte_adherent(texte) else RAISON_ADHESION  # g6-adhesion


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
GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G1", evaluer_g1), ("G7", evaluer_g7), ("ROLE", evaluer_role))  # gates-a-verdict


def evaluer_protege(gate, fonction, contexte):
    try:
        return list(fonction(contexte))
    except Exception as exc:
        return [Verdict(gate, None, "erreur interne du gate : " + type(exc).__name__)]


# --- Évaluation des gates (Phase B) ----------------------------------------------------------
def evaluer_gates(contexte):
    """Liste de résultats (genre, texte), genre `refuse` ou `avertit`. La table d'armement est
    vérifiée d'abord : un code livré qui viole l'ordre des étapes refuse (impossible sur un code
    sain, c'est la garde que les mutants exercent). G2 avertit ; les gates à verdict passent par
    l'entonnoir `decider`."""
    if not armement_valide(TABLE_ARMEMENT):
        return [("refuse", "[planning-core] table d'armement incohérente : l'ordre des étapes "
                           "(G6 et G5, puis G1, puis G7, puis le rôle) n'est pas respecté (P45-D-03)")]
    resultats = []
    resultats.extend(evaluer_g2(contexte))
    verdicts = []
    for gate, fonction in GATES_A_VERDICT:
        verdicts.extend(evaluer_protege(gate, fonction, contexte))
    refus, citations = decider(verdicts, contexte)
    resultats.extend(("refuse", texte) for texte in refus)
    resultats.extend(("avertit", texte) for texte in citations)
    return resultats


def main():
    armer_echeance()  # echeance-armee
    # Mode de diagnostic (45-08) : `--classer <agent.md>`, quatrième argument du cœur ; aucune décision.
    if len(sys.argv) > 4 and sys.argv[4] == "--classer":
        classer_fichier(sys.argv[1])
        sys.exit(0)
    # Phase A : l'adhésion n'est pas encore connue. Toute erreur sort sur un code non nul SANS rien
    # imprimer : la couche shell de la commande enregistrée tranche (P45-D-08, DIV-2).
    try:
        payload = lire_payload(sys.argv[1])  # phase-a
        ecrit, cwd = cible_de(payload)
        depart = ecrit if ecrit is not None else (cwd if cwd is not None else os.getcwd())  # racine-depart
        racine = racine_lab(depart)
        adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"]
    except BaseException:
        sys.exit(3)  # phase-a-sortie
    if not adherent:
        sys.exit(0)  # non-adherent
    # Phase B : le lab est adhérent. Toute erreur devient un refus explicite, code 0 (P45-D-08).
    try:
        contexte = {"payload": payload, "outil": payload.get("tool_name"), "ecrit": ecrit,
                    "cwd": cwd, "racine": racine,
                    "arg_xdg": sys.argv[2] if len(sys.argv) > 2 else "",
                    "arg_home": sys.argv[3] if len(sys.argv) > 3 else ""}
        resultats = evaluer_gates(contexte)  # phase-b
        refus = [texte for genre, texte in resultats if genre == "refuse"]
        avis = [texte for genre, texte in resultats if genre == "avertit"]
        if refus:
            sortie_refus(refus)
        elif avis:
            sortie_contexte(avis)
    except BaseException as exc:
        sortie_refus(["[planning-core] erreur interne du hook central dans un lab adhérent "
                      "cycles-v1 : action refusée (P45-D-08) — " + type(exc).__name__])
    sys.exit(0)


if __name__ == "__main__":
    main()
PY_PLANNING_HOOK_EOF
