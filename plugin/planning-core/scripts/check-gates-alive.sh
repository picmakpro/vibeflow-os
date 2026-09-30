#!/usr/bin/env bash
# check-gates-alive.sh — canary de SESSION du hook central de planning-core (Phase 45, 45-03 ;
# GATE-12 ; P45-D-20, P45-D-06, P45-D-04). Au démarrage d'une session dans un lab ADHÉRENT
# cycles-v1, il retrouve la commande que les réglages ont enregistrée pour le hook central, la
# REJOUE TELLE QUELLE sur un lab adhérent synthétique (mktemp) et SIGNALE — jamais ne bloque — quand
# elle ne ferme plus. Un gate qu'on croit vivant et qui ne l'est pas est pire qu'un gate absent : la
# commande enregistrée est fail-closed dans un lab adhérent, mais le harnais, lui, ne dit rien quand
# le script manque dans un worktree non préparé, ni quand la copie qui s'exécute est périmée.
#
# Usage :
#   check-gates-alive.sh                       # verdict par le code de sortie, une ligne si signal
#   check-gates-alive.sh --hook                # sous SessionStart : stdout STRICTEMENT VIDE hors signal
#   check-gates-alive.sh --settings=<fichier>  # lit UNIQUEMENT ce réglage (défaut : voir ci-dessous)
# Entrée : stdin = le payload SessionStart (clé `cwd`) ou vide (repli : le cwd physique du processus).
#
# Réglages lus, dans l'ordre : `$CLAUDE_PROJECT_DIR/.claude/settings.json` puis
# `$HOME/.claude/settings.json` (ou le seul --settings). L'entrée retenue est la première entrée
# PreToolUse dont la commande cite planning-hook.sh. CLAUDE_PROJECT_DIR et HOME sont les DEUX
# entrées déclarées de ce script (où chercher les réglages, quelle copie du hook rejouer) : aucune
# variable d'environnement ne change ce qu'il exige d'un gate (P45-D-12a). Aucun contenu de payload
# n'est journalisé.
#
# Contrat de sortie (patron à 4 codes de check-guard-health.sh : SAIN et INDÉTERMINÉ ne se
# confondent JAMAIS) :
#   0  = signal — UNE seule ligne sur stdout, préfixe `[planning-core] canary : `
#   3  = SAIN — vérifié : session hors lab adhérent (rien n'a été rejoué), ou canary passé
#   4  = INDÉTERMINÉ — rien n'a pu être vérifié (réglages illisibles, table d'armement absente,
#        aucun interpréteur Python) : jamais un vert de complaisance
#  64  = erreur d'usage
# Sous --hook, 3 et 4 sont traduits en 0 avec stdout vide (docs/HOOKS-CONTRAT-SORTIE.md §2-§3).
#
# Signaux, dans l'ordre où le canary les cherche (UN seul par exécution) :
#   1. hook central non enregistré (F2) : aucun réglage ne porte la commande
#   2. mode dégradé : la commande, rejouée sur le cas nominal, refuse — le script ou python3 manque
#      ou plante ; écritures par outil et dispatchs Agent et Task refusés, Bash reste ouvert (limite
#      déclarée, P45-D-06b)
#   3. gate armé sans canary : la table d'armement du planning-hook.sh frère (constantes
#      ARMEMENT_<gate>) arme un gate qu'aucun cas de CANARIS ne couvre (P45-D-03a)
#   4. cas en échec : un cas de CANARIS n'obtient pas l'attendu que la table d'armement en dérive
#
# Table des cas : la constante CANARIS ci-dessous, une ligne par cas `<id>|<gate>|<mode>|<payload>`.
#   <gate>    DEGRADE (cas du fail-closed de la commande) ou G6, G5, G1, G7, ROLE
#   <mode>    script-absent (CLAUDE_PROJECT_DIR vers un dossier vide) | python-absent (PATH réduit) |
#             nominal (le script réel)
#   <payload> <outil>[:<chemin relatif au lab synthétique>][@<agent_type>]
# L'ATTENDU EST DÉRIVÉ, jamais écrit dans la table : DEGRADE -> refus (Write, Agent, Task) ou silence
# (Bash : limite déclarée P45-D-06b, exercée et non seulement écrite) ; gate `armed` -> refus ; gate
# `observe` -> silence (observation : le gate ne refuse pas, il journalise). 45-05 à 45-09 ajoutent
# leurs cas ; un gate armé sans cas fait signaler ce canary et rougir sa suite.
#
# Le rejeu n'écrit rien hors de son dossier mktemp (HOME du script de hook conservé en lecture,
# XDG_CACHE_HOME redirigé), supprimé en sortie ; il n'a lieu que dans une session adhérente.
set -uo pipefail

HOOK=0
SETTINGS=""
SETTINGS_SET=0
for arg in "$@"; do
  case "$arg" in
    --hook)       HOOK=1 ;;
    --settings=*) SETTINGS="${arg#*=}"; SETTINGS_SET=1 ;;
    -h|--help)    grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-gates-alive] argument inconnu : $arg" >&2; exit 64 ;;
  esac
done
if [ "$SETTINGS_SET" -eq 1 ] && [ -z "$SETTINGS" ]; then
  echo "[check-gates-alive] --settings vide" >&2
  exit 64
fi

# Diagnostic : jamais sur stdout ; muet sous --hook.
diag() { [ "$HOOK" -eq 1 ] || echo "[check-gates-alive] $*" >&2; }

# Traduction du silence interne vers le harnais (uniquement sous --hook) : 3 et 4 deviennent 0.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK" -eq 1 ] && { [ "$code" -eq 3 ] || [ "$code" -eq 4 ]; }; then
    exit 0
  fi
  exit "$code"
}

# Cascade python3 -> python -> py -3 (ADR-054), rejet du stub Microsoft Store par CHEMIN ; reproduite
# localement (patron check-guard-health.sh py_resolve_local), jamais en sourçant vf-portable.sh.
py_resolve_local() {
  local cand bin
  for cand in python3 python "py -3"; do
    bin="${cand%% *}"
    command -v "$bin" >/dev/null 2>&1 || continue
    case "$(command -v "$bin" 2>/dev/null)" in *WindowsApps*) continue ;; esac
    printf '%s' "$cand"
    return 0
  done
  return 1
}

PY_INVOKE="$(py_resolve_local)" || { diag "INDETERMINE, rien n'a été vérifié : aucun interpréteur Python"; hook_exit 4; }

SCRIPT_DIR_SELF="$(cd "$(dirname "$0")" && pwd -P)" || { diag "INDETERMINE : dossier du script illisible"; hook_exit 4; }

IN=""
if [ ! -t 0 ]; then IN="$(cat)"; fi

# shellcheck disable=SC2086
$PY_INVOKE -I -S - "$SCRIPT_DIR_SELF" "$SETTINGS" "$IN" <<'PY_CHECK_GATES_ALIVE_EOF'
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

SCHEMA_ADHESION = "cycles-v1"
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
PREFIXE = "[planning-core] canary : "
CITE = "planning-hook.sh"
GATES = ("G6", "G5", "G1", "G7", "ROLE")
VALEURS_ARMEMENT = ("observe", "armed")
DELAI_REJEU = 25
NOMINAL = "Write:.planning/notes.md"

# --- Table des cas (une ligne par cas) : <id>|<gate>|<mode>|<payload>. L'attendu est DÉRIVÉ. ------
CANARIS = (
    "D01|DEGRADE|script-absent|Write:.planning/notes.md",
    "D02|DEGRADE|script-absent|Agent",
    "D03|DEGRADE|script-absent|Task",
    "D04|DEGRADE|script-absent|Bash",
    "D05|DEGRADE|python-absent|Write:.planning/notes.md",
    "D06|DEGRADE|python-absent|Agent",
    "D07|DEGRADE|python-absent|Task",
    "D08|DEGRADE|python-absent|Bash",
)


class Indetermine(Exception):
    """Rien n'a pu être vérifié : le code de sortie est 4, jamais 3."""


def signaler(texte):
    sys.stdout.write(PREFIXE + texte + "\n")
    sys.stdout.flush()


# --- Session : le plus proche ancêtre du cwd qui contient .planning/, adhésion lue comme le hook ---
def cwd_de_session(brut):
    try:
        donnees = json.loads(brut) if brut.strip() else None
    except ValueError:
        donnees = None
    cwd = donnees.get("cwd") if isinstance(donnees, dict) else None
    if not (isinstance(cwd, str) and cwd.startswith("/")):
        cwd = os.getcwd()
    return os.path.realpath(cwd)


def racine_planning(depart):
    d = depart
    while True:
        if os.path.isdir(os.path.join(d, ".planning")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def lire_adhesion(racine):
    """Même lecture que `verifier_adhesion` de la 44 : O_NOFOLLOW, égalité stricte."""
    try:
        fd = os.open(os.path.join(racine, ".planning", "config.json"), os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(fd, "rb") as fh:
            donnees = json.loads(fh.read().decode("utf-8"))
    except (OSError, ValueError):
        return False
    return isinstance(donnees, dict) and isinstance(donnees.get("planning_version"), str) \
        and donnees["planning_version"] == SCHEMA_ADHESION


# --- Réglages : la commande enregistrée ---------------------------------------------------------
def trouver_commande(candidats):
    """(commande, chemin du réglage, illisible). Un réglage présent mais illisible n'est jamais lu
    comme « sans entrée » : `illisible` le retient, l'appelant tranche."""
    illisible = False
    for chemin in candidats:
        if not os.path.isfile(chemin):
            continue
        try:
            with open(chemin, encoding="utf-8") as fh:
                donnees = json.load(fh)
            evenements = donnees.get("hooks", {}) if isinstance(donnees, dict) else None
            if not isinstance(evenements, dict):
                raise ValueError("réglage sans objet hooks")
            for groupe in evenements.get("PreToolUse", []) or []:
                for h in groupe.get("hooks", []) or []:
                    commande = h.get("command") if isinstance(h, dict) else None
                    if isinstance(commande, str) and CITE in commande:
                        return commande, chemin, illisible
        except (OSError, ValueError, AttributeError, TypeError):
            illisible = True
    return None, None, illisible


# --- Rejeu ---------------------------------------------------------------------------------------
def fabriquer_payload(spec, lab):
    outil, _, reste = spec.partition(":")
    chemin, _, agent = reste.partition("@")
    if not reste:
        outil, _, agent = spec.partition("@")
    if outil in ("Agent", "Task"):
        entree = {"description": "d", "prompt": "p", "subagent_type": "general-purpose"}
    elif outil == "Bash":
        entree = {"command": "true"}
    elif outil == "NotebookEdit":
        entree = {"notebook_path": os.path.join(lab, chemin), "new_source": "x"}
    elif outil == "Edit":
        entree = {"file_path": os.path.join(lab, chemin), "old_string": "a", "new_string": "b"}
    else:
        entree = {"file_path": os.path.join(lab, chemin), "content": "x"}
    obj = {"session_id": "canary", "transcript_path": "transcript.jsonl", "cwd": lab,
           "prompt_id": "canary", "permission_mode": "default"}
    if agent:
        obj["agent_id"] = "canary-agent"
        obj["agent_type"] = agent
    obj["hook_event_name"] = "PreToolUse"
    obj["tool_name"] = outil
    obj["tool_input"] = entree
    obj["tool_use_id"] = "toolu_canary"
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def verdict(rc, sortie):
    """`silence`, `deny` (UN objet JSON deny, code 0) ou un état d'échec nommé."""
    if rc != 0:
        return "code " + str(rc)
    if sortie == b"":
        return "silence"
    try:
        s = json.loads(sortie.decode("utf-8"))["hookSpecificOutput"]
        if s["hookEventName"] == "PreToolUse" and s["permissionDecision"] == "deny" \
                and isinstance(s["permissionDecisionReason"], str):
            return "deny"
    except (ValueError, KeyError, TypeError):
        pass
    return "document inattendu"


class Rejeu:
    def __init__(self, commande, projet, tmp):
        self.commande = commande
        self.projet = projet
        self.tmp = tmp
        self.lab = os.path.realpath(os.path.join(tmp, "lab"))
        os.makedirs(os.path.join(self.lab, ".planning"))
        with open(os.path.join(self.lab, ".planning", "config.json"), "w", encoding="utf-8") as fh:
            fh.write('{"planning_version": "%s"}' % SCHEMA_ADHESION)
        self.vide = os.path.join(tmp, "vide")
        os.makedirs(os.path.join(self.vide, ".claude"))
        self.pathd = os.path.join(tmp, "path-sans-python")
        os.makedirs(self.pathd)
        for nom in ("sh", "bash", "cat", "grep", "head", "mktemp", "rm", "env"):
            cible = shutil.which(nom)
            if cible:
                os.symlink(cible, os.path.join(self.pathd, nom))
        self.xdg = os.path.join(tmp, "xdg")
        os.makedirs(self.xdg)

    def env(self, mode):
        home = os.environ.get("HOME", "")
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": home,
               "XDG_CACHE_HOME": self.xdg, "TMPDIR": self.tmp, "CLAUDE_PROJECT_DIR": self.projet}
        if mode == "script-absent":
            env["CLAUDE_PROJECT_DIR"] = self.vide
            env["HOME"] = self.vide
        elif mode == "python-absent":
            env["PATH"] = self.pathd
        elif mode != "nominal":
            raise Indetermine("mode de cas inconnu : " + mode)
        return env

    def jouer(self, mode, spec):
        try:
            p = subprocess.run(["/bin/sh", "-c", self.commande], input=fabriquer_payload(spec, self.lab),
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=self.env(mode),
                               cwd=self.lab, timeout=DELAI_REJEU)
        except subprocess.TimeoutExpired:
            return "délai dépassé"
        except OSError as exc:
            return "lancement impossible (" + type(exc).__name__ + ")"
        return verdict(p.returncode, p.stdout)


# --- Table d'armement du planning-hook.sh frère ---------------------------------------------------
def lire_armement(dossier_scripts):
    """Constantes ARMEMENT_<gate> du script posé en frère : toute ligne absente, en double ou de valeur
    hors observe/armed rend le canary indéterminé (P45-D-03a)."""
    try:
        with open(os.path.join(dossier_scripts, CITE), encoding="utf-8") as fh:
            texte = fh.read()
    except OSError:
        raise Indetermine("planning-hook.sh frère illisible")
    table = {}
    for gate in GATES:
        valeurs = re.findall(r'^ARMEMENT_' + gate + r' = "([^"]*)"', texte, re.M)
        if len(valeurs) != 1 or valeurs[0] not in VALEURS_ARMEMENT:
            raise Indetermine("ligne ARMEMENT_" + gate + " absente, en double ou de valeur inconnue")
        table[gate] = valeurs[0]
    return table


def lire_canaris():
    cas = []
    for ligne in CANARIS:
        morceaux = ligne.split("|")
        if len(morceaux) != 4 or morceaux[1] not in ("DEGRADE",) + GATES \
                or morceaux[2] not in ("script-absent", "python-absent", "nominal"):
            raise Indetermine("ligne de CANARIS mal formée : " + ligne)
        cas.append(tuple(morceaux))
    return cas


def attendu_de(gate, spec, table):
    """L'attendu est DÉRIVÉ de la table d'armement, jamais écrit dans CANARIS."""
    if gate == "DEGRADE":
        return "silence" if spec.split(":")[0].split("@")[0] == "Bash" else "deny"
    return "deny" if table[gate] == "armed" else "silence"


def main():
    dossier_scripts, arg_settings, brut = sys.argv[1], sys.argv[2], sys.argv[3]
    racine = racine_planning(cwd_de_session(brut))
    adherente = racine is not None and lire_adhesion(racine)  # canary-adhesion
    if not adherente:
        return 3  # session hors lab adhérent : rien n'est rejoué

    projet = os.environ.get("CLAUDE_PROJECT_DIR") or racine
    if arg_settings:
        candidats = [arg_settings]
    else:
        home = os.environ.get("HOME") or os.path.expanduser("~")
        candidats = [os.path.join(projet, ".claude", "settings.json"), os.path.join(home, ".claude", "settings.json")]
    commande, _, illisible = trouver_commande(candidats)
    if commande is None:
        if illisible:
            return 4  # canary-indetermine
        signaler("hook central non enregistré : aucun réglage du projet ni du compte ne porte la commande de "
                 "planning-hook.sh (worktree ou clone non préparé ?) — les gates ne gardent rien dans cette "
                 "session ; préparer le projet (/vf-update).")
        return 0

    try:
        cas = lire_canaris()
    except Indetermine:
        return 4
    tmp = tempfile.mkdtemp(prefix="vf-canary-")
    try:
        rejeu = Rejeu(commande, projet, os.path.realpath(tmp))
        nominal = rejeu.jouer("nominal", NOMINAL)
        if nominal == "deny":
            signaler("hook central en mode dégradé : le script ou python3 manque ou plante ; dans ce lab adhérent "
                     "les écritures par outil et les dispatchs Agent et Task sont refusés, Bash reste ouvert "
                     "(limite déclarée, P45-D-06b) — réparer : /vf-update ou installer python3, puis relancer la session.")
            return 0
        try:
            table = lire_armement(dossier_scripts)
        except Indetermine:
            return 4
        manquants = sorted(g for g in GATES if table[g] == "armed" and not any(c[1] == g for c in cas))  # canary-sans-cas
        if manquants:
            signaler("gate armé sans canary : " + ", ".join(manquants))
            return 0
        echecs = []
        if nominal != "silence":
            echecs.append("nominal (attendu silence, obtenu " + nominal + ")")
        for identifiant, gate, mode, spec in cas:
            attendu = attendu_de(gate, spec, table)
            obtenu = rejeu.jouer(mode, spec)
            if obtenu != attendu:
                echecs.append(identifiant + " (attendu " + attendu + ", obtenu " + obtenu + ")")
        if echecs:
            montres = ", ".join(echecs[:5]) + ((" (+%d autre(s))" % (len(echecs) - 5)) if len(echecs) > 5 else "")
            signaler("%d cas en échec : %s — la commande enregistrée ne ferme pas comme elle le doit." % (len(echecs), montres))
            return 0
        return 3
    except Indetermine:
        return 4
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


try:
    sys.exit(main())
except SystemExit:
    raise
except BaseException:
    sys.stderr.write("[check-gates-alive] erreur interne du canary : rien n'a été vérifié\n")
    sys.exit(4)
PY_CHECK_GATES_ALIVE_EOF
rc=$?
case "$rc" in
  0|3|4) hook_exit "$rc" ;;
  *) diag "INDETERMINE : code inattendu de l'interpréteur ($rc)"; hook_exit 4 ;;
esac
