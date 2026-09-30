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

run_sections install,modes,desinstall,isolation

echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
