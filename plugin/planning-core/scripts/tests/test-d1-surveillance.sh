#!/usr/bin/env bash
# test-d1-surveillance.sh — D1, « toute écriture sur un fichier surveillé est expliquée ou tracée » (Phase 46, 46-07 ; CLOT-07, CLOT-09, CLOT-11 ;
# P46-D-07, P46-D-07a, P46-D-10, P46-D-11, P46-D-16). Le hook est rejoué PAR LA COMMANDE ENREGISTRÉE (lue dans hooks.json, sous /bin/sh -c), jamais par
# un appel direct au script (P45-D-20) ; les cas de D1 tournent sur des COPIES du hook à l'armement FORCÉ (`copie_forcee`), jamais sur l'état livré, qui
# change à chaque armement : `observe` pour tout (les écritures par outil passent, G6 ne refuse rien), ou `g6` (G6 et G5 armés, G3, G4 et G4′ restent à
# observe : un SUMMARY.md sans VERDICT.md n'est pas refusé, discipline du correctif 5c46c503). D1 n'a pas de constante d'armement.
#
# Familles :
#   R-D1-01  SessionStart d'un lab adhérent (deux unités ouvertes, une close) : `watchPaths` en chemins absolus, fichier par fichier — les cinq fichiers racine
#            et les quatre fichiers de chaque unité ouverte (SUMMARY.md encore absent compris), aucun dossier, aucun fichier de l'unité close, jamais le journal
#   R-D1-02  lab de 40 unités ouvertes : exactement 128 chemins et une ligne `genre=borne` au journal
#   R-D1-03  lab dev et ce dépôt : SessionStart, CwdChanged, FileChanged -> stdout d'octet vide, code 0, aucun fichier créé (empreinte de l'arbre identique)
#   R-D1-04  références posées au SessionStart, STATE.md réécrit hors moteur, FileChanged -> une ligne `contournement` (source=seance) puis une `reference` ;
#            un FileChanged sans changement de contenu et une première observation : aucun contournement
#   R-D1-05  copie G6 : Write et Edit de `surveillance.log` -> deny de G6 ; le recalcul ne range pas le journal « Hors modèle » (jumeau négatif : un nom
#            voisin y figure) ; FileChanged sur un fichier non surveillé (config.json hors du dossier de planning, un livrable, le journal) -> aucune ligne
# Mutants (chacun tué par un contrôle, trace assertion · attendu (original) · obtenu (mutant)) :
#   MUT-D1-ADHESION (adhésion ignorée, commande sans pré-filtre -> R-D1-03), MUT-D1-DOSSIER (le dossier de l'unité dans la liste -> R-D1-01),
#   MUT-D1-BORNE (borne retirée -> R-D1-02), MUT-D1-TRACE (aucune ligne de contournement -> R-D1-04).
# Variables : VF_D1_SECTIONS=<liste> pour ne rejouer qu'une partie (sections : base, mutants_base).
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; tout le travail fin est fait par Python (PYBIN).
# Lançable depuis tout cwd. Piège CI (`bash -e {0}`) : jamais `cmd && { … }` nu.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
HOOK="$SCRIPTS_DIR/planning-hook.sh"
HOOKS_JSON="$SCRIPTS_DIR/../hooks/hooks.json"
SETTINGS_LAB="$SCRIPTS_DIR/../settings.json"
[ -f "$HOOKS_JSON" ] || HOOKS_JSON=""
[ -f "$SETTINGS_LAB" ] || SETTINGS_LAB=""

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-d1-surveillance] python3 requis" >&2; exit 1; fi
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
cat > "$AIDES" <<'PY_AIDES_D1_EOF'
import ast
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.parse

TOKEN = "{{VF_SCRIPTS}}"
LIGNE_RE = re.compile(r"^(\S+)  genre=(\S+)  chemin=(\S+)  sha256=(\S+)  par=(\S+)  source=(\S+)$")
RACINE = ("STATE.md", "INDEX.md", "cloture.log", "derogations-gates.log", "config.json")
UNITE = ("PLAN.md", "CLOTURE.md", "VERDICT.md", "SUMMARY.md")


def okmut(ident, trace):
    print("  ✓ MUT-%s TUÉ — %s" % (ident, trace))


def komut(ident, assertion, attendu, obtenu):
    print("  ✗ MUT-%s NON TUÉ" % ident)
    print("    assertion : " + assertion)
    print("    attendu (original) : " + attendu)
    print("    obtenu (mutant)     : " + obtenu)


def ok(libelle):
    print("  ✓ " + libelle)


def ko(libelle, assertion, attendu, obtenu):
    print("  ✗ " + libelle)
    print("    assertion : " + str(assertion))
    print("    attendu   : " + str(attendu))
    print("    obtenu    : " + str(obtenu))


def court(octets, n=240):
    texte = octets.decode("utf-8", "replace") if isinstance(octets, bytes) else str(octets)
    texte = texte.replace("\n", "\\n")
    return texte if len(texte) <= n else texte[:n] + "…(+" + str(len(texte) - n) + ")"


def sha(octets):
    return hashlib.sha256(octets).hexdigest()


# --- Payloads du harnais (46-RECHERCHE-HOOKS §2 et §3) ----------------------------------------------------------------------
def _j(obj):
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def payload_session(cwd, source="startup"):
    return _j({"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "hook_event_name": "SessionStart", "source": source,
               "model": "modele-test"})


def payload_cwd(cwd):
    return _j({"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "hook_event_name": "CwdChanged", "old_cwd": cwd, "new_cwd": cwd})


def payload_fichier(cwd, fichier, evenement="change"):
    """FileChanged : `file_path` et `event` au PREMIER niveau, jamais dans `tool_input`."""
    return _j({"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "hook_event_name": "FileChanged", "file_path": fichier,
               "event": evenement})


def payload_ecriture(cwd, chemin, outil="Write"):
    entree = {"file_path": chemin, "content": "x"} if outil == "Write" else {"file_path": chemin, "old_string": "a", "new_string": "b"}
    return _j({"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "prompt_id": "prompt-test", "permission_mode": "default",
               "hook_event_name": "PreToolUse", "tool_name": outil, "tool_input": entree, "tool_use_id": "toolu_test"})


def lire_objet(out):
    """L'objet JSON de stdout, ou None si stdout est vide ; une chaîne d'erreur si ce n'est pas UN objet."""
    if out == b"":
        return None
    try:
        doc = json.loads(out.decode("utf-8"))
    except ValueError:
        return "document non JSON"
    return doc if isinstance(doc, dict) else "document non objet"


def verdict_de(rc, out):
    """`silence`, `deny`, `sortie` (UN objet hookSpecificOutput sans décision) ou `autre:...`."""
    if rc != 0:
        return "autre:rc=%d" % rc
    doc = lire_objet(out)
    if doc is None:
        return "silence"
    if isinstance(doc, str):
        return "autre:" + doc
    corps = doc.get("hookSpecificOutput")
    if isinstance(corps, dict) and corps.get("permissionDecision") == "deny":
        return "deny"
    if "decision" in doc or (isinstance(corps, dict) and ("permissionDecision" in corps or "decision" in corps)):
        return "autre:décision"
    return "sortie"


def raison_de(out):
    return json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]


# --- Corps Python du hook, copies et mutants ---------------------------------------------------------------------------------
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


REGEX_ARMEMENT = r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE|G3|G4|G4P) = )"(?:observe|armed)"'


def observe_partout(texte):
    return re.sub(REGEX_ARMEMENT, r'\1"observe"', texte, flags=re.M)


def armer_g6(texte):
    """G6 et G5 armés (l'étape 1), tout le reste à observe : la table reste cohérente (armement_valide) et G3, G4, G4′ ne refusent pas."""
    texte = observe_partout(texte)
    return re.sub(r'^(ARMEMENT_(?:G6|G5) = )"observe"', r'\1"armed"', texte, flags=re.M)


class Ctx:
    def __init__(self, scripts_dir, hooks_json, work, settings_lab):
        self.scripts_dir = scripts_dir
        self.hooks_json = hooks_json
        self.settings_lab = settings_lab
        self.work = os.path.realpath(work)
        self.hook = os.path.join(scripts_dir, "planning-hook.sh")
        self.home = os.path.join(self.work, "home")
        os.makedirs(self.home, exist_ok=True)
        self.cache = os.path.join(self.work, "cache-suite")
        os.makedirs(self.cache, exist_ok=True)
        self.gsd = os.path.join(self.work, "gsd-home")
        os.makedirs(self.gsd, exist_ok=True)
        self._copies = {}
        self._n = 0
        self.originaux = {}
        self.cmd = None
        self.cmd_np = None

    def unique(self, prefixe):
        self._n += 1
        return os.path.join(self.work, prefixe + "-" + str(self._n))

    def charger_commande(self):
        source = self.hooks_json or self.settings_lab
        if not source:
            return None
        d = json.load(open(source, encoding="utf-8"))
        evenements = d.get("hooks", {})
        cands = []
        for evt in ("PreToolUse", "SubagentStop", "CwdChanged", "FileChanged", "SessionStart"):
            for g in evenements.get(evt, []):
                for h in g.get("hooks", []):
                    if "planning-hook.sh" in h.get("command", ""):
                        cands.append((evt, h["command"]))
        if len(cands) != 5 or len({c for _e, c in cands}) != 1:
            return None
        self.cmd = cands[0][1]
        # Pré-filtre hors adhésion : les cas de D1 mesurent le CŒUR, rejoués par la couche shell d'avant le pré-filtre (le bloc retiré, octet pour
        # octet) ; la commande COMPLÈTE est rejouée par R-D1-03 (lab dev et ce dépôt).
        appel, debut = "vf_pre && exit 0\n", "_pn='\n'\nvf_pp()"
        if self.cmd.count(appel) != 1 or self.cmd.count(debut) != 1 or self.cmd.index(debut) > self.cmd.index(appel) or TOKEN not in self.cmd:
            return None
        self.cmd_np = self.cmd[:self.cmd.index(debut)] + self.cmd[self.cmd.index(appel) + len(appel):]
        return self.cmd

    def env(self, extra=None):
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.home, "XDG_CACHE_HOME": self.cache}
        if os.environ.get("TMPDIR"):
            env["TMPDIR"] = os.environ["TMPDIR"]
        if extra:
            env.update(extra)
        return env

    def lancer(self, entree, cwd=None, dossier=None, extra_env=None, np=True):
        """Rejoue la commande enregistrée TELLE QUELLE sous /bin/sh -c, avec le script du dossier donné (défaut : le script réel) ; `np` : sans son
        pré-filtre."""
        d = dossier or self.scripts_dir
        texte = (self.cmd_np if np else self.cmd).replace(TOKEN, "'" + d + "'")
        p = subprocess.run(["/bin/sh", "-c", texte], input=entree, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=self.env(extra_env), cwd=cwd,
                           timeout=120)
        return p.returncode, p.stdout, p.stderr

    def copie_forcee(self, dossier_scripts, valeur):
        """Copie du script du dossier donné à l'armement `valeur` : `observe` (tout à observe) ou `g6` (G6 et G5 armés)."""
        cle = (dossier_scripts, valeur)
        if cle not in self._copies:
            texte = open(os.path.join(dossier_scripts, "planning-hook.sh"), encoding="utf-8").read()
            texte = armer_g6(texte) if valeur == "g6" else observe_partout(texte)
            if len(re.findall(REGEX_ARMEMENT, texte, flags=re.M)) != 8:
                raise RuntimeError("huit constantes ARMEMENT_* attendues")
            d = self.unique("force-" + valeur)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
                fh.write(texte)
            os.chmod(os.path.join(d, "planning-hook.sh"), 0o755)
            self._copies[cle] = d
        return self._copies[cle]


def make_hook_mutant(ctx, ident, motif, remplacement, base=None):
    """Copie du hook (celui du dossier `base`, défaut le hook réel) dont l'UNIQUE ligne portant `motif` (fixe) est remplacée par `remplacement`
    (indentation conservée) ; `bash -n` et la compilation du corps Python extrait doivent passer. Un motif ambigu ou absent, ou un mutant identique,
    est un KO nommé."""
    source = os.path.join(base, "planning-hook.sh") if base else ctx.hook
    original = observe_partout(open(source, encoding="utf-8").read())
    lignes = original.split("\n")
    idx = [i for i, l in enumerate(lignes) if motif in l]
    if len(idx) != 1 or original.count(motif) != 1:
        return None, "MOTIF AMBIGU OU ABSENT (lignes=%d, occurrences=%d)" % (len(idx), original.count(motif))
    ligne = lignes[idx[0]]
    lignes[idx[0]] = ligne[: len(ligne) - len(ligne.lstrip())] + remplacement
    mute = "\n".join(lignes)
    if mute == original:
        return None, "NON OPPOSABLE (identique)"
    dossier = ctx.unique("mut-" + ident.lower())
    os.makedirs(dossier, exist_ok=True)
    chemin = os.path.join(dossier, "planning-hook.sh")
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(mute)
    os.chmod(chemin, 0o755)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    try:
        compile(corps_python(mute), chemin, "exec")
    except SyntaxError as e:
        return None, "SyntaxError du corps Python : " + str(e)
    return dossier, None


# --- Labs, journal, arbres -------------------------------------------------------------------------------------------------------
def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)


def fabriquer_lab(ctx, nom, ouvertes=("01-ouverte-a", "02-ouverte-b"), closes=("03-close",), adherent=True, racine_complete=True):
    """Lab jetable (chemin physique) : `.planning/config.json` (adhérent cycles-v1, sinon dev), les cinq fichiers racine surveillés, et sous
    `cycles/01-c/phases/` les phases `ouvertes` (PLAN.md seul) et `closes` (PLAN.md, CLOTURE.md, VERDICT.md, SUMMARY.md)."""
    lab = os.path.realpath(ctx.unique("lab-" + nom))
    os.makedirs(lab, exist_ok=True)
    plan = os.path.join(lab, ".planning")
    ecrire(os.path.join(plan, "config.json"), '{"planning_version": "%s"}' % ("cycles-v1" if adherent else "2.0"))
    if racine_complete:
        for fichier in ("STATE.md", "INDEX.md", "cloture.log", "derogations-gates.log"):
            ecrire(os.path.join(plan, fichier), "contenu initial de " + fichier + "\n")
    for phase in ouvertes:
        ecrire(os.path.join(plan, "cycles", "01-c", "phases", phase, "PLAN.md"), "---\necrit: []\n---\nplan de " + phase + "\n")
    for phase in closes:
        for fichier in UNITE:
            ecrire(os.path.join(plan, "cycles", "01-c", "phases", phase, fichier), "contenu de " + fichier + "\n")
    return lab


def chemin_journal(lab):
    return os.path.join(lab, ".planning", "surveillance.log")


def lignes_journal(lab):
    chemin = chemin_journal(lab)
    if not os.path.exists(chemin):
        return []
    return [l for l in open(chemin, encoding="utf-8").read().split("\n") if l]


def entrees_journal(lab):
    """Lignes du journal, décodées : dict(genre, chemin, sha, par, source) ; une ligne mal formée lève une erreur nommée."""
    res = []
    for ligne in lignes_journal(lab):
        m = LIGNE_RE.match(ligne)
        if not m:
            raise ValueError("ligne du journal de D1 mal formée : " + repr(ligne))
        res.append({"genre": m.group(2), "chemin": urllib.parse.unquote(m.group(3)), "sha": m.group(4), "par": m.group(5), "source": m.group(6)})
    return res


def empreinte_arbre(dossier):
    """Empreinte de l'arbre (chemins, types, tailles, dates de modification) : deux relevés égaux = aucun fichier créé, modifié ni retiré."""
    morceaux = []
    for racine, dossiers, fichiers in os.walk(dossier, followlinks=False):
        dossiers.sort()
        for nom in sorted(dossiers + fichiers):
            chemin = os.path.join(racine, nom)
            try:
                etat = os.lstat(chemin)
            except OSError:
                continue
            morceaux.append("%s|%o|%d|%d" % (os.path.relpath(chemin, dossier), etat.st_mode, etat.st_size, etat.st_mtime_ns))
    return sha("\n".join(morceaux).encode("utf-8"))


def attendus_surveilles(lab, unites_ouvertes):
    """Les chemins absolus attendus de la liste surveillée : les cinq fichiers racine, puis les quatre fichiers de chaque unité ouverte."""
    res = [os.path.join(lab, ".planning", nom) for nom in RACINE]
    for phase in unites_ouvertes:
        res += [os.path.join(lab, ".planning", "cycles", "01-c", "phases", phase, nom) for nom in UNITE]
    return res


def temoin(ctx, dossier):
    """Témoin : Write d'une cible neutre d'un lab adhérent -> silence (aucun mutant de D1 ne l'affecte)."""
    lab = fabriquer_lab(ctx, "temoin")
    d = ctx.copie_forcee(dossier, "observe")
    rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, ".planning", "notes.md")), cwd=lab, dossier=d)
    return verdict_de(rc, out) == "silence" and not err, verdict_de(rc, out)


def watch_paths(out):
    """(chemins de `hookSpecificOutput.watchPaths`, objet) d'un SessionStart ; ([], message) si la sortie n'est pas conforme."""
    doc = lire_objet(out)
    if doc is None or isinstance(doc, str):
        return None, "stdout %s" % ("vide" if doc is None else doc)
    corps = doc.get("hookSpecificOutput")
    if not isinstance(corps, dict) or corps.get("hookEventName") != "SessionStart" or not isinstance(corps.get("watchPaths"), list):
        return None, "objet sans hookSpecificOutput SessionStart + watchPaths : " + court(out)
    return corps["watchPaths"], doc


# =================================================================================================
# R-D1-01 à R-D1-05
# =================================================================================================
def _dossier(ctx, script):
    return script if script else ctx.scripts_dir


def controle_d1_01(ctx, script):
    """SessionStart d'un lab adhérent à deux unités ouvertes et une close : `watchPaths` = EXACTEMENT les cinq fichiers racine et les quatre fichiers
    de chaque unité ouverte (SUMMARY.md absent compris), chemins absolus, fichier par fichier (aucun dossier), aucun fichier de l'unité close, jamais
    le journal de D1 (même s'il existe) ni le cache du recalcul ; stderr vide, code 0, UN objet SessionStart."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    ouvertes = ("01-ouverte-a", "02-ouverte-b")
    lab = fabriquer_lab(ctx, "d1-01", ouvertes=ouvertes, closes=("03-close",))
    ecrire(chemin_journal(lab), "")
    ecrire(os.path.join(lab, ".planning", ".recalc-cache.json"), "{}")
    rc, out, err = ctx.lancer(payload_session(lab), cwd=lab, dossier=d)
    if rc != 0 or err:
        return False, "code 0 et stderr vide attendus — obtenu rc=%d stderr=%s" % (rc, court(err))
    chemins, doc = watch_paths(out)
    if chemins is None:
        return False, doc
    fautes = []
    attendus = attendus_surveilles(lab, ouvertes)
    if sorted(chemins) != sorted(attendus):
        fautes.append("liste différente de celle attendue : en trop %s, manquants %s" % (sorted(set(chemins) - set(attendus))[:3], sorted(set(attendus) - set(chemins))[:3]))
    for c in chemins:
        if not isinstance(c, str) or not c.startswith("/"):
            fautes.append("chemin non absolu : %r" % (c,))
        elif os.path.isdir(c):
            fautes.append("un DOSSIER est dans la liste (#91634) : " + c)
    if any("03-close" in str(c) for c in chemins):
        fautes.append("un fichier de l'unité close est surveillé")
    if any(str(c).endswith("surveillance.log") or str(c).endswith(".recalc-cache.json") for c in chemins):
        fautes.append("le journal de D1 ou le cache du recalcul est surveillé")
    if "additionalContext" in doc["hookSpecificOutput"]:
        fautes.append("additionalContext présent sans contournement à signaler")
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "SessionStart : %d chemins absolus, fichier par fichier (cinq racine + quatre par unité ouverte, SUMMARY.md absent compris), aucun dossier, "
                          "rien de l'unité close, ni le journal ni le cache" % len(chemins))


def controle_d1_02(ctx, script):
    """Lab de 40 unités ouvertes : exactement 128 chemins (la borne) et UNE ligne `genre=borne` au journal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    ouvertes = tuple("%02d-unite" % i for i in range(1, 41))
    lab = fabriquer_lab(ctx, "d1-02", ouvertes=ouvertes, closes=())
    rc, out, err = ctx.lancer(payload_session(lab), cwd=lab, dossier=d)
    if rc != 0 or err:
        return False, "code 0 et stderr vide attendus — obtenu rc=%d stderr=%s" % (rc, court(err))
    chemins, doc = watch_paths(out)
    if chemins is None:
        return False, doc
    fautes = []
    if len(chemins) != 128 or len(set(chemins)) != len(chemins):
        fautes.append("128 chemins distincts attendus — obtenu %d (%d distincts)" % (len(chemins), len(set(chemins))))
    if any(not isinstance(c, str) or not c.startswith("/") or os.path.isdir(c) for c in chemins):
        fautes.append("un chemin non absolu ou un dossier est dans la liste")
    bornes = [e for e in entrees_journal(lab) if e["genre"] == "borne"]
    if len(bornes) != 1:
        fautes.append("UNE ligne genre=borne attendue au journal — obtenu %d" % len(bornes))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else "40 unités ouvertes : exactement 128 chemins distincts (la borne) et UNE ligne genre=borne au journal")


def _etat_hors_adhesion(ctx, dossier, np, labs):
    """Les trois événements (SessionStart, CwdChanged, FileChanged) sur chaque lab (nom, racine, fichier) : stdout vide, code 0, stderr vide, empreinte
    de l'arbre identique. Rend la liste des fautes."""
    fautes = []
    for nom, racine, fichier, arbre in labs:
        for evt, brut in (("SessionStart", payload_session(racine)), ("CwdChanged", payload_cwd(racine)), ("FileChanged", payload_fichier(racine, fichier))):
            avant = empreinte_arbre(arbre)
            rc, out, err = ctx.lancer(brut, cwd=racine, dossier=dossier, np=np)
            apres = empreinte_arbre(arbre)
            if rc != 0 or out != b"" or err:
                fautes.append("%s, %s (%s) : stdout vide, stderr vide, code 0 attendus — obtenu rc=%d out=%s err=%s" % (evt, nom, "sans pré-filtre" if np else "commande complète", rc, court(out), court(err)))
            if avant != apres:
                fautes.append("%s, %s : aucun fichier créé ni modifié attendu (empreinte de l'arbre identique)" % (evt, nom))
            if os.path.exists(os.path.join(arbre, "surveillance.log")) or os.path.exists(os.path.join(arbre, ".planning", "surveillance.log")):
                fautes.append("%s, %s : un journal de D1 a été créé hors adhésion" % (evt, nom))
    return fautes


def controle_d1_03(ctx, script):
    """Lab dev (planning_version hors cycles-v1) et ce dépôt : SessionStart, CwdChanged, FileChanged -> stdout d'octet vide, code 0, aucun fichier
    créé. Rejoué par la commande COMPLÈTE (pré-filtre) ET par le cœur seul, sans pré-filtre : c'est le cœur qui garde l'adhésion (la mutation « adhésion
    ignorée » se prouve sur ce second rejeu)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    dev = fabriquer_lab(ctx, "d1-03-dev", adherent=False)
    depot = os.path.realpath(os.path.join(ctx.scripts_dir, "..", "..", ".."))
    labs = [("lab dev", dev, os.path.join(dev, ".planning", "STATE.md"), dev)]
    fautes = _etat_hors_adhesion(ctx, d, True, labs)
    depot_labs = [("ce dépôt", depot, os.path.join(depot, ".planning", "STATE.md"), os.path.join(depot, ".planning"))]
    if os.path.isdir(os.path.join(depot, ".planning")) and os.path.isdir(os.path.join(depot, "plugin", "planning-core")):
        fautes += _etat_hors_adhesion(ctx, d, False, labs + depot_labs)
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "lab dev (commande complète et cœur seul) et ce dépôt (commande complète) : SessionStart, CwdChanged, FileChanged -> stdout 0 octet, code 0, "
                          "arbre identique, aucun journal créé")


def controle_d1_04(ctx, script):
    """Références posées au SessionStart ; STATE.md réécrit par un script de test ; FileChanged (`event: change`) -> UNE ligne `contournement`
    (source=seance, sha256 du contenu réécrit, aucun auteur) puis UNE `reference` ; stdout vide, code 0. Jumeaux négatifs : un FileChanged sans changement de
    contenu ne trace rien ; la première observation d'un fichier jamais référencé pose la référence sans contournement."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "d1-04")
    state = os.path.join(lab, ".planning", "STATE.md")
    rc, out, err = ctx.lancer(payload_session(lab), cwd=lab, dossier=d)
    if rc != 0 or err or watch_paths(out)[0] is None:
        return False, "SessionStart : références posées, code 0 attendu — obtenu rc=%d %s" % (rc, court(out))
    avant = len(lignes_journal(lab))
    if avant < 5:
        return False, "références posées au SessionStart : au moins 5 lignes attendues — obtenu %d" % avant
    nouveau = "réécrit hors moteur\n"
    ecrire(state, nouveau)
    rc, out, err = ctx.lancer(payload_fichier(lab, state), cwd=lab, dossier=d)
    fautes = []
    if rc != 0 or out != b"" or err:
        fautes.append("FileChanged : stdout vide, code 0 attendus — obtenu rc=%d out=%s err=%s" % (rc, court(out), court(err)))
    entrees = entrees_journal(lab)
    nouvelles = entrees[avant:]
    sha_nouveau = sha(nouveau.encode("utf-8"))
    attendu = [("contournement", ".planning/STATE.md", sha_nouveau, "-", "seance"), ("reference", ".planning/STATE.md", sha_nouveau, "planning-hook.sh", "seance")]
    obtenu = [(e["genre"], e["chemin"], e["sha"], e["par"], e["source"]) for e in nouvelles]
    if obtenu != attendu:
        fautes.append("deux lignes (contournement puis reference de STATE.md, source=seance) attendues — obtenu %s" % obtenu)
    # Jumeau : le même FileChanged sans nouveau changement de contenu -> rien
    rc, out, err = ctx.lancer(payload_fichier(lab, state), cwd=lab, dossier=d)
    if len(lignes_journal(lab)) != avant + 2 or out != b"":
        fautes.append("FileChanged sans changement de contenu : aucune ligne attendue — obtenu %d ligne(s) de plus" % (len(lignes_journal(lab)) - avant - 2))
    # Première observation : un lab où aucun SessionStart n'a posé de référence
    neuf = fabriquer_lab(ctx, "d1-04-neuf")
    plan = os.path.join(neuf, ".planning", "cycles", "01-c", "phases", "01-ouverte-a", "PLAN.md")
    rc, out, err = ctx.lancer(payload_fichier(neuf, plan), cwd=neuf, dossier=d)
    obtenu = [(e["genre"], e["chemin"]) for e in entrees_journal(neuf)]
    if rc != 0 or out != b"" or obtenu != [("reference", ".planning/cycles/01-c/phases/01-ouverte-a/PLAN.md")]:
        fautes.append("première observation : une seule ligne reference, aucun contournement attendus — obtenu rc=%d %s" % (rc, obtenu))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "références posées au SessionStart, STATE.md réécrit hors moteur, FileChanged -> contournement (source=seance, sha256 du contenu réécrit, sans "
                          "auteur) puis reference ; sans changement de contenu rien ; première observation : référence seule")


def controle_d1_05(ctx, script):
    """Copie G6 : Write et Edit de `.planning/surveillance.log` -> UN deny `[planning-core] G6 :` qui nomme le journal et D1 (témoin : une cible neutre
    passe) ; le recalcul ne range pas le journal « Hors modèle » (jumeau négatif : `surveillance.log.autre` y figure) ; FileChanged sur un fichier non
    surveillé (config.json hors du dossier de planning, un livrable, le journal lui-même) -> aucune ligne."""
    fautes = []
    g6 = ctx.copie_forcee(_dossier(ctx, script), "g6")
    lab = fabriquer_lab(ctx, "d1-05")
    for outil in ("Write", "Edit"):
        rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, ".planning", "surveillance.log"), outil), cwd=lab, dossier=g6)
        v = verdict_de(rc, out)
        if v != "deny" or err:
            fautes.append("%s de surveillance.log (copie G6) : UN deny attendu — obtenu %s %s" % (outil, v, court(out)))
        else:
            raison = raison_de(out)
            if not raison.startswith("[planning-core] G6 :") or "surveillance.log" not in raison or "D1" not in raison:
                fautes.append("%s : raison `[planning-core] G6 :` qui nomme surveillance.log et D1 attendue — obtenu %r" % (outil, raison[:200]))
    rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, ".planning", "notes.md")), cwd=lab, dossier=g6)
    if verdict_de(rc, out) != "silence":
        fautes.append("témoin (cible neutre, copie G6) : silence attendu — obtenu %s" % verdict_de(rc, out))
    # Le recalcul : le journal est un emplacement du modèle
    recalc = os.path.join(ctx.scripts_dir, "recalc-planning.sh")
    lab_r = fabriquer_lab(ctx, "d1-05-recalc", ouvertes=(), closes=(), racine_complete=False)
    ecrire(chemin_journal(lab_r), "")
    ecrire(os.path.join(lab_r, ".planning", "surveillance.log.autre"), "autre\n")
    p = subprocess.run(["bash", recalc, "--planning=" + os.path.join(lab_r, ".planning")], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env({"GSD_HOME": ctx.gsd}), cwd=lab_r, timeout=240)
    index = os.path.join(lab_r, ".planning", "INDEX.md")
    texte = open(index, encoding="utf-8").read() if os.path.exists(index) else ""
    if p.returncode != 0:
        fautes.append("recalc-planning.sh : code 0 attendu — obtenu %d %s" % (p.returncode, court(p.stderr)))
    elif "`surveillance.log`" in texte or "`surveillance.log.autre`" not in texte:
        fautes.append("INDEX.md : surveillance.log absent de « Hors modèle » et son jumeau surveillance.log.autre présent attendus — obtenu %s" % court(texte, 400))
    # FileChanged hors liste : aucune ligne
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab_f = fabriquer_lab(ctx, "d1-05-hors-liste")
    ecrire(os.path.join(lab_f, "config.json"), "{}")
    ecrire(os.path.join(lab_f, "livrables", "rapport.md"), "livrable\n")
    ecrire(os.path.join(lab_f, ".planning", "notes.md"), "notes\n")
    ecrire(chemin_journal(lab_f), "")
    for nom, fichier in (("config.json hors du dossier de planning", os.path.join(lab_f, "config.json")), ("livrable", os.path.join(lab_f, "livrables", "rapport.md")),
                         ("fichier du dossier de planning hors liste", os.path.join(lab_f, ".planning", "notes.md")),
                         ("le journal lui-même", chemin_journal(lab_f))):
        rc, out, err = ctx.lancer(payload_fichier(lab_f, fichier), cwd=lab_f, dossier=d)
        if rc != 0 or out != b"" or err or lignes_journal(lab_f):
            fautes.append("FileChanged sur %s : aucune ligne, stdout vide attendus — obtenu rc=%d out=%s %d ligne(s)" % (nom, rc, court(out), len(lignes_journal(lab_f))))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "copie G6 : Write et Edit de surveillance.log -> deny G6 (journal et D1 nommés) ; recalcul : journal absent de « Hors modèle », jumeau présent ; "
                          "FileChanged sur config.json hors planning, livrable, fichier hors liste et journal : aucune ligne")


# --- Mutants --------------------------------------------------------------------------------------------------------
def original_de(ctx, ident, controle):
    """Résultat d'un contrôle sur le script réel, calculé une seule fois (les sections et les mutants lisent la même exécution)."""
    if ident not in ctx.originaux:
        ctx.originaux[ident] = controle(ctx, None)
    return ctx.originaux[ident]


def tuer(ctx, ident, motif, remplacement, id_controle, controle):
    """Preuve d'opposabilité : le contrôle passe sur l'original, le témoin est inchangé sous le mutant, le contrôle rougit sous le mutant."""
    dossier, raison = make_hook_mutant(ctx, ident, motif, remplacement)
    if dossier is None:
        komut(ident, "mutant du cœur valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
        return
    original = original_de(ctx, id_controle, controle)
    t_orig, t_mut = temoin(ctx, ctx.scripts_dir), temoin(ctx, dossier)
    mutant = controle(ctx, dossier)
    if not original[0]:
        komut(ident, "l'original passe %s (garde du témoin de la mutation)" % id_controle, "conforme", original[1])
    elif t_orig != t_mut:
        komut(ident, "témoin (Write neutre d'un lab adhérent) inchangé sous le mutant", str(t_orig), str(t_mut))
    elif mutant[0]:
        komut(ident, "%s rougit sous le mutant" % id_controle, "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
    else:
        okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s · témoin inchangé" % (id_controle, original[1], mutant[1]))


def rendre(ident, titre, controle, ctx):
    bon, detail = original_de(ctx, ident, controle)
    ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_base(ctx):
    rendre("R-D1-01", "liste surveillée au SessionStart", controle_d1_01, ctx)
    rendre("R-D1-02", "borne de 128 chemins et trace de la troncature", controle_d1_02, ctx)
    rendre("R-D1-03", "hors adhésion : octet vide, aucun fichier créé", controle_d1_03, ctx)
    rendre("R-D1-04", "une écriture que rien n'explique, vue par FileChanged, est tracée", controle_d1_04, ctx)
    rendre("R-D1-05", "journal protégé par G6, connu du recalcul, jamais surveillé", controle_d1_05, ctx)


def sec_mutants_base(ctx):
    # Adhésion ignorée : la sortie silencieuse d'un lab non adhérent retirée (la commande rejouée n'a pas son pré-filtre, `np`)
    tuer(ctx, "D1-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-D1-03", controle_d1_03)
    tuer(ctx, "D1-DOSSIER", "# d1-fichier-par-fichier", "liste.append(dossier)  # d1-fichier-par-fichier", "R-D1-01", controle_d1_01)
    tuer(ctx, "D1-BORNE", "# d1-borne", "if False:  # d1-borne", "R-D1-02", controle_d1_02)
    tuer(ctx, "D1-TRACE", "# d1-contournement", 'return ["reference"]  # d1-contournement', "R-D1-04", controle_d1_04)


SECTIONS = {
    "base": sec_base,
    "mutants_base": sec_mutants_base,
}


def main():
    scripts_dir, hooks_json, work, settings_lab = sys.argv[2:6]
    ctx = Ctx(scripts_dir, hooks_json or None, work, settings_lab or None)
    if ctx.charger_commande() is None:
        ko("commande enregistrée", "la commande enregistrée est lisible (la même sous les cinq événements, jeton et pré-filtre présents)",
           "1 commande", "introuvable dans " + str(hooks_json or settings_lab or "aucune source"))
        sys.exit(1)
    for nom in sys.argv[1].split(","):
        SECTIONS[nom](ctx)


main()
PY_AIDES_D1_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-d1.txt"
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$HOOKS_JSON" "$WORK" "$SETTINGS_LAB" > "$out" 2>&1
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

# Sous `.claude/scripts/tests/` d'un lab (as-installed), le hook et sa commande enregistrée sont ceux de l'installation : la suite ne rejoue que ce qu'elle peut lire.
[ -f "$HOOK" ] || ko "planning-hook.sh présent" "le script du hook central existe à côté des suites" "$HOOK" "absent"
if [ -z "$HOOKS_JSON" ] && [ -z "$SETTINGS_LAB" ]; then
  echo "NOTE : ni hooks.json ni settings.json à côté des scripts (suite lancée hors dépôt) : la commande enregistrée n'est pas lisible, rien n'est rejoué."
else
  run_sections "${VF_D1_SECTIONS:-base,mutants_base}"
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
