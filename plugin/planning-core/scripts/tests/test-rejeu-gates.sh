#!/usr/bin/env bash
# test-rejeu-gates.sh — suite de l'outil de rejeu en lecture seule (rejeu-gates.sh) et du geste de
# rejeu sur labs réels (rejeu-reel.sh) — Phase 45, 45-03 ; GATE-13, GATE-15 ; P45-D-21, P45-D-21a,
# P45-D-21c, P45-D-03b. Tout se joue sur des labs SYNTHÉTIQUES sous un HOME jetable : aucun lab réel,
# aucun chemin de machine. Les hooks rejoués sont des SUBSTITUTS écrits sous WORK (jamais livrés).
#
# Familles :
#   R-REJEU-01  deux sens : faux refus et faux accept comptés par gate, refus-conforme-modele à part
#   R-REJEU-02  empreinte des labs identique avant/après (suite ET outil), config.json inchangé
#   R-REJEU-03  --etape arme sur la COPIE seulement (source inchangé) ; motif d'armement non unique = 1
#   R-REJEU-04  chemins sous HOME affichés `~/…`, jamais le chemin absolu
#   R-REJEU-05  node_modules/ n'est ni copié ni rejoué
#   R-REJEU-06  planning-hook.sh frère, lab neutre : 0 faux refus, 0 faux accept
#   R-REJEU-07  un substitut qui écrit dans le lab RÉEL : EMPREINTE-DIVERGENTE, code 1
#   R-REJEU-08  un seul attendu par écriture : priorité fichier d'attendus > gate > générique
#   R-REJEU-09  unicité : chaque triplet apparaît une fois, la somme des comptes = les clés distinctes
#   R-REJEU-10  attendu du modèle (P45-D-21a), classification totale (P45-D-21c), règle écrite
#   R-REJEU-STATIQUE  aucun sous-processus autre que bash sur le hook copié et cmp
#   R-REEL-01..04  rejeu-reel.sh : empreinte de TOUT l'arbre par un geste extérieur, liens non suivis,
#                  aucune commande de gestionnaire de versions
#   MUT-*  douze mutants (motif unique, texte distinct, bash -n, compilation) : chaque garde rougit
#
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ;
# comparaisons de fichiers par `cmp -s` ou Python. HOME est RÉASSIGNÉ et EXPORTÉ dans la suite.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REJEU="$SCRIPTS_DIR/rejeu-gates.sh"
REEL="$SCRIPTS_DIR/rejeu-reel.sh"
HOOK="$SCRIPTS_DIR/planning-hook.sh"
RECALC="$SCRIPTS_DIR/recalc-planning.sh"

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-rejeu-gates] python3 requis" >&2; exit 1; fi
    ;;
esac

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() {
  echo "  ✗ $1"
  echo "    assertion : $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/home" "$WORK/xdg"
export HOME="$WORK/home"
export XDG_CACHE_HOME="$WORK/xdg"
T_DEBUT="$(date +%s)"

AIDES="$WORK/aides.py"
cat > "$AIDES" <<'PY_AIDES_REJEU_EOF'
import ast
import hashlib
import importlib.util
import json
import os
import re
import stat
import subprocess
import sys

SCRIPTS, REJEU, REEL, HOOK, RECALC, WORK, PYBIN = sys.argv[2:9]
HOME = os.environ["HOME"]
PROTEGES = (".planning/STATE.md", ".planning/INDEX.md", ".planning/cloture.log",
            ".planning/cycles/01-c/STATE.md", ".planning/x/INDEX.md")
_n = [0]


def ok(libelle):
    print("  ✓ " + libelle)


def ko(libelle, assertion, attendu, obtenu):
    print("  ✗ " + libelle)
    print("    assertion : " + str(assertion))
    print("    attendu   : " + str(attendu))
    print("    obtenu    : " + str(obtenu))


def okmut(ident, texte):
    print("  ✓ MUT-%s TUÉ — %s" % (ident, texte))


def komut(ident, assertion, attendu, obtenu):
    print("  ✗ MUT-%s NON TUÉ" % ident)
    print("    assertion : " + str(assertion))
    print("    attendu (original) : " + str(attendu))
    print("    obtenu (mutant)     : " + str(obtenu))


def court(texte, n=220):
    if isinstance(texte, bytes):
        texte = texte.decode("utf-8", "replace")
    texte = str(texte).replace("\n", "\\n")
    return texte if len(texte) <= n else texte[:n] + "…"


def unique(prefixe):
    _n[0] += 1
    return prefixe + "-" + str(_n[0])


def ecrire(chemin, contenu, mode=None):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)
    if mode is not None:
        os.chmod(chemin, mode)


def fabriquer_lab(nom, fichiers, config='{"planning_version": "2.0"}'):
    """Lab synthétique sous HOME (config 2.0 par défaut : ni adhérent ni migré)."""
    racine = os.path.join(HOME, nom)
    if config is not None:
        ecrire(os.path.join(racine, ".planning", "config.json"), config)
    for rel, contenu in fichiers.items():
        ecrire(os.path.join(racine, rel), contenu)
    return racine


def empreinte_arbre(racine):
    """Empreinte INDÉPENDANTE de l'outil, écrite pour la suite : chemin, type, mode, sha256 ou cible,
    aucun lien suivi."""
    lignes = []
    for dossier, dossiers, fichiers in os.walk(racine, followlinks=False):
        dossiers.sort()
        for nom in sorted(dossiers + fichiers):
            chemin = os.path.join(dossier, nom)
            rel = os.path.relpath(chemin, racine)
            st = os.lstat(chemin)
            if stat.S_ISLNK(st.st_mode):
                lignes.append("%s l %s" % (rel, os.readlink(chemin)))
            elif stat.S_ISDIR(st.st_mode):
                lignes.append("%s d %o" % (rel, stat.S_IMODE(st.st_mode)))
            else:
                with open(chemin, "rb") as fh:
                    lignes.append("%s f %o %s" % (rel, stat.S_IMODE(st.st_mode), hashlib.sha256(fh.read()).hexdigest()))
    return hashlib.sha256("\n".join(lignes).encode("utf-8")).hexdigest()


# --- Substituts de hook (jamais livrés) ------------------------------------------------------------
TETE_SUBSTITUT = '''#!/usr/bin/env bash
T="$(mktemp "${TMPDIR:-/tmp}/vf-substitut.XXXXXX")" || exit 70
trap 'rm -f "$T"' EXIT
cat > "$T" || exit 71
@PY@ -I -S - "$T" <<'PY_SUBSTITUT_EOF'
import json, os, sys
ARMEMENT_G6 = "observe"  # etape-1
ARMEMENT_G5 = "observe"  # etape-1
ARMEMENT_G1 = "observe"  # etape-2
ARMEMENT_G7 = "observe"  # etape-3
ARMEMENT_ROLE = "observe"  # etape-4
p = json.load(open(sys.argv[1], encoding="utf-8"))
outil = p.get("tool_name")
ti = p.get("tool_input") or {}
chemin = ti.get("file_path") or ti.get("notebook_path") or ""
ARMES = [g for g in ("G6", "G5", "G1", "G7", "ROLE") if globals()["ARMEMENT_" + g] == "armed"]


def refuser(gate, texte):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                             "permissionDecisionReason": "[planning-core] " + gate + " : " + texte}}))
    sys.exit(0)

'''


def substitut(nom, corps=""):
    chemin = os.path.join(WORK, "substituts", nom)
    ecrire(chemin, TETE_SUBSTITUT.replace("@PY@", PYBIN) + corps + "\nPY_SUBSTITUT_EOF\n", 0o755)
    return chemin


SUB_PASSE = "pass"
SUB_TOUT = 'refuser("G6", "armes=" + ",".join(ARMES))'


# --- Extraction du Python embarqué et lancement (avec constructeurs d'essai) -----------------------
def extraire(script, marqueur, cible):
    corps, dedans = [], False
    for ligne in open(script, encoding="utf-8").read().split("\n"):
        if ligne == marqueur:
            dedans = False
        if dedans:
            corps.append(ligne)
        if ligne.endswith("<<'" + marqueur + "'"):
            dedans = True
    ecrire(cible, "\n".join(corps) + "\n")
    return cible


CONSTRUCTEURS_ESSAI = r'''
import json, os, subprocess, sys

RECALC = sys.argv[1]
PROTEGES = json.loads(sys.argv[2])


def etats(lab):
    p = subprocess.run(["bash", RECALC, "--planning=" + os.path.join(lab.copie, ".planning"), "--read-only"],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        donnees = json.loads(p.stdout.decode("utf-8"))
    except ValueError:
        return {}
    res = {}
    for cycle in donnees.get("cycles", []):
        for phase in cycle.get("phases", []):
            res[".planning/" + phase["chemin"] + "/PLAN.md"] = (phase["etat"], phase.get("raison"))
    return res


def exploitable(etat, raison):
    if etat != "indéterminé":
        return True
    r = raison or ""
    return r.startswith("hors-cadrage:") or r.startswith("avant-cadrage-clos:") or r == "registre-invalide" \
        or r == "frontmatter-invalide:CADRAGE.md"


def plans(lab):
    return [r for r in lab.fichiers_planning if r.endswith("/PLAN.md")]


def g6_state(lab, ctx):
    return [("Write", ".planning/STATE.md", "doit-refuser", "")]


def g6_protege(lab, ctx):
    return [("Write", rel, "doit-refuser-modele", "") for rel in PROTEGES if rel in lab.fichiers_planning]


def g1_modele(lab, ctx):
    derives = etats(lab)
    sortie = []
    for rel in plans(lab):
        etat, raison = derives[rel]
        sortie.append(("Write", rel, "doit-passer" if etat not in ("indéterminé", "à cadrer", "en cadrage") else "doit-refuser-modele", ""))
    return sortie


g1_modele.classe_modele = True


def _regle(lab, avec_origine):
    derives = etats(lab)
    sortie = []
    for rel in plans(lab):
        etat = derives.get(rel)
        if etat is not None and exploitable(*etat):
            sortie.append(("Write", rel, "doit-passer" if etat[0] not in ("indéterminé", "à cadrer", "en cadrage") else "doit-refuser-modele", ""))
            continue
        cadrage = os.path.join(os.path.dirname(rel), "CADRAGE.md")
        clos = False
        if cadrage in lab.fichiers_planning:
            clos = "statut" in open(os.path.join(lab.copie, cadrage), encoding="utf-8").read()
        attendu = "doit-passer" if clos else "doit-refuser-modele"
        sortie.append(("Write", rel, attendu, "", "regle-ecrite") if avec_origine else ("Write", rel, attendu, ""))
    return sortie


def g1_regle(lab, ctx):
    return _regle(lab, True)


def g1_regle_omise(lab, ctx):
    return _regle(lab, False)


g1_regle.classe_modele = True
g1_regle_omise.classe_modele = True


def g1_total_vide(lab, ctx):
    return [("Write", rel, None, "") for rel in plans(lab)]


def g1_total_hors(lab, ctx):
    return [("Write", rel, "peut-etre", "") for rel in plans(lab)]


g1_total_vide.classe_modele = True
g1_total_hors.classe_modele = True

SCENARIOS = {
    "g6-state": ("G6", g6_state),
    "g6-protege": ("G6", g6_protege),
    "g1-modele": ("G1", g1_modele),
    "g1-regle": ("G1", g1_regle),
    "g1-regle-omise": ("G1", g1_regle_omise),
    "g1-total-vide": ("G1", g1_total_vide),
    "g1-total-hors": ("G1", g1_total_hors),
}
'''

LANCEUR_ESSAI = r'''
import importlib.util, os, sys
corps, scenario, recalc, proteges = sys.argv[1:5]
reste = sys.argv[5:]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location("rejeu_module", corps)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
sys.argv = [sys.argv[0], recalc, proteges]
import constructeurs_essai as ce
gate, fonction = ce.SCENARIOS[scenario]
mod.CONSTRUCTEURS[gate] = fonction
sys.exit(mod.main(reste))
'''


def preparer_essais():
    ecrire(os.path.join(WORK, "essais", "constructeurs_essai.py"), CONSTRUCTEURS_ESSAI)
    ecrire(os.path.join(WORK, "essais", "lanceur_essai.py"), LANCEUR_ESSAI)


def env_sain():
    return {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": HOME, "XDG_CACHE_HOME": os.environ.get("XDG_CACHE_HOME", "")}


class Resultat:
    def __init__(self, rc, out, err, rapport):
        self.rc, self.out, self.err, self.rapport = rc, out, err, rapport
        self.lignes, self.compte, self.etape, self.classe, self.empreintes = [], {}, None, {}, []
        for l in out.split("\n"):
            if l.startswith("COMPTE "):
                m = re.match(r"COMPTE (\S+) faux-refus=(\d+) faux-accept=(\d+) refus-conforme-modele=(\d+)$", l)
                if m:
                    self.compte[m.group(1)] = tuple(int(m.group(i)) for i in (2, 3, 4))
            elif l.startswith("REJEU-ETAPE-"):
                m = re.match(r"REJEU-ETAPE-(\d) faux-refus=(\d+) faux-accept=(\d+) refus-conforme-modele=(\d+)$", l)
                if m:
                    self.etape = tuple(int(m.group(i)) for i in (2, 3, 4))
            elif l.startswith("CLASSE-REGLE-ECRITE "):
                m = re.match(r"CLASSE-REGLE-ECRITE (\S+) lab=(\S+) n=(\d+)$", l)
                if m:
                    self.classe[(m.group(1), m.group(2))] = int(m.group(3))
            elif l.startswith("EMPREINTE-"):
                self.empreintes.append(l)
            elif l.count(" | ") == 5:
                self.lignes.append(tuple(l.split(" | ")))

    def lignes_chemin(self, fin):
        return [l for l in self.lignes if l[2].endswith(fin)]


def rejeu(labs, hook=None, etape=1, attendus=None, scenario=None, script=None, reel=False, rapport=True, extra=()):
    args = ["--lab=" + l for l in labs] + ["--etape=" + str(etape)]
    if hook:
        args.append("--hook=" + hook)
    if attendus:
        args.append("--attendus=" + attendus)
    chemin_rapport = os.path.join(WORK, unique("rapport") + ".txt")
    if rapport:
        args.append("--rapport=" + chemin_rapport)
    args += list(extra)
    script = script or (REEL if reel else REJEU)
    if scenario:
        corps = extraire(script, "PY_REJEU_GATES_EOF", os.path.join(WORK, "essais", unique("module") + ".py"))
        cmd = [PYBIN, os.path.join(WORK, "essais", "lanceur_essai.py"), corps, scenario, RECALC, json.dumps(list(PROTEGES))] + args
    else:
        cmd = ["bash", script] + args
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env_sain(), timeout=600)
    texte = ""
    if rapport and os.path.isfile(chemin_rapport):
        texte = open(chemin_rapport, encoding="utf-8").read()
    return Resultat(p.returncode, p.stdout.decode("utf-8"), p.stderr.decode("utf-8"), texte)


def ecrire_attendus(lignes):
    chemin = os.path.join(WORK, unique("attendus") + ".txt")
    ecrire(chemin, "# attendus d'essai\n" + "\n".join(lignes) + "\n")
    return chemin


# =================================================================================================
# Sections
# =================================================================================================
def sec_sens(_):
    """R-REJEU-01 à R-REJEU-05."""
    a = fabriquer_lab("lab-a", {".planning/interdit/x.md": "x", ".planning/notes.md": "n"})
    b = fabriquer_lab("lab-b", {".planning/y.md": "y"})
    sub = substitut("sub-interdit.sh", 'if ARMEMENT_G6 == "armed" and "/interdit/" in chemin: refuser("G6", "chemin interdit")')
    att = ecrire_attendus(["G6 | ~/lab-b | .planning/y.md | doit-refuser | un chemin que le substitut laisse passer"])
    avant = (empreinte_arbre(a), empreinte_arbre(b))
    r = rejeu([a, b], hook=sub, attendus=att)
    apres = (empreinte_arbre(a), empreinte_arbre(b))

    # R-REJEU-01
    g6 = r.compte.get("G6")
    if r.rc == 0 and g6 == (1, 1, 0) and r.etape == (1, 1, 0) and r.compte.get("G5") == (0, 0, 0):
        ok("R-REJEU-01 deux labs : un doit-passer refusé compte faux-refus=1 pour G6, un doit-refuser laissé passer compte faux-accept=1 ; REJEU-ETAPE-1 porte les deux comptes et refus-conforme-modele=0")
    else:
        ko("R-REJEU-01", "COMPTE G6 et REJEU-ETAPE-1 sur deux labs avec un substitut qui refuse /interdit/", "G6 (1, 1, 0), REJEU-ETAPE-1 (1, 1, 0), G5 (0, 0, 0), code 0",
           "rc=%d G6=%s etape=%s G5=%s err=%s" % (r.rc, g6, r.etape, r.compte.get("G5"), court(r.err)))

    # R-REJEU-02
    cfg_ok = all(open(os.path.join(l, ".planning", "config.json"), encoding="utf-8").read() == '{"planning_version": "2.0"}' for l in (a, b))
    lignes_e = [l for l in r.empreintes if l.startswith("EMPREINTE-IDENTIQUE ")]
    if avant == apres and cfg_ok and sorted(lignes_e) == ["EMPREINTE-IDENTIQUE ~/lab-a", "EMPREINTE-IDENTIQUE ~/lab-b"] and not any("DIVERGENTE" in l for l in r.empreintes):
        ok("R-REJEU-02 empreinte des deux labs identique avant/après (suite et outil : deux lignes EMPREINTE-IDENTIQUE), config.json toujours \"2.0\"")
    else:
        ko("R-REJEU-02", "aucun lab réel modifié", "empreintes identiques, config 2.0, deux EMPREINTE-IDENTIQUE",
           "suite=%s config=%s outil=%s" % (avant == apres, cfg_ok, r.empreintes))

    # R-REJEU-03 : l'armement de la copie
    lab3 = fabriquer_lab("lab-c3", {".planning/notes.md": "n"})
    sub3 = substitut("sub-armes.sh", SUB_TOUT)
    source_avant = open(sub3, "rb").read()
    fautes = []
    for etape, attendu in ((1, "armes=G6,G5"), (2, "armes=G6,G5,G1"), (4, "armes=G6,G5,G1,G7,ROLE")):
        r3 = rejeu([lab3], hook=sub3, etape=etape)
        vus = set(l[5] for l in r3.lignes)
        if vus != {"[planning-core] G6 : " + attendu}:
            fautes.append("étape %d : attendu %s, obtenu %s" % (etape, attendu, sorted(vus)))
    if open(sub3, "rb").read() != source_avant:
        fautes.append("le script source a été modifié")
    double = substitut("sub-double.sh", "pass\nARMEMENT_G6 = \"observe\"  # doublon")
    r3d = rejeu([lab3], hook=double, etape=1)
    if r3d.rc != 1 or "motif d'armement non unique" not in r3d.err:
        fautes.append("substitut à deux lignes ARMEMENT_G6 : attendu code 1 et « motif d'armement non unique », obtenu rc=%d err=%s" % (r3d.rc, court(r3d.err)))
    if fautes:
        ko("R-REJEU-03", "l'étape n arme les lignes des étapes <= n sur la copie, jamais sur la source", "armes=G6,G5 / +G1 / tout ; source inchangée ; doublon = code 1", "; ".join(fautes))
    else:
        ok("R-REJEU-03 --etape=1, 2, 4 arme G6 et G5 / + G1 / tout sur la copie (G7 et ROLE restent observe à l'étape 2), source inchangée, deux lignes ARMEMENT_G6 = code 1 « motif d'armement non unique »")

    # R-REJEU-04
    abs_home = [HOME, os.path.realpath(HOME)]
    fuites = [h for h in abs_home if h in r.out or h in r.rapport]
    if not fuites and any(l[1] == "~/lab-a" for l in r.lignes) and any(l[1] == "~/lab-b" for l in r.lignes):
        ok("R-REJEU-04 labs sous HOME affichés ~/lab-a et ~/lab-b, le chemin absolu du HOME n'apparaît ni sur stdout ni dans le rapport")
    else:
        ko("R-REJEU-04", "affichage ~/… sous HOME", "~/lab-a, ~/lab-b et aucun chemin absolu", "fuites=%s lignes=%s" % (fuites, [l[1] for l in r.lignes][:4]))

    # R-REJEU-05
    lab5 = fabriquer_lab("lab-c5", {".planning/notes.md": "n", "node_modules/pkg/.planning/config.json": "{}",
                                    "node_modules/pkg/.planning/secret.md": "s", ".git/.planning/g.md": "g"})
    r5 = rejeu([lab5], hook=substitut("sub-passe.sh", SUB_PASSE))
    if r5.rc == 0 and r5.lignes and not any("node_modules" in l[2] or ".git" in l[2] for l in r5.lignes):
        ok("R-REJEU-05 le sous-arbre node_modules/ (avec un .planning/ dedans) et .git/ ne sont ni copiés ni rejoués")
    else:
        ko("R-REJEU-05", "élagage node_modules, .git", "aucune ligne sous node_modules ni .git", "rc=%d lignes=%s" % (r5.rc, [l[2] for l in r5.lignes]))


def sec_reel_hook(_):
    """R-REJEU-06 et R-REJEU-07."""
    neutre = fabriquer_lab("lab-neutre", {".planning/notes.md": "n", "livrables/rapport.md": "r"})
    r = rejeu([neutre], hook=None, etape=1)
    if r.rc == 0 and r.compte.get("G6") == (0, 0, 0) and r.compte.get("G5") == (0, 0, 0) and r.etape == (0, 0, 0):
        ok("R-REJEU-06 planning-hook.sh frère, --etape=1, lab neutre (config, notes.md, livrables/) : faux-refus=0 faux-accept=0 quel que soit le contenu du hook frère")
    else:
        ko("R-REJEU-06", "hook réel sur un lab neutre", "REJEU-ETAPE-1 (0, 0, 0), code 0", "rc=%d etape=%s compte=%s err=%s" % (r.rc, r.etape, r.compte, court(r.err)))

    lab7 = fabriquer_lab("lab-d7", {".planning/notes.md": "n"})
    sub7 = substitut("sub-ecrit.sh", 'open(%r, "w").write("intrus")' % os.path.join(lab7, ".planning", "intrus.md"))
    r7 = rejeu([lab7], hook=sub7)
    if r7.rc == 1 and any(l == "EMPREINTE-DIVERGENTE ~/lab-d7" for l in r7.empreintes):
        ok("R-REJEU-07 un substitut qui écrit dans le lab réel pendant le rejeu : EMPREINTE-DIVERGENTE et code 1")
    else:
        ko("R-REJEU-07", "écriture dans le lab réel détectée", "code 1 et EMPREINTE-DIVERGENTE ~/lab-d7", "rc=%d empreintes=%s" % (r7.rc, r7.empreintes))


def sec_priorite(_):
    """R-REJEU-08 et R-REJEU-09."""
    lab = fabriquer_lab("lab-e8", {".planning/STATE.md": "s", ".planning/notes.md": "n"})
    refuse = substitut("sub-state.sh", 'if ARMEMENT_G6 == "armed" and chemin.endswith("/.planning/STATE.md"): refuser("G6", "STATE.md ecrit par outil")')
    passe = substitut("sub-passe8.sh", SUB_PASSE)
    fautes = []
    r = rejeu([lab], hook=refuse, scenario="g6-state")
    l = r.lignes_chemin(".planning/STATE.md")
    if not (len(l) == 1 and l[0][3] == "doit-refuser" and l[0][4] == "refus" and r.compte.get("G6") == (0, 0, 0)):
        fautes.append("(a) constructeur G6 doit-refuser sur la clé de la réécriture générique : %s compte=%s" % (l, r.compte.get("G6")))
    r = rejeu([lab], hook=passe, scenario="g6-state")
    if r.compte.get("G6") != (0, 1, 0):
        fautes.append("(b) substitut qui laisse passer : attendu faux-accept=1 et faux-refus=0, obtenu %s" % (r.compte.get("G6"),))
    att = ecrire_attendus(["G6 | ~/lab-e8 | .planning/STATE.md | doit-passer | le fichier d'attendus prime"])
    r = rejeu([lab], hook=refuse, scenario="g6-state", attendus=att)
    l = r.lignes_chemin(".planning/STATE.md")
    if not (len(l) == 1 and l[0][3] == "doit-passer" and r.compte.get("G6") == (1, 0, 0)):
        fautes.append("(c) une ligne doit-passer du fichier d'attendus l'emporte sur le constructeur : %s compte=%s" % (l, r.compte.get("G6")))
    contra = ecrire_attendus(["G6 | ~/lab-e8 | .planning/STATE.md | doit-passer | a", "G5 | ~/lab-e8 | .planning/STATE.md | doit-refuser | b"])
    r = rejeu([lab], hook=refuse, scenario="g6-state", attendus=contra)
    if r.rc != 1 or "attendus contradictoires" not in r.err:
        fautes.append("(d) deux attendus contradictoires : attendu code 1 et « attendus contradictoires », obtenu rc=%d err=%s" % (r.rc, court(r.err)))
    if fautes:
        for f in fautes:
            ko("R-REJEU-08", "un seul attendu par écriture, priorité fichier d'attendus > gate > générique", "voir le cas", f)
    else:
        ok("R-REJEU-08 une ligne par clé (outil, chemin, agent_type) : le constructeur d'un gate prime sur la réécriture générique, le fichier d'attendus sur le gate, deux attendus contradictoires = code 1, faux-accept sans faux-refus en plus")

    # R-REJEU-09 : unicité, sur cinq fichiers protégés et dix ordinaires
    fichiers = {rel: "p" for rel in PROTEGES}
    for i in range(9):
        fichiers[".planning/ordinaire-%d.md" % i] = "o"
    lab9 = fabriquer_lab("lab-f9", fichiers)
    tout = substitut("sub-tout9.sh", 'refuser("G6", "tout refuse")')
    r = rejeu([lab9], hook=tout, scenario="g6-protege")
    cles = [(l[1], l[2]) for l in r.lignes]
    doublons = sorted(set(c for c in cles if cles.count(c) > 1))
    somme = sum(sum(c) for c in r.compte.values())
    if not doublons and len(cles) == 15 and somme == 15 and r.compte.get("G6") == (10, 0, 5):
        ok("R-REJEU-09 cinq fichiers protégés et dix ordinaires : chaque clé apparaît UNE fois (15 lignes, aucun doublon), la somme des comptes par gate (15) égale les clés distinctes")
    else:
        ko("R-REJEU-09", "unicité des clés dans le relevé", "15 lignes distinctes, somme des comptes 15, G6 (10, 0, 5)",
           "lignes=%d doublons=%s somme=%d G6=%s" % (len(cles), doublons[:3], somme, r.compte.get("G6")))


def lab_trois_phases(nom, avec_cycle=True):
    clos = ('---\ninconnues:\n  - id: I-01\n    question: "Q ?"\n    structurante: oui\n    statut: ARBITRÉ\n'
            '    par: willy\n    le: "2026-09-27"\n    ou: "session"\n---\n')
    ouvert = '---\ninconnues:\n  - id: I-01\n    question: "Q ?"\n    structurante: oui\n---\n'
    f = {".planning/cycles/01-c/phases/01-a/PLAN.md": "---\necrit: livrables/a.md\n---\n",
         ".planning/cycles/01-c/phases/02-b/CADRAGE.md": clos,
         ".planning/cycles/01-c/phases/02-b/PLAN.md": "---\necrit: livrables/b.md\n---\n",
         ".planning/cycles/01-c/phases/03-c/CADRAGE.md": ouvert,
         ".planning/cycles/01-c/phases/03-c/PLAN.md": "---\necrit: livrables/c.md\n---\n"}
    if avec_cycle:
        f[".planning/cycles/01-c/CYCLE.md"] = "---\ntitre: Cycle\nrend:\n  - livrables/r.md\n---\n"
    return fabriquer_lab(nom, f)


SUB_G1 = '''if chemin.endswith("/PLAN.md"):
    d = os.path.dirname(chemin)
    cad = os.path.join(d, "CADRAGE.md")
    if not os.path.isfile(cad):
        refuser("G1", "phase sans CADRAGE.md")
    if "statut" not in open(cad, encoding="utf-8").read():
        refuser("G1", "registre de cadrage ouvert")'''


def sec_modele(_):
    """R-REJEU-10."""
    lab = lab_trois_phases("lab-g10")
    sub = substitut("sub-g1.sh", SUB_G1)
    sub_b = substitut("sub-g1-b.sh", SUB_G1 + '\nif "/02-b/" in chemin and chemin.endswith("/PLAN.md"):\n    refuser("G1", "refuse B aussi")')
    sub_c = substitut("sub-g1-c.sh", 'if chemin.endswith("/PLAN.md") and "/03-c/" in chemin:\n    refuser("G1", "registre ouvert")')
    fautes = []
    r = rejeu([lab], hook=sub, scenario="g1-modele")
    plans = sorted(r.lignes_chemin("PLAN.md"), key=lambda x: x[2])
    if len(plans) != 3 or [p[3] for p in plans] != ["doit-refuser-modele", "doit-passer", "doit-refuser-modele"] \
            or [p[4] for p in plans] != ["refus", "passe", "refus"] or plans[0][5] != "refus conforme au modèle, lab non migré" \
            or plans[2][5] != "refus conforme au modèle, lab non migré":
        fautes.append("(a) trois lignes A, B, C : %s" % (plans,))
    if r.compte.get("G1") != (0, 0, 2) or r.etape != (0, 0, 2) or r.classe.get(("G1", "~/lab-g10")) != 0:
        fautes.append("(a) comptes : G1=%s etape=%s classe=%s (attendu (0, 0, 2), (0, 0, 2), n=0)" % (r.compte.get("G1"), r.etape, r.classe))
    r = rejeu([lab], hook=sub_b, scenario="g1-modele")
    if r.compte.get("G1") != (1, 0, 2):
        fautes.append("(b) un substitut qui refuse B aussi : attendu faux-refus=1, refus-conforme-modele=2, obtenu %s" % (r.compte.get("G1"),))
    r = rejeu([lab], hook=sub_c, scenario="g1-modele")
    if r.compte.get("G1") != (0, 1, 1):
        fautes.append("(c) un substitut qui laisse passer A : attendu faux-accept=1, refus-conforme-modele=1, obtenu %s" % (r.compte.get("G1"),))
    att = ecrire_attendus(["G1 | ~/lab-g10 | .planning/cycles/01-c/phases/01-a/PLAN.md | doit-passer | le fichier d'attendus prime"])
    r = rejeu([lab], hook=sub, scenario="g1-modele", attendus=att)
    a = r.lignes_chemin("01-a/PLAN.md")
    if not (len(a) == 1 and a[0][3] == "doit-passer" and r.compte.get("G1") == (1, 0, 1)):
        fautes.append("(d) attendu doit-passer sur la clé de A : %s compte=%s" % (a, r.compte.get("G1")))

    # règle écrite : un cycle SANS CYCLE.md (le recalcul rend phases: [])
    lab_r = lab_trois_phases("lab-h10", avec_cycle=False)
    r = rejeu([lab_r], hook=sub, scenario="g1-regle")
    a = r.lignes_chemin("01-a/PLAN.md")
    if r.classe.get(("G1", "~/lab-h10")) != 3 or not a or "classé par la règle écrite, état dérivé absent" not in a[0][5] \
            or r.compte.get("G1") != (0, 0, 2):
        fautes.append("(e) origine regle-ecrite : classe=%s ligne=%s compte=%s" % (r.classe, a, r.compte.get("G1")))
    r = rejeu([lab_r], hook=sub, scenario="g1-regle-omise")
    if r.classe.get(("G1", "~/lab-h10")) != 0:
        fautes.append("(f) origine omise : attendu n=0, obtenu %s" % (r.classe,))

    # totalité
    for scen in ("g1-total-vide", "g1-total-hors"):
        r = rejeu([lab], hook=sub, scenario=scen)
        if r.rc != 1 or "classification absente :" not in r.err or any(l[3] == "doit-passer" and l[2].endswith("PLAN.md") for l in r.lignes):
            fautes.append("(g) %s : attendu code 1, « classification absente : », aucun doit-passer ; obtenu rc=%d err=%s" % (scen, r.rc, court(r.err)))
    if fautes:
        for f in fautes:
            ko("R-REJEU-10", "attendu du modèle (P45-D-21a), classification totale (P45-D-21c)", "voir le cas", f)
    else:
        ok("R-REJEU-10 attendu du modèle : A et C refus conformes (2), B jamais rangé en refus conforme (faux-refus si refusé), faux-accept si A passe, fichier d'attendus prioritaire, règle écrite comptée par CLASSE-REGLE-ECRITE (n=3 puis n=0), classification absente = code 1")


def _appels_sous_process(script, marqueur, autorises):
    """Violations : tout appel de sous-processus dont l'argv n'est pas une liste dont le premier
    élément est un des littéraux `autorises`, et tout autre moyen de lancer un programme."""
    corps = extraire(script, marqueur, os.path.join(WORK, unique("statique") + ".py"))
    arbre = ast.parse(open(corps, encoding="utf-8").read())
    violations, vus = [], 0
    for noeud in ast.walk(arbre):
        if not isinstance(noeud, ast.Call):
            continue
        f = noeud.func
        nom = ""
        if isinstance(f, ast.Attribute) and isinstance(f.value, ast.Name):
            nom = f.value.id + "." + f.attr
        if nom.startswith("os.") and f.attr in ("system", "popen", "fork", "spawnl", "spawnv", "spawnlp", "spawnvp", "execv", "execl", "execvp", "execlp"):
            violations.append(nom)
        if nom.startswith("subprocess."):
            if f.attr != "run":
                violations.append(nom)
                continue
            vus += 1
            premier = noeud.args[0] if noeud.args else None
            while isinstance(premier, ast.BinOp):
                premier = premier.left
            if not (isinstance(premier, ast.List) and premier.elts and isinstance(premier.elts[0], ast.Constant)
                    and premier.elts[0].value in autorises):
                violations.append("subprocess.run avec un argv non littéral autorisé")
            for mot in noeud.keywords:
                if mot.arg == "shell":
                    violations.append("shell=")
    texte = open(corps, encoding="utf-8").read()
    for mot in ("Popen", "check_output", "check_call", "shell=True"):
        if mot in texte:
            violations.append(mot)
    for elt in ast.walk(arbre):
        if isinstance(elt, ast.Constant) and elt.value in ("git", "hg", "svn"):
            violations.append("littéral " + elt.value)
    return violations, vus


def sec_statique(_):
    """R-REJEU-STATIQUE et R-REEL-04."""
    v, n = _appels_sous_process(REJEU, "PY_REJEU_GATES_EOF", ("bash", "cmp"))
    if not v and n == 2:
        ok("R-REJEU-STATIQUE le texte de rejeu-gates.sh ne lance aucun sous-processus autre que bash sur le hook copié et cmp (2 appels, aucun git)")
    else:
        ko("R-REJEU-STATIQUE", "sous-processus de rejeu-gates.sh", "bash (hook copié) et cmp seulement, 2 appels", "violations=%s appels=%d" % (v, n))
    v, n = _appels_sous_process(REEL, "PY_REJEU_REEL_EOF", ("bash", "cmp"))
    if not v and n == 2:
        ok("R-REEL-04 le texte de rejeu-reel.sh ne lance aucun sous-processus autre que bash sur rejeu-gates.sh et cmp (2 appels, aucun git)")
    else:
        ko("R-REEL-04", "sous-processus de rejeu-reel.sh", "bash (rejeu-gates.sh) et cmp seulement, 2 appels", "violations=%s appels=%d" % (v, n))


def sec_reel(_):
    """R-REEL-01 à R-REEL-03."""
    a = fabriquer_lab("lab-r1a", {".planning/notes.md": "n"})
    b = fabriquer_lab("lab-r1b", {".planning/notes.md": "n"})
    sub = substitut("sub-passe-reel.sh", SUB_PASSE)
    r = rejeu([a, b], hook=sub, reel=True)
    lignes = r.rapport.rstrip("\n").split("\n")
    dernieres = lignes[-2:]
    idx_gates = max(i for i, l in enumerate(lignes) if l.startswith("EMPREINTE-IDENTIQUE "))
    if r.rc == 0 and dernieres == ["EMPREINTE-ARBRE-IDENTIQUE ~/lab-r1a", "EMPREINTE-ARBRE-IDENTIQUE ~/lab-r1b"] and idx_gates < len(lignes) - 2:
        ok("R-REEL-01 rejeu-reel.sh sur deux labs et un substitut inoffensif : deux lignes EMPREINTE-ARBRE-IDENTIQUE ajoutées au rapport après celles de rejeu-gates.sh, code 0")
    else:
        ko("R-REEL-01", "geste de rejeu réel, labs intacts", "code 0, deux EMPREINTE-ARBRE-IDENTIQUE après celles de l'outil", "rc=%d fin=%s err=%s" % (r.rc, dernieres, court(r.err)))

    lab2 = fabriquer_lab("lab-r2", {".planning/notes.md": "n", "src/a.txt": "a"})
    ecrit = substitut("sub-src.sh", 'open(%r, "w").write("nouveau")' % os.path.join(lab2, "src", "nouveau.txt"))
    r = rejeu([lab2], hook=ecrit, reel=True)
    if r.rc == 1 and "EMPREINTE-ARBRE-DIVERGENTE ~/lab-r2" in r.rapport and "EMPREINTE-IDENTIQUE ~/lab-r2" in r.rapport:
        ok("R-REEL-02 un substitut qui écrit src/nouveau.txt HORS du périmètre que rejeu-gates.sh copie : EMPREINTE-ARBRE-DIVERGENTE et code 1, alors que la ligne EMPREINTE-IDENTIQUE de rejeu-gates.sh ne voit rien")
    else:
        ko("R-REEL-02", "écriture hors périmètre détectée par l'empreinte de tout l'arbre", "code 1, EMPREINTE-ARBRE-DIVERGENTE, EMPREINTE-IDENTIQUE de l'outil", "rc=%d rapport=%s" % (r.rc, court(r.rapport)))

    # R-REEL-03 : liens non suivis
    dehors = os.path.join(HOME, "dehors-r3")
    ecrire(os.path.join(dehors, "cible.txt"), "contenu")
    ecrire(os.path.join(dehors, "autre.txt"), "autre")
    lab3 = fabriquer_lab("lab-r3", {".planning/notes.md": "n", "src/f.txt": "f"})
    os.symlink(os.path.join(dehors, "cible.txt"), os.path.join(lab3, "lien-fichier"))
    os.chmod(os.path.join(lab3, "src", "f.txt"), 0o644)
    fautes = []
    modif = substitut("sub-dehors.sh", 'open(%r, "w").write("modifie dehors")' % os.path.join(dehors, "cible.txt"))
    r = rejeu([lab3], hook=modif, reel=True)
    if not (r.rc == 0 and "EMPREINTE-ARBRE-IDENTIQUE ~/lab-r3" in r.rapport):
        fautes.append("fichier extérieur modifié : attendu IDENTIQUE, obtenu rc=%d %s" % (r.rc, court(r.rapport)))
    cible = substitut("sub-cible.sh", 'lien = %r\nif os.path.islink(lien):\n    os.remove(lien)\n    os.symlink(%r, lien)' % (
        os.path.join(lab3, "lien-fichier"), os.path.join(dehors, "autre.txt")))
    r = rejeu([lab3], hook=cible, reel=True)
    if not (r.rc == 1 and "EMPREINTE-ARBRE-DIVERGENTE ~/lab-r3" in r.rapport):
        fautes.append("cible du lien changée : attendu DIVERGENTE, obtenu rc=%d %s" % (r.rc, court(r.rapport)))
    lab3b = fabriquer_lab("lab-r3b", {".planning/notes.md": "n", "src/f.txt": "f"})
    os.chmod(os.path.join(lab3b, "src", "f.txt"), 0o644)
    mode = substitut("sub-mode.sh", 'os.chmod(%r, 0o600)' % os.path.join(lab3b, "src", "f.txt"))
    r = rejeu([lab3b], hook=mode, reel=True)
    if not (r.rc == 1 and "EMPREINTE-ARBRE-DIVERGENTE ~/lab-r3b" in r.rapport):
        fautes.append("mode d'un fichier changé : attendu DIVERGENTE, obtenu rc=%d %s" % (r.rc, court(r.rapport)))
    if fautes:
        for f in fautes:
            ko("R-REEL-03", "liens jamais suivis, mode et cible comptent", "voir le cas", f)
    else:
        ok("R-REEL-03 un lien vers un fichier extérieur : modifier ce fichier ne change pas l'empreinte ; changer la cible du lien ou le mode d'un fichier la change")


# --- Mutants ----------------------------------------------------------------------------------------
def make_mutant(source, marqueur, ident, motif, remplacement, compagnons=()):
    """Copie de `source` dont l'UNIQUE ligne portant `motif` est remplacée (indentation conservée) ;
    `compagnons` : autres scripts copiés à côté. Rend (chemin, None) ou (None, raison)."""
    original = open(source, encoding="utf-8").read()
    lignes = original.split("\n")
    idx = [i for i, l in enumerate(lignes) if motif in l]
    if len(idx) != 1 or original.count(motif) != 1:
        return None, "MOTIF AMBIGU OU ABSENT (lignes=%d, occurrences=%d)" % (len(idx), original.count(motif))
    ligne = lignes[idx[0]]
    indent = ligne[: len(ligne) - len(ligne.lstrip())]
    lignes[idx[0]] = indent + remplacement
    muté = "\n".join(lignes)
    if muté == original:
        return None, "NON OPPOSABLE (identique)"
    dossier = os.path.join(WORK, unique("mut-" + ident.lower()))
    os.makedirs(dossier)
    chemin = os.path.join(dossier, os.path.basename(source))
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(muté)
    os.chmod(chemin, 0o755)
    for c in compagnons:
        with open(os.path.join(dossier, os.path.basename(c)), "w", encoding="utf-8") as fh:
            fh.write(open(c, encoding="utf-8").read())
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    corps = extraire(chemin, marqueur, os.path.join(dossier, "corps.py"))
    try:
        compile(open(corps, encoding="utf-8").read(), chemin, "exec")
    except SyntaxError as e:
        return None, "SyntaxError du corps Python : " + str(e)
    return chemin, None


def sec_mutants(_):
    G = "PY_REJEU_GATES_EOF"
    R = "PY_REJEU_REEL_EOF"

    def mutant(ident, source, marqueur, motif, remplacement, compagnons=()):
        chemin, raison = make_mutant(source, marqueur, ident, motif, remplacement, compagnons)
        if chemin is None:
            komut(ident, "mutant valide (motif unique)", "mutant construit", raison)
        return chemin

    # --- scénarios (chacun rend un résumé comparable) ---
    def sc_ecrit(script):
        a = fabriquer_lab(unique("lab-me"), {".planning/notes.md": "n"})
        av = empreinte_arbre(a)
        r = rejeu([a], hook=substitut(unique("sub") + ".sh", SUB_PASSE), script=script)
        cfg = open(os.path.join(a, ".planning", "config.json"), encoding="utf-8").read()
        return {"rc": r.rc, "arbre": empreinte_arbre(a) == av, "config": cfg == '{"planning_version": "2.0"}'}

    def sc_empreinte(script):
        lab = fabriquer_lab(unique("lab-mi"), {".planning/notes.md": "n"})
        sub = substitut(unique("sub") + ".sh", 'open(%r, "w").write("intrus")' % os.path.join(lab, ".planning", "intrus.md"))
        r = rejeu([lab], hook=sub, script=script)
        return {"rc": r.rc, "divergent": any("DIVERGENTE" in l for l in r.empreintes)}

    def sc_compte(script):
        a = fabriquer_lab(unique("lab-mc"), {".planning/interdit/x.md": "x"})
        sub = substitut(unique("sub") + ".sh", 'if ARMEMENT_G6 == "armed" and "/interdit/" in chemin: refuser("G6", "interdit")')
        r = rejeu([a], hook=sub, script=script)
        return {"G6": r.compte.get("G6"), "etape": r.etape}

    def sc_affichage(script):
        a = fabriquer_lab(unique("lab-ma"), {".planning/notes.md": "n"})
        r = rejeu([a], hook=substitut(unique("sub") + ".sh", SUB_PASSE), script=script)
        return {"absolu": HOME in r.out or os.path.realpath(HOME) in r.out, "tilde": any(l[1].startswith("~/") for l in r.lignes)}

    def sc_priorite(script):
        lab = fabriquer_lab(unique("lab-mp"), {".planning/STATE.md": "s"})
        sub = substitut(unique("sub") + ".sh", 'if ARMEMENT_G6 == "armed" and chemin.endswith("/.planning/STATE.md"): refuser("G6", "STATE")')
        r = rejeu([lab], hook=sub, scenario="g6-state", script=script)
        return {"G6": r.compte.get("G6")}

    def sc_doublon(script):
        fichiers = {rel: "p" for rel in PROTEGES}
        lab = fabriquer_lab(unique("lab-md"), fichiers)
        sub = substitut(unique("sub") + ".sh", 'refuser("G6", "tout")')
        r = rejeu([lab], hook=sub, scenario="g6-protege", script=script)
        cles = [(l[1], l[2]) for l in r.lignes]
        return {"lignes": len(cles), "distinctes": len(set(cles))}

    def sc_modele_a(script):
        lab = lab_trois_phases(unique("lab-mm"))
        r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_G1), scenario="g1-modele", script=script)
        return {"G1": r.compte.get("G1")}

    def sc_modele_b(script):
        lab = lab_trois_phases(unique("lab-mn"))
        sub = substitut(unique("sub") + ".sh", SUB_G1 + '\nif "/02-b/" in chemin and chemin.endswith("/PLAN.md"):\n    refuser("G1", "B")')
        r = rejeu([lab], hook=sub, scenario="g1-modele", script=script)
        return {"G1": r.compte.get("G1")}

    def sc_total(script):
        lab = lab_trois_phases(unique("lab-mt"))
        r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_G1), scenario="g1-total-vide", script=script)
        return {"rc": r.rc, "erreur": "classification absente" in r.err}

    def sc_reel_cmp(dossier_reel):
        lab = fabriquer_lab(unique("lab-mr"), {".planning/notes.md": "n", "src/a.txt": "a"})
        sub = substitut(unique("sub") + ".sh", 'open(%r, "w").write("nouveau")' % os.path.join(lab, "src", "nouveau.txt"))
        r = rejeu([lab], hook=sub, reel=True, script=dossier_reel)
        return {"rc": r.rc, "divergent": "EMPREINTE-ARBRE-DIVERGENTE" in r.rapport}

    def sc_reel_liens(dossier_reel):
        dehors = os.path.join(HOME, unique("dehors-ml"))
        ecrire(os.path.join(dehors, "cible.txt"), "contenu")
        lab = fabriquer_lab(unique("lab-ml"), {".planning/notes.md": "n"})
        os.symlink(os.path.join(dehors, "cible.txt"), os.path.join(lab, "lien-fichier"))
        sub = substitut(unique("sub") + ".sh", 'open(%r, "w").write("modifie")' % os.path.join(dehors, "cible.txt"))
        r = rejeu([lab], hook=sub, reel=True, script=dossier_reel)
        return {"rc": r.rc, "divergent": "EMPREINTE-ARBRE-DIVERGENTE" in r.rapport}

    def duel(ident, source, marqueur, motif, remplacement, scenario, verdict, texte, compagnons=()):
        chemin = mutant(ident, source, marqueur, motif, remplacement, compagnons)
        if chemin is None:
            return
        o = scenario(source)
        m = scenario(chemin)
        if o != m and verdict(o, m):
            okmut(ident, "%s · attendu (original) : %s · obtenu (mutant) : %s" % (texte, court(o), court(m)))
        else:
            komut(ident, texte, court(o), court(m) + " (mutant non opposable)")

    duel("REJEU-ECRIT", REJEU, G, "# rejeu-adhesion-copie", 'cible = os.path.join(lab.reel, rel, "config.json")  # rejeu-adhesion-copie',
         sc_ecrit, lambda o, m: o["rc"] == 0 and o["arbre"] and o["config"] and not (m["arbre"] and m["config"] and m["rc"] == 0),
         "R-REJEU-02 : l'adhésion simulée écrite dans le lab réel")
    duel("REJEU-EMPREINTE", REJEU, G, "# rejeu-empreinte", "identique = True  # rejeu-empreinte",
         sc_empreinte, lambda o, m: o["rc"] == 1 and o["divergent"] and not m["divergent"],
         "R-REJEU-07 : comparaison d'empreinte toujours égale")
    duel("REJEU-COMPTE", REJEU, G, "# rejeu-compte", 'comptes[gate][classe] += 0 if classe == "faux-refus" else 1  # rejeu-compte',
         sc_compte, lambda o, m: o["G6"] == (1, 0, 0) and m["G6"] != o["G6"],
         "R-REJEU-01 : faux refus non comptés")
    duel("REJEU-AFFICHAGE", REJEU, G, "# rejeu-affichage", "return p  # rejeu-affichage",
         sc_affichage, lambda o, m: not o["absolu"] and o["tilde"] and m["absolu"],
         "R-REJEU-04 : chemin affiché sans repli ~/")
    duel("REJEU-PRIORITE", REJEU, G, "# rejeu-priorite", 'rang = min(e["rang"] for e in liste)  # rejeu-priorite',
         sc_priorite, lambda o, m: o["G6"] == (0, 0, 0) and m["G6"] != (0, 0, 0),
         "R-REJEU-08 : le générique l'emporte sur le constructeur du gate")
    duel("REJEU-DOUBLON", REJEU, G, "# rejeu-doublon", "gagnants.extend(liste)  # rejeu-doublon",
         sc_doublon, lambda o, m: o["lignes"] == o["distinctes"] and m["lignes"] > m["distinctes"],
         "R-REJEU-09 : élimination des doublons retirée")
    duel("REJEU-MODELE-COMPTE", REJEU, G, "# rejeu-modele-compte", 'return "faux-refus" if obtenu == "refus" else "faux-accept"  # rejeu-modele-compte',
         sc_modele_a, lambda o, m: o["G1"] == (0, 0, 2) and m["G1"] == (2, 0, 0),
         "R-REJEU-10 : les refus conformes au modèle comptés en faux refus")
    duel("REJEU-MODELE-INVERSE", REJEU, G, "# rejeu-modele-inverse", 'return "refus-conforme-modele" if obtenu == "refus" else "conforme"  # rejeu-modele-inverse',
         sc_modele_b, lambda o, m: o["G1"] == (1, 0, 2) and m["G1"] == (0, 0, 3),
         "R-REJEU-10 : tout refus rangé en conforme au modèle, même sur un doit-passer")
    duel("REJEU-TOTAL", REJEU, G, "# rejeu-total", 'attendu = "doit-passer"  # rejeu-total',
         sc_total, lambda o, m: o["rc"] == 1 and o["erreur"] and m["rc"] == 0,
         "R-REJEU-10 : une écriture sans attendu retombe sur doit-passer")
    duel("REEL-CMP", REEL, R, "# reel-cmp", "identique = True  # reel-cmp",
         sc_reel_cmp, lambda o, m: o["rc"] == 1 and o["divergent"] and not m["divergent"],
         "R-REEL-02 : comparaison d'empreinte de rejeu-reel.sh toujours égale", compagnons=(REJEU,))
    duel("REEL-PERIMETRE", REEL, R, "# reel-perimetre", 'SOUS_ARBRES = [".planning", ".claude"]  # reel-perimetre',
         sc_reel_cmp, lambda o, m: o["divergent"] and not m["divergent"],
         "R-REEL-02 : empreinte limitée à .planning/ et .claude/", compagnons=(REJEU,))
    duel("REEL-LIENS", REEL, R, "# reel-lstat", "st = os.stat(chemin)  # reel-lstat",
         sc_reel_liens, lambda o, m: (not o["divergent"]) and m["divergent"],
         "R-REEL-03 : liens suivis", compagnons=(REJEU,))


SECTIONS = {
    "sens": sec_sens,
    "reel_hook": sec_reel_hook,
    "priorite": sec_priorite,
    "modele": sec_modele,
    "statique": sec_statique,
    "reel": sec_reel,
    "mutants": sec_mutants,
}


def main():
    preparer_essais()
    for nom in sys.argv[1].split(","):
        SECTIONS[nom](None)


main()
PY_AIDES_REJEU_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-$1.txt"
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$REJEU" "$REEL" "$HOOK" "$RECALC" "$WORK" "$PYBIN" > "$out" 2>&1
  rc=$?
  while IFS= read -r line; do
    printf '%s\n' "$line"
    case "$line" in
      "  ✓ "*) pass=$((pass+1)) ;;
      "  ✗ "*) fail=$((fail+1)) ;;
    esac
  done < "$out"
  if [ "$rc" -ne 0 ]; then
    if ! grep -q '^  ✗ ' "$out"; then
      ko "sections $1" "les aides Python se terminent sans erreur" "code 0" "code $rc (voir la sortie ci-dessus)"
    fi
  fi
}

for f in "$REJEU" "$REEL"; do
  if [ ! -f "$f" ]; then
    ko "outil présent" "le script de rejeu existe à côté de la suite" "$f" "absent"
  fi
done

if [ -f "$REJEU" ] && [ -f "$REEL" ]; then
  run_sections sens,reel_hook,priorite,modele,statique,reel,mutants
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
