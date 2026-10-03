#!/usr/bin/env bash
# rejeu-reel.sh — le GESTE de rejeu des gates sur des labs RÉELS (Phase 45, 45-03 ; GATE-13 ;
# P45-D-21, P45-D-03b). Il est EXTÉRIEUR à rejeu-gates.sh, à dessein : la preuve « aucune écriture
# dans le lab réel » ne peut pas venir de l'outil dont on veut prouver qu'il n'écrit pas — un outil
# qui écrirait hors de son propre périmètre d'empreinte ne se verrait pas. Ici l'empreinte couvre
# TOUT l'arbre de chaque lab, et c'est CETTE comparaison, non celle que rejeu-gates.sh fait sur son
# périmètre, dont dépend l'armement d'une étape (P45-D-03b). C'est ce script, jamais rejeu-gates.sh
# seul, que 45-05 à 45-09 lancent sur les labs réels. Les chemins des labs sont des ARGUMENTS.
#
# Usage :
#   rejeu-reel.sh --lab=<chemin> [--lab=<chemin>…] --etape=<1|2|3|4> [--attendus=<fichier>]
#                 --rapport=<fichier> [--hook=<script>]
# Mêmes arguments que rejeu-gates.sh (transmis tels quels), --rapport obligatoire. Pour chaque lab,
# dans cet ordre :
#   (1) empreinte de TOUT l'arbre — aucun élagage : `.git`, `node_modules` et dossiers de build
#       compris. Pour chaque entrée : chemin relatif, type, mode octal, mtime en nanosecondes, sha256
#       du contenu d'un fichier régulier ou cible lue d'un lien symbolique, LIEN JAMAIS SUIVI ;
#       entrées triées par octets ; un fichier d'empreinte par lab, HORS du lab ;
#   (2) rejeu-gates.sh avec les mêmes arguments ;
#   (3) la même empreinte ;
#   (4) `cmp -s` avant/après, lab par lab.
# Après ce que rejeu-gates.sh a écrit dans --rapport, il ajoute une ligne
# `EMPREINTE-ARBRE-IDENTIQUE <lab affiché>` ou `EMPREINTE-ARBRE-DIVERGENTE <lab affiché>` par lab
# (`~/…` sous HOME ; `<lab-N>` hors de HOME, N = rang parmi les `--lab=` hors de HOME, donc dépendant de l'ORDRE des `--lab=` de l'appel :
# la même liste dans le même ordre redonne les mêmes noms, un autre ordre les permute — lot C, F2). Un lab dont le relevé ne porte
# AUCUNE ligne mesurée reçoit en plus `MESURE-VIDE <lab affiché>` (rapport et sortie) et un message : jamais lu comme un vert (code 1).
# Un `.planning` du lab, racine ou imbriqué, qui est un lien dont la cible sort du lab est refusé avant tout rejeu (code 1, rien joué).
# Codes : 0 toutes identiques, 1 au moins une divergence ou une mesure vide (ou code non nul de
# rejeu-gates.sh, repris), 64 usage. Un lab très gros peut dépasser le délai d'un appel d'outil :
# lancer alors en arrière-plan et attendre la fin.
#
# Il ne lance aucune commande git, ne lit aucun gestionnaire de versions, n'écrit rien dans un lab.
# Son calcul d'empreinte ne réutilise aucun code de rejeu-gates.sh : deux implémentations
# indépendantes. Ses seuls sous-processus : rejeu-gates.sh (par bash) et `cmp`.
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

PY_INVOKE="$(py_resolve_local)" || { echo "[rejeu-reel] interpréteur Python introuvable" >&2; exit 1; }
SCRIPT_DIR_SELF="$(cd "$(dirname "$0")" && pwd -P)" || { echo "[rejeu-reel] dossier du script illisible" >&2; exit 1; }

# shellcheck disable=SC2086
exec $PY_INVOKE -I -S - "$SCRIPT_DIR_SELF/rejeu-gates.sh" "$@" <<'PY_REJEU_REEL_EOF'
import hashlib
import os
import shutil
import stat
import subprocess
import sys
import tempfile

# Sous-arbres empreints, relatifs au lab : "" = TOUT l'arbre, sans aucun élagage.
SOUS_ARBRES = [""]  # reel-perimetre


GENERIQUES = {}


def neutraliser(texte):
    """Aucun caractère de contrôle (LF, CR, ESC…) dans une ligne imprimée : `\\xNN`. Un nom de dossier ne forge pas de ligne."""
    return "".join(c if (c >= " " and c != "\x7f") else "\\x%02x" % ord(c) for c in texte)  # reel-neutraliser


def afficher(chemin):
    """Jamais un chemin absolu de machine : `~/…` sous HOME, sinon un nom générique `<lab-N>` (quick 45-B, B2)."""
    p = os.path.realpath(chemin)
    home = os.environ.get("HOME") or ""
    if home:
        h = os.path.realpath(home)
        if p == h:
            return "~"
        if p.startswith(h + os.sep):
            return neutraliser("~/" + p[len(h) + 1:])
    return GENERIQUES.setdefault(p, "<lab-%d>" % (len(GENERIQUES) + 1))  # reel-generique


def sous_un_lab(chemin, reel):
    """Vrai si `chemin` est le lab `reel` ou se trouve dessous : comparaison de chaînes ET identité de fichier de chaque ancêtre existant
    (un système de fichiers insensible à la casse rend `/x/LAB` et `/x/lab` identiques sans que les chaînes le disent)."""
    p = os.path.abspath(chemin)
    r = os.path.realpath(chemin)
    if r == reel or r.startswith(reel + os.sep):
        return True
    while True:
        try:
            if os.path.exists(p) and os.path.samefile(p, reel):  # reel-samefile
                return True
        except OSError:
            pass
        parent = os.path.dirname(p)
        if parent == p:
            return False
        p = parent


# Chemins que le rejeu ÉCRIT ou LIT à l'intérieur d'un `.planning/` ou du `.claude/` de la racine (quick 45-B, H3) : un lien
# dont la cible résolue sort du lab, à ces endroits, ferait écrire ou lire hors du lab.
NOMS_ECRITS_LUS = ("STATE.md", "INDEX.md", "cloture.log", "derogations-gates.log", ".recalc-cache.json", "config.json",
                   "cycles", "phases", "CADRAGE.md", "PLAN.md")


def lien_a_risque(rel):
    parts = rel.split("/")
    if parts[-1] == ".planning":  # reel-planning-lien
        # lot C, F1 : un `.planning` du lab (racine ou imbriqué) qui est LUI-MÊME un lien : rien de ce qui est dessous n'est vu par la
        # copie du rejeu, et ce qui y serait écrit ou lu l'est hors du lab (décision du manager vf-dev-manager, 2026-10-01, renversable).
        return True
    if parts[0] == ".claude":
        return len(parts) == 1 or (parts[1] == "agents" and len(parts) <= 3)
    if ".planning" not in parts[:-1]:
        return False
    sous = parts[parts.index(".planning") + 1:]
    return sous[-1] in NOMS_ECRITS_LUS or sous[-1].casefold() == "verdict.md" or "cycles" in sous[:-1]


def liens_sortants(reel, liens):
    sortants = []
    for rel in liens:
        if not lien_a_risque(rel):
            continue
        cible = os.path.realpath(os.path.join(reel, rel))
        if not (cible == reel or cible.startswith(reel + os.sep)):  # reel-lien-sortant
            sortants.append(rel)
    return sortants


def empreinte(racine, fichier):
    """Empreinte de l'arbre de `racine` : une ligne par entrée (chemin, type, mode, mtime ns, sha256
    ou cible du lien), triées par octets. os.lstat et os.scandir(follow_symlinks=False) : un lien
    symbolique est une entrée, jamais un chemin à parcourir ni un fichier à lire."""
    lignes = []
    liens = []

    def entree(rel):
        chemin = os.path.join(racine, rel) if rel else racine
        st = os.lstat(chemin)  # reel-lstat
        mode = st.st_mode
        if stat.S_ISLNK(mode):
            genre, sig = "l", os.readlink(chemin)
            liens.append(rel)
        elif stat.S_ISDIR(mode):
            genre, sig = "d", "-"
        elif stat.S_ISREG(mode):
            genre = "f"
            h = hashlib.sha256()
            try:
                with open(chemin, "rb") as fh:
                    for bloc in iter(lambda: fh.read(1 << 20), b""):
                        h.update(bloc)
                sig = h.hexdigest()  # reel-sha
            except OSError as exc:
                sig = "ERR:" + type(exc).__name__
        else:
            genre, sig = "s", "-"
        lignes.append((rel or ".", "%s\t%s\t%o\t%d\t%s" % (rel or ".", genre, stat.S_IMODE(mode), st.st_mtime_ns, sig)))  # reel-signature
        return genre

    # Parcours ITÉRATIF (quick 45-B, B3) : aucune récursion, donc aucune profondeur qui fasse planter l'interpréteur.
    pile = []
    for sous in SOUS_ARBRES:
        if sous == "" or os.path.lexists(os.path.join(racine, sous)):
            pile.append(sous)
    while pile:
        rel = pile.pop()
        if entree(rel) != "d":
            continue
        chemin = os.path.join(racine, rel) if rel else racine
        try:
            with os.scandir(chemin) as it:
                enfants = sorted(e.name for e in it)
        except OSError as exc:
            lignes.append((rel + "/?", "%s/?\tERR\t%s" % (rel, type(exc).__name__)))
            continue
        for nom in enfants:
            pile.append(rel + "/" + nom if rel else nom)

    lignes.sort(key=lambda t: os.fsencode(t[0]))
    with open(fichier, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("".join(l[1] + "\n" for l in lignes))
    return liens


def main(argv):
    rejeu_gates = argv[0]
    args = argv[1:]
    labs = []
    rapport = None
    for arg in args:
        if arg.startswith("--lab="):
            if arg[6:] == "":
                sys.stderr.write("[rejeu-reel] --lab vide\n")
                return 64
            labs.append(arg[6:])
        elif arg.startswith("--rapport="):
            rapport = arg[10:]
        elif arg.startswith(("--etape=", "--attendus=", "--hook=")):
            pass
        else:
            sys.stderr.write("[rejeu-reel] argument inconnu : " + arg + "\n")
            return 64
    if not labs or not rapport:
        sys.stderr.write("[rejeu-reel] au moins un --lab=<chemin> et --rapport=<fichier> sont requis\n")
        return 64
    for lab in labs:
        if not os.path.isdir(lab):
            sys.stderr.write("[rejeu-reel] lab introuvable (pas un dossier) : " + afficher(lab) + "\n")
            return 64

    # La racine d'un lab est RÉSOLUE avant toute empreinte : un --lab qui est un lien symbolique vers
    # le lab serait sinon une entrée de type lien, jamais parcourue, et l'arbre réel resterait
    # invisible (comme rejeu-gates.sh, qui travaille sur le lab réel).
    reels = [os.path.realpath(lab) for lab in labs]  # reel-realpath
    for lab in labs:
        afficher(lab)  # nomme les labs hors HOME dans l'ordre des arguments, comme rejeu-gates.sh
    for lab, reel in zip(labs, reels):
        if sous_un_lab(rapport, reel):  # reel-rapport
            sys.stderr.write("[rejeu-reel] le rapport ne peut pas être écrit sous un lab : " + afficher(lab) + "\n")
            return 64

    tmp = os.path.realpath(tempfile.mkdtemp(prefix="vf-rejeu-reel-"))
    try:
        liens = []
        for i, reel in enumerate(reels):
            liens.append(empreinte(reel, os.path.join(tmp, "avant-%d.txt" % i)))
        # H3 (quick 45-B, décisions du manager vf-dev-manager, 2026-10-01) : AVANT tout rejeu, un lien dont la cible résolue sort du
        # lab, sur un chemin que le rejeu écrit ou lit, est une erreur (code 1) : rien n'est joué, rien n'est écrit.
        refus = False
        for lab, reel, ls in zip(labs, reels, liens):
            for rel in liens_sortants(reel, ls):
                refus = True
                sys.stderr.write("[rejeu-reel] lien symbolique dont la cible sort du lab : " + afficher(lab) + "/" + neutraliser(rel)
                                 + " (le rejeu écrit ou lit à cet endroit) ; rien n'a été joué\n")
        if refus:
            return 1
        code = subprocess.run(["bash", rejeu_gates] + args).returncode
        if code == 64:  # reel-refus64
            # rejeu-gates.sh a refusé l'usage avant de rejouer quoi que ce soit : rien n'a été mesuré,
            # aucune ligne EMPREINTE-ARBRE-* n'est écrite ni imprimée.
            return code
        lignes = []
        divergence = False
        vides = []
        try:
            with open(rapport, encoding="utf-8") as fh:
                releve = fh.read().split("\n")
        except OSError:
            releve = []
        for lab in labs:  # reel-mesure-vide
            # lot C, F1 : un lab dont le relevé ne porte AUCUNE ligne mesurée (`<gate> | <lab affiché> | …`) n'a rien mesuré : jamais un vert.
            affiche = afficher(lab)
            if not any(len(ch) >= 5 and ch[1] == affiche for ch in (l.split(" | ") for l in releve)):
                vides.append(lab)
        for i, lab in enumerate(labs):
            avant = os.path.join(tmp, "avant-%d.txt" % i)
            apres = os.path.join(tmp, "apres-%d.txt" % i)
            empreinte(reels[i], apres)  # le retour (liens) ne sert qu'avant le rejeu
            identique = subprocess.run(["cmp", "-s", avant, apres]).returncode == 0  # reel-cmp
            if identique:
                lignes.append("EMPREINTE-ARBRE-IDENTIQUE " + afficher(lab))
            else:
                divergence = True
                lignes.append("EMPREINTE-ARBRE-DIVERGENTE " + afficher(lab))
        for lab in vides:
            lignes.append("MESURE-VIDE " + afficher(lab))
            sys.stderr.write("[rejeu-reel] aucune ligne mesurée pour " + afficher(lab) + " : ce n'est pas un vert (rien n'a été rejoué sur ce lab)\n")
        texte = "".join(l + "\n" for l in lignes)
        with open(rapport, "a", encoding="utf-8", newline="\n") as fh:
            fh.write(texte)
        sys.stdout.buffer.write(texte.encode("utf-8"))
        sys.stdout.flush()
        if code != 0:
            return code
        return 1 if (divergence or vides) else 0
    except (RecursionError, MemoryError):
        sys.stderr.write("[rejeu-reel] arborescence trop profonde ou trop grosse pour être empreinte : rien n'a été mesuré\n")
        return 1
    except OSError as exc:  # reel-profondeur
        # un chemin plus long que la limite du système (arbre très profond) ou une entrée disparue : message, jamais une trace.
        sys.stderr.write("[rejeu-reel] arborescence illisible ou trop profonde, ou rapport non écrit (" + type(exc).__name__ + ")\n")
        return 1
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
PY_REJEU_REEL_EOF
