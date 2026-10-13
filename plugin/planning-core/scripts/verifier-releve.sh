#!/usr/bin/env bash
# verifier-releve.sh — le PRÉDICAT D'ARMEMENT d'une étape de rejeu (Phase 46.1, 46.1-03 ; ARMG-04 ; P461-D-06).
# Il remplace les prédicats écrits en awk dans les plans d'armement (46-11, 46-12), qui lisaient une sous-chaîne
# (`faux-refus=0 faux-accept=0`), ignoraient `COUVERTURE-REJEU` et laissaient une section « Non armé » excuser un faux
# refus. Ici un relevé de rejeu est LU, ligne entière par ligne entière, et la décision d'armer est un code de sortie
# versionné, testé règle par règle (suite : tests/test-verifier-releve.sh).
#
# Usage :
#   verifier-releve.sh --etape=<5|6> [--lab=<lab affiché>]… <relevé>
#   (le relevé est un ARGUMENT, jamais l'entrée standard ; --lab ajoute un lab attendu à ceux que les lignes de table du relevé nomment)
# Codes : 0 armable · 1 non armable · 64 usage (étape absente ou autre que 5/6, option inconnue, zéro ou deux relevés).
# Sortie : une ligne `RELEVE-ECART <règle> : <détail>` par écart, puis UNE dernière ligne
#   `RELEVE-VERDICT armable etape=<n> labs=<k> gates=<G3,G4[,G4P]>` (code 0) ou `RELEVE-VERDICT non-armable etape=<n> ecarts=<m>` (code 1).
#   Le détail d'un écart nomme la règle, le numéro de ligne et le jeton en cause, jamais la ligne fautive entière : la sortie est
#   reproduite telle quelle dans les relevés versionnés.
# Lecture : O_NOFOLLOW (un lien est refusé), fichier régulier, 64 Mio au plus, UTF-8 strict ; un échec est l'écart `lecture`.
#
# Grammaire (lignes ENTIÈRES ; un `\r` final rend la ligne malformée) :
#   REJEU-ETAPE-<n> faux-refus=<a> faux-accept=<b> refus-conforme-modele=<c>   une seule, n égal à --etape, a = b = 0
#   (les lignes `COMPTE …`, `EMPREINTE-IDENTIQUE …`, `RELEVE-ECART …`, `RELEVE-VERDICT …` d'un relevé ne sont JAMAIS lues pour décider)
# Règles de cette tâche : lecture, vide, etape-absente, faux-refus, faux-accept (le reste de l'interface est posé par la tâche suivante).
# Une section « Non armé » n'a AUCUN effet sur la décision : aucune règle ne la lit.
#
# Ce que ce script ne fait PAS : il ne recalcule rien, ne lance aucun sous-processus, n'écrit aucun fichier, ne lit aucun lab, et ne
# vérifie pas le commit rejoué contre le dépôt (il juge la forme du relevé, pas son histoire).
# Chaque règle tient sur UNE ligne `if <condition>:` portant le marqueur `# releve-<règle>` : c'est la ligne que les mutants de la suite neutralisent.
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

PY_INVOKE="$(py_resolve_local)" || { echo "[verifier-releve] interpréteur Python introuvable" >&2; exit 1; }

# shellcheck disable=SC2086
exec $PY_INVOKE -I -S - "$@" <<'PY_VERIFIER_RELEVE_EOF'
import os
import re
import stat
import sys

BORNE_RELEVE = 64 * 1024 * 1024  # octets ; au-delà : écart lecture
GATES_PAR_ETAPE = {5: ("G3", "G4"), 6: ("G3", "G4", "G4P")}
MOTIFS_MACHINE = ("/Users/", "/home/")

RE_ETAPE = re.compile(r"REJEU-ETAPE-([0-9]+) faux-refus=([0-9]+) faux-accept=([0-9]+) refus-conforme-modele=([0-9]+)")
RE_GATE = re.compile(r"[A-Z][A-Z0-9]*")

ECARTS = []


def ecart(regle, detail):
    ECARTS.append("RELEVE-ECART %s : %s" % (regle, detail))


def sur(texte):
    """Forme affichable d'un nom tiré du relevé : jamais un chemin de machine, ni un caractère de contrôle, borné."""
    if any(t in texte for t in MOTIFS_MACHINE):
        return "<nom-masqué>"
    propre = "".join("?" if (ord(c) < 32 or ord(c) == 127) else c for c in texte)
    return propre if len(propre) <= 80 else propre[:77] + "..."


def usage(message):
    sys.stderr.write("[verifier-releve] usage : %s\n" % message)
    sys.stderr.write("  verifier-releve.sh --etape=<5|6> [--lab=<lab affiché>]... <relevé>\n")
    return 64


def lire_arguments(argv):
    """(etape, labs, chemin) ou (None, None, message d'usage)."""
    etape = None
    labs = []
    positionnels = []
    for arg in argv:
        if arg.startswith("--etape="):
            if etape is not None:
                return None, None, "--etape donné deux fois"
            valeur = arg[len("--etape="):]
            if valeur not in ("5", "6"):
                return None, None, "--etape doit valoir 5 ou 6"
            etape = int(valeur)
        elif arg.startswith("--lab="):
            lab = arg[len("--lab="):]
            if lab == "":
                return None, None, "--lab ne peut pas être vide"
            labs.append(lab)
        elif arg.startswith("-"):
            return None, None, "option inconnue"
        else:
            positionnels.append(arg)
    if etape is None:
        return None, None, "--etape=<5|6> est obligatoire"
    if len(positionnels) != 1:
        return None, None, "un seul relevé est attendu (reçu %d)" % len(positionnels)
    return etape, labs, positionnels[0]


def lire_releve(chemin):
    """Texte du relevé. OSError ou ValueError (lien, non régulier, borne, UTF-8) : l'appelant en fait l'écart `lecture`."""
    drapeaux = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0)
    if os.path.islink(chemin):
        raise ValueError("lien")
    fd = os.open(chemin, drapeaux)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode):
            raise ValueError("non régulier")
        if info.st_size > BORNE_RELEVE:
            raise ValueError("borne")
        morceaux = []
        total = 0
        while True:
            bloc = os.read(fd, 1 << 20)
            if not bloc:
                break
            total += len(bloc)
            if total > BORNE_RELEVE:
                raise ValueError("borne")
            morceaux.append(bloc)
    finally:
        os.close(fd)
    return b"".join(morceaux).decode("utf-8", "strict")


def conclure(etape, nb_labs):
    armable = (not ECARTS)  # verdict-final
    sortie = list(ECARTS)
    if armable:
        sortie.append("RELEVE-VERDICT armable etape=%d labs=%d gates=%s" % (etape, nb_labs, ",".join(GATES_PAR_ETAPE[etape])))
    else:
        sortie.append("RELEVE-VERDICT non-armable etape=%d ecarts=%d" % (etape, len(ECARTS)))
    sys.stdout.buffer.write("".join(ligne + "\n" for ligne in sortie).encode("utf-8", "replace"))
    sys.stdout.flush()
    return 0 if armable else 1


def juger(texte, etape, labs_options):
    lignes = texte.split("\n")
    if lignes and lignes[-1] == "":
        lignes.pop()
    numerotees = list(enumerate(lignes, 1))

    # --- labs : les --lab et ceux des lignes de table `<gate> | <lab> | … ` (au moins six champs ; une ligne de tableau Markdown commence par `|`)
    labs = []
    for lab in labs_options:
        if lab not in labs:
            labs.append(lab)
    for _, ligne in numerotees:
        champs = ligne.split(" | ")
        if len(champs) >= 6 and RE_GATE.fullmatch(champs[0]) and champs[1] not in labs:
            labs.append(champs[1])

    # --- REJEU-ETAPE
    etapes_valides = []
    for i, ligne in numerotees:
        if not ligne.startswith("REJEU-ETAPE-"):
            continue
        m = None if ligne.endswith("\r") else RE_ETAPE.fullmatch(ligne)
        if m is not None:
            etapes_valides.append((i, int(m.group(1)), int(m.group(2)), int(m.group(3))))
    de_l_etape = [e for e in etapes_valides if e[1] == etape]
    refus_non_nuls = [e for e in de_l_etape if e[2] != 0]
    accepts_non_nuls = [e for e in de_l_etape if e[3] != 0]

    if not de_l_etape:  # releve-etape-absente
        ecart("etape-absente", "aucune ligne REJEU-ETAPE-%d conforme à la grammaire" % etape)
    if refus_non_nuls:  # releve-faux-refus
        for i, _, a, _ in refus_non_nuls:
            ecart("faux-refus", "ligne %d : faux-refus=%d" % (i, a))
    if accepts_non_nuls:  # releve-faux-accept
        for i, _, _, b in accepts_non_nuls:
            ecart("faux-accept", "ligne %d : faux-accept=%d" % (i, b))
    return len(labs)


def main(argv):
    etape, labs_options, chemin = lire_arguments(argv)
    if etape is None:
        return usage(chemin)
    erreur_lecture = None
    try:
        texte = lire_releve(chemin)
    except (OSError, ValueError) as exc:
        erreur_lecture = type(exc).__name__
        texte = ""
    if erreur_lecture is not None:  # releve-lecture
        ecart("lecture", "relevé illisible, en lien, non régulier, au-delà de %d octets ou hors UTF-8 (%s)" % (BORNE_RELEVE, erreur_lecture))
        return conclure(etape, 0)
    if texte.strip() == "":  # releve-vide
        ecart("vide", "relevé vide ou réduit à des blancs")
        return conclure(etape, 0)
    return conclure(etape, juger(texte, etape, labs_options))


sys.exit(main(sys.argv[1:]))
PY_VERIFIER_RELEVE_EOF
