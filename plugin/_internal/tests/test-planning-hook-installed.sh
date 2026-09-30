#!/usr/bin/env bash
# test-planning-hook-installed.sh — canary de CI AS-INSTALLED du hook central (Phase 45, 45-03 ;
# GATE-12, GATE-03, GATE-10, GATE-15 ; P45-D-06, P45-D-20). La suite installe planning-core dans un
# lab jetable PAR L'INSTALLEUR INCHANGÉ (vibeflow-update.sh, scope projet), lit la commande POSÉE
# dans .claude/settings.json (jamais settings.local.json, jamais hooks.json : c'est ce que le
# harnais exécute chez l'utilisateur, pas ce que le dépôt déclare) et la rejoue TELLE QUELLE sous
# /bin/sh -c, stdin = le payload du harnais. Un gate qui ne peut plus tourner doit être vu ICI,
# bloquant, à chaque push : la CI découvre cette suite (find … -path '*/tests/test-*.sh'), sans
# que .github/workflows/ci.yml change.
#
# Familles :
#   R-INST-01  l'installeur pose exactement UNE entrée PreToolUse qui cite planning-hook.sh dans
#              settings.json, aucune dans settings.local.json ; le script posé est exécutable
#   R-INST-02  lab adhérent, script présent, Write d'une cible neutre : code 0, stdout vide
#   R-INST-03  lab adhérent, script absent / python absent / script qui sort 1 / qui sort 2 : deny
#              pour Write, Edit, NotebookEdit, Agent, Task ; silence pour Bash (limite déclarée,
#              P45-D-06b)
#   R-INST-04  lab dev dans les mêmes modes et pour les six outils : stdout d'octet vide, code 0
#   R-INST-05  contrôle négatif anti-vert-à-vide : un settings.json vidé de l'entrée fait rougir
#              l'assertion R-INST-01 (verdict inversé attendu)
#   R-INST-06  la désinstallation ne laisse aucune entrée résiduelle, fichiers JSON valides
#   R-INST-ISOL  le vrai ~/.claude n'a pas bougé (sous-chemins que l'installeur écrit)
#
# ISOLATION : HOME et XDG_CACHE_HOME sont RÉASSIGNÉS et EXPORTÉS dans la suite (patron
# test-vibeflow-update.sh) — jamais par un préfixe `HOME=` sur la ligne d'invocation. Le vrai HOME
# n'est lu que pour prendre l'empreinte avant/après. Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`,
# ni `sed -i`, ni `timeout`, ni `readlink -f` ; tout le travail fin est fait par Python (PYBIN),
# comparaisons par `cmp -s`. Piège CI (ci.yml l.552, `bash -e {0}`) : aucun `commande && { … }`
# nu — des `if`.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
PLUGIN_DIR="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-planning-hook-installed] python3 requis" >&2; exit 1; fi
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

REAL_HOME="${HOME:-}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Isolation : le HOME de la suite est jetable ; aucune variable héritée ne choisit une cible.
mkdir -p "$WORK/home" "$WORK/xdg"
export HOME="$WORK/home"
export XDG_CACHE_HOME="$WORK/xdg"
unset CLAUDE_PROJECT_DIR VF_TARGET VF_TARGET_OVERRIDE VF_RUNTIME VF_SCOPE VIBEFLOW_CACHE CLAUDE_CONFIG_DIR 2>/dev/null || true

echo "== test-planning-hook-installed (installeur : $INSTALLER) =="

[ -f "$INSTALLER" ] || { ko "installeur présent" "vibeflow-update.sh existe" "$INSTALLER" "absent"; echo "== Résultat : $pass OK · $fail KO =="; exit 1; }

AIDES="$WORK/aides.py"
cat > "$AIDES" <<'PY_AIDES_INST_EOF'
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time

SIX_OUTILS = ("Write", "Edit", "NotebookEdit", "Bash", "Agent", "Task")
FILTRES = ("Write", "Edit", "NotebookEdit", "Agent", "Task")
CITE = "planning-hook.sh"


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


def ecrire(chemin, contenu, mode=None):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)
    if mode is not None:
        os.chmod(chemin, mode)


# --- Payload du harnais (Claude Code 2.1.284, mesuré) : JSON compact, clés dans cet ordre -------
def payload(outil, entree, cwd):
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd,
           "prompt_id": "prompt-test", "permission_mode": "default",
           "hook_event_name": "PreToolUse", "tool_name": outil, "tool_input": entree,
           "tool_use_id": "toolu_test"}
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


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


# --- Lecture des réglages POSÉS ---------------------------------------------------------------
def lire_json(chemin):
    with open(chemin, encoding="utf-8") as fh:
        return json.load(fh)


def entrees_du_hook(chemin):
    """Commandes des entrées PreToolUse qui citent planning-hook.sh dans un réglage (liste vide si
    le fichier est absent). Une exception de lecture remonte : jamais un vert sur un fichier illisible."""
    if not os.path.isfile(chemin):
        return []
    d = lire_json(chemin)
    res = []
    for groupe in (d.get("hooks", {}) or {}).get("PreToolUse", []) or []:
        for h in groupe.get("hooks", []) or []:
            if CITE in str(h.get("command", "")):
                res.append(h["command"])
    return res


def verifier_pose(lab):
    """R-INST-01 : liste des écarts (vide = conforme). Exactement UNE entrée dans settings.json,
    aucune dans settings.local.json, script posé exécutable, aucun jeton résiduel."""
    ecarts = []
    reglage = os.path.join(lab, ".claude", "settings.json")
    local = os.path.join(lab, ".claude", "settings.local.json")
    if not os.path.isfile(reglage):
        return ["settings.json absent (0 entrée posée — garde anti-vert-à-vide)"]
    if "{{" in open(reglage, encoding="utf-8").read():
        ecarts.append("jeton {{…}} résiduel dans settings.json")
    n = len(entrees_du_hook(reglage))
    if n != 1:
        ecarts.append("%d entrée(s) PreToolUse citant %s dans settings.json (attendu 1)" % (n, CITE))
    nl = len(entrees_du_hook(local))
    if nl != 0:
        ecarts.append("%d entrée(s) citant %s dans settings.local.json (attendu 0)" % (nl, CITE))
    script = os.path.join(lab, ".claude", "scripts", CITE)
    if not (os.path.isfile(script) and os.access(script, os.X_OK)):
        ecarts.append("script posé absent ou non exécutable : .claude/scripts/" + CITE)
    return ecarts


# --- Contexte : le lab installé et les modes de défaillance ------------------------------------
class Ctx:
    def __init__(self, plugin_dir, installer, work):
        self.plugin_dir = plugin_dir
        self.installer = installer
        self.work = work
        self.home = os.environ["HOME"]
        self.lab = os.path.join(work, "lab-installe")
        self.cache = os.path.join(work, "cache")
        self.cmd = None
        self._n = 0
        self.dev = None
        self.adh = None
        self.vide = None
        self.path_sans_python = None
        self.proj = {}

    def unique(self, prefixe):
        self._n += 1
        return os.path.join(self.work, prefixe + "-" + str(self._n))

    def installateur(self, action, module="planning-core"):
        env = dict(os.environ)
        env["VF_SCOPE"] = "project"
        env["VIBEFLOW_CACHE"] = self.cache
        p = subprocess.run(["bash", self.installer, action, module], cwd=self.lab, env=env,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=300)
        return p.returncode, p.stdout.decode("utf-8", "replace")

    def preparer_cache(self):
        os.makedirs(self.cache, exist_ok=True)
        cible = os.path.join(self.cache, "planning-core")
        if os.path.isdir(cible):
            shutil.rmtree(cible)
        shutil.copytree(os.path.join(self.plugin_dir, "planning-core"), cible)

    def fabriquer_labs(self):
        """Lab adhérent (cycles-v1) et lab dev (2.0), jetables, avec une cible neutre."""
        self.adh = os.path.join(self.work, "lab-adherent")
        self.dev = os.path.join(self.work, "lab-dev")
        ecrire(os.path.join(self.adh, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
        ecrire(os.path.join(self.dev, ".planning", "config.json"), '{"planning_version": "2.0"}')
        self.vide = os.path.join(self.work, "dossier-vide")
        os.makedirs(os.path.join(self.vide, ".claude"), exist_ok=True)
        # python absent : PATH réduit à quelques liens (jamais python3)
        self.path_sans_python = os.path.join(self.work, "path-sans-python")
        os.makedirs(self.path_sans_python, exist_ok=True)
        for nom in ("sh", "bash", "cat", "grep", "head", "mktemp", "rm", "env"):
            cible = shutil.which(nom)
            if cible and not os.path.lexists(os.path.join(self.path_sans_python, nom)):
                os.symlink(cible, os.path.join(self.path_sans_python, nom))
        # scripts substituts qui sortent 1 puis 2 (dans un projet jetable dont .claude/scripts existe)
        for code in (1, 2):
            proj = os.path.join(self.work, "proj-exit%d" % code)
            ecrire(os.path.join(proj, ".claude", "scripts", CITE),
                   "#!/usr/bin/env bash\ncat >/dev/null\necho 'substitut : plantage' >&2\nexit %d\n" % code, 0o755)
            self.proj["exit%d" % code] = proj

    def charger_commande(self):
        cmds = entrees_du_hook(os.path.join(self.lab, ".claude", "settings.json"))
        if len(cmds) != 1:
            return None
        self.cmd = cmds[0]
        return self.cmd

    def env_mode(self, mode):
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.home}
        if os.environ.get("TMPDIR"):
            env["TMPDIR"] = os.environ["TMPDIR"]
        if mode == "present":
            env["CLAUDE_PROJECT_DIR"] = self.lab
        elif mode == "script-absent":
            env["CLAUDE_PROJECT_DIR"] = self.vide
        elif mode == "python-absent":
            env["CLAUDE_PROJECT_DIR"] = self.lab
            env["PATH"] = self.path_sans_python
        elif mode in ("exit1", "exit2"):
            env["CLAUDE_PROJECT_DIR"] = self.proj[mode]
        else:
            raise ValueError(mode)
        return env

    def rejouer(self, mode, entree, cwd, shell="/bin/sh"):
        """La commande POSÉE, telle quelle, sous /bin/sh -c ; stdout et stderr séparés."""
        p = subprocess.run([shell, "-c", self.cmd], input=entree, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, env=self.env_mode(mode), cwd=cwd, timeout=120)
        return p.returncode, p.stdout, p.stderr


def empreinte_home(home):
    """Empreinte (chemin, taille) des sous-chemins que l'installeur sait écrire dans un HOME."""
    lignes = []
    for sous in ("agents", "skills", "scripts", "rules", "commands"):
        base = os.path.join(home, ".claude", sous)
        for racine, dossiers, fichiers in os.walk(base, followlinks=False):
            dossiers.sort()
            for f in sorted(fichiers):
                chemin = os.path.join(racine, f)
                try:
                    lignes.append("%s %d" % (chemin, os.lstat(chemin).st_size))
                except OSError:
                    lignes.append(chemin + " ?")
    reglage = os.path.join(home, ".claude", "settings.json")
    if os.path.isfile(reglage):
        with open(reglage, "rb") as fh:
            lignes.append(reglage + " " + hashlib.sha256(fh.read()).hexdigest())
    return hashlib.sha256("\n".join(lignes).encode("utf-8")).hexdigest(), len(lignes)


# =================================================================================================
# Sections
# =================================================================================================
def sec_install(ctx):
    """R-INST-01 et R-INST-05."""
    ctx.preparer_cache()
    os.makedirs(ctx.lab, exist_ok=True)
    ctx.fabriquer_labs()
    rc, sortie = ctx.installateur("install")
    if rc != 0:
        ko("R-INST-01", "l'installeur inchangé pose planning-core dans un lab jetable (scope projet)", "code 0", "code %d : %s" % (rc, court(sortie)))
        sys.exit(1)
    ecarts = verifier_pose(ctx.lab)
    if ecarts:
        ko("R-INST-01", "une entrée PreToolUse posée dans settings.json, aucune dans settings.local.json, script exécutable", "aucun écart", "; ".join(ecarts))
        sys.exit(1)
    if ctx.charger_commande() is None:
        ko("R-INST-01", "la commande posée est lisible (entrée unique)", "1 commande", "introuvable")
        sys.exit(1)
    ok("R-INST-01 install réelle (scope projet) : UNE entrée PreToolUse qui cite planning-hook.sh dans settings.json, aucune dans settings.local.json, script posé exécutable")

    # R-INST-05 : contrôle négatif — l'assertion R-INST-01 doit ROUGIR sur des réglages sans l'entrée.
    fautes = []
    for nom, contenu in (("settings.json vidé de ses hooks", '{"hooks": {}}'),
                         ("settings.json absent", None),
                         ("entrée déplacée dans settings.local.json seul", "deplace")):
        faux = ctx.unique("neg")
        os.makedirs(os.path.join(faux, ".claude", "scripts"), exist_ok=True)
        shutil.copy2(os.path.join(ctx.lab, ".claude", "scripts", CITE), os.path.join(faux, ".claude", "scripts", CITE))
        if contenu == "deplace":
            shutil.copy2(os.path.join(ctx.lab, ".claude", "settings.json"), os.path.join(faux, ".claude", "settings.local.json"))
            ecrire(os.path.join(faux, ".claude", "settings.json"), '{"hooks": {}}')
        elif contenu is not None:
            ecrire(os.path.join(faux, ".claude", "settings.json"), contenu)
        if not verifier_pose(faux):
            fautes.append(nom)
    if fautes:
        ko("R-INST-05", "l'assertion R-INST-01 rougit sur des réglages sans l'entrée (verdict inversé)", "au moins un écart signalé pour chaque cas", "aucun écart pour : " + ", ".join(fautes))
    else:
        ok("R-INST-05 contrôle négatif : settings.json vidé, absent ou dont l'entrée n'est que dans settings.local.json fait rougir R-INST-01 (aucun vert à vide)")


def sec_modes(ctx):
    """R-INST-02, R-INST-03 et R-INST-04."""
    def entree(outil, lab, rel=".planning/notes.md"):
        return payload(outil, entree_outil(outil, lab + "/" + rel), lab)

    # R-INST-02 : lab adhérent, script présent, Write d'une cible neutre
    rc, out, err = ctx.rejouer("present", entree("Write", ctx.adh), ctx.adh)
    if rc == 0 and out == b"" and not err:
        ok("R-INST-02 commande posée, lab adhérent, script présent, Write de .planning/notes.md : code 0, stdout vide")
    else:
        ko("R-INST-02", "Write d'une cible neutre en lab adhérent, script présent", "rc 0, stdout vide, stderr vide", "rc=%d out=%s err=%s" % (rc, court(out), court(err)))

    # R-INST-03 : lab adhérent, le hook ne peut pas tourner
    fautes = []
    n = 0
    for mode in ("script-absent", "python-absent", "exit1", "exit2"):
        for outil in SIX_OUTILS:
            rc, out, err = ctx.rejouer(mode, entree(outil, ctx.adh), ctx.adh)
            v = verdict(rc, out)
            attendu = "silence" if outil == "Bash" else "deny"
            n += 1
            if v != attendu:
                fautes.append((mode + " " + outil, attendu, v + " " + court(out) + " " + court(err)))
    if fautes:
        for cas, a, b in fautes:
            ko("R-INST-03", "lab adhérent, hook indisponible : " + cas, a, b)
    else:
        ok("R-INST-03 lab adhérent, script absent / python absent / script qui sort 1 / qui sort 2 : deny pour Write, Edit, NotebookEdit, Agent, Task ; silence pour Bash (limite déclarée, P45-D-06b) — %d rejeux" % n)

    # R-INST-04 : lab dev, cinq modes, six outils — octet vide
    fautes = []
    n = 0
    for mode in ("present", "script-absent", "python-absent", "exit1", "exit2"):
        for outil in SIX_OUTILS:
            rc, out, err = ctx.rejouer(mode, entree(outil, ctx.dev), ctx.dev)
            n += 1
            if rc != 0 or out != b"":
                fautes.append((mode + " " + outil, "stdout 0 octet, code 0", "rc=%d out=%s err=%s" % (rc, court(out), court(err))))
    if fautes:
        for cas, a, b in fautes:
            ko("R-INST-04", "lab dev : " + cas, a, b)
    else:
        ok("R-INST-04 lab dev (config 2.0), cinq modes, six outils : stdout d'octet vide et code 0 — %d rejeux" % n)


# --- Canary de session check-gates-alive.sh, POSÉ dans le lab jetable (R-CAN-01 à R-CAN-08) ------
CANARY = "check-gates-alive.sh"
PREFIXE_SIGNAL = "[planning-core] canary : "


def copier_lab(ctx, prefixe):
    """Copie du lab installé (liens conservés) : les cas destructifs ne touchent jamais l'original."""
    dest = ctx.unique(prefixe)
    shutil.copytree(ctx.lab, dest, symlinks=True)
    return dest


def armer_copie(lab, gates):
    """Réécrit en `armed` les lignes ARMEMENT_<gate> du planning-hook.sh POSÉ dans `lab` (copie)."""
    chemin = os.path.join(lab, ".claude", "scripts", CITE)
    texte = open(chemin, encoding="utf-8").read()
    for g in gates:
        motif = 'ARMEMENT_%s = "observe"' % g
        if texte.count(motif) != 1:
            raise RuntimeError("motif d'armement non unique dans la copie : " + motif)
        texte = texte.replace(motif, 'ARMEMENT_%s = "armed"' % g)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(texte)


def session(cwd):
    return json.dumps({"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd,
                       "hook_event_name": "SessionStart", "source": "startup"}).encode("utf-8")


def lancer_canary(ctx, lab, cwd, args=(), stdin="payload", tmpdir=None, env_extra=None, home=None):
    """Lance le check-gates-alive.sh POSÉ dans `lab`, stdout et stderr séparés."""
    script = os.path.join(lab, ".claude", "scripts", CANARY)
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": home or ctx.home,
           "CLAUDE_PROJECT_DIR": lab}
    if tmpdir:
        env["TMPDIR"] = tmpdir
    if env_extra:
        env.update(env_extra)
    donnees = session(cwd) if stdin == "payload" else (stdin or b"")
    p = subprocess.run(["bash", script] + list(args), input=donnees, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, env=env, cwd=cwd, timeout=180)
    return p.returncode, p.stdout, p.stderr


def une_ligne(out, contient=()):
    """`None` si stdout est UNE ligne au préfixe du canary qui contient chaque fragment, sinon la raison."""
    texte = out.decode("utf-8", "replace")
    lignes = [l for l in texte.split("\n") if l != ""]
    if len(lignes) != 1 or not texte.endswith("\n"):
        return "%d ligne(s) : %s" % (len(lignes), court(out))
    if not lignes[0].startswith(PREFIXE_SIGNAL):
        return "préfixe absent : " + court(out)
    for f in contient:
        if f not in lignes[0]:
            return "fragment absent (%s) : %s" % (f, court(out))
    return None


def reglage_temoin(ctx, nom, marqueur, corps=None):
    """Réglages dont la commande cite planning-hook.sh et laisse une trace `marqueur` à CHAQUE
    exécution : la trace prouve qu'un rejeu a eu lieu (ou n'a pas eu lieu)."""
    cmd = corps if corps is not None else (": > '" + marqueur + "'; cat >/dev/null # planning-hook.sh")
    chemin = os.path.join(ctx.work, nom)
    ecrire(chemin, json.dumps({"hooks": {"PreToolUse": [{"matcher": "Write", "hooks": [
        {"type": "command", "command": cmd}]}]}}))
    return chemin


def corps_deny(raison):
    """Corps de commande qui refuse tout avec `raison` (sans apostrophe ni guillemet)."""
    return ("cat >/dev/null; printf '%s\\n' '{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\","
            "\"permissionDecisionReason\":\"" + raison + "\"}}' # planning-hook.sh")


def sec_can(ctx):
    """R-CAN-01 à R-CAN-08."""
    ses = os.path.join(ctx.work, "session-adherente")
    ecrire(os.path.join(ses, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    dedans = os.path.join(ses, "sous", "dossier")
    os.makedirs(dedans, exist_ok=True)
    hors = os.path.join(ctx.work, "hors-de-tout-lab")
    os.makedirs(hors, exist_ok=True)
    script = os.path.join(ctx.lab, ".claude", "scripts", CANARY)

    # R-CAN-01 : session adhérente, commande posée saine
    fautes = []
    for args, attendu in (((), 3), (("--hook",), 0)):
        rc, out, err = lancer_canary(ctx, ctx.lab, ses, args)
        if rc != attendu or out != b"":
            fautes.append((" ".join(args) or "sans --hook", "code %d, stdout vide" % attendu, "rc=%d out=%s err=%s" % (rc, court(out), court(err))))
    rc, out, err = lancer_canary(ctx, ctx.lab, dedans, ())  # cwd = sous-dossier du lab adhérent
    if rc != 3 or out != b"":
        fautes.append(("cwd dans un sous-dossier du lab", "code 3, stdout vide", "rc=%d out=%s" % (rc, court(out))))
    if not os.path.isfile(script):
        fautes.append(("canary posé", "check-gates-alive.sh présent dans le lab installé", "absent"))
    if fautes:
        for cas, a, b in fautes:
            ko("R-CAN-01", "session adhérente, commande posée saine : " + cas, a, b)
    else:
        ok("R-CAN-01 session dans un lab adhérent, commande posée saine : code 3 et stdout vide ; sous --hook code 0 et stdout vide")

    # R-CAN-02 : hors lab adhérent, aucun rejeu (le réglage-témoin laisse une trace s'il est exécuté)
    fautes = []
    marq = os.path.join(ctx.work, "trace-rejeu-can02")
    temoin = reglage_temoin(ctx, "reglage-temoin-02.json", marq)
    tmpd = ctx.unique("tmpdir-can02")
    os.makedirs(tmpd, exist_ok=True)
    for nom, cwd, stdin in (("lab dev", ctx.dev, "payload"), ("hors de tout .planning/", hors, "payload"),
                            ("stdin vide, cwd du processus dans un lab dev", ctx.dev, b"")):
        for args in ((), ("--hook",)):
            rc, out, err = lancer_canary(ctx, ctx.lab, cwd, args + ("--settings=" + temoin,), stdin=stdin, tmpdir=tmpd)
            attendu = 0 if args else 3
            if rc != attendu or out != b"" or os.path.exists(marq):
                fautes.append((nom + (" --hook" if args else ""), "code %d, stdout vide, aucun rejeu (pas de trace)" % attendu,
                               "rc=%d out=%s trace=%s" % (rc, court(out), os.path.exists(marq))))
                if os.path.exists(marq):
                    os.remove(marq)
    reste = sorted(os.listdir(tmpd))
    if reste:
        fautes.append(("TMPDIR", "aucun fichier créé sous TMPDIR", "présents : " + ", ".join(reste)))
    # témoin : dans un lab adhérent le même réglage EST rejoué (la trace prouve que le test peut voir un rejeu)
    lancer_canary(ctx, ctx.lab, ses, ("--settings=" + temoin,))
    if not os.path.exists(marq):
        fautes.append(("témoin", "le réglage-témoin est rejoué dans un lab adhérent", "aucune trace : la mesure ne voit pas un rejeu"))
    else:
        os.remove(marq)
    if fautes:
        for cas, a, b in fautes:
            ko("R-CAN-02", "hors lab adhérent : " + cas, a, b)
    else:
        ok("R-CAN-02 session dans un lab dev, hors de tout .planning/, stdin vide : code 3 (sous --hook 0), stdout vide, aucun rejeu (trace absente), rien créé sous TMPDIR")

    # R-CAN-03 : aucun réglage ne porte la commande
    fautes = []
    sans = os.path.join(ctx.work, "reglage-sans-hook.json")
    ecrire(sans, '{"hooks": {}}')
    vide_home = ctx.unique("home-vide")
    os.makedirs(vide_home, exist_ok=True)
    vide_proj = ctx.unique("proj-vide")
    os.makedirs(os.path.join(vide_proj, ".claude"), exist_ok=True)
    for nom, args, lab_proj in (("--settings sans entrée", ("--settings=" + sans,), ctx.lab),
                                ("ni le projet ni le compte", (), vide_proj)):
        rc, out, err = lancer_canary(ctx, ctx.lab, ses, args, home=vide_home, env_extra={"CLAUDE_PROJECT_DIR": lab_proj})
        raison = une_ligne(out, ("hook central non enregistré",))
        if rc != 0 or raison:
            fautes.append((nom, "code 0 et UNE ligne « hook central non enregistré »", "rc=%d %s" % (rc, raison or "")))
    if fautes:
        for cas, a, b in fautes:
            ko("R-CAN-03", "aucun réglage ne porte la commande : " + cas, a, b)
    else:
        ok("R-CAN-03 aucun réglage ne porte la commande (F2, worktree ou clone non préparé) : code 0, UNE ligne « hook central non enregistré »")

    # R-CAN-04 : le script posé est retiré
    lab4 = copier_lab(ctx, "lab-sans-script")
    os.remove(os.path.join(lab4, ".claude", "scripts", CITE))
    rc, out, err = lancer_canary(ctx, lab4, ses, ())
    raison = une_ligne(out, ("mode dégradé", "Agent", "Task", "Bash", "P45-D-06b"))
    if rc == 0 and not raison:
        ok("R-CAN-04 script posé retiré : code 0, UNE ligne qui dit « mode dégradé » (écritures et dispatchs Agent et Task refusés, Bash ouvert : limite déclarée P45-D-06b)")
    else:
        ko("R-CAN-04", "script posé retiré : signal de mode dégradé qui nomme la limite Bash", "code 0 et une ligne « mode dégradé … Agent … Task … Bash … P45-D-06b »", "rc=%d %s err=%s" % (rc, raison or court(out), court(err)))

    # R-CAN-05 : gate armé sans cas de canary
    lab5 = copier_lab(ctx, "lab-arme-sans-cas")
    armer_copie(lab5, ("G6", "G5"))
    rc, out, err = lancer_canary(ctx, lab5, ses, ())
    raison = une_ligne(out, ("gate armé sans canary : G5, G6",))
    if rc == 0 and not raison:
        ok("R-CAN-05 ARMEMENT_G6 et ARMEMENT_G5 armed sans cas de canary : code 0, UNE ligne « gate armé sans canary : G5, G6 »")
    else:
        ko("R-CAN-05", "gates G6 et G5 armés dans la copie posée, CANARIS sans cas G6 ni G5", "code 0 et « gate armé sans canary : G5, G6 »", "rc=%d %s err=%s" % (rc, raison or court(out), court(err)))

    # R-CAN-06 : réglages illisibles
    fautes = []
    casse = os.path.join(ctx.work, "reglage-casse.json")
    ecrire(casse, '{"hooks": {"PreToolUse": [ {oups')
    for args, attendu in ((("--settings=" + casse,), 4), (("--settings=" + casse, "--hook"), 0)):
        rc, out, err = lancer_canary(ctx, ctx.lab, ses, args)
        if rc != attendu or out != b"":
            fautes.append((" ".join(a.split("=")[0] for a in args), "code %d (jamais 3), stdout vide" % attendu, "rc=%d out=%s" % (rc, court(out))))
    proj6 = ctx.unique("proj-illisible")
    ecrire(os.path.join(proj6, ".claude", "settings.json"), "pas du json")
    rc, out, err = lancer_canary(ctx, ctx.lab, ses, (), home=vide_home, env_extra={"CLAUDE_PROJECT_DIR": proj6})
    if rc != 4 or out != b"":
        fautes.append(("settings.json du projet illisible", "code 4, stdout vide", "rc=%d out=%s" % (rc, court(out))))
    if fautes:
        for cas, a, b in fautes:
            ko("R-CAN-06", "réglages illisibles : " + cas, a, b)
    else:
        ok("R-CAN-06 settings.json illisible (JSON invalide) : code 4, jamais 3 ; sous --hook code 0 et stdout vide")

    # R-CAN-07 : usage
    fautes = []
    for args in (("--inconnu",), ("--settings=",), ("--hook", "extra")):
        rc, out, err = lancer_canary(ctx, ctx.lab, ses, args)
        if rc != 64 or out != b"":
            fautes.append((" ".join(args), "code 64, stdout vide", "rc=%d out=%s" % (rc, court(out))))
    if fautes:
        for cas, a, b in fautes:
            ko("R-CAN-07", "usage : " + cas, a, b)
    else:
        ok("R-CAN-07 argument inconnu, --settings vide, argument en trop : code 64, stdout vide")

    # R-CAN-08 (ajout) : la limite déclarée est EXERCÉE — une commande qui ne ferme pas fait signaler
    fautes = []
    ouverte = reglage_temoin(ctx, "reglage-ouvert.json", os.path.join(ctx.work, "trace-08"), corps="cat >/dev/null # planning-hook.sh")
    rc, out, err = lancer_canary(ctx, ctx.lab, ses, ("--settings=" + ouverte,))
    raison = une_ligne(out, ("cas en échec", "D01"))
    if rc != 0 or raison:
        fautes.append(("commande qui laisse tout passer", "code 0 et une ligne « cas en échec » qui nomme D01", "rc=%d %s" % (rc, raison or "")))
    for nom, texte_raison, attendu in (("commande qui refuse même le cas nominal avec la raison du fail-closed", "[planning-core] hook central indisponible (script ou python3 absent)", "mode dégradé"),
                                       ("commande dont un gate refuse la cible neutre (raison d'un gate)", "[planning-core] G6 : refus de gate arme", "cas en échec")):
        ferme_tout = reglage_temoin(ctx, "reglage-ferme-tout.json", os.path.join(ctx.work, "trace-08b"), corps=corps_deny(texte_raison))
        rc, out, err = lancer_canary(ctx, ctx.lab, ses, ("--settings=" + ferme_tout,))
        raison = une_ligne(out, (attendu,))
        texte_sortie = out.decode("utf-8", "replace")
        if attendu == "cas en échec" and "mode dégradé" in texte_sortie:
            raison = "un refus de gate est annoncé « mode dégradé » : " + court(out)
        if rc != 0 or raison:
            fautes.append((nom, "code 0 et une ligne « " + attendu + " »" + (" (jamais « mode dégradé »)" if attendu == "cas en échec" else ""), "rc=%d %s" % (rc, raison or "")))
    if fautes:
        for cas, a, b in fautes:
            ko("R-CAN-08", "table de cas pilotée par l'attendu : " + cas, a, b)
    else:
        ok("R-CAN-08 une commande qui laisse tout passer fait signaler « cas en échec » (D01…) ; une qui refuse la cible neutre avec la raison du fail-closed fait signaler le mode dégradé, avec la raison d'un gate elle fait signaler « cas en échec » et jamais « mode dégradé »")


def make_canary_mutant(ctx, ident, motif, remplacement):
    """Copie du lab installé dont le check-gates-alive.sh a l'UNIQUE ligne portant `motif` remplacée
    par `remplacement` (indentation conservée). Rend (lab_muté, None) ou (None, raison)."""
    lab = copier_lab(ctx, "lab-mut-" + ident.lower())
    chemin = os.path.join(lab, ".claude", "scripts", CANARY)
    original = open(chemin, encoding="utf-8").read()
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
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(muté)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    corps, dedans = [], False
    for l in muté.split("\n"):
        if l == "PY_CHECK_GATES_ALIVE_EOF":
            dedans = False
        if dedans:
            corps.append(l)
        if l.endswith("<<'PY_CHECK_GATES_ALIVE_EOF'"):
            dedans = True
    try:
        compile("\n".join(corps) + "\n", chemin, "exec")
    except SyntaxError as e:
        return None, "SyntaxError du corps Python : " + str(e)
    return lab, None


def okmut(ident, texte):
    print("  ✓ MUT-%s TUÉ — %s" % (ident, texte))


def komut(ident, assertion, attendu, obtenu):
    print("  ✗ MUT-%s NON TUÉ" % ident)
    print("    assertion : " + str(assertion))
    print("    attendu (original) : " + str(attendu))
    print("    obtenu (mutant)     : " + str(obtenu))


def sec_mutants(ctx):
    """MUT-CAN-SANS-CAS, MUT-CAN-ADHESION, MUT-CAN-INDETERMINE : chaque contrôle du canary rougit
    quand on le retire (motif unique, texte distinct, bash -n, compilation)."""
    ses = os.path.join(ctx.work, "session-adherente")
    hors = os.path.join(ctx.work, "hors-de-tout-lab")
    casse = os.path.join(ctx.work, "reglage-casse.json")
    marq = os.path.join(ctx.work, "trace-rejeu-mut")
    temoin = reglage_temoin(ctx, "reglage-temoin-mut.json", marq)

    def sc_sans_cas(lab):
        armer_copie(lab, ("G6", "G5"))
        rc, out, _ = lancer_canary(ctx, lab, ses, ())
        return rc, out

    def sc_adhesion(lab):
        if os.path.exists(marq):
            os.remove(marq)
        rc, out, _ = lancer_canary(ctx, lab, hors, ("--settings=" + temoin,))
        return rc, out, os.path.exists(marq)

    def sc_indetermine(lab):
        rc, out, _ = lancer_canary(ctx, lab, ses, ("--settings=" + casse,))
        return rc, out

    # MUT-CAN-SANS-CAS
    lab_o = copier_lab(ctx, "lab-mut-ref")
    lab_m, raison = make_canary_mutant(ctx, "SANS-CAS", "# canary-sans-cas", "manquants = []  # canary-sans-cas")
    if lab_m is None:
        komut("CAN-SANS-CAS", "mutant du contrôle « gate armé sans cas »", "mutant valide", raison)
    else:
        o = sc_sans_cas(lab_o)
        m = sc_sans_cas(lab_m)
        signal = "gate armé sans canary".encode("utf-8")
        if o != m and signal in o[1] and signal not in m[1]:
            okmut("CAN-SANS-CAS", "R-CAN-05 · attendu (original) : code %d, « gate armé sans canary : G5, G6 » · obtenu (mutant) : code %d, %s" % (o[0], m[0], court(m[1]) or "aucun signal"))
        else:
            komut("CAN-SANS-CAS", "gate armé sans cas : l'original signale, le mutant se tait", court(o[1]), court(m[1]) + " (mutant non opposable)")

    # MUT-CAN-ADHESION
    lab_m, raison = make_canary_mutant(ctx, "ADHESION", "# canary-adhesion", "adherente = True  # canary-adhesion")
    if lab_m is None:
        komut("CAN-ADHESION", "mutant du filtre « session adhérente »", "mutant valide", raison)
    else:
        o = sc_adhesion(lab_o)
        m = sc_adhesion(lab_m)
        if o[0] == 3 and o[1] == b"" and not o[2] and (m[0] != 3 or m[2]):
            okmut("CAN-ADHESION", "R-CAN-02 · attendu (original) : code 3, aucun rejeu · obtenu (mutant) : code %d, rejeu %s" % (m[0], "lancé" if m[2] else "non lancé"))
        else:
            komut("CAN-ADHESION", "session hors lab adhérent : l'original ne rejoue rien, le mutant rejoue", "code 3, aucune trace", "original=%s mutant=%s" % (o, m))

    # MUT-CAN-RAISON : la raison du refus n'est plus regardée (tout deny devient « mode dégradé »)
    def sc_raison(lab):
        cmd = corps_deny("[planning-core] G6 : refus d un gate arme")
        reg = reglage_temoin(ctx, "reglage-raison-mut.json", os.path.join(ctx.work, "trace-raison-mut"), corps=cmd)
        rc, out, _ = lancer_canary(ctx, lab, ses, ("--settings=" + reg,))
        return rc, out

    lab_m, raison = make_canary_mutant(ctx, "RAISON", "# canary-raison", 'return "deny-degrade"  # canary-raison')
    if lab_m is None:
        komut("CAN-RAISON", "mutant du tri des raisons de refus", "mutant valide", raison)
    else:
        o = sc_raison(lab_o)
        m = sc_raison(lab_m)
        d = "mode dégradé".encode("utf-8")
        if o[0] == 0 and d not in o[1] and d in m[1]:
            okmut("CAN-RAISON", "R-CAN-08 · attendu (original) : un refus de gate n'est pas « mode dégradé » · obtenu (mutant) : %s" % court(m[1]))
        else:
            komut("CAN-RAISON", "refus d'un gate : l'original ne dit pas « mode dégradé », le mutant le dit", court(o[1]), court(m[1]) + " (mutant non opposable)")

    # MUT-CAN-INDETERMINE
    lab_m, raison = make_canary_mutant(ctx, "INDETERMINE", "# canary-indetermine", "return 3  # canary-indetermine")
    if lab_m is None:
        komut("CAN-INDETERMINE", "mutant du code 4", "mutant valide", raison)
    else:
        o = sc_indetermine(lab_o)
        m = sc_indetermine(lab_m)
        if o[0] == 4 and m[0] == 3:
            okmut("CAN-INDETERMINE", "R-CAN-06 · attendu (original) : code 4 · obtenu (mutant) : code 3 (vert de complaisance)")
        else:
            komut("CAN-INDETERMINE", "réglages illisibles : l'original rend 4, le mutant rend 3", "code 4", "original=%s mutant=%s" % (o[0], m[0]))


def sec_desinstall(ctx):
    """R-INST-06 : la désinstallation ne laisse aucune entrée résiduelle."""
    rc, sortie = ctx.installateur("uninstall")
    if rc != 0:
        ko("R-INST-06", "l'installeur désinstalle planning-core", "code 0", "code %d : %s" % (rc, court(sortie)))
        return
    fautes = []
    for nom in ("settings.json", "settings.local.json"):
        chemin = os.path.join(ctx.lab, ".claude", nom)
        if not os.path.isfile(chemin):
            continue
        try:
            d = lire_json(chemin)
        except ValueError as e:
            fautes.append(nom + " n'est plus un JSON valide : " + str(e))
            continue
        n = sum(len(g.get("hooks", [])) for gs in (d.get("hooks", {}) or {}).values() for g in gs)
        if n != 0:
            fautes.append("%s porte encore %d entrée(s) de hooks" % (nom, n))
        if entrees_du_hook(chemin):
            fautes.append(nom + " cite encore " + CITE)
    if fautes:
        ko("R-INST-06", "désinstallation : aucune entrée résiduelle, JSON valides", "aucune", "; ".join(fautes))
    else:
        ok("R-INST-06 désinstallation : aucune entrée qui cite planning-hook.sh (ni aucune autre) dans settings.json et settings.local.json, fichiers JSON valides")


def sec_isolation(ctx):
    avant = sys.argv[3]
    reel = sys.argv[2]
    apres, n = empreinte_home(reel)
    if avant == apres:
        ok("R-INST-ISOL le vrai ~/.claude n'a pas bougé (empreinte de %d entrée(s) sur les sous-chemins que l'installeur écrit)" % n)
    else:
        ko("R-INST-ISOL", "empreinte du vrai ~/.claude avant/après", avant, apres)


SECTIONS = {
    "install": sec_install,
    "modes": sec_modes,
    "can": sec_can,
    "mutants": sec_mutants,
    "desinstall": sec_desinstall,
    "isolation": sec_isolation,
}


def main():
    ordre = sys.argv[1].split(",")
    if ordre == ["empreinte"]:
        print(empreinte_home(sys.argv[2])[0])
        return
    plugin_dir, installer, work = sys.argv[4:7]
    ctx = Ctx(plugin_dir, installer, work)
    for nom in ordre:
        SECTIONS[nom](ctx)


main()
PY_AIDES_INST_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie.txt"
  "$PYBIN" "$AIDES" "$1" "$REAL_HOME" "$EMPREINTE_AVANT" "$PLUGIN_DIR" "$INSTALLER" "$WORK" > "$out" 2>&1
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

# Empreinte du VRAI ~/.claude avant la suite (sous-chemins que l'installeur écrit seulement).
EMPREINTE_AVANT="$("$PYBIN" "$AIDES" empreinte "$REAL_HOME")"

run_sections install,modes,can,mutants,desinstall,isolation

echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
