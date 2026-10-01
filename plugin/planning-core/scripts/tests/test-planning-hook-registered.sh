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
import json
import os
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
        # matrice A et E) sont ceux de l'enveloppe du hook, pas ceux d'un gate : le script rejoué est une COPIE du livré dont les cinq
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
        """Dossier jetable portant planning-hook.sh du `source`, les cinq constantes ARMEMENT_* réécrites à `observe` (observe|armed → observe)."""
        texte, n = re.subn(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE) = )"(?:observe|armed)"', r'\1"observe"',
                           open(os.path.join(source, "planning-hook.sh"), encoding="utf-8").read(), flags=re.M)
        if n != 5:
            raise RuntimeError("cinq constantes ARMEMENT_* attendues, %d trouvée(s)" % n)
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

    def lancer(self, mode, entree, cwd=None, shell="/bin/sh", dossier=None, extra_env=None):
        texte, extra = self.preparer(dossier if dossier else self.dossier_mode(mode))
        if extra_env:
            extra = dict(extra)
            extra.update(extra_env)
        return self.rejouer(texte, entree, self.env_mode(mode, extra), cwd, shell)


def verdict(rc, out):
    """`silence` (rien, code 0), `deny` (UN objet JSON deny, code 0), sinon `autre`."""
    if rc != 0:
        return "autre:rc=" + str(rc)
    if out == b"":
        return "silence"
    try:
        obj = json.loads(out.decode("utf-8"))
        s = obj["hookSpecificOutput"]
        if s["hookEventName"] == "PreToolUse" and s["permissionDecision"] == "deny" and isinstance(s["permissionDecisionReason"], str):
            return "deny"
    except (ValueError, KeyError, TypeError):
        pass
    return "autre:document"


# --- Mutants du script (make_hook_mutant) ----------------------------------------------------
def make_hook_mutant(ctx, ident, motif, remplacement):
    """Copie du script dont l'UNIQUE ligne portant `motif` (fixe) est remplacée par `remplacement`
    (indentation conservée). Rend (dossier, None) ou (None, raison) : texte distinct de l'original,
    `bash -n` et compilation du corps Python extrait doivent passer, sinon le mutant ne prouve rien."""
    original = open(ctx.hook, encoding="utf-8").read()
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
def sec_entree(ctx):
    """R-CMD-01 : la forme de l'entrée enregistrée."""
    if not ctx.hooks_json:
        ok("R-CMD-01 (hors dépôt : commande lue dans le settings.json du lab, forme non rejouable ici)")
        return
    brut = open(ctx.hooks_json, encoding="utf-8").read()
    d = json.loads(brut)
    evts = d.get("hooks", {})
    pre = evts.get("PreToolUse", [])
    entrees = [(g, h) for g in pre for h in g.get("hooks", []) if "planning-hook.sh" in h.get("command", "")]
    fautes = []
    if len(pre) != 1 or len(entrees) != 1:
        fautes.append(("une seule entrée PreToolUse portant planning-hook.sh",
                       "1 groupe, 1 commande", "%d groupe(s), %d commande(s)" % (len(pre), len(entrees))))
    else:
        g, h = entrees[0]
        if g.get("matcher") != "Write|Edit|NotebookEdit|Bash|Agent|Task":
            fautes.append(("matcher exact", "Write|Edit|NotebookEdit|Bash|Agent|Task", g.get("matcher")))
        if h.get("timeout") != 20:
            fautes.append(("clé timeout", 20, h.get("timeout")))
        if h.get("type") != "command" or "args" in h:
            fautes.append(("forme shell (type command, sans args)", "command sans args", str(sorted(h.keys()))))
        cmd = h.get("command", "")
        if "{{VF_BASH}}" in cmd:
            fautes.append(("aucune occurrence de {{VF_BASH}}", "0", "présent"))
        noms = sorted(set(re.findall(r"([A-Za-z0-9._-]+\.(?:sh|py))", cmd)))
        if noms != ["planning-hook.sh"]:
            fautes.append(("seul basename *.sh/*.py cité", "['planning-hook.sh']", str(noms)))
    # entrées préexistantes : chacune retrouvée, dans l'ordre, sans altération (sous-suite)
    for evt, base in BASE_EVENEMENTS.items():
        courant = evts.get(evt, [])
        i = 0
        for groupe in courant:
            if i < len(base) and _groupe_contient(groupe, base[i]):
                i += 1
        if i != len(base):
            fautes.append(("entrées préexistantes de " + evt + " conservées", "structure de base", "altérée ou absente"))
    if fautes:
        for a, b, c in fautes:
            ko("R-CMD-01", a, b, c)
    else:
        ok("R-CMD-01 entrée unique, forme shell, matcher combiné, timeout 20, seul planning-hook.sh cité, événements préexistants inchangés")


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
        for groupes in d.get("hooks", {}).values():
            for g in groupes:
                for h in g.get("hooks", []):
                    if "planning-hook.sh" in json.dumps(h):
                        res.append((g.get("matcher"), h))
        return res

    rc, err = mh("merge")
    if rc != 0:
        ko("R-CMD-02", "merge-hooks.sh merge rend 0", "0", "rc=%d %s" % (rc, court(err)))
        return
    dans_s, dans_sl = entrees_posees(s), entrees_posees(sl)
    fautes = []
    if len(dans_s) != 1:
        fautes.append(("l'entrée est posée UNE fois dans settings.json", "1", str(len(dans_s))))
    if dans_sl:
        fautes.append(("rien dans settings.local.json (forme shell)", "0 entrée", str(len(dans_sl))))
    if dans_s:
        matcher, h = dans_s[0]
        if matcher != "Write|Edit|NotebookEdit|Bash|Agent|Task" or h.get("timeout") != 20:
            fautes.append(("matcher et timeout préservés", "Write|Edit|NotebookEdit|Bash|Agent|Task, 20", "%s, %s" % (matcher, h.get("timeout"))))
        if TOKEN in h["command"] or prefixe not in h["command"]:
            fautes.append(("jeton {{VF_SCRIPTS}} substitué par le préfixe", prefixe, court(h["command"], 80)))
    octets1 = (open(s, "rb").read(), open(sl, "rb").read() if os.path.exists(sl) else None)
    rc2, err2 = mh("merge")
    octets2 = (open(s, "rb").read(), open(sl, "rb").read() if os.path.exists(sl) else None)
    if rc2 != 0 or octets1 != octets2:
        fautes.append(("second merge idempotent (cmp)", "fichiers identiques, rc 0", "rc=%d, identiques=%s" % (rc2, octets1 == octets2)))
    # la commande POSÉE rejouée : script présent → silence ; script absent → deny
    if dans_s:
        cmd_posee = dans_s[0][1]["command"]
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
        ok("R-CMD-02 merge pose dans settings.json (rien dans settings.local.json), idempotent (cmp), commande posée rejouée, remove sans résidu")


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
PLANCHER_CORPUS = 72     # compte déclaré en dur du corpus livré : un corpus amaigri rougit aussi


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
    for nom in ("imb-a", "imb-b", "imb-c"):
        L.setdefault(nom, os.path.join(t, nom))
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
            rc, out, err, _ = ctx.lancer(mode, c.brut, cwd=c.cwd_proc)
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
                          "C": "script absent", "D": "python absent", "E": "script qui sort 1", "F": "script qui sort 2"}[mode]))


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
        if os.path.isdir(os.path.join(courant, ".planning")) and ".planning" not in [c.lower() for c in courant.split(os.sep)]:
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
    n = ctx.cmd.count(motif)
    if n != 1:
        return None, "motif ambigu ou absent (occurrences=%d)" % n
    muté = ctx.cmd.replace(motif, remplacement)
    if muté == ctx.cmd:
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
    o_t = rejouer_texte(ctx, ctx.cmd, mode_temoin, tem.brut, tem.cwd_proc)
    m_t = rejouer_texte(ctx, muté, mode_temoin, tem.brut, tem.cwd_proc)
    if o_t[:3] != m_t[:3]:
        komut(ident, "condition (b) : sur le témoin %s (mode %s) le mutant sort comme l'original" % (id_temoin, mode_temoin),
              nom_verdict(*o_t[:3]), nom_verdict(*m_t[:3]))
        return
    o_d = rejouer_texte(ctx, ctx.cmd, mode, disc.brut, disc.cwd_proc)
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
        ("EXT-8", 'else vf_tight "$(pwd -P)" && D=0; fi', 'else :; fi', "E24b", "C", {}),
        ("EXT-9", 'then P=$V/$P; else', 'then :; else', "E30", "C", {}),
        ("EXT-10", '..) _r=${_r%/*}; [ -n "$_r" ] || _r=/ ;;', '..) ;;', "A16", "C", {}),
        ("EXT-11", 'if [ -d "$_n" ] && _y=$(cd', 'if false && _y=$(cd', "A18", "C", {}),
        ("EXT-12", '*/[.][Pp][Ll][Aa][Nn][Nn][Ii][Nn][Gg]/*) ;;', '*/[.][Zz][Zz][Zz]/*) ;;', "A21", "C", {}),
        ("EXT-12D", '*/[.][Pp][Ll][Aa][Nn][Nn][Ii][Nn][Gg]/*) ;;', '*/[.][Zz][Zz][Zz]/*) ;;', "A19", "D", {}),
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
        original = controle_libelle_f4(ctx, ctx.cmd, adh_l, dev_l)
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

SECTIONS = {
    "entree": sec_entree,
    "merge": sec_merge,
    "modes": sec_modes,
    "matrice": sec_matrice,
    "shells": sec_shells,
    "perf": sec_perf,
    "depot": sec_depot,
    "mutants": sec_mutants,
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

run_sections entree,merge,modes,matrice,shells,perf,depot,mutants

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
