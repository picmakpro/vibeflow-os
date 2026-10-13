#!/usr/bin/env bash
# test-verifier-releve.sh — la suite du script de décision d'armement `verifier-releve.sh` : un relevé de rejeu se juge par
# un code de sortie, chaque règle du script a son cas négatif et son mutant (Phase 46.1, 46.1-03 ; ARMG-04 ; P461-D-06).
#
# Familles :
#   R-RELEVE-01  un relevé synthétique conforme (deux labs, étapes 5 et 6) est armable : code 0, dernière ligne `RELEVE-VERDICT armable …`
#   R-RELEVE-02  l'usage : sans --etape, --etape hors 5/6, option inconnue, aucun relevé ou deux relevés → code 64, aucune ligne RELEVE-VERDICT
#   R-RELEVE-03  UNE table (CAS_NEGATIFS : règle → cas) jouée par une boucle : chaque cas rend le code 1 et SA ligne `RELEVE-ECART <règle> : …`
#                et une dernière ligne `RELEVE-VERDICT non-armable …`
#   MUT-RELEVE-<RÈGLE>  un mutant par marqueur `# releve-<règle>` lu dans le script (la ligne `if …:` devient `if False:`), GÉNÉRÉ par une boucle :
#                le cas négatif de la règle ne rend plus SA ligne (et, pour un cas « seul », le code 0), le cas positif reste vert sous le mutant.
#                La trace est imprimée : assertion · attendu (original) · obtenu (mutant). Un marqueur sans cas dans la table est un `  ✗ `.
#
# Le script jugé est lu à côté de la suite (../verifier-releve.sh) ; hors dépôt (script absent) la suite l'écrit et rend `0 OK · 0 KO`, jamais un vert.
# La preuve que la table couvre chaque marqueur, la chaîne réelle sur lab synthétique et le corpus réel de la 46 sont le plan 46.1-18.
# Portable GNU/BSD (P45-D-16) : ni `stat -f/-c`, ni `sed -i`, ni `timeout`, ni `readlink -f` ; `cmp -s` jamais `diff`. Lançable depuis tout cwd, par
# `bash <suite>` (jamais sourcée). Piège CI : jamais `commande && { … }` nu.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"

PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*)
    if command -v python >/dev/null 2>&1; then PYBIN=python
    else echo "[test-verifier-releve] python3 requis" >&2; exit 1; fi
    ;;
esac

if [ ! -f "$SCRIPTS_DIR/verifier-releve.sh" ]; then
  echo "NOTE hors dépôt : verifier-releve.sh absent à côté de la suite — script de décision non rejoué (jamais un vert)"
  echo "== Résultat : 0 OK · 0 KO =="
  exit 0
fi

pass=0; fail=0
ko() {
  echo "  ✗ $1"
  echo "    assertion : $2"
  echo "    attendu   : $3"
  echo "    obtenu    : $4"
  fail=$((fail+1))
}

WORK="$(mktemp -d)"
trap 'chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT
T_DEBUT="$(date +%s)"

AIDES="$WORK/aides.py"
cat > "$AIDES" <<'PY_AIDES_VERIFIER_RELEVE_EOF'
import os
import re
import subprocess
import sys

SCRIPT = None
WORK = None
BORNE_RELEVE = 64 * 1024 * 1024
MARQUEUR_RE = re.compile(r"^\s*if .*:  # releve-([a-z-]+)$")
TERMINATEUR = "PY_VERIFIER_RELEVE_EOF"
COMMIT = "0123456789abcdef" * 2 + "01234567"  # 40 hex

LAB_A, LAB_1 = "~/lab-a", "<lab-1>"


def ok(libelle, detail=""):
    print("  ✓ %s%s" % (libelle, (" — " + detail) if detail else ""))


def ko(libelle, assertion, attendu, obtenu):
    print("  ✗ " + libelle)
    print("    assertion : " + assertion)
    print("    attendu   : " + attendu)
    print("    obtenu    : " + obtenu)


def okmut(ident, trace):
    print("  ✓ MUT-%s TUÉ — %s" % (ident, trace))


def komut(ident, assertion, attendu, obtenu):
    print("  ✗ MUT-%s NON TUÉ" % ident)
    print("    assertion : " + assertion)
    print("    attendu (original) : " + attendu)
    print("    obtenu (mutant)    : " + obtenu)


def court(texte, n=160):
    texte = " ".join(str(texte).split())
    return texte if len(texte) <= n else texte[: n - 3] + "..."


# ---------------------------------------------------------------------------------------------------------------------
# Lancement et lecture de la sortie
# ---------------------------------------------------------------------------------------------------------------------
def lancer(script, args):
    p = subprocess.run(["bash", script] + list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=WORK, timeout=120)
    return p.returncode, p.stdout.decode("utf-8", "replace"), p.stderr.decode("utf-8", "replace")


def ecarts_de(sortie):
    return [m.group(1) for m in (re.match(r"^RELEVE-ECART (\S+) : ", l) for l in sortie.split("\n")) if m]


def derniere(sortie):
    lignes = [l for l in sortie.split("\n") if l != ""]
    return lignes[-1] if lignes else ""


def verdicts_de(sortie):
    return [l for l in sortie.split("\n") if l.startswith("RELEVE-VERDICT ")]


# ---------------------------------------------------------------------------------------------------------------------
# Le constructeur de relevé synthétique : lignes paramétrables, opérations nommées
# ---------------------------------------------------------------------------------------------------------------------
def base(etape):
    lignes = ["# Relevé synthétique de rejeu (suite test-verifier-releve.sh)", "COMMIT-REJOUE " + COMMIT]
    gates = ["G3", "G4"] + (["G4P"] if etape == 6 else [])
    for lab in (LAB_A, LAB_1):
        for gate in gates:
            lignes.append("%s | %s | .planning/cycles/01-c/phases/01-p/SUMMARY.md | doit-passer | passe | passe" % (gate, lab))
    for gate in gates:
        lignes.append("COMPTE %s faux-refus=0 faux-accept=0 refus-conforme-modele=0" % gate)
    lignes.append("REJEU-ETAPE-%d faux-refus=0 faux-accept=0 refus-conforme-modele=196" % etape)
    lignes.append("COUVERTURE-REJEU G3 n=52 plancher=12")
    lignes.append("COUVERTURE-REJEU G4 n=44 plancher=12")
    if etape == 6:
        lignes.append("COUVERTURE-REJEU G4P n=96 plancher=8")
    lignes += ["EMPREINTE-IDENTIQUE " + LAB_A, "EMPREINTE-IDENTIQUE " + LAB_1]  # forme de rejeu-gates.sh, jamais lue
    lignes += ["EMPREINTE-ARBRE-IDENTIQUE " + LAB_A, "EMPREINTE-ARBRE-IDENTIQUE " + LAB_1]
    return lignes


def _index_unique(lignes, prefixe):
    idx = [i for i, l in enumerate(lignes) if l.startswith(prefixe)]
    if len(idx) != 1:
        raise AssertionError("le préfixe %r doit désigner UNE ligne de la base, trouvé %d" % (prefixe, len(idx)))
    return idx[0]


def appliquer(lignes, ops):
    lignes = list(lignes)
    for op in ops:
        genre = op[0]
        if genre == "sans":
            n = len(lignes)
            lignes = [l for l in lignes if not l.startswith(op[1])]
            if len(lignes) == n:
                raise AssertionError("sans %r : aucune ligne" % op[1])
        elif genre == "remplace":
            lignes[_index_unique(lignes, op[1])] = op[2]
        elif genre == "ajoute":
            lignes.append(op[1])
        elif genre == "double":
            i = _index_unique(lignes, op[1])
            lignes.insert(i + 1, lignes[i])
        elif genre == "crlf":
            i = _index_unique(lignes, op[1])
            lignes[i] = lignes[i] + "\r"
        else:
            raise AssertionError("opération inconnue : " + genre)
    return lignes


def ecrire_releve(nom, lignes):
    chemin = os.path.join(WORK, "cas", nom)
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "wb") as fh:
        fh.write(("\n".join(lignes) + "\n").encode("utf-8"))
    return chemin


def ecrire_octets(nom, octets):
    chemin = os.path.join(WORK, "cas", nom)
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "wb") as fh:
        fh.write(octets)
    return chemin


_compteur = [0]


def fabriquer(cas):
    """Arguments (liste) d'un cas : (args, None) ou (None, raison de non-exerçabilité)."""
    _compteur[0] += 1
    nom = "cas-%03d.txt" % _compteur[0]
    etape = cas.get("etape", 5)
    special = cas.get("special")
    if special is None:
        chemin = ecrire_releve(nom, appliquer(base(etape), cas.get("ops", ())))
    elif special == "absent":
        chemin = os.path.join(WORK, "cas", "n-existe-pas-%03d.txt" % _compteur[0])
    elif special == "zero":
        chemin = ecrire_octets(nom, b"")
    elif special == "blancs":
        chemin = ecrire_octets(nom, b"  \n\t \n\n   \n")
    elif special == "utf8":
        chemin = ecrire_octets(nom, ("\n".join(base(etape)) + "\n").encode("utf-8") + b"\xff\xfe\n")
    elif special == "lien":
        cible = ecrire_releve("cible-" + nom, base(etape))
        chemin = os.path.join(WORK, "cas", "lien-" + nom)
        os.symlink(cible, chemin)
    elif special == "dossier":
        chemin = os.path.join(WORK, "cas", "dossier-%03d" % _compteur[0])
        os.makedirs(chemin, exist_ok=True)
    elif special == "fifo":
        chemin = os.path.join(WORK, "cas", "fifo-%03d" % _compteur[0])
        try:
            os.makedirs(os.path.dirname(chemin), exist_ok=True)
            os.mkfifo(chemin)
        except (AttributeError, OSError) as exc:
            return None, "mkfifo indisponible (%s)" % type(exc).__name__
    elif special == "borne":
        chemin = os.path.join(WORK, "cas", "borne-%03d.txt" % _compteur[0])
        try:
            os.makedirs(os.path.dirname(chemin), exist_ok=True)
            with open(chemin, "wb") as fh:
                fh.truncate(BORNE_RELEVE + 1)
        except OSError as exc:
            return None, "fichier creux de 64 Mio + 1 octet impossible (%s)" % type(exc).__name__
    else:
        raise AssertionError("cas spécial inconnu : " + special)
    return ["--etape=%d" % etape] + list(cas.get("args", ())) + [chemin], None


# ---------------------------------------------------------------------------------------------------------------------
# La table des cas négatifs : règle → cas. `seule` : le cas ne déclenche que cette règle, donc sous le mutant le code doit devenir 0.
# ---------------------------------------------------------------------------------------------------------------------
REFUS_UN = "REJEU-ETAPE-5 faux-refus=1 faux-accept=0 refus-conforme-modele=196"
ACCEPT_UN = "REJEU-ETAPE-5 faux-refus=0 faux-accept=1 refus-conforme-modele=196"

CAS_NEGATIFS = {
    "lecture": [
        {"nom": "relevé absent", "special": "absent"},
        {"nom": "relevé en lien", "special": "lien"},
        {"nom": "relevé qui est un dossier", "special": "dossier"},
        {"nom": "relevé qui est un tube", "special": "fifo"},
        {"nom": "relevé de 64 Mio + 1 octet", "special": "borne"},
        {"nom": "relevé hors UTF-8", "special": "utf8"},
    ],
    "vide": [
        {"nom": "relevé de 0 octet", "special": "zero"},
        {"nom": "relevé réduit à des blancs", "special": "blancs"},
    ],
    "etape-absente": [
        {"nom": "aucune ligne REJEU-ETAPE-5", "ops": [("sans", "REJEU-ETAPE-5 ")], "seule": True},
    ],
    "faux-refus": [
        {"nom": "faux-refus=1", "ops": [("remplace", "REJEU-ETAPE-5 ", REFUS_UN)], "seule": True},
    ],
    "faux-accept": [
        {"nom": "faux-accept=1", "ops": [("remplace", "REJEU-ETAPE-5 ", ACCEPT_UN)], "seule": True},
    ],
}


# ---------------------------------------------------------------------------------------------------------------------
# Les contrôles
# ---------------------------------------------------------------------------------------------------------------------
def positif(script, etape, args=()):
    """(rc, sortie) du relevé conforme de l'étape sous `script`."""
    chemin = ecrire_releve("positif-%d-%d.txt" % (etape, _compteur[0]), base(etape))
    _compteur[0] += 1
    rc, out, err = lancer(script, ["--etape=%d" % etape] + list(args) + [chemin])
    return rc, out + err


def controle_01():
    attendu = {5: "RELEVE-VERDICT armable etape=5 labs=2 gates=G3,G4", 6: "RELEVE-VERDICT armable etape=6 labs=2 gates=G3,G4,G4P"}
    for etape in (5, 6):
        rc, sortie = positif(SCRIPT, etape)
        if rc == 0 and derniere(sortie) == attendu[etape] and not ecarts_de(sortie):
            ok("R-RELEVE-01 étape %d : le relevé conforme est armable" % etape, "code 0, " + attendu[etape])
        else:
            ko("R-RELEVE-01 étape %d" % etape, "un relevé synthétique conforme (deux labs) est armable", "code 0, dernière ligne « %s », aucun écart" % attendu[etape],
               "code %d, dernière ligne « %s », écarts %s" % (rc, court(derniere(sortie)), ecarts_de(sortie)))


def controle_02():
    chemin = ecrire_releve("usage.txt", base(5))
    chemin_bis = ecrire_releve("usage-bis.txt", base(5))
    cas = [
        ("sans --etape", [chemin]),
        ("--etape=4", ["--etape=4", chemin]),
        ("--etape=7", ["--etape=7", chemin]),
        ("--etape=abc", ["--etape=abc", chemin]),
        ("--etape= vide", ["--etape=", chemin]),
        ("--etape donné deux fois", ["--etape=5", "--etape=5", chemin]),
        ("--etape sans valeur", ["--etape", "5", chemin]),
        ("option inconnue", ["--etape=5", "--inconnue", chemin]),
        ("--lab= vide", ["--etape=5", "--lab=", chemin]),
        ("aucun relevé", ["--etape=5"]),
        ("deux relevés", ["--etape=5", chemin, chemin_bis]),
        ("relevé donné par l'entrée standard (-)", ["--etape=5", "-"]),
    ]
    for nom, args in cas:
        rc, out, err = lancer(SCRIPT, args)
        if rc == 64 and not verdicts_de(out + err) and out == "":
            ok("R-RELEVE-02 usage : %s → code 64" % nom)
        else:
            ko("R-RELEVE-02 usage : %s" % nom, "un usage invalide rend 64 sans aucune ligne RELEVE-VERDICT", "code 64, sortie standard vide, aucune ligne RELEVE-VERDICT",
               "code %d, %d ligne(s) RELEVE-VERDICT, sortie standard %s" % (rc, len(verdicts_de(out + err)), court(out, 60)))


def controle_03():
    for regle, cas_regle in CAS_NEGATIFS.items():
        for cas in cas_regle:
            args, raison = fabriquer(cas)
            if args is None:
                print("  ~ R-RELEVE-03 %s : %s — non exerçable ici (%s), ni vert ni rouge" % (regle, cas["nom"], raison))
                continue
            rc, out, err = lancer(SCRIPT, args)
            sortie = out + err
            vus = ecarts_de(sortie)
            if rc == 1 and regle in vus and derniere(sortie).startswith("RELEVE-VERDICT non-armable ") and len(verdicts_de(sortie)) == 1:
                ok("R-RELEVE-03 %s rougit : %s" % (regle, cas["nom"]), "code 1, RELEVE-ECART %s" % regle)
            else:
                ko("R-RELEVE-03 %s : %s" % (regle, cas["nom"]), "le cas négatif de la règle %s est refusé pour SA raison" % regle,
                   "code 1, une ligne RELEVE-ECART %s, dernière ligne RELEVE-VERDICT non-armable" % regle,
                   "code %d, écarts %s, dernière ligne « %s »" % (rc, vus, court(derniere(sortie))))


# ---------------------------------------------------------------------------------------------------------------------
# Les mutants du script
# ---------------------------------------------------------------------------------------------------------------------
def corps_python(source):
    lignes = source.split("\n")
    debut = [i for i, l in enumerate(lignes) if l.rstrip().endswith("<<'%s'" % TERMINATEUR)]
    fin = [i for i, l in enumerate(lignes) if l == TERMINATEUR]
    if len(debut) != 1 or len(fin) != 1:
        return None
    return "\n".join(lignes[debut[0] + 1: fin[0]]) + "\n"


def make_mutant(ident, selecteur, nouvelle):
    """(chemin du mutant, None) ou (None, raison) : l'UNIQUE ligne retenue par `selecteur` est remplacée (indentation conservée) ; `bash -n` et la
    compilation du corps Python doivent passer."""
    original = open(SCRIPT, encoding="utf-8").read()
    lignes = original.split("\n")
    idx = [i for i, l in enumerate(lignes) if selecteur(l)]
    if len(idx) != 1:
        return None, "MOTIF AMBIGU OU ABSENT (lignes=%d)" % len(idx)
    ligne = lignes[idx[0]]
    lignes[idx[0]] = ligne[: len(ligne) - len(ligne.lstrip())] + nouvelle
    mute = "\n".join(lignes)
    if mute == original:
        return None, "NON OPPOSABLE (identique)"
    dossier = os.path.join(WORK, "mut", ident.lower())
    os.makedirs(dossier, exist_ok=True)
    chemin = os.path.join(dossier, "verifier-releve.sh")
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(mute)
    p = subprocess.run(["bash", "-n", chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None, "bash -n ÉCHOUE : " + court(p.stderr.decode("utf-8", "replace"))
    corps = corps_python(mute)
    if corps is None:
        return None, "corps Python introuvable"
    try:
        compile(corps, "<mutant %s>" % ident, "exec")
    except SyntaxError as exc:
        return None, "le corps Python ne compile pas : %s" % exc
    return chemin, None


def decrire(rc, sortie, regle):
    vus = ecarts_de(sortie)
    if rc == 0:
        return "code 0, %s" % court(derniere(sortie), 80)
    return "code %d, aucune ligne RELEVE-ECART %s (écarts restants : %s)" % (rc, regle, ", ".join(vus) if vus else "aucun")


def executer_mutant_regle(regle, marqueurs):
    ident = "RELEVE-" + regle.upper()
    cas_regle = CAS_NEGATIFS.get(regle)
    if not cas_regle:
        print("  ✗ MUT-%s sans cas négatif dans CAS_NEGATIFS" % ident)
        print("    assertion : chaque marqueur # releve-%s a un cas négatif dans la table" % regle)
        print("    attendu   : au moins un cas pour la règle %s" % regle)
        print("    obtenu    : aucun")
        return
    motif = "# releve-" + regle
    chemin, raison = make_mutant(ident, lambda l: l.rstrip().endswith(":  " + motif) and l.lstrip().startswith("if "), "if False:  " + motif)
    if chemin is None:
        komut(ident, "le mutant de la règle %s se construit" % regle, "UNE ligne `if …:  %s` neutralisée" % motif, raison)
        return
    assertion = "R-RELEVE-03 %s rougit" % regle
    premiere = None
    exerces = 0
    for cas in cas_regle:
        args, _ = fabriquer(cas)
        if args is None:
            continue
        exerces += 1
        rc_o, out_o, err_o = lancer(SCRIPT, args)
        rc_m, out_m, err_m = lancer(chemin, args)
        so, sm = out_o + err_o, out_m + err_m
        if not (rc_o == 1 and regle in ecarts_de(so)):
            komut(ident, assertion + " (original) : " + cas["nom"], "code 1, RELEVE-ECART %s" % regle, "l'original lui-même ne rougit pas : code %d, écarts %s" % (rc_o, ecarts_de(so)))
            return
        if regle in ecarts_de(sm):
            komut(ident, assertion + " : " + cas["nom"], "code 1, RELEVE-ECART %s" % regle, "le mutant rend encore la ligne : " + decrire(rc_m, sm, regle))
            return
        if cas.get("seule") and not (rc_m == 0 and derniere(sm).startswith("RELEVE-VERDICT armable ")):
            komut(ident, assertion + " (cas seul) : " + cas["nom"], "code 1, RELEVE-ECART %s" % regle, "le mutant devait laisser armer : " + decrire(rc_m, sm, regle))
            return
        if premiere is None:
            premiere = decrire(rc_m, sm, regle)
    if exerces == 0:
        komut(ident, assertion, "au moins un cas exerçable", "aucun cas exerçable ici")
        return
    for etape in (5, 6):
        rc_p, sortie_p = positif(chemin, etape)
        if not (rc_p == 0 and derniere(sortie_p).startswith("RELEVE-VERDICT armable ")):
            komut(ident, "mutant valide : le relevé conforme de l'étape %d reste armable sous le mutant" % etape, "code 0, RELEVE-VERDICT armable",
                  "code %d, dernière ligne « %s »" % (rc_p, court(derniere(sortie_p))))
            return
    okmut(ident, "%s · attendu (original) : code 1, RELEVE-ECART %s · obtenu (mutant) : %s" % (assertion, regle, premiere))


def sec_mutants():
    source = open(SCRIPT, encoding="utf-8").read()
    marqueurs = [m.group(1) for m in (MARQUEUR_RE.match(l) for l in source.split("\n")) if m]
    for regle in marqueurs:
        executer_mutant_regle(regle, marqueurs)
    for regle in CAS_NEGATIFS:
        if regle not in marqueurs:
            print("  ✗ R-RELEVE-03 %s : cas sans marqueur" % regle)
            print("    assertion : chaque cas de la table vise un marqueur # releve-<règle> du script")
            print("    attendu   : un marqueur # releve-%s" % regle)
            print("    obtenu    : aucun")


def main():
    global SCRIPT, WORK
    SCRIPT, WORK = sys.argv[1], sys.argv[2]
    controle_01()
    controle_02()
    controle_03()
    sec_mutants()


main()
PY_AIDES_VERIFIER_RELEVE_EOF

out="$WORK/sortie-verifier-releve.txt"
"$PYBIN" "$AIDES" "$SCRIPTS_DIR/verifier-releve.sh" "$WORK" > "$out" 2>&1
rc=$?
while IFS= read -r line; do
  printf '%s\n' "$line"
  case "$line" in
    "  ✓ "*) pass=$((pass+1)) ;;
    "  ✗ "*) fail=$((fail+1)) ;;
  esac
done < "$out"
if [ "$rc" -ne 0 ] && ! grep -q '^  ✗ ' "$out"; then
  ko "aides Python" "les aides Python se terminent sans erreur" "code 0" "code $rc (voir la sortie ci-dessus)"
fi

T_FIN="$(date +%s)"
echo "DUREE s=$((T_FIN - T_DEBUT))"
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
