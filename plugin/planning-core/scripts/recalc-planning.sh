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
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
import unicodedata
from datetime import datetime

# --- Constantes du contrat -----------------------------------------------------------------
SCHEMA_ADHESION = "cycles-v1"
CACHE_SCHEMA_VERSION = 1
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)
# Candidats bash FIXES pour lancer le détecteur (F1/F44-07, correction de classe) : jamais
# `shutil.which("bash")` sur le PATH hérité — un PATH détourné (un faux `bash` en tête) rendrait
# le sous-processus lui-même contrôlé par l'attaquant, avant même que l'environnement maîtrisé
# n'entre en jeu. Deux chemins absolus, dans cet ordre ; voir `_resoudre_bash` pour la garde.
CANDIDATS_BASH = ("/bin/bash", "/usr/bin/bash")
# Environnement MAÎTRISÉ du sous-processus détecteur (F1/F44-07) : liste blanche construite DE
# ZÉRO, jamais `dict(os.environ)`. PATH fixe de dossiers système, aucune autre variable héritée
# (ni `BASH_ENV`, ni `ENV`, ni une fonction exportée `BASH_FUNC_*%%`, ni `SHELLOPTS`/`BASHOPTS`/
# `CDPATH`/`TMPDIR`/`HOME`/`GSD_WORKSTREAM`). `LC_ALL`/`LANG` volontairement ABSENTS : vérifié
# vert (R-LABS-ADVERSES, STATE.md aux octets UTF-8 invalides) sous cet environnement strictement
# réduit à PATH+GSD_HOME — awk ne lit que le frontmatter, borné par la clé recherchée, jamais le
# corps du fichier, la locale n'y change donc rien de mesurable ; les ajouter sans besoin mesuré
# serait une variable de plus à justifier.
PATH_MAITRISE = "/usr/bin:/bin:/usr/sbin:/sbin"
NOM_UNITE = re.compile(r"^[0-9]{2,}-[\w.-]+$")
ANNEXES = frozenset({"_bancs", "recherches", "intel", "sketches", "_archive", "registres"})
NOMS_MODELE_PHASE = ("CADRAGE.md", "PLAN.md", "CLOTURE.md", "VERDICT.md", "SUMMARY.md", "DEROGATION.md")
NOMS_MODELE_PLAN = ("PLAN.md", "CLOTURE.md", "VERDICT.md", "SUMMARY.md", "DEROGATION.md")
TERMINAUX = frozenset({"close", "abandonné", "remplacé"})
JOURNALISABLES = frozenset({"close", "abandonné", "remplacé", "gelé"})
ETATS_TOUS = (
    "à cadrer", "en cadrage", "à planifier", "à exécuter", "à juger", "à corriger", "à clore",
    "close", "indéterminé", "abandonné", "remplacé", "gelé",
)
# Table LIBELLES (code -> gabarit de phrase), reproduite depuis references/modele-cycles.md
# § Lisibilité des causes indéterminées — forme identique au contrat, jamais un `<libellé>`
# générique. Un code suffixé `:<x>` se sépare sur le premier `:` ; tout code absent de cette
# table retombe sur lui-même avec `-` et `:` remplacés par des espaces (jamais un KeyError).
LIBELLES = {
    # combinaison-non-prevue : clause de garde-fou pour une ÉVOLUTION FUTURE des règles R1-R8/
    # Φ0-Φ5 (modele-cycles.md § Défaut défensif) — _r1_a_r8() ci-dessous exhaustive déjà TOUTE
    # combinaison possible de plan/cloture/verdict/summary/constats, aucun code actuel ne produit
    # ce libellé (F6, 2026-09-28) ; il reste dans la table pour le jour où une règle nouvelle
    # laisserait un trou.
    "combinaison-non-prevue": "combinaison de signaux non prévue",
    "verdict-perime": "verdict périmé : re-juger (tentative n+1)",
    "livrable-modifie-apres-cloture": "livrable ou plan modifié après la clôture",
    "empreinte-hors-borne": "empreinte des livrables hors borne",
    "SUMMARY.md-sans-PLAN.md": "SUMMARY.md sans PLAN.md",
    "CLOTURE.md-sans-PLAN.md": "CLOTURE.md sans PLAN.md",
    "VERDICT.md-sans-CLOTURE.md": "VERDICT.md sans CLOTURE.md (marqueur)",
    "SUMMARY.md-avec-verdict-en-echec": "SUMMARY.md avec un verdict en échec",
    "derogation-sans-auteur": "dérogation sans auteur nommé",
    "derogation-invalide": "dérogation invalide",
    "CYCLE.md-absent": "CYCLE.md absent",
    "phase-indeterminee": "phase `{}` indéterminée",
    "plan-indetermine": "plan `{}` indéterminé",
    "livrable-absent": "livrable absent : {}",
    "livrable-vide": "livrable vide : {}",
    "livrable-hors-borne": "livrable hors borne : {}",
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
    if not est_fichier_regulier(chemin):
        return ("absent", {})
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
            texte = fh.read()
    except (OSError, UnicodeDecodeError):
        return ("invalide:illisible", {})
    return lire_frontmatter(texte)


def est_fichier_regulier(chemin):
    """Garde UNIQUE de régularité (44-04, P44-D-04/T-44-17) : lstat + S_ISREG, jamais de suivi de
    lien. Appelée avant toute ouverture d'un fichier du modèle — la lecture qui suit garde
    `SANS_SUIVI_DE_LIEN` (O_NOFOLLOW) en second rideau, jamais le seul rempart."""
    try:
        return stat.S_ISREG(os.lstat(chemin).st_mode)
    except OSError:
        return False


def _est_regulier(chemin):
    return est_fichier_regulier(chemin)


# --- Adhésion (P44-D-02) --------------------------------------------------------------------
def verifier_adhesion(planning):
    """Sans .planning/config.json déclarant EXACTEMENT "planning_version": "cycles-v1", le
    planning n'a pas adhéré : fichier absent ou non régulier, JSON invalide, racine non objet,
    clé absente, autre valeur, valeur non chaîne sont TOUS non adhérents."""
    chemin = os.path.join(planning, "config.json")
    resultat = {"attendue": SCHEMA_ADHESION, "declaree": None, "adherente": False, "config": "absent"}
    if not est_fichier_regulier(chemin):
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


# --- Résolution de bash pour le sous-processus détecteur (F1/F44-07, correction de classe) ----
def _bash_candidat_valide(chemin):
    """Un candidat de CANDIDATS_BASH est valide s'il est, au sens `lstat` (jamais un suivi de
    lien implicite) : un fichier régulier DIRECT, ou un lien symbolique dont la cible RÉSOLUE
    (`os.path.realpath`) est un fichier régulier appartenant à root (uid 0). Règle la plus
    stricte qui reste vraie sur macOS et Linux courants (où `/bin` peut lui-même être un lien vers
    `/usr/bin` sur un système à `/usr` fusionné — la résolution du RÉPERTOIRE parent par le noyau
    laisse alors `lstat` du composant final `bash` voir directement le fichier régulier, sans
    jamais passer par la branche lien symbolique ci-dessous) : le cas direct (candidat lui-même un
    fichier régulier) n'exige donc PAS de vérification de propriétaire séparée — s'il était
    substituable par un non-root, le système serait déjà compromis à un niveau que cette garde ne
    peut pas traiter. La branche lien symbolique existe pour l'indirection explicite seulement."""
    try:
        info = os.lstat(chemin)
    except OSError:
        return False
    if stat.S_ISREG(info.st_mode):
        return True
    if stat.S_ISLNK(info.st_mode):
        cible = os.path.realpath(chemin)
        try:
            info_cible = os.stat(cible)
        except OSError:
            return False
        return stat.S_ISREG(info_cible.st_mode) and info_cible.st_uid == 0
    return False


def _resoudre_bash():
    """Premier candidat VALIDE de CANDIDATS_BASH (chemins absolus fixes) ; None si aucun ne l'est
    — fail-closed nommé. Jamais `shutil.which("bash")` : sur un PATH détourné (un faux `bash` en
    tête), c'est le SOUS-PROCESSUS lui-même qui serait alors sous contrôle de l'attaquant, avant
    même que l'environnement maîtrisé de `detection_gsd` n'entre en jeu (F1/F44-07, mesuré : un
    faux `awk` en tête de PATH suffisait à faire disparaître le marqueur `gsd_state_version` d'un
    lab GSD, le PATH hérité entier étant jusqu'ici copié dans l'environnement du sous-processus)."""
    for candidat in CANDIDATS_BASH:
        if _bash_candidat_valide(candidat):
            return candidat
    return None


# --- Garde de lecture du détecteur (P44-D-02a, lot 7, correction de CLASSE) --------------------
# PRINCIPE (décision du head sous délégation technique de Willy, session principale, 2026-09-28,
# lot 7) : le moteur n'écrit QUE s'il a pu LIRE, pour de vrai, tout ce que le détecteur devait
# lire. Pas une liste de cas particuliers — un principe unique, appliqué par EXÉCUTION RÉELLE de
# la même primitive que le détecteur consomme, jamais par une liste de noms de fichiers à vérifier
# à la main (une telle liste diverge du détecteur à la première évolution des deux, côte à côte).
#
# CONSTAT qui motive ce lot (audit du 2026-09-28, mesuré par exécution directe de
# `vf_ws_enumerate`, HEAD 32b5d59) — la garde du lot 6 (fidélité STRUCTURELLE, noms/chemins à
# risque) ne couvrait PAS ceci : `vf_ws_enumerate` (workstream-policy.sh, boucle d'énumération)
# pose `found=1` inconditionnellement après chaque `printf`, MÊME quand `cd "$entry" && pwd` a
# ÉCHOUÉ (compartiment sans bit `x`, mode 000/600/400) — `cd` échoue, `$(...)` capture une chaîne
# VIDE, `printf` imprime une ligne VIDE, et `found=1` est posé quand même. `detect-gsd-engine.sh`
# lit cette ligne vide via `while IFS= read -r _wsdir; do [ -n "$_wsdir" ] || continue; ...`
# (workstream-policy.sh:305-306) — la ligne vide est silencieusement sautée, AUCUNE autre ligne ne
# suit, la priorité 2bis retombe sur la priorité 3/4 et rend le code 3 « terrain libre » SANS
# AUCUN diagnostic. Exactement le code que `detection_gsd` traduit en autorisation d'écrire :
# mesuré, le moteur ÉCRIT (exit 0) sur un compartiment réellement tenu par GSD, et quand le marqueur
# porté est au `STATE.md` RACINE lui-même rendu illisible (mode 000), le moteur va jusqu'à
# ÉCRASER ce `STATE.md` — le marqueur `gsd_state_version` disparaît. Le signalement de correction à
# la SOURCE (`vf_ws_enumerate`, hors périmètre P44-D-01b de ce lot) est reporté au BACKLOG.
#
# CORRECTION DE PORTÉE, INCHANGÉE depuis le lot 6 (P44-D-01b : `vf_ws_enumerate` et
# `detect-gsd-engine.sh` restent INCHANGÉS, APPELABLES jamais RÉIMPLÉMENTÉS) : la garde vit
# ENTIÈREMENT ici, côté appelant. Elle ne lit AUCUN `STATE.md` pour son CONTENU (ni `gsd_state_
# version`, ni `planning_version`) — elle juge deux choses, toutes deux structurelles :
#   1. FIDÉLITÉ PAR EXÉCUTION — `vf_ws_enumerate` est RELANCÉE ici, pour de vrai, dans le MÊME
#      bash et le MÊME environnement maîtrisé que ceux qui serviront à l'appel réel du détecteur
#      (jamais une réimplémentation Python de cette boucle bash — c'est exactement cette
#      réimplémentation qui a divergé au lot 3, cf. commentaire de `detection_gsd`). Son résultat
#      (un nom de compartiment par ligne retenue) est comparé à l'ensemble des compartiments RÉELS
#      du disque, dérivé INDÉPENDAMMENT en Python (`os.scandir`, jamais un glob shell). Toute
#      différence — ligne vide, ligne dupliquée, compartiment manquant — est un refus nommé : elle
#      couvre le trou ci-dessus SANS connaître son mécanisme exact (une future variante du même
#      trou, ailleurs dans `vf_ws_enumerate`, romprait la même égalité et serait donc AUSSI
#      couverte).
#   2. LISIBILITÉ RÉELLE — chaque compartiment retenu par cette exécution, le `STATE.md` racine
#      s'il existe, et le `STATE.md` de chaque compartiment s'il existe, doivent être OUVRABLES
#      pour de vrai (`os.scandir`/`os.open`, JAMAIS `os.access`, qui peut mentir sous ACL POSIX ou
#      montage réseau, et qui ne teste de toute façon qu'une PERMISSION déclarée, pas une lecture
#      RÉELLE). Un compartiment ou un `STATE.md` non ouvrable est un refus nommé — c'est la classe
#      qui couvre `compartiment-dir-000/600/400` et `STATE.md` racine ou de compartiment en 000,
#      chacune mesurée réécrire silencieusement (ou, pour le `STATE.md` racine, l'ÉCRASER) avant
#      ce lot.
# Toute `OSError` rencontrée PENDANT cette garde est un refus NOMMÉ, jamais un `continue`
# silencieux qui traiterait l'élément comme absent ou conforme (F2, revue du lot 6 : `is_symlink`/
# `is_dir` sous exception faisaient `continue`/`est_dossier=False`, un fail-OPEN).
# Classes structurelles du lot 6 (nom à saut de ligne, nom caché, chemin de planning à risque)
# CONSERVÉES comme diagnostic nommé — un futur lecteur doit pouvoir citer le motif précis. Elles
# sont FUSIONNÉES dans la MÊME liste de décision que l'ÉGALITÉ D'ENSEMBLES (point 1) et la
# LISIBILITÉ RÉELLE (point 2, lot 7/8) — correction de prose (revue, lot 8) : n'importe laquelle
# des trois, seule, suffit à refuser (la décision finale, `len(vues) == 0`, porte sur l'ensemble
# dédoublonné de TOUTES les classes accumulées, sans distinction de source). Une entrée en lien
# symbolique reste NON masquante (exclusion DÉCLARÉE du détecteur, F1, ne pas sur-refuser un cas
# déjà connu et accepté).
def _ouvrable(chemin, est_dossier):
    """Le chemin est-il RÉELLEMENT ouvrable pour l'utilisateur courant ? Une ouverture RÉELLE —
    `os.scandir` pour un dossier (échoue immédiatement, à l'appel, si le bit `x` manque),
    `os.open` en lecture pour un fichier — JAMAIS `os.access` (déclaratif, pas une lecture, et
    peut mentir sous ACL POSIX ou montage réseau). Toute `OSError` -> False ; jamais une exception
    qui remonte (F2).
    Branche fichier — durcissement lot 8 (audit local, 2026-09-28) : `O_NONBLOCK` avant tout, puis
    `fstat` du descripteur pour exiger un type RÉGULIER. Sans `O_NONBLOCK`, ouvrir une FIFO à cet
    emplacement bloque le processus INDÉFINIMENT tant qu'aucun autre processus n'en tient
    l'extrémité écriture — mesuré, ce `STATE.md` en FIFO pendait la garde de lecture sans jamais
    rendre la main. `O_NONBLOCK` rend l'ouverture d'une FIFO immédiate dans tous les cas (POSIX) ;
    sans effet sur un fichier régulier, dont la lecture nominale — ailleurs, via
    `_lire_frontmatter_fichier`, sur un descripteur distinct — n'est donc jamais affectée. Le
    `fstat` referme le cas où l'ouverture réussit malgré tout sur un type non régulier : refus
    NOMMÉ (False) plutôt qu'un faux `True`."""
    try:
        if est_dossier:
            it = os.scandir(chemin)
            try:
                pass
            finally:
                it.close()
        else:
            fd = os.open(chemin, os.O_RDONLY | os.O_NONBLOCK)
            try:
                if not stat.S_ISREG(os.fstat(fd).st_mode):
                    return False  # _ouvrable : type non régulier (FIFO, périphérique...) -> refus nommé
            finally:
                os.close(fd)
        return True
    except OSError:
        return False  # _ouvrable : toute OSError -> refus nommé, jamais un fail-open (F2)


def _executer_vf_ws_enumerate(bash_bin, workstream_policy_sh, planning_abs, env_maitrise, racine_lab):
    """Exécute RÉELLEMENT `vf_ws_enumerate` (workstream-policy.sh, INCHANGÉE — P44-D-01b), dans
    le MÊME bash et le MÊME environnement maîtrisé que ceux qui serviront à l'appel réel du
    détecteur. JAMAIS une réimplémentation Python de cette fonction bash. Retourne
    (ok: bool, lignes: list[str]) — `ok=False` sur tout échec de lancement ou code de sortie hors
    de {0, 2, 3} (les codes propres de `vf_ws_enumerate`, voir l'en-tête de workstream-policy.sh) :
    fail-closed, jamais une lecture partielle traitée comme fiable."""
    script_source = '. "$1"\nvf_ws_enumerate "$2"\n'
    try:
        resultat = subprocess.run(
            [bash_bin, "--noprofile", "--norc", "-c", script_source, "_",
             workstream_policy_sh, planning_abs],
            cwd=racine_lab, timeout=30, env=env_maitrise,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
    except Exception:
        return (False, [])
    if resultat.returncode not in (0, 2, 3):
        return (False, [])
    texte = resultat.stdout.decode("utf-8", "surrogateescape")
    lignes = texte.split("\n")
    if lignes and lignes[-1] == "":
        lignes = lignes[:-1]
    return (True, lignes)


def _lecture_detecteur_fidele(planning_abs, bash_bin, workstream_policy_sh, env_maitrise, racine_lab):
    """(fidele: bool, classes: list[str]) — `classes` NOMME chaque motif de refus rencontré
    (jamais un booléen nu). Voir le commentaire de tête ci-dessus pour le principe. Liste vide et
    `fidele=True` si `<planning_abs>/workstreams/` est absent (SILENCE, code 3 de
    `vf_ws_enumerate` — dépôt NON partitionné, état NOMINAL), en lien symbolique, ou non-répertoire
    (ces deux derniers cas sont DÉJÀ fermés par le détecteur lui-même, code 2 — cette garde ne
    double jamais un refus déjà couvert ailleurs)."""
    classes = []

    # --- Lisibilité RÉELLE du STATE.md racine, s'il existe (priorités 2 ET 3 du détecteur en
    # dépendent TOUTES DEUX — un STATE.md racine illisible masque l'une comme l'autre) -----------
    # Lot 8 (correction de CLASSE, audit du 2026-09-28) : `os.path.isfile` — jamais
    # `os.path.lexists` — pour mirer EXACTEMENT la sémantique de `[ -f ]` que lit le détecteur
    # (`detect-gsd-engine.sh:96,184`) : suit le lien, exige un fichier RÉGULIER à la cible. Un lien
    # symbolique CASSÉ (cible absente) est donc traité comme ABSENT, exactement comme le détecteur
    # (`[ -f ]` faux, aucune lecture tentée) — jamais un refus « illisible » (sur-refus mesuré,
    # audit du 2026-09-28 : `_ouvrable` tentait d'ouvrir une cible qui n'existe pas, ENOENT confondu
    # avec une vraie erreur de lecture). Un lien vers un régulier lisible reste jugé par
    # `_ouvrable`, exactement comme avant (`os.path.isfile` suit le lien avant l'appel, `_ouvrable`
    # aussi). Le `STATE.md` racine occupé par un lien CASSÉ reste refusé PAR AILLEURS — garde B de
    # `appliquer_ecritures` (« emplacement occupé »), qui `lstat`e sans jamais suivre le lien —
    # cette garde-ci ne double pas ce refus, elle cesse seulement de sur-refuser AVANT lui.
    etat_racine = os.path.join(planning_abs, "STATE.md")
    if os.path.isfile(etat_racine) and not _ouvrable(etat_racine, est_dossier=False):
        classes.append("state-racine-illisible")

    # --- workstreams/ absent, lien, ou non-dossier : rien de plus à vérifier ICI (déjà fermé
    # ailleurs, ou SILENCE nominal) -----------------------------------------------------------
    ws_root = os.path.join(planning_abs, "workstreams")
    try:
        info_root = os.lstat(ws_root)
    except OSError:
        vues = []
        for c in classes:
            if c not in vues:
                vues.append(c)
        return (len(vues) == 0, vues)
    if stat.S_ISLNK(info_root.st_mode) or not stat.S_ISDIR(info_root.st_mode):
        vues = []
        for c in classes:
            if c not in vues:
                vues.append(c)
        return (len(vues) == 0, vues)

    # --- Ensemble RÉEL des compartiments (Python, os.scandir — JAMAIS un glob shell) + lisibilité
    # de chaque compartiment retenu et de son STATE.md s'il existe --------------------------------
    reels = {}
    try:
        entrees = list(os.scandir(ws_root))
    except OSError:
        classes.append("workstreams-illisible")
        entrees = []
    chemin_planning_a_risque = "\n" in planning_abs
    for entree in entrees:
        try:
            est_lien = entree.is_symlink()
        except OSError:
            classes.append("compartiment-type-indetermine:" + entree.name)
            continue
        if est_lien:
            continue  # exclusion DÉCLARÉE du détecteur — pas masquant ici (lot 6, inchangé, F1)
        try:
            est_dossier = entree.is_dir(follow_symlinks=False)
        except OSError:
            classes.append("compartiment-type-indetermine:" + entree.name)
            continue
        if not est_dossier:
            continue
        # Diagnostic structurel hérité du lot 6 (des NOMS, jamais la décision — voir le
        # commentaire de tête : c'est l'égalité d'ensembles au point 1 ci-dessous qui décide) :
        if chemin_planning_a_risque:
            classes.append("chemin-planning-saut-de-ligne")
        if "\n" in entree.name:
            classes.append("nom-compartiment-saut-de-ligne")
        if entree.name.startswith("."):
            classes.append("nom-compartiment-cache:" + entree.name)
        reels[entree.name] = entree.path
        if not _ouvrable(entree.path, est_dossier=True):
            classes.append("compartiment-illisible:" + entree.name)
        else:
            # Lot 8 — même correction que pour `etat_racine` ci-dessus (`os.path.isfile`, jamais
            # `os.path.lexists` : un lien CASSÉ ici aussi est ABSENT pour le détecteur, jamais
            # illisible).
            etat_compartiment = os.path.join(entree.path, "STATE.md")
            if os.path.isfile(etat_compartiment) and not _ouvrable(etat_compartiment, est_dossier=False):
                classes.append("compartiment-state-illisible:" + entree.name)

    # --- Point 1 : FIDÉLITÉ PAR EXÉCUTION — `vf_ws_enumerate` relancée pour de vrai --------------
    ok_exec, lignes = _executer_vf_ws_enumerate(bash_bin, workstream_policy_sh, planning_abs, env_maitrise, racine_lab)
    if not ok_exec:
        classes.append("enumeration-execution-en-echec")
    else:
        attendus = sorted(reels.keys())
        obtenus = sorted(os.path.basename(l) for l in lignes)
        if attendus != obtenus:
            classes.append("enumeration-non-fidele")

    vues = []
    for c in classes:
        if c not in vues:
            vues.append(c)
    return (len(vues) == 0, vues)


# --- Détection GSD (P44-D-02a, P44-D-01b, P44-D-01c, P44-D-01d) — lot 4 ----------------------
# SOURCE UNIQUE DE VÉRITÉ (correction de CLASSE, lot 4) : aucune règle du détecteur bash
# (detect-gsd-engine.sh) n'est plus reproduite en Python. Trois copies mesurées divergentes au
# lot 3 (lien symbolique sur package.json, lien symbolique sur *.xcodeproj, STATE.md aux octets
# UTF-8 invalides après le frontmatter) fermaient chacune UN cas mais laissaient la classe ouverte
# — la seule fermeture réelle est d'appeler le VRAI détecteur, dans un environnement MAÎTRISÉ où
# sa priorité 1 (« chaîne GSD absente », le seul point qui dépend de GSD_HOME/CLAUDE_CONFIG_DIR/
# HOME hérités) ne peut plus jamais court-circuiter ses priorités 2/2bis/3. GSD_HOME est fixé
# explicitement au dossier du détecteur lui-même — un dossier qui EXISTE TOUJOURS quand ce script
# tourne (il contient detect-gsd-engine.sh, déjà vérifié régulier juste avant) — plutôt que laissé
# à la cascade par défaut du détecteur (projet-local > global > legacy > défaut), qui dépend de
# variables héritées. Aucun sourcing, aucune dépendance de code vers detect-gsd-engine.sh
# (P44-D-01b, P44-D-01d) : seul un sous-processus, sur son verdict de sortie seul.
#
# F1/F44-07 (correction de classe, 2026-09-28) : l'environnement maîtrisé ci-dessous était en fait
# `dict(os.environ)` — une COPIE INTÉGRALE du PATH (et de tout le reste) hérité, avec la seule
# SURCHARGE de GSD_HOME. Ça neutralisait bien la priorité 1 (GSD_HOME toujours présent), mais
# laissait les priorités 2/2bis/3 du détecteur, qui appellent `awk`/`mktemp`/`wc`/`cat`/`basename`
# via le PATH, entièrement soumises à ce PATH : un `awk` factice en tête (ou `BASH_ENV`, ou une
# fonction exportée `BASH_FUNC_awk%%`, ou `ENV`) fait mentir `has_frontmatter_key` sur la présence
# du marqueur `gsd_state_version`, sans jamais toucher au détecteur lui-même. Mesuré : le moteur
# écrivait (exit 0) sur un lab GSD réel et effaçait son marqueur. L'environnement est désormais
# construit DE ZÉRO (liste blanche) : PATH fixe de dossiers système, GSD_HOME seul — rien d'autre.
def detection_gsd(detect_sh, planning_abs, racine_lab):
    """« gsd », « non-gsd », « migration » ou « non-concluante ». Polarité inverse d'un DAG
    classique : l'incertitude ferme l'écriture. Fail-closed intégral (lot 4, durci F1/F44-07) :
    détecteur absent, en lien symbolique, non régulier, illisible, aucun candidat bash valide,
    échec de lancement, ou tout code de sortie hors de {0, 2, 3} (dont un 1 improbable, la
    priorité 1 étant neutralisée par l'environnement maîtrisé ci-dessous) -> `non-concluante`,
    jamais une écriture. Code 0 -> `gsd` (refus) ; code 3 -> `non-gsd` (écriture) ; code 2 ->
    `migration` : l'écriture est autorisée SOUS ADHÉSION `cycles-v1` seulement (P45-D-02, Phase 45)
    — l'adhésion est testée par `main()` AVANT cette fonction, sans adhésion la sortie 2 de la 44
    est inchangée ; la garde de lecture ci-dessous précède toujours le détecteur.
    Point envisagé et NON retenu (F1) : gater le code 3 sur une sortie stderr non vide — mesuré,
    un dossier de compartiments présent mais VIDE fait légitimement écrire deux lignes sur stderr
    (`vf_ws_enumerate`) tout en rendant le code 3 racine correct ; gater dessus aurait refusé
    l'écriture sur ce cas nominal (prose documentaire, aucun chemin résolu par ce fichier —
    vf-allow-unregistered-planning-path).
    Lot 7 (correction de CLASSE, audit du 2026-09-28) : AVANT tout appel au détecteur, une garde
    (`_lecture_detecteur_fidele`) vérifie que le moteur peut LIRE, pour de vrai, tout ce que le
    détecteur devait lire — fidélité PAR EXÉCUTION de `vf_ws_enumerate` (comparée à l'ensemble réel
    du disque) et lisibilité RÉELLE (ouverture, jamais `os.access`) de chaque compartiment retenu
    et de chaque `STATE.md` (racine et compartiments). Un écart rend TOUT verdict du détecteur non
    vérifiable : refus nommé, sans même invoquer le sous-processus détecteur. Voir le commentaire
    de tête de `_lecture_detecteur_fidele` pour le principe et le constat qui l'a motivée."""
    # F6 (revue) : « absent » (rien à cet emplacement) et « non régulier » (un dossier, un lien,
    # une FIFO...) partageaient jusqu'ici le même message stderr — deux causes distinctes,
    # confondues sous un même diagnostic. Deux motifs, deux messages désormais.
    try:
        info_detecteur = os.lstat(detect_sh)
    except OSError:
        print("[recalc-planning] détecteur absent : " + detect_sh, file=sys.stderr)
        return "non-concluante"  # motif-detecteur-absent
    if not stat.S_ISREG(info_detecteur.st_mode):
        print("[recalc-planning] détecteur non régulier : " + detect_sh, file=sys.stderr)
        return "non-concluante"  # motif-detecteur-irregulier
    bash_bin = _resoudre_bash()
    if bash_bin is None:
        print(
            "[recalc-planning] interpréteur bash introuvable pour lancer le détecteur "
            "(candidats fixes épuisés : " + ", ".join(CANDIDATS_BASH) + " — fail-closed voulu : "
            "sur un système sans AUCUN des deux (Alpine sans bash, NixOS, image distroless), "
            "ce script ne pourra plus jamais écrire, aucun repli sur un autre interpréteur)",
            file=sys.stderr,
        )
        return "non-concluante"  # motif-bash-introuvable
    # Environnement MAÎTRISÉ construit DE ZÉRO (liste blanche, F1/F44-07) : PATH fixe de dossiers
    # système, GSD_HOME pointé sur le dossier du détecteur (existe toujours). AUCUNE autre
    # variable héritée : ni BASH_ENV, ni ENV, ni une fonction exportée BASH_FUNC_*%%, ni
    # SHELLOPTS/BASHOPTS/CDPATH/TMPDIR/HOME/GSD_WORKSTREAM. Jamais `os.environ` nu ni une copie
    # partielle passée au sous-processus (P44-D-01d, verdict indépendant de tout héritage).
    # Résolu ICI, AVANT la garde de lecture (lot 7) : la garde relance `vf_ws_enumerate` dans ce
    # MÊME environnement — le détecteur et la garde doivent voir EXACTEMENT le même monde.
    env_maitrise = {"PATH": PATH_MAITRISE}
    env_maitrise["GSD_HOME"] = os.path.dirname(detect_sh)
    # Lot 7 — garde de lecture du détecteur, AVANT l'appel au détecteur (P44-D-02a) : si le moteur
    # ne peut pas lire, pour de vrai, tout ce que le détecteur devait lire (énumération fidèle des
    # compartiments PAR EXÉCUTION + lisibilité réelle de chaque élément), aucun de ses verdicts
    # (0/2/3) n'est vérifiable — inutile même d'invoquer le sous-processus.
    workstream_policy_sh = os.path.join(os.path.dirname(detect_sh), "workstream-policy.sh")
    fidele, classes_masquantes = _lecture_detecteur_fidele(
        planning_abs, bash_bin, workstream_policy_sh, env_maitrise, racine_lab,
    )
    if not fidele:
        print(
            "[recalc-planning] refus (P44-D-02a, garde de lecture du détecteur, lot 7) : le "
            "moteur n'a pas pu lire, pour de vrai, tout ce que le détecteur devait lire (classes : "
            + ", ".join(classes_masquantes) + ") — écriture refusée sans appeler le détecteur, "
            "son verdict ne serait pas vérifiable",
            file=sys.stderr,
        )
        return "non-concluante"  # motif-lecture-detecteur-non-fidele
    # `--noprofile --norc` (WR-02, revue) : ces deux drapeaux ne bloquent QUE le chargement de
    # `/etc/profile`, `~/.bash_profile` et `~/.bashrc` par un bash INTERACTIF ou de LOGIN — ils
    # n'ont AUCUN effet sur `BASH_ENV`/`ENV`, qu'un bash non-interactif lit indépendamment de ces
    # deux drapeaux. La protection réelle contre `BASH_ENV`/`ENV` vient EXCLUSIVEMENT de
    # `env_maitrise` ci-dessus, qui ne les inclut jamais dans l'environnement du sous-processus —
    # jamais des drapeaux eux-mêmes, conservés seulement en profondeur de défense si ce sous-
    # processus était un jour relancé autrement (interactif ou login).
    try:
        resultat = subprocess.run(
            [bash_bin, "--noprofile", "--norc", detect_sh, "--quiet", "--path", planning_abs],
            cwd=racine_lab, timeout=30, env=env_maitrise,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
    except Exception:
        return "non-concluante"  # motif-sous-processus-en-echec
    code = resultat.returncode
    if code == 0:
        return "gsd"  # motif-code-0
    if code == 3:
        # Point NON retenu (F1, sous-clause stderr ; prose documentaire, aucun chemin résolu ici —
        # vf-allow-unregistered-planning-path) : un code 3 « --quiet » n'est PAS toujours
        # silencieux en nominal — mesuré sur le banc (`hors-modele-racine`, dossier de
        # compartiments présent mais VIDE) : `vf_ws_enumerate` (priorité 2bis de
        # detect-gsd-engine.sh) écrit alors deux lignes sur stderr (« présent mais vide après
        # filtrage », « priorité 2bis SAUTÉE ») tout en rendant légitimement le code 3 racine.
        # Gater sur « stderr non vide » aurait donc refusé l'écriture sur ce cas nominal —
        # stderr_nominal consigné dans le rapport de mission, jamais implémenté comme gate ici.
        return "non-gsd"  # motif-code-3-terrain-libre
    if code == 2:
        # Signalement de MIGRATION (socle planning-core + signal de code) : jamais assimilé au code
        # 3 « terrain libre » (décision du head sous délégation technique de Willy, session
        # principale, 2026-09-28 — lot 2, L1). Verdict propre `migration` : l'écriture est admise
        # SOUS ADHÉSION `cycles-v1` SEULEMENT (P45-D-02, Willy, AskUserQuestion session principale,
        # 2026-09-29). Sans adhésion, `main()` sort en 2 AVANT d'appeler cette fonction : le refus de
        # la 44 est inchangé. Le détecteur reste, lui, octet pour octet celui de la 44 (P45-D-02b).
        return "migration"  # motif-code-2-migration
    if code == 1:
        # Sous environnement MAÎTRISÉ, la priorité 1 du détecteur (`[ ! -d "$GSD_HOME" ]`) ne
        # devrait plus jamais matcher — GSD_HOME ci-dessus existe toujours. Un code 1 malgré tout
        # (course, détecteur remplacé après le contrôle de régularité) ne dit RIEN sur le disque
        # du lab : fail-closed, jamais une réimplémentation Python de ses priorités 2/2bis/3
        # (P44-D-01b, P44-D-01d — c'est exactement cette réimplémentation, mesurée divergente au
        # lot 3, que ce lot supprime).
        return "non-concluante"  # motif-code-1-ferme
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
        return {e.name for e in entrees}
    except OSError:
        return set()


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
            phases.append({
                "nom": nom_phase, "chemin_abs": chemin_phase_abs, "chemin_rel": chemin_phase_rel,
                "entrees": entrees,
            })
        cycles.append({
            "nom": nom_cycle, "chemin_abs": chemin_cycle_abs, "chemin_rel": chemin_cycle_rel,
            "cycle_md": _est_regulier(os.path.join(chemin_cycle_abs, "CYCLE.md")),
            "phases": phases,
        })
    return {"cycles": cycles, "hors_modele": classer_entrees(planning)}


# --- Hors modèle et garde-fous de chemin (44-04, P44-D-04) ----------------------------------
NOMS_MODELE_RACINE_DOSSIERS = ("cycles", "baux", "missions")
NOMS_MODELE_RACINE_FICHIERS = (
    "PROJECT.md", "REQUIREMENTS.md", "config.json", "INDEX.md", "STATE.md",
    "cloture.log", ".recalc-cache.json",
    # Journal de dérogation des gates (P45-D-13, F7a — Willy, AskUserQuestion session principale,
    # 2026-09-30) : emplacement du modèle, jamais « Hors modèle » dans INDEX.md. Même nom consommé
    # par la commande de dérogation (45-04) et le gate G6 (45-05).
    "derogations-gates.log",
)


def _entrees_scandir(dossier):
    """Liste triée par nom des os.DirEntry d'un dossier ; [] si absent, illisible ou non-dossier."""
    try:
        return sorted(os.scandir(dossier), key=lambda e: e.name)
    except OSError:
        return []


def _type_entree_de(entree):
    """('dossier'|'fichier'|'lien'|'autre') depuis un os.DirEntry — jamais un suivi de lien."""
    try:
        if entree.is_symlink():
            return "lien"
        if entree.is_dir(follow_symlinks=False):
            return "dossier"
        if entree.is_file(follow_symlinks=False):
            return "fichier"
    except OSError:
        pass
    return "autre"


def echapper_nom(nom):
    """Échappe tout caractère de catégorie Unicode C* en `\\uXXXX` (quatre chiffres hexadécimaux
    en minuscules, complétés de zéros à gauche — même convention que `\\u000a`) pour un point de
    code dans le plan de base (<= U+FFFF) ; au-delà du plan de base multilingue Unicode (P44-D-17,
    correction de portée), la forme `\\UXXXXXXXX` (huit chiffres hexadécimaux en minuscules)
    reprend la convention littérale Python pour un point de code supplémentaire — un private-use
    de plan supplémentaire (catégorie Co) ou tout autre caractère de contrôle au-delà du BMP ne
    serait sinon ni représentable ni tronqué en silence. L'accent grave devient `` \\` ``."""
    resultat = []
    for c in nom:
        if c == "`":
            resultat.append("\\`")
            continue
        if unicodedata.category(c).startswith("C"):
            point_de_code = ord(c)
            if point_de_code <= 0xFFFF:
                resultat.append("\\u{:04x}".format(point_de_code))
            else:
                resultat.append("\\U{:08x}".format(point_de_code))
            continue
        resultat.append(c)
    return "".join(resultat)


def _classer_racine(planning):
    """Racine de `.planning/` : les six annexes et les emplacements du modèle doivent être du bon
    type (jamais lus s'ils sont annexes) ; tout le reste, un emplacement du mauvais type et tout
    lien symbolique -> hors modèle (44-04 § Classement)."""
    hors = []
    for entree in _entrees_scandir(planning):
        nom = entree.name
        type_ = _type_entree_de(entree)
        if type_ == "lien":
            hors.append({"chemin": nom, "type": "lien"})
            continue
        if nom in ANNEXES:
            if type_ != "dossier":
                hors.append({"chemin": nom, "type": type_})
            continue  # annexe reconnue : jamais lue, jamais descendue
        if nom in NOMS_MODELE_RACINE_DOSSIERS:
            if type_ != "dossier":
                hors.append({"chemin": nom, "type": type_})
            continue
        if nom in NOMS_MODELE_RACINE_FICHIERS:
            if type_ != "fichier":
                hors.append({"chemin": nom, "type": type_})
            continue
        hors.append({"chemin": nom, "type": type_})
    return hors


def _classer_plan_entrees(chemin_plan_abs, chemin_plan_rel, hors):
    for entree in _entrees_scandir(chemin_plan_abs):
        nom = entree.name
        chemin_rel = chemin_plan_rel + "/" + nom
        if nom in NOMS_MODELE_PLAN:
            continue  # nom reconnu ; le type reste le ressort de Φ1, jamais de classer_entrees
        hors.append({"chemin": chemin_rel, "type": _type_entree_de(entree)})


def _classer_plans_dir_entrees(dossier_plans_abs, chemin_plans_rel, hors):
    for entree in _entrees_scandir(dossier_plans_abs):
        nom = entree.name
        type_ = _type_entree_de(entree)
        chemin_rel = chemin_plans_rel + "/" + nom
        if type_ == "dossier" and NOM_UNITE.match(nom):  # plan
            _classer_plan_entrees(os.path.join(dossier_plans_abs, nom), chemin_rel, hors)
            continue
        hors.append({"chemin": chemin_rel, "type": type_})


def _classer_phase_entrees(chemin_phase_abs, chemin_phase_rel, hors):
    for entree in _entrees_scandir(chemin_phase_abs):
        nom = entree.name
        type_ = _type_entree_de(entree)
        chemin_rel = chemin_phase_rel + "/" + nom
        if nom in NOMS_MODELE_PHASE:
            continue  # nom reconnu ; le type reste le ressort de Φ1, jamais de classer_entrees
        if nom == "plans":
            if type_ == "dossier":
                _classer_plans_dir_entrees(os.path.join(chemin_phase_abs, nom), chemin_rel, hors)
            else:
                hors.append({"chemin": chemin_rel, "type": type_})
            continue
        hors.append({"chemin": chemin_rel, "type": type_})


def _classer_phases_dir_entrees(dossier_phases_abs, chemin_phases_rel, hors):
    for entree in _entrees_scandir(dossier_phases_abs):
        nom = entree.name
        type_ = _type_entree_de(entree)
        chemin_rel = chemin_phases_rel + "/" + nom
        if type_ == "dossier" and NOM_UNITE.match(nom):  # phase
            _classer_phase_entrees(os.path.join(dossier_phases_abs, nom), chemin_rel, hors)
            continue
        hors.append({"chemin": chemin_rel, "type": type_})


def _classer_cycle_entrees(chemin_cycle_abs, chemin_cycle_rel, hors):
    for entree in _entrees_scandir(chemin_cycle_abs):
        nom = entree.name
        type_ = _type_entree_de(entree)
        chemin_rel = chemin_cycle_rel + "/" + nom
        if nom == "CYCLE.md":
            continue  # nom reconnu ; le type reste le ressort de Φ1 (cycle_md), jamais ici
        if nom == "phases":
            if type_ == "dossier":
                _classer_phases_dir_entrees(os.path.join(chemin_cycle_abs, nom), chemin_rel, hors)
            else:
                hors.append({"chemin": chemin_rel, "type": type_})
            continue
        hors.append({"chemin": chemin_rel, "type": type_})


def _classer_arbre_cycles(planning):
    """Arbre `cycles/` : dossiers d'unité au nom valide descendus récursivement ; tout autre nom,
    un nom d'unité invalide, un dossier d'unité en lien -> hors modèle, jamais parcouru."""
    hors = []
    dossier_cycles = os.path.join(planning, "cycles")
    try:
        cycles_est_dossier_reel = stat.S_ISDIR(os.lstat(dossier_cycles).st_mode)
    except OSError:
        cycles_est_dossier_reel = False
    if not cycles_est_dossier_reel:
        return hors
    for entree in _entrees_scandir(dossier_cycles):
        nom = entree.name
        type_ = _type_entree_de(entree)
        chemin_rel = "cycles/" + nom
        if type_ == "dossier" and NOM_UNITE.match(nom):  # cycle
            _classer_cycle_entrees(os.path.join(dossier_cycles, nom), chemin_rel, hors)
            continue
        hors.append({"chemin": chemin_rel, "type": type_})
    return hors


def classer_entrees(planning):
    """(hors_modele : liste triée de {chemin, type}) — racine puis arbre `cycles/`, interface
    44-04 § Classement. Jamais un `os.listdir` (ni un `os.scandir`) dans un lien ni dans une
    annexe."""
    hors = _classer_racine(planning) + _classer_arbre_cycles(planning)
    return sorted(hors, key=lambda e: e["chemin"])


def _est_dossier(chemin):
    try:
        return stat.S_ISDIR(os.lstat(chemin).st_mode)
    except OSError:
        return False


# --- Grammaire du registre de cadrage et du champ ecrit: --------------------------------------
def lire_registre(donnees_cadrage):
    """(registre_ok, registre_clos) depuis le frontmatter DÉJÀ analysé de CADRAGE.md. Φ3 : registre
    absent ou mal formé (structurante hors oui/non, ligne qui n'est pas un mapping) -> registre_ok
    faux (`registre-invalide`). Lecture littérale spec §3.1 l.213 : TOUTE valeur non vide de
    `statut` ferme la ligne, quelle qu'elle soit — jamais une liste fermée, jamais un jugement de
    la valeur elle-même. `inconnues: []` est clos."""
    inconnues = donnees_cadrage.get("inconnues")
    if not isinstance(inconnues, list):
        return (False, False)
    clos = True
    for item in inconnues:
        if not isinstance(item, dict):
            return (False, False)
        structurante = item.get("structurante")
        if structurante not in ("oui", "non"):
            return (False, False)
        statut = item.get("statut")
        if structurante == "oui" and not (isinstance(statut, str) and statut.strip()):
            clos = False
    return (True, clos)


def entree_ecrit_valide(entree):
    """Une entrée `ecrit:` valide : chemin concret relatif à la racine du lab, non vide, sans `/`
    ni `~` initial, sans segment `..`, sans caractère de contrôle ni `\\`, sans métacaractère
    `*?[]{}<>` — jamais un motif (même règle que le moteur de recalcul)."""
    if not isinstance(entree, str) or entree == "":
        return False
    if entree.startswith("/") or entree.startswith("~"):
        return False
    if ".." in entree.split("/"):
        return False
    if any(ord(c) < 0x20 or ord(c) == 0x7F for c in entree):
        return False
    if "\\" in entree:
        return False
    if any(c in entree for c in "*?[]{}<>"):
        return False
    return True


def _valeurs_ecrit(donnees):
    ecrit = donnees.get("ecrit")
    if isinstance(ecrit, str):
        return [ecrit]
    if isinstance(ecrit, list):
        return ecrit
    return None


# --- Prédicat « livrable présent » et empreinte des livrables : bloc partagé (Phase 46, 46-01 ; P46-D-03a, P46-D-12) ----------
# MÊME texte dans poser-verdict.sh, planning-hook.sh et recalc-planning.sh (l'installeur ne pose que des `*.sh` : pas de module
# partagé, des copies ast-identiques que la suite test-cloture-empreintes.sh compare, R-EMP-04). Le parcours est borné et les
# bornes comptent les ENTRÉES parcourues (fichiers, sous-dossiers, liens) : un dépassement est un refus explicite, jamais une
# empreinte partielle. Les noms de NOMS_EXCLUS_LIVRABLES sont ignorés partout (prédicat « vide » ET empreinte) : ouvrir un
# dossier livrable dans le Finder ou l'Explorateur ne doit pas périmer un verdict.
BORNE_FICHIERS_LIVRABLES = 2000
BORNE_OCTETS_LIVRABLES = 134217728
NOMS_EXCLUS_LIVRABLES = (".DS_Store", "Thumbs.db", "desktop.ini")


def _normaliser_livrable(entree):
    """Entrée `ecrit:` normalisée : composants non vides et différents de `.`, rejoints par `/` (barre finale retirée)."""
    return "/".join(c for c in entree.split("/") if c not in ("", "."))


def _fichier_non_vide(taille):
    """Vrai si un fichier régulier de `taille` octets (lstat) n'est pas vide."""
    return taille > 0  # livrable-vide


def _nom_sain(nom):
    """Vrai si le nom d'une entrée de dossier se décode en UTF-8 et ne porte aucun caractère de contrôle : sans cela le texte
    canonique de l'empreinte serait ambigu (tabulation, saut de ligne) ou non encodable."""
    try:
        nom.encode("utf-8")
    except UnicodeEncodeError:
        return False
    return not any(ord(c) < 0x20 or ord(c) == 0x7F for c in nom)


def _borne_depassee(budget):
    """Libellé de la borne franchie par `budget` = [entrées parcourues, octets annoncés par lstat, octets lus], ou None."""
    if budget[0] > BORNE_FICHIERS_LIVRABLES:  # livrable-borne
        return "borne de %d fichiers dépassée (BORNE_FICHIERS_LIVRABLES)" % BORNE_FICHIERS_LIVRABLES
    if budget[1] > BORNE_OCTETS_LIVRABLES or budget[2] > BORNE_OCTETS_LIVRABLES:
        return "borne de %d octets dépassée (BORNE_OCTETS_LIVRABLES)" % BORNE_OCTETS_LIVRABLES
    return None


def _parcourir_livrable(dossier, relatif, budget):
    """(statut, detail, fichiers) : les fichiers réguliers du sous-arbre de `dossier` (`relatif` : son chemin relatif au lab),
    triés par chemin relatif, sous forme (relatif, chemin absolu, taille). Lstat sur chaque entrée : un lien et un fichier
    spécial interne ne sont ni suivis ni retenus. Statut `ok`, `borne` (detail = libellé de la borne) ou `illisible`."""
    fichiers = []
    pile = [(dossier, relatif)]
    while pile:
        courant, rel = pile.pop()
        try:
            with os.scandir(courant) as entrees:
                for entree in entrees:
                    nom = entree.name
                    if nom in NOMS_EXCLUS_LIVRABLES:  # livrable-exclus
                        continue
                    if not _nom_sain(nom):
                        return ("illisible", rel, [])
                    info = entree.stat(follow_symlinks=False)
                    budget[0] += 1
                    if stat.S_ISREG(info.st_mode):
                        budget[1] += info.st_size
                    depasse = _borne_depassee(budget)
                    if depasse is not None:
                        return ("borne", depasse, [])
                    if stat.S_ISDIR(info.st_mode):
                        pile.append((entree.path, rel + "/" + nom))
                    elif stat.S_ISREG(info.st_mode):
                        fichiers.append((rel + "/" + nom, entree.path, info.st_size))
        except OSError:
            return ("illisible", rel, [])
    fichiers.sort()
    return ("ok", relatif, fichiers)


def _examiner_livrable(racine, entree, budget):
    """(statut, detail, genre, fichiers) d'une entrée `ecrit:`. Le chemin est parcouru composant par composant par lstat : un
    lien, terminal ou intermédiaire, rend le livrable `lien` (jamais suivi). Un fichier régulier de 0 octet est `vide` ; un dossier
    sans aucun fichier régulier non vide est `vide` ; une entrée absente, un composant intermédiaire qui n'est pas un dossier ou un
    fichier spécial (FIFO, socket, périphérique) est `absent` ; une erreur de lecture est `illisible` ; un dépassement de borne est
    `borne`. `genre` vaut `fichier` ou `dossier` pour un livrable `present`."""
    normale = _normaliser_livrable(entree)
    composants = normale.split("/") if normale != "" else []
    if not composants:
        return ("absent", entree if entree != "" else ".", "", [])
    courant = racine
    info = None
    for rang, composant in enumerate(composants):
        courant = os.path.join(courant, composant)
        try:
            info = os.lstat(courant)  # livrable-lien
        except (FileNotFoundError, NotADirectoryError):
            return ("absent", normale, "", [])
        except OSError:
            return ("illisible", normale, "", [])
        if stat.S_ISLNK(info.st_mode):
            return ("lien", normale, "", [])
        if rang < len(composants) - 1 and not stat.S_ISDIR(info.st_mode):
            return ("absent", normale, "", [])
    if stat.S_ISREG(info.st_mode):
        budget[0] += 1
        budget[1] += info.st_size
        depasse = _borne_depassee(budget)
        if depasse is not None:
            return ("borne", depasse, "", [])
        if not _fichier_non_vide(info.st_size):
            return ("vide", normale, "", [])
        return ("present", normale, "fichier", [(normale, courant, info.st_size)])
    if stat.S_ISDIR(info.st_mode):
        statut, detail, fichiers = _parcourir_livrable(courant, normale, budget)
        if statut != "ok":
            return (statut, detail, "", [])
        if not any(_fichier_non_vide(f[2]) for f in fichiers):
            return ("vide", normale, "", [])
        return ("present", normale, "dossier", fichiers)
    return ("absent", normale, "", [])


def livrable_present(racine, entree):
    """(statut, detail) du livrable `entree` d'un `ecrit:` du lab de racine `racine` : statut `present`, `absent`, `lien`, `vide`,
    `borne` ou `illisible` (voir `_examiner_livrable`). Le prédicat unique de G3 et de la règle R4 du recalcul (P46-D-12)."""
    statut, detail, _genre, _fichiers = _examiner_livrable(racine, entree, [0, 0, 0])
    return (statut, detail)


def _hacher_livrable(chemin, budget):
    """(statut, valeur) : `ok` et le sha256 hexadécimal du fichier régulier `chemin` (ouvert O_NOFOLLOW puis fstat régulier, lu par
    blocs, octets lus ajoutés au budget partagé), `borne` et le libellé de la borne, ou `illisible`. Jamais un hash partiel."""
    import hashlib
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
    except OSError:
        return ("illisible", "")
    hacheur = hashlib.sha256()
    try:
        with os.fdopen(descripteur, "rb") as fh:
            if not stat.S_ISREG(os.fstat(fh.fileno()).st_mode):
                return ("illisible", "")
            while True:
                bloc = fh.read(65536)
                if not bloc:
                    break
                budget[2] += len(bloc)
                depasse = _borne_depassee(budget)
                if depasse is not None:
                    return ("borne", depasse)
                hacheur.update(bloc)
    except OSError:
        return ("illisible", "")
    return ("ok", hacheur.hexdigest())


def empreinte_livrables(racine, entrees):
    """("ok", sha256 hexadécimal) ou (statut d'échec, entrée ou libellé de borne) pour les entrées `ecrit:` `entrees`. Texte
    canonique : entrées normalisées, dédoublonnées et triées ; une ligne `fichier<TAB><chemin relatif au lab><TAB><sha256>` par
    entrée fichier ; pour une entrée dossier, une ligne `dossier<TAB><entrée>` puis une ligne `fichier…` par fichier régulier du
    sous-arbre, triées par chemin relatif ; lignes jointes par `\\n`, saut final, haché en UTF-8. Le budget (entrées et octets) est
    commun à toutes les entrées. Une entrée qui n'est pas `present` (absente, vide, lien, borne, illisible) fait échouer le calcul."""
    import hashlib
    budget = [0, 0, 0]
    lignes = []
    for entree in sorted(set(_normaliser_livrable(e) for e in entrees)):  # empreinte-tri
        statut, detail, genre, fichiers = _examiner_livrable(racine, entree, budget)
        if statut != "present":
            return (statut, detail)
        if genre == "dossier":
            lignes.append("dossier\t" + detail)
        for rel, chemin, _taille in fichiers:
            statut_hache, valeur = _hacher_livrable(chemin, budget)
            if statut_hache != "ok":
                return (statut_hache, valeur if valeur != "" else rel)
            lignes.append("fichier\t" + rel + "\t" + valeur)
    texte = "\n".join(lignes) + "\n"
    return ("ok", hashlib.sha256(texte.encode("utf-8")).hexdigest())


# --- Dérogation nominative (Φ0, P44-D-07) ------------------------------------------------------
DEROGATION_MOTS = ("abandonné", "remplacé", "gelé")
DEROGATION_RE = re.compile(r"^(abandonné|remplacé|gelé) par (\S.*)$")


def lire_derogation(chemin_derogation):
    """(mot|None, raison|None, auteur|None) — regex `^(abandonné|remplacé|gelé) par (\\S.*)$` sur
    `statut:`. Valeur exactement égale à l'un des trois mots (sans « par <auteur> ») ->
    `derogation-sans-auteur`. Tout autre cas -> `derogation-invalide`."""
    statut_fm, donnees = _lire_frontmatter_fichier(chemin_derogation)
    if statut_fm != "ok":
        return (None, "derogation-invalide", None)
    statut = donnees.get("statut")
    if not isinstance(statut, str):
        return (None, "derogation-invalide", None)
    m = DEROGATION_RE.match(statut)
    if m:
        mot, auteur = m.group(1), m.group(2).strip()
        if auteur:
            return (mot, None, auteur)
        return (None, "derogation-invalide", None)
    if statut in DEROGATION_MOTS:
        return (None, "derogation-sans-auteur", None)
    return (None, "derogation-invalide", None)


# --- Méta commune (auteur, tentative, hash) -----------------------------------------------------
def _meta_unite(chemin_abs, entrees):
    auteur = None
    if "SUMMARY.md" in entrees:
        statut, donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "SUMMARY.md"))
        if statut == "ok":
            auteur = donnees.get("auteur")
    tentative = None
    hash_juge = None
    hash_livrables = None
    if "VERDICT.md" in entrees:
        statut, donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "VERDICT.md"))
        if statut == "ok":
            tentative = donnees.get("tentative")
            hash_juge = donnees.get("hash")
            hash_livrables = donnees.get("hash_livrables")
    return {"auteur": auteur or "inconnu", "tentative": tentative, "hash_juge": hash_juge,
            "hash_livrables": hash_livrables, "type_derivation": None}


# --- Φ1 : régularité et lisibilité des fichiers du modèle présents ------------------------------
def _verifier_fichiers_reguliers(chemin_abs, entrees, noms_modele):
    """Premier fichier du modèle présent mais non régulier -> `fichier-non-regulier:<nom>` ;
    régulier mais illisible ou non UTF-8 -> `erreur-de-lecture:<nom>`. None si rien à signaler."""
    for nom in noms_modele:
        if nom not in entrees:
            continue
        chemin = os.path.join(chemin_abs, nom)
        if not est_fichier_regulier(chemin):
            return "fichier-non-regulier:" + nom
        try:
            descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
            with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
                fh.read()
        except (OSError, UnicodeDecodeError):
            return "erreur-de-lecture:" + nom
    return None


# --- Φ0 : dérogation nominative, commune à une phase à plan direct et à un plan -----------------
def _phi0(chemin_abs, entrees, meta):
    if "DEROGATION.md" not in entrees:
        return None
    chemin_derog = os.path.join(chemin_abs, "DEROGATION.md")
    if not _est_regulier(chemin_derog):
        return None  # non régulier : Φ1 le rattrape (fichier-non-regulier:DEROGATION.md)
    mot, raison, auteur = lire_derogation(chemin_derog)
    if raison is not None:
        return ("indéterminé", raison, meta)
    meta2 = dict(meta)
    meta2["auteur"] = auteur
    meta2["type_derivation"] = "derogation"
    return (mot, None, meta2)


# --- R1 à R8 : règles de feuille (phase à plan direct, ou plan de plans/) -----------------------
def _r1_a_r8(chemin_abs, entrees, racine_lab, meta):
    plan_present = "PLAN.md" in entrees
    cloture_present = "CLOTURE.md" in entrees
    verdict_present = "VERDICT.md" in entrees
    summary_present = "SUMMARY.md" in entrees
    # R1
    if not plan_present:
        if summary_present:
            return ("indéterminé", "SUMMARY.md-sans-PLAN.md", meta)
        if cloture_present:
            return ("indéterminé", "CLOTURE.md-sans-PLAN.md", meta)
        if verdict_present:
            return ("indéterminé", "VERDICT.md-sans-PLAN.md", meta)
        return ("à planifier", None, meta)
    # R2
    plan_statut, plan_donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "PLAN.md"))
    if plan_statut != "ok":
        return ("indéterminé", "frontmatter-invalide:PLAN.md", meta)
    valeurs = _valeurs_ecrit(plan_donnees)
    if not valeurs or not all(entree_ecrit_valide(v) for v in valeurs):
        return ("indéterminé", "ecrit-invalide", meta)
    # R3
    if not cloture_present:
        if verdict_present:
            return ("indéterminé", "VERDICT.md-sans-CLOTURE.md", meta)
        if summary_present:
            return ("indéterminé", "SUMMARY.md-sans-CLOTURE.md", meta)
        return ("à exécuter", None, meta)
    # R4 : « absent ou vide » par le prédicat partagé (P46-D-12) ; un lien, terminal ou intermédiaire, est absent
    for v in valeurs:
        statut_livrable, _detail_livrable = livrable_present(racine_lab, v)  # r4-predicat
        if statut_livrable == "vide":
            return ("indéterminé", "livrable-vide:" + v, meta)
        if statut_livrable == "borne":
            return ("indéterminé", "livrable-hors-borne:" + v, meta)
        if statut_livrable != "present":
            return ("indéterminé", "livrable-absent:" + v, meta)
    # R5
    if not verdict_present:
        if summary_present:
            return ("indéterminé", "SUMMARY.md-sans-VERDICT.md", meta)
        return ("à juger", None, meta)
    # R6
    verdict_statut, verdict_donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "VERDICT.md"))
    if verdict_statut != "ok":
        return ("indéterminé", "frontmatter-invalide:VERDICT.md", meta)
    constats = verdict_donnees.get("constats")
    if not isinstance(constats, list) or len(constats) == 0 or any(
        not isinstance(c, dict) or c.get("resultat") not in ("passé", "échec") for c in constats
    ):
        return ("indéterminé", "verdict-invalide", meta)
    # E : les deux empreintes du verdict (P46-D-03b) — `hash` (sha256 des octets du PLAN.md) et `hash_livrables` (empreinte composée
    # des entrées `ecrit:`, copie partagée de 46-01). Un écart, ou un `hash_livrables` absent, périme le verdict : R7 et R8 ne
    # s'appliquent qu'à un verdict conforme.
    empreinte_plan = hash_contenu(os.path.join(chemin_abs, "PLAN.md"))  # r-empreintes
    perime = empreinte_plan is None or meta["hash_juge"] != empreinte_plan
    if not perime:
        statut_emp, valeur_emp = empreinte_livrables(racine_lab, valeurs)  # r-empreintes-livrables
        if statut_emp == "borne":
            return ("indéterminé", "empreinte-hors-borne", meta)
        perime = statut_emp != "ok" or meta["hash_livrables"] != valeur_emp
    if perime:
        if summary_present:
            return ("indéterminé", "livrable-modifie-apres-cloture", meta)
        return ("à juger", "verdict-perime", meta)
    # R7
    if any(c.get("resultat") == "échec" for c in constats):
        if summary_present:
            return ("indéterminé", "SUMMARY.md-avec-verdict-en-echec", meta)
        return ("à corriger", None, meta)
    # R8
    if summary_present:
        meta2 = dict(meta)
        meta2["type_derivation"] = "feuille"
        return ("close", None, meta2)
    return ("à clore", None, meta)  # r8-a-clore


def deriver_feuille(unite, racine_lab):
    """Φ0 puis Φ1 puis R1 à R8 — pour une phase à plan direct (appelée depuis deriver_phase) ou un
    plan de `plans/` (appelée directement). (état, raison, méta)."""
    chemin_abs = unite["chemin_abs"]
    entrees = unite["entrees"]
    meta = _meta_unite(chemin_abs, entrees)
    r = _phi0(chemin_abs, entrees, meta)
    if r is not None:
        return r
    raison = _verifier_fichiers_reguliers(chemin_abs, entrees, NOMS_MODELE_PLAN)
    if raison is not None:
        return ("indéterminé", raison, meta)
    return _r1_a_r8(chemin_abs, entrees, racine_lab, meta)


# --- Incrémental par hash du contenu (44-04, P44-D-13) --------------------------------------
def hash_contenu(chemin):
    """sha256 du contenu d'un fichier régulier, lu par blocs, ouvert `SANS_SUIVI_DE_LIEN` après
    `est_fichier_regulier` — jamais None silencieux vers une confiance aveugle : None si non
    régulier ou illisible, jamais un hash d'un contenu partiel."""
    if not est_fichier_regulier(chemin):
        return None
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
    except OSError:
        return None
    hacheur = hashlib.sha256()
    try:
        with os.fdopen(descripteur, "rb") as fh:
            while True:
                bloc = fh.read(65536)
                if not bloc:
                    break
                hacheur.update(bloc)
    except OSError:
        return None
    return hacheur.hexdigest()


def signature_unite(unite, noms_modele, chemin_cadrage_supplementaire=None):
    """sha256 du texte canonique (44-04, P44-D-13) : liste triée des entrées du dossier de
    l'unité (nom + type) + (nom, sha256 du contenu) de chaque fichier de `noms_modele` PRÉSENT et
    RÉGULIER + pour un plan (`chemin_cadrage_supplementaire` fourni), le sha256 du CADRAGE.md de
    sa phase. Jamais une API de date de fichier — le contenu seul, jamais le moment où il a été
    écrit."""
    chemin_abs = unite["chemin_abs"]
    lignes = []
    for entree in _entrees_scandir(chemin_abs):
        lignes.append("entree\t" + entree.name + "\t" + _type_entree_de(entree))
    for nom in sorted(noms_modele):
        chemin_fichier = os.path.join(chemin_abs, nom)
        h = hash_contenu(chemin_fichier)
        if h is not None:
            lignes.append("fichier\t" + nom + "\t" + h)
    if chemin_cadrage_supplementaire is not None:
        h = hash_contenu(chemin_cadrage_supplementaire)
        if h is not None:
            lignes.append("cadrage\t" + h)
    texte = "\n".join(lignes)
    return hashlib.sha256(texte.encode("utf-8")).hexdigest()


def _lire_ecrit_reel(chemin_abs):
    """Liste triée des entrées `ecrit:` valides de PLAN.md, [] si absent, illisible ou invalide —
    ne DÉCIDE rien (R2/R4 restent le seul juge de l'état), seulement ce que le cache doit
    surveiller pour la reprise (P44-D-13, existence des livrables revue à chaque passage)."""
    plan_statut, plan_donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "PLAN.md"))
    if plan_statut != "ok":
        return []
    valeurs = _valeurs_ecrit(plan_donnees)
    if not valeurs:
        return []
    return sorted(v for v in valeurs if entree_ecrit_valide(v))


def charger_cache(planning):
    """(statut, donnees) — statut in {'absent', 'illisible', 'autre-format', 'valide'}. Tout
    statut hors 'valide' -> recalcul complet, jamais une confiance aveugle (44-04, P44-D-13) :
    absent, lien symbolique, non régulier, JSON invalide, racine non objet, ou d'un
    `cache_schema_version`/`moteur` différent sont TOUS traités à égalité."""
    chemin = os.path.join(planning, ".recalc-cache.json")
    if not est_fichier_regulier(chemin):
        try:
            os.lstat(chemin)
        except OSError:
            return ("absent", {})
        return ("illisible", {})
    try:
        descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "r", encoding="utf-8") as fh:
            texte = fh.read()
    except (OSError, UnicodeDecodeError):
        return ("illisible", {})
    try:
        donnees = json.loads(texte)
    except ValueError:
        return ("illisible", {})
    if not isinstance(donnees, dict):
        return ("autre-format", {})
    if donnees.get("cache_schema_version") != CACHE_SCHEMA_VERSION:
        return ("autre-format", {})
    if donnees.get("moteur") != "recalc-planning":
        return ("autre-format", {})
    unites = donnees.get("unites")
    if not isinstance(unites, dict):
        return ("autre-format", {})
    for cle, valeur in unites.items():
        if not isinstance(cle, str) or not isinstance(valeur, dict):
            return ("autre-format", {})
        if "signature" not in valeur or "etat" not in valeur:
            return ("autre-format", {})
    return ("valide", donnees)


def _deriver_feuille_cache(unite, racine_lab, cache_ctx, chemin_cadrage_supplementaire=None):
    """Enveloppe de `deriver_feuille` consciente du cache (44-04, P44-D-13) : `cache_ctx` None ->
    jamais consulté ni écrit (mode lecture seule, T-44-21) — délègue alors directement à
    `deriver_feuille`. Sinon, reprend l'entrée du cache existant SI la signature ET l'existence
    des livrables re-vérifiée à cet instant concordent toutes deux ; sinon recalcule et enregistre
    la nouvelle entrée."""
    if cache_ctx is None:
        return deriver_feuille(unite, racine_lab)
    chemin_rel = unite["chemin_rel"]
    signature = signature_unite(unite, NOMS_MODELE_PLAN, chemin_cadrage_supplementaire)
    entree_cache = (cache_ctx["existant"] or {}).get(chemin_rel)
    if isinstance(entree_cache, dict) and entree_cache.get("signature") == signature:
        ecrit_cache = entree_cache.get("ecrit") or []
        livrables_cache = entree_cache.get("livrables") or {}
        livrables_actuels = {v: os.path.lexists(os.path.join(racine_lab, v)) for v in ecrit_cache}
        if livrables_actuels == livrables_cache:
            cache_ctx["nouveau"][chemin_rel] = entree_cache
            cache_ctx["reprises"] += 1
            return (entree_cache.get("etat"), entree_cache.get("raison"), dict(entree_cache.get("meta") or {}))
    etat, raison, meta = deriver_feuille(unite, racine_lab)
    ecrit_reel = _lire_ecrit_reel(unite["chemin_abs"])
    livrables_reel = {v: os.path.lexists(os.path.join(racine_lab, v)) for v in ecrit_reel}
    cache_ctx["nouveau"][chemin_rel] = {
        "signature": signature, "ecrit": ecrit_reel, "livrables": livrables_reel,
        "etat": etat, "raison": raison, "meta": meta,
    }
    cache_ctx["recalculees"] += 1
    return (etat, raison, meta)


# --- Agrégation ----------------------------------------------------------------------------------
def _raison_a_juger(unite):
    """La raison d'une unité `à juger` (le seul état non terminal et non indéterminé qui en porte une : `verdict-perime`), None
    pour tout autre état — la remonte du plan à la phase et au cycle pour que INDEX.md et STATE.md la rendent."""
    return unite.get("raison") if unite["etat"] == "à juger" else None


def agreger(etats):
    """Première unité (déjà triée par nom) dont l'état n'est ni close ni abandonné ni remplacé ;
    si toutes sont terminales, close prime dès qu'au moins une l'est, sinon abandonné."""
    non_terminaux = [e for e in etats if e["etat"] not in TERMINAUX]
    if non_terminaux:
        return non_terminaux[0]
    if any(e["etat"] == "close" for e in etats):
        return next(e for e in etats if e["etat"] == "close")
    return etats[-1]


def _nom_premier_fichier_execution(entrees, a_plans_dir):
    for nom in ("PLAN.md", "CLOTURE.md", "VERDICT.md", "SUMMARY.md"):
        if nom in entrees:
            return nom
    if a_plans_dir:
        return "plans"
    return None


def _agreger_plans(phase, racine_lab, cache_ctx=None):
    """Φ5, `plans/` présent sans fichier de plan au niveau phase : agrégation des plans de la
    phase (P44-D-07). `plans/` sans aucun plan -> `à planifier`. `cache_ctx` : voir
    `_deriver_feuille_cache` — None en lecture seule (jamais consulté ni écrit)."""
    chemin_abs = phase["chemin_abs"]
    dossier_plans = os.path.join(chemin_abs, "plans")
    noms_plans = _lister_noms_unite(dossier_plans)
    meta_phase = {"auteur": "inconnu", "tentative": None, "hash_juge": None, "type_derivation": "plans-agregation"}
    if not noms_plans:
        return ("à planifier", None, meta_phase, [])
    chemin_cadrage_phase = os.path.join(chemin_abs, "CADRAGE.md")
    plans_derives = []
    for nom_plan in noms_plans:
        chemin_plan_abs = os.path.join(dossier_plans, nom_plan)
        chemin_plan_rel = phase["chemin_rel"] + "/plans/" + nom_plan
        entrees_plan = _lister_entrees(chemin_plan_abs)
        unite = {"nom": nom_plan, "chemin_abs": chemin_plan_abs, "chemin_rel": chemin_plan_rel, "entrees": entrees_plan}
        etat, raison, meta = _deriver_feuille_cache(unite, racine_lab, cache_ctx, chemin_cadrage_phase)
        plans_derives.append({
            "nom": nom_plan, "chemin": chemin_plan_rel, "etat": etat, "raison": raison,
            "auteur": meta["auteur"], "tentative": meta["tentative"], "hash_juge": meta["hash_juge"],
            "type_derivation": meta.get("type_derivation"),
        })
    plans_indetermines = [p for p in plans_derives if p["etat"] == "indéterminé"]
    if plans_indetermines:
        premier = plans_indetermines[0]
        return ("indéterminé", "plan-indetermine:" + premier["nom"], meta_phase, plans_derives)
    courant = agreger(plans_derives)
    if courant["etat"] not in TERMINAUX:
        return (courant["etat"], _raison_a_juger(courant), meta_phase, plans_derives)
    if any(p["etat"] == "close" for p in plans_derives):
        return ("close", None, meta_phase, plans_derives)
    return ("abandonné", None, meta_phase, plans_derives)


def deriver_phase(phase, racine_lab, cache_ctx=None):
    """Φ0 à Φ5, dans l'ordre — la première règle qui s'applique gagne. (état, raison, méta,
    plans). `cache_ctx` : voir `_deriver_feuille_cache` — None en lecture seule."""
    chemin_abs = phase["chemin_abs"]
    entrees = phase["entrees"]
    meta = _meta_unite(chemin_abs, entrees)
    # Φ0
    r = _phi0(chemin_abs, entrees, meta)
    if r is not None:
        etat, raison, meta2 = r
        return (etat, raison, meta2, [])
    # Φ1
    raison = _verifier_fichiers_reguliers(chemin_abs, entrees, NOMS_MODELE_PHASE)
    if raison is not None:
        return ("indéterminé", raison, meta, [])
    # Φ2
    cadrage_present = "CADRAGE.md" in entrees
    a_plans_dir = "plans" in entrees and _est_dossier(os.path.join(chemin_abs, "plans"))
    if not cadrage_present:
        nom = _nom_premier_fichier_execution(entrees, a_plans_dir)
        if nom is not None:
            return ("indéterminé", "hors-cadrage:" + nom, meta, [])
        return ("à cadrer", None, meta, [])
    # Φ3
    cadrage_statut, cadrage_donnees = _lire_frontmatter_fichier(os.path.join(chemin_abs, "CADRAGE.md"))
    if cadrage_statut != "ok":
        return ("indéterminé", "frontmatter-invalide:CADRAGE.md", meta, [])
    registre_ok, registre_clos = lire_registre(cadrage_donnees)
    if not registre_ok:
        return ("indéterminé", "registre-invalide", meta, [])
    # Φ4
    if not registre_clos:
        nom = _nom_premier_fichier_execution(entrees, a_plans_dir)
        if nom is not None:
            return ("indéterminé", "avant-cadrage-clos:" + nom, meta, [])
        return ("en cadrage", None, meta, [])
    # Φ5
    plan_present = "PLAN.md" in entrees
    if plan_present and a_plans_dir:
        return ("indéterminé", "plan-direct-et-plans", meta, [])
    if a_plans_dir:
        nom = next((n for n in ("CLOTURE.md", "VERDICT.md", "SUMMARY.md") if n in entrees), None)
        if nom is not None:
            return ("indéterminé", "fichier-de-plan-au-niveau-phase:" + nom, meta, [])
        return _agreger_plans(phase, racine_lab, cache_ctx)
    etat, raison_feuille, meta_feuille = _deriver_feuille_cache(phase, racine_lab, cache_ctx)
    return (etat, raison_feuille, meta_feuille, [])


def deriver_cycle(cycle, racine_lab, cache_ctx=None):
    chemin = cycle["chemin_rel"]
    if not cycle["cycle_md"]:
        return {"nom": cycle["nom"], "chemin": chemin, "etat": "indéterminé", "raison": "CYCLE.md-absent",
                "phase_courante": None, "phases": []}
    phases_derivees = []
    for phase in cycle["phases"]:
        etat, raison, meta, plans = deriver_phase(phase, racine_lab, cache_ctx)
        phases_derivees.append({
            "nom": phase["nom"], "chemin": phase["chemin_rel"], "etat": etat, "raison": raison,
            "auteur": meta["auteur"], "tentative": meta["tentative"], "hash_juge": meta["hash_juge"],
            "type_derivation": meta.get("type_derivation"),
            "plans": plans,
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
        return {"nom": cycle["nom"], "chemin": chemin, "etat": courante["etat"], "raison": _raison_a_juger(courante),
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


def _unites_journalisables(derivation):
    """Une ligne s'ajoute quand le recalcul OBSERVE l'entrée d'une phase ou d'un plan en `close`
    (ou en état de dérogation : `abandonné`, `remplacé`, `gelé`) — P44-D-11."""
    resultat = []
    for cycle in derivation["cycles"]:
        for phase in cycle["phases"]:
            if phase["etat"] in JOURNALISABLES:
                resultat.append(phase)
            for plan in phase.get("plans", []):
                if plan["etat"] in JOURNALISABLES:
                    resultat.append(plan)
    return resultat


def _verdict_journal(unite):
    """Le verdict de la ligne de cloture.log — `passé` pour une feuille close, `plans-clos` pour
    une phase à plans close, `plans-abandonnes` pour une phase à plans abandonné, ou le nom de la
    dérogation (`abandonné`, `remplacé`, `gelé`) sinon (44-02 § Agrégation)."""
    etat = unite["etat"]
    type_derivation = unite.get("type_derivation")
    if etat == "close":
        return "plans-clos" if type_derivation == "plans-agregation" else "passé"
    if etat == "abandonné" and type_derivation == "plans-agregation":
        return "plans-abandonnes"
    if etat in ("abandonné", "remplacé", "gelé"):
        return etat
    return None


def lignes_a_journaliser(derivation, lignes_existantes):
    """Dédoublonnage lu dans le journal lui-même (dernier couple verdict/tentative par chemin),
    jamais dans un cache. La comparaison porte sur la valeur ASSAINIE (celle qui est, ou serait,
    effectivement écrite) des DEUX côtés : le journal relu ne contient que des jetons déjà passés
    par `_jeton_journal`, donc comparer la valeur BRUTE de l'unité courante à ce jeton assaini
    rejournalise à chaque exécution dès qu'un champ (notamment `tentative`, lu tel quel depuis
    VERDICT.md, jamais validé — P44-D-09) contient un espace ou un `=` (audit, lot 3 constat 1)."""
    dernier_couple = {}
    for ligne in lignes_existantes:
        parsee = _parser_ligne_journal(ligne)
        if parsee is not None:
            dernier_couple[parsee["chemin"]] = (parsee["verdict"], parsee["tentative"])
    a_ajouter = []
    for unite in _unites_journalisables(derivation):
        chemin = unite["chemin"]
        verdict = _verdict_journal(unite)
        if verdict is None:
            continue
        if verdict == "passé":
            brute = unite.get("tentative")
            tentative = str(brute) if brute not in (None, "") else "-"
        else:
            tentative = "-"
        chemin_jeton = _jeton_journal(chemin, "-")
        couple_jeton = (_jeton_journal(verdict, "-"), _jeton_journal(tentative, "-"))
        if dernier_couple.get(chemin_jeton) != couple_jeton:
            a_ajouter.append({
                "chemin": chemin, "auteur": unite.get("auteur") or "inconnu",
                "verdict": verdict, "tentative": tentative,
            })
    a_ajouter.sort(key=lambda u: u["chemin"])
    return a_ajouter


def _jeton_journal(valeur, repli):
    """Encode une valeur arbitraire (P44-D-09 : lue, jamais validée — aucun contrôle de SENS) en
    UN jeton structurellement sûr pour une ligne de `cloture.log`, par un échappement pourcent
    INJECTIF (lot 4, correction de classe — remplace l'ancien assainissement par `_`, qui
    écrasait `"3 4"` et `"3_4"` sur le même jeton et pouvait donc faire manquer une clôture
    réellement nouvelle au dédoublonnage, P44-D-11 ; alphabet étendu F44-05/F7 : tout caractère
    NON IMPRIMABLE — `not str.isprintable()`, qui couvre NUL et les contrôles C0/C1, en plus des
    séparateurs Unicode déjà couverts par `isspace()` — était encore laissé passer BRUT, ce qui
    aurait permis d'injecter un octet de contrôle littéral dans `cloture.log`) : tout caractère
    considéré comme un espace par Python (`str.isspace()` — couvre U+2028 LIGNE SÉPARATRICE,
    U+0085 NEL et tout espace Unicode, pas seulement l'ASCII), tout caractère NON IMPRIMABLE
    (`not str.isprintable()` — NUL, contrôles C0/C1, séparateurs Unicode restants), tout `=` (qui
    ouvrirait une séquence `clé=` lisible par `LIGNE_JOURNAL_RE`), et le caractère d'échappement
    `%` lui-même, sont réécrits en `%XX` — deux chiffres hexadécimaux majuscules par OCTET de son
    encodage UTF-8 (un caractère multi-octets produit plusieurs `%XX` consécutifs, jamais un seul
    jeton non réversible). Le jeton résultant ne contient donc plus jamais d'espace, de saut de
    ligne, de `=`, ni d'octet de contrôle brut : deux valeurs distinctes produisent TOUJOURS deux
    jetons distincts (réversible par simple décodage pourcent).

    F5 (correction ciblée) : `return jeton or repli` laissait un jeton vide filer si `repli`
    lui-même était vide (repli vide -> `jeton or repli` retombe sur `""`), produisant une ligne
    que `LIGNE_JOURNAL_RE` (`\\S+` sur chaque champ) ne relirait plus jamais — une corruption
    SILENCIEUSE du journal. `repli` est un contrat interne, toujours un littéral non vide chez
    tous les appelants actuels (`"-"`, `"inconnu"`) : une erreur BRUYANTE immédiate (jamais une
    ligne illisible produite en silence) si ce contrat est un jour rompu. Une fois `repli` garanti
    non vide, `brute` (str) contient au moins un caractère, et chaque caractère produit au moins
    un caractère de sortie (lui-même, ou au moins un `%XX`) : `jeton` est donc TOUJOURS non vide,
    sans repli de dernier recours nécessaire.

    IN-02 (revue, correction ciblée) : l'invariant final est vérifié par une exception EXPLICITE,
    jamais un `assert` nu — un `assert` est désactivable en bloc par `python -O`/`PYTHONOPTIMIZE`,
    et ce moteur ne garantit nulle part que son interpréteur tourne sans cette option. Une garde de
    P44-D-11 (jamais de ligne illisible produite en silence dans `cloture.log`) reste active quel
    que soit le mode d'exécution."""
    if not repli:
        raise ValueError("_jeton_journal : 'repli' doit toujours être non vide (contrat interne)")
    brute = valeur if valeur not in (None, "") else repli
    morceaux = []
    for caractere in str(brute):
        if caractere == "%" or caractere == "=" or caractere.isspace() or not caractere.isprintable():
            for octet in caractere.encode("utf-8"):
                morceaux.append("%{:02X}".format(octet))
        else:
            morceaux.append(caractere)
    jeton = "".join(morceaux)
    if not jeton:
        raise AssertionError("_jeton_journal : jeton vide malgré un repli non vide (invariant violé)")
    return jeton


def _formater_ligne_journal(horodatage, unite):
    chemin = _jeton_journal(unite["chemin"], "-")
    auteur = _jeton_journal(unite["auteur"], "inconnu")
    verdict = _jeton_journal(unite["verdict"], "-")
    tentative = _jeton_journal(unite["tentative"], "-")
    return "{}  {}  {}  verdict={}  tentative={}  date=observation".format(
        horodatage, chemin, auteur, verdict, tentative,
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
    if cycle["etat"] == "à juger" and cycle["raison"] == "verdict-perime":
        return "à juger — " + libelle_raison(cycle["raison"])
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
        for entree in hors_modele:  # déjà triée par classer_entrees
            lignes.append("- `" + echapper_nom(entree["chemin"]) + "` (" + entree["type"] + ")")
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
    même dossier + os.replace (jamais un save() non atomique). Un emplacement existant qui n'est
    PAS un fichier régulier (lien symbolique compris — 44-04, R56) n'est jamais comparé à travers
    lui : il compte comme différent, et `os.replace` le remplace par un fichier régulier — jamais
    une écriture qui traverserait un lien en silence. F44-06 (correction ciblée) : la lecture de
    l'existant se faisait par `open()` nu, seul site des lectures du modèle sans `O_NOFOLLOW` —
    alignée ici sur le patron du reste du fichier (`os.open(..., O_RDONLY | O_NOFOLLOW)`, ELOOP
    comptant comme un échec de lecture, comme `_lire_frontmatter_fichier`)."""
    octets = contenu.encode("utf-8")
    existant = None
    if est_fichier_regulier(chemin):
        try:
            descripteur_existant = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
            with os.fdopen(descripteur_existant, "rb") as fh:
                existant = fh.read()
        except OSError:
            existant = None
    if existant == octets:
        return False
    dossier = os.path.dirname(chemin) or "."
    fd_tmp, chemin_tmp = tempfile.mkstemp(dir=dossier, prefix=".tmp-recalc-")
    fd_non_adopte = True  # tant que os.fdopen n'a pas pris possession du descripteur (F5)
    try:
        os.fchmod(fd_tmp, 0o644)
        with os.fdopen(fd_tmp, "wb") as fh:
            fd_non_adopte = False
            fh.write(octets)
        os.replace(chemin_tmp, chemin)
    except Exception:
        if fd_non_adopte:
            try:
                os.close(fd_tmp)
            except OSError:
                pass
        try:
            os.remove(chemin_tmp)
        except OSError:
            pass
        raise
    return True


# --- Archivage du socle v2 à la première écriture sous migration (P45-D-02, F10) ---------------
SEGMENTS_ARCHIVE_SOCLE_V2 = ("_archive", "socle-v2")
NOMS_ARCHIVE_SOCLE_V2 = ("STATE.md", "INDEX.md")
NOM_ARCHIVE_SOCLE_V2 = re.compile(r"^socle-v2(?:\.([0-9]+))?$")
MARQUEUR_INDEX_GENERE = "Généré par recalc-planning.sh, ne se rédige pas (P44-D-10).".encode("utf-8")


def gardes_ecriture_prealables(planning):
    """Gardes d'écriture de `appliquer_ecritures` (planning en lien, journal inaccessible, emplacement du modèle occupé par
    autre chose qu'un fichier régulier), jouées AVANT l'archivage du socle v2 (quick 45-B, M3, décisions du manager
    vf-dev-manager, 2026-10-01) : un refus d'écriture ne laisse plus d'archive orpheline. Mêmes messages que
    `appliquer_ecritures`, qui rejoue ces gardes après l'archivage. Rend 0 (admis) ou 1 (refus, rien écrit)."""
    try:
        planning_est_lien = stat.S_ISLNK(os.lstat(planning).st_mode)
    except OSError:
        planning_est_lien = False
    if planning_est_lien:
        print("[recalc-planning] dossier de planning en lien symbolique : " + planning, file=sys.stderr)
        return 1
    _lignes, statut_journal = lire_journal(planning)
    if statut_journal in ("lien", "illisible"):
        print("[recalc-planning] journal des clôtures inaccessible en écriture (statut=" + statut_journal + ")", file=sys.stderr)
        return 1
    for nom_cible in ("INDEX.md", "STATE.md", "cloture.log", ".recalc-cache.json"):
        chemin_cible = os.path.join(planning, nom_cible)
        if not os.path.lexists(chemin_cible):
            continue
        if not est_fichier_regulier(chemin_cible):
            print("[recalc-planning] emplacement occupé par autre chose qu'un fichier régulier : " + chemin_cible, file=sys.stderr)
            return 1
    return 0


def _est_genere(nom, octets):
    """Vrai si `octets` porte la marque de génération de recalc-planning (STATE.md : `genere_par: recalc-planning` en tête du
    frontmatter ; INDEX.md : la ligne « Généré par recalc-planning.sh… » en troisième ligne). Un fichier généré se reproduit,
    il n'est pas du contenu rédigé à la main : le ré-archiver à chaque passage empilerait des instantanés."""
    lignes = octets.split(b"\n")
    if nom == "STATE.md":
        return len(lignes) > 1 and lignes[0].rstrip(b"\r") == b"---" and lignes[1].rstrip(b"\r") == b"genere_par: recalc-planning"
    return len(lignes) > 2 and lignes[2].rstrip(b"\r") == MARQUEUR_INDEX_GENERE


def _archive_contient(dossier, sources):
    """Vrai si `dossier` porte, pour CHAQUE source, un fichier régulier (lu sans suivre de lien) aux mêmes octets."""
    for nom, octets in sources:
        chemin = os.path.join(dossier, nom)
        if not est_fichier_regulier(chemin):
            return False
        try:
            descripteur = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
            with os.fdopen(descripteur, "rb") as fh:
                if fh.read() != octets:
                    return False
        except OSError:
            return False
    return True


def _nom_archive_libre(existants):
    """`socle-v2` s'il est libre, sinon `socle-v2.N` avec N = plus grand suffixe existant + 1 (au moins 2)."""
    if SEGMENTS_ARCHIVE_SOCLE_V2[1] not in existants:
        return SEGMENTS_ARCHIVE_SOCLE_V2[1]
    plus_grand = 1
    for nom in existants:
        m = NOM_ARCHIVE_SOCLE_V2.match(nom)
        if m and m.group(1):
            plus_grand = max(plus_grand, int(m.group(1)))
    return SEGMENTS_ARCHIVE_SOCLE_V2[1] + "." + str(plus_grand + 1)


def archiver_socle_v2(planning):
    """Sous verdict `migration` SEULEMENT (F10, f10-archive — Willy, AskUserQuestion session
    principale, 2026-09-30 : « aucun contenu perdu »), APRÈS les gardes d'écriture et AVANT
    `appliquer_ecritures` : copie octet pour octet du STATE.md et de l'INDEX.md du socle v2 (fichiers
    réguliers, lus par O_NOFOLLOW, de contenu RÉDIGÉ À LA MAIN : un fichier qui porte la marque de
    génération de recalc-planning se reproduit et n'est pas archivé) sous `.planning/_archive/`.
    `_archive` est un emplacement annexe de la 44, jamais lu par le recalcul. Contenu rédigé à la
    main, remplacé sans sauvegarde sinon (ADR-031). Règles (quick 45-B, M3, décisions du manager
    vf-dev-manager, 2026-10-01, renversables) :
      - une archive existante n'est JAMAIS réécrite ; si une archive existante porte déjà tous les
        fichiers à archiver aux mêmes octets, il n'y a rien à faire (code 0) ; sinon une NOUVELLE
        archive est posée sous un nom libre (`socle-v2`, puis `socle-v2.2`, `socle-v2.3`, …) — une
        archive incomplète (demi-archive) ou de contenu différent ne fait jamais sauter l'archivage ;
      - tout ou rien : les fichiers sont écrits dans un dossier provisoire `_archive/.tmp-socle-v2-*`,
        puis le dossier est renommé en une fois ; en cas d'échec rien ne reste, et l'appelant ne
        remplace ni STATE.md ni INDEX.md (sortie 1) ;
      - `_archive` ou une archive nommée existant mais qui n'est pas un dossier réel (lien compris) :
        sortie 1, rien écrit.
    Rend 0 (archivé, déjà archivé ou rien à archiver) ou 1 (emplacement inutilisable)."""
    try:
        if stat.S_ISLNK(os.lstat(planning).st_mode):
            return 0  # `appliquer_ecritures` refuse ce cas (sortie 1) : rien à archiver ici
    except OSError:
        return 0
    sources = []
    for nom in NOMS_ARCHIVE_SOCLE_V2:
        chemin_source = os.path.join(planning, nom)
        if not est_fichier_regulier(chemin_source):
            continue
        descripteur = os.open(chemin_source, os.O_RDONLY | SANS_SUIVI_DE_LIEN)
        with os.fdopen(descripteur, "rb") as fh:
            octets_source = fh.read()
        if _est_genere(nom, octets_source):  # archive-genere
            continue
        sources.append((nom, octets_source))
    if not sources:
        return 0
    parent = os.path.join(planning, SEGMENTS_ARCHIVE_SOCLE_V2[0])
    existants = []
    try:
        info = os.lstat(parent)
    except FileNotFoundError:
        info = None
    if info is not None:
        if not stat.S_ISDIR(info.st_mode):  # lstat : un lien symbolique n'est pas un dossier réel
            print(
                "[recalc-planning] archivage du socle v2 impossible (P45-D-02, F10) : "
                + parent + " existe et n'est pas un dossier réel — rien n'est écrit",
                file=sys.stderr,
            )
            return 1
        for nom in sorted(os.listdir(parent)):
            if not NOM_ARCHIVE_SOCLE_V2.match(nom):
                continue
            if not stat.S_ISDIR(os.lstat(os.path.join(parent, nom)).st_mode):
                print(
                    "[recalc-planning] archivage du socle v2 impossible (P45-D-02, F10) : "
                    + os.path.join(parent, nom) + " existe et n'est pas un dossier réel — rien n'est écrit",
                    file=sys.stderr,
                )
                return 1
            existants.append(nom)
    for nom in existants:
        if _archive_contient(os.path.join(parent, nom), sources):  # archive-deja
            print(
                "[recalc-planning] socle v2 déjà archivé sous " + os.path.join(parent, nom)
                + " — jamais réécrit (P45-D-02, F10)",
                file=sys.stderr,
            )
            return 0
    if info is None:
        os.mkdir(parent)
        os.chmod(parent, 0o755)
    destination = os.path.join(parent, _nom_archive_libre(existants))  # archive-destination
    provisoire = tempfile.mkdtemp(dir=parent, prefix=".tmp-socle-v2-")
    try:
        for nom, octets in sources:
            chemin_archive = os.path.join(provisoire, nom)
            with open(chemin_archive, "xb") as fh:
                fh.write(octets)
            os.chmod(chemin_archive, 0o644)
        os.chmod(provisoire, 0o755)
        os.rename(provisoire, destination)  # archive-rename
    except BaseException:
        try:
            for nom_residuel in os.listdir(provisoire):
                os.remove(os.path.join(provisoire, nom_residuel))
            os.rmdir(provisoire)
        except OSError:
            pass
        raise
    print(
        "[recalc-planning] migration (P45-D-02) : " + ", ".join(nom for nom, _ in sources)
        + " du socle v2 archivé(s) sous " + destination + " avant remplacement",
        file=sys.stderr,
    )
    return 0


def appliquer_ecritures(planning, racine_lab, derivation, cache_ctx, statut_cache):
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
    for nom_cible in ("INDEX.md", "STATE.md", "cloture.log", ".recalc-cache.json"):
        chemin_cible = os.path.join(planning, nom_cible)
        # `est_fichier_regulier` (lstat + S_ISREG, jamais de suivi de lien) — PAS `os.path.isfile`
        # (traverse un lien symbolique) : un lien à cet emplacement, même pointant vers un fichier
        # régulier existant hors de `.planning/`, est refusé plutôt que remplacé en silence (F4).
        if os.path.lexists(chemin_cible) and not est_fichier_regulier(chemin_cible):
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
    nouveau_cache_texte = json.dumps(
        {
            "cache_schema_version": CACHE_SCHEMA_VERSION,
            "moteur": "recalc-planning",
            "unites": cache_ctx["nouveau"],
        },
        sort_keys=True, ensure_ascii=False,
    )
    if ecrire_si_different(os.path.join(planning, ".recalc-cache.json"), nouveau_cache_texte):
        ecrits.append(".recalc-cache.json")
    unites = sum(len(c["phases"]) for c in derivation["cycles"])
    rapport = {
        "moteur": "recalc-planning",
        "mode": "ecriture",
        "ecrits": sorted(ecrits),
        "cloture_ajouts": len(nouvelles_lignes),
        "unites": unites,
        "cache": statut_cache,
        "unites_recalculees": cache_ctx["recalculees"],
        "unites_reprises": cache_ctx["reprises"],
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

    if mode_lecture_seule:
        # Le cache n'est JAMAIS consulté ni écrit en lecture seule (T-44-21, P44-D-02a) : la
        # dérivation ci-dessous n'a aucune connaissance du cache (cache_ctx=None par défaut).
        cycles_derives = sorted(
            (deriver_cycle(c, racine_lab) for c in modele["cycles"]),
            key=lambda c: c["chemin"],  # tri, lecture seule
        )
        derivation = {"cycles": cycles_derives, "hors_modele": modele["hors_modele"]}
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
    # P45-D-02 : `migration` (détecteur à 2) est admis ICI, l'adhésion ayant déjà été exigée
    # ci-dessus ; `gsd` et `non-concluante` (garde de lecture, code 1, repli) restent des refus.
    if verdict_gsd not in ("non-gsd", "migration"):
        print(
            "[recalc-planning] refus d'écriture (P44-D-02a) : ce planning est tenu par le moteur "
            "GSD, ou sa détection n'est pas concluante — le recalcul n'écrit jamais dans ce cas",
            file=sys.stderr,
        )
        sys.exit(3)

    # Cache chargé et consulté UNIQUEMENT ici — après les deux refus (P44-D-02, P44-D-02a), sur
    # le chemin d'écriture garanti (44-04, T-44-21).
    statut_cache, donnees_cache = charger_cache(planning_abs)
    cache_existant = donnees_cache.get("unites") if statut_cache == "valide" else {}
    if not isinstance(cache_existant, dict):
        cache_existant = {}
    cache_ctx = {"existant": cache_existant, "nouveau": {}, "recalculees": 0, "reprises": 0}
    cycles_derives = sorted(
        (deriver_cycle(c, racine_lab, cache_ctx) for c in modele["cycles"]),
        key=lambda c: c["chemin"],  # tri, écriture
    )
    derivation = {"cycles": cycles_derives, "hors_modele": modele["hors_modele"]}

    if verdict_gsd == "migration":
        # F10 (P45-D-02) : le STATE.md/INDEX.md du socle v2 sont archivés AVANT d'être remplacés, et APRÈS les gardes
        # d'écriture (quick 45-B, M3) : un refus d'écriture ne laisse pas d'archive orpheline.
        code_prealable = gardes_ecriture_prealables(planning_abs)  # archive-prealables
        if code_prealable != 0:
            sys.exit(code_prealable)
        try:
            code_archive = archiver_socle_v2(planning_abs)
        except OSError as exc:
            print("[recalc-planning] échec d'archivage du socle v2 : " + str(exc), file=sys.stderr)
            sys.exit(1)
        if code_archive != 0:
            sys.exit(code_archive)

    try:
        code, rapport = appliquer_ecritures(planning_abs, racine_lab, derivation, cache_ctx, statut_cache)
    except OSError as exc:
        # Filet de sécurité (44-04, Rule 2) : une erreur d'entrée-sortie inattendue au-delà des
        # gardes déjà posées (ex. un emplacement occupé contourné) ne doit jamais remonter comme
        # une trace Python brute — toujours un message métier et un code de sortie du contrat.
        print("[recalc-planning] échec d'écriture inattendu : " + str(exc), file=sys.stderr)
        sys.exit(1)
    if code != 0:
        sys.exit(code)
    print(json.dumps(rapport, sort_keys=True, indent=2, ensure_ascii=False))
    sys.exit(0)


main()
PY_RECALC_PLANNING_EOF
