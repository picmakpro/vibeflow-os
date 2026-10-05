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
# l'armement des étapes ≤ --etape y est SIMULÉ sur une copie du hook. Ses seuls sous-processus : bash (le hook
# copié ; recalc-planning.sh --read-only sur la COPIE, pour l'état dérivé du constructeur G1) et cmp. Les chemins des labs réels ne
# vivent jamais dans ce fichier ni dans sa suite : ils sont des ARGUMENTS ; ce que les plans 45-05 à
# 45-09 rejouent le fait par `rejeu-reel.sh`, qui prend l'empreinte de TOUT l'arbre hors de cet outil.
#
# Usage :
#   rejeu-gates.sh --lab=<chemin> [--lab=<chemin>…] --etape=<1|2|3|4|5|6>
#                  [--attendus=<fichier>] [--rapport=<fichier>] [--hook=<script>]
#   --etape    étape d'armement simulée (P45-D-03, P46-D-11) : 1 = G6 et G5 ; 2 = + G1 ; 3 = + G7 ; 4 = + rôle ; 5 = + G3 et G4 ;
#              6 = + G4′ (G4P) ; l'armement simulé suit ORDRE_ETAPES (le hook copié) ; tout autre numéro est un usage refusé (64)
#   --hook     le hook à rejouer (défaut : planning-hook.sh à côté de ce script) ; toujours COPIÉ
#   --rapport  écrit aussi le relevé dans ce fichier (refusé s'il est sous un lab)
# Codes : 0 mesure faite (quels que soient les comptes), 1 erreur (lecture, empreinte divergente,
# motif d'armement non unique, attendus contradictoires, classification absente), 64 usage.
#
# Relevé (stdout, et --rapport) — lignes, dans cet ordre :
#   <gate> | <lab affiché> | <chemin> | <attendu> | <obtenu> | <raison>       une par écriture rejouée
#   COMPTE <gate> faux-refus=<n> faux-accept=<m> refus-conforme-modele=<k>     une par gate ; suivie du mot
#                                                                                `hors-etape` si le gate est d'une
#                                                                                étape > --etape (joué, imprimé,
#                                                                                jamais compté dans le total)
#   REJEU-ETAPE-<n> faux-refus=<N> faux-accept=<M> refus-conforme-modele=<K>   total des gates des étapes <= n ET des
#                                                                                lignes rangées sous aucune étape (`-`, `?`)
#   COUVERTURE-REJEU <G3|G4> n=<k> plancher=<p>                                (46-08) écritures réellement jouées par le
#                                                                                constructeur du gate et plancher exigé ; un
#                                                                                compte sous le plancher rend le code 1 : jamais
#                                                                                0 faux refus / 0 faux accept sans rien jouer
#   CLASSE-REGLE-ECRITE <gate> lab=<lab affiché> n=<j>                          gate qui classe d'après
#                                                                                le modèle, par lab
#   ROLE-AGENT lab=<lab affiché> agent=<nom> role=<rôle dérivé> ecriture=<attendu> dispatchs=<n>   une par agent rejoué
#                                                                                par le constructeur ROLE (45-09) ; rien sans agent
#   BORNE-LIVRABLES lab=<lab affiché> entree=<entrée> fichiers=<n> octets=<m>    (46-08) entrée réelle de premier niveau dont le
#                                                                                parcours dépasse 2000 entrées ou 128 Mio (mesure de
#                                                                                l'hypothèse A7, P46-D-03a) ; nommée, jamais agrégée
#   ENTREE-IGNOREE lab=<lab affiché> entree=<entrée> motif=<motif>               (46-08) entrée réelle que G3 et G4 ne rejouent pas
#                                                                                (nom non déclarable dans `ecrit:`, réservé, ou
#                                                                                squelette / verdict impossible) : dite, jamais tue
#   EMPREINTE-IDENTIQUE <lab affiché>   (ou EMPREINTE-DIVERGENTE + code 1)      une par lab
# Les chemins sous HOME sont affichés `~/…` ; les chemins internes sont relatifs au lab. Un lab HORS de HOME est affiché `<lab-N>`
# (jamais son chemin absolu), N étant son rang parmi les `--lab=` hors de HOME : il dépend de l'ORDRE des `--lab=` de l'appel — la même
# liste, dans le même ordre, redonne les mêmes noms ; un autre ordre les permute (lot C, F2). Pour les fichiers d'attendus, la colonne lab
# porte ce nom : l'écrire dans l'ordre des `--lab=` de la mesure.
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
# commentaires `#` ; une ligne dont le lab n'est pas dans cette mesure est ignorée. Pour le gate G7 (45-07) la colonne
# chemin est le dossier X (relatif au lab) où un `.planning/` est créé, et l'écriture rejouée est la CRÉATION de
# `X/.planning/config.json` (voir plus bas) ; la colonne se termine par le nom du dossier.
# Registre CONSTRUCTEURS (gate -> fonction(lab, ctx) qui rend des tuples (outil, chemin, attendu,
# agent_type[, origine[, charge[, branche[, situation]]]])) : `reecriture` (chaque fichier régulier des .planning/ copiés,
# attendu doit-passer) ; `G6` et `G5` (45-05 : fichiers générés, config.json, VERDICT.md ; G6 : aussi, Q-G6 = b, les scripts du hook
# présents sous `.claude/scripts/` de la racine adhérente) ; `G1` (45-06 : les
# PLAN.md de forme modèle, classés d'après l'état que recalc-planning.sh --read-only dérive sur la copie — `recalc-
# planning.sh` est cherché à côté de ce script — sinon d'après la règle écrite du modèle, `branche` nommant la
# règle appliquée ; des phases synthétiques 99-rejeu-* créées sur la copie) ; `G7` (45-07 : la CRÉATION de chaque
# `.planning/` imbriqué réel, attendu doit-passer, et celle d'un `.planning/` dans un dossier synthétique vide
# `rejeu-orphelin-g7/` sous chaque racine adhérente de la copie, attendu doit-refuser ; le dossier visé est mis de côté
# sur la copie, le hook est joué, le dossier est remis en place — UN payload à la fois, après les écritures parallèles ;
# une copie qui n'est pas identique avant et après est une erreur de l'outil) ; `ROLE` (45-09 : les définitions d'agents de la
# racine de chaque lab adhérent, classées par `planning-hook.sh --classer` sur la copie du hook ; légitimité mesurée sur les
# déclarations de l'agent, limite déclarée sous F9 = f9-allowlist, voir `construire_role`).
# Une écriture de création porte la situation `creation` : sa ligne du relevé se termine par ` [création]` et elle ne se
# fond jamais avec la réécriture en place du même chemin. `charge` (dict) remplace le tool_input d'un Edit (old_string, new_string,
# replace_all) : l'Edit de config.json qui perd l'adhésion a une clé (outil Edit) distincte de celle de
# la réécriture Write du même fichier. Un constructeur qui classe d'après le modèle porte
# l'attribut `classe_modele` ; il est TOTAL (P45-D-21c) : une écriture sans attendu, ou hors des
# trois valeurs, est une erreur — jamais un doit-passer implicite. `origine` = `regle-ecrite` marque
# une classification par la règle écrite du modèle faute d'état dérivé.
# Les constructeurs de TOUS les gates sont joués quelle que soit --etape : l'étape ne décide que de
# l'armement de la copie du hook et du COMPTAGE (un gate d'étape > --etape est simulé en observe : son
# `doit-refuser` obtient un passage, qui n'est pas un faux accept de l'étape mesurée). EXCEPTION (46-08) : les constructeurs
# `G3` et `G4` (étape 5) sont coûteux (unités synthétiques, une pose de verdict par `poser-verdict.sh`)
# et ne se jouent qu'à partir de l'étape de leur gate : un rejeu --etape=n d'une étape antérieure ne les construit pas, et leur couverture
# minimale (COUVERTURE-REJEU) n'est exigée qu'à partir de cette étape. `G3` (46-08 ; P46-D-01, P46-D-12) : sur la COPIE, des unités synthétiques de
# forme modèle sous `.planning/cycles/99-rejeu-cloture/phases/` dont `ecrit:` désigne des entrées RÉELLES de premier niveau du lab (squelette
# reflété sur la copie, le contenu réel n'est jamais lu) et des cas synthétiques à attendu nominatif ; l'attendu d'une entrée réelle vient
# d'un oracle de présence PROPRE au rejeu (lstat, aucun lien suivi), jamais du prédicat du hook. `G4` : mêmes unités, `SUMMARY.md`, verdicts posés par
# la vraie `poser-verdict.sh`.
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
exec $PY_INVOKE -I -S - "$SCRIPT_DIR_SELF" "$@" <<'PY_REJEU_GATES_EOF'
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

GATES = ("G6", "G5", "G1", "G7", "ROLE", "G3", "G4", "G4P")
ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",), ("G3", "G4"), ("G4P",))
ETAPE_DE = dict((g, i + 1) for i, lot in enumerate(ORDRE_ETAPES) for g in lot)
ELAGAGE = ("node_modules", ".git", ".venv", "__pycache__")
MARQUEURS_CODE = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle",
                  "build.gradle.kts", "composer.json", "Gemfile", "tsconfig.json", "Package.swift")
SCHEMA_ADHESION = "cycles-v1"
VALEURS_ATTENDU = ("doit-passer", "doit-refuser", "doit-refuser-modele")
ORIGINES = ("etat-derive", "regle-ecrite")
COMPTES = ("faux-refus", "faux-accept", "refus-conforme-modele")
RANG_ATTENDUS, RANG_GATE, RANG_GENERIQUE = 3, 2, 1
SITUATIONS = ("", "creation")
SYNTH_ORPHELIN_G7 = "rejeu-orphelin-g7"
RAISON_MODELE = "refus conforme au modèle, lab non migré"
RAISON_REGLE = "classé par la règle écrite, état dérivé absent"
MAX_CONTENU = 1 << 20
DELAI_HOOK = 120
ETAPE_G3G4 = 5  # étape à partir de laquelle les constructeurs G3 et G4 se jouent (constantes du rejeu : elles ne dérivent pas de ORDRE_ETAPES)
PREFIXE_GATE = re.compile(r"^\[planning-core\] ([A-Z0-9]+) : ")


class Usage(Exception):
    """Argument invalide : code 64."""


class ErreurOutil(Exception):
    """Erreur de mesure (lecture, armement, attendus, classification) : code 1."""


# --- Affichage : jamais un chemin de machine dans un relevé --------------------------------------
GENERIQUES = {}


def neutraliser(texte):
    """Aucun caractère de contrôle (LF, CR, ESC…) dans une ligne imprimée : `\\xNN`. Un nom de fichier ne forge pas de ligne du relevé."""
    return "".join(c if (c >= " " and c != "\x7f") else "\\x%02x" % ord(c) for c in texte)  # rejeu-neutraliser


def afficher(chemin):
    """Jamais un chemin absolu de machine : `~/…` sous HOME, sinon un nom générique `<lab-N>` dans l'ordre des labs (quick 45-B, B2)."""
    p = os.path.realpath(chemin)
    home = os.environ.get("HOME") or ""
    if home:
        h = os.path.realpath(home)
        if p == h:
            return "~"
        if p.startswith(h + os.sep):
            return neutraliser("~/" + p[len(h) + 1:])  # rejeu-affichage
    return GENERIQUES.setdefault(p, "<lab-%d>" % (len(GENERIQUES) + 1))  # rejeu-generique


def sous_un_lab(chemin, reel):
    """Vrai si `chemin` est le lab `reel` ou se trouve dessous : chaînes ET identité de fichier de chaque ancêtre existant
    (système de fichiers insensible à la casse : `/x/LAB` et `/x/lab` sont le même dossier sans que les chaînes le disent)."""
    p = os.path.abspath(chemin)
    r = os.path.realpath(chemin)
    if r == reel or r.startswith(reel + os.sep):
        return True
    while True:
        try:
            if os.path.exists(p) and os.path.samefile(p, reel):
                return True
        except OSError:
            pass
        parent = os.path.dirname(p)
        if parent == p:
            return False
        p = parent


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


def sous_copie(lab, chemin):
    """Garde H3 (quick 45-B, décisions du manager vf-dev-manager, 2026-10-01) : `chemin` doit se RÉSOUDRE sous la copie du lab.
    La copie recrée chaque lien avec sa cible d'origine : un lien à cible absolue (ou remontant) ferait écrire ou lire HORS de
    la copie, donc dans le lab réel ou ailleurs. Appelée avant tout makedirs, open en écriture, rename ou lecture d'un chemin
    qui peut traverser un lien ; erreur de l'outil (code 1), jamais un repli silencieux."""
    base = os.path.realpath(lab.copie)
    r = os.path.realpath(chemin)
    if not (r == base or r.startswith(base + os.sep)):  # rejeu-garde-lien
        raise ErreurOutil("lien symbolique dont la cible sort du lab : " + os.path.relpath(os.path.abspath(chemin), os.path.abspath(lab.copie)) + " (rien n'a été écrit hors de la copie)")


def lire_regulier(lab, chemin, limite):
    """Contenu texte d'un fichier RÉGULIER de la copie (lstat, aucun suivi de lien, cible résolue sous la copie) ; None sinon."""
    try:
        if not stat.S_ISREG(os.lstat(chemin).st_mode):  # rejeu-lecture-regulier
            return None
        sous_copie(lab, chemin)
        with open(chemin, encoding="utf-8", errors="replace") as fh:
            return fh.read(limite)
    except (OSError, ErreurOutil):
        return None


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
        sous_copie(lab, os.path.dirname(cible))
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
# Q-G6 = (b) (Willy, AskUserQuestion session principale, 2026-10-01) : les scripts du hook posés par l'installeur sous `.claude/scripts/`
# de la RACINE d'un lab adhérent sont protégés par G6 ; le relevé les joue quand le lab copié les porte (fichier régulier) — un lab
# qui n'a pas installé le hook en scope projet n'en a aucun à garder. Les réglages `.claude/settings*.json` ne le sont pas (limite (y)).
SCRIPTS_G6 = ("planning-hook.sh", "check-gates-alive.sh")
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
    if ".planning" in lab.dossiers_planning:  # rejeu-scripts-g6
        for nom in SCRIPTS_G6:
            rel = ".claude/scripts/" + nom
            if (rel, "f") in lab.entrees:
                sortie.append(("Write", rel, "doit-refuser", ""))
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


# --- Règle écrite du modèle pour G1 : lecture de CADRAGE.md par le code PROPRE de l'outil (45-06) -------------
# Copies ast-identiques de dequote, CLE_RE, lire_frontmatter, _lire_liste_indentee et lire_registre du moteur de
# recalcul (la suite compare les arbres) : l'outil ne lit jamais le CADRAGE.md d'une autre façon que le modèle, et ne
# s'appuie jamais sur le hook pour classer.
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


# --- G1 (45-06, GATE-06, P45-D-21a, P45-D-21c) : pas de plan sans cadrage --------------------------------------
# Le constructeur classe d'après le MODÈLE, jamais d'après le verdict du hook : l'état que `recalc-planning.sh
# --read-only` dérive sur la copie s'il existe pour la phase, sinon — quelle qu'en soit la cause — la règle écrite du
# modèle (`regle_ecrite`), appliquée par le code propre de l'outil. La classification est TOTALE : pour tout PLAN.md de
# la forme que vise G1, UN attendu, `doit-passer` ou `doit-refuser-modele`, jamais aucun, jamais un doit-passer faute
# d'état. Il ne lance jamais le hook ni une fonction du hook.
DOSSIER_SCRIPTS = None  # posé par le lanceur shell (dossier de rejeu-gates.sh) : recalc-planning.sh vit à côté
NOM_UNITE = re.compile(r"^[0-9]{2,}-[\w.-]+$")  # le nom d'unité du modèle (cycle, phase, plan)
SYNTH_CYCLE = "99-rejeu"
SYNTH_SANS = "99-rejeu-sans-cadrage"
SYNTH_OUVERT = "99-rejeu-registre-ouvert"
CADRAGE_OUVERT = '---\ninconnues:\n  - id: I-99\n    question: "Q ?"\n    structurante: oui\n---\n'


def forme_g1(rel):
    """Chemin (relatif au lab) du dossier de la PHASE si `rel` est un PLAN.md de la forme que vise G1 —
    `<…>/.planning/cycles/<cycle>/phases/<phase>/PLAN.md` ou `…/phases/<phase>/plans/<plan>/PLAN.md`, chaque nom
    d'unité conforme à NOM_UNITE, les noms fixes comparés en casefold — sinon None."""
    p = rel.split("/")
    for n in (6, 8):
        if len(p) < n:
            continue
        q = p[-n:]
        if q[0] != ".planning" or q[1].casefold() != "cycles" or q[3].casefold() != "phases" or q[-1].casefold() != "plan.md":
            continue
        if n == 8 and q[5].casefold() != "plans":
            continue
        unites = [q[2], q[4]] + ([q[6]] if n == 8 else [])
        if not all(NOM_UNITE.match(u) for u in unites):  # g1-forme
            continue
        return "/".join(p[:-n] + q[:5])
    return None


def regle_ecrite(copie, rel):
    """(attendu, branche) selon la RÈGLE ÉCRITE du modèle (modele-cycles.md, spec §5), sur la lecture propre de la copie
    (lstat de CADRAGE.md). Fonction totale à branches NOMMÉES, évaluées dans cet ordre, sans branche par défaut : un
    cas qu'aucune ne reconnaît est une erreur de l'outil, jamais un doit-passer."""
    phase = forme_g1(rel)
    if phase is None:
        return ("doit-passer", "hors-forme")  # GATE-06 ne vise pas ce chemin
    cadrage = os.path.join(copie, phase, "CADRAGE.md")
    try:
        mode = os.lstat(cadrage).st_mode
    except FileNotFoundError:
        return ("doit-refuser-modele", "pas-de-cadrage")  # même si un AUTRE fichier de la phase est non régulier
    except OSError:
        raise ErreurOutil("classification impossible : " + rel + " (lecture de CADRAGE.md)")
    if not stat.S_ISREG(mode):
        return ("doit-passer", "non-regulier")  # g1-nonreg : f5-etats, dossier, lien ou autre type, état indéterminé
    try:
        with open(cadrage, encoding="utf-8") as fh:
            statut, donnees = lire_frontmatter(fh.read())
    except (OSError, UnicodeDecodeError):
        return ("doit-passer", "illisible")
    if statut != "ok":
        return ("doit-passer", "illisible")
    if "inconnues" not in donnees:
        return ("doit-passer", "herite")  # g1-herite : format hérité, sans clé inconnues:
    registre_ok, clos = lire_registre(donnees)
    if not registre_ok:
        return ("doit-passer", "illisible")
    ouvert = not clos  # g1-clos : toute ligne structurante: oui sans statut ; `inconnues: []` est clos
    if ouvert:
        return ("doit-refuser-modele", "registre-ouvert")
    if clos:
        return ("doit-passer", "clos")
    raise ErreurOutil("classification impossible : " + rel)


def exploitable(etat, raison):
    """Un état dérivé fait référence, défini par le COUPLE (état, raison) : tout état autre que `indéterminé`, et, sous
    `indéterminé`, les seules raisons de Φ2 à Φ4 (CADRAGE.md y a passé Φ1, son contenu est lu par le modèle)."""
    if etat != "indéterminé":
        return True
    r = raison or ""
    return r.startswith("hors-cadrage:") or r.startswith("avant-cadrage-clos:") or r == "registre-invalide" \
        or r == "frontmatter-invalide:CADRAGE.md"


def attendu_derive(etat, raison):
    """Attendu d'un état dérivé exploitable : à cadrer, hors-cadrage:*, en cadrage, avant-cadrage-clos:* sont interdits
    par le modèle (lab non migré) ; registre-invalide, frontmatter-invalide:CADRAGE.md et tout état cadré passent."""
    r = raison or ""
    if etat in ("à cadrer", "en cadrage") or r.startswith("hors-cadrage:") or r.startswith("avant-cadrage-clos:"):
        return "doit-refuser-modele"
    return "doit-passer"


def chemin_recalc():
    if not DOSSIER_SCRIPTS:
        raise ErreurOutil("recalc-planning.sh introuvable : dossier des scripts inconnu")
    chemin = os.path.join(DOSSIER_SCRIPTS, "recalc-planning.sh")
    if not os.path.isfile(chemin):
        raise ErreurOutil("recalc-planning.sh introuvable à côté de rejeu-gates.sh")
    return chemin


def etats_derives(lab, planning):
    """{chemin de phase relatif au lab: (état, raison)} rendus par recalc-planning.sh --read-only sur la COPIE ; vide si
    le moteur ne rend rien d'exploitable (la règle écrite prend alors le relais, quelle qu'en soit la cause)."""
    recalc = chemin_recalc()
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": os.environ.get("HOME", "")}
    try:
        p = subprocess.run(["bash", recalc, "--planning=" + os.path.join(lab.copie, planning), "--read-only"],
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env, timeout=DELAI_HOOK)
        donnees = json.loads(p.stdout.decode("utf-8"))
        cycles = donnees.get("cycles", [])
        return dict((planning + "/" + ph["chemin"], (ph["etat"], ph.get("raison"))) for c in cycles for ph in c.get("phases", []))
    except (subprocess.TimeoutExpired, OSError, ValueError, KeyError, TypeError, AttributeError):
        return {}


def phases_synthetiques(lab, planning):
    """Écritures `doit-refuser` (le modèle les interdit pour tout lab) dans des phases synthétiques créées sur la COPIE :
    une sans CADRAGE.md, une à registre ouvert, sous chaque cycle réel (ou sous le cycle synthétique 99-rejeu)."""
    base = os.path.join(lab.copie, planning, "cycles")
    sous_copie(lab, base)
    cycles = []
    try:
        for nom in sorted(os.listdir(base)):
            if NOM_UNITE.match(nom) and stat.S_ISDIR(os.lstat(os.path.join(base, nom)).st_mode):
                cycles.append(nom)
    except OSError:
        cycles = []
    if not cycles:
        cycles = [SYNTH_CYCLE]
    sortie = []
    for cycle in cycles:
        for phase, cadrage in ((SYNTH_SANS, None), (SYNTH_OUVERT, CADRAGE_OUVERT)):
            dossier = os.path.join(base, cycle, "phases", phase)
            sous_copie(lab, dossier)
            try:
                os.makedirs(dossier, exist_ok=True)
                if cadrage is not None:
                    sous_copie(lab, os.path.join(dossier, "CADRAGE.md"))
                    with open(os.path.join(dossier, "CADRAGE.md"), "w", encoding="utf-8", newline="\n") as fh:
                        fh.write(cadrage)
            except OSError:
                continue
            sortie.append(("Write", planning + "/cycles/" + cycle + "/phases/" + phase + "/PLAN.md", "doit-refuser", ""))
    return sortie


def construire_g1(lab, ctx):
    """G1 : la réécriture de chaque PLAN.md réel de forme modèle (attendu du modèle : état dérivé, sinon règle écrite) et les
    phases synthétiques que le modèle interdit pour tout lab."""
    sortie, vus = [], set()
    for planning in lab.dossiers_planning:
        derives = etats_derives(lab, planning)
        for rel in sorted(r for r in lab.fichiers_planning if r.startswith(planning + "/") and r not in vus):
            phase = forme_g1(rel)
            if phase is None:
                continue  # hors de la forme visée : la ligne du relevé vient de la réécriture générique
            vus.add(rel)
            etat = derives.get(phase)
            if etat is not None and exploitable(*etat):
                attendu = attendu_derive(*etat)  # g1-derive
                sortie.append(("Write", rel, attendu, "", "etat-derive"))
            else:
                attendu, branche = regle_ecrite(lab.copie, rel)
                sortie.append(("Write", rel, attendu, "", "regle-ecrite", None, branche))  # g1-regle
        sortie.extend(phases_synthetiques(lab, planning))
    return sortie


construire_g1.classe_modele = True


# --- G7 (45-07, GATE-07, P45-D-14) : pas de planning orphelin sous un lab adhérent ----------------------------------
def construire_g7(lab, ctx):
    """G7 : la CRÉATION de `config.json` dans chaque `.planning/` imbriqué réel (doit-passer par défaut : le fichier d'attendus
    le reclasse, P45-D-21a) et la création d'un `.planning/` dans un dossier synthétique vide `rejeu-orphelin-g7/` sous
    chaque racine adhérente de la copie (doit-refuser : le modèle l'interdit pour tout lab). Écritures de situation
    `creation` : le dossier de planning visé est mis de côté au moment du jeu (`jouer_creation`). La racine du lab n'est pas
    un `.planning/` imbriqué."""
    sortie = []
    for planning in lab.dossiers_planning:
        parent = os.path.dirname(planning)
        if parent:
            sortie.append(("Write", planning + "/config.json", "doit-passer", "", "etat-derive", None, None, "creation"))
        synth = (parent + "/" if parent else "") + SYNTH_ORPHELIN_G7
        sous_copie(lab, os.path.join(lab.copie, synth))
        try:
            os.makedirs(os.path.join(lab.copie, synth), exist_ok=True)
        except OSError:
            continue
        sortie.append(("Write", synth + "/.planning/config.json", "doit-refuser", "", "etat-derive", None, None, "creation"))
    return sortie


# --- Rôle (45-09, GATE-09, P45-D-21, F9 = f9-allowlist) : le hook par rôle sur les définitions d'agents du lab ------------
# Pour chaque définition `.claude/agents/*.md` (fichier régulier, non caché) de la RACINE d'un lab copié dont le .planning/ est
# adhérent, `planning-hook.sh --classer` (la copie du hook rejoué) donne allowlist et disallowed. La légitimité se mesure sur les
# DÉCLARATIONS de l'agent, jamais sur son rôle : une écriture d'un agent qui retire Write ET Edit est `doit-refuser`, toute autre
# `doit-passer` ; un dispatch d'un nom de SA propre allowlist est `doit-passer` ; le dispatch de `hors-liste-rejeu` par un worker
# (vf-internal: true) est `doit-refuser`, sous `Agent` et sous `Task`. LIMITE DÉCLARÉE : sous F9 = f9-allowlist (Willy,
# AskUserQuestion session principale, 2026-09-30) ce prédicat (le dispatch appartient à l'allowlist de l'appelant) est celui de la
# politique du hook pour la ligne worker : la mesure n'y est PAS indépendante, elle prouve la concordance de deux implémentations ;
# la ligne juge, jugée sur disallowedTools, l'est. Ce constructeur ne pose jamais `doit-refuser-modele` : les déclarations d'un agent
# valent pour tout lab. Deux définitions du même nom normalisé de rôles différents : l'agent est inconnu du hook (P45-D-11), son
# écriture est `doit-passer` et aucun dispatch n'est rejoué. Un agent `.md` en lien symbolique n'est pas une définition (A1 de la 42).
DOSSIER_ROLE = "rejeu-role"
HORS_LISTE_ROLE = "hors-liste-rejeu"
NOM_SUR = re.compile(r"[^A-Za-z0-9._-]")


def normaliser_nom(nom):
    """Comparaison de noms d'agents (P45-D-09), écrite ICI : l'outil ne réutilise aucune fonction du hook."""
    return nom.casefold().replace("_", "-").replace(" ", "-")


def nom_de_definition(texte, repli):
    """`name:` du frontmatter (dé-quoté ; le dernier l'emporte), à défaut le nom de fichier sans `.md`."""
    lignes = texte.split("\n")
    if not lignes or lignes[0].strip() != "---":
        return repli
    nom = None
    for ligne in lignes[1:]:
        if ligne.strip() == "---":
            break
        m = re.match(r"^name:(.*)$", ligne)
        if m:
            valeur = m.group(1).strip()
            if len(valeur) >= 2 and valeur[0] == valeur[-1] and valeur[0] in ("'", '"'):
                valeur = valeur[1:-1]
            nom = valeur
    return nom if isinstance(nom, str) and nom else repli


def classer_definition(hook_copie, chemin):
    """{role, allowlist, disallowed} rendus par `planning-hook.sh --classer <agent.md>` sur la COPIE du hook."""
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": os.environ.get("HOME", "")}
    try:
        p = subprocess.run(["bash", hook_copie, "--classer", chemin], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, env=env, timeout=DELAI_HOOK)
        donnees = json.loads(p.stdout.decode("utf-8"))
    except (subprocess.TimeoutExpired, OSError, ValueError):
        raise ErreurOutil("--classer injouable : " + os.path.basename(chemin))
    if p.returncode != 0 or not isinstance(donnees, dict) or not isinstance(donnees.get("role"), str) \
            or not isinstance(donnees.get("allowlist"), list) or not isinstance(donnees.get("disallowed"), list):
        raise ErreurOutil("--classer : réponse inattendue pour " + os.path.basename(chemin))
    return donnees


def definitions_racine(lab):
    """[(nom, classe)] des définitions régulières de `<copie>/.claude/agents/*.md`, triées par nom de fichier."""
    dossier = os.path.join(lab.copie, ".claude", "agents")
    if os.path.lexists(dossier):
        sous_copie(lab, dossier)  # rejeu-agents-lien : .claude ou agents en lien vers l'extérieur, jamais lu (quick 45-B, H3)
    try:
        noms = sorted(os.listdir(dossier))
    except OSError:
        return []
    res = []
    for fichier in noms:
        chemin = os.path.join(dossier, fichier)
        if not fichier.endswith(".md") or fichier.startswith("."):
            continue
        try:
            if not stat.S_ISREG(os.lstat(chemin).st_mode):
                continue  # un lien symbolique n'est jamais une définition
            with open(chemin, encoding="utf-8-sig") as fh:
                texte = fh.read()
        except (OSError, UnicodeDecodeError):
            continue
        res.append((nom_de_definition(texte, fichier[:-3]), chemin))
    return res


def construire_role(lab, ctx):
    """ROLE : pour chaque agent de la racine du lab, l'écriture d'un livrable neutre `rejeu-role/<agent>.md` sous son agent_type
    (doit-refuser s'il retire Write ET Edit, sinon doit-passer), un dispatch de chaque nom de son allowlist sous `Agent`
    (doit-passer) et, pour un worker, le dispatch de `hors-liste-rejeu` sous `Agent` et sous `Task` (doit-refuser). Rien n'est
    rejoué si le .planning/ de la racine n'existe pas (le lab dev reste silencieux, P45-D-04)."""
    if ".planning" not in lab.dossiers_planning:
        return []
    groupes = {}
    for nom, chemin in definitions_racine(lab):
        groupes.setdefault(normaliser_nom(nom), []).append((nom, chemin, classer_definition(ctx["hook_copie"], chemin)))
    sortie = []
    for _cle, membres in sorted(groupes.items()):
        nom, _chemin, classe = membres[0]
        roles = set(m[2]["role"] for m in membres)
        ecriture = DOSSIER_ROLE + "/" + NOM_SUR.sub("_", nom) + ".md"
        if len(roles) > 1:  # rôles contradictoires : agent inconnu du hook, jamais refusé (P45-D-11)
            sortie.append(("Write", ecriture, "doit-passer", nom))
            ctx["notes"].append("ROLE-AGENT lab=%s agent=%s role=ambigu ecriture=doit-passer dispatchs=0" % (lab.affiche, NOM_SUR.sub("_", nom)))
            continue
        interdits = classe["disallowed"]
        ecriture_refusee = "Write" in interdits and "Edit" in interdits  # la légitimité d'une écriture : les déclarations
        sortie.append(("Write", ecriture, "doit-refuser" if ecriture_refusee else "doit-passer", nom))
        dispatchs = []
        for sous in classe["allowlist"]:
            if isinstance(sous, str) and sous != "" and sous not in dispatchs:
                dispatchs.append(sous)
        for sous in dispatchs:
            sortie.append(("Agent", sous, "doit-passer", nom))  # role-legitime : le dispatch appartient à l'allowlist de l'appelant
        if classe["role"] == "worker":
            sortie.append(("Agent", HORS_LISTE_ROLE, "doit-refuser", nom))
            sortie.append(("Task", HORS_LISTE_ROLE, "doit-refuser", nom))
        ctx["notes"].append("ROLE-AGENT lab=%s agent=%s role=%s ecriture=%s dispatchs=%d"
                            % (lab.affiche, NOM_SUR.sub("_", nom), classe["role"], "doit-refuser" if ecriture_refusee else "doit-passer", len(dispatchs)))
    return sortie


# --- G3 et G4 (46-08, CLOT-10 ; P46-D-01, P46-D-03, P46-D-03a, P46-D-11, P46-D-12) : clôture sans livrable, SUMMARY.md sans verdict ---------------------
# Un constructeur qui ne parcourt que le réel rendrait « 0 faux refus / 0 faux accept » sans rien jouer : les labs réels n'ont ni VERDICT.md ni unité
# `cycles/` au format modèle (46-RESEARCH, Pitfall « rejeu à vide »). Ce constructeur FABRIQUE donc, sur la COPIE seulement (`sous_copie` avant toute
# écriture), des unités de forme modèle sous `.planning/cycles/99-rejeu-cloture/phases/<NN>-<slug>/` (PLAN.md à `ecrit:`, CADRAGE.md clos pour que G1
# ne s'en mêle pas) : (a) des cas synthétiques à attendu NOMINATIF (livrable présent, absent, vide, lien, dossier réduit à un `.DS_Store` ; pour G4 :
# verdict conforme posé par la VRAIE `poser-verdict.sh`, absent, en échec, périmé par le plan, périmé par le livrable, invalide) ; (b) une unité par
# entrée RÉELLE de premier niveau du lab (non cachée, au plus MAX_ENTREES_REELLES, triées) dont `ecrit:` la désigne : un SQUELETTE de l'entrée est
# reflété sur la copie (même arborescence, un octet par fichier non vide, jamais le contenu réel ; un substitut de dimension pour une entrée hors
# borne). L'attendu d'une entrée réelle vient d'un ORACLE de présence propre au rejeu (`oracle_presence` : lstat par composant, un lien vaut absent,
# aucun lien suivi), jamais du prédicat du hook (T-46-082). Les CLOTURE.md et SUMMARY.md réels de style GSD sont rejoués en doit-passer par la
# réécriture générique : seule la forme `.planning/cycles/<c>/phases/<p>[/plans/<pl>]/` est visée par G3 et G4.
CYCLE_G34 = "99-rejeu-cloture"
DOSSIER_LIVRABLES_G34 = "rejeu-livrables-g34"
BORNE_FICHIERS_G34, BORNE_OCTETS_G34 = 2000, 134217728  # P46-D-03a : valeurs PROPRES du rejeu, comparées à celles du hook par la mesure (hypothèse A7)
MESURE_PLAFOND_G34 = 200000  # au-delà, le comptage d'une entrée réelle s'arrête et le relevé le dit (mesure tronquée)
EXCLUS_LIVRABLES_G34 = (".DS_Store", "Thumbs.db", "desktop.ini")
MAX_ENTREES_REELLES = 50
PLANCHER_G34 = 6  # écritures minimales jouées : par lab adhérent pour G3 et G4
CADRAGE_CLOS_G34 = "---\ninconnues: []\n---\n"


def nom_lisible(nom):
    """Vrai si un nom d'entrée se décode en UTF-8 et ne porte aucun caractère de contrôle (sinon le texte d'une empreinte serait ambigu)."""
    try:
        nom.encode("utf-8")
    except UnicodeEncodeError:
        return False
    return not any(ord(c) < 0x20 or ord(c) == 0x7f for c in nom)


def oracle_presence(chemin):
    """ORACLE de présence d'un livrable réel, PROPRE au rejeu (T-46-082) : (statut, entrées, octets, tronqué), statut `present`, `absent`, `vide`,
    `lien`, `borne` ou `illisible`. lstat sur l'entrée, un lien (terminal) vaut `lien` et n'est jamais suivi ; un fichier régulier de taille non
    nulle est `present` ; un dossier est `present` s'il porte au moins un fichier régulier non vide hors `.DS_Store`, `Thumbs.db`, `desktop.ini`,
    parcours itératif sans suivi de lien. Les entrées comptent fichiers, sous-dossiers et liens (le budget que le hook borne) ; au-delà de
    BORNE_FICHIERS_G34 entrées ou BORNE_OCTETS_G34 octets : `borne`. Aucun contenu n'est lu."""
    try:
        st = os.lstat(chemin)  # rejeu-oracle-presence
    except FileNotFoundError:
        return ("absent", 0, 0, False)
    except OSError:
        return ("illisible", 0, 0, False)
    if stat.S_ISLNK(st.st_mode):
        return ("lien", 0, 0, False)
    if stat.S_ISREG(st.st_mode):
        statut = "borne" if st.st_size > BORNE_OCTETS_G34 else ("present" if st.st_size > 0 else "vide")
        return (statut, 1, st.st_size, False)
    if not stat.S_ISDIR(st.st_mode):
        return ("absent", 0, 0, False)
    entrees = octets = 0
    non_vide = illisible = tronque = False
    pile = [chemin]
    while pile:
        courant = pile.pop()
        try:
            with os.scandir(courant) as it:
                for e in it:
                    if e.name in EXCLUS_LIVRABLES_G34:
                        continue
                    if not nom_lisible(e.name):
                        illisible = True
                        continue
                    entrees += 1
                    try:
                        info = e.stat(follow_symlinks=False)
                    except OSError:
                        illisible = True
                        continue
                    if stat.S_ISREG(info.st_mode):
                        octets += info.st_size
                        non_vide = non_vide or info.st_size > 0
                    elif stat.S_ISDIR(info.st_mode):
                        pile.append(e.path)
                    if entrees >= MESURE_PLAFOND_G34:
                        tronque = True
                        pile = []
                        break
        except OSError:
            illisible = True
    if entrees > BORNE_FICHIERS_G34 or octets > BORNE_OCTETS_G34:
        statut = "borne"
    elif illisible:
        statut = "illisible"
    else:
        statut = "present" if non_vide else "vide"
    return (statut, entrees, octets, tronque)


def entree_declarable(nom):
    """Vrai si le nom d'une entrée peut figurer dans `ecrit:` (même contrainte que le modèle : un chemin concret relatif, sans `~` initial, sans
    caractère de contrôle ni `\\`, sans métacaractère `*?[]{}<>`) ET se citer entre guillemets simples ou doubles dans un frontmatter."""
    if nom == "" or nom.startswith("~") or nom in (".", ".."):
        return False
    if any(ord(c) < 0x20 or ord(c) == 0x7f for c in nom) or "\\" in nom or any(c in nom for c in "*?[]{}<>"):
        return False
    return not ('"' in nom and "'" in nom) and nom_lisible(nom)


def citer(nom):
    return "'" + nom + "'" if '"' in nom else '"' + nom + '"'


def ecrire_copie(lab, chemin, contenu):
    """Écrit `contenu` (texte) dans `chemin`, sous la copie (`sous_copie` avant l'écriture) ; erreur de l'outil si l'écriture échoue."""
    sous_copie(lab, os.path.dirname(chemin))
    try:
        os.makedirs(os.path.dirname(chemin), exist_ok=True)
        with open(chemin, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(contenu)
    except OSError as exc:
        raise ErreurOutil("écriture impossible sur la copie : " + os.path.relpath(chemin, lab.copie) + " (" + type(exc).__name__ + ")")


def creer_unite_g34(lab, nom_unite, entree):
    """Unité de forme modèle `99-rejeu-cloture/phases/<nom_unite>` sur la copie : CADRAGE.md clos et PLAN.md dont `ecrit:` désigne `entree`.
    Rend (chemin relatif de l'unité, chemin absolu)."""
    rel = ".planning/cycles/" + CYCLE_G34 + "/phases/" + nom_unite
    dossier = os.path.join(lab.copie, rel)
    sous_copie(lab, dossier)
    if os.path.lexists(dossier):
        raise ErreurOutil("unité de rejeu déjà présente sur la copie : " + rel)
    ecrire_copie(lab, os.path.join(dossier, "CADRAGE.md"), CADRAGE_CLOS_G34)
    ecrire_copie(lab, os.path.join(dossier, "PLAN.md"), "---\necrit:\n  - " + citer(entree) + "\n---\n\n# Plan de rejeu\n")
    return rel, dossier


def poser_verdict_copie(lab, ctx, unite, constat, obligatoire=True):
    """Pose un VERDICT.md sur l'unité `unite` (chemin absolu, copie) par la VRAIE `poser-verdict.sh` (le SEUL chemin légitime, G5). Rend None si
    posé ; sinon la sortie d'erreur (une erreur de l'outil quand `obligatoire`)."""
    poser = os.path.join(DOSSIER_SCRIPTS or "", "poser-verdict.sh")
    if not os.path.isfile(poser):
        raise ErreurOutil("poser-verdict.sh introuvable à côté de rejeu-gates.sh")
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": os.environ.get("HOME", ""), "TMPDIR": ctx["tmp"]}
    try:
        p = subprocess.run(["bash", poser, "--unite=" + unite, "--juge=rejeu", "--tentative=1", "--score=rejeu", "--constat=rejeu::" + constat],
                           stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env, timeout=DELAI_HOOK)
    except (subprocess.TimeoutExpired, OSError):
        if obligatoire:
            raise ErreurOutil("poser-verdict.sh injouable sur la copie : " + os.path.relpath(unite, lab.copie))
        return "injouable"
    if p.returncode != 0:
        if obligatoire:
            raise ErreurOutil("poser-verdict.sh a refusé la pose d'un verdict synthétique (code %d) : %s" % (p.returncode, os.path.relpath(unite, lab.copie)))
        return "code %d" % p.returncode
    return None


def reflechir_squelette(lab, src, dst, statut, entrees):  # rejeu-miroir
    """Reflète sur la copie l'entrée réelle `src` : un LIEN reste un lien (cible inerte), un fichier garde sa vacuité (0 ou 1 octet), un dossier garde son
    arborescence et ses noms (un octet par fichier non vide ; liens et noms exclus compris) ; une entrée `borne` reçoit un substitut de même verdict
    (plus de BORNE_FICHIERS_G34 entrées, ou un fichier creux de plus de BORNE_OCTETS_G34 octets). Ce qui existe déjà sur la copie (marqueur de code
    copié, dossier `.xcodeproj` vide) n'est jamais écrasé, seulement complété. Aucun contenu réel n'est lu. Rend False si le reflet est impossible."""
    sous_copie(lab, os.path.dirname(dst))
    try:
        info = os.lstat(src)  # le genre de l'entrée se lit sur le disque, jamais sur le statut de l'oracle
        if stat.S_ISLNK(info.st_mode):
            if not os.path.lexists(dst):
                os.symlink("cible-rejeu-inerte", dst)
            return True
        if stat.S_ISREG(info.st_mode):
            if not os.path.lexists(dst):
                with open(dst, "wb") as fh:
                    if statut == "borne":
                        fh.truncate(BORNE_OCTETS_G34 + 1)
                    elif info.st_size > 0:
                        fh.write(b"x")
            return True
        if os.path.islink(dst) or (os.path.lexists(dst) and not os.path.isdir(dst)):
            return True  # déjà présent sur la copie (lien ou fichier copié) : jamais écrit à travers
        os.makedirs(dst, exist_ok=True)
        if statut == "borne":
            if entrees > BORNE_FICHIERS_G34:
                for i in range(BORNE_FICHIERS_G34 + 1):
                    with open(os.path.join(dst, "e%05d" % i), "wb"):
                        pass
            else:
                with open(os.path.join(dst, "creux"), "wb") as fh:
                    fh.truncate(BORNE_OCTETS_G34 + 1)
            return True
        pile = [(src, dst)]
        while pile:
            courant_src, courant_dst = pile.pop()
            with os.scandir(courant_src) as it:
                enfants = sorted(it, key=lambda x: os.fsencode(x.name))
            for e in enfants:
                cible = os.path.join(courant_dst, e.name)
                if os.path.lexists(cible):
                    continue
                if e.is_symlink():
                    os.symlink("cible-rejeu-inerte", cible)
                elif e.is_dir(follow_symlinks=False):
                    os.mkdir(cible)
                    pile.append((e.path, cible))
                elif e.is_file(follow_symlinks=False):
                    with open(cible, "wb") as fh:
                        if e.stat(follow_symlinks=False).st_size > 0:
                            fh.write(b"x")
        return True
    except (OSError, ErreurOutil):
        return False


def entrees_reelles(lab):
    """Entrées de premier niveau NON CACHÉES du lab réel, triées par octets, au plus MAX_ENTREES_REELLES (lecture des NOMS seulement)."""
    try:
        with os.scandir(lab.reel) as it:
            noms = [e.name for e in it if not e.name.startswith(".")]
    except OSError as exc:
        raise ErreurOutil("lecture impossible : premier niveau du lab (" + type(exc).__name__ + ")")
    return sorted(noms, key=os.fsencode)[:MAX_ENTREES_REELLES]


def preparer_g34(lab, ctx):  # rejeu-g3g4-synthetique
    """Unités G3 et G4 d'un lab, fabriquées UNE fois sur sa copie (les constructeurs G3 et G4 se partagent le résultat) : {"G3": [écritures], "G4": [...]}.
    Rien n'est fabriqué si le `.planning/` de la racine n'existe pas (un lab dev reste silencieux, P45-D-04)."""
    cache = ctx.setdefault("g34", {})
    if lab.index in cache:
        return cache[lab.index]
    res = {"G3": [], "G4": []}
    cache[lab.index] = res
    if ".planning" not in lab.dossiers_planning:
        return res
    liv = os.path.join(lab.copie, DOSSIER_LIVRABLES_G34)
    sous_copie(lab, liv)
    if os.path.lexists(liv):
        raise ErreurOutil("nom réservé du rejeu déjà présent sur la copie : " + DOSSIER_LIVRABLES_G34)

    def livrable(nom, contenu=None, dossier=None, lien=None):
        """Livrable synthétique `rejeu-livrables-g34/<nom>` : un fichier de `contenu`, un dossier de fichiers `dossier` ({nom: contenu}), ou un lien."""
        chemin = os.path.join(liv, nom)
        if lien is not None:
            sous_copie(lab, os.path.dirname(chemin))
            os.makedirs(os.path.dirname(chemin), exist_ok=True)
            os.symlink(lien, chemin)
        elif dossier is not None:
            for sous, texte in dossier.items():
                ecrire_copie(lab, os.path.join(chemin, sous), texte)
        elif contenu is not None:
            ecrire_copie(lab, chemin, contenu)
        return DOSSIER_LIVRABLES_G34 + "/" + nom

    # --- G3 : le CLOTURE.md d'une unité dont le livrable déclaré est présent, absent, vide, lien, dossier réduit à un `.DS_Store` ---
    plein = livrable("g3-present-fichier.txt", "livrable\n")
    cas_g3 = [("61-g3-present-fichier", plein, "doit-passer"),
              ("62-g3-present-dossier", livrable("g3-present-dossier", dossier={"a.txt": "a\n", "sous/b.txt": "b\n"}), "doit-passer"),
              ("63-g3-absent", DOSSIER_LIVRABLES_G34 + "/g3-absent.txt", "doit-refuser"),
              ("64-g3-vide", livrable("g3-vide.txt", ""), "doit-refuser"),
              ("65-g3-lien", livrable("g3-lien.txt", lien="g3-present-fichier.txt"), "doit-refuser"),
              ("66-g3-dossier-ds-store", livrable("g3-dossier-ds-store", dossier={".DS_Store": "x"}), "doit-refuser"),
              ("67-g3-lien-dossier", livrable("g3-lien-dossier", lien="g3-present-dossier"), "doit-refuser")]
    for nom_unite, entree, attendu in cas_g3:
        rel, _absolu = creer_unite_g34(lab, nom_unite, entree)
        res["G3"].append(("Write", rel + "/CLOTURE.md", attendu, ""))

    # --- G4 : le SUMMARY.md d'une unité selon son verdict (posé par la vraie poser-verdict.sh) ---
    def g4(nom_unite, nom_livrable, attendu, constat="passé", pose=True, dossier=None, apres=None):
        entree = livrable(nom_livrable, "livrable\n") if dossier is None else livrable(nom_livrable, dossier=dossier)
        rel, absolu = creer_unite_g34(lab, nom_unite, entree)
        if pose:
            poser_verdict_copie(lab, ctx, absolu, constat)
        if apres is not None:
            apres(absolu, os.path.join(lab.copie, entree))
        res["G4"].append(("Write", rel + "/SUMMARY.md", attendu, ""))
        return rel, absolu

    def perime_plan(absolu, _livrable):
        with open(os.path.join(absolu, "PLAN.md"), encoding="utf-8") as fh:
            ancien = fh.read()
        ecrire_copie(lab, os.path.join(absolu, "PLAN.md"), ancien + "\nPlan retouché après le verdict.\n")

    def perime_livrable(_absolu, chemin_livrable):
        ecrire_copie(lab, chemin_livrable, "livrable retouché après le verdict\n")

    def verdict_invalide(absolu, _livrable):
        ecrire_copie(lab, os.path.join(absolu, "VERDICT.md"), '---\njuge: "rejeu"\nhash: "0"\nhash_livrables: "0"\ntentative: 1\nscore: "rejeu"\nconstats: []\n---\n')

    g4("71-g4-conforme-fichier", "g4-conforme-fichier.txt", "doit-passer")
    g4("72-g4-conforme-dossier", "g4-conforme-dossier", "doit-passer", dossier={"a.txt": "a\n", "sous/b.txt": "b\n"})
    g4("73-g4-verdict-absent", "g4-verdict-absent.txt", "doit-refuser", pose=False)
    g4("74-g4-echec", "g4-echec.txt", "doit-refuser", constat="échec")
    g4("75-g4-perime-plan", "g4-perime-plan.txt", "doit-refuser", apres=perime_plan)
    g4("76-g4-perime-livrable", "g4-perime-livrable.txt", "doit-refuser", apres=perime_livrable)
    g4("77-g4-verdict-invalide", "g4-verdict-invalide.txt", "doit-refuser", pose=False, apres=verdict_invalide)

    # --- Entrées RÉELLES de premier niveau : l'attendu vient de l'oracle de présence, jamais du hook ---
    for rang, nom in enumerate(entrees_reelles(lab), 1):
        affiche = neutraliser(nom)
        if nom == DOSSIER_LIVRABLES_G34:
            ctx["notes"].append("ENTREE-IGNOREE lab=%s entree=%s motif=nom-reserve" % (lab.affiche, affiche))
            continue
        if not entree_declarable(nom):
            ctx["notes"].append("ENTREE-IGNOREE lab=%s entree=%s motif=non-declarable-dans-ecrit" % (lab.affiche, affiche))
            continue
        statut, entrees, octets, tronque = oracle_presence(os.path.join(lab.reel, nom))
        if statut == "borne":  # rejeu-borne : la mesure de l'hypothèse A7, nommée
            ctx["notes"].append("BORNE-LIVRABLES lab=%s entree=%s fichiers=%d octets=%d%s" % (lab.affiche, affiche, entrees, octets, " mesure-tronquee" if tronque else ""))
        if not reflechir_squelette(lab, os.path.join(lab.reel, nom), os.path.join(lab.copie, nom), statut, entrees):
            ctx["notes"].append("ENTREE-IGNOREE lab=%s entree=%s motif=squelette-impossible" % (lab.affiche, affiche))
            continue
        slug = re.sub(r"[^\w.-]", "_", nom)[:48]
        rel, absolu = creer_unite_g34(lab, "69-reel-%02d-%s" % (rang, slug), nom)
        res["G3"].append(("Write", rel + "/CLOTURE.md", "doit-passer" if statut == "present" else "doit-refuser", ""))
        if statut != "present":
            continue
        rel4, absolu4 = creer_unite_g34(lab, "79-reel-%02d-%s" % (rang, slug), nom)
        if poser_verdict_copie(lab, ctx, absolu4, "passé", obligatoire=False) is not None:
            ctx["notes"].append("ENTREE-IGNOREE lab=%s entree=%s motif=verdict-non-pose-pour-g4" % (lab.affiche, affiche))
            continue
        res["G4"].append(("Write", rel4 + "/SUMMARY.md", "doit-passer", ""))
    return res


def construire_g3(lab, ctx):
    """G3 : voir `preparer_g34`. Rien avant l'étape 5 (exception documentée en tête de fichier)."""
    return preparer_g34(lab, ctx)["G3"] if ctx["etape"] >= ETAPE_G3G4 else []


def construire_g4(lab, ctx):
    """G4 : voir `preparer_g34`. Rien avant l'étape 5."""
    return preparer_g34(lab, ctx)["G4"] if ctx["etape"] >= ETAPE_G3G4 else []


def couverture_g34(labs, gagnants, etape):  # rejeu-couverture
    """[(gate, n, plancher)] des gates G3 et G4 dont l'étape est atteinte : n = écritures réellement jouées sous le gate (constructeur ET fichier
    d'attendus), plancher = PLANCHER_G34 par lab adhérent, au moins un lab. Le plancher
    ne dépend pas des constructeurs : un constructeur retiré du registre laisse n à 0 sous un plancher qui reste exigé."""
    adherents = [l for l in labs if ".planning" in l.dossiers_planning]
    res = []
    if etape >= ETAPE_G3G4:
        for gate in ("G3", "G4"):
            res.append((gate, len([e for e in gagnants if e["gate"] == gate]), PLANCHER_G34 * max(1, len(adherents))))
    return res


CONSTRUCTEURS = {"reecriture": construire_reecriture, "G6": construire_g6, "G5": construire_g5, "G1": construire_g1, "G7": construire_g7, "ROLE": construire_role}  # rejeu-registre
CONSTRUCTEURS.update({"G3": construire_g3, "G4": construire_g4})  # rejeu-g3g4-registre


def normaliser(lab, gate, brut, rang):
    """Un tuple de constructeur -> dict d'entrée ; la classification est TOTALE (P45-D-21c)."""
    if not isinstance(brut, (tuple, list)) or len(brut) not in (4, 5, 6, 7, 8):
        raise ErreurOutil("écriture mal formée rendue par le constructeur " + gate)
    outil, chemin, attendu, agent_type = brut[:4]
    origine = brut[4] if len(brut) >= 5 else "etat-derive"
    charge = brut[5] if len(brut) >= 6 else None
    branche = brut[6] if len(brut) >= 7 else None
    situation = brut[7] if len(brut) == 8 else ""
    if situation not in SITUATIONS:
        raise ErreurOutil("situation inconnue : " + str(situation) + " pour " + montrer_clef(clef(outil, chemin, agent_type or "")))
    if charge is not None and not isinstance(charge, dict):
        raise ErreurOutil("charge mal formée rendue par le constructeur " + gate)
    cle = clef(outil, chemin, agent_type or "")
    if attendu not in VALEURS_ATTENDU:
        raise ErreurOutil("classification absente : " + montrer_clef(cle))  # rejeu-total
    if origine not in ORIGINES:
        raise ErreurOutil("origine inconnue : " + str(origine) + " pour " + montrer_clef(cle))
    return {"lab": lab.index, "clef": cle, "attendu": attendu, "origine": origine, "gate": gate, "rang": rang,
            "charge": charge, "branche": branche, "situation": situation}


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
        ecriture = ("Write", rel, attendu, "")
        if gate == "G7":  # la colonne chemin est le dossier X : l'écriture rejouée est la création de X/.planning/config.json
            x = rel.rstrip("/")
            if not x or x == "." or x.startswith("/") or ".." in x.split("/"):
                raise ErreurOutil("fichier d'attendus : ligne %d invalide (G7 : un dossier relatif au lab est attendu)" % n)
            ecriture = ("Write", x + "/.planning/config.json", attendu, "", "etat-derive", None, None, "creation")
        for lab in cibles:
            entrees.append(normaliser(lab, gate, ecriture, RANG_ATTENDUS))
    return entrees


def fusionner(entrees):
    """UNE entrée gagnante par (lab, clé) : fichier d'attendus > constructeur de gate > générique ;
    doublons éliminés ; attendus contradictoires de même rang = erreur ; `doit-refuser` et
    `doit-refuser-modele` de même rang ne se contredisent pas (le plus précis l'emporte)."""
    groupes = {}
    for e in entrees:
        groupes.setdefault((e["lab"], e["clef"], e["situation"]), []).append(e)
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
    if outil in ("Write", "Edit", "NotebookEdit"):
        lu = lire_regulier(lab, absolu, MAX_CONTENU)  # lstat + fichier régulier, aucun suivi de lien (quick 45-B, H3)
        if lu is not None:
            contenu = lu
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


def jouer_creation(hook_copie, env, lab, cle, charge, cote, numero):
    """Rejoue une CRÉATION sur la copie : le dossier de planning visé (le parent de l'écriture) est mis de côté sous `cote`, le
    hook est joué, le dossier est remis en place — toujours, même sur erreur. Il n'existe rien à mettre de côté pour un dossier
    synthétique."""
    planning = os.path.join(lab.copie, os.path.dirname(cle[1]))
    sous_copie(lab, os.path.dirname(planning))
    mis = None
    if os.path.lexists(planning):  # rejeu-cote
        mis = os.path.join(cote, "cote-%d" % numero)
        try:
            os.rename(planning, mis)
        except OSError as exc:
            raise ErreurOutil("mise de côté impossible sur la copie : " + os.path.relpath(planning, lab.copie) + " (" + type(exc).__name__ + ")")
    try:
        return jouer(hook_copie, env, lab, cle[0], cle[1], cle[2], charge)
    finally:
        if mis is not None:
            os.rename(mis, planning)  # rejeu-remise


def signature_copie(racine):
    """Signature de l'arbre d'une copie : chemin, type, mode, sha256 d'un fichier ou cible d'un lien, aucun lien suivi."""
    h = hashlib.sha256()
    for dossier, dossiers, fichiers in os.walk(racine, followlinks=False):
        dossiers.sort()
        for nom in sorted(dossiers + fichiers):
            chemin = os.path.join(dossier, nom)
            rel = os.path.relpath(chemin, racine)
            st = os.lstat(chemin)
            if stat.S_ISLNK(st.st_mode):
                ligne = "%s\tl\t%s" % (rel, os.readlink(chemin))
            elif stat.S_ISDIR(st.st_mode):
                ligne = "%s\td\t%o" % (rel, stat.S_IMODE(st.st_mode))
            else:
                with open(chemin, "rb") as fh:
                    ligne = "%s\tf\t%o\t%s" % (rel, stat.S_IMODE(st.st_mode), hashlib.sha256(fh.read()).hexdigest())
            h.update(os.fsencode(ligne) + b"\n")
    return h.hexdigest()


def classer(attendu, obtenu):
    if attendu == "doit-passer":
        return "faux-refus" if obtenu == "refus" else "conforme"  # rejeu-modele-inverse
    if attendu == "doit-refuser":
        return "conforme" if obtenu == "refus" else "faux-accept"
    return "refus-conforme-modele" if obtenu == "refus" else "faux-accept"  # rejeu-modele-compte


def hors_etape(gate, etape):
    """Vrai si `gate` est d'une étape > `etape` selon ORDRE_ETAPES : ses comptes n'entrent ni dans les totaux ni
    dans l'armement. La règle EXCLUT les gates d'étapes ultérieures ; elle ne retient pas « les seuls gates
    connus » : un gate rangé sous aucune étape (`-`, `?`) reste compté (décisions du manager vf-dev-manager,
    2026-09-30)."""
    return ETAPE_DE.get(gate, 0) > etape


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
    texte = neutraliser(texte.replace("\n", " ⏎ ").replace(" | ", " / "))
    return texte if len(texte) <= 240 else texte[:240] + "…"


def colonne_chemin(cle, situation=""):
    outil, chemin, agent = cle
    suffixe = "" if (outil == "Write" and not agent) else " [" + outil + ("@" + agent if agent else "") + "]"
    return neutraliser(chemin + suffixe).replace(" | ", " / ") + (" [création]" if situation == "creation" else "")


def analyser(argv):
    opts = {"labs": [], "etape": None, "attendus": None, "rapport": None, "hook": None}
    for arg in argv:
        if arg.startswith("--lab="):
            if arg[6:] == "":
                raise Usage("--lab vide")
            opts["labs"].append(arg[6:])
        elif arg.startswith("--etape="):
            if arg[8:] not in ("1", "2", "3", "4", "5", "6"):
                raise Usage("--etape invalide : " + arg[8:] + " (attendu 1, 2, 3, 4, 5 ou 6)")
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
        raise Usage("--etape=<1|2|3|4|5|6> est requis")
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
        for lab in labs:
            if sous_un_lab(opts["rapport"], lab.reel):
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
    contexte = {"hook_copie": hook_copie, "tmp": tmp, "etape": opts["etape"], "notes": []}
    for nom in ordre:
        rang = RANG_GENERIQUE if nom == "reecriture" else RANG_GATE
        for lab in labs:
            for brut in CONSTRUCTEURS[nom](lab, contexte):
                entrees.append(normaliser(lab, nom, brut, rang))
    if opts["attendus"]:
        entrees.extend(lire_attendus(opts["attendus"], labs))
    gagnants = fusionner(entrees)
    gagnants.sort(key=lambda e: (e["lab"], e["clef"], e["situation"]))

    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": os.environ.get("HOME", ""),
           "TMPDIR": tmp, "XDG_CACHE_HOME": os.path.join(tmp, "xdg")}
    os.makedirs(env["XDG_CACHE_HOME"], exist_ok=True)
    verdicts = [None] * len(gagnants)
    libres = [i for i, e in enumerate(gagnants) if e["situation"] != "creation"]
    with ThreadPoolExecutor(max_workers=min(8, os.cpu_count() or 2)) as pool:
        rendus = list(pool.map(lambda i: jouer(hook_copie, env, labs[gagnants[i]["lab"]], *gagnants[i]["clef"], gagnants[i]["charge"]), libres))
    for i, rendu in zip(libres, rendus):
        verdicts[i] = rendu
    # Les créations se jouent APRÈS les écritures parallèles, UNE à la fois : le dossier de planning visé est mis de côté le
    # temps du payload. La copie doit être identique avant et après (sinon, erreur de l'outil : le relevé serait faux).
    creations = [i for i, e in enumerate(gagnants) if e["situation"] == "creation"]
    if creations:
        cote = os.path.join(tmp, "cote")
        os.makedirs(cote)
        avant = [signature_copie(lab.copie) for lab in labs]
        for numero, i in enumerate(creations):
            e = gagnants[i]
            verdicts[i] = jouer_creation(hook_copie, env, labs[e["lab"]], e["clef"], e["charge"], cote, numero)
        apres = [signature_copie(lab.copie) for lab in labs]
        if avant != apres:  # rejeu-copie-remise
            raise ErreurOutil("copie non remise en place après les créations de G7 : le relevé n'est pas fiable")

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
            motif = (motif + " ; " if motif and motif != "passe" else "") + RAISON_REGLE + (" : " + gagnant["branche"] if gagnant.get("branche") else "")
        lignes.append(" | ".join([gate, lab.affiche, colonne_chemin(gagnant["clef"], gagnant["situation"]), gagnant["attendu"], obtenu, motif]))

    gates_comptes = [g for lot in ORDRE_ETAPES[:opts["etape"]] for g in lot]
    gates_comptes += [g for g in GATES if g in CONSTRUCTEURS and g not in gates_comptes]
    gates_comptes += sorted(g for g in comptes if g not in gates_comptes and g != "-")
    totaux = dict((c, 0) for c in COMPTES)
    for gate in sorted(gates_comptes, key=lambda g: (GATES.index(g) if g in GATES else len(GATES), g)):
        c = comptes.get(gate, dict((k, 0) for k in COMPTES))
        lignes.append("COMPTE %s faux-refus=%d faux-accept=%d refus-conforme-modele=%d%s"
                      % (gate, c["faux-refus"], c["faux-accept"], c["refus-conforme-modele"],
                         " hors-etape" if hors_etape(gate, opts["etape"]) else ""))
    for gate, c in comptes.items():
        if hors_etape(gate, opts["etape"]):  # rejeu-etape
            continue
        for k in COMPTES:
            totaux[k] += c[k]
    lignes.append("REJEU-ETAPE-%d faux-refus=%d faux-accept=%d refus-conforme-modele=%d"
                  % (opts["etape"], totaux["faux-refus"], totaux["faux-accept"], totaux["refus-conforme-modele"]))
    couvertures = couverture_g34(labs, gagnants, opts["etape"])
    insuffisantes = [c for c in couvertures if c[1] < c[2]]  # rejeu-couverture
    for gate, n, plancher in couvertures:
        lignes.append("COUVERTURE-REJEU %s n=%d plancher=%d" % (gate, n, plancher))
    for gate in [g for g in GATES if g in CONSTRUCTEURS and getattr(CONSTRUCTEURS[g], "classe_modele", False)]:
        for lab in labs:
            n = len([e for e in gagnants if e["lab"] == lab.index and e["gate"] == gate and e["origine"] == "regle-ecrite"])
            lignes.append("CLASSE-REGLE-ECRITE %s lab=%s n=%d" % (gate, lab.affiche, n))
    lignes.extend(contexte["notes"])  # ROLE-AGENT : une ligne par agent rejoué (rôle dérivé, nombre de dispatchs), 45-09

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
    for gate, n, plancher in insuffisantes:
        sys.stderr.write("[rejeu-gates] couverture insuffisante : %s n=%d plancher=%d — un zéro mesuré sans rien jouer n'est pas une mesure\n" % (gate, n, plancher))
    return 1 if (divergence or insuffisantes) else 0


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
    except RecursionError:  # rejeu-recursion
        # quick 45-B (B3) : un arbre de plus d'un millier de niveaux dépasse la pile de l'interpréteur ; message, jamais une trace.
        sys.stderr.write("[rejeu-gates] arborescence trop profonde pour être parcourue : rien n'a été mesuré\n")
        return 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    DOSSIER_SCRIPTS = sys.argv[1]  # dossier de rejeu-gates.sh, posé par le lanceur shell
    sys.exit(main(sys.argv[2:]))
PY_REJEU_GATES_EOF
