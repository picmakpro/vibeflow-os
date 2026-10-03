#!/usr/bin/env bash
# test-cloture-empreintes.sh — le modèle de la pose d'un verdict : prédicat « livrable présent », empreinte composée des
# livrables, deux empreintes du VERDICT.md, plafond de trois tentatives, forme d'unité de juge (Phase 46, 46-01 ; CLOT-01,
# CLOT-03, CLOT-05 ; P46-D-03, P46-D-03a, P46-D-05, P46-D-06a, P46-D-10, P46-D-12).
#
# Familles :
#   R-EMP-01  le prédicat « livrable présent » (lstat par composant, vide, lien, FIFO, dossier, exclusions)
#   R-EMP-02  l'empreinte des livrables (stable, indépendante de l'ordre, sensible au contenu, insensible aux exclus et aux liens)
#   R-EMP-03  les bornes (2000 entrées, 128 Mio) : refus explicite, jamais une empreinte partielle
#   R-EMP-05  la commande pose `hash` et `hash_livrables`, relus identiques par le parseur, six clés dans l'ordre
#   R-EMP-06  la commande refuse (64) un livrable absent, vide ou lien, un ecrit: invalide, une borne dépassée
#   R-EMP-07  aucun refus ne porte le chemin absolu du lab, « no such file » ni « can't open » (P46-D-10)
#   MUT-*     chaque garde est tuée par un mutant à motif unique : la trace du rouge (assertion, attendu, obtenu) est imprimée ;
#             un mutant tué par la durée est interdit, il meurt par structure ou par verdict
#
# Sections (VF_CLOT_SECTIONS, facultatif) : emp, mut. Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`,
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
import stat
import subprocess
import sys

MARQUEUR_POSER = "PY_POSER_VERDICT_EOF"
UNITE = ".planning/cycles/01-c/phases/01-p"
SCRIPTS_COPIES = ("poser-verdict.sh", "planning-hook.sh", "recalc-planning.sh", "deroger-gate.sh")


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


def lancer(ctx, dossier, nom, args):
    p = subprocess.run(["bash", os.path.join(dossier, nom)] + list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env(), cwd=ctx.work, timeout=120)
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


def poser_cmd(ctx, dossier, lab, tentative, unite=UNITE, juge="vf-design-judge", extra=()):
    args = ["--unite=" + os.path.join(lab, unite), "--juge=" + juge, "--tentative=" + str(tentative), "--score=8/10",
            "--constat=critere-a::passé"] + list(extra)
    return lancer(ctx, dossier, "poser-verdict.sh", args)


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
    ns = charger_bloc(os.path.join(dossier, "poser-verdict.sh"))
    lab = lab_neuf(ctx, "emp01")
    cas = cas_predicat(lab)
    fautes = []
    for nom, entree, attendu in cas:
        statut, detail = ns["livrable_present"](lab, entree)
        if statut != attendu:
            fautes.append("cas « %s » (%s) : obtenu %s, attendu %s" % (nom, entree, statut, attendu))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d cas du prédicat conformes (fichier plein, vide, lien terminal et intermédiaire, pendant, dossier "
                          "vide, de zéros, d'exclus, de lien interne, imbriqué, absent, FIFO) avec leurs jumeaux non vides" % len(cas))


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
    statut, detail = ns["livrable_present"](lab, "d11")
    if statut != "borne":
        fautes.append("livrable_present sur 11 fichiers : %s, attendu borne" % statut)
    return (not fautes), ("; ".join(fautes) if fautes else
                          "valeurs livrées 2000 et 134217728 ; bornes abaissées à 10 et 4096 : la borne passe, une unité de plus est un "
                          "refus explicite qui la nomme, budget commun à toutes les entrées, aucune empreinte partielle")


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
    original = sur(ctrl, ctx, ctx.scripts_dir)
    mutant = sur(ctrl, ctx, d)
    if not original[0]:
        komut(ident, "l'original passe %s" % cid, "conforme", original[1])
        return
    if avec_temoin:
        t_orig, t_mut = temoin_pose(ctx, ctx.scripts_dir), temoin_pose(ctx, d)
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
    try:
        bon, detail = ctrl(ctx, dossier)
    except Exception as exc:
        bon, detail = False, "exception du contrôle : %s : %s" % (type(exc).__name__, str(exc)[:300])
    ok("%s %s : %s" % (ident, titre, detail)) if bon else ko(ident, titre, "conforme", detail)


def sec_emp(ctx):
    d = ctx.scripts_dir
    rendre("R-EMP-01", "prédicat « livrable présent »", controle_emp_01, ctx, d)
    rendre("R-EMP-02", "empreinte des livrables", controle_emp_02, ctx, d)
    rendre("R-EMP-03", "bornes de parcours", controle_emp_03, ctx, d)
    rendre("R-EMP-05", "la commande pose hash et hash_livrables", controle_emp_05, ctx, d)
    rendre("R-EMP-06", "la commande refuse un livrable absent, vide, lien, un ecrit: invalide, une borne dépassée", controle_emp_06, ctx, d)
    rendre("R-EMP-07", "aucun refus ne fuit un chemin absolu ni « no such file »", controle_emp_07, ctx, d)


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
]


def sec_mut(ctx):
    filtre = [f for f in os.environ.get("VF_CLOT_MUTANTS", "").split(",") if f]
    for ident, nom, marqueur, motif, remplacement, cid, ctrl, mot, temoin in MUTANTS:
        if filtre and not any(f in ident for f in filtre):
            continue
        executer_mutant(ctx, ident, nom, marqueur, motif, remplacement, cid, ctrl, mot, temoin)


SECTIONS = {"emp": sec_emp, "mut": sec_mut}


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
run_sections "${VF_CLOT_SECTIONS:-emp,mut}"

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
