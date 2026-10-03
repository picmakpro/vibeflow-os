#!/usr/bin/env bash
# test-planning-prefilter.sh — garde d'ÉQUIVALENCE du pré-filtre hors adhésion de la commande enregistrée du hook central (Phase 45 ;
# revue de Samuel sur la PR #124 du 2026-10-01 ; arbitrage de Willy, AskUserQuestion session principale, 2026-10-02 : le pré-filtre
# seul, Bash RESTE dans le matcher). Un hook ne paie son coût que là où il a un effet : la commande court-circuite (`exit 0`, ni
# script, ni mktemp, ni python3) quand le lab est CERTAINEMENT non adhérent, et ne change RIEN, octet pour octet, dans tous les
# autres cas (adhérent, doute, valeur non analysable). Le pré-filtre est un nouveau chemin de sortie rapide : un candidat au
# fail-open, d'où cette garde.
#
# Trois commandes sont rejouées, lues dans hooks.json : la COMPLÈTE (celle que le harnais exécute), la même SANS pré-filtre (bloc
# retiré : la couche shell d'avant, octet pour octet) et la même TRONQUÉE à l'appel du pré-filtre (rend SHORT ou DEFER).
#
# Propriété (A) : chaque fois que le pré-filtre court-circuite (SHORT), la commande SANS pré-filtre rend 0 octet et code 0, script
#   présent comme script absent, et la commande complète aussi.
# Propriété (B) : le pré-filtre ne court-circuite JAMAIS là où le CŒUR juge le lab adhérent (oracle = racine_lab, verifier_adhesion
#   et cible_de du hook, chargés depuis planning-hook.sh).
# Propriété (E) : chaque fois que le pré-filtre DIFFÈRE, la commande complète rend exactement la sortie de la commande sans pré-filtre
#   (un cas sur huit, script présent ; un sur seize, script absent) : il ne laisse ni variable ni effet de bord derrière lui.
# Propriété (C) : les quatre shells présents (sh, dash, bash, zsh) rendent le même verdict SHORT/DEFER (tout le banc, un cas sur trois du reste).
# Propriété (D) : tableau des DIFFÉRÉS PAR CONSTRUCTION (valeur longue, antislash, `~`, relatif, `//`, `.`/`..`, `/.vol`, JSON non
#   compact, clé échappée, config illisible ou non régulière, lien pendant…) : le pré-filtre ne court-circuite pas, même quand le cœur
#   les jugerait non adhérents (il est PLUS conservateur que le cœur) ; et un plancher de court-circuits (jamais un vert à vide).
#
# Corpus : (1) gates-banc.txt, chaque écriture jouée par les six outils ; (2) arbres adverses des audits (liens symboliques et durs,
#   pendants, boucles, `.planning` imbriqués, `.claude/worktrees`, `.PLANNING`, Unicode U+212A, config échappée, illisible, FIFO…) ×
#   formes de chemin (`//`, `.`, `..`, relatif, `~`, échappements JSON, valeur longue, surrogate, NUL, clés dupliquées ou échappées,
#   JSON non compact) ; (3) le générateur de valeurs longues de controle_generatif ; (4) un générateur d'arbres de labs aléatoires.
#
# Propriété (F) : bornes et coût (re-audit du pré-filtre, 2026-10-02, F-P1 et F-P2). Le pré-filtre DIFFÈRE dès qu'une valeur dépasse 1024
#   caractères ou 64 composants, qu'une correspondance brute dépasse 2048 caractères ou que le payload porte plus de 16 valeurs (PF-BORNE-01,
#   autour de chaque borne, lab non adhérent et adhérent, script présent et absent, sortie identique à la commande sans pré-filtre) ; son
#   coût est borné (PF-COUT-01 : sous 5 s sur des valeurs propres de 1 000 à 4 096 caractères, et nombre d'appels à `vf_pc` exact, tueur
#   structurel indépendant de l'horloge). Propriété (G) : le coût d'une exécution ne dépend d'AUCUN contenu du système de fichiers que l'agent
#   contrôle (re-audit, tour 2, F-P3 et F-P4 ; PF-CREUX-01) : une config de plus de 64 Kio (creuse de 2 Gio, lien vers elle, de 1 Mio, sur un
#   ancêtre) fait DIFFÉRER avant toute lecture, 64 lectures de config au plus par exécution (copie instrumentée : le nombre de `grep` d'une
#   `config.json` est compté, jamais déduit de l'horloge), `_pa` et le compteur hérités de l'environnement sans effet. Les sections se lancent une à une : VF_PF_SECTIONS=table,bornes | corpus | mutants, et
#   VF_PF_MUT=<préfixes de mutants séparés par des virgules> (la suite entière dépasse dix minutes sur une machine chargée).
#
# Mutants (chacun doit rougir la garde, trace nom · assertion · attendu · obtenu) : (i) sortie trop tôt — sans vérifier cycles-v1, sans le
# cwd du payload, sans le cwd du processus, sans les ancêtres ; (ii) sans résolution physique, sans le lien pendant ; (iii) valeur longue,
# antislash, clé échappée, JSON non compact, `/.vol` acceptés ; (v) sans borne de taille de config, sans budget de lectures, `_pa` ou compteur non
# initialisés, mesure de taille sans suivre le lien, borne de taille déplacée.
#
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; `cmp -s` jamais `diff`. Lançable depuis tout cwd.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
HOOKS_JSON="$SCRIPTS_DIR/../hooks/hooks.json"
BANC="$TESTS_DIR/fixtures/gates-banc.txt"

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-planning-prefilter] python3 requis" >&2; exit 1; fi
    ;;
esac

if [ ! -f "$HOOKS_JSON" ] || [ ! -f "$BANC" ] || [ ! -f "$SCRIPTS_DIR/planning-hook.sh" ]; then
  echo "NOTE hors dépôt : hooks.json, gates-banc.txt ou planning-hook.sh absent à côté de la suite — garde d'équivalence non rejouée (jamais un vert)"
  echo "== Résultat : 0 OK · 0 KO =="
  exit 0
fi

pass=0; fail=0
WORK="$(mktemp -d)"
trap 'chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT
T_DEBUT="$(date +%s)"

AIDES="$WORK/aides.py"
cat > "$AIDES" <<'PY_AIDES_PREFILTRE_EOF'
import concurrent.futures
import json
import os
import posixpath
import random
import re
import shutil
import stat
import subprocess
import sys
import time

TOKEN = "{{VF_SCRIPTS}}"
APPEL = "vf_pre && exit 0\n"
DEBUT = "_pn='\n'\nvf_pp()"
OUTILS = ("Write", "Edit", "NotebookEdit", "Bash", "Agent", "Task")
GRAINE = 20261002
N_GEN = int(os.environ.get("VF_PF_N", "300"))
N_ARBRES = int(os.environ.get("VF_PF_ARBRES", "40"))


def ok(libelle):
    print("  ✓ " + libelle)


def ko(libelle, assertion, attendu, obtenu):
    print("  ✗ " + libelle)
    print("    assertion : " + str(assertion))
    print("    attendu   : " + str(attendu))
    print("    obtenu    : " + str(obtenu))


def court(x, n=200):
    t = x.decode("utf-8", "replace") if isinstance(x, bytes) else str(x)
    t = t.replace("\n", "\\n")
    return t if len(t) <= n else t[:n] + "…(+%d)" % (len(t) - n)


# --- payloads ------------------------------------------------------------------------------------
def payload_obj(outil, entree, cwd):
    obj = {"session_id": "sess-test", "transcript_path": "transcript.jsonl"}
    if cwd is not None:
        obj["cwd"] = cwd
    obj.update({"prompt_id": "prompt-test", "permission_mode": "default", "hook_event_name": "PreToolUse", "tool_name": outil,
                "tool_input": entree, "tool_use_id": "toolu_test"})
    return obj


def entree_outil(outil, chemin):
    if outil == "Bash":
        return {"command": "true"}
    if outil in ("Agent", "Task"):
        return {"description": "d", "prompt": "p", "subagent_type": "general-purpose"}
    if outil == "NotebookEdit":
        return {"notebook_path": chemin, "new_source": "x"}
    if outil == "Edit":
        return {"file_path": chemin, "old_string": "a", "new_string": "b"}
    return {"file_path": chemin, "content": "x"}


def compact(obj, ascii_=False):
    return json.dumps(obj, separators=(",", ":"), ensure_ascii=ascii_).encode("utf-8", "surrogatepass")


class Cas:
    def __init__(self, cat, ident, brut, cwd_proc, note="", doit_differer=False):
        self.cat, self.ident, self.brut, self.cwd_proc, self.note, self.doit_differer = cat, ident, brut, cwd_proc, note, doit_differer
        self.oracle = None


def ecrire(chemin, contenu, mode="w"):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, mode, **({"encoding": "utf-8"} if "b" not in mode else {})) as fh:
        fh.write(contenu)


# --- commandes : complète, sans pré-filtre, tronquée -------------------------------------------------
class Ctx:
    def __init__(self, scripts_dir, hooks_json, banc, work):
        self.scripts_dir, self.banc, self.work = scripts_dir, banc, work
        self.home = os.path.join(work, "home")
        os.makedirs(self.home, exist_ok=True)
        self.vide = os.path.join(work, "scripts-vides")
        os.makedirs(self.vide, exist_ok=True)
        d = json.load(open(hooks_json, encoding="utf-8"))
        cands = [h["command"] for g in d["hooks"]["PreToolUse"] for h in g["hooks"] if "planning-hook.sh" in h.get("command", "")]
        if len(cands) != 1:
            raise SystemExit("commande enregistrée introuvable")
        self.cmd = cands[0]
        self.cmd_np, self.cmd_pre = self.derive(self.cmd)
        self.n = 0
        self.shells = [("sh", ["/bin/sh", "-c"])]
        for nom in ("dash", "bash", "zsh"):
            w = shutil.which(nom)
            if w:
                self.shells.append((nom, [w, "-f", "-c"] if nom == "zsh" else [w, "-c"]))
        # le cœur, chargé pour servir d'oracle d'adhésion (racine_lab, verifier_adhesion, cible_de, lire_payload)
        texte = open(os.path.join(scripts_dir, "planning-hook.sh"), encoding="utf-8").read()
        corps, dedans = [], False
        for l in texte.split("\n"):
            if l == "PY_PLANNING_HOOK_EOF":
                dedans = False
            if dedans:
                corps.append(l)
            if l.endswith("<<'PY_PLANNING_HOOK_EOF'"):
                dedans = True
        self.ns = {"__name__": "hook_core"}
        exec(compile("\n".join(corps) + "\n", "planning-hook.sh", "exec"), self.ns)

    @staticmethod
    def derive(cmd):
        """(commande sans pré-filtre, commande tronquée à l'appel). Rend (None, None) si le bloc est absent ou en double."""
        if cmd.count(APPEL) != 1 or cmd.count(DEBUT) != 1 or cmd.index(DEBUT) > cmd.index(APPEL):
            return None, None
        np = cmd[:cmd.index(DEBUT)] + cmd[cmd.index(APPEL) + len(APPEL):]
        pre = cmd.replace(APPEL, "if vf_pre; then printf SHORT; else printf DEFER; fi\nexit 0\n")
        return np, pre

    def unique(self, p):
        self.n += 1
        return os.path.join(self.work, "%s-%d" % (p, self.n))

    def env(self, extra=None):
        e = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": self.home}
        if extra:
            e.update(extra)
        if os.environ.get("TMPDIR"):
            e["TMPDIR"] = os.environ["TMPDIR"]
        return e

    def texte(self, cmd, dossier):
        if TOKEN in cmd:
            return cmd.replace(TOKEN, "'" + dossier + "'"), {}
        raise SystemExit("jeton {{VF_SCRIPTS}} attendu dans hooks.json")

    def lancer(self, cmd, brut, cwd, dossier=None, shell=None, tmo=120, env_extra=None):
        t, _ = self.texte(cmd, dossier or self.scripts_dir)
        argv = shell or ["/bin/sh", "-c"]
        if argv[0].endswith("zsh"):
            t = "emulate sh\n" + t
        try:
            p = subprocess.run(argv + [t], input=brut, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=self.env(env_extra), cwd=cwd, timeout=tmo)
        except subprocess.TimeoutExpired:
            return -9, b"", b"TIMEOUT"
        return p.returncode, p.stdout, p.stderr

    def pre(self, cmd_pre, cas, shell=None):
        rc, out, err = self.lancer(cmd_pre, cas.brut, cas.cwd_proc, shell=shell)
        return out.decode("utf-8", "replace") if rc == 0 else "ERR rc=%d %s" % (rc, court(err))

    def coeur(self, cas):
        """Oracle : ce que le cœur juge de ce payload — `adherent`, `non`, `invalide` (JSON refusé, code 3), `doute` (l'analyse lève)."""
        ns = self.ns
        f = self.unique("transport")
        with open(f, "wb") as fh:
            fh.write(cas.brut)
        sauve = os.getcwd()
        try:
            os.chdir(cas.cwd_proc)
            try:
                payload = ns["lire_payload"](f)
            except BaseException:
                return "invalide"
            try:
                ecrit, cwd, variantes = ns["cible_de"](payload, self.home)
                depart = ecrit if ecrit is not None else (cwd if cwd is not None else os.getcwd())
                racine = ns["racine_lab"](depart)
                adh = racine is not None and ns["verifier_adhesion"](os.path.join(racine, ".planning"))["adherente"]
                for forme in variantes:
                    r2 = ns["racine_lab"](forme)
                    if r2 is not None and ns["verifier_adhesion"](os.path.join(r2, ".planning"))["adherente"]:
                        adh = True
            except BaseException:
                return "doute"
            return "adherent" if adh else "non"
        finally:
            os.chdir(sauve)
            try:
                os.unlink(f)
            except OSError:
                pass


# --- arbres de labs ------------------------------------------------------------------------------------
ADH = '{"planning_version": "cycles-v1"}'
DEV = '{"planning_version": "autre"}'


def lab(chemin, config=ADH, planning=".planning"):
    os.makedirs(chemin, exist_ok=True)
    if config is not None:
        ecrire(os.path.join(chemin, planning, "config.json"), config)
    else:
        os.makedirs(os.path.join(chemin, planning), exist_ok=True)
    return chemin


def foret(ctx):
    """Les arbres adverses (labs adhérents, non adhérents, imbriqués, liens, config piégée). Rend un dict nom → chemin physique absolu."""
    R = os.path.realpath(ctx.unique("foret"))
    os.makedirs(R)
    L = {}
    L["adh"] = lab(R + "/adh")
    L["dev"] = lab(R + "/dev", DEV)
    L["nodev"] = lab(R + "/nodev", None)
    L["plain"] = R + "/plain"
    os.makedirs(L["plain"] + "/a/b")
    lab(L["adh"] + "/sub/dev2", DEV)
    lab(L["dev"] + "/sub/adh2")
    ecrire(L["adh"] + "/.planning/.planning/config.json", ADH)
    ecrire(L["dev"] + "/.claude/.planning/config.json", ADH)
    L["wt"] = lab(L["dev"] + "/.claude/worktrees/w1")
    os.makedirs(L["wt"] + "/sub")
    L["esc"] = lab(R + "/esc", '{"planning_version": "cycles\\u002dv1"}')
    L["esckey"] = lab(R + "/esckey", '{"planning\\u005fversion":"cycles-v1"}')
    L["bs"] = lab(R + "/bs", '{"planning_version": "autre", "chemin": "C:\\\\x"}')
    L["majus"] = lab(R + "/majus", '{"PLANNING_VERSION": "CYCLES-V1"}')
    L["cfgdir"] = R + "/cfgdir"
    os.makedirs(L["cfgdir"] + "/.planning/config.json")
    L["fifo"] = R + "/fifo"
    os.makedirs(L["fifo"] + "/.planning")
    os.mkfifo(L["fifo"] + "/.planning/config.json")
    L["illisible"] = lab(R + "/illisible", ADH)
    os.chmod(L["illisible"] + "/.planning/config.json", 0)
    L["cfglink"] = lab(R + "/cfglink", None)
    os.symlink(L["adh"] + "/.planning/config.json", L["cfglink"] + "/.planning/config.json")
    L["dur"] = lab(R + "/dur", None)
    os.link(L["adh"] + "/.planning/config.json", L["dur"] + "/.planning/config.json")
    L["invalide"] = lab(R + "/invalide", "{pas du json cycles-v1")
    L["bom"] = lab(R + "/bom", "\ufeff" + ADH)
    L["majd"] = R + "/majd"
    ecrire(L["majd"] + "/.PLANNING/config.json", ADH)
    L["kelvin"] = lab(R + "/lab\u212a")
    L["longs"] = lab(R + "/l\u017fong")
    L["accent"] = lab(R + "/élodie lab")
    # liens
    os.symlink(L["adh"], R + "/lnk-adh")
    os.symlink(L["adh"] + "/inexistant", R + "/pend-adh")
    os.symlink(L["dev"] + "/inexistant", R + "/pend-dev")
    os.symlink(R + "/boucle2", R + "/boucle1")
    os.symlink(R + "/boucle1", R + "/boucle2")
    os.symlink(L["adh"] + "/.planning/config.json", R + "/lnk-fichier")
    os.symlink(L["adh"] + "/sub", R + "/lnk-sub")
    os.symlink("../adh", L["dev"] + "/lnk-haut")
    os.symlink(L["dev"], L["adh"] + "/lnk-dev")
    os.symlink(L["plain"], R + "/lnk-plain")
    # HOME : un lab adhérent sous le home de la suite
    L["hl"] = lab(ctx.home + "/hl")
    # préfixe de nom : `pfx` (adhérent) et `pfx-dev` (non adhérent) ; la mémoire du préfixe vérifié ne doit jamais tenir `pfx` pour un ancêtre de `pfx-dev/…`
    L["pfx"] = lab(R + "/pfx")
    L["pfxdev"] = lab(R + "/pfx-dev", DEV)
    L["racine"] = R
    return L


SUFFIXES = ("", "/x.md", "/.planning/STATE.md", "/.claude/scripts/planning-hook.sh", "/sub/neuf/profond.md", "/.planning/cycles/01-c/notes.md")


def varier(path, cwd, outil, rng, L, sel=None):
    """Formes d'écriture d'un même chemin : liste de (étiquette, octets, doit_differer). `doit_differer` : le pré-filtre ne doit PAS
    court-circuiter, quel que soit le jugement du cœur (D, plus conservateur que le cœur)."""
    cle = "notebook_path" if outil == "NotebookEdit" else "file_path"
    out = []

    def mk(etiq, chemin, cwd_p=cwd, differer=False, transf=None, ascii_=False, pretty=False):
        obj = payload_obj(outil, entree_outil(outil, chemin), cwd_p)
        if pretty:
            brut = json.dumps(obj, indent=2, ensure_ascii=ascii_).encode("utf-8", "surrogatepass")
        else:
            brut = compact(obj, ascii_)
        if transf:
            texte = brut.decode("utf-8", "surrogatepass")
            texte = transf(texte)
            brut = texte.encode("utf-8", "surrogatepass")
        out.append((etiq, brut, differer))

    mk("plain", path)
    if outil in ("Bash", "Agent", "Task"):
        mk("sans-cwd", path, cwd_p=None)
        mk("cwd-relatif", path, cwd_p="rel/cwd", differer=True)
        mk("cwd-slash-final", path, cwd_p=(cwd or "/") + "/", differer=True)
        mk("cwd-point", path, cwd_p=(cwd or "") + "/.", differer=True)
        mk("cwd-point-point", path, cwd_p=(cwd or "") + "/sub/..", differer=True)
        mk("cwd-vide", path, cwd_p="", differer=True)
        mk("cwd-echappe", path, cwd_p=(cwd or "") + "\\", differer=True)
        mk("cwd-pretty", path, pretty=True, differer=True)
        mk("cwd-long", path, cwd_p=(cwd or "") + "/" + ("zz" * 2100), differer=True)
        mk("cwd-vol", path, cwd_p="/.vol/1/2", differer=True)
        mk("cwd-tilde", path, cwd_p="~/hl", differer=True)
        return out
    p = path
    mk("double-slash", p.replace("/", "//", 2), differer=True)
    if "/" in p[1:]:
        base, _, reste = p.rpartition("/")
        mk("point", base + "/./" + reste, differer=True)
        mk("point-point", base + "/x/../" + reste, differer=True)
        mk("point-point-lien", base + "/../" + posixpath.basename(base) + "/" + reste, differer=True)
    mk("slash-final", p + "/", differer=True)
    mk("relatif", os.path.relpath(p, cwd) if cwd else p[1:], differer=True)
    mk("relatif-cwd-adh", "x.md", cwd_p=L["adh"], differer=True)
    mk("relatif-cwd-dev", "x.md", cwd_p=L["dev"], differer=True)
    mk("tilde", "~/hl/.planning/STATE.md", differer=True)
    mk("tilde-seul", "~", differer=True)
    mk("tilde-user", "~bob/x.md", differer=True)
    mk("slash-echappe", p, transf=lambda t: t.replace('"' + p + '"', '"' + p.replace("/", "\\/") + '"', 1), differer=True)
    mk("planning-unicode-echappe", p.replace(".planning", "@@DOT@@planning") if ".planning" in p else p + "@@DOT@@",
       differer=True, transf=lambda t: t.replace("@@DOT@@", "\\u002e"))
    mk("majuscules", re.sub(r"\.planning", ".PLANNING", p), differer=False)
    mk("casse-lab", p.upper(), differer=False)
    mk("kelvin", p.replace("/dev", "/de\u212av"), differer=False)
    mk("antislash", p + "\\x", differer=True)
    mk("nul", p + "@@NUL@@x", differer=True, transf=lambda t: t.replace("@@NUL@@", "\\u0000"))
    mk("surrogate", p + "@@SUR@@", differer=True, transf=lambda t: t.replace("@@SUR@@", "\\ud800"))
    mk("octet-invalide", p + "\udcff", differer=False)
    mk("long", p + "/" + ("x" * 300 + "/") * 30 + "f.md", differer=True)
    mk("long-planning", p + "/" + ("x" * 300 + "/") * 30 + ".planning/f.md", differer=True)
    mk("vol", "/.vol/1/2/x", differer=True)
    mk("vol-majuscules", "/.VOL/1/2/x", differer=True)
    mk("pretty", p, pretty=True, differer=True)
    mk("pretty-ascii", p, pretty=True, ascii_=True, differer=True)
    mk("cle-echappee", p, differer=True, transf=lambda t: t.replace('"' + cle + '"', '"\\u' + "%04x" % ord(cle[0]) + cle[1:] + '"', 1))
    mk("cle-echappee-maj", p, differer=True, transf=lambda t: t.replace('"' + cle + '"', '"\\u' + "%04X" % ord(cle[0]) + cle[1:] + '"', 1))
    mk("espaces", p, transf=lambda t: t.replace('"' + cle + '":', '"' + cle + '" \t :  ', 1), differer=False)
    mk("cle-doublee", p, transf=lambda t: t.replace('"' + cle + '":', '"' + cle + '":"' + L["dev"] + '/y.md","' + cle + '":', 1), differer=False)
    mk("cle-doublee-inverse", L["dev"] + "/y.md", transf=lambda t: t.replace('"' + cle + '":', '"' + cle + '":"' + p + '","' + cle + '":', 1), differer=False)
    mk("sans-cwd", p, cwd_p=None)
    mk("cwd-autre-adh", p, cwd_p=L["adh"])
    mk("cwd-autre-dev", p, cwd_p=L["dev"])
    mk("cwd-tmp", p, cwd_p="/tmp")
    return out


# --- générateur de valeurs longues (porté de controle_generatif) ------------------------------------------
def json_litteral(texte):
    return json.dumps(texte, ensure_ascii=True)[1:-1]


def nom_sous_forme(rng, nom):
    s = []
    for c in nom:
        f = rng.randrange(4)
        s.append(c if f == 0 else c.swapcase() if f == 1 else "\\u%04x" % ord(c) if f == 2 else "\\u%04X" % ord(c))
    return "".join(s)


def rembourrage(rng):
    f = rng.randrange(4)
    if f == 0:
        return "./" * rng.randrange(2100, 3000)
    if f == 1:
        return "a/../" * rng.randrange(900, 1200)
    if f == 2:
        n = rng.randrange(1100, 1500)
        return "a/" * n + "../" * n
    return ("x" * rng.randrange(200, 400) + "/") * rng.randrange(25, 35)


def valeur_generative(rng, avec_nom, bases, noms=(".planning", ".claude"), restes=("/STATE.md", "/scripts/x.sh", "/cycles/01-c/notes.md", "")):
    base = rng.choice(bases)
    pad = rembourrage(rng)
    reste = rng.choice(restes)
    if avec_nom:
        return json_litteral(base + "/" + pad) + nom_sous_forme(rng, rng.choice(noms)) + json_litteral(reste)
    return json_litteral(base + "/" + pad + "n" + reste + "/f.md")


def payload_brut(outil, chemin_json, cwd, cle="file_path"):
    obj = payload_obj(outil, {cle: "@@F@@", "content": "x"}, cwd)
    t = json.dumps(obj, separators=(",", ":"), ensure_ascii=True)
    return t.replace('"@@F@@"', '"' + chemin_json + '"', 1).encode("ascii")


# --- banc ------------------------------------------------------------------------------------------------
def parser_banc(texte):
    lignes = texte.split("\n")
    if lignes and lignes[-1] == "":
        lignes = lignes[:-1]
    labs, ordre = {}, []
    lab_c, fichier, contenu = None, None, []

    def clore():
        if lab_c is not None and fichier is not None:
            labs[lab_c]["fichiers"][fichier] = "".join(l + "\n" for l in contenu)

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
            lab_c = d[4:].split()[0]
            labs[lab_c] = {"fichiers": {}, "dossiers": [], "liens": [], "ecritures": []}
            ordre.append(lab_c)
        elif d.startswith("dossier "):
            labs[lab_c]["dossiers"].append(d[8:].strip())
        elif d.startswith("fichier "):
            fichier, contenu = d[8:].strip(), []
        elif d.startswith("lien "):
            chemin, cible = [p.strip() for p in d[5:].strip().split(" -> ", 1)]
            labs[lab_c]["liens"].append((chemin, cible))
        elif d.startswith("ecriture "):
            gauche = d[9:].split(" :: ", 1)[0]
            m = gauche.split(" ", 2)
            e = {"outil": m[0], "chemin": m[1], "cwd": None}
            for jeton in (m[2].split(" ") if len(m) > 2 else []):
                if jeton.startswith("cwd="):
                    e["cwd"] = jeton[4:]
            labs[lab_c]["ecritures"].append(e)
    clore()
    return ordre, labs


def corpus_banc(ctx):
    ordre, labs = parser_banc(open(ctx.banc, encoding="utf-8").read())
    racine = os.path.realpath(ctx.unique("banc"))
    cas = []
    for nom in ordre:
        dest = os.path.join(racine, nom)
        os.makedirs(dest, exist_ok=True)
        for d in labs[nom]["dossiers"]:
            os.makedirs(os.path.join(dest, d), exist_ok=True)
        for chemin, contenu in labs[nom]["fichiers"].items():
            ecrire(os.path.join(dest, chemin), contenu)
        for chemin, cible in labs[nom]["liens"]:
            os.makedirs(os.path.dirname(os.path.join(dest, chemin)), exist_ok=True)
            os.symlink(cible, os.path.join(dest, chemin))
    for nom in ordre:
        dest = os.path.join(racine, nom)
        lots = [(e["chemin"], e["cwd"]) for e in labs[nom]["ecritures"]] + [("-", None)]
        for i, (rel, cwd_rel) in enumerate(lots):
            chemin = dest + "/" + rel if rel != "-" else dest + "/.planning/notes.md"
            cwd = dest + "/" + cwd_rel if cwd_rel else dest
            os.makedirs(cwd, exist_ok=True)
            for outil in OUTILS:
                cas.append(Cas("banc", "banc:%s:%d:%s" % (nom, i, outil), compact(payload_obj(outil, entree_outil(outil, chemin), cwd)), cwd,
                               "%s %s" % (nom, rel)))
    return cas


# --- corpus adverse --------------------------------------------------------------------------------------
IMPORTANTS = {"adh", "dev", "lnk-adh", "pend-adh", "esc", "illisible", "wt", "fifo", "lnk-sub"}


def corpus_adverse(ctx, L):
    rng = random.Random(GRAINE)
    cas = []
    cibles = []
    for nom, base in sorted(L.items()):
        if nom == "racine":
            continue
        for s in SUFFIXES:
            cibles.append((nom, base + s))
    for nom in ("lnk-adh", "pend-adh", "pend-dev", "boucle1", "lnk-fichier", "lnk-sub", "lnk-plain"):
        for s in ("/x.md", "/.planning/STATE.md", "/neuf/y.md", ""):
            cibles.append((nom, L["racine"] + "/" + nom + s))
    cibles.append(("lnk-haut", L["dev"] + "/lnk-haut/.planning/STATE.md"))
    cibles.append(("lnk-haut-pp", L["dev"] + "/lnk-haut/../adh/.planning/STATE.md"))
    cibles.append(("lnk-dev", L["adh"] + "/lnk-dev/x.md"))
    cibles.append(("lnk-pp", L["racine"] + "/lnk-sub/../.planning/STATE.md"))
    cibles.append(("pend-pp", L["racine"] + "/pend-adh/../x.md"))
    for nom, chemin in cibles:
        outils = OUTILS if rng.random() < 0.25 else ("Write", "Edit", "NotebookEdit", "Bash", "Agent")[: 2 + rng.randrange(3)]
        for outil in outils:
            cwds = [L["adh"], L["dev"], os.path.dirname(chemin) if os.path.isdir(os.path.dirname(chemin)) else L["plain"], "/tmp"]
            cwd = rng.choice(cwds)
            proc = rng.choice((cwd, L["dev"], L["adh"], L["plain"], L["racine"]))
            vs = varier(chemin, cwd, outil, rng, L)
            if nom not in IMPORTANTS and len(vs) > 5:
                vs = rng.sample(vs, 5)
            for etiq, brut, differer in vs:
                cas.append(Cas("adverse", "adv:%s:%s:%s" % (nom, outil, etiq), brut, proc, "%s %s" % (nom, chemin[-50:]), differer))
    # cas déterministes : cwd et processus HORS lab, cible par lien, par lien pendant, par fichier lié (discriminent les mutants de résolution)
    for nom, chemin in (("lnk-adh", L["racine"] + "/lnk-adh/x.md"), ("pend-adh", L["racine"] + "/pend-adh/x.md"), ("lnk-sub", L["racine"] + "/lnk-sub/x.md"),
                        ("lnk-sub-pp", L["racine"] + "/lnk-sub/../.planning/STATE.md"), ("lnk-fichier", L["racine"] + "/lnk-fichier"),
                        ("adh", L["adh"] + "/.planning/STATE.md"), ("wt", L["wt"] + "/sub/x.md"), ("esc", L["esc"] + "/x.md"), ("dur", L["dur"] + "/x.md"),
                        ("cfglink", L["cfglink"] + "/x.md"), ("hl", L["hl"] + "/x.md"), ("accent", L["accent"] + "/x.md"), ("kelvin", L["kelvin"] + "/x.md")):
        for outil in ("Write", "Edit", "NotebookEdit"):
            cas.append(Cas("adverse", "adv:det:%s:%s" % (nom, outil), compact(payload_obj(outil, entree_outil(outil, chemin), L["dev"])), L["dev"], "cible %s, cwd et processus en lab dev" % nom))
            cas.append(Cas("adverse", "adv:det-plain:%s:%s" % (nom, outil), compact(payload_obj(outil, entree_outil(outil, chemin), L["plain"])), L["plain"], "cible %s, hors lab" % nom))
    for nom in ("adh", "wt", "esc", "dur", "cfglink", "hl", "accent", "kelvin", "lnk-adh"):
        base = L[nom] if nom in L else L["racine"] + "/" + nom
        for outil in ("Bash", "Agent", "Task"):
            cas.append(Cas("adverse", "adv:det-cwd:%s:%s" % (nom, outil), compact(payload_obj(outil, entree_outil(outil, None), base)), L["plain"], "cwd du payload dans %s, processus hors lab" % nom))
    # /.vol réel : le dossier .planning d'un lab adhérent et le lab lui-même, par numéro d'inode
    if os.path.isdir("/.vol"):
        for nom in ("adh", "dev"):
            st = os.stat(L[nom])
            stp = os.stat(L[nom] + "/.planning")
            for rel, sdir in (("/.planning/STATE.md", st), ("/STATE.md", stp), ("/x.md", st)):
                for outil in ("Write", "Bash"):
                    chemin = "/.vol/%d/%d%s" % (sdir.st_dev, sdir.st_ino, rel)
                    cas.append(Cas("adverse", "adv:vol:%s:%s:%s" % (nom, outil, rel), compact(payload_obj(outil, entree_outil(outil, chemin), L["plain"])),
                                   L["plain"], "vol %s" % nom, outil != "Bash"))
    # JSON non compact (limite (a)) : cible adhérente, cwd non adhérent
    for outil in ("Write", "Edit", "NotebookEdit"):
        cle = "notebook_path" if outil == "NotebookEdit" else "file_path"
        for indent in (1, 2, "\t"):
            obj = payload_obj(outil, entree_outil(outil, L["adh"] + "/.planning/STATE.md"), L["dev"])
            cas.append(Cas("adverse", "adv:pretty:%s:%s" % (outil, repr(indent)), json.dumps(obj, indent=indent).encode(), L["dev"], "JSON non compact", True))
        obj = payload_obj(outil, entree_outil(outil, L["adh"] + "/.planning/STATE.md"), L["dev"])
        t = json.dumps(obj, separators=(",", ":"))
        t = t.replace('"' + cle + '":', '"' + cle + '":\n', 1)
        cas.append(Cas("adverse", "adv:retour-ligne:" + outil, t.encode(), L["dev"], "retour à la ligne entre `:` et la valeur", True))
        t2 = json.dumps(obj, separators=(",", ":")).replace('"' + cle + '":', '"\\u0066' + cle[1:] + '":', 1)
        cas.append(Cas("adverse", "adv:cle-echappee:" + outil, t2.encode(), L["dev"], "clé écrite \\u0066ile_path", True))
        t3 = json.dumps(obj, separators=(",", ":")).replace('"cwd":"' + L["dev"] + '"', '"c\\u0077d":"' + L["dev"] + '"', 1)
        cas.append(Cas("adverse", "adv:cwd-echappe:" + outil, t3.encode(), L["dev"], "clé cwd écrite c\\u0077d", True))
    for outil in ("Bash", "Agent", "Task"):
        obj = payload_obj(outil, entree_outil(outil, None), L["adh"])
        t = json.dumps(obj, separators=(",", ":")).replace('"cwd":', '"c\\u0077d":', 1)
        cas.append(Cas("adverse", "adv:cwd-cle-echappee-adh:" + outil, t.encode(), L["dev"], "clé cwd échappée, lab adhérent par le cwd", True))
        obj = payload_obj(outil, entree_outil(outil, None), L["dev"])
        cas.append(Cas("adverse", "adv:proc-adh:" + outil, compact(obj), L["adh"], "cwd du processus adhérent, cwd du payload dev"))
        obj = payload_obj(outil, entree_outil(outil, None), None)
        cas.append(Cas("adverse", "adv:sans-cwd-proc-adh:" + outil, compact(obj), L["adh"], "sans cwd, processus adhérent"))
        cas.append(Cas("adverse", "adv:sans-cwd-proc-lien:" + outil, compact(obj), L["racine"] + "/lnk-adh", "sans cwd, processus dans un lien vers un lab adhérent"))
        cas.append(Cas("adverse", "adv:entree-vide:" + outil, b"", L["adh"], "entrée vide", True))
        cas.append(Cas("adverse", "adv:tronque:" + outil, compact(obj)[:40], L["adh"], "payload tronqué"))
        cas.append(Cas("adverse", "adv:vide-dev:" + outil, b"", L["dev"], "entrée vide, processus dev"))
    return cas


def corpus_generatif(ctx, L):
    rng = random.Random(GRAINE + 1)
    bases = [L["adh"], L["dev"], "/tmp/zz", ""]
    cas = []
    for i in range(N_GEN):
        outil = rng.choice(("Write", "Edit", "NotebookEdit"))
        cle = "notebook_path" if outil == "NotebookEdit" else "file_path"
        v = valeur_generative(rng, rng.random() < 0.7, bases, noms=(".planning",) if rng.random() < 0.5 else (".planning", ".claude"))
        cwd = rng.choice((L["adh"], L["dev"]))
        cas.append(Cas("generatif", "gen:%d" % i, payload_brut(outil, v, cwd, cle), rng.choice((cwd, L["dev"], L["adh"])), "valeur longue", True))
    return cas


def corpus_arbres(ctx):
    """Un générateur d'arbres de labs : imbrication, liens, casse, Unicode, worktrees, config illisible ou piégée."""
    rng = random.Random(GRAINE + 2)
    cas = []
    configs = [ADH, DEV, None, '{"planning_version":"cycles-v1","x":1}', '{ "planning_version" :\n "cycles-v1" }', "", "[]", "{", '{"planning_version": ["cycles-v1"]}',
               '{"a": "cycles-v1"}', '{"planning_version": "cycles-v10"}', '{"planning_version":"Cycles-V1"}', '{"planning_version":"cycles\\u002dv1"}', "\ufeff" + ADH]
    noms = ["lab", "Lab", "x y", "é", "lab\u212a", "l\u017fb", ".claude", ".CLAUDE", "worktrees", "Worktrees", ".planning", ".PLANNING", ".Planning", "a", "b", "c"]
    for t in range(N_ARBRES):
        R = os.path.realpath(ctx.unique("arbre"))
        os.makedirs(R)
        dossiers = [R]
        for _ in range(rng.randrange(3, 9)):
            parent = rng.choice(dossiers)
            nom = rng.choice(noms)
            d = os.path.join(parent, nom)
            try:
                os.makedirs(d, exist_ok=True)
            except OSError:
                continue
            dossiers.append(d)
        for d in list(dossiers):
            if rng.random() < 0.45:
                cfg = rng.choice(configs)
                pl = os.path.join(d, rng.choice((".planning", ".planning", ".planning", ".PLANNING")))
                try:
                    os.makedirs(pl, exist_ok=True)
                    if cfg is not None:
                        ecrire(os.path.join(pl, "config.json"), cfg)
                        r = rng.random()
                        if r < 0.08:
                            os.chmod(os.path.join(pl, "config.json"), 0)
                except OSError:
                    pass
            if rng.random() < 0.25 and len(dossiers) > 1:
                cible = rng.choice(dossiers)
                forme = rng.randrange(4)
                lien = os.path.join(d, "lnk%d" % rng.randrange(1000))
                try:
                    if forme == 0:
                        os.symlink(cible, lien)
                    elif forme == 1:
                        os.symlink(cible + "/inexistant", lien)
                    elif forme == 2:
                        os.symlink(os.path.relpath(cible, d), lien)
                    else:
                        os.symlink(lien + "x", lien)
                        os.symlink(lien, lien + "x")
                except OSError:
                    pass
                else:
                    dossiers.append(lien)
        existants = [d for d in dossiers if os.path.isdir(d)]
        for _ in range(30):
            d = rng.choice(existants)
            suffixe = rng.choice(("", "/x.md", "/.planning/STATE.md", "/.claude/scripts/planning-hook.sh", "/n/m/o.md", "/../x.md", "/.planning"))
            chemin = d + suffixe
            outil = rng.choice(OUTILS)
            cwd = rng.choice(existants)
            proc = rng.choice(existants)
            sauve_pat = rng.random()
            brut = compact(payload_obj(outil, entree_outil(outil, chemin), cwd if sauve_pat < 0.9 else None))
            cas.append(Cas("arbres", "arbre:%d:%d" % (t, len(cas)), brut, proc, chemin[-50:], "/../" in chemin and outil in ("Write", "Edit", "NotebookEdit")))
    return cas


# --- tableau D : différés par construction + plancher de court-circuits ---------------------------------
def table_differes(ctx, L):
    """(étiquette, octets, cwd processus). Le pré-filtre NE DOIT PAS court-circuiter, même quand le cœur jugerait non adhérent."""
    dev, plain = L["dev"], L["plain"]
    cwd = dev
    w = lambda chemin, c=cwd, outil="Write": compact(payload_obj(outil, entree_outil(outil, chemin), c))
    return [
        ("valeur longue (5 000 caractères) dans un lab dev", w(dev + "/" + ("x" * 100 + "/") * 50 + "f.md"), dev),
        ("valeur longue sans `.planning` ni `.claude`, cwd plain", w(plain + "/" + ("x" * 100 + "/") * 50 + "f.md", plain), plain),
        ("antislash dans le chemin (`\\/`)", w(dev + "/x.md").replace(b'/x.md', b'\\/x.md'), dev),
        ("échappement unicode `\\u0041` dans le chemin", w(dev + "/\\u0041.md"), dev),
        ("tilde `~/x.md`", w("~/x.md"), dev),
        ("`~utilisateur`", w("~bob/x.md"), dev),
        ("chemin relatif", w("x.md"), dev),
        ("double slash", w(dev + "//x.md"), dev),
        ("segment `.`", w(dev + "/./x.md"), dev),
        ("segment `..`", w(dev + "/sub/../x.md"), dev),
        ("slash final", w(dev + "/"), dev),
        ("`/.vol/…`", w("/.vol/1/2/x.md", plain), plain),
        ("`/.VOL/…` (casse)", w("/.VOL/1/2/x.md", plain), plain),
        ("JSON non compact (retour à la ligne)", json.dumps(payload_obj("Write", entree_outil("Write", dev + "/x.md"), dev), indent=2).encode(), dev),
        ("clé `file_path` échappée (`\\u0066ile_path`)", w(dev + "/x.md").replace(b'"file_path"', b'"\\u0066ile_path"'), dev),
        ("clé `cwd` échappée (`c\\u0077d`)", w(dev + "/x.md").replace(b'"cwd"', b'"c\\u0077d"'), dev),
        ("cwd relatif", w(dev + "/x.md", "rel"), dev),
        ("cwd absent de la valeur (chaîne vide)", w(dev + "/x.md", ""), dev),
        ("cwd long", compact(payload_obj("Bash", {"command": "true"}, plain + "/" + "z" * 5000)), plain),
        ("surrogate isolé", w(dev + "/\\ud800").replace(b"\\\\ud800", b"\\ud800"), dev),
        ("NUL échappé", w(dev + "/a\\u0000b").replace(b"\\\\u0000", b"\\u0000"), dev),
        ("config illisible (chmod 000)", w(L["illisible"] + "/x.md", L["illisible"]), L["illisible"]),
        ("config non régulière (dossier config.json)", w(L["cfgdir"] + "/x.md", L["cfgdir"]), L["cfgdir"]),
        ("config non régulière (FIFO)", w(L["fifo"] + "/x.md", L["fifo"]), L["fifo"]),
        ("config lien symbolique vers une config adhérente", w(L["cfglink"] + "/x.md", L["cfglink"]), L["cfglink"]),
        ("config contenant cycles-v1 échappé (`cycles\\u002dv1`)", w(L["esc"] + "/x.md", L["esc"]), L["esc"]),
        ("config à clé échappée", w(L["esckey"] + "/x.md", L["esckey"]), L["esckey"]),
        ("config qui contient un antislash sans cycles-v1", w(L["bs"] + "/x.md", L["bs"]), L["bs"]),
        ("config en MAJUSCULES (CYCLES-V1)", w(L["majus"] + "/x.md", L["majus"]), L["majus"]),
        ("config JSON invalide qui contient cycles-v1", w(L["invalide"] + "/x.md", L["invalide"]), L["invalide"]),
        ("ancêtre adhérent (lab dev sous un lab adhérent)", w(L["adh"] + "/sub/dev2/x.md", L["adh"] + "/sub/dev2"), L["adh"] + "/sub/dev2"),
        ("lien pendant vers un lab adhérent", w(L["racine"] + "/pend-adh/x.md", plain), plain),
        ("lien pendant vers un lab dev", w(L["racine"] + "/pend-dev/x.md", plain), plain),
        ("boucle de liens", w(L["racine"] + "/boucle1/x.md", plain), plain),
        ("lien vers un lab adhérent", w(L["racine"] + "/lnk-adh/x.md", plain), plain),
        ("processus dans un lab adhérent, payload en lab dev (Bash)", compact(payload_obj("Bash", {"command": "true"}, dev)), L["adh"]),
        ("payload sans cwd, processus dans un lab adhérent", compact(payload_obj("Agent", entree_outil("Agent", None), None)), L["adh"]),
        ("clé dupliquée : la première en lab dev, la seconde en lab adhérent",
         w(dev + "/y.md").replace(b'"file_path":"' + dev.encode() + b'/y.md"', b'"file_path":"' + dev.encode() + b'/y.md","file_path":"' + L["adh"].encode() + b'/.planning/STATE.md"', 1), dev),
    ]


def plancher_courts(ctx, L):
    """Cas qui DOIVENT court-circuiter (lab dev, sans lab, six outils) : un pré-filtre qui ne court-circuite jamais ne prouverait rien."""
    cas = []
    for nom, base in (("dev", L["dev"]), ("nodev", L["nodev"]), ("plain", L["plain"]), ("accent", None), ("tmp", "/tmp")):
        if base is None:
            continue
        for outil in OUTILS:
            for rel in ("/x.md", "/.planning/STATE.md", "/sub/neuf.md"):
                cas.append(("%s %s %s" % (nom, outil, rel), compact(payload_obj(outil, entree_outil(outil, base + rel), base)), base))
    return cas


# --- exécution ---------------------------------------------------------------------------------------------
def verdict_pre(ctx, cmd_pre, cas, shell=None):
    return ctx.pre(cmd_pre, cas, shell)


def garde(ctx, cmd, cas_liste, mutant=False, max_ko=8, avec_a=True):
    """Rend (violations, stats). Une violation = (assertion, attendu, obtenu, cas). Propriétés A, B, C, D selon `mutant`."""
    np, pre = ctx.derive(cmd)
    if np is None:
        return [("commande dérivable (bloc du pré-filtre présent une seule fois)", "oui", "non", None)], {}
    viol = []
    stats = {"cas": 0, "courts": 0, "differes": 0, "differes_adh": 0, "coeur_adherent": 0, "coeur_doute": 0, "coeur_invalide": 0, "A_rejeux": 0, "E_rejeux": 0}
    for pos, c in enumerate(cas_liste):
        c.pos = pos
        if c.oracle is None:
            c.oracle = ctx.coeur(c)
    shells = ctx.shells if not mutant else ctx.shells[:1]

    def jouer(c):
        rep = {nom: ctx.pre(pre, c, argv) for nom, argv in (shells if c.pos % 3 == 0 or c.cat == "banc" else shells[:1])}
        a = None
        e = None
        if avec_a and rep[shells[0][0]] == "DEFER" and c.pos % 8 == 0:
            # (E) DEFER ⇒ le chemin d'avant est INCHANGÉ : la commande complète rend exactement la sortie de la commande sans pré-filtre
            # (le pré-filtre ne laisse aucune variable ni aucun effet de bord derrière lui) ; un cas sur huit, script présent, un sur seize, script absent
            e = [(ctx.lancer(np, c.brut, c.cwd_proc, ctx.scripts_dir), ctx.lancer(cmd, c.brut, c.cwd_proc, ctx.scripts_dir), False)]
            if c.pos % 16 == 0:
                e.append((ctx.lancer(np, c.brut, c.cwd_proc, ctx.vide), ctx.lancer(cmd, c.brut, c.cwd_proc, ctx.vide), True))
        if avec_a and rep[shells[0][0]] == "SHORT":
            a = []
            for dossier in (ctx.scripts_dir, ctx.vide):
                a.append((dossier == ctx.vide, ctx.lancer(np, c.brut, c.cwd_proc, dossier), ctx.lancer(cmd, c.brut, c.cwd_proc, dossier)))
        return c, rep, a, e

    lots = [cas_liste[i:i + 128] for i in range(0, len(cas_liste), 128)]
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        for lot in lots:
            for c, rep, a, e in ex.map(jouer, lot):
                stats["cas"] += 1
                v0 = rep[shells[0][0]]
                if len(set(rep.values())) != 1:
                    viol.append(("(C) mêmes verdicts sous %s" % ", ".join(n for n, _ in shells), "un seul verdict", court(str(rep)), c))
                if v0 not in ("SHORT", "DEFER"):
                    viol.append(("le pré-filtre rend SHORT ou DEFER, rien d'autre", "SHORT|DEFER", court(v0), c))
                    continue
                stats["coeur_adherent"] += int(c.oracle == "adherent")
                stats["coeur_doute"] += int(c.oracle == "doute")
                stats["coeur_invalide"] += int(c.oracle == "invalide")
                if v0 == "SHORT":
                    stats["courts"] += 1
                    if c.oracle == "adherent":
                        viol.append(("(B) le pré-filtre ne court-circuite pas un lab que le cœur juge adhérent", "DEFER (cœur : adherent)", "SHORT", c))
                    if c.doit_differer:
                        viol.append(("(D) forme à différer par construction", "DEFER", "SHORT (cœur : %s)" % c.oracle, c))
                    for sans_script, (rn, on, en), (rc, oc, ec) in (a or []):
                        stats["A_rejeux"] += 1
                        if (rn, on, en) != (0, b"", b""):
                            viol.append(("(A) SHORT ⇒ la commande SANS pré-filtre rend 0 octet, code 0 (%s)" % ("script absent" if sans_script else "script présent"),
                                         "rc=0 out=''", "rc=%d out=%s err=%s" % (rn, court(on), court(en)), c))
                        if (rc, oc, ec) != (0, b"", b""):
                            viol.append(("(A) SHORT ⇒ la commande complète rend 0 octet, code 0 (%s)" % ("script absent" if sans_script else "script présent"),
                                         "rc=0 out=''", "rc=%d out=%s err=%s" % (rc, court(oc), court(ec)), c))
                else:
                    stats["differes"] += 1
                    stats["differes_adh"] += int(c.oracle == "adherent")
                    for (rn, on, en), (rc, oc, ec), sans_script in (e or []):
                        stats["E_rejeux"] += 1
                        if (rn, on, en) != (rc, oc, ec):
                            viol.append(("(E) DEFER ⇒ la commande complète rend exactement la sortie de la commande sans pré-filtre (%s)" % ("script absent" if sans_script else "script présent"),
                                         "rc=%d out=%s err=%s" % (rn, court(on), court(en)), "rc=%d out=%s err=%s" % (rc, court(oc), court(ec)), c))
            if mutant and viol:
                break
            if len(viol) > max_ko * 20:
                break
    return viol, stats


def table_d(ctx, cmd, L, mutant=False):
    np, pre = ctx.derive(cmd)
    viol = []
    for etiq, brut, cwd in table_differes(ctx, L):
        c = Cas("table", etiq, brut, cwd, etiq, True)
        v = ctx.pre(pre, c)
        if v != "DEFER":
            viol.append(("(D) différé par construction : " + etiq, "DEFER", v, c))
            if mutant:
                break
    return viol


def table_courts(ctx, cmd, L):
    np, pre = ctx.derive(cmd)
    viol, n = [], 0
    for etiq, brut, cwd in plancher_courts(ctx, L):
        c = Cas("plancher", etiq, brut, cwd, etiq)
        v = ctx.pre(pre, c)
        n += 1
        if v != "SHORT":
            viol.append(("plancher : un lab dev ou sans lab DOIT être court-circuité — " + etiq, "SHORT", v, c))
    return viol, n


# --- bornes du pré-filtre (F-P1, F-P2 du re-audit du 2026-10-02) --------------------------------------------
def comps(chemin):
    return chemin.count("/")


def chemin_long(base, n, comp=120):
    """Chemin propre de EXACTEMENT n caractères sous `base` (composants de `comp` caractères au plus)."""
    s = base
    while len(s) < n:
        r = n - len(s)
        morceau = min(r, 1 + comp)
        if r - morceau == 1:
            morceau -= 1
        s += "/" + "y" * (morceau - 1)
    return s


def chemin_comps(base, total):
    """Chemin propre de `total` composants sous `base` (composants d'un caractère)."""
    return base + "/a" * (total - comps(base))


def cas_bornes(ctx, L):
    """(étiquette, octets, cwd processus, verdict attendu du pré-filtre). Le pré-filtre DIFFÈRE dès qu'une valeur examinée dépasse
    1024 caractères ou 64 composants, qu'une correspondance brute dépasse 2048 caractères ou que le payload en compte plus de 16 ; il
    court-circuite sinon, dans un lab non adhérent. Dans tous les cas la commande complète rend la sortie de la commande sans pré-filtre."""
    dev, adh, plain = L["dev"], L["adh"], L["plain"]
    w = lambda chemin, c: compact(payload_obj("Write", entree_outil("Write", chemin), c))
    b = lambda c: compact(payload_obj("Bash", {"command": "true"}, c))
    cas = []
    # (nom, base du chemin, cwd du payload d'écriture, le lab est-il non adhérent). `.claude` : le repli de l'ancienne commande refuse
    # une valeur trop longue qui nomme `.claude` ou `.planning` (F-P2).
    for nom, base, cwd_b, court_ok in (("dev", dev, dev, True), ("claude", plain + "/.claude/q", plain, True), ("adh", adh, adh, False)):
        for lg in (1023, 1024, 1025, 4083, 4090, 4096, 4097):
            v = chemin_long(base, lg)
            att = "SHORT" if court_ok and lg <= 1024 else "DEFER"
            cas.append(("%s, Write, valeur de %d caractères" % (nom, lg), w(v, cwd_b), cwd_b, att))
            cas.append(("%s, Bash, cwd de %d caractères" % (nom, lg), b(v), cwd_b, att))
        for tot in (63, 64, 65, 66):
            v = chemin_comps(base + "/s", tot)
            att = "SHORT" if court_ok and tot <= 64 else "DEFER"
            cas.append(("%s, Write, valeur de %d composants" % (nom, tot), w(v, cwd_b), cwd_b, att))
            cas.append(("%s, Bash, cwd de %d composants" % (nom, tot), b(v), cwd_b, att))
    cas.append(("préfixe de nom : cwd dans pfx-dev (non adhérent), écriture dans pfx (adhérent)", w(L["pfx"] + "/x.md", L["pfxdev"]), L["pfxdev"], "DEFER"))
    cas.append(("préfixe de nom : cwd dans pfx (adhérent), écriture dans pfx-dev (non adhérent)", w(L["pfxdev"] + "/x.md", L["pfx"]), L["pfxdev"], "DEFER"))
    cas.append(("préfixe de nom : cwd et écriture dans pfx-dev (non adhérent)", w(L["pfxdev"] + "/x.md", L["pfxdev"]), L["pfxdev"], "SHORT"))
    txt = b(dev).decode("utf-8")
    cle = '"cwd":"%s"' % dev
    for n, att in ((1, "SHORT"), (16, "SHORT"), (17, "DEFER"), (40, "DEFER")):
        cas.append(("dev, Bash, %d clés cwd répétées" % n, txt.replace(cle, ",".join([cle] * n), 1).encode("utf-8"), dev, att))
    txt = b(plain + "/.claude/q").decode("utf-8")
    for k, att in ((100, "SHORT"), (4100, "DEFER")):
        cas.append(("claude, Bash, %d espaces entre la clé cwd et sa valeur" % k, txt.replace('"cwd":', '"cwd":' + " " * k, 1).encode("utf-8"), plain, att))
    return cas


def table_bornes(ctx, cmd, L, mutant=False):
    np, pre = ctx.derive(cmd)
    viol = []

    def jouer(e):
        etiq, brut, cwd, att = e
        c = Cas("bornes", etiq, brut, cwd, etiq)
        v = ctx.pre(pre, c)
        r = []
        if v != att:
            r.append(("(F) borne du pré-filtre : verdict (SHORT sous les bornes dans un lab non adhérent, DEFER au-delà ou en lab adhérent)", att, v, c))
        for dossier, nom in ((ctx.scripts_dir, "script présent"), (ctx.vide, "script absent")):
            a, z = ctx.lancer(np, brut, cwd, dossier), ctx.lancer(cmd, brut, cwd, dossier)
            if a != z:
                r.append(("(A)(E) la commande complète rend la sortie de la commande sans pré-filtre, octet pour octet (%s)" % nom,
                          "rc=%d out=%s err=%s" % (a[0], court(a[1]), court(a[2])), "rc=%d out=%s err=%s" % (z[0], court(z[1]), court(z[2])), c))
        return r
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        for r in ex.map(jouer, cas_bornes(ctx, L)):
            viol += r
            if mutant and viol:
                break
    return viol


def table_cout(ctx, cmd, L, mutant=False):
    """Coût borné : pour des valeurs propres de 1 000 à 4 096 caractères (cwd et chemin), lab adhérent et non adhérent, le pré-filtre seul
    comme la commande complète tiennent sous 5 s (attendu : moins d'une demi-seconde, soit une marge de 10 fois) ; et un tueur structurel
    qui ne dépend pas de l'horloge : le nombre d'appels à `vf_pc` est EXACT sur trois branches d'un même arbre (mémoire d'UN préfixe vérifié, ni
    sans mémoire ni chaîne cumulée) et nul sur une valeur de 200 composants (refusée avant tout parcours)."""
    np, pre = ctx.derive(cmd)
    dev, adh = L["dev"], L["adh"]
    viol = []
    cas = []
    for nom, base in (("dev", dev), ("adh", adh)):
        for lg in (1000, 1548, 2748, 4096):
            v = base + "/a" * ((lg - len(base)) // 2)
            for forme, chemin in (("composants d'un caractère", v), ("composants de 120 caractères", chemin_long(base, lg))):
                cas.append(("%s, Bash, cwd de %d caractères (%s)" % (nom, len(chemin), forme), compact(payload_obj("Bash", {"command": "true"}, chemin)), base))
                cas.append(("%s, Write, valeur de %d caractères (%s)" % (nom, len(chemin), forme),
                            compact(payload_obj("Write", entree_outil("Write", chemin + "/f.md"), chemin)), base))

    def chrono(e):
        etiq, brut, base = e
        r = []
        for quoi, c_ in (("pré-filtre seul", pre), ("commande complète", cmd)):
            t0 = time.time()
            rc, out, err = ctx.lancer(c_, brut, base, tmo=5)
            dt = time.time() - t0
            if err == b"TIMEOUT" or dt >= 5:
                r.append(("coût borné (%s) : moins de 5 s, jamais un TIMEOUT que le harnais tuerait en laissant passer" % quoi, "< 5 s (attendu < 0.5 s)",
                          "TIMEOUT à 5 s" if err == b"TIMEOUT" else "%.2f s" % dt, Cas("cout", etiq, brut, base, etiq)))
        return r
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        for r in ex.map(chrono, cas):
            viol += r
            if mutant and viol:
                return viol
    inst = pre.replace("vf_pc() { ", "vf_pc() { printf C >&2; ", 1)
    if inst == pre:
        return viol + [("fonction vf_pc instrumentable", "présente", "absente", None)]
    # Trois branches d'un même arbre, dans l'ordre du harnais (cwd, puis file_path, puis $PWD et le cwd physique) : P/s1/s2/s3 (cwd), P/s1/t1/t2/f.md
    # (écriture), P/s1/s2/s3 (processus). La mémoire d'UN préfixe vérifié (la dernière valeur parcourue) donne EXACTEMENT : cwd, toute la chaîne
    # (P + 4 répertoires) ; écriture, 3 appels jusqu'à P/s1, déjà vérifié ; $PWD, 2 appels jusqu'à P/s1 ; cwd physique, 0. Ni sans mémoire (chaque
    # valeur reparcourt toute sa chaîne), ni avec la chaîne cumulée `_pk` (la valeur parcourue en dernier ne coûterait rien).
    P = L["plain"]
    os.makedirs(P + "/s1/s2/s3", exist_ok=True)
    sous = P + "/s1/s2/s3"
    fich = P + "/s1/t1/t2/f.md"
    attendu = (comps(sous) + 1) + 3 + 2
    rc, out, err = ctx.lancer(inst, compact(payload_obj("Write", entree_outil("Write", fich), sous)), sous)
    obtenu = err.count(b"C")
    if out != b"SHORT" or obtenu != attendu:
        viol.append(("mémoire d'un seul préfixe vérifié : appels à vf_pc EXACTS sur trois branches d'un même arbre (ni sans mémoire, ni chaîne cumulée)",
                     "SHORT, %d appels" % attendu, "%s, %d appels" % (court(out), obtenu), Cas("cout", "appels vf_pc sur trois branches", b"", sous)))
    profond = chemin_comps(dev + "/s", 200)
    rc, out, err = ctx.lancer(inst, compact(payload_obj("Bash", {"command": "true"}, profond)), dev)
    obtenu = err.count(b"C")
    if out != b"DEFER" or obtenu != 0:
        viol.append(("valeur de 200 composants : refusée avant tout parcours (64 composants au plus, comptés sur la valeur, jamais sur la distance au préfixe déjà vérifié)", "DEFER, 0 appel", "%s, %d appels" % (court(out), obtenu),
                     Cas("cout", "appels vf_pc sur une valeur de 200 composants", b"", dev)))
    return viol


# --- coût indépendant du système de fichiers (re-audit du pré-filtre, tour 2, 2026-10-02, F-P3 et F-P4) -------------
SONDE_GREP = "grep() { for _a; do :; done; printf 'G:%s\\n' \"$_a\" >> \"$VF_SONDE\"; command grep \"$@\"; }\n"


def fixtures_creux(ctx):
    """Fixtures de PF-CREUX-01, créées UNE fois dans le dossier temporaire de la suite : configs creuses (2 Gio, 1 Mio), config d'un lien, configs
    de 65 536 et 65 537 octets, arbres de configs non adhérentes. Le dossier est supprimé à la fin de la suite (trap de la suite)."""
    if getattr(ctx, "creux", None):
        return ctx.creux
    R = os.path.realpath(ctx.unique("creux"))
    os.makedirs(R)
    F = {"R": R}

    def creux(chemin, taille, debut=b""):
        os.makedirs(os.path.dirname(chemin), exist_ok=True)
        with open(chemin, "wb") as fh:
            fh.write(debut)
            fh.truncate(taille)
    F["gio2"] = R + "/s1/.planning/config.json"
    creux(F["gio2"], 2 * 1024 ** 3)
    creux(R + "/s2/.planning/config.json", 1024 * 1024, ADH.encode())
    os.makedirs(R + "/s3/.planning")
    os.symlink(F["gio2"], R + "/s3/.planning/config.json")
    creux(R + "/s4/.planning/config.json", 1024 * 1024)
    os.makedirs(R + "/s4/a/b/c")
    os.makedirs(R + "/s1/a")
    for nom, taille in (("s5", 65536), ("s6", 65537)):
        corps = DEV.encode()
        os.makedirs(R + "/" + nom + "/.planning")
        with open(R + "/" + nom + "/.planning/config.json", "wb") as fh:
            fh.write(corps + b" " * (taille - len(corps)))
    # arbres : un `.planning/config.json` non adhérent à CHAQUE niveau ; niveaux au plus 30, et assez peu pour que la valeur reste sous 64 composants
    F["max"] = 62 - comps(R)

    def arbre(nom, niveaux):
        feuille = R + "/arbres/" + nom
        for k in range(niveaux):
            lab(feuille + "/c" * k if k else feuille, DEV)
        return feuille + "/c" * (niveaux - 1) if niveaux > 1 else feuille
    F["arbre"] = arbre
    ctx.creux = F
    return F


def table_creux(ctx, cmd, L, mutant=False):
    """Le coût d'une exécution du pré-filtre ne dépend d'AUCUN contenu du système de fichiers que l'agent contrôle (F-P3) : une config de plus de
    64 Kio (creuse de 2 Gio, ou d'un lien) fait DIFFÉRER avant toute lecture ; le budget est de 64 lectures de config par exécution ; `_pa` et le
    compteur sont initialisés à chaque exécution (F-P4). Tueurs STRUCTURELS : le nombre de lectures (`grep` d'une `config.json`) est compté dans
    une copie instrumentée, jamais déduit de l'horloge ; l'horloge ne sert qu'à borner (5 s, attendu moins d'une demi-seconde)."""
    np, pre = ctx.derive(cmd)
    F = fixtures_creux(ctx)
    R = F["R"]
    inst = SONDE_GREP + pre
    plain = L["plain"]
    w = lambda chemin, cwd: compact(payload_obj("Write", entree_outil("Write", chemin), cwd))
    cas = []
    # (étiquette, payload, cwd du processus, verdict, lectures de config attendues, environnement ajouté, rejouer la commande complète)
    cas.append(("config creuse de 2 Gio, Write sous le lab", w(R + "/s1/a/f.md", R + "/s1/a"), plain, "DEFER", 0, None, True))
    cas.append(("config de 1 Mio qui débute par cycles-v1, Write dans le lab", w(R + "/s2/f.md", R + "/s2"), plain, "DEFER", 0, None, True))
    cas.append(("config = lien vers la config creuse de 2 Gio", w(R + "/s3/f.md", R + "/s3"), plain, "DEFER", 0, None, True))
    cas.append(("config creuse de 1 Mio sur un ANCÊTRE du cwd", w(R + "/s4/a/b/c/f.md", R + "/s4/a/b/c"), plain, "DEFER", 0, None, True))
    cas.append(("config de 65 536 octets (limite incluse)", w(R + "/s5/f.md", R + "/s5"), plain, "SHORT", 1, None, True))
    cas.append(("config de 65 537 octets (limite dépassée)", w(R + "/s6/f.md", R + "/s6"), plain, "DEFER", 0, None, True))
    if F["max"] < 33:
        return [("fixtures de PF-CREUX-01 : au moins 33 niveaux sous 64 composants", ">= 33", "%d (dossier temporaire trop profond)" % F["max"], None)]
    n = 32
    ar = F["arbre"]
    a1, a2 = ar("p1", n), ar("p2", n)
    cas.append(("budget : %d + %d = 64 lectures de config (non adhérentes)" % (n, 64 - n), w(ar("q1", 64 - n) + "/f.md", a1), plain, "SHORT", 64, None, True))
    cas.append(("budget : %d + %d = 65 lectures de config" % (n, 65 - n), w(ar("q2", 65 - n) + "/f.md", a2), plain, "DEFER", 64, None, True))
    vals = [ar("r%d" % i, n) for i in range(16)]
    ti = {"file_path": vals[0] + "/f.md", "content": "x"}
    for i in range(1, 15):
        ti["n%d" % i] = {"cwd": vals[i]}
    cas.append(("budget : 16 valeurs sur 16 arbres de %d niveaux portant chacun une config" % n, compact(payload_obj("Write", ti, vals[15])), plain, "DEFER", 64, None, True))
    cas.append(("F-P4 : `_pa` hérité de l'environnement, égal à un ancêtre adhérent", w(L["adh"] + "/f.md", L["adh"]), plain, "DEFER", None, {"_pa": L["adh"]}, False))
    cas.append(("F-P4 : compteur `_pb` hérité de l'environnement (1000)", w(L["dev"] + "/f.md", L["dev"]), plain, "SHORT", None, {"_pb": "1000"}, False))

    def jouer(e):
        etiq, brut, cwd, att, g_att, env_extra, avec_complete = e
        c = Cas("creux", etiq, brut, cwd, etiq)
        r = []
        sonde = ctx.unique("sonde")
        t0 = time.time()
        rc, out, err = ctx.lancer(inst, brut, cwd, tmo=5, env_extra=dict(env_extra or {}, VF_SONDE=sonde))
        dt = time.time() - t0
        # le tueur STRUCTUREL d'abord : le nombre de lectures de config, lu même si l'horloge a tué le processus
        if g_att is not None:
            lu = len([l for l in (open(sonde, "rb").read().split(b"\n") if os.path.exists(sonde) else []) if l.endswith(b"/config.json")])
            if lu != g_att:
                r.append(("(F-P3) nombre de lectures de config (compté dans une copie instrumentée : budget de 64, aucune lecture d'un fichier de plus de 64 Kio)",
                          "%d lecture(s)" % g_att, "%d lecture(s)" % lu, c))
        if err == b"TIMEOUT" or dt >= 5:
            return r + [("coût borné : pré-filtre sous 5 s (attendu moins d'une demi-seconde), jamais un TIMEOUT que le harnais tuerait en laissant passer",
                         "< 5 s", "TIMEOUT à 5 s" if err == b"TIMEOUT" else "%.2f s" % dt, c)]
        verdict = out.decode("utf-8", "replace") if rc == 0 else "ERR rc=%d" % rc
        if verdict != att:
            r.append(("(F-P3)(F-P4) verdict du pré-filtre (DEFER dès qu'un contenu du système de fichiers le demande, SHORT sinon)", att, verdict, c))
        if avec_complete and not r:
            # le coût du CŒUR (planning-hook.sh lit une config de 2 Gio en 1,5 à 2,5 s) n'est pas celui du pré-filtre : pas d'horloge ici, l'égalité seule
            a = ctx.lancer(np, brut, cwd, tmo=90)
            z = ctx.lancer(cmd, brut, cwd, tmo=90)
            if a != z or a[2] == b"TIMEOUT":
                r.append(("(E) la commande complète rend la sortie de la commande sans pré-filtre, octet pour octet",
                          "rc=%d out=%s err=%s" % (a[0], court(a[1]), court(a[2])), "rc=%d out=%s err=%s" % (z[0], court(z[1]), court(z[2])), c))
        return r
    viol = []
    for e in cas:
        viol += jouer(e)
        if mutant and viol:
            break
    return viol


# --- sections ----------------------------------------------------------------------------------------------
def montrer(libelle, viol, ok_detail):
    if viol:
        for a, b, c, cas in viol[:6]:
            ko(libelle + (" · cas %s (%s)" % (cas.ident, cas.note) if cas else ""), a, b, c)
        if len(viol) > 6:
            print("    … et %d autre(s) violation(s)" % (len(viol) - 6))
    else:
        ok(libelle + " " + ok_detail)


def sec_commande(ctx):
    if ctx.cmd_np is None:
        ko("PF-00", "la commande enregistrée porte le bloc du pré-filtre UNE fois (définitions puis `vf_pre && exit 0`, avant tout lancement du script)", "1 bloc", "absent ou en double")
        return False
    i_appel, i_script = ctx.cmd.index(APPEL), ctx.cmd.index('bash "$S"')
    i_mktemp = ctx.cmd.find("mktemp")
    if not i_appel < i_script or i_mktemp != -1:
        ko("PF-00", "le pré-filtre précède tout lancement de planning-hook.sh ; aucun mktemp ni python3 dans la commande", "appel avant `bash \"$S\"`", "ordre faux")
        return False
    for mot in ("python", "mktemp", "tool_name"):
        bloc = ctx.cmd[ctx.cmd.index(DEBUT):i_appel]
        if mot in bloc:
            ko("PF-00", "le bloc du pré-filtre ne cite ni python, ni mktemp, ni tool_name (aucun lancement lourd, aucune dépendance au nom d'outil)", "absent", mot)
            return False
    ok("PF-00 la commande porte le bloc du pré-filtre une fois, AVANT tout lancement du script ; il ne cite ni python, ni mktemp ; sans le bloc, c'est la couche shell d'avant")
    return True


def sec_table(ctx, L):
    v = table_d(ctx, ctx.cmd, L)
    montrer("PF-D-01", v, "%d différés par construction (valeur longue, antislash, `~`, relatif, `//`, `.`, `..`, `/.vol`, JSON non compact, clés échappées, config illisible, "
            "non régulière ou piégée, lien pendant, boucle, ancêtre adhérent, cwd du processus) : jamais court-circuités" % len(table_differes(ctx, L)))
    v2, n = table_courts(ctx, ctx.cmd, L)
    montrer("PF-D-02", v2, "plancher : %d cas (lab dev, lab sans config, hors lab ; six outils) court-circuités" % n)


def sec_bornes(ctx, L):
    n = len(cas_bornes(ctx, L))
    montrer("PF-BORNE-01", table_bornes(ctx, ctx.cmd, L),
            "%d cas autour des bornes (1023, 1024, 1025 caractères ; 4083 à 4097 ; 63, 64, 65, 66 composants ; 1, 16, 17, 40 clés répétées ; 100 et 4 100 espaces) en lab non adhérent "
            "et adhérent : verdict attendu, et la commande complète rend, script présent comme script absent, la sortie de la commande sans pré-filtre" % n)
    montrer("PF-CREUX-01", table_creux(ctx, ctx.cmd, L),
            "coût indépendant du système de fichiers : config creuse de 2 Gio (et lien vers elle, et config de 1 Mio qui débute par cycles-v1, et sur un ancêtre) : DEFER en moins de 5 s, "
            "aucune lecture ; limite de 65 536 octets ; budget de 64 lectures de config (64 → SHORT, 65 et 16 valeurs sur 16 arbres → DEFER) ; `_pa` et le compteur hérités de l'environnement sans effet ; "
            "commande complète identique à la commande sans pré-filtre")
    montrer("PF-COUT-01", table_cout(ctx, ctx.cmd, L),
            "valeurs propres de 1 000 à 4 096 caractères (cwd et chemin, composants d'un caractère ou de 120), lab adhérent et non adhérent : pré-filtre seul et "
            "commande complète sous 5 s ; appels à vf_pc exacts sur trois branches d'un même arbre (mémoire d'un seul préfixe) et nuls sur 200 composants")


def sec_corpus(ctx, L):
    cats = (("banc", corpus_banc(ctx)), ("adverse", corpus_adverse(ctx, L)), ("generatif", corpus_generatif(ctx, L)), ("arbres", corpus_arbres(ctx)))
    total, ident_cas = [], set()
    for nom, liste in cats:
        t0 = time.time()
        viol, st = garde(ctx, ctx.cmd, liste)
        for c in liste:
            ident_cas.add(c.ident)
        detail = ("%d cas · %d court-circuits (tous silencieux, sans pré-filtre comme avec, script présent et absent : %d rejeux) · %d différés dont %d adhérents selon le cœur, "
                  "sortie identique à celle sans pré-filtre sur %d rejeux · "
                  "cœur : %d adhérents, %d doutes, %d JSON refusés · désaccords 0 · shells %s · %.0f s"
                  % (st["cas"], st["courts"], st["A_rejeux"], st["differes"], st["differes_adh"], st["E_rejeux"], st["coeur_adherent"], st["coeur_doute"], st["coeur_invalide"],
                     "/".join(n for n, _ in ctx.shells), time.time() - t0))
        montrer("PF-EQ-" + nom.upper(), viol, "équivalence (A)(B)(C)(D)(E) : " + detail)
        # garde contre un vert à vide : chaque famille doit exercer les deux issues
        if not viol and nom != "generatif" and (st["courts"] < max(5, st["cas"] // 50) or st["differes_adh"] < 1):
            ko("PF-EQ-" + nom.upper() + " (non vide)", "la famille exerce des SHORT et des DEFER sur lab adhérent", ">= %d SHORT et >= 1 DEFER adhérent" % max(5, st["cas"] // 50),
               "%d SHORT, %d DEFER adhérents" % (st["courts"], st["differes_adh"]))
        total.append((nom, liste, st))
    return total


MUTANTS = [
    ("IV-PK-REMIS", 'case $_pa/ in "$_pd"/*) _pa=$_pt; return 0 ;; esac; vf_pc "$_pd" || return 1; if [ "$_pd" = / ]; then _pa=$_pt; return 0; fi;',
     'case $_pk in *"$_pn$_pd$_pn"*) ;; *) _pk=$_pk$_pd$_pn; vf_pc "$_pd" || return 1 ;; esac; [ "$_pd" = / ] && return 0;',
     "iv : remet la chaîne de dédoublonnage `_pk` (le coût d'avant), les bornes restant en place : seul le compte exact des appels à vf_pc la distingue"),
    ("IV-MEMO-SANS-FRONTIERE", 'case $_pa/ in "$_pd"/*)', 'case $_pa/ in "$_pd"*)', "iv : la mémoire du préfixe vérifié tient `pfx` pour un ancêtre de `pfx-dev/…` (frontière de composant retirée)"),
    ("IV-SANS-BORNE-COMPOSANTS", '_pj=$((_pj+1)); [ "$_pj" -le 64 ] || return 1; ', "", "iv : retire la borne de 64 composants"),
    ("IV-SANS-BORNE-BRUTE", '[ "${#_pv}" -le 2048 ] || return 1; ', "", "iv : retire la borne de 2048 caractères sur la correspondance brute"),
    ("IV-SANS-PLAFOND-VALEURS", '_pz=$((_pz+1)); [ "$_pz" -le 16 ] || return 1; ', "", "iv : retire le plafond de 16 valeurs examinées"),
    ("V-SANS-BORNE-TAILLE", '[ -z "$(find -L "$_pq" -size +128 2>/dev/null)" ] || return 1; ', "", "v : retire la borne de 64 Kio sur la config (lecture d'un fichier creux de 2 Gio)"),
    ("V-SANS-BUDGET", '_pb=$((_pb+1)); [ "$_pb" -le 64 ] || return 1; ', "", "v : retire le budget de 64 lectures de config par exécution"),
    ("V-PA-NON-INITIALISE", '_pa=; _pb=0; ', '_pb=0; ', "v : `_pa` n'est plus initialisé (F-P4 : un `_pa` hérité de l'environnement tient un ancêtre adhérent pour vérifié)"),
    ("V-PB-NON-INITIALISE", '_pa=; _pb=0; ', '_pa=; ', "v : le compteur n'est plus initialisé (un `_pb` hérité de l'environnement consomme le budget)"),
    ("V-FIND-SANS-L", 'find -L "$_pq"', 'find "$_pq"', "v : la mesure de taille ne suit plus le lien (une config lien vers un fichier creux est lue)"),
    ("V-BORNE-TAILLE-DEPLACEE", '-size +128 ', '-size +256 ', "v : borne de taille déplacée (128 kio : une config de 65 537 octets est lue)"),
    ("I-SANS-CYCLES-V1", "[ $? -eq 1 ]; }", ":; }", "i : sort trop tôt, sans vérifier cycles-v1 dans la config"),
    ("I-SANS-CWD-PAYLOAD", "(file_path|notebook_path|cwd)", "(file_path|notebook_path)", "i : sort trop tôt, sans regarder le cwd du payload"),
    ("I-SANS-CWD-PROCESSUS", 'case $PWD in /*) vf_px "$PWD" || return 1 ;; esac; vf_pp . || return 1; vf_pw "$_pr"; }', "return 0; }", "i : sort trop tôt, sans regarder le cwd du processus"),
    ("I-SANS-ANCETRES", 'if [ "$_pd" = / ]; then _pa=$_pt; return 0; fi; _pd=${_pd%/*}; [ -n "$_pd" ] || _pd=/; done; }', "return 0; done; }", "i : sort trop tôt, sans remonter les ancêtres"),
    ("II-SANS-PHYSIQUE", '[ "$_ps" = 0 ] && return 0;', "return 0;", "ii : sans résolution physique (pwd -P) de la partie existante"),
    ("II-SANS-LIEN-PENDANT", '[ -d "$_pd" ] || return 1; fi;', ":; fi;", "ii : un lien pendant ou en boucle n'est pas un doute"),
    ("III-SANS-BORNE", '[ "${#1}" -le 1024 ] || return 1; _pd=$1;', "_pd=$1;", "iii : accepte une valeur longue (borne de 1024 caractères retirée)"),
    ("III-SANS-ANTISLASH", "*'\\'*|*//*", "*//*", "iii : accepte une valeur échappée (antislash)"),
    ("III-SANS-CLE-ECHAPPEE", "|*'\\u00'[2-7]*) return 1 ;; esac; _pm=", ") return 1 ;; esac; _pm=", "iii : accepte une clé écrite sous forme échappée"),
    ("III-SANS-NON-COMPACT", "case $I in *\"$_pn\"*|", "case $I in ", "iii : accepte un JSON non compact"),
    ("III-SANS-VOL", "|/[.][Vv][Oo][Ll]|/[.][Vv][Oo][Ll]/*) return 1", ") return 1", "iii : accepte /.vol"),
    ("III-SANS-DOTDOT", "*/./*|*/../*|*/.|*/..|", "", "iii : accepte `.` et `..` dans le chemin"),
]


def sec_mutants(ctx, L, familles):
    cas_tous = [c for _, liste, _ in familles for c in liste]
    filtre = os.environ.get("VF_PF_MUT", "")
    for nom, motif, remplacement, role in MUTANTS:
        if filtre and not any(nom.startswith(p) for p in filtre.split(",")):
            continue
        n = ctx.cmd.count(motif)
        if n != 1:
            print("  ✗ MUT-%s NON TUÉ" % nom)
            print("    assertion : condition (a) : motif unique dans la commande")
            print("    attendu (original) : mutant valide")
            print("    obtenu (mutant)     : occurrences=%d" % n)
            continue
        muté = ctx.cmd.replace(motif, remplacement)
        p = subprocess.run(["/bin/sh", "-n", "-c", muté.replace(TOKEN, "/nonexistent")], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if p.returncode != 0:
            print("  ✗ MUT-%s NON TUÉ" % nom)
            print("    assertion : condition (a) : sh -n réussit")
            print("    attendu (original) : mutant valide")
            print("    obtenu (mutant)     : " + court(p.stderr))
            continue
        # ordre : tableau D d'abord (rapide), puis le plancher, puis le corpus (sh seul, arrêt à la première violation)
        viol_t = table_d(ctx, muté, L, mutant=True)
        viol_b = table_bornes(ctx, muté, L, mutant=True) + table_cout(ctx, muté, L, mutant=True) + table_creux(ctx, muté, L, mutant=True)
        viol_c, _ = garde(ctx, muté, cas_tous, mutant=True, avec_a=False)
        viol = viol_t + viol_b + viol_c
        if not viol:
            print("  ✗ MUT-%s NON TUÉ" % nom)
            print("    assertion : la garde d'équivalence rougit sous le mutant (%s)" % role)
            print("    attendu (original) : vert (A)(B)(C)(D) sur le corpus")
            print("    obtenu (mutant)     : vert (mutant non opposable)")
            continue
        traces = []
        for src, lst in (("tableau D", viol_t), ("bornes et coût", viol_b), ("corpus", viol_c)):
            if lst:
                a, b, c, cas = lst[0]
                traces.append("%s : cas %s (%s) · assertion : %s · attendu (original) : %s · obtenu (mutant) : %s"
                              % (src, cas.ident if cas else "-", cas.note if cas else "-", a, b, court(c, 120)))
        print("  ✓ MUT-%s TUÉ — %s · %s" % (nom, role, " ‖ ".join(traces)))


def main():
    scripts_dir, hooks_json, banc, work = sys.argv[2:6]
    ctx = Ctx(scripts_dir, hooks_json, banc, work)
    if not sec_commande(ctx):
        sys.exit(1)
    L = foret(ctx)
    for nom in sys.argv[1].split(","):
        if nom == "table":
            sec_table(ctx, L)
        elif nom == "bornes":
            sec_bornes(ctx, L)
        elif nom == "mutants":
            familles = [(n, liste, None) for n, liste in (("banc", corpus_banc(ctx)), ("adverse", corpus_adverse(ctx, L)), ("generatif", corpus_generatif(ctx, L)), ("arbres", corpus_arbres(ctx)))]
            sec_mutants(ctx, L, familles)
        elif nom == "corpus":
            familles = sec_corpus(ctx, L)
            if "mutants" in sys.argv[1].split(","):
                sec_mutants(ctx, L, familles)
            break


main()
PY_AIDES_PREFILTRE_EOF

run_sections() { # <sections séparées par des virgules>
  local out rc line
  out="$WORK/sortie.txt"
  "$PYBIN" "$AIDES" "$1" "$SCRIPTS_DIR" "$HOOKS_JSON" "$BANC" "$WORK" > "$out" 2>&1
  rc=$?
  while IFS= read -r line; do
    printf '%s\n' "$line"
    case "$line" in
      "  ✓ "*) pass=$((pass+1)) ;;
      "  ✗ "*) fail=$((fail+1)) ;;
    esac
  done < "$out"
  if [ "$rc" -ne 0 ] && ! grep -q '^  ✗ ' "$out"; then
    echo "  ✗ section $1"; echo "    assertion : les aides Python se terminent sans erreur"; echo "    attendu   : code 0"; echo "    obtenu    : code $rc"
    fail=$((fail+1))
  fi
}

run_sections "${VF_PF_SECTIONS:-table,bornes,corpus,mutants}"

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
