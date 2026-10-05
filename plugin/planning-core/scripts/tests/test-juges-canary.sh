#!/usr/bin/env bash
# test-juges-canary.sh — canary de juge, C-16 (Phase 46, 46-09 ; CLOT-08 ; P46-D-06, P46-D-06a, P46-D-13, P46-D-16) : « un juge qui n'a pas prouvé qu'il sait
# refuser n'est jamais vert ». Le hook est rejoué PAR LA COMMANDE ENREGISTRÉE (lue dans hooks.json, sous /bin/sh -c), jamais par un appel direct au script
# (P45-D-20) ; les cas tournent sur des COPIES du hook à l'armement FORCÉ (`copie_forcee`), jamais sur l'état livré, qui change à chaque armement :
# `observe` pour tout, ou `g6` (G6 et G5 armés ; G3, G4 et G4′ restent à observe, discipline du correctif 5c46c503). Les verdicts de canary des fixtures
# sont posés par la VRAIE poser-verdict.sh (forme de juge de 46-01), jamais par un hash écrit à la main ; seuls les jumeaux négatifs (verdict invalide)
# sont fabriqués.
#
# Familles :
#   R-JUGE-01  lab adhérent à deux juges (`juge-a` sans dossier, `juge-b` dont la sortie piégée vise `critere-x` et dont le verdict de canary, posé par la vraie
#              commande, porte `critere-x::échec`) : SessionStart (source startup) -> UNE ligne d'`additionalContext` qui compte 1 prouvé et nomme `juge-a`
#              sans preuve, aucun refus, code 0 ; au plus trois noms par classe, suivis du reste compté (cinq juges sans dossier : trois noms et « 2 autre(s) »)
#   R-JUGE-02  aucun juge (agents d'autres rôles seulement, pas de `.claude/agents/`, juge du COMPTE seulement) -> aucune ligne ; lab dev avec juges et sans
#              dossier -> stdout d'octet vide, arbre identique (commande complète ET cœur seul) ; jumeau adhérent : la ligne est là
#   R-JUGE-03  SessionStart de source `resume`, `compact`, `clear` ou sans source : aucune ligne de juge, la liste surveillée de D1 reste émise (jumeau : startup)
# Mutants (chacun tué par un contrôle, trace assertion · attendu (original) · obtenu (mutant)) :
#   MUT-JUGE-SANS-PREUVE-VERT (un juge sans dossier compté prouvé -> R-JUGE-01), MUT-JUGE-ADHESION (adhésion ignorée, commande sans pré-filtre -> R-JUGE-02),
#   MUT-JUGE-SOURCE (la source du SessionStart n'est plus filtrée -> R-JUGE-03).
# Variables : VF_JUGES_SECTIONS=<liste> pour ne rejouer qu'une partie (sections : base, mutants_base).
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
    else echo "[test-juges-canary] python3 requis" >&2; exit 1; fi
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
cat > "$AIDES" <<'PY_AIDES_JUGES_EOF'
import hashlib
import json
import os
import re
import subprocess
import sys

TOKEN = "{{VF_SCRIPTS}}"
PREFIXE_SIGNAL = "[planning-core] juges (C-16) :"


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
    """SessionStart ; `source` None : la clé est omise."""
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "hook_event_name": "SessionStart", "model": "modele-test"}
    if source is not None:
        obj["source"] = source
    return _j(obj)


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


def contexte_de(out):
    """`additionalContext` du SessionStart de la sortie, ou None."""
    doc = lire_objet(out)
    if not isinstance(doc, dict):
        return None
    corps = doc.get("hookSpecificOutput")
    return corps.get("additionalContext") if isinstance(corps, dict) else None


def chemins_de(out):
    """`watchPaths` du SessionStart de la sortie, ou None."""
    doc = lire_objet(out)
    if not isinstance(doc, dict):
        return None
    corps = doc.get("hookSpecificOutput")
    return corps.get("watchPaths") if isinstance(corps, dict) else None


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
        # Pré-filtre hors adhésion : le cœur seul est rejoué par la couche shell d'avant le pré-filtre (le bloc retiré, octet pour octet) ; la commande
        # COMPLÈTE est rejouée par les contrôles qui mesurent le silence d'un lab non adhérent (R-JUGE-02).
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


# --- Labs, juges, verdicts de canary, arbres -----------------------------------------------------------------------------------
def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)


def def_juge(nom):
    """Définition d'un JUGE (rôle dérivé `juge` : Write et Edit retirés, aucune allowlist Agent)."""
    return "---\nname: %s\ndescription: juge synthétique d'un cas de test, jamais exécuté\ndisallowedTools: Write, Edit\n---\nCorps.\n" % nom


def def_producteur(nom):
    return "---\nname: %s\ndescription: producteur synthétique d'un cas de test, jamais exécuté\ntools: Read, Bash\n---\nCorps.\n" % nom


def def_manager(nom):
    return "---\nname: %s\ndescription: manager synthétique d'un cas de test, jamais exécuté\ntools: Read, Agent(%s-worker)\n---\nCorps.\n" % (nom, nom)


def fabriquer_lab(ctx, nom, agents=None, adherent=True):
    """Lab jetable (chemin physique) : `.planning/config.json` (adhérent cycles-v1, sinon dev) et les définitions d'agents `agents` {nom: texte} sous
    `.claude/agents/` (aucun dossier `.claude/` si `agents` est None)."""
    lab = os.path.realpath(ctx.unique("lab-" + nom))
    os.makedirs(lab, exist_ok=True)
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "%s"}' % ("cycles-v1" if adherent else "2.0"))
    for agent, texte in (agents or {}).items():
        ecrire(os.path.join(lab, ".claude", "agents", agent + ".md"), texte)
    return lab


def texte_sortie_piegee(juge, critere):
    return ("---\njuge: %s\ncritere_vise: %s\nprovenance: exemple raté fabriqué à la main pour un cas de test\n---\n\n# Sortie piégée\n\n"
            "Un rapport qui viole délibérément le critère %s.\n" % (juge, critere, critere))


def ecrire_sortie_piegee(lab, juge, critere, texte=None):
    chemin = os.path.join(lab, ".planning", "juges", juge, "SORTIE-PIEGEE.md")
    ecrire(chemin, texte if texte is not None else texte_sortie_piegee(juge, critere))
    return chemin


def poser(ctx, lab, juge, constats, tentative=1):
    """Pose le verdict de canary de `juge` par la VRAIE poser-verdict.sh (forme de juge de 46-01). Rend (code, sortie standard, erreur standard)."""
    args = ["bash", os.path.join(ctx.scripts_dir, "poser-verdict.sh"), "--unite=" + os.path.join(lab, ".planning", "juges", juge), "--juge=" + juge,
            "--tentative=" + str(tentative), "--score=8/10"] + ["--constat=" + c for c in constats]
    p = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), cwd=lab, timeout=120)
    return p.returncode, p.stdout, p.stderr


def juge_prouve(ctx, lab, juge, critere="critere-x"):
    """Fixture : sortie piégée qui vise `critere` et verdict posé par la vraie commande avec `critere::échec`. Rend None, ou le message d'échec de la pose."""
    ecrire_sortie_piegee(lab, juge, critere)
    rc, out, err = poser(ctx, lab, juge, [critere + "::échec", "critere-y::passé"])
    return None if rc == 0 else "poser-verdict.sh : code 0 attendu — obtenu rc=%d %s" % (rc, court(err))


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


def temoin(ctx, dossier):
    """Témoin : Write d'une cible neutre d'un lab adhérent -> silence (aucun mutant du canary de juge ne l'affecte)."""
    lab = fabriquer_lab(ctx, "temoin")
    d = ctx.copie_forcee(dossier, "observe")
    rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, ".planning", "notes.md")), cwd=lab, dossier=d)
    return verdict_de(rc, out) == "silence" and not err, verdict_de(rc, out)


def _dossier(ctx, script):
    return script if script else ctx.scripts_dir


def session(ctx, hook_dir, lab, source="startup", np=True):
    """SessionStart sur la copie du hook de `hook_dir` : rend (rc, out, err)."""
    return ctx.lancer(payload_session(lab, source), cwd=lab, dossier=hook_dir, np=np)


def ligne_de_juges(out):
    """(ligne, fautes) : l'`additionalContext` du SessionStart quand c'est UNE seule ligne qui porte le signal de juges ; (None, []) s'il n'y a pas
    d'`additionalContext` ; (ligne, fautes) sinon, `fautes` nommant ce qui n'est pas conforme (plusieurs lignes, autre préfixe)."""
    contexte = contexte_de(out)
    if contexte is None:
        return None, []
    fautes = []
    if "\n" in contexte:
        fautes.append("UNE ligne attendue — obtenu %d lignes : %s" % (contexte.count("\n") + 1, court(contexte)))
    if not contexte.startswith(PREFIXE_SIGNAL):
        fautes.append("préfixe %r attendu — obtenu %s" % (PREFIXE_SIGNAL, court(contexte)))
    return contexte, fautes


# =================================================================================================
# R-JUGE-01 à R-JUGE-03 : le signal de juges au SessionStart d'un lab adhérent
# =================================================================================================
def controle_juge_01(ctx, script):
    """Lab adhérent à deux juges et un producteur : `juge-a` sans dossier, `juge-b` prouvé (sortie piégée visant `critere-x`, verdict posé par la vraie
    commande avec `critere-x::échec`). SessionStart (source startup, commande COMPLÈTE) -> UN objet sans décision, code 0, stderr vide, UNE ligne
    d'`additionalContext` qui compte 1 prouvé et nomme `juge-a` sans preuve (ni `juge-b`, ni le producteur) ; la liste surveillée de D1 reste émise. Cinq
    juges sans dossier : trois noms et le reste compté (une ligne agrégée, pas une ligne par juge)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    fautes = []
    lab = fabriquer_lab(ctx, "juge-01", agents={"juge-a": def_juge("juge-a"), "juge-b": def_juge("juge-b"), "producteur-p": def_producteur("producteur-p")})
    echec = juge_prouve(ctx, lab, "juge-b")
    if echec:
        return False, "fixture : " + echec
    rc, out, err = session(ctx, d, lab, np=False)
    if rc != 0 or err or verdict_de(rc, out) != "sortie":
        fautes.append("SessionStart : UN objet sans décision, code 0, stderr vide attendus — obtenu rc=%d %s %s" % (rc, court(out), court(err)))
    ligne, anomalies = ligne_de_juges(out)
    fautes += anomalies
    if ligne is None:
        fautes.append("additionalContext avec la ligne de juges attendu — obtenu %s" % court(out))
    else:
        for attendu in ("1 prouvé(s)", "0 laxiste(s)", "1 sans preuve : juge-a"):
            if attendu not in ligne:
                fautes.append("%r attendu dans la ligne — obtenu %s" % (attendu, court(ligne)))
        for absent in ("juge-b", "producteur-p"):
            if absent in ligne:
                fautes.append("%r ne doit pas figurer dans la ligne (prouvé ou hors rôle) — obtenu %s" % (absent, court(ligne)))
    if not chemins_de(out):
        fautes.append("la liste surveillée de D1 (watchPaths) reste émise — obtenu %s" % court(out))
    # Cinq juges sans dossier : une ligne agrégée, trois noms, le reste compté
    agents = {"juge-%s" % c: def_juge("juge-%s" % c) for c in "abcde"}
    lab5 = fabriquer_lab(ctx, "juge-01-cinq", agents=agents)
    rc, out, err = session(ctx, d, lab5)
    ligne5, anomalies5 = ligne_de_juges(out)
    fautes += anomalies5
    if rc != 0 or err or ligne5 is None or "0 prouvé(s)" not in ligne5 or "5 sans preuve : juge-a, juge-b, juge-c et 2 autre(s)" not in ligne5 or "juge-d" in ligne5:
        fautes.append("cinq juges sans dossier : « 5 sans preuve : juge-a, juge-b, juge-c et 2 autre(s) » en UNE ligne attendu — obtenu rc=%d %s" % (rc, court(ligne5 or out)))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "lab adhérent à deux juges : UNE ligne (1 prouvé, juge-a sans preuve nommé, juge-b et le producteur absents), aucun refus, watchPaths de D1 conservés ; "
                          "cinq juges sans dossier : trois noms et « 2 autre(s) » en UNE ligne")


def controle_juge_02(ctx, script):
    """Aucun juge -> aucune ligne : agents d'autres rôles seulement, pas de `.claude/agents/`, un juge du COMPTE seulement (jamais un juge du lab). Lab
    dev avec deux juges et sans dossier : stdout d'octet vide, code 0, arbre identique, commande complète ET cœur seul (c'est le cœur qui garde
    l'adhésion). Jumeau : les mêmes agents dans un lab adhérent produisent la ligne."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    fautes = []
    autres = {"producteur-p": def_producteur("producteur-p"), "manager-m": def_manager("manager-m")}
    ecrire(os.path.join(ctx.home, ".claude", "agents", "juge-compte.md"), def_juge("juge-compte"))
    labs = (("agents d'autres rôles", fabriquer_lab(ctx, "juge-02-autres", agents=autres)),
            ("pas de .claude/agents", fabriquer_lab(ctx, "juge-02-sans-agents")),
            ("juge du compte seulement", fabriquer_lab(ctx, "juge-02-compte", agents=autres)))
    for nom, lab in labs:
        rc, out, err = session(ctx, d, lab, np=False)
        ligne, _anomalies = ligne_de_juges(out)
        if rc != 0 or err or (ligne is not None and "juges (C-16)" in ligne):
            fautes.append("%s : aucune ligne de juges attendue — obtenu rc=%d %s" % (nom, rc, court(ligne or out)))
        if not chemins_de(out):
            fautes.append("%s : la liste surveillée de D1 reste émise — obtenu %s" % (nom, court(out)))
    # Lab dev : silence, arbre identique
    agents = {"juge-a": def_juge("juge-a"), "juge-b": def_juge("juge-b")}
    dev = fabriquer_lab(ctx, "juge-02-dev", agents=agents, adherent=False)
    for np in (False, True):
        avant = empreinte_arbre(dev)
        rc, out, err = session(ctx, d, dev, np=np)
        if rc != 0 or out != b"" or err or empreinte_arbre(dev) != avant:
            fautes.append("lab dev avec juges (%s) : stdout d'octet vide, code 0, arbre identique attendus — obtenu rc=%d out=%s err=%s" % (
                "cœur seul" if np else "commande complète", rc, court(out), court(err)))
    # Jumeau : les mêmes agents, lab adhérent
    adh = fabriquer_lab(ctx, "juge-02-adherent", agents=agents)
    rc, out, err = session(ctx, d, adh, np=False)
    ligne, _anomalies = ligne_de_juges(out)
    if rc != 0 or ligne is None or "2 sans preuve : juge-a, juge-b" not in ligne:
        fautes.append("jumeau adhérent : « 2 sans preuve : juge-a, juge-b » attendu — obtenu rc=%d %s" % (rc, court(ligne or out)))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "agents d'autres rôles, absence de .claude/agents et juge du compte seul : aucune ligne (watchPaths conservés) ; lab dev à deux juges : stdout 0 octet, "
                          "arbre identique (commande complète et cœur seul) ; jumeau adhérent : la ligne nomme les deux juges")


def controle_juge_03(ctx, script):
    """SessionStart de source `resume`, `compact`, `clear` ou sans source : aucune ligne de juge, la liste surveillée de D1 reste émise. Jumeau : la
    source `startup` porte la ligne (un juge sans dossier)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    fautes = []
    lab = fabriquer_lab(ctx, "juge-03", agents={"juge-a": def_juge("juge-a")})
    for source in ("resume", "compact", "clear", None):
        rc, out, err = session(ctx, d, lab, source=source, np=False)
        contexte = contexte_de(out)
        if rc != 0 or err or (contexte is not None and "juges (C-16)" in contexte):
            fautes.append("source %s : aucune ligne de juge attendue — obtenu rc=%d %s" % (source, rc, court(contexte or out)))
        if not chemins_de(out):
            fautes.append("source %s : la liste surveillée de D1 (watchPaths) reste émise — obtenu %s" % (source, court(out)))
    rc, out, err = session(ctx, d, lab, source="startup", np=False)
    ligne, _anomalies = ligne_de_juges(out)
    if rc != 0 or ligne is None or "1 sans preuve : juge-a" not in ligne:
        fautes.append("jumeau startup : « 1 sans preuve : juge-a » attendu — obtenu rc=%d %s" % (rc, court(ligne or out)))
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "source resume, compact, clear et absente : aucune ligne de juge, watchPaths conservés ; jumeau startup : la ligne nomme juge-a")


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
    rendre("R-JUGE-01", "SessionStart d'un lab adhérent : UNE ligne agrégée de juges", controle_juge_01, ctx)
    rendre("R-JUGE-02", "aucun juge, juge du compte, lab dev : aucune ligne", controle_juge_02, ctx)
    rendre("R-JUGE-03", "la ligne de juges ne sort qu'à la source startup", controle_juge_03, ctx)


def sec_mutants_base(ctx):
    tuer(ctx, "JUGE-SANS-PREUVE-VERT", "# juge-sans-preuve", 'return "prouve", "dossier-absent"  # juge-sans-preuve', "R-JUGE-01", controle_juge_01)
    # Adhésion ignorée : la sortie silencieuse d'un lab non adhérent retirée (la commande rejouée n'a pas son pré-filtre, `np`)
    tuer(ctx, "JUGE-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-JUGE-02", controle_juge_02)
    tuer(ctx, "JUGE-SOURCE", "# juge-source", "if True:  # juge-source", "R-JUGE-03", controle_juge_03)


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
PY_AIDES_JUGES_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-juges.txt"
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
  run_sections "${VF_JUGES_SECTIONS:-base,mutants_base}"
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
