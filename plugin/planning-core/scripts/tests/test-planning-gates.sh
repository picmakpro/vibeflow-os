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
#   R-ENV-02        garde statique : le cœur Python ne lit aucune variable d'environnement (expanduser et
#                   expandvars compris) ; le lanceur lit TMPDIR (ligne du mktemp), XDG_CACHE_HOME et HOME
#                   (ligne d'appel du cœur, arguments) — amendement du 2026-09-30 (45-04) ; HOME sert aussi, et à cela seul,
#                   de racine de résolution des agents du compte (45-08, même décision du manager, 2026-09-30)
#   R-G5-01..06     G5 : Write, Edit, NotebookEdit de VERDICT.md sous .planning/ d'un lab adhérent, quel que
#                   soit le rôle ; en observe une ligne de journal sans contenu, en armed un deny (45-04)
#   R-G6-01..05     G6 : Write, Edit, NotebookEdit d'un fichier généré, enfant direct du dossier de planning d'un lab
#                   adhérent, quel que soit le rôle ; compartiments et plans du modèle non visés ; dérogation (45-05)
#   R-CANG-01..03   canary de session : les cas G6 et G5 attendent une ligne d'observation tant que le gate est en
#                   observe, un refus de gate dès qu'il est armed ; un gate neutralisé fait signaler le canary (45-05)
#   R-G1-01..10     G1 (45-06) : PLAN.md de forme modèle dans une phase sans CADRAGE.md ou à registre ouvert, observe puis
#                   armed, plan direct et sous plans/ (la phase jugée est la phase), socle v2 et nom d'unité invalide
#                   jamais visés ; la valeur d'un statut n'est jamais jugée ; bord F5 = f5-etats (un état que le modèle
#                   ne peut pas lire n'est jamais refusé, l'absence de CADRAGE.md l'est toujours) ; dérogation ;
#                   contrôle croisé avec recalc-planning.sh --read-only sur chaque phase des bancs (CROISE-G1) ;
#                   COMPTE G1 du banc
#   R-REGISTRE      lire_registre du hook est ast-identique à celle du moteur de recalcul
#   R-CANG-G1       le cas de canary G1-sans-cadrage (état livré, G6, G5 et G1 armed, evaluer_g1 neutralisé)
#   R-G7-01..05     G7 (45-07) : création d'un .planning/ par Write ou NotebookEdit dans un dossier nu sous un lab adhérent,
#                   observe puis armed ; un marqueur de projet de code laisse passer (un cas par marqueur, faux marqueurs
#                   refusés) ; .planning/ existant, Edit, lab dev, dossier sans ancêtre planifié : jamais refusés ; contrôle
#                   croisé des marqueurs avec le TEXTE de detect-gsd-engine.sh (R-G7-05) ; COUVERTURE G7, COMPTE G7 du banc
#   R-G7-06..09     G7 (45-07) : prédicat « habité » littéral de P45-D-14 (un agents/*.md régulier ET un fichier régulier sous
#                   memory/ ; tableau des cas imprimé `G7-HABITE`), fichiers réguliers seulement, dérogation, COMPTE G7 du banc
#   R-CANG-G7       le cas de canary G7-orphelin (état livré, étapes 1 à 3 armed, evaluer_g7 neutralisé)
#   R-ROLE-01..07   hook par rôle (45-08 ; GATE-09) : un juge défini dans le lab écrit, le hook résout sa définition (lab, compte,
#                   plugin ; name: du frontmatter, repli sur le nom de fichier ; normalisation), dérive « juge » et l'observe (copie
#                   observe : une ligne gate=ROLE) ou le refuse (copie armed) ; fil principal, agent inconnu, ambigu, illisible ou de
#                   plugin non résolu : jamais un refus de rôle ; lab dev : stdout d'octet vide ; --classer ; erreur interne
#   R-ROLE-13       HOME est l'entrée déclarée de la résolution des agents du compte (P45-D-12a) : il change la résolution, jamais
#                   l'adhésion, le verdict de G5 et de G6 ni l'armement ; XDG_CACHE_HOME, CLAUDE_PROJECT_DIR et TMPDIR ne la changent pas
#                   (le contrôle croisé du rôle avec check-agents.sh vit dans scripts/tests/test-role-hook-vs-check-agents.sh)
#   R-OBS-ENV       le journal d'observation suit XDG_CACHE_HOME puis HOME et rien d'autre : les valeurs
#                   reçues n'atteignent jamais l'armement ni l'adhésion (P45-D-12a)
#   R-JETON         l'encodeur du journal est ast-identique à _jeton_journal du moteur de recalcul
#   R-DEROG-01..08  la commande deroger-gate.sh (dérogation nominative, journal append-only injectif, jamais liée
#                   à l'urgence) et sa consommation par le hook : usage unique, citée, sans effet en observe
#   R-VERDICT-01..05 la commande poser-verdict.sh : format de la 44, sha256 du PLAN.md (A3), tentative 1 puis
#                   +1, écriture atomique, refus hors lab adhérent, jamais vue par G5 (45-04, F8 et A3)
#   R-ACCORD        chemin relatif : avertissement G2 en mode A <=> deny en mode C (limite h)
#   BANC            chaque `@@ ecriture` de fixtures/gates-banc.txt rend son attendu ; COUVERTURE
#   MUT-*           chaque garde est tuée par un mutant à motif unique dont la trace est imprimée
#
# Les cas de gate de 45-04 (G5) tournent sur une copie dont les constantes ARMEMENT_* sont FORCÉES
# (`observe` ou `armed`) : jamais sur l'état livré, qui change à chaque armement. Les cas de 45-01
# (G2, table, environnement) tournent sur l'état livré. Le banc accepte l'option `armee` (copie armée).
#
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; `cmp -s`
# jamais `diff` ; tout le travail fin est fait par Python (PYBIN). Lançable depuis tout cwd.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
HOOK="$SCRIPTS_DIR/planning-hook.sh"
RECALC="$SCRIPTS_DIR/recalc-planning.sh"
BANC="$TESTS_DIR/fixtures/gates-banc.txt"
BANC_RECALC="$TESTS_DIR/fixtures/recalc-planning-banc.txt"
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
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import time
import urllib.parse
from concurrent.futures import ThreadPoolExecutor

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
        self.cache = os.path.join(work, "cache-suite")
        os.makedirs(self.cache, exist_ok=True)
        self._forcees = {}
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
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.home, "XDG_CACHE_HOME": self.cache}
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

    def copie_forcee(self, dossier_scripts, valeur):
        """Copie du script du dossier donné dont les cinq constantes ARMEMENT_* valent `valeur`
        (`observe` ou `armed`) : les cas de gate ne dépendent jamais de l'état livré."""
        cle = (dossier_scripts, valeur)
        if cle not in self._forcees:
            texte = open(os.path.join(dossier_scripts, "planning-hook.sh"), encoding="utf-8").read()
            texte, n = re.subn(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE) = )"(?:observe|armed)"', r'\1"' + valeur + '"', texte, flags=re.M)
            if n != 5:
                raise RuntimeError("cinq constantes ARMEMENT_* attendues, %d trouvée(s)" % n)
            d = self.unique("force-" + valeur)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
                fh.write(texte)
            os.chmod(os.path.join(d, "planning-hook.sh"), 0o755)
            self._forcees[cle] = d
        return self._forcees[cle]

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
    e = {"attendu": att[0], "gate": att[1] if len(att) > 1 else None, "agent": None, "cwd": None, "commande": None,
         "armee": False}
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
        elif jeton == "armee":
            e["armee"] = True
        elif jeton:
            raise ValueError("option de banc inconnue : " + jeton)
    if e["attendu"] in ("doit-passer", "doit-refuser") and not e["armee"]:
        raise ValueError("un cas doit-passer / doit-refuser se rejoue sur copie armée (option `armee`) : " + reste)
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
def make_script_mutant(ctx, nom, marqueur, ident, motif, remplacement):
    """Copie du script `nom` (heredoc `marqueur`) dont l'UNIQUE ligne portant `motif` (fixe) est
    remplacée par `remplacement` (indentation conservée). `bash -n` et la compilation du corps Python
    extrait doivent passer. Un mutant d'un autre script que le hook reçoit aussi une copie du hook
    livré (le témoin rejoue la commande enregistrée sur ce dossier)."""
    original = open(os.path.join(ctx.scripts_dir, nom), encoding="utf-8").read()
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
    chemin = os.path.join(dossier, nom)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(muté)
    os.chmod(chemin, 0o755)
    if nom != "planning-hook.sh":
        shutil.copy(ctx.hook, os.path.join(dossier, "planning-hook.sh"))
        os.chmod(os.path.join(dossier, "planning-hook.sh"), 0o755)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    try:
        compile(corps_python(muté, marqueur), chemin, "exec")
    except SyntaxError as e:
        return None, "SyntaxError du corps Python : " + str(e)
    return dossier, None


def make_hook_mutant(ctx, ident, motif, remplacement):
    return make_script_mutant(ctx, "planning-hook.sh", "PY_PLANNING_HOOK_EOF", ident, motif, remplacement)


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


def controle_env_statique(ctx, script):
    """R-ENV-02 : garde STATIQUE — le cœur Python ne lit aucune variable d'environnement (AST : aucun
    `environ`, `getenv`, `putenv`, `expanduser`, `expandvars`, ni chaîne, import ou nom de ce genre) ;
    le lanceur lit TMPDIR une seule fois, sur la ligne du mktemp, XDG_CACHE_HOME et HOME une seule fois
    chacune, sur la seule ligne qui appelle le cœur (arguments), rien d'autre. Amendement des décisions
    du manager vf-dev-manager, 2026-09-30 (45-04) : XDG_CACHE_HOME ne sert qu'au chemin du journal
    d'observation, HOME à ce chemin (repli) et à la racine de résolution des agents du compte (45-08,
    même décision, P45-D-12a : un chemin, jamais une décision d'armement ni d'adhésion). Elle ne dépend
    d'aucun nom de variable posé par la suite."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    texte = open(chemin, encoding="utf-8").read()
    fautes = []
    interdits = ("environ", "getenv", "putenv", "environb", "getenvb", "unsetenv", "expanduser", "expandvars")
    arbre = ast.parse(corps_python(texte))
    for n in ast.walk(arbre):
        vu = None
        if isinstance(n, ast.Attribute) and n.attr in interdits:
            vu = n.attr
        elif isinstance(n, ast.Name) and n.id in interdits:
            vu = n.id
        elif isinstance(n, ast.Constant) and isinstance(n.value, str) and n.value in interdits:
            vu = repr(n.value)
        elif isinstance(n, ast.alias) and n.name in interdits:
            vu = "import " + n.name
        if vu:
            fautes.append("cœur Python : lecture de l'environnement (%s, ligne %d)" % (vu, getattr(n, "lineno", 0)))
    lanceur, dedans = [], False
    for l in texte.split("\n"):
        if l == "PY_PLANNING_HOOK_EOF":
            dedans = False
        if not dedans and not l.lstrip().startswith("#"):
            lanceur.append(l)
        if l.endswith("<<'PY_PLANNING_HOOK_EOF'"):
            dedans = True
    autorisees = {"TMPDIR", "T", "PYBIN", "XDG_CACHE_HOME", "HOME"}
    ancre = {"TMPDIR": "mktemp", "XDG_CACHE_HOME": '"$PYBIN"', "HOME": '"$PYBIN"'}
    lectures = {}
    for l in lanceur:
        for nom in re.findall(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)", l):
            lectures[nom] = lectures.get(nom, 0) + 1
            if nom not in autorisees:
                fautes.append("lanceur : variable lue hors liste : " + nom)
            elif nom in ancre and ancre[nom] not in l:
                fautes.append("lanceur : %s lue hors de la ligne attendue (%s) : %s" % (nom, ancre[nom], l.strip()))
    for nom in ancre:
        if lectures.get(nom, 0) != 1:
            fautes.append("lanceur : %d lecture(s) de %s (attendu 1)" % (lectures.get(nom, 0), nom))
    return (not fautes), ("; ".join(fautes) if fautes else "aucune lecture d'environnement dans le cœur Python (expanduser et expandvars compris) ; lanceur : TMPDIR une fois (ligne du mktemp), XDG_CACHE_HOME et HOME une fois chacune (ligne d'appel du cœur)")


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



# --- 45-04 : G5, journal d'observation, encodeur ---------------------------------------------------
VERDICT_REL = ".planning/cycles/01-c/phases/01-p/VERDICT.md"
SECRET = "SECRET-FACTICE-7f3a9c"


def journal_de(cache):
    return os.path.join(cache, "vibeflow", "gates-observation", "observation.log")


def lignes_journal(cache):
    chemin = journal_de(cache)
    if not os.path.exists(chemin):
        return []
    return [l for l in open(chemin, encoding="utf-8").read().split("\n") if l]


def dossier_neuf(ctx, prefixe):
    d = ctx.unique(prefixe)
    os.makedirs(d, exist_ok=True)
    return d


def _g5(ctx, dossier_hook, outil, rel, agent=None, lab="g5-adherent", extra_env=None, entree=None):
    _, _, chemins = labs_banc(ctx)
    racine = chemins[lab]
    e = entree if entree is not None else entree_outil(outil, os.path.join(racine, rel))
    brut = payload(outil, e, racine, agent_type=agent)
    return ctx.lancer("A", brut, cwd=racine, dossier=dossier_hook, extra_env=extra_env)


def controle_g5_01(ctx, script):
    """Copie observe : Write de VERDICT.md -> silence, code 0, UNE ligne gate=G5 au journal, sans contenu."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g5-01")
    rc, out, err = _g5(ctx, d, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    ligne = lignes[0]
    for motif in ("  gate=G5  ", "  chemin=" + VERDICT_REL + "  ", "  outil=Write  "):
        if motif not in ligne:
            return False, "la ligne ne porte pas %r : %s" % (motif, ligne)
    mode_f = stat.S_IMODE(os.stat(journal_de(cache)).st_mode)
    mode_d = stat.S_IMODE(os.stat(os.path.dirname(journal_de(cache))).st_mode)
    if mode_f != 0o600 or mode_d != 0o700:
        return False, "permissions fichier %o dossier %o (attendu 600 et 700)" % (mode_f, mode_d)
    return True, "copie observe : silence, code 0, une ligne gate=G5 (chemin, outil), journal 0600 dans un dossier 0700"


def controle_g5_02(ctx, script):
    """Copie armed : même payload -> UN objet deny, `[planning-core] G5 :`, poser-verdict.sh, rien au journal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    cache = dossier_neuf(ctx, "cache-g5-02")
    rc, out, err = _g5(ctx, d, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return False, "%s stderr=%s %s" % (v, court(err), court(out))
    raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    if not raison.startswith("[planning-core] G5 :") or "poser-verdict.sh" not in raison:
        return False, "raison : " + raison
    if lignes_journal(cache):
        return False, "un refus a écrit au journal d'observation"
    return True, "copie armed : un objet deny, raison « [planning-core] G5 : … poser-verdict.sh », journal vide"


def controle_g5_03(ctx, script):
    """Copie armed : Edit, NotebookEdit, casse, profondeur, fil principal, agent inconnu, juge -> refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    base = ".planning/cycles/01-c/phases/01-p/"
    cas = (("Edit", VERDICT_REL, None), ("NotebookEdit", VERDICT_REL, None),
           ("Write", base + "verdict.md", None), ("Write", base + "Verdict.MD", None),
           ("Write", base + "plans/01-a/VERDICT.md", None), ("Write", ".planning/VERDICT.md", None),
           ("Write", VERDICT_REL, None), ("Write", VERDICT_REL, "agent-inconnu"),
           ("Write", VERDICT_REL, "vf-design-judge"), ("Write", VERDICT_REL, "general-purpose"))
    fautes = []
    for outil, rel, agent in cas:
        rc, out, err = _g5(ctx, d, outil, rel, agent=agent)
        if classer(rc, out) != "deny" or err:
            fautes.append("%s %s agent=%s -> %s" % (outil, rel, agent, classer(rc, out)))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus : Edit, NotebookEdit, casse, profondeur, fil principal, agent inconnu, juge" % len(cas))


def controle_g5_04(ctx, script):
    """Copie armed : PLAN.md, SUMMARY.md, livrable nommé verdict hors .planning/, lab dev -> aucun refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for rel in (".planning/cycles/01-c/phases/01-p/PLAN.md", ".planning/cycles/01-c/phases/01-p/SUMMARY.md",
                ".planning/cycles/01-c/phases/01-p/VERDICT-notes.md", "livrables/verdict-client.md",
                "livrables/VERDICT.md"):
        rc, out, err = _g5(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err:
            fautes.append("%s -> %s" % (rel, classer(rc, out)))
    rc, out, err = _g5(ctx, d, "Write", VERDICT_REL, lab="g5-dev")
    if classer(rc, out) != "silence" or err:
        fautes.append("lab dev %s -> %s" % (VERDICT_REL, classer(rc, out)))
    return (not fautes), ("; ".join(fautes) if fautes else "aucun refus : PLAN.md, SUMMARY.md, nom voisin, livrables/VERDICT.md hors .planning/, lab dev en silence")


def controle_g5_05(ctx, script):
    """Erreur interne injectée dans evaluer_g5 (mutant sonde) : observe -> aucun refus + ligne d'erreur ;
    armed -> deny."""
    dossier, raison = make_hook_mutant(ctx, "G5-SONDE", "# g5-sonde", 'raise RuntimeError("sonde")  # g5-sonde')
    if dossier is None:
        return False, "mutant sonde invalide : " + raison
    cache = dossier_neuf(ctx, "cache-g5-05")
    rc, out, err = _g5(ctx, ctx.copie_forcee(dossier, "observe"), "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=G5  " not in lignes[0]:
        return False, "observe : rc=%d stdout=%s stderr=%s lignes=%s" % (rc, court(out), court(err), lignes)
    motif = [c for c in lignes[0].split("  ") if c.startswith("raison=")]
    if not motif or "erreur interne" not in urllib.parse.unquote(motif[0]):
        return False, "la ligne ne porte pas une raison d'erreur : " + lignes[0]
    rc, out, err = _g5(ctx, ctx.copie_forcee(dossier, "armed"), "Write", VERDICT_REL)
    if classer(rc, out) != "deny" or "erreur interne" not in json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]:
        return False, "armed : " + classer(rc, out) + " " + court(out)
    return True, "erreur interne de G5 : en observe aucun refus et une ligne d'erreur au journal, en armed un deny"


def controle_g5_06(ctx, script):
    """Le journal d'observation ne recopie ni le contenu ni la commande écrits (Pitfall 7)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g5-06")
    _, _, chemins = labs_banc(ctx)
    chemin = os.path.join(chemins["g5-adherent"], VERDICT_REL)
    entrees = (("Write", {"file_path": chemin, "content": SECRET}),
               ("Edit", {"file_path": chemin, "old_string": SECRET, "new_string": SECRET + "-2"}),
               ("NotebookEdit", {"notebook_path": chemin, "new_source": SECRET}))
    for outil, entree in entrees:
        rc, out, err = _g5(ctx, d, outil, VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache}, entree=entree)
        if rc != 0 or out != b"" or err:
            return False, "%s : rc=%d stdout=%s" % (outil, rc, court(out))
    lignes = lignes_journal(cache)
    if len(lignes) != 3:
        return False, "%d ligne(s) au journal (attendu 3)" % len(lignes)
    if any(SECRET in l for l in lignes):
        return False, "le contenu écrit figure au journal : " + court("\n".join(lignes))
    return True, "trois écritures observées (Write, Edit, NotebookEdit), aucune ligne ne porte le contenu factice"


def _arbre_fonction(corps, nom):
    for noeud in ast.parse(corps).body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name == nom:
            return ast.dump(noeud)
    return None


def controle_jeton(ctx, script):
    """R-JETON : l'encodeur du journal est ast-identique à `_jeton_journal` de recalc-planning.sh."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    a_h = _arbre_fonction(corps_python(open(chemin, encoding="utf-8").read()), "_jeton_journal")
    a_r = _arbre_fonction(corps_python(open(ctx.recalc, encoding="utf-8").read(), "PY_RECALC_PLANNING_EOF"), "_jeton_journal")
    if a_h is None or a_r is None:
        return False, "_jeton_journal absent (hook %s, moteur %s)" % (a_h is not None, a_r is not None)
    if a_h != a_r:
        return False, "arbres différents"
    return True, "arbres ast identiques (docstring comprise)"


def controle_obs_env(ctx, script):
    """R-OBS-ENV (P45-D-12a) : le chemin du journal suit XDG_CACHE_HOME puis HOME et rien d'autre ; le
    verdict de la commande enregistrée ne dépend d'aucune des deux valeurs ; un journal impossible à
    écrire ne transforme jamais une observation en refus."""
    dossier = _dossier(ctx, script)
    d_obs = ctx.copie_forcee(dossier, "observe")
    d_arm = ctx.copie_forcee(dossier, "armed")
    _, _, chemins = labs_banc(ctx)
    fautes = []
    a, b, h1, h2 = (dossier_neuf(ctx, "obs-" + n) for n in ("a", "b", "h1", "h2"))
    # (1) la ligne apparaît sous XDG_CACHE_HOME de la suite et sous aucun autre dossier
    _g5(ctx, d_obs, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": a, "HOME": h1})
    if len(lignes_journal(a)) != 1 or os.path.exists(os.path.join(h1, ".cache")):
        fautes.append("XDG_CACHE_HOME=A : %d ligne(s) sous A, %s sous HOME" % (len(lignes_journal(a)), os.path.exists(os.path.join(h1, ".cache"))))
    _g5(ctx, d_obs, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": b, "HOME": h2})
    if len(lignes_journal(b)) != 1 or len(lignes_journal(a)) != 1 or os.path.exists(os.path.join(h2, ".cache")):
        fautes.append("XDG_CACHE_HOME=B : %d ligne(s) sous B, %d sous A" % (len(lignes_journal(b)), len(lignes_journal(a))))
    # (2) repli sur HOME/.cache quand XDG_CACHE_HOME est vide ou non absolu (jamais créé sous le lab)
    for xdg in ("", "relatif/non/absolu"):
        h = dossier_neuf(ctx, "obs-hrepli")
        _g5(ctx, d_obs, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": xdg, "HOME": h})
        if len(lignes_journal(os.path.join(h, ".cache"))) != 1:
            fautes.append("XDG_CACHE_HOME=%r : pas de repli sur HOME/.cache" % xdg)
    if os.path.exists(os.path.join(chemins["g5-adherent"], "relatif")):
        fautes.append("un XDG_CACHE_HOME relatif a créé un dossier sous le lab")
    # (3) verdicts identiques octet pour octet sous d'autres valeurs, y compris inexploitables
    fichier = os.path.join(dossier_neuf(ctx, "obs-fichier"), "reguliere")
    with open(fichier, "w", encoding="utf-8") as fh:
        fh.write("")
    variantes = (("A et H1", {"XDG_CACHE_HOME": a, "HOME": h1}), ("B et H2", {"XDG_CACHE_HOME": b, "HOME": h2}),
                 ("vides", {"XDG_CACHE_HOME": "", "HOME": ""}),
                 ("fichiers réguliers (dossier non inscriptible)", {"XDG_CACHE_HOME": fichier, "HOME": fichier}))
    for etiquette, copie, attendu in (("observe", d_obs, "silence"), ("armed", d_arm, "deny")):
        reference = _g5(ctx, copie, "Write", VERDICT_REL)
        if classer(reference[0], reference[1]) != attendu:
            fautes.append("référence %s : %s (attendu %s)" % (etiquette, classer(reference[0], reference[1]), attendu))
            continue
        for nom, extra in variantes:
            r = _g5(ctx, copie, "Write", VERDICT_REL, extra_env=extra)
            if r != reference:
                fautes.append("copie %s sous %s : %s au lieu de %s (stderr %s)" % (etiquette, nom, classer(r[0], r[1]), attendu, court(r[2])))
    with open(fichier, encoding="utf-8") as fh:
        if fh.read() != "":
            fautes.append("le fichier régulier pris pour dossier a été modifié")
    return (not fautes), ("; ".join(fautes) if fautes else "journal sous XDG_CACHE_HOME puis HOME seulement ; verdicts identiques sous 4 jeux de valeurs (dont inexploitables), copie observe et copie armed")



# --- 45-04 : poser-verdict.sh ----------------------------------------------------------------------
UNITE = ".planning/cycles/01-c/phases/01-p"


def lab_frais(ctx, nom="g5-adherent"):
    """Copie jetable (le hook et les commandes y ÉCRIVENT) d'un lab du banc, avec un CYCLE.md."""
    _, labs, _ = labs_banc(ctx)
    dest = ctx.unique("lab-" + nom)
    materialiser(labs, nom, dest)
    ecrire(os.path.join(dest, ".planning", "cycles", "01-c", "CYCLE.md"), "---\ntitre: t\nrend: r\n---\n")
    ecrire(os.path.join(dest, "livrables", "rapport.md"), "x\n")
    return dest


def lancer_script(ctx, dossier, nom, args, cwd=None):
    p = subprocess.run(["bash", os.path.join(dossier, nom)] + list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env(), cwd=cwd or ctx.work, timeout=120)
    return p.returncode, p.stdout, p.stderr


def poser(ctx, dossier, lab, tentative, juge="vf-design-judge", score="8/10", constats=("critere-a::passé",), unite=UNITE, extra=()):
    args = ["--unite=" + os.path.join(lab, unite), "--juge=" + juge, "--tentative=" + str(tentative), "--score=" + score]
    args += ["--constat=" + c for c in constats] + list(extra)
    return lancer_script(ctx, dossier, "poser-verdict.sh", args)


def octets(chemin):
    with open(chemin, "rb") as fh:
        return fh.read()


def controle_verdict_01(ctx, script):
    """Création : format de la 44 (gabarit), hash = sha256 du PLAN.md (A3), tentative 1, 0644."""
    lab = lab_frais(ctx)
    rc, out, err = poser(ctx, _dossier(ctx, script), lab, 1, constats=("critere-a::passé", "critere-b::échec"))
    chemin = os.path.join(lab, UNITE, "VERDICT.md")
    if rc != 0 or not os.path.isfile(chemin):
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    texte = octets(chemin).decode("utf-8")
    lignes = texte.split("\n")
    fin = lignes.index("---", 1)
    cles = [l.split(":")[0] for l in lignes[1:fin] if l and not l.startswith(" ")]
    empreinte = hashlib.sha256(octets(os.path.join(lab, UNITE, "PLAN.md"))).hexdigest()
    mode = stat.S_IMODE(os.stat(chemin).st_mode)
    fautes = []
    if lignes[0] != "---" or cles != ["juge", "hash", "tentative", "score", "constats"]:
        fautes.append("clés du frontmatter : %s" % cles)
    for attendu in ('juge: "vf-design-judge"', 'hash: "%s"' % empreinte, "tentative: 1", 'score: "8/10"',
                    '  - critere: "critere-a"', '    resultat: "passé"', '  - critere: "critere-b"', '    resultat: "échec"'):
        if attendu not in lignes[1:fin]:
            fautes.append("ligne absente : " + attendu)
    if "# Verdict" not in lignes[fin + 1:]:
        fautes.append("corps sans « # Verdict »")
    if mode != 0o644:
        fautes.append("permissions %o" % mode)
    restes = [n for n in os.listdir(os.path.join(lab, UNITE)) if n.startswith(".")]
    if restes:
        fautes.append("fichier temporaire laissé : %s" % restes)
    return (not fautes), ("; ".join(fautes) if fautes else "code 0, VERDICT.md au format du gabarit, hash = sha256 des octets du PLAN.md, tentative 1, 0644, aucun temporaire")


def controle_verdict_02(ctx, script):
    """Tentative : 1 à la création, ancienne + 1 pour remplacer (sinon 64, fichier inchangé) ; un lien n'est
    pas un verdict existant et n'est jamais suivi (écriture atomique)."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx)
    chemin = os.path.join(lab, UNITE, "VERDICT.md")
    rc, _o, err = poser(ctx, d, lab, 1)
    if rc != 0:
        return False, "création refusée : rc=%d %s" % (rc, court(err))
    avant = octets(chemin)
    fautes = []
    for n in (1, 3):
        rc, _o, err = poser(ctx, d, lab, n)
        if rc != 64 or octets(chemin) != avant:
            fautes.append("--tentative=%d sur une tentative 1 : rc=%d, fichier %s" % (n, rc, "inchangé" if octets(chemin) == avant else "MODIFIÉ"))
    rc, _o, err = poser(ctx, d, lab, 2)
    if rc != 0 or b"tentative: 2" not in octets(chemin):
        fautes.append("--tentative=2 : rc=%d %s" % (rc, court(err)))
    # création à tentative 2 : refusée
    lab2 = lab_frais(ctx)
    rc, _o, err = poser(ctx, d, lab2, 2)
    if rc != 64 or os.path.exists(os.path.join(lab2, UNITE, "VERDICT.md")):
        fautes.append("création à --tentative=2 : rc=%d" % rc)
    # un lien posé à la place de VERDICT.md : remplacé, jamais suivi
    lab3 = lab_frais(ctx)
    cible = os.path.join(lab3, "livrables", "cible-du-lien.txt")
    ecrire(cible, "CIBLE\n")
    os.symlink(cible, os.path.join(lab3, UNITE, "VERDICT.md"))
    rc, _o, err = poser(ctx, d, lab3, 1)
    lien = os.path.join(lab3, UNITE, "VERDICT.md")
    if rc != 0 or os.path.islink(lien) or not os.path.isfile(lien) or octets(cible) != b"CIBLE\n":
        fautes.append("lien à la place de VERDICT.md : rc=%d, lien=%s, cible %s" % (rc, os.path.islink(lien), "inchangée" if octets(cible) == b"CIBLE\n" else "MODIFIÉE"))
    return (not fautes), ("; ".join(fautes) if fautes else "1 à la création, 1 et 3 refusés (64, cmp identique) sur une tentative 1, 2 accepté ; création à 2 refusée ; un lien est remplacé, sa cible intacte")


def controle_verdict_03(ctx, script):
    """recalc-planning.sh --read-only relit la tentative et le hash écrits (format de la 44)."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx)
    os.rmdir(os.path.join(lab, UNITE, "plans", "01-a"))  # une phase à plan direct n'a pas de plans/ (raison plan-direct-et-plans)
    os.rmdir(os.path.join(lab, UNITE, "plans"))
    ecrire(os.path.join(lab, UNITE, "SUMMARY.md"), "---\nauteur: vf-coder\n---\n")
    for n in (1, 2):
        rc, _o, err = poser(ctx, d, lab, n)
        if rc != 0:
            return False, "tentative %d : rc=%d %s" % (n, rc, court(err))
    p = subprocess.run(["bash", ctx.recalc, "--planning=" + os.path.join(lab, ".planning"), "--read-only"],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), timeout=120)
    if p.returncode != 0:
        return False, "recalc --read-only : rc=%d %s" % (p.returncode, court(p.stderr))
    rapport = json.loads(p.stdout.decode("utf-8"))
    phases = [ph for c in rapport["cycles"] for ph in c.get("phases", []) if ph["chemin"].endswith("01-p")]
    empreinte = hashlib.sha256(octets(os.path.join(lab, UNITE, "PLAN.md"))).hexdigest()
    if len(phases) != 1:
        return False, "phase 01-p introuvable : " + court(p.stdout)
    ph = phases[0]
    if str(ph.get("tentative")) != "2" or ph.get("hash_juge") != empreinte or ph.get("etat") != "close":
        return False, "tentative=%r hash=%r état=%r raison=%r" % (ph.get("tentative"), ph.get("hash_juge"), ph.get("etat"), ph.get("raison"))
    return True, "recalc --read-only rend tentative 2, le hash écrit et l'état close pour l'unité"


def controle_verdict_04(ctx, script):
    """Refus : lab non adhérent 2 ; unité hors .planning/cycles/, sans PLAN.md, constat, tentative, juge ou
    valeur qui ne se relit pas identique 64 ; jamais un fichier écrit."""
    d = _dossier(ctx, script)
    fautes = []
    dev = lab_frais(ctx, "g5-dev")
    rc, _o, err = poser(ctx, d, dev, 1)
    if rc != 2 or os.path.exists(os.path.join(dev, UNITE, "VERDICT.md")):
        fautes.append("lab non adhérent : rc=%d (attendu 2)" % rc)
    hors = dossier_neuf(ctx, "verdict-hors-lab")
    ecrire(os.path.join(hors, "PLAN.md"), "---\necrit: a\n---\n")
    rc, _o, err = lancer_script(ctx, d, "poser-verdict.sh", ["--unite=" + hors, "--juge=j", "--tentative=1", "--score=s", "--constat=c::passé"])
    if rc != 2 or os.path.exists(os.path.join(hors, "VERDICT.md")):
        fautes.append("unité hors de tout lab : rc=%d (attendu 2)" % rc)
    lab = lab_frais(ctx)
    ecrire(os.path.join(lab, ".planning", "notes", "PLAN.md"), "---\necrit: a\n---\n")
    cas = (("unité hors .planning/cycles/", {"unite": ".planning/notes"}, 64),
           ("unité sans PLAN.md", {"unite": UNITE + "/plans/01-a"}, 64),
           ("unité inexistante", {"unite": UNITE + "/absente"}, 64),
           ("constat au résultat hors passé/échec", {"constats": ("critere::peut-etre",)}, 64),
           ("constat sans ::", {"constats": ("critere",)}, 64),
           ("constat au critère vide", {"constats": ("::passé",)}, 64),
           ("tentative non numérique", {"tentative": "x"}, 64),
           ("tentative nulle", {"tentative": "0"}, 64),
           ("juge vide", {"juge": ""}, 64),
           ("score avec saut de ligne", {"score": "a\nb"}, 64),
           ("critère avec guillemet et saut de ligne", {"constats": ('a"\nb::passé',)}, 64))
    for nom, surcharge, attendu in cas:
        args = dict(unite=UNITE, tentative=1, juge="j", score="s", constats=("c::passé",))
        args.update(surcharge)
        rc, _o, err = poser(ctx, d, lab, args["tentative"], juge=args["juge"], score=args["score"], constats=args["constats"], unite=args["unite"])
        ecrits = [os.path.join(dp, f) for dp, _dn, fs in os.walk(os.path.join(lab, ".planning")) for f in fs if f == "VERDICT.md" or f.startswith(".VERDICT.")]
        if rc != attendu or ecrits:
            fautes.append("%s : rc=%d (attendu %d), écrit %s" % (nom, rc, attendu, [os.path.relpath(e, lab) for e in ecrits]))
    return (not fautes), ("; ".join(fautes) if fautes else "lab dev 2, hors lab 2, %d refus 64 : unité hors cycles, sans PLAN.md, constat, tentative, juge, valeur non relisible ; aucun fichier écrit" % len(cas))


def controle_verdict_05(ctx, script):
    """La commande ne passe jamais par un outil : lancée par Bash pendant que G5 est armé, le hook n'en voit
    rien et elle écrit (alors qu'un Write du même fichier est refusé)."""
    d = _dossier(ctx, script)
    armee = ctx.copie_forcee(ctx.scripts_dir, "armed")
    lab = lab_frais(ctx)
    commande = "bash '%s' --unite=%s --juge=vf-design-judge --tentative=1 --score=8/10 --constat=c::passé" % (
        os.path.join(d, "poser-verdict.sh"), os.path.join(lab, UNITE))
    brut = payload("Bash", {"command": commande}, lab)
    rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=armee)
    if classer(rc, out) == "deny" or err:
        return False, "le hook armé voit la commande Bash : " + classer(rc, out) + " " + court(out)
    brut = payload("Write", {"file_path": os.path.join(lab, UNITE, "VERDICT.md"), "content": "x"}, lab)
    rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=armee)
    if classer(rc, out) != "deny":
        return False, "témoin : le Write du même fichier n'est pas refusé sur la copie armée : " + classer(rc, out)
    rc, out, err = poser(ctx, d, lab, 1)
    if rc != 0 or not os.path.isfile(os.path.join(lab, UNITE, "VERDICT.md")):
        return False, "la commande n'a pas écrit : rc=%d %s" % (rc, court(err))
    return True, "G5 armé : la commande Bash n'est pas refusée et écrit, le Write du même fichier l'est"



# --- 45-04 : deroger-gate.sh et dérogations du hook -------------------------------------------------
def journal_derog(lab):
    return os.path.join(lab, ".planning", "derogations-gates.log")


def deroger(ctx, lab, dossier=None, gate="G5", chemins=(VERDICT_REL,), qui="willy", canal="AskUserQuestion session principale",
            date="2026-09-30", raison="cas de test de la dérogation", extra=()):
    args = ["--lab=" + lab, "--gate=" + gate] + ["--chemin=" + c for c in chemins]
    args += ["--qui=" + qui, "--canal=" + canal, "--date=" + date, "--raison=" + raison] + list(extra)
    return lancer_script(ctx, dossier or ctx.scripts_dir, "deroger-gate.sh", args)


def ecrire_dans(ctx, dossier_hook, lab, outil, rel, extra_env=None):
    brut = payload(outil, entree_outil(outil, os.path.join(lab, rel)), lab)
    return ctx.lancer("A", brut, cwd=lab, dossier=dossier_hook, extra_env=extra_env)


def lignes_de(chemin):
    if not os.path.exists(chemin):
        return []
    return [l for l in octets(chemin).decode("utf-8").split("\n") if l]


def controle_derog_01(ctx, script):
    """Dérogation valide : une ligne par chemin, ids 1 et 2, journal jamais tronqué, 0644."""
    d = _dossier(ctx, script)
    fautes = []
    lab = lab_frais(ctx)
    rc, out, err = deroger(ctx, lab, d, gate="G6", chemins=(".planning/cycles/01-c/CYCLE.md",))
    lignes = lignes_de(journal_derog(lab))
    attendu = "  derogation  id=1  gate=G6  chemin=.planning/cycles/01-c/CYCLE.md  qui=willy  canal=AskUserQuestion%20session%20principale  date=2026-09-30  raison=cas%20de%20test%20de%20la%20d"
    if rc != 0 or len(lignes) != 1 or attendu not in lignes[0]:
        fautes.append("une dérogation : rc=%d lignes=%s stderr=%s" % (rc, lignes, court(err)))
    elif stat.S_IMODE(os.stat(journal_derog(lab)).st_mode) != 0o644:
        fautes.append("permissions du journal")
    lab2 = lab_frais(ctx)
    rc, out, err = deroger(ctx, lab2, d, chemins=(VERDICT_REL, "livrables/rapport.md"))
    lignes = lignes_de(journal_derog(lab2))
    if rc != 0 or len(lignes) != 2 or "  id=1  " not in lignes[0] or "  id=2  " not in lignes[1]:
        fautes.append("deux chemins : rc=%d lignes=%s" % (rc, lignes))
    avant = octets(journal_derog(lab2))
    rc, out, err = deroger(ctx, lab2, d, gate="G1", chemins=("livrables/autre.md",))
    apres = octets(journal_derog(lab2))
    if rc != 0 or not apres.startswith(avant) or len(lignes_de(journal_derog(lab2))) != 3 or "  id=3  " not in lignes_de(journal_derog(lab2))[2]:
        fautes.append("ajout : préfixe conservé=%s rc=%d" % (apres.startswith(avant), rc))
    lab3 = lab_frais(ctx)
    with open(journal_derog(lab3), "wb") as fh:
        fh.write(b"ancien sans saut final")
    rc, out, err = deroger(ctx, lab3, d)
    apres = octets(journal_derog(lab3))
    derniere = lignes_de(journal_derog(lab3))[-1] if lignes_de(journal_derog(lab3)) else ""
    if rc != 0 or not apres.startswith(b"ancien sans saut final") or "  derogation  id=1  gate=G5  " not in derniere:
        fautes.append("journal sans saut final : rc=%d dernière=%s" % (rc, court(derniere)))
    return (not fautes), ("; ".join(fautes) if fautes else "une ligne par chemin (ids 1 et 2, puis 3), préfixe d'octets conservé, journal 0644, saut de ligne ajouté si absent")


def controle_derog_02(ctx, script):
    """Raison placeholder (après NFKC), qui, canal, date ou gate invalides : 64, le message nomme le champ, rien écrit."""
    d = _dossier(ctx, script)
    fautes = []
    lab = lab_frais(ctx)
    cas = [("raison vide", {"raison": ""}, "--raison")]
    for valeur in ("TODO", "todo", "xxx", "XXXX", "…", "...", "<raison>", "<…>", "ＴＯＤＯ", "ＸＸＸ", "．．．", "＜raison＞", "​", "   "):
        cas.append(("raison %r" % valeur, {"raison": valeur}, "--raison"))
    cas += [("qui vide", {"qui": ""}, "--qui"), ("canal vide", {"canal": ""}, "--canal"),
            ("date 2026-13-01", {"date": "2026-13-01"}, "--date"), ("date 30/09/2026", {"date": "30/09/2026"}, "--date"),
            ("date 2026-9-30", {"date": "2026-9-30"}, "--date"), ("gate G2", {"gate": "G2"}, "--gate"),
            ("gate g5", {"gate": "g5"}, "--gate"), ("chemin absolu", {"chemins": ("/etc/passwd",)}, "--chemin"),
            ("chemin avec ..", {"chemins": ("../x",)}, "--chemin")]
    for nom, surcharge, champ in cas:
        rc, out, err = deroger(ctx, lab, d, **surcharge)
        if rc != 64 or champ.encode("utf-8") not in err or os.path.exists(journal_derog(lab)):
            fautes.append("%s : rc=%d (attendu 64), champ %s %s, journal %s" % (nom, rc, champ, "nommé" if champ.encode("utf-8") in err else "NON nommé", "écrit" if os.path.exists(journal_derog(lab)) else "absent"))
    rc, out, err = lancer_script(ctx, d, "deroger-gate.sh", ["--lab=" + lab, "--gate=G5", "--chemin=a", "--qui=w", "--canal=c", "--date=2026-09-30"])
    if rc != 64 or b"--raison" not in err:
        fautes.append("option --raison absente : rc=%d" % rc)
    rc, out, err = deroger(ctx, lab, d, raison="raison réelle et motivée")
    if rc != 0:
        fautes.append("témoin : une raison réelle est refusée (rc=%d %s)" % (rc, court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus 64 qui nomment le champ (placeholders en pleine chasse compris), rien écrit ; une raison réelle passe" % (len(cas) + 1))


def controle_derog_03(ctx, script):
    """Une raison qui contient un saut de ligne et des lignes de journal factices : UNE ligne, aucune fausse consommation."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx)
    raison = "ok\n2026-09-30T00:00:00+00:00  consommee  id=1  gate=G5  chemin=x\n  consommee id=1"
    rc, out, err = deroger(ctx, lab, d, raison=raison)
    lignes = lignes_de(journal_derog(lab))
    if rc != 0:
        return False, "rc=%d %s" % (rc, court(err))
    fausses = [l for l in lignes if l.split("  ")[1:2] == ["consommee"]]
    if len(lignes) != 1 or fausses or octets(journal_derog(lab)).count(b"\n") != 1:
        return False, "%d ligne(s), fausses consommations %s : %s" % (len(lignes), fausses, court("\n".join(lignes)))
    return True, "une seule ligne de journal (encodage pourcent), aucune fausse consommation"


def _scenario_derog(ctx, script, etape):
    """(lab, dossier du hook forcé à `etape`) avec une dérogation G5 posée par la commande livrée."""
    lab = lab_frais(ctx)
    rc, out, err = deroger(ctx, lab)
    if rc != 0:
        raise RuntimeError("deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err)))
    return lab, ctx.copie_forcee(_dossier(ctx, script), etape)


def controle_derog_04(ctx, script):
    """Copie armed, Write de VERDICT.md couvert par une dérogation G5 : pas de refus, citation, consommation."""
    lab, hook = _scenario_derog(ctx, script, "armed")
    rc, out, err = ecrire_dans(ctx, hook, lab, "Write", VERDICT_REL)
    if classer(rc, out) != "avertit" or err:
        return False, "%s %s" % (classer(rc, out), court(out))
    texte = contexte_de(out)
    manque = [m for m in ("#1", "G5", "willy", "AskUserQuestion session principale", "2026-09-30", "cas de test de la dérogation") if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=G5  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    return True, "pas de refus, additionalContext qui cite id, qui, canal, date et raison, ligne consommee id=1 ajoutée"


def controle_derog_05(ctx, script):
    """Usage unique : le second Write identique est refusé, un autre chemin aussi."""
    lab, hook = _scenario_derog(ctx, script, "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", VERDICT_REL)
    r2 = ecrire_dans(ctx, hook, lab, "Write", VERDICT_REL)
    r3 = ecrire_dans(ctx, hook, lab, "Write", ".planning/cycles/01-c/phases/01-p/plans/01-a/VERDICT.md")
    fautes = []
    if classer(r1[0], r1[1]) != "avertit":
        fautes.append("premier Write : " + classer(r1[0], r1[1]))
    if classer(r2[0], r2[1]) != "deny":
        fautes.append("second Write identique : " + classer(r2[0], r2[1]) + " (dérogation consommée attendue refusée)")
    if classer(r3[0], r3[1]) != "deny":
        fautes.append("autre chemin : " + classer(r3[0], r3[1]))
    return (not fautes), ("; ".join(fautes) if fautes else "premier Write passe et cité, second Write identique refusé, autre chemin refusé")


def controle_derog_06(ctx, script):
    """Gate en observe : la dérogation n'est ni citée ni consommée."""
    lab, hook_obs = _scenario_derog(ctx, script, "observe")
    hook_arm = ctx.copie_forcee(_dossier(ctx, script), "armed")
    avant = octets(journal_derog(lab))
    cache = dossier_neuf(ctx, "cache-derog-06")
    rc, out, err = ecrire_dans(ctx, hook_obs, lab, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    if rc != 0 or out != b"" or err or octets(journal_derog(lab)) != avant:
        return False, "observe : rc=%d stdout=%s journal %s" % (rc, court(out), "inchangé" if octets(journal_derog(lab)) == avant else "MODIFIÉ")
    if len(lignes_journal(cache)) != 1:
        return False, "observe : %d ligne(s) d'observation (attendu 1)" % len(lignes_journal(cache))
    rc, out, err = ecrire_dans(ctx, hook_arm, lab, "Write", VERDICT_REL)
    if classer(rc, out) != "avertit":
        return False, "la dérogation a été consommée en observe : armed -> " + classer(rc, out)
    return True, "observe : silence, journal inchangé (octet pour octet), ligne d'observation écrite ; la dérogation sert ensuite en armed"


def controle_derog_07(ctx, script):
    """Journal remplacé par un lien vers un fichier qui porte une dérogation : aucune n'est active."""
    lab, hook = _scenario_derog(ctx, script, "armed")
    reel = os.path.join(lab, ".planning", "derogations-reel.txt")
    os.rename(journal_derog(lab), reel)
    os.symlink(reel, journal_derog(lab))
    avant = octets(reel)
    rc, out, err = ecrire_dans(ctx, hook, lab, "Write", VERDICT_REL)
    if classer(rc, out) != "deny" or octets(reel) != avant:
        return False, "%s, cible %s" % (classer(rc, out), "inchangée" if octets(reel) == avant else "MODIFIÉE")
    return True, "journal en lien symbolique : dérogation inactive, refus maintenu, cible intacte"


def controle_derog_08(ctx, script):
    """Aucune option de la commande ne porte sur l'urgence, la vitesse ou une durée."""
    d = _dossier(ctx, script)
    rc, aide, err = lancer_script(ctx, d, "deroger-gate.sh", ["-h"])
    autorisees = {"lab", "gate", "chemin", "qui", "canal", "date", "raison"}
    interdits = ("urgen", "vite", "rapid", "dur", "delai", "délai", "expir", "ttl", "timeout", "heure", "minute", "seconde", "temp", "now")
    fautes = []
    jetons = set(re.findall(r"--([a-z-]+)", aide.decode("utf-8")))
    if rc != 0 or not jetons or jetons - autorisees:
        fautes.append("aide -h : rc=%d options %s" % (rc, sorted(jetons)))
    source = open(os.path.join(d, "deroger-gate.sh"), encoding="utf-8").read()
    m = re.search(r"^OPTIONS = \(([^)]*)\)", source, re.M)
    declarees = set(re.findall(r'"([a-z-]+)"', m.group(1))) if m else set()
    if not declarees or declarees - autorisees:
        fautes.append("parseur : options déclarées %s" % sorted(declarees))
    for nom in jetons | declarees:
        if any(s in nom for s in interdits):
            fautes.append("option %s : nom lié au temps ou à l'urgence" % nom)
    lab = lab_frais(ctx)
    for extra in (["--urgence=oui"], ["--duree=1h"], ["--vite"], ["--expire=demain"]):
        rc, out, err = deroger(ctx, lab, d, extra=extra)
        if rc != 64 or os.path.exists(journal_derog(lab)):
            fautes.append("%s : rc=%d (attendu 64)" % (extra[0], rc))
    return (not fautes), ("; ".join(fautes) if fautes else "sept options (lab, gate, chemin, qui, canal, date, raison), aucune liée à l'urgence, la vitesse ou une durée ; quatre options de ce genre refusées (64)")


# --- 45-05 : G6 (fichiers générés) et canary des gates de l'étape 1 ---------------------------------------
PROTEGES_BANC = (".planning/STATE.md", ".planning/INDEX.md", ".planning/cloture.log", ".planning/derogations-gates.log")


def _g6(ctx, dossier_hook, outil, rel, agent=None, lab="g6-adherent", extra_env=None, entree=None):
    return _g5(ctx, dossier_hook, outil, rel, agent=agent, lab=lab, extra_env=extra_env, entree=entree)


def controle_g6_01(ctx, script):
    """Copie observe : Write d'un fichier généré -> silence, code 0, UNE ligne gate=G6 au journal d'observation."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g6-01")
    rc, out, err = _g6(ctx, d, "Write", ".planning/STATE.md", extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    for motif in ("  gate=G6  ", "  chemin=.planning/STATE.md  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : silence, code 0, une ligne gate=G6 (chemin, outil) au journal d'observation"


def controle_g6_02(ctx, script):
    """Copie armed : Write et Edit de chaque fichier généré, fil principal et agent inconnu -> un deny G6 chacun,
    dont le motif dit par quelle commande poser le fichier (Pitfall 9)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for rel in PROTEGES_BANC:
        attendu_cmd = "deroger-gate.sh" if rel.endswith("derogations-gates.log") else "recalc-planning.sh"
        for outil in ("Write", "Edit"):
            for agent in (None, "agent-inconnu"):
                rc, out, err = _g6(ctx, d, outil, rel, agent=agent)
                n += 1
                v = classer(rc, out)
                if v != "deny" or err or len(out.splitlines()) != 1:
                    fautes.append("%s %s agent=%s -> %s" % (outil, rel, agent, v))
                    continue
                raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
                if not raison.startswith("[planning-core] G6 :") or attendu_cmd not in raison:
                    fautes.append("%s %s agent=%s : raison %s" % (outil, rel, agent, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G6 (4 fichiers, Write et Edit, fil principal et agent inconnu), le motif nomme recalc-planning.sh ou deroger-gate.sh" % n)


def controle_g6_03(ctx, script):
    """Copie armée : compartiments, plans du modèle, notes -> aucun refus de G6."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for rel in (".planning/workstreams/x/STATE.md", ".planning/compartments/x/STATE.md",
                ".planning/cycles/01-c/phases/01-p/PLAN.md", ".planning/notes.md", ".planning/STATE.md.bak"):
        rc, out, err = _g6(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"G6" in out:
            fautes.append("%s -> %s %s" % (rel, classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "aucun refus : STATE.md de workstreams et de compartments, PLAN.md du modèle, notes, nom voisin")


def controle_g6_04(ctx, script):
    """Copie armée, lab dev : Write d'un fichier généré -> stdout d'octet vide."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    rc, out, err = _g6(ctx, d, "Write", ".planning/STATE.md", lab="g6-dev")
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s" % (rc, court(out))
    return True, "lab dev, copie armée : code 0 et stdout d'octet vide"


def controle_g6_05(ctx, script):
    """Une dérogation G6 active sur le fichier généré : passage cité et consommé, le second Write est refusé."""
    lab = lab_frais(ctx, "g6-adherent")
    os.remove(journal_derog(lab))  # journal neuf : la dérogation posée ci-dessous porte l'identifiant 1
    rc, out, err = deroger(ctx, lab, None, gate="G6", chemins=(".planning/STATE.md",))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", ".planning/STATE.md")
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "G6", "willy", "AskUserQuestion session principale", "2026-09-30") if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=G6  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    r2 = ecrire_dans(ctx, hook, lab, "Write", ".planning/STATE.md")
    if classer(r2[0], r2[1]) != "deny":
        return False, "second Write : " + classer(r2[0], r2[1])
    return True, "dérogation G6 : premier Write passe et cité, dérogation consommée, second Write refusé"


def scripts_canary(ctx, source, valeur, hook=None, armes=("G6", "G5"), tel_quel=False):
    """Dossier de scripts jetable : check-gates-alive.sh de `source` et planning-hook.sh (celui de `hook`, à
    défaut de `source`) dont les gates de `armes` (G6 et G5 par défaut) valent `valeur`, les autres gates restant à
    observe ; `tel_quel` : le hook n'est pas réécrit (l'état livré)."""
    texte = open(hook or os.path.join(source, "planning-hook.sh"), encoding="utf-8").read()
    for gate in ("G6", "G5", "G1", "G7", "ROLE"):
        if tel_quel:
            break
        v = valeur if gate in armes else "observe"
        texte, n = re.subn(r'^(ARMEMENT_' + gate + r' = )"(?:observe|armed)"', r'\1"' + v + '"', texte, flags=re.M)
        if n != 1:
            raise RuntimeError("une ligne ARMEMENT_%s attendue, %d trouvée(s)" % (gate, n))
    d = os.path.join(ctx.unique("projet-canary-" + valeur), ".claude", "scripts")  # forme du scope projet
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
        fh.write(texte)
    shutil.copy(os.path.join(source, "check-gates-alive.sh"), os.path.join(d, "check-gates-alive.sh"))
    for nom in ("planning-hook.sh", "check-gates-alive.sh"):
        os.chmod(os.path.join(d, nom), 0o755)
    return d


def lancer_canary_dossier(ctx, dossier):
    """Lance le check-gates-alive.sh de `dossier` (= <projet>/.claude/scripts) dans une session adhérente,
    `--settings` vers un réglage jetable dont la commande enregistrée (hooks.json, scope projet :
    "$CLAUDE_PROJECT_DIR"/.claude/scripts) vise ce même projet."""
    if TOKEN not in (ctx.cmd or ""):
        raise RuntimeError("la commande enregistrée ne porte pas le jeton " + TOKEN)
    projet = os.path.dirname(os.path.dirname(dossier))
    lab = ctx.unique("session-canary")
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    reglage = os.path.join(ctx.unique("reglage-canary"), "settings.json")
    ecrire(reglage, json.dumps({"hooks": {"PreToolUse": [{"matcher": "Write", "hooks": [
        {"type": "command", "command": ctx.cmd.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts')}]}]}}))
    p = subprocess.run(["bash", os.path.join(dossier, "check-gates-alive.sh"), "--settings=" + reglage],
                       input=json.dumps({"cwd": lab}).encode("utf-8"), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env={"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": ctx.home, "CLAUDE_PROJECT_DIR": projet},
                       cwd=lab, timeout=240)
    return p.returncode, p.stdout, p.stderr


def controle_cang_01(ctx, script):
    """G6 et G5 en observe : les trois cas du canary trouvent leur ligne d'observation -> code 3, stdout vide."""
    d = scripts_canary(ctx, _dossier(ctx, script), "observe")
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    return True, "G6 et G5 observe : code 3, stdout vide (G6-principal, G6-plugin et G5-verdict trouvent leur ligne d'observation)"


def controle_cang_02(ctx, script):
    """G6 et G5 armed : les trois cas obtiennent un deny de gate -> code 3, stdout vide."""
    d = scripts_canary(ctx, _dossier(ctx, script), "armed")
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    return True, "G6 et G5 armed : code 3, stdout vide (les trois cas obtiennent un refus de gate, jamais le texte du fail-closed)"


def controle_cang_03(ctx, script):
    """evaluer_g6 neutralisé (jamais de verdict) : le canary signale, code 0, UNE ligne qui nomme G6 — observe comme armed."""
    neutre, raison = make_hook_mutant(ctx, "G6-NEUTRE", "# gates-a-verdict", 'GATES_A_VERDICT = (("G5", evaluer_g5), ("G1", evaluer_g1), ("G7", evaluer_g7), ("ROLE", evaluer_role))  # gates-a-verdict')
    if neutre is None:
        return False, "mutant du hook invalide : " + raison
    fautes = []
    for valeur in ("observe", "armed"):
        d = scripts_canary(ctx, _dossier(ctx, script), valeur, hook=os.path.join(neutre, "planning-hook.sh"))
        rc, out, err = lancer_canary_dossier(ctx, d)
        texte = out.decode("utf-8", "replace")
        lignes = [l for l in texte.split("\n") if l]
        if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "G6" not in lignes[0] or "G5-verdict" in lignes[0]:
            fautes.append("%s : rc=%d %s" % (valeur, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "evaluer_g6 neutralisé, observe et armed : code 0 et une ligne qui nomme G6 (et pas G5)")


# --- 45-05 : identité des fichiers protégés (Pattern 5), périmètre F6 et F7b ---------------------------------
def lab_identite(ctx):
    """Copie jetable du lab g6-adherent, sans INDEX.md (la création d'un nom protégé ABSENT se juge par la casse),
    avec un lien dur vers le fichier d'état dans le dossier de planning et hors de lui, et un alias du
    dossier de planning."""
    lab = lab_frais(ctx, "g6-adherent")
    os.remove(os.path.join(lab, ".planning", "INDEX.md"))
    etat = os.path.join(lab, ".planning", "STATE.md")
    os.link(etat, os.path.join(lab, ".planning", "hard.md"))
    os.link(etat, os.path.join(lab, "livrables", "lien-dur.md"))
    os.symlink(".planning", os.path.join(lab, "alias-planning"))
    return lab


def _refus_de(ctx, hook, lab, gate, outil, rel=None, entree=None, agent=None):
    """(conforme, détail) : un deny dont la raison commence par `[planning-core] <gate> :`."""
    chemin = os.path.join(lab, rel) if rel else None
    e = entree if entree is not None else entree_outil(outil, chemin)
    rc, out, err = ctx.lancer("A", payload(outil, e, lab, agent_type=agent), cwd=lab, dossier=hook)
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return False, "%s %s -> %s %s" % (outil, rel, v, court(out))
    raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    if not raison.startswith("[planning-core] %s :" % gate):
        return False, "%s %s : raison %s" % (outil, rel, raison)
    return True, raison


def _passage_de(ctx, hook, lab, outil, rel, entree=None):
    chemin = os.path.join(lab, rel)
    e = entree if entree is not None else entree_outil(outil, chemin)
    rc, out, err = ctx.lancer("A", payload(outil, e, lab), cwd=lab, dossier=hook)
    v = classer(rc, out)
    return (v in ("silence", "avertit") and not err and b"[planning-core] G6" not in out and b"[planning-core] G5" not in out), "%s %s -> %s %s" % (outil, rel, v, court(out))


def controle_id_01(ctx, script):
    """Copie armée : variante de casse, lien dur (dans et hors du dossier de planning), alias du dossier de
    planning, segment `..`, création d'un nom protégé absent en autre casse -> refus de G6 ; jumeaux sans refus."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_identite(ctx)
    fautes = []
    cas = ((".planning/state.md", None), (".PLANNING/STATE.md", None), (".planning/Index.md", None),
           (".planning/Cloture.Log", None), (".planning/hard.md", None), ("livrables/lien-dur.md", None),
           ("alias-planning/STATE.md", None), (".planning/x/../STATE.md", None),
           (".planning/hard.md", "agent-inconnu"), ("alias-planning/STATE.md", "plugin-inconnu:agent-inconnu"))
    for rel, agent in cas:
        bon, detail = _refus_de(ctx, hook, lab, "G6", "Write", rel, agent=agent)
        if not bon:
            fautes.append(detail)
    for rel in ("livrables/STATE.md", "livrables/INDEX.md", "notes/STATE.md", ".planning/STATE.md.bak"):
        bon, detail = _passage_de(ctx, hook, lab, "Write", rel)
        if not bon:
            fautes.append("jumeau : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G6 (casse, lien dur dans et hors du dossier de planning, alias, segment .., création en autre casse, deux rôles), 4 jumeaux sans refus (même nom hors de la racine du dossier de planning, nom voisin)" % len(cas))


def controle_id_02(ctx, script):
    """Copie armée : un lien dur vers un VERDICT.md, sous un autre nom (dans et hors du dossier de planning) ->
    refus de G5 ; VERDICT.md.bak et un lien dur vers un autre fichier -> aucun refus."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_frais(ctx, "g5-adherent")
    unite = os.path.join(lab, UNITE)
    ecrire(os.path.join(unite, "VERDICT.md"), "v\n")
    os.link(os.path.join(unite, "VERDICT.md"), os.path.join(unite, "lien-verdict.md"))
    os.link(os.path.join(unite, "VERDICT.md"), os.path.join(lab, "livrables", "copie-verdict.md"))
    os.link(os.path.join(unite, "PLAN.md"), os.path.join(unite, "plan-lien.md"))
    ecrire(os.path.join(unite, "VERDICT.md.bak"), "b\n")
    fautes = []
    for rel in (UNITE + "/lien-verdict.md", "livrables/copie-verdict.md"):
        bon, detail = _refus_de(ctx, hook, lab, "G5", "Write", rel)
        if not bon:
            fautes.append(detail)
    for rel in (UNITE + "/VERDICT.md.bak", UNITE + "/plan-lien.md"):
        bon, detail = _passage_de(ctx, hook, lab, "Write", rel)
        if not bon:
            fautes.append("jumeau : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "lien dur vers un VERDICT.md refusé (G5) sous un autre nom, dans et hors du dossier de planning ; VERDICT.md.bak et un lien dur vers un autre fichier passent")


def controle_id_03(ctx, script):
    """F6 = f6-oui : une écriture par outil de config.json qui change ou retire planning_version est refusée (Write,
    Edit avec sa sémantique replace_all, NotebookEdit) ; celle qui le garde passe (autre clé changée)."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_frais(ctx, "g6-adherent")
    config = os.path.join(lab, ".planning", "config.json")
    ecrire(config, '{"planning_version": "cycles-v1", "seuil": 1, "copie": "cycles-v1"}')
    cible = os.path.join(lab, ".planning", "config.json")
    rel = ".planning/config.json"
    W = lambda contenu: ("Write", {"file_path": cible, "content": contenu})
    E = lambda ancien, nouveau, tout=None: ("Edit", dict({"file_path": cible, "old_string": ancien, "new_string": nouveau},
                                                        **({"replace_all": tout} if tout is not None else {})))
    refus = (("Write planning_version 2.0",) + W('{"planning_version": "2.0"}'),
             ("Write qui n'est pas du JSON",) + W("pas du json"),
             ("Write sans la clé",) + W('{"seuil": 1}'),
             ("Write où cycles-v1 est ailleurs",) + W('{"planning_version": "2.0", "copie": "cycles-v1"}'),
             ("Edit 2.0",) + E('"planning_version": "cycles-v1"', '"planning_version": "2.0"'),
             ("Edit qui retire la clé",) + E('"planning_version": "cycles-v1", ', ""),
             ("Edit ambigu sans replace_all",) + E("cycles-v1", "2.0"),
             ("Edit replace_all qui touche les deux",) + E("cycles-v1", "2.0", True),
             ("Edit inapplicable",) + E("absent du fichier", "x"),
             ("NotebookEdit",) + ("NotebookEdit", {"notebook_path": cible, "new_source": "x"}))
    passages = (("Write qui garde cycles-v1",) + W('{"planning_version": "cycles-v1", "seuil": 2}'),
                ("Edit d'une autre clé",) + E('"seuil": 1', '"seuil": 2'),
                ("Edit de la seconde occurrence seulement",) + E('"copie": "cycles-v1"', '"copie": "autre"'))
    fautes = []
    for etiquette, outil, entree in refus:
        bon, detail = _refus_de(ctx, hook, lab, "G6", outil, rel, entree=entree)
        if not bon:
            fautes.append(etiquette + " : " + detail)
    for etiquette, outil, entree in passages:
        bon, detail = _passage_de(ctx, hook, lab, outil, rel, entree=entree)
        if not bon:
            fautes.append(etiquette + " : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus (Write, Edit, replace_all, NotebookEdit) et %d passages de config.json selon planning_version" % (len(refus), len(passages)))


def controle_id_04(ctx, script):
    """F7b = f7b-oui : le cache du recalcul est protégé (Write et Edit refusés, motif recalc-planning.sh) ; un nom voisin passe."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_frais(ctx, "g6-adherent")
    fautes = []
    for outil in ("Write", "Edit"):
        bon, detail = _refus_de(ctx, hook, lab, "G6", outil, ".planning/.recalc-cache.json")
        if not bon:
            fautes.append(detail)
        elif "recalc-planning.sh" not in detail:
            fautes.append("motif sans recalc-planning.sh : " + detail)
    bon, detail = _passage_de(ctx, hook, lab, "Write", ".planning/.recalc-cache.json.bak")
    if not bon:
        fautes.append("jumeau : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "Write et Edit du cache refusés (motif recalc-planning.sh), nom voisin sans refus")


def controle_id_05(ctx, script):
    """recalc-planning.sh, lancé par Bash, écrit l'état, l'index et le cache sur un lab où G6 est armé : le hook n'en voit
    rien (alors qu'un Write de l'état par outil est refusé)."""
    armee = ctx.copie_forcee(ctx.scripts_dir, "armed")
    lab = lab_frais(ctx)
    os.rmdir(os.path.join(lab, UNITE, "plans", "01-a"))
    os.rmdir(os.path.join(lab, UNITE, "plans"))
    commande = "bash '%s' --planning=%s" % (ctx.recalc, os.path.join(lab, ".planning"))
    rc, out, err = ctx.lancer("A", payload("Bash", {"command": commande}, lab), cwd=lab, dossier=armee)
    if classer(rc, out) == "deny" or err:
        return False, "le hook armé voit la commande Bash : " + classer(rc, out) + " " + court(out)
    rc, out, err = ctx.lancer("A", payload("Write", {"file_path": os.path.join(lab, ".planning", "STATE.md"), "content": "x"}, lab), cwd=lab, dossier=armee)
    if classer(rc, out) != "deny":
        return False, "témoin : un Write de l'état n'est pas refusé sur la copie armée : " + classer(rc, out)
    p = subprocess.run(["bash", ctx.recalc, "--planning=" + os.path.join(lab, ".planning")], stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, env=ctx.env(), timeout=240)
    manque = [n for n in ("STATE.md", "INDEX.md", ".recalc-cache.json") if not os.path.isfile(os.path.join(lab, ".planning", n))]
    if p.returncode != 0 or manque:
        return False, "recalc-planning.sh : rc=%d, fichiers absents %s, %s" % (p.returncode, manque, court(p.stderr))
    return True, "G6 armé : la commande Bash n'est pas refusée et recalc-planning.sh écrit l'état, l'index et le cache (le Write de l'état est refusé)"


# --- 45-06 : G1 (pas de plan sans cadrage) ------------------------------------------------------------------
G1_LAB = "g1-adherent"
G1_PHASES = ".planning/cycles/01-c/phases/"
G1_SANS = G1_PHASES + "01-sans/PLAN.md"
G1_PLANS = G1_PHASES + "06-plans/plans/01-a/PLAN.md"
G1_MOTIF_ABSENCE = "n'a pas de CADRAGE.md"
G1_MOTIF_OUVERT = "porte des lignes structurantes sans statut"
NOMS_MODELE_PHASE = ("CADRAGE.md", "PLAN.md", "CLOTURE.md", "VERDICT.md", "SUMMARY.md", "DEROGATION.md")
PLANCHER_CROISE_G1 = 60  # plancher déclaré du nombre de phases comparées au recalcul (65 mesurées le 2026-09-30)


def _g1(ctx, hook, outil, rel, lab=G1_LAB, agent=None, extra_env=None):
    return _g5(ctx, hook, outil, rel, agent=agent, lab=lab, extra_env=extra_env)


def _raison_deny(rc, out, err):
    """(raison, None) d'un deny unique sans stderr ; (None, détail) sinon."""
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return None, "%s %s stderr=%s" % (v, court(out), court(err))
    return json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"], None


def controle_g1_01(ctx, script):
    """Copie observe : Write du PLAN.md d'une phase sans CADRAGE.md -> silence, code 0, UNE ligne gate=G1 au journal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g1-01")
    rc, out, err = _g1(ctx, d, "Write", G1_SANS, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    for motif in ("  gate=G1  ", "  chemin=" + G1_SANS + "  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : silence, code 0, une ligne gate=G1 (chemin, outil) au journal d'observation"


def controle_g1_02(ctx, script):
    """Copie armed : Write et Edit du PLAN.md d'une phase sans CADRAGE.md, en plan direct et sous plans/ -> un deny
    `[planning-core] G1 :` qui nomme la PHASE (jamais le plan)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for rel, phase, plan in ((G1_SANS, "01-sans", None), (G1_PLANS, "06-plans", "01-a"),
                             (G1_PHASES + "08-neuve/PLAN.md", "08-neuve", None)):
        for outil in ("Write", "Edit"):
            n += 1
            raison, detail = _raison_deny(*_g1(ctx, d, outil, rel))
            if raison is None:
                fautes.append("%s %s -> %s" % (outil, rel, detail))
            elif not raison.startswith("[planning-core] G1 :") or ("la phase %s " % phase) not in raison or G1_MOTIF_ABSENCE not in raison \
                    or (plan is not None and ("la phase %s " % plan) in raison):
                fautes.append("%s %s : raison %s" % (outil, rel, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G1 (Write et Edit ; plan direct, sous plans/, phase vide) qui nomment la phase" % n)


def controle_g1_03(ctx, script):
    """Copie armée : phase cadrée, autres fichiers du modèle, socle v2, nom d'unité invalide, hors .planning/ -> aucun
    refus de G1 ; lab dev -> stdout d'octet vide."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    passages = (G1_PHASES + "02-clos/PLAN.md", G1_PHASES + "03-vide/PLAN.md", G1_PHASES + "05-herite/PLAN.md",
                G1_PHASES + "07-plans-clos/plans/01-a/PLAN.md", G1_PHASES + "01-sans/SUMMARY.md", G1_PHASES + "01-sans/PLAN.md.bak",
                ".planning/phases/01-x/PLAN.md", G1_PHASES + "sans-numero/PLAN.md", G1_PHASES + "01-sans/plans/x/PLAN.md",
                "livrables/PLAN.md")
    for rel in passages:
        rc, out, err = _g1(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G1" in out:
            fautes.append("%s -> %s %s" % (rel, classer(rc, out), court(out)))
    rc, out, err = _g1(ctx, d, "Write", G1_SANS, lab="g1-dev")
    if rc != 0 or out != b"" or err:
        fautes.append("lab dev -> rc=%d stdout=%s" % (rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "aucun refus : phase cadrée (clos, inconnues: [], hérité), plan sous une phase cadrée, SUMMARY.md, PLAN.md.bak, socle v2, nom d'unité invalide, hors .planning/ ; lab dev en silence")


# Contrôle croisé (R-G1-04, R-G1-08) : pour chaque phase des bancs de la 44 et des gates, G1 (copie armée, Write de
# son PLAN.md) est comparé à l'état que recalc-planning.sh --read-only dérive. Les labs sont matérialisés sous un
# dossier jetable et RENDUS adhérents (config.json réécrit) : le hook n'agit que là. Sont écartées les phases
# dérogées (DEROGATION.md : la 44 juge alors sur la dérogation, le hook jamais) et celles qui portent un fichier du
# modèle non régulier (Φ1 court-circuite Φ2 : l'état indéterminé n'est pas une lecture de CADRAGE.md).
def _texte_sans_attendus(texte):
    """Le banc de la 44 sans ses directives propres : `@@ attendu*` (la dérivation attendue), `@@ fichier-dehors` (et
    son contenu) et les liens vers DEHORS/ (un fichier hors du lab, posé par son propre matérialiseur)."""
    sortie, saute = [], False
    for ligne in texte.split("\n"):
        if ligne.startswith("@@ "):
            saute = ligne.startswith("@@ fichier-dehors ")
            if saute or ligne.startswith("@@ attendu") or (ligne.startswith("@@ lien ") and "DEHORS/" in ligne):
                continue
        elif saute:
            continue
        sortie.append(ligne)
    return "\n".join(sortie)


def _labs_croises(ctx):
    if getattr(ctx, "_labs_croises", None) is None:
        sources = [("gates", ctx.banc)]
        if getattr(ctx, "banc_recalc", None):
            sources.append(("recalc", ctx.banc_recalc))
        labs, ignores = [], 0
        for nom_banc, chemin in sources:
            ordre, definitions = parser_banc(_texte_sans_attendus(open(chemin, encoding="utf-8").read()))
            base = ctx.unique("croise-" + nom_banc)
            for nom in ordre:
                dest = os.path.join(base, nom)
                try:
                    materialiser(definitions, nom, dest)
                    planning = os.path.join(dest, ".planning")
                    config = os.path.join(planning, "config.json")
                    if os.path.islink(planning) or not os.path.isdir(planning) or (os.path.isdir(config) and not os.path.islink(config)):
                        raise OSError("planning inexploitable")
                    if os.path.lexists(config):
                        os.unlink(config)
                    ecrire(config, '{"planning_version": "cycles-v1"}')
                except (OSError, ValueError):
                    ignores += 1
                    continue
                labs.append((nom_banc + "/" + nom, dest))
        ctx._labs_croises = (labs, ignores)
    return ctx._labs_croises


def _derivation_lab(ctx, racine):
    """[(chemin de phase relatif au dossier de planning, état, raison)] rendus par recalc-planning.sh --read-only."""
    p = subprocess.run(["bash", ctx.recalc, "--planning=" + os.path.join(racine, ".planning"), "--read-only"],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), timeout=180)
    if p.returncode != 0:
        return None
    try:
        donnees = json.loads(p.stdout.decode("utf-8"))
    except ValueError:
        return None
    return [(ph["chemin"], ph["etat"], ph.get("raison")) for c in donnees.get("cycles", []) for ph in c.get("phases", [])]


def _phase_comparable(racine, chemin):
    dossier = os.path.join(racine, ".planning", chemin)
    if os.path.lexists(os.path.join(dossier, "DEROGATION.md")):
        return False
    for nom in NOMS_MODELE_PHASE:
        cible = os.path.join(dossier, nom)
        if os.path.lexists(cible) and not stat.S_ISREG(os.lstat(cible).st_mode):
            return False
    return True


def _verdict_g1(ctx, dossier_hook, racine, chemin):
    """`absence`, `ouvert`, `passe` ou `autre:...` : ce que G1 (copie armée) rend pour le Write du PLAN.md de la phase."""
    brut = payload("Write", entree_outil("Write", os.path.join(racine, ".planning", chemin, "PLAN.md")), racine)
    rc, out, err = ctx.lancer("A", brut, cwd=racine, dossier=dossier_hook)
    v = classer(rc, out)
    if v in ("silence", "avertit") and not err and b"[planning-core] G1" not in out:
        return "passe"
    if v == "deny" and not err:
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
        if raison.startswith("[planning-core] G1 :") and G1_MOTIF_ABSENCE in raison:
            return "absence"
        if raison.startswith("[planning-core] G1 :") and G1_MOTIF_OUVERT in raison:
            return "ouvert"
    return "autre:%s %s" % (v, court(out))


def phases_croisees(ctx, script):
    """[(etiquette, chemin, état, raison, verdict de G1)] pour chaque phase comparable ; `script` = dossier du hook."""
    cle = _dossier(ctx, script)
    if getattr(ctx, "_croisees", None) is None:
        ctx._croisees = {}
    if cle not in ctx._croisees:
        labs, ignores = _labs_croises(ctx)
        armee = ctx.copie_forcee(cle, "armed")
        with ThreadPoolExecutor(max_workers=8) as pool:
            derivations = list(pool.map(lambda e: _derivation_lab(ctx, e[1]), labs))
            taches = []
            for (etiquette, racine), derivation in zip(labs, derivations):
                for chemin, etat, raison in derivation or []:
                    if _phase_comparable(racine, chemin):
                        taches.append((etiquette, racine, chemin, etat, raison))
            verdicts = list(pool.map(lambda t: _verdict_g1(ctx, armee, t[1], t[2]), taches))
        sans_derivation = sum(1 for d in derivations if d is None)
        ctx._croisees[cle] = ([(t[0], t[2], t[3], t[4], v) for t, v in zip(taches, verdicts)], len(labs), ignores + sans_derivation)
    return ctx._croisees[cle]


def controle_croise_g1(ctx, script):
    """R-G1-04 : « G1 refuse l'écriture du PLAN.md pour absence de CADRAGE.md » <=> recalc-planning.sh --read-only rend
    `à cadrer` ou une raison `hors-cadrage:*`, sur chaque phase comparable des deux bancs."""
    phases, n_labs, ignores = phases_croisees(ctx, script)
    fautes = []
    for etiquette, chemin, etat, raison, verdict in phases:
        attendu = etat == "à cadrer" or (raison or "").startswith("hors-cadrage:")
        if verdict.startswith("autre:") or (verdict == "absence") != attendu:
            fautes.append("%s %s : recalcul %s/%s, G1 %s" % (etiquette, chemin, etat, raison, verdict))
    n = len(phases)
    absence = sum(1 for p in phases if p[4] == "absence")
    print("CROISE-G1 n=%d labs=%d absence=%d hors-absence=%d ecartees=%d" % (n, n_labs, absence, n - absence, ignores))
    if n < PLANCHER_CROISE_G1:
        fautes.append("%d phase(s) comparée(s), sous le plancher déclaré %d" % (n, PLANCHER_CROISE_G1))
    if absence < 1 or n - absence < 1:
        fautes.append("comparaison à vide : %d refus d'absence, %d passages" % (absence, n - absence))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else "%d phases comparées (%d refus pour absence de CADRAGE.md, %d passages) : G1 refuse <=> `à cadrer` ou `hors-cadrage:*`" % (n, absence, n - absence))


def controle_g1_05(ctx, script):
    """Copie armée : registre avec une ligne structurante: oui sans statut -> deny qui cite l'id de la ligne ; deux lignes
    ouvertes -> les deux ids ; une ligne ouverte et une fermée -> seulement l'ouverte."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for rel, phase, citees, tues in ((G1_PHASES + "04-ouvert/PLAN.md", "04-ouvert", ("I-07",), ()),
                                     (G1_PHASES + "16-deux-ouverts/PLAN.md", "16-deux-ouverts", ("I-21", "I-22"), ()),
                                     (G1_PHASES + "17-mixte/PLAN.md", "17-mixte", ("I-31",), ("I-32",))):
        for outil in ("Write", "Edit"):
            n += 1
            raison, detail = _raison_deny(*_g1(ctx, d, outil, rel))
            if raison is None:
                fautes.append("%s %s -> %s" % (outil, rel, detail))
            elif not raison.startswith("[planning-core] G1 :") or ("la phase %s " % phase) not in raison or G1_MOTIF_OUVERT not in raison \
                    or any(i not in raison for i in citees) or any(i in raison for i in tues):
                fautes.append("%s %s : raison %s" % (outil, rel, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G1 qui citent l'id de chaque ligne ouverte (une, deux, une sur deux) et nomment la phase" % n)


def controle_g1_06(ctx, script):
    """Copie armée : statut ARBITRÉ, statut `n'importe quoi`, structurante: non sans statut, `inconnues: []` -> passage
    (la valeur d'un statut n'est jamais jugée)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for rel in (G1_PHASES + "02-clos/PLAN.md", G1_PHASES + "14-quelconque/PLAN.md", G1_PHASES + "15-non-structurante/PLAN.md",
                G1_PHASES + "03-vide/PLAN.md"):
        rc, out, err = _g1(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G1" in out:
            fautes.append("%s -> %s %s" % (rel, classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "passage : ARBITRÉ, n'importe quoi, structurante: non sans statut, inconnues: []")


def controle_g1_07(ctx, script):
    """Bord F5 (f5-etats) : CADRAGE.md au frontmatter invalide, au registre invalide, au format hérité, en lien, en dossier
    -> passage ; phase SANS CADRAGE.md dont un AUTRE fichier est non régulier (fixture E) -> REFUS."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for rel in (G1_PHASES + "09-fm-invalide/PLAN.md", G1_PHASES + "10-registre-invalide/PLAN.md", G1_PHASES + "05-herite/PLAN.md",
                G1_PHASES + "11-lien/PLAN.md", G1_PHASES + "12-dossier/PLAN.md"):
        rc, out, err = _g1(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G1" in out:
            fautes.append("%s -> %s %s (un état indéterminé n'est jamais refusé)" % (rel, classer(rc, out), court(out)))
    raison, detail = _raison_deny(*_g1(ctx, d, "Write", G1_PHASES + "13-autre/PLAN.md"))
    if raison is None:
        fautes.append("fixture E (pas de CADRAGE.md, CLOTURE.md en dossier) -> %s (jamais un passage par indétermination)" % detail)
    elif G1_MOTIF_ABSENCE not in raison:
        fautes.append("fixture E : raison %s" % raison)
    return (not fautes), ("; ".join(fautes) if fautes else "passage : frontmatter invalide, registre invalide, format hérité, lien, dossier ; refus : absence de CADRAGE.md avec un autre fichier non régulier (fixture E)")


def controle_g1_09(ctx, script):
    """Dérogation G1 active sur le PLAN.md : passage cité et consommé ; le second Write est refusé."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx, G1_LAB)
    rc, out, err = deroger(ctx, lab, None, gate="G1", chemins=(G1_SANS,))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(d, "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", G1_SANS)
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "G1", "willy", "AskUserQuestion session principale", "2026-09-30") if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=G1  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    r2 = ecrire_dans(ctx, hook, lab, "Write", G1_SANS)
    if classer(r2[0], r2[1]) != "deny":
        return False, "second Write : " + classer(r2[0], r2[1])
    return True, "dérogation G1 : premier Write passe et cité, dérogation consommée, second Write refusé"


def controle_registre(ctx, script):
    """R-REGISTRE : les arbres ast de lire_registre extraits du hook et du moteur de recalcul sont identiques."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    a_h = _arbre_fonction(corps_python(open(chemin, encoding="utf-8").read()), "lire_registre")
    a_r = _arbre_fonction(corps_python(open(ctx.recalc, encoding="utf-8").read(), "PY_RECALC_PLANNING_EOF"), "lire_registre")
    if a_h is None or a_r is None:
        return False, "lire_registre absent (hook %s, moteur %s)" % (a_h is not None, a_r is not None)
    if a_h != a_r:
        return False, "arbres différents"
    return True, "arbres ast identiques (docstring comprise)"


def controle_croise_g1_etendu(ctx, script):
    """R-G1-08 : la relation de R-G1-04 étendue — « G1 refuse (absence de CADRAGE.md OU registre ouvert) » <=> le recalcul rend
    `à cadrer`, `en cadrage`, `hors-cadrage:*` ou `avant-cadrage-clos:*` ; les états indéterminés `registre-invalide` et
    `frontmatter-invalide:CADRAGE.md` ne sont jamais refusés (f5-etats)."""
    phases, n_labs, ignores = phases_croisees(ctx, script)
    fautes = []
    illisibles = ouverts = 0
    for etiquette, chemin, etat, raison, verdict in phases:
        r = raison or ""
        attendu = etat in ("à cadrer", "en cadrage") or r.startswith("hors-cadrage:") or r.startswith("avant-cadrage-clos:")
        refuse = verdict in ("absence", "ouvert")
        if verdict.startswith("autre:") or refuse != attendu:
            fautes.append("%s %s : recalcul %s/%s, G1 %s" % (etiquette, chemin, etat, raison, verdict))
        if etat == "indéterminé" and r in ("registre-invalide", "frontmatter-invalide:CADRAGE.md"):
            illisibles += 1
            if verdict != "passe":
                fautes.append("%s %s : état illisible refusé (%s)" % (etiquette, chemin, verdict))
        if verdict == "ouvert":
            ouverts += 1
    n = len(phases)
    print("CROISE-G1-ETENDU n=%d absence-ou-ouvert=%d dont-ouvert=%d illisibles-jamais-refuses=%d" % (n, sum(1 for p in phases if p[4] in ("absence", "ouvert")), ouverts, illisibles))
    if n < PLANCHER_CROISE_G1:
        fautes.append("%d phase(s) comparée(s), sous le plancher déclaré %d" % (n, PLANCHER_CROISE_G1))
    if ouverts < 1 or illisibles < 1:
        fautes.append("comparaison à vide : %d refus pour registre ouvert, %d phases illisibles" % (ouverts, illisibles))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else "%d phases comparées (dont %d refus pour registre ouvert, %d phases illisibles jamais refusées)" % (n, ouverts, illisibles))


# Table de canary d'un dossier de scripts jetable (R-CANG-G1) : le hook livré TEL QUEL, ou G6, G5 et G1 armés.
def controle_cang_g1(ctx, script):
    """R-CANG-G1 : le canary rend 3 (sain, cas G1 compris) sur l'état livré, sur une copie où G6, G5 et G1 sont armed,
    et signale (code 0, une ligne qui nomme `G1-sans-cadrage`) quand evaluer_g1 est neutralisé."""
    dossier = _dossier(ctx, script)
    fautes = []
    d = scripts_canary(ctx, dossier, "observe", tel_quel=True)
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("état livré : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    d = scripts_canary(ctx, dossier, "armed", armes=("G6", "G5", "G1"))
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("G6, G5 et G1 armed : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    neutre, raison = make_hook_mutant(ctx, "G1-NEUTRE", "# gates-a-verdict", 'GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G7", evaluer_g7), ("ROLE", evaluer_role))  # gates-a-verdict')
    if neutre is None:
        fautes.append("mutant du hook invalide : " + raison)
    else:
        for valeur, armes in (("observe", ()), ("armed", ("G6", "G5", "G1"))):
            d = scripts_canary(ctx, dossier, valeur, hook=os.path.join(neutre, "planning-hook.sh"), armes=armes)
            rc, out, err = lancer_canary_dossier(ctx, d)
            lignes = [l for l in out.decode("utf-8", "replace").split("\n") if l]
            if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "G1-sans-cadrage" not in lignes[0] or "G6-principal" in lignes[0]:
                fautes.append("evaluer_g1 neutralisé (%s) : rc=%d %s" % (valeur, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "canary sain (code 3) sur l'état livré et sur G6, G5 et G1 armed ; evaluer_g1 neutralisé : une ligne qui nomme G1-sans-cadrage, observe comme armed")


# --- 45-07 : G7, pas de planning orphelin sous un lab adhérent (GATE-07, spec §2 D-05) ---------------------------------
G7_LAB = "g7-adherent"
G7_NU = "zone/nu/.planning/config.json"
G7_MOTIF = "exige un .claude/ habité"
# Les onze noms du détecteur, ÉCRITS ICI indépendamment du hook : un dossier `code-<nom>/` du banc porte le marqueur du même nom.
G7_MARQUEURS = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle", "build.gradle.kts",
                "composer.json", "Gemfile", "tsconfig.json", "Package.swift")


def _g7(ctx, hook, outil, rel, lab=G7_LAB, agent=None, extra_env=None):
    return _g5(ctx, hook, outil, rel, agent=agent, lab=lab, extra_env=extra_env)


def controle_g7_01(ctx, script):
    """Copie observe : Write de `zone/nu/.planning/config.json` sous un lab adhérent -> silence, code 0, UNE ligne gate=G7 au journal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g7-01")
    rc, out, err = _g7(ctx, d, "Write", G7_NU, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    for motif in ("  gate=G7  ", "  chemin=" + G7_NU + "  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : silence, code 0, une ligne gate=G7 (chemin, outil) au journal d'observation"


def controle_g7_02(ctx, script):
    """Copie armée : Write et NotebookEdit d'un .planning/ à créer dans un dossier nu (existant ou à créer, tout rôle) -> un deny
    `[planning-core] G7 :` qui nomme le dossier X."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for outil, rel, agent, x in (("Write", G7_NU, None, "zone/nu"), ("NotebookEdit", "zone/nu/.planning/x.ipynb", None, "zone/nu"),
                                 ("Write", G7_NU, "general-purpose", "zone/nu"),
                                 ("Write", "zone/nouveau/profond/.planning/config.json", None, "zone/nouveau/profond")):
        n += 1
        raison, detail = _raison_deny(*_g7(ctx, d, outil, rel, agent=agent))
        if raison is None:
            fautes.append("%s %s -> %s" % (outil, rel, detail))
        elif not raison.startswith("[planning-core] G7 :") or ("dans %s exige" % x) not in raison or G7_MOTIF not in raison:
            fautes.append("%s %s : raison %s" % (outil, rel, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G7 (Write et NotebookEdit, fil principal et agent, dossier existant ou à créer) qui nomment X" % n)


def controle_g7_03(ctx, script):
    """Copie armée : un .planning/ créé dans un dossier qui porte un marqueur de code -> aucun refus, un cas par marqueur (les onze
    noms, un dossier *.xcodeproj, un lien vers un fichier) ; un FAUX marqueur (dossier nommé package.json, lien cassé, fichier
    nommé App.xcodeproj) ne compte pas."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for dossier in ["code-" + m for m in G7_MARQUEURS] + ["code-App.xcodeproj", "code-lien"]:
        n += 1
        rc, out, err = _g7(ctx, d, "Write", "zone/%s/.planning/config.json" % dossier)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G7" in out:
            fautes.append("%s -> %s %s" % (dossier, classer(rc, out), court(out)))
    for dossier in ("code-dossier", "code-casse", "code-fichier-xcode"):
        raison, detail = _raison_deny(*_g7(ctx, d, "Write", "zone/%s/.planning/config.json" % dossier))
        if raison is None or not raison.startswith("[planning-core] G7 :"):
            fautes.append("faux marqueur %s -> %s" % (dossier, detail if raison is None else raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d marqueurs laissent passer (onze noms, *.xcodeproj, lien vers un fichier) ; dossier nommé package.json, lien cassé et fichier nommé App.xcodeproj refusés" % n)


def controle_g7_04(ctx, script):
    """Copie armée : écriture dans un .planning/ qui existe déjà, Edit, création sous un lab dev, création dans un dossier sans aucun
    ancêtre planifié -> aucun refus de G7."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for outil, rel in (("Write", "zone/existant/.planning/notes.md"), ("Write", ".planning/notes.md"), ("Edit", G7_NU)):
        rc, out, err = _g7(ctx, d, outil, rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G7" in out:
            fautes.append("%s %s -> %s %s" % (outil, rel, classer(rc, out), court(out)))
    rc, out, err = _g7(ctx, d, "Write", G7_NU, lab="g7-dev")
    if rc != 0 or out != b"" or err:
        fautes.append("lab dev -> rc=%d stdout=%s" % (rc, court(out)))
    libre = dossier_neuf(ctx, "g7-libre")
    brut = payload("Write", entree_outil("Write", os.path.join(libre, "nu", ".planning", "config.json")), libre)
    rc, out, err = ctx.lancer("A", brut, cwd=libre, dossier=d)
    if rc != 0 or out != b"" or err:
        fautes.append("dossier sans ancêtre planifié -> rc=%d stdout=%s" % (rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "aucun refus : .planning/ existant (imbriqué et racine), Edit, lab dev (stdout d'octet vide), dossier sans ancêtre planifié (stdout d'octet vide)")


def marqueurs_du_detecteur(texte):
    """(mots de la boucle `for f in … ; do` qui teste les fichiers, glob du projet Xcode) extraits du texte de detect-gsd-engine.sh."""
    m = re.search(r"has_code_signal\(\) \{(.*?)\n\}", texte, re.S)
    if m is None:
        return None, None
    corps = m.group(1)
    boucle = re.search(r"for f in ([^;]*?); do\n\s*\[ -f ", corps, re.S)
    xcode = re.search(r"for f in \./(\*\.xcodeproj); do \[ -d ", corps)
    if boucle is None or xcode is None:
        return None, None
    return boucle.group(1).replace("\\\n", " ").split(), xcode.group(1)


def controle_g7_05(ctx, script):
    """R-G7-05 : l'ensemble des marqueurs extrait du TEXTE de detect-gsd-engine.sh (mots de la boucle `for f in … ; do`, motif
    `*.xcodeproj`) est égal à MARQUEURS_CODE ∪ {*.xcodeproj} du hook ; les onze noms écrits par la suite (G7_MARQUEURS) aussi."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    ns = charger_module(chemin)
    detecteur = os.path.join(ctx.scripts_dir, "detect-gsd-engine.sh")
    mots, xcode = marqueurs_du_detecteur(open(detecteur, encoding="utf-8").read())
    if mots is None:
        return False, "extraction vide du texte du détecteur (rouge, jamais un vert à vide)"
    hook = set(ns["MARQUEURS_CODE"]) | {"*" + ns["SUFFIXE_XCODEPROJ"]}
    det = set(mots) | {xcode}
    fautes = []
    if len(mots) != len(set(mots)) or len(mots) != 11:
        fautes.append("le détecteur porte %d mot(s) pour %d distinct(s) (attendu 11)" % (len(mots), len(set(mots))))
    if hook != det:
        fautes.append("écart : seulement dans le hook %s, seulement dans le détecteur %s" % (sorted(hook - det), sorted(det - hook)))
    if set(G7_MARQUEURS) | {"*.xcodeproj"} != det:
        fautes.append("la liste de la suite diffère du détecteur : %s" % sorted((set(G7_MARQUEURS) | {"*.xcodeproj"}) ^ det))
    return (not fautes), ("; ".join(fautes) if fautes else "%d marqueurs, MARQUEURS_CODE ∪ {*.xcodeproj} = l'ensemble extrait du texte de detect-gsd-engine.sh" % len(det))


G7_HABITE = (  # (dossier du banc, habité selon le prédicat littéral de P45-D-14, libellé) : agent ET mémoire
    ("hab-ok", True, "agents/a.md et memory/m.md"), ("hab-profond", True, "agents/a.md et memory/ sous deux sous-dossiers"),
    ("hab-agents", False, "agents seuls"), ("hab-memoire", False, "mémoire seule"),
    ("hab-agent-memory", False, "agent-memory/ seul, sans fichier"), ("hab-vide", False, ".claude/ vide"))
G7_NON_REGULIERS = (  # (dossier du banc, libellé) : fichiers NON réguliers, jamais comptés
    ("hab-lien", "agents/x.md en lien symbolique (memory/m.md régulier)"),
    ("hab-memoire-lien", "memory/m.md en lien symbolique (agents/a.md régulier)"),
    ("hab-memoire-vide", "memory/ sans fichier régulier (agents/a.md régulier)"),
    ("hab-txt", "agents/notes.txt n'est pas un agents/*.md (memory/m.md régulier)"))


def cas_habite(ctx, script):
    """[(dossier, libellé, attendu, obtenu)] du prédicat « habité » sur copie armée : `passage` ou `refus` (un deny de G7), sinon l'écart."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lignes = []
    for dossier, habite, libelle in G7_HABITE:
        lignes.append((dossier, libelle, "passage" if habite else "refus", _verdict_g7(ctx, d, dossier)))
    return lignes


def _verdict_g7(ctx, hook, dossier):
    rc, out, err = _g7(ctx, hook, "Write", "zone/%s/.planning/config.json" % dossier)
    v = classer(rc, out)
    if err:
        return "stderr " + court(err)
    if v == "deny":
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
        return "refus" if raison.startswith("[planning-core] G7 :") and ("dans zone/%s exige" % dossier) in raison else "deny " + raison
    return "passage" if v in ("silence", "avertit") and b"[planning-core] G7" not in out else v + " " + court(out)


def controle_g7_06(ctx, script):
    """R-G7-06 : le prédicat littéral de P45-D-14 (agent ET mémoire) : agents et mémoire -> passage ; agents seuls, mémoire seule,
    agent-memory/ seul, .claude/ vide -> refus."""
    cas = cas_habite(ctx, script)
    fautes = ["%s (%s) : attendu %s, obtenu %s" % (dossier, libelle, attendu, obtenu) for dossier, libelle, attendu, obtenu in cas if attendu != obtenu]
    return (not fautes), ("; ".join(fautes) if fautes else "%d cas conformes au prédicat littéral : agents ET mémoire passent, agents seuls, mémoire seule, agent-memory/ seul et .claude/ vide sont refusés" % len(cas))


def controle_g7_07(ctx, script):
    """R-G7-07 : seuls les fichiers RÉGULIERS comptent — un agents/x.md ou un memory/m.md en lien symbolique, un memory/ sans fichier
    régulier, un agents/*.txt ne comptent pas (refus)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = ["%s (%s) : attendu refus, obtenu %s" % (dossier, libelle, obtenu) for dossier, libelle in G7_NON_REGULIERS
              for obtenu in [_verdict_g7(ctx, d, dossier)] if obtenu != "refus"]
    return (not fautes), ("; ".join(fautes) if fautes else "%d cas refusés : lien symbolique (agent ou mémoire), memory/ sans fichier régulier, agents/*.txt" % len(G7_NON_REGULIERS))


def controle_g7_08(ctx, script):
    """R-G7-08 : dérogation G7 active pour `zone/nu/.planning/config.json` : passage cité et consommé ; le second Write est refusé."""
    lab = lab_frais(ctx, G7_LAB)
    rc, out, err = deroger(ctx, lab, None, gate="G7", chemins=(G7_NU,))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", G7_NU)
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "G7", "willy", "AskUserQuestion session principale", "2026-09-30", G7_NU) if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=G7  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    r2 = ecrire_dans(ctx, hook, lab, "Write", G7_NU)
    if classer(r2[0], r2[1]) != "deny":
        return False, "second Write : " + classer(r2[0], r2[1])
    return True, "dérogation G7 : premier Write passe et cité, dérogation consommée, second Write refusé"


def compte_g7(ctx, script):
    """(faux refus, faux accept, nombre d'écritures) du banc G7 (labs g7-adherent et g7-dev) rejoué sur la copie ARMÉE de `script` : un
    doit-passer refusé est un faux refus, un doit-refuser non refusé un faux accept, un silence non silencieux un faux accept."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    _, labs, chemins = labs_banc(ctx)
    faux_refus = faux_accept = n = 0
    for nom in (G7_LAB, "g7-dev"):
        for e in labs[nom]["ecritures"]:
            brut, cwd = entree_de_ecriture(e, chemins[nom])
            rc, out, err = ctx.lancer("A", brut, cwd=cwd, dossier=d)
            _bon, obtenu = juger(e["attendu"], e["gate"], rc, out)
            n += 1
            if e["attendu"] == "doit-passer" and obtenu == "deny":
                faux_refus += 1
            elif e["attendu"] == "doit-refuser" and obtenu != "deny":
                faux_accept += 1
            elif e["attendu"] == "silence" and obtenu != "silence":
                faux_accept += 1
    return faux_refus, faux_accept, n


def controle_g7_09(ctx, script):
    """R-G7-09 : banc G7 sur copie armée -> zéro faux refus, zéro faux accept, sur un banc non vide (36 écritures au plus bas)."""
    fr, fa, n = compte_g7(ctx, script)
    if n < 30:
        return False, "banc G7 trop petit : %d écriture(s) (plancher 30, jamais un vert à vide)" % n
    return (fr == 0 and fa == 0), "COMPTE G7 faux-refus=%d faux-accept=%d sur %d écritures" % (fr, fa, n)


def controle_cang_g7(ctx, script):
    """R-CANG-G7 : le canary rend 3 (sain, cas G7 compris) sur l'état livré et sur une copie où les étapes 1 à 3 sont armées, et signale
    (code 0, une ligne qui nomme `G7-orphelin`) quand evaluer_g7 est neutralisé."""
    dossier = _dossier(ctx, script)
    fautes = []
    d = scripts_canary(ctx, dossier, "observe", tel_quel=True)
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("état livré : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    d = scripts_canary(ctx, dossier, "armed", armes=("G6", "G5", "G1", "G7"))
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("étapes 1 à 3 armed : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    neutre, raison = make_hook_mutant(ctx, "G7-NEUTRE", "# gates-a-verdict", 'GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G1", evaluer_g1), ("ROLE", evaluer_role))  # gates-a-verdict')
    if neutre is None:
        fautes.append("mutant du hook invalide : " + raison)
    else:
        for valeur, armes in (("observe", ()), ("armed", ("G6", "G5", "G1", "G7"))):
            d = scripts_canary(ctx, dossier, valeur, hook=os.path.join(neutre, "planning-hook.sh"), armes=armes)
            rc, out, err = lancer_canary_dossier(ctx, d)
            lignes = [l for l in out.decode("utf-8", "replace").split("\n") if l]
            if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "G7-orphelin" not in lignes[0] or "G6-principal" in lignes[0] or "G1-sans-cadrage" in lignes[0]:
                fautes.append("evaluer_g7 neutralisé (%s) : rc=%d %s" % (valeur, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "canary sain (code 3) sur l'état livré et sur les étapes 1 à 3 armed ; evaluer_g7 neutralisé : une ligne qui nomme G7-orphelin, observe comme armed")


# --- 45-08 : le hook par rôle (GATE-09 ; P45-D-04, P45-D-05, P45-D-05b, P45-D-11, P45-D-12a) ------------------------------
ROLE_LAB = "role-adherent"
ROLE_DEV = "role-dev"
ROLE_LIVRABLE = "livrables/x.md"
ROLE_MOTIF = "[planning-core] ROLE :"
TEXTE_JUGE = "---\nname: %s\ndescription: juge de la suite\ntools: Read, Glob, Grep\ndisallowedTools: Write, Edit\nomitClaudeMd: true\n---\nCorps.\n"
TEXTE_PRODUCTEUR = "---\nname: %s\ndescription: producteur de la suite\ntools: Read, Write\n---\nCorps.\n"


def _role(ctx, hook, outil, rel, agent=None, lab=ROLE_LAB, extra_env=None, entree=None):
    return _g5(ctx, hook, outil, rel, agent=agent, lab=lab, extra_env=extra_env, entree=entree)


def verdict_role(rc, out, err):
    """`refus` (un deny dont la raison commence par `[planning-core] ROLE :`), `passage` (silence ou avertissement sans verdict de rôle),
    sinon l'écart décrit."""
    if err:
        return "stderr " + court(err)
    v = classer(rc, out)
    if v == "deny":
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
        return "refus" if raison.startswith(ROLE_MOTIF) else "deny " + raison
    if v in ("silence", "avertit"):
        return "passage" if b"[planning-core] ROLE" not in out else v + " " + court(out)
    return v + " " + court(out)


def home_de_suite(ctx, nom, agents=(), plugins=()):
    """Dossier `HOME` jetable : `agents` = [(fichier, texte)] sous `.claude/agents/`, `plugins` = [(chemin relatif, texte)] sous
    `.claude/plugins/`."""
    home = dossier_neuf(ctx, "home-" + nom)
    for fichier, texte in agents:
        ecrire(os.path.join(home, ".claude", "agents", fichier), texte)
    for rel, texte in plugins:
        ecrire(os.path.join(home, ".claude", "plugins", rel), texte)
    return home


def controle_role_01(ctx, script):
    """Copie observe : Write d'un livrable par un juge du lab -> code 0, stdout vide ou avertissement de G2 seulement, UNE ligne gate=ROLE
    au journal (chemin, outil), aucun refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-role-01")
    rc, out, err = _role(ctx, d, "Write", ROLE_LIVRABLE, agent="juge-test", extra_env={"XDG_CACHE_HOME": cache})
    v = classer(rc, out)
    if rc != 0 or err or v not in ("silence", "avertit") or b"[planning-core] ROLE" in out:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if v == "avertit" and "G2" not in contexte_de(out):
        return False, "avertissement qui n'est pas celui de G2 : " + court(out)
    lignes = lignes_journal(cache)
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1) : %s" % (len(lignes), lignes)
    for motif in ("  gate=ROLE  ", "  chemin=" + ROLE_LIVRABLE + "  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : code 0, aucun refus (%s), une ligne gate=ROLE (chemin, outil) au journal" % v


def controle_role_02(ctx, script):
    """Copie armed : Write, Edit et NotebookEdit par un juge du lab, sous `juge-test`, `Juge_Test`, `juge test`, `JUGE-TEST`, et par le juge
    dont le name: est `Juge_Mixte` -> UN deny `[planning-core] ROLE :` (juge, poser-verdict.sh)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for outil in ("Write", "Edit", "NotebookEdit"):
        for agent in ("juge-test", "Juge_Test", "juge test", "JUGE-TEST", "juge-mixte", "JUGE_MIXTE", "Juge Mixte"):
            n += 1
            raison, detail = _raison_deny(*_role(ctx, d, outil, ROLE_LIVRABLE, agent=agent))
            if raison is None:
                fautes.append("%s agent=%s -> %s" % (outil, agent, detail))
            elif not raison.startswith(ROLE_MOTIF) or "est un juge" not in raison or "poser-verdict.sh" not in raison or agent not in raison:
                fautes.append("%s agent=%s : raison %s" % (outil, agent, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus de rôle (trois outils, casse et séparateurs, name: en casse mixte), raison « juge … poser-verdict.sh »" % n)


def _sans_agent_id(ctx, hook, outil, rel, agent_type, lab=ROLE_LAB):
    """Payload portant agent_type mais PAS agent_id (le fil principal lancé avec --agent, par exemple)."""
    _, _, chemins = labs_banc(ctx)
    racine = chemins[lab]
    obj = json.loads(payload(outil, entree_outil(outil, os.path.join(racine, rel)), racine, agent_type=agent_type).decode("utf-8"))
    del obj["agent_id"]
    return ctx.lancer("A", json.dumps(obj).encode("utf-8"), cwd=racine, dossier=hook)


def controle_role_03(ctx, script):
    """Copie armed : le même Write au fil principal (sans agent_id ni agent_type, ou avec agent_type seul), par un agent_type inconnu, par
    `plugin-x:agent-y` non résolu -> aucun refus de rôle (la ligne « Tous » seulement)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    cas = (("fil principal", _role(ctx, d, "Write", ROLE_LIVRABLE)),
           ("agent_type sans agent_id", _sans_agent_id(ctx, d, "Write", ROLE_LIVRABLE, "juge-test")),
           ("agent inconnu", _role(ctx, d, "Write", ROLE_LIVRABLE, agent="agent-inconnu")),
           ("plugin non résolu", _role(ctx, d, "Write", ROLE_LIVRABLE, agent="plugin-x:agent-y")),
           ("juge du compte sans HOME qui le porte", _role(ctx, d, "Write", ROLE_LIVRABLE, agent="juge-compte-absent")))
    for etiquette, r in cas:
        n += 1
        v = verdict_role(*r)
        if v != "passage":
            fautes.append("%s -> %s" % (etiquette, v))
    return (not fautes), ("; ".join(fautes) if fautes else "%d cas sans refus de rôle : fil principal, agent_type seul, agent inconnu, agent de plugin non résolu" % n)


def controle_role_04(ctx, script):
    """Résolution (P45-D-05b) sur copie armed : le lab gagne sur le compte, deux définitions de rôles différents au même niveau = inconnu,
    deux définitions du même rôle = ce rôle, name: absent = repli sur le nom de fichier, niveau du compte, niveau du plugin (segment du
    chemin, casse et séparateurs normalisés)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    home = home_de_suite(ctx, "role-04",
                         agents=[("double.md", TEXTE_PRODUCTEUR % "double"), ("juge-compte.md", TEXTE_JUGE % "juge-compte"),
                                 ("jumeau-a.md", TEXTE_JUGE % "jumeau"), ("jumeau-b.md", TEXTE_JUGE % "jumeau")],
                         plugins=[("cache/mp/monplugin/1.0/agents/juge-plugin.md", TEXTE_JUGE % "juge-plugin"),
                                  ("cache/mp/monplugin/1.0/agents/producteur-plugin.md", TEXTE_PRODUCTEUR % "producteur-plugin"),
                                  ("cache/mp/autre-chose/1.0/agents/juge-ailleurs.md", TEXTE_JUGE % "juge-ailleurs")])
    cas = (("double", "refus"), ("ambigu", "passage"), ("sans-nom", "refus"), ("juge-compte", "refus"), ("jumeau", "refus"),
           ("monplugin:juge-plugin", "refus"), ("MonPlugin:Juge_Plugin", "refus"), ("monplugin:producteur-plugin", "passage"),
           ("monplugin:absent", "passage"), ("autreplugin:juge-plugin", "passage"), ("juge-ailleurs", "passage"),
           ("autre-chose:juge-plugin", "passage"), ("juge-plugin", "passage"))
    fautes = []
    for agent, attendu in cas:
        v = verdict_role(*_role(ctx, d, "Write", ROLE_LIVRABLE, agent=agent, extra_env={"HOME": home}))
        if v != attendu:
            fautes.append("agent=%s : attendu %s, obtenu %s" % (agent, attendu, v))
    return (not fautes), ("; ".join(fautes) if fautes else "%d résolutions conformes : lab avant compte, ambigu = inconnu, même rôle = ce rôle, repli sur le nom de fichier, niveau du compte, niveau du plugin" % len(cas))


def controle_role_05(ctx, script):
    """Copie armed : dans un lab dev qui porte le même juge, Write, Edit, NotebookEdit, Bash, Agent et Task -> stdout d'octet vide, code 0
    (P45-D-04 : zéro régression dev)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    dispatch = {"description": "d", "prompt": "p", "subagent_type": "vf-crafter"}
    for outil, entree in (("Write", None), ("Edit", None), ("NotebookEdit", None), ("Bash", None), ("Agent", dispatch), ("Task", dispatch)):
        for agent in ("juge-test", "worker-vide", None):
            n += 1
            rc, out, err = _role(ctx, d, outil, ROLE_LIVRABLE, agent=agent, lab=ROLE_DEV, entree=entree)
            if rc != 0 or out != b"" or err:
                fautes.append("%s agent=%s -> rc=%d stdout=%s stderr=%s" % (outil, agent, rc, court(out), court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "%d appels d'un lab dev (six outils, juge, worker, fil principal) : stdout d'octet vide, code 0" % n)


def _classer(ctx, script, chemin):
    p = subprocess.run(["bash", os.path.join(_dossier(ctx, script), "planning-hook.sh"), "--classer", chemin],
                       stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
    return p.returncode, p.stdout, p.stderr


def controle_role_06(ctx, script):
    """`--classer` sur une définition au frontmatter jamais refermé -> `illisible` (une ligne JSON, code 0) ; sur un juge et un manager du lab
    -> `juge` et `manager` ; le hook traite l'agent illisible en inconnu (copie armed : aucun refus de rôle)."""
    _, _, chemins = labs_banc(ctx)
    agents = os.path.join(chemins[ROLE_LAB], ".claude", "agents")
    fautes = []
    for nom, role in (("abime.md", "illisible"), ("juge-test.md", "juge"), ("manager-test.md", "manager"), ("producteur-test.md", "producteur"), ("worker-vide.md", "worker")):
        rc, out, err = _classer(ctx, script, os.path.join(agents, nom))
        try:
            obtenu = json.loads(out.decode("utf-8").strip())
        except ValueError:
            fautes.append("%s : sortie non JSON : %s" % (nom, court(out)))
            continue
        if rc != 0 or err or len(out.splitlines()) != 1 or obtenu.get("role") != role or sorted(obtenu.keys()) != ["allowlist", "disallowed", "role"]:
            fautes.append("%s : attendu %s, obtenu rc=%d %s stderr=%s" % (nom, role, rc, court(out), court(err)))
    rc, out, err = _classer(ctx, script, os.path.join(agents, "absent.md"))
    if rc != 0 or json.loads(out.decode("utf-8")).get("role") != "illisible":
        fautes.append("fichier absent : rc=%d %s" % (rc, court(out)))
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    v = verdict_role(*_role(ctx, d, "Write", ROLE_LIVRABLE, agent="abime"))
    if v != "passage":
        fautes.append("agent à définition illisible : %s (attendu passage, traité en inconnu)" % v)
    return (not fautes), ("; ".join(fautes) if fautes else "--classer : abime = illisible, juge-test = juge, manager-test = manager, producteur-test = producteur, worker-vide = worker, fichier absent = illisible ; l'agent illisible est traité en inconnu")


def controle_role_07(ctx, script):
    """Erreur interne injectée dans evaluer_role (mutant sonde) : observe -> aucun refus + une ligne d'erreur au journal ; armed -> deny."""
    dossier, raison = make_hook_mutant(ctx, "ROLE-SONDE", "# role-sonde", 'raise RuntimeError("sonde")  # role-sonde')
    if dossier is None:
        return False, "mutant sonde invalide : " + raison
    cache = dossier_neuf(ctx, "cache-role-07")
    rc, out, err = _role(ctx, ctx.copie_forcee(dossier, "observe"), "Write", ".planning/notes.md", extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=ROLE  " not in lignes[0]:
        return False, "observe : rc=%d stdout=%s stderr=%s lignes=%s" % (rc, court(out), court(err), lignes)
    motif = [c for c in lignes[0].split("  ") if c.startswith("raison=")]
    if not motif or "erreur interne" not in urllib.parse.unquote(motif[0]):
        return False, "la ligne ne porte pas une raison d'erreur : " + lignes[0]
    rc, out, err = _role(ctx, ctx.copie_forcee(dossier, "armed"), "Write", ".planning/notes.md")
    if classer(rc, out) != "deny" or "erreur interne" not in json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]:
        return False, "armed : " + classer(rc, out) + " " + court(out)
    return True, "erreur interne de evaluer_role : en observe aucun refus et une ligne d'erreur au journal, en armed un deny (fail-closed)"


def controle_role_13(ctx, script):
    """P45-D-12a : `HOME` est l'entrée déclarée de la résolution des agents du COMPTE, et d'elle seule. Un juge défini seulement sous
    `<HOME>/.claude/agents/` : HOME A qui le porte -> refus (copie armed) ; HOME B qui ne le porte pas -> inconnu, aucun refus ; un lab dev
    reste silencieux sous les deux ; le verdict de G5 et de G6 d'un même payload et l'état d'armement (la copie à ARMEMENT_ROLE observe
    reste observe) ne changent pas ; XDG_CACHE_HOME, CLAUDE_PROJECT_DIR et TMPDIR ne changent pas la résolution."""
    dossier = _dossier(ctx, script)
    d_arm, d_obs = ctx.copie_forcee(dossier, "armed"), ctx.copie_forcee(dossier, "observe")
    home_a = home_de_suite(ctx, "role-13-a", agents=[("juge-compte.md", TEXTE_JUGE % "juge-compte")])
    home_b = home_de_suite(ctx, "role-13-b")
    fautes = []
    # (1) la résolution suit HOME
    for etiquette, home, attendu in (("HOME A", home_a, "refus"), ("HOME B", home_b, "passage")):
        v = verdict_role(*_role(ctx, d_arm, "Write", ROLE_LIVRABLE, agent="juge-compte", extra_env={"HOME": home}))
        if v != attendu:
            fautes.append("copie armed, %s : attendu %s, obtenu %s" % (etiquette, attendu, v))
    # (2) l'adhésion ne suit pas HOME : un lab dev reste silencieux, sous les deux
    for etiquette, home in (("HOME A", home_a), ("HOME B", home_b)):
        rc, out, err = _role(ctx, d_arm, "Write", ROLE_LIVRABLE, agent="juge-compte", lab=ROLE_DEV, extra_env={"HOME": home})
        if rc != 0 or out != b"" or err:
            fautes.append("lab dev, %s : rc=%d stdout=%s" % (etiquette, rc, court(out)))
    # (3) le verdict de G5 et de G6 (fil principal) est le même octet pour octet, sous les deux HOME
    for outil, rel in (("Write", VERDICT_REL), ("Write", ".planning/STATE.md"), ("Edit", ".planning/STATE.md")):
        ra = _role(ctx, d_arm, outil, rel, extra_env={"HOME": home_a})
        rb = _role(ctx, d_arm, outil, rel, extra_env={"HOME": home_b})
        if ra != rb or classer(ra[0], ra[1]) != "deny":
            fautes.append("%s %s : verdict différent sous HOME A et B (%s / %s)" % (outil, rel, classer(ra[0], ra[1]), classer(rb[0], rb[1])))
    # (4) l'armement ne suit pas HOME : la copie observe reste observe (silence) sous les deux, une ligne au journal seulement sous HOME A
    for etiquette, home, lignes_attendues in (("HOME A", home_a, 1), ("HOME B", home_b, 0)):
        cache = dossier_neuf(ctx, "cache-role-13")
        rc, out, err = _role(ctx, d_obs, "Write", ".planning/notes.md", agent="juge-compte", extra_env={"HOME": home, "XDG_CACHE_HOME": cache})
        lignes = [l for l in lignes_journal(cache) if "  gate=ROLE  " in l]
        if rc != 0 or out != b"" or err or len(lignes) != lignes_attendues:
            fautes.append("copie observe, %s : rc=%d stdout=%s, %d ligne(s) gate=ROLE (attendu %d)" % (etiquette, rc, court(out), len(lignes), lignes_attendues))
    # (5) les autres variables d'environnement ne changent pas la résolution, même quand elles désignent le dossier qui porte le juge
    for nom in ("XDG_CACHE_HOME", "CLAUDE_PROJECT_DIR", "TMPDIR"):
        v = verdict_role(*_role(ctx, d_arm, "Write", ROLE_LIVRABLE, agent="juge-compte", extra_env={"HOME": home_b, nom: home_a}))
        if v != "passage":
            fautes.append("HOME B et %s=HOME A : %s (attendu passage)" % (nom, v))
        v = verdict_role(*_role(ctx, d_arm, "Write", ROLE_LIVRABLE, agent="juge-compte", extra_env={"HOME": home_a, nom: home_b}))
        if v != "refus":
            fautes.append("HOME A et %s=HOME B : %s (attendu refus)" % (nom, v))
    return (not fautes), ("; ".join(fautes) if fautes else "HOME change la résolution d'un agent du compte (A : refus, B : inconnu), jamais l'adhésion (lab dev silencieux), le verdict de G5 et de G6 ni l'armement (copie observe) ; XDG_CACHE_HOME, CLAUDE_PROJECT_DIR et TMPDIR ne la changent pas")


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


def sec_env_statique(ctx):
    bon, detail = controle_env_statique(ctx, ctx.hook)
    ok("R-ENV-02 garde statique : " + detail) if bon else ko(
        "R-ENV-02", "aucune lecture d'environnement dans le cœur Python de planning-hook.sh (expanduser et expandvars compris) ; lanceur : TMPDIR sur la ligne du mktemp, XDG_CACHE_HOME et HOME sur la ligne d'appel du cœur, une fois chacune", "aucune faute", detail)


def sec_g5(ctx):
    for ident, ctrl, titre in (
            ("R-G5-01", controle_g5_01, "Write de VERDICT.md sur copie observe"),
            ("R-G5-02", controle_g5_02, "le même Write sur copie armed"),
            ("R-G5-03", controle_g5_03, "Edit, NotebookEdit, casse, profondeur, tout rôle : refusés sur copie armed"),
            ("R-G5-04", controle_g5_04, "PLAN.md, nom voisin, livrable hors .planning/, lab dev : aucun refus"),
            ("R-G5-05", controle_g5_05, "erreur interne de G5 : observe journalise, armed refuse"),
            ("R-G5-06", controle_g5_06, "le journal ne porte jamais le contenu écrit")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_g6(ctx):
    for ident, ctrl, titre in (
            ("R-G6-01", controle_g6_01, "Write d'un fichier généré sur copie observe"),
            ("R-G6-02", controle_g6_02, "chaque fichier généré, Write et Edit, tout rôle : refusé sur copie armed"),
            ("R-G6-03", controle_g6_03, "compartiments, plans du modèle, notes : aucun refus de G6"),
            ("R-G6-04", controle_g6_04, "lab dev : stdout d'octet vide"),
            ("R-G6-05", controle_g6_05, "dérogation G6 honorée, citée et consommée")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_id(ctx):
    for ident, ctrl, titre in (
            ("R-ID-01", controle_id_01, "identité : casse, lien dur, alias, segment .., création en autre casse (G6)"),
            ("R-ID-02", controle_id_02, "identité : lien dur vers un VERDICT.md sous un autre nom (G5)"),
            ("R-ID-03", controle_id_03, "F6 : config.json ne perd pas l'adhésion cycles-v1 par un outil"),
            ("R-ID-04", controle_id_04, "F7b : le cache du recalcul est protégé"),
            ("R-ID-05", controle_id_05, "recalc-planning.sh (commande) écrit toujours, le hook n'en voit rien")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_cang(ctx):
    for ident, ctrl, titre in (
            ("R-CANG-01", controle_cang_01, "canary de session, G6 et G5 en observe"),
            ("R-CANG-02", controle_cang_02, "canary de session, G6 et G5 armed"),
            ("R-CANG-03", controle_cang_03, "canary de session, evaluer_g6 neutralisé"),
            ("R-CANG-G1", controle_cang_g1, "canary de session, cas G1-sans-cadrage"),
            ("R-CANG-G7", controle_cang_g7, "canary de session, cas G7-orphelin")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_g1(ctx):
    for ident, ctrl, titre in (
            ("R-G1-01", controle_g1_01, "Write du PLAN.md d'une phase sans CADRAGE.md sur copie observe"),
            ("R-G1-02", controle_g1_02, "le même Write et Edit sur copie armed, plan direct et sous plans/"),
            ("R-G1-03", controle_g1_03, "phase cadrée, socle v2, nom d'unité invalide, lab dev : aucun refus")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    bon, detail = controle_croise_g1(ctx, None)
    ok("R-G1-04 contrôle croisé avec recalc-planning.sh --read-only : " + detail) if bon else ko(
        "R-G1-04", "G1 refuse pour absence de CADRAGE.md <=> le recalcul rend `à cadrer` ou `hors-cadrage:*`, phase par phase des deux bancs",
        "aucune divergence", detail)
    for ident, ctrl, titre in (
            ("R-G1-05", controle_g1_05, "registre ouvert sur copie armed : le refus cite l'id de chaque ligne ouverte"),
            ("R-G1-06", controle_g1_06, "la valeur d'un statut n'est jamais jugée"),
            ("R-G1-07", controle_g1_07, "bord F5 (f5-etats) : état indéterminé jamais refusé, absence de CADRAGE.md toujours refusée"),
            ("R-G1-09", controle_g1_09, "dérogation G1 honorée, citée et consommée")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    bon, detail = controle_croise_g1_etendu(ctx, None)
    ok("R-G1-08 contrôle croisé étendu : " + detail) if bon else ko(
        "R-G1-08", "G1 refuse (absence ou registre ouvert) <=> `à cadrer`, `en cadrage`, `hors-cadrage:*`, `avant-cadrage-clos:*` ; états illisibles jamais refusés",
        "aucune divergence", detail)


def sec_g7(ctx):
    for ident, ctrl, titre in (
            ("R-G7-01", controle_g7_01, "Write d'un .planning/ à créer dans un dossier nu sur copie observe"),
            ("R-G7-02", controle_g7_02, "le même Write et NotebookEdit sur copie armed, tout rôle"),
            ("R-G7-03", controle_g7_03, "marqueur de projet de code : un cas par marqueur, faux marqueurs refusés"),
            ("R-G7-04", controle_g7_04, ".planning/ existant, Edit, lab dev, dossier sans ancêtre planifié : aucun refus")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    bon, detail = controle_g7_05(ctx, ctx.hook)
    ok("R-G7-05 contrôle croisé des marqueurs avec le texte du détecteur : " + detail) if bon else ko(
        "R-G7-05", "MARQUEURS_CODE ∪ {*.xcodeproj} du hook = l'ensemble extrait du texte de detect-gsd-engine.sh", "ensembles égaux", detail)
    for dossier, libelle, attendu, obtenu in cas_habite(ctx, None):
        print("G7-HABITE cas=%s attendu=%s obtenu=%s (%s)" % (dossier, attendu, obtenu, libelle))
    for ident, ctrl, titre in (
            ("R-G7-06", controle_g7_06, "prédicat « habité » littéral de P45-D-14 (agent ET mémoire), tableau des cas imprimé (G7-HABITE)"),
            ("R-G7-07", controle_g7_07, "fichiers réguliers seulement : lien symbolique, memory/ sans fichier, agents/*.txt ne comptent pas"),
            ("R-G7-08", controle_g7_08, "dérogation G7 honorée, citée et consommée")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_role(ctx):
    for ident, ctrl, titre in (
            ("R-ROLE-01", controle_role_01, "Write d'un livrable par un juge du lab sur copie observe"),
            ("R-ROLE-02", controle_role_02, "le même Write, Edit et NotebookEdit sur copie armed, casse et séparateurs normalisés"),
            ("R-ROLE-03", controle_role_03, "fil principal, agent inconnu, agent de plugin non résolu : aucun refus de rôle"),
            ("R-ROLE-04", controle_role_04, "résolution : lab avant compte, ambigu = inconnu, repli sur le nom de fichier, compte, plugin"),
            ("R-ROLE-05", controle_role_05, "lab dev : stdout d'octet vide pour tout rôle et tout outil"),
            ("R-ROLE-06", controle_role_06, "--classer et définition illisible traitée en inconnu"),
            ("R-ROLE-07", controle_role_07, "erreur interne de evaluer_role : observe journalise, armed refuse"),
            ("R-ROLE-13", controle_role_13, "HOME : entrée déclarée de la résolution du compte, jamais de l'adhésion ni de l'armement")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_registre(ctx):
    bon, detail = controle_registre(ctx, ctx.hook)
    ok("R-REGISTRE " + detail) if bon else ko("R-REGISTRE", "les arbres ast de lire_registre du hook et du moteur de recalcul sont identiques", "identiques", detail)


def sec_verdict(ctx):
    for ident, ctrl, titre in (
            ("R-VERDICT-01", controle_verdict_01, "création au format du gabarit, hash sha256 du PLAN.md"),
            ("R-VERDICT-02", controle_verdict_02, "tentative 1 puis +1, fichier inchangé sur refus, lien jamais suivi"),
            ("R-VERDICT-03", controle_verdict_03, "le moteur de recalcul relit tentative et hash"),
            ("R-VERDICT-04", controle_verdict_04, "refus hors lab adhérent, hors cycles, sans PLAN.md, constat invalide"),
            ("R-VERDICT-05", controle_verdict_05, "jamais vue par G5")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_derog(ctx):
    for ident, ctrl, titre in (
            ("R-DEROG-01", controle_derog_01, "dérogation valide, une ligne par chemin, journal jamais tronqué"),
            ("R-DEROG-02", controle_derog_02, "raison placeholder et champs invalides refusés"),
            ("R-DEROG-03", controle_derog_03, "encodage injectif : aucune ligne injectée"),
            ("R-DEROG-04", controle_derog_04, "dérogation honorée et citée sur copie armée"),
            ("R-DEROG-05", controle_derog_05, "usage unique"),
            ("R-DEROG-06", controle_derog_06, "sans effet en observe"),
            ("R-DEROG-07", controle_derog_07, "journal en lien symbolique"),
            ("R-DEROG-08", controle_derog_08, "aucune option liée à l'urgence")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_obs_env(ctx):
    bon, detail = controle_obs_env(ctx, None)
    ok("R-OBS-ENV " + detail) if bon else ko("R-OBS-ENV", "le journal suit XDG_CACHE_HOME puis HOME et rien d'autre ; les valeurs n'atteignent jamais l'armement ni l'adhésion", "conforme", detail)


def sec_jeton(ctx):
    bon, detail = controle_jeton(ctx, ctx.hook)
    ok("R-JETON " + detail) if bon else ko("R-JETON", "l'encodeur du journal du hook est ast-identique à _jeton_journal du moteur de recalcul", "identiques", detail)


def sec_accord(ctx):
    bon, detail = controle_accord(ctx, None)
    ok("R-ACCORD " + detail) if bon else ko("R-ACCORD", "chemin relatif : avertissement G2 en mode A <=> deny en mode C (limite h)", "accord des deux couches", detail)


def sec_banc(ctx):
    ordre, labs, chemins = labs_banc(ctx)
    compte = {}
    faux = {}  # gate -> [faux refus, faux accept] du banc, rejoué sur copie armée
    tout_ok = True
    for nom in ordre:
        for e in labs[nom]["ecritures"]:
            brut, cwd = entree_de_ecriture(e, chemins[nom])
            dossier = ctx.copie_forcee(ctx.scripts_dir, "armed") if e["armee"] else None
            rc, out, err = ctx.lancer("A", brut, cwd=cwd, dossier=dossier)
            bon, obtenu = juger(e["attendu"], e["gate"], rc, out)
            etiquette = "BANC %s %s %s%s%s%s :: %s %s" % (nom, e["outil"], e["chemin"], (" agent=" + e["agent"]) if e["agent"] else "", " armee" if e["armee"] else "", (" " + e["commande"]) if e["commande"] else "", e["attendu"], e["gate"] or "")
            if bon and not err:
                ok(etiquette.strip())
            else:
                tout_ok = False
                ko(etiquette.strip(), "écriture du banc rejouée par la commande enregistrée", e["attendu"], obtenu + " " + court(out) + " " + court(err))
            compte.setdefault(e["gate"], {}).setdefault(e["attendu"], 0)
            compte[e["gate"]][e["attendu"]] += 1
            if e["attendu"] == "doit-passer" and obtenu == "deny":
                faux.setdefault(e["gate"], [0, 0])[0] += 1
            elif e["attendu"] == "doit-refuser" and obtenu != "deny":
                faux.setdefault(e["gate"], [0, 0])[1] += 1
    for gate in ("G2",):
        c = compte.get(gate, {})
        print("COUVERTURE %s avertit=%d silence=%d" % (gate, c.get("avertit", 0), c.get("silence", 0)))
        if c.get("avertit", 0) < 1 or c.get("silence", 0) < 1:
            ko("COUVERTURE " + gate, "au moins un cas `avertit` et un cas `silence` pour " + gate, ">= 1 chacun", str(c))
        else:
            ok("COUVERTURE %s : %d avertit, %d silence" % (gate, c["avertit"], c["silence"]))
    for gate in ("G5", "G6", "G1", "G7", "ROLE"):
        c = compte.get(gate, {})
        print("COUVERTURE %s doit-refuser=%d doit-passer=%d silence=%d" % (gate, c.get("doit-refuser", 0), c.get("doit-passer", 0), c.get("silence", 0)))
        if c.get("doit-refuser", 0) < 1 or c.get("doit-passer", 0) < 1 or c.get("silence", 0) < 1:
            ko("COUVERTURE " + gate, "au moins un cas doit-refuser, un cas doit-passer et un cas silence (jumeau dev) pour " + gate, ">= 1 chacun", str(c))
        else:
            ok("COUVERTURE %s : %d doit-refuser, %d doit-passer, %d silence (0 faux refus, 0 faux accept : chaque cas est conforme)" % (gate, c["doit-refuser"], c["doit-passer"], c["silence"]))
    # comptes du banc, par gate de l'étape 1 (P45-D-03b : l'armement exige 0 et 0)
    for gate in ("G5", "G6", "G1", "G7", "ROLE"):
        fr, fa = faux.get(gate, [0, 0])
        print("COMPTE %s faux-refus=%d faux-accept=%d" % (gate, fr, fa))
    if faux.get("G1", [0, 0]) == [0, 0] and compte.get("G1"):
        ok("R-G1-10 banc G1 sur copie armée : COMPTE G1 faux-refus=0 faux-accept=0")
    else:
        ko("R-G1-10", "banc G1 sur copie armée : zéro faux refus, zéro faux accept", "G1 [0, 0]", "G1=%s" % (faux.get("G1"),))
    bon, detail = controle_g7_09(ctx, None)
    if bon and faux.get("G7", [0, 0]) == [0, 0] and compte.get("G7"):
        ok("R-G7-09 banc G7 sur copie armée : COMPTE G7 faux-refus=0 faux-accept=0 (%s)" % detail)
    else:
        ko("R-G7-09", "banc G7 sur copie armée : zéro faux refus, zéro faux accept", "G7 [0, 0]", "G7=%s ; %s" % (faux.get("G7"), detail))
    if all(faux.get(g, [0, 0]) == [0, 0] for g in ("G5", "G6")) and all(compte.get(g) for g in ("G5", "G6")):
        ok("R-ID-06 banc complet G5 + G6 sur copie armée : COMPTE G5 faux-refus=0 faux-accept=0, COMPTE G6 faux-refus=0 faux-accept=0")
    else:
        ko("R-ID-06", "banc complet G5 + G6 sur copie armée : zéro faux refus, zéro faux accept", "G5 [0, 0], G6 [0, 0]", "G5=%s G6=%s" % (faux.get("G5"), faux.get("G6")))
    # jumeau négatif : chaque lab jumeau a au moins un cas
    for nom in ordre:
        if labs[nom]["jumeau_de"] and not labs[nom]["ecritures"]:
            ko("COUVERTURE jumeau " + nom, "un lab jumeau porte des écritures", ">= 1", "0")


CTRL_FICHIER = (controle_table_02, controle_parseur, controle_env_statique, controle_jeton, controle_registre, controle_g7_05)


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
        ("ENV-STATIQUE", 'G2_MODE = "avertit"', 'G2_MODE = os.environ.get("VF_NOM_NON_LISTE_PAR_LE_TEST", "avertit")',
         "R-ENV-02", controle_env_statique),
        ("ENV-LANCEUR", 'T="$(mktemp "${TMPDIR:-/tmp}/vf-planning-hook.XXXXXX")" || exit 70',
         'T="$(mktemp "${TMPDIR:-${HOME:-/tmp}}/vf-planning-hook.XXXXXX")" || exit 70', "R-ENV-02", controle_env_statique),
        # 45-04 : entonnoir, G5, journal d'observation, encodeur, amendement de R-ENV-02
        ("G5-CASSE", 'if composants[-1].casefold() != NOM_VERDICT:  # g5-casse',
         'if composants[-1] != "VERDICT.md":  # g5-casse', "R-G5-03", controle_g5_03),
        ("G5-PERIMETRE", 'if not composants or composants[0].casefold() != ".planning":  # g5-perimetre',
         'if not composants:  # g5-perimetre', "R-G5-04", controle_g5_04),
        ("DECIDER-OBSERVE", 'if etat == "armed":  # decider-armed', 'if etat in ("armed", "observe"):  # decider-armed',
         "R-G5-01", controle_g5_01),
        ("DECIDER-ARMED", 'if etat == "armed":  # decider-armed', 'if False:  # decider-armed', "R-G5-02", controle_g5_02),
        ("OBS-CONTENU", '# obs-ligne',
         r'ligne = "{}  gate={}  lab={}  chemin={}  outil={}  raison={}  contenu={}\n".format(horodatage, verdict.gate, _jeton_journal(contexte.get("racine"), "-"), _jeton_journal(verdict.chemin_rel, "-"), _jeton_journal(contexte.get("outil"), "-"), _jeton_journal(verdict.raison, "-"), _jeton_journal(str((contexte["payload"].get("tool_input") or {}).get("content", "")), "-"))  # obs-ligne',
         "R-G5-06", controle_g5_06),
        ("JETON", 'if caractere == "%" or caractere == "=" or caractere.isspace() or not caractere.isprintable():',
         'if caractere == "%" or caractere.isspace() or not caractere.isprintable():', "R-JETON", controle_jeton),
        ("OBS-CHEMIN", 'if isinstance(xdg, str) and xdg.startswith("/"):  # obs-xdg', 'if False:  # obs-xdg',
         "R-OBS-ENV", controle_obs_env),
        ("ENV-EXPANDUSER", 'SCHEMA_ADHESION = "cycles-v1"', 'SCHEMA_ADHESION = "cycles-v1" + os.path.expanduser("~")[:0]',
         "R-ENV-02", controle_env_statique),
        ("OBS-ARMEMENT", 'etat = TABLE_ARMEMENT.get(verdict.gate)',
         'etat = "armed" if (TABLE_ARMEMENT.get(verdict.gate) == "observe" and not os.access(os.path.dirname(chemin_journal_observation(contexte.get("arg_xdg"), contexte.get("arg_home")) or "/"), os.W_OK)) else TABLE_ARMEMENT.get(verdict.gate)',
         "R-OBS-ENV", controle_obs_env),
        ("OBS-ADHESION", 'adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"]',
         'adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"] and sys.argv[3] != ""',
         "R-OBS-ENV", controle_obs_env),
        # 45-04 : dérogation nominative
        ("DEROG-PLACEHOLDER", "# derog-placeholders", 'PLACEHOLDERS = ()  # derog-placeholders', "R-DEROG-02", controle_derog_02,
         "deroger-gate.sh", "PY_DEROGER_GATE_EOF"),
        ("DEROG-INJECTIF", "# derog-encodage", 'raison_j = valeurs["raison"]  # derog-encodage', "R-DEROG-03", controle_derog_03,
         "deroger-gate.sh", "PY_DEROGER_GATE_EOF"),
        ("DEROG-UNIQUE", "# derog-consommee", 'if False:  # derog-consommee', "R-DEROG-05", controle_derog_05),
        ("DEROG-LIEN", "# derog-lien", 'return os.open(chemin, mode)  # derog-lien', "R-DEROG-07", controle_derog_07),
        # 45-04 : commande de verdict
        ("VERDICT-TENTATIVE", "# verdict-tentative", 'if False:  # verdict-tentative', "R-VERDICT-02", controle_verdict_02,
         "poser-verdict.sh", "PY_POSER_VERDICT_EOF"),
        ("VERDICT-ATOMIQUE", "# verdict-atomique", 'open(chemin_verdict, "w", encoding="utf-8").write(texte)  # verdict-atomique',
         "R-VERDICT-02", controle_verdict_02, "poser-verdict.sh", "PY_POSER_VERDICT_EOF"),
        # 45-05 : G6 et canary de l'étape 1
        ("G6-RACINE", "# g6-racine", "a_la_racine = True  # g6-racine", "R-G6-03", controle_g6_03),
        ("G6-NOMS", "# g6-noms", 'GENERES_PAR_RECALC = ("STATE.md", "INDEX.md")  # g6-noms', "R-G6-02", controle_g6_02),
        ("CANG-OBS", "# canary-observation", "if True:  # canary-observation", "R-CANG-03", controle_cang_03,
         "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF"),
        # 45-05 : identité, F6, F7b
        ("ID-SAMEFILE", "# g6-samefile", "if False:  # g6-samefile", "R-ID-01", controle_id_01),
        ("ID-SAMEFILE-G5", "# g5-samefile", "if False:  # g5-samefile", "R-ID-02", controle_id_02),
        ("ID-CASEFOLD", "# id-casefold", "if a_la_racine and nom in [n for n, _g in PROTEGES_G6.values()]:  # id-casefold",
         "R-ID-01", controle_id_01),
        ("F6", "# g6-adhesion", "return None  # g6-adhesion", "R-ID-03", controle_id_03),
        ("F7B", "# g6-noms", 'GENERES_PAR_RECALC = ("STATE.md", "INDEX.md", "cloture.log")  # g6-noms', "R-ID-04", controle_id_04),
        # 45-06 : G1
        ("G1-CADRAGE", "# g1-cadrage", "if False:  # g1-cadrage", "R-G1-02", controle_g1_02),
        ("G1-FORME", "# g1-forme", 'dossier_phase = composants[:5] if composants and composants[-1].casefold() == "plan.md" else None  # g1-forme',
         "R-G1-03", controle_g1_03),
        ("G1-PHASE", "# g1-phase", "return composants[:-1]  # g1-phase", "R-G1-02", controle_g1_02),
        ("G1-OUVERT", "# g1-ouvert", "if True:  # g1-ouvert", "R-G1-05", controle_g1_05),
        ("G1-STATUT", 'if structurante == "oui" and not (isinstance(statut, str) and statut.strip()):',
         'if structurante == "oui" and statut != "ARBITRÉ":', "R-G1-06", controle_g1_06),
        ("G1-BORD", "# g1-bord", "if registre_ok:  # g1-bord", "R-G1-07", controle_g1_07),
        ("REGISTRE", "    clos = True", "    clos = False", "R-REGISTRE", controle_registre),
        # 45-07 : G7
        ("G7-MARQUEUR", "# g7-marqueurs",
         'MARQUEURS_CODE = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle", "build.gradle.kts", "composer.json", "tsconfig.json", "Package.swift")  # g7-marqueurs',
         "R-G7-05", controle_g7_05),
        ("G7-MARQUEUR-GEMFILE", "# g7-marqueurs",
         'MARQUEURS_CODE = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle", "build.gradle.kts", "composer.json", "tsconfig.json", "Package.swift")  # g7-marqueurs',
         "R-G7-03", controle_g7_03),
        ("G7-EXISTE", "# g7-existe", "if composant.casefold() == NOM_PLANNING:  # g7-existe", "R-G7-04", controle_g7_04),
        ("G7-PERIMETRE", "sys.exit(0)  # non-adherent", "pass", "R-G7-04", controle_g7_04),
        ("G7-HABITE", "# g7-habite", "if True:  # g7-habite", "R-G7-06", controle_g7_06),
        ("G7-REGULIER", "# g7-regulier-agent", 'if nom.endswith(".md") and not nom.startswith(".") and os.path.exists(os.path.join(agents, nom)):  # g7-regulier-agent',
         "R-G7-07", controle_g7_07),
        ("G7-BANC-ACCEPT", "# g7-habite", "if True:  # g7-habite", "R-G7-09", controle_g7_09),
        ("G7-BANC-REFUS", "porte_marqueur_code(x):  # g7-marqueur", "if False:  # g7-marqueur", "R-G7-09", controle_g7_09),
        ("G7-REGULIER-MEMOIRE", "# g7-regulier-memoire", "if os.path.exists(os.path.join(dossier, nom)):  # g7-regulier-memoire", "R-G7-07", controle_g7_07),
        # 45-08 : le hook par rôle (ligne juge)
        ("ROLE-NORMALISATION", "# role-normaliser", "return nom  # role-normaliser", "R-ROLE-02", controle_role_02),
        ("ROLE-PRINCIPAL", "# role-principal",
         'role, definition = ("juge", None) if not agent_id else resoudre_agent(agent_type, racine, contexte.get("arg_home"))  # role-principal',
         "R-ROLE-03", controle_role_03),
        ("ROLE-NIVEAU", "# role-niveaux", "niveaux = [dossier_compte, dossier_lab]  # role-niveaux", "R-ROLE-04", controle_role_04),
        ("PY-ADHESION-ROLE", "sys.exit(0)  # non-adherent", "pass", "R-ROLE-05", controle_role_05),
        ("ROLE-HOME", "# role-home",
         'dossier_compte = os.path.join("/inexistant-role-home", ".claude", "agents") if avec_home else None  # role-home',
         "R-ROLE-13", controle_role_13),
        ("ROLE-HOME-ARMEMENT", 'etat = TABLE_ARMEMENT.get(verdict.gate)',
         'etat = "armed" if (verdict.gate == "ROLE" and os.path.isdir(os.path.join(contexte.get("arg_home") or "/inexistant", ".claude", "agents"))) else TABLE_ARMEMENT.get(verdict.gate)',
         "R-ROLE-13", controle_role_13),
    ]
    filtre = [f for f in os.environ.get("VF_GATES_MUTANTS", "").split(",") if f]  # facultatif : sous-chaînes d'identifiants, développement
    for entree in M:
        ident, motif, repl, cible, ctrl = entree[:5]
        if filtre and not any(f in ident for f in filtre):
            continue
        nom_script, marqueur = entree[5:7] if len(entree) > 5 else ("planning-hook.sh", "PY_PLANNING_HOOK_EOF")
        dossier, raison = make_script_mutant(ctx, nom_script, marqueur, ident, motif, repl)
        if dossier is None:
            komut(ident, "mutant du cœur valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
            continue
        chemin_mut = os.path.join(dossier, "planning-hook.sh")
        cible_script = chemin_mut if ctrl in CTRL_FICHIER else dossier
        # l'original passe le contrôle ; le mutant le rate ; le témoin reste inchangé
        original = ctrl(ctx, ctx.hook if ctrl in CTRL_FICHIER else ctx.scripts_dir)
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
    "registre": sec_registre,
    "jeton": sec_jeton,
    "verdict": sec_verdict,
    "derog": sec_derog,
    "g2": sec_g2,
    "g5": sec_g5,
    "g6": sec_g6,
    "id": sec_id,
    "cang": sec_cang,
    "g1": sec_g1,
    "g7": sec_g7,
    "role": sec_role,
    "env": sec_env,
    "obs_env": sec_obs_env,
    "env_statique": sec_env_statique,
    "accord": sec_accord,
    "banc": sec_banc,
    "mutants": sec_mutants,
}


def main():
    scripts_dir, hooks_json, banc, work, settings_lab = sys.argv[2:7]
    ctx = Ctx(scripts_dir, hooks_json or None, work, settings_lab or None)
    ctx.banc = banc
    ctx.banc_recalc = sys.argv[7] if len(sys.argv) > 7 and sys.argv[7] else None
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
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$HOOKS_JSON" "$BANC" "$WORK" "$SETTINGS_LAB" "$BANC_RECALC" > "$out" 2>&1
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

[ -f "$BANC_RECALC" ] || ko "recalc-planning-banc.txt présent" "le banc de la 44 existe sous fixtures/ (contrôle croisé de G1)" "$BANC_RECALC" "absent"

# VF_GATES_SECTIONS (facultatif, pour rejouer une partie de la suite pendant le développement) : liste de sections séparées
# par des virgules ; sans elle, toutes les sections tournent, dans l'ordre ci-dessous.
run_sections "${VF_GATES_SECTIONS:-table,parseur,registre,jeton,g2,g5,g6,id,cang,g1,g7,role,verdict,derog,env,obs_env,env_statique,accord,banc,mutants}"

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
