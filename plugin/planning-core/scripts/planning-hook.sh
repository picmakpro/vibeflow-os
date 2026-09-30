#!/usr/bin/env bash
# planning-hook.sh — hook central PreToolUse de planning-core (Phase 45, P45-D-15 : UN SEUL script
# pour les gates d'écriture et le cloisonnement par rôle). Il n'agit que dans un lab adhérent
# `cycles-v1` (P45-D-01a) ; ailleurs — labs dev, ce dépôt compris — il ne sort RIEN et rend 0
# (P45-D-04). La racine du lab est dérivée du chemin écrit (à défaut du cwd du payload, à défaut du
# cwd physique du processus), jamais de $CLAUDE_PROJECT_DIR (P45-D-12).
#
# Entrée : le payload JSON du harnais sur stdin. Sortie : rien, ou UN objet JSON hookSpecificOutput
# (refus : permissionDecision deny ; avertissement : additionalContext), toujours code 0 — jamais
# exit 2 (P45-D-08, DIV-2).
#
# Contrat des codes du LANCEUR (bash) — il ne décide de RIEN : tout code non nul est repris par la
# commande enregistrée dans hooks.json, qui tranche elle-même (fail-closed dans un lab adhérent,
# silence ailleurs — P45-D-06, P45-D-06a) :
#    0  décidé (stdout vide ou UN objet JSON)
#    3  erreur Python AVANT que l'adhésion soit connue (stdout vide)
#   70  mktemp impossible
#   71  lecture de stdin impossible
#   72  aucun interpréteur Python (python3 puis python, ADR-054)
#
# Livraison — voie (a) de P44-D-14 : le cœur Python est embarqué en heredoc quoté (patron
# recalc-planning.sh) ; l'installeur ne pose pas de fichier .py. Le programme passe par stdin, le
# payload par un fichier de transport mktemp (0600, supprimé par un trap), jamais par argv.
#
# Aucune variable d'environnement ne change l'armement ni l'adhésion (P45-D-12a) : le lanceur lit
# TMPDIR pour choisir où poser son fichier de transport (un chemin, jamais une décision).
set -u

T="$(mktemp "${TMPDIR:-/tmp}/vf-planning-hook.XXXXXX")" || exit 70
trap 'rm -f "$T"' EXIT
cat > "$T" || exit 71

# Résolution de l'interpréteur (ADR-054) : stub Microsoft Store détecté par chemin, repli python.
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then
      PYBIN=python
    else
      exit 72
    fi
    ;;
esac

"$PYBIN" -I -S - "$T" <<'PY_PLANNING_HOOK_EOF'
import json
import os
import stat
import sys

# --- Constantes du contrat -----------------------------------------------------------------
SCHEMA_ADHESION = "cycles-v1"
SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)


# --- Lecture du payload et dérivation du lab ------------------------------------------------
def _premier_gagne(paires):
    """Clé en double : la PREMIÈRE occurrence gagne, comme la couche shell de la commande
    enregistrée (elle garde la première correspondance de chaque clé)."""
    resultat = {}
    for cle, valeur in paires:
        if cle not in resultat:
            resultat[cle] = valeur
    return resultat


def lire_payload(chemin):
    """Lit le payload du fichier de transport. Octets invalides : remplacés (jamais une exception
    pour un contenu que le harnais a déjà accepté)."""
    with open(chemin, "rb") as fh:
        octets = fh.read()
    texte = octets.decode("utf-8", "replace")
    payload = json.loads(texte, object_pairs_hook=_premier_gagne)
    if not isinstance(payload, dict):
        raise ValueError("payload non objet")
    return payload


def cible_de(payload):
    """(chemin écrit absolu ou None, cwd du payload ou None). Clé `file_path`, sinon
    `notebook_path`, dans `tool_input`. Un chemin relatif est JOINT au cwd du payload (à défaut au
    cwd physique du processus), comme la couche shell (limite h) : les deux couches rattachent
    le chemin au même lab."""
    cwd = payload.get("cwd")
    if not isinstance(cwd, str):
        cwd = None
    entree = payload.get("tool_input")
    ecrit = None
    if isinstance(entree, dict):
        for cle in ("file_path", "notebook_path"):
            valeur = entree.get(cle)
            if isinstance(valeur, str):
                ecrit = valeur
                break
    if ecrit is not None and not ecrit.startswith("/"):
        base = cwd if cwd is not None else os.path.realpath(os.getcwd())
        ecrit = base + "/" + ecrit
    return (ecrit, cwd)


def _partie_existante(chemin):
    """Plus proche ancêtre EXISTANT (dossier) du chemin, résolu physiquement (liens suivis sur la
    partie existante)."""
    courant = os.path.realpath(chemin)
    while not os.path.isdir(courant):
        parent = os.path.dirname(courant)
        if parent == courant:
            break
        courant = parent
    return courant


def racine_lab(depart):
    """Racine physique du lab : le PLUS PROCHE ancêtre qui contient un DOSSIER `.planning` (le
    plus proche gagne, P45-D-01a/P45-D-12), ou None. Un départ non absolu n'a pas de lab."""
    if not isinstance(depart, str) or not depart.startswith("/"):
        return None
    courant = _partie_existante(depart)
    while True:
        if os.path.isdir(os.path.join(courant, ".planning")):
            return courant
        parent = os.path.dirname(courant)
        if parent == courant:
            return None
        courant = parent


# --- Adhésion (même lecture que le moteur de recalcul, P44-D-02) ------------------------------
def est_fichier_regulier(chemin):
    """lstat + S_ISREG, jamais de suivi de lien."""
    try:
        return stat.S_ISREG(os.lstat(chemin).st_mode)
    except OSError:
        return False


def verifier_adhesion(planning):
    """Sans config.json déclarant EXACTEMENT "planning_version": "cycles-v1", le planning n'a pas
    adhéré : fichier absent ou non régulier, JSON invalide, racine non objet, clé absente, autre
    valeur, valeur non chaîne sont TOUS non adhérents."""
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


# --- Sorties : UN objet JSON par exécution, jamais systemMessage (DIV-3) ----------------------
def _emettre(objet):
    texte = json.dumps(objet, ensure_ascii=False) + "\n"
    sys.stdout.buffer.write(texte.encode("utf-8"))
    sys.stdout.buffer.flush()


def sortie_refus(raisons):
    _emettre({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "\n".join(raisons),
    }})


def sortie_contexte(textes):
    _emettre({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": "\n".join(textes),
    }})


# --- Évaluation des gates (Phase B) ----------------------------------------------------------
def evaluer_gates(contexte):
    """Liste de résultats (genre, texte), genre `refuse` ou `avertit`. Aucun gate n'est encore
    branché dans ce socle."""
    return []


def main():
    # Phase A : l'adhésion n'est pas encore connue. Toute erreur sort sur un code non nul SANS rien
    # imprimer : la couche shell de la commande enregistrée tranche (P45-D-08, DIV-2).
    try:
        payload = lire_payload(sys.argv[1])  # phase-a
        ecrit, cwd = cible_de(payload)
        depart = ecrit if ecrit is not None else (cwd if cwd is not None else os.getcwd())
        racine = racine_lab(depart)
        adherent = racine is not None and verifier_adhesion(os.path.join(racine, ".planning"))["adherente"]
    except BaseException:
        sys.exit(3)  # phase-a-sortie
    if not adherent:
        sys.exit(0)  # non-adherent
    # Phase B : le lab est adhérent. Toute erreur devient un refus explicite, code 0 (P45-D-08).
    try:
        contexte = {"payload": payload, "outil": payload.get("tool_name"), "ecrit": ecrit,
                    "cwd": cwd, "racine": racine}
        resultats = evaluer_gates(contexte)  # phase-b
        refus = [texte for genre, texte in resultats if genre == "refuse"]
        avis = [texte for genre, texte in resultats if genre == "avertit"]
        if refus:
            sortie_refus(refus)
        elif avis:
            sortie_contexte(avis)
    except BaseException as exc:
        sortie_refus(["[planning-core] erreur interne du hook central dans un lab adhérent "
                      "cycles-v1 : action refusée (P45-D-08) — " + type(exc).__name__])
    sys.exit(0)


if __name__ == "__main__":
    main()
PY_PLANNING_HOOK_EOF
