#!/usr/bin/env bash
# test-cloture-gates.sh — G3 et G4, les gates de clôture du hook central (Phase 46, 46-05 ; CLOT-01, CLOT-02, CLOT-03 ; P46-D-01, P46-D-03, P46-D-12).
# Le hook est rejoué PAR LA COMMANDE ENREGISTRÉE (lue dans hooks.json, sous /bin/sh -c), jamais par un appel direct au script (P45-D-20) ;
# les cas de gate tournent sur des COPIES à l'armement FORCÉ (`copie_forcee`), jamais sur l'état livré, qui change à chaque armement.
#
# Familles de G3 :
#   R-G3-01   copie observe : Write de CLOTURE.md d'une unité dont le PLAN.md voisin déclare un livrable absent -> silence, code 0, UNE ligne gate=G3
#   R-G3-02   copie armée : Write, Edit, NotebookEdit (fil principal et agent inconnu) -> UN deny `[planning-core] G3 :` qui nomme l'entrée ; livrable
#             vide, lien, dossier vide, dossier à .DS_Store seul, lien intermédiaire ; PLAN.md absent, sans ecrit: valide, ecrit: invalide ou qui
#             contient l'unité -> refus (unité indéterminée au modèle) ; casse ignorée ; unité de plan sous plans/ ; aucun chemin absolu ni « no such file »
#   R-G3-03   jumeaux qui passent (copie armée) : livrables présents et non vides (fichier, dossier, dossier avec .DS_Store) ; CLOTURE.md de style GSD,
#             de niveau cycle, nom d'unité invalide, CLOTURE.md.bak, livrable nommé CLOTURE.md hors .planning/ : jamais jugés ; lab dev : octet vide
#   R-G3-04   dérogation nominative G3 sur le chemin du CLOTURE.md (usage unique) ; erreur interne injectée : armée deny, observe ligne d'observation
#   R-G3-05   (A13, fix-46-a) livrable hors borne (2001 fichiers, fichier creux de BORNE_OCTETS_LIVRABLES + 1 octets, budget commun franchi par la seconde
#             entrée) -> UN deny G3 qui nomme la borne franchie et l'entrée, sans l'injonction de « produire » ; livrable absent : message générique inchangé
#   R-NFD-02  (A1, fix-46-a) copie armée : un nom d'unité en NFD rend la même sortie que sa forme NFC par chemin mixte, voie cwd (file_path relatif à un cwd NFD)
#             et lien à cible NFD ; dérogation inscrite avec --chemin en NFD (journal en NFC, écriture NFD citée) ; copie observe : une ligne, chemin NFC
#   R-PLAN-BORNE (A11, fix-46-a) PLAN.md de 1 Mio + 1 octet ou creux de 2 Gio -> UN deny G3 (CLOTURE.md) et UN deny G4 (SUMMARY.md) qui nomment
#             BORNE_LECTURE_PLAN ; PLAN.md d'exactement 1 Mio -> passe ; espion de lecture : `octets_plan_du_dossier` du hook jugé ne demande jamais
#             plus de BORNE_LECTURE_PLAN + 1 octets (durée du cas creux affichée, jamais assertée)
#   R-PLAN-BORNE-G2 (A11, complément, fix-46-a) G2 (`plans_ouverts` -> `lire_frontmatter_fichier(chemin, borne)`) lit le PLAN.md avec la même borne : espion de
#             lecture (jamais plus de BORNE_LECTURE_PLAN + 1 octets, PLAN.md creux de 2 Gio ignoré, PLAN.md d'exactement la borne rendu), hors-borne rendu
#             par la fonction, résultat identique à une lecture sans borne en deçà (CRLF, UTF-8 invalide) ; de bout en bout : borne + 1 octet avertit
#   R-LECTURE-BORNEE (A11, classe, fix-46-a tour 2) copie armée : TOUTE lecture d'un fichier du lab que l'agent contrôle est bornée par BORNE_LECTURE_FICHIER
#             (1 Mio, octets LUS) : CADRAGE.md de borne + 1 octets (ou creux de 2 Gio) -> UN deny G1 qui nomme la borne, jumeau d'exactement la borne -> passe ;
#             VERDICT.md posé par la VRAIE poser-verdict.sh puis complété à borne + 1 octets (ou creux) -> UN deny G4 qui nomme la borne, jumeau à la borne -> passe ;
#             VERDICT.md d'un juge (`planning-hook.sh --juges`) -> `sans_preuve` `verdict-hors-borne`, jumeau à la borne -> prouvé ; espion : `lire_octets_bornes`
#             du hook jugé rend `hors-borne` sur les deux fichiers creux sans jamais demander plus de borne + 1 octets
#   R-ADHESION-BORNEE (A11, classe) config.json de borne + 1 octets : adhésion indéterminée -> le cœur lancé directement sort en code 3 (stdout et stderr vides) sous
#             PreToolUse ; la commande enregistrée refuse par la couche de repli (« hook central indisponible », jamais le message de G1) dans un lab que son
#             grep dit adhérent, se tait sur Bash et sur SessionStart ; jumeau à la borne exacte : le cœur lit l'adhésion (deny G1, watchPaths) ; config.json dev
#             hors borne : silence (P46-D-16) ; config.json creux de 2 Gio : code 3 ; espion de `verifier_adhesion` et de `_appliquer_edit` (G6)
#   R-JOURNAUX-BORNES (A11, classe) journal des dérogations de borne + 1 octets : aucune dérogation lue (G3 maintient son refus, journal inchangé,
#             `derogation_active` appelée directement rend None), `consommer` rend False sans écrire, jumeau à la borne -> dérogation citée et consommée ;
#             `empreinte_fichier` de D1 ne lit jamais plus de BORNE_OCTETS_LIVRABLES octets + 1 Mio même devant un lecteur infini
# Familles de G4 (verdicts posés par la VRAIE poser-verdict.sh, jamais un hash écrit à la main sauf verdict volontairement faux) :
#   R-G4-01   copie observe : Write de SUMMARY.md sans VERDICT.md voisin -> silence, code 0, UNE ligne gate=G4
#   R-G4-02   copie armée : VERDICT.md absent, invalide (frontmatter, constats vides, résultat hors passé/échec, lien), constat en échec, PLAN.md
#             absent, ecrit: qui contient l'unité, livrables hors borne -> UN deny `[planning-core] G4 :` chacun, message distinct par cas
#   R-G4-03   verdict posé (tentative 2) puis un octet d'un livrable, le PLAN.md, `hash_livrables` retiré, un livrable supprimé -> « verdict périmé : re-juger
#             (tentative 3 sur 3, 0 restante(s) après elle) »
#   R-G4-04   jumeaux qui passent : verdict conforme, Write, Edit, NotebookEdit, seconde écriture d'une unité close, unité de plan ; style GSD, niveau
#             cycle, noms voisins jamais jugés ; lab dev : octet vide
#   R-G4-05   dérogation G4 sur le chemin du SUMMARY.md (usage unique) ; erreur interne injectée : armée deny, observe ligne d'observation
#   R-G4-06   aucun refus de G3 ou de G4 ne porte le chemin absolu du lab, « no such file » ni « can't open »
#   R-FORME-01 `unite_de_fichier` du hook et `forme_unite` de poser-verdict.sh rendent la même unité sur un lot de chemins (copies ast chargées du texte)
#   BANC      fixtures/cloture-banc.txt : onze labs adhérents et leurs onze jumeaux `-dev`, chaque écriture rejouée sur copie armée ; COUVERTURE G3, G4 (au moins
#             quatre doit-refuser et quatre doit-passer réellement joués par gate) ; COMPTE G3, COMPTE G4 : faux-refus=0 faux-accept=0
#   R-BANC-NFD (A1, fix-46-a) chaque écriture du banc dont le chemin porte un caractère composable (labs cl-nfc et cl-nfc-dev, noms en NFC) est rejouée sur copie
#             armée dans deux matérialisations fraîches, sous sa forme NFC et sous son jumeau NFD : mêmes code, stdout et stderr ; COUVERTURE NFD (au moins un
#             refus et un passage par gate, un silence) ; une différence nomme « jumeau NFD », l'écriture et les deux décisions
#             A1-readdir (fix-46-a tour 2) : chaque lab qui porte un nom d'unité composable (cl-nfc et cl-nfc-dev) est AUSSI matérialisé au disque NFD (noms du
#             disque décomposés, `materialiser_disque_nfd`) ; SessionStart (`source: startup`, copie armée) y rend, pour D1, la même liste surveillée que sur le
#             disque NFC (chemins relatifs en NFC, même ordre, plus de cinq chemins dont un au moins en forme de disque NFD) et les MÊMES (genre, chemin) au
#             journal de D1, ENTIER, sur tout système : les verdicts du banc sont posés par la vraie poser-verdict.sh sur les DEUX disques (fix-46-a tour 3 ; un
#             écart nomme les lignes d'un seul côté) ; le jumeau dev se tait ; un lab d'égalité de préfixe (`05-côté`, `05-cz`) rend `05-côté` avant `05-cz` des deux côtés (nom NFC
#             décroissant) ; sur un système insensible à la normalisation (APFS, HFS+) seulement, chaque écriture G3/G4 composable est rejouée sur le disque NFD
#             sous les deux formes de charge utile (même sortie que la référence), sinon une ligne `~` qui nomme la limite (bf)
#   R-CROISE-01 preuve croisée d'un seul prédicat : pour chaque unité du banc, G3 sur l'écriture de son CLOTURE.md et l'état rendu par recalc-planning.sh
#             --read-only (R4 : livrable-absent:, livrable-vide:… ou PLAN.md indéterminé) concordent ; une discordance est imprimée nommément
# Mutants (chacun tué par un contrôle, trace assertion · attendu (original) · obtenu (mutant)) :
#   MUT-G3-LIVRABLE (contrôle du statut neutralisé -> R-G3-02), MUT-G3-FORME (forme élargie à tout CLOTURE.md sous .planning/ -> R-G3-03),
#   MUT-G3-ADHESION (adhésion forcée vraie, commande sans pré-filtre -> jumeau lab dev de R-G3-03), MUT-PLAN-BORNE-TEST (test de la borne neutralisé),
#   MUT-PLAN-LECTURE (lecture sans borne) -> R-PLAN-BORNE, MUT-G3-BORNE-MESSAGE (branche `borne` neutralisée -> R-G3-05), MUT-NFD-CHEMIN (normalisation NFC
#   des composants retirée -> R-BANC-NFD), MUT-PLAN-G2-BORNE (G2 appelle `lire_frontmatter_fichier` sans borne), MUT-PLAN-G2-LECTURE (lecture sans borne dans
#   la fonction), MUT-PLAN-G2-HORS-BORNE (test de la borne neutralisé dans la fonction) -> R-PLAN-BORNE-G2 ;
#   MUT-READDIR-NFC (le nom lu par readdir sans NFC dans `_sous_dossiers` : l'unité au nom de disque NFD disparaît de la liste surveillée de D1) et
#   MUT-RECENCE-NFC (`cle_recence` sans NFC : `05-côté` du disque NFD passe après `05-cz`) -> R-BANC-NFD (A1-readdir, fix-46-a tour 2) ;
#   A11-classe (fix-46-a tour 2) : MUT-BORNE-GENERIQUE (la borne générique retirée : tout est lu et accepté), MUT-G1-BORNE-CADRAGE, MUT-G4-BORNE-VERDICT,
#   MUT-JUGE-BORNE-VERDICT -> R-LECTURE-BORNEE ; MUT-ADHESION-BORNE (l'adhésion hors borne rendue non adhérente), MUT-ADHESION-INCONNUE (la clause de
#   `main` retirée : la décision dans le doute refuse en code 0) -> R-ADHESION-BORNEE ; MUT-DEROG-BORNE (`derogation_active` lit au-delà de la borne,
#   appel direct), MUT-DEROG-VERROU (`consommer` lit au-delà), MUT-D1-LECTURE-HACHAGE (le compteur de `empreinte_fichier` retiré) -> R-JOURNAUX-BORNES ;
#   MUT-PLAN-G2-BORNE est RE-CIBLÉ (tour 2) : le défaut de `lire_frontmatter_fichier` valant désormais BORNE_LECTURE_PLAN, retirer la borne explicite est
#   devenu un mutant ÉQUIVALENT ; il relâche la borne (2 * BORNE_LECTURE_PLAN) et reste tué par R-PLAN-BORNE-G2 ;
#   MUT-G4-ABSENT, MUT-G4-ECHEC, MUT-G4-PLAFOND-MESSAGE (F6, fix-46-c) (-> R-G4-02), MUT-G4-HASH, MUT-G4-HASH-LIVRABLES (-> R-G4-03), MUT-G4-FAILOPEN (sonde d'erreur rendue silencieuse pour G4
#   dans evaluer_protege -> R-G4-05) ; MUT-CROISE (la copie du prédicat du hook seule rendue plus laxiste sur « vide » -> R-CROISE-01).
# Variables : VF_CLOT_SECTIONS=<liste> pour ne rejouer qu'une partie (sections : g3, g4, forme, banc, croise, mutants_g3, mutants_g4, mutants_croise).
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; `cmp -s` jamais `diff` ; tout le travail fin est fait par
# Python (PYBIN). Lançable depuis tout cwd. Piège CI (`bash -e {0}`) : jamais `cmd && { … }` nu.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
HOOK="$SCRIPTS_DIR/planning-hook.sh"
HOOKS_JSON="$SCRIPTS_DIR/../hooks/hooks.json"
SETTINGS_LAB="$SCRIPTS_DIR/../settings.json"
BANC="$TESTS_DIR/fixtures/cloture-banc.txt"
[ -f "$HOOKS_JSON" ] || HOOKS_JSON=""
[ -f "$SETTINGS_LAB" ] || SETTINGS_LAB=""
[ -f "$BANC" ] || BANC=""

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
import types
import unicodedata
import urllib.parse

TOKEN = "{{VF_SCRIPTS}}"
UNITE = ".planning/cycles/01-c/phases/01-p"
CLOTURE = UNITE + "/CLOTURE.md"
UNITE_PLAN = UNITE + "/plans/01-a"
CLOTURE_PLAN = UNITE_PLAN + "/CLOTURE.md"
LIVRABLE = "livrables/rapport.md"
SUMMARY = UNITE + "/SUMMARY.md"
SUMMARY_PLAN = UNITE_PLAN + "/SUMMARY.md"
VERDICT = UNITE + "/VERDICT.md"


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


def jumeau_nfd(texte):
    """Forme NFD, composant par composant (séparateur `/`), d'un chemin, d'un cwd ou d'une commande : égale au texte s'il ne porte aucun
    caractère composable (dans ce cas, aucun jumeau)."""
    return "/".join(unicodedata.normalize("NFD", c) for c in texte.split("/"))


def disque_insensible(ctx):
    """Vrai si le système de fichiers du dossier de travail est insensible à la normalisation (APFS, HFS+) : un dossier créé sous un nom NFC se
    retrouve sous son nom NFD. Calculé une fois."""
    if getattr(ctx, "_insensible", None) is None:
        d = ctx.unique("sonde-normalisation")
        os.makedirs(os.path.join(d, "é"))
        ctx._insensible = os.path.isdir(os.path.join(d, "é"))
    return ctx._insensible


def _lignes_seules(lignes):
    """Les éléments (genre, chemin) présents d'un seul côté, triés, trois au plus (le reste compté) ; `-` s'il n'y en a aucun."""
    triees = sorted(lignes)
    return ", ".join("%s %s" % (g, c) for g, c in triees[:3]) + (" …(+%d)" % (len(triees) - 3) if len(triees) > 3 else "") if triees else "-"


def relatifs_nfc(chemins, lab):
    """Les chemins (absolus) rendus relatifs au lab, chaque composant en NFC, l'ordre conservé. Le hook rend des chemins résolus physiquement : l'appelant passe
    la racine du lab résolue (`os.path.realpath`)."""
    return [unicodedata.normalize("NFC", os.path.relpath(p, lab)) for p in chemins]


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
        self.originaux = {}   # résultat des contrôles sur le script réel, calculé une fois (les mutants le comparent)
        self.memo = {}        # écritures du banc déjà rejouées : (dossier du hook, lab, outil, chemin, agent) -> (rc, stdout, stderr)
        self._ns = {}
        self._banc = None
        self.banc = None
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


def session(ctx, dossier_hook, lab):
    """SessionStart (`source: startup`) d'un lab, rejoué par la commande enregistrée avec le script du dossier donné ; (rc, stdout, stderr)."""
    brut = json.dumps({"session_id": "sess-test", "transcript_path": "transcript.jsonl", "cwd": lab, "hook_event_name": "SessionStart", "source": "startup"},
                      separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return ctx.lancer(brut, cwd=lab, dossier=dossier_hook)


def surveilles_de(out):
    """Liste de `hookSpecificOutput.watchPaths` d'un SessionStart ; [] si la sortie est vide ; None si elle n'est pas conforme."""
    if out == b"":
        return []
    try:
        liste = json.loads(out.decode("utf-8"))["hookSpecificOutput"]["watchPaths"]
    except (ValueError, KeyError, TypeError, AttributeError):
        return None
    return liste if isinstance(liste, list) else None


def journal_d1(lab):
    """Ensemble des (genre, chemin décodé) des lignes de `.planning/surveillance.log` d'un lab (vide si le journal est absent)."""
    chemin = os.path.join(lab, ".planning", "surveillance.log")
    if not os.path.isfile(chemin):
        return set()
    res = set()
    for ligne in open(chemin, encoding="utf-8").read().split("\n"):
        m = re.match(r"^\S+  genre=(\S+)  chemin=(\S+)  ", ligne)
        if m:
            res.add((m.group(1), urllib.parse.unquote(m.group(2))))
    return res


def deroger(ctx, lab, gate, chemins):
    args = ["--lab=" + lab, "--gate=" + gate] + ["--chemin=" + c for c in chemins]
    args += ["--qui=willy", "--canal=AskUserQuestion session principale", "--date=2026-10-05", "--raison=cas de test de la dérogation"]
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
    return _refus_gate(ctx, "G3", d, lab, outil, rel, agent)


def _refus_g4(ctx, d, lab, outil, rel, agent=None):
    return _refus_gate(ctx, "G4", d, lab, outil, rel, agent)


def _refus_gate(ctx, gate, d, lab, outil, rel, agent=None):
    """(conforme, détail, raison) : UN objet deny, `[planning-core] <gate> :`, journal d'observation vide."""
    cache = dossier_neuf(ctx, "cache-" + gate.lower() + "-refus")
    rc, out, err = ecrire_dans(ctx, d, lab, outil, rel, agent=agent, extra_env={"XDG_CACHE_HOME": cache})
    v = classer(rc, out)
    if v != "deny" or err or len(out.splitlines()) != 1:
        return False, "%s stderr=%s %s" % (v, court(err), court(out)), ""
    raison = raison_de(out)
    if not raison.startswith("[planning-core] %s :" % gate):
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


# --- A11 (fix-46-a) : lecture du PLAN.md de l'unité bornée par G3 et G4 -------------------------------------------------------
def espace_du_hook(ctx, dossier):
    """Espace de noms du corps Python du hook DU DOSSIER donné (le hook jugé, réel ou mutant : `espace(ctx, "hook")` lit toujours le hook réel), sans
    l'appel final à main()."""
    cle = ("hook-jugé", dossier)
    if cle not in ctx._ns:
        chemin = os.path.join(dossier, "planning-hook.sh")
        arbre = ast.parse(corps_python(open(chemin, encoding="utf-8").read()))
        arbre.body = [n for n in arbre.body if not (isinstance(n, ast.Expr) and isinstance(n.value, ast.Call) and getattr(n.value.func, "id", "") == "main")]
        ns = {"__name__": "bloc_charge_cloture"}
        exec(compile(arbre, chemin, "exec"), ns)
        ctx._ns[cle] = ns
    return ctx._ns[cle]


class _FichierEspion:
    """Enveloppe d'un fichier ouvert par `os.fdopen` : consigne chaque `read(n)` ; une lecture sans borne (`read()`, n < 0, n au-delà de la borne) est
    consignée puis ramenée à `borne + 1` octets (la mémoire du test reste bornée, même devant un hook fautif)."""

    def __init__(self, fichier, lectures, borne):
        self._fichier, self._lectures, self._borne = fichier, lectures, borne

    def __enter__(self):
        self._fichier.__enter__()
        return self

    def __exit__(self, *args):
        return self._fichier.__exit__(*args)

    def fileno(self):
        return self._fichier.fileno()

    def read(self, n=-1):
        self._lectures.append(n)
        if n is None or n < 0 or n > self._borne + 1:
            return self._fichier.read(self._borne + 1)
        return self._fichier.read(n)


class _OsEspion:
    """Le module `os` du hook, à l'identique, sauf `fdopen` qui rend un `_FichierEspion`."""

    def __init__(self, reel, lectures, borne):
        self._reel, self._lectures, self._borne = reel, lectures, borne

    def __getattr__(self, nom):
        return getattr(self._reel, nom)

    def fdopen(self, descripteur, *args, **kw):
        return _FichierEspion(self._reel.fdopen(descripteur, *args, **kw), self._lectures, self._borne)


def _remplissage(octets, debut="<!-- ", fin=" -->\n"):
    """EXACTEMENT `octets` octets (ASCII) de lignes de commentaire `debut` + « remplissage » + `fin`, l'octet exact ajusté sur la dernière ligne."""
    ligne = debut + "remplissage" + fin
    if octets == 0:
        return ""
    if octets < 2 * len(ligne):
        raise RuntimeError("remplissage de %d octets impossible (minimum %d)" % (octets, 2 * len(ligne)))
    n = octets // len(ligne) - 1
    dernier = octets - n * len(ligne)
    texte = ligne * n + debut + "r" * (dernier - len(debut) - len(fin)) + fin
    if len(texte.encode("utf-8")) != octets:
        raise RuntimeError("remplissage de %d octets mal construit : %d" % (octets, len(texte.encode("utf-8"))))
    return texte


def _fichier_de_taille(entete, taille):
    """Texte de EXACTEMENT `taille` octets : `entete` en tête, puis des lignes de commentaire Markdown, l'octet exact ajusté sur la dernière ligne."""
    return entete + _remplissage(taille - len(entete.encode("utf-8")))


def _completer(chemin, taille, debut="<!-- ", fin=" -->\n"):
    """Complète le fichier EXISTANT `chemin` jusqu'à EXACTEMENT `taille` octets par des lignes de commentaire (`<!-- remplissage -->`, ou `# remplissage` pour
    le journal), sans toucher à ses premiers octets (ajout en fin de fichier)."""
    existant = os.path.getsize(chemin)
    with open(chemin, "rb") as fh:
        fh.seek(max(0, existant - 1))
        fin_de_ligne = fh.read(1) == b"\n" if existant else True
    ajout = ("" if fin_de_ligne else "\n") + _remplissage(taille - existant - (0 if fin_de_ligne else 1), debut, fin)
    with open(chemin, "ab") as fh:
        fh.write(ajout.encode("utf-8"))
    if os.path.getsize(chemin) != taille:
        raise RuntimeError("%s : %d octets, attendu %d" % (chemin, os.path.getsize(chemin), taille))


def _plan_de_taille(taille):
    """PLAN.md de EXACTEMENT `taille` octets : frontmatter valide en tête (`ecrit: livrables/rapport.md`), puis des lignes de commentaire Markdown, l'octet
    exact ajusté sur la dernière ligne."""
    return _fichier_de_taille("---\necrit: " + LIVRABLE + "\n---\n", taille)


def coeur(ctx, dossier, lab, brut, args=()):
    """Le cœur LANCÉ DIRECTEMENT (`bash <dossier>/planning-hook.sh`), sans la couche de repli, charge utile sur stdin, cwd le lab ; (rc, stdout, stderr)."""
    p = subprocess.run(["bash", os.path.join(dossier, "planning-hook.sh")] + list(args), input=brut, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       env=ctx.env(), cwd=lab, timeout=120)
    return p.returncode, p.stdout, p.stderr


def controle_plan_borne(ctx, script):
    """Copie armée : PLAN.md de BORNE_LECTURE_PLAN + 1 octets (frontmatter valide en tête, livrable présent, verdict posé par la vraie commande) -> UN deny G3
    (CLOTURE.md) et UN deny G4 (SUMMARY.md) dont la raison nomme BORNE_LECTURE_PLAN et 1048576 ; jumeau d'EXACTEMENT BORNE_LECTURE_PLAN octets -> passe ;
    PLAN.md creux de 2 Gio -> deny G3 qui nomme la borne (durée affichée, jamais assertée) ; espion : `octets_plan_du_dossier` du hook jugé rend `hors-borne`
    sur le creux et ne demande jamais une lecture de plus de BORNE_LECTURE_PLAN + 1 octets."""
    dossier_jugé = _dossier(ctx, script)
    d = ctx.copie_forcee(dossier_jugé, "armed")
    ns = espace_du_hook(ctx, dossier_jugé)
    borne = ns.get("BORNE_LECTURE_PLAN", 1048576)
    fautes = []

    def refus(nom, gate, lab, rel):
        bon, detail, raison = _refus_gate(ctx, gate, d, lab, "Write", rel)
        if not bon:
            fautes.append("%s : %s" % (nom, detail))
            return
        for fragment in ("BORNE_LECTURE_PLAN", "1048576"):
            if fragment not in raison:
                fautes.append("%s : la raison ne nomme pas %s : %s" % (nom, fragment, raison))
                return
        fautes.extend("%s : %s" % (nom, f) for f in fautes_de_message(raison, lab))

    def passe(nom, lab, rel):
        rc, out, err = ecrire_dans(ctx, d, lab, "Write", rel)
        v = classer(rc, out)
        if v not in ("silence", "avertit") or err:
            fautes.append("%s : %s %s" % (nom, v, court(out)))

    # 1. borne + 1 octets : refus de G3 et de G4 qui nomment la borne
    lab = lab_g4(ctx, "plan-borne-plus1", plan=_plan_de_taille(1048576 + 1))
    refus("PLAN.md de 1 Mio + 1 octet, G3", "G3", lab, CLOTURE)
    refus("PLAN.md de 1 Mio + 1 octet, G4", "G4", lab, SUMMARY)
    # 2. jumeau à la borne : EXACTEMENT 1 Mio -> passe
    lab = lab_g4(ctx, "plan-borne-exact", plan=_plan_de_taille(1048576))
    passe("PLAN.md d'exactement 1 Mio, G3", lab, CLOTURE)
    passe("PLAN.md d'exactement 1 Mio, G4", lab, SUMMARY)
    # 3. PLAN.md creux de 2 Gio : frontmatter écrit puis `truncate`
    lab = fabriquer_lab(ctx, "plan-borne-creux", plan="---\necrit: " + LIVRABLE + "\n---\n", fichiers={LIVRABLE: "contenu\n"})
    plan_creux = os.path.join(lab, UNITE, "PLAN.md")
    os.truncate(plan_creux, 2 * 1024 ** 3)
    debut = time.monotonic()
    refus("PLAN.md creux de 2 Gio, G3", "G3", lab, CLOTURE)
    print("DUREE plan-creux-2gio s=%.1f (affichée, jamais assertée)" % (time.monotonic() - debut))
    # 4. espion : la lecture du hook jugé ne dépasse jamais borne + 1 octets
    lectures = []
    ns_espion = dict(ns)
    ns_espion["os"] = _OsEspion(os, lectures, borne)
    fonction = types.FunctionType(ns["octets_plan_du_dossier"].__code__, ns_espion)
    resultat = fonction(os.path.join(lab, UNITE))
    statut = resultat[0] if isinstance(resultat, tuple) else ("ok" if resultat else "illisible")
    if statut != "hors-borne":
        fautes.append("espion : octets_plan_du_dossier rend %r sur le PLAN.md creux de 2 Gio (attendu hors-borne)" % (statut,))
    if not lectures or any(n is None or not 0 < n <= borne + 1 for n in lectures):
        fautes.append("espion : lecture non bornée, read(n) demandés : %s (attendu 0 < n <= %d)" % (lectures, borne + 1))
    lectures_jumeau = []
    ns_jumeau = dict(ns)
    ns_jumeau["os"] = _OsEspion(os, lectures_jumeau, borne)
    fonction = types.FunctionType(ns["octets_plan_du_dossier"].__code__, ns_jumeau)
    lab_exact = ctx.unique("plan-borne-espion")
    ecrire(os.path.join(lab_exact, UNITE, "PLAN.md"), _plan_de_taille(borne))
    resultat = fonction(os.path.join(lab_exact, UNITE))
    if not (isinstance(resultat, tuple) and resultat[0] == "ok" and len(resultat[1]) == borne):
        fautes.append("espion : le PLAN.md d'exactement %d octets n'est pas rendu ('ok', octets) : %s" % (borne, court(str(resultat))))
    if any(n is None or not 0 < n <= borne + 1 for n in lectures_jumeau):
        fautes.append("espion, jumeau : lecture non bornée, read(n) demandés : %s" % lectures_jumeau)
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "PLAN.md de 1 Mio + 1 octet et PLAN.md creux de 2 Gio : UN deny G3 et UN deny G4 qui nomment BORNE_LECTURE_PLAN (1048576) ; PLAN.md "
                          "d'exactement 1 Mio : G3 et G4 passent ; espion : hors-borne rendu sans lecture de plus de %d octets" % (borne + 1))


# --- A11, complément (fix-46-a) : G2 lit aussi le PLAN.md de l'unité (`plans_ouverts` -> `lire_frontmatter_fichier`) : sa lecture est bornée ------
def controle_plan_borne_g2(ctx, script):
    """Copie armée et espion : `plans_ouverts` du hook jugé (G2) lit le PLAN.md d'une unité ouverte par `lire_frontmatter_fichier(chemin, borne)` ; sur un
    PLAN.md creux de 2 Gio il ne demande jamais une lecture de plus de BORNE_LECTURE_PLAN + 1 octets et IGNORE ce plan (fail-open de G2, spec §5.1, comme tout
    PLAN.md au frontmatter illisible) ; sur un PLAN.md d'exactement BORNE_LECTURE_PLAN octets il le rend ; `lire_frontmatter_fichier` rend
    `invalide:hors-borne` au-delà de la borne — SANS borne explicite aussi (tour 2, A11-classe : la borne générique BORNE_LECTURE_FICHIER s'applique) — et, sous
    la borne, le même résultat avec ou sans borne explicite (y compris pour des fins de ligne CRLF) ; de
    bout en bout, l'écriture d'un livrable déclaré par un PLAN.md de borne + 1 octet n'est plus couverte (avertissement de G2), celle d'un PLAN.md d'exactement
    la borne l'est (silence)."""
    dossier_jugé = _dossier(ctx, script)
    d = ctx.copie_forcee(dossier_jugé, "armed")
    ns = espace_du_hook(ctx, dossier_jugé)
    borne = ns.get("BORNE_LECTURE_PLAN", 1048576)
    fautes = []

    def plans_espionnes(lectures):
        """`plans_ouverts`, `lire_frontmatter_fichier` et `lire_octets_bornes` du hook jugé (la lecture vit dans le dernier depuis le tour 2, A11-classe),
        reconstruits sur un espace de noms dont `os.fdopen` consigne les `read(n)`."""
        ns_e = dict(ns)
        ns_e["os"] = _OsEspion(os, lectures, borne)
        for nom in ("lire_octets_bornes", "lire_frontmatter_fichier", "plans_ouverts"):
            f = ns.get(nom)
            if f is not None:
                ns_e[nom] = types.FunctionType(f.__code__, ns_e, f.__name__, f.__defaults__)
        return ns_e["plans_ouverts"]

    # 1. espion, PLAN.md creux de 2 Gio : lecture bornée, plan ignoré
    lab = fabriquer_lab(ctx, "plan-borne-g2-creux", plan="---\necrit: " + LIVRABLE + "\n---\n", fichiers={LIVRABLE: "contenu\n"})
    os.truncate(os.path.join(lab, UNITE, "PLAN.md"), 2 * 1024 ** 3)
    lectures = []
    debut = time.monotonic()
    plans = plans_espionnes(lectures)(lab)
    print("DUREE g2-plans-ouverts-creux-2gio s=%.1f (affichée, jamais assertée)" % (time.monotonic() - debut))
    if plans:
        fautes.append("espion, creux : plans_ouverts rend %s (attendu : le PLAN.md hors borne est ignoré)" % court(str(plans)))
    if not lectures or any(n is None or not 0 < n <= borne + 1 for n in lectures):
        fautes.append("espion, creux : lecture non bornée, read(n) demandés : %s (attendu 0 < n <= %d)" % (lectures, borne + 1))
    # 2. espion, PLAN.md d'exactement la borne : rendu
    lab_exact = fabriquer_lab(ctx, "plan-borne-g2-exact", plan=_plan_de_taille(borne), fichiers={LIVRABLE: "contenu\n"})
    lectures_exact = []
    plans = plans_espionnes(lectures_exact)(lab_exact)
    if not (len(plans) == 1 and plans[0][1] == [LIVRABLE]):
        fautes.append("espion, jumeau à la borne : plans_ouverts rend %s (attendu : un plan, entrée %s)" % (court(str(plans)), LIVRABLE))
    if any(n is None or not 0 < n <= borne + 1 for n in lectures_exact):
        fautes.append("espion, jumeau à la borne : lecture non bornée, read(n) demandés : %s" % lectures_exact)
    # 3. la fonction elle-même : hors-borne au-delà, SANS borne explicite aussi (la borne générique), même résultat avec et sans borne en deçà (CRLF compris)
    lff_reel = ns["lire_frontmatter_fichier"]

    def lff(chemin, *borne_optionnelle):
        try:
            return lff_reel(chemin, *borne_optionnelle)
        except TypeError as exc:  # le code d'avant n'accepte pas de borne : une faute nommée, jamais un plantage du contrôle
            fautes.append("lire_frontmatter_fichier n'accepte pas de borne : %s" % exc)
            return ("erreur", {})

    plus1 = os.path.join(fabriquer_lab(ctx, "plan-borne-g2-plus1", plan=_plan_de_taille(borne + 1)), UNITE, "PLAN.md")
    rendu = lff(plus1, borne)
    if rendu != ("invalide:hors-borne", {}):
        fautes.append("lire_frontmatter_fichier(PLAN.md de borne + 1 octets, borne) rend %s (attendu ('invalide:hors-borne', {}))" % court(str(rendu)))
    rendu_defaut = lff(plus1)
    if rendu_defaut != ("invalide:hors-borne", {}):
        fautes.append("lire_frontmatter_fichier SANS borne explicite sur un PLAN.md de borne + 1 octets rend %s (attendu ('invalide:hors-borne', {}) : la borne "
                      "générique BORNE_LECTURE_FICHIER s'applique)" % court(str(rendu_defaut)))
    crlf = ctx.unique("plan-borne-g2-crlf")
    ecrire(os.path.join(crlf, "PLAN.md"), "---\r\necrit: " + LIVRABLE + "\r\n---\r\nPlan.\r\n")
    avec, sans = lff(os.path.join(crlf, "PLAN.md"), borne), lff(os.path.join(crlf, "PLAN.md"))
    if avec != sans or avec[0] != "ok":
        fautes.append("lire_frontmatter_fichier : avec borne %s, sans borne %s (attendu : identiques, ok)" % (court(str(avec)), court(str(sans))))
    invalide = ctx.unique("plan-borne-g2-utf8")
    os.makedirs(invalide, exist_ok=True)
    with open(os.path.join(invalide, "PLAN.md"), "wb") as fh:
        fh.write(b"---\necrit: \xff\xfe\n---\n")
    if lff(os.path.join(invalide, "PLAN.md"), borne)[0] != "invalide:illisible" or lff(os.path.join(invalide, "PLAN.md"))[0] != "invalide:illisible":
        fautes.append("lire_frontmatter_fichier : un PLAN.md qui n'est pas de l'UTF-8 n'est pas rendu invalide:illisible avec et sans borne")
    # 4. de bout en bout (copie armée) : le PLAN.md de borne + 1 octet ne couvre plus son livrable, celui d'exactement la borne le couvre
    lab_plus1 = fabriquer_lab(ctx, "plan-borne-g2-e2e-plus1", plan=_plan_de_taille(borne + 1), fichiers={LIVRABLE: "contenu\n"})
    rc, out, err = ecrire_dans(ctx, d, lab_plus1, "Write", LIVRABLE)
    if classer(rc, out) != "avertit" or err or "[planning-core] G2" not in out.decode("utf-8", "replace"):
        fautes.append("bout en bout, borne + 1 octet : %s %s (attendu un avertissement de G2 : le plan hors borne est ignoré)" % (classer(rc, out), court(out)))
    rc, out, err = ecrire_dans(ctx, d, lab_exact, "Write", LIVRABLE)
    if classer(rc, out) != "silence" or err:
        fautes.append("bout en bout, exactement la borne : %s %s (attendu silence : le plan couvre son livrable)" % (classer(rc, out), court(out)))
    debut = time.monotonic()
    rc, out, err = ecrire_dans(ctx, d, lab, "Write", LIVRABLE)
    print("DUREE g2-ecriture-plan-creux-2gio s=%.1f (affichée, jamais assertée)" % (time.monotonic() - debut))
    if classer(rc, out) not in ("avertit", "silence") or err:
        fautes.append("bout en bout, PLAN.md creux de 2 Gio : %s %s (attendu : pas d'échec, le plan est ignoré)" % (classer(rc, out), court(out)))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "G2 (plans_ouverts) : PLAN.md creux de 2 Gio ignoré sans lecture de plus de %d octets, PLAN.md d'exactement %d octets rendu, hors-borne rendu par "
                          "lire_frontmatter_fichier au-delà et même résultat qu'une lecture sans borne en deçà (CRLF, UTF-8 invalide) ; de bout en bout : borne + 1 octet "
                          "avertit, exactement la borne couvre" % (borne + 1, borne))


# --- A11, classe (fix-46-a tour 2) : toute lecture d'un fichier du lab contrôlé par l'agent est bornée -----------------------------------------------
def _def_juge(nom):
    """Définition d'un JUGE (rôle dérivé `juge` : Write et Edit retirés) — recette de test-juges-canary.sh."""
    return "---\nname: %s\ndescription: juge synthétique d'un cas de test, jamais exécuté\ndisallowedTools: Write, Edit\n---\nCorps.\n" % nom


def _texte_sortie_piegee(juge, critere):
    """SORTIE-PIEGEE.md d'un juge — recette de test-juges-canary.sh."""
    return ("---\njuge: %s\ncritere_vise: %s\nprovenance: exemple raté fabriqué à la main pour un cas de test\n---\n\n# Sortie piégée\n\n"
            "Un rapport qui viole délibérément le critère %s.\n" % (juge, critere, critere))


def _lab_juge(ctx, nom):
    """(lab, chemin du VERDICT.md du juge `juge-x`) : lab adhérent au chemin physique, définition du juge, sortie piégée visant `critere-x` et verdict de
    canary posé par la VRAIE poser-verdict.sh (`critere-x::échec`, `critere-y::passé`)."""
    lab = os.path.realpath(fabriquer_lab(ctx, nom))
    ecrire(os.path.join(lab, ".claude", "agents", "juge-x.md"), _def_juge("juge-x"))
    ecrire(os.path.join(lab, ".planning", "juges", "juge-x", "SORTIE-PIEGEE.md"), _texte_sortie_piegee("juge-x", "critere-x"))
    args = ["bash", os.path.join(ctx.scripts_dir, "poser-verdict.sh"), "--unite=" + os.path.join(lab, ".planning", "juges", "juge-x"), "--juge=juge-x",
            "--tentative=1", "--score=8/10", "--constat=critere-x::échec", "--constat=critere-y::passé"]
    p = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), cwd=lab, timeout=120)
    if p.returncode != 0:
        raise RuntimeError("poser-verdict.sh refuse le verdict du juge : rc=%d %s" % (p.returncode, court(p.stderr)))
    return lab, os.path.join(lab, ".planning", "juges", "juge-x", "VERDICT.md")


def _verificateur_de_juges(ctx, dossier, lab):
    """Sortie JSON de `planning-hook.sh --juges <lab>` du dossier donné (stdin fermé), ou le texte de l'échec."""
    p = subprocess.run(["bash", os.path.join(dossier, "planning-hook.sh"), "--juges", lab], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, env=ctx.env(), cwd=lab, timeout=120)
    try:
        return json.loads(p.stdout.decode("utf-8"))
    except ValueError:
        return "rc=%d stdout=%s stderr=%s" % (p.returncode, court(p.stdout), court(p.stderr))


def controle_lecture_bornee(ctx, script):
    """Copie armée : (a) CADRAGE.md au registre CLOS de BORNE_LECTURE_FICHIER + 1 octets -> Write du PLAN.md de la phase : UN deny G1 dont la raison nomme
    BORNE_LECTURE_FICHIER et 1048576 ; jumeau d'EXACTEMENT la borne -> passe ; creux de 2 Gio -> deny G1 qui nomme la borne ; (b) VERDICT.md posé par la vraie
    poser-verdict.sh puis complété à borne + 1 octets -> Write du SUMMARY.md : UN deny G4 qui nomme la borne ; jumeau à la borne -> passe ; creux -> deny ;
    (c) VERDICT.md d'un juge : `--juges` range le juge `sans_preuve` `verdict-hors-borne` à borne + 1 octets (et sur un creux), le prouve à la borne exacte ;
    (d) espion : `lire_octets_bornes` du hook jugé rend `hors-borne` sur les deux fichiers creux sans jamais demander plus de borne + 1 octets."""
    dossier_jugé = _dossier(ctx, script)
    d = ctx.copie_forcee(dossier_jugé, "armed")
    ns = espace_du_hook(ctx, dossier_jugé)
    borne = ns.get("BORNE_LECTURE_FICHIER", 1048576)
    fautes = []
    entete = "---\ninconnues: []\n---\n"
    plan_phase = UNITE + "/PLAN.md"

    def refus(nom, gate, lab, rel):
        bon, detail, raison = _refus_gate(ctx, gate, d, lab, "Write", rel)
        if not bon:
            fautes.append("%s : %s" % (nom, detail))
            return
        for fragment in ("BORNE_LECTURE_FICHIER", "1048576"):
            if fragment not in raison:
                fautes.append("%s : la raison ne nomme pas %s : %s" % (nom, fragment, raison))
                return
        fautes.extend("%s : %s" % (nom, f) for f in fautes_de_message(raison, lab))

    def passe(nom, gate, lab, rel):
        rc, out, err = ecrire_dans(ctx, d, lab, "Write", rel)
        v = classer(rc, out)
        if v not in ("silence", "avertit") or err:
            fautes.append("%s : %s %s" % (nom, v, court(out)))
        elif v == "avertit" and gate in contexte_de(out):
            fautes.append("%s : un avertissement parle de %s : %s" % (nom, gate, court(out)))

    def creux(chemin):
        os.truncate(chemin, 2 * 1024 ** 3)

    # (a) CADRAGE.md, G1
    lab = fabriquer_lab(ctx, "lb-cadrage-plus1", fichiers={UNITE + "/CADRAGE.md": _fichier_de_taille(entete, borne + 1)})
    refus("CADRAGE.md de 1 Mio + 1 octet, G1", "G1", lab, plan_phase)
    lab = fabriquer_lab(ctx, "lb-cadrage-exact", fichiers={UNITE + "/CADRAGE.md": _fichier_de_taille(entete, borne)})
    passe("CADRAGE.md d'exactement 1 Mio, G1", "G1", lab, plan_phase)
    lab_cadrage_creux = fabriquer_lab(ctx, "lb-cadrage-creux", fichiers={UNITE + "/CADRAGE.md": entete})
    cadrage_creux = os.path.join(lab_cadrage_creux, UNITE, "CADRAGE.md")
    creux(cadrage_creux)
    debut = time.monotonic()
    refus("CADRAGE.md creux de 2 Gio, G1", "G1", lab_cadrage_creux, plan_phase)
    print("DUREE lecture-bornee-cadrage-creux-2gio s=%.1f (affichée, jamais assertée)" % (time.monotonic() - debut))
    # (b) VERDICT.md, G4
    lab = lab_g4(ctx, "lb-verdict-plus1")
    _completer(os.path.join(lab, VERDICT), borne + 1)
    refus("VERDICT.md de 1 Mio + 1 octet, G4", "G4", lab, SUMMARY)
    lab = lab_g4(ctx, "lb-verdict-exact")
    _completer(os.path.join(lab, VERDICT), borne)
    passe("VERDICT.md d'exactement 1 Mio, G4", "G4", lab, SUMMARY)
    lab_verdict_creux = lab_g4(ctx, "lb-verdict-creux")
    verdict_creux = os.path.join(lab_verdict_creux, VERDICT)
    creux(verdict_creux)
    debut = time.monotonic()
    refus("VERDICT.md creux de 2 Gio, G4", "G4", lab_verdict_creux, SUMMARY)
    print("DUREE lecture-bornee-verdict-creux-2gio s=%.1f (affichée, jamais assertée)" % (time.monotonic() - debut))
    # (c) VERDICT.md d'un juge, vérificateur de juges
    def juge_attendu(nom, lab, prouve, motif=None):
        classes = _verificateur_de_juges(ctx, dossier_jugé, lab)
        if not isinstance(classes, dict):
            fautes.append("%s : sortie de --juges illisible : %s" % (nom, classes))
        elif prouve:
            if classes.get("prouves") != ["juge-x"] or classes.get("sans_preuve"):
                fautes.append("%s : prouvés %s, sans preuve %s (attendu juge-x prouvé)" % (nom, classes.get("prouves"), court(str(classes.get("sans_preuve")))))
        elif classes.get("prouves") or classes.get("sans_preuve") != [{"juge": "juge-x", "motif": motif}]:
            fautes.append("%s : prouvés %s, sans preuve %s (attendu juge-x sans preuve, motif %s)" % (nom, classes.get("prouves"), court(str(classes.get("sans_preuve"))), motif))

    lab, verdict = _lab_juge(ctx, "lb-juge-plus1")
    _completer(verdict, borne + 1)
    juge_attendu("VERDICT.md de juge de 1 Mio + 1 octet", lab, False, "verdict-hors-borne")
    lab, verdict = _lab_juge(ctx, "lb-juge-exact")
    _completer(verdict, borne)
    juge_attendu("VERDICT.md de juge d'exactement 1 Mio", lab, True)
    lab, verdict_juge_creux = _lab_juge(ctx, "lb-juge-creux")
    creux(verdict_juge_creux)
    debut = time.monotonic()
    juge_attendu("VERDICT.md de juge creux de 2 Gio", lab, False, "verdict-hors-borne")
    print("DUREE lecture-bornee-juge-creux-2gio s=%.1f (affichée, jamais assertée)" % (time.monotonic() - debut))
    # (d) espion : la lecture générique du hook jugé ne demande jamais plus de borne + 1 octets
    lire = ns.get("lire_octets_bornes")
    if lire is None:
        fautes.append("espion : lire_octets_bornes absente du hook jugé (la lecture générique bornée n'existe pas)")
    else:
        for nom, chemin in (("CADRAGE.md creux", cadrage_creux), ("VERDICT.md creux", verdict_creux), ("VERDICT.md de juge creux", verdict_juge_creux)):
            lectures = []
            ns_e = dict(ns)
            ns_e["os"] = _OsEspion(os, lectures, borne)
            fonction = types.FunctionType(lire.__code__, ns_e, lire.__name__, lire.__defaults__)
            statut = fonction(chemin)[0]
            if statut != "hors-borne":
                fautes.append("espion : lire_octets_bornes rend %r sur le %s de 2 Gio (attendu hors-borne)" % (statut, nom))
            if not lectures or any(n is None or not 0 < n <= borne + 1 for n in lectures):
                fautes.append("espion : lecture non bornée sur le %s, read(n) demandés : %s (attendu 0 < n <= %d)" % (nom, lectures, borne + 1))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "CADRAGE.md (G1) et VERDICT.md (G4) de borne + 1 octets et creux de 2 Gio : UN deny qui nomme BORNE_LECTURE_FICHIER (1048576) ; à la borne exacte : "
                          "G1 et G4 passent ; VERDICT.md de juge : verdict-hors-borne au-delà, prouvé à la borne ; espion : hors-borne rendu sans lecture de plus de "
                          "%d octets" % (borne + 1))


def controle_adhesion_bornee(ctx, script):
    """config.json adhérent de BORNE_LECTURE_FICHIER + 1 octets (espaces) : l'adhésion est indéterminée. (1) cœur lancé directement sur un Write du PLAN.md
    d'une phase sans CADRAGE.md : code 3, stdout et stderr vides ; commande enregistrée : deny de la couche de repli (« hook central indisponible »), jamais le
    message de G1 ; Bash : silence ; SessionStart : code 0, stdout vide ; (2) jumeau à la borne exacte : deny G1 (le cœur lit l'adhésion), SessionStart émet
    watchPaths ; (3) config.json DEV hors borne : silence par la commande enregistrée (P46-D-16) ; (4) config.json adhérent creux de 2 Gio : cœur direct, code 3 ;
    (5) espion : `verifier_adhesion` du hook jugé lève `AdhesionIndeterminee` sans lire plus de borne + 1 octets ; (6) `_appliquer_edit` (G6) rend None sur un
    config.json de borne + 1 octets et le contenu édité à la borne exacte."""
    dossier_jugé = _dossier(ctx, script)
    d = ctx.copie_forcee(dossier_jugé, "armed")
    ns = espace_du_hook(ctx, dossier_jugé)
    borne = ns.get("BORNE_LECTURE_FICHIER", 1048576)
    fautes = []
    adherent, dev = '{"planning_version": "cycles-v1"}', '{"planning_version": "2.0"}'
    plan_phase = UNITE + "/PLAN.md"

    def lab_config(nom, entete, taille):
        lab = fabriquer_lab(ctx, nom)
        ecrire(os.path.join(lab, ".planning", "config.json"), entete + " " * (taille - len(entete)))
        return lab

    def ecriture(lab):
        return payload("Write", entree_outil("Write", os.path.join(lab, plan_phase)), lab)

    # (1) borne + 1 octets, adhérent
    lab = lab_config("ab-plus1", adherent, borne + 1)
    rc, out, err = coeur(ctx, d, lab, ecriture(lab))
    if rc != 3 or out != b"" or err != b"":
        fautes.append("cœur direct, Write : rc=%d stdout=%s stderr=%s (attendu : code 3, stdout et stderr vides)" % (rc, court(out), court(err)))
    rc, out, err = ctx.lancer(ecriture(lab), cwd=lab, dossier=d)
    if classer(rc, out) != "deny" or err:
        fautes.append("commande enregistrée, Write : %s %s (attendu : deny de la couche de repli)" % (classer(rc, out), court(out)))
    else:
        raison = raison_de(out)
        if "hook central indisponible" not in raison or "[planning-core] G1 :" in raison:
            fautes.append("commande enregistrée, Write : raison %s (attendu « hook central indisponible », jamais le message de G1)" % court(raison))
    rc, out, err = ctx.lancer(payload("Bash", {"command": "ls"}, lab), cwd=lab, dossier=d)
    if rc != 0 or out != b"" or err:
        fautes.append("commande enregistrée, Bash : rc=%d stdout=%s stderr=%s (attendu le silence)" % (rc, court(out), court(err)))
    rc, out, err = session(ctx, d, lab)
    if rc != 0 or out != b"" or err:
        fautes.append("commande enregistrée, SessionStart : rc=%d stdout=%s stderr=%s (attendu : code 0, stdout vide)" % (rc, court(out), court(err)))
    lab_plus1 = lab
    # (2) jumeau à la borne exacte
    lab = lab_config("ab-exact", adherent, borne)
    bon, detail, _raison = _refus_gate(ctx, "G1", d, lab, "Write", plan_phase)
    if not bon:
        fautes.append("config.json d'exactement 1 Mio, Write : %s (attendu le deny de G1 : le cœur lit l'adhésion)" % detail)
    rc, out, err = session(ctx, d, lab)
    surveilles = surveilles_de(out)
    if rc != 0 or err or not surveilles:
        fautes.append("config.json d'exactement 1 Mio, SessionStart : rc=%d stdout=%s stderr=%s (attendu watchPaths)" % (rc, court(out), court(err)))
    # (3) lab dev hors borne : silence
    lab = lab_config("ab-dev-plus1", dev, borne + 1)
    rc, out, err = ctx.lancer(ecriture(lab), cwd=lab, dossier=d)
    if rc != 0 or out != b"" or err:
        fautes.append("config.json DEV de borne + 1 octets, Write : rc=%d stdout=%s stderr=%s (attendu le silence, P46-D-16)" % (rc, court(out), court(err)))
    # (4) adhérent creux de 2 Gio
    lab = fabriquer_lab(ctx, "ab-creux")
    ecrire(os.path.join(lab, ".planning", "config.json"), adherent)
    os.truncate(os.path.join(lab, ".planning", "config.json"), 2 * 1024 ** 3)
    debut = time.monotonic()
    rc, out, err = coeur(ctx, d, lab, ecriture(lab))
    print("DUREE adhesion-bornee-config-creux-2gio s=%.1f (affichée, jamais assertée)" % (time.monotonic() - debut))
    if rc != 3 or out != b"" or err != b"":
        fautes.append("config.json creux de 2 Gio, cœur direct : rc=%d stdout=%s stderr=%s (attendu : code 3, stdout et stderr vides)" % (rc, court(out), court(err)))
    # (5) espion de verifier_adhesion
    exception = ns.get("AdhesionIndeterminee")
    if ns.get("lire_octets_bornes") is None or exception is None:
        fautes.append("espion : lire_octets_bornes ou AdhesionIndeterminee absente du hook jugé")
    else:
        lectures = []
        ns_e = dict(ns)
        ns_e["os"] = _OsEspion(os, lectures, borne)
        for nom in ("lire_octets_bornes", "verifier_adhesion"):
            f = ns[nom]
            ns_e[nom] = types.FunctionType(f.__code__, ns_e, f.__name__, f.__defaults__)
        try:
            ns_e["verifier_adhesion"](os.path.join(lab_plus1, ".planning"))
            fautes.append("espion : verifier_adhesion ne lève pas AdhesionIndeterminee sur un config.json de borne + 1 octets")
        except exception:
            pass
        if not lectures or any(n is None or not 0 < n <= borne + 1 for n in lectures):
            fautes.append("espion : lecture non bornée par verifier_adhesion, read(n) demandés : %s (attendu 0 < n <= %d)" % (lectures, borne + 1))
    # (6) _appliquer_edit (G6)
    edit = ns.get("_appliquer_edit")
    if edit is None:
        fautes.append("_appliquer_edit absente du hook jugé")
    else:
        entree = {"old_string": "cycles-v1", "new_string": "cycles-v2"}
        rendu = edit(os.path.join(lab_plus1, ".planning", "config.json"), entree)
        if rendu is not None:
            fautes.append("_appliquer_edit sur un config.json de borne + 1 octets rend un contenu de %d caractères (attendu None)" % len(rendu))
        exact = os.path.join(lab_config("ab-edit-exact", adherent, borne), ".planning", "config.json")
        attendu = adherent.replace("cycles-v1", "cycles-v2") + " " * (borne - len(adherent))
        rendu = edit(exact, entree)
        if rendu != attendu:
            fautes.append("_appliquer_edit sur un config.json d'exactement 1 Mio : %s (attendu le contenu édité)" % ("None" if rendu is None else "contenu différent"))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "config.json adhérent de borne + 1 octets (et creux de 2 Gio) : cœur direct code 3, couche de repli deny « hook central indisponible », Bash et "
                          "SessionStart silencieux ; à la borne exacte : le cœur lit l'adhésion (deny G1, watchPaths) ; lab dev hors borne : silence ; espion : "
                          "AdhesionIndeterminee sans lecture de plus de %d octets ; _appliquer_edit : None au-delà, contenu à la borne" % (borne + 1))


class LectureNonBornee(Exception):
    """Levée par le lecteur infini de R-JOURNAUX-BORNES quand le hook en lit sans fin (ce n'est pas une OSError : le hook ne l'attrape pas)."""


class _LecteurInfini:
    """Fichier ouvert par `os.fdopen` qui rend n octets à chaque `read(n)`, sans fin ; au-delà de `limite` octets fournis, lève LectureNonBornee."""
    _BLOC = b"x" * 1048576

    def __init__(self, compte, limite):
        self._compte, self._limite = compte, limite

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def read(self, n=-1):
        n = 1048576 if (n is None or n < 0) else n
        if self._compte[0] + n > self._limite:
            raise LectureNonBornee("plus de %d octets demandés" % self._limite)
        self._compte[0] += n
        return self._BLOC[:n] if n <= len(self._BLOC) else b"x" * n


class _OsInfini:
    """Le module `os` du hook, à l'identique, sauf `fdopen` qui ferme le descripteur réel et rend un `_LecteurInfini`."""

    def __init__(self, reel, compte, limite):
        self._reel, self._compte, self._limite = reel, compte, limite

    def __getattr__(self, nom):
        return getattr(self._reel, nom)

    def fdopen(self, descripteur, *args, **kw):
        self._reel.close(descripteur)
        return _LecteurInfini(self._compte, self._limite)


def controle_journaux_bornes(ctx, script):
    """Copie armée. (a) CLOTURE.md refusé par G3 (livrable absent), dérogation inscrite par la vraie deroger-gate.sh, journal complété APRÈS la dérogation à
    BORNE_LECTURE_FICHIER + 1 octets : Write -> deny G3, journal inchangé (aucune ligne `consommee`) ET `derogation_active` du hook jugé, appelée DIRECTEMENT sur ce
    journal, rend None ; jumeau à la borne exacte -> passe, dérogation citée et consommée ; (b) `consommer` appelée directement sur un journal de borne + 1 octets qui
    porte la dérogation -> False, journal inchangé ; (c) `empreinte_fichier` (D1) sur un lecteur INFINI -> None sans fournir plus de BORNE_OCTETS_LIVRABLES + 1 Mio."""
    dossier_jugé = _dossier(ctx, script)
    d = ctx.copie_forcee(dossier_jugé, "armed")
    ns = espace_du_hook(ctx, dossier_jugé)
    borne = ns.get("BORNE_LECTURE_FICHIER", 1048576)
    borne_d1 = ns.get("BORNE_OCTETS_LIVRABLES", 134217728)
    fautes = []

    def lab_derogation(nom):
        lab = fabriquer_lab(ctx, nom)
        rc, _out, err = deroger(ctx, lab, "G3", (CLOTURE,))
        if rc != 0:
            raise RuntimeError("deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err)))
        return lab, os.path.join(lab, ".planning", "derogations-gates.log")

    active, consomme = ns.get("derogation_active"), ns.get("consommer")
    # (a) journal de borne + 1 octets : aucune dérogation lue, refus maintenu
    lab, journal = lab_derogation("jb-plus1")
    _completer(journal, borne + 1, "# ", "\n")
    avant = open(journal, "rb").read()
    bon, detail, _raison = _refus_g3(ctx, d, lab, "Write", CLOTURE)
    if not bon:
        fautes.append("journal de borne + 1 octets, Write du CLOTURE.md : %s (attendu le deny de G3 : aucune dérogation lue)" % detail)
    apres = open(journal, "rb").read()
    if apres != avant or b"consommee" in apres:
        fautes.append("journal de borne + 1 octets : la taille ou le contenu a changé (%d -> %d octets) ou une ligne `consommee` a été écrite" % (len(avant), len(apres)))
    if active is None:
        fautes.append("derogation_active absente du hook jugé")
    else:
        rendu = active(lab, "G3", CLOTURE)
        if rendu is not None:
            fautes.append("derogation_active appelée directement sur un journal de borne + 1 octets rend une dérogation : %s (attendu None)" % court(str(rendu)))
    # (a) jumeau à la borne exacte : la dérogation est lue, citée, consommée
    lab, journal = lab_derogation("jb-exact")
    _completer(journal, borne, "# ", "\n")
    rc, out, err = ecrire_dans(ctx, d, lab, "Write", CLOTURE)
    texte = open(journal, encoding="utf-8").read()
    if classer(rc, out) != "avertit" or err or "consommée" not in contexte_de(out):
        fautes.append("journal d'exactement 1 Mio, Write du CLOTURE.md : %s %s (attendu un passage qui cite la dérogation consommée)" % (classer(rc, out), court(out)))
    if texte.count("  consommee  id=1  gate=G3  ") != 1:
        fautes.append("journal d'exactement 1 Mio : %d ligne(s) `consommee` (attendu 1)" % texte.count("  consommee  id=1  gate=G3  "))
    # (b) consommer, appelée directement
    lab, journal = lab_derogation("jb-consommer")
    entree = active(lab, "G3", CLOTURE) if active is not None else None
    if active is not None and entree is None:
        fautes.append("témoin : derogation_active ne lit pas la dérogation d'un journal sous la borne")
    _completer(journal, borne + 1, "# ", "\n")
    avant = open(journal, "rb").read()
    if consomme is None:
        fautes.append("consommer absente du hook jugé")
    elif entree is not None:
        rendu = consomme(lab, entree)
        apres = open(journal, "rb").read()
        if rendu is not False:
            fautes.append("consommer appelée directement sur un journal de borne + 1 octets rend %r (attendu False)" % (rendu,))
        if apres != avant:
            fautes.append("consommer a modifié un journal de borne + 1 octets (%d -> %d octets)" % (len(avant), len(apres)))
    # (c) empreinte_fichier : jamais plus de BORNE_OCTETS_LIVRABLES octets lus, même devant un lecteur infini
    empreinte = ns.get("empreinte_fichier")
    if empreinte is None:
        fautes.append("empreinte_fichier absente du hook jugé")
    else:
        petit = ctx.unique("jb-d1")
        ecrire(petit, "petit fichier régulier\n")
        compte = [0]
        ns_e = dict(ns)
        ns_e["os"] = _OsInfini(os, compte, 2 * (borne_d1 + 1))
        fonction = types.FunctionType(empreinte.__code__, ns_e, empreinte.__name__, empreinte.__defaults__)
        try:
            rendu = fonction(petit)
        except LectureNonBornee:
            fautes.append("empreinte_fichier : lecture non bornée (%d octets fournis sans que le hook s'arrête)" % compte[0])
        else:
            if rendu is not None:
                fautes.append("empreinte_fichier rend %s devant un lecteur infini (attendu None)" % court(str(rendu)))
            if compte[0] > borne_d1 + 1048576:
                fautes.append("empreinte_fichier a lu %d octets (attendu au plus BORNE_OCTETS_LIVRABLES + 1 Mio = %d)" % (compte[0], borne_d1 + 1048576))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "journal des dérogations de borne + 1 octets : G3 maintient son refus, journal inchangé, derogation_active rend None, consommer rend False ; à la "
                          "borne exacte : dérogation citée et consommée ; empreinte_fichier (D1) : None sans fournir plus de %d octets devant un lecteur infini"
                          % (borne_d1 + 1048576))


# --- A13 (fix-46-a) : un livrable hors borne n'est pas « à produire » -------------------------------------------------------
def controle_g3_05(ctx, script):
    """Copie armée : livrable dossier de 2001 fichiers -> UN deny G3 dont la raison contient « hors borne », l'entrée déclarée, « 2000 fichiers » et
    « BORNE_FICHIERS_LIVRABLES » et ne demande pas de « produire » le livrable ; livrable fichier creux de BORNE_OCTETS_LIVRABLES + 1 octets -> « 134217728
    octets » et « BORNE_OCTETS_LIVRABLES » ; deux entrées dont la seconde franchit le budget commun (1000 + 1001 fichiers) -> la raison nomme la SECONDE
    entrée et « budget commun » ; jumeau : livrable absent -> le message générique d'avant, inchangé."""
    dossier_jugé = _dossier(ctx, script)
    d = ctx.copie_forcee(dossier_jugé, "armed")
    ns = espace_du_hook(ctx, dossier_jugé)
    borne_octets = ns.get("BORNE_OCTETS_LIVRABLES", 134217728)
    fautes = []

    def cas(nom, lab, attendus):
        bon, detail, raison = _refus_g3(ctx, d, lab, "Write", CLOTURE)
        if not bon:
            fautes.append("%s : %s" % (nom, detail))
            return
        manque = [m for m in attendus if m not in raison]
        if manque:
            fautes.append("%s : la raison ne contient pas %s : %s" % (nom, manque, raison))
        if "produisez-le" in raison:
            fautes.append("%s : la raison demande encore de « produire » le livrable : %s" % (nom, raison))
        fautes.extend("%s : %s" % (nom, f) for f in fautes_de_message(raison, lab))

    lab = fabriquer_lab(ctx, "g3-05-fichiers", plan="ecrit: livrables", fichiers={"livrables/f%04d.md" % i: "x" for i in range(2001)})
    cas("2001 fichiers", lab, ("hors borne", "livrables", "2000 fichiers", "BORNE_FICHIERS_LIVRABLES"))
    lab = fabriquer_lab(ctx, "g3-05-octets", plan="ecrit: livrables/gros.bin", fichiers={"livrables/gros.bin": "x"})
    os.truncate(os.path.join(lab, "livrables", "gros.bin"), borne_octets + 1)
    cas("fichier creux de BORNE_OCTETS_LIVRABLES + 1 octets", lab, ("hors borne", "livrables/gros.bin", "%d octets" % borne_octets, "BORNE_OCTETS_LIVRABLES"))
    plan = "---\necrit:\n  - livrables/a\n  - livrables/b\n---\nPlan.\n"
    fichiers = {"livrables/a/f%04d.md" % i: "x" for i in range(1000)}
    fichiers.update({"livrables/b/f%04d.md" % i: "x" for i in range(1001)})
    lab = fabriquer_lab(ctx, "g3-05-commun", plan=plan, fichiers=fichiers)
    cas("deux entrées, budget commun franchi par la seconde", lab, ("hors borne", "livrables/b", "budget commun"))
    bon, detail, raison = _refus_g3(ctx, d, fabriquer_lab(ctx, "g3-05-absent"), "Write", CLOTURE)
    attendu = "livrable déclaré absent : " + LIVRABLE + " — produisez-le (non vide, sans lien) avant de clore (spec §5)"
    if not bon:
        fautes.append("jumeau absent : " + detail)
    elif attendu not in raison or "hors borne" in raison:
        fautes.append("jumeau absent : le message générique a changé : %s" % raison)
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "livrable hors borne (2001 fichiers, fichier creux de %d octets + 1, budget commun franchi par la seconde entrée) : UN deny G3 qui nomme la borne "
                          "franchie et l'entrée, sans l'injonction de produire ; livrable absent : le message générique inchangé" % borne_octets)


# --- A1 (fix-46-a) : un nom en forme NFD rend la même décision que sa forme NFC (R-NFD-02) -----------------------------------
# Les noms composables sont écrits par échappements \u : ni une relecture ni un éditeur ne peut les renormaliser.
CYCLE_NFC = ".planning/cycles/01-\u00e9t\u00e9"
UNITE_NFC = CYCLE_NFC + "/phases/02-re\u00e7u"
CLOTURE_NFC = UNITE_NFC + "/CLOTURE.md"


def _est_deny_g3(rc, out, err):
    return classer(rc, out) == "deny" and not err and raison_de(out).startswith("[planning-core] G3 :")


def controle_nfd_02(ctx, script):
    """A1 : le hook rend la même décision pour un nom d'unité en NFD que pour sa forme NFC, par toutes les voies — (i) chemin mixte (cycle NFC, phase NFD),
    (ii) `file_path` RELATIF à un `cwd` NFD, (iii) lien du lab dont la CIBLE est écrite en NFD, (iv) dérogation G3 inscrite par deroger-gate.sh avec
    `--chemin` en NFD (le journal porte la forme NFC, l'écriture NFD passe en la citant), (v) copie observe : l'écriture NFD laisse UNE ligne
    d'observation dont le chemin est la forme NFC. (i) à (iii) rendent la MÊME sortie que l'écriture NFC absolue."""
    dossier_jugé = _dossier(ctx, script)
    d = ctx.copie_forcee(dossier_jugé, "armed")
    fautes = []
    lab = fabriquer_lab(ctx, "nfd-02", unite=UNITE_NFC)
    base = ecrire_dans(ctx, d, lab, "Write", CLOTURE_NFC)
    if not _est_deny_g3(*base):
        return False, "écriture NFC absolue : pas un deny G3 : %s %s" % (classer(base[0], base[1]), court(base[1]))

    def meme_sortie(nom, resultat):
        if resultat != base:
            fautes.append("%s : %s %s (écriture NFC absolue : %s)" % (nom, classer(resultat[0], resultat[1]), court(resultat[1] or resultat[2]), classer(base[0], base[1])))

    # (i) chemin mixte : cycle en NFC, phase en NFD
    mixte = CYCLE_NFC + "/phases/" + jumeau_nfd("02-re\u00e7u") + "/CLOTURE.md"
    meme_sortie("(i) chemin mixte", ecrire_dans(ctx, d, lab, "Write", mixte))
    # (ii) voie cwd : file_path relatif à un cwd NFD dans le lab, processus lancé dans le lab
    brut = payload("Write", {"file_path": jumeau_nfd("phases/02-re\u00e7u/CLOTURE.md"), "content": "x"}, os.path.join(lab, jumeau_nfd(CYCLE_NFC)))
    meme_sortie("(ii) voie cwd", ctx.lancer(brut, cwd=lab, dossier=d))
    # (iii) lien du lab dont la cible est écrite en NFD
    os.symlink(jumeau_nfd(CYCLE_NFC), os.path.join(lab, "raccourci"))
    meme_sortie("(iii) lien à cible NFD", ecrire_dans(ctx, d, lab, "Write", "raccourci/phases/02-re\u00e7u/CLOTURE.md"))
    # (iv) dérogation inscrite avec --chemin en NFD
    lab_d = fabriquer_lab(ctx, "nfd-02-derog", unite=UNITE_NFC)
    rc, out, err = deroger(ctx, lab_d, "G3", (jumeau_nfd(CLOTURE_NFC),))
    if rc != 0:
        fautes.append("(iv) deroger-gate.sh refuse --chemin en NFD : rc=%d %s" % (rc, court(err or out)))
    else:
        journal = os.path.join(lab_d, ".planning", "derogations-gates.log")
        lignes = [l for l in open(journal, encoding="utf-8").read().split("\n") if "  derogation  " in l] if os.path.exists(journal) else []
        chemins = [urllib.parse.unquote(c[len("chemin="):]) for l in lignes for c in l.split("  ") if c.startswith("chemin=")]
        if chemins != [CLOTURE_NFC]:
            fautes.append("(iv) la ligne `derogation` ne porte pas le chemin NFC : %s" % chemins)
        r1 = ecrire_dans(ctx, d, lab_d, "Write", jumeau_nfd(CLOTURE_NFC))
        if classer(r1[0], r1[1]) != "avertit" or r1[2] or "#1" not in contexte_de(r1[1]) or "G3" not in contexte_de(r1[1]):
            fautes.append("(iv) l'écriture NFD ne passe pas en citant la dérogation : %s %s" % (classer(r1[0], r1[1]), court(r1[1])))
        r2 = ecrire_dans(ctx, d, lab_d, "Write", jumeau_nfd(CLOTURE_NFC))
        if classer(r2[0], r2[1]) != "deny":
            fautes.append("(iv) la dérogation (usage unique) n'est pas consommée : second Write %s" % classer(r2[0], r2[1]))
    # (v) copie observe : UNE ligne d'observation, chemin décodé en forme NFC
    lab_o = fabriquer_lab(ctx, "nfd-02-observe", unite=UNITE_NFC)
    cache = dossier_neuf(ctx, "cache-nfd-02")
    rc, out, err = ecrire_dans(ctx, ctx.copie_forcee(dossier_jugé, "observe"), lab_o, "Write", jumeau_nfd(CLOTURE_NFC), extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1:
        fautes.append("(v) copie observe : rc=%d stdout=%s stderr=%s lignes=%d (attendu : silence et UNE ligne)" % (rc, court(out), court(err), len(lignes)))
    else:
        champ = [urllib.parse.unquote(c[len("chemin="):]) for c in lignes[0].split("  ") if c.startswith("chemin=")]
        if champ != [CLOTURE_NFC]:
            fautes.append("(v) la ligne d'observation ne porte pas le chemin NFC : %s" % champ)
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "écriture NFD de CLOTURE.md : (i) chemin mixte, (ii) file_path relatif à un cwd NFD, (iii) lien à cible NFD rendent la même sortie que l'écriture "
                          "NFC absolue (deny G3) ; (iv) dérogation inscrite en NFD : journal en NFC, écriture NFD citée puis consommée ; (v) copie observe : une ligne, chemin NFC")


# =================================================================================================
# G4 : contrôles. Les verdicts valides sont posés par la VRAIE poser-verdict.sh ; seuls les verdicts volontairement faux sont écrits à la main.
# =================================================================================================
def poser(ctx, lab, unite, tentative, constats, juge="juge-test"):
    """Lance la vraie poser-verdict.sh sur l'unité `unite` (relative au lab) ; (rc, stdout, stderr)."""
    args = ["bash", os.path.join(ctx.scripts_dir, "poser-verdict.sh"), "--unite=" + os.path.join(lab, unite), "--juge=" + juge,
            "--tentative=%d" % tentative, "--score=ok"] + ["--constat=" + c for c in constats]
    p = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), cwd=lab, timeout=120)
    return p.returncode, p.stdout, p.stderr


def poser_jusqua(ctx, lab, unite, tentative, constats):
    """Pose par la vraie commande les verdicts de la tentative 1 à `tentative` (elle exige 1 à la création, puis +1) ; le dernier porte `constats`."""
    for n in range(1, tentative + 1):
        rc, _out, err = poser(ctx, lab, unite, n, constats if n == tentative else ("intermediaire::passé",))
        if rc != 0:
            raise RuntimeError("poser-verdict.sh refuse la tentative %d de %s : rc=%d %s" % (n, unite, rc, court(err)))


def lab_g4(ctx, nom, tentative=1, constats=("critere-a::passé",), unite=UNITE, fichiers=None, **kw):
    """Lab adhérent dont l'unité porte un livrable présent et un verdict posé par la vraie commande (tentatives 1 à `tentative`)."""
    fich = {LIVRABLE: "contenu\n"}
    fich.update(fichiers or {})
    lab = fabriquer_lab(ctx, nom, unite=unite, fichiers=fich, **kw)
    poser_jusqua(ctx, lab, unite, tentative, constats)
    return lab


def verdict_a_la_main(lab, constats=('  - critere: "a"', '    resultat: "passé"'), hash_plan=None, hash_livrables=None, tentative=1, chemin=VERDICT):
    """VERDICT.md volontairement FAUX (invalide, périmé, clé absente) : jamais un verdict valide, qui vient toujours de poser-verdict.sh."""
    lignes = ["---", 'juge: "j"']
    if hash_plan is not None:
        lignes.append('hash: "%s"' % hash_plan)
    if hash_livrables is not None:
        lignes.append('hash_livrables: "%s"' % hash_livrables)
    lignes.append("tentative: %d" % tentative)
    lignes.append('score: "ok"')
    if constats is not None:
        lignes.append("constats:" if constats else "constats: []")
        lignes.extend(constats)
    lignes.append("---")
    ecrire(os.path.join(lab, chemin), "\n".join(lignes) + "\n")


def sha_plan(lab, unite=UNITE):
    return hashlib.sha256(open(os.path.join(lab, unite, "PLAN.md"), "rb").read()).hexdigest()


def controle_g4_01(ctx, script):
    """Copie observe : Write de SUMMARY.md sans VERDICT.md voisin -> silence, code 0, UNE ligne gate=G4."""
    d = ctx.copie_forcee(_dossier(ctx, script), "observe")
    lab = fabriquer_lab(ctx, "g4-01")
    cache = dossier_neuf(ctx, "cache-g4-01")
    rc, out, err = ecrire_dans(ctx, d, lab, "Write", SUMMARY, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err:
        return False, "rc=%d stdout=%s stderr=%s" % (rc, court(out), court(err))
    if len(lignes) != 1:
        return False, "%d ligne(s) au journal (attendu 1)" % len(lignes)
    for motif in ("  gate=G4  ", "  chemin=" + SUMMARY + "  ", "  outil=Write  "):
        if motif not in lignes[0]:
            return False, "la ligne ne porte pas %r : %s" % (motif, lignes[0])
    return True, "copie observe : silence, code 0, une ligne gate=G4 (chemin du SUMMARY.md, outil Write)"


def controle_g4_02(ctx, script):
    """Copie armée : VERDICT.md absent, invalide (frontmatter, constats vides, résultat hors passé/échec, constats absents, lien), constat en échec, PLAN.md
    absent, ecrit: qui contient l'unité, livrables hors borne -> UN deny `[planning-core] G4 :` chacun, un message distinct par cas."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, messages = [], {}

    def cas(nom, lab, attendu, outil="Write", agent=None, genre=None):
        bon, detail, raison = _refus_g4(ctx, d, lab, outil, SUMMARY, agent=agent)
        if not bon:
            fautes.append("%s : %s" % (nom, detail))
        elif attendu not in raison:
            fautes.append("%s : la raison ne dit pas « %s » : %s" % (nom, attendu, raison))
        else:
            fautes.extend("%s : %s" % (nom, f) for f in fautes_de_message(raison, lab))
            if genre:
                messages[genre] = raison

    # 1. aucun VERDICT.md : trois outils, deux identités
    lab = fabriquer_lab(ctx, "g4-02-absent")
    for outil in ("Write", "Edit", "NotebookEdit"):
        for agent in (None, "agent-inconnu"):
            cas("absent " + outil + " agent=" + str(agent), lab, "aucun VERDICT.md : faites juger l'unité (poser-verdict.sh)", outil=outil, agent=agent, genre="absent")
    # 2. VERDICT.md invalide (règle R6) : écrit à la main, volontairement faux
    invalides = (
        ("sans-frontmatter", lambda lab: ecrire(os.path.join(lab, VERDICT), "pas de frontmatter\n")),
        ("constats-vides", lambda lab: verdict_a_la_main(lab, constats=(), hash_plan="0" * 64)),
        ("resultat-hors-passe-echec", lambda lab: verdict_a_la_main(lab, constats=('  - critere: "a"', '    resultat: "autre"'), hash_plan="0" * 64)),
        ("sans-constats", lambda lab: verdict_a_la_main(lab, constats=None, hash_plan="0" * 64)),
    )
    for nom, pose in invalides:
        lab = fabriquer_lab(ctx, "g4-02-" + nom)
        pose(lab)
        cas(nom, lab, "VERDICT.md invalide (règle R6)", genre="invalide")
    lab = fabriquer_lab(ctx, "g4-02-lien", fichiers={UNITE + "/autre.md": "---\nconstats: []\n---\n"}, liens={VERDICT: "autre.md"})
    cas("lien", lab, "VERDICT.md invalide (règle R6)")
    # 3. constat en échec : le numéro de la tentative suivante est lu dans le verdict
    for tentative in (1, 2):
        lab = lab_g4(ctx, "g4-02-echec-%d" % tentative, tentative=tentative, constats=("critere-a::passé", "critere-b::échec"))
        cas("échec tentative %d" % tentative, lab, "constat en échec : critere-b — corrigez puis re-jugez (tentative %d sur 3, %d restante(s) après elle)" % (tentative + 1, 2 - tentative),
            genre="echec")
    # F6 (fix-46-c) : à la 3e tentative le plafond de poser-verdict.sh est atteint, le message nomme la dérogation PLAFOND (jamais « tentative 4 »)
    lab = lab_g4(ctx, "g4-02-echec-3", tentative=3, constats=("critere-a::passé", "critere-b::échec"))
    cas("échec tentative 3 (plafond)", lab, "constat en échec : critere-b — corrigez puis re-jugez (plafond de 3 tentatives atteint : dérogation PLAFOND requise, "
        "deroger-gate.sh --gate=PLAFOND)", genre="echec")
    # 4. PLAN.md absent ; ecrit: qui contient l'unité (verdicts écrits à la main : la commande de pose les aurait refusés)
    lab = fabriquer_lab(ctx, "g4-02-plan-absent", sans_plan=True)
    verdict_a_la_main(lab, hash_plan="0" * 64, hash_livrables="0" * 64)
    cas("plan-absent", lab, "PLAN.md de l'unité absent, illisible ou sans ecrit: valide", genre="plan")
    lab = fabriquer_lab(ctx, "g4-02-ecrit-unite", plan="ecrit: " + UNITE)
    verdict_a_la_main(lab, hash_plan="0" * 64, hash_livrables="0" * 64)
    cas("ecrit-unite", lab, "ecrit: contient le dossier de l'unité")
    # 5. livrables hors borne : 2001 petits fichiers sous un dossier déclaré, plan haché à la main par le test
    lab = fabriquer_lab(ctx, "g4-02-borne", plan="ecrit: livrables", fichiers={"livrables/f%04d.md" % i: "x" for i in range(2001)})
    verdict_a_la_main(lab, hash_plan=sha_plan(lab), hash_livrables="0" * 64)
    cas("hors-borne", lab, "livrables hors borne : borne de 2000 fichiers dépassée", genre="borne")
    genres = ("absent", "invalide", "echec", "plan", "borne")
    if len({messages.get(g) for g in genres}) != len(genres) and not fautes:
        fautes.append("les messages ne sont pas distincts par cas : %s" % {g: messages.get(g) for g in genres})
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "UN deny « [planning-core] G4 : » par cas, message distinct : aucun VERDICT.md (3 outils, 2 identités) ; invalide R6 (frontmatter, constats vides, "
                          "résultat hors passé/échec, constats absents, lien) ; constat en échec avec la tentative suivante lue dans le verdict ; PLAN.md absent ; ecrit: qui "
                          "contient l'unité ; livrables hors borne")


def controle_g4_03(ctx, script):
    """Copie armée : verdict posé par la vraie commande (tentative 2), puis un octet d'un livrable, le PLAN.md, `hash_livrables` retiré ou un livrable supprimé
    -> « verdict périmé : re-juger (tentative 3 sur 3, 0 restante(s) après elle) »."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []
    attendu = "[planning-core] G4 : verdict périmé : re-juger (tentative 3 sur 3, 0 restante(s) après elle)"

    def perime(nom, lab):
        bon, detail, raison = _refus_g4(ctx, d, lab, "Write", SUMMARY)
        if not bon:
            fautes.append("%s : %s" % (nom, detail))
        elif raison != attendu:
            fautes.append("%s : la raison n'est pas « %s » : %s" % (nom, attendu, raison))

    lab = lab_g4(ctx, "g4-03-livrable", tentative=2)
    with open(os.path.join(lab, LIVRABLE), "a", encoding="utf-8") as fh:
        fh.write("x")
    perime("livrable modifié d'un octet", lab)
    lab = lab_g4(ctx, "g4-03-plan", tentative=2)
    with open(os.path.join(lab, UNITE, "PLAN.md"), "a", encoding="utf-8") as fh:
        fh.write("Une ligne de plus.\n")
    perime("PLAN.md modifié", lab)
    lab = lab_g4(ctx, "g4-03-cle", tentative=2)
    chemin = os.path.join(lab, VERDICT)
    texte = open(chemin, encoding="utf-8").read()
    sans = "\n".join(l for l in texte.split("\n") if not l.startswith("hash_livrables:"))
    if sans == texte.rstrip("\n"):
        fautes.append("le verdict posé ne porte pas de ligne hash_livrables à retirer")
    ecrire(chemin, sans + "\n")
    perime("hash_livrables retiré", lab)
    lab = lab_g4(ctx, "g4-03-supprime", tentative=2)
    os.remove(os.path.join(lab, LIVRABLE))
    perime("livrable supprimé", lab)
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "verdict posé (tentative 2) puis un octet d'un livrable, le PLAN.md, hash_livrables retiré ou un livrable supprimé : "
                          "« verdict périmé : re-juger (tentative 3 sur 3, 0 restante(s) après elle) » chaque fois")


def controle_g4_04(ctx, script):
    """Copie armée, jumeaux qui passent : verdict posé par la vraie commande, constats passés, empreintes conformes -> Write, Edit, NotebookEdit ; seconde
    écriture d'une unité close ; unité de plan ; SUMMARY.md de style GSD, de niveau cycle, noms voisins jamais jugés ; lab dev : octet vide."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes = []

    def passe(nom, lab, outil, rel):
        rc, out, err = ecrire_dans(ctx, d, lab, outil, rel)
        v = classer(rc, out)
        if v not in ("silence", "avertit") or err:
            fautes.append("%s %s : %s %s" % (nom, outil, v, court(out)))
        elif v == "avertit" and "G4" in contexte_de(out):
            fautes.append("%s %s : un avertissement parle de G4 : %s" % (nom, outil, court(out)))

    lab = lab_g4(ctx, "g4-04", tentative=2)
    for outil in ("Write", "Edit", "NotebookEdit"):
        passe("verdict conforme", lab, outil, SUMMARY)
    ecrire(os.path.join(lab, SUMMARY), "Résumé déjà écrit.\n")
    for outil in ("Write", "Edit"):
        passe("unité close retouchée", lab, outil, SUMMARY)
    lab = lab_g4(ctx, "g4-04-plans", unite=UNITE_PLAN)
    passe("unité de plan", lab, "Write", SUMMARY_PLAN)
    # formes jamais jugées : aucun VERDICT.md, de sorte qu'un G4 trop large refuserait
    lab = fabriquer_lab(ctx, "g4-04-voisins")
    for nom, rel in (("style GSD", ".planning/phases/01-x/SUMMARY.md"), ("niveau cycle", ".planning/cycles/01-c/SUMMARY.md"),
                     ("nom d'unité invalide (cycle)", ".planning/cycles/c/phases/01-p/SUMMARY.md"),
                     ("nom d'unité invalide (phase)", ".planning/cycles/01-c/phases/p/SUMMARY.md"),
                     ("SUMMARY.md.bak", SUMMARY + ".bak"), ("nom voisin", UNITE + "/SUMMARY-notes.md"),
                     ("profondeur fausse", UNITE + "/plans/SUMMARY.md"), ("sous un autre dossier", UNITE + "/annexes/01-a/SUMMARY.md"),
                     ("hors .planning/", "livrables/SUMMARY.md"), ("hors .planning/ (racine)", "SUMMARY.md")):
        passe(nom, lab, "Write", rel)
    lab_dev = fabriquer_lab(ctx, "g4-04-dev", adherent=False)
    for outil in ("Write", "Edit", "NotebookEdit"):
        rc, out, err = ecrire_dans(ctx, d, lab_dev, outil, SUMMARY)
        if rc != 0 or out != b"" or err:
            fautes.append("lab dev %s : rc=%d %s" % (outil, rc, court(out)))
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "aucun refus : verdict posé par la vraie commande (Write, Edit, NotebookEdit), seconde écriture d'une unité close, unité de plan ; style GSD, "
                          "niveau cycle, noms d'unité invalides, .bak, nom voisin, profondeur fausse, hors .planning/ jamais jugés ; lab dev : stdout d'octet vide et code 0")


def controle_g4_05(ctx, script):
    """Dérogation G4 active sur le chemin du SUMMARY.md : passage cité, usage unique ; erreur interne injectée dans evaluer_g4 (sonde) : armée deny
    « erreur interne du gate », observe ligne d'observation et aucun refus. La sonde est posée sur le hook du dossier jugé : un mutant qui rend
    l'erreur silencieuse pour G4 (evaluer_protege) est vu ici."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    lab = fabriquer_lab(ctx, "g4-05")
    rc, out, err = deroger(ctx, lab, "G4", (SUMMARY,))
    if rc != 0:
        return False, "deroger-gate.sh refuse le scénario : rc=%d %s" % (rc, court(err))
    r1 = ecrire_dans(ctx, d, lab, "Write", SUMMARY)
    if classer(r1[0], r1[1]) != "avertit" or r1[2]:
        return False, "premier Write : %s %s" % (classer(r1[0], r1[1]), court(r1[1]))
    texte = contexte_de(r1[1])
    manque = [m for m in ("#1", "G4", "willy", "AskUserQuestion session principale", "2026-10-05", SUMMARY) if m not in texte]
    journal = os.path.join(lab, ".planning", "derogations-gates.log")
    consommees = [l for l in open(journal, encoding="utf-8").read().split("\n") if "  consommee  id=1  gate=G4  " in l] if os.path.exists(journal) else []
    if manque or len(consommees) != 1:
        return False, "citation sans %s ; lignes consommee : %d" % (manque, len(consommees))
    r2 = ecrire_dans(ctx, d, lab, "Write", SUMMARY)
    if classer(r2[0], r2[1]) != "deny":
        return False, "second Write : " + classer(r2[0], r2[1])
    dossier, raison = make_hook_mutant(ctx, "G4-SONDE", "# g4-sonde", 'raise RuntimeError("sonde")  # g4-sonde', base=_dossier(ctx, script))
    if dossier is None:
        return False, "mutant sonde invalide : " + raison
    lab2 = fabriquer_lab(ctx, "g4-05-sonde")
    cache = dossier_neuf(ctx, "cache-g4-05")
    rc, out, err = ecrire_dans(ctx, ctx.copie_forcee(dossier, "observe"), lab2, "Write", SUMMARY, extra_env={"XDG_CACHE_HOME": cache})
    lignes = lignes_journal(cache)
    if rc != 0 or out != b"" or err or len(lignes) != 1 or "  gate=G4  " not in lignes[0]:
        return False, "sonde, observe : rc=%d stdout=%s stderr=%s lignes=%s" % (rc, court(out), court(err), lignes)
    motif = [c for c in lignes[0].split("  ") if c.startswith("raison=")]
    if not motif or "erreur interne" not in urllib.parse.unquote(motif[0]):
        return False, "la ligne ne porte pas une raison d'erreur : " + lignes[0]
    rc, out, err = ecrire_dans(ctx, ctx.copie_forcee(dossier, "armed"), lab2, "Write", SUMMARY)
    if classer(rc, out) != "deny" or "erreur interne du gate" not in raison_de(out):
        return False, "sonde, armée : " + classer(rc, out) + " " + court(out)
    return True, ("dérogation G4 : premier Write passe et cité, dérogation consommée, second Write refusé ; erreur interne de G4 : en observe aucun "
                  "refus et une ligne d'erreur au journal, armée un deny « erreur interne du gate »")


def controle_g4_06(ctx, script):
    """Aucun message de refus de G3 ou de G4 ne contient le chemin absolu du lab, « no such file » ni « can't open » (P46-D-10, #60490)."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    fautes, n = [], 0

    def verifie(nom, gate, lab, rel):
        nonlocal n
        bon, detail, raison = _refus_gate(ctx, gate, d, lab, "Write", rel)
        n += 1
        if not bon:
            fautes.append("%s : %s" % (nom, detail))
        else:
            fautes.extend("%s : %s" % (nom, f) for f in fautes_de_message(raison, lab))

    verifie("G3 livrable absent", "G3", fabriquer_lab(ctx, "g4-06-g3-absent"), CLOTURE)
    verifie("G3 PLAN.md absent", "G3", fabriquer_lab(ctx, "g4-06-g3-plan", sans_plan=True), CLOTURE)
    verifie("G3 ecrit: invalide", "G3", fabriquer_lab(ctx, "g4-06-g3-ecrit", plan="ecrit: ../hors-lab.md"), CLOTURE)
    verifie("G4 VERDICT.md absent", "G4", fabriquer_lab(ctx, "g4-06-g4-absent"), SUMMARY)
    lab = fabriquer_lab(ctx, "g4-06-g4-invalide")
    ecrire(os.path.join(lab, VERDICT), "pas de frontmatter\n")
    verifie("G4 VERDICT.md invalide", "G4", lab, SUMMARY)
    verifie("G4 constat en échec", "G4", lab_g4(ctx, "g4-06-g4-echec", constats=("critere-a::échec",)), SUMMARY)
    lab = lab_g4(ctx, "g4-06-g4-perime")
    with open(os.path.join(lab, LIVRABLE), "a", encoding="utf-8") as fh:
        fh.write("x")
    verifie("G4 verdict périmé", "G4", lab, SUMMARY)
    lab = fabriquer_lab(ctx, "g4-06-g4-plan", sans_plan=True)
    verdict_a_la_main(lab, hash_plan="0" * 64, hash_livrables="0" * 64)
    verifie("G4 PLAN.md absent", "G4", lab, SUMMARY)
    return (not fautes), ("; ".join(fautes[:6]) if fautes else
                          "%d refus de G3 et de G4 : ni chemin absolu du lab, ni « no such file », ni « can't open »" % n)


# =================================================================================================
# R-FORME-01 : la forme d'unité du hook et celle de la commande de pose sont la même règle
# =================================================================================================
def espace(ctx, nom):
    """Espace de noms du corps Python du hook (`hook`) ou de poser-verdict.sh (`poser`), sans l'appel final à main() : les contrôles croisés appellent
    les VRAIES fonctions, chargées du texte des scripts."""
    if nom not in ctx._ns:
        chemin, marqueur = (ctx.hook, "PY_PLANNING_HOOK_EOF") if nom == "hook" else (os.path.join(ctx.scripts_dir, "poser-verdict.sh"), "PY_POSER_VERDICT_EOF")
        arbre = ast.parse(corps_python(open(chemin, encoding="utf-8").read(), marqueur))
        arbre.body = [n for n in arbre.body if not (isinstance(n, ast.Expr) and isinstance(n.value, ast.Call) and getattr(n.value.func, "id", "") == "main")]
        ns = {"__name__": "bloc_charge_cloture"}
        exec(compile(arbre, chemin, "exec"), ns)
        ctx._ns[nom] = ns
    return ctx._ns[nom]


LOT_FORME = (
    # formes valides : phase, plan, casse, noms d'unité variés
    ".planning/cycles/01-c/phases/01-p/%s", ".planning/cycles/01-c/phases/01-p/plans/01-a/%s", ".PLANNING/CYCLES/01-C/PHASES/01-P/%s",
    ".Planning/Cycles/01-c/Phases/01-p/Plans/01-a/%s", ".planning/cycles/10-x.y/phases/001-long_nom/%s", ".planning/cycles/01-é/phases/02-ü/%s",
    ".planning/cycles/01-c/phases/01-p/plans/12-a-b/%s",
    # formes fausses : noms d'unité, profondeurs, dossiers fixes, préfixes
    ".planning/cycles/c/phases/01-p/%s", ".planning/cycles/1-c/phases/01-p/%s", ".planning/cycles/01_c/phases/01-p/%s", ".planning/cycles/01-/phases/01-p/%s",
    ".planning/cycles/01-c/phases/p/%s", ".planning/cycles/01-c/phases/01-p/plans/a/%s", ".planning/cycles/01-c/%s", ".planning/cycles/01-c/phases/%s",
    ".planning/cycles/01-c/phases/01-p/plans/%s", ".planning/cycles/01-c/phases/01-p/plan/01-a/%s", ".planning/cycles/01-c/phases/01-p/plans/01-a/x/%s",
    ".planning/cycles/01-c/phases/01-p/annexes/01-a/%s", ".planning/phases/01-x/%s", ".planning/%s", "%s", "livrables/%s", "planning/cycles/01-c/phases/01-p/%s",
    "cycles/01-c/phases/01-p/%s", ".planning/.planning/cycles/01-c/phases/01-p/%s", ".planning/cycle/01-c/phases/01-p/%s", ".planning/cycles/01-c/phase/01-p/%s",
)
NOMS_FORME = ("SUMMARY.md", "CLOTURE.md", "summary.md", "Cloture.MD", "SUMMARY.md.bak", "SUMMARY-notes.md", "PLAN.md", "VERDICT.md")


def controle_forme_01(ctx, script):
    """R-FORME-01 : sur un lot de chemins (formes valides de phase et de plan, noms d'unité invalides, profondeurs fausses, casse), `unite_de_fichier` du hook
    et `forme_unite` de poser-verdict.sh rendent la même unité. Les deux fonctions sont chargées du texte des scripts."""
    hook, poseur = espace(ctx, "hook"), espace(ctx, "poser")
    unite_de_fichier, forme_unite = hook["unite_de_fichier"], poseur["forme_unite"]
    ecarts, valides, faux = [], 0, 0
    for nom in ("SUMMARY.md", "CLOTURE.md"):
        for gabarit in LOT_FORME:
            for fichier in NOMS_FORME:
                composants = [c for c in (gabarit % fichier).split("/") if c != ""]
                du_hook = unite_de_fichier(composants, nom)
                du_poseur = composants[:-1] if (composants and composants[-1].casefold() == nom.casefold() and forme_unite(composants[:-1])) else None
                if du_hook != du_poseur:
                    ecarts.append("%s (nom %s) : hook=%s poser-verdict=%s" % ("/".join(composants), nom, du_hook, du_poseur))
                if du_hook is None:
                    faux += 1
                else:
                    valides += 1
    if ecarts:
        return False, "%d écart(s) : %s" % (len(ecarts), "; ".join(ecarts[:3]))
    if valides < 20 or faux < 100:
        return False, "lot trop pauvre pour prouver quoi que ce soit : %d formes valides, %d formes fausses" % (valides, faux)
    return True, "unite_de_fichier du hook et forme_unite de poser-verdict.sh : même unité sur %d chemins (%d de forme modèle, %d fausses)" % (valides + faux, valides, faux)


# =================================================================================================
# Banc de clôture : fixtures/cloture-banc.txt, un FICHIER TEXTE (aucun dossier .planning/ versionné)
# =================================================================================================
OUTILS_BANC = ("Write", "Edit", "NotebookEdit")
JETON_PLAN = "{{sha256-plan}}"
JETON_LIVRABLES = "{{empreinte-livrables}}"


def _chemin_banc(chemin):
    if chemin.startswith("/") or chemin.startswith("~") or ".." in chemin.split("/"):
        raise ValueError("chemin refusé par le matérialiseur : " + chemin)


def parser_ecriture(reste):
    if " :: " not in reste:
        raise ValueError("directive @@ ecriture sans ` :: ` : " + reste)
    gauche, droite = reste.split(" :: ", 1)
    att = droite.split()
    if len(att) != 2 or att[0] not in ("doit-passer", "doit-refuser", "silence") or att[1] not in ("G3", "G4"):
        raise ValueError("attendu inconnu : " + droite)
    morceaux = gauche.split()
    if len(morceaux) < 2 or morceaux[0] not in OUTILS_BANC:
        raise ValueError("outil de banc inconnu : " + gauche)
    _chemin_banc(morceaux[1])
    e = {"outil": morceaux[0], "chemin": morceaux[1], "agent": None, "attendu": att[0], "gate": att[1]}
    for m in morceaux[2:]:
        if not m.startswith("agent="):
            raise ValueError("option de banc inconnue : " + m)
        e["agent"] = m[6:]
    return e


def parser_verdict(reste):
    morceaux = reste.split()
    if len(morceaux) != 3 or not morceaux[1].startswith("tentative=") or not morceaux[2].startswith("constats="):
        raise ValueError("directive @@ verdict mal formée : " + reste)
    _chemin_banc(morceaux[0])
    return {"unite": morceaux[0], "tentative": int(morceaux[1][len("tentative="):]), "constats": tuple(morceaux[2][len("constats="):].split(","))}


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
            labs[lab] = {"fichiers": {}, "dossiers": [], "liens": [], "ecritures": [], "verdicts": [], "jumeau_de": jumeau}
            ordre.append(lab)
        elif d.startswith("dossier "):
            _chemin_banc(d[8:].strip())
            labs[lab]["dossiers"].append(d[8:].strip())
        elif d.startswith("fichier "):
            _chemin_banc(d[8:].strip())
            fichier, contenu = d[8:].strip(), []
        elif d.startswith("lien "):
            reste = d[5:].strip()
            if " -> " not in reste:
                raise ValueError("directive @@ lien mal formée : " + d)
            chemin, cible = [p.strip() for p in reste.split(" -> ", 1)]
            _chemin_banc(chemin)
            labs[lab]["liens"].append((chemin, cible))
        elif d.startswith("ecriture "):
            labs[lab]["ecritures"].append(parser_ecriture(d[9:]))
        elif d.startswith("verdict "):
            labs[lab]["verdicts"].append(parser_verdict(d[8:]))
        else:
            raise ValueError("directive de banc inconnue : " + d)
    clore()
    return ordre, labs


def resoudre_jetons(ctx, destination):
    """Résout, APRÈS l'écriture de tous les fichiers du lab, `{{sha256-plan}}` et `{{empreinte-livrables}}` des VERDICT.md écrits à la main (verdicts
    volontairement faux sur UNE des deux empreintes), par la copie du bloc partagé lue dans poser-verdict.sh. Un jeton qui ne se résout pas lève
    une erreur nommée, jamais une substitution vide."""
    poseur = None
    for racine, _dossiers, fichiers in os.walk(destination, followlinks=False):
        if "VERDICT.md" not in fichiers:
            continue
        chemin = os.path.join(racine, "VERDICT.md")
        if not stat.S_ISREG(os.lstat(chemin).st_mode):
            continue
        texte = open(chemin, encoding="utf-8").read()
        if JETON_PLAN not in texte and JETON_LIVRABLES not in texte:
            continue
        rel = os.path.relpath(chemin, destination)
        plan = os.path.join(racine, "PLAN.md")
        if not os.path.isfile(plan) or os.path.islink(plan):
            raise RuntimeError("jeton du banc non résolu : PLAN.md voisin absent de " + rel)
        octets = open(plan, "rb").read()
        texte = texte.replace(JETON_PLAN, hashlib.sha256(octets).hexdigest())
        if JETON_LIVRABLES in texte:
            poseur = poseur or espace(ctx, "poser")
            statut_fm, donnees = poseur["lire_frontmatter"](octets.decode("utf-8"))
            valeurs = poseur["_valeurs_ecrit"](donnees) if statut_fm == "ok" else []
            if not valeurs:
                raise RuntimeError("jeton du banc non résolu : ecrit: illisible ou absent du PLAN.md voisin (" + rel + ")")
            statut, detail = poseur["empreinte_livrables"](destination, valeurs)
            if statut != "ok":
                raise RuntimeError("jeton du banc non résolu : empreinte des livrables %s (%s) pour %s" % (statut, detail, rel))
            texte = texte.replace(JETON_LIVRABLES, detail)
        with open(chemin, "w", encoding="utf-8") as fh:
            fh.write(texte)


def materialiser(ctx, labs, nom, destination):
    lab = labs[nom]
    os.makedirs(destination, exist_ok=True)
    for dossier in lab["dossiers"]:
        os.makedirs(os.path.join(destination, dossier), exist_ok=True)
    for chemin, contenu in lab["fichiers"].items():
        ecrire(os.path.join(destination, chemin), contenu)
    for chemin, cible in lab["liens"]:
        os.makedirs(os.path.dirname(os.path.join(destination, chemin)), exist_ok=True)
        os.symlink(cible, os.path.join(destination, chemin))
    resoudre_jetons(ctx, destination)
    for v in lab["verdicts"]:
        poser_jusqua(ctx, destination, v["unite"], v["tentative"], v["constats"])


def _sous_planning(chemin):
    """Vrai si `chemin` (relatif au lab, séparateur `/`) est `.planning` ou se trouve dessous."""
    return chemin == ".planning" or chemin.startswith(".planning/")


def materialiser_disque_nfd(ctx, labs, nom, destination, hors_planning_declare=False):
    """La MÊME chaîne que `materialiser`, mais chaque chemin de dossier, de fichier, de lien ET la cible relative d'un lien passent par `jumeau_nfd` : les
    noms du DISQUE sont en NFD (A1-readdir, fix-46-a tour 2). Les contenus restent ceux du banc (noms en NFC). Par défaut les verdicts ne sont posés par
    `poser_jusqua` que sur un système insensible à la normalisation : sur un système sensible (ext4), un livrable stocké sous un nom NFD est ABSENT sous la
    forme que `ecrit:` déclare (NFC), et poser-verdict.sh refuse alors la pose (64, « livrable … est absent », limite (bf) ; mesuré sous simulation, quick
    261006-aw0 : `--unite` est lue sous le nom du disque, ce n'est pas elle qui manque).
    `hors_planning_declare` (fix-46-a tour 3, D1 de R-BANC-NFD) : tout chemin de dossier, de fichier, de lien et toute cible de lien qui n'est PAS sous
    `.planning/` garde sa forme du banc (celle que `ecrit:` déclare : D1 ne lit pas les livrables), seuls les noms sous `.planning/` passent en NFD ; les
    verdicts sont alors posés par la vraie commande sur TOUT système, pour que les deux disques portent les mêmes écritures du moteur."""
    def disque(chemin):
        return jumeau_nfd(chemin) if (not hors_planning_declare or _sous_planning(chemin)) else chemin

    def disque_cible(chemin, cible):
        resolue = os.path.normpath(os.path.join(os.path.dirname(chemin), cible))
        return jumeau_nfd(cible) if (not hors_planning_declare or _sous_planning(resolue)) else cible
    lab = labs[nom]
    os.makedirs(destination, exist_ok=True)
    for dossier in lab["dossiers"]:
        os.makedirs(os.path.join(destination, disque(dossier)), exist_ok=True)
    for chemin, contenu in lab["fichiers"].items():
        ecrire(os.path.join(destination, disque(chemin)), contenu)
    for chemin, cible in lab["liens"]:
        os.makedirs(os.path.dirname(os.path.join(destination, disque(chemin))), exist_ok=True)
        os.symlink(disque_cible(chemin, cible), os.path.join(destination, disque(chemin)))
    resoudre_jetons(ctx, destination)
    if hors_planning_declare or disque_insensible(ctx):
        for v in lab["verdicts"]:
            poser_jusqua(ctx, destination, jumeau_nfd(v["unite"]), v["tentative"], v["constats"])


def labs_banc(ctx):
    if ctx._banc is None:
        ordre, labs = parser_banc(open(ctx.banc, encoding="utf-8").read())
        racine = ctx.unique("bancs")
        chemins = {}
        for nom in ordre:
            chemins[nom] = os.path.join(racine, nom)
            materialiser(ctx, labs, nom, chemins[nom])
        ctx._banc = (ordre, labs, chemins)
    return ctx._banc


def jouer(ctx, dossier, lab, outil, rel, agent=None):
    """Rejoue une écriture par la commande enregistrée ; le résultat est gardé (le banc et la preuve croisée lisent la même exécution)."""
    cle = (dossier, lab, outil, rel, agent)
    if cle not in ctx.memo:
        ctx.memo[cle] = ecrire_dans(ctx, dossier, lab, outil, rel, agent=agent)
    return ctx.memo[cle]


def sec_banc(ctx):
    ordre, labs, chemins = labs_banc(ctx)
    d = ctx.copie_forcee(ctx.scripts_dir, "armed")
    compte, faux = {}, {}
    for nom in ordre:
        conformes = 0
        for e in labs[nom]["ecritures"]:
            rc, out, err = jouer(ctx, d, chemins[nom], e["outil"], e["chemin"], e["agent"])
            v = classer(rc, out)
            gate = e["gate"]
            if e["attendu"] == "doit-refuser":
                conforme = v == "deny" and ("[planning-core] %s :" % gate) in raison_de(out)
            elif e["attendu"] == "doit-passer":
                conforme = v in ("silence", "avertit") and not (v == "avertit" and gate in contexte_de(out))
            else:
                conforme = v == "silence"
            conforme = conforme and not err
            compte.setdefault(gate, {}).setdefault(e["attendu"], 0)
            compte[gate][e["attendu"]] += 1
            if e["attendu"] != "doit-refuser" and v == "deny":
                faux.setdefault(gate, [0, 0])[0] += 1
            elif e["attendu"] == "doit-refuser" and not conforme:
                faux.setdefault(gate, [0, 0])[1] += 1
            if conforme:
                conformes += 1
            else:
                ko("BANC %s %s %s%s :: %s %s" % (nom, e["outil"], e["chemin"], (" agent=" + e["agent"]) if e["agent"] else "", e["attendu"], gate),
                   "écriture du banc rejouée par la commande enregistrée sur copie armée", e["attendu"] + " " + gate, v + " " + court(out) + " " + court(err))
        if conformes == len(labs[nom]["ecritures"]):
            ok("BANC %s : %d écritures conformes%s" % (nom, conformes, (" (jumeau de " + labs[nom]["jumeau_de"] + ")") if labs[nom]["jumeau_de"] else ""))
    adherents = [n for n in ordre if not labs[n]["jumeau_de"]]
    jumeaux = [n for n in ordre if labs[n]["jumeau_de"]]
    if len(adherents) < 10 or len(jumeaux) < 10 or any(not labs[n]["ecritures"] for n in jumeaux):
        ko("BANC taille", "au moins dix labs adhérents, chacun avec son jumeau `-dev` qui porte des écritures", ">= 10 et >= 10",
           "%d adhérents, %d jumeaux" % (len(adherents), len(jumeaux)))
    for gate in ("G3", "G4"):
        c = compte.get(gate, {})
        print("COUVERTURE %s doit-refuser=%d doit-passer=%d silence=%d" % (gate, c.get("doit-refuser", 0), c.get("doit-passer", 0), c.get("silence", 0)))
        if c.get("doit-refuser", 0) < 4 or c.get("doit-passer", 0) < 4 or c.get("silence", 0) < 1:
            ko("COUVERTURE " + gate, "au moins quatre doit-refuser, quatre doit-passer et un silence (jumeau dev) réellement joués pour " + gate, ">= 4, >= 4, >= 1", str(c))
        else:
            ok("COUVERTURE %s : %d doit-refuser, %d doit-passer, %d silence (jumeaux dev)" % (gate, c["doit-refuser"], c["doit-passer"], c["silence"]))
    for gate in ("G3", "G4"):
        fr, fa = faux.get(gate, [0, 0])
        print("COMPTE %s faux-refus=%d faux-accept=%d" % (gate, fr, fa))
        n = sum(compte.get(gate, {}).values())
        if fr == 0 and fa == 0 and n:
            ok("R-BANC-%s banc sur copie armée : COMPTE %s faux-refus=0 faux-accept=0 (%d écritures)" % (gate, gate, n))
        else:
            ko("R-BANC-" + gate, "banc sur copie armée : zéro faux refus, zéro faux accept, sur un banc non vide", "%s [0, 0] sur >= 1 écriture" % gate,
               "%s=%s sur %d écriture(s)" % (gate, faux.get(gate), n))
    bon, detail = original_de(ctx, "R-BANC-NFD", controle_banc_nfd)
    ok("R-BANC-NFD jumeaux NFD du banc sur copie armée : " + detail) if bon else ko("R-BANC-NFD", "chaque écriture composable du banc rend, sous sa forme NFD, le même code et la même sortie",
                                                                                      "jumeaux identiques", detail)


def _ecrire_lab_egalite(racine, disque_nfd):
    """Lab synthétique d'égalité de préfixe : adhérent, cycle `01-c`, phases `05-côté` et `05-cz` (même préfixe numérique), sans SUMMARY.md (toutes
    deux non closes). `disque_nfd` : chaque composant de chemin est écrit en NFD (les contenus restent ceux du banc)."""
    fichiers = {".planning/config.json": '{"planning_version": "cycles-v1"}\n',
                ".planning/cycles/01-c/phases/05-côté/PLAN.md": "---\necrit: livrables/c.md\n---\nPlan.\n",
                ".planning/cycles/01-c/phases/05-cz/PLAN.md": "---\necrit: livrables/z.md\n---\nPlan.\n"}
    for chemin, contenu in fichiers.items():
        ecrire(os.path.join(racine, jumeau_nfd(chemin) if disque_nfd else chemin), contenu)


def controle_banc_nfd(ctx, script):
    """R-BANC-NFD (A1, fix-46-a ; A1-readdir, fix-46-a tour 2). Trois preuves sur copie armée, la forme NFC servant de référence.
    (1) Pour chaque écriture du banc dont le chemin porte un caractère composable, rejouée dans deux matérialisations FRAÎCHES du lab (l'une reçoit la forme
    NFC, l'autre le jumeau NFD), mêmes code, stdout et stderr (vide) ; au moins un refus et un passage pour G3 et pour G4, au moins un silence (jumeau dev).
    (2) Disque NFD, D1 (A1-readdir) : pour chaque lab qui porte un nom d'unité composable (l'adhérent et son jumeau dev), SessionStart (`source: startup`)
    rend, sur un disque dont les noms sont en NFD, la même liste surveillée (chemins relatifs en NFC, même ordre ; plus de cinq chemins pour l'adhérent, dont
    au moins un en forme de disque NFD : le nom du disque construit le chemin d'accès) et les mêmes (genre, chemin) au journal de D1 que sur le disque NFC,
    COMPARÉ EN ENTIER sur tout système (fix-46-a tour 3) : les deux disques portent les mêmes verdicts, posés par la vraie poser-verdict.sh (`hors_planning_declare`),
    donc les mêmes lignes `moteur` ; un écart nomme les lignes d'un seul côté ; le jumeau dev se tait des deux côtés ; PLUS un lab d'égalité de préfixe (phases `05-côté` et `05-cz`) : mêmes listes, `05-côté` avant `05-cz` (ordre
    déclaré : nom NFC décroissant ; sans NFC dans `cle_recence` l'unité NFD passerait après `05-cz`).
    (3) Disque NFD, G3 et G4, seulement sur un système insensible à la normalisation (APFS, HFS+) : chaque écriture composable rejouée sur le disque NFD sous
    les deux formes de charge utile rend la sortie de la référence ; sinon une ligne `~` qui nomme la limite (bf).
    Une différence nomme « jumeau NFD » ou « jumeau disque NFD », l'écriture et les deux décisions."""
    dossier_jugé = _dossier(ctx, script)
    d = ctx.copie_forcee(dossier_jugé, "armed")
    ordre, labs = parser_banc(open(ctx.banc, encoding="utf-8").read())
    insensible = disque_insensible(ctx)
    compte = {"G3": {"doit-refuser": 0, "doit-passer": 0}, "G4": {"doit-refuser": 0, "doit-passer": 0}}
    silences, jouees, ecarts = 0, 0, []
    disque_rejouees, disque_hors = 0, 0
    d1_labs, d1_chemins, d1_nfd_forme = 0, 0, 0
    for nom in ordre:
        composables = [e for e in labs[nom]["ecritures"] if jumeau_nfd(e["chemin"]) != e["chemin"]]
        nom_composable = any(jumeau_nfd(c) != c for c in list(labs[nom]["fichiers"]) + list(labs[nom]["dossiers"]))
        if not composables and not nom_composable:
            continue
        lab_nfc, lab_nfd, lab_disque = ctx.unique("nfd-nfc-" + nom), ctx.unique("nfd-nfd-" + nom), ctx.unique("nfd-disque-" + nom)
        materialiser(ctx, labs, nom, lab_nfc)
        materialiser(ctx, labs, nom, lab_nfd)
        materialiser_disque_nfd(ctx, labs, nom, lab_disque)
        for e in composables:
            jouees += 1
            r_nfc = ecrire_dans(ctx, d, lab_nfc, e["outil"], e["chemin"], agent=e["agent"])
            r_nfd = ecrire_dans(ctx, d, lab_nfd, e["outil"], jumeau_nfd(e["chemin"]), agent=e["agent"])
            v_nfc, v_nfd = classer(r_nfc[0], r_nfc[1]), classer(r_nfd[0], r_nfd[1])
            if insensible:
                for forme in (e["chemin"], jumeau_nfd(e["chemin"])):
                    r_disque = ecrire_dans(ctx, d, lab_disque, e["outil"], forme, agent=e["agent"])
                    disque_rejouees += 1
                    if r_disque != r_nfc:
                        ecarts.append("jumeau disque NFD de %s %s (charge %s) :: %s %s : disque NFC -> %s, disque NFD -> %s" % (
                            e["outil"], e["chemin"], "NFC" if forme == e["chemin"] else "NFD", e["attendu"], e["gate"],
                            v_nfc + " " + court(r_nfc[1], 80), classer(r_disque[0], r_disque[1]) + " " + court(r_disque[1], 80)))
            else:
                disque_hors += 1
            if r_nfc != r_nfd or r_nfc[2]:
                ecarts.append("jumeau NFD de %s %s :: %s %s : NFC -> %s, NFD -> %s" % (e["outil"], e["chemin"], e["attendu"], e["gate"], v_nfc + " " + court(r_nfc[1], 80),
                                                                                       v_nfd + " " + court(r_nfd[1], 80)))
                continue
            conforme = (v_nfc == "deny" and ("[planning-core] %s :" % e["gate"]) in raison_de(r_nfc[1])) if e["attendu"] == "doit-refuser" else (
                v_nfc in ("silence", "avertit") if e["attendu"] == "doit-passer" else v_nfc == "silence")
            if not conforme:
                ecarts.append("jumeau NFD de %s %s : la forme NFC elle-même ne rend pas l'attendu %s %s (%s)" % (e["outil"], e["chemin"], e["attendu"], e["gate"], v_nfc))
            elif e["attendu"] == "silence":
                silences += 1
            else:
                compte[e["gate"]][e["attendu"]] += 1
        if nom_composable:
            # D1 : SessionStart dans deux matérialisations FRAÎCHES (les écritures ci-dessus ne laissent aucune ligne `intention` dans ces journaux)
            lab_d1_nfc, lab_d1_nfd = ctx.unique("d1-nfc-" + nom), ctx.unique("d1-nfd-" + nom)
            materialiser(ctx, labs, nom, lab_d1_nfc)
            materialiser_disque_nfd(ctx, labs, nom, lab_d1_nfd, hors_planning_declare=True)
            r_a, r_b = session(ctx, d, lab_d1_nfc), session(ctx, d, lab_d1_nfd)
            wp_a, wp_b = surveilles_de(r_a[1]), surveilles_de(r_b[1])
            if wp_a is None or wp_b is None:
                ecarts.append("jumeau disque NFD de SessionStart (D1) du lab %s : sortie non conforme (NFC %s, disque NFD %s)" % (nom, court(r_a[1], 60), court(r_b[1], 60)))
            elif r_a[0] != r_b[0] or r_a[0] != 0 or r_a[2] or r_b[2]:
                ecarts.append("jumeau disque NFD de SessionStart (D1) du lab %s : code NFC %d, disque NFD %d, stderr %s %s" % (nom, r_a[0], r_b[0], court(r_a[2], 60), court(r_b[2], 60)))
            elif labs[nom]["jumeau_de"]:
                if wp_a or wp_b or r_a[1] != b"" or r_b[1] != b"":
                    ecarts.append("jumeau disque NFD de SessionStart (D1) du lab %s (hors adhésion) : doit se taire, NFC %s, disque NFD %s" % (nom, court(r_a[1], 60), court(r_b[1], 60)))
            else:
                liste_a, liste_b = relatifs_nfc(wp_a, os.path.realpath(lab_d1_nfc)), relatifs_nfc(wp_b, os.path.realpath(lab_d1_nfd))
                if liste_a != liste_b:
                    ecarts.append("jumeau disque NFD de SessionStart (D1) du lab %s : liste surveillée de %d chemin(s) sur le disque NFD, %d sur le disque NFC (absents du disque NFD : %s)" % (
                        nom, len(liste_b), len(liste_a), ", ".join([p for p in liste_a if p not in liste_b][:2]) or "-"))
                elif len(liste_a) <= 5:
                    ecarts.append("jumeau disque NFD de SessionStart (D1) du lab %s : preuve trop pauvre, %d chemin(s) surveillé(s) (au moins une unité attendue)" % (nom, len(liste_a)))
                elif not any(p != unicodedata.normalize("NFC", p) for p in wp_b):
                    ecarts.append("jumeau disque NFD de SessionStart (D1) du lab %s : aucun chemin surveillé en forme de disque NFD (le nom du disque construit le chemin d'accès)" % nom)
                elif journal_d1(lab_d1_nfc) != journal_d1(lab_d1_nfd):
                    j_nfc, j_nfd = journal_d1(lab_d1_nfc), journal_d1(lab_d1_nfd)
                    ecarts.append("jumeau disque NFD de SessionStart (D1) du lab %s : journal de D1 différent (%d ligne(s) NFC, %d disque NFD) ; NFC seul : %s ; disque NFD seul : %s" % (
                        nom, len(j_nfc), len(j_nfd), _lignes_seules(j_nfc - j_nfd), _lignes_seules(j_nfd - j_nfc)))
                else:
                    d1_labs += 1
                    d1_chemins = max(d1_chemins, len(liste_a))
                    d1_nfd_forme += sum(1 for p in wp_b if p != unicodedata.normalize("NFC", p))
    # D1, égalité de préfixe : `05-côté` et `05-cz`, listes égales en ordre, `05-côté` d'abord (nom NFC décroissant)
    lab_e_nfc, lab_e_nfd = ctx.unique("d1-egalite-nfc"), ctx.unique("d1-egalite-nfd")
    _ecrire_lab_egalite(lab_e_nfc, False)
    _ecrire_lab_egalite(lab_e_nfd, True)
    r_a, r_b = session(ctx, d, lab_e_nfc), session(ctx, d, lab_e_nfd)
    wp_a, wp_b = surveilles_de(r_a[1]), surveilles_de(r_b[1])
    egalite = "non joué"
    if not wp_a or not wp_b:
        ecarts.append("jumeau disque NFD de SessionStart (D1, égalité de préfixe) : liste vide (NFC %s, disque NFD %s)" % (court(r_a[1], 60), court(r_b[1], 60)))
    else:
        liste_a, liste_b = relatifs_nfc(wp_a, os.path.realpath(lab_e_nfc)), relatifs_nfc(wp_b, os.path.realpath(lab_e_nfd))
        cote, cz = ".planning/cycles/01-c/phases/05-côté/PLAN.md", ".planning/cycles/01-c/phases/05-cz/PLAN.md"
        if liste_a != liste_b:
            ecarts.append("jumeau disque NFD de SessionStart (D1, égalité de préfixe) : listes différentes en ordre (NFC %s ; disque NFD %s)" % (
                [p.split("/")[-2] for p in liste_a if p.endswith("/PLAN.md")], [p.split("/")[-2] for p in liste_b if p.endswith("/PLAN.md")]))
        elif cote not in liste_a or cz not in liste_a or liste_a.index(cote) > liste_a.index(cz):
            ecarts.append("jumeau disque NFD de SessionStart (D1, égalité de préfixe) : `05-côté` doit précéder `05-cz` (nom NFC décroissant), ordre rendu %s" % (
                [p.split("/")[-2] for p in liste_a if p.endswith("/PLAN.md")]))
        else:
            egalite = "05-côté avant 05-cz sur les deux disques"
    resume = "G3 refus=%d passage=%d ; G4 refus=%d passage=%d ; silence=%d ; %d écritures composables rejouées, jumeau NFD de décision identique ; D1 disque NFD : %d lab(s) adhérent(s), %d chemins surveillés dont %d en forme de disque NFD, journal identique, égalité de préfixe : %s ; disque NFD G3/G4 : %s" % (
        compte["G3"]["doit-refuser"], compte["G3"]["doit-passer"], compte["G4"]["doit-refuser"], compte["G4"]["doit-passer"], silences, jouees,
        d1_labs, d1_chemins, d1_nfd_forme, egalite, ("%d rejeux sous les deux formes de charge" % disque_rejouees) if insensible else "non exercé (système sensible)")
    if dossier_jugé == ctx.scripts_dir:
        print("COUVERTURE NFD " + resume)
        if not insensible:
            print("  ~ R-BANC-NFD (disque NFD, %d écritures G3/G4) non exercé (système de fichiers sensible à la normalisation, limite (bf))" % disque_hors)
    if ecarts:
        return False, "%d écart(s) : %s" % (len(ecarts), " | ".join(ecarts[:3]))
    if any(compte[g][k] < 1 for g in compte for k in compte[g]) or silences < 1 or d1_labs < 1 or egalite == "non joué":
        return False, "preuve trop pauvre : " + resume + " (attendu : au moins un refus et un passage par gate, un silence, un lab D1 conforme, l'égalité de préfixe)"
    return True, resume


# =================================================================================================
# R-CROISE-01 : un seul prédicat, deux consommateurs (G3 du hook, R4 du recalcul)
# =================================================================================================
RAISONS_R4 = ("livrable-absent:", "livrable-vide:", "livrable-hors-borne:", "ecrit-contient-unite:")
RAISONS_PLAN = ("ecrit-invalide", "frontmatter-invalide:PLAN.md", "CLOTURE.md-sans-PLAN.md")


def _entree_de(objet, chemin):
    """L'entrée du rapport du recalcul dont `chemin` est la valeur de la clé `chemin`, ou None."""
    if isinstance(objet, dict):
        if objet.get("chemin") == chemin:
            return objet
        for v in objet.values():
            r = _entree_de(v, chemin)
            if r is not None:
                return r
    elif isinstance(objet, list):
        for v in objet:
            r = _entree_de(v, chemin)
            if r is not None:
                return r
    return None


def controle_croise_01(ctx, script):
    """Pour chaque unité du banc dont le CLOTURE.md est écrit par outil : G3 (hook du dossier jugé, copie armée) refuse <=> l'état rendu par
    `recalc-planning.sh --read-only` pour l'unité, CLOTURE.md posé, est un indéterminé de livrable (R4 : livrable-absent:, livrable-vide:, livrable-hors-borne:,
    ecrit-contient-unite:) ou de PLAN.md (R1, R2). Une discordance est imprimée nommément."""
    d = ctx.copie_forcee(_dossier(ctx, script), "armed")
    ordre, labs, chemins = labs_banc(ctx)
    forme_unite = espace(ctx, "poser")["forme_unite"]
    discordances, n, refus, passages = [], 0, 0, 0
    for nom in ordre:
        if labs[nom]["jumeau_de"]:
            continue
        unites = []
        for e in labs[nom]["ecritures"]:
            composants = e["chemin"].split("/")
            if e["gate"] == "G3" and e["outil"] == "Write" and e["agent"] is None and composants[-1] == "CLOTURE.md" and forme_unite(composants[:-1]) \
                    and e["chemin"] not in unites:
                unites.append(e["chemin"])
        for cloture in unites:
            unite = cloture[:-len("/CLOTURE.md")]
            rc, out, err = jouer(ctx, d, chemins[nom], "Write", cloture)
            g3_refuse = classer(rc, out) == "deny" and "[planning-core] G3 :" in raison_de(out)
            copie = ctx.unique("croise-" + nom)
            shutil.copytree(chemins[nom], copie, symlinks=True)
            if not os.path.lexists(os.path.join(copie, cloture)):
                ecrire(os.path.join(copie, cloture), "Clôture.\n")
            p = subprocess.run(["bash", os.path.join(ctx.scripts_dir, "recalc-planning.sh"), "--planning=" + os.path.join(copie, ".planning"), "--read-only"],
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=ctx.env(), cwd=copie, timeout=120)
            entree = None
            if p.returncode == 0:
                try:
                    entree = _entree_de(json.loads(p.stdout.decode("utf-8")), unite[len(".planning/"):])
                except ValueError:
                    entree = None
            if entree is None:
                discordances.append("DISCORDANCE lab=%s unité=%s : l'unité est introuvable dans le rapport du recalcul (rc=%d)" % (nom, unite, p.returncode))
                continue
            raison = entree.get("raison")
            indetermine = isinstance(raison, str) and raison.startswith(RAISONS_R4 + RAISONS_PLAN)
            n += 1
            refus += 1 if g3_refuse else 0
            passages += 0 if g3_refuse else 1
            if g3_refuse != indetermine:
                discordances.append("DISCORDANCE lab=%s unité=%s : G3 %s, recalcul %s (%s)" % (nom, unite, "refuse" if g3_refuse else "laisse passer",
                                                                                                 entree.get("etat"), raison))
    for ligne in discordances:
        print(ligne)
    if discordances:
        return False, "%d discordance(s) entre G3 et R4 : %s" % (len(discordances), " | ".join(discordances[:3]))
    if n < 10 or refus < 3 or passages < 3:
        return False, "preuve trop pauvre : %d unités comparées (%d refus de G3, %d passages), attendu au moins 10, 3 et 3" % (n, refus, passages)
    return True, "%d unités du banc : G3 refuse exactement quand R4 du recalcul rend indéterminé (%d refus, %d passages), aucune discordance" % (n, refus, passages)


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


def sec_g3(ctx):
    for ident, ctrl, titre in (
            ("R-G3-01", controle_g3_01, "copie observe, livrable absent : une ligne gate=G3"),
            ("R-G3-02", controle_g3_02, "copie armée, refus"),
            ("R-G3-03", controle_g3_03, "copie armée, jumeaux qui passent"),
            ("R-G3-04", controle_g3_04, "dérogation et erreur interne"),
            ("R-PLAN-BORNE", controle_plan_borne, "PLAN.md au-delà de 1 Mio : refus explicite de G3 et G4, lecture bornée"),
            ("R-PLAN-BORNE-G2", controle_plan_borne_g2, "PLAN.md au-delà de 1 Mio : lecture bornée aussi par G2 (plans_ouverts), plan ignoré"),
            ("R-LECTURE-BORNEE", controle_lecture_bornee, "toute lecture d'un fichier du lab contrôlé par l'agent bornée : CADRAGE.md (G1), VERDICT.md (G4, juges), espion"),
            ("R-ADHESION-BORNEE", controle_adhesion_bornee, "config.json au-delà de la borne : adhésion indéterminée, code 3 sous PreToolUse, silence ailleurs, zéro régression hors adhésion"),
            ("R-JOURNAUX-BORNES", controle_journaux_bornes, "journal des dérogations et fichiers de D1 : lecture bornée, refus maintenu, silence de D1"),
            ("R-G3-05", controle_g3_05, "livrable hors borne : message distinct qui nomme la borne"),
            ("R-NFD-02", controle_nfd_02, "forme NFD : chemin mixte, voie cwd, lien à cible NFD, dérogation, copie observe")):
        bon, detail = original_de(ctx, ident, ctrl)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_g4(ctx):
    for ident, ctrl, titre in (
            ("R-G4-01", controle_g4_01, "copie observe, verdict absent : une ligne gate=G4"),
            ("R-G4-02", controle_g4_02, "copie armée, verdict absent, invalide, en échec, plan indéterminé, hors borne"),
            ("R-G4-03", controle_g4_03, "copie armée, verdict périmé (livrable, plan, hash_livrables retiré, livrable supprimé)"),
            ("R-G4-04", controle_g4_04, "copie armée, jumeaux qui passent"),
            ("R-G4-05", controle_g4_05, "dérogation et erreur interne"),
            ("R-G4-06", controle_g4_06, "aucun chemin absolu, « no such file » ni « can't open » dans un refus de G3 ou de G4")):
        bon, detail = original_de(ctx, ident, ctrl)
        ok(ident + " " + titre + " : " + detail) if bon else ko(ident, titre, "conforme", detail)


def sec_forme(ctx):
    bon, detail = original_de(ctx, "R-FORME-01", controle_forme_01)
    ok("R-FORME-01 " + detail) if bon else ko("R-FORME-01", "unite_de_fichier du hook et forme_unite de poser-verdict.sh rendent la même unité", "même unité", detail)


def sec_croise(ctx):
    bon, detail = original_de(ctx, "R-CROISE-01", controle_croise_01)
    ok("R-CROISE-01 " + detail) if bon else ko("R-CROISE-01", "G3 refuse exactement quand R4 du recalcul rend indéterminé (même prédicat, même chaîne)", "concordance", detail)


def sec_mutants_g3(ctx):
    tuer(ctx, "G3-LIVRABLE", "# g3-livrable", "if False:  # g3-livrable", "R-G3-02", controle_g3_02)
    tuer(ctx, "G3-FORME", "# g3-forme",
         'unite = composants[:-1] if composants and composants[0].casefold() == ".planning" and composants[-1].casefold() == "cloture.md" else None  # g3-forme',
         "R-G3-03", controle_g3_03)
    tuer(ctx, "G3-ADHESION", "sys.exit(0)  # non-adherent", "pass", "R-G3-03", controle_g3_03)
    tuer(ctx, "NFD-CHEMIN", "# nfc-chemin", 'return [c for c in rel.split(os.sep) if c not in ("", ".")]  # nfc-chemin', "R-BANC-NFD", controle_banc_nfd)
    # A1-readdir (fix-46-a tour 2) : le nom lu par readdir sans NFC -> l'unité au nom de disque NFD disparaît de la liste surveillée de D1 (jumeau disque NFD)
    tuer(ctx, "READDIR-NFC", "# nfc-readdir-unites", "if not NOM_UNITE.match(nom):  # nfc-readdir-unites", "R-BANC-NFD", controle_banc_nfd)
    # A1-readdir : le départage de `cle_recence` sans NFC -> `05-côté` du disque NFD passe après `05-cz` (cas d'égalité de préfixe)
    tuer(ctx, "RECENCE-NFC", "# nfc-recence", "return (len(chiffres), chiffres, nom)  # nfc-recence", "R-BANC-NFD", controle_banc_nfd)
    tuer(ctx, "G3-BORNE-MESSAGE", "# g3-borne", "if False:  # g3-borne", "R-G3-05", controle_g3_05)
    tuer(ctx, "PLAN-BORNE-TEST", "# plan-hors-borne", "if False:  # plan-hors-borne", "R-PLAN-BORNE", controle_plan_borne)
    tuer(ctx, "PLAN-LECTURE", "# plan-lecture-bornee", "octets = fh.read()  # plan-lecture-bornee", "R-PLAN-BORNE", controle_plan_borne)
    # re-ciblé (tour 2, A11-classe) : le défaut de `lire_frontmatter_fichier` valant BORNE_LECTURE_FICHIER (= BORNE_LECTURE_PLAN), retirer la borne explicite
    # est devenu un mutant équivalent ; celui-ci relâche la borne de G2 (2 * BORNE_LECTURE_PLAN)
    tuer(ctx, "PLAN-G2-BORNE", "# g2-plan-borne", 'statut, donnees = lire_frontmatter_fichier(os.path.join(dossier, "PLAN.md"), 2 * BORNE_LECTURE_PLAN)  # g2-plan-borne',
         "R-PLAN-BORNE-G2", controle_plan_borne_g2)
    tuer(ctx, "PLAN-G2-LECTURE", "# lff-lecture-bornee", "octets = fh.read()  # lff-lecture-bornee", "R-PLAN-BORNE-G2", controle_plan_borne_g2)
    tuer(ctx, "PLAN-G2-HORS-BORNE", "# lff-hors-borne", "if False:  # lff-hors-borne", "R-PLAN-BORNE-G2", controle_plan_borne_g2)
    # A11-classe (fix-46-a tour 2) : la borne générique, G1, G4, le vérificateur de juges
    tuer(ctx, "BORNE-GENERIQUE", "# lff-lecture-bornee", "octets = fh.read(); borne = len(octets)  # lff-lecture-bornee", "R-LECTURE-BORNEE", controle_lecture_bornee)
    tuer(ctx, "G1-BORNE-CADRAGE", "# g1-borne-cadrage", "if False:  # g1-borne-cadrage", "R-LECTURE-BORNEE", controle_lecture_bornee)
    tuer(ctx, "G4-BORNE-VERDICT", "# g4-borne-verdict", "if False:  # g4-borne-verdict", "R-LECTURE-BORNEE", controle_lecture_bornee)
    tuer(ctx, "JUGE-BORNE-VERDICT", "# juge-borne-verdict", "if False:  # juge-borne-verdict", "R-LECTURE-BORNEE", controle_lecture_bornee)
    # config.json : l'adhésion hors borne rendue non adhérente ; la clause de `main` retirée (la décision dans le doute refuse en code 0)
    tuer(ctx, "ADHESION-BORNE", "# adhesion-hors-borne", "return resultat  # adhesion-hors-borne", "R-ADHESION-BORNEE", controle_adhesion_bornee)
    tuer(ctx, "ADHESION-INCONNUE", "# adhesion-inconnue", "except ZeroDivisionError:  # adhesion-inconnue", "R-ADHESION-BORNEE", controle_adhesion_bornee)
    # journaux : derogation_active (appel direct), consommer (sous verrou), empreinte_fichier de D1
    tuer(ctx, "DEROG-BORNE", "# derog-borne-test", "if False:  # derog-borne-test", "R-JOURNAUX-BORNES", controle_journaux_bornes)
    tuer(ctx, "DEROG-VERROU", "# derog-borne-verrou", "if False:  # derog-borne-verrou", "R-JOURNAUX-BORNES", controle_journaux_bornes)
    tuer(ctx, "D1-LECTURE-HACHAGE", "# d1-lecture-hachage", "if False:  # d1-lecture-hachage", "R-JOURNAUX-BORNES", controle_journaux_bornes)


def sec_mutants_g4(ctx):
    tuer(ctx, "G4-ABSENT", "# g4-verdict-absent", "if False:  # g4-verdict-absent", "R-G4-02", controle_g4_02)
    tuer(ctx, "G4-ECHEC", "# g4-echec", "if False:  # g4-echec", "R-G4-02", controle_g4_02)
    tuer(ctx, "G4-PLAFOND-MESSAGE", "# g4-plafond-atteint", "if False:  # g4-plafond-atteint", "R-G4-02", controle_g4_02)  # F6
    tuer(ctx, "G4-HASH", "# g4-hash-plan", "if False:  # g4-hash-plan", "R-G4-03", controle_g4_03)
    tuer(ctx, "G4-HASH-LIVRABLES", "# g4-hash-livrables", 'if statut_emp != "ok":  # g4-hash-livrables', "R-G4-03", controle_g4_03)
    tuer(ctx, "G4-FAILOPEN", "# protege-erreur",
         'return [] if gate == "G4" else [Verdict(gate, None, "erreur interne du gate : " + type(exc).__name__)]  # protege-erreur', "R-G4-05", controle_g4_05)


def sec_mutants_croise(ctx):
    tuer(ctx, "CROISE", "# livrable-vide", "return taille >= 0  # livrable-vide", "R-CROISE-01", controle_croise_01)


SECTIONS = {
    "g3": sec_g3,
    "g4": sec_g4,
    "forme": sec_forme,
    "banc": sec_banc,
    "croise": sec_croise,
    "mutants_g3": sec_mutants_g3,
    "mutants_g4": sec_mutants_g4,
    "mutants_croise": sec_mutants_croise,
}


def main():
    scripts_dir, hooks_json, work, settings_lab, banc = sys.argv[2:7]
    ctx = Ctx(scripts_dir, hooks_json or None, work, settings_lab or None)
    ctx.banc = banc
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
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$HOOKS_JSON" "$WORK" "$SETTINGS_LAB" "$BANC" > "$out" 2>&1
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
[ -f "$SCRIPTS_DIR/poser-verdict.sh" ] || ko "poser-verdict.sh présent" "la commande de pose existe à côté du hook" "$SCRIPTS_DIR/poser-verdict.sh" "absent"
[ -f "$SCRIPTS_DIR/recalc-planning.sh" ] || ko "recalc-planning.sh présent" "le moteur de recalcul existe à côté du hook" "$SCRIPTS_DIR/recalc-planning.sh" "absent"
[ -n "$BANC" ] || ko "banc de clôture présent" "fixtures/cloture-banc.txt existe à côté des suites" "$TESTS_DIR/fixtures/cloture-banc.txt" "absent"
[ -f "$SCRIPTS_DIR/deroger-gate.sh" ] || ko "deroger-gate.sh présent" "la commande de dérogation existe à côté du hook" "$SCRIPTS_DIR/deroger-gate.sh" "absent"
if [ -z "$HOOKS_JSON" ] && [ -z "$SETTINGS_LAB" ]; then
  echo "NOTE : ni hooks.json ni settings.json à côté des scripts (suite lancée hors dépôt) : la commande enregistrée n'est pas lisible, rien n'est rejoué."
else
  run_sections "${VF_CLOT_SECTIONS:-g3,g4,forme,banc,croise,mutants_g3,mutants_g4,mutants_croise}"
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
