#!/usr/bin/env bash
# test-cloture-gates.sh — G3 et G4, les gates de clôture du hook central (Phase 46, 46-05 ; CLOT-01, CLOT-02 ; P46-D-01, P46-D-12).
# Le hook est rejoué PAR LA COMMANDE ENREGISTRÉE (lue dans hooks.json, sous /bin/sh -c), jamais par un appel direct au script (P45-D-20) ;
# les cas de gate tournent sur des COPIES à l'armement FORCÉ (`copie_forcee`), jamais sur l'état livré, qui change à chaque armement.
#
# Familles (G3, Tâche 2 de 46-05) :
#   R-G3-01   copie observe : Write de CLOTURE.md d'une unité dont le PLAN.md voisin déclare un livrable absent -> silence, code 0, UNE ligne gate=G3
#   R-G3-02   copie armée : Write, Edit, NotebookEdit (fil principal et agent inconnu) -> UN deny `[planning-core] G3 :` qui nomme l'entrée ; livrable
#             vide, lien, dossier vide, dossier à .DS_Store seul, lien intermédiaire ; PLAN.md absent, sans ecrit: valide, ecrit: invalide ou qui
#             contient l'unité -> refus (unité indéterminée au modèle) ; casse ignorée ; unité de plan sous plans/ ; aucun chemin absolu ni « no such file »
#   R-G3-03   jumeaux qui passent (copie armée) : livrables présents et non vides (fichier, dossier, dossier avec .DS_Store) ; CLOTURE.md de style GSD,
#             de niveau cycle, nom d'unité invalide, CLOTURE.md.bak, livrable nommé CLOTURE.md hors .planning/ : jamais jugés ; lab dev : octet vide
#   R-G3-04   dérogation nominative G3 sur le chemin du CLOTURE.md (usage unique) ; erreur interne injectée : armée deny, observe ligne d'observation
# Mutants (chacun tué par un contrôle, trace assertion · attendu (original) · obtenu (mutant)) :
#   MUT-G3-LIVRABLE (contrôle du statut neutralisé -> R-G3-02), MUT-G3-FORME (forme élargie à tout CLOTURE.md sous .planning/ -> R-G3-03),
#   MUT-G3-ADHESION (adhésion forcée vraie, commande sans pré-filtre -> jumeau lab dev de R-G3-03).
# Variables : VF_CLOT_SECTIONS=<liste> pour ne rejouer qu'une partie (sections : g3, mutants_g3).
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; `cmp -s` jamais `diff` ; tout le travail fin est fait par
# Python (PYBIN). Lançable depuis tout cwd. Piège CI (`bash -e {0}`) : jamais `cmd && { … }` nu.
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
    else echo "[test-cloture-gates] python3 requis" >&2; exit 1; fi
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

AIDES="$WORK/aides.py"
cat > "$AIDES" <<'PY_AIDES_CLOTURE_EOF'
import json
import os
import re
import stat
import subprocess
import sys
import urllib.parse

TOKEN = "{{VF_SCRIPTS}}"
UNITE = ".planning/cycles/01-c/phases/01-p"
CLOTURE = UNITE + "/CLOTURE.md"
UNITE_PLAN = UNITE + "/plans/01-a"
CLOTURE_PLAN = UNITE_PLAN + "/CLOTURE.md"
LIVRABLE = "livrables/rapport.md"


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


# --- Payload du harnais ------------------------------------------------------------------------------------------
def payload(outil, entree, cwd, agent_type=None, agent_id="agent-test"):
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": cwd,
           "prompt_id": "prompt-test", "permission_mode": "default"}
    if agent_type is not None:
        obj["agent_id"] = agent_id
        obj["agent_type"] = agent_type
    obj["hook_event_name"] = "PreToolUse"
    obj["tool_name"] = outil
    obj["tool_input"] = entree
    obj["tool_use_id"] = "toolu_test"
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def entree_outil(outil, chemin):
    if outil == "NotebookEdit":
        return {"notebook_path": chemin, "new_source": "x"}
    if outil == "Edit":
        return {"file_path": chemin, "old_string": "a", "new_string": "b"}
    return {"file_path": chemin, "content": "x"}


def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)


def classer(rc, out):
    """`silence`, `avertit` (additionalContext sans décision), `deny`, ou `autre:...`."""
    if rc != 0:
        return "autre:rc=%d" % rc
    if out == b"":
        return "silence"
    try:
        s = json.loads(out.decode("utf-8"))["hookSpecificOutput"]
    except (ValueError, KeyError, TypeError, AttributeError):
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


def contexte_de(out):
    return json.loads(out.decode("utf-8"))["hookSpecificOutput"].get("additionalContext", "")


# --- Corps Python du hook, mutants -----------------------------------------------------------------------------------
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


def make_hook_mutant(ctx, ident, motif, remplacement):
    """Copie du hook dont l'UNIQUE ligne portant `motif` (fixe) est remplacée par `remplacement` (indentation conservée) ; `bash -n` et la
    compilation du corps Python extrait doivent passer. Un motif ambigu ou absent, ou un mutant identique, est un KO nommé."""
    original = observe_partout(open(ctx.hook, encoding="utf-8").read())
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


# --- Journaux, labs, dérogation ---------------------------------------------------------------------------------------
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


def fabriquer_lab(ctx, nom, plan="ecrit: " + LIVRABLE, unite=UNITE, fichiers=None, dossiers=(), liens=(), adherent=True, sans_plan=False):
    """Lab jetable : `.planning/config.json` (adhérent cycles-v1, sinon dev), le PLAN.md de `unite` dont le frontmatter est `plan` (une ligne de
    `ecrit:` ou un frontmatter complet si elle commence par `---`), les `fichiers` {chemin: contenu}, les `dossiers` vides et les `liens`
    {chemin: cible}. `sans_plan` : aucun PLAN.md."""
    racine = ctx.unique("lab-" + nom)
    ecrire(os.path.join(racine, ".planning", "config.json"), '{"planning_version": "%s"}' % ("cycles-v1" if adherent else "2.0"))
    if not sans_plan:
        texte = plan if plan.startswith("---") else "---\n" + plan + "\n---\nPlan du cas.\n"
        ecrire(os.path.join(racine, unite, "PLAN.md"), texte)
    for rel, contenu in (fichiers or {}).items():
        ecrire(os.path.join(racine, rel), contenu)
    for rel in dossiers:
        os.makedirs(os.path.join(racine, rel), exist_ok=True)
    for rel, cible in dict(liens).items():
        os.makedirs(os.path.dirname(os.path.join(racine, rel)), exist_ok=True)
        os.symlink(cible, os.path.join(racine, rel))
    return racine


def ecrire_dans(ctx, dossier_hook, lab, outil, rel, agent=None, extra_env=None):
    brut = payload(outil, entree_outil(outil, os.path.join(lab, rel)), lab, agent_type=agent)
    return ctx.lancer(brut, cwd=lab, dossier=dossier_hook, extra_env=extra_env)


def deroger(ctx, lab, gate, chemins):
    args = ["--lab=" + lab, "--gate=" + gate] + ["--chemin=" + c for c in chemins]
    args += ["--qui=willy", "--canal=AskUserQuestion session principale", "--date=2026-10-05", "--raison=cas de test de la dérogation G3"]
    p = subprocess.run(["bash", os.path.join(ctx.scripts_dir, "deroger-gate.sh")] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env(), cwd=ctx.work, timeout=120)
    return p.returncode, p.stdout, p.stderr


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


# =================================================================================================
# G3 : contrôles (chacun rend (conforme, détail) et s'applique à un dossier de scripts : le vrai ou un mutant)
# =================================================================================================
def _dossier(ctx, script):
    return script if script else ctx.scripts_dir


def controle_temoin(ctx, script):
    """Témoin : Write d'une cible neutre d'un lab adhérent -> silence (aucun mutant de G3 ne l'affecte)."""
    lab = fabriquer_lab(ctx, "temoin")
    rc, out, err = ecrire_dans(ctx, _dossier(ctx, script), lab, "Write", ".planning/notes.md")
    return classer(rc, out) == "silence" and not err, classer(rc, out)


def controle_g3_01(ctx, script):
    """Copie observe : Write de CLOTURE.md d'une unité dont le PLAN.md voisin déclare un livrable absent -> silence, code 0, UNE ligne gate=G3."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "g3-01")
    cache = dossier_neuf(ctx, "cache-g3-01")
    rc, out, err = ecrire_dans(ctx, d, lab, "Write", CLOTURE, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    for motif in ("  gate=G3  ", "  chemin=" + CLOTURE + "  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : silence, code 0, une ligne gate=G3 (chemin du CLOTURE.md, outil Write)"


def _refus_g3(ctx, d, lab, outil, rel, agent=None):
    """(conforme, détail, raison) : UN objet deny, `[planning-core] G3 :`, journal d'observation vide."""
    cache = dossier_neuf(ctx, "cache-g3-refus")
    rc, out, err = ecrire_dans(ctx, d, lab, outil, rel, agent=agent, extra_env={"XDG_CACHE_HOME": cache})
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return False, "%s stderr=%s %s" % (v, court(err), court(out)), ""
    raison = raison_de(out)
    if not raison.startswith("[planning-core] G3 :"):
        return False, "raison : " + raison, raison
    if lignes_journal(cache):
        return False, "un refus a écrit au journal d'observation", raison
    return True, "", raison


def controle_g3_02(ctx, script):
    """Copie armée : Write, Edit, NotebookEdit (fil principal et agent inconnu) -> UN deny qui nomme l'entrée ; livrable vide, lien, dossier vide,
    dossier à .DS_Store seul, lien intermédiaire ; PLAN.md absent, sans ecrit: valide, ecrit: invalide, ecrit: qui contient l'unité ; casse ignorée ;
    unité de plan sous plans/ ; aucun chemin absolu ni « no such file »."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    # 1. livrable absent : trois outils, deux identités
    lab = fabriquer_lab(ctx, "g3-02-absent")
    for outil in ("Write", "Edit", "NotebookEdit"):
        for agent in (None, "agent-inconnu"):
            bon, detail, raison = _refus_g3(ctx, d, lab, outil, CLOTURE, agent=agent)
            if not bon:
                fautes.append("absent %s agent=%s : %s" % (outil, agent, detail))
            elif LIVRABLE not in raison or "livrable déclaré absent" not in raison:
                fautes.append("absent %s agent=%s : la raison ne nomme pas l'entrée : %s" % (outil, agent, raison))
            else:
                fautes.extend("absent %s : %s" % (outil, f) for f in fautes_de_message(raison, lab))
    # 2. livrable déclaré mais vide, lien, dossier vide, dossier à .DS_Store seul, lien intermédiaire
    variantes = (
        ("vide", dict(fichiers={LIVRABLE: ""}), "livrable déclaré vide"),
        ("lien", dict(fichiers={"livrables/autre.md": "contenu\n"}, liens={LIVRABLE: "autre.md"}), "livrable déclaré lien"),
        ("dossier-vide", dict(plan="ecrit: livrables", dossiers=("livrables",)), "livrable déclaré vide"),
        ("ds-store", dict(plan="ecrit: livrables", fichiers={"livrables/.DS_Store": "meta\n"}), "livrable déclaré vide"),
        ("lien-intermediaire", dict(plan="ecrit: liens/rapport.md", fichiers={"reel/rapport.md": "contenu\n"}, liens={"liens": "reel"}),
         "livrable déclaré lien"),
    )
    for nom, args, attendu in variantes:
        lab = fabriquer_lab(ctx, "g3-02-" + nom, **args)
        bon, detail, raison = _refus_g3(ctx, d, lab, "Write", CLOTURE)
        if not bon:
            fautes.append("%s : %s" % (nom, detail))
        elif attendu not in raison:
            fautes.append("%s : la raison ne dit pas « %s » : %s" % (nom, attendu, raison))
        else:
            fautes.extend("%s : %s" % (nom, f) for f in fautes_de_message(raison, lab))
    # 3. PLAN.md absent, sans ecrit:, ecrit: invalide, ecrit: qui contient l'unité : refus de modèle indéterminé
    etats = (
        ("plan-absent", dict(sans_plan=True), "PLAN.md de l'unité absent, illisible ou sans ecrit: valide"),
        ("sans-ecrit", dict(plan="titre: sans livrable"), "PLAN.md de l'unité absent, illisible ou sans ecrit: valide"),
        ("ecrit-invalide", dict(plan="ecrit: ../hors-lab.md"), "PLAN.md de l'unité absent, illisible ou sans ecrit: valide"),
        ("ecrit-unite", dict(plan="ecrit: " + UNITE), "ecrit: contient le dossier de l'unité"),
    )
    for nom, args, attendu in etats:
        lab = fabriquer_lab(ctx, "g3-02-" + nom, **args)
        bon, detail, raison = _refus_g3(ctx, d, lab, "Write", CLOTURE)
        if not bon:
            fautes.append("%s : %s" % (nom, detail))
        elif attendu not in raison or "indéterminée au modèle" not in raison:
            fautes.append("%s : la raison ne dit pas « %s » et « indéterminée au modèle » : %s" % (nom, attendu, raison))
        else:
            fautes.extend("%s : %s" % (nom, f) for f in fautes_de_message(raison, lab))
    # 4. casse ignorée, unité de plan sous plans/
    lab = fabriquer_lab(ctx, "g3-02-casse")
    bon, detail, _ = _refus_g3(ctx, d, lab, "Write", UNITE + "/Cloture.MD")
    if not bon:
        fautes.append("casse Cloture.MD : " + detail)
    lab = fabriquer_lab(ctx, "g3-02-plans", unite=UNITE_PLAN)
    bon, detail, raison = _refus_g3(ctx, d, lab, "Write", CLOTURE_PLAN)
    if not bon:
        fautes.append("unité de plan : " + detail)
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "UN deny « [planning-core] G3 : » nommant l'entrée pour Write, Edit, NotebookEdit (fil principal et agent inconnu) ; vide, lien, dossier "
                          "vide, .DS_Store seul, lien intermédiaire, PLAN.md absent, sans ecrit:, ecrit: invalide, ecrit: qui contient l'unité, casse, unité de plan ; "
                          "aucun chemin absolu ni « no such file »")


def controle_g3_03(ctx, script):
    """Copie armée, jumeaux qui passent : livrables présents et non vides ; CLOTURE.md de style GSD, de niveau cycle, nom d'unité invalide,
    CLOTURE.md.bak, livrable nommé CLOTURE.md hors .planning/ : jamais jugés ; lab dev : octet vide."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []

    def passe(nom, lab, outil, rel):
        rc, out, err = ecrire_dans(ctx, d, lab, outil, rel)
        v = classer(rc, out)
        if v not in ("silence", "avertit") or err:
            fautes.append("%s %s : %s %s" % (nom, outil, v, court(out)))
        elif v == "avertit" and "G3" in contexte_de(out):
            fautes.append("%s %s : un avertissement parle de G3 : %s" % (nom, outil, court(out)))

    # livrables présents : fichier, dossier, dossier avec .DS_Store ; trois outils ; unité de plan
    presents = (
        ("fichier", dict(fichiers={LIVRABLE: "contenu\n"})),
        ("dossier", dict(plan="ecrit: livrables", fichiers={"livrables/a.md": "contenu\n"})),
        ("sous-dossier", dict(plan="ecrit: livrables", fichiers={"livrables/sous/a.md": "contenu\n"})),
        ("ds-store", dict(plan="ecrit: livrables", fichiers={"livrables/a.md": "contenu\n", "livrables/.DS_Store": "meta\n"})),
        ("liste", dict(plan="---\necrit:\n  - " + LIVRABLE + "\n  - livrables/autre.md\n---\n", fichiers={LIVRABLE: "a\n", "livrables/autre.md": "b\n"})),
    )
    for nom, args in presents:
        lab = fabriquer_lab(ctx, "g3-03-" + nom, **args)
        for outil in ("Write", "Edit", "NotebookEdit"):
            passe("présent " + nom, lab, outil, CLOTURE)
    lab = fabriquer_lab(ctx, "g3-03-plans", unite=UNITE_PLAN, fichiers={LIVRABLE: "contenu\n"})
    passe("présent, unité de plan", lab, "Write", CLOTURE_PLAN)
    # formes jamais jugées : PLAN.md voisin absent ou à livrable absent, de sorte qu'un G3 trop large refuserait
    lab = fabriquer_lab(ctx, "g3-03-voisins")
    for nom, rel in (("style GSD", ".planning/phases/01-x/CLOTURE.md"), ("niveau cycle", ".planning/cycles/01-c/CLOTURE.md"),
                     ("nom d'unité invalide (cycle)", ".planning/cycles/c/phases/01-p/CLOTURE.md"),
                     ("nom d'unité invalide (phase)", ".planning/cycles/01-c/phases/p/CLOTURE.md"),
                     ("CLOTURE.md.bak", CLOTURE + ".bak"), ("nom voisin", UNITE + "/CLOTURE-notes.md"),
                     ("profondeur fausse", UNITE + "/plans/CLOTURE.md"), ("sous un autre dossier", UNITE + "/annexes/01-a/CLOTURE.md"),
                     ("hors .planning/", "livrables/CLOTURE.md"), ("hors .planning/ (racine)", "CLOTURE.md")):
        passe(nom, lab, "Write", rel)
    # lab dev : même écriture, livrable absent -> octet vide, code 0
    lab_dev = fabriquer_lab(ctx, "g3-03-dev", adherent=False)
    for outil in ("Write", "Edit", "NotebookEdit"):
        rc, out, err = ecrire_dans(ctx, d, lab_dev, outil, CLOTURE)
        if rc != 0 or out != b"" or err:
            fautes.append("lab dev %s : rc=%d %s" % (outil, rc, court(out)))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "aucun refus : livrables présents (fichier, dossier, sous-dossier, dossier avec .DS_Store, liste, unité de plan) ; style GSD, niveau cycle, "
                          "noms d'unité invalides, .bak, nom voisin, profondeur fausse, hors .planning/ jamais jugés ; lab dev : stdout d'octet vide et code 0")


def controle_g3_04(ctx, script):
    """Dérogation G3 active sur le chemin du CLOTURE.md : passage cité, usage unique ; erreur interne injectée dans evaluer_g3 (sonde) : armée deny
    « erreur interne du gate », observe ligne d'observation et aucun refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = fabriquer_lab(ctx, "g3-04")
    rc, out, err = deroger(ctx, lab, "G3", (CLOTURE,))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    r1 = ecrire_dans(ctx, d, lab, "Write", CLOTURE)
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "G3", "willy", "AskUserQuestion session principale", "2026-10-05", CLOTURE) if m not in texte]
    journal = os.path.join(lab, ".planning", "derogations-gates.log")
    consommees = [l for l in open(journal, encoding="utf-8").read().split("\n") if "  consommee  id=1  gate=G3  " in l] if os.path.exists(journal) else []
    if manque or len(consommees) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(consommees))
    r2 = ecrire_dans(ctx, d, lab, "Write", CLOTURE)
    if classer(r2[0], r2[1]) != "deny":
        return False, "second Write : " + classer(r2[0], r2[1])
    # erreur interne : sonde sur la première ligne de evaluer_g3
    dossier, raison = make_hook_mutant(ctx, "G3-SONDE", "# g3-sonde", 'raise RuntimeError("sonde")  # g3-sonde')
    if dossier is None:
        return False, "mutant sonde invalide : " + raison
    lab2 = fabriquer_lab(ctx, "g3-04-sonde")
    cache = dossier_neuf(ctx, "cache-g3-04")
    rc, out, err = ecrire_dans(ctx, ctx.copie_forcee(dossier, "observe"), lab2, "Write", CLOTURE, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=G3  " not in lignes[0]:
        return False, "sonde, observe : rc=%d stdout=%s stderr=%s lignes=%s" % (rc, court(out), court(err), lignes)
    motif = [c for c in lignes[0].split("  ") if c.startswith("raison=")]
    if not motif or "erreur interne" not in urllib.parse.unquote(motif[0]):
        return False, "la ligne ne porte pas une raison d'erreur : " + lignes[0]
    rc, out, err = ecrire_dans(ctx, ctx.copie_forcee(dossier, "armed"), lab2, "Write", CLOTURE)
    if classer(rc, out) != "deny" or "erreur interne du gate" not in raison_de(out):
        return False, "sonde, armée : " + classer(rc, out) + " " + court(out)
    return True, ("dérogation G3 : premier Write passe et cité, dérogation consommée, second Write refusé ; erreur interne de G3 : en observe aucun "
                  "refus et une ligne d'erreur au journal, armée un deny « erreur interne du gate »")


# --- Mutants --------------------------------------------------------------------------------------------------------
def tuer(ctx, ident, motif, remplacement, id_controle, controle):
    """Preuve d'opposabilité : le contrôle passe sur l'original, le témoin est inchangé sous le mutant, le contrôle rougit sous le mutant."""
    dossier, raison = make_hook_mutant(ctx, ident, motif, remplacement)
    if dossier is None:
        komut(ident, "mutant du cœur valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
        return
    original = controle(ctx, ctx.scripts_dir)
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


def sec_g3(ctx):
    for ident, ctrl, titre in (
            ("R-G3-01", controle_g3_01, "copie observe, livrable absent : une ligne gate=G3"),
            ("R-G3-02", controle_g3_02, "copie armée, refus"),
            ("R-G3-03", controle_g3_03, "copie armée, jumeaux qui passent"),
            ("R-G3-04", controle_g3_04, "dérogation et erreur interne")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_mutants_g3(ctx):
    tuer(ctx, "G3-LIVRABLE", "# g3-livrable", "if False:  # g3-livrable", "R-G3-02", controle_g3_02)
    tuer(ctx, "G3-FORME", "# g3-forme",
         'unite = composants[:-1] if composants and composants[0].casefold() == ".planning" and composants[-1].casefold() == "cloture.md" else None  # g3-forme',
         "R-G3-03", controle_g3_03)
    tuer(ctx, "G3-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-G3-03", controle_g3_03)


SECTIONS = {
    "g3": sec_g3,
    "mutants_g3": sec_mutants_g3,
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
PY_AIDES_CLOTURE_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-cloture.txt"
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
[ -f "$SCRIPTS_DIR/deroger-gate.sh" ] || ko "deroger-gate.sh présent" "la commande de dérogation existe à côté du hook" "$SCRIPTS_DIR/deroger-gate.sh" "absent"
if [ -z "$HOOKS_JSON" ] && [ -z "$SETTINGS_LAB" ]; then
  echo "NOTE : ni hooks.json ni settings.json à côté des scripts (suite lancée hors dépôt) : la commande enregistrée n'est pas lisible, rien n'est rejoué."
else
  run_sections "${VF_CLOT_SECTIONS:-g3,mutants_g3}"
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
