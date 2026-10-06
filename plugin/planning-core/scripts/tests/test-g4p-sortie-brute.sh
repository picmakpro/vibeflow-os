#!/usr/bin/env bash
# test-g4p-sortie-brute.sh — G4′, « pas de rapport de sous-agent sans sortie de commande brute » (Phase 46, 46-06 ; CLOT-06, CLOT-09, CLOT-12 ;
# P46-D-02, P46-D-02a, P46-D-02b, P46-D-10). Le hook est rejoué PAR LA COMMANDE ENREGISTRÉE (lue dans hooks.json, sous /bin/sh -c), jamais par un
# appel direct au script (P45-D-20) ; les cas de gate tournent sur des COPIES à l'armement FORCÉ (`copie_forcee`), jamais sur l'état livré, qui change
# à chaque armement. La grammaire est testée sur la fonction `sortie_brute_presente`, extraite du cœur Python du hook (ast, aucune copie libre) ET de
# bout en bout pour au moins un cas accepté et un cas refusé.
#
# Familles :
#   R-G4P-GRAM-01 messages acceptés par la grammaire (bloc ``` ou ~~~, fermeture plus longue, étiquette de langage, prose et autres blocs, lignes
#                 vides, blocs indentés, fins de ligne CRLF) ; de bout en bout : un rapport conforme passe sur copie armée
#   R-G4P-GRAM-02 jumeaux négatifs refusés (bloc sans ligne `$ `, commande sans sortie, deux commandes sans sortie entre elles, bloc non fermé, `$ls`,
#                 `$ ` suivi de blancs, sortie hors du bloc, commande après une ligne de texte, fermeture d'un autre caractère ou plus courte, message non
#                 chaîne) ; de bout en bout : un rapport non conforme est refusé sur copie armée
#   R-G4P-01      copie observe, lab adhérent, producteur doté de Bash, SubagentHandback sans sortie brute : silence, UNE ligne gate=G4P ; avec : aucune
#   R-G4P-02      copie armée, même cas : UN deny `[planning-core] G4P :` qui nomme l'agent et la marche à suivre ; avec sortie brute : passage
#   R-G4P-03      périmètre (copie armée, rapport sans sortie brute) : juge et manager qui ont Bash, worker et producteur sans Bash, allowlist ou définition
#                 illisible, agent inconnu, fil principal, agent_type vide, agent_id absent ou vide -> aucun refus ; worker doté de Bash, producteur sans champ
#                 `tools:`, formes `Bash(…)`, liste en ligne et en puces -> refus, aux deux événements
#   R-G4P-04      SubagentStop hors mode auto : UN objet `decision: block` + `reason`, code 0, stderr vide, jamais le code 2 ; avec sortie brute : silence
#   R-G4P-05      SubagentStop en mode auto : silence, aucune ligne de journal (le rapport a déjà passé le PreToolUse)
#   R-G4P-06      dérogation nominative `G4P` sur `agents/<agent_type>` : usage unique, aux deux événements
#   R-G4P-07      erreur interne injectée (dans evaluer_g4p, dans le mode SubagentStop) : armée deny / block, observe une ligne d'observation
#   R-G4P-08      lab dev : stdout d'octet vide aux deux événements
#   R-CANG-G4P    check-gates-alive.sh : cas G4P-handback et G4P-stop (producteur synthétique `canary-producteur` doté de Bash) ; état livré : observation, code 3 ;
#                 copie armée : deny puis block, code 3 ; evaluer_g4p neutralisé : signal qui nomme G4P
# Mutants (chacun tué par un contrôle, trace assertion · attendu (original) · obtenu (mutant)) :
#   MUT-G4P-GRAMMAIRE (la ligne qui suit la commande n'est plus jugée -> R-G4P-GRAM-02), MUT-G4P-FERMETURE (un bloc non fermé compte -> R-G4P-GRAM-02),
#   MUT-G4P-VERDICT (evaluer_g4p ne rend jamais de verdict -> R-G4P-01), MUT-G4P-AUTO (garde du mode auto retirée -> R-G4P-05), MUT-G4P-ROLE (juges et
#   managers inclus -> R-G4P-03), MUT-G4P-CAPACITE (contrôle de Bash retiré -> R-G4P-03), MUT-G4P-CODE2 (sortie SubagentStop en code 2 -> R-G4P-04),
#   MUT-G4P-ADHESION (adhésion forcée, commande sans pré-filtre -> R-G4P-08).
# Variables : VF_G4P_SECTIONS=<liste> pour ne rejouer qu'une partie (sections : gram, base, stop, canary, mutants_gram, mutants_base, mutants_stop).
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
    else echo "[test-g4p-sortie-brute] python3 requis" >&2; exit 1; fi
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
cat > "$AIDES" <<'PY_AIDES_G4P_EOF'
import ast
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.parse

TOKEN = "{{VF_SCRIPTS}}"
ABSENT = object()   # message absent du tool_input (jamais une chaîne)


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


def court(octets, n=200):
    texte = octets.decode("utf-8", "replace") if isinstance(octets, bytes) else str(octets)
    texte = texte.replace("\n", "\\n")
    return texte if len(texte) <= n else texte[:n] + "…(+" + str(len(texte) - n) + ")"


# --- Payloads du harnais -----------------------------------------------------------------------------------------
def payload_handback(cwd, agent_type, message, agent_id="agent-test", mode="default"):
    """PreToolUse de SubagentHandback : le rapport est `tool_input.message`. `agent_type` None : fil principal (ni agent_id ni agent_type)."""
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "prompt_id": "prompt-test", "permission_mode": mode}
    if agent_type is not None:
        if agent_id is not None:
            obj["agent_id"] = agent_id
        obj["agent_type"] = agent_type
    obj["hook_event_name"] = "PreToolUse"
    obj["tool_name"] = "SubagentHandback"
    obj["tool_input"] = {} if message is ABSENT else {"message": message}
    obj["tool_use_id"] = "toolu_test"
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def payload_stop(cwd, agent_type, message, agent_id="agent-test", mode="default"):
    """SubagentStop (46-RECHERCHE-HOOKS §2) : `last_assistant_message` est le rapport ; `mode` None : `permission_mode` absent ; `message` ABSENT : la
    clé est omise. `agent_type` None : ni agent_id ni agent_type (fil principal)."""
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd}
    if mode is not None:
        obj["permission_mode"] = mode
    obj.update({"hook_event_name": "SubagentStop", "stop_hook_active": False})
    if agent_type is not None:
        if agent_id is not None:
            obj["agent_id"] = agent_id
        obj["agent_type"] = agent_type
    obj["agent_transcript_path"] = "sub.jsonl"
    if message is not ABSENT:
        obj["last_assistant_message"] = message
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def payload_ecriture(cwd, chemin):
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd, "prompt_id": "prompt-test", "permission_mode": "default",
           "hook_event_name": "PreToolUse", "tool_name": "Write", "tool_input": {"file_path": chemin, "content": "x"}, "tool_use_id": "toolu_test"}
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def classer(rc, out):
    """`silence`, `avertit` (additionalContext sans décision), `deny`, `block` (SubagentStop : `decision: block` + `reason`), ou `autre:...`."""
    if rc != 0:
        return "autre:rc=%d" % rc
    if out == b"":
        return "silence"
    try:
        doc = json.loads(out.decode("utf-8"))
    except ValueError:
        return "autre:document"
    if isinstance(doc, dict) and doc.get("decision") == "block":
        return "block" if isinstance(doc.get("reason"), str) and set(doc) == {"decision", "reason"} else "autre:block-malforme"
    try:
        s = doc["hookSpecificOutput"]
    except (KeyError, TypeError):
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


def raison_de(out):
    return json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]


# --- Corps Python du hook, mutants ---------------------------------------------------------------------------------
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


class Ctx:
    def __init__(self, scripts_dir, hooks_json, work, settings_lab):
        self.scripts_dir = scripts_dir
        self.hooks_json = hooks_json
        self.settings_lab = settings_lab
        self.work = work
        self.hook = os.path.join(scripts_dir, "planning-hook.sh")
        self.home = os.path.join(work, "home")
        os.makedirs(self.home, exist_ok=True)
        self.cache = os.path.join(work, "cache-suite")
        os.makedirs(self.cache, exist_ok=True)
        self._forcees = {}
        self._n = 0
        self.originaux = {}   # résultat des contrôles sur le script réel, calculé une fois (les mutants le comparent)
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
        cands = [h["command"] for g in d.get("hooks", {}).get("PreToolUse", []) for h in g.get("hooks", [])
                 if "planning-hook.sh" in h.get("command", "")]
        if len(cands) != 1:
            return None
        self.cmd = cands[0]
        # Pré-filtre hors adhésion : les cas de cette suite mesurent le CŒUR et les gates, rejoués par la couche shell d'avant le pré-filtre (le bloc
        # retiré, octet pour octet) ; la commande COMPLÈTE est gardée par test-planning-prefilter.sh et par R-REFERENCE du canary.
        appel, debut = "vf_pre && exit 0\n", "_pn='\n'\nvf_pp()"
        if self.cmd.count(appel) != 1 or self.cmd.count(debut) != 1 or self.cmd.index(debut) > self.cmd.index(appel):
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

    def lancer(self, entree, cwd=None, dossier=None, extra_env=None):
        """Rejoue la commande enregistrée TELLE QUELLE sous /bin/sh -c, avec le script du dossier donné (défaut : le script réel)."""
        d = dossier or self.scripts_dir
        if TOKEN in self.cmd_np:
            texte, extra = self.cmd_np.replace(TOKEN, "'" + d + "'"), {}
        else:
            proj = self.unique("proj")
            os.makedirs(os.path.join(proj, ".claude"), exist_ok=True)
            os.symlink(d, os.path.join(proj, ".claude", "scripts"))
            texte, extra = self.cmd_np, {"CLAUDE_PROJECT_DIR": proj}
        env = self.env(extra)
        if extra_env:
            env.update(extra_env)
        p = subprocess.run(["/bin/sh", "-c", texte], input=entree, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, env=env, cwd=cwd, timeout=120)
        return p.returncode, p.stdout, p.stderr

    def copie_forcee(self, dossier_scripts, valeur):
        """Copie du script du dossier donné dont les huit constantes ARMEMENT_* valent `valeur` (`observe` ou `armed`) : les cas de gate ne
        dépendent jamais de l'état livré."""
        cle = (dossier_scripts, valeur)
        if cle not in self._forcees:
            texte = open(os.path.join(dossier_scripts, "planning-hook.sh"), encoding="utf-8").read()
            texte, n = re.subn(REGEX_ARMEMENT, r'\1"' + valeur + '"', texte, flags=re.M)
            if n != 8:
                raise RuntimeError("huit constantes ARMEMENT_* attendues, %d trouvée(s)" % n)
            d = self.unique("force-" + valeur)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
                fh.write(texte)
            os.chmod(os.path.join(d, "planning-hook.sh"), 0o755)
            self._forcees[cle] = d
        return self._forcees[cle]


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


# --- Journal d'observation, labs, agents ------------------------------------------------------------------------------
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


def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)


def def_agent(nom, tools=None, disallowed=None, interne=False):
    """Définition d'agent synthétique (frontmatter lu par le hook : `name`, `vf-internal`, `tools`, `disallowedTools`). `tools=None` : aucun champ
    `tools:` (l'agent hérite des outils de la session)."""
    lignes = ["---", "name: " + nom, "description: agent synthétique d'un cas de test, jamais exécuté"]
    if interne:
        lignes.append("vf-internal: true")
    if tools is not None:
        lignes.append("tools: " + tools)
    if disallowed is not None:
        lignes.append("disallowedTools: " + disallowed)
    lignes += ["---", "Corps.", ""]
    return "\n".join(lignes)


AGENTS = {
    # Dans le périmètre de G4′ (worker ou producteur, Bash disponible)
    "producteur-bash": def_agent("producteur-bash", tools="Read, Bash"),
    "worker-bash": def_agent("worker-bash", tools="Read, Bash", interne=True),
    "producteur-sans-champ": def_agent("producteur-sans-champ"),
    "producteur-bash-forme": def_agent("producteur-bash-forme", tools="Read, Bash(git status)"),
    "producteur-flux": def_agent("producteur-flux", tools="[Read, Bash]"),
    "producteur-puces": "---\nname: producteur-puces\ndescription: agent synthétique d'un cas de test, jamais exécuté\ntools:\n  - Read\n  - Bash\n---\nCorps.\n",
    # Hors périmètre : un juge ou un manager qui a Bash, un agent sans Bash, une définition illisible
    "juge-bash": def_agent("juge-bash", tools="Read, Bash", disallowed="Write, Edit"),
    "manager-bash": def_agent("manager-bash", tools="Read, Bash, Agent(worker-bash)"),
    "worker-sans-bash": def_agent("worker-sans-bash", tools="Read, Grep", interne=True),
    "producteur-sans-bash": def_agent("producteur-sans-bash", tools="Read, Write"),
    "producteur-interdit-bash": def_agent("producteur-interdit-bash", tools="Read, Bash", disallowed="Bash"),
    "producteur-sans-champ-interdit": def_agent("producteur-sans-champ-interdit", disallowed="Bash"),
    "producteur-allowlist-illisible": def_agent("producteur-allowlist-illisible", tools="Read, Bash("),
    "illisible": "---\nname: illisible\ndescription: frontmatter jamais refermé\ntools: Read, Bash\n",
}
HORS_PERIMETRE = ("juge-bash", "manager-bash", "worker-sans-bash", "producteur-sans-bash", "producteur-interdit-bash", "producteur-sans-champ-interdit",
                  "producteur-allowlist-illisible", "illisible", "agent-inconnu")
DANS_PERIMETRE = ("producteur-bash", "worker-bash", "producteur-sans-champ", "producteur-bash-forme", "producteur-flux", "producteur-puces")


def fabriquer_lab(ctx, nom, adherent=True, agents=None):
    """Lab jetable : `.planning/config.json` (adhérent cycles-v1, sinon dev) et les définitions d'agents `agents` {nom: texte} sous `.claude/agents/`."""
    racine = ctx.unique("lab-" + nom)
    ecrire(os.path.join(racine, ".planning", "config.json"), '{"planning_version": "%s"}' % ("cycles-v1" if adherent else "2.0"))
    for agent, texte in (AGENTS if agents is None else agents).items():
        ecrire(os.path.join(racine, ".claude", "agents", agent + ".md"), texte)
    return racine


def fautes_de_message(raison, lab):
    """Un message de refus ne porte ni le chemin absolu du lab, ni « no such file », ni « can't open » (P46-D-10, #60490)."""
    fautes = []
    if lab in raison or os.path.realpath(lab) in raison:
        fautes.append("chemin absolu du lab")
    bas = raison.casefold()
    for fragment in ("no such file", "can't open"):
        if fragment in bas:
            fautes.append(fragment)
    return fautes


def _dossier(ctx, script):
    return script if script else ctx.scripts_dir


def controle_temoin(ctx, script):
    """Témoin : Write d'une cible neutre d'un lab adhérent -> silence (aucun mutant de G4′ ne l'affecte)."""
    lab = fabriquer_lab(ctx, "temoin")
    rc, out, err = ctx.lancer(payload_ecriture(lab, os.path.join(lab, ".planning", "notes.md")), cwd=lab, dossier=_dossier(ctx, script))
    return classer(rc, out) == "silence" and not err, classer(rc, out)


def jouer_handback(ctx, dossier_hook, lab, agent_type, message, cache=None, agent_id="agent-test", mode="default"):
    extra = {"XDG_CACHE_HOME": cache} if cache else None
    return ctx.lancer(payload_handback(lab, agent_type, message, agent_id=agent_id, mode=mode), cwd=lab, dossier=dossier_hook, extra_env=extra)


# =================================================================================================
# Grammaire de la sortie brute : la fonction `sortie_brute_presente` du hook, extraite par ast (jamais une copie libre)
# =================================================================================================
def fonctions_grammaire(chemin_hook):
    """Espace de noms où `sortie_brute_presente` et `_delimiteur_ouvrant` du cœur Python du hook sont chargées depuis le TEXTE du script (celui du
    dossier jugé : le vrai ou un mutant)."""
    arbre = ast.parse(corps_python(open(chemin_hook, encoding="utf-8").read()))
    noeuds = [n for n in arbre.body if isinstance(n, ast.FunctionDef) and n.name in ("sortie_brute_presente", "_delimiteur_ouvrant")]
    if sorted(n.name for n in noeuds) != ["_delimiteur_ouvrant", "sortie_brute_presente"]:
        raise RuntimeError("sortie_brute_presente et _delimiteur_ouvrant attendues dans le cœur du hook")
    espace = {}
    exec(compile(ast.Module(body=noeuds, type_ignores=[]), chemin_hook, "exec"), espace)
    return espace


ACCEPTES = (
    ("bloc ``` : commande puis sortie", "```\n$ ls\nfichier.txt\n```"),
    ("bloc ~~~ : commande puis sortie", "~~~\n$ ls\nfichier.txt\n~~~"),
    ("fermeture plus longue que l'ouverture", "```\n$ ls\nfichier.txt\n`````"),
    ("ouverture de quatre, un bloc de trois dans la sortie", "````\n$ cat note.md\n```\n````"),
    ("étiquette de langage après l'ouverture", "```sh\n$ ls\nfichier.txt\n```"),
    ("étiquette après ~~~", "~~~bash\n$ pytest -q\n3 passed\n~~~"),
    ("prose avant, un bloc sans commande, un bloc conforme, prose après",
     "Voici le résultat.\n```\nsimple texte\n```\nfini\n```bash\n$ pytest -q\n3 passed\n```\nmerci"),
    ("lignes vides autour de la commande et de la sortie", "```\n\n$ ls\n\nfichier.txt\n\n```"),
    ("bloc indenté", "  ```\n  $ ls\n  fichier.txt\n  ```"),
    ("fins de ligne CRLF", "```\r\n$ ls\r\nfichier.txt\r\n```\r\n"),
    ("fermeture suivie de blancs", "```\n$ ls\nfichier.txt\n```   \n"),
    ("une seule ligne de sortie, plusieurs ensuite", "```\n$ make\nok\nencore\n```"),
    ("deux commandes dans le bloc : la seconde est de la sortie après la première sortie", "```\n$ a\nsortie\n$ b\nsortie\n```"),
)

REFUSES = (
    ("bloc sans ligne `$ `", "```\nls\nfichier.txt\n```"),
    ("commande sans sortie (fermeture juste après)", "```\n$ ls\n```"),
    ("commande sans sortie, lignes vides puis fermeture", "```\n$ ls\n\n\n```"),
    ("deux commandes sans sortie entre elles", "```\n$ a\n$ b\nfichier.txt\n```"),
    ("bloc non fermé", "```\n$ ls\nfichier.txt\n"),
    ("`$ls` sans espace", "```\n$ls\nfichier.txt\n```"),
    ("`$ ` suivi de blancs", "```\n$ \nfichier.txt\n```"),
    ("`$ ` suivi de deux blancs avant la commande", "```\n$  ls\nfichier.txt\n```"),
    ("sortie hors du bloc", "```\n$ ls\n```\nfichier.txt"),
    ("commande en deuxième ligne non vide, après une ligne de texte", "```\nvoici\n$ ls\nfichier.txt\n```"),
    ("fermeture d'un autre caractère (``` fermé par ~~~)", "```\n$ ls\nfichier.txt\n~~~"),
    ("fermeture d'un autre caractère (~~~ fermé par ```)", "~~~\n$ ls\nfichier.txt\n```"),
    ("fermeture plus courte que l'ouverture", "````\n$ ls\nfichier.txt\n```"),
    ("ligne de trois accents graves avec du texte : pas une fermeture", "```\n$ ls\nfichier.txt\n``` fin"),
    ("ouverture dont l'étiquette porte un accent grave : pas une ouverture", "```$ ls```\nfichier.txt\n```"),
    ("commande dans un message sans bloc", "$ ls\nfichier.txt"),
    ("deux accents graves seulement", "``\n$ ls\nfichier.txt\n``"),
    ("message vide", ""),
    ("prose seule", "J'ai terminé le travail, tout fonctionne."),
    ("message non chaîne : liste", ["```\n$ ls\nfichier.txt\n```"]),
    ("message non chaîne : nombre", 3),
    ("message non chaîne : null", None),
    ("message non chaîne : objet", {"message": "```\n$ ls\nfichier.txt\n```"}),
)


def controle_gram_01(ctx, script):
    """Messages acceptés (fonction extraite du hook du dossier jugé) ; de bout en bout : un rapport conforme d'un producteur doté de Bash passe sur
    copie armée (silence, aucune ligne au journal)."""
    chemin = os.path.join(_dossier(ctx, script), "planning-hook.sh")
    f = fonctions_grammaire(chemin)["sortie_brute_presente"]
    fautes = []
    for nom, message in ACCEPTES:
        if f(message) is not True:
            fautes.append("accepté attendu : %s (%r) — rendu %r" % (nom, message, f(message)))
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = fabriquer_lab(ctx, "gram-01")
    for nom, message in (ACCEPTES[1], ACCEPTES[4]):
        cache = dossier_neuf(ctx, "cache-gram-01")
        rc, out, err = jouer_handback(ctx, d, lab, "producteur-bash", message, cache=cache)
        if classer(rc, out) != "silence" or err or lignes_journal(cache):
            fautes.append("bout en bout (%s) : silence attendu — obtenu %s %s" % (nom, classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "%d messages acceptés par la fonction du hook (``` et ~~~, fermeture plus longue, étiquette, prose et autres blocs, lignes vides, bloc "
                          "indenté, CRLF) ; de bout en bout (~~~ puis ```sh) : silence sur copie armée" % len(ACCEPTES))


def controle_gram_02(ctx, script):
    """Jumeaux négatifs refusés par la fonction extraite du hook du dossier jugé ; de bout en bout : un rapport non conforme d'un producteur doté de
    Bash est refusé sur copie armée (UN deny `[planning-core] G4P :`), y compris un message non chaîne."""
    chemin = os.path.join(_dossier(ctx, script), "planning-hook.sh")
    f = fonctions_grammaire(chemin)["sortie_brute_presente"]
    fautes = []
    for nom, message in REFUSES:
        if f(message) is not False:
            fautes.append("refus attendu : %s (%r) — rendu %r" % (nom, message, f(message)))
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = fabriquer_lab(ctx, "gram-02")
    for nom, message in (REFUSES[1], REFUSES[4], REFUSES[19], REFUSES[20], ("message absent du tool_input", ABSENT)):
        rc, out, err = jouer_handback(ctx, d, lab, "producteur-bash", message)
        v = classer(rc, out)
        if v != "deny" or err or not raison_de(out).startswith("[planning-core] G4P :"):
            fautes.append("bout en bout (%r) : deny G4P attendu — obtenu %s %s" % (message if message is not ABSENT else "<absent>", v, court(out)))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "%d jumeaux négatifs refusés par la fonction du hook (sans `$ `, sans sortie, deux commandes, non fermé, `$ls`, `$ ` + blancs, sortie hors "
                          "du bloc, commande après du texte, fermeture d'un autre caractère ou plus courte, message non chaîne) ; de bout en bout : deny G4P "
                          "(commande sans sortie, bloc non fermé, liste, nombre, message absent)" % len(REFUSES))


# =================================================================================================
# G4′ de bout en bout : observe puis armée
# =================================================================================================
RAPPORT_SANS_PREUVE = "J'ai terminé le travail, tout fonctionne."
RAPPORT_AVEC_PREUVE = "Travail terminé.\n```\n$ pytest -q\n3 passed in 0.12s\n```\n"


def controle_g4p_01(ctx, script):
    """Copie observe, lab adhérent, producteur doté de Bash, SubagentHandback sans sortie brute : silence, code 0, UNE ligne gate=G4P au journal ;
    avec sortie brute : aucune ligne."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "g4p-01")
    for agent in ("producteur-bash", "worker-bash"):
        cache = dossier_neuf(ctx, "cache-g4p-01")
        rc, out, err = jouer_handback(ctx, d, lab, agent, RAPPORT_SANS_PREUVE, cache=cache)
        lignes = lignes_journal(cache)
        if rc != 0 or out != b"" or err:
            return False, "%s sans preuve : rc=%d stdout=%s stderr=%s" % (agent, rc, court(out), court(err))
        if len(lignes) != 1:
            return False, "%s sans preuve : %d ligne(s) au journal (attendu 1)" % (agent, len(lignes))
        for motif in ("  gate=G4P  ", "  chemin=agents/" + agent + "  ", "  outil=SubagentHandback  "):
            if motif not in lignes[0]:
                return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
        cache = dossier_neuf(ctx, "cache-g4p-01b")
        rc, out, err = jouer_handback(ctx, d, lab, agent, RAPPORT_AVEC_PREUVE, cache=cache)
        if rc != 0 or out != b"" or err or lignes_journal(cache):
            return False, "%s avec preuve : rc=%d stdout=%s lignes=%s" % (agent, rc, court(out), lignes_journal(cache))
    return True, "copie observe : silence, code 0, UNE ligne gate=G4P (chemin agents/<agent>, outil SubagentHandback) sans sortie brute, aucune avec"


def controle_g4p_02(ctx, script):
    """Copie armée, même cas : UN deny `[planning-core] G4P :` qui nomme l'agent et la marche à suivre, journal d'observation vide ; avec sortie brute :
    passage."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = fabriquer_lab(ctx, "g4p-02")
    fautes = []
    for agent in ("producteur-bash", "worker-bash"):
        cache = dossier_neuf(ctx, "cache-g4p-02")
        rc, out, err = jouer_handback(ctx, d, lab, agent, RAPPORT_SANS_PREUVE, cache=cache)
        v = classer(rc, out)
        if v != "deny" or err or len(out.splitlines()) != 1:
            fautes.append("%s sans preuve : %s stderr=%s %s" % (agent, v, court(err), court(out)))
            continue
        raison = raison_de(out)
        manque = [m for m in ("[planning-core] G4P :", agent, "sortie de commande brute", "$ <commande>", "deroger-gate.sh --gate=G4P --chemin=agents/" + agent)
                  if m not in raison]
        if manque:
            fautes.append("%s : la raison ne porte pas %s : %s" % (agent, manque, raison))
        fautes.extend("%s : %s" % (agent, f) for f in fautes_de_message(raison, lab))
        if lignes_journal(cache):
            fautes.append("%s : un refus a écrit au journal d'observation" % agent)
        rc, out, err = jouer_handback(ctx, d, lab, agent, RAPPORT_AVEC_PREUVE)
        if classer(rc, out) != "silence" or err:
            fautes.append("%s avec preuve : silence attendu — obtenu %s %s" % (agent, classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "copie armée : UN deny « [planning-core] G4P : » qui nomme l'agent, la sortie de commande brute, « $ <commande> » et la dérogation "
                          "nominative (agents/<agent>) ; aucun chemin absolu ; avec sortie brute : silence")


# =================================================================================================
# Périmètre, repli SubagentStop, dérogation, erreur interne, lab dev
# =================================================================================================
def jouer_stop(ctx, dossier_hook, lab, agent_type, message, cache=None, agent_id="agent-test", mode="default"):
    extra = {"XDG_CACHE_HOME": cache} if cache else None
    return ctx.lancer(payload_stop(lab, agent_type, message, agent_id=agent_id, mode=mode), cwd=lab, dossier=dossier_hook, extra_env=extra)


def raison_block(out):
    return json.loads(out.decode("utf-8"))["reason"]


def controle_g4p_03(ctx, script):
    """Périmètre (copie armée, rapport sans sortie brute) : juge et manager qui ont Bash, worker et producteur sans Bash (champ `tools:` sans Bash, ou
    Bash dans `disallowedTools`), allowlist illisible, définition illisible, agent inconnu, fil principal, `agent_type` vide, `agent_id` absent ou vide ->
    aucun refus de G4P (PreToolUse et SubagentStop) ; worker doté de Bash, producteur sans champ `tools:`, formes `Bash(…)`, liste en ligne et en puces
    -> refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = fabriquer_lab(ctx, "g4p-03")
    fautes = []
    for agent in HORS_PERIMETRE:
        for nom, jouer in (("SubagentHandback", jouer_handback), ("SubagentStop", jouer_stop)):
            rc, out, err = jouer(ctx, d, lab, agent, RAPPORT_SANS_PREUVE)
            if classer(rc, out) != "silence" or err:
                fautes.append("hors périmètre %s %s : silence attendu — obtenu %s %s" % (agent, nom, classer(rc, out), court(out)))
    anonymes = (("fil principal (ni agent_id ni agent_type)", None, "agent-test"), ("agent_type vide", "", "agent-test"),
                ("agent_id absent", "producteur-bash", None), ("agent_id vide", "producteur-bash", ""))
    for libelle, agent, ident in anonymes:
        for nom, jouer in (("SubagentHandback", jouer_handback), ("SubagentStop", jouer_stop)):
            rc, out, err = jouer(ctx, d, lab, agent, RAPPORT_SANS_PREUVE, agent_id=ident)
            if classer(rc, out) != "silence" or err:
                fautes.append("%s %s : silence attendu — obtenu %s %s" % (libelle, nom, classer(rc, out), court(out)))
    for agent in DANS_PERIMETRE:
        rc, out, err = jouer_handback(ctx, d, lab, agent, RAPPORT_SANS_PREUVE)
        if classer(rc, out) != "deny" or err or not raison_de(out).startswith("[planning-core] G4P :") or agent not in raison_de(out):
            fautes.append("dans le périmètre %s SubagentHandback : deny G4P attendu — obtenu %s %s" % (agent, classer(rc, out), court(out)))
        rc, out, err = jouer_stop(ctx, d, lab, agent, RAPPORT_SANS_PREUVE)
        if classer(rc, out) != "block" or err or not raison_block(out).startswith("[planning-core] G4P :"):
            fautes.append("dans le périmètre %s SubagentStop : block G4P attendu — obtenu %s %s" % (agent, classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "hors périmètre, aucun refus aux deux événements : %s ; fil principal, agent_type vide, agent_id absent ou vide ; dans le périmètre, refus aux deux "
                          "événements : %s" % (", ".join(HORS_PERIMETRE), ", ".join(DANS_PERIMETRE)))


def controle_g4p_04(ctx, script):
    """SubagentStop hors mode auto (`default`, `acceptEdits`, `plan`, `permission_mode` absent), producteur doté de Bash, rapport sans sortie brute
    (ou `last_assistant_message` absent, ou non chaîne), copie armée : UN objet `{"decision":"block","reason":…}` sur stdout, code 0, stderr vide,
    jamais le code 2 ; avec sortie brute : silence ; copie observe : silence et UNE ligne gate=G4P (outil SubagentStop)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = fabriquer_lab(ctx, "g4p-04")
    fautes = []
    for mode in ("default", "acceptEdits", "plan", None):
        rc, out, err = jouer_stop(ctx, d, lab, "producteur-bash", RAPPORT_SANS_PREUVE, mode=mode)
        if rc != 0 or classer(rc, out) != "block" or err or len(out.splitlines()) != 1:
            fautes.append("mode %s : block en code 0 attendu — obtenu rc=%d %s %s" % (mode, rc, classer(rc, out), court(out)))
            continue
        raison = raison_block(out)
        manque = [m for m in ("[planning-core] G4P :", "producteur-bash", "sortie de commande brute", "$ <commande>",
                              "deroger-gate.sh --gate=G4P --chemin=agents/producteur-bash") if m not in raison]
        if manque:
            fautes.append("mode %s : la raison ne porte pas %s : %s" % (mode, manque, raison))
        fautes.extend("mode %s : %s" % (mode, f) for f in fautes_de_message(raison, lab))
    # le cœur seul (sans la couche shell de la commande, qui masquerait un code 2 en silence) : decision block, code 0
    direct = subprocess.run(["bash", os.path.join(d, "planning-hook.sh")], input=payload_stop(lab, "producteur-bash", RAPPORT_SANS_PREUVE),
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=lab, env=ctx.env(), timeout=120)
    if direct.returncode != 0 or direct.stderr or classer(direct.returncode, direct.stdout) != "block":
        fautes.append("cœur seul : decision block, code 0 (jamais 2) attendus — obtenu rc=%d %s %s" % (direct.returncode, classer(direct.returncode, direct.stdout), court(direct.stdout)))
    for libelle, message in (("last_assistant_message absent", ABSENT), ("last_assistant_message liste", [RAPPORT_AVEC_PREUVE]), ("last_assistant_message null", None)):
        rc, out, err = jouer_stop(ctx, d, lab, "producteur-bash", message)
        if rc != 0 or classer(rc, out) != "block" or err:
            fautes.append("%s : block attendu (aucune preuve) — obtenu rc=%d %s %s" % (libelle, rc, classer(rc, out), court(out)))
    rc, out, err = jouer_stop(ctx, d, lab, "producteur-bash", RAPPORT_AVEC_PREUVE)
    if classer(rc, out) != "silence" or err:
        fautes.append("avec sortie brute : silence attendu — obtenu %s %s" % (classer(rc, out), court(out)))
    o = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g4p-04")
    rc, out, err = jouer_stop(ctx, o, lab, "producteur-bash", RAPPORT_SANS_PREUVE, cache=cache)
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=G4P  " not in lignes[0] or "  outil=SubagentStop  " not in lignes[0]:
        fautes.append("copie observe : silence et une ligne gate=G4P (outil SubagentStop) attendus — obtenu rc=%d %s lignes=%s" % (rc, court(out), lignes))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "SubagentStop hors mode auto (default, acceptEdits, plan, absent) : un seul objet decision block + reason, code 0, stderr vide, jamais le code 2 ; "
                          "message absent, liste ou null : block ; avec sortie brute : silence ; copie observe : silence et une ligne gate=G4P")


def controle_g4p_05(ctx, script):
    """Mode auto : SubagentStop avec `permission_mode: "auto"`, même rapport sans preuve -> silence et AUCUNE ligne de journal, copie armée comme copie
    observe (le rapport a déjà passé le PreToolUse de SubagentHandback) ; le PreToolUse de SubagentHandback, lui, juge en mode auto (deny armé)."""
    lab = fabriquer_lab(ctx, "g4p-05")
    fautes = []
    for valeur in ("armed", "observe"):
        d = ctx.copie_forcee(_dossier(ctx, script), valeur)
        cache = dossier_neuf(ctx, "cache-g4p-05")
        rc, out, err = jouer_stop(ctx, d, lab, "producteur-bash", RAPPORT_SANS_PREUVE, cache=cache, mode="auto")
        if rc != 0 or out != b"" or err or lignes_journal(cache):
            fautes.append("copie %s, mode auto : silence et aucune ligne attendus — obtenu rc=%d %s lignes=%s" % (valeur, rc, court(out), lignes_journal(cache)))
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    rc, out, err = jouer_handback(ctx, d, lab, "producteur-bash", RAPPORT_SANS_PREUVE, mode="auto")
    if classer(rc, out) != "deny" or not raison_de(out).startswith("[planning-core] G4P :"):
        fautes.append("SubagentHandback en mode auto, copie armée : deny G4P attendu — obtenu %s %s" % (classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "mode auto : SubagentStop muet, aucune ligne de journal (copie armée et copie observe) ; SubagentHandback en mode auto : deny G4P")


def _consommees(lab, gate, ident):
    journal = os.path.join(lab, ".planning", "derogations-gates.log")
    if not os.path.exists(journal):
        return 0
    return len([l for l in open(journal, encoding="utf-8").read().split("\n") if "  consommee  id=%d  gate=%s  " % (ident, gate) in l])


def deroger(ctx, lab, gate, chemins):
    args = ["--lab=" + lab, "--gate=" + gate] + ["--chemin=" + c for c in chemins]
    args += ["--qui=willy", "--canal=AskUserQuestion session principale", "--date=2026-10-05", "--raison=cas de test de la dérogation"]
    p = subprocess.run(["bash", os.path.join(ctx.scripts_dir, "deroger-gate.sh")] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env(), cwd=ctx.work, timeout=120)
    return p.returncode, p.stdout, p.stderr


def controle_g4p_06(ctx, script):
    """Dérogation nominative `--gate=G4P --chemin=agents/<agent_type>` : le premier rapport sans preuve passe (cité au PreToolUse, consommée au journal),
    le rapport suivant est refusé (usage unique) ; même cycle au repli SubagentStop (passage, dérogation consommée, second rapport bloqué)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    lab = fabriquer_lab(ctx, "g4p-06")
    rc, out, err = deroger(ctx, lab, "G4P", ("agents/producteur-bash",))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    r1 = jouer_handback(ctx, d, lab, "producteur-bash", RAPPORT_SANS_PREUVE)
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        fautes.append("SubagentHandback, premier rapport : citation attendue — obtenu %s %s" % (classer(r1[0], r1[1]), court(r1[1])))
    else:
        texte = json.loads(r1[1].decode("utf-8"))["hookSpecificOutput"]["additionalContext"]
        manque = [m for m in ("#1", "G4P", "willy", "AskUserQuestion session principale", "2026-10-05", "agents/producteur-bash") if m not in texte]
        if manque or _consommees(lab, "G4P", 1) != 1:
            fautes.append("citation sans %s ; lignes consommee : %d" % (manque, _consommees(lab, "G4P", 1)))
    r2 = jouer_handback(ctx, d, lab, "producteur-bash", RAPPORT_SANS_PREUVE)
    if classer(r2[0], r2[1]) != "deny":
        fautes.append("SubagentHandback, second rapport : deny attendu (usage unique) — obtenu %s" % classer(r2[0], r2[1]))
    lab2 = fabriquer_lab(ctx, "g4p-06-stop")
    rc, out, err = deroger(ctx, lab2, "G4P", ("agents/producteur-bash",))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario (SubagentStop) : rc=%d %s" % (rc, court(err))
    s1 = jouer_stop(ctx, d, lab2, "producteur-bash", RAPPORT_SANS_PREUVE)
    if classer(s1[0], s1[1]) != "silence" or s1[2] or _consommees(lab2, "G4P", 1) != 1:
        fautes.append("SubagentStop, premier rapport : passage et dérogation consommée attendus — obtenu %s consommées=%d" % (classer(s1[0], s1[1]), _consommees(lab2, "G4P", 1)))
    s2 = jouer_stop(ctx, d, lab2, "producteur-bash", RAPPORT_SANS_PREUVE)
    if classer(s2[0], s2[1]) != "block":
        fautes.append("SubagentStop, second rapport : block attendu (usage unique) — obtenu %s" % classer(s2[0], s2[1]))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "dérogation G4P sur agents/producteur-bash : premier rapport cité et dérogation consommée, second refusé (PreToolUse) ; au repli SubagentStop : "
                          "passage, consommée, second bloqué")


def controle_g4p_07(ctx, script):
    """Erreur interne injectée : (a) dans evaluer_g4p (sonde sur la ligne du verdict), (b) dans le mode SubagentStop lui-même (faute au retour sans
    verdict) ; copie armée : deny « erreur interne du gate » en PreToolUse (a), block en SubagentStop (a et b) ; copie observe : aucune sortie et une
    ligne d'observation qui porte l'erreur."""
    fautes = []
    sonde, raison = make_hook_mutant(ctx, "G4P-SONDE", "# g4p-verdict", 'raise RuntimeError("sonde")  # g4p-verdict')
    if sonde is None:
        return False, "mutant sonde invalide : " + raison
    mode, raison = make_hook_mutant(ctx, "G4P-MODE", "return None  # evt-mode-subagentstop", 'raise RuntimeError("faute injectee")')
    if mode is None:
        return False, "mutant du mode invalide : " + raison
    lab = fabriquer_lab(ctx, "g4p-07")
    # (a) sonde dans evaluer_g4p : le rapport est sans preuve, donc le verdict est atteint
    arme, observe = ctx.copie_forcee(sonde, "armed"), ctx.copie_forcee(sonde, "observe")
    rc, out, err = jouer_handback(ctx, arme, lab, "producteur-bash", RAPPORT_SANS_PREUVE)
    if classer(rc, out) != "deny" or "erreur interne du gate" not in raison_de(out) or not raison_de(out).startswith("[planning-core] G4P :"):
        fautes.append("sonde, armée, SubagentHandback : deny « erreur interne du gate » attendu — obtenu %s %s" % (classer(rc, out), court(out)))
    rc, out, err = jouer_stop(ctx, arme, lab, "producteur-bash", RAPPORT_SANS_PREUVE)
    if classer(rc, out) != "block" or "erreur interne du gate" not in raison_block(out):
        fautes.append("sonde, armée, SubagentStop : block « erreur interne du gate » attendu — obtenu %s %s" % (classer(rc, out), court(out)))
    for nom, jouer in (("SubagentHandback", jouer_handback), ("SubagentStop", jouer_stop)):
        cache = dossier_neuf(ctx, "cache-g4p-07")
        rc, out, err = jouer(ctx, observe, lab, "producteur-bash", RAPPORT_SANS_PREUVE, cache=cache)
        lignes = lignes_journal(cache)
        motif = [c for c in lignes[0].split("  ") if c.startswith("raison=")] if lignes else []
        if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=G4P  " not in lignes[0] or not motif \
                or "erreur interne" not in urllib.parse.unquote(motif[0]):
            fautes.append("sonde, observe, %s : aucune sortie et une ligne d'erreur attendues — obtenu rc=%d %s lignes=%s" % (nom, rc, court(out), lignes))
    # (b) faute dans le mode SubagentStop : rapport AVEC preuve, le retour sans verdict est atteint
    arme, observe = ctx.copie_forcee(mode, "armed"), ctx.copie_forcee(mode, "observe")
    rc, out, err = jouer_stop(ctx, arme, lab, "producteur-bash", RAPPORT_AVEC_PREUVE)
    if rc != 0 or classer(rc, out) != "block" or "erreur interne du gate" not in raison_block(out):
        fautes.append("faute du mode, armée : block « erreur interne du gate », code 0 attendu — obtenu rc=%d %s %s" % (rc, classer(rc, out), court(out)))
    cache = dossier_neuf(ctx, "cache-g4p-07b")
    rc, out, err = jouer_stop(ctx, observe, lab, "producteur-bash", RAPPORT_AVEC_PREUVE, cache=cache)
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=G4P  " not in lignes[0]:
        fautes.append("faute du mode, observe : aucune sortie et une ligne gate=G4P attendues — obtenu rc=%d %s lignes=%s" % (rc, court(out), lignes))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "erreur interne de G4′ : armée, deny en PreToolUse et block en SubagentStop (sonde du gate, faute du mode) ; observe, aucune sortie et une ligne "
                          "d'observation qui porte l'erreur")


def controle_g4p_08(ctx, script):
    """Lab dev (planning_version hors cycles-v1) : le rapport sans sortie d'un producteur doté de Bash, au PreToolUse de SubagentHandback et au repli
    SubagentStop, copie armée -> stdout d'octet vide, code 0, stderr vide."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = fabriquer_lab(ctx, "g4p-08-dev", adherent=False)
    fautes = []
    for nom, jouer in (("SubagentHandback", jouer_handback), ("SubagentStop", jouer_stop)):
        for agent in ("producteur-bash", "worker-bash"):
            rc, out, err = jouer(ctx, d, lab, agent, RAPPORT_SANS_PREUVE)
            if rc != 0 or out != b"" or err:
                fautes.append("lab dev, %s de %s : stdout vide, code 0 attendus — obtenu rc=%d %s %s" % (nom, agent, rc, court(out), court(err)))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "lab dev : SubagentHandback et SubagentStop d'un producteur et d'un worker dotés de Bash, sans sortie brute -> stdout d'octet vide, code 0, copie armée")


# =================================================================================================
# Canary de session : cas G4P-handback et G4P-stop (R-CANG-G4P)
# =================================================================================================
EVENEMENTS_CABLES = ("PreToolUse", "SubagentStop", "CwdChanged", "FileChanged", "SessionStart")


def dossier_canary(ctx, valeur, hook=None):
    """`<projet>/.claude/scripts` jetable (forme du scope projet) : check-gates-alive.sh du dépôt et planning-hook.sh (celui de `hook`, à défaut le réel)
    dont les huit constantes ARMEMENT_* valent `valeur` (`observe` ou `armed`) ; `valeur` None : le hook n'est pas réécrit (l'état livré)."""
    texte = open(os.path.join(hook or ctx.scripts_dir, "planning-hook.sh"), encoding="utf-8").read()
    if valeur is not None:
        texte, n = re.subn(REGEX_ARMEMENT, r'\1"' + valeur + '"', texte, flags=re.M)
        if n != 8:
            raise RuntimeError("huit constantes ARMEMENT_* attendues, %d trouvée(s)" % n)
    d = os.path.join(ctx.unique("projet-canary-" + str(valeur)), ".claude", "scripts")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
        fh.write(texte)
    shutil.copy(os.path.join(ctx.scripts_dir, "check-gates-alive.sh"), os.path.join(d, "check-gates-alive.sh"))
    for nom in ("planning-hook.sh", "check-gates-alive.sh"):
        os.chmod(os.path.join(d, nom), 0o755)
    return d


def lancer_canary(ctx, d):
    """Lance le check-gates-alive.sh de `d` dans une session adhérente, `--settings` vers un réglage jetable qui porte la commande de référence
    (hooks.json, scope projet) sous les cinq événements."""
    if TOKEN not in (ctx.cmd or ""):
        raise RuntimeError("la commande enregistrée ne porte pas le jeton " + TOKEN)
    projet = os.path.dirname(os.path.dirname(d))
    lab = ctx.unique("session-canary")
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    commande = ctx.cmd.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts')
    hooks = {}
    for evt in EVENEMENTS_CABLES:
        groupe = {"hooks": [{"type": "command", "command": commande}]}
        if evt == "PreToolUse":
            groupe["matcher"] = "Write"
        hooks[evt] = [groupe]
    reglage = os.path.join(ctx.unique("reglage-canary"), "settings.json")
    ecrire(reglage, json.dumps({"hooks": hooks}))
    p = subprocess.run(["bash", os.path.join(d, "check-gates-alive.sh"), "--settings=" + reglage], input=json.dumps({"cwd": lab}).encode("utf-8"),
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, env={"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": ctx.home, "CLAUDE_PROJECT_DIR": projet},
                       cwd=lab, timeout=240)
    return p.returncode, p.stdout, p.stderr


def controle_cang_g4p(ctx, script):
    """R-CANG-G4P : le check-gates-alive.sh du dépôt porte `G4P-handback` et `G4P-stop` (producteur synthétique `canary-producteur`, doté de Bash) ;
    état livré (G4P en observe) : cas en observation, code 3, stdout vide ; copie armée (toutes les étapes) : deny pour le premier, block pour le
    second, code 3 ; copie où evaluer_g4p ne rend jamais de verdict : signal (code 0, UNE ligne) qui nomme G4P-handback et G4P-stop, observe comme armée."""
    chemin = os.path.join(ctx.scripts_dir, "check-gates-alive.sh")
    texte = open(chemin, encoding="utf-8").read()
    fautes = []
    for cas in ('"G4P-handback|G4P|nominal|SubagentHandback:sans-sortie@" + AGENT_PRODUCTEUR + "|"', '"G4P-stop|G4P|nominal|SubagentStop:sans-sortie@" + AGENT_PRODUCTEUR + "|"'):
        if texte.count(cas) != 1:
            fautes.append("le cas %s n'est pas (une seule fois) dans CANARIS" % cas)
    if "canary-producteur" not in texte or "tools: Read, Bash" not in texte:
        fautes.append("la définition du producteur synthétique doté de Bash (canary-producteur) n'est pas dans DEFINITIONS_CANARY")
    if fautes:
        return False, "; ".join(fautes)
    dossier = _dossier(ctx, script)
    rc, out, err = lancer_canary(ctx, dossier_canary(ctx, None, hook=dossier))
    if rc != 3 or out != b"":
        fautes.append("état livré : code 3 et stdout vide attendus — obtenu rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    rc, out, err = lancer_canary(ctx, dossier_canary(ctx, "observe", hook=dossier))
    if rc != 3 or out != b"":
        fautes.append("copie observe : code 3 et stdout vide attendus (les deux cas trouvent leur ligne d'observation) — obtenu rc=%d stdout=%s" % (rc, court(out)))
    rc, out, err = lancer_canary(ctx, dossier_canary(ctx, "armed", hook=dossier))
    if rc != 3 or out != b"":
        fautes.append("copie armée : code 3 et stdout vide attendus (deny pour G4P-handback, block pour G4P-stop) — obtenu rc=%d stdout=%s" % (rc, court(out)))
    neutre, raison = make_hook_mutant(ctx, "G4P-NEUTRE", "# g4p-verdict", "return []  # g4p-verdict")
    if neutre is None:
        return False, "mutant du hook invalide : " + raison
    for valeur in ("observe", "armed"):
        rc, out, err = lancer_canary(ctx, dossier_canary(ctx, valeur, hook=neutre))
        lignes = [l for l in out.decode("utf-8", "replace").split("\n") if l]
        if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "G4P-handback" not in lignes[0] \
                or "G4P-stop" not in lignes[0] or "G6-principal" in lignes[0] or "G1-sans-cadrage" in lignes[0]:
            fautes.append("evaluer_g4p neutralisé (%s) : code 0 et une ligne qui nomme G4P-handback et G4P-stop attendus — obtenu rc=%d %s" % (valeur, rc, court(out)))
    return (not fautes), ("; ".join(fautes[:4]) if fautes else
                          "canary : état livré et copie observe, code 3 (les cas G4P-handback et G4P-stop trouvent leur ligne d'observation) ; copie armée, code 3 (deny puis "
                          "block) ; evaluer_g4p neutralisé : code 0 et une ligne qui nomme G4P-handback et G4P-stop, observe comme armée")


# --- Mutants --------------------------------------------------------------------------------------------------------
def original_de(ctx, ident, controle):
    """Résultat d'un contrôle sur le script réel, calculé une seule fois (les sections et les mutants lisent la même exécution)."""
    if ident not in ctx.originaux:
        ctx.originaux[ident] = controle(ctx, ctx.scripts_dir)
    return ctx.originaux[ident]


def tuer(ctx, ident, motif, remplacement, id_controle, controle):
    """Preuve d'opposabilité : le contrôle passe sur l'original, le témoin est inchangé sous le mutant, le contrôle rougit sous le mutant."""
    dossier, raison = make_hook_mutant(ctx, ident, motif, remplacement)
    if dossier is None:
        komut(ident, "mutant du cœur valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
        return
    original = original_de(ctx, id_controle, controle)
    t_orig, t_mut = controle_temoin(ctx, ctx.scripts_dir), controle_temoin(ctx, dossier)
    mutant = controle(ctx, dossier)
    if not original[0]:
        komut(ident, "l'original passe %s (garde du témoin de la mutation)" % id_controle, "conforme", original[1])
    elif t_orig != t_mut:
        komut(ident, "témoin (Write neutre d'un lab adhérent) inchangé sous le mutant", str(t_orig), str(t_mut))
    elif mutant[0]:
        komut(ident, "%s rougit sous le mutant" % id_controle, "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
    else:
        okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s · témoin inchangé" % (id_controle, original[1], mutant[1]))


def sec_gram(ctx):
    for ident, ctrl, titre in (
            ("R-G4P-GRAM-01", controle_gram_01, "grammaire, messages acceptés"),
            ("R-G4P-GRAM-02", controle_gram_02, "grammaire, jumeaux négatifs refusés")):
        bon, detail = original_de(ctx, ident, ctrl)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_base(ctx):
    for ident, ctrl, titre in (
            ("R-G4P-01", controle_g4p_01, "copie observe, rapport sans sortie brute : une ligne gate=G4P"),
            ("R-G4P-02", controle_g4p_02, "copie armée, rapport sans sortie brute : un deny")):
        bon, detail = original_de(ctx, ident, ctrl)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_stop(ctx):
    for ident, ctrl, titre in (
            ("R-G4P-03", controle_g4p_03, "périmètre : juges, managers, agents sans Bash, fil principal, agent inconnu ou illisible exclus"),
            ("R-G4P-04", controle_g4p_04, "SubagentStop hors mode auto : decision block, code 0, jamais le code 2"),
            ("R-G4P-05", controle_g4p_05, "mode auto : SubagentStop n'évalue rien"),
            ("R-G4P-06", controle_g4p_06, "dérogation nominative à usage unique"),
            ("R-G4P-07", controle_g4p_07, "erreur interne : armée refuse, observe observe"),
            ("R-G4P-08", controle_g4p_08, "lab dev : octet vide")):
        bon, detail = original_de(ctx, ident, ctrl)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_canary(ctx):
    bon, detail = original_de(ctx, "R-CANG-G4P", controle_cang_g4p)
    ok("R-CANG-G4P " + detail) if bon else ko("R-CANG-G4P", "le canary porte G4P-handback et G4P-stop et les rejoue comme la table le dérive", "conforme", detail)


def sec_mutants_stop(ctx):
    tuer(ctx, "G4P-AUTO", "# g4p-auto", "if False:  # g4p-auto", "R-G4P-05", controle_g4p_05)
    tuer(ctx, "G4P-ROLE", "# g4p-perimetre", "if definition is None:  # g4p-perimetre", "R-G4P-03", controle_g4p_03)
    tuer(ctx, "G4P-CAPACITE", "# g4p-capacite", "if False:  # g4p-capacite", "R-G4P-03", controle_g4p_03)
    tuer(ctx, "G4P-CODE2", "                sortie_blocage_subagent(raisons)", "sortie_blocage_subagent(raisons); os._exit(2)", "R-G4P-04", controle_g4p_04)
    # Adhésion forcée vraie : la sortie silencieuse d'un lab non adhérent retirée (la commande rejouée n'a pas son pré-filtre, `cmd_np`)
    tuer(ctx, "G4P-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-G4P-08", controle_g4p_08)


def sec_mutants_gram(ctx):
    tuer(ctx, "G4P-GRAMMAIRE", "# g4p-sortie", "etape = 3  # g4p-sortie", "R-G4P-GRAM-02", controle_gram_02)
    tuer(ctx, "G4P-FERMETURE", "# g4p-fermeture", "return etape == 3  # g4p-fermeture", "R-G4P-GRAM-02", controle_gram_02)


def sec_mutants_base(ctx):
    tuer(ctx, "G4P-VERDICT", "# g4p-verdict", "return []  # g4p-verdict", "R-G4P-01", controle_g4p_01)


SECTIONS = {
    "gram": sec_gram,
    "base": sec_base,
    "stop": sec_stop,
    "canary": sec_canary,
    "mutants_gram": sec_mutants_gram,
    "mutants_base": sec_mutants_base,
    "mutants_stop": sec_mutants_stop,
}


def main():
    scripts_dir, hooks_json, work, settings_lab = sys.argv[2:6]
    ctx = Ctx(scripts_dir, hooks_json or None, work, settings_lab or None)
    if ctx.charger_commande() is None:
        ko("commande enregistrée", "la commande enregistrée est lisible (une seule entrée PreToolUse portant planning-hook.sh)",
           "1 commande", "introuvable dans " + str(hooks_json or settings_lab or "aucune source"))
        sys.exit(1)
    for nom in sys.argv[1].split(","):
        SECTIONS[nom](ctx)


main()
PY_AIDES_G4P_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-g4p.txt"
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
  run_sections "${VF_G4P_SECTIONS:-gram,base,stop,canary,mutants_gram,mutants_base,mutants_stop}"
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
