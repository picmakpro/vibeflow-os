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
#   R-GSD-HOME-SIGNAL — (a) environnement normal et (b) GSD_HOME inexistant sur un socle
#         planning-core + signal de code : refus IDENTIQUE (code 3) dans les deux cas, empreinte
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
        attendus = materialiser(banc_path, nom, dest)
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


ETATS_ONZE = (
    "à cadrer", "en cadrage", "à planifier", "à exécuter", "à juger", "à corriger",
    "close", "indéterminé", "abandonné", "remplacé", "gelé",
)


def couverture(banc_path):
    """R20 : pour chacun des onze états, un lab non jumeau porte un `@@ attendu` à cet état sur
    une unité U ET un lab `jumeau-de=` ce lab porte un `@@ attendu` sur la MÊME unité U à un état
    différent."""
    texte = open(banc_path, encoding="utf-8").read()
    ordre, labs = parser_banc(texte)
    tout_ok = True
    for etat in ETATS_ONZE:
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
  MODE=$(stat -f "%Lp" "$R14_DIR/.planning/$f" 2>/dev/null || stat -c "%a" "$R14_DIR/.planning/$f" 2>/dev/null)
  R14_MODES="$R14_MODES $f=$MODE"
  [ "$MODE" = "644" ] || R14_OK=0
done
if [ "$R14_OK" -eq 1 ]; then
  ok "R14 INDEX.md/STATE.md/cloture.log en 0o644 sous umask 0077"
else
  ko "R14 permissions" "644 chacun" "$R14_MODES" "-"
fi

# ---------- R20 — contrôle de couverture (onze états, positif + jumeau, P44-D-06/D-17) ----------
R20_OUT="$WORK/r20-out.txt"
"$PYBIN" "$AIDES_PY" couverture "$BANC" > "$R20_OUT" 2>&1
R20_RC=$?
cat "$R20_OUT"
if [ "$R20_RC" -eq 0 ] && [ "$(grep -c '^COUVERTURE ' "$R20_OUT")" -eq 11 ]; then
  ok "R20 couverture : onze états couverts, chacun par un positif et un jumeau"
else
  ko "R20 couverture" "code 0, onze lignes COUVERTURE" "code=$R20_RC, $(grep -c '^COUVERTURE ' "$R20_OUT") ligne(s)" "$(grep '✗' "$R20_OUT" | head -1)"
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
materialiser etat-a-corriger-jumeau "$R27A_DIR"
( cd "$R27A_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r27a-err.txt" )
R27B_DIR="$WORK/r27b"
materialiser d08-summary-sans-plan "$R27B_DIR"
( cd "$R27B_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r27b-err.txt" )
if grep -qF 'verdict passé, SUMMARY absent' "$R27A_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R27 INDEX.md (etat-a-corriger-jumeau) contient « verdict passé, SUMMARY absent »"
else
  ko "R27 INDEX.md libellé A" "verdict passé, SUMMARY absent" "$(cat "$R27A_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
if grep -qF 'SUMMARY.md sans PLAN.md' "$R27B_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R27 INDEX.md (d08-summary-sans-plan) contient « SUMMARY.md sans PLAN.md »"
else
  ko "R27 INDEX.md libellé B" "SUMMARY.md sans PLAN.md" "$(cat "$R27B_DIR/.planning/INDEX.md" 2>/dev/null)" "-"
fi
if ! grep -qF 'verdict passé, SUMMARY absent' "$R27B_DIR/.planning/INDEX.md" 2>/dev/null \
   && ! grep -qF 'SUMMARY.md sans PLAN.md' "$R27A_DIR/.planning/INDEX.md" 2>/dev/null; then
  ok "R27 les deux libellés sont distincts (jamais le même générique)"
else
  ko "R27 distinction des libellés" "les deux libellés diffèrent" "chevauchement détecté" "-"
fi
if grep -qF 'verdict passé, SUMMARY absent' "$R27A_DIR/.planning/STATE.md" 2>/dev/null; then
  ok "R27 STATE.md (etat-a-corriger-jumeau) porte le libellé lisible de phase-indeterminee:01-p"
else
  ko "R27 STATE.md libellé" "verdict passé, SUMMARY absent" "$(cat "$R27A_DIR/.planning/STATE.md" 2>/dev/null)" "-"
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
    MODE_INDEX=$(stat -f "%Lp" "$DIR_CAS/.planning/INDEX.md" 2>/dev/null || stat -c "%a" "$DIR_CAS/.planning/INDEX.md" 2>/dev/null)
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
    MODE_CLOTURE=$(stat -f "%Lp" "$DIR_CAS/.planning/cloture.log" 2>/dev/null || stat -c "%a" "$DIR_CAS/.planning/cloture.log" 2>/dev/null)
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
  'manquant = next((v for v in valeurs if not os.path.lexists(os.path.join(racine_lab, v))), None)' \
  'manquant = None  # MUT-LIVRABLES'
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
  'if livrables_actuels == livrables_cache:' \
  'if True:  # MUT-LIVRABLES-CACHE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-livrables-cache-cas"
  materialiser traceur "$DIR_CAS"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >/dev/null 2>&1 )
  rm -f "$DIR_CAS/livrables/rapport.md"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-livrables-cache-out.json" 2>"$WORK/mut-livrables-cache-err.txt" ); RC_M=$?
  if ! _verifier_plantage LIVRABLES-CACHE "état de la phase de R58 après suppression du livrable" "$WORK/mut-livrables-cache-out.json" "$WORK/mut-livrables-cache-err.txt" "$RC_M"; then
    if grep -qF 'livrable absent : livrables/rapport.md' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null; then
      komut LIVRABLES-CACHE "état de la phase de R58 après suppression du livrable" "indéterminé, livrable-absent (original)" "indéterminé, livrable-absent (mutant non opposable)"
    else
      okmut LIVRABLES-CACHE "état de la phase de R58 après suppression du livrable · attendu (original) : indéterminé (livrable-absent:livrables/rapport.md) · obtenu (mutant) : $(grep 'cycles/01-traceur' "$DIR_CAS/.planning/INDEX.md" 2>/dev/null) (l'état repris du cache reste close malgré le livrable manquant)"
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
import os
import sys

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
    3) code_attendu=0 ;;
    0|2) code_attendu=3 ;;
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
matrice_env socle-signal setup_socle_signal 3

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
  if [ "$rc" -eq 3 ]; then
    ok "R-LABS-ADVERSES [$label] code de sortie 3"
  else
    ko "R-LABS-ADVERSES [$label] code" "3" "$rc" "$(cat "$WORK/adverse-$label-out.txt")"
  fi
  if cmp -s "$WORK/adverse-$label-state-avant.md" "$dir/.planning/STATE.md"; then
    ok "R-LABS-ADVERSES [$label] STATE.md (marqueur planning_version) inchangé octet pour octet"
  else
    ko "R-LABS-ADVERSES [$label] STATE.md" "octets inchangés" "modifié" "-"
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
# ================================================================================================

# ---------- R-CODE2-MIGRATION — régression de l'audit B : code 2 refuse désormais l'écriture ----
R_C2M_DIR="$WORK/r-code2-migration"
materialiser traceur "$R_C2M_DIR"
printf -- '---\nplanning_version: "2.0"\n---\n' > "$R_C2M_DIR/.planning/STATE.md"
printf '%s' '{}' > "$R_C2M_DIR/package.json"
empreinte "$R_C2M_DIR" > "$WORK/r-code2-migration-avant.txt"
( cd "$R_C2M_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >"$WORK/r-code2-migration-out.txt" 2>"$WORK/r-code2-migration-err.txt" )
R_C2M_RC=$?
empreinte "$R_C2M_DIR" > "$WORK/r-code2-migration-apres.txt"
if [ "$R_C2M_RC" -eq 3 ]; then
  ok "R-CODE2-MIGRATION code de sortie 3 (régression audit B : code 2 ne s'écrit plus comme le code 3)"
else
  ko "R-CODE2-MIGRATION code" "3" "$R_C2M_RC" "$(cat "$WORK/r-code2-migration-out.txt")"
fi
if grep -qF "P44-D-02a" "$WORK/r-code2-migration-err.txt" 2>/dev/null; then
  ok "R-CODE2-MIGRATION message de refus P44-D-02a sur stderr"
else
  ko "R-CODE2-MIGRATION stderr" "mentionne P44-D-02a" "$(cat "$WORK/r-code2-migration-err.txt")" "-"
fi
if cmp -s "$WORK/r-code2-migration-avant.txt" "$WORK/r-code2-migration-apres.txt"; then
  ok "R-CODE2-MIGRATION empreinte de .planning/ identique avant/après"
else
  ko "R-CODE2-MIGRATION empreinte" "identique" "diverge" "-"
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

# ---------- MUT-CODE2-MIGRATION — code 2 (migration) changé en écriture autorisée -----------------
if make_recalc_mutant CODE2-MIGRATION 'return "non-concluante"  # motif-code-2-migration' 'return "non-gsd"  # MUT-CODE2-MIGRATION'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-code2-migration-cas"
  materialiser traceur "$DIR_CAS"
  printf -- '---\nplanning_version: "2.0"\n---\n' > "$DIR_CAS/.planning/STATE.md"
  printf '%s' '{}' > "$DIR_CAS/package.json"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-code2-migration-out.txt" 2>"$WORK/mut-code2-migration-err.txt" ); RC_M=$?
  if ! _verifier_plantage CODE2-MIGRATION "code de sortie (socle planning-core + signal de code — audit B)" "$WORK/mut-code2-migration-out.txt" "$WORK/mut-code2-migration-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut CODE2-MIGRATION "code de sortie · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture malgré un signalement de migration — régression de l'audit B)"
    else
      komut CODE2-MIGRATION "code de sortie" "3" "$RC_M (mutant non opposable)"
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
printf -- '---\njuge: relecteur-banc\nhash: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd\ntentative: "3 4"\nconstats:\n  - resultat: passé\n---\n' > "$VERDICT_CIBLE"
( cd "$R_INJ_DIR" && GSD_HOME="$FAKE_GSD" bash "$RECALC" >/dev/null 2>"$WORK/r-injectif-err1.txt" )
R_INJ_RC1=$?
printf -- '---\njuge: relecteur-banc\nhash: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd\ntentative: "3_4"\nconstats:\n  - resultat: passé\n---\n' > "$VERDICT_CIBLE"
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
printf -- '---\njuge: relecteur-banc\nhash: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd\ntentative: "1  FORGED-RECORD  verdict=close  tentative=99  date=observation"\nconstats:\n  - resultat: passé\n---\n' \
  > "$R_DEDASSAINI_DIR/.planning/cycles/01-traceur/phases/01-livree/VERDICT.md"
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
  printf -- '---\njuge: relecteur-banc\nhash: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd\ntentative: "1  FORGED-RECORD  verdict=close  tentative=99  date=observation"\nconstats:\n  - resultat: passé\n---\n' \
    > "$DIR_CAS/.planning/cycles/01-traceur/phases/01-livree/VERDICT.md"
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
if [ "$R_GHS_A_RC" -eq 3 ]; then
  ok "R-GSD-HOME-SIGNAL (a) environnement normal : code de sortie 3"
else
  ko "R-GSD-HOME-SIGNAL (a) code" "3" "$R_GHS_A_RC" "$(cat "$WORK/r-ghs-a-out.txt")"
fi
if cmp -s "$EMPREINTE_GHS_A_AVANT" "$EMPREINTE_GHS_A_APRES"; then
  ok "R-GSD-HOME-SIGNAL (a) empreinte identique"
else
  ko "R-GSD-HOME-SIGNAL (a) empreinte" "identique" "diverge" "-"
fi

R_GHS_B_DIR="$WORK/r-gsd-home-signal-b"
materialiser traceur "$R_GHS_B_DIR"
printf -- '---\nplanning_version: "2.0"\n---\n' > "$R_GHS_B_DIR/.planning/STATE.md"
printf '%s' '{}' > "$R_GHS_B_DIR/package.json"
EMPREINTE_GHS_B_AVANT="$WORK/r-ghs-b-avant.txt"; empreinte "$R_GHS_B_DIR" > "$EMPREINTE_GHS_B_AVANT"
( cd "$R_GHS_B_DIR" && GSD_HOME="$R13_GSD_HOME_INEXISTANT" bash "$RECALC" >"$WORK/r-ghs-b-out.txt" 2>"$WORK/r-ghs-b-err.txt" )
R_GHS_B_RC=$?
EMPREINTE_GHS_B_APRES="$WORK/r-ghs-b-apres.txt"; empreinte "$R_GHS_B_DIR" > "$EMPREINTE_GHS_B_APRES"
if [ "$R_GHS_B_RC" -eq 3 ]; then
  ok "R-GSD-HOME-SIGNAL (b) GSD_HOME inexistant : code de sortie 3 (régression de l'audit : était 0)"
else
  ko "R-GSD-HOME-SIGNAL (b) code" "3" "$R_GHS_B_RC" "$(cat "$WORK/r-ghs-b-out.txt")"
fi
if cmp -s "$EMPREINTE_GHS_B_AVANT" "$EMPREINTE_GHS_B_APRES"; then
  ok "R-GSD-HOME-SIGNAL (b) empreinte identique (STATE.md non écrasé)"
else
  ko "R-GSD-HOME-SIGNAL (b) empreinte" "identique" "diverge (STATE.md aurait été écrasé)" "-"
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
