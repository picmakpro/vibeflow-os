#!/usr/bin/env bash
# test-planning-hook-registered.sh — rejeu de la COMMANDE ENREGISTRÉE du hook central (Phase 45,
# 45-01 ; GATE-01, GATE-02, GATE-03, GATE-10, GATE-15). La commande est lue dans hooks.json par
# json.load et rejouée TELLE QUELLE sous /bin/sh -c, stdin = le payload du harnais : c'est ce que
# le harnais exécute, pas un appel direct au script (P45-D-20).
#
# Familles (Tâche 1 : R-CMD-01 à R-CMD-08) :
#   R-CMD-01  l'entrée : UNE seule entrée PreToolUse, forme shell, matcher combiné, timeout 20,
#             seul basename cité = planning-hook.sh, événements préexistants inchangés
#   R-CMD-02  merge-hooks.sh : pose dans settings.json (jamais settings.local.json), idempotent,
#             remove sans résidu ; la commande POSÉE est rejouée
#   R-CMD-03  lab dev, script présent : stdout d'octet vide et code 0 pour les six outils (GATE-10)
#   R-CMD-04  lab adhérent, script présent, cible neutre : silence
#   R-CMD-05  lab adhérent, script absent : deny statique (Write, Edit, NotebookEdit, Agent, Task),
#             Bash ouvert (limite déclarée, P45-D-06b)
#   R-CMD-06  python absent : mêmes verdicts
#   R-CMD-07  faute injectée en phase A du script : repris par la couche shell
#   R-CMD-08  faute injectée en phase B : deny émis par le Python, code 0, jamais code 2 (P45-D-08)
#
# Phase 46, plan 46-04 (P46-D-09, P46-D-10, P46-D-16) : la MÊME commande est câblée sous cinq événements (PreToolUse élargi à
# SubagentHandback, SubagentStop, SessionStart, CwdChanged, FileChanged). R-CMD-01 et R-CMD-02 portent sur les cinq entrées ;
# R-EVT-01 à R-EVT-07 prouvent le contrat de chaque événement (VF_REG_SECTIONS=evenements pour les rejouer seuls) :
#   R-EVT-01  hors adhésion (lab dev fixture ET ce dépôt), chaque événement et le nouvel outil rendent un octet vide et 0 sous
#             quatre shells, SANS lancer le script ni python3 (marqueurs) ; R-EVT-01b : la copie sonde du cœur, rejouée sans
#             pré-filtre, n'écrit AUCUNE ligne au journal hors adhésion et une ligne dans un lab adhérent (témoin)
#   R-EVT-02  lab adhérent, script présent : silence, code 0, pour les cinq événements
#   R-EVT-03  lab adhérent, script absent puis python absent : SubagentHandback refusé (un deny), les quatre autres événements
#             muets ; aucun chemin absolu ni « no such file » / « can't open » dans un message
#   R-EVT-04  faute injectée dans un mode non outil : silence, code 0 (fail-open déclaré) ; en PreToolUse : deny
#   R-EVT-05  `hook_event_name` absent = PreToolUse ; inconnu ou non chaîne = silence
#   R-EVT-06  FileChanged : la racine se lit dans `file_path` de premier niveau, jamais dans `cwd`
#   R-EVT-07  contrat de sortie : SubagentStop `decision: block` code 0, jamais le code 2 ; les trois autres ne refusent jamais
#   Mutants : MUT-EVT-REPLI-HANDBACK, MUT-EVT-FAILOPEN, MUT-EVT-ADHESION, MUT-EVT-PREFILTRE, MUT-EVT-FILEPATH, MUT-EVT-EXIT2,
#   MUT-EVT-EXIT2-STATIQUE, MUT-CMD01-* (hooks.json mutés), chacun avec sa trace assertion / attendu / obtenu.
#
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ;
# comparaisons par `cmp -s` (jamais `diff`) ; tout le travail fin est fait par Python (PYBIN).
# Lançable depuis tout cwd. Posée sous `.claude/scripts/tests/` d'un lab, la suite lit la commande
# dans le `settings.json` du lab (hooks.json n'y existe pas) ; les cas qui exigent le dépôt
# (merge-hooks.sh) impriment alors `NOTE … hors dépôt`, jamais un vert.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
HOOK="$SCRIPTS_DIR/planning-hook.sh"
HOOKS_JSON="$SCRIPTS_DIR/../hooks/hooks.json"
SETTINGS_LAB="$SCRIPTS_DIR/../settings.json"
[ -f "$HOOKS_JSON" ] || HOOKS_JSON=""
[ -f "$SETTINGS_LAB" ] || SETTINGS_LAB=""
REPO_ROOT=""
if [ -f "$SCRIPTS_DIR/../../_internal/merge-hooks.sh" ]; then
  REPO_ROOT="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
fi

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-planning-hook-registered] python3 requis" >&2; exit 1; fi
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

# ================================================================================================
# Aides Python : fabrique de payloads et de labs, rejeu de la commande enregistrée, mutants.
# Un seul fichier, invoqué par sous-processus, section par section ; les lignes de résultat sont
# déjà au format `  ✓ …` / `  ✗ …` (assertion / attendu / obtenu) et comptées par le shell.
# ================================================================================================
AIDES="$WORK/aides.py"
cat > "$AIDES" <<'PY_AIDES_REG_EOF'
import concurrent.futures
import copy
import json
import os
import posixpath
import random
import re
import shutil
import subprocess
import sys
import time

TOKEN = "{{VF_SCRIPTS}}"
OUTILS_FILTRES = ("Write", "Edit", "NotebookEdit", "Agent", "Task")
SIX_OUTILS = ("Write", "Edit", "NotebookEdit", "Bash", "Agent", "Task")
BASE_EVENEMENTS = {
    "SessionStart": [
        {"matcher": "startup", "hooks": [
            {"type": "command", "command": "bash {{VF_SCRIPTS}}/check-planning-state.sh --defer-to-gsd || true"},
            {"type": "command", "command": "bash {{VF_SCRIPTS}}/planning-context.sh --defer-to-gsd || true"},
            {"type": "command", "command": "bash {{VF_SCRIPTS}}/detect-planning-debt.sh || true"}]},
        {"hooks": [
            {"type": "command", "command": "bash {{VF_SCRIPTS}}/planning-session-snapshot.sh || true"}]},
    ],
    "UserPromptSubmit": [
        {"hooks": [{"type": "command", "command": "bash {{VF_SCRIPTS}}/planning-task-context.sh || true"}]},
    ],
    "Stop": [
        {"hooks": [{"type": "command", "command": "bash {{VF_SCRIPTS}}/guard-planning-updated.sh"}]},
    ],
}
DENY_B = ('{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",'
          '"permissionDecisionReason":"[test] substitut du mode B"}}')


def ok(libelle):
    print("  ✓ " + libelle)


def ko(libelle, assertion, attendu, obtenu):
    print("  ✗ " + libelle)
    print("    assertion : " + str(assertion))
    print("    attendu   : " + str(attendu))
    print("    obtenu    : " + str(obtenu))


def court(octets, n=160):
    texte = octets.decode("utf-8", "replace") if isinstance(octets, bytes) else str(octets)
    texte = texte.replace("\n", "\\n")
    return texte if len(texte) <= n else texte[:n] + "…(+" + str(len(texte) - n) + ")"


# --- Payload du harnais (Claude Code 2.1.284, mesuré) : JSON compact, clés dans cet ordre -------
def payload(outil, entree, cwd, agent_type=None, agent_id="agent-test", compact=True):
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd,
           "prompt_id": "prompt-test", "permission_mode": "default"}
    if agent_type is not None:
        obj["agent_id"] = agent_id
        obj["agent_type"] = agent_type
    obj["hook_event_name"] = "PreToolUse"
    obj["tool_name"] = outil
    obj["tool_input"] = entree
    obj["tool_use_id"] = "toolu_test"
    if compact:
        return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return json.dumps(obj, ensure_ascii=False).encode("utf-8")


def entree_outil(outil, chemin):
    if outil in ("Agent", "Task"):
        return {"description": "d", "prompt": "p", "subagent_type": "general-purpose"}
    if outil == "Bash":
        return {"command": "true"}
    if outil == "NotebookEdit":
        return {"notebook_path": chemin, "new_source": "x"}
    if outil == "Edit":
        return {"file_path": chemin, "old_string": "a", "new_string": "b"}
    return {"file_path": chemin, "content": "x"}


# --- Labs -----------------------------------------------------------------------------------
PLAN_OUVERT = "---\necrit: livrable.md\n---\n"


def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)


def fabriquer_lab(racine, adherent, config=None, plan=True):
    """Lab jetable : `.planning/config.json` (adhérent cycles-v1 ou dev 2.0) et un plan ouvert qui
    déclare `ecrit: livrable.md`."""
    if config is None:
        config = '{"planning_version": "cycles-v1"}' if adherent else '{"planning_version": "2.0"}'
    if config is not False:
        ecrire(os.path.join(racine, ".planning", "config.json"), config)
    else:
        os.makedirs(os.path.join(racine, ".planning"), exist_ok=True)
    if plan:
        ecrire(os.path.join(racine, ".planning", "cycles", "01-c", "phases", "01-p", "PLAN.md"), PLAN_OUVERT)
    return racine


# --- Contexte : la commande enregistrée et ses six modes de défaillance ----------------------
class Ctx:
    def __init__(self, scripts_dir, hooks_json, repo_root, work, settings_lab):
        # Q-ARM (Willy, AskUserQuestion session principale, 2026-09-30) : les verdicts de cette suite (extraction, adhésion, mode dégradé,
        # matrice A et E) sont ceux de l'enveloppe du hook, pas ceux d'un gate : le script rejoué est une COPIE du livré dont les huit
        # constantes ARMEMENT_* valent `observe`, quel que soit l'état d'armement courant (un gate armé refuse à juste titre un VERDICT.md
        # ou un PLAN.md que la matrice attend silencieux). Les gates armés sont mesurés par test-planning-gates.sh.
        self.scripts_dir_livre = scripts_dir
        self.scripts_dir = self._dossier_observe(scripts_dir, work)
        self.hooks_json = hooks_json
        self.repo_root = repo_root
        self.work = work
        self.settings_lab = settings_lab
        self.hook = os.path.join(scripts_dir, "planning-hook.sh")
        self.cmd = None
        self.cmd_np = None   # la même commande SANS l'appel du pré-filtre (revue Samuel, PR #124) : base des mutants de la couche shell
        self.cmd_pre = None  # la commande tronquée à l'appel du pré-filtre : rend SHORT ou DEFER, ne lance rien d'autre
        self.source_cmd = None
        self.home = os.path.join(work, "home")
        os.makedirs(self.home, exist_ok=True)
        self._n = 0
        self._preparer_modes()

    def unique(self, prefixe):
        self._n += 1
        return os.path.join(self.work, prefixe + "-" + str(self._n))

    @staticmethod
    def _dossier_observe(source, work):
        """Dossier jetable portant planning-hook.sh du `source`, les huit constantes ARMEMENT_* réécrites à `observe` (observe|armed → observe)."""
        texte, n = re.subn(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE|G3|G4|G4P) = )"(?:observe|armed)"', r'\1"observe"',
                           open(os.path.join(source, "planning-hook.sh"), encoding="utf-8").read(), flags=re.M)
        if n != 8:
            raise RuntimeError("huit constantes ARMEMENT_* attendues, %d trouvée(s)" % n)
        d = os.path.join(work, "scripts-observe")
        os.makedirs(d, exist_ok=True)
        ecrire(os.path.join(d, "planning-hook.sh"), texte)
        os.chmod(os.path.join(d, "planning-hook.sh"), 0o755)
        return d

    # -- la commande, lue là où le harnais la lit
    def charger_commande(self):
        candidats = []
        if self.hooks_json:
            d = json.load(open(self.hooks_json, encoding="utf-8"))
            for g in d.get("hooks", {}).get("PreToolUse", []):
                for h in g.get("hooks", []):
                    if "planning-hook.sh" in h.get("command", ""):
                        candidats.append(h["command"])
            self.source_cmd = self.hooks_json
        elif self.settings_lab:
            d = json.load(open(self.settings_lab, encoding="utf-8"))
            for g in d.get("hooks", {}).get("PreToolUse", []):
                for h in g.get("hooks", []):
                    if "planning-hook.sh" in h.get("command", ""):
                        candidats.append(h["command"])
            self.source_cmd = self.settings_lab
        if len(candidats) != 1:
            return None
        self.cmd = candidats[0]
        # Pré-filtre hors adhésion (revue Samuel, PR #124 ; arbitrage Willy, AskUserQuestion session principale, 2026-10-02) : UN appel, une ligne.
        if self.cmd.count(APPEL_PREFILTRE) != 1:
            return None
        debut = self.cmd.find(DEBUT_PREFILTRE)
        if debut < 0 or debut > self.cmd.index(APPEL_PREFILTRE):
            return None
        # le bloc entier (définitions et appel) : ce qui reste est la couche shell d'avant le pré-filtre, octet pour octet
        self.cmd_np = self.cmd[:debut] + self.cmd[self.cmd.index(APPEL_PREFILTRE) + len(APPEL_PREFILTRE):]
        self.cmd_pre = self.cmd.replace(APPEL_PREFILTRE, "if vf_pre; then printf SHORT; else printf DEFER; fi\nexit 0\n")
        return self.cmd

    # -- modes A à F
    def _preparer_modes(self):
        w = self.work
        for mode, corps in (
            ("B", "cat >/dev/null\nprintf '%s\\n' '" + DENY_B + "'\nexit 0\n"),
            ("E", "cat >/dev/null\necho 'substitut E : plantage' >&2\nexit 1\n"),
            ("F", "cat >/dev/null\necho 'substitut F : plantage' >&2\nprintf '{\"hookSpecificOutput\":{'\nexit 2\n"),
        ):
            d = os.path.join(w, "mode" + mode)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
                fh.write("#!/usr/bin/env bash\n" + corps)
        os.makedirs(os.path.join(w, "modeC"), exist_ok=True)
        pathd = os.path.join(w, "pathD")
        os.makedirs(pathd, exist_ok=True)
        for nom in ("sh", "bash", "cat", "grep", "head", "mktemp", "rm", "env"):
            cible = shutil.which(nom)
            if cible and not os.path.lexists(os.path.join(pathd, nom)):
                os.symlink(cible, os.path.join(pathd, nom))

    def dossier_mode(self, mode):
        if mode in ("A", "D"):
            return self.scripts_dir
        return os.path.join(self.work, "mode" + mode)

    def env_mode(self, mode, extra=None):
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.home}
        if os.environ.get("TMPDIR"):
            env["TMPDIR"] = os.environ["TMPDIR"]
        if mode == "D":
            env["PATH"] = os.path.join(self.work, "pathD")
        if extra:
            env.update(extra)
        return env

    def preparer(self, dossier_scripts, cmd=None):
        """(texte de la commande, variables d'environnement additionnelles) pour un dossier de
        scripts donné. Forme du dépôt : le jeton est substitué. Forme posée dans un lab :
        `"$CLAUDE_PROJECT_DIR"/.claude/scripts`, résolu par un projet jetable."""
        cmd = cmd if cmd is not None else self.cmd
        if TOKEN in cmd:
            return cmd.replace(TOKEN, "'" + dossier_scripts + "'"), {}
        proj = self.unique("proj")
        os.makedirs(os.path.join(proj, ".claude"), exist_ok=True)
        os.symlink(dossier_scripts, os.path.join(proj, ".claude", "scripts"))
        return cmd, {"CLAUDE_PROJECT_DIR": proj}

    def rejouer(self, texte, entree, env, cwd=None, shell="/bin/sh"):
        t0 = time.perf_counter()
        p = subprocess.run([shell, "-c", texte], input=entree, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, env=env, cwd=cwd, timeout=120)
        return p.returncode, p.stdout, p.stderr, time.perf_counter() - t0

    def lancer(self, mode, entree, cwd=None, shell="/bin/sh", dossier=None, extra_env=None, np=False):
        texte, extra = self.preparer(dossier if dossier else self.dossier_mode(mode), self.cmd_np if np else None)
        if extra_env:
            extra = dict(extra)
            extra.update(extra_env)
        return self.rejouer(texte, entree, self.env_mode(mode, extra), cwd, shell)


APPEL_PREFILTRE = "vf_pre && exit 0\n"
DEBUT_PREFILTRE = "_pn='\n'\nvf_pp()"


def verdict(rc, out):
    """`silence` (rien, code 0), `deny` (UN objet JSON deny, code 0), `block` (SubagentStop), `watchPaths`, sinon `autre`."""
    if rc != 0:
        return "autre:rc=" + str(rc)
    if out == b"":
        return "silence"
    try:
        obj = json.loads(out.decode("utf-8"))
        if isinstance(obj, dict) and obj.get("decision") == "block" and isinstance(obj.get("reason"), str) and "hookSpecificOutput" not in obj:
            return "block"   # SubagentStop : décision JSON, code 0 (P46-D-10)
        if isinstance(obj, dict) and isinstance(obj.get("watchPaths"), list):
            return "watchPaths"
        s = obj["hookSpecificOutput"]
        if isinstance(s.get("watchPaths"), list):
            return "watchPaths"
        if s["hookEventName"] == "PreToolUse" and s["permissionDecision"] == "deny" and isinstance(s["permissionDecisionReason"], str):
            return "deny"
    except (ValueError, KeyError, TypeError, AttributeError):
        pass
    return "autre:document"


# --- Mutants du script (make_hook_mutant) ----------------------------------------------------
def make_hook_mutant(ctx, ident, motif, remplacement, source=None):
    """Copie du script dont l'UNIQUE ligne portant `motif` (fixe) est remplacée par `remplacement`
    (indentation conservée). Rend (dossier, None) ou (None, raison) : texte distinct de l'original,
    `bash -n` et compilation du corps Python extrait doivent passer, sinon le mutant ne prouve rien.
    `source` : chemin d'un script déjà muté à muter encore (chaîne de mutations de la 46) ; à défaut, le script livré."""
    original = open(source or ctx.hook, encoding="utf-8").read()
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
    dossier = ctx.unique("mut-" + ident.lower())
    os.makedirs(dossier, exist_ok=True)
    chemin = os.path.join(dossier, "planning-hook.sh")
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(muté)
    os.chmod(chemin, 0o755)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    corps, dedans = [], False
    for l in muté.split("\n"):
        if l == "PY_PLANNING_HOOK_EOF":
            dedans = False
        if dedans:
            corps.append(l)
        if l.endswith("<<'PY_PLANNING_HOOK_EOF'"):
            dedans = True
    try:
        compile("\n".join(corps) + "\n", chemin, "exec")
    except SyntaxError as e:
        return None, "SyntaxError du corps Python : " + str(e)
    return dossier, None


# =================================================================================================
# Sections
# =================================================================================================
# =================================================================================================
# Phase 46, plan 46-04 (P46-D-09, P46-D-10, P46-D-16) : la MÊME commande sous cinq événements.
# R-CMD-01 (forme des cinq entrées), puis R-EVT-01 à R-EVT-07 (contrat de chaque événement, silence hors adhésion, repli, fail-open).
# =================================================================================================
EVENEMENTS_CABLES = ("PreToolUse", "SubagentStop", "CwdChanged", "FileChanged", "SessionStart")
MATCHER_PRETOOLUSE = "Write|Edit|NotebookEdit|Bash|Agent|Task|SubagentHandback"
EVT_NON_OUTIL = ("SubagentStop", "SessionStart", "CwdChanged", "FileChanged")
CINQ_ENTREES = ("SubagentHandback",) + EVT_NON_OUTIL   # le nouvel outil du matcher, puis les quatre événements nouveaux
MODES_NON_OUTIL = (("SubagentStop", "evt-mode-subagentstop"), ("SessionStart", "evt-mode-sessionstart"),
                   ("CwdChanged", "evt-mode-cwdchanged"), ("FileChanged", "evt-mode-filechanged"))
FRAGMENTS_INTERDITS = ("no such file", "can't open")
PLAFOND_EVT_S = 10.0   # marge large sur le temps mesuré : la preuve est le verdict, le plafond n'écarte qu'un traitement non borné
# Chemin absolu de plus d'un composant (`/a/b`) : `/vf-update` seul n'en est pas un.
RE_CHEMIN_ABSOLU = re.compile(r"(?<![A-Za-z0-9_.\-])/(?:[A-Za-z0-9_.~\-]+/)+[A-Za-z0-9_.~\-]*")


def chemin_absolu_dans(texte):
    m = RE_CHEMIN_ABSOLU.search(texte)
    return m.group(0) if m else None


def fautes_entree(d):
    """R-CMD-01 sur le document hooks.json `d` : liste de (assertion, attendu, obtenu). Une seule entrée citant planning-hook.sh par
    événement, sous exactement les cinq événements ; matcher PreToolUse exact (UN seul groupe, jamais un second que la purge de
    merge-hooks écraserait) ; SubagentStop, CwdChanged, FileChanged sans `matcher` ; SessionStart dans un groupe sans matcher ; même texte
    de commande partout ; timeout 20 ; forme shell ; événements préexistants inchangés."""
    evts = d.get("hooks", {})
    fautes = []
    citent = {}
    for evt, groupes in evts.items():
        for g in groupes:
            for h in g.get("hooks", []):
                if "planning-hook.sh" in h.get("command", ""):
                    citent.setdefault(evt, []).append((g, h))
    if sorted(citent) != sorted(EVENEMENTS_CABLES):
        fautes.append(("planning-hook.sh cité sous exactement les cinq événements, aucun ailleurs", str(sorted(EVENEMENTS_CABLES)), str(sorted(citent))))
    for evt, liste in sorted(citent.items()):
        if len(liste) != 1:
            fautes.append(("une seule entrée portant planning-hook.sh sous " + evt, "1", str(len(liste))))
    pre = evts.get("PreToolUse", [])
    if len(pre) != 1:
        fautes.append(("un seul groupe PreToolUse (un second groupe citant planning-hook.sh serait écrasé par la purge de merge-hooks)", "1 groupe", "%d groupe(s)" % len(pre)))
    commandes = {h.get("command") for liste in citent.values() for _g, h in liste}
    if len(commandes) != 1:
        fautes.append(("le même texte de commande sous les cinq événements", "1 texte", "%d textes" % len(commandes)))
    for evt, liste in sorted(citent.items()):
        for g, h in liste:
            attendu_matcher = MATCHER_PRETOOLUSE if evt == "PreToolUse" else None
            if g.get("matcher") != attendu_matcher:
                fautes.append(("matcher de l'entrée " + evt + (" (exact, sept outils)" if evt == "PreToolUse" else " (omis)"), str(attendu_matcher), str(g.get("matcher"))))
            if h.get("timeout") != 20:
                fautes.append(("clé timeout sous " + evt, "20", str(h.get("timeout"))))
            if h.get("type") != "command" or "args" in h:
                fautes.append(("forme shell (type command, sans args) sous " + evt, "command sans args", str(sorted(h.keys()))))
            cmd = h.get("command", "")
            if "{{VF_BASH}}" in cmd:
                fautes.append(("aucune occurrence de {{VF_BASH}} sous " + evt, "0", "présent"))
            noms = sorted(set(re.findall(r"([A-Za-z0-9._-]+\.(?:sh|py))", cmd)))
            if noms != ["planning-hook.sh"]:
                fautes.append(("seul basename *.sh/*.py cité sous " + evt, "['planning-hook.sh']", str(noms)))
    # entrées préexistantes : chacune retrouvée, dans l'ordre, sans altération (sous-suite)
    for evt, base in BASE_EVENEMENTS.items():
        courant = evts.get(evt, [])
        i = 0
        for groupe in courant:
            if i < len(base) and _groupe_contient(groupe, base[i]):
                i += 1
        if i != len(base):
            fautes.append(("entrées préexistantes de " + evt + " conservées", "structure de base", "altérée ou absente"))
    return fautes


def sec_entree(ctx):
    """R-CMD-01 : la forme des cinq entrées enregistrées ; puis les mutants de hooks.json (MUT-CMD01-*)."""
    if not ctx.hooks_json:
        ok("R-CMD-01 (hors dépôt : commande lue dans le settings.json du lab, forme non rejouable ici)")
        return
    d = json.load(open(ctx.hooks_json, encoding="utf-8"))
    fautes = fautes_entree(d)
    if fautes:
        for a, b, c in fautes:
            ko("R-CMD-01", a, b, c)
        return
    ok("R-CMD-01 une entrée par événement sous les cinq (PreToolUse au matcher élargi à SubagentHandback, SubagentStop, CwdChanged, FileChanged sans matcher, SessionStart dans un groupe sans matcher), même commande, timeout 20, forme shell, seul planning-hook.sh cité, événements préexistants inchangés")

    def muter(ident, fonction, motif):
        copie = copy.deepcopy(d)
        fonction(copie)
        if copie == d:
            komut(ident, "hooks.json muté distinct de l'original", "document distinct", "NON OPPOSABLE (identique) : " + motif)
            return
        f = fautes_entree(copie)
        if f:
            okmut(ident, "R-CMD-01 rougit · attendu (original) : aucune faute · obtenu (mutant, %s) : %d faute(s), première : %s — attendu %s, obtenu %s"
                  % (motif, len(f), f[0][0], f[0][1], f[0][2]))
        else:
            komut(ident, "R-CMD-01 rougit sur hooks.json muté (%s)" % motif, "au moins une faute", "aucune faute (le contrôle passe à vide)")

    def sans_handback(c):
        c["hooks"]["PreToolUse"][0]["matcher"] = "Write|Edit|NotebookEdit|Bash|Agent|Task"

    def second_groupe(c):
        g = copy.deepcopy(c["hooks"]["PreToolUse"][0])
        g["matcher"] = "Bash"
        c["hooks"]["PreToolUse"].append(g)

    def sans_filechanged(c):
        del c["hooks"]["FileChanged"]

    def autre_commande(c):
        c["hooks"]["SubagentStop"][0]["hooks"][0]["command"] += "\n:"

    def session_matcher(c):
        for g in c["hooks"]["SessionStart"]:
            if any("planning-hook.sh" in h.get("command", "") for h in g["hooks"]):
                g["matcher"] = "startup"

    def timeout_long(c):
        c["hooks"]["FileChanged"][0]["hooks"][0]["timeout"] = 30

    def matcher_filechanged(c):
        c["hooks"]["FileChanged"][0]["matcher"] = "*"

    muter("CMD01-MATCHER", sans_handback, "SubagentHandback retiré du matcher PreToolUse")
    muter("CMD01-SECOND-GROUPE", second_groupe, "second groupe PreToolUse citant planning-hook.sh")
    muter("CMD01-FILECHANGED-ABSENT", sans_filechanged, "entrée FileChanged retirée")
    muter("CMD01-COMMANDE-DIFFERENTE", autre_commande, "texte de commande de SubagentStop différent")
    muter("CMD01-SESSIONSTART-MATCHER", session_matcher, "matcher `startup` posé sur le groupe SessionStart qui porte la commande")
    muter("CMD01-TIMEOUT", timeout_long, "timeout de FileChanged à 30")
    muter("CMD01-FILECHANGED-MATCHER", matcher_filechanged, "matcher `*` posé sur FileChanged (un fichier nommé `*`, jamais un joker)")


def _groupe_contient(groupe, base):
    """Le groupe courant est égal à la base, ou la contient (entrées ajoutées après par une phase
    ultérieure, jamais une altération des entrées de base)."""
    if groupe.get("matcher") != base.get("matcher"):
        return False
    hs = groupe.get("hooks", [])
    j = 0
    for h in hs:
        if j < len(base["hooks"]) and h == base["hooks"][j]:
            j += 1
    return j == len(base["hooks"])


def sec_merge(ctx):
    """R-CMD-02 : merge-hooks.sh pose, idempotent, remove sans résidu ; la commande posée rejouée."""
    if not ctx.repo_root or not ctx.hooks_json:
        print("NOTE R-CMD-02 hors dépôt : merge-hooks.sh ou hooks.json absent — cas non rejoué (jamais un vert)")
        return
    merge = os.path.join(ctx.repo_root, "plugin", "_internal", "merge-hooks.sh")
    w = ctx.unique("merge")
    os.makedirs(w, exist_ok=True)
    s = os.path.join(w, "settings.json")
    sl = os.path.join(w, "settings.local.json")
    prefixe = '"$CLAUDE_PROJECT_DIR"/.claude/scripts'

    def mh(mode):
        args = ["bash", merge, mode, ctx.hooks_json, "--settings", s, "--settings-local", sl]
        if mode == "merge":
            args += ["--scripts-prefix", prefixe]
        p = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env_mode("A"))
        return p.returncode, p.stderr

    def entrees_posees(chemin):
        if not os.path.exists(chemin):
            return []
        d = json.load(open(chemin, encoding="utf-8"))
        res = []
        for evt, groupes in d.get("hooks", {}).items():
            for g in groupes:
                for h in g.get("hooks", []):
                    if "planning-hook.sh" in json.dumps(h):
                        res.append((evt, g.get("matcher"), h))
        return res

    rc, err = mh("merge")
    if rc != 0:
        ko("R-CMD-02", "merge-hooks.sh merge rend 0", "0", "rc=%d %s" % (rc, court(err)))
        return
    dans_s, dans_sl = entrees_posees(s), entrees_posees(sl)
    fautes = []
    if sorted(e for e, _m, _h in dans_s) != sorted(EVENEMENTS_CABLES):
        fautes.append(("l'entrée est posée UNE fois par événement dans settings.json (cinq événements)", str(sorted(EVENEMENTS_CABLES)), str(sorted(e for e, _m, _h in dans_s))))
    if dans_sl:
        fautes.append(("rien dans settings.local.json (forme shell)", "0 entrée", str(len(dans_sl))))
    for evt, matcher, h in dans_s:
        attendu_matcher = MATCHER_PRETOOLUSE if evt == "PreToolUse" else None
        if matcher != attendu_matcher or h.get("timeout") != 20:
            fautes.append(("matcher et timeout préservés sous " + evt, "%s, 20" % attendu_matcher, "%s, %s" % (matcher, h.get("timeout"))))
        if TOKEN in h["command"] or prefixe not in h["command"]:
            fautes.append(("jeton {{VF_SCRIPTS}} substitué par le préfixe sous " + evt, prefixe, court(h["command"], 80)))
    if len({h["command"] for _e, _m, h in dans_s}) > 1:
        fautes.append(("même texte de commande posé sous les cinq événements", "1 texte", "%d textes" % len({h["command"] for _e, _m, h in dans_s})))
    octets1 = (open(s, "rb").read(), open(sl, "rb").read() if os.path.exists(sl) else None)
    rc2, err2 = mh("merge")
    octets2 = (open(s, "rb").read(), open(sl, "rb").read() if os.path.exists(sl) else None)
    if rc2 != 0 or octets1 != octets2:
        fautes.append(("second merge idempotent (cmp)", "fichiers identiques, rc 0", "rc=%d, identiques=%s" % (rc2, octets1 == octets2)))
    # la commande POSÉE rejouée : script présent → silence ; script absent → deny
    if dans_s:
        cmd_posee = dans_s[0][2]["command"]
        lab = fabriquer_lab(os.path.join(w, "lab"), True)
        proj_ok = os.path.join(w, "proj-ok")
        os.makedirs(os.path.join(proj_ok, ".claude"), exist_ok=True)
        os.symlink(ctx.scripts_dir, os.path.join(proj_ok, ".claude", "scripts"))
        proj_ko = os.path.join(w, "proj-ko")
        os.makedirs(os.path.join(proj_ko, ".claude", "scripts"), exist_ok=True)
        entree = payload("Write", {"file_path": lab + "/.planning/notes.md", "content": "x"}, lab)
        for proj, attendu in ((proj_ok, "silence"), (proj_ko, "deny")):
            env = ctx.env_mode("A", {"CLAUDE_PROJECT_DIR": proj})
            rc3, out3, err3, _ = ctx.rejouer(cmd_posee, entree, env)
            v = verdict(rc3, out3)
            if v != attendu or err3:
                fautes.append(("commande posée rejouée (%s)" % os.path.basename(proj), attendu, v + " " + court(err3)))
    rc4, err4 = mh("remove")
    if rc4 != 0 or entrees_posees(s) or entrees_posees(sl):
        fautes.append(("remove sans résidu qui cite planning-hook.sh", "0 entrée, rc 0",
                       "rc=%d, %d+%d entrée(s)" % (rc4, len(entrees_posees(s)), len(entrees_posees(sl)))))
    if fautes:
        for a, b, c in fautes:
            ko("R-CMD-02", a, b, c)
    else:
        ok("R-CMD-02 merge pose dans settings.json une entrée par événement sous les cinq (rien dans settings.local.json), idempotent (cmp), commande posée rejouée, remove sans résidu")


def _deny_ok(rc, out, err):
    """Un seul objet JSON deny, code 0, stderr vide, message qui nomme la réparation."""
    if verdict(rc, out) != "deny" or err:
        return False
    raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    return "Reparer" in raison and "planning-core" in raison


def _labs_simples(ctx, nom):
    base = ctx.unique(nom)
    adh = fabriquer_lab(os.path.join(base, "adh"), True)
    dev = fabriquer_lab(os.path.join(base, "dev"), False)
    return adh, dev


def raison_deny(rc, out, err):
    """Raison d'un deny unique (code 0, stderr vide), sinon None."""
    if verdict(rc, out) != "deny" or err:
        return None
    return json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]


def controle_libelle_f4(ctx, texte, adh, dev):
    """Lot C, F4 (re-audit, décision du manager vf-dev-manager, 2026-10-01, renversable) : le refus de la couche shell dit ce qu'il sait.
    Un chemin à échappement JSON non géré hors de tout lab adhérent : « doute d adhesion du lab (chemin non analysable) », jamais « dans
    un lab adherent » ; un chemin sous un lab réellement adhérent (même échappement) : « dans un lab adherent cycles-v1 », jamais
    « doute ». Script absent (mode C) : seule la couche shell parle. Rend (conforme, détail)."""
    fautes = []
    cas = (("hors de tout lab adhérent (échappement \\f)", dev + "/x\x0cy.md", dev, "doute d adhesion du lab", "dans un lab adherent"),
           ("sous un lab adhérent (échappement \\b)", adh + "/a\x08b.md", adh, "dans un lab adherent cycles-v1", "doute d adhesion"))
    for etiquette, chemin, cwd, attendu, interdit in cas:
        brut = payload("Write", {"file_path": chemin, "content": "x"}, cwd)
        rc, out, err, _ = rejouer_texte(ctx, texte, "C", brut, cwd)
        raison = raison_deny(rc, out, err)
        if raison is None:
            fautes.append("%s : pas de deny unique (rc=%d out=%s)" % (etiquette, rc, court(out)))
        elif attendu not in raison or interdit in raison or "hook central indisponible" not in raison or "Reparer" not in raison:
            fautes.append("%s : libellé %r (attendu %r, sans %r, avec « hook central indisponible » et « Reparer »)" % (etiquette, raison[:200], attendu, interdit))
    return (not fautes), ("; ".join(fautes) if fautes else "doute d'adhésion nommé hors lab, « dans un lab adherent cycles-v1 » sous un lab adhérent")


def sec_modes(ctx):
    """R-CMD-03 à R-CMD-08."""
    adh, dev = _labs_simples(ctx, "modes")

    def entree(outil, lab, rel=".planning/notes.md"):
        return payload(outil, entree_outil(outil, lab + "/" + rel), lab)

    # R-CMD-03 : lab dev, script présent, six outils
    fautes = []
    for outil in SIX_OUTILS:
        rc, out, err, _ = ctx.lancer("A", entree(outil, dev), cwd=dev)
        if rc != 0 or out != b"" or err:
            fautes.append((outil, "stdout 0 octet, code 0, stderr vide", "rc=%d out=%s err=%s" % (rc, court(out), court(err))))
    if fautes:
        for outil, a, b in fautes:
            ko("R-CMD-03", "lab dev, script présent : " + outil, a, b)
    else:
        ok("R-CMD-03 lab dev, script présent : stdout d'octet vide et code 0 pour Write, Edit, NotebookEdit, Bash, Agent, Task")

    # R-CMD-04 : lab adhérent, script présent, cible neutre
    rc, out, err, _ = ctx.lancer("A", entree("Write", adh), cwd=adh)
    if rc == 0 and out == b"" and not err:
        ok("R-CMD-04 lab adhérent, script présent, Write d'une cible neutre : code 0, stdout vide")
    else:
        ko("R-CMD-04", "Write de .planning/notes.md en lab adhérent, script présent", "rc 0, stdout vide", "rc=%d out=%s err=%s" % (rc, court(out), court(err)))

    # R-CMD-05 : script absent (mode C)
    fautes = []
    for outil in SIX_OUTILS:
        rc, out, err, _ = ctx.lancer("C", entree(outil, adh), cwd=adh)
        if outil == "Bash":
            if rc != 0 or out != b"" or err:
                fautes.append((outil, "stdout vide (Bash ouvert, P45-D-06b)", "rc=%d out=%s" % (rc, court(out))))
        elif not _deny_ok(rc, out, err):
            fautes.append((outil, "un objet deny, code 0, message de réparation", "rc=%d out=%s err=%s" % (rc, court(out), court(err))))
    rel = payload("Write", {"file_path": "livrable.md", "content": "x"}, adh)
    rc, out, err, _ = ctx.lancer("C", rel, cwd=adh)
    if not _deny_ok(rc, out, err):
        fautes.append(("Write relatif sous cwd adhérent (limite h)", "deny", "rc=%d out=%s" % (rc, court(out))))
    rel_dev = payload("Write", {"file_path": "livrable.md", "content": "x"}, dev)
    rc, out, err, _ = ctx.lancer("C", rel_dev, cwd=dev)
    if rc != 0 or out != b"":
        fautes.append(("Write relatif sous cwd dev", "silence", "rc=%d out=%s" % (rc, court(out))))
    if fautes:
        for outil, a, b in fautes:
            ko("R-CMD-05", "lab adhérent, script absent : " + outil, a, b)
    else:
        ok("R-CMD-05 lab adhérent, script absent : deny statique pour Write, Edit, NotebookEdit, Agent, Task (message de réparation), Bash et lab dev en silence, chemin relatif rattaché au lab")

    # R-CMD-05b (lot C, F4) : le libellé du refus de la couche shell dit exactement ce qu'elle sait
    conforme, detail = controle_libelle_f4(ctx, ctx.cmd, adh, dev)
    if conforme:
        ok("R-CMD-05b " + detail)
    else:
        ko("R-CMD-05b", "libellé exact du refus de la couche shell (doute d'adhésion / lab adhérent)", "libellés distincts", detail)

    # R-CMD-06 : python absent (mode D)
    fautes = []
    for outil, lab, attendu in (("Write", adh, "deny"), ("Agent", adh, "deny"), ("Bash", adh, "silence"),
                                ("Write", dev, "silence"), ("Agent", dev, "silence")):
        rc, out, err, _ = ctx.lancer("D", entree(outil, lab), cwd=lab)
        v = verdict(rc, out)
        if v != attendu or err:
            fautes.append((outil + " " + os.path.basename(lab), attendu, v + " " + court(out) + " " + court(err)))
    if fautes:
        for outil, a, b in fautes:
            ko("R-CMD-06", "python absent : " + outil, a, b)
    else:
        ok("R-CMD-06 python absent : lab adhérent Write et Agent en deny, Bash en silence ; lab dev Write et Agent en silence")

    # R-CMD-07 : faute en phase A du script — repris par la couche shell
    dossier, raison = make_hook_mutant(ctx, "R7", "payload = lire_payload(sys.argv[1])  # phase-a",
                                       'raise RuntimeError("faute injectee en phase A")')
    if dossier is None:
        ko("R-CMD-07", "mutant de la phase A", "mutant valide", raison)
    else:
        fautes = []
        rc, out, err, _ = ctx.lancer("A", entree("Write", adh), cwd=adh, dossier=dossier)
        if not _deny_ok(rc, out, err):
            fautes.append(("lab adhérent Write, phase A en faute", "deny (couche shell), code 0", "rc=%d out=%s" % (rc, court(out))))
        rc, out, err, _ = ctx.lancer("A", entree("Write", dev), cwd=dev, dossier=dossier)
        if rc != 0 or out != b"":
            fautes.append(("lab dev, phase A en faute", "silence", "rc=%d out=%s" % (rc, court(out))))
        if fautes:
            for a, b, c in fautes:
                ko("R-CMD-07", a, b, c)
        else:
            ok("R-CMD-07 phase A en faute : lab adhérent Write refusé par la couche shell, lab dev en silence")

    # R-CMD-08 : faute en phase B — deny émis par le Python, code 0, jamais code 2
    dossier, raison = make_hook_mutant(ctx, "R8", "resultats = evaluer_gates(contexte)  # phase-b",
                                       'raise RuntimeError("faute injectee en phase B")')
    if dossier is None:
        ko("R-CMD-08", "mutant de la phase B", "mutant valide", raison)
    else:
        fautes = []
        codes = []
        rc, out, err, _ = ctx.lancer("A", entree("Write", adh), cwd=adh, dossier=dossier)
        codes.append(rc)
        v = verdict(rc, out)
        raison_txt = ""
        if v == "deny":
            raison_txt = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
        if v != "deny" or "erreur interne" not in raison_txt or "P45-D-08" not in raison_txt:
            fautes.append(("lab adhérent, phase B en faute", "deny avec `erreur interne` et `P45-D-08`", v + " " + court(out)))
        # Direct : le script muté seul (sans la commande) sort code 0 et non 2
        rc2 = subprocess.run(["bash", os.path.join(dossier, "planning-hook.sh")], input=entree("Write", adh),
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE).returncode
        codes.append(rc2)
        rc, out, err, _ = ctx.lancer("A", entree("Write", dev), cwd=dev, dossier=dossier)
        codes.append(rc)
        if rc != 0 or out != b"":
            fautes.append(("lab dev, phase B en faute", "silence", "rc=%d out=%s" % (rc, court(out))))
        if any(c != 0 for c in codes):
            fautes.append(("aucun appel ne sort en code 2 (DIV-2)", "codes 0", str(codes)))
        if fautes:
            for a, b, c in fautes:
                ko("R-CMD-08", a, b, c)
        else:
            ok("R-CMD-08 phase B en faute : deny du Python (erreur interne, P45-D-08), code 0, lab dev en silence, aucun code 2")


# =================================================================================================
# Corpus adverse (Tâche 2) : arbres de labs A01-A15 et payloads E01-E36, chacun avec son attendu
# dégradé déclaré : `tight` (deny en modes C à F pour Write, Edit, NotebookEdit, Agent, Task) ou
# `none` (silence : Bash et toute lecture, limites déclarées (a) à (d), P45-D-06b).
# =================================================================================================
PLANCHER_MIN = 49        # plancher de la recherche : un corpus vidé rougit
PLANCHER_CORPUS = 78     # compte déclaré en dur du corpus livré : un corpus amaigri rougit aussi


class Cas:
    def __init__(self, ident, outil, brut, degrade, cwd_proc, python_ok=True, note=""):
        self.ident = ident
        self.outil = outil
        self.brut = brut
        self.degrade = degrade      # "tight" | "none"
        self.cwd_proc = cwd_proc
        self.python_ok = python_ok  # False : le cœur Python échoue avant l'adhésion (code 3)
        self.note = note


def _lien(cible, chemin):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    os.symlink(cible, chemin)


def construire_arbre(t):
    """Arbre de labs jetable sous `t`. Rend le dict nom → chemin absolu."""
    L = {}

    def lab(nom, adherent, config=None, plan=True):
        L[nom] = fabriquer_lab(os.path.join(t, nom), adherent, config, plan)
        return L[nom]

    lab("adh", True)
    os.makedirs(os.path.join(t, "adh", "sub"), exist_ok=True)
    os.makedirs(os.path.join(t, "adh", ".planning", "sub"), exist_ok=True)
    lab("dev", False)
    lab("adh esp", True)
    lab('qlab"x', True)
    lab('dq"x', False)
    lab("bs\\lab", True)
    lab("m$HOME`bt*'ap%s", True)
    lab("uni-é", True)
    lab("nl\nt\tlab", True)
    lab("pretty", True, config='{\n  "planning_version": "cycles-v1"\n}\n')
    lab("nextline", True, config='{"planning_version":\n "cycles-v1"}\n')
    lab("escaped", True, config='{"planning_version": "cycles\\u002dv1"}\n')
    lab("dev-note", False, config='{"note": "cycles-v1", "planning_version": "2.0"}\n')
    lab("dev-sans-config", False, config=False)
    lab('lab sp"q\\b', True)
    lab("devout", False)
    lab(os.path.join("devout", "inner"), True)
    lab("adhout", True)
    lab(os.path.join("adhout", "inner-dev"), False)
    # Lot A (B1/H1, amendement de P45-D-01a, décision du manager vf-dev-manager, 2026-10-01) : un `.planning` situé dans
    # (ou sous) un composant `.planning` n'est jamais une racine de lab. a = `.planning/.planning`, b = `.planning/cycles/.planning`,
    # c = `<phase>/.planning`.
    for nom, rel in (("imb-a", ".planning/.planning"), ("imb-b", ".planning/cycles/.planning"),
                     ("imb-c", ".planning/cycles/01-c/phases/01-p/.planning")):
        lab(nom, True)
        os.makedirs(os.path.join(t, nom, rel))
    # Lot E (F1, amendement de P45-D-01a, décision du manager vf-dev-manager, 2026-10-01) : un `.planning` situé sous un composant
    # `.claude` n'est jamais une racine de lab (sauf `.claude/worktrees/<nom>`, où Claude Code pose les worktrees d'un lab).
    for nom, rel in (("claude-a", ".claude/.planning"), ("claude-b", ".claude/scripts/.planning")):
        lab(nom, True)
        os.makedirs(os.path.join(t, nom, rel))
    lab(".claude/worktrees/wt", True)
    os.makedirs(os.path.join(t, ".claude", "worktrees", "wt", ".claude", "scripts", ".planning"))
    # Lot F (M4, re-revue du lot E) : la casse de `.claude` et de `worktrees` dans la commande enregistrée (motifs `[Cc][Ll]…`,
    # `[Ww][Oo]…`). Trois mesures qui fixent la forme : (1) la casse doit être PHYSIQUE (sur le disque, pas seulement dans le chemin
    # écrit) : avec `.claude` sur le disque et `.CLAUDE` dans le chemin, le mutant n'est pas opposable sous zsh (son `pwd -P` rend la
    # casse du disque) ni sous Linux (dossier inexistant en casse sensible) ; (2) l'exclusion `.claude` de G2 compare la casse
    # (`composants[0] in (".planning", ".claude")`) : en mode A le cœur avertirait sur `.CLAUDE/scripts/…`, ce qui casserait l'attendu
    # « silence » : le plan ouvert du lab `claude-casse` déclare donc `ecrit: .CLAUDE/scripts` (G2 n'avertit jamais qu'un
    # avertissement, jamais un refus) ; (3) sous `cw`, sous-arbre neuf : réutiliser le `.claude/worktrees` ci-dessus ramènerait la casse
    # du disque sur un disque insensible à la casse.
    lab("claude-casse", True)
    ecrire(os.path.join(t, "claude-casse", ".planning", "cycles", "01-c", "phases", "01-p", "PLAN.md"), "---\necrit: .CLAUDE/scripts\n---\n")
    os.makedirs(os.path.join(t, "claude-casse", ".CLAUDE", "scripts", ".planning"))
    lab(os.path.join("cw", ".claude", "WORKTREES", "wt"), True)
    os.makedirs(os.path.join(t, "bare"), exist_ok=True)
    _lien("adh", os.path.join(t, "alias-adh"))
    os.makedirs(os.path.join(t, "lab-plink"), exist_ok=True)
    _lien(os.path.join("..", "adh", ".planning"), os.path.join(t, "lab-plink", ".planning"))
    _lien(os.path.join("..", "dev"), os.path.join(t, "adh", "link-dev"))
    _lien(os.path.join("..", "bare"), os.path.join(t, "adh", "link-bare"))
    _lien(os.path.join("..", "adh"), os.path.join(t, "dev", "link-adh"))
    _lien(os.path.join("..", "adh", ".planning", "sub"), os.path.join(t, "dev", "link-sub"))
    os.makedirs(os.path.join(t, "cfglink", ".planning"), exist_ok=True)
    _lien(os.path.join("..", "..", "adh", ".planning", "config.json"),
          os.path.join(t, "cfglink", ".planning", "config.json"))
    for nom in ("adh esp", 'qlab"x', "bs\\lab", "m$HOME`bt*'ap%s", "uni-é", "nl\nt\tlab", 'lab sp"q\\b',
                "pretty", "adhout", "devout"):
        L.setdefault(nom, os.path.join(t, nom))
    L["devout/inner"] = os.path.join(t, "devout", "inner")
    L["adhout/inner-dev"] = os.path.join(t, "adhout", "inner-dev")
    for nom in ("imb-a", "imb-b", "imb-c", "claude-a", "claude-b"):
        L.setdefault(nom, os.path.join(t, nom))
    L["wt"] = os.path.join(t, ".claude", "worktrees", "wt")
    L["wt-casse"] = os.path.join(t, "cw", ".claude", "WORKTREES", "wt")
    for nom in ("alias-adh", "lab-plink", "bare", "cfglink", "nextline", "escaped", "dev-note", "dev-sans-config"):
        L.setdefault(nom, os.path.join(t, nom))
    return L


def construire_corpus(ctx):
    if getattr(ctx, "corpus", None) is not None:
        return ctx.corpus
    t = ctx.unique("tree")
    os.makedirs(t, exist_ok=True)
    L = construire_arbre(t)
    adh, dev = L["adh"], L["dev"]
    cas = []

    def w(ident, outil, chemin, cwd, degrade, cwd_proc=None, python_ok=True, note="", compact=True, ascii_=False):
        brut = payload(outil, entree_outil(outil, chemin), cwd, compact=compact)
        if ascii_:
            obj = json.loads(brut.decode("utf-8"))
            brut = json.dumps(obj, separators=(",", ":"), ensure_ascii=True).encode("ascii")
        cas.append(Cas(ident, outil, brut, degrade, cwd_proc or t, python_ok, note))

    def brut_cas(ident, outil, brut, degrade, cwd_proc=None, python_ok=True, note=""):
        cas.append(Cas(ident, outil, brut, degrade, cwd_proc or t, python_ok, note))

    notes = ".planning/notes.md"
    # ---- E01-E24 : extraction ----
    w("E01", "Write", adh + "/" + notes, adh, "tight", note="chemin simple")
    w("E02", "Write", L["adh esp"] + "/" + notes, dev, "tight", note="espace dans le lab")
    w("E03", "Write", L['qlab"x'] + "/" + notes, dev, "tight", note="guillemet échappé dans le lab")
    w("E04", "Write", L["bs\\lab"] + "/" + notes, dev, "tight", note="backslash dans le lab")
    w("E05", "Write", adh + "/.planning/f\\", dev, "tight", note="chemin qui finit par un backslash")
    w("E06", "Write", adh + '/.planning/f"', dev, "tight", note="chemin qui finit par un guillemet")
    w("E07", "Write", L["m$HOME`bt*'ap%s"] + "/" + notes, dev, "tight", note="$HOME, backtick, glob, apostrophe, %s")
    w("E08", "Write", L["uni-é"] + "/.planning/résumé.md", dev, "tight", note="Unicode brut")
    w("E09", "Write", adh + "/.planning/résumé.md", dev, "tight", ascii_=True, note="Unicode échappé (préfixe dans le même lab)")
    w("E09b", "Write", L["uni-é"] + "/" + notes, dev, "tight", ascii_=True, note="Unicode échappé dans le lab lui-même (limite d fermée par le lot A : le doute d'adhésion ferme en panne)")
    w("E10", "Write", L["nl\nt\tlab"] + "/" + notes, dev, "tight", note="\\n et \\t décodés")
    w("E11", "Write", adh + "/.planning/a\rb.md", dev, "tight", note="\\r arrête le décodage : préfixe")
    w("E11b", "Write", dev + "/.planning/a\rb.md", adh, "tight", note="préfixe dev, cwd adhérent : le doute tombe du côté du refus")
    texte12 = ('{"session_id":"s","cwd":"' + dev + '","hook_event_name":"PreToolUse","tool_name":"Write",'
               '"tool_input":{"file_path":"' + adh + '/.planning/notes.md","file_path":"' + dev
               + '/.planning/notes.md","content":"x"}}')
    brut_cas("E12", "Write", texte12.encode("utf-8"), "tight", note="clé en double : la première gagne")
    piege = '"file_path":"' + adh + '/.planning/x"'
    cas.append(Cas("E13", "Write", payload("Write", {"content": "avant " + piege, "file_path": dev + "/" + notes}, dev),
                   "none", t, True, "contenu piégé avant la vraie clé"))
    cas.append(Cas("E14", "Write", payload("Write", {"file_path": dev + "/" + notes, "content": piege + " après"}, dev),
                   "none", t, True, "contenu piégé après la vraie clé"))
    cas.append(Cas("E15", "Bash", payload("Bash", {"command": "echo '{" + piege + "}'"}, adh),
                   "none", t, True, "Bash dont la commande cite un objet file_path"))
    cas.append(Cas("E16", "Write", payload("Write", {"content": "a" * 200000, "file_path": adh + "/" + notes}, dev),
                   "tight", t, True, "200 Ko avant la clé"))
    cas.append(Cas("E17", "Write", payload("Write", {"file_path": adh + "/" + notes, "content": "b" * 1000000}, dev),
                   "tight", t, True, "1 Mo après la clé"))
    cas.append(Cas("E18", "Write", payload("Write", {"content": "c" * 5000000, "file_path": adh + "/" + notes}, dev),
                   "tight", t, True, "5 Mo avant la clé"))
    w("E19", "Write", adh + "/" + notes, adh, "none", compact=False, note="JSON espacé : tool_name espacé (limite a)")
    tronque = payload("Write", {"file_path": adh + "/" + notes, "content": "x" * 400}, dev)
    brut_cas("E20", "Write", tronque[: len(tronque) - 200], "tight", python_ok=False, note="JSON tronqué en pleine chaîne")
    brut_cas("E21", "Write", b"", "none", python_ok=False, note="entrée vide")
    inval = payload("Write", {"file_path": adh + "/" + notes, "content": "AAA_INVALIDE_BBB"}, dev)
    brut_cas("E22", "Write", inval.replace(b"AAA_INVALIDE_BBB", b"\xff\xfe\xc3"), "tight", note="octets invalides dans le contenu")
    w("E23", "NotebookEdit", adh + "/.planning/nb.ipynb", dev, "tight", note="notebook_path")
    cas.append(Cas("E24", "Write", payload("Write", {"content": "x"}, adh), "tight", t, True, "sans chemin : repli sur le cwd du payload"))
    obj24b = {"session_id": "s", "hook_event_name": "PreToolUse", "tool_name": "Write", "tool_input": {"content": "x"}}
    brut24 = json.dumps(obj24b, separators=(",", ":")).encode("utf-8")
    brut_cas("E24b", "Write", brut24, "tight", cwd_proc=adh, note="sans chemin ni cwd : repli pwd -P (processus dans un lab adhérent)")
    brut_cas("E24c", "Write", brut24, "none", cwd_proc=dev, note="sans chemin ni cwd : repli pwd -P (processus dans un lab dev)")
    # ---- E25-E36 : dispatch, chemins relatifs, lectures ----
    w("E25", "Agent", None, adh, "tight", note="dispatch Agent sous un lab adhérent")
    w("E26", "Task", None, adh, "tight", note="dispatch Task sous un lab adhérent")
    w("E27", "Agent", None, dev, "none", note="dispatch Agent sous un lab dev")
    w("E28", "Task", None, dev, "none", note="dispatch Task sous un lab dev")
    faux = {"description": "d", "prompt": 'faux "cwd":"' + adh + '" ici', "subagent_type": "general-purpose"}
    cas.append(Cas("E29", "Agent", payload("Agent", faux, dev), "none", t, True, "prompt d'Agent qui cite un faux cwd adhérent"))
    w("E30", "Write", "livrable.md", adh, "tight", note="chemin relatif, cwd adhérent")
    w("E31", "Write", "livrable.md", dev, "none", note="chemin relatif, cwd dev")
    w("E32", "Write", "../dev/" + notes, adh, "none", note="chemin relatif ../ vers un voisin dev depuis un cwd adhérent")
    w("E33", "NotebookEdit", ".planning/nb.ipynb", adh, "tight", note="NotebookEdit relatif, cwd adhérent")
    w("E34", "Bash", None, adh, "none", note="Bash sous un lab adhérent (limite déclarée)")
    w("E35", "Read", adh + "/" + notes, adh, "none", note="lecture sous un lab adhérent")
    w("E36", "Edit", adh + "/livrable.md", dev, "tight", note="Edit d'un livrable déclaré")
    # ---- A01-A15 : arbres ----
    w("A01", "Write", adh + "/" + notes, dev, "tight", note="adhérent")
    w("A02", "Write", L["pretty"] + "/" + notes, dev, "tight", note="adhérent, config espacée sur plusieurs lignes")
    w("A03", "Write", L["nextline"] + "/" + notes, dev, "none", note="valeur sur la ligne suivante (limite b)")
    w("A04", "Write", L["escaped"] + "/" + notes, dev, "none", note="cycles-v1 échappé (limite b)")
    w("A05", "Write", dev + "/" + notes, adh, "none", note="dev")
    w("A06", "Write", L["dev-note"] + "/" + notes, adh, "none", note="dev dont config.json mentionne cycles-v1 sous une autre clé")
    w("A07", "Write", L["dev-sans-config"] + "/" + notes, adh, "none", note="dev sans config.json")
    w("A08", "Write", L['lab sp"q\\b'] + "/" + notes, dev, "tight", note="dossier de lab avec espace, guillemet et backslash")
    w("A09a", "Write", L["devout/inner"] + "/" + notes, dev, "tight", note="adhérent dans dev : le plus proche gagne")
    w("A09b", "Write", L["adhout/inner-dev"] + "/" + notes, adh, "none", note="dev dans adhérent : le plus proche gagne")
    w("A10a", "Write", L["alias-adh"] + "/" + notes, dev, "tight", note="alias de lab")
    w("A10b", "Write", L["lab-plink"] + "/livrable.md", dev, "tight", note="alias de .planning")
    w("A11a", "Write", adh + "/link-dev/" + notes, adh, "none", note="lien d'un adhérent vers un dev")
    w("A11b", "Write", dev + "/link-sub/notes.md", dev, "tight", note="lien d'un dev vers un sous-dossier d'un adhérent")
    w("A11c", "Write", adh + "/link-bare/notes.md", dev, "none", note="lien d'un adhérent vers un dossier hors de tout lab")
    w("A11d", "Write", dev + "/link-adh/" + notes, dev, "tight", note="lien d'un dev vers un adhérent")
    w("A12", "Write", adh + "/absent/../" + notes, dev, "tight", note="`..` qui traverse un dossier inexistant")
    # m1 : `..` après un composant INEXISTANT — le Python replie lexicalement (realpath), la couche shell
    # doit décider pareil. Chaque cas se joue dans les trois modes (A script réel, C script absent,
    # D python absent) et le verdict dégradé de C et D doit égaler la décision de la couche Python.
    w("A16", "Write", dev + "/nonexist/../../adh/" + notes, dev, "tight", note="`..` après un composant inexistant, dev vers adhérent : la cible est un lab adhérent")
    w("A17", "Write", adh + "/nonexist/../../dev/" + notes, adh, "none", note="`..` après un composant inexistant, adhérent vers dev : la cible est un lab dev")
    w("A18", "Write", dev + "/link-adh/../adh/" + notes, dev, "tight", note="`..` après un lien vers un dossier existant : replié PHYSIQUEMENT (garde contre un repli lexical naïf)")
    w("A13", "Write", L["cfglink"] + "/" + notes, dev, "tight", note="config.json en lien symbolique (limite c : côté shell adhérent)")
    w("A14", "Write", dev + "/" + notes, adh, "none", note="session dans un adhérent qui écrit dans un dev voisin")
    w("A15", "Write", adh + "/" + notes, dev, "tight", note="session dans un dev qui écrit dans un adhérent voisin")
    # ---- A19-A23 : `.planning` imbriqué (lot A, B1/H1) — chaque cas se joue dans les six modes
    phase_imb = ".planning/cycles/01-c/phases/01-p/"
    w("A19", "Write", L["imb-a"] + "/.planning/notes.md", dev, "tight", note="`.planning/.planning` : le planning du lab reste la racine")
    w("A20", "Write", L["imb-b"] + "/" + phase_imb + "VERDICT.md", dev, "tight", note="`.planning/cycles/.planning` : la racine reste le lab")
    w("A21", "Write", L["imb-c"] + "/" + phase_imb + "VERDICT.md", dev, "tight", note="`<phase>/.planning` : la phase n'est jamais une racine")
    w("A22", "Edit", L["imb-c"] + "/" + phase_imb + "PLAN.md", dev, "tight", note="`<phase>/.planning`, Edit du PLAN.md de la phase")
    w("A23", "NotebookEdit", L["imb-c"] + "/" + phase_imb + "nb.ipynb", dev, "tight", note="`<phase>/.planning`, NotebookEdit")
    # ---- A24-A27 : `.planning` sous `.claude` (lot E, F1) — chaque cas se joue dans les six modes
    w("A24", "Write", L["claude-b"] + "/.claude/scripts/planning-hook.sh", dev, "tight", note="`.claude/scripts/.planning` : la racine reste le lab, le script du hook reste gardé")
    w("A25", "Write", L["claude-a"] + "/.claude/notes.md", dev, "tight", note="`.claude/.planning` : la racine reste le lab")
    w("A26", "Write", L["wt"] + "/.planning/notes.md", dev, "tight", note="lab adhérent posé sous `.claude/worktrees/<nom>` : reste une racine")
    w("A27", "Write", L["wt"] + "/.claude/scripts/planning-hook.sh", dev, "tight", note="`.claude/scripts/.planning` d'un lab sous `.claude/worktrees/<nom>` : la racine reste ce lab")
    # ---- A28-A29 : casse de `.claude` et de `worktrees` dans la commande enregistrée (lot F, M4) — chaque cas se joue dans les six modes
    w("A28", "Write", L["claude-casse"] + "/.CLAUDE/scripts/planning-hook.sh", dev, "tight", note="`.CLAUDE/scripts/.planning` (casse physique) : la racine reste le lab, le script du hook reste gardé")
    w("A29", "Write", L["wt-casse"] + "/.planning/notes.md", dev, "tight", note="lab adhérent posé sous `.claude/WORKTREES/<nom>` (casse physique) : reste une racine")
    # ---- E37-E39 : échappement JSON non géré (b, f, u0001) dans le chemin écrit, lot A (audit B1, basse). La couche shell
    # ne peut pas décoder la valeur (X=0 : préfixe seulement) ; en panne, un préfixe hors de tout lab adhérent avec un cwd
    # hors du lab ne doit JAMAIS ouvrir : le doute d'adhésion ferme (P45-D-06a), comme E11b.
    w("E37", "Write", dev + "/a\x08b/../../adh/" + notes, dev, "tight", note="échappement JSON b (non géré) : le préfixe est un dossier dev, la cible réelle un lab adhérent, cwd hors du lab")
    w("E38", "Write", dev + "/x\x0cy.md", dev, "tight", note="échappement JSON f (non géré) dans un chemin dev, cwd dev : le doute ferme en panne")
    w("E39", "Edit", dev + "/x\x01y.md", dev, "tight", note="échappement JSON u0001 (non géré) : le doute ferme en panne")
    # E40 : l'extraction DOIT décoder un guillemet échappé — sinon, le doute d'adhésion fermant en panne (E37-E39), un lab dev
    # serait refusé à tort ; seul un lab dev, un cwd hors de tout lab et un nom à guillemet distinguent l'extraction fidèle d'une
    # extraction tronquée (les mutants EXT-2 et EXT-4 y sont opposables).
    w("E40", "Write", L['dq"x'] + "/" + notes, L["bare"], "none", note="guillemet échappé dans un lab dev, cwd hors de tout lab : décodé, donc silence")
    ctx.corpus = cas
    ctx.labs = L
    return cas


def cas_par_id(ctx, ident):
    for c in construire_corpus(ctx):
        if c.ident == ident:
            return c
    raise KeyError(ident)


def attendu_mode(cas, mode):
    """`silence`, `deny` ou `passe-plat` (mode B : le deny du substitut, octet pour octet)."""
    if mode == "B":
        return "passe-plat"
    if mode == "A" and cas.python_ok:
        return "silence"
    return "deny" if cas.degrade == "tight" and cas.outil in OUTILS_FILTRES else "silence"


def obtenu_mode(cas, mode, rc, out, err):
    """Nom du verdict obtenu, comparable à `attendu_mode`."""
    if mode == "B":
        return "passe-plat" if (rc == 0 and out == (DENY_B + "\n").encode("utf-8")) else "autre:rc=%d out=%s" % (rc, court(out))
    v = verdict(rc, out)
    if v == "deny":
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
        return "deny" if ("Reparer" in raison or "erreur interne" in raison) else "autre:deny-inattendu"
    return v


def sec_matrice(ctx):
    cas = construire_corpus(ctx)
    n = len(cas)
    print("CORPUS n=%d plancher=%d (minimum de la recherche : %d)" % (n, PLANCHER_CORPUS, PLANCHER_MIN))
    if n < PLANCHER_MIN or n != PLANCHER_CORPUS:
        ko("R-CORPUS", "le compte réel des cas exercés égale le plancher déclaré en dur (≥ %d)" % PLANCHER_MIN,
           "n=%d" % PLANCHER_CORPUS, "n=%d" % n)
    else:
        ok("R-CORPUS %d cas exercés = plancher déclaré (≥ %d)" % (n, PLANCHER_MIN))
    for mode in "ABCDEF":
        fautes = 0
        for c in cas:
            rc, out, err, _ = ctx.lancer(mode, c.brut, cwd=c.cwd_proc, np=True)
            att, obt = attendu_mode(c, mode), obtenu_mode(c, mode, rc, out, err)
            bruit = bool(err) and mode in "ABCD"
            if att != obt or bruit:
                fautes += 1
                ko("R-MATRICE mode %s cas %s" % (mode, c.ident),
                   "%s (%s) sous /bin/sh, mode %s" % (c.ident, c.note, mode),
                   att + (" et stderr vide" if mode in "ABCD" else ""),
                   obt + (" stderr=" + court(err) if bruit else ""))
        if not fautes:
            ok("R-MATRICE mode %s : %d cas sous /bin/sh, verdicts conformes (%s)" % (
                mode, n, {"A": "script réel, silence partout", "B": "deny du substitut rejoué octet pour octet",
                          "C": "script absent", "D": "python absent", "E": "script qui sort 1", "F": "script qui sort 2"}[mode]) + " · commande SANS pré-filtre")
    # La commande COMPLÈTE : même sortie que sans pré-filtre, SAUF quand le pré-filtre court-circuite (silence : le script n'est pas lancé).
    for mode in "ABCDEF":
        fautes, courts = 0, 0
        for c in cas:
            rc, out, err, _ = ctx.lancer(mode, c.brut, cwd=c.cwd_proc)
            rcn, outn, errn, _ = ctx.lancer(mode, c.brut, cwd=c.cwd_proc, np=True)
            t, extra = ctx.preparer(ctx.dossier_mode(mode), ctx.cmd_pre)
            _, sortie, _, _ = ctx.rejouer(t, c.brut, ctx.env_mode(mode, extra), c.cwd_proc)
            court_circuit = sortie == b"SHORT"
            courts += int(court_circuit)
            attendu = (0, b"", b"") if court_circuit else (rcn, outn, errn)
            if (rc, out, err) != attendu or sortie not in (b"SHORT", b"DEFER"):
                fautes += 1
                ko("R-MATRICE-PRE mode %s cas %s" % (mode, c.ident), "commande complète = commande sans pré-filtre, ou silence si SHORT (%s)" % c.note,
                   "rc=%d out=%s" % (attendu[0], court(attendu[1])), "rc=%d out=%s err=%s sortie du pré-filtre=%s" % (rc, court(out), court(err), court(sortie)))
        if not fautes:
            ok("R-MATRICE-PRE mode %s : %d cas, commande complète identique à la commande sans pré-filtre (%d court-circuits, tous silencieux)" % (mode, n, courts))


# --- Extraction seule sous chaque shell (fonctions de la commande isolées, sans spawn du script) ---
def sonde_extraction(cmd):
    debut = cmd.index("NL='")
    fin = cmd.index("\nD=1;")
    defs = cmd[debut:fin]
    return ("I=$(cat)\n" + defs + "\n"
            'if vf_get file_path; then K=file_path; elif vf_get notebook_path; then K=notebook_path; else K=none; fi\n'
            'if [ "$K" = none ]; then printf "K=none\\n"; else\n'
            '  printf "K=%s\\nX=%s\\nV=%s\\n" "$K" "$X" "$(printf "%s" "$V" | od -An -v -tx1 | tr -d " \\n")"\n'
            '  case $V in /*) if vf_tight "$V"; then echo D=0; else echo D=1; fi ;; *) echo D=rel ;; esac\n'
            'fi\n')


def extrait_reference(brut):
    """Oracle indépendant : la lecture attendue de `file_path`, sinon `notebook_path`."""
    texte = brut.decode("utf-8", "replace")
    for cle in ("file_path", "notebook_path"):
        m = re.search(r'"' + cle + r'"[ \t]*:[ \t]*"((?:[^"\\]|\\.)*)"', texte)
        if not m:
            continue
        v, i, out, x = m.group(1), 0, [], 1
        while i < len(v):
            c = v[i]
            if c != "\\":
                out.append(c)
                i += 1
                continue
            e = v[i + 1]
            if e in '"\\/':
                out.append(e)
            elif e == "n":
                out.append("\n")
            elif e == "t":
                out.append("\t")
            else:
                x = 0
                break
            i += 2
        return cle, x, "".join(out)
    return "none", None, None


def _sous_claude_reference(chemin):
    """Oracle (lot E, F1) : le DERNIER composant `.claude` n'est pas suivi de `worktrees/<nom>`."""
    comps = chemin.lower().split(os.sep)
    if ".claude" not in comps:
        return False
    reste = [c for c in comps[len(comps) - 1 - comps[::-1].index(".claude") + 1:] if c]
    return not (len(reste) >= 2 and reste[0] == "worktrees")


def tight_reference(chemin):
    if not chemin.startswith("/"):
        return None
    courant = os.path.realpath(chemin)
    while not os.path.isdir(courant):
        parent = os.path.dirname(courant)
        if parent == courant:
            return False
        courant = parent
    while True:
        if os.path.isdir(os.path.join(courant, ".planning")) and ".planning" not in [c.lower() for c in courant.split(os.sep)] \
                and not _sous_claude_reference(courant):
            cfg = os.path.join(courant, ".planning", "config.json")
            if not os.path.isfile(cfg):
                return False
            lignes = open(cfg, "rb").read().decode("utf-8", "replace").split("\n")
            return any(re.search(r'"planning_version"[ \t]*:[ \t]*"cycles-v1"', l) for l in lignes)
        parent = os.path.dirname(courant)
        if parent == courant:
            return False
        courant = parent


def shells_presents():
    res = [("sh", ["/bin/sh", "-c"])]
    d = shutil.which("dash")
    if d:
        res.append(("dash", [d, "-c"]))
    b = shutil.which("bash")
    if b:
        res.append(("bash", [b, "-c"]))
    z = shutil.which("zsh")
    if z:
        res.append(("zsh", [z, "-f", "-c"]))
    return res


def sec_shells(ctx):
    cas = construire_corpus(ctx)
    sonde = sonde_extraction(ctx.cmd)
    exerces = []
    fautes = 0
    for nom, argv in shells_presents():
        texte = ("emulate sh\n" + sonde) if nom == "zsh" else sonde
        exerces.append(nom)
        for c in cas:
            env = ctx.env_mode("A")
            p = subprocess.run(argv + [texte], input=c.brut, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               env=env, cwd=c.cwd_proc, timeout=120)
            cle, x, v = extrait_reference(c.brut)
            if cle == "none":
                attendu = "K=none\n"
            else:
                d = tight_reference(v)
                attendu = "K=%s\nX=%d\nV=%s\nD=%s\n" % (cle, x, v.encode("utf-8").hex(),
                                                        "rel" if d is None else ("0" if d else "1"))
            obtenu = p.stdout.decode("utf-8", "replace")
            if obtenu != attendu:
                fautes += 1
                ko("R-EXTRACTION shell %s cas %s" % (nom, c.ident), "extraction de %s (%s) sous %s" % (c.ident, c.note, nom),
                   court(attendu.replace("\n", " | ")), court(obtenu.replace("\n", " | ")) + " " + court(p.stderr))
    print("SHELLS-EXERCES " + " ".join(exerces))
    if "sh" not in exerces or "bash" not in exerces:
        ko("R-EXTRACTION plancher", "sh et bash toujours exercés", "sh bash", " ".join(exerces))
    elif not fautes:
        ok("R-EXTRACTION mêmes verdicts sous %s : %d cas, V, X et D identiques à l'oracle" % (", ".join(exerces), len(cas)))


# --- Performance : 5 Mo, clé en fin de charge utile ------------------------------------------
def sec_perf(ctx):
    adh, _dev = _labs_simples(ctx, "perf")
    lourd = payload("Write", {"content": "z" * 5000000, "file_path": adh + "/.planning/notes.md"}, adh)
    fautes = []
    mesures = []
    for mode in ("C", "A"):
        rc, out, err, dt = ctx.lancer(mode, lourd, cwd=adh)
        attendu = "deny" if mode == "C" else "silence"
        v = verdict(rc, out)
        mesures.append("mode %s %.2f s" % (mode, dt))
        if v != attendu or dt >= 5.0:
            fautes.append((mode, "%s en moins de 5 s" % attendu, "%s en %.2f s" % (v, dt)))
    if fautes:
        for mode, a, b in fautes:
            ko("R-PERF", "5 Mo, clé en fin de charge utile, mode " + mode, a, b)
    else:
        ok("R-PERF 5 Mo, clé en fin : tranché en moins de 5 s (%s)" % ", ".join(mesures))


# --- Le dépôt lui-même : lab dev, jamais un octet ---------------------------------------------
def sec_depot(ctx):
    racine = ctx.repo_root
    if not racine or not os.path.isfile(os.path.join(racine, "plugin", "planning-core", "scripts", "planning-hook.sh")):
        print("NOTE R-DEPOT hors dépôt : plugin/planning-core/scripts/planning-hook.sh absent à côté des suites — cas non rejoué (jamais un vert)")
        return
    cibles = (".planning/STATE.md", "README.md", "plugin/planning-core/VERSION")
    fautes = []
    n = 0
    for mode in ("A", "C", "D"):
        for outil in SIX_OUTILS:
            for rel in cibles:
                chemin = os.path.join(racine, rel)
                rc, out, err, _ = ctx.lancer(mode, payload(outil, entree_outil(outil, chemin), racine), cwd=racine)
                n += 1
                if rc != 0 or out != b"" or err:
                    fautes.append(("%s %s mode %s" % (outil, rel, mode), "stdout 0 octet, code 0", "rc=%d out=%s err=%s" % (rc, court(out), court(err))))
    if fautes:
        for a, b, c in fautes:
            ko("R-DEPOT", a, b, c)
    else:
        ok("R-DEPOT ce dépôt (lab dev) : %d rejeux (six outils, trois cibles, modes A, C, D) : stdout 0 octet, code 0" % n)


# =================================================================================================
# Mutants (quatre conditions : (a) texte distinct et `sh -n` ; (b) témoin identique ; (c) l'obtenu
# est un verdict et non une erreur de syntaxe ; (d) trace assertion / attendu / obtenu imprimée)
# =================================================================================================
MARQUEURS_SYNTAXE = ("syntax error", "unexpected", "unterminated", "bad substitution", "parse error")


def nom_verdict(rc, out, err):
    v = verdict(rc, out)
    if v == "autre:rc=2" and out:
        return "code 2 (deny imprimé)"
    if v == "autre:rc=2":
        return "code 2"
    if v == "autre:document":
        v = "document invalide (json.loads échoue)"
    return v + ((" stderr=" + court(err, 60)) if err else "")


def okmut(ident, trace):
    print("  ✓ MUT-%s TUÉ — %s" % (ident, trace))


def komut(ident, assertion, attendu, obtenu):
    print("  ✗ MUT-%s NON TUÉ" % ident)
    print("    assertion : " + assertion)
    print("    attendu (original) : " + attendu)
    print("    obtenu (mutant)     : " + obtenu)


def make_cmd_mutant(ctx, ident, motif, remplacement):
    """Texte muté de la commande enregistrée : motif fixe à occurrence unique, sinon komut."""
    n = ctx.cmd_np.count(motif)
    if n != 1:
        return None, "motif ambigu ou absent (occurrences=%d)" % n
    muté = ctx.cmd_np.replace(motif, remplacement)
    if muté == ctx.cmd_np:
        return None, "NON OPPOSABLE (texte identique à l'original)"
    chemin = ctx.unique("cmd-" + ident.lower()) + ".sh"
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(muté.replace(TOKEN, "/nonexistent") if TOKEN in muté else muté)
    p = subprocess.run(["/bin/sh", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "sh -n ÉCHOUE : " + court(p.stderr)
    return muté, None


def rejouer_texte(ctx, texte, mode, brut, cwd):
    t, extra = ctx.preparer(ctx.dossier_mode(mode), texte)
    return ctx.rejouer(t, brut, ctx.env_mode(mode, extra), cwd)


def mutant_cmd(ctx, ident, motif, remplacement, id_disc, mode, id_temoin="E01", mode_temoin=None, attendu_code=0):
    muté, raison = make_cmd_mutant(ctx, ident, motif, remplacement)
    if muté is None:
        komut(ident, "condition (a) : texte muté distinct de l'original et sh -n réussit", "mutant valide", raison)
        return
    mode_temoin = mode_temoin or mode
    disc, tem = cas_par_id(ctx, id_disc), cas_par_id(ctx, id_temoin)
    o_t = rejouer_texte(ctx, ctx.cmd_np, mode_temoin, tem.brut, tem.cwd_proc)
    m_t = rejouer_texte(ctx, muté, mode_temoin, tem.brut, tem.cwd_proc)
    if o_t[:3] != m_t[:3]:
        komut(ident, "condition (b) : sur le témoin %s (mode %s) le mutant sort comme l'original" % (id_temoin, mode_temoin),
              nom_verdict(*o_t[:3]), nom_verdict(*m_t[:3]))
        return
    o_d = rejouer_texte(ctx, ctx.cmd_np, mode, disc.brut, disc.cwd_proc)
    m_d = rejouer_texte(ctx, muté, mode, disc.brut, disc.cwd_proc)
    att_nom = attendu_mode(disc, mode)
    if att_nom != obtenu_mode(disc, mode, *o_d[:3]):
        komut(ident, "l'original rend le verdict déclaré sur %s (garde du témoin de la mutation)" % id_disc,
              att_nom, nom_verdict(*o_d[:3]))
        return
    syntaxe = any(mk in m_d[2].decode("utf-8", "replace") for mk in MARQUEURS_SYNTAXE)
    if m_d[0] != attendu_code or syntaxe:
        komut(ident, "condition (c) : le mutant rend un verdict (code %d), jamais une erreur de syntaxe" % attendu_code,
              "code %d sans erreur de syntaxe" % attendu_code, "rc=%d stderr=%s" % (m_d[0], court(m_d[2])))
        return
    if o_d[:3] == m_d[:3]:
        komut(ident, "le mutant change le verdict sur %s (mode %s)" % (id_disc, mode),
              nom_verdict(*o_d[:3]), nom_verdict(*m_d[:3]) + " (mutant non opposable)")
        return
    okmut(ident, "cas %s (%s) mode %s sous /bin/sh · attendu (original) : %s · obtenu (mutant) : %s · témoin %s inchangé · (a) (b) (c) (d) vérifiées"
          % (id_disc, disc.note, mode, nom_verdict(*o_d[:3]), nom_verdict(*m_d[:3]), id_temoin))


def sec_mutants(ctx):
    construire_corpus(ctx)
    M = [
        ("EXT-1", '_y=$(cd -P -- "$_n" 2>/dev/null && pwd -P)', '_y=$(cd -- "$_n" 2>/dev/null && pwd)', "A11b", "C", {}),
        ("EXT-2", '"([^"\\\\]|\\\\.)*"\'', '"[^"]*"\'', "E40", "C", {}),
        ("EXT-3", '2>/dev/null; return $?; fi', '2>/dev/null && return 0; fi', "A09b", "C", {}),
        ("EXT-4", '\\\\\\"*) V=$V\\" ;;', '\\\\\\"*) X=0; return 0 ;;', "E40", "C", {}),
        ("EXT-5", 'for K in file_path notebook_path; do', 'for K in zz_file zz_note; do', "A14", "C", {}),
        ("EXT-6", '| head -n 1); [ -n "$_m" ]', '| tail -n 1); [ -n "$_m" ]', "E12", "C", {}),
        ("EXT-7", "-q -E '\"planning_version\"[[:space:]]*:[[:space:]]*\"cycles-v1\"'", "-q -F 'cycles-v1'", "A06", "C", {}),
        ("EXT-8", 'else vf_tight "$(pwd -P)" && D=0; fi; fi\n[ "$D" -eq 0 ]', 'else :; fi; fi\n[ "$D" -eq 0 ]', "E24b", "C", {}),
        ("EXT-9", 'then P=$V/$P; else', 'then :; else', "E30", "C", {}),
        ("EXT-10", '..) _r=${_r%/*}; [ -n "$_r" ] || _r=/ ;;', '..) ;;', "A16", "C", {}),
        ("EXT-11", 'if [ -d "$_n" ] && _y=$(cd', 'if false && _y=$(cd', "A18", "C", {}),
        ("EXT-12", '*/[.][Pp][Ll][Aa][Nn][Nn][Ii][Nn][Gg]/*) ;;', '*/[.][Zz][Zz][Zz]/*) ;;', "A21", "C", {}),
        ("EXT-12D", '*/[.][Pp][Ll][Aa][Nn][Nn][Ii][Nn][Gg]/*) ;;', '*/[.][Zz][Zz][Zz]/*) ;;', "A19", "D", {}),
        ("EXT-13", 'if ! vf_cl "$_d" && [ -d "$_d/.planning" ]; then', 'if [ -d "$_d/.planning" ]; then', "A24", "C", {}),
        ("EXT-13D", 'if ! vf_cl "$_d" && [ -d "$_d/.planning" ]; then', 'if [ -d "$_d/.planning" ]; then', "A25", "D", {}),
        ("EXT-14", 'case $_w in [Ww][Oo][Rr][Kk][Tt][Rr][Ee][Ee][Ss]/?*/) return 1 ;; esac; ', '', "A26", "C", {}),
        ("EXT-15", '_w=${_w##*/[.][Cc][Ll][Aa][Uu][Dd][Ee]/}', '_w=${_w#*/[.][Cc][Ll][Aa][Uu][Dd][Ee]/}', "A27", "C", {}),
        ("EXT-16", 'case $_w in */[.][Cc][Ll][Aa][Uu][Dd][Ee]/*) _w=${_w##*/[.][Cc][Ll][Aa][Uu][Dd][Ee]/};',
         'case $_w in */[.]claude/*) _w=${_w##*/[.]claude/};', "A28", "C", {}),
        ("EXT-17", 'case $_w in [Ww][Oo][Rr][Kk][Tt][Rr][Ee][Ee][Ss]/?*/) return 1 ;; esac;',
         'case $_w in worktrees/?*/) return 1 ;; esac;', "A29", "C", {}),
        ("PX-1", 'elif [ "$PX" = 0 ]; then D=0; fi', 'elif [ "$PX" = 0 ] && { vf_get cwd && vf_tight "$V"; }; then D=0; fi', "E37", "C", {}),
        ("PX-1D", 'elif [ "$PX" = 0 ]; then D=0; fi', 'elif [ "$PX" = 0 ] && { vf_get cwd && vf_tight "$V"; }; then D=0; fi', "E38", "D", {}),
        ("CMD-1", ';; *) exit 0 ;; esac', ';; *) ;; esac', "E35", "C", {}),
        ("CMD-2", 'bash "$S"); R=$?; fi', 'bash "$S"); R=0; fi', "E01", "E", {"id_temoin": "E27"}),
        ("CMD-3", 'if [ -f "$S" ]; then O=', 'if :; then O=', "E01", "C", {"mode_temoin": "A"}),
        ("CMD-4", 'la session."}}\'', 'la session."}\'', "E01", "C", {"id_temoin": "E27"}),
        ("CMD-5", 'la session."}}\'\nexit 0', 'la session."}}\'\nexit 2', "E01", "C", {"id_temoin": "E27", "attendu_code": 2}),
        ("CMD-6", "|*'\"tool_name\":\"Agent\"'*|*'\"tool_name\":\"Task\"'*", "", "E25", "C", {}),
        ("CMD-7", "*'\"tool_name\":\"Task\"'*) ;;", "*'\"tool_name\":\"Task\"'*|*'\"tool_name\":\"Bash\"'*) ;;", "E34", "C", {}),
    ]
    for ident, motif, repl, disc, mode, kw in M:
        mutant_cmd(ctx, ident, motif, repl, disc, mode, **kw)
    # MUT-LIBELLE-* (lot C, F4) : le libellé de doute retiré, ou appliqué à un lab réellement adhérent
    adh_l, dev_l = _labs_simples(ctx, "libelle-mut")
    for ident, motif, remplacement in (
            ("LIBELLE-DOUTE", 'if [ "$K" = done ] && [ "$PX" = 0 ] && ! vf_tight "$P"; then', "if false; then"),
            ("LIBELLE-ADHERENT", 'if [ "$K" = done ] && [ "$PX" = 0 ] && ! vf_tight "$P"; then', 'if [ "$K" = done ] && [ "$PX" = 0 ]; then')):
        muté, raison = make_cmd_mutant(ctx, ident, motif, remplacement)
        if muté is None:
            komut(ident, "texte muté distinct de l'original et sh -n réussit", "mutant valide", raison)
            continue
        original = controle_libelle_f4(ctx, ctx.cmd_np, adh_l, dev_l)
        mutant = controle_libelle_f4(ctx, muté, adh_l, dev_l)
        if not original[0]:
            komut(ident, "l'original passe R-CMD-05b", "conforme", original[1])
        elif mutant[0]:
            komut(ident, "R-CMD-05b rougit sous le mutant", "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
        else:
            okmut(ident, "R-CMD-05b rougit · attendu (original) : %s · obtenu (mutant) : %s" % (original[1], mutant[1]))
    # MUT-PY-PHASE-A : la sortie sur exception de la phase A remplacée par une sortie 0
    dossier, raison = make_hook_mutant(ctx, "PYA", "sys.exit(3)  # phase-a-sortie", "sys.exit(0)")
    if dossier is None:
        komut("PY-PHASE-A", "mutant du cœur (bash -n et compilation du corps)", "mutant valide", raison)
        return
    disc, tem = cas_par_id(ctx, "E20"), cas_par_id(ctx, "E01")
    o_t = ctx.lancer("A", tem.brut, cwd=tem.cwd_proc)
    m_t = ctx.lancer("A", tem.brut, cwd=tem.cwd_proc, dossier=dossier)
    if o_t[:3] != m_t[:3]:
        komut("PY-PHASE-A", "condition (b) : témoin E01 identique", nom_verdict(*o_t[:3]), nom_verdict(*m_t[:3]))
        return
    o_d = ctx.lancer("A", disc.brut, cwd=disc.cwd_proc)
    m_d = ctx.lancer("A", disc.brut, cwd=disc.cwd_proc, dossier=dossier)
    if obtenu_mode(disc, "A", *o_d[:3]) != "deny" or m_d[0] != 0 or o_d[:3] == m_d[:3]:
        komut("PY-PHASE-A", "phase A en faute (payload tronqué, lab adhérent) : l'original refuse (couche shell), le mutant se tait",
              nom_verdict(*o_d[:3]), nom_verdict(*m_d[:3]))
        return
    okmut("PY-PHASE-A", "cas E20 (payload tronqué, lab adhérent) mode A · attendu (original) : %s · obtenu (mutant) : %s · témoin E01 inchangé · (a) (b) (c) (d) vérifiées"
          % (nom_verdict(*o_d[:3]), nom_verdict(*m_d[:3])))

# =================================================================================================
# R-BORNE (F-01, audit de sécurité final du 2026-10-01 ; décisions du manager vf-dev-manager) : la couche shell de repli n'est
# plus quadratique en la longueur d'une valeur du payload. Au-delà de 4096 caractères la valeur n'est PAS parcourue (le coût
# mesuré avant : 23,27 s pour un chemin de 40 165 octets, au-delà du timeout de 20 s du harnais, qui laisse alors passer) ; le
# doute se tranche sur le cwd : un cwd adhérent refuse (« chemin trop long pour etre analyse »), un cwd non adhérent se tait
# (GATE-03). La preuve est le LIBELLÉ et le verdict, jamais l'horloge seule : le mutant qui retire la borne perd le libellé
# quelle que soit la vitesse de la machine ; le plafond de 10 s n'est qu'une marge de 10x et plus sur le temps mesuré.
# =================================================================================================
LONG_BORNE = "./" * 6000          # 12 000 caractères, trois fois la borne
PLAFOND_BORNE_S = 10.0


def controle_borne_f01(ctx, texte, adh, dev):
    """Rend (conforme, détail) : sept rejeux de la couche shell seule (mode C, script absent)."""
    fautes = []
    mesures = []

    def jouer(etiquette, outil, entree, cwd_payload, cwd_proc, attendu, libelle=None, interdit=None):
        brut = payload(outil, entree, cwd_payload)
        rc, out, err, dt = rejouer_texte_t(ctx, texte, "C", brut, cwd_proc)
        mesures.append(dt)
        v = verdict(rc, out)
        if v != attendu or err or dt >= PLAFOND_BORNE_S:
            fautes.append("%s : %s en %.2f s stderr=%s (attendu %s en moins de %.0f s)" % (etiquette, v, dt, court(err), attendu, PLAFOND_BORNE_S))
            return
        if attendu == "deny":
            raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
            if "hook central indisponible" not in raison or "Reparer" not in raison:
                fautes.append("%s : raison %r sans « hook central indisponible » et « Reparer »" % (etiquette, raison[:160]))
            if libelle is not None and libelle not in raison:
                fautes.append("%s : libellé %r (attendu %r)" % (etiquette, raison[:200], libelle))
            if interdit is not None and interdit in raison:
                fautes.append("%s : libellé %r (jamais %r)" % (etiquette, raison[:200], interdit))

    trop = "chemin trop long pour etre analyse"
    jouer("chemin absolu trop long, cwd adhérent", "Write", {"file_path": adh + "/" + LONG_BORNE + ".planning/notes.md", "content": "x"},
          adh, adh, "deny", libelle=trop)
    jouer("chemin relatif trop long, cwd adhérent", "Write", {"file_path": LONG_BORNE + "x.md", "content": "x"}, adh, adh, "deny", libelle=trop)
    jouer("chemin absolu trop long, cwd non adhérent (GATE-03)", "Write", {"file_path": dev + "/" + LONG_BORNE + "x.md", "content": "x"},
          dev, dev, "silence")
    jouer("chemin relatif trop long, cwd non adhérent (GATE-03)", "Edit",
          {"file_path": LONG_BORNE + "x.md", "old_string": "a", "new_string": "b"}, dev, dev, "silence")
    jouer("cwd trop long, chemin court, processus dans un lab adhérent", "Write", {"file_path": "x.md", "content": "x"},
          adh + "/" + LONG_BORNE, adh, "deny", interdit=trop)
    jouer("cwd trop long, chemin court, processus dans un lab non adhérent (GATE-03)", "Write", {"file_path": "x.md", "content": "x"},
          dev + "/" + LONG_BORNE, dev, "silence")
    jouer("cwd trop long, aucun chemin (Agent), processus dans un lab adhérent", "Agent",
          {"description": "d", "prompt": "p", "subagent_type": "general-purpose"}, adh + "/" + LONG_BORNE, adh, "deny", interdit=trop)
    jouer("sous la borne (3 000 caractères) : analysé, jamais « trop long »", "Write",
          {"file_path": adh + "/" + "./" * 1500 + ".planning/notes.md", "content": "x"}, adh, adh, "deny",
          libelle="dans un lab adherent cycles-v1", interdit=trop)
    # Pire cas SOUS la borne : des composantes qui existent (chaque `cd -P` est un sous-shell). Marge de 10x sur le temps mesuré.
    base = os.path.basename(adh)
    remonte = ("../" + base + "/") * (3500 // (len(base) + 4))
    jouer("sous la borne, composantes existantes (pire cas des sous-shells)", "Write",
          {"file_path": adh + "/" + remonte + ".planning/notes.md", "content": "x"}, adh, adh, "deny", interdit=trop)
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d rejeux : valeur trop longue tranchée sur le cwd (adhérent refuse, non adhérent se tait), sous la borne analysée, pire temps %.2f s (plafond %.0f s)"
                          % (len(mesures), max(mesures), PLAFOND_BORNE_S))


def rejouer_texte_t(ctx, texte, mode, brut, cwd):
    t, extra = ctx.preparer(ctx.dossier_mode(mode), texte)
    return ctx.rejouer(t, brut, ctx.env_mode(mode, extra), cwd)


def sec_borne(ctx):
    adh, dev = _labs_simples(ctx, "borne")
    original = controle_borne_f01(ctx, ctx.cmd_np, adh, dev)
    if original[0]:
        ok("R-BORNE-01 " + original[1] + " · commande SANS pré-filtre")
    else:
        ko("R-BORNE-01", "valeur du payload au-delà de 4096 caractères : jamais parcourue, tranchée sur le cwd, GATE-03 tenu", "conforme", original[1])
    complet = controle_borne_f01(ctx, ctx.cmd, adh, dev)
    if complet[0]:
        ok("R-BORNE-02 " + complet[1] + " · commande COMPLÈTE (pré-filtre)")
    else:
        ko("R-BORNE-02", "mêmes verdicts avec le pré-filtre : une valeur trop longue le fait différer, jamais court-circuiter", "conforme", complet[1])
    for ident, motif, remplacement in (
            ("BORNE-RETIREE", 'if [ "${#_m}" -gt 4096 ]; then B=1;', 'if false; then B=1;'),
            ("BORNE-LAB-DEV", 'if [ "$K" = long ]; then if vf_get cwd && [ "$B" = 0 ]; then vf_tight "$V" && D=0; else vf_tight "$(pwd -P)" && D=0; fi; elif',
             'if [ "$K" = long ]; then D=0; elif'),
            ("BORNE-LIBELLE", 'if [ "$K" = long ]; then W=', 'if false; then W='),
            ("BORNE-CWD-REL", 'if vf_get cwd && [ "$B" = 0 ]; then P=$V/$P;', 'if vf_get cwd; then P=$V/$P;'),
            ("BORNE-CWD-AGENT", 'elif [ "$K" != done ]; then if vf_get cwd && [ "$B" = 0 ]; then', 'elif [ "$K" != done ]; then if vf_get cwd; then')):
        muté, raison = make_cmd_mutant(ctx, ident, motif, remplacement)
        if muté is None:
            komut(ident, "texte muté distinct de l'original et sh -n réussit", "mutant valide", raison)
            continue
        mutant = controle_borne_f01(ctx, muté, adh, dev)
        if not original[0]:
            komut(ident, "l'original passe R-BORNE-01", "conforme", original[1])
        elif mutant[0]:
            komut(ident, "R-BORNE-01 rougit sous le mutant", "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
        else:
            okmut(ident, "R-BORNE-01 rougit · attendu (original) : %s · obtenu (mutant) : %s" % (original[1], mutant[1]))


# =================================================================================================
# R-DOUTE (N-01 et N-03, re-audit de sécurité du 2026-10-01 ; décisions du manager vf-dev-manager, renversables, même classe que
# GATE-03). Propriété : aucun chemin que le hook ne sait pas analyser ne peut taire les gates sur un actif sous `.planning/` ou
# `.claude/` d'un lab adhérent, quel que soit le cwd. (a) COUCHE SHELL : une valeur trop longue pour être parcourue est REFUSÉE dès
# qu'elle contient `.planning` ou `.claude` (casse ignorée), quel que soit le cwd ; sinon la décision sur le cwd de R-BORNE tient.
# (b) CŒUR : un chemin qui fait lever l'analyse (surrogate isolé, NUL, `~utilisateur`) ne sort plus en code non nul : refus s'il nomme
# `.planning` ou `.claude`, sinon décision sur le cwd. (c) `~` et `~/…` sont développés en HOME dans les deux couches, jamais lus
# comme relatifs au cwd. La preuve est le VERDICT et le LIBELLÉ ; chaque mutant reproduit l'ancien comportement.
# =================================================================================================
def payload_ascii(outil, entree, cwd):
    """Comme payload(), en JSON ASCII : un surrogate isolé y est écrit `\\ud800` (ce que sérialise le harnais)."""
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "prompt_id": "prompt-test",
           "permission_mode": "default", "hook_event_name": "PreToolUse", "tool_name": outil, "tool_input": entree,
           "tool_use_id": "toolu_test"}
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=True).encode("ascii")


def labs_doute(ctx, nom):
    """(lab adhérent, hors lab, nom du lab du HOME). Le HOME de la suite porte un lab adhérent ; le hors-lab porte un dossier LITTÉRAL
    nommé `~` qui contient un faux lab non adhérent de même nom : lu comme relatif au cwd, `~/<nom>/.planning/STATE.md` y tombe."""
    base = ctx.unique(nom)
    adh = fabriquer_lab(os.path.join(base, "adh"), True)
    ecrire(os.path.join(adh, ".claude", "scripts", "planning-hook.sh"), "x\n")  # actif gardé sous `.claude/` (N3-01)
    hors = fabriquer_lab(os.path.join(base, "hors"), False)
    lab_home = "labdir-" + os.path.basename(base)
    fabriquer_lab(os.path.join(ctx.home, lab_home), True)
    fabriquer_lab(os.path.join(hors, "~", lab_home), False)
    return adh, hors, lab_home


def verdict_direct(ctx, brut, cwd):
    """Verdict du CŒUR LIVRÉ (armé), lancé directement : jamais la couche shell. Rend (verdict, rc, stdout, stderr)."""
    p = subprocess.run(["bash", os.path.join(ctx.scripts_dir_livre, "planning-hook.sh")], input=brut, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, env=ctx.env_mode("A"), cwd=cwd, timeout=120)
    return verdict(p.returncode, p.stdout), p.returncode, p.stdout, p.stderr


# --- N2-01 (re-audit 2 du 2026-10-02) : la CLASSE « valeur longue que la couche de repli ne sait pas analyser » ------------------------
# Un nom d'actif gardé peut s'écrire de bien des façons dans le JSON (`.planning`, `.planning`, `.PLANNING`) : la couche
# de repli ne le décode pas, elle refuse donc toute valeur longue qui porte `.planning`, `.claude` OU un antislash. Le cœur, lui, a décodé
# le JSON : une valeur longue y est jugée d'emblée sur son nom décodé, sans realpath ni racine_lab (quadratiques en profondeur).
PLAFOND_DECISION_S = 2.0
GRAINE_GENERATIVE = 20261002
N_GENERATIF = int(os.environ.get("VF_GEN_N", "2000"))


def payload_brut(outil, chemin_json, cwd, cle="file_path"):
    """Payload dont la clé de chemin vaut le littéral JSON `chemin_json` (déjà échappé, sans guillemets) : permet d'écrire un nom sous une
    forme que json.dumps ne produit jamais (`\\u002eplanning`)."""
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "prompt_id": "prompt-test",
           "permission_mode": "default", "hook_event_name": "PreToolUse", "tool_name": outil,
           "tool_input": {cle: "@@F@@", "content": "x"}, "tool_use_id": "toolu_test"}
    texte = json.dumps(obj, separators=(",", ":"), ensure_ascii=True)
    return texte.replace('"@@F@@"', '"' + chemin_json + '"', 1).encode("ascii")


def json_litteral(texte):
    """Contenu d'une chaîne JSON (sans les guillemets) pour `texte`."""
    return json.dumps(texte, ensure_ascii=True)[1:-1]


def nom_sous_forme(rng, nom):
    """`nom` dont chaque caractère est pris au hasard sous sa forme littérale, littérale de casse inversée, `\\uXXXX` en minuscules ou
    `\\uXXXX` en majuscules (échappement JSON)."""
    sortie = []
    for c in nom:
        forme = rng.randrange(4)
        if forme == 0:
            sortie.append(c)
        elif forme == 1:
            sortie.append(c.swapcase())
        elif forme == 2:
            sortie.append("\\u%04x" % ord(c))
        else:
            sortie.append("\\u%04X" % ord(c))
    return "".join(sortie)


def rembourrage(rng):
    """Rembourrage (> 4096 caractères) de forme variée : `./`, `a/../`, descente puis remontée, composants longs."""
    forme = rng.randrange(4)
    if forme == 0:
        return "./" * rng.randrange(2100, 3000)
    if forme == 1:
        return "a/../" * rng.randrange(900, 1200)
    if forme == 2:
        n = rng.randrange(1100, 1500)
        return "a/" * n + "../" * n
    return ("x" * rng.randrange(200, 400) + "/") * rng.randrange(25, 35)  # au moins 25 × 201 = 5025 caractères


def valeur_generative(rng, avec_nom, bases, noms=(".planning", ".claude"), restes=("/STATE.md", "/scripts/x.sh", "/cycles/01-c/notes.md", "")):
    """Littéral JSON d'une valeur longue : base, rembourrage, puis (avec_nom) le nom sous une forme tirée au hasard, en milieu (suivi
    d'un reste) ou en fin de valeur. Sans nom : aucun `.planning`, aucun `.claude`, aucun antislash."""
    base = rng.choice(bases)
    pad = rembourrage(rng)
    reste = rng.choice(restes)
    if avec_nom:
        nom = nom_sous_forme(rng, rng.choice(noms))
        return json_litteral(base + "/" + pad) + nom + json_litteral(reste)
    return json_litteral(base + "/" + pad + "n" + reste + "/f.md")


def controle_generatif(ctx, texte, adh, hors, n=None, graine=GRAINE_GENERATIVE):
    """Preuve générative de la classe : `n` valeurs longues qui nomment `.planning` ou `.claude` sous une forme tirée au hasard.
    La couche de repli seule (script absent) les REFUSE toutes, cwd non adhérent ou adhérent. La commande complète (cœur livré présent)
    les lit sous deux formes (N3-01) : une valeur qui reste plus longue que la borne une fois réduite lexicalement est REFUSÉE sur son
    nom ; une valeur qui se réduit sous la borne reçoit EXACTEMENT le verdict de son JUMEAU COURT (la valeur réduite, rejouée telle quelle)
    — refusée si le jumeau l'est, silencieuse sinon (le faux refus de 079e905f sur un lab non adhérent est levé, c'est le but). Des valeurs
    longues qui ne nomment rien, sans antislash, en cwd non adhérent, restent silencieuses (GATE-03). Rend (conforme, détail, stats)."""
    n = N_GENERATIF if n is None else n
    rng = random.Random(graine)
    bases = [adh, hors, "/tmp/zz", ""]
    cas = []
    for _ in range(n):
        cas.append(("nom", valeur_generative(rng, True, bases), rng.choice((hors, adh)), rng.choice(("Write", "Edit", "NotebookEdit"))))
    for _ in range(max(1, n // 4)):  # N3-01 : valeurs qui visent `.planning/STATE.md` d'un lab ADHÉRENT sous une orthographe tirée au hasard
        cas.append(("nom", valeur_generative(rng, True, [adh], noms=(".planning",), restes=("/STATE.md",)), rng.choice((hors, adh)),
                    rng.choice(("Write", "Edit", "NotebookEdit"))))
    for _ in range(max(1, n // 4)):
        cas.append(("temoin", valeur_generative(rng, False, [hors]), hors, rng.choice(("Write", "Edit", "NotebookEdit"))))
    stats = {"graine": graine, "n": n, "deny_complet": 0, "deny_repli": 0, "temoins": 0, "temoins_pass": 0, "t_max": 0.0,
             "irreductibles": 0, "reductibles": 0, "jumeaux_egaux": 0, "jumeaux_refuses": 0}
    fautes = []

    def jouer(c):
        genre, v, cwd, outil = c
        cle = "notebook_path" if outil == "NotebookEdit" else "file_path"
        brut = payload_brut(outil, v, cwd, cle)
        t_c, extra_c = ctx.preparer(ctx.scripts_dir_livre, texte)
        rc1, out1, err1, dt1 = ctx.rejouer(t_c, brut, ctx.env_mode("A", extra_c), cwd)
        rc2, out2, err2, dt2 = rejouer_texte_t(ctx, texte, "C", brut, cwd)
        jumeau = None  # (verdict du jumeau court, stderr) ; None si la valeur reste trop longue une fois réduite
        reduit = posixpath.normpath(json.loads('"' + v + '"'))
        if genre == "nom" and len(reduit) <= 4096:
            rc3, out3, err3, dt3 = ctx.rejouer(t_c, payload_brut(outil, json_litteral(reduit), cwd, cle), ctx.env_mode("A", extra_c), cwd)
            jumeau = (verdict(rc3, out3), err3)
        return (c, verdict(rc1, out1), err1, dt1, verdict(rc2, out2), err2, dt2, jumeau)

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        for c, v1, e1, d1, v2, e2, d2, jumeau in ex.map(jouer, cas):
            stats["t_max"] = max(stats["t_max"], d1, d2)
            if c[0] == "nom":
                stats["deny_complet"] += int(v1 == "deny" and not e1)
                stats["deny_repli"] += int(v2 == "deny" and not e2)
                attendu = "deny"
                if jumeau is None:
                    stats["irreductibles"] += 1
                else:
                    stats["reductibles"] += 1
                    attendu = jumeau[0]
                    stats["jumeaux_refuses"] += int(attendu == "deny")
                    stats["jumeaux_egaux"] += int(v1 == attendu and not jumeau[1])
                if v1 != attendu or e1 or v2 != "deny" or e2:
                    fautes.append("valeur …%s cwd=%s : complet=%s (attendu %s) repli=%s" % (c[1][-60:], "adh" if c[2] == adh else "hors", v1, attendu, v2))
            else:
                stats["temoins"] += 1
                stats["temoins_pass"] += int(v1 == "silence" and v2 == "silence" and not e1 and not e2)
                if v1 != "silence" or v2 != "silence" or e1 or e2:
                    fautes.append("témoin …%s : complet=%s repli=%s (attendu silence)" % (c[1][-40:], v1, v2))
    if stats["t_max"] >= PLAFOND_DECISION_S:
        fautes.append("temps maximal %.2f s (plafond %.0f s)" % (stats["t_max"], PLAFOND_DECISION_S))
    if stats["irreductibles"] == 0 or stats["jumeaux_refuses"] < n // 10:  # garde contre un vert à vide : les deux familles doivent être exercées
        fautes.append("preuve creuse : %d irréductibles, %d jumeaux refusés (attendu au moins 1 et %d)" % (stats["irreductibles"], stats["jumeaux_refuses"], n // 10))
    detail = ("%d valeurs (graine %d) : repli %d/%d refusées ; complet : %d irréductibles refusées sur leur nom, %d réductibles dont %d refusées, "
              "verdict égal à celui du jumeau court %d/%d ; témoins PASS %d/%d, t_max %.2f s"
              % (n + max(1, n // 4), graine, stats["deny_repli"], n + max(1, n // 4), stats["irreductibles"], stats["reductibles"], stats["jumeaux_refuses"],
                 stats["jumeaux_egaux"], stats["reductibles"], stats["temoins_pass"], stats["temoins"], stats["t_max"]))
    return (not fautes), ("; ".join(fautes[:3]) + " | " + detail if fautes else detail), stats


def chemin_aller_retour(base, n, nom):
    """`base/` + `a/` × n + `../` × n + nom : descend puis remonte (la sonde N=130000 du ré-auditeur à n = 130000)."""
    return base + "/" + "a/" * n + "../" * n + nom


def controle_sonde_n(ctx, texte, adh, hors, n=130000):
    """La sonde du ré-auditeur (~520 Ko) : `.planning/STATE.md` puis `.claude/scripts/planning-hook.sh`, cwd non adhérent."""
    fautes = []
    pire = 0.0
    for nom in (".planning/STATE.md", ".claude/scripts/planning-hook.sh"):
        brut = payload("Write", {"file_path": chemin_aller_retour(adh, n, nom), "content": "x"}, hors)
        t_c, extra_c = ctx.preparer(ctx.scripts_dir_livre, texte)
        rc, out, err, dt = ctx.rejouer(t_c, brut, ctx.env_mode("A", extra_c), hors)
        pire = max(pire, dt)
        if verdict(rc, out) != "deny" or err or dt >= PLAFOND_DECISION_S:
            fautes.append("%s : %s en %.2f s stderr=%s (attendu deny, < %.0f s)" % (nom, verdict(rc, out), dt, court(err), PLAFOND_DECISION_S))
    return (not fautes), ("; ".join(fautes) if fautes else "sonde N=%d (nom en fin, cwd non adhérent) : deny des deux noms, pire temps %.2f s" % (n, pire))


def controle_doute_shell(ctx, texte, adh, hors, lab_home):
    """Rend (conforme, détail) : la couche shell seule (mode C, script absent)."""
    fautes = []
    n = [0]

    def jouer(etiquette, brut, cwd, attendu, libelle=None):
        n[0] += 1
        rc, out, err, dt = rejouer_texte_t(ctx, texte, "C", brut, cwd)
        v = verdict(rc, out)
        if v != attendu or err:
            fautes.append("%s : %s stderr=%s (attendu %s)" % (etiquette, v, court(err), attendu))
            return
        if attendu == "deny":
            raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
            if libelle is not None and libelle not in raison:
                fautes.append("%s : libellé %r (attendu %r)" % (etiquette, raison[:220], libelle))

    nomme = "il nomme .planning ou .claude"

    def ecrit(chemin, cwd, outil="Write"):
        return payload(outil, entree_outil(outil, chemin), cwd)

    jouer("N-01 chemin trop long qui nomme .planning, cwd non adhérent", ecrit(hors + "/" + LONG_BORNE + ".planning/STATE.md", hors), hors, "deny", nomme)
    jouer("N-01 chemin trop long qui nomme .CLAUDE (casse), cwd non adhérent", ecrit(hors + "/" + LONG_BORNE + ".CLAUDE/scripts/x.sh", hors), hors, "deny", nomme)
    jouer("N-01 chemin relatif trop long qui nomme .claude, cwd non adhérent", ecrit(LONG_BORNE + ".claude/x.sh", hors, "Edit"), hors, "deny", nomme)
    jouer("N-01 chemin trop long avec échappement `\\ud800` et `..` (sonde r3 de l'audit), cwd non adhérent",
          payload_ascii("Write", {"file_path": adh + "/\ud800/../" + LONG_BORNE + ".planning/STATE.md", "content": "x"}, hors), hors, "deny", nomme)
    jouer("N-01 chemin trop long qui ne nomme ni l'un ni l'autre : silence hors lab adhérent (GATE-03)", ecrit(hors + "/" + LONG_BORNE + "x.md", hors), hors, "silence")
    # N2-01 : le nom écrit sous une forme échappée (la couche de repli ne décode pas le JSON) ; descente puis remontée ; tout cwd
    nomme_esc = "il nomme .planning ou .claude, ou porte un echappement JSON"
    long_p = json_litteral(adh + "/" + LONG_BORNE)
    jouer("N2-01 `\\u002eplanning` dans une valeur trop longue, cwd non adhérent",
          payload_brut("Write", long_p + "\\u002eplanning/STATE.md", hors), hors, "deny", nomme_esc)
    jouer("N2-01 `.pl\\u0061nning` (une seule lettre échappée), cwd non adhérent",
          payload_brut("Write", long_p + ".pl\\u0061nning/STATE.md", hors), hors, "deny", nomme_esc)
    jouer("N2-01 `\\u002eclaude` en fin de valeur, cwd non adhérent",
          payload_brut("Edit", long_p + "\\u002eclaude", hors), hors, "deny", nomme_esc)
    jouer("N2-01 `\\u002E` PLANNING majuscules échappées, cwd ADHÉRENT",
          payload_brut("Write", long_p + "\\u002E\\u0050LANNING/x.md", adh), adh, "deny", nomme_esc)
    jouer("N2-01 un antislash seul (`\\/`) dans une valeur trop longue sans nom, cwd non adhérent : refusé",
          payload_brut("Write", json_litteral(hors + "/" + LONG_BORNE) + "\\/x.md", hors), hors, "deny", nomme_esc)
    jouer("N2-01 descente puis remontée (130 000 composantes) vers un lab adhérent, nom échappé, cwd non adhérent",
          payload_brut("Write", json_litteral(adh + "/" + "a/" * 130000 + "../" * 130000) + "\\u002eplanning/STATE.md", hors), hors, "deny", nomme_esc)
    jouer("N2-01 GATE-03 : valeur trop longue sans nom ni antislash, cwd non adhérent : silence",
          payload_brut("Write", json_litteral(hors + "/" + LONG_BORNE + "x.md"), hors), hors, "silence")
    # N-03 : `~` développé en HOME, jamais joint au cwd
    jouer("N-03 `~/<lab>/.planning/STATE.md`, cwd non adhérent : lu sous HOME, adhérent", ecrit("~/" + lab_home + "/.planning/STATE.md", hors), hors, "deny",
          "dans un lab adherent cycles-v1")
    jouer("N-03 `~/<lab>/.planning/STATE.md`, cwd adhérent", ecrit("~/" + lab_home + "/.planning/STATE.md", adh, "Edit"), adh, "deny",
          "dans un lab adherent cycles-v1")
    jouer("N-03 `~/x.md` sous HOME, hors de tout lab adhérent : silence (GATE-03)", ecrit("~/x.md", hors), hors, "silence")
    jouer("N-03 `~/x.md` sous HOME hors lab, cwd ADHÉRENT : silence (jamais joint au cwd)", ecrit("~/x.md", adh), adh, "silence")
    jouer("N-03 `~utilisateur/…` : non analysable, refusé dans le doute", ecrit("~bob/x.md", hors), hors, "deny", "chemin non analysable")
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d rejeux : valeur trop longue refusée si elle nomme .planning ou .claude (casse ignorée, échappement, tout cwd), silence sinon ; `~` développé en HOME, `~utilisateur` refusé"
                          % n[0])


def controle_doute_coeur(ctx, adh, hors, lab_home):
    """Rend (conforme, détail) : le cœur LIVRÉ lancé directement, rc 0 attendu partout (jamais le code 3)."""
    fautes = []
    n = [0]

    def jouer(etiquette, brut, cwd, attendu):
        n[0] += 1
        v, rc, out, err = verdict_direct(ctx, brut, cwd)
        if v != attendu or rc != 0 or err:
            fautes.append("%s : %s rc=%d stderr=%s (attendu %s, rc 0)" % (etiquette, v, rc, court(err), attendu))

    def e(chemin, cwd, outil="Write"):
        return payload_ascii(outil, entree_outil(outil, chemin), cwd)

    jouer("surrogate isolé, nomme .planning, cwd non adhérent", e(adh + "/\ud800/.planning/STATE.md", hors), hors, "deny")
    jouer("NUL, nomme .claude, cwd non adhérent", e(adh + "/\x00/.claude/scripts/x.sh", hors), hors, "deny")
    jouer("NUL, nomme .PLANNING (casse), cwd non adhérent", e(adh + "/\x00/.PLANNING/x.md", hors, "Edit"), hors, "deny")
    jouer("surrogate isolé, ne nomme rien, cwd non adhérent : silence (GATE-03)", e(hors + "/\ud800/x.md", hors), hors, "silence")
    jouer("NUL, ne nomme rien, cwd non adhérent : silence (GATE-03)", e(hors + "/\x00/x.md", hors), hors, "silence")
    jouer("NUL, ne nomme rien, cwd adhérent : refusé dans le doute", e(adh + "/\x00/x.md", adh), adh, "deny")
    jouer("surrogate isolé dans un chemin RELATIF qui nomme .planning, cwd non adhérent", e("\ud800/.planning/STATE.md", hors), hors, "deny")
    jouer("`~utilisateur/…` qui nomme .planning, cwd non adhérent", e("~bob/.planning/STATE.md", hors), hors, "deny")
    jouer("`~utilisateur/…` qui ne nomme rien, cwd non adhérent : silence", e("~bob/x.md", hors), hors, "silence")
    jouer("`~/<lab>/.planning/STATE.md`, cwd non adhérent portant un dossier littéral `~` : lu sous HOME", e("~/" + lab_home + "/.planning/STATE.md", hors), hors, "deny")
    jouer("`~/x.md` sous HOME hors lab, cwd non adhérent : silence", e("~/x.md", hors), hors, "silence")
    jouer("`~/x.md` sous HOME hors lab, cwd ADHÉRENT : silence (jamais joint au cwd)", e("~/x.md", adh), adh, "silence")
    jouer("cwd inanalysable (surrogate), chemin qui ne nomme rien : refusé dans le doute", e(hors + "/\ud800/x.md", hors + "/\ud800"), hors, "deny")
    # N2-01 puis N3-01 (re-audit 3 du 2026-10-02) : une valeur longue est LUE SOUS DEUX FORMES en temps linéaire (réduite lexicalement,
    # physique). Chacune qui tient sous la borne est analysée comme une valeur courte (exacte) ; seule une valeur qui RESTE trop longue est
    # jugée dans le doute (son nom décodé, puis le lab de son cwd et de ses ancêtres existants). Le chemin qui descend puis remonte vers un
    # lab NON adhérent se réduit à `hors/.planning/…` : analysé, il est silencieux (GATE-03) ; 079e905f le refusait sur son seul nom (faux
    # refus levé, déclaré). La propriété du doute (« un nom d'actif gardé que le hook ne sait pas analyser refuse ») reste prouvée sur les
    # valeurs IRRÉDUCTIBLES (composantes qui ne se réduisent pas), cwd non adhérent.
    aller_retour = hors + "/" + "a/" * 2500 + "../" * 2500
    aller_retour_adh = adh + "/" + "a/" * 2500 + "../" * 2500
    irreductible = hors + "/" + ("x" * 300 + "/") * 20
    irreductible_adh = adh + "/" + ("x" * 300 + "/") * 20
    jouer("N2-01 valeur longue qui descend puis remonte vers un lab NON adhérent, nom `\\u002eplanning` échappé, cwd non adhérent : réduite, analysée, silence",
          payload_brut("Write", json_litteral(aller_retour) + "\\u002eplanning/STATE.md", hors), hors, "silence")
    jouer("N2-01 même chemin, nom `.claude` littéral, cwd non adhérent : réduite, analysée, silence", e(aller_retour + ".claude/scripts/x.sh", hors), hors, "silence")
    jouer("N2-01 valeur longue RELATIVE qui nomme `.planning`, cwd non adhérent : réduite contre le cwd, analysée, silence",
          e("a/" * 2500 + "../" * 2500 + ".planning/x.md", hors), hors, "silence")
    jouer("N2-01 valeur longue en `notebook_path`, nom échappé, cwd non adhérent : réduite, analysée, silence",
          payload_brut("NotebookEdit", json_litteral(aller_retour) + "\\u002eclaude/x.ipynb", hors, "notebook_path"), hors, "silence")
    jouer("N2-01 valeur longue sans nom vers un lab non adhérent, cwd adhérent : réduite, analysée sur son lab réel, silence",
          e(aller_retour + "x.md", adh), adh, "silence")
    # La même descente puis remontée vers un lab ADHÉRENT : la forme réduite est analysée et refusée (le nom n'y est pour rien)
    jouer("N3-01 valeur longue qui descend puis remonte vers un lab adhérent, nom `\\u002eplanning` échappé, cwd non adhérent : refusée",
          payload_brut("Write", json_litteral(aller_retour_adh) + "\\u002eplanning/STATE.md", hors), hors, "deny")
    jouer("N3-01 même chemin, nom `.claude` littéral (script gardé), cwd non adhérent : refusée", e(aller_retour_adh + ".claude/scripts/planning-hook.sh", hors), hors, "deny")
    # Les valeurs IRRÉDUCTIBLES (plus longues que la borne après réduction) : décision dans le doute, comme avant
    jouer("N2-01 valeur IRRÉDUCTIBLE, nom `\\u002eplanning` échappé, cwd non adhérent : refusée sur son nom décodé",
          payload_brut("Write", json_litteral(irreductible) + "\\u002eplanning/STATE.md", hors), hors, "deny")
    jouer("N2-01 valeur IRRÉDUCTIBLE, nom `.claude` littéral, cwd non adhérent : refusée sur son nom", e(irreductible + ".claude/scripts/x.sh", hors), hors, "deny")
    jouer("N2-01 valeur IRRÉDUCTIBLE RELATIVE qui nomme `.planning`, cwd non adhérent : refusée sur son nom",
          e(("x" * 300 + "/") * 20 + ".planning/x.md", hors), hors, "deny")
    jouer("N2-01 valeur IRRÉDUCTIBLE en `notebook_path`, nom échappé, cwd non adhérent : refusée sur son nom",
          payload_brut("NotebookEdit", json_litteral(irreductible) + "\\u002eclaude/x.ipynb", hors, "notebook_path"), hors, "deny")
    jouer("N2-01 valeur IRRÉDUCTIBLE sans nom, cwd non adhérent, ancêtres hors lab adhérent : silence (GATE-03)", e(irreductible + "x.md", hors), hors, "silence")
    jouer("N2-01 valeur IRRÉDUCTIBLE sans nom, cwd adhérent : refusée dans le doute", e(irreductible + "x.md", adh), adh, "deny")
    jouer("N3-01 valeur IRRÉDUCTIBLE sans nom sous un lab ADHÉRENT (son ancêtre existant), cwd non adhérent : refusée dans le doute",
          e(irreductible_adh + "x.md", hors), hors, "deny")
    jouer("N2-01 cwd du payload plus long que la borne, chemin court, processus hors lab : silence (GATE-03)",
          payload("Write", {"file_path": "x.md", "content": "x"}, hors + "/" + "a/" * 2500 + "../" * 2500), hors, "silence")
    # N3-02 : un chemin RELATIF sous un cwd de plus de 4096 caractères n'est jamais résolu contre le cwd du processus
    cwd_long_hors = hors + "/" + "a/../" * 1100
    cwd_long_adh = adh + "/" + "a/../" * 1100
    jouer("N3-02 chemin relatif qui nomme `.planning`, cwd trop long (se réduit à un lab non adhérent) : refusé dans le doute, sur son nom",
          e(".planning/x.md", cwd_long_hors), hors, "deny")
    jouer("N3-02 chemin relatif sans nom, cwd trop long qui se réduit à un lab ADHÉRENT, processus hors lab : refusé (cwd lu réduit)",
          e("x.md", cwd_long_adh), hors, "deny")
    jouer("N3-02 chemin relatif sans nom, cwd trop long qui se réduit à un lab non adhérent : silence (GATE-03)", e("x.md", cwd_long_hors), hors, "silence")
    jouer("N3-02 chemin relatif sans nom, cwd IRRÉDUCTIBLE (reste trop long) : refusé dans le doute",
          e("x.md", hors + "/" + ("c" * 300 + "/") * 20), hors, "deny")
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d rejeux du cœur seul, toujours rc 0 : chemin inanalysable refusé s'il nomme .planning ou .claude, sinon décision sur le cwd ; `~` développé en HOME" % n[0])


def labs_reduction(ctx, nom):
    """(lab adhérent, lab non adhérent) avec un lien dur vers STATE.md, un lien symbolique vers `.planning`, un lien vers un sous-dossier
    gardé (`cyc`), un lien vers un dossier hors lab (`ext`), une boucle de liens (`loop`) et la définition d'un juge."""
    base = ctx.unique(nom)
    adh = fabriquer_lab(os.path.join(base, "adh"), True)
    hors = fabriquer_lab(os.path.join(base, "hors"), False)
    dehors = os.path.join(base, "dehors", "deep")
    os.makedirs(dehors, exist_ok=True)
    ecrire(os.path.join(adh, ".planning", "STATE.md"), "x\n")
    ecrire(os.path.join(adh, "src", "a.py"), "x\n")
    ecrire(os.path.join(adh, ".claude", "agents", "vf-judge.md"), "---\nname: vf-judge\ndescription: juge\ndisallowedTools: Write, Edit\n---\ncorps\n")
    os.link(os.path.join(adh, ".planning", "STATE.md"), os.path.join(adh, "src", "hl.md"))
    os.symlink(".planning", os.path.join(adh, "pl"))
    os.symlink("../.planning/cycles", os.path.join(adh, "src", "cyc"))
    os.symlink("../.planning", os.path.join(adh, "src", "plink"))
    os.symlink(dehors, os.path.join(adh, "src", "ext"))
    os.symlink("loop", os.path.join(adh, "src", "loop"))
    return adh, hors


def controle_reduction(ctx, adh, hors):
    """N3-01 (re-audit 3 du 2026-10-02) : cœur LIVRÉ lancé directement. Une valeur de plus de 4096 caractères qui se réduit (lexicalement ou
    physiquement) vers un actif gardé d'un lab adhérent est REFUSÉE par l'analyse exacte, quel que soit le cwd : lien dur, lien
    symbolique, écriture d'un juge, `..` après un lien symbolique dans les DEUX sens (F2 : le sens lexical, que seule la forme réduite
    voit, et le sens physique, que seule la forme physique voit) ; la même valeur vers un lab non adhérent reste silencieuse (GATE-03)
    ; une boucle de liens a le verdict de son jumeau court ; la sonde de 130 000 composantes est tranchée en moins de 2 s. Rend
    (conforme, détail)."""
    fautes = []
    n = [0]
    pire = [0.0]
    src = adh + "/src/"

    def lancer(brut, cwd):
        t0 = time.monotonic()
        v, rc, out, err = verdict_direct(ctx, brut, cwd)
        dt = time.monotonic() - t0
        pire[0] = max(pire[0], dt)
        return v, rc, err, dt

    def jouer(etiquette, brut, cwd, attendu):
        n[0] += 1
        v, rc, err, dt = lancer(brut, cwd)
        if v != attendu or rc != 0 or err or dt >= PLAFOND_DECISION_S:
            fautes.append("%s : %s rc=%d stderr=%s en %.2f s (attendu %s, rc 0, moins de %.0f s)" % (etiquette, v, rc, court(err), dt, attendu, PLAFOND_DECISION_S))

    def jumeau(etiquette, long_brut, court_brut, cwd):
        n[0] += 1
        v, rc, err, dt = lancer(long_brut, cwd)
        vc, rcc, errc, _dt = lancer(court_brut, cwd)
        if v != vc or rc != 0 or err or dt >= PLAFOND_DECISION_S:
            fautes.append("%s : long=%s rc=%d stderr=%s en %.2f s, jumeau court=%s (attendu le même verdict, rc 0)" % (etiquette, v, rc, court(err), dt, vc))

    def e(chemin, cwd, outil="Write", **kw):
        return payload(outil, entree_outil(outil, chemin), cwd, **kw)

    pad = "./" * 2100                    # 4 200 caractères
    jouer("N3-01 lien dur vers STATE.md derrière 4 200 barres obliques, cwd non adhérent", e(adh + "/src" + "/" * 4200 + "hl.md", hors), hors, "deny")
    jouer("N3-01 lien symbolique `pl` -> .planning derrière une descente puis remontée de 4 200 composantes, cwd non adhérent",
          e(adh + "/" + "a/" * 2100 + "../" * 2100 + "pl/STATE.md", hors), hors, "deny")
    jouer("N3-01 lien symbolique `plink` -> ../.planning sous src/, cwd adhérent", e(src + pad + "plink/STATE.md", adh), adh, "deny")
    jouer("N3-01 écriture d'un juge vers src/a.py derrière 2 100 `./`, cwd non adhérent", e(src + pad + "a.py", hors, agent_type="vf-judge"), hors, "deny")
    jouer("N3-01 F2 sens physique : `cyc/..` (lien vers un sous-dossier gardé) remonte dans `.planning`, cwd non adhérent",
          e(src + pad + "cyc/../STATE.md", hors), hors, "deny")
    jouer("N3-01 F2 sens lexical : `ext/../..` (lien vers un dossier hors lab) se réduit à `.planning/STATE.md`, cwd non adhérent",
          e(src + pad + "ext/../../.planning/STATE.md", hors), hors, "deny")
    jouer("N3-01 valeur longue réductible vers un livrable que le plan déclare, lab ADHÉRENT : analysée (exacte), silence ; jamais le doute",
          e(adh + "/" + "a/../" * 1100 + "livrable.md", hors), hors, "silence")
    jouer("N3-01 la même valeur vers un lab NON adhérent : silence (GATE-03)", e(hors + "/" + "a/../" * 1100 + "x.md", hors), hors, "silence")
    jouer("N3-01 `.planning/STATE.md` d'un lab non adhérent derrière 4 200 `./` : silence (faux refus de 079e905f levé)",
          e(hors + "/" + pad + ".planning/STATE.md", hors), hors, "silence")
    jumeau("N3-01 boucle de liens symboliques derrière 4 200 `./` : le verdict de son jumeau court", e(src + pad + "loop/x.md", hors), e(src + "loop/x.md", hors), hors)
    jouer("N3-01 sonde de 130 000 composantes vers un lien dur, cwd non adhérent", e(src + "a/" * 130000 + "../" * 130000 + "hl.md", hors), hors, "deny")
    jouer("N3-01 sonde de 130 000 composantes vers un lien symbolique, cwd adhérent", e(adh + "/" + "a/" * 130000 + "../" * 130000 + "pl/STATE.md", adh), adh, "deny")
    return (not fautes), ("; ".join(fautes) if fautes else
                          "%d rejeux du cœur seul : lien dur, lien symbolique, juge et `..` sous un lien (deux sens) refusés derrière un rembourrage long, lab non adhérent silencieux, boucle de liens égale à son jumeau, sonde de 130 000 composantes, pire temps %.2f s (plafond %.0f s)"
                          % (n[0], pire[0], PLAFOND_DECISION_S))


def sec_doute(ctx):
    adh, hors, lab_home = labs_doute(ctx, "doute")
    o = controle_doute_shell(ctx, ctx.cmd_np, adh, hors, lab_home)
    if o[0]:
        ok("R-DOUTE-01 " + o[1] + " · commande SANS pré-filtre")
    else:
        ko("R-DOUTE-01", "couche shell : valeur trop longue qui nomme un actif gardé refusée, `~` développé en HOME", "conforme", o[1])
    o_c = controle_doute_shell(ctx, ctx.cmd, adh, hors, lab_home)
    if o_c[0]:
        ok("R-DOUTE-05 " + o_c[1] + " · commande COMPLÈTE (pré-filtre)")
    else:
        ko("R-DOUTE-05", "mêmes verdicts avec le pré-filtre : valeur longue, `~`, échappement, jamais court-circuités", "conforme", o_c[1])
    c = controle_doute_coeur(ctx, adh, hors, lab_home)
    if c[0]:
        ok("R-DOUTE-02 " + c[1])
    else:
        ko("R-DOUTE-02", "cœur : chemin inanalysable décidé dans le doute, jamais le code 3, `~` développé en HOME", "conforme", c[1])
    g = controle_generatif(ctx, ctx.cmd, adh, hors)
    if g[0]:
        ok("R-DOUTE-03 " + g[1])
    else:
        ko("R-DOUTE-03", "preuve générative : toute valeur longue qui nomme .planning ou .claude, sous n'importe quelle orthographe, est refusée (commande complète ET repli seul, moins de %.0f s), les témoins restent silencieux" % PLAFOND_DECISION_S,
           "conforme", g[1])
    sonde = controle_sonde_n(ctx, ctx.cmd, adh, hors)
    if sonde[0]:
        ok("R-DOUTE-04 " + sonde[1])
    else:
        ko("R-DOUTE-04", "sonde du ré-auditeur (N=130000) : deny en moins de %.0f s" % PLAFOND_DECISION_S, "conforme", sonde[1])
    adh_r, hors_r = labs_reduction(ctx, "reduction")
    r = controle_reduction(ctx, adh_r, hors_r)
    if r[0]:
        ok("R-REDUC-01 " + r[1])
    else:
        ko("R-REDUC-01", "valeur longue réductible vers un actif gardé : refusée par l'analyse exacte (lien dur, lien symbolique, juge, `..` sous un lien dans les deux sens), lab non adhérent silencieux, sonde de 130 000 composantes", "conforme", r[1])
    for ident, motif, remplacement in (
            ("DOUTE-GUARD-RETIRE", "grep -a -q -i -E '[.](planning|claude)|[\\\\]' && G=1;", ":;"),
            ("DOUTE-GUARD-CLAUDE", "[.](planning|claude)|", "[.](planning)|"),
            ("DOUTE-GUARD-CASSE", "grep -a -q -i -E '[.](planning|claude)|", "grep -a -q -E '[.](planning|claude)|"),
            ("DOUTE-GUARD-ANTISLASH", "(planning|claude)|[\\\\]'", "(planning|claude)'"),
            ("DOUTE-GUARD-NOM", "'[.](planning|claude)|[\\\\]'", "'[\\\\]'"),
            ("DOUTE-TILDE-SHELL", "'~'|'~/'*) _h=${HOME%/}; case $_h in /*) P=$_h${P#'~'} ;; *) PX=0 ;; esac ;; '~'*) PX=0 ;; *) if vf_get cwd", "*) if vf_get cwd"),
            ("DOUTE-TILDE-USER", " '~'*) PX=0 ;; *) if vf_get cwd", " *) if vf_get cwd")):
        muté, raison = make_cmd_mutant(ctx, ident, motif, remplacement)
        if muté is None:
            komut(ident, "texte muté distinct de l'original et sh -n réussit", "mutant valide", raison)
            continue
        m = controle_doute_shell(ctx, muté, adh, hors, lab_home)
        if not o[0]:
            komut(ident, "l'original passe R-DOUTE-01", "conforme", o[1])
        elif m[0]:
            komut(ident, "R-DOUTE-01 rougit sous le mutant", "rouge", "vert : " + m[1] + " (mutant non opposable)")
        else:
            okmut(ident, "R-DOUTE-01 rougit · attendu (original) : %s · obtenu (mutant) : %s" % (o[1], m[1][:300]))
    for ident, motif, remplacement in (
            ("DOUTE-COEUR-REVERT", 'decide = decider_dans_le_doute(payload, getattr(exc_doute, "ancetres", ()))', "decide = None"),
            ("DOUTE-COEUR-AIGUILLAGE", "if len(ecrit) > BORNE_VALEUR or len(physique) > BORNE_VALEUR:  # aiguillage-longue", "if False:  # aiguillage-longue"),
            ("DOUTE-COEUR-NOMME", "if nomme_un_actif_garde(brut):  # doute-nomme", "if False:  # doute-nomme"),
            ("DOUTE-COEUR-CLAUDE", 'return ".planning" in bas or ".claude" in bas  # nomme-actif-garde', 'return ".planning" in bas  # nomme-actif-garde'),
            ("DOUTE-COEUR-ADHESION", "# doute-adhesion", "adherent = False  # doute-adhesion"),
            ("DOUTE-COEUR-CWD", "adherent = True  # doute-cwd", "adherent = False  # doute-cwd"),
            ("DOUTE-COEUR-TILDE", 'if (ecrit == "~" or ecrit.startswith("~/")) and isinstance(home, str) and home.startswith("/"):', "if False:"),
            ("DOUTE-COEUR-CWD-LONG", "if cwd_long:  # cwd-long", "if False:  # cwd-long"),
            ("DOUTE-COEUR-CWD-REDUIT", "cwd = reduire_lexicalement(cwd)  # doute-cwd-reduit", "pass  # doute-cwd-reduit"),
            ("DOUTE-COEUR-ANCETRES", "for lieu in [cwd] + list(ancetres):  # doute-ancetres", "for lieu in [cwd]:  # doute-ancetres")):
        dossier, raison = make_hook_mutant(ctx, ident, motif, remplacement)
        if dossier is None:
            komut(ident, "mutant du cœur (bash -n et compilation du corps)", "mutant valide", raison)
            continue
        sauve = ctx.scripts_dir_livre
        ctx.scripts_dir_livre = dossier
        try:
            m = controle_doute_coeur(ctx, adh, hors, lab_home)
        finally:
            ctx.scripts_dir_livre = sauve
        if not c[0]:
            komut(ident, "l'original passe R-DOUTE-02", "conforme", c[1])
        elif m[0]:
            komut(ident, "R-DOUTE-02 rougit sous le mutant", "rouge", "vert : " + m[1] + " (mutant non opposable)")
        else:
            okmut(ident, "R-DOUTE-02 rougit · attendu (original) : %s · obtenu (mutant) : %s" % (c[1], m[1][:300]))
    for ident, motif, remplacement in (
            ("REDUC-LEXICALE", "ecrit = reduire_lexicalement(joint)  # reduction-lexicale", "ecrit = joint  # reduction-lexicale"),
            ("REDUC-PHYSIQUE", "variantes.append(physique)  # variante-physique", "pass  # variante-physique"),
            ("REDUC-LIEN", "if not est_lien or liens > BORNE_LIENS:  # lien-suivi", "if True:  # lien-suivi"),
            ("REDUC-BORNE-LIENS", "if not est_lien or liens > BORNE_LIENS:  # lien-suivi", "if not est_lien:  # lien-suivi")):
        dossier, raison = make_hook_mutant(ctx, ident, motif, remplacement)
        if dossier is None:
            komut(ident, "mutant du cœur (bash -n et compilation du corps)", "mutant valide", raison)
            continue
        sauve = ctx.scripts_dir_livre
        ctx.scripts_dir_livre = dossier
        try:
            m = controle_reduction(ctx, adh_r, hors_r)
        finally:
            ctx.scripts_dir_livre = sauve
        if not r[0]:
            komut(ident, "l'original passe R-REDUC-01", "conforme", r[1])
        elif m[0]:
            komut(ident, "R-REDUC-01 rougit sous le mutant", "rouge", "vert : " + m[1] + " (mutant non opposable)")
        else:
            okmut(ident, "R-REDUC-01 rougit · attendu (original) : %s · obtenu (mutant) : %s" % (r[1], m[1][:300]))


# -------------------------------------------------------------------------------------------------
# Payloads des cinq entrées, labs, sondes
# -------------------------------------------------------------------------------------------------
def payload_evt(evt, cwd, fichier=None, agent_type="agent-test", texte_fin="fin"):
    """Payload du harnais pour l'entrée `evt` (champs documentés, 46-RECHERCHE-HOOKS §2 et §3). SubagentHandback est un outil de
    PreToolUse (`tool_input.message`) ; SubagentStop porte `agent_id`, `agent_type`, `last_assistant_message`, `stop_hook_active` ;
    CwdChanged `old_cwd` et `new_cwd` ; FileChanged `file_path` et `event` de PREMIER niveau."""
    if evt == "SubagentHandback":
        return payload("SubagentHandback", {"message": "rapport du sous-agent"}, cwd, agent_type=agent_type)
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd}
    if evt == "SubagentStop":
        obj.update({"permission_mode": "default", "hook_event_name": "SubagentStop", "stop_hook_active": False, "agent_id": "agent-test",
                    "agent_type": agent_type, "agent_transcript_path": "sub.jsonl", "last_assistant_message": texte_fin})
    elif evt == "SessionStart":
        obj.update({"hook_event_name": "SessionStart", "source": "startup", "model": "modele-test"})
    elif evt == "CwdChanged":
        obj.update({"hook_event_name": "CwdChanged", "old_cwd": cwd, "new_cwd": cwd})
    elif evt == "FileChanged":
        obj.update({"hook_event_name": "FileChanged", "file_path": fichier, "event": "change"})
    else:
        raise KeyError(evt)
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def lire_lignes_sonde(xdg):
    """Nombre de lignes `gate=EVT` du journal d'observation du rejeu (XDG_CACHE_HOME jetable) : la sonde de la phase B."""
    chemin = os.path.join(xdg, "vibeflow", "gates-observation", "observation.log")
    try:
        with open(chemin, encoding="utf-8", errors="replace") as fh:
            texte = fh.read()
    except OSError:
        return 0
    return sum(1 for ligne in texte.split("\n") if "  gate=EVT  " in ligne)


def dossier_sonde_lancement(ctx):
    """Dossier dont planning-hook.sh ne fait QUE créer le fichier `$VF_SONDE_LANCE` : s'il existe, la commande a lancé le script."""
    d = ctx.unique("sonde-lancement")
    os.makedirs(d, exist_ok=True)
    chemin = os.path.join(d, "planning-hook.sh")
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write("#!/usr/bin/env bash\ncat >/dev/null\n: > \"$VF_SONDE_LANCE\"\nexit 0\n")
    os.chmod(chemin, 0o755)
    return d


def bin_python_factice(ctx):
    """Dossier dont `python3` ne fait que créer le fichier `$VF_SONDE_PY` : s'il existe, python3 a été lancé."""
    d = ctx.unique("bin-python-factice")
    os.makedirs(d, exist_ok=True)
    chemin = os.path.join(d, "python3")
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write("#!/bin/sh\n: > \"$VF_SONDE_PY\"\nexit 72\n")
    os.chmod(chemin, 0o755)
    return d


def sous_shell(ctx, nom, argv, texte, dossier_scripts, brut, cwd, extra_env=None):
    """La commande `texte` rejouée telle quelle sous le shell `nom` (zsh : `emulate sh`, comme les autres suites). Rend (code, stdout, stderr)."""
    t, extra = ctx.preparer(dossier_scripts, texte)
    extra = dict(extra)
    if extra_env:
        extra.update(extra_env)
    if nom == "zsh":
        t = "emulate sh\n" + t
    p = subprocess.run(argv + [t], input=brut, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env_mode("A", extra), cwd=cwd, timeout=120)
    return p.returncode, p.stdout, p.stderr


def fabriquer_sonde_coeur(ctx, ident, source=None, extras=()):
    """Copie SONDE du cœur : une ligne `gate=EVT` est écrite au journal d'observation (XDG_CACHE_HOME du rejeu) à l'entrée de la phase B,
    avant les gates en PreToolUse et avant le mode de l'événement sinon ; `extras` : remplacements supplémentaires (motif, remplacement),
    les mutants. Rend (dossier, None) ou (None, raison)."""
    paires = (("resultats = evaluer_gates(contexte)  # phase-b",
               'observer(Verdict("EVT", None, "sonde-" + str(contexte["outil"])), contexte); resultats = evaluer_gates(contexte)  # phase-b'),
              ("raisons = MODES_EVENEMENT[evenement](contexte)  # evt-phase-b",
               'observer(Verdict("EVT", None, "sonde-" + evenement), contexte); raisons = MODES_EVENEMENT[evenement](contexte)  # evt-phase-b')) + tuple(extras)
    courant = source
    dossier = None
    for i, (motif, remplacement) in enumerate(paires):
        dossier, raison = make_hook_mutant(ctx, "%s-%d" % (ident, i), motif, remplacement, source=courant)
        if dossier is None:
            return None, raison
        courant = os.path.join(dossier, "planning-hook.sh")
    return dossier, None


def verdict_conforme(rc, out, err, attendu="silence"):
    return rc == 0 and err == b"" and verdict(rc, out) == attendu


def mutant_controle(ident, original, mutant, nom_controle):
    """MUT-<ident> : le contrôle doit rougir sous le mutant ; la trace (assertion, attendu, obtenu) est la sortie du contrôle."""
    if not original[0]:
        komut(ident, "l'original passe " + nom_controle, "conforme", original[1])
    elif mutant[0]:
        komut(ident, nom_controle + " rougit sous le mutant", "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
    else:
        okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s" % (nom_controle, original[1], mutant[1][:400]))


# -------------------------------------------------------------------------------------------------
# R-EVT-01 : hors adhésion, octet vide et code 0 — AVANT le script, AVANT python3
# -------------------------------------------------------------------------------------------------
def controle_evt_01(ctx, texte, labs):
    """Pour chaque lab hors adhésion (lab dev fixture, ce dépôt) et chacune des cinq entrées (SubagentHandback, SubagentStop,
    SessionStart, CwdChanged, FileChanged) : sous chaque shell présent, stdout d'octet vide, stderr vide, code 0 ET le script du hook jamais
    lancé (sonde de lancement) ; avec le script réel et un python3 factice en tête du PATH, python3 jamais lancé ; en mode dégradé (script
    absent, python absent), le même silence. La commande est le seul objet que le contrôle fait varier (mutant : la même commande SANS pré-filtre)."""
    fautes = []
    n = [0]
    sonde = dossier_sonde_lancement(ctx)
    factice = bin_python_factice(ctx)
    chemin_path = factice + os.pathsep + os.environ.get("PATH", "/usr/bin:/bin")
    nb_shells = len(shells_presents())
    for lab_nom, racine, fichier in labs:
        for evt in CINQ_ENTREES:
            brut = payload_evt(evt, racine, fichier)
            etiquette = "%s, %s" % (evt, lab_nom)
            for nom, argv in shells_presents():
                marque = ctx.unique("marque-lancement")
                rc, out, err = sous_shell(ctx, nom, argv, texte, sonde, brut, racine, {"VF_SONDE_LANCE": marque})
                n[0] += 1
                if rc != 0 or out != b"" or err:
                    fautes.append("%s, shell %s : stdout 0 octet, stderr vide, code 0 (attendu) — obtenu rc=%d out=%s err=%s" % (etiquette, nom, rc, court(out), court(err)))
                if os.path.exists(marque):
                    fautes.append("%s, shell %s : le script du hook n'est PAS lancé hors adhésion (attendu : aucun lancement) — obtenu : le script a été lancé" % (etiquette, nom))
            marque = ctx.unique("marque-python")
            rc, out, err = sous_shell(ctx, "sh", ["/bin/sh", "-c"], texte, ctx.scripts_dir, brut, racine, {"PATH": chemin_path, "VF_SONDE_PY": marque})
            n[0] += 1
            if rc != 0 or out != b"" or err:
                fautes.append("%s, script réel : stdout 0 octet, code 0 (attendu) — obtenu rc=%d out=%s" % (etiquette, rc, court(out)))
            if os.path.exists(marque):
                fautes.append("%s : python3 n'est PAS lancé hors adhésion (attendu : aucun lancement) — obtenu : python3 a été lancé" % etiquette)
            for mode in ("C", "D"):
                rc, out, err, _ = rejouer_texte(ctx, texte, mode, brut, racine)
                n[0] += 1
                if rc != 0 or out != b"" or err:
                    fautes.append("%s, mode dégradé %s : silence, code 0 (attendu) — obtenu rc=%d out=%s" % (etiquette, mode, rc, court(out)))
    detail = ("%d rejeux (%d entrées × %d labs hors adhésion : %s) : stdout 0 octet, code 0 sous %d shells, script du hook jamais lancé, python3 jamais lancé "
              "(python3 factice), même silence en mode dégradé (script absent, python absent)"
              % (n[0], len(CINQ_ENTREES), len(labs), ", ".join(l[0] for l in labs), nb_shells))
    return (not fautes), ("; ".join(fautes[:3]) + (" (+%d autre(s))" % (len(fautes) - 3) if len(fautes) > 3 else "") if fautes else detail)


def controle_evt_01b(ctx, dossier_coeur, labs, adh):
    """La copie sonde du cœur, rejouée par la commande SANS pré-filtre : hors adhésion aucune ligne au journal (la phase B n'est jamais
    atteinte), stdout vide, code 0 ; dans un lab adhérent (témoin : une sonde morte ne prouve rien) exactement une ligne par entrée."""
    fautes = []
    n = [0]
    for lab_nom, racine, fichier in labs:
        for evt in CINQ_ENTREES:
            xdg = ctx.unique("xdg-sonde")
            os.makedirs(xdg)
            rc, out, err, _ = ctx.lancer("A", payload_evt(evt, racine, fichier), cwd=racine, dossier=dossier_coeur, extra_env={"XDG_CACHE_HOME": xdg}, np=True)
            lignes = lire_lignes_sonde(xdg)
            n[0] += 1
            if rc != 0 or out != b"" or err or lignes != 0:
                fautes.append("%s, %s : 0 ligne au journal, stdout vide, code 0 (attendu) — obtenu %d ligne(s), rc=%d out=%s" % (evt, lab_nom, lignes, rc, court(out)))
    for evt in CINQ_ENTREES:
        xdg = ctx.unique("xdg-temoin")
        os.makedirs(xdg)
        rc, out, err, _ = ctx.lancer("A", payload_evt(evt, adh, adh + "/.planning/STATE.md"), cwd=adh, dossier=dossier_coeur, extra_env={"XDG_CACHE_HOME": xdg}, np=True)
        lignes = lire_lignes_sonde(xdg)
        n[0] += 1
        if rc != 0 or out != b"" or err or lignes != 1:
            fautes.append("témoin %s, lab adhérent : 1 ligne au journal, stdout vide, code 0 (attendu) — obtenu %d ligne(s), rc=%d out=%s" % (evt, lignes, rc, court(out)))
    detail = "%d rejeux de la copie sonde sans pré-filtre : aucune ligne hors adhésion (%s), une ligne par entrée dans un lab adhérent (témoin)" % (n[0], ", ".join(l[0] for l in labs))
    return (not fautes), ("; ".join(fautes[:3]) + (" (+%d autre(s))" % (len(fautes) - 3) if len(fautes) > 3 else "") if fautes else detail)


# -------------------------------------------------------------------------------------------------
# R-EVT-02 à R-EVT-07
# -------------------------------------------------------------------------------------------------
def controle_evt_02(ctx, adh):
    """Lab adhérent, script présent : silence, code 0, pour les cinq entrées — sur la copie observe (commande complète) et sur le cœur
    LIVRÉ (armé) lancé seul : aucun gate existant ne s'applique à ces entrées dans ce plan."""
    fautes = []
    for evt in CINQ_ENTREES:
        brut = payload_evt(evt, adh, adh + "/.planning/notes.md")
        rc, out, err, _ = ctx.lancer("A", brut, cwd=adh)
        if not verdict_conforme(rc, out, err):
            fautes.append("%s (commande complète) : silence, code 0 (attendu) — obtenu rc=%d out=%s err=%s" % (evt, rc, court(out), court(err)))
        v, rc2, out2, err2 = verdict_direct(ctx, brut, adh)
        if v != "silence" or rc2 != 0 or err2:
            fautes.append("%s (cœur livré seul) : silence, code 0 (attendu) — obtenu %s rc=%d err=%s" % (evt, v, rc2, court(err2)))
    return (not fautes), ("; ".join(fautes) if fautes else "SubagentHandback, SubagentStop, SessionStart, CwdChanged, FileChanged dans un lab adhérent : silence, code 0 (commande complète et cœur livré)")


def controle_evt_03(ctx, texte, adh, dev):
    """Lab adhérent, script absent (mode C) puis python absent (mode D) : SubagentHandback d'un sous-agent quelconque (juge compris, sans
    dériver le rôle) → UN deny dont la raison dit « hook central indisponible », nomme le rapport du sous-agent et la réparation ; les
    quatre autres événements → stdout vide, code 0 ; lab dev → silence. Aucun message ne porte de chemin absolu, ni « no such file » /
    « can't open »."""
    fautes = []
    for mode in ("C", "D"):
        for agent in ("agent-test", "vf-judge"):
            rc, out, err, _ = rejouer_texte(ctx, texte, mode, payload_evt("SubagentHandback", adh, agent_type=agent), adh)
            raison = raison_deny(rc, out, err)
            etiquette = "mode %s, SubagentHandback de %s" % (mode, agent)
            if raison is None:
                fautes.append("%s : UN deny, code 0 (attendu) — obtenu %s rc=%d out=%s" % (etiquette, verdict(rc, out), rc, court(out)))
                continue
            manque = [m for m in ("hook central indisponible", "SubagentHandback", "rapport", "/vf-update") if m not in raison]
            if manque:
                fautes.append("%s : raison qui contient %s (attendu) — obtenu %r" % (etiquette, manque, raison[:200]))
            interdit = [f for f in FRAGMENTS_INTERDITS if f in raison.casefold()]
            absolu = chemin_absolu_dans(raison)
            if interdit or absolu or adh in raison:
                fautes.append("%s : ni chemin absolu ni %s (attendu) — obtenu %r" % (etiquette, FRAGMENTS_INTERDITS, absolu or interdit or raison[:120]))
        rc, out, err, _ = rejouer_texte(ctx, texte, mode, payload_evt("SubagentHandback", dev), dev)
        if not verdict_conforme(rc, out, err):
            fautes.append("mode %s, SubagentHandback sous un lab dev : silence (attendu) — obtenu rc=%d out=%s" % (mode, rc, court(out)))
        for evt in EVT_NON_OUTIL:
            rc, out, err, _ = rejouer_texte(ctx, texte, mode, payload_evt(evt, adh, adh + "/.planning/STATE.md"), adh)
            if not verdict_conforme(rc, out, err):
                fautes.append("mode %s, %s : stdout 0 octet, code 0 (fail-open, attendu) — obtenu rc=%d out=%s err=%s" % (mode, evt, rc, court(out), court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "scripts absent puis python absent : SubagentHandback refusé par UN deny (« hook central indisponible », rapport du sous-agent, /vf-update ; juge compris, rôle non dérivé), "
                          "SubagentStop, SessionStart, CwdChanged, FileChanged muets, lab dev en silence, aucun chemin absolu ni « no such file » / « can't open »")


def controle_evt_04(ctx, adh, source=None):
    """Faute injectée dans le mode d'un événement non outil (SubagentStop, SessionStart, CwdChanged, FileChanged) : stdout vide, code 0
    (fail-open déclaré) ; la même injection en PreToolUse (SubagentHandback) : un deny `erreur interne` (inchangé, P45-D-08)."""
    fautes = []
    for evt, marque in MODES_NON_OUTIL:
        dossier, raison = make_hook_mutant(ctx, "EVT4-" + evt, "return None  # " + marque, 'raise RuntimeError("faute injectee")', source=source)
        if dossier is None:
            return False, "mutant d'injection invalide (%s) : %s" % (evt, raison)
        rc, out, err, _ = ctx.lancer("A", payload_evt(evt, adh, adh + "/.planning/STATE.md"), cwd=adh, dossier=dossier)
        if not verdict_conforme(rc, out, err):
            fautes.append("faute dans le mode %s : stdout vide, code 0 (fail-open, attendu) — obtenu %s rc=%d out=%s" % (evt, verdict(rc, out), rc, court(out)))
    dossier, raison = make_hook_mutant(ctx, "EVT4-PRE", "resultats = evaluer_gates(contexte)  # phase-b", 'raise RuntimeError("faute injectee")', source=source)
    if dossier is None:
        return False, "mutant d'injection invalide (PreToolUse) : " + raison
    rc, out, err, _ = ctx.lancer("A", payload_evt("SubagentHandback", adh), cwd=adh, dossier=dossier)
    texte = raison_deny(rc, out, err)
    if texte is None or "erreur interne" not in texte:
        fautes.append("faute en PreToolUse (SubagentHandback) : un deny `erreur interne` (attendu) — obtenu %s rc=%d out=%s" % (verdict(rc, out), rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "faute injectée dans le mode SubagentStop, SessionStart, CwdChanged, puis FileChanged : stdout vide, code 0 (fail-open déclaré) ; en PreToolUse : deny `erreur interne`")


def controle_evt_05(ctx, dossier_coeur, adh):
    """`hook_event_name` absent = PreToolUse (la phase B est atteinte) ; `PreToolUse` écrit = même chose ; inconnu, d'une autre casse, vide
    ou non chaîne = silence, la phase B n'est PAS atteinte (limite (aq)). La sonde du cœur (une ligne par phase B atteinte) départage."""
    fautes = []
    base = {"session_id": "sess-test", "cwd": adh, "tool_name": "Write", "tool_input": {"file_path": adh + "/.planning/notes.md", "content": "x"}}
    absent = object()
    for etiquette, valeur, lignes_attendues in (("absent", absent, 1), ("PreToolUse", "PreToolUse", 1), ("inconnu", "Bogus", 0),
                                                 ("casse différente", "pretooluse", 0), ("vide", "", 0), ("non chaîne", 123, 0)):
        obj = dict(base)
        if valeur is not absent:
            obj["hook_event_name"] = valeur
        xdg = ctx.unique("xdg-evt05")
        os.makedirs(xdg)
        rc, out, err, _ = ctx.lancer("A", json.dumps(obj, separators=(",", ":")).encode("utf-8"), cwd=adh, dossier=dossier_coeur, extra_env={"XDG_CACHE_HOME": xdg}, np=True)
        lignes = lire_lignes_sonde(xdg)
        if rc != 0 or out != b"" or err or lignes != lignes_attendues:
            fautes.append("hook_event_name %s : %d ligne(s) de sonde, stdout vide, code 0 (attendu) — obtenu %d ligne(s), rc=%d out=%s" % (etiquette, lignes_attendues, lignes, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "hook_event_name absent ou PreToolUse : phase B atteinte ; inconnu, autre casse, vide, non chaîne : silence sans phase B")


def controle_evt_06(ctx, dossier_coeur, adh, dev):
    """FileChanged : la racine se dérive du `file_path` de PREMIER niveau, jamais du cwd. Un fichier d'un lab adhérent avec un cwd dev atteint
    la phase B (une ligne de sonde) ; l'inverse (cwd adhérent, fichier d'un lab dev) se tait ; un `file_path` relatif ou plus long que la borne
    du cœur se tait même avec un cwd adhérent."""
    fautes = []
    cas = (("fichier d'un lab adhérent, cwd dev", dev, adh + "/.planning/STATE.md", 1),
           ("fichier d'un lab dev, cwd adhérent", adh, dev + "/.planning/STATE.md", 0),
           ("file_path relatif, cwd adhérent", adh, ".planning/STATE.md", 0),
           ("file_path plus long que la borne, cwd adhérent", adh, adh + "/" + "a" * 5000, 0),
           # pire cas BORNÉ sous la borne (le traitement ajouté par la 46 ne rallonge aucun chemin coûteux) : près de 4000 caractères, un millier de composantes
           ("file_path de près de 4000 caractères sous un lab adhérent (pire cas sous la borne), cwd dev", dev, adh + "/" + "a/" * ((3900 - len(adh)) // 2) + "f", 1))
    pire = 0.0
    for etiquette, cwd, fichier, lignes_attendues in cas:
        xdg = ctx.unique("xdg-evt06")
        os.makedirs(xdg)
        debut = time.monotonic()
        rc, out, err, _ = ctx.lancer("A", payload_evt("FileChanged", cwd, fichier), cwd=cwd, dossier=dossier_coeur, extra_env={"XDG_CACHE_HOME": xdg}, np=True)
        pire = max(pire, time.monotonic() - debut)
        lignes = lire_lignes_sonde(xdg)
        if rc != 0 or out != b"" or err or lignes != lignes_attendues:
            fautes.append("%s : %d ligne(s) de sonde, stdout vide, code 0 (attendu) — obtenu %d ligne(s), rc=%d out=%s" % (etiquette, lignes_attendues, lignes, rc, court(out)))
    if pire >= PLAFOND_EVT_S:
        fautes.append("traitement de FileChanged borné : moins de %.0f s (attendu) — obtenu %.2f s" % (PLAFOND_EVT_S, pire))
    return (not fautes), ("; ".join(fautes) if fautes else "FileChanged : racine lue dans file_path (lab adhérent atteint avec un cwd dev, lab dev ignoré avec un cwd adhérent), chemin relatif ou trop long : silence, pire cas sous la borne en %.2f s (plafond %.0f s)" % (pire, PLAFOND_EVT_S))


def controle_evt_07(ctx, adh, source=None):
    """Contrat de sortie (P46-D-10) : un blocage de SubagentStop est la décision JSON `decision: block` + `reason`, code 0, JAMAIS le code 2 ;
    un message qui porterait « no such file » ou « can't open » est neutralisé ; SessionStart, CwdChanged, FileChanged ne refusent jamais
    (un mode qui voudrait bloquer reste muet) ; aucune sortie par `exit 2` dans le script ni dans la commande."""
    fautes = []
    brut = payload_evt("SubagentStop", adh)
    for raison_test, doit_porter in (("raison de test", "raison de test"), ("Erreur : No such file or directory", None), ("bash: can't open fichier", None)):
        dossier, raison = make_hook_mutant(ctx, "EVT7-S", "return None  # evt-mode-subagentstop", "return [%r]" % raison_test, source=source)
        if dossier is None:
            return False, "mutant d'émission invalide : " + raison
        direct = subprocess.run(["bash", os.path.join(dossier, "planning-hook.sh")], input=brut, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=adh, timeout=120)
        rc, out, err, _ = ctx.lancer("A", brut, cwd=adh, dossier=dossier)
        for etiquette, code, sortie, erreur in (("cœur seul", direct.returncode, direct.stdout, direct.stderr), ("commande complète", rc, out, err)):
            try:
                obj = json.loads(sortie.decode("utf-8"))
            except ValueError:
                obj = None
            ok_forme = isinstance(obj, dict) and obj.get("decision") == "block" and isinstance(obj.get("reason"), str) and set(obj) == {"decision", "reason"}
            if code != 0 or erreur or not ok_forme:
                fautes.append("%s, raison %r : `decision: block` + `reason`, code 0, stderr vide (attendu) — obtenu rc=%d out=%s err=%s" % (etiquette, raison_test, code, court(sortie), court(erreur)))
                continue
            if doit_porter is not None and obj["reason"] != doit_porter:
                fautes.append("%s : reason %r (attendu) — obtenu %r" % (etiquette, doit_porter, obj["reason"]))
            if any(f in obj["reason"].casefold() for f in FRAGMENTS_INTERDITS):
                fautes.append("%s, raison %r : aucun fragment %s dans le message (attendu) — obtenu %r" % (etiquette, raison_test, FRAGMENTS_INTERDITS, obj["reason"]))
    for evt, marque in MODES_NON_OUTIL[1:]:
        dossier, raison = make_hook_mutant(ctx, "EVT7-N", "return None  # " + marque, 'return ["refus voulu"]', source=source)
        if dossier is None:
            return False, "mutant d'émission invalide (%s) : %s" % (evt, raison)
        rc, out, err, _ = ctx.lancer("A", payload_evt(evt, adh, adh + "/.planning/STATE.md"), cwd=adh, dossier=dossier)
        if not verdict_conforme(rc, out, err):
            fautes.append("%s : ne refuse JAMAIS, stdout vide, code 0 (attendu) — obtenu %s rc=%d out=%s" % (evt, verdict(rc, out), rc, court(out)))
    texte_script = open(source or ctx.hook, encoding="utf-8").read()
    for numero, ligne in enumerate(texte_script.split("\n"), 1):
        code = ligne.split("#", 1)[0]
        if re.search(r"\bsys\.exit\(2\)|^\s*exit 2\b", code):
            fautes.append("script, ligne %d : aucune sortie par le code 2 (attendu) — obtenu %r" % (numero, ligne.strip()[:100]))
    if re.search(r"\bexit 2\b", ctx.cmd):
        fautes.append("commande enregistrée : aucune sortie par le code 2 (attendu) — obtenu `exit 2`")
    return (not fautes), ("; ".join(fautes[:3]) if fautes else
                          "SubagentStop : `decision: block` + `reason`, code 0 (cœur seul et commande), fragments « no such file » / « can't open » neutralisés ; SessionStart, CwdChanged, FileChanged ne refusent jamais ; aucun `exit 2`")


def sec_evenements(ctx):
    adh, dev = _labs_simples(ctx, "evt")
    labs = [("lab dev fixture", dev, dev + "/.planning/STATE.md")]
    if ctx.repo_root and os.path.isfile(os.path.join(ctx.repo_root, "plugin", "planning-core", "scripts", "planning-hook.sh")):
        labs.append(("ce dépôt", ctx.repo_root, os.path.join(ctx.repo_root, ".planning", "STATE.md")))
    else:
        print("NOTE R-EVT-01 hors dépôt : plugin/planning-core/scripts/planning-hook.sh absent à côté des suites — le cas « ce dépôt » n'est pas rejoué (jamais un vert)")
    # --- R-EVT-01 : hors adhésion
    o1 = controle_evt_01(ctx, ctx.cmd, labs)
    if o1[0]:
        ok("R-EVT-01 " + o1[1])
    else:
        ko("R-EVT-01", "hors adhésion, chaque entrée (SubagentHandback, SubagentStop, SessionStart, CwdChanged, FileChanged) rend un octet vide et 0, sans lancer le script ni python3", "conforme", o1[1])
    sonde, raison = fabriquer_sonde_coeur(ctx, "SONDE")
    if sonde is None:
        ko("R-EVT-01b", "la copie sonde du cœur est valide", "sonde valide", raison)
        return
    o1b = controle_evt_01b(ctx, sonde, labs, adh)
    if o1b[0]:
        ok("R-EVT-01b " + o1b[1])
    else:
        ko("R-EVT-01b", "la copie sonde du cœur n'atteint jamais la phase B hors adhésion et l'atteint dans un lab adhérent (témoin)", "conforme", o1b[1])
    # MUT-EVT-PREFILTRE : la commande SANS pré-filtre lance le script hors adhésion
    mutant_controle("EVT-PREFILTRE", o1, controle_evt_01(ctx, ctx.cmd_np, labs), "R-EVT-01 (pré-filtre ignoré : la commande sans l'appel de vf_pre)")
    # MUT-EVT-ADHESION : adhésion forcée vraie dans le cœur (sur la copie sonde) : la phase B est atteinte hors adhésion
    forcee, raison = fabriquer_sonde_coeur(ctx, "SONDE-ADH", extras=(('adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"]', "adherent = True"),))
    if forcee is None:
        komut("EVT-ADHESION", "mutant du cœur valide (adhésion forcée vraie)", "mutant valide", raison)
    else:
        mutant_controle("EVT-ADHESION", o1b, controle_evt_01b(ctx, forcee, labs, adh), "R-EVT-01b (adhésion ignorée dans le cœur)")
    # --- R-EVT-02
    o2 = controle_evt_02(ctx, adh)
    ok("R-EVT-02 " + o2[1]) if o2[0] else ko("R-EVT-02", "lab adhérent, script présent : silence pour les cinq entrées", "conforme", o2[1])
    # --- R-EVT-03 (+ repli retiré)
    o3 = controle_evt_03(ctx, ctx.cmd, adh, dev)
    ok("R-EVT-03 " + o3[1]) if o3[0] else ko("R-EVT-03", "mode dégradé : SubagentHandback refusé, les quatre autres événements muets", "conforme", o3[1])
    o3_np = controle_evt_03(ctx, ctx.cmd_np, adh, dev)
    muté, raison = make_cmd_mutant(ctx, "EVT-REPLI", "|*'\"tool_name\":\"SubagentHandback\"'*|*'\"tool_name\":\"Agent\"'*", "|*'\"tool_name\":\"Agent\"'*")
    if muté is None:
        komut("EVT-REPLI-HANDBACK", "texte muté distinct de l'original et sh -n réussit", "mutant valide", raison)
    else:
        mutant_controle("EVT-REPLI-HANDBACK", o3_np, controle_evt_03(ctx, muté, adh, dev), "R-EVT-03 (alternative SubagentHandback retirée du `case` de repli)")
    # --- R-EVT-04 (+ fail-open transformé en deny)
    o4 = controle_evt_04(ctx, adh)
    ok("R-EVT-04 " + o4[1]) if o4[0] else ko("R-EVT-04", "faute dans un mode non outil : silence, code 0 ; en PreToolUse : deny", "conforme", o4[1])
    ouvert, raison = make_hook_mutant(ctx, "FAILOPEN", "if evenement == EVT_PRETOOLUSE:  # evt-refus-pretooluse", "if True:  # evt-refus-pretooluse")
    if ouvert is None:
        komut("EVT-FAILOPEN", "mutant du cœur valide (exception d'un mode non outil refusée)", "mutant valide", raison)
    else:
        mutant_controle("EVT-FAILOPEN", o4, controle_evt_04(ctx, adh, source=os.path.join(ouvert, "planning-hook.sh")), "R-EVT-04 (l'exception d'un mode non outil devient un deny)")
    # --- R-EVT-05
    o5 = controle_evt_05(ctx, sonde, adh)
    ok("R-EVT-05 " + o5[1]) if o5[0] else ko("R-EVT-05", "hook_event_name absent = PreToolUse, inconnu = silence", "conforme", o5[1])
    # --- R-EVT-06 (+ racine de FileChanged lue dans cwd)
    o6 = controle_evt_06(ctx, sonde, adh, dev)
    ok("R-EVT-06 " + o6[1]) if o6[0] else ko("R-EVT-06", "FileChanged : racine lue dans file_path de premier niveau", "conforme", o6[1])
    cwd_lu, raison = fabriquer_sonde_coeur(ctx, "SONDE-CWD", extras=(("if evenement == EVT_FILE_CHANGED:  # evt-filechanged-depart", "if False:  # evt-filechanged-depart"),))
    if cwd_lu is None:
        komut("EVT-FILEPATH", "mutant du cœur valide (racine de FileChanged lue dans cwd)", "mutant valide", raison)
    else:
        mutant_controle("EVT-FILEPATH", o6, controle_evt_06(ctx, cwd_lu, adh, dev), "R-EVT-06 (racine de FileChanged lue dans cwd)")
    # --- R-EVT-07 (+ sortie de SubagentStop par le code 2)
    o7 = controle_evt_07(ctx, adh)
    ok("R-EVT-07 " + o7[1]) if o7[0] else ko("R-EVT-07", "contrat de sortie : SubagentStop block en code 0, jamais le code 2 ; les trois autres ne refusent jamais", "conforme", o7[1])
    # MUT-EVT-EXIT2 : le blocage de SubagentStop sort par le code 2 (os._exit : le fail-open du mode, qui attrape SystemExit, ne le masque pas)
    deux, raison = make_hook_mutant(ctx, "EXIT2", "                sortie_blocage_subagent(raisons)", "sortie_blocage_subagent(raisons); os._exit(2)")
    if deux is None:
        komut("EVT-EXIT2", "mutant du cœur valide (blocage de SubagentStop par le code 2)", "mutant valide", raison)
    else:
        mutant_controle("EVT-EXIT2", o7, controle_evt_07(ctx, adh, source=os.path.join(deux, "planning-hook.sh")), "R-EVT-07 (SubagentStop sort par le code 2)")
    # MUT-EVT-EXIT2-STATIQUE : un `sys.exit(2)` écrit dans le script (attrapé par le fail-open du mode, donc invisible du comportement : seul le contrôle statique le voit)
    deux_s, raison = make_hook_mutant(ctx, "EXIT2S", "_emettre({\"decision\": \"block\", \"reason\": _message_sur(\"\\n\".join(raisons))})  # sortie-subagentstop",
                                      "_emettre({\"decision\": \"block\", \"reason\": _message_sur(\"\\n\".join(raisons))}); sys.exit(2)  # sortie-subagentstop")
    if deux_s is None:
        komut("EVT-EXIT2-STATIQUE", "mutant du cœur valide (`sys.exit(2)` écrit dans le script)", "mutant valide", raison)
    else:
        mutant_controle("EVT-EXIT2-STATIQUE", o7, controle_evt_07(ctx, adh, source=os.path.join(deux_s, "planning-hook.sh")), "R-EVT-07 (contrôle statique : `sys.exit(2)` dans le script)")


SECTIONS = {
    "borne": sec_borne,
    "doute": sec_doute,
    "entree": sec_entree,
    "merge": sec_merge,
    "modes": sec_modes,
    "matrice": sec_matrice,
    "shells": sec_shells,
    "perf": sec_perf,
    "depot": sec_depot,
    "mutants": sec_mutants,
    "evenements": sec_evenements,
}


def main():
    scripts_dir, hooks_json, repo_root, work, settings_lab = sys.argv[2:7]
    ctx = Ctx(scripts_dir, hooks_json or None, repo_root or None, work, settings_lab or None)
    if ctx.charger_commande() is None:
        ko("R-CMD-01", "la commande enregistrée est lisible (une seule entrée PreToolUse portant planning-hook.sh)",
           "1 commande", "commande enregistrée introuvable dans " + str(hooks_json or settings_lab or "aucune source"))
        sys.exit(1)
    for nom in sys.argv[1].split(","):
        SECTIONS[nom](ctx)


main()
PY_AIDES_REG_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-$1.txt"
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$HOOKS_JSON" "$REPO_ROOT" "$WORK" "$SETTINGS_LAB" > "$out" 2>&1
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

[ -f "$HOOK" ] || { ko "planning-hook.sh présent" "le script du hook central existe à côté des suites" "$HOOK" "absent"; }

# VF_REG_SECTIONS (facultatif, pour rejouer une partie de la suite pendant le développement) : sections séparées par des virgules.
run_sections "${VF_REG_SECTIONS:-entree,merge,modes,matrice,shells,perf,depot,borne,doute,mutants,evenements}"

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
