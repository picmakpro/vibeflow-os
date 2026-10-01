#!/usr/bin/env bash
# poser-verdict.sh — pose le VERDICT.md d'une unité (phase ou plan) d'un lab adhérent cycles-v1
# (Phase 45, 45-04, GATE-05 ; P45-D-07, P45-D-10). C'est le SEUL chemin légitime vers un VERDICT.md :
# G5 refuse toute écriture de ce fichier par Write, Edit ou NotebookEdit ; cette commande, lancée par
# Bash, n'est jamais vue par G5.
#
# Usage : poser-verdict.sh --unite=<dossier de l'unité> --juge=<nom> --tentative=<n> --score=<texte>
#                          --constat=<critère>::<passé|échec> [--constat=...] [-h]
#
# Qui la lance (décision F8 = f8-agnostique, Willy, AskUserQuestion session principale, 2026-09-30) :
# la commande est agnostique de l'appelant et `--juge` est obligatoire. Le juge la lance lui-même
# quand il a Bash (vf-design-judge) ; sinon le manager la lance sur le rapport du juge (trois juges
# livrés sur quatre n'ont pas Bash : quality-gate-client, content-clarity-judge, growth-quality-judge).
# Le hash et la tentative viennent TOUJOURS de la commande, jamais de l'agent.
#
# Artefact haché (décision A3 = a3-plan, même arbitrage, même canal) : le sha256 des octets du
# PLAN.md de l'unité, calculé ici par hashlib (jamais un outil externe). Il ne prouve pas que le
# livrable jugé est celui qui a été produit : la vérification du hash à la clôture relève de la
# Phase 46 (modele-cycles.md § VERDICT.md).
#
# Règles : la tentative vaut 1 à la création, ancienne tentative + 1 pour remplacer un VERDICT.md
# existant (sinon code 64, fichier inchangé) ; l'écriture est atomique (fichier temporaire du même
# dossier, fchmod 0644, os.replace) et ne traverse jamais un lien ; un VERDICT.md qui n'est pas un
# fichier régulier (lien, par exemple) n'est pas un verdict existant : il est remplacé, jamais suivi.
# Les valeurs qui ne se relisent pas identiques par le parseur de frontmatter sont refusées (64).
#
# Codes : 0 écrit · 1 erreur de lecture ou d'écriture · 2 lab non adhérent · 64 usage, tentative
# incohérente, constat invalide, unité hors .planning/cycles/ ou sans PLAN.md.
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
import hashlib
import json
import os
import re
import stat
import sys
import tempfile
import unicodedata

try:
    import fcntl
except ImportError:
    fcntl = None

SCHEMA_ADHESION = "cycles-v1"
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
NOM_UNITE = re.compile(r"^[0-9]{2,}-[\w.-]+$")
RESULTATS = ("passé", "échec")
OPTIONS_SIMPLES = ("unite", "juge", "tentative", "score")
USAGE = ("Usage : poser-verdict.sh --unite=<dossier de l'unité> --juge=<nom> --tentative=<n> "
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


def racine_lab(depart):
    """Racine physique du lab : le PLUS PROCHE ancêtre qui contient un DOSSIER `.planning` (le
    plus proche gagne, P45-D-01a/P45-D-12) et qui n'est pas lui-même dans (ou sous) un composant `.planning`
    (`sous_planning`), ou None. Un départ non absolu n'a pas de lab."""
    if not isinstance(depart, str) or not depart.startswith("/"):
        return None
    courant = _partie_existante(depart)
    while True:
        if os.path.isdir(os.path.join(courant, ".planning")) and not sous_planning(courant):  # racine-imbriquee
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


def lignes_verdict(juge, empreinte, tentative, score, constats):
    lignes = ["---", 'juge: "%s"' % juge, 'hash: "%s"' % empreinte, "tentative: %d" % tentative,
              'score: "%s"' % score, "constats:"]
    for critere, resultat in constats:
        lignes.append('  - critere: "%s"' % critere)
        lignes.append('    resultat: "%s"' % resultat)
    lignes.extend(["---", "", "# Verdict", "",
                   "Posé par `poser-verdict.sh` (P45-D-07) : le hash (sha256 des octets du PLAN.md de "
                   "l'unité, A3) et la tentative sont calculés par la commande, jamais par l'agent. "
                   "Le `score` est affiché et non bloquant ; seuls les `constats` en échec bloquent.", ""])
    return "\n".join(lignes)


def verifier_relecture(texte, juge, empreinte, tentative, score, constats):
    statut, donnees = lire_frontmatter(texte)
    attendu = {"juge": juge, "hash": empreinte, "tentative": str(tentative), "score": score,
               "constats": [{"critere": c, "resultat": r} for c, r in constats]}
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
    composants = [c for c in os.path.relpath(unite, racine).split(os.sep) if c not in ("", ".")]
    if not forme_unite(composants): raise Refus(64, "--unite : l'unité doit être un dossier de phase ou de plan du modèle (.planning/cycles/<cycle>/phases/<phase>[/plans/<plan>])")  # verdict-forme-unite
    plan = os.path.join(unite, "PLAN.md")
    if not est_fichier_regulier(plan):
        raise Refus(64, "--unite : pas de PLAN.md régulier dans l'unité (artefact haché, A3)")
    verrou = ouvrir_verrou(plan)  # verdict-verrou
    empreinte = hashlib.sha256(lire_octets(plan)).hexdigest()
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
    texte = lignes_verdict(juge, empreinte, tentative, valeurs["score"], constats)
    verifier_relecture(texte, juge, empreinte, tentative, valeurs["score"], constats)
    ecrire_atomique(unite, "VERDICT.md", texte)
    print("[poser-verdict] VERDICT.md écrit : %s (juge %s, tentative %d, hash %s)" % (
        os.path.join(os.path.relpath(unite, racine), "VERDICT.md"), juge, tentative, empreinte))


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
        print("[poser-verdict] échec de lecture ou d'écriture : " + str(exc), file=sys.stderr)
        sys.exit(1)
    sys.exit(0)


main()
PY_POSER_VERDICT_EOF
