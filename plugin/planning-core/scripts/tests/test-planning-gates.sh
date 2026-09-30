#!/usr/bin/env bash
# test-planning-gates.sh — sémantique des gates du hook central (Phase 45, 45-01 ; GATE-08, GATE-10,
# GATE-15) : table d'armement, contrôle croisé du parseur, G2 (avertit, jamais ne refuse), banc des
# écritures. Le hook est rejoué PAR LA COMMANDE ENREGISTRÉE (lue dans hooks.json), jamais par un appel
# direct au script (P45-D-20) ; la couche shell de cette commande a sa propre suite
# (test-planning-hook-registered.sh).
#
# Familles :
#   R-TABLE-01..03  la table d'armement vit dans le code livré (constantes ARMEMENT_*, tout à observe),
#                   armement_valide refuse un ordre violé, une table incohérente refuse (deny)
#   R-PARSEUR       lire_frontmatter du hook est ast-identique à celle du moteur de recalcul
#   R-G2-01..07     G2 avertit par additionalContext (jamais permissionDecision), référentiel = union
#                   des ecrit: des plans ouverts, se tait hors d'un lab adhérent ; R-G2-PERF
#   R-ENV-01        aucune variable d'environnement ne change l'armement ni l'adhésion (P45-D-12a)
#   R-ACCORD        chemin relatif : avertissement G2 en mode A <=> deny en mode C (limite h)
#   BANC            chaque `@@ ecriture` de fixtures/gates-banc.txt rend son attendu ; COUVERTURE
#   MUT-*           chaque garde est tuée par un mutant à motif unique dont la trace est imprimée
#
# Tous les cas de gate tournent sur l'état livré ; les cas qui exigent l'armement FORCÉ tournent sur
# une copie du script dont les constantes ARMEMENT_* valent `armed`, jamais sur l'état livré.
#
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; `cmp -s`
# jamais `diff` ; tout le travail fin est fait par Python (PYBIN). Lançable depuis tout cwd.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
HOOK="$SCRIPTS_DIR/planning-hook.sh"
RECALC="$SCRIPTS_DIR/recalc-planning.sh"
BANC="$TESTS_DIR/fixtures/gates-banc.txt"
HOOKS_JSON="$SCRIPTS_DIR/../hooks/hooks.json"
SETTINGS_LAB="$SCRIPTS_DIR/../settings.json"
[ -f "$HOOKS_JSON" ] || HOOKS_JSON=""
[ -f "$SETTINGS_LAB" ] || SETTINGS_LAB=""

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-planning-gates] python3 requis" >&2; exit 1; fi
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
T_DEBUT="$(date +%s)"

AIDES="$WORK/aides.py"
cat > "$AIDES" <<'PY_AIDES_GATES_EOF'
import ast
import json
import os
import re
import shutil
import subprocess
import sys
import time

TOKEN = "{{VF_SCRIPTS}}"
OUTILS_BANC = ("Write", "Edit", "NotebookEdit", "Bash")
# Table d'armement ATTENDUE de l'état livré : chaque armement d'une étape (45-05 à 45-09) met à
# jour la constante du script ET cette table dans le MÊME commit (R-TABLE-01).
TABLE_ATTENDUE = {"G6": "observe", "G5": "observe", "G1": "observe", "G7": "observe", "ROLE": "observe"}
ORDRE_ATTENDU = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",))


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


def court(octets, n=200):
    texte = octets.decode("utf-8", "replace") if isinstance(octets, bytes) else str(octets)
    texte = texte.replace("\n", "\\n")
    return texte if len(texte) <= n else texte[:n] + "…(+" + str(len(texte) - n) + ")"


# --- Payload du harnais (Claude Code 2.1.284, mesuré) ----------------------------------------
def payload(outil, entree, cwd, agent_type=None, agent_id="agent-test"):
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd,
           "prompt_id": "prompt-test", "permission_mode": "default"}
    if agent_type is not None:
        obj["agent_id"] = agent_id
        obj["agent_type"] = agent_type
    obj["hook_event_name"] = "PreToolUse"
    obj["tool_name"] = outil
    obj["tool_input"] = entree
    obj["tool_use_id"] = "toolu_test"
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def entree_outil(outil, chemin, commande=None):
    if outil == "Bash":
        return {"command": commande if commande is not None else "true"}
    if outil == "NotebookEdit":
        return {"notebook_path": chemin, "new_source": "x"}
    if outil == "Edit":
        return {"file_path": chemin, "old_string": "a", "new_string": "b"}
    return {"file_path": chemin, "content": "x"}


def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)


# --- Contexte : la commande enregistrée, modes A (script réel) et C (script absent) ------------
class Ctx:
    def __init__(self, scripts_dir, hooks_json, work, settings_lab):
        self.scripts_dir = scripts_dir
        self.hooks_json = hooks_json
        self.work = work
        self.settings_lab = settings_lab
        self.hook = os.path.join(scripts_dir, "planning-hook.sh")
        self.recalc = os.path.join(scripts_dir, "recalc-planning.sh")
        self.home = os.path.join(work, "home")
        os.makedirs(self.home, exist_ok=True)
        os.makedirs(os.path.join(work, "modeC"), exist_ok=True)
        self._n = 0
        self.cmd = None
        self._armee = None

    def unique(self, prefixe):
        self._n += 1
        return os.path.join(self.work, prefixe + "-" + str(self._n))

    def charger_commande(self):
        source = self.hooks_json or self.settings_lab
        if not source:
            return None
        d = json.load(open(source, encoding="utf-8"))
        cands = [h["command"] for g in d.get("hooks", {}).get("PreToolUse", []) for h in g.get("hooks", [])
                 if "planning-hook.sh" in h.get("command", "")]
        if len(cands) != 1:
            return None
        self.cmd = cands[0]
        return self.cmd

    def env(self, extra=None):
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.home}
        if os.environ.get("TMPDIR"):
            env["TMPDIR"] = os.environ["TMPDIR"]
        if extra:
            env.update(extra)
        return env

    def lancer(self, mode, entree, cwd=None, dossier=None, extra_env=None):
        """Rejoue la commande enregistrée TELLE QUELLE sous /bin/sh -c. Mode A : script du dossier
        donné (défaut : le script réel) ; mode C : dossier de scripts vide."""
        d = os.path.join(self.work, "modeC") if mode == "C" else (dossier or self.scripts_dir)
        if TOKEN in self.cmd:
            texte, extra = self.cmd.replace(TOKEN, "'" + d + "'"), {}
        else:
            proj = self.unique("proj")
            os.makedirs(os.path.join(proj, ".claude"), exist_ok=True)
            os.symlink(d, os.path.join(proj, ".claude", "scripts"))
            texte, extra = self.cmd, {"CLAUDE_PROJECT_DIR": proj}
        env = self.env(extra)
        if extra_env:
            env.update(extra_env)
        p = subprocess.run(["/bin/sh", "-c", texte], input=entree, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, env=env, cwd=cwd, timeout=120)
        return p.returncode, p.stdout, p.stderr

    def copie_armee(self):
        """Copie du script dont les cinq constantes ARMEMENT_* valent `armed` (armement FORCÉ)."""
        if self._armee is None:
            texte = open(self.hook, encoding="utf-8").read()
            texte, n = re.subn(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE) = )"observe"', r'\1"armed"', texte, flags=re.M)
            d = self.unique("armee")
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
                fh.write(texte)
            os.chmod(os.path.join(d, "planning-hook.sh"), 0o755)
            self._armee = (d, n)
        return self._armee


def classer(rc, out):
    """`silence`, `avertit` (additionalContext sans décision), `deny`, ou `autre:...`."""
    if rc != 0:
        return "autre:rc=%d" % rc
    if out == b"":
        return "silence"
    try:
        obj = json.loads(out.decode("utf-8"))
        s = obj["hookSpecificOutput"]
    except (ValueError, KeyError, TypeError):
        return "autre:document"
    if s.get("hookEventName") != "PreToolUse":
        return "autre:enveloppe"
    if s.get("permissionDecision") == "deny":
        return "deny"
    if "permissionDecision" in s or "permissionDecisionReason" in s:
        return "autre:decision"
    if isinstance(s.get("additionalContext"), str):
        return "avertit"
    return "autre:enveloppe"


def contexte_de(out):
    return json.loads(out.decode("utf-8"))["hookSpecificOutput"].get("additionalContext", "")


# --- Banc texte (grammaire du banc 44 + directive `ecriture`) --------------------------------
def _valider_chemin_banc(chemin):
    if chemin.startswith("/") or chemin.startswith("~") or ".." in chemin.split("/"):
        raise ValueError("chemin refusé par le matérialiseur : " + chemin)


def parser_banc(texte):
    lignes = texte.split("\n")
    if lignes and lignes[-1] == "":
        lignes = lignes[:-1]
    labs, ordre = {}, []
    lab, fichier, contenu = None, None, []

    def clore():
        if lab is not None and fichier is not None:
            labs[lab]["fichiers"][fichier] = "".join(l + "\n" for l in contenu)

    for ligne in lignes:
        if not ligne.startswith("@@ "):
            if fichier is not None:
                contenu.append(ligne)
            continue
        clore()
        fichier, contenu = None, []
        d = ligne[3:]
        if d == "#" or d.startswith("# "):
            continue
        if d.startswith("lab "):
            morceaux = d[4:].split()
            lab = morceaux[0]
            jumeau = None
            for m in morceaux[1:]:
                if m.startswith("jumeau-de="):
                    jumeau = m[len("jumeau-de="):]
            labs[lab] = {"fichiers": {}, "dossiers": [], "liens": [], "ecritures": [], "jumeau_de": jumeau}
            ordre.append(lab)
        elif d.startswith("dossier "):
            chemin = d[8:].strip()
            _valider_chemin_banc(chemin)
            labs[lab]["dossiers"].append(chemin)
        elif d.startswith("fichier "):
            chemin = d[8:].strip()
            _valider_chemin_banc(chemin)
            fichier, contenu = chemin, []
        elif d.startswith("lien "):
            reste = d[5:].strip()
            if " -> " not in reste:
                raise ValueError("directive @@ lien mal formée : " + d)
            chemin, cible = [p.strip() for p in reste.split(" -> ", 1)]
            _valider_chemin_banc(chemin)
            labs[lab]["liens"].append((chemin, cible))
        elif d.startswith("ecriture "):
            labs[lab]["ecritures"].append(_parser_ecriture(d[9:]))
        else:
            raise ValueError("directive de banc inconnue : " + d)
    clore()
    return ordre, labs


def _parser_ecriture(reste):
    if " :: " not in reste:
        raise ValueError("directive @@ ecriture sans ` :: ` : " + reste)
    gauche, droite = reste.split(" :: ", 1)
    att = droite.split()
    if not att or att[0] not in ("doit-passer", "doit-refuser", "avertit", "silence"):
        raise ValueError("attendu inconnu : " + droite)
    e = {"attendu": att[0], "gate": att[1] if len(att) > 1 else None, "agent": None, "cwd": None, "commande": None}
    morceaux = gauche.split(" ", 2)
    e["outil"], e["chemin"] = morceaux[0], morceaux[1]
    if e["outil"] not in OUTILS_BANC:
        raise ValueError("outil de banc inconnu : " + e["outil"])
    if e["chemin"] != "-":
        _valider_chemin_banc(e["chemin"])
    options = morceaux[2] if len(morceaux) > 2 else ""
    while options:
        if options.startswith("commande="):
            e["commande"] = options[len("commande="):]
            break
        jeton, _, options = options.partition(" ")
        if jeton.startswith("agent="):
            e["agent"] = jeton[6:]
        elif jeton.startswith("cwd="):
            e["cwd"] = jeton[4:]
            _valider_chemin_banc(e["cwd"])
        elif jeton:
            raise ValueError("option de banc inconnue : " + jeton)
    return e


def materialiser(labs, nom, destination):
    lab = labs[nom]
    os.makedirs(destination, exist_ok=True)
    for dossier in lab["dossiers"]:
        os.makedirs(os.path.join(destination, dossier), exist_ok=True)
    for chemin, contenu in lab["fichiers"].items():
        ecrire(os.path.join(destination, chemin), contenu)
    for chemin, cible in lab["liens"]:
        os.makedirs(os.path.dirname(os.path.join(destination, chemin)), exist_ok=True)
        os.symlink(cible, os.path.join(destination, chemin))


def entree_de_ecriture(e, racine):
    cwd = os.path.join(racine, e["cwd"]) if e["cwd"] else racine
    chemin = None if e["chemin"] == "-" else os.path.join(racine, e["chemin"])
    return payload(e["outil"], entree_outil(e["outil"], chemin, e["commande"]), cwd, agent_type=e["agent"]), cwd


def juger(attendu, gate, rc, out):
    """(conforme, obtenu) d'une écriture du banc."""
    v = classer(rc, out)
    if attendu == "silence":
        return v == "silence", v
    if attendu == "avertit":
        return (v == "avertit" and (gate is None or gate in contexte_de(out))), v
    if attendu == "doit-refuser":
        return v == "deny", v
    return v in ("silence", "avertit"), v   # doit-passer : aucun refus


# --- Mutants du script (make_hook_mutant) ----------------------------------------------------
def make_hook_mutant(ctx, ident, motif, remplacement):
    """Copie du script dont l'UNIQUE ligne portant `motif` (fixe) est remplacée par `remplacement`
    (indentation conservée). `bash -n` et la compilation du corps Python extrait doivent passer."""
    original = open(ctx.hook, encoding="utf-8").read()
    lignes = original.split("\n")
    idx = [i for i, l in enumerate(lignes) if motif in l]
    if len(idx) != 1 or original.count(motif) != 1:
        return None, "MOTIF AMBIGU OU ABSENT (lignes=%d, occurrences=%d)" % (len(idx), original.count(motif))
    ligne = lignes[idx[0]]
    lignes[idx[0]] = ligne[: len(ligne) - len(ligne.lstrip())] + remplacement
    muté = "\n".join(lignes)
    if muté == original:
        return None, "NON OPPOSABLE (identique)"
    dossier = ctx.unique("mut-" + ident.lower())
    os.makedirs(dossier, exist_ok=True)
    chemin = os.path.join(dossier, "planning-hook.sh")
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(muté)
    os.chmod(chemin, 0o755)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    try:
        compile(corps_python(muté), chemin, "exec")
    except SyntaxError as e:
        return None, "SyntaxError du corps Python : " + str(e)
    return dossier, None


def corps_python(texte, marqueur="PY_PLANNING_HOOK_EOF"):
    corps, dedans = [], False
    for l in texte.split("\n"):
        if l == marqueur:
            dedans = False
        if dedans:
            corps.append(l)
        if l.endswith("<<'" + marqueur + "'"):
            dedans = True
    return "\n".join(corps) + "\n"


def charger_module(chemin_script):
    texte = open(chemin_script, encoding="utf-8").read()
    ns = {"__name__": "hook_core"}
    exec(compile(corps_python(texte), chemin_script, "exec"), ns)
    return ns


def labs_banc(ctx):
    if getattr(ctx, "_labs_banc", None) is None:
        ordre, labs = parser_banc(open(ctx.banc, encoding="utf-8").read())
        racine = ctx.unique("bancs")
        chemins = {}
        for nom in ordre:
            chemins[nom] = os.path.join(racine, nom)
            materialiser(labs, nom, chemins[nom])
        ctx._labs_banc = (ordre, labs, chemins)
    return ctx._labs_banc


# =================================================================================================
# Contrôles (chacun rend (conforme, détail) et s'applique à un script donné : le vrai ou un mutant)
# =================================================================================================
def _dossier(ctx, script):
    return script if script else ctx.scripts_dir


def _ecrire_ok(ctx, script, nom_lab, outil, chemin, agent=None, commande=None, cwd_rel=None):
    _, _, chemins = labs_banc(ctx)
    racine = chemins[nom_lab]
    e = {"outil": outil, "chemin": chemin, "agent": agent, "cwd": cwd_rel, "commande": commande}
    brut, cwd = entree_de_ecriture(e, racine)
    return ctx.lancer("A", brut, cwd=cwd, dossier=_dossier(ctx, script))


def controle_temoin(ctx, script):
    """Témoin : Write d'une cible neutre d'un lab adhérent → silence (aucun mutant ne l'affecte)."""
    rc, out, err = _ecrire_ok(ctx, script, "g2-adherent", "Write", ".planning/notes.md")
    v = classer(rc, out)
    return v == "silence" and not err, v


def controle_g2_01(ctx, script):
    rc, out, err = _ecrire_ok(ctx, script, "g2-adherent", "Write", "livrables/autre.md")
    v = classer(rc, out)
    if v != "avertit":
        return False, v + " " + court(out)
    texte = contexte_de(out)
    manque = [m for m in ("G2", "P45-D-10", "Bash") if m not in texte]
    cles = sorted(json.loads(out.decode("utf-8"))["hookSpecificOutput"].keys())
    if manque or "permissionDecision" in cles:
        return False, "manque %s ; clés %s" % (manque, cles)
    return True, "additionalContext qui nomme G2, P45-D-10 et Bash, sans permissionDecision"


def controle_g2_02(ctx, script):
    fautes = []
    for chemin in ("livrables/rapport.md", ".planning/notes.md", ".claude/agents/x.md", "livrables/suite.md",
                   "livrables/annexe/x.md"):
        rc, out, err = _ecrire_ok(ctx, script, "g2-adherent", "Write", chemin)
        v = classer(rc, out)
        if v != "silence":
            fautes.append("%s -> %s" % (chemin, v))
    return (not fautes), ("; ".join(fautes) if fautes else "silence : déclaré, sous .planning/, sous .claude/, union des plans, dossier couvert")


def controle_g2_03(ctx, script):
    fautes = []
    for chemin in ("livrables/ancien.md", "livrables/gele.md"):
        rc, out, err = _ecrire_ok(ctx, script, "g2-adherent", "Write", chemin)
        v = classer(rc, out)
        if v != "avertit":
            fautes.append("%s -> %s" % (chemin, v))
    return (not fautes), ("; ".join(fautes) if fautes else "avertit : plan clos et plan dérogé ne couvrent rien")


def controle_g2_07(ctx, script):
    fautes = []
    for outil, chemin, cmd in (("Write", "livrables/autre.md", None), ("Edit", "livrables/autre.md", None),
                               ("NotebookEdit", "livrables/nb.ipynb", None), ("Bash", "-", "cat livrables/autre.md")):
        rc, out, err = _ecrire_ok(ctx, script, "g2-dev", outil, chemin, commande=cmd)
        if rc != 0 or out != b"" or err:
            fautes.append("%s -> rc=%d %s" % (outil, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "stdout d'octet vide et code 0 dans un lab dev qui porte un plan ouvert")


def controle_table_02(ctx, script):
    ns = charger_module(script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh"))
    av = ns["armement_valide"]
    o, a = "observe", "armed"

    def T(g6, g5, g1, g7, role):
        return {"G6": g6, "G5": g5, "G1": g1, "G7": g7, "ROLE": role}

    refusees = {"G1 armé sans G6 ni G5": T(o, o, a, o, o), "G6 armé sans G5": T(a, o, o, o, o),
                "G5 armé sans G6": T(o, a, o, o, o), "ROLE armé sans G7": T(a, a, a, o, a),
                "G7 armé sans G1": T(a, a, o, a, o), "valeur inconnue": T("arme", "arme", o, o, o)}
    acceptees = {"tout à observe": T(o, o, o, o, o), "étape 1": T(a, a, o, o, o), "étapes 1-2": T(a, a, a, o, o),
                 "étapes 1-3": T(a, a, a, a, o), "étapes 1-4": T(a, a, a, a, a)}
    fautes = []
    for nom, t in refusees.items():
        if av(t):
            fautes.append("acceptée à tort : " + nom)
    for nom, t in acceptees.items():
        if not av(t):
            fautes.append("refusée à tort : " + nom)
    return (not fautes), ("; ".join(fautes) if fautes else "6 tables rejetées, 5 préfixes de l'ordre acceptés")


def controle_parseur(ctx, script):
    """R-PARSEUR : les arbres ast de lire_frontmatter (et de ses dépendances directes) extraits des deux
    heredocs sont identiques."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    arb_h = _arbres_parseur(corps_python(open(chemin, encoding="utf-8").read()))
    arb_r = _arbres_parseur(corps_python(open(ctx.recalc, encoding="utf-8").read(), "PY_RECALC_PLANNING_EOF"))
    fautes = []
    for nom in ("dequote", "CLE_RE", "lire_frontmatter", "_lire_liste_indentee"):
        if nom not in arb_h or nom not in arb_r:
            fautes.append("absent : " + nom)
        elif arb_h[nom] != arb_r[nom]:
            fautes.append("arbres différents : " + nom)
    return (not fautes), ("; ".join(fautes) if fautes else "4 arbres identiques : dequote, CLE_RE, lire_frontmatter, _lire_liste_indentee")


def _arbres_parseur(corps):
    res = {}
    for noeud in ast.parse(corps).body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name in ("dequote", "lire_frontmatter", "_lire_liste_indentee"):
            res[noeud.name] = ast.dump(noeud)
        elif isinstance(noeud, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "CLE_RE" for t in noeud.targets):
            res["CLE_RE"] = ast.dump(noeud)
    return res


def controle_accord(ctx, script):
    """Limite h : pour chaque forme de chemin relatif, avertissement G2 en mode A <=> deny en mode C."""
    _, _, chemins = labs_banc(ctx)
    fautes = []
    formes = (("Write", "livrables/autre.md"), ("Write", "sub/../livrables/autre.md"), ("NotebookEdit", "livrables/nb.ipynb"))
    for lab, attendu_a, attendu_c in (("g2-adherent", "avertit", "deny"), ("g2-dev", "silence", "silence")):
        racine = chemins[lab]
        for outil, rel in formes:
            brut = payload(outil, entree_outil(outil, rel), racine)
            rc_a, out_a, _e1 = ctx.lancer("A", brut, cwd=racine, dossier=_dossier(ctx, script))
            rc_c, out_c, _e2 = ctx.lancer("C", brut, cwd=racine)
            va, vc = classer(rc_a, out_a), classer(rc_c, out_c)
            if (va, vc) != (attendu_a, attendu_c):
                fautes.append("%s %s %s : mode A %s, mode C %s (attendu %s / %s)" % (lab, outil, rel, va, vc, attendu_a, attendu_c))
    return (not fautes), ("; ".join(fautes) if fautes else "avertissement en mode A <=> deny en mode C sur lab adhérent ; silence des deux côtés sur lab dev")


def controle_env(ctx, scripts):
    """R-ENV-01 : mêmes verdicts, octet pour octet, sous cinq environnements."""
    _, _, chemins = labs_banc(ctx)
    envs = {}
    envs["vide"] = {}
    envs["HOME et XDG_CACHE_HOME fictifs"] = {"HOME": ctx.unique("env-home"), "XDG_CACHE_HOME": ctx.unique("env-cache")}
    for d in envs["HOME et XDG_CACHE_HOME fictifs"].values():
        os.makedirs(d, exist_ok=True)
    proj = ctx.unique("env-proj")
    os.makedirs(os.path.join(proj, ".claude", "scripts"), exist_ok=True)
    shutil.copy(ctx.hook, os.path.join(proj, ".claude", "scripts", "planning-hook.sh"))
    envs["CLAUDE_PROJECT_DIR ailleurs (copie identique)"] = {"CLAUDE_PROJECT_DIR": proj}
    tmp = ctx.unique("env-tmp")
    os.makedirs(tmp, exist_ok=True)
    envs["TMPDIR ailleurs"] = {"TMPDIR": tmp}
    envs["variables hostiles"] = {"VF_SCHEMA_ADHESION": "2.0", "VF_ARMEMENT": "off", "GSD_WORKSTREAM": "hostile"}
    charges = (("adhérent, cible neutre", "g2-adherent", "Write", ".planning/notes.md", "silence"),
               ("adhérent, livrable non déclaré", "g2-adherent", "Write", "livrables/autre.md", "avertit"),
               ("dev", "g2-dev", "Write", "livrables/autre.md", "silence"))
    fautes, n = [], 0
    for script in scripts:
        for etiquette, lab, outil, rel, attendu in charges:
            racine = chemins[lab]
            brut = payload(outil, entree_outil(outil, os.path.join(racine, rel)), racine)
            reference = ctx.lancer("A", brut, cwd=racine, dossier=script)
            if classer(reference[0], reference[1]) != attendu:
                fautes.append("référence %s (%s) : attendu %s, obtenu %s" % (etiquette, os.path.basename(script), attendu, classer(reference[0], reference[1])))
                continue
            for nom, extra in envs.items():
                r = ctx.lancer("A", brut, cwd=racine, dossier=script, extra_env=extra)
                n += 1
                if r != reference:
                    fautes.append("%s sous « %s » : %s au lieu de %s" % (etiquette, nom, classer(r[0], r[1]), attendu))
    return (not fautes), ("; ".join(fautes) if fautes else "%d rejeux sous 5 environnements : verdicts identiques octet pour octet" % n)


# =================================================================================================
# Sections
# =================================================================================================
def sec_table(ctx):
    texte = open(ctx.hook, encoding="utf-8").read()
    corps = corps_python(texte)
    fautes = []
    for gate, valeur in TABLE_ATTENDUE.items():
        motif = re.compile(r'^ARMEMENT_%s = "(observe|armed)"  # etape-[1-4]$' % gate, re.M)
        trouves = motif.findall(corps)
        if len(trouves) != 1:
            fautes.append("ARMEMENT_%s : %d ligne(s)" % (gate, len(trouves)))
        elif trouves[0] != valeur:
            fautes.append("ARMEMENT_%s = %s (attendu %s)" % (gate, trouves[0], valeur))
    for nom in ("phases_trace", '"gates"', "'gates'"):
        if nom in corps:
            fautes.append("le drapeau de config.json %s est cité par le hook (P45-D-01 : aucun code de la 45 ne le lit)" % nom)
    ns = charger_module(ctx.hook)
    if ns.get("G2_MODE") != "avertit":
        fautes.append("G2_MODE = %r" % ns.get("G2_MODE"))
    if ns.get("ORDRE_ETAPES") != ORDRE_ATTENDU:
        fautes.append("ORDRE_ETAPES = %r" % (ns.get("ORDRE_ETAPES"),))
    if not ns["armement_valide"](TABLE_ATTENDUE) or not ns["armement_valide"](ns["TABLE_ARMEMENT"]):
        fautes.append("la table livrée ne passe pas armement_valide")
    if ns["TABLE_ARMEMENT"] != TABLE_ATTENDUE:
        fautes.append("TABLE_ARMEMENT %r != TABLE_ATTENDUE" % (ns["TABLE_ARMEMENT"],))
    if fautes:
        for f in fautes:
            ko("R-TABLE-01", "les cinq constantes ARMEMENT_* (une ligne chacune) valent TABLE_ATTENDUE, G2_MODE vaut avertit, ordre de l'interface",
               "table livrée = table attendue", f)
    else:
        ok("R-TABLE-01 cinq constantes ARMEMENT_* sur une ligne chacune = TABLE_ATTENDUE (tout à observe), G2_MODE avertit, ORDRE_ETAPES conforme, armement_valide vrai")
    bon, detail = controle_table_02(ctx, ctx.hook)
    if bon:
        ok("R-TABLE-02 " + detail)
    else:
        ko("R-TABLE-02", "armement_valide rejette un ordre violé et accepte les préfixes", "6 rejets, 5 acceptations", detail)
    # Table livrée incohérente (G1 armé sans G6 ni G5) : le hook refuse dans un lab adhérent
    d = ctx.unique("incoherente")
    os.makedirs(d, exist_ok=True)
    incoh = re.sub(r'^(ARMEMENT_G1 = )"observe"', r'\1"armed"', texte, count=1, flags=re.M)
    with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
        fh.write(incoh)
    _, _, chemins = labs_banc(ctx)
    racine = chemins["g2-adherent"]
    brut = payload("Write", entree_outil("Write", racine + "/.planning/notes.md"), racine)
    rc, out, err = ctx.lancer("A", brut, cwd=racine, dossier=d)
    raison = ""
    if classer(rc, out) == "deny":
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    if classer(rc, out) == "deny" and "table d'armement incohérente" in raison and not err:
        ok("R-TABLE-03 table livrée incohérente (G1 armé sans G6 ni G5) : deny « table d'armement incohérente », code 0")
    else:
        ko("R-TABLE-03", "une table livrée qui viole l'ordre des étapes refuse", "deny « table d'armement incohérente »", classer(rc, out) + " " + court(out))


def sec_parseur(ctx):
    bon, detail = controle_parseur(ctx, ctx.hook)
    if bon:
        ok("R-PARSEUR " + detail)
    else:
        ko("R-PARSEUR", "les arbres ast du parseur de frontmatter du hook et du moteur de recalcul sont identiques", "identiques", detail)


def sec_g2(ctx):
    for ident, ctrl in (("R-G2-01", controle_g2_01), ("R-G2-02", controle_g2_02), ("R-G2-03", controle_g2_03)):
        bon, detail = ctrl(ctx, None)
        titre = {"R-G2-01": "Write hors ecrit: -> additionalContext (jamais permissionDecision)",
                 "R-G2-02": "écriture couverte, sous .planning/ ou .claude/ -> silence",
                 "R-G2-03": "plan clos ou dérogé ne couvre rien"}[ident]
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    # R-G2-04 : Bash
    fautes = []
    for cmd, cwd_rel, attendu in (("cat livrables/autre.md", None, "avertit"), ("cat ../livrables/autre.md", "sub", "avertit"),
                                  ("cat .planning/notes.md", None, "silence"), ("touch livrables/rapport.md", None, "silence"),
                                  ("echo 'guillemet ouvert", None, "silence"),
                                  ("cat .planning/notes.md > .planning/copie.md 2>&1", None, "silence")):
        rc, out, err = _ecrire_ok(ctx, None, "g2-adherent", "Bash", "-", commande=cmd, cwd_rel=cwd_rel)
        v = classer(rc, out)
        if v != attendu or err:
            fautes.append("%s -> %s" % (cmd, v))
        elif v == "avertit" and "Bash" not in contexte_de(out):
            fautes.append("%s : le message ne dit pas que Bash n'est pas couvert" % cmd)
    if fautes:
        ko("R-G2-04", "Bash : un jeton qui nomme un chemin hors ecrit: avertit ; chemins de .planning/, commande non découpable -> silence", "conforme", "; ".join(fautes))
    else:
        ok("R-G2-04 Bash : jeton hors ecrit: avertit (relatif au cwd du payload), .planning/ et commande non découpable en silence")
    # R-G2-05 : fil principal et sous-agent
    fautes = []
    for chemin in ("livrables/autre.md", "livrables/rapport.md"):
        r1 = _ecrire_ok(ctx, None, "g2-adherent", "Write", chemin)
        r2 = _ecrire_ok(ctx, None, "g2-adherent", "Write", chemin, agent="general-purpose")
        if r1 != r2:
            fautes.append("%s : fil principal %s / sous-agent %s" % (chemin, classer(r1[0], r1[1]), classer(r2[0], r2[1])))
    ok("R-G2-05 fil principal et sous-agent : même sortie octet pour octet (hypothèse G2-REF)") if not fautes else ko(
        "R-G2-05", "fil principal et sous-agent rendent la même sortie", "identiques", "; ".join(fautes))
    # R-G2-06 : frontmatter illisible
    rc, out, err = _ecrire_ok(ctx, None, "g2-adherent", "Write", "livrables/abime.md")
    v = classer(rc, out)
    if v == "avertit" and "erreur interne" not in contexte_de(out) and not err:
        ok("R-G2-06 PLAN.md au frontmatter illisible : plan ignoré, aucune exception ne sort du hook (G2 fail-open)")
    else:
        ko("R-G2-06", "un PLAN.md illisible est ignoré sans exception", "avertit (non couvert), rc 0", v + " " + court(out) + " " + court(err))
    bon, detail = controle_g2_07(ctx, None)
    ok("R-G2-07 " + detail) if bon else ko("R-G2-07", "lab dev qui contient un plan ouvert et un livrable non déclaré : silence", "octet vide", detail)
    # R-G2-PERF : 400 plans ouverts
    racine = ctx.unique("perf400")
    ecrire(os.path.join(racine, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    for i in range(1, 401):
        ecrire(os.path.join(racine, ".planning", "cycles", "01-c", "phases", "%03d-p" % i, "PLAN.md"),
               "---\necrit: livrables/f%d.md\n---\n" % i)
    brut = payload("Write", entree_outil("Write", racine + "/livrables/absent.md"), racine)
    t0 = time.perf_counter()
    rc, out, err = ctx.lancer("A", brut, cwd=racine)
    dt = time.perf_counter() - t0
    if classer(rc, out) == "avertit" and "400 plan(s) ouvert(s)" in contexte_de(out) and dt < 3.0:
        ok("R-G2-PERF lab adhérent de 400 plans ouverts : Write tranché en %.2f s (< 3 s)" % dt)
    else:
        ko("R-G2-PERF", "400 plans ouverts, Write hors ecrit: tranché en moins de 3 s", "avertit avec « 400 plan(s) ouvert(s) » en < 3 s", "%s en %.2f s" % (classer(rc, out), dt))


def sec_env(ctx):
    armee, n = ctx.copie_armee()
    if n != 5:
        ko("R-ENV-01", "la copie à l'armement forcé réécrit cinq constantes", "5", str(n))
        return
    bon, detail = controle_env(ctx, [ctx.scripts_dir, armee])
    ok("R-ENV-01 adhésion et armement indépendants de l'environnement (état livré et copie armée) : " + detail) if bon else ko(
        "R-ENV-01", "cinq environnements rendent le même verdict, octet pour octet (P45-D-12a ; limite (i) : la copie exécutée n'est pas testée ici)", "verdicts identiques", detail)


def sec_accord(ctx):
    bon, detail = controle_accord(ctx, None)
    ok("R-ACCORD " + detail) if bon else ko("R-ACCORD", "chemin relatif : avertissement G2 en mode A <=> deny en mode C (limite h)", "accord des deux couches", detail)


def sec_banc(ctx):
    ordre, labs, chemins = labs_banc(ctx)
    compte = {}
    tout_ok = True
    for nom in ordre:
        for e in labs[nom]["ecritures"]:
            brut, cwd = entree_de_ecriture(e, chemins[nom])
            rc, out, err = ctx.lancer("A", brut, cwd=cwd)
            bon, obtenu = juger(e["attendu"], e["gate"], rc, out)
            etiquette = "BANC %s %s %s%s :: %s %s" % (nom, e["outil"], e["chemin"], (" " + e["commande"]) if e["commande"] else "", e["attendu"], e["gate"] or "")
            if bon and not err:
                ok(etiquette.strip())
            else:
                tout_ok = False
                ko(etiquette.strip(), "écriture du banc rejouée par la commande enregistrée", e["attendu"], obtenu + " " + court(out) + " " + court(err))
            compte.setdefault(e["gate"], {}).setdefault(e["attendu"], 0)
            compte[e["gate"]][e["attendu"]] += 1
    for gate in ("G2",):
        c = compte.get(gate, {})
        print("COUVERTURE %s avertit=%d silence=%d" % (gate, c.get("avertit", 0), c.get("silence", 0)))
        if c.get("avertit", 0) < 1 or c.get("silence", 0) < 1:
            ko("COUVERTURE " + gate, "au moins un cas `avertit` et un cas `silence` pour " + gate, ">= 1 chacun", str(c))
        else:
            ok("COUVERTURE %s : %d avertit, %d silence" % (gate, c["avertit"], c["silence"]))
    # jumeau négatif : chaque lab jumeau a au moins un cas
    for nom in ordre:
        if labs[nom]["jumeau_de"] and not labs[nom]["ecritures"]:
            ko("COUVERTURE jumeau " + nom, "un lab jumeau porte des écritures", ">= 1", "0")


def sec_mutants(ctx):
    M = [
        ("G2-DECISION", '"additionalContext": "\\n".join(textes),',
         '"additionalContext": "\\n".join(textes), "permissionDecision": "deny",', "R-G2-01", controle_g2_01),
        ("G2-ECRIT", "for _plan, entrees in plans:  # g2-union", "for _plan, entrees in plans[:1]:  # g2-union", "R-G2-02", controle_g2_02),
        ("G2-CLOS", "# g2-clos", "if False:  # g2-clos", "R-G2-03", controle_g2_03),
        ("PY-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-G2-07", controle_g2_07),
        ("TABLE-ORDRE", "gates = [gate for etape in ORDRE_ETAPES for gate in etape]  # armement-valide-debut", "return True",
         "R-TABLE-02", controle_table_02),
        ("PARSEUR", 'return ("invalide:frontmatter-non-ferme", {})', 'return ("invalide:frontmatter-non-ferme-mute", {})',
         "R-PARSEUR", controle_parseur),
        ("ENV-ADHESION", 'SCHEMA_ADHESION = "cycles-v1"', 'SCHEMA_ADHESION = os.environ.get("VF_SCHEMA_ADHESION", "cycles-v1")',
         "R-ENV-01", lambda c, d: controle_env(c, [d])),
        ("ENV-ARMEMENT", 'G2_MODE = "avertit"', 'G2_MODE = os.environ.get("VF_ARMEMENT", "avertit")',
         "R-ENV-01", lambda c, d: controle_env(c, [d])),
        ("ACCORD-PY", 'ecrit = base + "/" + ecrit', "pass", "R-ACCORD", controle_accord),
    ]
    for ident, motif, repl, cible, ctrl in M:
        dossier, raison = make_hook_mutant(ctx, ident, motif, repl)
        if dossier is None:
            komut(ident, "mutant du cœur valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
            continue
        chemin_mut = os.path.join(dossier, "planning-hook.sh")
        cible_script = chemin_mut if ctrl in (controle_table_02, controle_parseur) else dossier
        # l'original passe le contrôle ; le mutant le rate ; le témoin reste inchangé
        original = ctrl(ctx, ctx.hook if ctrl in (controle_table_02, controle_parseur) else ctx.scripts_dir)
        t_orig, t_mut = controle_temoin(ctx, None), controle_temoin(ctx, dossier)
        mutant = ctrl(ctx, cible_script)
        if not original[0]:
            komut(ident, "l'original passe %s (garde du témoin de la mutation)" % cible, "conforme", original[1])
        elif t_orig != t_mut:
            komut(ident, "témoin (Write neutre d'un lab adhérent) inchangé sous le mutant", str(t_orig), str(t_mut))
        elif mutant[0]:
            komut(ident, "%s rougit sous le mutant" % cible, "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
        else:
            okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s · témoin inchangé"
                  % (cible, original[1], mutant[1]))


SECTIONS = {
    "table": sec_table,
    "parseur": sec_parseur,
    "g2": sec_g2,
    "env": sec_env,
    "accord": sec_accord,
    "banc": sec_banc,
    "mutants": sec_mutants,
}


def main():
    scripts_dir, hooks_json, banc, work, settings_lab = sys.argv[2:7]
    ctx = Ctx(scripts_dir, hooks_json or None, work, settings_lab or None)
    ctx.banc = banc
    if ctx.charger_commande() is None:
        ko("commande enregistrée", "la commande enregistrée est lisible (une seule entrée PreToolUse portant planning-hook.sh)",
           "1 commande", "introuvable dans " + str(hooks_json or settings_lab or "aucune source"))
        sys.exit(1)
    for nom in sys.argv[1].split(","):
        SECTIONS[nom](ctx)


main()
PY_AIDES_GATES_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-gates.txt"
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$HOOKS_JSON" "$BANC" "$WORK" "$SETTINGS_LAB" > "$out" 2>&1
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

[ -f "$HOOK" ] || ko "planning-hook.sh présent" "le script du hook central existe à côté des suites" "$HOOK" "absent"
[ -f "$BANC" ] || ko "gates-banc.txt présent" "le banc texte existe sous fixtures/" "$BANC" "absent"
[ -f "$RECALC" ] || ko "recalc-planning.sh présent" "le moteur de recalcul existe à côté du hook (contrôle croisé du parseur)" "$RECALC" "absent"

run_sections table,parseur,g2,env,accord,banc,mutants

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
