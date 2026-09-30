#!/usr/bin/env bash
# deroger-gate.sh — inscrit une dérogation NOMINATIVE à un gate d'écriture dans le journal append-only
# du lab adhérent (Phase 45, 45-04, GATE-11 ; P45-D-13, P45-D-01 ; spec §5.2). Le journal est
# `.planning/derogations-gates.log` (F7a = f7a-racine, Willy, AskUserQuestion session principale,
# 2026-09-30), enfant direct du dossier de planning, déclaré au modèle par 45-02.
#
# Usage : deroger-gate.sh --lab=<racine> --gate=<G1|G5|G6|G7|ROLE> --chemin=<relatif> [--chemin=...]
#                         --qui=<nom> --canal=<canal> --date=<AAAA-MM-JJ> --raison=<texte> [-h]
#
# Trois règles de l'échappatoire (spec §5.2) : nominative (qui, canal, date, gate, chemins, raison) ;
# jamais liée au moment ni à la vitesse (aucune option, aucune condition, aucune horloge ne conditionne
# l'acceptation : l'horodatage n'est qu'ÉCRIT) ; visible (le hook la cite quand il la consomme).
# Durée de vie : usage UNIQUE par (gate, chemin). Le hook qui laisse passer une action grâce à elle
# ajoute une ligne `consommee` au journal ; une dérogation consommée ne sert plus.
#
# Une ligne par chemin. Champs encodés par l'encodage pourcent injectif de la 44 (copie ast-identique
# de _jeton_journal) : une raison qui contient un saut de ligne ne peut pas injecter de fausse ligne.
# Une raison vide, TODO, xxx, une ellipse ou <...> est refusée après normalisation Unicode (NFKC).
# Le journal n'est jamais tronqué : ajout seul (O_APPEND, O_NOFOLLOW), verrou fcntl.flock quand le
# module existe (sinon limite déclarée : course locale). Un journal qui n'est pas un fichier régulier
# n'est pas écrit (code 1).
#
# Codes : 0 inscrit · 1 erreur de lecture ou d'écriture · 2 lab non adhérent · 64 usage ou champ refusé
# (le message nomme le champ).
#
# Limite déclarée (T-45-34) : la commande ne peut pas savoir qui la lance ; `--qui` est déclaratif.
set -u

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then
      PYBIN=python
    else
      echo "[deroger-gate] python3 ou python requis (ADR-054)" >&2
      exit 1
    fi
    ;;
esac

"$PYBIN" -I -S - "$@" <<'PY_DEROGER_GATE_EOF'
import datetime
import json
import os
import re
import stat
import sys
import unicodedata

try:
    import fcntl
except ImportError:
    fcntl = None

SCHEMA_ADHESION = "cycles-v1"
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
GATES = ("G1", "G5", "G6", "G7", "ROLE")
OPTIONS = ("lab", "gate", "chemin", "qui", "canal", "date", "raison")
PLACEHOLDERS = ("todo", "tbd", "fixme", "xxx", "n/a", "...")  # derog-placeholders
IDENTIFIANT_RE = re.compile(r"^\S+  (?:derogation|consommee)  id=([0-9]+)  ", re.M)
USAGE = ("Usage : deroger-gate.sh --lab=<racine> --gate=<G1|G5|G6|G7|ROLE> --chemin=<relatif> "
         "[--chemin=...] --qui=<nom> --canal=<canal> --date=<AAAA-MM-JJ> --raison=<texte> [-h]")


class Refus(Exception):
    def __init__(self, code, message):
        Exception.__init__(self, message)
        self.code = code
        self.message = message


# --- Copies ast-identiques du hook central (adhésion, chemin concret, encodeur du journal) ---------
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


def analyser(args):
    valeurs = {}
    chemins = []
    for arg in args:
        if arg in ("-h", "--help"):
            return None
        if not arg.startswith("--") or "=" not in arg:
            raise Refus(64, "argument non reconnu : " + arg)
        nom, _, valeur = arg[2:].partition("=")
        if nom == "chemin":
            chemins.append(valeur)
        elif nom in OPTIONS:
            if nom in valeurs:
                raise Refus(64, "option répétée : --" + nom)
            valeurs[nom] = valeur
        else:
            raise Refus(64, "option inconnue : --" + nom)
    manquantes = ["--" + n for n in OPTIONS if n != "chemin" and n not in valeurs]
    if not chemins:
        manquantes.append("--chemin")
    if manquantes:
        raise Refus(64, "option obligatoire manquante : " + ", ".join(manquantes))
    return valeurs, chemins


def normaliser(texte):
    """NFKC, caractères de contrôle et de format retirés, strip, casefold : la forme sous laquelle une
    raison est comparée aux placeholders (pleine chasse, espaces de largeur nulle compris)."""
    t = unicodedata.normalize("NFKC", texte)
    t = "".join(c for c in t if unicodedata.category(c) not in ("Cc", "Cf"))
    return t.strip().casefold()


def raison_placeholder(raison):
    n = normaliser(raison)
    if n == "" or n in PLACEHOLDERS:
        return True
    return bool(re.fullmatch(r"x+", n) or re.fullmatch(r"[.…]+", n) or re.fullmatch(r"<[^<>]*>", n))


def valider(valeurs, chemins_bruts):
    if valeurs["gate"] not in GATES:
        raise Refus(64, "--gate : G1, G5, G6, G7 ou ROLE attendu, reçu : " + valeurs["gate"])
    chemins = []
    for brut in chemins_bruts:
        if not entree_ecrit_valide(brut):
            raise Refus(64, "--chemin : chemin concret relatif au lab attendu, reçu : " + brut)
        normal = "/".join(c for c in brut.split("/") if c not in ("", "."))
        if normal == "":
            raise Refus(64, "--chemin : chemin vide après normalisation : " + brut)
        if normal not in chemins:
            chemins.append(normal)
    for nom in ("qui", "canal"):
        if normaliser(valeurs[nom]) == "":
            raise Refus(64, "--" + nom + " : valeur nominative obligatoire (non vide)")
    date = valeurs["date"]
    if not re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", date):
        raise Refus(64, "--date : AAAA-MM-JJ attendu, reçu : " + date)
    try:
        datetime.date(int(date[0:4]), int(date[5:7]), int(date[8:10]))
    except ValueError:
        raise Refus(64, "--date : date calendaire inexistante : " + date)
    if raison_placeholder(valeurs["raison"]):
        raise Refus(64, "--raison : une raison réelle est obligatoire (vide, TODO, xxx, ellipse ou <...> refusés)")
    return chemins


def lire_tout(descripteur):
    os.lseek(descripteur, 0, os.SEEK_SET)
    morceaux = []
    while True:
        lu = os.read(descripteur, 65536)
        if not lu:
            break
        morceaux.append(lu)
    return b"".join(morceaux)


def inscrire(lab, valeurs, chemins):
    journal = os.path.join(lab, ".planning", "derogations-gates.log")
    if os.path.lexists(journal) and not est_fichier_regulier(journal):
        raise Refus(1, "le journal des dérogations n'est pas un fichier régulier : aucune écriture")
    descripteur = os.open(journal, os.O_RDWR | os.O_APPEND | os.O_CREAT | SANS_SUIVI_DE_LIEN, 0o644)
    try:
        if hasattr(os, "fchmod"):
            os.fchmod(descripteur, 0o644)
        if fcntl is not None:
            fcntl.flock(descripteur, fcntl.LOCK_EX)
        existant = lire_tout(descripteur)
        identifiants = [int(i) for i in IDENTIFIANT_RE.findall(existant.decode("utf-8", "replace"))]
        suivant = (max(identifiants) if identifiants else 0) + 1
        horodatage = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
        raison_j = _jeton_journal(valeurs["raison"], "-")  # derog-encodage
        lignes = []
        for rang, chemin in enumerate(chemins):
            lignes.append("{}  derogation  id={}  gate={}  chemin={}  qui={}  canal={}  date={}  raison={}".format(
                horodatage, suivant + rang, valeurs["gate"], _jeton_journal(chemin, "-"),
                _jeton_journal(valeurs["qui"], "-"), _jeton_journal(valeurs["canal"], "-"), valeurs["date"], raison_j))
        donnees = ("\n" if existant and not existant.endswith(b"\n") else "") + "".join(l + "\n" for l in lignes)
        octets = donnees.encode("utf-8")
        while octets:
            ecrit = os.write(descripteur, octets)
            octets = octets[ecrit:]
    finally:
        os.close(descripteur)
    return suivant


def deroger(valeurs, chemins_bruts):
    chemins = valider(valeurs, chemins_bruts)
    lab = os.path.realpath(valeurs["lab"])
    if not os.path.isdir(lab) or not verifier_adhesion(os.path.join(lab, ".planning"))["adherente"]:
        raise Refus(2, "lab non adhérent : le config.json du dossier de planning doit déclarer "
                       "\"planning_version\": \"cycles-v1\"")
    premier = inscrire(lab, valeurs, chemins)
    for rang, chemin in enumerate(chemins):
        print("[deroger-gate] dérogation #%d inscrite : %s sur %s (%s, %s, %s)" % (
            premier + rang, valeurs["gate"], chemin, valeurs["qui"], valeurs["canal"], valeurs["date"]))


def main():
    try:
        analyse = analyser(sys.argv[1:])
        if analyse is None:
            print(USAGE)
            sys.exit(0)
        deroger(*analyse)
    except Refus as refus:
        print("[deroger-gate] " + refus.message, file=sys.stderr)
        if refus.code == 64:
            print(USAGE, file=sys.stderr)
        sys.exit(refus.code)
    except OSError as exc:
        print("[deroger-gate] échec de lecture ou d'écriture : " + str(exc), file=sys.stderr)
        sys.exit(1)
    sys.exit(0)


main()
PY_DEROGER_GATE_EOF
