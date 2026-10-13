#!/usr/bin/env bash
# test-verifier-releve.sh — la suite du script de décision d'armement `verifier-releve.sh` : un relevé de rejeu se juge par
# un code de sortie, chaque règle du script a son cas négatif et son mutant (Phase 46.1, 46.1-03 ; ARMG-04 ; P461-D-06).
#
# Familles :
#   R-RELEVE-01  un relevé synthétique conforme (deux labs, étapes 5 et 6) est armable : code 0, dernière ligne `RELEVE-VERDICT armable …`
#   R-RELEVE-02  l'usage : sans --etape, --etape hors 5/6, option inconnue, aucun relevé ou deux relevés → code 64, aucune ligne RELEVE-VERDICT
#   R-RELEVE-03  UNE table (CAS_NEGATIFS : règle → cas) jouée par une boucle : chaque cas rend le code 1 et SA ligne `RELEVE-ECART <règle> : …`
#                et une dernière ligne `RELEVE-VERDICT non-armable …`
#   R-RELEVE-04  les bords : n = plancher armable (jumeau de n = plancher - 1), un faux-refus=343 avec une section « Non armé » refusé, seul
#                EMPREINTE-IDENTIQUE (périmètre restreint) = empreinte-absente, lignes RELEVE-VERDICT / RELEVE-ECART reproduites inertes, lignes COMPTE
#                lues pour recouper REJEU-ETAPE (une ligne COMPTE à 343 faux refus non reportée dans REJEU-ETAPE = etape-recoupement ; gate `-` : faux-accept
#                seul ; gate inconnue `?` comptée ; gate d'une étape ultérieure non comptée), gate non visé ignoré, labs (union des --lab et des lignes de table),
#                CRLF, chemins relatifs nommés home ou Users armables, `COMPTE RENDU.md` armable, sortie déterministe sans la ligne fautive, aucun sous-processus
#                ni écriture
#   MUT-RELEVE-<RÈGLE>  un mutant par marqueur `# releve-<règle>` lu dans le script (la ligne `if …:` devient `if False:`), GÉNÉRÉ par une boucle :
#                le cas négatif de la règle ne rend plus SA ligne (et, pour un cas « seul », le code 0), le cas positif reste vert sous le mutant.
#                La trace est imprimée : assertion · attendu (original) · obtenu (mutant). Un marqueur sans cas dans la table est un `  ✗ `.
#   MUT-RELEVE-TOUJOURS-ARMABLE (verdict final forcé à armable : R-RELEVE-03 rougit) et MUT-RELEVE-TOUJOURS-REFUS (forcé à non armable : R-RELEVE-01 rougit)
#   Les chemins de machine que la suite fabrique pour la règle chemin-machine sont des PLACEHOLDERS (`/Users/dev/…`, `/home/runner/…`) admis par
#   scripts/check-machine-paths.sh : la règle du script les refuse quand même, et la suite versionnée ne porte aucun vrai chemin.
#
#   R-RELEVE-CHAINE  (46.1-18, P461-D-06, P461-D-07) la VRAIE chaîne sur un lab synthétique construit par la suite : rejeu-reel.sh (donc rejeu-gates.sh)
#                étape 5, étape 6 avec un agent producteur doté de Bash, étape 6 sans aucun agent → relevé → verifier-releve.sh. Étapes 5 et 6 avec agent :
#                armables ; étape 6 sans agent : `RELEVE-ECART couverture-insuffisante` sur G4P. Chacun des trois relevés est ensuite COMPOSÉ au format des
#                relevés de la phase (REPOS-AVANT/REPOS-APRES, COMMIT-REJOUE, « ## Sortie brute du rejeu », « ## Décision mécanique » qui reproduit la sortie
#                du script ; pour le non-armable, « ## Non armé — remonté à Willy » et ESCALADE-WILLY) et le script, rejoué sur le fichier final, rend le même
#                code et une dernière ligne identique (les lignes reproduites sont inertes). Un écart révélé se corrige dans le lecteur, jamais dans un attendu.
#                VF_RELEVE_CHAINE_DEPOT (lue SEULEMENT par R-RELEVE-CHAINE, jamais pour décider d'un cas) : si elle désigne un dossier ABSOLU EXISTANT, les trois
#                relevés composés y sont copiés sous chaine-etape-5.md, chaine-etape-6.md, chaine-etape-6-sans-agent.md — `46.1-CONTROLES.sh releve-chaine` les
#                passe au contrôle de cohérence de la phase. Variable absente, vide ou relative : rien n'est écrit hors du mktemp de la suite.
#   R-RELEVE-07  (fix-5b V4 (b)) la copie d'`ORDRE_ETAPES` du vérificateur est identique à celle de rejeu-gates.sh (ast.literal_eval des deux lignes) ; la confrontation voit une copie
#                perturbée (G4 déplacée dans le dernier lot) ; mutant MUT-RELEVE-ORDRE
#   R-RELEVE-08  (fix-5b V4 (a)) point fixe : pour chaque cas texte de la table, la SORTIE du script ne porte aucun jeton de la grammaire, et relevé + `## Décision mécanique` + sa sortie
#                redonne le même code, la même dernière ligne et les mêmes écarts ; mutant MUT-RELEVE-SORTIE-JETON
#   Mutants dédiés (hors marqueurs, fix-5b) : MUT-RELEVE-ENTIER-BORNE (V1), MUT-RELEVE-MACHINE-SOUS-CHAINE (V2), MUT-RELEVE-SORTIE-JETON (V4 (a)), MUT-RELEVE-ORDRE et
#                MUT-RELEVE-RECOUPEMENT-FA-EGAL (V4 (b))
#   R-RELEVE-05  (46.1-18) les deux relevés RÉELS de la Phase 46 (fixtures/releve-46-etape-5.txt et -6.txt, extraites par lignes ciblées, chaque ligne
#                verbatim, jamais complétées) sont refusés : faux-refus=349 à l'étape 5 ; à l'étape 6 faux-refus=343 ET commit-absent, deux causes indépendantes
#                (ce relevé ne porte aucune ligne COMMIT-REJOUE, il ne cite son commit qu'en prose) ; `jeton-deplace` ne vise QUE la ligne 1 de chaque fixture (le commentaire d'extraction,
#                non verbatim) ; deux retouches du relevé de l'étape 5 construites sur son texte (audit-5b F-2) sont refusées : (a) ligne REJEU-ETAPE-5 décalée d'une espace + ligne propre
#                à 0 (etape-recoupement, jeton-deplace), (b) faux-refus=349 changé en 0 alors que COMPTE G4 faux-refus=343 reste (etape-recoupement)
#   R-RELEVE-06  (46.1-18) contrôle statique (ast) du cœur Python : ni subprocess ni shutil importés, ni os.system ni os.remove appelés, aucun fichier ouvert
#                en écriture ; l'analyseur est éprouvé sur des sources fautives (il ne rend pas un vert à vide)
#   R-RELEVE-COUVERTURE  (46.1-18) la suite lit les marqueurs `# releve-<règle>` du script et exige pour chacun un cas négatif dans CAS_NEGATIFS ET un
#                mutant joué et tué ; elle imprime `COUVERTURE-SUITE regles=<n> cas-negatifs=<n> mutants=<n>` (n calculés) ; une règle sans cas ou sans mutant
#                est un échec (`  ✗ R-RELEVE-COUVERTURE`), jamais un vert à vide
#
# Le script jugé est lu à côté de la suite (../verifier-releve.sh) ; hors dépôt (script absent) la suite l'écrit et rend `0 OK · 0 KO`, jamais un vert.
# La chaîne lit aussi rejeu-reel.sh et rejeu-gates.sh (à côté du script jugé) ; elle ne les modifie pas.
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
import ast
import os
import re
import subprocess
import sys

SCRIPT = None
WORK = None
FIXTURES = None
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


TUES = set()  # identifiants des mutants joués ET tués (R-RELEVE-COUVERTURE les compte)


def okmut(ident, trace):
    TUES.add(ident)
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
    # lignes COMPTE à la forme de l'émetteur : toutes les gates des étapes <= n, plus G4P suffixée ` hors-etape` à l'étape 5 ; le refus conforme au modèle (196) est celui de G1 ;
    # le total REJEU-ETAPE somme les gates de l'étape (faux-refus et refus-conforme-modele égaux à la somme, faux-accept au moins égal)
    for gate in ("G6", "G5", "G1", "G7", "ROLE", "G3", "G4", "G4P"):
        lignes.append("COMPTE %s faux-refus=0 faux-accept=0 refus-conforme-modele=%d%s" % (gate, 196 if gate == "G1" else 0, " hors-etape" if (gate == "G4P" and etape == 5) else ""))
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
AUTRE_ETAPE = "REJEU-ETAPE-6 faux-refus=0 faux-accept=0 refus-conforme-modele=0"
ID_A, ID_1 = "EMPREINTE-ARBRE-IDENTIQUE " + LAB_A, "EMPREINTE-ARBRE-IDENTIQUE " + LAB_1
COMPTE_FR_UN = ("remplace", "COMPTE G4 ", "COMPTE G4 faux-refus=1 faux-accept=0 refus-conforme-modele=0")
COMPTE_FA_UN = ("remplace", "COMPTE G4 ", "COMPTE G4 faux-refus=0 faux-accept=1 refus-conforme-modele=0")
GROS = "1" * 4301  # plus de chiffres que la limite de conversion de Python >= 3.11 (4 300) : int() lèverait (fix-5b V1)
# Les chemins de machine de la suite sont des PLACEHOLDERS admis par scripts/check-machine-paths.sh (compte `dev`, compte `runner`) :
# la règle du script les refuse quand même, et la suite versionnée ne porte aucun vrai chemin.
LIGNE_USERS = "NOTE rejeu lancé depuis /Users/dev/lab"
LIGNE_HOME = "NOTE rejeu lancé depuis /home/runner/work/lab"

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
    "etape-malformee": [
        {"nom": "ligne sans refus-conforme-modele, seule du relevé", "ops": [("remplace", "REJEU-ETAPE-5 ", "REJEU-ETAPE-5 faux-refus=0 faux-accept=0")]},
        {"nom": "ligne sans refus-conforme-modele, à côté d'une ligne conforme", "ops": [("ajoute", "REJEU-ETAPE-5 faux-refus=0 faux-accept=0")], "seule": True},
        {"nom": "ligne conforme suivie de \\r", "ops": [("crlf", "REJEU-ETAPE-5 ")]},
        {"nom": "faux-refus à 4 301 chiffres, à côté de la ligne conforme", "tue": ("entier-borne",), "ops": [("ajoute", "REJEU-ETAPE-5 faux-refus=%s faux-accept=0 refus-conforme-modele=196" % GROS)], "seule": True},
        {"nom": "numéro d'étape à 4 301 chiffres, à côté de la ligne conforme", "tue": ("entier-borne",), "ops": [("ajoute", "REJEU-ETAPE-%s faux-refus=0 faux-accept=0 refus-conforme-modele=196" % GROS)], "seule": True},
        {"nom": "faux-accept à 10 chiffres, à côté de la ligne conforme", "tue": ("entier-borne",), "ops": [("ajoute", "REJEU-ETAPE-5 faux-refus=0 faux-accept=1234567890 refus-conforme-modele=196")], "seule": True},
    ],
    "etape-doublon": [
        {"nom": "la ligne REJEU-ETAPE-5 en double", "ops": [("double", "REJEU-ETAPE-5 ")], "seule": True},
    ],
    "etape-autre": [
        {"nom": "une ligne REJEU-ETAPE-6 à côté de la ligne 5 (--etape=5)", "ops": [("ajoute", AUTRE_ETAPE)], "seule": True},
        {"nom": "la seule ligne est REJEU-ETAPE-6 (--etape=5)", "ops": [("remplace", "REJEU-ETAPE-5 ", AUTRE_ETAPE)]},
    ],
    "faux-refus": [
        {"nom": "faux-refus=1", "ops": [("remplace", "REJEU-ETAPE-5 ", REFUS_UN), COMPTE_FR_UN], "seule": True},
    ],
    "faux-accept": [
        {"nom": "faux-accept=1", "ops": [("remplace", "REJEU-ETAPE-5 ", ACCEPT_UN), COMPTE_FA_UN], "seule": True},
    ],
    "commit-absent": [
        {"nom": "aucune ligne COMMIT-REJOUE", "ops": [("sans", "COMMIT-REJOUE")], "seule": True},
    ],
    "commit-malforme": [
        {"nom": "COMMIT-REJOUE à 39 hex, seule du relevé", "ops": [("remplace", "COMMIT-REJOUE ", "COMMIT-REJOUE " + COMMIT[:39])]},
        {"nom": "COMMIT-REJOUE en majuscules, seule du relevé", "ops": [("remplace", "COMMIT-REJOUE ", "COMMIT-REJOUE " + COMMIT.upper())]},
        {"nom": "COMMIT-REJOUE à 41 hex, à côté d'une ligne conforme", "ops": [("ajoute", "COMMIT-REJOUE " + COMMIT + "0")], "seule": True},
        {"nom": "COMMIT-REJOUE conforme suivie de \\r", "ops": [("crlf", "COMMIT-REJOUE ")]},
    ],
    "commit-doublon": [
        {"nom": "la ligne COMMIT-REJOUE en double", "ops": [("double", "COMMIT-REJOUE ")], "seule": True},
    ],
    "labs-absents": [
        {"nom": "ni --lab ni ligne de table", "ops": [("sans", "G3 | "), ("sans", "G4 | ")], "seule": True},
    ],
    "empreinte-absente": [
        {"nom": "une seule empreinte pour deux labs", "ops": [("sans", ID_1)], "seule": True},
        {"nom": "un --lab sans ligne d'empreinte", "args": ["--lab=~/lab-z"], "seule": True},
        {"nom": "ligne EMPREINTE-ARBRE-IDENTIQUE sans lab, à côté des conformes", "ops": [("ajoute", "EMPREINTE-ARBRE-IDENTIQUE")], "seule": True},
        {"nom": "l'empreinte d'un lab suivie de \\r", "ops": [("crlf", ID_1)], "seule": True},
    ],
    "empreinte-doublon": [
        {"nom": "l'empreinte d'un lab en double", "ops": [("double", ID_A)], "seule": True},
    ],
    "empreinte-divergente": [
        {"nom": "une ligne DIVERGENTE à côté des IDENTIQUE", "ops": [("ajoute", "EMPREINTE-ARBRE-DIVERGENTE " + LAB_A)], "seule": True},
        {"nom": "l'empreinte d'un lab est DIVERGENTE", "ops": [("remplace", ID_1, "EMPREINTE-ARBRE-DIVERGENTE " + LAB_1)]},
    ],
    "rejeu-divergent": [
        {"nom": "une ligne EMPREINTE-DIVERGENTE (rejeu-gates.sh) à côté des conformes", "ops": [("ajoute", "EMPREINTE-DIVERGENTE " + LAB_A)], "seule": True},
        {"nom": "une ligne EMPREINTE-DIVERGENTE sans nom de lab", "ops": [("ajoute", "EMPREINTE-DIVERGENTE")], "seule": True},
    ],
    "jeton-deplace": [
        {"nom": "la ligne REJEU-ETAPE-5 conforme décalée d'une espace, à côté de l'originale (forme de l'attaque audit-5b F-2 (a))",
         "ops": [("ajoute", " REJEU-ETAPE-5 faux-refus=0 faux-accept=0 refus-conforme-modele=196")], "seule": True},
        {"nom": "COMMIT-REJOUE en commentaire", "ops": [("ajoute", "# COMMIT-REJOUE " + COMMIT)], "seule": True},
        {"nom": "COUVERTURE-REJEU entre guillemets français", "ops": [("ajoute", "\u00ab COUVERTURE-REJEU G4 n=44 plancher=12 \u00bb")], "seule": True},
        {"nom": "une ligne COMPTE indentée de deux espaces", "ops": [("ajoute", "  COMPTE G4 faux-refus=343 faux-accept=0 refus-conforme-modele=0")], "seule": True},
        {"nom": "EMPREINTE-ARBRE-IDENTIQUE précédé d'un préfixe", "ops": [("ajoute", "x-EMPREINTE-ARBRE-IDENTIQUE " + LAB_A)], "seule": True},
        {"nom": "MESURE-VIDE précédé d'une espace", "ops": [("ajoute", " MESURE-VIDE " + LAB_1)], "seule": True},
        {"nom": "EMPREINTE-DIVERGENTE précédé d'une espace", "ops": [("ajoute", " EMPREINTE-DIVERGENTE " + LAB_A)], "seule": True},
    ],
    "compte-malforme": [
        {"nom": "COMPTE G3 suffixée hors-etape alors que G3 est de l'étape 5, à côté de la conforme",
         "ops": [("ajoute", "COMPTE G3 faux-refus=0 faux-accept=0 refus-conforme-modele=0 hors-etape")], "seule": True},
        {"nom": "COMPTE G4 sans refus-conforme-modele, à côté de la conforme", "ops": [("ajoute", "COMPTE G4 faux-refus=0 faux-accept=0")], "seule": True},
        {"nom": "COMPTE G4P sans le suffixe hors-etape à l'étape 5 (G4P est de l'étape 6)",
         "ops": [("remplace", "COMPTE G4P ", "COMPTE G4P faux-refus=0 faux-accept=0 refus-conforme-modele=0")], "seule": True},
        {"nom": "COMPTE G4 à 4 301 chiffres, à côté de la conforme", "ops": [("ajoute", "COMPTE G4 faux-refus=%s faux-accept=0 refus-conforme-modele=0" % GROS)], "seule": True},
        {"nom": "COMPTE G3 conforme suivie de \\r", "ops": [("crlf", "COMPTE G3 ")]},
        {"nom": "COMPTE G4P suffixée hors-etape à l'étape 6 (G4P y est de l'étape)", "etape": 6,
         "ops": [("remplace", "COMPTE G4P ", "COMPTE G4P faux-refus=0 faux-accept=0 refus-conforme-modele=0 hors-etape")]},
    ],
    "compte-absent": [
        {"nom": "sans COMPTE G6 (gate de l'étape 1)", "ops": [("sans", "COMPTE G6 ")], "seule": True},
        {"nom": "sans COMPTE G4P à l'étape 6", "etape": 6, "ops": [("sans", "COMPTE G4P ")], "seule": True},
    ],
    "etape-recoupement": [
        {"nom": "COMPTE G4 à faux-refus=1 sous un REJEU-ETAPE à 0", "ops": [COMPTE_FR_UN], "seule": True},
        {"nom": "COMPTE G1 à refus-conforme-modele=195 sous un REJEU-ETAPE à 196",
         "ops": [("remplace", "COMPTE G1 ", "COMPTE G1 faux-refus=0 faux-accept=0 refus-conforme-modele=195")], "seule": True},
        {"nom": "COMPTE G4 à faux-accept=1 sous un REJEU-ETAPE à 0", "ops": [COMPTE_FA_UN], "seule": True},
        {"nom": "COMPTE G4P à faux-refus=1 sous un REJEU-ETAPE-6 à 0", "etape": 6,
         "ops": [("remplace", "COMPTE G4P ", "COMPTE G4P faux-refus=1 faux-accept=0 refus-conforme-modele=0")], "seule": True},
    ],
    "mesure-vide": [
        {"nom": "une ligne MESURE-VIDE", "ops": [("ajoute", "MESURE-VIDE " + LAB_1)], "seule": True},
    ],
    "couverture-absente": [
        {"nom": "G4 sans COUVERTURE-REJEU à l'étape 5", "ops": [("sans", "COUVERTURE-REJEU G4 ")], "seule": True},
        {"nom": "G4P sans COUVERTURE-REJEU à l'étape 6", "etape": 6, "ops": [("sans", "COUVERTURE-REJEU G4P ")], "seule": True},
    ],
    "couverture-malformee": [
        {"nom": "COUVERTURE-REJEU sans plancher, à côté des conformes", "ops": [("ajoute", "COUVERTURE-REJEU G4 n=44")], "seule": True},
        {"nom": "COUVERTURE-REJEU d'un gate inconnu, à côté des conformes", "ops": [("ajoute", "COUVERTURE-REJEU G9 n=1 plancher=1")], "seule": True},
        {"nom": "plancher=0, seule ligne de G4", "ops": [("remplace", "COUVERTURE-REJEU G4 ", "COUVERTURE-REJEU G4 n=44 plancher=0")]},
        {"nom": "COUVERTURE-REJEU conforme suivie de \\r", "ops": [("crlf", "COUVERTURE-REJEU G3 ")]},
        {"nom": "n à 4 301 chiffres, à côté des conformes", "ops": [("ajoute", "COUVERTURE-REJEU G4 n=%s plancher=12" % GROS)], "seule": True},
        {"nom": "plancher à 4 301 chiffres, à côté des conformes", "ops": [("ajoute", "COUVERTURE-REJEU G4 n=44 plancher=%s" % GROS)], "seule": True},
    ],
    "couverture-doublon": [
        {"nom": "la ligne COUVERTURE-REJEU G4 en double", "ops": [("double", "COUVERTURE-REJEU G4 ")], "seule": True},
    ],
    "couverture-insuffisante": [
        {"nom": "G4 n=11 sous plancher=12 (p-1)", "ops": [("remplace", "COUVERTURE-REJEU G4 ", "COUVERTURE-REJEU G4 n=11 plancher=12")], "seule": True},
        {"nom": "G4P n=0 sous plancher=8 à l'étape 6", "etape": 6, "ops": [("remplace", "COUVERTURE-REJEU G4P ", "COUVERTURE-REJEU G4P n=0 plancher=8")], "seule": True},
    ],
    "chemin-machine": [
        {"nom": "un chemin /Users/… dans une ligne", "ops": [("ajoute", LIGNE_USERS)], "seule": True, "interdit": ["/Users/dev", "dev/lab"]},
        {"nom": "un chemin /home/… dans une ligne", "ops": [("ajoute", LIGNE_HOME)], "seule": True, "interdit": ["/home/runner", "runner/work"]},
        {"nom": "un chemin /Users/… en URL file:///", "ops": [("ajoute", "NOTE voir file:///Users/dev/x")], "seule": True, "interdit": ["dev/x"]},
        {"nom": "un chemin /home/… après un signe égal", "ops": [("ajoute", "NOTE chemin=/home/runner/x")], "seule": True, "interdit": ["runner/x"]},
        {"nom": "un chemin /Users/… entre guillemets français", "ops": [("ajoute", "NOTE voir \u00ab/Users/dev/lab\u00bb")], "seule": True, "interdit": ["dev/lab"]},
        {"nom": "un chemin /home/… atteint par un détour /tmp/../", "ops": [("ajoute", "NOTE voir /tmp/../home/runner/x")], "seule": True, "interdit": ["runner/x"]},
        {"nom": "un chemin //home/… à deux barres de tête", "ops": [("ajoute", "NOTE voir //home/runner/x")], "seule": True, "interdit": ["runner/x"]},
        {"nom": "la racine /home seule, sans barre finale", "ops": [("ajoute", "NOTE voir /home")], "seule": True},
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


def cas_rouge(rc, sortie, regle, cas):
    """Vrai si le cas négatif est refusé pour SA raison : code 1, sa ligne RELEVE-ECART, une seule dernière ligne RELEVE-VERDICT non-armable, et
    jamais le chemin de machine ni la ligne fautive dans la sortie."""
    if not (rc == 1 and regle in ecarts_de(sortie) and derniere(sortie).startswith("RELEVE-VERDICT non-armable ") and len(verdicts_de(sortie)) == 1):
        return False
    return not any(motif in sortie for motif in cas.get("interdit", ()))


def controle_03():
    for regle, cas_regle in CAS_NEGATIFS.items():
        for cas in cas_regle:
            args, raison = fabriquer(cas)
            if args is None:
                print("  ~ R-RELEVE-03 %s : %s — non exerçable ici (%s), ni vert ni rouge" % (regle, cas["nom"], raison))
                continue
            rc, out, err = lancer(SCRIPT, args)
            sortie = out + err
            if cas_rouge(rc, sortie, regle, cas):
                ok("R-RELEVE-03 %s rougit : %s" % (regle, cas["nom"]), "code 1, RELEVE-ECART %s" % regle)
            else:
                ko("R-RELEVE-03 %s : %s" % (regle, cas["nom"]), "le cas négatif de la règle %s est refusé pour SA raison" % regle,
                   "code 1, une ligne RELEVE-ECART %s, dernière ligne RELEVE-VERDICT non-armable%s" % (regle, ", jamais %s dans la sortie" % cas["interdit"] if cas.get("interdit") else ""),
                   "code %d, écarts %s, dernière ligne « %s »" % (rc, ecarts_de(sortie), court(derniere(sortie))))


def lancer_releve(nom, lignes, etape=5, args=(), brut=None, cwd=None):
    """(rc, sortie) du script original sur un relevé fabriqué (lignes, ou octets bruts)."""
    chemin = ecrire_octets(nom, brut) if brut is not None else ecrire_releve(nom, lignes)
    p = subprocess.run(["bash", SCRIPT, "--etape=%d" % etape] + list(args) + [chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd or WORK, timeout=120)
    return p.returncode, (p.stdout + p.stderr).decode("utf-8", "replace")


def bord(nom, assertion, attendu, rc, sortie, conforme):
    if conforme:
        ok("R-RELEVE-04 " + nom, attendu)
    else:
        ko("R-RELEVE-04 " + nom, assertion, attendu, "code %d, écarts %s, dernière ligne « %s »" % (rc, ecarts_de(sortie), court(derniere(sortie))))


def armable(rc, sortie):
    return rc == 0 and derniere(sortie).startswith("RELEVE-VERDICT armable ") and not ecarts_de(sortie)


def refuse_pour(rc, sortie, *regles):
    return rc == 1 and derniere(sortie).startswith("RELEVE-VERDICT non-armable ") and all(r in ecarts_de(sortie) for r in regles)


def controle_04():
    # n = plancher : jumeau positif de n = plancher - 1 (couverture-insuffisante)
    rc, s = lancer_releve("b-plancher.txt", appliquer(base(5), [("remplace", "COUVERTURE-REJEU G4 ", "COUVERTURE-REJEU G4 n=12 plancher=12")]))
    bord("n = plancher est armable (jumeau positif de n = plancher - 1)", "k >= p suffit", "code 0, RELEVE-VERDICT armable", rc, s, armable(rc, s))
    rc, s = lancer_releve("b-plancher-6.txt", appliquer(base(6), [("remplace", "COUVERTURE-REJEU G4P ", "COUVERTURE-REJEU G4P n=8 plancher=8")]), etape=6)
    bord("étape 6 : G4P n = plancher est armable", "k >= p suffit à chaque gate visé", "code 0, RELEVE-VERDICT armable", rc, s, armable(rc, s))
    # la section « Non armé » n'excuse rien (l'ancien awk de 46-11 acceptait faux-refus != 0 si elle était là)
    rc, s = lancer_releve("b-non-arme.txt", appliquer(base(5), [("remplace", "REJEU-ETAPE-5 ", "REJEU-ETAPE-5 faux-refus=343 faux-accept=0 refus-conforme-modele=196"),
                                                              ("remplace", "COMPTE G4 ", "COMPTE G4 faux-refus=343 faux-accept=0 refus-conforme-modele=0"),
                                                              ("ajoute", "## Non armé — remonté à Willy"), ("ajoute", "- G4 : 343 refus, limite (bp)")]))
    bord("faux-refus=343 avec une section « Non armé » est refusé", "la section « Non armé » n'a aucun effet", "code 1, RELEVE-ECART faux-refus",
         rc, s, refuse_pour(rc, s, "faux-refus") and len(ecarts_de(s)) == 1)
    # un relevé qui ne porte que la forme de rejeu-gates.sh (sans ARBRE) n'a aucune empreinte d'arbre
    rc, s = lancer_releve("b-empreinte-restreinte.txt", appliquer(base(5), [("sans", "EMPREINTE-ARBRE-")]))
    bord("seul EMPREINTE-IDENTIQUE (périmètre restreint) : empreinte-absente pour chaque lab", "EMPREINTE-IDENTIQUE n'est pas EMPREINTE-ARBRE-IDENTIQUE",
         "code 1, deux lignes RELEVE-ECART empreinte-absente", rc, s, refuse_pour(rc, s, "empreinte-absente") and ecarts_de(s).count("empreinte-absente") == 2)
    # lignes de décision reproduites : inertes
    reproduites = ["RELEVE-VERDICT armable etape=5 labs=2 gates=G3,G4", "RELEVE-ECART faux-refus : ligne 9 : faux-refus=0"]
    rc, s = lancer_releve("b-reproduit-refus.txt", appliquer(base(5), [("remplace", "REJEU-ETAPE-5 ", REFUS_UN), COMPTE_FR_UN] + [("ajoute", l) for l in reproduites]))
    bord("lignes RELEVE-VERDICT armable reproduites + faux-refus=1 : refusé", "les lignes reproduites sont inertes", "code 1, un seul RELEVE-VERDICT (le nôtre), non-armable",
         rc, s, refuse_pour(rc, s, "faux-refus") and len(verdicts_de(s)) == 1)
    rc, s = lancer_releve("b-reproduit-ok.txt", appliquer(base(5), [("ajoute", "RELEVE-VERDICT non-armable etape=5 ecarts=1"), ("ajoute", "RELEVE-ECART faux-refus : ligne 3 : faux-refus=1")]))
    bord("lignes RELEVE-VERDICT non-armable reproduites + relevé conforme : armable", "les lignes reproduites sont inertes", "code 0, RELEVE-VERDICT armable",
         rc, s, armable(rc, s) and len(verdicts_de(s)) == 1)
    # lignes COMPTE (fix-5b V4 (b)) : lues pour recouper REJEU-ETAPE selon la règle de l'émetteur
    rc, s = lancer_releve("b-compte.txt", appliquer(base(5), [("remplace", "COMPTE G4 ", "COMPTE G4 faux-refus=343 faux-accept=2 refus-conforme-modele=0")]))
    bord("une ligne COMPTE à 343 faux refus non reportée dans REJEU-ETAPE : etape-recoupement", "REJEU-ETAPE est recoupé avec la somme des lignes COMPTE de l'étape", "code 1, l'unique écart etape-recoupement",
         rc, s, refuse_pour(rc, s, "etape-recoupement") and ecarts_de(s) == ["etape-recoupement"])
    rc, s = lancer_releve("b-fa-sans-compte.txt", appliquer(base(5), [("remplace", "REJEU-ETAPE-5 ", ACCEPT_UN)]))
    bord("REJEU-ETAPE à faux-accept=1 sans ligne COMPTE qui le porte (gate `-` de l'émetteur) : faux-accept seul, jamais etape-recoupement",
         "faux-accept de REJEU-ETAPE est supérieur ou égal à la somme des lignes COMPTE", "code 1, l'unique écart faux-accept", rc, s, ecarts_de(s) == ["faux-accept"] and rc == 1)
    rc, s = lancer_releve("b-compte-inconnue.txt", appliquer(base(5), [("ajoute", "COMPTE ? faux-refus=1 faux-accept=0 refus-conforme-modele=0")]))
    bord("COMPTE ? (gate inconnue) à faux-refus=1 est compté : etape-recoupement", "une gate inconnue (`?`) reste comptée par l'émetteur", "code 1, l'unique écart etape-recoupement",
         rc, s, ecarts_de(s) == ["etape-recoupement"] and rc == 1)
    rc, s = lancer_releve("b-compte-inconnue-zero.txt", appliquer(base(5), [("ajoute", "COMPTE ? faux-refus=0 faux-accept=0 refus-conforme-modele=0")]))
    bord("COMPTE ? à zéro est armable", "une gate inconnue à zéro ne change aucun total", "code 0, RELEVE-VERDICT armable", rc, s, armable(rc, s))
    rc, s = lancer_releve("b-g4p-hors-etape.txt", appliquer(base(5), [("remplace", "COMPTE G4P ", "COMPTE G4P faux-refus=5 faux-accept=0 refus-conforme-modele=0 hors-etape")]))
    bord("étape 5 : COMPTE G4P suffixée hors-etape à faux-refus=5 n'est pas comptée", "les gates d'une étape ultérieure n'entrent pas dans le total", "code 0, RELEVE-VERDICT armable", rc, s, armable(rc, s))
    # couverture d'un gate non visé par l'étape : informative
    rc, s = lancer_releve("b-g4p-etape5.txt", appliquer(base(5), [("ajoute", "COUVERTURE-REJEU G4P n=0 plancher=8")]))
    bord("étape 5 : une couverture G4P insuffisante n'est pas lue (gate non visé)", "les gates visés dépendent de l'étape", "code 0, RELEVE-VERDICT armable gates=G3,G4",
         rc, s, armable(rc, s) and derniere(s).endswith("gates=G3,G4"))
    # labs : un tableau Markdown ne nomme pas de lab ; les --lab suffisent sans ligne de table
    rc, s = lancer_releve("b-markdown.txt", appliquer(base(5), [("ajoute", "| G3 | ~/lab-z | a | b | c | d |")]))
    bord("une ligne de tableau Markdown ne nomme pas de lab", "seules les lignes `<gate> | <lab> | …` comptent", "code 0, labs=2", rc, s,
         armable(rc, s) and "labs=2 " in derniere(s))
    rc, s = lancer_releve("b-lab-options.txt", appliquer(base(5), [("sans", "G3 | "), ("sans", "G4 | ")]), args=["--lab=" + LAB_A, "--lab=" + LAB_1])
    bord("deux --lab sans ligne de table : labs=2", "les labs sont l'union des --lab et des lignes de table", "code 0, labs=2", rc, s, armable(rc, s) and "labs=2 " in derniere(s))
    rc, s = lancer_releve("b-lab-union.txt", base(5), args=["--lab=" + LAB_A])
    bord("un --lab déjà nommé par la table ne compte pas deux fois", "union sans doublon", "code 0, labs=2", rc, s, armable(rc, s) and "labs=2 " in derniere(s))
    # jeton-deplace (fix-5b V4 (a)) : « COMPTE » est un mot courant ; seule la tête structurelle d'une ligne de compte est un jeton
    rc, s = lancer_releve("b-compte-rendu.txt", appliquer(base(5), [("ajoute", "G3 | " + LAB_A + " | livrables/COMPTE RENDU.md | doit-passer | passe | passe")]))
    bord("une ligne de table au chemin livrables/COMPTE RENDU.md est armable", "COMPTE seul, dans un nom de fichier, n'est pas un jeton", "code 0, RELEVE-VERDICT armable", rc, s, armable(rc, s))
    # chemin-machine (fix-5b V2) : seul un chemin ABSOLU de machine rougit ; un dossier relatif nommé `home` ou `Users` est un chemin de lab
    for nom, ligne in (("une ligne de table dont le chemin est src/pages/home/index.md", "G3 | " + LAB_A + " | src/pages/home/index.md | doit-passer | passe | passe"),
                       ("une note qui cite ~/home/notes.md", "NOTE voir ~/home/notes.md"),
                       ("une note qui cite docs/Users/guide.md", "NOTE voir docs/Users/guide.md")):
        rc, s = lancer_releve("b-machine-relatif.txt", appliquer(base(5), [("ajoute", ligne)]))
        bord(nom + " est armable (chemin relatif, jamais un chemin de machine)", "seul un chemin absolu /Users ou /home rougit chemin-machine", "code 0, RELEVE-VERDICT armable", rc, s, armable(rc, s))
    # bords de forme
    rc, s = lancer_releve("b-sans-fin-de-ligne.txt", None, brut=("\n".join(base(5))).encode("utf-8"))
    bord("relevé sans fin de ligne finale : armable", "la dernière ligne compte même sans \\n", "code 0, RELEVE-VERDICT armable", rc, s, armable(rc, s))
    rc, s = lancer_releve("b-crlf.txt", None, brut=("\r\n".join(base(5)) + "\r\n").encode("utf-8"))
    bord("relevé entièrement en CRLF : refusé", "un \\r final rend chaque ligne malformée", "code 1, RELEVE-ECART etape-malformee et commit-malforme",
         rc, s, refuse_pour(rc, s, "etape-malformee", "commit-malforme", "etape-absente", "commit-absent"))
    # sortie reproductible : ni la ligne fautive, ni deux sorties différentes
    rc1, s1 = lancer_releve("b-deterministe.txt", appliquer(base(5), [("remplace", "REJEU-ETAPE-5 ", REFUS_UN)]))
    rc2, s2 = lancer_releve("b-deterministe.txt", appliquer(base(5), [("remplace", "REJEU-ETAPE-5 ", REFUS_UN)]))
    bord("la sortie est déterministe et ne recopie pas la ligne fautive", "la sortie est reproduite telle quelle dans les relevés versionnés",
         "deux sorties identiques, sans « %s »" % REFUS_UN, rc1, s1, rc1 == rc2 and s1 == s2 and REFUS_UN not in s1)
    # ni sous-processus, ni écriture : cwd vide avant et après, aucune primitive de lancement ou d'écriture dans le cœur
    dossier = os.path.join(WORK, "lecture-seule")
    os.makedirs(dossier, exist_ok=True)
    avant = sorted(os.listdir(dossier))
    rc, s = lancer_releve("b-lecture-seule.txt", base(5), cwd=dossier)
    apres = sorted(os.listdir(dossier))
    corps = corps_python(open(SCRIPT, encoding="utf-8").read()) or ""
    interdits = [m for m in ("subprocess", "os.system", "Popen", "os.popen", "os.exec", "os.spawn", "os.fork", "os.write(", "os.mkdir", "os.rename", "os.remove", "os.unlink", "shutil") if m in corps]
    interdits += [m for m in re.findall(r"open\([^)]*[\"'][wax]\+?b?[\"']", corps)]
    bord("aucun sous-processus et aucune écriture", "le script lit, il ne recalcule ni n'écrit rien", "dossier de travail inchangé, aucune primitive de lancement ou d'écriture dans le cœur",
         rc, s, armable(rc, s) and avant == apres and not interdits)


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
    seule_vu = False
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
        if cas.get("seule") and not seule_vu:  # la trace montre de préférence un cas « seul » : sous le mutant, le code devient 0
            premiere, seule_vu = decrire(rc_m, sm, regle), True
        elif premiere is None:
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


def marqueurs_du_script():
    """Les règles du script, lues sur les lignes `if …:  # releve-<règle>` (dans l'ordre du script)."""
    source = open(SCRIPT, encoding="utf-8").read()
    return [m.group(1) for m in (MARQUEUR_RE.match(l) for l in source.split("\n")) if m]


def sec_mutants():
    marqueurs = marqueurs_du_script()
    for regle in marqueurs:
        executer_mutant_regle(regle, marqueurs)
    for regle in CAS_NEGATIFS:
        if regle not in marqueurs:
            print("  ✗ R-RELEVE-03 %s : cas sans marqueur" % regle)
            print("    assertion : chaque cas de la table vise un marqueur # releve-<règle> du script")
            print("    attendu   : un marqueur # releve-%s" % regle)
            print("    obtenu    : aucun")


def tous_les_cas():
    """[(règle, cas, args)] de tous les cas exerçables de la table."""
    sortie = []
    for regle, cas_regle in CAS_NEGATIFS.items():
        for cas in cas_regle:
            args, _ = fabriquer(cas)
            if args is not None:
                sortie.append((regle, cas, args))
    return sortie


def mutant_toujours_armable():
    ident = "RELEVE-TOUJOURS-ARMABLE"
    chemin, raison = make_mutant(ident, lambda l: "# verdict-final" in l, "armable = True  # verdict-final")
    if chemin is None:
        komut(ident, "le mutant du verdict final se construit", "UNE ligne `armable = …  # verdict-final` remplacée", raison)
        return
    assertion = "R-RELEVE-03 chaque cas négatif est refusé"
    cas = tous_les_cas()
    survivants = []
    premier = None
    for regle, c, args in cas:
        rc_o, out_o, err_o = lancer(SCRIPT, args)
        if not cas_rouge(rc_o, out_o + err_o, regle, c):
            komut(ident, assertion + " (original) : " + regle + " · " + c["nom"], "code 1, RELEVE-ECART %s" % regle, "l'original lui-même ne rougit pas : code %d" % rc_o)
            return
        rc_m, out_m, err_m = lancer(chemin, args)
        if cas_rouge(rc_m, out_m + err_m, regle, c):
            survivants.append(regle)
        elif premier is None:
            premier = "code %d, %s" % (rc_m, court(derniere(out_m + err_m), 80))
    if survivants:
        komut(ident, assertion, "code 1, RELEVE-VERDICT non-armable", "le mutant refuse encore : %s" % ", ".join(sorted(set(survivants))))
        return
    for etape in (5, 6):
        rc_p, sortie_p = positif(chemin, etape)
        if not armable(rc_p, sortie_p):
            komut(ident, "mutant valide : le relevé conforme de l'étape %d reste armable" % etape, "code 0, RELEVE-VERDICT armable", "code %d" % rc_p)
            return
    okmut(ident, "%s (%d cas) · attendu (original) : code 1, RELEVE-VERDICT non-armable · obtenu (mutant) : %s" % (assertion, len(cas), premier))


def mutant_toujours_refus():
    ident = "RELEVE-TOUJOURS-REFUS"
    chemin, raison = make_mutant(ident, lambda l: "# verdict-final" in l, "armable = False  # verdict-final")
    if chemin is None:
        komut(ident, "le mutant du verdict final se construit", "UNE ligne `armable = …  # verdict-final` remplacée", raison)
        return
    assertion = "R-RELEVE-01 le relevé conforme est armable"
    premier = None
    for etape in (5, 6):
        rc_o, sortie_o = positif(SCRIPT, etape)
        if not armable(rc_o, sortie_o):
            komut(ident, assertion + " (original) : étape %d" % etape, "code 0, RELEVE-VERDICT armable", "l'original lui-même ne rend pas armable : code %d" % rc_o)
            return
        rc_m, sortie_m = positif(chemin, etape)
        if armable(rc_m, sortie_m):
            komut(ident, assertion + " : étape %d" % etape, "code 0, RELEVE-VERDICT armable", "le mutant arme encore : code %d" % rc_m)
            return
        if premier is None:
            premier = "code %d, %s" % (rc_m, court(derniere(sortie_m), 80))
    # mutant valide : les cas négatifs restent refusés sous un verdict toujours négatif (le défaut est de ne jamais armer, pas d'armer à tort)
    for regle, c, args in tous_les_cas():
        rc_m, out_m, err_m = lancer(chemin, args)
        if not cas_rouge(rc_m, out_m + err_m, regle, c):
            komut(ident, "mutant valide : le cas négatif %s reste refusé" % regle, "code 1", "code %d" % rc_m)
            return
    okmut(ident, "%s · attendu (original) : code 0, RELEVE-VERDICT armable · obtenu (mutant) : %s" % (assertion, premier))


JETONS_LITTERAUX = ("REJEU-ETAPE-", "COMMIT-REJOUE", "EMPREINTE-ARBRE-", "EMPREINTE-DIVERGENTE", "MESURE-VIDE", "COUVERTURE-REJEU")
RE_TETE_COMPTE = re.compile(r"COMPTE[ \t]+\S+[ \t]+faux-refus")


def jetons_dans(ligne):
    """Jetons de la grammaire que porte la ligne, n'importe où : les six jetons littéraux et la tête structurelle d'une ligne de compte."""
    return [j for j in JETONS_LITTERAUX if j in ligne] + (["COMPTE"] if RE_TETE_COMPTE.search(ligne) else [])


def fautes_point_fixe(script):
    """R-RELEVE-08 (fix-5b V4 (a)) : pour chaque cas texte de la table, (1) aucune ligne de la SORTIE du script ne porte un jeton de la grammaire ; (2) le relevé suivi d'une ligne vide, de
    `## Décision mécanique` et de la sortie du script (la forme des relevés versionnés) redonne le même code, la même dernière ligne et la même liste d'écarts. Rend (fautes, nombre de cas)."""
    fautes, n = [], 0
    for regle, cas, args in tous_les_cas():
        if cas.get("special"):
            continue
        rc, out, err = lancer(script, args)
        sortie = out + err
        porteuses = [l for l in sortie.split("\n") if jetons_dans(l)]
        if porteuses:
            fautes.append("%s · %s : la sortie porte un jeton de la grammaire : %s" % (regle, cas["nom"], court(porteuses[0], 90)))
            continue
        releve = open(args[-1], "rb").read()
        chemin = ecrire_octets("point-fixe-%03d.txt" % n, releve.rstrip(b"\n") + b"\n\n## D\xc3\xa9cision m\xc3\xa9canique\n" + sortie.encode("utf-8"))
        n += 1
        rc2, out2, err2 = lancer(script, args[:-1] + [chemin])
        s2 = out2 + err2
        if not (rc2 == rc and derniere(s2) == derniere(sortie) and ecarts_de(s2) == ecarts_de(sortie)):
            fautes.append("%s · %s : relevé + décision reproduite : code %d écarts %s, attendu code %d écarts %s" % (regle, cas["nom"], rc2, ecarts_de(s2), rc, ecarts_de(sortie)))
    return fautes, n


def controle_08():
    fautes, n = fautes_point_fixe(SCRIPT)
    if n > 0 and not fautes:
        ok("R-RELEVE-08 point fixe : %d relevés non armables, relevé + sa décision reproduite = même code, même dernière ligne, mêmes écarts ; aucune ligne de sortie ne porte un jeton" % n)
    else:
        ko("R-RELEVE-08", "la sortie du script ne porte aucun jeton de la grammaire et sa reproduction dans un relevé ne change pas la décision (point fixe)", "aucune faute sur %d cas" % n,
           "%d faute(s) : %s" % (len(fautes), "; ".join(fautes[:3]) or "aucun cas joué"))


RE_ORDRE = re.compile(r"^ORDRE_ETAPES = (.+)$", re.M)


def ordre_etapes_de(texte):
    """La valeur de l'UNIQUE ligne `ORDRE_ETAPES = (…)` du texte (ast.literal_eval), ou None."""
    trouves = RE_ORDRE.findall(texte)
    if len(trouves) != 1:
        return None
    try:
        return ast.literal_eval(trouves[0])
    except (ValueError, SyntaxError):
        return None


def fautes_ordre(chemin_script):
    """R-RELEVE-07 : l'ordre des étapes copié dans le vérificateur est celui de rejeu-gates.sh (lues toutes deux par ast.literal_eval). Rend la liste des fautes."""
    emetteur = os.path.join(os.path.dirname(SCRIPT), "rejeu-gates.sh")
    if not os.path.isfile(emetteur):
        return ["rejeu-gates.sh absent à côté du script jugé : l'ordre des étapes n'est pas confronté (jamais un vert)"]
    copie = ordre_etapes_de(open(chemin_script, encoding="utf-8").read())
    origine = ordre_etapes_de(open(emetteur, encoding="utf-8").read())
    if copie is None or origine is None:
        return ["ligne `ORDRE_ETAPES = (…)` unique introuvable ou illisible (vérificateur : %s, rejeu-gates.sh : %s)" % (copie is not None, origine is not None)]
    if copie != origine:
        return ["ORDRE_ETAPES du vérificateur %s diffère de celui de rejeu-gates.sh %s" % (copie, origine)]
    return []


def controle_07():
    fautes = fautes_ordre(SCRIPT)
    # sensibilité : la même confrontation sur une copie PERTURBÉE (G4 déplacée dans le dernier lot) rougit
    source = open(SCRIPT, encoding="utf-8").read()
    perturbee = source.replace('("G3", "G4"), ("G4P",)', '("G3",), ("G4", "G4P")')
    sensible = perturbee != source and ordre_etapes_de(perturbee) is not None and ordre_etapes_de(perturbee) != ordre_etapes_de(open(os.path.join(os.path.dirname(SCRIPT), "rejeu-gates.sh"), encoding="utf-8").read())
    if not fautes and sensible:
        ok("R-RELEVE-07 ORDRE_ETAPES du vérificateur est celui de rejeu-gates.sh (ast.literal_eval des deux lignes) ; la confrontation voit une copie perturbée", "%s" % (ordre_etapes_de(source),))
    else:
        ko("R-RELEVE-07", "l'ordre des étapes copié dans le vérificateur est identique à celui de rejeu-gates.sh, et la confrontation n'est pas aveugle", "ordres égaux, copie perturbée vue",
           "fautes %s ; confrontation %s" % (fautes, "sensible" if sensible else "AVEUGLE"))


def mutant_ordre():
    """MUT-RELEVE-ORDRE (fix-5b V4 (b)) : G4 déplacée dans le dernier lot de la copie d'ORDRE_ETAPES -> R-RELEVE-07 rougit."""
    ident = "RELEVE-ORDRE"
    chemin, raison = make_mutant(ident, lambda l: l.startswith("ORDRE_ETAPES = "), 'ORDRE_ETAPES = (("G6", "G5"), ("G1",), ("G7",), ("ROLE",), ("G3",), ("G4", "G4P"))')
    if chemin is None:
        komut(ident, "le mutant se construit", "UNE ligne `ORDRE_ETAPES = …` modifiée", raison)
        return
    assertion = "R-RELEVE-07 l'ordre des étapes est celui de rejeu-gates.sh"
    if fautes_ordre(SCRIPT):
        komut(ident, assertion + " (original)", "aucune faute", "l'original lui-même rougit : %s" % court(fautes_ordre(SCRIPT)[0], 120))
        return
    fautes = fautes_ordre(chemin)
    if not fautes:
        komut(ident, assertion, "R-RELEVE-07 rougit sous le mutant", "le mutant passe encore")
        return
    okmut(ident, "%s · attendu (original) : aucune faute · obtenu (mutant) : %s" % (assertion, court(fautes[0], 130)))


def mutant_recoupement_fa_egal():
    """MUT-RELEVE-RECOUPEMENT-FA-EGAL (fix-5b V4 (b)) : le recoupement de faux-accept par ÉGALITÉ au lieu de « supérieur ou égal » -> le relevé dont REJEU-ETAPE porte un faux-accept sans
    ligne COMPTE qui le porte (gate `-` de l'émetteur) lève aussi etape-recoupement."""
    ident = "RELEVE-RECOUPEMENT-FA-EGAL"
    chemin, raison = make_mutant(ident, lambda l: l.rstrip().endswith("# recoupement-fa"), "if b != somme_fa:  # recoupement-fa")
    if chemin is None:
        komut(ident, "le mutant se construit", "UNE ligne `if b < somme_fa:  # recoupement-fa` rendue à l'égalité", raison)
        return
    assertion = "R-RELEVE-04 REJEU-ETAPE à faux-accept=1 sans ligne COMPTE qui le porte : faux-accept seul"
    releve = ecrire_releve("m-fa-egal.txt", appliquer(base(5), [("remplace", "REJEU-ETAPE-5 ", ACCEPT_UN)]))
    rc_o, out_o, err_o = lancer(SCRIPT, ["--etape=5", releve])
    if not (rc_o == 1 and ecarts_de(out_o + err_o) == ["faux-accept"]):
        komut(ident, assertion + " (original)", "code 1, l'unique écart faux-accept", "l'original lui-même : code %d, écarts %s" % (rc_o, ecarts_de(out_o + err_o)))
        return
    rc_m, out_m, err_m = lancer(chemin, ["--etape=5", releve])
    if "etape-recoupement" not in ecarts_de(out_m + err_m):
        komut(ident, assertion, "le mutant lève etape-recoupement", "le mutant ne lève pas etape-recoupement : écarts %s" % ecarts_de(out_m + err_m))
        return
    for etape in (5, 6):
        rc_p, sortie_p = positif(chemin, etape)
        if not armable(rc_p, sortie_p):
            komut(ident, "mutant valide : le relevé conforme de l'étape %d reste armable sous le mutant" % etape, "code 0, RELEVE-VERDICT armable", "code %d" % rc_p)
            return
    okmut(ident, "%s · attendu (original) : code 1, écarts [faux-accept] · obtenu (mutant) : code %d, écarts %s" % (assertion, rc_m, ecarts_de(out_m + err_m)))


def mutant_sortie_jeton():
    """MUT-RELEVE-SORTIE-JETON (fix-5b V4 (a)) : le détail de `etape-malformee` recite un jeton de la grammaire (le libellé d'avant le correctif) -> R-RELEVE-08 rougit."""
    ident = "RELEVE-SORTIE-JETON"
    chemin, raison = make_mutant(ident, lambda l: l.lstrip().startswith('ecart("etape-malformee"'),
                                 'ecart("etape-malformee", "ligne %d : jeton REJEU-ETAPE- sans la grammaire exacte" % i)')
    if chemin is None:
        komut(ident, "le mutant se construit", "UNE ligne `ecart(\"etape-malformee\", …)` qui recite un jeton", raison)
        return
    assertion = "R-RELEVE-08 aucune ligne de sortie ne porte un jeton"
    fautes_o, n_o = fautes_point_fixe(SCRIPT)
    if fautes_o or n_o == 0:
        komut(ident, assertion + " (original)", "aucune faute", "l'original lui-même rougit : %s" % court("; ".join(fautes_o), 120))
        return
    fautes_m, _ = fautes_point_fixe(chemin)
    if not fautes_m:
        komut(ident, assertion, "R-RELEVE-08 rougit sous le mutant", "le mutant passe encore")
        return
    for etape in (5, 6):
        rc_p, sortie_p = positif(chemin, etape)
        if not armable(rc_p, sortie_p):
            komut(ident, "mutant valide : le relevé conforme de l'étape %d reste armable sous le mutant" % etape, "code 0, RELEVE-VERDICT armable", "code %d" % rc_p)
            return
    okmut(ident, "%s · attendu (original) : aucune faute sur %d cas · obtenu (mutant) : %d faute(s), la première : %s" % (assertion, n_o, len(fautes_m), court(fautes_m[0], 110)))


def mutant_machine_sous_chaine():
    """MUT-RELEVE-MACHINE-SOUS-CHAINE (fix-5b V2, revue-5b n°5) : la ligne de calcul des chemins de machine (marqueur `# fait-chemin-machine`) rendue à la sous-chaîne `/Users/`, `/home/` -> un
    bord POSITIF de R-RELEVE-04 (chemin relatif `src/pages/home/index.md`, `~/home/notes.md`, `docs/Users/guide.md`) rougit `chemin-machine` ; l'original les arme tous."""
    ident = "RELEVE-MACHINE-SOUS-CHAINE"
    chemin, raison = make_mutant(ident, lambda l: l.rstrip().endswith("# fait-chemin-machine"),
                                 "chemins_machine = [(i, jeton) for i, ligne in numerotees for jeton in (\"/Users/\", \"/home/\") if jeton in ligne]  # fait-chemin-machine")
    if chemin is None:
        komut(ident, "le mutant se construit", "UNE ligne `… # fait-chemin-machine` rendue à la sous-chaîne", raison)
        return
    assertion = "R-RELEVE-04 un chemin relatif nommé home ou Users est armable"
    lignes = ("G3 | " + LAB_A + " | src/pages/home/index.md | doit-passer | passe | passe", "NOTE voir ~/home/notes.md", "NOTE voir docs/Users/guide.md")
    trace = None
    for i, ligne in enumerate(lignes):
        releve = ecrire_releve("m-sous-chaine-%d.txt" % i, appliquer(base(5), [("ajoute", ligne)]))
        rc_o, out_o, err_o = lancer(SCRIPT, ["--etape=5", releve])
        if not armable(rc_o, out_o + err_o):
            komut(ident, assertion + " (original) : " + ligne, "code 0, RELEVE-VERDICT armable", "l'original lui-même refuse : code %d, écarts %s" % (rc_o, ecarts_de(out_o + err_o)))
            return
        rc_m, out_m, err_m = lancer(chemin, ["--etape=5", releve])
        if "chemin-machine" not in ecarts_de(out_m + err_m):
            komut(ident, assertion + " : " + ligne, "le mutant rougit chemin-machine", "le mutant arme encore : code %d, écarts %s" % (rc_m, ecarts_de(out_m + err_m)))
            return
        if trace is None:
            trace = "code %d, RELEVE-ECART chemin-machine sur « %s »" % (rc_m, ligne)
    for etape in (5, 6):
        rc_p, sortie_p = positif(chemin, etape)
        if not armable(rc_p, sortie_p):
            komut(ident, "mutant valide : le relevé conforme de l'étape %d reste armable sous le mutant" % etape, "code 0, RELEVE-VERDICT armable", "code %d" % rc_p)
            return
    okmut(ident, "%s · attendu (original) : code 0, RELEVE-VERDICT armable · obtenu (mutant) : %s" % (assertion, trace))


def mutant_entier_borne():
    """MUT-RELEVE-ENTIER-BORNE (fix-5b V1, revue-5b n°4, audit-5b F-4) : la grammaire de REJEU-ETAPE rendue à `[0-9]+` (nombre sans borne) -> les cas à nombre de plus de 9 chiffres ne sont plus
    refusés pour `etape-malformee` (sous Python >= 3.11, int() lève sur 4 301 chiffres : une trace, aucune ligne de verdict ; sous Python < 3.11, le doublon et le faux-accept parlent à sa
    place) ; l'original les refuse tous."""
    ident = "RELEVE-ENTIER-BORNE"
    regle = "etape-malformee"
    ligne = next((l for l in open(SCRIPT, encoding="utf-8").read().split("\n") if l.startswith("RE_ETAPE = re.compile(")), "")
    if "{1,9}" not in ligne:
        komut(ident, "la grammaire de REJEU-ETAPE est bornée à 1 à 9 chiffres", "une ligne `RE_ETAPE = re.compile(…{1,9}…)`", "introuvable")
        return
    chemin, raison = make_mutant(ident, lambda l: l == ligne, ligne.replace("{1,9}", "+"))
    if chemin is None:
        komut(ident, "le mutant se construit", "UNE ligne RE_ETAPE rendue à `[0-9]+`", raison)
        return
    assertion = "R-RELEVE-03 %s rougit (nombres de plus de 9 chiffres)" % regle
    cas = [c for c in CAS_NEGATIFS[regle] if "entier-borne" in c.get("tue", ())]
    if not cas:
        komut(ident, assertion, "au moins un cas étiqueté entier-borne", "aucun")
        return
    trace = None
    for c in cas:
        args, _ = fabriquer(c)
        rc_o, out_o, err_o = lancer(SCRIPT, args)
        if not cas_rouge(rc_o, out_o + err_o, regle, c):
            komut(ident, assertion + " (original) : " + c["nom"], "code 1, RELEVE-ECART %s" % regle, "l'original lui-même ne rougit pas : code %d, écarts %s" % (rc_o, ecarts_de(out_o + err_o)))
            return
        rc_m, out_m, err_m = lancer(chemin, args)
        sm = out_m + err_m
        if cas_rouge(rc_m, sm, regle, c):
            komut(ident, assertion + " : " + c["nom"], "le mutant ne refuse plus ce cas pour %s" % regle, "le mutant le refuse encore : " + decrire(rc_m, sm, regle))
            return
        if trace is None:
            trace = decrire(rc_m, sm, regle) + (" (trace Python : %s)" % court(derniere(err_m), 60) if "Error" in derniere(err_m) else "")
    for etape in (5, 6):
        rc_p, sortie_p = positif(chemin, etape)
        if not armable(rc_p, sortie_p):
            komut(ident, "mutant valide : le relevé conforme de l'étape %d reste armable sous le mutant" % etape, "code 0, RELEVE-VERDICT armable", "code %d" % rc_p)
            return
    okmut(ident, "%s · attendu (original) : code 1, RELEVE-ECART %s · obtenu (mutant) : %s" % (assertion, regle, trace))


# ---------------------------------------------------------------------------------------------------------------------
# R-RELEVE-CHAINE : la vraie chaîne de rejeu sur un lab synthétique, composée au format des relevés de la phase (46.1-18, P461-D-06, P461-D-07)
# ---------------------------------------------------------------------------------------------------------------------
AGENT_PRODUCTEUR_BASH = "---\nname: producteur-bash\ndescription: agent synthétique\ntools: Read, Write, Bash\n---\nCorps.\n"
FICHIERS_LAB_CHAINE = {".planning/config.json": '{"planning_version": "2.0"}', ".planning/notes.md": "n", "rapport.md": "rapport\n", "dossier-plein/a.txt": "a\n"}
DEPOT_NOMS = {"5": "chaine-etape-5.md", "6": "chaine-etape-6.md", "6-sans-agent": "chaine-etape-6-sans-agent.md"}
RE_ECART_COUVERTURE_G4P = re.compile(r"^RELEVE-ECART couverture-insuffisante : gate G4P ligne [0-9]+ : n=0 sous plancher=4$")


def env_chaine():
    """Environnement du rejeu synthétique : un HOME temporaire que le lab n'habite pas (le lab s'affiche donc `<lab-1>`), rien d'autre."""
    home = os.path.join(WORK, "chaine-home")
    os.makedirs(home, exist_ok=True)
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": home, "XDG_CACHE_HOME": os.path.join(WORK, "chaine-xdg")}
    if os.environ.get("TMPDIR"):
        env["TMPDIR"] = os.environ["TMPDIR"]
    return env


def chaine_rejouer(nom, etape, avec_agent):
    """(code de rejeu-reel.sh, texte du rapport, erreur standard) du VRAI rejeu sur un lab synthétique tout neuf, construit sous WORK/chaine/<nom>/lab."""
    racine = os.path.join(WORK, "chaine", nom)
    lab = os.path.join(racine, "lab")
    fichiers = dict(FICHIERS_LAB_CHAINE)
    if avec_agent:
        fichiers[".claude/agents/producteur-bash.md"] = AGENT_PRODUCTEUR_BASH
    for rel, contenu in fichiers.items():
        chemin = os.path.join(lab, rel)
        os.makedirs(os.path.dirname(chemin), exist_ok=True)
        with open(chemin, "w", encoding="utf-8") as fh:
            fh.write(contenu)
    rapport = os.path.join(racine, "rapport.txt")
    reel = os.path.join(os.path.dirname(SCRIPT), "rejeu-reel.sh")
    p = subprocess.run(["bash", reel, "--lab=" + lab, "--etape=%d" % etape, "--rapport=" + rapport], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, env=env_chaine(), cwd=racine, timeout=300)
    texte = open(rapport, encoding="utf-8").read() if os.path.isfile(rapport) else ""
    return p.returncode, texte, p.stderr.decode("utf-8", "replace")


def chaine_composer(etape, rapport, decision, non_arme):
    """Le relevé de rejeu au format de la phase : en-tête (repos du lab synthétique, qu'aucun processus n'habite), commit rejoué, sortie brute du rejeu, décision
    mécanique qui reproduit la sortie du script et, pour un relevé non armable, la section « Non armé » et la ligne d'escalade."""
    lignes = ["# Relevé de rejeu composé par la suite test-verifier-releve.sh (R-RELEVE-CHAINE, étape %d, lab synthétique)" % etape,
              "REPOS-AVANT %s processus=0" % LAB_1, "REPOS-APRES %s processus=0" % LAB_1, "COMMIT-REJOUE " + COMMIT, "", "## Sortie brute du rejeu"]
    lignes += rapport.rstrip("\n").split("\n")
    lignes += ["", "## Décision mécanique"] + decision.rstrip("\n").split("\n")
    if non_arme:
        lignes += ["", "## Non armé — remonté à Willy", "- G4P : couverture insuffisante, aucun agent rejoué (n=0 sous le plancher)", "ESCALADE-WILLY ETAPE-%d couverture" % etape]
    return "\n".join(lignes) + "\n"


def chaine_faits(rapport):
    """Les comptes du rejeu synthétique, pour la trace : REJEU-ETAPE et COUVERTURE-REJEU, tels que le rejeu les a émis."""
    return " · ".join(l for l in rapport.split("\n") if l.startswith(("REJEU-ETAPE-", "COUVERTURE-REJEU ")))


def depot_chaine():
    """Dossier de dépôt de VF_RELEVE_CHAINE_DEPOT s'il est absolu et existant, sinon None (variable absente, vide, relative ou dossier absent : rien n'est déposé)."""
    depot = os.environ.get("VF_RELEVE_CHAINE_DEPOT", "")
    return depot if depot and os.path.isabs(depot) and os.path.isdir(depot) else None


def chaine_cas(libelle, cle, etape, avec_agent, armable_attendu):
    """Un cas de la chaîne : rejeu réel → ajout de COMMIT-REJOUE → script ; puis relevé composé → script rejoué (même code, même dernière ligne) → dépôt."""
    ident = "R-RELEVE-CHAINE " + libelle
    try:
        rc_reel, rapport, err_reel = chaine_rejouer("cas-" + cle, etape, avec_agent)
    except (OSError, subprocess.SubprocessError) as exc:
        ko(ident, "le rejeu réel (rejeu-reel.sh) s'exécute sur le lab synthétique", "un rapport de rejeu", type(exc).__name__ + " " + court(exc))
        return
    if rapport == "":
        ko(ident, "le rejeu réel écrit son rapport", "un rapport non vide", "rapport vide, code %d, erreur « %s »" % (rc_reel, court(err_reel)))
        return
    brut = os.path.join(WORK, "chaine", "cas-" + cle, "brut.txt")
    with open(brut, "w", encoding="utf-8") as fh:
        fh.write(rapport + "COMMIT-REJOUE " + COMMIT + "\n")
    p = subprocess.run(["bash", SCRIPT, "--etape=%d" % etape, "--lab=" + LAB_1, brut], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=WORK, timeout=120)
    rc, sortie = p.returncode, (p.stdout + p.stderr).decode("utf-8", "replace")
    if armable_attendu:
        attendu = "rejeu-reel.sh code 0, verifier-releve.sh code 0, dernière ligne RELEVE-VERDICT armable etape=%d, aucun écart" % etape
        conforme = rc_reel == 0 and armable(rc, sortie) and ("armable etape=%d labs=1 " % etape) in derniere(sortie)
    else:
        attendu = "rejeu-reel.sh code 1, verifier-releve.sh code 1, l'unique écart couverture-insuffisante sur G4P (n=0 sous plancher=4)"
        ecarts = [l for l in sortie.split("\n") if l.startswith("RELEVE-ECART ")]
        conforme = (rc_reel == 1 and rc == 1 and ecarts_de(sortie) == ["couverture-insuffisante"] and len(ecarts) == 1 and bool(RE_ECART_COUVERTURE_G4P.match(ecarts[0]))
                    and derniere(sortie) == "RELEVE-VERDICT non-armable etape=%d ecarts=1" % etape)
    if not conforme:
        ko(ident, "la chaîne réelle (rejeu-reel.sh → verifier-releve.sh) rend le verdict attendu sur la forme réelle des lignes émises", attendu,
           "rejeu-reel.sh code %d, verifier-releve.sh code %d, écarts %s, dernière ligne « %s », comptes du rejeu : %s" % (rc_reel, rc, ecarts_de(sortie), court(derniere(sortie)), court(chaine_faits(rapport))))
        return
    # le relevé composé au format de la phase : le script, rejoué sur le fichier final, rend le même code et la même dernière ligne
    final = chaine_composer(etape, rapport, sortie, not armable_attendu)
    chemin = os.path.join(WORK, "chaine", "cas-" + cle, "final.md")
    with open(chemin, "w", encoding="utf-8") as fh:
        fh.write(final)
    p2 = subprocess.run(["bash", SCRIPT, "--etape=%d" % etape, "--lab=" + LAB_1, chemin], stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=WORK, timeout=120)
    rc2, sortie2 = p2.returncode, (p2.stdout + p2.stderr).decode("utf-8", "replace")
    machine = [m for m in ("/Users/", "/home/") if m in final]
    if not (rc2 == rc and derniere(sortie2) == derniere(sortie) and ecarts_de(sortie2) == ecarts_de(sortie) and not machine):
        ko(ident, "le relevé composé au format de phase redonne le même code et la même dernière ligne (les lignes reproduites sont inertes), sans chemin de machine",
           "code %d, dernière ligne « %s »" % (rc, derniere(sortie)),
           "code %d, dernière ligne « %s », écarts %s, chemins de machine %s" % (rc2, court(derniere(sortie2)), ecarts_de(sortie2), machine))
        return
    depose = ""
    depot = depot_chaine()
    if depot is not None:
        with open(os.path.join(depot, DEPOT_NOMS[cle]), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(final)
        depose = " · déposé sous " + DEPOT_NOMS[cle]
    ok(ident, "%s · %s · composé au format de phase, même dernière ligne « %s »%s" % (chaine_faits(rapport), court(derniere(sortie), 70), court(derniere(sortie2), 70), depose))


def controle_chaine():
    reel = os.path.join(os.path.dirname(SCRIPT), "rejeu-reel.sh")
    if not os.path.isfile(reel):
        ko("R-RELEVE-CHAINE", "rejeu-reel.sh est lu à côté du script jugé", "rejeu-reel.sh présent", "absent : la chaîne réelle n'est pas rejouée, jamais un vert")
        return
    chaine_cas("étape 5, lab synthétique avec un agent producteur doté de Bash : armable", "5", 5, True, True)
    chaine_cas("étape 6, lab synthétique avec un agent producteur doté de Bash : armable", "6", 6, True, True)
    chaine_cas("étape 6, lab synthétique sans aucun agent : couverture-insuffisante sur G4P", "6-sans-agent", 6, False, False)


# ---------------------------------------------------------------------------------------------------------------------
# R-RELEVE-05 : les deux relevés RÉELS de la Phase 46 sont refusés (fixtures extraites par lignes ciblées, chaque ligne verbatim)
# ---------------------------------------------------------------------------------------------------------------------
LABS_46 = ("~/jarvis-keystone", "~/BusinessFlow-Lab")
# (fixture, étape, faux refus du relevé, règles refusées dans l'ordre alphabétique, commits attendus dans la fixture)
CORPUS_46 = (
    ("releve-46-etape-5.txt", 5, 349, ["faux-refus", "jeton-deplace"], 1),
    ("releve-46-etape-6.txt", 6, 343, ["commit-absent", "faux-refus", "jeton-deplace"], 0),
)


def controle_05():
    for nom, etape, refus, regles, commits in CORPUS_46:
        ident = "R-RELEVE-05 %s (étape %d)" % (nom, etape)
        chemin = os.path.join(FIXTURES, nom)
        if not os.path.isfile(chemin):
            ko(ident, "la fixture du relevé réel de la 46 existe", "fixtures/%s" % nom, "absente")
            continue
        lignes = open(chemin, encoding="utf-8").read().split("\n")
        n_commits = len([l for l in lignes if l.startswith("COMMIT-REJOUE")])
        rc, out, err = lancer(SCRIPT, ["--etape=%d" % etape] + ["--lab=" + lab for lab in LABS_46] + [chemin])
        sortie = out + err
        detail = [l for l in sortie.split("\n") if l.startswith("RELEVE-ECART faux-refus : ") and l.endswith(" : faux-refus=%d" % refus)]
        attendu = "code 1, écarts %s (dont faux-refus=%d ; jeton-deplace sur la seule ligne 1, le commentaire d'extraction de la fixture), %d ligne(s) COMMIT-REJOUE dans la fixture, dernière ligne RELEVE-VERDICT non-armable etape=%d ecarts=%d" % (regles, refus, commits, etape, len(regles))
        jetons = [l for l in sortie.split("\n") if l.startswith("RELEVE-ECART jeton-deplace : ")]
        if (rc == 1 and sorted(ecarts_de(sortie)) == regles and len(detail) == 1 and len(jetons) == 1 and jetons[0].startswith("RELEVE-ECART jeton-deplace : ligne 1 : ") and n_commits == commits
                and derniere(sortie) == "RELEVE-VERDICT non-armable etape=%d ecarts=%d" % (etape, len(regles))):
            ok(ident + " est refusé", "code 1, " + ", ".join("RELEVE-ECART " + r for r in regles) + ", faux-refus=%d, %d ligne(s) COMMIT-REJOUE" % (refus, n_commits))
        else:
            ko(ident, "le relevé réel de la 46 qui a fait refuser l'armement est refusé, pour chacune de ses causes et pour elles seules", attendu,
               "code %d, écarts %s, lignes faux-refus=%d : %d, %d ligne(s) COMMIT-REJOUE, dernière ligne « %s »" % (rc, sorted(ecarts_de(sortie)), refus, len(detail), n_commits, court(derniere(sortie))))
    # retouche (a) d'un relevé réel (audit-5b F-2 (a)) : la ligne REJEU-ETAPE-5 décalée d'une espace, une ligne propre à 0 ajoutée ; la ligne 1 de la fixture (commentaire d'extraction,
    # absent du relevé réel) est écartée pour que seule la retouche parle
    chemin = os.path.join(FIXTURES, "releve-46-etape-5.txt")
    if os.path.isfile(chemin):
        reelles = [l for l in open(chemin, encoding="utf-8").read().split("\n") if l != "" and not l.startswith("# extrait de ")]
        retouchee = [(" " + l if l.startswith("REJEU-ETAPE-5 ") else l) for l in reelles] + ["REJEU-ETAPE-5 faux-refus=0 faux-accept=0 refus-conforme-modele=196"]
        rc, out, err = lancer(SCRIPT, ["--etape=5"] + ["--lab=" + lab for lab in LABS_46] + [ecrire_releve("retouche-a.txt", retouchee)])
        sortie = out + err
        if rc == 1 and sorted(ecarts_de(sortie)) == ["etape-recoupement", "jeton-deplace"]:
            ok("R-RELEVE-05 retouche (a) du relevé réel de l'étape 5 (ligne REJEU-ETAPE-5 décalée d'une espace + ligne propre à 0) est refusée", "code 1, RELEVE-ECART etape-recoupement, RELEVE-ECART jeton-deplace")
        else:
            ko("R-RELEVE-05 retouche (a)", "un relevé réel retouché (ligne REJEU-ETAPE décalée d'une espace, ligne propre ajoutée) n'est pas armable", "code 1, les écarts etape-recoupement et jeton-deplace",
               "code %d, écarts %s, dernière ligne « %s »" % (rc, ecarts_de(sortie), court(derniere(sortie))))
        # retouche (b) (audit-5b F-2 (b)) : faux-refus=349 changé en 0 alors que COMPTE G4 faux-refus=343 reste
        retouchee_b = [("REJEU-ETAPE-5 faux-refus=0 faux-accept=0 refus-conforme-modele=196" if l.startswith("REJEU-ETAPE-5 ") else l) for l in reelles]
        rc, out, err = lancer(SCRIPT, ["--etape=5"] + ["--lab=" + lab for lab in LABS_46] + [ecrire_releve("retouche-b.txt", retouchee_b)])
        sortie = out + err
        if rc == 1 and ecarts_de(sortie) == ["etape-recoupement"]:
            ok("R-RELEVE-05 retouche (b) du relevé réel de l'étape 5 (faux-refus=349 changé en 0, COMPTE G4 faux-refus=343 gardée) est refusée", "code 1, RELEVE-ECART etape-recoupement")
        else:
            ko("R-RELEVE-05 retouche (b)", "un relevé réel dont REJEU-ETAPE ne reporte pas ses lignes COMPTE n'est pas armable", "code 1, l'unique écart etape-recoupement",
               "code %d, écarts %s, dernière ligne « %s »" % (rc, ecarts_de(sortie), court(derniere(sortie))))


# ---------------------------------------------------------------------------------------------------------------------
# R-RELEVE-06 : contrôle statique du cœur Python (ni sous-processus, ni suppression, ni écriture)
# ---------------------------------------------------------------------------------------------------------------------
IMPORTS_INTERDITS = ("subprocess", "shutil")
OS_INTERDITS = ("system", "remove", "unlink", "rename", "replace", "popen", "mkdir", "makedirs", "rmdir", "removedirs", "fork", "write", "truncate", "chmod", "symlink", "link")
DRAPEAUX_ECRITURE = ("O_WRONLY", "O_RDWR", "O_CREAT", "O_APPEND", "O_TRUNC", "O_EXCL")


def violations_statiques(corps):
    """Liste des violations du cœur Python `corps` : import interdit, appel os interdit (os.system, os.remove…), fichier ouvert en écriture (open, os.open)."""
    violations = []
    for noeud in ast.walk(ast.parse(corps)):
        if isinstance(noeud, ast.Import):
            violations += ["import " + a.name for a in noeud.names if a.name.split(".")[0] in IMPORTS_INTERDITS]
        elif isinstance(noeud, ast.ImportFrom):
            if (noeud.module or "").split(".")[0] in IMPORTS_INTERDITS:
                violations.append("from %s import …" % noeud.module)
        elif isinstance(noeud, ast.Attribute):
            if isinstance(noeud.value, ast.Name) and noeud.value.id == "os" and (noeud.attr in OS_INTERDITS or noeud.attr.startswith(("exec", "spawn"))):
                violations.append("os." + noeud.attr)
            if noeud.attr in DRAPEAUX_ECRITURE:
                violations.append("drapeau " + noeud.attr)
            if noeud.attr in ("write_text", "write_bytes"):
                violations.append("." + noeud.attr)
        elif isinstance(noeud, ast.Call) and isinstance(noeud.func, ast.Name):
            if noeud.func.id in ("__import__", "exec", "eval"):
                violations.append(noeud.func.id + "(…)")
            elif noeud.func.id == "open":
                mode = noeud.args[1] if len(noeud.args) > 1 else next((k.value for k in noeud.keywords if k.arg == "mode"), None)
                if mode is None:
                    continue  # open(chemin) : lecture
                if not (isinstance(mode, ast.Constant) and isinstance(mode.value, str)):
                    violations.append("open(…) à mode non constant")
                elif any(c in mode.value for c in "wax+"):
                    violations.append("open(…, %r)" % mode.value)
    return violations


SOURCES_FAUTIVES = (
    ("import subprocess", "import subprocess\n"),
    ("import shutil", "import os\nimport shutil\n"),
    ("from subprocess import run", "from subprocess import run\n"),
    ("os.system", "import os\nos.system('x')\n"),
    ("os.remove", "import os\nos.remove('x')\n"),
    ("open en écriture", "open('f', 'w')\n"),
    ("open en ajout par mot-clé", "open('f', mode='a')\n"),
    ("open en lecture-écriture", "open('f', 'rb+')\n"),
    ("os.open en écriture", "import os\nos.open('f', os.O_WRONLY | os.O_CREAT)\n"),
)
SOURCE_SAINE = "import os\nimport re\nfd = os.open('f', os.O_RDONLY | os.O_NONBLOCK)\nos.read(fd, 8)\nos.close(fd)\nopen('f').read()\nopen('f', 'rb').read()\n"


def controle_06():
    ident = "R-RELEVE-06"
    corps = corps_python(open(SCRIPT, encoding="utf-8").read())
    if corps is None:
        ko(ident, "le cœur Python du script s'extrait du heredoc", "un heredoc PY_VERIFIER_RELEVE_EOF", "introuvable")
        return
    aveugles = [nom for nom, source in SOURCES_FAUTIVES if not violations_statiques(source)]
    faux_positif = violations_statiques(SOURCE_SAINE)
    if aveugles or faux_positif:
        ko(ident, "l'analyseur statique voit chaque source fautive et laisse passer la source saine", "toutes les sources fautives relevées, aucune violation sur la source saine",
           "non vues : %s ; violations sur la source saine : %s" % (aveugles, faux_positif))
        return
    violations = violations_statiques(corps)
    if violations:
        ko(ident, "le cœur Python n'importe ni subprocess ni shutil, n'appelle ni os.system ni os.remove et n'ouvre aucun fichier en écriture", "aucune violation", ", ".join(sorted(set(violations))))
    else:
        ok(ident + " le cœur Python (%d lignes) n'importe ni subprocess ni shutil, n'appelle ni os.system ni os.remove et n'ouvre aucun fichier en écriture" % len(corps.split("\n")),
           "analyse ast ; l'analyseur voit les %d sources fautives de la suite" % len(SOURCES_FAUTIVES))


# ---------------------------------------------------------------------------------------------------------------------
# R-RELEVE-COUVERTURE : chaque règle marquée du script a un cas négatif ET un mutant tué ; la suite imprime sa couverture
# ---------------------------------------------------------------------------------------------------------------------
def evaluer_couverture(marqueurs, table, tues):
    """(règles, avec cas négatif, avec mutant tué, sans cas, sans mutant, cas sans marqueur) : tout est calculé, rien n'est posé."""
    sans_cas = [r for r in marqueurs if not table.get(r)]
    sans_mutant = [r for r in marqueurs if "RELEVE-" + r.upper() not in tues]
    orphelins = [r for r in table if r not in marqueurs]
    return len(marqueurs), len(marqueurs) - len(sans_cas), len(marqueurs) - len(sans_mutant), sans_cas, sans_mutant, orphelins


def controle_couverture():
    marqueurs = marqueurs_du_script()
    n, cas, mutants, sans_cas, sans_mutant, orphelins = evaluer_couverture(marqueurs, CAS_NEGATIFS, TUES)
    print("COUVERTURE-SUITE regles=%d cas-negatifs=%d mutants=%d" % (n, cas, mutants))
    # preuve que la couverture n'est pas un vert à vide : sur une règle sans cas, sans mutant, et un cas sans marqueur, elle échoue
    fn, _, _, fs_cas, fs_mut, f_orph = evaluer_couverture(["a", "b"], {"a": [{"nom": "x"}], "z": [{"nom": "y"}]}, {"RELEVE-A"})
    sensible = fn == 2 and fs_cas == ["b"] and fs_mut == ["b"] and f_orph == ["z"]
    if n > 0 and not sans_cas and not sans_mutant and not orphelins and n == cas == mutants and sensible:
        ok("R-RELEVE-COUVERTURE chacune des %d règles marquées du script a un cas négatif et un mutant tué" % n, "COUVERTURE-SUITE regles=%d cas-negatifs=%d mutants=%d" % (n, cas, mutants))
    else:
        ko("R-RELEVE-COUVERTURE", "chaque règle marquée `# releve-<règle>` du script a un cas négatif dans CAS_NEGATIFS ET un mutant joué et tué, sans cas orphelin",
           "regles=cas-negatifs=mutants, aucune règle sans cas, sans mutant, aucun cas sans marqueur",
           "regles=%d cas-negatifs=%d mutants=%d ; sans cas %s ; sans mutant tué %s ; cas sans marqueur %s ; analyseur de couverture %s"
           % (n, cas, mutants, sans_cas, sans_mutant, orphelins, "sensible" if sensible else "AVEUGLE"))


def main():
    global SCRIPT, WORK, FIXTURES
    SCRIPT, WORK = sys.argv[1], sys.argv[2]
    FIXTURES = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(SCRIPT), "tests", "fixtures")
    controle_01()
    controle_02()
    controle_03()
    controle_04()
    controle_07()
    controle_08()
    controle_chaine()
    controle_05()
    controle_06()
    sec_mutants()
    mutant_toujours_armable()
    mutant_toujours_refus()
    mutant_entier_borne()
    mutant_machine_sous_chaine()
    mutant_sortie_jeton()
    mutant_ordre()
    mutant_recoupement_fa_egal()
    controle_couverture()


main()
PY_AIDES_VERIFIER_RELEVE_EOF

out="$WORK/sortie-verifier-releve.txt"
"$PYBIN" "$AIDES" "$SCRIPTS_DIR/verifier-releve.sh" "$WORK" "$TESTS_DIR/fixtures" > "$out" 2>&1
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
