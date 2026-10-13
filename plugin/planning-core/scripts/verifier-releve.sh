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
# Grammaire (lignes ENTIÈRES ; un `\r` final rend la ligne malformée ; « commence par le jeton » = la ligne rougit si elle ne suit pas la grammaire ; tout
# nombre est écrit en 1 à 9 chiffres : un nombre plus long est une ligne malformée nommée, jamais une trace — fix-5b V1) :
#   REJEU-ETAPE-<n> faux-refus=<a> faux-accept=<b> refus-conforme-modele=<c>   UNE seule pour l'étape demandée, a = b = 0 ; c est informatif
#   COMMIT-REJOUE <40 hex minuscules>                                          UNE seule (le commit n'est pas vérifié contre le dépôt)
#   EMPREINTE-ARBRE-(IDENTIQUE|DIVERGENTE) <lab>                               par lab : UNE ligne IDENTIQUE, aucune DIVERGENTE
#                                                                              (jamais EMPREINTE-IDENTIQUE, émise par rejeu-gates.sh sur son périmètre restreint)
#   EMPREINTE-DIVERGENTE <lab>                                                 aucune (émise par rejeu-gates.sh : le rejeu a MODIFIÉ le lab ; toute ligne qui commence par ce jeton est un fait — fix-5b V3)
#   MESURE-VIDE <lab>                                                          aucune
#   COUVERTURE-REJEU (G3|G4|G4P) n=<k> plancher=<p>                            par gate visé (étape 5 : G3, G4 ; étape 6 : G3, G4, G4P) : UNE ligne, p ≥ 1, k ≥ p
#   ligne de table `<gate> | <lab> | …`                                        au moins six champs séparés par « | », premier champ ^[A-Z][A-Z0-9]*$ : nomme un lab
#                                                                              (labs = union des --lab et des labs de table, au moins un ; une ligne de tableau Markdown, qui commence par `|`, ne compte pas)
#   COMPTE (?|<gate>) faux-refus=<a> faux-accept=<b> refus-conforme-modele=<c>[ hors-etape]   UNE ligne par gate des étapes jusqu'à n (ORDRE_ETAPES, copie de celui de rejeu-gates.sh) ; le suffixe
#                                                                              ` hors-etape` est exigé si et seulement si l'étape de la gate dépasse n (gate inconnue : étape 0) ;
#                                                                              REJEU-ETAPE-<n> est RECOUPÉ avec la somme des lignes COMPTE sans suffixe, selon la règle de l'émetteur
#                                                                              (rejeu-gates.sh : les comptes des gates d'étapes ultérieures sont écartés ; la gate `-`, qui ne porte que des
#                                                                              faux-accept, n'a pas de ligne) : faux-refus et refus-conforme-modele ÉGAUX à la somme, faux-accept SUPÉRIEUR OU ÉGAL
#   aucune ligne ne porte un jeton de la grammaire ailleurs qu'en position 0 (REJEU-ETAPE-, COMMIT-REJOUE, EMPREINTE-ARBRE-, EMPREINTE-DIVERGENTE, MESURE-VIDE, COUVERTURE-REJEU, et la tête
#   d'une ligne de compte `COMPTE <gate> faux-refus` : « COMPTE » seul est un mot courant) : une ligne décalée d'une espace ou citée est malformée, jamais ignorée (fix-5b V4 (a)) ;
#   la SORTIE du script ne porte aucun de ces jetons (ses détails nomment la famille en minuscules) : reproduite dans un relevé versionné, elle ne change pas la décision
#   aucune ligne ne porte de chemin ABSOLU de machine : un jeton de chemin (suite maximale de caractères de mot, `.~%+@/-`) qui commence par `/` et vaut, une fois normalisé
#   lexicalement, `/Users` ou `/home` ou est dessous (`file:///Users/<c>`, `a=/home/<c>`, `//home/<c>`, `/tmp/../home/<c>` rougissent ; `src/pages/home/x`, `~/home/x` non — fix-5b V2)
#   (les lignes `EMPREINTE-IDENTIQUE …`, `RELEVE-ECART …`, `RELEVE-VERDICT …` d'un relevé ne sont JAMAIS lues pour décider ; les lignes COMPTE ne servent qu'au recoupement de REJEU-ETAPE)
# Règles (26, une ligne `if` marquée chacune) : lecture, vide, etape-absente, etape-malformee, etape-doublon, etape-autre (une ligne REJEU-ETAPE-<m>, m ≠ n),
#   faux-refus, faux-accept, commit-absent, commit-malforme, commit-doublon, labs-absents, empreinte-absente, empreinte-doublon, empreinte-divergente, rejeu-divergent,
#   mesure-vide, couverture-absente, couverture-malformee (dont plancher=0), couverture-doublon, couverture-insuffisante, jeton-deplace, chemin-machine, etape-recoupement (REJEU-ETAPE recoupé avec les lignes COMPTE), compte-malforme, compte-absent.
# Une section « Non armé » n'a AUCUN effet sur la décision : aucune règle ne la lit.
#
# Ce que ce script ne fait PAS : il ne recalcule rien, ne lance aucun sous-processus, n'écrit aucun fichier, ne lit aucun lab, et ne
# vérifie pas le commit rejoué contre le dépôt (il juge la forme du relevé, pas son histoire).
# LIMITE (bx) (fix-5b, audit-5b F-2, revue-5b n°7, P461-D-06 ; modele-cycles.md) : le script juge la FORME d'un relevé AUTO-DÉCLARÉ, pas sa vérité. (1) Le plancher de COUVERTURE-REJEU est
#   déclaré par le relevé lui-même (seuls p >= 1 et k >= p sont exigés). (2) Les lignes COMPTE ne sont pas recomptées sur les lignes de table : un relevé réécrit de façon cohérente
#   (table, COMPTE, REJEU-ETAPE) passe. (3) COMMIT-REJOUE n'est pas confronté au dépôt (le mode `armement` de l'outil de phase le fait). (4) Les labs exigés sont l'union des --lab et des
#   lignes de table : le prédicat des plans d'armement (46.1-05, 46.1-11) passe un --lab par lab réel. La revue de PR reste le contrôle du commit non recoupé.
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
import posixpath
import re
import stat
import sys

BORNE_RELEVE = 64 * 1024 * 1024  # octets ; au-delà : écart lecture
GATES_PAR_ETAPE = {5: ("G3", "G4"), 6: ("G3", "G4", "G4P")}
MOTIFS_MACHINE = ("/Users/", "/home/")  # affichage seulement (`sur`, conservateur : tout nom qui en contient un est masqué) ; la règle chemin-machine lit les jetons de chemin (fix-5b V2)
RACINES_MACHINE = ("/Users", "/home")
RE_JETON_CHEMIN = re.compile(r"[\w.~%+@/-]+")  # liste BLANCHE : tout autre caractère est une frontière de jeton (fail-closed : un chemin collé à un guillemet, un `=`, un `:` est lu)

# Tout nombre de la grammaire tient en 1 à 9 chiffres (fix-5b V1) : int() n'est appelé que sur un groupe ainsi borné, jamais sur un entier que la limite de conversion de
# Python >= 3.11 (4 300 chiffres) ferait lever ; un nombre plus long est une ligne malformée, nommée, comme sous toute version de Python.
RE_ETAPE = re.compile(r"REJEU-ETAPE-([0-9]{1,9}) faux-refus=([0-9]{1,9}) faux-accept=([0-9]{1,9}) refus-conforme-modele=([0-9]{1,9})")
RE_COMMIT = re.compile(r"COMMIT-REJOUE [0-9a-f]{40}")
RE_EMPREINTE = re.compile(r"EMPREINTE-ARBRE-(IDENTIQUE|DIVERGENTE) (.+)")
RE_COUVERTURE = re.compile(r"COUVERTURE-REJEU (G3|G4|G4P) n=([0-9]{1,9}) plancher=([0-9]{1,9})")
RE_GATE = re.compile(r"[A-Z][A-Z0-9]*")
# Ordre des étapes de rejeu-gates.sh (R-RELEVE-07 garde la copie identique) : la gate d'une ligne COMPTE est « hors étape » si son étape dépasse celle du relevé ; une gate rangée sous
# aucune étape (`?`, inconnue) est d'étape 0 : elle reste comptée, comme chez l'émetteur.
ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",), ("G3", "G4"), ("G4P",))
ETAPE_DE = dict((g, i + 1) for i, lot in enumerate(ORDRE_ETAPES) for g in lot)
RE_COMPTE = re.compile(r"COMPTE (\?|[A-Z0-9]+) faux-refus=([0-9]{1,9}) faux-accept=([0-9]{1,9}) refus-conforme-modele=([0-9]{1,9})( hors-etape)?")
# Jetons de la grammaire (fix-5b V4 (a)) : une ligne qui en porte un ailleurs qu'en position 0 est malformée (règle jeton-deplace) ; la SORTIE du script n'en porte jamais (elle est
# reproduite dans les relevés versionnés, puis relue : un jeton y rougirait chaque relevé non armable). `COMPTE` est un mot courant (« COMPTE RENDU.md ») : son jeton est la tête
# structurelle d'une ligne de compte, pas le mot seul.
JETONS_LITTERAUX = ("REJEU-ETAPE-", "COMMIT-REJOUE", "EMPREINTE-ARBRE-", "EMPREINTE-DIVERGENTE", "MESURE-VIDE", "COUVERTURE-REJEU")
RE_TETE_COMPTE = re.compile(r"COMPTE[ \t]+\S+[ \t]+faux-refus")

ECARTS = []


def ecart(regle, detail):
    ECARTS.append("RELEVE-ECART %s : %s" % (regle, detail))


def sur(texte):
    """Forme affichable d'un nom tiré du relevé : jamais un chemin de machine, ni un jeton de la grammaire, ni un caractère de contrôle, borné."""
    if any(t in texte for t in MOTIFS_MACHINE) or any(j in texte for j in JETONS_LITTERAUX) or RE_TETE_COMPTE.search(texte):
        return "<nom-masqué>"
    propre = "".join("?" if (ord(c) < 32 or ord(c) == 127) else c for c in texte)
    return propre if len(propre) <= 80 else propre[:77] + "..."


def racines_machine(ligne):
    """Racines de machine (/Users, /home) des chemins ABSOLUS que porte la ligne : la ligne est découpée en jetons de chemin (suites maximales de RE_JETON_CHEMIN), un jeton qui
    commence par `/` est normalisé lexicalement (barres de tête ramenées à une, `.` et `..` résolus : `//home/<c>`, `/tmp/../home/<c>` sont lus comme `/home/<c>`) et compte s'il vaut
    `/Users` ou `/home` ou s'il est dessous. Un chemin RELATIF (`src/pages/home/index.md`, `~/home/notes.md`, `docs/Users/guide.md`) n'est jamais un chemin de machine."""
    trouvees = []
    for jeton in RE_JETON_CHEMIN.findall(ligne):
        if not jeton.startswith("/"):
            continue
        norme = posixpath.normpath("/" + jeton.lstrip("/"))
        for racine in RACINES_MACHINE:
            if norme == racine or norme.startswith(racine + "/"):
                trouvees.append(racine)
    return trouvees


def jeton_deplace(ligne):
    """Vrai si la ligne porte un jeton de la grammaire ailleurs qu'en position 0 (recherche à partir de l'index 1, toute ligne, table comprise)."""
    return any(ligne.find(jeton, 1) != -1 for jeton in JETONS_LITTERAUX) or RE_TETE_COMPTE.search(ligne, 1) is not None


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

    gates = GATES_PAR_ETAPE[etape]

    # --- faits : une ligne « commence par le jeton » ou non ; conforme (grammaire exacte, aucun \r final) ou malformée
    def conforme(motif, ligne):
        return None if ligne.endswith("\r") else motif.fullmatch(ligne)

    etapes_valides, etapes_mal = [], []
    commits_valides, commits_mal = [], []
    identiques, divergentes, empreintes_mal = {}, [], []
    rejeux_divergents = []
    mesures_vides = []
    couvertures, couvertures_mal = {}, []
    comptes, comptes_mal = {}, []
    for i, ligne in numerotees:
        if ligne.startswith("REJEU-ETAPE-"):
            m = conforme(RE_ETAPE, ligne)
            if m is None:
                etapes_mal.append(i)
            else:
                etapes_valides.append((i, int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))))
        elif ligne.startswith("COMMIT-REJOUE"):
            (commits_valides if conforme(RE_COMMIT, ligne) else commits_mal).append(i)
        elif ligne.startswith("EMPREINTE-ARBRE-"):
            m = conforme(RE_EMPREINTE, ligne)
            if m is None:
                empreintes_mal.append(i)
            elif m.group(1) == "IDENTIQUE":
                identiques.setdefault(m.group(2), []).append(i)
            else:
                divergentes.append((i, m.group(2)))
        elif ligne.startswith("EMPREINTE-DIVERGENTE"):
            rejeux_divergents.append((i, ligne[len("EMPREINTE-DIVERGENTE"):].strip()))  # tout ce qui commence par le jeton est un fait : le rejeu a modifié un lab
        elif ligne.startswith("COMPTE "):
            m = conforme(RE_COMPTE, ligne)
            hors_etape = ETAPE_DE.get(m.group(1), 0) > etape if m else None
            if m is None or (m.group(5) is not None) != hors_etape:
                comptes_mal.append(i)  # hors grammaire, `\r` final, ou suffixe contraire à l'ordre des étapes
            elif not hors_etape:
                comptes.setdefault(m.group(1), []).append((i, int(m.group(2)), int(m.group(3)), int(m.group(4))))
        elif ligne.startswith("MESURE-VIDE"):
            mesures_vides.append(i)
        elif ligne.startswith("COUVERTURE-REJEU"):
            m = conforme(RE_COUVERTURE, ligne)
            if m is None or int(m.group(3)) == 0:
                couvertures_mal.append(i)
            else:
                couvertures.setdefault(m.group(1), []).append((i, int(m.group(2)), int(m.group(3))))

    de_l_etape = [e for e in etapes_valides if e[1] == etape]
    autres_etapes = [e for e in etapes_valides if e[1] != etape]
    gates_sans_compte = [g for lot in ORDRE_ETAPES[:etape] for g in lot if g not in comptes]
    somme_fr = sum(c[1] for lignes_g in comptes.values() for c in lignes_g)
    somme_fa = sum(c[2] for lignes_g in comptes.values() for c in lignes_g)
    somme_cm = sum(c[3] for lignes_g in comptes.values() for c in lignes_g)
    recoupements = []
    for i, _, a, b, c in de_l_etape:
        fautes_champs = []
        if a != somme_fr:
            fautes_champs.append("faux-refus=%d pour une somme des comptes de %d" % (a, somme_fr))
        if c != somme_cm:
            fautes_champs.append("refus-conforme-modele=%d pour une somme des comptes de %d" % (c, somme_cm))
        if b < somme_fa:  # recoupement-fa
            fautes_champs.append("faux-accept=%d sous la somme des comptes de %d" % (b, somme_fa))
        if fautes_champs:
            recoupements.append((i, " ; ".join(fautes_champs)))
    refus_non_nuls = [e for e in de_l_etape if e[2] != 0]
    accepts_non_nuls = [e for e in de_l_etape if e[3] != 0]
    labs_sans_empreinte = [lab for lab in labs if lab not in identiques]
    empreintes_doublons = [(lab, identiques[lab]) for lab in labs if len(identiques.get(lab, ())) > 1]
    gates_sans_couverture = [g for g in gates if g not in couvertures]
    gates_en_doublon = [(g, couvertures[g]) for g in gates if len(couvertures.get(g, ())) > 1]
    couvertures_courtes = [(g, i, n, p) for g in gates for (i, n, p) in couvertures.get(g, ()) if n < p]
    chemins_machine = [(i, racine) for i, ligne in numerotees for racine in racines_machine(ligne)]  # fait-chemin-machine
    jetons_deplaces = [i for i, ligne in numerotees if jeton_deplace(ligne)]

    # --- les règles : une ligne `if` marquée chacune, dont le corps appelle l'écart
    if not de_l_etape:  # releve-etape-absente
        ecart("etape-absente", "aucune ligne d'étape %d conforme à la grammaire" % etape)
    if etapes_mal:  # releve-etape-malformee
        for i in etapes_mal:
            ecart("etape-malformee", "ligne %d : ligne d'étape sans la grammaire exacte" % i)
    if len(de_l_etape) > 1:  # releve-etape-doublon
        ecart("etape-doublon", "%d lignes d'étape %d (lignes %s)" % (len(de_l_etape), etape, ",".join(str(e[0]) for e in de_l_etape)))
    if autres_etapes:  # releve-etape-autre
        for i, m, _, _, _ in autres_etapes:
            ecart("etape-autre", "ligne %d : ligne d'étape %d alors que --etape=%d" % (i, m, etape))
    if refus_non_nuls:  # releve-faux-refus
        for i, _, a, _, _ in refus_non_nuls:
            ecart("faux-refus", "ligne %d : faux-refus=%d" % (i, a))
    if accepts_non_nuls:  # releve-faux-accept
        for i, _, _, b, _ in accepts_non_nuls:
            ecart("faux-accept", "ligne %d : faux-accept=%d" % (i, b))
    if recoupements:  # releve-etape-recoupement
        for i, detail in recoupements:
            ecart("etape-recoupement", "ligne %d : %s" % (i, detail))
    if comptes_mal:  # releve-compte-malforme
        for i in comptes_mal:
            ecart("compte-malforme", "ligne %d : ligne de compte hors grammaire, avec un retour chariot final ou au suffixe contraire à l'ordre des étapes" % i)
    if gates_sans_compte:  # releve-compte-absent
        for g in gates_sans_compte:
            ecart("compte-absent", "gate %s : aucune ligne de compte conforme (gate d'une étape jusqu'à %d)" % (g, etape))
    if not commits_valides:  # releve-commit-absent
        ecart("commit-absent", "aucune ligne de commit rejoué conforme (40 hexadécimaux minuscules)")
    if commits_mal:  # releve-commit-malforme
        for i in commits_mal:
            ecart("commit-malforme", "ligne %d : ligne de commit rejoué sans la grammaire exacte" % i)
    if len(commits_valides) > 1:  # releve-commit-doublon
        ecart("commit-doublon", "%d lignes de commit rejoué conformes (lignes %s)" % (len(commits_valides), ",".join(str(i) for i in commits_valides)))
    if not labs:  # releve-labs-absents
        ecart("labs-absents", "aucun lab : ni --lab, ni ligne de table `<gate> | <lab> | …`")
    if labs_sans_empreinte or empreintes_mal:  # releve-empreinte-absente
        for lab in labs_sans_empreinte:
            ecart("empreinte-absente", "lab %s : aucune ligne d'empreinte d'arbre identique" % sur(lab))
        for i in empreintes_mal:
            ecart("empreinte-absente", "ligne %d : ligne d'empreinte d'arbre sans la grammaire exacte" % i)
    if empreintes_doublons:  # releve-empreinte-doublon
        for lab, numeros in empreintes_doublons:
            ecart("empreinte-doublon", "lab %s : %d lignes d'empreinte d'arbre identique (lignes %s)" % (sur(lab), len(numeros), ",".join(str(i) for i in numeros)))
    if divergentes:  # releve-empreinte-divergente
        for i, lab in divergentes:
            ecart("empreinte-divergente", "ligne %d : empreinte d'arbre divergente pour le lab %s" % (i, sur(lab)))
    if rejeux_divergents:  # releve-rejeu-divergent
        for i, lab in rejeux_divergents:
            ecart("rejeu-divergent", "ligne %d : le rejeu a modifié le lab %s" % (i, sur(lab) if lab else "(non nommé)"))
    if mesures_vides:  # releve-mesure-vide
        for i in mesures_vides:
            ecart("mesure-vide", "ligne %d : mesure vide (un lab sans ligne mesurée n'est jamais un vert)" % i)
    if gates_sans_couverture:  # releve-couverture-absente
        for g in gates_sans_couverture:
            ecart("couverture-absente", "gate %s : aucune ligne de couverture du rejeu conforme (plancher >= 1)" % g)
    if couvertures_mal:  # releve-couverture-malformee
        for i in couvertures_mal:
            ecart("couverture-malformee", "ligne %d : ligne de couverture du rejeu sans la grammaire exacte, ou plancher=0" % i)
    if gates_en_doublon:  # releve-couverture-doublon
        for g, lots in gates_en_doublon:
            ecart("couverture-doublon", "gate %s : %d lignes de couverture du rejeu conformes (lignes %s)" % (g, len(lots), ",".join(str(x[0]) for x in lots)))
    if couvertures_courtes:  # releve-couverture-insuffisante
        for g, i, n, p in couvertures_courtes:
            ecart("couverture-insuffisante", "gate %s ligne %d : n=%d sous plancher=%d" % (g, i, n, p))
    if jetons_deplaces:  # releve-jeton-deplace
        for i in jetons_deplaces:
            ecart("jeton-deplace", "ligne %d : jeton de la grammaire ailleurs qu'en tête de ligne" % i)
    if chemins_machine:  # releve-chemin-machine
        for i, racine in chemins_machine:
            ecart("chemin-machine", "ligne %d : chemin absolu de machine (famille %s)" % (i, racine.strip("/").lower()))
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
