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
        self.scripts_dir = scripts_dir
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
            ("E", "cat >/dev/null\necho 'substitut E : plantage' >&2\nprintf '{\"hookSpecificOutput\":{'\nexit 1\n"),
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

    def preparer(self, dossier_scripts):
        """(texte de la commande, variables d'environnement additionnelles) pour un dossier de
        scripts donné. Forme du dépôt : le jeton est substitué. Forme posée dans un lab :
        `"$CLAUDE_PROJECT_DIR"/.claude/scripts`, résolu par un projet jetable."""
        if TOKEN in self.cmd:
            return self.cmd.replace(TOKEN, "'" + dossier_scripts + "'"), {}
        proj = self.unique("proj")
        os.makedirs(os.path.join(proj, ".claude"), exist_ok=True)
        os.symlink(dossier_scripts, os.path.join(proj, ".claude", "scripts"))
        return self.cmd, {"CLAUDE_PROJECT_DIR": proj}

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


SECTIONS = {
    "entree": sec_entree,
    "merge": sec_merge,
    "modes": sec_modes,
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

run_sections entree
run_sections merge
run_sections modes

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
