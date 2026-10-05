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
# Mutants (chacun tué par un contrôle, trace assertion · attendu (original) · obtenu (mutant)) :
#   MUT-G4P-GRAMMAIRE (la ligne qui suit la commande n'est plus jugée -> R-G4P-GRAM-02), MUT-G4P-FERMETURE (un bloc non fermé compte -> R-G4P-GRAM-02),
#   MUT-G4P-VERDICT (evaluer_g4p ne rend jamais de verdict -> R-G4P-01).
# Variables : VF_G4P_SECTIONS=<liste> pour ne rejouer qu'une partie (sections : gram, base, mutants_gram, mutants_base).
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
import subprocess
import sys

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
    "producteur-bash": def_agent("producteur-bash", tools="Read, Bash"),
    "worker-bash": def_agent("worker-bash", tools="Read, Bash", interne=True),
}


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


def jouer_handback(ctx, dossier_hook, lab, agent_type, message, cache=None, agent_id="agent-test"):
    extra = {"XDG_CACHE_HOME": cache} if cache else None
    return ctx.lancer(payload_handback(lab, agent_type, message, agent_id=agent_id), cwd=lab, dossier=dossier_hook, extra_env=extra)


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


def sec_mutants_gram(ctx):
    tuer(ctx, "G4P-GRAMMAIRE", "# g4p-sortie", "etape = 3  # g4p-sortie", "R-G4P-GRAM-02", controle_gram_02)
    tuer(ctx, "G4P-FERMETURE", "# g4p-fermeture", "return etape == 3  # g4p-fermeture", "R-G4P-GRAM-02", controle_gram_02)


def sec_mutants_base(ctx):
    tuer(ctx, "G4P-VERDICT", "# g4p-verdict", "return []  # g4p-verdict", "R-G4P-01", controle_g4p_01)


SECTIONS = {
    "gram": sec_gram,
    "base": sec_base,
    "mutants_gram": sec_mutants_gram,
    "mutants_base": sec_mutants_base,
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
  run_sections "${VF_G4P_SECTIONS:-gram,base,mutants_gram,mutants_base}"
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
