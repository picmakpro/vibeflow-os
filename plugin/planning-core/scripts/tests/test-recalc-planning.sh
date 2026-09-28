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
if make_recalc_mutant GSD-FERME 'return "non-concluante"  # motif-detecteur-irregulier' 'return "non-gsd"  # MUT-GSD-FERME'; then
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
  'if dernier_couple.get(chemin) != (verdict, tentative):' \
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
if make_recalc_mutant NOFOLLOW 'SANS_SUIVI_DE_LIEN = getattr(os, "O_NOFOLLOW", 0)' 'SANS_SUIVI_DE_LIEN = 0  # MUT-NOFOLLOW'; then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-nofollow-cas"
  materialiser traceur "$DIR_CAS"
  rm -f "$DIR_CAS/.planning/cloture.log"
  CIBLE="$WORK/mut-nofollow-cible.log"
  printf 'contenu-original\n' > "$CIBLE"
  ln -s "$CIBLE" "$DIR_CAS/.planning/cloture.log"
  ( cd "$DIR_CAS" && GSD_HOME="$FAKE_GSD" bash "$MR" >"$WORK/mut-nofollow-out.txt" 2>"$WORK/mut-nofollow-err.txt" ); RC_M=$?
  if ! _verifier_plantage NOFOLLOW "code de sortie et cible du lien de R11" "$WORK/mut-nofollow-out.txt" "$WORK/mut-nofollow-err.txt" "$RC_M"; then
    if [ "$RC_M" -eq 1 ] && printf 'contenu-original\n' | cmp -s - "$CIBLE"; then
      komut NOFOLLOW "code de sortie et cible du lien de R11" "code 1, cible inchangée (original)" "code 1, cible inchangée (mutant non opposable)"
    else
      okmut NOFOLLOW "code de sortie et cible du lien de R11 · attendu (original) : code 1, cible inchangée · obtenu (mutant) : code $RC_M, cible $( printf 'contenu-original\n' | cmp -s - "$CIBLE" && echo inchangée || echo modifiée )"
    fi
  fi
fi

# ---------- MUT-CHAINE-ABSENTE — lecture indépendante de STATE.md racine neutralisée -------------
if make_recalc_mutant CHAINE-ABSENTE \
  'if _porte_marqueur_gsd(os.path.join(planning_abs, "STATE.md")):' \
  'if False:  # MUT-CHAINE-ABSENTE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-chaine-absente-cas"
  materialiser traceur "$DIR_CAS"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$DIR_CAS/.planning/STATE.md"
  ( cd "$DIR_CAS" && GSD_HOME="$R13_GSD_HOME_INEXISTANT" bash "$MR" >"$WORK/mut-chaine-absente-out.txt" 2>"$WORK/mut-chaine-absente-err.txt" ); RC_M=$?
  if ! _verifier_plantage CHAINE-ABSENTE "code de sortie de R13 (a)" "$WORK/mut-chaine-absente-out.txt" "$WORK/mut-chaine-absente-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut CHAINE-ABSENTE "code de sortie de R13 (a) · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture malgré chaîne GSD absente de la machine)"
    else
      komut CHAINE-ABSENTE "code de sortie de R13 (a)" "3" "$RC_M (mutant non opposable)"
    fi
  fi
fi

# ---------- MUT-PARTITION-ABSENTE — énumération des compartiments neutralisée --------------------
if make_recalc_mutant PARTITION-ABSENTE \
  'compartiments = _lister_compartiments(planning_abs)' \
  'compartiments = []  # MUT-PARTITION-ABSENTE'
then
  MR="$MUT_DIR/recalc-planning.sh"
  DIR_CAS="$WORK/mut-partition-absente-cas"
  materialiser traceur "$DIR_CAS"
  mkdir -p "$DIR_CAS/.planning/workstreams/gouvernance-banc"
  printf -- '---\ngsd_state_version: 1.0\n---\n' > "$DIR_CAS/.planning/workstreams/gouvernance-banc/STATE.md"
  ( cd "$DIR_CAS" && GSD_HOME="$R13_GSD_HOME_INEXISTANT" bash "$MR" >"$WORK/mut-partition-absente-out.txt" 2>"$WORK/mut-partition-absente-err.txt" ); RC_M=$?
  if ! _verifier_plantage PARTITION-ABSENTE "code de sortie de R13 (c)" "$WORK/mut-partition-absente-out.txt" "$WORK/mut-partition-absente-err.txt" "$RC_M"; then
    if [ "$RC_M" -ne 3 ]; then
      okmut PARTITION-ABSENTE "code de sortie de R13 (c) · attendu (original) : 3 · obtenu (mutant) : $RC_M (écriture sur un planning GSD partitionné malgré la chaîne GSD absente)"
    else
      komut PARTITION-ABSENTE "code de sortie de R13 (c)" "3" "$RC_M (mutant non opposable)"
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
