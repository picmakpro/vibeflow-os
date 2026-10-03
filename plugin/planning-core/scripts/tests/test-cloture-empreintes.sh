#!/usr/bin/env bash
# test-cloture-empreintes.sh — le modèle de la pose d'un verdict : prédicat « livrable présent », empreinte composée des
# livrables, deux empreintes du VERDICT.md, plafond de trois tentatives, forme d'unité de juge (Phase 46, 46-01 ; CLOT-01,
# CLOT-03, CLOT-05 ; P46-D-03, P46-D-03a, P46-D-05, P46-D-06a, P46-D-10, P46-D-12).
#
# Familles :
#   R-EMP-01  le prédicat « livrable présent » (lstat par composant, vide, lien, FIFO, dossier, exclusions)
#   R-EMP-02  l'empreinte des livrables (stable, indépendante de l'ordre, sensible au contenu, insensible aux exclus et aux liens)
#   R-EMP-03  les bornes (2000 entrées, 128 Mio) : refus explicite, jamais une empreinte partielle ; les octets LUS seuls la déclenchent
#   R-EMP-04  trois copies ast-identiques du bloc partagé ET de ses entrées (parseur de frontmatter, entree_ecrit_valide,
#             _valeurs_ecrit, SANS_SUIVI_DE_LIEN) : 27 noms ; mêmes verdicts du prédicat, de l'empreinte et de `entrees_du_plan`
#   R-EMP-05  la commande pose `hash` et `hash_livrables`, relus identiques par le parseur, six clés dans l'ordre
#   R-EMP-06  la commande refuse (64) un livrable absent, vide ou lien, un ecrit: invalide, une borne dépassée
#   R-EMP-07  aucun refus ne porte le chemin absolu du lab, « no such file » ni « can't open » (P46-D-10)
#   R-EMP-08  point fixe : une entrée `ecrit:` qui est ou contient le dossier de l'unité est refusée (64, « dossier de l'unité »),
#             sans verdict, temporaire, tentative ni dérogation consommée ; une entrée dans l'unité ou voisine est posée (point fixe)
#   R-EMP-09  budget commun à toutes les entrées d'un PLAN.md (`livrables_presents`) : aucune entrée après une borne n'est présente
#   R-EMP-10  nom d'entrée non UTF-8 ou porteur d'un caractère de contrôle : livrable `illisible`, jamais une empreinte
#   R-EMP-11  l'empreinte ne dépend pas de l'ordre d'énumération (trois ordres provoqués, texte canonique recalculé par la suite)
#   R-EMP-12  lecture sans lien à aucun composant (ouvertures chaînées, O_NOFOLLOW), sans blocage sur un FIFO (O_NONBLOCK) ; le
#             repli sans descripteur de dossier rend la même empreinte
#   R-PLAF-01 à 04  plafond de trois tentatives (code 65, VERDICT.md inchangé), dérogation PLAFOND à usage unique consommée sous
#             verrou avant l'écriture, constante du code (jamais un fichier du lab ni l'environnement), ordre prouvé par l'ast
#   R-JUGE-FORME-01, 02  la forme d'unité `.planning/juges/<juge>` (artefact haché SORTIE-PIEGEE.md, pas de hash_livrables, plafond
#             appliqué) et ses jumeaux négatifs (toute autre forme reste refusée, une unité de cycle garde sa règle)
#   MUT-*     chaque garde est tuée par un mutant à motif unique : la trace du rouge (assertion, attendu, obtenu) est imprimée ;
#             un mutant tué par la durée est interdit, il meurt par structure ou par verdict (EMP-*, VERDICT-*, PLAF-*, JUGE-*,
#             EMP-ENTREES-DEQUOTE, EMP-NOFOLLOW-AST, EMP-CHAINE-AST, UNITE-REFUS, BUDGET-COMMUN, NOM-SAIN-*, OCTETS-LUS, TRI,
#             LIEN-INTERMEDIAIRE, NONBLOCK, DIRFD) ; le résultat de l'original est mémoïsé par contrôle
#   « ~ »     une ligne qui commence par « ~ » signale un cas non exerçable sur le système courant : ni vert, ni rouge
#
# Sections (VF_CLOT_SECTIONS, facultatif) : emp, ast, plaf, juge, mut. Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`,
# ni `readlink -f`, ni `date -d` ; `cmp -s` jamais `diff` ; tout le travail fin est fait par Python (PYBIN). Lançable depuis tout
# cwd, par `bash <suite>` (jamais sourcée). Piège CI (`bash -e {0}`) : jamais `commande && { … }` nu.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-cloture-empreintes] python3 requis" >&2; exit 1; fi
    ;;
esac

pass=0; fail=0
ko() {
  echo "  ✗ $1"
  echo "    assertion : $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
T_DEBUT="$(date +%s)"

AIDES="$WORK/aides.py"
cat > "$AIDES" <<'PY_AIDES_CLOTURE_EMP_EOF'
import ast
import hashlib
import json
import os
import re
import shutil
import signal
import stat
import subprocess
import sys
import time

MARQUEUR_POSER = "PY_POSER_VERDICT_EOF"
UNITE = ".planning/cycles/01-c/phases/01-p"
SCRIPTS_COPIES = ("poser-verdict.sh", "planning-hook.sh", "recalc-planning.sh", "deroger-gate.sh")
TROIS_COPIES = (("planning-hook.sh", "PY_PLANNING_HOOK_EOF"), ("poser-verdict.sh", MARQUEUR_POSER),
                ("recalc-planning.sh", "PY_RECALC_PLANNING_EOF"))


def ok(libelle):
    print("  ✓ " + libelle)


def ko(libelle, assertion, attendu, obtenu):
    print("  ✗ " + libelle)
    print("    assertion : " + str(assertion))
    print("    attendu   : " + str(attendu))
    print("    obtenu    : " + str(obtenu))


def okmut(ident, trace):
    print("  ✓ MUT-%s TUÉ — %s" % (ident, trace))


def komut(ident, assertion, attendu, obtenu):
    print("  ✗ MUT-%s NON TUÉ" % ident)
    print("    assertion : " + assertion)
    print("    attendu (original) : " + attendu)
    print("    obtenu (mutant)     : " + obtenu)


def court(texte, n=220):
    if isinstance(texte, bytes):
        texte = texte.decode("utf-8", "replace")
    texte = str(texte).replace("\n", "\\n")
    return texte if len(texte) <= n else texte[:n] + "…(+" + str(len(texte) - n) + ")"


def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "wb") as fh:
        fh.write(contenu if isinstance(contenu, bytes) else contenu.encode("utf-8"))


def octets(chemin):
    with open(chemin, "rb") as fh:
        return fh.read()


class Ctx:
    def __init__(self, scripts_dir, work):
        self.scripts_dir = scripts_dir
        self.work = work
        self.home = os.path.join(work, "home")
        os.makedirs(self.home, exist_ok=True)
        self._n = 0
        self.memo = {}
        self.notes = []

    def unique(self, prefixe):
        self._n += 1
        return os.path.join(self.work, prefixe + "-" + str(self._n))

    def env(self):
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.home}
        if os.environ.get("TMPDIR"):
            env["TMPDIR"] = os.environ["TMPDIR"]
        return env


def corps_python(texte, marqueur):
    corps, dedans = [], False
    for ligne in texte.split("\n"):
        if ligne == marqueur:
            dedans = False
        if dedans:
            corps.append(ligne)
        if ligne.endswith("<<'" + marqueur + "'"):
            dedans = True
    return "\n".join(corps) + "\n"


def charger_bloc(chemin_script, marqueur=MARQUEUR_POSER):
    """Espace de noms du corps Python embarqué d'un script, sans l'appel final à main() : le bloc partagé y est chargé tel
    qu'il est livré, jamais réécrit dans la suite."""
    arbre = ast.parse(corps_python(open(chemin_script, encoding="utf-8").read(), marqueur))
    arbre.body = [n for n in arbre.body
                  if not (isinstance(n, ast.Expr) and isinstance(n.value, ast.Call) and getattr(n.value.func, "id", "") == "main")]
    ns = {"__name__": "bloc_charge"}
    exec(compile(arbre, chemin_script, "exec"), ns)
    return ns


def lancer(ctx, dossier, nom, args, env_extra=None):
    env = ctx.env()
    if env_extra:
        env.update(env_extra)
    p = subprocess.run(["bash", os.path.join(dossier, nom)] + list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=env, cwd=ctx.work, timeout=120)
    return p.returncode, p.stdout, p.stderr


def plan_md(entrees):
    if entrees is None:
        return "---\nauteur: x\n---\n"
    if entrees == "liste-vide":
        return "---\necrit: []\n---\n"
    if len(entrees) == 1:
        return "---\necrit: %s\n---\n" % entrees[0]
    return "---\necrit:\n" + "".join("  - %s\n" % e for e in entrees) + "---\n"


def lab_neuf(ctx, nom="lab", entrees=("livrables/rapport.md", "donnees"), unite=UNITE):
    """Lab adhérent jetable : une unité de phase, un PLAN.md qui déclare `entrees`, un fichier et un dossier de livrables non vides."""
    lab = ctx.unique(nom)
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}\n')
    ecrire(os.path.join(lab, unite, "PLAN.md"), plan_md(entrees))
    ecrire(os.path.join(lab, "livrables", "rapport.md"), "x\n")
    ecrire(os.path.join(lab, "donnees", "a.txt"), "A\n")
    ecrire(os.path.join(lab, "donnees", "sous", "b.txt"), "B\n")
    return lab


def poser_cmd(ctx, dossier, lab, tentative, unite=UNITE, juge="vf-design-judge", extra=(), env_extra=None):
    args = ["--unite=" + os.path.join(lab, unite), "--juge=" + juge, "--tentative=" + str(tentative), "--score=8/10",
            "--constat=critere-a::passé"] + list(extra)
    return lancer(ctx, dossier, "poser-verdict.sh", args, env_extra)


def deroger_cmd(ctx, dossier, lab, gate, chemin, raison="cas de test du plafond de tentatives"):
    args = ["--lab=" + lab, "--gate=" + gate, "--chemin=" + chemin, "--qui=willy", "--canal=AskUserQuestion session principale",
            "--date=2026-10-03", "--raison=" + raison]
    return lancer(ctx, dossier, "deroger-gate.sh", args)


def journal_derogations(lab):
    chemin = os.path.join(lab, ".planning", "derogations-gates.log")
    if not os.path.exists(chemin):
        return []
    return [l for l in octets(chemin).decode("utf-8").split("\n") if l]


def verdicts_ecrits(lab):
    return [os.path.join(dp, f) for dp, _dn, fs in os.walk(os.path.join(lab, ".planning")) for f in fs
            if f == "VERDICT.md" or f.startswith(".VERDICT.")]


def copie_bornes(ctx, dossier, fichiers=10, octets_max=4096):
    """Dossier jetable portant poser-verdict.sh dont les deux bornes du bloc partagé sont abaissées (chaque constante exactement
    une fois) : les cas de bornes se jouent sans fabriquer 2000 fichiers ni 128 Mio."""
    texte = open(os.path.join(dossier, "poser-verdict.sh"), encoding="utf-8").read()
    for motif, remplacement in (("BORNE_FICHIERS_LIVRABLES = 2000\n", "BORNE_FICHIERS_LIVRABLES = %d\n" % fichiers),
                                ("BORNE_OCTETS_LIVRABLES = 134217728\n", "BORNE_OCTETS_LIVRABLES = %d\n" % octets_max)):
        if texte.count(motif) != 1:
            raise RuntimeError("constante attendue une fois : %r (%d)" % (motif, texte.count(motif)))
        texte = texte.replace(motif, remplacement)
    d = ctx.unique("bornes")
    os.makedirs(d, exist_ok=True)
    chemin = os.path.join(d, "poser-verdict.sh")
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(texte)
    os.chmod(chemin, 0o755)
    return d


# --- R-EMP-01 : le prédicat « livrable présent » ---------------------------------------------------------------------
def cas_predicat(lab):
    base = os.path.join(lab, "cas")
    ecrire(os.path.join(base, "plein.md"), "x\n")
    ecrire(os.path.join(base, "vide.md"), "")
    os.symlink("plein.md", os.path.join(base, "lien-plein"))
    os.symlink("cible-absente.md", os.path.join(base, "lien-pendant"))
    ecrire(os.path.join(base, "reel", "rapport.md"), "x\n")
    os.symlink("reel", os.path.join(base, "liens"))
    os.makedirs(os.path.join(base, "d-vide"))
    ecrire(os.path.join(base, "d-zeros", "a.md"), "")
    ecrire(os.path.join(base, "d-zeros", "b.md"), "")
    ecrire(os.path.join(base, "d-ds", ".DS_Store"), "x")
    ecrire(os.path.join(base, "d-ds", "Thumbs.db"), "x")
    ecrire(os.path.join(base, "d-ds", "desktop.ini"), "x")
    ecrire(os.path.join(base, "d-sous", "sub", "x.md"), "x\n")
    ecrire(os.path.join(base, "d-plein", "a.md"), "x\n")
    ecrire(os.path.join(base, "d-lien-interne", "vide.md"), "")
    os.symlink("../plein.md", os.path.join(base, "d-lien-interne", "l"))
    if hasattr(os, "mkfifo"):
        os.mkfifo(os.path.join(base, "fifo"))
    cas = [("fichier non vide", "cas/plein.md", "present"),
           ("fichier de 0 octet", "cas/vide.md", "vide"),
           ("lien vers un fichier non vide", "cas/lien-plein", "lien"),
           ("lien pendant", "cas/lien-pendant", "lien"),
           ("composant intermédiaire lien (liens/rapport.md)", "cas/liens/rapport.md", "lien"),
           ("lien terminal vers un dossier", "cas/liens", "lien"),
           ("dossier vide", "cas/d-vide", "vide"),
           ("dossier dont tous les fichiers font 0 octet", "cas/d-zeros", "vide"),
           ("dossier qui ne contient que .DS_Store, Thumbs.db et desktop.ini non vides", "cas/d-ds", "vide"),
           ("dossier dont le seul contenu non vide est un lien interne", "cas/d-lien-interne", "vide"),
           ("dossier dont un sous-dossier porte un fichier non vide", "cas/d-sous", "present"),
           ("dossier non vide", "cas/d-plein", "present"),
           ("dossier non vide, barre finale", "cas/d-plein/", "present"),
           ("entrée absente", "cas/absent.md", "absent"),
           ("composant intermédiaire qui est un fichier", "cas/plein.md/x", "absent"),
           ("entrée « . » (la racine du lab n'est pas un livrable)", ".", "absent")]
    if hasattr(os, "mkfifo"):
        cas.append(("FIFO", "cas/fifo", "absent"))
    return cas


def controle_emp_01(ctx, dossier):
    lab = lab_neuf(ctx, "emp01")
    cas = cas_predicat(lab)
    fautes = []
    for script, marqueur in TROIS_COPIES:
        ns = charger_bloc(os.path.join(dossier, script), marqueur)
        for nom, entree, attendu in cas:
            statut, detail = ns["livrables_presents"](lab, [entree])[0][1:]
            if statut != attendu:
                fautes.append("%s, cas « %s » (%s) : obtenu %s, attendu %s" % (script, nom, entree, statut, attendu))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d cas du prédicat conformes dans les trois copies (fichier plein, vide, lien terminal et intermédiaire, "
                          "pendant, dossier vide, de zéros, d'exclus, de lien interne, imbriqué, absent, FIFO) avec leurs jumeaux non vides" % len(cas))


# --- R-EMP-02 : l'empreinte des livrables ----------------------------------------------------------------------------
ENTREES_EMP = ["livrables/rapport.md", "donnees"]


def controle_emp_02(ctx, dossier):
    ns = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    emp = ns["empreinte_livrables"]
    lab = lab_neuf(ctx, "emp02")
    fautes = []
    s1, e1 = emp(lab, ENTREES_EMP)
    s2, e2 = emp(lab, ENTREES_EMP)
    if s1 != "ok" or not re.fullmatch(r"[0-9a-f]{64}", e1 or ""):
        return False, "empreinte de base : %s %s" % (s1, court(e1))
    if (s2, e2) != (s1, e1):
        fautes.append("empreinte instable sur deux calculs")
    if emp(lab, list(reversed(ENTREES_EMP)))[1] != e1:
        fautes.append("l'ordre des entrées change l'empreinte")
    if emp(lab, ENTREES_EMP + ["donnees/", "./livrables/rapport.md"])[1] != e1:
        fautes.append("un doublon ou une forme non normalisée change l'empreinte")
    if emp(lab, ["livrables/rapport.md"])[1] == e1:
        fautes.append("un sous-ensemble d'entrées rend la même empreinte")
    # un octet modifié dans un fichier du dossier la change
    avant = octets(os.path.join(lab, "donnees", "sous", "b.txt"))
    ecrire(os.path.join(lab, "donnees", "sous", "b.txt"), "C\n")
    if emp(lab, ENTREES_EMP)[1] == e1:
        fautes.append("un octet modifié dans un fichier du dossier ne change pas l'empreinte")
    ecrire(os.path.join(lab, "donnees", "sous", "b.txt"), avant)
    if emp(lab, ENTREES_EMP)[1] != e1:
        fautes.append("le contenu restauré ne rend pas l'empreinte d'origine")
    # un octet modifié dans le fichier déclaré la change
    ecrire(os.path.join(lab, "livrables", "rapport.md"), "y\n")
    if emp(lab, ENTREES_EMP)[1] == e1:
        fautes.append("un octet modifié dans le fichier déclaré ne change pas l'empreinte")
    ecrire(os.path.join(lab, "livrables", "rapport.md"), "x\n")
    # un fichier ordinaire ajouté la change (même vide)
    for nom, contenu in (("donnees/nouveau.txt", "N\n"), ("donnees/sous/vide.txt", "")):
        ecrire(os.path.join(lab, nom), contenu)
        if emp(lab, ENTREES_EMP)[1] == e1:
            fautes.append("un fichier ordinaire ajouté (%s) ne change pas l'empreinte" % nom)
        os.remove(os.path.join(lab, nom))
    # un .DS_Store, Thumbs.db ou desktop.ini ajouté (non vide) ne la change pas ; un nom voisin la change (jumeau)
    for nom in ("donnees/.DS_Store", "donnees/sous/.DS_Store", "donnees/Thumbs.db", "donnees/sous/desktop.ini"):
        ecrire(os.path.join(lab, nom), "poubelle du système\n")
        if emp(lab, ENTREES_EMP)[1] != e1:
            fautes.append("un %s ajouté (nom exclu) change l'empreinte" % nom)
        os.remove(os.path.join(lab, nom))
    ecrire(os.path.join(lab, "donnees", ".DS_Store2"), "x\n")
    if emp(lab, ENTREES_EMP)[1] == e1:
        fautes.append("un nom voisin de .DS_Store (.DS_Store2) ne change pas l'empreinte")
    os.remove(os.path.join(lab, "donnees", ".DS_Store2"))
    # le contenu de la cible d'un lien interne ne la change pas, l'ajout du lien non plus
    ecrire(os.path.join(lab, "hors-dossier", "cible.txt"), "CIBLE-1\n")
    os.symlink("../hors-dossier/cible.txt", os.path.join(lab, "donnees", "lien-interne"))
    if emp(lab, ENTREES_EMP)[1] != e1:
        fautes.append("un lien interne ajouté change l'empreinte")
    ecrire(os.path.join(lab, "hors-dossier", "cible.txt"), "CIBLE-2 très différente\n")
    if emp(lab, ENTREES_EMP)[1] != e1:
        fautes.append("le contenu de la cible d'un lien interne change l'empreinte")
    # un livrable qui n'est pas présent fait échouer le calcul : jamais une empreinte
    os.remove(os.path.join(lab, "livrables", "rapport.md"))
    statut, detail = emp(lab, ENTREES_EMP)
    if statut != "absent" or detail != "livrables/rapport.md":
        fautes.append("livrable absent : obtenu (%s, %s), attendu (absent, livrables/rapport.md)" % (statut, detail))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "empreinte de 64 hexadécimaux, stable, indépendante de l'ordre et des doublons, changée par un octet "
                          "modifié ou un fichier ajouté, inchangée par .DS_Store, Thumbs.db, desktop.ini et par un lien interne")


# --- R-EMP-03 : les bornes ---------------------------------------------------------------------------------------------
def valeurs_livrees(dossier):
    corps = corps_python(open(os.path.join(dossier, "poser-verdict.sh"), encoding="utf-8").read(), MARQUEUR_POSER)
    valeurs = {}
    for noeud in ast.parse(corps).body:
        if isinstance(noeud, ast.Assign) and isinstance(noeud.targets[0], ast.Name) \
                and noeud.targets[0].id in ("BORNE_FICHIERS_LIVRABLES", "BORNE_OCTETS_LIVRABLES"):
            valeurs[noeud.targets[0].id] = ast.literal_eval(noeud.value)
    return valeurs


def controle_emp_03(ctx, dossier):
    fautes = []
    valeurs = valeurs_livrees(dossier)
    if valeurs != {"BORNE_FICHIERS_LIVRABLES": 2000, "BORNE_OCTETS_LIVRABLES": 134217728}:
        fautes.append("valeurs livrées des bornes : %s (attendu 2000 et 134217728)" % valeurs)
    d2 = copie_bornes(ctx, dossier)
    ns = charger_bloc(os.path.join(d2, "poser-verdict.sh"))
    emp = ns["empreinte_livrables"]
    lab = lab_neuf(ctx, "emp03")

    def dossier_de(nom, n, taille=2):
        for i in range(n):
            ecrire(os.path.join(lab, nom, "f%02d.txt" % i), "x" * taille)
        return nom

    cas = [("10 fichiers (la borne)", [dossier_de("d10", 10)], "ok", None),
           ("11 fichiers", [dossier_de("d11", 11)], "borne", "10 fichiers"),
           ("12 fichiers répartis sur deux entrées (budget commun)", [dossier_de("da", 6), dossier_de("db", 6)], "borne", "10 fichiers"),
           ("5 fichiers + 5 fichiers (10 au total, budget commun)", [dossier_de("dc", 5), dossier_de("dd", 5)], "ok", None)]
    ecrire(os.path.join(lab, "o4096.bin"), b"x" * 4096)
    ecrire(os.path.join(lab, "o4097.bin"), b"x" * 4097)
    ecrire(os.path.join(lab, "oa", "a.bin"), b"x" * 3000)
    ecrire(os.path.join(lab, "oa", "b.bin"), b"x" * 3000)
    cas += [("fichier de 4096 octets (la borne)", ["o4096.bin"], "ok", None),
            ("fichier de 4097 octets", ["o4097.bin"], "borne", "4096 octets"),
            ("dossier de deux fichiers de 3000 octets", ["oa"], "borne", "4096 octets")]
    for nom, entrees, attendu, mot in cas:
        statut, detail = emp(lab, entrees)
        if attendu == "ok":
            if statut != "ok" or not re.fullmatch(r"[0-9a-f]{64}", detail or ""):
                fautes.append("%s : obtenu (%s, %s), attendu une empreinte" % (nom, statut, court(detail)))
        else:
            if statut != "borne" or mot not in (detail or "") or re.fullmatch(r"[0-9a-f]{64}", detail or ""):
                fautes.append("%s : obtenu (%s, %s), attendu un refus (borne) qui nomme « %s » et aucune empreinte" % (nom, statut, court(detail), mot))
    # le prédicat seul applique la même borne
    statut, detail = ns["livrables_presents"](lab, ["d11"])[0][1:]
    if statut != "borne":
        fautes.append("livrables_presents sur 11 fichiers : %s, attendu borne" % statut)
    # les octets LUS seuls déclenchent la borne : budget [entrées, octets annoncés, octets lus] = [0, 0, 4090], 10 octets lus de plus
    ecrire(os.path.join(lab, "f.bin"), b"x" * 10)
    rendu = ns["_hacher_livrables"](lab, [("f.bin", 0)], [0, 0, 4090])
    if rendu[0] != "borne" or "4096 octets" not in str(rendu[1]):
        fautes.append("octets lus : 10 octets lus au-delà de 4090 déjà lus (borne 4096, octets annoncés 0) : obtenu %s, attendu borne "
                      "« 4096 octets »" % (rendu,))
    rendu = ns["_hacher_livrables"](lab, [("f.bin", 0)], [0, 0, 4000])
    if rendu[0] != "ok":
        fautes.append("octets lus : jumeau sous la borne (4000 + 10 octets lus) : obtenu %s, attendu ok" % (rendu,))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "valeurs livrées 2000 et 134217728 ; bornes abaissées à 10 et 4096 : la borne passe, une unité de plus est un "
                          "refus explicite qui la nomme, budget commun à toutes les entrées, aucune empreinte partielle ; les octets lus "
                          "seuls (4090 + 10) franchissent la borne, leur jumeau (4000 + 10) passe")


# --- R-EMP-05 : la commande pose les deux empreintes -------------------------------------------------------------
def empreinte_independante(lab, entrees):
    """Texte canonique de P46-D-03a recalculé SANS le bloc partagé : entrées normalisées, dédoublonnées, triées ; fichier :
    `fichier<TAB>chemin<TAB>sha256` ; dossier : `dossier<TAB>entrée` puis ses fichiers réguliers triés par chemin relatif."""
    lignes = []
    for entree in sorted(set("/".join(c for c in e.split("/") if c not in ("", ".")) for e in entrees)):
        chemin = os.path.join(lab, entree)
        if os.path.isdir(chemin):
            lignes.append("dossier\t" + entree)
            rels = []
            for dp, dn, fs in os.walk(chemin):
                dn[:] = [d for d in dn if not os.path.islink(os.path.join(dp, d))]
                for f in fs:
                    p = os.path.join(dp, f)
                    if f in (".DS_Store", "Thumbs.db", "desktop.ini") or os.path.islink(p) or not os.path.isfile(p):
                        continue
                    rels.append(entree + "/" + os.path.relpath(p, chemin).replace(os.sep, "/"))
            for rel in sorted(rels):
                lignes.append("fichier\t" + rel + "\t" + hashlib.sha256(octets(os.path.join(lab, rel))).hexdigest())
        else:
            lignes.append("fichier\t" + entree + "\t" + hashlib.sha256(octets(chemin)).hexdigest())
    return hashlib.sha256(("\n".join(lignes) + "\n").encode("utf-8")).hexdigest()


def controle_emp_05(ctx, dossier):
    lab = lab_neuf(ctx, "emp05")
    rc, out, err = poser_cmd(ctx, dossier, lab, 1)
    chemin = os.path.join(lab, UNITE, "VERDICT.md")
    if rc != 0 or not os.path.isfile(chemin):
        return False, "la commande n'a pas écrit : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    ns = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    statut_p, donnees = ns["lire_frontmatter"](octets(chemin).decode("utf-8"))
    lignes = octets(chemin).decode("utf-8").split("\n")
    fin = lignes.index("---", 1)
    cles = [l.split(":")[0] for l in lignes[1:fin] if l and not l.startswith(" ")]
    h_plan = hashlib.sha256(octets(os.path.join(lab, UNITE, "PLAN.md"))).hexdigest()
    h_bloc = ns["empreinte_livrables"](lab, ENTREES_EMP)
    h_indep = empreinte_independante(lab, ENTREES_EMP)
    fautes = []
    if cles != ["juge", "hash", "hash_livrables", "tentative", "score", "constats"]:
        fautes.append("clés du frontmatter : %s" % cles)
    if statut_p != "ok" or donnees.get("hash") != h_plan:
        fautes.append("hash relu %r, attendu le sha256 du PLAN.md %s" % (donnees.get("hash"), h_plan))
    if h_bloc[0] != "ok" or donnees.get("hash_livrables") != h_bloc[1]:
        fautes.append("hash_livrables relu %r, attendu l'empreinte du bloc partagé %s" % (donnees.get("hash_livrables"), h_bloc))
    if donnees.get("hash_livrables") != h_indep:
        fautes.append("hash_livrables relu %r, attendu l'empreinte du texte canonique recalculé par la suite %s" % (donnees.get("hash_livrables"), h_indep))
    if donnees.get("hash") == donnees.get("hash_livrables"):
        fautes.append("les deux empreintes sont égales")
    return (not fautes), ("; ".join(fautes) if fautes else
                          "code 0 ; hash = sha256 du PLAN.md (hashlib) ; hash_livrables = empreinte du bloc partagé et du texte canonique "
                          "recalculé par la suite ; six clés dans l'ordre juge, hash, hash_livrables, tentative, score, constats")


# --- R-EMP-06 et R-EMP-07 : les refus de la pose -------------------------------------------------------------------
def cas_refus(ctx, dossier):
    """[(nom, lab, mot attendu dans le message, dossier de scripts)] : un défaut par lab, jumeau valide en tête."""
    d_bornes = copie_bornes(ctx, dossier)
    cas = []

    def neuf(nom, entrees=("livrables/rapport.md", "donnees")):
        return lab_neuf(ctx, "emp06-" + nom, entrees)

    lab = neuf("absent")
    os.remove(os.path.join(lab, "livrables", "rapport.md"))
    cas.append(("livrable absent", lab, "livrables/rapport.md", dossier))
    lab = neuf("vide")
    ecrire(os.path.join(lab, "livrables", "rapport.md"), "")
    cas.append(("livrable vide", lab, "livrables/rapport.md", dossier))
    lab = neuf("lien")
    os.remove(os.path.join(lab, "livrables", "rapport.md"))
    os.symlink("../donnees/a.txt", os.path.join(lab, "livrables", "rapport.md"))
    cas.append(("livrable lien", lab, "livrables/rapport.md", dossier))
    lab = neuf("lien-inter", ("liens/rapport.md",))
    os.symlink("livrables", os.path.join(lab, "liens"))
    cas.append(("livrable derrière un lien intermédiaire", lab, "liens/rapport.md", dossier))
    lab = neuf("dossier-vide")
    shutil.rmtree(os.path.join(lab, "donnees"))
    os.makedirs(os.path.join(lab, "donnees"))
    cas.append(("dossier livrable vide", lab, "donnees", dossier))
    cas.append(("ecrit: absent du PLAN.md", _plan_autre(ctx, None), "ecrit:", dossier))
    cas.append(("ecrit: absolu", _plan_autre(ctx, ("/etc/passwd",)), "ecrit:", dossier))
    cas.append(("ecrit: avec ..", _plan_autre(ctx, ("../hors.md",)), "ecrit:", dossier))
    cas.append(("ecrit: avec un motif", _plan_autre(ctx, ("livrables/*.md",)), "ecrit:", dossier))
    cas.append(("ecrit: liste vide", _plan_autre(ctx, "liste-vide"), "ecrit:", dossier))
    lab = neuf("sans-frontmatter")
    ecrire(os.path.join(lab, UNITE, "PLAN.md"), "pas de frontmatter\n")
    cas.append(("PLAN.md sans frontmatter", lab, "ecrit:", dossier))
    lab = neuf("borne-fichiers", ("donnees",))
    for i in range(11):
        ecrire(os.path.join(lab, "donnees", "g%02d.txt" % i), "x")
    cas.append(("borne de fichiers dépassée", lab, "BORNE_FICHIERS_LIVRABLES", d_bornes))
    lab = neuf("borne-octets", ("livrables/rapport.md",))
    ecrire(os.path.join(lab, "livrables", "rapport.md"), b"x" * 4097)
    cas.append(("borne d'octets dépassée", lab, "BORNE_OCTETS_LIVRABLES", d_bornes))
    return cas


def _plan_autre(ctx, entrees):
    lab = lab_neuf(ctx, "emp06-plan")
    ecrire(os.path.join(lab, UNITE, "PLAN.md"), plan_md(entrees))
    return lab


def refus_pose(ctx, dossier):
    if ("refus", dossier) not in ctx.memo:
        sortie = []
        for nom, lab, mot, d in cas_refus(ctx, dossier):
            rc, out, err = poser_cmd(ctx, d, lab, 1)
            sortie.append((nom, lab, mot, rc, out, err))
        ctx.memo[("refus", dossier)] = sortie
    return ctx.memo[("refus", dossier)]


def controle_emp_06(ctx, dossier):
    fautes = []
    # jumeaux valides : le lab sans défaut est posé, et la borne exacte aussi
    lab = lab_neuf(ctx, "emp06-jumeau")
    rc, out, err = poser_cmd(ctx, dossier, lab, 1)
    if rc != 0:
        fautes.append("jumeau valide refusé : rc=%d %s" % (rc, court(err)))
    d_bornes = copie_bornes(ctx, dossier)
    lab = lab_neuf(ctx, "emp06-borne-exacte", ("donnees",))
    shutil.rmtree(os.path.join(lab, "donnees"))
    for i in range(10):
        ecrire(os.path.join(lab, "donnees", "g%02d.txt" % i), "x")
    rc, out, err = poser_cmd(ctx, d_bornes, lab, 1)
    if rc != 0:
        fautes.append("10 fichiers à la borne de 10 refusés : rc=%d %s" % (rc, court(err)))
    sorties = refus_pose(ctx, dossier)
    for nom, lab, mot, rc, out, err in sorties:
        texte = err.decode("utf-8", "replace")
        if rc != 64:
            fautes.append("%s : code %d, attendu 64 (stderr %s)" % (nom, rc, court(err)))
        elif verdicts_ecrits(lab):
            fautes.append("%s : un VERDICT.md ou son temporaire a été écrit : %s" % (nom, [os.path.basename(e) for e in verdicts_ecrits(lab)]))
        elif mot not in texte:
            fautes.append("%s : le message ne nomme pas « %s » : %s" % (nom, mot, court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d refus en code 64 (livrable absent, vide, lien, lien intermédiaire, dossier vide, ecrit: absent, absolu, avec "
                          "..., motif, liste vide, sans frontmatter, borne de fichiers, borne d'octets), le message nomme l'entrée ou "
                          "la borne, aucun VERDICT.md écrit ; les jumeaux valides (lab entier, borne exacte) sont posés" % len(sorties))


def controle_emp_07(ctx, dossier):
    fautes = []
    n = 0
    for nom, lab, mot, rc, out, err in refus_pose(ctx, dossier):
        texte = (out + err).decode("utf-8", "replace")
        bas = texte.lower()
        for chemin in {lab, os.path.realpath(lab), os.path.dirname(os.path.realpath(lab)), ctx.work}:
            if chemin and chemin in texte:
                fautes.append("%s : le message porte le chemin absolu %s" % (nom, chemin))
        for interdit in ("no such file", "can't open", "cannot open", "traceback"):
            if interdit in bas:
                fautes.append("%s : le message contient « %s » : %s" % (nom, interdit, court(texte)))
        if re.search(r"(^|[\s'\"(])/(Users|home|private|var|tmp|etc)/", texte):
            fautes.append("%s : le message porte un chemin absolu : %s" % (nom, court(texte)))
        n += 1
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d refus : ni le chemin absolu du lab, ni un chemin absolu hors du lab, ni « no such file », ni « can't open », "
                          "ni trace Python" % n)


# --- Mandataires de `os` injectés dans l'espace de noms d'un bloc chargé (ordre provoqué, compteur, espion) -----------------
class OsMandataire:
    """Module `os` dont quelques attributs sont remplacés ; tout le reste est délégué au vrai module. Injecté dans l'espace de noms
    d'un bloc chargé par `charger_bloc` (`ns["os"] = …`) : le bloc livré n'est jamais réécrit."""

    def __init__(self, **surcharges):
        object.__setattr__(self, "_surcharges", surcharges)

    def __getattr__(self, nom):
        surcharges = object.__getattribute__(self, "_surcharges")
        if nom in surcharges:
            return surcharges[nom]
        return getattr(os, nom)


class _Enumeration:
    """Résultat d'un `scandir` réécrit : itérable et gestionnaire de contexte, comme l'itérateur du vrai `os.scandir`."""

    def __init__(self, entrees):
        self.entrees = list(entrees)

    def __enter__(self):
        return iter(self.entrees)

    def __exit__(self, *_exc):
        return False

    def __iter__(self):
        return iter(self.entrees)


def scandir_ordonne(ordre):
    """`scandir` qui rend les entrées dans un ordre PROVOQUÉ (naturel = trié par nom, inverse, rotation d'un cran) : jamais
    l'ordre natif du système de fichiers."""
    def scandir(chemin):
        with os.scandir(chemin) as it:
            entrees = sorted(it, key=lambda e: e.name)
        if ordre == "inverse":
            entrees.reverse()
        elif ordre == "rotation" and entrees:
            entrees = entrees[1:] + entrees[:1]
        return _Enumeration(entrees)
    return scandir


class TropDEntrees(Exception):
    """Levée par le compteur au-delà du plafond d'entrées de dossier énumérées : borne le coût d'un mutant (jamais une OSError,
    que le bloc rattraperait en `illisible`)."""


def scandir_compteur(compteur, plafond):
    def scandir(chemin):
        with os.scandir(chemin) as it:
            entrees = list(it)
        compteur[0] += len(entrees)
        if compteur[0] > plafond:
            raise TropDEntrees("%d entrées de dossier énumérées (plafond %d)" % (compteur[0], plafond))
        return _Enumeration(entrees)
    return scandir


class OuvertureBloquee(Exception):
    """Levée par l'alarme quand une ouverture de FIFO bloque (jamais une OSError)."""


# --- R-EMP-08 : point fixe — une entrée qui est ou contient le dossier de l'unité est refusée à la pose -----------------------
MOT_UNITE = "dossier de l'unité"
ENTREES_UNITE = (UNITE, ".planning", ".planning/cycles", ".planning/cycles/01-c/phases", ".PLANNING", "./.planning/")
VOISINE = ".planning/cycles/01-c/phases/01-p-bis"


def fuites_message(ctx, lab, texte):
    """Ce qu'un message de refus ne doit jamais porter (mêmes contrôles que R-EMP-07)."""
    fuites = []
    for chemin in {lab, os.path.realpath(lab), os.path.dirname(os.path.realpath(lab)), ctx.work}:
        if chemin and chemin in texte:
            fuites.append("le chemin absolu " + chemin)
    bas = texte.lower()
    for interdit in ("no such file", "can't open", "cannot open", "traceback"):
        if interdit in bas:
            fuites.append("« %s »" % interdit)
    if re.search(r"(^|[\s'\"(])/(Users|home|private|var|tmp|etc)/", texte):
        fuites.append("un chemin absolu")
    return fuites


def hash_livrables_pose(lab, unite=UNITE):
    m = re.search(r'^hash_livrables: "([0-9a-f]{64})"$', octets(os.path.join(lab, unite, "VERDICT.md")).decode("utf-8"), re.M)
    return m.group(1) if m else None


def controle_emp_08(ctx, dossier):
    fautes = []
    ns = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    for entree in ENTREES_UNITE:
        lab = lab_neuf(ctx, "emp08", (entree,))
        rc, out, err = poser_cmd(ctx, dossier, lab, 1)
        texte = (out + err).decode("utf-8", "replace")
        if rc != 64:
            fautes.append("ecrit: %s : code %d, attendu 64 (refus « %s »)" % (entree, rc, MOT_UNITE))
        if MOT_UNITE not in texte or "est absent" in texte:
            fautes.append("ecrit: %s : le message ne nomme pas « %s » ou dit « est absent » : %s" % (entree, MOT_UNITE, court(err)))
        if verdicts_ecrits(lab):
            fautes.append("ecrit: %s : un VERDICT.md ou son temporaire écrit malgré le refus « %s »" % (entree, MOT_UNITE))
        for fuite in fuites_message(ctx, lab, texte):
            fautes.append("ecrit: %s : le refus « %s » porte %s" % (entree, MOT_UNITE, fuite))
    # jumeaux posés, et point fixe : l'empreinte recalculée après la pose égale celle posée
    lab_dans = lab_neuf(ctx, "emp08-dans", (UNITE + "/notes.md",))
    ecrire(os.path.join(lab_dans, UNITE, "notes.md"), "notes de l'unité\n")
    lab_voisine = lab_neuf(ctx, "emp08-voisine", (VOISINE,))
    ecrire(os.path.join(lab_voisine, VOISINE, "a.md"), "unité voisine\n")
    for nom, lab, entree in (("entrée dans l'unité", lab_dans, UNITE + "/notes.md"), ("unité voisine", lab_voisine, VOISINE)):
        rc, out, err = poser_cmd(ctx, dossier, lab, 1)
        if rc != 0:
            fautes.append("jumeau %s (%s) refusé hors du « %s » : rc=%d %s" % (nom, entree, MOT_UNITE, rc, court(err)))
            continue
        pose, recalcule = hash_livrables_pose(lab), ns["empreinte_livrables"](lab, [entree])
        if recalcule != ("ok", pose):
            fautes.append("point fixe rompu (jumeau %s) : hash_livrables posé %s, recalculé après la pose %s" % (nom, pose, recalcule))
    # non-consommation de la tentative : refus sur une tentative 2, PLAN.md rétabli, la tentative 2 passe
    lab = lab_neuf(ctx, "emp08-tentative")
    rc, out, err = poser_cmd(ctx, dossier, lab, 1)
    if rc != 0:
        return False, "tentative 1 du lab de non-consommation refusée : rc=%d %s" % (rc, court(err))
    chemin_plan, chemin_verdict = os.path.join(lab, UNITE, "PLAN.md"), os.path.join(lab, UNITE, "VERDICT.md")
    plan_avant, verdict_avant = octets(chemin_plan), octets(chemin_verdict)
    ecrire(chemin_plan, plan_md((".planning",)))
    rc, out, err = poser_cmd(ctx, dossier, lab, 2)
    if rc != 64 or MOT_UNITE not in err.decode("utf-8", "replace"):
        fautes.append("tentative 2 sous ecrit: .planning : rc=%d, attendu 64 « %s » : %s" % (rc, MOT_UNITE, court(err)))
    if octets(chemin_verdict) != verdict_avant:
        fautes.append("VERDICT.md modifié par un refus « %s »" % MOT_UNITE)
    if [n for n in os.listdir(os.path.join(lab, UNITE)) if n.startswith(".VERDICT.")]:
        fautes.append("temporaire laissé par un refus « %s »" % MOT_UNITE)
    ecrire(chemin_plan, plan_avant)
    rc, out, err = poser_cmd(ctx, dossier, lab, 2)
    if rc != 0:
        fautes.append("tentative 2 après rétablissement du PLAN.md : rc=%d (attendu 0 : le refus « %s » ne consomme aucune tentative) %s"
                      % (rc, MOT_UNITE, court(err)))
    # non-consommation de la dérogation PLAFOND : le refus précède le plafond (64, jamais 65)
    lab = lab_neuf(ctx, "emp08-derog")
    for n in (1, 2, 3):
        rc, out, err = poser_cmd(ctx, dossier, lab, n)
        if rc != 0:
            return False, "tentative %d du lab de dérogation refusée : rc=%d %s" % (n, rc, court(err))
    ecrire(os.path.join(lab, UNITE, "PLAN.md"), plan_md((UNITE,)))
    rc, out, err = deroger_cmd(ctx, dossier, lab, "PLAFOND", UNITE)
    if rc != 0:
        return False, "deroger-gate.sh refuse la dérogation PLAFOND sur l'unité : rc=%d %s" % (rc, court(err))
    rc, out, err = poser_cmd(ctx, dossier, lab, 4)
    if rc != 64 or MOT_UNITE not in err.decode("utf-8", "replace"):
        fautes.append("tentative 4 sous dérogation PLAFOND et ecrit: = l'unité : rc=%d, attendu 64 « %s » (jamais 65 ni 0) : %s"
                      % (rc, MOT_UNITE, court(err)))
    if [l for l in journal_derogations(lab) if "  consommee  " in l]:
        fautes.append("la dérogation PLAFOND a été consommée par une pose refusée (« %s »)" % MOT_UNITE)
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d entrées qui sont ou contiennent le dossier de l'unité (l'unité, .planning, deux ancêtres, .PLANNING, ./.planning/) "
                          "refusées en 64, message « %s », jamais « est absent », aucun VERDICT.md ni temporaire, aucun chemin absolu ; jumeaux "
                          "posés (entrée dans l'unité, unité voisine) au point fixe ; refus sans tentative consommée (la tentative 2 passe "
                          "ensuite) ni dérogation PLAFOND consommée (64, jamais 65)" % (len(ENTREES_UNITE), MOT_UNITE))


# --- R-EMP-09 : budget commun à toutes les entrées d'un PLAN.md -----------------------------------------------------------
def controle_emp_09(ctx, dossier):
    fautes = []
    ns = charger_bloc(os.path.join(copie_bornes(ctx, dossier), "poser-verdict.sh"))
    lab = lab_neuf(ctx, "emp09")

    def dossier_de(nom, n):
        for i in range(n):
            ecrire(os.path.join(lab, nom, "f%02d.txt" % i), "xx")
        return nom

    rendu = ns["livrables_presents"](lab, [dossier_de("da", 6), dossier_de("db", 6)])
    if [s for _e, s, _d in rendu] != ["present", "borne"] or "10 fichiers" not in rendu[1][2]:
        fautes.append("budget commun : 6+6 fichiers sous une borne de 10 : obtenu %s, attendu present puis borne « 10 fichiers »" % (rendu,))
    rendu = ns["livrables_presents"](lab, [dossier_de("dc", 5), dossier_de("dd", 5)])
    if [s for _e, s, _d in rendu] != ["present", "present"]:
        fautes.append("budget commun : 5+5 fichiers sous une borne de 10 : obtenu %s, attendu deux present" % (rendu,))
    rendu = ns["livrables_presents"](lab, ["da", "db", dossier_de("de", 1)])
    if [s for _e, s, _d in rendu] != ["present", "borne", "borne"]:
        fautes.append("budget commun : 6+6+1 fichiers : obtenu %s, attendu present, borne, borne (toute entrée après une borne)" % (rendu,))
    # cas p4, bornes réelles : 250 entrées imbriquées sur 250 dossiers et 1600 fichiers non vides au fond
    lab4 = ctx.unique("emp09-p4")
    entrees, rel = [], ""
    for _i in range(250):
        rel = rel + "/a" if rel else "a"
        entrees.append(rel)
    os.makedirs(os.path.join(lab4, rel))
    for i in range(1600):
        with open(os.path.join(lab4, rel, "f%04d" % i), "w") as fh:
            fh.write("x")
    ns_reel = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    compteur = [0]
    ns_reel["os"] = OsMandataire(scandir=scandir_compteur(compteur, 2500))
    debut = time.time()
    try:
        rendu = ns_reel["livrables_presents"](lab4, entrees)
    except TropDEntrees as exc:
        rendu = None
        fautes.append("budget commun : cas p4 (250 entrées imbriquées, 1600 fichiers) : %s, attendu au plus 2500" % exc)
    duree = time.time() - debut
    if rendu is not None:
        statuts = [s for _e, s, _d in rendu]
        if "borne" not in statuts:
            fautes.append("budget commun : cas p4 : aucune entrée borne (%d present)" % statuts.count("present"))
        elif "present" in statuts[statuts.index("borne"):]:
            fautes.append("budget commun : cas p4 : une entrée present après la première borne")
    return (not fautes), ("; ".join(fautes) if fautes else
                          "bornes abaissées à 10 : 6+6 → present puis borne « 10 fichiers », 5+5 → deux present, 6+6+1 → la troisième borne ; "
                          "cas p4 (bornes réelles, 250 entrées imbriquées, 1600 fichiers) : %d present puis %d borne, aucune present après la "
                          "première borne, %d entrées de dossier énumérées (au plus 2500), durée indicative %.2f s"
                          % (statuts.count("present"), statuts.count("borne"), compteur[0], duree))


# --- R-EMP-10 : un nom non UTF-8 ou porteur d'un caractère de contrôle rend le livrable illisible ----------------------------
def controle_emp_10(ctx, dossier):
    fautes, exerces = [], []
    ns = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    for nom, attendu in (("a.txt", True), ("é", True), ("a\tb", False), ("a\nb", False), ("a\x7fb", False), ("a\udcffb", False)):
        obtenu = ns["_nom_sain"](nom)
        if obtenu is not attendu:
            fautes.append("nom sain : _nom_sain(%r) rend %r, attendu %r" % (nom, obtenu, attendu))
    for etiquette, nom_fichier in (("une tabulation", "a\tb.txt"), ("un saut de ligne", "a\nb.txt")):
        lab = lab_neuf(ctx, "emp10")
        ecrire(os.path.join(lab, "nt", "ok.txt"), "y\n")
        try:
            ecrire(os.path.join(lab, "nt", nom_fichier), "x\n")
        except OSError as exc:
            ctx.notes.append("  ~ R-EMP-10 nom à %s non exercé (création refusée : %s)" % (etiquette, type(exc).__name__))
            continue
        rendu = ns["empreinte_livrables"](lab, ["nt"])
        if rendu[0] != "illisible":
            fautes.append("nom sain : livrable dont un fichier porte %s dans son nom : %s, attendu illisible (jamais ok)" % (etiquette, rendu))
        exerces.append(etiquette)
    lab = lab_neuf(ctx, "emp10b")
    ecrire(os.path.join(lab, "nu", "ok.txt"), "y\n")
    try:
        descripteur = os.open(os.fsencode(os.path.join(lab, "nu")) + b"/\xff.txt", os.O_WRONLY | os.O_CREAT, 0o644)
    except OSError:
        ctx.notes.append("  ~ R-EMP-10b non exercé (système de fichiers qui refuse les noms non UTF-8)")
    else:
        os.write(descripteur, b"x\n")
        os.close(descripteur)
        rendu = ns["empreinte_livrables"](lab, ["nu"])
        if rendu[0] != "illisible":
            fautes.append("nom sain : livrable dont un fichier porte un nom non UTF-8 réel : %s, attendu illisible (jamais ok)" % (rendu,))
        exerces.append("non UTF-8 réel")
    return (not fautes), ("; ".join(fautes) if fautes else
                          "_nom_sain vrai pour a.txt et é, faux pour tabulation, saut de ligne, DEL et substitut (octet non UTF-8) ; noms réels "
                          "exercés (%s) : livrable illisible, jamais une empreinte" % (", ".join(exerces) if exerces else "aucun"))


# --- R-EMP-11 : l'empreinte ne dépend pas de l'ordre d'énumération --------------------------------------------------------
def controle_emp_11(ctx, dossier):
    fautes = []
    lab = lab_neuf(ctx, "emp11")
    ecrire(os.path.join(lab, "d", "b.txt"), "B\n")
    ecrire(os.path.join(lab, "d", "a", "x.txt"), "X\n")
    for nom in ("a", "b", "c"):
        ecrire(os.path.join(lab, "m", nom + ".txt"), nom.upper() + "\n")
    entrees = ["d", "m"]
    attendu = empreinte_independante(lab, entrees)
    rendus = {}
    for ordre in ("naturel", "inverse", "rotation"):
        ns = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
        ns["os"] = OsMandataire(scandir=scandir_ordonne(ordre))
        rendus[ordre] = ns["empreinte_livrables"](lab, entrees)
        if rendus[ordre] != ("ok", attendu):
            fautes.append("ordre %s : empreinte %s, attendu le texte canonique recalculé par la suite (%s)" % (ordre, rendus[ordre], attendu))
    if len(set(rendus.values())) != 1:
        fautes.append("ordre : l'empreinte change avec l'ordre d'énumération : %s" % rendus)
    return (not fautes), ("; ".join(fautes) if fautes else
                          "empreinte identique sous trois ordres d'énumération provoqués (naturel, inverse, rotation) et égale au texte "
                          "canonique recalculé par la suite (sous-dossier d/a/x.txt avant d/b.txt, trois fichiers au même niveau)")


# --- R-EMP-12 : lecture sans lien à aucun composant, sans blocage sur un FIFO, repli sans descripteur ------------------------
def controle_emp_12(ctx, dossier):
    fautes = []
    ns = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    lab = lab_neuf(ctx, "emp12")
    ecrire(os.path.join(lab, "dehors", "f"), "HORS\n")
    os.symlink("dehors", os.path.join(lab, "lnk"))
    rendu = ns["_hacher_livrables"](lab, [("lnk/f", 0)], [0, 0, 0])
    if rendu[0] != "illisible":
        fautes.append("lien : composant intermédiaire lien (lnk/f) : obtenu %s, attendu illisible (jamais lu)" % (rendu,))
    rendu = ns["_hacher_livrables"](lab, [("dehors/f", 0)], [0, 0, 0])
    if rendu[0] != "ok":
        fautes.append("lien : jumeau réel dehors/f : obtenu %s, attendu ok" % (rendu,))
    fifo = "non exercé"
    if hasattr(os, "mkfifo") and hasattr(signal, "alarm"):
        os.mkfifo(os.path.join(lab, "fifo"))

        def sonner(_signum, _cadre):
            raise OuvertureBloquee()

        ancien = signal.signal(signal.SIGALRM, sonner)
        try:
            signal.alarm(5)
            rendu = ns["_hacher_livrables"](lab, [("fifo", 0)], [0, 0, 0])
        except OuvertureBloquee:
            rendu = None
            fautes.append("FIFO : ouverture bloquée (O_NONBLOCK) au-delà de 5 s")
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, ancien)
        if rendu is not None and rendu[0] != "illisible":
            fautes.append("FIFO : obtenu %s, attendu illisible sans blocage (O_NONBLOCK, fstat non régulier)" % (rendu,))
        fifo = "illisible sans blocage"
    else:
        ctx.notes.append("  ~ R-EMP-12b non exercé (os.mkfifo ou signal.alarm indisponible)")
    # espion : toute ouverture du chemin de lecture (hors la racine du lab, résolue par l'appelant) porte O_NOFOLLOW, O_NONBLOCK et,
    # là où le système l'offre, un descripteur de dossier
    journal = []

    def ouvrir(chemin, drapeaux, mode=0o777, *, dir_fd=None):
        journal.append((chemin, drapeaux, dir_fd))
        return os.open(chemin, drapeaux, mode, dir_fd=dir_fd)

    ns_espion = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    ns_espion["os"] = OsMandataire(open=ouvrir)
    lab_e = lab_neuf(ctx, "emp12-espion")
    rendu = ns_espion["empreinte_livrables"](lab_e, ENTREES_EMP)
    if rendu[0] != "ok":
        fautes.append("espion : empreinte %s, attendu ok" % (rendu,))
    lecture = [(c, d, f) for c, d, f in journal if not (c == lab_e and f is None)]
    if not lecture:
        fautes.append("espion : aucune ouverture du chemin de lecture consignée (contrôle à vide)")
    sans_suivi, sans_blocage = getattr(os, "O_NOFOLLOW", 0), getattr(os, "O_NONBLOCK", 0)
    avec_dirfd = os.open in os.supports_dir_fd and hasattr(os, "O_DIRECTORY")
    ecarts = {}
    for chemin, drapeaux, dir_fd in lecture:
        nom = os.path.basename(str(chemin))
        if sans_suivi and not drapeaux & sans_suivi:
            ecarts.setdefault("lien suivi possible : ouverture sans O_NOFOLLOW", []).append(nom)
        if sans_blocage and not drapeaux & sans_blocage:
            ecarts.setdefault("O_NONBLOCK absent d'une ouverture", []).append(nom)
        if avec_dirfd and dir_fd is None:
            ecarts.setdefault("lien intermédiaire suivi : ouverture par chemin, sans descripteur de dossier", []).append(nom)
    for libelle, noms in sorted(ecarts.items()):
        fautes.append("%s (%d ouverture(s) : %s)" % (libelle, len(noms), ", ".join(sorted(set(noms))[:6])))
    # repli sans descripteur de dossier : même empreinte que le chemin normal
    lab_r = lab_neuf(ctx, "emp12-repli")
    normal = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))["empreinte_livrables"](lab_r, ENTREES_EMP)
    ns_repli = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    ns_repli["AVEC_DESCRIPTEURS"] = False
    repli = ns_repli["empreinte_livrables"](lab_r, ENTREES_EMP)
    if normal[0] != "ok" or repli != normal:
        fautes.append("repli sans descripteur de dossier : empreinte %s, chemin normal %s : attendu la même" % (repli, normal))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "composant lien (lnk/f) illisible, jumeau réel ok ; FIFO %s ; %d ouvertures du chemin de lecture, toutes avec "
                          "O_NOFOLLOW et O_NONBLOCK%s ; repli sans descripteur : même empreinte"
                          % (fifo, len(lecture), " et un descripteur de dossier" if avec_dirfd else ""))


# --- R-EMP-04 : trois copies ast-identiques ---------------------------------------------------------------------------
NOMS_BLOC = ("BORNE_FICHIERS_LIVRABLES", "BORNE_OCTETS_LIVRABLES", "NOMS_EXCLUS_LIVRABLES", "SANS_BLOCAGE", "DRAPEAUX_LIVRABLE",
             "AVEC_DESCRIPTEURS", "_normaliser_livrable", "_fichier_non_vide", "_nom_sain", "_borne_depassee", "_parcourir_livrable",
             "_examiner_livrable", "livrables_presents", "_ouvrir_dossier_livrable", "_fermer_dossier_livrable", "_hacher_dans",
             "_hacher_livrables", "empreinte_livrables", "_couvre_unite", "entrees_du_plan", "entree_ecrit_valide")
NOMS_ENTREES = ("SANS_SUIVI_DE_LIEN", "dequote", "CLE_RE", "lire_frontmatter", "_lire_liste_indentee", "_valeurs_ecrit")
JEUX_PLAN = (
    ("ecrit scalaire", b"---\necrit: livrables/rapport.md\n---\n"),
    ("ecrit scalaire quoté", b"---\necrit: 'livrables/rapport.md'\n---\n"),
    ("liste en ligne", b"---\necrit: [livrables/rapport.md, donnees]\n---\n"),
    ("liste indentée", b"---\necrit:\n  - livrables/rapport.md\n  - donnees\n---\n"),
    ("entrées quotées 'x' et \"x\"", b"---\necrit:\n  - 'livrables/rapport.md'\n  - \"donnees\"\n---\n"),
    ("liste vide", b"---\necrit: []\n---\n"),
    ("ecrit absent", b"---\nauteur: x\n---\n"),
    ("ecrit: ../x", b"---\necrit: ../x\n---\n"),
    ("ecrit: /abs", b"---\necrit: /abs\n---\n"),
    ("liste de mappings", b"---\necrit:\n  - chemin: livrables/rapport.md\n---\n"),
    ("frontmatter non fermé", b"---\necrit: livrables/rapport.md\n"),
    ("non UTF-8", b"---\necrit: livrables/\xff.md\n---\n"),
    ("entrée = l'unité", ("---\necrit: %s\n---\n" % UNITE).encode("utf-8")),
    ("ancêtre .planning", b"---\necrit:\n  - livrables/rapport.md\n  - .planning\n---\n"),
    ("casse .PLANNING", b"---\necrit: .PLANNING/cycles\n---\n"),
    ("entrée voisine hors de l'unité", ("---\necrit: %s\n---\n" % VOISINE).encode("utf-8")),
)
NOMS_JOURNAL = ("NOM_JOURNAL_DEROGATIONS", "LIGNE_DEROGATION_RE", "_jeton_journal", "_chemin_journal_derogations",
                "_ouvrir_journal_derogations", "_entrees_journal", "_derogation_non_consommee", "derogation_active", "consommer", "citer")


def corps_ast(dossier, script, marqueur):
    return ast.parse(corps_python(open(os.path.join(dossier, script), encoding="utf-8").read(), marqueur))


def arbre_de(arbre, nom):
    """ast.dump de la fonction ou de la constante `nom` du corps (docstring comprise), ou None."""
    for noeud in arbre.body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name == nom:
            return ast.dump(noeud)
        if isinstance(noeud, ast.Assign) and isinstance(noeud.targets[0], ast.Name) and noeud.targets[0].id == nom:
            return ast.dump(noeud)
    return None


def comparer_arbres(arbres, noms, fautes):
    """`arbres` = [(script, arbre)] : chaque nom de `noms` a le même arbre dans tous les scripts ; un écart nomme le script et le nom."""
    for nom in noms:
        refs = [(s, arbre_de(a, nom)) for s, a in arbres]
        for s, r in refs:
            if r is None:
                fautes.append("%s absent de %s" % (nom, s))
        presentes = [(s, r) for s, r in refs if r is not None]
        for s, r in presentes[1:]:
            if r != presentes[0][1]:
                fautes.append("%s : arbre ast différent entre %s et %s" % (nom, presentes[0][0], s))


def controle_emp_04(ctx, dossier):
    arbres = {s: corps_ast(dossier, s, m) for s, m in TROIS_COPIES + (("deroger-gate.sh", "PY_DEROGER_GATE_EOF"),)}
    fautes = []
    trois = [(s, arbres[s]) for s, _m in TROIS_COPIES]
    comparer_arbres(trois, NOMS_BLOC + NOMS_ENTREES, fautes)
    comparer_arbres([(s, arbres[s]) for s in ("planning-hook.sh", "poser-verdict.sh")], NOMS_JOURNAL, fautes)
    comparer_arbres([(s, arbres[s]) for s in ("planning-hook.sh", "poser-verdict.sh", "recalc-planning.sh", "deroger-gate.sh")],
                    ("_jeton_journal", "entree_ecrit_valide"), fautes)
    # mêmes verdicts : le prédicat et l'empreinte rendent la même chose dans les trois copies sur le même lab
    lab = lab_neuf(ctx, "emp04")
    cas = cas_predicat(lab)
    rendus, chaines = {}, {}
    for script, marqueur in TROIS_COPIES:
        ns = charger_bloc(os.path.join(dossier, script), marqueur)
        rendus[script] = ([ns["livrables_presents"](lab, [entree])[0] for _n, entree, _a in cas], ns["empreinte_livrables"](lab, ENTREES_EMP))
        chaines[script] = [ns["entrees_du_plan"](jeu, UNITE) for _n, jeu in JEUX_PLAN]
    base = rendus["poser-verdict.sh"]
    for script, rendu in rendus.items():
        if rendu != base:
            fautes.append("%s rend un verdict de présence ou une empreinte différents de poser-verdict.sh sur le même lab" % script)
    for script, rendu in chaines.items():
        for (nom, _jeu), obtenu, attendu in zip(JEUX_PLAN, rendu, chaines["poser-verdict.sh"]):
            if obtenu != attendu:
                fautes.append("entrees_du_plan : jeu « %s » : %s rend %r, poser-verdict.sh rend %r" % (nom, script, obtenu, attendu))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d noms du bloc partagé et de ses entrées et %d du journal de dérogation à arbres ast identiques (docstring comprise) "
                          "dans les copies attendues ; mêmes statuts de présence (%d cas), même empreinte et mêmes verdicts de entrees_du_plan "
                          "(%d jeux d'octets) dans les trois copies"
                          % (len(NOMS_BLOC) + len(NOMS_ENTREES), len(NOMS_JOURNAL), len(cas), len(JEUX_PLAN)))


# --- R-PLAF-01 à 04 : le plafond de tentatives -------------------------------------------------------------------------
def controle_plaf_01(ctx, dossier):
    lab = lab_neuf(ctx, "plaf01")
    for n in (1, 2, 3):
        rc, out, err = poser_cmd(ctx, dossier, lab, n)
        if rc != 0:
            return False, "tentative %d : rc=%d (attendu 0) %s" % (n, rc, court(err))
    chemin = os.path.join(lab, UNITE, "VERDICT.md")
    avant = octets(chemin)
    fautes = []
    rc, out, err = poser_cmd(ctx, dossier, lab, 4)
    texte = err.decode("utf-8", "replace")
    if rc != 65:
        fautes.append("4e tentative : rc=%d (attendu 65) %s" % (rc, court(err)))
    else:
        if "plafond de 3 tentatives" not in texte or "arbitrage humain" not in texte:
            fautes.append("le message de la 4e tentative ne nomme pas le plafond de 3 et l'arbitrage humain : " + court(err))
        if "Usage" in texte:
            fautes.append("le refus du plafond imprime l'usage des erreurs de saisie (64) : le message doit être distinct")
    if octets(chemin) != avant:
        fautes.append("VERDICT.md modifié par la 4e tentative refusée")
    if [n for n in os.listdir(os.path.join(lab, UNITE)) if n.startswith(".")]:
        fautes.append("fichier temporaire laissé par la 4e tentative refusée")
    # jumeau : une tentative incohérente (5 sur une tentative 3) reste une erreur de saisie (64), jamais le plafond
    rc, out, err = poser_cmd(ctx, dossier, lab, 5)
    if rc != 64:
        fautes.append("tentative incohérente 5 sur une tentative 3 : rc=%d (attendu 64, distinct du plafond)" % rc)
    return (not fautes), ("; ".join(fautes) if fautes else
                          "tentatives 1, 2, 3 acceptées ; la 4e : code 65, message qui nomme le plafond de 3 et l'arbitrage humain, VERDICT.md "
                          "octet pour octet inchangé, aucun temporaire ; une tentative incohérente reste 64")


def controle_plaf_02(ctx, dossier):
    lab = lab_neuf(ctx, "plaf02")
    for n in (1, 2, 3):
        rc, out, err = poser_cmd(ctx, dossier, lab, n)
        if rc != 0:
            return False, "tentative %d : rc=%d (attendu 0) %s" % (n, rc, court(err))
    chemin = os.path.join(lab, UNITE, "VERDICT.md")
    fautes = []
    # jumeaux négatifs : une dérogation d'un autre gate sur l'unité, ou PLAFOND sur une autre unité, ne lève rien
    for gate, cible in (("G5", UNITE), ("PLAFOND", ".planning/cycles/01-c/phases/02-autre")):
        rc, out, err = deroger_cmd(ctx, dossier, lab, gate, cible)
        if rc != 0:
            return False, "deroger-gate.sh refuse la dérogation %s sur %s : rc=%d %s" % (gate, cible, rc, court(err))
    rc, out, err = poser_cmd(ctx, dossier, lab, 4)
    if rc != 65:
        fautes.append("4e tentative sous une dérogation d'un autre gate ou d'une autre unité : rc=%d (attendu 65)" % rc)
    if [l for l in journal_derogations(lab) if "  consommee  " in l]:
        fautes.append("une dérogation étrangère à l'unité a été consommée")
    # la vraie dérogation : PLAFOND sur l'unité
    rc, out, err = deroger_cmd(ctx, dossier, lab, "PLAFOND", UNITE)
    if rc != 0:
        return False, "deroger-gate.sh refuse la dérogation PLAFOND sur l'unité : rc=%d %s" % (rc, court(err))
    rc, out, err = poser_cmd(ctx, dossier, lab, 4)
    if rc != 0:
        fautes.append("4e tentative sous la dérogation PLAFOND de l'unité : rc=%d (attendu 0) %s" % (rc, court(err)))
    elif b"tentative: 4" not in octets(chemin):
        fautes.append("VERDICT.md sans tentative 4 après la dérogation")
    consommees = [l for l in journal_derogations(lab) if "  consommee  " in l and "gate=PLAFOND" in l]
    if len(consommees) != 1 or ("chemin=" + UNITE) not in consommees[0]:
        fautes.append("journal : %d ligne(s) consommee PLAFOND sur l'unité (attendu 1) : %s" % (len(consommees), court(" | ".join(consommees))))
    if b"consomm" not in out:
        fautes.append("la dérogation consommée n'est pas citée sur la sortie : " + court(out))
    avant = octets(chemin)
    rc, out, err = poser_cmd(ctx, dossier, lab, 5)
    if rc != 65:
        fautes.append("5e tentative : rc=%d (attendu 65 : usage unique de la dérogation) %s" % (rc, court(err)))
    if octets(chemin) != avant:
        fautes.append("VERDICT.md modifié par la 5e tentative refusée")
    if len([l for l in journal_derogations(lab) if "  consommee  " in l]) != len(consommees):
        fautes.append("la 5e tentative refusée a consommé une dérogation")
    return (not fautes), ("; ".join(fautes) if fautes else
                          "4e tentative refusée (65) sous une dérogation d'un autre gate ou d'une autre unité ; acceptée sous la dérogation PLAFOND de "
                          "l'unité, qui est citée et inscrite `consommee` ; la 5e est refusée (65), usage unique")


def controle_plaf_03(ctx, dossier):
    lab = lab_neuf(ctx, "plaf03")
    ecrire(os.path.join(lab, ".planning", "config.json"), json.dumps({
        "planning_version": "cycles-v1", "plafond_tentatives": 10, "PLAFOND_TENTATIVES": 10, "plafond": 10,
        "options": {"plafond_tentatives": 10, "plafond": 10}}))
    env_extra = {"PLAFOND_TENTATIVES": "10", "VF_PLAFOND_TENTATIVES": "10", "PLAFOND": "10", "VF_PLAFOND": "10",
                 "PLAFOND_TENTATIVES_VERDICT": "10"}
    fautes = []
    for n in (1, 2, 3):
        rc, out, err = poser_cmd(ctx, dossier, lab, n, env_extra=env_extra)
        if rc != 0:
            return False, "tentative %d : rc=%d (attendu 0) %s" % (n, rc, court(err))
    rc, out, err = poser_cmd(ctx, dossier, lab, 4, env_extra=env_extra)
    if rc != 65:
        fautes.append("4e tentative sous une clé de config et des variables d'environnement à 10 : rc=%d (attendu 65, constante du code)" % rc)
    texte = open(os.path.join(dossier, "poser-verdict.sh"), encoding="utf-8").read()
    corps = corps_python(texte, MARQUEUR_POSER)
    if re.search(r"os\.environ|getenv", corps):
        fautes.append("le corps du script lit l'environnement")
    valeur = None
    for noeud in ast.parse(corps).body:
        if isinstance(noeud, ast.Assign) and isinstance(noeud.targets[0], ast.Name) and noeud.targets[0].id == "PLAFOND_TENTATIVES":
            valeur = ast.literal_eval(noeud.value)
    if valeur != 3:
        fautes.append("PLAFOND_TENTATIVES est %r dans le code livré (attendu la constante 3)" % (valeur,))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "une clé de plafond à 10 dans config.json et des variables d'environnement à 10 ne changent rien : la 4e tentative reste "
                          "refusée (65) ; PLAFOND_TENTATIVES = 3 est une constante littérale, le script ne lit pas l'environnement")


def controle_plaf_04(ctx, dossier):
    arbre = corps_ast(dossier, "poser-verdict.sh", MARQUEUR_POSER)
    fonction = next((n for n in arbre.body if isinstance(n, ast.FunctionDef) and n.name == "poser"), None)
    if fonction is None:
        return False, "fonction poser absente de poser-verdict.sh"
    ordre = ("ouvrir_verrou", "derogation_active", "consommer", "ecrire_atomique")
    positions = {}
    for noeud in ast.walk(fonction):
        if isinstance(noeud, ast.Call) and isinstance(noeud.func, ast.Name) and noeud.func.id in ordre:
            pos = (noeud.lineno, noeud.col_offset)
            positions[noeud.func.id] = min(pos, positions.get(noeud.func.id, pos))
    fautes = []
    manquants = [n for n in ordre if n not in positions]
    if manquants:
        fautes.append("appel(s) absent(s) de poser : %s" % ", ".join(manquants))
    else:
        for avant, apres in zip(ordre, ordre[1:]):
            if not positions[avant] < positions[apres]:
                fautes.append("%s (ligne %d) ne précède pas %s (ligne %d) dans poser" % (avant, positions[avant][0], apres, positions[apres][0]))
    # `consommer` est le code du hook central (verrou exclusif du journal, relecture sous le verrou)
    arbre_hook = corps_ast(dossier, "planning-hook.sh", "PY_PLANNING_HOOK_EOF")
    a_poser, a_hook = arbre_de(arbre, "consommer"), arbre_de(arbre_hook, "consommer")
    if a_poser is None or a_poser != a_hook:
        fautes.append("consommer de poser-verdict.sh n'est pas ast-identique à celui de planning-hook.sh")
    noeud_hook = next((n for n in arbre_hook.body if isinstance(n, ast.FunctionDef) and n.name == "consommer"), None)
    verrouille = noeud_hook is not None and any(isinstance(n, ast.Attribute) and n.attr == "flock" for n in ast.walk(noeud_hook))
    if not verrouille:
        fautes.append("consommer du hook ne prend pas le verrou du journal (fcntl.flock)")
    return (not fautes), ("; ".join(fautes) if fautes else
                          "dans poser : ouvrir_verrou, puis derogation_active, puis consommer, puis ecrire_atomique ; consommer est ast-identique à "
                          "celui du hook, qui prend le verrou exclusif du journal")


# --- R-JUGE-FORME-01 et 02 : la forme d'unité d'un juge ------------------------------------------------------------------
UNITE_JUGE = ".planning/juges/vf-design-judge"


def lab_juge(ctx, nom):
    lab = lab_neuf(ctx, nom)
    ecrire(os.path.join(lab, UNITE_JUGE, "SORTIE-PIEGEE.md"), "sortie piégée : le critère visé est violé\n")
    return lab


def controle_juge_01(ctx, dossier):
    lab = lab_juge(ctx, "juge01")
    fautes = []
    rc, out, err = poser_cmd(ctx, dossier, lab, 1, unite=UNITE_JUGE)
    chemin = os.path.join(lab, UNITE_JUGE, "VERDICT.md")
    if rc != 0 or not os.path.isfile(chemin):
        return False, "forme de juge refusée : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    ns = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    statut, donnees = ns["lire_frontmatter"](octets(chemin).decode("utf-8"))
    lignes = octets(chemin).decode("utf-8").split("\n")
    fin = lignes.index("---", 1)
    cles = [l.split(":")[0] for l in lignes[1:fin] if l and not l.startswith(" ")]
    attendu = hashlib.sha256(octets(os.path.join(lab, UNITE_JUGE, "SORTIE-PIEGEE.md"))).hexdigest()
    if statut != "ok" or donnees.get("hash") != attendu:
        fautes.append("hash relu %r, attendu le sha256 de SORTIE-PIEGEE.md %s" % (donnees.get("hash"), attendu))
    if cles != ["juge", "hash", "tentative", "score", "constats"]:
        fautes.append("clés du frontmatter : %s (attendu juge, hash, tentative, score, constats, sans hash_livrables)" % cles)
    # le plafond s'applique comme à toute unité
    for n in (2, 3):
        rc, out, err = poser_cmd(ctx, dossier, lab, n, unite=UNITE_JUGE)
        if rc != 0:
            fautes.append("tentative %d de l'unité de juge : rc=%d %s" % (n, rc, court(err)))
    avant = octets(chemin)
    rc, out, err = poser_cmd(ctx, dossier, lab, 4, unite=UNITE_JUGE)
    if rc != 65 or octets(chemin) != avant:
        fautes.append("4e tentative de l'unité de juge : rc=%d (attendu 65), fichier %s" % (rc, "inchangé" if octets(chemin) == avant else "MODIFIÉ"))
    rc, out, err = deroger_cmd(ctx, dossier, lab, "PLAFOND", UNITE_JUGE)
    if rc != 0:
        fautes.append("deroger-gate.sh refuse la dérogation PLAFOND de l'unité de juge : rc=%d %s" % (rc, court(err)))
    else:
        rc, out, err = poser_cmd(ctx, dossier, lab, 4, unite=UNITE_JUGE)
        if rc != 0:
            fautes.append("4e tentative de l'unité de juge sous la dérogation PLAFOND : rc=%d (attendu 0) %s" % (rc, court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "unité .planning/juges/vf-design-judge posée (code 0) : hash = sha256 de SORTIE-PIEGEE.md, aucune clé hash_livrables ; plafond "
                          "appliqué (4e refusée en 65, acceptée sous la dérogation PLAFOND de l'unité)")


def controle_juge_02(ctx, dossier):
    fautes = []
    cas = []

    def neuf(nom):
        lab = lab_neuf(ctx, "juge02-" + nom)
        return lab

    def sortie(lab, rel):
        ecrire(os.path.join(lab, rel, "SORTIE-PIEGEE.md"), "sortie piégée\n")

    lab = neuf("dotdot")
    os.makedirs(os.path.join(lab, ".planning", "juges", "vf-design-judge"))
    sortie(lab, ".planning/autre")
    cas.append(("unité .planning/juges/../autre", lab, ".planning/juges/../autre"))
    lab = neuf("autre")
    sortie(lab, ".planning/autre/x")
    cas.append(("unité .planning/autre/x", lab, ".planning/autre/x"))
    lab = neuf("profond")
    sortie(lab, ".planning/juges/a/b")
    cas.append(("unité .planning/juges/a/b", lab, ".planning/juges/a/b"))
    lab = neuf("majuscule")
    sortie(lab, ".planning/juges/Majuscule")
    cas.append(("unité .planning/juges/Majuscule", lab, ".planning/juges/Majuscule"))
    lab = neuf("souligne")
    sortie(lab, ".planning/juges/x_y")
    cas.append(("unité .planning/juges/x_y (souligné)", lab, ".planning/juges/x_y"))
    lab = neuf("casse-juges")
    sortie(lab, ".planning/Juges/x")
    cas.append(("unité .planning/Juges/x (casse de juges)", lab, ".planning/Juges/x"))
    lab = neuf("long")
    sortie(lab, ".planning/juges/" + "a" * 65)
    cas.append(("nom de juge de 65 caractères", lab, ".planning/juges/" + "a" * 65))
    lab = neuf("sans-sortie")
    ecrire(os.path.join(lab, ".planning", "juges", "x", "PLAN.md"), "---\necrit: livrables/rapport.md\n---\n")
    cas.append(("unité .planning/juges/x sans SORTIE-PIEGEE.md (même avec un PLAN.md)", lab, ".planning/juges/x"))
    lab = neuf("lien")
    ecrire(os.path.join(lab, "livrables", "reel.md"), "sortie piégée\n")
    os.makedirs(os.path.join(lab, ".planning", "juges", "x"))
    os.symlink("../../../livrables/reel.md", os.path.join(lab, ".planning", "juges", "x", "SORTIE-PIEGEE.md"))
    cas.append(("SORTIE-PIEGEE.md est un lien", lab, ".planning/juges/x"))
    lab = neuf("cycle-sans-plan")
    os.remove(os.path.join(lab, UNITE, "PLAN.md"))
    sortie(lab, UNITE)
    cas.append(("unité de cycle sans PLAN.md (SORTIE-PIEGEE.md ne le remplace pas)", lab, UNITE))
    for nom, lab, unite in cas:
        rc, out, err = poser_cmd(ctx, dossier, lab, 1, unite=unite)
        if rc != 64 or verdicts_ecrits(lab):
            fautes.append("%s : rc=%d (attendu 64), écrit %s" % (nom, rc, [os.path.relpath(e, lab) for e in verdicts_ecrits(lab)]))
    # jumeau valide : la même sortie piégée, sous un nom de juge conforme
    lab = neuf("valide")
    sortie(lab, ".planning/juges/x")
    rc, out, err = poser_cmd(ctx, dossier, lab, 1, unite=".planning/juges/x")
    if rc != 0:
        fautes.append("jumeau valide .planning/juges/x refusé : rc=%d %s" % (rc, court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d unités hors forme refusées (64), aucun VERDICT.md écrit (autre dossier, profondeur, majuscule, souligné, casse de juges, nom "
                          "trop long, sans SORTIE-PIEGEE.md, lien, unité de cycle sans PLAN.md) ; le jumeau conforme est posé" % len(cas))


# --- Mutants ------------------------------------------------------------------------------------------------------------
def make_mutant(ctx, nom, marqueur, ident, motif, remplacement):
    """Dossier jetable portant les scripts livrés, dont `nom` a son UNIQUE ligne portant `motif` (fixe) remplacée par
    `remplacement` (indentation conservée). `bash -n` et la compilation du corps Python doivent passer."""
    original = open(os.path.join(ctx.scripts_dir, nom), encoding="utf-8").read()
    lignes = original.split("\n")
    idx = [i for i, l in enumerate(lignes) if motif in l]
    if len(idx) != 1 or original.count(motif) != 1:
        return None, "MOTIF AMBIGU OU ABSENT (lignes=%d, occurrences=%d)" % (len(idx), original.count(motif))
    ligne = lignes[idx[0]]
    lignes[idx[0]] = ligne[: len(ligne) - len(ligne.lstrip())] + remplacement
    mute = "\n".join(lignes)
    if mute == original:
        return None, "NON OPPOSABLE (identique)"
    d = ctx.unique("mut-" + ident.lower())
    os.makedirs(d, exist_ok=True)
    for s in SCRIPTS_COPIES:
        src = os.path.join(ctx.scripts_dir, s)
        if os.path.exists(src):
            shutil.copy(src, os.path.join(d, s))
            os.chmod(os.path.join(d, s), 0o755)
    chemin = os.path.join(d, nom)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(mute)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    try:
        compile(corps_python(mute, marqueur), chemin, "exec")
    except SyntaxError as exc:
        return None, "SyntaxError du corps Python : " + str(exc)
    return d, None


def temoin_pose(ctx, dossier):
    """Témoin : une pose neutre (lab entier, aucun défaut) reste acceptée sous le mutant, pour que le rouge ne vienne pas d'un
    script cassé."""
    lab = lab_neuf(ctx, "temoin")
    rc, out, err = poser_cmd(ctx, dossier, lab, 1)
    return rc, court(err)


def sur(ctrl, ctx, dossier):
    """(conforme, détail) d'un contrôle ; une exception du contrôle est un rouge décrit, jamais une section qui s'arrête."""
    try:
        return ctrl(ctx, dossier)
    except Exception as exc:
        return False, "exception du contrôle : %s : %s" % (type(exc).__name__, str(exc)[:300])


def executer_mutant(ctx, ident, nom, marqueur, motif, remplacement, cid, ctrl, mot_cle, avec_temoin=True):
    d, raison = make_mutant(ctx, nom, marqueur, ident, motif, remplacement)
    if d is None:
        komut(ident, "mutant valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
        return
    # le résultat de l'ORIGINAL est mémoïsé par contrôle (et le témoin de pose de l'original une fois) : il ne dépend pas du mutant
    if ("original", cid) not in ctx.memo:
        ctx.memo[("original", cid)] = sur(ctrl, ctx, ctx.scripts_dir)
    original = ctx.memo[("original", cid)]
    mutant = sur(ctrl, ctx, d)
    ctx.notes = []
    if not original[0]:
        komut(ident, "l'original passe %s" % cid, "conforme", original[1])
        return
    if avec_temoin:
        if ("temoin-original",) not in ctx.memo:
            ctx.memo[("temoin-original",)] = temoin_pose(ctx, ctx.scripts_dir)
        t_orig, t_mut = ctx.memo[("temoin-original",)], temoin_pose(ctx, d)
        if t_orig[0] != 0 or t_mut[0] != 0:
            komut(ident, "témoin (pose neutre) accepté sous l'original et sous le mutant", str(t_orig), str(t_mut))
            return
    if mutant[0]:
        komut(ident, "%s rougit sous le mutant" % cid, "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
    elif mot_cle not in mutant[1]:
        komut(ident, "%s rougit pour la raison visée (« %s »)" % (cid, mot_cle), "échec sur « %s »" % mot_cle, mutant[1])
    else:
        okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s%s"
              % (cid, original[1], mutant[1], " · témoin inchangé" if avec_temoin else ""))


# --- Sections --------------------------------------------------------------------------------------------------------------
def rendre(ident, titre, ctrl, ctx, dossier):
    ctx.notes = []
    try:
        bon, detail = ctrl(ctx, dossier)
    except Exception as exc:
        bon, detail = False, "exception du contrôle : %s : %s" % (type(exc).__name__, str(exc)[:300])
    ok("%s %s : %s" % (ident, titre, detail)) if bon else ko(ident, titre, "conforme", detail)
    for note in ctx.notes:  # cas non exerçables sur ce système : ligne « ~ », ni verte ni rouge
        print(note)
    ctx.notes = []


def sec_ast(ctx):
    rendre("R-EMP-04", "trois copies ast-identiques du bloc partagé", controle_emp_04, ctx, ctx.scripts_dir)


def sec_plaf(ctx):
    d = ctx.scripts_dir
    rendre("R-PLAF-01", "quatrième tentative refusée, code 65, fichier inchangé", controle_plaf_01, ctx, d)
    rendre("R-PLAF-02", "dérogation PLAFOND nominative, à usage unique", controle_plaf_02, ctx, d)
    rendre("R-PLAF-03", "le plafond est une constante du code", controle_plaf_03, ctx, d)
    rendre("R-PLAF-04", "ordre verrou, dérogation, consommation, écriture (structurel)", controle_plaf_04, ctx, d)


def sec_juge(ctx):
    d = ctx.scripts_dir
    rendre("R-JUGE-FORME-01", "unité de juge posée sur SORTIE-PIEGEE.md, sans hash_livrables", controle_juge_01, ctx, d)
    rendre("R-JUGE-FORME-02", "jumeaux négatifs : toute autre forme d'unité reste refusée", controle_juge_02, ctx, d)


def sec_emp(ctx):
    d = ctx.scripts_dir
    rendre("R-EMP-01", "prédicat « livrable présent »", controle_emp_01, ctx, d)
    rendre("R-EMP-02", "empreinte des livrables", controle_emp_02, ctx, d)
    rendre("R-EMP-03", "bornes de parcours", controle_emp_03, ctx, d)
    rendre("R-EMP-05", "la commande pose hash et hash_livrables", controle_emp_05, ctx, d)
    rendre("R-EMP-06", "la commande refuse un livrable absent, vide, lien, un ecrit: invalide, une borne dépassée", controle_emp_06, ctx, d)
    rendre("R-EMP-07", "aucun refus ne fuit un chemin absolu ni « no such file »", controle_emp_07, ctx, d)
    rendre("R-EMP-08", "point fixe : une entrée qui est ou contient le dossier de l'unité est refusée à la pose", controle_emp_08, ctx, d)
    rendre("R-EMP-09", "budget commun à toutes les entrées d'un PLAN.md", controle_emp_09, ctx, d)
    rendre("R-EMP-10", "nom non UTF-8 ou à caractère de contrôle : livrable illisible", controle_emp_10, ctx, d)
    rendre("R-EMP-11", "empreinte indépendante de l'ordre d'énumération", controle_emp_11, ctx, d)
    rendre("R-EMP-12", "lecture sans lien, sans blocage, repli sans descripteur", controle_emp_12, ctx, d)


MUTANTS = [
    # (ident, script, marqueur, motif, remplacement, contrôle, fonction, mot clé attendu dans l'échec, témoin de pose)
    ("EMP-VIDE", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-vide", "return True  # livrable-vide",
     "R-EMP-01", controle_emp_01, "vide", True),
    ("EMP-LIEN", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-lien", "info = os.stat(courant)  # livrable-lien",
     "R-EMP-01", controle_emp_01, "lien", True),
    ("EMP-BORNE", "poser-verdict.sh", MARQUEUR_POSER, "if budget[0] > BORNE_FICHIERS_LIVRABLES:  # livrable-borne",
     "if False:  # livrable-borne", "R-EMP-03", controle_emp_03, "fichiers", True),
    ("EMP-EXCLUS", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-exclus", "if False:  # livrable-exclus",
     "R-EMP-02", controle_emp_02, "nom exclu", True),
    ("VERDICT-HASH-LIVRABLES", "poser-verdict.sh", MARQUEUR_POSER, "# verdict-hash-livrables", "pass  # verdict-hash-livrables",
     "R-EMP-05", controle_emp_05, "ne se relisent pas identiques", False),
    ("PLAF", "poser-verdict.sh", MARQUEUR_POSER, "if tentative > PLAFOND_TENTATIVES:  # verdict-plafond",
     "if False:  # verdict-plafond", "R-PLAF-01", controle_plaf_01, "attendu 65", True),
    ("PLAF-CONSO", "poser-verdict.sh", MARQUEUR_POSER, "# verdict-consommation", "pass  # verdict-consommation",
     "R-PLAF-02", controle_plaf_02, "consommee", True),
    ("PLAF-ORDRE", "poser-verdict.sh", MARQUEUR_POSER, "# verdict-consommation",
     'ecrire_atomique(unite, "VERDICT.md", texte); consommer(racine, derogation)  # verdict-consommation',
     "R-PLAF-04", controle_plaf_04, "ecrire_atomique", True),
    ("JUGE-FORME", "poser-verdict.sh", MARQUEUR_POSER, "# verdict-forme-juge",
     'return len(composants) == 3 and composants[0].casefold() == ".planning" and composants[1] == "juges"  # verdict-forme-juge',
     "R-JUGE-FORME-02", controle_juge_02, "Majuscule", True),
    ("EMP-AST", "recalc-planning.sh", "PY_RECALC_PLANNING_EOF", "# livrable-vide", "return taille >= 1  # livrable-vide",
     "R-EMP-04", controle_emp_04, "recalc-planning.sh", True),
    # quick 261003-ps1 (F1 à F6) : les entrées du bloc, la chaîne unique, le point fixe, le budget commun, les noms, l'ordre, la lecture
    ("EMP-ENTREES-DEQUOTE", "recalc-planning.sh", "PY_RECALC_PLANNING_EOF",
     "    if len(v) >= 2 and v[0] == v[-1] and v[0] in (\"'\", '\"'):", "if False:", "R-EMP-04", controle_emp_04, "dequote", True),
    ("EMP-NOFOLLOW-AST", "planning-hook.sh", "PY_PLANNING_HOOK_EOF", 'SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)',
     "SANS_SUIVI_DE_LIEN = 0", "R-EMP-04", controle_emp_04, "SANS_SUIVI_DE_LIEN", True),
    ("EMP-CHAINE-AST", "recalc-planning.sh", "PY_RECALC_PLANNING_EOF", "# entrees-unite", "if False:  # entrees-unite",
     "R-EMP-04", controle_emp_04, "entrees_du_plan", True),
    ("UNITE-REFUS", "poser-verdict.sh", MARQUEUR_POSER, "# entrees-unite", "if False:  # entrees-unite",
     "R-EMP-08", controle_emp_08, "dossier de l'unité", True),
    ("BUDGET-COMMUN", "poser-verdict.sh", MARQUEUR_POSER, "# livrables-budget-commun",
     "statut, detail, _genre, _fichiers = _examiner_livrable(racine, entree, [0, 0, 0])  # livrables-budget-commun",
     "R-EMP-09", controle_emp_09, "budget commun", True),
    ("NOM-SAIN-CONTROLE", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-nom-controle", "return True  # livrable-nom-controle",
     "R-EMP-10", controle_emp_10, "nom sain", True),
    ("NOM-SAIN-UTF8", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-nom-utf8", "return True  # livrable-nom-utf8",
     "R-EMP-10", controle_emp_10, "nom sain", True),
    ("OCTETS-LUS", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-octets",
     "if budget[1] > BORNE_OCTETS_LIVRABLES:  # livrable-octets", "R-EMP-03", controle_emp_03, "octets lus", True),
    ("TRI", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-tri", "pass  # livrable-tri", "R-EMP-11", controle_emp_11, "ordre", True),
    ("LIEN-INTERMEDIAIRE", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-ouverture",
     "DRAPEAUX_LIVRABLE = os.O_RDONLY | SANS_BLOCAGE  # livrable-ouverture", "R-EMP-12", controle_emp_12, "lien", True),
    ("NONBLOCK", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-ouverture",
     "DRAPEAUX_LIVRABLE = os.O_RDONLY | SANS_SUIVI_DE_LIEN  # livrable-ouverture", "R-EMP-12", controle_emp_12, "O_NONBLOCK", True),
    ("DIRFD", "poser-verdict.sh", MARQUEUR_POSER, "# livrable-dirfd", "AVEC_DESCRIPTEURS = False  # livrable-dirfd",
     "R-EMP-12", controle_emp_12, "lien", True),
]


def sec_mut(ctx):
    filtre = [f for f in os.environ.get("VF_CLOT_MUTANTS", "").split(",") if f]
    for ident, nom, marqueur, motif, remplacement, cid, ctrl, mot, temoin in MUTANTS:
        if filtre and not any(f in ident for f in filtre):
            continue
        executer_mutant(ctx, ident, nom, marqueur, motif, remplacement, cid, ctrl, mot, temoin)


SECTIONS = {"emp": sec_emp, "ast": sec_ast, "plaf": sec_plaf, "juge": sec_juge, "mut": sec_mut}


def main():
    scripts_dir, work = sys.argv[2:4]
    ctx = Ctx(scripts_dir, work)
    for nom in sys.argv[1].split(","):
        SECTIONS[nom](ctx)


main()
PY_AIDES_CLOTURE_EMP_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-cloture-emp.txt"
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$WORK" > "$out" 2>&1
  rc=$?
  while IFS= read -r line; do
    printf '%s\n' "$line"
    case "$line" in
      "  ✓ "*) pass=$((pass+1)) ;;
      "  ✗ "*) fail=$((fail+1)) ;;
    esac
  done < "$out"
  if [ "$rc" -ne 0 ] && ! grep -q '^  ✗ ' "$out"; then
    ko "section $1" "les aides Python se terminent sans erreur" "code 0" "code $rc (voir la sortie ci-dessus)"
  fi
}

[ -f "$SCRIPTS_DIR/poser-verdict.sh" ] || ko "poser-verdict.sh présent" "la commande de verdict existe à côté des suites" "$SCRIPTS_DIR/poser-verdict.sh" "absent"

# VF_CLOT_SECTIONS (facultatif, pour rejouer une partie de la suite pendant le développement) ; VF_CLOT_MUTANTS filtre les mutants
# par fragment d'identifiant. Sans elles, toutes les sections tournent.
run_sections "${VF_CLOT_SECTIONS:-emp,ast,plaf,juge,mut}"

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
