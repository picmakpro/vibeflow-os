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
#   MUT-DEDOUBLONNAGE, MUT-NOFOLLOW, MUT-CHAINE-ABSENTE, MUT-PARTITION-ABSENTE, MUT-CHMOD,
#   MUT-CHMOD-JOURNAL — chacun mute une ligne à motif unique de recalc-planning.sh, chacun prouvé
#   par une trace assertion/attendu (original)/obtenu (mutant).
#   MUT-SYNTAXE, MUT-REFUS-COMPTE, MUT-PLANTAGE — gardes du harnais lui-même (patron
#   test-check-skills.sh).
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
            labs[lab_courant]["fichiers"][fichier_courant] = "".join(l + "\n" for l in contenu_courant)

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
                nom = reste.split()[0]
                labs[nom] = {"fichiers": {}, "dossiers": [], "attendus": []}
                ordre_labs.append(nom)
                lab_courant = nom
            elif directive.startswith("dossier "):
                chemin = directive[len("dossier "):].strip()
                _valider_chemin_banc(chemin)
                labs[lab_courant]["dossiers"].append(chemin)
            elif directive.startswith("fichier "):
                chemin = directive[len("fichier "):].strip()
                _valider_chemin_banc(chemin)
                fichier_courant = chemin
                contenu_courant = []
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
    sys.exit(0 if tout_ok else 1)


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

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
