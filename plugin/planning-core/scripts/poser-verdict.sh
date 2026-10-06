#!/usr/bin/env bash
# poser-verdict.sh — pose le VERDICT.md d'une unité (phase ou plan) d'un lab adhérent cycles-v1
# (Phase 45, 45-04, GATE-05 ; P45-D-07, P45-D-10). C'est le SEUL chemin légitime vers un VERDICT.md :
# G5 refuse toute écriture de ce fichier par Write, Edit ou NotebookEdit ; cette commande, lancée par
# Bash, n'est jamais vue par G5.
#
# Usage : poser-verdict.sh --unite=<dossier de l'unité : phase, plan ou juge> --juge=<nom> --tentative=<n> --score=<texte>
#                          --constat=<critère>::<passé|échec> [--constat=...] [-h]
#
# Qui la lance (décision F8 = f8-agnostique, Willy, AskUserQuestion session principale, 2026-09-30) :
# la commande est agnostique de l'appelant et `--juge` est obligatoire. Le juge la lance lui-même
# quand il a Bash (vf-design-judge) ; sinon le manager la lance sur le rapport du juge (trois juges
# livrés sur quatre n'ont pas Bash : quality-gate-client, content-clarity-judge, growth-quality-judge).
# Le hash vient TOUJOURS de la commande, jamais de l'agent. La tentative est fournie par l'appelant (`--tentative`) et VÉRIFIÉE par la
# commande : 1 à la création, ancienne tentative + 1 pour un remplacement, tout autre entier est refusé (code 64) ; jamais prise sur parole.
#
# Deux empreintes (Phase 46, 46-01 ; P46-D-03, P46-D-03a, P46-D-12 ; Willy, AskUserQuestion session
# principale, 2026-10-03, Q3 = a), toutes deux calculées ici par hashlib (jamais un outil externe) et
# jamais par l'agent, sous le verrou du PLAN.md :
#   `hash`           décision A3 = a3-plan (même arbitrage, même canal que le reste de ce fichier) :
#                    le sha256 des octets du PLAN.md de l'unité ;
#   `hash_livrables` l'empreinte composée des entrées `ecrit:` du PLAN.md (fichier : chemin relatif et
#                    sha256 ; dossier : la liste triée de ses fichiers réguliers ; aucun lien suivi ; parcours
#                    borné à BORNE_FICHIERS_LIVRABLES entrées et BORNE_OCTETS_LIVRABLES octets ; le
#                    texte canonique est décrit à `empreinte_livrables` et dans modele-cycles.md).
# La commande REFUSE de poser un verdict (code 64) quand un livrable déclaré est absent, vide ou un lien
# (jamais suivi), quand `ecrit:` est absent ou invalide, ou quand une borne est dépassée : jamais une
# empreinte partielle. Elle refuse aussi (64, message distinct) une entrée `ecrit:` qui est ou contient le
# dossier de l'unité (l'unité, `.planning` ou un autre ancêtre, sans égard à la casse) : le verdict s'y écrit,
# `hash_livrables` serait périmé dès la pose (point fixe ; décision du manager, vf-dev-manager, mandat de
# correction ciblée du 2026-10-03, revue anticipée du socle, renversable) ; ce refus précède la lecture de
# VERDICT.md, tout temporaire et toute consommation de dérogation. Le bloc partagé avec le hook central et
# le recalcul (copies ast-identiques, entrées comprises, R-EMP-04) porte la chaîne unique `entrees_du_plan`
# (PLAN.md -> entrées -> validation) -> `livrables_presents` (prédicat, budget COMMUN à toutes les entrées
# d'un PLAN.md) -> `empreinte_livrables` ; la lecture ne suit aucun lien à aucun composant (ouvertures
# chaînées par descripteur de dossier, O_NOFOLLOW, O_NONBLOCK).
#
# Règles : la tentative vaut 1 à la création, ancienne tentative + 1 pour remplacer un VERDICT.md
# existant (sinon code 64, fichier inchangé) ; l'écriture est atomique (fichier temporaire du même
# dossier, fchmod 0644, os.replace) et ne traverse jamais un lien ; un VERDICT.md qui n'est pas un
# fichier régulier (lien, par exemple) n'est pas un verdict existant : il est remplacé, jamais suivi.
# Les valeurs qui ne se relisent pas identiques par le parseur de frontmatter sont refusées (64).
#
# Seconde forme d'unité (Phase 46, 46-01 ; P46-D-06a ; Willy, AskUserQuestion session principale, 2026-10-03, Q6 = a) : le
# verdict du canary d'un juge se pose sur `.planning/juges/<juge>` (3 composants après la racine du lab, `juges` en casse exacte,
# nom `^[a-z0-9][a-z0-9-]{0,63}$`). L'artefact haché est SORTIE-PIEGEE.md (fichier régulier, jamais un lien) au lieu du PLAN.md ; le
# verdict n'a pas de `hash_livrables` ; le plafond de tentatives s'y applique comme à toute unité. Toute autre forme reste refusée.
#
# Plafond de tentatives (Phase 46, 46-01 ; P46-D-05 ; Willy, AskUserQuestion session principale, 2026-10-03,
# Q5 = a) : PLAFOND_TENTATIVES = 3 est une CONSTANTE de ce script, jamais lue dans un fichier du lab ni dans
# l'environnement. Une tentative au-delà (la quatrième) est refusée avec le code 65 et un message distinct, VERDICT.md
# inchangé, SAUF dérogation nominative du journal `.planning/derogations-gates.log` (jeton PLAFOND, chemin = l'unité
# relative au lab : `deroger-gate.sh --gate=PLAFOND`). La dérogation est à usage UNIQUE : elle est consommée (ligne
# `consommee`, sous le verrou exclusif du journal, MÊME code que le hook central) après le verrou du PLAN.md et AVANT
# l'écriture ; si l'écriture échoue après la consommation, la dérogation est perdue — fail-closed, visible au journal.
# Limite déclarée (g) (libellé mesuré par sonde, quick 261003-ps1) : supprimer VERDICT.md, ou le remplacer par un lien ou
# un FIFO, remet le compteur à 1 (tentative 1 acceptée, code 0 ; le lien est remplacé, jamais suivi) ; le remplacer par un
# dossier remet le contrôle à 1 mais l'écriture échoue (code 1, aucun verdict tant que le dossier reste) ; y éditer
# `tentative:` à une valeur plus basse remet le compteur à cette valeur + 1 (à 0, la tentative 1 est acceptée). Les
# écritures par Bash restent ouvertes. Précisions (libellé mesuré par sonde, quick 261006-23m) : un agent qui a Bash peut
# s'accorder lui-même la dérogation PLAFOND (deroger-gate.sh --gate=PLAFOND, --qui déclaratif, T-45-34 ; mesuré : la
# quatrième pose rend 65 sans elle, 0 avec) — dérogation journalisée et citée à la pose, et, pour D1, deux écritures du
# moteur (lignes `moteur`), jamais un contournement ; la disparition de VERDICT.md n'est tracée que si FileChanged la voit
# en séance (ligne `contournement` à sha256=absent, quand une référence du fichier existe) : supprimé puis reposé avant le
# SessionStart suivant, le verdict reposé est une écriture du moteur et la réconciliation ne trace rien (mesuré : aucun
# contournement, `tentative: 1`).
#
# Codes : 0 écrit · 1 erreur de lecture ou d'écriture · 2 lab non adhérent · 64 usage, tentative
# incohérente, constat invalide, unité hors forme (ni .planning/cycles/…, ni .planning/juges/<juge>) ou sans PLAN.md
# (sans SORTIE-PIEGEE.md pour un juge), ecrit: invalide, entrée ecrit: qui est ou contient le dossier de l'unité,
# livrable absent, vide ou lien, borne dépassée · 65 plafond de tentatives atteint sans dérogation.
#
# Limite déclarée : la commande ne peut pas savoir qui la lance (trace déclarative : `--juge`).
set -u

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then
      PYBIN=python
    else
      echo "[poser-verdict] python3 ou python requis (ADR-054)" >&2
      exit 1
    fi
    ;;
esac

"$PYBIN" -I -S - "$@" <<'PY_POSER_VERDICT_EOF'
import datetime
import hashlib
import json
import os
import re
import stat
import sys
import tempfile
import unicodedata
import urllib.parse

try:
    import fcntl
except ImportError:
    fcntl = None

SCHEMA_ADHESION = "cycles-v1"
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
NOM_UNITE = re.compile(r"^[0-9]{2,}-[\w.-]+$")
RESULTATS = ("passé", "échec")
OPTIONS_SIMPLES = ("unite", "juge", "tentative", "score")
PLAFOND_TENTATIVES = 3  # verdict-plafond-constante
NOM_SORTIE_PIEGEE = "SORTIE-PIEGEE.md"
JUGE_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}\Z")
USAGE = ("Usage : poser-verdict.sh --unite=<dossier de l'unité : phase, plan ou juge> --juge=<nom> --tentative=<n> "
         "--score=<texte> --constat=<critère>::<passé|échec> [--constat=...] [-h]")


class Refus(Exception):
    def __init__(self, code, message):
        Exception.__init__(self, message)
        self.code = code
        self.message = message


# --- Copies ast-identiques du hook central (lecture de l'adhésion, racine du lab, frontmatter) ------
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


def analyser(args):
    valeurs = {}
    constats = []
    for arg in args:
        try:
            arg.encode("utf-8")
        except UnicodeEncodeError:
            raise Refus(64, "argument non UTF-8 (octet invalide dans la ligne de commande)")  # verdict-utf8
        if arg in ("-h", "--help"):
            return None
        if not arg.startswith("--") or "=" not in arg:
            raise Refus(64, "argument non reconnu : " + arg)
        nom, _, valeur = arg[2:].partition("=")
        if nom == "constat":
            constats.append(valeur)
        elif nom in OPTIONS_SIMPLES:
            if nom in valeurs:
                raise Refus(64, "option répétée : --" + nom)
            valeurs[nom] = valeur
        else:
            raise Refus(64, "option inconnue : --" + nom)
    manquantes = ["--" + n for n in OPTIONS_SIMPLES if n not in valeurs]
    if not constats:
        manquantes.append("--constat")
    if manquantes:
        raise Refus(64, "option obligatoire manquante : " + ", ".join(manquantes))
    return valeurs, constats


def caractere_interdit(texte):
    """Premier caractère de contrôle (catégorie Cc : CR, VT, FF, FS, GS, RS, NEL, tabulation…) ou séparateur de ligne ou de
    paragraphe (Zl, Zp : U+2028, U+2029) du texte, ou None. Le moteur relit le VERDICT.md en newlines universels : un tel
    caractère dans --juge, --score ou --constat y devenait une ligne de plus (verdict en échec lu « close », `hash` ou `tentative`
    forgés), alors que le relecteur de cette commande, qui ne coupe que sur `\n`, ne le voyait pas (audit H4, décision du manager
    vf-dev-manager, 2026-10-01)."""
    for caractere in texte:
        if unicodedata.category(caractere) in ("Cc", "Zl", "Zp"):
            return caractere
    return None


def forme_unite(composants):
    """Vrai si `composants` (relatifs à la racine du lab) désignent le dossier d'une unité du modèle : phase
    `.planning/cycles/<cycle>/phases/<phase>` ou plan `.../phases/<phase>/plans/<plan>`, noms fixes comparés en casefold, noms d'unité
    conformes à NOM_UNITE — la même règle que `unite_de_plan` du hook central (revue m3)."""
    n = len(composants)
    if n not in (5, 7):
        return False
    if composants[0].casefold() != ".planning" or composants[1].casefold() != "cycles" or composants[3].casefold() != "phases":
        return False
    if n == 7 and composants[5].casefold() != "plans":
        return False
    unites = [composants[2], composants[4]] + ([composants[6]] if n == 7 else [])
    return all(NOM_UNITE.match(u) for u in unites)


# --- Copies ast-identiques du hook central et du moteur de recalcul (Phase 46, 46-01) ---------------------------------
# Entrée `ecrit:` valide (hook, recalcul, deroger-gate.sh) et lecture des entrées (recalcul) : un contrôle croisé de la suite
# test-cloture-empreintes.sh compare les arbres de syntaxe (R-EMP-04) et rougit à la moindre divergence.
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
    """Vrai si l'entrée `ecrit:` EST le dossier de l'unité (`unite_rel`, relatif au lab) ou l'un de ses ancêtres, comparé par composants,
    chacun en forme normale NFC puis sans égard à la casse (sur un système de fichiers insensible à la casse ou à la normalisation, `.PLANNING`
    et un nom saisi en NFD désignent le même dossier ; A1, fix-46-a). Une entrée qui se normalise en rien (`.`) n'est pas un livrable : le
    prédicat la rend `absente`, elle n'est pas traitée ici."""
    cible = [unicodedata.normalize("NFC", c).casefold() for c in _normaliser_livrable(entree).split("/") if c != ""]  # nfc-couvre
    unite = [unicodedata.normalize("NFC", c).casefold() for c in unite_rel.split("/") if c not in ("", ".")]
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


# --- Dérogation nominative PLAFOND (P46-D-05) : copies ast-identiques des fonctions du journal du hook central ----------
# Le plafond de tentatives se lève par une dérogation nominative du journal `.planning/derogations-gates.log` (jeton PLAFOND, chemin
# = l'unité relative au lab), à usage unique : `consommer` est le MÊME code que celui du hook (verrou exclusif du journal, relecture
# sous le verrou, ajout d'une ligne `consommee`).
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


def inscrire_ecriture_moteur(racine, chemin_rel, par):
    """D1 (Phase 46, 46-07 ; P46-D-07a) : après une écriture EFFECTIVE du moteur sur `chemin_rel` (relatif au lab, séparateur `/`), inscrit la ligne
    `moteur` au journal de D1 avec le sha256 du fichier APRÈS écriture : elle explique le changement que le watcher verra. Une erreur n'a AUCUN effet sur
    le code de sortie (aucune ligne)."""
    try:
        chemin = os.path.join(racine, *chemin_rel.split("/"))
        if not stat.S_ISREG(os.lstat(chemin).st_mode):
            return
        hacheur = hashlib.sha256()
        with os.fdopen(os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN), "rb") as fh:
            while True:
                bloc = fh.read(65536)
                if not bloc:
                    break
                hacheur.update(bloc)
        inscrire_surveillance(racine, "moteur", chemin_rel, hacheur.hexdigest(), par, None)
    except Exception:
        return


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


def forme_juge(composants):
    """Vrai si `composants` (relatifs à la racine du lab) désignent le dossier d'un juge : `.planning/juges/<juge>`, `juges` en casse
    exacte, nom de juge en minuscules, chiffres et tirets (JUGE_RE). L'artefact haché de cette unité est SORTIE-PIEGEE.md, jamais
    PLAN.md, et son verdict ne porte pas d'empreinte de livrables (P46-D-06a)."""
    return len(composants) == 3 and composants[0].casefold() == ".planning" and composants[1] == "juges" and JUGE_RE.match(composants[2]) is not None  # verdict-forme-juge


def ouvrir_verrou(chemin):
    """Prend le verrou exclusif (`fcntl.flock`) sur le fichier régulier `chemin` — le PLAN.md voisin du VERDICT.md, ouvert sans suivre
    de lien — et rend son descripteur, gardé ouvert jusqu'à la fin du processus ; None quand le module fcntl n'existe pas (pas de
    verrou). Deux poses simultanées se suivent : la seconde relit la tentative écrite par la première (revue m4, audit B3)."""
    if fcntl is None:
        return None
    descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
    fcntl.flock(descripteur, fcntl.LOCK_EX)
    return descripteur


def lire_octets(chemin):
    descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
    with os.fdopen(descripteur, "rb") as fh:
        return fh.read()


def controle_tentative(nouvelle, ancienne):
    """1 à la création, ancienne + 1 pour remplacer : sinon refus 64, fichier inchangé (anti-boucle)."""
    attendue = 1 if ancienne is None else ancienne + 1
    if nouvelle != attendue:  # verdict-tentative
        raise Refus(64, "--tentative : %d attendu (%s), reçu %d" % (
            attendue, "création" if ancienne is None else "ancienne tentative %d + 1" % ancienne, nouvelle))


def empreinte_des_livrables(racine, octets_plan, unite_rel):
    """Empreinte composée des livrables `ecrit:` du PLAN.md (octets déjà lus sous le verrou), ou refus 64. Mince adaptateur de la
    chaîne unique du bloc partagé : `entrees_du_plan` (PLAN.md -> entrées -> validation, refus d'une entrée qui est ou contient le
    dossier de l'unité `unite_rel`) puis `empreinte_livrables` (livrable absent, vide ou lien, borne dépassée, livrable illisible)
    (P46-D-03, P46-D-03a, P46-D-12). Les messages ne nomment que l'entrée déclarée (relative au lab) ou la borne : jamais un chemin
    absolu, jamais le texte d'une OSError (P46-D-10)."""
    motif, entrees = entrees_du_plan(octets_plan, unite_rel)
    if motif == "non-utf8":
        raise Refus(64, "PLAN.md : texte non UTF-8, ecrit: illisible : aucun livrable à empreinter")
    if motif == "frontmatter":
        raise Refus(64, "PLAN.md : frontmatter illisible (%s), ecrit: invalide : aucun livrable à empreinter" % entrees)
    if motif == "absent":
        raise Refus(64, "PLAN.md : ecrit: absent ou vide : aucun livrable à empreinter")
    if motif == "invalide":
        fautive = entrees
        nom_fautif = "chemin absolu ou ~ refusé" if isinstance(fautive, str) and fautive.startswith(("/", "~")) else repr(fautive)
        raise Refus(64, "PLAN.md : ecrit: invalide (entrée %s) : chemin concret relatif au lab attendu" % nom_fautif)
    if motif == "unite":
        raise Refus(64, "PLAN.md : ecrit: l'entrée %s est ou contient le dossier de l'unité : le verdict s'y écrit, hash_livrables serait périmé dès la pose — verdict non posé (déclarez les livrables eux-mêmes)" % entrees)
    statut, detail = empreinte_livrables(racine, entrees)
    if statut != "ok":
        raison = {"absent": "est absent", "vide": "est vide", "lien": "est un lien (jamais suivi)",
                  "illisible": "est illisible"}.get(statut)
        if raison is not None:
            raise Refus(64, "livrable %s %s (ecrit: du PLAN.md) : verdict non posé" % (detail, raison))
        raise Refus(64, "empreinte des livrables refusée : %s : verdict non posé" % detail)
    return detail


def lignes_verdict(juge, empreinte, empreinte_livr, tentative, score, constats):
    lignes = ["---", 'juge: "%s"' % juge, 'hash: "%s"' % empreinte]
    if empreinte_livr is not None:
        lignes.append('hash_livrables: "%s"' % empreinte_livr)  # verdict-hash-livrables
    lignes.extend(["tentative: %d" % tentative, 'score: "%s"' % score, "constats:"])
    for critere, resultat in constats:
        lignes.append('  - critere: "%s"' % critere)
        lignes.append('    resultat: "%s"' % resultat)
    lignes.extend(["---", "", "# Verdict", "",
                   "Posé par `poser-verdict.sh` (P45-D-07, P46-D-03) : les deux empreintes sont calculées par la commande, jamais par "
                   "l'agent — `hash` (sha256 des octets du PLAN.md de l'unité, A3) et `hash_livrables` (empreinte composée des entrées "
                   "`ecrit:` du PLAN.md, aucun lien suivi, parcours borné) ; la tentative est fournie par l'appelant "
                   "et vérifiée par la commande (1 à la création, ancienne + 1 pour un remplacement). "
                   "Le `score` est affiché et non bloquant ; seuls les `constats` en échec bloquent.", ""])
    return "\n".join(lignes)


def verifier_relecture(texte, juge, empreinte, empreinte_livr, tentative, score, constats):
    statut, donnees = lire_frontmatter(texte)
    attendu = {"juge": juge, "hash": empreinte, "tentative": str(tentative), "score": score,
               "constats": [{"critere": c, "resultat": r} for c, r in constats]}
    if empreinte_livr is not None:
        attendu["hash_livrables"] = empreinte_livr
    if statut != "ok" or donnees != attendu:
        raise Refus(64, "valeur(s) qui ne se relisent pas identiques (guillemet, saut de ligne ou "
                        "caractère de contrôle dans --juge, --score ou --constat)")


def ecrire_atomique(dossier, nom, texte):
    chemin_verdict = os.path.join(dossier, nom)
    descripteur, chemin_tmp = tempfile.mkstemp(prefix=".VERDICT.", suffix=".tmp", dir=dossier)
    try:
        with os.fdopen(descripteur, "w", encoding="utf-8") as fh:
            fh.write(texte)
            fh.flush()
            os.fchmod(fh.fileno(), 0o644)
        os.replace(chemin_tmp, chemin_verdict)  # verdict-atomique
    except BaseException:
        if os.path.lexists(chemin_tmp):
            os.unlink(chemin_tmp)
        raise
    return chemin_verdict


def poser(valeurs, constats_bruts):
    if not re.fullmatch(r"[0-9]+", valeurs["tentative"]) or int(valeurs["tentative"]) < 1:
        raise Refus(64, "--tentative : entier supérieur ou égal à 1 attendu")
    tentative = int(valeurs["tentative"])
    juge = valeurs["juge"]
    for nom, valeur in [("juge", juge), ("score", valeurs["score"])] + [("constat", brut) for brut in constats_bruts]:
        fautif = caractere_interdit(valeur)
        if fautif is not None: raise Refus(64, "--%s : caractère de contrôle ou séparateur de ligne (U+%04X) refusé" % (nom, ord(fautif)))  # verdict-controles
    if juge.strip() == "":
        raise Refus(64, "--juge : nom du juge obligatoire (non vide)")
    constats = []
    for brut in constats_bruts:
        critere, separateur, resultat = brut.rpartition("::")
        if separateur == "" or critere.strip() == "" or resultat not in RESULTATS:
            raise Refus(64, "--constat : <critère>::<passé|échec> attendu, reçu : " + brut)
        constats.append((critere, resultat))
    unite = os.path.realpath(valeurs["unite"])
    if not os.path.isdir(unite):
        raise Refus(64, "--unite : dossier introuvable : " + valeurs["unite"])
    racine = racine_lab(unite)
    if racine is None or not verifier_adhesion(os.path.join(racine, ".planning"))["adherente"]:
        raise Refus(2, "lab non adhérent : le config.json du dossier de planning doit déclarer "
                       "\"planning_version\": \"cycles-v1\"")
    composants = [unicodedata.normalize("NFC", c) for c in os.path.relpath(unite, racine).split(os.sep) if c not in ("", ".")]  # nfc-verdict-unite
    juge_forme = forme_juge(composants)
    if not (forme_unite(composants) or juge_forme): raise Refus(64, "--unite : l'unité doit être un dossier de phase ou de plan du modèle (.planning/cycles/<cycle>/phases/<phase>[/plans/<plan>]) ou le dossier d'un juge (.planning/juges/<juge>)")  # verdict-forme-unite
    nom_artefact = NOM_SORTIE_PIEGEE if juge_forme else "PLAN.md"
    plan = os.path.join(unite, nom_artefact)
    if not est_fichier_regulier(plan):
        raise Refus(64, "--unite : pas de %s régulier dans l'unité (artefact haché%s)" % (nom_artefact, "" if juge_forme else ", A3"))
    verrou = ouvrir_verrou(plan)  # verdict-verrou
    octets_plan = lire_octets(plan)
    empreinte = hashlib.sha256(octets_plan).hexdigest()
    unite_rel = "/".join(composants)
    empreinte_livr = None if juge_forme else empreinte_des_livrables(racine, octets_plan, unite_rel)
    chemin_verdict = os.path.join(unite, "VERDICT.md")
    ancienne = None
    if est_fichier_regulier(chemin_verdict):
        try:
            statut, donnees = lire_frontmatter(lire_octets(chemin_verdict).decode("utf-8"))
        except (OSError, UnicodeDecodeError):
            raise Refus(64, "VERDICT.md existant illisible : tentative inconnue, fichier inchangé")
        brute = donnees.get("tentative") if statut == "ok" else None
        if not isinstance(brute, str) or not re.fullmatch(r"[0-9]+", brute):
            raise Refus(64, "VERDICT.md existant sans tentative lisible : fichier inchangé")
        ancienne = int(brute)
    controle_tentative(tentative, ancienne)
    texte = lignes_verdict(juge, empreinte, empreinte_livr, tentative, valeurs["score"], constats)
    verifier_relecture(texte, juge, empreinte, empreinte_livr, tentative, valeurs["score"], constats)
    if tentative > PLAFOND_TENTATIVES:  # verdict-plafond
        derogation = derogation_active(racine, "PLAFOND", unite_rel)
        if derogation is None:
            raise Refus(65, "plafond de %d tentatives atteint pour %s : arbitrage humain requis (deroger-gate.sh --gate=PLAFOND, ou DEROGATION.md)" % (PLAFOND_TENTATIVES, unite_rel))
        if not consommer(racine, derogation): raise Refus(65, "plafond de %d tentatives atteint pour %s : la dérogation PLAFOND n'a pas pu être consommée, verdict non posé" % (PLAFOND_TENTATIVES, unite_rel))  # verdict-consommation
        inscrire_ecriture_moteur(racine, ".planning/" + NOM_JOURNAL_DEROGATIONS, "poser-verdict.sh")  # d1-moteur-plafond
        print(citer(derogation))
    ecrire_atomique(unite, "VERDICT.md", texte)
    inscrire_ecriture_moteur(racine, unite_rel + "/VERDICT.md", "poser-verdict.sh")  # d1-moteur-verdict
    print("[poser-verdict] VERDICT.md écrit : %s (juge %s, tentative %d, hash %s, hash_livrables %s)" % (
        unite_rel + "/VERDICT.md", juge, tentative, empreinte, empreinte_livr))


def main():
    try:
        analyse = analyser(sys.argv[1:])
        if analyse is None:
            print(USAGE)
            sys.exit(0)
        poser(*analyse)
    except Refus as refus:
        print("[poser-verdict] " + refus.message, file=sys.stderr)
        if refus.code == 64:
            print(USAGE, file=sys.stderr)
        sys.exit(refus.code)
    except OSError as exc:
        print("[poser-verdict] échec de lecture ou d'écriture (%s) : aucun verdict posé" % type(exc).__name__, file=sys.stderr)
        sys.exit(1)
    sys.exit(0)


main()
PY_POSER_VERDICT_EOF
