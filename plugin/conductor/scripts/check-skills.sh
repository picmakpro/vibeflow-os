#!/usr/bin/env bash
# check-skills.sh — Gate des skills par nature (B-03, FABR-06/09), miroir de check-agents.sh.
#
# Doctrine (Phase 43, spec fabrique §6) : chaque skill déclare sa NATURE en frontmatter —
# `vf-nature: referentiel | outil | procedure`, DÉFAUT « outil » quand la clé est absente
# (D-Q1, D-Q2 — aucun des 25 SKILL.md du corpus ne change de comportement à l'armement de ce
# gate). Une valeur PRÉSENTE mais hors de cet ensemble exact est REFUSÉE (rc 1) — jamais ramenée
# au défaut « outil » (B-03 : jamais un défaut silencieux sur une déclaration invalide).
# Une PROCÉDURE doit déclarer `ecrit:` (son périmètre d'écriture, moteur D-10) ET
# `vf-rubrique-juge:` (sa rubrique de juge) ; l'absence de l'un, de l'autre ou des deux est un
# refus explicite citant FABR-06 et le chemin relatif du fichier. Un référentiel ou un outil ne
# déclarent rien de plus.
# Trois marqueurs factuels OPTIONNELS (B-03/C-15) : `vf-gate-bloquant`, `vf-livrable-tiers`,
# `vf-couche-qualite` — présents, ils n'acceptent que `true`|`false` (D-Q1).
# FABR-07 (détection de dérive procédurale, écart déclaration/prose) n'est PAS posée par ce
# script — elle arrive en 43-02, un plan distinct, sur le même gate.
#
# Contrat de clés (D-Q1, costly) : ces six clés (`vf-nature`, `ecrit`, `vf-rubrique-juge`,
# `vf-gate-bloquant`, `vf-livrable-tiers`, `vf-couche-qualite`) sont des CONVENTIONS VibeFlow —
# `VIBEFLOW_SKILL_FIELDS`, en dur dans ce script, JAMAIS dans le manifeste daté (même frontière
# que D-01 de la Phase 42 : le manifeste ne porte que des champs d'origine NATIVE, périssables
# avec la doc externe ; une convention du dépôt ne périme pas).
#
# Référentiel : MÊME manifeste daté check-agents-manifest.json que check-agents.sh (même dossier
# que ce script, une seule vérité, FABR-09) — étendu d'une SEPTIÈME liste native
# `champs_frontmatter_skills` (champs de frontmatter natifs d'un SKILL.md, doc Anthropic) ;
# absent, illisible ou invalide (sept clés exactement) → MANIFESTE-ILLISIBLE, rc 1 (0 sous
# --hook) ; chargé seulement s'il y a au moins un skill à juger (chargement paresseux).
#
# Fraîcheur (D-05-like) : seule la liste `champs_frontmatter_skills` est jugée ici (les six
# autres sont hors périmètre de ce gate, jugées par check-agents.sh) — une liste périmée ne
# produit JAMAIS un refus, seulement un avertissement ⚠ MANIFESTE-PERIME. Pas d'option
# --manifest-freshness : la fraîcheur du MÊME fichier est déjà jugée INDÉTERMINÉE en CI par les
# quatre appels --manifest-freshness=strict de check-agents.sh, qui valide désormais les sept
# listes — check-skills.sh n'en fait jamais qu'un avertissement.
#
# Découverte (Claude's Discretion, réutilise D-10 de la Phase 42) : la cible (--skills-dir,
# défaut .claude/skills) est parcourue RÉCURSIVEMENT (os.walk, followlinks=False — aucun lien
# symbolique de dossier suivi), à TOUTE profondeur — les skills de ce dépôt vivent à trois
# profondeurs (plugin/<mod>/SKILL.md, plugin/<mod>/skills/<nom>/SKILL.md,
# plugin/reference/.../skills/<nom>/SKILL.md). Deux exclusions, chacune une ligne unique du
# fichier, prouvées par mutation (MUT-SD1, MUT-SD2) : tout dossier caché (nom commençant par un
# point) et tout dossier dont le nom finit par -references (documents posés par l'installeur,
# jamais des skills). Un SKILL.md en lien symbolique est REFUSÉ sans être ouvert (même patron A1
# que check-agents.sh). Le gate reste GÉNÉRIQUE : l'exclusion de gabarits doc-only
# (plugin/reference) n'est jamais un nom de module en dur ici — elle est portée par
# l'INVOCATION (qui lit le type doc-only du module.json avant d'appeler ce gate sur un module).
#
# Identité dans les messages : chemin relatif à --skills-dir (le nom de base vaut toujours
# SKILL.md et n'identifie rien) ; en --file, le chemin tel que passé sur la ligne de commande.
#
# Usage:
#   check-skills.sh                        # lint .claude/skills/**/SKILL.md · exit 1 si non conforme
#   check-skills.sh --strict               # + cible absente/vide rend INDETERMINE (F13)
#   check-skills.sh --hook                 # SessionStart : compact, exit 0 toujours
#   check-skills.sh --file <SKILL.md>      # un seul fichier
#   check-skills.sh --skills-dir=PATH      # défaut .claude/skills
#   check-skills.sh --allow-empty          # avec --strict : tolère une cible vide ou absente
#   check-skills.sh --third-party-prefix=PFX     # répétable, défaut gsd- (accumule AU-DESSUS
#                                                 # du défaut ; --no-third-party-prefix avant pour repartir de zéro)
#   check-skills.sh --no-third-party-prefix      # vide la liste des préfixes tiers
#
# BLOQUANT (FABR-06) : vf-nature présent hors {referentiel, outil, procedure} · procedure sans
#   ecrit: ni vf-rubrique-juge (l'un, l'autre ou les deux) · entrée de ecrit: ou
#   vf-rubrique-juge malformée (chemin absolu, ~, segment .., caractère hors charset) ·
#   vf-rubrique-juge en liste · marqueur (vf-gate-bloquant/vf-livrable-tiers/vf-couche-qualite)
#   hors {true, false} · frontmatter absent ou jamais refermé.
# WARNING : champ inconnu du référentiel natif ∪ des conventions VibeFlow (typo ?) · manifeste
#   périmé (MANIFESTE-PERIME, jamais un refus, D-05-like).
#
# Codes de sortie (identiques à check-agents.sh) : 0 = conforme (avertissements permis) ·
#   1 = non conforme ou invocation invalide · 3 = INDÉTERMINÉ (cible absente hors --hook, jeton
#   CIBLE-ABSENTE ; cible présente vide sous --strict sans --allow-empty, F13). Sous --hook, 3
#   devient 0 à la frontière du shell (hook_exit) ; le régime nominal (0 erreur, 0 avertissement)
#   n'imprime rien.
#
# --third-party-prefix (défaut "gsd-") exclut, par le champ `name:`, un SKILL.md ENTIER du lint
# FABR-06 (ce n'est pas notre skill) — compté séparément, jamais un skip muet.

set -uo pipefail

SKILLS_DIR=".claude/skills"
STRICT=false
HOOK_MODE=false
ALLOW_EMPTY=false
SINGLE_FILE=""
THIRD_PARTY_PREFIXES="gsd-"

for arg in "$@"; do
  case "$arg" in
    --strict)         STRICT=true ;;
    --hook)           HOOK_MODE=true ;;
    --allow-empty)    ALLOW_EMPTY=true ;;
    --file)           : ;; # valeur au prochain arg — géré ci-dessous
    --skills-dir=*)
      v="${arg#*=}"
      if [ -z "$v" ]; then
        echo "[check-skills] ✗ --skills-dir vide — un chemin est requis" >&2
        exit 1
      fi
      SKILLS_DIR="$v"
      ;;
    --third-party-prefix=*)
      v="${arg#*=}"
      if [ -z "$THIRD_PARTY_PREFIXES" ]; then THIRD_PARTY_PREFIXES="$v"; else THIRD_PARTY_PREFIXES="$THIRD_PARTY_PREFIXES:$v"; fi
      ;;
    --no-third-party-prefix) THIRD_PARTY_PREFIXES="" ;;
    -h|--help)        grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
  esac
done
# --file <path> (2 args)
prev=""
for arg in "$@"; do
  [ "$prev" = "--file" ] && SINGLE_FILE="$arg"
  prev="$arg"
done

# --- Traduction du silence interne vers le harness (uniquement sous --hook) — meme patron que ---
# check-agents.sh : le SEUL code de silence interne (3 = INDETERMINE) devient 0 a la frontiere du
# harness. 0 et 1 ne sont JAMAIS traduits. Voir docs/HOOKS-CONTRAT-SORTIE.md.
hook_exit() { # <code>
  local code="$1"
  if [ "$HOOK_MODE" = true ] && [ "$code" -eq 3 ]; then
    exit 0
  fi
  exit "$code"
}

# Chemin du manifeste daté dérivé du dossier du script (patron check-agents.sh), JAMAIS de
# l'environnement appelant ni du cwd — aucune option de substitution du manifeste.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VF_MANIFEST="$SCRIPT_DIR/check-agents-manifest.json"

# ADR-054 : stub Microsoft Store — python3 present dans le PATH mais inerte. Detection par
# CHEMIN (zero spawn), repli python ; sinon message + exit 0 (advisory, comme check-agents.sh).
PYBIN=python3
case "$(command -v python3 2>/dev/null)" in
  ''|*WindowsApps*) if command -v python >/dev/null 2>&1; then PYBIN=python; else echo "[check-skills] python3 requis" >&2; exit 0; fi ;;
esac

VF_SKILLS_DIR="$SKILLS_DIR" VF_STRICT="$STRICT" VF_HOOK="$HOOK_MODE" VF_SINGLE="$SINGLE_FILE" \
VF_ALLOW_EMPTY="$ALLOW_EMPTY" VF_THIRD_PARTY_PREFIXES="$THIRD_PARTY_PREFIXES" VF_MANIFEST="$VF_MANIFEST" \
"$PYBIN" - <<'PY_CHECK_SKILLS_EOF'
import glob, json, os, re, sys
from datetime import date

manifest_path = os.environ["VF_MANIFEST"]
skills_dir = os.environ["VF_SKILLS_DIR"]
strict = os.environ["VF_STRICT"] == "true"
hook = os.environ["VF_HOOK"] == "true"
allow_empty = os.environ["VF_ALLOW_EMPTY"] == "true"
single = os.environ["VF_SINGLE"]
third_party_prefixes = [p for p in os.environ.get("VF_THIRD_PARTY_PREFIXES", "").split(":") if p]

# Conventions VibeFlow en dur (D-Q1) — jamais dans le manifeste, jamais sujettes a la peremption
# d'une doc Anthropic externe (meme frontiere que D-01, Phase 42) :
VIBEFLOW_SKILL_FIELDS = {"vf-nature", "ecrit", "vf-rubrique-juge", "vf-gate-bloquant",
                         "vf-livrable-tiers", "vf-couche-qualite"}
NATURES = {"referentiel", "outil", "procedure"}

def decouvrir_skills(racine, refuses=None):
    """Decouverte RECURSIVE des SKILL.md sous racine (Claude's Discretion, reprend D-10 de la
    Phase 42) : deux exclusions PROUVEES par mutation (MUT-SD1, MUT-SD2), chacune sur sa PROPRE
    ligne, unique dans le fichier : les dossiers caches (nom commencant par un point) et les
    dossiers *-references poses par l'installeur (documents, jamais des skills). Aucun lien
    symbolique de dossier suivi (followlinks=False, pas de boucle). Fichiers retenus : nommes
    EXACTEMENT SKILL.md, a TOUTE profondeur, ET qui ne sont pas eux-memes un lien symbolique — un
    SKILL.md en lien symbolique est REFUSE comme un dossier : jamais ajoute a trouves, son
    contenu n'est jamais ouvert par cette fonction ni par un appelant. Rend une liste TRIEE."""
    trouves = []
    for dirpath, dirnames, filenames in os.walk(racine, followlinks=False):
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        dirnames[:] = [d for d in dirnames if not d.endswith('-references')]
        for fn in filenames:
            if fn == 'SKILL.md':
                full = os.path.join(dirpath, fn)
                if os.path.islink(full):
                    if refuses is not None:
                        refuses.append(full)
                    continue
                trouves.append(full)
    return sorted(trouves)

# Meme validation stricte que check-agents.sh (recopiee, FABR-09) — sept cles exactement : un
# manifeste ampute ou etendu au-dela des sept refuse les DEUX gates, jamais un seul.
_VALEUR_RE = re.compile(r"^[A-Za-z0-9_-]+$")

def charger_manifeste(chemin):
    """Lit et valide le manifeste date — toute absence/malformation leve une ValueError qui
    nomme la cle et le motif (jamais un defaut silencieux, jamais un skip ligne a ligne)."""
    with open(chemin, encoding="utf-8") as fh:
        m = json.load(fh)
    if not isinstance(m, dict):
        raise ValueError("racine du manifeste — attendu un objet JSON")
    cles_racine = {"valide_jours", "rafraichissement", "listes"}
    for cle in cles_racine:
        if cle not in m:
            raise ValueError(f"cle de premier niveau manquante — {cle}")
    extra = set(m.keys()) - cles_racine
    if extra:
        raise ValueError(f"cle(s) de premier niveau inconnue(s) — {sorted(extra)}")
    valide_jours = m["valide_jours"]
    if not isinstance(valide_jours, int) or isinstance(valide_jours, bool) or valide_jours <= 0:
        raise ValueError("valide_jours — attendu un entier strictement positif")
    listes = m["listes"]
    if not isinstance(listes, dict):
        raise ValueError("listes — attendu un objet JSON")
    cles_listes = {"outils", "champs_frontmatter", "types_natifs", "modeles", "modes_permission", "niveaux_effort", "champs_frontmatter_skills"}
    if set(listes.keys()) != cles_listes:
        raise ValueError(f"listes — attendu exactement les sept cles {sorted(cles_listes)}, trouve {sorted(listes.keys())}")
    for nom_liste, liste in listes.items():
        if not isinstance(liste, dict):
            raise ValueError(f"listes.{nom_liste} — attendu un objet JSON")
        verifie_le = liste.get("verifie_le")
        if not isinstance(verifie_le, str):
            raise ValueError(f"listes.{nom_liste}.verifie_le — attendu une date ISO")
        try:
            date.fromisoformat(verifie_le)
        except ValueError:
            raise ValueError(f"listes.{nom_liste}.verifie_le — date ISO invalide ({verifie_le})")
        source = liste.get("source")
        if not isinstance(source, str) or not source.startswith("https://"):
            raise ValueError(f"listes.{nom_liste}.source — attendu une chaine https:// ({source})")
        valeurs = liste.get("valeurs")
        if not isinstance(valeurs, list) or not valeurs:
            raise ValueError(f"listes.{nom_liste}.valeurs — attendu une liste non vide")
        for v in valeurs:
            if not isinstance(v, str) or not _VALEUR_RE.fullmatch(v):
                raise ValueError(f"listes.{nom_liste}.valeurs — valeur hors charset [A-Za-z0-9_-]+ ({v!r})")
    return m

def liste_skills_perimee(manifest, aujourd_hui):
    """Fraicheur SCOPEE a la seule liste champs_frontmatter_skills (contrairement a
    check-agents.sh qui juge les sept) — les six autres listes sont hors perimetre de ce gate,
    jugees par check-agents.sh. Rend une description ou None (liste fraiche)."""
    liste = manifest["listes"]["champs_frontmatter_skills"]
    valide_jours = manifest["valide_jours"]
    verifie_le = date.fromisoformat(liste["verifie_le"])
    if verifie_le > aujourd_hui:
        return f"champs_frontmatter_skills (DATE-FUTURE : verifiee le {verifie_le.isoformat()}, posterieure a aujourd'hui — non verifiable)"
    age = (aujourd_hui - verifie_le).days
    if age > valide_jours:
        return f"champs_frontmatter_skills (verifiee le {verifie_le.isoformat()}, {age} j, validite {valide_jours} j)"
    return None

KNOWN = None
perimee_msg = None

def charger_referentiel():
    """Charge le manifeste et peuple KNOWN/perimee_msg. Appelee SEULEMENT s'il existe au moins
    une cible a juger (chargement PARESSEUX) — la branche cible vide (F13) ne l'appelle jamais."""
    global KNOWN, perimee_msg
    try:
        m = charger_manifeste(manifest_path)
    except (OSError, ValueError) as e:
        cause = str(e).replace(" : ", " - ")
        print(f"[check-skills] ✗ MANIFESTE-ILLISIBLE ({manifest_path}) — {cause} — aucun verdict rendu")
        sys.exit(0 if hook else 1)
    listes = m["listes"]
    KNOWN = set(listes["champs_frontmatter_skills"]["valeurs"]) | VIBEFLOW_SKILL_FIELDS
    perimee_msg = liste_skills_perimee(m, date.today())

errors, warnings = [], []
thirdparty_files_total = 0
linted_paths = []

def parse_frontmatter(text):
    """Meme tokenizer YAML-tolerant (scalaire/liste/continuation) que check-agents.sh — recopie
    verbatim, aucune divergence de comportement entre les deux gates sur ce point."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    fm, i = {}, 1
    current_key = None
    while i < len(lines):
        line = lines[i]
        if line.strip() == "---":
            return fm
        m = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if m:
            current_key = m.group(1)
            val = m.group(2).strip()
            if val.startswith("[") and val.endswith("]"):
                items = [x.strip().strip(chr(34)).strip(chr(39)) for x in val[1:-1].split(",") if x.strip()]
                fm[current_key] = items
            elif val == "" or val == ">" or val == "|":
                fm[current_key] = "" if val == "" else val
            else:
                if len(val) >= 2 and val[0] == val[-1] and val[0] in (chr(34), chr(39)):
                    val = val[1:-1]
                fm[current_key] = val
        elif current_key is not None:
            item = re.match(r"^\s+-\s+(.+?)(\s+#.*)?$", line)
            if item and isinstance(fm.get(current_key), list):
                fm[current_key].append(item.group(1).strip().strip(chr(34)).strip(chr(39)))
            elif item and fm.get(current_key) == "":
                fm[current_key] = [item.group(1).strip().strip(chr(34)).strip(chr(39))]
            elif line.startswith("  ") and isinstance(fm.get(current_key), str):
                fm[current_key] = (fm[current_key] + " " + line.strip()).strip()
        i += 1
    return None  # frontmatter jamais ferme

def esc(v):
    """Fonction UNIQUE d'echappement (T-43-04) : representation echappee de Python (repr),
    tronquee a 80 caracteres — aucune valeur de frontmatter n'est jamais reinjectee telle quelle
    dans la sortie, ni passee a un shell. repr() echappe deja tout octet de controle (ESC
    compris) en sequence imprimable — jamais l'octet brut."""
    s = repr(v)
    return s if len(s) <= 80 else s[:80]

def is_absent_value(v):
    """valeur vide, liste vide ou chaine vide = absente (FABR-06)."""
    if v is None:
        return True
    if isinstance(v, str):
        return v.strip() == ""
    if isinstance(v, list):
        return len(v) == 0 or all((not isinstance(x, str)) or x.strip() == "" for x in v)
    return False

def valider_nature(rel, fm):
    """B-03 : valeur PRESENTE hors de l'ensemble exact {referentiel, outil, procedure}
    (sensible a la casse, sans accent) est REFUSEE — jamais ramenee au defaut « outil ». Une
    liste ou une valeur vide est invalide. Cle ABSENTE n'est jamais une erreur ici (le defaut
    « outil » est applique par invariant_procedure, pas ici)."""
    if "vf-nature" not in fm:
        return []
    val = fm["vf-nature"]
    if isinstance(val, str) and val in NATURES:
        return []
    return [f"{rel} : vf-nature invalide {esc(val)} — attendu referentiel|outil|procedure (B-03 : jamais un defaut silencieux)"]

def invariant_procedure(rel, fm):
    """FABR-06 : une procedure sans ecrit: ni vf-rubrique-juge (l'un, l'autre ou les deux) est
    refusee. Cle vf-nature absente -> defaut « outil » (jamais procedure) -> jamais d'erreur ici."""
    nature = fm.get("vf-nature", "outil")
    if not isinstance(nature, str) or nature != "procedure":
        return []
    manquants = []
    if is_absent_value(fm.get("ecrit")):
        manquants.append("ecrit:")
    if is_absent_value(fm.get("vf-rubrique-juge")):
        manquants.append("vf-rubrique-juge")
    if manquants:
        return [f"{rel} : vf-nature: procedure sans {' ni '.join(manquants)} (B-03, FABR-06)"]
    return []

def skill_display_name(text):
    fm = parse_frontmatter(text)
    if fm and isinstance(fm.get("name"), str) and fm.get("name"):
        return fm["name"]
    return ""

def check_file(rel, text):
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        errors.append(f"{rel} : frontmatter absent (--- ... ---) — aucun verdict possible")
        return
    fm = parse_frontmatter(text)
    if fm is None:
        errors.append(f"{rel} : frontmatter jamais referme (--- ... ---) — aucun verdict possible")
        return
    errors.extend(valider_nature(rel, fm))
    errors.extend(invariant_procedure(rel, fm))

if single:
    if os.path.islink(single):
        errors.append(f"{single} : lien symbolique refuse — un SKILL.md ne doit jamais etre un lien symbolique, contenu non lu")
    elif os.path.isfile(single):
        charger_referentiel()
        try:
            text = open(single, encoding="utf-8-sig").read()
        except OSError as e:
            errors.append(f"{single} : illisible ({e})")
        else:
            dname = skill_display_name(text)
            matched_prefix = next((p for p in third_party_prefixes if p and dname and dname.startswith(p)), None)
            if matched_prefix:
                thirdparty_files_total += 1
            else:
                check_file(single, text)
                linted_paths.append(single)
    else:
        errors.append(f"fichier introuvable : {single}")
else:
    cible_absente = (not single) and not os.path.isdir(skills_dir)
    symlinks_refuses = []
    files = decouvrir_skills(skills_dir, symlinks_refuses)
    for sp in symlinks_refuses:
        rel_sp = os.path.relpath(sp, skills_dir)
        errors.append(f"{rel_sp} : lien symbolique refuse — un SKILL.md ne doit jamais etre un lien symbolique, contenu non lu")
    if not files and not symlinks_refuses:
        if cible_absente and not hook and not allow_empty:
            print(f"[check-skills] ✗ INDETERMINE : {skills_dir} — CIBLE-ABSENTE, aucun verdict rendu")
            sys.exit(3)
        if strict and not allow_empty:
            if not hook:
                print(f"[check-skills] ✗ INDETERMINE : aucun SKILL.md dans {skills_dir} — cible absente ou vide, aucun verdict rendu (--allow-empty pour tolerer)")
            sys.exit(3)
        if not hook:
            print(f"[check-skills] aucun SKILL.md dans {skills_dir} — rien a verifier")
        sys.exit(0)
    charger_referentiel()
    for f in files:
        try:
            text = open(f, encoding="utf-8-sig").read()
        except OSError as e:
            errors.append(f"{os.path.relpath(f, skills_dir)} : illisible ({e})")
            continue
        dname = skill_display_name(text)
        matched_prefix = next((p for p in third_party_prefixes if p and dname and dname.startswith(p)), None)
        if matched_prefix:
            thirdparty_files_total += 1
            continue
        check_file(os.path.relpath(f, skills_dir), text)
        linted_paths.append(f)

n_err, n_warn = len(errors), len(warnings)

def rapport_manifeste_perime():
    return (f"[check-skills] ⚠ MANIFESTE-PERIME — {perimee_msg} — liste retrogradee en "
            f"avertissement ; rafraichir check-agents-manifest.json : relire la source, comparer, re-dater")

if hook:
    if perimee_msg:
        print(rapport_manifeste_perime())
    if n_err:
        print(f"[check-skills] ✗ {n_err} skill(s) non conforme(s) :")
        for e in errors:
            print(f"  - {e}")
    elif n_warn:
        print(f"[check-skills] ⚠ {n_warn} avertissement(s) — detail : bash .claude/scripts/check-skills.sh")
    sys.exit(0)

if perimee_msg:
    print(rapport_manifeste_perime())
for w in warnings:
    print(f"  ⚠ {w}")
if thirdparty_files_total:
    pfx_str = ','.join(third_party_prefixes) if third_party_prefixes else '—'
    print(f"[check-skills] {thirdparty_files_total} skill(s) tiers non linte(s) (prefixe(s) : {pfx_str})")
if n_err:
    print(f"[check-skills] ✗ {n_err} non-conformite(s) bloquante(s) :")
    for e in errors:
        print(f"  ✗ {e}")
    sys.exit(1)
print(f"[check-skills] ✓ skills conformes (nature B-03) · {len(linted_paths)} SKILL.md juge(s){' · ' + str(n_warn) + ' warning(s)' if n_warn else ''}")
sys.exit(0)
PY_CHECK_SKILLS_EOF
PY_RC=$?
hook_exit "$PY_RC"
