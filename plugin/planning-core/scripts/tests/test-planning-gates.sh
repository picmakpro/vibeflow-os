#!/usr/bin/env bash
# test-planning-gates.sh — sémantique des gates du hook central (Phase 45, 45-01 ; GATE-08, GATE-10,
# GATE-15) : table d'armement, contrôle croisé du parseur, G2 (avertit, jamais ne refuse), banc des
# écritures. Le hook est rejoué PAR LA COMMANDE ENREGISTRÉE (lue dans hooks.json), jamais par un appel
# direct au script (P45-D-20) ; la couche shell de cette commande a sa propre suite
# (test-planning-hook-registered.sh).
#
# Familles :
#   R-TABLE-01..03  la table d'armement vit dans le code livré (constantes ARMEMENT_* = TABLE_ATTENDUE, l'état courant),
#                   armement_valide refuse un ordre violé, une table incohérente refuse (deny)
#   R-PARSEUR       lire_frontmatter du hook est ast-identique à celle du moteur de recalcul
#   R-G2-01..07     G2 avertit par additionalContext (jamais permissionDecision), référentiel = union
#                   des ecrit: des plans ouverts, se tait hors d'un lab adhérent ; R-G2-PERF
#   R-ENV-01        aucune variable d'environnement ne change l'armement ni l'adhésion (P45-D-12a)
#   R-ENV-02        garde statique : le cœur Python ne lit aucune variable d'environnement (expanduser et
#                   expandvars compris) ; le lanceur lit TMPDIR (ligne du mktemp), XDG_CACHE_HOME et HOME
#                   (ligne d'appel du cœur, arguments) — amendement du 2026-09-30 (45-04) ; HOME sert aussi, et à cela seul,
#                   de racine de résolution des agents du compte (45-08, même décision du manager, 2026-09-30)
#   R-G5-01..06     G5 : Write, Edit, NotebookEdit de VERDICT.md sous .planning/ d'un lab adhérent, quel que
#                   soit le rôle ; en observe une ligne de journal sans contenu, en armed un deny (45-04)
#   R-G6-01..05     G6 : Write, Edit, NotebookEdit d'un fichier généré, enfant direct du dossier de planning d'un lab
#                   adhérent, quel que soit le rôle ; compartiments et plans du modèle non visés ; dérogation (45-05)
#   R-G6-06..09     Q-G6 = (b) (Willy, AskUserQuestion session principale, 2026-10-01) : G6 protège aussi les scripts du hook posés sous
#                   `<lab>/.claude/scripts/` d'un lab adhérent (planning-hook.sh et check-gates-alive.sh : Write, Edit, NotebookEdit, casse,
#                   liens dur et symbolique, alias, `..`, relatif, création) ; les réglages `.claude/settings*.json` ne le sont pas (limite (y)) ;
#                   observe journalise, lab dev silencieux (GATE-10), dérogation nominative ; MUT-G6-SCRIPT* et MUT-G6-SCRIPTS
#   R-CANG-01..03   canary de session : les cas G6 et G5 attendent une ligne d'observation tant que le gate est en
#                   observe, un refus de gate dès qu'il est armed ; un gate neutralisé fait signaler le canary (45-05)
#   R-G1-01..10     G1 (45-06) : PLAN.md de forme modèle dans une phase sans CADRAGE.md ou à registre ouvert, observe puis
#                   armed, plan direct et sous plans/ (la phase jugée est la phase), socle v2 et nom d'unité invalide
#                   jamais visés ; la valeur d'un statut n'est jamais jugée ; bord F5 = f5-etats (un état que le modèle
#                   ne peut pas lire n'est jamais refusé, l'absence de CADRAGE.md l'est toujours) ; dérogation ;
#                   contrôle croisé avec recalc-planning.sh --read-only sur chaque phase des bancs (CROISE-G1) ;
#                   COMPTE G1 du banc
#   R-REGISTRE      lire_registre du hook est ast-identique à celle du moteur de recalcul
#   R-CANG-G1       le cas de canary G1-sans-cadrage (état livré, G6, G5 et G1 armed, evaluer_g1 neutralisé)
#   R-G7-01..05     G7 (45-07) : création d'un .planning/ par Write ou NotebookEdit dans un dossier nu sous un lab adhérent,
#                   observe puis armed ; un marqueur de projet de code laisse passer (un cas par marqueur, faux marqueurs
#                   refusés) ; .planning/ existant, Edit, lab dev, dossier sans ancêtre planifié : jamais refusés ; contrôle
#                   croisé des marqueurs avec le TEXTE de detect-gsd-engine.sh (R-G7-05) ; COUVERTURE G7, COMPTE G7 du banc
#   R-G7-06..09     G7 (45-07) : prédicat « habité » littéral de P45-D-14 (un agents/*.md régulier ET un fichier régulier sous
#                   memory/ ; tableau des cas imprimé `G7-HABITE`), fichiers réguliers seulement, dérogation, COMPTE G7 du banc
#   R-CANG-G7       le cas de canary G7-orphelin (état livré, étapes 1 à 3 armed, evaluer_g7 neutralisé)
#   R-CANG-ROLE     les cas de canary du rôle (45-09) : écriture d'un juge, dispatch d'un worker sous Agent ET sous Task, sur des
#                   définitions d'agents que le canary pose dans son lab synthétique ; observe (une ligne gate=ROLE par cas) puis armed
#   R-CANG-ROLE-MORT evaluer_role neutralisé : le canary signale, une ligne qui nomme ROLE-juge
#   R-CANG-COUVERTURE la couverture minimale de P45-D-20 (script absent, python3 absent, Task, Agent, fil principal, plugin:), étiquetée cas
#                   par cas et vérifiée contre le payload ; `--couverture` ; une couverture incomplète fait signaler le canary
#                   (MUT-CANG-TASK : le cas Task retiré ; MUT-CANG-COUVERTURE : le contrôle de couverture qui rend toujours « complet »)
#   R-ROLE-01..07   hook par rôle (45-08 ; GATE-09) : un juge défini dans le lab écrit, le hook résout sa définition (lab, compte,
#                   plugin ; name: du frontmatter, repli sur le nom de fichier ; normalisation), dérive « juge » et l'observe (copie
#                   observe : une ligne gate=ROLE) ou le refuse (copie armed) ; fil principal, agent inconnu, ambigu, illisible ou de
#                   plugin non résolu : jamais un refus de rôle ; lab dev : stdout d'octet vide ; --classer ; erreur interne
#   R-ROLE-08..12   ligne worker selon F9 = f9-allowlist (Willy, AskUserQuestion session principale, 2026-09-30) : un worker ne
#                   dispatche que ce que SA propre allowlist Agent(...) / Task(...) autorise (allowlist vide : tout refusé), sous
#                   les deux tool_name Agent ET Task, subagent_type normalisé des deux côtés (chaîne entière, aucun préfixe retiré) ;
#                   racine du dispatch = cwd du payload (lab dev : silence) ; manager, producteur, juge, fil principal, inconnu :
#                   jamais un refus ; dérogation ROLE ; COMPTE ROLE du banc sur copie armée
#   R-ROLE-13       HOME est l'entrée déclarée de la résolution des agents du compte (P45-D-12a) : il change la résolution, jamais
#                   l'adhésion, le verdict de G5 et de G6 ni l'armement ; XDG_CACHE_HOME, CLAUDE_PROJECT_DIR et TMPDIR ne la changent pas
#                   (le contrôle croisé du rôle avec check-agents.sh vit dans scripts/tests/test-role-hook-vs-check-agents.sh)
#   R-OBS-ENV       le journal d'observation suit XDG_CACHE_HOME puis HOME et rien d'autre : les valeurs
#                   reçues n'atteignent jamais l'armement ni l'adhésion (P45-D-12a)
#   R-JETON         l'encodeur du journal est ast-identique à _jeton_journal du moteur de recalcul
#   R-DEROG-01..08  la commande deroger-gate.sh (dérogation nominative, journal append-only injectif, jamais liée
#                   à l'urgence) et sa consommation par le hook : usage unique, citée, sans effet en observe
#   R-VERDICT-01..05 la commande poser-verdict.sh : format de la 44, sha256 du PLAN.md (A3), tentative 1 puis
#                   +1, écriture atomique, refus hors lab adhérent, jamais vue par G5 (45-04, F8 et A3)
#   R-ACCORD        chemin relatif : avertissement G2 en mode A <=> deny en mode C (limite h)
#   BANC            chaque `@@ ecriture` de fixtures/gates-banc.txt rend son attendu ; COUVERTURE
#   LOT A           (section `lota` ; correction ciblée post-45-09, décisions du manager vf-dev-manager, 2026-10-01) : R-IMB-01..05 un `.planning`
#                   imbriqué n'est jamais une racine de lab ; R-DEROG-09 une dérogation n'est consommée que si la décision finale est un
#                   passage ; R-DEROG-10 droits du journal jamais élargis, argv UTF-8 ; R-VERDICT-06..09 poser-verdict.sh (contrôles, forme
#                   d'unité, verrou, UTF-8) ; R-DEFS-01..05 parseur de définitions linéaire et borné, échéance interne, orphelin, transport ; R-DEFS-06 minuteur désarmé après la décision (F-03) ; R-ADH-REPLI constante partagée entre G6 et le grep de repli (F-02) ;
#                   R-VERSION-01 version active d'un plugin ; R-CAN-09..11 le canary n'exécute que la commande de référence, constantes
#                   d'armement absentes = signal ; chaque contrôle a son mutant (MUT-IMB-*, DEROG-GLOBALE, DEROG-FCHMOD, DEROG-UTF8, VERDICT-*,
#                   PUCE-*, ECHEANCE-* (dont FIGEE-EMISSION, FIGEE-SORTIE, FIGE-GARDE), ADH-REPLI-*, TRANSPORT-EFFACE, PLUGIN-*, CANG-RECONNUE, CANG-ARMEMENT-SIGNAL)
#   R-REFERENCE     (section `reference`, 45-10 ; GATE-15, T-45-90) la référence du modèle (section « Hook central et gates d'écriture
#                   (Phase 45) ») est identique au code livré : table d'armement (état, étape, cas de canary, relevé), noms protégés par
#                   G6, journal de dérogation, marqueurs de code, ordre de résolution des agents, outils refusés et laissé ouvert en mode
#                   dégradé (commande de hooks.json), limites déclarées (a) à (ae) chacune sur sa ligne ; MUT-REFERENCE-* : une valeur de
#                   gate inversée, `Agent` retiré des outils refusés, une limite retirée (chacune des 26, puis (l) à part), un nom de
#                   journal, un marqueur, l'ordre de résolution, un cas de canary, une constante du hook changée sans la référence
#   MUT-*           chaque garde est tuée par un mutant à motif unique dont la trace est imprimée
#
# Les cas de gate de 45-04 (G5) tournent sur une copie dont les constantes ARMEMENT_* sont FORCÉES
# (`observe` ou `armed`) : jamais sur l'état livré, qui change à chaque armement. Les cas de 45-01
# (G2, table, environnement) tournent sur l'état livré. Le banc accepte l'option `armee` (copie armée).
#
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; `cmp -s`
# jamais `diff` ; tout le travail fin est fait par Python (PYBIN). Lançable depuis tout cwd.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
HOOK="$SCRIPTS_DIR/planning-hook.sh"
RECALC="$SCRIPTS_DIR/recalc-planning.sh"
BANC="$TESTS_DIR/fixtures/gates-banc.txt"
BANC_RECALC="$TESTS_DIR/fixtures/recalc-planning-banc.txt"
HOOKS_JSON="$SCRIPTS_DIR/../hooks/hooks.json"
SETTINGS_LAB="$SCRIPTS_DIR/../settings.json"
[ -f "$HOOKS_JSON" ] || HOOKS_JSON=""
[ -f "$SETTINGS_LAB" ] || SETTINGS_LAB=""

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-planning-gates] python3 requis" >&2; exit 1; fi
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
cat > "$AIDES" <<'PY_AIDES_GATES_EOF'
import ast
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import time
import urllib.parse
from concurrent.futures import ThreadPoolExecutor

TOKEN = "{{VF_SCRIPTS}}"
OUTILS_BANC = ("Write", "Edit", "NotebookEdit", "Bash", "Agent", "Task")
# Table d'armement ATTENDUE de l'état livré : chaque armement d'une étape (45-05 à 45-09) met à
# jour la constante du script ET cette table dans le MÊME commit (R-TABLE-01).
TABLE_ATTENDUE = {"G6": "armed", "G5": "armed", "G1": "armed", "G7": "armed", "ROLE": "armed"}
ORDRE_ATTENDU = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",))


def ok(libelle):
    print("  ✓ " + libelle)


def ko(libelle, assertion, attendu, obtenu):
    print("  ✗ " + libelle)
    print("    assertion : " + str(assertion))
    print("    attendu   : " + str(attendu))
    print("    obtenu    : " + str(obtenu))


def okmut(ident, trace):
    print("  ✓ MUT-%s TUÉ — %s" % (ident, trace))


def komut(ident, assertion, attendu, obtenu):
    print("  ✗ MUT-%s NON TUÉ" % ident)
    print("    assertion : " + assertion)
    print("    attendu (original) : " + attendu)
    print("    obtenu (mutant)     : " + obtenu)


def court(octets, n=200):
    texte = octets.decode("utf-8", "replace") if isinstance(octets, bytes) else str(octets)
    texte = texte.replace("\n", "\\n")
    return texte if len(texte) <= n else texte[:n] + "…(+" + str(len(texte) - n) + ")"


# --- Payload du harnais (Claude Code 2.1.284, mesuré) ----------------------------------------
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


def entree_outil(outil, chemin, commande=None, sous=None):
    if outil == "Bash":
        return {"command": commande if commande is not None else "true"}
    if outil in ("Agent", "Task"):
        return {"description": "d", "prompt": "p", "subagent_type": sous if sous is not None else "general-purpose"}
    if outil == "NotebookEdit":
        return {"notebook_path": chemin, "new_source": "x"}
    if outil == "Edit":
        return {"file_path": chemin, "old_string": "a", "new_string": "b"}
    return {"file_path": chemin, "content": "x"}


def ecrire(chemin, contenu):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(contenu)


# --- Contexte : la commande enregistrée, modes A (script réel) et C (script absent) ------------
class Ctx:
    def __init__(self, scripts_dir, hooks_json, work, settings_lab):
        self.scripts_dir = scripts_dir
        self.hooks_json = hooks_json
        self.work = work
        self.settings_lab = settings_lab
        self.hook = os.path.join(scripts_dir, "planning-hook.sh")
        self.recalc = os.path.join(scripts_dir, "recalc-planning.sh")
        self.home = os.path.join(work, "home")
        os.makedirs(self.home, exist_ok=True)
        self.cache = os.path.join(work, "cache-suite")
        os.makedirs(self.cache, exist_ok=True)
        self._forcees = {}
        os.makedirs(os.path.join(work, "modeC"), exist_ok=True)
        self._n = 0
        self.cmd = None
        self.cmd_np = None
        self._armee = None

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
        # Pré-filtre hors adhésion (revue Samuel, PR #124 ; arbitrage Willy, AskUserQuestion session principale, 2026-10-02) : les cas de cette suite
        # mesurent le CŒUR et les gates, rejoués par la couche shell d'avant le pré-filtre (le bloc retiré, octet pour octet) : un lab non
        # adhérent n'y lance plus le cœur, un mutant du cœur y serait invisible. La commande COMPLÈTE est gardée par test-planning-prefilter.sh
        # (équivalence : court-circuit seulement hors adhésion) et, ici, par R-REFERENCE et le canary.
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

    def lancer(self, mode, entree, cwd=None, dossier=None, extra_env=None):
        """Rejoue la commande enregistrée TELLE QUELLE sous /bin/sh -c. Mode A : script du dossier
        donné (défaut : le script réel) ; mode C : dossier de scripts vide."""
        d = os.path.join(self.work, "modeC") if mode == "C" else (dossier or self.scripts_dir)
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
        """Copie du script du dossier donné dont les cinq constantes ARMEMENT_* valent `valeur`
        (`observe` ou `armed`) : les cas de gate ne dépendent jamais de l'état livré."""
        cle = (dossier_scripts, valeur)
        if cle not in self._forcees:
            texte = open(os.path.join(dossier_scripts, "planning-hook.sh"), encoding="utf-8").read()
            texte, n = re.subn(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE) = )"(?:observe|armed)"', r'\1"' + valeur + '"', texte, flags=re.M)
            if n != 5:
                raise RuntimeError("cinq constantes ARMEMENT_* attendues, %d trouvée(s)" % n)
            d = self.unique("force-" + valeur)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
                fh.write(texte)
            os.chmod(os.path.join(d, "planning-hook.sh"), 0o755)
            self._forcees[cle] = d
        return self._forcees[cle]

    def copie_armee(self):
        """Copie du script dont les cinq constantes ARMEMENT_* valent `armed` (armement FORCÉ)."""
        if self._armee is None:
            texte = open(self.hook, encoding="utf-8").read()
            texte, n = re.subn(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE) = )"(?:observe|armed)"', r'\1"armed"', texte, flags=re.M)
            d = self.unique("armee")
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
                fh.write(texte)
            os.chmod(os.path.join(d, "planning-hook.sh"), 0o755)
            self._armee = (d, n)
        return self._armee


def classer(rc, out):
    """`silence`, `avertit` (additionalContext sans décision), `deny`, `block` (SubagentStop : décision JSON, Phase 46), `watchPaths`, ou
    `autre:...`."""
    if rc != 0:
        return "autre:rc=%d" % rc
    if out == b"":
        return "silence"
    try:
        obj = json.loads(out.decode("utf-8"))
        if isinstance(obj, dict) and obj.get("decision") == "block" and isinstance(obj.get("reason"), str) and "hookSpecificOutput" not in obj:
            return "block"
        if isinstance(obj, dict) and isinstance(obj.get("watchPaths"), list):
            return "watchPaths"
        s = obj["hookSpecificOutput"]
        if isinstance(s.get("watchPaths"), list):
            return "watchPaths"
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


def contexte_de(out):
    return json.loads(out.decode("utf-8"))["hookSpecificOutput"].get("additionalContext", "")


# --- Banc texte (grammaire du banc 44 + directive `ecriture`) --------------------------------
def _valider_chemin_banc(chemin):
    if chemin.startswith("/") or chemin.startswith("~") or ".." in chemin.split("/"):
        raise ValueError("chemin refusé par le matérialiseur : " + chemin)


def parser_banc(texte):
    lignes = texte.split("\n")
    if lignes and lignes[-1] == "":
        lignes = lignes[:-1]
    labs, ordre = {}, []
    lab, fichier, contenu = None, None, []

    def clore():
        if lab is not None and fichier is not None:
            labs[lab]["fichiers"][fichier] = "".join(l + "\n" for l in contenu)

    for ligne in lignes:
        if not ligne.startswith("@@ "):
            if fichier is not None:
                contenu.append(ligne)
            continue
        clore()
        fichier, contenu = None, []
        d = ligne[3:]
        if d == "#" or d.startswith("# "):
            continue
        if d.startswith("lab "):
            morceaux = d[4:].split()
            lab = morceaux[0]
            jumeau = None
            for m in morceaux[1:]:
                if m.startswith("jumeau-de="):
                    jumeau = m[len("jumeau-de="):]
            labs[lab] = {"fichiers": {}, "dossiers": [], "liens": [], "ecritures": [], "jumeau_de": jumeau}
            ordre.append(lab)
        elif d.startswith("dossier "):
            chemin = d[8:].strip()
            _valider_chemin_banc(chemin)
            labs[lab]["dossiers"].append(chemin)
        elif d.startswith("fichier "):
            chemin = d[8:].strip()
            _valider_chemin_banc(chemin)
            fichier, contenu = chemin, []
        elif d.startswith("lien "):
            reste = d[5:].strip()
            if " -> " not in reste:
                raise ValueError("directive @@ lien mal formée : " + d)
            chemin, cible = [p.strip() for p in reste.split(" -> ", 1)]
            _valider_chemin_banc(chemin)
            labs[lab]["liens"].append((chemin, cible))
        elif d.startswith("ecriture "):
            labs[lab]["ecritures"].append(_parser_ecriture(d[9:]))
        else:
            raise ValueError("directive de banc inconnue : " + d)
    clore()
    return ordre, labs


def _parser_ecriture(reste):
    if " :: " not in reste:
        raise ValueError("directive @@ ecriture sans ` :: ` : " + reste)
    gauche, droite = reste.split(" :: ", 1)
    att = droite.split()
    if not att or att[0] not in ("doit-passer", "doit-refuser", "avertit", "silence"):
        raise ValueError("attendu inconnu : " + droite)
    e = {"attendu": att[0], "gate": att[1] if len(att) > 1 else None, "agent": None, "cwd": None, "commande": None,
         "armee": False, "sous": None}
    morceaux = gauche.split(" ", 2)
    e["outil"], e["chemin"] = morceaux[0], morceaux[1]
    if e["outil"] not in OUTILS_BANC:
        raise ValueError("outil de banc inconnu : " + e["outil"])
    if e["chemin"] != "-":
        _valider_chemin_banc(e["chemin"])
    options = morceaux[2] if len(morceaux) > 2 else ""
    while options:
        if options.startswith("commande="):
            e["commande"] = options[len("commande="):]
            break
        jeton, _, options = options.partition(" ")
        if jeton.startswith("agent="):
            e["agent"] = jeton[6:]
        elif jeton.startswith("cwd="):
            e["cwd"] = jeton[4:]
            _valider_chemin_banc(e["cwd"])
        elif jeton.startswith("sous="):
            e["sous"] = jeton[5:]
        elif jeton == "armee":
            e["armee"] = True
        elif jeton:
            raise ValueError("option de banc inconnue : " + jeton)
    if e["attendu"] in ("doit-passer", "doit-refuser") and not e["armee"]:
        raise ValueError("un cas doit-passer / doit-refuser se rejoue sur copie armée (option `armee`) : " + reste)
    return e


JETON_PLAN = "{{sha256-plan}}"
JETON_LIVRABLES = "{{empreinte-livrables}}"
POSER_VERDICT_SH = None  # chemin de poser-verdict.sh, posé par main() : la source du bloc partagé qui résout les jetons du banc


class JetonNonResolu(RuntimeError):
    """Un jeton du banc ne se résout pas : ni un OSError ni un ValueError, pour que `_labs_croises` ne l'écarte jamais en silence."""


def _bloc_poser_verdict():
    """Espace de noms du corps Python de poser-verdict.sh, sans l'appel final à main() : les jetons du banc sont résolus par la copie du
    bloc partagé que lit la vraie commande de pose, jamais par celle du recalcul (preuve croisée, 46-03)."""
    if not POSER_VERDICT_SH or not os.path.isfile(POSER_VERDICT_SH):
        raise JetonNonResolu("jeton du banc non résolu : poser-verdict.sh introuvable")
    arbre = ast.parse(corps_python(open(POSER_VERDICT_SH, encoding="utf-8").read(), "PY_POSER_VERDICT_EOF"))
    arbre.body = [n for n in arbre.body
                  if not (isinstance(n, ast.Expr) and isinstance(n.value, ast.Call) and getattr(n.value.func, "id", "") == "main")]
    ns = {"__name__": "bloc_charge_banc"}
    exec(compile(arbre, POSER_VERDICT_SH, "exec"), ns)
    return ns


def resoudre_jetons(destination):
    """Résout, APRÈS l'écriture de tous les fichiers du lab, `{{sha256-plan}}` (sha256 des octets du PLAN.md voisin du VERDICT.md) et
    `{{empreinte-livrables}}` (empreinte des entrées `ecrit:` de ce PLAN.md, par la copie du bloc lue dans poser-verdict.sh), comme le
    matérialiseur de test-recalc-planning.sh : sans quoi un verdict valide du banc de recalcul deviendrait périmé ici. Un jeton qui ne se
    résout pas lève JetonNonResolu avec un message nommé, jamais une substitution vide."""
    ns = None
    for racine, _dossiers, fichiers in os.walk(destination, followlinks=False):
        if "VERDICT.md" not in fichiers:
            continue
        chemin = os.path.join(racine, "VERDICT.md")
        rel = os.path.relpath(chemin, destination)
        if not stat.S_ISREG(os.lstat(chemin).st_mode):
            continue
        texte = open(chemin, encoding="utf-8").read()
        if JETON_PLAN not in texte and JETON_LIVRABLES not in texte:
            continue
        plan = os.path.join(racine, "PLAN.md")
        if not os.path.isfile(plan) or os.path.islink(plan):
            raise JetonNonResolu("jeton du banc non résolu : PLAN.md voisin absent de " + rel)
        octets_plan = open(plan, "rb").read()
        if JETON_PLAN in texte:
            texte = texte.replace(JETON_PLAN, hashlib.sha256(octets_plan).hexdigest())
        if JETON_LIVRABLES in texte:
            if ns is None:
                ns = _bloc_poser_verdict()
            statut_fm, donnees = ns["lire_frontmatter"](octets_plan.decode("utf-8"))
            if statut_fm != "ok":
                raise JetonNonResolu("jeton du banc non résolu : frontmatter du PLAN.md voisin illisible (" + rel + ")")
            valeurs = ns["_valeurs_ecrit"](donnees)
            if not valeurs:
                raise JetonNonResolu("jeton du banc non résolu : ecrit: absent du PLAN.md voisin (" + rel + ")")
            statut, detail = ns["empreinte_livrables"](destination, valeurs)
            if statut != "ok":
                raise JetonNonResolu("jeton du banc non résolu : empreinte des livrables " + statut + " (" + str(detail) + ") pour " + rel)
            texte = texte.replace(JETON_LIVRABLES, detail)
        with open(chemin, "w", encoding="utf-8") as fh:
            fh.write(texte)


def materialiser(labs, nom, destination):
    lab = labs[nom]
    os.makedirs(destination, exist_ok=True)
    for dossier in lab["dossiers"]:
        os.makedirs(os.path.join(destination, dossier), exist_ok=True)
    for chemin, contenu in lab["fichiers"].items():
        ecrire(os.path.join(destination, chemin), contenu)
    for chemin, cible in lab["liens"]:
        os.makedirs(os.path.dirname(os.path.join(destination, chemin)), exist_ok=True)
        os.symlink(cible, os.path.join(destination, chemin))
    resoudre_jetons(destination)


def entree_de_ecriture(e, racine):
    cwd = os.path.join(racine, e["cwd"]) if e["cwd"] else racine
    chemin = None if e["chemin"] == "-" else os.path.join(racine, e["chemin"])
    return payload(e["outil"], entree_outil(e["outil"], chemin, e["commande"], e.get("sous")), cwd, agent_type=e["agent"]), cwd


def juger(attendu, gate, rc, out):
    """(conforme, obtenu) d'une écriture du banc."""
    v = classer(rc, out)
    if attendu == "silence":
        return v == "silence", v
    if attendu == "avertit":
        return (v == "avertit" and (gate is None or gate in contexte_de(out))), v
    if attendu == "doit-refuser":
        return v == "deny", v
    return v in ("silence", "avertit"), v   # doit-passer : aucun refus


# --- Mutants du script (make_hook_mutant) ----------------------------------------------------
def observe_partout(texte):
    """Le texte du script dont les cinq constantes ARMEMENT_* valent `observe` (Q-ARM, Willy, AskUserQuestion session principale, 2026-09-30) : la
    base d'un mutant ne dépend pas de l'état d'armement courant (les contrôles forcent eux-mêmes l'état qu'ils mesurent, par copie_forcee ; le
    témoin « Write neutre » ne doit pas voir un gate armé refuser à la place du mutant). Sans ligne ARMEMENT_* (le canary), le texte est rendu tel quel."""
    return re.sub(r'^(ARMEMENT_(?:G6|G5|G1|G7|ROLE) = )"(?:observe|armed)"', r'\1"observe"', texte, flags=re.M)


def make_script_mutant(ctx, nom, marqueur, ident, motif, remplacement):
    """Copie du script `nom` (heredoc `marqueur`) dont l'UNIQUE ligne portant `motif` (fixe) est
    remplacée par `remplacement` (indentation conservée). `bash -n` et la compilation du corps Python
    extrait doivent passer. Un mutant d'un autre script que le hook reçoit aussi une copie du hook
    livré (le témoin rejoue la commande enregistrée sur ce dossier)."""
    original = observe_partout(open(os.path.join(ctx.scripts_dir, nom), encoding="utf-8").read())
    lignes = original.split("\n")
    idx = [i for i, l in enumerate(lignes) if motif in l]
    if len(idx) != 1 or original.count(motif) != 1:
        return None, "MOTIF AMBIGU OU ABSENT (lignes=%d, occurrences=%d)" % (len(idx), original.count(motif))
    ligne = lignes[idx[0]]
    lignes[idx[0]] = ligne[: len(ligne) - len(ligne.lstrip())] + remplacement
    muté = "\n".join(lignes)
    if muté == original:
        return None, "NON OPPOSABLE (identique)"
    dossier = ctx.unique("mut-" + ident.lower())
    os.makedirs(dossier, exist_ok=True)
    chemin = os.path.join(dossier, nom)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(muté)
    os.chmod(chemin, 0o755)
    if nom != "planning-hook.sh":
        with open(os.path.join(dossier, "planning-hook.sh"), "w", encoding="utf-8") as fh:
            fh.write(observe_partout(open(ctx.hook, encoding="utf-8").read()))
        os.chmod(os.path.join(dossier, "planning-hook.sh"), 0o755)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr)
    try:
        compile(corps_python(muté, marqueur), chemin, "exec")
    except SyntaxError as e:
        return None, "SyntaxError du corps Python : " + str(e)
    return dossier, None


def make_hook_mutant(ctx, ident, motif, remplacement):
    return make_script_mutant(ctx, "planning-hook.sh", "PY_PLANNING_HOOK_EOF", ident, motif, remplacement)


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


def charger_module(chemin_script):
    texte = open(chemin_script, encoding="utf-8").read()
    ns = {"__name__": "hook_core"}
    exec(compile(corps_python(texte), chemin_script, "exec"), ns)
    return ns


def labs_banc(ctx):
    if getattr(ctx, "_labs_banc", None) is None:
        ordre, labs = parser_banc(open(ctx.banc, encoding="utf-8").read())
        racine = ctx.unique("bancs")
        chemins = {}
        for nom in ordre:
            chemins[nom] = os.path.join(racine, nom)
            materialiser(labs, nom, chemins[nom])
        ctx._labs_banc = (ordre, labs, chemins)
    return ctx._labs_banc


# =================================================================================================
# Contrôles (chacun rend (conforme, détail) et s'applique à un script donné : le vrai ou un mutant)
# =================================================================================================
def _dossier(ctx, script):
    return script if script else ctx.scripts_dir


def _ecrire_ok(ctx, script, nom_lab, outil, chemin, agent=None, commande=None, cwd_rel=None):
    _, _, chemins = labs_banc(ctx)
    racine = chemins[nom_lab]
    e = {"outil": outil, "chemin": chemin, "agent": agent, "cwd": cwd_rel, "commande": commande}
    brut, cwd = entree_de_ecriture(e, racine)
    return ctx.lancer("A", brut, cwd=cwd, dossier=_dossier(ctx, script))


def controle_temoin(ctx, script):
    """Témoin : Write d'une cible neutre d'un lab adhérent → silence (aucun mutant ne l'affecte)."""
    rc, out, err = _ecrire_ok(ctx, script, "g2-adherent", "Write", ".planning/notes.md")
    v = classer(rc, out)
    return v == "silence" and not err, v


def controle_g2_01(ctx, script):
    rc, out, err = _ecrire_ok(ctx, script, "g2-adherent", "Write", "livrables/autre.md")
    v = classer(rc, out)
    if v != "avertit":
        return False, v + " " + court(out)
    texte = contexte_de(out)
    manque = [m for m in ("G2", "P45-D-10", "Bash") if m not in texte]
    cles = sorted(json.loads(out.decode("utf-8"))["hookSpecificOutput"].keys())
    if manque or "permissionDecision" in cles:
        return False, "manque %s ; clés %s" % (manque, cles)
    return True, "additionalContext qui nomme G2, P45-D-10 et Bash, sans permissionDecision"


def controle_g2_02(ctx, script):
    fautes = []
    for chemin in ("livrables/rapport.md", ".planning/notes.md", ".claude/agents/x.md", "livrables/suite.md",
                   "livrables/annexe/x.md"):
        rc, out, err = _ecrire_ok(ctx, script, "g2-adherent", "Write", chemin)
        v = classer(rc, out)
        if v != "silence":
            fautes.append("%s -> %s" % (chemin, v))
    return (not fautes), ("; ".join(fautes) if fautes else "silence : déclaré, sous .planning/, sous .claude/, union des plans, dossier couvert")


def controle_g2_03(ctx, script):
    fautes = []
    for chemin in ("livrables/ancien.md", "livrables/gele.md"):
        rc, out, err = _ecrire_ok(ctx, script, "g2-adherent", "Write", chemin)
        v = classer(rc, out)
        if v != "avertit":
            fautes.append("%s -> %s" % (chemin, v))
    return (not fautes), ("; ".join(fautes) if fautes else "avertit : plan clos et plan dérogé ne couvrent rien")


def controle_g2_07(ctx, script):
    fautes = []
    for outil, chemin, cmd in (("Write", "livrables/autre.md", None), ("Edit", "livrables/autre.md", None),
                               ("NotebookEdit", "livrables/nb.ipynb", None), ("Bash", "-", "cat livrables/autre.md")):
        rc, out, err = _ecrire_ok(ctx, script, "g2-dev", outil, chemin, commande=cmd)
        if rc != 0 or out != b"" or err:
            fautes.append("%s -> rc=%d %s" % (outil, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "stdout d'octet vide et code 0 dans un lab dev qui porte un plan ouvert")


def controle_table_02(ctx, script):
    ns = charger_module(script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh"))
    av = ns["armement_valide"]
    o, a = "observe", "armed"

    def T(g6, g5, g1, g7, role):
        return {"G6": g6, "G5": g5, "G1": g1, "G7": g7, "ROLE": role}

    refusees = {"G1 armé sans G6 ni G5": T(o, o, a, o, o), "G6 armé sans G5": T(a, o, o, o, o),
                "G5 armé sans G6": T(o, a, o, o, o), "ROLE armé sans G7": T(a, a, a, o, a),
                "G7 armé sans G1": T(a, a, o, a, o), "valeur inconnue": T("arme", "arme", o, o, o)}
    acceptees = {"tout à observe": T(o, o, o, o, o), "étape 1": T(a, a, o, o, o), "étapes 1-2": T(a, a, a, o, o),
                 "étapes 1-3": T(a, a, a, a, o), "étapes 1-4": T(a, a, a, a, a)}
    fautes = []
    for nom, t in refusees.items():
        if av(t):
            fautes.append("acceptée à tort : " + nom)
    for nom, t in acceptees.items():
        if not av(t):
            fautes.append("refusée à tort : " + nom)
    return (not fautes), ("; ".join(fautes) if fautes else "6 tables rejetées, 5 préfixes de l'ordre acceptés")


def controle_parseur(ctx, script):
    """R-PARSEUR : les arbres ast de lire_frontmatter (et de ses dépendances directes) extraits des deux
    heredocs sont identiques."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    arb_h = _arbres_parseur(corps_python(open(chemin, encoding="utf-8").read()))
    arb_r = _arbres_parseur(corps_python(open(ctx.recalc, encoding="utf-8").read(), "PY_RECALC_PLANNING_EOF"))
    fautes = []
    for nom in ("dequote", "CLE_RE", "lire_frontmatter", "_lire_liste_indentee"):
        if nom not in arb_h or nom not in arb_r:
            fautes.append("absent : " + nom)
        elif arb_h[nom] != arb_r[nom]:
            fautes.append("arbres différents : " + nom)
    return (not fautes), ("; ".join(fautes) if fautes else "4 arbres identiques : dequote, CLE_RE, lire_frontmatter, _lire_liste_indentee")


def _arbres_parseur(corps):
    res = {}
    for noeud in ast.parse(corps).body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name in ("dequote", "lire_frontmatter", "_lire_liste_indentee"):
            res[noeud.name] = ast.dump(noeud)
        elif isinstance(noeud, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "CLE_RE" for t in noeud.targets):
            res["CLE_RE"] = ast.dump(noeud)
    return res


def controle_accord(ctx, script):
    """Limite h : pour chaque forme de chemin relatif, avertissement G2 en mode A <=> deny en mode C."""
    _, _, chemins = labs_banc(ctx)
    fautes = []
    formes = (("Write", "livrables/autre.md"), ("Write", "sub/../livrables/autre.md"), ("NotebookEdit", "livrables/nb.ipynb"))
    for lab, attendu_a, attendu_c in (("g2-adherent", "avertit", "deny"), ("g2-dev", "silence", "silence")):
        racine = chemins[lab]
        for outil, rel in formes:
            brut = payload(outil, entree_outil(outil, rel), racine)
            rc_a, out_a, _e1 = ctx.lancer("A", brut, cwd=racine, dossier=_dossier(ctx, script))
            rc_c, out_c, _e2 = ctx.lancer("C", brut, cwd=racine)
            va, vc = classer(rc_a, out_a), classer(rc_c, out_c)
            if (va, vc) != (attendu_a, attendu_c):
                fautes.append("%s %s %s : mode A %s, mode C %s (attendu %s / %s)" % (lab, outil, rel, va, vc, attendu_a, attendu_c))
    return (not fautes), ("; ".join(fautes) if fautes else "avertissement en mode A <=> deny en mode C sur lab adhérent ; silence des deux côtés sur lab dev")


def controle_env_statique(ctx, script):
    """R-ENV-02 : garde STATIQUE — le cœur Python ne lit aucune variable d'environnement (AST : aucun
    `environ`, `getenv`, `putenv`, `expanduser`, `expandvars`, ni chaîne, import ou nom de ce genre) ;
    le lanceur lit TMPDIR une seule fois, sur la ligne du mktemp, XDG_CACHE_HOME et HOME une seule fois
    chacune, sur la seule ligne qui appelle le cœur (arguments), rien d'autre. Amendement des décisions
    du manager vf-dev-manager, 2026-09-30 (45-04) : XDG_CACHE_HOME ne sert qu'au chemin du journal
    d'observation, HOME à ce chemin (repli) et à la racine de résolution des agents du compte (45-08,
    même décision, P45-D-12a : un chemin, jamais une décision d'armement ni d'adhésion). Elle ne dépend
    d'aucun nom de variable posé par la suite."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    texte = open(chemin, encoding="utf-8").read()
    fautes = []
    interdits = ("environ", "getenv", "putenv", "environb", "getenvb", "unsetenv", "expanduser", "expandvars")
    arbre = ast.parse(corps_python(texte))
    for n in ast.walk(arbre):
        vu = None
        if isinstance(n, ast.Attribute) and n.attr in interdits:
            vu = n.attr
        elif isinstance(n, ast.Name) and n.id in interdits:
            vu = n.id
        elif isinstance(n, ast.Constant) and isinstance(n.value, str) and n.value in interdits:
            vu = repr(n.value)
        elif isinstance(n, ast.alias) and n.name in interdits:
            vu = "import " + n.name
        if vu:
            fautes.append("cœur Python : lecture de l'environnement (%s, ligne %d)" % (vu, getattr(n, "lineno", 0)))
    lanceur, dedans = [], False
    for l in texte.split("\n"):
        if l == "PY_PLANNING_HOOK_EOF":
            dedans = False
        if not dedans and not l.lstrip().startswith("#"):
            lanceur.append(l)
        if l.endswith("<<'PY_PLANNING_HOOK_EOF'"):
            dedans = True
    autorisees = {"TMPDIR", "T", "PYBIN", "XDG_CACHE_HOME", "HOME"}
    ancre = {"TMPDIR": "mktemp", "XDG_CACHE_HOME": '"$PYBIN"', "HOME": '"$PYBIN"'}
    lectures = {}
    for l in lanceur:
        for nom in re.findall(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)", l):
            lectures[nom] = lectures.get(nom, 0) + 1
            if nom not in autorisees:
                fautes.append("lanceur : variable lue hors liste : " + nom)
            elif nom in ancre and ancre[nom] not in l:
                fautes.append("lanceur : %s lue hors de la ligne attendue (%s) : %s" % (nom, ancre[nom], l.strip()))
    for nom in ancre:
        if lectures.get(nom, 0) != 1:
            fautes.append("lanceur : %d lecture(s) de %s (attendu 1)" % (lectures.get(nom, 0), nom))
    return (not fautes), ("; ".join(fautes) if fautes else "aucune lecture d'environnement dans le cœur Python (expanduser et expandvars compris) ; lanceur : TMPDIR une fois (ligne du mktemp), XDG_CACHE_HOME et HOME une fois chacune (ligne d'appel du cœur)")


def controle_env(ctx, scripts):
    """R-ENV-01 : mêmes verdicts, octet pour octet, sous cinq environnements."""
    _, _, chemins = labs_banc(ctx)
    envs = {}
    envs["vide"] = {}
    envs["HOME et XDG_CACHE_HOME fictifs"] = {"HOME": ctx.unique("env-home"), "XDG_CACHE_HOME": ctx.unique("env-cache")}
    for d in envs["HOME et XDG_CACHE_HOME fictifs"].values():
        os.makedirs(d, exist_ok=True)
    proj = ctx.unique("env-proj")
    os.makedirs(os.path.join(proj, ".claude", "scripts"), exist_ok=True)
    shutil.copy(ctx.hook, os.path.join(proj, ".claude", "scripts", "planning-hook.sh"))
    envs["CLAUDE_PROJECT_DIR ailleurs (copie identique)"] = {"CLAUDE_PROJECT_DIR": proj}
    tmp = ctx.unique("env-tmp")
    os.makedirs(tmp, exist_ok=True)
    envs["TMPDIR ailleurs"] = {"TMPDIR": tmp}
    envs["variables hostiles"] = {"VF_SCHEMA_ADHESION": "2.0", "VF_ARMEMENT": "off", "GSD_WORKSTREAM": "hostile"}
    charges = (("adhérent, cible neutre", "g2-adherent", "Write", ".planning/notes.md", "silence"),
               ("adhérent, livrable non déclaré", "g2-adherent", "Write", "livrables/autre.md", "avertit"),
               ("dev", "g2-dev", "Write", "livrables/autre.md", "silence"))
    fautes, n = [], 0
    for script in scripts:
        for etiquette, lab, outil, rel, attendu in charges:
            racine = chemins[lab]
            brut = payload(outil, entree_outil(outil, os.path.join(racine, rel)), racine)
            reference = ctx.lancer("A", brut, cwd=racine, dossier=script)
            if classer(reference[0], reference[1]) != attendu:
                fautes.append("référence %s (%s) : attendu %s, obtenu %s" % (etiquette, os.path.basename(script), attendu, classer(reference[0], reference[1])))
                continue
            for nom, extra in envs.items():
                r = ctx.lancer("A", brut, cwd=racine, dossier=script, extra_env=extra)
                n += 1
                if r != reference:
                    fautes.append("%s sous « %s » : %s au lieu de %s" % (etiquette, nom, classer(r[0], r[1]), attendu))
    return (not fautes), ("; ".join(fautes) if fautes else "%d rejeux sous 5 environnements : verdicts identiques octet pour octet" % n)



# --- 45-04 : G5, journal d'observation, encodeur ---------------------------------------------------
VERDICT_REL = ".planning/cycles/01-c/phases/01-p/VERDICT.md"
SECRET = "SECRET-FACTICE-7f3a9c"


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


def _g5(ctx, dossier_hook, outil, rel, agent=None, lab="g5-adherent", extra_env=None, entree=None):
    _, _, chemins = labs_banc(ctx)
    racine = chemins[lab]
    e = entree if entree is not None else entree_outil(outil, os.path.join(racine, rel))
    brut = payload(outil, e, racine, agent_type=agent)
    return ctx.lancer("A", brut, cwd=racine, dossier=dossier_hook, extra_env=extra_env)


def controle_g5_01(ctx, script):
    """Copie observe : Write de VERDICT.md -> silence, code 0, UNE ligne gate=G5 au journal, sans contenu."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g5-01")
    rc, out, err = _g5(ctx, d, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    ligne = lignes[0]
    for motif in ("  gate=G5  ", "  chemin=" + VERDICT_REL + "  ", "  outil=Write  "):
        if motif not in ligne:
            return False, "la ligne ne porte pas %r : %s" % (motif, ligne)
    mode_f = stat.S_IMODE(os.stat(journal_de(cache)).st_mode)
    mode_d = stat.S_IMODE(os.stat(os.path.dirname(journal_de(cache))).st_mode)
    if mode_f != 0o600 or mode_d != 0o700:
        return False, "permissions fichier %o dossier %o (attendu 600 et 700)" % (mode_f, mode_d)
    return True, "copie observe : silence, code 0, une ligne gate=G5 (chemin, outil), journal 0600 dans un dossier 0700"


def controle_g5_02(ctx, script):
    """Copie armed : même payload -> UN objet deny, `[planning-core] G5 :`, poser-verdict.sh, rien au journal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    cache = dossier_neuf(ctx, "cache-g5-02")
    rc, out, err = _g5(ctx, d, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return False, "%s stderr=%s %s" % (v, court(err), court(out))
    raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    if not raison.startswith("[planning-core] G5 :") or "poser-verdict.sh" not in raison:
        return False, "raison : " + raison
    if lignes_journal(cache):
        return False, "un refus a écrit au journal d'observation"
    return True, "copie armed : un objet deny, raison « [planning-core] G5 : … poser-verdict.sh », journal vide"


def controle_g5_03(ctx, script):
    """Copie armed : Edit, NotebookEdit, casse, profondeur, fil principal, agent inconnu, juge -> refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    base = ".planning/cycles/01-c/phases/01-p/"
    cas = (("Edit", VERDICT_REL, None), ("NotebookEdit", VERDICT_REL, None),
           ("Write", base + "verdict.md", None), ("Write", base + "Verdict.MD", None),
           ("Write", base + "plans/01-a/VERDICT.md", None), ("Write", ".planning/VERDICT.md", None),
           ("Write", VERDICT_REL, None), ("Write", VERDICT_REL, "agent-inconnu"),
           ("Write", VERDICT_REL, "vf-design-judge"), ("Write", VERDICT_REL, "general-purpose"))
    fautes = []
    for outil, rel, agent in cas:
        rc, out, err = _g5(ctx, d, outil, rel, agent=agent)
        if classer(rc, out) != "deny" or err:
            fautes.append("%s %s agent=%s -> %s" % (outil, rel, agent, classer(rc, out)))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus : Edit, NotebookEdit, casse, profondeur, fil principal, agent inconnu, juge" % len(cas))


def controle_g5_04(ctx, script):
    """Copie armed : PLAN.md, SUMMARY.md, livrable nommé verdict hors .planning/, lab dev -> aucun refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for rel in (".planning/cycles/01-c/phases/01-p/PLAN.md", ".planning/cycles/01-c/phases/01-p/SUMMARY.md",
                ".planning/cycles/01-c/phases/01-p/VERDICT-notes.md", "livrables/verdict-client.md",
                "livrables/VERDICT.md"):
        rc, out, err = _g5(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err:
            fautes.append("%s -> %s" % (rel, classer(rc, out)))
    rc, out, err = _g5(ctx, d, "Write", VERDICT_REL, lab="g5-dev")
    if classer(rc, out) != "silence" or err:
        fautes.append("lab dev %s -> %s" % (VERDICT_REL, classer(rc, out)))
    return (not fautes), ("; ".join(fautes) if fautes else "aucun refus : PLAN.md, SUMMARY.md, nom voisin, livrables/VERDICT.md hors .planning/, lab dev en silence")


def controle_g5_05(ctx, script):
    """Erreur interne injectée dans evaluer_g5 (mutant sonde) : observe -> aucun refus + ligne d'erreur ;
    armed -> deny."""
    dossier, raison = make_hook_mutant(ctx, "G5-SONDE", "# g5-sonde", 'raise RuntimeError("sonde")  # g5-sonde')
    if dossier is None:
        return False, "mutant sonde invalide : " + raison
    cache = dossier_neuf(ctx, "cache-g5-05")
    rc, out, err = _g5(ctx, ctx.copie_forcee(dossier, "observe"), "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=G5  " not in lignes[0]:
        return False, "observe : rc=%d stdout=%s stderr=%s lignes=%s" % (rc, court(out), court(err), lignes)
    motif = [c for c in lignes[0].split("  ") if c.startswith("raison=")]
    if not motif or "erreur interne" not in urllib.parse.unquote(motif[0]):
        return False, "la ligne ne porte pas une raison d'erreur : " + lignes[0]
    rc, out, err = _g5(ctx, ctx.copie_forcee(dossier, "armed"), "Write", VERDICT_REL)
    if classer(rc, out) != "deny" or "erreur interne" not in json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]:
        return False, "armed : " + classer(rc, out) + " " + court(out)
    return True, "erreur interne de G5 : en observe aucun refus et une ligne d'erreur au journal, en armed un deny"


def controle_g5_06(ctx, script):
    """Le journal d'observation ne recopie ni le contenu ni la commande écrits (Pitfall 7)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g5-06")
    _, _, chemins = labs_banc(ctx)
    chemin = os.path.join(chemins["g5-adherent"], VERDICT_REL)
    entrees = (("Write", {"file_path": chemin, "content": SECRET}),
               ("Edit", {"file_path": chemin, "old_string": SECRET, "new_string": SECRET + "-2"}),
               ("NotebookEdit", {"notebook_path": chemin, "new_source": SECRET}))
    for outil, entree in entrees:
        rc, out, err = _g5(ctx, d, outil, VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache}, entree=entree)
        if rc != 0 or out != b"" or err:
            return False, "%s : rc=%d stdout=%s" % (outil, rc, court(out))
    lignes = lignes_journal(cache)
    if len(lignes) != 3:
        return False, "%d ligne(s) au journal (attendu 3)" % len(lignes)
    if any(SECRET in l for l in lignes):
        return False, "le contenu écrit figure au journal : " + court("\n".join(lignes))
    return True, "trois écritures observées (Write, Edit, NotebookEdit), aucune ligne ne porte le contenu factice"


def _arbre_fonction(corps, nom):
    for noeud in ast.parse(corps).body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name == nom:
            return ast.dump(noeud)
    return None


def controle_jeton(ctx, script):
    """R-JETON : l'encodeur du journal est ast-identique à `_jeton_journal` de recalc-planning.sh."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    a_h = _arbre_fonction(corps_python(open(chemin, encoding="utf-8").read()), "_jeton_journal")
    a_r = _arbre_fonction(corps_python(open(ctx.recalc, encoding="utf-8").read(), "PY_RECALC_PLANNING_EOF"), "_jeton_journal")
    if a_h is None or a_r is None:
        return False, "_jeton_journal absent (hook %s, moteur %s)" % (a_h is not None, a_r is not None)
    if a_h != a_r:
        return False, "arbres différents"
    return True, "arbres ast identiques (docstring comprise)"


def controle_obs_env(ctx, script):
    """R-OBS-ENV (P45-D-12a) : le chemin du journal suit XDG_CACHE_HOME puis HOME et rien d'autre ; le
    verdict de la commande enregistrée ne dépend d'aucune des deux valeurs ; un journal impossible à
    écrire ne transforme jamais une observation en refus."""
    dossier = _dossier(ctx, script)
    d_obs = ctx.copie_forcee(dossier, "observe")
    d_arm = ctx.copie_forcee(dossier, "armed")
    _, _, chemins = labs_banc(ctx)
    fautes = []
    a, b, h1, h2 = (dossier_neuf(ctx, "obs-" + n) for n in ("a", "b", "h1", "h2"))
    # (1) la ligne apparaît sous XDG_CACHE_HOME de la suite et sous aucun autre dossier
    _g5(ctx, d_obs, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": a, "HOME": h1})
    if len(lignes_journal(a)) != 1 or os.path.exists(os.path.join(h1, ".cache")):
        fautes.append("XDG_CACHE_HOME=A : %d ligne(s) sous A, %s sous HOME" % (len(lignes_journal(a)), os.path.exists(os.path.join(h1, ".cache"))))
    _g5(ctx, d_obs, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": b, "HOME": h2})
    if len(lignes_journal(b)) != 1 or len(lignes_journal(a)) != 1 or os.path.exists(os.path.join(h2, ".cache")):
        fautes.append("XDG_CACHE_HOME=B : %d ligne(s) sous B, %d sous A" % (len(lignes_journal(b)), len(lignes_journal(a))))
    # (2) repli sur HOME/.cache quand XDG_CACHE_HOME est vide ou non absolu (jamais créé sous le lab)
    for xdg in ("", "relatif/non/absolu"):
        h = dossier_neuf(ctx, "obs-hrepli")
        _g5(ctx, d_obs, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": xdg, "HOME": h})
        if len(lignes_journal(os.path.join(h, ".cache"))) != 1:
            fautes.append("XDG_CACHE_HOME=%r : pas de repli sur HOME/.cache" % xdg)
    if os.path.exists(os.path.join(chemins["g5-adherent"], "relatif")):
        fautes.append("un XDG_CACHE_HOME relatif a créé un dossier sous le lab")
    # (3) verdicts identiques octet pour octet sous d'autres valeurs, y compris inexploitables
    fichier = os.path.join(dossier_neuf(ctx, "obs-fichier"), "reguliere")
    with open(fichier, "w", encoding="utf-8") as fh:
        fh.write("")
    variantes = (("A et H1", {"XDG_CACHE_HOME": a, "HOME": h1}), ("B et H2", {"XDG_CACHE_HOME": b, "HOME": h2}),
                 ("vides", {"XDG_CACHE_HOME": "", "HOME": ""}),
                 ("fichiers réguliers (dossier non inscriptible)", {"XDG_CACHE_HOME": fichier, "HOME": fichier}))
    for etiquette, copie, attendu in (("observe", d_obs, "silence"), ("armed", d_arm, "deny")):
        reference = _g5(ctx, copie, "Write", VERDICT_REL)
        if classer(reference[0], reference[1]) != attendu:
            fautes.append("référence %s : %s (attendu %s)" % (etiquette, classer(reference[0], reference[1]), attendu))
            continue
        for nom, extra in variantes:
            r = _g5(ctx, copie, "Write", VERDICT_REL, extra_env=extra)
            if r != reference:
                fautes.append("copie %s sous %s : %s au lieu de %s (stderr %s)" % (etiquette, nom, classer(r[0], r[1]), attendu, court(r[2])))
    with open(fichier, encoding="utf-8") as fh:
        if fh.read() != "":
            fautes.append("le fichier régulier pris pour dossier a été modifié")
    return (not fautes), ("; ".join(fautes) if fautes else "journal sous XDG_CACHE_HOME puis HOME seulement ; verdicts identiques sous 4 jeux de valeurs (dont inexploitables), copie observe et copie armed")



# --- 45-04 : poser-verdict.sh ----------------------------------------------------------------------
UNITE = ".planning/cycles/01-c/phases/01-p"


def lab_frais(ctx, nom="g5-adherent"):
    """Copie jetable (le hook et les commandes y ÉCRIVENT) d'un lab du banc, avec un CYCLE.md."""
    _, labs, _ = labs_banc(ctx)
    dest = ctx.unique("lab-" + nom)
    materialiser(labs, nom, dest)
    ecrire(os.path.join(dest, ".planning", "cycles", "01-c", "CYCLE.md"), "---\ntitre: t\nrend: r\n---\n")
    ecrire(os.path.join(dest, "livrables", "rapport.md"), "x\n")
    return dest


def lancer_script(ctx, dossier, nom, args, cwd=None):
    p = subprocess.run(["bash", os.path.join(dossier, nom)] + list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env(), cwd=cwd or ctx.work, timeout=120)
    return p.returncode, p.stdout, p.stderr


def poser(ctx, dossier, lab, tentative, juge="vf-design-judge", score="8/10", constats=("critere-a::passé",), unite=UNITE, extra=()):
    args = ["--unite=" + os.path.join(lab, unite), "--juge=" + juge, "--tentative=" + str(tentative), "--score=" + score]
    args += ["--constat=" + c for c in constats] + list(extra)
    return lancer_script(ctx, dossier, "poser-verdict.sh", args)


def octets(chemin):
    with open(chemin, "rb") as fh:
        return fh.read()


def controle_verdict_01(ctx, script):
    """Création : format de la 44 (gabarit), hash = sha256 du PLAN.md (A3), tentative 1, 0644."""
    lab = lab_frais(ctx)
    rc, out, err = poser(ctx, _dossier(ctx, script), lab, 1, constats=("critere-a::passé", "critere-b::échec"))
    chemin = os.path.join(lab, UNITE, "VERDICT.md")
    if rc != 0 or not os.path.isfile(chemin):
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    texte = octets(chemin).decode("utf-8")
    lignes = texte.split("\n")
    fin = lignes.index("---", 1)
    cles = [l.split(":")[0] for l in lignes[1:fin] if l and not l.startswith(" ")]
    empreinte = hashlib.sha256(octets(os.path.join(lab, UNITE, "PLAN.md"))).hexdigest()
    mode = stat.S_IMODE(os.stat(chemin).st_mode)
    fautes = []
    if lignes[0] != "---" or cles != ["juge", "hash", "hash_livrables", "tentative", "score", "constats"]:
        fautes.append("clés du frontmatter : %s" % cles)
    for attendu in ('juge: "vf-design-judge"', 'hash: "%s"' % empreinte, "tentative: 1", 'score: "8/10"',
                    '  - critere: "critere-a"', '    resultat: "passé"', '  - critere: "critere-b"', '    resultat: "échec"'):
        if attendu not in lignes[1:fin]:
            fautes.append("ligne absente : " + attendu)
    if "# Verdict" not in lignes[fin + 1:]:
        fautes.append("corps sans « # Verdict »")
    if not any(re.fullmatch(r'hash_livrables: "[0-9a-f]{64}"', l) for l in lignes[1:fin]):
        fautes.append("hash_livrables absent ou mal formé (empreinte de 64 hexadécimaux attendue)")
    if mode != 0o644:
        fautes.append("permissions %o" % mode)
    restes = [n for n in os.listdir(os.path.join(lab, UNITE)) if n.startswith(".")]
    if restes:
        fautes.append("fichier temporaire laissé : %s" % restes)
    return (not fautes), ("; ".join(fautes) if fautes else "code 0, VERDICT.md au format du gabarit (deux empreintes, 46-01), hash = sha256 des octets du PLAN.md, tentative 1, 0644, aucun temporaire")


def controle_verdict_02(ctx, script):
    """Tentative : 1 à la création, ancienne + 1 pour remplacer (sinon 64, fichier inchangé) ; un lien n'est
    pas un verdict existant et n'est jamais suivi (écriture atomique)."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx)
    chemin = os.path.join(lab, UNITE, "VERDICT.md")
    rc, _o, err = poser(ctx, d, lab, 1)
    if rc != 0:
        return False, "création refusée : rc=%d %s" % (rc, court(err))
    avant = octets(chemin)
    fautes = []
    for n in (1, 3):
        rc, _o, err = poser(ctx, d, lab, n)
        if rc != 64 or octets(chemin) != avant:
            fautes.append("--tentative=%d sur une tentative 1 : rc=%d, fichier %s" % (n, rc, "inchangé" if octets(chemin) == avant else "MODIFIÉ"))
    rc, _o, err = poser(ctx, d, lab, 2)
    if rc != 0 or b"tentative: 2" not in octets(chemin):
        fautes.append("--tentative=2 : rc=%d %s" % (rc, court(err)))
    # création à tentative 2 : refusée
    lab2 = lab_frais(ctx)
    rc, _o, err = poser(ctx, d, lab2, 2)
    if rc != 64 or os.path.exists(os.path.join(lab2, UNITE, "VERDICT.md")):
        fautes.append("création à --tentative=2 : rc=%d" % rc)
    # un lien posé à la place de VERDICT.md : remplacé, jamais suivi
    lab3 = lab_frais(ctx)
    cible = os.path.join(lab3, "livrables", "cible-du-lien.txt")
    ecrire(cible, "CIBLE\n")
    os.symlink(cible, os.path.join(lab3, UNITE, "VERDICT.md"))
    rc, _o, err = poser(ctx, d, lab3, 1)
    lien = os.path.join(lab3, UNITE, "VERDICT.md")
    if rc != 0 or os.path.islink(lien) or not os.path.isfile(lien) or octets(cible) != b"CIBLE\n":
        fautes.append("lien à la place de VERDICT.md : rc=%d, lien=%s, cible %s" % (rc, os.path.islink(lien), "inchangée" if octets(cible) == b"CIBLE\n" else "MODIFIÉE"))
    return (not fautes), ("; ".join(fautes) if fautes else "1 à la création, 1 et 3 refusés (64, cmp identique) sur une tentative 1, 2 accepté ; création à 2 refusée ; un lien est remplacé, sa cible intacte")


def controle_verdict_03(ctx, script):
    """recalc-planning.sh --read-only relit la tentative et le hash écrits (format de la 44)."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx)
    os.rmdir(os.path.join(lab, UNITE, "plans", "01-a"))  # une phase à plan direct n'a pas de plans/ (raison plan-direct-et-plans)
    os.rmdir(os.path.join(lab, UNITE, "plans"))
    ecrire(os.path.join(lab, UNITE, "SUMMARY.md"), "---\nauteur: vf-coder\n---\n")
    for n in (1, 2):
        rc, _o, err = poser(ctx, d, lab, n)
        if rc != 0:
            return False, "tentative %d : rc=%d %s" % (n, rc, court(err))
    p = subprocess.run(["bash", ctx.recalc, "--planning=" + os.path.join(lab, ".planning"), "--read-only"],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), timeout=120)
    if p.returncode != 0:
        return False, "recalc --read-only : rc=%d %s" % (p.returncode, court(p.stderr))
    rapport = json.loads(p.stdout.decode("utf-8"))
    phases = [ph for c in rapport["cycles"] for ph in c.get("phases", []) if ph["chemin"].endswith("01-p")]
    empreinte = hashlib.sha256(octets(os.path.join(lab, UNITE, "PLAN.md"))).hexdigest()
    if len(phases) != 1:
        return False, "phase 01-p introuvable : " + court(p.stdout)
    ph = phases[0]
    if str(ph.get("tentative")) != "2" or ph.get("hash_juge") != empreinte or ph.get("etat") != "close":
        return False, "tentative=%r hash=%r état=%r raison=%r" % (ph.get("tentative"), ph.get("hash_juge"), ph.get("etat"), ph.get("raison"))
    return True, "recalc --read-only rend tentative 2, le hash écrit et l'état close pour l'unité"


def controle_verdict_04(ctx, script):
    """Refus : lab non adhérent 2 ; unité hors .planning/cycles/, sans PLAN.md, constat, tentative, juge ou
    valeur qui ne se relit pas identique 64 ; jamais un fichier écrit."""
    d = _dossier(ctx, script)
    fautes = []
    dev = lab_frais(ctx, "g5-dev")
    rc, _o, err = poser(ctx, d, dev, 1)
    if rc != 2 or os.path.exists(os.path.join(dev, UNITE, "VERDICT.md")):
        fautes.append("lab non adhérent : rc=%d (attendu 2)" % rc)
    hors = dossier_neuf(ctx, "verdict-hors-lab")
    ecrire(os.path.join(hors, "PLAN.md"), "---\necrit: a\n---\n")
    rc, _o, err = lancer_script(ctx, d, "poser-verdict.sh", ["--unite=" + hors, "--juge=j", "--tentative=1", "--score=s", "--constat=c::passé"])
    if rc != 2 or os.path.exists(os.path.join(hors, "VERDICT.md")):
        fautes.append("unité hors de tout lab : rc=%d (attendu 2)" % rc)
    lab = lab_frais(ctx)
    ecrire(os.path.join(lab, ".planning", "notes", "PLAN.md"), "---\necrit: a\n---\n")
    cas = (("unité hors .planning/cycles/", {"unite": ".planning/notes"}, 64),
           ("unité sans PLAN.md", {"unite": UNITE + "/plans/01-a"}, 64),
           ("unité inexistante", {"unite": UNITE + "/absente"}, 64),
           ("constat au résultat hors passé/échec", {"constats": ("critere::peut-etre",)}, 64),
           ("constat sans ::", {"constats": ("critere",)}, 64),
           ("constat au critère vide", {"constats": ("::passé",)}, 64),
           ("tentative non numérique", {"tentative": "x"}, 64),
           ("tentative nulle", {"tentative": "0"}, 64),
           ("juge vide", {"juge": ""}, 64),
           ("score avec saut de ligne", {"score": "a\nb"}, 64),
           ("critère avec guillemet et saut de ligne", {"constats": ('a"\nb::passé',)}, 64))
    for nom, surcharge, attendu in cas:
        args = dict(unite=UNITE, tentative=1, juge="j", score="s", constats=("c::passé",))
        args.update(surcharge)
        rc, _o, err = poser(ctx, d, lab, args["tentative"], juge=args["juge"], score=args["score"], constats=args["constats"], unite=args["unite"])
        ecrits = [os.path.join(dp, f) for dp, _dn, fs in os.walk(os.path.join(lab, ".planning")) for f in fs if f == "VERDICT.md" or f.startswith(".VERDICT.")]
        if rc != attendu or ecrits:
            fautes.append("%s : rc=%d (attendu %d), écrit %s" % (nom, rc, attendu, [os.path.relpath(e, lab) for e in ecrits]))
    return (not fautes), ("; ".join(fautes) if fautes else "lab dev 2, hors lab 2, %d refus 64 : unité hors cycles, sans PLAN.md, constat, tentative, juge, valeur non relisible ; aucun fichier écrit" % len(cas))


def controle_verdict_05(ctx, script):
    """La commande ne passe jamais par un outil : lancée par Bash pendant que G5 est armé, le hook n'en voit
    rien et elle écrit (alors qu'un Write du même fichier est refusé)."""
    d = _dossier(ctx, script)
    armee = ctx.copie_forcee(ctx.scripts_dir, "armed")
    lab = lab_frais(ctx)
    commande = "bash '%s' --unite=%s --juge=vf-design-judge --tentative=1 --score=8/10 --constat=c::passé" % (
        os.path.join(d, "poser-verdict.sh"), os.path.join(lab, UNITE))
    brut = payload("Bash", {"command": commande}, lab)
    rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=armee)
    if classer(rc, out) == "deny" or err:
        return False, "le hook armé voit la commande Bash : " + classer(rc, out) + " " + court(out)
    brut = payload("Write", {"file_path": os.path.join(lab, UNITE, "VERDICT.md"), "content": "x"}, lab)
    rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=armee)
    if classer(rc, out) != "deny":
        return False, "témoin : le Write du même fichier n'est pas refusé sur la copie armée : " + classer(rc, out)
    rc, out, err = poser(ctx, d, lab, 1)
    if rc != 0 or not os.path.isfile(os.path.join(lab, UNITE, "VERDICT.md")):
        return False, "la commande n'a pas écrit : rc=%d %s" % (rc, court(err))
    return True, "G5 armé : la commande Bash n'est pas refusée et écrit, le Write du même fichier l'est"



# --- 45-04 : deroger-gate.sh et dérogations du hook -------------------------------------------------
def journal_derog(lab):
    return os.path.join(lab, ".planning", "derogations-gates.log")


def deroger(ctx, lab, dossier=None, gate="G5", chemins=(VERDICT_REL,), qui="willy", canal="AskUserQuestion session principale",
            date="2026-09-30", raison="cas de test de la dérogation", extra=()):
    args = ["--lab=" + lab, "--gate=" + gate] + ["--chemin=" + c for c in chemins]
    args += ["--qui=" + qui, "--canal=" + canal, "--date=" + date, "--raison=" + raison] + list(extra)
    return lancer_script(ctx, dossier or ctx.scripts_dir, "deroger-gate.sh", args)


def ecrire_dans(ctx, dossier_hook, lab, outil, rel, extra_env=None):
    brut = payload(outil, entree_outil(outil, os.path.join(lab, rel)), lab)
    return ctx.lancer("A", brut, cwd=lab, dossier=dossier_hook, extra_env=extra_env)


def lignes_de(chemin):
    if not os.path.exists(chemin):
        return []
    return [l for l in octets(chemin).decode("utf-8").split("\n") if l]


def controle_derog_01(ctx, script):
    """Dérogation valide : une ligne par chemin, ids 1 et 2, journal jamais tronqué, 0644."""
    d = _dossier(ctx, script)
    fautes = []
    lab = lab_frais(ctx)
    rc, out, err = deroger(ctx, lab, d, gate="G6", chemins=(".planning/cycles/01-c/CYCLE.md",))
    lignes = lignes_de(journal_derog(lab))
    attendu = "  derogation  id=1  gate=G6  chemin=.planning/cycles/01-c/CYCLE.md  qui=willy  canal=AskUserQuestion%20session%20principale  date=2026-09-30  raison=cas%20de%20test%20de%20la%20d"
    if rc != 0 or len(lignes) != 1 or attendu not in lignes[0]:
        fautes.append("une dérogation : rc=%d lignes=%s stderr=%s" % (rc, lignes, court(err)))
    elif stat.S_IMODE(os.stat(journal_derog(lab)).st_mode) != 0o644:
        fautes.append("permissions du journal")
    lab2 = lab_frais(ctx)
    rc, out, err = deroger(ctx, lab2, d, chemins=(VERDICT_REL, "livrables/rapport.md"))
    lignes = lignes_de(journal_derog(lab2))
    if rc != 0 or len(lignes) != 2 or "  id=1  " not in lignes[0] or "  id=2  " not in lignes[1]:
        fautes.append("deux chemins : rc=%d lignes=%s" % (rc, lignes))
    avant = octets(journal_derog(lab2))
    rc, out, err = deroger(ctx, lab2, d, gate="G1", chemins=("livrables/autre.md",))
    apres = octets(journal_derog(lab2))
    if rc != 0 or not apres.startswith(avant) or len(lignes_de(journal_derog(lab2))) != 3 or "  id=3  " not in lignes_de(journal_derog(lab2))[2]:
        fautes.append("ajout : préfixe conservé=%s rc=%d" % (apres.startswith(avant), rc))
    lab3 = lab_frais(ctx)
    with open(journal_derog(lab3), "wb") as fh:
        fh.write(b"ancien sans saut final")
    rc, out, err = deroger(ctx, lab3, d)
    apres = octets(journal_derog(lab3))
    derniere = lignes_de(journal_derog(lab3))[-1] if lignes_de(journal_derog(lab3)) else ""
    if rc != 0 or not apres.startswith(b"ancien sans saut final") or "  derogation  id=1  gate=G5  " not in derniere:
        fautes.append("journal sans saut final : rc=%d dernière=%s" % (rc, court(derniere)))
    return (not fautes), ("; ".join(fautes) if fautes else "une ligne par chemin (ids 1 et 2, puis 3), préfixe d'octets conservé, journal 0644, saut de ligne ajouté si absent")


def controle_derog_02(ctx, script):
    """Raison placeholder (après NFKC), qui, canal, date ou gate invalides : 64, le message nomme le champ, rien écrit."""
    d = _dossier(ctx, script)
    fautes = []
    lab = lab_frais(ctx)
    cas = [("raison vide", {"raison": ""}, "--raison")]
    for valeur in ("TODO", "todo", "xxx", "XXXX", "…", "...", "<raison>", "<…>", "ＴＯＤＯ", "ＸＸＸ", "．．．", "＜raison＞", "​", "   "):
        cas.append(("raison %r" % valeur, {"raison": valeur}, "--raison"))
    cas += [("qui vide", {"qui": ""}, "--qui"), ("canal vide", {"canal": ""}, "--canal"),
            ("date 2026-13-01", {"date": "2026-13-01"}, "--date"), ("date 30/09/2026", {"date": "30/09/2026"}, "--date"),
            ("date 2026-9-30", {"date": "2026-9-30"}, "--date"), ("gate G2", {"gate": "G2"}, "--gate"),
            ("gate g5", {"gate": "g5"}, "--gate"), ("chemin absolu", {"chemins": ("/etc/passwd",)}, "--chemin"),
            ("chemin avec ..", {"chemins": ("../x",)}, "--chemin")]
    for nom, surcharge, champ in cas:
        rc, out, err = deroger(ctx, lab, d, **surcharge)
        if rc != 64 or champ.encode("utf-8") not in err or os.path.exists(journal_derog(lab)):
            fautes.append("%s : rc=%d (attendu 64), champ %s %s, journal %s" % (nom, rc, champ, "nommé" if champ.encode("utf-8") in err else "NON nommé", "écrit" if os.path.exists(journal_derog(lab)) else "absent"))
    rc, out, err = lancer_script(ctx, d, "deroger-gate.sh", ["--lab=" + lab, "--gate=G5", "--chemin=a", "--qui=w", "--canal=c", "--date=2026-09-30"])
    if rc != 64 or b"--raison" not in err:
        fautes.append("option --raison absente : rc=%d" % rc)
    rc, out, err = deroger(ctx, lab, d, raison="raison réelle et motivée")
    if rc != 0:
        fautes.append("témoin : une raison réelle est refusée (rc=%d %s)" % (rc, court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus 64 qui nomment le champ (placeholders en pleine chasse compris), rien écrit ; une raison réelle passe" % (len(cas) + 1))


def controle_derog_03(ctx, script):
    """Une raison qui contient un saut de ligne et des lignes de journal factices : UNE ligne, aucune fausse consommation."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx)
    raison = "ok\n2026-09-30T00:00:00+00:00  consommee  id=1  gate=G5  chemin=x\n  consommee id=1"
    rc, out, err = deroger(ctx, lab, d, raison=raison)
    lignes = lignes_de(journal_derog(lab))
    if rc != 0:
        return False, "rc=%d %s" % (rc, court(err))
    fausses = [l for l in lignes if l.split("  ")[1:2] == ["consommee"]]
    if len(lignes) != 1 or fausses or octets(journal_derog(lab)).count(b"\n") != 1:
        return False, "%d ligne(s), fausses consommations %s : %s" % (len(lignes), fausses, court("\n".join(lignes)))
    return True, "une seule ligne de journal (encodage pourcent), aucune fausse consommation"


def _scenario_derog(ctx, script, etape):
    """(lab, dossier du hook forcé à `etape`) avec une dérogation G5 posée par la commande livrée."""
    lab = lab_frais(ctx)
    rc, out, err = deroger(ctx, lab)
    if rc != 0:
        raise RuntimeError("deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err)))
    return lab, ctx.copie_forcee(_dossier(ctx, script), etape)


def controle_derog_04(ctx, script):
    """Copie armed, Write de VERDICT.md couvert par une dérogation G5 : pas de refus, citation, consommation."""
    lab, hook = _scenario_derog(ctx, script, "armed")
    rc, out, err = ecrire_dans(ctx, hook, lab, "Write", VERDICT_REL)
    if classer(rc, out) != "avertit" or err:
        return False, "%s %s" % (classer(rc, out), court(out))
    texte = contexte_de(out)
    manque = [m for m in ("#1", "G5", "willy", "AskUserQuestion session principale", "2026-09-30", "cas de test de la dérogation") if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=G5  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    return True, "pas de refus, additionalContext qui cite id, qui, canal, date et raison, ligne consommee id=1 ajoutée"


def controle_derog_05(ctx, script):
    """Usage unique : le second Write identique est refusé, un autre chemin aussi."""
    lab, hook = _scenario_derog(ctx, script, "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", VERDICT_REL)
    r2 = ecrire_dans(ctx, hook, lab, "Write", VERDICT_REL)
    r3 = ecrire_dans(ctx, hook, lab, "Write", ".planning/cycles/01-c/phases/01-p/plans/01-a/VERDICT.md")
    fautes = []
    if classer(r1[0], r1[1]) != "avertit":
        fautes.append("premier Write : " + classer(r1[0], r1[1]))
    if classer(r2[0], r2[1]) != "deny":
        fautes.append("second Write identique : " + classer(r2[0], r2[1]) + " (dérogation consommée attendue refusée)")
    if classer(r3[0], r3[1]) != "deny":
        fautes.append("autre chemin : " + classer(r3[0], r3[1]))
    return (not fautes), ("; ".join(fautes) if fautes else "premier Write passe et cité, second Write identique refusé, autre chemin refusé")


def controle_derog_06(ctx, script):
    """Gate en observe : la dérogation n'est ni citée ni consommée."""
    lab, hook_obs = _scenario_derog(ctx, script, "observe")
    hook_arm = ctx.copie_forcee(_dossier(ctx, script), "armed")
    avant = octets(journal_derog(lab))
    cache = dossier_neuf(ctx, "cache-derog-06")
    rc, out, err = ecrire_dans(ctx, hook_obs, lab, "Write", VERDICT_REL, extra_env={"XDG_CACHE_HOME": cache})
    if rc != 0 or out != b"" or err or octets(journal_derog(lab)) != avant:
        return False, "observe : rc=%d stdout=%s journal %s" % (rc, court(out), "inchangé" if octets(journal_derog(lab)) == avant else "MODIFIÉ")
    if len(lignes_journal(cache)) != 1:
        return False, "observe : %d ligne(s) d'observation (attendu 1)" % len(lignes_journal(cache))
    rc, out, err = ecrire_dans(ctx, hook_arm, lab, "Write", VERDICT_REL)
    if classer(rc, out) != "avertit":
        return False, "la dérogation a été consommée en observe : armed -> " + classer(rc, out)
    return True, "observe : silence, journal inchangé (octet pour octet), ligne d'observation écrite ; la dérogation sert ensuite en armed"


def controle_derog_07(ctx, script):
    """Journal remplacé par un lien vers un fichier qui porte une dérogation : aucune n'est active."""
    lab, hook = _scenario_derog(ctx, script, "armed")
    reel = os.path.join(lab, ".planning", "derogations-reel.txt")
    os.rename(journal_derog(lab), reel)
    os.symlink(reel, journal_derog(lab))
    avant = octets(reel)
    rc, out, err = ecrire_dans(ctx, hook, lab, "Write", VERDICT_REL)
    if classer(rc, out) != "deny" or octets(reel) != avant:
        return False, "%s, cible %s" % (classer(rc, out), "inchangée" if octets(reel) == avant else "MODIFIÉE")
    return True, "journal en lien symbolique : dérogation inactive, refus maintenu, cible intacte"


def controle_derog_08(ctx, script):
    """Aucune option de la commande ne porte sur l'urgence, la vitesse ou une durée."""
    d = _dossier(ctx, script)
    rc, aide, err = lancer_script(ctx, d, "deroger-gate.sh", ["-h"])
    autorisees = {"lab", "gate", "chemin", "qui", "canal", "date", "raison"}
    interdits = ("urgen", "vite", "rapid", "dur", "delai", "délai", "expir", "ttl", "timeout", "heure", "minute", "seconde", "temp", "now")
    fautes = []
    jetons = set(re.findall(r"--([a-z-]+)", aide.decode("utf-8")))
    if rc != 0 or not jetons or jetons - autorisees:
        fautes.append("aide -h : rc=%d options %s" % (rc, sorted(jetons)))
    source = open(os.path.join(d, "deroger-gate.sh"), encoding="utf-8").read()
    m = re.search(r"^OPTIONS = \(([^)]*)\)", source, re.M)
    declarees = set(re.findall(r'"([a-z-]+)"', m.group(1))) if m else set()
    if not declarees or declarees - autorisees:
        fautes.append("parseur : options déclarées %s" % sorted(declarees))
    for nom in jetons | declarees:
        if any(s in nom for s in interdits):
            fautes.append("option %s : nom lié au temps ou à l'urgence" % nom)
    lab = lab_frais(ctx)
    for extra in (["--urgence=oui"], ["--duree=1h"], ["--vite"], ["--expire=demain"]):
        rc, out, err = deroger(ctx, lab, d, extra=extra)
        if rc != 64 or os.path.exists(journal_derog(lab)):
            fautes.append("%s : rc=%d (attendu 64)" % (extra[0], rc))
    return (not fautes), ("; ".join(fautes) if fautes else "sept options (lab, gate, chemin, qui, canal, date, raison), aucune liée à l'urgence, la vitesse ou une durée ; quatre options de ce genre refusées (64)")


# --- 45-05 : G6 (fichiers générés) et canary des gates de l'étape 1 ---------------------------------------
PROTEGES_BANC = (".planning/STATE.md", ".planning/INDEX.md", ".planning/cloture.log", ".planning/derogations-gates.log")


def _g6(ctx, dossier_hook, outil, rel, agent=None, lab="g6-adherent", extra_env=None, entree=None):
    return _g5(ctx, dossier_hook, outil, rel, agent=agent, lab=lab, extra_env=extra_env, entree=entree)


def controle_g6_01(ctx, script):
    """Copie observe : Write d'un fichier généré -> silence, code 0, UNE ligne gate=G6 au journal d'observation."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g6-01")
    rc, out, err = _g6(ctx, d, "Write", ".planning/STATE.md", extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    for motif in ("  gate=G6  ", "  chemin=.planning/STATE.md  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : silence, code 0, une ligne gate=G6 (chemin, outil) au journal d'observation"


def controle_g6_02(ctx, script):
    """Copie armed : Write et Edit de chaque fichier généré, fil principal et agent inconnu -> un deny G6 chacun,
    dont le motif dit par quelle commande poser le fichier (Pitfall 9)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for rel in PROTEGES_BANC:
        attendu_cmd = "deroger-gate.sh" if rel.endswith("derogations-gates.log") else "recalc-planning.sh"
        for outil in ("Write", "Edit"):
            for agent in (None, "agent-inconnu"):
                rc, out, err = _g6(ctx, d, outil, rel, agent=agent)
                n += 1
                v = classer(rc, out)
                if v != "deny" or err or len(out.splitlines()) != 1:
                    fautes.append("%s %s agent=%s -> %s" % (outil, rel, agent, v))
                    continue
                raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
                if not raison.startswith("[planning-core] G6 :") or attendu_cmd not in raison:
                    fautes.append("%s %s agent=%s : raison %s" % (outil, rel, agent, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G6 (4 fichiers, Write et Edit, fil principal et agent inconnu), le motif nomme recalc-planning.sh ou deroger-gate.sh" % n)


def controle_g6_03(ctx, script):
    """Copie armée : compartiments, plans du modèle, notes -> aucun refus de G6."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for rel in (".planning/workstreams/x/STATE.md", ".planning/compartments/x/STATE.md",
                ".planning/cycles/01-c/phases/01-p/PLAN.md", ".planning/notes.md", ".planning/STATE.md.bak"):
        rc, out, err = _g6(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"G6" in out:
            fautes.append("%s -> %s %s" % (rel, classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "aucun refus : STATE.md de workstreams et de compartments, PLAN.md du modèle, notes, nom voisin")


def controle_g6_04(ctx, script):
    """Copie armée, lab dev : Write d'un fichier généré -> stdout d'octet vide."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    rc, out, err = _g6(ctx, d, "Write", ".planning/STATE.md", lab="g6-dev")
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s" % (rc, court(out))
    return True, "lab dev, copie armée : code 0 et stdout d'octet vide"


def controle_g6_05(ctx, script):
    """Une dérogation G6 active sur le fichier généré : passage cité et consommé, le second Write est refusé."""
    lab = lab_frais(ctx, "g6-adherent")
    os.remove(journal_derog(lab))  # journal neuf : la dérogation posée ci-dessous porte l'identifiant 1
    rc, out, err = deroger(ctx, lab, None, gate="G6", chemins=(".planning/STATE.md",))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", ".planning/STATE.md")
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "G6", "willy", "AskUserQuestion session principale", "2026-09-30") if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=G6  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    r2 = ecrire_dans(ctx, hook, lab, "Write", ".planning/STATE.md")
    if classer(r2[0], r2[1]) != "deny":
        return False, "second Write : " + classer(r2[0], r2[1])
    return True, "dérogation G6 : premier Write passe et cité, dérogation consommée, second Write refusé"


def scripts_canary(ctx, source, valeur, hook=None, armes=("G6", "G5"), tel_quel=False):
    """Dossier de scripts jetable : check-gates-alive.sh de `source` et planning-hook.sh (celui de `hook`, à
    défaut de `source`) dont les gates de `armes` (G6 et G5 par défaut) valent `valeur`, les autres gates restant à
    observe ; `tel_quel` : le hook n'est pas réécrit (l'état livré)."""
    texte = open(hook or os.path.join(source, "planning-hook.sh"), encoding="utf-8").read()
    for gate in ("G6", "G5", "G1", "G7", "ROLE"):
        if tel_quel:
            break
        v = valeur if gate in armes else "observe"
        texte, n = re.subn(r'^(ARMEMENT_' + gate + r' = )"(?:observe|armed)"', r'\1"' + v + '"', texte, flags=re.M)
        if n != 1:
            raise RuntimeError("une ligne ARMEMENT_%s attendue, %d trouvée(s)" % (gate, n))
    d = os.path.join(ctx.unique("projet-canary-" + valeur), ".claude", "scripts")  # forme du scope projet
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
        fh.write(texte)
    shutil.copy(os.path.join(source, "check-gates-alive.sh"), os.path.join(d, "check-gates-alive.sh"))
    for nom in ("planning-hook.sh", "check-gates-alive.sh"):
        os.chmod(os.path.join(d, nom), 0o755)
    return d


EVENEMENTS_CABLES = ("PreToolUse", "SubagentStop", "CwdChanged", "FileChanged", "SessionStart")


def reglage_cinq_evenements(chemin, commande, sans=(), autre=None):
    """Réglage jetable : `commande` sous les cinq événements (PreToolUse au matcher Write, les quatre autres sans matcher, Phase 46) ;
    `sans` : événements omis ; `autre` : (événement, commande) remplace la commande de cet événement."""
    hooks = {}
    for evt in EVENEMENTS_CABLES:
        if evt in sans:
            continue
        groupe = {"hooks": [{"type": "command", "command": autre[1] if autre and autre[0] == evt else commande}]}
        if evt == "PreToolUse":
            groupe["matcher"] = "Write"
        hooks[evt] = [groupe]
    ecrire(chemin, json.dumps({"hooks": hooks}))


def lancer_canary_dossier(ctx, dossier):
    """Lance le check-gates-alive.sh de `dossier` (= <projet>/.claude/scripts) dans une session adhérente,
    `--settings` vers un réglage jetable dont la commande enregistrée (hooks.json, scope projet :
    "$CLAUDE_PROJECT_DIR"/.claude/scripts) vise ce même projet, posée sous les cinq événements (Phase 46)."""
    if TOKEN not in (ctx.cmd or ""):
        raise RuntimeError("la commande enregistrée ne porte pas le jeton " + TOKEN)
    projet = os.path.dirname(os.path.dirname(dossier))
    lab = ctx.unique("session-canary")
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    reglage = os.path.join(ctx.unique("reglage-canary"), "settings.json")
    reglage_cinq_evenements(reglage, ctx.cmd.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts'))
    p = subprocess.run(["bash", os.path.join(dossier, "check-gates-alive.sh"), "--settings=" + reglage],
                       input=json.dumps({"cwd": lab}).encode("utf-8"), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env={"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": ctx.home, "CLAUDE_PROJECT_DIR": projet},
                       cwd=lab, timeout=240)
    return p.returncode, p.stdout, p.stderr


def controle_cang_01(ctx, script):
    """G6 et G5 en observe : les trois cas du canary trouvent leur ligne d'observation -> code 3, stdout vide."""
    d = scripts_canary(ctx, _dossier(ctx, script), "observe")
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    return True, "G6 et G5 observe : code 3, stdout vide (G6-principal, G6-plugin et G5-verdict trouvent leur ligne d'observation)"


def controle_cang_02(ctx, script):
    """G6 et G5 armed : les trois cas obtiennent un deny de gate -> code 3, stdout vide."""
    d = scripts_canary(ctx, _dossier(ctx, script), "armed")
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    return True, "G6 et G5 armed : code 3, stdout vide (les trois cas obtiennent un refus de gate, jamais le texte du fail-closed)"


def controle_cang_03(ctx, script):
    """evaluer_g6 neutralisé (jamais de verdict) : le canary signale, code 0, UNE ligne qui nomme G6 — observe comme armed."""
    neutre, raison = make_hook_mutant(ctx, "G6-NEUTRE", "# gates-a-verdict", 'GATES_A_VERDICT = (("G5", evaluer_g5), ("G1", evaluer_g1), ("G7", evaluer_g7), ("ROLE", evaluer_role))  # gates-a-verdict')
    if neutre is None:
        return False, "mutant du hook invalide : " + raison
    fautes = []
    for valeur in ("observe", "armed"):
        d = scripts_canary(ctx, _dossier(ctx, script), valeur, hook=os.path.join(neutre, "planning-hook.sh"))
        rc, out, err = lancer_canary_dossier(ctx, d)
        texte = out.decode("utf-8", "replace")
        lignes = [l for l in texte.split("\n") if l]
        if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "G6" not in lignes[0] or "G5-verdict" in lignes[0]:
            fautes.append("%s : rc=%d %s" % (valeur, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "evaluer_g6 neutralisé, observe et armed : code 0 et une ligne qui nomme G6 (et pas G5)")


# --- Phase 46, 46-04 : le canary retrouve la commande sous les cinq événements ; deux cas DEGRADE pour SubagentHandback ---------
def controle_cang_evt_01(ctx, script):
    """R-CANG-EVT-01 : un réglage jetable portant la commande de référence sous les cinq événements : code 3 (sain), stdout vide ; privé de
    l'entrée FileChanged (puis SubagentStop, CwdChanged, SessionStart) : code 0 et UNE ligne de signal qui nomme l'événement manquant,
    sous --hook comme en direct ; deux événements manquants : les deux nommés ; une AUTRE commande sous SubagentStop : signal « non reconnue »
    qui nomme l'événement, la commande n'étant jamais exécutée."""
    d = scripts_canary(ctx, _dossier(ctx, script), "observe", tel_quel=True)
    projet = os.path.dirname(os.path.dirname(d))
    reelle = ctx.cmd.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts')
    fautes = []

    def lancer(args=(), **kw):
        reglage = os.path.join(ctx.unique("reglage-evt"), "settings.json")
        reglage_cinq_evenements(reglage, reelle, **kw)
        return canary_direct(ctx, d, reglage, args, projet=projet)

    rc, out, err = lancer()
    if rc != 3 or out != b"":
        fautes.append("cinq événements : code 3 et stdout vide (attendu) — obtenu rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    for args in ((), ("--hook",)):
        rc, out, err = lancer(args, sans=("FileChanged",))
        raison = une_ligne_canary(out, ("FileChanged", "non câblé"))
        if rc != 0 or raison:
            fautes.append("sans FileChanged %s : code 0 et UNE ligne qui nomme FileChanged (attendu) — obtenu rc=%d %s" % (" ".join(args) or "sans --hook", rc, raison or ""))
    for evt in ("SubagentStop", "CwdChanged", "SessionStart"):
        rc, out, err = lancer(sans=(evt,))
        raison = une_ligne_canary(out, (evt, "non câblé"))
        if rc != 0 or raison:
            fautes.append("sans %s : code 0 et UNE ligne qui nomme %s (attendu) — obtenu rc=%d %s" % (evt, evt, rc, raison or ""))
    rc, out, err = lancer(sans=("CwdChanged", "FileChanged"))
    raison = une_ligne_canary(out, ("CwdChanged", "FileChanged"))
    if rc != 0 or raison:
        fautes.append("sans CwdChanged ni FileChanged : code 0 et UNE ligne qui nomme les deux (attendu) — obtenu rc=%d %s" % (rc, raison or ""))
    marqueur = os.path.join(ctx.unique("marqueur-evt"), "cree")
    os.makedirs(os.path.dirname(marqueur))
    rc, out, err = lancer(autre=("SubagentStop", "touch '%s' # planning-hook.sh" % marqueur))
    raison = une_ligne_canary(out, ("non reconnue", "SubagentStop"))
    if rc != 0 or raison or os.path.exists(marqueur):
        fautes.append("autre commande sous SubagentStop : code 0, UNE ligne « non reconnue » qui nomme SubagentStop, commande jamais exécutée (attendu) — obtenu rc=%d %s marqueur=%s"
                      % (rc, raison or "", os.path.exists(marqueur)))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "cinq événements : code 3 ; privé de FileChanged (--hook compris), SubagentStop, CwdChanged ou SessionStart : une ligne qui nomme l'événement ; deux manquants : les deux nommés ; autre commande sous SubagentStop : « non reconnue », jamais exécutée")


def controle_cang_evt_02(ctx, script):
    """R-CANG-EVT-02 : les cas DEGRADE `D09` (script absent) et `D10` (python absent), payload SubagentHandback, sont dans CANARIS ; ils sont
    COUVERTS : sur une commande de référence dont la couche de repli a perdu l'alternative SubagentHandback, le canary signale (code 0, UNE
    ligne « cas en échec ») exactement ces deux cas ; sur la commande livrée il est sain (R-CANG-EVT-01)."""
    d = scripts_canary(ctx, _dossier(ctx, script), "observe", tel_quel=True)
    projet = os.path.dirname(os.path.dirname(d))
    texte = open(os.path.join(d, "check-gates-alive.sh"), encoding="utf-8").read()
    fautes = []
    for ident, mode in (("D09", "script-absent"), ("D10", "python-absent")):
        motif = '"%s|DEGRADE|%s|SubagentHandback|%s",' % (ident, mode, mode)
        if texte.count(motif) != 1:
            fautes.append("cas %s dans CANARIS (attendu : une ligne `%s`) — obtenu %d occurrence(s)" % (ident, motif, texte.count(motif)))
    alternative = "|*'\"tool_name\":\"SubagentHandback\"'*|*'\"tool_name\":\"Agent\"'*"
    if ctx.cmd.count(alternative) != 1:
        return False, "la commande enregistrée porte l'alternative SubagentHandback entre NotebookEdit et Agent (attendu 1) — obtenu %d" % ctx.cmd.count(alternative)
    sans_repli = ctx.cmd.replace(alternative, "|*'\"tool_name\":\"Agent\"'*")
    reference = os.path.join(ctx.unique("reference-evt"), "reference.txt")
    ecrire(reference, sans_repli)
    reglage = os.path.join(ctx.unique("reglage-evt02"), "settings.json")
    reglage_cinq_evenements(reglage, sans_repli.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts'))
    rc, out, err = canary_direct(ctx, d, reglage, ("--reference=" + reference,), projet=projet)
    raison = une_ligne_canary(out, ("2 cas en échec", "D09", "D10"))
    if rc != 0 or raison:
        fautes.append("repli sans SubagentHandback : code 0 et UNE ligne « 2 cas en échec » qui nomme D09 et D10 (attendu) — obtenu rc=%d %s stderr=%s" % (rc, raison or "", court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "D09 et D10 présents dans CANARIS ; couverts : sans l'alternative SubagentHandback du repli, le canary signale exactement ces deux cas (« 2 cas en échec »)")


# --- 45-05 : identité des fichiers protégés (Pattern 5), périmètre F6 et F7b ---------------------------------
def lab_identite(ctx):
    """Copie jetable du lab g6-adherent, sans INDEX.md (la création d'un nom protégé ABSENT se juge par la casse),
    avec un lien dur vers le fichier d'état dans le dossier de planning et hors de lui, et un alias du
    dossier de planning."""
    lab = lab_frais(ctx, "g6-adherent")
    os.remove(os.path.join(lab, ".planning", "INDEX.md"))
    etat = os.path.join(lab, ".planning", "STATE.md")
    os.link(etat, os.path.join(lab, ".planning", "hard.md"))
    os.link(etat, os.path.join(lab, "livrables", "lien-dur.md"))
    os.symlink(".planning", os.path.join(lab, "alias-planning"))
    return lab


def _refus_de(ctx, hook, lab, gate, outil, rel=None, entree=None, agent=None):
    """(conforme, détail) : un deny dont la raison commence par `[planning-core] <gate> :`."""
    chemin = os.path.join(lab, rel) if rel else None
    e = entree if entree is not None else entree_outil(outil, chemin)
    rc, out, err = ctx.lancer("A", payload(outil, e, lab, agent_type=agent), cwd=lab, dossier=hook)
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return False, "%s %s -> %s %s" % (outil, rel, v, court(out))
    raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    if not raison.startswith("[planning-core] %s :" % gate):
        return False, "%s %s : raison %s" % (outil, rel, raison)
    return True, raison


def _passage_de(ctx, hook, lab, outil, rel, entree=None):
    chemin = os.path.join(lab, rel)
    e = entree if entree is not None else entree_outil(outil, chemin)
    rc, out, err = ctx.lancer("A", payload(outil, e, lab), cwd=lab, dossier=hook)
    v = classer(rc, out)
    return (v in ("silence", "avertit") and not err and b"[planning-core] G6" not in out and b"[planning-core] G5" not in out), "%s %s -> %s %s" % (outil, rel, v, court(out))


def controle_id_01(ctx, script):
    """Copie armée : variante de casse, lien dur (dans et hors du dossier de planning), alias du dossier de
    planning, segment `..`, création d'un nom protégé absent en autre casse -> refus de G6 ; jumeaux sans refus."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_identite(ctx)
    fautes = []
    cas = ((".planning/state.md", None), (".PLANNING/STATE.md", None), (".planning/Index.md", None),
           (".planning/Cloture.Log", None), (".planning/hard.md", None), ("livrables/lien-dur.md", None),
           ("alias-planning/STATE.md", None), (".planning/x/../STATE.md", None),
           (".planning/hard.md", "agent-inconnu"), ("alias-planning/STATE.md", "plugin-inconnu:agent-inconnu"))
    for rel, agent in cas:
        bon, detail = _refus_de(ctx, hook, lab, "G6", "Write", rel, agent=agent)
        if not bon:
            fautes.append(detail)
    for rel in ("livrables/STATE.md", "livrables/INDEX.md", "notes/STATE.md", ".planning/STATE.md.bak"):
        bon, detail = _passage_de(ctx, hook, lab, "Write", rel)
        if not bon:
            fautes.append("jumeau : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G6 (casse, lien dur dans et hors du dossier de planning, alias, segment .., création en autre casse, deux rôles), 4 jumeaux sans refus (même nom hors de la racine du dossier de planning, nom voisin)" % len(cas))


def controle_id_02(ctx, script):
    """Copie armée : un lien dur vers un VERDICT.md, sous un autre nom (dans et hors du dossier de planning) ->
    refus de G5 ; VERDICT.md.bak et un lien dur vers un autre fichier -> aucun refus."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_frais(ctx, "g5-adherent")
    unite = os.path.join(lab, UNITE)
    ecrire(os.path.join(unite, "VERDICT.md"), "v\n")
    os.link(os.path.join(unite, "VERDICT.md"), os.path.join(unite, "lien-verdict.md"))
    os.link(os.path.join(unite, "VERDICT.md"), os.path.join(lab, "livrables", "copie-verdict.md"))
    os.link(os.path.join(unite, "PLAN.md"), os.path.join(unite, "plan-lien.md"))
    ecrire(os.path.join(unite, "VERDICT.md.bak"), "b\n")
    fautes = []
    for rel in (UNITE + "/lien-verdict.md", "livrables/copie-verdict.md"):
        bon, detail = _refus_de(ctx, hook, lab, "G5", "Write", rel)
        if not bon:
            fautes.append(detail)
    for rel in (UNITE + "/VERDICT.md.bak", UNITE + "/plan-lien.md"):
        bon, detail = _passage_de(ctx, hook, lab, "Write", rel)
        if not bon:
            fautes.append("jumeau : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "lien dur vers un VERDICT.md refusé (G5) sous un autre nom, dans et hors du dossier de planning ; VERDICT.md.bak et un lien dur vers un autre fichier passent")


def controle_id_03(ctx, script):
    """F6 = f6-oui : une écriture par outil de config.json qui change ou retire planning_version est refusée (Write,
    Edit avec sa sémantique replace_all, NotebookEdit) ; celle qui le garde passe (autre clé changée)."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_frais(ctx, "g6-adherent")
    config = os.path.join(lab, ".planning", "config.json")
    ecrire(config, '{"planning_version": "cycles-v1", "seuil": 1, "copie": "cycles-v1"}')
    cible = os.path.join(lab, ".planning", "config.json")
    rel = ".planning/config.json"
    W = lambda contenu: ("Write", {"file_path": cible, "content": contenu})
    E = lambda ancien, nouveau, tout=None: ("Edit", dict({"file_path": cible, "old_string": ancien, "new_string": nouveau},
                                                        **({"replace_all": tout} if tout is not None else {})))
    refus = (("Write planning_version 2.0",) + W('{"planning_version": "2.0"}'),
             ("Write qui n'est pas du JSON",) + W("pas du json"),
             ("Write sans la clé",) + W('{"seuil": 1}'),
             ("Write où cycles-v1 est ailleurs",) + W('{"planning_version": "2.0", "copie": "cycles-v1"}'),
             ("Edit 2.0",) + E('"planning_version": "cycles-v1"', '"planning_version": "2.0"'),
             ("Edit qui retire la clé",) + E('"planning_version": "cycles-v1", ', ""),
             ("Edit ambigu sans replace_all",) + E("cycles-v1", "2.0"),
             ("Edit replace_all qui touche les deux",) + E("cycles-v1", "2.0", True),
             ("Edit inapplicable",) + E("absent du fichier", "x"),
             ("NotebookEdit",) + ("NotebookEdit", {"notebook_path": cible, "new_source": "x"}))
    passages = (("Write qui garde cycles-v1",) + W('{"planning_version": "cycles-v1", "seuil": 2}'),
                ("Edit d'une autre clé",) + E('"seuil": 1', '"seuil": 2'),
                ("Edit de la seconde occurrence seulement",) + E('"copie": "cycles-v1"', '"copie": "autre"'))
    fautes = []
    for etiquette, outil, entree in refus:
        bon, detail = _refus_de(ctx, hook, lab, "G6", outil, rel, entree=entree)
        if not bon:
            fautes.append(etiquette + " : " + detail)
    for etiquette, outil, entree in passages:
        bon, detail = _passage_de(ctx, hook, lab, outil, rel, entree=entree)
        if not bon:
            fautes.append(etiquette + " : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus (Write, Edit, replace_all, NotebookEdit) et %d passages de config.json selon planning_version" % (len(refus), len(passages)))


def controle_id_04(ctx, script):
    """F7b = f7b-oui : le cache du recalcul est protégé (Write et Edit refusés, motif recalc-planning.sh) ; un nom voisin passe."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_frais(ctx, "g6-adherent")
    fautes = []
    for outil in ("Write", "Edit"):
        bon, detail = _refus_de(ctx, hook, lab, "G6", outil, ".planning/.recalc-cache.json")
        if not bon:
            fautes.append(detail)
        elif "recalc-planning.sh" not in detail:
            fautes.append("motif sans recalc-planning.sh : " + detail)
    bon, detail = _passage_de(ctx, hook, lab, "Write", ".planning/.recalc-cache.json.bak")
    if not bon:
        fautes.append("jumeau : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "Write et Edit du cache refusés (motif recalc-planning.sh), nom voisin sans refus")


def controle_id_05(ctx, script):
    """recalc-planning.sh, lancé par Bash, écrit l'état, l'index et le cache sur un lab où G6 est armé : le hook n'en voit
    rien (alors qu'un Write de l'état par outil est refusé)."""
    armee = ctx.copie_forcee(ctx.scripts_dir, "armed")
    lab = lab_frais(ctx)
    os.rmdir(os.path.join(lab, UNITE, "plans", "01-a"))
    os.rmdir(os.path.join(lab, UNITE, "plans"))
    commande = "bash '%s' --planning=%s" % (ctx.recalc, os.path.join(lab, ".planning"))
    rc, out, err = ctx.lancer("A", payload("Bash", {"command": commande}, lab), cwd=lab, dossier=armee)
    if classer(rc, out) == "deny" or err:
        return False, "le hook armé voit la commande Bash : " + classer(rc, out) + " " + court(out)
    rc, out, err = ctx.lancer("A", payload("Write", {"file_path": os.path.join(lab, ".planning", "STATE.md"), "content": "x"}, lab), cwd=lab, dossier=armee)
    if classer(rc, out) != "deny":
        return False, "témoin : un Write de l'état n'est pas refusé sur la copie armée : " + classer(rc, out)
    p = subprocess.run(["bash", ctx.recalc, "--planning=" + os.path.join(lab, ".planning")], stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, env=ctx.env(), timeout=240)
    manque = [n for n in ("STATE.md", "INDEX.md", ".recalc-cache.json") if not os.path.isfile(os.path.join(lab, ".planning", n))]
    if p.returncode != 0 or manque:
        return False, "recalc-planning.sh : rc=%d, fichiers absents %s, %s" % (p.returncode, manque, court(p.stderr))
    return True, "G6 armé : la commande Bash n'est pas refusée et recalc-planning.sh écrit l'état, l'index et le cache (le Write de l'état est refusé)"


# --- 45-06 : G1 (pas de plan sans cadrage) ------------------------------------------------------------------
G1_LAB = "g1-adherent"
G1_PHASES = ".planning/cycles/01-c/phases/"
G1_SANS = G1_PHASES + "01-sans/PLAN.md"
G1_PLANS = G1_PHASES + "06-plans/plans/01-a/PLAN.md"
G1_MOTIF_ABSENCE = "n'a pas de CADRAGE.md"
G1_MOTIF_OUVERT = "porte des lignes structurantes sans statut"
NOMS_MODELE_PHASE = ("CADRAGE.md", "PLAN.md", "CLOTURE.md", "VERDICT.md", "SUMMARY.md", "DEROGATION.md")
PLANCHER_CROISE_G1 = 60  # plancher déclaré du nombre de phases comparées au recalcul (65 mesurées le 2026-09-30)


def _g1(ctx, hook, outil, rel, lab=G1_LAB, agent=None, extra_env=None):
    return _g5(ctx, hook, outil, rel, agent=agent, lab=lab, extra_env=extra_env)


def _raison_deny(rc, out, err):
    """(raison, None) d'un deny unique sans stderr ; (None, détail) sinon."""
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return None, "%s %s stderr=%s" % (v, court(out), court(err))
    return json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"], None


def controle_g1_01(ctx, script):
    """Copie observe : Write du PLAN.md d'une phase sans CADRAGE.md -> silence, code 0, UNE ligne gate=G1 au journal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g1-01")
    rc, out, err = _g1(ctx, d, "Write", G1_SANS, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    for motif in ("  gate=G1  ", "  chemin=" + G1_SANS + "  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : silence, code 0, une ligne gate=G1 (chemin, outil) au journal d'observation"


def controle_g1_02(ctx, script):
    """Copie armed : Write et Edit du PLAN.md d'une phase sans CADRAGE.md, en plan direct et sous plans/ -> un deny
    `[planning-core] G1 :` qui nomme la PHASE (jamais le plan)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for rel, phase, plan in ((G1_SANS, "01-sans", None), (G1_PLANS, "06-plans", "01-a"),
                             (G1_PHASES + "08-neuve/PLAN.md", "08-neuve", None)):
        for outil in ("Write", "Edit"):
            n += 1
            raison, detail = _raison_deny(*_g1(ctx, d, outil, rel))
            if raison is None:
                fautes.append("%s %s -> %s" % (outil, rel, detail))
            elif not raison.startswith("[planning-core] G1 :") or ("la phase %s " % phase) not in raison or G1_MOTIF_ABSENCE not in raison \
                    or (plan is not None and ("la phase %s " % plan) in raison):
                fautes.append("%s %s : raison %s" % (outil, rel, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G1 (Write et Edit ; plan direct, sous plans/, phase vide) qui nomment la phase" % n)


def controle_g1_03(ctx, script):
    """Copie armée : phase cadrée, autres fichiers du modèle, socle v2, nom d'unité invalide, hors .planning/ -> aucun
    refus de G1 ; lab dev -> stdout d'octet vide."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    passages = (G1_PHASES + "02-clos/PLAN.md", G1_PHASES + "03-vide/PLAN.md", G1_PHASES + "05-herite/PLAN.md",
                G1_PHASES + "07-plans-clos/plans/01-a/PLAN.md", G1_PHASES + "01-sans/SUMMARY.md", G1_PHASES + "01-sans/PLAN.md.bak",
                ".planning/phases/01-x/PLAN.md", G1_PHASES + "sans-numero/PLAN.md", G1_PHASES + "01-sans/plans/x/PLAN.md",
                "livrables/PLAN.md")
    for rel in passages:
        rc, out, err = _g1(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G1" in out:
            fautes.append("%s -> %s %s" % (rel, classer(rc, out), court(out)))
    rc, out, err = _g1(ctx, d, "Write", G1_SANS, lab="g1-dev")
    if rc != 0 or out != b"" or err:
        fautes.append("lab dev -> rc=%d stdout=%s" % (rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "aucun refus : phase cadrée (clos, inconnues: [], hérité), plan sous une phase cadrée, SUMMARY.md, PLAN.md.bak, socle v2, nom d'unité invalide, hors .planning/ ; lab dev en silence")


# Contrôle croisé (R-G1-04, R-G1-08) : pour chaque phase des bancs de la 44 et des gates, G1 (copie armée, Write de
# son PLAN.md) est comparé à l'état que recalc-planning.sh --read-only dérive. Les labs sont matérialisés sous un
# dossier jetable et RENDUS adhérents (config.json réécrit) : le hook n'agit que là. Sont écartées les phases
# dérogées (DEROGATION.md : la 44 juge alors sur la dérogation, le hook jamais) et celles qui portent un fichier du
# modèle non régulier (Φ1 court-circuite Φ2 : l'état indéterminé n'est pas une lecture de CADRAGE.md).
def _texte_sans_attendus(texte):
    """Le banc de la 44 sans ses directives propres : `@@ attendu*` (la dérivation attendue), `@@ fichier-dehors` (et
    son contenu) et les liens vers DEHORS/ (un fichier hors du lab, posé par son propre matérialiseur)."""
    sortie, saute = [], False
    for ligne in texte.split("\n"):
        if ligne.startswith("@@ "):
            saute = ligne.startswith("@@ fichier-dehors ")
            if saute or ligne.startswith("@@ attendu") or (ligne.startswith("@@ lien ") and "DEHORS/" in ligne):
                continue
        elif saute:
            continue
        sortie.append(ligne)
    return "\n".join(sortie)


def _labs_croises(ctx):
    if getattr(ctx, "_labs_croises", None) is None:
        sources = [("gates", ctx.banc)]
        if getattr(ctx, "banc_recalc", None):
            sources.append(("recalc", ctx.banc_recalc))
        labs, ignores = [], 0
        for nom_banc, chemin in sources:
            ordre, definitions = parser_banc(_texte_sans_attendus(open(chemin, encoding="utf-8").read()))
            base = ctx.unique("croise-" + nom_banc)
            for nom in ordre:
                dest = os.path.join(base, nom)
                try:
                    materialiser(definitions, nom, dest)
                    planning = os.path.join(dest, ".planning")
                    config = os.path.join(planning, "config.json")
                    if os.path.islink(planning) or not os.path.isdir(planning) or (os.path.isdir(config) and not os.path.islink(config)):
                        raise OSError("planning inexploitable")
                    if os.path.lexists(config):
                        os.unlink(config)
                    ecrire(config, '{"planning_version": "cycles-v1"}')
                except (OSError, ValueError):
                    ignores += 1
                    continue
                labs.append((nom_banc + "/" + nom, dest))
        ctx._labs_croises = (labs, ignores)
    return ctx._labs_croises


def _derivation_lab(ctx, racine):
    """[(chemin de phase relatif au dossier de planning, état, raison)] rendus par recalc-planning.sh --read-only."""
    p = subprocess.run(["bash", ctx.recalc, "--planning=" + os.path.join(racine, ".planning"), "--read-only"],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), timeout=180)
    if p.returncode != 0:
        return None
    try:
        donnees = json.loads(p.stdout.decode("utf-8"))
    except ValueError:
        return None
    return [(ph["chemin"], ph["etat"], ph.get("raison")) for c in donnees.get("cycles", []) for ph in c.get("phases", [])]


def _phase_comparable(racine, chemin):
    dossier = os.path.join(racine, ".planning", chemin)
    if os.path.lexists(os.path.join(dossier, "DEROGATION.md")):
        return False
    for nom in NOMS_MODELE_PHASE:
        cible = os.path.join(dossier, nom)
        if os.path.lexists(cible) and not stat.S_ISREG(os.lstat(cible).st_mode):
            return False
    return True


def _verdict_g1(ctx, dossier_hook, racine, chemin):
    """`absence`, `ouvert`, `passe` ou `autre:...` : ce que G1 (copie armée) rend pour le Write du PLAN.md de la phase."""
    brut = payload("Write", entree_outil("Write", os.path.join(racine, ".planning", chemin, "PLAN.md")), racine)
    rc, out, err = ctx.lancer("A", brut, cwd=racine, dossier=dossier_hook)
    v = classer(rc, out)
    if v in ("silence", "avertit") and not err and b"[planning-core] G1" not in out:
        return "passe"
    if v == "deny" and not err:
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
        if raison.startswith("[planning-core] G1 :") and G1_MOTIF_ABSENCE in raison:
            return "absence"
        if raison.startswith("[planning-core] G1 :") and G1_MOTIF_OUVERT in raison:
            return "ouvert"
    return "autre:%s %s" % (v, court(out))


def phases_croisees(ctx, script):
    """[(etiquette, chemin, état, raison, verdict de G1)] pour chaque phase comparable ; `script` = dossier du hook."""
    cle = _dossier(ctx, script)
    if getattr(ctx, "_croisees", None) is None:
        ctx._croisees = {}
    if cle not in ctx._croisees:
        labs, ignores = _labs_croises(ctx)
        armee = ctx.copie_forcee(cle, "armed")
        with ThreadPoolExecutor(max_workers=8) as pool:
            derivations = list(pool.map(lambda e: _derivation_lab(ctx, e[1]), labs))
            taches = []
            for (etiquette, racine), derivation in zip(labs, derivations):
                for chemin, etat, raison in derivation or []:
                    if _phase_comparable(racine, chemin):
                        taches.append((etiquette, racine, chemin, etat, raison))
            verdicts = list(pool.map(lambda t: _verdict_g1(ctx, armee, t[1], t[2]), taches))
        sans_derivation = sum(1 for d in derivations if d is None)
        ctx._croisees[cle] = ([(t[0], t[2], t[3], t[4], v) for t, v in zip(taches, verdicts)], len(labs), ignores + sans_derivation)
    return ctx._croisees[cle]


def controle_croise_g1(ctx, script):
    """R-G1-04 : « G1 refuse l'écriture du PLAN.md pour absence de CADRAGE.md » <=> recalc-planning.sh --read-only rend
    `à cadrer` ou une raison `hors-cadrage:*`, sur chaque phase comparable des deux bancs."""
    phases, n_labs, ignores = phases_croisees(ctx, script)
    fautes = []
    for etiquette, chemin, etat, raison, verdict in phases:
        attendu = etat == "à cadrer" or (raison or "").startswith("hors-cadrage:")
        if verdict.startswith("autre:") or (verdict == "absence") != attendu:
            fautes.append("%s %s : recalcul %s/%s, G1 %s" % (etiquette, chemin, etat, raison, verdict))
    n = len(phases)
    absence = sum(1 for p in phases if p[4] == "absence")
    print("CROISE-G1 n=%d labs=%d absence=%d hors-absence=%d ecartees=%d" % (n, n_labs, absence, n - absence, ignores))
    if n < PLANCHER_CROISE_G1:
        fautes.append("%d phase(s) comparée(s), sous le plancher déclaré %d" % (n, PLANCHER_CROISE_G1))
    if absence < 1 or n - absence < 1:
        fautes.append("comparaison à vide : %d refus d'absence, %d passages" % (absence, n - absence))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else "%d phases comparées (%d refus pour absence de CADRAGE.md, %d passages) : G1 refuse <=> `à cadrer` ou `hors-cadrage:*`" % (n, absence, n - absence))


def controle_g1_05(ctx, script):
    """Copie armée : registre avec une ligne structurante: oui sans statut -> deny qui cite l'id de la ligne ; deux lignes
    ouvertes -> les deux ids ; une ligne ouverte et une fermée -> seulement l'ouverte."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for rel, phase, citees, tues in ((G1_PHASES + "04-ouvert/PLAN.md", "04-ouvert", ("I-07",), ()),
                                     (G1_PHASES + "16-deux-ouverts/PLAN.md", "16-deux-ouverts", ("I-21", "I-22"), ()),
                                     (G1_PHASES + "17-mixte/PLAN.md", "17-mixte", ("I-31",), ("I-32",))):
        for outil in ("Write", "Edit"):
            n += 1
            raison, detail = _raison_deny(*_g1(ctx, d, outil, rel))
            if raison is None:
                fautes.append("%s %s -> %s" % (outil, rel, detail))
            elif not raison.startswith("[planning-core] G1 :") or ("la phase %s " % phase) not in raison or G1_MOTIF_OUVERT not in raison \
                    or any(i not in raison for i in citees) or any(i in raison for i in tues):
                fautes.append("%s %s : raison %s" % (outil, rel, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G1 qui citent l'id de chaque ligne ouverte (une, deux, une sur deux) et nomment la phase" % n)


def controle_g1_06(ctx, script):
    """Copie armée : statut ARBITRÉ, statut `n'importe quoi`, structurante: non sans statut, `inconnues: []` -> passage
    (la valeur d'un statut n'est jamais jugée)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for rel in (G1_PHASES + "02-clos/PLAN.md", G1_PHASES + "14-quelconque/PLAN.md", G1_PHASES + "15-non-structurante/PLAN.md",
                G1_PHASES + "03-vide/PLAN.md"):
        rc, out, err = _g1(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G1" in out:
            fautes.append("%s -> %s %s" % (rel, classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "passage : ARBITRÉ, n'importe quoi, structurante: non sans statut, inconnues: []")


def controle_g1_07(ctx, script):
    """Bord F5 (f5-etats) : CADRAGE.md au frontmatter invalide, au registre invalide, au format hérité, en lien, en dossier
    -> passage ; phase SANS CADRAGE.md dont un AUTRE fichier est non régulier (fixture E) -> REFUS."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for rel in (G1_PHASES + "09-fm-invalide/PLAN.md", G1_PHASES + "10-registre-invalide/PLAN.md", G1_PHASES + "05-herite/PLAN.md",
                G1_PHASES + "11-lien/PLAN.md", G1_PHASES + "12-dossier/PLAN.md"):
        rc, out, err = _g1(ctx, d, "Write", rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G1" in out:
            fautes.append("%s -> %s %s (un état indéterminé n'est jamais refusé)" % (rel, classer(rc, out), court(out)))
    raison, detail = _raison_deny(*_g1(ctx, d, "Write", G1_PHASES + "13-autre/PLAN.md"))
    if raison is None:
        fautes.append("fixture E (pas de CADRAGE.md, CLOTURE.md en dossier) -> %s (jamais un passage par indétermination)" % detail)
    elif G1_MOTIF_ABSENCE not in raison:
        fautes.append("fixture E : raison %s" % raison)
    return (not fautes), ("; ".join(fautes) if fautes else "passage : frontmatter invalide, registre invalide, format hérité, lien, dossier ; refus : absence de CADRAGE.md avec un autre fichier non régulier (fixture E)")


def controle_g1_09(ctx, script):
    """Dérogation G1 active sur le PLAN.md : passage cité et consommé ; le second Write est refusé."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx, G1_LAB)
    rc, out, err = deroger(ctx, lab, None, gate="G1", chemins=(G1_SANS,))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(d, "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", G1_SANS)
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "G1", "willy", "AskUserQuestion session principale", "2026-09-30") if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=G1  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    r2 = ecrire_dans(ctx, hook, lab, "Write", G1_SANS)
    if classer(r2[0], r2[1]) != "deny":
        return False, "second Write : " + classer(r2[0], r2[1])
    return True, "dérogation G1 : premier Write passe et cité, dérogation consommée, second Write refusé"


def controle_registre(ctx, script):
    """R-REGISTRE : les arbres ast de lire_registre extraits du hook et du moteur de recalcul sont identiques."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    a_h = _arbre_fonction(corps_python(open(chemin, encoding="utf-8").read()), "lire_registre")
    a_r = _arbre_fonction(corps_python(open(ctx.recalc, encoding="utf-8").read(), "PY_RECALC_PLANNING_EOF"), "lire_registre")
    if a_h is None or a_r is None:
        return False, "lire_registre absent (hook %s, moteur %s)" % (a_h is not None, a_r is not None)
    if a_h != a_r:
        return False, "arbres différents"
    return True, "arbres ast identiques (docstring comprise)"


def controle_croise_g1_etendu(ctx, script):
    """R-G1-08 : la relation de R-G1-04 étendue — « G1 refuse (absence de CADRAGE.md OU registre ouvert) » <=> le recalcul rend
    `à cadrer`, `en cadrage`, `hors-cadrage:*` ou `avant-cadrage-clos:*` ; les états indéterminés `registre-invalide` et
    `frontmatter-invalide:CADRAGE.md` ne sont jamais refusés (f5-etats)."""
    phases, n_labs, ignores = phases_croisees(ctx, script)
    fautes = []
    illisibles = ouverts = 0
    for etiquette, chemin, etat, raison, verdict in phases:
        r = raison or ""
        attendu = etat in ("à cadrer", "en cadrage") or r.startswith("hors-cadrage:") or r.startswith("avant-cadrage-clos:")
        refuse = verdict in ("absence", "ouvert")
        if verdict.startswith("autre:") or refuse != attendu:
            fautes.append("%s %s : recalcul %s/%s, G1 %s" % (etiquette, chemin, etat, raison, verdict))
        if etat == "indéterminé" and r in ("registre-invalide", "frontmatter-invalide:CADRAGE.md"):
            illisibles += 1
            if verdict != "passe":
                fautes.append("%s %s : état illisible refusé (%s)" % (etiquette, chemin, verdict))
        if verdict == "ouvert":
            ouverts += 1
    n = len(phases)
    print("CROISE-G1-ETENDU n=%d absence-ou-ouvert=%d dont-ouvert=%d illisibles-jamais-refuses=%d" % (n, sum(1 for p in phases if p[4] in ("absence", "ouvert")), ouverts, illisibles))
    if n < PLANCHER_CROISE_G1:
        fautes.append("%d phase(s) comparée(s), sous le plancher déclaré %d" % (n, PLANCHER_CROISE_G1))
    if ouverts < 1 or illisibles < 1:
        fautes.append("comparaison à vide : %d refus pour registre ouvert, %d phases illisibles" % (ouverts, illisibles))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else "%d phases comparées (dont %d refus pour registre ouvert, %d phases illisibles jamais refusées)" % (n, ouverts, illisibles))


# Table de canary d'un dossier de scripts jetable (R-CANG-G1) : le hook livré TEL QUEL, ou G6, G5 et G1 armés.
def controle_cang_g1(ctx, script):
    """R-CANG-G1 : le canary rend 3 (sain, cas G1 compris) sur l'état livré, sur une copie où G6, G5 et G1 sont armed,
    et signale (code 0, une ligne qui nomme `G1-sans-cadrage`) quand evaluer_g1 est neutralisé."""
    dossier = _dossier(ctx, script)
    fautes = []
    d = scripts_canary(ctx, dossier, "observe", tel_quel=True)
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("état livré : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    d = scripts_canary(ctx, dossier, "armed", armes=("G6", "G5", "G1"))
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("G6, G5 et G1 armed : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    neutre, raison = make_hook_mutant(ctx, "G1-NEUTRE", "# gates-a-verdict", 'GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G7", evaluer_g7), ("ROLE", evaluer_role))  # gates-a-verdict')
    if neutre is None:
        fautes.append("mutant du hook invalide : " + raison)
    else:
        for valeur, armes in (("observe", ()), ("armed", ("G6", "G5", "G1"))):
            d = scripts_canary(ctx, dossier, valeur, hook=os.path.join(neutre, "planning-hook.sh"), armes=armes)
            rc, out, err = lancer_canary_dossier(ctx, d)
            lignes = [l for l in out.decode("utf-8", "replace").split("\n") if l]
            if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "G1-sans-cadrage" not in lignes[0] or "G6-principal" in lignes[0]:
                fautes.append("evaluer_g1 neutralisé (%s) : rc=%d %s" % (valeur, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "canary sain (code 3) sur l'état livré et sur G6, G5 et G1 armed ; evaluer_g1 neutralisé : une ligne qui nomme G1-sans-cadrage, observe comme armed")


# --- 45-07 : G7, pas de planning orphelin sous un lab adhérent (GATE-07, spec §2 D-05) ---------------------------------
G7_LAB = "g7-adherent"
G7_NU = "zone/nu/.planning/config.json"
G7_MOTIF = "exige un .claude/ habité"
# Les onze noms du détecteur, ÉCRITS ICI indépendamment du hook : un dossier `code-<nom>/` du banc porte le marqueur du même nom.
G7_MARQUEURS = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle", "build.gradle.kts",
                "composer.json", "Gemfile", "tsconfig.json", "Package.swift")


def _g7(ctx, hook, outil, rel, lab=G7_LAB, agent=None, extra_env=None):
    return _g5(ctx, hook, outil, rel, agent=agent, lab=lab, extra_env=extra_env)


def controle_g7_01(ctx, script):
    """Copie observe : Write de `zone/nu/.planning/config.json` sous un lab adhérent -> silence, code 0, UNE ligne gate=G7 au journal."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g7-01")
    rc, out, err = _g7(ctx, d, "Write", G7_NU, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    for motif in ("  gate=G7  ", "  chemin=" + G7_NU + "  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : silence, code 0, une ligne gate=G7 (chemin, outil) au journal d'observation"


def controle_g7_02(ctx, script):
    """Copie armée : Write et NotebookEdit d'un .planning/ à créer dans un dossier nu (existant ou à créer, tout rôle) -> un deny
    `[planning-core] G7 :` qui nomme le dossier X."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for outil, rel, agent, x in (("Write", G7_NU, None, "zone/nu"), ("NotebookEdit", "zone/nu/.planning/x.ipynb", None, "zone/nu"),
                                 ("Write", G7_NU, "general-purpose", "zone/nu"),
                                 ("Write", "zone/nouveau/profond/.planning/config.json", None, "zone/nouveau/profond")):
        n += 1
        raison, detail = _raison_deny(*_g7(ctx, d, outil, rel, agent=agent))
        if raison is None:
            fautes.append("%s %s -> %s" % (outil, rel, detail))
        elif not raison.startswith("[planning-core] G7 :") or ("dans %s exige" % x) not in raison or G7_MOTIF not in raison:
            fautes.append("%s %s : raison %s" % (outil, rel, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G7 (Write et NotebookEdit, fil principal et agent, dossier existant ou à créer) qui nomment X" % n)


def controle_g7_03(ctx, script):
    """Copie armée : un .planning/ créé dans un dossier qui porte un marqueur de code -> aucun refus, un cas par marqueur (les onze
    noms, un dossier *.xcodeproj, un lien vers un fichier) ; un FAUX marqueur (dossier nommé package.json, lien cassé, fichier
    nommé App.xcodeproj) ne compte pas."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for dossier in ["code-" + m for m in G7_MARQUEURS] + ["code-App.xcodeproj", "code-lien"]:
        n += 1
        rc, out, err = _g7(ctx, d, "Write", "zone/%s/.planning/config.json" % dossier)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G7" in out:
            fautes.append("%s -> %s %s" % (dossier, classer(rc, out), court(out)))
    for dossier in ("code-dossier", "code-casse", "code-fichier-xcode"):
        raison, detail = _raison_deny(*_g7(ctx, d, "Write", "zone/%s/.planning/config.json" % dossier))
        if raison is None or not raison.startswith("[planning-core] G7 :"):
            fautes.append("faux marqueur %s -> %s" % (dossier, detail if raison is None else raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d marqueurs laissent passer (onze noms, *.xcodeproj, lien vers un fichier) ; dossier nommé package.json, lien cassé et fichier nommé App.xcodeproj refusés" % n)


def controle_g7_04(ctx, script):
    """Copie armée : écriture dans un .planning/ qui existe déjà, Edit, création sous un lab dev, création dans un dossier sans aucun
    ancêtre planifié -> aucun refus de G7."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    for outil, rel in (("Write", "zone/existant/.planning/notes.md"), ("Write", ".planning/notes.md"), ("Edit", G7_NU)):
        rc, out, err = _g7(ctx, d, outil, rel)
        if classer(rc, out) not in ("silence", "avertit") or err or b"[planning-core] G7" in out:
            fautes.append("%s %s -> %s %s" % (outil, rel, classer(rc, out), court(out)))
    rc, out, err = _g7(ctx, d, "Write", G7_NU, lab="g7-dev")
    if rc != 0 or out != b"" or err:
        fautes.append("lab dev -> rc=%d stdout=%s" % (rc, court(out)))
    libre = dossier_neuf(ctx, "g7-libre")
    brut = payload("Write", entree_outil("Write", os.path.join(libre, "nu", ".planning", "config.json")), libre)
    rc, out, err = ctx.lancer("A", brut, cwd=libre, dossier=d)
    if rc != 0 or out != b"" or err:
        fautes.append("dossier sans ancêtre planifié -> rc=%d stdout=%s" % (rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "aucun refus : .planning/ existant (imbriqué et racine), Edit, lab dev (stdout d'octet vide), dossier sans ancêtre planifié (stdout d'octet vide)")


def marqueurs_du_detecteur(texte):
    """(mots de la boucle `for f in … ; do` qui teste les fichiers, glob du projet Xcode) extraits du texte de detect-gsd-engine.sh."""
    m = re.search(r"has_code_signal\(\) \{(.*?)\n\}", texte, re.S)
    if m is None:
        return None, None
    corps = m.group(1)
    boucle = re.search(r"for f in ([^;]*?); do\n\s*\[ -f ", corps, re.S)
    xcode = re.search(r"for f in \./(\*\.xcodeproj); do \[ -d ", corps)
    if boucle is None or xcode is None:
        return None, None
    return boucle.group(1).replace("\\\n", " ").split(), xcode.group(1)


def controle_g7_05(ctx, script):
    """R-G7-05 : l'ensemble des marqueurs extrait du TEXTE de detect-gsd-engine.sh (mots de la boucle `for f in … ; do`, motif
    `*.xcodeproj`) est égal à MARQUEURS_CODE ∪ {*.xcodeproj} du hook ; les onze noms écrits par la suite (G7_MARQUEURS) aussi."""
    chemin = script if script.endswith(".sh") else os.path.join(script, "planning-hook.sh")
    ns = charger_module(chemin)
    detecteur = os.path.join(ctx.scripts_dir, "detect-gsd-engine.sh")
    mots, xcode = marqueurs_du_detecteur(open(detecteur, encoding="utf-8").read())
    if mots is None:
        return False, "extraction vide du texte du détecteur (rouge, jamais un vert à vide)"
    hook = set(ns["MARQUEURS_CODE"]) | {"*" + ns["SUFFIXE_XCODEPROJ"]}
    det = set(mots) | {xcode}
    fautes = []
    if len(mots) != len(set(mots)) or len(mots) != 11:
        fautes.append("le détecteur porte %d mot(s) pour %d distinct(s) (attendu 11)" % (len(mots), len(set(mots))))
    if hook != det:
        fautes.append("écart : seulement dans le hook %s, seulement dans le détecteur %s" % (sorted(hook - det), sorted(det - hook)))
    if set(G7_MARQUEURS) | {"*.xcodeproj"} != det:
        fautes.append("la liste de la suite diffère du détecteur : %s" % sorted((set(G7_MARQUEURS) | {"*.xcodeproj"}) ^ det))
    return (not fautes), ("; ".join(fautes) if fautes else "%d marqueurs, MARQUEURS_CODE ∪ {*.xcodeproj} = l'ensemble extrait du texte de detect-gsd-engine.sh" % len(det))


G7_HABITE = (  # (dossier du banc, habité selon le prédicat littéral de P45-D-14, libellé) : agent ET mémoire
    ("hab-ok", True, "agents/a.md et memory/m.md"), ("hab-profond", True, "agents/a.md et memory/ sous deux sous-dossiers"),
    ("hab-agents", False, "agents seuls"), ("hab-memoire", False, "mémoire seule"),
    ("hab-agent-memory", False, "agent-memory/ seul, sans fichier"), ("hab-vide", False, ".claude/ vide"))
G7_NON_REGULIERS = (  # (dossier du banc, libellé) : fichiers NON réguliers, jamais comptés
    ("hab-lien", "agents/x.md en lien symbolique (memory/m.md régulier)"),
    ("hab-memoire-lien", "memory/m.md en lien symbolique (agents/a.md régulier)"),
    ("hab-memoire-vide", "memory/ sans fichier régulier (agents/a.md régulier)"),
    ("hab-txt", "agents/notes.txt n'est pas un agents/*.md (memory/m.md régulier)"))


def cas_habite(ctx, script):
    """[(dossier, libellé, attendu, obtenu)] du prédicat « habité » sur copie armée : `passage` ou `refus` (un deny de G7), sinon l'écart."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lignes = []
    for dossier, habite, libelle in G7_HABITE:
        lignes.append((dossier, libelle, "passage" if habite else "refus", _verdict_g7(ctx, d, dossier)))
    return lignes


def _verdict_g7(ctx, hook, dossier):
    rc, out, err = _g7(ctx, hook, "Write", "zone/%s/.planning/config.json" % dossier)
    v = classer(rc, out)
    if err:
        return "stderr " + court(err)
    if v == "deny":
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
        return "refus" if raison.startswith("[planning-core] G7 :") and ("dans zone/%s exige" % dossier) in raison else "deny " + raison
    return "passage" if v in ("silence", "avertit") and b"[planning-core] G7" not in out else v + " " + court(out)


def controle_g7_06(ctx, script):
    """R-G7-06 : le prédicat littéral de P45-D-14 (agent ET mémoire) : agents et mémoire -> passage ; agents seuls, mémoire seule,
    agent-memory/ seul, .claude/ vide -> refus."""
    cas = cas_habite(ctx, script)
    fautes = ["%s (%s) : attendu %s, obtenu %s" % (dossier, libelle, attendu, obtenu) for dossier, libelle, attendu, obtenu in cas if attendu != obtenu]
    return (not fautes), ("; ".join(fautes) if fautes else "%d cas conformes au prédicat littéral : agents ET mémoire passent, agents seuls, mémoire seule, agent-memory/ seul et .claude/ vide sont refusés" % len(cas))


def controle_g7_07(ctx, script):
    """R-G7-07 : seuls les fichiers RÉGULIERS comptent — un agents/x.md ou un memory/m.md en lien symbolique, un memory/ sans fichier
    régulier, un agents/*.txt ne comptent pas (refus)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = ["%s (%s) : attendu refus, obtenu %s" % (dossier, libelle, obtenu) for dossier, libelle in G7_NON_REGULIERS
              for obtenu in [_verdict_g7(ctx, d, dossier)] if obtenu != "refus"]
    return (not fautes), ("; ".join(fautes) if fautes else "%d cas refusés : lien symbolique (agent ou mémoire), memory/ sans fichier régulier, agents/*.txt" % len(G7_NON_REGULIERS))


def controle_g7_08(ctx, script):
    """R-G7-08 : dérogation G7 active pour `zone/nu/.planning/config.json` : passage cité et consommé ; le second Write est refusé."""
    lab = lab_frais(ctx, G7_LAB)
    rc, out, err = deroger(ctx, lab, None, gate="G7", chemins=(G7_NU,))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", G7_NU)
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "G7", "willy", "AskUserQuestion session principale", "2026-09-30", G7_NU) if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=G7  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    r2 = ecrire_dans(ctx, hook, lab, "Write", G7_NU)
    if classer(r2[0], r2[1]) != "deny":
        return False, "second Write : " + classer(r2[0], r2[1])
    return True, "dérogation G7 : premier Write passe et cité, dérogation consommée, second Write refusé"


def compte_g7(ctx, script):
    """(faux refus, faux accept, nombre d'écritures) du banc G7 (labs g7-adherent et g7-dev) rejoué sur la copie ARMÉE de `script` : un
    doit-passer refusé est un faux refus, un doit-refuser non refusé un faux accept, un silence non silencieux un faux accept."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    _, labs, chemins = labs_banc(ctx)
    faux_refus = faux_accept = n = 0
    for nom in (G7_LAB, "g7-dev"):
        for e in labs[nom]["ecritures"]:
            brut, cwd = entree_de_ecriture(e, chemins[nom])
            rc, out, err = ctx.lancer("A", brut, cwd=cwd, dossier=d)
            _bon, obtenu = juger(e["attendu"], e["gate"], rc, out)
            n += 1
            if e["attendu"] == "doit-passer" and obtenu == "deny":
                faux_refus += 1
            elif e["attendu"] == "doit-refuser" and obtenu != "deny":
                faux_accept += 1
            elif e["attendu"] == "silence" and obtenu != "silence":
                faux_accept += 1
    return faux_refus, faux_accept, n


def controle_g7_09(ctx, script):
    """R-G7-09 : banc G7 sur copie armée -> zéro faux refus, zéro faux accept, sur un banc non vide (36 écritures au plus bas)."""
    fr, fa, n = compte_g7(ctx, script)
    if n < 30:
        return False, "banc G7 trop petit : %d écriture(s) (plancher 30, jamais un vert à vide)" % n
    return (fr == 0 and fa == 0), "COMPTE G7 faux-refus=%d faux-accept=%d sur %d écritures" % (fr, fa, n)


def controle_cang_g7(ctx, script):
    """R-CANG-G7 : le canary rend 3 (sain, cas G7 compris) sur l'état livré et sur une copie où les étapes 1 à 3 sont armées, et signale
    (code 0, une ligne qui nomme `G7-orphelin`) quand evaluer_g7 est neutralisé."""
    dossier = _dossier(ctx, script)
    fautes = []
    d = scripts_canary(ctx, dossier, "observe", tel_quel=True)
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("état livré : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    d = scripts_canary(ctx, dossier, "armed", armes=("G6", "G5", "G1", "G7"))
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("étapes 1 à 3 armed : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    neutre, raison = make_hook_mutant(ctx, "G7-NEUTRE", "# gates-a-verdict", 'GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G1", evaluer_g1), ("ROLE", evaluer_role))  # gates-a-verdict')
    if neutre is None:
        fautes.append("mutant du hook invalide : " + raison)
    else:
        for valeur, armes in (("observe", ()), ("armed", ("G6", "G5", "G1", "G7"))):
            d = scripts_canary(ctx, dossier, valeur, hook=os.path.join(neutre, "planning-hook.sh"), armes=armes)
            rc, out, err = lancer_canary_dossier(ctx, d)
            lignes = [l for l in out.decode("utf-8", "replace").split("\n") if l]
            if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "G7-orphelin" not in lignes[0] or "G6-principal" in lignes[0] or "G1-sans-cadrage" in lignes[0]:
                fautes.append("evaluer_g7 neutralisé (%s) : rc=%d %s" % (valeur, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "canary sain (code 3) sur l'état livré et sur les étapes 1 à 3 armed ; evaluer_g7 neutralisé : une ligne qui nomme G7-orphelin, observe comme armed")


# --- 45-09 : le canary du rôle (GATE-12 ; P45-D-20) ----------------------------------------------------------------------
# Couverture minimale de P45-D-20, ÉCRITE ICI indépendamment du canary : le contrôle ne se compare jamais à sa propre constante.
COUVERTURE_ATTENDUE = ("script-absent", "python-absent", "Task", "Agent", "fil-principal", "plugin")
MOTIF_CAS_TASK = '"ROLE-worker-Task|ROLE|'


def controle_cang_role(ctx, script):
    """R-CANG-ROLE : le canary rend 3 (sain, les trois cas ROLE compris : écriture d'un juge, dispatch d'un worker sous Agent puis sous
    Task) sur l'état livré (ROLE en observe : chaque cas trouve sa ligne `gate=ROLE`) et sur une copie où les quatre étapes sont armées
    (chaque cas obtient un refus de gate)."""
    dossier = _dossier(ctx, script)
    fautes = []
    d = scripts_canary(ctx, dossier, "observe", tel_quel=True)
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("état livré : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    d = scripts_canary(ctx, dossier, "armed", armes=("G6", "G5", "G1", "G7", "ROLE"))
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        fautes.append("les quatre étapes armed : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "canary sain (code 3) sur l'état livré (une ligne gate=ROLE par cas) et sur les quatre étapes armed (un refus de gate par cas : juge, worker sous Agent, worker sous Task)")


def controle_cang_role_mort(ctx, script):
    """R-CANG-ROLE-MORT : evaluer_role ne rend jamais de verdict -> le canary signale (code 0, UNE ligne qui nomme ROLE), observe comme armed."""
    dossier = _dossier(ctx, script)
    neutre, raison = make_hook_mutant(ctx, "ROLE-NEUTRE", "# gates-a-verdict", 'GATES_A_VERDICT = (("G6", evaluer_g6), ("G5", evaluer_g5), ("G1", evaluer_g1), ("G7", evaluer_g7))  # gates-a-verdict')
    if neutre is None:
        return False, "mutant du hook invalide : " + raison
    fautes = []
    for valeur, armes in (("observe", ()), ("armed", ("G6", "G5", "G1", "G7", "ROLE"))):
        d = scripts_canary(ctx, dossier, valeur, hook=os.path.join(neutre, "planning-hook.sh"), armes=armes)
        rc, out, err = lancer_canary_dossier(ctx, d)
        lignes = [l for l in out.decode("utf-8", "replace").split("\n") if l]
        if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "ROLE-juge" not in lignes[0] or "G6-principal" in lignes[0] or "G1-sans-cadrage" in lignes[0]:
            fautes.append("evaluer_role neutralisé (%s) : rc=%d %s" % (valeur, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "evaluer_role neutralisé : code 0 et une ligne qui nomme ROLE-juge (et ni G6 ni G1), observe comme armed")


def dossier_sans_cas_task(ctx, dossier):
    """Copie jetable de `dossier` (check-gates-alive.sh et planning-hook.sh) d'où la ligne du cas ROLE-worker-Task est retirée."""
    texte = open(os.path.join(dossier, "check-gates-alive.sh"), encoding="utf-8").read()
    lignes = [l for l in texte.split("\n") if MOTIF_CAS_TASK not in l]
    d = ctx.unique("canary-sans-task")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "check-gates-alive.sh"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(lignes))
    shutil.copy(os.path.join(dossier, "planning-hook.sh"), os.path.join(d, "planning-hook.sh"))
    for nom in ("check-gates-alive.sh", "planning-hook.sh"):
        os.chmod(os.path.join(d, nom), 0o755)
    return d


def controle_cang_couverture(ctx, script):
    """R-CANG-COUVERTURE : `--couverture` imprime les six éléments de la couverture minimale et rend 3 ; sur une copie d'où le cas
    ROLE-worker-Task est retiré, il rend 0 avec UNE ligne de signal qui nomme Task (et n'imprime plus Task) ; la même copie, en session
    adhérente, fait signaler le canary (code 0, UNE ligne qui nomme la couverture et Task)."""
    dossier = _dossier(ctx, script)
    fautes = []
    cwd = ctx.unique("cwd-couverture")
    os.makedirs(cwd, exist_ok=True)
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": ctx.home}

    def couverture(d):
        p = subprocess.run(["bash", os.path.join(d, "check-gates-alive.sh"), "--couverture"], stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, env=env, cwd=cwd, timeout=60)
        return p.returncode, [l for l in p.stdout.decode("utf-8", "replace").split("\n") if l]

    rc, lignes = couverture(dossier)
    if rc != 3 or lignes != list(COUVERTURE_ATTENDUE):
        fautes.append("état livré : rc=%d lignes=%s" % (rc, lignes))
    sans = dossier_sans_cas_task(ctx, dossier)
    rc, lignes = couverture(sans)
    signal = [l for l in lignes if l.startswith("[planning-core] canary : ")]
    elements = [l for l in lignes if not l.startswith("[planning-core] canary : ")]
    if rc != 0 or len(signal) != 1 or "Task" not in signal[0] or "Task" in elements or elements != [e for e in COUVERTURE_ATTENDUE if e != "Task"]:
        fautes.append("sans le cas ROLE-worker-Task : rc=%d lignes=%s" % (rc, lignes))
    d = scripts_canary(ctx, sans, "observe", tel_quel=True)
    rc, out, err = lancer_canary_dossier(ctx, d)
    lignes = [l for l in out.decode("utf-8", "replace").split("\n") if l]
    if rc != 0 or len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : ") or "couverture" not in lignes[0] or "Task" not in lignes[0]:
        fautes.append("session sans le cas ROLE-worker-Task : rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "six éléments imprimés (code 3) ; sans le cas ROLE-worker-Task : code 0, une ligne qui nomme Task, cinq éléments ; en session : une ligne de signal de couverture")


# --- 45-08 : le hook par rôle (GATE-09 ; P45-D-04, P45-D-05, P45-D-05b, P45-D-11, P45-D-12a) ------------------------------
ROLE_LAB = "role-adherent"
ROLE_DEV = "role-dev"
ROLE_LIVRABLE = "livrables/x.md"
ROLE_MOTIF = "[planning-core] ROLE :"
TEXTE_JUGE = "---\nname: %s\ndescription: juge de la suite\ntools: Read, Glob, Grep\ndisallowedTools: Write, Edit\nomitClaudeMd: true\n---\nCorps.\n"
TEXTE_PRODUCTEUR = "---\nname: %s\ndescription: producteur de la suite\ntools: Read, Write\n---\nCorps.\n"


def _role(ctx, hook, outil, rel, agent=None, lab=ROLE_LAB, extra_env=None, entree=None):
    return _g5(ctx, hook, outil, rel, agent=agent, lab=lab, extra_env=extra_env, entree=entree)


def verdict_role(rc, out, err):
    """`refus` (un deny dont la raison commence par `[planning-core] ROLE :`), `passage` (silence ou avertissement sans verdict de rôle),
    sinon l'écart décrit."""
    if err:
        return "stderr " + court(err)
    v = classer(rc, out)
    if v == "deny":
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
        return "refus" if raison.startswith(ROLE_MOTIF) else "deny " + raison
    if v in ("silence", "avertit"):
        return "passage" if b"[planning-core] ROLE" not in out else v + " " + court(out)
    return v + " " + court(out)


def home_de_suite(ctx, nom, agents=(), plugins=()):
    """Dossier `HOME` jetable : `agents` = [(fichier, texte)] sous `.claude/agents/`, `plugins` = [(chemin relatif, texte)] sous
    `.claude/plugins/`."""
    home = dossier_neuf(ctx, "home-" + nom)
    for fichier, texte in agents:
        ecrire(os.path.join(home, ".claude", "agents", fichier), texte)
    for rel, texte in plugins:
        ecrire(os.path.join(home, ".claude", "plugins", rel), texte)
    return home


def controle_role_01(ctx, script):
    """Copie observe : Write d'un livrable par un juge du lab -> code 0, stdout vide ou avertissement de G2 seulement, UNE ligne gate=ROLE
    au journal (chemin, outil), aucun refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-role-01")
    rc, out, err = _role(ctx, d, "Write", ROLE_LIVRABLE, agent="juge-test", extra_env={"XDG_CACHE_HOME": cache})
    v = classer(rc, out)
    if rc != 0 or err or v not in ("silence", "avertit") or b"[planning-core] ROLE" in out:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if v == "avertit" and "G2" not in contexte_de(out):
        return False, "avertissement qui n'est pas celui de G2 : " + court(out)
    lignes = lignes_journal(cache)
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1) : %s" % (len(lignes), lignes)
    for motif in ("  gate=ROLE  ", "  chemin=" + ROLE_LIVRABLE + "  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : code 0, aucun refus (%s), une ligne gate=ROLE (chemin, outil) au journal" % v


def controle_role_02(ctx, script):
    """Copie armed : Write, Edit et NotebookEdit par un juge du lab, sous `juge-test`, `Juge_Test`, `juge test`, `JUGE-TEST`, et par le juge
    dont le name: est `Juge_Mixte` -> UN deny `[planning-core] ROLE :` (juge, poser-verdict.sh)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for outil in ("Write", "Edit", "NotebookEdit"):
        for agent in ("juge-test", "Juge_Test", "juge test", "JUGE-TEST", "juge-mixte", "JUGE_MIXTE", "Juge Mixte"):
            n += 1
            raison, detail = _raison_deny(*_role(ctx, d, outil, ROLE_LIVRABLE, agent=agent))
            if raison is None:
                fautes.append("%s agent=%s -> %s" % (outil, agent, detail))
            elif not raison.startswith(ROLE_MOTIF) or "est un juge" not in raison or "poser-verdict.sh" not in raison or agent not in raison:
                fautes.append("%s agent=%s : raison %s" % (outil, agent, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus de rôle (trois outils, casse et séparateurs, name: en casse mixte), raison « juge … poser-verdict.sh »" % n)


def _sans_agent_id(ctx, hook, outil, rel, agent_type, lab=ROLE_LAB):
    """Payload portant agent_type mais PAS agent_id (le fil principal lancé avec --agent, par exemple)."""
    _, _, chemins = labs_banc(ctx)
    racine = chemins[lab]
    obj = json.loads(payload(outil, entree_outil(outil, os.path.join(racine, rel)), racine, agent_type=agent_type).decode("utf-8"))
    del obj["agent_id"]
    return ctx.lancer("A", json.dumps(obj).encode("utf-8"), cwd=racine, dossier=hook)


def controle_role_03(ctx, script):
    """Copie armed : le même Write au fil principal (sans agent_id ni agent_type, ou avec agent_type seul), par un agent_type inconnu, par
    `plugin-x:agent-y` non résolu -> aucun refus de rôle (la ligne « Tous » seulement)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    cas = (("fil principal", _role(ctx, d, "Write", ROLE_LIVRABLE)),
           ("agent_type sans agent_id", _sans_agent_id(ctx, d, "Write", ROLE_LIVRABLE, "juge-test")),
           ("agent inconnu", _role(ctx, d, "Write", ROLE_LIVRABLE, agent="agent-inconnu")),
           ("plugin non résolu", _role(ctx, d, "Write", ROLE_LIVRABLE, agent="plugin-x:agent-y")),
           ("juge du compte sans HOME qui le porte", _role(ctx, d, "Write", ROLE_LIVRABLE, agent="juge-compte-absent")))
    for etiquette, r in cas:
        n += 1
        v = verdict_role(*r)
        if v != "passage":
            fautes.append("%s -> %s" % (etiquette, v))
    return (not fautes), ("; ".join(fautes) if fautes else "%d cas sans refus de rôle : fil principal, agent_type seul, agent inconnu, agent de plugin non résolu" % n)


def controle_role_04(ctx, script):
    """Résolution (P45-D-05b) sur copie armed : le lab gagne sur le compte, deux définitions de rôles différents au même niveau = inconnu,
    deux définitions du même rôle = ce rôle, name: absent = repli sur le nom de fichier, niveau du compte, niveau du plugin (segment du
    chemin, casse et séparateurs normalisés)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    home = home_de_suite(ctx, "role-04",
                         agents=[("double.md", TEXTE_PRODUCTEUR % "double"), ("juge-compte.md", TEXTE_JUGE % "juge-compte"),
                                 ("jumeau-a.md", TEXTE_JUGE % "jumeau"), ("jumeau-b.md", TEXTE_JUGE % "jumeau")],
                         plugins=[("cache/mp/monplugin/1.0/agents/juge-plugin.md", TEXTE_JUGE % "juge-plugin"),
                                  ("cache/mp/monplugin/1.0/agents/producteur-plugin.md", TEXTE_PRODUCTEUR % "producteur-plugin"),
                                  ("cache/mp/autre-chose/1.0/agents/juge-ailleurs.md", TEXTE_JUGE % "juge-ailleurs")])
    cas = (("double", "refus"), ("ambigu", "passage"), ("sans-nom", "refus"), ("juge-compte", "refus"), ("jumeau", "refus"),
           ("monplugin:juge-plugin", "refus"), ("MonPlugin:Juge_Plugin", "refus"), ("monplugin:producteur-plugin", "passage"),
           ("monplugin:absent", "passage"), ("autreplugin:juge-plugin", "passage"), ("juge-ailleurs", "passage"),
           ("autre-chose:juge-plugin", "passage"), ("juge-plugin", "passage"))
    fautes = []
    for agent, attendu in cas:
        v = verdict_role(*_role(ctx, d, "Write", ROLE_LIVRABLE, agent=agent, extra_env={"HOME": home}))
        if v != attendu:
            fautes.append("agent=%s : attendu %s, obtenu %s" % (agent, attendu, v))
    return (not fautes), ("; ".join(fautes) if fautes else "%d résolutions conformes : lab avant compte, ambigu = inconnu, même rôle = ce rôle, repli sur le nom de fichier, niveau du compte, niveau du plugin" % len(cas))


def controle_role_05(ctx, script):
    """Copie armed : dans un lab dev qui porte le même juge, Write, Edit, NotebookEdit, Bash, Agent et Task -> stdout d'octet vide, code 0
    (P45-D-04 : zéro régression dev)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    dispatch = {"description": "d", "prompt": "p", "subagent_type": "vf-crafter"}
    for outil, entree in (("Write", None), ("Edit", None), ("NotebookEdit", None), ("Bash", None), ("Agent", dispatch), ("Task", dispatch)):
        for agent in ("juge-test", "worker-vide", None):
            n += 1
            rc, out, err = _role(ctx, d, outil, ROLE_LIVRABLE, agent=agent, lab=ROLE_DEV, entree=entree)
            if rc != 0 or out != b"" or err:
                fautes.append("%s agent=%s -> rc=%d stdout=%s stderr=%s" % (outil, agent, rc, court(out), court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "%d appels d'un lab dev (six outils, juge, worker, fil principal) : stdout d'octet vide, code 0" % n)


def _classer(ctx, script, chemin):
    p = subprocess.run(["bash", os.path.join(_dossier(ctx, script), "planning-hook.sh"), "--classer", chemin],
                       stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
    return p.returncode, p.stdout, p.stderr


def controle_role_06(ctx, script):
    """`--classer` sur une définition au frontmatter jamais refermé -> `illisible` (une ligne JSON, code 0) ; sur un juge et un manager du lab
    -> `juge` et `manager` ; le hook traite l'agent illisible en inconnu (copie armed : aucun refus de rôle)."""
    _, _, chemins = labs_banc(ctx)
    agents = os.path.join(chemins[ROLE_LAB], ".claude", "agents")
    fautes = []
    for nom, role in (("abime.md", "illisible"), ("juge-test.md", "juge"), ("manager-test.md", "manager"), ("producteur-test.md", "producteur"), ("worker-vide.md", "worker")):
        rc, out, err = _classer(ctx, script, os.path.join(agents, nom))
        try:
            obtenu = json.loads(out.decode("utf-8").strip())
        except ValueError:
            fautes.append("%s : sortie non JSON : %s" % (nom, court(out)))
            continue
        if rc != 0 or err or len(out.splitlines()) != 1 or obtenu.get("role") != role or sorted(obtenu.keys()) != ["allowlist", "disallowed", "role"]:
            fautes.append("%s : attendu %s, obtenu rc=%d %s stderr=%s" % (nom, role, rc, court(out), court(err)))
    rc, out, err = _classer(ctx, script, os.path.join(agents, "absent.md"))
    if rc != 0 or json.loads(out.decode("utf-8")).get("role") != "illisible":
        fautes.append("fichier absent : rc=%d %s" % (rc, court(out)))
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    v = verdict_role(*_role(ctx, d, "Write", ROLE_LIVRABLE, agent="abime"))
    if v != "passage":
        fautes.append("agent à définition illisible : %s (attendu passage, traité en inconnu)" % v)
    return (not fautes), ("; ".join(fautes) if fautes else "--classer : abime = illisible, juge-test = juge, manager-test = manager, producteur-test = producteur, worker-vide = worker, fichier absent = illisible ; l'agent illisible est traité en inconnu")


def controle_role_07(ctx, script):
    """Erreur interne injectée dans evaluer_role (mutant sonde) : observe -> aucun refus + une ligne d'erreur au journal ; armed -> deny."""
    dossier, raison = make_hook_mutant(ctx, "ROLE-SONDE", "# role-sonde", 'raise RuntimeError("sonde")  # role-sonde')
    if dossier is None:
        return False, "mutant sonde invalide : " + raison
    cache = dossier_neuf(ctx, "cache-role-07")
    rc, out, err = _role(ctx, ctx.copie_forcee(dossier, "observe"), "Write", ".planning/notes.md", extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=ROLE  " not in lignes[0]:
        return False, "observe : rc=%d stdout=%s stderr=%s lignes=%s" % (rc, court(out), court(err), lignes)
    motif = [c for c in lignes[0].split("  ") if c.startswith("raison=")]
    if not motif or "erreur interne" not in urllib.parse.unquote(motif[0]):
        return False, "la ligne ne porte pas une raison d'erreur : " + lignes[0]
    rc, out, err = _role(ctx, ctx.copie_forcee(dossier, "armed"), "Write", ".planning/notes.md")
    if classer(rc, out) != "deny" or "erreur interne" not in json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]:
        return False, "armed : " + classer(rc, out) + " " + court(out)
    return True, "erreur interne de evaluer_role : en observe aucun refus et une ligne d'erreur au journal, en armed un deny (fail-closed)"


def controle_role_13(ctx, script):
    """P45-D-12a : `HOME` est l'entrée déclarée de la résolution des agents du COMPTE, et d'elle seule. Un juge défini seulement sous
    `<HOME>/.claude/agents/` : HOME A qui le porte -> refus (copie armed) ; HOME B qui ne le porte pas -> inconnu, aucun refus ; un lab dev
    reste silencieux sous les deux ; le verdict de G5 et de G6 d'un même payload et l'état d'armement (la copie à ARMEMENT_ROLE observe
    reste observe) ne changent pas ; XDG_CACHE_HOME, CLAUDE_PROJECT_DIR et TMPDIR ne changent pas la résolution."""
    dossier = _dossier(ctx, script)
    d_arm, d_obs = ctx.copie_forcee(dossier, "armed"), ctx.copie_forcee(dossier, "observe")
    home_a = home_de_suite(ctx, "role-13-a", agents=[("juge-compte.md", TEXTE_JUGE % "juge-compte")])
    home_b = home_de_suite(ctx, "role-13-b")
    fautes = []
    # (1) la résolution suit HOME
    for etiquette, home, attendu in (("HOME A", home_a, "refus"), ("HOME B", home_b, "passage")):
        v = verdict_role(*_role(ctx, d_arm, "Write", ROLE_LIVRABLE, agent="juge-compte", extra_env={"HOME": home}))
        if v != attendu:
            fautes.append("copie armed, %s : attendu %s, obtenu %s" % (etiquette, attendu, v))
    # (2) l'adhésion ne suit pas HOME : un lab dev reste silencieux, sous les deux
    for etiquette, home in (("HOME A", home_a), ("HOME B", home_b)):
        rc, out, err = _role(ctx, d_arm, "Write", ROLE_LIVRABLE, agent="juge-compte", lab=ROLE_DEV, extra_env={"HOME": home})
        if rc != 0 or out != b"" or err:
            fautes.append("lab dev, %s : rc=%d stdout=%s" % (etiquette, rc, court(out)))
    # (3) le verdict de G5 et de G6 (fil principal) est le même octet pour octet, sous les deux HOME
    for outil, rel in (("Write", VERDICT_REL), ("Write", ".planning/STATE.md"), ("Edit", ".planning/STATE.md")):
        ra = _role(ctx, d_arm, outil, rel, extra_env={"HOME": home_a})
        rb = _role(ctx, d_arm, outil, rel, extra_env={"HOME": home_b})
        if ra != rb or classer(ra[0], ra[1]) != "deny":
            fautes.append("%s %s : verdict différent sous HOME A et B (%s / %s)" % (outil, rel, classer(ra[0], ra[1]), classer(rb[0], rb[1])))
    # (4) l'armement ne suit pas HOME : la copie observe reste observe (silence) sous les deux, une ligne au journal seulement sous HOME A
    for etiquette, home, lignes_attendues in (("HOME A", home_a, 1), ("HOME B", home_b, 0)):
        cache = dossier_neuf(ctx, "cache-role-13")
        rc, out, err = _role(ctx, d_obs, "Write", ".planning/notes.md", agent="juge-compte", extra_env={"HOME": home, "XDG_CACHE_HOME": cache})
        lignes = [l for l in lignes_journal(cache) if "  gate=ROLE  " in l]
        if rc != 0 or out != b"" or err or len(lignes) != lignes_attendues:
            fautes.append("copie observe, %s : rc=%d stdout=%s, %d ligne(s) gate=ROLE (attendu %d)" % (etiquette, rc, court(out), len(lignes), lignes_attendues))
    # (5) les autres variables d'environnement ne changent pas la résolution, même quand elles désignent le dossier qui porte le juge
    for nom in ("XDG_CACHE_HOME", "CLAUDE_PROJECT_DIR", "TMPDIR"):
        v = verdict_role(*_role(ctx, d_arm, "Write", ROLE_LIVRABLE, agent="juge-compte", extra_env={"HOME": home_b, nom: home_a}))
        if v != "passage":
            fautes.append("HOME B et %s=HOME A : %s (attendu passage)" % (nom, v))
        v = verdict_role(*_role(ctx, d_arm, "Write", ROLE_LIVRABLE, agent="juge-compte", extra_env={"HOME": home_a, nom: home_b}))
        if v != "refus":
            fautes.append("HOME A et %s=HOME B : %s (attendu refus)" % (nom, v))
    return (not fautes), ("; ".join(fautes) if fautes else "HOME change la résolution d'un agent du compte (A : refus, B : inconnu), jamais l'adhésion (lab dev silencieux), le verdict de G5 et de G6 ni l'armement (copie observe) ; XDG_CACHE_HOME, CLAUDE_PROJECT_DIR et TMPDIR ne la changent pas")


# --- 45-08, Tâche 3 : la ligne worker (F9 = f9-allowlist, Willy, AskUserQuestion session principale, 2026-09-30) -------------------
OUTILS_DISPATCH_SUITE = ("Agent", "Task")  # les deux tool_name, exercés à chaque cas de dispatch (P45-D-09)
MOTIF_WORKER_F9 = "F9 = f9-allowlist, Willy, AskUserQuestion session principale, 2026-09-30"


def _dispatch(ctx, hook, outil, agent, sous, lab=ROLE_LAB, extra_env=None):
    return _role(ctx, hook, outil, "", agent=agent, lab=lab, extra_env=extra_env, entree=entree_outil(outil, None, sous=sous))


def _cas_dispatch(ctx, hook, cas, lab=ROLE_LAB):
    """[faute] d'une série de (agent, sous, attendu) rejouée sous Agent ET sous Task : `refus` (un deny de rôle qui cite le worker, le sous-agent
    et F9) ou `passage`."""
    fautes, n = [], 0
    for agent, sous, attendu in cas:
        for outil in OUTILS_DISPATCH_SUITE:
            n += 1
            rc, out, err = _dispatch(ctx, hook, outil, agent, sous, lab=lab)
            v = verdict_role(rc, out, err)
            if v != attendu:
                fautes.append("%s agent=%s sous=%r : attendu %s, obtenu %s" % (outil, agent, sous, attendu, v))
            elif attendu == "refus":
                raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
                for morceau in ("est un worker", "dispatch de %s refusé" % sous, "allowlist Agent(...) / Task(...)", MOTIF_WORKER_F9):
                    if morceau not in raison:
                        fautes.append("%s agent=%s sous=%r : la raison ne porte pas %r : %s" % (outil, agent, sous, morceau, raison))
    return fautes, n


def controle_role_08(ctx, script):
    """Copie armed, lab adhérent : un worker dont l'allowlist contient `vf-crafter` (écrite Agent(...) puis Task(...)) dispatche `vf-crafter` sous
    Agent ET sous Task -> passage ; `hors-liste` -> refus ; worker à allowlist vide : tout dispatch refusé. Copie observe : le même refus est une
    ligne gate=ROLE au journal, jamais un refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = _cas_dispatch(ctx, d, (
        ("worker-liste", "vf-crafter", "passage"), ("worker-liste", "autre-agent", "passage"), ("worker-liste", "hors-liste", "refus"),
        ("worker-task", "vf-crafter", "passage"), ("worker-task", "hors-liste", "refus"), ("worker-task", "autre-agent", "refus"),
        ("worker-vide", "vf-crafter", "refus"), ("worker-vide", "general-purpose", "refus")))
    o = ctx.copie_forcee(_dossier(ctx, script), "observe")
    for outil in OUTILS_DISPATCH_SUITE:
        cache = dossier_neuf(ctx, "cache-role-08")
        rc, out, err = _dispatch(ctx, o, outil, "worker-liste", "hors-liste", extra_env={"XDG_CACHE_HOME": cache})
        lignes = lignes_journal(cache)
        if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=ROLE  " not in lignes[0] or ("  chemin=dispatch/hors-liste  ") not in lignes[0] or ("  outil=" + outil + "  ") not in lignes[0]:
            fautes.append("copie observe %s : rc=%d stdout=%s lignes=%s" % (outil, rc, court(out), lignes))
    return (not fautes), ("; ".join(fautes) if fautes else "%d dispatchs sur copie armed (Agent et Task) : dans l'allowlist passe, hors liste refusé, allowlist vide refuse tout ; copie observe : une ligne gate=ROLE par refus évité" % n)


def controle_role_09(ctx, script):
    """Le subagent_type est normalisé (casse, `_`, espace, `-`) des DEUX côtés et comparé en entier : `VF_Crafter`, `vf crafter`, `VF-CRAFTER`
    passent comme `vf-crafter` ; `autre:vf-crafter` (aucun préfixe retiré), `vf-crafter-2` et `vf-craft` (aucun préfixe de chaîne) sont refusés."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = _cas_dispatch(ctx, d, (
        ("worker-liste", "VF_Crafter", "passage"), ("worker-liste", "vf crafter", "passage"), ("worker-liste", "VF-CRAFTER", "passage"),
        ("worker-liste", "AUTRE_AGENT", "passage"), ("worker-liste", "Autre Agent", "passage"),
        ("worker-liste", "autre:vf-crafter", "refus"), ("worker-liste", "vf-crafter-2", "refus"), ("worker-liste", "vf-craft", "refus"),
        ("worker-liste", "", "refus"), ("Worker_Liste", "VF_Crafter", "passage"), ("WORKER LISTE", "hors-liste", "refus")))
    return (not fautes), ("; ".join(fautes) if fautes else "%d dispatchs : casse, `_`, espace et `-` unifiés des deux côtés, chaîne entière, aucun préfixe retiré" % n)


def _payload_dispatch(racine_payload, outil, agent, sous):
    return payload(outil, entree_outil(outil, None, sous=sous), racine_payload, agent_type=agent)


def controle_role_10(ctx, script):
    """La racine du dispatch est dérivée du cwd du PAYLOAD (P45-D-12) : cwd du payload dans un lab dev (process lancé depuis le lab adhérent)
    -> stdout d'octet vide, même pour un worker ; cwd du payload dans le lab adhérent (process lancé depuis le lab dev) -> refus."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    _, _, chemins = labs_banc(ctx)
    adherent, dev = chemins[ROLE_LAB], chemins[ROLE_DEV]
    fautes = []
    rc, out, err = ctx.lancer("A", _payload_dispatch(dev, "Agent", "worker-vide", "vf-crafter"), cwd=adherent, dossier=d)
    if rc != 0 or out != b"" or err:
        fautes.append("cwd du payload = lab dev, process dans le lab adhérent : rc=%d stdout=%s" % (rc, court(out)))
    for outil in OUTILS_DISPATCH_SUITE:
        rc, out, err = ctx.lancer("A", _payload_dispatch(adherent, outil, "worker-vide", "vf-crafter"), cwd=dev, dossier=d)
        if verdict_role(rc, out, err) != "refus":
            fautes.append("%s, cwd du payload = lab adhérent, process dans le lab dev : %s" % (outil, verdict_role(rc, out, err)))
    return (not fautes), ("; ".join(fautes) if fautes else "la racine du dispatch vient du cwd du payload : lab dev = octet vide, lab adhérent = refus, quel que soit le cwd du processus")


def controle_role_11(ctx, script):
    """Manager, producteur, juge, fil principal, agent inconnu, agent de plugin non résolu, définitions ambiguë et illisible : dispatch (Agent
    et Task) jamais un refus de rôle (P45-D-11, limite déclarée)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = _cas_dispatch(ctx, d, tuple((agent, "hors-liste", "passage") for agent in (
        "manager-test", "producteur-test", "juge-test", "agent-inconnu", "plugin-x:agent-y", "ambigu", "abime")))
    for outil in OUTILS_DISPATCH_SUITE:
        n += 1
        v = verdict_role(*_dispatch(ctx, d, outil, None, "hors-liste"))
        if v != "passage":
            fautes.append("%s fil principal : %s" % (outil, v))
    return (not fautes), ("; ".join(fautes) if fautes else "%d dispatchs (Agent et Task) sans refus de rôle : manager, producteur, juge, fil principal, agent inconnu, plugin non résolu, ambigu, illisible" % n)


def _ecrire_agent(ctx, hook, lab, outil, rel, agent, extra_env=None):
    brut = payload(outil, entree_outil(outil, os.path.join(lab, rel)), lab, agent_type=agent)
    return ctx.lancer("A", brut, cwd=lab, dossier=hook, extra_env=extra_env)


def compte_role(ctx, script):
    """(faux refus, faux accept, nombre d'écritures) du banc ROLE (labs role-adherent et role-dev) rejoué sur la copie ARMÉE de `script`."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    _, labs, chemins = labs_banc(ctx)
    faux_refus = faux_accept = n = 0
    for nom in (ROLE_LAB, ROLE_DEV):
        for e in labs[nom]["ecritures"]:
            brut, cwd = entree_de_ecriture(e, chemins[nom])
            rc, out, err = ctx.lancer("A", brut, cwd=cwd, dossier=d)
            _bon, obtenu = juger(e["attendu"], e["gate"], rc, out)
            n += 1
            if e["attendu"] == "doit-passer" and obtenu == "deny":
                faux_refus += 1
            elif e["attendu"] == "doit-refuser" and obtenu != "deny":
                faux_accept += 1
            elif e["attendu"] == "silence" and obtenu != "silence":
                faux_accept += 1
    return faux_refus, faux_accept, n


def controle_role_12(ctx, script):
    """Dérogation ROLE active sur un chemin d'écriture de juge : passage cité et consommé, le second Write est refusé ; banc ROLE (labs
    role-adherent et role-dev, dispatch compris) sur copie armed : `COMPTE ROLE faux-refus=0 faux-accept=0`, sur un banc non vide."""
    lab = lab_frais(ctx, ROLE_LAB)
    rc, out, err = deroger(ctx, lab, None, gate="ROLE", chemins=(ROLE_LIVRABLE,))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    r1 = _ecrire_agent(ctx, hook, lab, "Write", ROLE_LIVRABLE, "juge-test")
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "ROLE", "willy", "AskUserQuestion session principale", "2026-09-30", ROLE_LIVRABLE) if m not in texte]
    lignes = [l for l in lignes_de(journal_derog(lab)) if "  consommee  id=1  gate=ROLE  " in l]
    if manque or len(lignes) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(lignes))
    r2 = _ecrire_agent(ctx, hook, lab, "Write", ROLE_LIVRABLE, "juge-test")
    if verdict_role(*r2) != "refus":
        return False, "second Write : " + verdict_role(*r2)
    fr, fa, n = compte_role(ctx, script)
    if n < 50:
        return False, "banc ROLE trop petit : %d écriture(s) (plancher 50, jamais un vert à vide)" % n
    return (fr == 0 and fa == 0), "dérogation ROLE : premier Write passe et cité, consommée, second Write refusé ; COMPTE ROLE faux-refus=%d faux-accept=%d sur %d écritures" % (fr, fa, n)


# =================================================================================================
# Sections
# =================================================================================================
def sec_table(ctx):
    texte = open(ctx.hook, encoding="utf-8").read()
    corps = corps_python(texte)
    fautes = []
    for gate, valeur in TABLE_ATTENDUE.items():
        motif = re.compile(r'^ARMEMENT_%s = "(observe|armed)"  # etape-[1-4]$' % gate, re.M)
        trouves = motif.findall(corps)
        if len(trouves) != 1:
            fautes.append("ARMEMENT_%s : %d ligne(s)" % (gate, len(trouves)))
        elif trouves[0] != valeur:
            fautes.append("ARMEMENT_%s = %s (attendu %s)" % (gate, trouves[0], valeur))
    for nom in ("phases_trace", '"gates"', "'gates'"):
        if nom in corps:
            fautes.append("le drapeau de config.json %s est cité par le hook (P45-D-01 : aucun code de la 45 ne le lit)" % nom)
    ns = charger_module(ctx.hook)
    if ns.get("G2_MODE") != "avertit":
        fautes.append("G2_MODE = %r" % ns.get("G2_MODE"))
    if ns.get("ORDRE_ETAPES") != ORDRE_ATTENDU:
        fautes.append("ORDRE_ETAPES = %r" % (ns.get("ORDRE_ETAPES"),))
    if not ns["armement_valide"](TABLE_ATTENDUE) or not ns["armement_valide"](ns["TABLE_ARMEMENT"]):
        fautes.append("la table livrée ne passe pas armement_valide")
    if ns["TABLE_ARMEMENT"] != TABLE_ATTENDUE:
        fautes.append("TABLE_ARMEMENT %r != TABLE_ATTENDUE" % (ns["TABLE_ARMEMENT"],))
    if fautes:
        for f in fautes:
            ko("R-TABLE-01", "les cinq constantes ARMEMENT_* (une ligne chacune) valent TABLE_ATTENDUE, G2_MODE vaut avertit, ordre de l'interface",
               "table livrée = table attendue", f)
    else:
        ok("R-TABLE-01 cinq constantes ARMEMENT_* sur une ligne chacune = TABLE_ATTENDUE (l'état courant), G2_MODE avertit, ORDRE_ETAPES conforme, armement_valide vrai")
    bon, detail = controle_table_02(ctx, ctx.hook)
    if bon:
        ok("R-TABLE-02 " + detail)
    else:
        ko("R-TABLE-02", "armement_valide rejette un ordre violé et accepte les préfixes", "6 rejets, 5 acceptations", detail)
    # Table livrée incohérente (G1 armé sans G6 ni G5) : le hook refuse dans un lab adhérent
    bon, detail = controle_table_03(ctx, ctx.scripts_dir)
    if bon:
        ok("R-TABLE-03 " + detail)
    else:
        ko("R-TABLE-03", "une table livrée qui viole l'ordre des étapes refuse", "deny « table d'armement incohérente »", detail)


def controle_table_03(ctx, script):
    """R-TABLE-03 : une table incohérente (G1 armé, G6 et G5 en observe : vraie QUEL QUE SOIT l'état courant d'armement, Q-ARM, Willy,
    AskUserQuestion session principale, 2026-09-30) construite en réécrivant les cinq constantes du script livré -> deny « table
    d'armement incohérente », code 0, dans un lab adhérent."""
    texte = open(os.path.join(_dossier(ctx, script), "planning-hook.sh"), encoding="utf-8").read()
    d = ctx.unique("incoherente")
    os.makedirs(d, exist_ok=True)
    incoh = texte
    for gate, valeur in (("G6", "observe"), ("G5", "observe"), ("G1", "armed"), ("G7", "observe"), ("ROLE", "observe")):
        incoh, n = re.subn(r'^(ARMEMENT_%s = )"(?:observe|armed)"' % gate, r'\1"%s"' % valeur, incoh, count=1, flags=re.M)
        if n != 1:
            return False, "ARMEMENT_%s : %d ligne(s) réécrite(s) (attendu 1)" % (gate, n)
    with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
        fh.write(incoh)
    _, _, chemins = labs_banc(ctx)
    racine = chemins["g2-adherent"]
    brut = payload("Write", entree_outil("Write", racine + "/.planning/notes.md"), racine)
    rc, out, err = ctx.lancer("A", brut, cwd=racine, dossier=d)
    raison = ""
    if classer(rc, out) == "deny":
        raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    if classer(rc, out) == "deny" and "table d'armement incohérente" in raison and not err:
        return True, "table incohérente (G1 armé sans G6 ni G5, quel que soit l'état courant) : deny « table d'armement incohérente », code 0"
    return False, classer(rc, out) + " " + court(out)


def sec_parseur(ctx):
    bon, detail = controle_parseur(ctx, ctx.hook)
    if bon:
        ok("R-PARSEUR " + detail)
    else:
        ko("R-PARSEUR", "les arbres ast du parseur de frontmatter du hook et du moteur de recalcul sont identiques", "identiques", detail)


def sec_g2(ctx):
    for ident, ctrl in (("R-G2-01", controle_g2_01), ("R-G2-02", controle_g2_02), ("R-G2-03", controle_g2_03)):
        bon, detail = ctrl(ctx, None)
        titre = {"R-G2-01": "Write hors ecrit: -> additionalContext (jamais permissionDecision)",
                 "R-G2-02": "écriture couverte, sous .planning/ ou .claude/ -> silence",
                 "R-G2-03": "plan clos ou dérogé ne couvre rien"}[ident]
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    # R-G2-04 : Bash
    fautes = []
    for cmd, cwd_rel, attendu in (("cat livrables/autre.md", None, "avertit"), ("cat ../livrables/autre.md", "sub", "avertit"),
                                  ("cat .planning/notes.md", None, "silence"), ("touch livrables/rapport.md", None, "silence"),
                                  ("echo 'guillemet ouvert", None, "silence"),
                                  ("cat .planning/notes.md > .planning/copie.md 2>&1", None, "silence")):
        rc, out, err = _ecrire_ok(ctx, None, "g2-adherent", "Bash", "-", commande=cmd, cwd_rel=cwd_rel)
        v = classer(rc, out)
        if v != attendu or err:
            fautes.append("%s -> %s" % (cmd, v))
        elif v == "avertit" and "Bash" not in contexte_de(out):
            fautes.append("%s : le message ne dit pas que Bash n'est pas couvert" % cmd)
    if fautes:
        ko("R-G2-04", "Bash : un jeton qui nomme un chemin hors ecrit: avertit ; chemins de .planning/, commande non découpable -> silence", "conforme", "; ".join(fautes))
    else:
        ok("R-G2-04 Bash : jeton hors ecrit: avertit (relatif au cwd du payload), .planning/ et commande non découpable en silence")
    # R-G2-05 : fil principal et sous-agent
    fautes = []
    for chemin in ("livrables/autre.md", "livrables/rapport.md"):
        r1 = _ecrire_ok(ctx, None, "g2-adherent", "Write", chemin)
        r2 = _ecrire_ok(ctx, None, "g2-adherent", "Write", chemin, agent="general-purpose")
        if r1 != r2:
            fautes.append("%s : fil principal %s / sous-agent %s" % (chemin, classer(r1[0], r1[1]), classer(r2[0], r2[1])))
    ok("R-G2-05 fil principal et sous-agent : même sortie octet pour octet (hypothèse G2-REF)") if not fautes else ko(
        "R-G2-05", "fil principal et sous-agent rendent la même sortie", "identiques", "; ".join(fautes))
    # R-G2-06 : frontmatter illisible
    rc, out, err = _ecrire_ok(ctx, None, "g2-adherent", "Write", "livrables/abime.md")
    v = classer(rc, out)
    if v == "avertit" and "erreur interne" not in contexte_de(out) and not err:
        ok("R-G2-06 PLAN.md au frontmatter illisible : plan ignoré, aucune exception ne sort du hook (G2 fail-open)")
    else:
        ko("R-G2-06", "un PLAN.md illisible est ignoré sans exception", "avertit (non couvert), rc 0", v + " " + court(out) + " " + court(err))
    bon, detail = controle_g2_07(ctx, None)
    ok("R-G2-07 " + detail) if bon else ko("R-G2-07", "lab dev qui contient un plan ouvert et un livrable non déclaré : silence", "octet vide", detail)
    # R-G2-PERF : 400 plans ouverts
    racine = ctx.unique("perf400")
    ecrire(os.path.join(racine, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    for i in range(1, 401):
        ecrire(os.path.join(racine, ".planning", "cycles", "01-c", "phases", "%03d-p" % i, "PLAN.md"),
               "---\necrit: livrables/f%d.md\n---\n" % i)
    brut = payload("Write", entree_outil("Write", racine + "/livrables/absent.md"), racine)
    t0 = time.perf_counter()
    rc, out, err = ctx.lancer("A", brut, cwd=racine)
    dt = time.perf_counter() - t0
    if classer(rc, out) == "avertit" and "400 plan(s) ouvert(s)" in contexte_de(out) and dt < 3.0:
        ok("R-G2-PERF lab adhérent de 400 plans ouverts : Write tranché en %.2f s (< 3 s)" % dt)
    else:
        ko("R-G2-PERF", "400 plans ouverts, Write hors ecrit: tranché en moins de 3 s", "avertit avec « 400 plan(s) ouvert(s) » en < 3 s", "%s en %.2f s" % (classer(rc, out), dt))


def sec_env(ctx):
    armee, n = ctx.copie_armee()
    if n != 5:
        ko("R-ENV-01", "la copie à l'armement forcé réécrit cinq constantes", "5", str(n))
        return
    bon, detail = controle_env(ctx, [ctx.scripts_dir, armee])
    ok("R-ENV-01 adhésion et armement indépendants de l'environnement (état livré et copie armée) : " + detail) if bon else ko(
        "R-ENV-01", "cinq environnements rendent le même verdict, octet pour octet (P45-D-12a ; limite (i) : la copie exécutée n'est pas testée ici)", "verdicts identiques", detail)


def sec_env_statique(ctx):
    bon, detail = controle_env_statique(ctx, ctx.hook)
    ok("R-ENV-02 garde statique : " + detail) if bon else ko(
        "R-ENV-02", "aucune lecture d'environnement dans le cœur Python de planning-hook.sh (expanduser et expandvars compris) ; lanceur : TMPDIR sur la ligne du mktemp, XDG_CACHE_HOME et HOME sur la ligne d'appel du cœur, une fois chacune", "aucune faute", detail)


def sec_g5(ctx):
    for ident, ctrl, titre in (
            ("R-G5-01", controle_g5_01, "Write de VERDICT.md sur copie observe"),
            ("R-G5-02", controle_g5_02, "le même Write sur copie armed"),
            ("R-G5-03", controle_g5_03, "Edit, NotebookEdit, casse, profondeur, tout rôle : refusés sur copie armed"),
            ("R-G5-04", controle_g5_04, "PLAN.md, nom voisin, livrable hors .planning/, lab dev : aucun refus"),
            ("R-G5-05", controle_g5_05, "erreur interne de G5 : observe journalise, armed refuse"),
            ("R-G5-06", controle_g5_06, "le journal ne porte jamais le contenu écrit")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


# --- Q-G6 = (b) (Willy, AskUserQuestion session principale, 2026-10-01) : G6 protège les scripts du hook --------------
# `.claude/scripts/planning-hook.sh` et son canary `check-gates-alive.sh`, là où l'installeur les pose dans un lab en scope projet.
# Les réglages `.claude/settings*.json` ne le sont PAS (limite (y)) ; Bash n'est pas couvert (P45-D-10).
SCRIPTS_HOOK_BANC = (".claude/scripts/planning-hook.sh", ".claude/scripts/check-gates-alive.sh")


def controle_g6_06(ctx, script):
    """Copie armed : Write, Edit et NotebookEdit de chaque script du hook sous `.claude/scripts/` d'un lab adhérent, fil principal
    et agent inconnu -> un deny G6 chacun dont le motif nomme le script et la mise à jour (/vf-update)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for rel in SCRIPTS_HOOK_BANC:
        for outil in ("Write", "Edit", "NotebookEdit"):
            for agent in (None, "agent-inconnu"):
                rc, out, err = _g6(ctx, d, outil, rel, agent=agent)
                n += 1
                v = classer(rc, out)
                if v != "deny" or err or len(out.splitlines()) != 1:
                    fautes.append("%s %s agent=%s -> %s" % (outil, rel, agent, v))
                    continue
                raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
                if not raison.startswith("[planning-core] G6 :") or rel not in raison or "/vf-update" not in raison:
                    fautes.append("%s %s agent=%s : raison %s" % (outil, rel, agent, raison))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G6 (2 scripts, Write, Edit et NotebookEdit, fil principal et agent inconnu), le motif nomme le script et /vf-update" % n)


def controle_g6_07(ctx, script):
    """Copie observe : Write d'un script du hook -> silence, code 0, UNE ligne gate=G6 chemin=.claude/scripts/... ; copie armed : les noms
    voisins, le même nom hors de `.claude/scripts/`, les réglages `.claude/settings*.json` (limite (y)) passent, un lab dev (hors
    adhésion) reste silencieux (GATE-10), stdout d'octet vide."""
    fautes = []
    o = ctx.copie_forcee(_dossier(ctx, script), "observe")
    cache = dossier_neuf(ctx, "cache-g6-07")
    rel = ".claude/scripts/planning-hook.sh"
    rc, out, err = _g6(ctx, o, "Write", rel, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=G6  " not in lignes[0] or ("  chemin=" + rel + "  ") not in lignes[0]:
        fautes.append("observe : rc=%d stdout=%s lignes=%s" % (rc, court(out), lignes))
    a = ctx.copie_forcee(_dossier(ctx, script), "armed")
    for voisin in (".claude/scripts/autre.sh", ".claude/scripts/planning-hook.sh.bak", ".claude/scripts/sous/planning-hook.sh",
                   ".claude/planning-hook.sh", "scripts/planning-hook.sh", "livrables/planning-hook.sh",
                   ".claude/settings.json", ".claude/settings.local.json"):
        rc, out, err = _g6(ctx, a, "Write", voisin)
        if classer(rc, out) not in ("silence", "avertit") or err or b"G6" in out:
            fautes.append("voisin %s -> %s %s" % (voisin, classer(rc, out), court(out)))
    for outil in ("Write", "Edit", "NotebookEdit"):
        for script_rel in SCRIPTS_HOOK_BANC:
            rc, out, err = _g6(ctx, a, outil, script_rel, lab="g6-dev")
            if rc != 0 or out != b"" or err:
                fautes.append("lab dev %s %s : rc=%d stdout=%s" % (outil, script_rel, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "observe : silence et une ligne gate=G6 ; armed : 8 voisins sans refus (dont settings*.json, limite (y)), lab dev silencieux (6 écritures, stdout vide)")


def lab_scripts(ctx):
    """Copie jetable du lab g6-adherent, avec liens dur et symbolique vers les scripts du hook, un alias du dossier
    `.claude/scripts` et un lien dur dans le dossier ; check-gates-alive.sh est ABSENT (la création d'un nom protégé se juge par la casse)."""
    lab = lab_frais(ctx, "g6-adherent")
    scripts = os.path.join(lab, ".claude", "scripts")
    os.link(os.path.join(scripts, "planning-hook.sh"), os.path.join(lab, "livrables", "dur-hook.sh"))
    os.link(os.path.join(scripts, "planning-hook.sh"), os.path.join(scripts, "dur.sh"))
    os.symlink(".claude/scripts/planning-hook.sh", os.path.join(lab, "lien-hook.sh"))
    os.symlink(".claude/scripts", os.path.join(lab, "alias-scripts"))
    os.remove(os.path.join(scripts, "check-gates-alive.sh"))
    return lab


def controle_g6_08(ctx, script):
    """Copie armée : variante de casse, lien dur (dans et hors du dossier), lien symbolique, alias du dossier, segment `..`, chemin relatif,
    création d'un script protégé absent (autre casse comprise) -> refus de G6 ; jumeaux sans refus."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = lab_scripts(ctx)
    fautes = []
    cas = ((".claude/scripts/Planning-Hook.sh", None), (".CLAUDE/scripts/planning-hook.sh", None), ("livrables/dur-hook.sh", None),
           (".claude/scripts/dur.sh", None), ("lien-hook.sh", None), ("alias-scripts/planning-hook.sh", None),
           (".claude/scripts/x/../planning-hook.sh", None), (".claude/../.claude/scripts/planning-hook.sh", None),
           (".claude/scripts/check-gates-alive.sh", None), (".claude/scripts/Check-Gates-Alive.SH", None),
           (".claude/scripts/planning-hook.sh", "plugin-inconnu:agent-inconnu"), ("livrables/dur-hook.sh", "agent-inconnu"),
           # lot E, F3 : création d'un script ABSENT par un dossier aliasé ou de casse différente (le dossier se juge par samefile, jamais
           # par comparaison de chaînes : sous le mutant G6-SCRIPT-DOSSIER-CHAINES, une autre casse du dossier échappe à G6)
           ("alias-scripts/check-gates-alive.sh", None), (".CLAUDE/scripts/check-gates-alive.sh", None),
           (".claude/Scripts/check-gates-alive.sh", None), (".CLAUDE/SCRIPTS/Check-Gates-Alive.SH", "agent-inconnu"))
    for rel, agent in cas:
        bon, detail = _refus_de(ctx, hook, lab, "G6", "Write", rel, agent=agent)
        if not bon:
            fautes.append(detail)
    bon, detail = _refus_de(ctx, hook, lab, "G6", "Write", entree=entree_outil("Write", ".claude/scripts/planning-hook.sh"))
    if not bon:
        fautes.append("chemin relatif : " + detail)
    for rel in ("livrables/planning-hook.sh", "scripts/planning-hook.sh", ".claude/scripts/planning-hook.sh.bak", ".claude/agents/planning-hook.sh",
                ".claude/settings.json"):
        bon, detail = _passage_de(ctx, hook, lab, "Write", rel)
        if not bon:
            fautes.append("jumeau : " + detail)
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus G6 (casse, lien dur dans et hors du dossier, lien symbolique, alias, segment .., chemin relatif, création en autre casse, deux rôles), 5 jumeaux sans refus" % (len(cas) + 1))


def controle_g6_09(ctx, script):
    """Une dérogation G6 nominative sur `.claude/scripts/planning-hook.sh` : premier Write cité et consommé, second refusé ; l'autre script reste refusé."""
    lab = lab_frais(ctx, "g6-adherent")
    os.remove(journal_derog(lab))
    rc, out, err = deroger(ctx, lab, None, gate="G6", chemins=(".claude/scripts/planning-hook.sh",))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    r1 = ecrire_dans(ctx, hook, lab, "Write", ".claude/scripts/planning-hook.sh")
    if classer(r1[0], r1[1]) != "avertit" or r1[2] or "#1" not in contexte_de(r1[1]):
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    r2 = ecrire_dans(ctx, hook, lab, "Write", ".claude/scripts/planning-hook.sh")
    r3 = ecrire_dans(ctx, hook, lab, "Write", ".claude/scripts/check-gates-alive.sh")
    if classer(r2[0], r2[1]) != "deny" or classer(r3[0], r3[1]) != "deny":
        return False, "second Write : %s ; autre script : %s" % (classer(r2[0], r2[1]), classer(r3[0], r3[1]))
    return True, "dérogation G6 sur un script du hook : premier Write passe et cité, consommée, second refusé, l'autre script reste refusé"


def sec_g6(ctx):
    for ident, ctrl, titre in (
            ("R-G6-01", controle_g6_01, "Write d'un fichier généré sur copie observe"),
            ("R-G6-02", controle_g6_02, "chaque fichier généré, Write et Edit, tout rôle : refusé sur copie armed"),
            ("R-G6-03", controle_g6_03, "compartiments, plans du modèle, notes : aucun refus de G6"),
            ("R-G6-04", controle_g6_04, "lab dev : stdout d'octet vide"),
            ("R-G6-05", controle_g6_05, "dérogation G6 honorée, citée et consommée"),
            ("R-G6-06", controle_g6_06, "Q-G6 = b : scripts du hook (scope projet), Write, Edit, NotebookEdit : refusés sur copie armed"),
            ("R-G6-07", controle_g6_07, "scripts du hook : observe journalise, voisins et settings*.json passent, lab dev silencieux"),
            ("R-G6-08", controle_g6_08, "scripts du hook : identité (casse, liens, alias, .., relatif, création)"),
            ("R-G6-09", controle_g6_09, "scripts du hook : dérogation nominative honorée et consommée")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_id(ctx):
    for ident, ctrl, titre in (
            ("R-ID-01", controle_id_01, "identité : casse, lien dur, alias, segment .., création en autre casse (G6)"),
            ("R-ID-02", controle_id_02, "identité : lien dur vers un VERDICT.md sous un autre nom (G5)"),
            ("R-ID-03", controle_id_03, "F6 : config.json ne perd pas l'adhésion cycles-v1 par un outil"),
            ("R-ID-04", controle_id_04, "F7b : le cache du recalcul est protégé"),
            ("R-ID-05", controle_id_05, "recalc-planning.sh (commande) écrit toujours, le hook n'en voit rien")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_cang(ctx):
    for ident, ctrl, titre in (
            ("R-CANG-01", controle_cang_01, "canary de session, G6 et G5 en observe"),
            ("R-CANG-02", controle_cang_02, "canary de session, G6 et G5 armed"),
            ("R-CANG-03", controle_cang_03, "canary de session, evaluer_g6 neutralisé"),
            ("R-CANG-G1", controle_cang_g1, "canary de session, cas G1-sans-cadrage"),
            ("R-CANG-G7", controle_cang_g7, "canary de session, cas G7-orphelin"),
            ("R-CANG-ROLE", controle_cang_role, "canary de session, cas du rôle (juge, worker sous Agent, worker sous Task)"),
            ("R-CANG-ROLE-MORT", controle_cang_role_mort, "canary de session, evaluer_role neutralisé"),
            ("R-CANG-COUVERTURE", controle_cang_couverture, "canary de session, couverture minimale déclarée (P45-D-20)"),
            ("R-CANG-EVT-01", controle_cang_evt_01, "canary de session, la commande sous les cinq événements (Phase 46)"),
            ("R-CANG-EVT-02", controle_cang_evt_02, "canary de session, cas DEGRADE D09 et D10 (SubagentHandback en mode dégradé)")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    # Mutants du canary (Phase 46) : l'événement non câblé n'est plus vu, une autre commande est reconnue, le cas D09 est retiré
    for ident, motif, remplacement, ctrl, nom_ctrl in (
            ("CANG-EVT-MANQUANT", "# canary-evenements", "sans, non_reconnus = [], []  # canary-evenements", controle_cang_evt_01, "R-CANG-EVT-01"),
            ("CANG-EVT-RECONNUE", "# canary-evenement-reconnue", "if True:  # canary-evenement-reconnue", controle_cang_evt_01, "R-CANG-EVT-01"),
            ("CANG-EVT-CAS-D09", '"D09|DEGRADE|script-absent|SubagentHandback|script-absent",', "", controle_cang_evt_02, "R-CANG-EVT-02")):
        dossier, raison = make_script_mutant(ctx, "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF", ident, motif, remplacement)
        if dossier is None:
            komut(ident, "mutant du canary valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
            continue
        original = ctrl(ctx, None)
        mutant = ctrl(ctx, dossier)
        if not original[0]:
            komut(ident, "l'original passe " + nom_ctrl, "conforme", original[1])
        elif mutant[0]:
            komut(ident, nom_ctrl + " rougit sous le mutant", "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
        else:
            okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s" % (nom_ctrl, original[1], mutant[1][:400]))


def sec_g1(ctx):
    for ident, ctrl, titre in (
            ("R-G1-01", controle_g1_01, "Write du PLAN.md d'une phase sans CADRAGE.md sur copie observe"),
            ("R-G1-02", controle_g1_02, "le même Write et Edit sur copie armed, plan direct et sous plans/"),
            ("R-G1-03", controle_g1_03, "phase cadrée, socle v2, nom d'unité invalide, lab dev : aucun refus")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    bon, detail = controle_croise_g1(ctx, None)
    ok("R-G1-04 contrôle croisé avec recalc-planning.sh --read-only : " + detail) if bon else ko(
        "R-G1-04", "G1 refuse pour absence de CADRAGE.md <=> le recalcul rend `à cadrer` ou `hors-cadrage:*`, phase par phase des deux bancs",
        "aucune divergence", detail)
    for ident, ctrl, titre in (
            ("R-G1-05", controle_g1_05, "registre ouvert sur copie armed : le refus cite l'id de chaque ligne ouverte"),
            ("R-G1-06", controle_g1_06, "la valeur d'un statut n'est jamais jugée"),
            ("R-G1-07", controle_g1_07, "bord F5 (f5-etats) : état indéterminé jamais refusé, absence de CADRAGE.md toujours refusée"),
            ("R-G1-09", controle_g1_09, "dérogation G1 honorée, citée et consommée")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    bon, detail = controle_croise_g1_etendu(ctx, None)
    ok("R-G1-08 contrôle croisé étendu : " + detail) if bon else ko(
        "R-G1-08", "G1 refuse (absence ou registre ouvert) <=> `à cadrer`, `en cadrage`, `hors-cadrage:*`, `avant-cadrage-clos:*` ; états illisibles jamais refusés",
        "aucune divergence", detail)


def sec_g7(ctx):
    for ident, ctrl, titre in (
            ("R-G7-01", controle_g7_01, "Write d'un .planning/ à créer dans un dossier nu sur copie observe"),
            ("R-G7-02", controle_g7_02, "le même Write et NotebookEdit sur copie armed, tout rôle"),
            ("R-G7-03", controle_g7_03, "marqueur de projet de code : un cas par marqueur, faux marqueurs refusés"),
            ("R-G7-04", controle_g7_04, ".planning/ existant, Edit, lab dev, dossier sans ancêtre planifié : aucun refus")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)
    bon, detail = controle_g7_05(ctx, ctx.hook)
    ok("R-G7-05 contrôle croisé des marqueurs avec le texte du détecteur : " + detail) if bon else ko(
        "R-G7-05", "MARQUEURS_CODE ∪ {*.xcodeproj} du hook = l'ensemble extrait du texte de detect-gsd-engine.sh", "ensembles égaux", detail)
    for dossier, libelle, attendu, obtenu in cas_habite(ctx, None):
        print("G7-HABITE cas=%s attendu=%s obtenu=%s (%s)" % (dossier, attendu, obtenu, libelle))
    for ident, ctrl, titre in (
            ("R-G7-06", controle_g7_06, "prédicat « habité » littéral de P45-D-14 (agent ET mémoire), tableau des cas imprimé (G7-HABITE)"),
            ("R-G7-07", controle_g7_07, "fichiers réguliers seulement : lien symbolique, memory/ sans fichier, agents/*.txt ne comptent pas"),
            ("R-G7-08", controle_g7_08, "dérogation G7 honorée, citée et consommée")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_role(ctx):
    for ident, ctrl, titre in (
            ("R-ROLE-01", controle_role_01, "Write d'un livrable par un juge du lab sur copie observe"),
            ("R-ROLE-02", controle_role_02, "le même Write, Edit et NotebookEdit sur copie armed, casse et séparateurs normalisés"),
            ("R-ROLE-03", controle_role_03, "fil principal, agent inconnu, agent de plugin non résolu : aucun refus de rôle"),
            ("R-ROLE-04", controle_role_04, "résolution : lab avant compte, ambigu = inconnu, repli sur le nom de fichier, compte, plugin"),
            ("R-ROLE-05", controle_role_05, "lab dev : stdout d'octet vide pour tout rôle et tout outil"),
            ("R-ROLE-06", controle_role_06, "--classer et définition illisible traitée en inconnu"),
            ("R-ROLE-07", controle_role_07, "erreur interne de evaluer_role : observe journalise, armed refuse"),
            ("R-ROLE-08", controle_role_08, "worker : dispatch dans sa propre allowlist passe, hors liste refusé, sous Agent ET Task (F9 = f9-allowlist)"),
            ("R-ROLE-09", controle_role_09, "subagent_type normalisé des deux côtés, chaîne entière, aucun préfixe retiré"),
            ("R-ROLE-10", controle_role_10, "racine du dispatch dérivée du cwd du payload (lab dev : silence)"),
            ("R-ROLE-11", controle_role_11, "manager, producteur, juge, fil principal, inconnu, ambigu, illisible : dispatch jamais refusé"),
            ("R-ROLE-12", controle_role_12, "dérogation ROLE honorée, citée et consommée ; COMPTE ROLE du banc"),
            ("R-ROLE-13", controle_role_13, "HOME : entrée déclarée de la résolution du compte, jamais de l'adhésion ni de l'armement")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_registre(ctx):
    bon, detail = controle_registre(ctx, ctx.hook)
    ok("R-REGISTRE " + detail) if bon else ko("R-REGISTRE", "les arbres ast de lire_registre du hook et du moteur de recalcul sont identiques", "identiques", detail)


def sec_verdict(ctx):
    for ident, ctrl, titre in (
            ("R-VERDICT-01", controle_verdict_01, "création au format du gabarit, hash sha256 du PLAN.md"),
            ("R-VERDICT-02", controle_verdict_02, "tentative 1 puis +1, fichier inchangé sur refus, lien jamais suivi"),
            ("R-VERDICT-03", controle_verdict_03, "le moteur de recalcul relit tentative et hash"),
            ("R-VERDICT-04", controle_verdict_04, "refus hors lab adhérent, hors cycles, sans PLAN.md, constat invalide"),
            ("R-VERDICT-05", controle_verdict_05, "jamais vue par G5")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_derog(ctx):
    for ident, ctrl, titre in (
            ("R-DEROG-01", controle_derog_01, "dérogation valide, une ligne par chemin, journal jamais tronqué"),
            ("R-DEROG-02", controle_derog_02, "raison placeholder et champs invalides refusés"),
            ("R-DEROG-03", controle_derog_03, "encodage injectif : aucune ligne injectée"),
            ("R-DEROG-04", controle_derog_04, "dérogation honorée et citée sur copie armée"),
            ("R-DEROG-05", controle_derog_05, "usage unique"),
            ("R-DEROG-06", controle_derog_06, "sans effet en observe"),
            ("R-DEROG-07", controle_derog_07, "journal en lien symbolique"),
            ("R-DEROG-08", controle_derog_08, "aucune option liée à l'urgence")):
        bon, detail = ctrl(ctx, None)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_obs_env(ctx):
    bon, detail = controle_obs_env(ctx, None)
    ok("R-OBS-ENV " + detail) if bon else ko("R-OBS-ENV", "le journal suit XDG_CACHE_HOME puis HOME et rien d'autre ; les valeurs n'atteignent jamais l'armement ni l'adhésion", "conforme", detail)


def sec_jeton(ctx):
    bon, detail = controle_jeton(ctx, ctx.hook)
    ok("R-JETON " + detail) if bon else ko("R-JETON", "l'encodeur du journal du hook est ast-identique à _jeton_journal du moteur de recalcul", "identiques", detail)


def sec_accord(ctx):
    bon, detail = controle_accord(ctx, None)
    ok("R-ACCORD " + detail) if bon else ko("R-ACCORD", "chemin relatif : avertissement G2 en mode A <=> deny en mode C (limite h)", "accord des deux couches", detail)


def sec_banc(ctx):
    ordre, labs, chemins = labs_banc(ctx)
    compte = {}
    faux = {}  # gate -> [faux refus, faux accept] du banc, rejoué sur copie armée
    tout_ok = True
    for nom in ordre:
        for e in labs[nom]["ecritures"]:
            brut, cwd = entree_de_ecriture(e, chemins[nom])
            dossier = ctx.copie_forcee(ctx.scripts_dir, "armed") if e["armee"] else None
            rc, out, err = ctx.lancer("A", brut, cwd=cwd, dossier=dossier)
            bon, obtenu = juger(e["attendu"], e["gate"], rc, out)
            etiquette = "BANC %s %s %s%s%s%s%s :: %s %s" % (nom, e["outil"], e["chemin"], (" agent=" + e["agent"]) if e["agent"] else "", (" sous=" + e["sous"]) if e.get("sous") else "", " armee" if e["armee"] else "", (" " + e["commande"]) if e["commande"] else "", e["attendu"], e["gate"] or "")
            if bon and not err:
                ok(etiquette.strip())
            else:
                tout_ok = False
                ko(etiquette.strip(), "écriture du banc rejouée par la commande enregistrée", e["attendu"], obtenu + " " + court(out) + " " + court(err))
            compte.setdefault(e["gate"], {}).setdefault(e["attendu"], 0)
            compte[e["gate"]][e["attendu"]] += 1
            if e["attendu"] == "doit-passer" and obtenu == "deny":
                faux.setdefault(e["gate"], [0, 0])[0] += 1
            elif e["attendu"] == "doit-refuser" and obtenu != "deny":
                faux.setdefault(e["gate"], [0, 0])[1] += 1
    for gate in ("G2",):
        c = compte.get(gate, {})
        print("COUVERTURE %s avertit=%d silence=%d" % (gate, c.get("avertit", 0), c.get("silence", 0)))
        if c.get("avertit", 0) < 1 or c.get("silence", 0) < 1:
            ko("COUVERTURE " + gate, "au moins un cas `avertit` et un cas `silence` pour " + gate, ">= 1 chacun", str(c))
        else:
            ok("COUVERTURE %s : %d avertit, %d silence" % (gate, c["avertit"], c["silence"]))
    for gate in ("G5", "G6", "G1", "G7", "ROLE"):
        c = compte.get(gate, {})
        print("COUVERTURE %s doit-refuser=%d doit-passer=%d silence=%d" % (gate, c.get("doit-refuser", 0), c.get("doit-passer", 0), c.get("silence", 0)))
        if c.get("doit-refuser", 0) < 1 or c.get("doit-passer", 0) < 1 or c.get("silence", 0) < 1:
            ko("COUVERTURE " + gate, "au moins un cas doit-refuser, un cas doit-passer et un cas silence (jumeau dev) pour " + gate, ">= 1 chacun", str(c))
        else:
            ok("COUVERTURE %s : %d doit-refuser, %d doit-passer, %d silence (0 faux refus, 0 faux accept : chaque cas est conforme)" % (gate, c["doit-refuser"], c["doit-passer"], c["silence"]))
    # comptes du banc, par gate de l'étape 1 (P45-D-03b : l'armement exige 0 et 0)
    for gate in ("G5", "G6", "G1", "G7", "ROLE"):
        fr, fa = faux.get(gate, [0, 0])
        print("COMPTE %s faux-refus=%d faux-accept=%d" % (gate, fr, fa))
    if faux.get("G1", [0, 0]) == [0, 0] and compte.get("G1"):
        ok("R-G1-10 banc G1 sur copie armée : COMPTE G1 faux-refus=0 faux-accept=0")
    else:
        ko("R-G1-10", "banc G1 sur copie armée : zéro faux refus, zéro faux accept", "G1 [0, 0]", "G1=%s" % (faux.get("G1"),))
    bon, detail = controle_g7_09(ctx, None)
    if bon and faux.get("G7", [0, 0]) == [0, 0] and compte.get("G7"):
        ok("R-G7-09 banc G7 sur copie armée : COMPTE G7 faux-refus=0 faux-accept=0 (%s)" % detail)
    else:
        ko("R-G7-09", "banc G7 sur copie armée : zéro faux refus, zéro faux accept", "G7 [0, 0]", "G7=%s ; %s" % (faux.get("G7"), detail))
    if all(faux.get(g, [0, 0]) == [0, 0] for g in ("G5", "G6")) and all(compte.get(g) for g in ("G5", "G6")):
        ok("R-ID-06 banc complet G5 + G6 sur copie armée : COMPTE G5 faux-refus=0 faux-accept=0, COMPTE G6 faux-refus=0 faux-accept=0")
    else:
        ko("R-ID-06", "banc complet G5 + G6 sur copie armée : zéro faux refus, zéro faux accept", "G5 [0, 0], G6 [0, 0]", "G5=%s G6=%s" % (faux.get("G5"), faux.get("G6")))
    # jumeau négatif : chaque lab jumeau a au moins un cas
    for nom in ordre:
        if labs[nom]["jumeau_de"] and not labs[nom]["ecritures"]:
            ko("COUVERTURE jumeau " + nom, "un lab jumeau porte des écritures", ">= 1", "0")


CTRL_FICHIER = (controle_table_02, controle_parseur, controle_env_statique, controle_jeton, controle_registre, controle_g7_05)


def sec_mutants(ctx):
    M = [
        ("G2-DECISION", '"additionalContext": "\\n".join(textes),',
         '"additionalContext": "\\n".join(textes), "permissionDecision": "deny",', "R-G2-01", controle_g2_01),
        ("G2-ECRIT", "for _plan, entrees in plans:  # g2-union", "for _plan, entrees in plans[:1]:  # g2-union", "R-G2-02", controle_g2_02),
        ("G2-CLOS", "# g2-clos", "if False:  # g2-clos", "R-G2-03", controle_g2_03),
        ("PY-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-G2-07", controle_g2_07),
        ("TABLE-ORDRE", "gates = [gate for etape in ORDRE_ETAPES for gate in etape]  # armement-valide-debut", "return True",
         "R-TABLE-02", controle_table_02),
        ("TABLE-ORDRE-REFUS", "gates = [gate for etape in ORDRE_ETAPES for gate in etape]  # armement-valide-debut", "return True",
         "R-TABLE-03", controle_table_03),
        ("PARSEUR", 'return ("invalide:frontmatter-non-ferme", {})', 'return ("invalide:frontmatter-non-ferme-mute", {})',
         "R-PARSEUR", controle_parseur),
        ("ENV-ADHESION", 'SCHEMA_ADHESION = "cycles-v1"', 'SCHEMA_ADHESION = os.environ.get("VF_SCHEMA_ADHESION", "cycles-v1")',
         "R-ENV-01", lambda c, d: controle_env(c, [d])),
        ("ENV-ARMEMENT", 'G2_MODE = "avertit"', 'G2_MODE = os.environ.get("VF_ARMEMENT", "avertit")',
         "R-ENV-01", lambda c, d: controle_env(c, [d])),
        ("ACCORD-PY", 'ecrit = base + "/" + ecrit', "pass", "R-ACCORD", controle_accord),
        ("ENV-STATIQUE", 'G2_MODE = "avertit"', 'G2_MODE = os.environ.get("VF_NOM_NON_LISTE_PAR_LE_TEST", "avertit")',
         "R-ENV-02", controle_env_statique),
        ("ENV-LANCEUR", 'T="$(mktemp "${TMPDIR:-/tmp}/vf-planning-hook.XXXXXX")" || exit 70',
         'T="$(mktemp "${TMPDIR:-${HOME:-/tmp}}/vf-planning-hook.XXXXXX")" || exit 70', "R-ENV-02", controle_env_statique),
        # 45-04 : entonnoir, G5, journal d'observation, encodeur, amendement de R-ENV-02
        ("G5-CASSE", 'if composants[-1].casefold() != NOM_VERDICT:  # g5-casse',
         'if composants[-1] != "VERDICT.md":  # g5-casse', "R-G5-03", controle_g5_03),
        ("G5-PERIMETRE", 'if not composants or composants[0].casefold() != ".planning":  # g5-perimetre',
         'if not composants:  # g5-perimetre', "R-G5-04", controle_g5_04),
        ("DECIDER-OBSERVE", 'if etat == "armed":  # decider-armed', 'if etat in ("armed", "observe"):  # decider-armed',
         "R-G5-01", controle_g5_01),
        ("DECIDER-ARMED", 'if etat == "armed":  # decider-armed', 'if False:  # decider-armed', "R-G5-02", controle_g5_02),
        ("OBS-CONTENU", '# obs-ligne',
         r'ligne = "{}  gate={}  lab={}  chemin={}  outil={}  raison={}  contenu={}\n".format(horodatage, verdict.gate, _jeton_journal(contexte.get("racine"), "-"), _jeton_journal(verdict.chemin_rel, "-"), _jeton_journal(contexte.get("outil"), "-"), _jeton_journal(verdict.raison, "-"), _jeton_journal(str((contexte["payload"].get("tool_input") or {}).get("content", "")), "-"))  # obs-ligne',
         "R-G5-06", controle_g5_06),
        ("JETON", 'if caractere == "%" or caractere == "=" or caractere.isspace() or not caractere.isprintable():',
         'if caractere == "%" or caractere.isspace() or not caractere.isprintable():', "R-JETON", controle_jeton),
        ("OBS-CHEMIN", 'if isinstance(xdg, str) and xdg.startswith("/"):  # obs-xdg', 'if False:  # obs-xdg',
         "R-OBS-ENV", controle_obs_env),
        ("ENV-EXPANDUSER", 'SCHEMA_ADHESION = "cycles-v1"', 'SCHEMA_ADHESION = "cycles-v1" + os.path.expanduser("~")[:0]',
         "R-ENV-02", controle_env_statique),
        ("OBS-ARMEMENT", 'etat = TABLE_ARMEMENT.get(verdict.gate)',
         'etat = "armed" if (TABLE_ARMEMENT.get(verdict.gate) == "observe" and not os.access(os.path.dirname(chemin_journal_observation(contexte.get("arg_xdg"), contexte.get("arg_home")) or "/"), os.W_OK)) else TABLE_ARMEMENT.get(verdict.gate)',
         "R-OBS-ENV", controle_obs_env),
        ("OBS-ADHESION", 'adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"]',
         'adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"] and sys.argv[3] != ""',
         "R-OBS-ENV", controle_obs_env),
        # 45-04 : dérogation nominative
        ("DEROG-PLACEHOLDER", "# derog-placeholders", 'PLACEHOLDERS = ()  # derog-placeholders', "R-DEROG-02", controle_derog_02,
         "deroger-gate.sh", "PY_DEROGER_GATE_EOF"),
        ("DEROG-INJECTIF", "# derog-encodage", 'raison_j = valeurs["raison"]  # derog-encodage', "R-DEROG-03", controle_derog_03,
         "deroger-gate.sh", "PY_DEROGER_GATE_EOF"),
        ("DEROG-UNIQUE", "# derog-consommee", 'if False:  # derog-consommee', "R-DEROG-05", controle_derog_05),
        ("DEROG-LIEN", "# derog-lien", 'return os.open(chemin, mode)  # derog-lien', "R-DEROG-07", controle_derog_07),
        # 45-04 : commande de verdict
        ("VERDICT-TENTATIVE", "# verdict-tentative", 'if False:  # verdict-tentative', "R-VERDICT-02", controle_verdict_02,
         "poser-verdict.sh", "PY_POSER_VERDICT_EOF"),
        ("VERDICT-ATOMIQUE", "# verdict-atomique", 'open(chemin_verdict, "w", encoding="utf-8").write(texte)  # verdict-atomique',
         "R-VERDICT-02", controle_verdict_02, "poser-verdict.sh", "PY_POSER_VERDICT_EOF"),
        # 45-05 : G6 et canary de l'étape 1
        ("G6-RACINE", "# g6-racine", "a_la_racine = True  # g6-racine", "R-G6-03", controle_g6_03),
        # Q-G6 = (b) : scripts du hook
        ("G6-SCRIPTS", "# g6-scripts", "SCRIPTS_HOOK_G6 = ()  # g6-scripts", "R-G6-06", controle_g6_06),
        ("G6-SCRIPT-RACINE", "# g6-script-racine", "if False:  # g6-script-racine", "R-G6-08", controle_g6_08),
        ("G6-SCRIPT-DOSSIER-CHAINES", "# g6-script-racine", "if parent == dossier:  # g6-script-racine", "R-G6-08", controle_g6_08),
        ("G6-SCRIPT-CASEFOLD", "# g6-script-casefold", "if canonique == nom:  # g6-script-casefold", "R-G6-08", controle_g6_08),
        ("G6-SCRIPT-SAMEFILE", "# g6-script-samefile", "if False:  # g6-script-samefile", "R-G6-08", controle_g6_08),
        ("G6-SCRIPT-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-G6-07", controle_g6_07),
        ("G6-SCRIPT-DEROG", "# g6-scripts", "SCRIPTS_HOOK_G6 = ()  # g6-scripts", "R-G6-09", controle_g6_09),
        ("G6-NOMS", "# g6-noms", 'GENERES_PAR_RECALC = ("STATE.md", "INDEX.md")  # g6-noms', "R-G6-02", controle_g6_02),
        ("CANG-OBS", "# canary-observation", "if True:  # canary-observation", "R-CANG-03", controle_cang_03,
         "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF"),
        # 45-05 : identité, F6, F7b
        ("ID-SAMEFILE", "# g6-samefile", "if False:  # g6-samefile", "R-ID-01", controle_id_01),
        ("ID-SAMEFILE-G5", "# g5-samefile", "if False:  # g5-samefile", "R-ID-02", controle_id_02),
        ("ID-CASEFOLD", "# id-casefold", "if a_la_racine and nom in [n for n, _g in PROTEGES_G6.values()]:  # id-casefold",
         "R-ID-01", controle_id_01),
        ("F6", "# g6-adhesion", "return None  # g6-adhesion", "R-ID-03", controle_id_03),
        ("F7B", "# g6-noms", 'GENERES_PAR_RECALC = ("STATE.md", "INDEX.md", "cloture.log")  # g6-noms', "R-ID-04", controle_id_04),
        # 45-06 : G1
        ("G1-CADRAGE", "# g1-cadrage", "if False:  # g1-cadrage", "R-G1-02", controle_g1_02),
        ("G1-FORME", "# g1-forme", 'dossier_phase = composants[:5] if composants and composants[-1].casefold() == "plan.md" else None  # g1-forme',
         "R-G1-03", controle_g1_03),
        ("G1-PHASE", "# g1-phase", "return composants[:-1]  # g1-phase", "R-G1-02", controle_g1_02),
        ("G1-OUVERT", "# g1-ouvert", "if True:  # g1-ouvert", "R-G1-05", controle_g1_05),
        ("G1-STATUT", 'if structurante == "oui" and not (isinstance(statut, str) and statut.strip()):',
         'if structurante == "oui" and statut != "ARBITRÉ":', "R-G1-06", controle_g1_06),
        ("G1-BORD", "# g1-bord", "if registre_ok:  # g1-bord", "R-G1-07", controle_g1_07),
        ("REGISTRE", "    clos = True", "    clos = False", "R-REGISTRE", controle_registre),
        # 45-07 : G7
        ("G7-MARQUEUR", "# g7-marqueurs",
         'MARQUEURS_CODE = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle", "build.gradle.kts", "composer.json", "tsconfig.json", "Package.swift")  # g7-marqueurs',
         "R-G7-05", controle_g7_05),
        ("G7-MARQUEUR-GEMFILE", "# g7-marqueurs",
         'MARQUEURS_CODE = ("package.json", "go.mod", "Cargo.toml", "pyproject.toml", "pom.xml", "build.gradle", "build.gradle.kts", "composer.json", "tsconfig.json", "Package.swift")  # g7-marqueurs',
         "R-G7-03", controle_g7_03),
        ("G7-EXISTE", "# g7-existe", "if composant.casefold() == NOM_PLANNING:  # g7-existe", "R-G7-04", controle_g7_04),
        ("G7-PERIMETRE", "sys.exit(0)  # non-adherent", "pass", "R-G7-04", controle_g7_04),
        ("G7-HABITE", "# g7-habite", "if True:  # g7-habite", "R-G7-06", controle_g7_06),
        ("G7-REGULIER", "# g7-regulier-agent", 'if nom.endswith(".md") and not nom.startswith(".") and os.path.exists(os.path.join(agents, nom)):  # g7-regulier-agent',
         "R-G7-07", controle_g7_07),
        ("G7-BANC-ACCEPT", "# g7-habite", "if True:  # g7-habite", "R-G7-09", controle_g7_09),
        ("G7-BANC-REFUS", "porte_marqueur_code(x):  # g7-marqueur", "if False:  # g7-marqueur", "R-G7-09", controle_g7_09),
        ("G7-REGULIER-MEMOIRE", "# g7-regulier-memoire", "if os.path.exists(os.path.join(dossier, nom)):  # g7-regulier-memoire", "R-G7-07", controle_g7_07),
        # 45-08 : le hook par rôle (ligne juge)
        ("ROLE-NORMALISATION", "# role-normaliser", "return nom  # role-normaliser", "R-ROLE-02", controle_role_02),
        ("ROLE-PRINCIPAL", "# role-principal",
         'role, definition = ("juge", None) if not agent_id else resoudre_agent(agent_type, racine, contexte.get("arg_home"))  # role-principal',
         "R-ROLE-03", controle_role_03),
        ("ROLE-NIVEAU", "# role-niveaux", "niveaux = [dossier_compte, dossier_lab]  # role-niveaux", "R-ROLE-04", controle_role_04),
        ("PY-ADHESION-ROLE", "sys.exit(0)  # non-adherent", "pass", "R-ROLE-05", controle_role_05),
        ("ROLE-HOME", "# role-home",
         'dossier_compte = os.path.join("/inexistant-role-home", ".claude", "agents") if avec_home else None  # role-home',
         "R-ROLE-13", controle_role_13),
        ("ROLE-HOME-ARMEMENT", 'etat = TABLE_ARMEMENT.get(verdict.gate)',
         'etat = "armed" if (verdict.gate == "ROLE" and os.path.isdir(os.path.join(contexte.get("arg_home") or "/inexistant", ".claude", "agents"))) else TABLE_ARMEMENT.get(verdict.gate)',
         "R-ROLE-13", controle_role_13),
        # 45-08 : le hook par rôle (ligne worker, F9 = f9-allowlist)
        ("ROLE-TASK", "# role-dispatch", 'OUTILS_DISPATCH = ("Agent",)  # role-dispatch', "R-ROLE-08", controle_role_08),
        ("ROLE-SUBAGENT", "# role-allowlist",
         'if isinstance(sous, str) and sous in allowlist_de_definition(definition):  # role-allowlist', "R-ROLE-09", controle_role_09),
        ("ROLE-WORKER", "# role-worker", 'if False:  # role-worker', "R-ROLE-08", controle_role_08),
        ("ROLE-ALLOWLIST", "# role-allowlist", 'if False:  # role-allowlist', "R-ROLE-08", controle_role_08),
        ("ROLE-CWD", "# racine-depart", 'depart = ecrit if ecrit is not None else os.getcwd()  # racine-depart', "R-ROLE-10", controle_role_10),
        # 45-09 : canary du rôle et couverture minimale (P45-D-20)
        ("CANG-TASK", '"ROLE-worker-Task|ROLE|', "# cas ROLE-worker-Task retiré de CANARIS", "R-CANG-COUVERTURE", controle_cang_couverture,
         "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF"),
        ("CANG-COUVERTURE", "# couverture-manquants", "return []  # couverture-manquants", "R-CANG-COUVERTURE", controle_cang_couverture,
         "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF"),
    ]
    filtre = [f for f in os.environ.get("VF_GATES_MUTANTS", "").split(",") if f]  # facultatif : sous-chaînes d'identifiants, développement
    for entree in M:
        ident, motif, repl, cible, ctrl = entree[:5]
        if filtre and not any(f in ident for f in filtre):
            continue
        nom_script, marqueur = entree[5:7] if len(entree) > 5 else ("planning-hook.sh", "PY_PLANNING_HOOK_EOF")
        dossier, raison = make_script_mutant(ctx, nom_script, marqueur, ident, motif, repl)
        if dossier is None:
            komut(ident, "mutant du cœur valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
            continue
        chemin_mut = os.path.join(dossier, "planning-hook.sh")
        cible_script = chemin_mut if ctrl in CTRL_FICHIER else dossier
        # l'original passe le contrôle ; le mutant le rate ; le témoin reste inchangé
        original = ctrl(ctx, ctx.hook if ctrl in CTRL_FICHIER else ctx.scripts_dir)
        t_orig, t_mut = controle_temoin(ctx, None), controle_temoin(ctx, dossier)
        mutant = ctrl(ctx, cible_script)
        if not original[0]:
            komut(ident, "l'original passe %s (garde du témoin de la mutation)" % cible, "conforme", original[1])
        elif t_orig != t_mut:
            komut(ident, "témoin (Write neutre d'un lab adhérent) inchangé sous le mutant", str(t_orig), str(t_mut))
        elif mutant[0]:
            komut(ident, "%s rougit sous le mutant" % cible, "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
        else:
            okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s · témoin inchangé"
                  % (cible, original[1], mutant[1]))


# =================================================================================================
# LOT A (correction ciblée post-45-09 : revue de phase et audit de sécurité sur e13a426 ; décisions du manager
# vf-dev-manager, 2026-10-01, renversables) : chaque constat a son contrôle, rejoué sur le script livré ET sur un
# mutant qui retire le seul correctif (le contrôle doit rougir sur le mutant : la trace est imprimée).
# =================================================================================================
LOTA_CONTROLES = []   # [(identifiant, fonction(ctx, dossier_de_scripts) -> (conforme, détail))]
LOTA_MUTANTS = []     # [(identifiant du mutant, motif, remplacement, identifiant du contrôle, nom du script, marqueur du heredoc)]


def lota(ident):
    def deco(f):
        LOTA_CONTROLES.append((ident, f))
        return f
    return deco


def lota_mutant(ident, motif, remplacement, controle, nom="planning-hook.sh", marqueur="PY_PLANNING_HOOK_EOF"):
    LOTA_MUTANTS.append((ident, motif, remplacement, controle, nom, marqueur))


def lota_executer(fonction, ctx, dossier):
    """(conforme, détail) d'un contrôle ; une exception du contrôle est un KO décrit, jamais une section qui s'arrête."""
    try:
        return fonction(ctx, dossier)
    except Exception as exc:
        return False, "exception du contrôle : %s : %s" % (type(exc).__name__, str(exc)[:300])


def sec_lota(ctx):
    par_id = dict(LOTA_CONTROLES)
    for ident, fonction in LOTA_CONTROLES:
        conforme, detail = lota_executer(fonction, ctx, ctx.scripts_dir)
        if conforme:
            ok("%s %s" % (ident, detail))
        else:
            ko(ident, "contrôle du lot A sur les scripts livrés", "conforme", detail)
    filtre = [f for f in os.environ.get("VF_GATES_MUTANTS", "").split(",") if f]
    for ident, motif, remplacement, controle, nom, marqueur in LOTA_MUTANTS:
        if filtre and not any(f in ident for f in filtre):
            continue
        dossier, raison = make_script_mutant(ctx, nom, marqueur, ident, motif, remplacement)
        if dossier is None:
            komut(ident, "mutant valide (texte distinct, bash -n, compilation du corps)", "mutant valide", raison)
            continue
        for autre in ("planning-hook.sh", "poser-verdict.sh", "deroger-gate.sh", "check-gates-alive.sh"):
            if not os.path.exists(os.path.join(dossier, autre)):
                shutil.copy(os.path.join(ctx.scripts_dir, autre), os.path.join(dossier, autre))
                os.chmod(os.path.join(dossier, autre), 0o755)
        ctrl = par_id[controle]
        original = lota_executer(ctrl, ctx, ctx.scripts_dir)
        temoin_o, temoin_m = controle_temoin(ctx, None), controle_temoin(ctx, dossier)
        mutant = lota_executer(ctrl, ctx, dossier)
        if not original[0]:
            komut(ident, "l'original passe %s" % controle, "conforme", original[1])
        elif temoin_o != temoin_m:
            komut(ident, "témoin (Write neutre d'un lab adhérent) inchangé sous le mutant", str(temoin_o), str(temoin_m))
        elif mutant[0]:
            komut(ident, "%s rougit sous le mutant" % controle, "rouge", "vert : " + mutant[1] + " (mutant non opposable)")
        else:
            okmut(ident, "%s rougit · attendu (original) : %s · obtenu (mutant) : %s · témoin inchangé" % (controle, original[1], mutant[1]))


def copie_de_scripts(ctx, dossier, noms, prefixe):
    """Dossier jetable portant les `noms` copiés de `dossier` (exécutables)."""
    d = ctx.unique(prefixe)
    os.makedirs(d, exist_ok=True)
    for nom in noms:
        shutil.copy(os.path.join(dossier, nom), os.path.join(d, nom))
        os.chmod(os.path.join(d, nom), 0o755)
    return d


def deny_de(rc, out, err, gate):
    """(vrai, détail) si un deny unique de `gate` (`[planning-core] <gate> :`) sans stderr, sinon (faux, détail)."""
    v = classer(rc, out)
    if v != "deny" or err:
        return False, "%s rc=%d stderr=%s stdout=%s" % (v, rc, court(err), court(out))
    raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
    return raison.startswith("[planning-core] %s :" % gate), raison[:120]


# --- LOT A, constat 1 (B1/H1) : un `.planning` imbriqué n'est jamais une racine de lab -----------------------------------
# Amendement de P45-D-01a (décision du manager vf-dev-manager, 2026-10-01) : un dossier `.planning` situé dans (ou sous)
# un composant `.planning` n'est JAMAIS une racine de lab ; on remonte. Quatre implémentations : `racine_lab` du hook,
# `vf_tight` de hooks.json (suite test-planning-hook-registered.sh), `racine_lab` de poser-verdict.sh, `racine_planning`
# du canary. Atteignable en deux Write (un fichier sous `<phase>/.planning/` suffit à créer le dossier), même avec G7 armé.
IMBRIQUES = ("a", "b", "c")
PHASE_IMB = ".planning/cycles/01-c/phases/01-p"


def lab_imbrique(ctx, variante):
    """Lab adhérent dont le planning porte un `.planning` imbriqué : a = `.planning/.planning`, b = `.planning/cycles/.planning`,
    c = `<phase>/.planning`."""
    lab = ctx.unique("lab-imbrique-" + variante)
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    phase = os.path.join(lab, ".planning", "cycles", "01-c", "phases", "01-p")
    ecrire(os.path.join(phase, "PLAN.md"), "---\necrit: livrables\n---\n")
    ecrire(os.path.join(lab, "livrables", "rapport.md"), "x\n")  # 46-01 : poser-verdict.sh refuse un livrable absent ou vide
    imbrique = {"a": os.path.join(lab, ".planning", ".planning"), "b": os.path.join(lab, ".planning", "cycles", ".planning"),
                "c": os.path.join(phase, ".planning")}[variante]
    os.makedirs(imbrique)
    return lab


def fonction_extraite(chemin_script, marqueur, nom):
    """Fonction `nom` du corps Python embarqué (marqueur du heredoc), exécutée seule dans un espace de noms jetable."""
    corps = corps_python(open(chemin_script, encoding="utf-8").read(), marqueur)
    for noeud in ast.parse(corps).body:
        if isinstance(noeud, ast.FunctionDef) and noeud.name == nom:
            ns = {"os": os, "re": re}
            exec(compile(ast.Module(body=[noeud], type_ignores=[]), chemin_script, "exec"), ns)
            return ns[nom]
    return None


@lota("R-IMB-01")
def controle_imbrique_hook(ctx, script):
    """Copie armée : un `.planning` imbriqué (a, b, c) ne fait jamais d'un dossier de planning ou de phase une racine non
    adhérente — Write d'un fichier généré (G6), d'un VERDICT.md (G5) et d'un PLAN.md sans cadrage (G1) : un deny du gate."""
    armee = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for variante in IMBRIQUES:
        lab = lab_imbrique(ctx, variante)
        for gate, rel in (("G6", ".planning/STATE.md"), ("G5", PHASE_IMB + "/VERDICT.md"), ("G1", PHASE_IMB + "/PLAN.md")):
            n += 1
            brut = payload("Write", entree_outil("Write", os.path.join(lab, rel)), lab)
            rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=armee)
            conforme, detail = deny_de(rc, out, err, gate)
            if not conforme:
                fautes.append("variante %s, %s sur %s : %s" % (variante, gate, rel, detail))
    return (not fautes), ("; ".join(fautes) if fautes else "%d refus de gate (G6, G5, G1 sur trois variantes de `.planning` imbriqué)" % n)


@lota("R-IMB-02")
def controle_imbrique_poser(ctx, script):
    """poser-verdict.sh : l'unité d'un lab adhérent dont le planning porte un `.planning` imbriqué (a, b, c) est posée (code 0),
    jamais jugée « lab non adhérent » (code 2)."""
    d = _dossier(ctx, script)
    fautes = []
    for variante in IMBRIQUES:
        lab = lab_imbrique(ctx, variante)
        rc, out, err = poser(ctx, d, lab, 1, unite=PHASE_IMB)
        if rc != 0 or not os.path.isfile(os.path.join(lab, PHASE_IMB, "VERDICT.md")):
            fautes.append("variante %s : rc=%d %s" % (variante, rc, court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "code 0 et VERDICT.md posé sur les trois variantes")


def canary_degrade(ctx, dossier, cwd_session):
    """Lance le check-gates-alive.sh de `dossier` (copié seul dans un projet jetable) sur un projet SANS planning-hook.sh : une
    session reconnue adhérente signale le mode dégradé (code 0, une ligne), une session jugée hors lab adhérent rend 3 en silence."""
    projet = ctx.unique("projet-canary-sans-hook")
    d = os.path.join(projet, ".claude", "scripts")
    os.makedirs(d)
    shutil.copy(os.path.join(dossier, "check-gates-alive.sh"), os.path.join(d, "check-gates-alive.sh"))
    reglage = os.path.join(ctx.unique("reglage-canary-imb"), "settings.json")
    reglage_cinq_evenements(reglage, ctx.cmd.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts'))
    p = subprocess.run(["bash", os.path.join(d, "check-gates-alive.sh"), "--settings=" + reglage],
                       input=json.dumps({"cwd": cwd_session}).encode("utf-8"), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env={"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": ctx.home, "CLAUDE_PROJECT_DIR": projet},
                       cwd=cwd_session, timeout=120)
    return p.returncode, p.stdout, p.stderr


@lota("R-IMB-03")
def controle_imbrique_canary(ctx, script):
    """Canary : une session dont le cwd est un `.planning` imbriqué (a, b, c) d'un lab adhérent est reconnue adhérente (le
    canary rejoue la commande, ici sans script : mode dégradé, code 0), jamais « hors lab adhérent » (code 3, rien rejoué)."""
    d = _dossier(ctx, script)
    fautes = []
    for variante in IMBRIQUES:
        lab = lab_imbrique(ctx, variante)
        cwd = {"a": os.path.join(lab, ".planning", ".planning"), "b": os.path.join(lab, ".planning", "cycles", ".planning"),
               "c": os.path.join(lab, PHASE_IMB, ".planning")}[variante]
        rc, out, err = canary_degrade(ctx, d, cwd)
        if rc != 0 or b"mode d\xc3\xa9grad\xc3\xa9" not in out:
            fautes.append("variante %s : rc=%d stdout=%s" % (variante, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "les trois variantes sont reconnues adhérentes (code 0, « mode dégradé »)")


@lota("R-IMB-04")
def controle_sous_planning(ctx, script):
    """`sous_planning` (hook, poser-verdict.sh, canary) : vrai pour un chemin qui porte un composant `.planning`, casse ignorée ;
    faux pour `planning`, `x.planning`, `.planningx` (jamais une sous-chaîne)."""
    d = _dossier(ctx, script)
    fautes = []
    for nom, marqueur in (("planning-hook.sh", "PY_PLANNING_HOOK_EOF"), ("poser-verdict.sh", "PY_POSER_VERDICT_EOF"),
                          ("check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF")):
        f = fonction_extraite(os.path.join(d, nom), marqueur, "sous_planning")
        if f is None:
            fautes.append("%s : sous_planning absente" % nom)
            continue
        for chemin, attendu in (("/a/.planning", True), ("/a/.PLANNING/b", True), ("/a/.Planning/b/c", True),
                                ("/a/b/.planning/cycles", True), ("/a/planning/b", False), ("/a/x.planning/b", False),
                                ("/a/.planningx/b", False), ("/a/b", False), ("/", False)):
            if f(chemin) is not attendu:
                fautes.append("%s : sous_planning(%r) = %r (attendu %r)" % (nom, chemin, f(chemin), attendu))
    return (not fautes), ("; ".join(fautes) if fautes else "composant `.planning` seul, casse ignorée, dans les trois scripts")


lota_mutant("IMB-HOOK", "# racine-imbriquee", 'if os.path.isdir(os.path.join(courant, ".planning")):  # racine-imbriquee', "R-IMB-01")
lota_mutant("IMB-POSER", "# racine-imbriquee", 'if os.path.isdir(os.path.join(courant, ".planning")):  # racine-imbriquee', "R-IMB-02",
            "poser-verdict.sh", "PY_POSER_VERDICT_EOF")
lota_mutant("IMB-CANARY", "# racine-imbriquee", 'if os.path.isdir(os.path.join(d, ".planning")):  # racine-imbriquee', "R-IMB-03",
            "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF")
lota_mutant("IMB-CASEFOLD", "# sous-planning-casse", 'return any(c == ".planning" for c in chemin.split(os.sep))  # sous-planning-casse', "R-IMB-04")


@lota("R-IMB-05")
def controle_imbrique_cas_canary(ctx, script):
    """Canary de session (cas G5-imbrique, lab synthétique à `.planning/` imbriqués) : sain (code 3, stdout vide) sur le hook livré ;
    un hook qui fait d'un `.planning` imbriqué une racine non adhérente fait signaler le canary (cas en échec)."""
    d = scripts_canary(ctx, _dossier(ctx, script), "observe", tel_quel=True)
    rc, out, err = lancer_canary_dossier(ctx, d)
    if rc != 3 or out != b"":
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    return True, "canary sain (code 3) : le cas G5-imbrique trouve sa ligne d'observation dans un lab à `.planning/` imbriqués"


lota_mutant("IMB-HOOK-CANARY", "# racine-imbriquee", 'if os.path.isdir(os.path.join(courant, ".planning")):  # racine-imbriquee', "R-IMB-05")


# --- LOT E, constat F1 (revue du lot D) : un `.planning` sous un composant `.claude` n'est jamais une racine de lab -----------
# Amendement de P45-D-01a (décision du manager vf-dev-manager, 2026-10-01, renversable) : sans lui, la chaîne Write de
# `.claude/scripts/package.json`, Write de `.claude/scripts/.planning/x.md`, Write de `.claude/scripts/planning-hook.sh` faisait de
# `.claude/scripts` une racine non adhérente : silence, tous gates armés. Exception mesurée : `.claude/worktrees/<nom>` (là où Claude Code
# pose les worktrees d'un lab) reste une racine possible, sans quoi tout lab travaillé dans un worktree serait jugé par son voisin.
# Quatre implémentations de la règle : `racine_lab` du hook, de poser-verdict.sh, `racine_planning` du canary, `vf_tight` de hooks.json.
# Lot F (M5) : la variante d (poche `.claude/worktrees/<nom>/.planning` créée DANS le lab) n'est jouée que par R-CLAUDE-01, hors de
# VARIANTES_CLAUDE : sous la limite (o), la poche est sa propre racine (non adhérente) ; R-CLAUDE-02 attendrait le lab, R-CLAUDE-03 une
# session adhérente, deux attendus qui ne valent pas pour une poche.
VARIANTES_CLAUDE = ("a", "b", "c")


def lab_claude(ctx, variante):
    """Lab adhérent dont `.claude` porte un `.planning` : a = `.claude/.planning`, b = `.claude/scripts/.planning`, c = lab posé sous
    `<x>/.claude/worktrees/wt` avec `.claude/scripts/.planning`, d = poche `.claude/worktrees/wt/.planning` créée dans un lab adhérent.
    Rend (lab, dossier du `.planning` créé)."""
    base = ctx.unique("lab-claude-" + variante)
    lab = os.path.join(base, ".claude", "worktrees", "wt") if variante == "c" else base
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    rel = {"a": (".claude", ".planning"), "b": (".claude", "scripts", ".planning"), "c": (".claude", "scripts", ".planning"),
           "d": (".claude", "worktrees", "wt", ".planning")}[variante]
    imbrique = os.path.join(lab, *rel)
    os.makedirs(imbrique)
    return lab, imbrique


def racines_extraites(chemin_script, marqueur, noms):
    """Fonctions `noms` du corps Python embarqué, exécutées ensemble dans un espace de noms jetable (rend l'espace de noms)."""
    corps = corps_python(open(chemin_script, encoding="utf-8").read(), marqueur)
    choisies = [n for n in ast.parse(corps).body if isinstance(n, ast.FunctionDef) and n.name in noms]
    ns = {"os": os, "re": re}
    exec(compile(ast.Module(body=choisies, type_ignores=[]), chemin_script, "exec"), ns)
    return ns


@lota("R-CLAUDE-01")
def controle_claude_hook(ctx, script):
    """Copie armée : un `.planning` sous `.claude` (a, b) ou sous `.claude/scripts` d'un lab posé sous `.claude/worktrees/<nom>` (c) ne
    fait jamais de ce dossier une racine non adhérente — Write du script du hook (chemin absolu, puis relatif depuis un cwd dans
    `.claude/scripts`) et d'un fichier généré : un deny G6 chacun. Variante d (lot F, M5) : poche `.claude/worktrees/wt/.planning` créée DANS
    le lab, sans `config.json` — trois deny G6 sur le script du hook du lab (chemin absolu ; absolu et relatif depuis une session ouverte dans
    la poche), deux silences sous la poche (script du hook du worktree, création d'un `.planning`)."""
    armee = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0
    for variante in VARIANTES_CLAUDE:
        lab, imbrique = lab_claude(ctx, variante)
        scripts = os.path.join(lab, ".claude", "scripts")
        os.makedirs(scripts, exist_ok=True)
        for nom, cible, cwd in (("script absolu", os.path.join(scripts, "planning-hook.sh"), lab),
                                ("script relatif", "planning-hook.sh", scripts),
                                ("fichier généré", os.path.join(lab, ".planning", "STATE.md"), lab)):
            n += 1
            brut = payload("Write", entree_outil("Write", cible), cwd)
            rc, out, err = ctx.lancer("A", brut, cwd=cwd, dossier=armee)
            conforme, detail = deny_de(rc, out, err, "G6")
            if not conforme:
                fautes.append("variante %s, %s : %s" % (variante, nom, detail))
    # Variante d (lot F, M5) : poche `<lab>/.claude/worktrees/wt/.planning` créée DANS le lab (sans config.json). Une session ouverte dans la
    # poche écrit le script du hook du LAB : la racine se dérive du chemin écrit, jamais du cwd de la session (mutant CLAUDE-POCHE).
    lab, imbrique = lab_claude(ctx, "d")
    poche = os.path.dirname(imbrique)
    scripts = os.path.join(lab, ".claude", "scripts")
    os.makedirs(scripts, exist_ok=True)
    os.makedirs(os.path.join(poche, "sub"), exist_ok=True)
    os.makedirs(os.path.join(poche, ".claude", "scripts"), exist_ok=True)
    script_lab = os.path.join(scripts, "planning-hook.sh")
    refus_d = (("script du lab, absolu", script_lab, lab),
               ("script du lab, absolu depuis la poche", script_lab, poche),
               ("script du lab, relatif depuis la poche", os.path.join("..", "..", "scripts", "planning-hook.sh"), poche))
    silences_d = (("script du worktree", os.path.join(poche, ".claude", "scripts", "planning-hook.sh"), poche),
                  ("création d'un .planning sous la poche", os.path.join(poche, "sub", ".planning", "x.md"), poche))
    for nom, cible, cwd in refus_d:
        brut = payload("Write", entree_outil("Write", cible), cwd)
        rc, out, err = ctx.lancer("A", brut, cwd=cwd, dossier=armee)
        conforme, detail = deny_de(rc, out, err, "G6")
        if not conforme:
            fautes.append("variante d, %s : %s" % (nom, detail))
    for nom, cible, cwd in silences_d:
        brut = payload("Write", entree_outil("Write", cible), cwd)
        rc, out, err = ctx.lancer("A", brut, cwd=cwd, dossier=armee)
        if classer(rc, out) != "silence" or err:
            fautes.append("variante d, %s : %s rc=%d stderr=%s stdout=%s" % (nom, classer(rc, out), rc, court(err), court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else (
        "%d refus G6 (script du hook absolu et relatif, fichier généré, trois variantes de `.planning` sous `.claude`)" % n
        + " ; variante d (poche `.claude/worktrees/<nom>/.planning` créée dans le lab) : %d refus G6 sur le script du hook du lab (chemin absolu ; "
        "absolu et relatif depuis une session ouverte dans la poche), %d silences sous la poche (script du hook du worktree, "
        "création d'un `.planning`)" % (len(refus_d), len(silences_d))))


@lota("R-CLAUDE-02")
def controle_claude_poser(ctx, script):
    """poser-verdict.sh : `racine_lab` d'un chemin sous `.claude/scripts` (a, b) ou sous le `.claude/scripts` d'un worktree (c) rend le lab,
    jamais le dossier qui porte le `.planning` créé sous `.claude`."""
    ns = racines_extraites(os.path.join(_dossier(ctx, script), "poser-verdict.sh"), "PY_POSER_VERDICT_EOF",
                           ("_partie_existante", "sous_planning", "sous_claude", "racine_lab"))
    fautes = []
    for variante in VARIANTES_CLAUDE:
        lab, imbrique = lab_claude(ctx, variante)
        obtenu = ns["racine_lab"](os.path.realpath(os.path.dirname(imbrique)) + "/x")
        if obtenu != os.path.realpath(lab):
            fautes.append("variante %s : racine %r (attendu %r)" % (variante, obtenu, os.path.realpath(lab)))
    return (not fautes), ("; ".join(fautes) if fautes else "la racine reste le lab sur les trois variantes")


@lota("R-CLAUDE-03")
def controle_claude_canary(ctx, script):
    """Canary : une session dont le cwd est `.claude/scripts` (a : `.claude`) d'un lab adhérent portant un `.planning` à cet endroit est
    reconnue adhérente (code 0, « mode dégradé »), jamais « hors lab adhérent » (code 3)."""
    d = _dossier(ctx, script)
    fautes = []
    for variante in VARIANTES_CLAUDE:
        lab, imbrique = lab_claude(ctx, variante)
        rc, out, err = canary_degrade(ctx, d, os.path.dirname(imbrique))
        if rc != 0 or b"mode d\xc3\xa9grad\xc3\xa9" not in out:
            fautes.append("variante %s : rc=%d stdout=%s" % (variante, rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "les trois variantes sont reconnues adhérentes (code 0, « mode dégradé »)")


@lota("R-CLAUDE-04")
def controle_sous_claude(ctx, script):
    """`sous_claude` (hook, poser-verdict.sh, canary) : vrai pour un chemin dont le dernier composant `.claude` (casse ignorée) n'est pas
    suivi de `worktrees/<nom>` ; faux pour `.claudex`, `x.claude`, un chemin sans `.claude`, `.claude/worktrees/<nom>[/...]`."""
    d = _dossier(ctx, script)
    fautes = []
    for nom, marqueur in (("planning-hook.sh", "PY_PLANNING_HOOK_EOF"), ("poser-verdict.sh", "PY_POSER_VERDICT_EOF"),
                          ("check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF")):
        f = fonction_extraite(os.path.join(d, nom), marqueur, "sous_claude")
        if f is None:
            fautes.append("%s : sous_claude absente" % nom)
            continue
        for chemin, attendu in (("/a/.claude", True), ("/a/.CLAUDE", True), ("/a/.claude/scripts", True), ("/a/.Claude/Scripts/b", True),
                                ("/a/.claude/worktrees", True), ("/a/.claude/worktrees/", True),
                                ("/a/.claude/worktrees/wt/.claude/scripts", True), ("/a/.claude/worktrees/wt/.claude", True),
                                ("/a/.claude/worktrees/wt", False), ("/a/.CLAUDE/Worktrees/wt/b", False),
                                ("/a/.claudex/b", False), ("/a/x.claude/b", False), ("/a/b", False), ("/", False)):
            if f(chemin) is not attendu:
                fautes.append("%s : sous_claude(%r) = %r (attendu %r)" % (nom, chemin, f(chemin), attendu))
    return (not fautes), ("; ".join(fautes) if fautes else "dernier composant `.claude`, casse ignorée, exception `worktrees/<nom>`, dans les trois scripts")


_ANCIEN_HOOK = 'if os.path.isdir(os.path.join(courant, ".planning")) and not sous_planning(courant):  # racine-imbriquee racine-claude'
lota_mutant("CLAUDE-HOOK", " racine-claude", _ANCIEN_HOOK, "R-CLAUDE-01")
lota_mutant("CLAUDE-POSER", " racine-claude", _ANCIEN_HOOK, "R-CLAUDE-02", "poser-verdict.sh", "PY_POSER_VERDICT_EOF")
lota_mutant("CLAUDE-CANARY", " racine-claude", 'if os.path.isdir(os.path.join(d, ".planning")) and not sous_planning(d):  # racine-imbriquee racine-claude',
            "R-CLAUDE-03", "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF")
lota_mutant("CLAUDE-WORKTREES", "# sous-claude-worktrees", 'return True  # sous-claude-worktrees', "R-CLAUDE-01")
lota_mutant("CLAUDE-DERNIER", "# sous-claude-dernier", 'reste = [c for c in composants[places[0] + 1:] if c]  # sous-claude-dernier', "R-CLAUDE-01")
# Lot F (M5) : la racine se dérive du chemin écrit, jamais du cwd de la session (une session ouverte dans la poche jugerait sinon le script du lab par la poche).
lota_mutant("CLAUDE-POCHE", "# racine-depart",
            'depart = cwd if cwd is not None else (ecrit if ecrit is not None else os.getcwd())  # racine-depart', "R-CLAUDE-01")
lota_mutant("CLAUDE-CASSE", "# sous-claude-casse", 'places = [i for i, c in enumerate(composants) if c == ".claude"]  # sous-claude-casse', "R-CLAUDE-04")
lota_mutant("CLAUDE-CASSE-POSER", "# sous-claude-casse", 'places = [i for i, c in enumerate(composants) if c == ".claude"]  # sous-claude-casse', "R-CLAUDE-04",
            "poser-verdict.sh", "PY_POSER_VERDICT_EOF")
lota_mutant("CLAUDE-CASSE-CANARY", "# sous-claude-casse", 'places = [i for i, c in enumerate(composants) if c == ".claude"]  # sous-claude-casse', "R-CLAUDE-04",
            "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF")


# --- LOT A, constat 4 (revue m2) : une dérogation n'est consommée que si la décision FINALE est un passage grâce à elle ---------
# Avant : `decider` consommait la dérogation de G6 verdict par verdict, alors que ROLE refusait la même écriture : la dérogation était
# brûlée pour rien. Décision du manager vf-dev-manager, 2026-10-01 : on consomme seulement quand aucun verdict armé ne reste refusé.
@lota("R-DEROG-09")
def controle_derog_non_brulee(ctx, script):
    """Copie armée, juge-test écrit `.planning/STATE.md` (G6 couvert par une dérogation, ROLE non couvert) : un deny ROLE, la
    dérogation G6 n'est PAS consommée ; le même Write au fil principal (G6 seul) passe, cité, et la consomme alors."""
    lab = lab_frais(ctx, "role-adherent")
    journal = journal_derog(lab)
    if os.path.exists(journal):
        os.remove(journal)
    rc, _o, err = deroger(ctx, lab, None, gate="G6", chemins=(".planning/STATE.md",))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    cible = os.path.join(lab, ".planning", "STATE.md")
    brut = payload("Write", entree_outil("Write", cible), lab, agent_type="juge-test")
    rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=hook)
    conforme, detail = deny_de(rc, out, err, "ROLE")
    brulees = [l for l in lignes_de(journal) if "  consommee  " in l]
    fautes = []
    if not conforme:
        fautes.append("Write du juge : " + detail)
    if brulees:
        fautes.append("dérogation G6 consommée alors que ROLE refuse : %s" % brulees)
    if "G6" in (json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"] if classer(rc, out) == "deny" else ""):
        fautes.append("la raison cite G6, couvert par la dérogation")
    rc, out, err = ctx.lancer("A", payload("Write", entree_outil("Write", cible), lab), cwd=lab, dossier=hook)
    consommees = [l for l in lignes_de(journal) if "  consommee  id=1  gate=G6  " in l]
    if classer(rc, out) != "avertit" or err or "#1" not in contexte_de(out) or len(consommees) != 1:
        fautes.append("Write au fil principal : %s, %d consommation(s) de #1 (attendu avertit cité + 1)" % (classer(rc, out), len(consommees)))
    return (not fautes), ("; ".join(fautes) if fautes else "juge : deny ROLE seul, dérogation G6 intacte ; fil principal : passage cité, dérogation consommée")


lota_mutant("DEROG-GLOBALE", "# decider-global",
            "if False:  # decider-global", "R-DEROG-09")


# --- LOT A, constats 5, 6, 7 (revue m3, m4 ; audit H4, B3) : poser-verdict.sh -----------------------------------------------------
# Décisions du manager vf-dev-manager, 2026-10-01 (renversables).
def copie_modifiee(ctx, dossier, nom, remplacements, prefixe):
    """Dossier jetable portant `nom` copié de `dossier` après les `remplacements` [(motif fixe, texte)] (chaque motif exactement une
    fois) ; `bash -n` doit passer. Sert à injecter un délai dans un script, jamais à muter un garde."""
    texte = open(os.path.join(dossier, nom), encoding="utf-8").read()
    for motif, remplacement in remplacements:
        if texte.count(motif) != 1:
            raise RuntimeError("motif attendu une fois dans %s : %r (%d)" % (nom, motif, texte.count(motif)))
        texte = texte.replace(motif, remplacement)
    d = ctx.unique(prefixe)
    os.makedirs(d, exist_ok=True)
    chemin = os.path.join(d, nom)
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(texte)
    os.chmod(chemin, 0o755)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise RuntimeError("bash -n échoue sur la copie modifiée : " + court(p.stderr))
    return d


SEPARATEURS_VERDICT = (("\r", "CR"), ("\x0b", "VT"), ("\x0c", "FF"), ("\x1c", "FS"), ("\x1d", "GS"), ("\x1e", "RS"), ("\x85", "NEL"),
                       ("\u2028", "LS"), ("\u2029", "PS"), ("\x01", "SOH"), ("\t", "TAB"))


def verdicts_ecrits(lab):
    return [os.path.join(dp, f) for dp, _dn, fs in os.walk(os.path.join(lab, ".planning")) for f in fs if f == "VERDICT.md" or f.startswith(".VERDICT.")]


@lota("R-VERDICT-06")
def controle_verdict_controles(ctx, script):
    """H4 (audit) : un caractère de contrôle ou un séparateur de ligne (CR, VT, FF, FS, GS, RS, NEL, U+2028, U+2029, tout Cc) dans
    --juge, --score ou --constat (critère) est refusé (64) et rien n'est écrit : le moteur lit en newlines universels, un CR faisait
    lire « close » un verdict en échec ou forgeait `hash` et `tentative`. Un argument propre passe (témoin)."""
    d = _dossier(ctx, script)
    fautes, n = [], 0
    for caractere, nom in SEPARATEURS_VERDICT:
        for option in ("juge", "score", "constat"):
            lab = lab_frais(ctx)
            kw = {"juge": "j", "score": "8/10", "constats": ("critere-a::passé",)}
            if option == "juge":
                kw["juge"] = "x" + caractere + "y"
            elif option == "score":
                kw["score"] = "8" + caractere + "10"
            else:
                kw["constats"] = ("crit" + caractere + "ere::passé",)
            n += 1
            rc, _o, err = poser(ctx, d, lab, 1, **kw)
            if rc != 64 or verdicts_ecrits(lab):
                fautes.append("%s dans --%s : rc=%d, écrit %s" % (nom, option, rc, [os.path.basename(e) for e in verdicts_ecrits(lab)]))
    # forge réelle : un CR dans --score ajoute une ligne `tentative: 9` pour un lecteur à newlines universels
    lab = lab_frais(ctx)
    rc, _o, err = poser(ctx, d, lab, 1, score='8/10\rtentative: 9')
    if rc != 64 or verdicts_ecrits(lab):
        fautes.append("forge de tentative par CR : rc=%d" % rc)
    lab = lab_frais(ctx)
    rc, _o, err = poser(ctx, d, lab, 1)
    if rc != 0:
        fautes.append("témoin propre refusé : rc=%d %s" % (rc, court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "%d arguments à caractère de contrôle ou séparateur refusés (64), rien d'écrit ; la forge par CR refusée ; témoin propre accepté" % n)


@lota("R-VERDICT-07")
def controle_verdict_forme_unite(ctx, script):
    """m3 (revue) : --unite doit avoir la forme d'une unité de plan ou de phase du modèle (même règle que `unite_de_plan` : cinq ou sept
    composants, `cycles`, `phases`, `plans`, noms d'unité conformes). Un dossier du cycle, de `phases/`, de `plans/` ou un nom
    d'unité invalide, même avec un PLAN.md, est refusé (64) ; les deux formes valides passent."""
    d = _dossier(ctx, script)
    fautes = []
    invalides = (".planning/cycles/01-c", ".planning/cycles/01-c/phases", ".planning/cycles/01-c/phases/01-p/plans",
                 ".planning/cycles/01-c/phases/x-p", ".planning/cycles/01-c/phases/01-p/plans/zz",
                 ".planning/cycles/01-c/phases/01-p/foo/01-a", ".planning/cycles/01-c/foo/01-p", ".planning/notes/01-c/phases/01-p")
    for unite in invalides:
        lab = lab_frais(ctx)
        ecrire(os.path.join(lab, unite, "PLAN.md"), "---\necrit: livrables/rapport.md\n---\n")
        rc, _o, err = poser(ctx, d, lab, 1, unite=unite)
        if rc != 64 or verdicts_ecrits(lab):
            fautes.append("%s : rc=%d (attendu 64), écrit %s" % (unite, rc, [os.path.relpath(e, lab) for e in verdicts_ecrits(lab)]))
    for unite in (".planning/cycles/01-c/phases/01-p", ".planning/cycles/01-c/phases/01-p/plans/01-a"):
        lab = lab_frais(ctx)
        ecrire(os.path.join(lab, unite, "PLAN.md"), "---\necrit: livrables/rapport.md\n---\n")
        rc, _o, err = poser(ctx, d, lab, 1, unite=unite)
        if rc != 0 or not os.path.isfile(os.path.join(lab, unite, "VERDICT.md")):
            fautes.append("unité valide %s : rc=%d %s" % (unite, rc, court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "%d unités hors forme refusées (64), les formes de phase et de plan acceptées" % len(invalides))


@lota("R-VERDICT-08")
def controle_verdict_verrou(ctx, script):
    """m4 + B3 : deux poses simultanées de la tentative 1 sur la même unité (un délai est injecté entre la lecture de la tentative et
    l'écriture, dans une COPIE du script) : sous le verrou (`fcntl.flock` sur le PLAN.md voisin, jamais suivi s'il est un lien) l'une
    est écrite, l'autre refusée (64 : la tentative 1 n'est plus la bonne) ; le VERDICT.md final porte la tentative 1."""
    d = copie_modifiee(ctx, _dossier(ctx, script), "poser-verdict.sh",
                       [("    controle_tentative(tentative, ancienne)\n",
                         "    controle_tentative(tentative, ancienne)\n    import time\n    time.sleep(0.7)\n")], "poser-avec-delai")
    lab = lab_frais(ctx)
    args = ["bash", os.path.join(d, "poser-verdict.sh"), "--unite=" + os.path.join(lab, UNITE), "--juge=j", "--tentative=1",
            "--score=s", "--constat=c::passé"]
    procs = [subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env()) for _ in range(2)]
    codes = sorted(p.wait(timeout=60) for p in procs)
    for p in procs:
        p.stdout.close()
        p.stderr.close()
    fautes = []
    if codes != [0, 64]:
        fautes.append("codes %s (attendu [0, 64] : une pose, un refus de tentative)" % codes)
    chemin = os.path.join(lab, UNITE, "VERDICT.md")
    if not os.path.isfile(chemin) or b"tentative: 1" not in octets(chemin):
        fautes.append("VERDICT.md final absent ou sans tentative 1")
    restes = [n for n in os.listdir(os.path.join(lab, UNITE)) if n.startswith(".")]
    if restes:
        fautes.append("fichier temporaire laissé : %s" % restes)
    # un PLAN.md en lien symbolique n'est jamais suivi : refus, rien d'écrit
    lab2 = lab_frais(ctx)
    plan2 = os.path.join(lab2, UNITE, "PLAN.md")
    cible = os.path.join(lab2, "livrables", "plan-reel.md")
    ecrire(cible, "---\necrit: a\n---\n")
    os.remove(plan2)
    os.symlink(cible, plan2)
    rc, _o, err = poser(ctx, _dossier(ctx, script), lab2, 1)
    if rc == 0 or verdicts_ecrits(lab2):
        fautes.append("PLAN.md en lien : rc=%d, écrit %s" % (rc, verdicts_ecrits(lab2)))
    return (not fautes), ("; ".join(fautes) if fautes else "deux poses simultanées : codes [0, 64], tentative 1, aucun temporaire ; PLAN.md en lien refusé")


@lota("R-VERDICT-09")
def controle_verdict_utf8(ctx, script):
    """Un argv non UTF-8 (octet 0xFF) est refusé proprement (64, message, aucune trace Python) et rien n'est écrit."""
    d = _dossier(ctx, script)
    lab = lab_frais(ctx)
    argv = [b"bash", os.path.join(d, "poser-verdict.sh").encode("utf-8"), b"--unite=" + os.path.join(lab, UNITE).encode("utf-8"),
            b"--juge=j\xff", b"--tentative=1", b"--score=s", b"--constat=c::pass\xc3\xa9"]
    p = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), timeout=60)
    if p.returncode != 64 or b"Traceback" in p.stderr or verdicts_ecrits(lab):
        return False, "rc=%d stderr=%s écrit=%s" % (p.returncode, court(p.stderr), verdicts_ecrits(lab))
    return True, "argv non UTF-8 : code 64, message, aucune trace, rien d'écrit"


lota_mutant("VERDICT-CONTROLES", "# verdict-controles", "pass  # verdict-controles", "R-VERDICT-06", "poser-verdict.sh", "PY_POSER_VERDICT_EOF")
lota_mutant("VERDICT-FORME-UNITE", "# verdict-forme-unite", "pass  # verdict-forme-unite", "R-VERDICT-07", "poser-verdict.sh", "PY_POSER_VERDICT_EOF")
lota_mutant("VERDICT-VERROU", "# verdict-verrou", "verrou = None  # verdict-verrou", "R-VERDICT-08", "poser-verdict.sh", "PY_POSER_VERDICT_EOF")
lota_mutant("VERDICT-UTF8", "# verdict-utf8", "pass  # verdict-utf8", "R-VERDICT-09", "poser-verdict.sh", "PY_POSER_VERDICT_EOF")


# --- LOT A, constat 8 (audit B3) : deroger-gate.sh n'élargit jamais les droits d'un journal et refuse un argv non UTF-8 ------------
# Décision du manager vf-dev-manager, 2026-10-01, renversable : `fchmod 0644` élargissait un journal 0600 existant.
@lota("R-DEROG-10")
def controle_derog_droits_utf8(ctx, script):
    """Un journal existant 0600 reste 0600 après une dérogation (jamais élargi) ; un journal créé par la commande est 0644 ; un argv non
    UTF-8 (octet 0xFF dans --raison) est refusé proprement (64, message, aucune trace Python) et le journal reste intact."""
    d = _dossier(ctx, script)
    fautes = []
    lab = lab_frais(ctx)
    journal = journal_derog(lab)
    if os.path.exists(journal):
        os.remove(journal)
    fd = os.open(journal, os.O_WRONLY | os.O_CREAT, 0o600)
    os.close(fd)
    os.chmod(journal, 0o600)
    rc, _o, err = deroger(ctx, lab, d, gate="G6", chemins=(".planning/STATE.md",))
    mode = stat.S_IMODE(os.stat(journal).st_mode)
    if rc != 0 or mode != 0o600:
        fautes.append("journal 0600 existant : rc=%d, droits %o (attendu 600)" % (rc, mode))
    lab2 = lab_frais(ctx)
    journal2 = journal_derog(lab2)
    if os.path.exists(journal2):
        os.remove(journal2)
    rc, _o, err = deroger(ctx, lab2, d, gate="G6", chemins=(".planning/STATE.md",))
    mode2 = stat.S_IMODE(os.stat(journal2).st_mode) if os.path.exists(journal2) else None
    if rc != 0 or mode2 != 0o644:
        fautes.append("journal créé : rc=%d, droits %s (attendu 644)" % (rc, oct(mode2) if mode2 is not None else None))
    lab3 = lab_frais(ctx)
    journal3 = journal_derog(lab3)
    if os.path.exists(journal3):
        os.remove(journal3)
    argv = [b"bash", os.path.join(d, "deroger-gate.sh").encode("utf-8"), b"--lab=" + lab3.encode("utf-8"), b"--gate=G6",
            b"--chemin=.planning/STATE.md", b"--qui=willy", b"--canal=AskUserQuestion session principale", b"--date=2026-09-30",
            b"--raison=cas de test \xff"]
    p = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), timeout=60)
    if p.returncode != 64 or b"Traceback" in p.stderr or os.path.exists(journal3):
        fautes.append("argv non UTF-8 : rc=%d stderr=%s journal créé=%s" % (p.returncode, court(p.stderr), os.path.exists(journal3)))
    return (not fautes), ("; ".join(fautes) if fautes else "journal 0600 conservé, journal créé 0644, argv non UTF-8 refusé (64, aucune trace, aucun journal)")


lota_mutant("DEROG-FCHMOD", "# derog-fchmod", 'if hasattr(os, "fchmod"):  # derog-fchmod', "R-DEROG-10", "deroger-gate.sh", "PY_DEROGER_GATE_EOF")
lota_mutant("DEROG-UTF8", "# derog-utf8", "pass  # derog-utf8", "R-DEROG-10", "deroger-gate.sh", "PY_DEROGER_GATE_EOF")


# --- LOT A, constat 2 (H2) : le parseur de définitions d'agent est linéaire, borné, et le cœur se borne lui-même ---------------------
# Décisions du manager vf-dev-manager, 2026-10-01 (renversables). L'expression `^\s+-\s+(.+?)(\s+#.*)?$` était quadratique : 60 Ko
# d'espaces dans une définition donnaient plus de 20 s, un fail-open ; le Python orphelin survivait au kill et le fichier de
# transport gardait le payload sous SIGKILL.
ANCIENNE_PUCE = re.compile(r"^\s+-\s+(.+?)(\s+#.*)?$")
ANCIEN_FRONTMATTER = '''
def ancien_frontmatter_agent(texte):
    lignes = texte.split("\\n")
    if not lignes or lignes[0].strip() != "---":
        return None
    fm, i, cle = {}, 1, None
    while i < len(lignes):
        ligne = lignes[i]
        if ligne.strip() == "---":
            return fm
        m = _CLE_AGENT_RE.match(ligne)
        if m:
            cle = m.group(1)
            val = m.group(2).strip()
            if val.startswith("[") and val.endswith("]"):
                fm[cle] = [x.strip().strip(chr(34)).strip(chr(39)) for x in val[1:-1].split(",") if x.strip()]
            elif val == "" or val == ">" or val == "|":
                fm[cle] = "" if val == "" else val
            else:
                if len(val) >= 2 and val[0] == val[-1] and val[0] in (chr(34), chr(39)):
                    val = val[1:-1]
                fm[cle] = val
        elif cle is not None:
            item = re.match(r"^\\s+-\\s+(.+?)(\\s+#.*)?$", ligne)
            if item and isinstance(fm.get(cle), list):
                fm[cle].append(item.group(1).strip().strip(chr(34)).strip(chr(39)))
            elif item and fm.get(cle) == "":
                fm[cle] = [item.group(1).strip().strip(chr(34)).strip(chr(39))]
            elif ligne.startswith("  ") and isinstance(fm.get(cle), str):
                fm[cle] = (fm[cle] + " " + ligne.strip()).strip()
        i += 1
    return None
'''


def alphabet_complet(alphabet, longueur_max):
    chaines = [""]
    courant = [""]
    for _ in range(longueur_max):
        courant = [c + a for c in courant for a in alphabet]
        chaines.extend(courant)
    return chaines


@lota("R-DEFS-01")
def controle_defs_equivalence(ctx, script):
    """`puce_agent` et `frontmatter_agent` du hook rendent EXACTEMENT ce que rendaient l'ancienne expression et l'ancien parseur
    quadratique : exhaustif sur de petits alphabets (blancs Unicode compris), puis aléatoire sur des frontmatters entiers."""
    import random
    ns = charger_module(os.path.join(_dossier(ctx, script), "planning-hook.sh"))
    puce, front = ns.get("puce_agent"), ns.get("frontmatter_agent")
    if puce is None:
        return False, "puce_agent absente du hook"
    ancien = {"re": re, "_CLE_AGENT_RE": ns["_CLE_AGENT_RE"]}
    exec(ANCIEN_FRONTMATTER, ancien)
    fautes, n = [], 0
    for ligne in alphabet_complet((" ", "-", "#", "x", " ", "\t"), 6):
        m, p = ANCIENNE_PUCE.match(ligne), puce(ligne)
        n += 1
        if (m is None) != (p is None) or (m is not None and m.group(1) != p.group(1)):
            fautes.append("puce %r : ancien %r, nouveau %r" % (ligne, m.group(1) if m else None, p.group(1) if p else None))
            if len(fautes) > 5:
                break
    hasard = random.Random(4501)
    morceaux = ("---", "name: x", "tools:", "tools: a, b", "tools: [a, b]", "description: >", "  - a", "  -  b  # c", "  - ", "  -", "  suite", "   ",
                "  ", "x: ' y '", "  - '  q  '", "  # note", "\tzz", "- n", "disallowedTools:", "  - Write", "key: ", "  text  ")
    for _ in range(2500):
        corps = [hasard.choice(morceaux) for _ in range(hasard.randint(1, 9))]
        texte = "\n".join(["---"] + corps + hasard.choice((["---", "tail"], ["---"], [])))
        n += 1
        a, b = ancien["ancien_frontmatter_agent"](texte), front(texte)
        if a != b:
            fautes.append("frontmatter %r : ancien %r, nouveau %r" % (texte, a, b))
            if len(fautes) > 5:
                break
    return (not fautes), ("; ".join(fautes) if fautes else "%d lignes et frontmatters identiques à l'ancien parseur (alphabets de six symboles jusqu'à six caractères, blancs Unicode, 2500 frontmatters aléatoires)" % n)


def definition_piegee(lab, nom, ligne):
    """Écrit `<lab>/.claude/agents/<nom>.md` : un frontmatter dont `tools:` porte la puce `ligne`."""
    ecrire(os.path.join(lab, ".claude", "agents", nom + ".md"),
           "---\nname: %s\ndescription: définition piégée\ntools:\n%s\ndisallowedTools: Write\n---\nCorps.\n" % (nom, ligne))


@lota("R-DEFS-02")
def controle_defs_piegee(ctx, script):
    """Une définition piégée (trente puces de 32 000 espaces, soit 960 Ko sous la borne de lecture de 1 Mio : environ 40 s avec l'ancienne
    expression quadratique, cinq fois l'échéance interne de 8 s ; trois puces de 30 000 espaces ne coûtaient que 3,5 s et un coureur
    rapide les passait sous 2 s : le mutant survivait selon la vitesse de la machine, il est désormais coupé par l'échéance) est tranchée en moins de 2 s ; une
    définition hors des bornes (ligne de 40 000 caractères, 1,2 Mo) est INDÉTERMINÉE : jamais un refus de rôle, jamais un délai ;
    sous un lab non adhérent, stdout d'octet vide."""
    armee = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = ctx.unique("lab-piege")
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    definition_piegee(lab, "trap", "\n".join("  - x" + " " * 32000 for _ in range(30)))
    definition_piegee(lab, "ligne-longue", "  - x" + " " * 40000)
    ecrire(os.path.join(lab, ".claude", "agents", "gros.md"), "---\nname: gros\ntools: Read\n---\n" + ("x" * 1200000) + "\n")
    dev = ctx.unique("lab-piege-dev")
    ecrire(os.path.join(dev, ".planning", "config.json"), '{"planning_version": "2.0"}')
    definition_piegee(dev, "trap", "\n".join("  - x" + " " * 32000 for _ in range(30)))
    fautes = []
    for agent in ("trap", "ligne-longue", "gros"):
        brut = payload("Write", entree_outil("Write", os.path.join(lab, "livrables", "x.md")), lab, agent_type=agent)
        debut = time.perf_counter()
        rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=armee)
        duree = time.perf_counter() - debut
        v = verdict_role(rc, out, err)
        if v != "passage" or duree >= 2.0:
            fautes.append("%s : %s en %.2f s (attendu passage en moins de 2 s)" % (agent, v, duree))
    brut = payload("Write", entree_outil("Write", os.path.join(dev, "livrables", "x.md")), dev, agent_type="trap")
    debut = time.perf_counter()
    rc, out, err = ctx.lancer("A", brut, cwd=dev, dossier=armee)
    if rc != 0 or out != b"" or err or time.perf_counter() - debut >= 2.0:
        fautes.append("lab dev : rc=%d stdout=%s" % (rc, court(out)))
    return (not fautes), ("; ".join(fautes) if fautes else "définition piégée tranchée en moins de 2 s, définitions hors bornes indéterminées (passage), lab dev silencieux")


def echeance_copie(ctx, script, delai, injection, prefixe, avant_lecture=False):
    """Copie du hook dont ECHEANCE_COEUR_S vaut `delai` et qui exécute `injection` (une instruction Python sur UNE ligne) soit avant la
    lecture du payload, soit juste avant l'évaluation des gates."""
    remplacements = [("ECHEANCE_COEUR_S = 8.0", "ECHEANCE_COEUR_S = %s" % delai)]
    if avant_lecture:
        remplacements.append(("payload = lire_payload(sys.argv[1])  # phase-a", injection + "; payload = lire_payload(sys.argv[1])  # phase-a"))
    else:
        remplacements.append(("resultats = evaluer_gates(contexte)  # phase-b", injection + "; resultats = evaluer_gates(contexte)  # phase-b"))
    return copie_modifiee(ctx, _dossier(ctx, script), "planning-hook.sh", remplacements, prefixe)


def lab_adherent_simple(ctx, prefixe):
    lab = ctx.unique(prefixe)
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    return lab


@lota("R-DEFS-03")
def controle_defs_echeance(ctx, script):
    """Le dépassement SIMULÉ de l'échéance interne (délai ramené à 0,8 s, un sommeil de 6 s injecté avant les gates) FERME : le cœur sort
    sur 73 sans rien imprimer, la commande enregistrée refuse l'écriture dans un lab adhérent (raison du fail-closed) et se tait dans
    un lab dev, en moins de 4 s."""
    copie = echeance_copie(ctx, script, "0.8", "import time; time.sleep(6)", "hook-echeance")
    fautes = []
    adh, dev = lab_adherent_simple(ctx, "lab-echeance"), ctx.unique("lab-echeance-dev")
    ecrire(os.path.join(dev, ".planning", "config.json"), '{"planning_version": "2.0"}')
    for etiquette, lab, attendu in (("lab adhérent", adh, "deny"), ("lab dev", dev, "silence")):
        brut = payload("Write", entree_outil("Write", os.path.join(lab, ".planning", "notes.md")), lab)
        debut = time.perf_counter()
        rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=copie)
        duree = time.perf_counter() - debut
        v = classer(rc, out)
        if v != attendu or duree >= 4.0 or (attendu == "deny" and b"hook central indisponible" not in out):
            fautes.append("%s : %s en %.2f s (attendu %s en moins de 4 s)" % (etiquette, v, duree, attendu))
    brut = payload("Write", entree_outil("Write", os.path.join(adh, ".planning", "notes.md")), adh)
    p = subprocess.run(["bash", os.path.join(copie, "planning-hook.sh")], input=brut, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env(), cwd=adh, timeout=30)
    if p.returncode != 73 or p.stdout != b"":
        fautes.append("lanceur seul : rc=%d stdout=%s (attendu 73 et rien)" % (p.returncode, court(p.stdout)))
    return (not fautes), ("; ".join(fautes) if fautes else "échéance dépassée : code 73 sans sortie, deny du fail-closed dans un lab adhérent, silence dans un lab dev")


def vivant(pid):
    """Vrai si le processus `pid` existe et n'est pas un zombie."""
    p = subprocess.run(["ps", "-o", "stat=", "-p", str(pid)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    etat = p.stdout.decode("utf-8", "replace").strip()
    return etat != "" and not etat.startswith("Z")


def lancer_endormi(ctx, copie, lab, tmpdir, fichier_pid):
    """Lance le hook `copie` (qui écrit son pid dans `fichier_pid` puis dort) sur un payload de lab adhérent ; rend (Popen, pid du Python
    ou None)."""
    brut = payload("Write", entree_outil("Write", os.path.join(lab, ".planning", "notes.md")), lab)
    env = ctx.env({"TMPDIR": tmpdir})
    proc = subprocess.Popen(["bash", os.path.join(copie, "planning-hook.sh")], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, env=env, cwd=lab)
    proc.stdin.write(brut)
    proc.stdin.close()
    pid = None
    for _ in range(100):
        if os.path.exists(fichier_pid) and open(fichier_pid, encoding="utf-8").read().strip():
            pid = int(open(fichier_pid, encoding="utf-8").read().strip())
            break
        time.sleep(0.1)
    return proc, pid


def tuer(proc, pid):
    for cible in (pid, proc.pid):
        if cible:
            try:
                os.kill(cible, 9)
            except OSError:
                pass
    proc.wait(timeout=10)
    proc.stdout.close()
    proc.stderr.close()


@lota("R-DEFS-04")
def controle_defs_orphelin(ctx, script):
    """Le Python ne survit pas à son lanceur : le lanceur est tué (SIGKILL) pendant que le cœur dort (délai interne de 60 s) ; le cœur
    disparaît en moins de 4 s."""
    fichier_pid = os.path.join(ctx.unique("pid-orphelin"), "pid")
    os.makedirs(os.path.dirname(fichier_pid))
    copie = echeance_copie(ctx, script, "60.0", "open(%r, 'w').write(str(os.getpid())); import time; time.sleep(30)" % fichier_pid, "hook-orphelin")
    lab = lab_adherent_simple(ctx, "lab-orphelin")
    tmp = ctx.unique("tmp-orphelin")
    os.makedirs(tmp)
    proc, pid = lancer_endormi(ctx, copie, lab, tmp, fichier_pid)
    try:
        if pid is None:
            return False, "le cœur n'a pas démarré (pas de pid)"
        os.kill(proc.pid, 9)
        proc.wait(timeout=10)
        mort = False
        for _ in range(40):
            if not vivant(pid):
                mort = True
                break
            time.sleep(0.1)
    finally:
        tuer(proc, pid)
    return mort, ("le cœur a disparu moins de 4 s après son lanceur" if mort else "le cœur Python (pid %d) vit encore 4 s après la mort de son lanceur" % pid)


INJECTION_APRES_EMISSION = ('import os as _o, signal as _s, time as _t; globals().__setitem__("ECHEANCE_COEUR_S", 0.0); '
                            '_o.kill(_o.getpid(), _s.SIGALRM); _t.sleep(0.3)')
INJECTION_A_LA_SORTIE = ("import atexit, os as _o, signal as _s, time as _t; "
                         "atexit.register(lambda: (globals().__setitem__('ECHEANCE_COEUR_S', 0.0), _o.kill(_o.getpid(), _s.SIGALRM), _t.sleep(0.3)))")


@lota("R-DEFS-06")
def controle_defs_minuteur(ctx, script):
    """F-03 (audit de sécurité final du 2026-10-01) : le minuteur de l'échéance n'est jamais armé APRÈS la décision. Banc déterministe, sans
    horloge : l'échéance est ramenée à 0 et un SIGALRM est envoyé au cœur par lui-même, soit juste après l'impression d'un refus de G6, soit
    à la sortie du processus (décision silencieuse). Une décision imprimée avec le code 0 est livrée telle quelle : le lanceur rend 0 et la
    commande enregistrée rend la raison du cœur (G6), jamais le refus générique du fail-closed ni un code 73 ou 142."""
    armee = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    lab = lab_adherent_simple(ctx, "lab-minuteur")
    sorties = (
        ("après l'impression d'un refus", [("sortie_refus(refus)\n", "sortie_refus(refus); " + INJECTION_APRES_EMISSION + "\n")],
         os.path.join(lab, ".planning", "STATE.md"), "deny"),
        ("à la sortie, décision silencieuse", [("def main():\n    armer_echeance()  # echeance-armee\n",
                                                "def main():\n    armer_echeance()  # echeance-armee\n    " + INJECTION_A_LA_SORTIE + "\n")],
         os.path.join(lab, ".planning", "notes.md"), "silence"))
    for etiquette, remplacements, cible, attendu in sorties:
        copie = copie_modifiee(ctx, armee, "planning-hook.sh", remplacements, "hook-minuteur")
        brut = payload("Write", entree_outil("Write", cible), lab)
        p = subprocess.run(["bash", os.path.join(copie, "planning-hook.sh")], input=brut, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           env=ctx.env(), cwd=lab, timeout=60)
        if p.returncode != 0 or classer(p.returncode, p.stdout) != attendu or p.stderr:
            fautes.append("%s, lanceur seul : rc=%d %s stderr=%s (attendu 0 et %s)" % (etiquette, p.returncode, classer(p.returncode, p.stdout),
                                                                                   court(p.stderr), attendu))
        rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=copie)
        v = classer(rc, out)
        if v != attendu or err or (attendu == "deny" and (b"G6" not in out or b"hook central indisponible" in out)):
            fautes.append("%s, commande enregistrée : %s %s (attendu %s portant la raison du cœur, sans « hook central indisponible »)"
                          % (etiquette, v, court(out), attendu))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "SIGALRM tardif sans effet : refus de G6 et silence livrés tels quels (lanceur 0, commande enregistrée = raison du cœur)")


CONTENUS_ADHESION = (
    # (étiquette, contenu, G6 doit l'admettre ?)  : l'admission est exigée pour les formes courantes (jamais un faux refus), le refus pour
    # les formes que le JSON admet mais que la couche shell de repli (grep ligne à ligne, sans décodage) ne reconnaît pas.
    ("compact", '{"planning_version":"cycles-v1"}', True),
    ("deux espaces, ligne par ligne", '{\n  "planning_version": "cycles-v1"\n}\n', True),
    ("séparateurs en tabulation", '{"planning_version"\t:\t"cycles-v1"}', True),
    ("fins de ligne CRLF", '{\r\n"planning_version": "cycles-v1"\r\n}\r\n', True),
    ("autres clés", '{"planning_version": "cycles-v1", "seuil": 3, "copie": {"x": 1}}', True),
    ("clé en double, la seconde gagne", '{"planning_version":"x","planning_version":"cycles-v1"}', True),
    ("deux-points sur la ligne suivante", '{"planning_version"\n:"cycles-v1"}', False),
    ("valeur sur la ligne suivante", '{\n"planning_version":\n"cycles-v1"\n}\n', False),
    ("clé échappée \\u005f", '{"planning\\u005fversion":"cycles-v1"}', False),
    ("valeur échappée \\u002d", '{"planning_version":"cycles\\u002dv1"}', False),
    ("clé imbriquée seulement", '{"a":{"planning_version":"cycles-v1"}}', False),
)


@lota("R-ADH-REPLI")
def controle_adhesion_repli(ctx, script):
    """F-02 (audit de sécurité final du 2026-10-01) : tout contenu de config.json que G6 admet pour un lab adhérent est AUSSI reconnu adhérent
    par la couche shell de repli de la commande enregistrée. (a) le motif du repli est UNE constante partagée (MOTIF_ADHESION_REPLI du
    cœur), comparée ici au motif du `grep` de hooks.json, jamais une seconde copie libre ; (b) pour chaque contenu de la batterie : G6 le
    refuse, ou le lab qui le porte est refusé par le repli (script absent) sur une écriture neutre ; les formes courantes restent admises."""
    fautes = []
    dossier = _dossier(ctx, script)
    noyau = charger_module(os.path.join(dossier, "planning-hook.sh"))
    motif_noyau = noyau.get("MOTIF_ADHESION_REPLI")
    trouves = re.findall(r"-q -E '(\"planning_version\"[^']*)'", ctx.cmd or "")
    if len(trouves) != 1 or trouves[0] != motif_noyau:
        fautes.append("motif du repli : hooks.json %r, cœur %r (attendus identiques, une seule occurrence)" % (trouves, motif_noyau))
    hook = ctx.copie_forcee(dossier, "armed")
    for etiquette, contenu, admis in CONTENUS_ADHESION:
        lab = lab_adherent_simple(ctx, "lab-adh-g6")
        brut = payload("Write", {"file_path": os.path.join(lab, ".planning", "config.json"), "content": contenu}, lab)
        rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=hook)
        v = classer(rc, out)
        if err or v not in ("silence", "deny"):
            fautes.append("%s : G6 %s %s" % (etiquette, v, court(out)))
            continue
        if admis and v != "silence":
            fautes.append("%s : G6 refuse une forme courante (attendu admise) : %s" % (etiquette, court(out)))
        if not admis and v != "deny":
            fautes.append("%s : G6 admet une forme que le repli ne reconnaît pas (attendu refus)" % etiquette)
        if not admis and v == "deny":
            # N-05 : le refus d'un contenu que le JSON dit adhérent nomme la contrainte de mise en forme ; un contenu réellement non adhérent garde la raison d'origine
            raison = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["permissionDecisionReason"]
            attendu_forme = etiquette != "clé imbriquée seulement"
            if attendu_forme and ("UNE même ligne" not in raison or "changer ou retirer" in raison):
                fautes.append("%s : raison %r (attendu : la contrainte de mise en forme, « UNE même ligne », jamais « changer ou retirer »)" % (etiquette, raison[:200]))
            if not attendu_forme and "changer ou retirer l'adhésion" not in raison:
                fautes.append("%s : raison %r (attendu : « changer ou retirer l'adhésion »)" % (etiquette, raison[:200]))
        if v == "silence":
            lab2 = lab_adherent_simple(ctx, "lab-adh-repli")
            ecrire(os.path.join(lab2, ".planning", "config.json"), contenu)
            neutre = payload("Write", entree_outil("Write", os.path.join(lab2, ".planning", "notes.md")), lab2)
            rc2, out2, err2 = ctx.lancer("C", neutre, cwd=lab2)
            if classer(rc2, out2) != "deny" or b"hook central indisponible" not in out2:
                fautes.append("%s : admis par G6 mais NON reconnu adhérent par le repli (script absent : %s) — la porte du Write de config.json"
                              % (etiquette, classer(rc2, out2)))
    return (not fautes), ("; ".join(fautes) if fautes else
                          "motif du repli partagé (constante du cœur = grep de hooks.json) ; %d contenus : admis par G6 ⇒ reconnu par le repli, formes que le grep manque refusées"
                          % len(CONTENUS_ADHESION))


@lota("R-DEFS-05")
def controle_defs_transport(ctx, script):
    """Fichier de transport : créé en 0600 (vu avant la lecture), EFFACÉ dès que le cœur a lu le payload — un SIGKILL du lanceur et du cœur
    pendant le calcul ne laisse rien sous TMPDIR."""
    fautes = []
    lab = lab_adherent_simple(ctx, "lab-transport")
    # a) avant la lecture : le fichier existe, 0600
    fichier_pid = os.path.join(ctx.unique("pid-transport-a"), "pid")
    os.makedirs(os.path.dirname(fichier_pid))
    copie = echeance_copie(ctx, script, "60.0", "open(%r, 'w').write(str(os.getpid())); import time; time.sleep(3)" % fichier_pid,
                           "hook-transport-a", avant_lecture=True)
    tmp = ctx.unique("tmp-transport-a")
    os.makedirs(tmp)
    proc, pid = lancer_endormi(ctx, copie, lab, tmp, fichier_pid)
    try:
        presents = [n for n in os.listdir(tmp) if n.startswith("vf-planning-hook.")]
        if len(presents) != 1:
            fautes.append("avant la lecture : %d fichier(s) de transport (attendu 1)" % len(presents))
        else:
            mode = stat.S_IMODE(os.stat(os.path.join(tmp, presents[0])).st_mode)
            if mode != 0o600:
                fautes.append("fichier de transport en %o (attendu 600)" % mode)
    finally:
        tuer(proc, pid)
    # b) après la lecture : effacé, même sous SIGKILL
    fichier_pid = os.path.join(ctx.unique("pid-transport-b"), "pid")
    os.makedirs(os.path.dirname(fichier_pid))
    copie = echeance_copie(ctx, script, "60.0", "open(%r, 'w').write(str(os.getpid())); import time; time.sleep(30)" % fichier_pid, "hook-transport-b")
    tmp = ctx.unique("tmp-transport-b")
    os.makedirs(tmp)
    proc, pid = lancer_endormi(ctx, copie, lab, tmp, fichier_pid)
    try:
        if pid is None:
            fautes.append("le cœur n'a pas démarré (pas de pid)")
        else:
            restes = os.listdir(tmp)
            if restes:
                fautes.append("pendant le calcul : %s sous TMPDIR" % restes)
    finally:
        tuer(proc, pid)
    restes = os.listdir(tmp)
    if restes:
        fautes.append("après SIGKILL : %s sous TMPDIR" % restes)
    return (not fautes), ("; ".join(fautes) if fautes else "transport 0600 avant la lecture, effacé dès la lecture : rien sous TMPDIR pendant le calcul ni après SIGKILL")


lota_mutant("PUCE-REGEX-FM", "# puce-agent-fm", 'item = re.match(r"^\\s+-\\s+(.+?)(\\s+#.*)?$", ligne)  # puce-agent-fm', "R-DEFS-02")
lota_mutant("PUCE-REGEX-CHAMP", "# puce-agent-champ", 'item = re.match(r"^\\s+-\\s+(.+?)(\\s+#.*)?$", lignes[k])  # puce-agent-champ', "R-DEFS-02")
lota_mutant("PUCE-EQUIVALENCE", "# puce-lineaire", "if True:  # puce-lineaire", "R-DEFS-01")
lota_mutant("ECHEANCE-ARMEE", "# echeance-armee", "pass  # echeance-armee", "R-DEFS-03")
lota_mutant("ECHEANCE-DELAI", "# echeance-delai", "if False:  # echeance-delai", "R-DEFS-03")
lota_mutant("ECHEANCE-PARENT", "# echeance-parent", "if False:  # echeance-parent", "R-DEFS-04")
lota_mutant("ADH-REPLI-CONJONCTION", "# g6-adhesion", "return None if _texte_adherent(texte) else RAISON_ADHESION  # g6-adhesion", "R-ADH-REPLI")
lota_mutant("ADH-REPLI-RAISON", "# raison-forme", "return RAISON_ADHESION  # raison-forme", "R-ADH-REPLI")
lota_mutant("ADH-REPLI-ESPACES", "# repli-espaces", 'motif = re.compile(MOTIF_ADHESION_REPLI.replace("[[:space:]]", r"[ \\t\\r\\n\\v\\f]"))  # repli-espaces',
            "R-ADH-REPLI")
lota_mutant("ADH-REPLI-MOTIF", "# motif-adhesion-repli", 'MOTIF_ADHESION_REPLI = \'"planning_version"[[:space:]]*:[[:space:]]*"cycles-v[0-9]"\'  # motif-adhesion-repli',
            "R-ADH-REPLI")
lota_mutant("ECHEANCE-FIGEE-EMISSION", "# echeance-figee-emission", "pass  # echeance-figee-emission", "R-DEFS-06")
lota_mutant("ECHEANCE-FIGEE-SORTIE", "# echeance-figee-sortie", "pass  # echeance-figee-sortie", "R-DEFS-06")
lota_mutant("ECHEANCE-FIGE-GARDE", "# echeance-fige-garde", "if False:  # echeance-fige-garde", "R-DEFS-06")
lota_mutant("TRANSPORT-EFFACE", "# transport-efface", "pass  # transport-efface", "R-DEFS-05")


# --- LOT A, constat 3 (revue M1 et m5) : un plugin en plusieurs versions ne retient que sa version ACTIVE ---------------------------------
# Avant : `definitions_plugin` donnait `inconnu` quand deux versions en cache portaient des rôles différents (le rôle disparaissait), la
# plus ancienne sinon, et marchait tout `~/.claude/plugins` à chaque appel (environ 1 s). Décision du manager vf-dev-manager, 2026-10-01 :
# la version de `installed_plugins.json` (installPath, fichier régulier et lisible) ; à défaut la plus HAUTE du cache (tri de version, pas
# lexical) ; seul le dossier de cette version est lu. `HOME` reste un argument du lanceur (R-ENV-02).
VERSION_AGENT = "agentx"


def agent_version(version, texte, module=None):
    """(chemin relatif sous `.claude/plugins/`, texte) de l'agent `agentx` dans la version `version` du plugin `monplugin`."""
    base = "cache/mp/monplugin/%s/" % version + ((module + "/") if module else "")
    return (base + "agents/agentx.md", texte % VERSION_AGENT)


def installed_plugins(home, versions, ecrire_comme="regulier", cle="monplugin@mp"):
    """Pose `installed_plugins.json` : une entrée par (version, installPath) de `versions`. `ecrire_comme` : `regulier`, `illisible`
    (JSON cassé), `lien` (lien symbolique vers un fichier valide)."""
    chemin = os.path.join(home, ".claude", "plugins", "installed_plugins.json")
    entrees = [{"scope": "user", "installPath": chemin_install, "version": version} for version, chemin_install in versions]
    texte = json.dumps({"version": 2, "plugins": {cle: entrees}})
    if ecrire_comme == "illisible":
        texte = '{"version": 2, "plugins": {oups'
    if ecrire_comme == "lien":
        reel = os.path.join(home, "ailleurs", "installed.json")
        ecrire(reel, texte)
        os.makedirs(os.path.dirname(chemin), exist_ok=True)
        os.symlink(reel, chemin)
    else:
        ecrire(chemin, texte)


def verdict_version(ctx, hook, home):
    return verdict_role(*_role(ctx, hook, "Write", ROLE_LIVRABLE, agent="monplugin:" + VERSION_AGENT, extra_env={"HOME": home}))


@lota("R-VERSION-01")
def controle_version_active(ctx, script):
    """Copie armée, deux versions en cache (`1.9.0` producteur, `1.10.0` juge) : sans installed_plugins.json la plus HAUTE (tri de
    version : 1.10.0 après 1.9.0) fait foi, refus ; installed_plugins.json qui désigne 1.9.0 : passage ; qui désigne 1.10.0 : refus ;
    deux versions de même rôle : ce rôle ; pré-version (`2.0.0-beta` juge, `2.0.0` producteur) : la version finale ; dispositions
    `<version>/<module>/agents` et `<version>/<module>/content/agents`."""
    hook = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []

    def cas(etiquette, attendu, agents, install=None, comme="regulier", cle="monplugin@mp"):
        home = home_de_suite(ctx, "version", plugins=agents)
        if install is not None:
            installed_plugins(home, [(v, os.path.join(home, ".claude", "plugins", "cache", "mp", "monplugin", v) if sous is None else sous) for v, sous in install],
                              comme, cle)
        v = verdict_version(ctx, hook, home)
        if v != attendu:
            fautes.append("%s : attendu %s, obtenu %s" % (etiquette, attendu, v))

    mixte = [agent_version("1.9.0", TEXTE_PRODUCTEUR), agent_version("1.10.0", TEXTE_JUGE)]
    cas("la plus haute (1.10.0 juge) sans installed_plugins.json", "refus", mixte)
    cas("installed_plugins.json désigne 1.10.0 (juge)", "refus", mixte, install=[("1.10.0", None)])
    inverse = [agent_version("1.9.0", TEXTE_JUGE), agent_version("1.10.0", TEXTE_PRODUCTEUR)]
    cas("la plus haute (1.10.0 producteur) sans installed_plugins.json", "passage", inverse)
    cas("installed_plugins.json désigne 1.9.0 (juge) : la version active gagne sur la plus haute", "refus", inverse, install=[("1.9.0", None)])
    cas("installed_plugins.json illisible : repli sur la plus haute (producteur)", "passage", inverse, install=[("1.9.0", None)], comme="illisible")
    cas("installed_plugins.json en lien symbolique : ignoré, repli sur la plus haute (producteur)", "passage", inverse, install=[("1.9.0", None)], comme="lien")
    ecrire(os.path.join(ctx.work, "hors-plugins", "agents", "agentx.md"), TEXTE_JUGE % VERSION_AGENT)
    cas("installPath hors de ~/.claude/plugins : ignoré, repli sur la plus haute (producteur)", "passage", inverse,
        install=[("1.9.0", os.path.join(ctx.work, "hors-plugins"))])
    cas("entrée d'un autre plugin seulement : repli sur la plus haute (producteur)", "passage", inverse, install=[("1.9.0", None)], cle="autre@mp")
    memes = [agent_version("1.0.0", TEXTE_JUGE), agent_version("1.1.0", TEXTE_JUGE)]
    cas("deux versions de même rôle (juge)", "refus", memes)
    cas("pré-version juge et version finale producteur : la finale", "passage", [agent_version("2.0.0-beta", TEXTE_JUGE), agent_version("2.0.0", TEXTE_PRODUCTEUR)])
    cas("disposition <version>/<module>/agents", "refus", [agent_version("2.0.0", TEXTE_JUGE, "mod")])
    cas("disposition <version>/<module>/content/agents", "refus", [agent_version("2.0.0", TEXTE_JUGE, "mod/content")])
    cas("version ancienne seule contradictoire : jamais lue", "passage", [agent_version("1.0.0", TEXTE_JUGE), agent_version("3.0.0", TEXTE_PRODUCTEUR)])
    return (not fautes), ("; ".join(fautes) if fautes else "13 résolutions conformes : version active, plus haute (tri de version), repli sur un installed_plugins.json absent, illisible, en lien ou hors plugins")


lota_mutant("PLUGIN-INSTALLED", "# plugin-installed", "versions = []  # plugin-installed", "R-VERSION-01")
lota_mutant("PLUGIN-HAUTE", "# plugin-haute", "haute = min(cle for cle, _chemin in versions)  # plugin-haute", "R-VERSION-01")
lota_mutant("PLUGIN-TRI", "# plugin-tri", "return (nom,)  # plugin-tri", "R-VERSION-01")


# --- LOT A, constats 9 et 10 (audit M2 ; audit M1, part canary) : le canary n'exécute que la commande que l'installeur pose ------------
# Décisions du manager vf-dev-manager, 2026-10-01 (renversables). M2 : le canary exécutait par `/bin/sh -c` la première commande PreToolUse
# du `settings.json` du lab qui contenait « planning-hook.sh » — n'importe quelle commande forgée. Il n'exécute plus qu'une commande
# STRICTEMENT égale à celle de hooks.json, résolue comme l'installeur la pose (scope projet : "$CLAUDE_PROJECT_DIR"/.claude/scripts, scope
# compte : "$HOME"/.claude/scripts) ; sinon il signale « commande enregistrée non reconnue » sans rien exécuter. M1 (canary) : des
# constantes d'armement absentes ou illisibles, sous adhésion, sont un SIGNAL, plus un silence sous --hook. L'option `--reference=<fichier>`
# (réservée aux suites) remplace la commande de référence : elle n'est jamais lue des réglages.
def canary_direct(ctx, dossier_scripts, reglage, args=(), session=None, home=None, projet=None):
    """Lance le check-gates-alive.sh de `dossier_scripts` dans une session adhérente, sur le réglage `reglage` ; rend (code, stdout, stderr)."""
    session = session or lab_adherent_simple(ctx, "session-canary-direct")
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": home or ctx.home, "CLAUDE_PROJECT_DIR": projet or session}
    p = subprocess.run(["bash", os.path.join(dossier_scripts, "check-gates-alive.sh"), "--settings=" + reglage] + list(args),
                       input=json.dumps({"cwd": session}).encode("utf-8"), stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
                       cwd=session, timeout=240)
    return p.returncode, p.stdout, p.stderr


def reglage_de(ctx, commandes, prefixe="reglage-m2"):
    """Réglage jetable : `commandes` sous PreToolUse (chacune dans son groupe) ; la commande réelle sous les quatre autres événements (Phase 46 :
    le canary signale un événement non câblé, ce que ces cas ne veulent pas mesurer)."""
    chemin = os.path.join(ctx.unique(prefixe), "settings.json")
    hooks = {"PreToolUse": [{"matcher": "Write", "hooks": [{"type": "command", "command": c}]} for c in commandes]}
    for evt in EVENEMENTS_CABLES[1:]:
        hooks[evt] = [{"hooks": [{"type": "command", "command": ctx.cmd.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts')}]}]
    ecrire(chemin, json.dumps({"hooks": hooks}))
    return chemin


def une_ligne_canary(out, fragments):
    """None si stdout est UNE ligne au préfixe du canary qui contient chaque fragment, sinon la raison."""
    lignes = [l for l in out.decode("utf-8", "replace").split("\n") if l]
    if len(lignes) != 1 or not lignes[0].startswith("[planning-core] canary : "):
        return "%d ligne(s) : %s" % (len(lignes), court(out))
    manque = [f for f in fragments if f not in lignes[0]]
    return ("fragment(s) absent(s) %s : %s" % (manque, lignes[0])) if manque else None


@lota("R-CAN-09")
def controle_canary_commande_reconnue(ctx, script):
    """M2 : une commande forgée `touch <marqueur> # planning-hook.sh` n'est JAMAIS exécutée (marqueur jamais créé) : seule, elle fait signaler
    « commande enregistrée non reconnue » (code 0, UNE ligne, sous --hook comme en direct) ; devant la vraie commande, la vraie est rejouée
    (code 3) ; la forme du scope compte ("$HOME"/.claude/scripts) est reconnue comme celle du scope projet."""
    d = scripts_canary(ctx, _dossier(ctx, script), "observe", tel_quel=True)
    reelle = ctx.cmd.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts')
    marqueur = os.path.join(ctx.unique("marqueur-m2"), "cree")
    os.makedirs(os.path.dirname(marqueur))
    forgee = "touch '%s' # planning-hook.sh" % marqueur
    fautes = []
    for args in ((), ("--hook",)):
        rc, out, err = canary_direct(ctx, d, reglage_de(ctx, [forgee]), args, projet=os.path.dirname(os.path.dirname(d)))
        raison = une_ligne_canary(out, ("commande enregistrée non reconnue",))
        if rc != 0 or raison or os.path.exists(marqueur):
            fautes.append("commande forgée seule %s : rc=%d %s marqueur=%s" % (" ".join(args) or "sans --hook", rc, raison or "", os.path.exists(marqueur)))
    rc, out, err = canary_direct(ctx, d, reglage_de(ctx, [forgee, reelle]), (), projet=os.path.dirname(os.path.dirname(d)))
    if rc != 3 or out != b"" or os.path.exists(marqueur):
        fautes.append("forgée puis réelle : rc=%d stdout=%s marqueur=%s (attendu 3, rien, aucun marqueur)" % (rc, court(out), os.path.exists(marqueur)))
    # forme du scope compte : HOME porte `.claude/scripts` (canary et hook réels), le réglage pose "$HOME"/.claude/scripts
    home = ctx.unique("home-compte-m2")
    dh = os.path.join(home, ".claude", "scripts")
    os.makedirs(dh)
    for nom in ("check-gates-alive.sh", "planning-hook.sh"):
        shutil.copy(os.path.join(d, nom), os.path.join(dh, nom))
    compte = ctx.cmd.replace(TOKEN, '"$HOME"/.claude/scripts')
    vide = ctx.unique("projet-vide-m2")
    os.makedirs(vide)
    rc, out, err = canary_direct(ctx, dh, reglage_de(ctx, [compte]), (), home=home, projet=vide)
    if rc != 3 or out != b"":
        fautes.append("scope compte : rc=%d stdout=%s stderr=%s (attendu 3 et rien)" % (rc, court(out), court(err)))
    return (not fautes), ("; ".join(fautes) if fautes else "commande forgée : jamais exécutée, signalée « non reconnue » ; forgée puis réelle : la réelle est rejouée ; forme du scope compte reconnue")


@lota("R-CAN-10")
def controle_canary_armement_signal(ctx, script):
    """M1 (canary) : un planning-hook.sh sans constantes ARMEMENT_* posé à côté du canary, dans une session adhérente, fait SIGNALER « constantes
    d'armement absentes ou illisibles » (code 0, UNE ligne), sous --hook comme en direct — plus un code 4 qui se traduit en silence."""
    projet = ctx.unique("projet-sans-constantes")
    d = os.path.join(projet, ".claude", "scripts")
    os.makedirs(d)
    shutil.copy(os.path.join(_dossier(ctx, script), "check-gates-alive.sh"), os.path.join(d, "check-gates-alive.sh"))
    with open(os.path.join(d, "planning-hook.sh"), "w", encoding="utf-8") as fh:
        fh.write("#!/usr/bin/env bash\ncat >/dev/null\nexit 0\n")
    reglage = reglage_de(ctx, [ctx.cmd.replace(TOKEN, '"$CLAUDE_PROJECT_DIR"/.claude/scripts')])
    fautes = []
    for args in ((), ("--hook",)):
        rc, out, err = canary_direct(ctx, d, reglage, args, projet=projet)
        raison = une_ligne_canary(out, ("constantes d'armement absentes ou illisibles",))
        if rc != 0 or raison:
            fautes.append("%s : rc=%d %s" % (" ".join(args) or "sans --hook", rc, raison or ""))
    return (not fautes), ("; ".join(fautes) if fautes else "constantes absentes : code 0 et UNE ligne de signal, sous --hook comme en direct")


@lota("R-CAN-11")
def controle_canary_reference_dans_hooks_json(ctx, script):
    """La commande de référence EMBARQUÉE dans le canary est, octet pour octet, celle de hooks.json : la dérive de l'une ou de l'autre rougit ici
    (le canary ne lit pas hooks.json au démarrage : l'installeur ne le pose pas dans le lab)."""
    texte = open(os.path.join(_dossier(ctx, script), "check-gates-alive.sh"), encoding="utf-8").read()
    debut = texte.find("COMMANDE_REFERENCE = r'''")
    if debut < 0:
        return False, "COMMANDE_REFERENCE absente du canary"
    corps = texte[debut + len("COMMANDE_REFERENCE = r'''"):]
    fin = corps.find("'''")
    embarquee = corps[:fin]
    if embarquee != ctx.cmd:
        return False, "commande embarquée différente de hooks.json (%d caractères contre %d)" % (len(embarquee), len(ctx.cmd))
    return True, "commande embarquée identique à celle de hooks.json (%d caractères)" % len(embarquee)


lota_mutant("CANG-RECONNUE", "# canary-reconnue", "if True:  # canary-reconnue", "R-CAN-09", "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF")
lota_mutant("CANG-ARMEMENT-SIGNAL", "# canary-armement", "return 4  # canary-armement", "R-CAN-10", "check-gates-alive.sh", "PY_CHECK_GATES_ALIVE_EOF")


# --- LOT C, constat 1 (re-audit N1) : le budget d'indexation ne décompte que les fichiers CANDIDATS --------------------------------
# Décision du manager vf-dev-manager, 2026-10-01 (renversable) : des fichiers frères triés avant l'agent visé épuisaient les 8 Mio
# d'indexation, l'agent devenait `illisible` et le hook ROLE se taisait (un juge `zz-judge` seul : refus ; avec dix `aaa-*.md` de 1 Mo :
# plus aucun refus). Un épuisement qui survient malgré tout est VISIBLE : une ligne `raison=budget-indexation` au journal d'observation.
def frere_lourd(lab, nom, agent, octets=1000000):
    """`<lab>/.claude/agents/<nom>.md` : une définition valide de `agent`, remplie jusqu'à `octets` octets (lignes courtes)."""
    entete = "---\nname: %s\ndescription: frère lourd\ntools: Read\n---\n" % agent
    corps = ("x" * 99 + "\n") * ((octets - len(entete)) // 100)
    ecrire(os.path.join(lab, ".claude", "agents", nom + ".md"), entete + corps)


@lota("R-N1-01")
def controle_n1_budget_candidats(ctx, script):
    """Dix frères `aaa-*.md` de 1 Mo triés avant `zz-judge` : le juge reste refusé (ROLE) en moins de 3 s ; aucune ligne `budget-indexation`
    (les frères ne sont pas candidats) ; puis dix définitions de `zz-judge` de 1 Mo (candidates : le budget s'épuise) : jamais un refus
    (indéterminé, P45-D-11), et UNE ligne `raison=budget-indexation` au journal d'observation."""
    armee = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    lab = ctx.unique("lab-n1")
    ecrire(os.path.join(lab, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    ecrire(os.path.join(lab, ".claude", "agents", "zz-judge.md"), TEXTE_JUGE % "zz-judge")
    for i in range(10):
        frere_lourd(lab, "aaa-%02d" % i, "aaa-%02d" % i)
    cache = dossier_neuf(ctx, "cache-n1-a")
    brut = payload("Write", entree_outil("Write", os.path.join(lab, "livrables", "x.md")), lab, agent_type="zz-judge")
    debut = time.perf_counter()
    rc, out, err = ctx.lancer("A", brut, cwd=lab, dossier=armee, extra_env={"XDG_CACHE_HOME": cache})
    duree = time.perf_counter() - debut
    v = verdict_role(rc, out, err)
    if v != "refus" or duree >= 3.0:
        fautes.append("dix frères de 1 Mo : %s en %.2f s (attendu refus en moins de 3 s)" % (v, duree))
    if [l for l in lignes_journal(cache) if "raison=budget-indexation" in l]:
        fautes.append("ligne budget-indexation écrite alors qu'aucun candidat n'a épuisé le budget")
    lab2 = ctx.unique("lab-n1-candidats")
    ecrire(os.path.join(lab2, ".planning", "config.json"), '{"planning_version": "cycles-v1"}')
    for i in range(10):
        frere_lourd(lab2, "zz-judge-%02d" % i, "zz-judge")
    cache2 = dossier_neuf(ctx, "cache-n1-b")
    brut = payload("Write", entree_outil("Write", os.path.join(lab2, "livrables", "x.md")), lab2, agent_type="zz-judge")
    rc, out, err = ctx.lancer("A", brut, cwd=lab2, dossier=armee, extra_env={"XDG_CACHE_HOME": cache2})
    v = verdict_role(rc, out, err)
    visibles = [l for l in lignes_journal(cache2) if "raison=budget-indexation" in l and "gate=ROLE" in l]
    if v != "passage":
        fautes.append("budget épuisé sur des candidats : %s (attendu passage : indéterminé)" % v)
    if len(visibles) != 1:
        fautes.append("budget épuisé : %d ligne(s) budget-indexation au journal (attendu 1)" % len(visibles))
    return (not fautes), ("; ".join(fautes) if fautes else "dix frères de 1 Mo : refus du juge en moins de 3 s, aucun signal ; dix candidats de 1 Mo : indéterminé (passage) et une ligne raison=budget-indexation")


lota_mutant("INDEXATION-CANDIDATS", "# indexation-candidats", "if False:  # indexation-candidats", "R-N1-01")
lota_mutant("BUDGET-SIGNAL", "# role-signal", "for signal in []:  # role-signal", "R-N1-01")


# LOTA-ANCRE


# --- R-REFERENCE et MUT-REFERENCE (45-10 ; GATE-15, T-45-90) ----------------------------------------------------------------------------
# La référence du modèle (modele-cycles.md, section « Hook central et gates d'écriture (Phase 45) ») dit ce que le hook livré fait. Ce
# contrôle la compare, mécaniquement, aux constantes du hook (table d'armement, noms protégés par G6, nom du journal de dérogation,
# marqueurs de code, ordre de résolution des agents), à la commande enregistrée de hooks.json (outils refusés en mode dégradé, outil
# laissé ouvert) et à la table CANARIS du canary (cas par gate) : tout écart rougit — une référence qui annoncerait un gate armé qui ne
# l'est pas serait un faux vert documentaire (T-45-90). Les limites déclarées (a) à (ae) sont chacune sur sa propre ligne canonique
# `- **limite (X)**` avec ses mots-clés. Chaque mutant retire ou fausse UNE chose, sur une copie de la référence écrite sous le dossier
# de travail (ou, pour MUT-REFERENCE-CODE, sur les constantes du hook, la référence restant intacte) ; le contrôle doit alors rendre un
# écart. Les lignes d'écart du contrôle commencent par `ECART` ; la suite ne les imprime que si la VRAIE référence est en écart (un
# mutant tué n'imprime que sa trace, sans ce mot : une exécution verte n'a aucune ligne ECART).
TITRE_REFERENCE = re.compile(r"^## Hook central et gates d.écriture \(Phase 45\)")
GATES_REFERENCE = ("G6", "G5", "G1", "G7", "ROLE", "G2")
LIMITES_REFERENCE = (
    ("a", ("compact", "tool_name", "N-06")),
    ("b", ("cycles-v1", "une ligne")),
    ("c", ("lien symbolique", "O_NOFOLLOW")),
    ("d", ("fermée", "échappement JSON")),
    ("e", ("JSON", "outil inconnu")),
    ("f", ("bash", "127")),
    ("g", ("Bash", "P45-D-06b")),
    ("h", ("relatif", "cwd")),
    ("i", ("CLAUDE_PROJECT_DIR", "P45-D-21b")),
    ("j", ("CADRAGE.md", "G1", "f5-etats")),
    ("k", ("config.json", "virgule finale", "BOM")),
    ("l", ("allowlist", "G6", "F9")),
    ("m", ("F2", "config.json", "plusieurs lignes", "silence")),
    ("n", ("T-45-42", "F6", "Bash")),
    ("o", ("P45-D-01a", "ancêtre", "U+212A")),
    ("p", ("R1", "sans `config.json`", "plus proche")),
    ("q", ("m1", "subagent_type", "fork")),
    ("r", ("m6", "journal d'observation", "rotation")),
    ("s", ("échéance", "73", "déni de service")),
    ("t", ("F3", "installed_plugins.json", "chiffres")),
    ("u", ("F4", "échappement JSON", "hors de tout lab adhérent")),
    ("v", ("F5", "marque de génération", "sans archive")),
    ("w", ("N1", "name:", "échappement YAML")),
    ("x", ("MESURE-VIDE", "volume")),
    ("y", ("settings", "Q-G6 = b", "scope compte", "planning-hook.sh", "lien préexistant")),
    ("z", ("SIGALRM", "Alarm clock", "faux refus")),
    ("aa", ("F-01", "4096", "cwd", "GATE-03", "N-01", "surrogate", "N2-01", "antislash", "N2-03", "N2-04", "R-DOUTE-04", "N3-01", "N3-02", "forme physique",
            "réduite lexicalement", "lien dur", "lien symbolique", "R-REDUC-01", "N4-01", "N4-04", "ROLE-juge")),
    ("ab", ("F-04", "~", "cwd", "Write", "N-03", "HOME", "N2-02", "plus stricte")),
    ("ac", ("F-05", "notebook_path", "Agent", "Task")),
    ("ad", ("F-06", ".claude/worktrees", "Write")),
    ("ae", ("F-07", "MultiEdit", "MCP", "matcher")),
    ("af", ("F2", "..", "lien symbolique", "PHYSIQUEMENT", "LEXICALEMENT", "R-REDUC-01", "N4-04")),
    ("ag", ("F3", "lien symbolique", "FICHIER", "couche de repli")),
    ("ah", ("F4", "config.json", "saut de ligne", "grep")),
    ("ai", ("F5", "leurre", "5 000 chiffres", "imbrication", "_premier_gagne")),
    ("aj", ("F6", "NotebookEdit", "file_path", "notebook_path")),
    ("ak", ("Windows", "8.3", "Python", "3.14", "3.9.6")),
    ("al", ("N4-02", "/.vol", "inode", "macOS")),
    ("am", ("N4-03", "dérogation", "fail-closed")),
    ("an", ("N4-05", "lstat", "readlink", "OSError")),
    ("ao", ("cwd", "new_cwd")),
    ("ap", ("SubagentHandback", "juges", "G4′ est ouvert")),
    ("aq", ("inconnu",)),
)


def section_reference(texte):
    lignes = texte.split("\n")
    debut = next((i for i, l in enumerate(lignes) if TITRE_REFERENCE.match(l)), None)
    if debut is None:
        return None
    fin = next((j for j in range(debut + 1, len(lignes)) if lignes[j].startswith("## ")), len(lignes))
    return lignes[debut:fin]


def jetons_reference(ligne):
    return re.findall(r"`([^`]+)`", ligne)


def canaris_par_gate(texte_canary):
    res = {}
    for ident, gate in re.findall(r'"([A-Za-z0-9_-]+)\|(G6|G5|G1|G7|ROLE)\|nominal\|', texte_canary):
        res.setdefault(gate, set()).add(ident)
    return res


def ordre_resolution_hook(texte_hook):
    """Ordre (lab, compte, plugin) de `resoudre_agent`, lu dans le TEXTE du hook : l'ordre des deux premiers niveaux est celui de la liste
    `niveaux`, le plugin vient après la boucle (premier appel de `definitions_plugin`)."""
    try:
        corps = texte_hook[texte_hook.index("def resoudre_agent("):]
        fin = corps.find("\ndef ", 10)
        corps = corps[: fin if fin != -1 else len(corps)]
        ligne = next(l for l in corps.split("\n") if "niveaux = [" in l)
        base = corps.index(ligne)
        positions = [("lab", base + ligne.index("dossier_lab")), ("compte", base + ligne.index("dossier_compte")),
                     ("plugin", corps.index("definitions_plugin("))]
    except (ValueError, StopIteration):
        return None
    return [nom for nom, _ in sorted(positions, key=lambda p: p[1])]


def outils_commande(commande, matcher):
    """(outils refusés en mode dégradé, outils laissés ouverts) de la commande enregistrée : les noms du `case` glob de la commande, et ceux
    du matcher de l'entrée que ce glob ne refuse pas."""
    refuses = set(re.findall(r"""\*'"tool_name":"([A-Za-z]+)"'\*""", commande))
    return refuses, set(matcher.split("|")) - refuses


def ecarts_reference(texte, ns, texte_hook, canaris, commande, matcher):
    """Lignes `ECART …` de la comparaison référence ↔ code (liste vide : conforme)."""
    ecarts = []
    section = section_reference(texte)
    if section is None:
        return ["ECART section « Hook central et gates d'écriture (Phase 45) » absente de la référence"]
    table, ordre = ns["TABLE_ARMEMENT"], ns["ORDRE_ETAPES"]
    etape = {g: str(i + 1) for i, groupe in enumerate(ordre) for g in groupe}
    for gate in table:
        if gate not in GATES_REFERENCE:
            ecarts.append("ECART gate %s du hook inconnu du contrôle (la référence ne peut pas le décrire)" % gate)
    for gate in GATES_REFERENCE:
        lignes = [l for l in section if re.match(r"^\|\s*%s\s*\|" % gate, l)]
        if len(lignes) != 1:
            ecarts.append("ECART table d'armement : %d ligne(s) `| %s |` (attendu 1)" % (len(lignes), gate))
            continue
        cases = [c.strip().strip("`") for c in lignes[0].strip().strip("|").split("|")]
        if len(cases) != 6:
            ecarts.append("ECART table d'armement : la ligne %s a %d colonne(s) (attendu 6)" % (gate, len(cases)))
            continue
        etat = ns["G2_MODE"] if gate == "G2" else table.get(gate)
        if cases[2] != etat:
            ecarts.append("ECART %s : état « %s » dans la référence, « %s » dans le code livré" % (gate, cases[2], etat))
        attendue = "-" if gate == "G2" else etape.get(gate)
        if cases[1] != attendue:
            ecarts.append("ECART %s : étape « %s » dans la référence, « %s » dans ORDRE_ETAPES" % (gate, cases[1], attendue))
        ids = {x.strip() for x in cases[4].split(",")}
        ids_code = {"aucun"} if gate == "G2" else canaris.get(gate, set())
        if ids != ids_code:
            ecarts.append("ECART %s : cas de canary %s dans la référence, %s dans CANARIS" % (gate, sorted(ids), sorted(ids_code)))
        releve = "aucun" if gate == "G2" else "45-REJEU-ETAPE-" + (etape.get(gate) or "?")
        if cases[5] != releve:
            ecarts.append("ECART %s : relevé « %s » dans la référence, « %s » attendu" % (gate, cases[5], releve))
    toutes_observe = all(v == "observe" for v in table.values())
    dit_aucun = any("Aucun gate n'est armé" in l for l in section)
    if toutes_observe and not dit_aucun:
        ecarts.append("ECART le code livré a toutes ses constantes à observe : la référence doit dire « Aucun gate n'est armé »")
    if not toutes_observe and dit_aucun:
        ecarts.append("ECART la référence dit « Aucun gate n'est armé » alors qu'une constante du code livré vaut armed")

    def jetons_de(marque, attendu, etiquette):
        lignes = [l for l in section if l.startswith(marque)]
        if len(lignes) != 1:
            ecarts.append("ECART %s : %d ligne(s) `%s` (attendu 1)" % (etiquette, len(lignes), marque))
            return
        lus = set(jetons_reference(lignes[0]))
        if lus != attendu:
            ecarts.append("ECART %s : référence %s, code %s" % (etiquette, sorted(lus), sorted(attendu)))

    jetons_de("- **Noms protégés par G6**", {nom for nom, _genre in ns["PROTEGES_G6"].values()}, "noms protégés par G6")
    jetons_de("- **Scripts du hook protégés par G6**", set(ns["SCRIPTS_HOOK_G6"]), "scripts du hook protégés par G6")
    jetons_de("- **Journal de dérogation**", {ns["NOM_JOURNAL_DEROGATIONS"]}, "nom du journal de dérogation")
    jetons_de("- **Marqueurs de projet de code (G7)**", set(ns["MARQUEURS_CODE"]) | {"*" + ns["SUFFIXE_XCODEPROJ"]}, "marqueurs de code")
    refuses, ouverts = outils_commande(commande, matcher)
    # Revue Samuel, PR #124 (arbitrage Willy, AskUserQuestion session principale, 2026-10-02) : le pré-filtre hors adhésion de la commande
    pre_ok = "vf_pre() {" in commande and commande.count("vf_pre && exit 0\n") == 1 and commande.index("vf_pre && exit 0\n") < commande.index('bash "$S"')
    jetons_de("- **Pré-filtre hors adhésion**", {"vf_pre", "vf_pre && exit 0"} if pre_ok else set(), "pré-filtre hors adhésion (défini et appelé avant le lancement du script)")
    jetons_de("- **Outils refusés en mode dégradé**", refuses, "outils refusés en mode dégradé")
    jetons_de("- **Outil laissé ouvert en mode dégradé**", ouverts, "outil laissé ouvert en mode dégradé")
    lignes = [l for l in section if l.startswith("- **Ordre de résolution des agents (P45-D-05b)**")]
    ordre_code = ordre_resolution_hook(texte_hook)
    if len(lignes) != 1:
        ecarts.append("ECART ordre de résolution : %d ligne(s) (attendu 1)" % len(lignes))
    elif [x.strip() for x in lignes[0].split(" : ", 1)[-1].split(",")] != ordre_code:
        ecarts.append("ECART ordre de résolution : référence %r, code %r" % (lignes[0].split(" : ", 1)[-1], ordre_code))
    for lettre, mots in LIMITES_REFERENCE:
        marque = "- **limite (%s)**" % lettre
        lignes = [l for l in section if l.startswith(marque)]
        if len(lignes) != 1:
            ecarts.append("ECART limite (%s) : %d ligne(s) `%s` (attendu 1, chacune sur sa propre ligne)" % (lettre, len(lignes), marque))
            continue
        manque = [m for m in mots if m not in lignes[0]]
        if manque:
            ecarts.append("ECART limite (%s) : mots-clés absents de sa ligne : %s" % (lettre, manque))
    return ecarts


def remplacer_ligne_reference(texte, marque, fonction):
    lignes = texte.split("\n")
    idx = [i for i, l in enumerate(lignes) if l.startswith(marque)]
    if len(idx) != 1:
        return texte
    if fonction is None:
        del lignes[idx[0]]
    else:
        lignes[idx[0]] = fonction(lignes[idx[0]])
    return "\n".join(lignes)


def sec_reference(ctx):
    chemin = os.path.normpath(os.path.join(ctx.scripts_dir, "..", "references", "modele-cycles.md"))
    if not os.path.isfile(chemin):
        ko("R-REFERENCE", "la référence du modèle est lisible à côté du module", chemin, "absente")
        return
    ns = charger_module(ctx.hook)
    texte_hook = open(ctx.hook, encoding="utf-8").read()
    canaris = canaris_par_gate(open(os.path.join(ctx.scripts_dir, "check-gates-alive.sh"), encoding="utf-8").read())
    if not ctx.hooks_json:
        ko("R-REFERENCE", "hooks.json est lisible (matcher et commande enregistrée)", "hooks.json", "absent")
        return
    donnees = json.load(open(ctx.hooks_json, encoding="utf-8"))
    matchers = [g["matcher"] for g in donnees["hooks"]["PreToolUse"] if any("planning-hook.sh" in h.get("command", "") for h in g["hooks"])]
    if len(matchers) != 1 or not ctx.cmd:
        ko("R-REFERENCE", "une seule entrée PreToolUse porte planning-hook.sh", "1", str(len(matchers)))
        return

    def controler(fichier, ns_=ns):
        return ecarts_reference(open(fichier, encoding="utf-8").read(), ns_, texte_hook, canaris, ctx.cmd, matchers[0])

    ecarts = controler(chemin)
    if ecarts:
        for e in ecarts:
            print(e)
        ko("R-REFERENCE", "la référence est identique au hook livré, à la commande enregistrée et au canary (aucun écart)", "aucun écart", "%d écart(s)" % len(ecarts))
        return
    ok("R-REFERENCE la table d'armement (six gates : état, étape, cas de canary, relevé), les noms protégés par G6, le journal de dérogation, les marqueurs de code, l'ordre de résolution, les outils refusés et laissés ouverts en mode dégradé et les %d limites déclarées (a) à (aq) sont ceux du code livré ; la présence de la phrase « Aucun gate n'est armé » suit l'état d'armement du code" % len(LIMITES_REFERENCE))
    original = open(chemin, encoding="utf-8").read()

    def mutant_texte(ident, fonction, motif):
        copie = ctx.unique("reference-" + ident.lower()) + ".md"
        texte = fonction(original)
        if texte == original:
            komut("REFERENCE-" + ident, "mutant de la référence (texte distinct)", "texte distinct", "NON OPPOSABLE (identique) : " + motif)
            return
        with open(copie, "w", encoding="utf-8") as fh:
            fh.write(texte)
        ecarts_m = controler(copie)
        if ecarts_m:
            okmut("REFERENCE-" + ident, "R-REFERENCE rougit · attendu (original) : aucun écart · obtenu (mutant, %s) : %d écart(s), premier : %s" % (motif, len(ecarts_m), ecarts_m[0].replace("ECART ", "écart : ", 1)))
        else:
            komut("REFERENCE-" + ident, "R-REFERENCE rougit sur la référence mutée (%s)" % motif, "au moins un écart", "aucun écart (le contrôle passe à vide)")

    mutant_texte("G6", lambda t: re.sub(r"^(\| G6 \| 1 \| )(observe|armed)", lambda m: m.group(1) + ("armed" if m.group(2) == "observe" else "observe"), t, count=1, flags=re.M),
                 "valeur de G6 inversée dans la table d'armement")
    mutant_texte("OUTIL", lambda t: remplacer_ligne_reference(t, "- **Outils refusés en mode dégradé**", lambda l: l.replace("`Agent`, ", "", 1)),
                 "`Agent` retiré de la liste des outils refusés en mode dégradé")
    mutant_texte("LIMITE-L", lambda t: remplacer_ligne_reference(t, "- **limite (l)**", None), "la ligne de la limite (l) retirée")
    # F-01 à F-08 (audit de sécurité final, 2026-10-01) : un mot-clé retiré de la ligne d'une limite ajoutée, sur une copie privée de la référence
    mutant_texte("LIMITE-AE-MOTCLE", lambda t: remplacer_ligne_reference(t, "- **limite (ae)**", lambda l: l.replace("MultiEdit", "MultiEd1t", 1)),
                 "le mot-clé MultiEdit retiré de la ligne de la limite (ae)")
    mutant_texte("LIMITE-AA-MOTCLE", lambda t: remplacer_ligne_reference(t, "- **limite (aa)**", lambda l: l.replace("GATE-03", "GATE-0x", 1)),
                 "le mot-clé GATE-03 retiré de la ligne de la limite (aa)")
    # Re-audit final tour 4 (2026-10-02) : un mot-clé retiré de la ligne de chacune des limites (al), (am), (an), sur une copie privée
    mutant_texte("LIMITE-AL-MOTCLE", lambda t: remplacer_ligne_reference(t, "- **limite (al)**", lambda l: l.replace("/.vol", "/.v0l")),
                 "le mot-clé /.vol retiré de la ligne de la limite (al)")
    mutant_texte("LIMITE-AM-MOTCLE", lambda t: remplacer_ligne_reference(t, "- **limite (am)**", lambda l: l.replace("fail-closed", "fail-open", 1)),
                 "le mot-clé fail-closed retiré de la ligne de la limite (am)")
    mutant_texte("LIMITE-AN-MOTCLE", lambda t: remplacer_ligne_reference(t, "- **limite (an)**", lambda l: l.replace("readlink", "readl1nk", 1)),
                 "le mot-clé readlink retiré de la ligne de la limite (an)")
    mutant_texte("PREFILTRE", lambda t: remplacer_ligne_reference(t, "- **Pré-filtre hors adhésion**", None),
                 "la ligne du pré-filtre hors adhésion retirée")
    mutant_texte("SCRIPTS", lambda t: remplacer_ligne_reference(t, "- **Scripts du hook protégés par G6**", lambda l: l.replace("`check-gates-alive.sh`", "`check-gates-alive.shx`", 1)),
                 "`check-gates-alive.sh` renommé dans la liste des scripts du hook protégés")
    mutant_texte("JOURNAL", lambda t: remplacer_ligne_reference(t, "- **Journal de dérogation**", lambda l: l.replace("derogations-gates.log", "derogations.log")),
                 "nom du journal de dérogation changé")
    mutant_texte("MARQUEURS", lambda t: remplacer_ligne_reference(t, "- **Marqueurs de projet de code (G7)**", lambda l: l.replace("`Gemfile`, ", "", 1)),
                 "`Gemfile` retiré des marqueurs de code")
    mutant_texte("ORDRE", lambda t: t.replace("lab, compte, plugin", "compte, lab, plugin", 1), "ordre de résolution lab/compte inversé")
    mutant_texte("CANARY", lambda t: re.sub(r"(\| G1 \| 2 \| (?:observe|armed) \| [^|]*\| )G1-sans-cadrage", r"\1G1-autre", t, count=1), "cas de canary de G1 renommé")
    # Chaque limite, retirée une à une : le contrôle doit nommer cette limite.
    non_tuees = []
    for lettre, _mots in LIMITES_REFERENCE:
        copie = ctx.unique("reference-limite-" + lettre) + ".md"
        texte = remplacer_ligne_reference(original, "- **limite (%s)**" % lettre, None)
        if texte == original:
            non_tuees.append(lettre + " (opposable : non)")
            continue
        with open(copie, "w", encoding="utf-8") as fh:
            fh.write(texte)
        if not any(("limite (%s)" % lettre) in e for e in controler(copie)):
            non_tuees.append(lettre)
    if non_tuees:
        komut("REFERENCE-LIMITES", "chaque limite (a) à (aq) retirée seule fait rougir R-REFERENCE en la nommant", "%d limites tuées" % len(LIMITES_REFERENCE),
              "non tuées : " + ", ".join(non_tuees))
    else:
        okmut("REFERENCE-LIMITES", "R-REFERENCE rougit · attendu (original) : aucun écart · obtenu (mutant) : chacune des %d limites déclarées retirée seule est nommée par le contrôle" % len(LIMITES_REFERENCE))
    # Côté code : une constante du hook change, la référence reste intacte.
    ns_mut = dict(ns)
    # Q-ARM (Willy, AskUserQuestion session principale, 2026-09-30) : la constante est INVERSÉE (observe <-> armed), jamais posée à une valeur
    # fixe : le mutant reste opposable quel que soit l'état d'armement courant.
    inverse = "observe" if ns["TABLE_ARMEMENT"]["G1"] == "armed" else "armed"
    ns_mut["TABLE_ARMEMENT"] = dict(ns["TABLE_ARMEMENT"], G1=inverse)
    ns_scripts = dict(ns)
    ns_scripts["SCRIPTS_HOOK_G6"] = tuple(ns["SCRIPTS_HOOK_G6"]) + ("autre-script.sh",)
    ecarts_s = controler(chemin, ns_scripts)
    if ecarts_s:
        okmut("REFERENCE-CODE-SCRIPTS", "R-REFERENCE rougit · attendu (original) : aucun écart · obtenu (mutant, un script ajouté à SCRIPTS_HOOK_G6 dans le code, référence intacte) : %d écart(s), premier : %s" % (len(ecarts_s), ecarts_s[0].replace("ECART ", "écart : ", 1)))
    else:
        komut("REFERENCE-CODE-SCRIPTS", "R-REFERENCE rougit quand un script protégé est ajouté dans le code sans la référence", "au moins un écart", "aucun écart")
    ecarts_c = controler(chemin, ns_mut)
    if ecarts_c:
        okmut("REFERENCE-CODE", "R-REFERENCE rougit · attendu (original) : aucun écart · obtenu (mutant, ARMEMENT_G1 inversé en %s dans le code, référence intacte) : %d écart(s), premier : %s" % (inverse, len(ecarts_c), ecarts_c[0].replace("ECART ", "écart : ", 1)))
    else:
        komut("REFERENCE-CODE", "R-REFERENCE rougit quand une constante du hook change sans la référence", "au moins un écart", "aucun écart")


SECTIONS = {
    "table": sec_table,
    "parseur": sec_parseur,
    "registre": sec_registre,
    "jeton": sec_jeton,
    "verdict": sec_verdict,
    "derog": sec_derog,
    "g2": sec_g2,
    "g5": sec_g5,
    "g6": sec_g6,
    "id": sec_id,
    "cang": sec_cang,
    "g1": sec_g1,
    "g7": sec_g7,
    "role": sec_role,
    "env": sec_env,
    "obs_env": sec_obs_env,
    "env_statique": sec_env_statique,
    "accord": sec_accord,
    "banc": sec_banc,
    "mutants": sec_mutants,
    "lota": sec_lota,
    "reference": sec_reference,
}


def main():
    global POSER_VERDICT_SH
    scripts_dir, hooks_json, banc, work, settings_lab = sys.argv[2:7]
    POSER_VERDICT_SH = os.path.join(scripts_dir, "poser-verdict.sh")
    ctx = Ctx(scripts_dir, hooks_json or None, work, settings_lab or None)
    ctx.banc = banc
    ctx.banc_recalc = sys.argv[7] if len(sys.argv) > 7 and sys.argv[7] else None
    if ctx.charger_commande() is None:
        ko("commande enregistrée", "la commande enregistrée est lisible (une seule entrée PreToolUse portant planning-hook.sh)",
           "1 commande", "introuvable dans " + str(hooks_json or settings_lab or "aucune source"))
        sys.exit(1)
    for nom in sys.argv[1].split(","):
        SECTIONS[nom](ctx)


main()
PY_AIDES_GATES_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie-gates.txt"
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$HOOKS_JSON" "$BANC" "$WORK" "$SETTINGS_LAB" "$BANC_RECALC" > "$out" 2>&1
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

[ -f "$HOOK" ] || ko "planning-hook.sh présent" "le script du hook central existe à côté des suites" "$HOOK" "absent"
[ -f "$BANC" ] || ko "gates-banc.txt présent" "le banc texte existe sous fixtures/" "$BANC" "absent"
[ -f "$RECALC" ] || ko "recalc-planning.sh présent" "le moteur de recalcul existe à côté du hook (contrôle croisé du parseur)" "$RECALC" "absent"

[ -f "$BANC_RECALC" ] || ko "recalc-planning-banc.txt présent" "le banc de la 44 existe sous fixtures/ (contrôle croisé de G1)" "$BANC_RECALC" "absent"

# VF_GATES_SECTIONS (facultatif, pour rejouer une partie de la suite pendant le développement) : liste de sections séparées
# par des virgules ; sans elle, toutes les sections tournent, dans l'ordre ci-dessous.
run_sections "${VF_GATES_SECTIONS:-table,parseur,registre,jeton,g2,g5,g6,id,cang,g1,g7,role,verdict,derog,env,obs_env,env_statique,accord,banc,mutants,lota,reference}"

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
