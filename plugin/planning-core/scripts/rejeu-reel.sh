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
# (`~/…` sous HOME). Codes : 0 toutes identiques, 1 au moins une divergence (ou code non nul de
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


def afficher(chemin):
    p = os.path.realpath(chemin)
    home = os.environ.get("HOME") or ""
    if home:
        h = os.path.realpath(home)
        if p == h:
            return "~"
        if p.startswith(h + os.sep):
            return "~/" + p[len(h) + 1:]
    return p


def empreinte(racine, fichier):
    """Empreinte de l'arbre de `racine` : une ligne par entrée (chemin, type, mode, mtime ns, sha256
    ou cible du lien), triées par octets. os.lstat et os.scandir(follow_symlinks=False) : un lien
    symbolique est une entrée, jamais un chemin à parcourir ni un fichier à lire."""
    lignes = []

    def entree(rel):
        chemin = os.path.join(racine, rel) if rel else racine
        st = os.lstat(chemin)  # reel-lstat
        mode = st.st_mode
        if stat.S_ISLNK(mode):
            genre, sig = "l", os.readlink(chemin)
        elif stat.S_ISDIR(mode):
            genre, sig = "d", "-"
        elif stat.S_ISREG(mode):
            genre = "f"
            h = hashlib.sha256()
            try:
                with open(chemin, "rb") as fh:
                    for bloc in iter(lambda: fh.read(1 << 20), b""):
                        h.update(bloc)
                sig = h.hexdigest()
            except OSError as exc:
                sig = "ERR:" + type(exc).__name__
        else:
            genre, sig = "s", "-"
        lignes.append((rel or ".", "%s\t%s\t%o\t%d\t%s" % (rel or ".", genre, stat.S_IMODE(mode), st.st_mtime_ns, sig)))
        return genre

    def descendre(rel):
        if entree(rel) != "d":
            return
        chemin = os.path.join(racine, rel) if rel else racine
        try:
            with os.scandir(chemin) as it:
                enfants = sorted(e.name for e in it)
        except OSError as exc:
            lignes.append((rel + "/?", "%s/?\tERR\t%s" % (rel, type(exc).__name__)))
            return
        for nom in enfants:
            descendre(rel + "/" + nom if rel else nom)

    for sous in SOUS_ARBRES:
        if sous == "" or os.path.lexists(os.path.join(racine, sous)):
            descendre(sous)
    lignes.sort(key=lambda t: os.fsencode(t[0]))
    with open(fichier, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("".join(l[1] + "\n" for l in lignes))


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

    tmp = os.path.realpath(tempfile.mkdtemp(prefix="vf-rejeu-reel-"))
    try:
        for i, lab in enumerate(labs):
            empreinte(lab, os.path.join(tmp, "avant-%d.txt" % i))
        code = subprocess.run(["bash", rejeu_gates] + args).returncode
        lignes = []
        divergence = False
        for i, lab in enumerate(labs):
            avant = os.path.join(tmp, "avant-%d.txt" % i)
            apres = os.path.join(tmp, "apres-%d.txt" % i)
            empreinte(lab, apres)
            identique = subprocess.run(["cmp", "-s", avant, apres]).returncode == 0  # reel-cmp
            if identique:
                lignes.append("EMPREINTE-ARBRE-IDENTIQUE " + afficher(lab))
            else:
                divergence = True
                lignes.append("EMPREINTE-ARBRE-DIVERGENTE " + afficher(lab))
        texte = "".join(l + "\n" for l in lignes)
        with open(rapport, "a", encoding="utf-8", newline="\n") as fh:
            fh.write(texte)
        sys.stdout.buffer.write(texte.encode("utf-8"))
        sys.stdout.flush()
        if code != 0:
            return code
        return 1 if divergence else 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
PY_REJEU_REEL_EOF
