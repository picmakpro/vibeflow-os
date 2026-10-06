#!/usr/bin/env bash
# test-d1-surveillance.sh — D1, « toute écriture sur un fichier surveillé est expliquée ou tracée » (Phase 46, 46-07 ; CLOT-07, CLOT-09, CLOT-11 ;
# P46-D-07, P46-D-07a, P46-D-10, P46-D-11, P46-D-16). Le hook est rejoué PAR LA COMMANDE ENREGISTRÉE (lue dans hooks.json, sous /bin/sh -c), jamais par
# un appel direct au script (P45-D-20) ; les cas de D1 tournent sur des COPIES du hook à l'armement FORCÉ (`copie_forcee`), jamais sur l'état livré, qui
# change à chaque armement : `observe` pour tout (les écritures par outil passent, G6 ne refuse rien), ou `g6` (G6 et G5 armés, G3, G4 et G4′ restent à
# observe : un SUMMARY.md sans VERDICT.md n'est pas refusé, discipline du correctif 5c46c503). D1 n'a pas de constante d'armement.
#
# Familles :
#   R-D1-01  SessionStart d'un lab adhérent (deux unités ouvertes, une close) : `watchPaths` en chemins absolus, fichier par fichier — les cinq fichiers racine
#            et les quatre fichiers de chaque unité ouverte (SUMMARY.md encore absent compris), aucun dossier, aucun fichier de l'unité close, jamais le journal ;
#            (N-1, audit-46-b) un dossier ou un lien posé à la place d'un fichier surveillé n'entre jamais dans la liste
#   R-D1-02  lab de 40 unités ouvertes : exactement 128 chemins et une ligne `genre=borne` au journal (sha256 = empreinte de la liste), signal de borne dans additionalContext
#   R-D1-03  lab dev et ce dépôt : SessionStart, CwdChanged, FileChanged -> stdout d'octet vide, code 0, aucun fichier créé (empreinte de l'arbre identique)
#   R-D1-04  références posées au SessionStart, STATE.md réécrit hors moteur, FileChanged -> une ligne `contournement` (source=seance) puis une `reference` ;
#            un FileChanged sans changement de contenu et une première observation : aucun contournement
#   R-D1-05  copie G6 : Write et Edit de `surveillance.log` -> deny de G6 ; le recalcul ne range pas le journal « Hors modèle » (jumeau négatif : un nom
#            voisin y figure) ; FileChanged sur un fichier non surveillé (config.json hors du dossier de planning, un livrable, le journal) -> aucune ligne
#   R-D1-06  recalc-planning.sh (écriture) : une ligne `moteur` (par=recalc-planning.sh, sha256 du fichier écrit) pour STATE.md et INDEX.md, FileChanged expliqué ;
#            `--read-only` : aucune ligne ; jumeau : STATE.md réécrit à la main ensuite -> contournement
#   R-D1-07  poser-verdict.sh, deroger-gate.sh et la consommation d'une dérogation par le hook : une ligne `moteur` chacun, FileChanged expliqué
#   R-D1-08  Write laissé passer (copie observe) : une ligne `intention`, FileChanged expliqué ; un second changement sans nouvelle intention : contournement ;
#            un Write refusé (copie G6), un Write hors liste : aucune intention
#   R-D1-09  `inscrire_surveillance` et `_jeton_journal` ast-identiques dans les quatre scripts ; un chemin à saut de ligne reste UNE ligne encodée
#   R-D1-16  (A9, fix-46-a) 41 phases ouvertes : les unités les PLUS RÉCENTES d'abord (`cle_recence`), 41-active surveillée, signal de borne sans chemin absolu, une seule fois par liste
#            tronquée (S2 : rien de plus ; S3 : liste changée, seconde ligne borne et signal de nouveau) ; ordre `100-a`, `99-z`, `010-b`, `02-a`, `01-a`
#   R-D1-17  (A9, fix-46-a) plafond d'octets hachés à la réconciliation (copie à BORNE_OCTETS_RECONCILIATION = 4096) : fichier écarté sans ligne, une ligne borne, signal qui le nomme, sans répétition ;
#            fichier au-delà de BORNE_OCTETS_LIVRABLES : même signal
#   R-D1-15  (A1, fix-46-a) unité `01-été` : références de chemin NFC ; Write par le chemin NFD du CLOTURE.md -> UNE ligne `intention` de chemin NFC ; FileChanged sur le
#            chemin NFC : aucun contournement ; FileChanged d'un chemin NFD exercé là où la forme NFD désigne le fichier (MUT-D1-NFC)
#   R-D1-18  (A1, fix-46-a tour 3) unité `01-été` créée sous son nom NFD sur le disque : poser-verdict.sh du dossier jugé, sur le chemin du disque, inscrit UNE ligne `moteur`
#            de clé NFC (sha256 du VERDICT.md du disque) et le FileChanged qui suit n'est pas un contournement (MUT-D1-MOTEUR-NFD)
#   R-D1-10  SessionStart (références posées), CLOTURE.md créé hors séance, SessionStart -> un contournement (source=reconciliation) et le signal D1 avec le chemin,
#            une ligne `signal` posée ; un troisième SessionStart sans changement : aucun signal
#   R-D1-11  une écriture du moteur entre deux séances : aucun contournement à la réconciliation
#   R-D1-12  CwdChanged : `watchPaths` au premier niveau ET sous `hookSpecificOutput` ; FileChanged : jamais de `watchPaths`
#   R-D1-13  erreur injectée dans chaque mode de D1 : stdout vide, code 0, aucun refus ; aucune sortie de D1 ne contient `deny` ni `block`
#   R-D1-14  journal de plus de 5 Mio dont la dernière référence est hors de la fenêtre des 4 Mio de fin : première observation (jumeau : dans la fenêtre,
#            contournement) ; un SessionStart sur 128 chemins lit chaque fichier une fois (mesure structurelle)
#   R-D1-19  (A6, P46 lot B, b3) journal réduit au silence par Bash (lien vers /dev/null, chmod 000, `chflags uchg`, absent alors que l'état précédent existe : reprise ou cache du
#            recalcul) : signal D1 au SessionStart, rien d'écrit ; jumeaux : première séance sans journal, journal sain, séance suivante (pas de répétition)
#   R-D1-20  (Q-B, fix-46-c) `.planning/.gitignore` (une ligne `surveillance.log`) posé au SessionStart d'un lab adhérent : idempotent, existant préservé, hors adhésion rien,
#            lien et dossier jamais suivis, aucun temporaire
#   Le cas de canary R-CANG-D1 vit dans la section `cang` de test-planning-gates.sh.
# Mutants (chacun tué par un contrôle, trace assertion · attendu (original) · obtenu (mutant)) :
#   MUT-D1-ADHESION (adhésion ignorée, commande sans pré-filtre -> R-D1-03), MUT-D1-DOSSIER (le dossier de l'unité dans la liste -> R-D1-01), MUT-D1-GITIGNORE-APPEL / -IDEMPOTENT / -ATOMIQUE (Q-B -> R-D1-20), MUT-D1-GITIGNORE-MODELE (`.gitignore` retiré des noms du modèle du recalcul -> R-D1-05), MUT-D1-JAMAIS-UN-DOSSIER (filtre « absent ou fichier régulier » retiré -> R-D1-01, N-1),
#   MUT-D1-BORNE (borne retirée -> R-D1-02), MUT-D1-TRACE (aucune ligne de contournement -> R-D1-04), MUT-D1-MOTEUR (ligne moteur du recalcul retirée ->
#   R-D1-06), MUT-D1-INTENTION (ligne d'intention retirée -> R-D1-08), MUT-D1-INTENTION-REUTILISEE (une intention explique plusieurs changements ->
#   R-D1-08), MUT-D1-AST (une copie divergente -> R-D1-09), MUT-D1-RECONCILIATION (réconciliation retirée -> R-D1-10), MUT-D1-SIGNAL-REPETE (ligne `signal`
#   non posée -> R-D1-10), MUT-D1-REFUS (une erreur de D1 transformée en deny -> R-D1-13), MUT-D1-WATCH-FILECHANGED (FileChanged renvoie la liste -> R-D1-12),
#   MUT-D1-FENETRE (fenêtre de lecture retirée -> R-D1-14), MUT-D1-ORDRE (parcours des phases par ordre croissant -> R-D1-16), MUT-D1-ANNONCE-BORNE
#   (signal de borne retiré -> R-D1-16), MUT-D1-IDENTITE-BORNE (une ligne borne à chaque SessionStart -> R-D1-16), MUT-D1-OCTETS (plafond d'octets retiré -> R-D1-17), MUT-D1-NFC (-> R-D1-15),
#   MUT-D1-MOTEUR-NFD (ligne moteur d'un verdict hachée sous la forme NFC -> R-D1-18 ; opposable sur un système SENSIBLE à la normalisation seulement : sur APFS ou HFS+
#   la forme NFC désigne le même dossier, la suite rend `non applicable ici`), MUT-D1-JOURNAL-SIGNAL / -ETAT / -IRREGULIER / -DROITS / -ABSENT / -PREMIERE-SEANCE / -OUVERTURE
#   (chaque contrôle d'`anomalie_journal` retiré seul, ou forcé -> R-D1-19 ; -OUVERTURE non applicable sans `chflags`).
# Variables : VF_D1_SECTIONS=<liste> pour ne rejouer qu'une partie (sections : base, mutants_base, moteur, mutants_moteur, reconciliation, mutants_reconciliation).
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
import shutil
import subprocess
import sys
import tempfile
import time
import unicodedata
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


def jumeau_nfd(texte):
    """Forme NFD, composant par composant (séparateur `/`) : égale au texte s'il ne porte aucun caractère composable."""
    return "/".join(unicodedata.normalize("NFD", c) for c in texte.split("/"))


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


def controle_d1_20(ctx, script):
    """(Q-B, fix-46-c) `.planning/.gitignore` posé au SessionStart d'un lab ADHÉRENT : une seule ligne `surveillance.log`, avant toute ligne du journal ; un second
    SessionStart ne le touche pas (même octets, même inode) ; un `.gitignore` existant sans la ligne la reçoit en dernier, ses lignes restent (avec ou sans
    saut de ligne final) ; un `.gitignore` qui porte déjà la ligne est laissé tel quel (octets identiques) ; un lab non adhérent n'en reçoit pas ; un `.gitignore`
    en lien ou en dossier n'est jamais suivi ni modifié ; aucun fichier temporaire ne reste."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    fautes = []

    def session(lab):
        return ctx.lancer(payload_session(lab), cwd=lab, dossier=d)

    def gi(lab):
        return os.path.join(lab, ".planning", ".gitignore")

    def lu(chemin):
        with open(chemin, "rb") as fh:
            return fh.read()

    def restes(lab):
        return [n for n in os.listdir(os.path.join(lab, ".planning")) if n.startswith(".gitignore.")]

    lab = fabriquer_lab(ctx, "d1-20-neuf")
    rc, out, err = session(lab)
    if rc != 0 or err or not os.path.isfile(gi(lab)) or lu(gi(lab)) != b"surveillance.log\n":
        fautes.append("lab adhérent sans .gitignore : UNE ligne `surveillance.log` attendue — obtenu rc=%d %r" % (rc, lu(gi(lab))[:80] if os.path.isfile(gi(lab)) else None))
    ino = os.stat(gi(lab)).st_ino if os.path.isfile(gi(lab)) else None
    session(lab)
    if not os.path.isfile(gi(lab)) or lu(gi(lab)) != b"surveillance.log\n" or os.stat(gi(lab)).st_ino != ino:
        fautes.append("second SessionStart : le .gitignore doit rester le même fichier, une seule ligne")
    if restes(lab):
        fautes.append("fichier temporaire laissé : %s" % restes(lab))
    # existant sans la ligne, sans saut de ligne final
    lab = fabriquer_lab(ctx, "d1-20-existant")
    ecrire(gi(lab), "node_modules\n*.tmp")
    session(lab)
    if lu(gi(lab)) != b"node_modules\n*.tmp\nsurveillance.log\n":
        fautes.append(".gitignore existant : lignes conservées et `surveillance.log` ajoutée en dernier attendues — obtenu %r" % lu(gi(lab))[:120])
    # déjà présent (forme `/surveillance.log` comprise) : octets inchangés
    for nom, contenu in (("present", "a\nsurveillance.log\nb\n"), ("present-racine", "/surveillance.log")):
        lab = fabriquer_lab(ctx, "d1-20-" + nom)
        ecrire(gi(lab), contenu)
        session(lab)
        if lu(gi(lab)) != contenu.encode("utf-8"):
            fautes.append(".gitignore qui porte déjà la ligne (%s) : laissé tel quel attendu — obtenu %r" % (nom, lu(gi(lab))[:80]))
    # lab non adhérent : aucun fichier
    lab = fabriquer_lab(ctx, "d1-20-dev", adherent=False)
    session(lab)
    if os.path.lexists(gi(lab)):
        fautes.append("lab non adhérent : aucun .gitignore attendu")
    # lien et dossier : jamais suivis
    lab = fabriquer_lab(ctx, "d1-20-lien")
    cible = os.path.join(os.path.dirname(lab), "d1-20-lien-hors.txt")
    ecrire(cible, "hors du lab\n")
    os.symlink(cible, gi(lab))
    session(lab)
    if lu(cible) != b"hors du lab\n" or not os.path.islink(gi(lab)):
        fautes.append(".gitignore en lien : jamais suivi, cible et lien inchangés attendus")
    lab = fabriquer_lab(ctx, "d1-20-dossier")
    os.makedirs(gi(lab))
    session(lab)
    if not os.path.isdir(gi(lab)) or os.listdir(gi(lab)):
        fautes.append(".gitignore en dossier : inchangé attendu")
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          ".planning/.gitignore : posé une fois (`surveillance.log`), idempotent, existant préservé (ligne ajoutée en dernier), déjà présent laissé tel quel, "
                          "hors adhésion rien, lien et dossier jamais suivis, aucun temporaire")


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
    # (audit-46-b N-1, T-46-074) un chemin surveillé n'est gardé que s'il est ABSENT ou FICHIER RÉGULIER : un dossier ou un lien (même vers un dossier) posé à la
    # place d'un fichier surveillé n'entre jamais dans `watchPaths` ; le jumeau (fichier régulier, absent) y reste
    hostile = fabriquer_lab(ctx, "d1-01-hostile", ouvertes=("01-ouverte-a",), closes=())
    plan = os.path.join(hostile, ".planning")
    cible = os.path.join(os.path.dirname(hostile), "d1-01-hostile-hors")
    os.makedirs(cible, exist_ok=True)
    os.remove(os.path.join(plan, "STATE.md"))
    os.makedirs(os.path.join(plan, "STATE.md"))  # un DOSSIER à la place d'un fichier racine
    os.remove(os.path.join(plan, "INDEX.md"))
    os.symlink(cible, os.path.join(plan, "INDEX.md"))  # un LIEN vers un dossier
    unite = os.path.join(plan, "cycles", "01-c", "phases", "01-ouverte-a")
    os.remove(os.path.join(unite, "PLAN.md"))
    os.symlink(cible, os.path.join(unite, "PLAN.md"))  # un LIEN à la place du PLAN.md de l'unité
    os.makedirs(os.path.join(unite, "CLOTURE.md"))  # un dossier à la place d'un fichier d'unité
    rc2, out2, err2 = ctx.lancer(payload_session(hostile), cwd=hostile, dossier=d)
    chemins2, doc2 = watch_paths(out2)
    if rc2 != 0 or chemins2 is None:
        fautes.append("lab hostile : code 0 et UN objet SessionStart attendus — obtenu rc=%d %s" % (rc2, court(err2) if chemins2 is not None else doc2))
    else:
        interdits = [os.path.relpath(c, hostile) for c in chemins2 if os.path.islink(c) or (os.path.lexists(c) and not os.path.isfile(c))]
        if interdits:
            fautes.append("un dossier ou un lien est dans la liste (T-46-074) : %s" % interdits[:3])
        attendus2 = [c for c in attendus_surveilles(hostile, ("01-ouverte-a",)) if not any(c.endswith(s) for s in (
            "/STATE.md", "/INDEX.md", "/01-ouverte-a/PLAN.md", "/01-ouverte-a/CLOTURE.md"))]
        if sorted(chemins2) != sorted(attendus2):
            fautes.append("lab hostile : liste différente — en trop %s, manquants %s" % (sorted(set(chemins2) - set(attendus2))[:3], sorted(set(attendus2) - set(chemins2))[:3]))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "SessionStart : %d chemins absolus, fichier par fichier (cinq racine + quatre par unité ouverte, SUMMARY.md absent compris), aucun dossier, "
                          "rien de l'unité close, ni le journal ni le cache ; lab hostile (dossier, lien) : ni dossier ni lien, le reste surveillé" % len(chemins))


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
    elif not re.fullmatch(r"[0-9a-f]{64}", bornes[0]["sha"]):
        fautes.append("le sha256 de la ligne borne est l'empreinte de la liste (64 chiffres hexadécimaux) — obtenu %r" % (bornes[0]["sha"],))
    contexte = doc["hookSpecificOutput"].get("additionalContext")
    if not isinstance(contexte, str) or "[planning-core] D1 : surveillance bornée" not in contexte or "BORNE_WATCHPATHS" not in contexte:
        fautes.append("additionalContext : le signal de borne (« surveillance bornée », « BORNE_WATCHPATHS ») attendu — obtenu %r" % (contexte,))
    elif "ni surveillées ni réconciliées" not in contexte:  # N-8 (audit-46-b) : les unités hors liste ne sont pas non plus réconciliées
        fautes.append("additionalContext : « ni surveillées ni réconciliées » attendu dans le signal de borne — obtenu %r" % (contexte,))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else "40 unités ouvertes : exactement 128 chemins distincts (la borne), UNE ligne genre=borne (sha256 = empreinte de la liste) et le signal de borne dans additionalContext")


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
    # Ce dépôt n'est rejoué QUE par le script réel : un mutant « adhésion ignorée » y laisserait un journal de D1 (le pré-filtre ne prouve pas la non-adhésion
    # d'un config.json de plus de 128 octets : c'est le cœur qui la garde) — la preuve de la mutation se fait sur le lab dev fixture, jamais sur le dépôt.
    if script is None and os.path.isdir(os.path.join(depot, ".planning")) and os.path.isdir(os.path.join(depot, "plugin", "planning-core")):
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
    recalc = os.path.join(_dossier(ctx, script), "recalc-planning.sh")
    lab_r = fabriquer_lab(ctx, "d1-05-recalc", ouvertes=(), closes=(), racine_complete=False)
    ecrire(chemin_journal(lab_r), "")
    ecrire(os.path.join(lab_r, ".planning", "surveillance.log.autre"), "autre\n")
    ecrire(os.path.join(lab_r, ".planning", ".gitignore"), "surveillance.log\n")  # Q-B : posé par le hook, emplacement du modèle
    ecrire(os.path.join(lab_r, ".planning", ".gitignore.bak"), "jumeau\n")
    p = subprocess.run(["bash", recalc, "--planning=" + os.path.join(lab_r, ".planning")], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env({"GSD_HOME": ctx.gsd}), cwd=lab_r, timeout=240)
    index = os.path.join(lab_r, ".planning", "INDEX.md")
    texte = open(index, encoding="utf-8").read() if os.path.exists(index) else ""
    if p.returncode != 0:
        fautes.append("recalc-planning.sh : code 0 attendu — obtenu %d %s" % (p.returncode, court(p.stderr)))
    elif "`surveillance.log`" in texte or "`surveillance.log.autre`" not in texte:
        fautes.append("INDEX.md : surveillance.log absent de « Hors modèle » et son jumeau surveillance.log.autre présent attendus — obtenu %s" % court(texte, 400))
    elif "`.gitignore`" in texte or "`.gitignore.bak`" not in texte:
        fautes.append("INDEX.md : .gitignore absent de « Hors modèle » et son jumeau .gitignore.bak présent attendus — obtenu %s" % court(texte, 400))
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


# =================================================================================================
# R-D1-06 à R-D1-09 : les écritures du moteur et les écritures par outil laissées passer sont EXPLIQUÉES
# =================================================================================================
SCRIPTS_MOTEUR = ("planning-hook.sh", "recalc-planning.sh", "poser-verdict.sh", "deroger-gate.sh", "detect-gsd-engine.sh")
MARQUEURS = {"planning-hook.sh": "PY_PLANNING_HOOK_EOF", "recalc-planning.sh": "PY_RECALC_PLANNING_EOF", "poser-verdict.sh": "PY_POSER_VERDICT_EOF",
             "deroger-gate.sh": "PY_DEROGER_GATE_EOF"}


def script_de(ctx, dossier, nom):
    """Le script `nom` du dossier jugé (une copie mutante) s'il y est, sinon celui du dépôt."""
    if dossier and os.path.exists(os.path.join(dossier, nom)):
        return os.path.join(dossier, nom)
    return os.path.join(ctx.scripts_dir, nom)


def make_scripts_mutant(ctx, ident, script, motif, remplacement):
    """Dossier qui porte les copies des scripts du moteur (hook, recalcul, pose de verdict, dérogation, détecteur du moteur de développement) dont
    `script` a son UNIQUE ligne portant `motif` remplacée par `remplacement` (indentation conservée) ; `bash -n` et la compilation du corps Python
    doivent passer. Motif ambigu ou absent, ou mutant identique : un KO nommé."""
    source = os.path.join(ctx.scripts_dir, script)
    original = open(source, encoding="utf-8").read()
    lignes = original.split("\n")
    idx = [i for i, l in enumerate(lignes) if motif in l]
    if len(idx) != 1 or original.count(motif) != 1:
        return None, "MOTIF AMBIGU OU ABSENT (lignes=%d, occurrences=%d)" % (len(idx), original.count(motif))
    ligne = lignes[idx[0]]
    lignes[idx[0]] = ligne[: len(ligne) - len(ligne.lstrip())] + remplacement
    mute = "\n".join(lignes)
    if mute == original:
        return None, "NON OPPOSABLE (identique)"
    dossier = ctx.unique("mut-scripts-" + ident.lower())
    os.makedirs(dossier, exist_ok=True)
    for nom in SCRIPTS_MOTEUR:
        with open(os.path.join(dossier, nom), "w", encoding="utf-8") as fh:
            fh.write(mute if nom == script else open(os.path.join(ctx.scripts_dir, nom), encoding="utf-8").read())
        os.chmod(os.path.join(dossier, nom), 0o755)
    chemin = os.path.join(dossier, script)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    if script in MARQUEURS:
        try:
            compile(corps_python(mute, MARQUEURS[script]), chemin, "exec")
        except SyntaxError as e:
            return None, "SyntaxError du corps Python : " + str(e)
    return dossier, None


def lancer_script(ctx, argv, lab):
    p = subprocess.run(["bash"] + argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env({"GSD_HOME": ctx.gsd}), cwd=lab, timeout=240)
    return p.returncode, p.stdout, p.stderr


def lancer_recalc(ctx, dossier, lab, *options):
    return lancer_script(ctx, [script_de(ctx, dossier, "recalc-planning.sh"), "--planning=" + os.path.join(lab, ".planning")] + list(options), lab)


def lignes_de(lab, genre, chemin=None):
    return [e for e in entrees_journal(lab) if e["genre"] == genre and (chemin is None or e["chemin"] == chemin)]


def sha_du_fichier(chemin):
    return sha(open(chemin, "rb").read())


def session(ctx, hook_dir, lab):
    """SessionStart sur la copie `observe` du hook : les références sont posées. Rend (rc, out, err)."""
    return ctx.lancer(payload_session(lab), cwd=lab, dossier=hook_dir)


def changement(ctx, hook_dir, lab, rel):
    """FileChanged sur le fichier `rel` (relatif au lab) ; rend (rc, out, err)."""
    return ctx.lancer(payload_fichier(lab, os.path.join(lab, *rel.split("/"))), cwd=lab, dossier=hook_dir)


def contournements(lab, rel):
    return lignes_de(lab, "contournement", rel)


def controle_d1_06(ctx, script):
    """`recalc-planning.sh` (écriture) réécrit STATE.md et INDEX.md : une ligne `moteur` (par=recalc-planning.sh) avec le sha256 du fichier écrit ; le FileChanged
    qui suit n'est pas un contournement (référence seule). Jumeau négatif : STATE.md réécrit ensuite à la main (sha différent de celui du moteur) -> contournement.
    `--read-only` : aucune ligne au journal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "d1-06", ouvertes=(), closes=())
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or err:
        return False, "SessionStart : code 0 attendu — obtenu rc=%d %s" % (rc, court(err))
    avant = len(lignes_journal(lab))
    rc, out, err = lancer_recalc(ctx, script, lab, "--read-only")
    if rc != 0 or len(lignes_journal(lab)) != avant:
        return False, "recalc --read-only : code 0 et aucune ligne au journal attendus — obtenu rc=%d, %d ligne(s) de plus" % (rc, len(lignes_journal(lab)) - avant)
    rc, out, err = lancer_recalc(ctx, script, lab)
    if rc != 0:
        return False, "recalc-planning.sh : code 0 attendu — obtenu %d %s" % (rc, court(err))
    fautes = []
    for nom in ("STATE.md", "INDEX.md"):
        rel = ".planning/" + nom
        moteur = lignes_de(lab, "moteur", rel)
        reel = sha_du_fichier(os.path.join(lab, ".planning", nom))
        if len(moteur) != 1 or moteur[0]["sha"] != reel or moteur[0]["par"] != "recalc-planning.sh":
            fautes.append("%s : UNE ligne moteur (par=recalc-planning.sh, sha256 du fichier écrit %s…) attendue — obtenu %s" % (nom, reel[:12], [(m["sha"][:12], m["par"]) for m in moteur]))
        rc, out, err = changement(ctx, d, lab, rel)
        if rc != 0 or out != b"" or err or contournements(lab, rel):
            fautes.append("FileChanged sur %s après l'écriture du moteur : aucun contournement, stdout vide attendus — obtenu rc=%d %s %d contournement(s)" % (nom, rc, court(out), len(contournements(lab, rel))))
    ecrire(os.path.join(lab, ".planning", "STATE.md"), "réécrit à la main, hors moteur\n")
    changement(ctx, d, lab, ".planning/STATE.md")
    if len(contournements(lab, ".planning/STATE.md")) != 1:
        fautes.append("jumeau : STATE.md réécrit à la main après le moteur -> UN contournement attendu — obtenu %d" % len(contournements(lab, ".planning/STATE.md")))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "recalc-planning.sh : une ligne moteur (sha256 du fichier écrit) par fichier écrit, FileChanged expliqué ; réécriture à la main ensuite : contournement ; "
                          "--read-only : aucune ligne")


def controle_d1_07(ctx, script):
    """`poser-verdict.sh` pose un VERDICT.md, `deroger-gate.sh` ajoute une dérogation, le hook (copie G6) en consomme une : une ligne `moteur` chacun (par= le script,
    sha256 du fichier écrit) ; le FileChanged qui suit n'est pas un contournement."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    g6 = ctx.copie_forcee(_dossier(ctx, script), "g6")
    lab = fabriquer_lab(ctx, "d1-07", ouvertes=("01-u",), closes=())
    unite = os.path.join(".planning", "cycles", "01-c", "phases", "01-u")
    ecrire(os.path.join(lab, unite, "PLAN.md"), "---\necrit: [livrables/rapport.md]\n---\nplan\n")
    ecrire(os.path.join(lab, "livrables", "rapport.md"), "livrable\n")
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or err:
        return False, "SessionStart : code 0 attendu — obtenu rc=%d %s" % (rc, court(err))
    fautes = []
    # 1. poser-verdict.sh
    rc, out, err = lancer_script(ctx, [script_de(ctx, script, "poser-verdict.sh"), "--unite=" + os.path.join(lab, unite), "--juge=juge-test", "--tentative=1", "--score=ok",
                                       "--constat=critere::passé"], lab)
    rel = ".planning/cycles/01-c/phases/01-u/VERDICT.md"
    if rc != 0:
        return False, "poser-verdict.sh : code 0 attendu — obtenu %d %s" % (rc, court(err))
    moteur = lignes_de(lab, "moteur", rel)
    if len(moteur) != 1 or moteur[0]["par"] != "poser-verdict.sh" or moteur[0]["sha"] != sha_du_fichier(os.path.join(lab, rel)):
        fautes.append("poser-verdict.sh : UNE ligne moteur (par=poser-verdict.sh, sha256 du VERDICT.md) attendue — obtenu %s" % [(m["par"], m["sha"][:12]) for m in moteur])
    changement(ctx, d, lab, rel)
    if contournements(lab, rel):
        fautes.append("FileChanged sur VERDICT.md après poser-verdict.sh : aucun contournement attendu")
    # 2. deroger-gate.sh
    journal_derog = ".planning/derogations-gates.log"
    rc, out, err = lancer_script(ctx, [script_de(ctx, script, "deroger-gate.sh"), "--lab=" + lab, "--gate=G6", "--chemin=.planning/STATE.md", "--qui=suite-d1", "--canal=suite de test",
                                       "--date=2026-10-05", "--raison=preuve de D1 : la derogation est une ecriture du moteur"], lab)
    if rc != 0:
        return False, "deroger-gate.sh : code 0 attendu — obtenu %d %s" % (rc, court(err))
    moteur = lignes_de(lab, "moteur", journal_derog)
    reel = sha_du_fichier(os.path.join(lab, journal_derog))
    if len(moteur) != 1 or moteur[0]["par"] != "deroger-gate.sh" or moteur[0]["sha"] != reel:
        fautes.append("deroger-gate.sh : UNE ligne moteur (par=deroger-gate.sh, sha256 du journal) attendue — obtenu %s" % [(m["par"], m["sha"][:12]) for m in moteur])
    changement(ctx, d, lab, journal_derog)
    if contournements(lab, journal_derog):
        fautes.append("FileChanged sur le journal de dérogation après deroger-gate.sh : aucun contournement attendu")
    # 3. le hook consomme la dérogation : le Write de STATE.md (G6 armé) passe, cité
    rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, ".planning", "STATE.md")), cwd=lab, dossier=g6)
    if rc != 0 or verdict_de(rc, out) != "sortie" or "dérogation #1 consommée" not in out.decode("utf-8", "replace"):
        return False, "Write de STATE.md avec dérogation active (copie G6) : passage cité attendu — obtenu %s %s" % (verdict_de(rc, out), court(out))
    moteur = [m for m in lignes_de(lab, "moteur", journal_derog) if m["par"] == "planning-hook.sh"]
    reel = sha_du_fichier(os.path.join(lab, journal_derog))
    if len(moteur) != 1 or moteur[0]["sha"] != reel:
        fautes.append("consommation par le hook : UNE ligne moteur (par=planning-hook.sh, sha256 du journal) attendue — obtenu %s" % [(m["par"], m["sha"][:12]) for m in moteur])
    changement(ctx, d, lab, journal_derog)
    if contournements(lab, journal_derog):
        fautes.append("FileChanged sur le journal de dérogation après la consommation par le hook : aucun contournement attendu")
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "poser-verdict.sh, deroger-gate.sh et la consommation d'une dérogation par le hook : une ligne moteur chacun (sha256 du fichier écrit), FileChanged expliqué")


def controle_d1_08(ctx, script):
    """Write de PLAN.md laissé passer par le hook (copie observe) -> UNE ligne `intention` ; le FileChanged qui suit n'est pas un contournement ; un second
    FileChanged après une nouvelle écriture SANS nouvelle intention -> contournement (une intention n'explique qu'un changement) ; un Write refusé (copie G6)
    -> aucune intention ; un Write hors liste ou un Bash -> aucune intention."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    g6 = ctx.copie_forcee(_dossier(ctx, script), "g6")
    lab = fabriquer_lab(ctx, "d1-08", ouvertes=("01-u",), closes=())
    plan_rel = ".planning/cycles/01-c/phases/01-u/PLAN.md"
    plan = os.path.join(lab, *plan_rel.split("/"))
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or err:
        return False, "SessionStart : code 0 attendu — obtenu rc=%d %s" % (rc, court(err))
    fautes = []
    rc, out, err = ctx.lancer(payload_ecriture(lab, plan), cwd=lab, dossier=d)
    intentions = lignes_de(lab, "intention", plan_rel)
    if rc != 0 or verdict_de(rc, out) == "deny" or len(intentions) != 1 or intentions[0]["par"] != "Write" or intentions[0]["sha"] != "-":
        return False, "Write de PLAN.md laissé passer : UNE ligne intention (par=Write, sans sha256) attendue — obtenu rc=%d %s %s" % (rc, verdict_de(rc, out), [(i["par"], i["sha"]) for i in intentions])
    ecrire(plan, "---\necrit: []\n---\nplan réécrit par l'outil\n")
    rc, out, err = changement(ctx, d, lab, plan_rel)
    if rc != 0 or out != b"" or contournements(lab, plan_rel) or len(lignes_de(lab, "reference", plan_rel)) != 2:
        fautes.append("FileChanged après l'écriture par outil : aucun contournement, une référence de plus attendus — obtenu %d contournement(s), %d référence(s)" % (len(contournements(lab, plan_rel)), len(lignes_de(lab, "reference", plan_rel))))
    ecrire(plan, "---\necrit: []\n---\nplan réécrit une seconde fois, hors outil\n")
    changement(ctx, d, lab, plan_rel)
    if len(contournements(lab, plan_rel)) != 1:
        fautes.append("second changement sans nouvelle intention : UN contournement attendu (une intention n'explique qu'un changement) — obtenu %d" % len(contournements(lab, plan_rel)))
    # Write refusé : copie G6, STATE.md -> aucune intention
    avant = len(lignes_journal(lab))
    rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, ".planning", "STATE.md")), cwd=lab, dossier=g6)
    if verdict_de(rc, out) != "deny" or lignes_de(lab, "intention", ".planning/STATE.md") or len(lignes_journal(lab)) != avant:
        fautes.append("Write refusé (copie G6) : un deny et aucune intention attendus — obtenu %s, %d intention(s)" % (verdict_de(rc, out), len(lignes_de(lab, "intention", ".planning/STATE.md"))))
    # Write hors liste : aucune intention
    rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, ".planning", "notes.md")), cwd=lab, dossier=d)
    if len(lignes_journal(lab)) != avant:
        fautes.append("Write hors liste : aucune ligne attendue")
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "Write de PLAN.md laissé passer : une ligne intention, FileChanged expliqué ; second changement sans intention : contournement ; Write refusé ou hors liste : "
                          "aucune intention")


def controle_d1_15(ctx, script):
    """A1 (fix-46-a) : unité ouverte `01-été` (nom écrit par échappements \\u) ; références posées par SessionStart, toutes de chemin NFC ; Write par le chemin NFD
    du CLOTURE.md de l'unité (copie observe) -> UNE ligne `intention` de chemin NFC ; le fichier écrit au chemin NFC puis FileChanged sur le chemin enregistré (NFC)
    -> aucun contournement ; FileChanged d'un chemin NFD exercé seulement là où la forme NFD désigne le fichier (sinon une ligne `~`, sans ✓)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    unite = "01-\u00e9t\u00e9"
    lab = fabriquer_lab(ctx, "d1-15", ouvertes=(unite,), closes=())
    cloture_rel = ".planning/cycles/01-c/phases/%s/CLOTURE.md" % unite
    cloture_nfd = jumeau_nfd(cloture_rel)
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or err:
        return False, "SessionStart : code 0 attendu — obtenu rc=%d %s" % (rc, court(err))
    fautes = []
    refs = lignes_de(lab, "reference")
    if not any(unite in r["chemin"] for r in refs) or any(not unicodedata.is_normalized("NFC", r["chemin"]) for r in refs):
        fautes.append("références de SessionStart : toutes de chemin NFC et au moins une sous l'unité %s attendues — obtenu %s" % (unite, [r["chemin"] for r in refs][:3]))
    rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, *cloture_nfd.split("/"))), cwd=lab, dossier=d)
    intentions = lignes_de(lab, "intention", cloture_rel)
    if rc != 0 or verdict_de(rc, out) == "deny" or len(intentions) != 1:
        return False, "Write du CLOTURE.md par son chemin NFD : UNE ligne intention de chemin NFC attendue — obtenu rc=%d %s, %d intention(s) %s" % (
            rc, verdict_de(rc, out), len(intentions), [i["chemin"] for i in lignes_de(lab, "intention")][:3])
    ecrire(os.path.join(lab, *cloture_rel.split("/")), "clôture écrite au chemin NFC\n")
    rc, out, err = changement(ctx, d, lab, cloture_rel)
    if rc != 0 or out != b"" or contournements(lab, cloture_rel):
        fautes.append("FileChanged sur le chemin enregistré (NFC) après l'écriture : aucun contournement attendu — obtenu rc=%d %d contournement(s)" % (rc, len(contournements(lab, cloture_rel))))
    if os.path.exists(os.path.join(lab, *cloture_nfd.split("/"))):
        ecrire(os.path.join(lab, *cloture_rel.split("/")), "clôture réécrite hors outil\n")
        rc, out, err = ctx.lancer(payload_fichier(lab, os.path.join(lab, *cloture_nfd.split("/"))), cwd=lab, dossier=d)
        if rc != 0 or len(contournements(lab, cloture_rel)) != 1:
            fautes.append("FileChanged d'un chemin NFD : UN contournement de chemin NFC attendu — obtenu rc=%d %d contournement(s)" % (rc, len(contournements(lab, cloture_rel))))
    elif script is None:
        print("  ~ R-D1-15 (FileChanged NFD) non exercé (système de fichiers sensible à la normalisation)")
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "unité 01-été : références de chemin NFC ; Write par le chemin NFD du CLOTURE.md : UNE intention de chemin NFC ; FileChanged sur le chemin NFC : aucun contournement")


def disque_insensible(ctx):
    """Vrai si le système de fichiers du dossier de travail est insensible à la normalisation (APFS, HFS+) : un dossier créé sous un nom NFC se retrouve sous son
    nom NFD. Calculé une fois (même recette que `disque_insensible` de test-cloture-gates.sh)."""
    if getattr(ctx, "_insensible", None) is None:
        d = ctx.unique("sonde-normalisation")
        os.makedirs(os.path.join(d, "\u00e9"))
        ctx._insensible = os.path.isdir(os.path.join(d, unicodedata.normalize("NFD", "\u00e9")))
    return ctx._insensible


def controle_d1_18(ctx, script):
    """A1, tour 3 (fix-46-a ; NFD ext4) : unité `01-été` créée sous son nom NFD SUR LE DISQUE (PLAN.md `ecrit: [livrables/rapport.md]`, livrable ASCII : patron de
    R-D1-07), SessionStart, poser-verdict.sh du dossier JUGÉ sur le chemin du DISQUE, puis FileChanged sur ce chemin : UNE ligne `moteur` de clé NFC dont le sha256
    est celui du VERDICT.md du disque, aucun contournement. Toute I/O du contrôle porte sur la forme du disque (NFD) ; seule la clé attendue au journal est NFC. Sur
    un système sensible à la normalisation, une ligne moteur hachée sous la forme NFC y serait perdue (le fichier n'existe pas sous ce nom) et le FileChanged
    suivant tracerait un contournement à tort."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    unite = "01-\u00e9t\u00e9"
    rel_nfc = ".planning/cycles/01-c/phases/%s" % unite
    rel_disque = jumeau_nfd(rel_nfc)
    lab = fabriquer_lab(ctx, "d1-18", ouvertes=(), closes=())
    dossier_disque = os.path.join(lab, *rel_disque.split("/"))
    ecrire(os.path.join(dossier_disque, "PLAN.md"), "---\necrit: [livrables/rapport.md]\n---\nplan\n")
    ecrire(os.path.join(lab, "livrables", "rapport.md"), "livrable\n")
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or err:
        return False, "SessionStart : code 0 attendu — obtenu rc=%d %s" % (rc, court(err))
    rc, out, err = lancer_script(ctx, [script_de(ctx, script, "poser-verdict.sh"), "--unite=" + dossier_disque, "--juge=juge-test", "--tentative=1", "--score=ok",
                                       "--constat=critere::passé"], lab)
    if rc != 0:
        return False, "poser-verdict.sh sur l'unité au nom de disque NFD : code 0 attendu — obtenu %d %s" % (rc, court(err))
    cle = rel_nfc + "/VERDICT.md"
    verdict_disque = os.path.join(dossier_disque, "VERDICT.md")
    fautes = []
    moteur = lignes_de(lab, "moteur", cle)
    if len(moteur) != 1 or moteur[0]["par"] != "poser-verdict.sh" or moteur[0]["sha"] != sha_du_fichier(verdict_disque):
        fautes.append("verdict posé dans une unité au nom de disque NFD : UNE ligne moteur de clé NFC attendue (sha256 du VERDICT.md du disque) — obtenu %s" % (
            [(m["par"], m["sha"][:12]) for m in moteur], ))
    rc, out, err = ctx.lancer(payload_fichier(lab, verdict_disque), cwd=lab, dossier=d)
    if rc != 0 or out != b"" or contournements(lab, cle):
        fautes.append("verdict posé dans une unité au nom de disque NFD, FileChanged sur le chemin du disque : aucun contournement attendu — obtenu rc=%d %s %d contournement(s)" % (
            rc, court(out), len(contournements(lab, cle))))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "unité 01-été au nom de disque NFD : poser-verdict.sh inscrit UNE ligne moteur de clé NFC (sha256 du VERDICT.md du disque), le FileChanged sur le chemin du disque "
                          "n'est pas un contournement")


def _fonctions(chemin, marqueur, noms):
    """{nom: ast.dump} des fonctions `noms` du corps Python du script (docstring comprise) et leur nombre de définitions."""
    arbre = ast.parse(corps_python(open(chemin, encoding="utf-8").read(), marqueur))
    res, compte = {}, {}
    for noeud in arbre.body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name in noms:
            res[noeud.name] = ast.dump(noeud)
            compte[noeud.name] = compte.get(noeud.name, 0) + 1
    return res, compte


def _charger(chemin, marqueur):
    """`inscrire_surveillance` du script, chargée dans un espace de noms où elle n'a que `os`, `stat` et `_jeton_journal` (comme dans le script)."""
    arbre = ast.parse(corps_python(open(chemin, encoding="utf-8").read(), marqueur))
    noeuds = [n for n in arbre.body if isinstance(n, ast.FunctionDef) and n.name in ("_jeton_journal", "inscrire_surveillance")]
    espace = {"os": os, "stat": __import__("stat")}
    exec(compile(ast.Module(body=noeuds, type_ignores=[]), chemin, "exec"), espace)
    return espace["inscrire_surveillance"]


def controle_d1_09(ctx, script):
    """`inscrire_surveillance` et `_jeton_journal` sont ast-identiques dans planning-hook.sh, recalc-planning.sh, poser-verdict.sh et deroger-gate.sh (UNE définition
    chacune) ; chaque copie, exécutée, inscrit UNE ligne encodée pour un chemin qui porte un saut de ligne, mode 0600, et n'inscrit RIEN (sans exception) quand le
    journal est un lien, un dossier ou que le dossier de planning est absent."""
    dumps = {}
    fautes = []
    for nom in ("planning-hook.sh", "recalc-planning.sh", "poser-verdict.sh", "deroger-gate.sh"):
        fonctions, compte = _fonctions(script_de(ctx, script, nom), MARQUEURS[nom], ("inscrire_surveillance", "_jeton_journal"))
        for fn in ("inscrire_surveillance", "_jeton_journal"):
            if compte.get(fn) != 1:
                fautes.append("%s : %d définition(s) de %s (attendu 1)" % (nom, compte.get(fn, 0), fn))
            dumps.setdefault(fn, {})[nom] = fonctions.get(fn)
    for fn, par_script in dumps.items():
        if len(set(par_script.values())) != 1:
            divergents = [nom for nom, v in par_script.items() if v != par_script["planning-hook.sh"]]
            fautes.append("%s n'est pas ast-identique à celle de planning-hook.sh dans %s" % (fn, divergents))
    if fautes:
        return False, "; ".join(fautes[:3])
    for nom in ("planning-hook.sh", "recalc-planning.sh", "poser-verdict.sh", "deroger-gate.sh"):
        f = _charger(script_de(ctx, script, nom), MARQUEURS[nom])
        lab = os.path.realpath(ctx.unique("lab-d1-09"))
        os.makedirs(os.path.join(lab, ".planning"))
        f(lab, "contournement", "a\nb c.md", "abc", "outil=x", "seance")
        lignes = lignes_journal(lab)
        mode = os.stat(chemin_journal(lab)).st_mode & 0o777
        if len(lignes) != 1 or not LIGNE_RE.match(lignes[0]) or "chemin=a%0Ab%20c.md" not in lignes[0] or "par=outil%3Dx" not in lignes[0] or mode != 0o600:
            fautes.append("%s : UNE ligne encodée (chemin=a%%0Ab%%20c.md, par=outil%%3Dx, mode 0600) attendue — obtenu %s mode=%o" % (nom, lignes, mode))
        ailleurs = os.path.join(lab, "ailleurs.log")
        ecrire(ailleurs, "")
        os.unlink(chemin_journal(lab))
        os.symlink(ailleurs, chemin_journal(lab))
        f(lab, "reference", ".planning/STATE.md", "abc", "p", "seance")
        if os.path.getsize(ailleurs) != 0:
            fautes.append("%s : journal en lien symbolique : aucune ligne écrite à travers le lien attendue" % nom)
        os.unlink(chemin_journal(lab))
        os.makedirs(chemin_journal(lab))
        f(lab, "reference", ".planning/STATE.md", "abc", "p", "seance")
        os.rmdir(chemin_journal(lab))
        f(os.path.join(lab, "inexistant"), "reference", ".planning/STATE.md", "abc", "p", "seance")
        if os.path.exists(os.path.join(lab, "inexistant")):
            fautes.append("%s : racine inexistante : rien créé attendu" % nom)
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "inscrire_surveillance et _jeton_journal ast-identiques dans les quatre scripts ; chaque copie : une ligne encodée pour un chemin à saut de ligne (0600), "
                          "aucune ligne ni exception pour un journal en lien ou en dossier, ni pour une racine absente")


# =================================================================================================
# R-D1-10 à R-D1-14 : réconciliation au SessionStart, signal, CwdChanged, fail-open, fenêtre de lecture
# =================================================================================================
def contexte_de(out):
    """`additionalContext` du SessionStart de la sortie, ou None."""
    doc = lire_objet(out)
    if not isinstance(doc, dict):
        return None
    corps = doc.get("hookSpecificOutput")
    return corps.get("additionalContext") if isinstance(corps, dict) else None


def controle_d1_10(ctx, script):
    """Références posées au SessionStart ; CLOTURE.md d'une unité ouverte créé « hors séance » par un script de test ; SessionStart -> UNE ligne
    `contournement` (source=reconciliation, sha256 du contenu créé), un `additionalContext` qui porte le signal D1 et le chemin, une ligne `signal` posée ;
    un troisième SessionStart sans changement : aucun signal, aucune ligne de plus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "d1-10", ouvertes=("01-u",), closes=())
    rel = ".planning/cycles/01-c/phases/01-u/CLOTURE.md"
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or err or contexte_de(out) is not None:
        return False, "premier SessionStart : références posées, aucun signal attendus — obtenu rc=%d %s" % (rc, court(out))
    contenu = "clôture écrite hors séance\n"
    ecrire(os.path.join(lab, *rel.split("/")), contenu)
    rc, out, err = session(ctx, d, lab)
    fautes = []
    if rc != 0 or err:
        fautes.append("SessionStart de réconciliation : code 0 attendu — obtenu rc=%d %s" % (rc, court(err)))
    ligne = contournements(lab, rel)
    if len(ligne) != 1 or ligne[0]["source"] != "reconciliation" or ligne[0]["sha"] != sha(contenu.encode("utf-8")):
        fautes.append("UNE ligne contournement (source=reconciliation, sha256 du contenu créé) attendue — obtenu %s" % [(l["source"], l["sha"][:12]) for l in ligne])
    signal = contexte_de(out)
    if not isinstance(signal, str) or not signal.startswith("[planning-core] D1 : 1 écriture(s) non expliquée(s)") or rel not in signal or "surveillance.log" not in signal:
        fautes.append("additionalContext : le signal D1 qui nomme le chemin attendu — obtenu %r" % (signal,))
    if len(lignes_de(lab, "signal")) != 1:
        fautes.append("UNE ligne signal attendue — obtenu %d" % len(lignes_de(lab, "signal")))
    avant = len(lignes_journal(lab))
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or contexte_de(out) is not None or len(lignes_journal(lab)) != avant or len(lignes_de(lab, "signal")) != 1:
        fautes.append("troisième SessionStart sans changement : aucun signal, aucune ligne de plus attendus — obtenu %r, %d ligne(s) de plus, %d signal(aux)"
                      % (contexte_de(out), len(lignes_journal(lab)) - avant, len(lignes_de(lab, "signal"))))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "CLOTURE.md créé hors séance : au SessionStart, un contournement (source=reconciliation) et le signal D1 avec le chemin, une ligne signal posée ; "
                          "troisième SessionStart sans changement : aucun signal")


def fonction_du_hook(ctx, script, nom):
    """Fonction `nom` du corps Python du hook DU DOSSIER jugé (réel ou mutant), exécutée seule dans un espace de noms jetable (le seul module fourni est
    `unicodedata` : `cle_recence` départage sur la forme NFC du nom, A1-readdir, fix-46-a tour 2) ; None si elle n'existe pas."""
    hook = os.path.join(_dossier(ctx, script), "planning-hook.sh")
    for noeud in ast.parse(corps_python(open(hook, encoding="utf-8").read())).body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name == nom:
            espace = {"unicodedata": unicodedata}
            exec(compile(ast.Module(body=[noeud], type_ignores=[]), hook, "exec"), espace)
            return espace[nom]
    return None


def controle_d1_16(ctx, script):
    """D1 surveille les unités non closes les PLUS RÉCENTES d'abord (A9, fix-46-a) : phases `01-ancienne` à `40-ancienne` et `41-active` -> au SessionStart S1 les quatre
    fichiers de `41-active` sont dans `watchPaths`, aucun de `01-ancienne`, 128 chemins, signal de borne présent, aucun chemin absolu dans l'additionalContext ; S2 sans
    changement -> aucun signal de borne, aucune ligne `borne` ni `signal` de plus ; PLAN.md de `41-active` réécrit hors moteur et phase `42-nouvelle` créée -> S3 : un
    contournement `source=reconciliation` pour ce PLAN.md, une seconde ligne `borne`, signal de borne de nouveau, fichiers de `42-nouvelle` surveillés ; `cle_recence`
    (chargée du hook jugé) trie `01-a`, `100-a`, `99-z`, `010-b`, `02-a` en `100-a`, `99-z`, `010-b`, `02-a`, `01-a`."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    ouvertes = tuple("%02d-ancienne" % i for i in range(1, 41)) + ("41-active",)
    lab = fabriquer_lab(ctx, "d1-16", ouvertes=ouvertes, closes=())
    phases = os.path.join(lab, ".planning", "cycles", "01-c", "phases")
    fautes = []
    rc, out, err = session(ctx, d, lab)
    chemins, doc = watch_paths(out)
    if rc != 0 or err or chemins is None:
        return False, "S1 : code 0 et watchPaths attendus — obtenu rc=%d %s" % (rc, court(out))
    actifs = [os.path.join(phases, "41-active", nom) for nom in UNITE]
    if [c for c in actifs if c not in chemins] or any("01-ancienne" in c for c in chemins) or len(chemins) != 128:
        fautes.append("S1 : les quatre fichiers de 41-active surveillés, aucun de 01-ancienne, 128 chemins attendus — obtenu %d chemin(s), 41-active : %d/4, 01-ancienne : %d" % (
            len(chemins), len([c for c in actifs if c in chemins]), len([c for c in chemins if "01-ancienne" in c])))
    signal = contexte_de(out)
    if not isinstance(signal, str) or "[planning-core] D1 : surveillance bornée" not in signal or "BORNE_WATCHPATHS" not in signal or lab in signal:
        fautes.append("S1 : le signal de borne sans chemin absolu attendu dans additionalContext — obtenu %r" % (signal,))
    comptes1 = (len(lignes_de(lab, "borne")), len(lignes_de(lab, "signal")))
    if comptes1 != (1, 1):
        fautes.append("S1 : UNE ligne borne et UNE ligne signal attendues — obtenu %s" % (comptes1,))
    # S2 : aucun changement
    avant = len(lignes_journal(lab))
    rc, out, err = session(ctx, d, lab)
    signal = contexte_de(out)
    if rc != 0 or (isinstance(signal, str) and "surveillance bornée" in signal) or len(lignes_journal(lab)) != avant or (len(lignes_de(lab, "borne")), len(lignes_de(lab, "signal"))) != comptes1:
        fautes.append("S2 : sans changement, aucun signal de borne et aucune ligne borne ni signal de plus attendus — obtenu %r, %d ligne(s) de plus, %d borne(s), %d signal(aux)" % (
            signal, len(lignes_journal(lab)) - avant, len(lignes_de(lab, "borne")), len(lignes_de(lab, "signal"))))
    # S3 : PLAN.md de 41-active réécrit hors moteur, phase 42-nouvelle créée
    plan_actif = ".planning/cycles/01-c/phases/41-active/PLAN.md"
    ecrire(os.path.join(lab, *plan_actif.split("/")), "---\necrit: []\n---\nplan réécrit hors moteur\n")
    ecrire(os.path.join(phases, "42-nouvelle", "PLAN.md"), "---\necrit: []\n---\nplan de 42-nouvelle\n")
    rc, out, err = session(ctx, d, lab)
    chemins3, _doc3 = watch_paths(out)
    if rc != 0 or chemins3 is None:
        return False, "S3 : code 0 et watchPaths attendus — obtenu rc=%d %s" % (rc, court(out))
    ligne = contournements(lab, plan_actif)
    if len(ligne) != 1 or ligne[0]["source"] != "reconciliation":
        fautes.append("S3 : UN contournement (source=reconciliation) pour le PLAN.md de 41-active attendu — obtenu %s" % [(l["source"]) for l in ligne])
    if len(lignes_de(lab, "borne")) != 2:
        fautes.append("S3 : une seconde ligne borne (la liste a changé) attendue — obtenu %d" % len(lignes_de(lab, "borne")))
    signal = contexte_de(out)
    if not isinstance(signal, str) or "surveillance bornée" not in signal:
        fautes.append("S3 : le signal de borne de nouveau attendu — obtenu %r" % (signal,))
    if [c for c in (os.path.join(phases, "42-nouvelle", nom) for nom in UNITE) if c not in chemins3]:
        fautes.append("S3 : les quatre fichiers de 42-nouvelle surveillés attendus")
    # l'ordre déclaré par le nom
    cle = fonction_du_hook(ctx, script, "cle_recence")
    if cle is None:
        fautes.append("cle_recence absente du hook : l'ordre de récence n'est pas déclaré")
    else:
        trie = sorted(["01-a", "100-a", "99-z", "010-b", "02-a"], key=cle, reverse=True)
        if trie != ["100-a", "99-z", "010-b", "02-a", "01-a"]:
            fautes.append("cle_recence trie 01-a, 100-a, 99-z, 010-b, 02-a en %s (attendu 100-a, 99-z, 010-b, 02-a, 01-a)" % trie)
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "41 phases ouvertes : les quatre fichiers de 41-active sont surveillés (aucun de 01-ancienne), signal de borne sans chemin absolu ; S2 sans changement : rien de plus ; "
                          "S3 (PLAN.md réécrit, phase 42 créée) : un contournement, une seconde ligne borne, le signal de nouveau, 42-nouvelle surveillée ; cle_recence : 100-a, 99-z, 010-b, 02-a, 01-a")


def copie_plafond(ctx, dossier, valeur):
    """Copie `observe` du hook du dossier jugé dont BORNE_OCTETS_RECONCILIATION vaut `valeur` (la ligne `# d1-plafond-reconciliation`, comptée exactement une fois)."""
    texte = observe_partout(open(os.path.join(dossier, "planning-hook.sh"), encoding="utf-8").read())
    lignes = [l for l in texte.split("\n") if "# d1-plafond-reconciliation" in l]
    if len(lignes) != 1 or not lignes[0].startswith("BORNE_OCTETS_RECONCILIATION = "):
        raise RuntimeError("la ligne `BORNE_OCTETS_RECONCILIATION = … # d1-plafond-reconciliation` est attendue exactement une fois (%d trouvée(s))" % len(lignes))
    texte = texte.replace(lignes[0], "BORNE_OCTETS_RECONCILIATION = %d  # d1-plafond-reconciliation" % valeur)
    d = ctx.unique("plafond")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
        fh.write(texte)
    os.chmod(os.path.join(d, "planning-hook.sh"), 0o755)
    return d


def controle_d1_17(ctx, script):
    """La réconciliation plafonne les octets hachés (A9, fix-46-a) : copie observe dont BORNE_OCTETS_RECONCILIATION vaut 4096 ; STATE.md et INDEX.md de 3000 octets ->
    référence posée pour STATE.md, AUCUNE ligne pour INDEX.md, une ligne `borne`, additionalContext qui nomme « BORNE_OCTETS_RECONCILIATION » et « .planning/INDEX.md » ;
    second SessionStart identique -> rien de plus ; copie observe ORDINAIRE : `cloture.log` creux de BORNE_OCTETS_LIVRABLES + 1 octets -> aucune ligne pour lui, une ligne
    `borne`, un signal qui le nomme (durée affichée)."""
    dossier_jugé = _dossier(ctx, script)
    fautes = []
    try:
        d = copie_plafond(ctx, dossier_jugé, 4096)
    except RuntimeError as exc:
        return False, str(exc)
    lab = fabriquer_lab(ctx, "d1-17", ouvertes=(), closes=())
    for nom in ("STATE.md", "INDEX.md"):
        ecrire(os.path.join(lab, ".planning", nom), "x" * 2999 + "\n")
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or err:
        return False, "SessionStart (plafond de 4096 octets) : code 0 attendu — obtenu rc=%d %s" % (rc, court(err))
    if len(lignes_de(lab, "reference", ".planning/STATE.md")) != 1 or lignes_de(lab, "reference", ".planning/INDEX.md") or [e for e in entrees_journal(lab) if e["chemin"] == ".planning/INDEX.md"]:
        fautes.append("plafond de 4096 octets : une référence pour STATE.md et AUCUNE ligne pour INDEX.md attendues — obtenu STATE %d, INDEX %d" % (
            len(lignes_de(lab, "reference", ".planning/STATE.md")), len([e for e in entrees_journal(lab) if e["chemin"] == ".planning/INDEX.md"])))
    signal = contexte_de(out)
    if len(lignes_de(lab, "borne")) != 1 or not isinstance(signal, str) or "BORNE_OCTETS_RECONCILIATION" not in signal or ".planning/INDEX.md" not in signal:
        fautes.append("plafond de 4096 octets : UNE ligne borne et un signal qui nomme BORNE_OCTETS_RECONCILIATION et .planning/INDEX.md attendus — obtenu %d borne(s), %r" % (len(lignes_de(lab, "borne")), signal))
    avant = len(lignes_journal(lab))
    rc, out, err = session(ctx, d, lab)
    signal = contexte_de(out)
    if rc != 0 or len(lignes_journal(lab)) != avant or (isinstance(signal, str) and "BORNE_OCTETS_RECONCILIATION" in signal):
        fautes.append("second SessionStart identique : aucune ligne de plus, aucun signal de borne attendus — obtenu %d ligne(s) de plus, %r" % (len(lignes_journal(lab)) - avant, signal))
    # copie ordinaire : un fichier surveillé au-delà de BORNE_OCTETS_LIVRABLES
    trouve = re.search(r"^BORNE_OCTETS_LIVRABLES = ([0-9]+)", open(os.path.join(dossier_jugé, "planning-hook.sh"), encoding="utf-8").read(), flags=re.M)
    borne_octets = int(trouve.group(1)) if trouve else 134217728
    lab2 = fabriquer_lab(ctx, "d1-17-creux", ouvertes=(), closes=())
    with open(os.path.join(lab2, ".planning", "cloture.log"), "wb") as fh:
        fh.truncate(borne_octets + 1)
    debut = time.monotonic()
    rc, out, err = session(ctx, ctx.copie_forcee(dossier_jugé, "observe"), lab2)
    duree = time.monotonic() - debut
    signal = contexte_de(out)
    if rc != 0 or [e for e in entrees_journal(lab2) if e["chemin"] == ".planning/cloture.log" and e["genre"] in ("reference", "contournement")]:
        fautes.append("cloture.log de BORNE_OCTETS_LIVRABLES + 1 octets : aucune ligne de référence ni de contournement attendue — obtenu rc=%d" % rc)
    if len(lignes_de(lab2, "borne")) != 1 or not isinstance(signal, str) or ".planning/cloture.log" not in signal:
        fautes.append("cloture.log hors borne : UNE ligne borne et un signal qui le nomme attendus — obtenu %d borne(s), %r" % (len(lignes_de(lab2, "borne")), signal))
    if script is None:
        print("DUREE d1-17-creux s=%.1f (affichée, jamais assertée)" % duree)
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "plafond de 4096 octets : STATE.md référencé, INDEX.md écarté (aucune ligne), une ligne borne, signal qui nomme BORNE_OCTETS_RECONCILIATION et .planning/INDEX.md, "
                          "second SessionStart sans rien de plus ; cloture.log creux au-delà de BORNE_OCTETS_LIVRABLES : aucune ligne, une ligne borne, signal qui le nomme")


def controle_d1_11(ctx, script):
    """Une écriture du moteur entre deux séances (recalc-planning.sh réécrit STATE.md et INDEX.md) : aucun contournement à la réconciliation, aucun signal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "d1-11", ouvertes=(), closes=())
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or err:
        return False, "premier SessionStart : code 0 attendu — obtenu rc=%d %s" % (rc, court(err))
    rc, out, err = lancer_recalc(ctx, script, lab)
    if rc != 0:
        return False, "recalc-planning.sh : code 0 attendu — obtenu %d %s" % (rc, court(err))
    if not lignes_de(lab, "moteur", ".planning/STATE.md"):
        return False, "recalc-planning.sh : une ligne moteur pour STATE.md attendue"
    rc, out, err = session(ctx, d, lab)
    fautes = []
    if rc != 0 or err or lignes_de(lab, "contournement") or lignes_de(lab, "signal") or contexte_de(out) is not None:
        fautes.append("SessionStart après une écriture du moteur : aucun contournement ni signal attendus — obtenu %d contournement(s), %d signal(aux), contexte %r"
                      % (len(lignes_de(lab, "contournement")), len(lignes_de(lab, "signal")), contexte_de(out)))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else "écriture du moteur entre deux séances : aucun contournement à la réconciliation, aucun signal")


def controle_d1_12(ctx, script):
    """CwdChanged d'un lab adhérent : `watchPaths` au PREMIER niveau ET sous `hookSpecificOutput` (`hookEventName: "CwdChanged"`), la même liste que le
    SessionStart ; FileChanged (fichier changé ou non) : stdout vide, jamais de `watchPaths`."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "d1-12")
    rc, out, err = session(ctx, d, lab)
    liste_session, doc = watch_paths(out)
    if liste_session is None:
        return False, doc
    rc, out, err = ctx.lancer(payload_cwd(lab), cwd=lab, dossier=d)
    fautes = []
    doc = lire_objet(out)
    if rc != 0 or err or not isinstance(doc, dict):
        return False, "CwdChanged : un objet JSON, code 0 attendus — obtenu rc=%d %s" % (rc, court(out))
    corps = doc.get("hookSpecificOutput")
    if sorted(doc) != ["hookSpecificOutput", "watchPaths"]:
        fautes.append("CwdChanged : clés de premier niveau hookSpecificOutput et watchPaths seulement attendues — obtenu %s" % sorted(doc))
    if sorted(doc.get("watchPaths") or []) != sorted(liste_session):
        fautes.append("CwdChanged : watchPaths de premier niveau = la liste du SessionStart attendu")
    if not isinstance(corps, dict) or corps.get("hookEventName") != "CwdChanged" or sorted(corps.get("watchPaths") or []) != sorted(liste_session) or sorted(corps) != ["hookEventName", "watchPaths"]:
        fautes.append("CwdChanged : hookSpecificOutput {hookEventName: CwdChanged, watchPaths: la liste} attendu — obtenu %s" % court(json.dumps(corps)))
    state = os.path.join(lab, ".planning", "STATE.md")
    for etat in ("sans changement", "changé hors moteur"):
        if etat != "sans changement":
            ecrire(state, "réécrit hors moteur\n")
        rc, out, err = ctx.lancer(payload_fichier(lab, state), cwd=lab, dossier=d)
        if rc != 0 or out != b"" or err:
            fautes.append("FileChanged (%s) : stdout vide, jamais de watchPaths attendus — obtenu rc=%d %s" % (etat, rc, court(out)))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "CwdChanged : watchPaths au premier niveau ET sous hookSpecificOutput (hookEventName CwdChanged), la liste du SessionStart ; FileChanged : stdout vide")


MODES_D1 = (("SessionStart", "evt-mode-sessionstart"), ("CwdChanged", "evt-mode-cwdchanged"), ("FileChanged", "evt-mode-filechanged"))
INTERDITS_D1 = ('"deny"', '"block"', "permissionDecision", '"decision"')


def controle_d1_13(ctx, script):
    """Erreur injectée dans chaque mode de D1 (SessionStart, CwdChanged, FileChanged) : stdout vide, stderr vide, code 0, aucun refus ; aucune sortie
    de D1 (SessionStart avec signal, CwdChanged) ne contient `deny`, `block` ni `decision`."""
    base = script
    fautes = []
    for evt, marque in MODES_D1:
        dossier, raison = make_hook_mutant(ctx, "D1-INJ-" + evt, "return None  # " + marque, 'raise RuntimeError("faute injectee")', base=base)
        if dossier is None:
            return False, "mutant d'injection invalide (%s) : %s" % (evt, raison)
        lab = fabriquer_lab(ctx, "d1-13-" + evt.lower())
        etat = os.path.join(lab, ".planning", "STATE.md")
        brut = {"SessionStart": payload_session(lab), "CwdChanged": payload_cwd(lab), "FileChanged": payload_fichier(lab, etat)}[evt]
        rc, out, err = ctx.lancer(brut, cwd=lab, dossier=dossier)
        if rc != 0 or out != b"" or err:
            fautes.append("faute dans le mode %s : stdout vide, stderr vide, code 0 (fail-open, aucun refus) attendus — obtenu rc=%d %s %s" % (evt, rc, court(out), court(err)))
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "d1-13-sorties", ouvertes=("01-u",), closes=())
    session(ctx, d, lab)
    ecrire(os.path.join(lab, ".planning", "cycles", "01-c", "phases", "01-u", "CLOTURE.md"), "hors séance\n")
    rc, out_s, err = session(ctx, d, lab)
    rc2, out_c, err2 = ctx.lancer(payload_cwd(lab), cwd=lab, dossier=d)
    if not (contexte_de(out_s) or "").startswith("[planning-core] D1 :") or not out_c:
        fautes.append("témoin : un SessionStart avec signal et un CwdChanged non vides attendus")
    for nom, out in (("SessionStart", out_s), ("CwdChanged", out_c)):
        trouve = [m for m in INTERDITS_D1 if m in out.decode("utf-8", "replace")]
        if trouve:
            fautes.append("la sortie de %s contient %s (D1 ne refuse jamais)" % (nom, trouve))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "faute injectée dans le mode SessionStart, CwdChanged, puis FileChanged : stdout vide, code 0, aucun refus ; les sorties de D1 ne contiennent ni deny, ni block, ni decision")


LIGNE_REMPLISSAGE = "2026-10-05T00:00:00Z  genre=reference  chemin=.planning/remplissage-%07d.md  sha256=" + "0" * 64 + "  par=planning-hook.sh  source=seance\n"


def journal_de_5_mio(lab, ref_au_debut):
    """Journal de plus de 5 Mio : une référence ANCIENNE de STATE.md, au début (hors de la fenêtre de lecture des 4 Mio de fin) ou à la fin (dans la fenêtre),
    et des lignes de remplissage valides pour des chemins hors liste."""
    ref = "2026-10-05T00:00:00Z  genre=reference  chemin=.planning/STATE.md  sha256=" + sha(b"ancien contenu de STATE.md") + "  par=planning-hook.sh  source=seance\n"
    corps = "".join(LIGNE_REMPLISSAGE % i for i in range(29000))
    texte = (ref + corps) if ref_au_debut else (corps + ref)
    ecrire(chemin_journal(lab), texte)
    return os.path.getsize(chemin_journal(lab))


def controle_d1_14(ctx, script):
    """Journal de plus de 5 Mio dont la dernière référence de STATE.md est HORS de la fenêtre de lecture (4 Mio de fin) : première observation (une référence
    de plus, aucun contournement, limite (ba)) ; jumeau : la même référence DANS la fenêtre -> un contournement. Coût : un SessionStart sur 128 chemins lit
    chaque fichier une seule fois (mesure structurelle : nombre de lectures égal au nombre de chemins, jamais une borne d'horloge)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    fautes = []
    lab_a = fabriquer_lab(ctx, "d1-14-hors", ouvertes=(), closes=())
    lab_b = fabriquer_lab(ctx, "d1-14-dans", ouvertes=(), closes=())
    taille_a, taille_b = journal_de_5_mio(lab_a, True), journal_de_5_mio(lab_b, False)
    if min(taille_a, taille_b) < 5 * 1024 * 1024:
        return False, "journal de 5 Mio au moins attendu — obtenu %d et %d octets" % (taille_a, taille_b)
    rc, out, err = session(ctx, d, lab_a)
    ref_a = [e for e in entrees_journal_de_fin(lab_a) if e["chemin"] == ".planning/STATE.md" and e["source"] == "reconciliation"]
    if rc != 0 or err or watch_paths(out)[0] is None:
        fautes.append("SessionStart (référence hors fenêtre) : code 0 et watchPaths attendus — obtenu rc=%d %s" % (rc, court(out)))
    if [e for e in ref_a if e["genre"] == "contournement"] or len([e for e in ref_a if e["genre"] == "reference"]) != 1 or contexte_de(out) is not None:
        fautes.append("référence hors de la fenêtre : première observation (UNE référence, aucun contournement, aucun signal) attendue — obtenu %s" % [(e["genre"]) for e in ref_a])
    rc, out, err = session(ctx, d, lab_b)
    ref_b = [e for e in entrees_journal_de_fin(lab_b) if e["chemin"] == ".planning/STATE.md" and e["source"] == "reconciliation"]
    if [e["genre"] for e in ref_b] != ["contournement", "reference"]:
        fautes.append("jumeau : la même référence dans la fenêtre : contournement puis référence attendus — obtenu %s" % [e["genre"] for e in ref_b])
    # Coût structurel : une lecture par fichier de la liste
    hook = os.path.join(_dossier(ctx, script), "planning-hook.sh")
    espace = {"__name__": "d1_mesure"}
    exec(compile(corps_python(open(hook, encoding="utf-8").read()), hook, "exec"), espace)
    lab_c = fabriquer_lab(ctx, "d1-14-cout", ouvertes=tuple("%02d-unite" % i for i in range(1, 41)), closes=())
    liste, tronquee = espace["chemins_surveilles"](lab_c)
    for chemin in liste:
        if not os.path.exists(chemin):
            ecrire(chemin, "contenu de " + os.path.basename(chemin) + "\n")
    compteur = {}
    reel = os.open

    def compte(chemin, *args, **kwargs):
        compteur[str(chemin)] = compteur.get(str(chemin), 0) + 1
        return reel(chemin, *args, **kwargs)

    os.open = compte
    try:
        espace["reconcilier"](lab_c, liste, tronquee)
    finally:
        os.open = reel
    lectures = [compteur.get(c, 0) for c in liste]
    if len(liste) != 128 or not tronquee or lectures != [1] * 128:
        fautes.append("128 chemins lus UNE fois chacun attendus — obtenu %d chemin(s), %d lecture(s), maximum %d par chemin" % (len(liste), sum(lectures), max(lectures or [0])))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "journal de %.1f Mio : référence hors fenêtre = première observation (aucun contournement), la même dans la fenêtre = contournement ; SessionStart sur 128 "
                          "chemins : 128 lectures, une par chemin" % (taille_a / 1048576.0))


def entrees_journal_de_fin(lab):
    """Les entrées du journal lues sur les derniers 200 Kio (les lignes écrites par la réconciliation)."""
    chemin = chemin_journal(lab)
    taille = os.path.getsize(chemin)
    with open(chemin, "rb") as fh:
        fh.seek(max(0, taille - 200000))
        brut = fh.read().decode("utf-8", "replace").split("\n")
    res = []
    for ligne in brut:
        m = LIGNE_RE.match(ligne)
        if m:
            res.append({"genre": m.group(2), "chemin": urllib.parse.unquote(m.group(3)), "sha": m.group(4), "par": m.group(5), "source": m.group(6)})
    return res


# --- Mutants --------------------------------------------------------------------------------------------------------
def drapeaux_utilisables():
    """Vrai si `chflags uchg` (journal immuable : droits intacts, ouverture en écriture refusée) est disponible ici (macOS, BSD) ; sinon la branche d'ouverture
    de `anomalie_journal` n'a pas de cas portable et le mutant qui la retire est déclaré non applicable."""
    try:
        sonde = tempfile.mkdtemp(prefix="d1-chflags-")
        chemin = os.path.join(sonde, "f")
        ecrire(chemin, "x")
        p = subprocess.run(["chflags", "uchg", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if p.returncode == 0:
            subprocess.run(["chflags", "nouchg", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        shutil.rmtree(sonde, ignore_errors=True)
        return p.returncode == 0
    except (OSError, ValueError):
        return False


def controle_d1_19(ctx, script):
    """(A6, P46 lot B, b3) Le journal de D1 réduit au silence par Bash est SIGNALÉ au SessionStart, sans écrire : lien (vers /dev/null), droits retirés
    (chmod 000), journal immuable (`chflags uchg`, là où il existe), journal absent alors que l'état précédent existe (séance de reprise, ou cache du recalcul).
    Jumeaux : première séance sans journal : aucun signal ; un journal sain : aucun signal ; le signal d'absence n'est pas répété (la séance suivante, le journal
    recréé est sain)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    fautes, vus = [], []

    def verifier(nom, out, mots):
        signal = contexte_de(out)
        if mots is None:
            if signal is not None:
                fautes.append("%s : aucun signal attendu — obtenu %r" % (nom, signal))
            return
        if not isinstance(signal, str) or not all(m in signal for m in ("[planning-core] D1", "surveillance.log") + mots):
            fautes.append("%s : un signal de D1 qui porte %s attendu — obtenu %r" % (nom, list(mots), signal))
        elif "/" in signal.replace(".planning/surveillance.log", ""):
            fautes.append("%s : aucun chemin absolu dans le signal — obtenu %r" % (nom, signal))

    # A. lien vers /dev/null
    lab = fabriquer_lab(ctx, "d1-19a")
    session(ctx, d, lab)
    os.remove(chemin_journal(lab))
    os.symlink("/dev/null", chemin_journal(lab))
    rc, out, err = session(ctx, d, lab)
    verifier("lien", out, ("régulier",))
    if not os.path.islink(chemin_journal(lab)):
        fautes.append("lien : le journal en lien n'est ni suivi ni remplacé")
    vus.append("lien")
    # B. droits retirés
    lab = fabriquer_lab(ctx, "d1-19b")
    session(ctx, d, lab)
    os.chmod(chemin_journal(lab), 0)
    try:
        rc, out, err = session(ctx, d, lab)
    finally:
        os.chmod(chemin_journal(lab), 0o600)
    verifier("chmod 000", out, ("droits",))
    vus.append("droits")
    # C. absent, séance de reprise ; puis la séance suivante : rien (anti-répétition)
    lab = fabriquer_lab(ctx, "d1-19c")
    session(ctx, d, lab)
    os.remove(chemin_journal(lab))
    rc, out, err = ctx.lancer(payload_session(lab, "resume"), cwd=lab, dossier=d)
    verifier("absent (reprise)", out, ("absent",))
    rc, out, err = ctx.lancer(payload_session(lab, "resume"), cwd=lab, dossier=d)
    verifier("absent : séance suivante", out, None)
    vus.append("absent-reprise")
    # D. absent, trace du recalcul (cache) à `startup`
    lab = fabriquer_lab(ctx, "d1-19d")
    ecrire(os.path.join(lab, ".planning", ".recalc-cache.json"), "{}")
    rc, out, err = session(ctx, d, lab)
    verifier("absent (cache du recalcul)", out, ("absent",))
    vus.append("absent-cache")
    # E. jumeaux : première séance sans journal ni trace ; reprise sur journal sain
    lab = fabriquer_lab(ctx, "d1-19e")
    rc, out, err = session(ctx, d, lab)
    verifier("première séance sans journal", out, None)
    rc, out, err = ctx.lancer(payload_session(lab, "resume"), cwd=lab, dossier=d)
    verifier("reprise sur journal sain", out, None)
    vus.append("jumeaux")
    # F. journal immuable (droits intacts, ouverture en écriture refusée)
    if drapeaux_utilisables():
        lab = fabriquer_lab(ctx, "d1-19f")
        session(ctx, d, lab)
        subprocess.run(["chflags", "uchg", chemin_journal(lab)])
        try:
            rc, out, err = session(ctx, d, lab)
        finally:
            subprocess.run(["chflags", "nouchg", chemin_journal(lab)])
        verifier("journal immuable", out, ("inscriptible",))
        vus.append("immuable")
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "journal en lien, sans droits%s, absent alors que l'état précédent existe (reprise ; cache du recalcul) : un signal D1 qui le nomme, sans chemin absolu, "
                          "rien d'écrit ; jumeaux (première séance sans journal, journal sain, séance suivante) : aucun signal" % (", immuable" if "immuable" in vus else ""))


def original_de(ctx, ident, controle):
    """Résultat d'un contrôle sur le script réel, calculé une seule fois (les sections et les mutants lisent la même exécution)."""
    if ident not in ctx.originaux:
        ctx.originaux[ident] = controle(ctx, None)
    return ctx.originaux[ident]


def tuer(ctx, ident, motif, remplacement, id_controle, controle, script="planning-hook.sh"):
    """Preuve d'opposabilité : le contrôle passe sur l'original, le témoin est inchangé sous le mutant, le contrôle rougit sous le mutant. `script` : le script
    du moteur que le mutant réécrit (le hook par défaut)."""
    if script == "planning-hook.sh":
        dossier, raison = make_hook_mutant(ctx, ident, motif, remplacement)
    else:
        dossier, raison = make_scripts_mutant(ctx, ident, script, motif, remplacement)
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
    rendre("R-D1-20", "Q-B : .planning/.gitignore posé au SessionStart d'un lab adhérent, idempotent", controle_d1_20, ctx)


def sec_mutants_base(ctx):
    # Adhésion ignorée : la sortie silencieuse d'un lab non adhérent retirée (la commande rejouée n'a pas son pré-filtre, `np`)
    tuer(ctx, "D1-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-D1-03", controle_d1_03)
    tuer(ctx, "D1-DOSSIER", "# d1-fichier-par-fichier", "liste.append(dossier)  # d1-fichier-par-fichier", "R-D1-01", controle_d1_01)
    # N-1 (audit-46-b) : le filtre « absent ou fichier régulier » retiré -> un dossier ou un lien entre dans la liste
    tuer(ctx, "D1-JAMAIS-UN-DOSSIER", "# d1-jamais-un-dossier", "return True  # d1-jamais-un-dossier", "R-D1-01", controle_d1_01)
    tuer(ctx, "D1-BORNE", "# d1-borne", "if False:  # d1-borne", "R-D1-02", controle_d1_02)
    tuer(ctx, "D1-TRACE", "# d1-contournement", 'return ["reference"]  # d1-contournement', "R-D1-04", controle_d1_04)
    # Q-B : l'appel retiré, l'idempotence retirée (la ligne s'ajoute à chaque séance), l'écriture atomique remplacée par une écriture en place (le temporaire reste)
    tuer(ctx, "D1-GITIGNORE-APPEL", "# gitignore-appel", "pass  # gitignore-appel", "R-D1-20", controle_d1_20)
    tuer(ctx, "D1-GITIGNORE-IDEMPOTENT", "# gitignore-idempotent", "if False:  # gitignore-idempotent", "R-D1-20", controle_d1_20)
    tuer(ctx, "D1-GITIGNORE-ATOMIQUE", "# gitignore-atomique", "open(chemin, \"wb\").write(contenu)  # gitignore-atomique", "R-D1-20", controle_d1_20)


def sec_moteur(ctx):
    rendre("R-D1-06", "le recalcul inscrit ce qu'il écrit", controle_d1_06, ctx)
    rendre("R-D1-07", "pose de verdict, dérogation et consommation inscrites", controle_d1_07, ctx)
    rendre("R-D1-08", "une écriture par outil laissée passer est une intention, une seule fois", controle_d1_08, ctx)
    rendre("R-D1-09", "la fonction qui inscrit est ast-identique dans les quatre scripts", controle_d1_09, ctx)
    rendre("R-D1-15", "A1 : un chemin NFD est tracé sous sa forme NFC", controle_d1_15, ctx)
    rendre("R-D1-18", "A1, tour 3 : un verdict posé dans une unité au nom de disque NFD est expliqué par sa ligne moteur", controle_d1_18, ctx)


def sec_mutants_moteur(ctx):
    tuer(ctx, "D1-MOTEUR", "# d1-moteur-state", "pass  # d1-moteur-state", "R-D1-06", controle_d1_06, script="recalc-planning.sh")
    tuer(ctx, "D1-GITIGNORE-MODELE", '".gitignore",', '"gitignore-neutre",', "R-D1-05", controle_d1_05, script="recalc-planning.sh")
    tuer(ctx, "D1-INTENTION", "# d1-intention", "pass  # d1-intention", "R-D1-08", controle_d1_08)
    tuer(ctx, "D1-INTENTION-REUTILISEE", "# d1-apres", "apres = entrees  # d1-apres", "R-D1-08", controle_d1_08)
    tuer(ctx, "D1-NFC", "# nfc-d1", "composants = os.path.relpath(os.path.join(os.path.realpath(parent), nom), racine).split(os.sep)  # nfc-d1", "R-D1-15", controle_d1_15)
    # I/O de la ligne moteur d'un verdict sur la forme NFC (HEAD de fix-46-a tour 2) : opposable seulement sur un système sensible à la normalisation (sur APFS, la forme
    # NFC désigne le même dossier que le nom du disque)
    if disque_insensible(ctx):
        ok("MUT-D1-MOTEUR-NFD non applicable ici : système de fichiers insensible à la normalisation (le mutant n'y est pas opposable)")
    else:
        tuer(ctx, "D1-MOTEUR-NFD", "# d1-moteur-verdict", 'inscrire_ecriture_moteur(racine, unite_rel + "/VERDICT.md", "poser-verdict.sh")  # d1-moteur-verdict',
             "R-D1-18", controle_d1_18, script="poser-verdict.sh")
    # Une copie divergente : la fonction de poser-verdict.sh perd la garde du lien (le contrôle des arbres rougit)
    tuer(ctx, "D1-AST", "if os.path.islink(planning) or (", "if os.path.islink(planning):", "R-D1-09", controle_d1_09, script="poser-verdict.sh")


def sec_reconciliation(ctx):
    rendre("R-D1-10", "réconciliation par hash au SessionStart et signal", controle_d1_10, ctx)
    rendre("R-D1-11", "une écriture du moteur entre deux séances n'est pas un contournement", controle_d1_11, ctx)
    rendre("R-D1-12", "CwdChanged : deux formes de watchPaths ; FileChanged : jamais de watchPaths", controle_d1_12, ctx)
    rendre("R-D1-13", "fail-open : une erreur de D1 sort en silence, aucun refus", controle_d1_13, ctx)
    rendre("R-D1-14", "fenêtre de lecture du journal et coût du SessionStart", controle_d1_14, ctx)
    rendre("R-D1-16", "les unités les plus récentes d'abord, la borne signalée sans répétition", controle_d1_16, ctx)
    rendre("R-D1-17", "la réconciliation plafonne les octets hachés et le signale", controle_d1_17, ctx)
    rendre("R-D1-19", "A6 : un journal de D1 réduit au silence par Bash est signalé au SessionStart", controle_d1_19, ctx)


def sec_mutants_reconciliation(ctx):
    tuer(ctx, "D1-RECONCILIATION", "# d1-reconciliation", "genres = []  # d1-reconciliation", "R-D1-10", controle_d1_10)
    tuer(ctx, "D1-SIGNAL-REPETE", "# d1-signal", "pass  # d1-signal", "R-D1-10", controle_d1_10)
    # Une erreur de D1 transformée en refus : la branche d'erreur des trois événements émet un deny (la commande rejouée n'a pas son pré-filtre)
    tuer(ctx, "D1-REFUS", "# evt-erreur-d1", 'sortie_refus(["[planning-core] erreur de D1"])  # evt-erreur-d1', "R-D1-13", controle_d1_13)
    # FileChanged renvoie la liste : le mode émet lui-même l'objet de SessionStart
    tuer(ctx, "D1-WATCH-FILECHANGED", "return None  # evt-mode-filechanged",
         'sortie_d1(sortie_surveillance(EVT_SESSION_START, chemins_surveilles(racine)[0], None)); return None  # evt-mode-filechanged', "R-D1-12", controle_d1_12)
    tuer(ctx, "D1-FENETRE", "# d1-fenetre", "debut = 0  # d1-fenetre", "R-D1-14", controle_d1_14)
    tuer(ctx, "D1-ORDRE", "# d1-recence-phases", "for phase in _sous_dossiers(phases):  # d1-recence-phases", "R-D1-16", controle_d1_16)
    tuer(ctx, "D1-ANNONCE-BORNE", "# d1-annonce-borne", "if False:  # d1-annonce-borne", "R-D1-16", controle_d1_16)
    tuer(ctx, "D1-IDENTITE-BORNE", "# d1-identite-borne", "if True:  # d1-identite-borne", "R-D1-16", controle_d1_16)
    tuer(ctx, "D1-OCTETS", "# d1-octets-exclus", "if False:  # d1-octets-exclus", "R-D1-17", controle_d1_17)
    # A6 : chaque contrôle d'`anomalie_journal` retiré seul, et le signal lui-même
    tuer(ctx, "D1-JOURNAL-SIGNAL", "# d1-journal-signal", "if False:  # d1-journal-signal", "R-D1-19", controle_d1_19)
    tuer(ctx, "D1-JOURNAL-ETAT", "# d1-journal-etat", "anomalie = None  # d1-journal-etat", "R-D1-19", controle_d1_19)
    tuer(ctx, "D1-JOURNAL-IRREGULIER", "# d1-journal-irregulier", "if False:  # d1-journal-irregulier", "R-D1-19", controle_d1_19)
    tuer(ctx, "D1-JOURNAL-DROITS", "# d1-journal-droits", "if False:  # d1-journal-droits", "R-D1-19", controle_d1_19)
    tuer(ctx, "D1-JOURNAL-ABSENT", "# d1-journal-absent", "precedent = False  # d1-journal-absent", "R-D1-19", controle_d1_19)
    tuer(ctx, "D1-JOURNAL-PREMIERE-SEANCE", "# d1-journal-absent", "precedent = True  # d1-journal-absent", "R-D1-19", controle_d1_19)
    if drapeaux_utilisables():
        tuer(ctx, "D1-JOURNAL-OUVERTURE", "# d1-journal-ouverture", "pass  # d1-journal-ouverture", "R-D1-19", controle_d1_19)
    else:
        ok("MUT-D1-JOURNAL-OUVERTURE non applicable ici : pas de `chflags` (aucun cas portable de journal aux droits intacts mais inscriptible en refus)")


SECTIONS = {
    "base": sec_base,
    "mutants_base": sec_mutants_base,
    "moteur": sec_moteur,
    "mutants_moteur": sec_mutants_moteur,
    "reconciliation": sec_reconciliation,
    "mutants_reconciliation": sec_mutants_reconciliation,
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
  run_sections "${VF_D1_SECTIONS:-base,mutants_base,moteur,mutants_moteur,reconciliation,mutants_reconciliation}"
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
