#!/usr/bin/env bash
# recalc-planning.sh — dérive du disque l'état d'un planning métier et génère INDEX.md, STATE.md
# et cloture.log (spec docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md, §3,
# §3.1, §7.1, §7.4, §10). L'état n'est jamais déclaré, toujours recalculé depuis les fichiers du
# modèle (cycles/, CYCLE.md, CADRAGE.md, PLAN.md, le marqueur de clôture de plan, VERDICT.md,
# SUMMARY.md).
#
# Usage:
#   recalc-planning.sh [--planning=<dossier>] [--read-only] [-h|--help]
# Défaut : --planning=.planning (relatif au cwd). Racine du lab = parent absolu du dossier de
# planning (les chemins `ecrit:` s'y résolvent).
#
# Codes de sortie :
#   0  succès
#   1  erreur d'exécution (interpréteur Python introuvable, dossier de planning absent ou
#      non-dossier, dossier de planning en lien symbolique en mode écriture, cloture.log en lien
#      symbolique ou illisible en mode écriture, échec d'entrée-sortie)
#   2  refus d'adhésion (P44-D-02)
#   3  refus GSD — détecté ou détection non concluante (P44-D-02a)
#  64  argument inconnu
# Messages sur stderr, préfixe [recalc-planning].
#
# Livraison — voie (a) de P44-D-14 : le moteur Python est embarqué en heredoc quoté dans ce
# script, patron de plugin/conductor/scripts/dag.sh, plutôt que livré comme fichier .py séparé.
# Motif en une phrase : l'installeur du plugin ne pose que *.sh en exécutable et *.txt/*.json en
# données — un .py de ce dossier ne serait jamais posé chez un utilisateur.
#
# Ce que cette commande NE FAIT PAS : aucun hook ni garde d'écriture n'est câblé par elle
# (P44-D-15, où le recalcul tourne se décide ailleurs) ; elle ne refuse RIEN sur le CONTENU d'un
# planning — ses deux seuls refus sont écrire sans adhésion déclarée (P44-D-02) et écrire sur un
# planning tenu par le moteur GSD, détecté ou non concluant (P44-D-02a). Toute combinaison de
# signaux non prévue sur le contenu rend `indéterminé`, jamais un refus.
set -uo pipefail

PLANNING_DIR=".planning"
READ_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --planning=*) PLANNING_DIR="${arg#*=}" ;;
    --read-only)  READ_ONLY=1 ;;
    -h|--help)    grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[recalc-planning] argument inconnu : $arg" >&2; exit 64 ;;
  esac
done

# Sibling detect-gsd-engine.sh (P44-D-02a) : résolu par le RÉPERTOIRE DU SCRIPT, jamais par le
# cwd (patron dag.sh, ferme le même vecteur qu'un candidat relatif au répertoire de travail).
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DETECT_GSD_SH="$SCRIPT_DIR/detect-gsd-engine.sh"

# Résolution de l'interpréteur (ADR-054, patron check-skills.sh) : stub Microsoft Store détecté
# par chemin, repli python, sinon échec bruyant — une commande qui ne tourne pas ne rend jamais
# un vert.
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then
      PYBIN=python
    else
      echo "[recalc-planning] interpréteur Python introuvable — impossible d'exécuter le moteur" >&2
      exit 1
    fi
    ;;
esac

"$PYBIN" - "$PLANNING_DIR" "$READ_ONLY" "$DETECT_GSD_SH" <<'PY_RECALC_PLANNING_EOF'
import errno
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
from datetime import datetime

# --- Constantes du contrat -----------------------------------------------------------------
SCHEMA_ADHESION = "cycles-v1"
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
NOM_UNITE = re.compile(r"^[0-9]{2,}-[\w.-]+$")
ANNEXES = frozenset({"_bancs", "recherches", "intel", "sketches", "_archive", "registres"})
FICHIERS_PHASE = ("CADRAGE.md", "PLAN.md", "CLOTURE.md", "VERDICT.md", "SUMMARY.md")
ENSEMBLE_CLOSE = frozenset(FICHIERS_PHASE)
ENSEMBLE_A_EXECUTER = frozenset({"CADRAGE.md", "PLAN.md"})
TERMINAUX = frozenset({"close", "abandonné", "remplacé"})
ETATS_TOUS = (
    "à cadrer", "en cadrage", "à planifier", "à exécuter", "à juger", "à corriger",
    "close", "indéterminé", "abandonné", "remplacé", "gelé",
)
LIBELLES = {
    "CYCLE.md-absent": "CYCLE.md absent ou non régulier",
    "combinaison-non-prevue": "combinaison de signaux non prévue",
    "phase-indeterminee": "phase `{}` indéterminée",
}


# --- Grammaire minimale du frontmatter (P44-D-12, aucun devin, Pitfall 3) -------------------
def dequote(valeur):
    """Dé-quote une valeur entre guillemets simples ou doubles, sans traitement d'échappement."""
    v = valeur.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in ("'", '"'):
        return v[1:-1]
    return v


CLE_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(.*)$")


def lire_frontmatter(texte):
    """Parse un frontmatter minimal (première ligne `---`, fermeture `---`) : toute forme non
    reconnue (clé dupliquée, bloc littéral, ligne orpheline, frontmatter jamais refermé) rend un
    statut d'échec distinct de « absent » — jamais une valeur devinée (Pitfall 3)."""
    lignes = texte.split("\n")
    if not lignes or lignes[0].rstrip("\r") != "---":
        return ("absent", {})
    fin = None
    for i in range(1, len(lignes)):
        if lignes[i].rstrip("\r") == "---":
            fin = i
            break
    if fin is None:
        return ("invalide:frontmatter-non-ferme", {})
    corps = lignes[1:fin]
    donnees = {}
    cles_vues = set()
    i = 0
    n = len(corps)
    while i < n:
        brute = corps[i].rstrip("\r")
        allegee = brute.strip()
        if allegee == "" or allegee.startswith("#"):
            i += 1
            continue
        if brute != brute.lstrip():
            return ("invalide:ligne-orpheline", {})
        m = CLE_RE.match(brute)
        if not m:
            return ("invalide:ligne-non-reconnue", {})
        cle, reste = m.group(1), m.group(2).strip()
        if cle in cles_vues:
            return ("invalide:cle-dupliquee", {})
        if reste == "":
            valeur, j = _lire_liste_indentee(corps, i + 1)
            if valeur is None:
                return ("invalide:liste-mal-formee", {})
            donnees[cle] = valeur
            i = j
        elif reste == "[]":
            donnees[cle] = []
            i += 1
        elif reste.startswith("[") and reste.endswith("]"):
            interieur = reste[1:-1].strip()
            donnees[cle] = [] if interieur == "" else [dequote(p.strip()) for p in interieur.split(",")]
            i += 1
        else:
            donnees[cle] = dequote(reste)
            i += 1
        cles_vues.add(cle)
    return ("ok", donnees)


def _lire_liste_indentee(corps, depart):
    """Lit une liste de scalaires (`- valeur`) ou une liste de mappings plats (`- k: v` puis
    `k2: v2` plus indentées) sous une clé vide. Renvoie (None, depart) si la forme est mixte ou
    porte un bloc littéral (invalide, jamais devinée)."""
    items = []
    mode = None
    carte_courante = None
    j = depart
    n = len(corps)
    while j < n:
        suivante = corps[j].rstrip("\r")
        if suivante.strip() == "":
            j += 1
            continue
        if suivante == suivante.lstrip():
            break
        interieur = suivante.strip()
        if interieur.startswith("|") or interieur.startswith(">"):
            return (None, j)
        if interieur.startswith("- "):
            corps_item = interieur[2:]
            mkv = CLE_RE.match(corps_item)
            if mkv:
                if mode == "scalaires":
                    return (None, j)
                mode = "mappings"
                carte_courante = {mkv.group(1): dequote(mkv.group(2))}
                items.append(carte_courante)
            else:
                if mode == "mappings":
                    return (None, j)
                mode = "scalaires"
                items.append(dequote(corps_item))
                carte_courante = None
        else:
            mkv2 = CLE_RE.match(interieur)
            if mode == "mappings" and mkv2 and carte_courante is not None:
                cle2 = mkv2.group(1)
                if cle2 in carte_courante:
                    return (None, j)
                carte_courante[cle2] = dequote(mkv2.group(2))
            else:
                return (None, j)
        j += 1
    return (items, j)


def _lire_frontmatter_fichier(chemin):
    """Lit chemin en frontmatter strict : fichier régulier requis (lstat, non suivi), ouverture
    O_NOFOLLOW, décodage UTF-8 strict."""
    try:
        est_regulier = stat.S_ISREG(os.lstat(chemin).st_mode)
    except OSError:
        est_regulier = False
    if not est_regulier:
        return ("absent", {})
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
            texte = fh.read()
    except (OSError, UnicodeDecodeError):
        return ("invalide:illisible", {})
    return lire_frontmatter(texte)


def _est_regulier(chemin):
    try:
        return stat.S_ISREG(os.lstat(chemin).st_mode)
    except OSError:
        return False


# --- Adhésion (P44-D-02) --------------------------------------------------------------------
def verifier_adhesion(planning):
    """Sans .planning/config.json déclarant EXACTEMENT "planning_version": "cycles-v1", le
    planning n'a pas adhéré : fichier absent ou non régulier, JSON invalide, racine non objet,
    clé absente, autre valeur, valeur non chaîne sont TOUS non adhérents."""
    chemin = os.path.join(planning, "config.json")
    resultat = {"attendue": SCHEMA_ADHESION, "declaree": None, "adherente": False, "config": "absent"}
    try:
        est_regulier = stat.S_ISREG(os.lstat(chemin).st_mode)
    except OSError:
        est_regulier = False
    if not est_regulier:
        return resultat
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
            texte = fh.read()
    except (OSError, UnicodeDecodeError):
        resultat["config"] = "illisible"
        return resultat
    try:
        donnees = json.loads(texte)
    except ValueError:
        resultat["config"] = "illisible"
        return resultat
    if not isinstance(donnees, dict):
        resultat["config"] = "illisible"
        return resultat
    resultat["config"] = "valide"
    if "planning_version" in donnees:
        resultat["declaree"] = donnees["planning_version"]
    resultat["adherente"] = isinstance(resultat["declaree"], str) and resultat["declaree"] == SCHEMA_ADHESION
    return resultat


# --- Détection GSD (P44-D-02a, P44-D-01b, P44-D-01c) ----------------------------------------
def _porte_marqueur_gsd(chemin_state):
    statut, donnees = _lire_frontmatter_fichier(chemin_state)
    return statut == "ok" and "gsd_state_version" in donnees


def _porte_marqueur_partition(chemin_state):
    statut, donnees = _lire_frontmatter_fichier(chemin_state)
    return statut == "ok" and "workstream" in donnees and "created" in donnees


def _lister_compartiments(planning_abs):
    """Énumère les sous-dossiers réels (jamais un lien, ni sur le dossier lui-même ni sur une
    entrée) du sous-dossier `workstreams` du planning."""
    dossier_compartiments = os.path.join(planning_abs, "workstreams")
    try:
        if not stat.S_ISDIR(os.lstat(dossier_compartiments).st_mode):
            return []
    except OSError:
        return []
    try:
        entrees = sorted(os.scandir(dossier_compartiments), key=lambda e: e.name)
    except OSError:
        return []
    resultat = []
    for entree in entrees:
        try:
            reel = entree.is_dir(follow_symlinks=False)
        except OSError:
            reel = False
        if reel:
            resultat.append(entree.path)
    return resultat


def detection_gsd(detect_sh, planning_abs, racine_lab):
    """« gsd », « non-gsd » ou « non-concluante ». Polarité inverse d'un DAG classique :
    l'incertitude ferme l'écriture. Quand le détecteur rend 1 (chaîne GSD absente de la machine,
    jamais inspecté le planning), le moteur vérifie lui-même sans dépendre du détecteur."""
    try:
        detecteur_regulier = stat.S_ISREG(os.lstat(detect_sh).st_mode)
    except OSError:
        detecteur_regulier = False
    if not detecteur_regulier:
        print("[recalc-planning] détecteur non régulier : " + detect_sh, file=sys.stderr)
        return "non-concluante"  # motif-detecteur-irregulier
    try:
        code = subprocess.run(
            ["bash", detect_sh, "--quiet", "--path", planning_abs],
            cwd=racine_lab, timeout=30,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        ).returncode
    except Exception:
        return "non-concluante"  # motif-sous-processus-en-echec
    if code == 0:
        return "gsd"  # motif-code-0
    if code in (2, 3):
        return "non-gsd"  # motif-code-2-ou-3
    if code == 1:
        if _porte_marqueur_gsd(os.path.join(planning_abs, "STATE.md")):
            return "gsd"  # motif-marqueur-racine
        compartiments = _lister_compartiments(planning_abs)
        if any(_porte_marqueur_gsd(os.path.join(c, "STATE.md")) for c in compartiments):
            return "gsd"  # motif-marqueur-compartiment
        if any(_porte_marqueur_partition(os.path.join(c, "STATE.md")) for c in compartiments):
            return "gsd"  # motif-partition-compartiment
        return "non-gsd"  # motif-code-1-sans-marqueur
    return "non-concluante"  # motif-repli-generique


# --- Scanner du modèle (44-04 classe hors_modele ; l'interface est posée ici) ----------------
def _lister_noms_unite(dossier):
    try:
        if not stat.S_ISDIR(os.lstat(dossier).st_mode):
            return []
    except OSError:
        return []
    try:
        entrees = sorted(os.scandir(dossier), key=lambda e: e.name)
    except OSError:
        return []
    resultat = []
    for entree in entrees:
        try:
            reel = entree.is_dir(follow_symlinks=False)
        except OSError:
            reel = False
        if reel and NOM_UNITE.match(entree.name):
            resultat.append(entree.name)
    return sorted(resultat)


def _lister_entrees(dossier):
    try:
        entrees = os.scandir(dossier)
    except OSError:
        return set()
    return {e.name for e in entrees}


def scanner(planning):
    cycles = []
    dossier_cycles = os.path.join(planning, "cycles")
    for nom_cycle in _lister_noms_unite(dossier_cycles):
        chemin_cycle_abs = os.path.join(dossier_cycles, nom_cycle)
        chemin_cycle_rel = "cycles/" + nom_cycle
        phases = []
        dossier_phases = os.path.join(chemin_cycle_abs, "phases")
        for nom_phase in _lister_noms_unite(dossier_phases):
            chemin_phase_abs = os.path.join(dossier_phases, nom_phase)
            chemin_phase_rel = chemin_cycle_rel + "/phases/" + nom_phase
            entrees = _lister_entrees(chemin_phase_abs)
            fichiers = {
                nom: (nom in entrees and _est_regulier(os.path.join(chemin_phase_abs, nom)))
                for nom in FICHIERS_PHASE
            }
            phases.append({
                "nom": nom_phase, "chemin_abs": chemin_phase_abs, "chemin_rel": chemin_phase_rel,
                "entrees": entrees, "fichiers": fichiers,
            })
        cycles.append({
            "nom": nom_cycle, "chemin_abs": chemin_cycle_abs, "chemin_rel": chemin_cycle_rel,
            "cycle_md": _est_regulier(os.path.join(chemin_cycle_abs, "CYCLE.md")),
            "phases": phases,
        })
    return {"cycles": cycles, "hors_modele": []}


# --- Dérivation d'une feuille (phase) — traceur : deux combinaisons reconnues ----------------
def _registre_clos(statut, donnees):
    if statut != "ok":
        return False
    inconnues = donnees.get("inconnues")
    if not isinstance(inconnues, list):
        return False
    for item in inconnues:
        if not isinstance(item, dict):
            return False
        if item.get("structurante") == "oui" and not (item.get("statut") or "").strip():
            return False
    return True


def _valeurs_ecrit(donnees):
    ecrit = donnees.get("ecrit")
    if isinstance(ecrit, str):
        return [ecrit]
    if isinstance(ecrit, list):
        return ecrit
    return None


def _chemin_ecrit_valide(chemin):
    if not isinstance(chemin, str) or chemin == "":
        return False
    if chemin.startswith("/") or chemin.startswith("~"):
        return False
    if ".." in chemin.split("/"):
        return False
    if any(ord(c) < 0x20 or ord(c) == 0x7F for c in chemin):
        return False
    if "\\" in chemin:
        return False
    if any(c in chemin for c in "*?[]{}<>"):
        return False
    return True


def _ecrit_valide(statut, donnees):
    if statut != "ok":
        return False
    valeurs = _valeurs_ecrit(donnees)
    if not valeurs:
        return False
    return all(_chemin_ecrit_valide(v) for v in valeurs)


def _livrables_presents(racine_lab, donnees_plan):
    valeurs = _valeurs_ecrit(donnees_plan) or []
    return all(os.path.lexists(os.path.join(racine_lab, v)) for v in valeurs)


def _meta_phase(chemin_phase_abs, fichiers):
    auteur = None
    if fichiers.get("SUMMARY.md"):
        statut, donnees = _lire_frontmatter_fichier(os.path.join(chemin_phase_abs, "SUMMARY.md"))
        if statut == "ok":
            auteur = donnees.get("auteur")
    tentative = None
    hash_juge = None
    if fichiers.get("VERDICT.md"):
        statut, donnees = _lire_frontmatter_fichier(os.path.join(chemin_phase_abs, "VERDICT.md"))
        if statut == "ok":
            tentative = donnees.get("tentative")
            hash_juge = donnees.get("hash")
    return {"auteur": auteur or "inconnu", "tentative": tentative, "hash_juge": hash_juge}


def deriver_feuille(phase, racine_lab):
    """(état, raison, méta) — le traceur reconnaît exactement deux combinaisons (P44-D-08) :
    `close` et `à exécuter`. Toute autre combinaison rend `indéterminé`, jamais une supposition."""
    entrees = phase["entrees"]
    fichiers = phase["fichiers"]
    chemin_abs = phase["chemin_abs"]
    meta = _meta_phase(chemin_abs, fichiers)
    cadrage_statut, cadrage_donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "CADRAGE.md"))
    plan_statut, plan_donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "PLAN.md"))
    registre_clos = _registre_clos(cadrage_statut, cadrage_donnees)
    ecrit_valide = _ecrit_valide(plan_statut, plan_donnees)
    if entrees == ENSEMBLE_CLOSE and all(fichiers[n] for n in ENSEMBLE_CLOSE) and registre_clos and ecrit_valide:
        verdict_statut, verdict_donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "VERDICT.md"))
        if verdict_statut == "ok":
            constats = verdict_donnees.get("constats")
            tous_passes = (
                isinstance(constats, list) and len(constats) > 0
                and all(isinstance(c, dict) and c.get("resultat") == "passé" for c in constats)
            )
            if tous_passes and _livrables_presents(racine_lab, plan_donnees):
                return ("close", None, meta)
        return ("indéterminé", "combinaison-non-prevue", meta)
    if entrees == ENSEMBLE_A_EXECUTER and all(fichiers[n] for n in ENSEMBLE_A_EXECUTER) and registre_clos and ecrit_valide:
        return ("à exécuter", None, meta)
    return ("indéterminé", "combinaison-non-prevue", meta)


# --- Agrégation d'un cycle --------------------------------------------------------------------
def agreger(etats):
    """Première phase (déjà triée par nom) dont l'état n'est ni close ni abandonné ni remplacé ;
    si toutes sont terminales, close prime dès qu'au moins une l'est, sinon abandonné."""
    non_terminaux = [e for e in etats if e["etat"] not in TERMINAUX]
    if non_terminaux:
        return non_terminaux[0]
    if any(e["etat"] == "close" for e in etats):
        return next(e for e in etats if e["etat"] == "close")
    return etats[-1]


def deriver_cycle(cycle, racine_lab):
    chemin = cycle["chemin_rel"]
    if not cycle["cycle_md"]:
        return {"nom": cycle["nom"], "chemin": chemin, "etat": "indéterminé", "raison": "CYCLE.md-absent",
                "phase_courante": None, "phases": []}
    phases_derivees = []
    for phase in cycle["phases"]:
        etat, raison, meta = deriver_feuille(phase, racine_lab)
        phases_derivees.append({
            "nom": phase["nom"], "chemin": phase["chemin_rel"], "etat": etat, "raison": raison,
            "auteur": meta["auteur"], "tentative": meta["tentative"], "hash_juge": meta["hash_juge"],
            "plans": [],
        })
    if not phases_derivees:
        return {"nom": cycle["nom"], "chemin": chemin, "etat": "à cadrer", "raison": None,
                "phase_courante": None, "phases": phases_derivees}
    indeterminees = [p for p in phases_derivees if p["etat"] == "indéterminé"]
    if indeterminees:
        premiere = indeterminees[0]
        raison_cycle = "phase-indeterminee:" + premiere["nom"]
        return {"nom": cycle["nom"], "chemin": chemin, "etat": "indéterminé", "raison": raison_cycle,
                "phase_courante": premiere["nom"], "phases": phases_derivees}
    courante = agreger(phases_derivees)
    if courante["etat"] not in TERMINAUX:
        return {"nom": cycle["nom"], "chemin": chemin, "etat": courante["etat"], "raison": None,
                "phase_courante": courante["nom"], "phases": phases_derivees}
    if any(p["etat"] == "close" for p in phases_derivees):
        return {"nom": cycle["nom"], "chemin": chemin, "etat": "close", "raison": None,
                "phase_courante": None, "phases": phases_derivees}
    return {"nom": cycle["nom"], "chemin": chemin, "etat": "abandonné", "raison": None,
            "phase_courante": None, "phases": phases_derivees}


# --- Libellés lisibles des raisons d'indétermination (décision (a), 2026-09-28) --------------
def libelle_raison(code):
    if code is None:
        return ""
    if ":" in code:
        base, x = code.split(":", 1)
        gabarit = LIBELLES.get(base)
        if gabarit is None:
            return (base + " " + x).replace("-", " ").replace(":", " ")
        if "{}" in gabarit:
            return gabarit.format(x)
        return gabarit + " " + x
    gabarit = LIBELLES.get(code)
    if gabarit is not None:
        return gabarit
    return code.replace("-", " ").replace(":", " ")


def libelle_cycle_indetermine(code, phases):
    """Étend le libellé à la cause PROPRE de la phase quand code vaut phase-indeterminee:<phase>
    — repli défensif sur la forme sans le deux-points si la phase n'est pas retrouvée, n'est pas
    elle-même indéterminée, ou n'a pas de raison (correction de classe, revue tour 4)."""
    base = libelle_raison(code)
    if code is not None and code.startswith("phase-indeterminee:"):
        nom_phase = code.split(":", 1)[1]
        phase = next((p for p in phases if p["nom"] == nom_phase), None)
        if phase is not None and phase["etat"] == "indéterminé" and phase.get("raison"):
            return base + " : " + libelle_raison(phase["raison"])
    return base


# --- Journal (cloture.log, P44-D-11, ajout seul) ----------------------------------------------
LIGNE_JOURNAL_RE = re.compile(
    r"^(?P<horodatage>\S+)  (?P<chemin>\S+)  (?P<auteur>\S+)  "
    r"verdict=(?P<verdict>\S+)  tentative=(?P<tentative>\S+)  date=observation$"
)


def _parser_ligne_journal(ligne):
    m = LIGNE_JOURNAL_RE.match(ligne)
    return m.groupdict() if m else None


def lire_journal(planning):
    """(lignes, statut). Le statut « lien » vient de l'échec de l'ouverture sans suivi de lien
    (ELOOP), pas d'un contrôle lstat préalable — une seule garde."""
    chemin = os.path.join(planning, "cloture.log")
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
    except FileNotFoundError:
        return ([], "absent")
    except OSError as e:
        if e.errno == errno.ELOOP:
            return ([], "lien")
        return ([], "illisible")
    try:
        with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
            texte = fh.read()
    except (OSError, UnicodeDecodeError):
        return ([], "illisible")
    return ([l for l in texte.split("\n") if l != ""], "lu")


def _unites_closes(derivation):
    resultat = []
    for cycle in derivation["cycles"]:
        for phase in cycle["phases"]:
            if phase["etat"] == "close":
                resultat.append(phase)
            for plan in phase.get("plans", []):
                if plan["etat"] == "close":
                    resultat.append(plan)
    return resultat


def lignes_a_journaliser(derivation, lignes_existantes):
    """Dédoublonnage lu dans le journal lui-même (dernier couple verdict/tentative par chemin),
    jamais dans un cache."""
    dernier_couple = {}
    for ligne in lignes_existantes:
        parsee = _parser_ligne_journal(ligne)
        if parsee is not None:
            dernier_couple[parsee["chemin"]] = (parsee["verdict"], parsee["tentative"])
    a_ajouter = []
    for unite in _unites_closes(derivation):
        chemin = unite["chemin"]
        verdict = "passé"
        brute = unite.get("tentative")
        tentative = str(brute) if brute not in (None, "") else "-"
        if dernier_couple.get(chemin) != (verdict, tentative):
            a_ajouter.append({
                "chemin": chemin, "auteur": unite.get("auteur") or "inconnu",
                "verdict": verdict, "tentative": tentative,
            })
    a_ajouter.sort(key=lambda u: u["chemin"])
    return a_ajouter


def _formater_ligne_journal(horodatage, unite):
    chemin = unite["chemin"]
    auteur = re.sub(r"\s+", "_", (unite["auteur"] or "inconnu").strip()) or "inconnu"
    return "{}  {}  {}  verdict={}  tentative={}  date=observation".format(
        horodatage, chemin, auteur, unite["verdict"], unite["tentative"],
    )


def ajouter_au_journal(chemin, lignes):
    """Ouverture en ajout seul, jamais en troncature. Permissions FORCÉES à 0o644 par fchmod
    explicite sur le descripteur, après ouverture — jamais le seul mode passé à os.open, filtré
    par le umask du processus appelant."""
    if not lignes:
        return
    fd_journal = os.open(chemin, os.O_WRONLY | os.O_APPEND | os.O_CREAT | SANS_SUIVI_DE_LIEN, 0o644)
    os.fchmod(fd_journal, 0o644)
    texte = "".join(ligne + "\n" for ligne in lignes)
    with os.fdopen(fd_journal, "a", encoding="utf-8") as fh:
        fh.write(texte)


# --- Rendu déterministe de INDEX.md et STATE.md -----------------------------------------------
def _texte_etat_cycle(cycle):
    if cycle["etat"] == "indéterminé":
        return "indéterminé — " + libelle_cycle_indetermine(cycle["raison"], cycle["phases"]) + " (" + cycle["chemin"] + ")"
    return cycle["etat"]


def _dernier_signe_de_vie(chemin_cycle, lignes_journal):
    dernier = None
    prefixe = chemin_cycle + "/"
    for ligne in lignes_journal:
        parsee = _parser_ligne_journal(ligne)
        if parsee is None:
            continue
        chemin = parsee["chemin"]
        if chemin == chemin_cycle or chemin.startswith(prefixe):
            dernier = parsee["horodatage"]
    return dernier if dernier is not None else "aucun"


def rendre_index(derivation, lignes_journal):
    cycles = derivation["cycles"]
    ouverts = [c for c in cycles if c["etat"] not in ("close", "abandonné")]
    sortis = sorted(c["chemin"] for c in cycles if c["etat"] in ("close", "abandonné"))
    lignes = ["# Index du planning", "", "Généré par recalc-planning.sh, ne se rédige pas (P44-D-10).", ""]
    if ouverts:
        lignes.append("| Cycle | État | Phase courante | Dernier signe de vie | Bail en cours |")
        lignes.append("|---|---|---|---|---|")
        for cycle in ouverts:
            phase_courante = cycle["phase_courante"] or "aucune"
            dernier = _dernier_signe_de_vie(cycle["chemin"], lignes_journal)
            lignes.append(
                "| " + cycle["chemin"] + " | " + _texte_etat_cycle(cycle) + " | " + phase_courante
                + " | " + dernier + " | aucun |"
            )
    else:
        lignes.append("_Aucun cycle ouvert._")
    lignes.append("")
    lignes.append("Sortis de l'index (clos ou abandonnés) : " + (", ".join(sortis) if sortis else "aucun") + ".")
    lignes.append("")
    lignes.append("## Hors modèle")
    lignes.append("")
    hors_modele = derivation.get("hors_modele") or []
    if hors_modele:
        for entree in sorted(hors_modele):
            lignes.append("- " + entree)
    else:
        lignes.append("_Aucune entrée._")
    lignes.append("")
    return "\n".join(lignes)


def rendre_state(derivation):
    cycles = derivation["cycles"]
    ouverts = [c for c in cycles if c["etat"] not in ("close", "abandonné")]
    if ouverts:
        courant = ouverts[0]
        cycle_courant = courant["nom"]
        phase_courante = courant["phase_courante"] or "aucune"
        etat_txt = _texte_etat_cycle(courant)
    else:
        cycle_courant = "aucun"
        phase_courante = "aucune"
        etat_txt = "aucun"
    lignes = [
        "---",
        "genere_par: recalc-planning",
        "cycle_courant: " + cycle_courant,
        "phase_courante: " + phase_courante,
        "etat: " + etat_txt,
        "---",
        "",
        "# Position courante",
        "",
        "- Cycle courant : " + cycle_courant,
        "- Phase courante : " + phase_courante,
        "",
    ]
    return "\n".join(lignes)


# --- Écriture atomique et application (SEUL appelant : appliquer_ecritures) -------------------
def ecrire_si_different(chemin, contenu):
    """Compare aux octets existants, ne réécrit que s'ils diffèrent — fichier temporaire dans le
    même dossier + os.replace (jamais un save() non atomique)."""
    octets = contenu.encode("utf-8")
    try:
        with open(chemin, "rb") as fh:
            existant = fh.read()
    except OSError:
        existant = None
    if existant == octets:
        return False
    dossier = os.path.dirname(chemin) or "."
    fd_tmp, chemin_tmp = tempfile.mkstemp(dir=dossier, prefix=".tmp-recalc-")
    try:
        os.fchmod(fd_tmp, 0o644)
        with os.fdopen(fd_tmp, "wb") as fh:
            fh.write(octets)
        os.replace(chemin_tmp, chemin)
    except Exception:
        try:
            os.remove(chemin_tmp)
        except OSError:
            pass
        raise
    return True


def appliquer_ecritures(planning, racine_lab, derivation):
    try:
        planning_est_lien = stat.S_ISLNK(os.lstat(planning).st_mode)
    except OSError:
        planning_est_lien = False
    if planning_est_lien:
        print("[recalc-planning] dossier de planning en lien symbolique : " + planning, file=sys.stderr)
        return (1, None)
    lignes_existantes, statut_journal = lire_journal(planning)
    if statut_journal in ("lien", "illisible"):
        print("[recalc-planning] journal des clôtures inaccessible en écriture (statut=" + statut_journal + ")", file=sys.stderr)
        return (1, None)
    for nom_cible in ("INDEX.md", "STATE.md", "cloture.log"):
        chemin_cible = os.path.join(planning, nom_cible)
        if os.path.lexists(chemin_cible) and not os.path.isfile(chemin_cible):
            print("[recalc-planning] emplacement occupé par autre chose qu'un fichier régulier : " + chemin_cible, file=sys.stderr)
            return (1, None)
    a_ajouter = lignes_a_journaliser(derivation, lignes_existantes)
    horodatage = datetime.now().astimezone().isoformat(timespec="seconds")
    nouvelles_lignes = [_formater_ligne_journal(horodatage, u) for u in a_ajouter]
    ajouter_au_journal(os.path.join(planning, "cloture.log"), nouvelles_lignes)
    lignes_completes, _ = lire_journal(planning)
    ecrits = []
    if ecrire_si_different(os.path.join(planning, "INDEX.md"), rendre_index(derivation, lignes_completes)):
        ecrits.append("INDEX.md")
    if ecrire_si_different(os.path.join(planning, "STATE.md"), rendre_state(derivation)):
        ecrits.append("STATE.md")
    unites = sum(len(c["phases"]) for c in derivation["cycles"])
    rapport = {
        "moteur": "recalc-planning",
        "mode": "ecriture",
        "ecrits": sorted(ecrits),
        "cloture_ajouts": len(nouvelles_lignes),
        "unites": unites,
    }
    return (0, rapport)


# --- Comptage pour le rapport lecture seule -----------------------------------------------------
def _compter_par_etat_unites(derivation):
    compte = {e: 0 for e in ETATS_TOUS}
    for cycle in derivation["cycles"]:
        for phase in cycle["phases"]:
            if phase["etat"] in compte:
                compte[phase["etat"]] += 1
            for plan in phase.get("plans", []):
                if plan["etat"] in compte:
                    compte[plan["etat"]] += 1
    return compte


def _compter_cycles_par_etat(derivation):
    compte = {e: 0 for e in ETATS_TOUS}
    for cycle in derivation["cycles"]:
        if cycle["etat"] in compte:
            compte[cycle["etat"]] += 1
    return compte


# --- Point d'entrée ----------------------------------------------------------------------------
def main():
    planning_arg, mode_lecture_seule_brut, detect_sh = sys.argv[1], sys.argv[2], sys.argv[3]
    mode_lecture_seule = mode_lecture_seule_brut == "1"
    if not os.path.isdir(planning_arg):
        print("[recalc-planning] dossier de planning absent ou non-dossier : " + planning_arg, file=sys.stderr)
        sys.exit(1)
    planning_abs = os.path.abspath(planning_arg)
    racine_lab = os.path.dirname(planning_abs)
    modele = scanner(planning_abs)
    cycles_derives = sorted(
        (deriver_cycle(c, racine_lab) for c in modele["cycles"]),
        key=lambda c: c["chemin"],
    )
    derivation = {"cycles": cycles_derives, "hors_modele": modele["hors_modele"]}

    if mode_lecture_seule:
        adhesion = verifier_adhesion(planning_abs)
        lignes_existantes, statut_journal = lire_journal(planning_abs)
        cloture_a_ajouter = [
            {"chemin": u["chemin"], "auteur": u["auteur"], "verdict": u["verdict"], "tentative": u["tentative"]}
            for u in lignes_a_journaliser(derivation, lignes_existantes)
        ]
        rapport = {
            "moteur": "recalc-planning",
            "mode": "lecture-seule",
            "adhesion": adhesion,
            "cycles": derivation["cycles"],
            "hors_modele": derivation["hors_modele"],
            "compte_par_etat": _compter_par_etat_unites(derivation),
            "compte_cycles_par_etat": _compter_cycles_par_etat(derivation),
            "cloture_a_ajouter": cloture_a_ajouter,
            "journal": statut_journal,
        }
        print(json.dumps(rapport, sort_keys=True, indent=2, ensure_ascii=False))
        sys.exit(0)

    adhesion = verifier_adhesion(planning_abs)
    if not adhesion["adherente"]:
        print(
            "[recalc-planning] refus d'écriture (P44-D-02) : le fichier config.json du dossier de "
            "planning doit déclarer \"planning_version\": \"cycles-v1\" — utilisez --read-only pour "
            "dériver sans adhésion",
            file=sys.stderr,
        )
        sys.exit(2)

    verdict_gsd = detection_gsd(detect_sh, planning_abs, racine_lab)
    if verdict_gsd != "non-gsd":
        print(
            "[recalc-planning] refus d'écriture (P44-D-02a) : ce planning est tenu par le moteur "
            "GSD, ou sa détection n'est pas concluante — le recalcul n'écrit jamais dans ce cas",
            file=sys.stderr,
        )
        sys.exit(3)

    code, rapport = appliquer_ecritures(planning_abs, racine_lab, derivation)
    if code != 0:
        sys.exit(code)
    print(json.dumps(rapport, sort_keys=True, indent=2, ensure_ascii=False))
    sys.exit(0)


main()
PY_RECALC_PLANNING_EOF
