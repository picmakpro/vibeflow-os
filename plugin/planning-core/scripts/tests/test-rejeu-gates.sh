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
#   R-REJEU-ETAPE  règle de comptage par étape (45-06, décisions du manager vf-dev-manager, 2026-09-30) :
#                 REJEU-ETAPE-n et l'armement ne comptent que les gates des étapes <= n ; un gate d'étape > n est
#                 joué, sa ligne COMPTE porte `hors-etape` ; les gates `-` et `?` restent comptés
#   R-REJEU-G6G5  constructeurs G6 et G5 (45-05) : le vrai hook armé à l'étape 1 sur deux labs synthétiques, une
#                 ligne par clé, le constructeur G6 prime sur la réécriture générique, faux-refus=0 faux-accept=0
#   R-REJEU-G1    constructeur G1 (45-06) : attendu du modèle, refus conformes comptés à part, classification
#                 totale (règle écrite, CLASSE-REGLE-ECRITE), code propre de l'outil (aucun appel au hook)
#   R-REJEU-G1-CONCORDANCE  test différentiel sur 64 cellules générées (itertools.product) : attendu du relevé
#                 <=> deny du vrai hook <=> oracle de huit lignes ; somme des n = 26
#   R-REJEU-G7    constructeur G7 (45-07) et option --attendus sur des fixtures SYNTHÉTIQUES : le vrai hook armé à l'étape 3, un
#                 lab à deux .planning/ imbriqués (habité, nu), le nu marqué doit-refuser-modele par le fichier d'attendus (refus
#                 conforme au modèle, compté à part), les créations synthétiques doit-refuser ; le dossier imbriqué est mis de côté
#                 puis remis en place sur la copie (trace d'un substitut, erreur de l'outil si la copie diffère) ; à --etape=2 la
#                 ligne COMPTE G7 est suffixée `hors-etape` et ne compte pas
#   R-REJEU-ROLE  constructeur ROLE (45-09) : le vrai hook armé à l'étape 4 sur un lab synthétique qui porte un juge, un manager à
#                 allowlist, un worker à allowlist et un producteur ; la légitimité se mesure sur les déclarations des agents (écriture
#                 d'un agent qui retire Write et Edit : doit-refuser ; dispatch d'un nom de sa propre allowlist : doit-passer, F9 =
#                 f9-allowlist, Willy, AskUserQuestion session principale, 2026-09-30 ; dispatch hors liste d'un worker sous Agent ET
#                 Task : doit-refuser) ; un substitut qui applique la lettre compte un faux refus ; à --etape=3 les lignes ROLE sont hors-etape
#   R-REJEU-10   Q-G6 = (b) (Willy, AskUserQuestion session principale, 2026-10-01) : les scripts du hook présents sous `.claude/scripts/` de la
#                racine d'un lab adhérent entrent dans le relevé de G6 (doit-refuser), settings.json n'y entre pas ; un hook qui ne les
#                garde pas compte un faux accept par script ; MUT-REJEU-SCRIPTS-G6. Q-ARM (2026-09-30) : le hook « frère » des cas est
#                une copie à observe (HOOK), les cas ne dépendent pas de l'état d'armement courant
#   R-REJEU-STATIQUE  aucun sous-processus autre que bash (hook copié, `--classer`, recalc-planning.sh) et cmp
#   R-REJEU-LIENS / R-REEL-LIENS  (quick 45-B, H3 ; décisions du manager vf-dev-manager, 2026-10-01) : un lien du lab dont la cible
#                 résolue sort du lab, sur un chemin que le rejeu écrit ou lit (cycles/, phases/, STATE.md, .claude/agents), est une
#                 erreur (code 1) AVANT toute écriture sur la copie ; dossier extérieur intact ; payload sans suivi de lien ; rejeu-reel.sh
#                 refuse avant de rien jouer ; témoins positifs (lien interne au lab, lien sortant hors des chemins du rejeu)
#   R-REJEU-RELEVE / R-REEL-CASSE / R-REJEU-PROFOND  (quick 45-B, B2 et B3) : aucun chemin absolu ni ligne forgée par un nom dans le
#                 relevé, garde « rapport sous un lab » par identité de fichier, arbre profond sans trace Python
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
import itertools
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


def hook_observe(source):
    """Copie du hook dont les huit constantes ARMEMENT_* valent `observe` (Q-ARM, Willy, AskUserQuestion session principale,
    2026-09-30) : les cas du rejeu ne dépendent pas de l'état d'armement courant du hook livré. L'outil arme lui-même, sur sa
    propre copie, les gates des étapes <= --etape ; ceux des étapes suivantes restent à observe (« simulés en observe »)."""
    texte, n = re.subn(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE|G3|G4|G4P) = )"(?:observe|armed)"', r'\1"observe"', open(source, encoding="utf-8").read(), flags=re.M)
    if n != 8:
        raise RuntimeError("huit constantes ARMEMENT_* attendues, %d trouvée(s)" % n)
    chemin = os.path.join(WORK, "hook-observe", "planning-hook.sh")
    ecrire(chemin, texte, 0o755)
    return chemin


HOOK = hook_observe(HOOK)  # le hook « frère » des cas du rejeu : le script livré, tous gates à observe


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
ARMEMENT_G3 = "observe"  # etape-5
ARMEMENT_G4 = "observe"  # etape-5
ARMEMENT_G4P = "observe"  # etape-6
p = json.load(open(sys.argv[1], encoding="utf-8"))
outil = p.get("tool_name")
ti = p.get("tool_input") or {}
chemin = ti.get("file_path") or ti.get("notebook_path") or ""
ARMES = [g for g in ("G6", "G5", "G1", "G7", "ROLE", "G3", "G4", "G4P") if globals()["ARMEMENT_" + g] == "armed"]


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

def g1_sans_cadrage(lab, ctx):
    """Constructeur d'essai de G1 (45-06) : doit-refuser l'écriture du PLAN.md de chaque phase (sans CADRAGE.md)."""
    return [("Write", rel, "doit-refuser", "") for rel in plans(lab)]


SCENARIOS = {
    "aucun": (None, None),
    "g1-sans-cadrage": ("G1", g1_sans_cadrage),
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
# Isolement (45-05) : les constructeurs livrés de G6 et G5 ne jouent pas dans un essai qui mesure autre chose.
for g in [g for g in mod.CONSTRUCTEURS if g != "reecriture"]:
    del mod.CONSTRUCTEURS[g]
if fonction is not None:
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
        self.hors_etape = set()  # gates dont la ligne COMPTE porte le suffixe `hors-etape` (jamais comptés au total)
        for l in out.split("\n"):
            if l.startswith("COMPTE "):
                m = re.match(r"COMPTE (\S+) faux-refus=(\d+) faux-accept=(\d+) refus-conforme-modele=(\d+)(?: hors-etape)?$", l)
                if m:
                    self.compte[m.group(1)] = tuple(int(m.group(i)) for i in (2, 3, 4))
                    if l.endswith(" hors-etape"):
                        self.hors_etape.add(m.group(1))
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
    if scenario is None and hook and hook != HOOK and not reel:
        scenario = "aucun"  # substitut de hook : les constructeurs livrés de G6 et G5 ne jouent pas
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


def scenario_scripts_g6(script=None, hook=None, scenario=None):
    """Rejeu --etape=1 d'un lab dont la racine porte `.planning/` et, sous `.claude/`, les deux scripts du hook et un settings.json."""
    lab = fabriquer_lab(unique("lab-g6s"), {".planning/notes.md": "n", ".claude/scripts/planning-hook.sh": "#!/bin/bash\n",
                                            ".claude/scripts/check-gates-alive.sh": "#!/bin/bash\n", ".claude/settings.json": "{}\n"})
    return rejeu([lab], hook=hook or HOOK, etape=1, script=script, scenario=scenario)


def sec_reel_hook(_):
    """R-REJEU-06 et R-REJEU-07."""
    neutre = fabriquer_lab("lab-neutre", {".planning/notes.md": "n", "livrables/rapport.md": "r"})
    r = rejeu([neutre], hook=HOOK, etape=1)
    if r.rc == 0 and r.compte.get("G6") == (0, 0, 0) and r.compte.get("G5") == (0, 0, 0) and r.etape == (0, 0, 0) \
            and r.compte.get("G1") == (0, 2, 0) and "G1" in r.hors_etape:
        ok("R-REJEU-06 planning-hook.sh frère (copie à observe : Q-ARM), --etape=1, lab neutre (config, notes.md, livrables/) : faux-refus=0 faux-accept=0 pour G6 et G5 ; les deux phases synthétiques du constructeur G1 (joué, G1 en observe) passent : COMPTE G1 … faux-accept=2 hors-etape, hors du total REJEU-ETAPE-1 (0, 0, 0)")
    else:
        ko("R-REJEU-06", "hook réel sur un lab neutre", "REJEU-ETAPE-1 (0, 0, 0), COMPTE G1 (0, 2, 0) hors-etape, code 0", "rc=%d etape=%s compte=%s hors=%s err=%s" % (r.rc, r.etape, r.compte, sorted(r.hors_etape), court(r.err)))

    # R-REJEU-10 (Q-G6 = b, Willy, AskUserQuestion session principale, 2026-10-01) : les scripts du hook posés sous `.claude/scripts/` de la
    # racine d'un lab adhérent entrent dans le relevé de G6 (doit-refuser) quand le lab copié les porte ; `.claude/settings.json` n'y entre pas
    # (limite (y)) ; un hook qui ne les garde pas compte un faux accept par script.
    attendu_s = [(".claude/scripts/check-gates-alive.sh", "doit-refuser", "refus"), (".claude/scripts/planning-hook.sh", "doit-refuser", "refus")]
    r10 = scenario_scripts_g6()
    ls10 = sorted((l[2], l[3], l[4]) for l in r10.lignes if l[2].startswith(".claude/"))
    sans_scripts = os.path.join(WORK, "hook-sans-scripts", "planning-hook.sh")
    texte_sans, n_sans = re.subn(r'^SCRIPTS_HOOK_G6 = \(.*\)  # g6-scripts$', "SCRIPTS_HOOK_G6 = ()  # g6-scripts",
                                 open(HOOK, encoding="utf-8").read(), count=1, flags=re.M)
    ecrire(sans_scripts, texte_sans, 0o755)
    r10m = scenario_scripts_g6(hook=sans_scripts, scenario="")
    sans = [l[2] for l in r10m.lignes if l[2].startswith(".claude/")]
    if r10.rc == 0 and ls10 == attendu_s and r10.compte.get("G6") == (0, 0, 0) and r10.etape == (0, 0, 0) and n_sans == 1 \
            and r10m.compte.get("G6") == (0, 2, 0) and len(sans) == 2:
        ok("R-REJEU-10 lab adhérent dont .claude/scripts/ porte les deux scripts du hook (et un settings.json) : deux lignes G6 doit-refuser/refus (hook frère, --etape=1), COMPTE G6 (0, 0, 0), settings.json absent du relevé (limite (y)) ; un hook dont SCRIPTS_HOOK_G6 est vide : COMPTE G6 faux-accept=2 sur ces deux scripts")
    else:
        ko("R-REJEU-10", "les scripts du hook entrent dans le relevé de G6 et un hook qui ne les garde pas est compté en faux accept",
           "2 lignes doit-refuser/refus, COMPTE G6 (0, 0, 0) ; hook sans scripts : (0, 2, 0)",
           "rc=%d lignes=%s compte=%s ; sans scripts : compte=%s lignes=%s err=%s" % (r10.rc, ls10, r10.compte.get("G6"), r10m.compte.get("G6"), sans, court(r10.err)))

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
    r1 = rejeu([lab], hook=sub, scenario="g1-modele", etape=1)
    if r1.compte.get("G1") != (0, 0, 2) or "G1" not in r1.hors_etape or r1.etape != (0, 0, 0) or len(r1.lignes_chemin("PLAN.md")) != 3:
        fautes.append("(a) à --etape=1 les trois lignes G1 restent au relevé, COMPTE G1 (0, 0, 2) hors-etape, REJEU-ETAPE-1 (0, 0, 0) : G1=%s hors=%s etape=%s" % (r1.compte.get("G1"), sorted(r1.hors_etape), r1.etape))
    r = rejeu([lab], hook=sub, scenario="g1-modele", etape=2)  # les totaux se lisent à l'étape où G1 est compté
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


SUB_G1_ARME = '''if ARMEMENT_G1 == "armed" and chemin.endswith("/PLAN.md") and not os.path.isfile(os.path.join(os.path.dirname(chemin), "CADRAGE.md")):
    refuser("G1", "phase sans CADRAGE.md")'''
SUB_REFUS_SANS_GATE = 'print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "refus sans nom de gate"}}))\nsys.exit(0)'


def lab_etape(nom):
    return fabriquer_lab(nom, {".planning/notes.md": "n", ".planning/cycles/01-c/phases/01-sans/PLAN.md": "---\necrit: livrables/a.md\n---\n"})


def etape_g1(script):
    """G1 d'essai (constructeur injecté) rejoué sous un hook où G1 est en observe, à --etape=1 puis 2, puis armé sur la copie."""
    res = {}
    lab = lab_etape(unique("lab-et"))
    sub_obs = substitut(unique("sub") + ".sh", SUB_G1_ARME)
    sub_passe = substitut(unique("sub") + ".sh", SUB_PASSE)
    r = rejeu([lab], hook=sub_obs, etape=1, scenario="g1-sans-cadrage", script=script)
    res["g1-etape1"] = (r.compte.get("G1"), "G1" in r.hors_etape, r.etape, len(r.lignes_chemin("01-sans/PLAN.md")))
    r = rejeu([lab], hook=sub_passe, etape=2, scenario="g1-sans-cadrage", script=script)
    res["g1-etape2"] = (r.compte.get("G1"), "G1" in r.hors_etape, r.etape)
    r = rejeu([lab], hook=sub_obs, etape=2, scenario="g1-sans-cadrage", script=script)
    res["g1-arme"] = (r.compte.get("G1"), "G1" in r.hors_etape, r.etape)
    return res


def etape_g6(script):
    """Un substitut qui refuse à tort une écriture d'un gate de l'étape mesurée (G6 à --etape=1) : toujours un faux refus compté."""
    lab = fabriquer_lab(unique("lab-et"), {".planning/notes.md": "n"})
    sub = substitut(unique("sub") + ".sh", 'if ARMEMENT_G6 == "armed" and chemin.endswith("/.planning/notes.md"): refuser("G6", "notes.md refusé à tort")')
    r = rejeu([lab], hook=sub, etape=1, script=script)
    return {"g6-faux-refus": (r.compte.get("G6"), "G6" in r.hors_etape, r.etape)}


def etape_sans_etape(script):
    """Les lignes rangées sous aucune étape restent comptées : un faux accept sous le gate `-`, un faux refus sous le gate `?`."""
    res = {}
    lab = fabriquer_lab(unique("lab-et"), {".planning/notes.md": "n"})
    att = ecrire_attendus(["- | ~/%s | .planning/notes.md | doit-refuser | un passage rangé sous aucun gate" % os.path.basename(lab)])
    r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), etape=1, attendus=att, script=script)
    res["gate-tiret"] = (r.compte.get("-"), r.etape)
    lab3 = fabriquer_lab(unique("lab-et"), {".planning/notes.md": "n"})
    r = rejeu([lab3], hook=substitut(unique("sub") + ".sh", SUB_REFUS_SANS_GATE), etape=1, script=script)
    res["gate-interrogation"] = (r.compte.get("?"), "?" in r.hors_etape, r.etape)
    return res


def scenarios_etape(script):
    res = {}
    for mesure in (etape_g1, etape_g6, etape_sans_etape):
        res.update(mesure(script))
    return res


ATTENDU_ETAPE = {"g1-etape1": ((0, 1, 0), True, (0, 0, 0), 1), "g1-etape2": ((0, 1, 0), False, (0, 1, 0)),
                 "g1-arme": ((0, 0, 0), False, (0, 0, 0)), "g6-faux-refus": ((1, 0, 0), False, (1, 0, 0)),
                 "gate-tiret": (None, (0, 1, 0)), "gate-interrogation": ((2, 0, 0), False, (2, 0, 0))}


def sec_etape(_):
    """R-REJEU-ETAPE : REJEU-ETAPE-<n> et l'armement ne comptent que les gates des étapes <= n ; les gates `-` et `?` restent comptés."""
    res = scenarios_etape(REJEU)
    fautes = ["%s : attendu %s, obtenu %s" % (cle, ATTENDU_ETAPE[cle], res.get(cle)) for cle in ATTENDU_ETAPE if res.get(cle) != ATTENDU_ETAPE[cle]]
    if fautes:
        for f in fautes:
            ko("R-REJEU-ETAPE", "REJEU-ETAPE-n exclut les gates d'étape > n, garde les gates `-` et `?`", "voir le cas", f)
    else:
        ok("R-REJEU-ETAPE --etape=1 : le doit-refuser d'un constructeur G1 qu'un hook en observe laisse passer imprime `COMPTE G1 … faux-accept=1 … hors-etape` (la ligne du relevé reste) et REJEU-ETAPE-1 vaut 0/0/0 ; --etape=2 : G1 n'est plus hors-etape et son faux accept entre dans REJEU-ETAPE-2 ; G1 armé sur la copie : 0/0/0 ; un faux refus de G6 à --etape=1 est compté ; un faux accept rangé sous le gate `-` et un faux refus sous le gate `?` restent comptés dans REJEU-ETAPE-1")


FICHIERS_G6G5 = {".planning/STATE.md": "s", ".planning/INDEX.md": "i", ".planning/cloture.log": "c",
                 ".planning/cycles/01-c/CYCLE.md": "---\ntitre: t\nrend: r\n---\n",
                 ".planning/cycles/01-c/phases/01-p/CADRAGE.md": "---\ninconnues: []\n---\n",
                 ".planning/cycles/01-c/phases/01-p/PLAN.md": "---\necrit: livrables/a.md\n---\n"}
ATTENDUS_G6G5 = (  # (chemin affiché, attendu, obtenu) d'un lab de FICHIERS_G6G5 ; les clés d'un lab sont DISTINCTES
    (".planning/STATE.md", "doit-refuser", "refus"), (".planning/INDEX.md", "doit-refuser", "refus"),
    (".planning/cloture.log", "doit-refuser", "refus"), (".planning/derogations-gates.log", "doit-refuser", "refus"),
    (".planning/.recalc-cache.json", "doit-refuser", "refus"),
    (".planning/config.json", "doit-passer", "passe"), (".planning/config.json [Edit]", "doit-refuser", "refus"),
    (".planning/cycles/01-c/phases/01-p/PLAN.md", "doit-passer", "passe"),
    (".planning/cycles/01-c/phases/01-p/VERDICT.md", "doit-refuser", "refus"),
    # 45-06 : la phase est cadrée selon le modèle (CYCLE.md, CADRAGE.md clos) ; le constructeur G1 est joué à --etape=1, G1 simulé
    # en observe : ses deux phases synthétiques (doit-refuser) obtiennent un passage, compté hors-etape
    (".planning/cycles/01-c/CYCLE.md", "doit-passer", "passe"), (".planning/cycles/01-c/phases/01-p/CADRAGE.md", "doit-passer", "passe"),
    (".planning/cycles/01-c/phases/99-rejeu-sans-cadrage/PLAN.md", "doit-refuser", "passe"),
    (".planning/cycles/01-c/phases/99-rejeu-registre-ouvert/PLAN.md", "doit-refuser", "passe"),
    # 45-07 : le constructeur G7 est joué aussi, une création synthétique par racine adhérente (doit-refuser), G7 simulé en observe
    ("rejeu-orphelin-g7/.planning/config.json [création]", "doit-refuser", "passe"))


def scenario_g6g5(script):
    """Relevé du rejeu de l'étape 1 avec le VRAI hook (copie armée) sur deux labs synthétiques."""
    a = fabriquer_lab(unique("lab-g6a"), FICHIERS_G6G5, config='{"planning_version": "2.0", "autre": 1}')
    b = fabriquer_lab(unique("lab-g6b"), FICHIERS_G6G5)
    r = rejeu([a, b], hook=HOOK, etape=1, script=script)
    lignes = {}
    for g, lab, chemin, attendu, obtenu, _raison in r.lignes:
        lignes.setdefault(lab, []).append((chemin, attendu, obtenu))
    return r, sorted(lignes.items())


def sec_g6g5(_):
    """R-REJEU-G6G5 : les constructeurs G6 et G5 livrés, le vrai hook armé à l'étape 1, deux labs synthétiques."""
    r, par_lab = scenario_g6g5(REJEU)
    fautes = []
    if r.rc != 0:
        fautes.append("code %d : %s" % (r.rc, court(r.err)))
    if len(par_lab) != 2:
        fautes.append("%d lab(s) au relevé (attendu 2)" % len(par_lab))
    for lab, lignes in par_lab:
        if sorted(lignes) != sorted(ATTENDUS_G6G5):
            fautes.append("%s : lignes %s (attendu une par clé, %d)" % (lab, sorted(lignes), len(ATTENDUS_G6G5)))
        cles = [l[0] for l in lignes]
        if len(cles) != len(set(cles)):
            fautes.append("%s : clé en double %s" % (lab, sorted(c for c in set(cles) if cles.count(c) > 1)))
    if r.compte.get("G6") != (0, 0, 0) or r.compte.get("G5") != (0, 0, 0) or r.etape != (0, 0, 0):
        fautes.append("comptes G6=%s G5=%s etape=%s (attendu 0, 0, 0)" % (r.compte.get("G6"), r.compte.get("G5"), r.etape))
    if r.compte.get("G1") != (0, 4, 0) or "G1" not in r.hors_etape:
        fautes.append("COMPTE G1 %s hors=%s (attendu (0, 4, 0) hors-etape : deux phases synthétiques par lab, G1 simulé en observe)" % (r.compte.get("G1"), sorted(r.hors_etape)))
    if r.compte.get("G7") != (0, 2, 0) or "G7" not in r.hors_etape:
        fautes.append("COMPTE G7 %s hors=%s (attendu (0, 2, 0) hors-etape : une création synthétique par lab, G7 simulé en observe)" % (r.compte.get("G7"), sorted(r.hors_etape)))
    if fautes:
        for f in fautes:
            ko("R-REJEU-G6G5", "constructeurs G6 et G5 + vrai hook armé à l'étape 1, deux labs synthétiques", "une ligne par clé distincte, faux-refus=0 faux-accept=0", f)
    else:
        ok("R-REJEU-G6G5 vrai hook, --etape=1, deux labs synthétiques : chaque fichier protégé (STATE.md, INDEX.md, cloture.log, journal de dérogation, cache) UNE fois en doit-refuser/refus (le constructeur G6 prime sur la réécriture générique), config.json et PLAN.md UNE fois en doit-passer/passe, l'Edit qui perd l'adhésion et le VERDICT.md voisin en doit-refuser/refus ; le constructeur G1 est joué (CYCLE.md et CADRAGE.md en doit-passer, deux phases synthétiques en doit-refuser/passe, COMPTE G1 hors-etape) ; le constructeur G7 est joué (une création synthétique par lab en doit-refuser/passe, COMPTE G7 hors-etape) ; 14 lignes par lab = 14 clés distinctes ; faux-refus=0 faux-accept=0 pour G6 et G5, REJEU-ETAPE-1 à 0")


# --- 45-06 : G1, constructeur du rejeu (R-REJEU-G1) et concordance règle écrite / prédicat (R-REJEU-G1-CONCORDANCE) ------
CLOS_G1 = '---\ninconnues:\n  - id: I-01\n    question: "Q ?"\n    structurante: oui\n    statut: ARBITRÉ\n    par: willy\n    le: "2026-09-30"\n    ou: "session"\n---\n'
OUVERT_G1 = '---\ninconnues:\n  - id: I-01\n    question: "Q ?"\n    structurante: oui\n---\n'
HERITE_G1 = "---\ntitre: ancien cadrage sans registre\n---\n"
CYCLE_G1 = "---\ntitre: t\nrend: r\n---\n"
PLAN_G1 = "---\necrit: livrables/a.md\n---\n"
PH = ".planning/cycles/01-c/phases/"

# Substitut de hook qui joue G1 (armé sur la copie) : pas de CADRAGE.md, ou registre ouvert ; la phase d'un plan sous plans/ est la phase.
SUB_G1_PRED = "\n".join([
    'if ARMEMENT_G1 == "armed" and chemin.endswith("/PLAN.md"):',
    '    d = os.path.dirname(chemin)',
    '    if os.path.basename(os.path.dirname(d)) == "plans":',
    '        d = os.path.dirname(os.path.dirname(d))',
    '    cad = os.path.join(d, "CADRAGE.md")',
    '    if not os.path.lexists(cad):',
    '        refuser("G1", "phase sans CADRAGE.md")',
    '    if os.path.isfile(cad) and "structurante: oui" in open(cad, encoding="utf-8").read() and "statut" not in open(cad, encoding="utf-8").read():',
    '        refuser("G1", "registre ouvert")',
    ''])


def sub_g1(nom, refuse_aussi=()):
    corps = SUB_G1_PRED
    for morceau in refuse_aussi:
        corps += 'if ARMEMENT_G1 == "armed" and chemin.endswith("/PLAN.md") and %r in chemin:\n    refuser("G1", "refuse aussi une phase cadrée")\n' % morceau
    return substitut(nom, corps)


def lab_g1_modele(nom):
    """Lab non migré à cycle avec CYCLE.md : sans CADRAGE.md, registre ouvert, clos, hérité, plan sous plans/ sans CADRAGE.md."""
    return fabriquer_lab(nom, {
        PH[:-7] + "CYCLE.md": CYCLE_G1,
        PH + "01-sans/PLAN.md": PLAN_G1,
        PH + "02-ouvert/CADRAGE.md": OUVERT_G1, PH + "02-ouvert/PLAN.md": PLAN_G1,
        PH + "03-clos/CADRAGE.md": CLOS_G1, PH + "03-clos/PLAN.md": PLAN_G1,
        PH + "04-herite/CADRAGE.md": HERITE_G1, PH + "04-herite/PLAN.md": PLAN_G1,
        PH + "05-plans/plans/01-a/PLAN.md": PLAN_G1})


def lab_g1_classe(nom):
    """Quatre phases classées par la règle écrite (l'état dérivé manque) : D (cycle sans CYCLE.md, sans CADRAGE.md), E (Φ1 par une
    AUTRE entrée non régulière, sans CADRAGE.md), F (même Φ1, CADRAGE.md clos), H (CADRAGE.md est un dossier)."""
    lab = fabriquer_lab(nom, {
        PH[:-7] + "CYCLE.md": CYCLE_G1,
        ".planning/cycles/02-x/phases/01-d/PLAN.md": PLAN_G1,
        PH + "05-e/PLAN.md": PLAN_G1,
        PH + "06-f/PLAN.md": PLAN_G1, PH + "06-f/CADRAGE.md": CLOS_G1,
        PH + "07-h/PLAN.md": PLAN_G1})
    for rel in (PH + "05-e/CLOTURE.md", PH + "06-f/CLOTURE.md", PH + "07-h/CADRAGE.md"):
        os.makedirs(os.path.join(lab, rel))
    return lab


def par_chemin(r, aff):
    return dict((l[2], l) for l in r.lignes if l[1] == aff)


def sec_g1(_):
    """R-REJEU-G1."""
    fautes = []
    # (a) vrai hook armé à l'étape 2, lab non migré : l'attendu du modèle, phase par phase
    lab = lab_g1_modele(unique("lab-g1m"))
    aff = "~/" + os.path.basename(lab)
    r = rejeu([lab], hook=HOOK, etape=2)
    lignes = par_chemin(r, aff)
    attendus = {PH + "01-sans/PLAN.md": ("doit-refuser-modele", "refus"), PH + "02-ouvert/PLAN.md": ("doit-refuser-modele", "refus"),
                PH + "03-clos/PLAN.md": ("doit-passer", "passe"), PH + "04-herite/PLAN.md": ("doit-passer", "passe"),
                PH + "05-plans/plans/01-a/PLAN.md": ("doit-refuser-modele", "refus"),
                PH + "99-rejeu-sans-cadrage/PLAN.md": ("doit-refuser", "refus"), PH + "99-rejeu-registre-ouvert/PLAN.md": ("doit-refuser", "refus")}
    for chemin, (attendu, obtenu) in attendus.items():
        l = lignes.get(chemin)
        if l is None or (l[3], l[4]) != (attendu, obtenu):
            fautes.append("(a) %s : attendu %s/%s, obtenu %s" % (chemin, attendu, obtenu, None if l is None else (l[3], l[4])))
    if r.compte.get("G1") != (0, 0, 3) or r.etape != (0, 0, 3) or r.classe.get(("G1", aff)) != 0 or "G1" in r.hors_etape:
        fautes.append("(a) G1=%s etape=%s classe=%s (attendu (0, 0, 3) : trois refus conformes au modèle, phase par phase ; n=0)" % (r.compte.get("G1"), r.etape, r.classe))
    # (b) un substitut qui refuse AUSSI la phase à CADRAGE.md clos : faux refus, jamais un refus conforme
    r = rejeu([lab], hook=sub_g1(unique("sub") + ".sh", ("/03-clos/",)), etape=2, scenario="")
    if r.compte.get("G1") != (1, 0, 3):
        fautes.append("(b) substitut qui refuse aussi la phase à CADRAGE.md clos : attendu G1 (1, 0, 3), obtenu %s" % (r.compte.get("G1"),))
    # (c) classification totale (P45-D-21c) : D, E, F, H sont classées par la règle écrite
    lab_c = lab_g1_classe(unique("lab-g1c"))
    aff_c = "~/" + os.path.basename(lab_c)
    r = rejeu([lab_c], hook=HOOK, etape=2)
    lignes = par_chemin(r, aff_c)
    regle = " classé par la règle écrite, état dérivé absent : "
    cas = ((".planning/cycles/02-x/phases/01-d/PLAN.md", "doit-refuser-modele", "refus", "pas-de-cadrage"),
           (PH + "05-e/PLAN.md", "doit-refuser-modele", "refus", "pas-de-cadrage"),
           (PH + "06-f/PLAN.md", "doit-passer", "passe", "clos"), (PH + "07-h/PLAN.md", "doit-passer", "passe", "non-regulier"))
    for chemin, attendu, obtenu, branche in cas:
        l = lignes.get(chemin)
        if l is None or (l[3], l[4]) != (attendu, obtenu) or ("état dérivé absent : " + branche) not in l[5]:
            fautes.append("(c) %s : attendu %s/%s (%s), obtenu %s" % (chemin, attendu, obtenu, branche, None if l is None else l[3:]))
    if r.classe.get(("G1", aff_c)) != 4 or r.compte.get("G1") != (0, 0, 2):
        fautes.append("(c) CLASSE-REGLE-ECRITE G1 lab=%s n=4 attendu ; obtenu %s, COMPTE G1 %s (attendu (0, 0, 2))" % (aff_c, r.classe, r.compte.get("G1")))
    for morceau in ("/06-f/", "/07-h/"):
        r = rejeu([lab_c], hook=sub_g1(unique("sub") + ".sh", (morceau,)), etape=2, scenario="")
        if r.compte.get("G1") != (1, 0, 2):
            fautes.append("(c) substitut qui refuse aussi %s : attendu faux-refus=1 (1, 0, 2), obtenu %s" % (morceau, r.compte.get("G1")))
    # (d) contrôle statique : rejeu-gates.sh ne nomme pas evaluer_g1 ; le constructeur ne lance ni n'appelle le hook ; les copies du parseur sont ast-identiques
    corps = extraire(REJEU, "PY_REJEU_GATES_EOF", os.path.join(WORK, unique("statique-g1") + ".py"))
    source = open(corps, encoding="utf-8").read()
    m = re.search(r"^def construire_g1\(.*?(?=^def |^class |\Z)", source, re.S | re.M)
    if "evaluer_g1" in open(REJEU, encoding="utf-8").read():
        fautes.append("(d) rejeu-gates.sh contient evaluer_g1")
    if m is None or len(m.group(0).strip()) == 0:
        fautes.append("(d) extraction vide du corps du constructeur G1 (rouge, jamais un vert à vide)")
    elif "hook" in m.group(0).lower() or "jouer(" in m.group(0):
        fautes.append("(d) le constructeur G1 lance ou appelle le hook : " + court(m.group(0), 160))
    recalc = extraire(RECALC, "PY_RECALC_PLANNING_EOF", os.path.join(WORK, unique("statique-recalc") + ".py"))

    def arbres(chemin):
        res = {}
        for noeud in ast.parse(open(chemin, encoding="utf-8").read()).body:
            if isinstance(noeud, ast.FunctionDef) and noeud.name in ("dequote", "lire_frontmatter", "_lire_liste_indentee", "lire_registre"):
                res[noeud.name] = ast.dump(noeud)
            elif isinstance(noeud, ast.Assign) and any(isinstance(c, ast.Name) and c.id == "CLE_RE" for c in noeud.targets):
                res["CLE_RE"] = ast.dump(noeud)
        return res
    a_outil, a_moteur = arbres(corps), arbres(recalc)
    for nom in ("dequote", "CLE_RE", "lire_frontmatter", "_lire_liste_indentee", "lire_registre"):
        if nom not in a_outil or nom not in a_moteur or a_outil[nom] != a_moteur[nom]:
            fautes.append("(d) copie du parseur : %s absente ou différente de celle de recalc-planning.sh" % nom)
    if fautes:
        for f in fautes:
            ko("R-REJEU-G1", "constructeur G1 : attendu du modèle, classification totale, code propre de l'outil", "voir le cas", f)
    else:
        ok("R-REJEU-G1 vrai hook, --etape=2 : lab non migré (sans CADRAGE.md, registre ouvert, plan sous plans/ : refus conformes au modèle, 3, phase par phase ; clos et hérité : passage), phases synthétiques 99-rejeu-* en doit-refuser/refus, faux-refus=0 faux-accept=0 ; un substitut qui refuse aussi la phase à CADRAGE.md clos : faux-refus=1 ; classification totale : D, E, F, H classées par la règle écrite (CLASSE-REGLE-ECRITE n=4, faux-refus=0), F ou H refusées à tort : faux-refus=1 ; rejeu-gates.sh ne nomme pas evaluer_g1, le constructeur n'appelle pas le hook, copies du parseur ast-identiques")


# --- 45-07 : G7, constructeur du rejeu (R-REJEU-G7) et option --attendus sur des fixtures SYNTHÉTIQUES ----------------------------
# Lab synthétique non migré (config 2.0, l'adhésion est simulée sur la copie) qui porte deux .planning/ imbriqués : `habite/`
# (un agents/*.md ET un fichier de mémoire : habité, prédicat littéral de P45-D-14) et `zone/nu/` (aucun des deux). Le fichier
# d'attendus marque `zone/nu` doit-refuser-modele : le modèle l'interdit (lab non migré, P45-D-21a) ; tout autre `.planning/`
# imbriqué absent du fichier reste doit-passer.
FICHIERS_G7 = {".planning/notes.md": "n", "habite/.planning/notes.md": "n", "habite/.claude/agents/a.md": "a",
               "habite/.claude/memory/m.md": "m", "zone/nu/.planning/notes.md": "n", "zone/nu/.planning/sous/x.md": "x"}
ENTETE_ATTENDUS_G7 = ["# Attendus D-05 d'essai (fixtures synthétiques) : le chemin d'une ligne G7 est le dossier X où un .planning/ est créé.",
                      "# Tout autre .planning/ absent de D-05 reste doit-passer."]


def lab_g7(nom, avec_attendus=True):
    lab = fabriquer_lab(nom, FICHIERS_G7)
    aff = "~/" + os.path.basename(lab)
    lignes = ENTETE_ATTENDUS_G7 + (["G7 | %s | zone/nu | doit-refuser-modele | orphelin synthétique, refus conforme au modèle, lab non migré" % aff] if avec_attendus else [])
    return lab, aff, ecrire_attendus(lignes)


def lignes_g7(r, aff):
    return dict((l[2], (l[3], l[4])) for l in r.lignes if l[0] == "G7" and l[1] == aff)


# le relevé attendu à --etape=3 (vrai hook) : (attendu, obtenu) par chemin affiché
ATTENDU_G7 = {"habite/.planning/config.json [création]": ("doit-passer", "passe"),
              "zone/nu/.planning/config.json [création]": ("doit-refuser-modele", "refus"),
              "rejeu-orphelin-g7/.planning/config.json [création]": ("doit-refuser", "refus"),
              "habite/rejeu-orphelin-g7/.planning/config.json [création]": ("doit-refuser", "refus"),
              "zone/nu/rejeu-orphelin-g7/.planning/config.json [création]": ("doit-refuser", "refus")}

# Substitut qui ENREGISTRE, à chaque payload, si chacun des deux .planning/ imbriqués existe sur la copie (cwd du hook = la copie).
def sub_trace_g7(nom, journal):
    return substitut(nom, "\n".join([
        'cwd = os.getcwd()',
        'hab = os.path.isdir(os.path.join(cwd, "habite", ".planning"))',
        'nu = os.path.isdir(os.path.join(cwd, "zone", "nu", ".planning"))',
        'open(%r, "a").write("%%s|%%d|%%d\\n" %% (chemin[len(cwd) + 1:], hab, nu))' % journal,
        ""]))


def scenario_g7(script, etape=3):
    """Relevé du rejeu de l'étape `etape` avec le VRAI hook, le constructeur G7 et un fichier d'attendus synthétique, puis le
    même lab avec le substitut qui trace la mise de côté."""
    lab, aff, att = lab_g7(unique("lab-g7"))
    r = rejeu([lab], hook=HOOK, etape=etape, attendus=att, script=script)
    return r, aff


def trace_g7(script):
    """Journal du substitut : pour chaque payload, (chemin, habite présent, nu présent). Le constructeur G7 joue avec un substitut."""
    lab, aff, att = lab_g7(unique("lab-g7t"))
    journal = os.path.join(WORK, unique("trace-g7") + ".txt")
    r = rejeu([lab], hook=sub_trace_g7(unique("sub") + ".sh", journal), etape=3, attendus=att, script=script, scenario="")
    lignes = [l.split("|") for l in open(journal, encoding="utf-8").read().split("\n") if l] if os.path.exists(journal) else []
    return r, lignes


def sec_g7(_):
    """R-REJEU-G7 : constructeur G7, option --attendus, mise de côté et remise du .planning/ imbriqué sur la copie, comptage par étape."""
    fautes = []
    r, aff = scenario_g7(REJEU, 3)
    lignes = lignes_g7(r, aff)
    if r.rc != 0:
        fautes.append("--etape=3 : code %d : %s" % (r.rc, court(r.err)))
    if lignes != ATTENDU_G7:
        fautes.append("--etape=3 : lignes G7 %s (attendu %s)" % (sorted(lignes.items()), sorted(ATTENDU_G7.items())))
    if r.compte.get("G7") != (0, 0, 1) or "G7" in r.hors_etape or r.etape != (0, 0, 1):
        fautes.append("--etape=3 : COMPTE G7 %s hors=%s REJEU-ETAPE-3 %s (attendu (0, 0, 1) : le nu est un refus conforme au modèle, compté à part)" % (r.compte.get("G7"), sorted(r.hors_etape), r.etape))
    if any("EMPREINTE-DIVERGENTE" in e for e in r.empreintes) or not any(e.startswith("EMPREINTE-IDENTIQUE") for e in r.empreintes):
        fautes.append("--etape=3 : empreinte du lab réel %s" % r.empreintes)
    for chemin, (attendu, obtenu) in (("zone/nu/.planning/config.json [création]", ("doit-refuser-modele", "refus")),):
        motif = [l for l in r.lignes if l[2] == chemin]
        if not motif or "refus conforme au modèle, lab non migré" not in motif[0][5]:
            fautes.append("--etape=3 : la ligne du nu ne porte pas « refus conforme au modèle, lab non migré » : %s" % motif)
    # même lab à --etape=2 : le constructeur est joué (ses lignes sont au relevé), la ligne COMPTE est suffixée et ne compte pas
    r2, aff2 = scenario_g7(REJEU, 2)
    l2 = lignes_g7(r2, aff2)
    if sorted(l2) != sorted(ATTENDU_G7) or any(obtenu != "passe" for _a, obtenu in l2.values()):
        fautes.append("--etape=2 : lignes G7 %s (attendu les mêmes cinq clés, toutes passées : G7 est simulé en observe)" % sorted(l2.items()))
    if r2.compte.get("G7") != (0, 4, 0) or "G7" not in r2.hors_etape or r2.etape != (0, 0, 0):
        fautes.append("--etape=2 : COMPTE G7 %s hors=%s REJEU-ETAPE-2 %s (attendu (0, 4, 0) hors-etape, totaux à 0)" % (r2.compte.get("G7"), sorted(r2.hors_etape), r2.etape))
    # un lab sans attendu : le nu reste doit-passer par défaut, le hook armé le refuse : faux refus nominatif (jamais un refus conforme)
    lab, aff, _att = lab_g7(unique("lab-g7d"), avec_attendus=False)
    r3 = rejeu([lab], hook=HOOK, etape=3)
    if lignes_g7(r3, aff).get("zone/nu/.planning/config.json [création]") != ("doit-passer", "refus") or r3.compte.get("G7") != (1, 0, 0):
        fautes.append("sans attendu : le nu doit rester doit-passer/refus et compter un faux refus : %s %s" % (lignes_g7(r3, aff).get("zone/nu/.planning/config.json [création]"), r3.compte.get("G7")))
    # mise de côté et remise : pendant le payload de création d'un dossier, il est absent et l'autre présent ; tous les autres payloads les voient
    rt, trace = trace_g7(REJEU)
    if rt.rc != 0 or not trace:
        fautes.append("trace : code %d, %d ligne(s) (rouge, jamais un vert à vide) %s" % (rt.rc, len(trace), court(rt.err)))
    else:
        absents_hab = [l for l in trace if l[1] == "0"]
        absents_nu = [l for l in trace if l[2] == "0"]
        if [l[0] for l in absents_hab] != ["habite/.planning/config.json"] or absents_hab[0][2] != "1":
            fautes.append("trace : habite absent pendant %s (attendu son seul payload de création, nu présent)" % [l[0] for l in absents_hab])
        if [l[0] for l in absents_nu] != ["zone/nu/.planning/config.json"] or absents_nu[0][1] != "1":
            fautes.append("trace : nu absent pendant %s (attendu son seul payload de création, habite présent)" % [l[0] for l in absents_nu])
    # attendu G7 à chemin invalide : erreur (code 1), jamais un passage implicite
    lab_i = fabriquer_lab(unique("lab-g7i"), FICHIERS_G7)
    att_i = ecrire_attendus(["G7 | ~/%s | ../dehors | doit-refuser-modele | chemin invalide" % os.path.basename(lab_i)])
    ri = rejeu([lab_i], hook=HOOK, etape=3, attendus=att_i)
    if ri.rc != 1 or "invalide" not in ri.err:
        fautes.append("attendu G7 à chemin `..` : code %d %s (attendu 1 et « invalide »)" % (ri.rc, court(ri.err)))
    if fautes:
        for f in fautes:
            ko("R-REJEU-G7", "constructeur G7 + --attendus (fixtures synthétiques) : le nu est un refus conforme au modèle, le .planning/ imbriqué est remis en place", "voir le cas", f)
    else:
        ok("R-REJEU-G7 vrai hook, --etape=3, lab synthétique à deux .planning/ imbriqués (habité, nu) et un fichier d'attendus dont la ligne G7 marque zone/nu doit-refuser-modele (la colonne chemin se termine par le nom du dossier) : faux-refus=0 faux-accept=0 refus-conforme-modele=1 (les trois créations synthétiques en doit-refuser/refus, l'habité en doit-passer/passe) ; empreinte du lab identique ; le même lab à --etape=2 joue le constructeur, COMPTE G7 (0, 4, 0) hors-etape et REJEU-ETAPE-2 à 0 ; sans attendu, le nu reste doit-passer et compte un faux refus ; un substitut qui trace montre le dossier visé absent pendant son seul payload de création et présent ailleurs ; un chemin d'attendu en `..` est refusé (code 1)")


# --- 45-09 : ROLE, constructeur du rejeu (R-REJEU-ROLE) ---------------------------------------------------------------------
# Lab synthétique non migré (config 2.0, l'adhésion est simulée sur la copie) dont la RACINE porte un juge, un manager à allowlist,
# un worker à allowlist (une seule entrée : cible-w), un producteur, un juge dont le name: diffère du nom de fichier, deux
# définitions contradictoires du même nom (juge et producteur : agent inconnu du hook, P45-D-11) et un lien symbolique vers le juge
# (jamais une définition). F9 = f9-allowlist (Willy, AskUserQuestion session principale, 2026-09-30) : le dispatch du worker dans sa
# propre allowlist est doit-passer.
def _agent(nom, tools, extra=""):
    return "---\nname: %s\ndescription: agent synthétique\ntools: %s\n%s---\nCorps.\n" % (nom, tools, extra)


ROLE_FICHIERS = {
    ".claude/agents/juge-test.md": _agent("juge-test", "Read, Glob, Grep", "disallowedTools: Write, Edit\nomitClaudeMd: true\n"),
    ".claude/agents/autre-fichier.md": _agent("Juge_Mixte", "Read, Glob, Grep", "disallowedTools: Write, Edit\nomitClaudeMd: true\n"),
    ".claude/agents/manager-test.md": _agent("manager-test", "Read, Write, SendMessage, Agent(cible-m1, cible-m2)"),
    ".claude/agents/worker-test.md": _agent("worker-test", "Read, Agent(cible-w)", "vf-internal: true\n"),
    ".claude/agents/producteur-test.md": _agent("producteur-test", "Read, Write"),
    ".claude/agents/ambigu-a.md": _agent("ambigu", "Read, Glob, Grep", "disallowedTools: Write, Edit\nomitClaudeMd: true\n"),
    ".claude/agents/ambigu-b.md": _agent("ambigu", "Read, Write"),
}
# (chemin affiché) -> (attendu, obtenu) du relevé de l'étape 4 avec le vrai hook
ATTENDU_ROLE = {
    "rejeu-role/juge-test.md [Write@juge-test]": ("doit-refuser", "refus"),
    "rejeu-role/Juge_Mixte.md [Write@Juge_Mixte]": ("doit-refuser", "refus"),
    "rejeu-role/manager-test.md [Write@manager-test]": ("doit-passer", "passe"),
    "cible-m1 [Agent@manager-test]": ("doit-passer", "passe"),
    "cible-m2 [Agent@manager-test]": ("doit-passer", "passe"),
    "rejeu-role/worker-test.md [Write@worker-test]": ("doit-passer", "passe"),
    "cible-w [Agent@worker-test]": ("doit-passer", "passe"),
    "hors-liste-rejeu [Agent@worker-test]": ("doit-refuser", "refus"),
    "hors-liste-rejeu [Task@worker-test]": ("doit-refuser", "refus"),
    "rejeu-role/producteur-test.md [Write@producteur-test]": ("doit-passer", "passe"),
    "rejeu-role/ambigu.md [Write@ambigu]": ("doit-passer", "passe"),
}
ROLE_AGENTS = ["ROLE-AGENT lab=%s agent=ambigu role=ambigu ecriture=doit-passer dispatchs=0",
               "ROLE-AGENT lab=%s agent=juge-test role=juge ecriture=doit-refuser dispatchs=0",
               "ROLE-AGENT lab=%s agent=Juge_Mixte role=juge ecriture=doit-refuser dispatchs=0",
               "ROLE-AGENT lab=%s agent=manager-test role=manager ecriture=doit-passer dispatchs=2",
               "ROLE-AGENT lab=%s agent=producteur-test role=producteur ecriture=doit-passer dispatchs=0",
               "ROLE-AGENT lab=%s agent=worker-test role=worker ecriture=doit-passer dispatchs=1"]
# Substitut qui applique LA LETTRE de la table §5 (« Worker : tout dispatch refusé ») et refuse le juge : la légitimité du
# constructeur ne dérive jamais du rôle, le dispatch du worker dans sa propre allowlist compte donc un faux refus.
SUB_LETTRE = "\n".join([
    'if ARMEMENT_ROLE == "armed" and outil in ("Agent", "Task") and p.get("agent_type") == "worker-test":',
    '    refuser("ROLE", "worker : tout dispatch refusé (la lettre)")',
    'if ARMEMENT_ROLE == "armed" and outil == "Write" and p.get("agent_type") in ("juge-test", "Juge_Mixte"):',
    '    refuser("ROLE", "juge")',
    ''])


def substitut_classeur(nom, corps):
    """Substitut de hook qui répond aussi à `--classer` (le constructeur ROLE l'appelle sur la copie du hook) : il délègue ce mode au
    vrai hook ; toute autre décision est la sienne."""
    deleg = '#!/usr/bin/env bash\nif [ "${1:-}" = "--classer" ]; then exec bash %s --classer "${2:-}"; fi\n' % HOOK
    tete = TETE_SUBSTITUT.replace("@PY@", PYBIN).replace("#!/usr/bin/env bash\n", deleg, 1)
    chemin = os.path.join(WORK, "substituts", nom)
    ecrire(chemin, tete + corps + "\nPY_SUBSTITUT_EOF\n", 0o755)
    return chemin


def lab_role(nom, avec_planning=True):
    lab = fabriquer_lab(nom, ROLE_FICHIERS, config='{"planning_version": "2.0"}' if avec_planning else None)
    os.symlink(os.path.join(lab, ".claude", "agents", "juge-test.md"), os.path.join(lab, ".claude", "agents", "lien-juge.md"))
    return lab, "~/" + os.path.basename(lab)


def scenario_role(script, etape=4, hook=HOOK, avec_planning=True):
    lab, aff = lab_role(unique("lab-role"), avec_planning)
    r = rejeu([lab], hook=hook, etape=etape, script=script, scenario=("" if hook != HOOK else None))
    return r, aff


def lignes_role(r, aff):
    return dict((l[2], (l[3], l[4])) for l in r.lignes if l[0] == "ROLE" and l[1] == aff)


def sec_role(_):
    """R-REJEU-ROLE : constructeur ROLE, le vrai hook armé à l'étape 4, légitimité mesurée sur les déclarations (F9 = f9-allowlist)."""
    fautes = []
    r, aff = scenario_role(REJEU, 4)
    lignes = lignes_role(r, aff)
    if r.rc != 0:
        fautes.append("--etape=4 : code %d : %s" % (r.rc, court(r.err)))
    if lignes != ATTENDU_ROLE:
        fautes.append("--etape=4 : lignes ROLE %s (attendu %s)" % (sorted(lignes.items()), sorted(ATTENDU_ROLE.items())))
    if r.compte.get("ROLE") != (0, 0, 0) or "ROLE" in r.hors_etape or r.etape != (0, 0, 0):
        fautes.append("--etape=4 : COMPTE ROLE %s hors=%s REJEU-ETAPE-4 %s (attendu (0, 0, 0) compté)" % (r.compte.get("ROLE"), sorted(r.hors_etape), r.etape))
    if any("EMPREINTE-DIVERGENTE" in e for e in r.empreintes) or not any(e.startswith("EMPREINTE-IDENTIQUE") for e in r.empreintes):
        fautes.append("--etape=4 : empreinte du lab réel %s" % r.empreintes)
    notes = sorted(l for l in r.out.split("\n") if l.startswith("ROLE-AGENT "))
    if notes != sorted(m % aff for m in ROLE_AGENTS):
        fautes.append("--etape=4 : lignes ROLE-AGENT %s (attendu %s)" % (notes, sorted(m % aff for m in ROLE_AGENTS)))
    if any("lien-juge" in l[2] for l in r.lignes):
        fautes.append("--etape=4 : un agent en lien symbolique est rejoué comme une définition : %s" % [l[2] for l in r.lignes if "lien-juge" in l[2]])
    # --etape=3 : ROLE est simulé en observe ; ses lignes sont imprimées, son compte est hors-etape et n'entre pas dans REJEU-ETAPE-3
    r3, aff3 = scenario_role(REJEU, 3)
    l3 = lignes_role(r3, aff3)
    if sorted(l3) != sorted(ATTENDU_ROLE) or any(obtenu != "passe" for _a, obtenu in l3.values()):
        fautes.append("--etape=3 : lignes ROLE %s (attendu les mêmes onze clés, toutes passées : ROLE est simulé en observe)" % sorted(l3.items()))
    if r3.compte.get("ROLE") != (0, 4, 0) or "ROLE" not in r3.hors_etape or r3.etape != (0, 0, 0):
        fautes.append("--etape=3 : COMPTE ROLE %s hors=%s REJEU-ETAPE-3 %s (attendu (0, 4, 0) hors-etape, totaux à 0)" % (r3.compte.get("ROLE"), sorted(r3.hors_etape), r3.etape))
    # la lettre (le substitut refuse tout dispatch d'un worker) : le dispatch de sa propre allowlist est un faux refus ; le reste reste à 0
    rs, affs = scenario_role(REJEU, 4, hook=substitut_classeur(unique("sub-lettre") + ".sh", SUB_LETTRE))
    ls = lignes_role(rs, affs)
    if ls.get("cible-w [Agent@worker-test]") != ("doit-passer", "refus") or rs.compte.get("ROLE") != (1, 0, 0):
        fautes.append("la lettre : %s COMPTE ROLE %s (attendu doit-passer/refus, (1, 0, 0) : le dispatch de la propre allowlist du worker ; les autres gates du substitut ne sont pas jugés ici)" % (ls.get("cible-w [Agent@worker-test]"), rs.compte.get("ROLE")))
    # un lab sans .planning/ à la racine (lab dev) : le constructeur ne rejoue rien
    rd, affd = scenario_role(REJEU, 4, avec_planning=False)
    if rd.rc != 0 or lignes_role(rd, affd) or rd.compte.get("ROLE") != (0, 0, 0):
        fautes.append("lab sans .planning/ : code %d lignes ROLE %s COMPTE ROLE %s (attendu aucune ligne)" % (rd.rc, sorted(lignes_role(rd, affd)), rd.compte.get("ROLE")))
    if fautes:
        for f in fautes:
            ko("R-REJEU-ROLE", "constructeur ROLE : légitimité mesurée sur les déclarations des agents, le vrai hook armé à l'étape 4", "voir le cas", f)
    else:
        ok("R-REJEU-ROLE vrai hook, --etape=4, lab synthétique à la racine duquel vivent un juge, un juge dont le name: diffère du fichier, un manager, un worker à allowlist, un producteur, deux définitions contradictoires (agent inconnu : écriture doit-passer) et un lien symbolique (jamais une définition) : onze lignes, l'écriture d'un agent qui retire Write et Edit en doit-refuser/refus, le dispatch du worker dans sa propre allowlist en doit-passer/passe (F9 = f9-allowlist), le dispatch hors liste sous Agent ET Task en doit-refuser/refus, COMPTE ROLE (0, 0, 0), six lignes ROLE-AGENT ; à --etape=3 ROLE est en observe, COMPTE ROLE (0, 4, 0) hors-etape, REJEU-ETAPE-3 à 0 ; un substitut qui applique la lettre (tout dispatch d'un worker refusé) compte un faux refus sur le dispatch de sa propre allowlist (la légitimité ne dérive jamais du rôle) ; un lab sans .planning/ à la racine ne rejoue rien")


ETATS_CADRAGE = ("absent", "herite", "clos", "ouvert", "vide", "invalide", "dossier", "lien")
ORACLE_G1 = {"absent": "refus", "herite": "passe", "clos": "passe", "ouvert": "refus", "vide": "passe", "invalide": "passe", "dossier": "passe", "lien": "passe"}
BRANCHE_ATTENDUE = {"absent": "pas-de-cadrage", "herite": "herite", "clos": "clos", "ouvert": "registre-ouvert", "vide": "clos",
                    "invalide": "illisible", "dossier": "non-regulier", "lien": "non-regulier"}
_CELLULES = []


def cellules_g1():
    """Produit cartésien CALCULÉ (itertools.product), 2 x 2 x 8 x 2 = 64 : cycle {avec, sans} CYCLE.md, nom de phase {dans, hors}
    NOM_UNITE, état de CADRAGE.md, autre entrée non régulière dans la phase {non, oui}."""
    return list(itertools.product(("avec", "sans"), ("conforme", "hors"), ETATS_CADRAGE, ("non", "oui")))


def fabriquer_cellules():
    if _CELLULES:
        return _CELLULES
    contenus = {"herite": HERITE_G1, "clos": CLOS_G1, "ouvert": OUVERT_G1, "vide": "---\ninconnues: []\n---\n", "invalide": "---\ninconnues: []\n"}
    for i, cell in enumerate(cellules_g1()):
        cycle, nom, etat, autre = cell
        phase = "01-p" if nom == "conforme" else "phase-x"
        f = {PH + phase + "/PLAN.md": PLAN_G1}
        if cycle == "avec":
            f[PH[:-7] + "CYCLE.md"] = CYCLE_G1
        if etat in contenus:
            f[PH + phase + "/CADRAGE.md"] = contenus[etat]
        lab = fabriquer_lab("lab-cc%02d" % i, f, config='{"planning_version": "cycles-v1"}')
        dossier = os.path.join(lab, PH, phase)
        if etat == "dossier":
            os.makedirs(os.path.join(dossier, "CADRAGE.md"))
        if etat == "lien":
            os.symlink("cible-absente", os.path.join(dossier, "CADRAGE.md"))
        if autre == "oui":
            os.makedirs(os.path.join(dossier, "CLOTURE.md"))
        _CELLULES.append((cell, lab, phase))
    return _CELLULES


def hook_arme():
    chemin = os.path.join(WORK, "hook-arme-g1", "planning-hook.sh")
    if not os.path.exists(chemin):
        texte, n = re.subn(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE|G3|G4|G4P) = )"(?:observe|armed)"', r'\1"armed"', open(HOOK, encoding="utf-8").read(), flags=re.M)
        if n != 8:
            raise RuntimeError("huit constantes ARMEMENT_* attendues, %d trouvée(s)" % n)
        ecrire(chemin, texte, 0o755)
    return chemin


def verdict_hook(lab, rel):
    """`refus` (deny `[planning-core] G1 :`), `passe` (stdout vide) ou `autre` : le VRAI hook, copie armée, Write de `rel`."""
    obj = {"session_id": "t", "transcript_path": "t", "cwd": lab, "hook_event_name": "PreToolUse", "tool_name": "Write",
           "tool_input": {"file_path": os.path.join(lab, rel), "content": "x"}, "tool_use_id": "t"}
    p = subprocess.run(["bash", hook_arme()], input=json.dumps(obj).encode("utf-8"), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=env_sain(), cwd=lab, timeout=120)
    if p.returncode != 0:
        return "autre"
    if p.stdout == b"":
        return "passe"
    s = json.loads(p.stdout.decode("utf-8"))["hookSpecificOutput"]
    return "refus" if s.get("permissionDecision") == "deny" and s.get("permissionDecisionReason", "").startswith("[planning-core] G1 :") else "autre"


def exploitable_essai(etat, raison):
    """Partition de l'interface du plan, écrite ICI (jamais reprise de l'outil) : exploitable = tout état autre que indéterminé, et,
    sous indéterminé, les seules raisons de Φ2 à Φ4."""
    if etat != "indéterminé":
        return True
    r = raison or ""
    return r.startswith("hors-cadrage:") or r.startswith("avant-cadrage-clos:") or r == "registre-invalide" or r == "frontmatter-invalide:CADRAGE.md"


def etats_recalcul(lab):
    p = subprocess.run(["bash", RECALC, "--planning=" + os.path.join(lab, ".planning"), "--read-only"], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=env_sain(), timeout=180)
    donnees = json.loads(p.stdout.decode("utf-8"))
    return dict((ph["chemin"], (ph["etat"], ph.get("raison"))) for c in donnees.get("cycles", []) for ph in c.get("phases", []))


def mesurer_cellules(script, selection, hook):
    """{cellule: (attendu, branche, n)} du relevé de `script` (vrai jeu de constructeurs) sur les cellules choisies."""
    cibles = [c for c in fabriquer_cellules() if selection(c[0])]
    r = rejeu([c[1] for c in cibles], hook=hook, etape=2, scenario="", script=script)
    par_lab = {}
    for l in r.lignes:
        par_lab.setdefault(l[1], {})[l[2]] = l
    res = {}
    for cell, lab, phase in cibles:
        aff = "~/" + os.path.basename(lab)
        l = par_lab.get(aff, {}).get(PH + phase + "/PLAN.md")
        branche = None
        if l is not None and "état dérivé absent : " in l[5]:
            branche = l[5].split("état dérivé absent : ")[-1].strip()
        res[cell] = (None if l is None else l[3], branche, r.classe.get(("G1", aff)))
    return res


def divergences_relevee(mesure):
    """Cellules dont l'attendu du relevé n'est pas l'oracle (une table de huit lignes plus la ligne hors NOM_UNITE)."""
    res = []
    for cell, (attendu, _branche, _n) in mesure.items():
        oracle = "passe" if cell[1] == "hors" else ORACLE_G1[cell[2]]
        if (attendu == "doit-refuser-modele") != (oracle == "refus"):
            res.append(cell)
    return res


def sec_concordance(_):
    """R-REJEU-G1-CONCORDANCE : test différentiel, règle écrite de l'outil contre le prédicat du hook, sur 64 cellules GÉNÉRÉES."""
    cellules = fabriquer_cellules()
    fautes = []
    if len(cellules) != 64:
        fautes.append("%d cellules générées (attendu EXACTEMENT 64)" % len(cellules))
    mesure = mesurer_cellules(REJEU, lambda c: True, HOOK)
    div, raisons, somme = [], {}, 0
    for cell, lab, phase in cellules:
        attendu, branche, n = mesure[cell]
        hook_v = verdict_hook(lab, PH + phase + "/PLAN.md")
        oracle = "passe" if cell[1] == "hors" else ORACLE_G1[cell[2]]
        if attendu is None or hook_v == "autre" or not ((attendu == "doit-refuser-modele") == (hook_v == "refus") == (oracle == "refus")):
            div.append("cellule (cycle=%s, nom=%s, cadrage=%s, autre=%s) : attendu du relevé %s, hook %s, oracle %s" % (cell + (attendu, hook_v, oracle)))
        somme += n or 0
        if branche is not None:
            raisons[branche] = raisons.get(branche, 0) + 1
            if branche != BRANCHE_ATTENDUE[cell[2]]:
                div.append("cellule %s : raison nommée %s (attendu %s)" % (cell, branche, BRANCHE_ATTENDUE[cell[2]]))
    # recalcul côté suite : la partition (état, raison) de l'interface, cellule par cellule
    non_exploitables = 0
    for cell, lab, phase in cellules:
        if cell[1] != "conforme":
            continue
        etat = etats_recalcul(lab).get("cycles/01-c/phases/" + phase)
        non = etat is None or not exploitable_essai(*etat)
        non_exploitables += 1 if non else 0
        if (mesure[cell][2] == 1) != non:
            div.append("cellule %s : n=%s, état dérivé %s (n=1 <=> non exploitable)" % (cell, mesure[cell][2], etat))
    if "defaut" in raisons:
        div.append("raison `defaut` : la règle écrite n'a pas de branche par défaut")
    if non_exploitables != 26 or somme != 26:
        div.append("cellules à nom conforme non exploitables : %d, somme des n : %d (attendu 26 et 26)" % (non_exploitables, somme))
    print("CONCORDANCE G1 cellules=%d divergences=%d" % (len(cellules), len(div)))
    print("RAISONS-REGLE-ECRITE G1 " + " ".join("%s=%d" % kv for kv in sorted(raisons.items())) + " somme-n=%d" % somme)
    fautes.extend(div[:8])
    if fautes:
        for f in fautes:
            ko("R-REJEU-G1-CONCORDANCE", "la règle écrite de l'outil et le prédicat de G1 rendent le même verdict sur 64 cellules générées", "0 divergence", f)
    else:
        ok("R-REJEU-G1-CONCORDANCE 64 cellules générées (itertools.product : cycle x nom de phase x état de CADRAGE.md x autre entrée non régulière) : attendu du relevé <=> deny du vrai hook (copie armée) <=> oracle de huit lignes, 0 divergence ; raisons nommées %s, aucune raison `defaut` ; somme des n = 26 = cellules à nom conforme sans état dérivé exploitable (recalcul lancé par la suite, cellule par cellule)" % ", ".join("%s=%d" % kv for kv in sorted(raisons.items())))


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
    if not v and n == 4:
        ok("R-REJEU-STATIQUE le texte de rejeu-gates.sh ne lance aucun sous-processus autre que bash (le hook copié : le jeu d'une écriture et `--classer` du constructeur ROLE ; recalc-planning.sh --read-only) et cmp (4 appels, aucun git)")
    else:
        ko("R-REJEU-STATIQUE", "sous-processus de rejeu-gates.sh", "bash (hook copié, `--classer`, recalc-planning.sh) et cmp seulement, 4 appels", "violations=%s appels=%d" % (v, n))
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

    # R-REEL-05 : --lab est un lien symbolique vers le lab (M1) — la racine est résolue, l'arbre réel
    # est parcouru, l'écriture hors périmètre est vue.
    reel5 = fabriquer_lab("lab-r5", {".planning/notes.md": "n", "code.txt": "c"})
    lien5 = os.path.join(HOME, "lien-vers-lab-r5")
    os.symlink(reel5, lien5)
    ecrit5 = substitut("sub-lien-lab.sh", 'open(%r, "a").write("mutated")' % os.path.join(reel5, "code.txt"))
    r = rejeu([lien5], hook=ecrit5, reel=True)
    if r.rc == 1 and "EMPREINTE-ARBRE-DIVERGENTE ~/lab-r5" in r.rapport and "EMPREINTE-ARBRE-IDENTIQUE" not in r.rapport:
        ok("R-REEL-05 --lab donné par un lien symbolique vers le lab, substitut qui écrit code.txt hors périmètre : EMPREINTE-ARBRE-DIVERGENTE et code 1 (racine résolue avant l'empreinte)")
    else:
        ko("R-REEL-05", "--lab = lien vers le lab, écriture réelle hors périmètre", "code 1, EMPREINTE-ARBRE-DIVERGENTE ~/lab-r5, jamais IDENTIQUE", "rc=%d rapport=%s err=%s" % (r.rc, court(r.rapport), court(r.err)))

    # R-REEL-06 : --rapport sous un lab, ou lien vers l'intérieur d'un lab (M2) — refus avant toute
    # empreinte, aucun fichier créé dans le lab, aucune ligne EMPREINTE-ARBRE-*.
    lab6 = fabriquer_lab("lab-r6", {".planning/notes.md": "n"})
    sub6 = substitut("sub-passe-rapport.sh", SUB_PASSE)
    fautes = []
    lien6 = os.path.join(HOME, "lien-rapport-r6")
    os.symlink(os.path.join(lab6, "rapport-lien.txt"), lien6)
    for nom, cible in (("sous le lab", os.path.join(lab6, "rapport-dedans.txt")), ("lien vers l'intérieur du lab", lien6)):
        r = rejeu([lab6], hook=sub6, reel=True, rapport=False, extra=["--rapport=" + cible])
        crees = [f for f in os.listdir(lab6) if f.startswith("rapport-")]
        if not (r.rc == 64 and not crees and "EMPREINTE-ARBRE" not in r.out and r.err.startswith("[rejeu-reel] le rapport ne peut pas être écrit sous un lab")):
            fautes.append("rapport %s : attendu code 64, refus de rejeu-reel.sh avant toute mesure, rien dans le lab ; obtenu rc=%d créés=%s out=%s err=%s" % (nom, r.rc, crees, court(r.out), court(r.err)))
    if fautes:
        for f in fautes:
            ko("R-REEL-06", "un rapport sous un lab est refusé avant toute empreinte", "voir le cas", f)
    else:
        ok("R-REEL-06 --rapport sous un lab, ou lien symbolique vers l'intérieur d'un lab : code 64, refus émis par rejeu-reel.sh avant toute mesure, aucun fichier créé dans le lab, aucune ligne EMPREINTE-ARBRE-*")

    # R-REEL-07 : rejeu-gates.sh refuse l'usage (code 64) : rien n'a été rejoué, donc rien à annoncer.
    lab7 = fabriquer_lab("lab-r7", {".planning/notes.md": "n"})
    rap7 = os.path.join(WORK, unique("rapport") + ".txt")
    p7 = subprocess.run(["bash", REEL, "--lab=" + lab7, "--rapport=" + rap7], stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env_sain(), timeout=600)
    if p7.returncode == 64 and b"EMPREINTE-ARBRE" not in p7.stdout and not os.path.exists(rap7):
        ok("R-REEL-07 usage refusé par rejeu-gates.sh (--etape absent) : code 64 repris, aucune ligne EMPREINTE-ARBRE-* imprimée, rapport non créé")
    else:
        ko("R-REEL-07", "aucune empreinte annoncée quand rien n'a été rejoué", "code 64, sortie sans EMPREINTE-ARBRE, rapport absent", "rc=%d out=%s rapport=%s" % (p7.returncode, court(p7.stdout), os.path.exists(rap7)))


# --- Quick 45-B (H3, B3) : aucun lien symbolique du lab ne fait écrire ou lire hors de la copie ; arbre très profond -------------
# Décisions du manager (vf-dev-manager, 2026-10-01), renversables. Un lien dont la cible résolue sort du lab est une ERREUR
# (code 1, dossier extérieur intact) avant toute écriture sur la copie ; un lien dont la cible reste dans le lab est suivi
# normalement (témoin positif). Le geste réel (rejeu-reel.sh) le refuse AVANT de rien jouer.
def lab_ext(nom, lien, relatif=False, avec_cycle=False):
    """Lab synthétique dont `lien` (chemin relatif au lab) est un lien symbolique vers un dossier EXTÉRIEUR `ext-<nom>`."""
    lab = fabriquer_lab(nom, {".planning/notes.md": "n"})
    ext = os.path.join(HOME, "ext-" + nom)
    ecrire(os.path.join(ext, "x.txt"), "extérieur")
    if avec_cycle:
        ecrire(os.path.join(lab, ".planning", "cycles", "01-c", "CYCLE.md"), "c")
    chemin = os.path.join(lab, lien)
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    os.symlink(os.path.relpath(ext, os.path.dirname(chemin)) if relatif else ext, chemin)
    return lab, ext


def sec_liens(_):
    """R-REJEU-LIENS (H3) : écriture et lecture à travers un lien sortant ; R-REEL-LIENS ; R-REEL-PROF (B3)."""
    cas = (("cycles absolu", ".planning/cycles", False, False), ("cycles relatif", ".planning/cycles", True, False),
           ("phases d'un cycle réel", ".planning/cycles/01-c/phases", False, True))
    fautes = []
    for nom, lien, relatif, avec_cycle in cas:
        lab, ext = lab_ext(unique("lab-l"), lien, relatif, avec_cycle)
        avant = empreinte_arbre(ext)
        r = rejeu([lab], hook=HOOK, etape=2)
        if not (r.rc == 1 and r.err.startswith("[rejeu-gates] ") and "Traceback" not in r.err and empreinte_arbre(ext) == avant):
            fautes.append("%s : attendu code 1 et dossier extérieur intact ; obtenu rc=%d ext_intact=%s err=%s" % (nom, r.rc, empreinte_arbre(ext) == avant, court(r.err)))
    if fautes:
        for f in fautes:
            ko("R-REJEU-LIENS", "un lien qui sort du lab ne laisse rien écrire hors de la copie", "code 1, dossier extérieur intact", f)
    else:
        ok("R-REJEU-LIENS .planning/cycles (absolu, relatif) ou phases/ d'un cycle réel en lien vers un dossier extérieur : code 1, message de rejeu-gates.sh, dossier extérieur INTACT (empreinte comparée)")

    # témoin positif : un lien qui reste DANS le lab est suivi, aucun refus
    lab = fabriquer_lab(unique("lab-l"), {".planning/notes.md": "n", ".planning/vrais-cycles/01-c/CYCLE.md": "c"})
    os.symlink("vrais-cycles", os.path.join(lab, ".planning", "cycles"))
    r = rejeu([lab], hook=HOOK, etape=2)
    reel_intact = not os.path.exists(os.path.join(lab, ".planning", "vrais-cycles", "01-c", "phases"))
    if r.rc == 0 and reel_intact:
        ok("R-REJEU-LIENS témoin : .planning/cycles lien vers un dossier DU lab : suivi sur la copie, code 0, lab réel intact")
    else:
        ko("R-REJEU-LIENS témoin", "un lien interne au lab n'est pas refusé", "code 0, lab intact", "rc=%d intact=%s err=%s" % (r.rc, reel_intact, court(r.err)))

    # lecture : STATE.md en lien (vers l'extérieur, ou vers un fichier DU lab) : jamais suivi, la charge du hook porte le contenu neutre
    for nom, cible in (("extérieur", None), ("interne", "notes.md")):
        lab = fabriquer_lab(unique("lab-l"), {".planning/notes.md": "NOTE-INTERNE"})
        ext = os.path.join(HOME, unique("ext-secret"))
        ecrire(os.path.join(ext, "secret.md"), "SECRET-EXTERIEUR")
        os.symlink(cible or os.path.join(ext, "secret.md"), os.path.join(lab, ".planning", "STATE.md"))
        trace = os.path.join(WORK, unique("trace") + ".txt")
        sub = substitut(unique("sub-trace") + ".sh", 'if chemin.endswith("/.planning/STATE.md"): open(%r, "a").write(str(ti.get("content")) + "\\n")' % trace)
        r = rejeu([lab], hook=sub, scenario="g6-state")
        vu = open(trace, encoding="utf-8").read() if os.path.exists(trace) else ""
        if vu == "x\n":
            ok("R-REJEU-LIENS STATE.md en lien (%s) : son contenu n'est jamais lu, la charge du hook porte le contenu neutre" % nom)
        else:
            ko("R-REJEU-LIENS lecture (%s)" % nom, "payload sans suivi de lien (lstat + fichier régulier)", "charge neutre x", "rc=%d vu=%s" % (r.rc, court(vu)))

    # lecture : .claude/agents en lien vers un dossier extérieur portant une définition
    lab, ext = lab_ext(unique("lab-l"), ".claude/agents", False, False)
    ecrire(os.path.join(ext, "w.md"), _agent("w-ext", "Read, Agent(cible-w)", "vf-internal: true\n"))
    r = rejeu([lab], hook=HOOK, etape=4)
    if r.rc == 1 and "ROLE-AGENT" not in r.out and r.err.startswith("[rejeu-gates] "):
        ok("R-REJEU-LIENS .claude/agents en lien vers un dossier extérieur : code 1, aucune définition extérieure lue")
    else:
        ko("R-REJEU-LIENS agents", "definitions_racine sans suivi de lien", "code 1, aucune ligne ROLE-AGENT", "rc=%d out=%s err=%s" % (r.rc, court(r.out), court(r.err)))

    # geste réel : refus AVANT tout rejeu, rien d'écrit, rapport non créé
    cas_reel = (("cycles absolu", ".planning/cycles", False, False), ("cycles relatif", ".planning/cycles", True, False),
                ("phases d'un cycle réel", ".planning/cycles/01-c/phases", False, True), ("STATE.md", ".planning/STATE.md", False, False),
                ("agents", ".claude/agents", False, False))
    fautes = []
    for nom, lien, relatif, avec_cycle in cas_reel:
        lab, ext = lab_ext(unique("lab-lr"), lien, relatif, avec_cycle)
        avant, marque = empreinte_arbre(ext), os.path.join(WORK, unique("marque") + ".txt")
        sub = substitut(unique("sub-marque") + ".sh", 'open(%r, "w").write("joue")' % marque)
        r = rejeu([lab], hook=sub, reel=True)
        if not (r.rc == 1 and r.err.startswith("[rejeu-reel] ") and not os.path.exists(marque) and r.rapport == "" and "EMPREINTE-ARBRE" not in r.out
                and "Traceback" not in r.err and empreinte_arbre(ext) == avant):
            fautes.append("%s : attendu code 1, rien joué, rapport absent ; obtenu rc=%d joué=%s rapport=%s err=%s" % (nom, r.rc, os.path.exists(marque), court(r.rapport), court(r.err)))
    if fautes:
        for f in fautes:
            ko("R-REEL-LIENS", "rejeu-reel.sh refuse un lien sortant avant tout rejeu", "code 1, aucun hook joué", f)
    else:
        ok("R-REEL-LIENS rejeu-reel.sh : lien sortant sur cycles/, phases/, STATE.md ou .claude/agents : code 1 avec message, AUCUN hook joué, rapport non créé, dossier extérieur intact")
    # témoin : un lien sortant hors des chemins que le rejeu écrit ou lit n'est pas refusé
    lab, ext = lab_ext(unique("lab-lr"), "docs-externes", False, False)
    r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), reel=True)
    if r.rc == 0:
        ok("R-REEL-LIENS témoin : un lien sortant à la racine du lab, hors des chemins écrits ou lus, ne bloque pas le rejeu (code 0)")
    else:
        ko("R-REEL-LIENS témoin", "pas de sur-refus", "code 0", "rc=%d err=%s" % (r.rc, court(r.err)))

    # B3 : arbre de plus de 1 500 niveaux : erreur propre (code 1, message), jamais une trace Python
    lab = fabriquer_lab(unique("lab-prof"), {".planning/notes.md": "n"})
    base = os.path.join(lab, "src")
    os.makedirs(base)
    cwd = os.getcwd()
    try:
        os.chdir(base)
        for _ in range(1600):
            os.mkdir("d")
            os.chdir("d")
    finally:
        os.chdir(cwd)
    try:
        r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), reel=True)
        if r.rc == 1 and "Traceback" not in r.err and r.err.startswith("[rejeu-"):
            ok("R-REEL-PROF arbre de 1 600 niveaux : code 1 et message, jamais une trace Python (le volume de l'arbre reste une limite déclarée, non optimisée)")
        else:
            ko("R-REEL-PROF", "arbre très profond", "code 1, message [rejeu-…], pas de Traceback", "rc=%d err=%s" % (r.rc, court(r.err)))
    finally:
        try:
            os.chdir(base)
            n = 0
            while os.path.isdir("d") and n < 1600:
                os.chdir("d")
                n += 1
            for _ in range(n):
                os.chdir("..")
                os.rmdir("d")
        except OSError:
            pass
        finally:
            os.chdir(cwd)


# --- Quick 45-B (B2, B3) : relevé sans chemin de machine ni ligne forgée, garde « rapport sous un lab » insensible à la casse,
# arbre profond. Décisions du manager (vf-dev-manager, 2026-10-01), renversables. ------------------------------------------------
LANCEUR_PROFONDEUR = r'''
import importlib.util, os, sys
corps, mode, limite, dossier, jeu = sys.argv[1:6]
reste = sys.argv[6:]
spec = importlib.util.spec_from_file_location("rejeu_module", corps)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
mod.DOSSIER_SCRIPTS = dossier
sys.setrecursionlimit(int(limite))
sys.exit(mod.main(([jeu] if mode == "reel" else []) + reste))
'''


def hors_home(nom):
    """Lab synthétique HORS de HOME (sous WORK, frère de home/)."""
    racine = os.path.join(os.path.realpath(WORK), "hors-home", nom)
    ecrire(os.path.join(racine, ".planning", "config.json"), '{"planning_version": "2.0"}')
    ecrire(os.path.join(racine, ".planning", "notes.md"), "n")
    return racine


def sc_hors_home(script, reel=False):
    a, b = hors_home(unique("lab-hh")), hors_home(unique("lab-hh"))
    r = rejeu([a, b], hook=substitut(unique("sub") + ".sh", SUB_PASSE), script=script, reel=reel)
    tout = r.out + r.err + r.rapport
    return {"rc": r.rc, "absolu": os.path.realpath(WORK) in tout or WORK in tout, "generiques": "<lab-1>" in tout and "<lab-2>" in tout}


def sc_lf(script, reel=False):
    nom = "lab-lf" + unique("")
    forge = "COMPTE G6 faux-refus=9 faux-accept=9 refus-conforme-modele=9"
    lab = fabriquer_lab(nom + "\n" + forge + "-lab", {".planning/a\n" + forge + ".md": "x"})
    r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), script=script, reel=reel)
    lignes = (r.out + r.rapport).split("\n")
    return {"rc": r.rc, "forge": any(l.startswith("COMPTE G6 faux-refus=9") for l in lignes),
            "echappe": "\\x0a" in r.out and "\\x0a" in r.rapport}


def casse_insensible():
    sonde = os.path.join(HOME, "sonde-casse-45b")
    ecrire(os.path.join(sonde, "a"), "a")
    return os.path.exists(os.path.join(HOME, "SONDE-CASSE-45B", "a"))


def sc_casse(script, reel=True):
    lab = fabriquer_lab(unique("lab-Cs"), {".planning/notes.md": "n"})
    var = os.path.join(os.path.dirname(lab), os.path.basename(lab).upper(), "rapport-casse.txt")
    r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), script=script, reel=reel, rapport=False, extra=["--rapport=" + var])
    return {"rc": r.rc, "cree": os.path.exists(os.path.join(lab, "rapport-casse.txt")), "refus_par": r.err.split("]")[0]}


def arbre_profond(nom, n):
    lab = fabriquer_lab(nom, {".planning/notes.md": "n"})
    base = os.path.join(lab, "src")
    os.makedirs(base)
    cwd = os.getcwd()
    try:
        os.chdir(base)
        for _ in range(n):
            os.mkdir("d")
            os.chdir("d")
    finally:
        os.chdir(cwd)
    return lab


def lancer_profondeur(script, mode, limite, lab):
    corps = extraire(script, "PY_REJEU_GATES_EOF" if mode == "gates" else "PY_REJEU_REEL_EOF", os.path.join(WORK, "essais", unique("module-prof") + ".py"))
    ecrire(os.path.join(WORK, "essais", "lanceur_profondeur.py"), LANCEUR_PROFONDEUR)
    sub = substitut(unique("sub") + ".sh", SUB_PASSE)
    rap = os.path.join(WORK, unique("rapport") + ".txt")
    jeu = os.path.join(SCRIPTS, "rejeu-gates.sh")
    cmd = [PYBIN, os.path.join(WORK, "essais", "lanceur_profondeur.py"), corps, mode, str(limite), SCRIPTS, jeu,
           "--lab=" + lab, "--etape=1", "--hook=" + sub, "--rapport=" + rap]
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env_sain(), timeout=600)
    return p.returncode, p.stdout.decode("utf-8", "replace"), p.stderr.decode("utf-8", "replace"), (open(rap, encoding="utf-8").read() if os.path.exists(rap) else "")


def sc_prof_gates(script):
    lab = arbre_profond(unique("lab-pg"), 150)
    rc, out, err, _ = lancer_profondeur(script, "gates", 120, lab)
    return {"rc": rc, "message": err.startswith("[rejeu-gates] arborescence trop profonde"), "trace": "Traceback" in err}


def sc_prof_reel(script):
    lab = arbre_profond(unique("lab-pr"), 150)
    rc, out, err, rap = lancer_profondeur(script, "reel", 120, lab)
    return {"rc": rc, "trace": "Traceback" in err, "identique": "EMPREINTE-ARBRE-IDENTIQUE" in rap}


def sec_releve(_):
    """R-REJEU-RELEVE (B2) : jamais un chemin absolu, aucune ligne forgée par un nom ; R-REEL-CASSE ; R-REJEU-PROFOND (B3)."""
    for nom, script, reel in (("rejeu-gates.sh", REJEU, False), ("rejeu-reel.sh", REEL, True)):
        o = sc_hors_home(script, reel)
        if o["rc"] == 0 and not o["absolu"] and o["generiques"]:
            ok("R-REJEU-RELEVE %s : deux labs hors de HOME sont nommés <lab-1> et <lab-2>, aucun chemin absolu dans la sortie, le rapport ni les messages" % nom)
        else:
            ko("R-REJEU-RELEVE %s" % nom, "aucun chemin absolu de machine imprimé", "rc 0, <lab-1> et <lab-2>, aucun chemin absolu", o)
        o = sc_lf(script, reel)
        if o["rc"] == 0 and not o["forge"] and o["echappe"]:
            ok("R-REJEU-RELEVE %s : un LF dans un nom de dossier ou de fichier est échappé (\\x0a), aucune ligne du relevé n'est forgée" % nom)
        else:
            ko("R-REJEU-RELEVE %s LF" % nom, "un nom de fichier ne forge pas de ligne", "rc 0, aucune ligne COMPTE forgée, \\x0a visible", o)
    if casse_insensible():
        for nom, script, reel in (("rejeu-reel.sh", REEL, True), ("rejeu-gates.sh", REJEU, False)):
            o = sc_casse(script, reel)
            if o["rc"] == 64 and not o["cree"] and o["refus_par"] == "[" + nom[:-3]:
                ok("R-REEL-CASSE %s : --rapport sous le lab écrit avec une autre casse (même dossier sur ce système de fichiers) : code 64, aucun fichier créé dans le lab" % nom)
            else:
                ko("R-REEL-CASSE %s" % nom, "le garde « rapport sous un lab » compare l'identité des dossiers", "code 64, rien créé", o)
    else:
        ok("R-REEL-CASSE non applicable ici : ce système de fichiers distingue la casse, `/x/LAB` et `/x/lab` y sont deux dossiers (le cas se joue sous APFS/NTFS par défaut)")
    # B3 : le parcours de rejeu-reel.sh est ITÉRATIF (limite de récursion abaissée à 120 sur un arbre de 150 niveaux : il passe) ;
    # celui de rejeu-gates.sh est récursif : message et code 1, jamais une trace.
    o = sc_prof_reel(REEL)
    if o["rc"] == 0 and o["identique"] and not o["trace"]:
        ok("R-REJEU-PROFOND rejeu-reel.sh : parcours itératif, un arbre de 150 niveaux sous une limite de récursion de 120 est empreint sans erreur (EMPREINTE-ARBRE-IDENTIQUE)")
    else:
        ko("R-REJEU-PROFOND rejeu-reel.sh", "parcours sans récursion", "rc 0, EMPREINTE-ARBRE-IDENTIQUE, pas de trace", o)
    o = sc_prof_gates(REJEU)
    if o["rc"] == 1 and o["message"] and not o["trace"]:
        ok("R-REJEU-PROFOND rejeu-gates.sh : un arbre plus profond que la pile de l'interpréteur rend le code 1 et un message, jamais une trace Python")
    else:
        ko("R-REJEU-PROFOND rejeu-gates.sh", "erreur propre sur un arbre trop profond", "rc 1, message, pas de trace", o)


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


# --- Lot C, F1 (re-revue) : un `.planning` du lab qui est LUI-MÊME un lien sortant est refusé ; une mesure à zéro ligne n'est jamais un vert ---
# Décisions du manager (vf-dev-manager, 2026-10-01), renversables. Avant : `.planning` en lien vers l'extérieur n'était pas dans les chemins
# à risque, la copie du rejeu n'y voyait rien, le geste rendait 0 ligne mesurée et EMPREINTE-ARBRE-IDENTIQUE (un vert vide).
def lab_planning_lien(nom, imbrique=False):
    """Lab synthétique dont `.planning` (racine, ou `sous/.planning` si `imbrique`) est un lien vers un dossier EXTÉRIEUR qui porte un vrai
    `.planning` (config.json, notes.md). Rend (lab, dossier extérieur)."""
    lab = fabriquer_lab(nom, {"src/a.txt": "a"}, config=None)
    ext = os.path.join(HOME, "ext-" + nom)
    ecrire(os.path.join(ext, "config.json"), '{"planning_version": "2.0"}')
    ecrire(os.path.join(ext, "notes.md"), "n")
    chemin = os.path.join(lab, "sous", ".planning") if imbrique else os.path.join(lab, ".planning")
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    os.symlink(ext, chemin)
    return lab, ext


def sc_planning_lien(script, imbrique=False):
    lab, ext = lab_planning_lien(unique("lab-pl"), imbrique)
    avant = empreinte_arbre(ext)
    r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), reel=True, script=script)
    return {"rc": r.rc, "refus": "lien symbolique dont la cible sort du lab" in r.err, "rien_joue": r.rapport == "", "ext_intact": empreinte_arbre(ext) == avant,
            "vert": "EMPREINTE-ARBRE-IDENTIQUE" in r.rapport and "MESURE-VIDE" not in r.rapport and r.rc == 0}


def sc_mesure_vide(script):
    lab = fabriquer_lab(unique("lab-mv"), {"src/a.txt": "a"}, config=None)
    r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), reel=True, script=script)
    return {"rc": r.rc, "signal": "MESURE-VIDE" in r.rapport and "MESURE-VIDE" in r.out and "ce n'est pas un vert" in r.err,
            "vert": "EMPREINTE-ARBRE-IDENTIQUE" in r.rapport and r.rc == 0}


def sec_lotc(_):
    """R-REEL-PLANNING-LIEN, R-REEL-MESURE-VIDE (lot C, F1)."""
    fautes = []
    for nom, imbrique in (("racine", False), ("imbriqué", True)):
        o = sc_planning_lien(REEL, imbrique)
        if not (o["rc"] == 1 and o["refus"] and o["rien_joue"] and o["ext_intact"] and not o["vert"]):
            fautes.append("`.planning` %s en lien sortant : attendu code 1, refus nominatif, rapport non créé, extérieur intact, aucun vert ; obtenu %s" % (nom, o))
    if fautes:
        for f in fautes:
            ko("R-REEL-PLANNING-LIEN", "un `.planning` du lab qui est un lien vers l'extérieur est refusé avant tout rejeu", "code 1, rien joué", f)
    else:
        ok("R-REEL-PLANNING-LIEN `.planning` du lab (racine ou imbriqué) en lien vers l'extérieur : code 1, message nominatif, rapport non créé, dossier extérieur intact, jamais un vert vide")
    # témoin : un `.planning` en lien vers un dossier DU lab n'est pas refusé
    lab = fabriquer_lab(unique("lab-pli"), {"vrai/config.json": '{"planning_version": "2.0"}', "vrai/notes.md": "n"}, config=None)
    os.symlink("vrai", os.path.join(lab, ".planning"))
    r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), reel=True)
    # la copie ne suit pas un `.planning` en lien : rien n'est mesuré, et c'est dit (MESURE-VIDE, code 1), jamais un vert
    if "lien symbolique dont la cible sort du lab" not in r.err and r.rc == 1 and "MESURE-VIDE" in r.rapport:
        ok("R-REEL-PLANNING-LIEN témoin : `.planning` lien vers un dossier DU lab : pas de refus de lien sortant ; rien de mesuré, signalé MESURE-VIDE (code 1)")
    else:
        ko("R-REEL-PLANNING-LIEN témoin", "pas de sur-refus d'un lien interne, et rien de mesuré est dit", "pas de refus sortant, MESURE-VIDE, code 1", "rc=%d err=%s" % (r.rc, court(r.err)))
    o = sc_mesure_vide(REEL)
    if o["rc"] == 1 and o["signal"] and not o["vert"]:
        ok("R-REEL-MESURE-VIDE un lab sans aucune ligne mesurée : MESURE-VIDE au rapport et à la sortie, message « ce n'est pas un vert », code 1")
    else:
        ko("R-REEL-MESURE-VIDE", "zéro ligne mesurée signalée, jamais lue comme un vert", "code 1, MESURE-VIDE", str(o))
    lab = fabriquer_lab(unique("lab-mvt"), {".planning/notes.md": "n"})
    r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), reel=True)
    if r.rc == 0 and "MESURE-VIDE" not in r.rapport and "MESURE-VIDE" not in r.out:
        ok("R-REEL-MESURE-VIDE témoin : un lab qui porte des lignes mesurées : code 0, aucune MESURE-VIDE")
    else:
        ko("R-REEL-MESURE-VIDE témoin", "pas de signal sur un lab mesuré", "code 0", "rc=%d rapport=%s" % (r.rc, court(r.rapport)))


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

    def sc_reel_lien_lab(dossier_reel):
        reel = fabriquer_lab(unique("lab-mk"), {".planning/notes.md": "n", "code.txt": "c"})
        lien = os.path.join(HOME, unique("lien-mk"))
        os.symlink(reel, lien)
        sub = substitut(unique("sub") + ".sh", 'open(%r, "a").write("mutated")' % os.path.join(reel, "code.txt"))
        r = rejeu([lien], hook=sub, reel=True, script=dossier_reel)
        return {"rc": r.rc, "divergent": "EMPREINTE-ARBRE-DIVERGENTE" in r.rapport}

    def sc_reel_rapport(dossier_reel):
        lab = fabriquer_lab(unique("lab-mq"), {".planning/notes.md": "n"})
        sub = substitut(unique("sub") + ".sh", SUB_PASSE)
        r = rejeu([lab], hook=sub, reel=True, rapport=False, extra=["--rapport=" + os.path.join(lab, "rapport-dedans.txt")], script=dossier_reel)
        return {"rc": r.rc, "avant_mesure": r.err.startswith("[rejeu-reel] le rapport ne peut pas")}

    def sc_reel_usage(dossier_reel):
        lab = fabriquer_lab(unique("lab-mu"), {".planning/notes.md": "n"})
        rap = os.path.join(WORK, unique("rapport") + ".txt")
        p = subprocess.run(["bash", dossier_reel, "--lab=" + lab, "--rapport=" + rap],
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env_sain(), timeout=600)
        return {"rc": p.returncode, "lignes": b"EMPREINTE-ARBRE" in p.stdout, "rapport": os.path.exists(rap)}

    def sc_reel_signature(dossier_reel):
        """Trois gestes, chacun sur son lab : `touch` seul, mode seul, contenu changé à mtime restauré."""
        gestes = {
            "touch": 'os.utime(%r, None)',
            "mode": 'os.chmod(%r, 0o600)',
            "contenu": 'open(%r, "w").write("bbbb")\nos.utime(%r, ns=(10**18, 10**18))',  # mtime constant : le hook peut tourner en concurrence, la dernière opération est toujours la restauration
        }
        res = {}
        for nom, code in gestes.items():
            lab = fabriquer_lab(unique("lab-ms"), {".planning/notes.md": "n", "src/f.txt": "aaaa"})
            f = os.path.join(lab, "src", "f.txt")
            os.chmod(f, 0o644)
            os.utime(f, ns=(1000000000 * 10**9, 1000000000 * 10**9))
            corps = code % ((f,) * code.count("%r"))
            r = rejeu([lab], hook=substitut(unique("sub") + ".sh", corps), reel=True, script=dossier_reel)
            res[nom] = "DIVERGENTE" if "EMPREINTE-ARBRE-DIVERGENTE" in r.rapport else "IDENTIQUE"
        return res

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
    def sc_scripts(script):
        r = scenario_scripts_g6(script=script)
        return {"lignes": sorted(l[2] for l in r.lignes if l[2].startswith(".claude/")), "G6": r.compte.get("G6")}

    duel("REJEU-SCRIPTS-G6", REJEU, G, "# rejeu-scripts-g6", 'if False:  # rejeu-scripts-g6',
         sc_scripts, lambda o, m: len(o["lignes"]) == 2 and o["G6"] == (0, 0, 0) and m["lignes"] == [],
         "R-REJEU-10 : le constructeur G6 ne joue plus les scripts du hook")
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
         "R-REEL-02 : comparaison d'empreinte de rejeu-reel.sh toujours égale", compagnons=(REJEU, RECALC))
    duel("REEL-PERIMETRE", REEL, R, "# reel-perimetre", 'SOUS_ARBRES = [".planning", ".claude"]  # reel-perimetre',
         sc_reel_cmp, lambda o, m: o["divergent"] and not m["divergent"],
         "R-REEL-02 : empreinte limitée à .planning/ et .claude/", compagnons=(REJEU, RECALC))
    duel("REEL-LIENS", REEL, R, "# reel-lstat", "st = os.stat(chemin)  # reel-lstat",
         sc_reel_liens, lambda o, m: (not o["divergent"]) and m["divergent"],
         "R-REEL-03 : liens suivis", compagnons=(REJEU, RECALC))
    duel("REEL-REALPATH", REEL, R, "# reel-realpath", "reels = list(labs)  # reel-realpath",
         sc_reel_lien_lab, lambda o, m: o["rc"] == 1 and o["divergent"] and m["rc"] == 0 and not m["divergent"],
         "R-REEL-05 : racine du lab non résolue (un --lab lien symbolique rend IDENTIQUE alors que le lab a changé)", compagnons=(REJEU, RECALC))
    duel("REEL-RAPPORT", REEL, R, "# reel-rapport", "if False:  # reel-rapport",
         sc_reel_rapport, lambda o, m: o["rc"] == 64 and o["avant_mesure"] and not m["avant_mesure"],
         "R-REEL-06 : refus du rapport sous un lab retiré (il n'est plus émis avant toute mesure)", compagnons=(REJEU, RECALC))
    duel("REEL-REFUS64", REEL, R, "# reel-refus64", "if False:  # reel-refus64",
         sc_reel_usage, lambda o, m: o["rc"] == 64 and not o["lignes"] and not o["rapport"] and (m["lignes"] or m["rapport"]),
         "R-REEL-07 : lignes EMPREINTE-ARBRE-* écrites alors que rejeu-gates.sh a refusé l'usage", compagnons=(REJEU, RECALC))
    duel("REEL-PLANNING-LIEN", REEL, R, "# reel-planning-lien", "if False:  # reel-planning-lien",
         sc_planning_lien, lambda o, m: o["refus"] and not m["refus"],
         "F1 : un `.planning` en lien vers l'extérieur n'est plus refusé", compagnons=(REJEU, RECALC))
    duel("REEL-PLANNING-LIEN-IMBRIQUE", REEL, R, "# reel-planning-lien", "if parts == [\".planning\"]:  # reel-planning-lien",
         lambda script: sc_planning_lien(script, True), lambda o, m: o["refus"] and not m["refus"],
         "F1 : seul le `.planning` de la racine est refusé, un `.planning` imbriqué en lien sortant passe", compagnons=(REJEU, RECALC))
    duel("REEL-MESURE-VIDE", REEL, R, "# reel-mesure-vide", "for lab in []:  # reel-mesure-vide",
         sc_mesure_vide, lambda o, m: o["rc"] == 1 and o["signal"] and m["vert"],
         "F1 : une mesure à zéro ligne est lue comme un vert", compagnons=(REJEU, RECALC))
    def sc_g6g5(script):
        r, _ = scenario_g6g5(script)
        return {"G6": r.compte.get("G6"), "etape": r.etape}

    duel("REJEU-G6-ENREGISTRE", REJEU, G, "# rejeu-registre",
         'CONSTRUCTEURS = {"reecriture": construire_reecriture, "G5": construire_g5, "G1": construire_g1, "G7": construire_g7}  # rejeu-registre',
         sc_g6g5, lambda o, m: o["G6"] == (0, 0, 0) and o["etape"] == (0, 0, 0) and m["G6"] is not None and m["G6"][0] > 0,
         "R-REJEU-G6G5 : constructeur G6 retiré du registre (STATE.md compte en doit-passer et le hook armé le refuse : faux-refus)", compagnons=(RECALC,))
    duel("REJEU-ETAPE", REJEU, G, "# rejeu-etape", "if False:  # rejeu-etape",
         etape_g1, lambda o, m: o["g1-etape1"] == ATTENDU_ETAPE["g1-etape1"] and m["g1-etape1"][2] == (0, 1, 0),
         "R-REJEU-ETAPE : la somme reprend tous les gates (un gate d'étape > n, simulé en observe, compte en faux accept)")
    duel("REJEU-ETAPE-LISTE", REJEU, G, "# rejeu-etape",
         'if gate not in [g for lot in ORDRE_ETAPES[:opts["etape"]] for g in lot]:  # rejeu-etape',
         etape_sans_etape, lambda o, m: o["gate-tiret"] == ATTENDU_ETAPE["gate-tiret"] and o["gate-interrogation"] == ATTENDU_ETAPE["gate-interrogation"]
         and m["gate-tiret"][1] == (0, 0, 0) and m["gate-interrogation"][2] == (0, 0, 0),
         "R-REJEU-ETAPE : la somme devient une liste blanche des gates d'étapes connues (les lignes `-` et `?` ne comptent plus)")

    # --- 45-06 : constructeur G1 ---
    def sc_g1_modele(script):
        lab = lab_g1_modele(unique("lab-mgm"))
        r = rejeu([lab], hook=sub_g1(unique("sub") + ".sh", ("/03-clos/",)), etape=2, scenario="", script=script)
        return {"G1": r.compte.get("G1")}

    def sc_g1_classe(script):
        lab = lab_g1_classe(unique("lab-mgc"))
        r = rejeu([lab], hook=HOOK, etape=2, script=script)
        return {"G1": r.compte.get("G1"), "classe": r.classe.get(("G1", "~/" + os.path.basename(lab)))}

    def sc_conc(selection):
        def scenario(script):
            mesure = mesurer_cellules(script, selection, substitut(unique("sub") + ".sh", SUB_PASSE))
            return {"divergences": len(divergences_relevee(mesure)), "n": sum((v[2] or 0) for v in mesure.values())}
        return scenario

    MODELE_DERIVE = ('attendu = "doit-refuser-modele" if jouer(ctx["hook_copie"], {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": os.environ.get("HOME", ""), '
                     '"TMPDIR": ctx["tmp"], "XDG_CACHE_HOME": os.path.join(ctx["tmp"], "xdg")}, lab, "Write", rel, "")[0] == "refus" else "doit-passer"  # g1-derive')
    duel("REJEU-G1-MODELE", REJEU, G, "# g1-derive", MODELE_DERIVE, sc_g1_modele,
         lambda o, m: o["G1"] == (1, 0, 3) and m["G1"] == (0, 0, 4),
         "R-REJEU-G1 : le constructeur G1 classe d'après le refus obtenu du hook (la phase à CADRAGE.md clos que le substitut refuse est rangée en conforme)", compagnons=(RECALC,))
    duel("REJEU-G1-COMPTE", REJEU, G, "# rejeu-modele-compte", 'return "faux-refus" if obtenu == "refus" else "faux-accept"  # rejeu-modele-compte',
         sc_g1_modele, lambda o, m: o["G1"] == (1, 0, 3) and m["G1"] == (4, 0, 0),
         "R-REJEU-G1 : les refus conformes au modèle comptés en faux refus", compagnons=(RECALC,))
    duel("REJEU-G1-REGLE", REJEU, G, "# g1-regle", 'sortie.append(("Write", rel, "doit-passer", ""))  # g1-regle',
         lambda s: (sc_g1_classe(s), sc_conc(lambda c: c[0] == "sans" and c[1] == "conforme" and c[2] in ("absent", "ouvert") and c[3] == "non")(s)),
         lambda o, m: o[0]["G1"] == (0, 0, 2) and o[0]["classe"] == 4 and o[1]["divergences"] == 0 and m[0]["G1"][0] == 2 and m[0]["classe"] == 0 and m[1]["divergences"] == 2,
         "R-REJEU-G1 et R-REJEU-G1-CONCORDANCE : l'axe cycle — le constructeur retombe sur doit-passer quand l'état dérivé manque (D et E deviennent des faux refus, n=0, les cellules sans CYCLE.md divergent)", compagnons=(RECALC,))
    duel("REJEU-G1-NOM", REJEU, G, "# g1-forme", "if False:  # g1-forme",
         sc_conc(lambda c: c[1] == "hors" and c[2] in ("absent", "ouvert") and c[3] == "non"),
         lambda o, m: o["divergences"] == 0 and m["divergences"] >= 1,
         "R-REJEU-G1-CONCORDANCE : l'axe nom de phase — la règle écrite classe aussi les phases hors NOM_UNITE", compagnons=(RECALC,))
    duel("REJEU-G1-HERITE", REJEU, G, "# g1-herite", 'return ("doit-refuser-modele", "registre-ouvert")  # g1-herite',
         sc_conc(lambda c: c[1] == "conforme" and c[2] == "herite" and c[3] == "non"),
         lambda o, m: o["divergences"] == 0 and m["divergences"] >= 1,
         "R-REJEU-G1-CONCORDANCE : l'axe CADRAGE.md — un format hérité lu « ouvert » par la règle écrite", compagnons=(RECALC,))
    duel("REJEU-G1-VIDE", REJEU, G, "# g1-clos", 'ouvert = not clos or donnees.get("inconnues") == []  # g1-clos',
         sc_conc(lambda c: c[1] == "conforme" and c[2] == "vide" and c[3] == "non"),
         lambda o, m: o["divergences"] == 0 and m["divergences"] >= 1,
         "R-REJEU-G1-CONCORDANCE : `inconnues: []` lu « ouvert » par la règle écrite", compagnons=(RECALC,))
    duel("REJEU-G1-NONREG", REJEU, G, "# g1-nonreg", 'return ("doit-refuser-modele", "pas-de-cadrage")  # g1-nonreg',
         sc_conc(lambda c: c[1] == "conforme" and c[2] in ("dossier", "lien") and c[3] == "non"),
         lambda o, m: o["divergences"] == 0 and m["divergences"] >= 1,
         "R-REJEU-G1-CONCORDANCE : un CADRAGE.md non régulier (dossier ou lien) lu « absent » par la règle écrite", compagnons=(RECALC,))
    # --- 45-07 : constructeur G7 ---
    def sc_g7_remise(script):
        r, aff = scenario_g7(script, 3)
        return {"rc": r.rc, "G7": r.compte.get("G7"), "erreur": "copie non remise en place" in r.err, "lignes": len(lignes_g7(r, aff))}

    def sc_g7_trace(script):
        rt, trace = trace_g7(script)
        return {"rc": rt.rc, "absents": sorted(set(l[0] for l in trace if l[1] == "0" or l[2] == "0")), "payloads": len(trace)}

    duel("REJEU-G7-REMISE", REJEU, G, "# rejeu-remise", "pass  # rejeu-remise",
         lambda s: (sc_g7_remise(s), sc_g7_trace(s)),
         lambda o, m: o[0]["rc"] == 0 and o[0]["G7"] == (0, 0, 1) and o[0]["lignes"] == 5 and m[0]["rc"] == 1 and m[0]["erreur"] and o[1]["rc"] == 0 and m[1]["rc"] == 1,
         "R-REJEU-G7 : le .planning/ imbriqué mis de côté n'est pas remis en place sur la copie (erreur de l'outil, aucun relevé)", compagnons=(RECALC,))
    duel("REJEU-G7-COTE", REJEU, G, "# rejeu-cote", "if False:  # rejeu-cote",
         sc_g7_trace, lambda o, m: o["rc"] == 0 and o["absents"] == ["habite/.planning/config.json", "zone/nu/.planning/config.json"] and m["absents"] == [],
         "R-REJEU-G7 : le .planning/ imbriqué n'est pas mis de côté avant le jeu (le hook voit un .planning/ existant)", compagnons=(RECALC,))
    # --- 45-09 : constructeur ROLE ---
    def sc_role(script):
        r, aff = scenario_role(script, 4)
        return {"rc": r.rc, "ROLE": r.compte.get("ROLE"), "etape": r.etape}

    duel("REJEU-ROLE-LEGITIME", REJEU, G, "# role-legitime",
         'sortie.append(("Agent", sous, "doit-refuser" if classe["role"] == "worker" else "doit-passer", nom))  # role-legitime',
         sc_role, lambda o, m: o["rc"] == 0 and o["ROLE"] == (0, 0, 0) and o["etape"] == (0, 0, 0) and m["ROLE"] != o["ROLE"],
         "R-REJEU-ROLE : la légitimité d'un dispatch jugée par le rôle au lieu de l'allowlist (le dispatch de la propre allowlist du worker devient doit-refuser)", compagnons=(RECALC,))
    tout = {"touch": "DIVERGENTE", "mode": "DIVERGENTE", "contenu": "DIVERGENTE"}
    duel("REEL-MTIME", REEL, R, "# reel-signature",
         'lignes.append((rel or ".", "%s\\t%s\\t%o\\t%d\\t%s" % (rel or ".", genre, stat.S_IMODE(mode), 0, sig)))  # reel-signature',
         sc_reel_signature, lambda o, m: o == tout and m == dict(tout, touch="IDENTIQUE"),
         "R-REEL-08 : mtime_ns retiré de la signature (un touch seul n'est plus vu)", compagnons=(REJEU, RECALC))
    duel("REEL-MODE", REEL, R, "# reel-signature",
         'lignes.append((rel or ".", "%s\\t%s\\t%o\\t%d\\t%s" % (rel or ".", genre, 0, st.st_mtime_ns, sig)))  # reel-signature',
         sc_reel_signature, lambda o, m: o == tout and m == dict(tout, mode="IDENTIQUE"),
         "R-REEL-08 : mode retiré de la signature (un chmod seul n'est plus vu)", compagnons=(REJEU, RECALC))
    duel("REEL-SHA", REEL, R, "# reel-sha", 'sig = "x"  # reel-sha',
         sc_reel_signature, lambda o, m: o == tout and m == dict(tout, contenu="IDENTIQUE"),
         "R-REEL-08 : sha256 retiré de la signature (un contenu changé à mtime restauré n'est plus vu)", compagnons=(REJEU, RECALC))
    # --- Quick 45-B : H3 (liens), B2 (relevé), B3 (profondeur) ---
    def sc_lien_ecriture(script):
        lab, ext = lab_ext(unique("lab-ml"), ".planning/cycles", False, False)
        avant = empreinte_arbre(ext)
        r = rejeu([lab], hook=HOOK, etape=2, script=script)
        return {"rc": r.rc, "ext_intact": empreinte_arbre(ext) == avant}

    def sc_lien_agents(script):
        lab, ext = lab_ext(unique("lab-ma"), ".claude/agents", False, False)
        os.makedirs(ext, exist_ok=True)
        r = rejeu([lab], hook=HOOK, etape=4, script=script)
        return {"rc": r.rc}

    def sc_lien_lecture(script):
        lab = fabriquer_lab(unique("lab-mr"), {".planning/notes.md": "NOTE-INTERNE"})
        os.symlink("notes.md", os.path.join(lab, ".planning", "STATE.md"))
        trace = os.path.join(WORK, unique("trace") + ".txt")
        sub = substitut(unique("sub-trace") + ".sh", 'if chemin.endswith("/.planning/STATE.md"): open(%r, "a").write(str(ti.get("content")) + "\\n")' % trace)
        rejeu([lab], hook=sub, scenario="g6-state", script=script)
        return {"lu": open(trace, encoding="utf-8").read() if os.path.exists(trace) else None}

    def sc_lien_reel(script):
        lab, ext = lab_ext(unique("lab-mlr"), ".planning/STATE.md", False, False)
        marque = os.path.join(WORK, unique("marque") + ".txt")
        sub = substitut(unique("sub-marque") + ".sh", 'open(%r, "w").write("joue")' % marque)
        r = rejeu([lab], hook=sub, reel=True, script=script)
        return {"rc": r.rc, "joue": os.path.exists(marque)}

    duel("REJEU-GARDE-LIEN", REJEU, G, "# rejeu-garde-lien", "if False:  # rejeu-garde-lien",
         sc_lien_ecriture, lambda o, m: o == {"rc": 1, "ext_intact": True} and m["ext_intact"] is False,
         "H3 : la garde « la cible résolue reste sous la copie » retirée (le rejeu écrit dans le dossier extérieur par un lien)", compagnons=(RECALC,))
    duel("REJEU-LECTURE-REGULIER", REJEU, G, "# rejeu-lecture-regulier", "if False:  # rejeu-lecture-regulier",
         sc_lien_lecture, lambda o, m: o == {"lu": "x\n"} and m["lu"] != "x\n",
         "H3 : le payload ne vérifie plus que le fichier lu est régulier (STATE.md en lien interne : son contenu est lu)", compagnons=(RECALC,))
    duel("REJEU-AGENTS-LIEN", REJEU, G, "# rejeu-agents-lien", "pass  # rejeu-agents-lien",
         sc_lien_agents, lambda o, m: o["rc"] == 1 and m["rc"] == 0,
         "H3 : .claude/agents en lien vers l'extérieur n'est plus refusé (le dossier extérieur est lu)", compagnons=(RECALC,))
    duel("REEL-LIEN-SORTANT", REEL, R, "# reel-lien-sortant", "if False:  # reel-lien-sortant",
         sc_lien_reel, lambda o, m: o == {"rc": 1, "joue": False} and m["joue"] is True,
         "H3 : rejeu-reel.sh ne refuse plus un lien sortant avant le rejeu (le hook est joué)", compagnons=(REJEU, RECALC))
    duel("REJEU-GENERIQUE", REJEU, G, "# rejeu-generique", "return p  # rejeu-generique",
         lambda s: sc_hors_home(s, False), lambda o, m: o["rc"] == 0 and not o["absolu"] and m["absolu"],
         "B2 : un lab hors de HOME est de nouveau affiché par son chemin absolu", compagnons=(RECALC,))
    duel("REEL-GENERIQUE", REEL, R, "# reel-generique", "return p  # reel-generique",
         lambda s: sc_hors_home(s, True), lambda o, m: o["rc"] == 0 and not o["absolu"] and m["absolu"],
         "B2 : rejeu-reel.sh affiche de nouveau le chemin absolu d'un lab hors de HOME", compagnons=(REJEU, RECALC))
    duel("REJEU-NEUTRALISER", REJEU, G, "# rejeu-neutraliser", "return texte  # rejeu-neutraliser",
         lambda s: sc_lf(s, False), lambda o, m: o["rc"] == 0 and not o["forge"] and o["echappe"] and m["forge"],
         "B2 : les caractères de contrôle d'un nom ne sont plus échappés (une ligne COMPTE est forgée par un nom de fichier)", compagnons=(RECALC,))
    duel("REEL-NEUTRALISER", REEL, R, "# reel-neutraliser", "return texte  # reel-neutraliser",
         lambda s: sc_lf(s, True), lambda o, m: o["rc"] == 0 and not o["forge"] and o["echappe"] and m["forge"],
         "B2 : rejeu-reel.sh n'échappe plus les caractères de contrôle d'un nom de lab", compagnons=(REJEU, RECALC))
    duel("REJEU-RECURSION", REJEU, G, "# rejeu-recursion", "except ZeroDivisionError:  # rejeu-recursion",
         sc_prof_gates, lambda o, m: o == {"rc": 1, "message": True, "trace": False} and m["trace"] and not m["message"],
         "B3 : la RecursionError de rejeu-gates.sh n'est plus rattrapée (trace Python au lieu du message)", compagnons=(RECALC,))
    if casse_insensible():
        duel("REEL-SAMEFILE", REEL, R, "# reel-samefile", "if False:  # reel-samefile",
             lambda s: sc_casse(s, True), lambda o, m: o["rc"] == 64 and not o["cree"] and o["refus_par"] == "[rejeu-reel" and m["refus_par"] == "[rejeu-gates",
             "B2 : l'identité de fichier n'est plus comparée par rejeu-reel.sh (le refus ne vient plus de lui mais de rejeu-gates.sh, après le début du geste)", compagnons=(REJEU, RECALC))
    else:
        ok("MUT-REEL-SAMEFILE non applicable ici : système de fichiers sensible à la casse (le mutant n'y est pas opposable)")
    pmax = os.pathconf(HOME, "PC_PATH_MAX")
    if len(os.path.join(HOME, "x", "src") + "/d" * 1600) > pmax:
        def sc_prof_reel_reel(script):
            lab = arbre_profond(unique("lab-mpr"), 1600)
            try:
                r = rejeu([lab], hook=substitut(unique("sub") + ".sh", SUB_PASSE), reel=True, script=script)
                return {"rc": r.rc, "trace": "Traceback" in r.err}
            finally:
                try:
                    os.chdir(os.path.join(lab, "src"))
                    n = 0
                    while os.path.isdir("d") and n < 1600:
                        os.chdir("d")
                        n += 1
                    for _ in range(n):
                        os.chdir("..")
                        os.rmdir("d")
                except OSError:
                    pass
                finally:
                    os.chdir("/")
        duel("REEL-PROFONDEUR", REEL, R, "# reel-profondeur", "except ZeroDivisionError:  # reel-profondeur",
             sc_prof_reel_reel, lambda o, m: o == {"rc": 1, "trace": False} and m["trace"],
             "B3 : l'erreur système d'un chemin plus long que PATH_MAX n'est plus rattrapée par rejeu-reel.sh (trace Python)", compagnons=(REJEU, RECALC))
    else:
        ok("MUT-REEL-PROFONDEUR non applicable ici : PATH_MAX (%d) dépasse la longueur d'un arbre de 1 600 niveaux, l'erreur système n'y est pas atteinte" % pmax)


SECTIONS = {
    "sens": sec_sens,
    "reel_hook": sec_reel_hook,
    "priorite": sec_priorite,
    "modele": sec_modele,
    "etape": sec_etape,
    "g6g5": sec_g6g5,
    "g1": sec_g1,
    "g7": sec_g7,
    "role": sec_role,
    "concordance": sec_concordance,
    "statique": sec_statique,
    "reel": sec_reel,
    "liens": sec_liens,
    "lotc": sec_lotc,
    "releve": sec_releve,
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
  run_sections sens,reel_hook,priorite,modele,etape,g6g5,g1,g7,role,concordance,statique,reel,liens,lotc,releve,mutants
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
