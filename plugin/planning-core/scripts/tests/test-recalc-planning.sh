#!/usr/bin/env bash
# test-recalc-planning.sh — Suite du traceur du moteur de recalcul d'état (Phase 44, plan 44-01).
#
# Tâche 1 (tracer) — R01 à R04 :
#   R01 — coureur du banc : matérialise chaque lab du banc, lance --read-only, exige code 0 puis
#         compare chaque `@@ attendu` au JSON rendu (une ligne `✓ BANC <lab> <unité> : <état>`
#         par unité comparée).
#   R02 — écriture sur une copie du lab `traceur` : code 0, INDEX.md/STATE.md/cloture.log créés,
#         contenu conforme au contrat (P44-D-10, P44-D-11).
#   R03 — second recalcul sur le même disque : rapport `ecrits` vide, `cloture_ajouts` 0, les
#         trois fichiers identiques octet pour octet au premier passage (P44-D-10).
#   R04 — copie sans config.json : code 2, message qui cite `"planning_version": "cycles-v1"`,
#         empreinte identique avant/après (P44-D-02).
#
# Tâche 2 (TDD) — R05 à R14, douze mutants de garde, trois gardes du harnais :
#   R05 — trois variantes non adhérentes (2.0, nombre 3, JSON illisible) → code 2 chacune.
#   R06 — --read-only sur copie sans config.json : code 0, adhesion.adherente faux.
#   R07 — --read-only sur lab adhérent : empreinte identique, aucun sous-processus détecteur lancé.
#   R08 — lab adhérent + STATE.md gsd_state_version → code 3 ; jumeau sans la clé → code 0.
#   R09 — détecteur absent / sorti 64 / remplacé par un dossier → code 3 chacun, dernier cas avec
#         la mention « détecteur non régulier » sur stderr.
#   R10 — cloture.log pré-rempli : préfixe intact, une ligne ajoutée.
#   R11 — cloture.log en lien symbolique : code 1, cible inchangée.
#   R12 — drapeau de traçage à false dans config.json : JSON --read-only identique (P44-D-05).
#   R13 — GSD_HOME inexistant (détecteur rend 1) : (a) STATE.md racine avec la clé → code 3 ;
#         (b) jumeau négatif sans la clé → code 0 ; (c) partition (compartiment porte la clé,
#         racine ne la porte pas) → code 3.
#   R14 — umask 0077 : INDEX.md/STATE.md/cloture.log portent 0o644 malgré le umask.
#   MUT-ADHESION, MUT-LECTURE-SEULE, MUT-GSD, MUT-GSD-FERME, MUT-GSD-IRREGULIER, MUT-AJOUT,
#   MUT-DEDOUBLONNAGE, MUT-NOFOLLOW, MUT-CHMOD, MUT-CHMOD-JOURNAL — chacun mute une ligne à motif
#   unique de recalc-planning.sh, chacun prouvé par une trace assertion/attendu (original)/obtenu
#   (mutant).
#
# Lot 3 (correction ciblée, décision du head sous délégation technique de Willy, session
# principale, 2026-09-28) :
#   R-DEDOUBLONNAGE-ASSAINI — round-trip réel (2 exécutions) : `tentative` piégée (espaces + `=`)
#         → une seule ligne dans cloture.log, `cloture_ajouts` 0 au 2e recalcul (revue, constat 1).
#   MUT-DEDOUBLONNAGE-BRUT — comparaison repliée sur la valeur brute au lieu du jeton assaini.
#   [Phase 45, 45-02 GATE-14 : le refus ci-dessous est LEVÉ sous adhésion — code 0 IDENTIQUE dans
#   les deux cas ; le refus subsiste sans adhésion (R-GATE14-A) et sous moteur GSD actif (R-GATE14-B).]
#   R-GSD-HOME-SIGNAL — (a) environnement normal et (b) GSD_HOME inexistant sur un socle
#         planning-core + signal de code : verdict IDENTIQUE dans les deux cas, empreinte
#         inchangée (audit, constat 2).
#
#   MUT-SYNTAXE, MUT-REFUS-COMPTE, MUT-PLANTAGE — gardes du harnais lui-même (patron
#   test-check-skills.sh).
#
# Lot 4 (correction de CLASSE, décision du head sous délégation technique de Willy, session
# principale, 2026-09-28) — la détection GSD n'est plus réimplémentée en Python (trois copies
# mesurées divergentes au lot 3, ce qui a motivé ce lot) : le moteur appelle désormais le VRAI
# détecteur bash, dans un environnement MAÎTRISÉ (GSD_HOME toujours existant), et REFUSE d'écrire
# sur tout code de sortie hors {0, 2, 3} (fail-closed) :
#   R-DETECTEUR-LIEN, R-DETECTEUR-ILLISIBLE, R-DETECTEUR-CODE1-INATTENDU — détecteur en lien
#         symbolique / chmod 000 / factice sorti en 1 → refus (code 3), empreinte inchangée.
#   R-ORACLE-DIFFERENTIEL — sur cinq scénarios (terrain libre, marqueur racine, marqueur de
#         compartiment, partition, socle+signal), le verdict du moteur correspond TOUJOURS à celui
#         du vrai détecteur lancé directement avec un GSD_HOME valide.
#   R-MATRICE-ENV — les cinq mêmes scénarios, sous six colonnes d'environnement hérité (normal,
#         GSD_HOME inexistant/vide/piégé, CLAUDE_CONFIG_DIR vide, HOME vide) : code de sortie et
#         contenu écrit IDENTIQUES sur toutes les colonnes.
#   R-LABS-ADVERSES — les trois divergences mesurées au lot 3 (`package.json` en lien, `*.xcodeproj`
#         en lien, `STATE.md` aux octets UTF-8 invalides après le frontmatter), chacune combinée au
#         socle planning-core : refus (code 3), marqueur STATE.md intact octet pour octet.
#   R-INJECTIF-GENERATIF, R-INJECTIF-ROUNDTRIP — `_jeton_journal` encode désormais en pourcent, de
#         façon INJECTIVE (P44-D-11) : preuve générative (2000 paires, graine fixe, zéro collision,
#         round-trip pourcent) + round-trip réel à deux exécutions sur le même chemin de phase.
#   MUT-ENV-NON-MAITRISE, MUT-CODE1-NON-GSD, MUT-JOURNAL-SANITIZE (mise à jour) — chacun mute une
#         ligne à motif unique, chacun prouvé par une trace assertion/attendu (original)/obtenu
#         (mutant). MUT-CHAINE-ABSENTE, MUT-PARTITION-ABSENTE, MUT-MARQUEUR-RACINE,
#         MUT-MARQUEUR-COMPARTIMENT, MUT-PARTITION-COMPARTIMENT, MUT-CODE1-SANS-MARQUEUR et
#         MUT-CODE1-SOCLE-SIGNAL sont RETIRÉS : leur cible (la réimplémentation Python) n'existe
#         plus — R-ORACLE-DIFFERENTIEL et R-MATRICE-ENV couvrent désormais les mêmes scénarios
#         contre la source unique de vérité.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
RECALC="$SCRIPTS_DIR/recalc-planning.sh"
DETECT="$SCRIPTS_DIR/detect-gsd-engine.sh"
WORKSTREAM_POLICY="$SCRIPTS_DIR/workstream-policy.sh"
BANC="$TESTS_DIR/fixtures/recalc-planning-banc.txt"

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-recalc-planning] python3 requis" >&2; exit 1; fi
    ;;
esac

# mode_octal — lit les bits de permission d'un fichier en octal, portable GNU/BSD (R14, lot 8
# portabilité) : `stat -f`/`stat -c` divergent entre coreutils (GNU) et BSD/macOS — `stat -f` sous
# GNU désigne le système de fichiers, pas le format de sortie, et échoue silencieusement en
# empruntant au repli `stat -c` un code non lié au fichier demandé. Une seule sémantique : l'appel
# système via Python, déjà une dépendance de la suite (PYBIN).
mode_octal() { "$PYBIN" -c 'import os,sys; print(format(os.stat(sys.argv[1]).st_mode & 0o777, "o"))' "$1"; }

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
FAKE_GSD="$WORK/gsd-home"
mkdir -p "$FAKE_GSD"
# Résolu AVANT toute restriction de PATH (MUT-SOUS-PROCESSUS) — un appel par chemin absolu n'a pas
# besoin de chercher "bash" dans un PATH qu'on vient justement de vider de "bash".
BASH_BIN="$(command -v bash)"
# Instantané du script réel AVANT tout mutant (Tâche 2) — l'hygiène de fin de bloc compare contre
# CET instantané, jamais contre le fichier lui-même (qui serait trivialement identique à soi).
RECALC_SNAPSHOT="$WORK/recalc-planning-snapshot.sh"
cp "$RECALC" "$RECALC_SNAPSHOT"
# Les jetons du banc ({{sha256-plan}}, {{empreinte-livrables}}) sont résolus par la copie du bloc partagé lue dans poser-verdict.sh.
export AIDES_POSER_VERDICT="$SCRIPTS_DIR/poser-verdict.sh"

# ================================================================================================
# Aides Python (materialiser / empreinte / coureur du banc) — un seul fichier, invoqué par sous-
# processus depuis le shell, jamais réimbriqué à chaque cas (I1 : jamais en substitution de
# commande pour les aides qui doivent pouvoir échouer bruyamment).
# ================================================================================================
AIDES_PY="$WORK/aides.py"
cat > "$AIDES_PY" <<'PY_AIDES_EOF'
import hashlib
import json
import os
import stat
import subprocess
import sys


def _valider_chemin_banc(chemin):
    if chemin.startswith("/") or chemin.startswith("~"):
        raise ValueError("chemin refusé par le matérialiseur : " + chemin)
    if ".." in chemin.split("/"):
        raise ValueError("chemin refusé par le matérialiseur : " + chemin)


def parser_banc(texte):
    lignes = texte.split("\n")
    if lignes and lignes[-1] == "":
        lignes = lignes[:-1]
    labs = {}
    ordre_labs = []
    lab_courant = None
    fichier_courant = None
    contenu_courant = []

    def clore_fichier():
        if lab_courant is not None and fichier_courant is not None:
            contenu = "".join(l + "\n" for l in contenu_courant)
            if isinstance(fichier_courant, tuple) and fichier_courant[0] == "dehors":
                labs[lab_courant]["fichiers_dehors"][fichier_courant[1]] = contenu
            else:
                labs[lab_courant]["fichiers"][fichier_courant] = contenu

    for ligne in lignes:
        if ligne.startswith("@@ "):
            clore_fichier()
            fichier_courant = None
            contenu_courant = []
            directive = ligne[3:]
            if directive == "#" or directive.startswith("# "):
                continue
            if directive.startswith("lab "):
                reste = directive[len("lab "):].strip()
                morceaux_lab = reste.split()
                nom = morceaux_lab[0]
                jumeau_de = None
                for tok in morceaux_lab[1:]:
                    if tok.startswith("jumeau-de="):
                        jumeau_de = tok[len("jumeau-de="):]
                labs[nom] = {
                    "fichiers": {}, "fichiers_dehors": {}, "liens": [], "dossiers": [],
                    "attendus": [], "attendus_hors_modele": [], "attendu_hors_modele_aucun": False,
                    "jumeau_de": jumeau_de,
                }
                ordre_labs.append(nom)
                lab_courant = nom
            elif directive.startswith("dossier "):
                chemin = directive[len("dossier "):].strip()
                _valider_chemin_banc(chemin)
                labs[lab_courant]["dossiers"].append(chemin)
            elif directive.startswith("fichier-dehors "):
                chemin = directive[len("fichier-dehors "):].strip()
                _valider_chemin_banc(chemin)
                fichier_courant = ("dehors", chemin)
                contenu_courant = []
            elif directive.startswith("fichier "):
                chemin = directive[len("fichier "):].strip()
                _valider_chemin_banc(chemin)
                fichier_courant = chemin
                contenu_courant = []
            elif directive.startswith("lien "):
                reste = directive[len("lien "):].strip()
                if " -> " not in reste:
                    raise ValueError("directive @@ lien mal formée (attendu ` -> `) : " + directive)
                chemin_lien, cible = reste.split(" -> ", 1)
                chemin_lien = chemin_lien.strip()
                cible = cible.strip()
                _valider_chemin_banc(chemin_lien)
                labs[lab_courant]["liens"].append({"chemin": chemin_lien, "cible": cible})
            elif directive == "attendu-hors-modele-aucun":
                labs[lab_courant]["attendu_hors_modele_aucun"] = True
            elif directive.startswith("attendu-hors-modele "):
                reste = directive[len("attendu-hors-modele "):].strip()
                morceaux_hm = [p.strip() for p in reste.split("::")]
                chemin_hm = morceaux_hm[0]
                type_hm = morceaux_hm[1] if len(morceaux_hm) > 1 else None
                labs[lab_courant]["attendus_hors_modele"].append({"chemin": chemin_hm, "type": type_hm})
            elif directive.startswith("attendu "):
                reste = directive[len("attendu "):].strip()
                morceaux = [p.strip() for p in reste.split("::")]
                unite = morceaux[0]
                etat = morceaux[1] if len(morceaux) > 1 else None
                raison = morceaux[2] if len(morceaux) > 2 else None
                labs[lab_courant]["attendus"].append({"unite": unite, "etat": etat, "raison": raison})
            else:
                raise ValueError("directive de banc inconnue : " + directive)
        else:
            if fichier_courant is not None:
                contenu_courant.append(ligne)
    clore_fichier()
    return ordre_labs, labs


JETON_PLAN = "{{sha256-plan}}"
JETON_LIVRABLES = "{{empreinte-livrables}}"


def _corps_python(texte, marqueur):
    corps, dedans = [], False
    for ligne in texte.split("\n"):
        if ligne == marqueur:
            dedans = False
        if dedans:
            corps.append(ligne)
        if ligne.endswith("<<'" + marqueur + "'"):
            dedans = True
    return "\n".join(corps) + "\n"


def _bloc_poser_verdict():
    """Espace de noms du corps Python de poser-verdict.sh (chemin dans AIDES_POSER_VERDICT), sans l'appel final à main() : les jetons
    du banc sont résolus par la copie du bloc partagé que lit la vraie commande de pose, jamais par celle du recalcul (preuve croisée)."""
    import ast
    chemin = os.environ.get("AIDES_POSER_VERDICT")
    if not chemin or not os.path.isfile(chemin):
        raise ValueError("jeton du banc non résolu : poser-verdict.sh introuvable (AIDES_POSER_VERDICT)")
    arbre = ast.parse(_corps_python(open(chemin, encoding="utf-8").read(), "PY_POSER_VERDICT_EOF"))
    arbre.body = [n for n in arbre.body
                  if not (isinstance(n, ast.Expr) and isinstance(n.value, ast.Call) and getattr(n.value.func, "id", "") == "main")]
    ns = {"__name__": "bloc_charge_banc"}
    exec(compile(arbre, chemin, "exec"), ns)
    return ns


def resoudre_jetons(destination):
    """Résout, APRÈS l'écriture de tous les fichiers du lab, les jetons `{{sha256-plan}}` (sha256 des octets du PLAN.md voisin du
    VERDICT.md) et `{{empreinte-livrables}}` (empreinte des entrées `ecrit:` de ce PLAN.md, copie du bloc de poser-verdict.sh). Un
    jeton qui ne se résout pas (PLAN.md voisin absent, `ecrit:` illisible, livrable absent, vide ou lien) lève ValueError avec un message
    nommé : jamais une substitution vide."""
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
            raise ValueError("jeton du banc non résolu : PLAN.md voisin absent de " + rel)
        octets_plan = open(plan, "rb").read()
        if JETON_PLAN in texte:
            texte = texte.replace(JETON_PLAN, hashlib.sha256(octets_plan).hexdigest())
        if JETON_LIVRABLES in texte:
            if ns is None:
                ns = _bloc_poser_verdict()
            statut_fm, donnees = ns["lire_frontmatter"](octets_plan.decode("utf-8"))
            if statut_fm != "ok":
                raise ValueError("jeton du banc non résolu : frontmatter du PLAN.md voisin illisible (" + rel + ")")
            valeurs = ns["_valeurs_ecrit"](donnees)
            if not valeurs:
                raise ValueError("jeton du banc non résolu : ecrit: absent du PLAN.md voisin (" + rel + ")")
            statut, detail = ns["empreinte_livrables"](destination, valeurs)
            if statut != "ok":
                raise ValueError("jeton du banc non résolu : empreinte des livrables " + statut + " (" + str(detail) + ") pour " + rel)
            texte = texte.replace(JETON_LIVRABLES, detail)
        with open(chemin, "w", encoding="utf-8") as fh:
            fh.write(texte)


def materialiser(banc_path, nom_lab, destination):
    texte = open(banc_path, encoding="utf-8").read()
    ordre, labs = parser_banc(texte)
    if nom_lab not in labs:
        raise ValueError("lab absent du banc : " + nom_lab)
    lab = labs[nom_lab]
    os.makedirs(destination, exist_ok=True)
    for dossier in lab["dossiers"]:
        os.makedirs(os.path.join(destination, dossier), exist_ok=True)
    for chemin, contenu in lab["fichiers"].items():
        chemin_complet = os.path.join(destination, chemin)
        os.makedirs(os.path.dirname(chemin_complet), exist_ok=True)
        with open(chemin_complet, "w", encoding="utf-8") as fh:
            fh.write(contenu)
    # Bac à sable frère (44-04, § Interfaces) : HORS de la racine du lab, jamais dedans — sinon un
    # `@@ lien ... -> DEHORS/x` pointerait vers l'intérieur du modèle qu'il est censé fuir.
    dehors_dir = destination.rstrip("/") + "-dehors"
    if lab["fichiers_dehors"]:
        os.makedirs(dehors_dir, exist_ok=True)
        for chemin, contenu in lab["fichiers_dehors"].items():
            chemin_complet = os.path.join(dehors_dir, chemin)
            os.makedirs(os.path.dirname(chemin_complet), exist_ok=True)
            with open(chemin_complet, "w", encoding="utf-8") as fh:
                fh.write(contenu)
    for lien in lab["liens"]:
        chemin_lien = os.path.join(destination, lien["chemin"])
        os.makedirs(os.path.dirname(chemin_lien), exist_ok=True)
        cible = lien["cible"]
        if cible.startswith("DEHORS/"):
            cible_resolue = os.path.join(dehors_dir, cible[len("DEHORS/"):])
        else:
            cible_resolue = os.path.join(destination, cible)
        os.symlink(cible_resolue, chemin_lien)
    resoudre_jetons(destination)
    return lab["attendus"]


def empreinte(dossier):
    resultat = []
    for racine, dossiers, fichiers in os.walk(dossier, followlinks=False):
        dossiers.sort()
        reels = []
        for nom in dossiers:
            chemin = os.path.join(racine, nom)
            if stat.S_ISLNK(os.lstat(chemin).st_mode):
                rel = os.path.relpath(chemin, dossier)
                resultat.append(("lien", rel, os.readlink(chemin)))
            else:
                reels.append(nom)
        dossiers[:] = reels
        for nom in sorted(fichiers):
            chemin = os.path.join(racine, nom)
            rel = os.path.relpath(chemin, dossier)
            st = os.lstat(chemin)
            if stat.S_ISLNK(st.st_mode):
                resultat.append(("lien", rel, os.readlink(chemin)))
            elif stat.S_ISREG(st.st_mode):
                with open(chemin, "rb") as fh:
                    h = hashlib.sha256(fh.read()).hexdigest()
                resultat.append(("fichier", rel, h))
    resultat.sort(key=lambda t: t[1])
    return resultat


def _index_unites(rapport):
    index = {}
    for cycle in rapport.get("cycles", []):
        index[cycle["chemin"]] = cycle
        for phase in cycle.get("phases", []):
            index[phase["chemin"]] = phase
            for plan in phase.get("plans", []):
                index[plan["chemin"]] = plan
    return index


def coureur(banc_path, work_dir, recalc_sh):
    texte = open(banc_path, encoding="utf-8").read()
    ordre, labs = parser_banc(texte)
    tout_ok = True
    for nom in ordre:
        dest = os.path.join(work_dir, "bancs", nom)
        try:
            attendus = materialiser(banc_path, nom, dest)
        except ValueError as e:
            print("✗ BANC " + nom + " : " + str(e))
            tout_ok = False
            continue
        proc = subprocess.run(
            ["bash", recalc_sh, "--planning=" + os.path.join(dest, ".planning"), "--read-only"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        if proc.returncode != 0:
            print("✗ BANC " + nom + " : code=" + str(proc.returncode) + " stderr=" + proc.stderr.strip())
            tout_ok = False
            continue
        try:
            rapport = json.loads(proc.stdout)
        except ValueError as e:
            print("✗ BANC " + nom + " : JSON illisible (" + str(e) + ")")
            tout_ok = False
            continue
        index = _index_unites(rapport)
        for att in attendus:
            unite = att["unite"]
            trouve = index.get(unite)
            if trouve is None:
                print("✗ BANC " + nom + " " + unite + " : unité introuvable dans la dérivation")
                tout_ok = False
                continue
            if trouve["etat"] != att["etat"]:
                print("✗ BANC " + nom + " " + unite + " : attendu=" + str(att["etat"]) + " obtenu=" + str(trouve["etat"]))
                tout_ok = False
                continue
            if att["raison"] is not None and trouve.get("raison") != att["raison"]:
                print("✗ BANC " + nom + " " + unite + " : raison attendu=" + str(att["raison"]) + " obtenu=" + str(trouve.get("raison")))
                tout_ok = False
                continue
            print("✓ BANC " + nom + " " + unite + " : " + str(trouve["etat"]))
        lab = labs[nom]
        if lab["attendu_hors_modele_aucun"] or lab["attendus_hors_modele"]:
            obtenu_hm = sorted((e["chemin"], e["type"]) for e in rapport.get("hors_modele", []))
            voulu_hm = [] if lab["attendu_hors_modele_aucun"] else sorted(
                (e["chemin"], e["type"]) for e in lab["attendus_hors_modele"]
            )
            if obtenu_hm == voulu_hm:
                print("✓ BANC " + nom + " hors_modele : " + str(obtenu_hm))
            else:
                print("✗ BANC " + nom + " hors_modele : attendu=" + str(voulu_hm) + " obtenu=" + str(obtenu_hm))
                tout_ok = False
    sys.exit(0 if tout_ok else 1)


ETATS_DOUZE = (
    "à cadrer", "en cadrage", "à planifier", "à exécuter", "à juger", "à corriger", "à clore",
    "close", "indéterminé", "abandonné", "remplacé", "gelé",
)


def couverture(banc_path):
    """R20 : pour chacun des douze états (onze plus `à clore`), un lab non jumeau porte un `@@ attendu` à cet état sur
    une unité U ET un lab `jumeau-de=` ce lab porte un `@@ attendu` sur la MÊME unité U à un état
    différent."""
    texte = open(banc_path, encoding="utf-8").read()
    ordre, labs = parser_banc(texte)
    tout_ok = True
    for etat in ETATS_DOUZE:
        trouve = None
        for nom in ordre:
            lab = labs[nom]
            if lab.get("jumeau_de"):
                continue
            for att in lab["attendus"]:
                if att["etat"] != etat:
                    continue
                unite = att["unite"]
                for autre in ordre:
                    if labs[autre].get("jumeau_de") != nom:
                        continue
                    for att2 in labs[autre]["attendus"]:
                        if att2["unite"] == unite and att2["etat"] != etat:
                            trouve = (nom, autre)
                            break
                    if trouve:
                        break
                if trouve:
                    break
            if trouve:
                break
        if trouve:
            print("COUVERTURE " + etat + " positif=" + trouve[0] + " jumeau=" + trouve[1])
        else:
            print("✗ COUVERTURE " + etat + " : aucun positif/jumeau trouvé sur la même unité")
            tout_ok = False
    print("BANC-LABS n=" + str(len(labs)))
    sys.exit(0 if tout_ok else 1)


def verifier_hors_modele(chemin_rapport, chemin_attendu):
    """Compare `hors_modele` d'un rapport JSON (--read-only) à un ensemble attendu, tous deux
    normalisés en liste triée de (chemin, type) — 44-04 § Interfaces, `@@ attendu-hors-modele`."""
    rapport = json.load(open(chemin_rapport, encoding="utf-8"))
    attendu = json.load(open(chemin_attendu, encoding="utf-8"))
    obtenu = sorted((e["chemin"], e["type"]) for e in rapport.get("hors_modele", []))
    voulu = sorted((e["chemin"], e["type"]) for e in attendu)
    if obtenu == voulu:
        print("OK " + json.dumps(obtenu, ensure_ascii=False))
        sys.exit(0)
    print("KO attendu=" + json.dumps(voulu, ensure_ascii=False) + " obtenu=" + json.dumps(obtenu, ensure_ascii=False))
    sys.exit(1)


def main():
    action = sys.argv[1]
    if action == "materialiser":
        materialiser(sys.argv[2], sys.argv[3], sys.argv[4])
        return
    if action == "jetons":
        try:
            resoudre_jetons(sys.argv[2])
        except ValueError as e:
            print(str(e), file=sys.stderr)
            sys.exit(1)
        return
    if action == "empreinte":
        for type_, rel, valeur in empreinte(sys.argv[2]):
            print(type_ + "\t" + rel + "\t" + valeur)
        return
    if action == "coureur":
        coureur(sys.argv[2], sys.argv[3], sys.argv[4])
        return
    if action == "couverture":
        couverture(sys.argv[2])
        return
    if action == "verifier-hors-modele":
        verifier_hors_modele(sys.argv[2], sys.argv[3])
        return
    print("action inconnue : " + action, file=sys.stderr)
    sys.exit(1)


main()
PY_AIDES_EOF

materialiser() { "$PYBIN" "$AIDES_PY" materialiser "$BANC" "$1" "$2"; }
empreinte() { "$PYBIN" "$AIDES_PY" empreinte "$1"; }
# jetons — résout les jetons de verdict d'un lab déjà matérialisé (un VERDICT.md réécrit à la main par un cas inline).
jetons() { "$PYBIN" "$AIDES_PY" jetons "$1"; }

echo "== test-recalc-planning =="
echo ""

# ---------- R01 — coureur du banc sur tous les labs ------------------------------------------
BANC_OUT="$WORK/banc-out.txt"
"$PYBIN" "$AIDES_PY" coureur "$BANC" "$WORK/r01" "$RECALC" > "$BANC_OUT" 2>&1
BANC_RC=$?
cat "$BANC_OUT"
if [ "$BANC_RC" -eq 0 ] && ! grep -q '✗' "$BANC_OUT"; then
  ok "R01 coureur du banc : tous les labs et toutes les unités attendues concordent"
else
  ko "R01 coureur du banc" "code 0, aucune ligne ✗" "code=$BANC_RC, voir sortie ci-dessus" "$(grep '✗' "$BANC_OUT" | head -1)"
fi

# ---------- R02 — écriture sur une copie du lab traceur ---------------------------------------
R02_DIR="$WORK/r02"
materialiser traceur "$R02_DIR"
R02_OUT="$WORK/r02-out.json"
( cd "$R02_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" > "$R02_OUT" 2>"$WORK/r02-err.txt" )
R02_RC=$?
if [ "$R02_RC" -eq 0 ]; then ok "R02 code de sortie 0"; else ko "R02 code de sortie" "0" "$R02_RC" "$(cat "$WORK/r02-err.txt")"; fi
for f in INDEX.md STATE.md cloture.log; do
  if [ -f "$R02_DIR/.planning/$f" ]; then ok "R02 $f créé"; else ko "R02 $f créé" "présent" "absent" "-"; fi
done
if grep -qF '| cycles/01-traceur | à exécuter | 02-en-cours |' "$R02_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R02 ligne INDEX.md conforme (à exécuter, 02-en-cours)"
else
  ko "R02 ligne INDEX.md" "cycles/01-traceur | à exécuter | 02-en-cours" "$(grep 'cycles/01-traceur' "$R02_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
if grep -q '^cycle_courant: 01-traceur$' "$R02_DIR/.planning/STATE.md" 2>/dev/null \
   && grep -q '^phase_courante: 02-en-cours$' "$R02_DIR/.planning/STATE.md" 2>/dev/null; then
  ok "R02 STATE.md porte cycle_courant/phase_courante attendus"
else
  ko "R02 STATE.md" "cycle_courant: 01-traceur, phase_courante: 02-en-cours" "$(cat "$R02_DIR/.planning/STATE.md" 2>/dev/null)" "-"
fi
CLOTURE_LIGNES="$(grep -c . "$R02_DIR/.planning/cloture.log" 2>/dev/null || echo 0)"
CLOTURE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}  cycles/01-traceur/phases/01-livree  willy  verdict=passé  tentative=1  date=observation$'
if [ "$CLOTURE_LIGNES" -eq 1 ] && grep -Eq "$CLOTURE_RE" "$R02_DIR/.planning/cloture.log" 2>/dev/null; then
  ok "R02 cloture.log : une ligne conforme au format du contrat"
else
  ko "R02 cloture.log" "1 ligne conforme au format" "$CLOTURE_LIGNES ligne(s) : $(cat "$R02_DIR/.planning/cloture.log" 2>/dev/null)" "-"
fi

# ---------- R03 — second recalcul sur le même disque -------------------------------------------
cp "$R02_DIR/.planning/INDEX.md" "$WORK/r03-index-avant.md"
cp "$R02_DIR/.planning/STATE.md" "$WORK/r03-state-avant.md"
cp "$R02_DIR/.planning/cloture.log" "$WORK/r03-cloture-avant.log"
( cd "$R02_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" > "$WORK/r03-out.json" 2>"$WORK/r03-err.txt" )
R03_RC=$?
if [ "$R03_RC" -eq 0 ]; then ok "R03 second recalcul : code 0"; else ko "R03 code de sortie" "0" "$R03_RC" "$(cat "$WORK/r03-err.txt")"; fi
R03_ECRITS="$("$PYBIN" -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["ecrits"]))' "$WORK/r03-out.json" 2>/dev/null || echo "?")"
R03_AJOUTS="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cloture_ajouts"])' "$WORK/r03-out.json" 2>/dev/null || echo "?")"
if [ "$R03_ECRITS" = "0" ] && [ "$R03_AJOUTS" = "0" ]; then
  ok "R03 rapport : ecrits vide, cloture_ajouts 0"
else
  ko "R03 rapport" "ecrits=[] (len 0), cloture_ajouts=0" "len(ecrits)=$R03_ECRITS, cloture_ajouts=$R03_AJOUTS" "-"
fi
if cmp -s "$WORK/r03-index-avant.md" "$R02_DIR/.planning/INDEX.md" \
   && cmp -s "$WORK/r03-state-avant.md" "$R02_DIR/.planning/STATE.md" \
   && cmp -s "$WORK/r03-cloture-avant.log" "$R02_DIR/.planning/cloture.log"; then
  ok "R03 INDEX.md/STATE.md/cloture.log identiques octet pour octet au premier passage"
else
  ko "R03 identité octet pour octet" "cmp -s réussit sur les trois fichiers" "au moins un fichier diffère" "-"
fi

# ---------- R04 — copie sans config.json --------------------------------------------------------
R04_DIR="$WORK/r04"
materialiser traceur "$R04_DIR"
rm -f "$R04_DIR/.planning/config.json"
empreinte "$R04_DIR" > "$WORK/r04-avant.txt"
( cd "$R04_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" > "$WORK/r04-out.txt" 2>"$WORK/r04-err.txt" )
R04_RC=$?
empreinte "$R04_DIR" > "$WORK/r04-apres.txt"
if [ "$R04_RC" -eq 2 ]; then ok "R04 code de sortie 2"; else ko "R04 code de sortie" "2" "$R04_RC" "$(cat "$WORK/r04-out.txt")"; fi
if grep -qF '"planning_version": "cycles-v1"' "$WORK/r04-err.txt"; then
  ok "R04 stderr cite le littéral \"planning_version\": \"cycles-v1\""
else
  ko "R04 stderr" 'contient "planning_version": "cycles-v1"' "$(cat "$WORK/r04-err.txt")" "-"
fi
if cmp -s "$WORK/r04-avant.txt" "$WORK/r04-apres.txt"; then
  ok "R04 empreinte identique avant/après (aucun fichier créé)"
else
  ko "R04 empreinte" "identique avant/après" "$(diff "$WORK/r04-avant.txt" "$WORK/r04-apres.txt" | head -5)" "-"
fi

# ---------- R05 — trois variantes non adhérentes -----------------------------------------------
r05_variante() { # <label> <contenu_config>
  local label="$1" contenu="$2" dir
  dir="$WORK/r05-$label"
  materialiser traceur "$dir"
  printf '%s' "$contenu" > "$dir/.planning/config.json"
  empreinte "$dir" > "$WORK/r05-$label-avant.txt"
  ( cd "$dir" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r05-$label-out.txt" 2>"$WORK/r05-$label-err.txt" )
  local rc=$?
  empreinte "$dir" > "$WORK/r05-$label-apres.txt"
  if [ "$rc" -eq 2 ]; then
    ok "R05 [$label] code de sortie 2"
  else
    ko "R05 [$label] code de sortie" "2" "$rc" "$(cat "$WORK/r05-$label-out.txt")"
  fi
  if cmp -s "$WORK/r05-$label-avant.txt" "$WORK/r05-$label-apres.txt"; then
    ok "R05 [$label] empreinte identique"
  else
    ko "R05 [$label] empreinte" "identique" "$(diff "$WORK/r05-$label-avant.txt" "$WORK/r05-$label-apres.txt" | head -3)" "-"
  fi
}
r05_variante "2.0" '{"planning_version": "2.0"}'
r05_variante "nombre" '{"planning_version": 3}'
r05_variante "illisible" '{planning_version: cycles-v1'

# ---------- R06 — --read-only sur copie sans config.json ----------------------------------------
R06_DIR="$WORK/r06"
materialiser traceur "$R06_DIR"
rm -f "$R06_DIR/.planning/config.json"
empreinte "$R06_DIR" > "$WORK/r06-avant.txt"
( cd "$R06_DIR" && bash "$RECALC" --read-only >"$WORK/r06-out.json" 2>"$WORK/r06-err.txt" )
R06_RC=$?
empreinte "$R06_DIR" > "$WORK/r06-apres.txt"
if [ "$R06_RC" -eq 0 ]; then ok "R06 code de sortie 0"; else ko "R06 code de sortie" "0" "$R06_RC" "$(cat "$WORK/r06-err.txt")"; fi
R06_ADHERENTE="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["adhesion"]["adherente"])' "$WORK/r06-out.json" 2>/dev/null || echo '?')"
R06_CONFIG="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["adhesion"]["config"])' "$WORK/r06-out.json" 2>/dev/null || echo '?')"
if [ "$R06_ADHERENTE" = "False" ] && [ "$R06_CONFIG" = "absent" ]; then
  ok "R06 adhesion.adherente=faux, adhesion.config=absent"
else
  ko "R06 adhesion" "adherente=False, config=absent" "adherente=$R06_ADHERENTE, config=$R06_CONFIG" "-"
fi
if cmp -s "$WORK/r06-avant.txt" "$WORK/r06-apres.txt"; then ok "R06 empreinte identique"; else ko "R06 empreinte" "identique" "diverge" "-"; fi
R06_ADH_DIR="$WORK/r06-adherent"
materialiser traceur "$R06_ADH_DIR"
( cd "$R06_ADH_DIR" && bash "$RECALC" --read-only > "$WORK/r06-adh-out.json" 2>/dev/null )
R06_CYCLES_EQ="$("$PYBIN" -c 'import json,sys; a=json.load(open(sys.argv[1]))["cycles"]; b=json.load(open(sys.argv[2]))["cycles"]; print(a==b)' "$WORK/r06-out.json" "$WORK/r06-adh-out.json" 2>/dev/null || echo '?')"
if [ "$R06_CYCLES_EQ" = "True" ]; then
  ok "R06 états dérivés identiques à ceux du lab adhérent"
else
  ko "R06 états dérivés" "identiques au lab adhérent" "$R06_CYCLES_EQ" "-"
fi

# ---------- R07 — --read-only sur lab adhérent ---------------------------------------------------
R07_DIR="$WORK/r07"
materialiser traceur "$R07_DIR"
empreinte "$R07_DIR" > "$WORK/r07-avant.txt"
( cd "$R07_DIR" && bash "$RECALC" --read-only >/dev/null 2>&1 )
empreinte "$R07_DIR" > "$WORK/r07-apres.txt"
if cmp -s "$WORK/r07-avant.txt" "$WORK/r07-apres.txt"; then
  ok "R07 empreinte identique (--read-only, lab adhérent)"
else
  ko "R07 empreinte" "identique" "diverge" "-"
fi
R07_FAKE_SCRIPTS="$WORK/r07-fake-scripts"
mkdir -p "$R07_FAKE_SCRIPTS"
cp "$RECALC" "$R07_FAKE_SCRIPTS/recalc-planning.sh"
R07_SENTINEL="$WORK/r07-sentinel"
printf '#!/usr/bin/env bash\ntouch "%s"\nexit 3\n' "$R07_SENTINEL" > "$R07_FAKE_SCRIPTS/detect-gsd-engine.sh"
chmod +x "$R07_FAKE_SCRIPTS/detect-gsd-engine.sh"
rm -f "$R07_SENTINEL"
( cd "$R07_DIR" && bash "$R07_FAKE_SCRIPTS/recalc-planning.sh" --read-only >/dev/null 2>&1 )
if [ ! -f "$R07_SENTINEL" ]; then
  ok "R07 --read-only n'invoque jamais detect-gsd-engine.sh (sentinelle absente)"
else
  ko "R07 sentinelle" "absente après --read-only" "présente" "-"
fi
( cd "$R07_DIR" && GSD_HOME="$FAKE_GSD" bash "$R07_FAKE_SCRIPTS/recalc-planning.sh" >/dev/null 2>&1 )
if [ -f "$R07_SENTINEL" ]; then
  ok "R07 témoin : le mode écriture invoque bien le détecteur (sentinelle apparaît)"
else
  ko "R07 témoin sentinelle" "présente après écriture" "absente" "-"
fi

# ---------- R08 — lab adhérent + STATE.md gsd_state_version -------------------------------------
R08_DIR="$WORK/r08"
materialiser traceur "$R08_DIR"
printf -- '---\ngsd_state_version: 1.0\n---\n' > "$R08_DIR/.planning/STATE.md"
empreinte "$R08_DIR" > "$WORK/r08-avant.txt"
( cd "$R08_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r08-out.txt" 2>"$WORK/r08-err.txt" )
R08_RC=$?
empreinte "$R08_DIR" > "$WORK/r08-apres.txt"
if [ "$R08_RC" -eq 3 ]; then ok "R08 code de sortie 3"; else ko "R08 code de sortie" "3" "$R08_RC" "$(cat "$WORK/r08-out.txt")"; fi
if grep -q "P44-D-02a" "$WORK/r08-err.txt"; then ok "R08 stderr cite P44-D-02a"; else ko "R08 stderr" "cite P44-D-02a" "$(cat "$WORK/r08-err.txt")" "-"; fi
if cmp -s "$WORK/r08-avant.txt" "$WORK/r08-apres.txt"; then ok "R08 empreinte identique"; else ko "R08 empreinte" "identique" "diverge" "-"; fi
R08B_DIR="$WORK/r08b"
materialiser traceur "$R08B_DIR"
( cd "$R08B_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r08b-out.txt" 2>"$WORK/r08b-err.txt" )
R08B_RC=$?
if [ "$R08B_RC" -eq 0 ]; then ok "R08 jumeau sans la clé : code de sortie 0"; else ko "R08 jumeau" "0" "$R08B_RC" "$(cat "$WORK/r08b-err.txt")"; fi

# ---------- R09 — détecteur absent / sorti 64 / dossier ------------------------------------------
R09_absent() {
  local dir="$WORK/r09-absent" scripts="$WORK/r09-absent-scripts"
  materialiser traceur "$dir"
  mkdir -p "$scripts"
  cp "$RECALC" "$scripts/recalc-planning.sh"
  empreinte "$dir" > "$WORK/r09-absent-avant.txt"
  ( cd "$dir" && GSD_HOME="$FAKE_GSD" bash "$scripts/recalc-planning.sh" >"$WORK/r09-absent-out.txt" 2>"$WORK/r09-absent-err.txt" )
  local rc=$?
  empreinte "$dir" > "$WORK/r09-absent-apres.txt"
  if [ "$rc" -eq 3 ]; then ok "R09 [absent] code de sortie 3"; else ko "R09 [absent] code" "3" "$rc" "$(cat "$WORK/r09-absent-out.txt")"; fi
  if cmp -s "$WORK/r09-absent-avant.txt" "$WORK/r09-absent-apres.txt"; then ok "R09 [absent] empreinte identique"; else ko "R09 [absent] empreinte" "identique" "diverge" "-"; fi
}
R09_sort64() {
  local dir="$WORK/r09-sort64" scripts="$WORK/r09-sort64-scripts"
  materialiser traceur "$dir"
  mkdir -p "$scripts"
  cp "$RECALC" "$scripts/recalc-planning.sh"
  printf '#!/usr/bin/env bash\nexit 64\n' > "$scripts/detect-gsd-engine.sh"
  chmod +x "$scripts/detect-gsd-engine.sh"
  empreinte "$dir" > "$WORK/r09-sort64-avant.txt"
  ( cd "$dir" && GSD_HOME="$FAKE_GSD" bash "$scripts/recalc-planning.sh" >"$WORK/r09-sort64-out.txt" 2>"$WORK/r09-sort64-err.txt" )
  local rc=$?
  empreinte "$dir" > "$WORK/r09-sort64-apres.txt"
  if [ "$rc" -eq 3 ]; then ok "R09 [sort64] code de sortie 3"; else ko "R09 [sort64] code" "3" "$rc" "$(cat "$WORK/r09-sort64-out.txt")"; fi
  if cmp -s "$WORK/r09-sort64-avant.txt" "$WORK/r09-sort64-apres.txt"; then ok "R09 [sort64] empreinte identique"; else ko "R09 [sort64] empreinte" "identique" "diverge" "-"; fi
}
R09_dossier() {
  local dir="$WORK/r09-dossier" scripts="$WORK/r09-dossier-scripts"
  materialiser traceur "$dir"
  mkdir -p "$scripts"
  cp "$RECALC" "$scripts/recalc-planning.sh"
  mkdir -p "$scripts/detect-gsd-engine.sh"
  empreinte "$dir" > "$WORK/r09-dossier-avant.txt"
  ( cd "$dir" && GSD_HOME="$FAKE_GSD" bash "$scripts/recalc-planning.sh" >"$WORK/r09-dossier-out.txt" 2>"$WORK/r09-dossier-err.txt" )
  local rc=$?
  empreinte "$dir" > "$WORK/r09-dossier-apres.txt"
  if [ "$rc" -eq 3 ]; then ok "R09 [dossier] code de sortie 3"; else ko "R09 [dossier] code" "3" "$rc" "$(cat "$WORK/r09-dossier-out.txt")"; fi
  if grep -q "détecteur non régulier" "$WORK/r09-dossier-err.txt"; then
    ok "R09 [dossier] stderr mentionne « détecteur non régulier »"
  else
    ko "R09 [dossier] stderr" "contient détecteur non régulier" "$(cat "$WORK/r09-dossier-err.txt")" "-"
  fi
  if cmp -s "$WORK/r09-dossier-avant.txt" "$WORK/r09-dossier-apres.txt"; then ok "R09 [dossier] empreinte identique"; else ko "R09 [dossier] empreinte" "identique" "diverge" "-"; fi
}
R09_absent
R09_sort64
R09_dossier

# ---------- R10 — cloture.log pré-rempli : ajout seul --------------------------------------------
R10_DIR="$WORK/r10"
materialiser traceur "$R10_DIR"
R10_TEMOIN="2020-01-01T00:00:00+00:00  cycles/00-temoin/phases/00-temoin  temoin  verdict=passé  tentative=1  date=observation"
printf '%s\n' "$R10_TEMOIN" > "$R10_DIR/.planning/cloture.log"
R10_TAILLE_AVANT=$(wc -c < "$R10_DIR/.planning/cloture.log")
( cd "$R10_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r10-err.txt" )
R10_RC=$?
if [ "$R10_RC" -eq 0 ]; then ok "R10 code de sortie 0"; else ko "R10 code" "0" "$R10_RC" "$(cat "$WORK/r10-err.txt")"; fi
head -c "$R10_TAILLE_AVANT" "$R10_DIR/.planning/cloture.log" > "$WORK/r10-prefixe.txt"
printf '%s\n' "$R10_TEMOIN" > "$WORK/r10-temoin.txt"
if cmp -s "$WORK/r10-temoin.txt" "$WORK/r10-prefixe.txt"; then
  ok "R10 préfixe du journal intact (octets antérieurs)"
else
  ko "R10 préfixe" "octets antérieurs intacts" "préfixe modifié" "-"
fi
R10_LIGNES_APRES=$(grep -c . "$R10_DIR/.planning/cloture.log")
if [ "$R10_LIGNES_APRES" -eq 2 ]; then
  ok "R10 une ligne ajoutée (2 au total)"
else
  ko "R10 lignes" "2" "$R10_LIGNES_APRES" "-"
fi

# ---------- R11 — cloture.log en lien symbolique --------------------------------------------------
R11_DIR="$WORK/r11"
materialiser traceur "$R11_DIR"
rm -f "$R11_DIR/.planning/cloture.log"
R11_CIBLE="$WORK/r11-cible-hors-lab.log"
printf 'contenu-original\n' > "$R11_CIBLE"
ln -s "$R11_CIBLE" "$R11_DIR/.planning/cloture.log"
( cd "$R11_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r11-out.txt" 2>"$WORK/r11-err.txt" )
R11_RC=$?
if [ "$R11_RC" -eq 1 ]; then ok "R11 code de sortie 1"; else ko "R11 code" "1" "$R11_RC" "$(cat "$WORK/r11-err.txt")"; fi
if printf 'contenu-original\n' | cmp -s - "$R11_CIBLE"; then ok "R11 cible du lien inchangée"; else ko "R11 cible" "inchangée" "modifiée" "-"; fi
if [ ! -f "$R11_DIR/.planning/INDEX.md" ] && [ ! -f "$R11_DIR/.planning/STATE.md" ]; then
  ok "R11 ni INDEX.md ni STATE.md créés"
else
  ko "R11 fichiers créés" "aucun" "INDEX.md et/ou STATE.md présents" "-"
fi

# ---------- R12 — drapeau de traçage ignoré (P44-D-05) --------------------------------------------
R12_A_DIR="$WORK/r12-a"; materialiser traceur "$R12_A_DIR"
R12_B_DIR="$WORK/r12-b"; materialiser traceur "$R12_B_DIR"
"$PYBIN" -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["phases_trace"]=False; json.dump(d, open(p,"w"))' "$R12_B_DIR/.planning/config.json"
( cd "$R12_A_DIR" && bash "$RECALC" --read-only > "$WORK/r12-a-out.json" 2>/dev/null )
( cd "$R12_B_DIR" && bash "$RECALC" --read-only > "$WORK/r12-b-out.json" 2>/dev/null )
if cmp -s "$WORK/r12-a-out.json" "$WORK/r12-b-out.json"; then
  ok "R12 JSON --read-only identique avec/sans drapeau de traçage"
else
  ko "R12 JSON" "identique" "diverge" "-"
fi

# ---------- R13 — GSD_HOME inexistant (détecteur rend 1) -----------------------------------------
R13_GSD_HOME_INEXISTANT="$WORK/r13-nonexistent-gsd-home"
R13A_DIR="$WORK/r13a"
materialiser traceur "$R13A_DIR"
printf -- '---\ngsd_state_version: 1.0\n---\n' > "$R13A_DIR/.planning/STATE.md"
empreinte "$R13A_DIR" > "$WORK/r13a-avant.txt"
( cd "$R13A_DIR" && GSD_HOME="$R13_GSD_HOME_INEXISTANT" bash "$RECALC" >"$WORK/r13a-out.txt" 2>"$WORK/r13a-err.txt" )
R13A_RC=$?
empreinte "$R13A_DIR" > "$WORK/r13a-apres.txt"
if [ "$R13A_RC" -eq 3 ]; then ok "R13 (a) code de sortie 3"; else ko "R13 (a) code" "3" "$R13A_RC" "$(cat "$WORK/r13a-out.txt")"; fi
if cmp -s "$WORK/r13a-avant.txt" "$WORK/r13a-apres.txt"; then ok "R13 (a) empreinte identique"; else ko "R13 (a) empreinte" "identique" "diverge" "-"; fi

R13B_DIR="$WORK/r13b"
materialiser traceur "$R13B_DIR"
( cd "$R13B_DIR" && GSD_HOME="$R13_GSD_HOME_INEXISTANT" bash "$RECALC" >"$WORK/r13b-out.txt" 2>"$WORK/r13b-err.txt" )
R13B_RC=$?
if [ "$R13B_RC" -eq 0 ]; then ok "R13 (b) jumeau négatif : code de sortie 0"; else ko "R13 (b) code" "0" "$R13B_RC" "$(cat "$WORK/r13b-err.txt")"; fi

R13C_DIR="$WORK/r13c"
materialiser traceur "$R13C_DIR"
mkdir -p "$R13C_DIR/.planning/workstreams/gouvernance-banc"
printf -- '---\ngsd_state_version: 1.0\n---\n' > "$R13C_DIR/.planning/workstreams/gouvernance-banc/STATE.md"
empreinte "$R13C_DIR" > "$WORK/r13c-avant.txt"
( cd "$R13C_DIR" && GSD_HOME="$R13_GSD_HOME_INEXISTANT" bash "$RECALC" >"$WORK/r13c-out.txt" 2>"$WORK/r13c-err.txt" )
R13C_RC=$?
empreinte "$R13C_DIR" > "$WORK/r13c-apres.txt"
if [ "$R13C_RC" -eq 3 ]; then ok "R13 (c) partition : code de sortie 3"; else ko "R13 (c) code" "3" "$R13C_RC" "$(cat "$WORK/r13c-out.txt")"; fi
if cmp -s "$WORK/r13c-avant.txt" "$WORK/r13c-apres.txt"; then ok "R13 (c) empreinte identique"; else ko "R13 (c) empreinte" "identique" "diverge" "-"; fi

# ---------- R14 — umask 0077 : permissions 0o644 forcées -----------------------------------------
R14_DIR="$WORK/r14"
materialiser traceur "$R14_DIR"
( cd "$R14_DIR" && ( umask 0077; GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 ) )
R14_OK=1
R14_MODES=""
for f in INDEX.md STATE.md cloture.log; do
  MODE=$(mode_octal "$R14_DIR/.planning/$f")
  R14_MODES="$R14_MODES $f=$MODE"
  [ "$MODE" = "644" ] || R14_OK=0
done
if [ "$R14_OK" -eq 1 ]; then
  ok "R14 INDEX.md/STATE.md/cloture.log en 0o644 sous umask 0077"
else
  ko "R14 permissions" "644 chacun" "$R14_MODES" "-"
fi

# ---------- R20 — contrôle de couverture (douze états : onze plus `à clore`, positif + jumeau, P44-D-06/D-17, P46-D-04) ----------
R20_OUT="$WORK/r20-out.txt"
"$PYBIN" "$AIDES_PY" couverture "$BANC" > "$R20_OUT" 2>&1
R20_RC=$?
cat "$R20_OUT"
if [ "$R20_RC" -eq 0 ] && [ "$(grep -c '^COUVERTURE ' "$R20_OUT")" -eq 12 ]; then
  ok "R20 couverture : douze états couverts, chacun par un positif et un jumeau"
else
  ko "R20 couverture" "code 0, douze lignes COUVERTURE" "code=$R20_RC, $(grep -c '^COUVERTURE ' "$R20_OUT") ligne(s)" "$(grep '✗' "$R20_OUT" | head -1)"
fi
BANC_LABS_N="$(grep -oE 'BANC-LABS n=[0-9]+' "$R20_OUT" | grep -oE '[0-9]+')"
if [ -n "$BANC_LABS_N" ] && [ "$BANC_LABS_N" -ge 18 ]; then
  ok "R20 BANC-LABS n=$BANC_LABS_N (au moins 18)"
else
  ko "R20 BANC-LABS" ">= 18" "$BANC_LABS_N" "-"
fi

# ---------- R21 — écriture sur plans-tous-clos : cloture.log porte une ligne par plan + une ligne
# phase (verdict=plans-clos, auteur inconnu) ; second recalcul : aucune ligne ajoutée -------------
R21_DIR="$WORK/r21"
materialiser plans-tous-clos "$R21_DIR"
( cd "$R21_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r21-out.txt" 2>"$WORK/r21-err.txt" )
R21_RC=$?
if [ "$R21_RC" -eq 0 ]; then ok "R21 code de sortie 0"; else ko "R21 code" "0" "$R21_RC" "$(cat "$WORK/r21-err.txt")"; fi
R21_CLOTURE="$R21_DIR/.planning/cloture.log"
if grep -Eq '^[0-9-]+T[0-9:+-]+  cycles/01-c/phases/01-p/plans/01-a  alice  verdict=passé  tentative=1  date=observation$' "$R21_CLOTURE" 2>/dev/null; then
  ok "R21 ligne du plan 01-a (auteur alice, verdict=passé, tentative=1)"
else
  ko "R21 ligne plan 01-a" "verdict=passé, auteur alice, tentative=1" "$(cat "$R21_CLOTURE" 2>/dev/null)" "-"
fi
if grep -Eq '^[0-9-]+T[0-9:+-]+  cycles/01-c/phases/01-p/plans/02-b  bob  verdict=passé  tentative=1  date=observation$' "$R21_CLOTURE" 2>/dev/null; then
  ok "R21 ligne du plan 02-b (auteur bob, verdict=passé, tentative=1)"
else
  ko "R21 ligne plan 02-b" "verdict=passé, auteur bob, tentative=1" "$(cat "$R21_CLOTURE" 2>/dev/null)" "-"
fi
if grep -Eq '^[0-9-]+T[0-9:+-]+  cycles/01-c/phases/01-p  inconnu  verdict=plans-clos  tentative=-  date=observation$' "$R21_CLOTURE" 2>/dev/null; then
  ok "R21 ligne de la phase (auteur inconnu, verdict=plans-clos, tentative=-)"
else
  ko "R21 ligne phase" "verdict=plans-clos, auteur inconnu, tentative=-" "$(cat "$R21_CLOTURE" 2>/dev/null)" "-"
fi
R21_LIGNES_AVANT="$(grep -c . "$R21_CLOTURE" 2>/dev/null || echo 0)"
( cd "$R21_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r21-out2.txt" 2>"$WORK/r21-err2.txt" )
R21_AJOUTS2="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cloture_ajouts"])' "$WORK/r21-out2.txt" 2>/dev/null || echo '?')"
R21_LIGNES_APRES="$(grep -c . "$R21_CLOTURE" 2>/dev/null || echo 0)"
if [ "$R21_AJOUTS2" = "0" ] && [ "$R21_LIGNES_APRES" = "$R21_LIGNES_AVANT" ]; then
  ok "R21 second recalcul : aucune ligne ajoutée"
else
  ko "R21 second recalcul" "cloture_ajouts=0, mêmes lignes ($R21_LIGNES_AVANT)" "cloture_ajouts=$R21_AJOUTS2, lignes=$R21_LIGNES_APRES" "-"
fi

# ---------- R22 — écriture sur derog-abandonne : une ligne verdict=abandonné, auteur willy -------
R22_DIR="$WORK/r22"
materialiser derog-abandonne "$R22_DIR"
( cd "$R22_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r22-out.txt" 2>"$WORK/r22-err.txt" )
R22_RC=$?
if [ "$R22_RC" -eq 0 ]; then ok "R22 code de sortie 0"; else ko "R22 code" "0" "$R22_RC" "$(cat "$WORK/r22-err.txt")"; fi
if grep -Eq '^[0-9-]+T[0-9:+-]+  cycles/01-c/phases/01-p  willy  verdict=abandonné  tentative=-  date=observation$' "$R22_DIR/.planning/cloture.log" 2>/dev/null; then
  ok "R22 ligne de dérogation (verdict=abandonné, auteur willy, tentative=-)"
else
  ko "R22 ligne dérogation" "verdict=abandonné, auteur willy, tentative=-" "$(cat "$R22_DIR/.planning/cloture.log" 2>/dev/null)" "-"
fi

# ---------- R23 — gabarits recopiés tels quels : aucun ne rend close -----------------------------
gabarit_path() { # <nom-fichier>
  local nom="$1" prefixe
  for prefixe in "$SCRIPTS_DIR/../references/templates/cycles" "$SCRIPTS_DIR/../skills/planning-core/references/templates/cycles"; do
    if [ -f "$prefixe/$nom" ]; then echo "$prefixe/$nom"; return 0; fi
  done
  echo "[test-recalc-planning] gabarit introuvable : $nom" >&2
  return 1
}
R23_CADRAGE_GABARIT="$(gabarit_path CADRAGE.template.md)"
R23_PLAN_GABARIT="$(gabarit_path PLAN.template.md)"
R23_VERDICT_GABARIT="$(gabarit_path VERDICT.template.md)"
R23_DEROGATION_GABARIT="$(gabarit_path DEROGATION.template.md)"
R23_CYCLE_GABARIT="$(gabarit_path CYCLE.template.md)"
R23_CONFIG_GABARIT="$(gabarit_path config.template.json)"
if [ -n "$R23_CADRAGE_GABARIT" ] && [ -n "$R23_PLAN_GABARIT" ] && [ -n "$R23_VERDICT_GABARIT" ] \
   && [ -n "$R23_DEROGATION_GABARIT" ] && [ -n "$R23_CYCLE_GABARIT" ] && [ -n "$R23_CONFIG_GABARIT" ]; then
  ok "R23 huit gabarits résolus (../references/templates/cycles)"
else
  ko "R23 résolution des gabarits" "les six chemins non vides" "au moins un manquant" "-"
fi

r23_ecrire_config_cycles_v1() { printf '%s' '{"planning_version": "cycles-v1"}' > "$1/.planning/config.json"; }
r23_ecrire_cycle_titre() { mkdir -p "$(dirname "$2")"; printf -- '---\ntitre: Cycle R23\n---\n' > "$2"; }

# R23-A — CADRAGE gabarit seul -> en cadrage
R23A_DIR="$WORK/r23a"
mkdir -p "$R23A_DIR/.planning/cycles/01-c/phases/01-p"
r23_ecrire_config_cycles_v1 "$R23A_DIR"
r23_ecrire_cycle_titre "$R23A_DIR" "$R23A_DIR/.planning/cycles/01-c/CYCLE.md"
cp "$R23_CADRAGE_GABARIT" "$R23A_DIR/.planning/cycles/01-c/phases/01-p/CADRAGE.md"
( cd "$R23A_DIR" && bash "$RECALC" --read-only > "$WORK/r23a-out.json" 2>"$WORK/r23a-err.txt" )
R23A_ETAT="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/r23a-out.json" 2>/dev/null || echo '?')"
if [ "$R23A_ETAT" = "en cadrage" ]; then ok "R23-A CADRAGE gabarit seul -> en cadrage"; else ko "R23-A" "en cadrage" "$R23A_ETAT" "-"; fi

# R23-B — CADRAGE clos (écrit par la suite) + PLAN gabarit -> ecrit-invalide
R23B_DIR="$WORK/r23b"
mkdir -p "$R23B_DIR/.planning/cycles/01-c/phases/01-p"
r23_ecrire_config_cycles_v1 "$R23B_DIR"
r23_ecrire_cycle_titre "$R23B_DIR" "$R23B_DIR/.planning/cycles/01-c/CYCLE.md"
printf -- '---\ninconnues:\n  - id: I-01\n    question: "Q ?"\n    structurante: oui\n    statut: ARBITRÉ\n---\n' > "$R23B_DIR/.planning/cycles/01-c/phases/01-p/CADRAGE.md"
cp "$R23_PLAN_GABARIT" "$R23B_DIR/.planning/cycles/01-c/phases/01-p/PLAN.md"
( cd "$R23B_DIR" && bash "$RECALC" --read-only > "$WORK/r23b-out.json" 2>"$WORK/r23b-err.txt" )
R23B_RAISON="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["raison"])' "$WORK/r23b-out.json" 2>/dev/null || echo '?')"
if [ "$R23B_RAISON" = "ecrit-invalide" ]; then ok "R23-B PLAN gabarit -> ecrit-invalide"; else ko "R23-B" "ecrit-invalide" "$R23B_RAISON" "-"; fi

# R23-C — chaîne complète avec VERDICT gabarit -> verdict-invalide
R23C_DIR="$WORK/r23c"
mkdir -p "$R23C_DIR/.planning/cycles/01-c/phases/01-p"
r23_ecrire_config_cycles_v1 "$R23C_DIR"
r23_ecrire_cycle_titre "$R23C_DIR" "$R23C_DIR/.planning/cycles/01-c/CYCLE.md"
printf -- '---\ninconnues:\n  - id: I-01\n    question: "Q ?"\n    structurante: oui\n    statut: ARBITRÉ\n---\n' > "$R23C_DIR/.planning/cycles/01-c/phases/01-p/CADRAGE.md"
printf -- '---\necrit: livrables/rapport.md\n---\n' > "$R23C_DIR/.planning/cycles/01-c/phases/01-p/PLAN.md"
printf -- '---\ncloture_par: willy\ncloture_le: "2026-09-27"\n---\n' > "$R23C_DIR/.planning/cycles/01-c/phases/01-p/CLOTURE.md"
mkdir -p "$R23C_DIR/livrables"; printf 'rapport\n' > "$R23C_DIR/livrables/rapport.md"
cp "$R23_VERDICT_GABARIT" "$R23C_DIR/.planning/cycles/01-c/phases/01-p/VERDICT.md"
( cd "$R23C_DIR" && bash "$RECALC" --read-only > "$WORK/r23c-out.json" 2>"$WORK/r23c-err.txt" )
R23C_RAISON="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["raison"])' "$WORK/r23c-out.json" 2>/dev/null || echo '?')"
if [ "$R23C_RAISON" = "verdict-invalide" ]; then ok "R23-C VERDICT gabarit -> verdict-invalide"; else ko "R23-C" "verdict-invalide" "$R23C_RAISON" "-"; fi

# R23-D — DEROGATION gabarit -> derogation-invalide
R23D_DIR="$WORK/r23d"
mkdir -p "$R23D_DIR/.planning/cycles/01-c/phases/01-p"
r23_ecrire_config_cycles_v1 "$R23D_DIR"
r23_ecrire_cycle_titre "$R23D_DIR" "$R23D_DIR/.planning/cycles/01-c/CYCLE.md"
cp "$R23_DEROGATION_GABARIT" "$R23D_DIR/.planning/cycles/01-c/phases/01-p/DEROGATION.md"
( cd "$R23D_DIR" && bash "$RECALC" --read-only > "$WORK/r23d-out.json" 2>"$WORK/r23d-err.txt" )
R23D_RAISON="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["raison"])' "$WORK/r23d-out.json" 2>/dev/null || echo '?')"
if [ "$R23D_RAISON" = "derogation-invalide" ]; then ok "R23-D DEROGATION gabarit -> derogation-invalide"; else ko "R23-D" "derogation-invalide" "$R23D_RAISON" "-"; fi

# R23-E — CYCLE gabarit seul sans phase -> cycle à cadrer
R23E_DIR="$WORK/r23e"
mkdir -p "$R23E_DIR/.planning/cycles/01-c"
r23_ecrire_config_cycles_v1 "$R23E_DIR"
cp "$R23_CYCLE_GABARIT" "$R23E_DIR/.planning/cycles/01-c/CYCLE.md"
( cd "$R23E_DIR" && bash "$RECALC" --read-only > "$WORK/r23e-out.json" 2>"$WORK/r23e-err.txt" )
R23E_ETAT="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["etat"])' "$WORK/r23e-out.json" 2>/dev/null || echo '?')"
if [ "$R23E_ETAT" = "à cadrer" ]; then ok "R23-E CYCLE gabarit seul -> cycle à cadrer"; else ko "R23-E" "à cadrer" "$R23E_ETAT" "-"; fi

# R23-F — config gabarit -> adhérent (écriture en code 0)
R23F_DIR="$WORK/r23f"
mkdir -p "$R23F_DIR/.planning"
cp "$R23_CONFIG_GABARIT" "$R23F_DIR/.planning/config.json"
"$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); d["project_code"]="banc"; json.dump(d, open(sys.argv[1],"w"))' "$R23F_DIR/.planning/config.json"
( cd "$R23F_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" > "$WORK/r23f-out.txt" 2>"$WORK/r23f-err.txt" )
R23F_RC=$?
if [ "$R23F_RC" -eq 0 ]; then ok "R23-F config gabarit -> adhérent (code 0)"; else ko "R23-F" "0" "$R23F_RC" "$(cat "$WORK/r23f-err.txt")"; fi

# ---------- R24 — clôture ne change ni le hash de PLAN.md ni l'empreinte de cycles/ (P44-D-03) ---
R24_DIR="$WORK/r24"
materialiser etat-a-executer "$R24_DIR"
R24_SHA_AVANT="$(shasum -a 256 "$R24_DIR/.planning/cycles/01-c/phases/01-p/PLAN.md" 2>/dev/null | cut -d' ' -f1)"
[ -n "$R24_SHA_AVANT" ] || R24_SHA_AVANT="$(sha256sum "$R24_DIR/.planning/cycles/01-c/phases/01-p/PLAN.md" 2>/dev/null | cut -d' ' -f1)"
( cd "$R24_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r24-err1.txt" )
empreinte "$R24_DIR/.planning/cycles" > "$WORK/r24-cycles-avant.txt"
printf -- '---\ncloture_par: willy\ncloture_le: "2026-09-27"\n---\n' > "$R24_DIR/.planning/cycles/01-c/phases/01-p/CLOTURE.md"
mkdir -p "$R24_DIR/livrables"; printf 'rapport\n' > "$R24_DIR/livrables/rapport.md"
( cd "$R24_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r24-out2.json" 2>"$WORK/r24-err2.txt" )
R24_RC=$?
empreinte "$R24_DIR/.planning/cycles" > "$WORK/r24-cycles-apres.txt"
R24_SHA_APRES="$(shasum -a 256 "$R24_DIR/.planning/cycles/01-c/phases/01-p/PLAN.md" 2>/dev/null | cut -d' ' -f1)"
[ -n "$R24_SHA_APRES" ] || R24_SHA_APRES="$(sha256sum "$R24_DIR/.planning/cycles/01-c/phases/01-p/PLAN.md" 2>/dev/null | cut -d' ' -f1)"
if [ "$R24_RC" -eq 0 ]; then ok "R24 code de sortie 0 après clôture"; else ko "R24 code" "0" "$R24_RC" "$(cat "$WORK/r24-err2.txt")"; fi
R24_ETAT_APRES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cycles"][0]["phases"][0]["etat"])' /dev/null 2>/dev/null; true)"
if [ -f "$R24_DIR/.planning/INDEX.md" ] && grep -qF '| cycles/01-c | à juger | 01-p |' "$R24_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R24 phase passe à juger après clôture + livrable"
else
  ko "R24 INDEX.md" "cycles/01-c | à juger | 01-p" "$(grep 'cycles/01-c' "$R24_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
if [ -n "$R24_SHA_AVANT" ] && [ "$R24_SHA_AVANT" = "$R24_SHA_APRES" ]; then
  ok "R24 sha256 de PLAN.md inchangé (P44-D-03)"
else
  ko "R24 sha256 PLAN.md" "$R24_SHA_AVANT" "$R24_SHA_APRES" "-"
fi
if cmp -s "$WORK/r24-cycles-avant.txt" "$WORK/r24-cycles-apres.txt"; then
  ok "R24 empreinte de .planning/cycles/ hors marqueur identique par recalcul (CLOTURE.md posé par le test, pas par le recalcul)"
else
  ok "R24 empreinte de .planning/cycles/ : CLOTURE.md posé par le test entre les deux recalculs (attendu), aucune AUTRE écriture du recalcul sous cycles/ (vérifié par R24-bis)"
fi
# R24-bis — le recalcul lui-même n'écrit RIEN sous cycles/ (empreinte prise juste avant/après le
# MÊME recalcul, sans poser CLOTURE.md entre les deux)
R24BIS_DIR="$WORK/r24bis"
materialiser etat-a-executer "$R24BIS_DIR"
empreinte "$R24BIS_DIR/.planning/cycles" > "$WORK/r24bis-avant.txt"
( cd "$R24BIS_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
empreinte "$R24BIS_DIR/.planning/cycles" > "$WORK/r24bis-apres.txt"
if cmp -s "$WORK/r24bis-avant.txt" "$WORK/r24bis-apres.txt"; then
  ok "R24-bis le recalcul n'écrit jamais sous .planning/cycles/"
else
  ko "R24-bis empreinte cycles/" "identique" "diverge" "-"
fi

# ---------- R25 — ordre des cycles dans INDEX.md ; cycle close sorti de l'index ------------------
R25_DIR="$WORK/r25"
materialiser cycles-ordre "$R25_DIR"
( cd "$R25_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r25-err.txt" )
R25_INDEX="$R25_DIR/.planning/INDEX.md"
LIGNE_PREMIER="$(grep -n 'cycles/01-premier' "$R25_INDEX" 2>/dev/null | head -1 | cut -d: -f1)"
LIGNE_SECOND="$(grep -n 'cycles/02-second' "$R25_INDEX" 2>/dev/null | head -1 | cut -d: -f1)"
if [ -n "$LIGNE_PREMIER" ] && [ -n "$LIGNE_SECOND" ] && [ "$LIGNE_PREMIER" -lt "$LIGNE_SECOND" ]; then
  ok "R25 cycles-ordre : 01-premier précède 02-second dans INDEX.md"
else
  ko "R25 ordre" "01-premier avant 02-second" "lignes $LIGNE_PREMIER / $LIGNE_SECOND" "-"
fi
R25C_DIR="$WORK/r25c"
materialiser cycle-close "$R25C_DIR"
( cd "$R25C_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r25c-err.txt" )
R25C_INDEX="$R25C_DIR/.planning/INDEX.md"
if ! grep -q '| cycles/01-c |' "$R25C_INDEX" 2>/dev/null && grep -qF 'Sortis de l'"'"'index (clos ou abandonnés) : cycles/01-c.' "$R25C_INDEX" 2>/dev/null; then
  ok "R25 cycle-close : pas de ligne de tableau, cité sur la ligne Sortis de l'index"
else
  ko "R25 cycle-close" "aucune ligne tableau + ligne Sortis de l'index" "$(cat "$R25C_INDEX" 2>/dev/null)" "-"
fi

# ---------- R26 — STATE.md porte cycle_courant: 01-premier ---------------------------------------
if grep -q '^cycle_courant: 01-premier$' "$R25_DIR/.planning/STATE.md" 2>/dev/null; then
  ok "R26 STATE.md cycle_courant: 01-premier"
else
  ko "R26 STATE.md" "cycle_courant: 01-premier" "$(cat "$R25_DIR/.planning/STATE.md" 2>/dev/null)" "-"
fi

# ---------- R27 — libellés lisibles distincts (INDEX.md et STATE.md, décision (a) 2026-09-28) ----
R27A_DIR="$WORK/r27a"
materialiser etat-a-clore "$R27A_DIR"
( cd "$R27A_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r27a-err.txt" )
R27B_DIR="$WORK/r27b"
materialiser d08-summary-sans-plan "$R27B_DIR"
( cd "$R27B_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r27b-err.txt" )
R27C_DIR="$WORK/r27c"
materialiser verdict-perime "$R27C_DIR"
( cd "$R27C_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r27c-err.txt" )
# 46-03 (P46-D-04) : « verdict passé, SUMMARY absent » est un état à part entière, `à clore` ; son ancien libellé n'existe plus.
if grep -qF '| cycles/01-c | à clore | 01-p |' "$R27A_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R27 INDEX.md (etat-a-clore) porte l'état « à clore » (phase courante 01-p)"
else
  ko "R27 INDEX.md libellé A" "| cycles/01-c | à clore | 01-p |" "$(cat "$R27A_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
if grep -qF 'SUMMARY.md sans PLAN.md' "$R27B_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R27 INDEX.md (d08-summary-sans-plan) contient « SUMMARY.md sans PLAN.md »"
else
  ko "R27 INDEX.md libellé B" "SUMMARY.md sans PLAN.md" "$(cat "$R27B_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
if ! grep -qF 'SUMMARY.md sans PLAN.md' "$R27A_DIR/.planning/INDEX.md" 2>/dev/null \
   && ! grep -qF 'à clore' "$R27B_DIR/.planning/INDEX.md" 2>/dev/null \
   && ! grep -qF 'verdict périmé' "$R27A_DIR/.planning/INDEX.md" "$R27B_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R27 les libellés sont distincts (jamais le même générique)"
else
  ko "R27 distinction des libellés" "les libellés diffèrent d'un lab à l'autre" "chevauchement détecté" "-"
fi
if grep -qF 'etat: à clore' "$R27A_DIR/.planning/STATE.md" 2>/dev/null; then
  ok "R27 STATE.md (etat-a-clore) porte l'état « à clore »"
else
  ko "R27 STATE.md libellé" "etat: à clore" "$(cat "$R27A_DIR/.planning/STATE.md" 2>/dev/null)" "-"
fi
if ! grep -qF 'verdict passé, SUMMARY absent' "$R27A_DIR/.planning/INDEX.md" "$R27A_DIR/.planning/STATE.md" 2>/dev/null \
   && ! grep -qF 'verdict-passe-sans-SUMMARY' "$R27A_DIR/.planning/INDEX.md" "$R27A_DIR/.planning/STATE.md" 2>/dev/null; then
  ok "R27 le libellé « verdict passé, SUMMARY absent » n'apparaît plus (INDEX.md, STATE.md)"
else
  ko "R27 ancien libellé" "absent de INDEX.md et STATE.md" "présent" "$(cat "$R27A_DIR/.planning/INDEX.md" 2>/dev/null)"
fi
# 46-03 (P46-D-03b) : la raison d'un `à juger` périmé se lit dans l'index et dans l'état.
if grep -qF '| cycles/01-c | à juger — verdict périmé : re-juger (tentative n+1) | 01-p |' "$R27C_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R27 INDEX.md (verdict-perime) porte « verdict périmé : re-juger (tentative n+1) »"
else
  ko "R27 INDEX.md verdict périmé" "à juger — verdict périmé : re-juger (tentative n+1)" "$(cat "$R27C_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
if grep -qF 'etat: à juger — verdict périmé : re-juger (tentative n+1)' "$R27C_DIR/.planning/STATE.md" 2>/dev/null; then
  ok "R27 STATE.md (verdict-perime) porte « verdict périmé : re-juger (tentative n+1) »"
else
  ko "R27 STATE.md verdict périmé" "etat: à juger — verdict périmé : re-juger (tentative n+1)" "$(cat "$R27C_DIR/.planning/STATE.md" 2>/dev/null)" "-"
fi
# Jumeau négatif : un `à juger` ordinaire (sans verdict) ne porte aucune raison dans l'index.
R27D_DIR="$WORK/r27d"
materialiser livrable-vide-jumeau "$R27D_DIR"
( cd "$R27D_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r27d-err.txt" )
if grep -qF '| cycles/01-c | à juger | 01-p |' "$R27D_DIR/.planning/INDEX.md" 2>/dev/null \
   && ! grep -qF 'verdict périmé' "$R27D_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R27 INDEX.md (jumeau, à juger sans verdict) ne porte aucune raison de péremption"
else
  ko "R27 jumeau à juger" "| cycles/01-c | à juger | 01-p | sans « verdict périmé »" "$(cat "$R27D_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi

# ---------- 46-03 — état « à clore », empreintes du verdict, R4 « absent ou vide » (P46-D-04, P46-D-03b, P46-D-12) -----
phase_etat_raison() { # <recalc.sh> <dossier du lab> -> « état|raison » de la phase 01-p ; ERREUR si le recalcul échoue
  local recalc="$1" dir="$2" sortie
  sortie="$WORK/per-courant.json"
  bash "$recalc" --planning="$dir/.planning" --read-only > "$sortie" 2>"$WORK/per-courant.err" || { echo "ERREUR"; return 0; }
  "$PYBIN" -c '
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    p = [ph for c in d["cycles"] for ph in c["phases"] if ph["nom"] == "01-p"][0]
    print(p["etat"] + "|" + str(p.get("raison") or ""))
except Exception:
    print("ERREUR")
' "$sortie"
}
cycle_etat_raison() { # <recalc.sh> <dossier du lab> -> « état|raison » du cycle 01-c
  local recalc="$1" dir="$2" sortie
  sortie="$WORK/per-courant.json"
  bash "$recalc" --planning="$dir/.planning" --read-only > "$sortie" 2>"$WORK/per-courant.err" || { echo "ERREUR"; return 0; }
  "$PYBIN" -c '
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    c = [c for c in d["cycles"] if c["nom"] == "01-c"][0]
    print(c["etat"] + "|" + str(c.get("raison") or ""))
except Exception:
    print("ERREUR")
' "$sortie"
}
verifier_etat() { # <id> <libellé> <recalc.sh> <lab du banc> <attendu « état|raison »>
  local id="$1" libelle="$2" recalc="$3" lab="$4" attendu="$5" dir obtenu
  dir="$WORK/per-lab-$lab"
  [ -d "$dir" ] || materialiser "$lab" "$dir"
  obtenu="$(phase_etat_raison "$recalc" "$dir")"
  if [ "$obtenu" = "$attendu" ]; then ok "$id $libelle ($lab : $attendu)"; else ko "$id $libelle" "état|raison de $lab" "$attendu" "$obtenu $(cat "$WORK/per-courant.err" 2>/dev/null)"; fi
}

# R-CLORE-01 — constats tous passé, deux empreintes conformes, SUMMARY.md absent : `à clore`, sans raison, non terminal.
verifier_etat R-CLORE-01 "état à clore" "$RECALC" etat-a-clore 'à clore|'
verifier_etat R-CLORE-01 "jumeau : le même verdict avec SUMMARY.md" "$RECALC" etat-a-clore-jumeau 'close|'
R_CLORE_CYCLE="$(cycle_etat_raison "$RECALC" "$WORK/per-lab-etat-a-clore")"
if [ "$R_CLORE_CYCLE" = 'à clore|' ]; then
  ok "R-CLORE-01 l'agrégat du cycle suit l'état non terminal (à clore, jamais indéterminé)"
else
  ko "R-CLORE-01 agrégat du cycle" "à clore|" "$R_CLORE_CYCLE" "-"
fi
R_CLORE_JSON="$WORK/per-lab-etat-a-clore-rapport.json"
bash "$RECALC" --planning="$WORK/per-lab-etat-a-clore/.planning" --read-only > "$R_CLORE_JSON" 2>/dev/null
R_CLORE_FAITS="$("$PYBIN" -c '
import json, sys
d = json.load(open(sys.argv[1]))
print("compte=%s journal=%d" % (d["compte_par_etat"].get("à clore"), len(d["cloture_a_ajouter"])))
' "$R_CLORE_JSON" 2>/dev/null || echo ERREUR)"
if [ "$R_CLORE_FAITS" = "compte=1 journal=0" ]; then
  ok "R-CLORE-01 compte_par_etat compte l'état et rien n'est journalisé (non terminal : aucune ligne de cloture.log)"
else
  ko "R-CLORE-01 compte et journal" "compte=1 journal=0" "$R_CLORE_FAITS" "-"
fi

# R-PERIME-01 — un écart d'empreinte, ou un hash_livrables absent, avant SUMMARY.md : `à juger` (verdict-perime).
verifier_etat R-PERIME-01 "hash_livrables littéral faux" "$RECALC" verdict-perime 'à juger|verdict-perime'
verifier_etat R-PERIME-01 "jumeau : empreintes conformes" "$RECALC" verdict-perime-jumeau 'à clore|'
verifier_etat R-PERIME-01 "hash_livrables absent" "$RECALC" verdict-sans-empreinte-livrables 'à juger|verdict-perime'
verifier_etat R-PERIME-01 "jumeau : hash_livrables présent" "$RECALC" verdict-sans-empreinte-livrables-jumeau 'à clore|'
verifier_etat R-PERIME-01 "hash du PLAN.md faux" "$RECALC" plan-modifie 'à juger|verdict-perime'
verifier_etat R-PERIME-01 "jumeau : hash du PLAN.md conforme" "$RECALC" plan-modifie-jumeau 'à clore|'
R_PERIME_CYCLE="$(cycle_etat_raison "$RECALC" "$WORK/per-lab-verdict-perime")"
if [ "$R_PERIME_CYCLE" = 'à juger|verdict-perime' ]; then
  ok "R-PERIME-01 le cycle remonte la raison verdict-perime de sa phase courante"
else
  ko "R-PERIME-01 raison du cycle" "à juger|verdict-perime" "$R_PERIME_CYCLE" "-"
fi
# Réécriture réelle : un livrable (ou le PLAN.md) change APRÈS la résolution du verdict ; un fichier non déclaré, jamais.
R_PERIME_VIVANT="$WORK/per-vivant-a-clore"
materialiser etat-a-clore "$R_PERIME_VIVANT"
printf 'Hors ecrit: du plan.\n' > "$R_PERIME_VIVANT/autre-fichier.md"
R_AVANT="$(phase_etat_raison "$RECALC" "$R_PERIME_VIVANT")"
printf 'Livrable non vide!\n' > "$R_PERIME_VIVANT/livrables/rapport.md"   # même taille que « Livrable non vide. » (+0 octet)
R_APRES_LIVRABLE="$(phase_etat_raison "$RECALC" "$R_PERIME_VIVANT")"
if [ "$R_AVANT" = 'à clore|' ] && [ "$R_APRES_LIVRABLE" = 'à juger|verdict-perime' ]; then
  ok "R-PERIME-01 un octet d'un livrable réécrit après la résolution : à clore -> à juger (verdict-perime)"
else
  ko "R-PERIME-01 réécriture du livrable" "à clore| puis à juger|verdict-perime" "$R_AVANT puis $R_APRES_LIVRABLE" "-"
fi
R_PERIME_JUMEAU="$WORK/per-vivant-jumeau"
materialiser etat-a-clore "$R_PERIME_JUMEAU"
printf 'Hors ecrit: du plan.\n' > "$R_PERIME_JUMEAU/autre-fichier.md"
printf 'Autre contenu hors plan.\n' > "$R_PERIME_JUMEAU/autre-fichier.md"   # réécrit : aucun `ecrit:` ne le couvre
R_APRES_AUTRE="$(phase_etat_raison "$RECALC" "$R_PERIME_JUMEAU")"
if [ "$R_APRES_AUTRE" = 'à clore|' ]; then
  ok "R-PERIME-01 jumeau : un fichier hors ecrit: réécrit ne périme pas le verdict (à clore)"
else
  ko "R-PERIME-01 jumeau fichier hors ecrit:" "à clore|" "$R_APRES_AUTRE" "-"
fi
R_PERIME_PLAN="$WORK/per-vivant-plan"
materialiser etat-a-clore "$R_PERIME_PLAN"
printf '\nPrécision ajoutée au plan après le verdict.\n' >> "$R_PERIME_PLAN/.planning/cycles/01-c/phases/01-p/PLAN.md"
R_APRES_PLAN="$(phase_etat_raison "$RECALC" "$R_PERIME_PLAN")"
if [ "$R_APRES_PLAN" = 'à juger|verdict-perime' ]; then
  ok "R-PERIME-01 le PLAN.md modifié après le verdict le périme (à juger, verdict-perime)"
else
  ko "R-PERIME-01 PLAN.md modifié" "à juger|verdict-perime" "$R_APRES_PLAN" "-"
fi
# Conséquence voulue (modele-cycles.md) : un verdict en échec suivi d'une correction du livrable repasse en `à juger`.
R_ECHEC_CORRIGE="$WORK/per-echec-corrige"
materialiser etat-a-corriger "$R_ECHEC_CORRIGE"
R_ECHEC_AVANT="$(phase_etat_raison "$RECALC" "$R_ECHEC_CORRIGE")"
printf 'Livrable corrigé.\n' > "$R_ECHEC_CORRIGE/livrables/rapport.md"
R_ECHEC_APRES="$(phase_etat_raison "$RECALC" "$R_ECHEC_CORRIGE")"
if [ "$R_ECHEC_AVANT" = 'à corriger|' ] && [ "$R_ECHEC_APRES" = 'à juger|verdict-perime' ]; then
  ok "R-PERIME-01 un verdict en échec suivi d'une correction du livrable : à corriger -> à juger (verdict-perime)"
else
  ko "R-PERIME-01 correction après échec" "à corriger| puis à juger|verdict-perime" "$R_ECHEC_AVANT puis $R_ECHEC_APRES" "-"
fi

# R-PERIME-02 — un écart d'empreinte avec SUMMARY.md présent : `indéterminé` (livrable-modifie-apres-cloture).
verifier_etat R-PERIME-02 "hash_livrables littéral faux, SUMMARY.md présent" "$RECALC" livrable-modifie-apres-cloture 'indéterminé|livrable-modifie-apres-cloture'
verifier_etat R-PERIME-02 "jumeau : empreintes conformes, SUMMARY.md présent" "$RECALC" livrable-modifie-apres-cloture-jumeau 'close|'
R_CLOS_VIVANT="$WORK/per-vivant-close"
materialiser etat-close "$R_CLOS_VIVANT"
R_CLOS_AVANT="$(phase_etat_raison "$RECALC" "$R_CLOS_VIVANT")"
printf 'Livrable de etat-close!\n' > "$R_CLOS_VIVANT/livrables/rapport.md"   # même taille que « Livrable de etat-close. »
R_CLOS_APRES="$(phase_etat_raison "$RECALC" "$R_CLOS_VIVANT")"
if [ "$R_CLOS_AVANT" = 'close|' ] && [ "$R_CLOS_APRES" = 'indéterminé|livrable-modifie-apres-cloture' ]; then
  ok "R-PERIME-02 un livrable réécrit après la clôture : close -> indéterminé (livrable-modifie-apres-cloture)"
else
  ko "R-PERIME-02 réécriture après clôture" "close| puis indéterminé|livrable-modifie-apres-cloture" "$R_CLOS_AVANT puis $R_CLOS_APRES" "-"
fi

# R-R4VIDE-01 — R4 par le prédicat partagé : absent ou vide ; un lien (jamais suivi) compte comme absent.
verifier_etat R-R4VIDE-01 "livrable de 0 octet" "$RECALC" livrable-vide 'indéterminé|livrable-vide:livrables/rapport.md'
verifier_etat R-R4VIDE-01 "jumeau : livrable non vide" "$RECALC" livrable-vide-jumeau 'à juger|'
verifier_etat R-R4VIDE-01 "livrable lien vers un fichier non vide" "$RECALC" livrable-lien 'indéterminé|livrable-absent:livrables/lien.md'
verifier_etat R-R4VIDE-01 "jumeau : fichier réel au même chemin" "$RECALC" livrable-lien-jumeau 'à juger|'
verifier_etat R-R4VIDE-01 "dossier sans aucun fichier" "$RECALC" livrable-dossier-vide 'indéterminé|livrable-vide:livrables/dossier'
verifier_etat R-R4VIDE-01 "jumeau : dossier avec un fichier non vide" "$RECALC" livrable-dossier-vide-jumeau 'à juger|'
verifier_etat R-R4VIDE-01 "dossier avec le seul .DS_Store (exclusion fixe)" "$RECALC" livrable-dossier-ds-store 'indéterminé|livrable-vide:livrables/dossier'
verifier_etat R-R4VIDE-01 "jumeau : un fichier ordinaire à côté du .DS_Store" "$RECALC" livrable-dossier-ds-store-jumeau 'à juger|'

# ---------- quick 261003-ps1 — R4 par la chaîne unique du bloc partagé (`entrees_du_plan`, `livrables_presents`) ----------------
# Copies matérialisées du lab de banc `livrable-vide-jumeau` (état `à juger`, unité de phase 01-p, CLOTURE.md présent), PLAN.md
# réécrit dans la suite : le banc de fixtures n'est pas touché.
UNITE_01P=".planning/cycles/01-c/phases/01-p"
ecrire_plan_ecrit() { # <dossier du lab> <entrée> : réécrit le PLAN.md de l'unité 01-p avec une seule entrée `ecrit:`
  printf '%s\n' '---' "ecrit: $2" '---' > "$1/$UNITE_01P/PLAN.md"
}
ecrire_fichiers() { # <dossier> <nombre> : <nombre> fichiers non vides dans <dossier>
  "$PYBIN" -c '
import os, sys
base, n = sys.argv[1], int(sys.argv[2])
os.makedirs(base, exist_ok=True)
for i in range(n):
    with open(os.path.join(base, "f%04d.txt" % i), "w") as fh:
        fh.write("x")
' "$1" "$2"
}
verifier_copie() { # <id> <libellé> <dossier du lab> <attendu « état|raison »>
  local obtenu
  obtenu="$(phase_etat_raison "$RECALC" "$3")"
  if [ "$obtenu" = "$4" ]; then ok "$1 $2 ($4)"; else ko "$1 $2" "état|raison de la phase 01-p" "$4" "$obtenu $(cat "$WORK/per-courant.err" 2>/dev/null)"; fi
}

# R-UNITE-01 — une entrée `ecrit:` qui est ou contient le dossier de l'unité (unité à CLOTURE.md) : R4 rend
# `ecrit-contient-unite:<entrée>` (la pose la refuse : décision du manager, renversable) ; sans CLOTURE.md, R3 décide.
R_UNITE_A="$WORK/r-unite-a"
materialiser livrable-vide-jumeau "$R_UNITE_A"
ecrire_plan_ecrit "$R_UNITE_A" "$UNITE_01P"
verifier_copie R-UNITE-01 "ecrit: = le dossier de l'unité, CLOTURE.md présent" "$R_UNITE_A" "indéterminé|ecrit-contient-unite:$UNITE_01P"
R_UNITE_B="$WORK/r-unite-b"
materialiser livrable-vide-jumeau "$R_UNITE_B"
ecrire_plan_ecrit "$R_UNITE_B" ".planning"
verifier_copie R-UNITE-01 "ecrit: .planning (ancêtre de l'unité), CLOTURE.md présent" "$R_UNITE_B" 'indéterminé|ecrit-contient-unite:.planning'
R_UNITE_C="$WORK/r-unite-c"
materialiser livrable-vide-jumeau "$R_UNITE_C"
ecrire_plan_ecrit "$R_UNITE_C" "$UNITE_01P"
rm -f "$R_UNITE_C/$UNITE_01P/CLOTURE.md"
verifier_copie R-UNITE-01 "jumeau : même entrée, CLOTURE.md retiré (R3 décide)" "$R_UNITE_C" 'à exécuter|'
R_UNITE_D="$WORK/r-unite-d"
materialiser livrable-vide-jumeau "$R_UNITE_D"
ecrire_plan_ecrit "$R_UNITE_D" "$UNITE_01P/notes.md"
printf '%s\n' 'Notes de l unité.' > "$R_UNITE_D/$UNITE_01P/notes.md"
verifier_copie R-UNITE-01 "jumeau : entrée DANS l'unité (fichier non vide)" "$R_UNITE_D" 'à juger|'

# R-R4BORNE-01 — budget COMMUN à toutes les entrées d'un PLAN.md : deux entrées chacune sous la borne réelle (2000 entrées) dont la
# somme la dépasse rendent `livrable-hors-borne:<seconde entrée>` ; 250 entrées imbriquées ne coûtent pas 250 parcours.
R_BORNE_A="$WORK/r-r4borne-a"
materialiser livrable-vide-jumeau "$R_BORNE_A"
printf '%s\n' '---' 'ecrit:' '  - livrables/a' '  - livrables/b' '---' > "$R_BORNE_A/$UNITE_01P/PLAN.md"
ecrire_fichiers "$R_BORNE_A/livrables/a" 1000
ecrire_fichiers "$R_BORNE_A/livrables/b" 1001
verifier_copie R-R4BORNE-01 "1000 + 1001 fichiers sur deux entrées (borne 2000)" "$R_BORNE_A" 'indéterminé|livrable-hors-borne:livrables/b'
R_BORNE_B="$WORK/r-r4borne-b"
materialiser livrable-vide-jumeau "$R_BORNE_B"
printf '%s\n' '---' 'ecrit:' '  - livrables/a' '  - livrables/b' '---' > "$R_BORNE_B/$UNITE_01P/PLAN.md"
ecrire_fichiers "$R_BORNE_B/livrables/a" 1000
ecrire_fichiers "$R_BORNE_B/livrables/b" 1000
verifier_copie R-R4BORNE-01 "jumeau : 1000 + 1000 fichiers (à la borne)" "$R_BORNE_B" 'à juger|'
R_BORNE_C="$WORK/r-r4borne-c"
materialiser livrable-vide-jumeau "$R_BORNE_C"
"$PYBIN" -c '
import os, sys
lab, plan = sys.argv[1], sys.argv[2]
rel, entrees = "", []
for _i in range(250):
    rel = rel + "/a" if rel else "a"
    entrees.append(rel)
os.makedirs(os.path.join(lab, rel))
for i in range(1600):
    with open(os.path.join(lab, rel, "f%04d" % i), "w") as fh:
        fh.write("x")
with open(plan, "w") as fh:
    fh.write("---\necrit:\n" + "".join("  - %s\n" % e for e in entrees) + "---\n")
' "$R_BORNE_C" "$R_BORNE_C/$UNITE_01P/PLAN.md"
R_BORNE_T0="$(date +%s)"
R_BORNE_P4="$(phase_etat_raison "$RECALC" "$R_BORNE_C")"
R_BORNE_DUREE=$(( $(date +%s) - R_BORNE_T0 ))
if [ "$R_BORNE_P4" = 'indéterminé|livrable-hors-borne:a/a' ]; then
  ok "R-R4BORNE-01 cas p4 : 250 entrées imbriquées et 1600 fichiers -> indéterminé|livrable-hors-borne:a/a (durée indicative ${R_BORNE_DUREE} s)"
else
  ko "R-R4BORNE-01 cas p4" "état|raison de la phase 01-p" 'indéterminé|livrable-hors-borne:a/a' "$R_BORNE_P4 $(cat "$WORK/per-courant.err" 2>/dev/null)"
fi

# R-JETON-01 — un jeton du banc qui ne se résout pas fait échouer le lab avec un message nommé (jamais une substitution vide).
R_JETON_BANC="$WORK/banc-jeton.txt"
cat > "$R_JETON_BANC" <<'JETON_BANC_EOF'
@@ lab jeton-sans-plan

@@ fichier .planning/config.json
{"planning_version": "cycles-v1"}

@@ fichier .planning/cycles/01-c/phases/01-p/VERDICT.md
---
juge: relecteur-banc
hash: {{sha256-plan}}
hash_livrables: {{empreinte-livrables}}
tentative: 1
constats:
  - resultat: passé
---

@@ attendu cycles/01-c :: à cadrer
@@ lab jeton-livrable-absent

@@ fichier .planning/config.json
{"planning_version": "cycles-v1"}

@@ fichier .planning/cycles/01-c/phases/01-p/PLAN.md
---
ecrit: livrables/inexistant.md
---

@@ fichier .planning/cycles/01-c/phases/01-p/VERDICT.md
---
juge: relecteur-banc
hash: {{sha256-plan}}
hash_livrables: {{empreinte-livrables}}
tentative: 1
constats:
  - resultat: passé
---

@@ attendu cycles/01-c :: à cadrer
JETON_BANC_EOF
R_JETON_OUT="$WORK/banc-jeton-out.txt"
"$PYBIN" "$AIDES_PY" coureur "$R_JETON_BANC" "$WORK/r-jeton" "$RECALC" > "$R_JETON_OUT" 2>&1
R_JETON_RC=$?
if [ "$R_JETON_RC" -eq 1 ] \
   && grep -qF '✗ BANC jeton-sans-plan : jeton du banc non résolu : PLAN.md voisin absent de .planning/cycles/01-c/phases/01-p/VERDICT.md' "$R_JETON_OUT" \
   && grep -qF '✗ BANC jeton-livrable-absent : jeton du banc non résolu : empreinte des livrables absent (livrables/inexistant.md)' "$R_JETON_OUT"; then
  ok "R-JETON-01 un jeton non résolu (PLAN.md voisin absent, livrable absent) fait échouer le lab avec un message nommé"
else
  ko "R-JETON-01 jeton non résolu" "code 1 et deux lignes ✗ BANC nommées" "code=$R_JETON_RC $(tr '\n' ' ' < "$R_JETON_OUT")" "-"
fi

# ================================================================================================
# 44-04 Tâche 1 — hors modèle et garde-fous de chemin (R40 à R46)
# ================================================================================================

# ---------- R40 — hors modèle à la racine (annexes exclues, intrus listés) ------------------------
R40_DIR="$WORK/r40"
materialiser hors-modele-racine "$R40_DIR"
( cd "$R40_DIR" && bash "$RECALC" --read-only > "$WORK/r40-out.json" 2>"$WORK/r40-err.txt" )
R40_RC=$?
printf '%s' '[{"chemin":"BOARD.md","type":"fichier"},{"chemin":"intel","type":"fichier"},{"chemin":"notes.md","type":"fichier"},{"chemin":"phases","type":"dossier"},{"chemin":"workstreams","type":"dossier"}]' > "$WORK/r40-attendu.json"
if [ "$R40_RC" -eq 0 ] && "$PYBIN" "$AIDES_PY" verifier-hors-modele "$WORK/r40-out.json" "$WORK/r40-attendu.json" >"$WORK/r40-verif.txt" 2>&1; then
  ok "R40 hors modèle à la racine : cinq intrus listés avec leur type, les six annexes absentes"
else
  ko "R40 hors_modele racine" "BOARD.md/intel/notes.md (fichier), phases/workstreams (dossier)" "rc=$R40_RC $(cat "$WORK/r40-verif.txt" 2>/dev/null) $(cat "$WORK/r40-err.txt" 2>/dev/null)" "-"
fi

# ---------- R41 — hors modèle dans l'arbre cycles/ ; un intrus ne change aucun état ---------------
R41_DIR="$WORK/r41"
materialiser hors-modele-interne "$R41_DIR"
( cd "$R41_DIR" && bash "$RECALC" --read-only > "$WORK/r41-out.json" 2>"$WORK/r41-err.txt" )
R41_RC=$?
printf '%s' '[{"chemin":"cycles/01-c/notes.md","type":"fichier"},{"chemin":"cycles/01-c/phases/01-p/brouillon.md","type":"fichier"},{"chemin":"cycles/01-c/phases/02-q/plans/01-x/annexe.txt","type":"fichier"},{"chemin":"cycles/brouillon.md","type":"fichier"},{"chemin":"cycles/sans-numero","type":"dossier"}]' > "$WORK/r41-attendu.json"
if [ "$R41_RC" -eq 0 ] && "$PYBIN" "$AIDES_PY" verifier-hors-modele "$WORK/r41-out.json" "$WORK/r41-attendu.json" >"$WORK/r41-verif.txt" 2>&1; then
  ok "R41 hors modèle dans l'arbre cycles/ : cinq intrus listés, triés (0 < b < s en ASCII)"
else
  ko "R41 hors_modele arbre" "cinq entrées triées" "rc=$R41_RC $(cat "$WORK/r41-verif.txt" 2>/dev/null) $(cat "$WORK/r41-err.txt" 2>/dev/null)" "-"
fi
R41J_DIR="$WORK/r41j"
materialiser hors-modele-interne-jumeau "$R41J_DIR"
( cd "$R41J_DIR" && bash "$RECALC" --read-only > "$WORK/r41j-out.json" 2>"$WORK/r41j-err.txt" )
R41_ETATS_EGAUX="$("$PYBIN" -c '
import json, sys
a = json.load(open(sys.argv[1]))
b = json.load(open(sys.argv[2]))
def etats(d):
    r = {}
    for c in d["cycles"]:
        r[c["chemin"]] = c["etat"]
        for p in c["phases"]:
            r[p["chemin"]] = p["etat"]
            for pl in p.get("plans", []):
                r[pl["chemin"]] = pl["etat"]
    return r
print(etats(a) == etats(b))
' "$WORK/r41-out.json" "$WORK/r41j-out.json" 2>/dev/null || echo '?')"
if [ "$R41_ETATS_EGAUX" = "True" ]; then
  ok "R41 les intrus internes ne changent aucun état (identiques au jumeau sans intrus)"
else
  ko "R41 états identiques au jumeau" "True" "$R41_ETATS_EGAUX" "-"
fi

# ---------- R42 — emplacement du modèle du mauvais type : hors modèle en lecture, refus en écriture
R42_DIR="$WORK/r42"
materialiser modele-mauvais-type "$R42_DIR"
( cd "$R42_DIR" && bash "$RECALC" --read-only > "$WORK/r42-out.json" 2>"$WORK/r42-err.txt" )
R42_RC=$?
printf '%s' '[{"chemin":"cycles","type":"fichier"},{"chemin":"INDEX.md","type":"dossier"}]' > "$WORK/r42-attendu.json"
if [ "$R42_RC" -eq 0 ] && "$PYBIN" "$AIDES_PY" verifier-hors-modele "$WORK/r42-out.json" "$WORK/r42-attendu.json" >"$WORK/r42-verif.txt" 2>&1; then
  ok "R42 lecture seule : cycles (fichier) et INDEX.md (dossier) tous deux hors modèle"
else
  ko "R42 hors_modele lecture seule" "cycles (fichier), INDEX.md (dossier)" "rc=$R42_RC $(cat "$WORK/r42-verif.txt" 2>/dev/null) $(cat "$WORK/r42-err.txt" 2>/dev/null)" "-"
fi
R42_NB_CYCLES="$("$PYBIN" -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["cycles"]))' "$WORK/r42-out.json" 2>/dev/null || echo '?')"
if [ "$R42_NB_CYCLES" = "0" ]; then
  ok "R42 lecture seule : aucun cycle dérivé (cycles est un fichier)"
else
  ko "R42 nombre de cycles" "0" "$R42_NB_CYCLES" "-"
fi
R42W_DIR="$WORK/r42w"
materialiser modele-mauvais-type "$R42W_DIR"
empreinte "$R42W_DIR" > "$WORK/r42w-avant.txt"
( cd "$R42W_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r42w-out.txt" 2>"$WORK/r42w-err.txt" )
R42W_RC=$?
empreinte "$R42W_DIR" > "$WORK/r42w-apres.txt"
if [ "$R42W_RC" -eq 1 ]; then ok "R42 écriture : code de sortie 1"; else ko "R42 écriture code" "1" "$R42W_RC" "$(cat "$WORK/r42w-out.txt")"; fi
if grep -qF "INDEX.md" "$WORK/r42w-err.txt" 2>/dev/null && grep -q "emplacement occupé" "$WORK/r42w-err.txt" 2>/dev/null; then
  ok "R42 écriture : stderr nomme le chemin fautif (INDEX.md)"
else
  ko "R42 écriture stderr" "emplacement occupé ... INDEX.md" "$(cat "$WORK/r42w-err.txt" 2>/dev/null)" "-"
fi
if cmp -s "$WORK/r42w-avant.txt" "$WORK/r42w-apres.txt"; then
  ok "R42 écriture : empreinte du lab identique avant/après (rien écrit)"
else
  ko "R42 écriture empreinte" "identique" "diverge" "-"
fi

# ---------- R43 — lien de dossier jamais suivi (cycles/02-lien) -----------------------------------
R43_DIR="$WORK/r43"
materialiser lien-dossier-cycle "$R43_DIR"
( cd "$R43_DIR" && bash "$RECALC" --read-only > "$WORK/r43-out.json" 2>"$WORK/r43-err.txt" )
R43_RC=$?
printf '%s' '[{"chemin":"cycles/02-lien","type":"lien"}]' > "$WORK/r43-attendu.json"
if [ "$R43_RC" -eq 0 ] && "$PYBIN" "$AIDES_PY" verifier-hors-modele "$WORK/r43-out.json" "$WORK/r43-attendu.json" >"$WORK/r43-verif.txt" 2>&1; then
  ok "R43 cycles/02-lien (lien vers un dossier) hors modèle, jamais suivi"
else
  ko "R43 hors_modele" "cycles/02-lien (lien)" "rc=$R43_RC $(cat "$WORK/r43-verif.txt" 2>/dev/null) $(cat "$WORK/r43-err.txt" 2>/dev/null)" "-"
fi
R43_UNITE_ABSENTE="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(not any(c["chemin"]=="cycles/02-lien" for c in d["cycles"]))' "$WORK/r43-out.json" 2>/dev/null || echo '?')"
if [ "$R43_UNITE_ABSENTE" = "True" ]; then
  ok "R43 aucune unité cycles/02-lien dans le JSON (jamais parcouru)"
else
  ko "R43 unité cycles/02-lien" "absente du JSON" "$R43_UNITE_ABSENTE" "-"
fi

# ---------- R44 — lien de fichier jamais suivi (PLAN.md) ------------------------------------------
R44_DIR="$WORK/r44"
materialiser lien-fichier-plan "$R44_DIR"
( cd "$R44_DIR" && bash "$RECALC" --read-only > "$WORK/r44-out.json" 2>"$WORK/r44-err.txt" )
R44_RC=$?
R44_ETAT="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/r44-out.json" 2>/dev/null || echo '?')"
R44_RAISON="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["raison"])' "$WORK/r44-out.json" 2>/dev/null || echo '?')"
if [ "$R44_RC" -eq 0 ] && [ "$R44_ETAT" = "indéterminé" ] && [ "$R44_RAISON" = "fichier-non-regulier:PLAN.md" ]; then
  ok "R44 PLAN.md en lien vers un fichier : indéterminé (fichier-non-regulier:PLAN.md), jamais suivi"
else
  ko "R44 état/raison" "indéterminé / fichier-non-regulier:PLAN.md" "rc=$R44_RC état=$R44_ETAT raison=$R44_RAISON" "-"
fi
if grep -q "JETON-DEHORS-44" "$WORK/r44-out.json" 2>/dev/null; then
  ko "R44 jeton" "absent du JSON" "présent" "-"
else
  ok "R44 jeton JETON-DEHORS-44 absent du JSON (contenu jamais lu)"
fi

# ---------- R45 — nom d'unité à saut de ligne et accent grave : une entrée, échappée --------------
# Le nom piégé ne s'écrit jamais dans le banc texte (un saut de ligne littéral y casserait le
# format une-directive-par-ligne) : lab construit directement ici, comme prescrit par le plan.
R45_NOM=$'01-x\n`y'
R45_DIR="$WORK/r45"
mkdir -p "$R45_DIR/.planning/cycles/$R45_NOM"
printf '%s' '{"planning_version": "cycles-v1"}' > "$R45_DIR/.planning/config.json"
( cd "$R45_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r45-out.txt" 2>"$WORK/r45-err.txt" )
R45_RC=$?
if [ "$R45_RC" -eq 0 ]; then ok "R45 code de sortie 0"; else ko "R45 code" "0" "$R45_RC" "$(cat "$WORK/r45-err.txt")"; fi
if grep -qF '\u000a' "$R45_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R45 INDEX.md porte le nom échappé (\\u000a littéral, jamais un saut de ligne brut)"
else
  ko "R45 INDEX.md échappement" 'contient \u000a' "$(cat "$R45_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
R45_LIGNES_TOTAL="$(wc -l < "$R45_DIR/.planning/INDEX.md" 2>/dev/null | tr -d ' ')"
if [ "$R45_LIGNES_TOTAL" = "11" ]; then
  ok "R45 INDEX.md tient sur 11 lignes (le saut de ligne du nom ne casse pas le format)"
else
  ko "R45 lignes INDEX.md" "11" "$R45_LIGNES_TOTAL" "-"
fi
if [ ! -f "$R45_DIR/.planning/cloture.log" ]; then
  ok "R45 cloture.log inchangé (aucune unité close, le nom piégé n'y atteint jamais)"
else
  ko "R45 cloture.log" "absent (aucune clôture observée)" "$(cat "$R45_DIR/.planning/cloture.log" 2>/dev/null)" "-"
fi

# ---------- R46 — rendu de INDEX.md en écriture : une ligne par entrée / "_Aucune entrée._" -------
R46A_DIR="$WORK/r46a"
materialiser hors-modele-racine "$R46A_DIR"
( cd "$R46A_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r46a-out.txt" 2>"$WORK/r46a-err.txt" )
if grep -q '^## Hors modèle$' "$R46A_DIR/.planning/INDEX.md" 2>/dev/null \
   && [ "$(grep -c '^- ' "$R46A_DIR/.planning/INDEX.md" 2>/dev/null)" -eq 5 ]; then
  ok "R46 lab porteur d'intrus : ## Hors modèle suivi de cinq lignes (une par entrée)"
else
  ko "R46 rendu avec intrus" "## Hors modèle + 5 lignes" "$(cat "$R46A_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
R46B_DIR="$WORK/r46b"
materialiser hors-modele-interne-jumeau "$R46B_DIR"
( cd "$R46B_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r46b-out.txt" 2>"$WORK/r46b-err.txt" )
if grep -qF '_Aucune entrée._' "$R46B_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R46 lab sans intrus : ## Hors modèle porte _Aucune entrée._"
else
  ko "R46 rendu sans intrus" "_Aucune entrée._" "$(cat "$R46B_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi

# ================================================================================================
# 44-04 Tâche 2 — incrémental par hash du contenu (R50 à R58)
# ================================================================================================

# ---------- R50 — premier recalcul en écriture : cache absent, tout recalculé ---------------------
R50_DIR="$WORK/r50"
materialiser traceur "$R50_DIR"
( cd "$R50_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r50-out.json" 2>"$WORK/r50-err.txt" )
R50_RC=$?
R50_CACHE="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cache"])' "$WORK/r50-out.json" 2>/dev/null || echo '?')"
R50_UNITES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites"])' "$WORK/r50-out.json" 2>/dev/null || echo '?')"
R50_RECALCULEES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/r50-out.json" 2>/dev/null || echo '?')"
R50_ECRITS_CACHE="$("$PYBIN" -c 'import json,sys; print(".recalc-cache.json" in json.load(open(sys.argv[1]))["ecrits"])' "$WORK/r50-out.json" 2>/dev/null || echo '?')"
if [ "$R50_RC" -eq 0 ] && [ "$R50_CACHE" = "absent" ] && [ "$R50_UNITES" = "$R50_RECALCULEES" ] && [ -f "$R50_DIR/.planning/.recalc-cache.json" ] && [ "$R50_ECRITS_CACHE" = "True" ]; then
  ok "R50 premier recalcul : cache absent, unites_recalculees = unites ($R50_UNITES), .recalc-cache.json créé et listé dans ecrits"
else
  ko "R50 premier recalcul" "cache=absent, recalculees=unites, cache créé+listé" "rc=$R50_RC cache=$R50_CACHE unites=$R50_UNITES recalculees=$R50_RECALCULEES ecrits_cache=$R50_ECRITS_CACHE" "-"
fi

# ---------- R51 — second recalcul : cache valide, tout repris -------------------------------------
( cd "$R50_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r51-out.json" 2>"$WORK/r51-err.txt" )
R51_RC=$?
R51_CACHE="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cache"])' "$WORK/r51-out.json" 2>/dev/null || echo '?')"
R51_REPRISES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_reprises"])' "$WORK/r51-out.json" 2>/dev/null || echo '?')"
R51_RECALCULEES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/r51-out.json" 2>/dev/null || echo '?')"
R51_ECRITS="$("$PYBIN" -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["ecrits"]))' "$WORK/r51-out.json" 2>/dev/null || echo '?')"
if [ "$R51_RC" -eq 0 ] && [ "$R51_CACHE" = "valide" ] && [ "$R51_REPRISES" = "$R50_UNITES" ] && [ "$R51_RECALCULEES" = "0" ] && [ "$R51_ECRITS" = "0" ]; then
  ok "R51 second recalcul : cache valide, unites_reprises = unites ($R50_UNITES), unites_recalculees 0, ecrits vide"
else
  ko "R51 second recalcul" "cache=valide, reprises=unites, recalculees=0, ecrits=0" "rc=$R51_RC cache=$R51_CACHE reprises=$R51_REPRISES recalculees=$R51_RECALCULEES ecrits=$R51_ECRITS" "-"
fi

# ---------- R52 — touch de tous les fichiers du modèle, contenu inchangé : rien recalculé ---------
for f in CADRAGE.md PLAN.md CLOTURE.md VERDICT.md SUMMARY.md; do
  cp "$R50_DIR/.planning/cycles/01-traceur/phases/01-livree/$f" "$WORK/r52-ref-$f"
  touch "$R50_DIR/.planning/cycles/01-traceur/phases/01-livree/$f"
done
cp "$R50_DIR/.planning/INDEX.md" "$WORK/r52-index-avant.md"
cp "$R50_DIR/.planning/STATE.md" "$WORK/r52-state-avant.md"
cp "$R50_DIR/.planning/cloture.log" "$WORK/r52-cloture-avant.log"
cp "$R50_DIR/.planning/.recalc-cache.json" "$WORK/r52-cache-avant.json"
( cd "$R50_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r52-out.json" 2>"$WORK/r52-err.txt" )
R52_RC=$?
R52_RECALCULEES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/r52-out.json" 2>/dev/null || echo '?')"
if [ "$R52_RC" -eq 0 ] && [ "$R52_RECALCULEES" = "0" ]; then
  ok "R52 touch sans changement de contenu : unites_recalculees 0"
else
  ko "R52 recalculees" "0" "rc=$R52_RC recalculees=$R52_RECALCULEES" "-"
fi
if cmp -s "$WORK/r52-index-avant.md" "$R50_DIR/.planning/INDEX.md" \
   && cmp -s "$WORK/r52-state-avant.md" "$R50_DIR/.planning/STATE.md" \
   && cmp -s "$WORK/r52-cloture-avant.log" "$R50_DIR/.planning/cloture.log" \
   && cmp -s "$WORK/r52-cache-avant.json" "$R50_DIR/.planning/.recalc-cache.json"; then
  ok "R52 INDEX.md/STATE.md/cloture.log/.recalc-cache.json identiques octet pour octet"
else
  ko "R52 identité octet pour octet" "les quatre fichiers identiques" "au moins un diffère" "-"
fi

# ---------- R53 — contenu changé (passé -> échec, même taille), mtime restauré : vu et recalculé --
R53_VERDICT="$R50_DIR/.planning/cycles/01-traceur/phases/01-livree/VERDICT.md"
cp "$R53_VERDICT" "$WORK/r53-verdict-ref.md"
"$PYBIN" -c "
p = '$R53_VERDICT'
t = open(p, encoding='utf-8').read()
assert 'resultat: passé' in t, t
t2 = t.replace('resultat: passé', 'resultat: échec')
assert len(t.encode('utf-8')) == len(t2.encode('utf-8')), (len(t.encode('utf-8')), len(t2.encode('utf-8')))
open(p, 'w', encoding='utf-8').write(t2)
"
touch -r "$WORK/r53-verdict-ref.md" "$R53_VERDICT"
( cd "$R50_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r53-out.json" 2>"$WORK/r53-err.txt" )
R53_RC=$?
R53_RECALCULEES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/r53-out.json" 2>/dev/null || echo '?')"
if [ "$R53_RC" -eq 0 ] && [ "$R53_RECALCULEES" -ge 1 ] 2>/dev/null; then
  ok "R53 contenu changé à mtime restauré : unites_recalculees >= 1 ($R53_RECALCULEES)"
else
  ko "R53 recalculees" ">= 1" "rc=$R53_RC recalculees=$R53_RECALCULEES" "-"
fi
R53_LIGNE_ATTENDUE='indéterminé — phase `01-livree` indéterminée : SUMMARY.md avec un verdict en échec (cycles/01-traceur)'
if grep -qF "$R53_LIGNE_ATTENDUE" "$R50_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R53 INDEX.md porte le libellé imbriqué exact (SUMMARY.md avec un verdict en échec)"
else
  ko "R53 libellé INDEX.md" "$R53_LIGNE_ATTENDUE" "$(cat "$R50_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
# Contrôle croisé : un recalcul COMPLET (sans cache préalable) sur le même contenu édité rend la
# MÊME ligne — la reprise partielle du cache n'invente jamais une sortie que le recalcul complet
# ne produirait pas.
R53_TEMOIN_DIR="$WORK/r53-temoin"
materialiser traceur "$R53_TEMOIN_DIR"
cp "$R53_VERDICT" "$R53_TEMOIN_DIR/.planning/cycles/01-traceur/phases/01-livree/VERDICT.md"
( cd "$R53_TEMOIN_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
if grep -qF "$R53_LIGNE_ATTENDUE" "$R53_TEMOIN_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R53 un recalcul complet sans cache rend la même ligne (le cache n'invente aucune sortie)"
else
  ko "R53 témoin sans cache" "$R53_LIGNE_ATTENDUE" "$(cat "$R53_TEMOIN_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi

# ---------- R54 — cache non JSON : illisible, recalcul complet ------------------------------------
# Comparaison à l'INDEX.md du MÊME lab (jamais d'un autre) : le dédoublonnage de cloture.log fait
# que l'horodatage de « Dernier signe de vie » reste stable d'un passage à l'autre SUR LE MÊME
# lab (couple verdict/tentative inchangé) — comparer à un AUTRE lab ferait diverger sur l'horodatage
# seul, un faux négatif sans rapport avec le cache.
R54_DIR="$WORK/r54"
materialiser traceur "$R54_DIR"
( cd "$R54_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
cp "$R54_DIR/.planning/INDEX.md" "$WORK/r54-index-premier-passage.md"
printf 'ceci n'"'"'est pas du JSON' > "$R54_DIR/.planning/.recalc-cache.json"
( cd "$R54_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r54-out.json" 2>"$WORK/r54-err.txt" )
R54_RC=$?
R54_CACHE="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cache"])' "$WORK/r54-out.json" 2>/dev/null || echo '?')"
if [ "$R54_RC" -eq 0 ] && [ "$R54_CACHE" = "illisible" ]; then
  ok "R54 cache non JSON : statut illisible, recalcul complet"
else
  ko "R54 cache" "illisible" "rc=$R54_RC cache=$R54_CACHE" "-"
fi
if cmp -s "$WORK/r54-index-premier-passage.md" "$R54_DIR/.planning/INDEX.md"; then
  ok "R54 INDEX.md identique à celui d'un passage à cache valide (même lab)"
else
  ko "R54 INDEX.md" "identique au premier passage du même lab" "$(diff "$WORK/r54-index-premier-passage.md" "$R54_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi

# ---------- R55 — cache_schema_version 999 puis absent : autre-format, recalcul complet -----------
R55_DIR="$WORK/r55"
materialiser traceur "$R55_DIR"
( cd "$R55_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
"$PYBIN" -c "
import json
p = '$R55_DIR/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
d['cache_schema_version'] = 999
json.dump(d, open(p, 'w', encoding='utf-8'))
"
( cd "$R55_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r55a-out.json" 2>"$WORK/r55a-err.txt" )
R55A_RC=$?
R55A_CACHE="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cache"])' "$WORK/r55a-out.json" 2>/dev/null || echo '?')"
"$PYBIN" -c "
import json
p = '$R55_DIR/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
del d['cache_schema_version']
json.dump(d, open(p, 'w', encoding='utf-8'))
"
( cd "$R55_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r55b-out.json" 2>"$WORK/r55b-err.txt" )
R55B_RC=$?
R55B_CACHE="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cache"])' "$WORK/r55b-out.json" 2>/dev/null || echo '?')"
if [ "$R55A_RC" -eq 0 ] && [ "$R55A_CACHE" = "autre-format" ] && [ "$R55B_RC" -eq 0 ] && [ "$R55B_CACHE" = "autre-format" ]; then
  ok "R55 cache_schema_version 999 puis absent : autre-format les deux fois, recalcul complet"
else
  ko "R55 cache" "autre-format, autre-format" "rc=$R55A_RC/$R55B_RC cache=$R55A_CACHE/$R55B_CACHE" "-"
fi

# ---------- R56 — cache en lien symbolique hors du lab : écriture refusée, cible inchangée -------
# Avant F4 (audit B), .recalc-cache.json n'était PAS dans la liste des emplacements vérifiés par
# appliquer_ecritures : le lien était silencieusement remplacé par un fichier régulier (rc=0).
# Depuis F4, .recalc-cache.json reçoit le même traitement que INDEX.md/STATE.md/cloture.log — un
# lien à cet emplacement refuse TOUTE l'écriture (rc=1), rien n'est touché, la cible hors lab reste
# intacte.
R56_DIR="$WORK/r56"
materialiser traceur "$R56_DIR"
( cd "$R56_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
R56_CIBLE="$WORK/r56-cible-hors-lab.json"
cp "$R56_DIR/.planning/.recalc-cache.json" "$R56_CIBLE"
cp "$R56_CIBLE" "$WORK/r56-cible-avant.json"
cp "$R56_DIR/.planning/INDEX.md" "$WORK/r56-index-avant.md"
cp "$R56_DIR/.planning/STATE.md" "$WORK/r56-state-avant.md"
rm -f "$R56_DIR/.planning/.recalc-cache.json"
ln -s "$R56_CIBLE" "$R56_DIR/.planning/.recalc-cache.json"
( cd "$R56_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r56-out.json" 2>"$WORK/r56-err.txt" )
R56_RC=$?
if [ "$R56_RC" -eq 1 ]; then
  ok "R56 cache en lien symbolique : écriture refusée (rc=1, F4)"
else
  ko "R56 code de sortie" "1" "$R56_RC" "$(cat "$WORK/r56-out.json" 2>/dev/null)"
fi
if grep -qF "emplacement occupé par autre chose qu'un fichier régulier" "$WORK/r56-err.txt" && grep -qF ".recalc-cache.json" "$WORK/r56-err.txt"; then
  ok "R56 stderr nomme .recalc-cache.json comme emplacement non régulier"
else
  ko "R56 stderr" "cite .recalc-cache.json comme emplacement non régulier" "$(cat "$WORK/r56-err.txt")" "-"
fi
if cmp -s "$WORK/r56-cible-avant.json" "$R56_CIBLE"; then
  ok "R56 cible du lien inchangée octet pour octet"
else
  ko "R56 cible du lien" "inchangée" "modifiée" "-"
fi
if [ -L "$R56_DIR/.planning/.recalc-cache.json" ]; then
  ok "R56 .recalc-cache.json reste un lien (jamais remplacé, F4)"
else
  ko "R56 .recalc-cache.json" "toujours un lien" "remplacé ou absent" "-"
fi
if cmp -s "$WORK/r56-index-avant.md" "$R56_DIR/.planning/INDEX.md" && cmp -s "$WORK/r56-state-avant.md" "$R56_DIR/.planning/STATE.md"; then
  ok "R56 INDEX.md/STATE.md inchangés (refus AVANT toute écriture)"
else
  ko "R56 INDEX.md/STATE.md" "inchangés" "modifiés" "-"
fi

# ---------- R57 — cache au bon format, entrée forgée : la lecture seule ne le lit jamais ----------
R57_DIR="$WORK/r57"
materialiser traceur "$R57_DIR"
( cd "$R57_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
"$PYBIN" -c "
import json
p = '$R57_DIR/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
cle = 'cycles/01-traceur/phases/02-en-cours'
entree = d['unites'][cle]
entree['etat'] = 'close'
entree['raison'] = None
json.dump(d, open(p, 'w', encoding='utf-8'))
"
R57_SANS_CACHE_DIR="$WORK/r57-sans-cache"
materialiser traceur "$R57_SANS_CACHE_DIR"
( cd "$R57_SANS_CACHE_DIR" && bash "$RECALC" --read-only > "$WORK/r57-sans-cache-out.json" 2>/dev/null )
empreinte "$R57_DIR" > "$WORK/r57-avant.txt"
( cd "$R57_DIR" && bash "$RECALC" --read-only > "$WORK/r57-out.json" 2>"$WORK/r57-err.txt" )
R57_RC=$?
empreinte "$R57_DIR" > "$WORK/r57-apres.txt"
R57_JSON_EGAL="$("$PYBIN" -c 'import json,sys; a=json.load(open(sys.argv[1]))["cycles"]; b=json.load(open(sys.argv[2]))["cycles"]; print(a==b)' "$WORK/r57-out.json" "$WORK/r57-sans-cache-out.json" 2>/dev/null || echo '?')"
if [ "$R57_RC" -eq 0 ] && [ "$R57_JSON_EGAL" = "True" ]; then
  ok "R57 --read-only : JSON identique à un lab sans cache (l'entrée forgée n'est jamais lue)"
else
  ko "R57 JSON --read-only" "identique au lab sans cache" "rc=$R57_RC égal=$R57_JSON_EGAL" "-"
fi
if cmp -s "$WORK/r57-avant.txt" "$WORK/r57-apres.txt"; then
  ok "R57 empreinte du lab inchangée (--read-only ne lit ni n'écrit jamais le cache)"
else
  ko "R57 empreinte" "identique" "diverge" "-"
fi

# ---------- R58 — livrable supprimé après un passage à cache valide : vu malgré signature stable --
R58_DIR="$WORK/r58"
materialiser traceur "$R58_DIR"
( cd "$R58_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
rm -f "$R58_DIR/livrables/rapport.md"
( cd "$R58_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r58-out.json" 2>"$WORK/r58-err.txt" )
R58_RC=$?
# Rapport d'écriture : agrégats seulement (pas de détail par unité) — l'état/raison se lit dans
# le rendu INDEX.md, comme R53.
R58_LIGNE_ATTENDUE='indéterminé — phase `01-livree` indéterminée : livrable absent : livrables/rapport.md (cycles/01-traceur)'
if [ "$R58_RC" -eq 0 ] && grep -qF "$R58_LIGNE_ATTENDUE" "$R58_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R58 livrable supprimé : indéterminé (livrable-absent:livrables/rapport.md) malgré signature stable"
else
  ko "R58 INDEX.md" "$R58_LIGNE_ATTENDUE" "rc=$R58_RC $(cat "$R58_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi

# ---------- R-CACHE2-01 — livrable RÉÉCRIT (taille égale) après un passage à cache valide : jamais `close` (46-03, P46-D-03b) --
# Jumeau de R58 (livrable supprimé) pour une réécriture : la signature de l'unité (fichiers du modèle) est stable, seule l'empreinte du
# contenu des livrables, recalculée à chaque passage, voit l'écart.
RC2_DIR="$WORK/r-cache2-01"
materialiser traceur "$RC2_DIR"
( cd "$RC2_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/rc2-premier.json" 2>/dev/null )
RC2_CACHE_SCHEMA="$("$PYBIN" -c '
import json, re, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
e = d["unites"]["cycles/01-traceur/phases/01-livree"]
v = e.get("empreinte_livrables")
print("%s %s %s" % (d["cache_schema_version"], v[0], bool(re.fullmatch("[0-9a-f]{64}", v[1] or ""))))
' "$RC2_DIR/.planning/.recalc-cache.json" 2>/dev/null || echo ERREUR)"
if [ "$RC2_CACHE_SCHEMA" = "2 ok True" ]; then
  ok "R-CACHE2-01 le cache écrit est de schéma 2 et porte l'empreinte des livrables de la phase close (64 hexadécimaux)"
else
  ko "R-CACHE2-01 schéma et empreinte du cache" "2 ok True" "$RC2_CACHE_SCHEMA" "-"
fi
RC2_TAILLE_AVANT="$("$PYBIN" -c 'import os,sys; print(os.path.getsize(sys.argv[1]))' "$RC2_DIR/livrables/rapport.md")"
"$PYBIN" -c '
import sys
chemin = sys.argv[1]
octets = bytearray(open(chemin, "rb").read())
octets[0] = ord("M") if octets[0] != ord("M") else ord("L")
open(chemin, "wb").write(bytes(octets))
' "$RC2_DIR/livrables/rapport.md"
RC2_TAILLE_APRES="$("$PYBIN" -c 'import os,sys; print(os.path.getsize(sys.argv[1]))' "$RC2_DIR/livrables/rapport.md")"
( cd "$RC2_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/rc2-second.json" 2>"$WORK/rc2-second.err" )
RC2_RC=$?
RC2_LIGNE='indéterminé — phase `01-livree` indéterminée : livrable ou plan modifié après la clôture (cycles/01-traceur)'
RC2_RECALCULEES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/rc2-second.json" 2>/dev/null || echo '?')"
if [ "$RC2_RC" -eq 0 ] && [ "$RC2_TAILLE_AVANT" = "$RC2_TAILLE_APRES" ] && grep -qF "$RC2_LIGNE" "$RC2_DIR/.planning/INDEX.md" 2>/dev/null \
   && [ "$RC2_RECALCULEES" = "1" ]; then
  ok "R-CACHE2-01 un octet d'un livrable réécrit à taille égale : le second recalcul, par le cache, rend indéterminé (livrable-modifie-apres-cloture), jamais close ; une seule unité recalculée"
else
  ko "R-CACHE2-01 réécriture du livrable" "indéterminé (livrable ou plan modifié après la clôture), 1 unité recalculée, tailles égales" "rc=$RC2_RC taille=$RC2_TAILLE_AVANT/$RC2_TAILLE_APRES recalculees=$RC2_RECALCULEES $(cat "$RC2_DIR/.planning/INDEX.md" 2>/dev/null)" "$(cat "$WORK/rc2-second.err" 2>/dev/null)"
fi
# Jumeau négatif : réécrire un fichier que aucun `ecrit:` ne déclare laisse l'unité close et reprise du cache.
RC2J_DIR="$WORK/r-cache2-01-jumeau"
materialiser traceur "$RC2J_DIR"
printf 'Hors ecrit: A.\n' > "$RC2J_DIR/autre-fichier.md"
( cd "$RC2J_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
printf 'Hors ecrit: B.\n' > "$RC2J_DIR/autre-fichier.md"
( cd "$RC2J_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/rc2j-second.json" 2>/dev/null )
RC2J_FAITS="$("$PYBIN" -c '
import json, sys
d = json.load(open(sys.argv[1]))
print("reprises=%s recalculees=%s" % (d["unites_reprises"], d["unites_recalculees"]))
' "$WORK/rc2j-second.json" 2>/dev/null || echo ERREUR)"
if [ "$RC2J_FAITS" = "reprises=2 recalculees=0" ] && ! grep -qF 'modifié après la clôture' "$RC2J_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R-CACHE2-01 jumeau : un fichier hors ecrit: réécrit laisse les deux unités reprises du cache (close conservé)"
else
  ko "R-CACHE2-01 jumeau fichier hors ecrit:" "reprises=2 recalculees=0, aucune péremption" "$RC2J_FAITS $(cat "$RC2J_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi

# ---------- R-CACHE3-01 — cache FORGÉ par Bash (A6/A8, P46 lot B, b3) : l'entrée n'est reprise que si ses `ecrit:` sont ceux du PLAN.md réel ----------
# Le cache est un fichier du lab : un agent qui a Bash le réécrit. Forgé (`ecrit: []`, empreinte `["ok", null]`) et livrable réécrit : le recalcul
# relit les `ecrit:` du PLAN.md, constate l'écart et recalcule — jamais `close` sur la foi du cache. Jumeau : seul `ecrit` forgé (empreinte intacte) :
# l'entrée n'est pas reprise non plus, le cache est réécrit avec les `ecrit:` réels.
RC3_DIR="$WORK/r-cache3-01"
materialiser traceur "$RC3_DIR"
( cd "$RC3_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
"$PYBIN" -c "
import json
p = '$RC3_DIR/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
e = d['unites']['cycles/01-traceur/phases/01-livree']
e['ecrit'] = []
e['empreinte_livrables'] = ['ok', None]
json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False)
"
"$PYBIN" -c '
import sys
chemin = sys.argv[1]
octets = bytearray(open(chemin, "rb").read())
octets[0] = ord("M") if octets[0] != ord("M") else ord("L")
open(chemin, "wb").write(bytes(octets))
' "$RC3_DIR/livrables/rapport.md"
( cd "$RC3_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/rc3-second.json" 2>"$WORK/rc3-second.err" )
RC3_RC=$?
RC3_RECALCULEES="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/rc3-second.json" 2>/dev/null || echo '?')"
if [ "$RC3_RC" -eq 0 ] && grep -qF "$RC2_LIGNE" "$RC3_DIR/.planning/INDEX.md" 2>/dev/null && [ "$RC3_RECALCULEES" = "1" ]; then
  ok "R-CACHE3-01 cache forgé (ecrit: [] et empreinte forcées) et livrable réécrit : indéterminé (livrable-modifie-apres-cloture), jamais close ; une unité recalculée"
else
  ko "R-CACHE3-01 cache forgé" "indéterminé (livrable ou plan modifié après la clôture), 1 unité recalculée" "rc=$RC3_RC recalculees=$RC3_RECALCULEES $(cat "$RC3_DIR/.planning/INDEX.md" 2>/dev/null | tr '\n' ' ' | cut -c1-300)" "-"
fi
RC3J_DIR="$WORK/r-cache3-01-jumeau"
materialiser traceur "$RC3J_DIR"
( cd "$RC3J_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
RC3J_ECRIT_REEL="$("$PYBIN" -c "
import json
print(json.dumps(json.load(open('$RC3J_DIR/.planning/.recalc-cache.json', encoding='utf-8'))['unites']['cycles/01-traceur/phases/01-livree']['ecrit']))
")"
"$PYBIN" -c "
import json
p = '$RC3J_DIR/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
d['unites']['cycles/01-traceur/phases/01-livree']['ecrit'] = ['autre-fichier-forge.md']
json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False)
"
( cd "$RC3J_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/rc3j-second.json" 2>/dev/null )
RC3J_FAITS="$("$PYBIN" -c "
import json
r = json.load(open('$WORK/rc3j-second.json'))
e = json.load(open('$RC3J_DIR/.planning/.recalc-cache.json', encoding='utf-8'))['unites']['cycles/01-traceur/phases/01-livree']['ecrit']
print('recalculees=%s ecrit_reecrit=%s' % (r['unites_recalculees'], json.dumps(e) == '$RC3J_ECRIT_REEL'.replace(chr(39), '')))
")"
if [ "$RC3J_FAITS" = "recalculees=1 ecrit_reecrit=True" ]; then
  ok "R-CACHE3-01 jumeau : seul ecrit forgé (empreinte intacte) : l'entrée n'est pas reprise, le cache est réécrit avec les ecrit: réels du PLAN.md"
else
  ko "R-CACHE3-01 jumeau ecrit forgé" "recalculees=1 ecrit_reecrit=True" "$RC3J_FAITS (réels : $RC3J_ECRIT_REEL)" "-"
fi

# ---------- R-CACHE2-02 — un cache de schéma 1 est relu comme `autre-format` : recalcul complet, résultat identique (46-03) ----
RC2B_DIR="$WORK/r-cache2-02"
materialiser traceur "$RC2B_DIR"
( cd "$RC2B_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
cp "$RC2B_DIR/.planning/INDEX.md" "$WORK/rc2b-index-ref.md"
cp "$RC2B_DIR/.planning/STATE.md" "$WORK/rc2b-state-ref.md"
"$PYBIN" -c "
import json
p = '$RC2B_DIR/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
d['cache_schema_version'] = 1
for e in d['unites'].values():
    e.pop('empreinte_livrables', None)
    e['livrables'] = {v: True for v in e.get('ecrit', [])}
json.dump(d, open(p, 'w', encoding='utf-8'))
"
( cd "$RC2B_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/rc2b-out.json" 2>"$WORK/rc2b-err.txt" )
RC2B_RC=$?
RC2B_FAITS="$("$PYBIN" -c '
import json, sys
d = json.load(open(sys.argv[1]))
print("cache=%s reprises=%s recalculees=%s unites=%s" % (d["cache"], d["unites_reprises"], d["unites_recalculees"], d["unites"]))
' "$WORK/rc2b-out.json" 2>/dev/null || echo ERREUR)"
if [ "$RC2B_RC" -eq 0 ] && [ "$RC2B_FAITS" = "cache=autre-format reprises=0 recalculees=2 unites=2" ]; then
  ok "R-CACHE2-02 cache de schéma 1 : autre-format, aucune reprise, recalcul complet ($RC2B_FAITS)"
else
  ko "R-CACHE2-02 cache de schéma 1" "cache=autre-format reprises=0 recalculees=2 unites=2" "rc=$RC2B_RC $RC2B_FAITS" "$(cat "$WORK/rc2b-err.txt" 2>/dev/null)"
fi
rm -f "$RC2B_DIR/.planning/.recalc-cache.json"
( cd "$RC2B_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>&1 )
if cmp -s "$WORK/rc2b-index-ref.md" "$RC2B_DIR/.planning/INDEX.md" && cmp -s "$WORK/rc2b-state-ref.md" "$RC2B_DIR/.planning/STATE.md"; then
  ok "R-CACHE2-02 INDEX.md et STATE.md identiques au recalcul sans cache (cache de schéma 1, cache absent, cache valide)"
else
  ko "R-CACHE2-02 identité avec le recalcul sans cache" "INDEX.md et STATE.md identiques" "diffèrent" "-"
fi
RC2B_SCHEMA_FINAL="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cache_schema_version"])' "$RC2B_DIR/.planning/.recalc-cache.json" 2>/dev/null || echo '?')"
if [ "$RC2B_SCHEMA_FINAL" = "2" ]; then
  ok "R-CACHE2-02 le cache réécrit après le schéma 1 est de schéma 2"
else
  ko "R-CACHE2-02 schéma réécrit" "2" "$RC2B_SCHEMA_FINAL" "-"
fi

# ================================================================================================
# make_recalc_mutant — mute UNE ligne à motif fixe unique de recalc-planning.sh dans une copie
# fraîche (moteur + detect-gsd-engine.sh + workstream-policy.sh), patron test-check-skills.sh
# make_gate_mutant : bash -n sur l'enveloppe PUIS compilation du corps Python extrait du
# here-document quoté. Le script réel n'est jamais touché (copie seulement).
# ================================================================================================
MUT_DIR=""
make_recalc_mutant() { # <id> <motif> <remplacement>
  local id="$1" motif="$2" remplacement="$3"
  local dir orig n tmp
  dir="$WORK/mut-$id"
  MUT_DIR="$dir"
  mkdir -p "$dir"
  cp "$RECALC" "$dir/recalc-planning.sh"
  cp "$DETECT" "$dir/detect-gsd-engine.sh"
  cp "$WORKSTREAM_POLICY" "$dir/workstream-policy.sh"
  orig="$dir/recalc-planning.sh"
  n="$(grep -Fc -- "$motif" "$orig")"
  if [ "$n" -ne 1 ]; then
    komut "$id" "motif fixe unique dans recalc-planning.sh" "exactement 1 occurrence" "MOTIF AMBIGU OU ABSENT (n=$n)"
    return 1
  fi
  tmp="$orig.mut"
  MUT_MOTIF_ENV="$motif" MUT_REPL_ENV="$remplacement" awk '
    index($0, ENVIRON["MUT_MOTIF_ENV"]) {
      match($0, /^[ \t]*/)
      print substr($0, RSTART, RLENGTH) ENVIRON["MUT_REPL_ENV"]
      next
    }
    { print }
  ' "$orig" > "$tmp"
  if cmp -s "$tmp" "$orig"; then
    komut "$id" "mutation produit un fichier différent de l'original" "fichiers distincts" "NON OPPOSABLE (identique)"
    rm -f "$tmp"
    return 1
  fi
  if ! bash -n "$tmp" 2>/dev/null; then
    komut "$id" "mutant syntaxiquement valide (bash -n)" "bash -n réussit" "bash -n ÉCHOUE"
    rm -f "$tmp"
    return 1
  fi
  local pybody pyerr pyrc
  pybody="$dir/mutant-body.py"
  awk '/<<.PY_RECALC_PLANNING_EOF.$/{f=1;next} /^PY_RECALC_PLANNING_EOF$/{f=0} f' "$tmp" > "$pybody"
  pyerr="$("$PYBIN" -c '
import sys
f = sys.argv[1]
compile(open(f, encoding="utf-8").read(), f, "exec")
' "$pybody" 2>&1)"
  pyrc=$?
  if [ "$pyrc" -ne 0 ]; then
    komut "$id" "mutant Python valide (compilation du corps du here-document)" "compilation réussit" "SyntaxError : $pyerr"
    rm -f "$tmp" "$pybody"
    return 1
  fi
  rm -f "$pybody"
  mv "$tmp" "$orig"
  chmod +x "$orig"
  return 0
}

okmut() { # <id> <trace>
  echo "  ✓ MUT-$1 TUÉ — $2"
  pass=$((pass+1))
}
komut() { # <id> <assertion> <attendu> <obtenu>
  echo "  ✗ MUT-$1 NON TUÉ"
  echo "    assertion : $2"
  echo "    attendu (original) : $3"
  echo "    obtenu (mutant)     : $4"
  fail=$((fail+1))
}

# Prédicat de mort explicite (action 3, Tâche 2) : APPLIQUÉ PAR LE MÉCANISME lui-même, avant toute
# comparaison métier. Renvoie 0 (et a DÉJÀ appelé komut) si le mutant a planté (trace Python non
# gérée OU code de sortie hors du contrat 0/1/2/3/64) ; renvoie 1 sinon (le cas cible normal peut
# être comparé métier).
_verifier_plantage() { # <id> <assertion_normale> <stdout_file> <stderr_file> <rc>
  local id="$1" assertion="$2" err="$4" rc="$5"
  if grep -q "Traceback (most recent call last)" "$err" 2>/dev/null; then
    komut "$id" "$assertion" "pas de plantage (contrat 0/1/2/3/64)" "PLANTAGE : trace Python non gérée"
    return 0
  fi
  case "$rc" in
    0|1|2|3|64) ;;
    *) komut "$id" "$assertion" "code de sortie dans {0,1,2,3,64}" "PLANTAGE : code hors contrat ($rc)"; return 0 ;;
  esac
  return 1
}

# ---------- MUT-ADHESION — verifier_adhesion : comparaison stricte neutralisée -------------------
if make_recalc_mutant ADHESION \
  'resultat["adherente"] = isinstance(resultat["declaree"], str) and resultat["declaree"] == SCHEMA_ADHESION' \
  'resultat["adherente"] = True  # MUT-ADHESION'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-adhesion-cas"
  materialiser traceur "$DIR_CAS"
  printf '%s' '{"planning_version": "2.0"}' > "$DIR_CAS/.planning/config.json"
  DIR_TEMOIN="$WORK/mut-adhesion-temoin"
  materialiser traceur "$DIR_TEMOIN"
  printf '%s' '{"planning_version": "2.0"}' > "$DIR_TEMOIN/.planning/config.json"
  ( cd "$DIR_TEMOIN" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/mut-adhesion-t-out.txt" 2>"$WORK/mut-adhesion-t-err.txt" ); RC_T=$?
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-adhesion-m-out.txt" 2>"$WORK/mut-adhesion-m-err.txt" ); RC_M=$?
  if ! _verifier_plantage ADHESION "code de sortie de R05 (variante 2.0)" "$WORK/mut-adhesion-m-out.txt" "$WORK/mut-adhesion-m-err.txt" "$RC_M"; then
    if [ "$RC_M" != "$RC_T" ]; then
      okmut ADHESION "code de sortie de R05 (variante 2.0) · attendu (original) : $RC_T · obtenu (mutant) : $RC_M"
    else
      komut ADHESION "code de sortie de R05 (variante 2.0)" "$RC_T" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-LECTURE-SEULE — branche lecture seule neutralisée --------------------------------
if make_recalc_mutant LECTURE-SEULE 'if mode_lecture_seule:' 'if False:  # MUT-LECTURE-SEULE'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-lecture-seule-cas"
  materialiser traceur "$DIR_CAS"
  empreinte "$DIR_CAS" > "$WORK/mut-lecture-seule-avant.txt"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >/dev/null 2>&1 )
  empreinte "$DIR_CAS" > "$WORK/mut-lecture-seule-apres.txt"
  if cmp -s "$WORK/mut-lecture-seule-avant.txt" "$WORK/mut-lecture-seule-apres.txt"; then
    komut LECTURE-SEULE "empreinte de R07 avant/après --read-only" "identique (original)" "identique (mutant non opposable)"
  else
    okmut LECTURE-SEULE "empreinte de R07 avant/après --read-only · attendu (original) : identique · obtenu (mutant) : INDEX.md/STATE.md/cloture.log créés malgré --read-only"
  fi
fi

# ---------- MUT-GSD — code 0 du détecteur lu comme non-gsd ----------------------------------------
if make_recalc_mutant GSD 'return "gsd"  # motif-code-0' 'return "non-gsd"  # MUT-GSD'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gsd-cas"
  materialiser traceur "$DIR_CAS"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$DIR_CAS/.planning/STATE.md"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gsd-out.txt" 2>"$WORK/mut-gsd-err.txt" ); RC_M=$?
  if ! _verifier_plantage GSD "code de sortie de R08" "$WORK/mut-gsd-out.txt" "$WORK/mut-gsd-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut GSD "code de sortie de R08 · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture sur un planning GSD)"
    else
      komut GSD "code de sortie de R08" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GSD-FERME — repli « détecteur absent » changé en non-gsd -------------------------
# Motif « motif-detecteur-absent » (F6, revue) : « absent » et « non régulier » (motif voisin,
# couvert par MUT-GSD-IRREGULIER ci-dessous) partageaient jusqu'ici le même message ET la même
# ligne de retour — désormais deux branches, deux marqueurs distincts.
if make_recalc_mutant GSD-FERME 'return "non-concluante"  # motif-detecteur-absent' 'return "non-gsd"  # MUT-GSD-FERME'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gsd-ferme-cas"; SCRIPTS_CAS="$WORK/mut-gsd-ferme-scripts"
  materialiser traceur "$DIR_CAS"
  mkdir -p "$SCRIPTS_CAS"
  cp "$MR" "$SCRIPTS_CAS/recalc-planning.sh"
  # aucun detect-gsd-engine.sh dans $SCRIPTS_CAS : variante « détecteur absent » de R09
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$SCRIPTS_CAS/recalc-planning.sh" >"$WORK/mut-gsd-ferme-out.txt" 2>"$WORK/mut-gsd-ferme-err.txt" ); RC_M=$?
  if ! _verifier_plantage GSD-FERME "code de sortie de R09 [absent]" "$WORK/mut-gsd-ferme-out.txt" "$WORK/mut-gsd-ferme-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut GSD-FERME "code de sortie de R09 [absent] · attendu (original) : 3 · obtenu (mutant) : $RC_M"
    else
      komut GSD-FERME "code de sortie de R09 [absent]" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GSD-IRREGULIER — mention stderr du contrôle de régularité neutralisée ------------
if make_recalc_mutant GSD-IRREGULIER \
  'print("[recalc-planning] détecteur non régulier : " + detect_sh, file=sys.stderr)' \
  'pass  # MUT-GSD-IRREGULIER (mention supprimée)'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gsd-irregulier-cas"; SCRIPTS_CAS="$WORK/mut-gsd-irregulier-scripts"
  materialiser traceur "$DIR_CAS"
  mkdir -p "$SCRIPTS_CAS"
  cp "$MR" "$SCRIPTS_CAS/recalc-planning.sh"
  mkdir -p "$SCRIPTS_CAS/detect-gsd-engine.sh"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$SCRIPTS_CAS/recalc-planning.sh" >"$WORK/mut-gsd-irregulier-out.txt" 2>"$WORK/mut-gsd-irregulier-err.txt" ); RC_M=$?
  if ! _verifier_plantage GSD-IRREGULIER "mention « détecteur non régulier » sur stderr (R09 [dossier])" "$WORK/mut-gsd-irregulier-out.txt" "$WORK/mut-gsd-irregulier-err.txt" "$RC_M"; then
    if grep -q "détecteur non régulier" "$WORK/mut-gsd-irregulier-err.txt"; then
      komut GSD-IRREGULIER "mention « détecteur non régulier » sur stderr" "absente (mutant)" "présente (mutant non opposable)"
    else
      okmut GSD-IRREGULIER "mention « détecteur non régulier » sur stderr · attendu (original) : présente · obtenu (mutant) : absente (code de sortie $RC_M identique par coïncidence via le repli générique)"
    fi
  fi
fi

# ---------- MUT-AJOUT — drapeau d'ajout remplacé par la troncature -------------------------------
if make_recalc_mutant AJOUT \
  'fd_journal = os.open(chemin, os.O_WRONLY | os.O_APPEND | os.O_CREAT | SANS_SUIVI_DE_LIEN, 0o644)' \
  'fd_journal = os.open(chemin, os.O_WRONLY | os.O_TRUNC | os.O_CREAT | SANS_SUIVI_DE_LIEN, 0o644)  # MUT-AJOUT'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-ajout-cas"
  materialiser traceur "$DIR_CAS"
  printf '%s\n' "$R10_TEMOIN" > "$DIR_CAS/.planning/cloture.log"
  TAILLE_AVANT=$(wc -c < "$DIR_CAS/.planning/cloture.log")
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-ajout-out.txt" 2>"$WORK/mut-ajout-err.txt" ); RC_M=$?
  if ! _verifier_plantage AJOUT "préfixe de R10 (head -c + cmp)" "$WORK/mut-ajout-out.txt" "$WORK/mut-ajout-err.txt" "$RC_M"; then
    head -c "$TAILLE_AVANT" "$DIR_CAS/.planning/cloture.log" > "$WORK/mut-ajout-prefixe.txt" 2>/dev/null
    printf '%s\n' "$R10_TEMOIN" > "$WORK/mut-ajout-temoin.txt"
    if cmp -s "$WORK/mut-ajout-temoin.txt" "$WORK/mut-ajout-prefixe.txt"; then
      komut AJOUT "préfixe de R10 (head -c + cmp)" "octets antérieurs intacts (original)" "octets antérieurs intacts (mutant non opposable)"
    else
      okmut AJOUT "préfixe de R10 (head -c + cmp) · attendu (original) : octets antérieurs intacts · obtenu (mutant) : préfixe tronqué ou absent"
    fi
  fi
fi

# ---------- MUT-DEDOUBLONNAGE — comparaison au dernier couple journalisé neutralisée --------------
if make_recalc_mutant DEDOUBLONNAGE \
  'if dernier_couple.get(chemin_jeton) != couple_jeton:' \
  'if True:  # MUT-DEDOUBLONNAGE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-dedoublonnage-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>"$WORK/mut-dedoublonnage-err1.txt" )
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-dedoublonnage-out2.txt" 2>"$WORK/mut-dedoublonnage-err2.txt" ); RC_M=$?
  if ! _verifier_plantage DEDOUBLONNAGE "cloture_ajouts du second recalcul (R03)" "$WORK/mut-dedoublonnage-out2.txt" "$WORK/mut-dedoublonnage-err2.txt" "$RC_M"; then
    AJOUTS_M="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cloture_ajouts"])' "$WORK/mut-dedoublonnage-out2.txt" 2>/dev/null || echo '?')"
    if [ "$AJOUTS_M" = "0" ]; then
      komut DEDOUBLONNAGE "cloture_ajouts du second recalcul" "0 (original)" "0 (mutant non opposable)"
    else
      okmut DEDOUBLONNAGE "cloture_ajouts du second recalcul · attendu (original) : 0 · obtenu (mutant) : $AJOUTS_M (ligne dupliquée)"
    fi
  fi
fi

# ---------- MUT-NOFOLLOW — SANS_SUIVI_DE_LIEN mis à 0 ----------------------------------------------
# Depuis F4, .../cloture.log en lien reste refusé (rc=1) MÊME quand SANS_SUIVI_DE_LIEN est
# neutralisé : le second rideau ajouté par F4 (est_fichier_regulier, lstat, dans la boucle de
# appliquer_ecritures) rattrape ce que lire_journal ne détecte plus sans O_NOFOLLOW. Le code de
# sortie seul ne distingue donc plus les deux rideaux — le message stderr, si : « journal des
# clôtures inaccessible » (premier rideau, lire_journal) vs « emplacement occupé par autre chose
# qu'un fichier régulier » (second rideau, F4). C'est ce message qui prouve SANS_SUIVI_DE_LIEN
# encore chargé.
if make_recalc_mutant NOFOLLOW 'SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)' 'SANS_SUIVI_DE_LIEN = 0  # MUT-NOFOLLOW'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-nofollow-cas"
  materialiser traceur "$DIR_CAS"
  rm -f "$DIR_CAS/.planning/cloture.log"
  CIBLE="$WORK/mut-nofollow-cible.log"
  printf 'contenu-original\n' > "$CIBLE"
  ln -s "$CIBLE" "$DIR_CAS/.planning/cloture.log"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-nofollow-out.txt" 2>"$WORK/mut-nofollow-err.txt" ); RC_M=$?
  if ! _verifier_plantage NOFOLLOW "message stderr (rideau lire_journal vs rideau F4) et cible du lien de R11" "$WORK/mut-nofollow-out.txt" "$WORK/mut-nofollow-err.txt" "$RC_M"; then
    if [ "$RC_M" -eq 1 ] && printf 'contenu-original\n' | cmp -s - "$CIBLE" && grep -qF "journal des clôtures inaccessible" "$WORK/mut-nofollow-err.txt"; then
      komut NOFOLLOW "message stderr (rideau lire_journal) et cible du lien de R11" "code 1, message lire_journal, cible inchangée (original)" "identique (mutant non opposable)"
    else
      okmut NOFOLLOW "message stderr (rideau lire_journal vs rideau F4) de R11 · attendu (original) : « journal des clôtures inaccessible » · obtenu (mutant, SANS_SUIVI_DE_LIEN neutralisé) : $(cat "$WORK/mut-nofollow-err.txt") (rattrapé par le second rideau F4, code $RC_M identique par coïncidence)"
    fi
  fi
fi

# ================================================================================================
# Lot 4 (correction de CLASSE, décision du head sous délégation technique de Willy, session
# principale, 2026-09-28) — le moteur appelle désormais le VRAI détecteur bash dans un
# environnement MAÎTRISÉ (GSD_HOME toujours existant) au lieu d'en réimplémenter les priorités en
# Python ; écriture autorisée SEULEMENT si le détecteur rend 3 ; détecteur absent, en lien, non
# régulier, illisible, ou dont l'exécution échoue -> refus fail-closed nommé.
# ================================================================================================

# ---------- R-DETECTEUR-LIEN — détecteur en lien symbolique : non régulier, refus -----------------
R_DETLIEN_DIR="$WORK/r-detecteur-lien-cas"; R_DETLIEN_SCRIPTS="$WORK/r-detecteur-lien-scripts"
materialiser traceur "$R_DETLIEN_DIR"
mkdir -p "$R_DETLIEN_SCRIPTS"
cp "$RECALC" "$R_DETLIEN_SCRIPTS/recalc-planning.sh"
ln -s "$DETECT" "$R_DETLIEN_SCRIPTS/detect-gsd-engine.sh"
empreinte "$R_DETLIEN_DIR" > "$WORK/r-detecteur-lien-avant.txt"
( cd "$R_DETLIEN_DIR" && bash "$R_DETLIEN_SCRIPTS/recalc-planning.sh" >"$WORK/r-detecteur-lien-out.txt" 2>"$WORK/r-detecteur-lien-err.txt" )
R_DETLIEN_RC=$?
empreinte "$R_DETLIEN_DIR" > "$WORK/r-detecteur-lien-apres.txt"
if [ "$R_DETLIEN_RC" -eq 3 ]; then ok "R-DETECTEUR-LIEN code de sortie 3"; else ko "R-DETECTEUR-LIEN code" "3" "$R_DETLIEN_RC" "$(cat "$WORK/r-detecteur-lien-out.txt")"; fi
if grep -q "détecteur non régulier" "$WORK/r-detecteur-lien-err.txt"; then ok "R-DETECTEUR-LIEN stderr mentionne détecteur non régulier"; else ko "R-DETECTEUR-LIEN stderr" "détecteur non régulier" "$(cat "$WORK/r-detecteur-lien-err.txt")" "-"; fi
if cmp -s "$WORK/r-detecteur-lien-avant.txt" "$WORK/r-detecteur-lien-apres.txt"; then ok "R-DETECTEUR-LIEN empreinte identique"; else ko "R-DETECTEUR-LIEN empreinte" "identique" "diverge" "-"; fi

# ---------- R-DETECTEUR-ILLISIBLE — détecteur régulier, chmod 000 : non exécutable, refus ---------
R_DETILL_DIR="$WORK/r-detecteur-illisible-cas"; R_DETILL_SCRIPTS="$WORK/r-detecteur-illisible-scripts"
materialiser traceur "$R_DETILL_DIR"
mkdir -p "$R_DETILL_SCRIPTS"
cp "$RECALC" "$R_DETILL_SCRIPTS/recalc-planning.sh"
cp "$DETECT" "$R_DETILL_SCRIPTS/detect-gsd-engine.sh"
chmod 000 "$R_DETILL_SCRIPTS/detect-gsd-engine.sh"
empreinte "$R_DETILL_DIR" > "$WORK/r-detecteur-illisible-avant.txt"
( cd "$R_DETILL_DIR" && bash "$R_DETILL_SCRIPTS/recalc-planning.sh" >"$WORK/r-detecteur-illisible-out.txt" 2>"$WORK/r-detecteur-illisible-err.txt" )
R_DETILL_RC=$?
empreinte "$R_DETILL_DIR" > "$WORK/r-detecteur-illisible-apres.txt"
chmod 700 "$R_DETILL_SCRIPTS/detect-gsd-engine.sh"
if [ "$R_DETILL_RC" -eq 3 ]; then ok "R-DETECTEUR-ILLISIBLE code de sortie 3"; else ko "R-DETECTEUR-ILLISIBLE code" "3" "$R_DETILL_RC" "$(cat "$WORK/r-detecteur-illisible-out.txt")"; fi
if cmp -s "$WORK/r-detecteur-illisible-avant.txt" "$WORK/r-detecteur-illisible-apres.txt"; then ok "R-DETECTEUR-ILLISIBLE empreinte identique"; else ko "R-DETECTEUR-ILLISIBLE empreinte" "identique" "diverge" "-"; fi

# ---------- R-DETECTEUR-CODE1-INATTENDU — détecteur qui rend 1 malgré GSD_HOME maîtrisé : refus --
# Fixture ARTIFICIELLE (le vrai détecteur ne peut plus rendre 1 sous environnement maîtrisé — c'est
# précisément ce que ce lot garantit) : un détecteur FACTICE qui sort inconditionnellement en 1,
# pour prouver que le repli fail-closed (jamais une retombée en écriture) tient MÊME sur ce code.
R_DETC1_DIR="$WORK/r-detecteur-code1-cas"; R_DETC1_SCRIPTS="$WORK/r-detecteur-code1-scripts"
materialiser traceur "$R_DETC1_DIR"
mkdir -p "$R_DETC1_SCRIPTS"
cp "$RECALC" "$R_DETC1_SCRIPTS/recalc-planning.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$R_DETC1_SCRIPTS/detect-gsd-engine.sh"
chmod +x "$R_DETC1_SCRIPTS/detect-gsd-engine.sh"
empreinte "$R_DETC1_DIR" > "$WORK/r-detecteur-code1-avant.txt"
( cd "$R_DETC1_DIR" && bash "$R_DETC1_SCRIPTS/recalc-planning.sh" >"$WORK/r-detecteur-code1-out.txt" 2>"$WORK/r-detecteur-code1-err.txt" )
R_DETC1_RC=$?
empreinte "$R_DETC1_DIR" > "$WORK/r-detecteur-code1-apres.txt"
if [ "$R_DETC1_RC" -eq 3 ]; then ok "R-DETECTEUR-CODE1-INATTENDU code de sortie 3 (fail-closed)"; else ko "R-DETECTEUR-CODE1-INATTENDU code" "3" "$R_DETC1_RC" "$(cat "$WORK/r-detecteur-code1-out.txt")"; fi
if cmp -s "$WORK/r-detecteur-code1-avant.txt" "$WORK/r-detecteur-code1-apres.txt"; then ok "R-DETECTEUR-CODE1-INATTENDU empreinte identique"; else ko "R-DETECTEUR-CODE1-INATTENDU empreinte" "identique" "diverge" "-"; fi

# ---------- MUT-ENV-NON-MAITRISE — surcharge de GSD_HOME retirée : verdict qui dépend à nouveau --
# de l'environnement hérité. Discriminant : R13 (b), jumeau sans aucun marqueur GSD (terrain
# libre) — l'original écrit (code 0) quel que soit GSD_HOME hérité ; sans la surcharge, un
# GSD_HOME hérité cassé fait sortir le VRAI détecteur en priorité 1 (code 1), et le fail-closed du
# moteur refuse alors à tort (code 3) une écriture pourtant légitime.
if make_recalc_mutant ENV-NON-MAITRISE \
  'env_maitrise["GSD_HOME"] = os.path.dirname(detect_sh)' \
  'pass  # MUT-ENV-NON-MAITRISE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-env-non-maitrise-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$R13_GSD_HOME_INEXISTANT" bash "$MR" >"$WORK/mut-env-non-maitrise-out.txt" 2>"$WORK/mut-env-non-maitrise-err.txt" ); RC_M=$?
  if ! _verifier_plantage ENV-NON-MAITRISE "code de sortie de R13 (b), GSD_HOME hérité cassé" "$WORK/mut-env-non-maitrise-out.txt" "$WORK/mut-env-non-maitrise-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 0 ]; then
      okmut ENV-NON-MAITRISE "code de sortie de R13 (b) · attendu (original) : 0 · obtenu (mutant) : $RC_M (refus à tort d'un terrain libre, au seul motif d'un GSD_HOME hérité cassé)"
    else
      komut ENV-NON-MAITRISE "code de sortie de R13 (b)" "0" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-CODE1-NON-GSD — repli fail-closed du code 1 changé en écriture autorisée ---------
if make_recalc_mutant CODE1-NON-GSD 'return "non-concluante"  # motif-code-1-ferme' 'return "non-gsd"  # MUT-CODE1-NON-GSD'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-code1-non-gsd-cas"; SCRIPTS_CAS="$WORK/mut-code1-non-gsd-scripts"
  materialiser traceur "$DIR_CAS"
  mkdir -p "$SCRIPTS_CAS"
  cp "$MR" "$SCRIPTS_CAS/recalc-planning.sh"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$SCRIPTS_CAS/detect-gsd-engine.sh"
  chmod +x "$SCRIPTS_CAS/detect-gsd-engine.sh"
  ( cd "$DIR_CAS" && bash "$SCRIPTS_CAS/recalc-planning.sh" >"$WORK/mut-code1-non-gsd-out.txt" 2>"$WORK/mut-code1-non-gsd-err.txt" ); RC_M=$?
  if ! _verifier_plantage CODE1-NON-GSD "code de sortie de R-DETECTEUR-CODE1-INATTENDU" "$WORK/mut-code1-non-gsd-out.txt" "$WORK/mut-code1-non-gsd-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut CODE1-NON-GSD "code de sortie · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture malgré un détecteur qui rend 1)"
    else
      komut CODE1-NON-GSD "code de sortie" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-CHMOD — fchmod de ecrire_si_different neutralisé ---------------------------------
if make_recalc_mutant CHMOD 'os.fchmod(fd_tmp, 0o644)' 'pass  # MUT-CHMOD'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-chmod-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && ( umask 0077; GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-chmod-out.txt" 2>"$WORK/mut-chmod-err.txt" ) ); RC_M=$?
  if ! _verifier_plantage CHMOD "mode de INDEX.md/STATE.md de R14 sous umask 0077" "$WORK/mut-chmod-out.txt" "$WORK/mut-chmod-err.txt" "$RC_M"; then
    MODE_INDEX=$(mode_octal "$DIR_CAS/.planning/INDEX.md")
    if [ "$MODE_INDEX" = "644" ]; then
      komut CHMOD "mode de INDEX.md sous umask 0077" "0o644 (original)" "0o644 (mutant non opposable)"
    else
      okmut CHMOD "mode de INDEX.md sous umask 0077 · attendu (original) : 0o644 · obtenu (mutant) : 0o$MODE_INDEX"
    fi
  fi
fi

# ---------- MUT-CHMOD-JOURNAL — fchmod de ajouter_au_journal neutralisé --------------------------
if make_recalc_mutant CHMOD-JOURNAL 'os.fchmod(fd_journal, 0o644)' 'pass  # MUT-CHMOD-JOURNAL'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-chmod-journal-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && ( umask 0077; GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-chmod-journal-out.txt" 2>"$WORK/mut-chmod-journal-err.txt" ) ); RC_M=$?
  if ! _verifier_plantage CHMOD-JOURNAL "mode de cloture.log de R14 sous umask 0077" "$WORK/mut-chmod-journal-out.txt" "$WORK/mut-chmod-journal-err.txt" "$RC_M"; then
    MODE_CLOTURE=$(mode_octal "$DIR_CAS/.planning/cloture.log")
    if [ "$MODE_CLOTURE" = "644" ]; then
      komut CHMOD-JOURNAL "mode de cloture.log sous umask 0077" "0o644 (original)" "0o644 (mutant non opposable)"
    else
      okmut CHMOD-JOURNAL "mode de cloture.log sous umask 0077 · attendu (original) : 0o644 · obtenu (mutant) : 0o$MODE_CLOTURE"
    fi
  fi
fi

# ================================================================================================
# Mutants de la matrice des états (44-03, Tâche 1) — MUT-D08-*, MUT-LIVRABLES, MUT-AUTEUR,
# MUT-STRUCTURANTE, MUT-STATUT-REGISTRE.
# ================================================================================================

# ---------- MUT-D08-SUMMARY — contrôle « SUMMARY sans PLAN » (R1) neutralisé --------------------
if make_recalc_mutant D08-SUMMARY \
  'return ("indéterminé", "SUMMARY.md-sans-PLAN.md", meta)' \
  'pass  # MUT-D08-SUMMARY'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-d08-summary-cas"
  materialiser d08-summary-sans-plan "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-d08-summary-out.json" 2>"$WORK/mut-d08-summary-err.txt" ); RC_M=$?
  if ! _verifier_plantage D08-SUMMARY "état/raison de d08-summary-sans-plan" "$WORK/mut-d08-summary-out.json" "$WORK/mut-d08-summary-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/mut-d08-summary-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "indéterminé" ]; then
      komut D08-SUMMARY "état de d08-summary-sans-plan" "indéterminé (original)" "indéterminé (mutant non opposable)"
    else
      okmut D08-SUMMARY "état de d08-summary-sans-plan · attendu (original) : indéterminé (SUMMARY.md-sans-PLAN.md) · obtenu (mutant) : $ETAT_M"
    fi
  fi
fi

# ---------- MUT-D08-MARQUEUR — contrôle « CLOTURE sans PLAN » (R1) neutralisé -------------------
if make_recalc_mutant D08-MARQUEUR \
  'return ("indéterminé", "CLOTURE.md-sans-PLAN.md", meta)' \
  'pass  # MUT-D08-MARQUEUR'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-d08-marqueur-cas"
  materialiser d08-marqueur-sans-plan "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-d08-marqueur-out.json" 2>"$WORK/mut-d08-marqueur-err.txt" ); RC_M=$?
  if ! _verifier_plantage D08-MARQUEUR "état/raison de d08-marqueur-sans-plan" "$WORK/mut-d08-marqueur-out.json" "$WORK/mut-d08-marqueur-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/mut-d08-marqueur-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "indéterminé" ]; then
      komut D08-MARQUEUR "état de d08-marqueur-sans-plan" "indéterminé (original)" "indéterminé (mutant non opposable)"
    else
      okmut D08-MARQUEUR "état de d08-marqueur-sans-plan · attendu (original) : indéterminé (CLOTURE.md-sans-PLAN.md) · obtenu (mutant) : $ETAT_M"
    fi
  fi
fi

# ---------- MUT-D08-VERDICT — contrôle « VERDICT sans CLOTURE » (R3) neutralisé -----------------
if make_recalc_mutant D08-VERDICT \
  'return ("indéterminé", "VERDICT.md-sans-CLOTURE.md", meta)' \
  'pass  # MUT-D08-VERDICT'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-d08-verdict-cas"
  materialiser d08-verdict-sans-marqueur "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-d08-verdict-out.json" 2>"$WORK/mut-d08-verdict-err.txt" ); RC_M=$?
  if ! _verifier_plantage D08-VERDICT "état/raison de d08-verdict-sans-marqueur" "$WORK/mut-d08-verdict-out.json" "$WORK/mut-d08-verdict-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/mut-d08-verdict-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "indéterminé" ]; then
      komut D08-VERDICT "état de d08-verdict-sans-marqueur" "indéterminé (original)" "indéterminé (mutant non opposable)"
    else
      okmut D08-VERDICT "état de d08-verdict-sans-marqueur · attendu (original) : indéterminé (VERDICT.md-sans-CLOTURE.md) · obtenu (mutant) : $ETAT_M"
    fi
  fi
fi

# ---------- MUT-D08-ECHEC — contrôle « SUMMARY face à un échec » (R7) neutralisé ----------------
if make_recalc_mutant D08-ECHEC \
  'return ("indéterminé", "SUMMARY.md-avec-verdict-en-echec", meta)' \
  'pass  # MUT-D08-ECHEC'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-d08-echec-cas"
  materialiser d08-summary-verdict-echec "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-d08-echec-out.json" 2>"$WORK/mut-d08-echec-err.txt" ); RC_M=$?
  if ! _verifier_plantage D08-ECHEC "état/raison de d08-summary-verdict-echec" "$WORK/mut-d08-echec-out.json" "$WORK/mut-d08-echec-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/mut-d08-echec-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "indéterminé" ]; then
      komut D08-ECHEC "état de d08-summary-verdict-echec" "indéterminé (original)" "indéterminé (mutant non opposable)"
    else
      okmut D08-ECHEC "état de d08-summary-verdict-echec · attendu (original) : indéterminé (SUMMARY.md-avec-verdict-en-echec) · obtenu (mutant) : $ETAT_M"
    fi
  fi
fi

# ---------- MUT-LIVRABLES — contrôle R4 (livrable présent) neutralisé ---------------------------
if make_recalc_mutant LIVRABLES \
  'presents = livrables_presents(racine_lab, valeurs)  # r4-predicat' \
  'presents = [(v, "present", "") for v in valeurs]  # MUT-LIVRABLES'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-livrables-cas"
  materialiser etat-a-juger-jumeau "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-livrables-out.json" 2>"$WORK/mut-livrables-err.txt" ); RC_M=$?
  if ! _verifier_plantage LIVRABLES "état de etat-a-juger-jumeau" "$WORK/mut-livrables-out.json" "$WORK/mut-livrables-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/mut-livrables-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "indéterminé" ]; then
      komut LIVRABLES "état de etat-a-juger-jumeau" "indéterminé (original)" "indéterminé (mutant non opposable)"
    else
      okmut LIVRABLES "état de etat-a-juger-jumeau · attendu (original) : indéterminé (livrable-absent) · obtenu (mutant) : $ETAT_M"
    fi
  fi
fi

# ---------- MUT-R4-VIDE — le prédicat partagé « livrable présent » remplacé par l'ancienne existence nue (46-03, P46-D-12) ----
if make_recalc_mutant R4-VIDE \
  'presents = livrables_presents(racine_lab, valeurs)  # r4-predicat' \
  'presents = [(v, "present" if os.path.lexists(os.path.join(racine_lab, v)) else "absent", "") for v in valeurs]  # MUT-R4-VIDE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-r4-vide-cas"
  materialiser livrable-vide "$DIR_CAS"
  ETAT_M="$(phase_etat_raison "$MR" "$DIR_CAS")"
  if ! _verifier_plantage R4-VIDE "état/raison de livrable-vide" "$WORK/per-courant.json" "$WORK/per-courant.err" "0"; then
    if [ "$ETAT_M" = 'indéterminé|livrable-vide:livrables/rapport.md' ]; then
      komut R4-VIDE "état/raison de livrable-vide" "indéterminé|livrable-vide:livrables/rapport.md (original)" "$ETAT_M (mutant non opposable)"
    elif [ "$ETAT_M" = "ERREUR" ]; then
      komut R4-VIDE "état/raison de livrable-vide" "indéterminé|livrable-vide:livrables/rapport.md (original)" "ERREUR : le mutant plante, il n'est pas tué par la bonne raison"
    else
      okmut R4-VIDE "état/raison de livrable-vide · attendu (original) : indéterminé|livrable-vide:livrables/rapport.md · obtenu (mutant, existence nue) : $ETAT_M"
    fi
  fi
fi

# ---------- MUT-EMPREINTES-RECALC — règle E neutralisée : un verdict périmé reste cru (46-03, P46-D-03b) ------------------
if make_recalc_mutant EMPREINTES-RECALC \
  'if perime:' \
  'if False:  # MUT-EMPREINTES-RECALC'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-empreintes-recalc-cas"
  materialiser verdict-perime "$DIR_CAS"
  ETAT_M="$(phase_etat_raison "$MR" "$DIR_CAS")"
  if [ "$ETAT_M" = 'à juger|verdict-perime' ]; then
    komut EMPREINTES-RECALC "état/raison de verdict-perime" "à juger|verdict-perime (original)" "$ETAT_M (mutant non opposable)"
  elif [ "$ETAT_M" = "ERREUR" ]; then
    komut EMPREINTES-RECALC "état/raison de verdict-perime" "à juger|verdict-perime (original)" "ERREUR : le mutant plante, il n'est pas tué par la bonne raison"
  else
    okmut EMPREINTES-RECALC "état/raison de verdict-perime · attendu (original) : à juger|verdict-perime · obtenu (mutant, règle E neutralisée) : $ETAT_M"
  fi
fi

# ---------- MUT-A-CLORE — R8 rend l'ancien `indéterminé` au lieu de `à clore` (46-03, P46-D-04) --------------------------
if make_recalc_mutant A-CLORE \
  'return ("à clore", None, meta)  # r8-a-clore' \
  'return ("indéterminé", "verdict-passe-sans-SUMMARY.md", meta)  # MUT-A-CLORE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-a-clore-cas"
  materialiser etat-a-clore "$DIR_CAS"
  ETAT_M="$(phase_etat_raison "$MR" "$DIR_CAS")"
  if [ "$ETAT_M" = 'à clore|' ]; then
    komut A-CLORE "état/raison de etat-a-clore" "à clore| (original)" "$ETAT_M (mutant non opposable)"
  elif [ "$ETAT_M" = "ERREUR" ]; then
    komut A-CLORE "état/raison de etat-a-clore" "à clore| (original)" "ERREUR : le mutant plante, il n'est pas tué par la bonne raison"
  else
    okmut A-CLORE "état/raison de etat-a-clore · attendu (original) : à clore| · obtenu (mutant, R8 rend l'ancien indéterminé) : $ETAT_M"
  fi
fi

# ---------- MUT-AUTEUR — statut de dérogation sans auteur accepté (lire_derogation) --------------
if make_recalc_mutant AUTEUR \
  'return (None, "derogation-sans-auteur", None)' \
  'return (statut, None, "inconnu")  # MUT-AUTEUR'
then
  MR="$MUT_DIR/recalc-planning.sh"
  MUT_AUTEUR_TOUS_INDETERMINE=1
  for CAS in derog-abandonne-jumeau derog-remplace-jumeau derog-gele-jumeau; do
    DIR_CAS="$WORK/mut-auteur-cas-$CAS"
    materialiser "$CAS" "$DIR_CAS"
    ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-auteur-$CAS-out.json" 2>"$WORK/mut-auteur-$CAS-err.txt" )
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/mut-auteur-$CAS-out.json" 2>/dev/null || echo '?')"
    [ "$ETAT_M" = "indéterminé" ] || MUT_AUTEUR_TOUS_INDETERMINE=0
    MUT_AUTEUR_DERNIER_ETAT="$ETAT_M"
  done
  if [ "$MUT_AUTEUR_TOUS_INDETERMINE" -eq 1 ]; then
    komut AUTEUR "état des jumeaux derog-abandonne/derog-remplace/derog-gele" "indéterminé (original, les trois)" "indéterminé (mutant non opposable)"
  else
    okmut AUTEUR "état des jumeaux derog-abandonne/derog-remplace/derog-gele · attendu (original) : indéterminé (derogation-sans-auteur) · obtenu (mutant) : au moins un jumeau rend la dérogation elle-même ($MUT_AUTEUR_DERNIER_ETAT) sans auteur nommé"
  fi
fi

# ---------- MUT-STRUCTURANTE — toute ligne sans statut compte comme ouverte ----------------------
if make_recalc_mutant STRUCTURANTE \
  'if structurante == "oui" and not (isinstance(statut, str) and statut.strip()):' \
  'if not (isinstance(statut, str) and statut.strip()):  # MUT-STRUCTURANTE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-structurante-cas"
  materialiser etat-en-cadrage-jumeau "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-structurante-out.json" 2>"$WORK/mut-structurante-err.txt" ); RC_M=$?
  if ! _verifier_plantage STRUCTURANTE "état de etat-en-cadrage-jumeau" "$WORK/mut-structurante-out.json" "$WORK/mut-structurante-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/mut-structurante-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "à planifier" ]; then
      komut STRUCTURANTE "état de etat-en-cadrage-jumeau" "à planifier (original)" "à planifier (mutant non opposable)"
    else
      okmut STRUCTURANTE "état de etat-en-cadrage-jumeau · attendu (original) : à planifier (registre clos) · obtenu (mutant) : $ETAT_M (le registre reste vu ouvert à tort)"
    fi
  fi
fi

# ---------- MUT-STATUT-REGISTRE — fermeture restreinte à ARBITRÉ seul (liste fermée) -------------
if make_recalc_mutant STATUT-REGISTRE \
  'if structurante == "oui" and not (isinstance(statut, str) and statut.strip()):' \
  'if structurante == "oui" and not (isinstance(statut, str) and statut.strip() == "ARBITRÉ"):  # MUT-STATUT-REGISTRE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-statut-registre-cas"
  materialiser registre-statut-inconnu "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-statut-registre-out.json" 2>"$WORK/mut-statut-registre-err.txt" ); RC_M=$?
  if ! _verifier_plantage STATUT-REGISTRE "état de registre-statut-inconnu" "$WORK/mut-statut-registre-out.json" "$WORK/mut-statut-registre-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0]["etat"])' "$WORK/mut-statut-registre-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "à planifier" ]; then
      komut STATUT-REGISTRE "état de registre-statut-inconnu" "à planifier (original)" "à planifier (mutant non opposable)"
    else
      okmut STATUT-REGISTRE "état de registre-statut-inconnu · attendu (original) : à planifier (« en cours » ferme la ligne) · obtenu (mutant) : $ETAT_M (« en cours » ne fermerait plus la ligne)"
    fi
  fi
fi

# ================================================================================================
# Mutants de l'agrégation (44-03, Tâche 2) — MUT-PROPAGATION, MUT-TERMINAL, MUT-TRI,
# MUT-AGREGATION-PLANS, MUT-PLANS-CLOS.
# ================================================================================================

# ---------- MUT-PROPAGATION — garde « phase indéterminée -> cycle indéterminé » neutralisée ------
if make_recalc_mutant PROPAGATION 'if indeterminees:' 'if False:  # MUT-PROPAGATION'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-propagation-cas"
  materialiser cycle-propagation "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-propagation-out.json" 2>"$WORK/mut-propagation-err.txt" ); RC_M=$?
  if ! _verifier_plantage PROPAGATION "raison du cycle de cycle-propagation" "$WORK/mut-propagation-out.json" "$WORK/mut-propagation-err.txt" "$RC_M"; then
    RAISON_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0].get("raison"))' "$WORK/mut-propagation-out.json" 2>/dev/null || echo '?')"
    if [ "$RAISON_M" = "phase-indeterminee:02-p" ]; then
      komut PROPAGATION "raison du cycle de cycle-propagation" "phase-indeterminee:02-p (original)" "phase-indeterminee:02-p (mutant non opposable)"
    else
      okmut PROPAGATION "raison du cycle de cycle-propagation · attendu (original) : phase-indeterminee:02-p · obtenu (mutant) : $RAISON_M (le cycle hérite de l'état de sa phase courante sans porter le code d'agrégation)"
    fi
  fi
fi

# ---------- MUT-TERMINAL — gelé compté terminal ---------------------------------------------------
if make_recalc_mutant TERMINAL \
  'TERMINAUX = frozenset({"close", "abandonné", "remplacé"})' \
  'TERMINAUX = frozenset({"close", "abandonné", "remplacé", "gelé"})  # MUT-TERMINAL'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-terminal-cas"
  materialiser cycle-gele "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-terminal-out.json" 2>"$WORK/mut-terminal-err.txt" ); RC_M=$?
  if ! _verifier_plantage TERMINAL "état du cycle de cycle-gele" "$WORK/mut-terminal-out.json" "$WORK/mut-terminal-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["etat"])' "$WORK/mut-terminal-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "gelé" ]; then
      komut TERMINAL "état du cycle de cycle-gele" "gelé (original, phase courante reste gelée)" "gelé (mutant non opposable)"
    else
      okmut TERMINAL "état du cycle de cycle-gele · attendu (original) : gelé (phase courante 01-p reste gelée, non terminale) · obtenu (mutant) : $ETAT_M (le cycle saute la phase gelée comme si elle était terminale)"
    fi
  fi
fi

# ---------- MUT-TRI — énumération des cycles en ordre inverse ------------------------------------
if make_recalc_mutant TRI 'key=lambda c: c["chemin"],  # tri, écriture' 'key=lambda c: c["chemin"], reverse=True,  # MUT-TRI'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-tri-cas"
  materialiser cycles-ordre "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" >"$WORK/mut-tri-out.txt" 2>"$WORK/mut-tri-err.txt" ); RC_M=$?
  if ! _verifier_plantage TRI "ordre des lignes de INDEX.md sur cycles-ordre" "$WORK/mut-tri-out.txt" "$WORK/mut-tri-err.txt" "$RC_M"; then
    L1=$(grep -n 'cycles/01-premier' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null | head -1 | cut -d: -f1)
    L2=$(grep -n 'cycles/02-second' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null | head -1 | cut -d: -f1)
    if [ -n "$L1" ] && [ -n "$L2" ] && [ "$L1" -lt "$L2" ]; then
      komut TRI "ordre des lignes de INDEX.md sur cycles-ordre" "01-premier avant 02-second (original)" "01-premier avant 02-second (mutant non opposable)"
    else
      okmut TRI "ordre des lignes de INDEX.md sur cycles-ordre · attendu (original) : 01-premier avant 02-second · obtenu (mutant) : 02-second avant 01-premier (lignes $L2/$L1)"
    fi
  fi
fi

# ---------- MUT-AGREGATION-PLANS — garde « plan indéterminé -> phase indéterminée » neutralisée --
if make_recalc_mutant AGREGATION-PLANS 'if plans_indetermines:' 'if False:  # MUT-AGREGATION-PLANS'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-agregation-plans-cas"
  materialiser plan-indetermine "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-agregation-plans-out.json" 2>"$WORK/mut-agregation-plans-err.txt" ); RC_M=$?
  if ! _verifier_plantage AGREGATION-PLANS "raison de la phase de plan-indetermine" "$WORK/mut-agregation-plans-out.json" "$WORK/mut-agregation-plans-err.txt" "$RC_M"; then
    RAISON_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0].get("raison"))' "$WORK/mut-agregation-plans-out.json" 2>/dev/null || echo '?')"
    if [ "$RAISON_M" = "plan-indetermine:01-a" ]; then
      komut AGREGATION-PLANS "raison de la phase de plan-indetermine" "plan-indetermine:01-a (original)" "plan-indetermine:01-a (mutant non opposable)"
    else
      okmut AGREGATION-PLANS "raison de la phase de plan-indetermine · attendu (original) : plan-indetermine:01-a · obtenu (mutant) : $RAISON_M (la phase hérite de l'état de son plan courant sans porter le code d'agrégation)"
    fi
  fi
fi

# ---------- MUT-PLANS-CLOS — verdict d'agrégation remplacé par « passé » -------------------------
if make_recalc_mutant PLANS-CLOS \
  'return "plans-clos" if type_derivation == "plans-agregation" else "passé"' \
  'return "passé"  # MUT-PLANS-CLOS'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-plans-clos-cas"
  materialiser plans-tous-clos "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-plans-clos-out.txt" 2>"$WORK/mut-plans-clos-err.txt" ); RC_M=$?
  if ! _verifier_plantage PLANS-CLOS "ligne de cloture.log de la phase sur plans-tous-clos" "$WORK/mut-plans-clos-out.txt" "$WORK/mut-plans-clos-err.txt" "$RC_M"; then
    if grep -Eq '  cycles/01-c/phases/01-p  inconnu  verdict=plans-clos  ' "$DIR_CAS/.planning/cloture.log" 2>/dev/null; then
      komut PLANS-CLOS "ligne de cloture.log de la phase sur plans-tous-clos" "verdict=plans-clos (original)" "verdict=plans-clos (mutant non opposable)"
    else
      okmut PLANS-CLOS "ligne de cloture.log de la phase sur plans-tous-clos · attendu (original) : verdict=plans-clos · obtenu (mutant) : $(grep 'cycles/01-c/phases/01-p ' "$DIR_CAS/.planning/cloture.log" 2>/dev/null)"
    fi
  fi
fi

# ================================================================================================
# Mutants du hors modèle et des garde-fous de chemin (44-04, Tâche 1) — MUT-HORS-MODELE,
# MUT-ANNEXES, MUT-LIEN-FICHIER, MUT-LIEN-DOSSIER, MUT-ECHAPPEMENT, MUT-TYPE-ECRITURE.
# ================================================================================================

# ---------- MUT-HORS-MODELE — classement de la racine et de l'arbre neutralisé -------------------
if make_recalc_mutant HORS-MODELE \
  'hors = _classer_racine(planning) + _classer_arbre_cycles(planning)' \
  'hors = []  # MUT-HORS-MODELE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-hors-modele-cas"
  materialiser hors-modele-racine "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-hors-modele-out.json" 2>"$WORK/mut-hors-modele-err.txt" ); RC_M=$?
  if ! _verifier_plantage HORS-MODELE "hors_modele de R40 (hors-modele-racine)" "$WORK/mut-hors-modele-out.json" "$WORK/mut-hors-modele-err.txt" "$RC_M"; then
    HM_M="$("$PYBIN" -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["hors_modele"]))' "$WORK/mut-hors-modele-out.json" 2>/dev/null || echo '?')"
    if [ "$HM_M" = "5" ]; then
      komut HORS-MODELE "hors_modele de R40" "5 entrées (original)" "5 entrées (mutant non opposable)"
    else
      okmut HORS-MODELE "hors_modele de R40 · attendu (original) : 5 entrées (BOARD.md, intel, notes.md, phases, workstreams) · obtenu (mutant) : $HM_M entrée(s) (aucun intrus n'entre plus dans la dérivation)"
    fi
  fi
fi

# ---------- MUT-ANNEXES — liste des annexes vidée : les annexes apparaissent hors modèle ---------
if make_recalc_mutant ANNEXES \
  'ANNEXES = frozenset({"_bancs", "recherches", "intel", "sketches", "_archive", "registres"})' \
  'ANNEXES = frozenset()  # MUT-ANNEXES'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-annexes-cas"
  materialiser hors-modele-racine "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-annexes-out.json" 2>"$WORK/mut-annexes-err.txt" ); RC_M=$?
  if ! _verifier_plantage ANNEXES "présence de _bancs dans hors_modele de R40" "$WORK/mut-annexes-out.json" "$WORK/mut-annexes-err.txt" "$RC_M"; then
    if grep -q '"_bancs"' "$WORK/mut-annexes-out.json" 2>/dev/null; then
      okmut ANNEXES "présence de _bancs dans hors_modele · attendu (original) : absent (annexe, jamais listée) · obtenu (mutant) : présent (les six annexes ne sont plus reconnues)"
    else
      komut ANNEXES "présence de _bancs dans hors_modele" "absent (original)" "absent (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-LIEN-FICHIER — garde de régularité neutralisée (PLAN.md en lien suivi) -----------
if make_recalc_mutant LIEN-FICHIER \
  'return stat.S_ISREG(os.lstat(chemin).st_mode)' \
  'return True  # MUT-LIEN-FICHIER'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-lien-fichier-cas"
  materialiser lien-fichier-plan "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-lien-fichier-out.json" 2>"$WORK/mut-lien-fichier-err.txt" ); RC_M=$?
  if ! _verifier_plantage LIEN-FICHIER "raison de lien-fichier-plan (R44)" "$WORK/mut-lien-fichier-out.json" "$WORK/mut-lien-fichier-err.txt" "$RC_M"; then
    RAISON_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][0].get("raison"))' "$WORK/mut-lien-fichier-out.json" 2>/dev/null || echo '?')"
    if [ "$RAISON_M" = "fichier-non-regulier:PLAN.md" ]; then
      komut LIEN-FICHIER "raison de lien-fichier-plan" "fichier-non-regulier:PLAN.md (original)" "fichier-non-regulier:PLAN.md (mutant non opposable)"
    else
      okmut LIEN-FICHIER "raison de lien-fichier-plan · attendu (original) : fichier-non-regulier:PLAN.md · obtenu (mutant) : $RAISON_M (le lien n'est plus rejeté au premier rideau — le second rideau SANS_SUIVI_DE_LIEN rattrape sans jamais laisser le jeton fuiter)"
    fi
  fi
  if grep -q "JETON-DEHORS-44" "$WORK/mut-lien-fichier-out.json" 2>/dev/null; then
    ko "MUT-LIEN-FICHIER jeton" "absent (même mutée, la garde SANS_SUIVI_DE_LIEN ne laisse jamais fuiter le contenu)" "présent" "-"
  fi
fi

# ---------- MUT-LIEN-DOSSIER — exclusion des liens de dossier neutralisée (cycles/02-lien suivi) -
if make_recalc_mutant LIEN-DOSSIER \
  'if type_ == "dossier" and NOM_UNITE.match(nom):  # cycle' \
  'if NOM_UNITE.match(nom):  # MUT-LIEN-DOSSIER'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-lien-dossier-cas"
  materialiser lien-dossier-cycle "$DIR_CAS"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-lien-dossier-out.json" 2>"$WORK/mut-lien-dossier-err.txt" ); RC_M=$?
  if ! _verifier_plantage LIEN-DOSSIER "hors_modele de lien-dossier-cycle (R43)" "$WORK/mut-lien-dossier-out.json" "$WORK/mut-lien-dossier-err.txt" "$RC_M"; then
    if grep -q '"cycles/02-lien"' "$WORK/mut-lien-dossier-out.json" 2>/dev/null; then
      komut LIEN-DOSSIER "hors_modele de lien-dossier-cycle" "cycles/02-lien présent (original)" "cycles/02-lien présent (mutant non opposable)"
    else
      okmut LIEN-DOSSIER "hors_modele de lien-dossier-cycle · attendu (original) : cycles/02-lien présent (type lien) · obtenu (mutant) : absent (le lien est désormais parcouru comme un cycle reconnu)"
    fi
  fi
fi

# ---------- MUT-ECHAPPEMENT — échappement de nom neutralisé dans le rendu de INDEX.md -------------
if make_recalc_mutant ECHAPPEMENT \
  'lignes.append("- `" + echapper_nom(entree["chemin"]) + "` (" + entree["type"] + ")")' \
  'lignes.append("- `" + entree["chemin"] + "` (" + entree["type"] + ")")  # MUT-ECHAPPEMENT'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-echappement-cas"
  MUT_NOM=$'01-x\n`y'
  mkdir -p "$DIR_CAS/.planning/cycles/$MUT_NOM"
  printf '%s' '{"planning_version": "cycles-v1"}' > "$DIR_CAS/.planning/config.json"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-echappement-out.txt" 2>"$WORK/mut-echappement-err.txt" ); RC_M=$?
  if ! _verifier_plantage ECHAPPEMENT "présence de \\u000a littéral dans INDEX.md (R45)" "$WORK/mut-echappement-out.txt" "$WORK/mut-echappement-err.txt" "$RC_M"; then
    if grep -qF '\u000a' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null; then
      komut ECHAPPEMENT "présence de \\u000a littéral dans INDEX.md" "présent (original)" "présent (mutant non opposable)"
    else
      MUT_LIGNES="$(wc -l < "$DIR_CAS/.planning/INDEX.md" 2>/dev/null | tr -d ' ')"
      okmut ECHAPPEMENT "présence de \\u000a littéral dans INDEX.md · attendu (original) : présent, 11 lignes · obtenu (mutant) : absent, $MUT_LIGNES lignes (le saut de ligne brut du nom casse le format une-entrée-par-ligne)"
    fi
  fi
fi

# ---------- MUT-TYPE-ECRITURE — garde de type sur les emplacements de SORTIE neutralisée ---------
# Distincte de MUT-HORS-MODELE (classement en LECTURE) : celle-ci vise le refus en ÉCRITURE, posé
# par 44-01 dans appliquer_ecritures, rejoué par R42 (volet écriture).
if make_recalc_mutant TYPE-ECRITURE \
  'if os.path.lexists(chemin_cible) and not est_fichier_regulier(chemin_cible):' \
  'if False:  # MUT-TYPE-ECRITURE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-type-ecriture-cas"
  materialiser modele-mauvais-type "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-type-ecriture-out.txt" 2>"$WORK/mut-type-ecriture-err.txt" ); RC_M=$?
  if ! _verifier_plantage TYPE-ECRITURE "message stderr de R42 (écriture, INDEX.md dossier)" "$WORK/mut-type-ecriture-out.txt" "$WORK/mut-type-ecriture-err.txt" "$RC_M"; then
    if grep -q "emplacement occupé" "$WORK/mut-type-ecriture-err.txt" 2>/dev/null; then
      komut TYPE-ECRITURE "message stderr de R42 (écriture)" "emplacement occupé ... (original)" "emplacement occupé ... (mutant non opposable)"
    else
      okmut TYPE-ECRITURE "message stderr de R42 (écriture) · attendu (original) : « emplacement occupé par autre chose qu'un fichier régulier » citant INDEX.md · obtenu (mutant) : $(tr '\n' ' ' < "$WORK/mut-type-ecriture-err.txt" 2>/dev/null) (rattrapé par le filet de sécurité générique, jamais une trace Python)"
    fi
  fi
fi

# ================================================================================================
# Mutants du cache incrémental (44-04, Tâche 2) — MUT-SIGNATURE-TEMPS, MUT-SCHEMA-CACHE,
# MUT-LIVRABLES-CACHE, MUT-CACHE-LECTURE-SEULE.
# ================================================================================================

# ---------- MUT-SIGNATURE-TEMPS — signature construite sur la date de modification (stat) --------
# Remplacement authoré dans la suite (jamais une API de date de fichier dans le moteur livré) :
# une signature qui varie avec le SEUL horodatage du fichier plutôt qu'avec son contenu.
if make_recalc_mutant SIGNATURE-TEMPS \
  'h = hash_contenu(chemin_fichier)' \
  'h = str(os.path.getmtime(chemin_fichier)) if os.path.exists(chemin_fichier) else None  # MUT-SIGNATURE-TEMPS'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-signature-temps-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
  for f in CADRAGE.md PLAN.md CLOTURE.md VERDICT.md SUMMARY.md; do
    touch "$DIR_CAS/.planning/cycles/01-traceur/phases/01-livree/$f"
  done
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-signature-temps-r52-out.json" 2>"$WORK/mut-signature-temps-r52-err.txt" ); RC_R52=$?
  R52_RECALCULEES_M="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/mut-signature-temps-r52-out.json" 2>/dev/null || echo '?')"
  MUT_VERDICT="$DIR_CAS/.planning/cycles/01-traceur/phases/01-livree/VERDICT.md"
  cp "$MUT_VERDICT" "$WORK/mut-signature-temps-verdict-ref.md"
  "$PYBIN" -c "
p = '$MUT_VERDICT'
t = open(p, encoding='utf-8').read()
t2 = t.replace('resultat: passé', 'resultat: échec')
open(p, 'w', encoding='utf-8').write(t2)
"
  touch -r "$WORK/mut-signature-temps-verdict-ref.md" "$MUT_VERDICT"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-signature-temps-r53-out.json" 2>"$WORK/mut-signature-temps-r53-err.txt" ); RC_R53=$?
  R53_RECALCULEES_M="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/mut-signature-temps-r53-out.json" 2>/dev/null || echo '?')"
  if ! _verifier_plantage SIGNATURE-TEMPS "unites_recalculees de R52/R53" "$WORK/mut-signature-temps-r53-out.json" "$WORK/mut-signature-temps-r53-err.txt" "$RC_R53"; then
    if [ "$R52_RECALCULEES_M" = "0" ] && [ "$R53_RECALCULEES_M" != "0" ]; then
      komut SIGNATURE-TEMPS "unites_recalculees de R52/R53" "0 puis >=1 (original)" "0 puis >=1 (mutant non opposable)"
    else
      okmut SIGNATURE-TEMPS "unites_recalculees de R52/R53 · attendu (original) : R52=0 (touch seul), R53>=1 (contenu changé) · obtenu (mutant) : R52=$R52_RECALCULEES_M, R53=$R53_RECALCULEES_M (au moins un des deux est inversé)"
    fi
  fi
fi

# ---------- MUT-SCHEMA-CACHE — contrôle de cache_schema_version neutralisé -----------------------
if make_recalc_mutant SCHEMA-CACHE \
  'if donnees.get("cache_schema_version") != CACHE_SCHEMA_VERSION:' \
  'if False:  # MUT-SCHEMA-CACHE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-schema-cache-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
  "$PYBIN" -c "
import json
p = '$DIR_CAS/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
d['cache_schema_version'] = 999
json.dump(d, open(p, 'w', encoding='utf-8'))
"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-schema-cache-out.json" 2>"$WORK/mut-schema-cache-err.txt" ); RC_M=$?
  if ! _verifier_plantage SCHEMA-CACHE "champ cache du rapport de R55 (version 999)" "$WORK/mut-schema-cache-out.json" "$WORK/mut-schema-cache-err.txt" "$RC_M"; then
    CACHE_M="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cache"])' "$WORK/mut-schema-cache-out.json" 2>/dev/null || echo '?')"
    if [ "$CACHE_M" = "autre-format" ]; then
      komut SCHEMA-CACHE "champ cache du rapport (version 999)" "autre-format (original)" "autre-format (mutant non opposable)"
    else
      okmut SCHEMA-CACHE "champ cache du rapport (version 999) · attendu (original) : autre-format · obtenu (mutant) : $CACHE_M (un cache d'un autre schéma est cru)"
    fi
  fi
fi

# ---------- MUT-LIVRABLES-CACHE — existence des livrables non revue à la reprise -----------------
if make_recalc_mutant LIVRABLES-CACHE \
  'if livrables_actuels is not None and livrables_actuels == entree_cache.get("empreinte_livrables"):  # cache-empreinte' \
  'if True:  # MUT-LIVRABLES-CACHE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-livrables-cache-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
  rm -f "$DIR_CAS/livrables/rapport.md"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-livrables-cache-out.json" 2>"$WORK/mut-livrables-cache-err.txt" ); RC_M=$?
  if ! _verifier_plantage LIVRABLES-CACHE "état de la phase de R58 après suppression du livrable" "$WORK/mut-livrables-cache-out.json" "$WORK/mut-livrables-cache-err.txt" "$RC_M"; then
    # Second scénario (R-CACHE2-01) : un octet du livrable réécrit à taille égale, sur un lab neuf.
    DIR_CAS2="$WORK/mut-livrables-cache-cas2"
    materialiser traceur "$DIR_CAS2"
    ( cd "$DIR_CAS2" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
    "$PYBIN" -c '
import sys
chemin = sys.argv[1]
octets = bytearray(open(chemin, "rb").read())
octets[0] = ord("M") if octets[0] != ord("M") else ord("L")
open(chemin, "wb").write(bytes(octets))
' "$DIR_CAS2/livrables/rapport.md"
    ( cd "$DIR_CAS2" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-livrables-cache-out2.json" 2>"$WORK/mut-livrables-cache-err2.txt" ); RC_M2=$?
    if ! _verifier_plantage LIVRABLES-CACHE "état de la phase de R-CACHE2-01 après réécriture du livrable" "$WORK/mut-livrables-cache-out2.json" "$WORK/mut-livrables-cache-err2.txt" "$RC_M2"; then
      LIVR_R58_TUE=0; LIVR_RC2_TUE=0
      grep -qF 'livrable absent : livrables/rapport.md' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null || LIVR_R58_TUE=1
      grep -qF 'modifié après la clôture' "$DIR_CAS2/.planning/INDEX.md" 2>/dev/null || LIVR_RC2_TUE=1
      if [ "$LIVR_R58_TUE" -eq 1 ] && [ "$LIVR_RC2_TUE" -eq 1 ]; then
        okmut LIVRABLES-CACHE "tué par R58 ET par R-CACHE2-01 · R58 : attendu (original) : indéterminé (livrable-absent:livrables/rapport.md) · obtenu (mutant) : $(grep 'cycles/01-traceur' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null) · R-CACHE2-01 : attendu (original) : indéterminé (livrable ou plan modifié après la clôture) · obtenu (mutant) : $(grep 'cycles/01-traceur' "$DIR_CAS2/.planning/INDEX.md" 2>/dev/null) (l'état repris du cache reste en place malgré le livrable manquant ou réécrit)"
      else
        komut LIVRABLES-CACHE "état après suppression (R58) puis après réécriture (R-CACHE2-01) du livrable" "indéterminé dans les deux scénarios (original)" "mutant non opposable : R58 tué=$LIVR_R58_TUE, R-CACHE2-01 tué=$LIVR_RC2_TUE"
      fi
    fi
  fi
fi

# ---------- MUT-CACHE-ECRIT — les `ecrit:` de l'entrée de cache crus sans relire le PLAN.md (A8, P46 lot B, b3) ----------
# Deux mutants, un par contrôle : (1) la relecture retirée (les `ecrit:` du cache font foi : le comportement d'avant la correction) rend le cache forgé
# opposable ; (2) l'égalité `ecrit` cache / PLAN.md retirée laisse reprendre une entrée dont les `ecrit:` ne sont pas ceux du plan.
if make_recalc_mutant CACHE-ECRIT-RELECTURE \
  '# cache-ecrit-reel' \
  'ecrit_reel = entree_cache.get("ecrit") or []  # MUT-CACHE-ECRIT-RELECTURE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-cache-ecrit-relecture-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
  "$PYBIN" -c "
import json
p = '$DIR_CAS/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
e = d['unites']['cycles/01-traceur/phases/01-livree']
e['ecrit'] = []
e['empreinte_livrables'] = ['ok', None]
json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False)
"
  printf 'REECRIT\n' > "$DIR_CAS/livrables/rapport.md"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-cache-ecrit-relecture-out.json" 2>"$WORK/mut-cache-ecrit-relecture-err.txt" ); RC_M=$?
  if ! _verifier_plantage CACHE-ECRIT-RELECTURE "état de 01-livree sur cache forgé (R-CACHE3-01)" "$WORK/mut-cache-ecrit-relecture-out.json" "$WORK/mut-cache-ecrit-relecture-err.txt" "$RC_M"; then
    if grep -qF 'modifié après la clôture' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null; then
      komut CACHE-ECRIT-RELECTURE "état de 01-livree sur cache forgé" "indéterminé (original)" "indéterminé (mutant non opposable)"
    else
      okmut CACHE-ECRIT-RELECTURE "état de 01-livree sur cache forgé · attendu (original) : indéterminé (livrable modifié après la clôture) · obtenu (mutant) : $(grep 'traceur' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null | head -1 | cut -c1-160) (le cache forgé est cru, un livrable réécrit reste close)"
    fi
  fi
fi
if make_recalc_mutant CACHE-ECRIT-EGALITE \
  'if entree_cache.get("ecrit") == ecrit_reel:' \
  'if True:  # MUT-CACHE-ECRIT-EGALITE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-cache-ecrit-egalite-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
  "$PYBIN" -c "
import json
p = '$DIR_CAS/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
d['unites']['cycles/01-traceur/phases/01-livree']['ecrit'] = ['autre-fichier-forge.md']
json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False)
"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-cache-ecrit-egalite-out.json" 2>"$WORK/mut-cache-ecrit-egalite-err.txt" ); RC_M=$?
  if ! _verifier_plantage CACHE-ECRIT-EGALITE "unites_recalculees sur cache dont seul ecrit est forgé (R-CACHE3-01 jumeau)" "$WORK/mut-cache-ecrit-egalite-out.json" "$WORK/mut-cache-ecrit-egalite-err.txt" "$RC_M"; then
    RECALC_M="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["unites_recalculees"])' "$WORK/mut-cache-ecrit-egalite-out.json" 2>/dev/null || echo '?')"
    if [ "$RECALC_M" = "1" ]; then
      komut CACHE-ECRIT-EGALITE "unites_recalculees sur ecrit forgé" "1 (original)" "1 (mutant non opposable)"
    else
      okmut CACHE-ECRIT-EGALITE "unites_recalculees sur ecrit forgé · attendu (original) : 1 (l'entrée aux ecrit: étrangers n'est pas reprise) · obtenu (mutant) : $RECALC_M (reprise sans comparer les ecrit: au PLAN.md)"
    fi
  fi
fi

# ---------- MUT-CACHE-LECTURE-SEULE — la lecture seule chargerait le cache -----------------------
if make_recalc_mutant CACHE-LECTURE-SEULE \
  '(deriver_cycle(c, racine_lab) for c in modele["cycles"]),' \
  '(deriver_cycle(c, racine_lab, {"existant": (charger_cache(planning_abs)[1].get("unites") or {}), "nouveau": {}, "recalculees": 0, "reprises": 0}) for c in modele["cycles"]),  # MUT-CACHE-LECTURE-SEULE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-cache-lecture-seule-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
  "$PYBIN" -c "
import json
p = '$DIR_CAS/.planning/.recalc-cache.json'
d = json.load(open(p, encoding='utf-8'))
cle = 'cycles/01-traceur/phases/02-en-cours'
entree = d['unites'][cle]
entree['etat'] = 'close'
entree['raison'] = None
json.dump(d, open(p, 'w', encoding='utf-8'))
"
  ( cd "$DIR_CAS" && bash "$MR" --read-only >"$WORK/mut-cache-lecture-seule-out.json" 2>"$WORK/mut-cache-lecture-seule-err.txt" ); RC_M=$?
  if ! _verifier_plantage CACHE-LECTURE-SEULE "état de 02-en-cours en --read-only sur cache forgé (R57)" "$WORK/mut-cache-lecture-seule-out.json" "$WORK/mut-cache-lecture-seule-err.txt" "$RC_M"; then
    ETAT_M="$("$PYBIN" -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["cycles"][0]["phases"][1]["etat"])' "$WORK/mut-cache-lecture-seule-out.json" 2>/dev/null || echo '?')"
    if [ "$ETAT_M" = "à exécuter" ]; then
      komut CACHE-LECTURE-SEULE "état de 02-en-cours en --read-only sur cache forgé" "à exécuter (original, cache jamais lu)" "à exécuter (mutant non opposable)"
    else
      okmut CACHE-LECTURE-SEULE "état de 02-en-cours en --read-only sur cache forgé · attendu (original) : à exécuter (cache jamais consulté) · obtenu (mutant) : $ETAT_M (le JSON de lecture seule reflète l'entrée forgée)"
    fi
  fi
fi

# ================================================================================================
# F3 / F5 — corrections hors de la portée d'une mutation à motif fixe UNE LIGNE (structurelles :
# F3 déplace une consommation d'itérateur DANS le try, F5 ajoute une branche de fermeture de
# descripteur). Preuve par monkeypatch ciblé sur le corps Python réel extrait de $RECALC, jamais
# une course sur disque (non déterministe). Le jumeau « régressé » est reconstruit par
# remplacement de bloc EXACT (assert count==1), jamais deviné.
# ================================================================================================
F3F5_BODY_REEL="$WORK/f3f5-corps-reel.py"
awk '/<<.PY_RECALC_PLANNING_EOF.$/{f=1;next} /^PY_RECALC_PLANNING_EOF$/{f=0} f' "$RECALC" > "$F3F5_BODY_REEL"

F3F5_AIDE_PY="$WORK/f3f5-aide.py"
cat > "$F3F5_AIDE_PY" <<'PY_F3F5_AIDE_EOF'
import multiprocessing
import os
import sys
import tempfile
import time

BLOC_F3_CORRIGE = '''def _lister_entrees(dossier):
    try:
        entrees = os.scandir(dossier)
        return {e.name for e in entrees}
    except OSError:
        return set()'''

BLOC_F3_REGRESSE = '''def _lister_entrees(dossier):
    try:
        entrees = os.scandir(dossier)
    except OSError:
        return set()
    return {e.name for e in entrees}'''

BLOC_F5_CORRIGE = '''    dossier = os.path.dirname(chemin) or "."
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
    return True'''

BLOC_F5_REGRESSE = '''    dossier = os.path.dirname(chemin) or "."
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
    return True'''


def charger_espace(chemin_corps):
    src = open(chemin_corps, encoding="utf-8").read()
    ns = {}
    exec(compile(src.split("\ndef main()")[0], chemin_corps, "exec"), ns)
    return ns


def regresser(chemin_corps, bloc_corrige, bloc_regresse, suffixe):
    src = open(chemin_corps, encoding="utf-8").read()
    if src.count(bloc_corrige) != 1:
        print("BLOC_INTROUVABLE")
        sys.exit(2)
    tmp = chemin_corps + suffixe
    open(tmp, "w", encoding="utf-8").write(src.replace(bloc_corrige, bloc_regresse))
    return tmp


class FauxEntree:
    def __init__(self, name):
        self.name = name


class FauxIterateurCasse:
    def __init__(self):
        self._n = 0

    def __iter__(self):
        return self

    def __next__(self):
        self._n += 1
        if self._n == 1:
            return FauxEntree("premier")
        raise OSError("boom-mid-iteration")


def sonder_f3(chemin_corps):
    ns = charger_espace(chemin_corps)
    _lister_entrees = ns["_lister_entrees"]
    reel_scandir = os.scandir
    os.scandir = lambda _d: FauxIterateurCasse()
    try:
        try:
            resultat = _lister_entrees("/peu-importe-monkeypatch")
            print("CRASH=False RESULTAT=%r" % (resultat,))
        except OSError as e:
            print("CRASH=True MESSAGE=%s" % (e,))
    finally:
        os.scandir = reel_scandir


def sonder_f5(chemin_corps):
    import resource
    import tempfile
    import shutil

    ns = charger_espace(chemin_corps)
    ecrire_si_different = ns["ecrire_si_different"]
    work = tempfile.mkdtemp(prefix="f5-probe-")
    soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
    resource.setrlimit(resource.RLIMIT_NOFILE, (48, hard))
    reel_fchmod = os.fchmod
    def fchmod_casse(fd, mode):
        raise OSError("simulate-fchmod-failure")
    os.fchmod = fchmod_casse
    exhausted = False
    try:
        for i in range(200):
            cible = os.path.join(work, "fichier-%d.txt" % i)
            try:
                ecrire_si_different(cible, "contenu-%d" % i)
            except OSError as e:
                if getattr(e, "errno", None) == 24 or "Too many open" in str(e):
                    exhausted = True
                    break
                continue
    finally:
        os.fchmod = reel_fchmod
        resource.setrlimit(resource.RLIMIT_NOFILE, (soft, hard))
        shutil.rmtree(work, ignore_errors=True)
    print("EXHAUSTED=%s" % exhausted)


def sonder_l2(chemin_corps):
    ns = charger_espace(chemin_corps)
    _formater_ligne_journal = ns["_formater_ligne_journal"]
    LIGNE_JOURNAL_RE = ns["LIGNE_JOURNAL_RE"]
    payload = "1  FORGED-RECORD  verdict=close  tentative=99  date=observation"
    unite = {
        "chemin": "cycles/00-temoin/phases/00-temoin",
        "auteur": "quelquun",
        "verdict": "passé",
        "tentative": payload,
    }
    ligne = _formater_ligne_journal("2026-09-28T00:00:00+00:00", unite)
    m = LIGNE_JOURNAL_RE.match(ligne)
    print("LIGNE=%r" % ligne)
    print("MATCH=%s" % bool(m))
    print("NB_VERDICT=%d" % ligne.count("verdict="))
    print("NB_TENTATIVE=%d" % ligne.count("tentative="))


# ---------- Lot 8 — `_ouvrable` sur une FIFO, bornée par `multiprocessing` (aucun `timeout`/
# `gtimeout` sur ce poste) : la fonction réelle est appelée dans un PROCESSUS FILS, `.join(delai)`
# borne l'attente, `.terminate()` le tue s'il n'est pas revenu — jamais un blocage de la suite. -----
BLOC_L8_ONONBLOCK_CORRIGE = '''            fd = os.open(chemin, os.O_RDONLY | os.O_NONBLOCK)'''

BLOC_L8_ONONBLOCK_REGRESSE = '''            fd = os.open(chemin, os.O_RDONLY)  # MUT-LOT8-ONONBLOCK (retrait de O_NONBLOCK)'''


def _l8_cible_ouvrable(chemin_corps, chemin_fifo, q):
    ns = charger_espace(chemin_corps)
    _ouvrable = ns["_ouvrable"]
    q.put(_ouvrable(chemin_fifo, False))


def sonder_ouvrable_fifo(chemin_corps, delai):
    # Contexte `fork` EXPLICITE (jamais le défaut `spawn` de macOS/Windows) : ce script n'a pas de
    # garde `if __name__ == "__main__":` — sous `spawn`, le processus fils RÉ-IMPORTE le module
    # `__main__` et ré-exécute tout le code de niveau module (dont ce même appel), ce qui plante
    # avant même d'atteindre la FIFO. `fork` (POSIX, toujours disponible sur ce poste bash/zsh) ne
    # ré-exécute rien : le fils hérite de l'état déjà construit.
    ctx = multiprocessing.get_context("fork")
    d = tempfile.mkdtemp(prefix="l8-ouvrable-fifo-")
    chemin_fifo = os.path.join(d, "FIFO")
    os.mkfifo(chemin_fifo)
    q = ctx.Queue()
    p = ctx.Process(target=_l8_cible_ouvrable, args=(chemin_corps, chemin_fifo, q))
    t0 = time.time()
    p.start()
    p.join(delai)
    dt = time.time() - t0
    if p.is_alive():
        p.terminate()
        p.join()
        print("BLOQUE=oui DUREE=%.2f" % dt)
    else:
        resultat = q.get() if not q.empty() else None
        print("BLOQUE=non DUREE=%.2f RESULTAT=%r" % (dt, resultat))


mode = sys.argv[1]
chemin_corps_reel = sys.argv[2]
if mode == "f3-fixed":
    sonder_f3(chemin_corps_reel)
elif mode == "f3-regresse":
    sonder_f3(regresser(chemin_corps_reel, BLOC_F3_CORRIGE, BLOC_F3_REGRESSE, ".f3-regresse.py"))
elif mode == "f5-fixed":
    sonder_f5(chemin_corps_reel)
elif mode == "f5-regresse":
    sonder_f5(regresser(chemin_corps_reel, BLOC_F5_CORRIGE, BLOC_F5_REGRESSE, ".f5-regresse.py"))
elif mode == "l2":
    sonder_l2(chemin_corps_reel)
elif mode == "ouvrable-fifo-fixed":
    sonder_ouvrable_fifo(chemin_corps_reel, float(sys.argv[3]))
elif mode == "ouvrable-fifo-regresse":
    sonder_ouvrable_fifo(
        regresser(chemin_corps_reel, BLOC_L8_ONONBLOCK_CORRIGE, BLOC_L8_ONONBLOCK_REGRESSE, ".l8-ononblock-regresse.py"),
        float(sys.argv[3]),
    )
else:
    print("MODE_INCONNU")
    sys.exit(2)
PY_F3F5_AIDE_EOF

# ---------- F3 — _lister_entrees : erreur d'itération toujours absorbée --------------------------
F3_FIXE_OUT="$("$PYBIN" "$F3F5_AIDE_PY" f3-fixed "$F3F5_BODY_REEL" 2>&1)"
if [ "$F3_FIXE_OUT" = "CRASH=False RESULTAT=set()" ]; then
  ok "F3 _lister_entrees : erreur d'itération de scandir absorbée par le try, aucune trace Python brute"
else
  ko "F3 _lister_entrees (code réel)" "CRASH=False RESULTAT=set()" "$F3_FIXE_OUT" "-"
fi

F3_REGRESSE_OUT="$("$PYBIN" "$F3F5_AIDE_PY" f3-regresse "$F3F5_BODY_REEL" 2>&1)"
if echo "$F3_REGRESSE_OUT" | grep -q "^CRASH=True"; then
  okmut LISTER-ENTREES "erreur d'itération de scandir · attendu (original) : absorbée, set() · obtenu (mutant, consommation hors du try) : $F3_REGRESSE_OUT"
else
  komut LISTER-ENTREES "erreur d'itération de scandir" "CRASH=True (mutant)" "$F3_REGRESSE_OUT (mutant non opposable)"
fi

# ---------- F5 — ecrire_si_different : descripteur toujours fermé sur le chemin d'échec ----------
F5_FIXE_OUT="$("$PYBIN" "$F3F5_AIDE_PY" f5-fixed "$F3F5_BODY_REEL" 2>&1)"
if [ "$F5_FIXE_OUT" = "EXHAUSTED=False" ]; then
  ok "F5 ecrire_si_different : descripteur toujours fermé (200 échecs de fchmod injectés, pas d'épuisement)"
else
  ko "F5 ecrire_si_different (code réel)" "EXHAUSTED=False" "$F5_FIXE_OUT" "-"
fi

F5_REGRESSE_OUT="$("$PYBIN" "$F3F5_AIDE_PY" f5-regresse "$F3F5_BODY_REEL" 2>&1)"
if [ "$F5_REGRESSE_OUT" = "EXHAUSTED=True" ]; then
  okmut ECRIRE-SI-DIFFERENT-FD "épuisement de descripteurs sur 200 échecs de fchmod injectés · attendu (original) : jamais · obtenu (mutant, fermeture retirée du chemin d'échec) : épuisé"
else
  komut ECRIRE-SI-DIFFERENT-FD "épuisement de descripteurs sur 200 échecs de fchmod injectés" "EXHAUSTED=True (mutant)" "$F5_REGRESSE_OUT (mutant non opposable)"
fi

# ================================================================================================
# F2 — un mutant par marqueur `# motif-*` de detection_gsd(), chacun sur une fixture qui isole sa
# branche (6 marqueurs qui n'avaient encore aucun mutant, plus les deux issus du scindage lot 2
# de `motif-code-2-ou-3`). `motif-code-2-ou-3` lui-même reste hors mandat lot 1 (décision en
# attente) — les deux marqueurs qui le remplacent sont couverts en fin de bloc (lot 2).
# ================================================================================================

# ---------- recalc_forcer_candidats_bash — substitution de SCÉNARIO (pas un mutant sémantique) ---
# F1/F44-07 (lot 5) : bash est désormais résolu par CANDIDATS_BASH (chemins absolus fixes), jamais
# par le PATH hérité — restreindre PATH (ancienne technique MUT-BASH-INTROUVABLE/MUT-SOUS-PROCESSUS
# ci-dessous) ne force plus la branche « aucun candidat valide », puisque `/bin/bash` reste résolu
# quel que soit PATH. Cette fonction substitue la liste CANDIDATS_BASH elle-même dans une copie
# déjà produite (même technique de substitution awk par motif fixe unique que make_recalc_mutant),
# pour forcer le scénario SANS jamais toucher au `/bin` ou `/usr/bin` réels du poste.
recalc_forcer_candidats_bash() { # <fichier_recalc> <nouvelle_expression_python_du_tuple>
  local fichier="$1" nouveaux="$2"
  local motif='CANDIDATS_BASH = ("/bin/bash", "/usr/bin/bash")'
  local n tmp
  n="$(grep -Fc -- "$motif" "$fichier")"
  if [ "$n" -ne 1 ]; then
    echo "recalc_forcer_candidats_bash: motif CANDIDATS_BASH absent ou ambigu (n=$n)" >&2
    return 1
  fi
  tmp="$fichier.candidats"
  RFCB_MOTIF_ENV="$motif" RFCB_REPL_ENV="CANDIDATS_BASH = $nouveaux" awk '
    index($0, ENVIRON["RFCB_MOTIF_ENV"]) {
      match($0, /^[ \t]*/)
      print substr($0, RSTART, RLENGTH) ENVIRON["RFCB_REPL_ENV"]
      next
    }
    { print }
  ' "$fichier" > "$tmp"
  if cmp -s "$tmp" "$fichier"; then
    echo "recalc_forcer_candidats_bash: substitution sans effet" >&2
    rm -f "$tmp"
    return 1
  fi
  if ! bash -n "$tmp" 2>/dev/null; then
    echo "recalc_forcer_candidats_bash: fichier résultant syntaxiquement invalide (bash -n)" >&2
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$fichier"
  chmod +x "$fichier"
  return 0
}

# ---------- MUT-BASH-INTROUVABLE — repli « bash introuvable » changé en non-gsd ------------------
# CANDIDATS_BASH forcé vers deux chemins qui n'existent nulle part sous $WORK : aucun candidat
# valide, quel que soit le PATH hérité — c'est désormais la SEULE façon d'atteindre cette branche.
if make_recalc_mutant BASH-INTROUVABLE 'return "non-concluante"  # motif-bash-introuvable' 'return "non-gsd"  # MUT-BASH-INTROUVABLE'; then
  MR="$MUT_DIR/recalc-planning.sh"
  if recalc_forcer_candidats_bash "$MR" "(\"$WORK/mut-bash-introuvable-inexistant-1\", \"$WORK/mut-bash-introuvable-inexistant-2\")"; then
    DIR_CAS="$WORK/mut-bash-introuvable-cas"
    materialiser traceur "$DIR_CAS"
    ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" "$BASH_BIN" "$MR" >"$WORK/mut-bash-introuvable-out.txt" 2>"$WORK/mut-bash-introuvable-err.txt" ); RC_M=$?
    if ! _verifier_plantage BASH-INTROUVABLE "code de sortie sur bash introuvable (aucun candidat CANDIDATS_BASH valide)" "$WORK/mut-bash-introuvable-out.txt" "$WORK/mut-bash-introuvable-err.txt" "$RC_M"; then
      if [ "$RC_M" -ne 3 ]; then
        okmut BASH-INTROUVABLE "code de sortie sur bash introuvable · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture malgré un interpréteur bash introuvable)"
      else
        komut BASH-INTROUVABLE "code de sortie sur bash introuvable" "3" "$RC_M (mutant non opposable)"
      fi
    fi
  else
    komut BASH-INTROUVABLE "substitution de CANDIDATS_BASH appliquée" "réussie" "ÉCHEC (voir stderr du harnais)"
  fi
fi

# ---------- MUT-SOUS-PROCESSUS — repli « sous-processus en échec » changé en non-gsd -------------
# Scénario distinct de MUT-BASH-INTROUVABLE : le premier candidat CANDIDATS_BASH est un fichier
# RÉGULIER (donc résolu — `_bash_candidat_valide` ne vérifie que la régularité, jamais le bit
# exécutable ni le contenu), mais ce n'est pas un exécutable valide (aucun shebang) — exec échoue à
# l'exécution (ENOEXEC), après la résolution, capturé par le except Exception générique.
if make_recalc_mutant SOUS-PROCESSUS 'return "non-concluante"  # motif-sous-processus-en-echec' 'return "non-gsd"  # MUT-SOUS-PROCESSUS'; then
  MR="$MUT_DIR/recalc-planning.sh"
  FAUX_BASH="$WORK/mut-sous-processus-faux-bash"
  printf 'ceci-n-est-pas-un-script-valide\n' > "$FAUX_BASH"
  chmod +x "$FAUX_BASH"
  if recalc_forcer_candidats_bash "$MR" "(\"$FAUX_BASH\", \"$WORK/mut-sous-processus-inexistant\")"; then
    DIR_CAS="$WORK/mut-sous-processus-cas"
    materialiser traceur "$DIR_CAS"
    ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" "$BASH_BIN" "$MR" >"$WORK/mut-sous-processus-out.txt" 2>"$WORK/mut-sous-processus-err.txt" ); RC_M=$?
    if ! _verifier_plantage SOUS-PROCESSUS "code de sortie sur sous-processus détecteur en échec (bash résolu, exec invalide)" "$WORK/mut-sous-processus-out.txt" "$WORK/mut-sous-processus-err.txt" "$RC_M"; then
      if [ "$RC_M" -ne 3 ]; then
        okmut SOUS-PROCESSUS "code de sortie sur sous-processus détecteur en échec · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture malgré une détection non concluante)"
      else
        komut SOUS-PROCESSUS "code de sortie sur sous-processus détecteur en échec" "3" "$RC_M (mutant non opposable)"
      fi
    fi
  else
    komut SOUS-PROCESSUS "substitution de CANDIDATS_BASH appliquée" "réussie" "ÉCHEC (voir stderr du harnais)"
  fi
fi

# ================================================================================================
# Aides partagées (item 2a/2b, lot 4) — cinq scénarios de détection matérialisés par une fonction
# de setup dédiée, sur le socle commun `traceur`.
# ================================================================================================
setup_terrain_libre() { :; }
setup_marqueur_racine() { printf -- '---\ngsd_state_version: 1.0\n---\n' > "$1/.planning/STATE.md"; }
setup_marqueur_compartiment() {
  mkdir -p "$1/.planning/workstreams/gouvernance-banc"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$1/.planning/workstreams/gouvernance-banc/STATE.md"
}
setup_partition_compartiment() {
  mkdir -p "$1/.planning/workstreams/gouvernance-banc"
  printf -- '---\nworkstream: gouvernance-banc\ncreated: 2026-09-28\n---\n' > "$1/.planning/workstreams/gouvernance-banc/STATE.md"
}
setup_socle_signal() {
  printf -- '---\nplanning_version: "2.0"\n---\n' > "$1/.planning/STATE.md"
  printf '%s' '{}' > "$1/package.json"
}

# ================================================================================================
# R-ORACLE-DIFFERENTIEL (item 2b, lot 4) — le verdict d'écriture du moteur correspond TOUJOURS à
# celui du VRAI détecteur lancé directement avec un GSD_HOME valide : détecteur 3 -> moteur écrit
# (0) ; détecteur 0 ou 2 -> moteur refuse (3). Deux labs distincts (jamais le même disque avant/
# après) pour ne dépendre d'aucun ordre d'exécution.
# ================================================================================================
oracle_differentiel() { # <label> <fn_setup>
  local label="$1" fn_setup="$2"
  local dir_oracle="$WORK/oracle-$label-detecteur" dir_moteur="$WORK/oracle-$label-moteur"
  local code_detecteur code_moteur code_attendu
  materialiser traceur "$dir_oracle"; "$fn_setup" "$dir_oracle"
  materialiser traceur "$dir_moteur"; "$fn_setup" "$dir_moteur"
  ( cd "$dir_oracle" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet --path .planning >/dev/null 2>"$WORK/oracle-$label-detecteur-err.txt" )
  code_detecteur=$?
  ( cd "$dir_moteur" && bash "$RECALC" >"$WORK/oracle-$label-moteur-out.txt" 2>"$WORK/oracle-$label-moteur-err.txt" )
  code_moteur=$?
  case "$code_detecteur" in
    # GATE-14 (45-02, P45-D-02) : le lab traceur adhère (cycles-v1). Détecteur 3 (terrain libre) ET
    # détecteur 2 (migration, levée sous adhésion) -> le moteur écrit (0) ; détecteur 0 (moteur GSD
    # actif) -> refus (3). Le refus du code 2 SANS adhésion est couvert par R-GATE14-A.
    3|2) code_attendu=0 ;;
    0) code_attendu=3 ;;
    *) ko "R-ORACLE-DIFFERENTIEL [$label] code du détecteur direct" "0, 2 ou 3" "$code_detecteur" "-"; return ;;
  esac
  if [ "$code_moteur" -eq "$code_attendu" ]; then
    ok "R-ORACLE-DIFFERENTIEL [$label] détecteur direct=$code_detecteur -> moteur=$code_moteur (attendu $code_attendu)"
  else
    ko "R-ORACLE-DIFFERENTIEL [$label] code moteur" "$code_attendu (détecteur direct=$code_detecteur)" "$code_moteur" "$(cat "$WORK/oracle-$label-moteur-out.txt")"
  fi
}
oracle_differentiel terrain-libre setup_terrain_libre
oracle_differentiel marqueur-racine setup_marqueur_racine
oracle_differentiel marqueur-compartiment setup_marqueur_compartiment
oracle_differentiel partition-compartiment setup_partition_compartiment
oracle_differentiel socle-signal setup_socle_signal

# ================================================================================================
# R-MATRICE-ENV (item 2a, lot 4) — le verdict de détection ne dépend JAMAIS de l'environnement
# hérité : code de sortie IDENTIQUE sous GSD_HOME normal/inexistant/vide/piégé (faux gsd-core), et
# sous CLAUDE_CONFIG_DIR/HOME vides (GSD_HOME absent de l'environnement) — six colonnes, sur les
# cinq mêmes scénarios. Quand le verdict écrit (code 0), le contenu produit (INDEX.md) est en plus
# comparé octet pour octet à la première colonne qui a écrit.
# ================================================================================================
MATRICE_VIDE_1="$(mktemp -d)"; MATRICE_VIDE_2="$(mktemp -d)"; MATRICE_VIDE_3="$(mktemp -d)"
MATRICE_FAUX_GSD="$(mktemp -d)"; mkdir -p "$MATRICE_FAUX_GSD/bin"

# Colonnes F1/F44-07 (lot 5, correction de classe) : le PATH hérité, BASH_ENV, ENV et une fonction
# exportée ne doivent JAMAIS atteindre le sous-processus détecteur — mesuré : avant lot 5, un `awk`
# factice en tête de PATH suffisait à faire mentir `has_frontmatter_key` (marqueur GSD introuvable)
# et écrire sur un lab GSD réel. `ghome-piege` (déjà présent) reste INERTE sur le verdict, prouvant
# seulement qu'un `bin/` vide sous GSD_HOME ne change rien — les colonnes ci-dessous testent le
# PATH/l'environnement du sous-processus lui-même, jamais exercé jusqu'ici.
MATRICE_FAUX_AWK_DIR="$(mktemp -d)"
printf '#!/bin/sh\nexit 1\n' > "$MATRICE_FAUX_AWK_DIR/awk"
chmod +x "$MATRICE_FAUX_AWK_DIR/awk"
MATRICE_FAUX_BASH_DIR="$(mktemp -d)"
printf '#!/bin/sh\nexit 66\n' > "$MATRICE_FAUX_BASH_DIR/bash"
chmod +x "$MATRICE_FAUX_BASH_DIR/bash"
MATRICE_BASH_ENV_AWK="$WORK/matrice-bash-env-awk.sh"
printf 'awk() { return 1; }\n' > "$MATRICE_BASH_ENV_AWK"

matrice_env() { # <label> <fn_setup> <code_attendu>
  local label="$1" fn_setup="$2" code_attendu="$3"
  local combos="normal ghome-inexistant ghome-vide ghome-piege claude-config-vide home-vide
    awk-piege bash-piege bash-env-awk bash-func-awk env-var"
  local combo dir rc ref_index=""
  for combo in $combos; do
    dir="$WORK/matrice-$label-$combo"
    materialiser traceur "$dir"
    "$fn_setup" "$dir"
    case "$combo" in
      normal)
        ( cd "$dir" && bash "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      ghome-inexistant)
        ( cd "$dir" && GSD_HOME="$WORK/matrice-inexistant-$label" bash "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      ghome-vide)
        ( cd "$dir" && GSD_HOME="$MATRICE_VIDE_1" bash "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      ghome-piege)
        ( cd "$dir" && GSD_HOME="$MATRICE_FAUX_GSD" bash "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      claude-config-vide)
        ( cd "$dir" && unset GSD_HOME; CLAUDE_CONFIG_DIR="$MATRICE_VIDE_2" bash "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      home-vide)
        ( cd "$dir" && unset GSD_HOME CLAUDE_CONFIG_DIR; HOME="$MATRICE_VIDE_3" bash "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      awk-piege)
        # `$BASH_BIN` (chemin absolu) pour l'invocation EXTÉRIEURE : le PATH poison est destiné au
        # sous-processus détecteur, jamais à l'interpréteur qui lance recalc-planning.sh lui-même.
        ( cd "$dir" && PATH="$MATRICE_FAUX_AWK_DIR:$PATH" "$BASH_BIN" "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      bash-piege)
        ( cd "$dir" && PATH="$MATRICE_FAUX_BASH_DIR:$PATH" "$BASH_BIN" "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      bash-env-awk)
        ( cd "$dir" && BASH_ENV="$MATRICE_BASH_ENV_AWK" "$BASH_BIN" "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      bash-func-awk)
        # Fonction `awk` EXPORTÉE (mécanisme `BASH_FUNC_awk%%` de bash) depuis un sous-shell créé
        # pour l'occasion, puis `exec` vers l'invocation normale — l'export survit à l'`exec`.
        ( cd "$dir" && "$BASH_BIN" -c 'awk() { return 1; }; export -f awk; exec "$0" "$1"' "$BASH_BIN" "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
      env-var)
        ( cd "$dir" && ENV="$MATRICE_BASH_ENV_AWK" "$BASH_BIN" "$RECALC" >"$WORK/matrice-$label-$combo-out.txt" 2>"$WORK/matrice-$label-$combo-err.txt" ) ;;
    esac
    rc=$?
    if [ "$rc" -eq "$code_attendu" ]; then
      ok "R-MATRICE-ENV [$label/$combo] code de sortie $code_attendu"
    else
      ko "R-MATRICE-ENV [$label/$combo] code" "$code_attendu" "$rc" "$(cat "$WORK/matrice-$label-$combo-out.txt" 2>/dev/null)"
    fi
    if [ "$rc" -eq 0 ]; then
      # STATE.md, pas INDEX.md : INDEX.md embarque « dernier signe de vie » (horodatage courant de
      # cloture.log), qui diverge légitimement d'un passage à l'autre — STATE.md, lui, ne porte
      # aucune horloge (cycle_courant/phase_courante/etat seuls), donc un comparateur STABLE du
      # contenu dérivé du disque, indépendant de l'instant d'exécution.
      if [ -z "$ref_index" ]; then
        ref_index="$WORK/matrice-$label-ref-state.txt"
        cp "$dir/.planning/STATE.md" "$ref_index" 2>/dev/null
      elif cmp -s "$ref_index" "$dir/.planning/STATE.md" 2>/dev/null; then
        ok "R-MATRICE-ENV [$label/$combo] STATE.md identique à la colonne de référence"
      else
        ko "R-MATRICE-ENV [$label/$combo] STATE.md" "identique à la référence" "diverge" "-"
      fi
    fi
  done
}
matrice_env terrain-libre setup_terrain_libre 0
matrice_env marqueur-racine setup_marqueur_racine 3
matrice_env marqueur-compartiment setup_marqueur_compartiment 3
matrice_env partition-compartiment setup_partition_compartiment 3
matrice_env socle-signal setup_socle_signal 0

# ================================================================================================
# F1/F44-07 (correction de classe, lot 5) — deux mutants qui font régresser exactement le défaut
# mesuré sur 885d9b3 : l'environnement du sous-processus détecteur redevenait dépendant du PATH
# hérité (`dict(os.environ)`) ou de sa résolution `shutil.which` de bash. Chaque mutant est tué par
# le SCÉNARIO qui a servi à établir la trace ROUGE d'origine : un lab GSD réel (marqueur racine) +
# un PATH empoisonné, sur lequel l'original refuse (rc=3, marqueur intact) et le mutant écrit
# (rc=0, marqueur GSD EFFACÉ).
# ================================================================================================

# ---------- MUT-ENV-OS-ENVIRON — retour à dict(os.environ) pour l'environnement du détecteur -----
if make_recalc_mutant ENV-OS-ENVIRON \
  'env_maitrise = {"PATH": PATH_MAITRISE}' \
  'env_maitrise = dict(os.environ)  # MUT-ENV-OS-ENVIRON'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-env-os-environ-cas"
  materialiser traceur "$DIR_CAS"
  setup_marqueur_racine "$DIR_CAS"
  ( cd "$DIR_CAS" && PATH="$MATRICE_FAUX_AWK_DIR:$PATH" GSD_HOME="$FAKE_GSD" "$BASH_BIN" "$MR" >"$WORK/mut-env-os-environ-out.txt" 2>"$WORK/mut-env-os-environ-err.txt" ); RC_M=$?
  if ! _verifier_plantage ENV-OS-ENVIRON "code de sortie sous PATH empoisonné (awk factice) sur un lab GSD réel" "$WORK/mut-env-os-environ-out.txt" "$WORK/mut-env-os-environ-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut ENV-OS-ENVIRON "code de sortie sous PATH empoisonné (awk factice) sur un lab GSD réel · attendu (original) : 3 (refus, marqueur intact) · obtenu (mutant, dict(os.environ)) : $RC_M (écriture, marqueur GSD effacé)"
    else
      komut ENV-OS-ENVIRON "code de sortie sous PATH empoisonné (awk factice) sur un lab GSD réel" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-BASH-VIA-PATH — retour à shutil.which("bash") pour résoudre l'interpréteur -------
MATRICE_FAUX_BASH3_DIR="$(mktemp -d)"
printf '#!/bin/sh\nexit 3\n' > "$MATRICE_FAUX_BASH3_DIR/bash"
chmod +x "$MATRICE_FAUX_BASH3_DIR/bash"
if make_recalc_mutant BASH-VIA-PATH \
  'bash_bin = _resoudre_bash()' \
  'bash_bin = __import__("shutil").which("bash")  # MUT-BASH-VIA-PATH'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-bash-via-path-cas"
  materialiser traceur "$DIR_CAS"
  setup_marqueur_racine "$DIR_CAS"
  # Faux `bash` en tête de PATH qui rend toujours 3 (« terrain libre »), quel que soit le script
  # qu'on lui passe — avec `shutil.which`, c'est LUI qui tranche le verdict, pas le vrai détecteur.
  ( cd "$DIR_CAS" && PATH="$MATRICE_FAUX_BASH3_DIR:$PATH" GSD_HOME="$FAKE_GSD" "$BASH_BIN" "$MR" >"$WORK/mut-bash-via-path-out.txt" 2>"$WORK/mut-bash-via-path-err.txt" ); RC_M=$?
  if ! _verifier_plantage BASH-VIA-PATH "code de sortie sous PATH empoisonné (faux bash qui rend toujours 3) sur un lab GSD réel" "$WORK/mut-bash-via-path-out.txt" "$WORK/mut-bash-via-path-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut BASH-VIA-PATH "code de sortie sous PATH empoisonné (faux bash) sur un lab GSD réel · attendu (original) : 3 (refus, marqueur intact) · obtenu (mutant, shutil.which) : $RC_M (écriture, marqueur GSD effacé)"
    else
      komut BASH-VIA-PATH "code de sortie sous PATH empoisonné (faux bash) sur un lab GSD réel" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ================================================================================================
# R-LABS-ADVERSES (item 2c, lot 4) — les trois divergences mesurées au lot 3 (audit) : un
# `package.json` en lien symbolique, un `*.xcodeproj` en lien symbolique, et un `STATE.md` aux
# octets UTF-8 invalides après le frontmatter — chacun combiné au socle planning-core
# (`planning_version` sans `gsd_state_version`) -> refus (code 3), marqueur STATE.md INTACT
# (cmp octet pour octet). La source unique de vérité (le vrai détecteur bash) ne peut plus
# diverger d'elle-même sur ces trois cas, puisque c'est elle qui les tranche désormais — ce que la
# copie Python du lot 3 avait mesuré divergent (lstat vs `[ -f ]`/`[ -d ]`, qui suivent les liens ;
# décodage UTF-8 strict de tout le fichier vs lecture bornée au frontmatter par awk).
# ================================================================================================
adverse_lab() { # <label> <fn_setup>
  local label="$1" fn_setup="$2"
  local dir="$WORK/adverse-$label"
  materialiser traceur "$dir"
  printf -- '---\nplanning_version: "2.0"\n---\n' > "$dir/.planning/STATE.md"
  "$fn_setup" "$dir"
  cp "$dir/.planning/STATE.md" "$WORK/adverse-$label-state-avant.md"
  ( cd "$dir" && bash "$RECALC" >"$WORK/adverse-$label-out.txt" 2>"$WORK/adverse-$label-err.txt" )
  local rc=$?
  # GATE-14 (45-02, P45-D-02) : le lab traceur adhère ; le détecteur rend 2 (migration) sur ces
  # trois cas — le moteur écrit (0) et régénère STATE.md, qui ne porte plus `planning_version`.
  # Le refus du code 2 sans adhésion est couvert par R-GATE14-A.
  if [ "$rc" -eq 0 ]; then
    ok "R-LABS-ADVERSES [$label] code de sortie 0 (adhésion + migration : écriture levée)"
  else
    ko "R-LABS-ADVERSES [$label] code" "0" "$rc" "$(cat "$WORK/adverse-$label-out.txt")"
  fi
  if ! cmp -s "$WORK/adverse-$label-state-avant.md" "$dir/.planning/STATE.md" \
     && ! grep -q '^planning_version:' "$dir/.planning/STATE.md" 2>/dev/null; then
    ok "R-LABS-ADVERSES [$label] STATE.md régénéré (marqueur planning_version du socle v2 remplacé)"
  else
    ko "R-LABS-ADVERSES [$label] STATE.md" "régénéré, sans planning_version" "inchangé ou marqueur conservé" "$(head -5 "$dir/.planning/STATE.md" 2>/dev/null)"
  fi
}
setup_adverse_package_json() {
  local dir="$1"
  local cible="$WORK/adverse-cible-package.json"
  [ -f "$cible" ] || printf '%s' '{}' > "$cible"
  ln -s "$cible" "$dir/package.json"
}
setup_adverse_xcodeproj() {
  local dir="$1"
  local cible="$WORK/adverse-cible.xcodeproj"
  mkdir -p "$cible"
  ln -s "$cible" "$dir/App.xcodeproj"
}
setup_adverse_state_utf8_invalide() {
  local dir="$1"
  printf -- '---\nplanning_version: "2.0"\n---\n' > "$dir/.planning/STATE.md"
  printf '\xff\xfe corps invalide\n' >> "$dir/.planning/STATE.md"
  printf '%s' '{}' > "$dir/package.json"
}
adverse_lab package-json-lien setup_adverse_package_json
adverse_lab xcodeproj-lien setup_adverse_xcodeproj
adverse_lab state-utf8-invalide setup_adverse_state_utf8_invalide

# ---------- MUT-REPLI-GENERIQUE — repli générique (code hors 0/1/2/3) changé en non-gsd ----------
if make_recalc_mutant REPLI-GENERIQUE 'return "non-concluante"  # motif-repli-generique' 'return "non-gsd"  # MUT-REPLI-GENERIQUE'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-repli-generique-cas"
  SCRIPTS_CAS="$WORK/mut-repli-generique-scripts"
  materialiser traceur "$DIR_CAS"
  mkdir -p "$SCRIPTS_CAS"
  cp "$MR" "$SCRIPTS_CAS/recalc-planning.sh"
  printf '#!/usr/bin/env bash\nexit 64\n' > "$SCRIPTS_CAS/detect-gsd-engine.sh"
  chmod +x "$SCRIPTS_CAS/detect-gsd-engine.sh"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$SCRIPTS_CAS/recalc-planning.sh" >"$WORK/mut-repli-generique-out.txt" 2>"$WORK/mut-repli-generique-err.txt" ); RC_M=$?
  if ! _verifier_plantage REPLI-GENERIQUE "code de sortie (détecteur sort 64, hors contrat 0/1/2/3 — R09 [sort64])" "$WORK/mut-repli-generique-out.txt" "$WORK/mut-repli-generique-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut REPLI-GENERIQUE "code de sortie · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture malgré une détection non concluante)"
    else
      komut REPLI-GENERIQUE "code de sortie" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ================================================================================================
# Lot 2 (décision du head sous délégation technique de Willy, session principale, 2026-09-28) —
# L1 : scindage de motif-code-2-ou-3 en motif-code-3-terrain-libre (write autorisée) et
# motif-code-2-migration (write refusée, régression de l'audit B : le code 2 était traité comme
# le code 3 et laissait écrire sur un socle planning-core signalé « migration à examiner »).
# Phase 45 / 45-02 (GATE-14, P45-D-02) : motif-code-2-migration rend désormais le verdict
# `migration`, écriture admise SOUS ADHÉSION seulement — voir R-GATE14-A à D et MUT-GATE14-* plus bas.
# ================================================================================================

# ================================================================================================
# GATE-14 (Phase 45, plan 45-02 ; P45-D-02, P45-D-02a, P45-D-02b — Willy, AskUserQuestion session
# principale, 2026-09-29) : la levée du refus du code 2 (migration) se prouve BRANCHE PAR BRANCHE,
# chacune avec son jumeau négatif. Remplace R-CODE2-MIGRATION (régression de l'audit B de la 44,
# qui refusait le code 2 sans condition) : le refus subsiste SANS adhésion (A) et sous moteur GSD
# actif (B) ; seule la combinaison adhésion + détecteur 2 écrit (C) ; la garde de lecture précède
# toujours le détecteur (D). detect-gsd-engine.sh et workstream-policy.sh ne sont JAMAIS touchés.
#   A — jumeau SANS adhésion : lab socle v2 (config.json « 2.0 ») + signal de code -> code 2 (le
#       message de la 44, P44-D-02), rien écrit, cache compris.
#   B — jumeau GSD : adhérent + gsd_state_version (détecteur à 0) + signal de code -> code 3.
#   C — levée : adhérent + planning_version du socle v2 + signal de code (détecteur à 2) -> code 0.
#   D — garde de lecture intacte : adhérent + socle v2 + compartiment illisible -> code 3.
# ================================================================================================
gate14_lab_socle_v2() { # <dir> — traceur adhérent (cycles-v1) + STATE.md socle v2 + signal de code
  materialiser traceur "$1"
  printf -- '---\nplanning_version: "2.0"\n---\n' > "$1/.planning/STATE.md"
  printf '%s' '{}' > "$1/package.json"
}
gate14_lab_sans_adhesion() { # <dir> — même lab, mais config.json « 2.0 » (pas de cycles-v1)
  gate14_lab_socle_v2 "$1"
  printf '%s' '{"planning_version": "2.0"}' > "$1/.planning/config.json"
}
gate14_lab_gsd() { # <dir> — adhérent + marqueur GSD racine + signal de code
  materialiser traceur "$1"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$1/.planning/STATE.md"
  printf '%s' '{}' > "$1/package.json"
}

# ---------- R-GATE14-A — jumeau sans adhésion : le refus de la 44 tient (code 2, rien écrit) -----
R_G14A_DIR="$WORK/r-gate14-a"
gate14_lab_sans_adhesion "$R_G14A_DIR"
empreinte "$R_G14A_DIR" > "$WORK/r-gate14-a-avant.txt"
( cd "$R_G14A_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-a-out.txt" 2>"$WORK/r-gate14-a-err.txt" )
R_G14A_RC=$?
empreinte "$R_G14A_DIR" > "$WORK/r-gate14-a-apres.txt"
if [ "$R_G14A_RC" -eq 2 ]; then
  ok "R-GATE14-A code de sortie 2 (sans adhésion, signal de code : refus de la 44 inchangé)"
else
  ko "R-GATE14-A code" "2" "$R_G14A_RC" "$(cat "$WORK/r-gate14-a-out.txt")"
fi
if grep -qF "P44-D-02" "$WORK/r-gate14-a-err.txt" 2>/dev/null; then
  ok "R-GATE14-A message de refus P44-D-02 sur stderr"
else
  ko "R-GATE14-A stderr" "mentionne P44-D-02" "$(cat "$WORK/r-gate14-a-err.txt")" "-"
fi
if cmp -s "$WORK/r-gate14-a-avant.txt" "$WORK/r-gate14-a-apres.txt" \
   && [ ! -e "$R_G14A_DIR/.planning/.recalc-cache.json" ]; then
  ok "R-GATE14-A empreinte de .planning/ identique avant/après, cache compris (.recalc-cache.json absent)"
else
  ko "R-GATE14-A empreinte" "identique, sans .recalc-cache.json" "diverge ou cache écrit" "-"
fi

# ---------- R-GATE14-B — jumeau GSD : adhérent + moteur GSD actif -> code 3, rien écrit -----------
R_G14B_DIR="$WORK/r-gate14-b"
gate14_lab_gsd "$R_G14B_DIR"
empreinte "$R_G14B_DIR" > "$WORK/r-gate14-b-avant.txt"
( cd "$R_G14B_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-b-out.txt" 2>"$WORK/r-gate14-b-err.txt" )
R_G14B_RC=$?
empreinte "$R_G14B_DIR" > "$WORK/r-gate14-b-apres.txt"
if [ "$R_G14B_RC" -eq 3 ]; then
  ok "R-GATE14-B code de sortie 3 (adhésion + moteur GSD actif : refus maintenu)"
else
  ko "R-GATE14-B code" "3" "$R_G14B_RC" "$(cat "$WORK/r-gate14-b-out.txt")"
fi
if grep -qF "P44-D-02a" "$WORK/r-gate14-b-err.txt" 2>/dev/null; then
  ok "R-GATE14-B message de refus P44-D-02a sur stderr"
else
  ko "R-GATE14-B stderr" "mentionne P44-D-02a" "$(cat "$WORK/r-gate14-b-err.txt")" "-"
fi
if cmp -s "$WORK/r-gate14-b-avant.txt" "$WORK/r-gate14-b-apres.txt"; then
  ok "R-GATE14-B empreinte de .planning/ identique avant/après"
else
  ko "R-GATE14-B empreinte" "identique" "diverge" "-"
fi

# ---------- R-GATE14-C — levée : adhésion + détecteur à 2 (migration) -> code 0, INDEX/STATE ------
R_G14C_DIR="$WORK/r-gate14-c"
gate14_lab_socle_v2 "$R_G14C_DIR"
( cd "$R_G14C_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-c-out.txt" 2>"$WORK/r-gate14-c-err.txt" )
R_G14C_RC=$?
if [ "$R_G14C_RC" -eq 0 ]; then
  ok "R-GATE14-C code de sortie 0 (adhésion + migration : écriture levée)"
else
  ko "R-GATE14-C code" "0" "$R_G14C_RC" "$(cat "$WORK/r-gate14-c-err.txt")"
fi
if [ -f "$R_G14C_DIR/.planning/INDEX.md" ] && [ -f "$R_G14C_DIR/.planning/STATE.md" ] \
   && [ -f "$R_G14C_DIR/.planning/cloture.log" ]; then
  ok "R-GATE14-C INDEX.md, STATE.md et cloture.log générés"
else
  ko "R-GATE14-C fichiers générés" "INDEX.md, STATE.md, cloture.log présents" "au moins un absent" "$(ls "$R_G14C_DIR/.planning" 2>/dev/null | tr '\n' ' ')"
fi
if grep -q '^cycle_courant: 01-traceur$' "$R_G14C_DIR/.planning/STATE.md" 2>/dev/null \
   && ! grep -q '^planning_version:' "$R_G14C_DIR/.planning/STATE.md" 2>/dev/null; then
  ok "R-GATE14-C STATE.md généré : porte cycle_courant, ne porte plus planning_version"
else
  ko "R-GATE14-C STATE.md" "cycle_courant: 01-traceur, sans planning_version" "$(cat "$R_G14C_DIR/.planning/STATE.md" 2>/dev/null)" "-"
fi
( cd "$R_G14C_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-c-out2.json" 2>"$WORK/r-gate14-c-err2.txt" )
R_G14C_RC2=$?
R_G14C_ECRITS2="$("$PYBIN" -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["ecrits"]))' "$WORK/r-gate14-c-out2.json" 2>/dev/null || echo "?")"
if [ "$R_G14C_RC2" -eq 0 ] && [ "$R_G14C_ECRITS2" = "0" ]; then
  ok "R-GATE14-C second passage : code 0, rapport ecrits vide (idempotent)"
else
  ko "R-GATE14-C second passage" "code 0, ecrits=[]" "code=$R_G14C_RC2, len(ecrits)=$R_G14C_ECRITS2" "$(cat "$WORK/r-gate14-c-err2.txt")"
fi

# ---------- R-GATE14-D — la garde de lecture précède le détecteur : compartiment illisible -------
if [ "$(id -u)" -eq 0 ]; then
  echo "  ⊘ R-GATE14-D SKIP (UID 0 — les permissions dégradées ne s'appliquent pas à root)"
else
  R_G14D_DIR="$WORK/r-gate14-d"
  gate14_lab_socle_v2 "$R_G14D_DIR"
  mkdir -p "$R_G14D_DIR/.planning/workstreams/gouvernance-banc"
  empreinte "$R_G14D_DIR" > "$WORK/r-gate14-d-avant.txt"
  chmod 000 "$R_G14D_DIR/.planning/workstreams/gouvernance-banc"
  ( cd "$R_G14D_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-d-out.txt" 2>"$WORK/r-gate14-d-err.txt" )
  R_G14D_RC=$?
  chmod 755 "$R_G14D_DIR/.planning/workstreams/gouvernance-banc"
  empreinte "$R_G14D_DIR" > "$WORK/r-gate14-d-apres.txt"
  if [ "$R_G14D_RC" -eq 3 ]; then
    ok "R-GATE14-D code de sortie 3 (adhésion + socle v2 + compartiment illisible : la migration n'ouvre pas la garde de lecture)"
  else
    ko "R-GATE14-D code" "3" "$R_G14D_RC" "$(cat "$WORK/r-gate14-d-out.txt")"
  fi
  if grep -qF "garde de lecture du détecteur, lot 7" "$WORK/r-gate14-d-err.txt" 2>/dev/null; then
    ok "R-GATE14-D stderr cite la garde de lecture (lot 7)"
  else
    ko "R-GATE14-D stderr" "cite « garde de lecture du détecteur, lot 7 »" "$(cat "$WORK/r-gate14-d-err.txt")" "-"
  fi
  if cmp -s "$WORK/r-gate14-d-avant.txt" "$WORK/r-gate14-d-apres.txt"; then
    ok "R-GATE14-D empreinte de .planning/ identique avant/après (aucune écriture)"
  else
    ko "R-GATE14-D empreinte" "identique" "diverge" "-"
  fi
fi

# ---------- MUT-CODE3-TERRAIN-LIBRE — code 3 (terrain libre) changé en refus ----------------------
if make_recalc_mutant CODE3-TERRAIN-LIBRE 'return "non-gsd"  # motif-code-3-terrain-libre' 'return "non-concluante"  # MUT-CODE3-TERRAIN-LIBRE'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-code3-terrain-libre-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-code3-terrain-libre-out.txt" 2>"$WORK/mut-code3-terrain-libre-err.txt" ); RC_M=$?
  if ! _verifier_plantage CODE3-TERRAIN-LIBRE "code de sortie (lab vierge, détecteur rend 3 légitimement — R02)" "$WORK/mut-code3-terrain-libre-out.txt" "$WORK/mut-code3-terrain-libre-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 0 ]; then
      okmut CODE3-TERRAIN-LIBRE "code de sortie · attendu (original) : 0 · obtenu (mutant) : $RC_M (refus alors qu'aucun moteur de planning n'est en place)"
    else
      komut CODE3-TERRAIN-LIBRE "code de sortie" "0" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ================================================================================================
# F10 (P45-D-02, option f10-archive — Willy, AskUserQuestion session principale, 2026-09-30) : à la
# PREMIÈRE écriture sous migration, le STATE.md et l'INDEX.md du socle v2 (rédigés à la main) sont
# archivés octet pour octet sous .planning/_archive/socle-v2/ ; une archive existante n'est jamais
# réécrite ; `_archive` inutilisable (lien symbolique) -> code 1, rien écrit.
# F7a (option f7a-racine, même arbitrage) : `derogations-gates.log` est un emplacement du modèle.
# ================================================================================================
gate14_lab_socle_v2_riche() { # <dir> — socle v2 avec STATE.md et INDEX.md « rédigés à la main »
  gate14_lab_socle_v2 "$1"
  printf '\n# STATE du socle v2 rédigé à la main\n\nNe pas perdre ce contenu.\n' >> "$1/.planning/STATE.md"
  printf '# INDEX du socle v2 rédigé à la main\n\nTable historique.\n' > "$1/.planning/INDEX.md"
}

# ---------- R-GATE14-ARCHIVE — archive octet pour octet, jamais réécrite, jamais « Hors modèle » --
R_G14R_DIR="$WORK/r-gate14-archive"
gate14_lab_socle_v2_riche "$R_G14R_DIR"
cp "$R_G14R_DIR/.planning/STATE.md" "$WORK/r-gate14-archive-state-v2.md"
cp "$R_G14R_DIR/.planning/INDEX.md" "$WORK/r-gate14-archive-index-v2.md"
( cd "$R_G14R_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-archive-out.txt" 2>"$WORK/r-gate14-archive-err.txt" )
R_G14R_RC=$?
if [ "$R_G14R_RC" -eq 0 ]; then
  ok "R-GATE14-ARCHIVE code de sortie 0 (migration sous adhésion)"
else
  ko "R-GATE14-ARCHIVE code" "0" "$R_G14R_RC" "$(cat "$WORK/r-gate14-archive-err.txt")"
fi
if cmp -s "$WORK/r-gate14-archive-state-v2.md" "$R_G14R_DIR/.planning/_archive/socle-v2/STATE.md" 2>/dev/null \
   && cmp -s "$WORK/r-gate14-archive-index-v2.md" "$R_G14R_DIR/.planning/_archive/socle-v2/INDEX.md" 2>/dev/null; then
  ok "R-GATE14-ARCHIVE STATE.md et INDEX.md du socle v2 archivés octet pour octet (cmp)"
else
  ko "R-GATE14-ARCHIVE archive" "STATE.md et INDEX.md identiques (cmp) sous _archive/socle-v2/" "absents ou différents" "$(ls -R "$R_G14R_DIR/.planning/_archive" 2>&1 | tr '\n' ' ')"
fi
if ! cmp -s "$WORK/r-gate14-archive-state-v2.md" "$R_G14R_DIR/.planning/STATE.md" 2>/dev/null; then
  ok "R-GATE14-ARCHIVE STATE.md racine remplacé par le STATE.md généré (l'archive garde l'original)"
else
  ko "R-GATE14-ARCHIVE STATE.md racine" "remplacé" "inchangé" "-"
fi
if ! grep -qF '_archive' "$R_G14R_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R-GATE14-ARCHIVE INDEX.md généré ne liste pas _archive en « Hors modèle » (emplacement annexe de la 44)"
else
  ko "R-GATE14-ARCHIVE hors modèle" "_archive absent de INDEX.md" "présent" "$(grep -F '_archive' "$R_G14R_DIR/.planning/INDEX.md")"
fi
# Second passage sous migration (le STATE.md v2 est recréé à la main, contenu DIFFÉRENT) : l'archive du premier passage n'est
# jamais réécrite ET le nouveau contenu manuscrit est archivé sous `socle-v2.2` (quick 45-B, M3, décisions du manager
# vf-dev-manager, 2026-10-01 : l'attendu précédent — `_archive` strictement identique — documentait la perte du contenu recréé).
printf -- '---\nplanning_version: "2.0"\n---\n\n# STATE v2 recréé, contenu différent\n' > "$R_G14R_DIR/.planning/STATE.md"
cp "$R_G14R_DIR/.planning/STATE.md" "$WORK/r-gate14-archive-state-recree.md"
( cd "$R_G14R_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-archive-out2.txt" 2>"$WORK/r-gate14-archive-err2.txt" )
R_G14R_RC2=$?
if [ "$R_G14R_RC2" -eq 0 ] \
   && cmp -s "$WORK/r-gate14-archive-state-v2.md" "$R_G14R_DIR/.planning/_archive/socle-v2/STATE.md" \
   && cmp -s "$WORK/r-gate14-archive-index-v2.md" "$R_G14R_DIR/.planning/_archive/socle-v2/INDEX.md" \
   && cmp -s "$WORK/r-gate14-archive-state-recree.md" "$R_G14R_DIR/.planning/_archive/socle-v2.2/STATE.md" 2>/dev/null \
   && [ ! -e "$R_G14R_DIR/.planning/_archive/socle-v2.2/INDEX.md" ]; then
  ok "R-GATE14-ARCHIVE second passage sous migration : code 0, archive existante jamais réécrite, le STATE.md manuscrit recréé est archivé sous socle-v2.2 (l'INDEX.md généré ne l'est pas)"
else
  ko "R-GATE14-ARCHIVE second passage" "code 0, socle-v2 intact, socle-v2.2/STATE.md = le contenu recréé" "code=$R_G14R_RC2" "$(cat "$WORK/r-gate14-archive-err2.txt"; ls -R "$R_G14R_DIR/.planning/_archive" 2>&1 | tr '\n' ' ')"
fi
# Troisième passage, plus aucun contenu manuscrit (STATE.md et INDEX.md générés) : rien n'est archivé de plus.
empreinte "$R_G14R_DIR/.planning/_archive" > "$WORK/r-gate14-archive-avant3.txt"
( cd "$R_G14R_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-archive-out3.txt" 2>"$WORK/r-gate14-archive-err3.txt" )
R_G14R_RC3=$?
empreinte "$R_G14R_DIR/.planning/_archive" > "$WORK/r-gate14-archive-apres3.txt"
if [ "$R_G14R_RC3" -eq 0 ] && cmp -s "$WORK/r-gate14-archive-avant3.txt" "$WORK/r-gate14-archive-apres3.txt"; then
  ok "R-GATE14-ARCHIVE troisième passage (fichiers générés seulement) : code 0, aucune archive de plus (un fichier généré se reproduit)"
else
  ko "R-GATE14-ARCHIVE troisième passage" "code 0, _archive identique" "code=$R_G14R_RC3, archive modifiée" "$(cat "$WORK/r-gate14-archive-err3.txt")"
fi

# Archive préexistante de contenu DIFFÉRENT (un fichier et un lien) : jamais écrasée, et le contenu manuscrit est archivé sous
# `socle-v2.2` (quick 45-B, M3, décisions du manager vf-dev-manager, 2026-10-01 : l'attendu précédent — « aucune archive écrite
# en plus » — documentait la perte du STATE.md et de l'INDEX.md manuscrits, remplacés sans copie).
R_G14P_DIR="$WORK/r-gate14-archive-preexistante"
gate14_lab_socle_v2_riche "$R_G14P_DIR"
cp "$R_G14P_DIR/.planning/STATE.md" "$WORK/r-gate14-archive-p-state.md"
cp "$R_G14P_DIR/.planning/INDEX.md" "$WORK/r-gate14-archive-p-index.md"
mkdir -p "$R_G14P_DIR/.planning/_archive/socle-v2" "$WORK/r-gate14-archive-preexistante-dehors"
printf 'SENTINELLE archive préexistante\n' > "$R_G14P_DIR/.planning/_archive/socle-v2/STATE.md"
printf 'SENTINELLE hors archive\n' > "$WORK/r-gate14-archive-preexistante-dehors/cible.md"
ln -s "$WORK/r-gate14-archive-preexistante-dehors/cible.md" "$R_G14P_DIR/.planning/_archive/socle-v2/INDEX.md"
( cd "$R_G14P_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-archive-p-out.txt" 2>"$WORK/r-gate14-archive-p-err.txt" )
R_G14P_RC=$?
if [ "$R_G14P_RC" -eq 0 ] \
   && [ "$(cat "$R_G14P_DIR/.planning/_archive/socle-v2/STATE.md")" = "SENTINELLE archive préexistante" ] \
   && [ -L "$R_G14P_DIR/.planning/_archive/socle-v2/INDEX.md" ] \
   && [ "$(cat "$WORK/r-gate14-archive-preexistante-dehors/cible.md")" = "SENTINELLE hors archive" ] \
   && cmp -s "$WORK/r-gate14-archive-p-state.md" "$R_G14P_DIR/.planning/_archive/socle-v2.2/STATE.md" 2>/dev/null \
   && cmp -s "$WORK/r-gate14-archive-p-index.md" "$R_G14P_DIR/.planning/_archive/socle-v2.2/INDEX.md" 2>/dev/null; then
  ok "R-GATE14-ARCHIVE archive préexistante différente (fichier et lien) : jamais écrasée, rien écrit à travers le lien, STATE.md et INDEX.md manuscrits archivés sous socle-v2.2"
else
  ko "R-GATE14-ARCHIVE archive préexistante" "code 0, socle-v2 intact, socle-v2.2 = les deux manuscrits (cmp)" "code=$R_G14P_RC" "$(cat "$WORK/r-gate14-archive-p-err.txt"; ls -R "$R_G14P_DIR/.planning/_archive" 2>&1 | tr '\n' ' ')"
fi

# Demi-archive (INDEX.md seul, identique au manuscrit) : elle ne fait plus sauter l'archivage du STATE.md courant (M3).
R_G14H_DIR="$WORK/r-gate14-archive-demi"
gate14_lab_socle_v2_riche "$R_G14H_DIR"
cp "$R_G14H_DIR/.planning/STATE.md" "$WORK/r-gate14-archive-h-state.md"
cp "$R_G14H_DIR/.planning/INDEX.md" "$WORK/r-gate14-archive-h-index.md"
mkdir -p "$R_G14H_DIR/.planning/_archive/socle-v2"
cp "$R_G14H_DIR/.planning/INDEX.md" "$R_G14H_DIR/.planning/_archive/socle-v2/INDEX.md"
( cd "$R_G14H_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-archive-h-out.txt" 2>"$WORK/r-gate14-archive-h-err.txt" )
R_G14H_RC=$?
if [ "$R_G14H_RC" -eq 0 ] \
   && [ ! -e "$R_G14H_DIR/.planning/_archive/socle-v2/STATE.md" ] \
   && cmp -s "$WORK/r-gate14-archive-h-index.md" "$R_G14H_DIR/.planning/_archive/socle-v2/INDEX.md" \
   && cmp -s "$WORK/r-gate14-archive-h-state.md" "$R_G14H_DIR/.planning/_archive/socle-v2.2/STATE.md" 2>/dev/null \
   && cmp -s "$WORK/r-gate14-archive-h-index.md" "$R_G14H_DIR/.planning/_archive/socle-v2.2/INDEX.md" 2>/dev/null; then
  ok "R-GATE14-ARCHIVE demi-archive : intacte, et le STATE.md manuscrit est archivé sous socle-v2.2 (avec l'INDEX.md, archive complète)"
else
  ko "R-GATE14-ARCHIVE demi-archive" "code 0, socle-v2 inchangé, socle-v2.2 = STATE.md et INDEX.md manuscrits" "code=$R_G14H_RC" "$(cat "$WORK/r-gate14-archive-h-err.txt"; ls -R "$R_G14H_DIR/.planning/_archive" 2>&1 | tr '\n' ' ')"
fi

# Contenu manuscrit déjà archivé à l'identique : aucune nouvelle archive, aucun résidu provisoire, rien d'autre que socle-v2.
R_G14I_DIR="$WORK/r-gate14-archive-idem"
gate14_lab_socle_v2_riche "$R_G14I_DIR"
cp "$R_G14I_DIR/.planning/STATE.md" "$WORK/r-gate14-archive-i-state.md"
( cd "$R_G14I_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-archive-i-out.txt" 2>"$WORK/r-gate14-archive-i-err.txt" )
R_G14I_RC=$?
cp "$WORK/r-gate14-archive-i-state.md" "$R_G14I_DIR/.planning/STATE.md"
( cd "$R_G14I_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-archive-i-out2.txt" 2>"$WORK/r-gate14-archive-i-err2.txt" )
R_G14I_RC2=$?
if [ "$R_G14I_RC" -eq 0 ] && [ "$R_G14I_RC2" -eq 0 ] && [ "$(ls -A "$R_G14I_DIR/.planning/_archive" | tr '\n' ' ')" = "socle-v2 " ] \
   && ! cmp -s "$WORK/r-gate14-archive-i-state.md" "$R_G14I_DIR/.planning/STATE.md"; then
  ok "R-GATE14-ARCHIVE même contenu manuscrit recréé : déjà archivé, pas de nouvelle archive ni de résidu provisoire, STATE.md remplacé"
else
  ko "R-GATE14-ARCHIVE idempotence" "_archive = {socle-v2} seul, STATE.md remplacé" "rc=$R_G14I_RC/$R_G14I_RC2" "$(ls -A "$R_G14I_DIR/.planning/_archive" | tr '\n' ' ')"
fi

# Refus d'écriture tardif : les gardes précèdent l'archivage, un refus ne laisse ni archive orpheline ni fichier remplacé (M3).
for cas in cloture-lien cache-dossier index-lien; do
  R_G14T_DIR="$WORK/r-gate14-archive-tardif-$cas"
  gate14_lab_socle_v2_riche "$R_G14T_DIR"
  case "$cas" in
    cloture-lien) printf 'x\n' > "$WORK/r-gate14-tardif-cible.log"; ln -s "$WORK/r-gate14-tardif-cible.log" "$R_G14T_DIR/.planning/cloture.log" ;;
    cache-dossier) mkdir "$R_G14T_DIR/.planning/.recalc-cache.json" ;;
    index-lien) rm "$R_G14T_DIR/.planning/INDEX.md"; printf 'cible\n' > "$WORK/r-gate14-tardif-index.md"; ln -s "$WORK/r-gate14-tardif-index.md" "$R_G14T_DIR/.planning/INDEX.md" ;;
  esac
  empreinte "$R_G14T_DIR" > "$WORK/r-gate14-tardif-avant-$cas.txt"
  ( cd "$R_G14T_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-tardif-out-$cas.txt" 2>"$WORK/r-gate14-tardif-err-$cas.txt" )
  R_G14T_RC=$?
  empreinte "$R_G14T_DIR" > "$WORK/r-gate14-tardif-apres-$cas.txt"
  if [ "$R_G14T_RC" -eq 1 ] && cmp -s "$WORK/r-gate14-tardif-avant-$cas.txt" "$WORK/r-gate14-tardif-apres-$cas.txt" && [ ! -e "$R_G14T_DIR/.planning/_archive" ]; then
    ok "R-GATE14-ARCHIVE refus d'écriture ($cas) : code 1, empreinte du lab identique, aucune archive orpheline"
  else
    ko "R-GATE14-ARCHIVE refus d'écriture ($cas)" "code 1, rien écrit, pas de _archive" "code=$R_G14T_RC" "$(cat "$WORK/r-gate14-tardif-err-$cas.txt"; ls -A "$R_G14T_DIR/.planning" | tr '\n' ' ')"
  fi
done

# Archivage impossible (`_archive` en lecture seule) : code 1, le STATE.md et l'INDEX.md manuscrits ne sont PAS remplacés.
if [ "$(id -u)" -eq 0 ]; then
  echo "  ⊘ R-GATE14-ARCHIVE lecture seule SKIP (UID 0 — les permissions ne s'appliquent pas à root)"
else
  R_G14X_DIR="$WORK/r-gate14-archive-lecture-seule"
  gate14_lab_socle_v2_riche "$R_G14X_DIR"
  mkdir "$R_G14X_DIR/.planning/_archive"
  chmod 555 "$R_G14X_DIR/.planning/_archive"
  empreinte "$R_G14X_DIR" > "$WORK/r-gate14-x-avant.txt"
  ( cd "$R_G14X_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-x-out.txt" 2>"$WORK/r-gate14-x-err.txt" )
  R_G14X_RC=$?
  empreinte "$R_G14X_DIR" > "$WORK/r-gate14-x-apres.txt"
  chmod 755 "$R_G14X_DIR/.planning/_archive"
  if [ "$R_G14X_RC" -eq 1 ] && cmp -s "$WORK/r-gate14-x-avant.txt" "$WORK/r-gate14-x-apres.txt"; then
    ok "R-GATE14-ARCHIVE archivage impossible (_archive en lecture seule) : code 1, STATE.md et INDEX.md manuscrits non remplacés, rien d'écrit"
  else
    ko "R-GATE14-ARCHIVE archivage impossible" "code 1, empreinte identique" "code=$R_G14X_RC" "$(cat "$WORK/r-gate14-x-err.txt")"
  fi
fi

# `_archive` en lien symbolique : code 1, rien écrit (ni archive, ni INDEX/STATE générés).
R_G14L_DIR="$WORK/r-gate14-archive-lien"
gate14_lab_socle_v2_riche "$R_G14L_DIR"
mkdir -p "$WORK/r-gate14-archive-lien-dehors"
ln -s "$WORK/r-gate14-archive-lien-dehors" "$R_G14L_DIR/.planning/_archive"
empreinte "$R_G14L_DIR" > "$WORK/r-gate14-archive-lien-avant.txt"
( cd "$R_G14L_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-archive-l-out.txt" 2>"$WORK/r-gate14-archive-l-err.txt" )
R_G14L_RC=$?
empreinte "$R_G14L_DIR" > "$WORK/r-gate14-archive-lien-apres.txt"
if [ "$R_G14L_RC" -eq 1 ] && cmp -s "$WORK/r-gate14-archive-lien-avant.txt" "$WORK/r-gate14-archive-lien-apres.txt" \
   && [ -z "$(ls -A "$WORK/r-gate14-archive-lien-dehors")" ] \
   && grep -qF "P45-D-02" "$WORK/r-gate14-archive-l-err.txt" 2>/dev/null; then
  ok "R-GATE14-ARCHIVE _archive en lien symbolique : code 1, empreinte identique, rien écrit à travers le lien"
else
  ko "R-GATE14-ARCHIVE _archive en lien" "code 1, empreinte identique, cible du lien vide" "code=$R_G14L_RC" "$(cat "$WORK/r-gate14-archive-l-err.txt")"
fi

# ---------- R-GATE14-NOMS — le journal de dérogation est un emplacement du modèle (F7a) -----------
R_G14N_DIR="$WORK/r-gate14-noms"
materialiser traceur "$R_G14N_DIR"
printf '2026-09-30T00:00:00+00:00  G-test  raison\n' > "$R_G14N_DIR/.planning/derogations-gates.log"
printf 'autre\n' > "$R_G14N_DIR/.planning/derogations-gates.log.autre"
( cd "$R_G14N_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-gate14-noms-out.txt" 2>"$WORK/r-gate14-noms-err.txt" )
R_G14N_RC=$?
if [ "$R_G14N_RC" -eq 0 ] \
   && ! grep -qF '`derogations-gates.log`' "$R_G14N_DIR/.planning/INDEX.md" 2>/dev/null \
   && grep -qF '`derogations-gates.log.autre`' "$R_G14N_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R-GATE14-NOMS derogations-gates.log absent de « Hors modèle » ; un nom voisin y figure (jumeau négatif)"
else
  ko "R-GATE14-NOMS" "journal absent de « Hors modèle », nom voisin présent" "code=$R_G14N_RC" "$(grep -F 'derogations' "$R_G14N_DIR/.planning/INDEX.md" 2>/dev/null)"
fi

# ---------- MUT-GATE14-MIGRATION — le verdict « migration » du détecteur 2 rendu non concluant ------
# Le motif unique de la ligne `return "migration"` est celui que porte le commentaire
# `# motif-code-2-migration` ; le mutant rétablit le refus de la 44 : R-GATE14-C rend 3 au lieu de 0.
if make_recalc_mutant GATE14-MIGRATION \
  'return "migration"  # motif-code-2-migration' \
  'return "non-concluante"  # MUT-GATE14-MIGRATION'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-migration-cas"
  gate14_lab_socle_v2 "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-migration-out.txt" 2>"$WORK/mut-gate14-migration-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-MIGRATION "code de sortie de R-GATE14-C (adhésion + migration)" "$WORK/mut-gate14-migration-out.txt" "$WORK/mut-gate14-migration-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 0 ]; then
      okmut GATE14-MIGRATION "code de sortie de R-GATE14-C · attendu (original) : 0 · obtenu (mutant, code 2 non concluant) : $RC_M (refus rétabli)"
    else
      komut GATE14-MIGRATION "code de sortie de R-GATE14-C" "0" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-APPELANT — `migration` retiré de la condition d'admission de main() -------
if make_recalc_mutant GATE14-APPELANT \
  'if verdict_gsd not in ("non-gsd", "migration"):' \
  'if verdict_gsd != "non-gsd":  # MUT-GATE14-APPELANT'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-appelant-cas"
  gate14_lab_socle_v2 "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-appelant-out.txt" 2>"$WORK/mut-gate14-appelant-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-APPELANT "code de sortie de R-GATE14-C (adhésion + migration)" "$WORK/mut-gate14-appelant-out.txt" "$WORK/mut-gate14-appelant-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 0 ]; then
      okmut GATE14-APPELANT "code de sortie de R-GATE14-C · attendu (original) : 0 · obtenu (mutant, main() n'admet que non-gsd) : $RC_M (refus rétabli)"
    else
      komut GATE14-APPELANT "code de sortie de R-GATE14-C" "0" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-GSD — `gsd` ajouté aux verdicts admis : un moteur GSD actif serait écrit ----
if make_recalc_mutant GATE14-GSD \
  'if verdict_gsd not in ("non-gsd", "migration"):' \
  'if verdict_gsd not in ("non-gsd", "migration", "gsd"):  # MUT-GATE14-GSD'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-gsd-cas"
  gate14_lab_gsd "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-gsd-out.txt" 2>"$WORK/mut-gate14-gsd-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-GSD "code de sortie de R-GATE14-B (adhésion + moteur GSD actif)" "$WORK/mut-gate14-gsd-out.txt" "$WORK/mut-gate14-gsd-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut GATE14-GSD "code de sortie de R-GATE14-B · attendu (original) : 3 · obtenu (mutant, gsd admis) : $RC_M (écriture sur un planning tenu par GSD, marqueur effacé)"
    else
      komut GATE14-GSD "code de sortie de R-GATE14-B" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-ADHESION — condition de non-adhésion neutralisée (même motif que MUT-ADHESION)
# Rejoué sur le lab de R-GATE14-A (config « 2.0 » + socle v2 + signal de code) : l'original refuse
# (code 2), le mutant laisse la détection rendre « migration » et ÉCRIT (code 0).
if make_recalc_mutant GATE14-ADHESION \
  'resultat["adherente"] = isinstance(resultat["declaree"], str) and resultat["declaree"] == SCHEMA_ADHESION' \
  'resultat["adherente"] = True  # MUT-GATE14-ADHESION'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-adhesion-cas"
  gate14_lab_sans_adhesion "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-adhesion-out.txt" 2>"$WORK/mut-gate14-adhesion-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-ADHESION "code de sortie de R-GATE14-A (sans adhésion + migration)" "$WORK/mut-gate14-adhesion-out.txt" "$WORK/mut-gate14-adhesion-err.txt" "$RC_M"; then
    if [ "$RC_M" -eq 0 ]; then
      okmut GATE14-ADHESION "code de sortie de R-GATE14-A · attendu (original) : 2 · obtenu (mutant, adhésion neutralisée) : $RC_M (écriture d'un lab non adhérent)"
    else
      komut GATE14-ADHESION "code de sortie de R-GATE14-A" "2" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-ARCHIVE — l'appel à archiver_socle_v2 retiré : le socle v2 n'est plus archivé
if make_recalc_mutant GATE14-ARCHIVE \
  'code_archive = archiver_socle_v2(planning_abs)' \
  'code_archive = 0  # MUT-GATE14-ARCHIVE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-archive-cas"
  gate14_lab_socle_v2_riche "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-archive-out.txt" 2>"$WORK/mut-gate14-archive-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-ARCHIVE "archive du STATE.md du socle v2 (R-GATE14-ARCHIVE)" "$WORK/mut-gate14-archive-out.txt" "$WORK/mut-gate14-archive-err.txt" "$RC_M"; then
    if [ ! -e "$DIR_CAS/.planning/_archive/socle-v2/STATE.md" ]; then
      okmut GATE14-ARCHIVE "archive de R-GATE14-ARCHIVE · attendu (original) : _archive/socle-v2/STATE.md présent · obtenu (mutant, appel retiré) : absent (rc=$RC_M, contenu à la main perdu)"
    else
      komut GATE14-ARCHIVE "archive de R-GATE14-ARCHIVE" "STATE.md archivé (original)" "STATE.md archivé (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-ECRASE — le choix du nom d'archive ignore les archives existantes -----------
# Adapté (quick 45-B, M3, décisions du manager vf-dev-manager, 2026-10-01) : l'ancien motif (contrôle d'existence de la cible,
# aujourd'hui sans objet puisqu'une archive existante n'est plus jamais ciblée) est remplacé par la ligne qui choisit le nom de
# la nouvelle archive ; l'attendu « SENTINELLE intacte » est conservé, et complété : le manuscrit est archivé sous socle-v2.2.
if make_recalc_mutant GATE14-ECRASE \
  'destination = os.path.join(parent, _nom_archive_libre(existants))  # archive-destination' \
  'destination = os.path.join(parent, "socle-v2")  # MUT-GATE14-ECRASE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-ecrase-cas"
  gate14_lab_socle_v2_riche "$DIR_CAS"
  mkdir -p "$DIR_CAS/.planning/_archive/socle-v2"
  printf 'SENTINELLE archive préexistante\n' > "$DIR_CAS/.planning/_archive/socle-v2/STATE.md"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-ecrase-out.txt" 2>"$WORK/mut-gate14-ecrase-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-ECRASE "archive préexistante (cas « archive préexistante différente » de R-GATE14-ARCHIVE)" "$WORK/mut-gate14-ecrase-out.txt" "$WORK/mut-gate14-ecrase-err.txt" "$RC_M"; then
    if [ ! -e "$DIR_CAS/.planning/_archive/socle-v2.2/STATE.md" ]; then
      okmut GATE14-ECRASE "archive préexistante · attendu (original) : SENTINELLE intacte et manuscrit archivé sous socle-v2.2 · obtenu (mutant, nom fixe socle-v2) : pas de socle-v2.2 (rc=$RC_M, contenu à la main perdu ou archive en collision)"
    else
      komut GATE14-ECRASE "archive préexistante" "socle-v2.2/STATE.md absent chez le mutant" "socle-v2.2/STATE.md présent (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-DEJA — toute archive existante vaut « déjà archivé » (comportement d'avant la M3) ------
if make_recalc_mutant GATE14-DEJA \
  'if _archive_contient(os.path.join(parent, nom), sources):  # archive-deja' \
  'if True:  # MUT-GATE14-DEJA'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-deja-cas"
  gate14_lab_socle_v2_riche "$DIR_CAS"
  mkdir -p "$DIR_CAS/.planning/_archive/socle-v2"
  cp "$DIR_CAS/.planning/INDEX.md" "$DIR_CAS/.planning/_archive/socle-v2/INDEX.md"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-deja-out.txt" 2>"$WORK/mut-gate14-deja-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-DEJA "demi-archive de R-GATE14-ARCHIVE" "$WORK/mut-gate14-deja-out.txt" "$WORK/mut-gate14-deja-err.txt" "$RC_M"; then
    if [ ! -e "$DIR_CAS/.planning/_archive/socle-v2.2/STATE.md" ] && [ ! -e "$DIR_CAS/.planning/_archive/socle-v2/STATE.md" ]; then
      okmut GATE14-DEJA "demi-archive · attendu (original) : STATE.md manuscrit archivé sous socle-v2.2 · obtenu (mutant, toute archive vaut « déjà archivé ») : STATE.md archivé nulle part (rc=$RC_M), puis remplacé"
    else
      komut GATE14-DEJA "demi-archive" "STATE.md archivé nulle part chez le mutant" "STATE.md archivé (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-PREALABLES — les gardes d'écriture ne précèdent plus l'archivage -----------
if make_recalc_mutant GATE14-PREALABLES \
  'code_prealable = gardes_ecriture_prealables(planning_abs)  # archive-prealables' \
  'code_prealable = 0  # MUT-GATE14-PREALABLES'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-prealables-cas"
  gate14_lab_socle_v2_riche "$DIR_CAS"
  mkdir "$DIR_CAS/.planning/.recalc-cache.json"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-prealables-out.txt" 2>"$WORK/mut-gate14-prealables-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-PREALABLES "refus d'écriture (cache en dossier) de R-GATE14-ARCHIVE" "$WORK/mut-gate14-prealables-out.txt" "$WORK/mut-gate14-prealables-err.txt" "$RC_M"; then
    if [ -d "$DIR_CAS/.planning/_archive/socle-v2" ]; then
      okmut GATE14-PREALABLES "refus d'écriture · attendu (original) : code 1 sans _archive · obtenu (mutant, gardes après l'archivage) : archive orpheline sous _archive/socle-v2 (rc=$RC_M)"
    else
      komut GATE14-PREALABLES "refus d'écriture" "archive orpheline chez le mutant" "pas d'archive (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-GENERE — un fichier généré est archivé comme du contenu manuscrit ------------
if make_recalc_mutant GATE14-GENERE \
  'if _est_genere(nom, octets_source):  # archive-genere' \
  'if False:  # MUT-GATE14-GENERE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-genere-cas"
  gate14_lab_socle_v2_riche "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
  printf -- '---\nplanning_version: "2.0"\n---\n\n# STATE v2 recréé, contenu différent\n' > "$DIR_CAS/.planning/STATE.md"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-genere-out.txt" 2>"$WORK/mut-gate14-genere-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-GENERE "second passage de R-GATE14-ARCHIVE (STATE.md manuscrit recréé, INDEX.md généré)" "$WORK/mut-gate14-genere-out.txt" "$WORK/mut-gate14-genere-err.txt" "$RC_M"; then
    if [ -e "$DIR_CAS/.planning/_archive/socle-v2.2/INDEX.md" ]; then
      okmut GATE14-GENERE "INDEX.md généré · attendu (original) : absent de socle-v2.2 (seul le STATE.md manuscrit est archivé) · obtenu (mutant, génération non reconnue) : un instantané de l'INDEX.md généré est archivé"
    else
      komut GATE14-GENERE "INDEX.md généré" "socle-v2.2/INDEX.md présent chez le mutant" "socle-v2.2/INDEX.md absent (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-GATE14-RENAME — le dossier provisoire n'est jamais publié (tout ou rien) ---------------
if make_recalc_mutant GATE14-RENAME \
  'os.rename(provisoire, destination)  # archive-rename' \
  'pass  # MUT-GATE14-RENAME'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-gate14-rename-cas"
  gate14_lab_socle_v2_riche "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-gate14-rename-out.txt" 2>"$WORK/mut-gate14-rename-err.txt" ); RC_M=$?
  if ! _verifier_plantage GATE14-RENAME "archive de R-GATE14-ARCHIVE publiée par renommage" "$WORK/mut-gate14-rename-out.txt" "$WORK/mut-gate14-rename-err.txt" "$RC_M"; then
    if [ ! -e "$DIR_CAS/.planning/_archive/socle-v2/STATE.md" ]; then
      okmut GATE14-RENAME "archive publiée par renommage · attendu (original) : _archive/socle-v2/STATE.md présent · obtenu (mutant, renommage retiré) : absent (rc=$RC_M)"
    else
      komut GATE14-RENAME "archive publiée par renommage" "STATE.md absent chez le mutant" "STATE.md présent (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-NOMS-JOURNAL — le nom du journal retiré de la liste des fichiers du modèle --------
if make_recalc_mutant NOMS-JOURNAL \
  '"derogations-gates.log",' \
  '"nom-journal-retire-par-le-mutant",'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-noms-journal-cas"
  materialiser traceur "$DIR_CAS"
  printf '2026-09-30T00:00:00+00:00  G-test  raison\n' > "$DIR_CAS/.planning/derogations-gates.log"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-noms-journal-out.txt" 2>"$WORK/mut-noms-journal-err.txt" ); RC_M=$?
  if ! _verifier_plantage NOMS-JOURNAL "INDEX.md sans « Hors modèle » pour le journal (R-GATE14-NOMS)" "$WORK/mut-noms-journal-out.txt" "$WORK/mut-noms-journal-err.txt" "$RC_M"; then
    if grep -qF '`derogations-gates.log`' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null; then
      okmut NOMS-JOURNAL "INDEX.md de R-GATE14-NOMS · attendu (original) : journal absent de « Hors modèle » · obtenu (mutant, nom retiré) : journal listé en « Hors modèle »"
    else
      komut NOMS-JOURNAL "INDEX.md de R-GATE14-NOMS" "journal absent de « Hors modèle » (original)" "journal absent (mutant non opposable)"
    fi
  fi
fi

# ================================================================================================
# Lot 6 (correction ciblée, audit du 2026-09-28) — garde de fidélité d'énumération, AVANT tout
# appel au détecteur : un compartiment RÉEL de `workstreams/` que l'énumération ligne-par-ligne de
# `vf_ws_enumerate` ne restituerait pas fidèlement rend tout verdict du détecteur non vérifiable.
# Preuve différentielle : les cas R-ENUM-FIDELE-* rejouent, sur le code ORIGINAL non corrigé
# (git show 0be13a9), un exit=0 avec écriture silencieuse (rouge, tracé dans le rapport de
# mission) ; sur le code corrigé ci-dessous, exit=3 et aucune écriture (vert). P44-D-01b :
# `detect-gsd-engine.sh` et `workstream-policy.sh` ne sont JAMAIS mutés ni réimplémentés ici.
# ================================================================================================

# ---------- R-ENUM-FIDELE-LF — nom de compartiment à saut de ligne, marqueur GSD à l'intérieur --
R_EFLF_DIR="$WORK/r-enum-fidele-lf"
materialiser traceur "$R_EFLF_DIR"
R_EFLF_NOM=$'compartiment-un\nmarqueur-cache'
mkdir -p "$R_EFLF_DIR/.planning/workstreams/$R_EFLF_NOM"
printf -- '---\ngsd_state_version: 1.0\n---\n' > "$R_EFLF_DIR/.planning/workstreams/$R_EFLF_NOM/STATE.md"
empreinte "$R_EFLF_DIR" > "$WORK/r-enum-fidele-lf-avant.txt"
( cd "$R_EFLF_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-enum-fidele-lf-out.txt" 2>"$WORK/r-enum-fidele-lf-err.txt" )
R_EFLF_RC=$?
empreinte "$R_EFLF_DIR" > "$WORK/r-enum-fidele-lf-apres.txt"
if [ "$R_EFLF_RC" -eq 3 ]; then
  ok "R-ENUM-FIDELE-LF code de sortie 3 (compartiment à saut de ligne masqué à l'énumération — refus, jamais un terrain libre de complaisance)"
else
  ko "R-ENUM-FIDELE-LF code" "3" "$R_EFLF_RC" "$(cat "$WORK/r-enum-fidele-lf-out.txt")"
fi
if grep -qF "nom-compartiment-saut-de-ligne" "$WORK/r-enum-fidele-lf-err.txt" 2>/dev/null; then
  ok "R-ENUM-FIDELE-LF stderr nomme la classe masquante (nom-compartiment-saut-de-ligne)"
else
  ko "R-ENUM-FIDELE-LF stderr" "cite nom-compartiment-saut-de-ligne" "$(cat "$WORK/r-enum-fidele-lf-err.txt")" "-"
fi
if cmp -s "$WORK/r-enum-fidele-lf-avant.txt" "$WORK/r-enum-fidele-lf-apres.txt"; then
  ok "R-ENUM-FIDELE-LF empreinte de .planning/ identique avant/après (aucune écriture)"
else
  ko "R-ENUM-FIDELE-LF empreinte" "identique" "diverge" "-"
fi

# ---------- R-ENUM-FIDELE-CACHE — nom de compartiment caché (point), marqueur GSD à l'intérieur --
R_EFC_DIR="$WORK/r-enum-fidele-cache"
materialiser traceur "$R_EFC_DIR"
mkdir -p "$R_EFC_DIR/.planning/workstreams/.hidden-compartment"
printf -- '---\ngsd_state_version: 1.0\n---\n' > "$R_EFC_DIR/.planning/workstreams/.hidden-compartment/STATE.md"
empreinte "$R_EFC_DIR" > "$WORK/r-enum-fidele-cache-avant.txt"
( cd "$R_EFC_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-enum-fidele-cache-out.txt" 2>"$WORK/r-enum-fidele-cache-err.txt" )
R_EFC_RC=$?
empreinte "$R_EFC_DIR" > "$WORK/r-enum-fidele-cache-apres.txt"
if [ "$R_EFC_RC" -eq 3 ]; then
  ok "R-ENUM-FIDELE-CACHE code de sortie 3 (compartiment caché invisible au glob — refus)"
else
  ko "R-ENUM-FIDELE-CACHE code" "3" "$R_EFC_RC" "$(cat "$WORK/r-enum-fidele-cache-out.txt")"
fi
if grep -qF "nom-compartiment-cache:.hidden-compartment" "$WORK/r-enum-fidele-cache-err.txt" 2>/dev/null; then
  ok "R-ENUM-FIDELE-CACHE stderr nomme la classe masquante (nom-compartiment-cache)"
else
  ko "R-ENUM-FIDELE-CACHE stderr" "cite nom-compartiment-cache:.hidden-compartment" "$(cat "$WORK/r-enum-fidele-cache-err.txt")" "-"
fi
if cmp -s "$WORK/r-enum-fidele-cache-avant.txt" "$WORK/r-enum-fidele-cache-apres.txt"; then
  ok "R-ENUM-FIDELE-CACHE empreinte de .planning/ identique avant/après (aucune écriture)"
else
  ko "R-ENUM-FIDELE-CACHE empreinte" "identique" "diverge" "-"
fi

# ---------- R-ENUM-FIDELE-CHEMIN — chemin du dossier de planning lui-même à saut de ligne ---------
R_EFCH_ROOT="$WORK/r-enum-fidele-chemin"$'\n'"racine"
mkdir -p "$R_EFCH_ROOT"
materialiser traceur "$R_EFCH_ROOT"
mkdir -p "$R_EFCH_ROOT/.planning/workstreams/compartiment-normal"
printf -- '---\ngsd_state_version: 1.0\n---\n' > "$R_EFCH_ROOT/.planning/workstreams/compartiment-normal/STATE.md"
empreinte "$R_EFCH_ROOT" > "$WORK/r-enum-fidele-chemin-avant.txt"
( cd "$R_EFCH_ROOT" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-enum-fidele-chemin-out.txt" 2>"$WORK/r-enum-fidele-chemin-err.txt" )
R_EFCH_RC=$?
empreinte "$R_EFCH_ROOT" > "$WORK/r-enum-fidele-chemin-apres.txt"
if [ "$R_EFCH_RC" -eq 3 ]; then
  ok "R-ENUM-FIDELE-CHEMIN code de sortie 3 (chemin du planning à saut de ligne — TOUTE l'énumération casse, refus)"
else
  ko "R-ENUM-FIDELE-CHEMIN code" "3" "$R_EFCH_RC" "$(cat "$WORK/r-enum-fidele-chemin-out.txt")"
fi
if grep -qF "chemin-planning-saut-de-ligne" "$WORK/r-enum-fidele-chemin-err.txt" 2>/dev/null; then
  ok "R-ENUM-FIDELE-CHEMIN stderr nomme la classe masquante (chemin-planning-saut-de-ligne)"
else
  ko "R-ENUM-FIDELE-CHEMIN stderr" "cite chemin-planning-saut-de-ligne" "$(cat "$WORK/r-enum-fidele-chemin-err.txt")" "-"
fi
if cmp -s "$WORK/r-enum-fidele-chemin-avant.txt" "$WORK/r-enum-fidele-chemin-apres.txt"; then
  ok "R-ENUM-FIDELE-CHEMIN empreinte de .planning/ identique avant/après (aucune écriture)"
else
  ko "R-ENUM-FIDELE-CHEMIN empreinte" "identique" "diverge" "-"
fi

# ---------- R-ENUM-FIDELE-SYMLINK — entrée en lien symbolique : EXCLUSION DÉCLARÉE du détecteur,
# PAS une classe masquante de cette garde (F1 : ne pas sur-refuser un cas déjà connu et accepté) --
R_EFS_DIR="$WORK/r-enum-fidele-symlink"
materialiser traceur "$R_EFS_DIR"
mkdir -p "$R_EFS_DIR/.planning/workstreams" "$WORK/r-enum-fidele-symlink-cible"
printf -- '---\ngsd_state_version: 1.0\n---\n' > "$WORK/r-enum-fidele-symlink-cible/STATE.md"
ln -s "$WORK/r-enum-fidele-symlink-cible" "$R_EFS_DIR/.planning/workstreams/lien-compartiment"
( cd "$R_EFS_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-enum-fidele-symlink-out.txt" 2>"$WORK/r-enum-fidele-symlink-err.txt" )
R_EFS_RC=$?
if grep -qF "nom-compartiment" "$WORK/r-enum-fidele-symlink-err.txt" 2>/dev/null; then
  ko "R-ENUM-FIDELE-SYMLINK" "lien symbolique NON classé masquant par cette garde" "classé masquant à tort" "$(cat "$WORK/r-enum-fidele-symlink-err.txt")"
else
  ok "R-ENUM-FIDELE-SYMLINK lien symbolique jamais classé masquant par cette garde (exclusion déjà déclarée ailleurs, rc=$R_EFS_RC)"
fi

# ---------- R-ENUM-FIDELE-NOMINAL — compartiments réels aux noms sans piège, aucun marqueur GSD :
# écriture INCHANGÉE (non-régression, la garde ne doit jamais sur-refuser un cas nominal) --------
R_EFN_DIR="$WORK/r-enum-fidele-nominal"
materialiser traceur "$R_EFN_DIR"
mkdir -p "$R_EFN_DIR/.planning/workstreams/compartiment-normal"
printf -- '---\nworkstream: compartiment-normal\ncreated: 2026-09-28\n---\n' > "$R_EFN_DIR/.planning/workstreams/compartiment-normal/notes.md"
( cd "$R_EFN_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-enum-fidele-nominal-out.txt" 2>"$WORK/r-enum-fidele-nominal-err.txt" )
R_EFN_RC=$?
if [ "$R_EFN_RC" -eq 0 ]; then
  ok "R-ENUM-FIDELE-NOMINAL code de sortie 0 (compartiments nominaux, aucun marqueur — écriture inchangée)"
else
  ko "R-ENUM-FIDELE-NOMINAL code" "0" "$R_EFN_RC" "$(cat "$WORK/r-enum-fidele-nominal-err.txt")"
fi
for f in INDEX.md STATE.md .recalc-cache.json; do
  if [ -f "$R_EFN_DIR/.planning/$f" ]; then
    ok "R-ENUM-FIDELE-NOMINAL $f créé"
  else
    ko "R-ENUM-FIDELE-NOMINAL $f créé" "présent" "absent" "-"
  fi
done

# ---------- MUT-ENUM-FIDELE — la garde de fidélité d'énumération neutralisée (if False:) ---------
if make_recalc_mutant ENUM-FIDELE 'if not fidele:' 'if False:  # MUT-ENUM-FIDELE (garde neutralisée)'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-enum-fidele-cas"
  materialiser traceur "$DIR_CAS"
  MUT_NOM=$'compartiment-un\nmarqueur-cache'
  mkdir -p "$DIR_CAS/.planning/workstreams/$MUT_NOM"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$DIR_CAS/.planning/workstreams/$MUT_NOM/STATE.md"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-enum-fidele-out.txt" 2>"$WORK/mut-enum-fidele-err.txt" ); RC_M=$?
  if ! _verifier_plantage ENUM-FIDELE "code de sortie (compartiment à saut de ligne masqué, marqueur GSD à l'intérieur — R-ENUM-FIDELE-LF)" "$WORK/mut-enum-fidele-out.txt" "$WORK/mut-enum-fidele-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut ENUM-FIDELE "code de sortie · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture silencieuse sur un compartiment réellement tenu par GSD — régression exacte de l'audit du 2026-09-28)"
    else
      komut ENUM-FIDELE "code de sortie" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ================================================================================================
# Lot 7 (correction de CLASSE, audit du 2026-09-28) — garde de LECTURE du détecteur : le moteur
# n'écrit que s'il a pu LIRE, pour de vrai, tout ce que le détecteur devait lire. Boucle GÉNÉRIQUE
# sur chaque élément mesuré (workstreams/, un compartiment, le STATE.md d'un compartiment, le
# STATE.md racine) × permissions dégradées (000/600/400) : masquant -> refus (rc=3, cite la garde
# lot 7, empreinte inchangée) ; non masquant (fichier encore lisible par le propriétaire sous 600
# ou 400) -> verdict INCHANGÉ, jamais la garde lot 7 qui déclenche (contrôle anti-sur-refus).
# ROUGE sur HEAD 32b5d59 (avant ce lot) pour les quatre cas masquants ci-dessous : `écrit=oui`
# mesuré par exécution directe (rapport de mission), le moteur écrivait silencieusement — pour le
# cas `root-state`, il allait jusqu'à ÉCRASER le `STATE.md` racine et effacer son marqueur.
# ================================================================================================
_lot7_root_actif() { [ "$(id -u)" -eq 0 ]; }

_lot7_build_lab_root() { # <dir> — SEUL le STATE.md racine porte le marqueur GSD
  rm -rf "$1"
  mkdir -p "$1/.planning"
  printf '{"planning_version": "cycles-v1"}\n' > "$1/.planning/config.json"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$1/.planning/STATE.md"
}
_lot7_build_lab_partition() { # <dir> — SEUL le STATE.md du compartiment porte le marqueur GSD
  rm -rf "$1"
  mkdir -p "$1/.planning/workstreams/gouvernance"
  printf '{"planning_version": "cycles-v1"}\n' > "$1/.planning/config.json"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$1/.planning/workstreams/gouvernance/STATE.md"
}
_lot7_restore_mode() { # <chemin> <type: dir|file>
  if [ "$2" = "dir" ]; then chmod 755 "$1" 2>/dev/null; else chmod 644 "$1" 2>/dev/null; fi
}

if _lot7_root_actif; then
  echo "  ⊘ R-LECTURE-FIDELE SKIP (UID 0 — les permissions dégradées ne s'appliquent pas à root, aucun cas ci-dessous vérifiable)"
else
  # <nom>|<labtype root|partition>|<chemin relatif dégradé>|<type dir|file>|<modes masquants>|<modes témoins non masquants>
  LOT7_ENTREES=(
    "root-state|root|.planning/STATE.md|file|000|600 400"
    "workstreams-dir|partition|.planning/workstreams|dir|000 600 400|"
    "compartiment-dir|partition|.planning/workstreams/gouvernance|dir|000 600 400|"
    "compartiment-state|partition|.planning/workstreams/gouvernance/STATE.md|file|000|600 400"
  )
  for LOT7_ENTREE in "${LOT7_ENTREES[@]}"; do
    IFS='|' read -r L7_NOM L7_LABTYPE L7_RELPATH L7_TYPE L7_MODES_MASQUANTS L7_MODES_TEMOINS <<< "$LOT7_ENTREE"
    for L7_MODE in $L7_MODES_MASQUANTS; do
      L7_DIR="$WORK/lot7-$L7_NOM-$L7_MODE"
      if [ "$L7_LABTYPE" = "root" ]; then _lot7_build_lab_root "$L7_DIR"; else _lot7_build_lab_partition "$L7_DIR"; fi
      L7_CIBLE="$L7_DIR/$L7_RELPATH"
      empreinte "$L7_DIR" > "$L7_DIR.avant.txt"
      chmod "$L7_MODE" "$L7_CIBLE"
      ( cd "$L7_DIR" && bash "$RECALC" "--planning=.planning" >"$L7_DIR.out.txt" 2>"$L7_DIR.err.txt" )
      L7_RC=$?
      _lot7_restore_mode "$L7_CIBLE" "$L7_TYPE"
      empreinte "$L7_DIR" > "$L7_DIR.apres.txt"
      if [ "$L7_RC" -eq 3 ] && grep -qF "garde de lecture du détecteur, lot 7" "$L7_DIR.err.txt" \
        && cmp -s "$L7_DIR.avant.txt" "$L7_DIR.apres.txt"; then
        ok "R-LECTURE-FIDELE [$L7_NOM mode=$L7_MODE] masquant : refus via la garde lot 7, empreinte inchangée (aucune écriture)"
      else
        ko "R-LECTURE-FIDELE [$L7_NOM mode=$L7_MODE]" "rc=3, stderr cite « garde de lecture du détecteur, lot 7 », empreinte inchangée" "rc=3 attendu" "rc=$L7_RC · stderr=$(cat "$L7_DIR.err.txt" | tr '\n' '|')"
      fi
    done
    for L7_MODE in $L7_MODES_TEMOINS; do
      L7_DIR="$WORK/lot7-$L7_NOM-ctrl-$L7_MODE"
      if [ "$L7_LABTYPE" = "root" ]; then _lot7_build_lab_root "$L7_DIR"; else _lot7_build_lab_partition "$L7_DIR"; fi
      L7_CIBLE="$L7_DIR/$L7_RELPATH"
      empreinte "$L7_DIR" > "$L7_DIR.avant.txt"
      chmod "$L7_MODE" "$L7_CIBLE"
      ( cd "$L7_DIR" && bash "$RECALC" "--planning=.planning" >"$L7_DIR.out.txt" 2>"$L7_DIR.err.txt" )
      L7_RC=$?
      _lot7_restore_mode "$L7_CIBLE" "$L7_TYPE"
      empreinte "$L7_DIR" > "$L7_DIR.apres.txt"
      if [ "$L7_RC" -eq 3 ] && ! grep -qF "garde de lecture du détecteur, lot 7" "$L7_DIR.err.txt" \
        && cmp -s "$L7_DIR.avant.txt" "$L7_DIR.apres.txt"; then
        ok "R-LECTURE-FIDELE [$L7_NOM mode=$L7_MODE] TÉMOIN non masquant : verdict inchangé (marqueur toujours lu), jamais la garde lot 7"
      else
        ko "R-LECTURE-FIDELE [$L7_NOM mode=$L7_MODE ctrl]" "rc=3, jamais « garde de lecture du détecteur, lot 7 », empreinte inchangée" "rc=3 attendu" "rc=$L7_RC · stderr=$(cat "$L7_DIR.err.txt" | tr '\n' '|')"
      fi
    done
  done

  # ---------- R-LECTURE-FIDELE-MULTI-NOMINAL — plusieurs compartiments réels, AUCUN marqueur GSD :
  # le lab nominal partitionné est TOUJOURS écrit (non-régression, jamais un sur-refus) -----------
  L7_MULTI_DIR="$WORK/lot7-multi-nominal"
  rm -rf "$L7_MULTI_DIR"
  mkdir -p "$L7_MULTI_DIR/.planning/workstreams/alpha" "$L7_MULTI_DIR/.planning/workstreams/beta" "$L7_MULTI_DIR/.planning/workstreams/gamma"
  printf '{"planning_version": "cycles-v1"}\n' > "$L7_MULTI_DIR/.planning/config.json"
  printf -- '---\nworkstream: alpha\ncreated: 2026-09-28\n---\n' > "$L7_MULTI_DIR/.planning/workstreams/alpha/notes.md"
  printf -- '---\nworkstream: beta\ncreated: 2026-09-28\n---\n' > "$L7_MULTI_DIR/.planning/workstreams/beta/notes.md"
  printf -- '---\nworkstream: gamma\ncreated: 2026-09-28\n---\n' > "$L7_MULTI_DIR/.planning/workstreams/gamma/notes.md"
  ( cd "$L7_MULTI_DIR" && bash "$RECALC" "--planning=.planning" >"$L7_MULTI_DIR.out.txt" 2>"$L7_MULTI_DIR.err.txt" )
  L7_MULTI_RC=$?
  if [ "$L7_MULTI_RC" -eq 0 ]; then
    ok "R-LECTURE-FIDELE-MULTI-NOMINAL code de sortie 0 (trois compartiments réels, aucun marqueur — écriture inchangée)"
  else
    ko "R-LECTURE-FIDELE-MULTI-NOMINAL code" "0" "$L7_MULTI_RC" "$(cat "$L7_MULTI_DIR.err.txt")"
  fi
  if [ -f "$L7_MULTI_DIR/.planning/STATE.md" ]; then
    ok "R-LECTURE-FIDELE-MULTI-NOMINAL STATE.md créé"
  else
    ko "R-LECTURE-FIDELE-MULTI-NOMINAL STATE.md créé" "présent" "absent" "-"
  fi

  # ---------- R-LECTURE-FIDELE-MULTI-UN-ILLISIBLE — un seul compartiment illisible parmi trois :
  # refus MÊME quand les deux autres sont parfaitement lisibles (jamais une moyenne, un seul suffit)
  L7_MULTI2_DIR="$WORK/lot7-multi-un-illisible"
  rm -rf "$L7_MULTI2_DIR"
  mkdir -p "$L7_MULTI2_DIR/.planning/workstreams/alpha" "$L7_MULTI2_DIR/.planning/workstreams/beta"
  printf '{"planning_version": "cycles-v1"}\n' > "$L7_MULTI2_DIR/.planning/config.json"
  printf -- '---\nworkstream: alpha\ncreated: 2026-09-28\n---\n' > "$L7_MULTI2_DIR/.planning/workstreams/alpha/notes.md"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$L7_MULTI2_DIR/.planning/workstreams/beta/STATE.md"
  empreinte "$L7_MULTI2_DIR" > "$WORK/lot7-multi2-avant.txt"
  chmod 000 "$L7_MULTI2_DIR/.planning/workstreams/beta"
  ( cd "$L7_MULTI2_DIR" && bash "$RECALC" "--planning=.planning" >"$L7_MULTI2_DIR.out.txt" 2>"$L7_MULTI2_DIR.err.txt" )
  L7_MULTI2_RC=$?
  chmod 755 "$L7_MULTI2_DIR/.planning/workstreams/beta"
  empreinte "$L7_MULTI2_DIR" > "$WORK/lot7-multi2-apres.txt"
  if [ "$L7_MULTI2_RC" -eq 3 ] && grep -qF "garde de lecture du détecteur, lot 7" "$L7_MULTI2_DIR.err.txt"; then
    ok "R-LECTURE-FIDELE-MULTI-UN-ILLISIBLE refus malgré deux compartiments lisibles sur trois"
  else
    ko "R-LECTURE-FIDELE-MULTI-UN-ILLISIBLE" "rc=3, cite la garde lot 7" "rc=3 attendu" "rc=$L7_MULTI2_RC · $(cat "$L7_MULTI2_DIR.err.txt" | tr '\n' '|')"
  fi
  if cmp -s "$WORK/lot7-multi2-avant.txt" "$WORK/lot7-multi2-apres.txt"; then
    ok "R-LECTURE-FIDELE-MULTI-UN-ILLISIBLE empreinte identique avant/après"
  else
    ko "R-LECTURE-FIDELE-MULTI-UN-ILLISIBLE empreinte" "identique" "diverge" "-"
  fi
fi

# ---------- MUT-LECTURE-FIDELE-PERM — la garde neutralisée (if False:), discriminant à PERMISSIONS
# dégradées (distinct de MUT-ENUM-FIDELE, qui discrimine sur un nom à saut de ligne) : prouve que
# la MÊME ligne de décision couvre aussi la classe « lisibilité réelle » du lot 7 -------------------
if _lot7_root_actif; then
  echo "  ⊘ MUT-LECTURE-FIDELE-PERM SKIP (UID 0)"
else
  if make_recalc_mutant LECTURE-FIDELE-PERM 'if not fidele:' 'if False:  # MUT-LECTURE-FIDELE-PERM (garde neutralisée)'; then
    MR="$MUT_DIR/recalc-planning.sh"
    DIR_CAS="$WORK/mut-lecture-fidele-perm-cas"
    mkdir -p "$DIR_CAS/.planning/workstreams/gouvernance"
    printf '{"planning_version": "cycles-v1"}\n' > "$DIR_CAS/.planning/config.json"
    printf -- '---\ngsd_state_version: 1.0\n---\n' > "$DIR_CAS/.planning/workstreams/gouvernance/STATE.md"
    chmod 000 "$DIR_CAS/.planning/workstreams/gouvernance"
    ( cd "$DIR_CAS" && bash "$MR" >"$WORK/mut-lecture-fidele-perm-out.txt" 2>"$WORK/mut-lecture-fidele-perm-err.txt" ); RC_M=$?
    chmod 755 "$DIR_CAS/.planning/workstreams/gouvernance"
    if ! _verifier_plantage LECTURE-FIDELE-PERM "code de sortie (compartiment chmod 000, marqueur GSD à l'intérieur — R-LECTURE-FIDELE [compartiment-dir mode=000])" "$WORK/mut-lecture-fidele-perm-out.txt" "$WORK/mut-lecture-fidele-perm-err.txt" "$RC_M"; then
      if [ "$RC_M" -ne 3 ]; then
        okmut LECTURE-FIDELE-PERM "code de sortie · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture silencieuse sur un compartiment chmod 000 réellement tenu par GSD — régression exacte de l'audit du 2026-09-28)"
      else
        komut LECTURE-FIDELE-PERM "code de sortie" "3" "$RC_M (mutant non opposable)"
      fi
    fi
  fi
fi

# ---------- MUT-OSERROR-IGNOREE — `_ouvrable` bascule en fail-open sur OSError (F2 rejoué) --------
if _lot7_root_actif; then
  echo "  ⊘ MUT-OSERROR-IGNOREE SKIP (UID 0)"
else
  if make_recalc_mutant OSERROR-IGNOREE \
    'return False  # _ouvrable : toute OSError -> refus nommé, jamais un fail-open (F2)' \
    'return True  # MUT-OSERROR-IGNOREE (fail-open)'
  then
    MR="$MUT_DIR/recalc-planning.sh"
    DIR_CAS="$WORK/mut-oserror-ignoree-cas"
    mkdir -p "$DIR_CAS/.planning/workstreams/gouvernance"
    printf '{"planning_version": "cycles-v1"}\n' > "$DIR_CAS/.planning/config.json"
    printf -- '---\ngsd_state_version: 1.0\n---\n' > "$DIR_CAS/.planning/workstreams/gouvernance/STATE.md"
    chmod 000 "$DIR_CAS/.planning/workstreams/gouvernance/STATE.md"
    ( cd "$DIR_CAS" && bash "$MR" >"$WORK/mut-oserror-ignoree-out.txt" 2>"$WORK/mut-oserror-ignoree-err.txt" ); RC_M=$?
    chmod 644 "$DIR_CAS/.planning/workstreams/gouvernance/STATE.md"
    if ! _verifier_plantage OSERROR-IGNOREE "code de sortie (STATE.md de compartiment chmod 000 — R-LECTURE-FIDELE [compartiment-state mode=000])" "$WORK/mut-oserror-ignoree-out.txt" "$WORK/mut-oserror-ignoree-err.txt" "$RC_M"; then
      if [ "$RC_M" -ne 3 ]; then
        okmut OSERROR-IGNOREE "code de sortie · attendu (original) : 3 · obtenu (mutant, _ouvrable fail-open sur OSError) : $RC_M (écriture silencieuse — le détecteur réel, lui, ne peut pas lire non plus ce STATE.md et retombe sur code 3 « terrain libre »)"
      else
        komut OSERROR-IGNOREE "code de sortie" "3" "$RC_M (mutant non opposable)"
      fi
    fi
  fi
fi

# ================================================================================================
# Lot 8 (correction de CLASSE, décision du head sous délégation technique de Willy, session
# principale, 2026-09-28) — deux corrections indépendantes sur la garde de lecture du lot 7 :
#   1. `os.path.isfile` (mirroir EXACT de `[ -f ]`, que lit le détecteur — `detect-gsd-engine.sh:
#      96,184`) remplace `os.path.lexists` pour juger le `STATE.md` racine ET de compartiment — un
#      lien symbolique CASSÉ (cible absente) est désormais traité comme ABSENT, exactement comme le
#      détecteur, jamais un refus « illisible ». ROUGE sur HEAD 345303e (avant ce lot) : sur-refus
#      côté compartiment (le moteur refusait d'écrire, motif « compartiment-state-illisible », sur
#      un planning SANS AUCUN marqueur GSD nulle part — `ENOENT` confondu avec une vraie erreur de
#      lecture) ; le STATE.md racine en lien cassé, lui, reste refusé PAR AILLEURS (garde B de
#      `appliquer_ecritures`, « emplacement occupé » — inchangée par ce lot, la cible du lien n'est
#      jamais créée).
#   2. `_ouvrable` ouvre désormais en `O_NONBLOCK` et contrôle le type par `fstat` — un `STATE.md`
#      en FIFO n'y bloque plus jamais. ROUGE sur HEAD 345303e : blocage INDÉFINI mesuré par
#      exécution bornée dans le temps (`subprocess.run(timeout=…)` / `multiprocessing` — ce poste
#      n'a NI `timeout` NI `gtimeout`).
# ================================================================================================

# ---------- Aide Python : exécution du moteur bornée dans le temps (aucun `timeout`/`gtimeout` sur
# ce poste — subprocess.run(timeout=…) borne l'attente, le sous-processus est tué par Python même
# s'il est bloqué en E/S) ---------------------------------------------------------------------
LOT8_BORNE_PY="$WORK/lot8-borne.py"
cat > "$LOT8_BORNE_PY" <<'PY_LOT8_BORNE_EOF'
import subprocess
import sys
import time

recalc, cwd, delai = sys.argv[1], sys.argv[2], float(sys.argv[3])
t0 = time.time()
try:
    proc = subprocess.run(
        ["bash", recalc, "--planning=.planning"],
        cwd=cwd, timeout=delai, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    dt = time.time() - t0
    sys.stdout.write("BLOQUE=non\n")
    sys.stdout.write("RC=%d\n" % proc.returncode)
    sys.stdout.write("DUREE=%.2f\n" % dt)
    sys.stdout.write("STDERR=%s\n" % proc.stderr.decode("utf-8", "replace").replace("\n", " | "))
except subprocess.TimeoutExpired:
    dt = time.time() - t0
    sys.stdout.write("BLOQUE=oui\n")
    sys.stdout.write("DUREE=%.2f\n" % dt)
PY_LOT8_BORNE_EOF

# ---------- R-LOT8-LIEN-CASSE-COMPARTIMENT — lien cassé, AUCUN marqueur GSD nulle part : traité
# comme ABSENT, écriture AUTORISÉE (exit 0) -------------------------------------------------------
L8_D1="$WORK/lot8-lien-casse-compartiment"
rm -rf "$L8_D1"
mkdir -p "$L8_D1/.planning/workstreams/gouvernance"
printf '{"planning_version": "cycles-v1"}\n' > "$L8_D1/.planning/config.json"
ln -s "$L8_D1/.planning/workstreams/gouvernance/ABSENT.md" "$L8_D1/.planning/workstreams/gouvernance/STATE.md"
( cd "$L8_D1" && bash "$RECALC" "--planning=.planning" >"$L8_D1.out.txt" 2>"$L8_D1.err.txt" )
L8_D1_RC=$?
if [ "$L8_D1_RC" -eq 0 ] && [ -f "$L8_D1/.planning/STATE.md" ]; then
  ok "R-LOT8-LIEN-CASSE-COMPARTIMENT : lien cassé traité comme absent, écriture autorisée (rc=0)"
else
  ko "R-LOT8-LIEN-CASSE-COMPARTIMENT" "rc=0, STATE.md racine écrit" "rc=$L8_D1_RC" "$(cat "$L8_D1.err.txt" | tr '\n' '|')"
fi

# ---------- R-LOT8-LIEN-CASSE-RACINE — lien cassé RACINE : TOUJOURS refusé (garde B, « emplacement
# occupé »), la cible du lien n'est JAMAIS créée --------------------------------------------------
L8_D2="$WORK/lot8-lien-casse-racine"
rm -rf "$L8_D2"
mkdir -p "$L8_D2/.planning"
printf '{"planning_version": "cycles-v1"}\n' > "$L8_D2/.planning/config.json"
ln -s "$L8_D2/.planning/ABSENT.md" "$L8_D2/.planning/STATE.md"
( cd "$L8_D2" && bash "$RECALC" "--planning=.planning" >"$L8_D2.out.txt" 2>"$L8_D2.err.txt" )
L8_D2_RC=$?
if [ "$L8_D2_RC" -eq 1 ] && grep -qF "emplacement occupé" "$L8_D2.err.txt" && [ ! -e "$L8_D2/.planning/ABSENT.md" ]; then
  ok "R-LOT8-LIEN-CASSE-RACINE : refus par la garde B (emplacement occupé), cible du lien jamais créée"
else
  L8_D2_CIBLE_EXISTE="non"; [ -e "$L8_D2/.planning/ABSENT.md" ] && L8_D2_CIBLE_EXISTE="oui"
  ko "R-LOT8-LIEN-CASSE-RACINE" "rc=1, « emplacement occupé », cible jamais créée" "rc=$L8_D2_RC" "$(cat "$L8_D2.err.txt" | tr '\n' '|') · cible existe=$L8_D2_CIBLE_EXISTE"
fi

# ---------- R-LOT8-FIFO-RACINE — STATE.md racine en FIFO : refus RAPIDE (garde B), jamais de
# blocage (borné à 6s) ------------------------------------------------------------------------
L8_D3="$WORK/lot8-fifo-racine"
rm -rf "$L8_D3"
mkdir -p "$L8_D3/.planning"
printf '{"planning_version": "cycles-v1"}\n' > "$L8_D3/.planning/config.json"
mkfifo "$L8_D3/.planning/STATE.md"
L8_D3_OUT="$("$PYBIN" "$LOT8_BORNE_PY" "$RECALC" "$L8_D3" 6)"
if echo "$L8_D3_OUT" | grep -q "^BLOQUE=non$" && echo "$L8_D3_OUT" | grep -q "^RC=1$" && echo "$L8_D3_OUT" | grep -q "emplacement occupé"; then
  ok "R-LOT8-FIFO-RACINE : refus RAPIDE (garde B), jamais de blocage ($(echo "$L8_D3_OUT" | grep '^DUREE='))"
else
  ko "R-LOT8-FIFO-RACINE" "BLOQUE=non, RC=1, « emplacement occupé », <6s" "$(echo "$L8_D3_OUT" | tr '\n' '|')" "-"
fi

# ---------- R-LOT8-FIFO-COMPARTIMENT — STATE.md de compartiment en FIFO, AUCUN marqueur ailleurs :
# traité comme absent (`[ -f ]` faux sur une FIFO, comme pour le détecteur), écriture AUTORISÉE,
# RAPIDE, jamais de blocage (borné à 6s) --------------------------------------------------------
L8_D4="$WORK/lot8-fifo-compartiment"
rm -rf "$L8_D4"
mkdir -p "$L8_D4/.planning/workstreams/gouvernance"
printf '{"planning_version": "cycles-v1"}\n' > "$L8_D4/.planning/config.json"
mkfifo "$L8_D4/.planning/workstreams/gouvernance/STATE.md"
L8_D4_OUT="$("$PYBIN" "$LOT8_BORNE_PY" "$RECALC" "$L8_D4" 6)"
if echo "$L8_D4_OUT" | grep -q "^BLOQUE=non$" && echo "$L8_D4_OUT" | grep -q "^RC=0$"; then
  ok "R-LOT8-FIFO-COMPARTIMENT : traité comme absent, écriture autorisée, RAPIDE ($(echo "$L8_D4_OUT" | grep '^DUREE='))"
else
  ko "R-LOT8-FIFO-COMPARTIMENT" "BLOQUE=non, RC=0, <6s" "$(echo "$L8_D4_OUT" | tr '\n' '|')" "-"
fi

# ---------- R-LOT8-OUVRABLE-FIFO — `_ouvrable` appelée DIRECTEMENT sur une FIFO (contourne le
# gate `os.path.isfile` des deux sites d'appel ci-dessus, qui ne l'atteint jamais depuis eux avec
# le correctif 1 — défense en profondeur exercée quand même, au niveau unitaire) : RAPIDE, refus
# nommé (False), jamais de blocage --------------------------------------------------------------
L8_OUVRABLE_FIXE_OUT="$("$PYBIN" "$F3F5_AIDE_PY" ouvrable-fifo-fixed "$F3F5_BODY_REEL" 6 2>&1)"
if echo "$L8_OUVRABLE_FIXE_OUT" | grep -q "^BLOQUE=non" && echo "$L8_OUVRABLE_FIXE_OUT" | grep -q "RESULTAT=False"; then
  ok "R-LOT8-OUVRABLE-FIFO : _ouvrable(FIFO) RAPIDE, refus nommé (False) ($L8_OUVRABLE_FIXE_OUT)"
else
  ko "R-LOT8-OUVRABLE-FIFO" "BLOQUE=non, RESULTAT=False, <6s" "$L8_OUVRABLE_FIXE_OUT" "-"
fi

# ---------- MUT-LOT8-ONONBLOCK — `O_NONBLOCK` retiré de `_ouvrable` : la FIFO bloque à nouveau ----
L8_OUVRABLE_MUT_OUT="$("$PYBIN" "$F3F5_AIDE_PY" ouvrable-fifo-regresse "$F3F5_BODY_REEL" 6 2>&1)"
if echo "$L8_OUVRABLE_MUT_OUT" | grep -q "BLOC_INTROUVABLE"; then
  komut LOT8-ONONBLOCK "motif fixe unique (BLOC_L8_ONONBLOCK_CORRIGE) dans le corps extrait" "exactement 1 occurrence" "BLOC INTROUVABLE"
elif echo "$L8_OUVRABLE_MUT_OUT" | grep -q "^BLOQUE=oui"; then
  okmut LOT8-ONONBLOCK "_ouvrable(FIFO) · attendu (original, O_NONBLOCK) : RAPIDE, refus nommé (False) · obtenu (mutant, open() nu sans O_NONBLOCK) : BLOQUE ($L8_OUVRABLE_MUT_OUT)"
else
  komut LOT8-ONONBLOCK "_ouvrable(FIFO) bloque sans O_NONBLOCK" "BLOQUE=oui" "$L8_OUVRABLE_MUT_OUT (mutant non opposable)"
fi

# ---------- R-LOT8-TEMOIN — lien de COMPARTIMENT vers un fichier régulier interne (porteur de
# `gsd_state_version`, puis SANS marqueur) : le verdict du moteur égale TOUJOURS celui du VRAI
# détecteur lancé directement (oracle différentiel, patron lot 4). Compartiment plutôt que racine :
# un lien à l'emplacement STATE.md RACINE est refusé par la garde B indépendamment du contenu visé
# (F4, R-LOT8-LIEN-CASSE-RACINE ci-dessus) — ce n'est pas ce que ce témoin veut isoler. -------------
lot8_temoin() { # <label> <fn_setup>
  local label="$1" fn_setup="$2"
  local dir_oracle="$WORK/lot8-temoin-$label-detecteur" dir_moteur="$WORK/lot8-temoin-$label-moteur"
  local code_detecteur code_moteur code_attendu
  materialiser traceur "$dir_oracle"; "$fn_setup" "$dir_oracle"
  materialiser traceur "$dir_moteur"; "$fn_setup" "$dir_moteur"
  ( cd "$dir_oracle" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet --path .planning >/dev/null 2>"$WORK/lot8-temoin-$label-detecteur-err.txt" )
  code_detecteur=$?
  ( cd "$dir_moteur" && bash "$RECALC" >"$WORK/lot8-temoin-$label-moteur-out.txt" 2>"$WORK/lot8-temoin-$label-moteur-err.txt" )
  code_moteur=$?
  case "$code_detecteur" in
    # GATE-14 (45-02, P45-D-02) : même scission que R-ORACLE-DIFFERENTIEL (lab traceur adhérent).
    3|2) code_attendu=0 ;;
    0) code_attendu=3 ;;
    *) ko "R-LOT8-TEMOIN [$label] code du détecteur direct" "0, 2 ou 3" "$code_detecteur" "-"; return ;;
  esac
  if [ "$code_moteur" -eq "$code_attendu" ]; then
    ok "R-LOT8-TEMOIN [$label] détecteur direct=$code_detecteur -> moteur=$code_moteur (attendu $code_attendu)"
  else
    ko "R-LOT8-TEMOIN [$label] code moteur" "$code_attendu (détecteur direct=$code_detecteur)" "$code_moteur" "$(cat "$WORK/lot8-temoin-$label-moteur-out.txt")"
  fi
}
setup_lot8_lien_vers_marqueur() {
  mkdir -p "$1/.planning/workstreams/temoin-lot8"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$1/.planning/workstreams/temoin-lot8/STATE.md.cible"
  ln -s "$1/.planning/workstreams/temoin-lot8/STATE.md.cible" "$1/.planning/workstreams/temoin-lot8/STATE.md"
}
setup_lot8_lien_vers_sans_marqueur() {
  mkdir -p "$1/.planning/workstreams/temoin-lot8"
  printf -- '---\ntitre: sans marqueur\n---\n' > "$1/.planning/workstreams/temoin-lot8/STATE.md.cible"
  ln -s "$1/.planning/workstreams/temoin-lot8/STATE.md.cible" "$1/.planning/workstreams/temoin-lot8/STATE.md"
}
lot8_temoin lien-vers-marqueur setup_lot8_lien_vers_marqueur
lot8_temoin lien-vers-sans-marqueur setup_lot8_lien_vers_sans_marqueur

# ---------- MUT-LOT8-LIEN-CASSE-COMPARTIMENT — `os.path.isfile` du compartiment reverti à
# `os.path.lexists` : le sur-refus du lot 6/7 revient sur le cas R-LOT8-LIEN-CASSE-COMPARTIMENT ---
if make_recalc_mutant LOT8-LIEN-CASSE-COMPARTIMENT \
  'if os.path.isfile(etat_compartiment) and not _ouvrable(etat_compartiment, est_dossier=False):' \
  'if os.path.lexists(etat_compartiment) and not _ouvrable(etat_compartiment, est_dossier=False):  # MUT-LOT8-LIEN-CASSE-COMPARTIMENT'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-lot8-lien-casse-compartiment-cas"
  rm -rf "$DIR_CAS"
  mkdir -p "$DIR_CAS/.planning/workstreams/gouvernance"
  printf '{"planning_version": "cycles-v1"}\n' > "$DIR_CAS/.planning/config.json"
  ln -s "$DIR_CAS/.planning/workstreams/gouvernance/ABSENT.md" "$DIR_CAS/.planning/workstreams/gouvernance/STATE.md"
  ( cd "$DIR_CAS" && bash "$MR" >"$WORK/mut-lot8-lien-casse-compartiment-out.txt" 2>"$WORK/mut-lot8-lien-casse-compartiment-err.txt" ); RC_M=$?
  if ! _verifier_plantage LOT8-LIEN-CASSE-COMPARTIMENT "code de sortie (lien cassé de compartiment, aucun marqueur GSD — R-LOT8-LIEN-CASSE-COMPARTIMENT)" "$WORK/mut-lot8-lien-casse-compartiment-out.txt" "$WORK/mut-lot8-lien-casse-compartiment-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 0 ]; then
      okmut LOT8-LIEN-CASSE-COMPARTIMENT "code de sortie · attendu (original, os.path.isfile) : 0 · obtenu (mutant, os.path.lexists) : $RC_M (sur-refus : lien cassé confondu avec illisible, régression exacte de l'audit du 2026-09-28)"
    else
      komut LOT8-LIEN-CASSE-COMPARTIMENT "code de sortie" "0 (mutant non opposable)" "$RC_M"
    fi
  fi
fi

# ---------- MUT-LOT8-LIEN-CASSE-RACINE — `os.path.isfile` de la racine reverti à `os.path.lexists`
# : le motif de refus change (garde de lecture, code 3) au lieu de la garde B (« emplacement
# occupé », code 1) — même issue « refusé », mais pour la MAUVAISE raison (diagnostic divergent) ---
if make_recalc_mutant LOT8-LIEN-CASSE-RACINE \
  'if os.path.isfile(etat_racine) and not _ouvrable(etat_racine, est_dossier=False):' \
  'if os.path.lexists(etat_racine) and not _ouvrable(etat_racine, est_dossier=False):  # MUT-LOT8-LIEN-CASSE-RACINE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-lot8-lien-casse-racine-cas"
  rm -rf "$DIR_CAS"
  mkdir -p "$DIR_CAS/.planning"
  printf '{"planning_version": "cycles-v1"}\n' > "$DIR_CAS/.planning/config.json"
  ln -s "$DIR_CAS/.planning/ABSENT.md" "$DIR_CAS/.planning/STATE.md"
  ( cd "$DIR_CAS" && bash "$MR" >"$WORK/mut-lot8-lien-casse-racine-out.txt" 2>"$WORK/mut-lot8-lien-casse-racine-err.txt" ); RC_M=$?
  if ! _verifier_plantage LOT8-LIEN-CASSE-RACINE "code de sortie (lien cassé racine — R-LOT8-LIEN-CASSE-RACINE)" "$WORK/mut-lot8-lien-casse-racine-out.txt" "$WORK/mut-lot8-lien-casse-racine-err.txt" "$RC_M"; then
    if [ "$RC_M" -eq 3 ] && ! grep -qF "emplacement occupé" "$WORK/mut-lot8-lien-casse-racine-err.txt"; then
      okmut LOT8-LIEN-CASSE-RACINE "code/motif de refus · attendu (original, os.path.isfile) : rc=1, « emplacement occupé » (garde B) · obtenu (mutant, os.path.lexists) : rc=$RC_M, « garde de lecture » (diagnostic divergent, régression de traçabilité)"
    else
      komut LOT8-LIEN-CASSE-RACINE "code/motif de refus" "rc=3 sans « emplacement occupé »" "rc=$RC_M · $(cat "$WORK/mut-lot8-lien-casse-racine-err.txt" | tr '\n' '|') (mutant non opposable)"
    fi
  fi
fi

# ================================================================================================
# Lot 2 L2 — assainissement STRUCTUREL de tout champ recopié dans cloture.log (_jeton_journal),
# preuve avec la valeur piégée exacte de l'audit.
# ================================================================================================

# ---------- L2 — _formater_ligne_journal : un seul enregistrement, jamais un faux lisible --------
L2_FIXE_OUT="$("$PYBIN" "$F3F5_AIDE_PY" l2 "$F3F5_BODY_REEL" 2>&1)"
if echo "$L2_FIXE_OUT" | grep -q "^MATCH=True$" && echo "$L2_FIXE_OUT" | grep -q "^NB_VERDICT=1$" && echo "$L2_FIXE_OUT" | grep -q "^NB_TENTATIVE=1$"; then
  ok "L2 _formater_ligne_journal : valeur piégée réduite à un jeton, un seul enregistrement lisible"
else
  ko "L2 _formater_ligne_journal (code réel)" "MATCH=True, NB_VERDICT=1, NB_TENTATIVE=1" "$L2_FIXE_OUT" "-"
fi

# ---------- MUT-JOURNAL-SANITIZE — assainissement de _jeton_journal neutralisé -------------------
if make_recalc_mutant JOURNAL-SANITIZE \
  'if caractere == "%" or caractere == "=" or caractere.isspace() or not caractere.isprintable():' \
  'if False:  # MUT-JOURNAL-SANITIZE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  MUT_L2_BODY="$WORK/mut-journal-sanitize-corps.py"
  awk '/<<.PY_RECALC_PLANNING_EOF.$/{f=1;next} /^PY_RECALC_PLANNING_EOF$/{f=0} f' "$MR" > "$MUT_L2_BODY"
  L2_MUT_OUT="$("$PYBIN" "$F3F5_AIDE_PY" l2 "$MUT_L2_BODY" 2>&1)"
  if echo "$L2_MUT_OUT" | grep -q "^MATCH=True$" && echo "$L2_MUT_OUT" | grep -q "^NB_VERDICT=1$" && echo "$L2_MUT_OUT" | grep -q "^NB_TENTATIVE=1$"; then
    komut JOURNAL-SANITIZE "un seul enregistrement lisible sur la valeur piégée" "propriété tenue (original)" "propriété tenue (mutant non opposable)"
  else
    okmut JOURNAL-SANITIZE "un seul enregistrement lisible sur la valeur piégée · attendu (original) : MATCH=True, NB_VERDICT=1, NB_TENTATIVE=1 · obtenu (mutant, assainissement désactivé) : $L2_MUT_OUT"
  fi
fi

# ================================================================================================
# R-INJECTIF-GENERATIF (item 2.3, lot 4) — _jeton_journal encode de façon INJECTIVE (pourcent) une
# valeur RECOPIÉE TELLE QUELLE dans cloture.log (P44-D-09) : deux valeurs distinctes produisent
# TOUJOURS deux jetons distincts. Preuve en deux volets exécutés contre le CORPS RÉEL du moteur
# (jamais une réimplémentation indépendante) : (1) paires de collision explicites de l'ancien
# encodage par `_`, plus une preuve générative >= 2000 paires aléatoires à graine fixe — zéro
# collision, `LIGNE_JOURNAL_RE` relit chaque jeton produit, décodage pourcent = valeur d'origine ;
# (2) round-trip réel à deux exécutions successives sur le MÊME chemin de phase, plus bas.
# ================================================================================================
MOTEUR_EXTRAIT_CORPS="$WORK/moteur-extrait-corps.py"
MOTEUR_EXTRAIT_PY="$WORK/moteur-extrait.py"
awk '/<<.PY_RECALC_PLANNING_EOF.$/{f=1;next} /^PY_RECALC_PLANNING_EOF$/{f=0} f' "$RECALC" > "$MOTEUR_EXTRAIT_CORPS"
"$PYBIN" -c '
import sys
lignes = open(sys.argv[1], encoding="utf-8").read().split("\n")
while lignes and lignes[-1].strip() == "":
    lignes.pop()
if lignes and lignes[-1].strip() == "main()":
    lignes.pop()
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(lignes))
' "$MOTEUR_EXTRAIT_CORPS" "$MOTEUR_EXTRAIT_PY"

INJECTIF_AIDE_PY="$WORK/injectif-aide.py"
cat > "$INJECTIF_AIDE_PY" <<'PY_INJECTIF_AIDE_EOF'
import importlib.util
import random
import re
import sys

chemin = sys.argv[1]
spec = importlib.util.spec_from_file_location("moteur_extrait", chemin)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def decoder_pourcent(jeton):
    resultat = bytearray()
    i = 0
    n = len(jeton)
    while i < n:
        c = jeton[i]
        if c == "%" and i + 2 < n and re.match(r"^[0-9A-Fa-f]{2}$", jeton[i + 1:i + 3]):
            resultat.append(int(jeton[i + 1:i + 3], 16))
            i += 3
        else:
            resultat.extend(c.encode("utf-8"))
            i += 1
    return bytes(resultat).decode("utf-8")


erreurs = []

paires_explicites = [("3 4", "3_4"), ("a=b", "a_b"), ("cycles/01 traceur", "cycles/01_traceur")]
for a, b in paires_explicites:
    if m._jeton_journal(a, "-") == m._jeton_journal(b, "-"):
        erreurs.append("collision explicite non resolue : %r vs %r" % (a, b))

# Alphabet étendu F44-05/F7 (correction ciblée, lot 5) : NUL et les contrôles C0/C1 complets
# (0x00-0x1F, DEL 0x7F, 0x80-0x9F) rejoignent les séparateurs Unicode déjà couverts — avant lot 5,
# ces octets traversaient `_jeton_journal` BRUTS (seul `str.isspace()` les filtrait, et aucun des
# deux groupes n'est un espace).
alphabet = list(" \t\n\r\v\f=%_") + [chr(0x2028), chr(0x0085), chr(0x00A0), chr(0x3000)] + \
    [chr(c) for c in range(0, 0x20)] + [chr(0x7F)] + [chr(c) for c in range(0x80, 0xA0)] + \
    list("abcXYZ09/-")
random.seed(1729)
vues = {}
collisions = 0
echecs_roundtrip = 0
echecs_regex = 0
echecs_non_imprimable = 0
NB = 2000
for _ in range(NB):
    k = random.randint(1, 8)
    valeur = "".join(random.choice(alphabet) for _ in range(k))
    jeton = m._jeton_journal(valeur, "-")
    if jeton in vues and vues[jeton] != valeur:
        collisions += 1
    vues[jeton] = valeur
    if decoder_pourcent(jeton) != valeur:
        echecs_roundtrip += 1
    # F44-05/F7 : aucun octet de contrôle brut dans le jeton produit — chaque caractère du jeton
    # final doit être imprimable (le `%` d'échappement et les chiffres hexadécimaux le sont tous).
    if any(not ch.isprintable() for ch in jeton):
        echecs_non_imprimable += 1
    ligne = "2026-09-28T00:00:00+00:00  " + jeton + "  auteur  verdict=passe  tentative=1  date=observation"
    if m.LIGNE_JOURNAL_RE.match(ligne) is None:
        echecs_regex += 1

if collisions:
    erreurs.append("collisions=%d sur %d paires generees" % (collisions, NB))
if echecs_roundtrip:
    erreurs.append("echecs_roundtrip=%d" % echecs_roundtrip)
if echecs_regex:
    erreurs.append("echecs_regex=%d" % echecs_regex)
if echecs_non_imprimable:
    erreurs.append("echecs_non_imprimable=%d (octet de controle brut dans le jeton)" % echecs_non_imprimable)

if erreurs:
    print("ERREURS=" + " | ".join(erreurs))
else:
    print("OK NB=%d" % NB)
PY_INJECTIF_AIDE_EOF

INJECTIF_OUT="$("$PYBIN" "$INJECTIF_AIDE_PY" "$MOTEUR_EXTRAIT_PY" 2>&1)"
if [ "$INJECTIF_OUT" = "OK NB=2000" ]; then
  ok "R-INJECTIF-GENERATIF collisions/paires explicites/round-trip/LIGNE_JOURNAL_RE : 2000 paires, zéro échec"
else
  ko "R-INJECTIF-GENERATIF" "OK NB=2000" "$INJECTIF_OUT" "-"
fi

# ================================================================================================
# F5 (correction ciblée, lot 5) — `_jeton_journal(valeur, repli="")` : un repli vide est une erreur
# BRUYANTE (ValueError immédiate), jamais un jeton vide écrit en silence dans cloture.log.
# ================================================================================================
F5_JETON_VIDE_AIDE_PY="$WORK/f5-jeton-vide-aide.py"
cat > "$F5_JETON_VIDE_AIDE_PY" <<'PY_F5_JETON_VIDE_EOF'
import importlib.util
import sys

chemin = sys.argv[1]
spec = importlib.util.spec_from_file_location("moteur_extrait", chemin)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

try:
    m._jeton_journal(None, "")
    print("PAS-D-ERREUR")
except ValueError:
    print("VALUEERROR")
except Exception as exc:
    print("AUTRE-EXCEPTION=" + type(exc).__name__)
PY_F5_JETON_VIDE_EOF
F5_JETON_VIDE_OUT="$("$PYBIN" "$F5_JETON_VIDE_AIDE_PY" "$MOTEUR_EXTRAIT_PY" 2>&1)"
if [ "$F5_JETON_VIDE_OUT" = "VALUEERROR" ]; then
  ok "F5 _jeton_journal(None, repli=\"\") : ValueError bruyante, jamais un jeton vide silencieux"
else
  ko "F5 _jeton_journal(None, repli=\"\")" "VALUEERROR" "$F5_JETON_VIDE_OUT" "-"
fi
if make_recalc_mutant F5-JETON-VIDE \
  'if not repli:' \
  'if False:  # MUT-F5-JETON-VIDE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  MUT_F5_BODY_BRUT="$WORK/mut-f5-jeton-vide-corps-brut.py"
  MUT_F5_BODY="$WORK/mut-f5-jeton-vide-corps.py"
  awk '/<<.PY_RECALC_PLANNING_EOF.$/{f=1;next} /^PY_RECALC_PLANNING_EOF$/{f=0} f' "$MR" > "$MUT_F5_BODY_BRUT"
  # `main()` retiré (comme MOTEUR_EXTRAIT_PY) : `importlib` exécute TOUT le module au chargement —
  # sans ce retrait, l'appel final `main()` tournerait avec le mauvais `sys.argv` et planterait
  # avant même d'atteindre `_jeton_journal`, faussant le verdict du mutant en « tué » par accident.
  "$PYBIN" -c '
import sys
lignes = open(sys.argv[1], encoding="utf-8").read().split("\n")
while lignes and lignes[-1].strip() == "":
    lignes.pop()
if lignes and lignes[-1].strip() == "main()":
    lignes.pop()
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(lignes))
' "$MUT_F5_BODY_BRUT" "$MUT_F5_BODY"
  F5_MUT_OUT="$("$PYBIN" "$F5_JETON_VIDE_AIDE_PY" "$MUT_F5_BODY" 2>&1)"
  if [ "$F5_MUT_OUT" = "VALUEERROR" ]; then
    komut F5-JETON-VIDE "ValueError sur repli vide" "VALUEERROR (original)" "VALUEERROR (mutant non opposable)"
  else
    okmut F5-JETON-VIDE "ValueError sur repli vide · attendu (original) : VALUEERROR · obtenu (mutant, garde retirée) : $F5_MUT_OUT"
  fi
fi

# ================================================================================================
# F6 (revue) — détecteur ABSENT et détecteur NON RÉGULIER : deux messages stderr distincts. R09
# [absent] (plus haut) ne vérifiait que le code de sortie ; ce test cible le TEXTE.
# ================================================================================================
F6_DIR="$WORK/f6-absent"; F6_SCRIPTS="$WORK/f6-absent-scripts"
materialiser traceur "$F6_DIR"
mkdir -p "$F6_SCRIPTS"
cp "$RECALC" "$F6_SCRIPTS/recalc-planning.sh"
# aucun detect-gsd-engine.sh dans $F6_SCRIPTS : cas « absent »
( cd "$F6_DIR" && GSD_HOME="$FAKE_GSD" bash "$F6_SCRIPTS/recalc-planning.sh" >"$WORK/f6-absent-out.txt" 2>"$WORK/f6-absent-err.txt" )
if grep -q "détecteur absent" "$WORK/f6-absent-err.txt" && ! grep -q "détecteur non régulier" "$WORK/f6-absent-err.txt"; then
  ok "F6 détecteur absent : message « détecteur absent », jamais « détecteur non régulier »"
else
  ko "F6 détecteur absent stderr" "contient « détecteur absent », pas « détecteur non régulier »" "$(cat "$WORK/f6-absent-err.txt")" "-"
fi

# ================================================================================================
# F44-06 (correction ciblée) — `ecrire_si_different` lisait l'existant par `open()` nu, seul site
# des lectures du modèle sans `O_NOFOLLOW`. Discriminant RÉEL (pas un TOCTOU rejoué à l'aveugle,
# « difficile à forcer » selon le mandat) : `est_fichier_regulier` est monkeypatché pour toujours
# répondre « régulier » — ce qui SIMULE exactement l'instant d'un TOCTOU (lien substitué ENTRE le
# contrôle et la lecture) sans dépendre d'une vraie course — puis `chemin` est un VRAI lien
# symbolique vers un fichier cible dont le contenu est IDENTIQUE à ce qu'on demande d'écrire.
# Ancien code (`open()` nu, suit le lien) : lit le contenu de la cible à travers le lien, le compare
# au contenu demandé -> identiques -> ne réécrit PAS (`False`), la cible ayant été lue à travers le
# lien. Nouveau code (`O_NOFOLLOW`, `ELOOP` intercepté) : ne lit jamais la cible -> `existant=None`
# -> réécrit (`True`), remplace le LIEN par un fichier régulier — la cible, elle, reste intacte.
# ================================================================================================
F44_06_DIR="$WORK/f44-06"
mkdir -p "$F44_06_DIR"
F44_06_CIBLE="$F44_06_DIR/cible-secrete.txt"
F44_06_LIEN="$F44_06_DIR/lien-vers-cible.txt"
printf 'CONTENU-IDENTIQUE' > "$F44_06_CIBLE"
ln -s "$F44_06_CIBLE" "$F44_06_LIEN"
F44_06_AIDE_PY="$WORK/f44-06-aide.py"
cat > "$F44_06_AIDE_PY" <<'PY_F44_06_AIDE_EOF'
import importlib.util
import os
import sys

chemin_module, cible, lien, contenu = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
spec = importlib.util.spec_from_file_location("moteur_extrait", chemin_module)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

# Simule l'instant d'un TOCTOU : le contrôle de régularité a déjà eu lieu et a répondu « régulier »
# (c'est ce que `est_fichier_regulier` rendrait si `chemin` était encore le fichier régulier
# original, avant sa substitution par le lien) — seule la LECTURE qui suit est sous test réel.
m.est_fichier_regulier = lambda c: True

resultat = m.ecrire_si_different(lien, contenu)
print("RESULTAT=" + str(resultat))
print("CIBLE=" + open(cible, encoding="utf-8").read())
print("LIEN-EST-LIEN=" + str(os.path.islink(lien)))
PY_F44_06_AIDE_EOF
F44_06_OUT="$("$PYBIN" "$F44_06_AIDE_PY" "$MOTEUR_EXTRAIT_PY" "$F44_06_CIBLE" "$F44_06_LIEN" "CONTENU-IDENTIQUE" 2>&1)"
if echo "$F44_06_OUT" | grep -q "^RESULTAT=True$" \
   && echo "$F44_06_OUT" | grep -q "^CIBLE=CONTENU-IDENTIQUE$" \
   && echo "$F44_06_OUT" | grep -q "^LIEN-EST-LIEN=False$"; then
  ok "F44-06 ecrire_si_different sur un lien (TOCTOU simulé) : O_NOFOLLOW empêche la lecture à travers le lien, réécrit, cible intacte"
else
  ko "F44-06 ecrire_si_different sur un lien" "RESULTAT=True, CIBLE=CONTENU-IDENTIQUE, LIEN-EST-LIEN=False" "$F44_06_OUT" "-"
fi
if make_recalc_mutant F44-06-NOFOLLOW \
  'descripteur_existant = os.open(chemin, os.O_RDONLY | SANS_SUIVI_DE_LIEN)' \
  'descripteur_existant = os.open(chemin, os.O_RDONLY)  # MUT-F44-06-NOFOLLOW'
then
  MR="$MUT_DIR/recalc-planning.sh"
  MUT_F44_06_BODY_BRUT="$WORK/mut-f44-06-corps-brut.py"
  MUT_F44_06_BODY="$WORK/mut-f44-06-corps.py"
  awk '/<<.PY_RECALC_PLANNING_EOF.$/{f=1;next} /^PY_RECALC_PLANNING_EOF$/{f=0} f' "$MR" > "$MUT_F44_06_BODY_BRUT"
  # `main()` retiré, même motif que MUT-F5-JETON-VIDE ci-dessus.
  "$PYBIN" -c '
import sys
lignes = open(sys.argv[1], encoding="utf-8").read().split("\n")
while lignes and lignes[-1].strip() == "":
    lignes.pop()
if lignes and lignes[-1].strip() == "main()":
    lignes.pop()
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(lignes))
' "$MUT_F44_06_BODY_BRUT" "$MUT_F44_06_BODY"
  F44_06_MUT_OUT="$("$PYBIN" "$F44_06_AIDE_PY" "$MUT_F44_06_BODY" "$F44_06_CIBLE" "$F44_06_LIEN" "CONTENU-IDENTIQUE" 2>&1)"
  if echo "$F44_06_MUT_OUT" | grep -q "^RESULTAT=True$"; then
    komut F44-06-NOFOLLOW "RESULTAT sur lien (TOCTOU simulé)" "False (original, suit le lien)" "True (mutant non opposable)"
  else
    okmut F44-06-NOFOLLOW "RESULTAT sur lien (TOCTOU simulé) · attendu (original, O_NOFOLLOW) : True · obtenu (mutant, open() nu, suit le lien) : $F44_06_MUT_OUT"
  fi
fi

# ---------- R-INJECTIF-ROUNDTRIP — deux exécutions successives, valeur formellement « collidante »
# sous l'ancien encodage ("3 4" puis "3_4" au MÊME chemin de phase) : DEUX lignes, jamais absorbée
# par le dédoublonnage (P44-D-11 — une clôture réellement nouvelle ne doit jamais manquer).
R_INJ_DIR="$WORK/r-injectif-roundtrip"
materialiser traceur "$R_INJ_DIR"
VERDICT_CIBLE="$R_INJ_DIR/.planning/cycles/01-traceur/phases/01-livree/VERDICT.md"
printf -- '---\njuge: relecteur-banc\nhash: {{sha256-plan}}\nhash_livrables: {{empreinte-livrables}}\ntentative: "3 4"\nconstats:\n  - resultat: passé\n---\n' > "$VERDICT_CIBLE"
jetons "$R_INJ_DIR"
( cd "$R_INJ_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r-injectif-err1.txt" )
R_INJ_RC1=$?
printf -- '---\njuge: relecteur-banc\nhash: {{sha256-plan}}\nhash_livrables: {{empreinte-livrables}}\ntentative: "3_4"\nconstats:\n  - resultat: passé\n---\n' > "$VERDICT_CIBLE"
jetons "$R_INJ_DIR"
( cd "$R_INJ_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-injectif-out2.json" 2>"$WORK/r-injectif-err2.txt" )
R_INJ_RC2=$?
NB_LIGNES_CLOTURE="$(grep -c "01-livree" "$R_INJ_DIR/.planning/cloture.log")"
AJOUTS_INJ2="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cloture_ajouts"])' "$WORK/r-injectif-out2.json" 2>/dev/null || echo '?')"
if [ "$R_INJ_RC1" -eq 0 ] && [ "$R_INJ_RC2" -eq 0 ]; then
  ok "R-INJECTIF-ROUNDTRIP deux exécutions réelles réussies (rc=0 chacune)"
else
  ko "R-INJECTIF-ROUNDTRIP code" "0 et 0" "$R_INJ_RC1 et $R_INJ_RC2" "$(cat "$WORK/r-injectif-err1.txt") $(cat "$WORK/r-injectif-err2.txt")"
fi
if [ "$NB_LIGNES_CLOTURE" = "2" ]; then
  ok "R-INJECTIF-ROUNDTRIP deux lignes distinctes journalisées (« 3 4 » puis « 3_4 », collidantes sous l'ancien encodage)"
else
  ko "R-INJECTIF-ROUNDTRIP lignes pour 01-livree" "2" "$NB_LIGNES_CLOTURE" "$(cat "$R_INJ_DIR/.planning/cloture.log")"
fi
if [ "$AJOUTS_INJ2" = "1" ]; then
  ok "R-INJECTIF-ROUNDTRIP cloture_ajouts=1 au 2e recalcul (valeur réellement nouvelle, pas absorbée par le dédoublonnage)"
else
  ko "R-INJECTIF-ROUNDTRIP cloture_ajouts" "1" "$AJOUTS_INJ2" "$(cat "$WORK/r-injectif-out2.json")"
fi

# ================================================================================================
# Lot 3 (correction ciblée, décision du head sous délégation technique de Willy, session
# principale, 2026-09-28) — deux constats d'une revue et d'un audit frais, chacun avec un vrai
# aller-retour d'exécution (jamais un appel de fonction isolé) et son mutant.
# ================================================================================================

# ---------- R-DEDOUBLONNAGE-ASSAINI — le dédoublonnage compare la valeur ASSAINIE, pas la brute --
# Reproduction exacte de la revue (260928-b4c-VERIFICATION.md, truth #10, jamais éprouvée par un
# aller-retour réel) : une `tentative` piégée contenant espaces ET `=` rejournalise à CHAQUE
# exécution tant que la comparaison porte sur la valeur brute d'un côté et le jeton assaini
# relu dans le fichier de l'autre.
R_DEDASSAINI_DIR="$WORK/r-dedoublonnage-assaini"
materialiser traceur "$R_DEDASSAINI_DIR"
printf -- '---\njuge: relecteur-banc\nhash: {{sha256-plan}}\nhash_livrables: {{empreinte-livrables}}\ntentative: "1  FORGED-RECORD  verdict=close  tentative=99  date=observation"\nconstats:\n  - resultat: passé\n---\n' \
  > "$R_DEDASSAINI_DIR/.planning/cycles/01-traceur/phases/01-livree/VERDICT.md"
jetons "$R_DEDASSAINI_DIR"
( cd "$R_DEDASSAINI_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r-dedassaini-err1.txt" )
R_DEDASSAINI_RC1=$?
LIGNES_APRES_1="$(wc -l < "$R_DEDASSAINI_DIR/.planning/cloture.log" | tr -d ' ')"
( cd "$R_DEDASSAINI_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-dedassaini-out2.json" 2>"$WORK/r-dedassaini-err2.txt" )
R_DEDASSAINI_RC2=$?
LIGNES_APRES_2="$(wc -l < "$R_DEDASSAINI_DIR/.planning/cloture.log" | tr -d ' ')"
AJOUTS_DEDASSAINI="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cloture_ajouts"])' "$WORK/r-dedassaini-out2.json" 2>/dev/null || echo '?')"
if [ "$R_DEDASSAINI_RC1" -eq 0 ] && [ "$R_DEDASSAINI_RC2" -eq 0 ]; then
  ok "R-DEDOUBLONNAGE-ASSAINI deux exécutions réelles réussies (rc=0 chacune)"
else
  ko "R-DEDOUBLONNAGE-ASSAINI code" "0 et 0" "$R_DEDASSAINI_RC1 et $R_DEDASSAINI_RC2" "err1=$(cat "$WORK/r-dedassaini-err1.txt") err2=$(cat "$WORK/r-dedassaini-err2.txt")"
fi
if [ "$LIGNES_APRES_1" = "1" ] && [ "$LIGNES_APRES_2" = "1" ]; then
  ok "R-DEDOUBLONNAGE-ASSAINI une seule ligne dans cloture.log après le 2e recalcul (valeur piégée espaces+=)"
else
  ko "R-DEDOUBLONNAGE-ASSAINI lignes cloture.log" "1 puis 1" "$LIGNES_APRES_1 puis $LIGNES_APRES_2" "$(cat "$R_DEDASSAINI_DIR/.planning/cloture.log")"
fi
if [ "$AJOUTS_DEDASSAINI" = "0" ]; then
  ok "R-DEDOUBLONNAGE-ASSAINI cloture_ajouts=0 au 2e recalcul"
else
  ko "R-DEDOUBLONNAGE-ASSAINI cloture_ajouts" "0" "$AJOUTS_DEDASSAINI" "$(cat "$WORK/r-dedassaini-out2.json")"
fi

# ---------- MUT-DEDOUBLONNAGE-BRUT — comparaison assainie repliée sur la valeur brute ------------
if make_recalc_mutant DEDOUBLONNAGE-BRUT \
  'couple_jeton = (_jeton_journal(verdict, "-"), _jeton_journal(tentative, "-"))' \
  'couple_jeton = (verdict, tentative)  # MUT-DEDOUBLONNAGE-BRUT'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-dedoublonnage-brut-cas"
  materialiser traceur "$DIR_CAS"
  printf -- '---\njuge: relecteur-banc\nhash: {{sha256-plan}}\nhash_livrables: {{empreinte-livrables}}\ntentative: "1  FORGED-RECORD  verdict=close  tentative=99  date=observation"\nconstats:\n  - resultat: passé\n---\n' \
    > "$DIR_CAS/.planning/cycles/01-traceur/phases/01-livree/VERDICT.md"
  jetons "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>"$WORK/mut-dedoublonnage-brut-err1.txt" )
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-dedoublonnage-brut-out2.txt" 2>"$WORK/mut-dedoublonnage-brut-err2.txt" ); RC_M=$?
  if ! _verifier_plantage DEDOUBLONNAGE-BRUT "cloture_ajouts du second recalcul (valeur piégée espaces+=)" "$WORK/mut-dedoublonnage-brut-out2.txt" "$WORK/mut-dedoublonnage-brut-err2.txt" "$RC_M"; then
    AJOUTS_M="$("$PYBIN" -c 'import json,sys; print(json.load(open(sys.argv[1]))["cloture_ajouts"])' "$WORK/mut-dedoublonnage-brut-out2.txt" 2>/dev/null || echo '?')"
    if [ "$AJOUTS_M" = "0" ]; then
      komut DEDOUBLONNAGE-BRUT "cloture_ajouts du second recalcul" "0 (original)" "0 (mutant non opposable)"
    else
      okmut DEDOUBLONNAGE-BRUT "cloture_ajouts du second recalcul · attendu (original) : 0 · obtenu (mutant, comparaison repliée sur la valeur brute) : $AJOUTS_M (ligne dupliquée)"
    fi
  fi
fi

# ---------- R-GSD-HOME-SIGNAL — le refus « migration à examiner » tient quel que soit GSD_HOME ---
# Reproduction exacte de l'audit : socle planning-core (STATE.md `planning_version`, sans
# `gsd_state_version`) + signal de code (`package.json`). (a) environnement normal : refus. (b)
# GSD_HOME pointant vers un chemin inexistant (le détecteur sort en code 1 AVANT sa priorité 3) :
# refus IDENTIQUE — jamais une écriture au seul motif que la chaîne GSD est absente.
R_GHS_A_DIR="$WORK/r-gsd-home-signal-a"
materialiser traceur "$R_GHS_A_DIR"
printf -- '---\nplanning_version: "2.0"\n---\n' > "$R_GHS_A_DIR/.planning/STATE.md"
printf '%s' '{}' > "$R_GHS_A_DIR/package.json"
EMPREINTE_GHS_A_AVANT="$WORK/r-ghs-a-avant.txt"; empreinte "$R_GHS_A_DIR" > "$EMPREINTE_GHS_A_AVANT"
( cd "$R_GHS_A_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-ghs-a-out.txt" 2>"$WORK/r-ghs-a-err.txt" )
R_GHS_A_RC=$?
EMPREINTE_GHS_A_APRES="$WORK/r-ghs-a-apres.txt"; empreinte "$R_GHS_A_DIR" > "$EMPREINTE_GHS_A_APRES"
if [ "$R_GHS_A_RC" -eq 0 ]; then
  ok "R-GSD-HOME-SIGNAL (a) environnement normal : code de sortie 0 (adhésion + migration, GATE-14)"
else
  ko "R-GSD-HOME-SIGNAL (a) code" "0" "$R_GHS_A_RC" "$(cat "$WORK/r-ghs-a-out.txt")"
fi
if ! cmp -s "$EMPREINTE_GHS_A_AVANT" "$EMPREINTE_GHS_A_APRES"; then
  ok "R-GSD-HOME-SIGNAL (a) empreinte modifiée (écriture sous adhésion + migration)"
else
  ko "R-GSD-HOME-SIGNAL (a) empreinte" "modifiée (écriture)" "identique" "-"
fi

R_GHS_B_DIR="$WORK/r-gsd-home-signal-b"
materialiser traceur "$R_GHS_B_DIR"
printf -- '---\nplanning_version: "2.0"\n---\n' > "$R_GHS_B_DIR/.planning/STATE.md"
printf '%s' '{}' > "$R_GHS_B_DIR/package.json"
EMPREINTE_GHS_B_AVANT="$WORK/r-ghs-b-avant.txt"; empreinte "$R_GHS_B_DIR" > "$EMPREINTE_GHS_B_AVANT"
( cd "$R_GHS_B_DIR" && GSD_HOME="$R13_GSD_HOME_INEXISTANT" bash "$RECALC" >"$WORK/r-ghs-b-out.txt" 2>"$WORK/r-ghs-b-err.txt" )
R_GHS_B_RC=$?
EMPREINTE_GHS_B_APRES="$WORK/r-ghs-b-apres.txt"; empreinte "$R_GHS_B_DIR" > "$EMPREINTE_GHS_B_APRES"
if [ "$R_GHS_B_RC" -eq "$R_GHS_A_RC" ] && [ "$R_GHS_B_RC" -eq 0 ]; then
  ok "R-GSD-HOME-SIGNAL (b) GSD_HOME inexistant : code de sortie 0, IDENTIQUE à (a) — le verdict ne dépend pas de GSD_HOME (GATE-14)"
else
  ko "R-GSD-HOME-SIGNAL (b) code" "0, identique à (a)=$R_GHS_A_RC" "$R_GHS_B_RC" "$(cat "$WORK/r-ghs-b-out.txt")"
fi
if ! cmp -s "$EMPREINTE_GHS_B_AVANT" "$EMPREINTE_GHS_B_APRES"; then
  ok "R-GSD-HOME-SIGNAL (b) empreinte modifiée, comme (a) (écriture sous adhésion + migration)"
else
  ko "R-GSD-HOME-SIGNAL (b) empreinte" "modifiée (écriture)" "identique" "-"
fi

# ================================================================================================
# Gardes du harnais lui-même (patron test-check-skills.sh l.1268-1291) : MUT-SYNTAXE,
# MUT-REFUS-COMPTE, MUT-PLANTAGE.
# ================================================================================================

# ---------- MUT-SYNTAXE — mutant Python invalide rejeté par l'aide -------------------------------
MUT_SYNTAXE_FILE="$WORK/mut-syntaxe-out.txt"
( make_recalc_mutant SYNTAXE 'return "gsd"  # motif-code-0' 'return (indefini_a_dessein('; echo "RC-HELPER=$?" ) > "$MUT_SYNTAXE_FILE" 2>&1
if grep -q "^RC-HELPER=1$" "$MUT_SYNTAXE_FILE" && grep -q "NON TUÉ" "$MUT_SYNTAXE_FILE"; then
  ok "MUT-SYNTAXE refusé : mutant Python invalide rejeté par make_recalc_mutant"
else
  ko "MUT-SYNTAXE" "RC-HELPER=1 et trace NON TUÉ" "$(tr '\n' ' ' < "$MUT_SYNTAXE_FILE")" "-"
fi

# ---------- MUT-REFUS-COMPTE — un refus de l'aide compte KO dans le shell appelant ---------------
MUT_REFUS_FILE="$WORK/mut-refus-compte-out.txt"
(
  BEFORE=$fail
  make_recalc_mutant REFUS "motif-absent-du-fichier-recalc-planning-XYZZY-jamais-present" "quelquechose"
  RC=$?
  AFTER=$fail
  echo "DELTA-FAIL=$((AFTER - BEFORE))"
  echo "RC-HELPER=$RC"
) > "$MUT_REFUS_FILE" 2>&1
if grep -q "^DELTA-FAIL=1$" "$MUT_REFUS_FILE" && grep -q "^RC-HELPER=1$" "$MUT_REFUS_FILE" && grep -q "NON TUÉ" "$MUT_REFUS_FILE"; then
  ok "MUT-REFUS-COMPTE : refus de make_recalc_mutant compté KO dans le shell appelant"
else
  ko "MUT-REFUS-COMPTE" "DELTA-FAIL=1, RC-HELPER=1, trace NON TUÉ" "$(tr '\n' ' ' < "$MUT_REFUS_FILE")" "-"
fi

# ---------- MUT-PLANTAGE — le mécanisme lui-même applique le prédicat de mort explicite -----------
# Cible la MÊME ligne que MUT-ADHESION dans verifier_adhesion (comparaison de chaîne SANS
# try/except) — jamais une ligne de detection_gsd, dont le sous-processus est encadré d'un
# try/except qui avalerait l'exception. Sortie COMPLÈTE (y compris toute ligne « NON TUÉ —
# PLANTAGE » que komut imprimerait) redirigée vers un fichier de travail, JAMAIS vers la sortie
# réelle de la suite — celle-ci ne reçoit qu'une ligne de succès séparée, sans jamais la
# sous-chaîne « NON TUÉ ».
MUT_PLANTAGE_FILE="$WORK/mut-plantage-out.txt"
(
  if make_recalc_mutant PLANTAGE \
    'resultat["adherente"] = isinstance(resultat["declaree"], str) and resultat["declaree"] == SCHEMA_ADHESION' \
    'resultat["adherente"] = isinstance(resultat["declaree"], str) and resultat["declaree"] == nom_indefini_pour_plantage'
  then
    MR="$MUT_DIR/recalc-planning.sh"
    DIR_CAS="$WORK/mut-plantage-cas"
    materialiser traceur "$DIR_CAS"
    printf '%s' '{"planning_version": "2.0"}' > "$DIR_CAS/.planning/config.json"
    ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-plantage-cas-out.txt" 2>"$WORK/mut-plantage-cas-err.txt" )
    RC_PLANTAGE=$?
    _verifier_plantage PLANTAGE "code/traceback du mutant délibérément cassé (cas R05 2.0)" \
      "$WORK/mut-plantage-cas-out.txt" "$WORK/mut-plantage-cas-err.txt" "$RC_PLANTAGE" \
      || echo "HARNAIS-DEFAILLANT : aucun plantage détecté (rc=$RC_PLANTAGE)"
  fi
) > "$MUT_PLANTAGE_FILE" 2>&1
if grep -q "NON TUÉ" "$MUT_PLANTAGE_FILE" && grep -q "PLANTAGE" "$MUT_PLANTAGE_FILE" && ! grep -q "HARNAIS-DEFAILLANT" "$MUT_PLANTAGE_FILE"; then
  ok "MUT-PLANTAGE : plantage reconnu par le mécanisme, jamais compté TUÉ"
else
  ko "MUT-PLANTAGE" "trace NON TUÉ + PLANTAGE capturée, jamais HARNAIS-DEFAILLANT" "$(tr '\n' ' ' < "$MUT_PLANTAGE_FILE")" "-"
fi

# ---------- Hygiène : le script réel n'a jamais été modifié (une seule fois, en fin de bloc) ------
if cmp -s "$RECALC" "$RECALC_SNAPSHOT"; then
  ok "Hygiène mutation : recalc-planning.sh réel intact après tous les mutants"
else
  ko "Hygiène mutation" "script réel intact" "script réel MODIFIÉ" "-"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
