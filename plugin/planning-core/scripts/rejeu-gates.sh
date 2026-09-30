#!/usr/bin/env bash
# rejeu-gates.sh — outil de REJEU EN LECTURE SEULE des gates d'écriture de planning-core (Phase 45,
# 45-03 ; GATE-13 ; P45-D-21, P45-D-21a, P45-D-21c, P45-D-03b). Il mesure les faux refus ET les
# faux accept d'un hook central sur des labs dont les chemins lui sont passés en argument : avant
# d'armer un gate, on veut savoir ce qu'il refuserait sur du réel — chaque refus nominatif, jamais
# une moyenne (un gate mal calibré a refusé 200 entrées sur 206, spec §5.1).
#
# Ce qu'il ne fait JAMAIS : écrire dans un lab passé en argument, lancer un gestionnaire de versions,
# lire une variable d'environnement qui change un verdict (HOME ne sert qu'à afficher `~/…` et au
# hook lui-même, qui le lit pour résoudre les définitions d'agent, P45-D-12a). Il travaille sur une
# COPIE sous mktemp : l'adhésion cycles-v1 y est SIMULÉE (jamais un interrupteur du script livré) et
# l'armement des étapes ≤ --etape y est SIMULÉ sur une copie du hook. Les chemins des labs réels ne
# vivent jamais dans ce fichier ni dans sa suite : ils sont des ARGUMENTS ; ce que les plans 45-05 à
# 45-09 rejouent le fait par `rejeu-reel.sh`, qui prend l'empreinte de TOUT l'arbre hors de cet outil.
#
# Usage :
#   rejeu-gates.sh --lab=<chemin> [--lab=<chemin>…] --etape=<1|2|3|4>
#                  [--attendus=<fichier>] [--rapport=<fichier>] [--hook=<script>]
#   --etape    étape d'armement simulée (P45-D-03) : 1 = G6 et G5 ; 2 = + G1 ; 3 = + G7 ; 4 = + rôle
#   --hook     le hook à rejouer (défaut : planning-hook.sh à côté de ce script) ; toujours COPIÉ
#   --rapport  écrit aussi le relevé dans ce fichier (refusé s'il est sous un lab)
# Codes : 0 mesure faite (quels que soient les comptes), 1 erreur (lecture, empreinte divergente,
# motif d'armement non unique, attendus contradictoires, classification absente), 64 usage.
#
# Relevé (stdout, et --rapport) — lignes, dans cet ordre :
#   <gate> | <lab affiché> | <chemin> | <attendu> | <obtenu> | <raison>       une par écriture rejouée
#   COMPTE <gate> faux-refus=<n> faux-accept=<m> refus-conforme-modele=<k>     une par gate
#   REJEU-ETAPE-<n> faux-refus=<N> faux-accept=<M> refus-conforme-modele=<K>
#   CLASSE-REGLE-ECRITE <gate> lab=<lab affiché> n=<j>                          gate qui classe d'après
#                                                                                le modèle, par lab
#   EMPREINTE-IDENTIQUE <lab affiché>   (ou EMPREINTE-DIVERGENTE + code 1)      une par lab
# Les chemins sous HOME sont affichés `~/…` ; les chemins internes sont relatifs au lab.
#
# Contrat de rejeu : chaque écriture est identifiée par son triplet (outil, chemin relatif au lab
# après normpath, agent_type — vide pour le fil principal) et reçoit UN SEUL attendu, donc une seule
# ligne et un seul compte. `fusionner` applique la priorité : fichier d'attendus > constructeur d'un
# gate > constructeur générique `reecriture` ; les doublons (même clé, même attendu) sont éliminés ;
# des attendus CONTRADICTOIRES de même rang sont une erreur. Attendu à trois valeurs (P45-D-21a) :
#   doit-passer          le modèle autorise l'écriture : refus obtenu = faux refus
#   doit-refuser         le modèle l'interdit pour tout lab : passage obtenu = faux accept
#   doit-refuser-modele  le modèle l'interdit parce que le lab n'est pas migré : refus obtenu =
#                        « refus conforme au modèle, lab non migré » (compté à part, ni faux refus ni
#                        faux accept) ; passage obtenu = faux accept
# Fichier d'attendus : lignes `<gate> | <lab affiché> | <chemin relatif> | <attendu> | <motif>`,
# commentaires `#` ; une ligne dont le lab n'est pas dans cette mesure est ignorée.
# Registre CONSTRUCTEURS (gate -> fonction(lab, ctx) qui rend des tuples (outil, chemin, attendu,
# agent_type[, origine[, charge]])) : `reecriture` (chaque fichier régulier des .planning/ copiés, attendu
# doit-passer) ; `G6` et `G5` (45-05 : fichiers générés, config.json, VERDICT.md) ; 45-06 à 45-09
# ajoutent le leur. `charge` (dict) remplace le tool_input d'un Edit (old_string, new_string,
# replace_all) : l'Edit de config.json qui perd l'adhésion a une clé (outil Edit) distincte de celle de
# la réécriture Write du même fichier. Un constructeur qui classe d'après le modèle porte
# l'attribut `classe_modele` ; il est TOTAL (P45-D-21c) : une écriture sans attendu, ou hors des
# trois valeurs, est une erreur — jamais un doit-passer implicite. `origine` = `regle-ecrite` marque
# une classification par la règle écrite du modèle faute d'état dérivé.
# Les constructeurs de TOUS les gates sont joués quelle que soit --etape : l'étape ne décide que de
# l'armement de la copie du hook.
set -uo pipefail

for arg in "$@"; do
  case "$arg" in
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  esac
done

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

PY_INVOKE="$(py_resolve_local)" || { echo "[rejeu-gates] interpréteur Python introuvable" >&2; exit 1; }
SCRIPT_DIR_SELF="$(cd "$(dirname "$0")" && pwd -P)" || { echo "[rejeu-gates] dossier du script illisible" >&2; exit 1; }

# Hook par défaut : le planning-hook.sh frère, sauf --hook explicite.
HOOK_DONNE=0
for arg in "$@"; do
  case "$arg" in --hook=*) HOOK_DONNE=1 ;; esac
done
if [ "$HOOK_DONNE" -eq 0 ]; then
  set -- "$@" "--hook=$SCRIPT_DIR_SELF/planning-hook.sh"
fi

# shellcheck disable=SC2086
exec $PY_INVOKE -I -S - "$@" <<'PY_REJEU_GATES_EOF'
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

GATES = ("G6", "G5", "G1", "G7", "ROLE")
ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",))
ELAGAGE = ("node_modules", ".git", ".venv", "__pycache__")
MARQUEURS_CODE = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle",
                  "build.gradle.kts", "composer.json", "Gemfile", "tsconfig.json", "Package.swift")
SCHEMA_ADHESION = "cycles-v1"
VALEURS_ATTENDU = ("doit-passer", "doit-refuser", "doit-refuser-modele")
ORIGINES = ("etat-derive", "regle-ecrite")
COMPTES = ("faux-refus", "faux-accept", "refus-conforme-modele")
RANG_ATTENDUS, RANG_GATE, RANG_GENERIQUE = 3, 2, 1
RAISON_MODELE = "refus conforme au modèle, lab non migré"
RAISON_REGLE = "classé par la règle écrite, état dérivé absent"
MAX_CONTENU = 1 << 20
DELAI_HOOK = 120
PREFIXE_GATE = re.compile(r"^\[planning-core\] ([A-Z0-9]+) : ")


class Usage(Exception):
    """Argument invalide : code 64."""


class ErreurOutil(Exception):
    """Erreur de mesure (lecture, armement, attendus, classification) : code 1."""


# --- Affichage : jamais un chemin de machine dans un relevé --------------------------------------
def afficher(chemin):
    p = os.path.realpath(chemin)
    home = os.environ.get("HOME") or ""
    if home:
        h = os.path.realpath(home)
        if p == h:
            return "~"
        if p.startswith(h + os.sep):
            return "~/" + p[len(h) + 1:]  # rejeu-affichage
    return p


def clef(outil, chemin, agent_type):
    return (outil, os.path.normpath(chemin) if chemin else chemin, agent_type)


def montrer_clef(cle):
    return "(%s, %s, %s)" % cle


class Lab:
    def __init__(self, index, arg):
        self.index = index
        self.arg = arg
        self.reel = os.path.realpath(arg)
        self.affiche = afficher(arg)
        self.copie = None
        self.entrees = []
        self.fichiers_planning = []
        self.dossiers_planning = []


# --- Périmètre lu : sous-arbres .planning/ et .claude/, marqueurs de code, aucun lien suivi -------
def parcourir(racine):
    res = []

    def lister(chemin):
        try:
            with os.scandir(chemin) as it:
                return sorted(it, key=lambda x: x.name)
        except OSError as exc:
            raise ErreurOutil("lecture impossible : " + os.path.relpath(chemin, racine) + " (" + type(exc).__name__ + ")")

    def sous_arbre(rel):
        res.append((rel, "d"))
        for e in lister(os.path.join(racine, rel)):
            if e.name in ELAGAGE:
                continue
            r = rel + "/" + e.name
            if e.is_symlink():
                res.append((r, "l"))
            elif e.is_dir(follow_symlinks=False):
                sous_arbre(r)
            elif e.is_file(follow_symlinks=False):
                res.append((r, "f"))

    def rec(rel):
        entrees = lister(os.path.join(racine, rel) if rel else racine)
        porte_planning = any(e.name == ".planning" for e in entrees)
        for e in entrees:
            if e.name in ELAGAGE:
                continue
            r = rel + "/" + e.name if rel else e.name
            if e.name in (".planning", ".claude"):
                if e.is_symlink():
                    res.append((r, "l"))
                elif e.is_dir(follow_symlinks=False):
                    sous_arbre(r)
                continue
            if porte_planning:
                if e.name in MARQUEURS_CODE and (e.is_symlink() or e.is_file(follow_symlinks=False)):
                    res.append((r, "l" if e.is_symlink() else "f"))
                    continue
                if e.name.endswith(".xcodeproj") and e.is_dir(follow_symlinks=False):
                    res.append((r, "d"))
                    continue
            if e.is_dir(follow_symlinks=False):
                rec(r)

    rec("")
    return res


def empreinte_perimetre(lab, entrees, fichier):
    """Empreinte (chemin, type, mode, sha256 ou cible du lien) des `entrees` du périmètre lu, écrite
    dans `fichier`. Le périmètre « après » est PARCOURU DE NOUVEAU : un fichier créé ou supprimé par
    un hook pendant le rejeu doit se voir, pas seulement un fichier connu qui change."""
    lignes = []
    for rel, genre in sorted(entrees, key=lambda t: os.fsencode(t[0])):
        chemin = os.path.join(lab.reel, rel)
        try:
            st = os.lstat(chemin)
            if genre == "l":
                sig = os.readlink(chemin)
            elif genre == "f":
                h = hashlib.sha256()
                with open(chemin, "rb") as fh:
                    for bloc in iter(lambda: fh.read(1 << 20), b""):
                        h.update(bloc)
                sig = h.hexdigest()
            else:
                sig = "-"
            lignes.append("%s\t%s\t%o\t%s" % (rel, genre, st.st_mode & 0o7777, sig))
        except OSError as exc:
            lignes.append("%s\t%s\tERR\t%s" % (rel, genre, type(exc).__name__))
    with open(fichier, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lignes) + ("\n" if lignes else ""))


def copier(lab, dest):
    lab.copie = dest
    os.makedirs(dest)
    for rel, genre in lab.entrees:
        src = os.path.join(lab.reel, rel)
        dst = os.path.join(dest, rel)
        try:
            if genre == "d":
                os.makedirs(dst, exist_ok=True)
            elif genre == "f":
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copyfile(src, dst)
            else:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                os.symlink(os.readlink(src), dst)
        except OSError as exc:
            raise ErreurOutil("copie impossible : " + rel + " (" + type(exc).__name__ + ")")
    for rel, genre in lab.entrees:
        parts = rel.split("/")
        if genre == "d" and parts[-1] == ".planning":
            lab.dossiers_planning.append(rel)
        if genre == "f" and ".planning" in parts[:-1]:
            lab.fichiers_planning.append(rel)


def simuler_adhesion(lab):
    """Adhésion SIMULÉE sur la COPIE : chaque .planning/config.json reçoit planning_version =
    cycles-v1 (autres clés conservées, fichier créé s'il manque). Jamais dans le lab réel."""
    for rel in lab.dossiers_planning:
        cible = os.path.join(lab.copie, rel, "config.json")  # rejeu-adhesion-copie
        donnees = {}
        try:
            with open(cible, encoding="utf-8") as fh:
                lu = json.load(fh)
            if isinstance(lu, dict):
                donnees = lu
        except (OSError, ValueError):
            donnees = {}
        donnees["planning_version"] = SCHEMA_ADHESION
        try:
            if os.path.lexists(cible):
                os.unlink(cible)
            with open(cible, "w", encoding="utf-8") as fh:
                json.dump(donnees, fh)
        except OSError as exc:
            raise ErreurOutil("adhésion simulée impossible : " + rel + " (" + type(exc).__name__ + ")")


def armer_copie(source, dest, etape):
    """Copie du hook dont les lignes ARMEMENT_<gate> des étapes <= `etape` valent armed."""
    try:
        with open(source, encoding="utf-8") as fh:
            texte = fh.read()
    except OSError:
        raise ErreurOutil("hook illisible : " + os.path.basename(source))
    for gate in [g for lot in ORDRE_ETAPES[:etape] for g in lot]:
        motif = re.compile(r'^ARMEMENT_' + gate + r' = "(?:observe|armed)"', re.M)
        if len(motif.findall(texte)) != 1:
            raise ErreurOutil("motif d'armement non unique : ARMEMENT_" + gate)
        texte = motif.sub('ARMEMENT_' + gate + ' = "armed"', texte)
    with open(dest, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(texte)


# --- Constructeurs de corpus ------------------------------------------------------------------------
def construire_reecriture(lab, ctx):
    """Générique : chaque fichier régulier des .planning/ copiés, réécrit à l'identique."""
    return [("Write", rel, "doit-passer", "") for rel in lab.fichiers_planning]


# Noms que G6 protège à la racine du dossier de planning (le même périmètre que le hook : fichiers
# générés, journal de dérogation, cache du recalcul) ; le contrôle de l'adhésion porte sur config.json.
NOMS_G6 = ("STATE.md", "INDEX.md", "cloture.log", "derogations-gates.log", ".recalc-cache.json")
CHARGE_ADHESION_PERDUE = {"old_string": '"' + SCHEMA_ADHESION + '"', "new_string": '"2.0"'}


def construire_g6(lab, ctx):
    """G6 (45-05) : pour chaque dossier de planning copié, doit-refuser la réécriture de chaque fichier
    protégé présent et la création de chaque nom protégé absent (une seule clé par nom : elle prime sur
    la réécriture générique) ; config.json réécrit à l'identique (adhésion simulée) doit passer, le même
    fichier dont planning_version devient 2.0 (Edit) doit être refusé (F6)."""
    sortie = []
    for rel in lab.dossiers_planning:
        for nom in NOMS_G6:
            sortie.append(("Write", rel + "/" + nom, "doit-refuser", ""))
        sortie.append(("Write", rel + "/config.json", "doit-passer", ""))
        sortie.append(("Edit", rel + "/config.json", "doit-refuser", "", "etat-derive", CHARGE_ADHESION_PERDUE))
    return sortie


def construire_g5(lab, ctx):
    """G5 (45-05) : doit-refuser l'écriture d'un VERDICT.md à côté de chaque PLAN.md copié, et la
    réécriture de chaque VERDICT.md copié (le modèle l'interdit pour tout lab)."""
    chemins = set()
    for rel in lab.fichiers_planning:
        nom = rel.split("/")[-1]
        if nom == "PLAN.md":
            chemins.add(os.path.dirname(rel) + "/VERDICT.md")
        elif nom.casefold() == "verdict.md":
            chemins.add(rel)
    return [("Write", rel, "doit-refuser", "") for rel in sorted(chemins)]


CONSTRUCTEURS = {"reecriture": construire_reecriture, "G6": construire_g6, "G5": construire_g5}  # rejeu-registre


def normaliser(lab, gate, brut, rang):
    """Un tuple de constructeur -> dict d'entrée ; la classification est TOTALE (P45-D-21c)."""
    if not isinstance(brut, (tuple, list)) or len(brut) not in (4, 5, 6):
        raise ErreurOutil("écriture mal formée rendue par le constructeur " + gate)
    outil, chemin, attendu, agent_type = brut[:4]
    origine = brut[4] if len(brut) >= 5 else "etat-derive"
    charge = brut[5] if len(brut) == 6 else None
    if charge is not None and not isinstance(charge, dict):
        raise ErreurOutil("charge mal formée rendue par le constructeur " + gate)
    cle = clef(outil, chemin, agent_type or "")
    if attendu not in VALEURS_ATTENDU:
        raise ErreurOutil("classification absente : " + montrer_clef(cle))  # rejeu-total
    if origine not in ORIGINES:
        raise ErreurOutil("origine inconnue : " + str(origine) + " pour " + montrer_clef(cle))
    return {"lab": lab.index, "clef": cle, "attendu": attendu, "origine": origine, "gate": gate, "rang": rang,
            "charge": charge}


def lire_attendus(chemin, labs):
    """Fichier d'attendus : `<gate> | <lab affiché> | <chemin relatif> | <attendu> | <motif>`."""
    entrees = []
    try:
        with open(chemin, encoding="utf-8") as fh:
            lignes = fh.read().split("\n")
    except OSError:
        raise ErreurOutil("fichier d'attendus illisible")
    for n, ligne in enumerate(lignes, 1):
        texte = ligne.strip()
        if not texte or texte.startswith("#"):
            continue
        champs = [c.strip() for c in texte.split("|", 4)]
        if len(champs) < 4 or champs[3] not in VALEURS_ATTENDU or (champs[0] not in GATES and champs[0] != "-"):
            raise ErreurOutil("fichier d'attendus : ligne %d invalide" % n)
        gate, nom_lab, rel, attendu = champs[:4]
        cibles = [l for l in labs if nom_lab in (l.affiche, l.arg)]
        for lab in cibles:
            entrees.append(normaliser(lab, gate, ("Write", rel, attendu, ""), RANG_ATTENDUS))
    return entrees


def fusionner(entrees):
    """UNE entrée gagnante par (lab, clé) : fichier d'attendus > constructeur de gate > générique ;
    doublons éliminés ; attendus contradictoires de même rang = erreur ; `doit-refuser` et
    `doit-refuser-modele` de même rang ne se contredisent pas (le plus précis l'emporte)."""
    groupes = {}
    for e in entrees:
        groupes.setdefault((e["lab"], e["clef"]), []).append(e)
    gagnants = []
    for cle, liste in groupes.items():
        rang = max(e["rang"] for e in liste)  # rejeu-priorite
        tete = [e for e in liste if e["rang"] == rang]
        valeurs = set(e["attendu"] for e in tete)
        if len(valeurs) > 1:
            if valeurs == {"doit-refuser", "doit-refuser-modele"}:
                gagnant = [e for e in tete if e["attendu"] == "doit-refuser-modele"][0]
            else:
                raise ErreurOutil("attendus contradictoires : " + montrer_clef(cle[1]))
        else:
            gagnant = tete[0]
        gagnants.append(gagnant)  # rejeu-doublon
    return gagnants


# --- Rejeu d'une écriture -------------------------------------------------------------------------
def payload(lab, outil, chemin, agent_type, charge=None):
    absolu = os.path.join(lab.copie, chemin) if chemin else lab.copie
    contenu = "x"
    if outil in ("Write", "Edit", "NotebookEdit") and os.path.isfile(absolu):
        try:
            with open(absolu, encoding="utf-8", errors="replace") as fh:
                contenu = fh.read(MAX_CONTENU)
        except OSError:
            contenu = "x"
    if outil in ("Agent", "Task"):
        entree = {"description": "d", "prompt": "p", "subagent_type": chemin}
    elif outil == "Bash":
        entree = {"command": chemin}
    elif outil == "NotebookEdit":
        entree = {"notebook_path": absolu, "new_source": contenu}
    elif outil == "Edit" and charge is not None:
        entree = dict(charge, file_path=absolu)
    elif outil == "Edit":
        entree = {"file_path": absolu, "old_string": "", "new_string": contenu}
    else:
        entree = {"file_path": absolu, "content": contenu}
    obj = {"session_id": "rejeu", "transcript_path": "transcript.jsonl", "cwd": lab.copie,
           "prompt_id": "rejeu", "permission_mode": "default"}
    if agent_type:
        obj["agent_id"] = "rejeu-agent"
        obj["agent_type"] = agent_type
    obj["hook_event_name"] = "PreToolUse"
    obj["tool_name"] = outil
    obj["tool_input"] = entree
    obj["tool_use_id"] = "toolu_rejeu"
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def jouer(hook_copie, env, lab, outil, chemin, agent_type, charge=None):
    """('passe'|'refus', raison) : un refus est un permissionDecision deny ; un code non nul ou une
    sortie illisible vaut refus (la commande enregistrée fermerait, P45-D-06)."""
    try:
        p = subprocess.run(["bash", hook_copie], input=payload(lab, outil, chemin, agent_type, charge),
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env, cwd=lab.copie,
                           timeout=DELAI_HOOK)
    except (subprocess.TimeoutExpired, OSError) as exc:
        return "refus", "hook injouable (" + type(exc).__name__ + ")"
    if p.returncode != 0:
        return "refus", "hook en erreur (code %d)" % p.returncode
    if p.stdout == b"":
        return "passe", "passe"
    try:
        s = json.loads(p.stdout.decode("utf-8"))["hookSpecificOutput"]
    except (ValueError, KeyError, TypeError):
        return "refus", "sortie du hook illisible"
    if isinstance(s, dict) and s.get("permissionDecision") == "deny":
        return "refus", str(s.get("permissionDecisionReason", ""))
    return "passe", "passe"


def classer(attendu, obtenu):
    if attendu == "doit-passer":
        return "faux-refus" if obtenu == "refus" else "conforme"  # rejeu-modele-inverse
    if attendu == "doit-refuser":
        return "conforme" if obtenu == "refus" else "faux-accept"
    return "refus-conforme-modele" if obtenu == "refus" else "faux-accept"  # rejeu-modele-compte


def gate_de_raison(raison):
    m = PREFIXE_GATE.match(raison or "")
    return m.group(1) if m else "?"


def assainir(texte, labs, tmp):
    for lab in labs:
        if lab.copie:
            texte = texte.replace(lab.copie, lab.affiche)
    texte = texte.replace(tmp, "<tmp>")
    home = os.environ.get("HOME") or ""
    if home:
        for h in {home, os.path.realpath(home)}:
            if h and h != "/":
                texte = texte.replace(h, "~")
    texte = texte.replace("\n", " ⏎ ").replace(" | ", " / ")
    return texte if len(texte) <= 240 else texte[:240] + "…"


def colonne_chemin(cle):
    outil, chemin, agent = cle
    suffixe = "" if (outil == "Write" and not agent) else " [" + outil + ("@" + agent if agent else "") + "]"
    return chemin + suffixe


def analyser(argv):
    opts = {"labs": [], "etape": None, "attendus": None, "rapport": None, "hook": None}
    for arg in argv:
        if arg.startswith("--lab="):
            if arg[6:] == "":
                raise Usage("--lab vide")
            opts["labs"].append(arg[6:])
        elif arg.startswith("--etape="):
            if arg[8:] not in ("1", "2", "3", "4"):
                raise Usage("--etape invalide : " + arg[8:] + " (attendu 1, 2, 3 ou 4)")
            opts["etape"] = int(arg[8:])
        elif arg.startswith("--attendus="):
            opts["attendus"] = arg[11:]
        elif arg.startswith("--rapport="):
            opts["rapport"] = arg[10:]
        elif arg.startswith("--hook="):
            opts["hook"] = arg[7:]
        else:
            raise Usage("argument inconnu : " + arg)
    if not opts["labs"]:
        raise Usage("au moins un --lab=<chemin> est requis")
    if opts["etape"] is None:
        raise Usage("--etape=<1|2|3|4> est requis")
    for champ in ("attendus", "rapport", "hook"):
        if opts[champ] == "":
            raise Usage("--" + champ + " vide")
    for arg in opts["labs"]:
        if not os.path.isdir(arg):
            raise Usage("lab introuvable (pas un dossier) : " + afficher(arg))
    return opts


def executer(opts, tmp):
    labs = [Lab(i, a) for i, a in enumerate(opts["labs"])]
    if opts["rapport"]:
        rap = os.path.realpath(opts["rapport"])
        for lab in labs:
            if rap == lab.reel or rap.startswith(lab.reel + os.sep):
                raise Usage("le rapport ne peut pas être écrit sous un lab : " + lab.affiche)
    hook_copie = os.path.join(tmp, "hook", "planning-hook.sh")
    os.makedirs(os.path.dirname(hook_copie))
    armer_copie(opts["hook"], hook_copie, opts["etape"])

    for lab in labs:
        lab.entrees = parcourir(lab.reel)
        empreinte_perimetre(lab, lab.entrees, os.path.join(tmp, "avant-%d.txt" % lab.index))
    for lab in labs:
        copier(lab, os.path.join(tmp, "copie-%d" % lab.index))
        simuler_adhesion(lab)

    entrees = []
    ordre = ["reecriture"] + [g for g in GATES if g in CONSTRUCTEURS] + \
        [g for g in sorted(CONSTRUCTEURS) if g != "reecriture" and g not in GATES]
    contexte = {"hook_copie": hook_copie, "tmp": tmp, "etape": opts["etape"]}
    for nom in ordre:
        rang = RANG_GENERIQUE if nom == "reecriture" else RANG_GATE
        for lab in labs:
            for brut in CONSTRUCTEURS[nom](lab, contexte):
                entrees.append(normaliser(lab, nom, brut, rang))
    if opts["attendus"]:
        entrees.extend(lire_attendus(opts["attendus"], labs))
    gagnants = fusionner(entrees)
    gagnants.sort(key=lambda e: (e["lab"], e["clef"]))

    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": os.environ.get("HOME", ""),
           "TMPDIR": tmp, "XDG_CACHE_HOME": os.path.join(tmp, "xdg")}
    os.makedirs(env["XDG_CACHE_HOME"], exist_ok=True)
    with ThreadPoolExecutor(max_workers=min(8, os.cpu_count() or 2)) as pool:
        verdicts = list(pool.map(lambda e: jouer(hook_copie, env, labs[e["lab"]], *e["clef"], e["charge"]), gagnants))

    comptes = {}
    lignes = []
    for gagnant, (obtenu, raison) in zip(gagnants, verdicts):
        lab = labs[gagnant["lab"]]
        gate = gagnant["gate"]
        if gate in ("reecriture", "-"):
            gate = gate_de_raison(raison) if obtenu == "refus" else "-"
        classe = classer(gagnant["attendu"], obtenu)
        if classe != "conforme":
            comptes.setdefault(gate, dict((c, 0) for c in COMPTES))
            comptes[gate][classe] += 1  # rejeu-compte
        motif = assainir(raison, labs, tmp)
        if classe == "refus-conforme-modele":
            motif = RAISON_MODELE
        if gagnant["origine"] == "regle-ecrite":
            motif = (motif + " ; " if motif and motif != "passe" else "") + RAISON_REGLE
        lignes.append(" | ".join([gate, lab.affiche, colonne_chemin(gagnant["clef"]), gagnant["attendu"], obtenu, motif]))

    gates_comptes = [g for lot in ORDRE_ETAPES[:opts["etape"]] for g in lot]
    gates_comptes += [g for g in GATES if g in CONSTRUCTEURS and g not in gates_comptes]
    gates_comptes += sorted(g for g in comptes if g not in gates_comptes and g != "-")
    totaux = dict((c, 0) for c in COMPTES)
    for gate in sorted(gates_comptes, key=lambda g: (GATES.index(g) if g in GATES else len(GATES), g)):
        c = comptes.get(gate, dict((k, 0) for k in COMPTES))
        lignes.append("COMPTE %s faux-refus=%d faux-accept=%d refus-conforme-modele=%d"
                      % (gate, c["faux-refus"], c["faux-accept"], c["refus-conforme-modele"]))
    for gate, c in comptes.items():
        for k in COMPTES:
            totaux[k] += c[k]
    lignes.append("REJEU-ETAPE-%d faux-refus=%d faux-accept=%d refus-conforme-modele=%d"
                  % (opts["etape"], totaux["faux-refus"], totaux["faux-accept"], totaux["refus-conforme-modele"]))
    for gate in [g for g in GATES if g in CONSTRUCTEURS and getattr(CONSTRUCTEURS[g], "classe_modele", False)]:
        for lab in labs:
            n = len([e for e in gagnants if e["lab"] == lab.index and e["gate"] == gate and e["origine"] == "regle-ecrite"])
            lignes.append("CLASSE-REGLE-ECRITE %s lab=%s n=%d" % (gate, lab.affiche, n))

    divergence = False
    for lab in labs:
        avant = os.path.join(tmp, "avant-%d.txt" % lab.index)
        apres = os.path.join(tmp, "apres-%d.txt" % lab.index)
        empreinte_perimetre(lab, parcourir(lab.reel), apres)
        identique = subprocess.run(["cmp", "-s", avant, apres]).returncode == 0  # rejeu-empreinte
        if identique:
            lignes.append("EMPREINTE-IDENTIQUE " + lab.affiche)
        else:
            divergence = True
            lignes.append("EMPREINTE-DIVERGENTE " + lab.affiche)

    texte = "\n".join(lignes) + "\n"
    sys.stdout.buffer.write(texte.encode("utf-8"))
    sys.stdout.flush()
    if opts["rapport"]:
        try:
            with open(opts["rapport"], "w", encoding="utf-8", newline="\n") as fh:
                fh.write(texte)
        except OSError as exc:
            raise ErreurOutil("rapport non écrit (" + type(exc).__name__ + ")")
    return 1 if divergence else 0


def main(argv):
    try:
        opts = analyser(argv)
    except Usage as exc:
        sys.stderr.write("[rejeu-gates] " + str(exc) + "\n")
        return 64
    tmp = os.path.realpath(tempfile.mkdtemp(prefix="vf-rejeu-"))
    try:
        return executer(opts, tmp)
    except Usage as exc:
        sys.stderr.write("[rejeu-gates] " + str(exc) + "\n")
        return 64
    except ErreurOutil as exc:
        sys.stderr.write("[rejeu-gates] " + str(exc) + "\n")
        return 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
PY_REJEU_GATES_EOF
